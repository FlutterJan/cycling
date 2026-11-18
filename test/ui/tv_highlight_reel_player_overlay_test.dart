// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/simulation/instant_highlight_clip_generator.dart';
import 'package:pro_peloton_manager/ui/widgets/tv_highlight_reel_player_overlay.dart';

InstantHighlightReel _buildSampleReel() {
  return InstantHighlightReel(
    reelId: 'reel_test_637',
    stageId: 'stage_tdp_7',
    raceName: 'Tour de Pologne',
    stageName: 'Karpacz Orlinek — Finał Górski',
    stageNumber: 7,
    stageDistanceKm: 162.4,
    stageTypeLabel: 'Etap górski',
    winnerName: 'Rafał Majka',
    winnerTeamName: 'Polonia Pro Cycling',
    gcLeaderName: 'Rafał Majka',
    broadcastNetworkName: 'TVP SPORT • WORLD FEED',
    totalDurationSeconds: 45.0,
    averageDramaScore: 88.0,
    generatedAt: DateTime(2026, 8, 12, 17, 30),
    segments: const [
      HighlightClipSegment(
        id: 'seg_1',
        orderIndex: 0,
        role: HighlightSegmentRole.coldOpen,
        cameraAngle: BroadcastCameraAngle.helicopter,
        transitionIn: HighlightTransitionType.whooshCut,
        title: 'Otwarcie transmisji pod Karpaczem',
        commentaryLine: 'Peleton wjeżdża na decydujące kilometry w Karkonoszach.',
        commentaryTag: 'INTRO',
        kilometerMark: 120.0,
        remainingKm: 42.4,
        stageTimestampSeconds: 10800.0,
        startTimelineSecond: 0.0,
        endTimelineSecond: 10.0,
        dramaScore: 72.0,
        gradientPercent: 4.5,
        lowerThird: HighlightTvLowerThird(
          primaryTitle: 'PELETON GŁÓWNY',
          secondarySubtitle: 'Tempo narzucone przez liderów klasyfikacji',
          badgeText: 'OPEN',
          riderSpeedKmh: 44.2,
          riderPowerWatts: 345,
          gradientPercent: 4.5,
        ),
      ),
      HighlightClipSegment(
        id: 'seg_2',
        orderIndex: 1,
        role: HighlightSegmentRole.tacticalTurningPoint,
        cameraAngle: BroadcastCameraAngle.motoLead,
        transitionIn: HighlightTransitionType.crossDissolve,
        title: 'Atak na podjeździe pod Orlinek',
        commentaryLine: 'Dynamiczne przyspieszenie na najstromszej ściance!',
        commentaryTag: 'ATAK',
        kilometerMark: 151.5,
        remainingKm: 10.9,
        stageTimestampSeconds: 13100.0,
        startTimelineSecond: 10.0,
        endTimelineSecond: 22.0,
        dramaScore: 86.0,
        gradientPercent: 9.2,
        lowerThird: HighlightTvLowerThird(
          primaryTitle: 'RAFAŁ MAJKA',
          secondarySubtitle: 'Polonia Pro Cycling • +0:18 przewagi',
          badgeText: 'ATAK',
          riderSpeedKmh: 26.8,
          riderPowerWatts: 468,
          gradientPercent: 9.2,
        ),
      ),
      HighlightClipSegment(
        id: 'seg_3',
        orderIndex: 2,
        role: HighlightSegmentRole.keyClimbOrSector,
        cameraAngle: BroadcastCameraAngle.droneTracking,
        transitionIn: HighlightTransitionType.wipeGoldBar,
        title: 'Walka w grupie pościgowej',
        commentaryLine: 'Rywale próbują utrzymać dystans poniżej dwudziestu sekund.',
        commentaryTag: 'POGOŃ',
        kilometerMark: 158.0,
        remainingKm: 4.4,
        stageTimestampSeconds: 13650.0,
        startTimelineSecond: 22.0,
        endTimelineSecond: 33.0,
        dramaScore: 91.0,
        gradientPercent: 10.4,
        lowerThird: HighlightTvLowerThird(
          primaryTitle: 'GRUPA POŚCIGOWA',
          secondarySubtitle: '4 kolarzy w walce o podium',
          badgeText: 'GC',
          riderSpeedKmh: 24.5,
          riderPowerWatts: 452,
          gradientPercent: 10.4,
        ),
      ),
      HighlightClipSegment(
        id: 'seg_4',
        orderIndex: 3,
        role: HighlightSegmentRole.finalSprintClimax,
        cameraAngle: BroadcastCameraAngle.finishLineOverhead,
        transitionIn: HighlightTransitionType.slamZoom,
        title: 'Zwycięski finisz na Orlinku',
        commentaryLine: 'Rafał Majka podnosi ręce w geście triumfu na mecie!',
        commentaryTag: 'META',
        kilometerMark: 162.4,
        remainingKm: 0.0,
        stageTimestampSeconds: 14120.0,
        startTimelineSecond: 33.0,
        endTimelineSecond: 45.0,
        dramaScore: 98.0,
        gradientPercent: 7.8,
        lowerThird: HighlightTvLowerThird(
          primaryTitle: 'ZWYCIĘZCA: RAFAŁ MAJKA',
          secondarySubtitle: 'Polonia Pro Cycling • Złota Koszulka Lidera',
          badgeText: 'FINISZ',
          riderSpeedKmh: 33.4,
          riderPowerWatts: 615,
          gradientPercent: 7.8,
        ),
      ),
    ],
    pacingCurve: const [
      BroadcastPacingCue(
        timelineSecond: 0.0,
        excitementLevel: 0.45,
        mood: BroadcastAudioCueMood.introSting,
      ),
      BroadcastPacingCue(
        timelineSecond: 15.0,
        excitementLevel: 0.72,
        mood: BroadcastAudioCueMood.tensionBuild,
      ),
      BroadcastPacingCue(
        timelineSecond: 35.0,
        excitementLevel: 0.96,
        mood: BroadcastAudioCueMood.climaxRoar,
      ),
      BroadcastPacingCue(
        timelineSecond: 45.0,
        excitementLevel: 0.85,
        mood: BroadcastAudioCueMood.podiumAnthem,
      ),
    ],
  );
}

