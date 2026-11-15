// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider_physiology.dart';
import '../../models/rider/rider_skills.dart';
import '../physics/nutrition_and_glycogen_engine.dart';
import '../weather/dynamic_mountain_weather_engine.dart';
import 'rider_race_state.dart';

/// Lokalizacja i parametry oficjalnej strefy bufetu (Feed Zone / Zone de Ravitaillement).
class FeedZoneLocation {
  /// Identyfikator strefy
  final String id;

  /// Nazwa punktu żywieniowego
  final String zoneName;

  /// Początek strefy bufetowej w kilometrach trasy [km]
  final double startKm;

  /// Koniec strefy bufetowej w kilometrach trasy [km] (strefa trwa zazwyczaj 1.5 - 3 km)
  final double endKm;

  /// Wysokość n.p.m. strefy bufetu [m]
  final double elevationMeters;

  /// Czy w strefie stoją masażyści (soigneurzy) z torbami żywieniowymi ("musette")
  final bool isMusetteStation;

  /// Czy w tym rejonie dopuszczone jest podawanie bidonów z wozów technicznych
  final bool isVehicleFeedingAllowed;

  /// Czy strefa znajduje się w strefie zakazu bufetu UCI (ostatnie 20 km etapu)
  final bool isClosedForFinalKms;

  const FeedZoneLocation({
    required this.id,
    required this.zoneName,
    required this.startKm,
    required this.endKm,
    required this.elevationMeters,
    this.isMusetteStation = true,
    this.isVehicleFeedingAllowed = true,
    this.isClosedForFinalKms = false,
  });

  /// Długość strefy bufetu w kilometrach
  double get lengthKm => endKm - startKm;

  /// Czy dany kilometraż znajduje się wewnątrz tej strefy bufetu
  bool containsDistance(double distanceKm) {
    return distanceKm >= startKm && distanceKm <= endKm;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'zoneName': zoneName,
      'startKm': startKm,
      'endKm': endKm,
      'elevationMeters': elevationMeters,
      'isMusetteStation': isMusetteStation,
      'isVehicleFeedingAllowed': isVehicleFeedingAllowed,
      'isClosedForFinalKms': isClosedForFinalKms,
    };
  }

  factory FeedZoneLocation.fromJson(Map<String, dynamic> json) {
    return FeedZoneLocation(
      id: json['id'] as String,
      zoneName: json['zoneName'] as String,
      startKm: (json['startKm'] as num).toDouble(),
      endKm: (json['endKm'] as num).toDouble(),
      elevationMeters: (json['elevationMeters'] as num).toDouble(),
      isMusetteStation: json['isMusetteStation'] as bool? ?? true,
      isVehicleFeedingAllowed: json['isVehicleFeedingAllowed'] as bool? ?? true,
      isClosedForFinalKms: json['isClosedForFinalKms'] as bool? ?? false,
    );
  }
}

/// Zawartość torby żywieniowej (Musette bag) podawanej kolarzowi w strefie bufetu.
class MusetteBagContent {
  /// Liczba bidonów (zazwyczaj 2: izotonik z węglowodanami + czysta woda)
  final int bidonsCount;

  /// Liczba żeli energetycznych (szybkie węglowodany maltodekstryna/fruktoza)
  final int energyGelsCount;

  /// Liczba batonów energetycznych lub ciastek ryżowych (rice cakes)
  final int energyBarsCount;

  /// Czy torba zawiera zwiniętą ultralekką kamizelkę wiatroszczelną / pelerynę przeciwdeszczową
  final bool containsEmergencyRainGilet;

  /// Ilość węglowodanów w płynach zawartych w bidonach [g]
  final double totalCarbsGrams;

  const MusetteBagContent({
    this.bidonsCount = 2,
    this.energyGelsCount = 3,
    this.energyBarsCount = 1,
    this.containsEmergencyRainGilet = false,
    this.totalCarbsGrams = 80.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'bidonsCount': bidonsCount,
      'energyGelsCount': energyGelsCount,
      'energyBarsCount': energyBarsCount,
      'containsEmergencyRainGilet': containsEmergencyRainGilet,
      'totalCarbsGrams': totalCarbsGrams,
    };
  }

