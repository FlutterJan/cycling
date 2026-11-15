import 'dart:math' as math;

import '../../models/career/staff_member.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider.dart';
import '../peloton/mountain_gc_ai_controller.dart';
import '../peloton/rider_race_state.dart';

/// Archetyp osobowości taktycznej kolarza i dyrektora sportowego AI w wyścigu 3D.
enum TacticalAiArchetype {
  cannibalAttacker,
  dieselCalculator,
  wheelsuckerOpportunist,
  kamikazeDescender,
  breakawayHunter,
  loyalRoadCaptain;

  String toJson() => name;

  static TacticalAiArchetype fromJson(String value) {
    return TacticalAiArchetype.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TacticalAiArchetype.dieselCalculator,
    );
  }

  /// Czytelna nazwa archetypu po polsku.
  String get displayName {
    switch (this) {
      case TacticalAiArchetype.cannibalAttacker:
        return 'Kanibal-Atakujący';
      case TacticalAiArchetype.dieselCalculator:
        return 'Diesel-Kalkulator';
      case TacticalAiArchetype.wheelsuckerOpportunist:
        return 'Pasożyt-Oportunista';
      case TacticalAiArchetype.kamikazeDescender:
        return 'Zjazdowiec-Kamikadze';
      case TacticalAiArchetype.breakawayHunter:
        return 'Łowca Ucieczek i Gór';
      case TacticalAiArchetype.loyalRoadCaptain:
        return 'Lojalny Kapitan Szosy';
    }
  }

  /// Krótki opis stylu jazdy i inspiracji kolarskiej.
  String get tacticalStyleSummary {
    switch (this) {
      case TacticalAiArchetype.cannibalAttacker:
        return 'Atakuje z daleka (nawet 50 km przed metą na przedostatniej przełęczy), gdy wyczuje słabość rywali.';
      case TacticalAiArchetype.dieselCalculator:
        return 'Ignoruje szarpane zrywy i jedzie morderczym, równym tempem na progu FTP, dochodząc przegrzanych rywali pod szczytem.';
      case TacticalAiArchetype.wheelsuckerOpportunist:
        return 'Oszczędza energię na kole, odmawia mocnych zmian w ucieczce i wyskakuje na ostatnich 300 metrach.';
      case TacticalAiArchetype.kamikazeDescender:
        return 'Atakuje na szczycie przełęczy i podejmuje maksymalne ryzyko na krętym zjeździe, zmuszając rywali do pogoni w dolinie.';
      case TacticalAiArchetype.breakawayHunter:
        return 'Skacze do każdego odjazdu dnia i walczy o każdą premię górską do koszulki w grochy.';
      case TacticalAiArchetype.loyalRoadCaptain:
        return 'W ułamku sekundy oddaje własne koło liderowi po defekcie i perfekcyjnie ustawia zespół przed zakrętami.';
    }
  }
}

/// Znormalizowane parametry behawioralne [0.0 - 1.0] opisujące profil taktyczny AI.
class AiPersonalityTraits {
  final double aggression;
  final double attackDistanceToFinishKm;
  final double ftpPacingDiscipline;
  final double breakawayPullWillingness;
  final double descentRiskAppetite;
  final double komSprintAppetite;
  final double leaderSupportPriority;
  final double lateSprintAmbushMeters;
  final double unpredictabilityFactor;

  const AiPersonalityTraits({
    required this.aggression,
    required this.attackDistanceToFinishKm,
    required this.ftpPacingDiscipline,
    required this.breakawayPullWillingness,
    required this.descentRiskAppetite,
    required this.komSprintAppetite,
    required this.leaderSupportPriority,
    required this.lateSprintAmbushMeters,
    required this.unpredictabilityFactor,
  });

  Map<String, dynamic> toJson() {
    return {
      'aggression': aggression,
      'attackDistanceToFinishKm': attackDistanceToFinishKm,
      'ftpPacingDiscipline': ftpPacingDiscipline,
      'breakawayPullWillingness': breakawayPullWillingness,
      'descentRiskAppetite': descentRiskAppetite,
      'komSprintAppetite': komSprintAppetite,
      'leaderSupportPriority': leaderSupportPriority,
      'lateSprintAmbushMeters': lateSprintAmbushMeters,
      'unpredictabilityFactor': unpredictabilityFactor,
    };
  }

  factory AiPersonalityTraits.fromJson(Map<String, dynamic> json) {
    return AiPersonalityTraits(
      aggression: (json['aggression'] as num).toDouble(),
      attackDistanceToFinishKm:
          (json['attackDistanceToFinishKm'] as num).toDouble(),
      ftpPacingDiscipline: (json['ftpPacingDiscipline'] as num).toDouble(),
      breakawayPullWillingness:
          (json['breakawayPullWillingness'] as num).toDouble(),
      descentRiskAppetite: (json['descentRiskAppetite'] as num).toDouble(),
      komSprintAppetite: (json['komSprintAppetite'] as num).toDouble(),
      leaderSupportPriority:
          (json['leaderSupportPriority'] as num).toDouble(),
      lateSprintAmbushMeters:
          (json['lateSprintAmbushMeters'] as num).toDouble(),
      unpredictabilityFactor:
          (json['unpredictabilityFactor'] as num).toDouble(),
    );
  }
}

