import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/physics/velodrome_banking_and_centripetal_solver.dart';
import '../../engine/rendering3d/velodrome_wooden_bowl_3d_renderer.dart';
import '../../models/race/velodrome_track_and_hour_record_model.dart';
import '../../models/rider/rider.dart';

/// Strategia tempa podczas oficjalnej próby bicia Rekordu Godzinnego UCI.
enum HourRecordPacingStrategy {
  evenPace('Równe Tempo', 'Stały czas okrążenia od startu do 60:00.00'),
  negativeSplit(
    'Negative Split',
    'Oszczędne otwarcie 0–20 min i stopniowe przyspieszenie w finale',
  );

  final String labelPl;
  final String descriptionPl;

  const HourRecordPacingStrategy(this.labelPl, this.descriptionPl);
}

/// Faza próby bicia Rekordu Godzinnego UCI.
enum HourRecordAttemptPhase {
  setup,
  running,
  paused,
  completed,
}

/// Profil kolarza przystępującego do próby bicia Rekordu Godzinnego UCI.
class HourRecordCandidateProfile {
  final String id;
  final String fullName;
  final String nationalityCode;
  final String teamName;
  final UciHourRecordCategory category;
  final double ftpWatts;
  final double wPrimeJoules;
  final double massKg;
  final double cdaMetersSquared;
  final double lineDisciplineSkill;
  final double pacingPrecisionSkill;

  const HourRecordCandidateProfile({
    required this.id,
    required this.fullName,
    required this.nationalityCode,
    required this.teamName,
    required this.category,
    required this.ftpWatts,
    required this.wPrimeJoules,
    required this.massKg,
    required this.cdaMetersSquared,
    this.lineDisciplineSkill = 96.0,
    this.pacingPrecisionSkill = 96.0,
  });

  factory HourRecordCandidateProfile.fromRider(Rider rider) {
    return HourRecordCandidateProfile(
      id: rider.id,
      fullName: rider.fullName,
      nationalityCode: rider.nationalityIso,
      teamName: 'Pro Peloton Team',
      category: UciHourRecordCategory.menElite,
      ftpWatts: rider.physiology.ftpWatts.toDouble(),
      wPrimeJoules: rider.physiology.wPrimeJoules.toDouble(),
      massKg: rider.physiology.weightKg,
      cdaMetersSquared: 0.168,
      lineDisciplineSkill:
          ((rider.skills.timeTrialPositioning * 0.6) +
                  (rider.skills.bikeHandling * 0.4))
              .clamp(75.0, 99.0),
      pacingPrecisionSkill:
          ((rider.skills.timeTrialPositioning * 0.7) +
                  (rider.skills.raceIq * 0.3))
              .clamp(75.0, 99.0),
    );
  }

  static const List<HourRecordCandidateProfile> defaultCandidates = [
    HourRecordCandidateProfile(
      id: 'cand_tt_specialist',
      fullName: 'Filippo Bellini',
      nationalityCode: 'ITA',
      teamName: 'Aurelia Pro Cycling',
      category: UciHourRecordCategory.menElite,
      ftpWatts: 468.0,
      wPrimeJoules: 26500.0,
      massKg: 76.0,
      cdaMetersSquared: 0.165,
      lineDisciplineSkill: 98.0,
      pacingPrecisionSkill: 98.0,
    ),
    HourRecordCandidateProfile(
      id: 'cand_aero_engineer',
      fullName: 'Daniel Sterling',
      nationalityCode: 'GBR',
      teamName: 'Albion Aero Project',
      category: UciHourRecordCategory.menElite,
      ftpWatts: 446.0,
      wPrimeJoules: 23000.0,
      massKg: 71.5,
      cdaMetersSquared: 0.160,
      lineDisciplineSkill: 97.0,
      pacingPrecisionSkill: 99.0,
    ),
    HourRecordCandidateProfile(
      id: 'cand_women_elite',
      fullName: 'Vittoria Conti',
      nationalityCode: 'ITA',
      teamName: 'Stella Rosa Track',
      category: UciHourRecordCategory.womenElite,
      ftpWatts: 362.0,
      wPrimeJoules: 19500.0,
      massKg: 58.5,
      cdaMetersSquared: 0.154,
      lineDisciplineSkill: 97.0,
      pacingPrecisionSkill: 97.0,
    ),
  ];
}

/// Zarejestrowany międzyczas pojedynczego okrążenia 250 m w trakcie próby.
class HourRecordLiveLapSplit {
  final int lapNumber;
  final double lapTimeSeconds;
  final double targetLapTimeSeconds;
  final double cumulativeTimeSeconds;
  final double cumulativeDistanceMeters;
  final double speedKmh;
  final double powerWatts;

  const HourRecordLiveLapSplit({
    required this.lapNumber,
    required this.lapTimeSeconds,
    required this.targetLapTimeSeconds,
    required this.cumulativeTimeSeconds,
    required this.cumulativeDistanceMeters,
    required this.speedKmh,
    required this.powerWatts,
  });

  double get deltaSeconds => lapTimeSeconds - targetLapTimeSeconds;

  bool get isOnPace => deltaSeconds.abs() <= 0.10;
}

/// Oficjalny wynik zakończonej 60-minutowej próby Rekordu Godzinnego UCI.
class HourRecordFinalProtocol {
  final HourRecordCandidateProfile candidate;
  final VelodromeFacilitySpec facility;
  final FixedGearTrackBike bike;
  final HourRecordPacingStrategy strategy;
  final double finalDistanceKm;
  final double completedLaps;
  final double averageSpeedKmh;
  final double averagePowerWatts;
  final double averageCadenceRpm;
  final double averageLapTimeSeconds;
  final double worldRecordToBeatKm;
  final double deltaToWorldRecordMeters;
  final bool isNewWorldRecord;
  final String certificateSerial;
  final DateTime completedAt;

  const HourRecordFinalProtocol({
    required this.candidate,
    required this.facility,
    required this.bike,
    required this.strategy,
    required this.finalDistanceKm,
    required this.completedLaps,
    required this.averageSpeedKmh,
    required this.averagePowerWatts,
    required this.averageCadenceRpm,
    required this.averageLapTimeSeconds,
    required this.worldRecordToBeatKm,
    required this.deltaToWorldRecordMeters,
    required this.isNewWorldRecord,
    required this.certificateSerial,
    required this.completedAt,
  });
}

/// Ekran oficjalnej Próby Bicia Rekordu Godzinnego UCI (UCI Hour Record Attempt).
class UciHourRecordAttemptScreen extends StatefulWidget {
  final Rider? initialRider;
  final String initialVelodromeId;
  final VoidCallback? onBack;

  const UciHourRecordAttemptScreen({
    super.key,
    this.initialRider,
    this.initialVelodromeId = 'aguascalientes_bicentenario',
    this.onBack,
  });

  @override
  State<UciHourRecordAttemptScreen> createState() =>
      _UciHourRecordAttemptScreenState();
}

