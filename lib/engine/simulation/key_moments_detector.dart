import 'dart:math' as math;
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../events/race_incident_engine.dart';
import '../peloton/echelon_crosswind_engine.dart';
import '../peloton/mountain_gc_ai_controller.dart';
import '../peloton/rider_race_state.dart';

/// Rodzaje kluczowych momentów etapu wymuszających zatrzymanie szybkiej symulacji (Fast-Forward)
/// i przełączenie gry w interaktywny tryb 3D.
enum KeyMomentType {
  /// 1. Formowanie ucieczki dnia na pierwszych kilometrach (km 0-15)
  breakawayFormation,

  /// 2a. Wjazd na trudny sektor brukowy (3-5 gwiazdek lub szuter Strade)
  challengingCobbles,

  /// 2b. Wejście w strefę silnego bocznego wiatru (> 25 km/h) grożącego wachlarzami
  severeCrosswindEchelon,

  /// 3a. Atak faworyta klasyfikacji generalnej (GC) na podjeździe
  gcLeaderAttack,

  /// 3b. Wjazd na decydującą wspinaczkę etapu (kategoria 1, HC lub nachylenie > 8.5%)
  decisiveClimb,

  /// 4. Kraksa lub defekt mechaniczny kolarza z drużyny gracza
  playerRiderIncident,

  /// 5. Ostatnie 5 kilometrów do mety etapu (finałowy sprint lub walka o etap)
  finaleFinal5Km;

  String toJson() => name;

  static KeyMomentType fromJson(String value) {
    return KeyMomentType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => KeyMomentType.finaleFinal5Km,
    );
  }

  String get label {
    switch (this) {
      case KeyMomentType.breakawayFormation:
        return 'Formowanie ucieczki dnia';
      case KeyMomentType.challengingCobbles:
        return 'Sektor brukowy!';
      case KeyMomentType.severeCrosswindEchelon:
        return 'Boczny wiatr – Ranty!';
      case KeyMomentType.gcLeaderAttack:
        return 'Atak faworyta GC!';
      case KeyMomentType.decisiveClimb:
        return 'Królewski podjazd';
      case KeyMomentType.playerRiderIncident:
        return 'Alarm w drużynie!';
      case KeyMomentType.finaleFinal5Km:
        return 'Ostatnie 5 km do mety';
    }
  }
}

/// Zdarzenie kluczowego momentu wyścigu generowane przez detektor.
class KeyMomentTrigger {
  final KeyMomentType type;

  /// Kilometr etapu, w którym nastąpiła detekcja [km]
  final double kilometerMark;

  /// Tytuł powiadomienia na ekranie (np. "Wjazd na sektor Carrefour de l'Arbre!")
  final String title;

  /// Szczegółowy opis taktyczny sytuacji
  final String description;

  /// Czy gra powinna natychmiast zatrzymać przyspieszenie i przejść do silnika 3D
  final bool shouldSwitchTo3d;

  /// Sugerowany profil kamery 3D ('helicopter', 'motoLead', 'cockpit', 'teamCar')
  final String recommendedCameraMode;

  /// Identyfikator powiązanego kolarza (np. poszkodowanego lub atakującego)
  final String? relatedRiderId;

  /// Nazwisko powiązanego kolarza
  final String? relatedRiderName;

  /// Indeks powiązanego segmentu trasy
  final int? relatedSegmentIndex;

  /// Unikalny klucz zapobiegający powtórnemu wyzwalaniu tego samego zdarzenia
  final String triggerKey;

  const KeyMomentTrigger({
    required this.type,
    required this.kilometerMark,
    required this.title,
    required this.description,
    this.shouldSwitchTo3d = true,
    required this.recommendedCameraMode,
    this.relatedRiderId,
    this.relatedRiderName,
    this.relatedSegmentIndex,
    required this.triggerKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toJson(),
      'kilometerMark': kilometerMark,
      'title': title,
      'description': description,
      'shouldSwitchTo3d': shouldSwitchTo3d,
      'recommendedCameraMode': recommendedCameraMode,
      'relatedRiderId': relatedRiderId,
      'relatedRiderName': relatedRiderName,
      'relatedSegmentIndex': relatedSegmentIndex,
      'triggerKey': triggerKey,
    };
  }