/// Kontekst sytuacji wyścigowej przekazywany do oceny decyzji osobowości AI.
class TacticalAiRaceContext {
  final Rider rider;
  final RiderRaceState riderState;
  final StageSegment currentSegment;
  final List<StageSegment> upcomingSegments;
  final double distanceRemainingKm;
  final bool isPenultimateOrEarlierMajorClimb;
  final bool isNearClimbSummit;
  final bool isInBreakaway;
  final bool isBreakawayForming;
  final bool isLeaderInSameGroup;
  final bool leaderHasMechanical;
  final String? leaderId;
  final List<RivalClimbingAssessment> rivalsInGroup;
  final bool rivalAttacking;
  final double teamLeaderGapToFrontSeconds;
  final DirectorTacticalPhilosophy? directorPhilosophy;
  final int randomSeed;

  const TacticalAiRaceContext({
    required this.rider,
    required this.riderState,
    required this.currentSegment,
    this.upcomingSegments = const [],
    required this.distanceRemainingKm,
    this.isPenultimateOrEarlierMajorClimb = false,
    this.isNearClimbSummit = false,
    this.isInBreakaway = false,
    this.isBreakawayForming = false,
    this.isLeaderInSameGroup = false,
    this.leaderHasMechanical = false,
    this.leaderId,
    this.rivalsInGroup = const [],
    this.rivalAttacking = false,
    this.teamLeaderGapToFrontSeconds = 0.0,
    this.directorPhilosophy,
    this.randomSeed = 0,
  });

  /// Aktualny stosunek dostępnej energii beztlenowej W' do pojemności maksymalnej [0.0 - 1.0].
  double get wPrimeRatio {
    final maxWPrime = rider.physiology.wPrimeJoules;
    if (maxWPrime <= 0) return 0.0;
    return (riderState.currentWPrime / maxWPrime).clamp(0.0, 1.0);
  }

  /// Pozostały dystans do mety w metrach [m].
  double get distanceRemainingMeters =>
      math.max(0.0, distanceRemainingKm * 1000.0);

  /// Czy na aktualnym lub bezpośrednio kolejnym segmencie znajduje się premia górska KOM.
  bool get isApproachingOrOnKom {
    if (_isKomClassification(currentSegment.sprintOrKomClassification)) {
      return true;
    }
    if (upcomingSegments.isNotEmpty &&
        _isKomClassification(
            upcomingSegments.first.sprintOrKomClassification)) {
      return true;
    }
    return false;
  }

  /// Czy bezpośrednio po bieżącym odcinku następuje stromy lub techniczny zjazd.
  bool get hasSteepDescentAhead {
    if (upcomingSegments.isEmpty) return false;
    final next = upcomingSegments.first;
    return next.gradientPercent < -4.0 ||
        (next.isDescent && next.technicalDifficulty >= 55.0);
  }

  /// Czy przed kolarzem znajdują się techniczne zakręty lub wymagający sektor brukowy.
  bool get hasTechnicalCornersAhead {
    if (currentSegment.technicalDifficulty >= 55.0 ||
        currentSegment.isCobblestone) {
      return true;
    }
    if (upcomingSegments.isNotEmpty) {
      final next = upcomingSegments.first;
      return next.technicalDifficulty >= 58.0 || next.isCobblestone;
    }
    return false;
  }

  static bool _isKomClassification(SegmentClassification classification) {
    return classification == SegmentClassification.cat4 ||
        classification == SegmentClassification.cat3 ||
        classification == SegmentClassification.cat2 ||
        classification == SegmentClassification.cat1 ||
        classification == SegmentClassification.horsCategorie;
  }
}

/// Wynikowa decyzja taktyczna wygenerowana przez profil osobowości AI.
class TacticalAiDecision {
  final TacticalAiArchetype archetype;
  final TacticalOrder recommendedOrder;
  final double targetPowerFractionOfFtp;
  final int targetWatts;
  final double pullContributionRatio;
  final double descentRiskMultiplier;
  final bool shouldLaunchAttack;
  final bool shouldContestKomSprint;
  final bool shouldSwapWheelWithLeader;
  final bool shouldOrganizeCornerLeadout;
  final bool shouldLaunchFinal300mAmbush;
  final double targetLateralPositionRoad;
  final double decisionConfidence;
  final String radioCommentary;

  const TacticalAiDecision({
    required this.archetype,
    required this.recommendedOrder,
    required this.targetPowerFractionOfFtp,
    required this.targetWatts,
    required this.pullContributionRatio,
    required this.descentRiskMultiplier,
    required this.shouldLaunchAttack,
    required this.shouldContestKomSprint,
    required this.shouldSwapWheelWithLeader,
    required this.shouldOrganizeCornerLeadout,
    required this.shouldLaunchFinal300mAmbush,
    required this.targetLateralPositionRoad,
    required this.decisionConfidence,
    required this.radioCommentary,
  });

  Map<String, dynamic> toJson() {
    return {
      'archetype': archetype.toJson(),
      'recommendedOrder': recommendedOrder.toJson(),
      'targetPowerFractionOfFtp': targetPowerFractionOfFtp,
      'targetWatts': targetWatts,
      'pullContributionRatio': pullContributionRatio,
      'descentRiskMultiplier': descentRiskMultiplier,
      'shouldLaunchAttack': shouldLaunchAttack,
      'shouldContestKomSprint': shouldContestKomSprint,
      'shouldSwapWheelWithLeader': shouldSwapWheelWithLeader,
      'shouldOrganizeCornerLeadout': shouldOrganizeCornerLeadout,
      'shouldLaunchFinal300mAmbush': shouldLaunchFinal300mAmbush,
      'targetLateralPositionRoad': targetLateralPositionRoad,
      'decisionConfidence': decisionConfidence,
      'radioCommentary': radioCommentary,
    };
  }

