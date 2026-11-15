import 'dart:math' as math;
import '../../models/rider/rider.dart';
import '../../models/rider/rider_skills.dart';
import 'rider_race_state.dart';

/// Rola kolarza w sprinterskim pociągu rozprowadzającym (Lead-out Train).
enum LeadoutRole {
  /// Rozprowadzający #3 (Lokomotywa): 3000m - 1500m do mety (nadaje wysokie tempo 56-60 km/h)
  locomotive3,

  /// Rozprowadzający #2 (Podkręcający): 1500m - 600m do mety (podnosi prędkość do 63-66 km/h)
  speedLifter2,

  /// Ostatni rozprowadzający (Pilot / Rybka): 600m - 200/250m do mety (wystrzeliwuje sprintera z koła)
  finalPilot,

  /// Główny sprinter finiszujący (otwiera finisz na 200-250m)
  sprinter,

  /// Sprinter solowy bez pociągu, walczący o koło topowego sprintera
  independentSprinter,

  /// Kolarz, który wykonał swoją zmianę i spłynął na bok jezdni
  swungOff;

  String toJson() => name;

  static LeadoutRole fromJson(String value) {
    return LeadoutRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LeadoutRole.locomotive3,
    );
  }
}

/// Członek sprinterskiego pociągu rozprowadzającego.
class SprintTrainMember {
  final String riderId;
  final LeadoutRole role;

  /// Kolejność w pociągu (1 = czoło, 4 = sprinter na końcu)
  final int orderInTrain;

  /// Docelowa moc generowana w danej sekundzie [W]
  final int targetWatts;

  /// Czy kolarz ukończył swoją zmianę i zjechał na bok
  final bool isSwungOff;

  const SprintTrainMember({
    required this.riderId,
    required this.role,
    required this.orderInTrain,
    required this.targetWatts,
    this.isSwungOff = false,
  });

  SprintTrainMember copyWith({
    String? riderId,
    LeadoutRole? role,
    int? orderInTrain,
    int? targetWatts,
    bool? isSwungOff,
  }) {
    return SprintTrainMember(
      riderId: riderId ?? this.riderId,
      role: role ?? this.role,
      orderInTrain: orderInTrain ?? this.orderInTrain,
      targetWatts: targetWatts ?? this.targetWatts,
      isSwungOff: isSwungOff ?? this.isSwungOff,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'role': role.toJson(),
      'orderInTrain': orderInTrain,
      'targetWatts': targetWatts,
      'isSwungOff': isSwungOff,
    };
  }

  factory SprintTrainMember.fromJson(Map<String, dynamic> json) {
    return SprintTrainMember(
      riderId: json['riderId'] as String,
      role: LeadoutRole.fromJson(json['role'] as String),
      orderInTrain: (json['orderInTrain'] as num).toInt(),
      targetWatts: (json['targetWatts'] as num).toInt(),
      isSwungOff: json['isSwungOff'] as bool? ?? false,
    );
  }
}

/// Formacja pociągu sprinterskiego zespołu na ostatnich 3 kilometrach.
class SprintTrain {
  final String teamId;
  final String teamName;
  final String sprinterId;
  final List<SprintTrainMember> members;

  /// Identyfikator kolarza aktualnie ciągnącego na czele pociągu
  final String activeLeadoutRiderId;

  /// Pozycja boczna pociągu na szerokości szosy (-1.0 = lewa barierka, 1.0 = prawa barierka)
  final double lateralRoadPosition;

  /// Szacowana prędkość pociągu w km/h
  final double trainSpeedKmh;

  const SprintTrain({
    required this.teamId,
    required this.teamName,
    required this.sprinterId,
    required this.members,
    required this.activeLeadoutRiderId,
    required this.lateralRoadPosition,
    required this.trainSpeedKmh,
  });

  SprintTrain copyWith({
    String? teamId,
    String? teamName,
    String? sprinterId,
    List<SprintTrainMember>? members,
    String? activeLeadoutRiderId,
    double? lateralRoadPosition,
    double? trainSpeedKmh,
  }) {
    return SprintTrain(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      sprinterId: sprinterId ?? this.sprinterId,
      members: members ?? this.members,
      activeLeadoutRiderId: activeLeadoutRiderId ?? this.activeLeadoutRiderId,
      lateralRoadPosition: lateralRoadPosition ?? this.lateralRoadPosition,
      trainSpeedKmh: trainSpeedKmh ?? this.trainSpeedKmh,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'sprinterId': sprinterId,
      'members': members.map((m) => m.toJson()).toList(),
      'activeLeadoutRiderId': activeLeadoutRiderId,
      'lateralRoadPosition': lateralRoadPosition,
      'trainSpeedKmh': trainSpeedKmh,
    };
  }

