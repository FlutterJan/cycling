import 'dart:math' as math;

import '../../models/race/stage_segment.dart';
import '../../state/race_simulation_notifier.dart';
import '../rendering3d/spatial_hash_grid_1d_2d.dart';
import 'rider_race_state.dart';

/// Kierunek wybranego korytarza podczas manewru wyprzedzania.
enum OvertakeLaneDirection {
  /// Kolarz jedzie w szyku i nie wykonuje aktywnego manewru wyprzedzania.
  none,

  /// Wyprzedzanie lewą stroną szosy (ujemne przesunięcie osi Y).
  left,

  /// Wyprzedzanie prawą stroną szosy (dodatnie przesunięcie osi Y).
  right,
}

/// Konfiguracja parametrów fizycznych i sterujących silnika Boids peletonu.
class BoidsSteeringConfig {
  /// Długość minimalnej bezpiecznej kopuły wokół roweru [m].
  final double riderLengthMeters;

  /// Szerokość minimalnej bezpiecznej kopuły wokół roweru [m].
  final double riderWidthMeters;

  /// Promień skanowania wolnego korytarza przy wyprzedzaniu [m].
  final double overtakeScanRadiusMeters;

  /// Standardowa szerokość szosy asfaltowej [m].
  final double standardRoadWidthMeters;

  /// Szerokość wąskiego sektora bruku / zwężenia trasy [m].
  final double narrowCobbleRoadWidthMeters;

  /// Maksymalna prędkość poprzeczna zmiany pasa na szosie [m/s].
  final double maxLateralSpeedMs;

  /// Maksymalny kąt wychylenia roweru przy zmianie toru jazdy [rad].
  final double maxLeanAngleRad;

  /// Próg wiatru bocznego [km/h], powyżej którego kolarze formują wachlarz.
  final double crosswindEchelonThresholdKmh;

  /// Waga wektora separacji (Collision Avoidance).
  final double separationWeight;

  /// Waga wektora szukania cienia aerodynamicznego (Draft Seeking).
  final double draftSeekingWeight;

  /// Waga wektora wyprzedzania (Overtaking Lane Finder).
  final double overtakeWeight;

  /// Waga siły utrzymującej kolarzy wewnątrz granic jezdni.
  final double roadBoundaryWeight;

  /// Czy wymuszać twardą projekcję bezkolizyjną po integracji ruchu.
  final bool enforceHardSeparation;

  const BoidsSteeringConfig({
    this.riderLengthMeters = 1.85,
    this.riderWidthMeters = 0.65,
    this.overtakeScanRadiusMeters = 15.0,
    this.standardRoadWidthMeters = 7.0,
    this.narrowCobbleRoadWidthMeters = 3.2,
    this.maxLateralSpeedMs = 2.6,
    this.maxLeanAngleRad = 0.28,
    this.crosswindEchelonThresholdKmh = 15.0,
    this.separationWeight = 4.2,
    this.draftSeekingWeight = 1.6,
    this.overtakeWeight = 2.8,
    this.roadBoundaryWeight = 6.0,
    this.enforceHardSeparation = true,
  });
}

/// Wektory sterujące wyliczone dla pojedynczego kolarza w bieżącej klatce symulacji.
class BoidSteeringVectors {
  final double separationForceX;
  final double separationForceY;
  final double draftSeekingForceX;
  final double draftSeekingForceY;
  final double overtakingForceX;
  final double overtakingForceY;
  final double boundaryForceY;
  final double totalSteeringX;
  final double totalSteeringY;
  final OvertakeLaneDirection chosenOvertakeLane;
  final double targetLateralOffsetMeters;
  final double leanAngleRad;
  final double accordionCompressionFactor;

  const BoidSteeringVectors({
    required this.separationForceX,
    required this.separationForceY,
    required this.draftSeekingForceX,
    required this.draftSeekingForceY,
    required this.overtakingForceX,
    required this.overtakingForceY,
    required this.boundaryForceY,
    required this.totalSteeringX,
    required this.totalSteeringY,
    required this.chosenOvertakeLane,
    required this.targetLateralOffsetMeters,
    required this.leanAngleRad,
    required this.accordionCompressionFactor,
  });

