// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rider/rider.dart';
import '../../services/career/physiology_lab_testing_service.dart';
import '../../services/career/training_and_camps_service.dart';
import '../../services/generators/rider_procedural_generator.dart';
import '../../state/career_controller.dart';
import '../widgets/polar_pedal_force_diagram_painter.dart';
import '../widgets/rider_avatar_painter.dart';

/// Ekran Laboratorium Wydolnościowego i Diagnostyki Fizjologicznej.
///
/// Zawiera:
/// 1. Interaktywny wykres krzywej mleczanowej z dwiema osiami Y:
///    - Oś X: Moc w Watach [W] lub W/kg
///    - Oś Y1 (lewa): Stężenie kwasu mlekowego we krwi włośniczkowej [mmol/l]
///    - Oś Y2 (prawa): Tętno [bpm]
///    - Zaznaczone punkty przegięcia: LT1 (próg tlenowy/FatMax) oraz LT2 (MLSS/OBLA 4.0 mmol/l).
/// 2. Porównanie wyników kolarza z poprzednich miesięcy (np. przed i po obozie wysokogórskim).
/// 3. Przycisk zlecenia nowego badania dla wybranego zawodnika lub kandydata ze skautingu.
/// 4. Szczegółową tabelę stopniową próby (Ramp Test 100W, +30W / 3 min) oraz 7 stref treningowych.
class PhysiologyLabScreen extends ConsumerStatefulWidget {
  final String? initialRiderId;
  final bool showAppBar;

  const PhysiologyLabScreen({
    super.key,
    this.initialRiderId,
    this.showAppBar = true,
  });

  @override
  ConsumerState<PhysiologyLabScreen> createState() => _PhysiologyLabScreenState();
}