  factory TacticalAiDecision.fromJson(Map<String, dynamic> json) {
    return TacticalAiDecision(
      archetype: TacticalAiArchetype.fromJson(json['archetype'] as String),
      recommendedOrder:
          TacticalOrder.fromJson(json['recommendedOrder'] as String),
      targetPowerFractionOfFtp:
          (json['targetPowerFractionOfFtp'] as num).toDouble(),
      targetWatts: (json['targetWatts'] as num).toInt(),
      pullContributionRatio:
          (json['pullContributionRatio'] as num).toDouble(),
      descentRiskMultiplier:
          (json['descentRiskMultiplier'] as num).toDouble(),
      shouldLaunchAttack: json['shouldLaunchAttack'] as bool,
      shouldContestKomSprint: json['shouldContestKomSprint'] as bool,
      shouldSwapWheelWithLeader: json['shouldSwapWheelWithLeader'] as bool,
      shouldOrganizeCornerLeadout:
          json['shouldOrganizeCornerLeadout'] as bool,
      shouldLaunchFinal300mAmbush:
          json['shouldLaunchFinal300mAmbush'] as bool,
      targetLateralPositionRoad:
          (json['targetLateralPositionRoad'] as num).toDouble(),
      decisionConfidence: (json['decisionConfidence'] as num).toDouble(),
      radioCommentary: json['radioCommentary'] as String,
    );
  }
}

/// Bazowy kontrakt dla każdego z 6 archetypów osobowości taktycznej AI.
abstract class TacticalAiPersonalityProfile {
  const TacticalAiPersonalityProfile();

  TacticalAiArchetype get archetype;
  AiPersonalityTraits get traits;

  TacticalAiDecision evaluateDecision(TacticalAiRaceContext context);

  int _computeTargetWatts(Rider rider, double ftpFraction) {
    final ftp = math.max(150, rider.physiology.ftpWatts);
    return (ftp * ftpFraction).round().clamp(80, 1800);
  }

  double _deterministicJitter(int seed, String riderId, double amplitude) {
    final hash = riderId.codeUnits.fold<int>(seed, (acc, c) => acc * 31 + c);
    final normalized = ((hash.abs() % 1000) / 500.0) - 1.0; // [-1.0, 1.0)
    return normalized * amplitude;
  }

  double _directorAggressionBoost(DirectorTacticalPhilosophy? philosophy) {
    switch (philosophy) {
      case DirectorTacticalPhilosophy.aggressiveAttacking:
        return 0.08;
      case DirectorTacticalPhilosophy.breakawayGambler:
        return 0.05;
      case DirectorTacticalPhilosophy.cautiousDefensive:
        return -0.07;
      case DirectorTacticalPhilosophy.gcCalculator:
        return -0.03;
      case DirectorTacticalPhilosophy.sprinterTrainSpecialist:
      case null:
        return 0.0;
    }
  }
}

/// 1. `CannibalAttacker` (styl Pogačara): nie czeka na ostatni kilometr – atakuje już
/// na przedostatniej przełęczy 50 km przed metą, jeśli czuje słabość rywali.
class CannibalAttacker extends TacticalAiPersonalityProfile {
  const CannibalAttacker();

  @override
  TacticalAiArchetype get archetype => TacticalAiArchetype.cannibalAttacker;

  @override
  AiPersonalityTraits get traits => const AiPersonalityTraits(
        aggression: 0.96,
        attackDistanceToFinishKm: 50.0,
        ftpPacingDiscipline: 0.45,
        breakawayPullWillingness: 0.78,
        descentRiskAppetite: 0.74,
        komSprintAppetite: 0.70,
        leaderSupportPriority: 0.15,
        lateSprintAmbushMeters: 350.0,
        unpredictabilityFactor: 0.85,
      );

