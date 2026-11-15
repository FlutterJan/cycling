import 'dart:math' as math;
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider_skills.dart';
import 'drafting_grid_system.dart';

/// Pojedyncza formacja wachlarzowa (echelon / rant) powstała na wietrze bocznym.
class EchelonFormation {
  /// Numer wachlarza (1 = czołowy wachlarz / pierwszy rant, 2 = drugi wachlarz, itd.)
  final int echelonIndex;

  /// Identyfikatory kolarzy jadących w tym wachlarzu
  final List<String> riderIds;

  /// Maksymalna fizyczna pojemność wachlarza na szerokości szosy
  final int capacity;

  /// Czy wachlarz osiągnął krawędź szosy i utworzył rynsztok (gutter)
  final bool isGutterFormed;

  /// Identyfikator kolarza, który "odpadł z rantu" na skraj pobocza
  final String? gutterRiderId;

  /// Średnia oszczędność aerodynamiczna w tym wachlarzu [%]
  final double averageDraftingSavingsPercent;

  /// Szacowana strata czasowa do pierwszego wachlarza [s] (0.0 dla 1. wachlarza)
  final double gapToLeadEchelonSeconds;

  const EchelonFormation({
    required this.echelonIndex,
    required this.riderIds,
    required this.capacity,
    required this.isGutterFormed,
    this.gutterRiderId,
    required this.averageDraftingSavingsPercent,
    this.gapToLeadEchelonSeconds = 0.0,
  });

  int get riderCount => riderIds.length;

  EchelonFormation copyWith({
    int? echelonIndex,
    List<String>? riderIds,
    int? capacity,
    bool? isGutterFormed,
    String? gutterRiderId,
    double? averageDraftingSavingsPercent,
    double? gapToLeadEchelonSeconds,
  }) {
    return EchelonFormation(
      echelonIndex: echelonIndex ?? this.echelonIndex,
      riderIds: riderIds ?? this.riderIds,
      capacity: capacity ?? this.capacity,
      isGutterFormed: isGutterFormed ?? this.isGutterFormed,
      gutterRiderId: gutterRiderId ?? this.gutterRiderId,
      averageDraftingSavingsPercent:
          averageDraftingSavingsPercent ?? this.averageDraftingSavingsPercent,
      gapToLeadEchelonSeconds: gapToLeadEchelonSeconds ?? this.gapToLeadEchelonSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'echelonIndex': echelonIndex,
      'riderIds': riderIds,
      'capacity': capacity,
      'isGutterFormed': isGutterFormed,
      'gutterRiderId': gutterRiderId,
      'averageDraftingSavingsPercent': averageDraftingSavingsPercent,
      'gapToLeadEchelonSeconds': gapToLeadEchelonSeconds,
    };
  }

