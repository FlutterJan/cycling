import 'dart:math' as math;
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_physiology.dart';
import 'drafting_grid_system.dart';
import 'rider_race_state.dart';

/// Faza taktyczna rozgrywania finałowego podjazdu przez zespół faworyta GC.
enum MountainTacticalPhase {
  /// Pociąg górski: pomocnicy narzucają mordercze tempo (5.8 - 6.2 W/kg), by wykruszyć rywali
  tempoDrill,

  /// Monitorowanie rywali i oczekiwanie na najbardziej stromy odcinek (>9%)
  scoutingRivals,

  /// Odpalenie ataku nadprogowego przez lidera GC (wykorzystanie zapasu W')
  launchingAttack,

  /// Samotna wspinaczka lidera do szczytu (utrzymywanie wypracowanej przewagi)
  soloClimbToSummit,

  /// Taktyka defensywna: pilnowanie koła atakującego rywala (odpowiedź na atak)
  defensiveMarking;

  String toJson() => name;

  static MountainTacticalPhase fromJson(String value) {
    return MountainTacticalPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MountainTacticalPhase.tempoDrill,
    );
  }
}

/// Ocena stanu fizjologicznego i taktycznego rywala na wspinaczce.
class RivalClimbingAssessment {
  final String riderId;

  /// Rzeczywista kadencja rywala [RPM]
  final int cadenceRpm;

  /// Czy rywal "kręci kwadratowo" pod górę z niską kadencją (< 78 RPM)
  final bool isGrinding;

  /// Pozycja rywala w szyku grupy (1 = czoło, wyższe liczby = dalej w głąb)
  final int rowInGroup;

  /// Czy rywal spływa na koniec czuba grupy (traci pozycje)
  final bool isDriftingToBack;

  /// Szacowany poziom naładowania baterii beztlenowej W' rywala (0.0 - 1.0)
  final double estimatedWPrimeRatio;

  /// Syntetyczny wskaźnik słabości rywala [0.0 - 100.0] (> 65 = rywal gotowy do zerwania)
  final double weaknessScore;

  /// Czy rywal wykazuje krytyczne oznaki słabości
  bool get isVulnerable => weaknessScore >= 65.0;

  const RivalClimbingAssessment({
    required this.riderId,
    required this.cadenceRpm,
    required this.isGrinding,
    required this.rowInGroup,
    required this.isDriftingToBack,
    required this.estimatedWPrimeRatio,
    required this.weaknessScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'cadenceRpm': cadenceRpm,
      'isGrinding': isGrinding,
      'rowInGroup': rowInGroup,
      'isDriftingToBack': isDriftingToBack,
      'estimatedWPrimeRatio': estimatedWPrimeRatio,
      'weaknessScore': weaknessScore,
    };
  }

