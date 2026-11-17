// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/rendering3d/camera_rig_controller.dart';
import '../../engine/rendering3d/wind_streamlines_visualizer.dart';
import '../../engine/simulation/stage_replay_recorder.dart';

// ============================================================================
// 1. ANALIZATOR SUKCESU TAKTYCZNEGO POWTÓRKI (REPLAY SUCCESS ANALYZER)
// ============================================================================

/// Powód sukcesu lub kluczowy czynnik przewagi w badanym klipie powtórki.
class ReplaySuccessFactor {
  final String title;
  final String detail;
  final String metricBadge;
  final Color accentColor;
  final IconData icon;

  const ReplaySuccessFactor({
    required this.title,
    required this.detail,
    required this.metricBadge,
    required this.accentColor,
    required this.icon,
  });
}

/// Wynik analizy taktycznej i fizycznej wybranego klipu w kinie powtórek.
class ReplaySuccessAnalysisReport {
  final String winnerRiderId;
  final String winnerRiderName;
  final int winnerBibNumber;
  final String winnerTeamId;
  final String focusedRiderId;
  final String focusedRiderName;
  final int focusedRiderRankInFrame;
  final int totalRidersInClip;

  final double winnerAvgSpeedKmh;
  final double winnerPeakSpeedKmh;
  final int winnerAvgPowerWatts;
  final int winnerPeakPowerWatts;
  final double pelotonAvgSpeedKmh;
  final int pelotonAvgPowerWatts;

  final double preAttackDraftingRatio;
  final double attackLaunchDistanceToFinishKm;
  final double attackLaunchGradientPercent;
  final double speedSurgeKmh;
  final int powerSurgeWatts;
  final bool usedBikeThrowAtFinish;
  final String headlineVerdict;
  final List<ReplaySuccessFactor> factors;

  const ReplaySuccessAnalysisReport({
    required this.winnerRiderId,
    required this.winnerRiderName,
    required this.winnerBibNumber,
    required this.winnerTeamId,
    required this.focusedRiderId,
    required this.focusedRiderName,
    required this.focusedRiderRankInFrame,
    required this.totalRidersInClip,
    required this.winnerAvgSpeedKmh,
    required this.winnerPeakSpeedKmh,
    required this.winnerAvgPowerWatts,
    required this.winnerPeakPowerWatts,
    required this.pelotonAvgSpeedKmh,
    required this.pelotonAvgPowerWatts,
    required this.preAttackDraftingRatio,
    required this.attackLaunchDistanceToFinishKm,
    required this.attackLaunchGradientPercent,
    required this.speedSurgeKmh,
    required this.powerSurgeWatts,
    required this.usedBikeThrowAtFinish,
    required this.headlineVerdict,
    required this.factors,
  });
}

/// Kalkulator analizujący klatki [ReplayClip] pod kątem przyczyn sukcesu ataku lub sprintu.
class ReplayTacticalSuccessAnalyzer {
  const ReplayTacticalSuccessAnalyzer._();

