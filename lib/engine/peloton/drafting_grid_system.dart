import 'dart:math' as math;
import '../../models/race/stage_segment.dart';

/// Typ grupy kolarzy na trasie wyścigu.
enum GroupType {
  /// Samotny kolarz (solo)
  solo,

  /// Ucieczka (od 2 do kilkunastu kolarzy)
  breakaway,

  /// Grupa pościgowa za ucieczką (chase group)
  chaseGroup,

  /// Główny peleton (duża grupa 30 - 150+ kolarzy)
  peloton,

  /// Grupetto / Autobus (odpadli sprinterzy i pomocnicy jadący stałym tempem)
  grupetto;

  String toJson() => name;

  static GroupType fromJson(String value) {
    return GroupType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GroupType.peloton,
    );
  }
}

/// Dokładna pozycja kolarza w formacji 2D grupy kolarskiej na szosie.
class GridRiderPosition {
  /// Unikalny identyfikator kolarza
  final String riderId;

  /// Numer rzędu od czoła grupy (0 = czoło grupy / pierwsza linia, 1 = drugi rząd, itd.)
  final int rowIndex;

  /// Numer kolumny na szerokości szosy (0 do maxColumns - 1)
  final int columnIndex;

  /// Czy kolarz jedzie aktualnie na pierwszej pozycji i daje zmianę (pulling at the front)
  final bool isPulling;

  /// Procentowa oszczędność energii dzięki osłonie aerodynamicznej [0.0% - 45.0%]
  final double draftingSavingsPercent;

  /// Współczynnik redukcji oporu powietrza jako ułamek dziesiętny [0.0 - 0.45]
  /// Do bezpośredniego użycia w kalkulatorze aero (AeroCalculator)
  double get draftingReduction => draftingSavingsPercent / 100.0;

  /// Mnożnik oporu powietrza: 1.0 dla czoła (0% zysku), 0.68 dla drugiego koła, 0.55 dla środka peletonu
  double get draftingMultiplier => 1.0 - draftingReduction;

  /// Pozycja wzdłużna względem czoła grupy w metrach (0.0 m = linia czołowa, >0 = w głębi)
  final double longitudinalOffsetMeters;

  /// Odległość boczna kolarza od środka osi jezdni w metrach
  final double lateralOffsetMeters;

  /// Czy kolarz został wypchnięty na skraj szosy / pobocze (gutter) przy silnym wietrze bocznym
  final bool isInGutter;

  const GridRiderPosition({
    required this.riderId,
    required this.rowIndex,
    required this.columnIndex,
    required this.isPulling,
    required this.draftingSavingsPercent,
    required this.longitudinalOffsetMeters,
    required this.lateralOffsetMeters,
    this.isInGutter = false,
  });

  GridRiderPosition copyWith({
    String? riderId,
    int? rowIndex,
    int? columnIndex,
    bool? isPulling,
    double? draftingSavingsPercent,
    double? longitudinalOffsetMeters,
    double? lateralOffsetMeters,
    bool? isInGutter,
  }) {
    return GridRiderPosition(
      riderId: riderId ?? this.riderId,
      rowIndex: rowIndex ?? this.rowIndex,
      columnIndex: columnIndex ?? this.columnIndex,
      isPulling: isPulling ?? this.isPulling,
      draftingSavingsPercent: draftingSavingsPercent ?? this.draftingSavingsPercent,
      longitudinalOffsetMeters: longitudinalOffsetMeters ?? this.longitudinalOffsetMeters,
      lateralOffsetMeters: lateralOffsetMeters ?? this.lateralOffsetMeters,
      isInGutter: isInGutter ?? this.isInGutter,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'rowIndex': rowIndex,
      'columnIndex': columnIndex,
      'isPulling': isPulling,
      'draftingSavingsPercent': draftingSavingsPercent,
      'longitudinalOffsetMeters': longitudinalOffsetMeters,
      'lateralOffsetMeters': lateralOffsetMeters,
      'isInGutter': isInGutter,
    };
  }

