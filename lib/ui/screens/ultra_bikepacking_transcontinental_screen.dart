import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/physics/ultra_sleep_deprivation_and_circadian_solver.dart';
import '../../models/race/ultra_endurance_bikepacking_race_model.dart';

/// Rozszerzenie UI z polskimi etykietami dla [UltraSleepStrategy].
extension UltraSleepStrategyUiX on UltraSleepStrategy {
  String get displayNamePl {
    switch (this) {
      case UltraSleepStrategy.microNap20Min:
        return 'Mikrodrzemka (20 min)';
      case UltraSleepStrategy.powerSleep90Min:
        return 'Cykl snu (90 min)';
      case UltraSleepStrategy.bivy4Hours:
        return 'Biwak Bivy (4 h)';
      case UltraSleepStrategy.hotel5Hours:
        return 'Hotel (5 h snu + ładowanie)';
      case UltraSleepStrategy.pushThroughNight:
        return 'Jedź dalej przez noc';
    }
  }
}

/// Filtr widoku kropek na mapie GPS `Dotwatching Live Tracker`.
enum DotwatchingMapFilter {
  allRiders('Wszyscy', 'All'),
  topLeaders('Czołówka', 'Leaders'),
  restingOnly('Postój / Sen', 'Resting'),
  playerFocus('Mój Kolarz', 'My Rider');

  final String labelPl;
  final String labelEn;

  const DotwatchingMapFilter(this.labelPl, this.labelEn);
}

/// Zakładka dolnego/bocznego panelu w widoku mobilnym i kompaktowym.
enum UltraScreenMobileTab {
  trackerMap('Mapa GPS'),
  nightDecisions('Decyzje Nocne'),
  electronicsAndGear('Dynamo & Bagaż'),
  checkpointsAndDots('CP & Ranking');

  final String label;

  const UltraScreenMobileTab(this.label);
}

/// Kropka kolarza na mapie `Dotwatching Live Tracker`.
class DotwatchingRiderPin {
  final String id;
  final String capNumber;
  final String riderName;
  final String teamCode;
  final double distanceKm;
  final double speedKmh;
  final double elapsedHours;
  final double sleepDebtHours;
  final bool isPlayer;
  final bool isSleeping;
  final bool isScratched;
  final String statusNote;
  final int lastPingMinutesAgo;

  const DotwatchingRiderPin({
    required this.id,
    required this.capNumber,
    required this.riderName,
    required this.teamCode,
    required this.distanceKm,
    required this.speedKmh,
    required this.elapsedHours,
    required this.sleepDebtHours,
    this.isPlayer = false,
    this.isSleeping = false,
    this.isScratched = false,
    this.statusNote = 'Jazda',
    this.lastPingMinutesAgo = 2,
  });

  DotwatchingRiderPin copyWith({
    String? id,
    String? capNumber,
    String? riderName,
    String? teamCode,
    double? distanceKm,
    double? speedKmh,
    double? elapsedHours,
    double? sleepDebtHours,
    bool? isPlayer,
    bool? isSleeping,
    bool? isScratched,
    String? statusNote,
    int? lastPingMinutesAgo,
  }) {
    return DotwatchingRiderPin(
      id: id ?? this.id,
      capNumber: capNumber ?? this.capNumber,
      riderName: riderName ?? this.riderName,
      teamCode: teamCode ?? this.teamCode,
      distanceKm: distanceKm ?? this.distanceKm,
      speedKmh: speedKmh ?? this.speedKmh,
      elapsedHours: elapsedHours ?? this.elapsedHours,
      sleepDebtHours: sleepDebtHours ?? this.sleepDebtHours,
      isPlayer: isPlayer ?? this.isPlayer,
      isSleeping: isSleeping ?? this.isSleeping,
      isScratched: isScratched ?? this.isScratched,
      statusNote: statusNote ?? this.statusNote,
      lastPingMinutesAgo: lastPingMinutesAgo ?? this.lastPingMinutesAgo,
    );
  }
}

/// Wpis w dzienniku decyzji nocnych i zdarzeń telemetrycznych.
class UltraNightDecisionLogEntry {
  final String timestampLabel;
  final String title;
  final String detail;
  final Color accentColor;

  const UltraNightDecisionLogEntry({
    required this.timestampLabel,
    required this.title,
    required this.detail,
    required this.accentColor,
  });
}

/// Ekran wyścigów Ultra-Endurance Bikepacking z mapą GPS `Dotwatching Live Tracker`
/// i interaktywnym panelem decyzji nocnych (`Bivy vs Hotel`, `Sleep Debt`, `Dynamo`).
class UltraBikepackingTranscontinentalScreen extends StatefulWidget {
  final UltraEnduranceBikepackingRaceModel? initialRace;
  final bool isReadOnly;
  final VoidCallback? onBackPressed;

  const UltraBikepackingTranscontinentalScreen({
    super.key,
    this.initialRace,
    this.isReadOnly = false,
    this.onBackPressed,
  });

  @override
  State<UltraBikepackingTranscontinentalScreen> createState() =>
      _UltraBikepackingTranscontinentalScreenState();
}