  factory SprintTrain.fromJson(Map<String, dynamic> json) {
    return SprintTrain(
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      sprinterId: json['sprinterId'] as String,
      members: (json['members'] as List<dynamic>)
          .map((e) => SprintTrainMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeLeadoutRiderId: json['activeLeadoutRiderId'] as String,
      lateralRoadPosition: (json['lateralRoadPosition'] as num).toDouble(),
      trainSpeedKmh: (json['trainSpeedKmh'] as num).toDouble(),
    );
  }
}

/// Decyzja i stan fizyczny sprintera w decydującej fazie finiszu.
class SprinterFinishingDecision {
  final String riderId;

  /// Czy kolarz został zablokowany przy barierkach (zamknięty w klatce)
  final bool isBoxedIn;

  /// Strona zablokowania ('leftBarrier', 'rightBarrier', 'wheelPocket')
  final String? boxedInReason;

  /// Czy sprinter otworzył już pełny finisz (sprint z maksymalną mocą)
  final bool isSprinting;

  /// Dystans pokonany na pełnym wietrze bez osłony aerodynamicznej [m]
  final double metersInFullWind;

  /// Kara za zbyt wczesne wyjście na wiatr (spadek mocy w ułamku 0.0 - 0.40)
  final double prematureLaunchPenalty;

  /// Docelowa moc wyjściowa w tej sekundzie [W]
  final int targetWatts;

  /// Pozycja boczna na szosie (-1.0 do 1.0)
  final double lateralRoadPosition;

  /// Identyfikator kolarza, o którego koło walczy sprinter
  final String? targetWheelRiderId;

  /// Telemetryczny opis manewru finiszowego
  final String sprintLog;

  const SprinterFinishingDecision({
    required this.riderId,
    required this.isBoxedIn,
    this.boxedInReason,
    required this.isSprinting,
    required this.metersInFullWind,
    required this.prematureLaunchPenalty,
    required this.targetWatts,
    required this.lateralRoadPosition,
    this.targetWheelRiderId,
    required this.sprintLog,
  });

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'isBoxedIn': isBoxedIn,
      'boxedInReason': boxedInReason,
      'isSprinting': isSprinting,
      'metersInFullWind': metersInFullWind,
      'prematureLaunchPenalty': prematureLaunchPenalty,
      'targetWatts': targetWatts,
      'lateralRoadPosition': lateralRoadPosition,
      'targetWheelRiderId': targetWheelRiderId,
      'sprintLog': sprintLog,
    };
  }

  factory SprinterFinishingDecision.fromJson(Map<String, dynamic> json) {
    return SprinterFinishingDecision(
      riderId: json['riderId'] as String,
      isBoxedIn: json['isBoxedIn'] as bool,
      boxedInReason: json['boxedInReason'] as String?,
      isSprinting: json['isSprinting'] as bool,
      metersInFullWind: (json['metersInFullWind'] as num).toDouble(),
      prematureLaunchPenalty: (json['prematureLaunchPenalty'] as num).toDouble(),
      targetWatts: (json['targetWatts'] as num).toInt(),
      lateralRoadPosition: (json['lateralRoadPosition'] as num).toDouble(),
      targetWheelRiderId: json['targetWheelRiderId'] as String?,
      sprintLog: json['sprintLog'] as String,
    );
  }
}

/// Wynik symulacji ostatnich 3 kilometrów i finiszu z peletonu.
class SprintSimulationResult {
  final double distanceToFinishMeters;
  final List<SprintTrain> trains;
  final List<SprinterFinishingDecision> sprinterDecisions;
  final double fastestSpeedKmh;
  final String radioComm;

  const SprintSimulationResult({
    required this.distanceToFinishMeters,
    required this.trains,
    required this.sprinterDecisions,
    required this.fastestSpeedKmh,
    required this.radioComm,
  });
}

