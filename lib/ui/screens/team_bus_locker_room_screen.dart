import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/bike_manufacturer_deal.dart';
import '../../models/team/cycling_team.dart';
import '../../services/generators/rider_procedural_generator.dart';
import '../widgets/rider_avatar_painter.dart';

/// Mowa motywacyjna Dyrektora Sportowego wygłaszana w autobusie przed startem etapu.
enum DirectorSpeechOption {
  removePressure(
    title: 'Zdejmijcie presję',
    shortTag: 'Spokój i luz',
    speechQuote:
        '„Panowie, zero spiny na starcie. Jedźcie swoje, słuchajcie nóg i bawcie się wyścigiem — presja zostaje w autobusie.”',
    moraleDelta: 12,
    focusFirst20KmDelta: 6,
    accentColor: AppColors.accentBlue,
    icon: Icons.spa_rounded,
    effectSummary: '+12 Morale • +6 Koncentracja (0–20 km) • Chroni przed spadkiem morale przy słabej nodze',
  ),
  allInForLeader(
    title: 'Jedziemy dziś wszystko na naszego lidera!',
    shortTag: 'Pełna mobilizacja',
    speechQuote:
        '„Dziś cały zespół pracuje na jeden cel. Pierwsze 20 kilometrów trzymamy lidera z przodu, osłaniamy go od wiatru i nie oddajemy ani metra!”',
    moraleDelta: 10,
    focusFirst20KmDelta: 18,
    accentColor: AppColors.goldAccent,
    icon: Icons.shield_rounded,
    effectSummary: '+10 Morale • +18 Koncentracja (0–20 km) • Dodatkowy bonus +5 koncentracji dla Lidera',
  ),
  attackFromKmZero(
    title: 'Zaatakujcie od kilometra zero!',
    shortTag: 'Agresywny start',
    speechQuote:
        '„Od opuszczenia flagi dyrektora idzie ogień! Chcę widzieć nasze koszulki w pierwszym odjeździe — niech peleton od razu wie, kto tu rządzi!”',
    moraleDelta: 8,
    focusFirst20KmDelta: 22,
    accentColor: AppColors.primaryAccent,
    icon: Icons.flash_on_rounded,
    effectSummary: '+8 Morale • +22 Koncentracja (0–20 km) • Maksymalna gotowość do skoku od km 0',
  ),
  surviveTimeLimit(
    title: 'Przetrwajcie ten etap w limicie czasu',
    shortTag: 'Dyscyplina i ekonomia',
    speechQuote:
        '„To będzie brutalny dzień w siodle. Zero niepotrzebnych zrywów, jedziemy mądrze w grupetto, pijemy co 15 minut i meldujemy się w limicie.”',
    moraleDelta: 6,
    focusFirst20KmDelta: 14,
    accentColor: AppColors.statusSuccess,
    icon: Icons.hourglass_bottom_rounded,
    effectSummary: '+6 Morale • +14 Koncentracja (0–20 km) • Oszczędność nerwów i stabilne tempo otwarcia',
  );

  final String title;
  final String shortTag;
  final String speechQuote;
  final int moraleDelta;
  final int focusFirst20KmDelta;
  final Color accentColor;
  final IconData icon;
  final String effectSummary;

  const DirectorSpeechOption({
    required this.title,
    required this.shortTag,
    required this.speechQuote,
    required this.moraleDelta,
    required this.focusFirst20KmDelta,
    required this.accentColor,
    required this.icon,
    required this.effectSummary,
  });
}

/// Stan pojedynczego kolarza w autobusie drużyny przed startem etapu.
class TeamBusRiderSlot {
  final Rider rider;
  final int startNumber;
  final String seatCode;
  final String roleLabel;
  final bool isLeader;
  final int trueDayCondition; // -5 .. +5
  final bool isWarmedUp;
  final bool isWarmingUp;
  final double warmUpProgress;
  final double warmUpWatts;
  final int warmUpBpm;
  final int baseMorale;
  final int currentMorale;
  final int baseFocusFirst20Km;
  final int currentFocusFirst20Km;
  final int? lastMoraleDelta;
  final int? lastFocusDelta;

  const TeamBusRiderSlot({
    required this.rider,
    required this.startNumber,
    required this.seatCode,
    required this.roleLabel,
    required this.isLeader,
    required this.trueDayCondition,
    this.isWarmedUp = false,
    this.isWarmingUp = false,
    this.warmUpProgress = 0.0,
    this.warmUpWatts = 240.0,
    this.warmUpBpm = 128,
    required this.baseMorale,
    required this.currentMorale,
    required this.baseFocusFirst20Km,
    required this.currentFocusFirst20Km,
    this.lastMoraleDelta,
    this.lastFocusDelta,
  });

  TeamBusRiderSlot copyWith({
    Rider? rider,
    int? startNumber,
    String? seatCode,
    String? roleLabel,
    bool? isLeader,
    int? trueDayCondition,
    bool? isWarmedUp,
    bool? isWarmingUp,
    double? warmUpProgress,
    double? warmUpWatts,
    int? warmUpBpm,
    int? baseMorale,
    int? currentMorale,
    int? baseFocusFirst20Km,
    int? currentFocusFirst20Km,
    int? lastMoraleDelta,
    int? lastFocusDelta,
  }) {
    return TeamBusRiderSlot(
      rider: rider ?? this.rider,
      startNumber: startNumber ?? this.startNumber,
      seatCode: seatCode ?? this.seatCode,
      roleLabel: roleLabel ?? this.roleLabel,
      isLeader: isLeader ?? this.isLeader,
      trueDayCondition: trueDayCondition ?? this.trueDayCondition,
      isWarmedUp: isWarmedUp ?? this.isWarmedUp,
      isWarmingUp: isWarmingUp ?? this.isWarmingUp,
      warmUpProgress: warmUpProgress ?? this.warmUpProgress,
      warmUpWatts: warmUpWatts ?? this.warmUpWatts,
      warmUpBpm: warmUpBpm ?? this.warmUpBpm,
      baseMorale: baseMorale ?? this.baseMorale,
      currentMorale: currentMorale ?? this.currentMorale,
      baseFocusFirst20Km: baseFocusFirst20Km ?? this.baseFocusFirst20Km,
      currentFocusFirst20Km:
          currentFocusFirst20Km ?? this.currentFocusFirst20Km,
      lastMoraleDelta: lastMoraleDelta ?? this.lastMoraleDelta,
      lastFocusDelta: lastFocusDelta ?? this.lastFocusDelta,
    );
  }
}