  factory MusetteBagContent.fromJson(Map<String, dynamic> json) {
    return MusetteBagContent(
      bidonsCount: (json['bidonsCount'] as num?)?.toInt() ?? 2,
      energyGelsCount: (json['energyGelsCount'] as num?)?.toInt() ?? 3,
      energyBarsCount: (json['energyBarsCount'] as num?)?.toInt() ?? 1,
      containsEmergencyRainGilet: json['containsEmergencyRainGilet'] as bool? ?? false,
      totalCarbsGrams: (json['totalCarbsGrams'] as num?)?.toDouble() ?? 80.0,
    );
  }
}

/// Wynik próby przechwycenia torby bufetowej (musette) przez kolarza w locie.
class MusetteGrabResult {
  final bool success;
  final bool isDropped;
  final bool isTangledWarning;
  final int bidonsAdded;
  final int gelsAdded;
  final int barsAdded;
  final bool emergencyGiletReceived;
  final String radioMessagePl;

  const MusetteGrabResult({
    required this.success,
    required this.isDropped,
    required this.isTangledWarning,
    required this.bidonsAdded,
    required this.gelsAdded,
    required this.barsAdded,
    required this.emergencyGiletReceived,
    required this.radioMessagePl,
  });
}

/// Fazy operacji zakładania lub zdejmowania odzieży ochronnej podczas jazdy na rowerze.
enum JacketOperationPhase {
  /// Brak aktywnej operacji – ubranie stabilne
  none,

  /// Kolarz sięga dłonią do tylnej kieszonki po zwiniętą kurtkę / kamizelkę
  reachingPocket,

  /// Przekładanie rąk przez rękawy (puszczenie kierownicy jedną ręką, lekka utrata prędkości)
  puttingOnSleeves,

  /// Zasuwanie zamka błyskawicznego pod szyję (zipping up)
  zippingUp,

  /// Kurtka w pełni ubrana i zapięta – ochrona aktywna
  wornAndZipped,

  /// Rozsuwanie zamka i ściąganie kurtki po zjeździe
  takingOff;

  String toJson() => name;

  static JacketOperationPhase fromJson(String value) {
    return JacketOperationPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => JacketOperationPhase.none,
    );
  }

  /// Czy operacja ubierania/zdejmowania jest w toku
  bool get isInProgress =>
      this == JacketOperationPhase.reachingPocket ||
      this == JacketOperationPhase.puttingOnSleeves ||
      this == JacketOperationPhase.zippingUp ||
      this == JacketOperationPhase.takingOff;
}

/// Stan ubrania ochronnego i trwającej procedury jego zmiany dla danego kolarza.
class JacketDeploymentState {
  final String riderId;
  final RiderClothingType currentClothing;
  final JacketOperationPhase phase;
  final double phaseProgressSeconds;
  final bool hasJacketInPocket;
  final bool isZipped;

  const JacketDeploymentState({
    required this.riderId,
    required this.currentClothing,
    this.phase = JacketOperationPhase.none,
    this.phaseProgressSeconds = 0.0,
    this.hasJacketInPocket = true,
    this.isZipped = true,
  });

  /// Czy kolarz ma aktualnie założoną i zapiętą kurtkę lub kamizelkę
  bool get isWearingJacket =>
      (currentClothing == RiderClothingType.rainJacket ||
          currentClothing == RiderClothingType.windGilet ||
          currentClothing == RiderClothingType.thermalWinterJacket) &&
      phase == JacketOperationPhase.none &&
      isZipped;

  JacketDeploymentState copyWith({
    String? riderId,
    RiderClothingType? currentClothing,
    JacketOperationPhase? phase,
    double? phaseProgressSeconds,
    bool? hasJacketInPocket,
    bool? isZipped,
  }) {
    return JacketDeploymentState(
      riderId: riderId ?? this.riderId,
      currentClothing: currentClothing ?? this.currentClothing,
      phase: phase ?? this.phase,
      phaseProgressSeconds: phaseProgressSeconds ?? this.phaseProgressSeconds,
      hasJacketInPocket: hasJacketInPocket ?? this.hasJacketInPocket,
      isZipped: isZipped ?? this.isZipped,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'currentClothing': currentClothing.toJson(),
      'phase': phase.toJson(),
      'phaseProgressSeconds': phaseProgressSeconds,
      'hasJacketInPocket': hasJacketInPocket,
      'isZipped': isZipped,
    };
  }