  static ReplaySuccessAnalysisReport analyze({
    required ReplayClip clip,
    required int currentFrameIndex,
    String? focusedRiderId,
  }) {
    if (clip.frames.isEmpty) {
      return const ReplaySuccessAnalysisReport(
        winnerRiderId: '',
        winnerRiderName: 'Brak danych',
        winnerBibNumber: 0,
        winnerTeamId: '-',
        focusedRiderId: '',
        focusedRiderName: 'Brak danych',
        focusedRiderRankInFrame: 0,
        totalRidersInClip: 0,
        winnerAvgSpeedKmh: 0.0,
        winnerPeakSpeedKmh: 0.0,
        winnerAvgPowerWatts: 0,
        winnerPeakPowerWatts: 0,
        pelotonAvgSpeedKmh: 0.0,
        pelotonAvgPowerWatts: 0,
        preAttackDraftingRatio: 0.0,
        attackLaunchDistanceToFinishKm: 0.0,
        attackLaunchGradientPercent: 0.0,
        speedSurgeKmh: 0.0,
        powerSurgeWatts: 0,
        usedBikeThrowAtFinish: false,
        headlineVerdict: 'Brak klatek powtórki do analizy.',
        factors: [],
      );
    }

    final safeIndex = currentFrameIndex.clamp(0, clip.frames.length - 1);
    final lastFrame = clip.frames.last;
    final currentFrame = clip.frames[safeIndex];

    // Zwycięzca / lider na końcu klipu
    final sortedLast = List<ReplayRiderState>.from(lastFrame.riders)
      ..sort((a, b) => b.distanceCoveredMeters.compareTo(a.distanceCoveredMeters));
    final winner = sortedLast.isNotEmpty ? sortedLast.first : null;
    final winnerId = winner?.riderId ?? '';

    // Obserwowany kolarz w bieżącej klatce
    final sortedCurrent = List<ReplayRiderState>.from(currentFrame.riders)
      ..sort((a, b) => b.distanceCoveredMeters.compareTo(a.distanceCoveredMeters));
    final targetId = focusedRiderId ?? winnerId;
    int focusedRank = sortedCurrent.indexWhere((r) => r.riderId == targetId) + 1;
    if (focusedRank <= 0 && sortedCurrent.isNotEmpty) {
      focusedRank = 1;
    }
    final focusedRider = currentFrame.getRider(targetId) ??
        (sortedCurrent.isNotEmpty ? sortedCurrent.first : null);

    double winnerSpeedSum = 0.0;
    double winnerPeakSpeed = 0.0;
    int winnerPowerSum = 0;
    int winnerPeakPower = 0;
    int winnerSamples = 0;
    int preAttackDraftSamples = 0;
    int preAttackTotalSamples = 0;
    bool usedBikeThrow = false;

    double pelotonSpeedSum = 0.0;
    int pelotonPowerSum = 0;
    int pelotonSamples = 0;

    // Detekcja momentu przyspieszenia / ataku zwycięzcy
    int surgeFrameIdx = 0;
    double maxSpeedJump = 0.0;
    int maxPowerJump = 0;
    double prevWinnerSpeed = 0.0;
    int prevWinnerPower = 0;

    for (int i = 0; i < clip.frames.length; i++) {
      final f = clip.frames[i];
      if (f.riders.isEmpty) continue;

      double frameSpeedSum = 0.0;
      int framePowerSum = 0;
      for (final r in f.riders) {
        frameSpeedSum += r.speedKmh;
        framePowerSum += r.powerWatts;
      }
      pelotonSpeedSum += frameSpeedSum / f.riders.length;
      pelotonPowerSum += (framePowerSum / f.riders.length).round();
      pelotonSamples++;

      final wState = f.getRider(winnerId);
      if (wState != null) {
        winnerSpeedSum += wState.speedKmh;
        winnerPowerSum += wState.powerWatts;
        if (wState.speedKmh > winnerPeakSpeed) winnerPeakSpeed = wState.speedKmh;
        if (wState.powerWatts > winnerPeakPower) winnerPeakPower = wState.powerWatts;
        if (wState.isBikeThrow) usedBikeThrow = true;

        if (i > 0) {
          final dSpeed = wState.speedKmh - prevWinnerSpeed;
          final dPower = wState.powerWatts - prevWinnerPower;
          if (dPower > maxPowerJump || dSpeed > maxSpeedJump) {
            maxPowerJump = math.max(maxPowerJump, dPower);
            maxSpeedJump = math.max(maxSpeedJump, dSpeed);
            surgeFrameIdx = i;
          }
        }
        prevWinnerSpeed = wState.speedKmh;
        prevWinnerPower = wState.powerWatts;
        winnerSamples++;
      }
    }

    // Ocena oszczędzania sił w cieniu przed momentem przyspieszenia
    final preWindowEnd = math.max(1, surgeFrameIdx);
    for (int i = 0; i < preWindowEnd && i < clip.frames.length; i++) {
      final wState = clip.frames[i].getRider(winnerId);
      if (wState != null) {
        preAttackTotalSamples++;
        if (wState.isDrafting) preAttackDraftSamples++;
      }
    }

    final winnerAvgSpeed = winnerSamples > 0 ? winnerSpeedSum / winnerSamples : 0.0;
    final winnerAvgPower = winnerSamples > 0 ? (winnerPowerSum / winnerSamples).round() : 0;
    final pelotonAvgSpeed = pelotonSamples > 0 ? pelotonSpeedSum / pelotonSamples : 0.0;
    final pelotonAvgPower = pelotonSamples > 0 ? (pelotonPowerSum / pelotonSamples).round() : 0;
    final draftingRatio =
        preAttackTotalSamples > 0 ? preAttackDraftSamples / preAttackTotalSamples : 0.0;

    final surgeFrame = clip.frames[surgeFrameIdx.clamp(0, clip.frames.length - 1)];
    final factors = <ReplaySuccessFactor>[];

    // 1. Cień aerodynamiczny przed atakiem / sprintem
    if (draftingRatio >= 0.45) {
      factors.add(ReplaySuccessFactor(
        title: 'Oszczędność w tunelu aero przed zrywem',
        detail:
            'Kolarz przebywał w cieniu aerodynamicznym przez ${(draftingRatio * 100).round()}% fazy wstępnej, zachowując świeże włókna szybkokurczliwe.',
        metricBadge: '${(draftingRatio * 100).round()}% DRAFT',
        accentColor: AppColors.statusSuccess,
        icon: Icons.air_rounded,
      ));
    } else {
      factors.add(ReplaySuccessFactor(
        title: 'Agresywna jazda na otwartym wietrze',
        detail:
            'Atak wyprowadzony z pierwszej linii bez długiego krycia na kole — czysta przewaga bezwzględnej mocy nad grupą.',
        metricBadge: '+${math.max(0, winnerAvgPower - pelotonAvgPower)} W',
        accentColor: AppColors.amberWarning,
        icon: Icons.bolt_rounded,
      ));
    }

    // 2. Skok mocy / moment odpalenia
    factors.add(ReplaySuccessFactor(
      title: clip.type == ReplayClipType.finalKilometer
          ? 'Decydująca proca sprinterska'
          : 'Timing skoku na ${surgeFrame.distanceToFinishKm.toStringAsFixed(2)} km do mety',
      detail:
          'Impuls $winnerPeakPower W (${winnerPeakSpeed.toStringAsFixed(1)} km/h) przy nachyleniu ${surgeFrame.currentGradientPercent.toStringAsFixed(1)}% rozerwał stawkę.',
      metricBadge: '$winnerPeakPower W PEAK',
      accentColor: AppColors.cyanAccent,
      icon: Icons.flash_on_rounded,
    ));

    // 3. Przewaga prędkości nad peletonem
    final speedDelta = winnerAvgSpeed - pelotonAvgSpeed;
    factors.add(ReplaySuccessFactor(
      title: 'Przewaga kinetyczna nad grupą',
      detail:
          'Średnia prędkość w sekwencji wyniosła ${winnerAvgSpeed.toStringAsFixed(1)} km/h wobec ${pelotonAvgSpeed.toStringAsFixed(1)} km/h peletonu.',
      metricBadge: '${speedDelta >= 0 ? '+' : ''}${speedDelta.toStringAsFixed(1)} km/h',
      accentColor: AppColors.accentBlue,
      icon: Icons.speed_rounded,
    ));

    // 4. Rzut rowerem na kreskę
    if (usedBikeThrow) {
      factors.add(const ReplaySuccessFactor(
        title: 'Perfekcyjny rzut rowerem (Bike Throw)',
        detail:
            'Wypchnięcie roweru przed linię ciała na ostatnich metrach dodało kluczowe centymetry na fotofiniszu.',
        metricBadge: '+24 CM THROW',
        accentColor: AppColors.goldAccent,
        icon: Icons.emoji_events_rounded,
      ));
    }

    final headline = clip.type == ReplayClipType.finalKilometer
        ? '${winner?.riderName ?? "Zwycięzca"} wygrał finisz dzięki $winnerPeakPower W w szczycie i wyjściu z tunelu aero (${winnerPeakSpeed.toStringAsFixed(1)} km/h).'
        : '${winner?.riderName ?? "Lider"} rozstrzygnął moment na ${surgeFrame.leadKilometerMark.toStringAsFixed(1)} km skokiem +${math.max(0, winnerPeakPower - pelotonAvgPower)} W ponad średnią grupy.';

    return ReplaySuccessAnalysisReport(
      winnerRiderId: winnerId,
      winnerRiderName: winner?.riderName ?? 'Brak',
      winnerBibNumber: winner?.bibNumber ?? 0,
      winnerTeamId: winner?.teamId ?? '-',
      focusedRiderId: focusedRider?.riderId ?? winnerId,
      focusedRiderName: focusedRider?.riderName ?? (winner?.riderName ?? 'Brak'),
      focusedRiderRankInFrame: focusedRank,
      totalRidersInClip: currentFrame.riders.length,
      winnerAvgSpeedKmh: winnerAvgSpeed,
      winnerPeakSpeedKmh: winnerPeakSpeed,
      winnerAvgPowerWatts: winnerAvgPower,
      winnerPeakPowerWatts: winnerPeakPower,
      pelotonAvgSpeedKmh: pelotonAvgSpeed,
      pelotonAvgPowerWatts: pelotonAvgPower,
      preAttackDraftingRatio: draftingRatio,
      attackLaunchDistanceToFinishKm: surgeFrame.distanceToFinishKm,
      attackLaunchGradientPercent: surgeFrame.currentGradientPercent,
      speedSurgeKmh: maxSpeedJump,
      powerSurgeWatts: maxPowerJump,
      usedBikeThrowAtFinish: usedBikeThrow,
      headlineVerdict: headline,
      factors: factors,
    );
  }
}

// ============================================================================
// 2. GENERATOR DANYCH POKAZOWYCH 176 KOLARZY (GDY BRAK ZEWNĘTRZNEGO REJESTRATORA)
// ============================================================================

/// Buduje realistyczny [StageReplayRecorder] ze 176 kolarzami i 3 klipami (finisz, atak GC, ranty).
class ReplayTheaterSampleBuilder {
  const ReplayTheaterSampleBuilder._();

  static const List<String> _teamIds = [
    'TJV', 'UAE', 'IGD', 'SOQ', 'ADC', 'BOH', 'TBV', 'LTK', 'GFC', 'EFE',
    'MOV', 'DSM', 'COF', 'ARK', 'AST', 'JAY', 'IPT', 'UXT', 'LOT', 'TUD',
    'Q36', 'UXM',
  ];

  static const List<String> _teamHexColors = [
    '#FACC15', '#E5E7EB', '#EF4444', '#2563EB', '#1D4ED8', '#10B981', '#F97316', '#DC2626',
    '#3B82F6', '#EC4899', '#0EA5E9', '#38BDF8', '#B91C1C', '#E11D48', '#06B6D4', '#4F46E5',
    '#0284C7', '#F59E0B', '#DC2626', '#111827', '#059669', '#8B5CF6',
  ];

  static const List<String> _sampleNames = [
    'K. Kowalski', 'M. Nowak', 'J. Vingegaard', 'T. Pogacar', 'W. Van Aert', 'M. Van der Poel',
    'J. Philipsen', 'R. Evenepoel', 'P. Roglic', 'B. Girmay', 'M. Pedersen', 'D. Groenewegen',
    'F. Jakobsen', 'T. Merlier', 'O. Kooij', 'J. Milan', 'C. Laporte', 'A. De Lie',
  ];

