import 'dart:math' as math;
import '../../models/equipment/complete_bike.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_health.dart';
import '../../models/rider/rider_skills.dart';
import '../peloton/drafting_grid_system.dart';

/// Rodzaj incydentu losowego na trasie etapu.
enum IncidentType {
  /// Przebicie opony (kapelusz / snejk / szkło)
  punctureFlatTire,

  /// Awaria mechaniczna (spadnięty łańcuch, uszkodzona przerzutka, pęknięta szprycha)
  mechanicalFailure,

  /// Pojedynczy poślizg / kraksa kolarza (np. na mokrym pasie lub zakręcie)
  soloCrash,

  /// Zbiorowa kraksa w peletonie (efekt domina na dużej prędkości)
  pelotonPileup,

  /// Zablokowanie szosy przez leżące rowery (postój bez upadku)
  roadBlockage;

  String toJson() => name;

  static IncidentType fromJson(String value) {
    return IncidentType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => IncidentType.punctureFlatTire,
    );
  }
}

/// Sposób rozwiązania problemu i powrotu kolarza do wyścigu.
enum AssistanceMethod {
  /// Oddanie całego roweru przez pomocnika z drużyny (błyskawiczna wymiana ~14s)
  teammateBikeSwap,

  /// Wymiana koła lub roweru z wozu technicznego drużyny (~35-65s)
  teamCarService,

  /// Pomoc z neutralnego wozu technicznego Shimano/Mavic (~25-45s)
  neutralService,

  /// Samodzielne podniesienie roweru, poprawienie łańcucha i start (~10-20s)
  selfRemount;

  String toJson() => name;

  static AssistanceMethod fromJson(String value) {
    return AssistanceMethod.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AssistanceMethod.teamCarService,
    );
  }
}

/// Poszkodowany uczestnik incydentu wyścigowego.
class IncidentVictim {
  final String riderId;
  final String riderName;
  final String teamId;
  final IncidentType incidentType;

  /// Stracony czas w sekundach z powodu postoju [s]
  final double timeLostSeconds;

  /// Odniesiona kontuzja (jeśli wystąpiła)
  final Injury? injury;

  /// Czy kolarz został zmuszony do wycofania się z wyścigu (Did Not Finish)
  final bool isDnf;

  /// Sposób udzielonej pomocy technicznej
  final AssistanceMethod assistanceMethod;

  /// Identyfikator poświęconego pomocnika (jeśli oddał swój rower liderowi)
  final String? sacrificedTeammateId;

  /// Czytelny opis zdarzenia dla relacji live
  final String description;

  const IncidentVictim({
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.incidentType,
    required this.timeLostSeconds,
    this.injury,
    required this.isDnf,
    required this.assistanceMethod,
    this.sacrificedTeammateId,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'teamId': teamId,
      'incidentType': incidentType.toJson(),
      'timeLostSeconds': timeLostSeconds,
      'injury': injury?.toJson(),
      'isDnf': isDnf,
      'assistanceMethod': assistanceMethod.toJson(),
      'sacrificedTeammateId': sacrificedTeammateId,
      'description': description,
    };
  }

  factory IncidentVictim.fromJson(Map<String, dynamic> json) {
    return IncidentVictim(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      teamId: json['teamId'] as String,
      incidentType: IncidentType.fromJson(json['incidentType'] as String),
      timeLostSeconds: (json['timeLostSeconds'] as num).toDouble(),
      injury: json['injury'] != null ? Injury.fromJson(json['injury'] as Map<String, dynamic>) : null,
      isDnf: json['isDnf'] as bool,
      assistanceMethod: AssistanceMethod.fromJson(json['assistanceMethod'] as String),
      sacrificedTeammateId: json['sacrificedTeammateId'] as String?,
      description: json['description'] as String,
    );
  }

  @override
  String toString() {
    return 'IncidentVictim($riderName, type: ${incidentType.name}, lost: ${timeLostSeconds.toStringAsFixed(0)}s, DNF: $isDnf)';
  }
}

/// Zdarzenie losowe na trasie etapu (kraksa, defekt, blokada szosy).
class RaceIncidentEvent {
  final String id;
  final double kilometerMark;
  final IncidentType type;

  /// Główni poszkodowani kolarze (upadki lub defekty)
  final List<IncidentVictim> primaryVictims;

  /// Kolarze zablokowani za kraksą (zatrzymani bez upadku)
  final List<String> heldUpRiderIds;