  factory JacketDeploymentState.fromJson(Map<String, dynamic> json) {
    return JacketDeploymentState(
      riderId: json['riderId'] as String,
      currentClothing: RiderClothingType.fromJson(json['currentClothing'] as String),
      phase: JacketOperationPhase.fromJson(json['phase'] as String),
      phaseProgressSeconds: (json['phaseProgressSeconds'] as num?)?.toDouble() ?? 0.0,
      hasJacketInPocket: json['hasJacketInPocket'] as bool? ?? true,
      isZipped: json['isZipped'] as bool? ?? true,
    );
  }
}

/// Szczegółowy wynik ekspozycji kolarza na chłód i ulewę na alpejskim zjeździe.
class DescentColdExposureResult {
  final String riderId;

  /// Czy kolarz jedzie w założonej kurtce/kamizelce
  final bool isWearingJacket;

  /// Wysokość n.p.m. przełęczy [m]
  final double altitudeMeters;

  /// Czy panuje ulewa / marznący deszcz
  final bool isHeavyRainOrStorm;

  /// Odporność kolarza na złą pogodę (1-100)
  final int rainResistanceSkill;

  /// Poziom zdrętwienia palców i utraty czucia w dłoniach na klamkach hamulcowych [0.0 - 1.0]
  final double handNumbnessLevel;

  /// Spadek prędkości w zakrętach na serpentynach z powodu zdrętwiałych rąk [%]
  final double corneringSpeedPenaltyPercent;

  /// Utrata dodatkowego zapasu energii na drżenie mięśniowe [%] (dokładnie 15% przy braku kurtki w ulewie!)
  final double shiveringEnergyLossPercent;

  /// Dodatkowe gramy glikogenu spalone z powodu mimowolnego drżenia mięśniowego [g]
  final double extraGlycogenBurnGrams;

  /// Mnożnik ryzyka kraksy na zjeździe
  final double crashRiskMultiplier;

  /// Komunikat ostrzegawczy z wyścigu
  final String diagnosticMessagePl;

  const DescentColdExposureResult({
    required this.riderId,
    required this.isWearingJacket,
    required this.altitudeMeters,
    required this.isHeavyRainOrStorm,
    required this.rainResistanceSkill,
    required this.handNumbnessLevel,
    required this.corneringSpeedPenaltyPercent,
    required this.shiveringEnergyLossPercent,
    required this.extraGlycogenBurnGrams,
    required this.crashRiskMultiplier,
    required this.diagnosticMessagePl,
  });

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'isWearingJacket': isWearingJacket,
      'altitudeMeters': altitudeMeters,
      'isHeavyRainOrStorm': isHeavyRainOrStorm,
      'rainResistanceSkill': rainResistanceSkill,
      'handNumbnessLevel': handNumbnessLevel,
      'corneringSpeedPenaltyPercent': corneringSpeedPenaltyPercent,
      'shiveringEnergyLossPercent': shiveringEnergyLossPercent,
      'extraGlycogenBurnGrams': extraGlycogenBurnGrams,
      'crashRiskMultiplier': crashRiskMultiplier,
      'diagnosticMessagePl': diagnosticMessagePl,
    };
  }

  factory DescentColdExposureResult.fromJson(Map<String, dynamic> json) {
    return DescentColdExposureResult(
      riderId: json['riderId'] as String,
      isWearingJacket: json['isWearingJacket'] as bool,
      altitudeMeters: (json['altitudeMeters'] as num).toDouble(),
      isHeavyRainOrStorm: json['isHeavyRainOrStorm'] as bool,
      rainResistanceSkill: (json['rainResistanceSkill'] as num).toInt(),
      handNumbnessLevel: (json['handNumbnessLevel'] as num).toDouble(),
      corneringSpeedPenaltyPercent: (json['corneringSpeedPenaltyPercent'] as num).toDouble(),
      shiveringEnergyLossPercent: (json['shiveringEnergyLossPercent'] as num).toDouble(),
      extraGlycogenBurnGrams: (json['extraGlycogenBurnGrams'] as num).toDouble(),
      crashRiskMultiplier: (json['crashRiskMultiplier'] as num).toDouble(),
      diagnosticMessagePl: json['diagnosticMessagePl'] as String,
    );
  }
}

