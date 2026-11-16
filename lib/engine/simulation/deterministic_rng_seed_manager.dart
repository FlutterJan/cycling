// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math' as math;

/// Domeny losowości w symulacji etapu.
///
/// Separacja domen gwarantuje, że pobranie liczby losowej w jednej domenie
/// (np. dodatkowe sprawdzenie kamery powtórki lub rozkaz taktyczny gracza)
/// nigdy nie przesuwa sekwencji losowej w innej domenie (np. podmuchy wiatru
/// lub decyzje AI rywali).
enum RngDomain {
  /// Podmuchy wiatru, zmiana kierunku i turbulencje boczne.
  windGusts,

  /// Zachowania taktyczne AI (ataki, blefowanie, reakcje na odjazdy).
  aiBehavior,

  /// Zdarzenia losowe: kraksy, defekty mechaniczne, przebicia opon.
  incidents,

  /// Dyspozycja dnia i biorytm kolarzy.
  dayCondition,

  /// Warunki pogodowe (opady, temperatura, mgła górska).
  weather,

  /// Mikro-ruchy peletonu (Boids, formowanie wachlarzy, tasowanie pozycji).
  pelotonMicroMovement,

  /// Wybór dynamicznych ujęć kamery podczas powtórek `StageReplayRecorder`.
  replayCamera,
}

/// Migawka wewnętrznego stanu strumienia PRNG umożliwiająca zapis i przywrócenie
/// generatora co do pojedynczego wywołania (np. przy zapisie/wczytaniu powtórki).
class PrngStreamSnapshot {
  final RngDomain domain;
  final int initialSeed;
  final int state;
  final int callCount;

  const PrngStreamSnapshot({
    required this.domain,
    required this.initialSeed,
    required this.state,
    required this.callCount,
  });

  Map<String, dynamic> toJson() => {
        'domain': domain.name,
        'initialSeed': initialSeed,
        'state': state,
        'callCount': callCount,
      };

  factory PrngStreamSnapshot.fromJson(Map<String, dynamic> json) {
    final domainName = json['domain'] as String? ?? RngDomain.aiBehavior.name;
    final domain = RngDomain.values.firstWhere(
      (d) => d.name == domainName,
      orElse: () => RngDomain.aiBehavior,
    );
    return PrngStreamSnapshot(
      domain: domain,
      initialSeed: (json['initialSeed'] as num).toInt(),
      state: (json['state'] as num).toInt(),
      callCount: (json['callCount'] as num).toInt(),
    );
  }
}

/// Deterministyczny strumień PRNG (algorytm Mulberry32) implementujący [math.Random].
///
/// Gwarantuje identyczną sekwencję bitową na każdej platformie (Windows, Web, mobile)
/// niezależnie od implementacji wewnętrznej `dart:math.Random`.
class DeterministicPrngStream implements math.Random {
  final RngDomain domain;
  final int initialSeed;

  int _state;
  int _callCount;

  DeterministicPrngStream({
    required this.domain,
    required int seed,
  })  : initialSeed = _normalizeSeed32(seed),
        _state = _normalizeSeed32(seed),
        _callCount = 0;

  DeterministicPrngStream._restored({
    required this.domain,
    required this.initialSeed,
    required int state,
    required int callCount,
  })  : _state = state & 0xFFFFFFFF,
        _callCount = callCount;

  /// Liczba dotychczasowych wywołań generatora w tym strumieniu.
  int get callCount => _callCount;

  /// Aktualny 32-bitowy stan wewnętrzny.
  int get currentState => _state;

  static int _normalizeSeed32(int seed) {
    final masked = seed & 0xFFFFFFFF;
    return masked == 0 ? 0x6D2B79F5 : masked;
  }

