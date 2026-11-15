// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/physics/tire_pressure_calculator.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/equipment/equipment_wear_and_maintenance.dart';
import '../../models/equipment/frame_model.dart';
import '../../models/equipment/groupset_model.dart';
import '../../models/equipment/tire_model.dart';
import '../../models/equipment/wheelset_model.dart';
import '../../models/race/stage_segment.dart';

/// Poziom nocnego serwisu roweru podczas Grand Touru.
enum BikeServiceTier {
  /// Podstawowe mycie, kontrola napędu i sprawdzenie ciśnienia (0.5h pracy).
  quickWashAndCheck,

  /// Standardowy serwis etapowy: mycie, regulacja, wosk w płynie, kontrola klocków (1.5h pracy).
  standardRacePrep,

  /// Pełny serwis VIP: kąpiel ultradźwiękowa, gotowanie w wosku na gorąco, wymiana okładzin,
  /// zalanie świeżego mleczka i centrowanie kół (3.0h pracy).
  fullVipGrandTourOverhaul;

  String get displayName {
    switch (this) {
      case BikeServiceTier.quickWashAndCheck:
        return 'Szybkie mycie i inspekcja';
      case BikeServiceTier.standardRacePrep:
        return 'Standardowy serwis etapowy';
      case BikeServiceTier.fullVipGrandTourOverhaul:
        return 'Pełny serwis VIP (Hot Wax + Overhaul)';
    }
  }

  double get laborHours {
    switch (this) {
      case BikeServiceTier.quickWashAndCheck:
        return 0.5;
      case BikeServiceTier.standardRacePrep:
        return 1.5;
      case BikeServiceTier.fullVipGrandTourOverhaul:
        return 3.0;
    }
  }
}

/// Profil mechanika w zespole serwisowym Grand Touru.
class GrandTourMechanicStaff {
  final String id;
  final String name;
  final String specialization;
  final int skillScore; // 1-100
  final double maxShiftHours; // zazwyczaj 6.5h na noc

  const GrandTourMechanicStaff({
    required this.id,
    required this.name,
    required this.specialization,
    required this.skillScore,
    this.maxShiftHours = 6.5,
  });
}

/// Rower kolarza w bazie Grand Touru przypisany do nocnego serwisu.
class GrandTourBikeRosterItem {
  final String riderId;
  final String riderName;
  final String roleDescription; // np. Lider GC, Sprinter, Góral, Domestique
  final bool isLeader;
  final BikeServiceTier serviceTier;
  final double overallWearPercent;

  const GrandTourBikeRosterItem({
    required this.riderId,
    required this.riderName,
    required this.roleDescription,
    this.isLeader = false,
    this.serviceTier = BikeServiceTier.standardRacePrep,
    this.overallWearPercent = 18.0,
  });

  GrandTourBikeRosterItem copyWith({
    String? riderId,
    String? riderName,
    String? roleDescription,
    bool? isLeader,
    BikeServiceTier? serviceTier,
    double? overallWearPercent,
  }) {
    return GrandTourBikeRosterItem(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      roleDescription: roleDescription ?? this.roleDescription,
      isLeader: isLeader ?? this.isLeader,
      serviceTier: serviceTier ?? this.serviceTier,
      overallWearPercent: overallWearPercent ?? this.overallWearPercent,
    );
  }
}

/// Panel Warsztatu Mechaników WorldTour.
///
/// Funkcjonalności:
/// 1. **Ustawianie ciśnienia w oponach** (suwaki BAR/PSI) z interaktywnym podglądem
///    wykresu strat mocy i oporów toczenia (Crr) oraz punktu krytycznego (Breakpoint).
///    Wizualizacja strat impedancyjnych przy nadciśnieniu na bruku (+15-25W!).
/// 2. **Wybór smarowania łańcucha** na jutrzejszy etap (Hot Melt Wax Standard vs
///    All-Weather Hydrofobowy vs Drip Wax vs Wet Lube) z uwzględnieniem prognozy pogody.
/// 3. **Wymiana zużytych części** (łańcuch, bieżnik opon, mikronacięcia po bruku,
///    klocki żywiczne/spiekane, mleczko tubeless, pełny Grand Tour Overhaul).
/// 4. **Nocny serwis rowerów podczas 3-tygodniowego Grand Touru** (przydział 4 mechaników
///    do 8 rowerów, optymalizacja godzin pracy i zapobieganie zmęczeniu załogi).
class MechanicWorkshopPanel extends StatefulWidget {
  final CompleteBike? bike;
  final double riderWeightKg;
  final String riderName;
  final SegmentSurfaceType upcomingSurface;
  final bool isUpcomingRain;
  final ValueChanged<CompleteBike>? onBikeUpdated;
  final ValueChanged<TirePressureRecommendation>? onPressureApplied;

  const MechanicWorkshopPanel({
    super.key,
    this.bike,
    this.riderWeightKg = 68.0,
    this.riderName = 'Lider Zespołu',
    this.upcomingSurface = SegmentSurfaceType.roughAsphalt,
    this.isUpcomingRain = false,
    this.onBikeUpdated,
    this.onPressureApplied,
  });

  @override
  State<MechanicWorkshopPanel> createState() => _MechanicWorkshopPanelState();
}