  static StageReplayRecorder createDemoRecorder({int riderCount = 176}) {
    final recorder = StageReplayRecorder(stageName: 'Etap 14 • Alpe d\'Huez / Champs-Élysées');
    final rng = math.Random(2026);

    final ridersMeta = List.generate(riderCount, (i) {
      final teamIdx = i % _teamIds.length;
      final baseName = i < _sampleNames.length
          ? _sampleNames[i]
          : 'Kolarz #${(i + 1).toString().padLeft(3, '0')}';
      return (
        id: 'rider_${i + 1}',
        bib: i + 1,
        name: baseName,
        teamId: _teamIds[teamIdx],
        hex: _teamHexColors[teamIdx],
        isPlayer: i < 8,
        baseLateral: ((i % 7) - 3) * 0.85,
        baseSpeedOffset: (i == 0 ? 1.8 : (i < 6 ? 1.1 - i * 0.15 : -(i * 0.018))),
      );
    });

    // Klip 1: Ostatni kilometr sprintu (45 klatek)
    const int finishFramesCount = 45;
    final finishFrames = <ReplayFrameSnapshot>[];
    for (int f = 0; f < finishFramesCount; f++) {
      final tNorm = f / (finishFramesCount - 1);
      final leadDist = 178000.0 + tNorm * 1000.0;
      final distToFinish = (1000.0 - tNorm * 1000.0) / 1000.0;
      final isNearFinish = distToFinish <= 0.06;

      final riders = List.generate(riderCount, (i) {
        final meta = ridersMeta[i];
        // Zwycięzca (#1) wyskakuje z koła rozprowadzającego przy tNorm > 0.55
        double surge = 0.0;
        if (i == 0 && tNorm > 0.52) {
          surge = (tNorm - 0.52) * 32.0;
        } else if (i == 1 && tNorm > 0.45) {
          surge = (tNorm - 0.45) * 24.0;
        } else if (i < 10) {
          surge = tNorm * (14.0 - i);
        }

        final dist = leadDist - (i * 0.72) + surge + (rng.nextDouble() - 0.5) * 0.25;
        final speedKmh = (58.0 + tNorm * 14.5 + meta.baseSpeedOffset + (i == 0 && tNorm > 0.52 ? 5.2 : 0.0))
            .clamp(38.0, 77.5);
        final isSprinting = tNorm > 0.55 && i < 18;
        final power = isSprinting
            ? (980 + (18 - i) * 28 + (i == 0 ? 160 : 0))
            : (390 + (i % 6) * 25);
        final lateral = (meta.baseLateral +
                (i == 0 && tNorm > 0.52 ? -0.9 : 0.0) +
                math.sin(tNorm * 4 + i) * 0.15)
            .clamp(-3.3, 3.3);
        final isDrafting = i > 0 && !(i == 0 && tNorm > 0.55);

        return ReplayRiderState(
          riderId: meta.id,
          bibNumber: meta.bib,
          riderName: meta.name,
          teamId: meta.teamId,
          teamJerseyHexColor: meta.hex,
          isPlayerRider: meta.isPlayer,
          distanceCoveredMeters: dist,
          lateralOffsetRoadMeters: lateral,
          elevationMeters: 124.0 + tNorm * 4.5,
          speedMs: speedKmh / 3.6,
          speedKmh: speedKmh,
          powerWatts: power,
          cadenceRpm: isSprinting ? 112 : 96,
          heartRateBpm: (174 + (tNorm * 18).round() - (i % 5)).clamp(150, 198),
          isSprinting: isSprinting,
          isBikeThrow: isNearFinish && i < 3,
          isDrafting: isDrafting,
          isCrashed: false,
          hasDefect: false,
        );
      });

      finishFrames.add(ReplayFrameSnapshot(
        frameIndex: f,
        timestampSeconds: 14210.0 + f * 1.1,
        leadKilometerMark: leadDist / 1000.0,
        distanceToFinishKm: distToFinish,
        currentGradientPercent: 0.8,
        currentElevationMeters: 124.0 + tNorm * 4.5,
        leadRiderName: tNorm > 0.65 ? ridersMeta[0].name : ridersMeta[1].name,
        activeMomentTag: isNearFinish ? 'Finisz na kreskę' : 'Pociąg sprinterski • Ostatni 1 km',
        riders: riders,
      ));
    }

    // Zapisujemy ręcznie poprzez publiczne struktury lub zwracamy opakowany wynik
    // Dodajemy do wewnętrznej listy przez symulację snapshotów? Lepiej przekazać gotowe klipy
    // bezpośrednio w StageReplayRecorder lub przez helper zwracający List<ReplayClip>.
    // Uwaga: StageReplayRecorder.recordSnapshot() buduje _finalKmFrames automatycznie.
    // Użyjmy dedykowanego kontenera klipów zbudowanego z StageReplayRecorder + dodatkowych klipów!
    final clipFinish = ReplayClip(
      id: 'clip_final_kilometer',
      title: 'Decydujący Finisz • Ostatni Kilometr',
      description: 'Proca sprinterska na ostatnich 350 m i rzut rowerem na kreskę.',
      type: ReplayClipType.finalKilometer,
      startDistanceKm: 178.0,
      endDistanceKm: 179.0,
      startTimestampSeconds: 14210.0,
      endTimestampSeconds: 14258.4,
      frames: finishFrames,
    );

    // Klip 2: Atak faworyta GC na podjeździe HC (35 klatek)
    const int attackFramesCount = 35;
    final attackFrames = <ReplayFrameSnapshot>[];
    for (int f = 0; f < attackFramesCount; f++) {
      final tNorm = f / (attackFramesCount - 1);
      final leadDist = 148200.0 + tNorm * 620.0;
      final riders = List.generate(riderCount, (i) {
        final meta = ridersMeta[i];
        final isAttacker = i == 3 || i == 0;
        final surge = isAttacker && tNorm > 0.35 ? (tNorm - 0.35) * 42.0 : 0.0;
        final speedKmh = isAttacker && tNorm > 0.35 ? 25.4 : (20.8 - (i * 0.015)).clamp(15.0, 22.0);
        final power = isAttacker && tNorm > 0.35 ? 545 : (375 - (i % 10) * 6);
        return ReplayRiderState(
          riderId: meta.id,
          bibNumber: meta.bib,
          riderName: meta.name,
          teamId: meta.teamId,
          teamJerseyHexColor: meta.hex,
          isPlayerRider: meta.isPlayer,
          distanceCoveredMeters: leadDist - i * 1.1 + surge,
          lateralOffsetRoadMeters: (meta.baseLateral * 0.7).clamp(-3.0, 3.0),
          elevationMeters: 1620.0 + tNorm * 58.0,
          speedMs: speedKmh / 3.6,
          speedKmh: speedKmh,
          powerWatts: power,
          cadenceRpm: isAttacker && tNorm > 0.35 ? 94 : 78,
          heartRateBpm: isAttacker ? 189 : 176,
          isSprinting: isAttacker && tNorm > 0.35 && tNorm < 0.55,
          isBikeThrow: false,
          isDrafting: !isAttacker && i > 2,
          isCrashed: false,
          hasDefect: false,
        );
      });

      attackFrames.add(ReplayFrameSnapshot(
        frameIndex: f,
        timestampSeconds: 11840.0 + f * 1.5,
        leadKilometerMark: leadDist / 1000.0,
        distanceToFinishKm: 30.8 - tNorm * 0.62,
        currentGradientPercent: 9.4,
        currentElevationMeters: 1620.0 + tNorm * 58.0,
        leadRiderName: ridersMeta[3].name,
        activeMomentTag: 'Atak GC • Col du Galibier 9.4%',
        riders: riders,
      ));
    }

    final clipGcAttack = ReplayClip(
      id: 'clip_attack_gc',
      title: 'Atak Lidera GC • Col du Galibier',
      description: 'Oderwanie na nachyleniu 9.4% przy 545 W i natychmiastowej luce 35 m.',
      type: ReplayClipType.gcAttack,
      startDistanceKm: 148.2,
      endDistanceKm: 148.8,
      startTimestampSeconds: 11840.0,
      endTimestampSeconds: 11891.0,
      frames: attackFrames,
    );

    // Klip 3: Ranty na bocznym wietrze (30 klatek)
    const int echelonFramesCount = 30;
    final echelonFrames = <ReplayFrameSnapshot>[];
    for (int f = 0; f < echelonFramesCount; f++) {
      final tNorm = f / (echelonFramesCount - 1);
      final leadDist = 112000.0 + tNorm * 550.0;
      final riders = List.generate(riderCount, (i) {
        final meta = ridersMeta[i];
        final echelonGroup = i < 24 ? 0 : (i < 85 ? 1 : 2);
        final groupGap = echelonGroup * 18.0;
        final lateral = ((i % 8) * 0.72 - 2.6).clamp(-3.3, 3.3);
        return ReplayRiderState(
          riderId: meta.id,
          bibNumber: meta.bib,
          riderName: meta.name,
          teamId: meta.teamId,
          teamJerseyHexColor: meta.hex,
          isPlayerRider: meta.isPlayer,
          distanceCoveredMeters: leadDist - i * 0.55 - groupGap,
          lateralOffsetRoadMeters: lateral,
          elevationMeters: 42.0,
          speedMs: (54.0 - echelonGroup * 3.5) / 3.6,
          speedKmh: 54.0 - echelonGroup * 3.5,
          powerWatts: echelonGroup == 0 ? 445 : 380,
          cadenceRpm: 98,
          heartRateBpm: 181,
          isSprinting: false,
          isBikeThrow: false,
          isDrafting: i > 0 && (i % 8) != 0,
          isCrashed: false,
          hasDefect: false,
        );
      });

      echelonFrames.add(ReplayFrameSnapshot(
        frameIndex: f,
        timestampSeconds: 8410.0 + f * 1.2,
        leadKilometerMark: leadDist / 1000.0,
        distanceToFinishKm: 67.0 - tNorm * 0.55,
        currentGradientPercent: 0.2,
        currentElevationMeters: 42.0,
        leadRiderName: ridersMeta[4].name,
        activeMomentTag: 'Wachlarz na bocznym wietrze 42 km/h',
        riders: riders,
      ));
    }

    final clipEchelon = ReplayClip(
      id: 'clip_attack_echelon',
      title: 'Ranty w Bocznej Wichurze • Podział Peletonu',
      description: '24 kolarzy w pierwszym wachlarzu wykorzystuje osłonę przed wiatrem z lewej.',
      type: ReplayClipType.echelonAttack,
      startDistanceKm: 112.0,
      endDistanceKm: 112.6,
      startTimestampSeconds: 8410.0,
      endTimestampSeconds: 8444.8,
      frames: echelonFrames,
    );

    // Wypełniamy także StageReplayRecorder poprzez clipy demonstracyjne używane przez ekran
    _cachedDemoClips[recorder] = [clipFinish, clipGcAttack, clipEchelon];
    return recorder;
  }