  @override
  TacticalAiDecision evaluateDecision(TacticalAiRaceContext context) {
    final wPrime = context.wPrimeRatio;
    final glycogenOk = context.riderState.currentGlycogen >= 75.0;
    final jitter = _deterministicJitter(
      context.randomSeed,
      context.rider.id,
      0.04,
    );
    final directorBoost = _directorAggressionBoost(context.directorPhilosophy);

    final vulnerableRivals = context.rivalsInGroup
        .where((r) => r.isVulnerable || r.weaknessScore >= 56.0)
        .length;
    final sensesRivalWeakness = vulnerableRivals > 0 ||
        (context.rivalsInGroup.isNotEmpty &&
            context.rivalsInGroup.any((r) => r.isGrinding || r.isDriftingToBack));

    final inLongRangeWindow = context.distanceRemainingKm <= 55.0 &&
        context.distanceRemainingKm >= 8.0;
    final onPenultimateOrClimb = context.isPenultimateOrEarlierMajorClimb ||
        context.currentSegment.isClimb;

    final canLaunchLongAttack = inLongRangeWindow &&
        onPenultimateOrClimb &&
        sensesRivalWeakness &&
        wPrime >= 0.42 &&
        glycogenOk;

    final canLaunchFinalAttack = context.distanceRemainingKm < 8.0 &&
        context.currentSegment.isClimb &&
        wPrime >= 0.30 &&
        glycogenOk;

    if (canLaunchLongAttack || canLaunchFinalAttack) {
      final ftpFraction =
          (1.22 + directorBoost + jitter).clamp(1.12, 1.35);
      return TacticalAiDecision(
        archetype: archetype,
        recommendedOrder: TacticalOrder.attack,
        targetPowerFractionOfFtp: ftpFraction,
        targetWatts: _computeTargetWatts(context.rider, ftpFraction),
        pullContributionRatio: 0.90,
        descentRiskMultiplier: 1.08,
        shouldLaunchAttack: true,
        shouldContestKomSprint: context.isApproachingOrOnKom,
        shouldSwapWheelWithLeader: false,
        shouldOrganizeCornerLeadout: false,
        shouldLaunchFinal300mAmbush: false,
        targetLateralPositionRoad: 0.25,
        decisionConfidence:
            (0.84 + (vulnerableRivals * 0.04) + directorBoost).clamp(0.5, 0.99),
        radioCommentary: canLaunchLongAttack
            ? '${context.rider.lastName} nie czeka na finał! Atakuje ${context.distanceRemainingKm.toStringAsFixed(1)} km przed metą, wyczuwając kryzys rywali!'
            : '${context.rider.lastName} odpala dynamiczny skok pod górę!',
      );
    }

    // Jeśli jest już w ucieczce lub na czele, utrzymuje wysokie tempo
    if (context.isInBreakaway && wPrime >= 0.25) {
      final ftpFraction = (1.03 + jitter * 0.5).clamp(0.95, 1.10);
      return TacticalAiDecision(
        archetype: archetype,
        recommendedOrder: TacticalOrder.pullGroup,
        targetPowerFractionOfFtp: ftpFraction,
        targetWatts: _computeTargetWatts(context.rider, ftpFraction),
        pullContributionRatio: 0.85,
        descentRiskMultiplier: 1.06,
        shouldLaunchAttack: false,
        shouldContestKomSprint: context.isApproachingOrOnKom,
        shouldSwapWheelWithLeader: false,
        shouldOrganizeCornerLeadout: false,
        shouldLaunchFinal300mAmbush: false,
        targetLateralPositionRoad: 0.0,
        decisionConfidence: 0.78,
        radioCommentary:
            '${context.rider.lastName} narzuca wysokie tempo, nie dając rywalom chwili oddechu.',
      );
    }

    final baseFraction = (0.86 + jitter * 0.5).clamp(0.75, 0.95);
    return TacticalAiDecision(
      archetype: archetype,
      recommendedOrder: TacticalOrder.followWheels,
      targetPowerFractionOfFtp: baseFraction,
      targetWatts: _computeTargetWatts(context.rider, baseFraction),
      pullContributionRatio: 0.65,
      descentRiskMultiplier: 1.04,
      shouldLaunchAttack: false,
      shouldContestKomSprint: false,
      shouldSwapWheelWithLeader: false,
      shouldOrganizeCornerLeadout: false,
      shouldLaunchFinal300mAmbush: false,
      targetLateralPositionRoad: 0.1,
      decisionConfidence: 0.72,
      radioCommentary:
          '${context.rider.lastName} obserwuje rywali z czoła grupy i czeka na moment słabości.',
    );
  }
}

/// 2. `DieselCalculator` (styl Vingegaarda / Dumoulina): ignoruje szarpane zrywy rywali,
/// jedzie równym, morderczym tempem według miernika mocy na własnym progu FTP,
/// doganiając przegrzanych atakujących pod szczytem.
class DieselCalculator extends TacticalAiPersonalityProfile {
  const DieselCalculator();

  @override
  TacticalAiArchetype get archetype => TacticalAiArchetype.dieselCalculator;

  @override
  AiPersonalityTraits get traits => const AiPersonalityTraits(
        aggression: 0.42,
        attackDistanceToFinishKm: 12.0,
        ftpPacingDiscipline: 0.98,
        breakawayPullWillingness: 0.65,
        descentRiskAppetite: 0.52,
        komSprintAppetite: 0.35,
        leaderSupportPriority: 0.25,
        lateSprintAmbushMeters: 200.0,
        unpredictabilityFactor: 0.22,
      );

  @override
  TacticalAiDecision evaluateDecision(TacticalAiRaceContext context) {
    final wPrime = context.wPrimeRatio;
    final hasOverheatedAttackers = context.rivalsInGroup
        .any((r) => r.estimatedWPrimeRatio < 0.25 || r.weaknessScore >= 70.0);

    // Na podjeździe lub w pościgu: ignoruje szarpane ataki i trzyma równy próg FTP
    if (context.currentSegment.isClimb) {
      final climbingFraction = (hasOverheatedAttackers &&
              context.isNearClimbSummit &&
              wPrime >= 0.45)
          ? 1.06
          : (wPrime >= 0.20 ? 0.99 : 0.93);

      return TacticalAiDecision(
        archetype: archetype,
        recommendedOrder: TacticalOrder.holdPosition,
        targetPowerFractionOfFtp: climbingFraction,
        targetWatts: _computeTargetWatts(context.rider, climbingFraction),
        pullContributionRatio: 0.70,
        descentRiskMultiplier: 0.96,
        shouldLaunchAttack: false, // Celowo ignoruje zrywy i jedzie z licznika
        shouldContestKomSprint: false,
        shouldSwapWheelWithLeader: false,
        shouldOrganizeCornerLeadout: false,
        shouldLaunchFinal300mAmbush: false,
        targetLateralPositionRoad: 0.0,
        decisionConfidence: 0.93,
        radioCommentary: hasOverheatedAttackers && context.isNearClimbSummit
            ? '${context.rider.lastName} z zegarmistrzowską precyzją na progu FTP dochodzi przegrzanych rywali pod szczytem!'
            : '${context.rider.lastName} ignoruje szarpane zrywy i jedzie równym, morderczym tempem według miernika mocy.',
      );
    }

    // Poza podjazdami utrzymuje stabilną moc podprogową bez zbędnych skoków
    final steadyFraction = context.rivalAttacking ? 0.94 : 0.88;
    return TacticalAiDecision(
      archetype: archetype,
      recommendedOrder: TacticalOrder.holdPosition,
      targetPowerFractionOfFtp: steadyFraction,
      targetWatts: _computeTargetWatts(context.rider, steadyFraction),
      pullContributionRatio: 0.65,
      descentRiskMultiplier: 0.95,
      shouldLaunchAttack: false,
      shouldContestKomSprint: false,
      shouldSwapWheelWithLeader: false,
      shouldOrganizeCornerLeadout: false,
      shouldLaunchFinal300mAmbush: false,
      targetLateralPositionRoad: -0.1,
      decisionConfidence: 0.88,
      radioCommentary:
          '${context.rider.lastName} pilnuje własnych watów i nie daje się wciągnąć w nerwowe przyspieszenia.',
    );
  }
}