  /// Czas stracony przez kolarzy zablokowanych za kraksą [s]
  final double blockageDelaySeconds;

  /// Czy szosa została całkowicie zablokowana przez rowery
  final bool isRoadBlocked;

  /// Komunikat Radia Wyścigu (Radio Tour)
  final String radioReport;

  const RaceIncidentEvent({
    required this.id,
    required this.kilometerMark,
    required this.type,
    required this.primaryVictims,
    required this.heldUpRiderIds,
    this.blockageDelaySeconds = 0.0,
    required this.isRoadBlocked,
    required this.radioReport,
  });

  /// Czy w wyniku incydentu którykolwiek kolarz wycofał się z wyścigu (DNF)
  bool get hasDnf => primaryVictims.any((v) => v.isDnf);

  /// Lista kolarzy, którzy musieli wycofać się z wyścigu
  List<IncidentVictim> get dnfVictims => primaryVictims.where((v) => v.isDnf).toList();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kilometerMark': kilometerMark,
      'type': type.toJson(),
      'primaryVictims': primaryVictims.map((v) => v.toJson()).toList(),
      'heldUpRiderIds': heldUpRiderIds,
      'blockageDelaySeconds': blockageDelaySeconds,
      'isRoadBlocked': isRoadBlocked,
      'radioReport': radioReport,
    };
  }

  factory RaceIncidentEvent.fromJson(Map<String, dynamic> json) {
    return RaceIncidentEvent(
      id: json['id'] as String,
      kilometerMark: (json['kilometerMark'] as num).toDouble(),
      type: IncidentType.fromJson(json['type'] as String),
      primaryVictims: (json['primaryVictims'] as List<dynamic>)
          .map((e) => IncidentVictim.fromJson(e as Map<String, dynamic>))
          .toList(),
      heldUpRiderIds: (json['heldUpRiderIds'] as List<dynamic>).map((e) => e as String).toList(),
      blockageDelaySeconds: (json['blockageDelaySeconds'] as num?)?.toDouble() ?? 0.0,
      isRoadBlocked: json['isRoadBlocked'] as bool,
      radioReport: json['radioReport'] as String,
    );
  }

  @override
  String toString() {
    return 'RaceIncidentEvent(${type.name} at ${kilometerMark.toStringAsFixed(1)}km, victims: ${primaryVictims.length}, DNF: $hasDnf)';
  }
}

/// Silnik zdarzeń losowych i zbiegów okoliczności podczas etapu wyścigu.
///
/// Modeluje:
/// 1. Defekty mechaniczne i przebicia opon:
///    - Prawdopodobieństwo zależne od nawierzchni (bruk 1-5, szuter Strade, chropowaty asfalt),
///      opony ([CompleteBike.punctureRiskFactor]) oraz deszczu (woda wypłukuje odłamki krzemienia i szkła).
///    - Skutki: postój, czekanie na wóz techniczny drużyny LUB natychmiastowe oddanie roweru przez pomocnika!
/// 2. Kraksy w peletonie:
///    - Prawdopodobieństwo zależne od zakrętów i zwężeń ([StageSegment.technicalDifficulty]),
///      prędkości peletonu (> 60 km/h), deszczu, bruku oraz nerwowości finału (< 20 km do mety).
///    - Skutki: zablokowanie szosy dla grupy kolarzy z tyłu, uszkodzenie sprzętu lub groźna kontuzja
///      (np. złamanie obojczyka [InjuryType.clavicleFracture] kończące wyścig DNF).
class RaceIncidentEngine {
  RaceIncidentEngine._();

