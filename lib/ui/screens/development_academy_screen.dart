// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/rider/rider.dart';
import '../../models/team/bike_manufacturer_deal.dart';
import '../../models/team/cycling_team.dart';
import '../../models/team/sponsor_contract.dart';
import '../../services/career/development_team_u23_service.dart';
import '../../services/generators/rider_procedural_generator.dart';
import '../../state/career_controller.dart';

/// Wybrana metryka do prezentacji na krzywej progresji fizjologicznej adepta.
enum DevoMetricType {
  ftpWatts,
  wattsPerKg,
  vo2Max,
  sprintPower5s,
  vlaMax;

  String get label {
    switch (this) {
      case DevoMetricType.ftpWatts:
        return 'Próg FTP (Wat)';
      case DevoMetricType.wattsPerKg:
        return 'Moc Względna (W/kg)';
      case DevoMetricType.vo2Max:
        return 'Pułap Tlenowy (VO₂max)';
      case DevoMetricType.sprintPower5s:
        return 'Sprint 5s (Moc)';
      case DevoMetricType.vlaMax:
        return 'VLaMax (Glikoliza)';
    }
  }

  String get unit {
    switch (this) {
      case DevoMetricType.ftpWatts:
        return 'W';
      case DevoMetricType.wattsPerKg:
        return 'W/kg';
      case DevoMetricType.vo2Max:
        return 'ml/kg/min';
      case DevoMetricType.sprintPower5s:
        return 'W';
      case DevoMetricType.vlaMax:
        return 'mmol/l/s';
    }
  }

  Color get color {
    switch (this) {
      case DevoMetricType.ftpWatts:
        return AppColors.accentBlue;
      case DevoMetricType.wattsPerKg:
        return AppColors.emeraldGreen;
      case DevoMetricType.vo2Max:
        return AppColors.primaryGold;
      case DevoMetricType.sprintPower5s:
        return AppColors.crimsonAlert;
      case DevoMetricType.vlaMax:
        return const Color(0xFF8B5CF6);
    }
  }
}

/// Ekran Akademii Młodzieżowej U23 (Development Academy Screen).
///
/// Funkcjonalności:
/// 1. **Kadra Devo**: Lista juniorów i orlików (18-22 lata) z podglądem parametrów,
///    specjalizacji, wieku, kontraktu i wskaźnika zmęczenia/burnoutu.
/// 2. **Krzywe Progresji**: Interaktywny wykres ewolucji FTP, VO₂max, W/kg, sprintu 5s
///    w oknie plastyczności młodego organizmu.
/// 3. **Porównanie z Rówieśnikami**: Globalne percentyle i benchmarki względem
///    innych zawodników U23 na świecie (np. Top 3% diament pokoleniowy).
/// 4. **Raporty Trenera & Mentoring**: Oceny szefa szkolenia młodzieży, ryzyko
///    przetrenowania i przydzielanie weterana WorldTeamu jako mentora.
/// 5. **Awans do Pierwszej Drużyny**: Przycisk „Promuj do pierwszej drużyny (Neo-Pro)”
///    z weryfikacją limitu WorldTouru i podniesieniem pensji zawodowej.
/// 6. **Wyścigi Młodzieżowe & Kampus**: Kalendarz startów (Baby Giro, Avenir,
///    Roubaix Espoirs) oraz rozbudowa bazy (Tier 1-3).
class DevelopmentAcademyScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  final int initialTab;
  final String? initialRiderId;

  const DevelopmentAcademyScreen({
    super.key,
    this.showAppBar = true,
    this.initialTab = 0,
    this.initialRiderId,
  });

  @override
  ConsumerState<DevelopmentAcademyScreen> createState() =>
      _DevelopmentAcademyScreenState();
}

