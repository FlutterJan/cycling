import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/paracycling/uci_paracycling_tandem_handbike_model.dart';

/// Zakładki widoku mobilnego ekranu Pucharu Świata UCI Para-Cycling.
enum ParacyclingScreenTab {
  calendarAndRace,
  squadAndTandem,
  relayAndStandings,
}

/// Wynik symulacji pojedynczego biegu UCI Para-Cycling z pełną klasyfikacją podium.
class ParacyclingSimulatedEventSummary {
  final ParacyclingRaceEvent event;
  final ParacyclingSportClass sportClass;
  final ParacyclingRaceResult playerResult;
  final List<ParacyclingRaceResult> leaderboard;

  const ParacyclingSimulatedEventSummary({
    required this.event,
    required this.sportClass,
    required this.playerResult,
    required this.leaderboard,
  });
}

/// Deterministyczny symulator wyścigów UCI Para-Cycling (Tandem B, Handbike H1–H5, C1–C5).
class ParacyclingRaceSimulator {
  const ParacyclingRaceSimulator._();

  static const List<({String name, String nat, double strength})> _rivals = [
    (name: 'L. Van Der Berg', nat: 'NED', strength: 1.035),
    (name: 'M. Fontaine', nat: 'FRA', strength: 1.015),
    (name: 'T. Bosworth', nat: 'GBR', strength: 0.992),
    (name: 'J. Morales', nat: 'ESP', strength: 0.974),
    (name: 'S. Richter', nat: 'GER', strength: 0.955),
    (name: 'A. Moretti', nat: 'ITA', strength: 0.938),
  ];

  /// Symuluje start wyścigu i zwraca pełną listę wyników wraz z miejscem gracza.
  static ParacyclingSimulatedEventSummary simulateEvent({
    required ParacyclingRaceEvent event,
    required ParacyclingSportClass sportClass,
    required String competitorId,
    required String displayName,
    required double effectiveFtpWatts,
    required double systemWeightKg,
    required double cdaM2,
    required double crr,
    double? maxDescentOverrideKmh,
    int seedOffset = 0,
  }) {
    final safeDistanceKm = math.max(5.0, event.distanceKm);
    final elevationPerKm = event.elevationGainM / safeDistanceKm;
    final profileDragFactor = switch (event.courseProfile) {
      ParacyclingCourseProfile.flat => 0.96,
      ParacyclingCourseProfile.rolling => 1.02,
      ParacyclingCourseProfile.technicalCircuit => 1.05,
      ParacyclingCourseProfile.hilly => 1.12,
    };

    // Efektywna moc skorygowana o masę, opory toczenia i CdA.
    final aeroResistance = math.max(0.16, cdaM2) * 1.225 * 0.5;
    final rollingResistance = math.max(45.0, systemWeightKg) * 9.81 * crr;
    final climbPowerPenalty =
        math.max(0.0, elevationPerKm) * systemWeightKg * 0.016;
    final availableFlatWatts = math.max(
      90.0,
      effectiveFtpWatts *
              (event.discipline == ParacyclingDiscipline.individualTimeTrial
                  ? 1.02
                  : 0.92) -
          climbPowerPenalty,
    );

    // Przybliżona prędkość równowagowa [m/s] z równania mocy P = F_aero * v^3 + F_roll * v.
    double speedMs = 10.5;
    for (int i = 0; i < 8; i++) {
      final fAero = aeroResistance * profileDragFactor;
      final powerAtV =
          fAero * speedMs * speedMs * speedMs + rollingResistance * speedMs;
      final derivative = 3 * fAero * speedMs * speedMs + rollingResistance;
      if (derivative > 0.01) {
        speedMs = (speedMs - (powerAtV - availableFlatWatts) / derivative)
            .clamp(5.5, 16.5);
      }
    }

    final uciFactor = sportClass.uciFactorPercentage / 100.0;
    final playerTimeSeconds =
        ((safeDistanceKm * 1000.0) / speedMs) / math.max(0.65, uciFactor);
    final playerMaxSpeedKmh = maxDescentOverrideKmh ??
        (speedMs * 3.6 * (1.28 + (elevationPerKm / 120.0).clamp(0.0, 0.35)))
            .clamp(38.0, 92.0);

    final rng = math.Random(
      event.id.hashCode ^
          competitorId.hashCode ^
          sportClass.index ^
          seedOffset,
    );

    final List<({String id, String name, double time, double watts, double maxKmh})>
        rawEntries = [
      (
        id: competitorId,
        name: displayName,
        time: playerTimeSeconds,
        watts: availableFlatWatts,
        maxKmh: playerMaxSpeedKmh,
      ),
    ];

    for (int i = 0; i < _rivals.length; i++) {
      final rival = _rivals[i];
      final jitter = 0.988 + rng.nextDouble() * 0.026;
      final rivalStrength = rival.strength * jitter;
      final rivalTime = playerTimeSeconds / rivalStrength;
      final rivalWatts = availableFlatWatts * rivalStrength;
      final rivalMaxSpeed =
          (playerMaxSpeedKmh * (0.96 + rng.nextDouble() * 0.06))
              .clamp(36.0, 108.0);
      rawEntries.add((
        id: 'rival_${event.id}_${sportClass.code}_$i',
        name: '${rival.name} (${rival.nat})',
        time: rivalTime,
        watts: rivalWatts,
        maxKmh: rivalMaxSpeed,
      ));
    }

    rawEntries.sort((a, b) => a.time.compareTo(b.time));

    final List<ParacyclingRaceResult> leaderboard = [];
    late ParacyclingRaceResult playerResult;

    for (int i = 0; i < rawEntries.length; i++) {
      final rank = i + 1;
      final entry = rawEntries[i];
      final medal = switch (rank) {
        1 => ParacyclingMedalType.gold,
        2 => ParacyclingMedalType.silver,
        3 => ParacyclingMedalType.bronze,
        _ => ParacyclingMedalType.none,
      };
      final rankRatio = switch (rank) {
        1 => 1.0,
        2 => 0.80,
        3 => 0.65,
        4 => 0.50,
        5 => 0.38,
        6 => 0.28,
        _ => 0.18,
      };
      final points = (event.winnerUciPoints * rankRatio).round();
      final result = ParacyclingRaceResult(
        eventId: event.id,
        competitorId: entry.id,
        displayName: entry.name,
        sportClass: sportClass,
        finishTimeSeconds: entry.time,
        rank: rank,
        uciPointsEarned: points,
        averagePowerWatts: entry.watts,
        maxSpeedKmh: entry.maxKmh,
        medalEarned: medal,
      );
      leaderboard.add(result);
      if (entry.id == competitorId) {
        playerResult = result;
      }
    }

    return ParacyclingSimulatedEventSummary(
      event: event,
      sportClass: sportClass,
      playerResult: playerResult,
      leaderboard: leaderboard,
    );
  }
}