/// Zaawansowany silnik stref bufetu (Feed Zones) oraz taktycznego ubierania kurtek przeciwdeszczowych.
class FeedingAndRainJacketMechanics {
  FeedingAndRainJacketMechanics._();

  /// Standardowy czas potrzebny na założenie kurtki podczas jazdy [s] (sięgnięcie, rękawy, suwak)
  static const double jacketPutOnDurationSeconds = 7.0;

  /// Standardowy czas na zdjęcie kurtki po zjeździe [s]
  static const double jacketTakeOffDurationSeconds = 4.0;

  /// Pułap wysokiej przełęczy alpejskiej generującej krytyczne wychłodzenie [m n.p.m.]
  static const double alpinePassColdThresholdMeters = 2000.0;

  /// Bazowa utrata energii na drżenie mięśniowe przy braku kurtki w ulewie na alpejskiej przełęczy [%]
  static const double baseShiveringEnergyLossPercent = 15.0;

  /// Generuje realistyczne strefy bufetu (Feed Zones) wzdłuż trasy danego etapu.
  ///
  /// Zgodnie z zasadami UCI:
  /// - Strefa główna bufetu lokowana jest w okolicach środka dystansu (zazwyczaj km 80 - 120).
  /// - Zakaz podawania żywności i bidonów obowiązuje na pierwszych 30 km i ostatnich 20 km.
  /// - Na etapach górskich dodawany jest bufet u podnóża kluczowego podjazdu.
  static List<FeedZoneLocation> generateFeedZonesForStage(RaceStage stage) {
    final double totalKm = stage.totalDistanceKm;
    if (totalKm <= 40.0) {
      // Krótkie czasówki lub prologi nie posiadają strefy stacjonarnego bufetu
      return [];
    }

    final List<FeedZoneLocation> zones = [];

    // 1. Główny bufet stacjonarny w okolicy 45% - 55% dystansu
    final double midKm = (totalKm * 0.50).clamp(35.0, totalKm - 25.0);
    zones.add(FeedZoneLocation(
      id: '${stage.id}_feed_mid',
      zoneName: 'Oficjalny Bufet Główny (Ravitaillement)',
      startKm: double.parse(midKm.toStringAsFixed(1)),
      endKm: double.parse((midKm + 2.5).toStringAsFixed(1)),
      elevationMeters: 650.0,
      isMusetteStation: true,
      isVehicleFeedingAllowed: true,
      isClosedForFinalKms: false,
    ));

    // 2. Dodatkowy punkt żywieniowy u podnóża podjazdu HC na etapach górskich > 150 km
    if (totalKm > 150.0 && stage.stageType == StageType.highMountain) {
      final double mountainBaseKm = (totalKm * 0.72).clamp(midKm + 20.0, totalKm - 22.0);
      zones.add(FeedZoneLocation(
        id: '${stage.id}_feed_mountain_base',
        zoneName: 'Punkt Żywieniowy u Podnóża Przełęczy',
        startKm: double.parse(mountainBaseKm.toStringAsFixed(1)),
        endKm: double.parse((mountainBaseKm + 1.8).toStringAsFixed(1)),
        elevationMeters: 1100.0,
        isMusetteStation: true,
        isVehicleFeedingAllowed: true,
        isClosedForFinalKms: false,
      ));
    }

    return zones;
  }