/// Wynik odprawy w autobusie drużyny przekazywany po wygłoszeniu mowy i wyjściu na start.
class TeamBusBriefingResult {
  final DirectorSpeechOption? deliveredSpeech;
  final List<TeamBusRiderSlot> riderSlots;

  const TeamBusBriefingResult({
    required this.deliveredSpeech,
    required this.riderSlots,
  });
}

/// Klimatyczny ekran Wnętrza Autobusu Drużyny przed startem etapu (*W sercu peletonu*).
class TeamBusLockerRoomScreen extends StatefulWidget {
  final CyclingTeam? team;
  final RaceStage? stage;
  final List<Rider>? riders;
  final List<int>? presetDayConditions;
  final ValueChanged<TeamBusBriefingResult>? onSpeechDelivered;
  final ValueChanged<TeamBusBriefingResult>? onProceedToStart;
  final bool instantWarmUpForTesting;

  const TeamBusLockerRoomScreen({
    super.key,
    this.team,
    this.stage,
    this.riders,
    this.presetDayConditions,
    this.onSpeechDelivered,
    this.onProceedToStart,
    this.instantWarmUpForTesting = false,
  });

  @override
  State<TeamBusLockerRoomScreen> createState() =>
      _TeamBusLockerRoomScreenState();
}

