import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/asset_bundle_preload_warmer.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/ui/widgets/loading_race_screen_with_pro_tips.dart';

RaceStage _buildTestStage() {
  return const RaceStage(
    id: 'test_stage_17',
    stageNumber: 17,
    name: 'Saint-Gervais → Courchevel',
    stageType: StageType.highMountain,
    baseTemperatureCelsius: 19.0,
    weatherCondition: WeatherCondition.sunny,
    windSpeedKmh: 18.0,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 40.0,
        startElevationM: 600.0,
        endElevationM: 900.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 25.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.intermediateSprint,
      ),
      StageSegment(
        index: 1,
        startKm: 40.0,
        lengthKm: 25.0,
        startElevationM: 900.0,
        endElevationM: 2304.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 70.0,
        windDirectionDegrees: 210.0,
        roadBearingDegrees: 110.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      ),
      StageSegment(
        index: 2,
        startKm: 65.0,
        lengthKm: 18.0,
        startElevationM: 2304.0,
        endElevationM: 1747.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 55.0,
        windDirectionDegrees: 195.0,
        roadBearingDegrees: 140.0,
        sprintOrKomClassification: SegmentClassification.finishLine,
      ),
    ],
  );
}

void main() {
  group('SportsDirectorProTipsCatalog', () {
    test('zawiera wszystkie kategorie i unikalne identyfikatory', () {
      final ids = SportsDirectorProTipsCatalog.allTips
          .map((t) => t.id)
          .toSet();
      expect(
        ids.length,
        SportsDirectorProTipsCatalog.allTips.length,
      );
      expect(SportsDirectorProTipsCatalog.allTips.length, greaterThanOrEqualTo(10));
    });

    test('pickRandom respektuje excludeId i categoryFilter', () {
      final rng = math.Random(42);
      final first = SportsDirectorProTipsCatalog.pickRandom(
        random: rng,
        categoryFilter: TacticalProTipCategory.climbingAndPacing,
      );
      expect(first.category, TacticalProTipCategory.climbingAndPacing);

      final second = SportsDirectorProTipsCatalog.pickRandom(
        random: rng,
        excludeId: first.id,
        categoryFilter: TacticalProTipCategory.climbingAndPacing,
      );
      expect(second.category, TacticalProTipCategory.climbingAndPacing);
      expect(second.id, isNot(first.id));
    });
  });

  group('LoadingRaceScreenWithProTips widget', () {
    testWidgets(
      'wyświetla postęp AssetBundlePreloadWarmer, profil etapu i blokuje start przed zakończeniem',
      (tester) async {
        var entered = false;
        const runningState = PreloadWarmupState(
          phase: PreloadWarmupPhase.glbMeshes,
          progress: 0.56,
          currentTaskLabel: 'Ładowanie siatek .glb rowerów (10/16)...',
          isRunning: true,
          isWarmedUp: false,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: LoadingRaceScreenWithProTips(
                stage: _buildTestStage(),
                autoStartWarmup: false,
                autoRotateTips: false,
                randomSeed: 7,
                overrideWarmupState: runningState,
                onReadyToEnterRace: () => entered = true,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('ETAP 17'), findsOneWidget);
        expect(find.text('Saint-Gervais → Courchevel'), findsOneWidget);
        expect(find.text('56%'), findsOneWidget);
        expect(
          find.text('Ładowanie siatek .glb rowerów (10/16)...'),
          findsOneWidget,
        );
        expect(find.text('PROFIL WYSOKOŚCIOWY ETAPU'), findsOneWidget);
        expect(find.text('PORADA DYREKTORA SPORTOWEGO'), findsOneWidget);

        await tester.ensureVisible(find.text('Ładowanie zasobów 3D...'));
        await tester.tap(find.text('Ładowanie zasobów 3D...'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(entered, isFalse);
      },
    );

    testWidgets(
      'odblokowuje przycisk wejścia po zakończeniu rozgrzewki i obsługuje nawigację porad',
      (tester) async {
        var entered = false;
        const completedState = PreloadWarmupState(
          phase: PreloadWarmupPhase.completed,
          progress: 1.0,
          currentTaskLabel: 'Gotowe do wyścigu (240 ms)',
          isRunning: false,
          isWarmedUp: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: LoadingRaceScreenWithProTips(
                stage: _buildTestStage(),
                autoStartWarmup: false,
                autoRotateTips: false,
                randomSeed: 1,
                overrideWarmupState: completedState,
                onReadyToEnterRace: () => entered = true,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('100%'), findsOneWidget);
        expect(find.text('Wejdź do Wyścigu 3D'), findsOneWidget);

        // Zmiana porady przyciskiem losowania
        await tester.ensureVisible(find.byIcon(Icons.shuffle_rounded));
        await tester.tap(find.byIcon(Icons.shuffle_rounded));
        await tester.pump(const Duration(milliseconds: 300));

        // Kliknięcie wejścia do wyścigu 3D
        await tester.ensureVisible(find.text('Wejdź do Wyścigu 3D'));
        await tester.tap(find.text('Wejdź do Wyścigu 3D'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(entered, isTrue);
      },
    );

    testWidgets('wyświetla stan błędu rozgrzewki z przyciskiem Ponów', (tester) async {
      const failedState = PreloadWarmupState(
        phase: PreloadWarmupPhase.failed,
        progress: 0.4,
        currentTaskLabel: 'Wystąpił błąd podczas rozgrzewania zasobów',
        isRunning: false,
        isWarmedUp: false,
        errorMessage: 'Brak pliku testowego .glb',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoadingRaceScreenWithProTips(
              stage: _buildTestStage(),
              autoStartWarmup: false,
              autoRotateTips: false,
              overrideWarmupState: failedState,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Brak pliku testowego .glb'), findsOneWidget);
      expect(find.text('Ponów'), findsOneWidget);
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'responsywność bez przepełnień w rozdzielczości ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          const readyState = PreloadWarmupState(
            phase: PreloadWarmupPhase.completed,
            progress: 1.0,
            currentTaskLabel: 'Gotowe do wyścigu (180 ms)',
            isRunning: false,
            isWarmedUp: true,
          );

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                home: LoadingRaceScreenWithProTips(
                  stage: _buildTestStage(),
                  autoStartWarmup: false,
                  autoRotateTips: false,
                  overrideWarmupState: readyState,
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.text('ETAP 17'), findsOneWidget);
          expect(find.text('Wejdź do Wyścigu 3D'), findsOneWidget);
        },
      );
    }
  });
}