  /// Sprawdza czy podany kilometraż znajduje się w aktywnej strefie bufetu.
  static FeedZoneLocation? getActiveFeedZoneAtDistance(
    double distanceKm,
    List<FeedZoneLocation> zones,
  ) {
    for (final zone in zones) {
      if (zone.containsDistance(distanceKm)) {
        return zone;
      }
    }
    return null;
  }

  /// Próba przechwycenia torby żywieniowej (musette) od soigneura w strefie bufetu.
  ///
  /// Prawdopodobieństwo sukcesu zależy od techniki kolarza ([RiderSkills.bikeHandling]),
  /// inteligencji wyścigowej ([RiderSkills.raceIq]) oraz prędkości grupy w strefie.
  static MusetteGrabResult attemptGrabMusette({
    required RiderSkills skills,
    required double currentSpeedKmh,
    required MusetteBagContent bagContent,
    double crowdChaosFactor = 0.15,
  }) {
    // Bazowa szansa: 96%
    double successChance = 0.96;

    // Prędkość powyżej 42 km/h w strefie bufetu zwiększa ryzyko upuszczenia
    if (currentSpeedKmh > 42.0) {
      successChance -= ((currentSpeedKmh - 42.0) / 20.0) * 0.22;
    }

    // Umiejętności kolarza
    successChance += ((skills.bikeHandling - 50) / 100.0) * 0.10;
    successChance += ((skills.raceIq - 50) / 100.0) * 0.05;
    successChance -= crowdChaosFactor;
    successChance = successChance.clamp(0.50, 0.99);

    final randomVal = (skills.bikeHandling * 17 + currentSpeedKmh.round() * 31) % 100 / 100.0;
    final bool success = randomVal <= successChance;

    if (!success) {
      return const MusetteGrabResult(
        success: false,
        isDropped: true,
        isTangledWarning: false,
        bidonsAdded: 0,
        gelsAdded: 0,
        barsAdded: 0,
        emergencyGiletReceived: false,
        radioMessagePl: 'Torba upuszczona w strefie bufetu! Soigneur nie zdołał pewnie podać paska.',
      );
    }

    return MusetteGrabResult(
      success: true,
      isDropped: false,
      isTangledWarning: false,
      bidonsAdded: bagContent.bidonsCount,
      gelsAdded: bagContent.energyGelsCount,
      barsAdded: bagContent.energyBarsCount,
      emergencyGiletReceived: bagContent.containsEmergencyRainGilet,
      radioMessagePl: 'Musette przejęte pewnie! Pobrane bidony (${bagContent.bidonsCount}) i żele (${bagContent.energyGelsCount}).',
    );
  }

  /// Rozpoczęcie operacji ubierania kurtki przeciwdeszczowej lub kamizelki przed zjazdem.
  static JacketDeploymentState startPuttingOnJacket({
    required JacketDeploymentState currentState,
    required RiderClothingType targetClothing,
  }) {
    if (currentState.isWearingJacket && currentState.currentClothing == targetClothing) {
      return currentState;
    }

    return currentState.copyWith(
      currentClothing: targetClothing,
      phase: JacketOperationPhase.reachingPocket,
      phaseProgressSeconds: 0.0,
      isZipped: false,
    );
  }

  /// Rozpoczęcie zdejmowania kurtki po zjeździe do ciepłej doliny.
  static JacketDeploymentState startTakingOffJacket({
    required JacketDeploymentState currentState,
  }) {
    if (currentState.currentClothing == RiderClothingType.summerAeroJersey) {
      return currentState;
    }

    return currentState.copyWith(
      phase: JacketOperationPhase.takingOff,
      phaseProgressSeconds: 0.0,
    );
  }

