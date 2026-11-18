import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/engine/rendering3d/esports_cyber_velodrome_and_hologram_3d.dart';
import 'package:pro_peloton_manager/models/esports/uci_cycling_esports_world_model.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  group('EsportsCyberVelodromeAndHologram3dEngine', () {
    test('computeWkgBarColor maps W/kg zones consistently', () {
      expect(
        EsportsCyberVelodromeAndHologram3dEngine.computeWkgBarColor(2.6),
        AppColors.cyanAccent,
      );
      expect(
        EsportsCyberVelodromeAndHologram3dEngine.computeWkgBarColor(3.5),
        AppColors.statusSuccess,
      );
      expect(
        EsportsCyberVelodromeAndHologram3dEngine.computeWkgBarColor(4.4),
        AppColors.goldAccent,
      );
      expect(
        EsportsCyberVelodromeAndHologram3dEngine.computeWkgBarColor(5.1),
        AppColors.amberWarning,
      );
      expect(
        EsportsCyberVelodromeAndHologram3dEngine.computeWkgBarColor(6.0),
        AppColors.crimsonAlert,
      );
      expect(
        EsportsCyberVelodromeAndHologram3dEngine.computeWkgBarColor(7.2),
        AppColors.powerZone7,
      );
    });

    test('computePowerUpHologramColor and shortCode cover all PowerUps', () {
      for (final type in EsportsPowerUpType.values) {
        final color =
            EsportsCyberVelodromeAndHologram3dEngine.computePowerUpHologramColor(
          type,
        );
        final code =
            EsportsCyberVelodromeAndHologram3dEngine.powerUpShortCode(type);
        expect(color, isA<Color>());
        expect(code, isNotEmpty);
      }
    });

    test('projectWorldPoint projects forward points and hides points behind', () {
      final camPos = Vector3(0, 3.2, -9.2);
      final camTarget = Vector3(0, 1.1, 26.0);

      final visible = EsportsCyberVelodromeAndHologram3dEngine.projectWorldPoint(
        worldPoint: Vector3(0, 0.5, 12.0),
        cameraPos: camPos,
        cameraTarget: camTarget,
        viewportSize: const Size(1024, 768),
        fovDegrees: 58.0,
      );
      expect(visible.isVisible, isTrue);
      expect(visible.depthMeters, greaterThan(10.0));
      expect(visible.scale, greaterThan(0.0));

      final behind = EsportsCyberVelodromeAndHologram3dEngine.projectWorldPoint(
        worldPoint: Vector3(0, 0.5, -25.0),
        cameraPos: camPos,
        cameraTarget: camTarget,
        viewportSize: const Size(1024, 768),
        fovDegrees: 58.0,
      );
      expect(behind.isVisible, isFalse);
    });

    test('buildDemoFrameInput and computeTelemetry return valid metrics', () {
      final input =
          EsportsCyberVelodromeAndHologram3dEngine.buildDemoFrameInput(
        elapsedSeconds: 4.5,
        worldPreset: EsportsCyberWorldPreset.tokyoNeonCrit,
        activePlayerPowerUp: EsportsPowerUpType.aeroHelmet,
        activePowerUpRemainingSeconds: 9.0,
      );
      const config = EsportsCyberVelodromeConfig(
        worldPreset: EsportsCyberWorldPreset.tokyoNeonCrit,
      );

      final telemetry =
          EsportsCyberVelodromeAndHologram3dEngine.computeTelemetry(
        input: input,
        config: config,
      );

      expect(telemetry.visibleRidersCount, greaterThanOrEqualTo(5));
      expect(telemetry.visibleHologramsCount, greaterThanOrEqualTo(3));
      expect(telemetry.averageWkg, greaterThan(4.0));
      expect(telemetry.leaderWkg, greaterThanOrEqualTo(telemetry.averageWkg));
      expect(telemetry.activePowerUpsCount, greaterThanOrEqualTo(1));
    });
  });

  group('EsportsCyberVelodromeViewportWidget responsiveness & interaction', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                backgroundColor: AppColors.background,
                body: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: EsportsCyberVelodromeViewportWidget(
                      autoAnimate: false,
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(EsportsCyberVelodromeViewportWidget), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('switches world preset, camera mode and triggers Power-Up',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      EsportsPowerUpType? triggered;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: SingleChildScrollView(
              child: EsportsCyberVelodromeViewportWidget(
                autoAnimate: true,
                onTriggerPowerUp: (type) => triggered = type,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('TOKIO CRIT'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.textContaining('TOKIO NEON CRIT'),
        findsOneWidget,
      );

      await tester.tap(find.text('DRONE'));
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.textContaining('Użyj: AERO'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(triggered, EsportsPowerUpType.aeroHelmet);
      expect(find.textContaining('Aktywny ('), findsOneWidget);
    });
  });
}