  static final Expando<List<ReplayClip>> _cachedDemoClips = Expando<List<ReplayClip>>();

  static List<ReplayClip> extractClips(StageReplayRecorder recorder) {
    final clips = <ReplayClip>[];
    final finalKm = recorder.buildFinalKilometerClip();
    if (finalKm != null && finalKm.frames.isNotEmpty) {
      clips.add(finalKm);
    }
    clips.addAll(recorder.highlightClips.where((c) => c.frames.isNotEmpty));

    final demo = _cachedDemoClips[recorder];
    if (clips.isEmpty && demo != null) {
      clips.addAll(demo);
    }
    return clips;
  }
}

// ============================================================================
// 3. SILNIK RENDEROWANIA KINA POWTÓREK + AERO VISION (CUSTOM PAINTER)
// ============================================================================

/// Rzutuje kolarzy z bieżącej klatki [ReplayFrameSnapshot] w wybranym trybie kamery
/// [RaceCameraMode] oraz rysuje strugi powietrza Aero Vision.
class ReplayTheaterViewportPainter extends CustomPainter {
  final ReplayFrameSnapshot? frame;
  final RaceCameraMode cameraMode;
  final String? focusedRiderId;
  final bool aeroVisionEnabled;
  final double aeroFlowPhase;
  final ReplayClipType clipType;

  const ReplayTheaterViewportPainter({
    required this.frame,
    required this.cameraMode,
    required this.focusedRiderId,
    required this.aeroVisionEnabled,
    required this.aeroFlowPhase,
    required this.clipType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Tło nieba i horyzontu
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0B0E14),
          Color(0xFF141923),
          Color(0xFF1A202C),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    final currentFrame = frame;
    if (currentFrame == null || currentFrame.riders.isEmpty) {
      return;
    }

    final horizonY = cameraMode == RaceCameraMode.heliCam
        ? size.height * 0.14
        : size.height * 0.28;

    // Pasmo górskie na horyzoncie
    final mountainPath = Path()..moveTo(0, horizonY);
    for (int i = 0; i <= 8; i++) {
      final x = (i / 8) * size.width;
      final peak = (i % 2 == 0) ? 18.0 : 42.0;
      mountainPath.lineTo(x, horizonY - peak);
    }
    mountainPath
      ..lineTo(size.width, horizonY + 12)
      ..lineTo(0, horizonY + 12)
      ..close();
    canvas.drawPath(
      mountainPath,
      Paint()..color = const Color(0xFF1F2633).withValues(alpha: 0.75),
    );

    // 2. Wstęga asfaltu w perspektywie
    final roadTopHalfW = cameraMode == RaceCameraMode.heliCam
        ? size.width * 0.22
        : size.width * 0.08;
    final roadBottomHalfW = cameraMode == RaceCameraMode.heliCam
        ? size.width * 0.44
        : size.width * 0.48;
    final centerX = size.width * 0.5;

    final roadPath = Path()
      ..moveTo(centerX - roadTopHalfW, horizonY)
      ..lineTo(centerX + roadTopHalfW, horizonY)
      ..lineTo(centerX + roadBottomHalfW, size.height)
      ..lineTo(centerX - roadBottomHalfW, size.height)
      ..close();

    canvas.drawPath(roadPath, Paint()..color = const Color(0xFF1D222B));

    // Krawędzie jezdni i przerywana linia osi
    final edgePaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(centerX - roadTopHalfW, horizonY),
      Offset(centerX - roadBottomHalfW, size.height),
      edgePaint,
    );
    canvas.drawLine(
      Offset(centerX + roadTopHalfW, horizonY),
      Offset(centerX + roadBottomHalfW, size.height),
      edgePaint,
    );

