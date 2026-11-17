import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/career/career_save.dart';
import '../../models/equipment/bike_fit_configuration.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/cycling_team.dart';
import '../../state/career_controller.dart';
import '../widgets/bike_preview_painter.dart';
import '../widgets/polar_pedal_force_diagram_painter.dart';
import '../widgets/power_curve_chart_widget.dart';
import '../widgets/rider_avatar_painter.dart';

/// Szczegółowy ekran profilu pojedynczego kolarza podzielony na 4 główne zakładki:
/// 1. Fizjologia i Krzywa Mocy (PowerCurveChartWidget, VO2max, W', tętno, waga, CdA).
/// 2. Umiejętności techniczne, historia kontuzji i aktualny plan treningowy.
/// 3. Kontrakt, morale, lojalność i cele sezonowe zawodnika.
/// 4. Przypisany rower i personalizacja sprzętu dla tego kolarza.
class RiderDetailScreen extends ConsumerStatefulWidget {
  final String riderId;
  final Rider? initialRider;

  const RiderDetailScreen({
    super.key,
    required this.riderId,
    this.initialRider,
  });

  @override
  ConsumerState<RiderDetailScreen> createState() => _RiderDetailScreenState();
}

class _RiderDetailScreenState extends ConsumerState<RiderDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Stan personalizacji roweru i szczegółowego Bike Fittingu w zakładce 4
  int _selectedBikeIndex = 0;
  bool _useTanWallTires = true;
  bool _bikeFitInitialized = false;

  double _saddleHeightMm = 745.0;
  double _saddleSetbackMm = 58.0;
  double _saddleTiltDegrees = -2.0;
  int _cockpitWidthMm = 380;
  int _stemLengthMm = 120;
  int _spacersStackMm = 0;
  double _hoodInwardTiltDegrees = 12.0;
  double _crankArmLengthMm = 170.0;
  double _cleatOffsetMm = -4.0;

  // Wybrany fokus treningowy w zakładce 2
  String _currentTrainingFocus = 'Budowa bazy tlenowej & VO2max';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final careerUiState = ref.watch(careerProvider);
    final careerController = ref.read(careerProvider.notifier);
    final save = careerUiState.save;

    if (save == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.goldAccent),
        ),
      );
    }

    final rider = save.getRiderById(widget.riderId) ?? widget.initialRider;
    if (rider == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.surface),
        body: const Center(
          child: Text(
            'Nie znaleziono profilu kolarza w bazie danych.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final playerTeam = save.playerTeam;
    final teamColor = _parseHexColor(playerTeam.primaryJerseyColorHex);

    // Kolarz lider do porównania H2H na wykresie
    Rider? comparisonRider;
    if (playerTeam.rosterRiderIds.isNotEmpty) {
      final leaderId = playerTeam.rosterRiderIds.first;
      if (leaderId != rider.id) {
        comparisonRider = save.getRiderById(leaderId);
      } else if (playerTeam.rosterRiderIds.length > 1) {
        comparisonRider = save.getRiderById(playerTeam.rosterRiderIds[1]);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.goldAccent),
          tooltip: 'Wróć',
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: teamColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Profil Kolarza: ${rider.fullName}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: AppColors.goldAccent),
            tooltip: 'Zmień Rolę Taktyczną',
            onPressed: () => _showRoleDialog(context, rider, careerController),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Stały baner profilowy kolarza (Hero Banner)
          _buildProfileHeroBanner(context, save, playerTeam, rider, careerController),

          // 2. Belka zakładek nawigacyjnych (TabBar)
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.goldAccent,
              indicatorWeight: 3.0,
              labelColor: AppColors.goldAccent,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(
                  icon: Icon(Icons.show_chart_rounded, size: 18),
                  text: '1. Fizjologia & Moc',
                ),
                Tab(
                  icon: Icon(Icons.psychology_rounded, size: 18),
                  text: '2. Umiejętności & Trening',
                ),
                Tab(
                  icon: Icon(Icons.handshake_rounded, size: 18),
                  text: '3. Kontrakt & Morale',
                ),
                Tab(
                  icon: Icon(Icons.pedal_bike_rounded, size: 18),
                  text: '4. Rower & Sprzęt',
                ),
              ],
            ),
          ),

          // 3. Zawartość aktywnej zakładki (TabBarView)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ZAKŁADKA 1: Fizjologia i Krzywa Mocy
                _buildTab1PhysiologyAndPower(context, rider, comparisonRider),

                // ZAKŁADKA 2: Umiejętności techniczne, kontuzje i trening
                _buildTab2SkillsAndTraining(context, rider),

                // ZAKŁADKA 3: Kontrakt, morale, lojalność i cele
                _buildTab3ContractAndMorale(context, rider, playerTeam),

                // ZAKŁADKA 4: Przypisany rower i personalizacja sprzętu
                _buildTab4BikeAndEquipment(context, rider, playerTeam),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. BANER PROFILOWY KOLARZA (HERO BANNER)
  // ===========================================================================

  Widget _buildProfileHeroBanner(
    BuildContext context,
    CareerSave save,
    CyclingTeam playerTeam,
    Rider rider,
    CareerController careerController,
  ) {
    final bool isInjured = rider.health.currentInjury != null;
    final double form = rider.physiology.form.clamp(0.0, 100.0);
    final double fatigue = rider.physiology.fatigue.clamp(0.0, 100.0);
    final double tsb = form - fatigue;

    Color tsbColor = AppColors.powerZone3;
    String tsbLabel = 'Szczyt formy';
    if (tsb < 0 && tsb >= -10) {
      tsbColor = AppColors.goldAccent;
      tsbLabel = 'Lekkie zmęczenie';
    } else if (tsb < -10) {
      tsbColor = AppColors.powerZone6;
      tsbLabel = 'Zmęczenie';
    }

    final double wKg = rider.physiology.weightKg > 0
        ? rider.physiology.ftpWatts / rider.physiology.weightKg
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF131722),
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1060;
          final profileInfo = Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Wektorowy awatar kolarza w wysokiej rozdzielczości
              RiderAvatarWidget(
                appearance: rider.appearance,
                team: playerTeam,
                size: 72,
                showBorder: true,
                borderColor: AppColors.goldAccent,
              ),
              const SizedBox(width: 16),

              // Dane personalne i taktyczne
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          rider.fullName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            rider.countryIso,
                            style: const TextStyle(
                              color: AppColors.cyanAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getSpecializationLabel(rider.specialization).toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.goldAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${rider.age} lat • Urodzony: ${_formatBirthDate(rider.birthDate)} • Drużyna: ${playerTeam.name}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        InkWell(
                      onTap: () => _showRoleDialog(context, rider, careerController),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2638),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getRoleLabel(rider.contract.role),
                              style: const TextStyle(color: AppColors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit, size: 9, color: AppColors.cyanAccent),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

          // Pigułki kluczowych metryk (FTP, W/kg, TSB, Zdrowie)
          final pills = Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildHeaderPill('FTP', '${rider.physiology.ftpWatts} W', AppColors.cyanAccent),
              _buildHeaderPill('W/KG', '${wKg.toStringAsFixed(2)} W/kg', AppColors.powerZone3),
              _buildHeaderPill('ŚWIEŻOŚĆ', '${tsb > 0 ? "+" : ""}${tsb.round()} TSB', tsbColor, subtitle: tsbLabel),
              _buildHeaderPill(
                'ZDROWIE',
                isInjured ? 'KONTUZJA' : '100% OK',
                isInjured ? AppColors.powerZone6 : AppColors.powerZone3,
                subtitle: isInjured ? '${rider.health.currentInjury!.daysRemaining} dni' : 'Gotowy',
              ),
            ],
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: profileInfo),
                const SizedBox(width: 16),
                pills,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profileInfo,
              const SizedBox(height: 14),
              pills,
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderPill(String label, String value, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(subtitle, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 9, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. ZAKŁADKA 1: FIZJOLOGIA I KRZYWA MOCY
  // ===========================================================================

  Widget _buildTab1PhysiologyAndPower(
    BuildContext context,
    Rider rider,
    Rider? comparisonRider,
  ) {
    final phys = rider.physiology;
    final lab = rider.labProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kafelki laboratoryjnych wskaźników fizjologicznych
          Row(
            children: [
              _buildPhysioCard(
                title: 'VO2MAX (PUŁAP TLENOWY)',
                value: '${phys.vo2Max.toStringAsFixed(1)} ml/kg/min',
                desc: 'Klasa światowa (${lab.vo2MaxAbsoluteLitersMin.toStringAsFixed(2)} L/min • MAP ${lab.powerAtVo2MaxWatts}W)',
                icon: Icons.air_rounded,
                accentColor: AppColors.cyanAccent,
              ),
              const SizedBox(width: 14),
              _buildPhysioCard(
                title: "W' (REZERWA BEZTLENOWA)",
                value: '${(phys.wPrimeJoules / 1000).toStringAsFixed(1)} kJ',
                desc: 'Pojemność do ataku ponad FTP',
                icon: Icons.battery_charging_full_rounded,
                accentColor: AppColors.powerZone6,
              ),
              const SizedBox(width: 14),
              _buildPhysioCard(
                title: 'TĘTNO PROGOWE & MAX',
                value: '${phys.lactateThresholdHr} / ${phys.maxHr} bpm',
                desc: 'Spoczynkowe: ${phys.restingHr} bpm (Rezerwa: ${phys.heartRateReserve})',
                icon: Icons.favorite_rounded,
                accentColor: AppColors.powerZone5,
              ),
              const SizedBox(width: 14),
              _buildPhysioCard(
                title: 'AERODYNAMIKA & MASA',
                value: '${phys.weightKg.toStringAsFixed(1)} kg • ${phys.heightCm.round()} cm',
                desc: 'Frontal Area: ${phys.frontalAreaM2.toStringAsFixed(3)} m² (CdA ~0.235)',
                icon: Icons.speed_rounded,
                accentColor: AppColors.goldAccent,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Kafelki dokładnych parametrów laboratoryjnych (LT1, LT2/MLSS, VLaMax, Gross Efficiency)
          Row(
            children: [
              _buildPhysioCard(
                title: 'PRÓG TLENOWY (LT₁ / FatMax)',
                value: '${lab.lt1Watts} W (${lab.lt1WattsPerKg.toStringAsFixed(2)} W/kg)',
                desc: 'Mleczan: ${lab.lt1LactateMmolL} mmol/l • FatMax: ${lab.fatMaxWatts}W (${lab.fatMaxOxidationRateGramsPerHour} g/h)',
                icon: Icons.energy_savings_leaf_rounded,
                accentColor: AppColors.powerZone2,
              ),
              const SizedBox(width: 14),
              _buildPhysioCard(
                title: 'PRÓG BEZTLENOWY (LT₂ / MLSS)',
                value: '${lab.lt2Watts} W (${lab.lt2WattsPerKg.toStringAsFixed(2)} W/kg)',
                desc: 'Mleczan: ${lab.lt2LactateMmolL} mmol/l (Równowaga MLSS • ${(lab.fractionalUtilization * 100).round()}% MAP)',
                icon: Icons.bolt_rounded,
                accentColor: AppColors.powerZone4,
              ),
              const SizedBox(width: 14),
              _buildPhysioCard(
                title: 'VLAMAX (GLIKOLIZA BEZTLENOWA)',
                value: '${lab.vlaMaxMmolLPerSec.toStringAsFixed(2)} mmol/l/s',
                desc: lab.metabolicPhenotype.displayName,
                icon: Icons.local_fire_department_rounded,
                accentColor: AppColors.powerZone5,
              ),
              const SizedBox(width: 14),
              _buildPhysioCard(
                title: 'EKONOMIA JAZDY (GROSS EFFICIENCY)',
                value: '${lab.grossEfficiencyPercent.toStringAsFixed(1)}%',
                desc: '${lab.metabolicKcalPerKjWork.toStringAsFixed(2)} kcal/kJ (Delta: ${lab.deltaEfficiencyPercent.toStringAsFixed(1)}%)',
                icon: Icons.insights_rounded,
                accentColor: AppColors.emeraldGreen,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Baner przejścia do Laboratorium Wydolnościowego
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cyanAccent.withValues(alpha: 0.12),
                  AppColors.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.cyanAccent.withValues(alpha: 0.35),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 520;
                final headerRow = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cyanAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.cyanAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.biotech_rounded,
                        color: AppColors.cyanAccent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LABORATORIUM WYDOLNOŚCIOWE & ERGOSPIROMETRIA',
                            style: TextStyle(
                              color: AppColors.cyanAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Krzywa mleczanowa [La], wentylacja płuc VE, progi LT₁ i LT₂ oraz badanie fenotypu metabolicznego (${lab.metabolicPhenotype.displayName}).',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final actionButton = ElevatedButton.icon(
                  onPressed: () => context.goToPhysiologyLab(riderId: rider.id),
                  icon: const Icon(Icons.show_chart_rounded, size: 16),
                  label: const Text('Otwórz Laboratorium'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyanAccent,
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      headerRow,
                      const SizedBox(height: 12),
                      actionButton,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: headerRow),
                    const SizedBox(width: 16),
                    actionButton,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Interaktywny widget Krzywej Mocy (PowerCurveChartWidget)
          PowerCurveChartWidget(
            riderA: rider,
            riderB: comparisonRider,
            height: 480,
            showHeader: true,
            showTabs: true,
          ),
          const SizedBox(height: 20),

          // Interaktywny wykres kołowy biomechaniki pedałowania 360° (Peanut Diagram)
          PolarPedalForceDiagramWidget(
            rider: rider,
            initialMode: PolarPedalingTechniqueMode.activeRider,
          ),
        ],
      ),
    );
  }

  Widget _buildPhysioCard({
    required String title,
    required String value,
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
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: accentColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. ZAKŁADKA 2: UMIEJĘTNOŚCI TECHNICZNE, KONTUZJE I PLAN TRENINGOWY
  // ===========================================================================

  Widget _buildTab2SkillsAndTraining(BuildContext context, Rider rider) {
    final skills = rider.skills;
    final health = rider.health;
    final bool isInjured = health.currentInjury != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lewa kolumna: Umiejętności techniczne
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology_rounded, size: 20, color: AppColors.goldAccent),
                      SizedBox(width: 8),
                      Text(
                        'Umiejętności Techniczne (Skala 0-100)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSkillRow('Prowadzenie roweru (Handling)', skills.bikeHandling, AppColors.cyanAccent),
                  _buildSkillRow('Zjazdy (Descending)', skills.descending, AppColors.cyanAccent),
                  _buildSkillRow('Jazda po brukach (Cobbles)', skills.cobbles, AppColors.goldAccent),
                  _buildSkillRow('Pozycja aerodynamiczna (Aero)', skills.aeroPositioning, AppColors.powerZone3),
                  _buildSkillRow('Jazda na kole (Drafting)', skills.draftingEfficiency, AppColors.powerZone3),
                  _buildSkillRow('Inteligencja wyścigowa (Race IQ)', skills.raceIq, AppColors.goldAccent),
                  _buildSkillRow('Pozycja na czasówce (TT Position)', skills.timeTrialPositioning, AppColors.cyanAccent),
                  _buildSkillRow('Odporność na deszcz (Rain)', skills.rainResistance, AppColors.textPrimary),
                  _buildSkillRow('Tolerancja na upał (Heat)', skills.heatTolerance, AppColors.powerZone6),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Prawa kolumna: Historia kontuzji i plan treningowy
          Expanded(
            flex: 5,
            child: Column(
              children: [
                // Karta zdrowia i historii kontuzji
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isInjured ? AppColors.powerZone6.withValues(alpha: 0.6) : AppTheme.borderColor,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.medical_services_rounded, size: 18, color: AppColors.powerZone6),
                              SizedBox(width: 8),
                              Text(
                                'Zdrowie & Historia Kontuzji',
                                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isInjured ? AppColors.powerZone6.withValues(alpha: 0.2) : AppColors.powerZone3.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isInjured ? 'KONTUZJA' : '100% ZDROWIA',
                              style: TextStyle(
                                color: isInjured ? AppColors.powerZone6 : AppColors.powerZone3,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isInjured) ...[
                        Text(
                          'Aktywny uraz: ${health.currentInjury!.name}',
                          style: const TextStyle(color: AppColors.powerZone6, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pozostało dni rekonwalescencji: ${health.currentInjury!.daysRemaining} dni • Trening na szosie: ${health.canTrain ? "Dozwolony" : "Wstrzymany"}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ] else ...[
                        const Text(
                          'Kolarz w pełni zdrowy. Brak powikłań mięśniowych lub stanów zapalnych.',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 14),
                      const Divider(color: AppTheme.borderColor),
                      const SizedBox(height: 8),
                      const Text(
                        'Przebyte urazy w karierze zawodnika:',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      _buildInjuryHistoryItem('Pęknięcie obojczyka (Tour de Suisse 2024)', '28 dni absencji'),
                      _buildInjuryHistoryItem('Stłuczenie kości biodrowej (Kraksa w peletonie 2025)', '10 dni rehabilitacji'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Karta planu treningowego i obozów
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.fitness_center_rounded, size: 18, color: AppColors.cyanAccent),
                          SizedBox(width: 8),
                          Text(
                            'Aktualny Plan Treningowy & Zgrupowania',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Główny cel mikrocyklu treningowego:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _currentTrainingFocus,
                              style: const TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                            InkWell(
                              onTap: () => _showTrainingFocusPicker(context),
                              child: const Text('Zmień', style: TextStyle(color: AppColors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.landscape_rounded, color: AppColors.goldAccent, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Najbliższe Zgrupowanie Wysokogórskie:', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                  Text('Teide / Sierra Nevada (21 dni)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillRow(String name, int score, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary)),
              Text('$score / 100', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (score / 100.0).clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInjuryHistoryItem(String name, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('• $name', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          Text(time, style: const TextStyle(color: AppColors.goldAccent, fontSize: 10.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. ZAKŁADKA 3: KONTRAKT, MORALE, LOJALNOŚĆ I CELE SEZONOWE
  // ===========================================================================

  Widget _buildTab3ContractAndMorale(
    BuildContext context,
    Rider rider,
    CyclingTeam playerTeam,
  ) {
    final contract = rider.contract;
    final double morale = contract.morale.clamp(0.0, 100.0);
    final double loyalty = contract.leaderLoyalty.clamp(0.0, 100.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lewa kolumna: Finanse kontraktu i klauzule
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.description_rounded, size: 20, color: AppColors.goldAccent),
                      SizedBox(width: 8),
                      Text(
                        'Warunki Kontraktu Zawodnika',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildContractDetailRow('Pensja roczna', '€${(contract.annualSalaryEur / 1000).round()}k / rok', isHighlight: true),
                  _buildContractDetailRow('Pensja miesięczna', '€${contract.monthlySalaryEur} / mies.'),
                  _buildContractDetailRow('Ważność kontraktu do', '31 grudnia ${contract.contractEndYear}'),
                  _buildContractDetailRow('Klauzula odejścia (Buyout)', '€${(contract.releaseClauseEur / 1000).round()}k'),
                  _buildContractDetailRow('Premia za zwycięstwo etapowe', '€${(contract.winBonusEur / 1000).round()}k'),
                  _buildContractDetailRow('Premia za podpisanie umowy', '€${(contract.signingBonusEur / 1000).round()}k'),
                  _buildContractDetailRow('Przypisana rola w składzie', _getRoleLabel(contract.role)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Otwarto panel negocjacji nowego kontraktu z agentem kolarza.')),
                        );
                      },
                      icon: const Icon(Icons.handshake_rounded, size: 16),
                      label: const Text('Zaproponuj Nowy Kontrakt (Przedłużenie)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Prawa kolumna: Morale, Lojalność i Cele
          Expanded(
            flex: 5,
            child: Column(
              children: [
                // Karta Morale i Lojalności
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sentiment_satisfied_alt_rounded, size: 18, color: AppColors.cyanAccent),
                          SizedBox(width: 8),
                          Text(
                            'Morale & Lojalność Wobec Ekipy',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildProgressGauge('Poziom Morale Kolarza', morale, AppColors.powerZone3),
                      const SizedBox(height: 12),
                      _buildProgressGauge('Lojalność Wobec Dyrektora', loyalty, AppColors.goldAccent),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Czynniki zadowolenia: Znakomita jakość rowerów w warsztacie, status niekwestionowanego lidera na Tour de France, terminowe wypłaty premii.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Karta Celów Sezonowych
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.flag_rounded, size: 18, color: AppColors.goldAccent),
                          SizedBox(width: 8),
                          Text(
                            'Główne Cele Sezonowe Zawodnika',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildGoalRow('Cel #1 (Grand Tour)', 'Podium w Klasyfikacji Generalnej (Top 3)'),
                      _buildGoalRow('Cel #2 (Monument)', 'Zwycięstwo etapowe w wyścigu WorldTour'),
                      _buildGoalRow('Cel #3 (Ranking)', 'Zdobycie minimum 1,500 punktów UCI w sezonie'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? AppColors.powerZone3 : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: isHighlight ? 13.5 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressGauge(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            Text('${value.round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (value / 100.0).clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalRow(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: AppColors.goldAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.goldAccent, fontSize: 10, fontWeight: FontWeight.w800)),
                Text(desc, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. ZAKŁADKA 4: PRZYPISANY ROWER I PERSONALIZACJA SPRZĘTU
  // ===========================================================================

  Widget _buildTab4BikeAndEquipment(
    BuildContext context,
    Rider rider,
    CyclingTeam playerTeam,
  ) {
    final bikes = playerTeam.bikes;
    final baseBike = bikes.isNotEmpty ? bikes[_selectedBikeIndex.clamp(0, bikes.length - 1)] : null;

    if (baseBike == null) {
      return const Center(
        child: Text('Brak skonfigurowanych rowerów w warsztacie drużyny.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    // Inicjalizacja domyślnego fittingu pod parametry biomechaniczne kolarza
    if (!_bikeFitInitialized) {
      final defaultFit = BikeFitConfiguration.proceduralForRider(
        heightCm: rider.physiology.heightCm,
        weightKg: rider.physiology.weightKg,
        isAeroFocus: true,
        isClimberFocus: rider.specialization == RiderSpecialization.gcClimber ||
            rider.specialization == RiderSpecialization.pureClimber,
      );
      _saddleHeightMm = defaultFit.saddleHeightMm;
      _saddleSetbackMm = defaultFit.saddleSetbackMm;
      _saddleTiltDegrees = defaultFit.saddleTiltDegrees;
      _cockpitWidthMm = defaultFit.cockpitWidthMm;
      _stemLengthMm = defaultFit.stemLengthMm;
      _spacersStackMm = defaultFit.spacersStackMm;
      _hoodInwardTiltDegrees = defaultFit.hoodInwardTiltDegrees;
      _crankArmLengthMm = defaultFit.crankArmLengthMm;
      _cleatOffsetMm = defaultFit.cleatOffsetMm;
      _bikeFitInitialized = true;
    }

    // Aktywna konfiguracja Bike Fittingu
    final currentFit = BikeFitConfiguration(
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

    // Klonujemy obiekt roweru z zastosowaniem personalizacji kolarza
    final customizedBike = baseBike.applyBikeFit(currentFit);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pasek wyboru ramy / roweru z warsztatu
          Row(
            children: [
              const Text('Wybierz Rower: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(width: 12),
              ...List.generate(bikes.length, (idx) {
                final isSelected = idx == _selectedBikeIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(bikes[idx].name),
                    selected: isSelected,
                    selectedColor: AppColors.goldAccent,
                    backgroundColor: AppColors.surfaceLight,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 11,
                    ),
                    onSelected: (_) => setState(() => _selectedBikeIndex = idx),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Interaktywny podgląd profilu 2D roweru
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: BikePreviewWidget(
              bike: customizedBike,
              isTanWallOverride: _useTanWallTires,
              showSpecsPill: true,
              showFloorReflection: true,
            ),
          ),
          const SizedBox(height: 16),

          // Belka szybkich presetów Bike Fittingu (1-Click Fitting Presets)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, color: AppColors.goldAccent, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Presety Fittingu:',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPresetChip(
                          label: 'Super-Aero (Slammed)',
                          icon: Icons.flash_on_rounded,
                          onTap: () => _applyFitPreset(
                            BikeFitConfiguration.slammedAeroRoad(
                              saddleHeightMm: _saddleHeightMm,
                              saddleSetbackMm: _saddleSetbackMm,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPresetChip(
                          label: 'WorldTour Zrównoważony',
                          icon: Icons.verified_rounded,
                          onTap: () => _applyFitPreset(
                            BikeFitConfiguration.uciWorldTourBalanced(
                              saddleHeightMm: _saddleHeightMm,
                              saddleSetbackMm: _saddleSetbackMm,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPresetChip(
                          label: 'Górski (Wspinaczka)',
                          icon: Icons.landscape_rounded,
                          onTap: () => _applyFitPreset(
                            BikeFitConfiguration.climberLightweight(
                              saddleHeightMm: _saddleHeightMm,
                              saddleSetbackMm: _saddleSetbackMm,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPresetChip(
                          label: 'Bruki (Roubaix Comfort)',
                          icon: Icons.shield_rounded,
                          onTap: () => _applyFitPreset(
                            BikeFitConfiguration.cobbledEnduranceComfort(
                              saddleHeightMm: _saddleHeightMm,
                              saddleSetbackMm: _saddleSetbackMm,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPresetChip(
                          label: 'Auto-Fit (Wzrost kolarza)',
                          icon: Icons.accessibility_new_rounded,
                          onTap: () => _applyFitPreset(
                            BikeFitConfiguration.proceduralForRider(
                              heightCm: rider.physiology.heightCm,
                              weightKg: rider.physiology.weightKg,
                              isAeroFocus: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Paski wskaźników telemetrycznych fittingu (Zysk Aero, Sterowność, Komfort, Kąt biodra, Zgodność UCI)
          Row(
            children: [
              _buildFitMetricCard(
                title: 'ZYSK AERODYNAMICZNY',
                value: '+${currentFit.estimatedWattsSavedAt45Kmh} W',
                subValue: 'CdA: ${currentFit.totalCdaModifier.toStringAsFixed(4)} m²',
                icon: Icons.speed_rounded,
                color: AppColors.cyanAccent,
              ),
              const SizedBox(width: 12),
              _buildFitMetricCard(
                title: 'STEROWNOŚĆ I STABILNOŚĆ',
                value: '${currentFit.handlingControlScore.round()} / 100',
                subValue: currentFit.handlingControlScore >= 80
                    ? 'Pewny chwyt'
                    : (currentFit.handlingControlScore >= 65 ? 'Umiarkowana' : 'Nerwowy przód'),
                icon: Icons.navigation_rounded,
                color: currentFit.handlingControlScore >= 75
                    ? AppColors.emeraldGreen
                    : (currentFit.handlingControlScore >= 60 ? AppColors.goldAccent : AppColors.crimsonAlert),
              ),
              const SizedBox(width: 12),
              _buildFitMetricCard(
                title: 'KOMFORT PLECY & LĘDŹWIE',
                value: '${currentFit.comfortScore.round()} / 100',
                subValue: currentFit.comfortScore >= 75 ? 'Długie etapy OK' : 'Szybkie zmęczenie',
                icon: Icons.airline_seat_recline_extra_rounded,
                color: currentFit.comfortScore >= 70 ? AppColors.powerZone2 : AppColors.powerZone5,
              ),
              const SizedBox(width: 12),
              _buildFitMetricCard(
                title: 'KĄT BIODRA W GMP',
                value: '${currentFit.hipAngleAtTdcDegrees.toStringAsFixed(1)}°',
                subValue: 'Kadencja: ~${currentFit.optimalCadenceRpm} RPM',
                icon: Icons.rotate_right_rounded,
                color: AppColors.powerZone4,
              ),
              const SizedBox(width: 12),
              _buildFitMetricCard(
                title: 'STATUS REGULACYJNY UCI',
                value: currentFit.isUciLegal ? '100% ZGODNY' : 'NIELEGALNY',
                subValue: currentFit.hasExtremeAeroHoods
                    ? 'Klamki >14° (+${currentFit.uciHoodTiltExcessDegrees.round()}°)'
                    : 'Aprobata UCI',
                icon: currentFit.isUciLegal ? Icons.verified_rounded : Icons.warning_amber_rounded,
                color: currentFit.isUciLegal ? AppColors.emeraldGreen : AppColors.crimsonAlert,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Kontrolki konfiguracji 9 parametrów geometrii fittingu
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Szczegółowy Panel Geometrii i Bike Fittingu Kolarza',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Zgodne ze standardem LeMonda & biomechaniki WorldTour',
                      style: TextStyle(fontSize: 11, color: AppColors.cyanAccent, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // -------------------------------------------------------------
                // SEKCJA 1: STREFA SIODEŁKA
                // -------------------------------------------------------------
                _buildSectionHeader('1. STREFA SIODEŁKA (SADDLE GEOMETRY)', Icons.chair_alt_rounded),
                const SizedBox(height: 12),

                // Wysokość siodła
                _buildSliderRow(
                  label: 'Wysokość siodła od suportu (BB):',
                  valueDisplay: '${_saddleHeightMm.round()} mm',
                  subLabel: 'Wzór LeMonda ~${(rider.physiology.heightCm * 10 * 0.465 * 0.883).round()} mm',
                  value: _saddleHeightMm,
                  min: 640.0,
                  max: 880.0,
                  divisions: 240,
                  onChanged: (val) => setState(() => _saddleHeightMm = val),
                ),
                const SizedBox(height: 8),

                // Cofnięcie siodła (Setback)
                _buildSliderRow(
                  label: 'Cofnięcie siodła (BB Setback):',
                  valueDisplay: '${_saddleSetbackMm.toStringAsFixed(1)} mm',
                  subLabel: _saddleSetbackMm < 50.0 ? 'Wymaga ulgi morfologicznej UCI' : 'Standard UCI ≥50mm',
                  value: _saddleSetbackMm,
                  min: 35.0,
                  max: 85.0,
                  divisions: 50,
                  onChanged: (val) => setState(() => _saddleSetbackMm = val),
                ),
                const SizedBox(height: 8),

                // Kąt pochylenia siodełka (Tilt)
                _buildSliderRow(
                  label: 'Pochylenie siodła (Tilt):',
                  valueDisplay: '${_saddleTiltDegrees.toStringAsFixed(1)}° (${_saddleTiltDegrees < 0 ? "Nos w dół" : (_saddleTiltDegrees > 0 ? "Nos w górę" : "Poziom")})',
                  subLabel: 'Norma UCI: ±9.0°',
                  value: _saddleTiltDegrees,
                  min: -6.0,
                  max: 2.0,
                  divisions: 16,
                  onChanged: (val) => setState(() => _saddleTiltDegrees = val),
                ),
                const SizedBox(height: 18),

                // -------------------------------------------------------------
                // SEKCJA 2: STREFA KOKPITU
                // -------------------------------------------------------------
                _buildSectionHeader('2. KOKPIT I KIEROWNICA (COCKPIT & REACH)', Icons.directions_bike_rounded),
                const SizedBox(height: 12),

                // Szerokość kierownicy
                Row(
                  children: [
                    const SizedBox(
                      width: 250,
                      child: Text('Szerokość kierownicy (Cockpit):', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ),
                    ...[360, 380, 400, 420].map((w) {
                      final isSelected = _cockpitWidthMm == w;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('$w mm'),
                          selected: isSelected,
                          selectedColor: AppColors.goldAccent,
                          backgroundColor: AppColors.surfaceLight,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                          onSelected: (_) => setState(() => _cockpitWidthMm = w),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),

                // Długość mostka kierownicy
                Row(
                  children: [
                    const SizedBox(
                      width: 250,
                      child: Text('Długość mostka (Stem Length):', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ),
                    ...[90, 100, 110, 120, 130, 140].map((s) {
                      final isSelected = _stemLengthMm == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('$s mm'),
                          selected: isSelected,
                          selectedColor: AppColors.goldAccent,
                          backgroundColor: AppColors.surfaceLight,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                          onSelected: (_) => setState(() => _stemLengthMm = s),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),

                // Wysokość podkładek pod mostkiem (Spacers Stack)
                Row(
                  children: [
                    const SizedBox(
                      width: 250,
                      child: Text('Podkładki pod mostek (Spacers):', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ),
                    ...[0, 5, 10, 15, 20, 25].map((sp) {
                      final isSelected = _spacersStackMm == sp;
                      final label = sp == 0 ? '0 mm (Slammed)' : '$sp mm';
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          selectedColor: AppColors.goldAccent,
                          backgroundColor: AppColors.surfaceLight,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : AppColors.textPrimary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                          onSelected: (_) => setState(() => _spacersStackMm = sp),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),

                // Kąt podgięcia klamkomanetek (0° do 35° pod puppy paws)
                _buildSliderRow(
                  label: 'Podgięcie klamek (Inward Tilt):',
                  valueDisplay: '${_hoodInwardTiltDegrees.toStringAsFixed(1)}° (${_hoodInwardTiltDegrees > 14.0 ? "Aero Hack / Puppy Paws" : "Legalne UCI"})',
                  subLabel: _hoodInwardTiltDegrees > 14.0 ? 'Przekracza limit UCI 14.0°!' : 'Pełna zgodność z UCI',
                  value: _hoodInwardTiltDegrees,
                  min: 0.0,
                  max: 35.0,
                  divisions: 35,
                  accentColor: _hoodInwardTiltDegrees > 14.0 ? AppColors.crimsonAlert : AppColors.goldAccent,
                  onChanged: (val) => setState(() => _hoodInwardTiltDegrees = val),
                ),
                const SizedBox(height: 18),

                // -------------------------------------------------------------
                // SEKCJA 3: NAPĘD I KONTAKT ZE STOPĄ (CRANKS & CLEATS)
                // -------------------------------------------------------------
                _buildSectionHeader('3. NAPĘD I PEDAŁY (CRANKS & CLEATS)', Icons.pedal_bike_rounded),
                const SizedBox(height: 12),

                // Długość korby
                Row(
                  children: [
                    const SizedBox(
                      width: 250,
                      child: Text('Długość ramion korby (Crank):', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ),
                    ...[165.0, 170.0, 172.5, 175.0].map((c) {
                      final isSelected = _crankArmLengthMm == c;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${c.toStringAsFixed(1)} mm'),
                          selected: isSelected,
                          selectedColor: AppColors.goldAccent,
                          backgroundColor: AppColors.surfaceLight,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                          onSelected: (_) => setState(() => _crankArmLengthMm = c),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),

                // Przesunięcie bloków w butach
                _buildSliderRow(
                  label: 'Przesunięcie bloków w butach (Cleat Offset):',
                  valueDisplay: '${_cleatOffsetMm > 0 ? "+" : ""}${_cleatOffsetMm.toStringAsFixed(1)} mm (${_cleatOffsetMm < -2.0 ? "Mid-foot / Odciążenie łydki" : (_cleatOffsetMm > 2.0 ? "Przód / Dźwignia sprintu" : "Neutralne")})',
                  subLabel: 'Wpływ na ścięgno Achillesa: ${(currentFit.calfStrainIndex * 100).round()}% obciążenia',
                  value: _cleatOffsetMm,
                  min: -10.0,
                  max: 10.0,
                  divisions: 20,
                  onChanged: (val) => setState(() => _cleatOffsetMm = val),
                ),
                const SizedBox(height: 10),

                // Opcjonalna ścianka opony Tan-Wall
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Opony Tan-Wall (Beżowy bok)', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  subtitle: const Text('Klasyczny styl retro pro-peletonu', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                  value: _useTanWallTires,
                  activeThumbColor: AppColors.goldAccent,
                  onChanged: (val) => setState(() => _useTanWallTires = val),
                ),
                const SizedBox(height: 16),

                // Ewentualne ostrzeżenia biomechaniczne
                if (currentFit.biomechanicalWarnings.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.crimsonAlert.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.crimsonAlert.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppColors.crimsonAlert, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Ostrzeżenia Biomechaniczne & Regulaminowe UCI:',
                              style: TextStyle(color: AppColors.crimsonAlert, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...currentFit.biomechanicalWarnings.map(
                          (w) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '• $w',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Podsumowanie zysków aero i wagi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.powerZone3.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded, color: AppColors.powerZone3, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Szacowany zysk aerodynamiczny pozycji: ~${currentFit.estimatedWattsSavedAt45Kmh} Watów przy 45 km/h',
                            style: const TextStyle(color: AppColors.powerZone3, fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      Text(
                        'Waga całkowita roweru: ${customizedBike.totalWeightKg.toStringAsFixed(2)} kg',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _applyFitPreset(BikeFitConfiguration preset) {
    setState(() {
      _saddleHeightMm = preset.saddleHeightMm;
      _saddleSetbackMm = preset.saddleSetbackMm;
      _saddleTiltDegrees = preset.saddleTiltDegrees;
      _cockpitWidthMm = preset.cockpitWidthMm;
      _stemLengthMm = preset.stemLengthMm;
      _spacersStackMm = preset.spacersStackMm;
      _hoodInwardTiltDegrees = preset.hoodInwardTiltDegrees;
      _crankArmLengthMm = preset.crankArmLengthMm;
      _cleatOffsetMm = preset.cleatOffsetMm;
    });
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.goldAccent),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.goldAccent,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.goldAccent),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFitMetricCard({
    required String title,
    required String value,
    required String subValue,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              subValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueDisplay,
    required String subLabel,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    Color accentColor = AppColors.goldAccent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Row(
              children: [
                Text(
                  valueDisplay,
                  style: TextStyle(color: accentColor, fontWeight: FontWeight.w800, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  '($subLabel)',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: accentColor,
          inactiveColor: AppColors.surfaceLight,
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ===========================================================================
  // 6. METODY POMOCNICZE I DIALOGI
  // ===========================================================================

  void _showRoleDialog(
    BuildContext context,
    Rider rider,
    CareerController careerController,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          title: Text('Zmień Rolę: ${rider.fullName}'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: RiderRole.values.map((role) {
                final isCurrent = rider.contract.role == role;
                return ListTile(
                  title: Text(
                    _getRoleLabel(role),
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                      color: isCurrent ? AppColors.goldAccent : AppColors.textPrimary,
                    ),
                  ),
                  trailing: isCurrent ? const Icon(Icons.check, color: AppColors.goldAccent) : null,
                  onTap: () {
                    careerController.updateRiderRole(riderId: rider.id, newRole: role);
                    Navigator.pop(dialogCtx);
                    setState(() {});
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Zamknij'),
            ),
          ],
        );
      },
    );
  }

  void _showTrainingFocusPicker(BuildContext context) {
    const focuses = [
      'Budowa bazy tlenowej & VO2max',
      'Symulacja podjazdów wysokogórskich (W/kg)',
      'Pociąg sprinterski & moc beztlenowa Pmax',
      'Aerodynamika i pozycja na czasówce (TT)',
      'Regeneracja aktywna i odnowa biologiczna',
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          title: const Text('Wybierz Fokus Treningowy'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: focuses.map((f) {
                final isSelected = _currentTrainingFocus == f;
                return ListTile(
                  title: Text(
                    f,
                    style: TextStyle(
                      color: isSelected ? AppColors.goldAccent : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                  trailing: isSelected ? const Icon(Icons.check, color: AppColors.goldAccent) : null,
                  onTap: () {
                    setState(() => _currentTrainingFocus = f);
                    Navigator.pop(dialogCtx);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Anuluj'),
            ),
          ],
        );
      },
    );
  }

  String _getRoleLabel(RiderRole role) {
    switch (role) {
      case RiderRole.teamLeader:
        return 'Lider Zespołu';
      case RiderRole.coLeader:
        return 'Współlider';
      case RiderRole.superDomestique:
        return 'Super-Pomocnik';
      case RiderRole.sprinter:
        return 'Lider Sprinter';
      case RiderRole.breakawaySpecialist:
        return 'Hulaka / Uciekinier';
      case RiderRole.domestique:
        return 'Pomocnik (Domestique)';
      case RiderRole.neoPro:
        return 'Młody Talent (Neo-Pro)';
    }
  }

  String _getSpecializationLabel(RiderSpecialization spec) {
    switch (spec) {
      case RiderSpecialization.gcClimber:
        return 'Góral GC';
      case RiderSpecialization.pureClimber:
        return 'Czysty Góral';
      case RiderSpecialization.puncher:
        return 'Puncheur';
      case RiderSpecialization.classicCobbles:
        return 'Brukowiec';
      case RiderSpecialization.pureSprinter:
        return 'Czysty Sprinter';
      case RiderSpecialization.versatileSprinter:
        return 'Sprinter Wszechstronny';
      case RiderSpecialization.timeTrialist:
        return 'Czasowiec';
      case RiderSpecialization.domestiqueEngine:
        return 'Motor Peletonu';
      case RiderSpecialization.breakawaySpecialist:
        return 'Uciekinier';
    }
  }

  Color _parseHexColor(String hexString, [Color fallback = AppColors.primaryAccent]) {
    try {
      String hex = hexString.replaceAll('#', '').trim();
      if (hex.length == 6) hex = 'FF$hex';
      if (hex.length == 8) return Color(int.parse(hex, radix: 16));
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  String _formatBirthDate(DateTime dt) {
    const months = ['sty', 'lut', 'mar', 'kwi', 'maj', 'cze', 'lip', 'sie', 'wrz', 'paź', 'lis', 'gru'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

