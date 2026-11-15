import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/career/career_save.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../../services/career/team_chemistry_and_builder_service.dart';
import '../../state/career_controller.dart';
import '../widgets/rider_avatar_painter.dart';

/// Ekran "Budowa Zespołu i Hierarchia" (Team Builder & Hierarchy).
/// Pozwala graczowi metodą przeciągnij-i-upuść oraz kliknij-przypisz:
/// - Wyznaczyć Głównych Liderów (Grand Tour GC, Bruki/Klasyki, Główny Sprinter),
/// - Zbudować wokół każdego lidera dedykowaną grupę pomocników (Pociąg Górski, Skład na Bruki, Lead-out Train),
/// - Wyliczać synergię grupy (% zgrania, osłona aero, premia do watów),
/// - Obliczać łączną moc pociągu górskiego w W/kg oraz prędkość pociągu sprinterskiego,
/// - Monitorować zadowolenie kolarzy z ich pozycji w drużynie i unikać konfliktów ego.
class TeamBuilderHierarchyScreen extends ConsumerStatefulWidget {
  const TeamBuilderHierarchyScreen({super.key});

  @override
  ConsumerState<TeamBuilderHierarchyScreen> createState() =>
      _TeamBuilderHierarchyScreenState();
}

class _TeamBuilderHierarchyScreenState
    extends ConsumerState<TeamBuilderHierarchyScreen> {
  // Lokalne kopie liderów i dedykowanych formacji do modyfikacji
  List<FranchiseRider> _leaders = [];
  List<DedicatedSquad> _squads = [];
  bool _isInitialized = false;

  // Filtr puli rezerwowej
  String _poolFilter = 'all';
  String _poolSearchQuery = '';

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

    final playerTeam = save.playerTeam;
    final allRoster = save.playerRoster;

    // Inicjalizacja stanu liderów i pociągów przy pierwszym wejściu
    if (!_isInitialized) {
      _initBuilderState(save, allRoster);
      _isInitialized = true;
    }

    // Wyliczenie audytu hierarchii, synergii i zadowolenia w szatni
    final audit = TeamChemistryAndBuilderService.analyzeTeamHierarchy(
      teamRoster: allRoster,
      franchiseLeaders: _leaders,
      squads: _squads,
      team: playerTeam,
    );

    // Wyznaczenie kolarzy przypisanych do jakiejkolwiek roli/pociągu
    final Set<String> assignedRiderIds = {
      for (final l in _leaders) l.riderId,
      for (final sq in _squads) ...sq.allRiderIds,
    };

    // Pula kolarzy rezerwowych (nieprzypisanych do żadnego pociągu)
    final unassignedRiders = allRoster.where((r) {
      if (assignedRiderIds.contains(r.id)) return false;

      if (_poolSearchQuery.isNotEmpty) {
        final q = _poolSearchQuery.toLowerCase();
        if (!r.fullName.toLowerCase().contains(q) && !r.countryIso.toLowerCase().contains(q)) {
          return false;
        }
      }

      switch (_poolFilter) {
        case 'climbers':
          return r.specialization == RiderSpecialization.gcClimber ||
              r.specialization == RiderSpecialization.pureClimber;
        case 'sprinters':
          return r.specialization == RiderSpecialization.pureSprinter ||
              r.specialization == RiderSpecialization.versatileSprinter;
        case 'classics':
          return r.specialization == RiderSpecialization.puncher ||
              r.specialization == RiderSpecialization.classicCobbles;
        case 'all':
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.goldAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.hub_rounded, color: AppColors.goldAccent, size: 20),
            SizedBox(width: 10),
            Text(
              'Budowa Zespołu & Hierarchia (Team Builder)',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _applyAndSaveHierarchy(context, save, careerController),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Zastosuj Hierarchię'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 1050;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Górny pasek wskaźników harmonii i audytu szatni
              _buildAuditHeaderBar(audit),

              // 2. Główny obszar roboczy (Split view na desktopie, pionowy na mobile)
              Expanded(
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Lewa część: Główne formacje i liderzy (7 flex)
                          Expanded(
                            flex: 7,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Sekcja 1: Główni Liderzy Drużyny
                                  _buildFranchiseLeadersSection(context, save, allRoster),
                                  const SizedBox(height: 20),

                                  // Sekcja 2: Dedykowane Pociągi Pomocników
                                  _buildDedicatedSquadsSection(context, save, allRoster, playerTeam),
                                ],
                              ),
                            ),
                          ),

                          // Prawa część: Pula rezerwowych i audyt konfliktów (3.5 flex)
                          Container(
                            width: 380,
                            decoration: const BoxDecoration(
                              color: Color(0xFF141824),
                              border: Border(left: BorderSide(color: AppTheme.borderColor)),
                            ),
                            child: _buildRosterPoolSidebar(context, allRoster, unassignedRiders, audit),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildFranchiseLeadersSection(context, save, allRoster),
                            const SizedBox(height: 20),
                            _buildDedicatedSquadsSection(context, save, allRoster, playerTeam),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 520,
                              child: _buildRosterPoolSidebar(context, allRoster, unassignedRiders, audit),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 1. GÓRNY PASEK AUDYTU HARMONII I PREMII SYNERGII
  // ===========================================================================

  Widget _buildAuditHeaderBar(TeamHierarchyAudit audit) {
    final double harmony = audit.overallTeamHarmonyScore.clamp(0.0, 100.0);
    final Color harmonyColor = harmony >= 75
        ? AppColors.powerZone3
        : (harmony >= 50 ? AppColors.goldAccent : AppColors.powerZone6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF131722),
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          // Wskaźnik zadowolenia w szatni
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: harmonyColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: harmonyColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.diversity_3_rounded, size: 16, color: harmonyColor),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HARMONIA SZATNI', style: TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w800)),
                    Text(
                      '${harmony.round()}% Zadowolenia',
                      style: TextStyle(color: harmonyColor, fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Pasek progresu harmonii
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      audit.hasConflicts ? '⚠️ Wykryto potencjalne konflikty hierarchii' : '✅ Optymalny podział ról w drużynie',
                      style: TextStyle(
                        color: audit.hasConflicts ? AppColors.powerZone6 : AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_leaders.length}/3 Liderów • ${_squads.length} Pociągów Pomocników',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: harmony / 100.0,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(harmonyColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. SEKCJA GŁÓWNYCH LIDERÓW ZESPOŁU (FRANCHISE LEADERS)
  // ===========================================================================

  Widget _buildFranchiseLeadersSection(
    BuildContext context,
    CareerSave save,
    List<Rider> allRoster,
  ) {
    const leaderSlots = [
      (focus: FranchiseRoleFocus.grandTourGc, label: 'Lider na Grand Toury (GC)', icon: Icons.landscape_rounded, color: AppColors.goldAccent),
      (focus: FranchiseRoleFocus.springCobbledClassics, label: 'Lider na Bruki & Monumenty', icon: Icons.handyman_rounded, color: AppColors.cyanAccent),
      (focus: FranchiseRoleFocus.pureSprintTrain, label: 'Główny Sprinter Zespołu', icon: Icons.bolt_rounded, color: AppColors.powerZone3),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.military_tech_rounded, color: AppColors.goldAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Główni Liderzy Drużyny (Franchise Riders)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                'Przeciągnij kolarza do slotu lub kliknij "+"',
                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 sloty liderów
          Row(
            children: leaderSlots.map((slot) {
              final assignedLeader = _leaders.firstWhere(
                (l) => l.focus == slot.focus,
                orElse: () => const FranchiseRider(riderId: '', riderName: '', focus: FranchiseRoleFocus.allRounder, priorityRank: 0),
              );

              final Rider? rider = assignedLeader.riderId.isNotEmpty
                  ? allRoster.firstWhere((r) => r.id == assignedLeader.riderId, orElse: () => allRoster.first)
                  : null;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildLeaderDropTargetSlot(
                    context: context,
                    slot: slot,
                    rider: rider,
                    allRoster: allRoster,
                    save: save,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderDropTargetSlot({
    required BuildContext context,
    required ({FranchiseRoleFocus focus, String label, IconData icon, Color color}) slot,
    required Rider? rider,
    required List<Rider> allRoster,
    required CareerSave save,
  }) {
    return DragTarget<Rider>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        _assignFranchiseLeader(details.data, slot.focus);
      },
      builder: (context, candidateData, rejectedData) {
        final bool isHovered = candidateData.isNotEmpty;

        return Container(
          height: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovered ? const Color(0xFF222B3D) : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered ? AppColors.goldAccent : (rider != null ? slot.color.withValues(alpha: 0.5) : Colors.white12),
              width: isHovered ? 2.0 : 1.2,
            ),
          ),
          child: rider == null
              ? InkWell(
                  onTap: () => _showRiderPickerModal(
                    context: context,
                    allRoster: allRoster,
                    title: 'Wybierz: ${slot.label}',
                    onSelected: (selectedRider) {
                      _assignFranchiseLeader(selectedRider, slot.focus);
                    },
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(slot.icon, size: 28, color: slot.color.withValues(alpha: 0.6)),
                      const SizedBox(height: 6),
                      Text(
                        slot.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+ Przypisz kolarza',
                        style: TextStyle(color: slot.color, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    Row(
                      children: [
                        RiderAvatarWidget(
                          appearance: rider.appearance,
                          team: save.playerTeam,
                          size: 52,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                slot.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: slot.color, fontSize: 9.5, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                rider.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${rider.physiology.ftpWatts}W • ${(rider.physiology.ftpWatts / rider.physiology.weightKg).toStringAsFixed(2)} W/kg',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                        tooltip: 'Usuń lidera',
                        onPressed: () {
                          setState(() {
                            _leaders.removeWhere((l) => l.focus == slot.focus);
                          });
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // ===========================================================================
  // 3. SEKCJA DEDYKOWANYCH POCIĄGÓW POMOCNIKÓW (DEDICATED SQUADS)
  // ===========================================================================

  Widget _buildDedicatedSquadsSection(
    BuildContext context,
    CareerSave save,
    List<Rider> allRoster,
    CyclingTeam playerTeam,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dedykowane Grupy Pomocników & Pociągi (Dedicated Squads)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Przydziel pomocników (górskich wspinaczy, brukowców, rozprowadzających) wokół każdego z liderów.',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),

        // Lista 3 pociągów
        ..._squads.map((squad) {
          final leader = allRoster.firstWhere(
            (r) => r.id == squad.leaderRiderId,
            orElse: () => allRoster.first,
          );

          final domestiques = allRoster.where((r) => squad.domestiqueRiderIds.contains(r.id)).toList();
          final synergy = TeamChemistryAndBuilderService.calculateSquadSynergy(
            squad: squad,
            allRiders: allRoster,
            team: playerTeam,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSquadCard(
              context: context,
              save: save,
              squad: squad,
              leader: leader,
              domestiques: domestiques,
              synergy: synergy,
              allRoster: allRoster,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSquadCard({
    required BuildContext context,
    required CareerSave save,
    required DedicatedSquad squad,
    required Rider leader,
    required List<Rider> domestiques,
    required SquadSynergyBonus synergy,
    required List<Rider> allRoster,
  }) {
    // 1. Obliczenie mocy pociągu górskiego (W/kg)
    final allMembers = [leader, ...domestiques];
    final double avgWKg = allMembers.isNotEmpty
        ? allMembers.fold<double>(0.0, (s, r) => s + (r.physiology.ftpWatts / r.physiology.weightKg)) / allMembers.length
        : 0.0;

    // 2. Obliczenie parametrów pociągu sprinterskiego
    final int avgSprintWatts = allMembers.isNotEmpty
        ? (allMembers.fold<int>(0, (s, r) => s + r.powerProfile.watts5s) / allMembers.length).round()
        : 0;
    final double leadOutSpeed = 64.0 + (avgSprintWatts / 1400.0) * 8.5;

    // 3. Oznaczenie wizualne pociągu
    final bool isMountainSquad = squad.targetSeasonObjective.toLowerCase().contains('tour') ||
        squad.name.toLowerCase().contains('górsk');
    final bool isSprintSquad = squad.name.toLowerCase().contains('sprint') ||
        squad.name.toLowerCase().contains('lead-out');

    final Color accentColor = isMountainSquad
        ? AppColors.goldAccent
        : (isSprintSquad ? AppColors.powerZone3 : AppColors.cyanAccent);

    return DragTarget<Rider>(
      onWillAcceptWithDetails: (details) => !squad.allRiderIds.contains(details.data.id),
      onAcceptWithDetails: (details) {
        _addRiderToSquad(details.data, squad.id);
      },
      builder: (context, candidateData, rejectedData) {
        final bool isHovered = candidateData.isNotEmpty;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isHovered ? const Color(0xFF1E2638) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? accentColor : AppTheme.borderColor,
              width: isHovered ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nagłówek pociągu ze wskaźnikami synergii
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isMountainSquad ? Icons.terrain_rounded : (isSprintSquad ? Icons.bolt_rounded : Icons.handyman_rounded),
                        color: accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        squad.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'Zgranie: ${synergy.cohesionRating.round()}% • Osłona Aero: +${synergy.draftingEfficiencyBonusPercent}%',
                      style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Pasek kluczowych metryk mocy formacji
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSquadMetricPill('LIDER', leader.fullName, AppColors.textPrimary),
                    _buildSquadMetricPill('LICZBA KOLARZY', '${squad.memberCount} kolarzy', AppColors.cyanAccent),
                    if (isMountainSquad)
                      _buildSquadMetricPill('ŚREDNIA MOC W GÓRACH', '${avgWKg.toStringAsFixed(2)} W/kg', AppColors.goldAccent)
                    else if (isSprintSquad)
                      _buildSquadMetricPill('PRĘDKOŚĆ ROZPROWADZENIA', '${leadOutSpeed.toStringAsFixed(1)} km/h', AppColors.powerZone3)
                    else
                      _buildSquadMetricPill('PREMIA DO TEMPA', '+${synergy.domestiquePacingWattsBonus.round()} W w ucieczce', AppColors.cyanAccent),
                    _buildSquadMetricPill('BONUS MORALE', '+${synergy.leaderMoraleBonusPercent.round()}%', AppColors.powerZone3),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Płytki kolarzy wchodzących w skład formacji
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  // Kafelek Lidera Formacji (stały)
                  _buildSquadMemberChip(
                    context: context,
                    rider: leader,
                    isLeader: true,
                    save: save,
                    accentColor: accentColor,
                    onRemove: null,
                  ),

                  // Kafelki Pomocników
                  ...domestiques.map((dom) {
                    return _buildSquadMemberChip(
                      context: context,
                      rider: dom,
                      isLeader: false,
                      save: save,
                      accentColor: accentColor,
                      onRemove: () {
                        setState(() {
                          final updatedIds = List<String>.from(squad.domestiqueRiderIds)..remove(dom.id);
                          _updateSquadDomestiques(squad.id, updatedIds);
                        });
                      },
                    );
                  }),

                  // Przycisk "+ Dodaj Pomocnika"
                  InkWell(
                    onTap: () => _showRiderPickerModal(
                      context: context,
                      allRoster: allRoster.where((r) => !squad.allRiderIds.contains(r.id)).toList(),
                      title: 'Dodaj pomocnika do: ${squad.name}',
                      onSelected: (selectedRider) {
                        _addRiderToSquad(selectedRider, squad.id);
                      },
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12, style: BorderStyle.solid),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 18, color: accentColor),
                          const SizedBox(width: 6),
                          Text(
                            'Upuść lub dodaj (+)',
                            style: TextStyle(color: accentColor, fontSize: 11.5, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSquadMetricPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 8.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildSquadMemberChip({
    required BuildContext context,
    required Rider rider,
    required bool isLeader,
    required CareerSave save,
    required Color accentColor,
    required VoidCallback? onRemove,
  }) {
    final double wKg = rider.physiology.weightKg > 0
        ? rider.physiology.ftpWatts / rider.physiology.weightKg
        : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
      decoration: BoxDecoration(
        color: isLeader ? const Color(0xFF241C10) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLeader ? AppColors.goldAccent : Colors.white12,
          width: isLeader ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RiderAvatarWidget(
            appearance: rider.appearance,
            team: save.playerTeam,
            size: 38,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    rider.lastName,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                  if (isLeader) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded, size: 12, color: AppColors.goldAccent),
                  ],
                ],
              ),
              Text(
                '${rider.physiology.ftpWatts}W (${wKg.toStringAsFixed(1)} W/kg)',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
              ),
            ],
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onRemove,
              child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. BOCZNY PANEL: PULA REZERWOWYCH I OSTRZEŻENIA SZATNI
  // ===========================================================================

  Widget _buildRosterPoolSidebar(
    BuildContext context,
    List<Rider> allRoster,
    List<Rider> unassignedRiders,
    TeamHierarchyAudit audit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Górna belka wyszukiwarki puli
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pula Rezerwowych',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${unassignedRiders.length} wolnych',
                      style: const TextStyle(color: AppColors.goldAccent, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: TextField(
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Szukaj w rezerwie...',
                    hintStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, size: 15, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _poolSearchQuery = val),
                ),
              ),
              const SizedBox(height: 8),

              // Pigułki szybkiego filtrowania
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPoolFilterChip('Wszyscy', 'all'),
                    const SizedBox(width: 6),
                    _buildPoolFilterChip('Górale', 'climbers'),
                    const SizedBox(width: 6),
                    _buildPoolFilterChip('Sprinterzy', 'sprinters'),
                    const SizedBox(width: 6),
                    _buildPoolFilterChip('Brukowcy', 'classics'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(color: AppTheme.borderColor, height: 1),

        // Lista kolarzy rezerwowych (każdy element jest Draggable<Rider>)
        Expanded(
          child: unassignedRiders.isEmpty
              ? const Center(
                  child: Text(
                    'Wszyscy kolarze zostali przypisani do ról.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: unassignedRiders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final rider = unassignedRiders[idx];
                    return _buildDraggableRiderItem(context, rider);
                  },
                ),
        ),

        // Dolna sekcja: Raport ostrzeżeń hierarchii (jeśli istnieją konflikty)
        if (audit.warnings.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF221414),
              border: Border(top: BorderSide(color: AppColors.powerZone6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.powerZone6),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Ostrzeżenia dotyczące hierarchii:',
                        style: TextStyle(color: AppColors.powerZone6, fontWeight: FontWeight.w900, fontSize: 10.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ...audit.warnings.take(2).map((w) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '• $w',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 10),
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPoolFilterChip(String label, String key) {
    final isSelected = _poolFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.goldAccent,
      backgroundColor: AppColors.surfaceLight,
      labelStyle: TextStyle(
        fontSize: 10,
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
        color: isSelected ? Colors.black : AppColors.textPrimary,
      ),
      onSelected: (_) => setState(() => _poolFilter = key),
    );
  }

  Widget _buildDraggableRiderItem(BuildContext context, Rider rider) {
    final double wKg = rider.physiology.weightKg > 0
        ? rider.physiology.ftpWatts / rider.physiology.weightKg
        : 0.0;

    final riderTile = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          RiderAvatarWidget(appearance: rider.appearance, size: 36),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rider.fullName,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 11.5),
                ),
                Text(
                  '${rider.specialization.name} • ${rider.physiology.ftpWatts}W (${wKg.toStringAsFixed(1)} W/kg)',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.goldAccent),
            tooltip: 'Przypisz do formacji',
            onSelected: (squadId) {
              _addRiderToSquad(rider, squadId);
            },
            itemBuilder: (ctx) {
              return _squads.map((s) {
                return PopupMenuItem(
                  value: s.id,
                  child: Text('Dodaj do: ${s.name}', style: const TextStyle(fontSize: 12)),
                );
              }).toList();
            },
          ),
        ],
      ),
    );

    return Draggable<Rider>(
      data: rider,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 240,
          child: Opacity(opacity: 0.9, child: riderTile),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: riderTile),
      child: riderTile,
    );
  }

  // ===========================================================================
  // 5. LOGIKA STANU, INICJALIZACJA I ZAPIS HIERARCHII
  // ===========================================================================

  void _initBuilderState(CareerSave save, List<Rider> allRoster) {
    // 1. Inicjalizacja Liderów
    if (save.franchiseLeaders.isNotEmpty) {
      _leaders = List.from(save.franchiseLeaders);
    } else {
      // Auto-wyznaczenie na start
      _leaders = [];
      final topClimber = allRoster.firstWhere(
        (r) => r.specialization == RiderSpecialization.gcClimber || r.specialization == RiderSpecialization.pureClimber,
        orElse: () => allRoster.first,
      );
      _leaders.add(FranchiseRider(
        riderId: topClimber.id,
        riderName: topClimber.fullName,
        focus: FranchiseRoleFocus.grandTourGc,
        priorityRank: 1,
      ));

      final topClassics = allRoster.firstWhere(
        (r) => (r.specialization == RiderSpecialization.classicCobbles || r.specialization == RiderSpecialization.puncher) && r.id != topClimber.id,
        orElse: () => allRoster.length > 1 ? allRoster[1] : allRoster.first,
      );
      _leaders.add(FranchiseRider(
        riderId: topClassics.id,
        riderName: topClassics.fullName,
        focus: FranchiseRoleFocus.springCobbledClassics,
        priorityRank: 2,
      ));

      final topSprinter = allRoster.firstWhere(
        (r) => (r.specialization == RiderSpecialization.pureSprinter || r.specialization == RiderSpecialization.versatileSprinter) &&
            r.id != topClimber.id &&
            r.id != topClassics.id,
        orElse: () => allRoster.length > 2 ? allRoster[2] : allRoster.first,
      );
      _leaders.add(FranchiseRider(
        riderId: topSprinter.id,
        riderName: topSprinter.fullName,
        focus: FranchiseRoleFocus.pureSprintTrain,
        priorityRank: 3,
      ));
    }

    // 2. Inicjalizacja Dedykowanych Pociągów
    if (save.dedicatedSquads.isNotEmpty) {
      _squads = List.from(save.dedicatedSquads);
    } else {
      final gtLeaderId = _leaders.isNotEmpty ? _leaders.first.riderId : allRoster.first.id;
      final classicsLeaderId = _leaders.length > 1 ? _leaders[1].riderId : allRoster.first.id;
      final sprintLeaderId = _leaders.length > 2 ? _leaders[2].riderId : allRoster.first.id;

      _squads = [
        DedicatedSquad(
          id: 'squad_mountain',
          name: 'Pociąg Górski (Grand Tour)',
          leaderRiderId: gtLeaderId,
          domestiqueRiderIds: allRoster.where((r) => r.specialization == RiderSpecialization.pureClimber && r.id != gtLeaderId).take(4).map((r) => r.id).toList(),
          targetSeasonObjective: 'Klasyfikacja Generalna Tour de France',
          cohesionScore: 82.0,
        ),
        DedicatedSquad(
          id: 'squad_cobbles',
          name: 'Formacja na Bruki i Klasyki',
          leaderRiderId: classicsLeaderId,
          domestiqueRiderIds: allRoster.where((r) => r.specialization == RiderSpecialization.classicCobbles && r.id != classicsLeaderId).take(3).map((r) => r.id).toList(),
          targetSeasonObjective: 'Paryż-Roubaix & Flandria',
          cohesionScore: 78.0,
        ),
        DedicatedSquad(
          id: 'squad_sprint',
          name: 'Pociąg Sprinterski (Lead-Out)',
          leaderRiderId: sprintLeaderId,
          domestiqueRiderIds: allRoster.where((r) => r.specialization == RiderSpecialization.versatileSprinter && r.id != sprintLeaderId).take(3).map((r) => r.id).toList(),
          targetSeasonObjective: 'Etapy sprinterskie & Zielona Koszulka',
          cohesionScore: 88.0,
        ),
      ];
    }
  }

  void _assignFranchiseLeader(Rider rider, FranchiseRoleFocus focus) {
    setState(() {
      _leaders.removeWhere((l) => l.focus == focus || l.riderId == rider.id);
      _leaders.add(FranchiseRider(
        riderId: rider.id,
        riderName: rider.fullName,
        focus: focus,
        priorityRank: focus == FranchiseRoleFocus.grandTourGc ? 1 : 2,
      ));

      // Aktualizujemy lidera w odpowiadającym pociągu
      _squads = _squads.map((sq) {
        if (focus == FranchiseRoleFocus.grandTourGc && sq.name.contains('Górsk')) {
          return sq.copyWith(leaderRiderId: rider.id);
        } else if (focus == FranchiseRoleFocus.springCobbledClassics && sq.name.contains('Bruk')) {
          return sq.copyWith(leaderRiderId: rider.id);
        } else if (focus == FranchiseRoleFocus.pureSprintTrain && sq.name.contains('Sprint')) {
          return sq.copyWith(leaderRiderId: rider.id);
        }
        return sq;
      }).toList();
    });
  }

  void _addRiderToSquad(Rider rider, String squadId) {
    setState(() {
      // Usuwamy kolarza z innych pociągów
      _squads = _squads.map((sq) {
        final filteredDomestiques = sq.domestiqueRiderIds.where((id) => id != rider.id).toList();
        if (sq.id == squadId) {
          if (!filteredDomestiques.contains(rider.id) && sq.leaderRiderId != rider.id) {
            filteredDomestiques.add(rider.id);
          }
        }
        return sq.copyWith(domestiqueRiderIds: filteredDomestiques);
      }).toList();
    });
  }

  void _updateSquadDomestiques(String squadId, List<String> updatedDomestiques) {
    setState(() {
      _squads = _squads.map((sq) {
        return sq.id == squadId ? sq.copyWith(domestiqueRiderIds: updatedDomestiques) : sq;
      }).toList();
    });
  }

  void _showRiderPickerModal({
    required BuildContext context,
    required List<Rider> allRoster,
    required String title,
    required ValueChanged<Rider> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: allRoster.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (subCtx, idx) {
                    final r = allRoster[idx];
                    return ListTile(
                      tileColor: AppColors.surfaceLight,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      leading: RiderAvatarWidget(appearance: r.appearance, size: 36),
                      title: Text(r.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      subtitle: Text('${r.specialization.name} • ${r.physiology.ftpWatts}W'),
                      onTap: () {
                        Navigator.pop(ctx);
                        onSelected(r);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyAndSaveHierarchy(
    BuildContext context,
    CareerSave save,
    CareerController careerController,
  ) {
    // 1. Zapis liderów franczyzy
    final assignments = _leaders.map((l) {
      return (riderId: l.riderId, focus: l.focus, priorityRank: l.priorityRank);
    }).toList();

    careerController.assignFranchiseLeaders(assignments);

    // 2. Zapis dedykowanych składów
    final updatedSave = save.copyWith(dedicatedSquads: _squads);
    careerController.updateSave(updatedSave);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Hierarchia zespołu i pociągi pomocników zostały pomyślnie zaktualizowane!'),
        backgroundColor: AppColors.powerZone3,
      ),
    );
  }
}