class _MechanicWorkshopPanelState extends State<MechanicWorkshopPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Stan parametrów kół i ciśnienia
  late double _frontBar;
  late double _rearBar;
  late int _tireWidthMm;
  late TireSystemType _tireSystem;
  late RoadSurfaceCategory _surfaceCategory;
  late RimType _rimType;
  late bool _isWetRoad;

  // Stan roweru i zużycia
  late CompleteBike _currentBike;
  late EquipmentWearAndMaintenance _wearState;

  // Stan zespołu mechaników Grand Touru
  late List<GrandTourMechanicStaff> _mechanicsList;
  late List<GrandTourBikeRosterItem> _rosterList;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _initBikeAndWear();
    _initTirePressure();
    _initGrandTourRoster();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initBikeAndWear() {
    if (widget.bike != null) {
      _currentBike = widget.bike!;
      _wearState = widget.bike!.wear;
    } else {
      _wearState = EquipmentWearAndMaintenance.brandNew(
        allWeatherWax: widget.isUpcomingRain,
      );
      _currentBike = CompleteBike(
        id: 'workshop-demo-bike',
        name: 'S-Works Tarmac SL8 Team Issue',
        frame: const FrameModel(
          id: 'frame-tarmac-sl8',
          brandId: 'specialized',
          name: 'Tarmac SL8',
          category: FrameCategory.allRounder,
          weightGrams: 785,
          aeroCdaModifier: -0.012,
          stiffnessToWeightIndex: 2.1,
          comfortCompliance: 0.70,
          priceEur: 5500,
          mesh3dAssetPath: 'assets/models/frame.glb',
          primaryColorHex: '#101010',
        ),
        wheelset: const WheelsetModel(
          id: 'wheels-roval-clx',
          brandId: 'roval',
          name: 'Rapide CLX II',
          rimDepthMm: 51,
          weightGrams: 1520,
          aeroCdaModifier: -0.015,
          crosswindStabilityPenalty: 0.2,
          momentOfInertia: 0.12,
          hubEngagementDragWatts: 0.4,
          priceEur: 2700,
        ),
        groupset: const GroupsetModel(
          id: 'groupset-duraace',
          brandId: 'shimano',
          name: 'Dura-Ace Di2 R9200',
          weightGrams: 2200,
          isElectronic: true,
          speedCount: 12,
          mechanicalEfficiency: 0.985,
          priceEur: 3800,
        ),
        tire: const TireModel(
          id: 'tire-gp5000-28',
          brandId: 'continental',
          name: 'GP5000 S TR',
          widthMm: 28,
          weightGrams: 275,
          rollingResistanceCrr: 0.0035,
          punctureResistanceIndex: 4.0,
          wetGripIndex: 4.5,
          isTubeless: true,
          priceEur: 85,
        ),
        cockpitWidthMm: 380,
        hoodInwardTiltDegrees: 12.0,
        slammedStem: true,
        wearAndMaintenance: _wearState,
      );
    }
  }

  void _initTirePressure() {
    _tireWidthMm = _currentBike.tire.widthMm;
    _tireSystem = _currentBike.tire.isTubeless
        ? TireSystemType.tubeless
        : TireSystemType.tpuTube;

    _surfaceCategory = _mapSegmentToSurfaceCategory(widget.upcomingSurface);
    _isWetRoad = widget.isUpcomingRain;
    _rimType = RimType.hooked;

    final rec = TirePressureCalculator.calculateOptimalPressure(
      totalMassKg: widget.riderWeightKg + _currentBike.totalWeightKg + 1.0,
      tireWidthMm: _tireWidthMm,
      tireSystem: _tireSystem,
      surface: _surfaceCategory,
      isWet: _isWetRoad,
      rimType: _rimType,
    );

    _frontBar = rec.frontPressureBar;
    _rearBar = rec.rearPressureBar;
  }

  void _initGrandTourRoster() {
    _mechanicsList = const [
      GrandTourMechanicStaff(
        id: 'm1',
        name: 'Marek Velo',
        specialization: 'Główny Mechanik (Chief)',
        skillScore: 98,
        maxShiftHours: 7.0,
      ),
      GrandTourMechanicStaff(
        id: 'm2',
        name: 'Johan De Smet',
        specialization: 'Ekspert Kół i Bruków (Flandria)',
        skillScore: 94,
        maxShiftHours: 6.5,
      ),
      GrandTourMechanicStaff(
        id: 'm3',
        name: 'Pierre Moreau',
        specialization: 'Napędy & Woskowanie Łańcuchów',
        skillScore: 95,
        maxShiftHours: 6.5,
      ),
      GrandTourMechanicStaff(
        id: 'm4',
        name: 'Lukas Novak',
        specialization: 'Asystent Serwisowy (Młodszy)',
        skillScore: 86,
        maxShiftHours: 6.0,
      ),
    ];

    _rosterList = [
      GrandTourBikeRosterItem(
        riderId: 'r1',
        riderName: widget.riderName,
        roleDescription: 'Lider Klasyfikacji Generalnej (GC)',
        isLeader: true,
        serviceTier: BikeServiceTier.fullVipGrandTourOverhaul,
        overallWearPercent: 24.0,
      ),
      const GrandTourBikeRosterItem(
        riderId: 'r2',
        riderName: 'Wout Van Aert-Type',
        roleDescription: 'Główny Rozprowadzający / Puncheur',
        isLeader: false,
        serviceTier: BikeServiceTier.standardRacePrep,
        overallWearPercent: 32.0,
      ),
      const GrandTourBikeRosterItem(
        riderId: 'r3',
        riderName: 'Sepp Kuss-Type',
        roleDescription: 'Główny Pomocnik w Wysokich Górach',
        isLeader: false,
        serviceTier: BikeServiceTier.standardRacePrep,
        overallWearPercent: 19.0,
      ),
      const GrandTourBikeRosterItem(
        riderId: 'r4',
        riderName: 'Kasper Asgreen-Type',
        roleDescription: 'Kapitan Szosowy / Rower na wiatry',
        isLeader: false,
        serviceTier: BikeServiceTier.quickWashAndCheck,
        overallWearPercent: 28.0,
      ),
      const GrandTourBikeRosterItem(
        riderId: 'r5',
        riderName: 'Michał Kwiatkowski-Type',
        roleDescription: 'Super-Domestique',
        isLeader: false,
        serviceTier: BikeServiceTier.standardRacePrep,
        overallWearPercent: 22.0,
      ),
      const GrandTourBikeRosterItem(
        riderId: 'r6',
        riderName: 'Młody Talent (Góral)',
        roleDescription: 'Młody Pomocnik',
        isLeader: false,
        serviceTier: BikeServiceTier.quickWashAndCheck,
        overallWearPercent: 15.0,
      ),
      const GrandTourBikeRosterItem(
        riderId: 'r7',
        riderName: 'Rouleur Tempowiec',
        roleDescription: 'Praca na czele peletonu',
        isLeader: false,
        serviceTier: BikeServiceTier.quickWashAndCheck,
        overallWearPercent: 35.0,
      ),
      const GrandTourBikeRosterItem(
        riderId: 'r8',
        riderName: 'Zapasowy Rower Lidera (Roof Car)',
        roleDescription: 'Rower Zapasowy na dachu auta #1',
        isLeader: true,
        serviceTier: BikeServiceTier.standardRacePrep,
        overallWearPercent: 5.0,
      ),
    ];
  }

  RoadSurfaceCategory _mapSegmentToSurfaceCategory(SegmentSurfaceType type) {
    switch (type) {
      case SegmentSurfaceType.smoothAsphalt:
        return RoadSurfaceCategory.smoothAsphalt;
      case SegmentSurfaceType.concrete:
        return RoadSurfaceCategory.averageAsphalt;
      case SegmentSurfaceType.roughAsphalt:
        return RoadSurfaceCategory.roughAsphalt;
      case SegmentSurfaceType.cobblestonesSector1:
      case SegmentSurfaceType.cobblestonesSector2:
      case SegmentSurfaceType.cobblestonesSector3:
      case SegmentSurfaceType.cobblestonesSector4:
      case SegmentSurfaceType.cobblestonesSector5:
        return RoadSurfaceCategory.cobblestones;
      case SegmentSurfaceType.gravelStrade:
        return RoadSurfaceCategory.gravel;
    }
  }

  TirePressureRecommendation _getOptimalRecommendation() {
    return TirePressureCalculator.calculateOptimalPressure(
      totalMassKg: widget.riderWeightKg + _currentBike.totalWeightKg + 1.0,
      tireWidthMm: _tireWidthMm,
      tireSystem: _tireSystem,
      surface: _surfaceCategory,
      isWet: _isWetRoad,
      rimType: _rimType,
    );
  }

  TirePressureEvaluation _getEvaluation() {
    final rec = _getOptimalRecommendation();
    return TirePressureCalculator.evaluatePressure(
      frontPressureBar: _frontBar,
      rearPressureBar: _rearBar,
      recommendation: rec,
      speedKmh: 42.0,
    );
  }

  void _applyOptimalPressurePreset() {
    final rec = _getOptimalRecommendation();
    setState(() {
      _frontBar = rec.frontPressureBar;
      _rearBar = rec.rearPressureBar;
    });

    widget.onPressureApplied?.call(rec);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceLight,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.emeraldGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Zastosowano zalecenia Silca/SRAM: ${_frontBar.toStringAsFixed(2)} BAR przód, ${_rearBar.toStringAsFixed(2)} BAR tył.',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateWearAndNotify(EquipmentWearAndMaintenance newWear, String message) {
    setState(() {
      _wearState = newWear;
      _currentBike = _currentBike.applyWear(newWear);
    });

    widget.onBikeUpdated?.call(_currentBike);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceLight,
        content: Row(
          children: [
            const Icon(Icons.build_circle, color: AppColors.cyanAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTirePressureTab(),
                _buildChainLubricantTab(),
                _buildPartsReplacementTab(),
                _buildNightServiceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final health = _wearState.overallHealthIndex;
    final healthColor = health >= 85
        ? AppColors.emeraldGreen
        : (health >= 60 ? AppColors.amberWarning : AppColors.crimsonAlert);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(
              Icons.home_repair_service_rounded,
              color: AppColors.goldAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WARSZTAT MECHANIKÓW I SERWIS WYŚCIGOWY',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rower: ${_currentBike.name} • Kolarz: ${widget.riderName} (${widget.riderWeightKg.toStringAsFixed(0)} kg)',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: healthColor.withAlpha(35),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: healthColor.withAlpha(120)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.health_and_safety, color: healthColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Kondycja: $health%',
                  style: TextStyle(
                    color: healthColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.goldAccent,
        indicatorWeight: 3,
        labelColor: AppColors.goldAccent,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(
            icon: Icon(Icons.speed_rounded, size: 20),
            text: 'Ciśnienie & Crr',
          ),
          Tab(
            icon: Icon(Icons.water_drop_outlined, size: 20),
            text: 'Smarowanie & Wosk',
          ),
          Tab(
            icon: Icon(Icons.build_rounded, size: 20),
            text: 'Części & Zużycie',
          ),
          Tab(
            icon: Icon(Icons.nightlight_round, size: 20),
            text: 'Nocna Zmiana GT',
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // ZAKŁADKA 1: CIŚNIENIE W OPONACH & WYKRES CRR
  // =========================================================================
  Widget _buildTirePressureTab() {
    final recommendation = _getOptimalRecommendation();
    final evaluation = _getEvaluation();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPressureHeaderRow(recommendation),
          const SizedBox(height: 18),
          _buildCrrChartContainer(recommendation, evaluation),
          const SizedBox(height: 20),
          _buildPressureSliders(recommendation),
          const SizedBox(height: 20),
          _buildTireSetupSelectors(),
          const SizedBox(height: 20),
          _buildEvaluationCard(evaluation, recommendation),
        ],
      ),
    );
  }

  Widget _buildPressureHeaderRow(TirePressureRecommendation rec) {
    return Wrap(
      spacing: 16,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OPTYMALIZACJA CIŚNIENIA SILCA / SRAM',
              style: TextStyle(
                color: AppColors.goldAccent,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Zalecane: ${rec.frontPressureBar.toStringAsFixed(2)} BAR (${rec.frontPressurePsi.toStringAsFixed(0)} PSI) F / '
              '${rec.rearPressureBar.toStringAsFixed(2)} BAR (${rec.rearPressurePsi.toStringAsFixed(0)} PSI) R',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _applyOptimalPressurePreset,
          icon: const Icon(Icons.auto_fix_high, size: 16),
          label: const Text('ZASTOSUJ SILCA/SRAM'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.goldAccent,
            foregroundColor: AppColors.backgroundDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildCrrChartContainer(
    TirePressureRecommendation rec,
    TirePressureEvaluation evaluation,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.show_chart, color: AppColors.cyanAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Krzywa Strat Mocy i Impedancji (Crr Curve)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _buildChartLegendItem('Optimum (Breakpoint)', AppColors.emeraldGreen),
                  _buildChartLegendItem('Przód (${_frontBar.toStringAsFixed(1)}B)', AppColors.accentBlue),
                  _buildChartLegendItem('Tył (${_rearBar.toStringAsFixed(1)}B)', AppColors.amberWarning),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _TirePressureCrrChartPainter(
                surface: _surfaceCategory,
                optimalRearBar: rec.rearPressureBar,
                frontBar: _frontBar,
                rearBar: _rearBar,
                minSafeBar: rec.minSafeRearPressureBar,
                isHookless: _rimType == RimType.hookless,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _surfaceCategory.isCobblestones
                ? 'UWAGA NA BRUK: Przepompowanie powyżej ${rec.rearPressureBar.toStringAsFixed(1)} BAR wywołuje gwałtowne straty odbijania koła (impedance losses = +15-25W!) oraz utratę kontroli.'
                : 'Po lewej: uginanie opony (straty histerezy). Po prawej za zieloną linią: mikrodrgania i odbijanie (straty impedancyjne).',
            style: TextStyle(
              color: _surfaceCategory.isCobblestones
                  ? AppColors.amberWarning
                  : AppColors.textSecondary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildPressureSliders(TirePressureRecommendation rec) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tire_repair, color: AppColors.accentBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'PRZEDNIE KOŁO (Front)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                '${_frontBar.toStringAsFixed(2)} BAR • ${TirePressureCalculator.barToPsi(_frontBar).toStringAsFixed(0)} PSI',
                style: const TextStyle(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accentBlue,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.accentBlue,
              overlayColor: AppColors.accentBlue.withAlpha(40),
            ),
            child: Slider(
              value: _frontBar,
              min: 1.8,
              max: 7.0,
              divisions: 104,
              onChanged: (val) {
                setState(() => _frontBar = (val * 20.0).round() / 20.0);
              },
            ),
          ),
          const Divider(color: AppColors.cardBorder, height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tire_repair, color: AppColors.amberWarning, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'TYLNE KOŁO (Rear - napędzane)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                '${_rearBar.toStringAsFixed(2)} BAR • ${TirePressureCalculator.barToPsi(_rearBar).toStringAsFixed(0)} PSI',
                style: const TextStyle(
                  color: AppColors.amberWarning,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.amberWarning,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.amberWarning,
              overlayColor: AppColors.amberWarning.withAlpha(40),
            ),
            child: Slider(
              value: _rearBar,
              min: 1.8,
              max: 7.0,
              divisions: 104,
              onChanged: (val) {
                setState(() => _rearBar = (val * 20.0).round() / 20.0);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTireSetupSelectors() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KONFIGURACJA OGUMIENIA I NAWIERZCHNI',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _buildSelectorDropdown<int>(
                label: 'Szerokość opony',
                value: _tireWidthMm,
                items: const [25, 28, 30, 32],
                itemLabel: (w) => '$w mm',
                onChanged: (val) {
                  if (val != null) setState(() => _tireWidthMm = val);
                },
              ),
              _buildSelectorDropdown<TireSystemType>(
                label: 'System opony',
                value: _tireSystem,
                items: TireSystemType.values,
                itemLabel: (s) => s.displayName.split('(').first.trim(),
                onChanged: (val) {
                  if (val != null) setState(() => _tireSystem = val);
                },
              ),
              _buildSelectorDropdown<RoadSurfaceCategory>(
                label: 'Nawierzchnia',
                value: _surfaceCategory,
                items: RoadSurfaceCategory.values,
                itemLabel: (s) => s.displayName.split('(').first.trim(),
                onChanged: (val) {
                  if (val != null) setState(() => _surfaceCategory = val);
                },
              ),
              _buildSelectorDropdown<RimType>(
                label: 'Typ obręczy',
                value: _rimType,
                items: RimType.values,
                itemLabel: (r) => r == RimType.hookless ? 'Hookless (Max 5.0B)' : 'Hooked (Haczykowa)',
                onChanged: (val) {
                  if (val != null) setState(() => _rimType = val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButton<T>(
            value: value,
            underline: const SizedBox(),
            dropdownColor: AppColors.surfaceLight,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildEvaluationCard(
    TirePressureEvaluation evaluation,
    TirePressureRecommendation rec,
  ) {
    Color verdictColor;
    switch (evaluation.verdict) {
      case PressureEvaluationVerdict.optimal:
        verdictColor = AppColors.emeraldGreen;
        break;
      case PressureEvaluationVerdict.slightlyHigh:
      case PressureEvaluationVerdict.slightlyLow:
        verdictColor = AppColors.amberWarning;
        break;
      case PressureEvaluationVerdict.severeOverpressureImpedance:
      case PressureEvaluationVerdict.dangerouslyLowPinchFlatRisk:
      case PressureEvaluationVerdict.hooklessDanger:
        verdictColor = AppColors.crimsonAlert;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: verdictColor.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: verdictColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  evaluation.verdict.displayName.toUpperCase(),
                  style: TextStyle(
                    color: verdictColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '+${evaluation.totalRollingPenaltyWatts.toStringAsFixed(1)} W STRAT',
                style: TextStyle(
                  color: evaluation.totalRollingPenaltyWatts > 0.5
                      ? verdictColor
                      : AppColors.emeraldGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            evaluation.diagnosticMessage,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricPill(
                  'Przyczepność w łukach',
                  '${evaluation.corneringGripPercent.toStringAsFixed(0)}%',
                  evaluation.corneringGripPercent >= 85
                      ? AppColors.emeraldGreen
                      : AppColors.amberWarning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricPill(
                  'Ryzyko Snakebite',
                  '${evaluation.pinchFlatRiskPercent.toStringAsFixed(0)}%',
                  evaluation.pinchFlatRiskPercent < 15
                      ? AppColors.emeraldGreen
                      : AppColors.crimsonAlert,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricPill(
                  'Strata Impedancji',
                  '+${evaluation.impedanceLossWatts.toStringAsFixed(1)} W',
                  evaluation.impedanceLossWatts < 2.0
                      ? AppColors.emeraldGreen
                      : AppColors.crimsonAlert,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  // =========================================================================
  // ZAKŁADKA 2: SMAROWANIE ŁAŃCUCHA & WOSK NA ETAP
  // =========================================================================
  Widget _buildChainLubricantTab() {
    final activeLube = _wearState.chain.lubricantType;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeatherForecastAlert(),
          const SizedBox(height: 18),
          const Text(
            'WYBÓR FORMUŁY SMAROWANIA / WOSKU',
            style: TextStyle(
              color: AppColors.goldAccent,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          ...DrivetrainLubricantType.values
              .where((l) => l != DrivetrainLubricantType.strippedNoLube)
              .map((lube) => _buildLubricantCard(lube, activeLube)),
        ],
      ),
    );
  }

  Widget _buildWeatherForecastAlert() {
    final bool isRainAlert = widget.isUpcomingRain;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRainAlert
            ? AppColors.crimsonAlert.withAlpha(20)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRainAlert
              ? AppColors.crimsonAlert.withAlpha(120)
              : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isRainAlert ? Icons.cloudy_snowing : Icons.wb_sunny_rounded,
            color: isRainAlert ? AppColors.crimsonAlert : AppColors.goldAccent,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRainAlert
                      ? 'PROGNOZA: ULEWNY DESZCZ NA JUTRZEJSZYM ETAPIE!'
                      : 'PROGNOZA: SUCHA NAWIERZCHNIA I SŁOŃCE',
                  style: TextStyle(
                    color: isRainAlert ? AppColors.crimsonAlert : AppColors.goldAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isRainAlert
                      ? 'Standardowy wosk na gorąco (Hot Melt Wax) ulegnie wypłukaniu po 140 km! Zastosuj formułę All-Weather Hydrofobową, aby uniknąć +7.5W strat na finiszu.'
                      : 'Idealne warunki na czysty wosk na gorąco z dodatkiem dwusiarczku wolframu (WS2) / grafenu (zaledwie 3.5 W strat tarcia napędu).',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLubricantCard(
    DrivetrainLubricantType lube,
    DrivetrainLubricantType activeLube,
  ) {
    final bool isSelected = lube == activeLube;
    final double baselineWatts = lube.baselineFrictionLossWatts;

    String recommendationBadge;
    Color badgeColor;

    if (lube == DrivetrainLubricantType.hotMeltWaxAllWeather) {
      recommendationBadge = 'REKOMENDOWANY NA DESZCZ & GRAND TOUR';
      badgeColor = AppColors.cyanAccent;
    } else if (lube == DrivetrainLubricantType.hotMeltWaxStandard) {
      recommendationBadge = 'NAJSZYBSZY NA SUCHO (3.5 W)';
      badgeColor = AppColors.goldAccent;
    } else if (lube == DrivetrainLubricantType.dripWaxEmulsion) {
      recommendationBadge = 'SZYBKA APLIKACJA W POLU';
      badgeColor = AppColors.accentBlue;
    } else {
      recommendationBadge = 'TRADYCYJNY OLEJ SYNTETYCZNY';
      badgeColor = AppColors.powerZone1;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.surfaceLight.withAlpha(200)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.goldAccent : AppColors.cardBorder,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  recommendationBadge,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              Text(
                '${baselineWatts.toStringAsFixed(1)} W STRAT',
                style: TextStyle(
                  color: baselineWatts <= 4.0
                      ? AppColors.emeraldGreen
                      : AppColors.amberWarning,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lube.displayName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getLubricantDescription(lube),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isSelected)
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.goldAccent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'AKTUALNIE NA ROWERZE',
                      style: TextStyle(
                        color: AppColors.goldAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    final newWear = _wearState.performHotMeltWaxing(
                      allWeatherFormula:
                          lube == DrivetrainLubricantType.hotMeltWaxAllWeather,
                    );
                    _updateWearAndNotify(
                      newWear,
                      'Mechanicy wygotowali łańcuch w: ${lube.displayName}.',
                    );
                  },
                  icon: const Icon(Icons.soup_kitchen, size: 16),
                  label: const Text('ZASTOSUJ TĘ FORMUŁĘ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceLight,
                    foregroundColor: AppColors.goldAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLubricantDescription(DrivetrainLubricantType lube) {
    switch (lube) {
      case DrivetrainLubricantType.hotMeltWaxStandard:
        return 'Parafina czysta z proszkiem WS2. Najniższe opory w suchych warunkach. Wypłukuje się po ok. 140 km w deszczu.';
      case DrivetrainLubricantType.hotMeltWaxAllWeather:
        return 'Parafina z dodatkiem wosków hydrofobowych i polimerów. Wytrzymuje do 270 km w ulewnym deszczu bez wypłukania.';
      case DrivetrainLubricantType.dripWaxEmulsion:
        return 'Wosk ceramiczny w emulsji wodnej. Łatwy do dolewki przed startem w strefie paddocku.';
      case DrivetrainLubricantType.syntheticWetLube:
        return 'Lepki olej syntetyczny. Nie wypłukuje się, lecz lepi kurz i generuje wyższe straty tarcia (7.2W).';
      case DrivetrainLubricantType.syntheticDryLube:
        return 'Lekki olej PTFE na suchy asfalt. Błyskawicznie zmywany przez kałuże.';
      case DrivetrainLubricantType.strippedNoLube:
        return 'Łańcuch suchy/wypłukany.';
    }
  }

  // =========================================================================
  // ZAKŁADKA 3: CZĘŚCI & STAN ZUŻYCIA
  // =========================================================================
  Widget _buildPartsReplacementTab() {
    final chain = _wearState.chain;
    final rearTire = _wearState.rearTire;
    final frontBrake = _wearState.frontBrake;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'DIAGNOSTYKA CZĘŚCI I AKCJE SERWISOWE',
                style: TextStyle(
                  color: AppColors.goldAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.6,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final newWear = _wearState.performCompleteGrandTourOverhaul();
                  _updateWearAndNotify(
                    newWear,
                    'Wykonano pełny przegląd generalny (Grand Tour Overhaul)! Rower w 100% sprawny.',
                  );
                },
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text('PEŁNY OVERHAUL GT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emeraldGreen,
                  foregroundColor: AppColors.backgroundDark,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildWearComponentCard(
            title: 'Łańcuch Napędu (Shimano Dura-Ace 12s)',
            icon: Icons.link,
            metrics: [
              'Wyciągnięcie: ${chain.chainElongationPercent.toStringAsFixed(2)}% (Limit: 0.50%)',
              'Film woskowy: ${chain.waxFilmRemainingPercent.toStringAsFixed(0)}%',
              'Przebieg: ${chain.totalChainMileageKm.toStringAsFixed(0)} km',
            ],
            progressValue: (chain.chainElongationPercent / 0.75).clamp(0.0, 1.0),
            isAlert: chain.needsReplacement,
            actionLabel: 'WYMIEŃ ŁAŃCUCH',
            onAction: () {
              final newWear = _wearState.replaceChain();
              _updateWearAndNotify(newWear, 'Założono fabrycznie nowy łańcuch.');
            },
          ),
          const SizedBox(height: 14),
          _buildWearComponentCard(
            title: 'Ogumienie (GP5000 S TR Tubeless)',
            icon: Icons.tire_repair,
            metrics: [
              'Zużycie bieżnika tył: ${rearTire.treadWearPercent.toStringAsFixed(0)}%',
              'Mikronacięcia po bruku: ${rearTire.microCutsCount} szt.',
              'Mleczko Tubeless: ${rearTire.tubelessSealantVolumeMl.toStringAsFixed(0)} ml (${rearTire.tubelessSealantFreshnessPercent.toStringAsFixed(0)}% świeżości)',
            ],
            progressValue: (rearTire.treadWearPercent / 100.0).clamp(0.0, 1.0),
            isAlert: rearTire.needsReplacement || rearTire.needsSealantTopUp,
            actionLabel: 'WYMIEŃ OPONY I ZALEJ PŁYN',
            onAction: () {
              var newWear = _wearState.replaceTires(front: true, rear: true);
              newWear = newWear.topUpTubelessSealant(amountMl: 38.0);
              _updateWearAndNotify(newWear, 'Wymieniono komplet opon i zalano 38ml świeżego mleczka.');
            },
          ),
          const SizedBox(height: 14),
          _buildWearComponentCard(
            title: 'Hamulce Tarczowe (${frontBrake.padCompound.displayName})',
            icon: Icons.disc_full_rounded,
            metrics: [
              'Zużycie klocków przód: ${frontBrake.padWearPercent.toStringAsFixed(0)}%',
              'Zeszklenie tarcz: ${frontBrake.rotorGlazingPercent.toStringAsFixed(0)}%',
              'Płyn hydrauliczny: ${frontBrake.hydraulicFluidConditionPercent.toStringAsFixed(0)}%',
            ],
            progressValue: (frontBrake.padWearPercent / 100.0).clamp(0.0, 1.0),
            isAlert: frontBrake.needsPadReplacement || frontBrake.hydraulicFluidConditionPercent < 60.0,
            actionLabel: 'NOWE KLOCKI & ODPOWIETRZENIE',
            onAction: () {
              var newWear = _wearState.replaceBrakePads(
                compound: BrakePadCompound.metallicSintered,
              );
              newWear = newWear.trueRotorsAndBleedHydraulics();
              _updateWearAndNotify(newWear, 'Założono nowe klocki spiekane i odpowietrzono hydraulikę.');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWearComponentCard({
    required String title,
    required IconData icon,
    required List<String> metrics,
    required double progressValue,
    required bool isAlert,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    final progressColor = isAlert
        ? AppColors.crimsonAlert
        : (progressValue > 0.6 ? AppColors.amberWarning : AppColors.emeraldGreen);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlert ? AppColors.crimsonAlert.withAlpha(150) : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: progressColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isAlert)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.crimsonAlert.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'WYMAGA SERWISU',
                    style: TextStyle(
                      color: AppColors.crimsonAlert,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: metrics
                .map((m) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '• $m',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.build_outlined, size: 14),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceLight,
                foregroundColor: AppColors.cyanAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // ZAKŁADKA 4: NOCNA ZMIANA MECHANIKÓW PODCZAS GRAND TOURU
  // =========================================================================
  Widget _buildNightServiceTab() {
    final double totalRequiredHours = _rosterList.fold(
      0.0,
      (sum, item) => sum + item.serviceTier.laborHours,
    );

    final double totalAvailableHours = _mechanicsList.fold(
      0.0,
      (sum, m) => sum + m.maxShiftHours,
    );

    final double workloadRatio = totalRequiredHours / totalAvailableHours;
    final bool isOverworked = workloadRatio > 1.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNightWorkloadHeader(
            totalRequiredHours,
            totalAvailableHours,
            workloadRatio,
            isOverworked,
          ),
          const SizedBox(height: 20),
          const Text(
            'KADRA MECHANIKÓW W TRUCKU SERWISOWYM (4 OSOBY)',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          _buildMechanicsRosterRow(),
          const SizedBox(height: 20),
          const Text(
            'HARMONOGRAM SERWISU DLA 8 ROWERÓW WYŚCIGOWYCH',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          ..._rosterList.map((bikeItem) => _buildRosterBikeCard(bikeItem)),
        ],
      ),
    );
  }

  Widget _buildNightWorkloadHeader(
    double requiredHours,
    double availableHours,
    double workloadRatio,
    bool isOverworked,
  ) {
    final statusColor = isOverworked
        ? AppColors.crimsonAlert
        : (workloadRatio > 0.85 ? AppColors.amberWarning : AppColors.emeraldGreen);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withAlpha(150)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.nightlife_rounded, color: statusColor, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'BILANS ROBOCZOGODZIN NOCNEJ ZMIANY',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                '${requiredHours.toStringAsFixed(1)} h / ${availableHours.toStringAsFixed(1)} h',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: workloadRatio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOverworked
                ? 'PRZECIĄŻENIE ZAŁOGI! Mechanicy będą spać poniżej 4 godzin. Ryzyko niedokręconego koła lub błędu na porannym etapie rośnie o +25%!'
                : 'Załoga ma wystarczająco czasu na odpoczynek i regenerację przed kolejnym etapem Grand Touru.',
            style: TextStyle(
              color: isOverworked ? AppColors.crimsonAlert : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMechanicsRosterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _mechanicsList.map((mechanic) {
          return Container(
            width: 220,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        mechanic.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${mechanic.skillScore}★',
                      style: const TextStyle(
                        color: AppColors.goldAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  mechanic.specialization,
                  style: const TextStyle(color: AppColors.accentBlue, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Text(
                  'Maks. dyżur: ${mechanic.maxShiftHours}h',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRosterBikeCard(GrandTourBikeRosterItem bikeItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: bikeItem.isLeader ? AppColors.goldAccent.withAlpha(120) : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            bikeItem.isLeader ? Icons.star : Icons.pedal_bike,
            color: bikeItem.isLeader ? AppColors.goldAccent : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bikeItem.riderName,
                  style: TextStyle(
                    color: bikeItem.isLeader ? AppColors.goldAccent : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  bikeItem.roleDescription,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          DropdownButton<BikeServiceTier>(
            value: bikeItem.serviceTier,
            dropdownColor: AppColors.surfaceLight,
            underline: const SizedBox(),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
            items: BikeServiceTier.values.map((tier) {
              return DropdownMenuItem<BikeServiceTier>(
                value: tier,
                child: Text('${tier.displayName} (${tier.laborHours}h)'),
              );
            }).toList(),
            onChanged: (newTier) {
              if (newTier != null) {
                setState(() {
                  final idx = _rosterList.indexOf(bikeItem);
                  _rosterList[idx] = bikeItem.copyWith(serviceTier: newTier);
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

/// CustomPainter rysujący asymetryczną krzywą oporów toczenia i impedancji ($Crr$ vs ciśnienie w BAR).
class _TirePressureCrrChartPainter extends CustomPainter {
  final RoadSurfaceCategory surface;
  final double optimalRearBar;
  final double frontBar;
  final double rearBar;
  final double minSafeBar;
  final bool isHookless;

  const _TirePressureCrrChartPainter({
    required this.surface,
    required this.optimalRearBar,
    required this.frontBar,
    required this.rearBar,
    required this.minSafeBar,
    required this.isHookless,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppColors.surfaceLight.withAlpha(80);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      bgPaint,
    );

    const minBar = 1.5;
    const maxBar = 7.5;
    const double barRange = maxBar - minBar;

    double toScreenX(double bar) {
      return ((bar - minBar) / barRange) * size.width;
    }

    // Funkcja kosztu strat oporów (Histereza + Impedancja)
    double calcLossWatts(double bar) {
      final double delta = bar - optimalRearBar;
      if (delta <= 0) {
        // Histereza
        return 16.0 + (delta.abs() * 8.0);
      } else {
        // Impedancja
        final double factor = surface.isCobblestones ? 12.0 : 3.5;
        return 16.0 + (delta * delta * factor);
      }
    }

    const double minW = 10.0;
    const double maxW = 55.0;

    double toScreenY(double watts) {
      final clamped = watts.clamp(minW, maxW);
      final fraction = (clamped - minW) / (maxW - minW);
      return size.height - (fraction * (size.height - 24.0)) - 12.0;
    }

    // 1. Rysowanie bezpiecznej strefy Hookless
    if (isHookless) {
      final hooklessX = toScreenX(5.0);
      final dangerPaint = Paint()..color = AppColors.crimsonAlert.withAlpha(35);
      canvas.drawRect(
        Rect.fromLTRB(hooklessX, 0, size.width, size.height),
        dangerPaint,
      );
    }

    // 2. Rysowanie krzywej Crr
    final curvePath = Path();
    bool first = true;

    for (double b = minBar; b <= maxBar; b += 0.1) {
      final x = toScreenX(b);
      final y = toScreenY(calcLossWatts(b));
      if (first) {
        curvePath.moveTo(x, y);
        first = false;
      } else {
        curvePath.lineTo(x, y);
      }
    }

    final curvePaint = Paint()
      ..color = AppColors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawPath(curvePath, curvePaint);

    // 3. Pionowa linia Breakpoint (Optimum)
    final optX = toScreenX(optimalRearBar);
    final optPaint = Paint()
      ..color = AppColors.emeraldGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(optX, 0), Offset(optX, size.height), optPaint);

    // 4. Punkty dla przedniego koła (Niebieski) i tylnego (Żółty)
    final frontX = toScreenX(frontBar).clamp(0.0, size.width);
    final frontY = toScreenY(calcLossWatts(frontBar));
    final frontPaint = Paint()..color = AppColors.accentBlue;
    canvas.drawCircle(Offset(frontX, frontY), 6.0, frontPaint);
    canvas.drawCircle(Offset(frontX, frontY), 2.5, Paint()..color = Colors.white);

    final rearX = toScreenX(rearBar).clamp(0.0, size.width);
    final rearY = toScreenY(calcLossWatts(rearBar));
    final rearPaint = Paint()..color = AppColors.amberWarning;
    canvas.drawCircle(Offset(rearX, rearY), 6.0, rearPaint);
    canvas.drawCircle(Offset(rearX, rearY), 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _TirePressureCrrChartPainter oldDelegate) {
    return oldDelegate.optimalRearBar != optimalRearBar ||
        oldDelegate.frontBar != frontBar ||
        oldDelegate.rearBar != rearBar ||
        oldDelegate.surface != surface ||
        oldDelegate.isHookless != isHookless;
  }
}