    final dashPaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.28)
      ..strokeWidth = 1.5;
    for (int d = 0; d < 10; d++) {
      final t1 = d / 10.0;
      final t2 = (d + 0.45) / 10.0;
      final y1 = horizonY + (size.height - horizonY) * t1;
      final y2 = horizonY + (size.height - horizonY) * t2;
      canvas.drawLine(Offset(centerX, y1), Offset(centerX, y2), dashPaint);
    }

    // 3. Wyznaczenie punktu odniesienia kamery na wybranym kolarzu
    final sorted = List<ReplayRiderState>.from(currentFrame.riders)
      ..sort((a, b) => b.distanceCoveredMeters.compareTo(a.distanceCoveredMeters));
    final focusRider = currentFrame.getRider(focusedRiderId ?? '') ?? sorted.first;
    final focusDist = focusRider.distanceCoveredMeters;

    // 4. Rzutowanie widocznych kolarzy z 176-osobowego peletonu
    final projected = <_ProjectedReplayRider>[];
    for (int idx = 0; idx < sorted.length; idx++) {
      final r = sorted[idx];
      final relDist = r.distanceCoveredMeters - focusDist;

      // Zakres widoczności kamery (w metrach wzdłuż trasy)
      double normalizedDepth;
      switch (cameraMode) {
        case RaceCameraMode.chaseCam:
          // Fokus u dołu ekranu (0.72), rywale przed nim (do +65m) i tuż za (-12m)
          if (relDist < -12.0 || relDist > 68.0) continue;
          normalizedDepth = 1.0 - ((relDist + 12.0) / 80.0);
          break;
        case RaceCameraMode.motoTvCam:
          // Kamera jedzie przed kolarzem: im dalej przed fokusem, tym bliżej dołu lub odwrotnie
          if (relDist < -48.0 || relDist > 24.0) continue;
          normalizedDepth = ((relDist + 48.0) / 72.0);
          break;
        case RaceCameraMode.heliCam:
          // Szeroki widok z góry na cały peleton (-95m do +55m)
          if (relDist < -95.0 || relDist > 55.0) continue;
          normalizedDepth = 1.0 - ((relDist + 95.0) / 150.0);
          break;
        case RaceCameraMode.finishLineCam:
          // Teleobiektyw z bramy mety: pokazuje czoło grupy (-75m do +35m)
          if (relDist < -75.0 || relDist > 35.0) continue;
          normalizedDepth = ((relDist + 75.0) / 110.0);
          break;
      }

      final clampedDepth = normalizedDepth.clamp(0.05, 0.96);
      final perspectiveT = math.pow(clampedDepth, 1.15).toDouble();
      final y = horizonY + (size.height - horizonY) * perspectiveT;
      final roadHalfAtY =
          roadTopHalfW + (roadBottomHalfW - roadTopHalfW) * perspectiveT;
      final lateralRatio = (r.lateralOffsetRoadMeters / 3.6).clamp(-1.0, 1.0);
      final x = centerX + lateralRatio * roadHalfAtY * 0.85;
      final scale = 0.45 + perspectiveT * 0.95;

      projected.add(_ProjectedReplayRider(
        rider: r,
        rank: idx + 1,
        position: Offset(x, y),
        scale: scale,
        isFocused: r.riderId == focusRider.riderId,
      ));
    }

    // Sortowanie od najdalszych (najmniejsze Y) do najbliższych
    projected.sort((a, b) => a.position.dy.compareTo(b.position.dy));

    // 5. Nakładka AERO VISION (stożki cienia aerodynamicznego, strefy oporu i strugi)
    if (aeroVisionEnabled) {
      final isCrosswind = clipType == ReplayClipType.echelonAttack;
      final windDeflectionX = isCrosswind ? 28.0 : 0.0;

      for (final p in projected) {
        final r = p.rider;
        final coneLen = (32.0 + r.speedKmh * 0.45) * p.scale;
        final coneW = 14.0 * p.scale;

        // Zielony stożek cienia aerodynamicznego za kolarzem
        final wakePath = Path()
          ..moveTo(p.position.dx - coneW * 0.4, p.position.dy)
          ..lineTo(p.position.dx + coneW * 0.4, p.position.dy)
          ..lineTo(p.position.dx + coneW * 1.1 + windDeflectionX * p.scale,
              p.position.dy + coneLen)
          ..lineTo(p.position.dx - coneW * 1.1 + windDeflectionX * p.scale,
              p.position.dy + coneLen)
          ..close();

        canvas.drawPath(
          wakePath,
          Paint()
            ..color = (r.isDrafting ? AppColors.statusSuccess : AppColors.cyanAccent)
                .withValues(alpha: p.isFocused ? 0.34 : 0.16),
        );

        // Czerwona strefa wystawienia na wiatr dla kolarzy poza cieniem
        if (!r.isDrafting) {
          canvas.drawCircle(
            Offset(p.position.dx, p.position.dy - 4 * p.scale),
            11.0 * p.scale,
            Paint()
              ..color = AppColors.crimsonAlert.withValues(alpha: 0.25)
              ..style = PaintingStyle.fill,
          );
        }

        // Animowane linie prądu powietrza wokół fokusa i czołówki
        if (p.isFocused || p.rank <= 6) {
          final streamPaint = Paint()
            ..color = AppColors.cyanAccent.withValues(alpha: p.isFocused ? 0.85 : 0.42)
            ..strokeWidth = p.isFocused ? 1.8 : 1.0
            ..style = PaintingStyle.stroke;

          for (int s = -1; s <= 1; s += 2) {
            final startX = p.position.dx + s * 7.0 * p.scale;
            final startY = p.position.dy - 14.0 * p.scale;
            final endY = p.position.dy + coneLen * 0.85;
            final wave = math.sin(aeroFlowPhase * 2 * math.pi + s) * 3.0 * p.scale;
            final streamPath = Path()
              ..moveTo(startX, startY)
              ..quadraticBezierTo(
                startX + s * 6.0 * p.scale + wave,
                (startY + endY) * 0.5,
                startX + windDeflectionX * 0.6 * p.scale,
                endY,
              );
            canvas.drawPath(streamPath, streamPaint);
          }
        }
      }

      // Kompas Aero Vision w prawym górnym rogu viewportu
      _drawAeroCompass(canvas, size, isCrosswind);
    }

    // 6. Rysowanie sylwetek kolarzy
    for (final p in projected) {
      final r = p.rider;
      final jerseyColor = _parseHexColor(r.teamJerseyHexColor);

      if (p.isFocused) {
        // Złoty pierścień wyboru kamery
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(p.position.dx, p.position.dy + 3 * p.scale),
            width: 28 * p.scale,
            height: 11 * p.scale,
          ),
          Paint()
            ..color = AppColors.goldAccent.withValues(alpha: 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      }

      // Cień na asfalcie
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(p.position.dx, p.position.dy + 2 * p.scale),
          width: 14 * p.scale,
          height: 6 * p.scale,
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.45),
      );

      // Koło i sylwetka
      final bodyRadius = (p.isFocused ? 6.5 : 5.0) * p.scale;
      canvas.drawCircle(
        Offset(p.position.dx, p.position.dy - 5 * p.scale),
        bodyRadius,
        Paint()..color = jerseyColor,
      );

      // Kask
      canvas.drawCircle(
        Offset(p.position.dx, p.position.dy - 11 * p.scale),
        bodyRadius * 0.62,
        Paint()
          ..color = r.isPlayerRider ? AppColors.goldAccent : AppColors.textPrimary,
      );

      // Etykieta nad fokusem lub sprinterem / atakującym
      if (p.isFocused || (p.rank <= 3 && p.scale > 0.72)) {
        final labelText = '#${r.bibNumber} ${r.riderName} (${r.powerWatts}W)';
        final textPainter = TextPainter(
          text: TextSpan(
            text: labelText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: (p.isFocused ? 11.0 : 9.5),
              fontWeight: p.isFocused ? FontWeight.w700 : FontWeight.w600,
              color: p.isFocused ? AppColors.goldAccent : AppColors.textPrimary,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final tagRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(p.position.dx, p.position.dy - 24 * p.scale),
            width: textPainter.width + 12,
            height: 18,
          ),
          const Radius.circular(6),
        );
        canvas.drawRRect(
          tagRect,
          Paint()
            ..color = AppColors.background.withValues(alpha: 0.85),
        );
        canvas.drawRRect(
          tagRect,
          Paint()
            ..color = p.isFocused ? AppColors.goldAccent : AppColors.cardBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
        textPainter.paint(
          canvas,
          Offset(tagRect.left + 6, tagRect.top + 2),
        );
      }
    }
  }

  void _drawAeroCompass(Canvas canvas, Size size, bool isCrosswind) {
    final center = Offset(size.width - 44, 44);
    canvas.drawCircle(
      center,
      24,
      Paint()..color = AppColors.background.withValues(alpha: 0.82),
    );
    canvas.drawCircle(
      center,
      24,
      Paint()
        ..color = AppColors.cyanAccent.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final angle = isCrosswind ? -math.pi * 0.35 : -math.pi * 0.5;
    final tip = Offset(
      center.dx + math.cos(angle) * 14,
      center.dy + math.sin(angle) * 14,
    );
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = AppColors.cyanAccent
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: isCrosswind ? 'RANT' : 'AERO',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: AppColors.cyanAccent,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + 6));
  }

  static Color _parseHexColor(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      final value = int.tryParse('FF$clean', radix: 16);
      if (value != null) return Color(value);
    }
    return AppColors.accentBlue;
  }

  @override
  bool shouldRepaint(covariant ReplayTheaterViewportPainter oldDelegate) {
    return oldDelegate.frame != frame ||
        oldDelegate.cameraMode != cameraMode ||
        oldDelegate.focusedRiderId != focusedRiderId ||
        oldDelegate.aeroVisionEnabled != aeroVisionEnabled ||
        oldDelegate.aeroFlowPhase != aeroFlowPhase ||
        oldDelegate.clipType != clipType;
  }
}

class _ProjectedReplayRider {
  final ReplayRiderState rider;
  final int rank;
  final Offset position;
  final double scale;
  final bool isFocused;

  const _ProjectedReplayRider({
    required this.rider,
    required this.rank,
    required this.position,
    required this.scale,
    required this.isFocused,
  });
}

// ============================================================================
// 4. GŁÓWNY EKRAN KINA POWTÓREK (RACE REPLAY DIRECTOR THEATER SCREEN)
// ============================================================================

