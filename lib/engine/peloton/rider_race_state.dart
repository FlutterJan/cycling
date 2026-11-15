/// Polecenia taktyczne wydawane kolarzowi przez dyrektora sportowego podczas etapu.
enum TacticalOrder {
  /// Utrzymuj pozycję w grupie / jedź w szyku
  holdPosition,

  /// Nadawaj tempo / dawaj mocne zmiany na czele grupy
  pullGroup,

  /// Chroń lidera zespołu (osłaniaj go przed wiatrem, kasuj ataki)
  protectLeader,

  /// Przeprowadź atak / skocz z grupy / inicjuj ucieczkę
  attack,

  /// Trzymaj się koła rywala / reaguj na skoki innych kolarzy
  followWheels,

  /// Zjedź do wozu technicznego po bidony i batony dla zespołu
  fetchBidonsFromCar,

  /// Maksymalnie oszczędzaj energię w głębi peletonu / na ogonie
  saveEnergy;

  String toJson() => name;

  static TacticalOrder fromJson(String value) {
    return TacticalOrder.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TacticalOrder.holdPosition,
    );
  }

  /// Czytelna etykieta polecenia taktycznego
  String get label {
    switch (this) {
      case TacticalOrder.holdPosition:
        return 'Utrzymuj pozycję';
      case TacticalOrder.pullGroup:
        return 'Dawaj zmiany na czele';
      case TacticalOrder.protectLeader:
        return 'Chroń lidera';
      case TacticalOrder.attack:
        return 'Atakuj!';
      case TacticalOrder.followWheels:
        return 'Pilnuj koła';
      case TacticalOrder.fetchBidonsFromCar:
        return 'Zjedź po bidony';
      case TacticalOrder.saveEnergy:
        return 'Oszczędzaj siły';
    }
  }

  /// Krótki opis działania taktycznego
  String get description {
    switch (this) {
      case TacticalOrder.holdPosition:
        return 'Kolarz jedzie swoim tempem na stałej pozycji w szyku.';
      case TacticalOrder.pullGroup:
        return 'Kolarz wychodzi na pierwszą linię i dyktuje ostre tempo.';
      case TacticalOrder.protectLeader:
        return 'Kolarz jedzie tuż przed liderem, tnąc wiatr i chroniąc przed kraksami.';
      case TacticalOrder.attack:
        return 'Kolarz generuje maksymalną moc beztlenową, próbując rozerwać grupę.';
      case TacticalOrder.followWheels:
        return 'Kolarz natychmiast reaguje na ruchy najgroźniejszych rywali.';
      case TacticalOrder.fetchBidonsFromCar:
        return 'Kolarz spływa na tył kolumny samochodów, by pobrać zapasy dla kolegów.';
      case TacticalOrder.saveEnergy:
        return 'Kolarz chowa się w najgłębszym tunelu aerodynamicznym peletonu.';
    }
  }
}

/// Dynamiczny stan pojedynczego kolarza w trakcie symulacji etapu wyścigu.
class RiderRaceState {
  /// Unikalny identyfikator kolarza
  final String riderId;

  /// Identyfikator zespołu kolarza
  final String teamId;

  /// Pokonany dystans na etapie w metrach [m]
  final double distanceCoveredMeters;

  /// Pozycja boczna na szerokości szosy:
  /// -1.0 = lewa krawędź jezdni, 0.0 = środek drogi, 1.0 = prawa krawędź
  final double lateralPositionRoad;

  /// Aktualna prędkość chwilowa kolarza w metrach na sekundę [m/s]
  final double currentSpeedMs;

  /// Aktualna moc mechaniczna generowana na pedałach [W]
  final int currentWatts;

  /// Aktualna kadencja pedałowania w obrotach na minutę [RPM]
  final int currentCadenceRpm;

  /// Aktualne tętno kolarza w uderzeniach na minutę [bpm]
  final int currentHeartRate;

  /// Dostępny zapas energii beztlenowej W' w dżulach [J]
  final double currentWPrime;

  /// Zapas zmagazynowanego glikogenu w gramach [g]
  final double currentGlycogen;

  /// Liczba bidonów z wodą/izotonikiem w koszykach (0 do 2)
  final int bidonsLeft;

  /// Liczba żeli energetycznych w kieszonkach koszulki (0 do 6)
  final int gelsLeft;

  /// Aktywne polecenie taktyczne dyrektora sportowego
  final TacticalOrder activeTacticalOrder;

  /// Indeks grupy, w której aktualnie znajduje się kolarz:
  /// 0 = ucieczka / czoło wyścigu, 1 = peleton / pościg, itd.
  final int groupIndex;

  /// Strata czasowa do lidera wyścigu w sekundach [s] (0.0 jeśli na czele)
  final double timeGapToLeaderSeconds;

