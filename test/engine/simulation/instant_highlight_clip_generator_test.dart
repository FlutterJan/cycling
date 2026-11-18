import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/simulation/instant_highlight_clip_generator.dart';
import 'package:pro_peloton_manager/engine/simulation/key_moments_detector.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_replay_recorder.dart';

void main() {
  group('InstantHighlightClipGenerator', () {
    const generator = InstantHighlightClipGenerator();

    test('generuje dokładnie 45-sekundowy skrót z kluczowych momentów i finału',
        () {
      final triggers = [
        const KeyMomentTrigger(
          type: KeyMomentType.breakawayFormation,
          kilometerMark: 8.5,
          title: 'Ucieczka 5 kolarzy',
          description: 'Piątka śmiałków odjeżdża po starcie ostrym.',
          recommendedCameraMode: 'helicopter',
          triggerKey: 'km_breakaway',
        ),
        const KeyMomentTrigger(
          type: KeyMomentType.challengingCobbles,
          kilometerMark: 112.0,
          title: 'Carrefour de l\'Arbre',
          description: 'Selekcja na pięciogwiazdkowym sektorze brukowym.',
          recommendedCameraMode: 'motoLead',
          relatedRiderName: 'Mathieu van der Poel',
          triggerKey: 'km_cobbles',
        ),
        const KeyMomentTrigger(
          type: KeyMomentType.gcLeaderAttack,
          kilometerMark: 158.0,
          title: 'Atak faworyta GC!',
          description: 'Mocne przyspieszenie na przedostatniej rampie.',
          recommendedCameraMode: 'motoLead',
          relatedRiderName: 'Tadej Pogačar',
          triggerKey: 'km_gc',
        ),
      ];

      final finalFrames = [
        const ReplayFrameSnapshot(
          frameIndex: 1,
          timestampSeconds: 14210.0,
          leadKilometerMark: 179.4,
          distanceToFinishKm: 0.6,
          currentGradientPercent: 0.4,
          currentElevationMeters: 42.0,
          leadRiderName: 'Jasper Philipsen',
          riders: [
            ReplayRiderState(
              riderId: 'r1',
              bibNumber: 1,
              riderName: 'Jasper Philipsen',
              teamId: 't1',
              teamJerseyHexColor: '#38BDF8',
              isPlayerRider: true,
              distanceCoveredMeters: 179400,
              lateralOffsetRoadMeters: 0.2,
              elevationMeters: 42.0,
              speedMs: 18.6,
              speedKmh: 66.96,
              powerWatts: 1210,
              cadenceRpm: 108,
              heartRateBpm: 186,
              isSprinting: true,
              isBikeThrow: true,
              isDrafting: false,
              isCrashed: false,
              hasDefect: false,
            ),
          ],
        ),
      ];

      final reel = generator.generatePostStageReel(
        stageId: 'tdf_s5',
        raceName: 'Tour de France',
        stageName: 'Lille - Arenberg',
        stageNumber: 5,
        stageDistanceKm: 180.0,
        stageTypeLabel: 'Klasyk brukowy',
        winnerName: 'Jasper Philipsen',
        winnerTeamName: 'Alpecin-Deceuninck',
        gcLeaderName: 'Tadej Pogačar',
        keyMoments: triggers,
        finalKilometerFrames: finalFrames,
      );

      expect(reel.totalDurationSeconds, closeTo(45.0, 0.01));
      expect(reel.segments.length, greaterThanOrEqualTo(5));
      expect(reel.segments.first.startTimelineSecond, closeTo(0.0, 0.001));
      expect(reel.segments.last.endTimelineSecond, closeTo(45.0, 0.01));

      final sumDurations = reel.segments.fold<double>(
        0.0,
        (sum, s) => sum + s.durationSeconds,
      );
      expect(sumDurations, closeTo(45.0, 0.01));
      expect(
        reel.segments.any(
          (s) => s.role == HighlightSegmentRole.finalSprintClimax,
        ),
        isTrue,
      );
      expect(reel.pacingCurve.length, equals(reel.segments.length));
    });

    test('tworzy zastępczą narrację 45s nawet przy pustych danych wejściowych',
        () {
      final reel = generator.generatePostStageReel(
        stageId: 'empty_s1',
        raceName: 'Critérium du Dauphiné',
        stageName: 'Etap 1',
        stageNumber: 1,
        stageDistanceKm: 145.0,
        stageTypeLabel: 'Płaski',
        winnerName: 'Olav Kooij',
        winnerTeamName: 'Visma',
        gcLeaderName: 'Olav Kooij',
      );

      expect(reel.isEmpty, isFalse);
      expect(reel.totalDurationSeconds, closeTo(45.0, 0.01));
      expect(reel.segments.length, greaterThanOrEqualTo(4));
      expect(
        reel.exportBroadcastScriptSummary(),
        contains('Olav Kooij'),
      );
    });

    test('deduplikuje powtarzające się momenty na tym samym kilometrze', () {
      final duplicateTriggers = [
        const KeyMomentTrigger(
          type: KeyMomentType.gcLeaderAttack,
          kilometerMark: 120.0,
          title: 'Atak 1',
          description: 'Pierwszy atak',
          recommendedCameraMode: 'motoLead',
          triggerKey: 'dup_1',
        ),
        const KeyMomentTrigger(
          type: KeyMomentType.gcLeaderAttack,
          kilometerMark: 120.5,
          title: 'Atak 2',
          description: 'Duplikat na tym samym kilometrze',
          recommendedCameraMode: 'motoLead',
          triggerKey: 'dup_2',
        ),
      ];

      final reel = generator.generatePostStageReel(
        stageId: 'dup_stage',
        raceName: 'Giro d\'Italia',
        stageName: 'Etap 16',
        stageNumber: 16,
        stageDistanceKm: 160.0,
        stageTypeLabel: 'Górski',
        winnerName: 'Primož Roglič',
        winnerTeamName: 'Red Bull',
        gcLeaderName: 'Primož Roglič',
        keyMoments: duplicateTriggers,
      );

      final gcSegments = reel.segments
          .where((s) => s.role == HighlightSegmentRole.tacticalTurningPoint)
          .toList();
      expect(gcSegments.length, equals(1));
    });

    test('zachowuje bezstratną serializację JSON round-trip', () {
      final reel = generator.generatePostStageReel(
        stageId: 'json_s1',
        raceName: 'Vuelta a España',
        stageName: 'Angliru',
        stageNumber: 17,
        stageDistanceKm: 125.0,
        stageTypeLabel: 'Górski HC',
        winnerName: 'Sepp Kuss',
        winnerTeamName: 'Visma',
        gcLeaderName: 'Sepp Kuss',
      );

      final json = reel.toJson();
      final restored = InstantHighlightReel.fromJson(json);

      expect(restored.reelId, equals(reel.reelId));
      expect(restored.stageName, equals(reel.stageName));
      expect(restored.totalDurationSeconds, closeTo(45.0, 0.01));
      expect(restored.segments.length, equals(reel.segments.length));
      expect(restored.pacingCurve.length, equals(reel.pacingCurve.length));
    });
  });

  group('InstantHighlightClipGeneratorNotifier & UI', () {
    test('zarządza odtwarzaniem, przewijaniem i skokami po segmentach', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(instantHighlightClipGeneratorProvider.notifier);
      notifier.generateFromStageData(
        stageId: 's_test',
        raceName: 'Paris-Nice',
        stageName: 'Nicea',
        stageNumber: 8,
        stageDistanceKm: 110.0,
        stageTypeLabel: 'Pagórkowaty',
        winnerName: 'Remco Evenepoel',
        winnerTeamName: 'Soudal',
        gcLeaderName: 'Remco Evenepoel',
      );

      var state = container.read(instantHighlightClipGeneratorProvider);
      expect(state.hasReel, isTrue);
      expect(state.totalDurationSeconds, closeTo(45.0, 0.01));

      notifier.jumpToSegment(2);
      state = container.read(instantHighlightClipGeneratorProvider);
      expect(
        state.playbackPositionSeconds,
        closeTo(state.reel!.segments[2].startTimelineSecond, 0.01),
      );

      notifier.setPlaybackSpeed(1.5);
      notifier.toggleTvGraphics();
      state = container.read(instantHighlightClipGeneratorProvider);
      expect(state.playbackSpeed, equals(1.5));
      expect(state.showTvGraphics, isFalse);

      notifier.stop();
      expect(
        container
            .read(instantHighlightClipGeneratorProvider)
            .playbackPositionSeconds,
        equals(0.0),
      );
    });

    Future<void> pumpAtResolution(
      WidgetTester tester,
      Size size,
      InstantHighlightReel? reel, {
      bool isEnabled = true,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: InstantHighlightClipPlayerPanel(
                  initialReel: reel,
                  isEnabled: isEnabled,
                  onGenerateSampleRequested: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renderuje się poprawnie w 390x844, 1024x768 i 1600x900',
        (tester) async {
      final reel = const InstantHighlightClipGenerator().generatePostStageReel(
        stageId: 'ui_s1',
        raceName: 'Tour de Pologne',
        stageName: 'Kraków',
        stageNumber: 7,
        stageDistanceKm: 142.0,
        stageTypeLabel: 'Etap finałowy',
        winnerName: 'Michał Kwiatkowski',
        winnerTeamName: 'INEOS Grenadiers',
        gcLeaderName: 'Jonas Vingegaard',
      );

      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpAtResolution(tester, size, reel);
        expect(find.textContaining('Skrót TV 45s'), findsOneWidget);
        expect(find.text('Odtwórz'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('obsługuje stan pusty oraz stan wyłączony (disabled)',
        (tester) async {
      await pumpAtResolution(
        tester,
        const Size(1024, 768),
        null,
        isEnabled: false,
      );
      expect(
        find.text('Brak wygenerowanego skrótu telewizyjnego'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