/// 3. `WheelsuckerOpportunist`: oszczędza każdą kroplę energii w ucieczce,
/// odmawia dawania mocnych zmian, by wyskoczyć z koła na ostatnich 300 metrach.
class WheelsuckerOpportunist extends TacticalAiPersonalityProfile {
  const WheelsuckerOpportunist();

  @override
  TacticalAiArchetype get archetype =>
      TacticalAiArchetype.wheelsuckerOpportunist;

  @override
  AiPersonalityTraits get traits => const AiPersonalityTraits(
        aggression: 0.25,
        attackDistanceToFinishKm: 0.3,
        ftpPacingDiscipline: 0.60,
        breakawayPullWillingness: 0.04,
        descentRiskAppetite: 0.45,
        komSprintAppetite: 0.20,
        leaderSupportPriority: 0.05,
        lateSprintAmbushMeters: 300.0,
        unpredictabilityFactor: 0.62,
      );

  @override
  TacticalAiDecision evaluateDecision(TacticalAiRaceContext context) {
    final distanceMeters = context.distanceRemainingMeters;
    final wPrime = context.wPrimeRatio;

    // Ostatnie 300 metrów: wyskok z koła pełnym sprintem
    if (distanceMeters <= 300.0 && wPrime >= 0.15) {
      const ambushFraction = 1.55;
      return TacticalAiDecision(
        archetype: archetype,
        recommendedOrder: TacticalOrder.attack,
        targetPowerFractionOfFtp: ambushFraction,
        targetWatts: _computeTargetWatts(context.rider, ambushFraction),
        pullContributionRatio: 0.0,
        descentRiskMultiplier: 1.02,
        shouldLaunchAttack: true,
        shouldContestKomSprint: false,
        shouldSwapWheelWithLeader: false,
        shouldOrganizeCornerLeadout: false,
        shouldLaunchFinal300mAmbush: true,
        targetLateralPositionRoad: 0.45,
        decisionConfidence: 0.94,
        radioCommentary:
            '${context.rider.lastName} po kilometrach jazdy na kole wyskakuje z tunelu na ostatnich 300 metrach!',
      );
    }

    // W ucieczce lub grupie: maksymalna oszczędność, odmowa mocnych zmian
    final draftFraction = context.isInBreakaway ? 0.72 : 0.68;
    return TacticalAiDecision(
      archetype: archetype,
      recommendedOrder: TacticalOrder.saveEnergy,
      targetPowerFractionOfFtp: draftFraction,
      targetWatts: _computeTargetWatts(context.rider, draftFraction),
      pullContributionRatio: 0.03,
      descentRiskMultiplier: 0.92,
      shouldLaunchAttack: false,
      shouldContestKomSprint: false,
      shouldSwapWheelWithLeader: false,
      shouldOrganizeCornerLeadout: false,
      shouldLaunchFinal300mAmbush: false,
      targetLateralPositionRoad: -0.25,
      decisionConfidence: 0.91,
      radioCommentary: context.isInBreakaway
          ? '${context.rider.lastName} odmawia dawania zmian w ucieczce i chowa się głęboko za plecami rywali.'
          : '${context.rider.lastName} oszczędza każdą kroplę energii w głębi szyku, czekając na ostatnie 300 m.',
    );
  }
}

/// 4. `KamikazeDescender`: atakuje na szczycie przełęczy i podejmuje maksymalne
/// ryzyko na krętym zjeździe, zmuszając ostrożniejszych rywali do pogoni w dolinie.
class KamikazeDescender extends TacticalAiPersonalityProfile {
  const KamikazeDescender();

  @override
  TacticalAiArchetype get archetype => TacticalAiArchetype.kamikazeDescender;

  @override
  AiPersonalityTraits get traits => const AiPersonalityTraits(
        aggression: 0.88,
        attackDistanceToFinishKm: 28.0,
        ftpPacingDiscipline: 0.50,
        breakawayPullWillingness: 0.72,
        descentRiskAppetite: 0.99,
        komSprintAppetite: 0.55,
        leaderSupportPriority: 0.12,
        lateSprintAmbushMeters: 250.0,
        unpredictabilityFactor: 0.90,
      );