  /// Następna deterministyczna liczba 32-bitowa bez znaku `[0, 2^32 - 1]`.
  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _state;
    t = _imul32(t ^ (t >>> 15), t | 1);
    t = (t ^ ((t + _imul32(t ^ (t >>> 7), t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF;
    final result = (t ^ (t >>> 14)) & 0xFFFFFFFF;
    _callCount++;
    return result;
  }

  static int _imul32(int a, int b) {
    final aLow = a & 0xFFFF;
    final aHigh = (a >>> 16) & 0xFFFF;
    final bLow = b & 0xFFFF;
    final bHigh = (b >>> 16) & 0xFFFF;
    final low = aLow * bLow;
    final mid = ((aLow * bHigh + aHigh * bLow) & 0xFFFF) << 16;
    return (low + mid) & 0xFFFFFFFF;
  }

  @override
  int nextInt(int max) {
    if (max <= 0) {
      throw RangeError.range(max, 1, null, 'max', 'Must be positive');
    }
    if (max > 0xFFFFFFFF) {
      final hi = nextUint32();
      final lo = nextUint32();
      final combined = ((hi & 0x1FFFFF) << 32) | lo;
      return combined % max;
    }
    // Redukcja Lemire'a / odrzucanie modulo eliminuje bias dla potęg niebędących 2^k.
    final limit = 0x100000000 - (0x100000000 % max);
    int r = nextUint32();
    while (r >= limit) {
      r = nextUint32();
    }
    return r % max;
  }

  @override
  double nextDouble() {
    // 53-bitowa precyzja mantysy IEEE 754 w zakresie [0.0, 1.0)
    final hi = nextUint32() >>> 5; // 27 bitów
    final lo = nextUint32() >>> 6; // 26 bitów
    return ((hi * 67108864.0) + lo) / 9007199254740992.0;
  }

  @override
  bool nextBool() => (nextUint32() & 1) == 1;

  /// Zwraca wartość zmiennoprzecinkową w zakresie `[min, max)`.
  double nextRange(double min, double max) {
    if (max <= min) return min;
    return min + nextDouble() * (max - min);
  }

  /// Zwraca wartość w zakresie `[-1.0, 1.0)`.
  double nextSignedDouble() => (nextDouble() * 2.0) - 1.0;

  /// Rozkład normalny (transformacja Boxa-Mullera).
  double nextGaussian({double mean = 0.0, double stdDev = 1.0}) {
    final u1 = math.max(1e-12, nextDouble());
    final u2 = nextDouble();
    final z0 = math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
    return mean + z0 * stdDev;
  }

  /// Deterministyczne tasowanie listy w miejscu (Fisher-Yates).
  void shuffle<T>(List<T> items) {
    for (int i = items.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = items[i];
      items[i] = items[j];
      items[j] = tmp;
    }
  }

  /// Wybiera losowy element z niepustej listy.
  T pickOne<T>(List<T> items) {
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'Cannot pick from an empty list');
    }
    return items[nextInt(items.length)];
  }

  /// Resetuje strumień do stanu początkowego.
  void reset() {
    _state = initialSeed;
    _callCount = 0;
  }

  /// Tworzy migawkę stanu strumienia.
  PrngStreamSnapshot saveState() {
    return PrngStreamSnapshot(
      domain: domain,
      initialSeed: initialSeed,
      state: _state,
      callCount: _callCount,
    );
  }

  /// Przywraca stan strumienia z migawki.
  void restoreState(PrngStreamSnapshot snapshot) {
    if (snapshot.domain != domain) {
      throw ArgumentError(
        'Snapshot domain ${snapshot.domain.name} does not match stream domain ${domain.name}',
      );
    }
    _state = snapshot.state & 0xFFFFFFFF;
    _callCount = snapshot.callCount;
  }

  /// Tworzy strumień z zapisanej migawki.
  factory DeterministicPrngStream.fromSnapshot(PrngStreamSnapshot snapshot) {
    return DeterministicPrngStream._restored(
      domain: snapshot.domain,
      initialSeed: snapshot.initialSeed,
      state: snapshot.state,
      callCount: snapshot.callCount,
    );
  }
}

/// Próbka podmuchu wiatru obliczona deterministycznie dla konkretnej milisekundy etapu.
class WindGustSample {
  /// Czas od startu etapu w milisekundach [ms].
  final int timestampMs;