  const RiderRaceState({
    required this.riderId,
    required this.teamId,
    required this.distanceCoveredMeters,
    required this.lateralPositionRoad,
    required this.currentSpeedMs,
    required this.currentWatts,
    required this.currentCadenceRpm,
    required this.currentHeartRate,
    required this.currentWPrime,
    required this.currentGlycogen,
    required this.bidonsLeft,
    required this.gelsLeft,
    required this.activeTacticalOrder,
    required this.groupIndex,
    required this.timeGapToLeaderSeconds,
  });

  /// Początkowy stan kolarza na linii startu etapu
  factory RiderRaceState.initial({
    required String riderId,
    required String teamId,
    required double initialWPrimeJoules,
    required double initialGlycogenGrams,
    int initialHeartRateBpm = 55,
    int groupIndex = 0,
    double initialLateralPosition = 0.0,
    TacticalOrder initialOrder = TacticalOrder.holdPosition,
  }) {
    return RiderRaceState(
      riderId: riderId,
      teamId: teamId,
      distanceCoveredMeters: 0.0,
      lateralPositionRoad: initialLateralPosition.clamp(-1.0, 1.0),
      currentSpeedMs: 0.0,
      currentWatts: 0,
      currentCadenceRpm: 0,
      currentHeartRate: initialHeartRateBpm,
      currentWPrime: initialWPrimeJoules,
      currentGlycogen: initialGlycogenGrams,
      bidonsLeft: 2,
      gelsLeft: 4,
      activeTacticalOrder: initialOrder,
      groupIndex: groupIndex,
      timeGapToLeaderSeconds: 0.0,
    );
  }

  /// Aktualna prędkość kolarza w km/h
  double get currentSpeedKmh => currentSpeedMs * 3.6;

  /// Pokonany dystans w kilometrach [km]
  double get distanceCoveredKm => distanceCoveredMeters / 1000.0;

  /// Alias dystansu w metrach
  double get currentDistanceMeters => distanceCoveredMeters;

  /// Czy kolarz wiezie pełny zapas płynów (2 bidony)
  bool get hasFullBidons => bidonsLeft >= 2;

  /// Czy kolarz nie ma już nic do picia (0 bidonów)
  bool get isOutOfHydration => bidonsLeft <= 0;

  /// Czy kolarz posiada jeszcze żele energetyczne
  bool get hasGels => gelsLeft > 0;

  /// Alias dla generowanej mocy [W]
  double get currentPowerWatts => currentWatts.toDouble();

  /// Alias dla tętna [bpm]
  double get heartRateBpm => currentHeartRate.toDouble();

  /// Szacunkowa strefa tętna (1-7)
  int get heartRateZone {
    if (currentHeartRate < 120) return 1;
    if (currentHeartRate < 145) return 2;
    if (currentHeartRate < 160) return 3;
    if (currentHeartRate < 172) return 4;
    if (currentHeartRate < 182) return 5;
    if (currentHeartRate < 192) return 6;
    return 7;
  }

  /// Alias dla dostępnego zapasu W' [J]
  double get wPrimeBalanceJoules => currentWPrime;

  /// Alias dla zmagazynowanego glikogenu [g]
  double get glycogenRemainingGrams => currentGlycogen;

  /// Alias dla kadencji [rpm]
  double get cadenceRpm => currentCadenceRpm.toDouble();

  /// Alias dla aktywnego trybu taktycznego
  TacticalOrder get activeTacticalMode => activeTacticalOrder;

  /// Oszczędność aerodynamiczna [0.0 - 0.45]
  double get draftingSavingsPercent {
    if (groupIndex > 0) return 0.32;
    return 0.0;
  }

