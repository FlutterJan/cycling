import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/ui/widgets/tv_picture_in_picture_breakaway_cam.dart';

void main() {
  TvPipBreakawayFeedData buildSampleBreakawayData({
    PipCameraTargetType targetType = PipCameraTargetType.breakaway,
    double gapSeconds = 105.0,
    List<PipBreakawayRiderSample>? riders,
  }) {
    return TvPipBreakawayFeedData(
      targetType: targetType,
      cameraAngle: PipCameraAngle.motoFront,
      gapToPelotonSeconds: gapSeconds,
      gapDistanceMeters: 1250.0,
      groupSpeedKmh: 45.6,
      roadGradientPercent: 6.8,
      highlightRiderName: 'M. Kwiatkowski',
      highlightRiderWatts: 412,
      isLiveSignalActive: true,
      isPlayerInGroup: true,
      signalQualityPercent: 98.0,
      riders: riders ??
          const <PipBreakawayRiderSample>[
            PipBreakawayRiderSample(
              riderId: 'r1',
              riderName: 'M. Kwiatkowski',
              teamShortCode: 'IGD',
              jerseyColor: AppColors.primaryAccent,
              isPlayerRider: true,
              lateralOffsetMeters: -0.9,
              longitudinalOffsetMeters: 3.5,
              speedKmh: 45.8,
              watts: 412,
              cadenceRpm: 94.0,
              isAttacking: true,
            ),
            PipBreakawayRiderSample(
              riderId: 'r2',
              riderName: 'J. Alaphilippe',
              teamShortCode: 'SOQ',
              jerseyColor: AppColors.accentBlue,
              lateralOffsetMeters: 1.1,
              longitudinalOffsetMeters: 8.0,
              speedKmh: 45.4,
              watts: 398,
              cadenceRpm: 91.0,
            ),
          ],
    );
  }

  Widget wrapInViewport(
    Size size,
    Widget child,
  ) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: <Widget>[
              const Positioned.fill(
                child: ColoredBox(color: AppColors.background),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }

  group('TvPictureInPictureBreakawayCam', () {
    testWidgets('renderuje podgląd ucieczki z telemetrią i wyróżnionym kolarzem',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapInViewport(
          const Size(1600, 900),
          TvPictureInPictureBreakawayCam(
            data: buildSampleBreakawayData(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('UCIECZKA'), findsOneWidget);
      expect(find.text('MOTO 2'), findsOneWidget);
      expect(find.text('M. KWIATKOWSKI'), findsOneWidget);
      expect(find.text('412 W'), findsOneWidget);
      expect(find.text('+1:45'), findsOneWidget);
      expect(find.text('45.6 km/h'), findsOneWidget);
      expect(find.text('+6.8%'), findsOneWidget);
    });

    testWidgets('renderuje tryb pogoni po kraksie z ujemną stratą czasową',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapInViewport(
          const Size(1280, 800),
          TvPictureInPictureBreakawayCam(
            data: buildSampleBreakawayData(
              targetType: PipCameraTargetType.crashChase,
              gapSeconds: -38.0,
              riders: const <PipBreakawayRiderSample>[
                PipBreakawayRiderSample(
                  riderId: 'r_crash',
                  riderName: 'T. Pogacar',
                  teamShortCode: 'UAD',
                  jerseyColor: AppColors.crimsonAlert,
                  hasCrashDamage: true,
                  lateralOffsetMeters: 0.4,
                  longitudinalOffsetMeters: 5.0,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('POGOŃ PO KRAKSIE'), findsOneWidget);
      expect(find.text('-38s'), findsOneWidget);
    });

    testWidgets(
        'obsługuje zamianę kamer, zmianę celu, kąta, powiększenie i minimalizację',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool swapped = false;
      PipCameraTargetType? selectedTarget;
      PipCameraAngle? selectedAngle;
      bool? expandedState;
      bool? minimizedState;

      await tester.pumpWidget(
        wrapInViewport(
          const Size(1600, 900),
          TvPictureInPictureBreakawayCam(
            data: buildSampleBreakawayData(),
            onSwapCameras: () => swapped = true,
            onSelectTargetType: (PipCameraTargetType t) => selectedTarget = t,
            onChangeCameraAngle: (PipCameraAngle a) => selectedAngle = a,
            onExpandedChanged: (bool v) => expandedState = v,
            onMinimizedChanged: (bool v) => minimizedState = v,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Zamiana kamer
      await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
      await tester.pump(const Duration(milliseconds: 50));
      expect(swapped, isTrue);

      // Zmiana celu (cyklicznie z breakaway -> crashChase)
      await tester.tap(find.text('UCIECZKA'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(selectedTarget, PipCameraTargetType.crashChase);

      // Zmiana kąta kamery (motoFront -> helicopterOverhead)
      await tester.tap(find.text('MOTO 2'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(selectedAngle, PipCameraAngle.helicopterOverhead);

      // Powiększenie okna
      await tester.tap(find.byIcon(Icons.open_in_full_rounded));
      await tester.pump(const Duration(milliseconds: 260));
      expect(expandedState, isTrue);

      // Minimalizacja do pigułki i przywrócenie
      await tester.tap(find.byIcon(Icons.minimize_rounded));
      await tester.pump(const Duration(milliseconds: 260));
      expect(minimizedState, isTrue);
      expect(find.textContaining('BREAKAWAY'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.open_in_full_rounded));
      await tester.pump(const Duration(milliseconds: 260));
      expect(minimizedState, isFalse);
    });

    testWidgets('w stanie disabled nie wywołuje callbacków',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool swapped = false;

      await tester.pumpWidget(
        wrapInViewport(
          const Size(1280, 720),
          TvPictureInPictureBreakawayCam(
            enabled: false,
            data: buildSampleBreakawayData(),
            onSwapCameras: () => swapped = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
      await tester.pump(const Duration(milliseconds: 50));
      expect(swapped, isFalse);
    });

    testWidgets('obsługuje pustą listę kolarzy i wartości graniczne NaN/Inf',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapInViewport(
          const Size(1024, 768),
          const TvPictureInPictureBreakawayCam(
            data: TvPipBreakawayFeedData(
              targetType: PipCameraTargetType.counterAttack,
              gapToPelotonSeconds: double.nan,
              groupSpeedKmh: double.infinity,
              roadGradientPercent: double.negativeInfinity,
              riders: <PipBreakawayRiderSample>[],
              isLiveSignalActive: false,
              signalQualityPercent: 35.0,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('KONTRATAK'), findsOneWidget);
      expect(find.text('+0s'), findsOneWidget);
      expect(find.text('0.0 km/h'), findsOneWidget);
    });

    testWidgets(
        'responsywność bez overflow dla 390x844, 1024x768 i 1600x900',
        (WidgetTester tester) async {
      const List<Size> viewports = <Size>[
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ];

      for (final Size viewport in viewports) {
        await tester.binding.setSurfaceSize(viewport);
        await tester.pumpWidget(
          wrapInViewport(
            viewport,
            TvPictureInPictureBreakawayCam(
              data: buildSampleBreakawayData(),
              onSwapCameras: () {},
              onSelectTargetType: (_) {},
              onChangeCameraAngle: (_) {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      }

      await tester.binding.setSurfaceSize(null);
    });
  });
}