class _TeamBusLockerRoomScreenState extends State<TeamBusLockerRoomScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;
  late CyclingTeam _team;
  late RaceStage _stage;
  late List<TeamBusRiderSlot> _slots;

  int _selectedIndex = 0;
  DirectorSpeechOption _selectedSpeech = DirectorSpeechOption.allInForLeader;
  DirectorSpeechOption? _deliveredSpeech;
  Timer? _warmUpTimer;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _team = widget.team ?? _buildDefaultTeam();
    _stage = widget.stage ?? _buildDefaultStage();
    _slots = _buildInitialRiderSlots();
  }

  @override
  void dispose() {
    _warmUpTimer?.cancel();
    _ambientController.dispose();
    super.dispose();
  }

  CyclingTeam _buildDefaultTeam() {
    return const CyclingTeam(
      id: 'team_pl_apex',
      name: 'Apex Pro Cycling',
      division: TeamDivision.worldTour,
      countryIso: 'POL',
      primaryJerseyColorHex: '#8E4A49',
      secondaryJerseyColorHex: '#181B22',
      accentJerseyColorHex: '#D4AF37',
      cashBalanceEur: 6400000,
      monthlyBurnRateEur: 420000,
      uciPointsSeason: 8420,
      rosterRiderIds: <String>[],
      staff: TeamStaff(
        trainersLevel: 84,
        sportsDirectorsLevel: 88,
        doctorsLevel: 82,
        mechanicsLevel: 86,
        scoutsLevel: 79,
      ),
      bikeDeal: BikeManufacturerDeal(
        manufacturerId: 'brand_aeroveloce',
        manufacturerName: 'AeroVeloce',
        prestigeLevel: 4,
        annualCashContributionEur: 900000,
        freeBikesQuota: 80,
        researchAndDevelopmentLevel: 85,
        suppliedFrameIds: ['frame_aero_pro', 'frame_climb_sl'],
        suppliedWheelsetIds: ['wheel_carbon_50', 'wheel_climb_32'],
        contractYearsLeft: 2,
        minimumUciRankingRequired: 18,
      ),
      sponsors: [],
      inventoryBikes: [],
    );
  }

  RaceStage _buildDefaultStage() {
    return const RaceStage(
      id: 'stage_tdf_14',
      stageNumber: 14,
      name: 'Pau — Saint-Lary-Soulan (Pla d\'Adet)',
      stageType: StageType.summitFinish,
      baseTemperatureCelsius: 24.5,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 14.0,
      segments: [
        StageSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 62.0,
          startElevationM: 210.0,
          endElevationM: 480.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 22.0,
          windDirectionDegrees: 35.0,
          roadBearingDegrees: 140.0,
          sprintOrKomClassification: SegmentClassification.intermediateSprint,
        ),
        StageSegment(
          index: 1,
          startKm: 62.0,
          lengthKm: 36.0,
          startElevationM: 480.0,
          endElevationM: 2115.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 64.0,
          windDirectionDegrees: 110.0,
          roadBearingDegrees: 170.0,
          sprintOrKomClassification: SegmentClassification.horsCategorie,
        ),
        StageSegment(
          index: 2,
          startKm: 98.0,
          lengthKm: 28.0,
          startElevationM: 2115.0,
          endElevationM: 840.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 72.0,
          windDirectionDegrees: 80.0,
          roadBearingDegrees: 95.0,
          sprintOrKomClassification: SegmentClassification.none,
        ),
        StageSegment(
          index: 3,
          startKm: 126.0,
          lengthKm: 15.5,
          startElevationM: 840.0,
          endElevationM: 1564.0,
          surfaceType: SegmentSurfaceType.roughAsphalt,
          technicalDifficulty: 58.0,
          windDirectionDegrees: 45.0,
          roadBearingDegrees: 155.0,
          sprintOrKomClassification: SegmentClassification.cat1,
        ),
        StageSegment(
          index: 4,
          startKm: 141.5,
          lengthKm: 10.7,
          startElevationM: 820.0,
          endElevationM: 1680.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 68.0,
          windDirectionDegrees: 15.0,
          roadBearingDegrees: 185.0,
          sprintOrKomClassification: SegmentClassification.horsCategorie,
        ),
      ],
    );
  }

  List<TeamBusRiderSlot> _buildInitialRiderSlots() {
    final rng = math.Random(20260714);
    final List<Rider> sourceRiders = <Rider>[];

    if (widget.riders != null && widget.riders!.isNotEmpty) {
      sourceRiders.addAll(widget.riders!.take(8));
    }

    if (sourceRiders.length < 8) {
      final specs = <RiderSpecialization>[
        RiderSpecialization.gcClimber,
        RiderSpecialization.pureClimber,
        RiderSpecialization.puncher,
        RiderSpecialization.domestiqueEngine,
        RiderSpecialization.breakawaySpecialist,
        RiderSpecialization.timeTrialist,
        RiderSpecialization.versatileSprinter,
        RiderSpecialization.classicCobbles,
      ];
      final roles = <RiderRole>[
        RiderRole.teamLeader,
        RiderRole.superDomestique,
        RiderRole.coLeader,
        RiderRole.domestique,
        RiderRole.breakawaySpecialist,
        RiderRole.domestique,
        RiderRole.sprinter,
        RiderRole.neoPro,
      ];
      for (int i = sourceRiders.length; i < 8; i++) {
        sourceRiders.add(
          RiderProceduralGenerator.generateRider(
            id: 'bus_rider_$i',
            specialization: specs[i % specs.length],
            targetOverallRating: i == 0 ? 89 : (76 + rng.nextInt(10)),
            teamId: _team.id,
            role: roles[i % roles.length],
            random: rng,
          ),
        );
      }
    }

    const seatCodes = <String>['1A', '1B', '2A', '2B', '3A', '3B', '4A', '4B'];
    final List<TeamBusRiderSlot> slots = <TeamBusRiderSlot>[];

    for (int i = 0; i < sourceRiders.length; i++) {
      final rider = sourceRiders[i];
      final int dayCond = (widget.presetDayConditions != null &&
              i < widget.presetDayConditions!.length)
          ? widget.presetDayConditions![i].clamp(-5, 5)
          : _computeInitialDayCondition(rider, rng);
      final int baseMorale = rider.contract.morale.round().clamp(35, 95);
      final int baseFocus = (58 + (rider.skills.raceIq * 0.22)).round().clamp(50, 82);
      final bool isLeader = i == 0 || rider.contract.role == RiderRole.teamLeader;

      slots.add(
        TeamBusRiderSlot(
          rider: rider,
          startNumber: 101 + i,
          seatCode: seatCodes[i % seatCodes.length],
          roleLabel: _resolveRoleLabel(rider, i),
          isLeader: isLeader,
          trueDayCondition: dayCond,
          baseMorale: baseMorale,
          currentMorale: baseMorale,
          baseFocusFirst20Km: baseFocus,
          currentFocusFirst20Km: baseFocus,
          warmUpWatts: (rider.physiology.ftpWatts * 0.68).roundToDouble(),
          warmUpBpm: 124 + rng.nextInt(16),
        ),
      );
    }

    return slots;
  }

  int _computeInitialDayCondition(Rider rider, math.Random rng) {
    final double tsb = rider.health.trainingStressBalance;
    final int tsbBias = (tsb / 10.0).round().clamp(-2, 2);
    final int roll = rng.nextInt(7) - 3; // -3..+3
    return (tsbBias + roll).clamp(-5, 5);
  }

  String _resolveRoleLabel(Rider rider, int index) {
    switch (rider.contract.role) {
      case RiderRole.teamLeader:
        return 'Lider GC';
      case RiderRole.coLeader:
        return 'Co-Lider';
      case RiderRole.superDomestique:
        return 'Super-Domestique';
      case RiderRole.sprinter:
        return 'Sprinter';
      case RiderRole.breakawaySpecialist:
        return 'Uciekinier';
      case RiderRole.neoPro:
        return 'Neo-Pro';
      case RiderRole.domestique:
        return index == 0 ? 'Lider GC' : 'Pomocnik';
    }
  }

  void _startWarmUpForRider(int index) {
    if (index < 0 || index >= _slots.length) return;
    final slot = _slots[index];
    if (slot.isWarmedUp || slot.isWarmingUp) return;

    if (widget.instantWarmUpForTesting) {
      setState(() {
        _slots[index] = slot.copyWith(
          isWarmingUp: false,
          isWarmedUp: true,
          warmUpProgress: 1.0,
        );
      });
      return;
    }

    setState(() {
      _selectedIndex = index;
      _slots[index] = slot.copyWith(
        isWarmingUp: true,
        warmUpProgress: 0.08,
      );
    });
    _ensureWarmUpTimerRunning();
  }

  void _startWarmUpForAll() {
    if (widget.instantWarmUpForTesting) {
      setState(() {
        _slots = _slots
            .map(
              (s) => s.copyWith(
                isWarmingUp: false,
                isWarmedUp: true,
                warmUpProgress: 1.0,
              ),
            )
            .toList();
      });
      return;
    }

    bool anyStarted = false;
    setState(() {
      for (int i = 0; i < _slots.length; i++) {
        if (!_slots[i].isWarmedUp && !_slots[i].isWarmingUp) {
          _slots[i] = _slots[i].copyWith(
            isWarmingUp: true,
            warmUpProgress: 0.06,
          );
          anyStarted = true;
        }
      }
    });
    if (anyStarted) {
      _ensureWarmUpTimerRunning();
    }
  }

  void _ensureWarmUpTimerRunning() {
    if (_warmUpTimer != null && _warmUpTimer!.isActive) return;
    _warmUpTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      bool anyStillWarming = false;
      setState(() {
        for (int i = 0; i < _slots.length; i++) {
          final slot = _slots[i];
          if (slot.isWarmingUp && !slot.isWarmedUp) {
            final double nextProgress = (slot.warmUpProgress + 0.085).clamp(0.0, 1.0);
            final bool done = nextProgress >= 1.0;
            final double rampedWatts = slot.rider.physiology.ftpWatts *
                (0.62 + 0.28 * nextProgress);
            final int rampedBpm = (122 + (32 * nextProgress)).round();

            _slots[i] = slot.copyWith(
              warmUpProgress: nextProgress,
              isWarmingUp: !done,
              isWarmedUp: done,
              warmUpWatts: rampedWatts,
              warmUpBpm: rampedBpm,
            );
            if (!done) {
              anyStillWarming = true;
            }
          }
        }
      });

      if (!anyStillWarming) {
        timer.cancel();
      }
    });
  }

  void _deliverSpeech() {
    if (_deliveredSpeech != null) return;
    final speech = _selectedSpeech;

    setState(() {
      _deliveredSpeech = speech;
      _slots = _slots.map((slot) {
        int moraleBoost = speech.moraleDelta;
        int focusBoost = speech.focusFirst20KmDelta;

        switch (speech) {
          case DirectorSpeechOption.removePressure:
            if (slot.isWarmedUp && slot.trueDayCondition < 0) {
              moraleBoost += 4;
            }
            break;
          case DirectorSpeechOption.allInForLeader:
            if (slot.isLeader) {
              focusBoost += 5;
              moraleBoost += 3;
            }
            break;
          case DirectorSpeechOption.attackFromKmZero:
            if (slot.rider.specialization ==
                    RiderSpecialization.breakawaySpecialist ||
                slot.rider.specialization == RiderSpecialization.puncher) {
              focusBoost += 4;
            }
            break;
          case DirectorSpeechOption.surviveTimeLimit:
            if (slot.rider.specialization == RiderSpecialization.pureSprinter) {
              moraleBoost += 4;
            }
            break;
        }

        final int newMorale = (slot.baseMorale + moraleBoost).clamp(1, 100);
        final int newFocus =
            (slot.baseFocusFirst20Km + focusBoost).clamp(1, 100);

        return slot.copyWith(
          currentMorale: newMorale,
          currentFocusFirst20Km: newFocus,
          lastMoraleDelta: newMorale - slot.baseMorale,
          lastFocusDelta: newFocus - slot.baseFocusFirst20Km,
        );
      }).toList();
    });

    final result = TeamBusBriefingResult(
      deliveredSpeech: speech,
      riderSlots: List<TeamBusRiderSlot>.unmodifiable(_slots),
    );
    widget.onSpeechDelivered?.call(result);
  }

  void _proceedToStartLine() {
    final result = TeamBusBriefingResult(
      deliveredSpeech: _deliveredSpeech,
      riderSlots: List<TeamBusRiderSlot>.unmodifiable(_slots),
    );
    if (widget.onProceedToStart != null) {
      widget.onProceedToStart!(result);
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    }
  }

  Color _parseHexColor(String hex, Color fallback) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      final parsed = int.tryParse('FF$cleaned', radix: 16);
      if (parsed != null) return Color(parsed);
    } else if (cleaned.length == 8) {
      final parsed = int.tryParse(cleaned, radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return fallback;
  }

  int get _warmedUpCount => _slots.where((s) => s.isWarmedUp).length;

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        _parseHexColor(_team.primaryJerseyColorHex, AppColors.primaryAccent);
    final secondaryColor =
        _parseHexColor(_team.secondaryJerseyColorHex, AppColors.surface);
    final accentColor =
        _parseHexColor(_team.accentJerseyColorHex, AppColors.goldAccent);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final bool isDesktop = width >= 1200;
            final bool isTablet = width >= 720 && width < 1200;

            return Column(
              children: [
                _buildTopHeader(
                  context: context,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                  isCompact: width < 720,
                ),
                Expanded(
                  child: isDesktop
                      ? _buildDesktopLayout(
                          primaryColor: primaryColor,
                          secondaryColor: secondaryColor,
                          accentColor: accentColor,
                        )
                      : _buildScrollableLayout(
                          isTablet: isTablet,
                          primaryColor: primaryColor,
                          secondaryColor: secondaryColor,
                          accentColor: accentColor,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader({
    required BuildContext context,
    required Color primaryColor,
    required Color accentColor,
    required bool isCompact,
  }) {
    final bool allWarmedUp = _warmedUpCount == _slots.length;
    final bool canPop = Navigator.of(context).canPop();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1.0),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canPop) ...[
                _InteractiveIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Wróć',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 10),
              ],
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.55),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.directions_bus_filled_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isCompact ? 240 : 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'AUTOBUS DRUŻYNY • ${_team.name.toUpperCase()}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Etap ${_stage.stageNumber}: ${_stage.name}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StageMetaPill(
                icon: Icons.route_rounded,
                label: '${_stage.totalDistanceKm.toStringAsFixed(1)} km',
              ),
              _StageMetaPill(
                icon: Icons.landscape_rounded,
                label: '${_stage.elevationGainMeters} m',
              ),
              _StageMetaPill(
                icon: Icons.thermostat_rounded,
                label: '${_stage.baseTemperatureCelsius.toStringAsFixed(0)}°C',
              ),
              _ActionPillButton(
                label: allWarmedUp
                    ? 'Rozgrzewka ukończona (8/8)'
                    : 'Rozgrzej wszystkich ($_warmedUpCount/8)',
                icon: allWarmedUp
                    ? Icons.verified_rounded
                    : Icons.pedal_bike_rounded,
                accentColor:
                    allWarmedUp ? AppColors.statusSuccess : AppColors.accentBlue,
                enabled: !allWarmedUp,
                onPressed: _startWarmUpForAll,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout({
    required Color primaryColor,
    required Color secondaryColor,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Lewa kolumna: Wizualizacja autobusu + Mowa Dyrektora Sportowego
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBusInteriorCard(
                    height: 265,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 14),
                  _buildDirectorSpeechPanel(accentColor: accentColor),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Prawa kolumna: 8 kart kolarzy w autobusie + wyjście na start
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSquadHeaderBar(),
                const SizedBox(height: 10),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, gridConstraints) {
                      final int cols = gridConstraints.maxWidth >= 560 ? 2 : 1;
                      return GridView.builder(
                        itemCount: _slots.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 192,
                        ),
                        itemBuilder: (context, index) => _buildRiderCard(
                          index: index,
                          primaryColor: primaryColor,
                          accentColor: accentColor,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableLayout({
    required bool isTablet,
    required Color primaryColor,
    required Color secondaryColor,
    required Color accentColor,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBusInteriorCard(
            height: isTablet ? 330 : 250,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            accentColor: accentColor,
          ),
          const SizedBox(height: 14),
          _buildDirectorSpeechPanel(accentColor: accentColor),
          const SizedBox(height: 16),
          _buildSquadHeaderBar(),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final int cols = constraints.maxWidth >= 680 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _slots.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 192,
                ),
                itemBuilder: (context, index) => _buildRiderCard(
                  index: index,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBusInteriorCard({
    required double height,
    required Color primaryColor,
    required Color secondaryColor,
    required Color accentColor,
  }) {
    final selectedSlot = _slots[_selectedIndex];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: _ambientController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: TeamBusInteriorPainter(
                        teamPrimaryColor: primaryColor,
                        teamSecondaryColor: secondaryColor,
                        teamAccentColor: accentColor,
                        stage: _stage,
                        riderSlots: _slots,
                        selectedRiderIndex: _selectedIndex,
                        ledPulse: _ambientController.value,
                        speechDelivered: _deliveredSpeech != null,
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _deliveredSpeech != null
                                ? AppColors.statusSuccess
                                : AppColors.amberWarning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _deliveredSpeech != null
                              ? 'GOTOWI DO WYJŚCIA NA START'
                              : 'ODPRAWA PRZEDETAPOWA • -00:18:00',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              border: Border(
                top: BorderSide(color: AppColors.cardBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.airline_seat_recline_extra_rounded,
                    size: 16, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fotel ${selectedSlot.seatCode}: ${selectedSlot.rider.fullName} '
                    '(${selectedSlot.roleLabel}) • '
                    '${selectedSlot.isWarmedUp ? _conditionSummary(selectedSlot.trueDayCondition) : "Oczekuje na rozgrzewkę na trenażerze"}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildDirectorSpeechPanel({required Color accentColor}) {
    final bool speechDone = _deliveredSpeech != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.campaign_rounded, color: accentColor, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'MOWA MOTYWACYJNA DYREKTORA SPORTOWEGO',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (speechDone)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.statusSuccess.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.statusSuccess.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text(
                    'WYGŁOSZONA',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.statusSuccess,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...DirectorSpeechOption.values.map((option) {
            final bool isSelected = speechDone
                ? _deliveredSpeech == option
                : _selectedSpeech == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SpeechOptionTile(
                option: option,
                selected: isSelected,
                disabled: speechDone,
                onTap: () {
                  if (!speechDone) {
                    setState(() => _selectedSpeech = option);
                  }
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
            child: Text(
              (speechDone ? _deliveredSpeech! : _selectedSpeech).speechQuote,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionPillButton(
                label: speechDone
                    ? 'Mowa wygłoszona'
                    : 'Wygłoś mowę motywacyjną',
                icon: speechDone
                    ? Icons.check_circle_rounded
                    : Icons.record_voice_over_rounded,
                accentColor:
                    speechDone ? AppColors.statusSuccess : AppColors.goldAccent,
                enabled: !speechDone,
                onPressed: _deliverSpeech,
              ),
              _ActionPillButton(
                label: 'Wyjdź na linię startu',
                icon: Icons.flag_rounded,
                accentColor: AppColors.primaryAccent,
                enabled: true,
                filled: true,
                onPressed: _proceedToStartLine,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSquadHeaderBar() {
    return Row(
      children: [
        const Icon(Icons.groups_rounded,
            size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'SKŁAD ETAPOWY (8 KOLARZY) • ODKRYJ NOGĘ DNIA NA TRENAŻERZE',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          '$_warmedUpCount / ${_slots.length} po rozgrzewce',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
            color: AppColors.accentBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildRiderCard({
    required int index,
    required Color primaryColor,
    required Color accentColor,
  }) {
    final slot = _slots[index];
    final bool isSelected = _selectedIndex == index;

    return _BusRiderCard(
      slot: slot,
      team: _team,
      selected: isSelected,
      primaryColor: primaryColor,
      accentColor: accentColor,
      onSelect: () => setState(() => _selectedIndex = index),
      onWarmUp: () => _startWarmUpForRider(index),
    );
  }

  String _conditionSummary(int value) {
    if (value >= 4) return 'Noga Dnia +$value (Dzień konia!)';
    if (value >= 2) return 'Noga Dnia +$value (Świetna dyspozycja)';
    if (value == 1) return 'Noga Dnia +1 (Lekka przewaga)';
    if (value == 0) return 'Noga Dnia 0 (Standardowa)';
    if (value >= -2) return 'Noga Dnia $value (Ciężkie nogi)';
    return 'Noga Dnia $value (Kryzysowa dyspozycja)';
  }
}

class _BusRiderCard extends StatefulWidget {
  final TeamBusRiderSlot slot;
  final CyclingTeam team;
  final bool selected;
  final Color primaryColor;
  final Color accentColor;
  final VoidCallback onSelect;
  final VoidCallback onWarmUp;

  const _BusRiderCard({
    required this.slot,
    required this.team,
    required this.selected,
    required this.primaryColor,
    required this.accentColor,
    required this.onSelect,
    required this.onWarmUp,
  });

  @override
  State<_BusRiderCard> createState() => _BusRiderCardState();
}

class _BusRiderCardState extends State<_BusRiderCard> {
  bool _hovered = false;
  bool _focused = false;

  Color _conditionColor(int cond) {
    if (cond >= 3) return AppColors.statusSuccess;
    if (cond >= 1) return AppColors.accentBlue;
    if (cond == 0) return AppColors.textSecondary;
    if (cond >= -2) return AppColors.amberWarning;
    return AppColors.crimsonAlert;
  }

  String _conditionText(int cond) {
    if (cond > 0) return '+$cond';
    return '$cond';
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final Color borderColor = widget.selected
        ? widget.accentColor
        : (_hovered || _focused
            ? AppColors.accentBlue.withValues(alpha: 0.75)
            : AppColors.cardBorder);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.surfaceLight
                : (_hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.7)
                    : AppColors.surface),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: widget.selected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  RiderAvatarWidget.fromRider(
                    rider: slot.rider,
                    team: widget.team,
                    size: 42,
                    showHelmet: false,
                    showGlasses: false,
                    borderWidth: 1.5,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: widget.primaryColor.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#${slot.startNumber}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                slot.rider.fullName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${slot.roleLabel} • Fotel ${slot.seatCode} • OVR ${slot.rider.overallRating}',
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
                  const SizedBox(width: 8),
                  _buildConditionBadge(slot),
                ],
              ),
              const SizedBox(height: 10),
              // Morale & Koncentracja na pierwszych 20 km
              _StatProgressRow(
                label: 'Morale',
                value: slot.currentMorale,
                delta: slot.lastMoraleDelta,
                barColor: AppColors.goldAccent,
              ),
              const SizedBox(height: 6),
              _StatProgressRow(
                label: 'Koncentracja (0–20 km)',
                value: slot.currentFocusFirst20Km,
                delta: slot.lastFocusDelta,
                barColor: AppColors.accentBlue,
              ),
              const Spacer(),
              if (slot.isWarmingUp)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Trenażer: ${slot.warmUpWatts.round()} W • ${slot.warmUpBpm} BPM',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFeatures: [FontFeature.tabularFigures()],
                            color: AppColors.amberWarning,
                          ),
                        ),
                        Text(
                          '${(slot.warmUpProgress * 100).round()}%',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontFeatures: [FontFeature.tabularFigures()],
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: slot.warmUpProgress,
                        minHeight: 5,
                        backgroundColor: AppColors.background,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.amberWarning),
                      ),
                    ),
                  ],
                )
              else if (!slot.isWarmedUp)
                _ActionPillButton(
                  label: 'Rozgrzewka na trenażerze',
                  icon: Icons.directions_bike_rounded,
                  accentColor: AppColors.accentBlue,
                  enabled: true,
                  compact: true,
                  onPressed: widget.onWarmUp,
                )
              else
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 14,
                      color: _conditionColor(slot.trueDayCondition),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Po rozgrzewce przed autobusem • Gotowy',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConditionBadge(TeamBusRiderSlot slot) {
    if (!slot.isWarmedUp) {
      return Container(
        width: 44,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: slot.isWarmingUp
                ? AppColors.amberWarning
                : AppColors.cardBorder,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot.isWarmingUp ? '...' : '?',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: slot.isWarmingUp
                    ? AppColors.amberWarning
                    : AppColors.textSecondary,
              ),
            ),
            const Text(
              'NOGA',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final color = _conditionColor(slot.trueDayCondition);
    return Container(
      width: 44,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _conditionText(slot.trueDayCondition),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
            ),
          ),
          Text(
            'NOGA',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatProgressRow extends StatelessWidget {
  final String label;
  final int value;
  final int? delta;
  final Color barColor;

  const _StatProgressRow({
    required this.label,
    required this.value,
    required this.delta,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (delta != null && delta != 0)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  delta! > 0 ? '+$delta' : '$delta',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: delta! > 0
                        ? AppColors.statusSuccess
                        : AppColors.crimsonAlert,
                  ),
                ),
              ),
            Text(
              '$value',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (value / 100.0).clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

class _SpeechOptionTile extends StatefulWidget {
  final DirectorSpeechOption option;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _SpeechOptionTile({
    required this.option,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  State<_SpeechOptionTile> createState() => _SpeechOptionTileState();
}

class _SpeechOptionTileState extends State<_SpeechOptionTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final option = widget.option;
    final bool active = widget.selected;
    final bool isDisabled = widget.disabled;

    return FocusableActionDetector(
      enabled: !isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: Opacity(
        opacity: isDisabled && !active ? 0.48 : 1.0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isDisabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? option.accentColor.withValues(alpha: 0.14)
                  : (_hovered || _focused
                      ? AppColors.surfaceLight
                      : AppColors.background.withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active
                    ? option.accentColor
                    : (_hovered || _focused
                        ? AppColors.textSecondary.withValues(alpha: 0.5)
                        : AppColors.cardBorder),
                width: active ? 1.4 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: option.accentColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(option.icon, size: 17, color: option.accentColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.effectSummary,
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
            ),
          ),
        ),
      ),
    );
  }
}

class _StageMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StageMetaPill({
    required this.icon,
    required this.label,
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
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
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
    );
  }
}

class _ActionPillButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool enabled;
  final bool filled;
  final bool compact;
  final VoidCallback onPressed;

  const _ActionPillButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.enabled,
    this.filled = false,
    this.compact = false,
    required this.onPressed,
  });

  @override
  State<_ActionPillButton> createState() => _ActionPillButtonState();
}

class _ActionPillButtonState extends State<_ActionPillButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.enabled;
    final Color bg = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.filled
            ? (_pressed
                ? widget.accentColor.withValues(alpha: 0.85)
                : (_hovered
                    ? widget.accentColor.withValues(alpha: 0.92)
                    : widget.accentColor))
            : (_hovered || _focused
                ? widget.accentColor.withValues(alpha: 0.22)
                : widget.accentColor.withValues(alpha: 0.13));

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 14,
            vertical: widget.compact ? 6 : 9,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: !enabled
                  ? AppColors.cardBorder
                  : (_focused
                      ? AppColors.textPrimary
                      : widget.accentColor.withValues(alpha: 0.85)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: widget.compact ? 14 : 16,
                color: !enabled
                    ? AppColors.textSecondary
                    : (widget.filled ? AppColors.textPrimary : widget.accentColor),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: widget.compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: !enabled
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
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
          borderRadius: BorderRadius.circular(10),
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceLight : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Icon(widget.icon, size: 18, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter renderujący wnętrze nowoczesnego autobusu drużyny kolarskiej:
/// - fotele skórzane w dwóch rzędach perspektywicznych,
/// - oświetlenie LED w barwach drużyny,
/// - ekran taktyczny TV na przedniej ścianie z profilem etapu,
/// - zawieszone koszulki startowe 8 kolarzy na relingu szatni.
class TeamBusInteriorPainter extends CustomPainter {
  final Color teamPrimaryColor;
  final Color teamSecondaryColor;
  final Color teamAccentColor;
  final RaceStage stage;
  final List<TeamBusRiderSlot> riderSlots;
  final int selectedRiderIndex;
  final double ledPulse;
  final bool speechDelivered;

  const TeamBusInteriorPainter({
    required this.teamPrimaryColor,
    required this.teamSecondaryColor,
    required this.teamAccentColor,
    required this.stage,
    required this.riderSlots,
    required this.selectedRiderIndex,
    required this.ledPulse,
    required this.speechDelivered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double w = size.width;
    final double h = size.height;

    // 1. Tło kabiny i perspektywa ścian / sufitu / podłogi
    _paintCabinShell(canvas, w, h);

    // 2. Okna panoramiczne i poświata miasteczka startowego
    _paintBusWindows(canvas, w, h);

    // 3. Oświetlenie LED w barwach drużyny
    _paintTeamLedLighting(canvas, w, h);

    // 4. Ekran taktyczny TV na przedniej ścianie kabiny
    _paintTacticalTvScreen(canvas, w, h);

    // 5. Zawieszone koszulki startowe kolarzy na relingu
    _paintHangingRaceJerseys(canvas, w, h);

    // 6. Skórzane fotele kolarzy (8 miejsc)
    _paintLeatherSeats(canvas, w, h);
  }

  void _paintCabinShell(Canvas canvas, double w, double h) {
    // Główne tło kabiny
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0C0E13),
          Color(0xFF151922),
          Color(0xFF0F1115),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Ściana przednia (bulkhead) w głębi perspektywy
    final Rect frontWall = Rect.fromLTWH(w * 0.22, h * 0.16, w * 0.56, h * 0.44);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frontWall, const Radius.circular(8)),
      Paint()..color = const Color(0xFF181B22),
    );

    // Sufit
    final ceilingPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(frontWall.right, frontWall.top)
      ..lineTo(frontWall.left, frontWall.top)
      ..close();
    canvas.drawPath(ceilingPath, Paint()..color = const Color(0xFF12151C));

    // Podłoga z centralnym przejściem
    final floorPath = Path()
      ..moveTo(frontWall.left, frontWall.bottom)
      ..lineTo(frontWall.right, frontWall.bottom)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(floorPath, Paint()..color = const Color(0xFF101319));

    // Centralny dywanik / przejście w autobusie
    final aislePath = Path()
      ..moveTo(w * 0.44, frontWall.bottom)
      ..lineTo(w * 0.56, frontWall.bottom)
      ..lineTo(w * 0.64, h)
      ..lineTo(w * 0.36, h)
      ..close();
    canvas.drawPath(aislePath, Paint()..color = const Color(0xFF1A1E28));

    // Linie podziału paneli ścian
    final linePaint = Paint()
      ..color = const Color(0xFF2A2F3D)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, h * 0.12),
      Offset(frontWall.left, frontWall.top),
      linePaint,
    );
    canvas.drawLine(
      Offset(w, h * 0.12),
      Offset(frontWall.right, frontWall.top),
      linePaint,
    );
  }

  void _paintBusWindows(Canvas canvas, double w, double h) {
    final leftWindow = Path()
      ..moveTo(w * 0.02, h * 0.18)
      ..lineTo(w * 0.20, h * 0.22)
      ..lineTo(w * 0.20, h * 0.48)
      ..lineTo(w * 0.02, h * 0.50)
      ..close();

    final rightWindow = Path()
      ..moveTo(w * 0.98, h * 0.18)
      ..lineTo(w * 0.80, h * 0.22)
      ..lineTo(w * 0.80, h * 0.48)
      ..lineTo(w * 0.98, h * 0.50)
      ..close();

    final windowGlassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1E293B).withValues(alpha: 0.7),
          const Color(0xFF0F172A).withValues(alpha: 0.9),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.18, w, h * 0.34));

    canvas.drawPath(leftWindow, windowGlassPaint);
    canvas.drawPath(rightWindow, windowGlassPaint);

    final framePaint = Paint()
      ..color = const Color(0xFF2A2F3D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(leftWindow, framePaint);
    canvas.drawPath(rightWindow, framePaint);
  }

  void _paintTeamLedLighting(Canvas canvas, double w, double h) {
    final double alpha = 0.45 + 0.35 * ledPulse;
    final glowPaint = Paint()
      ..color = teamPrimaryColor.withValues(alpha: alpha * 0.75)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

    final corePaint = Paint()
      ..color = Color.lerp(teamPrimaryColor, teamAccentColor, 0.35)!
          .withValues(alpha: 0.9)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Górne listwy LED wzdłuż sufitu
    final leftCeilingStart = Offset(w * 0.04, h * 0.05);
    final leftCeilingEnd = Offset(w * 0.24, h * 0.17);
    final rightCeilingStart = Offset(w * 0.96, h * 0.05);
    final rightCeilingEnd = Offset(w * 0.76, h * 0.17);

    for (final p in [
      (leftCeilingStart, leftCeilingEnd),
      (rightCeilingStart, rightCeilingEnd),
    ]) {
      canvas.drawLine(p.$1, p.$2, glowPaint);
      canvas.drawLine(p.$1, p.$2, corePaint);
    }

    // Dolne listwy LED wzdłuż przejścia
    final aisleGlow = Paint()
      ..color = teamAccentColor.withValues(alpha: alpha * 0.65)
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    final aisleCore = Paint()
      ..color = teamAccentColor.withValues(alpha: 0.85)
      ..strokeWidth = 1.2;

    canvas.drawLine(Offset(w * 0.44, h * 0.60), Offset(w * 0.36, h), aisleGlow);
    canvas.drawLine(Offset(w * 0.44, h * 0.60), Offset(w * 0.36, h), aisleCore);
    canvas.drawLine(Offset(w * 0.56, h * 0.60), Offset(w * 0.64, h), aisleGlow);
    canvas.drawLine(Offset(w * 0.56, h * 0.60), Offset(w * 0.64, h), aisleCore);
  }

  void _paintTacticalTvScreen(Canvas canvas, double w, double h) {
    final Rect tvFrame = Rect.fromLTWH(w * 0.31, h * 0.19, w * 0.38, h * 0.24);
    final RRect tvFrameRRect =
        RRect.fromRectAndRadius(tvFrame, const Radius.circular(6));

    // Poświata ekranu TV
    canvas.drawRRect(
      tvFrameRRect.inflate(2),
      Paint()
        ..color = AppColors.accentBlue.withValues(alpha: 0.18 + 0.08 * ledPulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Obudowa TV
    canvas.drawRRect(
      tvFrameRRect,
      Paint()..color = const Color(0xFF0A0C10),
    );
    canvas.drawRRect(
      tvFrameRRect,
      Paint()
        ..color = const Color(0xFF2E3440)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Ekran wewnętrzny
    final Rect screen = tvFrame.deflate(4);
    canvas.drawRect(screen, Paint()..color = const Color(0xFF0F172A));

    // Wykres profilu wysokościowego trasy na TV
    final List<double> altitudes = _extractStageProfilePoints();
    final Path profilePath = Path();
    final Path fillPath = Path();

    final double plotLeft = screen.left + 6;
    final double plotRight = screen.right - 6;
    final double plotTop = screen.top + screen.height * 0.32;
    final double plotBottom = screen.bottom - 8;

    fillPath.moveTo(plotLeft, plotBottom);
    for (int i = 0; i < altitudes.length; i++) {
      final double t = i / (altitudes.length - 1);
      final double x = plotLeft + t * (plotRight - plotLeft);
      final double y = plotBottom - altitudes[i] * (plotBottom - plotTop);
      if (i == 0) {
        profilePath.moveTo(x, y);
      } else {
        profilePath.lineTo(x, y);
      }
      fillPath.lineTo(x, y);
    }
    fillPath.lineTo(plotRight, plotBottom);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            teamAccentColor.withValues(alpha: 0.45),
            teamAccentColor.withValues(alpha: 0.05),
          ],
        ).createShader(screen),
    );
    canvas.drawPath(
      profilePath,
      Paint()
        ..color = teamAccentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Tekst na ekranie TV
    final titlePainter = TextPainter(
      text: TextSpan(
        text: 'TAKTYKA TV • ETAP ${stage.stageNumber}',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: AppColors.accentBlue,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: screen.width - 10);
    titlePainter.paint(canvas, Offset(screen.left + 6, screen.top + 4));

    if (speechDelivered) {
      final badgePainter = TextPainter(
        text: const TextSpan(
          text: 'PLAN ZATWIERDZONY',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 7.5,
            fontWeight: FontWeight.w700,
            color: AppColors.statusSuccess,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: screen.width - 10);
      badgePainter.paint(
        canvas,
        Offset(screen.right - badgePainter.width - 6, screen.top + 4),
      );
    }
  }

  List<double> _extractStageProfilePoints() {
    if (stage.segments.isEmpty) {
      return const [0.15, 0.25, 0.65, 0.35, 0.85, 0.95];
    }
    final List<double> raw = <double>[stage.segments.first.startElevationM];
    for (final seg in stage.segments) {
      raw.add(seg.endElevationM);
    }
    final double minE = raw.reduce(math.min);
    final double maxE = raw.reduce(math.max);
    final double span = math.max(100.0, maxE - minE);
    return raw.map((e) => ((e - minE) / span).clamp(0.08, 0.95)).toList();
  }

  void _paintHangingRaceJerseys(Canvas canvas, double w, double h) {
    // Reling z zawieszonymi koszulkami na górnej półce nad przednią ścianą
    final double railY = h * 0.47;
    final double railLeft = w * 0.25;
    final double railRight = w * 0.75;

    canvas.drawLine(
      Offset(railLeft, railY),
      Offset(railRight, railY),
      Paint()
        ..color = const Color(0xFF475569)
        ..strokeWidth = 2.0,
    );

    final int count = math.min(8, riderSlots.length);
    if (count == 0) return;

    final double step = (railRight - railLeft) / (count + 1);
    for (int i = 0; i < count; i++) {
      final double cx = railLeft + step * (i + 1);
      final bool isSelected = i == selectedRiderIndex;
      final slot = riderSlots[i];

      // Wieszak
      canvas.drawLine(
        Offset(cx, railY),
        Offset(cx, railY + 4),
        Paint()
          ..color = const Color(0xFF94A3B8)
          ..strokeWidth = 1.2,
      );

      // Mini-koszulka startowa
      final double jW = isSelected ? 20 : 17;
      final double jH = isSelected ? 22 : 19;
      final double top = railY + 4;

      final jerseyPath = Path()
        ..moveTo(cx - jW * 0.28, top)
        ..lineTo(cx + jW * 0.28, top)
        ..lineTo(cx + jW * 0.56, top + jH * 0.28)
        ..lineTo(cx + jW * 0.38, top + jH * 0.42)
        ..lineTo(cx + jW * 0.34, top + jH)
        ..lineTo(cx - jW * 0.34, top + jH)
        ..lineTo(cx - jW * 0.38, top + jH * 0.42)
        ..lineTo(cx - jW * 0.56, top + jH * 0.28)
        ..close();

      canvas.drawPath(
        jerseyPath,
        Paint()..color = teamPrimaryColor,
      );

      // Poziomy pas barw drużyny
      canvas.drawRect(
        Rect.fromLTWH(cx - jW * 0.32, top + jH * 0.38, jW * 0.64, jH * 0.20),
        Paint()..color = teamAccentColor,
      );

      canvas.drawPath(
        jerseyPath,
        Paint()
          ..color = isSelected ? teamAccentColor : const Color(0xFF2E3440)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 1.5 : 0.8,
      );

      // Numer startowy na koszulce
      final numPainter = TextPainter(
        text: TextSpan(
          text: '${slot.startNumber}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 6.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      numPainter.paint(
        canvas,
        Offset(cx - numPainter.width / 2, top + jH * 0.65),
      );
    }
  }

  void _paintLeatherSeats(Canvas canvas, double w, double h) {
    // 4 rzędy po 2 fotele (lewa i prawa strona przejścia) w perspektywie
    final int count = math.min(8, riderSlots.length);
    for (int i = 0; i < count; i++) {
      final int row = i ~/ 2; // 0 (najbliżej ekranu) .. 3 (najbliżej widza)
      final bool isLeft = i.isEven;
      final double depthT = (row + 0.5) / 4.0; // 0.125 .. 0.875

      final double seatY = h * (0.62 + depthT * 0.30);
      final double seatW = w * (0.11 + depthT * 0.07);
      final double seatH = h * (0.12 + depthT * 0.08);
      final double aisleOffset = w * (0.09 + depthT * 0.09);

      final double centerX = isLeft ? (w * 0.5 - aisleOffset - seatW * 0.5) : (w * 0.5 + aisleOffset + seatW * 0.5);
      final Rect seatRect = Rect.fromCenter(
        center: Offset(centerX, seatY),
        width: seatW,
        height: seatH,
      );

      final bool isSelected = i == selectedRiderIndex;
      final slot = riderSlots[i];

      // Oparcie skórzanego fotela
      final RRect backrest = RRect.fromRectAndRadius(
        seatRect,
        const Radius.circular(8),
      );
      canvas.drawRRect(
        backrest,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isSelected ? const Color(0xFF2B3140) : const Color(0xFF1F2430),
              const Color(0xFF12151C),
            ],
          ).createShader(seatRect),
      );

      // Zagłówek z przeszyciem drużynowym
      final Rect headrest = Rect.fromCenter(
        center: Offset(centerX, seatRect.top + seatH * 0.16),
        width: seatW * 0.58,
        height: seatH * 0.24,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(headrest, const Radius.circular(5)),
        Paint()..color = const Color(0xFF282E3C),
      );

      // Pasek LED/przeszycia fotela
      canvas.drawRRect(
        backrest,
        Paint()
          ..color = isSelected ? teamAccentColor : const Color(0xFF333B4D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 1.8 : 1.0,
      );

      // Kropka statusu rozgrzewki / Nogi Dnia na fotelu
      final Color statusColor = slot.isWarmedUp
          ? (slot.trueDayCondition >= 2
              ? AppColors.statusSuccess
              : (slot.trueDayCondition < 0
                  ? AppColors.crimsonAlert
                  : AppColors.accentBlue))
          : (slot.isWarmingUp
              ? AppColors.amberWarning
              : AppColors.textSecondary.withValues(alpha: 0.5));

      canvas.drawCircle(
        Offset(seatRect.right - 8, seatRect.top + 8),
        3.5,
        Paint()..color = statusColor,
      );

      // Kod fotela (1A..4B)
      final codePainter = TextPainter(
        text: TextSpan(
          text: '${slot.seatCode} • #${slot.startNumber}',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 8.0 + depthT * 2.0,
            fontWeight: FontWeight.w700,
            color: isSelected ? teamAccentColor : AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      codePainter.paint(
        canvas,
        Offset(centerX - codePainter.width / 2, seatRect.bottom - codePainter.height - 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant TeamBusInteriorPainter oldDelegate) {
    return oldDelegate.ledPulse != ledPulse ||
        oldDelegate.selectedRiderIndex != selectedRiderIndex ||
        oldDelegate.speechDelivered != speechDelivered ||
        oldDelegate.riderSlots != riderSlots ||
        oldDelegate.teamPrimaryColor != teamPrimaryColor ||
        oldDelegate.teamAccentColor != teamAccentColor;
  }
}
