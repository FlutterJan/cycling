import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/rendering3d/first_person_cockpit_camera_renderer.dart';
import 'package:pro_peloton_manager/engine/rendering3d/onboard_bike_mounted_action_cam_3d.dart';
import 'package:pro_peloton_manager/ui/widgets/corner_g_force_and_lean_angle_telemetry_hud.dart';

Widget _buildHost({
  required Size size,
  required Widget child,
}) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('CornerGForcePhysicsCalculator & Model', () {
    test('wylicza przeciążenie boczne G, kąt przechyłu i próg ryzyka', () {
      // 72 km/h = 20 m/s na zakręcie R = 50 m => 400 / (50 * 9.80665) ≈ 0.816 G
      final double latG = CornerGForcePhysicsCalculator.computeLateralG(
        speedMs: 20.0,
        cornerRadiusMeters: 50.0,
        turnRight: true,
      );
      expect(latG, closeTo(0.816, 0.01));

      final double leanDeg =
          CornerGForcePhysicsCalculator.computeLeanAngleDegrees(lateralG: latG);
      expect(leanDeg, closeTo(39.2, 0.5));

      final CornerGripRiskTier dryRisk =
          CornerGForcePhysicsCalculator.evaluateGripRisk(
        lateralG: latG,
        surface: CornerSurfaceGripCondition.dryTarmac,
      );
      expect(dryRisk, CornerGripRiskTier.pushing);

      final CornerGripRiskTier wetRisk =
          CornerGForcePhysicsCalculator.evaluateGripRisk(
        lateralG: latG,
        surface: CornerSurfaceGripCondition.dampTarmac,
      );
      expect(wetRisk, CornerGripRiskTier.slideAlert);
    });

    test('serializuje i deserializuje CornerGForceAndLeanTelemetryData 1:1', () {
      const CornerGForceAndLeanTelemetryData original =
          CornerGForceAndLeanTelemetryData(
        lateralGForce: -0.92,
        longitudinalGForce: -0.35,
        leanAngleDegrees: -42.6,
        speedKmh: 66.5,
        cornerRadiusMeters: 38.0,
        peakLateralG: 1.05,
        peakLeanDegrees: 46.4,
        surfaceGrip: CornerSurfaceGripCondition.dampTarmac,
        cameraSource: CornerTelemetryCameraSource.firstPersonCockpit,
        isEnabled: true,
      );

      final Map<String, dynamic> json = original.toJson();
      final CornerGForceAndLeanTelemetryData restored =
          CornerGForceAndLeanTelemetryData.fromJson(json);

      expect(restored, equals(original));
      expect(restored.combinedGForce, greaterThan(0.92));
    });
  });

  group('CornerGForceAndLeanAngleTelemetryHud Widget', () {
    const List<Size> responsiveSizes = <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ];

    for (final Size viewportSize in responsiveSizes) {
      testWidgets(
        'renderuje się bez błędów układu na ${viewportSize.width.toInt()}x${viewportSize.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewportSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            _buildHost(
              size: viewportSize,
              child: Align(
                alignment: Alignment.topLeft,
                child: CornerGForceAndLeanAngleTelemetryHud(
                  data: const CornerGForceAndLeanTelemetryData(
                    lateralGForce: 0.88,
                    longitudinalGForce: -0.22,
                    leanAngleDegrees: 41.3,
                    speedKmh: 64.0,
                    cornerRadiusMeters: 37.0,
                    cameraSource: CornerTelemetryCameraSource.onBoardActionCam,
                  ),
                  onResetPeaks: () {},
                  onSurfaceChanged: (_) {},
                  onToggleVisibility: () {},
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(
            find.byType(CornerGForceAndLeanAngleTelemetryHud),
            findsOneWidget,
          );
          expect(find.textContaining('0.88 G R'), findsOneWidget);
          expect(find.textContaining('41.3° R'), findsOneWidget);

          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }

    testWidgets(
      'obsługuje zwijanie, zmianę nawierzchni, reset szczytów i stan disabled',
      (WidgetTester tester) async {
        const Size desktopSize = Size(1024, 768);
        tester.view.physicalSize = desktopSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        bool resetCalled = false;
        CornerSurfaceGripCondition selectedSurface =
            CornerSurfaceGripCondition.dryTarmac;

        await tester.pumpWidget(
          _buildHost(
            size: desktopSize,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setLocalState) {
                return CornerGForceAndLeanAngleTelemetryHud(
                  data: CornerGForceAndLeanTelemetryData(
                    lateralGForce: -0.74,
                    leanAngleDegrees: -36.5,
                    speedKmh: 58.0,
                    surfaceGrip: selectedSurface,
                  ),
                  onResetPeaks: () => resetCalled = true,
                  onSurfaceChanged: (CornerSurfaceGripCondition next) {
                    setLocalState(() => selectedSurface = next);
                  },
                );
              },
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byIcon(Icons.restart_alt_rounded));
        await tester.pump(const Duration(milliseconds: 200));
        expect(resetCalled, isTrue);

        await tester.tap(find.text('Suchy asfalt'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('Mokry asfalt'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close_fullscreen_rounded));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byIcon(Icons.open_in_full_rounded), findsOneWidget);

        // Stan disabled + ukryty
        await tester.pumpWidget(
          _buildHost(
            size: desktopSize,
            child: const CornerGForceAndLeanAngleTelemetryHud(
              data: CornerGForceAndLeanTelemetryData(
                lateralGForce: 0.4,
                leanAngleDegrees: 21.8,
                speedKmh: 45.0,
                isEnabled: false,
              ),
              isVisible: false,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.textContaining('0.40 G'), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });

  group('Integracja z OnBoard Action Cam i First-Person Cockpit', () {
    testWidgets(
      'OnBoardBikeMountedActionCam3d przełącza opcjonalny HUD G-Force',
      (WidgetTester tester) async {
        const Size desktopSize = Size(1280, 800);
        tester.view.physicalSize = desktopSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _buildHost(
            size: desktopSize,
            child: const OnBoardBikeMountedActionCam3d(autoPlay: false),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('G-Force: OFF'), findsOneWidget);
        expect(
          find.byType(CornerGForceAndLeanAngleTelemetryHud),
          findsNothing,
        );

        await tester.ensureVisible(find.text('G-Force: OFF'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('G-Force: OFF'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.text('G-Force: ON'), findsOneWidget);
        expect(
          find.byType(CornerGForceAndLeanAngleTelemetryHud),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      'FirstPersonCockpitViewportWidget przełącza opcjonalny HUD G-Force',
      (WidgetTester tester) async {
        const Size desktopSize = Size(1280, 800);
        tester.view.physicalSize = desktopSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _buildHost(
            size: desktopSize,
            child: const FirstPersonCockpitViewportWidget(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('G-Force: OFF'), findsOneWidget);
        expect(
          find.byType(CornerGForceAndLeanAngleTelemetryHud),
          findsNothing,
        );

        await tester.ensureVisible(find.text('G-Force: OFF'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('G-Force: OFF'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.text('G-Force: ON'), findsOneWidget);
        expect(
          find.byType(CornerGForceAndLeanAngleTelemetryHud),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });
}