/// Kino Powtórek Wyścigowych pozwalające odtwarzać zapisane finisze i kluczowe momenty
/// z [StageReplayRecorder], przewijać klatka po klatce, przełączać kamery na dowolnego
/// z 176 kolarzy, włączać widok strug powietrza `Aero Vision` i analizować przyczyny sukcesu.
class RaceReplayDirectorTheaterScreen extends StatefulWidget {
  final StageReplayRecorder? recorder;
  final ReplayClip? initialClip;
  final String? initialFocusedRiderId;
  final VoidCallback? onClose;

  const RaceReplayDirectorTheaterScreen({
    super.key,
    this.recorder,
    this.initialClip,
    this.initialFocusedRiderId,
    this.onClose,
  });

  @override
  State<RaceReplayDirectorTheaterScreen> createState() =>
      _RaceReplayDirectorTheaterScreenState();
}

enum _RiderFilterMode { all, playerTeam, top15 }

class _RaceReplayDirectorTheaterScreenState
    extends State<RaceReplayDirectorTheaterScreen>
    with SingleTickerProviderStateMixin {
  late StageReplayRecorder _activeRecorder;
  late List<ReplayClip> _availableClips;
  ReplayClip? _selectedClip;
  StageReplayPlayer? _player;

  bool _aeroVisionEnabled = true;
  WindStreamlinesConfig _aeroConfig =
      const WindStreamlinesConfig(aeroVisionActive: true);
  _RiderFilterMode _riderFilterMode = _RiderFilterMode.all;
  String _riderSearchQuery = '';
  int _mobileTabIndex = 0;

  late final AnimationController _playbackTicker;
  late final TextEditingController _searchController;
  DateTime _lastTickTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _playbackTicker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(_onAnimationTick);

    _initializeFromWidget();
  }

  @override
  void didUpdateWidget(covariant RaceReplayDirectorTheaterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recorder != widget.recorder ||
        oldWidget.initialClip != widget.initialClip) {
      _initializeFromWidget();
    }
  }

  void _initializeFromWidget() {
    _activeRecorder =
        widget.recorder ?? ReplayTheaterSampleBuilder.createDemoRecorder();
    _availableClips = ReplayTheaterSampleBuilder.extractClips(_activeRecorder);

    if (widget.initialClip != null && !widget.initialClip!.isEmpty) {
      final exists = _availableClips.any((c) => c.id == widget.initialClip!.id);
      if (!exists) {
        _availableClips = [widget.initialClip!, ..._availableClips];
      }
      _selectClip(widget.initialClip!);
    } else if (_availableClips.isNotEmpty) {
      _selectClip(_availableClips.first);
    } else {
      _selectedClip = null;
      _player = null;
    }
  }

  void _selectClip(ReplayClip clip) {
    _playbackTicker.stop();
    final firstRiderId = widget.initialFocusedRiderId ??
        (clip.frames.isNotEmpty && clip.frames.first.riders.isNotEmpty
            ? clip.frames.first.riders.first.riderId
            : null);

    setState(() {
      _selectedClip = clip;
      _player = StageReplayPlayer(
        clip: clip,
        initialCameraMode: clip.type == ReplayClipType.echelonAttack
            ? RaceCameraMode.heliCam
            : RaceCameraMode.chaseCam,
        initialFocusedRiderId: firstRiderId,
      );
      _aeroConfig = _aeroConfig.copyWith(aeroVisionActive: _aeroVisionEnabled);
    });
  }

  void _loadDemoSample() {
    final demo = ReplayTheaterSampleBuilder.createDemoRecorder();
    setState(() {
      _activeRecorder = demo;
      _availableClips = ReplayTheaterSampleBuilder.extractClips(demo);
    });
    if (_availableClips.isNotEmpty) {
      _selectClip(_availableClips.first);
    }
  }

  void _onAnimationTick() {
    final player = _player;
    if (player == null || !player.isPlaying) return;

    final now = DateTime.now();
    final dt = now.difference(_lastTickTime).inMilliseconds / 1000.0;
    _lastTickTime = now;

    if (dt <= 0) return;
    final prevFrame = player.currentFrameIndex;
    player.tick(dt.clamp(0.008, 0.08));

    if (!player.isPlaying) {
      _playbackTicker.stop();
    }
    if (mounted && (prevFrame != player.currentFrameIndex || !player.isPlaying)) {
      setState(() {});
    }
  }

  void _togglePlayPause() {
    final player = _player;
    if (player == null || player.clip.frames.isEmpty) return;

    setState(() {
      if (player.isPlaying) {
        player.pause();
        _playbackTicker.stop();
      } else {
        if (player.currentFrameIndex >= player.clip.frames.length - 1) {
          player.seekToFrame(0);
        }
        _lastTickTime = DateTime.now();
        player.play();
        _playbackTicker.repeat();
      }
    });
  }

  void _stepBackward() {
    final player = _player;
    if (player == null) return;
    _playbackTicker.stop();
    setState(() {
      player.pause();
      player.stepBackward();
    });
  }

  void _stepForward() {
    final player = _player;
    if (player == null) return;
    _playbackTicker.stop();
    setState(() {
      player.pause();
      player.stepForward();
    });
  }

  void _seekToFrame(int frameIndex) {
    final player = _player;
    if (player == null) return;
    setState(() {
      player.seekToFrame(frameIndex);
    });
  }

  void _setPlaybackSpeed(double speed) {
    final player = _player;
    if (player == null) return;
    setState(() {
      player.setPlaybackSpeed(speed);
    });
  }

  void _setCameraMode(RaceCameraMode mode) {
    final player = _player;
    if (player == null) return;
    setState(() {
      player.setCameraMode(mode);
    });
  }

  void _setFocusedRider(String riderId) {
    final player = _player;
    if (player == null) return;
    setState(() {
      player.setFocusedRider(riderId);
    });
  }

  void _toggleAeroVision() {
    setState(() {
      _aeroVisionEnabled = !_aeroVisionEnabled;
      _aeroConfig = _aeroConfig.copyWith(aeroVisionActive: _aeroVisionEnabled);
    });
  }

  @override
  void dispose() {
    _playbackTicker.removeListener(_onAnimationTick);
    _playbackTicker.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Focus(
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isDesktop = width >= 1220;
              final isTablet = width >= 760 && width < 1220;

              return Column(
                children: [
                  _buildTopDirectorBar(isCompact: !isDesktop),
                  Expanded(
                    child: _selectedClip == null || _player == null
                        ? _buildEmptyState()
                        : isDesktop
                            ? _buildDesktopLayout()
                            : isTablet
                                ? _buildTabletLayout()
                                : _buildMobileLayout(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.space) {
      _togglePlayPause();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _stepBackward();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _stepForward();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyA) {
      _toggleAeroVision();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ==========================================================================
  // GÓRNY PASEK REŻYSERA (TOP DIRECTOR BAR)
  // ==========================================================================

  Widget _buildTopDirectorBar({required bool isCompact}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isCompact ? 330 : 560),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
              if (widget.onClose != null) ...[
                _TheaterIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Zamknij kino powtórek',
                  onPressed: widget.onClose,
                ),
                const SizedBox(width: 10),
              ],
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryAccent),
                ),
                child: const Icon(
                  Icons.movie_filter_rounded,
                  color: AppColors.goldAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'KINO POWTÓREK REŻYSERSKICH',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _activeRecorder.stageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _AeroVisionToggleChip(
                enabled: _aeroVisionEnabled,
                isInteractive: _player != null,
                onTap: _toggleAeroVision,
              ),
              if (!isCompact && _player != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    'Kolarzy w klatce: ${_player!.currentFrame?.riders.length ?? 0}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // UKŁADY RESPONSYWNE (1600x900 DESKTOP / 1024x768 TABLET / 390x844 MOBILE)
  // ==========================================================================

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 310,
            child: _buildClipAndRiderSwitcherPanel(),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(child: _buildViewportCard()),
                const SizedBox(height: 12),
                _buildTransportAndCameraBar(),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 350,
            child: _buildAnalysisAndTelemetryPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              children: [
                Expanded(child: _buildViewportCard()),
                const SizedBox(height: 10),
                _buildTransportAndCameraBar(),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 340,
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  _buildCompactTabSelector(const ['Klipy i 176 Kolarzy', 'Analiza Sukcesu']),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildClipAndRiderSwitcherPanel(),
                        _buildAnalysisAndTelemetryPanel(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: _buildViewportCard(),
          ),
          const SizedBox(height: 8),
          _buildTransportAndCameraBar(compact: true),
          const SizedBox(height: 8),
          Row(
            children: [
              _MobileSectionPill(
                label: 'Klipy & Kolarze',
                selected: _mobileTabIndex == 0,
                onTap: () => setState(() => _mobileTabIndex = 0),
              ),
              const SizedBox(width: 8),
              _MobileSectionPill(
                label: 'Analiza Sukcesu',
                selected: _mobileTabIndex == 1,
                onTap: () => setState(() => _mobileTabIndex = 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 440,
            child: _mobileTabIndex == 0
                ? _buildClipAndRiderSwitcherPanel()
                : _buildAnalysisAndTelemetryPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTabSelector(List<String> labels) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.primaryAccent,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        tabs: labels.map((l) => Tab(height: 36, text: l)).toList(),
      ),
    );
  }

  // ==========================================================================
  // LEWY PANEL: WYBÓR KLIPÓW ORAZ KAMERA NA DOWOLNEGO ZE 176 KOLARZY
  // ==========================================================================

  Widget _buildClipAndRiderSwitcherPanel() {
    final currentFrame = _player?.currentFrame;
    final allRiders = List<ReplayRiderState>.from(currentFrame?.riders ?? const [])
      ..sort((a, b) => b.distanceCoveredMeters.compareTo(a.distanceCoveredMeters));

    final query = _riderSearchQuery.trim().toLowerCase();
    final filteredRiders = allRiders.where((r) {
      if (_riderFilterMode == _RiderFilterMode.playerTeam && !r.isPlayerRider) {
        return false;
      }
      if (_riderFilterMode == _RiderFilterMode.top15) {
        final rank = allRiders.indexOf(r);
        if (rank >= 15) return false;
      }
      if (query.isEmpty) return true;
      return r.riderName.toLowerCase().contains(query) ||
          r.teamId.toLowerCase().contains(query) ||
          r.bibNumber.toString().contains(query);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                const Icon(Icons.video_library_rounded,
                    size: 16, color: AppColors.goldAccent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ZAPISANE KLIPY ETAPU',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '${_availableClips.length}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 118,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _availableClips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final clip = _availableClips[index];
                final isSelected = _selectedClip?.id == clip.id;
                return _ClipSelectorTile(
                  clip: clip,
                  selected: isSelected,
                  onTap: () => _selectClip(clip),
                );
              },
            ),
          ),
          const Divider(color: AppColors.cardBorder, height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.videocam_rounded,
                    size: 16, color: AppColors.accentBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'KAMERA NA KOLARZA (${allRiders.length})',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _riderSearchQuery = v),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Szukaj nazwiska, numeru lub drużyny...',
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 16, color: AppColors.textSecondary),
                suffixIcon: _riderSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 15),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _riderSearchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.goldAccent),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 6,
              children: [
                _FilterChipPill(
                  label: 'Wszyscy (${allRiders.length})',
                  selected: _riderFilterMode == _RiderFilterMode.all,
                  onTap: () =>
                      setState(() => _riderFilterMode = _RiderFilterMode.all),
                ),
                _FilterChipPill(
                  label: 'Moja Ekipa',
                  selected: _riderFilterMode == _RiderFilterMode.playerTeam,
                  onTap: () => setState(
                      () => _riderFilterMode = _RiderFilterMode.playerTeam),
                ),
                _FilterChipPill(
                  label: 'Top 15',
                  selected: _riderFilterMode == _RiderFilterMode.top15,
                  onTap: () =>
                      setState(() => _riderFilterMode = _RiderFilterMode.top15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredRiders.isEmpty
                ? const Center(
                    child: Text(
                      'Brak kolarzy spełniających filtr.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: filteredRiders.length,
                    itemBuilder: (context, idx) {
                      final rider = filteredRiders[idx];
                      final rank = allRiders.indexOf(rider) + 1;
                      final isFocused =
                          _player?.focusedRiderId == rider.riderId;
                      return _RiderCameraRow(
                        rider: rider,
                        rank: rank,
                        selected: isFocused,
                        onTap: () => _setFocusedRider(rider.riderId),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ŚRODKOWY VIEWPORT 3D + AERO VISION + PASEK STEROWANIA KLATKAMI
  // ==========================================================================

  Widget _buildViewportCard() {
    final player = _player!;
    final frame = player.currentFrame;
    final focusedRider = frame?.getRider(player.focusedRiderId ?? '') ??
        (frame != null && frame.riders.isNotEmpty ? frame.riders.first : null);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _aeroVisionEnabled
              ? AppColors.cyanAccent.withValues(alpha: 0.55)
              : AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: ReplayTheaterViewportPainter(
                  frame: frame,
                  cameraMode: player.cameraMode,
                  focusedRiderId: player.focusedRiderId,
                  aeroVisionEnabled: _aeroVisionEnabled,
                  aeroFlowPhase: _playbackTicker.value,
                  clipType: player.clip.type,
                ),
              ),
            ),
            // Górny HUD ujęcia kamery
            Positioned(
              top: 10,
              left: 12,
              right: 76,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _HudBadge(
                    icon: Icons.camera_alt_rounded,
                    label: player.cameraMode.shortLabel,
                    accentColor: AppColors.goldAccent,
                  ),
                  if (frame?.activeMomentTag != null)
                    _HudBadge(
                      icon: Icons.bolt_rounded,
                      label: frame!.activeMomentTag!,
                      accentColor: AppColors.primaryAccent,
                    ),
                  if (_aeroVisionEnabled)
                    _HudBadge(
                      icon: Icons.air_rounded,
                      label: _aeroConfig.aeroVisionActive
                          ? 'AERO VISION ON'
                          : 'AERO OFF',
                      accentColor: AppColors.cyanAccent,
                    ),
                ],
              ),
            ),
            // Dolny pasek telemetrii wybranego kolarza
            if (focusedRider != null && frame != null)
              Positioned(
                bottom: 10,
                left: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '#${focusedRider.bibNumber} ${focusedRider.riderName}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.goldAccent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            focusedRider.teamId,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 12,
                        children: [
                          _MiniStat(
                              label: 'MOC',
                              value: '${focusedRider.powerWatts} W',
                              color: AppColors.cyanAccent),
                          _MiniStat(
                              label: 'PRĘD.',
                              value:
                                  '${focusedRider.speedKmh.toStringAsFixed(1)} km/h',
                              color: AppColors.textPrimary),
                          _MiniStat(
                              label: 'KAD.',
                              value: '${focusedRider.cadenceRpm} RPM',
                              color: AppColors.textSecondary),
                          _MiniStat(
                              label: 'AERO',
                              value:
                                  focusedRider.isDrafting ? 'W CIENIU' : 'NA WIETRZE',
                              color: focusedRider.isDrafting
                                  ? AppColors.statusSuccess
                                  : AppColors.crimsonAlert),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportAndCameraBar({bool compact = false}) {
    final player = _player!;
    final totalFrames = player.clip.frames.length;
    final currentIdx = player.currentFrameIndex;
    final currentFrame = player.currentFrame;
    final maxIdx = math.max(1, totalFrames - 1);

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'KLATKA ${currentIdx + 1} / $totalFrames',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.goldAccent,
                ),
              ),
              const SizedBox(width: 10),
              if (currentFrame != null)
                Expanded(
                  child: Text(
                    '${currentFrame.distanceToFinishKm.toStringAsFixed(2)} km do mety • ${currentFrame.currentGradientPercent.toStringAsFixed(1)}%',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.goldAccent,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.goldAccent,
              overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              min: 0,
              max: maxIdx.toDouble(),
              divisions: maxIdx > 0 ? maxIdx : null,
              value: currentIdx.clamp(0, maxIdx).toDouble(),
              onChanged: totalFrames > 1
                  ? (val) => _seekToFrame(val.round())
                  : null,
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Przyciski transportu klatka po klatce
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TheaterIconButton(
                    icon: Icons.first_page_rounded,
                    tooltip: 'Początek klipu',
                    onPressed: currentIdx > 0 ? () => _seekToFrame(0) : null,
                  ),
                  const SizedBox(width: 4),
                  _TheaterIconButton(
                    icon: Icons.skip_previous_rounded,
                    tooltip: 'Poprzednia klatka (-1)',
                    onPressed: currentIdx > 0 ? _stepBackward : null,
                  ),
                  const SizedBox(width: 6),
                  _PlayPauseButton(
                    isPlaying: player.isPlaying,
                    enabled: totalFrames > 1,
                    onPressed: _togglePlayPause,
                  ),
                  const SizedBox(width: 6),
                  _TheaterIconButton(
                    icon: Icons.skip_next_rounded,
                    tooltip: 'Następna klatka (+1)',
                    onPressed: currentIdx < totalFrames - 1 ? _stepForward : null,
                  ),
                  const SizedBox(width: 4),
                  _TheaterIconButton(
                    icon: Icons.last_page_rounded,
                    tooltip: 'Koniec klipu',
                    onPressed: currentIdx < totalFrames - 1
                        ? () => _seekToFrame(totalFrames - 1)
                        : null,
                  ),
                ],
              ),
              // Prędkość odtwarzania
              Wrap(
                spacing: 4,
                children: [0.25, 0.5, 1.0, 2.0].map((spd) {
                  final active = (player.playbackSpeed - spd).abs() < 0.01;
                  return _FilterChipPill(
                    label: '${spd}x',
                    selected: active,
                    onTap: () => _setPlaybackSpeed(spd),
                  );
                }).toList(),
              ),
              // Przełącznik trybów kamery
              Wrap(
                spacing: 4,
                children: RaceCameraMode.values.map((mode) {
                  return _FilterChipPill(
                    label: mode.shortLabel,
                    selected: player.cameraMode == mode,
                    onTap: () => _setCameraMode(mode),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // PRAWY PANEL: ANALIZA DLACZEGO ATAK / SPRINT ZAKOŃCZYŁ SIĘ SUKCESEM
  // ==========================================================================

  Widget _buildAnalysisAndTelemetryPanel() {
    final player = _player!;
    final report = ReplayTacticalSuccessAnalyzer.analyze(
      clip: player.clip,
      currentFrameIndex: player.currentFrameIndex,
      focusedRiderId: player.focusedRiderId,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics_rounded,
                    size: 17, color: AppColors.goldAccent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ANALIZA SUKCESU TAKTYCZNEGO',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WERDYKT: #${report.winnerBibNumber} ${report.winnerRiderName}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.goldAccent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    report.headlineVerdict,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'SZCZYT MOCY',
                    value: '${report.winnerPeakPowerWatts} W',
                    subValue: 'Śr. grupy ${report.pelotonAvgPowerWatts} W',
                    accent: AppColors.cyanAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    label: 'SZCZYT PRĘDKOŚCI',
                    value: '${report.winnerPeakSpeedKmh.toStringAsFixed(1)} km/h',
                    subValue:
                        'Śr. grupy ${report.pelotonAvgSpeedKmh.toStringAsFixed(1)} km/h',
                    accent: AppColors.statusSuccess,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'DLACZEGO TEN MANEWR ZADZIAŁAŁ',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...report.factors.map((factor) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(factor.icon,
                                size: 15, color: factor.accentColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                factor.title,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    factor.accentColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                factor.metricBadge,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                  color: factor.accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          factor.detail,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            height: 1.35,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_rounded,
                size: 42, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Brak zapisanych powtórek etapu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Przekazany rejestr StageReplayRecorder nie zawiera jeszcze żadnego klipu finiszu ani ataku.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDemoSample,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
              label: const Text(
                'Wczytaj Pakiet Pokazowy (176 kolarzy)',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 5. KOMPONENTY INTERAKTYWNE Z PEŁNYMI STANAMI HOVER / ACTIVE / DISABLED / FOCUS
// ============================================================================

class _TheaterIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _TheaterIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_TheaterIconButton> createState() => _TheaterIconButtonState();
}

class _TheaterIconButtonState extends State<_TheaterIconButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: !enabled
                    ? AppColors.surfaceLight.withValues(alpha: 0.4)
                    : _hovered
                        ? AppColors.surfaceLight
                        : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _focused
                      ? AppColors.goldAccent
                      : !enabled
                          ? AppColors.cardBorder.withValues(alpha: 0.4)
                          : AppColors.cardBorder,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatefulWidget {
  final bool isPlaying;
  final bool enabled;
  final VoidCallback onPressed;

  const _PlayPauseButton({
    required this.isPlaying,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<_PlayPauseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.enabled ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: !widget.enabled
                  ? AppColors.surfaceLight
                  : _hovered
                      ? AppColors.goldAccent
                      : AppColors.primaryAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 20,
              color: !widget.enabled
                  ? AppColors.textSecondary
                  : _hovered
                      ? AppColors.background
                      : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AeroVisionToggleChip extends StatefulWidget {
  final bool enabled;
  final bool isInteractive;
  final VoidCallback onTap;

  const _AeroVisionToggleChip({
    required this.enabled,
    required this.isInteractive,
    required this.onTap,
  });

  @override
  State<_AeroVisionToggleChip> createState() => _AeroVisionToggleChipState();
}

class _AeroVisionToggleChipState extends State<_AeroVisionToggleChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.isInteractive,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isInteractive ? widget.onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: widget.enabled
                  ? AppColors.cyanAccent.withValues(alpha: _hovered ? 0.25 : 0.16)
                  : _hovered
                      ? AppColors.surfaceLight
                      : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : widget.enabled
                        ? AppColors.cyanAccent
                        : AppColors.cardBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.air_rounded,
                  size: 16,
                  color: widget.enabled
                      ? AppColors.cyanAccent
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.enabled ? 'Aero Vision: WŁ.' : 'Aero Vision: WYŁ.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.enabled
                        ? AppColors.cyanAccent
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChipPill extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_FilterChipPill> createState() => _FilterChipPillState();
}

class _FilterChipPillState extends State<_FilterChipPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.primaryAccent
                  : _hovered
                      ? AppColors.surfaceLight
                      : AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.selected
                    ? AppColors.goldAccent
                    : AppColors.cardBorder,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w600,
                color: widget.selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClipSelectorTile extends StatefulWidget {
  final ReplayClip clip;
  final bool selected;
  final VoidCallback onTap;

  const _ClipSelectorTile({
    required this.clip,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ClipSelectorTile> createState() => _ClipSelectorTileState();
}

class _ClipSelectorTileState extends State<_ClipSelectorTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.primaryAccent.withValues(alpha: 0.25)
                  : _hovered
                      ? AppColors.surfaceLight
                      : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.selected
                    ? AppColors.goldAccent
                    : AppColors.cardBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.clip.type == ReplayClipType.finalKilometer
                      ? Icons.flag_rounded
                      : widget.clip.type == ReplayClipType.echelonAttack
                          ? Icons.air_rounded
                          : Icons.trending_up_rounded,
                  size: 16,
                  color: widget.selected
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.clip.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${widget.clip.frameCount} kl. • ${widget.clip.startDistanceKm.toStringAsFixed(1)}–${widget.clip.endDistanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RiderCameraRow extends StatefulWidget {
  final ReplayRiderState rider;
  final int rank;
  final bool selected;
  final VoidCallback onTap;

  const _RiderCameraRow({
    required this.rider,
    required this.rank,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_RiderCameraRow> createState() => _RiderCameraRowState();
}

class _RiderCameraRowState extends State<_RiderCameraRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: widget.selected
                    ? AppColors.goldAccent.withValues(alpha: 0.14)
                    : _hovered
                        ? AppColors.surfaceLight
                        : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.selected
                      ? AppColors.goldAccent
                      : AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${widget.rank}.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: widget.selected
                            ? AppColors.goldAccent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '#${widget.rider.bibNumber} ${widget.rider.riderName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight:
                            widget.selected ? FontWeight.w700 : FontWeight.w600,
                        color: widget.rider.isPlayerRider
                            ? AppColors.goldAccent
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.rider.powerWatts}W',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.cyanAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileSectionPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MobileSectionPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryAccent : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.goldAccent : AppColors.cardBorder,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HudBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;

  const _HudBadge({
    required this.icon,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accentColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color accent;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.subValue,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