  /// Prędkość wiatru z uwzględnieniem podmuchu [km/h].
  final double gustSpeedKmh;

  /// Odchylenie od bazowej prędkości wiatru [km/h].
  final double gustDeltaKmh;

  /// Kierunek wiatru z uwzględnieniem chwilowego zawirowania [0..360 stopni].
  final double windDirectionDegrees;

  /// Intensywność turbulencji (0.0 = cisza, 1.0 = gwałtowny szkwał).
  final double turbulenceIntensity;

  const WindGustSample({
    required this.timestampMs,
    required this.gustSpeedKmh,
    required this.gustDeltaKmh,
    required this.windDirectionDegrees,
    required this.turbulenceIntensity,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WindGustSample &&
        other.timestampMs == timestampMs &&
        other.gustSpeedKmh == gustSpeedKmh &&
        other.gustDeltaKmh == gustDeltaKmh &&
        other.windDirectionDegrees == windDirectionDegrees &&
        other.turbulenceIntensity == turbulenceIntensity;
  }

  @override
  int get hashCode => Object.hash(
        timestampMs,
        gustSpeedKmh,
        gustDeltaKmh,
        windDirectionDegrees,
        turbulenceIntensity,
      );
}

/// Deterministyczny rzut zachowania AI dla konkretnego kolarza i milisekundy.
class AiBehaviorRoll {
  final int timestampMs;
  final String riderId;

  /// Znormalizowany rzut agresji ataku [0.0, 1.0).
  final double aggressionRoll;

  /// Znormalizowany rzut blefowania / poker face [0.0, 1.0).
  final double bluffRoll;

  /// Deterministyczne opóźnienie reakcji AI w milisekundach [120, 1400].
  final int reactionDelayMs;

  /// Ziarno pomocnicze dla złożonych decyzji taktycznych.
  final int decisionSeed;

  const AiBehaviorRoll({
    required this.timestampMs,
    required this.riderId,
    required this.aggressionRoll,
    required this.bluffRoll,
    required this.reactionDelayMs,
    required this.decisionSeed,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiBehaviorRoll &&
        other.timestampMs == timestampMs &&
        other.riderId == riderId &&
        other.aggressionRoll == aggressionRoll &&
        other.bluffRoll == bluffRoll &&
        other.reactionDelayMs == reactionDelayMs &&
        other.decisionSeed == decisionSeed;
  }

  @override
  int get hashCode => Object.hash(
        timestampMs,
        riderId,
        aggressionRoll,
        bluffRoll,
        reactionDelayMs,
        decisionSeed,
      );
}

/// Zapis pojedynczego rozkazu taktycznego gracza do deterministycznej powtórki.
class TacticalCommandReplayRecord {
  final int timestampMs;
  final String riderId;
  final String orderName;
  final double? parameterValue;

  const TacticalCommandReplayRecord({
    required this.timestampMs,
    required this.riderId,
    required this.orderName,
    this.parameterValue,
  });

  Map<String, dynamic> toJson() => {
        'tMs': timestampMs,
        'riderId': riderId,
        'order': orderName,
        if (parameterValue != null) 'param': parameterValue,
      };

  factory TacticalCommandReplayRecord.fromJson(Map<String, dynamic> json) {
    return TacticalCommandReplayRecord(
      timestampMs: (json['tMs'] as num).toInt(),
      riderId: json['riderId'] as String,
      orderName: json['order'] as String,
      parameterValue: (json['param'] as num?)?.toDouble(),
    );
  }
}

/// Pełny manifest deterministyczny etapu umożliwiający identyczne odtworzenie
/// w `StageReplayRecorder` lub ponowne uruchomienie etapu z tymi samymi rozkazami.
class StageDeterminismManifest {
  final int stageSeed;
  final String stageId;
  final List<TacticalCommandReplayRecord> commandLog;
  final Map<String, PrngStreamSnapshot> initialStreamSnapshots;

