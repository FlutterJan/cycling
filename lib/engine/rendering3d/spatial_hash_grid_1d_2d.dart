import 'dart:math' as math;
import 'dart:typed_data';

/// Statystyki diagnostyczne rozkładu elementów w strukturze [SpatialHashGrid1d2d].
class SpatialHashGridStats {
  /// Liczba aktywnych elementów wstawionych w bieżącej klatce.
  final int itemCount;

  /// Liczba niepustych koszyków w bieżącej klatce.
  final int occupiedBuckets;

  /// Maksymalna liczba elementów w pojedynczym koszyku.
  final int maxBucketDepth;

  /// Średnia liczba elementów na zajęty koszyk.
  final double averageBucketDepth;

  /// Długość koszyka wzdłuż trasy [m].
  final double longitudinalBucketMeters;

  /// Czy siatka działa w trybie 2D (wzdłużnym + poprzecznym).
  final bool is2dMode;

  const SpatialHashGridStats({
    required this.itemCount,
    required this.occupiedBuckets,
    required this.maxBucketDepth,
    required this.averageBucketDepth,
    required this.longitudinalBucketMeters,
    required this.is2dMode,
  });
}

/// Wysokowydajna struktura przestrzenna Zero-GC (O(N)) dzieląca trasę na koszyki co 5 m
/// (opcjonalnie 2D z podziałem poprzecznym szosy) dla obliczeń draftingu i unikania kolizji.
///
/// Zamiast porównań każdy-z-każdym O(N²) lub sortowania O(N log N) w każdej klatce,
/// indeksy kolarzy są wstawiane do tablicy haszującej z listą wiązaną w płaskich
/// tablicach typowanych (`Int32List`) i stemplowaniem klatkowym O(1) przy czyszczeniu.
class SpatialHashGrid1d2d {
  /// Długość pojedynczego koszyka wzdłuż osi trasy [m] (domyślnie 5.0 m).
  final double longitudinalBucketMeters;

  /// Opcjonalna szerokość koszyka poprzecznego [m]. Gdy `null`, siatka działa w trybie 1D.
  final double? lateralBucketMeters;

  /// Rozmiar tablicy haszującej (zawsze potęga dwójki).
  final int hashTableSize;

  final int _tableMask;
  final double _invLongBucket;
  final double _invLatBucket;
  final bool _is2d;

  final Int32List _head;
  final Int32List _headStamp;
  int _currentStamp = 1;

  Int32List _next = Int32List(0);
  Int32List _cellX = Int32List(0);
  Int32List _cellY = Int32List(0);
  Int32List _queryBuffer = Int32List(64);
  int _itemCount = 0;

  static const int _primeX = 73856093;
  static const int _primeY = 19349663;
  static const int _maxStampBeforeReset = 0x3FFFFFFF;

  SpatialHashGrid1d2d({
    this.longitudinalBucketMeters = 5.0,
    this.lateralBucketMeters,
    int hashTableSize = 1024,
  })  : assert(longitudinalBucketMeters > 0.0, 'longitudinalBucketMeters must be > 0'),
        assert(
          lateralBucketMeters == null || lateralBucketMeters > 0.0,
          'lateralBucketMeters must be > 0 when provided',
        ),
        hashTableSize = _nextPowerOfTwo(math.max(64, hashTableSize)),
        _tableMask = _nextPowerOfTwo(math.max(64, hashTableSize)) - 1,
        _invLongBucket = 1.0 / longitudinalBucketMeters,
        _invLatBucket =
            lateralBucketMeters != null ? 1.0 / lateralBucketMeters : 0.0,
        _is2d = lateralBucketMeters != null,
        _head = Int32List(_nextPowerOfTwo(math.max(64, hashTableSize))),
        _headStamp = Int32List(_nextPowerOfTwo(math.max(64, hashTableSize)));

  static int _nextPowerOfTwo(int v) {
    var p = 1;
    while (p < v) {
      p <<= 1;
    }
    return p;
  }

  /// Czy siatka wykorzystuje również oś poprzeczną (tryb 2D).
  bool get is2dMode => _is2d;

  /// Liczba elementów wstawionych w bieżącej klatce.
  int get itemCount => _itemCount;

  /// Tablica wskaźników `next` listy wiązanej w koszyku do bezpośredniego odczytu w pętli gorącej.
  Int32List get nextArray => _next;

  /// Tablica współrzędnych koszyka X (wzdłużnych) każdego wstawionego elementu.
  Int32List get cellXArray => _cellX;

  /// Tablica współrzędnych koszyka Y (poprzecznych) każdego wstawionego elementu.
  Int32List get cellYArray => _cellY;

  /// Wyznacza indeks koszyka wzdłużnego dla zadanej odległości [m].
  int cellXFor(double distanceMeters) => (distanceMeters * _invLongBucket).floor();

  /// Wyznacza indeks koszyka poprzecznego dla zadanego przesunięcia bocznego [m].
  int cellYFor(double lateralOffsetMeters) =>
      _is2d ? (lateralOffsetMeters * _invLatBucket).floor() : 0;