  static const zero = BoidSteeringVectors(
    separationForceX: 0.0,
    separationForceY: 0.0,
    draftSeekingForceX: 0.0,
    draftSeekingForceY: 0.0,
    overtakingForceX: 0.0,
    overtakingForceY: 0.0,
    boundaryForceY: 0.0,
    totalSteeringX: 0.0,
    totalSteeringY: 0.0,
    chosenOvertakeLane: OvertakeLaneDirection.none,
    targetLateralOffsetMeters: 0.0,
    leanAngleRad: 0.0,
    accordionCompressionFactor: 1.0,
  );
}

/// Ciągły stan przestrzenny i kinematyczny kolarza w silniku Boids (60 FPS).
class BoidRiderState {
  final String riderId;
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double lateralVelocityMs;
  final double longitudinalSpeedMs;
  final double targetSpeedMs;
  final double leanAngleRad;
  final OvertakeLaneDirection overtakeLane;
  final double overtakeCooldownSec;
  final String? draftingTargetRiderId;
  final TacticalOrder tacticalOrder;
  final bool isCrashed;
  final bool isDnf;

  const BoidRiderState({
    required this.riderId,
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    this.lateralVelocityMs = 0.0,
    required this.longitudinalSpeedMs,
    required this.targetSpeedMs,
    this.leanAngleRad = 0.0,
    this.overtakeLane = OvertakeLaneDirection.none,
    this.overtakeCooldownSec = 0.0,
    this.draftingTargetRiderId,
    this.tacticalOrder = TacticalOrder.holdPosition,
    this.isCrashed = false,
    this.isDnf = false,
  });

  /// Tworzy początkowy stan Boids na podstawie snapshotu symulacji wyścigu.
  factory BoidRiderState.fromSnapshot(RiderPositionSnapshot snapshot) {
    return BoidRiderState(
      riderId: snapshot.riderId,
      distanceMeters: snapshot.distanceCoveredMeters,
      lateralOffsetMeters: snapshot.lateralOffsetRoadMeters,
      lateralVelocityMs: 0.0,
      longitudinalSpeedMs: snapshot.speedMs,
      targetSpeedMs: snapshot.speedMs,
      leanAngleRad: 0.0,
      overtakeLane: OvertakeLaneDirection.none,
      overtakeCooldownSec: 0.0,
      draftingTargetRiderId: null,
      tacticalOrder: snapshot.activeTacticalOrder,
      isCrashed: snapshot.isCrashed,
      isDnf: snapshot.isDnf,
    );
  }

  /// Zwraca znormalizowaną pozycję poprzeczną w przedziale [-1.0, 1.0].
  double normalizedLateralPosition(double roadWidthMeters) {
    final halfRoad = math.max(0.5, roadWidthMeters * 0.5);
    return (lateralOffsetMeters / halfRoad).clamp(-1.0, 1.0);
  }

  BoidRiderState copyWith({
    String? riderId,
    double? distanceMeters,
    double? lateralOffsetMeters,
    double? lateralVelocityMs,
    double? longitudinalSpeedMs,
    double? targetSpeedMs,
    double? leanAngleRad,
    OvertakeLaneDirection? overtakeLane,
    double? overtakeCooldownSec,
    String? draftingTargetRiderId,
    bool clearDraftingTarget = false,
    TacticalOrder? tacticalOrder,
    bool? isCrashed,
    bool? isDnf,
  }) {
    return BoidRiderState(
      riderId: riderId ?? this.riderId,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      lateralOffsetMeters: lateralOffsetMeters ?? this.lateralOffsetMeters,
      lateralVelocityMs: lateralVelocityMs ?? this.lateralVelocityMs,
      longitudinalSpeedMs: longitudinalSpeedMs ?? this.longitudinalSpeedMs,
      targetSpeedMs: targetSpeedMs ?? this.targetSpeedMs,
      leanAngleRad: leanAngleRad ?? this.leanAngleRad,
      overtakeLane: overtakeLane ?? this.overtakeLane,
      overtakeCooldownSec: overtakeCooldownSec ?? this.overtakeCooldownSec,
      draftingTargetRiderId: clearDraftingTarget
          ? null
          : (draftingTargetRiderId ?? this.draftingTargetRiderId),
      tacticalOrder: tacticalOrder ?? this.tacticalOrder,
      isCrashed: isCrashed ?? this.isCrashed,
      isDnf: isDnf ?? this.isDnf,
    );
  }
}

/// Wynik pojedynczej klatki symulacji ruchu ciągłego peletonu.
class BoidsFrameResult {
  final List<BoidRiderState> riders;
  final Map<String, BoidSteeringVectors> steeringVectors;
  final double effectiveRoadWidthMeters;
  final double pelotonLengthMeters;
  final int collisionCountResolved;
  final int activeOvertakesCount;

