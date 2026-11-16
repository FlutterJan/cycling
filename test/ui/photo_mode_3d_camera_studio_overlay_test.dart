import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/widgets/photo_mode_3d_camera_studio_overlay.dart';

void main() {
  group('PhotoMode3dCameraStudioOverlay — logika optyki i kamery', () {
    test('PhotoCamera3dPose przemieszcza się lokalnie i normalizuje kąty', () {
      const pose = PhotoCamera3dPose(
        positionX: 0.0,
        positionY: 2.0,
        positionZ: 0.0,
        yawDegrees: 0.0,
      );

      final forward = pose.movedLocal(forward: 5.0, up: 1.5);
      expect(forward.positionZ, closeTo(5.0, 0.001));
      expect(forward.positionY, closeTo(3.5, 0.001));

      final orbited = pose.orbited(deltaYaw: 190.0, deltaPitch: -100.0);
      expect(orbited.yawDegrees, closeTo(-170.0, 0.001));
      expect(orbited.pitchDegrees, -75.0);
    });

    test('PhotoLensSettings oblicza FOV dla 24mm–200mm i siłę Bokeh', () {
      const wide = PhotoLensSettings(
        focalLengthMm: 24.0,
        apertureFStop: 1.4,
        bokehIntensity: 1.0,
      );
      const tele = PhotoLensSettings(
        focalLengthMm: 200.0,
        apertureFStop: 16.0,
        bokehIntensity: 1.0,
      );

      expect(wide.verticalFovDegrees, greaterThan(50.0));
      expect(tele.verticalFovDegrees, lessThan(8.0));
      expect(wide.lensCategoryLabel, 'Szeroki kąt');
      expect(tele.lensCategoryLabel, 'Super Teleobiektyw');
      expect(wide.effectiveBlurSigma, greaterThan(9.0));
      expect(tele.effectiveBlurSigma, closeTo(0.0, 0.001));
    });

    test('PhotoColorFilterPreset buduje macierze filtrów kolorystycznych', () {
      expect(PhotoColorFilterPreset.natural.buildColorFilter(), isNull);
      expect(
        PhotoColorFilterPreset.classicBw1970.buildColorFilter(intensity: 1.0),
        isNotNull,
      );
      expect(
        PhotoColorFilterPreset.goldenHour.buildColorFilter(intensity: 0.8),
        isNotNull,
      );
      expect(
        PhotoColorFilterPreset.hdrContrast.buildColorFilter(intensity: 0.9),
        isNotNull,
      );
    });
  });

  group('PhotoMode3dCameraStudioOverlay — responsywność i interakcje UI', () {
    Widget buildHarness({
      required Size size,
      bool isRacePaused = true,
      ValueChanged<PhotoCamera3dPose>? onPoseChanged,
      VoidCallback? onRequestPauseRace,
      PhotoScreenshotCaptureCallback? onCaptureScreenshot,
    }) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: PhotoMode3dCameraStudioOverlay(
              isRacePaused: isRacePaused,
              onPoseChanged: onPoseChanged,
              onRequestPauseRace: onRequestPauseRace,
              onCaptureScreenshot: onCaptureScreenshot,
            ),
          ),
        ),
      );
    }

    for (final resolution in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje bez błędów overflow w rozdzielczości ${resolution.width.toInt()}x${resolution.height.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(resolution);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(buildHarness(size: resolution));
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('photo_mode_shutter_btn')), findsOneWidget);
        },
      );
    }

    testWidgets('wymaga zapauzowania wyścigu przed odblokowaniem studia', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var pauseRequested = false;
      await tester.pumpWidget(
        buildHarness(
          size: const Size(1280, 800),
          isRacePaused: false,
          onRequestPauseRace: () => pauseRequested = true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tryb Fotograficzny 3D wymaga pauzy'), findsOneWidget);
      await tester.tap(find.byKey(const Key('photo_mode_pause_race_btn')));
      await tester.pump(const Duration(milliseconds: 200));

      expect(pauseRequested, isTrue);
    });

    testWidgets('obsługuje Free Fly Cam, obiektyw 24-200mm, filtry i zapis do galerii',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      PhotoCamera3dPose? lastPose;
      PhotoModeStudioState? capturedState;

      await tester.pumpWidget(
        buildHarness(
          size: const Size(1600, 900),
          onPoseChanged: (pose) => lastPose = pose,
          onCaptureScreenshot: (state, _) async {
            capturedState = state;
            return PhotoScreenshotSaveResult(
              success: true,
              filePath: 'gallery/ppm_test.png',
              entry: PhotoGallerySavedEntry(
                id: 'ppm_test',
                filePath: 'gallery/ppm_test.png',
                capturedAt: DateTime(2026, 7, 18),
                stageName: "Alpe d'Huez",
                focalLengthMm: state.lens.focalLengthMm,
                apertureFStop: state.lens.apertureFStop,
                filterPreset: state.filterPreset,
                widthPx: 1920,
                heightPx: 1080,
                byteSize: 245760,
              ),
            );
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Ruch Free Fly Cam
      await tester.tap(find.byKey(const Key('photo_mode_fly_forward_btn')));
      await tester.pump(const Duration(milliseconds: 150));
      expect(lastPose, isNotNull);

      // Zakładka Obiektyw & Bokeh -> zmiana ogniskowej na 200 mm
      await tester.tap(find.byKey(const Key('photo_mode_tab_lens')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const Key('photo_mode_focal_200mm')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('200 mm'), findsWidgets);

      // Zakładka Filtry -> Klasyczny Czarno-Biały 1970
      await tester.tap(find.byKey(const Key('photo_mode_tab_filters')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(
        find.byKey(const Key('photo_mode_filter_classic_bw_1970')),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Zapis zrzutu ekranu do galerii
      await tester.tap(find.byKey(const Key('photo_mode_shutter_btn')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(capturedState, isNotNull);
      expect(capturedState!.lens.focalLengthMm, 200.0);
      expect(capturedState!.filterPreset, PhotoColorFilterPreset.classicBw1970);
      expect(find.textContaining('Zapisano do galerii'), findsOneWidget);

      // Sprawdź zakładkę Galeria
      await tester.tap(find.byKey(const Key('photo_mode_tab_gallery')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('GALERIA SESJI (1)'), findsOneWidget);

      // Tryb czystego kadru (ukryj i przywróć HUD)
      await tester.tap(find.byKey(const Key('photo_mode_hide_hud_btn')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('photo_mode_show_hud_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('photo_mode_show_hud_btn')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('photo_mode_shutter_btn')), findsOneWidget);
    });
  });
}