  /// Aktualizacja postępu operacji ubierania/zdejmowania odzieży w danym kroku czasowym [dtSeconds].
  static JacketDeploymentState updateJacketOperation({
    required JacketDeploymentState state,
    required double dtSeconds,
  }) {
    if (state.phase == JacketOperationPhase.none || state.phase == JacketOperationPhase.wornAndZipped) {
      return state;
    }

    final double newProgress = state.phaseProgressSeconds + dtSeconds;

    if (state.phase == JacketOperationPhase.takingOff) {
      if (newProgress >= jacketTakeOffDurationSeconds) {
        return state.copyWith(
          currentClothing: RiderClothingType.summerAeroJersey,
          phase: JacketOperationPhase.none,
          phaseProgressSeconds: 0.0,
          isZipped: false,
          hasJacketInPocket: true,
        );
      }
      return state.copyWith(phaseProgressSeconds: newProgress);
    }

    // Cykl ubierania: reachingPocket -> puttingOnSleeves -> zippingUp -> wornAndZipped
    if (newProgress < 2.0) {
      return state.copyWith(
        phase: JacketOperationPhase.reachingPocket,
        phaseProgressSeconds: newProgress,
      );
    } else if (newProgress < 5.0) {
      return state.copyWith(
        phase: JacketOperationPhase.puttingOnSleeves,
        phaseProgressSeconds: newProgress,
      );
    } else if (newProgress < jacketPutOnDurationSeconds) {
      return state.copyWith(
        phase: JacketOperationPhase.zippingUp,
        phaseProgressSeconds: newProgress,
      );
    } else {
      // Zakończono pełne założenie i zapięcie
      return state.copyWith(
        phase: JacketOperationPhase.none,
        phaseProgressSeconds: 0.0,
        isZipped: true,
        hasJacketInPocket: false,
      );
    }
  }