  factory GridRiderPosition.fromJson(Map<String, dynamic> json) {
    return GridRiderPosition(
      riderId: json['riderId'] as String,
      rowIndex: (json['rowIndex'] as num).toInt(),
      columnIndex: (json['columnIndex'] as num).toInt(),
      isPulling: json['isPulling'] as bool,
      draftingSavingsPercent: (json['draftingSavingsPercent'] as num).toDouble(),
      longitudinalOffsetMeters: (json['longitudinalOffsetMeters'] as num).toDouble(),
      lateralOffsetMeters: (json['lateralOffsetMeters'] as num).toDouble(),
      isInGutter: json['isInGutter'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'GridRiderPosition(rider: $riderId, row: $rowIndex, col: $columnIndex, '
        'pulling: $isPulling, savings: ${draftingSavingsPercent.toStringAsFixed(1)}%, '
        'gutter: $isInGutter)';
  }
}

/// Grupa kolarzy poruszających się wspólnie na trasie (Peleton, Ucieczka, Grupetto).
class PelotonGroup {
  final String id;
  final GroupType type;

  /// Identyfikatory kolarzy w grupie (uporządkowane od czoła do ogona)
  final List<String> riderIds;

  /// Identyfikatory kolarzy dających aktualnie zmianę na czele
  final List<String> pacemakerRiderIds;

  /// Wyliczone pozycje każdego kolarza w siatce 2D formacji
  final List<GridRiderPosition> positions;

  /// Strata czasowa grupy do lidera wyścigu w sekundach [s] (0.0 dla czoła wyścigu)
  final double gapToRaceLeaderSeconds;

  /// Pozycja kilometrowa grupy na etapie [km]
  final double distanceCoveredKm;

  /// Średnia aktualna prędkość grupy w km/h
  final double averageSpeedKmh;

  const PelotonGroup({
    required this.id,
    required this.type,
    required this.riderIds,
    required this.pacemakerRiderIds,
    required this.positions,
    this.gapToRaceLeaderSeconds = 0.0,
    this.distanceCoveredKm = 0.0,
    this.averageSpeedKmh = 42.0,
  });

  /// Liczba kolarzy w danej grupie
  int get riderCount => riderIds.length;

  /// Identyfikator kolarza prowadzącego grupę
  String? get leadRiderId => riderIds.isNotEmpty ? riderIds.first : null;

  /// Średnia oszczędność energii wszystkich kolarzy w grupie [%]
  double get averageDraftingSavingsPercent {
    if (positions.isEmpty) return 0.0;
    final total = positions.fold<double>(0.0, (sum, p) => sum + p.draftingSavingsPercent);
    return total / positions.length;
  }

  /// Znajduje pozycję siatki dla konkretnego kolarza
  GridRiderPosition? getPositionForRider(String riderId) {
    try {
      return positions.firstWhere((p) => p.riderId == riderId);
    } catch (_) {
      return null;
    }
  }

  PelotonGroup copyWith({
    String? id,
    GroupType? type,
    List<String>? riderIds,
    List<String>? pacemakerRiderIds,
    List<GridRiderPosition>? positions,
    double? gapToRaceLeaderSeconds,
    double? distanceCoveredKm,
    double? averageSpeedKmh,
  }) {
    return PelotonGroup(
      id: id ?? this.id,
      type: type ?? this.type,
      riderIds: riderIds ?? this.riderIds,
      pacemakerRiderIds: pacemakerRiderIds ?? this.pacemakerRiderIds,
      positions: positions ?? this.positions,
      gapToRaceLeaderSeconds: gapToRaceLeaderSeconds ?? this.gapToRaceLeaderSeconds,
      distanceCoveredKm: distanceCoveredKm ?? this.distanceCoveredKm,
      averageSpeedKmh: averageSpeedKmh ?? this.averageSpeedKmh,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toJson(),
      'riderIds': riderIds,
      'pacemakerRiderIds': pacemakerRiderIds,
      'positions': positions.map((p) => p.toJson()).toList(),
      'gapToRaceLeaderSeconds': gapToRaceLeaderSeconds,
      'distanceCoveredKm': distanceCoveredKm,
      'averageSpeedKmh': averageSpeedKmh,
    };
  }

  factory PelotonGroup.fromJson(Map<String, dynamic> json) {
    return PelotonGroup(
      id: json['id'] as String,
      type: GroupType.fromJson(json['type'] as String),
      riderIds: (json['riderIds'] as List<dynamic>).map((e) => e as String).toList(),
      pacemakerRiderIds: (json['pacemakerRiderIds'] as List<dynamic>).map((e) => e as String).toList(),
      positions: (json['positions'] as List<dynamic>)
          .map((e) => GridRiderPosition.fromJson(e as Map<String, dynamic>))
          .toList(),
      gapToRaceLeaderSeconds: (json['gapToRaceLeaderSeconds'] as num?)?.toDouble() ?? 0.0,
      distanceCoveredKm: (json['distanceCoveredKm'] as num?)?.toDouble() ?? 0.0,
      averageSpeedKmh: (json['averageSpeedKmh'] as num?)?.toDouble() ?? 42.0,
    );
  }

  @override
  String toString() {
    return 'PelotonGroup($id, ${type.name}, riders: $riderCount, '
        'gap: ${gapToRaceLeaderSeconds.toStringAsFixed(1)}s, '
        'avgDraft: ${averageDraftingSavingsPercent.toStringAsFixed(1)}%)';
  }
}

/// Zaawansowany system siatki aerodynamicznej i pozycjonowania kolarzy na szerokości szosy.
///
/// Wylicza poziom oszczędności energii (Drafting Factor) dla każdego kolarza:
/// - Kolarz na czele dający zmianę: 0.0% oszczędności (mnożnik 1.0)
/// - Drugi kolarz bezpośrednio na kole: 32.0% oszczędności (mnożnik 0.68)
/// - Trzeci kolarz w linii: ~38.0% oszczędności
/// - Środek szerokiego peletonu (otoczony kolarzami): do 45.0% oszczędności (mnożnik 0.55)
///
/// Uwzględnia szerokość szosy [roadWidthMeters] – zwężenia drogi wymuszają rozciągnięcie
/// peletonu w pojedynczy rząd (wężyk), spychając tylnych kolarzy na dalsze rzędy i ograniczając
/// szerokie formacje wachlarzowe (echelon).
class DraftingGridSystem {
  DraftingGridSystem._();

  /// Maksymalna oszczędność w głębi szerokiego peletonu [%]
  static const double maxPelotonSavingsPercent = 45.0;

  /// Oszczędność kolarza jadącego bezpośrednio za kołem lidera [%]
  static const double secondWheelSavingsPercent = 32.0;

  /// Oszczędność kolarza na czele dającego zmianę [%]
  static const double pullingFrontSavingsPercent = 0.0;

  /// Standardowa szerokość zajmowana przez jednego kolarza z kierownicą i łokciami [m]
  static const double lateralSlotWidthMeters = 0.95;

  /// Średnia odległość osi przedniej od tylnego koła w zwartej grupie [m]
  static const double longitudinalRowSpacingMeters = 1.65;

  /// Szacuje szerokość jezdni [m] na podstawie parametrów segmentu trasy ([StageSegment]).
  static double estimateRoadWidthMeters(StageSegment segment) {
    switch (segment.surfaceType) {
      case SegmentSurfaceType.smoothAsphalt:
        // Na gładkim asfalcie szerokość zależy od trudności technicznej (autostrada vs miejskie zwężenie)
        if (segment.technicalDifficulty > 70.0) {
          return 4.2; // Wąskie miejskie uliczki, wysepki
        } else if (segment.technicalDifficulty > 40.0) {
          return 6.0; // Standardowa dwukierunkowa szosa krajowa
        }
        return 7.5; // Szeroka arteria, dojazd do mety
      case SegmentSurfaceType.concrete:
        return 6.0;
      case SegmentSurfaceType.roughAsphalt:
        return 5.5;
      case SegmentSurfaceType.gravelStrade:
        return 4.5; // Szuter toskański (droga gruntowa)
      case SegmentSurfaceType.cobblestonesSector1:
      case SegmentSurfaceType.cobblestonesSector2:
        return 4.2;
      case SegmentSurfaceType.cobblestonesSector3:
        return 3.6; // Średni sektor brukowy (np. Haveluy)
      case SegmentSurfaceType.cobblestonesSector4:
      case SegmentSurfaceType.cobblestonesSector5:
        return 3.0; // Piekielnie wąski sektor (np. Trouée d'Arenberg, Carrefour de l'Arbre)
    }
  }

  /// Wyznacza maksymalną liczbę kolarzy mogących jechać obok siebie (w jednym rzędzie)
  /// przy danej szerokości szosy.
  static int calculateMaxColumnsForRoadWidth(double roadWidthMeters) {
    final double safeWidth = math.max(1.8, roadWidthMeters);
    final int cols = (safeWidth / lateralSlotWidthMeters).floor();
    return cols.clamp(1, 10);
  }

  /// Oblicza oszczędność aerodynamiczną kolarza [0.0% - 45.0%] w oparciu o jego pozycję w siatce.
  ///
  /// Parametry:
  /// - [rowIndex]: numer rzędu od czoła (0 = czoło)
  /// - [columnIndex]: pozycja boczna (0 do maxColumns - 1)
  /// - [maxColumns]: liczba kolarzy mieszczących się obok siebie na szosie
  /// - [isPulling]: czy kolarz jedzie na czele i dyktuje tempo
  /// - [groupType]: typ formacji grupy
  /// - [totalRows]: łączna liczba rzędów w grupie
  static double calculateRiderSavings({
    required int rowIndex,
    required int columnIndex,
    required int maxColumns,
    required bool isPulling,
    required GroupType groupType,
    required int totalRows,
  }) {
    // 1. Kolarz dający zmianę na czele zawsze ponosi pełen opór (0% oszczędności)
    if (isPulling || rowIndex == 0) {
      return pullingFrontSavingsPercent;
    }

    // 2. Kolarz w drugim rzędzie (bezpośrednio za kołem lidera)
    if (rowIndex == 1) {
      return secondWheelSavingsPercent; // Dokładnie 32%
    }

    // 3. Trzeci rząd (dobra osłona w tunelu aerodynamicznym)
    if (rowIndex == 2) {
      return 37.5;
    }

    // 4. Rzędy od 4 wzwyż (głęboki peleton / duża grupa):
    if (groupType == GroupType.peloton || groupType == GroupType.grupetto) {
      // Czy kolarz znajduje się na skrajnej kolumnie (brak osłony bocznej z jednej strony)
      final bool isEdgeColumn = (columnIndex == 0 || columnIndex == (maxColumns - 1));

      // Kolarz na ogonie grupy ma nieco mniejsze ciśnienie wsteczne
      final bool isTailRow = (rowIndex >= totalRows - 2);

      if (!isEdgeColumn && !isTailRow && maxColumns >= 3 && rowIndex >= 3) {
        // Idealny środek szerokiego peletonu (otoczony z przodu, z tyłu i z boków):
        // Maksymalna ochrona aerodynamiczna do 45% oszczędności
        return maxPelotonSavingsPercent;
      } else if (!isEdgeColumn) {
        // Środek, ale bliżej ogona lub w węższej kolumnie
        return 42.0;
      } else {
        // Skrajna krawędź peletonu (skraj drogi lub korytarz wiatrowy)
        return 36.0;
      }
    }

    // Dla małych grup (ucieczka, pościg 2-8 kolarzy w linii pojedynczej / podwójnej)
    if (groupType == GroupType.breakaway || groupType == GroupType.chaseGroup) {
      // W ucieczce kolarze za 2. kołem osiągają stabilne 36% - 40%
      final double progress = math.min(1.0, (rowIndex - 1) / 3.0);
      return secondWheelSavingsPercent + (progress * 7.0); // 32.0% do 39.0%
    }

    return 35.0;
  }

  /// Główna metoda układająca pozycje kolarzy w siatce grupy na zadanym odcinku szosy.
  ///
  /// Uwzględnia:
  /// - Identyfikatory kolarzy w kolejności taktycznej (od czoła do tyłu)
  /// - Listę kolarzy dających zmianę na czele ([pacemakerRiderIds])
  /// - Szerokość drogi na segmencie [roadWidthMeters]
  /// - Wpływ wiatru bocznego i ryzyko wypchnięcia na pobocze (gutter / wachlarz)
  ///
  /// Zwraca zaktualizowany obiekt [PelotonGroup] z kompletem pozycji [GridRiderPosition].
  static PelotonGroup arrangeGroupPositions({
    required String groupId,
    required GroupType groupType,
    required List<String> riderIds,
    required List<String> pacemakerRiderIds,
    required double roadWidthMeters,
    double relativeWindAngleDegrees = 0.0,
    double gapToRaceLeaderSeconds = 0.0,
    double distanceCoveredKm = 0.0,
    double averageSpeedKmh = 42.0,
  }) {
    if (riderIds.isEmpty) {
      return PelotonGroup(
        id: groupId,
        type: groupType,
        riderIds: const [],
        pacemakerRiderIds: const [],
        positions: const [],
        gapToRaceLeaderSeconds: gapToRaceLeaderSeconds,
        distanceCoveredKm: distanceCoveredKm,
        averageSpeedKmh: averageSpeedKmh,
      );
    }

    // 1. Obliczenie przepustowości jezdni (liczba kolumn kolarzy obok siebie)
    final int maxCols = calculateMaxColumnsForRoadWidth(roadWidthMeters);

    // W małej ucieczce (np. 3-6 kolarzy) rzadko jedzie się w 6 rzędach – formacja zwęża się do 1-2 kolumn
    int effectiveColumns;
    if (groupType == GroupType.breakaway || groupType == GroupType.solo) {
      effectiveColumns = math.min(maxCols, riderIds.length <= 4 ? 1 : 2);
    } else if (groupType == GroupType.chaseGroup) {
      effectiveColumns = math.min(maxCols, 3);
    } else {
      effectiveColumns = maxCols;
    }

    // 2. Kolarze na czele (pacemakerzy dający zmianę)
    final Set<String> pacemakersSet = pacemakerRiderIds.isNotEmpty
        ? pacemakerRiderIds.toSet()
        : {riderIds.first};

    // 3. Rozmieszczenie kolarzy w wierszach i kolumnach siatki
    final List<GridRiderPosition> positions = [];
    final int totalRiders = riderIds.length;
    final int estimatedTotalRows = (totalRiders / effectiveColumns).ceil();

    // Wyznaczenie kąta bocznego wiatru (czy tworzy się naturalny wachlarz / echelon)
    final bool isCrosswind = relativeWindAngleDegrees > 35.0 && relativeWindAngleDegrees < 145.0;
    // Maksymalna pojemność wachlarza na szerokości szosy przy wietrze bocznym
    final int echelonCapacity = (roadWidthMeters / 1.15).floor().clamp(3, 14);

    int currentRow = 0;
    int currentCol = 0;

    for (int i = 0; i < totalRiders; i++) {
      final String rId = riderIds[i];
      final bool isLeaderPulling = pacemakersSet.contains(rId);

      // Kolarze dający zmianę zawsze są na czele (rząd 0)
      int assignedRow;
      int assignedCol;

      if (isLeaderPulling) {
        assignedRow = 0;
        assignedCol = currentCol % effectiveColumns;
        currentCol++;
        if (currentCol >= effectiveColumns && i < pacemakersSet.length - 1) {
          currentRow++;
          currentCol = 0;
        }
      } else {
        // Kolarze osłaniani
        if (currentRow == 0) {
          currentRow = 1;
          currentCol = 0;
        }
        assignedRow = currentRow;
        assignedCol = currentCol;

        currentCol++;
        if (currentCol >= effectiveColumns) {
          currentRow++;
          currentCol = 0;
        }
      }

      // Weryfikacja czy przy wietrze bocznym kolarz mieści się w wachlarzu
      bool inGutter = false;
      if (isCrosswind && i >= echelonCapacity && groupType == GroupType.peloton) {
        inGutter = true;
      }

      // Obliczenie oszczędności aerodynamicznej
      double savings = calculateRiderSavings(
        rowIndex: assignedRow,
        columnIndex: assignedCol,
        maxColumns: effectiveColumns,
        isPulling: isLeaderPulling,
        groupType: groupType,
        totalRows: estimatedTotalRows,
      );

      // Jeśli kolarz został wypchnięty na pobocze (gutter) przy wietrze bocznym,
      // jego osłona drastycznie spada o połowę
      if (inGutter) {
        savings = math.max(12.0, savings * 0.45);
      }

      // Współrzędne fizyczne w metrach
      final double longOffset = assignedRow * longitudinalRowSpacingMeters;
      final double latOffset = (assignedCol - ((effectiveColumns - 1) / 2.0)) * lateralSlotWidthMeters;

      positions.add(
        GridRiderPosition(
          riderId: rId,
          rowIndex: assignedRow,
          columnIndex: assignedCol,
          isPulling: isLeaderPulling,
          draftingSavingsPercent: savings,
          longitudinalOffsetMeters: longOffset,
          lateralOffsetMeters: latOffset,
          isInGutter: inGutter,
        ),
      );
    }

    return PelotonGroup(
      id: groupId,
      type: groupType,
      riderIds: riderIds,
      pacemakerRiderIds: pacemakersSet.toList(),
      positions: positions,
      gapToRaceLeaderSeconds: gapToRaceLeaderSeconds,
      distanceCoveredKm: distanceCoveredKm,
      averageSpeedKmh: averageSpeedKmh,
    );
  }
}