class _PhysiologyLabScreenState extends ConsumerState<PhysiologyLabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Aktywny kolarz i wygenerowany raport badania
  late Rider _selectedRider;
  PhysiologyLabTestReport? _currentReport;
  PhysiologyLabTestReport? _comparisonReport;

  // Lista kolarzy zespołu oraz kandydatów ze skautingu
  List<Rider> _squadRiders = [];
  List<Rider> _scoutingCandidates = [];

  // Ustawienia widoku wykresu
  bool _useWKg = false;
  bool _showLactateSeries = true;
  bool _showHeartRateSeries = true;
  bool _showVentilationSeries = false;
  bool _showVo2Series = false;
  bool _showComparisonOverlay = true;

  // Kursor scrubbingowy wykresu
  double? _hoveredPowerWatts;

  // Wybrana baza do porównania
  String _selectedComparisonPeriod = 'Przed Obozem Wysokogórskim';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeData() {
    final careerState = ref.read(careerControllerProvider);
    final save = careerState.save;

    if (save != null && save.riders.isNotEmpty) {
      final teamRiders = save.riders.where((r) => r.contract.teamId == save.playerTeamId).toList();
      _squadRiders = teamRiders.isNotEmpty ? teamRiders : save.riders.take(8).toList();

      if (save.scoutingProspects.isNotEmpty) {
        _scoutingCandidates = save.scoutingProspects.map((p) => p.trueRider).toList();
      } else {
        _scoutingCandidates = _generateDemoScoutingCandidates();
      }
    } else {
      _squadRiders = _generateDemoSquad();
      _scoutingCandidates = _generateDemoScoutingCandidates();
    }

    if (widget.initialRiderId != null) {
      final found = _squadRiders.firstWhere(
        (r) => r.id == widget.initialRiderId,
        orElse: () => _scoutingCandidates.firstWhere(
          (r) => r.id == widget.initialRiderId,
          orElse: () => _squadRiders.first,
        ),
      );
      _selectedRider = found;
    } else {
      _selectedRider = _squadRiders.first;
    }

    _runInitialSimulatedTest(_selectedRider);
  }

  void _runInitialSimulatedTest(Rider rider) {
    // Generujemy aktualny raport z badania laboratoryjnego
    _currentReport = PhysiologyLabTestingService.conductRampTest(
      rider: rider,
      testDate: DateTime.now(),
      recentFocus: RiderTrainingFocus.baseBuilding,
    );

    // Generujemy raport historyczny sprzed 45 dni (np. przed obozem wysokogórskim) do porównania
    final baselineLabProfile = rider.labProfile.copyWith(
      vlaMaxMmolLPerSec: rider.specialization == RiderSpecialization.pureSprinter
          ? (rider.labProfile.vlaMaxMmolLPerSec - 0.05).clamp(0.40, 0.95)
          : (rider.labProfile.vlaMaxMmolLPerSec + 0.06).clamp(0.20, 0.95),
      lt1Watts: (rider.labProfile.lt1Watts - 14).clamp(140, 480),
      lt2Watts: (rider.labProfile.lt2Watts - 18).clamp(200, 500),
      vo2MaxMlKgMin: (rider.labProfile.vo2MaxMlKgMin - 2.0).clamp(50.0, 94.0),
      powerAtVo2MaxWatts: (rider.labProfile.powerAtVo2MaxWatts - 22).clamp(240, 600),
      grossEfficiencyPercent: (rider.labProfile.grossEfficiencyPercent - 0.6).clamp(19.0, 25.0),
    );

    _comparisonReport = PhysiologyLabTestingService.conductRampTest(
      rider: rider.copyWith(
        physiology: rider.physiology.copyWith(labProfile: baselineLabProfile),
      ),
      testDate: DateTime.now().subtract(const Duration(days: 45)),
    );
  }

  void _updateComparisonPeriod(String period) {
    setState(() {
      _selectedComparisonPeriod = period;
      int daysAgo = 45;
      double vlaDelta = 0.05;
      int ftpDelta = 16;
      double vo2Delta = 1.8;

      if (period == 'Screening Przedsezonowy') {
        daysAgo = 90;
        vlaDelta = 0.08;
        ftpDelta = 26;
        vo2Delta = 3.2;
      } else if (period == 'Baza z Początku Sezonu') {
        daysAgo = 120;
        vlaDelta = 0.11;
        ftpDelta = 34;
        vo2Delta = 4.2;
      }

      final rider = _selectedRider;
      final baselineLabProfile = rider.labProfile.copyWith(
        vlaMaxMmolLPerSec: rider.specialization == RiderSpecialization.pureSprinter
            ? (rider.labProfile.vlaMaxMmolLPerSec - vlaDelta).clamp(0.40, 0.95)
            : (rider.labProfile.vlaMaxMmolLPerSec + vlaDelta).clamp(0.20, 0.95),
        lt1Watts: (rider.labProfile.lt1Watts - (ftpDelta * 0.8).round()).clamp(140, 480),
        lt2Watts: (rider.labProfile.lt2Watts - ftpDelta).clamp(200, 500),
        vo2MaxMlKgMin: (rider.labProfile.vo2MaxMlKgMin - vo2Delta).clamp(50.0, 94.0),
        powerAtVo2MaxWatts: (rider.labProfile.powerAtVo2MaxWatts - (ftpDelta * 1.2).round()).clamp(240, 600),
        grossEfficiencyPercent: (rider.labProfile.grossEfficiencyPercent - 0.7).clamp(19.0, 25.0),
      );

      _comparisonReport = PhysiologyLabTestingService.conductRampTest(
        rider: rider.copyWith(
          physiology: rider.physiology.copyWith(labProfile: baselineLabProfile),
        ),
        testDate: DateTime.now().subtract(Duration(days: daysAgo)),
      );
    });
  }

  List<Rider> _generateDemoSquad() {
    return [
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.gcClimber,
        targetOverallRating: 89,
      ),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.pureClimber,
        targetOverallRating: 86,
      ),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.timeTrialist,
        targetOverallRating: 87,
      ),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.pureSprinter,
        targetOverallRating: 88,
      ),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.puncher,
        targetOverallRating: 85,
      ),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.domestiqueEngine,
        targetOverallRating: 82,
      ),
    ];
  }

  List<Rider> _generateDemoScoutingCandidates() {
    return [
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.gcClimber,
        targetOverallRating: 78,
      ),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.pureSprinter,
        targetOverallRating: 77,
      ),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.timeTrialist,
        targetOverallRating: 79,
      ),
    ];
  }

  void _onSelectRider(Rider rider) {
    setState(() {
      _selectedRider = rider;
      _hoveredPowerWatts = null;
      _runInitialSimulatedTest(rider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final report = _currentReport;
    if (report == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar ? _buildAppBar(context) : null,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Karuzela wyboru kolarza (Kadra vs Skauting)
            _buildRiderSelectorBar(),

            // 2. Główna zawartość z zakładkami
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Kafelki wskaźników fizjologicznych na żywo (LT1, LT2, VO2max, VLaMax)
                    _buildHeroMetricsGrid(report),
                    const SizedBox(height: 16),

                    // Sekcja interaktywnego wykresu krzywej mleczanowej
                    _buildLactateChartCard(report),
                    const SizedBox(height: 16),

                    // Pasek zakładek szczegółowych
                    _buildSubTabs(),
                    const SizedBox(height: 14),

                    // Zawartość wybranej pod-zakładki
                    _buildTabContent(report),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // NAGŁÓWEK I APPBRA
  // ===========================================================================

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.powerZone4.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.powerZone4.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.science_rounded, color: AppColors.powerZone4, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Laboratorium Wydolnościowe',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'Ergospirometria CPET & Kinetyka Mleczanowa (Ramp Test 100W, +30W/3min)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Przycisk zlecenia nowego badania
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldAccent,
              foregroundColor: Colors.black,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.biotech_rounded, size: 18),
            label: const Text(
              'Zleć Nowe Badanie',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _showOrderNewTestModal(context),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 1. WYBÓR KOLARZA (KADRA VS KANDYDACI ZE SKAUTINGU)
  // ===========================================================================

  Widget _buildRiderSelectorBar() {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _squadRiders.length + _scoutingCandidates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSquad = index < _squadRiders.length;
          final rider = isSquad
              ? _squadRiders[index]
              : _scoutingCandidates[index - _squadRiders.length];
          final isSelected = rider.id == _selectedRider.id;

          return InkWell(
            onTap: () => _onSelectRider(rider),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.goldAccent.withValues(alpha: 0.16)
                    : AppColors.surfaceLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.goldAccent : AppColors.cardBorder,
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RiderAvatarWidget(
                    appearance: rider.appearance,
                    size: 42,
                    showHelmet: false,
                    showGlasses: false,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            rider.lastName,
                            style: TextStyle(
                              color: isSelected ? AppColors.goldAccent : AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (!isSquad)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.cyanAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SKAUT',
                                style: TextStyle(
                                  color: AppColors.cyanAccent,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '${rider.specialization.displayName} • ${rider.physiology.ftpWatts}W',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
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
    );
  }

  // ===========================================================================
  // 2. KAFELKI WSKAŹNIKÓW FIZJOLOGICZNYCH (HERO GRID)
  // ===========================================================================

  Widget _buildHeroMetricsGrid(PhysiologyLabTestReport report) {
    final lab = report.newLabProfile;

    return Row(
      children: [
        _buildHeroMetricCard(
          title: 'PRÓG TLENOWY (LT₁ / FatMax)',
          value: '${report.measuredLt1Watts} W',
          subValue: '${report.measuredLt1WattsPerKg.toStringAsFixed(2)} W/kg',
          desc: 'Mleczan: ${report.measuredLt1Lactate.toStringAsFixed(1)} mmol/l • VE: ${report.measuredLt1Ventilation} l/min',
          icon: Icons.energy_savings_leaf_rounded,
          accentColor: AppColors.powerZone2,
        ),
        const SizedBox(width: 12),
        _buildHeroMetricCard(
          title: 'PRÓG BEZTLENOWY (LT₂ / MLSS)',
          value: '${report.measuredLt2Watts} W',
          subValue: '${report.measuredLt2WattsPerKg.toStringAsFixed(2)} W/kg',
          desc: 'Mleczan: ${report.measuredLt2Lactate.toStringAsFixed(1)} mmol/l (OBLA) • ${report.measuredLt2Hr} bpm',
          icon: Icons.bolt_rounded,
          accentColor: AppColors.powerZone4,
        ),
        const SizedBox(width: 12),
        _buildHeroMetricCard(
          title: 'PUŁAP TLENOWY (VO₂max)',
          value: report.measuredVo2MaxMlKgMin.toStringAsFixed(1),
          subValue: 'ml/kg/min',
          desc: '${report.measuredVo2MaxLitersMin.toStringAsFixed(2)} l/min • MAP: ${report.measuredMaxAerobicPowerWatts}W',
          icon: Icons.air_rounded,
          accentColor: AppColors.cyanAccent,
        ),
        const SizedBox(width: 12),
        _buildHeroMetricCard(
          title: 'GLIKOLIZA (VLaMax)',
          value: report.measuredVlaMax.toStringAsFixed(2),
          subValue: 'mmol/l/s',
          desc: lab.metabolicPhenotype.displayName,
          icon: Icons.local_fire_department_rounded,
          accentColor: lab.isSprinterPhenotype ? AppColors.powerZone6 : AppColors.emeraldGreen,
        ),
      ],
    );
  }

  Widget _buildHeroMetricCard({
    required String title,
    required String value,
    required String subValue,
    required String desc,
    required IconData icon,
    required Color accentColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subValue,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. INTERAKTYWNY WYKRES KRZYWEJ MLECZANOWEJ (LACTATE & HR CURVE)
  // ===========================================================================

  Widget _buildLactateChartCard(PhysiologyLabTestReport report) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pasek narzędziowy wykresu (nagłówek, przełączniki serii, jednostki W vs W/kg)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.show_chart_rounded, color: AppColors.goldAccent, size: 20),
                  const Text(
                    'Krzywa Kinetyki Kwasu Mlekowego & Tętna',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Pigułka LT1
                  _buildLegendPill('LT₁ ~1.8 mmol/l', AppColors.powerZone2),
                  // Pigułka LT2 / OBLA
                  _buildLegendPill('LT₂ / OBLA 4.0 mmol/l', AppColors.powerZone4),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Przełącznik W vs W/kg
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildUnitToggleOption('Waty [W]', !_useWKg, () => setState(() => _useWKg = false)),
                        _buildUnitToggleOption('W/kg', _useWKg, () => setState(() => _useWKg = true)),
                      ],
                    ),
                  ),
                  // Przełącznik nałożenia poprzedniego badania
                  FilterChip(
                    label: const Text('Porównanie z bazą'),
                    selected: _showComparisonOverlay,
                    onSelected: (val) => setState(() => _showComparisonOverlay = val),
                    backgroundColor: AppColors.backgroundDark,
                    selectedColor: AppColors.cyanAccent.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.cyanAccent,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: _showComparisonOverlay ? AppColors.cyanAccent : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pasek wyboru aktywnych serii (Mleczan, Tętno, Wentylacja, VO2)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSeriesFilterChip('Mleczan [La] (mmol/l)', AppColors.goldAccent, _showLactateSeries,
                  (val) => setState(() => _showLactateSeries = val)),
              _buildSeriesFilterChip('Tętno HR (bpm)', AppColors.crimsonAlert, _showHeartRateSeries,
                  (val) => setState(() => _showHeartRateSeries = val)),
              _buildSeriesFilterChip('Wentylacja VE (l/min)', AppColors.cyanAccent, _showVentilationSeries,
                  (val) => setState(() => _showVentilationSeries = val)),
              _buildSeriesFilterChip('Pobór VO₂ (ml/kg/min)', AppColors.emeraldGreen, _showVo2Series,
                  (val) => setState(() => _showVo2Series = val)),
            ],
          ),
          const SizedBox(height: 16),

          // Główny płótno wykresu CustomPainter
          SizedBox(
            height: 380,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onHorizontalDragUpdate: (details) => _handleChartTouch(details.localPosition.dx, constraints.maxWidth),
                  onTapDown: (details) => _handleChartTouch(details.localPosition.dx, constraints.maxWidth),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 380),
                    painter: _InteractiveLactateCurvePainter(
                      currentReport: report,
                      comparisonReport: _showComparisonOverlay ? _comparisonReport : null,
                      useWKg: _useWKg,
                      showLactate: _showLactateSeries,
                      showHeartRate: _showHeartRateSeries,
                      showVentilation: _showVentilationSeries,
                      showVo2: _showVo2Series,
                      hoveredPowerWatts: _hoveredPowerWatts,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleChartTouch(double localX, double totalWidth) {
    final report = _currentReport;
    if (report == null || report.steps.isEmpty) return;

    const double chartLeft = 55.0;
    final double chartRight = totalWidth - 55.0;
    final double chartWidth = chartRight - chartLeft;

    if (localX < chartLeft || localX > chartRight) return;

    final double fraction = (localX - chartLeft) / chartWidth;
    final double minPower = report.steps.first.powerWatts.toDouble();
    final double maxPower = report.steps.last.powerWatts.toDouble();
    final double targetPower = minPower + fraction * (maxPower - minPower);

    setState(() {
      _hoveredPowerWatts = targetPower;
    });
  }

  Widget _buildLegendPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUnitToggleOption(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldAccent.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSeriesFilterChip(String label, Color color, bool isSelected, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () => onChanged(!isSelected),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. ZAKŁADKI SZCZEGÓŁOWE
  // ===========================================================================

  Widget _buildSubTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.goldAccent,
        labelColor: AppColors.goldAccent,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        tabs: const [
          Tab(
            icon: Icon(Icons.compare_arrows_rounded, size: 18),
            text: 'Porównanie z Poprzednich Miesięcy',
          ),
          Tab(
            icon: Icon(Icons.table_rows_rounded, size: 18),
            text: 'Tabela Stopni Ramp Test (100W, +30W/3min)',
          ),
          Tab(
            icon: Icon(Icons.speed_rounded, size: 18),
            text: 'Strefy Treningowe Z1-Z7',
          ),
          Tab(
            icon: Icon(Icons.radar_rounded, size: 18),
            text: 'Biomechanika 360° (Polar View)',
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(PhysiologyLabTestReport report) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        switch (_tabController.index) {
          case 0:
            return _buildComparisonTab(report);
          case 1:
            return _buildProtocolStepsTable(report);
          case 2:
            return _buildTrainingZonesTab(report);
          case 3:
            return PolarPedalForceDiagramWidget(rider: _selectedRider);
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  // ===========================================================================
  // ZAKŁADKA 1: PORÓWNANIE Z POPRZEDNICH MIESIĘCY
  // ===========================================================================

  Widget _buildComparisonTab(PhysiologyLabTestReport report) {
    final trend = report.trendAnalysis;
    final comp = _comparisonReport;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Wybór okresu historycznego do porównania
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded, color: AppColors.cyanAccent, size: 18),
                SizedBox(width: 8),
                Text(
                  'Okres Odniesienia:',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedComparisonPeriod,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w600),
                  items: const [
                    DropdownMenuItem(
                      value: 'Przed Obozem Wysokogórskim',
                      child: Text('Przed Obozem w Sierra Nevada (45 dni temu)'),
                    ),
                    DropdownMenuItem(
                      value: 'Screening Przedsezonowy',
                      child: Text('Screening Przedsezonowy (90 dni temu)'),
                    ),
                    DropdownMenuItem(
                      value: 'Baza z Początku Sezonu',
                      child: Text('Baza z Początku Sezonu (120 dni temu)'),
                    ),
                  ],
                  onChanged: (newVal) {
                    if (newVal != null) {
                      _updateComparisonPeriod(newVal);
                    }
                  },
                ),
              ),
            ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Karta werdyktu adaptacyjnego i diagnozy sztabu
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: trend.isTrainingGoingInRightDirection
                ? AppColors.emeraldGreen.withValues(alpha: 0.08)
                : AppColors.crimsonAlert.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: trend.isTrainingGoingInRightDirection
                  ? AppColors.emeraldGreen.withValues(alpha: 0.3)
                  : AppColors.crimsonAlert.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    trend.isTrainingGoingInRightDirection
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    color: trend.isTrainingGoingInRightDirection
                        ? AppColors.emeraldGreen
                        : AppColors.crimsonAlert,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      trend.verdict.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: trend.isTrainingGoingInRightDirection
                            ? AppColors.emeraldGreen
                            : AppColors.crimsonAlert,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      'Adaptation Score: ${trend.adaptationScore}/100',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                trend.verdictSummary,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 10),
              Text(
                report.diagnosticSummary,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Siatka porównawcza parametrów przed i po (Delta Grid)
        if (comp != null) ...[
          Row(
            children: [
              _buildDeltaCard(
                title: 'PRÓG TLENOWY LT₁',
                currentVal: '${report.measuredLt1Watts} W (${report.measuredLt1WattsPerKg.toStringAsFixed(2)} W/kg)',
                prevVal: '${comp.measuredLt1Watts} W (${comp.measuredLt1WattsPerKg.toStringAsFixed(2)} W/kg)',
                deltaVal: '+${report.measuredLt1Watts - comp.measuredLt1Watts} W',
                isPositive: report.measuredLt1Watts >= comp.measuredLt1Watts,
              ),
              const SizedBox(width: 12),
              _buildDeltaCard(
                title: 'PRÓG BEZTLENOWY LT₂ / MLSS',
                currentVal: '${report.measuredLt2Watts} W (${report.measuredLt2WattsPerKg.toStringAsFixed(2)} W/kg)',
                prevVal: '${comp.measuredLt2Watts} W (${comp.measuredLt2WattsPerKg.toStringAsFixed(2)} W/kg)',
                deltaVal: '+${report.measuredLt2Watts - comp.measuredLt2Watts} W',
                isPositive: report.measuredLt2Watts >= comp.measuredLt2Watts,
              ),
              const SizedBox(width: 12),
              _buildDeltaCard(
                title: 'PUŁAP TLENOWY VO₂max',
                currentVal: '${report.measuredVo2MaxMlKgMin.toStringAsFixed(1)} ml/kg/min',
                prevVal: '${comp.measuredVo2MaxMlKgMin.toStringAsFixed(1)} ml/kg/min',
                deltaVal: '${trend.vo2MaxDeltaMlKgMin >= 0 ? "+" : ""}${trend.vo2MaxDeltaMlKgMin} ml',
                isPositive: trend.vo2MaxDeltaMlKgMin >= 0,
              ),
              const SizedBox(width: 12),
              _buildDeltaCard(
                title: 'GLIKOLIZA VLaMax',
                currentVal: '${report.measuredVlaMax.toStringAsFixed(2)} mmol/l/s',
                prevVal: '${comp.measuredVlaMax.toStringAsFixed(2)} mmol/l/s',
                deltaVal: '${trend.vlaMaxDeltaMmolLPerSec >= 0 ? "+" : ""}${trend.vlaMaxDeltaMmolLPerSec} mmol',
                isPositive: _selectedRider.specialization == RiderSpecialization.pureSprinter
                    ? trend.vlaMaxDeltaMmolLPerSec >= 0
                    : trend.vlaMaxDeltaMmolLPerSec <= 0, // Dla górala spadek VLaMax to sukces!
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Rekomendacje szkoleniowe
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
              const Row(
                children: [
                  Icon(Icons.assignment_turned_in_rounded, color: AppColors.goldAccent, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Zalecenia Sztabu Szkoleniowego i Fizjologii',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...report.coachRecommendations.map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: AppColors.goldAccent, fontSize: 16)),
                      Expanded(
                        child: Text(
                          rec,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeltaCard({
    required String title,
    required String currentVal,
    required String prevVal,
    required String deltaVal,
    required bool isPositive,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              currentVal,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 2,
              children: [
                Text(
                  'Baza: $prevVal',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? AppColors.emeraldGreen.withValues(alpha: 0.18)
                        : AppColors.crimsonAlert.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    deltaVal,
                    style: TextStyle(
                      color: isPositive ? AppColors.emeraldGreen : AppColors.crimsonAlert,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ZAKŁADKA 2: TABELA STOPNI RAMP TEST (100W, +30W/3min)
  // ===========================================================================

  Widget _buildProtocolStepsTable(PhysiologyLabTestReport report) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Table(
          border: TableBorder(
            horizontalInside: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.5)),
          ),
          columnWidths: const {
            0: FlexColumnWidth(1.2), // Stopień
            1: FlexColumnWidth(1.5), // Czas
            2: FlexColumnWidth(1.8), // Moc
            3: FlexColumnWidth(1.6), // Mleczan
            4: FlexColumnWidth(1.6), // Tętno
            5: FlexColumnWidth(1.8), // VE (l/min)
            6: FlexColumnWidth(1.8), // VO2
            7: FlexColumnWidth(1.4), // RER
            8: FlexColumnWidth(2.0), // Węgle vs Tłuszcz
          },
          children: [
            // Nagłówek tabeli
            TableRow(
              decoration: BoxDecoration(color: AppColors.backgroundDark.withValues(alpha: 0.6)),
              children: const [
                _TableHeaderCell('KROK'),
                _TableHeaderCell('CZAS'),
                _TableHeaderCell('MOC (W/kg)'),
                _TableHeaderCell('MLECZAN'),
                _TableHeaderCell('TĘTNO'),
                _TableHeaderCell('VE [l/min]'),
                _TableHeaderCell('VO₂ [ml]'),
                _TableHeaderCell('RER'),
                _TableHeaderCell('SPALANIE (W/T)'),
              ],
            ),
            // Wiersze ze stopniami pomiarowymi
            ...report.steps.map((step) {
              final isLt1Step = step.powerWatts == report.measuredLt1Watts ||
                  (step.powerWatts < report.measuredLt1Watts && step.powerWatts + 30 > report.measuredLt1Watts);
              final isLt2Step = step.powerWatts == report.measuredLt2Watts ||
                  (step.powerWatts < report.measuredLt2Watts && step.powerWatts + 30 > report.measuredLt2Watts);

              Color? rowColor;
              if (isLt2Step) {
                rowColor = AppColors.powerZone4.withValues(alpha: 0.12);
              } else if (isLt1Step) {
                rowColor = AppColors.powerZone2.withValues(alpha: 0.12);
              }

              final mm = (step.elapsedSeconds ~/ 60).toString().padLeft(2, '0');
              final ss = (step.elapsedSeconds % 60).toString().padLeft(2, '0');

              return TableRow(
                decoration: BoxDecoration(color: rowColor),
                children: [
                  _TableCell('#${step.stepNumber}'),
                  _TableCell('$mm:$ss min'),
                  _TableCell('${step.powerWatts}W (${step.wattsPerKg} W/kg)', isBold: true),
                  _TableCell(
                    '${step.bloodLactateMmolL.toStringAsFixed(2)} mmol/l',
                    textColor: step.bloodLactateMmolL >= 4.0
                        ? AppColors.powerZone4
                        : (step.bloodLactateMmolL >= 1.8 ? AppColors.powerZone3 : AppColors.textPrimary),
                    isBold: isLt1Step || isLt2Step,
                  ),
                  _TableCell('${step.heartRateBpm} bpm'),
                  _TableCell('${step.minuteVentilationVE} l/min'),
                  _TableCell(step.oxygenUptakeVO2MlKgMin.toStringAsFixed(1)),
                  _TableCell(step.respiratoryExchangeRatioRER.toStringAsFixed(2)),
                  _TableCell('${step.carbOxidationGramsPerHour.round()}g / ${step.fatOxidationGramsPerHour.round()}g'),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ZAKŁADKA 3: STREFY TRENINGOWE Z1-Z7
  // ===========================================================================

  Widget _buildTrainingZonesTab(PhysiologyLabTestReport report) {
    return Column(
      children: report.trainingZones.map((zone) {
        Color zoneColor;
        switch (zone.zoneIndex) {
          case 1:
            zoneColor = AppColors.powerZone1;
            break;
          case 2:
            zoneColor = AppColors.powerZone2;
            break;
          case 3:
            zoneColor = AppColors.powerZone3;
            break;
          case 4:
            zoneColor = AppColors.powerZone4;
            break;
          case 5:
            zoneColor = AppColors.powerZone5;
            break;
          case 6:
            zoneColor = AppColors.powerZone6;
            break;
          case 7:
          default:
            zoneColor = AppColors.powerZone7;
            break;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: zoneColor.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: zoneColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: zoneColor),
                ),
                alignment: Alignment.center,
                child: Text(
                  zone.code,
                  style: TextStyle(
                    color: zoneColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          zone.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${zone.minWatts} - ${zone.maxWatts} W',
                          style: TextStyle(
                            color: zoneColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      zone.physiologicalAdaptation,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Tętno: ${zone.minHeartRateBpm > 0 ? "${zone.minHeartRateBpm} - " : "< "}${zone.maxHeartRateBpm} bpm',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Typowy mleczan: ~${zone.typicalLactateMmolL.toStringAsFixed(1)} mmol/l',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // 5. MODAL ZLECENIA NOWEGO BADANIA LABORATORYJNEGO
  // ===========================================================================

  void _showOrderNewTestModal(BuildContext context) {
    Rider candidate = _selectedRider;
    RiderTrainingFocus focus = RiderTrainingFocus.baseBuilding;
    int testCost = 450;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.biotech_rounded, color: AppColors.goldAccent, size: 24),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Zlecenie Badania Laboratoryjnego',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(modalContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Wybór kolarza (Kadra lub Skauting)
                  const Text('Wybierz Zawodnika:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Rider>(
                        value: candidate,
                        dropdownColor: AppColors.surface,
                        isExpanded: true,
                        items: [
                          ..._squadRiders.map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text('${r.fullName} (${r.specialization.displayName}) - Kadra'),
                            ),
                          ),
                          ..._scoutingCandidates.map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text('${r.fullName} (${r.specialization.displayName}) - [SKAUTING]'),
                            ),
                          ),
                        ],
                        onChanged: (newRider) {
                          if (newRider != null) {
                            setModalState(() => candidate = newRider);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Protokół badania
                  const Text('Protokół Diagnostyczny:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.directions_bike_rounded, color: AppColors.goldAccent, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ramp Test (100W, +30W / 3 min) + Ergospirometria CPET + Mleczan',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Ostatnio realizowany blok treningowy (do symulacji adaptacji)
                  const Text('Kontekst Przygotowań (Ostatni Blok):',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<RiderTrainingFocus>(
                        value: focus,
                        dropdownColor: AppColors.surface,
                        isExpanded: true,
                        items: RiderTrainingFocus.values.map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(f.label),
                          ),
                        ).toList(),
                        onChanged: (newFocus) {
                          if (newFocus != null) {
                            setModalState(() => focus = newFocus);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Koszt i potwierdzenie
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Koszt Badania:', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          Text(
                            '€$testCost',
                            style: const TextStyle(
                              color: AppColors.goldAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text(
                          'Rozpocznij Badanie',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: () {
                          Navigator.of(modalContext).pop();
                          _executeNewLabTest(candidate, focus);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _executeNewLabTest(Rider rider, RiderTrainingFocus focus) {
    // Przeprowadzamy nowe badanie z uwzględnieniem dotychczasowego profilu
    final previous = rider.labProfile;
    final newReport = PhysiologyLabTestingService.conductRampTest(
      rider: rider,
      testDate: DateTime.now(),
      recentFocus: focus,
      previousProfile: previous,
    );

    // Aktualizujemy kolarza w aplikacji
    final updatedRider = PhysiologyLabTestingService.applyReportToRider(rider, newReport);

    setState(() {
      _selectedRider = updatedRider;
      _currentReport = newReport;
      _comparisonReport = PhysiologyLabTestingService.conductRampTest(
        rider: rider,
        testDate: DateTime.now().subtract(const Duration(days: 45)),
      );
      _hoveredPowerWatts = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.statusSuccess),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Badanie ukończone dla ${updatedRider.fullName}! Nowy próg LT2: ${newReport.measuredLt2Watts}W (VO2max: ${newReport.measuredVo2MaxMlKgMin.toStringAsFixed(1)})',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// INTERAKTYWNY CUSTOM PAINTER KRZYWEJ MLECZANOWEJ (LACTATE & HR CURVE)
// =============================================================================

class _InteractiveLactateCurvePainter extends CustomPainter {
  final PhysiologyLabTestReport currentReport;
  final PhysiologyLabTestReport? comparisonReport;
  final bool useWKg;
  final bool showLactate;
  final bool showHeartRate;
  final bool showVentilation;
  final bool showVo2;
  final double? hoveredPowerWatts;

  _InteractiveLactateCurvePainter({
    required this.currentReport,
    this.comparisonReport,
    required this.useWKg,
    required this.showLactate,
    required this.showHeartRate,
    required this.showVentilation,
    required this.showVo2,
    this.hoveredPowerWatts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 55.0;
    const double paddingRight = 55.0;
    const double paddingTop = 30.0;
    const double paddingBottom = 45.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    final double weightKg = currentReport.weightKg > 0 ? currentReport.weightKg : 70.0;
    final double minPower = currentReport.steps.first.powerWatts.toDouble();
    final double maxPower = currentReport.steps.last.powerWatts.toDouble();
    final double powerSpan = math.max(50.0, maxPower - minPower);

    // Zakresy osi Y1 (mleczan): 0.0 - 14.0 mmol/l
    const double maxLactateY = 14.0;
    // Zakresy osi Y2 (tętno): 80 - 200 bpm
    const double minHrY = 80.0;
    const double maxHrY = 205.0;

    // 1. Rysowanie siatki i etykiet osi
    _drawGridAndAxes(
      canvas,
      paddingLeft: paddingLeft,
      paddingTop: paddingTop,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      minPower: minPower,
      maxPower: maxPower,
      weightKg: weightKg,
    );

    // 2. Rysowanie pionowych linii progów fizjologicznych LT1 i LT2
    _drawThresholdLines(
      canvas,
      paddingLeft: paddingLeft,
      paddingTop: paddingTop,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      minPower: minPower,
      powerSpan: powerSpan,
      weightKg: weightKg,
    );

    // 3. Rysowanie krzywej historycznej do porównania (jeśli dostępna)
    if (comparisonReport != null) {
      _drawHistoricalLactateCurve(
        canvas,
        compReport: comparisonReport!,
        paddingLeft: paddingLeft,
        paddingTop: paddingTop,
        chartWidth: chartWidth,
        chartHeight: chartHeight,
        minPower: minPower,
        powerSpan: powerSpan,
      );
    }

    // 4. Rysowanie głównych krzywych bieżącego badania
    if (showVentilation) {
      _drawVentilationCurve(canvas, paddingLeft, paddingTop, chartWidth, chartHeight, minPower, powerSpan);
    }
    if (showVo2) {
      _drawVo2Curve(canvas, paddingLeft, paddingTop, chartWidth, chartHeight, minPower, powerSpan);
    }
    if (showHeartRate) {
      _drawHeartRateCurve(canvas, paddingLeft, paddingTop, chartWidth, chartHeight, minPower, powerSpan, minHrY, maxHrY);
    }
    if (showLactate) {
      _drawLactateCurve(canvas, paddingLeft, paddingTop, chartWidth, chartHeight, minPower, powerSpan, maxLactateY);
    }

    // 5. Interaktywny kursor scrubbingowy i okienko tooltipa
    if (hoveredPowerWatts != null) {
      _drawScrubbingCrosshair(
        canvas,
        size: size,
        paddingLeft: paddingLeft,
        paddingTop: paddingTop,
        chartWidth: chartWidth,
        chartHeight: chartHeight,
        minPower: minPower,
        powerSpan: powerSpan,
        weightKg: weightKg,
      );
    }
  }

  void _drawGridAndAxes(
    Canvas canvas, {
    required double paddingLeft,
    required double paddingTop,
    required double chartWidth,
    required double chartHeight,
    required double minPower,
    required double maxPower,
    required double weightKg,
  }) {
    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    final axisPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 1.2;

    // Poziome linie siatki (dla mleczanu: 2, 4, 6, 8, 10, 12, 14 mmol/l)
    for (int la = 2; la <= 14; la += 2) {
      final double y = paddingTop + chartHeight * (1.0 - (la / 14.0));
      canvas.drawLine(Offset(paddingLeft, y), Offset(paddingLeft + chartWidth, y), gridPaint);

      // Etykieta osi Y1 (mleczan mmol/l po lewej)
      _drawText(
        canvas,
        '$la',
        Offset(paddingLeft - 8, y),
        alignment: Alignment.centerRight,
        color: AppColors.goldAccent.withValues(alpha: 0.8),
        fontSize: 10,
        fontWeight: la == 4 ? FontWeight.bold : FontWeight.normal,
      );

      // Etykieta osi Y2 (tętno bpm po prawej: 80 - 200)
      final int hrVal = 80 + ((la / 14.0) * (200 - 80)).round();
      _drawText(
        canvas,
        '$hrVal bpm',
        Offset(paddingLeft + chartWidth + 8, y),
        alignment: Alignment.centerLeft,
        color: AppColors.crimsonAlert.withValues(alpha: 0.8),
        fontSize: 10,
      );
    }

    // Pionowe linie siatki (kroki mocy)
    for (final step in currentReport.steps) {
      final double x = paddingLeft + ((step.powerWatts - minPower) / (maxPower - minPower)) * chartWidth;
      canvas.drawLine(Offset(x, paddingTop), Offset(x, paddingTop + chartHeight), gridPaint);

      // Etykieta mocy na osi X
      final String label = useWKg
          ? (step.powerWatts / weightKg).toStringAsFixed(1)
          : '${step.powerWatts}W';

      _drawText(
        canvas,
        label,
        Offset(x, paddingTop + chartHeight + 10),
        alignment: Alignment.topCenter,
        color: AppColors.textSecondary,
        fontSize: 10,
      );
    }

    // Osie główne
    canvas.drawLine(Offset(paddingLeft, paddingTop), Offset(paddingLeft, paddingTop + chartHeight), axisPaint);
    canvas.drawLine(Offset(paddingLeft + chartWidth, paddingTop),
        Offset(paddingLeft + chartWidth, paddingTop + chartHeight), axisPaint);
    canvas.drawLine(Offset(paddingLeft, paddingTop + chartHeight),
        Offset(paddingLeft + chartWidth, paddingTop + chartHeight), axisPaint);

    // Tytuły osi
    _drawText(
      canvas,
      'Mleczan [mmol/l]',
      Offset(paddingLeft - 30, paddingTop - 16),
      alignment: Alignment.topLeft,
      color: AppColors.goldAccent,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    _drawText(
      canvas,
      'Tętno [bpm]',
      Offset(paddingLeft + chartWidth + 30, paddingTop - 16),
      alignment: Alignment.topRight,
      color: AppColors.crimsonAlert,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );
  }

  void _drawThresholdLines(
    Canvas canvas, {
    required double paddingLeft,
    required double paddingTop,
    required double chartWidth,
    required double chartHeight,
    required double minPower,
    required double powerSpan,
    required double weightKg,
  }) {
    // 1. Linia LT1 (Próg tlenowy / FatMax)
    final double lt1X = paddingLeft + ((currentReport.measuredLt1Watts - minPower) / powerSpan) * chartWidth;
    if (lt1X >= paddingLeft && lt1X <= paddingLeft + chartWidth) {
      final lt1Paint = Paint()
        ..color = AppColors.powerZone2.withValues(alpha: 0.85)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;

      _drawDashedLine(canvas, Offset(lt1X, paddingTop), Offset(lt1X, paddingTop + chartHeight), lt1Paint);

      // Badge informacyjny LT1
      _drawBadge(
        canvas,
        'LT₁ ${currentReport.measuredLt1Watts}W (${currentReport.measuredLt1WattsPerKg.toStringAsFixed(2)} W/kg)',
        Offset(lt1X, paddingTop + 8),
        AppColors.powerZone2,
      );
    }

    // 2. Linia LT2 / OBLA (Próg beztlenowy 4.0 mmol/l)
    final double lt2X = paddingLeft + ((currentReport.measuredLt2Watts - minPower) / powerSpan) * chartWidth;
    if (lt2X >= paddingLeft && lt2X <= paddingLeft + chartWidth) {
      final lt2Paint = Paint()
        ..color = AppColors.powerZone4.withValues(alpha: 0.9)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;

      _drawDashedLine(canvas, Offset(lt2X, paddingTop), Offset(lt2X, paddingTop + chartHeight), lt2Paint);

      // Badge informacyjny LT2
      _drawBadge(
        canvas,
        'LT₂ ${currentReport.measuredLt2Watts}W (MLSS 4.0 mmol/l)',
        Offset(lt2X, paddingTop + 26),
        AppColors.powerZone4,
      );
    }
  }

  void _drawHistoricalLactateCurve(
    Canvas canvas, {
    required PhysiologyLabTestReport compReport,
    required double paddingLeft,
    required double paddingTop,
    required double chartWidth,
    required double chartHeight,
    required double minPower,
    required double powerSpan,
  }) {
    final compPaint = Paint()
      ..color = AppColors.cyanAccent.withValues(alpha: 0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool first = true;

    for (final step in compReport.steps) {
      final double x = paddingLeft + ((step.powerWatts - minPower) / powerSpan) * chartWidth;
      final double y = paddingTop + chartHeight * (1.0 - (step.bloodLactateMmolL / 14.0).clamp(0.0, 1.0));

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, compPaint);
  }

  void _drawLactateCurve(
    Canvas canvas,
    double paddingLeft,
    double paddingTop,
    double chartWidth,
    double chartHeight,
    double minPower,
    double powerSpan,
    double maxLactateY,
  ) {
    final linePaint = Paint()
      ..color = AppColors.goldAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppColors.goldAccent
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = AppColors.backgroundDark
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final fillPath = Path();
    bool first = true;

    for (final step in currentReport.steps) {
      final double x = paddingLeft + ((step.powerWatts - minPower) / powerSpan) * chartWidth;
      final double y = paddingTop + chartHeight * (1.0 - (step.bloodLactateMmolL / maxLactateY).clamp(0.0, 1.0));

      if (first) {
        path.moveTo(x, y);
        fillPath.moveTo(x, paddingTop + chartHeight);
        fillPath.lineTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(paddingLeft + chartWidth, paddingTop + chartHeight);
    fillPath.close();

    // Wypełnienie gradientem pod krzywą mleczanową
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.goldAccent.withValues(alpha: 0.25),
          AppColors.goldAccent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(paddingLeft, paddingTop, chartWidth, chartHeight));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Punkty pomiarowe
    for (final step in currentReport.steps) {
      final double x = paddingLeft + ((step.powerWatts - minPower) / powerSpan) * chartWidth;
      final double y = paddingTop + chartHeight * (1.0 - (step.bloodLactateMmolL / maxLactateY).clamp(0.0, 1.0));

      canvas.drawCircle(Offset(x, y), 5.0, dotPaint);
      canvas.drawCircle(Offset(x, y), 5.0, dotBorderPaint);
    }
  }

  void _drawHeartRateCurve(
    Canvas canvas,
    double paddingLeft,
    double paddingTop,
    double chartWidth,
    double chartHeight,
    double minPower,
    double powerSpan,
    double minHrY,
    double maxHrY,
  ) {
    final hrPaint = Paint()
      ..color = AppColors.crimsonAlert
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppColors.crimsonAlert
      ..style = PaintingStyle.fill;

    final path = Path();
    bool first = true;

    for (final step in currentReport.steps) {
      final double x = paddingLeft + ((step.powerWatts - minPower) / powerSpan) * chartWidth;
      final double hrFraction = (step.heartRateBpm - minHrY) / (maxHrY - minHrY);
      final double y = paddingTop + chartHeight * (1.0 - hrFraction.clamp(0.0, 1.0));

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, hrPaint);

    for (final step in currentReport.steps) {
      final double x = paddingLeft + ((step.powerWatts - minPower) / powerSpan) * chartWidth;
      final double hrFraction = (step.heartRateBpm - minHrY) / (maxHrY - minHrY);
      final double y = paddingTop + chartHeight * (1.0 - hrFraction.clamp(0.0, 1.0));

      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }
  }

  void _drawVentilationCurve(
    Canvas canvas,
    double paddingLeft,
    double paddingTop,
    double chartWidth,
    double chartHeight,
    double minPower,
    double powerSpan,
  ) {
    final vePaint = Paint()
      ..color = AppColors.cyanAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool first = true;

    for (final step in currentReport.steps) {
      final double x = paddingLeft + ((step.powerWatts - minPower) / powerSpan) * chartWidth;
      final double y = paddingTop + chartHeight * (1.0 - (step.minuteVentilationVE / 220.0).clamp(0.0, 1.0));

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, vePaint);
  }

  void _drawVo2Curve(
    Canvas canvas,
    double paddingLeft,
    double paddingTop,
    double chartWidth,
    double chartHeight,
    double minPower,
    double powerSpan,
  ) {
    final vo2Paint = Paint()
      ..color = AppColors.emeraldGreen
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool first = true;

    for (final step in currentReport.steps) {
      final double x = paddingLeft + ((step.powerWatts - minPower) / powerSpan) * chartWidth;
      final double y = paddingTop + chartHeight * (1.0 - (step.oxygenUptakeVO2MlKgMin / 95.0).clamp(0.0, 1.0));

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, vo2Paint);
  }

  void _drawScrubbingCrosshair(
    Canvas canvas, {
    required Size size,
    required double paddingLeft,
    required double paddingTop,
    required double chartWidth,
    required double chartHeight,
    required double minPower,
    required double powerSpan,
    required double weightKg,
  }) {
    final double power = hoveredPowerWatts!.clamp(minPower, currentReport.steps.last.powerWatts.toDouble());
    final double x = paddingLeft + ((power - minPower) / powerSpan) * chartWidth;

    final crosshairPaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(x, paddingTop), Offset(x, paddingTop + chartHeight), crosshairPaint);

    // Wyszukanie lub interpolacja wartości
    final double lactate = currentReport.newLabProfile.estimateLactateAtPower(power);
    final int hr = currentReport.newLabProfile.estimateHeartRateAtPower(power);
    final combustion = currentReport.newLabProfile.estimateSubstrateOxidation(power);

    // Rysowanie okienka Tooltip
    const double tooltipWidth = 180.0;
    const double tooltipHeight = 110.0;
    double tooltipX = x + 12;
    if (tooltipX + tooltipWidth > size.width - 20) {
      tooltipX = x - tooltipWidth - 12;
    }
    final double tooltipY = paddingTop + 10;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
      const Radius.circular(10),
    );

    final bgPaint = Paint()..color = AppColors.surface.withValues(alpha: 0.96);
    final borderPaint = Paint()
      ..color = AppColors.goldAccent
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    final double wKg = power / weightKg;
    _drawText(
      canvas,
      'MOC: ${power.round()}W (${wKg.toStringAsFixed(2)} W/kg)',
      Offset(tooltipX + 10, tooltipY + 8),
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    );

    _drawText(
      canvas,
      'Mleczan: ${lactate.toStringAsFixed(2)} mmol/l',
      Offset(tooltipX + 10, tooltipY + 28),
      fontSize: 11,
      color: AppColors.goldAccent,
      fontWeight: FontWeight.w600,
    );

    _drawText(
      canvas,
      'Tętno: $hr bpm',
      Offset(tooltipX + 10, tooltipY + 46),
      fontSize: 11,
      color: AppColors.crimsonAlert,
      fontWeight: FontWeight.w600,
    );

    _drawText(
      canvas,
      'Współczynnik RER: ${combustion.respiratoryExchangeRatioRer}',
      Offset(tooltipX + 10, tooltipY + 64),
      fontSize: 10,
      color: AppColors.cyanAccent,
    );

    _drawText(
      canvas,
      'Węgle: ${combustion.carbOxidationRateGramsPerHour.round()} g/h • Tłuszcz: ${combustion.fatOxidationRateGramsPerHour.round()} g/h',
      Offset(tooltipX + 10, tooltipY + 82),
      fontSize: 10,
      color: AppColors.textSecondary,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, {double dash = 4.0, double gap = 3.0}) {
    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double distance = math.sqrt(dx * dx + dy * dy);
    final double step = dash + gap;
    final double unitX = dx / distance;
    final double unitY = dy / distance;

    double current = 0.0;
    while (current < distance) {
      final double segEnd = math.min(current + dash, distance);
      canvas.drawLine(
        Offset(start.dx + unitX * current, start.dy + unitY * current),
        Offset(start.dx + unitX * segEnd, start.dy + unitY * segEnd),
        paint,
      );
      current += step;
    }
  }

  void _drawBadge(Canvas canvas, String text, Offset center, Color color) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(color: Colors.black, fontSize: 9.5, fontWeight: FontWeight.w900),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final double width = textPainter.width + 12;
    final double height = textPainter.height + 6;

    final rect = Rect.fromCenter(center: center, width: width, height: height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(5));

    final paint = Paint()..color = color;
    canvas.drawRRect(rrect, paint);
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2));
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position, {
    Alignment alignment = Alignment.topLeft,
    Color color = AppColors.textPrimary,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final double dx = position.dx - (alignment.x + 1) / 2 * textPainter.width;
    final double dy = position.dy - (alignment.y + 1) / 2 * textPainter.height;

    textPainter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _InteractiveLactateCurvePainter oldDelegate) {
    return oldDelegate.currentReport != currentReport ||
        oldDelegate.comparisonReport != comparisonReport ||
        oldDelegate.useWKg != useWKg ||
        oldDelegate.showLactate != showLactate ||
        oldDelegate.showHeartRate != showHeartRate ||
        oldDelegate.showVentilation != showVentilation ||
        oldDelegate.showVo2 != showVo2 ||
        oldDelegate.hoveredPowerWatts != hoveredPowerWatts;
  }
}

// =============================================================================
// POMOCNICZE WIDŻETY TABELI
// =============================================================================

class _TableHeaderCell extends StatelessWidget {
  final String title;

  const _TableHeaderCell(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final Color? textColor;
  final bool isBold;

  const _TableCell(this.text, {this.textColor, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? AppColors.textPrimary,
          fontSize: 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