/// Kontroler sztucznej inteligencji rozprowadzania sprintu (Lead-out Train).
///
/// Implementuje:
/// 1. Strukturę pociągu na ostatnich 3 km:
///    - 3000m - 1500m: Rozprowadzający #3 (lokomotywa, 520-580 W, ~58 km/h)
///    - 1500m - 600m:  Rozprowadzający #2 (podkręcający, 700-850 W, ~64 km/h)
///    - 600m  - 250m:  Ostatni rozprowadzający (pilot, 950-1150 W, ~68 km/h)
///    - 250m  - 0m:    Sprinter otwiera finisz (1300-1650 W, do 73 km/h)
/// 2. Walkę o koło czołowego sprintera (solowi sprinterzy walczą na łokcie o pozycję).
/// 3. Blokowanie przy barierkach (boxed-in) – zamknięcie korytarza zmusza do przyhamowania.
/// 4. Karę za przedwczesne wyjście na wiatr:
///    Gdy sprinter wyjdzie na wiatr zbyt wcześnie (np. na 450m), jego rezerwa beztlenowa
///    kończy się po 12 sekundach, a moc na ostatnich 100m drastycznie spada o 30-40%!
class SprintTrainAiController {
  SprintTrainAiController._();

  /// Optymalna odległość otwarcia sprintu z koła pilota [m] (200 - 250 m)
  static const double optimalSprintLaunchDistanceMeters = 240.0;

  /// Maksymalny dystans sprintu z pełną mocą przed wystąpieniem załamania glikolitycznego [m]
  static const double maxSustainableSprintDistanceMeters = 240.0;

  /// Margines krawędzi barierek na szosie
  static const double barrierLeftEdge = -0.85;
  static const double barrierRightEdge = 0.85;

  /// Główna metoda symulująca sprint na ostatnich 3000 metrów płaskiego etapu.
  static SprintSimulationResult updateFinalKilometers({
    required double distanceToFinishMeters,
    required List<SprintTrain> existingTrains,
    required Map<String, Rider> ridersMap,
    required Map<String, RiderRaceState> riderStates,
    required List<String> independentSprinterIds,
    double timeStepSeconds = 1.0,
  }) {
    final double dist = math.max(0.0, distanceToFinishMeters);
    final List<SprintTrain> updatedTrains = [];
    final List<SprinterFinishingDecision> decisions = [];
    double topSpeedKmh = 55.0;

    // 1. Aktualizacja każdego z pociągów sprinterskich
    for (final train in existingTrains) {
      final updatedTrain = _updateSingleTrain(
        train: train,
        distanceToFinishMeters: dist,
        ridersMap: ridersMap,
      );
      updatedTrains.add(updatedTrain);
      if (updatedTrain.trainSpeedKmh > topSpeedKmh) {
        topSpeedKmh = updatedTrain.trainSpeedKmh;
      }
    }

    // Znalezienie wiodącego pociągu (najszybszy pociąg wyznacza punkt odniesienia do walki o koło)
    SprintTrain? leadTrain = updatedTrains.isNotEmpty
        ? updatedTrains.reduce((a, b) => a.trainSpeedKmh > b.trainSpeedKmh ? a : b)
        : null;

    // 2. Obsługa finiszu sprinterów z pociągów
    for (final train in updatedTrains) {
      final sprinter = ridersMap[train.sprinterId];
      final state = riderStates[train.sprinterId];
      if (sprinter == null || state == null) continue;

      final decision = _evaluateSprinterLaunch(
        sprinter: sprinter,
        state: state,
        distanceToFinishMeters: dist,
        train: train,
        allTrains: updatedTrains,
        timeStepSeconds: timeStepSeconds,
      );
      decisions.add(decision);
    }

    // 3. Obsługa solowych sprinterów walczących o koło
    for (final soloId in independentSprinterIds) {
      final sprinter = ridersMap[soloId];
      final state = riderStates[soloId];
      if (sprinter == null || state == null) continue;

      final decision = _evaluateIndependentSprinter(
        sprinter: sprinter,
        state: state,
        distanceToFinishMeters: dist,
        leadTrain: leadTrain,
        allTrains: updatedTrains,
        timeStepSeconds: timeStepSeconds,
      );
      decisions.add(decision);
    }

    // Komunikat radiowy
    String radio;
    if (dist <= 250.0) {
      radio = '250 METRÓW DO KRESKI! Sprinterzy odpalają ogień – walka bark w bark o zwycięstwo etapowe!';
    } else if (dist <= 600.0) {
      radio = '600 metrów do mety! Ostatni piloci wchodzą na 70 km/h, pociągi zderzają się na szerokości szosy!';
    } else if (dist <= 1500.0) {
      radio = 'Flamme Rouge tuż-tuż (1.5 km)! Ogromna prędkość, pociągi sprinterskie przejmują kontrolę nad peletonem.';
    } else {
      radio = 'Ostatnie 3 kilometry etapu. Formowanie pociągów sprinterskich, walka o pozycje na czele.';
    }

    return SprintSimulationResult(
      distanceToFinishMeters: dist,
      trains: updatedTrains,
      sprinterDecisions: decisions,
      fastestSpeedKmh: topSpeedKmh,
      radioComm: radio,
    );
  }