  factory KeyMomentTrigger.fromJson(Map<String, dynamic> json) {
    return KeyMomentTrigger(
      type: KeyMomentType.fromJson(json['type'] as String),
      kilometerMark: (json['kilometerMark'] as num).toDouble(),
      title: json['title'] as String,
      description: json['description'] as String,
      shouldSwitchTo3d: json['shouldSwitchTo3d'] as bool? ?? true,
      recommendedCameraMode: json['recommendedCameraMode'] as String,
      relatedRiderId: json['relatedRiderId'] as String?,
      relatedRiderName: json['relatedRiderName'] as String?,
      relatedSegmentIndex: (json['relatedSegmentIndex'] as num?)?.toInt(),
      triggerKey: json['triggerKey'] as String,
    );
  }

  @override
  String toString() {
    return 'KeyMomentTrigger(${type.name} at KM ${kilometerMark.toStringAsFixed(1)}: "$title")';
  }
}

/// Stan wewnętrzny detektora kluczowych momentów zapobiegający wielokrotnym triggerom.
class KeyMomentsDetectorState {
  /// Zbiór kluczy zdarzeń, które zostały już wyzwolone w trakcie etapu
  final Set<String> triggeredKeys;

  /// Ostatnio wykryty kluczowy moment
  final KeyMomentTrigger? lastTriggeredMoment;

  /// Historia wszystkich momentów wyzwolonych na etapie
  final List<KeyMomentTrigger> history;

  const KeyMomentsDetectorState({
    this.triggeredKeys = const {},
    this.lastTriggeredMoment,
    this.history = const [],
  });

  bool hasTriggered(String key) => triggeredKeys.contains(key);

  KeyMomentsDetectorState withNewMoment(KeyMomentTrigger moment) {
    final newSet = Set<String>.from(triggeredKeys)..add(moment.triggerKey);
    final newHistory = List<KeyMomentTrigger>.from(history)..add(moment);
    return KeyMomentsDetectorState(
      triggeredKeys: newSet,
      lastTriggeredMoment: moment,
      history: newHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'triggeredKeys': triggeredKeys.toList(),
      'lastTriggeredMoment': lastTriggeredMoment?.toJson(),
      'history': history.map((m) => m.toJson()).toList(),
    };
  }