  int _hash(int cx, int cy) {
    if (_is2d) {
      return ((cx * _primeX) ^ (cy * _primeY)) & _tableMask;
    }
    return (cx * _primeX) & _tableMask;
  }

  void _ensureCapacity(int requiredItems) {
    if (_next.length >= requiredItems) return;
    final newCap = math.max(requiredItems, _next.length * 2 + 32);
    _next = Int32List(newCap);
    _cellX = Int32List(newCap);
    _cellY = Int32List(newCap);
  }

  void _ensureQueryCapacity(int requiredItems) {
    if (_queryBuffer.length >= requiredItems) return;
    _queryBuffer = Int32List(math.max(requiredItems, _queryBuffer.length * 2));
  }

  /// Rozpoczyna nową klatkę w czasie O(1), czyszcząc poprzednie koszyki bez alokacji.
  void beginFrame(int expectedItemCount) {
    _ensureCapacity(expectedItemCount);
    _itemCount = 0;
    if (_currentStamp >= _maxStampBeforeReset) {
      _headStamp.fillRange(0, hashTableSize, 0);
      _currentStamp = 1;
    } else {
      _currentStamp++;
    }
  }

  /// Wstawia element o indeksie [itemIndex] (z zakresu `0 <= itemIndex < expectedItemCount`).
  void insert(
    int itemIndex,
    double distanceMeters, [
    double lateralOffsetMeters = 0.0,
  ]) {
    final cx = (distanceMeters * _invLongBucket).floor();
    final cy = _is2d ? (lateralOffsetMeters * _invLatBucket).floor() : 0;
    final slot = _hash(cx, cy);

    if (_headStamp[slot] != _currentStamp) {
      _headStamp[slot] = _currentStamp;
      _head[slot] = -1;
    }

    _cellX[itemIndex] = cx;
    _cellY[itemIndex] = cy;
    _next[itemIndex] = _head[slot];
    _head[slot] = itemIndex;
    _itemCount++;
  }

  /// Przebudowuje całą siatkę z płaskich tablic współrzędnych w czasie ściśle O(N).
  void rebuildFromArrays(
    int count,
    Float64List distances, {
    Float64List? laterals,
    Uint8List? activeFlags,
  }) {
    beginFrame(count);
    final use2d = _is2d && laterals != null;
    for (var i = 0; i < count; i++) {
      if (activeFlags != null && activeFlags[i] == 0) continue;
      final cx = (distances[i] * _invLongBucket).floor();
      final cy = use2d ? (laterals[i] * _invLatBucket).floor() : 0;
      final slot = _hash(cx, cy);

      if (_headStamp[slot] != _currentStamp) {
        _headStamp[slot] = _currentStamp;
        _head[slot] = -1;
      }

      _cellX[i] = cx;
      _cellY[i] = cy;
      _next[i] = _head[slot];
      _head[slot] = i;
      _itemCount++;
    }
  }

  /// Zwraca surowy indeks pierwszego elementu w slocie koszyka `(cx, cy)` lub `-1`.
  ///
  /// Przy przechodzeniu po liście wiązanej przez [nextArray] należy weryfikować
  /// `cellXArray[j] == cx` (oraz `cellYArray[j] == cy` w trybie 2D) ze względu na haszowanie.
  int bucketHeadRaw(int cx, [int cy = 0]) {
    final slot = _hash(cx, cy);
    if (_headStamp[slot] != _currentStamp) return -1;
    return _head[slot];
  }

  /// Wyszukuje wszystkie elementy w zakresie wzdłużnym `[minDistanceMeters, maxDistanceMeters]`
  /// i zapisuje ich indeksy do bufora [outBuffer], zwracając liczbę znalezionych sąsiadów.
  int queryLongitudinalInto(
    double minDistanceMeters,
    double maxDistanceMeters,
    Int32List outBuffer, {
    int excludeIndex = -1,
  }) {
    final minCx = (minDistanceMeters * _invLongBucket).floor();
    final maxCx = (maxDistanceMeters * _invLongBucket).floor();
    final limit = outBuffer.length;
    var count = 0;

    for (var cx = minCx; cx <= maxCx; cx++) {
      final slot = (cx * _primeX) & _tableMask;
      if (_headStamp[slot] != _currentStamp) continue;

      var idx = _head[slot];
      while (idx != -1) {
        if (idx != excludeIndex && _cellX[idx] == cx) {
          if (count < limit) {
            outBuffer[count++] = idx;
          } else {
            return count;
          }
        }
        idx = _next[idx];
      }
    }
    return count;
  }