  const BoidsFrameResult({
    required this.riders,
    required this.steeringVectors,
    required this.effectiveRoadWidthMeters,
    required this.pelotonLengthMeters,
    required this.collisionCountResolved,
    required this.activeOvertakesCount,
  });
}

/// Silnik fizyki ruchu ciągłego peletonu (Boids Steering + Collision Avoidance).
///
/// Zapewnia bezkolizyjne poruszanie się do 176+ kolarzy w 60 FPS dzięki:
/// 1. Separacji przestrzennej (kopuła 1.85 m x 0.65 m),
/// 2. Szukaniu cienia aerodynamicznego z formowaniem wachlarzy przy wietrze bocznym,
/// 3. Skanowaniu korytarza wyprzedzania w promieniu 15 m z animacją przechyłu,
/// 4. Obsłudze zwężeń szosy (np. bruk 3.2 m) wywołujących efekt akordeonu (*gruppo allungato*).
class BoidsSteeringCollisionAvoidance {
  final BoidsSteeringConfig config;

  // Siatka przestrzenna 5 m (O(N)) współdzielona w ramach bieżącego izolatu (Zero-GC).
  static final SpatialHashGrid1d2d _sharedGrid = SpatialHashGrid1d2d(
    longitudinalBucketMeters: 5.0,
  );

  const BoidsSteeringCollisionAvoidance({
    this.config = const BoidsSteeringConfig(),
  });

  /// Wyznacza aktualną szerokość przejezdną szosy na podstawie parametrów segmentu.
  double resolveRoadWidthMeters({
    StageSegment? segment,
    double? overrideRoadWidthMeters,
  }) {
    if (overrideRoadWidthMeters != null) {
      return overrideRoadWidthMeters.clamp(2.2, 12.0);
    }
    if (segment == null) {
      return config.standardRoadWidthMeters;
    }
    if (segment.isCobblestone) {
      return config.narrowCobbleRoadWidthMeters;
    }
    if (segment.surfaceType == SegmentSurfaceType.gravelStrade) {
      return 4.0;
    }
    if (segment.technicalDifficulty >= 75.0) {
      return 4.5;
    }
    return config.standardRoadWidthMeters;
  }

  /// Oblicza podpisany wektor wiatru bocznego [km/h] na podstawie kąta wiatru i azymutu drogi.
  /// Wartość dodatnia oznacza wiatr wiejący z lewej na prawą stronę szosy.
  double computeSignedCrosswindKmh({
    required StageSegment? segment,
    required double windSpeedKmh,
    double? overrideSignedCrosswindKmh,
  }) {
    if (overrideSignedCrosswindKmh != null) {
      return overrideSignedCrosswindKmh;
    }
    if (segment == null || windSpeedKmh <= 0.0) {
      return 0.0;
    }
    final angleDiffRad =
        (segment.windDirectionDegrees - segment.roadBearingDegrees) *
        (math.pi / 180.0);
    return windSpeedKmh * math.sin(angleDiffRad);
  }