  factory RivalClimbingAssessment.fromJson(Map<String, dynamic> json) {
    return RivalClimbingAssessment(
      riderId: json['riderId'] as String,
      cadenceRpm: (json['cadenceRpm'] as num).toInt(),
      isGrinding: json['isGrinding'] as bool,
      rowInGroup: (json['rowInGroup'] as num).toInt(),
      isDriftingToBack: json['isDriftingToBack'] as bool,
      estimatedWPrimeRatio: (json['estimatedWPrimeRatio'] as num).toDouble(),
      weaknessScore: (json['weaknessScore'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'RivalClimbingAssessment($riderId, cad: ${cadenceRpm}rpm, grind: $isGrinding, '
        'row: $rowInGroup, drift: $isDriftingToBack, weakScore: ${weaknessScore.toStringAsFixed(0)})';
  }
}

/// Decyzja taktyczna kontrolera góry dla zespołu i lidera GC.
class MountainTrainPlan {
  final MountainTacticalPhase phase;

  /// Identyfikator lidera klasyfikacji generalnej zespołu
  final String gcLeaderId;

  /// Identyfikator kolarza aktualnie prowadzącego pociąg górski (lub lidera, jeśli atakuje)
  final String activePacemakerId;

  /// Docelowa intensywność pociągu górskiego lub ataku w W/kg (np. 5.8 - 6.2 W/kg)
  final double targetWattsPerKg;

  /// Docelowa bezwzględna moc mechaniczna dla aktualnego prowadzącego [W]
  final int targetWatts;

  /// Czy lider GC powinien w tej sekundzie odpalić atak nadprogowy
  final bool shouldLaunchLeaderAttack;

  /// Analiza stanu rywali na podjeździe
  final List<RivalClimbingAssessment> assessedRivals;

  /// Uzasadnienie decyzji taktycznej dyrektora sportowego
  final String tacticalReasoning;

  const MountainTrainPlan({
    required this.phase,
    required this.gcLeaderId,
    required this.activePacemakerId,
    required this.targetWattsPerKg,
    required this.targetWatts,
    required this.shouldLaunchLeaderAttack,
    required this.assessedRivals,
    required this.tacticalReasoning,
  });

  Map<String, dynamic> toJson() {
    return {
      'phase': phase.toJson(),
      'gcLeaderId': gcLeaderId,
      'activePacemakerId': activePacemakerId,
      'targetWattsPerKg': targetWattsPerKg,
      'targetWatts': targetWatts,
      'shouldLaunchLeaderAttack': shouldLaunchLeaderAttack,
      'assessedRivals': assessedRivals.map((r) => r.toJson()).toList(),
      'tacticalReasoning': tacticalReasoning,
    };
  }

  factory MountainTrainPlan.fromJson(Map<String, dynamic> json) {
    return MountainTrainPlan(
      phase: MountainTacticalPhase.fromJson(json['phase'] as String),
      gcLeaderId: json['gcLeaderId'] as String,
      activePacemakerId: json['activePacemakerId'] as String,
      targetWattsPerKg: (json['targetWattsPerKg'] as num).toDouble(),
      targetWatts: (json['targetWatts'] as num).toInt(),
      shouldLaunchLeaderAttack: json['shouldLaunchLeaderAttack'] as bool,
      assessedRivals: (json['assessedRivals'] as List<dynamic>)
          .map((e) => RivalClimbingAssessment.fromJson(e as Map<String, dynamic>))
          .toList(),
      tacticalReasoning: json['tacticalReasoning'] as String,
    );
  }

  @override
  String toString() {
    return 'MountainTrainPlan(${phase.name}, pacemaker: $activePacemakerId, '
        '${targetWattsPerKg.toStringAsFixed(2)} W/kg (${targetWatts}W), attack: $shouldLaunchLeaderAttack)';
  }
}

/// Kontroler sztucznej inteligencji rozgrywania finałowych wspinaczek przez faworytów GC.
///
/// Implementuje:
/// 1. Taktykę "pociągu górskiego" (Mountain Train):
///    Drużyna lidera ustawia 2-3 pomocników narzucających mordercze tempo (5.8 - 6.2 W/kg),
///    aby wykruszyć peleton, uniemożliwić rywalom niespodziewane ataki i dowieźć lidera
///    wypoczętego na kluczowy fragment góry.
/// 2. Monitorowanie słabości rywali:
///    AI analizuje kadencję rywali (< 78 RPM - "kręcenie kwadratowe") oraz ich pozycję w szyku
///    (spływanie na koniec czuba grupy).
/// 3. Odpalenie ataku nadprogowego:
///    Gdy rywale słabną, a nachylenie segmentu przekracza 9% (gdzie drafting prawie nie działa,
///    a liczy się czysty W/kg), lider odpala potężny atak beztlenowy (7.2 - 8.5 W/kg) czerpiąc
///    ze swojego zapasu W'.
class MountainGcAiController {
  MountainGcAiController._();

  /// Próg nachylenia drogi faworyzujący atak lidera GC (> 9.0%)
  static const double steepRampThresholdGradient = 9.0;

  /// Kadencja graniczna świadcząca o "kręceniu kwadratowym" pod górę [RPM]
  static const int grindingCadenceThresholdRpm = 78;

  /// Ocenia stan fizyczny i pozycję pojedynczego rywala na wspinaczce.
  static RivalClimbingAssessment assessRivalClimbingState({
    required RiderRaceState rivalState,
    required RiderPhysiology rivalPhysiology,
    required PelotonGroup group,
  }) {
    // 1. Kadencja: niska kadencja na stromym podjeździe (< 78 RPM) oznacza walkę z przełożeniem
    final bool isGrinding = rivalState.currentCadenceRpm > 0 &&
        rivalState.currentCadenceRpm < grindingCadenceThresholdRpm;

    // 2. Pozycja w szyku: kolarze silni jadą w 1. lub 2. rzędzie, słabnący spływają na 3. rząd i dalej
    final gridPos = group.getPositionForRider(rivalState.riderId);
    final int rowInGroup = gridPos?.rowIndex ?? 3;
    final bool isDriftingToBack = rowInGroup >= 2;

    // 3. Poziom energii beztlenowej W'
    final double maxW = math.max(1000.0, rivalPhysiology.wPrimeJoules.toDouble());
    final double wPrimeRatio = (rivalState.currentWPrime / maxW).clamp(0.0, 1.0);

    // 4. Syntetyczny wskaźnik słabości [0 - 100]
    double weakness = 0.0;
    if (isGrinding) weakness += 35.0;
    if (isDriftingToBack) weakness += (rowInGroup >= 3 ? 40.0 : 25.0);
    if (wPrimeRatio < 0.35) weakness += 30.0;
    if (wPrimeRatio < 0.15) weakness += 20.0;

    return RivalClimbingAssessment(
      riderId: rivalState.riderId,
      cadenceRpm: rivalState.currentCadenceRpm,
      isGrinding: isGrinding,
      rowInGroup: rowInGroup,
      isDriftingToBack: isDriftingToBack,
      estimatedWPrimeRatio: wPrimeRatio,
      weaknessScore: weakness.clamp(0.0, 100.0),
    );
  }

  /// Główna metoda planująca taktykę górską zespołu GC w danej sekundzie wyścigu.
  ///
  /// Parametry:
  /// - [gcLeader]: kolarz będący liderem GC zespołu
  /// - [gcLeaderState]: aktualny stan lidera ([RiderRaceState])
  /// - [mountainDomestiques]: lista pomocników górskich w zespole (np. 2-3 kolarzy)
  /// - [domestiqueStates]: mapa id pomocnika -> [RiderRaceState]
  /// - [rivalStates]: mapa id rywali GC -> [RiderRaceState]
  /// - [rivalsMap]: mapa id rywali GC -> [Rider]
  /// - [group]: czołowa grupa faworytów ([PelotonGroup])
  /// - [currentSegment]: aktualny segment trasy ([StageSegment])
  /// - [distanceToSummitKm]: dystans pozostały do szczytu podjazdu / mety [km]
  static MountainTrainPlan evaluateMountainTactics({
    required Rider gcLeader,
    required RiderRaceState gcLeaderState,
    required List<Rider> mountainDomestiques,
    required Map<String, RiderRaceState> domestiqueStates,
    required Map<String, RiderRaceState> rivalStates,
    required Map<String, Rider> rivalsMap,
    required PelotonGroup group,
    required StageSegment currentSegment,
    required double distanceToSummitKm,
  }) {
    final double currentGradient = currentSegment.gradientPercent;
    final bool isSteepRamp = currentGradient >= steepRampThresholdGradient;

    // 1. Analiza stanu rywali GC
    final List<RivalClimbingAssessment> rivalAssessments = [];
    int vulnerableRivalsCount = 0;

    for (final entry in rivalStates.entries) {
      final rival = rivalsMap[entry.key];
      if (rival == null) continue;

      final assessment = assessRivalClimbingState(
        rivalState: entry.value,
        rivalPhysiology: rival.physiology,
        group: group,
      );

      rivalAssessments.add(assessment);
      if (assessment.isVulnerable) {
        vulnerableRivalsCount++;
      }
    }

    // 2. Weryfikacja dostępności pomocników w pociągu górskim:
    // Wybieramy pierwszego zdolnego do pracy pomocnika, który ma jeszcze zapas sił (W' > 2500 J)
    Rider? activeDomestique;
    for (final dom in mountainDomestiques) {
      final state = domestiqueStates[dom.id];
      if (state != null && state.currentWPrime > 2500.0) {
        // Pomocnik musi być z przodu grupy (rząd 0 lub 1)
        activeDomestique = dom;
        break;
      }
    }

    // 3. Stan zapasu beztlenowego lidera GC
    final double leaderMaxW = math.max(1000.0, gcLeader.physiology.wPrimeJoules.toDouble());
    final double leaderWPrimeRatio = gcLeaderState.currentWPrime / leaderMaxW;
    final bool leaderHasPunchForAttack = leaderWPrimeRatio >= 0.55 && gcLeaderState.currentWPrime >= 10000.0;

    // 4. Warunki odpalenia ataku przez lidera GC:
    // - Jesteśmy na stromym fragmencie góry (>9%), GDZIE DRAFTING NIE CHRONI RYWALI
    // - Co najmniej 1 rywal wykazuje słabość (niska kadencja / spływanie) LUB do szczytu zostało < 4 km
    // - Lider ma wystarczający zapas energii beztlenowej W'
    final bool shouldAttackNow = isSteepRamp &&
        leaderHasPunchForAttack &&
        (vulnerableRivalsCount > 0 || distanceToSummitKm <= 4.0 || activeDomestique == null);

    // -------------------------------------------------------------
    // SCENARIUSZ A: Lider odpala atak nadprogowy na stromiźnie (>9%)
    // -------------------------------------------------------------
    if (shouldAttackNow) {
      // Atak beztlenowy: 7.2 do 8.2 W/kg w zależności od zrywności kolarza
      final double attackWattsPerKg = 7.4 + ((gcLeader.skills.bikeHandling - 50) / 100.0) * 0.8;
      final int attackWatts = (gcLeader.physiology.weightKg * attackWattsPerKg).round();

      String reason;
      if (isSteepRamp && vulnerableRivalsCount > 0) {
        reason = 'Atak na stromej ściance (${currentGradient.toStringAsFixed(1)}%)! Rywale kręcą kwadratowo, lider urywa grupę!';
      } else if (distanceToSummitKm <= 3.5) {
        reason = 'Decydujący atak w końcówce wspinaczki (${distanceToSummitKm.toStringAsFixed(1)} km do szczytu)!';
      } else {
        reason = 'Samodzielny skok faworyta GC po wyczerpaniu pracy pomocników.';
      }

      return MountainTrainPlan(
        phase: MountainTacticalPhase.launchingAttack,
        gcLeaderId: gcLeader.id,
        activePacemakerId: gcLeader.id,
        targetWattsPerKg: attackWattsPerKg,
        targetWatts: attackWatts,
        shouldLaunchLeaderAttack: true,
        assessedRivals: rivalAssessments,
        tacticalReasoning: reason,
      );
    }

    // -------------------------------------------------------------
    // SCENARIUSZ B: Pociąg górski pomocników (5.8 - 6.2 W/kg)
    // -------------------------------------------------------------
    if (activeDomestique != null) {
      // Im bliżej stromego odcinka lub szczytu, tym mocniejszy ogień z pociągu (od 5.8 do 6.2 W/kg)
      final double trainIntensity = distanceToSummitKm < 6.0 ? 6.15 : 5.85;
      final int trainWatts = (activeDomestique.physiology.weightKg * trainIntensity).round();

      return MountainTrainPlan(
        phase: MountainTacticalPhase.tempoDrill,
        gcLeaderId: gcLeader.id,
        activePacemakerId: activeDomestique.id,
        targetWattsPerKg: trainIntensity,
        targetWatts: trainWatts,
        shouldLaunchLeaderAttack: false,
        assessedRivals: rivalAssessments,
        tacticalReasoning: 'Pociąg górski narzuca ostre tempo (${trainIntensity.toStringAsFixed(2)} W/kg) przez pomocnika [${activeDomestique.lastName}]. Wykruszanie peletonu.',
      );
    }

    // -------------------------------------------------------------
    // SCENARIUSZ C: Oczekiwanie i badanie rywali (Scouting)
    // -------------------------------------------------------------
    // Brak pomocników, ale nachylenie nie jest jeszcze wystarczająco strome (< 9%) – lider jedzie czujnie w kołach
    const double steadyClimbWkg = 5.70;
    final int steadyWatts = (gcLeader.physiology.weightKg * steadyClimbWkg).round();

    return MountainTrainPlan(
      phase: MountainTacticalPhase.scoutingRivals,
      gcLeaderId: gcLeader.id,
      activePacemakerId: gcLeader.id,
      targetWattsPerKg: steadyClimbWkg,
      targetWatts: steadyWatts,
      shouldLaunchLeaderAttack: false,
      assessedRivals: rivalAssessments,
      tacticalReasoning: 'Lider GC jedzie czujnie w czubie grupy, czekając na stromiznę (>9%) do zadania decydującego ciosu.',
    );
  }
}