  factory EchelonFormation.fromJson(Map<String, dynamic> json) {
    return EchelonFormation(
      echelonIndex: (json['echelonIndex'] as num).toInt(),
      riderIds: (json['riderIds'] as List<dynamic>).map((e) => e as String).toList(),
      capacity: (json['capacity'] as num).toInt(),
      isGutterFormed: json['isGutterFormed'] as bool,
      gutterRiderId: json['gutterRiderId'] as String?,
      averageDraftingSavingsPercent:
          (json['averageDraftingSavingsPercent'] as num).toDouble(),
      gapToLeadEchelonSeconds:
          (json['gapToLeadEchelonSeconds'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'EchelonFormation(#$echelonIndex, riders: $riderCount/$capacity, '
        'gap: ${gapToLeadEchelonSeconds.toStringAsFixed(1)}s, '
        'gutter: $isGutterFormed, avgDraft: ${averageDraftingSavingsPercent.toStringAsFixed(1)}%)';
  }
}

/// Wynik symulacji wiatru bocznego i ewentualnego rozerwania peletonu.
class CrosswindEchelonResult {
  /// Czy wiatr boczny przekroczył próg krytyczny (> 25 km/h) i wymusił formowanie wachlarzy
  final bool isEchelonActive;

  /// Rzeczywista prędkość składowej poprzecznej wiatru (crosswind) [km/h]
  final double crosswindSpeedKmh;

  /// Obliczona pojemność pojedynczego wachlarza na szerokości szosy (np. 8-12 kolarzy)
  final int echelonCapacity;

  /// Lista utworzonych wachlarzy
  final List<EchelonFormation> echelons;

  /// Przekształcone grupy wyścigowe (nowy 1. peleton, 2. grupa pościgowa, kolejne wachlarze)
  final List<PelotonGroup> resultingGroups;

  /// Kolarze, którzy stracili osłonę aerodynamiczną ("zostali w rynsztoku na rancie")
  final List<String> gutterRiderIds;

  const CrosswindEchelonResult({
    required this.isEchelonActive,
    required this.crosswindSpeedKmh,
    required this.echelonCapacity,
    required this.echelons,
    required this.resultingGroups,
    required this.gutterRiderIds,
  });

  @override
  String toString() {
    return 'CrosswindEchelonResult(active: $isEchelonActive, crosswind: ${crosswindSpeedKmh.toStringAsFixed(1)}km/h, '
        'capacity: $echelonCapacity, echelons: ${echelons.length}, '
        'groups: ${resultingGroups.length}, inGutter: ${gutterRiderIds.length})';
  }
}

/// Silnik symulujący taktykę i fizykę wachlarzy (echelons / ranty) przy silnym wietrze bocznym.
///
/// Zasady działania:
/// 1. Gdy boczny wiatr przekracza 25 km/h, kolarze nie mogą draftować prosto za sobą i muszą
///    układać się po przekątnej (wachlarz) w stronę zawietrzną.
/// 2. Szerokość szosy ogranicza liczbę kolarzy mieszczących się w jednym wachlarzu (do 8-12 osób).
/// 3. Kolarze z niskimi umiejętnościami pozycjonowania ([RiderSkills.raceIq], [RiderSkills.bikeHandling],
///    [RiderSkills.draftingEfficiency]) zostają zepchnięci na skraj szosy ("do rynsztoka / na rant").
/// 4. Kolarz na rancie traci osłonę aerodynamiczną (pełny wiatr), otwiera się luka, a peleton
///    ulega natychmiastowemu rozerwaniu na kilka mniejszych grup.
class EchelonCrosswindEngine {
  EchelonCrosswindEngine._();

  /// Krytyczna prędkość wiatru bocznego wywołująca rzeź na wachlarzach [km/h]
  static const double crosswindThresholdKmh = 25.0;

  /// Minimalna pojemność wachlarza na bardzo wąskiej szosie (np. bruk lub grobla)
  static const double minEchelonCapacity = 6.0;

  /// Maksymalna pojemność wachlarza na szerokiej arterii
  static const double maxEchelonCapacity = 14.0;

  /// Oblicza składową prędkości poprzecznej wiatru (crosswind) w km/h.
  ///
  /// Parametry:
  /// - [windSpeedKmh]: całkowita prędkość wiatru [km/h]
  /// - [relativeWindAngleDegrees]: kąt wiatru względem osi jazdy (0° = w twarz, 90° = czysty boczny, 180° = w plecy)
  static double calculateCrosswindSpeedKmh({
    required double windSpeedKmh,
    required double relativeWindAngleDegrees,
  }) {
    final double betaRad = relativeWindAngleDegrees * (math.pi / 180.0);
    // Składowa poprzeczna to sinus kąta wiatru
    return (windSpeedKmh * math.sin(betaRad)).abs();
  }

  /// Wylicza maksymalną liczbę kolarzy mogących zmieścić się w jednym wachlarzu
  /// przy danej szerokości drogi i sile wiatru.
  ///
  /// Wzór geometryczny:
  /// Kolarz w wachlarzu wymaga przesunięcia bocznego ok. 0.65 - 0.75m od poprzednika.
  /// Capacity = floor((roadWidth - buffer) / lateralOffset) + 1
  static int calculateEchelonCapacity({
    required double roadWidthMeters,
    required double crosswindSpeedKmh,
  }) {
    // Im silniejszy wiatr boczny, tym większe przesunięcie kątowe (wachlarz jest bardziej płaski)
    final double windSeverityFactor = (crosswindSpeedKmh / 35.0).clamp(0.8, 1.4);
    final double requiredLateralOffsetM = 0.60 * windSeverityFactor;

    // Bezpieczny margines od krawędzi asfaltu/pobocza
    final double usableRoadWidth = math.max(2.5, roadWidthMeters - 0.8);
    final int capacity = (usableRoadWidth / requiredLateralOffsetM).floor() + 1;

    return capacity.clamp(minEchelonCapacity.toInt(), maxEchelonCapacity.toInt());
  }

  /// Oblicza syntetyczny wskaźnik zdolności kolarza do walki o pozycję na rancie [1.0 - 100.0].
  ///
  /// Kolarz potrzebuje:
  /// - [RiderSkills.raceIq] (35%) – antycypacja, wyczucie momentu skrętu na otwarty odcinek
  /// - [RiderSkills.bikeHandling] (25%) – walka na łokcie o koło
  /// - [RiderSkills.draftingEfficiency] (25%) – trzymanie koła w korytarzu powietrznym
  /// - [RiderSkills.aeroPositioning] (15%) – stabilność sylwetki na bocznym wietrze
  static double calculateRiderCrosswindScore(RiderSkills skills) {
    return (skills.raceIq * 0.35) +
        (skills.bikeHandling * 0.25) +
        (skills.draftingEfficiency * 0.25) +
        (skills.aeroPositioning * 0.15);
  }

  /// Główna metoda symulująca zachowanie peletonu na bocznym wietrze.
  ///
  /// Jeśli prędkość wiatru bocznego przekracza 25 km/h, następuje podział grupy na wachlarze.
  /// Kolarze o słabym pozycjonowaniu i niskim draftingEfficiency wypadają na rant (rynsztok),
  /// a grupa pęka na Echelon 1, Echelon 2, Echelon 3 itd.
  ///
  /// Parametry:
  /// - [sourceGroup]: wejściowa grupa kolarska (np. główny peleton)
  /// - [segment]: odcinek trasy wyścigu ([StageSegment])
  /// - [windSpeedKmh]: prędkość wiatru na etapie w km/h
  /// - [riderSkillsMap]: mapa identyfikator kolarza -> umiejętności [RiderSkills]
  /// - [roadWidthMeters]: opcjonalna dokładna szerokość jezdni (jeśli brak, szacowana z segmentu)
  static CrosswindEchelonResult simulateCrosswindSplit({
    required PelotonGroup sourceGroup,
    required StageSegment segment,
    required double windSpeedKmh,
    required Map<String, RiderSkills> riderSkillsMap,
    double? roadWidthMeters,
  }) {
    final double roadWidth = roadWidthMeters ?? DraftingGridSystem.estimateRoadWidthMeters(segment);
    final double crosswindKmh = calculateCrosswindSpeedKmh(
      windSpeedKmh: windSpeedKmh,
      relativeWindAngleDegrees: segment.relativeWindAngleDegrees,
    );

    // Warunek aktywacji wachlarzy: wiatr boczny > 25 km/h oraz co najmniej 12 kolarzy w grupie
    final bool isEchelonActive = crosswindKmh >= crosswindThresholdKmh && sourceGroup.riderCount >= 12;

    if (!isEchelonActive) {
      // Wiatr zbyt słaby lub grupa zbyt mała na podział – standardowa siatka bez rzezi na wachlarzach
      final updatedGroup = DraftingGridSystem.arrangeGroupPositions(
        groupId: sourceGroup.id,
        groupType: sourceGroup.type,
        riderIds: sourceGroup.riderIds,
        pacemakerRiderIds: sourceGroup.pacemakerRiderIds,
        roadWidthMeters: roadWidth,
        relativeWindAngleDegrees: segment.relativeWindAngleDegrees,
        gapToRaceLeaderSeconds: sourceGroup.gapToRaceLeaderSeconds,
        distanceCoveredKm: sourceGroup.distanceCoveredKm,
        averageSpeedKmh: sourceGroup.averageSpeedKmh,
      );

      return CrosswindEchelonResult(
        isEchelonActive: false,
        crosswindSpeedKmh: crosswindKmh,
        echelonCapacity: calculateEchelonCapacity(
          roadWidthMeters: roadWidth,
          crosswindSpeedKmh: crosswindKmh,
        ),
        echelons: const [],
        resultingGroups: [updatedGroup],
        gutterRiderIds: const [],
      );
    }

    // 1. Wyznaczenie limitu kolarzy w pojedynczym wachlarzu na danej drodze (np. 8-12)
    final int echelonCapacity = calculateEchelonCapacity(
      roadWidthMeters: roadWidth,
      crosswindSpeedKmh: crosswindKmh,
    );

    // 2. Kwalifikacja kolarzy do czołowych wachlarzy w oparciu o ich pozycję i umiejętności
    // Kolarze dający zmianę (pacemakerzy) oraz kolarze o najwyższym wskaźniku walki na wietrze
    // utrzymują się z przodu.
    final List<({String riderId, double score, bool isPacemaker})> rankedRiders = [];

    for (final riderId in sourceGroup.riderIds) {
      final skills = riderSkillsMap[riderId] ??
          const RiderSkills(
            cobbles: 50,
            descending: 50,
            bikeHandling: 50,
            aeroPositioning: 50,
            draftingEfficiency: 50,
            raceIq: 50,
            rainResistance: 50,
            heatTolerance: 50,
            timeTrialPositioning: 50,
          );

      final double ability = calculateRiderCrosswindScore(skills);
      final bool isPacemaker = sourceGroup.pacemakerRiderIds.contains(riderId);

      // Pacemakerzy mają dodatkowy bonus za jazdę na samym przodzie peletonu w momencie nadejścia wiatru
      final double effectiveScore = isPacemaker ? (ability + 30.0) : ability;

      rankedRiders.add((
        riderId: riderId,
        score: effectiveScore,
        isPacemaker: isPacemaker,
      ));
    }

    // Sortowanie kolarzy: od najlepiej ustawionych do najsłabszych
    rankedRiders.sort((a, b) => b.score.compareTo(a.score));

    // 3. Podział kolarzy na kolejne wachlarze (Echelon 1, Echelon 2, Echelon 3 itd.)
    final List<EchelonFormation> echelons = [];
    final List<PelotonGroup> newGroups = [];
    final List<String> gutterRiderIds = [];

    int riderIndex = 0;
    int echelonNumber = 1;
    double accumulatedGapSeconds = sourceGroup.gapToRaceLeaderSeconds;

    while (riderIndex < rankedRiders.length) {
      final int remainingRiders = rankedRiders.length - riderIndex;
      // Pojemność bieżącego wachlarza
      final int currentCap = echelonNumber == 1
          ? echelonCapacity
          : math.min(echelonCapacity + 2, remainingRiders);

      final int takeCount = math.min(currentCap, remainingRiders);
      final List<String> echelonMembers = [];

      for (int k = 0; k < takeCount; k++) {
        echelonMembers.add(rankedRiders[riderIndex + k].riderId);
      }

      // Kolarz, który był tuż za limitem pojemności wachlarza, ląduje "w rynsztoku" (na rancie)
      String? gutterVictimId;
      bool isGutter = false;

      if (takeCount == currentCap && (riderIndex + takeCount) < rankedRiders.length) {
        gutterVictimId = rankedRiders[riderIndex + takeCount].riderId;
        gutterRiderIds.add(gutterVictimId);
        isGutter = true;
      }

      // Wyliczenie oszczędności aerodynamicznej dla wachlarza:
      // Lider ma 0%, reszta ma solidną osłonę w diagonali wachlarza (ok. 30-36%)
      final double avgSavings = echelonMembers.length <= 1
          ? 0.0
          : ((echelonMembers.length - 1) * 33.0) / echelonMembers.length;

      final echelonFormation = EchelonFormation(
        echelonIndex: echelonNumber,
        riderIds: echelonMembers,
        capacity: currentCap,
        isGutterFormed: isGutter,
        gutterRiderId: gutterVictimId,
        averageDraftingSavingsPercent: avgSavings,
        gapToLeadEchelonSeconds: accumulatedGapSeconds - sourceGroup.gapToRaceLeaderSeconds,
      );

      echelons.add(echelonFormation);

      // Utworzenie nowej grupy wyścigowej (PelotonGroup) dla tego wachlarza
      final GroupType gType;
      if (echelonNumber == 1) {
        gType = sourceGroup.type == GroupType.breakaway ? GroupType.breakaway : GroupType.peloton;
      } else if (echelonNumber == 2) {
        gType = GroupType.chaseGroup;
      } else {
        gType = GroupType.grupetto;
      }

      // Liderem wachlarza zostaje kolarz z najlepszym wynikiem
      final List<String> echelonPacemakers = [echelonMembers.first];

      final newGroup = DraftingGridSystem.arrangeGroupPositions(
        groupId: '${sourceGroup.id}_echelon_$echelonNumber',
        groupType: gType,
        riderIds: echelonMembers,
        pacemakerRiderIds: echelonPacemakers,
        roadWidthMeters: roadWidth,
        relativeWindAngleDegrees: segment.relativeWindAngleDegrees,
        gapToRaceLeaderSeconds: accumulatedGapSeconds,
        distanceCoveredKm: sourceGroup.distanceCoveredKm,
        averageSpeedKmh: math.max(30.0, sourceGroup.averageSpeedKmh - ((echelonNumber - 1) * 1.8)),
      );

      newGroups.add(newGroup);

      // Kolejny wachlarz traci dystans czasowy (luka na wietrze powiększa się o 4 - 8 sekund)
      accumulatedGapSeconds += (4.0 + (echelonNumber * 2.5));
      riderIndex += takeCount;
      echelonNumber++;
    }

    return CrosswindEchelonResult(
      isEchelonActive: true,
      crosswindSpeedKmh: crosswindKmh,
      echelonCapacity: echelonCapacity,
      echelons: echelons,
      resultingGroups: newGroups,
      gutterRiderIds: gutterRiderIds,
    );
  }
}