  @override
  TacticalAiDecision evaluateDecision(TacticalAiRaceContext context) {
    final wPrime = context.wPrimeRatio;

    // 1. Atak na szczycie przełęczy tuż przed krętym zjazdem
    if (context.isNearClimbSummit &&
        (context.hasSteepDescentAhead || context.currentSegment.isClimb) &&
        wPrime >= 0.32) {
      const crestAttackFraction = 1.24;
      return TacticalAiDecision(
        archetype: archetype,
        recommendedOrder: TacticalOrder.attack,
        targetPowerFractionOfFtp: crestAttackFraction,
        targetWatts: _computeTargetWatts(context.rider, crestAttackFraction),
        pullContributionRatio: 0.85,
        descentRiskMultiplier: 1.22,
        shouldLaunchAttack: true,
        shouldContestKomSprint: context.isApproachingOrOnKom,
        shouldSwapWheelWithLeader: false,
        shouldOrganizeCornerLeadout: false,
        shouldLaunchFinal300mAmbush: false,
        targetLateralPositionRoad: 0.35,
        decisionConfidence: 0.90,
        radioCommentary:
            '${context.rider.lastName} atakuje na samym szczycie przełęczy, przygotowując szaleńczy zjazd!',
      );
    }

    // 2. Maksymalne ryzyko na krętym zjeździe
    if (context.currentSegment.isDescent) {
      final isWinding = context.currentSegment.technicalDifficulty >= 45.0;
      final descentPower = isWinding ? 0.96 : 1.04;
      return TacticalAiDecision(
        archetype: archetype,
        recommendedOrder: TacticalOrder.attack,
        targetPowerFractionOfFtp: descentPower,
        targetWatts: _computeTargetWatts(context.rider, descentPower),
        pullContributionRatio: 0.95,
        descentRiskMultiplier: isWinding ? 1.25 : 1.18,
        shouldLaunchAttack: true,
        shouldContestKomSprint: false,
        shouldSwapWheelWithLeader: false,
        shouldOrganizeCornerLeadout: false,
        shouldLaunchFinal300mAmbush: false,
        targetLateralPositionRoad: 0.60, // Agresywne cięcie wierzchołków zakrętów
        decisionConfidence: 0.95,
        radioCommentary:
            '${context.rider.lastName} jedzie na granicy przyczepności na zjeździe, zmuszając rywali do szaleńczej pogoni w dolinie!',
      );
    }

    // 3. Dociskanie w dolinie, by utrzymać przewagę po zjeździe
    final flatFraction = context.isInBreakaway ? 1.02 : 0.85;
    return TacticalAiDecision(
      archetype: archetype,
      recommendedOrder: context.isInBreakaway
          ? TacticalOrder.pullGroup
          : TacticalOrder.followWheels,
      targetPowerFractionOfFtp: flatFraction,
      targetWatts: _computeTargetWatts(context.rider, flatFraction),
      pullContributionRatio: 0.72,
      descentRiskMultiplier: 1.12,
      shouldLaunchAttack: false,
      shouldContestKomSprint: false,
      shouldSwapWheelWithLeader: false,
      shouldOrganizeCornerLeadout: false,
      shouldLaunchFinal300mAmbush: false,
      targetLateralPositionRoad: 0.15,
      decisionConfidence: 0.76,
      radioCommentary:
          '${context.rider.lastName} utrzymuje wysoką prędkość, czekając na kolejny szczyt i techniczny zjazd.',
    );
  }
}

/// 5. `BreakawayHunter`: specjalista od ucieczek, który skacze do każdego odjazdu
/// i walczy o każdą premię górską do koszulki w grochy.
class BreakawayHunter extends TacticalAiPersonalityProfile {
  const BreakawayHunter();

  @override
  TacticalAiArchetype get archetype => TacticalAiArchetype.breakawayHunter;

  @override
  AiPersonalityTraits get traits => const AiPersonalityTraits(
        aggression: 0.91,
        attackDistanceToFinishKm: 110.0,
        ftpPacingDiscipline: 0.58,
        breakawayPullWillingness: 0.92,
        descentRiskAppetite: 0.70,
        komSprintAppetite: 0.99,
        leaderSupportPriority: 0.18,
        lateSprintAmbushMeters: 300.0,
        unpredictabilityFactor: 0.80,
      );

  @override
  TacticalAiDecision evaluateDecision(TacticalAiRaceContext context) {
    final wPrime = context.wPrimeRatio;

    // 1. Walka o każdą premię górską do koszulki w grochy
    if (context.isApproachingOrOnKom && wPrime >= 0.22) {
      const komSprintFraction = 1.28;
      return TacticalAiDecision(
        archetype: archetype,
        recommendedOrder: TacticalOrder.attack,
        targetPowerFractionOfFtp: komSprintFraction,
        targetWatts: _computeTargetWatts(context.rider, komSprintFraction),
        pullContributionRatio: 0.90,
        descentRiskMultiplier: 1.05,
        shouldLaunchAttack: true,
        shouldContestKomSprint: true,
        shouldSwapWheelWithLeader: false,
        shouldOrganizeCornerLeadout: false,
        shouldLaunchFinal300mAmbush: false,
        targetLateralPositionRoad: 0.30,
        decisionConfidence: 0.95,
        radioCommentary:
            '${context.rider.lastName} przyspiesza po punkty do koszulki w grochy na linii premii górskiej!',
      );
    }

    // 2. Skok do każdego formującego się odjazdu
    if (!context.isInBreakaway &&
        (context.isBreakawayForming || context.distanceRemainingKm > 35.0) &&
        wPrime >= 0.35) {
      const breakJumpFraction = 1.20;
      return TacticalAiDecision(
        archetype: archetype,
        recommendedOrder: TacticalOrder.attack,
        targetPowerFractionOfFtp: breakJumpFraction,
        targetWatts: _computeTargetWatts(context.rider, breakJumpFraction),
        pullContributionRatio: 0.95,
        descentRiskMultiplier: 1.05,
        shouldLaunchAttack: true,
        shouldContestKomSprint: false,
        shouldSwapWheelWithLeader: false,
        shouldOrganizeCornerLeadout: false,
        shouldLaunchFinal300mAmbush: false,
        targetLateralPositionRoad: 0.40,
        decisionConfidence: 0.89,
        radioCommentary:
            '${context.rider.lastName} natychmiast skacze do odjazdu — nie odpuszcza żadnej ucieczki dnia!',
      );
    }

    // 3. Solidna współpraca w ucieczce
    final relayFraction = context.isInBreakaway ? 0.98 : 0.82;
    return TacticalAiDecision(
      archetype: archetype,
      recommendedOrder: context.isInBreakaway
          ? TacticalOrder.pullGroup
          : TacticalOrder.followWheels,
      targetPowerFractionOfFtp: relayFraction,
      targetWatts: _computeTargetWatts(context.rider, relayFraction),
      pullContributionRatio: 0.92,
      descentRiskMultiplier: 1.03,
      shouldLaunchAttack: false,
      shouldContestKomSprint: false,
      shouldSwapWheelWithLeader: false,
      shouldOrganizeCornerLeadout: false,
      shouldLaunchFinal300mAmbush: false,
      targetLateralPositionRoad: 0.0,
      decisionConfidence: 0.86,
      radioCommentary: context.isInBreakaway
          ? '${context.rider.lastName} daje mocne, regularne zmiany, by utrzymać ucieczkę przed peletonem.'
          : '${context.rider.lastName} krąży na czole peletonu, szukając okazji do kolejnego skoku.',
    );
  }
}