  /// Wyszukuje elementy w oknie 2D `[minDistanceMeters, maxDistanceMeters] x [minLateralMeters, maxLateralMeters]`.
  int query2dInto(
    double minDistanceMeters,
    double maxDistanceMeters,
    double minLateralMeters,
    double maxLateralMeters,
    Int32List outBuffer, {
    int excludeIndex = -1,
  }) {
    if (!_is2d) {
      return queryLongitudinalInto(
        minDistanceMeters,
        maxDistanceMeters,
        outBuffer,
        excludeIndex: excludeIndex,
      );
    }

    final minCx = (minDistanceMeters * _invLongBucket).floor();
    final maxCx = (maxDistanceMeters * _invLongBucket).floor();
    final minCy = (minLateralMeters * _invLatBucket).floor();
    final maxCy = (maxLateralMeters * _invLatBucket).floor();
    final limit = outBuffer.length;
    var count = 0;

    for (var cx = minCx; cx <= maxCx; cx++) {
      for (var cy = minCy; cy <= maxCy; cy++) {
        final slot = ((cx * _primeX) ^ (cy * _primeY)) & _tableMask;
        if (_headStamp[slot] != _currentStamp) continue;

        var idx = _head[slot];
        while (idx != -1) {
          if (idx != excludeIndex &&
              _cellX[idx] == cx &&
              _cellY[idx] == cy) {
            if (count < limit) {
              outBuffer[count++] = idx;
            } else {
              return count;
            }
          }
          idx = _next[idx];
        }
      }
    }
    return count;
  }

  /// Wyszukuje elementy w zakresie wzdłużnym korzystając z wewnętrznego bufora Zero-GC.
  /// Zwraca listę widokową o długości równej liczbie znalezionych sąsiadów.
  Int32List queryLongitudinalView(
    double minDistanceMeters,
    double maxDistanceMeters, {
    int excludeIndex = -1,
  }) {
    _ensureQueryCapacity(math.max(64, _next.length));
    final count = queryLongitudinalInto(
      minDistanceMeters,
      maxDistanceMeters,
      _queryBuffer,
      excludeIndex: excludeIndex,
    );
    return Int32List.sublistView(_queryBuffer, 0, count);
  }

  /// Wywołuje [visitor] dla każdego indeksu w koszykach pokrywających `[minDistanceMeters, maxDistanceMeters]`.
  void forEachInLongitudinalRange(
    double minDistanceMeters,
    double maxDistanceMeters,
    void Function(int itemIndex) visitor, {
    int excludeIndex = -1,
  }) {
    final minCx = (minDistanceMeters * _invLongBucket).floor();
    final maxCx = (maxDistanceMeters * _invLongBucket).floor();

    for (var cx = minCx; cx <= maxCx; cx++) {
      final slot = (cx * _primeX) & _tableMask;
      if (_headStamp[slot] != _currentStamp) continue;

      var idx = _head[slot];
      while (idx != -1) {
        if (idx != excludeIndex && _cellX[idx] == cx) {
          visitor(idx);
        }
        idx = _next[idx];
      }
    }
  }

  /// Wywołuje [visitor] dla każdego indeksu w koszykach 2D pokrywających zadany prostokąt.
  void forEachIn2dRange(
    double minDistanceMeters,
    double maxDistanceMeters,
    double minLateralMeters,
    double maxLateralMeters,
    void Function(int itemIndex) visitor, {
    int excludeIndex = -1,
  }) {
    if (!_is2d) {
      forEachInLongitudinalRange(
        minDistanceMeters,
        maxDistanceMeters,
        visitor,
        excludeIndex: excludeIndex,
      );
      return;
    }

    final minCx = (minDistanceMeters * _invLongBucket).floor();
    final maxCx = (maxDistanceMeters * _invLongBucket).floor();
    final minCy = (minLateralMeters * _invLatBucket).floor();
    final maxCy = (maxLateralMeters * _invLatBucket).floor();

    for (var cx = minCx; cx <= maxCx; cx++) {
      for (var cy = minCy; cy <= maxCy; cy++) {
        final slot = ((cx * _primeX) ^ (cy * _primeY)) & _tableMask;
        if (_headStamp[slot] != _currentStamp) continue;

        var idx = _head[slot];
        while (idx != -1) {
          if (idx != excludeIndex &&
              _cellX[idx] == cx &&
              _cellY[idx] == cy) {
            visitor(idx);
          }
          idx = _next[idx];
        }
      }
    }
  }

  /// Oblicza statystyki zajętości koszyków dla bieżącej klatki (diagnostyka).
  SpatialHashGridStats computeStats() {
    var occupied = 0;
    var maxDepth = 0;
    var totalItems = 0;

    for (var slot = 0; slot < hashTableSize; slot++) {
      if (_headStamp[slot] != _currentStamp) continue;
      var depth = 0;
      var idx = _head[slot];
      while (idx != -1) {
        depth++;
        idx = _next[idx];
      }
      if (depth > 0) {
        occupied++;
        totalItems += depth;
        if (depth > maxDepth) {
          maxDepth = depth;
        }
      }
    }

    return SpatialHashGridStats(
      itemCount: totalItems,
      occupiedBuckets: occupied,
      maxBucketDepth: maxDepth,
      averageBucketDepth: occupied > 0 ? totalItems / occupied : 0.0,
      longitudinalBucketMeters: longitudinalBucketMeters,
      is2dMode: _is2d,
    );
  }
}