  /// Oblicza wpływ zjazdu w ulewie z wysokiej przełęczy na kolarza bez kurtki.
  ///
  /// Dokładnie implementuje zachowanie:
  /// - Kolarz zjeżdża z przełęczy (np. 2200m n.p.m.) w ulewie bez założenia kurtki.
  /// - Kolarz z niskim [RiderSkills.rainResistance] (np. < 50):
  ///   * Traci czucie w dłoniach (drętwienie palców, brak modulacji klamek hamulcowych).
  ///   * Jedzie wolniej w zakrętach (spadek prędkości na zakrętach i serpentynach od 20% do 35%).
  ///   * **Traci dodatkowe 15% zapasu energii na drżenie mięśniowe** (mimowolna termogeneza drżeniowa wyczerpująca glikogen).
  /// - Jeśli kolarz UBRAŁ kurtkę przeciwdeszczową:
  ///   * Zachowuje pełne czucie w dłoniach, brak utraty prędkości w zakrętach i **brak 15% straty energii**.
  static DescentColdExposureResult calculateDescentColdImpact({
    required String riderId,
    required bool isWearingJacket,
    required double altitudeMeters,
    required bool isHeavyRainOrStorm,
    required RiderSkills skills,
    required RiderPhysiology physiology,
  }) {
    final int rainResist = skills.rainResistance;
    final bool isHighColdPass = altitudeMeters >= alpinePassColdThresholdMeters;

    // 1. Jeśli kolarz ubrał kurtkę lub warunki nie są ekstremalnie chłodne/deszczowe
    if (isWearingJacket || (!isHeavyRainOrStorm && !isHighColdPass)) {
      return DescentColdExposureResult(
        riderId: riderId,
        isWearingJacket: isWearingJacket,
        altitudeMeters: altitudeMeters,
        isHeavyRainOrStorm: isHeavyRainOrStorm,
        rainResistanceSkill: rainResist,
        handNumbnessLevel: 0.0,
        corneringSpeedPenaltyPercent: 0.0,
        shiveringEnergyLossPercent: 0.0,
        extraGlycogenBurnGrams: 0.0,
        crashRiskMultiplier: 1.0,
        diagnosticMessagePl: isWearingJacket
            ? 'Kolarz zabezpieczony kurtką przeciwdeszczową. Pełne czucie w dłoniach i optymalna kontrola w zakrętach.'
            : 'Warunki atmosferyczne na zjeździe nie wymagają kurtki ochronnej.',
      );
    }

    // 2. Kolarz zjeżdża z przełęczy 2200m n.p.m. w ulewie BEZ KURTKI!
    // Współczynnik podatności na złą pogodę (0.0 = całkowicie uodporniony, 1.0 = skrajnie podatny)
    final double vulnerabilityFactor = ((100 - rainResist) / 100.0).clamp(0.15, 1.0);

    // Wysokość przełęczy potęguje chłód (na 2200m jest zimniej niż na 2000m)
    final double altitudeSeverity = 1.0 + ((altitudeMeters - alpinePassColdThresholdMeters) / 1000.0).clamp(0.0, 0.5);

    // A) Poziom utraty czucia w dłoniach (0.0 do 1.0)
    // Zdrętwiałe palce nie są w stanie zaciskać klamek hamulców
    final double handNumbness = (0.55 + (vulnerabilityFactor * 0.45)) * (altitudeSeverity * 0.95);
    final double clampedNumbness = handNumbness.clamp(0.20, 1.0);

    // B) Spadek prędkości w zakrętach i serpentynach [%]
    // Dla niskiego rainResistance (<50) strata wynosi 20% - 35%
    final double corneringPenalty = (18.0 + (vulnerabilityFactor * 17.0)) * altitudeSeverity;
    final double clampedCorneringPenalty = corneringPenalty.clamp(8.0, 42.0);

    // C) Utrata dodatkowych 15% zapasu energii na drżenie mięśniowe (zgodnie z promptem)
    // Bazowe 15%, modyfikowane nieznacznie podatnością na zimno
    final double energyLossPercent = baseShiveringEnergyLossPercent * (0.85 + (vulnerabilityFactor * 0.30));
    final double clampedEnergyLossPercent = energyLossPercent.clamp(12.0, 22.0);

    // D) Dodatkowo spalone gramy glikogenu (15% z pojemności glikogenowej kolarza)
    final double maxGlycogen = physiology.glycogenCapacityGrams > 0 ? physiology.glycogenCapacityGrams : 500.0;
    final double extraGlycogenBurn = maxGlycogen * (clampedEnergyLossPercent / 100.0);

    // E) Mnożnik ryzyka kraksy na zjeździe
    final double crashRisk = 1.0 + (clampedNumbness * 2.8);

    final String message = 'BRAK KURTKI na zjeździe z ${altitudeMeters.round()}m n.p.m. w ulewie! '
        'Niski rainResistance ($rainResist) skutkuje zdrętwieniem dłoni (${(clampedNumbness * 100).round()}% utraty czucia), '
        'zwolnieniem o ${clampedCorneringPenalty.toStringAsFixed(1)}% w zakrętach i utratą ${clampedEnergyLossPercent.toStringAsFixed(1)}% energii na drżenie mięśniowe!';

    return DescentColdExposureResult(
      riderId: riderId,
      isWearingJacket: false,
      altitudeMeters: altitudeMeters,
      isHeavyRainOrStorm: isHeavyRainOrStorm,
      rainResistanceSkill: rainResist,
      handNumbnessLevel: double.parse(clampedNumbness.toStringAsFixed(2)),
      corneringSpeedPenaltyPercent: double.parse(clampedCorneringPenalty.toStringAsFixed(1)),
      shiveringEnergyLossPercent: double.parse(clampedEnergyLossPercent.toStringAsFixed(1)),
      extraGlycogenBurnGrams: double.parse(extraGlycogenBurn.toStringAsFixed(1)),
      crashRiskMultiplier: double.parse(crashRisk.toStringAsFixed(2)),
      diagnosticMessagePl: message,
    );
  }