  /// Wykonuje pojedynczą klatkę fizyki ruchu ciągłego (domyślnie 60 FPS, `dtSeconds = 1/60`).
  BoidsFrameResult stepFrame({
    required List<BoidRiderState> riders,
    double dtSeconds = 1.0 / 60.0,
    StageSegment? segment,
    double? roadWidthMeters,
    double windSpeedKmh = 0.0,
    double? signedCrosswindKmh,
  }) {
    if (riders.isEmpty) {
      return BoidsFrameResult(
        riders: const [],
        steeringVectors: const {},
        effectiveRoadWidthMeters: resolveRoadWidthMeters(
          segment: segment,
          overrideRoadWidthMeters: roadWidthMeters,
        ),
        pelotonLengthMeters: 0.0,
        collisionCountResolved: 0,
        activeOvertakesCount: 0,
      );
    }

    final dt = dtSeconds.clamp(1.0 / 240.0, 0.1);
    final effectiveRoadWidth = resolveRoadWidthMeters(
      segment: segment,
      overrideRoadWidthMeters: roadWidthMeters,
    );
    final halfPlayableWidth = math.max(
      0.35,
      (effectiveRoadWidth - config.riderWidthMeters) * 0.5,
    );
    final crosswindKmh = computeSignedCrosswindKmh(
      segment: segment,
      windSpeedKmh: windSpeedKmh,
      overrideSignedCrosswindKmh: signedCrosswindKmh,
    );

    // Współczynnik kompresji szerokości szosy napędzający efekt akordeonu (*gruppo allungato*).
    final roadNarrowingRatio =
        (effectiveRoadWidth / config.standardRoadWidthMeters).clamp(0.4, 1.0);
    final accordionFactor = roadNarrowingRatio < 0.75
        ? 1.0 + (0.75 - roadNarrowingRatio) * 1.4
        : 1.0;

    // Budowa siatki przestrzennej O(N) z koszykami co 5 m zamiast sortowania O(N log N).
    final grid = _sharedGrid;
    grid.beginFrame(riders.length);
    final activeIndices = <int>[];
    final nextStates = List<BoidRiderState>.from(riders);
    final vectorsMap = <String, BoidSteeringVectors>{};

    for (var i = 0; i < riders.length; i++) {
      final r = riders[i];
      if (!r.isCrashed && !r.isDnf) {
        activeIndices.add(i);
        grid.insert(i, r.distanceMeters, r.lateralOffsetMeters);
      } else {
        vectorsMap[r.riderId] = BoidSteeringVectors.zero;
      }
    }

    var activeOvertakesCount = 0;
    final scanWindow = config.overtakeScanRadiusMeters;
    final nearbyNeighbors = <BoidRiderState>[];
    final gridNext = grid.nextArray;
    final gridCellX = grid.cellXArray;

    // Główna pętla wyliczająca 3 wektory sterujące dla każdego aktywnego kolarza w czasie O(N).
    for (var pos = 0; pos < activeIndices.length; pos++) {
      final idx = activeIndices[pos];
      final rider = riders[idx];

      // Zbieramy sąsiadów z koszyków w oknie wzdłużnym [-scanWindow, +scanWindow] w O(1).
      nearbyNeighbors.clear();
      final minCx = grid.cellXFor(rider.distanceMeters - scanWindow);
      final maxCx = grid.cellXFor(rider.distanceMeters + scanWindow);
      for (var cx = minCx; cx <= maxCx; cx++) {
        var j = grid.bucketHeadRaw(cx);
        while (j != -1) {
          if (j != idx && gridCellX[j] == cx) {
            final neighbor = riders[j];
            if ((neighbor.distanceMeters - rider.distanceMeters).abs() <= scanWindow) {
              nearbyNeighbors.add(neighbor);
            }
          }
          j = gridNext[j];
        }
      }

      // 1. Wektor Separacji (Collision Avoidance: kopuła 1.85 m x 0.65 m).
      final separation = _computeSeparationVector(
        rider: rider,
        neighbors: nearbyNeighbors,
        accordionFactor: accordionFactor,
      );

      // 2. Wektor Szukania Cienia Aerodynamicznego (Draft Seeking + Echelon).
      final draftResult = _computeDraftSeekingVector(
        rider: rider,
        neighbors: nearbyNeighbors,
        crosswindKmh: crosswindKmh,
        halfPlayableWidth: halfPlayableWidth,
      );

      // 3. Wektor Wyprzedzania i Ataku (Overtaking Lane Finder w promieniu 15 m).
      final overtakeResult = _computeOvertakingVector(
        rider: rider,
        neighbors: nearbyNeighbors,
        halfPlayableWidth: halfPlayableWidth,
        dt: dt,
      );

      if (overtakeResult.lane != OvertakeLaneDirection.none) {
        activeOvertakesCount++;
      }

      // 4. Siła utrzymania wewnątrz krawędzi jezdni (ważne przy zwężeniu na 3.2 m).
      final boundaryForceY = _computeBoundaryForceY(
        lateralOffsetMeters: rider.lateralOffsetMeters,
        halfPlayableWidth: halfPlayableWidth,
      );

      // Sumowanie wektorów sterujących.
      final draftMultiplier =
          overtakeResult.lane != OvertakeLaneDirection.none ? 0.15 : 1.0;

      final totalForceX =
          separation.dx * config.separationWeight +
          draftResult.forceX * config.draftSeekingWeight * draftMultiplier +
          overtakeResult.forceX * config.overtakeWeight;

      final totalForceY =
          separation.dy * config.separationWeight +
          draftResult.forceY * config.draftSeekingWeight * draftMultiplier +
          overtakeResult.forceY * config.overtakeWeight +
          boundaryForceY * config.roadBoundaryWeight;

      // Integracja prędkości bocznej oraz pozycji poprzecznej.
      final dampedLatVel =
          (rider.lateralVelocityMs + totalForceY * dt) * math.exp(-5.5 * dt);
      final clampedLatVel = dampedLatVel.clamp(
        -config.maxLateralSpeedMs,
        config.maxLateralSpeedMs,
      );
      final nextLateralOffset = (rider.lateralOffsetMeters + clampedLatVel * dt)
          .clamp(-halfPlayableWidth, halfPlayableWidth);

      // Integracja prędkości wzdłużnej z efektem akordeonu i hamowaniem przed kolizją.
      final desiredSpeed = math.max(
        1.5,
        rider.targetSpeedMs + totalForceX * 0.45,
      );
      final speedLerpAlpha = (dt * 6.0).clamp(0.0, 1.0);
      final nextSpeedMs =
          rider.longitudinalSpeedMs +
          (desiredSpeed - rider.longitudinalSpeedMs) * speedLerpAlpha;
      final nextDistance = rider.distanceMeters + nextSpeedMs * dt;

      // Płynna animacja wychylenia roweru (lean angle) podczas zmiany pasa.
      final targetLean =
          (clampedLatVel / config.maxLateralSpeedMs) * config.maxLeanAngleRad;
      final leanAlpha = (dt * 10.0).clamp(0.0, 1.0);
      final nextLeanAngle =
          rider.leanAngleRad + (targetLean - rider.leanAngleRad) * leanAlpha;

      nextStates[idx] = rider.copyWith(
        distanceMeters: nextDistance,
        lateralOffsetMeters: nextLateralOffset,
        lateralVelocityMs: clampedLatVel,
        longitudinalSpeedMs: nextSpeedMs,
        leanAngleRad: nextLeanAngle,
        overtakeLane: overtakeResult.lane,
        overtakeCooldownSec: overtakeResult.cooldownSec,
        draftingTargetRiderId: draftResult.targetRiderId,
        clearDraftingTarget: draftResult.targetRiderId == null,
      );

      vectorsMap[rider.riderId] = BoidSteeringVectors(
        separationForceX: separation.dx,
        separationForceY: separation.dy,
        draftSeekingForceX: draftResult.forceX,
        draftSeekingForceY: draftResult.forceY,
        overtakingForceX: overtakeResult.forceX,
        overtakingForceY: overtakeResult.forceY,
        boundaryForceY: boundaryForceY,
        totalSteeringX: totalForceX,
        totalSteeringY: totalForceY,
        chosenOvertakeLane: overtakeResult.lane,
        targetLateralOffsetMeters: overtakeResult.targetLaneY,
        leanAngleRad: nextLeanAngle,
        accordionCompressionFactor: accordionFactor,
      );
    }

    // Twarda projekcja bezkolizyjna gwarantująca 0% przenikania kopuł 1.85 m x 0.65 m.
    var collisionCountResolved = 0;
    if (config.enforceHardSeparation) {
      collisionCountResolved = _resolveHardCollisions(
        states: nextStates,
        activeIndices: activeIndices,
        halfPlayableWidth: halfPlayableWidth,
      );
    }

    // Obliczenie aktualnego rozciągnięcia grupy (*gruppo allungato*).
    var minDistance = double.infinity;
    var maxDistance = double.negativeInfinity;
    for (final idx in activeIndices) {
      final d = nextStates[idx].distanceMeters;
      if (d < minDistance) minDistance = d;
      if (d > maxDistance) maxDistance = d;
    }
    final pelotonLength = activeIndices.length >= 2
        ? math.max(0.0, maxDistance - minDistance)
        : 0.0;

    return BoidsFrameResult(
      riders: nextStates,
      steeringVectors: vectorsMap,
      effectiveRoadWidthMeters: effectiveRoadWidth,
      pelotonLengthMeters: pelotonLength,
      collisionCountResolved: collisionCountResolved,
      activeOvertakesCount: activeOvertakesCount,
    );
  }