  const StageDeterminismManifest({
    required this.stageSeed,
    required this.stageId,
    this.commandLog = const [],
    this.initialStreamSnapshots = const {},
  });

  /// Suma kontrolna FNV-1a manifestu do szybkiej weryfikacji spójności powtórki.
  int computeChecksum() {
    var hash = 0x811C9DC5;
    hash = _fnvMixInt(hash, stageSeed);
    hash = _fnvMixString(hash, stageId);
    for (final cmd in commandLog) {
      hash = _fnvMixInt(hash, cmd.timestampMs);
      hash = _fnvMixString(hash, cmd.riderId);
      hash = _fnvMixString(hash, cmd.orderName);
      if (cmd.parameterValue != null) {
        hash = _fnvMixInt(hash, (cmd.parameterValue! * 1000).round());
      }
    }
    return hash & 0xFFFFFFFF;
  }

  Map<String, dynamic> toJson() => {
        'stageSeed': stageSeed,
        'stageId': stageId,
        'checksum': computeChecksum(),
        'commandLog': commandLog.map((c) => c.toJson()).toList(),
        'streams': initialStreamSnapshots.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory StageDeterminismManifest.fromJson(Map<String, dynamic> json) {
    final rawCommands = json['commandLog'] as List<dynamic>? ?? const [];
    final rawStreams = json['streams'] as Map<String, dynamic>? ?? const {};
    return StageDeterminismManifest(
      stageSeed: (json['stageSeed'] as num).toInt(),
      stageId: json['stageId'] as String? ?? 'stage_unknown',
      commandLog: rawCommands
          .whereType<Map<String, dynamic>>()
          .map(TacticalCommandReplayRecord.fromJson)
          .toList(),
      initialStreamSnapshots: rawStreams.map(
        (k, v) => MapEntry(k, PrngStreamSnapshot.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }
}

/// Centralny menedżer deterministycznych generatorów liczb losowych dla etapu (`stageSeed`).
///
/// Zapewnia:
/// 1. Izolowane strumienie PRNG dla każdej domeny symulacji ([RngDomain]).
/// 2. Bezpośrednią kompatybilność z [math.Random] w `StageSimulationLoop`.
/// 3. Deterministyczne próbkowanie podmuchów wiatru i decyzji AI indeksowane
///    co do milisekundy (`elapsedMs`), co pozwala `StageReplayRecorder` na
///    swobodne przewijanie powtórki z zachowaniem identycznych warunków wiatrowych
///    i zachowań kolarzy AI.
/// 4. Zapis/odczyt stanu wszystkich strumieni oraz rejestrację rozkazów taktycznych.
class DeterministicRngSeedManager {
  /// Główne 32-bitowe ziarno etapu.
  final int stageSeed;

  /// Identyfikator etapu powiązany z ziarnem (opcjonalny metadata).
  final String stageId;

  final Map<RngDomain, DeterministicPrngStream> _domainStreams = {};
  final List<TacticalCommandReplayRecord> _commandLog = [];

  DeterministicRngSeedManager({
    required int stageSeed,
    this.stageId = 'stage_default',
  }) : stageSeed = _sanitizeSeed(stageSeed) {
    for (final domain in RngDomain.values) {
      _domainStreams[domain] = DeterministicPrngStream(
        domain: domain,
        seed: _deriveDomainSeed(this.stageSeed, domain),
      );
    }
  }

  /// Tworzy menedżera wyliczając deterministyczne ziarno etapu z ziarna kariery,
  /// identyfikatora wyścigu oraz numeru etapu.
  factory DeterministicRngSeedManager.forStage({
    required int careerSeed,
    required String stageId,
    int stageNumber = 1,
  }) {
    final computedSeed = computeStageSeed(
      careerSeed: careerSeed,
      stageId: stageId,
      stageNumber: stageNumber,
    );
    return DeterministicRngSeedManager(
      stageSeed: computedSeed,
      stageId: stageId,
    );
  }

  /// Odtwarza menedżera wraz ze wszystkimi strumieniami i logiem rozkazów z manifestu JSON.
  factory DeterministicRngSeedManager.fromManifest(StageDeterminismManifest manifest) {
    final manager = DeterministicRngSeedManager(
      stageSeed: manifest.stageSeed,
      stageId: manifest.stageId,
    );
    for (final entry in manifest.initialStreamSnapshots.entries) {
      final matchingDomain = RngDomain.values.where((d) => d.name == entry.key);
      if (matchingDomain.isNotEmpty) {
        manager._domainStreams[matchingDomain.first]?.restoreState(entry.value);
      }
    }
    manager._commandLog.addAll(manifest.commandLog);
    return manager;
  }

  /// Zwraca deterministyczne 32-bitowe ziarno etapu dla zadanych parametrów.
  static int computeStageSeed({
    required int careerSeed,
    required String stageId,
    int stageNumber = 1,
  }) {
    var hash = 0x811C9DC5;
    hash = _fnvMixInt(hash, careerSeed);
    hash = _fnvMixInt(hash, stageNumber);
    hash = _fnvMixString(hash, stageId);
    return _sanitizeSeed(_avalanche32(hash));
  }

  static int _sanitizeSeed(int seed) {
    final masked = seed & 0xFFFFFFFF;
    return masked == 0 ? 0x9E3779B9 : masked;
  }

  static int _deriveDomainSeed(int baseSeed, RngDomain domain) {
    var hash = 0x811C9DC5;
    hash = _fnvMixInt(hash, baseSeed);
    hash = _fnvMixInt(hash, domain.index + 1);
    hash = _fnvMixString(hash, domain.name);
    return _sanitizeSeed(_avalanche32(hash));
  }

  /// Zwraca izolowany strumień PRNG dla danej domeny symulacji.
  DeterministicPrngStream streamFor(RngDomain domain) {
    return _domainStreams[domain]!;
  }

  /// Domyślny strumień dla ogólnej pętli `StageSimulationLoop`.
  DeterministicPrngStream get simulationStream => streamFor(RngDomain.aiBehavior);

  /// Strumień dedykowany incydentom losowym (kraksy/defekty).
  DeterministicPrngStream get incidentStream => streamFor(RngDomain.incidents);

  /// Strumień dedykowany podmuchom wiatru.
  DeterministicPrngStream get windStream => streamFor(RngDomain.windGusts);

  /// Zapisuje rozkaz taktyczny gracza z dokładnością do milisekundy.
  void recordTacticalCommand({
    required int timestampMs,
    required String riderId,
    required String orderName,
    double? parameterValue,
  }) {
    _commandLog.add(TacticalCommandReplayRecord(
      timestampMs: timestampMs < 0 ? 0 : timestampMs,
      riderId: riderId,
      orderName: orderName,
      parameterValue: parameterValue,
    ));
  }

  /// Niezmienna lista zarejestrowanych rozkazów taktycznych.
  List<TacticalCommandReplayRecord> get commandLog => List.unmodifiable(_commandLog);

  /// Zwraca rozkazy przypadające w zadanym oknie czasowym `[startMs, endMs]`.
  List<TacticalCommandReplayRecord> commandsInWindow(int startMs, int endMs) {
    return _commandLog
        .where((cmd) => cmd.timestampMs >= startMs && cmd.timestampMs <= endMs)
        .toList(growable: false);
  }

  /// Generuje jednorazowy, bezstanowy strumień PRNG przypięty do konkretnej
  /// milisekundy `elapsedMs` (oraz opcjonalnie encji np. `riderId`).
  ///
  /// Gwarantuje identyczne wyniki podczas powtórek `StageReplayRecorder` przy
  /// dowolnym skoku na osi czasu.
  DeterministicPrngStream deriveMillisecondStream({
    required RngDomain domain,
    required int elapsedMs,
    String? entityId,
  }) {
    var hash = 0x811C9DC5;
    hash = _fnvMixInt(hash, stageSeed);
    hash = _fnvMixInt(hash, domain.index + 17);
    hash = _fnvMixInt(hash, elapsedMs < 0 ? 0 : elapsedMs);
    if (entityId != null && entityId.isNotEmpty) {
      hash = _fnvMixString(hash, entityId);
    }
    return DeterministicPrngStream(
      domain: domain,
      seed: _avalanche32(hash),
    );
  }

  /// Oblicza deterministyczny podmuch wiatru co do milisekundy (`elapsedMs`).
  ///
  /// Łączy wielooktawową falę czasową (płynne narastanie i opadanie szkwałów)
  /// z deterministycznym szumem ziarna `stageSeed`, dzięki czemu ten sam etap
  /// i powtórka w `StageReplayRecorder` odtwarzają identyczne podmuchy wiatru.
  WindGustSample sampleWindGustAtMs({
    required int elapsedMs,
    required double baseWindSpeedKmh,
    required double baseWindDirectionDegrees,
    double exposureFactor = 1.0,
  }) {
    final safeMs = elapsedMs < 0 ? 0 : elapsedMs;
    final clampedExposure = exposureFactor.clamp(0.0, 1.5);
    final baseSpeed = baseWindSpeedKmh < 0 ? 0.0 : baseWindSpeedKmh;

    // Płynna modulacja wielooktawowa (węzły co 4000 ms i 1250 ms) dla realistycznych podmuchów
    final macroBucket = safeMs ~/ 4000;
    final macroT = (safeMs % 4000) / 4000.0;
    final macroSmooth = _smoothstep(macroT);

    final m0 = _unitDoubleForKey(RngDomain.windGusts, macroBucket, salt: 11);
    final m1 = _unitDoubleForKey(RngDomain.windGusts, macroBucket + 1, salt: 11);
    final macroWave = m0 + (m1 - m0) * macroSmooth;

    final microBucket = safeMs ~/ 500;
    final microT = (safeMs % 500) / 500.0;
    final microSmooth = _smoothstep(microT);

    final f0 = _unitDoubleForKey(RngDomain.windGusts, microBucket, salt: 37);
    final f1 = _unitDoubleForKey(RngDomain.windGusts, microBucket + 1, salt: 37);
    final microWave = f0 + (f1 - f0) * microSmooth;

    // Drobny szum milisekundowy (1 ms)
    final msJitter = _unitDoubleForKey(RngDomain.windGusts, safeMs, salt: 73) - 0.5;

    final combinedWave = (macroWave * 0.65) + (microWave * 0.30) + ((msJitter + 0.5) * 0.05);
    final turbulence = (combinedWave * clampedExposure).clamp(0.0, 1.0);

    // Podmuch może wzmocnić wiatr do +45% lub chwilowo osłabić o -20%
    final gustDelta = baseSpeed * (((combinedWave - 0.35) * 0.65) * clampedExposure);
    final gustSpeed = math.max(0.0, baseSpeed + gustDelta);

    // Chwilowe odchylenie kierunku wiatru (+/- 18 stopni)
    final dir0 = _unitDoubleForKey(RngDomain.windGusts, macroBucket, salt: 101) - 0.5;
    final dir1 = _unitDoubleForKey(RngDomain.windGusts, macroBucket + 1, salt: 101) - 0.5;
    final dirWave = dir0 + (dir1 - dir0) * macroSmooth;
    final directionDeg = (baseWindDirectionDegrees + (dirWave * 36.0 * clampedExposure)) % 360.0;
    final normalizedDir = directionDeg < 0 ? directionDeg + 360.0 : directionDeg;

    return WindGustSample(
      timestampMs: safeMs,
      gustSpeedKmh: gustSpeed,
      gustDeltaKmh: gustDelta,
      windDirectionDegrees: normalizedDir,
      turbulenceIntensity: turbulence,
    );
  }

  /// Generuje deterministyczny rzut zachowania AI dla konkretnego kolarza i milisekundy.
  AiBehaviorRoll sampleAiBehaviorAtMs({
    required int elapsedMs,
    required String riderId,
  }) {
    final safeMs = elapsedMs < 0 ? 0 : elapsedMs;
    final stream = deriveMillisecondStream(
      domain: RngDomain.aiBehavior,
      elapsedMs: safeMs,
      entityId: riderId,
    );
    final aggression = stream.nextDouble();
    final bluff = stream.nextDouble();
    final reactionDelay = 120 + stream.nextInt(1281); // 120..1400 ms
    final decisionSeed = stream.nextUint32();

    return AiBehaviorRoll(
      timestampMs: safeMs,
      riderId: riderId,
      aggressionRoll: aggression,
      bluffRoll: bluff,
      reactionDelayMs: reactionDelay,
      decisionSeed: decisionSeed,
    );
  }

  /// Resetuje wszystkie strumienie domenowe do początkowego stanu `stageSeed`.
  /// Nie usuwa logu rozkazów, chyba że `clearCommandLog: true`.
  void resetAllStreams({bool clearCommandLog = false}) {
    for (final stream in _domainStreams.values) {
      stream.reset();
    }
    if (clearCommandLog) {
      _commandLog.clear();
    }
  }

  /// Tworzy pełny manifest deterministyczny etapu do zapisania wraz z powtórką `StageReplayRecorder`.
  StageDeterminismManifest exportManifest() {
    final snapshots = <String, PrngStreamSnapshot>{};
    for (final entry in _domainStreams.entries) {
      snapshots[entry.key.name] = entry.value.saveState();
    }
    return StageDeterminismManifest(
      stageSeed: stageSeed,
      stageId: stageId,
      commandLog: List<TacticalCommandReplayRecord>.unmodifiable(_commandLog),
      initialStreamSnapshots: Map<String, PrngStreamSnapshot>.unmodifiable(snapshots),
    );
  }

  /// Serializuje stan menedżera do JSON.
  String toJsonString() => jsonEncode(exportManifest().toJson());

  /// Odtwarza menedżera z JSON.
  factory DeterministicRngSeedManager.fromJsonString(String jsonStr) {
    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
    return DeterministicRngSeedManager.fromManifest(
      StageDeterminismManifest.fromJson(decoded),
    );
  }

  double _unitDoubleForKey(RngDomain domain, int bucket, {required int salt}) {
    var hash = 0x811C9DC5;
    hash = _fnvMixInt(hash, stageSeed);
    hash = _fnvMixInt(hash, domain.index + 1);
    hash = _fnvMixInt(hash, salt);
    hash = _fnvMixInt(hash, bucket);
    final mixed = _avalanche32(hash);
    return (mixed & 0xFFFFFF) / 16777216.0;
  }

  static double _smoothstep(double t) {
    final c = t.clamp(0.0, 1.0);
    return c * c * (3.0 - 2.0 * c);
  }
}

int _fnvMixInt(int hash, int value) {
  var h = hash;
  for (int i = 0; i < 4; i++) {
    final byte = (value >>> (i * 8)) & 0xFF;
    h ^= byte;
    h = DeterministicPrngStream._imul32(h, 0x01000193);
  }
  return h & 0xFFFFFFFF;
}

int _fnvMixString(int hash, String text) {
  var h = hash;
  final units = text.codeUnits;
  for (int i = 0; i < units.length; i++) {
    h ^= units[i] & 0xFF;
    h = DeterministicPrngStream._imul32(h, 0x01000193);
  }
  return h & 0xFFFFFFFF;
}

int _avalanche32(int x) {
  var h = x & 0xFFFFFFFF;
  h ^= h >>> 16;
  h = DeterministicPrngStream._imul32(h, 0x85EBCA6B);
  h ^= h >>> 13;
  h = DeterministicPrngStream._imul32(h, 0xC2B2AE35);
  h ^= h >>> 16;
  return h & 0xFFFFFFFF;
}