  factory KeyMomentsDetectorState.fromJson(Map<String, dynamic> json) {
    return KeyMomentsDetectorState(
      triggeredKeys: (json['triggeredKeys'] as List<dynamic>).map((e) => e as String).toSet(),
      lastTriggeredMoment: json['lastTriggeredMoment'] != null
          ? KeyMomentTrigger.fromJson(json['lastTriggeredMoment'] as Map<String, dynamic>)
          : null,
      history: (json['history'] as List<dynamic>)
          .map((e) => KeyMomentTrigger.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Detektor kluczowych momentów wyścigu (Key Moments Detector).
///
/// Monitoruje szybką symulację w tle (Fast-Forward, np. 20x-50x czasu rzeczywistego)
/// i automatycznie pauzuje przyspieszenie, przełączając widok w interaktywny tryb 3D:
/// 1. Formowanie ucieczki dnia (km 0-15): gracz decyduje, czy wysłać zawodnika do odjazdu.
/// 2. Wjazd na trudny sektor bruku (3-5*) lub strefę silnego bocznego wiatru (> 25 km/h).
/// 3. Atak faworyta GC lub wjazd na decydującą wspinaczkę (kat. 1 / HC / > 8.5%).
/// 4. Kraksa lub defekt kolarza z drużyny gracza (decyzja o zmianie roweru / wozie technicznym).
/// 5. Ostatnie 5 km przed metą etapu (pociągi sprinterskie, walka o pozycję, finisz).
class KeyMomentsDetector {
  KeyMomentsDetector._();

  /// Główna metoda detekcji uruchamiana w każdym kroku symulacji.
  ///
  /// Zwraca rekord:
  /// - `trigger`: nowo wykryty kluczowy moment (null jeśli brak nowego zdarzenia)
  /// - `updatedState`: zaktualizowany stan detektora
  static ({KeyMomentTrigger? trigger, KeyMomentsDetectorState updatedState}) evaluateStep({
    required KeyMomentsDetectorState state,
    required double currentKm,
    required RaceStage stage,
    required StageSegment currentSegment,
    required String playerTeamId,
    required List<String> playerRiderIds,
    required Map<String, RiderRaceState> allRiderStates,
    required List<RaceIncidentEvent> stepIncidents,
    MountainTrainPlan? activeMountainPlan,
    CrosswindEchelonResult? crosswindResult,
    bool isBreakawayEstablished = false,
  }) {
    final double stageLengthKm = stage.totalDistanceKm;
    final double distToFinishKm = math.max(0.0, stageLengthKm - currentKm);

    // -------------------------------------------------------------
    // REGUŁA 4: KRAKSA LUB DEFEKT KOLARZA GRACZA (NAJWYŻSZY PRIORYTET)
    // -------------------------------------------------------------
    for (final incident in stepIncidents) {
      for (final victim in incident.primaryVictims) {
        if (victim.teamId == playerTeamId || playerRiderIds.contains(victim.riderId)) {
          final String triggerKey = 'incident_${incident.type.name}_${victim.riderId}_${currentKm.round()}';
          if (!state.hasTriggered(triggerKey)) {
            final bool isCrash = incident.type == IncidentType.pelotonPileup || incident.type == IncidentType.soloCrash;

            final moment = KeyMomentTrigger(
              type: KeyMomentType.playerRiderIncident,
              kilometerMark: currentKm,
              title: isCrash ? 'KRAKSA TWOJEGO KOLARZA!' : 'DEFEKT SPRZĘTU W TWOIM ZESPOLE!',
              description: victim.description,
              shouldSwitchTo3d: true,
              recommendedCameraMode: isCrash ? 'teamCar' : 'cockpit',
              relatedRiderId: victim.riderId,
              relatedRiderName: victim.riderName,
              triggerKey: triggerKey,
            );

            return (trigger: moment, updatedState: state.withNewMoment(moment));
          }
        }
      }
    }

    // -------------------------------------------------------------
    // REGUŁA 5: OSTATNIE 5 KM PRZED METĄ ETAPU
    // -------------------------------------------------------------
    if (distToFinishKm <= 5.0 && distToFinishKm > 0.0) {
      const String triggerKey = 'moment_finale_final_5km';
      if (!state.hasTriggered(triggerKey)) {
        final moment = KeyMomentTrigger(
          type: KeyMomentType.finaleFinal5Km,
          kilometerMark: currentKm,
          title: 'OSTATNIE 5 KILOMETRÓW ETAPU!',
          description: 'Peleton wkracza w decydującą fazę. Przejście do widoku 3D na finałowe kilometry i sprint!',
          shouldSwitchTo3d: true,
          recommendedCameraMode: 'motoLead',
          triggerKey: triggerKey,
        );

        return (trigger: moment, updatedState: state.withNewMoment(moment));
      }
    }

    // -------------------------------------------------------------
    // REGUŁA 3: ATAK FAWORYTA GC LUB DECYDUJĄCY PODJAZD
    // -------------------------------------------------------------
    // A) Atak lidera GC:
    if (activeMountainPlan != null && activeMountainPlan.shouldLaunchLeaderAttack) {
      final String triggerKey = 'gc_attack_${currentSegment.index}';
      if (!state.hasTriggered(triggerKey)) {
        final moment = KeyMomentTrigger(
          type: KeyMomentType.gcLeaderAttack,
          kilometerMark: currentKm,
          title: 'DECYDUJĄCY ATAK FAWORYTA GC!',
          description: activeMountainPlan.tacticalReasoning,
          shouldSwitchTo3d: true,
          recommendedCameraMode: 'helicopter',
          relatedRiderId: activeMountainPlan.gcLeaderId,
          relatedSegmentIndex: currentSegment.index,
          triggerKey: triggerKey,
        );

        return (trigger: moment, updatedState: state.withNewMoment(moment));
      }
    }

    // B) Wjazd na decydującą wspinaczkę (kat. 1, HC lub nachylenie >= 8.5%):
    final bool isDecisiveClimb = currentSegment.isClimb &&
        (currentSegment.sprintOrKomClassification == SegmentClassification.cat1 ||
            currentSegment.sprintOrKomClassification == SegmentClassification.horsCategorie ||
            currentSegment.gradientPercent >= 8.5);

    if (isDecisiveClimb) {
      final String triggerKey = 'decisive_climb_segment_${currentSegment.index}';
      if (!state.hasTriggered(triggerKey)) {
        final moment = KeyMomentTrigger(
          type: KeyMomentType.decisiveClimb,
          kilometerMark: currentKm,
          title: 'WJAZD NA KLUCZOWY PODJAZD (${currentSegment.gradientPercent.toStringAsFixed(1)}%)!',
          description: 'Rozpoczyna się selektywny odcinek góry [Kategoria ${currentSegment.sprintOrKomClassification.name}]. Przełączenie w tryb 3D.',
          shouldSwitchTo3d: true,
          recommendedCameraMode: 'helicopter',
          relatedSegmentIndex: currentSegment.index,
          triggerKey: triggerKey,
        );

        return (trigger: moment, updatedState: state.withNewMoment(moment));
      }
    }

    // -------------------------------------------------------------
    // REGUŁA 2: TRUDNY SEKTOR BRUKU LUB SILNY WIATR BOCZNY
    // -------------------------------------------------------------
    // A) Sektor brukowy (3, 4, 5 gwiazdek lub toskański szuter):
    final bool isSevereCobble = currentSegment.surfaceType == SegmentSurfaceType.cobblestonesSector3 ||
        currentSegment.surfaceType == SegmentSurfaceType.cobblestonesSector4 ||
        currentSegment.surfaceType == SegmentSurfaceType.cobblestonesSector5 ||
        currentSegment.surfaceType == SegmentSurfaceType.gravelStrade;

    if (isSevereCobble) {
      final String triggerKey = 'cobble_segment_${currentSegment.index}';
      if (!state.hasTriggered(triggerKey)) {
        final moment = KeyMomentTrigger(
          type: KeyMomentType.challengingCobbles,
          kilometerMark: currentKm,
          title: 'WJAZD NA SEKTOR BRUKOWY (${currentSegment.surfaceType.name})!',
          description: 'Peleton wjeżdża na trudną nawierzchnię. Wysokie ryzyko defektów i walka o pozycję!',
          shouldSwitchTo3d: true,
          recommendedCameraMode: 'lowBicycleHero',
          relatedSegmentIndex: currentSegment.index,
          triggerKey: triggerKey,
        );

        return (trigger: moment, updatedState: state.withNewMoment(moment));
      }
    }

    // B) Silny wiatr boczny (> 25 km/h) i formowanie wachlarzy:
    if (crosswindResult != null && crosswindResult.isEchelonActive) {
      final String triggerKey = 'crosswind_echelon_segment_${currentSegment.index}';
      if (!state.hasTriggered(triggerKey)) {
        final moment = KeyMomentTrigger(
          type: KeyMomentType.severeCrosswindEchelon,
          kilometerMark: currentKm,
          title: 'UWAGA! BOCZNY WIATR I WACHLARZE (${crosswindResult.crosswindSpeedKmh.toStringAsFixed(0)} KM/H)!',
          description: 'Peleton pęka na rantach! Pojemność wachlarza wynosi tylko ${crosswindResult.echelonCapacity} kolarzy.',
          shouldSwitchTo3d: true,
          recommendedCameraMode: 'helicopter',
          relatedSegmentIndex: currentSegment.index,
          triggerKey: triggerKey,
        );

        return (trigger: moment, updatedState: state.withNewMoment(moment));
      }
    }

    // -------------------------------------------------------------
    // REGUŁA 1: FORMOWANIE UCIECZKI DNIA (KM 0 - 15)
    // -------------------------------------------------------------
    if (currentKm >= 1.0 && currentKm <= 15.0 && !isBreakawayEstablished) {
      const String triggerKey = 'moment_breakaway_formation_start';
      if (!state.hasTriggered(triggerKey)) {
        final moment = KeyMomentTrigger(
          type: KeyMomentType.breakawayFormation,
          kilometerMark: currentKm,
          title: 'FORMOWANIE UCIECZKI DNIA (KM 0-15)!',
          description: 'Opuszczona flaga startu ostrego! Początek ataków – Twoja szansa na wysłanie kolarza do ucieczki.',
          shouldSwitchTo3d: true,
          recommendedCameraMode: 'motoLead',
          triggerKey: triggerKey,
        );

        return (trigger: moment, updatedState: state.withNewMoment(moment));
      }
    }

    return (trigger: null, updatedState: state);
  }
}