  _Vec2 _computeSeparationVector({
    required BoidRiderState rider,
    required List<BoidRiderState> neighbors,
    required double accordionFactor,
  }) {
    final safeLength = config.riderLengthMeters;
    final safeWidth = config.riderWidthMeters;
    var forceX = 0.0;
    var forceY = 0.0;

    for (final other in neighbors) {
      final dx = other.distanceMeters - rider.distanceMeters;
      final dy = other.lateralOffsetMeters - rider.lateralOffsetMeters;
      final absDx = dx.abs();
      final absDy = dy.abs();

      // Bezpośrednia strefa kopuły roweru (1.85 m x 0.65 m) z lekkim marginesem prewencyjnym.
      final triggerLength = safeLength * 1.15;
      final triggerWidth = safeWidth * 1.25;

      if (absDx < triggerLength && absDy < triggerWidth) {
        final overlapX = (triggerLength - absDx) / triggerLength;
        final overlapY = (triggerWidth - absDy) / triggerWidth;

        // Płynna siła odpychająca na boki szosy (Delta Y).
        double pushDirY;
        if (absDy > 0.001) {
          pushDirY = dy > 0 ? -1.0 : 1.0;
        } else {
          // Deterministyczny rozdział przy idealnym wyrównaniu w osi Y.
          pushDirY = rider.riderId.compareTo(other.riderId) <= 0 ? -1.0 : 1.0;
        }
        forceY += pushDirY * overlapY * (1.0 + overlapX);

        // Gdy poprzednik jest bezpośrednio przed nami, wyhamowujemy wzdłużnie (efekt akordeonu).
        if (dx > 0.0 && absDy < safeWidth * 0.95) {
          forceX -= overlapX * accordionFactor * 2.5;
        }
      }
    }

    return _Vec2(forceX, forceY);
  }

