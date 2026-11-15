import 'dart:math' as math;
import 'dart:typed_data';

import '../../state/race_simulation_notifier.dart';

/// Konfiguracja parametrów fizycznych i wag 4 wektorów sił dla [BoidsPelotonFlockingSolver].
class BoidsFlockingConfig {
  /// Minimalny bezpieczny odstęp boczny między kolarzami [m].
  final double minLateralSeparationMeters;

  /// Minimalny bezpieczny odstęp wzdłużny (długość roweru + bufor) [m].
  final double minLongitudinalSeparationMeters;

  /// Zasięg patrzenia w przód dla wektora Alignment [m].
  final double alignmentLookaheadMeters;

  /// Optymalna odległość za kołem poprzedzającego kolarza w cieniu aero [m].
  final double draftOptimalGapMeters;

  /// Maksymalny zasięg oddziaływania tunelu aerodynamicznego [m].
  final double draftMaxRangeMeters;

  /// Próg różnicy prędkości (\Delta v > 0.8 m/s), powyżej którego kolarz inicjuje wyjście na wiatr.
  final double overtakeDeltaVThresholdMs;

  /// Zasięg skanowania wolnego pasa przy manewrze wyprzedzania [m].
  final double overtakeScanDistanceMeters;

  /// Szerokość pasa bocznego przy wyprzedzaniu [m].
  final double overtakeLaneOffsetMeters;

  /// Domyślna szerokość jezdni [m].
  final double defaultRoadWidthMeters;

  /// Margines bezpieczeństwa od krawędzi asfaltu [m].
  final double roadShoulderMarginMeters;

  /// Maksymalna prędkość poprzeczna zmiany pasa [m/s].
  final double maxLateralSpeedMs;

  /// Maksymalne przyspieszenie wzdłużne [m/s²].
  final double maxLongitudinalAccelMs2;

  /// Maksymalne opóźnienie (hamowanie) wzdłużne [m/s²].
  final double maxLongitudinalDecelMs2;

  /// Maksymalny kąt pochylenia roweru w zakręcie/zmianie pasa [rad].
  final double maxLeanAngleRad;

  /// Waga wektora Separation.
  final double separationWeight;

  /// Waga wektora Alignment.
  final double alignmentWeight;

  /// Waga wektora DraftSeeking.
  final double draftSeekingWeight;

  /// Waga wektora OvertakeLaneShift.
  final double overtakeLaneShiftWeight;

  /// Waga siły utrzymującej kolarzy w granicach szosy.
  final double boundaryWeight;

  /// Bazowy współczynnik oporu aerodynamicznego CdA pojedynczego kolarza [m²].
  final double baseRiderCda;

  /// Minimalny mnożnik CdA w najgłębszej kieszeni aerodynamicznej.
  final double minDraftCdaMultiplier;

  const BoidsFlockingConfig({
    this.minLateralSeparationMeters = 0.45,
    this.minLongitudinalSeparationMeters = 1.95,
    this.alignmentLookaheadMeters = 6.0,
    this.draftOptimalGapMeters = 1.35,
    this.draftMaxRangeMeters = 4.5,
    this.overtakeDeltaVThresholdMs = 0.8,
    this.overtakeScanDistanceMeters = 12.0,
    this.overtakeLaneOffsetMeters = 0.85,
    this.defaultRoadWidthMeters = 7.0,
    this.roadShoulderMarginMeters = 0.35,
    this.maxLateralSpeedMs = 2.4,
    this.maxLongitudinalAccelMs2 = 4.5,
    this.maxLongitudinalDecelMs2 = 6.5,
    this.maxLeanAngleRad = 0.26,
    this.separationWeight = 3.8,
    this.alignmentWeight = 1.8,
    this.draftSeekingWeight = 2.2,
    this.overtakeLaneShiftWeight = 3.0,
    this.boundaryWeight = 6.5,
    this.baseRiderCda = 0.31,
    this.minDraftCdaMultiplier = 0.58,
  });
}

