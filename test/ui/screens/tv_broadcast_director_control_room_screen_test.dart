import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/broadcast/tv_director_live_production_model.dart';
import 'package:pro_peloton_manager/ui/screens/tv_broadcast_director_control_room_screen.dart';

void main() {
  group('TvBroadcastDirectorNotifier', () {
    test('przełącza kamery przez PREVIEW -> CUT / DISSOLVE oraz bezpośredni CUT', () {
      final notifier = TvBroadcastDirectorNotifier();
      expect(notifier.state.programCameraId, 'heliCam1');
      expect(notifier.state.previewCameraId, 'heliCam2');

      notifier.cuePreview('motoCamPeloton');
      expect(notifier.state.previewCameraId, 'motoCamPeloton');

      notifier.takePreview(transition: BroadcastTransitionType.dissolve);
      expect(notifier.state.programCameraId, 'motoCamPeloton');
      expect(notifier.state.lastTransitionType, BroadcastTransitionType.dissolve);
      expect(notifier.state.lastTransitionDurationMs, 320);

      notifier.cutDirectlyToCamera('motoCamFront');
      expect(notifier.state.programCameraId, 'motoCamFront');
      expect(notifier.state.lastTransitionType, BroadcastTransitionType.cut);
      expect(notifier.state.totalCameraCuts, 2);
    });

    test('wyzwala grafiki ekranowe W/kg, profil 3D i powtórkę slow-motion', () {
      final notifier = TvBroadcastDirectorNotifier();

      notifier.triggerQuickGraphic(TvGraphicOverlayType.riderWkgComparison);
      expect(
        notifier.state.activeOnAirGraphic?.type,
        TvGraphicOverlayType.riderWkgComparison,
      );

      notifier.triggerQuickGraphic(TvGraphicOverlayType.climb3dProfile);
      expect(
        notifier.state.activeOnAirGraphic?.type,
        TvGraphicOverlayType.climb3dProfile,
      );

      notifier.triggerQuickGraphic(TvGraphicOverlayType.slowMotionReplay);
      expect(
        notifier.state.activeOnAirGraphic?.type,
        TvGraphicOverlayType.slowMotionReplay,
      );

      notifier.dismissActiveGraphic();
      expect(notifier.state.activeOnAirGraphic, isNull);
    });

    test('łapanie symulowanego ataku zwiększa licznik złapanych ataków i emocje', () {
      final notifier = TvBroadcastDirectorNotifier();
      final initialDrama = notifier.state.viewershipMetrics.dramaRating;

      notifier.triggerSimulatedRaceAttack(preferredCameraId: 'motoCamChase');
      notifier.cutDirectlyToCamera('motoCamChase');

      expect(notifier.state.capturedPeakMomentsCount, 1);
      expect(
        notifier.state.viewershipMetrics.dramaRating,
        greaterThan(initialDrama),
      );

      notifier.stepLiveSecond();
      expect(notifier.state.currentRaceSecond, 1);
    });
  });

  group('TvBroadcastDirectorControlRoomScreen', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się poprawnie bez przepełnień w ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: TvBroadcastDirectorControlRoomScreen(
                  enableLiveTicker: false,
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('PROGRAM OUT'), findsOneWidget);
          expect(find.text('CUT (0ms)'), findsOneWidget);
          expect(find.text('DISSOLVE (320ms)'), findsOneWidget);
          expect(
            find.text('MULTIVIEWER — 6 MONITORÓW PODGLĄDU NA ŻYWO'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('interakcje CUT, DISSOLVE i wyzwalacze grafik działają poprawnie', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TvBroadcastDirectorControlRoomScreen(
              enableLiveTicker: false,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Przełączenie DISSOLVE
      await tester.tap(find.text('DISSOLVE (320ms)'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('CIĘCIA: 1'), findsOneWidget);

      // Wyzwolenie grafiki W/kg
      await tester.tap(find.text('Porównanie W/kg Liderów'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('W/kg'), findsWidgets);

      // Wyzwolenie profilu 3D
      await tester.tap(find.text('Profil Podjazdu 3D'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('COL DE LA LOZE'), findsWidgets);

      // Wyzwolenie powtórki slow-motion
      await tester.tap(find.text('Powtórka Slow-Motion 0.25x'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('POWTÓRKA SLOW-MOTION'), findsWidgets);

      expect(tester.takeException(), isNull);
    });

    testWidgets('tryb isReadOnly blokuje przełączanie i wyzwalacze', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TvBroadcastDirectorControlRoomScreen(
              isReadOnly: true,
              enableLiveTicker: false,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.ensureVisible(find.text('CUT (0ms)'));
      await tester.tap(find.text('CUT (0ms)'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('CIĘCIA: 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