  _DraftResult _computeDraftSeekingVector({
    required BoidRiderState rider,
    required List<BoidRiderState> neighbors,
    required double crosswindKmh,
    required double halfPlayableWidth,
  }) {
    if (rider.tacticalOrder == TacticalOrder.attack) {
      return const _DraftResult(forceX: 0.0, forceY: 0.0, targetRiderId: null);
    }

    final isEchelonActive =
        crosswindKmh.abs() >= config.crosswindEchelonThresholdKmh;
    // Przesunięcie skośne na zawietrzną w przypadku wiatru bocznego (formowanie wachlarza).
    final echelonShiftY = isEchelonActive
        ? (crosswindKmh > 0 ? 0.45 : -0.45)
        : 0.0;

    BoidRiderState? bestLeader;
    var bestScore = double.infinity;
    var desiredY = rider.lateralOffsetMeters;

    for (final other in neighbors) {
      final dx = other.distanceMeters - rider.distanceMeters;
      // Szukamy kolarza jadącego przed nami w strefie cienia [1.85 m, 6.5 m].
      if (dx < config.riderLengthMeters || dx > 6.5) {
        continue;
      }
      // Jeśli poprzednik jest wyraźnie wolniejszy, lepiej go wyprzedzić niż za nim zwalniać.
      if (other.longitudinalSpeedMs < rider.targetSpeedMs - 0.8) {
        continue;
      }

      final idealY = (other.lateralOffsetMeters + echelonShiftY).clamp(
        -halfPlayableWidth,
        halfPlayableWidth,
      );
      final lateralCost = (idealY - rider.lateralOffsetMeters).abs();
      final score = dx * 0.6 + lateralCost * 1.4;
      if (score < bestScore) {
        bestScore = score;
        bestLeader = other;
        desiredY = idealY;
      }
    }

    if (bestLeader == null) {
      return const _DraftResult(forceX: 0.0, forceY: 0.0, targetRiderId: null);
    }

    final dy = desiredY - rider.lateralOffsetMeters;
    final dx = bestLeader.distanceMeters - rider.distanceMeters;
    // Optymalny dystans za kołem poprzednika to ~2.15 m.
    final spacingErrorX = dx - (config.riderLengthMeters + 0.30);

    return _DraftResult(
      forceX: spacingErrorX.clamp(-1.0, 1.0) * 0.35,
      forceY: (dy * 2.4).clamp(-2.5, 2.5),
      targetRiderId: bestLeader.riderId,
    );
  }