/// Dwuwymiarowy wektor siły w układzie lokalnym szosy (oś X wzdłużna, oś Y poprzeczna).
class FlockingForceVector {
  final double longitudinal;
  final double lateral;

  const FlockingForceVector(this.longitudinal, this.lateral);

  static const zero = FlockingForceVector(0.0, 0.0);

  double get magnitude => math.sqrt(longitudinal * longitudinal + lateral * lateral);
}

/// Rozbicie sił Boids oraz wynikowych parametrów aerodynamicznych dla jednego kolarza.
class BoidFlockingForceBreakdown {
  final FlockingForceVector separation;
  final FlockingForceVector alignment;
  final FlockingForceVector draftSeeking;
  final FlockingForceVector overtakeLaneShift;
  final FlockingForceVector boundary;
  final FlockingForceVector total;
  final double estimatedCda;
  final double draftSavingsRatio;
  final String? draftLeaderId;
  final int overtakeDirection;

  const BoidFlockingForceBreakdown({
    required this.separation,
    required this.alignment,
    required this.draftSeeking,
    required this.overtakeLaneShift,
    required this.boundary,
    required this.total,
    required this.estimatedCda,
    required this.draftSavingsRatio,
    this.draftLeaderId,
    this.overtakeDirection = 0,
  });
}

/// Stan pojedynczego kolarza w solverze [BoidsPelotonFlockingSolver].
class PelotonBoidAgent {
  final String riderId;
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double speedMs;
  final double desiredSpeedMs;
  final double lateralVelocityMs;
  final double leanAngleRad;
  final double estimatedCda;
  final double draftSavingsRatio;
  final String? draftLeaderId;
  final int overtakeDirection;
  final bool isActive;

  const PelotonBoidAgent({
    required this.riderId,
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.speedMs,
    required this.desiredSpeedMs,
    this.lateralVelocityMs = 0.0,
    this.leanAngleRad = 0.0,
    this.estimatedCda = 0.31,
    this.draftSavingsRatio = 0.0,
    this.draftLeaderId,
    this.overtakeDirection = 0,
    this.isActive = true,
  });

  /// Tworzy agenta Boids na podstawie snapshotu symulacji wyścigu.
  factory PelotonBoidAgent.fromSnapshot(
    RiderPositionSnapshot snapshot, {
    double? desiredSpeedOverrideMs,
  }) {
    return PelotonBoidAgent(
      riderId: snapshot.riderId,
      distanceMeters: snapshot.distanceCoveredMeters,
      lateralOffsetMeters: snapshot.lateralOffsetRoadMeters,
      speedMs: snapshot.speedMs,
      desiredSpeedMs: desiredSpeedOverrideMs ?? snapshot.speedMs,
      isActive: !snapshot.isCrashed && !snapshot.isDnf,
    );
  }