  /// Oblicza prawdopodobieństwo przebicia opony dla pojedynczego kolarza na odcinku 1 km.
  static double calculatePunctureProbabilityPerKm({
    required SegmentSurfaceType surfaceType,
    required WeatherCondition weatherCondition,
    required double bikePunctureRiskFactor,
  }) {
    // Bazowe ryzyko na gładkim suchym asfalcie (~0.012% na km)
    double baseRisk = 0.00012;

    // 1. Mnożnik nawierzchni
    switch (surfaceType) {
      case SegmentSurfaceType.smoothAsphalt:
      case SegmentSurfaceType.concrete:
        baseRisk *= 1.0;
        break;
      case SegmentSurfaceType.roughAsphalt:
        baseRisk *= 1.8;
        break;
      case SegmentSurfaceType.gravelStrade:
        baseRisk *= 4.5;
        break;
      case SegmentSurfaceType.cobblestonesSector1:
        baseRisk *= 3.5;
        break;
      case SegmentSurfaceType.cobblestonesSector2:
        baseRisk *= 5.0;
        break;
      case SegmentSurfaceType.cobblestonesSector3:
        baseRisk *= 8.0;
        break;
      case SegmentSurfaceType.cobblestonesSector4:
        baseRisk *= 12.0;
        break;
      case SegmentSurfaceType.cobblestonesSector5:
        baseRisk *= 18.0; // Piekło Północy (Trouée d'Arenberg)
        break;
    }

    // 2. Mnożnik pogody (deszcz zwilża opony i ułatwia wbijanie ostrych kamyków)
    if (weatherCondition == WeatherCondition.heavyStorm) {
      baseRisk *= 2.4;
    } else if (weatherCondition == WeatherCondition.lightRain) {
      baseRisk *= 1.7;
    }

    // 3. Mnożnik opony i technologii roweru (np. tubeless redukuje ryzyko)
    baseRisk *= bikePunctureRiskFactor.clamp(0.4, 2.5);

    return baseRisk.clamp(0.00005, 0.08);
  }

  /// Oblicza prawdopodobieństwo kraksy na odcinku 1 km.
  static double calculateCrashProbabilityPerKm({
    required StageSegment segment,
    required WeatherCondition weatherCondition,
    required double currentSpeedKmh,
    required double distanceToFinishKm,
    required RiderSkills skills,
    required bool isEchelonCrosswind,
  }) {
    // Bazowe ryzyko upadku na bezpiecznym prostym odcinku (~0.006% na km)
    double baseCrashRisk = 0.00006;

    // 1. Trudność techniczna trasy (zakręty, wysepki, zwężenia)
    final double techFactor = segment.technicalDifficulty / 40.0;
    baseCrashRisk *= techFactor.clamp(0.6, 3.5);

    // 2. Prędkość (na zjazdach i w sprincie > 60 km/h ryzyko skokowo rośnie)
    if (currentSpeedKmh > 65.0) {
      baseCrashRisk *= 2.5;
    } else if (currentSpeedKmh > 52.0) {
      baseCrashRisk *= 1.6;
    }

    // 3. Deszcz i mokra nawierzchnia
    if (weatherCondition == WeatherCondition.heavyStorm) {
      baseCrashRisk *= 2.8;
    } else if (weatherCondition == WeatherCondition.lightRain) {
      baseCrashRisk *= 2.0;
    }

    // 4. Nawierzchnia (mokry bruk lub szuter)
    if (segment.surfaceType.name.contains('cobble')) {
      baseCrashRisk *= 2.5;
    } else if (segment.surfaceType == SegmentSurfaceType.gravelStrade) {
      baseCrashRisk *= 1.8;
    }

    // 5. Nerwowość finału (ostatnie 20 km płaskiego etapu to walka pociągów sprinterskich)
    if (distanceToFinishKm <= 10.0) {
      baseCrashRisk *= 2.8;
    } else if (distanceToFinishKm <= 20.0) {
      baseCrashRisk *= 1.9;
    }

    // 6. Ranty i wachlarze przy wietrze bocznym
    if (isEchelonCrosswind) {
      baseCrashRisk *= 1.6;
    }

    // 7. Umiejętności kolarza (bikeHandling i rainResistance kolarza chronią przed upadkiem)
    final double defense = (skills.bikeHandling * 0.65) + (skills.rainResistance * 0.35);
    final double skillMultiplier = 1.0 - ((defense - 50.0) / 100.0) * 0.50; // 0.75 do 1.25

    return (baseCrashRisk * skillMultiplier).clamp(0.00002, 0.09);
  }