/// 6. `LoyalRoadCaptain`: weteran, który w ułamku sekundy oddaje własne koło
/// liderowi po defekcie i ustawia zespół przed zakrętami.
class LoyalRoadCaptain extends TacticalAiPersonalityProfile {
  const LoyalRoadCaptain();

  @override
  TacticalAiArchetype get archetype => TacticalAiArchetype.loyalRoadCaptain;

  @override
  AiPersonalityTraits get traits => const AiPersonalityTraits(
        aggression: 0.30,
        attackDistanceToFinishKm: 5.0,
        ftpPacingDiscipline: 0.88,
        breakawayPullWillingness: 0.82,
        descentRiskAppetite: 0.65,
        komSprintAppetite: 0.10,
        leaderSupportPriority: 1.0,
        lateSprintAmbushMeters: 150.0,
        unpredictabilityFactor: 0.18,
      );

  @override
  TacticalAiDecision evaluateDecision(TacticalAiRaceContext context) {
    // 1. Natychmiastowe oddanie własnego koła liderowi po defekcie
    if (context.leaderHasMechanical) {
      const wheelSwapFraction = 0.92;
      return TacticalAiDecision(
        archetype: archetype,
        recommendedOrder: TacticalOrder.protectLeader,
        targetPowerFractionOfFtp: wheelSwapFraction,
        targetWatts: _computeTargetWatts(context.rider, wheelSwapFraction),
        pullContributionRatio: 1.0,
        descentRiskMultiplier: 1.0,
        shouldLaunchAttack: false,
        shouldContestKomSprint: false,
        shouldSwapWheelWithLeader: true,
        shouldOrganizeCornerLeadout: false,
        shouldLaunchFinal300mAmbush: false,
        targetLateralPositionRoad: 0.80, // Zjazd na prawą stronę dla błyskawicznej wymiany koła
        decisionConfidence: 0.99,
        radioCommentary:
            'Defekt lidera! Weteran ${context.rider.lastName} w ułamku sekundy zsiada i oddaje swoje koło liderowi!',
      );
    }

    // 2. Ustawienie zespołu przed technicznymi zakrętami lub brukiem
    if (context.hasTechnicalCornersAhead) {
      const leadoutFraction = 1.04;
      return TacticalAiDecision(
        archetype: archetype,
        recommendedOrder: TacticalOrder.protectLeader,
        targetPowerFractionOfFtp: leadoutFraction,
        targetWatts: _computeTargetWatts(context.rider, leadoutFraction),
        pullContributionRatio: 0.95,
        descentRiskMultiplier: 1.04,
        shouldLaunchAttack: false,
        shouldContestKomSprint: false,
        shouldSwapWheelWithLeader: false,
        shouldOrganizeCornerLeadout: true,
        shouldLaunchFinal300mAmbush: false,
        targetLateralPositionRoad: -0.40, // Czysta linia z przodu szyku przed zakrętem
        decisionConfidence: 0.94,
        radioCommentary:
            '${context.rider.lastName} ustawia cały pociąg zespołu z przodu peletonu przed nadchodzącymi zakrętami.',
      );
    }

    // 3. Stała osłona lidera lub dociąganie lidera z powrotem do czoła
    final needsBridgeForLeader = context.teamLeaderGapToFrontSeconds > 3.0;
    final supportFraction = needsBridgeForLeader ? 1.02 : 0.86;
    return TacticalAiDecision(
      archetype: archetype,
      recommendedOrder: needsBridgeForLeader
          ? TacticalOrder.pullGroup
          : TacticalOrder.protectLeader,
      targetPowerFractionOfFtp: supportFraction,
      targetWatts: _computeTargetWatts(context.rider, supportFraction),
      pullContributionRatio: 0.85,
      descentRiskMultiplier: 0.98,
      shouldLaunchAttack: false,
      shouldContestKomSprint: false,
      shouldSwapWheelWithLeader: false,
      shouldOrganizeCornerLeadout: false,
      shouldLaunchFinal300mAmbush: false,
      targetLateralPositionRoad: -0.15,
      decisionConfidence: 0.90,
      radioCommentary: needsBridgeForLeader
          ? '${context.rider.lastName} bierze lidera na koło i spokojnie redukuje stratę do czoła grupy.'
          : '${context.rider.lastName} osłania lidera przed wiatrem i pilnuje porządku w zespole.',
    );
  }
}

/// Centralny system zarządzania profilami osobowości taktycznych AI dla kolarzy
/// i dyrektorów sportowych w symulacji wyścigu 3D.
class TacticalAiPersonalityProfiles {
  const TacticalAiPersonalityProfiles._();