  /// Aktualizuje stan pojedynczego pociągu sprinterskiego w zależności od odległości do mety.
  static SprintTrain _updateSingleTrain({
    required SprintTrain train,
    required double distanceToFinishMeters,
    required Map<String, Rider> ridersMap,
  }) {
    final List<SprintTrainMember> updatedMembers = [];
    String activePacemakerId = train.sprinterId;
    double currentTrainSpeedKmh = 58.0;

    for (final member in train.members) {
      final rider = ridersMap[member.riderId];
      final ftp = rider?.physiology.ftpWatts ?? 400;
      int watts = ftp;
      bool swungOff = member.isSwungOff;

      switch (member.role) {
        case LeadoutRole.locomotive3:
          if (distanceToFinishMeters > 1500.0) {
            watts = (ftp * 1.35).round().clamp(500, 650);
            activePacemakerId = member.riderId;
            currentTrainSpeedKmh = 59.5;
          } else {
            // Po 1.5 km spływa na bok
            swungOff = true;
            watts = (ftp * 0.50).round();
          }
          break;

        case LeadoutRole.speedLifter2:
          if (distanceToFinishMeters <= 1500.0 && distanceToFinishMeters > 600.0) {
            watts = (ftp * 1.80).round().clamp(700, 920);
            activePacemakerId = member.riderId;
            currentTrainSpeedKmh = 64.5;
          } else if (distanceToFinishMeters <= 600.0) {
            swungOff = true;
            watts = (ftp * 0.40).round();
          } else {
            // Jedzie w kołach za lokomotywą #3
            watts = (ftp * 0.85).round();
          }
          break;

        case LeadoutRole.finalPilot:
          if (distanceToFinishMeters <= 600.0 && distanceToFinishMeters > optimalSprintLaunchDistanceMeters) {
            watts = (ftp * 2.50).round().clamp(950, 1250);
            activePacemakerId = member.riderId;
            currentTrainSpeedKmh = 68.5;
          } else if (distanceToFinishMeters <= optimalSprintLaunchDistanceMeters) {
            swungOff = true;
            watts = (ftp * 0.35).round();
          } else {
            // Schowany w tunelu za #2
            watts = (ftp * 0.75).round();
          }
          break;

        case LeadoutRole.sprinter:
          // Sprinter do 250m siedzi w idealnym tunelu za pilotem
          if (distanceToFinishMeters > optimalSprintLaunchDistanceMeters) {
            watts = (ftp * 0.65).round(); // Pełna regeneracja przed eksplozją
          } else {
            activePacemakerId = member.riderId;
            final maxSprint = rider?.powerProfile.power5sWatts ?? 1500;
            watts = maxSprint;
            currentTrainSpeedKmh = 72.5;
          }
          break;

        case LeadoutRole.independentSprinter:
        case LeadoutRole.swungOff:
          watts = (ftp * 0.40).round();
          swungOff = true;
          break;
      }

      updatedMembers.add(
        member.copyWith(
          targetWatts: watts,
          isSwungOff: swungOff,
        ),
      );
    }

    return train.copyWith(
      members: updatedMembers,
      activeLeadoutRiderId: activePacemakerId,
      trainSpeedKmh: currentTrainSpeedKmh,
    );
  }