  _OvertakeResult _computeOvertakingVector({
    required BoidRiderState rider,
    required List<BoidRiderState> neighbors,
    required double halfPlayableWidth,
    required double dt,
  }) {
    final safeLength = config.riderLengthMeters;
    final safeWidth = config.riderWidthMeters;

    // Sprawdzamy, czy bezpośrednio przed kolarzem jedzie wolniejszy zawodnik blokujący tor.
    BoidRiderState? blockerAhead;
    var minBlockerDx = double.infinity;
    for (final other in neighbors) {
      final dx = other.distanceMeters - rider.distanceMeters;
      final absDy = (other.lateralOffsetMeters - rider.lateralOffsetMeters)
          .abs();
      if (dx > 0.0 && dx <= 7.5 && absDy < safeWidth * 1.2) {
        final isFaster =
            rider.targetSpeedMs > other.longitudinalSpeedMs + 0.30 ||
            rider.tacticalOrder == TacticalOrder.attack ||
            rider.tacticalOrder == TacticalOrder.pullGroup;
        if (isFaster && dx < minBlockerDx) {
          minBlockerDx = dx;
          blockerAhead = other;
        }
      }
    }

    var activeLane = rider.overtakeLane;
    var cooldown = math.max(0.0, rider.overtakeCooldownSec - dt);

    if (blockerAhead == null && cooldown <= 0.0) {
      // Brak przeszkody przed nami i koniec manewru -> powrót do szyku.
      return _OvertakeResult(
        lane: OvertakeLaneDirection.none,
        forceX: 0.0,
        forceY: 0.0,
        targetLaneY: rider.lateralOffsetMeters,
        cooldownSec: 0.0,
      );
    }

    // Skanowanie lewej i prawej strony drogi w promieniu 15 m.
    final laneOffset = safeWidth + 0.35;
    final leftCandidateY = (rider.lateralOffsetMeters - laneOffset).clamp(
      -halfPlayableWidth,
      halfPlayableWidth,
    );
    final rightCandidateY = (rider.lateralOffsetMeters + laneOffset).clamp(
      -halfPlayableWidth,
      halfPlayableWidth,
    );

    final canGoLeft =
        (rider.lateralOffsetMeters - leftCandidateY).abs() >= safeWidth * 0.65;
    final canGoRight =
        (rightCandidateY - rider.lateralOffsetMeters).abs() >= safeWidth * 0.65;

    double evaluateLaneOccupancy(double laneY) {
      var penalty = 0.0;
      for (final other in neighbors) {
        final dx = other.distanceMeters - rider.distanceMeters;
        if (dx < -safeLength || dx > config.overtakeScanRadiusMeters) {
          continue;
        }
        final dy = (other.lateralOffsetMeters - laneY).abs();
        if (dy < safeWidth * 1.15) {
          // Im bliżej wzdłużnie w promieniu 15 m, tym większy koszt zajętości pasa.
          final proximity =
              1.0 -
              (dx.abs() / config.overtakeScanRadiusMeters).clamp(0.0, 1.0);
          penalty += 1.0 + proximity * 2.0;
        }
      }
      return penalty;
    }

    if (activeLane == OvertakeLaneDirection.none || blockerAhead != null) {
      final leftCost = canGoLeft
          ? evaluateLaneOccupancy(leftCandidateY)
          : 999.0;
      final rightCost = canGoRight
          ? evaluateLaneOccupancy(rightCandidateY)
          : 999.0;

      if (leftCost >= 999.0 && rightCost >= 999.0) {
        return _OvertakeResult(
          lane: OvertakeLaneDirection.none,
          forceX: 0.0,
          forceY: 0.0,
          targetLaneY: rider.lateralOffsetMeters,
          cooldownSec: 0.0,
        );
      }

      if (leftCost <= rightCost) {
        activeLane = OvertakeLaneDirection.left;
      } else {
        activeLane = OvertakeLaneDirection.right;
      }
      cooldown = 0.75;
    }

    final targetLaneY = activeLane == OvertakeLaneDirection.left
        ? leftCandidateY
        : rightCandidateY;
    final dy = targetLaneY - rider.lateralOffsetMeters;

    return _OvertakeResult(
      lane: activeLane,
      forceX: 0.45,
      forceY: dy.clamp(-1.8, 1.8),
      targetLaneY: targetLaneY,
      cooldownSec: cooldown,
    );
  }

  double _computeBoundaryForceY({
    required double lateralOffsetMeters,
    required double halfPlayableWidth,
  }) {
    if (lateralOffsetMeters < -halfPlayableWidth) {
      return (-halfPlayableWidth - lateralOffsetMeters) * 2.5;
    }
    if (lateralOffsetMeters > halfPlayableWidth) {
      return (halfPlayableWidth - lateralOffsetMeters) * 2.5;
    }
    const margin = 0.25;
    if (lateralOffsetMeters < -halfPlayableWidth + margin) {
      return ((-halfPlayableWidth + margin) - lateralOffsetMeters) * 0.8;
    }
    if (lateralOffsetMeters > halfPlayableWidth - margin) {
      return ((halfPlayableWidth - margin) - lateralOffsetMeters) * 0.8;
    }
    return 0.0;
  }