class _DevelopmentAcademyScreenState
    extends ConsumerState<DevelopmentAcademyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Aktywny kolarz w podglądzie szczegółowym
  String? _selectedRiderId;

  // Filtr specjalizacji w kadrze
  RiderSpecialization? _specializationFilter;

  // Wybrana seria danych na krzywej progresji
  DevoMetricType _selectedMetric = DevoMetricType.ftpWatts;

  // Stan lokalny Devo Squadu (zsynchronizowany z CareerSave lub demonstracyjny)
  DevelopmentTeamU23? _localDevoTeam;
  CyclingTeam? _localPrimaryTeam;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 4),
    );
    _selectedRiderId = widget.initialRiderId;
    _initDevoState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initDevoState() {
    final careerState = ref.read(careerProvider);
    final save = careerState.save;

    if (save != null) {
      _localPrimaryTeam = save.playerTeam;
      // Inicjalizacja lub odtworzenie Devo Squadu
      _localDevoTeam = DevelopmentTeamU23(
        primaryTeamId: save.playerTeam.id,
        devoTeamName: '${save.playerTeam.name} Devo Team',
        isFormed: true,
        formationDate: DateTime(2026, 1, 1),
        infrastructureTier: DevoInfrastructureTier.nationalContinental,
        cashBudgetEur: 65000,
        riders: _generateRealisticDevoRoster(save.playerTeam),
      );
    } else {
      // Tryb demonstracyjny / standalone fallback
      _setupDemoTeam();
    }

    if (_selectedRiderId == null &&
        _localDevoTeam != null &&
        _localDevoTeam!.riders.isNotEmpty) {
      _selectedRiderId = _localDevoTeam!.riders.first.rider.id;
    }
  }

  void _setupDemoTeam() {
    const titleSponsor = SponsorContract(
      id: 'sp_demo_title',
      companyName: 'Lotto-Visma Tech Group',
      industry: SponsorIndustry.tech,
      sponsorTier: SponsorTier.titlePrimary,
      annualBudgetEur: 18000000,
      contractDurationYears: 3,
      sponsorSatisfaction: 85.0,
      objectives: [],
    );

    final demoSenior = RiderProceduralGenerator.generateRider(
      id: 'mentor_sep',
      specialization: RiderSpecialization.classicCobbles,
      targetOverallRating: 84,
      age: 33,
    );

    _localPrimaryTeam = CyclingTeam(
      id: 'team_demo_wt',
      name: 'Veloce WorldTour Team',
      division: TeamDivision.worldTour,
      countryIso: 'BEL',
      primaryJerseyColorHex: '#003399',
      secondaryJerseyColorHex: '#FFFFFF',
      accentJerseyColorHex: '#FFCC00',
      cashBalanceEur: 4200000,
      monthlyBurnRateEur: 420000,
      uciPointsSeason: 4600,
      rosterRiderIds: [demoSenior.id],
      staff: const TeamStaff(
        trainersLevel: 88,
        sportsDirectorsLevel: 90,
        doctorsLevel: 86,
        mechanicsLevel: 92,
        scoutsLevel: 95,
      ),
      bikeDeal: const BikeManufacturerDeal(
        manufacturerId: 'cervelo',
        manufacturerName: 'Cervélo Bicycles',
        prestigeLevel: 5,
        annualCashContributionEur: 2800000,
        freeBikesQuota: 85,
        researchAndDevelopmentLevel: 90,
        suppliedFrameIds: [],
        suppliedWheelsetIds: [],
        contractYearsLeft: 2,
        minimumUciRankingRequired: 5,
      ),
      sponsors: const [titleSponsor],
      inventoryBikes: [],
    );

    _localDevoTeam = DevelopmentTeamU23(
      primaryTeamId: _localPrimaryTeam!.id,
      devoTeamName: 'Veloce Future Stars Devo Team',
      isFormed: true,
      formationDate: DateTime(2026, 1, 1),
      infrastructureTier: DevoInfrastructureTier.nationalContinental,
      cashBudgetEur: 75000,
      totalYouthUciPoints: 340,
      totalAlumniPromoted: 2,
      riders: _generateRealisticDevoRoster(_localPrimaryTeam!),
    );
  }

  /// Generuje realistyczną kadrę 6 utalentowanych adeptów Devo (18-20 lat)
  /// z pełną historią comiesięcznych audytów wydolnościowych.
  List<DevoRiderProfile> _generateRealisticDevoRoster(CyclingTeam team) {
    final rng = math.Random(101);
    final profiles = <DevoRiderProfile>[];

    final specs = [
      RiderSpecialization.gcClimber,
      RiderSpecialization.pureSprinter,
      RiderSpecialization.classicCobbles,
      RiderSpecialization.puncher,
      RiderSpecialization.timeTrialist,
      RiderSpecialization.pureClimber,
    ];

    for (int i = 0; i < specs.length; i++) {
      final spec = specs[i];
      final isDiamond = i == 0; // Pierwszy kolarz to diament pokoleniowy
      final rider = RiderProceduralGenerator.generateNeoProTalent(
        currentSeasonYear: 2026,
        tier: isDiamond
            ? ScoutingTier.generationalTalent
            : (i == 1
                ? ScoutingTier.worldTourProspect
                : ScoutingTier.solidPro),
        preferredSpecialization: spec,
        random: rng,
      ).copyWith(
        birthDate: DateTime(2008 - (i % 2), 2 + i, 10 + i), // 18-19 lat
      );

      // Generowanie 4 historycznych audytów w odstępie miesięcznym
      final audits = <PhysiologicalAuditSnapshot>[];
      int baseFtp = rider.physiology.ftpWatts - (18 + rng.nextInt(10));
      double baseVo2 = rider.physiology.vo2Max - (1.2 + rng.nextDouble() * 1.5);
      double vla = rider.physiology.labProfile?.vlaMaxMmolLPerSec ?? 0.50;

      for (int m = 0; m < 4; m++) {
        final date = DateTime(2026, 1 + m, 15);
        final ftpStep = baseFtp + (m * (4 + rng.nextInt(4)));
        final vo2Step = baseVo2 + (m * 0.35);
        audits.add(
          PhysiologicalAuditSnapshot(
            testDate: date,
            ftpWatts: ftpStep,
            wattsPerKg: ftpStep / rider.physiology.weightKg,
            vo2Max: double.parse(vo2Step.toStringAsFixed(1)),
            vlaMax: double.parse(vla.toStringAsFixed(2)),
            maxSprintPower5s: rider.powerProfile.watts5s + (m * 15),
            overallRating: (ftpStep / 4.1).round(),
            notes: m == 0
                ? 'Audyt wstępny po podpisaniu kontraktu.'
                : 'Miesiąc $m: Progres adaptacji tlenowej pod okiem trenera Devo.',
          ),
        );
      }

      profiles.add(
        DevoRiderProfile(
          rider: rider,
          signedDate: DateTime(2026, 1, 1),
          monthlySalaryEur: 2000 + (isDiamond ? 1200 : 300 * i),
          contractEndYear: 2028,
          status: i == 4 ? DevoRiderStatus.stagiaire : DevoRiderStatus.activeU23,
          raceDaysThisSeason: 12 + (i * 4),
          burnoutFatigueIndex: 18.0 + (i * 7.5),
          uciYouthPointsSeason: isDiamond ? 145 : (i * 25),
          seniorMentorName: i == 0 ? 'Sep Vanmarcke (Weteran WT)' : null,
          seniorMentorId: i == 0 ? 'mentor_sep' : null,
          auditHistory: audits,
        ),
      );
    }

    return profiles;
  }

  DevoRiderProfile? get _selectedProfile {
    if (_localDevoTeam == null || _localDevoTeam!.riders.isEmpty) return null;
    return _localDevoTeam!.riders.firstWhere(
      (p) => p.rider.id == _selectedRiderId,
      orElse: () => _localDevoTeam!.riders.first,
    );
  }

  // ===========================================================================
  // AKCJE GRACZA (Promocja, Nabór, Wyścigi, Upgrade)
  // ===========================================================================

  void _promoteSelectedRiderToWorldTeam() {
    final profile = _selectedProfile;
    if (profile == null || _localPrimaryTeam == null || _localDevoTeam == null) return;

    if (profile.status == DevoRiderStatus.promotedToWorldTeam) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ten zawodnik został już awansowany do pierwszego składu.'),
          backgroundColor: AppColors.amberWarning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.5)),
        ),
        title: const Row(
          children: [
            Icon(Icons.stars, color: AppColors.primaryGold, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Awans do Pierwszej Drużyny (Neo-Pro)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Czy na pewno chcesz awansować zawodnika ${profile.rider.fullName} (wiek: ${profile.currentAge} l.) do głównego składu WorldTouru?',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _buildPromotionBenefitRow(
                    'Aktualna pensja Devo:',
                    '${profile.monthlySalaryEur} € / msc',
                    AppColors.textSecondary,
                  ),
                  const SizedBox(height: 6),
                  _buildPromotionBenefitRow(
                    'Nowy kontrakt WorldTour:',
                    '4 250 € / msc (51 000 € rocznie)',
                    AppColors.primaryGold,
                  ),
                  const SizedBox(height: 6),
                  _buildPromotionBenefitRow(
                    'Status w zespole:',
                    'Oficjalny Neo-Pro WorldTour',
                    AppColors.accentBlue,
                  ),
                  const SizedBox(height: 6),
                  _buildPromotionBenefitRow(
                    'Wpływ na morale:',
                    '+95.0 pkt (Pełna euforia zawodnika)',
                    AppColors.statusSuccess,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              try {
                final result = DevelopmentTeamU23Service.promoteRiderToFirstTeam(
                  primaryTeam: _localPrimaryTeam!,
                  devoTeam: _localDevoTeam!,
                  devoRiderId: profile.rider.id,
                );

                setState(() {
                  _localPrimaryTeam = result.updatedTeam;
                  _localDevoTeam = result.updatedDevo;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '🎉 Sukces! ${profile.rider.fullName} podpisał profesjonalny kontrakt Neo-Pro i dołączył do pierwszej drużyny!',
                    ),
                    backgroundColor: AppColors.statusSuccess,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Błąd awansu: $e'),
                    backgroundColor: AppColors.crimsonAlert,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'Podpisz kontrakt Neo-Pro',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionBenefitRow(String label, String value, Color color) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  void _openSignProspectModal() {
    final talents = DevelopmentTeamU23Service.generateAvailableYoungTalents(
      currentSeasonYear: 2026,
      count: 6,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.person_add_alt_1, color: AppColors.primaryGold, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'NABOR TALENTÓW JUNIOR & U23',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Wolni 18-letni kolarze kończący wiek juniorski, gotowi na kontrakt w Devo Squadzie.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.builder(
                itemCount: talents.length,
                itemBuilder: (context, index) {
                  final t = talents[index];
                  return _buildProspectCard(t, ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProspectCard(Rider t, BuildContext modalCtx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryGold.withValues(alpha: 0.15),
            child: Text(
              _getCountryFlagEmoji(t.nationalityIso),
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      t.fullName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Wiek: 18 l.',
                        style: TextStyle(color: AppColors.accentBlue, fontSize: 9.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${t.specialization.displayName} • Potencjał: ${t.potential}/99',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  'FTP: ${t.physiology.ftpWatts}W (${t.physiology.wattsPerKg.toStringAsFixed(2)} W/kg) • VO₂: ${t.physiology.vo2Max.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(modalCtx).pop();
              _signProspect(t);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Podpisz', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _signProspect(Rider t) {
    if (_localDevoTeam == null || _localPrimaryTeam == null) return;
    try {
      final res = DevelopmentTeamU23Service.signYoungProspectToDevo(
        primaryTeam: _localPrimaryTeam!,
        devoTeam: _localDevoTeam!,
        prospectRider: t,
        monthlySalaryEur: 2200,
        contractDurationYears: 2,
        signingBonusEur: 5000,
      );

      setState(() {
        _localPrimaryTeam = res.updatedTeam;
        _localDevoTeam = res.updatedDevo;
        _selectedRiderId = t.id;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Podpisano kontrakt młodzieżowy z ${t.fullName}!'),
          backgroundColor: AppColors.statusSuccess,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd kontraktowania: $e'),
          backgroundColor: AppColors.crimsonAlert,
        ),
      );
    }
  }

  // ===========================================================================
  // GŁÓWNY BUILD EKRANU
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final devo = _localDevoTeam;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryGold, width: 1.2),
                    ),
                    child: const Icon(Icons.school, color: AppColors.primaryGold, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        devo?.devoTeamName.toUpperCase() ?? 'AKADEMIA ROZWOJOWA U23',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Baza: ${devo?.infrastructureTier.displayName ?? "UCI Continental"} • Kadra: ${devo?.activeRidersCount ?? 0}/${devo?.infrastructureTier.maxRosterCapacity ?? 8}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_add_outlined, color: AppColors.primaryGold),
                  tooltip: 'Nabór młodych talentów U19/U23',
                  onPressed: _openSignProspectModal,
                ),
                const SizedBox(width: 8),
              ],
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppColors.primaryGold,
                labelColor: AppColors.primaryGold,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(icon: Icon(Icons.people_alt, size: 16), text: 'Kadra Devo'),
                  Tab(icon: Icon(Icons.show_chart, size: 16), text: 'Krzywe Progresji'),
                  Tab(icon: Icon(Icons.public, size: 16), text: 'Benchmark Globalny'),
                  Tab(icon: Icon(Icons.psychology, size: 16), text: 'Raporty Trenera'),
                  Tab(icon: Icon(Icons.emoji_events, size: 16), text: 'Wyścigi & Kampus'),
                ],
              ),
            )
          : null,
      body: devo == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRosterTab(theme),
                _buildProgressionCurvesTab(theme),
                _buildGlobalBenchmarkTab(theme),
                _buildCoachReportsTab(theme),
                _buildRacesAndCampusTab(theme),
              ],
            ),
    );
  }

  // ===========================================================================
  // 1. ZAKŁADKA: KADRA DEVO & MŁODZI ADEPCI
  // ===========================================================================
  Widget _buildRosterTab(ThemeData theme) {
    final devo = _localDevoTeam!;
    final filtered = devo.riders.where((p) {
      if (_specializationFilter != null &&
          p.rider.specialization != _specializationFilter) {
        return false;
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pasek filtrów specjalizacji
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(null, 'Wszyscy (${devo.riders.length})'),
                const SizedBox(width: 8),
                _buildFilterChip(RiderSpecialization.gcClimber, 'Górale GC'),
                const SizedBox(width: 8),
                _buildFilterChip(RiderSpecialization.pureSprinter, 'Sprinterzy'),
                const SizedBox(width: 8),
                _buildFilterChip(RiderSpecialization.classicCobbles, 'Klasykowcy'),
                const SizedBox(width: 8),
                _buildFilterChip(RiderSpecialization.timeTrialist, 'Czasowcy'),
                const SizedBox(width: 8),
                _buildFilterChip(RiderSpecialization.puncher, 'Puncherzy'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Lista kolarzy Devo
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Brak kolarzy w wybranej kategorii specjalizacji.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final profile = filtered[index];
                      final isSelected = profile.rider.id == _selectedRiderId;
                      return _buildDevoRiderCard(profile, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(RiderSpecialization? spec, String label) {
    final isSelected = _specializationFilter == spec;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : AppColors.textPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: AppColors.surfaceLight,
      selectedColor: AppColors.primaryGold,
      checkmarkColor: Colors.black,
      onSelected: (_) {
        setState(() {
          _specializationFilter = spec;
        });
      },
    );
  }

  Widget _buildDevoRiderCard(DevoRiderProfile profile, bool isSelected) {
    final r = profile.rider;
    final flag = _getCountryFlagEmoji(r.nationalityIso);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRiderId = r.id;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGold.withValues(alpha: 0.12)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : AppColors.cardBorder,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.backgroundDark,
                  child: Text(flag, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            r.fullName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(profile.status),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Wiek: ${profile.currentAge} l. • ${r.specialization.displayName} • Potencjał: ${r.potential}/99',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${r.physiology.ftpWatts} W',
                      style: const TextStyle(
                        color: AppColors.accentBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${r.physiology.wattsPerKg.toStringAsFixed(2)} W/kg',
                      style: const TextStyle(
                        color: AppColors.emeraldGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Wskaźniki parametrów fizjologicznych i wypalenia
            Row(
              children: [
                _buildMetricMiniPill('VO₂max', '${r.physiology.vo2Max.toStringAsFixed(1)} ml'),
                const SizedBox(width: 6),
                _buildMetricMiniPill(
                  'VLaMax',
                  (r.physiology.labProfile?.vlaMaxMmolLPerSec ?? 0.50).toStringAsFixed(2),
                ),
                const SizedBox(width: 6),
                _buildMetricMiniPill('Dni ścig.', '${profile.raceDaysThisSeason} d.'),
                const Spacer(),
                // Wskaźnik burnoutu
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.battery_alert,
                      size: 13,
                      color: profile.isOvertrained
                          ? AppColors.crimsonAlert
                          : (profile.burnoutFatigueIndex > 45 ? AppColors.amberWarning : AppColors.statusSuccess),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Zmęczenie: ${profile.burnoutFatigueIndex.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: profile.isOvertrained
                            ? AppColors.crimsonAlert
                            : AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DevoRiderStatus status) {
    Color color;
    switch (status) {
      case DevoRiderStatus.activeU23:
        color = AppColors.emeraldGreen;
        break;
      case DevoRiderStatus.stagiaire:
        color = AppColors.primaryGold;
        break;
      case DevoRiderStatus.promotedToWorldTeam:
        color = AppColors.accentBlue;
        break;
      case DevoRiderStatus.demotedFromWorldTeam:
        color = AppColors.amberWarning;
        break;
      case DevoRiderStatus.graduatedAgeLimit:
        color = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildMetricMiniPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ===========================================================================
  // 2. ZAKŁADKA: KRZYWE PROGRESJI FIZJOLOGICZNEJ
  // ===========================================================================
  Widget _buildProgressionCurvesTab(ThemeData theme) {
    final profile = _selectedProfile;
    if (profile == null) {
      return const Center(child: Text('Wybierz kolarza z kadry Devo.', style: TextStyle(color: AppColors.textSecondary)));
    }

    final audits = profile.auditHistory;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nagłówek wybranego adepta z przyciskiem Promocji
          _buildSelectedRiderHeaderCard(profile),
          const SizedBox(height: 16),

          // Przełącznik metryk krzywej progresji
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DevoMetricType.values.map((metric) {
                final isSelected = _selectedMetric == metric;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(metric.label),
                    selected: isSelected,
                    selectedColor: metric.color.withValues(alpha: 0.25),
                    backgroundColor: AppColors.surfaceLight,
                    labelStyle: TextStyle(
                      color: isSelected ? metric.color : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: isSelected ? metric.color : AppColors.cardBorder,
                      width: 1.0,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedMetric = metric;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // GŁÓWNY WYKRES KRZYWEJ PROGRESJI W CUSTOMPAINTER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.timeline, color: _selectedMetric.color, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'EWOLUCJA W CZASIE: ${_selectedMetric.label.toUpperCase()}',
                      style: TextStyle(
                        color: _selectedMetric.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Ostatni pomiar: ${_getLatestMetricValue(audits, _selectedMetric)} ${_selectedMetric.unit}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: CustomPaint(
                    painter: _DevoProgressionCurvePainter(
                      snapshots: audits,
                      metric: _selectedMetric,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // TABELA HISTORYCZNYCH AUDYTÓW
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: AppColors.primaryGold, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'HISTORIA AUDYTÓW WYDOLNOŚCIOWYCH (LABORATORIUM DEVO)',
                      style: TextStyle(
                        color: AppColors.primaryGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(1.0),
                    2: FlexColumnWidth(1.0),
                    3: FlexColumnWidth(1.0),
                    4: FlexColumnWidth(2.0),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1.0)),
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text('Data', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text('FTP (W)', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text('W/kg', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text('VO₂max', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text('Notatka Trenera', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    ...audits.map((s) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '${s.testDate.day}.${s.testDate.month}.${s.testDate.year}',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 10.5),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('${s.ftpWatts}W', style: const TextStyle(color: AppColors.accentBlue, fontSize: 10.5, fontWeight: FontWeight.w700)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(s.wattsPerKg.toStringAsFixed(2), style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 10.5, fontWeight: FontWeight.w700)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(s.vo2Max.toStringAsFixed(1), style: const TextStyle(color: AppColors.primaryGold, fontSize: 10.5, fontWeight: FontWeight.w700)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(s.notes, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedRiderHeaderCard(DevoRiderProfile profile) {
    final r = profile.rider;
    final isPromoted = profile.status == DevoRiderStatus.promotedToWorldTeam;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.backgroundDark,
            child: Text(_getCountryFlagEmoji(r.nationalityIso), style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      r.fullName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(profile.status),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${profile.currentAge} lat • ${r.specialization.displayName} • Waga: ${r.physiology.weightKg.toStringAsFixed(1)} kg',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: isPromoted ? null : _promoteSelectedRiderToWorldTeam,
            icon: Icon(
              isPromoted ? Icons.check : Icons.upgrade,
              size: 18,
            ),
            label: Text(
              isPromoted ? 'W Pierwszym Składzie' : 'Promuj do WorldTeamu (Neo-Pro)',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPromoted ? AppColors.surfaceLight : AppColors.primaryGold,
              foregroundColor: isPromoted ? AppColors.textSecondary : Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  String _getLatestMetricValue(List<PhysiologicalAuditSnapshot> snapshots, DevoMetricType metric) {
    if (snapshots.isEmpty) return '0';
    final last = snapshots.last;
    switch (metric) {
      case DevoMetricType.ftpWatts:
        return '${last.ftpWatts}';
      case DevoMetricType.wattsPerKg:
        return last.wattsPerKg.toStringAsFixed(2);
      case DevoMetricType.vo2Max:
        return last.vo2Max.toStringAsFixed(1);
      case DevoMetricType.sprintPower5s:
        return '${last.maxSprintPower5s}';
      case DevoMetricType.vlaMax:
        return last.vlaMax.toStringAsFixed(2);
    }
  }

  // ===========================================================================
  // 3. ZAKŁADKA: BENCHMARK I PORÓWNANIE ZE ŚWIATEM
  // ===========================================================================
  Widget _buildGlobalBenchmarkTab(ThemeData theme) {
    final profile = _selectedProfile;
    if (profile == null) {
      return const Center(child: Text('Wybierz kolarza z kadry Devo.', style: TextStyle(color: AppColors.textSecondary)));
    }

    final r = profile.rider;
    final wKg = r.physiology.wattsPerKg;
    final vo2 = r.physiology.vo2Max;

    // Wyliczanie percentyla globalnego U23
    final percentile = _calculateGlobalPeerPercentile(r);
    final tierTitle = _getPercentileTierTitle(percentile);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSelectedRiderHeaderCard(profile),
          const SizedBox(height: 16),

          // Karta percentyla światowego
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.backgroundDark,
                  AppColors.surfaceLight,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                const Icon(Icons.stars, color: AppColors.primaryGold, size: 36),
                const SizedBox(height: 8),
                Text(
                  'GLOBALNY RANKING U23: TOP ${(100 - percentile).toStringAsFixed(1)}% NA ŚWIECIE',
                  style: const TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tierTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Na tle ponad 1200 orlików i juniorów z kadr narodowych i zespołów kontynentalnych UCI, '
                  '${r.fullName} wyróżnia się ponadprzeciętnym profilem fizjologicznym.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SŁUPKI PORÓWNAWCZE Z BENCHMARKIEM ŚWIATOWYM
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PORÓWNANIE Z METRYKAMI ŚWIATOWYMI U23',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),

                _buildBenchmarkBarRow(
                  label: 'Moc 20 min (W/kg)',
                  riderValue: wKg,
                  peerAvg: 4.90,
                  eliteBenchmark: 6.20,
                  unit: 'W/kg',
                ),
                const SizedBox(height: 12),

                _buildBenchmarkBarRow(
                  label: 'Pułap Tlenowy (VO₂max)',
                  riderValue: vo2,
                  peerAvg: 72.0,
                  eliteBenchmark: 88.0,
                  unit: 'ml/kg/min',
                ),
                const SizedBox(height: 12),

                _buildBenchmarkBarRow(
                  label: 'Maksymalny Sprint 5s (Wat)',
                  riderValue: r.powerProfile.watts5s.toDouble(),
                  peerAvg: 1150.0,
                  eliteBenchmark: 1650.0,
                  unit: 'W',
                ),
                const SizedBox(height: 12),

                _buildBenchmarkBarRow(
                  label: 'Zmysł Taktyczny (Race IQ)',
                  riderValue: r.skills.raceIq.toDouble(),
                  peerAvg: 62.0,
                  eliteBenchmark: 90.0,
                  unit: 'pkt',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkBarRow({
    required String label,
    required double riderValue,
    required double peerAvg,
    required double eliteBenchmark,
    required String unit,
  }) {
    final double fraction = (riderValue / eliteBenchmark).clamp(0.0, 1.0);
    final double peerFraction = (peerAvg / eliteBenchmark).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(
              '${riderValue.toStringAsFixed(1)} $unit ',
              style: const TextStyle(color: AppColors.primaryGold, fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
            Text(
              '(Śr. U23: ${peerAvg.toStringAsFixed(1)})',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentBlue, AppColors.primaryGold],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            // Znacznik średniej rówieśników
            Positioned(
              left: (MediaQuery.of(context).size.width - 64) * peerFraction,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _calculateGlobalPeerPercentile(Rider r) {
    final wKg = r.physiology.wattsPerKg;
    final vo2 = r.physiology.vo2Max;
    final score = (wKg * 10.0) + (vo2 * 0.4) + (r.potential * 0.3);

    // Skala od 50 do 99 percentile
    return (score - 60.0).clamp(50.0, 99.5);
  }

  String _getPercentileTierTitle(double percentile) {
    if (percentile >= 97.0) return 'Diament Pokoleniowy (Kaliber Pogačara & Evenepoela)';
    if (percentile >= 90.0) return 'Elitarny Prospekt WorldTour (Przyszły Lider Klasyfikacji)';
    if (percentile >= 75.0) return 'Solidny Kandydat Zawodowy (Poziom ProTeam / Pomocnik WT)';
    return 'Kandydat Kontynentalny (Solidny Rzemieślnik Peletonu)';
  }

  // ===========================================================================
  // 4. ZAKŁADKA: RAPORTY TRENERA MŁODZIEŻY & MENTORING
  // ===========================================================================
  Widget _buildCoachReportsTab(ThemeData theme) {
    final profile = _selectedProfile;
    if (profile == null) {
      return const Center(child: Text('Wybierz kolarza z kadry Devo.', style: TextStyle(color: AppColors.textSecondary)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSelectedRiderHeaderCard(profile),
          const SizedBox(height: 16),

          // Karta Raportu Trenera
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.accentBlue,
                      child: Icon(Icons.person, color: Colors.black, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DIRK DE WOLF',
                          style: TextStyle(
                            color: AppColors.accentBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'Szef Przygotowania Fizycznego & Trener Główny Devo',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('RAPORT MIESIĘCZNY', style: TextStyle(color: AppColors.textSecondary, fontSize: 9.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '„${_generateCoachAssessmentText(profile)}”',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildReportPill(
                      'Podatność na kontuzje: Niska',
                      AppColors.statusSuccess,
                      Icons.healing,
                    ),
                    _buildReportPill(
                      'Etyka treningowa: Wzorowa',
                      AppColors.primaryGold,
                      Icons.verified,
                    ),
                    _buildReportPill(
                      profile.isOvertrained
                          ? 'Alert zmęczenia: WYPALENIE!'
                          : 'Poziom energii: Optymalny',
                      profile.isOvertrained ? AppColors.crimsonAlert : AppColors.emeraldGreen,
                      Icons.bolt,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Karta Mentora
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.handshake_outlined, color: AppColors.primaryGold, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'PROGRAM MENTORINGU WETERANA (SENIOR MENTORSHIP)',
                      style: TextStyle(
                        color: AppColors.primaryGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  profile.seniorMentorName != null
                      ? 'Przypisany mentor: ${profile.seniorMentorName}. '
                          'Młody kolarz czerpie z doświadczenia weterana, zyskując +25% do tempa adaptacji taktycznej.'
                      : 'Brak przypisanego mentora. Wybierz doświadczonego kolarza z pierwszego zespołu, by przyspieszyć rozwój adepta.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _assignMentorToRider(profile),
                  icon: const Icon(Icons.person_pin, size: 16),
                  label: Text(
                    profile.seniorMentorName != null ? 'Zmień Mentora' : 'Przypisz Mentora z WorldTeamu',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primaryGold,
                    side: const BorderSide(color: AppColors.primaryGold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _generateCoachAssessmentText(DevoRiderProfile profile) {
    final r = profile.rider;
    if (profile.isOvertrained) {
      return '${r.fullName} wykazuje objawy ostrego przemęczenia po ostatnich startach (${profile.raceDaysThisSeason} dni wyścigowych). '
          'Zalecam bezwzględne odstawienie od startów na 2-3 tygodnie, skupienie na regeneracji i sen, aby uniknąć załamania formy.';
    }

    if (r.physiology.ftpWatts >= 350) {
      return '${r.fullName} rozwija się w zastraszającym tempie! Silnik o mocy ${r.physiology.ftpWatts}W '
          'przy wadze ${r.physiology.weightKg.toStringAsFixed(1)}kg oznacza, że chłopak jest już gotowy na zderzenie z peletonem WorldTouru. '
          'W mojej ocenie zasłużył na natychmiastowy awans do pierwszej drużyny.';
    }

    return 'Zawodnik sumiennie realizuje założenia mikrocykli treningowych. Obserwujemy stabilny przyrost pułapu tlenowego '
        'i poprawę dynamiki na podjazdach. W kolejnym kwartale rekomenduję wystawienie go w wyścigach etapowych U23 (Ronde de l\'Isard lub Baby Giro).';
  }

  Widget _buildReportPill(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  void _assignMentorToRider(DevoRiderProfile profile) {
    final primaryTeam = _localPrimaryTeam;
    if (primaryTeam == null) return;

    // Przykładowy weteran do wyboru
    final mentor = RiderProceduralGenerator.generateRider(
      id: 'mentor_sep',
      specialization: RiderSpecialization.classicCobbles,
      targetOverallRating: 84,
      age: 33,
    );

    setState(() {
      _localDevoTeam = DevelopmentTeamU23Service.assignSeniorMentor(
        devoTeam: _localDevoTeam!,
        primaryTeam: primaryTeam,
        devoRiderId: profile.rider.id,
        seniorMentor: mentor,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Przypisano mentora ${mentor.fullName} do kolarza ${profile.rider.fullName}!'),
        backgroundColor: AppColors.statusSuccess,
      ),
    );
  }

  // ===========================================================================
  // 5. ZAKŁADKA: WYŚCIGI MŁODZIEŻOWE & KAMPUS DEVO
  // ===========================================================================
  Widget _buildRacesAndCampusTab(ThemeData theme) {
    final devo = _localDevoTeam!;
    final races = DevelopmentTeamU23Service.getOfficialYouthRaceCalendar();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Karta poziomu bazy szkoleniowej
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.surfaceLight, AppColors.backgroundDark],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.apartment, color: AppColors.primaryGold, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        devo.infrastructureTier.displayName.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Pojemność: ${devo.activeRidersCount}/${devo.infrastructureTier.maxRosterCapacity} • Mnożnik rozwoju: ${devo.infrastructureTier.growthMultiplier}x',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      Text(
                        'Miesięczny koszt utrzymania bazy: ${devo.infrastructureTier.monthlyMaintenanceCostEur} €',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                if (devo.infrastructureTier != DevoInfrastructureTier.worldClassCampus)
                  ElevatedButton(
                    onPressed: _upgradeDevoCampus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Rozbuduj', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Kalendarz wyścigów U23
          const Row(
            children: [
              Icon(Icons.calendar_month, color: AppColors.accentBlue, size: 18),
              SizedBox(width: 8),
              Text(
                'OFICJALNY KALENDARZ STARTÓW MŁODZIEŻOWYCH U23',
                style: TextStyle(
                  color: AppColors.accentBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ...races.map((race) => _buildYouthRaceCard(race)),
        ],
      ),
    );
  }

  Widget _buildYouthRaceCard(YouthRaceEvent race) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getCountryFlagEmoji(race.countryIso),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  race.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${race.uciPointsForWin} PKT UCI',
                  style: const TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            race.description,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Miesiąc: ${race.month} • Dni: ${race.durationDays} • Pula nagród: ${race.prizePoolEur} €',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _simulateRaceAction(race),
                icon: const Icon(Icons.play_arrow, size: 14),
                label: const Text('Symuluj Start', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentBlue,
                  side: const BorderSide(color: AppColors.accentBlue),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _simulateRaceAction(YouthRaceEvent race) {
    final devo = _localDevoTeam!;
    if (devo.riders.length < race.requiredMinSquadSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wymagane minimum ${race.requiredMinSquadSize} kolarzy w kadrze Devo, by wystartować w ${race.name}.'),
          backgroundColor: AppColors.amberWarning,
        ),
      );
      return;
    }

    // Wybieramy kolarzy
    final selectedIds = devo.riders.take(race.maxSquadSize).map((r) => r.rider.id).toList();

    final sim = DevelopmentTeamU23Service.simulateYouthRace(
      devoTeam: devo,
      raceEvent: race,
      participantRiderIds: selectedIds,
    );

    setState(() {
      _localDevoTeam = sim.updatedDevo;
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          race.name,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          sim.raceResult.raceReport,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold, foregroundColor: Colors.black),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _upgradeDevoCampus() {
    final devo = _localDevoTeam!;
    final nextTier = devo.infrastructureTier == DevoInfrastructureTier.regional
        ? DevoInfrastructureTier.nationalContinental
        : DevoInfrastructureTier.worldClassCampus;

    try {
      final res = DevelopmentTeamU23Service.upgradeInfrastructure(
        primaryTeam: _localPrimaryTeam!,
        devoTeam: devo,
        targetTier: nextTier,
      );

      setState(() {
        _localPrimaryTeam = res.updatedTeam;
        _localDevoTeam = res.updatedDevo;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Baza Devo rozbudowana do poziomu: ${nextTier.displayName}!'),
          backgroundColor: AppColors.statusSuccess,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd rozbudowy: $e'),
          backgroundColor: AppColors.crimsonAlert,
        ),
      );
    }
  }

  String _getCountryFlagEmoji(String iso) {
    switch (iso.toUpperCase()) {
      case 'BEL':
      case 'BE':
        return '🇧🇪';
      case 'FRA':
      case 'FR':
        return '🇫🇷';
      case 'ITA':
      case 'IT':
        return '🇮🇹';
      case 'POL':
      case 'PL':
        return '🇵🇱';
      case 'ESP':
      case 'ES':
        return '🇪🇸';
      case 'NED':
      case 'NL':
        return '🇳🇱';
      case 'GBR':
      case 'GB':
        return '🇬🇧';
      case 'DEN':
      case 'DK':
        return '🇩🇰';
      case 'SLO':
      case 'SI':
        return '🇸🇮';
      case 'COL':
      case 'CO':
        return '🇨🇴';
      default:
        return '🌐';
    }
  }
}

/// CustomPainter rysujący płynną krzywą progresji fizjologicznej adepta w czasie.
class _DevoProgressionCurvePainter extends CustomPainter {
  final List<PhysiologicalAuditSnapshot> snapshots;
  final DevoMetricType metric;

  _DevoProgressionCurvePainter({
    required this.snapshots,
    required this.metric,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (snapshots.isEmpty) return;

    final values = snapshots.map((s) => _extractValue(s, metric)).toList();
    final double minVal = values.reduce(math.min);
    final double maxVal = values.reduce(math.max);
    final double range = math.max(1.0, maxVal - minVal);

    const double paddingLeft = 36.0;
    const double paddingBottom = 26.0;
    const double paddingTop = 16.0;
    const double paddingRight = 16.0;

    final double graphWidth = size.width - paddingLeft - paddingRight;
    final double graphHeight = size.height - paddingTop - paddingBottom;

    // Linie siatki poziomej
    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    const int gridSteps = 4;
    for (int i = 0; i <= gridSteps; i++) {
      final y = paddingTop + (graphHeight / gridSteps) * i;
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      final valAtStep = maxVal - (range / gridSteps) * i;
      final textSpan = TextSpan(
        text: valAtStep.toStringAsFixed(metric == DevoMetricType.wattsPerKg || metric == DevoMetricType.vlaMax ? 1 : 0),
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 8.5),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(2, y - 6));
    }

    if (values.length < 2) return;

    // Punkty krzywej
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = paddingLeft + (graphWidth / (values.length - 1)) * i;
      final normalized = (values[i] - minVal) / range;
      final y = paddingTop + graphHeight - (normalized * graphHeight);
      points.add(Offset(x, y));
    }

    // Rysowanie gradientu wypełnienia pod wykresem
    final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      fillPath.lineTo(points[i].dx, points[i].dy);
    }
    fillPath.lineTo(points.last.dx, paddingTop + graphHeight);
    fillPath.lineTo(points.first.dx, paddingTop + graphHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          metric.color.withValues(alpha: 0.35),
          metric.color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(paddingLeft, paddingTop, graphWidth, graphHeight));

    canvas.drawPath(fillPath, fillPaint);

    // Rysowanie głównej linii krzywej
    final linePaint = Paint()
      ..color = metric.color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Rysowanie punktów audytów
    final pointPaint = Paint()
      ..color = metric.color
      ..style = PaintingStyle.fill;
    final pointInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final pt in points) {
      canvas.drawCircle(pt, 4.5, pointPaint);
      canvas.drawCircle(pt, 2.0, pointInnerPaint);
    }
  }

  double _extractValue(PhysiologicalAuditSnapshot s, DevoMetricType metric) {
    switch (metric) {
      case DevoMetricType.ftpWatts:
        return s.ftpWatts.toDouble();
      case DevoMetricType.wattsPerKg:
        return s.wattsPerKg;
      case DevoMetricType.vo2Max:
        return s.vo2Max;
      case DevoMetricType.sprintPower5s:
        return s.maxSprintPower5s.toDouble();
      case DevoMetricType.vlaMax:
        return s.vlaMax;
    }
  }

  @override
  bool shouldRepaint(covariant _DevoProgressionCurvePainter oldDelegate) {
    return oldDelegate.snapshots != snapshots || oldDelegate.metric != metric;
  }
}