  /// Krokowa aplikacja mechaniki żywienia i odzieży w pętli symulacji etapu dla danego kolarza.
  ///
  /// Integruje:
  /// - Przejazd przez strefę bufetu i dopełnienie bidonów/żeli
  /// - Podanie kurtki z torby lub wozu technicznego
  /// - Naliczanie kar zjazdowych w przypadku braku kurtki w ulewie
  static ({
    RiderRaceState updatedRiderState,
    NutritionState updatedNutritionState,
    JacketDeploymentState updatedJacketState,
    DescentColdExposureResult? coldExposureResult,
    String? radioMessage,
  }) processStep({
    required RiderRaceState riderState,
    required NutritionState nutritionState,
    required JacketDeploymentState jacketState,
    required RiderSkills skills,
    required RiderPhysiology physiology,
    required StageSegment currentSegment,
    required LocalWeatherSnapshot currentWeather,
    required List<FeedZoneLocation> feedZones,
    required double dtSeconds,
    bool autoDeployJacketBeforeColdDescent = true,
  }) {
    RiderRaceState rState = riderState;
    NutritionState nState = nutritionState;
    JacketDeploymentState jState = jacketState;
    String? radioMsg;
    DescentColdExposureResult? coldImpact;

    final double currentKm = rState.distanceCoveredMeters / 1000.0;

    // 1. Sprawdzamy czy kolarz znajduje się w strefie bufetu
    final activeFeedZone = getActiveFeedZoneAtDistance(currentKm, feedZones);
    if (activeFeedZone != null && (rState.bidonsLeft < 2 || rState.gelsLeft < 4)) {
      // Kolarz pobiera torbę musette
      const musetteContent = MusetteBagContent(
        bidonsCount: 2,
        energyGelsCount: 3,
        energyBarsCount: 1,
        containsEmergencyRainGilet: true,
      );

      final grabResult = attemptGrabMusette(
        skills: skills,
        currentSpeedKmh: rState.currentSpeedMs * 3.6,
        bagContent: musetteContent,
      );

      if (grabResult.success) {
        rState = rState.copyWith(
          bidonsLeft: 2,
          gelsLeft: math.min(6, rState.gelsLeft + grabResult.gelsAdded),
        );

        if (grabResult.emergencyGiletReceived && !jState.hasJacketInPocket) {
          jState = jState.copyWith(hasJacketInPocket: true);
        }

        radioMsg = grabResult.radioMessagePl;
      }
    }

    // 2. Automatyczne podejmowanie decyzji o założeniu kurtki przed alpejskim zjazdem
    final bool isSevereColdPassDescent = currentSegment.isDescent &&
        (currentSegment.startElevationM >= 1900.0 || currentWeather.altitudeMeters >= 1900.0) &&
        (currentWeather.precipitationIntensity > 0.4 || currentWeather.apparentTemperatureCelsius <= 10.0);

    if (autoDeployJacketBeforeColdDescent && isSevereColdPassDescent && !jState.isWearingJacket) {
      if (jState.phase == JacketOperationPhase.none) {
        jState = startPuttingOnJacket(
          currentState: jState,
          targetClothing: RiderClothingType.rainJacket,
        );
      }
    }

    // 3. Aktualizacja postępu operacji ubierania kurtki
    jState = updateJacketOperation(state: jState, dtSeconds: dtSeconds);

    // 4. Ocena ekspozycji na chłód na zjeździe
    if (currentSegment.isDescent) {
      coldImpact = calculateDescentColdImpact(
        riderId: rState.riderId,
        isWearingJacket: jState.isWearingJacket,
        altitudeMeters: math.max(currentSegment.startElevationM, currentWeather.altitudeMeters),
        isHeavyRainOrStorm: currentWeather.precipitationIntensity > 0.45 ||
            currentWeather.weatherType.isFreezingCondition,
        skills: skills,
        physiology: physiology,
      );

      // Jeśli brak kurtki doprowadził do utraty energii na drżenie mięśniowe:
      if (coldImpact.shiveringEnergyLossPercent > 0.0) {
        // Redukujemy zapas glikogenu proporcjonalnie do czasu kroku dtSeconds
        final double extraBurnPerSecond = coldImpact.extraGlycogenBurnGrams / 600.0; // Rozłożone na ~10 minut zjazdu
        final double newGlycogen = math.max(0.0, nState.currentGlycogenGrams - (extraBurnPerSecond * dtSeconds));
        nState = nState.copyWith(currentGlycogenGrams: newGlycogen);
        rState = rState.copyWith(currentGlycogen: newGlycogen);

        if (radioMsg == null && coldImpact.handNumbnessLevel > 0.6) {
          radioMsg = coldImpact.diagnosticMessagePl;
        }
      }
    }

    return (
      updatedRiderState: rState,
      updatedNutritionState: nState,
      updatedJacketState: jState,
      coldExposureResult: coldImpact,
      radioMessage: radioMsg,
    );
  }
}