/// Ekran Pucharu Świata UCI Para-Cycling i Igrzysk Paralimpijskich.
class UciParacyclingWorldCupScreen extends StatefulWidget {
  final UciParacyclingTandemHandbikeModel? initialModel;
  final VoidCallback? onBack;

  const UciParacyclingWorldCupScreen({
    super.key,
    this.initialModel,
    this.onBack,
  });

  @override
  State<UciParacyclingWorldCupScreen> createState() =>
      _UciParacyclingWorldCupScreenState();
}

class _UciParacyclingWorldCupScreenState
    extends State<UciParacyclingWorldCupScreen> {
  late UciParacyclingTandemHandbikeModel _model;
  ParacyclingDivision? _selectedDivision;
  ParacyclingSportClass _selectedClass = ParacyclingSportClass.b;
  late String _selectedEventId;
  String? _selectedCompetitorId;
  String? _selectedBikeId;
  ParacyclingScreenTab _mobileTab = ParacyclingScreenTab.calendarAndRace;
  ParacyclingSimulatedEventSummary? _lastSimulation;
  int _simulationCounter = 0;

  // Stan konfiguratora Tandem B
  String? _draftPilotId;
  String? _draftStokerId;
  String? _draftTandemBikeId;
  double _draftSyncIndex = 0.96;

  // Stan kreatora sztafety Handbike H1–H5
  List<String> _draftRelayRiderIds = [];

  @override
  void initState() {
    super.initState();
    _model = widget.initialModel ??
        UciParacyclingTandemHandbikeModel.createDefaultWorldCupSeason();
    _selectedEventId = _model.events.isNotEmpty ? _model.events.first.id : '';
    _initializeDraftSelections();
    _syncRaceCompetitorAndBike();
  }

  void _initializeDraftSelections() {
    final pilots = _model.availablePilots;
    final stokers = _model.athletesInClass(ParacyclingSportClass.b);
    final tandemBikes = _model.compatibleBikesForClass(ParacyclingSportClass.b);
    if (pilots.isNotEmpty) _draftPilotId = pilots.first.id;
    if (stokers.isNotEmpty) _draftStokerId = stokers.first.id;
    if (tandemBikes.isNotEmpty) _draftTandemBikeId = tandemBikes.first.id;
    if (_model.tandemCrews.isNotEmpty) {
      _draftSyncIndex = _model.tandemCrews.first.synchronizationIndex;
    }

    if (_model.relayEntries.isNotEmpty) {
      _draftRelayRiderIds =
          _model.relayEntries.first.riders.map((r) => r.id).toList();
    } else {
      _draftRelayRiderIds = _model.athletes
          .where(
            (a) =>
                !a.isPilot &&
                a.sportClass.division == ParacyclingDivision.handbike,
          )
          .take(3)
          .map((a) => a.id)
          .toList();
    }
  }

  ParacyclingRaceEvent? get _activeEvent {
    if (_model.events.isEmpty) return null;
    return _model.events.firstWhere(
      (e) => e.id == _selectedEventId,
      orElse: () => _model.events.first,
    );
  }

  void _syncRaceCompetitorAndBike() {
    final event = _activeEvent;
    if (event == null) return;

    if (!event.eligibleClasses.contains(_selectedClass) &&
        event.eligibleClasses.isNotEmpty) {
      _selectedClass = event.eligibleClasses.first;
    }

    if (event.discipline == ParacyclingDiscipline.teamRelay) {
      _selectedCompetitorId =
          _model.relayEntries.isNotEmpty ? _model.relayEntries.first.id : null;
      _selectedBikeId = null;
      return;
    }

    if (_selectedClass == ParacyclingSportClass.b) {
      _selectedCompetitorId =
          _model.tandemCrews.isNotEmpty ? _model.tandemCrews.first.id : null;
    } else {
      final classAthletes = _model.athletesInClass(_selectedClass);
      if (classAthletes.isNotEmpty) {
        if (!classAthletes.any((a) => a.id == _selectedCompetitorId)) {
          _selectedCompetitorId = classAthletes.first.id;
        }
      } else {
        _selectedCompetitorId = null;
      }
    }

    final bikes = _model.compatibleBikesForClass(_selectedClass);
    if (bikes.isNotEmpty) {
      if (!bikes.any((b) => b.id == _selectedBikeId)) {
        _selectedBikeId = bikes.first.id;
      }
    } else {
      _selectedBikeId = null;
    }
  }

  void _selectDivision(ParacyclingDivision? division) {
    setState(() {
      _selectedDivision = division;
      if (division != null && _selectedClass.division != division) {
        _selectedClass = ParacyclingSportClass.values.firstWhere(
          (c) => c.division == division,
        );
      }
      _syncRaceCompetitorAndBike();
    });
  }

  void _selectSportClass(ParacyclingSportClass sportClass) {
    setState(() {
      _selectedClass = sportClass;
      _selectedDivision = sportClass.division;
      _syncRaceCompetitorAndBike();
    });
  }

  void _selectEvent(ParacyclingRaceEvent event) {
    setState(() {
      _selectedEventId = event.id;
      _syncRaceCompetitorAndBike();
    });
  }

  bool get _canSimulateActiveRace {
    final event = _activeEvent;
    if (event == null) return false;
    if (event.discipline == ParacyclingDiscipline.teamRelay) {
      final relay = _model.relayEntries
          .where((r) => r.id == _selectedCompetitorId)
          .firstOrNull;
      return relay != null && relay.isRulesCompliant;
    }
    if (_selectedClass == ParacyclingSportClass.b) {
      final crew = _model.tandemCrews
          .where((c) => c.id == _selectedCompetitorId)
          .firstOrNull;
      final bike =
          _model.bikes.where((b) => b.id == _selectedBikeId).firstOrNull;
      return crew != null &&
          crew.isUciValid &&
          bike != null &&
          bike.isCompatibleWithClass(_selectedClass);
    }
    final athlete = _model.athletes
        .where((a) => a.id == _selectedCompetitorId)
        .firstOrNull;
    final bike =
        _model.bikes.where((b) => b.id == _selectedBikeId).firstOrNull;
    return athlete != null &&
        bike != null &&
        bike.isCompatibleWithClass(_selectedClass);
  }

  void _runRaceSimulation() {
    final event = _activeEvent;
    if (event == null || !_canSimulateActiveRace) return;

    _simulationCounter++;
    late ParacyclingSimulatedEventSummary summary;

    if (event.discipline == ParacyclingDiscipline.teamRelay) {
      final relay = _model.relayEntries
          .firstWhere((r) => r.id == _selectedCompetitorId);
      final avgWeight = relay.riders.fold<double>(
            0.0,
            (s, r) => s + r.weightKg,
          ) /
          math.max(1, relay.riders.length);
      summary = ParacyclingRaceSimulator.simulateEvent(
        event: event,
        sportClass: ParacyclingSportClass.h3,
        competitorId: relay.id,
        displayName: relay.teamName,
        effectiveFtpWatts: relay.combinedRelayFtpWatts / 2.65,
        systemWeightKg: avgWeight + 10.8,
        cdaM2: 0.205,
        crr: 0.0034,
        seedOffset: _simulationCounter,
      );
    } else if (_selectedClass == ParacyclingSportClass.b) {
      final crew = _model.tandemCrews
          .firstWhere((c) => c.id == _selectedCompetitorId);
      final bike = _model.bikes.firstWhere((b) => b.id == _selectedBikeId);
      final crewWithBike = crew.copyWith(tandemBike: bike);
      summary = ParacyclingRaceSimulator.simulateEvent(
        event: event,
        sportClass: ParacyclingSportClass.b,
        competitorId: crew.id,
        displayName: '${crew.crewDisplayName} (POL)',
        effectiveFtpWatts: crewWithBike.combinedFtpWatts,
        systemWeightKg: crewWithBike.totalSystemWeightKg,
        cdaM2: bike.cdaM2,
        crr: bike.crr,
        maxDescentOverrideKmh: crewWithBike.projectedMaxDescentKmh,
        seedOffset: _simulationCounter,
      );
    } else {
      final athlete = _model.athletes
          .firstWhere((a) => a.id == _selectedCompetitorId);
      final bike = _model.bikes.firstWhere((b) => b.id == _selectedBikeId);
      summary = ParacyclingRaceSimulator.simulateEvent(
        event: event,
        sportClass: athlete.sportClass,
        competitorId: athlete.id,
        displayName: '${athlete.name} (${athlete.nationalityCode})',
        effectiveFtpWatts: athlete.ftpWatts,
        systemWeightKg: athlete.weightKg + bike.weightKg,
        cdaM2: bike.cdaM2,
        crr: bike.crr,
        seedOffset: _simulationCounter,
      );
    }

    setState(() {
      _lastSimulation = summary;
      _model = _model.recordResult(summary.playerResult);
    });
  }

  void _saveTandemCrewUpdate() {
    final pilot = _model.availablePilots
        .where((p) => p.id == _draftPilotId)
        .firstOrNull;
    final stoker = _model.athletesInClass(ParacyclingSportClass.b)
        .where((s) => s.id == _draftStokerId)
        .firstOrNull;
    final bike = _model
        .compatibleBikesForClass(ParacyclingSportClass.b)
        .where((b) => b.id == _draftTandemBikeId)
        .firstOrNull;

    if (pilot == null || stoker == null || bike == null) return;

    final updatedCrew = TandemCrewPairing(
      id: _model.tandemCrews.isNotEmpty
          ? _model.tandemCrews.first.id
          : 'crew_pol_b_custom',
      pilot: pilot,
      stoker: stoker,
      synchronizationIndex: _draftSyncIndex,
      communicationChemistry: 94,
      tandemBike: bike,
    );

    setState(() {
      final rest = _model.tandemCrews.length > 1
          ? _model.tandemCrews.sublist(1)
          : <TandemCrewPairing>[];
      _model = _model.copyWith(tandemCrews: [updatedCrew, ...rest]);
      _syncRaceCompetitorAndBike();
    });
  }

  void _toggleRelayRider(String riderId) {
    setState(() {
      final updated = List<String>.from(_draftRelayRiderIds);
      if (updated.contains(riderId)) {
        updated.remove(riderId);
      } else if (updated.length < 3) {
        updated.add(riderId);
      }
      _draftRelayRiderIds = updated;
    });
  }

  void _saveRelayEntry() {
    final selectedRiders = _model.athletes
        .where((a) => _draftRelayRiderIds.contains(a.id))
        .toList();
    if (selectedRiders.length != 3) return;

    final updatedRelay = HandbikeTeamRelayEntry(
      id: _model.relayEntries.isNotEmpty
          ? _model.relayEntries.first.id
          : 'relay_pol_h_custom',
      teamName:
          'Polska Sztafeta ${selectedRiders.map((r) => r.sportClass.code).join('–')}',
      nationalityCode: 'POL',
      riders: selectedRiders,
      maxClassificationPoints: 11,
    );

    if (!updatedRelay.isRulesCompliant) return;

    setState(() {
      final rest = _model.relayEntries.length > 1
          ? _model.relayEntries.sublist(1)
          : <HandbikeTeamRelayEntry>[];
      _model = _model.copyWith(relayEntries: [updatedRelay, ...rest]);
      _syncRaceCompetitorAndBike();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(
          fontFamily: 'Inter',
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isDesktop = width >= 1200;
              final isTablet = width >= 720 && width < 1200;

              return Column(
                children: [
                  _buildHeader(context, isCompact: !isDesktop && !isTablet),
                  _buildDivisionAndClassBar(isCompact: !isDesktop && !isTablet),
                  if (!isDesktop && !isTablet) _buildMobileTabBar(),
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isCompact}) {
    final goldCount = _model.results
        .where((r) => r.medalEarned == ParacyclingMedalType.gold)
        .length;
    final silverCount = _model.results
        .where((r) => r.medalEarned == ParacyclingMedalType.silver)
        .length;
    final bronzeCount = _model.results
        .where((r) => r.medalEarned == ParacyclingMedalType.bronze)
        .length;
    final totalUciPoints = _model.results.fold<int>(
      0,
      (sum, r) => sum + r.uciPointsEarned,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: isCompact ? 10 : 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (widget.onBack != null || Navigator.of(context).canPop())
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _InteractiveActionButton(
                label: isCompact ? '' : 'Wróć',
                icon: Icons.arrow_back_rounded,
                isSecondary: true,
                compact: isCompact,
                onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
              ),
            ),
          Container(
            width: isCompact ? 36 : 42,
            height: isCompact ? 36 : 42,
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.5),
              ),
            ),
            child: const Icon(
              Icons.accessible_forward_rounded,
              color: AppColors.goldAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UCI Para-Cycling & Igrzyska Paralimpijskie',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 15 : 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_model.teamName} • Sezon ${_model.seasonYear}',
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
          if (!isCompact) ...[
            _MedalStatPill(
              label: 'Złoto',
              value: goldCount,
              color: AppColors.goldAccent,
            ),
            const SizedBox(width: 8),
            _MedalStatPill(
              label: 'Srebro',
              value: silverCount,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: 8),
            _MedalStatPill(
              label: 'Brąz',
              value: bronzeCount,
              color: AppColors.amberWarning,
            ),
            const SizedBox(width: 10),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 16,
                  color: AppColors.cyanAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  '$totalUciPoints pkt UCI',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivisionAndClassBar({required bool isCompact}) {
    final visibleClasses = _selectedDivision == null
        ? ParacyclingSportClass.values
        : ParacyclingSportClass.values
            .where((c) => c.division == _selectedDivision)
            .toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _InteractiveFilterChip(
                  label: 'Wszystkie Dywizje',
                  selected: _selectedDivision == null,
                  accentColor: AppColors.cyanAccent,
                  onTap: () => _selectDivision(null),
                ),
                const SizedBox(width: 8),
                ...ParacyclingDivision.values.map(
                  (div) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _InteractiveFilterChip(
                      label: div.displayNamePl,
                      selected: _selectedDivision == div,
                      accentColor: AppColors.goldAccent,
                      onTap: () => _selectDivision(div),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: visibleClasses.map((sportClass) {
                final readiness = _model.evaluateClassReadiness(sportClass);
                final isSelected = _selectedClass == sportClass;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _InteractiveFilterChip(
                    label:
                        '${sportClass.code} (${sportClass.uciFactorPercentage.toStringAsFixed(0)}%)',
                    selected: isSelected,
                    accentColor: readiness.isReadyForCompetition
                        ? AppColors.statusSuccess
                        : AppColors.amberWarning,
                    leadingDotColor: readiness.isReadyForCompetition
                        ? AppColors.statusSuccess
                        : AppColors.amberWarning,
                    onTap: () => _selectSportClass(sportClass),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _InteractiveTabButton(
              label: 'Kalendarz & Start',
              selected: _mobileTab == ParacyclingScreenTab.calendarAndRace,
              onTap: () => setState(
                () => _mobileTab = ParacyclingScreenTab.calendarAndRace,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _InteractiveTabButton(
              label: 'Kadra & Tandem B',
              selected: _mobileTab == ParacyclingScreenTab.squadAndTandem,
              onTap: () => setState(
                () => _mobileTab = ParacyclingScreenTab.squadAndTandem,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _InteractiveTabButton(
              label: 'Sztafeta & Wyniki',
              selected: _mobileTab == ParacyclingScreenTab.relayAndStandings,
              onTap: () => setState(
                () => _mobileTab = ParacyclingScreenTab.relayAndStandings,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCalendarSection(),
                  const SizedBox(height: 14),
                  _buildClassReadinessCard(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildRaceSimulatorCard(),
                  if (_lastSimulation != null) ...[
                    const SizedBox(height: 14),
                    _buildLastSimulationResultCard(_lastSimulation!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTandemCrewLabCard(),
                  const SizedBox(height: 14),
                  _buildHandbikeRelayBuilderCard(),
                  const SizedBox(height: 14),
                  _buildWorldCupStandingsCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCalendarSection(),
                  const SizedBox(height: 14),
                  _buildClassReadinessCard(),
                  const SizedBox(height: 14),
                  _buildTandemCrewLabCard(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildRaceSimulatorCard(),
                  if (_lastSimulation != null) ...[
                    const SizedBox(height: 14),
                    _buildLastSimulationResultCard(_lastSimulation!),
                  ],
                  const SizedBox(height: 14),
                  _buildHandbikeRelayBuilderCard(),
                  const SizedBox(height: 14),
                  _buildWorldCupStandingsCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: switch (_mobileTab) {
        ParacyclingScreenTab.calendarAndRace => Column(
            children: [
              _buildCalendarSection(),
              const SizedBox(height: 12),
              _buildRaceSimulatorCard(),
              if (_lastSimulation != null) ...[
                const SizedBox(height: 12),
                _buildLastSimulationResultCard(_lastSimulation!),
              ],
            ],
          ),
        ParacyclingScreenTab.squadAndTandem => Column(
            children: [
              _buildClassReadinessCard(),
              const SizedBox(height: 12),
              _buildTandemCrewLabCard(),
            ],
          ),
        ParacyclingScreenTab.relayAndStandings => Column(
            children: [
              _buildHandbikeRelayBuilderCard(),
              const SizedBox(height: 12),
              _buildWorldCupStandingsCard(),
            ],
          ),
      },
    );
  }

  Widget _buildCalendarSection() {
    return _PanelCard(
      title: 'Kalendarz Pucharu Świata & Igrzysk',
      icon: Icons.calendar_month_rounded,
      accentColor: AppColors.goldAccent,
      child: Column(
        children: _model.events.map((event) {
          final isSelected = event.id == _activeEvent?.id;
          final isParalympics =
              event.tier == ParacyclingEventTier.paralympicGames;
          final badgeColor =
              isParalympics ? AppColors.goldAccent : AppColors.accentBlue;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _InteractiveEventCard(
              selected: isSelected,
              accentColor: badgeColor,
              onTap: () => _selectEvent(event),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: badgeColor.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Text(
                            isParalympics
                                ? 'IGRZYSKA PARALIMPIJSKIE'
                                : 'PUCHAR ŚWIATA UCI',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        event.startDateIso,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${event.location} (${event.countryCode}) • ${event.discipline.displayNamePl}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _MiniMetricChip(
                        label: '${event.distanceKm.toStringAsFixed(1)} km',
                      ),
                      _MiniMetricChip(label: '+${event.elevationGainM} m'),
                      _MiniMetricChip(label: '${event.laps} rund'),
                      _MiniMetricChip(
                        label: '${event.winnerUciPoints} pkt UCI',
                        highlightColor: AppColors.cyanAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClassReadinessCard() {
    final readiness = _model.evaluateClassReadiness(_selectedClass);
    final statusColor = readiness.isReadyForCompetition
        ? AppColors.statusSuccess
        : AppColors.amberWarning;

    return _PanelCard(
      title: 'Klasa ${_selectedClass.code} — Profil UCI',
      icon: Icons.verified_user_outlined,
      accentColor: statusColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedClass.displayNamePl,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedClass.uciDescriptionPl,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TelemetryMetricBox(
                label: 'Współczynnik UCI',
                value:
                    '${_selectedClass.uciFactorPercentage.toStringAsFixed(1)}%',
                color: AppColors.cyanAccent,
              ),
              _TelemetryMetricBox(
                label: 'Bazowe CdA',
                value: '${_selectedClass.referenceCdaM2.toStringAsFixed(3)} m²',
                color: AppColors.accentBlue,
              ),
              _TelemetryMetricBox(
                label: 'Liczba kół',
                value: '${_selectedClass.wheelCount} koła',
                color: AppColors.goldAccent,
              ),
              _TelemetryMetricBox(
                label: 'Śr. FTP klasy',
                value: '${readiness.averageFtpWatts.round()} W',
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              readiness.summaryPl,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceSimulatorCard() {
    final event = _activeEvent;
    if (event == null) {
      return const _PanelCard(
        title: 'Centrum Startowe',
        icon: Icons.flag_rounded,
        accentColor: AppColors.primaryAccent,
        child: Text(
          'Brak wydarzeń w kalendarzu UCI Para-Cycling.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final isRelay = event.discipline == ParacyclingDiscipline.teamRelay;
    final bikes = _model.compatibleBikesForClass(_selectedClass);

    return _PanelCard(
      title: 'Centrum Startowe: ${event.location}',
      icon: Icons.flag_rounded,
      accentColor: event.tier == ParacyclingEventTier.paralympicGames
          ? AppColors.goldAccent
          : AppColors.primaryAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.courseProfile.displayNamePl} • ${event.distanceKm.toStringAsFixed(1)} km • +${event.elevationGainM} m • Pula: €${event.prizePoolEur.round()}',
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
            ],
          ),
          const SizedBox(height: 14),
          if (isRelay) ...[
            const Text(
              'Zgłoszona Sztafeta Handbike (H1–H5, limit 11 pkt UCI)',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ..._model.relayEntries.map((relay) {
              final selected = relay.id == _selectedCompetitorId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InteractiveSelectionTile(
                  selected: selected,
                  title: relay.teamName,
                  subtitle:
                      'Punkty: ${relay.totalClassificationPoints}/${relay.maxClassificationPoints} • Łączne FTP: ${relay.combinedRelayFtpWatts.round()} W',
                  statusColor: relay.isRulesCompliant
                      ? AppColors.statusSuccess
                      : AppColors.crimsonAlert,
                  onTap: () =>
                      setState(() => _selectedCompetitorId = relay.id),
                ),
              );
            }),
          ] else if (_selectedClass == ParacyclingSportClass.b) ...[
            const Text(
              'Załoga Tandemu Klasy B (Pilot + Stoker)',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (_model.tandemCrews.isEmpty)
              const Text(
                'Brak skonfigurowanych załóg Tandem B.',
                style: TextStyle(color: AppColors.amberWarning, fontSize: 12),
              )
            else
              ..._model.tandemCrews.map((crew) {
                final selected = crew.id == _selectedCompetitorId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _InteractiveSelectionTile(
                    selected: selected,
                    title: crew.crewDisplayName,
                    subtitle:
                        'FTP: ${crew.combinedFtpWatts.round()} W (${crew.effectiveWPerKg.toStringAsFixed(2)} W/kg) • Zjazd max: ${crew.projectedMaxDescentKmh.toStringAsFixed(1)} km/h',
                    statusColor: crew.isUciValid
                        ? AppColors.statusSuccess
                        : AppColors.crimsonAlert,
                    onTap: () =>
                        setState(() => _selectedCompetitorId = crew.id),
                  ),
                );
              }),
          ] else ...[
            Text(
              'Reprezentant w klasie ${_selectedClass.code}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (_model.athletesInClass(_selectedClass).isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.amberWarning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.amberWarning.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Brak zawodnika w kadrze dla klasy ${_selectedClass.code}. Wybierz inną klasę z paska powyżej.',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.amberWarning,
                  ),
                ),
              )
            else
              ..._model.athletesInClass(_selectedClass).map((athlete) {
                final selected = athlete.id == _selectedCompetitorId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _InteractiveSelectionTile(
                    selected: selected,
                    title: '${athlete.name} (${athlete.nationalityCode})',
                    subtitle:
                        'FTP: ${athlete.ftpWatts.round()} W • ${athlete.wPerKg.toStringAsFixed(2)} W/kg • VO2max: ${athlete.vo2Max.toStringAsFixed(1)}',
                    statusColor: AppColors.cyanAccent,
                    onTap: () =>
                        setState(() => _selectedCompetitorId = athlete.id),
                  ),
                );
              }),
          ],
          if (!isRelay && bikes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Sprzęt UCI dopuszczony dla klasy ${_selectedClass.code}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...bikes.map((bike) {
              final selected = bike.id == _selectedBikeId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InteractiveSelectionTile(
                  selected: selected,
                  title: bike.name,
                  subtitle:
                      '${bike.weightKg.toStringAsFixed(1)} kg • CdA ${bike.cdaM2.toStringAsFixed(3)} m² • ${bike.wheelCount} koła',
                  statusColor: AppColors.accentBlue,
                  onTap: () => setState(() => _selectedBikeId = bike.id),
                ),
              );
            }),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InteractiveActionButton(
                  label: 'Symuluj Start UCI (${event.tier == ParacyclingEventTier.paralympicGames ? 'Igrzyska' : 'Puchar Świata'})',
                  icon: Icons.play_arrow_rounded,
                  enabled: _canSimulateActiveRace,
                  onPressed: _runRaceSimulation,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLastSimulationResultCard(
    ParacyclingSimulatedEventSummary summary,
  ) {
    final res = summary.playerResult;
    final medalColor = switch (res.medalEarned) {
      ParacyclingMedalType.gold => AppColors.goldAccent,
      ParacyclingMedalType.silver => AppColors.textPrimary,
      ParacyclingMedalType.bronze => AppColors.amberWarning,
      ParacyclingMedalType.none => AppColors.accentBlue,
    };

    return _PanelCard(
      title: 'Wynik Biegu: ${summary.event.location} (${summary.sportClass.code})',
      icon: Icons.workspace_premium_rounded,
      accentColor: medalColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: medalColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: medalColor.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: medalColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Miejsce #${res.rank} — ${res.displayName}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: medalColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Czas: ${_formatRaceTime(res.finishTimeSeconds)} • +${res.uciPointsEarned} pkt UCI • Śr. ${res.averagePowerWatts.round()} W • Vmax ${res.maxSpeedKmh.toStringAsFixed(1)} km/h',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...summary.leaderboard.take(5).map((entry) {
            final isPlayer = entry.competitorId == res.competitorId;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isPlayer
                    ? AppColors.primaryAccent.withValues(alpha: 0.18)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isPlayer
                      ? AppColors.primaryAccent
                      : AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '#${entry.rank}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: entry.rank == 1
                            ? AppColors.goldAccent
                            : AppColors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    _formatRaceTime(entry.finishTimeSeconds),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '+${entry.uciPointsEarned} pkt',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cyanAccent,
                      fontFeatures: [FontFeature.tabularFigures()],
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

  Widget _buildTandemCrewLabCard() {
    final pilots = _model.availablePilots;
    final stokers = _model.athletesInClass(ParacyclingSportClass.b);
    final tandemBikes = _model.compatibleBikesForClass(ParacyclingSportClass.b);

    final pilot = pilots.where((p) => p.id == _draftPilotId).firstOrNull;
    final stoker = stokers.where((s) => s.id == _draftStokerId).firstOrNull;
    final bike =
        tandemBikes.where((b) => b.id == _draftTandemBikeId).firstOrNull;

    final previewCrew = (pilot != null && stoker != null && bike != null)
        ? TandemCrewPairing(
            id: 'preview_crew',
            pilot: pilot,
            stoker: stoker,
            synchronizationIndex: _draftSyncIndex,
            communicationChemistry: 94,
            tandemBike: bike,
          )
        : null;

    return _PanelCard(
      title: 'Laboratorium Tandemu Klasy B',
      icon: Icons.directions_bike_rounded,
      accentColor: AppColors.cyanAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (previewCrew == null)
            const Text(
              'Brak dostępnych pilotów, stokerów lub tandemów w kadrze.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            )
          else ...[
            Text(
              'Duet: ${previewCrew.crewDisplayName}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TelemetryMetricBox(
                  label: 'Łączne FTP',
                  value: '${previewCrew.combinedFtpWatts.round()} W',
                  color: AppColors.goldAccent,
                ),
                _TelemetryMetricBox(
                  label: 'Moc / Masa',
                  value: '${previewCrew.effectiveWPerKg.toStringAsFixed(2)} W/kg',
                  color: AppColors.cyanAccent,
                ),
                _TelemetryMetricBox(
                  label: 'Zjazd Vmax',
                  value:
                      '${previewCrew.projectedMaxDescentKmh.toStringAsFixed(1)} km/h',
                  color: AppColors.statusSuccess,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Synchronizacja pedałowania',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(_draftSyncIndex * 100).round()}%',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cyanAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            Slider(
              value: _draftSyncIndex,
              min: 0.80,
              max: 1.00,
              divisions: 20,
              activeColor: AppColors.cyanAccent,
              inactiveColor: AppColors.cardBorder,
              onChanged: (v) => setState(() => _draftSyncIndex = v),
            ),
            _InteractiveActionButton(
              label: 'Zapisz Konfigurację Tandemu B',
              icon: Icons.save_rounded,
              isSecondary: true,
              onPressed: _saveTandemCrewUpdate,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHandbikeRelayBuilderCard() {
    final handbikeAthletes = _model.athletes
        .where(
          (a) =>
              !a.isPilot &&
              a.sportClass.division == ParacyclingDivision.handbike,
        )
        .toList();
    final selectedRiders = handbikeAthletes
        .where((a) => _draftRelayRiderIds.contains(a.id))
        .toList();
    final totalPoints = selectedRiders.fold<int>(
      0,
      (sum, r) => sum + r.sportClass.relayClassificationPoints,
    );
    final isCompliant =
        selectedRiders.length == 3 && totalPoints <= 11 && totalPoints > 0;
    final statusColor =
        isCompliant ? AppColors.statusSuccess : AppColors.crimsonAlert;

    return _PanelCard(
      title: 'Sztafeta Handbike H1–H5 (Limit 11 pkt)',
      icon: Icons.groups_rounded,
      accentColor: statusColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Wybrano ${selectedRiders.length}/3 zawodników',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'Suma: $totalPoints / 11 pkt',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...handbikeAthletes.map((athlete) {
            final isSelected = _draftRelayRiderIds.contains(athlete.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _InteractiveSelectionTile(
                selected: isSelected,
                title: '${athlete.name} (${athlete.sportClass.code})',
                subtitle:
                    '${athlete.sportClass.relayClassificationPoints} pkt klas. • FTP ${athlete.ftpWatts.round()} W',
                statusColor: AppColors.goldAccent,
                onTap: () => _toggleRelayRider(athlete.id),
              ),
            );
          }),
          const SizedBox(height: 8),
          _InteractiveActionButton(
            label: 'Zatwierdź Skład Sztafety',
            icon: Icons.check_circle_outline_rounded,
            enabled: isCompliant,
            isSecondary: true,
            onPressed: _saveRelayEntry,
          ),
        ],
      ),
    );
  }

  Widget _buildWorldCupStandingsCard() {
    final standings = _model.computeWorldCupStandings();

    return _PanelCard(
      title: 'Klasyfikacja Generalna Pucharu Świata',
      icon: Icons.leaderboard_rounded,
      accentColor: AppColors.goldAccent,
      child: standings.isEmpty
          ? const Text(
              'Rozegraj pierwszy wyścig Pucharu Świata lub Igrzysk, aby wyliczyć klasyfikację punktową UCI.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          : Column(
              children: standings.take(6).toList().asMap().entries.map((item) {
                final rank = item.key + 1;
                final entry = item.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$rank.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: rank == 1
                                ? AppColors.goldAccent
                                : AppColors.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entry.sportClass.code,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.totalPoints} pkt',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldAccent,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  String _formatRaceTime(double totalSeconds) {
    final rounded = totalSeconds.round();
    final hours = rounded ~/ 3600;
    final minutes = (rounded % 3600) ~/ 60;
    final seconds = rounded % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$mm:$ss';
    }
    return '$mm:$ss';
  }
}

class _PanelCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  const _PanelCard({
    required this.title,
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
        border: Border.all(color: AppColors.cardBorder, width: 1),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MedalStatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MedalStatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetricChip extends StatelessWidget {
  final String label;
  final Color? highlightColor;

  const _MiniMetricChip({required this.label, this.highlightColor});

  @override
  Widget build(BuildContext context) {
    final color = highlightColor ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _TelemetryMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TelemetryMetricBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final Color? leadingDotColor;
  final VoidCallback onTap;

  const _InteractiveFilterChip({
    required this.label,
    required this.selected,
    required this.accentColor,
    this.leadingDotColor,
    required this.onTap,
  });

  @override
  State<_InteractiveFilterChip> createState() => _InteractiveFilterChipState();
}

class _InteractiveFilterChipState extends State<_InteractiveFilterChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? widget.accentColor.withValues(alpha: _pressed ? 0.28 : 0.20)
        : (_hovered ? AppColors.surfaceLight : AppColors.surface);
    final borderColor = _focused
        ? AppColors.cyanAccent
        : (widget.selected ? widget.accentColor : AppColors.cardBorder);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leadingDotColor != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: widget.leadingDotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight:
                      widget.selected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveTabButton extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _InteractiveTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_InteractiveTabButton> createState() => _InteractiveTabButtonState();
}

class _InteractiveTabButtonState extends State<_InteractiveTabButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.primaryAccent.withValues(alpha: 0.25)
                : (_hovered ? AppColors.surfaceLight : AppColors.background),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.cyanAccent
                  : (widget.selected
                      ? AppColors.primaryAccent
                      : AppColors.cardBorder),
            ),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.selected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveEventCard extends StatefulWidget {
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;
  final Widget child;

  const _InteractiveEventCard({
    required this.selected,
    required this.accentColor,
    required this.onTap,
    required this.child,
  });

  @override
  State<_InteractiveEventCard> createState() => _InteractiveEventCardState();
}

class _InteractiveEventCardState extends State<_InteractiveEventCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.accentColor.withValues(alpha: _pressed ? 0.16 : 0.10)
                : (_hovered ? AppColors.surfaceLight : AppColors.background),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.cyanAccent
                  : (widget.selected
                      ? widget.accentColor
                      : AppColors.cardBorder),
              width: widget.selected || _focused ? 1.5 : 1.0,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _InteractiveSelectionTile extends StatefulWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final Color statusColor;
  final VoidCallback onTap;

  const _InteractiveSelectionTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.statusColor,
    required this.onTap,
  });

  @override
  State<_InteractiveSelectionTile> createState() =>
      _InteractiveSelectionTileState();
}

class _InteractiveSelectionTileState extends State<_InteractiveSelectionTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.statusColor.withValues(alpha: 0.14)
                : (_hovered ? AppColors.surfaceLight : AppColors.background),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.cyanAccent
                  : (widget.selected
                      ? widget.statusColor
                      : AppColors.cardBorder),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: widget.selected
                    ? widget.statusColor
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;
  final bool isSecondary;
  final bool compact;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.isSecondary = false,
    this.compact = false,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.isSecondary ? AppColors.surfaceLight : AppColors.primaryAccent;
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : (_pressed
            ? baseColor.withValues(alpha: 0.78)
            : (_hovered ? baseColor.withValues(alpha: 0.92) : baseColor));
    final borderColor = _focused
        ? AppColors.cyanAccent
        : (widget.enabled ? AppColors.cardBorder : AppColors.cardBorder);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              if (widget.label.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: widget.enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
