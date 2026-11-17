import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_photo_album_auto_capturer.dart';
import 'package:pro_peloton_manager/ui/widgets/post_stage_highlight_reel_carousel.dart';

void main() {
  group('StageHighlightReelItem & PostStageHighlightReelBuilder', () {
    test('serializacja JSON zachowuje wszystkie pola 1:1', () {
      final original = PostStageHighlightReelBuilder.buildDefaultSampleReel(
        stageNumber: 14,
        stageName: 'Col du Tourmalet',
      ).first;

      final restored = StageHighlightReelItem.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.mediaType, original.mediaType);
      expect(restored.title, original.title);
      expect(restored.stageNumber, 14);
      expect(restored.kilometerMark, original.kilometerMark);
      expect(restored.dramaScore, original.dramaScore);
      expect(restored.clipDuration, original.clipDuration);
      expect(restored.subjects.length, original.subjects.length);
    });

    test('fromStagePhotoAlbum generuje klipy wideo i zdjęcia dla albumu', () {
      const photo = StagePhotoSnapshot(
        photoId: 'p_1',
        stageId: 'stage_7',
        stageNumber: 7,
        slotCategory: StagePhotoSlotCategory.finaleAndFinishLine,
        momentKind: StagePhotoMomentKind.sprintPhotoFinish,
        kilometerMark: 188.0,
        remainingKm: 0.0,
        elapsedSeconds: 15200,
        title: 'Fotofinisz na kresce',
        editorialCaption: 'Różnica pół koła na mecie.',
        dramaScore: 95.0,
        isFeaturedCover: true,
        visualSeed: 77,
        cameraSpec: StagePhotoCameraSpec(
          preset: StagePhotoCameraPreset.finishLineTelephoto,
          focalLengthMm: 400,
          shutterSpeedLabel: '1/2500s',
          apertureLabel: 'f/2.8',
          isoValue: 400,
          cameraYawDeg: 0.0,
          cameraPitchDeg: -4.0,
        ),
        environment: StagePhotoEnvironmentContext(
          lightingMood: StagePhotoLightingMood.goldenHour,
          gradientPercent: 0.4,
          windSpeedKmh: 10.0,
          hasCobbles: false,
          elevationMeters: 150.0,
        ),
      );

      const album = StagePhotoAlbum(
        stageId: 'stage_7',
        stageName: 'Etap 7',
        stageNumber: 7,
        totalDistanceKm: 188.0,
        photos: [photo],
        totalMomentsEvaluated: 4,
        isFinalized: true,
      );

      final items = PostStageHighlightReelBuilder.fromStagePhotoAlbum(album);

      expect(items.length, 2);
      expect(
        items.where((i) => i.mediaType == HighlightMediaType.videoClip).length,
        1,
      );
      expect(
        items.where((i) => i.mediaType == HighlightMediaType.stagePhoto).length,
        1,
      );
      expect(items.last.exifSummary, contains('400mm'));
    });
  });

  group('PostStageHighlightReelCarousel Widget Tests', () {
    Widget wrapWidget(
      Widget child, {
      Size size = const Size(1280, 800),
    }) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: size.width,
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('nawigacja karuzeli, filtry, prędkość wideo i callbacki działają poprawnie',
        (tester) async {
      final items = PostStageHighlightReelBuilder.buildDefaultSampleReel(
        stageNumber: 15,
        stageName: 'Plateau de Beille',
      );
      StageHighlightReelItem? openedItem;
      StageHighlightReelItem? toggledFavorite;

      await tester.pumpWidget(
        wrapWidget(
          PostStageHighlightReelCarousel(
            items: items,
            stageTitle: 'Plateau de Beille',
            stageNumber: 15,
            onOpenInReplayTheater: (item) => openedItem = item,
            onToggleFavorite: (item) => toggledFavorite = item,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Kadr 1 z 4'), findsOneWidget);
      expect(find.text('WIDEO'), findsWidgets);

      // Przejście do następnego elementu (zdjęcie)
      await tester.tap(find.byTooltip('Następny materiał'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Kadr 2 z 4'), findsOneWidget);

      // Filtrowanie tylko zdjęć
      await tester.tap(find.text('Zdjęcia'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Kadr 1 z 2'), findsOneWidget);

      // Powrót do wszystkich i sprawdzenie prędkości wideo
      await tester.tap(find.text('Wszystkie'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('1.0x'), findsOneWidget);

      await tester.tap(find.text('1.0x'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('2.0x'), findsOneWidget);

      // Callbacki akcji
      await tester.ensureVisible(find.text('Kino Powtórek'));
      await tester.tap(find.text('Kino Powtórek'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(openedItem?.id, items.first.id);

      await tester.ensureVisible(find.text('Wyróżnij'));
      await tester.tap(find.text('Wyróżnij'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(toggledFavorite?.id, items.first.id);
      expect(find.text('Wyróżniono'), findsOneWidget);
    });

    testWidgets('obsługuje stan pusty oraz stan isDisabled', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const PostStageHighlightReelCarousel(
            items: [],
            stageTitle: 'Etap 1',
            stageNumber: 1,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Brak skrótów i zdjęć z tego etapu'), findsOneWidget);

      final items = PostStageHighlightReelBuilder.buildDefaultSampleReel();
      StageHighlightReelItem? openedItem;
      await tester.pumpWidget(
        wrapWidget(
          PostStageHighlightReelCarousel(
            items: items,
            stageTitle: 'Etap 1',
            stageNumber: 1,
            isDisabled: true,
            onOpenInReplayTheater: (item) => openedItem = item,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.ensureVisible(find.text('Kino Powtórek'));
      await tester.tap(find.text('Kino Powtórek'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(openedItem, isNull);
    });

    for (final resolution in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'brak przepełnień LayoutBuilder w rozdzielczości ${resolution.width.toInt()}x${resolution.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = resolution;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final items = PostStageHighlightReelBuilder.buildDefaultSampleReel(
          stageNumber: 19,
          stageName: 'Isola 2000',
        );

        await tester.pumpWidget(
          wrapWidget(
            PostStageHighlightReelCarousel(
              items: items,
              stageTitle: 'Isola 2000',
              stageNumber: 19,
              onOpenInReplayTheater: (_) {},
            ),
            size: resolution,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.text('SKRÓTY & GALERIA ETAPU'), findsOneWidget);
      });
    }
  });
}
