import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/equipment/frame_model.dart';
import '../../models/equipment/groupset_model.dart';
import '../../models/equipment/tire_model.dart';
import '../../models/equipment/wheelset_model.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../../services/career/ai_team_transfer_simulation_service.dart';
import '../../state/career_state_notifier.dart';
import '../widgets/bike_preview_painter.dart';
import '../widgets/rider_avatar_painter.dart';

/// Rola kolarza zatwierdzana podczas Gali Prezentacji Zespołu przed sezonem.
enum SeasonLeaderRole {
  gcLeader('Lider GC', AppColors.goldAccent),
  classicsLeader('Lider Klasyków', AppColors.primaryAccent),
  mainSprinter('Główny Sprinter', AppColors.statusSuccess),
  roadCaptain('Kapitan Drogi', AppColors.accentBlue),
  domestique('Pomocnik', AppColors.textSecondary),
  u23Prospect('Talent U23', AppColors.cyanAccent);

  final String label;
  final Color badgeColor;

  const SeasonLeaderRole(this.label, this.badgeColor);
}

/// Wpis podsumowania zmian kadrowych przed nowym sezonem.
class RosterMovementEntry {
  final String riderName;
  final String detail;
  final String categoryLabel;
  final Color accentColor;
  final IconData icon;

  const RosterMovementEntry({
    required this.riderName,
    required this.detail,
    required this.categoryLabel,
    required this.accentColor,
    required this.icon,
  });
}

/// Uroczysty ekran Gali Prezentacji Zespołu przed startem nowego sezonu (styczeń).
class PreSeasonTeamPresentationScreen extends ConsumerStatefulWidget {
  /// Opcjonalny callback wywoływany po kliknięciu "ROZPOCZNIJ SEZON WYŚCIGOWY".
  final VoidCallback? onSeasonStarted;

  const PreSeasonTeamPresentationScreen({
    super.key,
    this.onSeasonStarted,
  });

  @override
  ConsumerState<PreSeasonTeamPresentationScreen> createState() =>
      _PreSeasonTeamPresentationScreenState();
}