Future<void> _pumpWithSize(
  WidgetTester tester,
  Size size,
  Widget child,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('TvHighlightTransitionCalculator', () {
    test('wykrywa aktywne przejścia dla wszystkich 4 typów w oknie 0.55s', () {
      final reel = _buildSampleReel();

      final t0 = TvHighlightTransitionCalculator.evaluateAtTimeline(
        reel: reel,
        timelineSeconds: 0.20,
      );
      expect(t0.isActive, isTrue);
      expect(t0.transitionType, HighlightTransitionType.whooshCut);
      expect(t0.incomingSegment?.id, 'seg_1');

      final t1 = TvHighlightTransitionCalculator.evaluateAtTimeline(
        reel: reel,
        timelineSeconds: 10.25,
      );
      expect(t1.isActive, isTrue);
      expect(t1.transitionType, HighlightTransitionType.crossDissolve);
      expect(t1.outgoingSegment?.id, 'seg_1');
      expect(t1.incomingSegment?.id, 'seg_2');

      final t2 = TvHighlightTransitionCalculator.evaluateAtTimeline(
        reel: reel,
        timelineSeconds: 22.30,
      );
      expect(t2.isActive, isTrue);
      expect(t2.transitionType, HighlightTransitionType.wipeGoldBar);

      final t3 = TvHighlightTransitionCalculator.evaluateAtTimeline(
        reel: reel,
        timelineSeconds: 33.40,
      );
      expect(t3.isActive, isTrue);
      expect(t3.transitionType, HighlightTransitionType.slamZoom);

      final idle = TvHighlightTransitionCalculator.evaluateAtTimeline(
        reel: reel,
        timelineSeconds: 15.0,
      );
      expect(idle.isActive, isFalse);
    });

    test('formatuje czas i interpoluje krzywą napięcia', () {
      final reel = _buildSampleReel();
      expect(TvHighlightTransitionCalculator.formatTimestamp(0), '00:00');
      expect(TvHighlightTransitionCalculator.formatTimestamp(45), '00:45');
      expect(
        TvHighlightTransitionCalculator.segmentIndexAt(
          reel: reel,
          timelineSeconds: 25.0,
        ),
        2,
      );
      final midExcitement = TvHighlightTransitionCalculator.excitementAt(
        reel: reel,
        timelineSeconds: 25.0,
      );
      expect(midExcitement, greaterThan(0.75));
      expect(midExcitement, lessThan(0.95));
    });
  });

  group('TvHighlightReelPlayerOverlay UI & Responsywność', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje bez przepełnień na ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          final reel = _buildSampleReel();
          await _pumpWithSize(
            tester,
            size,
            TvHighlightReelPlayerOverlay(
              reel: reel,
              autoPlay: false,
              onClose: () {},
            ),
          );

          expect(find.textContaining('TV REEL 45s'), findsOneWidget);
          expect(find.textContaining('Karpacz Orlinek'), findsOneWidget);
          expect(find.text('LISTA UJĘĆ I PRZEJŚĆ TV'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('obsługuje stan pusty i przycisk generowania skrótu', (tester) async {
      var generateCalled = false;
      await _pumpWithSize(
        tester,
        const Size(1024, 768),
        TvHighlightReelPlayerOverlay(
          reel: null,
          onGenerateReelRequested: () => generateCalled = true,
          onClose: () {},
        ),
      );

      expect(find.text('Brak skrótu telewizyjnego z etapu'), findsOneWidget);
      await tester.tap(find.text('Zmontuj skrót 45s'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(generateCalled, isTrue);
    });

    testWidgets('obsługuje przełączanie segmentów, HUD, prędkość i stan disabled',
        (tester) async {
      final reel = _buildSampleReel();
      HighlightClipSegment? changedTo;

      await _pumpWithSize(
        tester,
        const Size(1280, 800),
        TvHighlightReelPlayerOverlay(
          reel: reel,
          autoPlay: false,
          onSegmentChanged: (seg) => changedTo = seg,
          onClose: () {},
        ),
      );

      // Przejście do 3. segmentu na liście.
      await tester.tap(find.text('Walka w grupie pościgowej'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(changedTo?.id, 'seg_3');

      // Przełączenie prędkości z 1.0x na 1.5x.
      expect(find.text('1.0x'), findsOneWidget);
      await tester.tap(find.text('1.0x'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('1.5x'), findsOneWidget);

      // Ukrycie nakładki HUD.
      await tester.tap(find.text('HUD ON'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('HUD OFF'), findsOneWidget);

      // Włączenie odtwarzania i zatrzymanie po krótkim kroku.
      await tester.tap(find.text('Odtwórz'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Pauza'), findsOneWidget);
      await tester.tap(find.text('Pauza'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Odtwórz'), findsOneWidget);

      // Weryfikacja stanu disabled.
      await _pumpWithSize(
        tester,
        const Size(1280, 800),
        TvHighlightReelPlayerOverlay(
          reel: reel,
          isEnabled: false,
          onSegmentChanged: (seg) => changedTo = seg,
          onClose: () {},
        ),
      );
      changedTo = null;
      await tester.tap(find.text('Zwycięski finisz na Orlinku'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(changedTo, isNull);
    });
  });
}