class _UltraBikepackingTranscontinentalScreenState
    extends State<UltraBikepackingTranscontinentalScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beaconController;

  late UltraEnduranceBikepackingRaceModel _race;
  late UltraBikepackingRiderProgress _playerProgress;
  late UltraCircadianSleepState _sleepState;
  late BikepackingLoadout _loadout;
  late DynamoHubSpec _dynamoHub;

  UltraSleepStrategy _selectedSleepStrategy = UltraSleepStrategy.powerSleep90Min;
  BivyShelterCondition _selectedShelter = BivyShelterCondition.dryAlpineBivy;
  DotwatchingMapFilter _mapFilter = DotwatchingMapFilter.allRiders;
  UltraScreenMobileTab _mobileTab = UltraScreenMobileTab.trackerMap;

  String? _selectedRiderId;
  String? _selectedCheckpointId;
  double _ambientTempCelsius = 7.5;
  bool _isRaining = false;
  final double _baseCruisingSpeedKmh = 26.5;

  late List<DotwatchingRiderPin> _dotRiders;
  final List<UltraNightDecisionLogEntry> _decisionLog = [];

  @override
  void initState() {
    super.initState();
    _beaconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _initRaceScenario(
      widget.initialRace ??
          UltraEnduranceBikepackingRaceModel.transcontinental4000KmPreset(),
    );
  }

  void _initRaceScenario(UltraEnduranceBikepackingRaceModel race) {
    _race = race;
    _loadout = race.defaultLoadout;
    _dynamoHub = race.defaultDynamoHub;

    _playerProgress = const UltraBikepackingRiderProgress(
      riderId: 'player_ultra_042',
      distanceCoveredKm: 1642.0,
      elapsedHours: 78.5,
      movingHours: 64.0,
      stoppedHours: 14.5,
      totalSleepHours: 9.5,
      hoursSinceLastSleep: 21.5,
      sleepDebtHours: 6.4,
      cognitiveAlertnessPercent: 64.0,
      hydrationLiters: 1.8,
      caloriesDeficitKcal: 1250.0,
      visitedCheckpointIds: ['cp_0_start', 'cp_1_alps'],
      collectedStampIds: ['cp_0_start', 'cp_1_alps'],
      electronicsState: ElectronicsPowerState(
        headlightBatteryPercent: 76.0,
        gpsComputerBatteryPercent: 84.0,
        trackerBatteryPercent: 91.0,
        di2ShiftingBatteryPercent: 88.0,
        powerBankMah: 14200.0,
        powerBankCapacityMah: 20000.0,
      ),
    );

    _sleepState = UltraCircadianSleepState(
      elapsedRaceHours: _playerProgress.elapsedHours,
      localClockHour: 2.25,
      hoursSinceLastSleep: _playerProgress.hoursSinceLastSleep,
      sleepDebtHours: _playerProgress.sleepDebtHours,
      cumulativeSleepHours: _playerProgress.totalSleepHours,
      cognitiveAlertnessPercent: _playerProgress.cognitiveAlertnessPercent,
      activeCaffeineMg: 65.0,
      bivyStopsCount: 2,
      hotelStopsCount: 1,
      microNapsCount: 1,
      totalSleepStopHours: 9.5,
      totalHotelSpendEur: 85.0,
    );

    _dotRiders = [
      DotwatchingRiderPin(
        id: 'player_ultra_042',
        capNumber: '#042',
        riderName: 'K. Majewski (Ty)',
        teamCode: 'POL',
        distanceKm: _playerProgress.distanceCoveredKm,
        speedKmh: 24.8,
        elapsedHours: _playerProgress.elapsedHours,
        sleepDebtHours: _sleepState.sleepDebtHours,
        isPlayer: true,
        statusNote: 'Wspinaczka nocna',
        lastPingMinutesAgo: 1,
      ),
      const DotwatchingRiderPin(
        id: 'rival_001',
        capNumber: '#001',
        riderName: 'C. Strasser',
        teamCode: 'AUT',
        distanceKm: 1735.0,
        speedKmh: 26.2,
        elapsedHours: 78.5,
        sleepDebtHours: 7.8,
        statusNote: 'Atakuje nocą',
        lastPingMinutesAgo: 2,
      ),
      const DotwatchingRiderPin(
        id: 'rival_007',
        capNumber: '#007',
        riderName: 'F. Gemperle',
        teamCode: 'SUI',
        distanceKm: 1698.0,
        speedKmh: 0.0,
        elapsedHours: 78.5,
        sleepDebtHours: 3.1,
        isSleeping: true,
        statusNote: 'Bivy 90m (Zagrzeb)',
        lastPingMinutesAgo: 4,
      ),
      const DotwatchingRiderPin(
        id: 'rival_019',
        capNumber: '#019',
        riderName: 'L. De Vries',
        teamCode: 'NED',
        distanceKm: 1618.0,
        speedKmh: 23.4,
        elapsedHours: 78.5,
        sleepDebtHours: 5.9,
        statusNote: 'Równy rytm',
        lastPingMinutesAgo: 3,
      ),
      const DotwatchingRiderPin(
        id: 'rival_088',
        capNumber: '#088',
        riderName: 'J. Moreau',
        teamCode: 'FRA',
        distanceKm: 1520.0,
        speedKmh: 0.0,
        elapsedHours: 78.5,
        sleepDebtHours: 1.5,
        isSleeping: true,
        statusNote: 'Hotel 5h (Lublana)',
        lastPingMinutesAgo: 11,
      ),
      const DotwatchingRiderPin(
        id: 'rival_114',
        capNumber: '#114',
        riderName: 'M. Kowalczyk',
        teamCode: 'POL',
        distanceKm: 1385.0,
        speedKmh: 0.0,
        elapsedHours: 78.5,
        sleepDebtHours: 9.2,
        isScratched: true,
        statusNote: 'Scratch (kolano)',
        lastPingMinutesAgo: 45,
      ),
    ];

    _selectedRiderId = 'player_ultra_042';
    _selectedCheckpointId = _race.nextPendingCheckpoint(
      _playerProgress.visitedCheckpointIds,
    )?.id;

    _decisionLog
      ..clear()
      ..addAll(const [
        UltraNightDecisionLogEntry(
          timestampLabel: '78h 30m • 02:15',
          title: 'Wejście w Nadir Dobowy',
          detail:
              'Czujność spadła do 64%. Rozważ 90-min cykl snu lub biwak przed podjazdem w Górach Dynarskich.',
          accentColor: AppColors.amberWarning,
        ),
        UltraNightDecisionLogEntry(
          timestampLabel: '54h 10m • CP1',
          title: 'Zaliczone Passo dello Stelvio (2758 m)',
          detail:
              'Karta kontrolna podbita w limicie. Dynamo SON 28 doładowało lampkę do 100%.',
          accentColor: AppColors.statusSuccess,
        ),
      ]);
  }

  @override
  void dispose() {
    _beaconController.dispose();
    super.dispose();
  }

  bool get _isNightTime =>
      _sleepState.localClockHour >= 21.0 || _sleepState.localClockHour < 5.5;

  String _formatClockHour(double hour) {
    final norm = ((hour % 24.0) + 24.0) % 24.0;
    final h = norm.floor();
    final m = ((norm - h) * 60.0).round() % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String _formatElapsed(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60.0).round() % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  CircadianPhaseZone get _currentCircadianPhase =>
      UltraSleepDeprivationAndCircadianSolver.classifyCircadianPhase(
        _sleepState.localClockHour,
      );

  SleepDeprivationSeverity get _currentDeprivationSeverity =>
      UltraSleepDeprivationAndCircadianSolver.classifyDeprivationSeverity(
        _sleepState,
      );

  void _executeRidingBlock(double hours) {
    if (widget.isReadOnly || _playerProgress.isScratched) return;

    final currentSegment = _findCurrentSegment();
    final nextProgress = _race.simulateRidingBlock(
      progress: _playerProgress,
      durationHours: hours,
      baseCruisingSpeedKmh: _baseCruisingSpeedKmh,
      loadout: _loadout,
      dynamoHub: _dynamoHub,
      isNight: _isNightTime,
      segment: currentSegment,
    );

    final stepResult =
        UltraSleepDeprivationAndCircadianSolver.stepRidingPhysiology(
      _sleepState,
      UltraSleepPhysiologyStepInput(
        durationHours: hours,
        ambientTempCelsius: _ambientTempCelsius,
        isRaining: _isRaining,
        elevationMeters: 1200.0,
        isTechnicalDescent: _isNightTime && (currentSegment?.nightHazardFactor ?? 1.0) > 1.1,
        deterministicRoll: 0.42,
      ),
    );

    final coveredDelta =
        nextProgress.distanceCoveredKm - _playerProgress.distanceCoveredKm;
    final avgBlockSpeed = hours > 0 ? coveredDelta / hours : 0.0;

    setState(() {
      _playerProgress = nextProgress.copyWith(
        cognitiveAlertnessPercent:
            stepResult.nextState.cognitiveAlertnessPercent,
        sleepDebtHours: stepResult.nextState.sleepDebtHours,
      );
      _sleepState = stepResult.nextState;
      _syncDotRidersAfterTimeStep(
        hours: hours,
        playerSpeedKmh: avgBlockSpeed,
        playerStatus: _isNightTime ? 'Jazda nocna' : 'Jazda dzienna',
        playerSleeping: false,
      );
      _decisionLog.insert(
        0,
        UltraNightDecisionLogEntry(
          timestampLabel:
              '${_formatElapsed(_playerProgress.elapsedHours)} • ${_formatClockHour(_sleepState.localClockHour)}',
          title: 'Przejechano +${coveredDelta.toStringAsFixed(1)} km (${hours.toStringAsFixed(0)}h)',
          detail: stepResult.recommendedActionPl,
          accentColor: stepResult.microSleepTriggered
              ? AppColors.crimsonAlert
              : AppColors.accentBlue,
        ),
      );
    });
  }

  void _executeSleepDecision(UltraSleepStrategy strategy) {
    if (widget.isReadOnly || _playerProgress.isScratched) return;

    if (strategy == UltraSleepStrategy.pushThroughNight) {
      _executeRidingBlock(2.0);
      return;
    }

    final eval = UltraSleepDeprivationAndCircadianSolver.evaluateSleepStop(
      SleepStopEvaluationInput(
        currentState: _sleepState,
        strategy: strategy,
        shelterCondition: _selectedShelter,
        ambientTempCelsius: _ambientTempCelsius,
        isRaining: _isRaining,
      ),
    );

    final isWarm = _selectedShelter == BivyShelterCondition.warmIndoorHotel ||
        strategy == UltraSleepStrategy.hotel5Hours;

    final nextProgress = _playerProgress.applySleepStop(
      strategy,
      isWarmShelter: isWarm,
    );

    final totalStopHours = eval.totalStoppedHours;
    final hotelSpendDelta =
        eval.nextState.totalHotelSpendEur - _sleepState.totalHotelSpendEur;

    setState(() {
      _playerProgress = nextProgress.copyWith(
        cognitiveAlertnessPercent: eval.nextState.cognitiveAlertnessPercent,
        sleepDebtHours: eval.nextState.sleepDebtHours,
      );
      _sleepState = eval.nextState;
      _syncDotRidersAfterTimeStep(
        hours: totalStopHours,
        playerSpeedKmh: 0.0,
        playerStatus: '${strategy.displayNamePl} (${_selectedShelter.labelPl})',
        playerSleeping: true,
      );
      _decisionLog.insert(
        0,
        UltraNightDecisionLogEntry(
          timestampLabel:
              '${_formatElapsed(_playerProgress.elapsedHours)} • ${_formatClockHour(_sleepState.localClockHour)}',
          title: 'Postój: ${strategy.displayNamePl}',
          detail:
              'Odzyskano +${eval.alertnessGainedPercent.toStringAsFixed(0)}% czujności • '
              'Koszt czasu ${totalStopHours.toStringAsFixed(1)}h'
              '${hotelSpendDelta > 0 ? ' • ${hotelSpendDelta.toStringAsFixed(0)} EUR' : ''}',
          accentColor: AppColors.statusSuccess,
        ),
      );
    });
  }

  void _takeCaffeineDose(double mg) {
    if (widget.isReadOnly || _playerProgress.isScratched) return;

    final stepResult =
        UltraSleepDeprivationAndCircadianSolver.stepRidingPhysiology(
      _sleepState,
      UltraSleepPhysiologyStepInput(
        durationHours: 0.25,
        caffeineIntakeMg: mg,
        ambientTempCelsius: _ambientTempCelsius,
        isRaining: _isRaining,
      ),
    );

    setState(() {
      _sleepState = stepResult.nextState;
      _playerProgress = _playerProgress.copyWith(
        cognitiveAlertnessPercent:
            stepResult.nextState.cognitiveAlertnessPercent,
      );
      _decisionLog.insert(
        0,
        UltraNightDecisionLogEntry(
          timestampLabel:
              '${_formatElapsed(_playerProgress.elapsedHours)} • ${_formatClockHour(_sleepState.localClockHour)}',
          title: 'Dawka kofeiny +${mg.toInt()} mg',
          detail:
              'Aktywna kofeina: ${_sleepState.activeCaffeineMg.toStringAsFixed(0)} mg '
              '(maskowanie zmęczenia +${stepResult.caffeineBoostPercent.toStringAsFixed(1)}%).',
          accentColor: AppColors.goldAccent,
        ),
      );
    });
  }

  void _syncDotRidersAfterTimeStep({
    required double hours,
    required double playerSpeedKmh,
    required String playerStatus,
    required bool playerSleeping,
  }) {
    _dotRiders = _dotRiders.map((pin) {
      if (pin.isPlayer) {
        return pin.copyWith(
          distanceKm: _playerProgress.distanceCoveredKm,
          speedKmh: playerSpeedKmh,
          elapsedHours: _playerProgress.elapsedHours,
          sleepDebtHours: _sleepState.sleepDebtHours,
          isSleeping: playerSleeping,
          isScratched: _playerProgress.isScratched,
          statusNote: playerStatus,
          lastPingMinutesAgo: 0,
        );
      }
      if (pin.isScratched) return pin;
      final rivalSpeed = pin.isSleeping ? 18.0 : math.max(20.0, pin.speedKmh);
      final nextDist = math.min(
        _race.totalDistanceKm,
        pin.distanceKm + rivalSpeed * hours * 0.85,
      );
      return pin.copyWith(
        distanceKm: nextDist,
        elapsedHours: pin.elapsedHours + hours,
        isSleeping: false,
        speedKmh: rivalSpeed,
        statusNote: nextDist >= _race.totalDistanceKm ? 'Meta' : 'W trasie',
        lastPingMinutesAgo: (pin.lastPingMinutesAgo + 2) % 12,
      );
    }).toList();
  }

  UltraRouteSegmentSpec? _findCurrentSegment() {
    for (final seg in _race.routeSegments) {
      if (_playerProgress.distanceCoveredKm >= seg.startKm &&
          _playerProgress.distanceCoveredKm <= seg.endKm) {
        return seg;
      }
    }
    return _race.routeSegments.isNotEmpty ? _race.routeSegments.last : null;
  }

  List<DotwatchingRiderPin> get _filteredDotRiders {
    switch (_mapFilter) {
      case DotwatchingMapFilter.allRiders:
        return _dotRiders;
      case DotwatchingMapFilter.topLeaders:
        final sorted = List<DotwatchingRiderPin>.from(_dotRiders)
          ..sort((a, b) => b.distanceKm.compareTo(a.distanceKm));
        return sorted.take(3).toList();
      case DotwatchingMapFilter.restingOnly:
        return _dotRiders.where((r) => r.isSleeping).toList();
      case DotwatchingMapFilter.playerFocus:
        return _dotRiders.where((r) => r.isPlayer).toList();
    }
  }

  int get _playerRank {
    final sorted = List<DotwatchingRiderPin>.from(_dotRiders)
      ..sort((a, b) => b.distanceKm.compareTo(a.distanceKm));
    final idx = sorted.indexWhere((r) => r.isPlayer);
    return idx >= 0 ? idx + 1 : 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 760;
            final isTablet = width >= 760 && width < 1260;

            return Column(
              children: [
                _buildTopTelemetryHeader(isMobile: isMobile),
                Expanded(
                  child: isMobile
                      ? _buildMobileLayout()
                      : isTablet
                          ? _buildTabletLayout()
                          : _buildDesktopLayout(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopTelemetryHeader({required bool isMobile}) {
    final nextCp =
        _race.nextPendingCheckpoint(_playerProgress.visitedCheckpointIds);
    final distToCp = nextCp != null
        ? math.max(0.0, nextCp.distanceKm - _playerProgress.distanceCoveredKm)
        : 0.0;
    final progressRatio =
        (_playerProgress.distanceCoveredKm / _race.totalDistanceKm)
            .clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 10 : 14,
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
              if (widget.onBackPressed != null) ...[
                _InteractiveIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Powrót',
                  onPressed: widget.onBackPressed!,
                ),
                const SizedBox(width: 10),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _beaconController,
                      builder: (context, _) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.lerp(
                              AppColors.cyanAccent,
                              AppColors.statusSuccess,
                              _beaconController.value,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'DOTWATCHING LIVE',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.cyanAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _race.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 15 : 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      nextCp != null
                          ? 'Następny CP: ${nextCp.name} (${distToCp.toStringAsFixed(0)} km)'
                          : 'Ukończono wszystkie punkty kontrolne!',
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
                _buildQuickMetricChip(
                  icon: Icons.schedule_rounded,
                  label: 'Czas lok.',
                  value:
                      '${_formatClockHour(_sleepState.localClockHour)} (${_isNightTime ? 'Noc' : 'Dzień'})',
                  accent: _isNightTime
                      ? AppColors.accentBlue
                      : AppColors.goldAccent,
                ),
                const SizedBox(width: 8),
                _buildQuickMetricChip(
                  icon: Icons.leaderboard_rounded,
                  label: 'Pozycja',
                  value: '#$_playerRank / ${_dotRiders.length}',
                  accent: AppColors.goldAccent,
                ),
                const SizedBox(width: 8),
                _buildQuickMetricChip(
                  icon: Icons.route_rounded,
                  label: 'Dystans',
                  value:
                      '${_playerProgress.distanceCoveredKm.toStringAsFixed(0)} / ${_race.totalDistanceKm.toStringAsFixed(0)} km',
                  accent: AppColors.cyanAccent,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progressRatio,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.goldAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progressRatio * 100).toStringAsFixed(1)}% • ${_formatElapsed(_playerProgress.elapsedHours)}',
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

  Widget _buildQuickMetricChip({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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

  // ---------------------------------------------------------------------------
  // RESPONSIVE LAYOUTS (390x844 / 1024x768 / 1600x900)
  // ---------------------------------------------------------------------------

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Lewa i środkowa część: Mapa GPS Dotwatching + Dolne listy CP i Ranking
          Expanded(
            flex: 7,
            child: Column(
              children: [
                Expanded(
                  flex: 6,
                  child: _buildDotwatchingMapCard(compact: false),
                ),
                const SizedBox(height: 14),
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Expanded(child: _buildCheckpointsCard()),
                      const SizedBox(width: 14),
                      Expanded(child: _buildDotwatchingLeaderboardCard()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Prawa część: Panel decyzji nocnych + Fizjologia Snu + Dynamo & Bagaż
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildNightDecisionPanelCard(),
                  const SizedBox(height: 14),
                  _buildElectronicsAndLoadoutCard(),
                  const SizedBox(height: 14),
                  _buildDecisionLogCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          SizedBox(
            height: 360,
            child: _buildDotwatchingMapCard(compact: false),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildNightDecisionPanelCard()),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    _buildElectronicsAndLoadoutCard(),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 290,
                      child: _buildDotwatchingLeaderboardCard(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 250,
            child: Row(
              children: [
                Expanded(child: _buildCheckpointsCard()),
                const SizedBox(width: 14),
                Expanded(child: _buildDecisionLogCard()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: UltraScreenMobileTab.values.map((tab) {
                final selected = _mobileTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _InteractivePillButton(
                    label: tab.label,
                    selected: selected,
                    onTap: () => setState(() => _mobileTab = tab),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: switch (_mobileTab) {
              UltraScreenMobileTab.trackerMap => Column(
                  children: [
                    SizedBox(
                      height: 320,
                      child: _buildDotwatchingMapCard(compact: true),
                    ),
                    const SizedBox(height: 12),
                    _buildSimulationActionBar(compact: true),
                  ],
                ),
              UltraScreenMobileTab.nightDecisions => Column(
                  children: [
                    _buildNightDecisionPanelCard(),
                    const SizedBox(height: 12),
                    _buildDecisionLogCard(),
                  ],
                ),
              UltraScreenMobileTab.electronicsAndGear =>
                _buildElectronicsAndLoadoutCard(),
              UltraScreenMobileTab.checkpointsAndDots => Column(
                  children: [
                    SizedBox(
                      height: 280,
                      child: _buildDotwatchingLeaderboardCard(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 280,
                      child: _buildCheckpointsCard(),
                    ),
                  ],
                ),
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 1. DOTWATCHING LIVE TRACKER MAP CARD
  // ---------------------------------------------------------------------------

  Widget _buildDotwatchingMapCard({required bool compact}) {
    final selectedPin = _dotRiders.firstWhere(
      (r) => r.id == _selectedRiderId,
      orElse: () => _dotRiders.first,
    );

    return _SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.satellite_alt_rounded,
                    size: 18,
                    color: AppColors.cyanAccent,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Dotwatching Live Tracker (GPS)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: DotwatchingMapFilter.values.map((filter) {
                  return _InteractivePillButton(
                    label: filter.labelPl,
                    selected: _mapFilter == filter,
                    onTap: () => setState(() => _mapFilter = filter),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        return GestureDetector(
                          onTapDown: (details) => _handleMapTap(
                            details.localPosition,
                            box.biggest,
                          ),
                          child: AnimatedBuilder(
                            animation: _beaconController,
                            builder: (context, _) {
                              return CustomPaint(
                                painter: DotwatchingLiveTrackerPainter(
                                  race: _race,
                                  riders: _filteredDotRiders,
                                  visitedCheckpointIds:
                                      _playerProgress.visitedCheckpointIds,
                                  selectedRiderId: _selectedRiderId,
                                  selectedCheckpointId: _selectedCheckpointId,
                                  localClockHour: _sleepState.localClockHour,
                                  beaconPhase: _beaconController.value,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  // Nakładka z informacją o wybranym kolarzu na mapie
                  Positioned(
                    left: 10,
                    bottom: 10,
                    right: compact ? 10 : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selectedPin.isPlayer
                                  ? AppColors.cyanAccent
                                  : selectedPin.isSleeping
                                      ? AppColors.amberWarning
                                      : AppColors.goldAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${selectedPin.capNumber} ${selectedPin.riderName} • '
                              '${selectedPin.distanceKm.toStringAsFixed(0)} km • '
                              '${selectedPin.speedKmh.toStringAsFixed(1)} km/h • '
                              '${selectedPin.statusNote}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFeatures: [FontFeature.tabularFigures()],
                                color: AppColors.textPrimary,
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
          ),
          if (!compact) ...[
            const SizedBox(height: 10),
            _buildSimulationActionBar(compact: false),
          ],
        ],
      ),
    );
  }

  void _handleMapTap(Offset tapPos, Size size) {
    final visibleRiders = _filteredDotRiders;
    double bestDist = 28.0;
    String? hitRiderId;

    for (final pin in visibleRiders) {
      final t = (pin.distanceKm / _race.totalDistanceKm).clamp(0.0, 1.0);
      final pt = DotwatchingLiveTrackerPainter.routePointAt(t, size);
      final d = (pt - tapPos).distance;
      if (d < bestDist) {
        bestDist = d;
        hitRiderId = pin.id;
      }
    }

    if (hitRiderId != null) {
      setState(() => _selectedRiderId = hitRiderId);
      return;
    }

    for (final cp in _race.checkpoints) {
      final t = (cp.distanceKm / _race.totalDistanceKm).clamp(0.0, 1.0);
      final pt = DotwatchingLiveTrackerPainter.routePointAt(t, size);
      if ((pt - tapPos).distance < 26.0) {
        setState(() => _selectedCheckpointId = cp.id);
        return;
      }
    }
  }

  Widget _buildSimulationActionBar({required bool compact}) {
    final disabled = widget.isReadOnly || _playerProgress.isScratched;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _InteractiveActionButton(
          icon: Icons.directions_bike_rounded,
          label: '+2h Jazdy',
          accent: AppColors.cyanAccent,
          disabled: disabled,
          onPressed: () => _executeRidingBlock(2.0),
        ),
        _InteractiveActionButton(
          icon: Icons.nights_stay_rounded,
          label: '+4h Odcinek Nocny',
          accent: AppColors.accentBlue,
          disabled: disabled,
          onPressed: () => _executeRidingBlock(4.0),
        ),
        _InteractiveActionButton(
          icon: Icons.local_cafe_rounded,
          label: 'Espresso +100 mg',
          accent: AppColors.goldAccent,
          disabled: disabled,
          onPressed: () => _takeCaffeineDose(100.0),
        ),
        if (!compact)
          _InteractiveActionButton(
            icon: Icons.water_drop_rounded,
            label: _isRaining ? 'Deszcz: TAK' : 'Deszcz: NIE',
            accent: _isRaining ? AppColors.amberWarning : AppColors.textSecondary,
            disabled: widget.isReadOnly,
            onPressed: () => setState(() {
              _isRaining = !_isRaining;
              _ambientTempCelsius = _isRaining ? 4.5 : 8.5;
            }),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. NIGHT DECISIONS & SLEEP PHYSIOLOGY PANEL
  // ---------------------------------------------------------------------------

  Widget _buildNightDecisionPanelCard() {
    final phase = _currentCircadianPhase;
    final severity = _currentDeprivationSeverity;
    final alertness = _sleepState.cognitiveAlertnessPercent;
    final crashRisk = _playerProgress.hallucinationAndCrashRisk(
      isNight: _isNightTime,
    );

    final previewEval = UltraSleepDeprivationAndCircadianSolver.evaluateSleepStop(
      SleepStopEvaluationInput(
        currentState: _sleepState,
        strategy: _selectedSleepStrategy,
        shelterCondition: _selectedShelter,
        ambientTempCelsius: _ambientTempCelsius,
        isRaining: _isRaining,
      ),
    );

    final severityColor = severity.requiresMandatoryStop
        ? AppColors.crimsonAlert
        : severity == SleepDeprivationSeverity.moderateImpairment
            ? AppColors.amberWarning
            : AppColors.statusSuccess;

    return _SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bedtime_rounded,
                size: 18,
                color: AppColors.goldAccent,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Panel Decyzji Nocnych & Sleep Debt',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: severityColor.withValues(alpha: 0.55),
                  ),
                ),
                child: Text(
                  severity.labelPl,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: severityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Faza dobowa & metryki fizjologii snu
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Faza: ${phase.labelPl}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Temp: ${_ambientTempCelsius.toStringAsFixed(1)}°C',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildMiniStat(
                      'Czujność',
                      '${alertness.toStringAsFixed(0)}%',
                      alertness < 45
                          ? AppColors.crimsonAlert
                          : alertness < 70
                              ? AppColors.amberWarning
                              : AppColors.statusSuccess,
                    ),
                    _buildMiniStat(
                      'Dług snu',
                      '${_sleepState.sleepDebtHours.toStringAsFixed(1)} h',
                      _sleepState.sleepDebtHours > 7.0
                          ? AppColors.crimsonAlert
                          : AppColors.goldAccent,
                    ),
                    _buildMiniStat(
                      'Bez snu',
                      '${_sleepState.hoursSinceLastSleep.toStringAsFixed(1)} h',
                      AppColors.textPrimary,
                    ),
                    _buildMiniStat(
                      'Ryzyko błędu',
                      '${(crashRisk * 100).toStringAsFixed(0)}%',
                      crashRisk > 0.35
                          ? AppColors.crimsonAlert
                          : AppColors.cyanAccent,
                    ),
                    _buildMiniStat(
                      'Kofeina',
                      '${_sleepState.activeCaffeineMg.toStringAsFixed(0)} mg',
                      AppColors.goldAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Warunki Schronienia (Bivy vs Hotel)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: BivyShelterCondition.values.map((shelter) {
              return _InteractivePillButton(
                label: shelter.labelPl,
                selected: _selectedShelter == shelter,
                disabled: widget.isReadOnly,
                onTap: () => setState(() => _selectedShelter = shelter),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Strategia Nocna',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Column(
            children: UltraSleepStrategy.values.map((strategy) {
              final selected = _selectedSleepStrategy == strategy;
              final eval =
                  UltraSleepDeprivationAndCircadianSolver.evaluateSleepStop(
                SleepStopEvaluationInput(
                  currentState: _sleepState,
                  strategy: strategy,
                  shelterCondition: _selectedShelter,
                  ambientTempCelsius: _ambientTempCelsius,
                  isRaining: _isRaining,
                ),
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _NightStrategyOptionTile(
                  strategy: strategy,
                  evaluation: eval,
                  selected: selected,
                  disabled: widget.isReadOnly,
                  onTap: () =>
                      setState(() => _selectedSleepStrategy = strategy),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primaryAccent.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.psychology_rounded,
                  size: 16,
                  color: AppColors.goldAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    previewEval.verdictPl,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _InteractiveActionButton(
              icon: _selectedSleepStrategy == UltraSleepStrategy.pushThroughNight
                  ? Icons.bolt_rounded
                  : Icons.hotel_rounded,
              label: _selectedSleepStrategy == UltraSleepStrategy.pushThroughNight
                  ? 'Zatwierdź: Jedź dalej przez noc (+2h)'
                  : 'Wykonaj postój: ${_selectedSleepStrategy.displayNamePl}',
              accent: AppColors.goldAccent,
              filled: true,
              disabled: widget.isReadOnly || _playerProgress.isScratched,
              onPressed: () => _executeSleepDecision(_selectedSleepStrategy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. ELECTRONICS, DYNAMO HUB & BIKEPACKING LOADOUT CARD
  // ---------------------------------------------------------------------------

  Widget _buildElectronicsAndLoadoutCard() {
    final readiness = _race.evaluateSetupReadiness(
      loadout: _loadout,
      dynamoHub: _dynamoHub,
      electronics: _playerProgress.electronicsState,
    );
    final elec = _playerProgress.electronicsState;

    return _SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.electrical_services_rounded,
                size: 18,
                color: AppColors.cyanAccent,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Dynamo Hub, Elektronika & Bagaż',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${readiness.totalPackWeightKg.toStringAsFixed(1)} kg • '
                '${readiness.netDynamoWattsAt25KmhNight >= 0 ? '+' : ''}'
                '${readiness.netDynamoWattsAt25KmhNight.toStringAsFixed(1)} W',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: readiness.netDynamoWattsAt25KmhNight >= 0
                      ? AppColors.statusSuccess
                      : AppColors.amberWarning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _InteractivePillButton(
                label: 'SON 28 Ultra',
                selected: _dynamoHub.tier == DynamoHubTier.highEfficiencySon28,
                disabled: widget.isReadOnly,
                onTap: () => setState(
                  () => _dynamoHub = DynamoHubSpec.son28Ultra(),
                ),
              ),
              _InteractivePillButton(
                label: 'Aero Dynamo',
                selected:
                    _dynamoHub.tier == DynamoHubTier.ultraLowDragAeroDynamo,
                disabled: widget.isReadOnly,
                onTap: () => setState(
                  () => _dynamoHub = const DynamoHubSpec(
                    id: 'dynamo_aero',
                    name: 'SONdelux Aero Ultra',
                    tier: DynamoHubTier.ultraLowDragAeroDynamo,
                    nominalOutputWattsAt20Kmh: 4.1,
                    peakOutputWatts: 6.4,
                    mechanicalDragWattsEngaged: 4.2,
                    mechanicalDragWattsDisengaged: 0.45,
                    weightGrams: 385,
                    usbCacheBatteryMah: 1800,
                    isEngaged: true,
                  ),
                ),
              ),
              _InteractivePillButton(
                label: 'Tylko Powerbank',
                selected: _dynamoHub.tier == DynamoHubTier.noneBatteryOnly,
                disabled: widget.isReadOnly,
                onTap: () => setState(
                  () => _dynamoHub = DynamoHubSpec.batteryOnly(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBatteryBar('Lampka przednia LED', elec.headlightBatteryPercent),
          const SizedBox(height: 6),
          _buildBatteryBar('Licznik GPS / Nawigacja', elec.gpsComputerBatteryPercent),
          const SizedBox(height: 6),
          _buildBatteryBar('Nadajnik Dotwatching', elec.trackerBatteryPercent),
          const SizedBox(height: 6),
          _buildBatteryBar(
            'PowerBank (${elec.powerBankMah.toInt()} / ${elec.powerBankCapacityMah.toInt()} mAh)',
            (elec.powerBankMah / elec.powerBankCapacityMah * 100.0)
                .clamp(0.0, 100.0),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryBar(String label, double percent) {
    final clamped = percent.clamp(0.0, 100.0);
    final barColor = clamped < 25.0
        ? AppColors.crimsonAlert
        : clamped < 50.0
            ? AppColors.amberWarning
            : AppColors.statusSuccess;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(
              '${clamped.toStringAsFixed(0)}%',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clamped / 100.0,
            minHeight: 5,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. CHECKPOINTS & LIVE DOTWATCHING LEADERBOARD
  // ---------------------------------------------------------------------------

  Widget _buildCheckpointsCard() {
    return _SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flag_rounded, size: 18, color: AppColors.goldAccent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Punkty Kontrolne (CP & Parcours)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: _race.checkpoints.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final cp = _race.checkpoints[index];
                final visited =
                    _playerProgress.visitedCheckpointIds.contains(cp.id);
                final selected = _selectedCheckpointId == cp.id;

                return InkWell(
                  onTap: () => setState(() => _selectedCheckpointId = cp.id),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryAccent.withValues(alpha: 0.2)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.goldAccent
                            : AppTheme.borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          visited
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: visited
                              ? AppColors.statusSuccess
                              : AppColors.goldAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cp.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${cp.distanceKm.toStringAsFixed(0)} km • '
                                '${cp.elevationM.toStringAsFixed(0)} m n.p.m. • '
                                'Limit ${cp.cutOffHoursFromStart.toStringAsFixed(0)}h',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildDotwatchingLeaderboardCard() {
    final sorted = List<DotwatchingRiderPin>.from(_dotRiders)
      ..sort((a, b) => b.distanceKm.compareTo(a.distanceKm));

    return _SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.format_list_numbered_rounded,
                size: 18,
                color: AppColors.cyanAccent,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Klasyfikacja Live Dotwatching',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final pin = sorted[index];
                final selected = _selectedRiderId == pin.id;
                final statusColor = pin.isScratched
                    ? AppColors.crimsonAlert
                    : pin.isSleeping
                        ? AppColors.amberWarning
                        : pin.isPlayer
                            ? AppColors.cyanAccent
                            : AppColors.statusSuccess;

                return InkWell(
                  onTap: () => setState(() => _selectedRiderId = pin.id),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: pin.isPlayer
                          ? AppColors.cyanAccent.withValues(alpha: 0.1)
                          : selected
                              ? AppColors.primaryAccent.withValues(alpha: 0.18)
                              : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: pin.isPlayer
                            ? AppColors.cyanAccent.withValues(alpha: 0.55)
                            : selected
                                ? AppColors.goldAccent
                                : AppTheme.borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${index + 1}.',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()],
                              color: AppColors.goldAccent,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${pin.capNumber} ${pin.riderName} (${pin.teamCode})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                pin.statusNote,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${pin.distanceKm.toStringAsFixed(0)} km',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
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

  Widget _buildDecisionLogCard() {
    return _SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dziennik Decyzji Nocnych',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._decisionLog.take(4).map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border(
                        left: BorderSide(color: entry.accentColor, width: 3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                entry.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.timestampLabel,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontFeatures: [FontFeature.tabularFigures()],
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          entry.detail,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTER: DOTWATCHING LIVE TRACKER MAP
// =============================================================================

class DotwatchingLiveTrackerPainter extends CustomPainter {
  final UltraEnduranceBikepackingRaceModel race;
  final List<DotwatchingRiderPin> riders;
  final List<String> visitedCheckpointIds;
  final String? selectedRiderId;
  final String? selectedCheckpointId;
  final double localClockHour;
  final double beaconPhase;

  const DotwatchingLiveTrackerPainter({
    required this.race,
    required this.riders,
    required this.visitedCheckpointIds,
    required this.selectedRiderId,
    required this.selectedCheckpointId,
    required this.localClockHour,
    required this.beaconPhase,
  });

  /// Wyznacza punkt na zstylizowanej kontynentalnej trasie 2D dla ułamka `t` in [0, 1].
  static Offset routePointAt(double t, Size size) {
    final clamped = t.clamp(0.0, 1.0);
    final padX = size.width * 0.08;
    final padY = size.height * 0.18;
    final usableW = math.max(10.0, size.width - padX * 2);
    final usableH = math.max(10.0, size.height - padY * 2);

    final x = padX + clamped * usableW;
    // Kontynentalna krzywa z przełęczami alpejskimi i łukiem bałkańskim
    final wave = math.sin(clamped * math.pi * 2.4) * 0.28 +
        math.cos(clamped * math.pi * 5.2) * 0.09;
    final y = padY + usableH * (0.52 - wave);
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final isNight = localClockHour >= 21.0 || localClockHour < 5.5;

    // 1. Tło mapy satelitarnej / topograficznej
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isNight
            ? const [Color(0xFF0A0D13), Color(0xFF111826), Color(0xFF0D1119)]
            : const [Color(0xFF121722), Color(0xFF1A2232), Color(0xFF131924)],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // 2. Siatka współrzędnych GPS (graticule)
    final gridPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.45)
      ..strokeWidth = 0.8;
    const cols = 8;
    const rows = 5;
    for (int c = 1; c < cols; c++) {
      final x = size.width * (c / cols);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (int r = 1; r < rows; r++) {
      final y = size.height * (r / rows);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 3. Nocna strefa terminatora (jeśli jest noc)
    if (isNight) {
      final nightOverlay = Paint()
        ..color = const Color(0xFF070A10).withValues(alpha: 0.34);
      canvas.drawRect(rect, nightOverlay);
    }

    // 4. Rysowanie trasy segment po segmencie
    final routePath = Path();
    const samples = 90;
    for (int i = 0; i <= samples; i++) {
      final t = i / samples;
      final pt = routePointAt(t, size);
      if (i == 0) {
        routePath.moveTo(pt.dx, pt.dy);
      } else {
        routePath.lineTo(pt.dx, pt.dy);
      }
    }

    // Poświata trasy
    canvas.drawPath(
      routePath,
      Paint()
        ..color = AppColors.accentBlue.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round,
    );

    // Główna linia GPX
    canvas.drawPath(
      routePath,
      Paint()
        ..color = AppColors.accentBlue.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    // 5. Punkty kontrolne (Checkpoints)
    final visitedSet = visitedCheckpointIds.toSet();
    for (final cp in race.checkpoints) {
      final t = (cp.distanceKm / race.totalDistanceKm).clamp(0.0, 1.0);
      final pt = routePointAt(t, size);
      final visited = visitedSet.contains(cp.id);
      final selected = cp.id == selectedCheckpointId;

      if (selected) {
        canvas.drawCircle(
          pt,
          12.0,
          Paint()..color = AppColors.goldAccent.withValues(alpha: 0.24),
        );
      }

      canvas.drawCircle(
        pt,
        5.5,
        Paint()
          ..color = visited ? AppColors.statusSuccess : AppColors.goldAccent,
      );
      canvas.drawCircle(
        pt,
        5.5,
        Paint()
          ..color = AppColors.background
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      final cpPainter = TextPainter(
        text: TextSpan(
          text: cp.index == 0
              ? 'START'
              : cp.type == UltraCheckpointType.finishLine
                  ? 'META'
                  : 'CP${cp.index}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      cpPainter.paint(canvas, Offset(pt.dx - cpPainter.width / 2, pt.dy + 9));
    }

    // 6. Kropki kolarzy (Live Dots)
    for (final pin in riders) {
      final t = (pin.distanceKm / race.totalDistanceKm).clamp(0.0, 1.0);
      final pt = routePointAt(t, size);
      final isSelected = pin.id == selectedRiderId;

      final dotColor = pin.isScratched
          ? AppColors.crimsonAlert
          : pin.isPlayer
              ? AppColors.cyanAccent
              : pin.isSleeping
                  ? AppColors.amberWarning
                  : AppColors.textPrimary;

      if (pin.isPlayer || isSelected) {
        final pulseRadius = 9.0 + beaconPhase * 8.0;
        canvas.drawCircle(
          pt,
          pulseRadius,
          Paint()
            ..color = dotColor.withValues(alpha: 0.28 * (1.0 - beaconPhase)),
        );
      }

      canvas.drawCircle(
        pt,
        pin.isPlayer ? 6.5 : 5.0,
        Paint()..color = dotColor,
      );
      canvas.drawCircle(
        pt,
        pin.isPlayer ? 6.5 : 5.0,
        Paint()
          ..color = AppColors.background
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );

      final capPainter = TextPainter(
        text: TextSpan(
          text: pin.capNumber,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: pin.isPlayer ? AppColors.cyanAccent : AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      capPainter.paint(
        canvas,
        Offset(pt.dx - capPainter.width / 2, pt.dy - 19),
      );
    }
  }

  @override
  bool shouldRepaint(covariant DotwatchingLiveTrackerPainter oldDelegate) {
    return oldDelegate.riders != riders ||
        oldDelegate.selectedRiderId != selectedRiderId ||
        oldDelegate.selectedCheckpointId != selectedCheckpointId ||
        oldDelegate.localClockHour != localClockHour ||
        oldDelegate.beaconPhase != beaconPhase ||
        oldDelegate.visitedCheckpointIds != visitedCheckpointIds;
  }
}

// =============================================================================
// REUSABLE INTERACTIVE UI PRIMITIVES (HOVER / FOCUS / ACTIVE / DISABLED)
// =============================================================================

class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: child,
    );
  }
}

class _InteractivePillButton extends StatefulWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _InteractivePillButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.disabled = false,
  });

  @override
  State<_InteractivePillButton> createState() => _InteractivePillButtonState();
}

class _InteractivePillButtonState extends State<_InteractivePillButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.selected
            ? AppColors.primaryAccent.withValues(alpha: 0.35)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    final borderColor = widget.disabled
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : widget.selected
            ? AppColors.goldAccent
            : _focused
                ? AppColors.cyanAccent
                : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: !widget.disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.disabled ? null : widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.disabled
                  ? AppColors.textSecondary.withValues(alpha: 0.5)
                  : widget.selected
                      ? AppColors.goldAccent
                      : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool filled;
  final bool disabled;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onPressed,
    this.filled = false,
    this.disabled = false,
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
    final bg = widget.disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.filled
            ? widget.accent.withValues(alpha: _hovered ? 0.28 : 0.2)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    final border = widget.disabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _focused
            ? AppColors.cyanAccent
            : widget.accent.withValues(alpha: _hovered ? 0.9 : 0.55);

    return FocusableActionDetector(
      enabled: !widget.disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: InkWell(
          onTap: widget.disabled ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 16,
                    color: widget.disabled
                        ? AppColors.textSecondary.withValues(alpha: 0.45)
                        : widget.accent,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: widget.disabled
                            ? AppColors.textSecondary.withValues(alpha: 0.45)
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _InteractiveIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_InteractiveIconButton> createState() => _InteractiveIconButtonState();
}

class _InteractiveIconButtonState extends State<_InteractiveIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceLight : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Icon(widget.icon, size: 18, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _NightStrategyOptionTile extends StatefulWidget {
  final UltraSleepStrategy strategy;
  final SleepStopEvaluationResult evaluation;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _NightStrategyOptionTile({
    required this.strategy,
    required this.evaluation,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  State<_NightStrategyOptionTile> createState() =>
      _NightStrategyOptionTileState();
}

class _NightStrategyOptionTileState extends State<_NightStrategyOptionTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final isPush = widget.strategy == UltraSleepStrategy.pushThroughNight;
    final bg = widget.disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.selected
            ? AppColors.primaryAccent.withValues(alpha: 0.25)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;
    final border = widget.selected
        ? AppColors.goldAccent
        : _focused
            ? AppColors.cyanAccent
            : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: !widget.disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.disabled ? null : widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                isPush
                    ? Icons.flash_on_rounded
                    : widget.strategy == UltraSleepStrategy.hotel5Hours
                        ? Icons.hotel_rounded
                        : Icons.nights_stay_rounded,
                size: 16,
                color: isPush
                    ? AppColors.crimsonAlert
                    : widget.selected
                        ? AppColors.goldAccent
                        : AppColors.accentBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.strategy.displayNamePl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      isPush
                          ? 'Brak snu • Wyższe ryzyko halucynacji'
                          : '+${widget.evaluation.alertnessGainedPercent.toStringAsFixed(0)}% czujności • '
                              '-${widget.evaluation.debtRecoveredHours.toStringAsFixed(1)}h długu',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.strategy == UltraSleepStrategy.hotel5Hours)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Text(
                    '€85',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.goldAccent,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