  /// Główna metoda sprawdzająca wystąpienie incydentów losowych w zadanym kroku symulacji.
  ///
  /// Parametry:
  /// - [currentKm]: aktualny kilometraż etapu
  /// - [stepDistanceKm]: dystans pokonany w danym kroku (np. 0.012 km przy 1s i 43 km/h)
  /// - [group]: grupa kolarzy ([PelotonGroup])
  /// - [stage]: etap wyścigu ([RaceStage])
  /// - [segment]: aktualny segment trasy ([StageSegment])
  /// - [ridersMap]: mapa id kolarza -> [Rider]
  /// - [bikesMap]: mapa id kolarza -> [CompleteBike]
  /// - [random]: generator liczb losowych
  static List<RaceIncidentEvent> evaluateIncidentsForStep({
    required double currentKm,
    required double stepDistanceKm,
    required PelotonGroup group,
    required RaceStage stage,
    required StageSegment segment,
    required Map<String, Rider> ridersMap,
    required Map<String, CompleteBike> bikesMap,
    math.Random? random,
  }) {
    final rng = random ?? math.Random();
    final List<RaceIncidentEvent> events = [];
    final double distToFinish = math.max(0.0, stage.totalDistanceKm - currentKm);

    // Kopia listy kolarzy w grupie
    final List<String> currentRiderIds = List.from(group.riderIds);

    // -------------------------------------------------------------
    // 1. SYMULACJA KRAKSY W PELETONIE
    // -------------------------------------------------------------
    // Badamy ryzyko kraksy dla grupy jako całości
    final double groupCrashProb = calculateCrashProbabilityPerKm(
          segment: segment,
          weatherCondition: stage.weatherCondition,
          currentSpeedKmh: group.averageSpeedKmh,
          distanceToFinishKm: distToFinish,
          skills: const RiderSkills(
            cobbles: 60,
            descending: 60,
            bikeHandling: 60,
            aeroPositioning: 60,
            draftingEfficiency: 60,
            raceIq: 60,
            rainResistance: 60,
            heatTolerance: 60,
            timeTrialPositioning: 60,
          ),
          isEchelonCrosswind: stage.windSpeedKmh > 25.0,
        ) *
        stepDistanceKm *
        math.min(18.0, group.riderCount * 0.15); // Im większy peleton, tym większe ryzyko kraksy

    if (currentRiderIds.length >= 6 && rng.nextDouble() < groupCrashProb) {
      // Kraksa nastąpiła! Losujemy liczbę poszkodowanych (od 2 do 8 kolarzy)
      final int victimCount = rng.nextInt(math.min(7, currentRiderIds.length - 2)) + 2;
      final List<IncidentVictim> victims = [];
      final List<String> heldUpIds = [];

      // Mieszamy kolarzy z ogona i środka peletonu
      currentRiderIds.shuffle(rng);
      final fallenRiderIds = currentRiderIds.take(victimCount).toList();

      for (final rId in fallenRiderIds) {
        final rider = ridersMap[rId];
        if (rider == null) continue;

        // Losowanie skutków medycznych upadku:
        final double injuryRoll = rng.nextDouble();
        Injury? injury;
        bool isDnf = false;
        double timeLost = 25.0 + rng.nextInt(40); // 25 - 65 sekund postoju
        String desc;

        if (injuryRoll < 0.08) {
          // 8% szans: Złamanie obojczyka (DNF!)
          injury = const Injury(
            name: 'Złamanie obojczyka',
            type: InjuryType.clavicleFracture,
            daysRemaining: 42,
            trainingAllowed: false,
          );
          isDnf = true;
          timeLost = 9999.0;
          desc = '${rider.lastName} doznał złamania obojczyka w kraksie i wycofuje się z wyścigu!';
        } else if (injuryRoll < 0.14) {
          // 6% szans: Wstrząśnienie mózgu (DNF!)
          injury = const Injury(
            name: 'Wstrząśnienie mózgu',
            type: InjuryType.concussion,
            daysRemaining: 14,
            trainingAllowed: false,
          );
          isDnf = true;
          timeLost = 9999.0;
          desc = '${rider.lastName} uderzył głową o asfalt – wstrząśnienie mózgu, koniec wyścigu (DNF).';
        } else {
          // 86% szans: Otarcia skóry, szlify i potłuczenia (kolarz jedzie dalej)
          injury = Injury(
            name: 'Szlify asfaltowe',
            type: InjuryType.roadRash,
            daysRemaining: 4 + rng.nextInt(3),
            trainingAllowed: true,
          );
          desc = '${rider.lastName} podnosi się po upadku ze szlifami na biodrze i wraca na rower.';
        }

        victims.add(
          IncidentVictim(
            riderId: rId,
            riderName: '${rider.firstName} ${rider.lastName}',
            teamId: rider.contract.teamId,
            incidentType: IncidentType.pelotonPileup,
            timeLostSeconds: timeLost,
            injury: injury,
            isDnf: isDnf,
            assistanceMethod: AssistanceMethod.selfRemount,
            description: desc,
          ),
        );
      }

      // Kolarze zablokowani za kraksą (zatrzymani bez upadku)
      final remainingRiders = currentRiderIds.skip(victimCount).toList();
      final int heldUpCount = math.min(12, remainingRiders.length);
      for (int i = 0; i < heldUpCount; i++) {
        heldUpIds.add(remainingRiders[i]);
      }

      final String radioMsg = 'KRAKSA W PELETONIE na ${currentKm.toStringAsFixed(1)} km! '
          'Leży ${victims.length} kolarzy! Szosa częściowo zablokowana.';

      events.add(
        RaceIncidentEvent(
          id: 'crash_${currentKm.round()}_${rng.nextInt(1000)}',
          kilometerMark: currentKm,
          type: IncidentType.pelotonPileup,
          primaryVictims: victims,
          heldUpRiderIds: heldUpIds,
          blockageDelaySeconds: 18.0 + rng.nextInt(15),
          isRoadBlocked: heldUpIds.isNotEmpty,
          radioReport: radioMsg,
        ),
      );

      // Po kraksie nie sprawdzamy już kapci w tej sekundzie
      return events;
    }

    // -------------------------------------------------------------
    // 2. SYMULACJA PRZEBICIA OPONY / DEFEKTU MECHANICZNEGO
    // -------------------------------------------------------------
    for (final rId in currentRiderIds) {
      final rider = ridersMap[rId];
      final bike = bikesMap[rId];
      if (rider == null) continue;

      final double punctureRiskFactor = bike?.punctureRiskFactor ?? 1.0;
      final double pProb = calculatePunctureProbabilityPerKm(
            surfaceType: segment.surfaceType,
            weatherCondition: stage.weatherCondition,
            bikePunctureRiskFactor: punctureRiskFactor,
          ) *
          stepDistanceKm;

      if (rng.nextDouble() < pProb) {
        // Przebicie opony u kolarza!
        // Sprawdzamy czy to lider zespołu i czy w pobliżu jedzie pomocnik, który może oddać swój rower!
        final bool isTeamLeader = rider.specialization == RiderSpecialization.gcClimber ||
            rider.specialization == RiderSpecialization.pureSprinter;

        String? sacrificedDomestiqueId;
        AssistanceMethod method = AssistanceMethod.teamCarService;
        double timeLost = 45.0 + rng.nextInt(25); // 45 - 70 sekund na wóz techniczny
        String desc;

        if (isTeamLeader) {
          // Szukamy pomocnika z tego samego zespołu jadącego w tej samej grupie
          final domestiqueCandidate = currentRiderIds.firstWhere(
            (id) {
              if (id == rId) return false;
              final other = ridersMap[id];
              return other != null &&
                  other.contract.teamId == rider.contract.teamId &&
                  other.specialization == RiderSpecialization.domestiqueEngine;
            },
            orElse: () => '',
          );

          if (domestiqueCandidate.isNotEmpty) {
            // Pomocnik natychmiast oddaje swój rower liderowi!
            sacrificedDomestiqueId = domestiqueCandidate;
            method = AssistanceMethod.teammateBikeSwap;
            timeLost = 14.0 + rng.nextInt(5); // Tylko 14-19 sekund straty dla lidera!
            final domRider = ridersMap[domestiqueCandidate];
            desc = 'DEFEKT LATERA! Pomocnik ${domRider?.lastName ?? "pomocnik"} błyskawicznie oddaje swój rower liderowi [${rider.lastName}]!';
          } else {
            desc = 'Defekt koła u lidera [${rider.lastName}]! Brak pomocników w pobliżu – oczekiwanie na wóz techniczny.';
          }
        } else {
          desc = 'Przebicie opony u kolarza [${rider.lastName}]. Wymiana koła z wozu technicznego.';
        }

        final victim = IncidentVictim(
          riderId: rId,
          riderName: '${rider.firstName} ${rider.lastName}',
          teamId: rider.contract.teamId,
          incidentType: IncidentType.punctureFlatTire,
          timeLostSeconds: timeLost,
          isDnf: false,
          assistanceMethod: method,
          sacrificedTeammateId: sacrificedDomestiqueId,
          description: desc,
        );

        events.add(
          RaceIncidentEvent(
            id: 'puncture_${currentKm.round()}_$rId',
            kilometerMark: currentKm,
            type: IncidentType.punctureFlatTire,
            primaryVictims: [victim],
            heldUpRiderIds: const [],
            blockageDelaySeconds: 0.0,
            isRoadBlocked: false,
            radioReport: desc,
          ),
        );

        // Maksymalnie 1 defekt na grupę w pojedynczym kroku czasowym
        break;
      }
    }

    return events;
  }
}

