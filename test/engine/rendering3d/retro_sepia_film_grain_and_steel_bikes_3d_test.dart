import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/rendering3d/retro_sepia_film_grain_and_steel_bikes_3d.dart';
import 'package:pro_peloton_manager/models/retro/golden_era_retro_season_model.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

void main() {
  group('RetroSepiaFilmGrainAndSteelBikes3dRenderer', () {
    const RetroSepiaFilmGrainAndSteelBikes3dRenderer renderer =
        RetroSepiaFilmGrainAndSteelBikes3dRenderer();

    test('generuje 5 chromowanych muf, 2 bidony na kierownicy i czapeczkę', () {
      const RetroSepiaFilmConfig config = RetroSepiaFilmConfig();
      const RetroSteelBikeRider3dPose pose = RetroSteelBikeRider3dPose();

      final RetroFilmGrainFrameState state = renderer.evaluateFrame(
        config: config,
        pose: pose,
        timeSeconds: 1.25,
      );

      expect(state.chromeLugs.length, equals(5));
      expect(state.handlebarBidons.length, equals(2));
      expect(state.handlebarBidons.first.isLeftSide, isTrue);
      expect(state.handlebarBidons.last.isLeftSide, isFalse);
      expect(state.casquette.style, equals(RetroCapStyle.classicCottonCasquette));
      expect(state.effectiveSepiaAmount, closeTo(0.72, 0.001));
    });

    test('forDecade dobiera odpowiedni filtr 16mm/VHS/Betacam/HD dla każdej dekady',
        () {
      final RetroSepiaFilmConfig c70 =
          RetroSepiaFilmConfig.forDecade(GoldenEraDecade.steelCannibalEra1970s);
      final RetroSepiaFilmConfig c80 =
          RetroSepiaFilmConfig.forDecade(GoldenEraDecade.badgerAndAeroDawn1980s);
      final RetroSepiaFilmConfig c90 =
          RetroSepiaFilmConfig.forDecade(GoldenEraDecade.stiAndRadioDawn1990s);
      final RetroSepiaFilmConfig c00 =
          RetroSepiaFilmConfig.forDecade(GoldenEraDecade.carbonAndPowerEra2000s);

      expect(c70.filterMode, equals(RetroBroadcastFilterMode.film16mmSepia1970s));
      expect(c70.enableHandlebarBidons, isTrue);
      expect(c80.filterMode, equals(RetroBroadcastFilterMode.vhsAnalog1980s));
      expect(c90.filterMode, equals(RetroBroadcastFilterMode.earlyBetacam1990s));
      expect(c00.filterMode, equals(RetroBroadcastFilterMode.cleanRestoredDigital));
      expect(c00.enableHandlebarBidons, isFalse);
      expect(c00.enableCasquette, isFalse);
    });

    test('projectPoint3d zwraca skończone współrzędne i dodatnią głębię', () {
      final Projected3dVertex projected = renderer.projectPoint3d(
        point: vm.Vector3(0.36, 0.86, 0.0),
        viewport: const Size(800, 450),
        yawRad: 0.48,
        pitchRad: 0.16,
      );

      expect(projected.offset.dx.isFinite, isTrue);
      expect(projected.offset.dy.isFinite, isTrue);
      expect(projected.depth, greaterThan(0.0));
      expect(projected.scale, greaterThan(0.0));
    });
  });

  group('RetroSepiaFilmGrainAndSteelBikesPanel', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: RetroSepiaFilmGrainAndSteelBikesPanel(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renderuje się poprawnie bez przepełnień na 390x844',
        (WidgetTester tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.text('Filtr Transmisji TV'), findsOneWidget);
      expect(find.text('5 lut.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się poprawnie bez przepełnień na 1024x768',
        (WidgetTester tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('Rama Stalowa & Epoka'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się poprawnie bez przepełnień na 1600x900',
        (WidgetTester tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(find.text('16MM FILM · 24 FPS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('przełącza filtr TV, ramę stalową i wyłącza bidony na kierownicy',
        (WidgetTester tester) async {
      RetroSepiaFilmConfig? lastConfig;
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: RetroSepiaFilmGrainAndSteelBikesPanel(
              onConfigChanged: (RetroSepiaFilmConfig cfg) => lastConfig = cfg,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('VHS Analog (1980s)'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(lastConfig?.filterMode, equals(RetroBroadcastFilterMode.vhsAnalog1980s));
      expect(find.text('VHS SP · HI-FI'), findsOneWidget);

      await tester.tap(find.text('Bidony na kierownicy'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(lastConfig?.enableHandlebarBidons, isFalse);
      expect(find.text('Wył.'), findsOneWidget);

      await tester.tap(find.text('Tytan Gr.9 · 1994'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(lastConfig?.enableDowntubeShifters, isFalse);
    });
  });
}