  static const CannibalAttacker cannibalAttacker = CannibalAttacker();
  static const DieselCalculator dieselCalculator = DieselCalculator();
  static const WheelsuckerOpportunist wheelsuckerOpportunist =
      WheelsuckerOpportunist();
  static const KamikazeDescender kamikazeDescender = KamikazeDescender();
  static const BreakawayHunter breakawayHunter = BreakawayHunter();
  static const LoyalRoadCaptain loyalRoadCaptain = LoyalRoadCaptain();

  /// Pełna lista 6 archetypów AI dostępnych w silniku symulacji.
  static const List<TacticalAiPersonalityProfile> allProfiles = [
    cannibalAttacker,
    dieselCalculator,
    wheelsuckerOpportunist,
    kamikazeDescender,
    breakawayHunter,
    loyalRoadCaptain,
  ];

  /// Zwraca instancję profilu dla wskazanego archetypu.
  static TacticalAiPersonalityProfile forArchetype(
      TacticalAiArchetype archetype) {
    switch (archetype) {
      case TacticalAiArchetype.cannibalAttacker:
        return cannibalAttacker;
      case TacticalAiArchetype.dieselCalculator:
        return dieselCalculator;
      case TacticalAiArchetype.wheelsuckerOpportunist:
        return wheelsuckerOpportunist;
      case TacticalAiArchetype.kamikazeDescender:
        return kamikazeDescender;
      case TacticalAiArchetype.breakawayHunter:
        return breakawayHunter;
      case TacticalAiArchetype.loyalRoadCaptain:
        return loyalRoadCaptain;
    }
  }

  /// Dobiera archetyp AI na podstawie specjalizacji, umiejętności, fizjologii
  /// kolarza oraz filozofii dyrektora sportowego z kontrolowaną nieprzewidywalnością.
  static TacticalAiArchetype assignForRider(
    Rider rider, {
    DirectorTacticalPhilosophy? directorPhilosophy,
    int seed = 0,
  }) {
    final skills = rider.skills;
    final age = rider.age;

    // Ekstremalne umiejętności zjazdowe promują Zjazdowca-Kamikadze
    if (skills.descending >= 86 &&
        rider.specialization != RiderSpecialization.pureSprinter) {
      return TacticalAiArchetype.kamikazeDescender;
    }

    // Doświadczony pomocnik o wysokim raceIq -> Lojalny Kapitan Szosy
    if (rider.specialization == RiderSpecialization.domestiqueEngine &&
        (skills.raceIq >= 75 || age >= 29)) {
      return TacticalAiArchetype.loyalRoadCaptain;
    }

    switch (rider.specialization) {
      case RiderSpecialization.gcClimber:
      case RiderSpecialization.pureClimber:
        final explosiveRatio = rider.physiology.wPrimeJoules /
            math.max(1.0, rider.physiology.weightKg);
        if (directorPhilosophy ==
                DirectorTacticalPhilosophy.aggressiveAttacking ||
            explosiveRatio >= 340.0) {
          return TacticalAiArchetype.cannibalAttacker;
        }
        return TacticalAiArchetype.dieselCalculator;

      case RiderSpecialization.puncher:
        if (skills.descending >= 80) {
          return TacticalAiArchetype.kamikazeDescender;
        }
        return (seed + rider.id.hashCode).abs() % 3 == 0
            ? TacticalAiArchetype.wheelsuckerOpportunist
            : TacticalAiArchetype.cannibalAttacker;

      case RiderSpecialization.breakawaySpecialist:
        return TacticalAiArchetype.breakawayHunter;

      case RiderSpecialization.pureSprinter:
      case RiderSpecialization.versatileSprinter:
        return TacticalAiArchetype.wheelsuckerOpportunist;

      case RiderSpecialization.timeTrialist:
        return TacticalAiArchetype.dieselCalculator;

      case RiderSpecialization.classicCobbles:
        if (directorPhilosophy ==
            DirectorTacticalPhilosophy.aggressiveAttacking) {
          return TacticalAiArchetype.cannibalAttacker;
        }
        return skills.raceIq >= 78
            ? TacticalAiArchetype.loyalRoadCaptain
            : TacticalAiArchetype.wheelsuckerOpportunist;

      case RiderSpecialization.domestiqueEngine:
        return TacticalAiArchetype.loyalRoadCaptain;
    }
  }

  /// Przypisuje osobowości taktyczne dla całego peletonu przed startem etapu.
  static Map<String, TacticalAiArchetype> assignPelotonPersonalities(
    List<Rider> riders, {
    Map<String, DirectorTacticalPhilosophy> teamPhilosophies = const {},
    int raceSeed = 42,
  }) {
    final result = <String, TacticalAiArchetype>{};
    for (var i = 0; i < riders.length; i++) {
      final rider = riders[i];
      final philosophy = teamPhilosophies[rider.contract.teamId];
      result[rider.id] = assignForRider(
        rider,
        directorPhilosophy: philosophy,
        seed: raceSeed + i,
      );
    }
    return result;
  }

  /// Ewaluuje bieżącą decyzję taktyczną kolarza AI w oparciu o jego archetyp.
  static TacticalAiDecision evaluateRiderDecision(
    TacticalAiRaceContext context, {
    TacticalAiArchetype? overrideArchetype,
  }) {
    final archetype = overrideArchetype ??
        assignForRider(
          context.rider,
          directorPhilosophy: context.directorPhilosophy,
          seed: context.randomSeed,
        );
    return forArchetype(archetype).evaluateDecision(context);
  }
}