  /// Ocenia finisz sprintera posiadającego własny pociąg.
  static SprinterFinishingDecision _evaluateSprinterLaunch({
    required Rider sprinter,
    required RiderRaceState state,
    required double distanceToFinishMeters,
    required SprintTrain train,
    required List<SprintTrain> allTrains,
    required double timeStepSeconds,
  }) {
    final double maxSprintWatts = sprinter.powerProfile.power5sWatts.toDouble();
    final bool isSprintWindow = distanceToFinishMeters <= optimalSprintLaunchDistanceMeters;

    // Weryfikacja blokowania przy barierkach (boxed-in):
    // Jeśli pociąg jedzie blisko barierki (lateralPosition <= -0.80 lub >= 0.80) i obok jedzie inny pociąg
    final ({bool isBlocked, String? reason}) boxCheck = _checkForBarrierBoxing(
      sprinterLateralPos: train.lateralRoadPosition,
      allTrains: allTrains,
      currentTrainId: train.teamId,
      skills: sprinter.skills,
    );

    // Dystans spędzony na pełnym wietrze:
    double metersInWind = 0.0;
    bool isSprinting = false;
    double prematurePenalty = 0.0;
    int targetWatts;
    String log;

    if (boxCheck.isBlocked) {
      // Sprinter jest zablokowany przy barierkach! Musi czekać lub przyhamować
      targetWatts = (sprinter.physiology.ftpWatts * 0.90).round();
      log = 'ZABLOKOWANY PRZY BARIERKACH! Brak korytarza do otwarcia sprintu (${boxCheck.reason}).';
    } else if (isSprintWindow) {
      // Prawidłowe otwarcie sprintu na ostatnich 200-240m
      isSprinting = true;
      metersInWind = (optimalSprintLaunchDistanceMeters - distanceToFinishMeters).clamp(0.0, 300.0);

      // Sprawdzenie czy sprinter wyszedł na wiatr za wcześnie:
      if (metersInWind > maxSustainableSprintDistanceMeters) {
        // Drastyczny spadek mocy w końcówce (lactic acid breakdown)
        final double excess = metersInWind - maxSustainableSprintDistanceMeters;
        prematurePenalty = (excess / 120.0).clamp(0.0, 0.40); // do 40% spadku mocy!
        final double effectiveWatts = maxSprintWatts * (1.0 - prematurePenalty);
        targetWatts = effectiveWatts.round();
        log = 'Moc spada! Przedwczesny finisz zjada nogi (-${(prematurePenalty * 100).toStringAsFixed(0)}% mocy).';
      } else {
        targetWatts = maxSprintWatts.round();
        log = 'POTĘŻNY FINISZ Z KOŁA PILOTA! (${targetWatts}W, 72 km/h).';
      }
    } else {
      // Oczekiwanie w tunelu za pilotem
      targetWatts = (sprinter.physiology.ftpWatts * 0.65).round();
      log = 'Schowany w tunelu za pilotem (${distanceToFinishMeters.toStringAsFixed(0)}m do mety).';
    }

    return SprinterFinishingDecision(
      riderId: sprinter.id,
      isBoxedIn: boxCheck.isBlocked,
      boxedInReason: boxCheck.reason,
      isSprinting: isSprinting,
      metersInFullWind: metersInWind,
      prematureLaunchPenalty: prematurePenalty,
      targetWatts: targetWatts,
      lateralRoadPosition: train.lateralRoadPosition,
      sprintLog: log,
    );
  }