class _PreSeasonTeamPresentationScreenState
    extends ConsumerState<PreSeasonTeamPresentationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spotlightController;
  final Map<String, int> _assignedNumbers = {};
  final Map<String, SeasonLeaderRole> _assignedRoles = {};
  String? _selectedLeaderId;
  bool _assignmentsConfirmed = false;
  bool _isStartingSeason = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _spotlightController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spotlightController.dispose();
    super.dispose();
  }

  void _ensureRosterInitialized(List<Rider> roster) {
    if (roster.isEmpty) return;
    final sorted = List<Rider>.from(roster)
      ..sort((a, b) => b.overallRating.compareTo(a.overallRating));

    var nextNumber = 1;
    for (final rider in sorted) {
      if (!_assignedNumbers.containsKey(rider.id)) {
        while (_assignedNumbers.values.contains(nextNumber)) {
          nextNumber++;
        }
        _assignedNumbers[rider.id] = nextNumber.clamp(1, 99);
        nextNumber++;
      }
      _assignedRoles.putIfAbsent(
        rider.id,
        () => _defaultRoleForRider(rider, sorted.indexOf(rider)),
      );
    }

    _selectedLeaderId ??= sorted.first.id;
  }

  SeasonLeaderRole _defaultRoleForRider(Rider rider, int rankIndex) {
    if (rankIndex == 0 &&
        (rider.specialization == RiderSpecialization.gcClimber ||
            rider.specialization == RiderSpecialization.pureClimber)) {
      return SeasonLeaderRole.gcLeader;
    }
    if (rider.specialization == RiderSpecialization.pureSprinter ||
        rider.specialization == RiderSpecialization.versatileSprinter) {
      return SeasonLeaderRole.mainSprinter;
    }
    if (rider.specialization == RiderSpecialization.classicCobbles ||
        rider.specialization == RiderSpecialization.puncher) {
      return SeasonLeaderRole.classicsLeader;
    }
    if (rider.age <= 23) {
      return SeasonLeaderRole.u23Prospect;
    }
    if (rankIndex <= 2) {
      return SeasonLeaderRole.roadCaptain;
    }
    return SeasonLeaderRole.domestique;
  }

  List<Rider> _selectTopThreeLeaders(List<Rider> roster) {
    final sorted = List<Rider>.from(roster)
      ..sort((a, b) => b.overallRating.compareTo(a.overallRating));
    return sorted.take(3).toList();
  }

  CompleteBike _resolveFlagshipBike(CyclingTeam team) {
    if (team.inventoryBikes.isNotEmpty) {
      return team.inventoryBikes.first;
    }
    return CompleteBike(
      id: 'gala_flagship_${team.id}',
      name: '${team.bikeDeal.manufacturerName} Team Edition ${DateTime.now().year}',
      frame: FrameModel(
        id: 'gala_frame',
        brandId: team.bikeDeal.manufacturerId,
        name: '${team.bikeDeal.manufacturerName} Aero Carbon SL',
        category: FrameCategory.aero,
        weightGrams: 720,
        aeroCdaModifier: -0.018,
        stiffnessToWeightIndex: 2.25,
        comfortCompliance: 0.78,
        priceEur: 5800,
        mesh3dAssetPath: 'assets/3d/bikes/aero_frame.glb',
        primaryColorHex: team.primaryJerseyColorHex,
      ),
      wheelset: const WheelsetModel(
        id: 'gala_wheels',
        brandId: 'carbon_pro',
        name: 'Aero Carbon 55mm Disc',
        rimDepthMm: 55,
        weightGrams: 1320,
        aeroCdaModifier: -0.011,
        crosswindStabilityPenalty: 0.25,
        momentOfInertia: 0.082,
        hubEngagementDragWatts: 1.4,
        priceEur: 2600,
      ),
      groupset: const GroupsetModel(
        id: 'gala_groupset',
        brandId: 'elec_pro',
        name: 'Pro Electronic 12s',
        weightGrams: 2150,
        isElectronic: true,
        speedCount: 12,
        mechanicalEfficiency: 0.985,
        priceEur: 3400,
      ),
      tire: const TireModel(
        id: 'gala_tire',
        brandId: 'grip_pro',
        name: 'Corsa Pro Tan-Wall 28mm',
        widthMm: 28,
        weightGrams: 245,
        rollingResistanceCrr: 0.0034,
        punctureResistanceIndex: 3.4,
        wetGripIndex: 4.5,
        isTubeless: true,
        priceEur: 85,
      ),
      cockpitWidthMm: 380,
      hoodInwardTiltDegrees: 8.0,
      slammedStem: true,
    );
  }

  List<RosterMovementEntry> _buildJoinedEntries(CareerState state) {
    final teamId = state.playerTeam.id;
    final transfersIn = state.recentTransferNews
        .where((TransferNewsItem item) => item.toTeamId == teamId)
        .map(
          (item) => RosterMovementEntry(
            riderName: item.riderName,
            detail: 'Transfer z ${item.fromTeamName} • ${item.newsType.polishLabel}',
            categoryLabel: 'Nowy kontrakt',
            accentColor: AppColors.statusSuccess,
            icon: Icons.person_add_alt_1_rounded,
          ),
        )
        .toList();

    if (transfersIn.isNotEmpty) {
      return transfersIn;
    }

    final recentSignings = state.playerRoster
        .where((r) => r.age > 23)
        .take(2)
        .map(
          (r) => RosterMovementEntry(
            riderName: r.fullName,
            detail: '${r.specialization.displayName} • OVR ${r.overallRating}',
            categoryLabel: 'Wzmocnienie kadry',
            accentColor: AppColors.statusSuccess,
            icon: Icons.person_add_alt_1_rounded,
          ),
        )
        .toList();
    return recentSignings;
  }

  List<RosterMovementEntry> _buildDepartedEntries(CareerState state) {
    final teamId = state.playerTeam.id;
    return state.recentTransferNews
        .where((TransferNewsItem item) => item.fromTeamId == teamId)
        .map(
          (item) => RosterMovementEntry(
            riderName: item.riderName,
            detail: 'Przejście do ${item.toTeamName}',
            categoryLabel: 'Odejście',
            accentColor: AppColors.crimsonAlert,
            icon: Icons.person_remove_rounded,
          ),
        )
        .toList();
  }

  List<RosterMovementEntry> _buildU23Entries(CareerState state) {
    final u23Riders = state.playerRoster.where((r) => r.age <= 23).toList()
      ..sort((a, b) => b.potential.compareTo(a.potential));

    return u23Riders
        .take(3)
        .map(
          (r) => RosterMovementEntry(
            riderName: r.fullName,
            detail:
                'Wiek ${r.age} lat • Potencjał ${r.potential} • ${r.specialization.displayName}',
            categoryLabel: 'Awans U23',
            accentColor: AppColors.accentBlue,
            icon: Icons.school_rounded,
          ),
        )
        .toList();
  }

  List<TourRace> _resolveTargetRacesForLeader(
    Rider leader,
    List<TourRace> calendarRaces,
  ) {
    if (calendarRaces.isEmpty) return const [];

    bool matches(TourRace race) {
      switch (leader.specialization) {
        case RiderSpecialization.gcClimber:
        case RiderSpecialization.pureClimber:
          return race.uciCategory == RaceCategory.grandTour ||
              race.uciCategory == RaceCategory.worldTourStageRace;
        case RiderSpecialization.classicCobbles:
        case RiderSpecialization.puncher:
          return race.uciCategory == RaceCategory.monument ||
              race.uciCategory == RaceCategory.worldTourOneDay;
        case RiderSpecialization.pureSprinter:
        case RiderSpecialization.versatileSprinter:
          return race.uciCategory == RaceCategory.worldTourOneDay ||
              race.uciCategory == RaceCategory.proSeries ||
              race.uciCategory == RaceCategory.grandTour;
        case RiderSpecialization.timeTrialist:
        case RiderSpecialization.domestiqueEngine:
        case RiderSpecialization.breakawaySpecialist:
          return race.uciCategory == RaceCategory.worldTourStageRace ||
              race.uciCategory == RaceCategory.grandTour;
      }
    }

    final matched = calendarRaces.where(matches).take(2).toList();
    if (matched.isNotEmpty) return matched;
    return calendarRaces.take(2).toList();
  }

  String _targetObjectiveForLeader(Rider leader) {
    switch (leader.specialization) {
      case RiderSpecialization.gcClimber:
      case RiderSpecialization.pureClimber:
        return 'Walka o podium klasyfikacji generalnej (GC)';
      case RiderSpecialization.classicCobbles:
      case RiderSpecialization.puncher:
        return 'Finałowa rozgrywka i podium w Monumentach';
      case RiderSpecialization.pureSprinter:
      case RiderSpecialization.versatileSprinter:
        return 'Zwycięstwa etapowe i koszulka punktowa';
      case RiderSpecialization.timeTrialist:
        return 'Triumfy w jeździe na czas i prologach';
      case RiderSpecialization.domestiqueEngine:
      case RiderSpecialization.breakawaySpecialist:
        return 'Ucieczki dnia i wsparcie liderów w górach';
    }
  }

  void _updateRiderNumber(String riderId, int delta) {
    final current = _assignedNumbers[riderId] ?? 1;
    final next = (current + delta).clamp(1, 99);
    if (next == current) return;

    setState(() {
      _assignedNumbers[riderId] = next;
      _assignmentsConfirmed = false;
      _validationError = null;
    });
  }

  void _updateRiderRole(String riderId, SeasonLeaderRole role) {
    setState(() {
      _assignedRoles[riderId] = role;
      _assignmentsConfirmed = false;
      _validationError = null;
    });
  }

  void _confirmNumbersAndRoles(List<Rider> roster) {
    final usedNumbers = <int>{};
    for (final rider in roster) {
      final numValue = _assignedNumbers[rider.id];
      if (numValue == null || numValue < 1 || numValue > 99) {
        setState(() {
          _validationError =
              'Kolarz ${rider.fullName} musi mieć przypisany numer z zakresu 1–99.';
          _assignmentsConfirmed = false;
        });
        return;
      }
      if (!usedNumbers.add(numValue)) {
        setState(() {
          _validationError =
              'Numer #$numValue jest przypisany do więcej niż jednego kolarza. Każdy numer w zespole musi być unikalny.';
          _assignmentsConfirmed = false;
        });
        return;
      }
    }

    setState(() {
      _validationError = null;
      _assignmentsConfirmed = true;
    });
  }

  Future<void> _startRacingSeason(
    CareerState state,
    List<Rider> leaders,
    CompleteBike flagshipBike,
  ) async {
    if (!_assignmentsConfirmed || _isStartingSeason) return;

    setState(() {
      _isStartingSeason = true;
    });

    final team = state.playerTeam;
    final seasonYear = state.currentSeasonYear;
    final leaderLines = leaders.map((leader) {
      final bib = _assignedNumbers[leader.id] ?? 1;
      final role = _assignedRoles[leader.id]?.label ?? 'Lider';
      final targets = _resolveTargetRacesForLeader(leader, state.calendar.races)
          .map((r) => r.name)
          .join(', ');
      return '• #$bib ${leader.fullName} ($role) — cele: ${targets.isEmpty ? "Kalendarz WorldTour" : targets}';
    }).join('\n');

    final article = CareerInboxMessage(
      id: 'gala_press_${seasonYear}_${DateTime.now().millisecondsSinceEpoch}',
      date: state.currentDate,
      senderName: 'Redakcja CyclingWorld Media',
      senderRole: 'Prasa Kolarska • Gala Prezentacji',
      subject:
          'Oficjalna prezentacja ${team.name} na sezon $seasonYear! Znamy liderów i nowy rower',
      body:
          'Podczas dzisiejszej uroczystej Gali Prezentacji Zespołu w świetle reflektorów drużyna ${team.name} '
          'odsłoniła barwy oraz flagową maszynę ${flagshipBike.name} (${flagshipBike.totalWeightKg.toStringAsFixed(2)} kg) na sezon $seasonYear.\n\n'
          'Główni liderzy i zatwierdzone numery startowe:\n$leaderLines\n\n'
          'Zespół wyrusza teraz na styczniowe wyścigi otwarcia sezonu!',
      category: InboxCategory.general,
      priority: InboxPriority.normal,
      actionLabel: 'Przejdź do kalendarza',
    );

    ref.read(careerStateNotifierProvider.notifier).addInboxMessage(article);

    if (!mounted) return;
    if (widget.onSeasonStarted != null) {
      widget.onSeasonStarted!();
    } else {
      context.goToCalendar();
    }
  }

  Color _parseHexColor(String hex, Color fallback) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final parsed = int.tryParse('FF$clean', radix: 16);
      if (parsed != null) return Color(parsed);
    } else if (clean.length == 8) {
      final parsed = int.tryParse(clean, radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final careerState = ref.watch(careerStateNotifierProvider);
    final team = careerState.playerTeam;
    final roster = careerState.playerRoster;
    _ensureRosterInitialized(roster);

    final leaders = _selectTopThreeLeaders(roster);
    final flagshipBike = _resolveFlagshipBike(team);
    final primaryColor =
        _parseHexColor(team.primaryJerseyColorHex, AppColors.primaryAccent);
    final secondaryColor =
        _parseHexColor(team.secondaryJerseyColorHex, AppColors.goldAccent);
    final accentColor =
        _parseHexColor(team.accentJerseyColorHex, AppColors.goldAccent);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 700;
            final isTablet = width >= 700 && width < 1200;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : (isTablet ? 24 : 36),
                vertical: isMobile ? 16 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(careerState, team, accentColor, isMobile),
                      const SizedBox(height: 20),
                      _buildGalaStageSection(
                        team: team,
                        seasonYear: careerState.currentSeasonYear,
                        leaders: leaders,
                        flagshipBike: flagshipBike,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        accentColor: accentColor,
                        isMobile: isMobile,
                        isTablet: isTablet,
                      ),
                      const SizedBox(height: 24),
                      _buildMovementsAndTargetsSection(
                        careerState: careerState,
                        leaders: leaders,
                        isMobile: isMobile,
                        isTablet: isTablet,
                      ),
                      const SizedBox(height: 24),
                      _buildRosterNumbersAndRolesCard(
                        roster: roster,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 24),
                      _buildStartSeasonFooter(
                        careerState: careerState,
                        leaders: leaders,
                        flagshipBike: flagshipBike,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 16),
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

  Widget _buildHeader(
    CareerState state,
    CyclingTeam team,
    Color teamAccent,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: teamAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: teamAccent.withValues(alpha: 0.5)),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: teamAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GALA PREZENTACJI ZESPOŁU • SEZON ${state.currentSeasonYear}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      team.name,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 20 : 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.goldAccent,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Styczeń ${state.currentSeasonYear} • ${team.division.label}',
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
          ),
        ],
      ),
    );
  }

  Widget _buildGalaStageSection({
    required CyclingTeam team,
    required int seasonYear,
    required List<Rider> leaders,
    required CompleteBike flagshipBike,
    required Color primaryColor,
    required Color secondaryColor,
    required Color accentColor,
    required bool isMobile,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _spotlightController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _GalaStageSpotlightPainter(
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                    accentColor: accentColor,
                    animationValue: _spotlightController.value,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        'SCENA GŁÓWNA • LIDERZY & MASZYNA $seasonYear',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: accentColor,
                        ),
                      ),
                    ),
                    if (!isMobile)
                      Text(
                        'Kliknij lidera, aby wyróżnić jego profil',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                if (isMobile) ...[
                  _buildLeadersStageRow(
                    leaders: leaders,
                    team: team,
                    accentColor: accentColor,
                    isMobile: true,
                  ),
                  const SizedBox(height: 20),
                  _buildBikeStageShowcase(
                    bike: flagshipBike,
                    team: team,
                    accentColor: accentColor,
                    height: 200,
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: isTablet ? 6 : 7,
                        child: _buildLeadersStageRow(
                          leaders: leaders,
                          team: team,
                          accentColor: accentColor,
                          isMobile: false,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: isTablet ? 5 : 5,
                        child: _buildBikeStageShowcase(
                          bike: flagshipBike,
                          team: team,
                          accentColor: accentColor,
                          height: isTablet ? 230 : 270,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadersStageRow({
    required List<Rider> leaders,
    required CyclingTeam team,
    required Color accentColor,
    required bool isMobile,
  }) {
    if (leaders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Text(
          'Brak zawodników w składzie drużyny do zaprezentowania na scenie.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: isMobile ? 12 : 20,
      runSpacing: 16,
      children: leaders.asMap().entries.map((entry) {
        final idx = entry.key;
        final rider = entry.value;
        final isSelected = _selectedLeaderId == rider.id;
        final bib = _assignedNumbers[rider.id] ?? (idx + 1);
        final role = _assignedRoles[rider.id] ?? SeasonLeaderRole.gcLeader;
        final avatarSize = isMobile ? 96.0 : (idx == 0 ? 148.0 : 128.0);

        return _GalaLeaderStageCard(
          rider: rider,
          team: team,
          bibNumber: bib,
          role: role,
          rank: idx + 1,
          avatarSize: avatarSize,
          isSelected: isSelected,
          accentColor: accentColor,
          onTap: () {
            setState(() {
              _selectedLeaderId = rider.id;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildBikeStageShowcase({
    required CompleteBike bike,
    required CyclingTeam team,
    required Color accentColor,
    required double height,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOWY ROWER WYŚCIGOWY',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bike.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  '${bike.totalWeightKg.toStringAsFixed(2)} kg',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.goldAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BikePreviewWidget(
            bike: bike,
            height: height,
            showBackground: false,
            showSpecsPill: false,
            showFloorReflection: true,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildBikeSpecChip('Rama', bike.frame.name),
              _buildBikeSpecChip('Koła', '${bike.wheelset.rimDepthMm}mm'),
              _buildBikeSpecChip('Napęd', bike.groupset.name),
              _buildBikeSpecChip('Opony', '${bike.tire.widthMm}mm'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBikeSpecChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMovementsAndTargetsSection({
    required CareerState careerState,
    required List<Rider> leaders,
    required bool isMobile,
    required bool isTablet,
  }) {
    final joined = _buildJoinedEntries(careerState);
    final departed = _buildDepartedEntries(careerState);
    final u23 = _buildU23Entries(careerState);

    final movementsCard = _buildRosterMovementsCard(
      joined: joined,
      departed: departed,
      u23: u23,
    );
    final targetsCard = _buildLeaderTargetsCard(
      leaders: leaders,
      calendarRaces: careerState.calendar.races,
    );

    if (isMobile || isTablet) {
      return Column(
        children: [
          movementsCard,
          const SizedBox(height: 20),
          targetsCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: movementsCard),
        const SizedBox(width: 24),
        Expanded(flex: 6, child: targetsCard),
      ],
    );
  }

  Widget _buildRosterMovementsCard({
    required List<RosterMovementEntry> joined,
    required List<RosterMovementEntry> departed,
    required List<RosterMovementEntry> u23,
  }) {
    return Container(
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
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'PODSUMOWANIE ZMIAN KADROWYCH',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMovementGroup(
            title: 'Dołączyli do zespołu',
            entries: joined,
            emptyText: 'Brak nowych transferów przychodzących przed sezonem.',
          ),
          const SizedBox(height: 14),
          _buildMovementGroup(
            title: 'Odeszli z zespołu',
            entries: departed,
            emptyText: 'Skład utrzymany — brak odejść w oknie transferowym.',
          ),
          const SizedBox(height: 14),
          _buildMovementGroup(
            title: 'Awans z Akademii U23',
            entries: u23,
            emptyText: 'Brak zawodników U23 włączonych do pierwszego składu.',
          ),
        ],
      ),
    );
  }

  Widget _buildMovementGroup({
    required String title,
    required List<RosterMovementEntry> entries,
    required String emptyText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Text(
              emptyText,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          ...entries.map(
            (e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: e.accentColor.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(e.icon, color: e.accentColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.riderName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          e.detail,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: e.accentColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      e.categoryLabel,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: e.accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLeaderTargetsCard({
    required List<Rider> leaders,
    required List<TourRace> calendarRaces,
  }) {
    return Container(
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
            children: [
              Icon(
                Icons.flag_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'GŁÓWNE WYŚCIGI DOCELOWE LIDERÓW',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (leaders.isEmpty)
            const Text(
              'Brak zdefiniowanych liderów w kadrze.',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
              ),
            )
          else
            ...leaders.map((leader) {
              final targets =
                  _resolveTargetRacesForLeader(leader, calendarRaces);
              final isHighlighted = _selectedLeaderId == leader.id;
              final bib = _assignedNumbers[leader.id] ?? 1;
              final role =
                  _assignedRoles[leader.id] ?? SeasonLeaderRole.gcLeader;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? AppColors.surfaceLight
                      : AppColors.background.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isHighlighted
                        ? AppColors.goldAccent
                        : AppTheme.borderColor,
                    width: isHighlighted ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: role.badgeColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$bib',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: role.badgeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            leader.fullName,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          role.label,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: role.badgeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _targetObjectiveForLeader(leader),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: targets.isEmpty
                          ? [
                              _buildRaceTargetChip(
                                'Kalendarz WorldTour',
                                'Cały sezon',
                              ),
                            ]
                          : targets
                              .map(
                                (race) => _buildRaceTargetChip(
                                  race.name,
                                  '${_monthShortName(race.startMonth)} • ${race.stages.length} et.',
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRaceTargetChip(String raceName, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 14,
            color: AppColors.goldAccent,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$raceName ($subtitle)',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterNumbersAndRolesCard({
    required List<Rider> roster,
    required bool isMobile,
  }) {
    final sortedRoster = List<Rider>.from(roster)
      ..sort((a, b) => b.overallRating.compareTo(a.overallRating));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.badge_rounded,
                    color: AppColors.goldAccent,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'ZATWIERDZENIE NUMERÓW I RÓL NA SEZON',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              _buildConfirmRolesButton(roster),
            ],
          ),
          if (_validationError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.crimsonAlert.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.crimsonAlert),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.crimsonAlert,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _validationError!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...sortedRoster.map((rider) {
            final number = _assignedNumbers[rider.id] ?? 1;
            final role =
                _assignedRoles[rider.id] ?? SeasonLeaderRole.domestique;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRiderRowIdentity(rider),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildBibStepper(rider.id, number),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildRoleDropdown(rider.id, role),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: _buildRiderRowIdentity(rider),
                        ),
                        const SizedBox(width: 12),
                        _buildBibStepper(rider.id, number),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 200,
                          child: _buildRoleDropdown(rider.id, role),
                        ),
                      ],
                    ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRiderRowIdentity(Rider rider) {
    return Row(
      children: [
        RiderAvatarWidget.fromRider(
          rider: rider,
          size: 38,
          showHelmet: false,
          showGlasses: false,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rider.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${rider.specialization.displayName} • OVR ${rider.overallRating}',
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
    );
  }

  Widget _buildBibStepper(String riderId, int number) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperIconButton(
          icon: Icons.remove_rounded,
          tooltip: 'Zmniejsz numer',
          onPressed: number > 1 ? () => _updateRiderNumber(riderId, -1) : null,
        ),
        Container(
          width: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 6),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Text(
            '#$number',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.goldAccent,
            ),
          ),
        ),
        _StepperIconButton(
          icon: Icons.add_rounded,
          tooltip: 'Zwiększ numer',
          onPressed: number < 99 ? () => _updateRiderNumber(riderId, 1) : null,
        ),
      ],
    );
  }

  Widget _buildRoleDropdown(String riderId, SeasonLeaderRole currentRole) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SeasonLeaderRole>(
          value: currentRole,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          iconEnabledColor: AppColors.textSecondary,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: SeasonLeaderRole.values.map((role) {
            return DropdownMenuItem<SeasonLeaderRole>(
              value: role,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: role.badgeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      role.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              _updateRiderRole(riderId, val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildConfirmRolesButton(List<Rider> roster) {
    return OutlinedButton.icon(
      onPressed: roster.isEmpty ? null : () => _confirmNumbersAndRoles(roster),
      icon: Icon(
        _assignmentsConfirmed
            ? Icons.verified_rounded
            : Icons.check_circle_outline_rounded,
        size: 18,
      ),
      label: Text(
        _assignmentsConfirmed
            ? 'NUMERY I ROLE ZATWIERDZONE'
            : 'ZATWIERDŹ NUMERY I ROLE',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textSecondary.withValues(alpha: 0.4);
          }
          return _assignmentsConfirmed
              ? AppColors.statusSuccess
              : AppColors.goldAccent;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.goldAccent.withValues(alpha: 0.22);
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return (_assignmentsConfirmed
                    ? AppColors.statusSuccess
                    : AppColors.goldAccent)
                .withValues(alpha: 0.14);
          }
          return (_assignmentsConfirmed
                  ? AppColors.statusSuccess
                  : AppColors.goldAccent)
              .withValues(alpha: 0.08);
        }),
        side: WidgetStateProperty.resolveWith((states) {
          final color = _assignmentsConfirmed
              ? AppColors.statusSuccess
              : AppColors.goldAccent;
          if (states.contains(WidgetState.focused)) {
            return BorderSide(color: color, width: 2.0);
          }
          return BorderSide(color: color.withValues(alpha: 0.6), width: 1.0);
        }),
      ),
    );
  }

  Widget _buildStartSeasonFooter({
    required CareerState careerState,
    required List<Rider> leaders,
    required CompleteBike flagshipBike,
    required bool isMobile,
  }) {
    final canStart = _assignmentsConfirmed && !_isStartingSeason;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canStart
              ? AppColors.goldAccent.withValues(alpha: 0.5)
              : AppTheme.borderColor,
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                canStart
                    ? 'Zespół gotowy do oficjalnego otwarcia sezonu!'
                    : 'Zatwierdź numery startowe i role, aby rozpocząć sezon',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Kliknięcie opublikuje komunikat prasowy w mediach i otworzy kalendarz styczniowych wyścigów.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(
            width: isMobile ? double.infinity : null,
            child: ElevatedButton.icon(
              onPressed: canStart
                  ? () => _startRacingSeason(careerState, leaders, flagshipBike)
                  : null,
              icon: _isStartingSeason
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.rocket_launch_rounded, size: 18),
              label: const Text(
                'ROZPOCZNIJ SEZON WYŚCIGOWY',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return AppColors.surfaceLight;
                  }
                  if (states.contains(WidgetState.pressed)) {
                    return AppColors.goldAccent.withValues(alpha: 0.8);
                  }
                  if (states.contains(WidgetState.hovered)) {
                    return const Color(0xFFE5C158);
                  }
                  return AppColors.goldAccent;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return AppColors.textSecondary.withValues(alpha: 0.5);
                  }
                  return Colors.black;
                }),
                side: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.focused)) {
                    return const BorderSide(color: Colors.white, width: 2.0);
                  }
                  return BorderSide.none;
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthShortName(int month) {
    const months = [
      'Sty',
      'Lut',
      'Mar',
      'Kwi',
      'Maj',
      'Cze',
      'Lip',
      'Sie',
      'Wrz',
      'Paź',
      'Lis',
      'Gru',
    ];
    return months[(month - 1).clamp(0, 11)];
  }
}

class _GalaLeaderStageCard extends StatefulWidget {
  final Rider rider;
  final CyclingTeam team;
  final int bibNumber;
  final SeasonLeaderRole role;
  final int rank;
  final double avatarSize;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _GalaLeaderStageCard({
    required this.rider,
    required this.team,
    required this.bibNumber,
    required this.role,
    required this.rank,
    required this.avatarSize,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_GalaLeaderStageCard> createState() => _GalaLeaderStageCardState();
}

class _GalaLeaderStageCardState extends State<_GalaLeaderStageCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final activeBorder = widget.isSelected
        ? AppColors.goldAccent
        : (_isHovered || _isFocused
            ? widget.accentColor
            : AppTheme.borderColor);

    return FocusableActionDetector(
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: widget.avatarSize + 36,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(
                alpha: widget.isSelected ? 0.9 : 0.72,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: activeBorder,
                width: widget.isSelected || _isFocused ? 2.0 : 1.0,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.goldAccent.withValues(alpha: 0.25),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    RiderAvatarWidget.fromRider(
                      rider: widget.rider,
                      team: widget.team,
                      size: widget.avatarSize,
                      showHelmet: false,
                      showGlasses: false,
                      borderColor: widget.isSelected
                          ? AppColors.goldAccent
                          : widget.accentColor,
                      borderWidth: 2.5,
                    ),
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${widget.bibNumber}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.rider.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.role.badgeColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.role.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: widget.role.badgeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepperIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _StepperIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.background.withValues(alpha: 0.4);
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.goldAccent.withValues(alpha: 0.28);
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.surface;
            }
            return AppColors.background;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textSecondary.withValues(alpha: 0.35);
            }
            return AppColors.textPrimary;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: AppColors.goldAccent, width: 1.5);
            }
            return const BorderSide(color: AppTheme.borderColor, width: 1.0);
          }),
        ),
      ),
    );
  }
}

/// Rysuje uroczyste reflektory sceniczne w barwach drużyny oraz refleks podłogi sceny.
class _GalaStageSpotlightPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final double animationValue;

  const _GalaStageSpotlightPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.background,
          Color.lerp(AppColors.background, primaryColor, 0.14)!,
          AppColors.surface,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final sway = math.sin(animationValue * math.pi) * size.width * 0.04;

    _drawBeam(
      canvas,
      size,
      origin: Offset(size.width * 0.16, -20),
      targetCenter: Offset(size.width * 0.25 + sway, size.height * 0.92),
      spreadWidth: size.width * 0.26,
      color: primaryColor.withValues(alpha: 0.24),
    );
    _drawBeam(
      canvas,
      size,
      origin: Offset(size.width * 0.50, -20),
      targetCenter: Offset(size.width * 0.50 - sway * 0.5, size.height * 0.92),
      spreadWidth: size.width * 0.30,
      color: accentColor.withValues(alpha: 0.18),
    );
    _drawBeam(
      canvas,
      size,
      origin: Offset(size.width * 0.84, -20),
      targetCenter: Offset(size.width * 0.76 - sway, size.height * 0.92),
      spreadWidth: size.width * 0.26,
      color: secondaryColor.withValues(alpha: 0.22),
    );

    // Linia krawędzi sceny
    final floorY = size.height * 0.90;
    final floorPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          accentColor.withValues(alpha: 0.55),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, floorY, size.width, 2))
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, floorY), Offset(size.width, floorY), floorPaint);
  }

  void _drawBeam(
    Canvas canvas,
    Size size, {
    required Offset origin,
    required Offset targetCenter,
    required double spreadWidth,
    required Color color,
  }) {
    final path = Path()
      ..moveTo(origin.dx - 12, origin.dy)
      ..lineTo(origin.dx + 12, origin.dy)
      ..lineTo(targetCenter.dx + spreadWidth * 0.5, targetCenter.dy)
      ..lineTo(targetCenter.dx - spreadWidth * 0.5, targetCenter.dy)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color,
          color.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GalaStageSpotlightPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}