  PelotonBoidAgent copyWith({
    String? riderId,
    double? distanceMeters,
    double? lateralOffsetMeters,
    double? speedMs,
    double? desiredSpeedMs,
    double? lateralVelocityMs,
    double? leanAngleRad,
    double? estimatedCda,
    double? draftSavingsRatio,
    String? draftLeaderId,
    bool clearDraftLeader = false,
    int? overtakeDirection,
    bool? isActive,
  }) {
    return PelotonBoidAgent(
      riderId: riderId ?? this.riderId,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      lateralOffsetMeters: lateralOffsetMeters ?? this.lateralOffsetMeters,
      speedMs: speedMs ?? this.speedMs,
      desiredSpeedMs: desiredSpeedMs ?? this.desiredSpeedMs,
      lateralVelocityMs: lateralVelocityMs ?? this.lateralVelocityMs,
      leanAngleRad: leanAngleRad ?? this.leanAngleRad,
      estimatedCda: estimatedCda ?? this.estimatedCda,
      draftSavingsRatio: draftSavingsRatio ?? this.draftSavingsRatio,
      draftLeaderId: clearDraftLeader ? null : (draftLeaderId ?? this.draftLeaderId),
      overtakeDirection: overtakeDirection ?? this.overtakeDirection,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Wynik pojedynczego kroku solvera [BoidsPelotonFlockingSolver].
class BoidsFlockingStepResult {
  final List<PelotonBoidAgent> agents;
  final Map<String, BoidFlockingForceBreakdown> breakdowns;
  final int activeRiderCount;
  final int activeOvertakeCount;
  final double averageCda;

  const BoidsFlockingStepResult({
    required this.agents,
    required this.breakdowns,
    required this.activeRiderCount,
    required this.activeOvertakeCount,
    required this.averageCda,
  });
}

/// Wysokowydajny solver unikania kolizji i płynnego ruchu 176 kolarzy dla sceny 3D.
///
/// Wykorzystuje 4 wektory sił:
/// 1. `Separation` — odpychanie boczne min. 0.45 m oraz utrzymanie odstępu wzdłużnego,
/// 2. `Alignment` — wyrównanie prędkości do kolarzy jadących bezpośrednio z przodu,
/// 3. `DraftSeeking` — wyszukiwanie kieszeni aerodynamicznej o najniższym CdA,
/// 4. `OvertakeLaneShift` — płynne wyjście na wiatr przy różnicy prędkości \Delta v > 0.8 m/s.
class BoidsPelotonFlockingSolver {
  final BoidsFlockingConfig config;

  // Wstępnie alokowane bufory robocze eliminujące alokacje GC w pętli 60/120 FPS.
  Int32List _sortedIndices = Int32List(0);
  Float64List _dist = Float64List(0);
  Float64List _lat = Float64List(0);
  Float64List _spd = Float64List(0);
  Float64List _desSpd = Float64List(0);
  Float64List _latVel = Float64List(0);
  Uint8List _active = Uint8List(0);
  Float64List _outDist = Float64List(0);
  Float64List _outLat = Float64List(0);
  Float64List _outSpd = Float64List(0);
  Float64List _outLatVel = Float64List(0);
  Float64List _outCda = Float64List(0);
  Float64List _outSavings = Float64List(0);
  Int32List _outLeaderIdx = Int32List(0);
  Int32List _outOvertakeDir = Int32List(0);

  BoidsPelotonFlockingSolver({this.config = const BoidsFlockingConfig()});

  void _ensureCapacity(int n) {
    if (_sortedIndices.length >= n) return;
    _sortedIndices = Int32List(n);
    _dist = Float64List(n);
    _lat = Float64List(n);
    _spd = Float64List(n);
    _desSpd = Float64List(n);
    _latVel = Float64List(n);
    _active = Uint8List(n);
    _outDist = Float64List(n);
    _outLat = Float64List(n);
    _outSpd = Float64List(n);
    _outLatVel = Float64List(n);
    _outCda = Float64List(n);
    _outSavings = Float64List(n);
    _outLeaderIdx = Int32List(n);
    _outOvertakeDir = Int32List(n);
  }

  /// Wykonuje jeden krok symulacji dla listy kolarzy (do 176+ jednostek) w czasie O(N·k).
  ///
  /// Parametr [collectBreakdowns] pozwala pominąć alokację mapy diagnostycznej w gorącej pętli.
  BoidsFlockingStepResult step(
    List<PelotonBoidAgent> agents, {
    double dtSeconds = 1.0 / 60.0,
    double? roadWidthMeters,
    double crosswindSpeedMs = 0.0,
    double windAngleRad = 0.0,
    bool collectBreakdowns = false,
  }) {
    final n = agents.length;
    if (n == 0) {
      return BoidsFlockingStepResult(
        agents: const [],
        breakdowns: const {},
        activeRiderCount: 0,
        activeOvertakeCount: 0,
        averageCda: config.baseRiderCda,
      );
    }

    final dt = dtSeconds.clamp(0.001, 0.1);
    final effectiveRoadWidth = math.max(
      config.minLateralSeparationMeters * 2.5,
      roadWidthMeters ?? config.defaultRoadWidthMeters,
    );
    final halfUsableRoad = math.max(
      0.35,
      effectiveRoadWidth * 0.5 - config.roadShoulderMarginMeters,
    );

    _ensureCapacity(n);

    for (var i = 0; i < n; i++) {
      final a = agents[i];
      _sortedIndices[i] = i;
      _dist[i] = a.distanceMeters;
      _lat[i] = a.lateralOffsetMeters;
      _spd[i] = a.speedMs;
      _desSpd[i] = a.desiredSpeedMs;
      _latVel[i] = a.lateralVelocityMs;
      _active[i] = a.isActive ? 1 : 0;
    }

    // Sortowanie wstawianiowe indeksów po distanceMeters — O(N) dla niemal posortowanego peletonu.
    for (var i = 1; i < n; i++) {
      final keyIdx = _sortedIndices[i];
      final keyDist = _dist[keyIdx];
      var j = i - 1;
      while (j >= 0 && _dist[_sortedIndices[j]] > keyDist) {
        _sortedIndices[j + 1] = _sortedIndices[j];
        j--;
      }
      _sortedIndices[j + 1] = keyIdx;
    }

    final maxScanRange = math.max(
      config.overtakeScanDistanceMeters,
      math.max(config.alignmentLookaheadMeters, config.draftMaxRangeMeters),
    );
    final echelonSlope = -math.sin(windAngleRad) * (crosswindSpeedMs / 8.0).clamp(-1.0, 1.0) * 0.35;
    final breakdowns = collectBreakdowns ? <String, BoidFlockingForceBreakdown>{} : const <String, BoidFlockingForceBreakdown>{};

    var activeCount = 0;
    var overtakeCount = 0;
    var cdaSum = 0.0;

    for (var pos = 0; pos < n; pos++) {
      final i = _sortedIndices[pos];
      if (_active[i] == 0) {
        _outDist[i] = _dist[i];
        _outLat[i] = _lat[i];
        _outSpd[i] = 0.0;
        _outLatVel[i] = 0.0;
        _outCda[i] = config.baseRiderCda;
        _outSavings[i] = 0.0;
        _outLeaderIdx[i] = -1;
        _outOvertakeDir[i] = 0;
        continue;
      }
      activeCount++;

      final distI = _dist[i];
      final latI = _lat[i];
      final spdI = _spd[i];
      final desSpdI = _desSpd[i];
      final latVelI = _latVel[i];

      var sepX = 0.0;
      var sepY = 0.0;
      var alignSpeedSum = 0.0;
      var alignLatVelSum = 0.0;
      var alignWeightSum = 0.0;

      var bestCda = config.baseRiderCda;
      var bestLeaderIdx = -1;
      var bestPocketX = distI;
      var bestPocketY = latI;

      var blockingLeaderIdx = -1;
      var blockingLeaderDist = double.infinity;

      // Skanowanie sąsiadów w tył (do 4.5 m dla separacji).
      for (var p = pos - 1; p >= 0; p--) {
        final j = _sortedIndices[p];
        final dx = _dist[j] - distI; // ujemne
        if (-dx > config.minLongitudinalSeparationMeters * 1.4) break;
        if (_active[j] == 0) continue;

        final dy = _lat[j] - latI;
        final absDx = -dx;
        final absDy = dy.abs();
        if (absDx < config.minLongitudinalSeparationMeters &&
            absDy < config.minLateralSeparationMeters * 1.8) {
          final nx = absDx / config.minLongitudinalSeparationMeters;
          final ny = absDy / config.minLateralSeparationMeters;
          final ellipSq = nx * nx + ny * ny;
          if (ellipSq < 1.0) {
            final intensity = 1.0 - math.sqrt(ellipSq);
            final latSign = dy == 0.0 ? (i < j ? -1.0 : 1.0) : (dy > 0.0 ? -1.0 : 1.0);
            sepY += latSign * intensity * config.separationWeight * 1.6;
            sepX += intensity * config.separationWeight * 0.35;
          }
        }
      }

      // Skanowanie sąsiadów w przód (Separation, Alignment, DraftSeeking, blokada Overtake).
      for (var p = pos + 1; p < n; p++) {
        final j = _sortedIndices[p];
        final dx = _dist[j] - distI; // dodatnie
        if (dx > maxScanRange) break;
        if (_active[j] == 0) continue;

        final dy = _lat[j] - latI;
        final absDy = dy.abs();

        // 1. Separation (odpychanie boczne min. 0.45 m + bufor wzdłużny).
        if (dx < config.minLongitudinalSeparationMeters &&
            absDy < config.minLateralSeparationMeters * 1.8) {
          final nx = dx / config.minLongitudinalSeparationMeters;
          final ny = absDy / config.minLateralSeparationMeters;
          final ellipSq = nx * nx + ny * ny;
          if (ellipSq < 1.0) {
            final intensity = 1.0 - math.sqrt(ellipSq);
            final latSign = dy == 0.0 ? (i < j ? -1.0 : 1.0) : (dy > 0.0 ? -1.0 : 1.0);
            sepY += latSign * intensity * config.separationWeight * 1.6;
            if (absDy < config.minLateralSeparationMeters * 0.9) {
              sepX -= intensity * config.separationWeight * 1.1;
            }
          }
        }

        // 2. Alignment (wyrównanie prędkości do kolarzy jadących z przodu).
        if (dx <= config.alignmentLookaheadMeters && absDy <= 0.95) {
          final w = (1.0 - dx / config.alignmentLookaheadMeters) *
              (1.0 - absDy / 1.1).clamp(0.15, 1.0);
          alignSpeedSum += _spd[j] * w;
          alignLatVelSum += _latVel[j] * w;
          alignWeightSum += w;
        }

        // Wykrywanie kolarza blokującego korytarz przed nami.
        if (dx <= config.overtakeScanDistanceMeters &&
            absDy < config.minLateralSeparationMeters * 1.45 &&
            dx < blockingLeaderDist) {
          blockingLeaderDist = dx;
          blockingLeaderIdx = j;
        }

        // 3. DraftSeeking (szukanie kieszeni najniższego CdA).
        if (dx >= 0.65 && dx <= config.draftMaxRangeMeters) {
          final pocketY = (_lat[j] + echelonSlope * dx).clamp(-halfUsableRoad, halfUsableRoad);
          final latErr = (latI - pocketY).abs();
          if (latErr <= 1.6) {
            final gapDelta = (dx - config.draftOptimalGapMeters).abs();
            final longFactor = (1.0 - gapDelta / config.draftMaxRangeMeters).clamp(0.0, 1.0);
            final latFactor = math.exp(-(latErr * latErr) / (2.0 * 0.55 * 0.55));
            final savings = (1.0 - config.minDraftCdaMultiplier) * longFactor * latFactor;
            final candidateCda = config.baseRiderCda * (1.0 - savings);
            if (candidateCda < bestCda) {
              bestCda = candidateCda;
              bestLeaderIdx = j;
              bestPocketX = _dist[j] - config.draftOptimalGapMeters;
              bestPocketY = pocketY;
            }
          }
        }
      }

      // 4. OvertakeLaneShift (płynne wyjście na wiatr przy różnicy prędkości \Delta v > 0.8 m/s).
      var overtakeX = 0.0;
      var overtakeY = 0.0;
      var overtakeDir = 0;

      if (blockingLeaderIdx != -1) {
        final deltaV = desSpdI - _spd[blockingLeaderIdx];
        if (deltaV > config.overtakeDeltaVThresholdMs) {
          final blockLat = _lat[blockingLeaderIdx];
          final leftTarget = blockLat - config.overtakeLaneOffsetMeters;
          final rightTarget = blockLat + config.overtakeLaneOffsetMeters;

          final leftClear = leftTarget >= -halfUsableRoad &&
              _isLaneClear(pos, n, distI, leftTarget, config.overtakeScanDistanceMeters);
          final rightClear = rightTarget <= halfUsableRoad &&
              _isLaneClear(pos, n, distI, rightTarget, config.overtakeScanDistanceMeters);

          if (leftClear || rightClear) {
            if (leftClear && rightClear) {
              // Wybierz stronę bliższą obecnej pozycji lub korzystniejszą względem wiatru.
              final preferRight = (rightTarget - latI).abs() < (leftTarget - latI).abs();
              overtakeDir = preferRight ? 1 : -1;
            } else {
              overtakeDir = leftClear ? -1 : 1;
            }
            final targetLaneY = overtakeDir < 0 ? leftTarget : rightTarget;
            final latDiff = targetLaneY - latI;
            overtakeY = latDiff.clamp(-1.5, 1.5) * config.overtakeLaneShiftWeight * 2.2;
            overtakeX = (desSpdI - spdI).clamp(0.0, 2.5) * 0.65;
            overtakeCount++;
          }
        }
      }

      // Obliczenie finalnych wektorów Alignment i DraftSeeking (wyłączamy ciągnięcie w tunel podczas wyprzedzania).
      var alignX = 0.0;
      var alignY = 0.0;
      if (alignWeightSum > 0.0 && overtakeDir == 0) {
        final targetAlignSpd = alignSpeedSum / alignWeightSum;
        final targetAlignLatVel = alignLatVelSum / alignWeightSum;
        alignX = (targetAlignSpd - spdI) * config.alignmentWeight;
        alignY = (targetAlignLatVel - latVelI) * config.alignmentWeight * 0.45;
      }

      var draftX = 0.0;
      var draftY = 0.0;
      if (bestLeaderIdx != -1 && overtakeDir == 0) {
        draftX = (bestPocketX - distI).clamp(-1.2, 1.2) * config.draftSeekingWeight * 0.55;
        draftY = (bestPocketY - latI).clamp(-1.4, 1.4) * config.draftSeekingWeight;
      }

      // Siła utrzymania w granicach szosy.
      var boundaryY = 0.0;
      if (latI > halfUsableRoad) {
        boundaryY = -(latI - halfUsableRoad) * config.boundaryWeight * 2.0;
      } else if (latI < -halfUsableRoad) {
        boundaryY = (-halfUsableRoad - latI) * config.boundaryWeight * 2.0;
      }

      // Dążenie do prędkości własnej kolarza (bazowy napęd).
      final cruiseDriveX = (desSpdI - spdI) * (overtakeDir != 0 ? 1.8 : 1.05);

      final totalX = (cruiseDriveX + sepX + alignX + draftX + overtakeX)
          .clamp(-config.maxLongitudinalDecelMs2, config.maxLongitudinalAccelMs2);
      final totalY = sepY + alignY + draftY + overtakeY + boundaryY;

      final newSpd = math.max(0.0, spdI + totalX * dt);
      final latDamping = math.exp(-3.2 * dt);
      final dampedLatVel = (latVelI * latDamping + totalY * dt)
          .clamp(-config.maxLateralSpeedMs, config.maxLateralSpeedMs);

      _outSpd[i] = newSpd;
      _outDist[i] = distI + newSpd * dt;
      _outLatVel[i] = dampedLatVel;
      _outLat[i] = (latI + dampedLatVel * dt).clamp(-halfUsableRoad, halfUsableRoad);
      _outCda[i] = bestCda;
      _outSavings[i] = ((config.baseRiderCda - bestCda) / config.baseRiderCda).clamp(0.0, 1.0);
      _outLeaderIdx[i] = bestLeaderIdx;
      _outOvertakeDir[i] = overtakeDir;

      cdaSum += bestCda;

      if (collectBreakdowns) {
        breakdowns[agents[i].riderId] = BoidFlockingForceBreakdown(
          separation: FlockingForceVector(sepX, sepY),
          alignment: FlockingForceVector(alignX, alignY),
          draftSeeking: FlockingForceVector(draftX, draftY),
          overtakeLaneShift: FlockingForceVector(overtakeX, overtakeY),
          boundary: FlockingForceVector(0.0, boundaryY),
          total: FlockingForceVector(totalX, totalY),
          estimatedCda: bestCda,
          draftSavingsRatio: _outSavings[i],
          draftLeaderId: bestLeaderIdx != -1 ? agents[bestLeaderIdx].riderId : null,
          overtakeDirection: overtakeDir,
        );
      }
    }

    // Twarda projekcja bezkolizyjna gwarantująca min. 0.45 m odstępu bocznego przy nakładaniu wzdłużnym.
    _enforceMinLateralClearance(n, halfUsableRoad);

    final outAgents = List<PelotonBoidAgent>.generate(n, (i) {
      final a = agents[i];
      if (_active[i] == 0) {
        return a.copyWith(speedMs: 0.0, lateralVelocityMs: 0.0, leanAngleRad: 0.0);
      }
      final lean = (-_outLatVel[i] / config.maxLateralSpeedMs * config.maxLeanAngleRad)
          .clamp(-config.maxLeanAngleRad, config.maxLeanAngleRad);
      final leaderIdx = _outLeaderIdx[i];
      return PelotonBoidAgent(
        riderId: a.riderId,
        distanceMeters: _outDist[i],
        lateralOffsetMeters: _outLat[i],
        speedMs: _outSpd[i],
        desiredSpeedMs: a.desiredSpeedMs,
        lateralVelocityMs: _outLatVel[i],
        leanAngleRad: lean,
        estimatedCda: _outCda[i],
        draftSavingsRatio: _outSavings[i],
        draftLeaderId: leaderIdx != -1 ? agents[leaderIdx].riderId : null,
        overtakeDirection: _outOvertakeDir[i],
        isActive: true,
      );
    }, growable: false);

    return BoidsFlockingStepResult(
      agents: outAgents,
      breakdowns: breakdowns,
      activeRiderCount: activeCount,
      activeOvertakeCount: overtakeCount,
      averageCda: activeCount > 0 ? cdaSum / activeCount : config.baseRiderCda,
    );
  }

  bool _isLaneClear(
    int pos,
    int n,
    double distI,
    double targetLat,
    double scanDistance,
  ) {
    final minClear = config.minLateralSeparationMeters * 1.15;
    for (var p = pos + 1; p < n; p++) {
      final j = _sortedIndices[p];
      final dx = _dist[j] - distI;
      if (dx > scanDistance) break;
      if (_active[j] == 0) continue;
      if ((_lat[j] - targetLat).abs() < minClear) {
        return false;
      }
    }
    return true;
  }

  void _enforceMinLateralClearance(int n, double halfUsableRoad) {
    final minLat = config.minLateralSeparationMeters;
    final overlapLong = config.minLongitudinalSeparationMeters * 0.82;

    for (var pos = 0; pos < n; pos++) {
      final i = _sortedIndices[pos];
      if (_active[i] == 0) continue;

      for (var p = pos + 1; p < n; p++) {
        final j = _sortedIndices[p];
        if ((_outDist[j] - _outDist[i]).abs() > overlapLong) break;
        if (_active[j] == 0) continue;

        final dy = _outLat[j] - _outLat[i];
        final absDy = dy.abs();
        if (absDy < minLat) {
          final push = (minLat - absDy) * 0.52;
          final sign = dy == 0.0 ? (i < j ? 1.0 : -1.0) : (dy > 0.0 ? 1.0 : -1.0);
          _outLat[i] = (_outLat[i] - sign * push).clamp(-halfUsableRoad, halfUsableRoad);
          _outLat[j] = (_outLat[j] + sign * push).clamp(-halfUsableRoad, halfUsableRoad);
        }
      }
    }
  }
}