  /// Twarde rozdzielenie nakładających się kopuł (1.85 m x 0.65 m),
  /// gwarantujące brak przenikania siatek 3D nawet w dużym ścisku w czasie O(N).
  int _resolveHardCollisions({
    required List<BoidRiderState> states,
    required List<int> activeIndices,
    required double halfPlayableWidth,
  }) {
    final safeLength = config.riderLengthMeters;
    final safeWidth = config.riderWidthMeters;
    var resolvedPairs = 0;
    final grid = _sharedGrid;

    for (var pass = 0; pass < 32; pass++) {
      grid.beginFrame(states.length);
      for (final idx in activeIndices) {
        final s = states[idx];
        grid.insert(idx, s.distanceMeters, s.lateralOffsetMeters);
      }
      final gridNext = grid.nextArray;
      final gridCellX = grid.cellXArray;
      var anyOverlapInPass = false;

      final reverseOrder = pass.isEven;
      final count = activeIndices.length;
      for (var step = 0; step < count; step++) {
        final idxA = activeIndices[reverseOrder ? (count - 1 - step) : step];
        final a = states[idxA];
        final minCx = grid.cellXFor(a.distanceMeters);
        final maxCx = grid.cellXFor(a.distanceMeters + safeLength);

        for (var cx = minCx; cx <= maxCx; cx++) {
          var idxB = grid.bucketHeadRaw(cx);
          while (idxB != -1) {
            if (idxB != idxA && gridCellX[idxB] == cx) {
              final curA = states[idxA];
              final b = states[idxB];
              final dx = b.distanceMeters - curA.distanceMeters;
              if (dx >= 0.0 && dx < safeLength && (dx > 0.0 || idxB > idxA)) {
                final dy = b.lateralOffsetMeters - curA.lateralOffsetMeters;
                final absDy = dy.abs();
                if (absDy < safeWidth) {
                  anyOverlapInPass = true;
                  resolvedPairs++;
                  final overlapY = (safeWidth - absDy) + 0.005;
                  final overlapX = (safeLength - dx) + 0.005;

                  final dirY = absDy > 0.0001
                      ? (dy >= 0 ? 1.0 : -1.0)
                      : (curA.riderId.compareTo(b.riderId) <= 0 ? 1.0 : -1.0);

                  final newYA = (curA.lateralOffsetMeters - dirY * overlapY * 0.5).clamp(
                    -halfPlayableWidth,
                    halfPlayableWidth,
                  );
                  final newYB = (b.lateralOffsetMeters + dirY * overlapY * 0.5).clamp(
                    -halfPlayableWidth,
                    halfPlayableWidth,
                  );

                  final remainingOverlapY = safeWidth - (newYB - newYA).abs();
                  var newXA = curA.distanceMeters;
                  if (remainingOverlapY > 0.0) {
                    newXA -= overlapX;
                  } else if (pass >= 6) {
                    // Rozładowanie zakleszczenia wielokierunkowego przy dużym ścisku.
                    newXA -= overlapX * 0.25;
                  }

                  states[idxA] = curA.copyWith(
                    distanceMeters: newXA,
                    lateralOffsetMeters: newYA,
                  );
                  states[idxB] = b.copyWith(lateralOffsetMeters: newYB);
                }
              }
            }
            idxB = gridNext[idxB];
          }
        }
      }

      if (!anyOverlapInPass) {
        break;
      }
    }

    return resolvedPairs;
  }
}

class _Vec2 {
  final double dx;
  final double dy;
  const _Vec2(this.dx, this.dy);
}

class _DraftResult {
  final double forceX;
  final double forceY;
  final String? targetRiderId;

  const _DraftResult({
    required this.forceX,
    required this.forceY,
    required this.targetRiderId,
  });
}

class _OvertakeResult {
  final OvertakeLaneDirection lane;
  final double forceX;
  final double forceY;
  final double targetLaneY;
  final double cooldownSec;

  const _OvertakeResult({
    required this.lane,
    required this.forceX,
    required this.forceY,
    required this.targetLaneY,
    required this.cooldownSec,
  });
}
