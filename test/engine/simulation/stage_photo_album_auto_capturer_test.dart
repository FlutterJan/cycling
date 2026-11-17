import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/simulation/key_moments_detector.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_photo_album_auto_capturer.dart';

void main() {
  group('StagePhotoAlbumAutoCapturer', () {
    late StagePhotoAlbumAutoCapturer capturer;

    setUp(() {
      capturer = StagePhotoAlbumAutoCapturer();
      capturer.startStageCapture(
        stageId: 'tdf_stage_14',
        stageName: 'Pau - Pla d\'Adet',
        stageNumber: 14,
        totalDistanceKm: 152.0,
      );
    });

    test('captures 4 key moments across slots and sorts chronologically', () {
      const envClimb = StagePhotoEnvironmentContext(
        gradientPercent: 9.4,
        elevationMeters: 1680.0,
        temperatureCelsius: 17.5,
        windSpeedKmh: 14.0,
        lightingMood: StagePhotoLightingMood.goldenHour,
      );
      const rider = StagePhotoRiderSubject(
        riderId: 'r_leader',
        riderName: 'T. Pogacar',
        teamName: 'UAE Team',
        jerseyColorArgb: 0xFFD4AF37,
        isPlayerTeam: true,
        powerWatts: 620,
        speedKmh: 24.8,
        heartRateBpm: 184,
        positionInStage: 1,
        gapSeconds: 0.0,
      );

      capturer.evaluateKeyMomentTrigger(
        const KeyMomentTrigger(
          type: KeyMomentType.breakawayFormation,
          kilometerMark: 11.5,
          title: 'Odjazd dnia na 12. km',
          description: 'Siedmiu kolarzy odrywa się od peletonu.',
          recommendedCameraMode: 'helicopter',
          triggerKey: 'break_11',
        ),
        elapsedSeconds: 920.0,
        context: const StagePhotoEnvironmentContext(),
      );

      capturer.evaluateKeyMomentTrigger(
        const KeyMomentTrigger(
          type: KeyMomentType.decisiveClimb,
          kilometerMark: 118.0,
          title: 'Wspinaczka na Col du Tourmalet',
          description: 'Peleton rwie się na stromych serpentynach.',
          recommendedCameraMode: 'motoLead',
          triggerKey: 'climb_118',
        ),
        elapsedSeconds: 10800.0,
        context: envClimb,
        subjects: const [rider],
      );

      capturer.evaluateKeyMomentTrigger(
        const KeyMomentTrigger(
          type: KeyMomentType.playerRiderIncident,
          kilometerMark: 88.0,
          title: 'Defekt koła pomocnika',
          description: 'Szybka wymiana koła z wozu neutralnego.',
          recommendedCameraMode: 'teamCar',
          triggerKey: 'inc_88',
        ),
        elapsedSeconds: 7800.0,
        context: const StagePhotoEnvironmentContext(hasRain: true),
      );

      capturer.evaluateKeyMomentTrigger(
        const KeyMomentTrigger(
          type: KeyMomentType.finaleFinal5Km,
          kilometerMark: 148.5,
          title: 'Ostatnie 3.5 km pod Pla d\'Adet',
          description: 'Decydujące przyspieszenie przed szczytem.',
          recommendedCameraMode: 'motoLead',
          triggerKey: 'fin_148',
        ),
        elapsedSeconds: 13900.0,
        context: envClimb,
        subjects: const [rider],
      );

      final album = capturer.finalizeStageAlbum(stageWinner: rider);

      expect(album.isFinalized, isTrue);
      expect(album.photos.length, 4);
      expect(album.photos.map((p) => p.kilometerMark).toList(),
          [11.5, 88.0, 118.0, 148.5]);
      expect(album.photos.where((p) => p.isFeaturedCover).length, 1);
      expect(album.coverPhoto, isNotNull);
    });

    test('deduplicates nearby identical moments and keeps higher drama', () {
      const lowEnv = StagePhotoEnvironmentContext(gradientPercent: 2.0);
      const highEnv = StagePhotoEnvironmentContext(
        gradientPercent: 10.5,
        hasRain: true,
      );

      final first = capturer.captureCustomMoment(
        kind: StagePhotoMomentKind.gcSummitAttack,
        kilometerMark: 120.0,
        elapsedSeconds: 10000.0,
        title: 'Pierwsze przyspieszenie',
        caption: 'Test tempa.',
        context: lowEnv,
        customDramaScore: 70.0,
      );
      final second = capturer.captureCustomMoment(
        kind: StagePhotoMomentKind.gcSummitAttack,
        kilometerMark: 121.0,
        elapsedSeconds: 10040.0,
        title: 'Decydujący atak lidera',
        caption: 'Pełny gaz w deszczu.',
        context: highEnv,
        customDramaScore: 93.0,
      );

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(capturer.candidatePhotos.length, 1);
      expect(capturer.candidatePhotos.first.title, 'Decydujący atak lidera');
    });

    test('caps album to 4 photos when more than 4 moments occur', () {
      for (var i = 0; i < 7; i++) {
        capturer.captureCustomMoment(
          kind: StagePhotoMomentKind.values[i],
          kilometerMark: 15.0 + i * 20.0,
          elapsedSeconds: 1000.0 + i * 1600.0,
          title: 'Moment #$i',
          caption: 'Opis momentu $i',
          context: const StagePhotoEnvironmentContext(),
        );
      }

      final album = capturer.finalizeStageAlbum();
      expect(album.photos.length, 4);
      expect(album.totalMomentsEvaluated, 7);
    });

    test('auto-adds finish photo on finalize when none was recorded', () {
      const winner = StagePhotoRiderSubject(
        riderId: 'sprinter_1',
        riderName: 'J. Philipsen',
        teamName: 'Alpecin',
        jerseyColorArgb: 0xFF38BDF8,
        isPlayerTeam: false,
        powerWatts: 1320,
        speedKmh: 71.4,
        heartRateBpm: 191,
        positionInStage: 1,
        gapSeconds: 0.0,
      );

      final album = capturer.finalizeStageAlbum(
        stageWinner: winner,
        isPhotoFinishSprint: true,
        finishElapsedSeconds: 12450.0,
      );

      expect(album.photos.length, 1);
      expect(
        album.photos.first.momentKind,
        StagePhotoMomentKind.sprintPhotoFinish,
      );
      expect(album.photos.first.kilometerMark, 152.0);
    });

    test('supports full JSON round-trip serialization', () {
      capturer.captureCustomMoment(
        kind: StagePhotoMomentKind.cobbleSectorBattle,
        kilometerMark: 95.5,
        elapsedSeconds: 8100.0,
        title: 'Arenberg Forest',
        caption: 'Walka na bruku 5 gwiazdek.',
        context: const StagePhotoEnvironmentContext(
          hasCobbles: true,
          roadSurfaceLabel: 'Bruk 5★',
        ),
        subjects: const [
          StagePhotoRiderSubject(
            riderId: 'mvdp',
            riderName: 'M. van der Poel',
            teamName: 'Alpecin',
            jerseyColorArgb: 0xFFEF4444,
            isPlayerTeam: true,
            powerWatts: 540,
            speedKmh: 46.2,
            heartRateBpm: 178,
            positionInStage: 1,
            gapSeconds: 0.0,
          ),
        ],
      );

      final original = capturer.finalizeStageAlbum();
      final decoded = StagePhotoAlbum.fromJson(original.toJson());

      expect(decoded.stageId, original.stageId);
      expect(decoded.stageName, original.stageName);
      expect(decoded.photos.length, original.photos.length);
      expect(decoded.photos.first.title, original.photos.first.title);
      expect(
        decoded.photos.first.subjects.first.riderName,
        'M. van der Poel',
      );
    });
  });

  group('StagePhotoAlbumNotifier & GalleryPanel', () {
    test('notifier manages stage capture lifecycle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(stagePhotoAlbumProvider.notifier);
      notifier.startStage(
        stageId: 'roubaix',
        stageName: 'Paris - Roubaix',
        stageNumber: 1,
        totalDistanceKm: 257.0,
      );

      notifier.recordKeyMoment(
        const KeyMomentTrigger(
          type: KeyMomentType.challengingCobbles,
          kilometerMark: 162.0,
          title: 'Trouée d\'Arenberg',
          description: 'Wjazd w leśny przekop.',
          recommendedCameraMode: 'motoLead',
          triggerKey: 'arenberg',
        ),
        elapsedSeconds: 13200.0,
        context: const StagePhotoEnvironmentContext(hasCobbles: true),
      );

      notifier.finalizeStage();
      final state = container.read(stagePhotoAlbumProvider);

      expect(state.activeAlbum?.isFinalized, isTrue);
      expect(state.archivedAlbums.length, 1);
      expect(state.activeAlbum?.photos.length, 1);
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'StagePhotoAlbumGalleryPanel renders cleanly at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        final capturer = StagePhotoAlbumAutoCapturer()
          ..startStageCapture(
            stageId: 'stage_5',
            stageName: 'Etap 5 Alpy',
            stageNumber: 5,
            totalDistanceKm: 170.0,
          );
        capturer.captureCustomMoment(
          kind: StagePhotoMomentKind.breakawayAttack,
          kilometerMark: 14.0,
          elapsedSeconds: 1100.0,
          title: 'Ucieczka dnia',
          caption: 'Czterech śmiałków na czele.',
          context: const StagePhotoEnvironmentContext(),
        );
        capturer.captureCustomMoment(
          kind: StagePhotoMomentKind.decisiveMountainClimb,
          kilometerMark: 122.0,
          elapsedSeconds: 10900.0,
          title: 'Col de la Madeleine',
          caption: 'Strome nachylenie 9%.',
          context: const StagePhotoEnvironmentContext(gradientPercent: 9.0),
        );
        capturer.captureCustomMoment(
          kind: StagePhotoMomentKind.crashOrMechanicalDrama,
          kilometerMark: 138.0,
          elapsedSeconds: 12200.0,
          title: 'Defekt na zjeździe',
          caption: 'Pościg za grupą faworytów.',
          context: const StagePhotoEnvironmentContext(hasRain: true),
        );
        final album = capturer.finalizeStageAlbum(
          stageWinner: const StagePhotoRiderSubject(
            riderId: 'w1',
            riderName: 'J. Vingegaard',
            teamName: 'Visma',
            jerseyColorArgb: 0xFFD4AF37,
            isPlayerTeam: true,
            powerWatts: 460,
            speedKmh: 28.5,
            heartRateBpm: 180,
            positionInStage: 1,
            gapSeconds: 0.0,
          ),
        );

        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xFF0F1115),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: StagePhotoAlbumGalleryPanel(
                  albumOverride: album,
                  onExportAlbumPressed: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('Album Etapu 5'), findsOneWidget);
        expect(find.text('4/4 KADRÓW'), findsOneWidget);

        await tester.tap(find.text('Kluczowy teren').first);
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Col de la Madeleine'), findsWidgets);
      });
    }
  });
}