  RiderRaceState copyWith({
    String? riderId,
    String? teamId,
    double? distanceCoveredMeters,
    double? lateralPositionRoad,
    double? currentSpeedMs,
    int? currentWatts,
    int? currentCadenceRpm,
    int? currentHeartRate,
    double? currentWPrime,
    double? currentGlycogen,
    int? bidonsLeft,
    int? gelsLeft,
    TacticalOrder? activeTacticalOrder,
    int? groupIndex,
    double? timeGapToLeaderSeconds,
  }) {
    return RiderRaceState(
      riderId: riderId ?? this.riderId,
      teamId: teamId ?? this.teamId,
      distanceCoveredMeters: distanceCoveredMeters ?? this.distanceCoveredMeters,
      lateralPositionRoad: (lateralPositionRoad ?? this.lateralPositionRoad).clamp(-1.0, 1.0),
      currentSpeedMs: currentSpeedMs ?? this.currentSpeedMs,
      currentWatts: currentWatts ?? this.currentWatts,
      currentCadenceRpm: currentCadenceRpm ?? this.currentCadenceRpm,
      currentHeartRate: currentHeartRate ?? this.currentHeartRate,
      currentWPrime: currentWPrime ?? this.currentWPrime,
      currentGlycogen: currentGlycogen ?? this.currentGlycogen,
      bidonsLeft: (bidonsLeft ?? this.bidonsLeft).clamp(0, 2),
      gelsLeft: (gelsLeft ?? this.gelsLeft).clamp(0, 6),
      activeTacticalOrder: activeTacticalOrder ?? this.activeTacticalOrder,
      groupIndex: groupIndex ?? this.groupIndex,
      timeGapToLeaderSeconds: timeGapToLeaderSeconds ?? this.timeGapToLeaderSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'teamId': teamId,
      'distanceCoveredMeters': distanceCoveredMeters,
      'lateralPositionRoad': lateralPositionRoad,
      'currentSpeedMs': currentSpeedMs,
      'currentWatts': currentWatts,
      'currentCadenceRpm': currentCadenceRpm,
      'currentHeartRate': currentHeartRate,
      'currentWPrime': currentWPrime,
      'currentGlycogen': currentGlycogen,
      'bidonsLeft': bidonsLeft,
      'gelsLeft': gelsLeft,
      'activeTacticalOrder': activeTacticalOrder.toJson(),
      'groupIndex': groupIndex,
      'timeGapToLeaderSeconds': timeGapToLeaderSeconds,
    };
  }

  factory RiderRaceState.fromJson(Map<String, dynamic> json) {
    return RiderRaceState(
      riderId: json['riderId'] as String,
      teamId: json['teamId'] as String,
      distanceCoveredMeters: (json['distanceCoveredMeters'] as num).toDouble(),
      lateralPositionRoad: (json['lateralPositionRoad'] as num).toDouble().clamp(-1.0, 1.0),
      currentSpeedMs: (json['currentSpeedMs'] as num).toDouble(),
      currentWatts: (json['currentWatts'] as num).toInt(),
      currentCadenceRpm: (json['currentCadenceRpm'] as num).toInt(),
      currentHeartRate: (json['currentHeartRate'] as num).toInt(),
      currentWPrime: (json['currentWPrime'] as num).toDouble(),
      currentGlycogen: (json['currentGlycogen'] as num).toDouble(),
      bidonsLeft: (json['bidonsLeft'] as num).toInt().clamp(0, 2),
      gelsLeft: (json['gelsLeft'] as num).toInt().clamp(0, 6),
      activeTacticalOrder: TacticalOrder.fromJson(json['activeTacticalOrder'] as String),
      groupIndex: (json['groupIndex'] as num).toInt(),
      timeGapToLeaderSeconds: (json['timeGapToLeaderSeconds'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiderRaceState &&
        other.riderId == riderId &&
        other.teamId == teamId &&
        other.distanceCoveredMeters == distanceCoveredMeters &&
        other.lateralPositionRoad == lateralPositionRoad &&
        other.currentSpeedMs == currentSpeedMs &&
        other.currentWatts == currentWatts &&
        other.currentCadenceRpm == currentCadenceRpm &&
        other.currentHeartRate == currentHeartRate &&
        other.currentWPrime == currentWPrime &&
        other.currentGlycogen == currentGlycogen &&
        other.bidonsLeft == bidonsLeft &&
        other.gelsLeft == gelsLeft &&
        other.activeTacticalOrder == activeTacticalOrder &&
        other.groupIndex == groupIndex &&
        other.timeGapToLeaderSeconds == timeGapToLeaderSeconds;
  }

  @override
  int get hashCode {
    return Object.hash(
      riderId,
      teamId,
      distanceCoveredMeters,
      lateralPositionRoad,
      currentSpeedMs,
      currentWatts,
      currentCadenceRpm,
      currentHeartRate,
      currentWPrime,
      currentGlycogen,
      bidonsLeft,
      gelsLeft,
      activeTacticalOrder,
      groupIndex,
      timeGapToLeaderSeconds,
    );
  }

  @override
  String toString() {
    return 'RiderRaceState(rider: $riderId, dist: ${distanceCoveredKm.toStringAsFixed(1)}km, '
        'v: ${currentSpeedKmh.toStringAsFixed(1)}km/h, P: ${currentWatts}W, '
        'HR: ${currentHeartRate}bpm, W\': ${currentWPrime.toStringAsFixed(0)}J, '
        'glycogen: ${currentGlycogen.toStringAsFixed(0)}g, bidons: $bidonsLeft, gels: $gelsLeft, '
        'order: ${activeTacticalOrder.name}, grp: $groupIndex, gap: ${timeGapToLeaderSeconds.toStringAsFixed(1)}s)';
  }
}