class _UciHourRecordAttemptScreenState extends State<UciHourRecordAttemptScreen>
    with SingleTickerProviderStateMixin {
  static const double _attemptDurationSeconds = 3600.0;
  static const double _standardLapLengthMeters = 250.0;

  late final List<HourRecordCandidateProfile> _candidates;
  late HourRecordCandidateProfile _selectedCandidate;
  late VelodromeFacilitySpec _selectedFacility;
  late int _chainringTeeth;
  late int _cogTeeth;
  HourRecordPacingStrategy _strategy = HourRecordPacingStrategy.negativeSplit;
  double _targetLapTimeSeconds = 15.65;
  double _negativeSplitSpreadSeconds = 0.24;
  double _altitudeAcclimatizationBonus = 0.55;

  HourRecordAttemptPhase _phase = HourRecordAttemptPhase.setup;
  VelodromeCameraMode _cameraMode = VelodromeCameraMode.chaseMoto;
  double _cameraYawOffset = 0.0;
  double _simulationSpeedMultiplier = 60.0;
  bool _showVirtualRecordLaser = true;

  // Stan aktywnej symulacji 60:00.00
  late final Ticker _ticker;
  Duration? _lastTickElapsed;
  double _elapsedSeconds = 0.0;
  double _distanceMeters = 0.0;
  double _currentSpeedMs = 0.0;
  double _currentPowerWatts = 0.0;
  double _currentCadenceRpm = 0.0;
  double _currentGForce = 1.0;
  double _remainingWPrimeJoules = 25000.0;
  int _currentLapNumber = 1;
  double _lapStartTimeSeconds = 0.0;
  double _lapStartDistanceMeters = 0.0;
  double _lastLapTimeSeconds = 0.0;
  double _sumPowerSamples = 0.0;
  double _sumCadenceSamples = 0.0;
  int _sampleCount = 0;
  double _lapFlashIntensity = 0.0;
  final List<HourRecordLiveLapSplit> _recentLaps = <HourRecordLiveLapSplit>[];
  VelodromeWoodenBowlTelemetry? _latest3dTelemetry;
  HourRecordFinalProtocol? _finalProtocol;

  @override
  void initState() {
    super.initState();
    _candidates = [
      if (widget.initialRider != null)
        HourRecordCandidateProfile.fromRider(widget.initialRider!),
      ...HourRecordCandidateProfile.defaultCandidates,
    ];
    _selectedCandidate = _candidates.first;
    _selectedFacility =
        VelodromeTrackAndHourRecordModel.defaultVelodromes.firstWhere(
      (v) => v.id == widget.initialVelodromeId,
      orElse: () => VelodromeTrackAndHourRecordModel.defaultVelodromes.first,
    );
    _chainringTeeth = 61;
    _cogTeeth = 14;
    _remainingWPrimeJoules = _selectedCandidate.wPrimeJoules;
    _syncOptimalTargetLapTime();

    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  FixedGearTrackBike get _currentBike => FixedGearTrackBike(
        modelName: 'Bolide HR Aero Track',
        chainringTeeth: _chainringTeeth.clamp(
          FixedGearTrackBike.minChainringTeeth,
          FixedGearTrackBike.maxChainringTeeth,
        ),
        cogTeeth: _cogTeeth.clamp(
          FixedGearTrackBike.minCogTeeth,
          FixedGearTrackBike.maxCogTeeth,
        ),
        cdaMetersSquared: _selectedCandidate.cdaMetersSquared,
        bikeWeightKg: 7.1,
        drivetrainEfficiency: 0.986,
      );

  UciHourRecordEntry get _recordToBeat {
    final model = VelodromeTrackAndHourRecordModel.standard(
      initialVelodromeId: _selectedFacility.id,
      customBike: _currentBike,
    );
    return model.currentRecordForCategory(_selectedCandidate.category);
  }

  double get _effectiveHypoxiaFactor {
    final base = _selectedFacility.hypoxiaPowerPenaltyFactor;
    final reduction =
        (1.0 - base) * _altitudeAcclimatizationBonus.clamp(0.0, 0.70);
    return (base + reduction).clamp(0.70, 1.0);
  }

  double get _effectiveFtpWatts =>
      _selectedCandidate.ftpWatts * _effectiveHypoxiaFactor;

  HourRecordAttemptSimulation get _preAttemptProjection {
    final model = VelodromeTrackAndHourRecordModel.standard(
      initialVelodromeId: _selectedFacility.id,
      customBike: _currentBike,
    );
    return model.simulateHourRecordAttempt(
      sustainableHourPowerWatts: _selectedCandidate.ftpWatts,
      riderMassKg: _selectedCandidate.massKg,
      category: _selectedCandidate.category,
      altitudeAcclimatizationBonus: _altitudeAcclimatizationBonus,
      velodromeOverride: _selectedFacility,
      bikeOverride: _currentBike,
    );
  }

  void _syncOptimalTargetLapTime() {
    final proj = _preAttemptProjection;
    final speedMs = math.max(10.0, proj.predictedSpeedKmh / 3.6);
    final idealLap = _standardLapLengthMeters / speedMs;
    _targetLapTimeSeconds = (idealLap - 0.04).clamp(14.00, 19.50);
  }

  double _plannedLapTimeAtProgress(double progress) {
    final base = _targetLapTimeSeconds;
    if (_strategy == HourRecordPacingStrategy.evenPace) {
      return base;
    }
    // Negative Split: pierwsze 20 min wolniej, środek na celu, finał szybciej.
    final spread = _negativeSplitSpreadSeconds;
    if (progress < 0.333) {
      final t = progress / 0.333;
      return base + spread * (1.0 - t * 0.6);
    }
    if (progress < 0.72) {
      final t = (progress - 0.333) / (0.72 - 0.333);
      return base + (spread * 0.4) * (1.0 - t);
    }
    final t = (progress - 0.72) / 0.28;
    return base - spread * 0.85 * t;
  }

  void _startAttempt() {
    _ticker.stop();
    setState(() {
      _phase = HourRecordAttemptPhase.running;
      _elapsedSeconds = 0.0;
      _distanceMeters = 0.0;
      _currentLapNumber = 1;
      _lapStartTimeSeconds = 0.0;
      _lapStartDistanceMeters = 0.0;
      _lastLapTimeSeconds = 0.0;
      _sumPowerSamples = 0.0;
      _sumCadenceSamples = 0.0;
      _sampleCount = 0;
      _lapFlashIntensity = 0.0;
      _remainingWPrimeJoules = _selectedCandidate.wPrimeJoules;
      _recentLaps.clear();
      _finalProtocol = null;
      _lastTickElapsed = null;

      final firstTarget = _plannedLapTimeAtProgress(0.0);
      _currentSpeedMs = (_standardLapLengthMeters / firstTarget) * 0.78;
      _currentCadenceRpm =
          _currentBike.cadenceRpmFromSpeedKmh(_currentSpeedMs * 3.6);
      _currentPowerWatts = _effectiveFtpWatts * 0.96;
      _currentGForce = 1.0;
    });
    _ticker.start();
  }

  void _togglePause() {
    if (_phase == HourRecordAttemptPhase.running) {
      _ticker.stop();
      setState(() {
        _phase = HourRecordAttemptPhase.paused;
        _lastTickElapsed = null;
      });
    } else if (_phase == HourRecordAttemptPhase.paused) {
      setState(() {
        _phase = HourRecordAttemptPhase.running;
        _lastTickElapsed = null;
      });
      _ticker.start();
    }
  }

  void _resetToSetup() {
    _ticker.stop();
    setState(() {
      _phase = HourRecordAttemptPhase.setup;
      _elapsedSeconds = 0.0;
      _distanceMeters = 0.0;
      _recentLaps.clear();
      _finalProtocol = null;
      _lastTickElapsed = null;
    });
  }

  void _fastForwardNearFinish() {
    if (_phase != HourRecordAttemptPhase.running &&
        _phase != HourRecordAttemptPhase.paused) {
      return;
    }
    while (_elapsedSeconds < 3570.0 && _phase != HourRecordAttemptPhase.completed) {
      _advanceSimulationStep(2.0);
    }
    setState(() {});
  }

  void _onTick(Duration elapsed) {
    if (_phase != HourRecordAttemptPhase.running) return;
    final Duration prev = _lastTickElapsed ?? elapsed;
    _lastTickElapsed = elapsed;
    final double dtReal =
        ((elapsed - prev).inMicroseconds / 1000000.0).clamp(0.0, 0.05);
    if (dtReal <= 0) return;

    final double dtSimTotal = dtReal * _simulationSpeedMultiplier;
    const double maxSubStep = 0.5;
    double remaining = dtSimTotal;
    while (remaining > 0 && _phase == HourRecordAttemptPhase.running) {
      final double step = math.min(maxSubStep, remaining);
      _advanceSimulationStep(step);
      remaining -= step;
    }

    if (mounted) {
      setState(() {
        _lapFlashIntensity = (_lapFlashIntensity - dtReal * 2.2).clamp(0.0, 1.0);
      });
    }
  }

  void _advanceSimulationStep(double dt) {
    if (_elapsedSeconds >= _attemptDurationSeconds) {
      _completeAttempt();
      return;
    }

    final double stepDt =
        math.min(dt, _attemptDurationSeconds - _elapsedSeconds);
    final double progress = (_elapsedSeconds / _attemptDurationSeconds).clamp(0.0, 1.0);
    final double plannedLapTime = _plannedLapTimeAtProgress(progress);

    double desiredSpeedMs = _standardLapLengthMeters / plannedLapTime;
    if (_currentLapNumber == 1) {
      // Rozpędzanie ostrego koła ze startu zatrzymanego na pierwszych 250 m.
      final double lapFraction =
          ((_distanceMeters - _lapStartDistanceMeters) / _standardLapLengthMeters)
              .clamp(0.0, 1.0);
      desiredSpeedMs *= (0.72 + 0.28 * Curves.easeOut.transform(lapFraction));
    }

    final double disciplineNoise =
        (1.0 - (_selectedCandidate.lineDisciplineSkill / 100.0)) *
            (0.25 + 0.85 * math.pow(progress, 1.6));
    final double metersAboveBlackLine = disciplineNoise.clamp(0.0, 0.65);

    final VelodromeBankingPhysicsResult reqPhysics =
        VelodromeBankingAndCentripetalSolver.solveAverageLapPhysics(
      facility: _selectedFacility,
      bike: _currentBike,
      riderMassKg: _selectedCandidate.massKg,
      speedMs: desiredSpeedMs,
      metersAboveBlackLine: metersAboveBlackLine,
    );

    double actualSpeedMs = desiredSpeedMs;
    double actualPowerW = reqPhysics.requiredRiderPowerWatts;
    final double safeFtp = _effectiveFtpWatts;

    if (actualPowerW > safeFtp) {
      final double excess = actualPowerW - safeFtp;
      final double wCost = excess * stepDt;
      if (_remainingWPrimeJoules >= wCost) {
        _remainingWPrimeJoules -= wCost;
      } else {
        final double sustainablePower =
            safeFtp + (_remainingWPrimeJoules / math.max(0.5, stepDt));
        _remainingWPrimeJoules = 0.0;
        actualSpeedMs =
            VelodromeBankingAndCentripetalSolver.solveSteadySpeedFromPower(
          facility: _selectedFacility,
          bike: _currentBike,
          riderMassKg: _selectedCandidate.massKg,
          riderPowerWatts: sustainablePower,
          metersAboveBlackLine: metersAboveBlackLine,
        );
        actualPowerW = sustainablePower;
      }
    } else {
      final double dcp = safeFtp - actualPowerW;
      final double tauW = 546.0 * math.exp(-0.01 * dcp) + 316.0;
      _remainingWPrimeJoules = _selectedCandidate.wPrimeJoules -
          (_selectedCandidate.wPrimeJoules - _remainingWPrimeJoules) *
              math.exp(-stepDt / tauW);
    }

    final double effectiveLapLength =
        VelodromeBankingAndCentripetalSolver.computeEffectiveLapLengthMeters(
      metersAboveBlackLine,
    );
    final double blackLineScale = _standardLapLengthMeters / effectiveLapLength;
    final double lapProgressDistanceGain =
        actualSpeedMs * stepDt * blackLineScale;

    _elapsedSeconds += stepDt;
    _distanceMeters += lapProgressDistanceGain;
    _currentSpeedMs = actualSpeedMs;
    _currentPowerWatts = actualPowerW;
    _currentCadenceRpm = _currentBike.cadenceRpmFromSpeedKmh(actualSpeedMs * 3.6);
    _currentGForce = reqPhysics.gForceLoadFactor;
    _sumPowerSamples += actualPowerW;
    _sumCadenceSamples += _currentCadenceRpm;
    _sampleCount++;

    while (_distanceMeters - _lapStartDistanceMeters >= _standardLapLengthMeters) {
      final double lapEndDist = _lapStartDistanceMeters + _standardLapLengthMeters;
      final double overshootDist = _distanceMeters - lapEndDist;
      final double overshootTime =
          actualSpeedMs > 0 ? overshootDist / actualSpeedMs : 0.0;
      final double lapEndTime = _elapsedSeconds - overshootTime;
      final double lapDuration =
          math.max(10.0, lapEndTime - _lapStartTimeSeconds);

      _lastLapTimeSeconds = lapDuration;
      _lapFlashIntensity = 1.0;

      _recentLaps.insert(
        0,
        HourRecordLiveLapSplit(
          lapNumber: _currentLapNumber,
          lapTimeSeconds: lapDuration,
          targetLapTimeSeconds: plannedLapTime,
          cumulativeTimeSeconds: lapEndTime,
          cumulativeDistanceMeters: lapEndDist,
          speedKmh: actualSpeedMs * 3.6,
          powerWatts: actualPowerW,
        ),
      );
      if (_recentLaps.length > 8) {
        _recentLaps.removeLast();
      }

      _currentLapNumber++;
      _lapStartDistanceMeters = lapEndDist;
      _lapStartTimeSeconds = lapEndTime;
    }

    if (_elapsedSeconds >= _attemptDurationSeconds) {
      _completeAttempt();
    }
  }

  void _completeAttempt() {
    _ticker.stop();
    final double finalKm = _distanceMeters / 1000.0;
    final UciHourRecordEntry record = _recordToBeat;
    final double deltaMeters = (finalKm - record.distanceKm) * 1000.0;
    final bool isNewWr = deltaMeters > 0.0;
    final double completedLaps = _distanceMeters / _standardLapLengthMeters;
    final double avgPower =
        _sampleCount > 0 ? _sumPowerSamples / _sampleCount : _currentPowerWatts;
    final double avgCadence =
        _sampleCount > 0 ? _sumCadenceSamples / _sampleCount : _currentCadenceRpm;
    final double avgLap = completedLaps > 0 ? 3600.0 / completedLaps : 0.0;

    final String serial =
        'UCI-HR-${_selectedFacility.countryCode}-${_chainringTeeth}x$_cogTeeth-'
        '${(finalKm * 1000).round()}';

    setState(() {
      _elapsedSeconds = _attemptDurationSeconds;
      _phase = HourRecordAttemptPhase.completed;
      _lastTickElapsed = null;
      _finalProtocol = HourRecordFinalProtocol(
        candidate: _selectedCandidate,
        facility: _selectedFacility,
        bike: _currentBike,
        strategy: _strategy,
        finalDistanceKm: finalKm,
        completedLaps: completedLaps,
        averageSpeedKmh: finalKm,
        averagePowerWatts: avgPower,
        averageCadenceRpm: avgCadence,
        averageLapTimeSeconds: avgLap,
        worldRecordToBeatKm: record.distanceKm,
        deltaToWorldRecordMeters: deltaMeters,
        isNewWorldRecord: isNewWr,
        certificateSerial: serial,
        completedAt: DateTime.now(),
      );
    });
  }

  String _formatAttemptClock(double seconds) {
    final double clamped = seconds.clamp(0.0, _attemptDurationSeconds);
    final int totalCentiseconds = (clamped * 100).round();
    final int mins = totalCentiseconds ~/ 6000;
    final int secs = (totalCentiseconds % 6000) ~/ 100;
    final int cs = totalCentiseconds % 100;
    return '${mins.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}.'
        '${cs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 760;
            final bool isTablet =
                constraints.maxWidth >= 760 && constraints.maxWidth < 1180;

            return Column(
              children: [
                _buildTopBar(isMobile: isMobile),
                Expanded(
                  child: _phase == HourRecordAttemptPhase.completed &&
                          _finalProtocol != null
                      ? _buildCompletedCertificateView(
                          protocol: _finalProtocol!,
                          isMobile: isMobile,
                        )
                      : _phase == HourRecordAttemptPhase.setup
                          ? _buildSetupLayout(
                              isMobile: isMobile,
                              isTablet: isTablet,
                            )
                          : _buildLiveVelodromeLayout(
                              isMobile: isMobile,
                              isTablet: isTablet,
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar({required bool isMobile}) {
    final record = _recordToBeat;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          if (widget.onBack != null) ...[
            _InteractiveActionButton(
              label: isMobile ? '' : 'Powrót',
              icon: Icons.arrow_back_rounded,
              onPressed: widget.onBack,
            ),
            const SizedBox(width: 10),
          ],
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.45),
              ),
            ),
            child: const Icon(
              Icons.timer_outlined,
              color: AppColors.goldAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Próba Bicia Rekordu Godzinnego UCI',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isMobile ? 15 : 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Cel WR (${record.category.displayNamePl}): '
                  '${record.distanceKm.toStringAsFixed(3)} km • ${record.riderName}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 12),
            _StatusPill(
              label: _phase == HourRecordAttemptPhase.setup
                  ? 'HOMOLOGACJA SPRZĘTU'
                  : _phase == HourRecordAttemptPhase.running
                      ? 'PRÓBA NA ŻYWO'
                      : _phase == HourRecordAttemptPhase.paused
                          ? 'WSTRZYMANA'
                          : 'ZAKOŃCZONA',
              accentColor: _phase == HourRecordAttemptPhase.running
                  ? AppColors.statusSuccess
                  : _phase == HourRecordAttemptPhase.completed
                      ? AppColors.goldAccent
                      : AppColors.accentBlue,
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. WIDOK KONFIGURACJI PRZED PRÓBĄ
  // ===========================================================================

  Widget _buildSetupLayout({
    required bool isMobile,
    required bool isTablet,
  }) {
    final projection = _preAttemptProjection;
    final velodromePanel = _buildVelodromeSelectionCard();
    final bikeAndPacingPanel = _buildGearingAndStrategyCard();
    final preview3dAndForecast = _buildPreAttemptForecastCard(projection);

    if (isMobile) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildCandidateSelectorCard(),
            const SizedBox(height: 12),
            velodromePanel,
            const SizedBox(height: 12),
            bikeAndPacingPanel,
            const SizedBox(height: 12),
            preview3dAndForecast,
          ],
        ),
      );
    }

    if (isTablet) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCandidateSelectorCard(),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: velodromePanel),
                const SizedBox(width: 14),
                Expanded(child: bikeAndPacingPanel),
              ],
            ),
            const SizedBox(height: 14),
            preview3dAndForecast,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCandidateSelectorCard(),
                  const SizedBox(height: 14),
                  velodromePanel,
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: SingleChildScrollView(child: bikeAndPacingPanel),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: SingleChildScrollView(child: preview3dAndForecast),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateSelectorCard() {
    return _SectionCard(
      title: 'Kolarz i Kategoria UCI',
      icon: Icons.person_outline_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _candidates.map((cand) {
          final bool selected = cand.id == _selectedCandidate.id;
          return _InteractiveChoiceChip(
            title: cand.fullName,
            subtitle:
                '${cand.nationalityCode} • FTP ${cand.ftpWatts.toStringAsFixed(0)} W • '
                '${cand.massKg.toStringAsFixed(1)} kg',
            isSelected: selected,
            onTap: () {
              setState(() {
                _selectedCandidate = cand;
                _remainingWPrimeJoules = cand.wPrimeJoules;
                _syncOptimalTargetLapTime();
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVelodromeSelectionCard() {
    const facilities = VelodromeTrackAndHourRecordModel.defaultVelodromes;
    final double rho = _selectedFacility.airDensityKgPerM3;
    final double aeroSaving = _selectedFacility.aeroDragReductionPercentVsSeaLevel;
    final double hypoxiaDrop = (1.0 - _effectiveHypoxiaFactor) * 100.0;

    return _SectionCard(
      title: 'Wybór Welodromu (Nizinny vs Meksyk)',
      icon: Icons.stadium_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...facilities.map((fac) {
            final bool isSelected = fac.id == _selectedFacility.id;
            final bool isHighAltitude =
                fac.altitudeTier == VelodromeAltitudeTier.highAltitude;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _VelodromeFacilityTile(
                facility: fac,
                isSelected: isSelected,
                isHighAltitudeMexico: isHighAltitude,
                onTap: () {
                  setState(() {
                    _selectedFacility = fac;
                    _syncOptimalTargetLapTime();
                  });
                },
              ),
            );
          }),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
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
                    Expanded(
                      child: _MetricMiniTile(
                        label: 'Gęstość powietrza ρ',
                        value: '${rho.toStringAsFixed(3)} kg/m³',
                        valueColor: AppColors.cyanAccent,
                      ),
                    ),
                    Expanded(
                      child: _MetricMiniTile(
                        label: 'Zysk aero vs 0 m',
                        value: '+${aeroSaving.toStringAsFixed(1)}%',
                        valueColor: AppColors.statusSuccess,
                      ),
                    ),
                    Expanded(
                      child: _MetricMiniTile(
                        label: 'Strata hipoksji',
                        value: '-${hypoxiaDrop.toStringAsFixed(1)}%',
                        valueColor: hypoxiaDrop > 3.0
                            ? AppColors.amberWarning
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (_selectedFacility.altitudeMeters > 600.0) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Aklimatyzacja wysokogórska (obóz)',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(_altitudeAcclimatizationBonus * 100).toStringAsFixed(0)}%',
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
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.goldAccent,
                      inactiveTrackColor: AppColors.background,
                      thumbColor: AppColors.goldAccent,
                    ),
                    child: Slider(
                      value: _altitudeAcclimatizationBonus,
                      min: 0.0,
                      max: 0.70,
                      divisions: 7,
                      onChanged: (val) {
                        setState(() {
                          _altitudeAcclimatizationBonus = val;
                          _syncOptimalTargetLapTime();
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGearingAndStrategyCard() {
    final bike = _currentBike;
    final double targetSpeedKmh = (250.0 / _targetLapTimeSeconds) * 3.6;
    final double expectedRpm = bike.cadenceRpmFromSpeedKmh(targetSpeedKmh);
    final bool cadenceOptimal = expectedRpm >= 94.0 && expectedRpm <= 110.0;

    return _SectionCard(
      title: 'Napęd Ostrego Koła i Strategia Tempa',
      icon: Icons.settings_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Przełożenie ostrego koła (bez hamulców)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  bike.gearingLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Szybkie presety torowe:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: const [
              (60, 14),
              (61, 14),
              (62, 14),
              (64, 14),
              (62, 13),
            ].map((pair) {
              final bool active =
                  _chainringTeeth == pair.$1 && _cogTeeth == pair.$2;
              return _InteractiveActionButton(
                label: '${pair.$1}x${pair.$2}',
                isActive: active,
                onPressed: () {
                  setState(() {
                    _chainringTeeth = pair.$1;
                    _cogTeeth = pair.$2;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tarcza korby (58T–64T)',
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
            children: List.generate(7, (idx) => 58 + idx).map((teeth) {
              return _InteractiveActionButton(
                label: '${teeth}T',
                isActive: _chainringTeeth == teeth,
                onPressed: () => setState(() => _chainringTeeth = teeth),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          const Text(
            'Zębatka tylna (13T–15T)',
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
            children: const [13, 14, 15].map((teeth) {
              return _InteractiveActionButton(
                label: '${teeth}T',
                isActive: _cogTeeth == teeth,
                onPressed: () => setState(() => _cogTeeth = teeth),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MetricMiniTile(
                    label: 'Rozwinięcie',
                    value: '${bike.developmentMeters.toStringAsFixed(2)} m',
                  ),
                ),
                Expanded(
                  child: _MetricMiniTile(
                    label: 'Gear Inches',
                    value: '${bike.gearInches.toStringAsFixed(1)}"',
                  ),
                ),
                Expanded(
                  child: _MetricMiniTile(
                    label: 'Kadencja @ cel',
                    value: '${expectedRpm.toStringAsFixed(1)} RPM',
                    valueColor: cadenceOptimal
                        ? AppColors.statusSuccess
                        : AppColors.amberWarning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 14),
          const Text(
            'Strategia Tempa na 60:00.00',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: HourRecordPacingStrategy.values.map((strat) {
              final bool selected = _strategy == strat;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: strat == HourRecordPacingStrategy.evenPace ? 8 : 0,
                  ),
                  child: _InteractiveChoiceChip(
                    title: strat.labelPl,
                    subtitle: strat.descriptionPl,
                    isSelected: selected,
                    onTap: () => setState(() => _strategy = strat),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Docelowy czas okrążenia (250 m)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_targetLapTimeSeconds.toStringAsFixed(2)} s '
                '(${targetSpeedKmh.toStringAsFixed(2)} km/h)',
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
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.cyanAccent,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.cyanAccent,
            ),
            child: Slider(
              value: _targetLapTimeSeconds.clamp(14.00, 19.50),
              min: 14.00,
              max: 19.50,
              divisions: 110,
              onChanged: (val) => setState(() => _targetLapTimeSeconds = val),
            ),
          ),
          if (_strategy == HourRecordPacingStrategy.negativeSplit) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Progresja Negative Split',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '±${_negativeSplitSpreadSeconds.toStringAsFixed(2)} s/okr.',
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
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.goldAccent,
                inactiveTrackColor: AppColors.surfaceLight,
                thumbColor: AppColors.goldAccent,
              ),
              child: Slider(
                value: _negativeSplitSpreadSeconds,
                min: 0.10,
                max: 0.45,
                divisions: 7,
                onChanged: (val) =>
                    setState(() => _negativeSplitSpreadSeconds = val),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreAttemptForecastCard(HourRecordAttemptSimulation projection) {
    final bool beatsWr = projection.beatsCurrentRecord;
    final double plannedSpeedKmh = (250.0 / _targetLapTimeSeconds) * 3.6;
    final double plannedDistanceKm = plannedSpeedKmh;
    final double deltaPlannedMeters =
        (plannedDistanceKm - _recordToBeat.distanceKm) * 1000.0;
    final double reqWattsForTarget =
        VelodromeTrackAndHourRecordModel.standard(
      initialVelodromeId: _selectedFacility.id,
      customBike: _currentBike,
    ).requiredPowerWattsForSpeedKmh(
      speedKmh: plannedSpeedKmh,
      riderMassKg: _selectedCandidate.massKg,
      velodromeOverride: _selectedFacility,
      bikeOverride: _currentBike,
    );
    final bool powerSustainable = reqWattsForTarget <= _effectiveFtpWatts * 1.02;

    return _SectionCard(
      title: 'Podgląd 3D i Prognoza Rekordu',
      icon: Icons.analytics_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 210,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: VelodromeWoodenBowl3dPainter(
                  renderer: VelodromeWoodenBowl3dRenderer(
                    config: VelodromeWoodenBowlConfig(
                      facility: _selectedFacility,
                      cameraMode: VelodromeCameraMode.broadcastBowl,
                      virtualRecordSpeedKmh: _recordToBeat.averageSpeedKmh,
                    ),
                  ),
                  timeSeconds: 4.5,
                  heroRider: VelodromeTrackRider3D(
                    riderId: _selectedCandidate.id,
                    shortName: _selectedCandidate.fullName,
                    jerseyColor: AppColors.primaryAccent,
                    helmetColor: AppColors.goldAccent,
                    bikeFrameColor: AppColors.accentBlue,
                    distanceMeters: 62.0,
                    speedKmh: plannedSpeedKmh,
                    cadenceRpm:
                        _currentBike.cadenceRpmFromSpeedKmh(plannedSpeedKmh),
                    powerWatts: reqWattsForTarget,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: beatsWr
                    ? AppColors.statusSuccess.withValues(alpha: 0.45)
                    : AppColors.cardBorder,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricMiniTile(
                        label: 'Potencjał kolarza (60m)',
                        value:
                            '${projection.predictedDistanceKm.toStringAsFixed(3)} km',
                        valueColor: beatsWr
                            ? AppColors.statusSuccess
                            : AppColors.amberWarning,
                      ),
                    ),
                    Expanded(
                      child: _MetricMiniTile(
                        label: 'Efektywne FTP',
                        value: '${_effectiveFtpWatts.toStringAsFixed(0)} W',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MetricMiniTile(
                        label: 'Dystans z planu tempa',
                        value: '${plannedDistanceKm.toStringAsFixed(3)} km',
                        valueColor: deltaPlannedMeters >= 0
                            ? AppColors.goldAccent
                            : AppColors.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: _MetricMiniTile(
                        label: 'Moc dla tempa',
                        value: '${reqWattsForTarget.toStringAsFixed(0)} W',
                        valueColor: powerSustainable
                            ? AppColors.statusSuccess
                            : AppColors.crimsonAlert,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (!powerSustainable)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.crimsonAlert.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.crimsonAlert.withValues(alpha: 0.45),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.crimsonAlert,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Uwaga: docelowe tempo przekracza efektywne FTP na tej wysokości — ryzyko wyczerpania W\' przed 60:00.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          _InteractiveActionButton(
            label: 'Rozpocznij Oficjalną Próbę 60:00.00',
            icon: Icons.play_arrow_rounded,
            isPrimaryCta: true,
            isActive: true,
            onPressed: _startAttempt,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. WIDOK NA ŻYWO: 3D WELODROM + METRONOM + TELEMETRIA
  // ===========================================================================

  Widget _buildLiveVelodromeLayout({
    required bool isMobile,
    required bool isTablet,
  }) {
    final viewport3d = _buildLive3dViewportCard(isMobile: isMobile);
    final metronomeCard = _buildLapMetronomeCard();
    final telemetryCard = _buildLiveTelemetryCard();

    if (isMobile) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SizedBox(height: 290, child: viewport3d),
            const SizedBox(height: 12),
            metronomeCard,
            const SizedBox(height: 12),
            telemetryCard,
          ],
        ),
      );
    }

    if (isTablet) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Expanded(flex: 5, child: viewport3d),
            const SizedBox(height: 12),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Expanded(child: SingleChildScrollView(child: metronomeCard)),
                  const SizedBox(width: 12),
                  Expanded(child: SingleChildScrollView(child: telemetryCard)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 7, child: viewport3d),
          const SizedBox(width: 16),
          SizedBox(
            width: 390,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  metronomeCard,
                  const SizedBox(height: 14),
                  telemetryCard,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLive3dViewportCard({required bool isMobile}) {
    final UciHourRecordEntry wr = _recordToBeat;
    final double wrSpeedMs = wr.averageSpeedKmh / 3.6;
    final double wrDistanceMeters = wrSpeedMs * _elapsedSeconds;
    final double deltaToWrMeters = _distanceMeters - wrDistanceMeters;
    final bool aheadOfWr = deltaToWrMeters >= 0;

    final renderer = VelodromeWoodenBowl3dRenderer(
      config: VelodromeWoodenBowlConfig(
        facility: _selectedFacility,
        cameraMode: _cameraMode,
        virtualRecordSpeedKmh: wr.averageSpeedKmh,
        showVirtualRecordLaser: _showVirtualRecordLaser,
        showRoofAndSpotlights: true,
        showInfieldScoreboard: true,
        showTelemetryOverlay: false,
      ),
    );

    final hero = VelodromeTrackRider3D(
      riderId: _selectedCandidate.id,
      shortName: _selectedCandidate.fullName,
      jerseyColor: AppColors.primaryAccent,
      helmetColor: AppColors.goldAccent,
      bikeFrameColor: AppColors.accentBlue,
      distanceMeters: _distanceMeters,
      metersAboveBlackLine: 0.05,
      speedKmh: _currentSpeedMs * 3.6,
      cadenceRpm: _currentCadenceRpm,
      powerWatts: _currentPowerWatts,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _cameraYawOffset += details.delta.dx * 0.008;
              });
            },
            child: CustomPaint(
              painter: VelodromeWoodenBowl3dPainter(
                renderer: renderer,
                timeSeconds: _elapsedSeconds,
                heroRider: hero,
                cameraYawOffsetRadians: _cameraYawOffset,
                onTelemetryUpdated: (tel) {
                  _latest3dTelemetry = tel;
                },
              ),
            ),
          ),
          // Zegar oficjalny 60:00.00 + delta WR w lewym górnym rogu
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: aheadOfWr
                      ? AppColors.statusSuccess.withValues(alpha: 0.65)
                      : AppColors.goldAccent.withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatAttemptClock(_elapsedSeconds),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isMobile ? 20 : 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(_distanceMeters / 1000.0).toStringAsFixed(3)} km • '
                    'Okr. $_currentLapNumber • '
                    'WR: ${aheadOfWr ? '+' : ''}${deltaToWrMeters.toStringAsFixed(1)} m',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: aheadOfWr
                          ? AppColors.statusSuccess
                          : AppColors.amberWarning,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Błysk przejazdu przez linię pomiarową
          if (_lapFlashIntensity > 0.05)
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.cyanAccent
                        .withValues(alpha: _lapFlashIntensity * 0.65),
                    width: 3.0,
                  ),
                ),
              ),
            ),
          // Dolny pasek kamer 3D i tempa symulacji
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: VelodromeCameraMode.values.map((mode) {
                    return _InteractiveActionButton(
                      label: mode.shortTag,
                      isActive: _cameraMode == mode,
                      onPressed: () => setState(() => _cameraMode = mode),
                    );
                  }).toList(),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _InteractiveActionButton(
                      label: 'Laser WR',
                      isActive: _showVirtualRecordLaser,
                      onPressed: () => setState(() =>
                          _showVirtualRecordLaser = !_showVirtualRecordLaser),
                    ),
                    ...[1.0, 10.0, 60.0, 240.0].map((mult) {
                      return _InteractiveActionButton(
                        label: '${mult.toInt()}x',
                        isActive: _simulationSpeedMultiplier == mult,
                        onPressed: () =>
                            setState(() => _simulationSpeedMultiplier = mult),
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

  Widget _buildLapMetronomeCard() {
    final double progress = (_elapsedSeconds / _attemptDurationSeconds).clamp(0.0, 1.0);
    final double currentTargetLap = _plannedLapTimeAtProgress(progress);
    final double lapProgressRatio =
        ((_distanceMeters - _lapStartDistanceMeters) / _standardLapLengthMeters)
            .clamp(0.0, 1.0);
    final double currentLapElapsed = _elapsedSeconds - _lapStartTimeSeconds;

    return _SectionCard(
      title: 'Metronom Czasu Okrążenia (250 m)',
      icon: Icons.av_timer_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MetronomePulseGauge(
                lapProgress: lapProgressRatio,
                flashIntensity: _lapFlashIntensity,
                lapTimeSeconds: currentLapElapsed,
                targetSeconds: currentTargetLap,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetricMiniTile(
                      label: 'Cel okrążenia (${_strategy.labelPl})',
                      value: '${currentTargetLap.toStringAsFixed(2)} s',
                      valueColor: AppColors.cyanAccent,
                    ),
                    const SizedBox(height: 8),
                    _MetricMiniTile(
                      label: 'Ostatnie okrążenie',
                      value: _lastLapTimeSeconds > 0
                          ? '${_lastLapTimeSeconds.toStringAsFixed(2)} s'
                          : 'Start zatrzymany...',
                      valueColor: _lastLapTimeSeconds > 0 &&
                              (_lastLapTimeSeconds - currentTargetLap).abs() <=
                                  0.15
                          ? AppColors.statusSuccess
                          : AppColors.textPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentLaps.isNotEmpty) ...[
            const Text(
              'Ostatnie międzyczasy okrążeń:',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _recentLaps.take(6).map((lap) {
                final Color badgeColor = lap.isOnPace
                    ? AppColors.statusSuccess
                    : lap.deltaSeconds.abs() <= 0.30
                        ? AppColors.amberWarning
                        : AppColors.crimsonAlert;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    '#${lap.lapNumber}: ${lap.lapTimeSeconds.toStringAsFixed(2)}s',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InteractiveActionButton(
                label: _phase == HourRecordAttemptPhase.running
                    ? 'Pauza'
                    : 'Wznów',
                icon: _phase == HourRecordAttemptPhase.running
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                isActive: _phase == HourRecordAttemptPhase.running,
                onPressed: _togglePause,
              ),
              _InteractiveActionButton(
                label: 'Finał 59:30',
                icon: Icons.fast_forward_rounded,
                onPressed: _fastForwardNearFinish,
              ),
              _InteractiveActionButton(
                label: 'Przerwij',
                icon: Icons.stop_rounded,
                onPressed: _resetToSetup,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTelemetryCard() {
    final double wPrimePct =
        (_remainingWPrimeJoules / math.max(1.0, _selectedCandidate.wPrimeJoules))
            .clamp(0.0, 1.0);
    final double bankingDeg = _latest3dTelemetry?.localBankingDegrees ??
        _selectedFacility.turnBankingDegrees;

    return _SectionCard(
      title: 'Telemetria Torowa na Żywo',
      icon: Icons.speed_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricMiniTile(
                  label: 'Prędkość',
                  value: '${(_currentSpeedMs * 3.6).toStringAsFixed(2)} km/h',
                  valueColor: AppColors.cyanAccent,
                ),
              ),
              Expanded(
                child: _MetricMiniTile(
                  label: 'Moc chwilowa',
                  value: '${_currentPowerWatts.toStringAsFixed(0)} W',
                  valueColor: AppColors.goldAccent,
                ),
              ),
              Expanded(
                child: _MetricMiniTile(
                  label: 'Kadencja (${_currentBike.gearingLabel})',
                  value: '${_currentCadenceRpm.toStringAsFixed(1)} RPM',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricMiniTile(
                  label: 'Wiraż / Przeciążenie',
                  value:
                      '${bankingDeg.toStringAsFixed(1)}° • ${_currentGForce.toStringAsFixed(2)}G',
                ),
              ),
              Expanded(
                child: _MetricMiniTile(
                  label: 'Welodrom',
                  value:
                      '${_selectedFacility.city} (${_selectedFacility.altitudeMeters.toStringAsFixed(0)} m)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bateria beztlenowa W\'',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${(wPrimePct * 100).toStringAsFixed(0)}%',
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
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: wPrimePct,
              minHeight: 8,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                wPrimePct > 0.35
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. CERTYFIKAT NOWEGO REKORDU ŚWIATA PO 60:00.00
  // ===========================================================================

  Widget _buildCompletedCertificateView({
    required HourRecordFinalProtocol protocol,
    required bool isMobile,
  }) {
    final bool isWr = protocol.isNewWorldRecord;
    final Color accent = isWr ? AppColors.goldAccent : AppColors.accentBlue;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent,
                width: isWr ? 2.0 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CustomPaint(
                    painter: _UciHomologationSealPainter(isWorldRecord: isWr),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isWr
                      ? 'CERTYFIKAT NOWEGO REKORDU ŚWIATA UCI'
                      : 'OFICJALNY PROTOKÓŁ PRÓBY GODZINNEJ UCI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isMobile ? 18 : 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Czas próby: 60:00.00 • Homologacja ${protocol.certificateSerial}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Text(
                        protocol.candidate.fullName,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${protocol.finalDistanceKm.toStringAsFixed(3)} km',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isMobile ? 34 : 44,
                          fontWeight: FontWeight.w900,
                          color: isWr
                              ? AppColors.goldAccent
                              : AppColors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${protocol.completedLaps.toStringAsFixed(3)} okrążeń (250 m) • '
                        '${isWr ? '+' : ''}${protocol.deltaToWorldRecordMeters.toStringAsFixed(1)} m vs WR '
                        '(${protocol.worldRecordToBeatKm.toStringAsFixed(3)} km)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isWr
                              ? AppColors.statusSuccess
                              : AppColors.amberWarning,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _CertificateStatBox(
                      label: 'Welodrom',
                      value:
                          '${protocol.facility.name} (${protocol.facility.altitudeMeters.toStringAsFixed(0)} m)',
                    ),
                    _CertificateStatBox(
                      label: 'Przełożenie Ostrego Koła',
                      value:
                          '${protocol.bike.gearingLabel} (${protocol.averageCadenceRpm.toStringAsFixed(1)} RPM)',
                    ),
                    _CertificateStatBox(
                      label: 'Strategia Tempa',
                      value: protocol.strategy.labelPl,
                    ),
                    _CertificateStatBox(
                      label: 'Średnia Moc / Okrążenie',
                      value:
                          '${protocol.averagePowerWatts.toStringAsFixed(0)} W • ${protocol.averageLapTimeSeconds.toStringAsFixed(2)} s',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _InteractiveActionButton(
                      label: 'Nowa Próba / Zmień Setup',
                      icon: Icons.tune_rounded,
                      isActive: true,
                      isPrimaryCta: true,
                      onPressed: _resetToSetup,
                    ),
                    _InteractiveActionButton(
                      label: 'Powtórz z tym samym setupem',
                      icon: Icons.replay_rounded,
                      onPressed: _startAttempt,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// POMOCNICZE WIDŻETY UI (KARTY, PRZYCISKI HOVER/FOCUS/ACTIVE/DISABLED, METRONOM)
// =============================================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
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
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.goldAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
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

class _StatusPill extends StatelessWidget {
  final String label;
  final Color accentColor;

  const _StatusPill({
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accentColor.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: accentColor,
        ),
      ),
    );
  }
}

class _MetricMiniTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricMiniTile({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _CertificateStatBox extends StatelessWidget {
  final String label;
  final String value;

  const _CertificateStatBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 380),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: _MetricMiniTile(label: label, value: value),
    );
  }
}

class _VelodromeFacilityTile extends StatefulWidget {
  final VelodromeFacilitySpec facility;
  final bool isSelected;
  final bool isHighAltitudeMexico;
  final VoidCallback onTap;

  const _VelodromeFacilityTile({
    required this.facility,
    required this.isSelected,
    required this.isHighAltitudeMexico,
    required this.onTap,
  });

  @override
  State<_VelodromeFacilityTile> createState() => _VelodromeFacilityTileState();
}

class _VelodromeFacilityTileState extends State<_VelodromeFacilityTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _focused
        ? AppColors.goldAccent
        : widget.isSelected
            ? AppColors.goldAccent
            : _hovered
                ? AppColors.textSecondary.withValues(alpha: 0.45)
                : AppColors.cardBorder;
    final Color bgColor = _pressed
        ? AppColors.surfaceLight
        : widget.isSelected
            ? AppColors.primaryAccent.withValues(alpha: 0.22)
            : _hovered
                ? AppColors.surfaceLight.withValues(alpha: 0.65)
                : AppColors.background.withValues(alpha: 0.5);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _focused || widget.isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.facility.name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.facility.city} (${widget.facility.countryCode}) • '
                      '${widget.facility.altitudeMeters.toStringAsFixed(0)} m n.p.m. • '
                      'Wiraże ${widget.facility.turnBankingDegrees.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(
                label: widget.isHighAltitudeMexico ? 'MEKSYK • WYSOKO' : 'NIZINNY',
                accentColor: widget.isHighAltitudeMexico
                    ? AppColors.goldAccent
                    : AppColors.accentBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveChoiceChip extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback? onTap;

  const _InteractiveChoiceChip({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<_InteractiveChoiceChip> createState() => _InteractiveChoiceChipState();
}

class _InteractiveChoiceChipState extends State<_InteractiveChoiceChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null;
    final Color bg = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : _pressed
            ? AppColors.surfaceLight
            : widget.isSelected
                ? AppColors.primaryAccent.withValues(alpha: 0.25)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background.withValues(alpha: 0.55);
    final Color border = _focused || widget.isSelected
        ? AppColors.goldAccent
        : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: border,
              width: _focused || widget.isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
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
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final bool isPrimaryCta;
  final VoidCallback? onPressed;

  const _InteractiveActionButton({
    required this.label,
    this.icon,
    this.isActive = false,
    this.isPrimaryCta = false,
    this.onPressed,
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
    final bool enabled = widget.onPressed != null;
    final Color bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.isPrimaryCta
            ? (_pressed
                ? AppColors.primaryAccent.withValues(alpha: 0.85)
                : _hovered
                    ? AppColors.goldAccent.withValues(alpha: 0.90)
                    : AppColors.primaryAccent)
            : widget.isActive
                ? AppColors.primaryAccent
                : _pressed
                    ? AppColors.surfaceLight
                    : _hovered
                        ? AppColors.surfaceLight.withValues(alpha: 0.85)
                        : AppColors.surface;
    final Color borderColor = _focused
        ? AppColors.goldAccent
        : widget.isActive || widget.isPrimaryCta
            ? AppColors.goldAccent
            : AppColors.cardBorder;
    final Color fgColor = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : widget.isPrimaryCta && _hovered
            ? AppColors.background
            : widget.isActive || widget.isPrimaryCta
                ? AppColors.textPrimary
                : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isPrimaryCta ? 16 : 10,
            vertical: widget.isPrimaryCta ? 12 : 7,
          ),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: widget.isPrimaryCta ? 18 : 14, color: fgColor),
                if (widget.label.isNotEmpty) const SizedBox(width: 6),
              ],
              if (widget.label.isNotEmpty)
                Flexible(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: widget.isPrimaryCta ? 13 : 11,
                      fontWeight: FontWeight.w700,
                      color: fgColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetronomePulseGauge extends StatelessWidget {
  final double lapProgress;
  final double flashIntensity;
  final double lapTimeSeconds;
  final double targetSeconds;

  const _MetronomePulseGauge({
    required this.lapProgress,
    required this.flashIntensity,
    required this.lapTimeSeconds,
    required this.targetSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: CustomPaint(
        painter: _MetronomeGaugePainter(
          lapProgress: lapProgress,
          flashIntensity: flashIntensity,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lapTimeSeconds.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '/ ${targetSeconds.toStringAsFixed(2)}s',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetronomeGaugePainter extends CustomPainter {
  final double lapProgress;
  final double flashIntensity;

  const _MetronomeGaugePainter({
    required this.lapProgress,
    required this.flashIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (math.min(size.width, size.height) / 2) - 6;

    final Paint bgPaint = Paint()
      ..color = AppColors.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0;
    canvas.drawCircle(center, radius, bgPaint);

    final Paint arcPaint = Paint()
      ..color = Color.lerp(
            AppColors.cyanAccent,
            AppColors.goldAccent,
            flashIntensity,
          ) ??
          AppColors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * lapProgress.clamp(0.0, 1.0),
      false,
      arcPaint,
    );

    if (flashIntensity > 0.05) {
      final Paint glowPaint = Paint()
        ..color = AppColors.goldAccent.withValues(alpha: flashIntensity * 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius - 8, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MetronomeGaugePainter oldDelegate) {
    return oldDelegate.lapProgress != lapProgress ||
        oldDelegate.flashIntensity != flashIntensity;
  }
}

class _UciHomologationSealPainter extends CustomPainter {
  final bool isWorldRecord;

  const _UciHomologationSealPainter({required this.isWorldRecord});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double r = math.min(size.width, size.height) / 2;

    final Color outerColor =
        isWorldRecord ? AppColors.goldAccent : AppColors.accentBlue;

    canvas.drawCircle(
      center,
      r - 2,
      Paint()
        ..color = outerColor.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      r - 2,
      Paint()
        ..color = outerColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Pięć tęczowych pasków UCI w środku pieczęci.
    const List<Color> uciBands = [
      Color(0xFF0072CE),
      Color(0xFFEF3340),
      Color(0xFF111827),
      Color(0xFFFFD100),
      Color(0xFF009639),
    ];
    final double bandWidth = (r * 1.15) / uciBands.length;
    final double startX = center.dx - (r * 1.15) / 2;
    for (int i = 0; i < uciBands.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          startX + i * bandWidth,
          center.dy - 14,
          bandWidth - 1,
          28,
        ),
        Paint()..color = uciBands[i],
      );
    }

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: isWorldRecord ? 'WR • UCI' : 'UCI',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: outerColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy + 18),
    );
  }

  @override
  bool shouldRepaint(covariant _UciHomologationSealPainter oldDelegate) {
    return oldDelegate.isWorldRecord != isWorldRecord;
  }
}