  /// Ocenia finisz samotnego sprintera walczącego o koło rywala.
  static SprinterFinishingDecision _evaluateIndependentSprinter({
    required Rider sprinter,
    required RiderRaceState state,
    required double distanceToFinishMeters,
    required SprintTrain? leadTrain,
    required List<SprintTrain> allTrains,
    required double timeStepSeconds,
  }) {
    final double maxSprintWatts = sprinter.powerProfile.power5sWatts.toDouble();
    final bool isSprintWindow = distanceToFinishMeters <= (optimalSprintLaunchDistanceMeters - 20.0); // Otwiera ciut później

    // Walka o koło czołowego sprintera:
    // Zdolność do wywalczenia koła zależy od bikeHandling i raceIq
    final double wheelBattleScore = (sprinter.skills.bikeHandling * 0.60) + (sprinter.skills.raceIq * 0.40);
    final bool wonTheWheel = wheelBattleScore >= 70.0 && leadTrain != null;

    final double assignedLateralPos = wonTheWheel
        ? leadTrain.lateralRoadPosition
        : state.lateralPositionRoad;

    final ({bool isBlocked, String? reason}) boxCheck = _checkForBarrierBoxing(
      sprinterLateralPos: assignedLateralPos,
      allTrains: allTrains,
      currentTrainId: '',
      skills: sprinter.skills,
    );

    int targetWatts;
    bool isSprinting = false;
    double prematurePenalty = 0.0;
    double metersInWind = 0.0;
    String log;

    if (boxCheck.isBlocked) {
      targetWatts = (sprinter.physiology.ftpWatts * 0.85).round();
      log = 'Solowy sprinter zablokowany przy barierkach! Brak miejsca do wyjścia z koła.';
    } else if (isSprintWindow) {
      isSprinting = true;
      metersInWind = ((optimalSprintLaunchDistanceMeters - 20.0) - distanceToFinishMeters).clamp(0.0, 300.0);

      if (metersInWind > maxSustainableSprintDistanceMeters) {
        final double excess = metersInWind - maxSustainableSprintDistanceMeters;
        prematurePenalty = (excess / 120.0).clamp(0.0, 0.40);
        targetWatts = (maxSprintWatts * (1.0 - prematurePenalty)).round();
        log = 'Spadek prędkości solowego sprintera – nogi zalane kwasem mlekowym.';
      } else {
        // Skok z koła
        final double surfBonus = wonTheWheel ? 1.02 : 0.96;
        targetWatts = (maxSprintWatts * surfBonus).round().clamp(1000, 1650);
        log = wonTheWheel
            ? 'Genialny wyskok z koła pociągu rywali! (${targetWatts}W).'
            : 'Atak ze środka grupy bez osłony pociągu.';
      }
    } else {
      // Trzymanie koła
      targetWatts = (sprinter.physiology.ftpWatts * (wonTheWheel ? 0.68 : 0.90)).round();
      log = wonTheWheel
          ? 'Trzyma koło lidera pociągu [${leadTrain.sprinterId}].'
          : 'Szuka koła i korytarza powietrznego w peletonie.';
    }

    return SprinterFinishingDecision(
      riderId: sprinter.id,
      isBoxedIn: boxCheck.isBlocked,
      boxedInReason: boxCheck.reason,
      isSprinting: isSprinting,
      metersInFullWind: metersInWind,
      prematureLaunchPenalty: prematurePenalty,
      targetWatts: targetWatts,
      lateralRoadPosition: assignedLateralPos,
      targetWheelRiderId: wonTheWheel ? leadTrain.sprinterId : null,
      sprintLog: log,
    );
  }

  /// Sprawdza, czy sprinter jest uwięziony / zablokowany przy barierkach (boxed-in).
  static ({bool isBlocked, String? reason}) _checkForBarrierBoxing({
    required double sprinterLateralPos,
    required List<SprintTrain> allTrains,
    required String currentTrainId,
    required RiderSkills skills,
  }) {
    // Kolarz przy samej lewej barierce (pos <= -0.85)
    final bool isNearLeftBarrier = sprinterLateralPos <= barrierLeftEdge;
    // Kolarz przy samej prawej barierce (pos >= 0.85)
    final bool isNearRightBarrier = sprinterLateralPos >= barrierRightEdge;

    if (!isNearLeftBarrier && !isNearRightBarrier) {
      return (isBlocked: false, reason: null);
    }

    // Sprawdzenie czy obok kolarza przy barierce jedzie konkurencyjny pociąg odcinający drogę
    for (final otherTrain in allTrains) {
      if (otherTrain.teamId == currentTrainId) continue;

      if (isNearLeftBarrier && (otherTrain.lateralRoadPosition - sprinterLateralPos).abs() < 0.28) {
        // Zdolność uniknięcia zamknięcia w klatce dzięki sprytowi i technice jazdy
        final bool escapedBox = skills.bikeHandling >= 88 && skills.raceIq >= 82;
        if (!escapedBox) {
          return (isBlocked: true, reason: 'Zamknięty przy lewej barierce przez pociąg ${otherTrain.teamName}');
        }
      }

      if (isNearRightBarrier && (otherTrain.lateralRoadPosition - sprinterLateralPos).abs() < 0.28) {
        final bool escapedBox = skills.bikeHandling >= 88 && skills.raceIq >= 82;
        if (!escapedBox) {
          return (isBlocked: true, reason: 'Zamknięty przy prawej barierce przez pociąg ${otherTrain.teamName}');
        }
      }
    }

    return (isBlocked: false, reason: null);
  }
}

