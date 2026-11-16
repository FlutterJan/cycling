import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/ui/widgets/rider_fatigue_body_heatmap_painter.dart';

void main() {
  group('RiderFatigueBodyHeatmapPainter & Profile', () {
    test('fatigueColorForLevel interpolates from green to dark crimson', () {
      final fresh = RiderFatigueBodyHeatmapPainter.fatigueColorForLevel(0.0);
      final mid = RiderFatigueBodyHeatmapPainter.fatigueColorForLevel(0.35);
      final high = RiderFatigueBodyHeatmapPainter.fatigueColorForLevel(0.70);
      final critical = RiderFatigueBodyHeatmapPainter.fatigueColorForLevel(1.0);

      expect(fresh, AppColors.statusSuccess);
      expect(mid, AppColors.amberWarning);
      expect(high, AppColors.crimsonAlert);
      expect(critical, RiderFatigueBodyHeatmapPainter.deepCrimson);

      final disabled = RiderFatigueBodyHeatmapPainter.fatigueColorForLevel(
        1.0,
        isEnabled: false,
      );
      expect(disabled.a, lessThan(0.6));
    });

    test('RiderMuscleFatigueProfile.fromRiderHealth reflects TSB and injuries', () {
      const kneeHealth = RiderHealth(
        acuteTrainingLoad: 95,
        chronicTrainingLoad: 70,
        currentInjury: Injury(
          name: 'Zapalenie ścięgna rzepki',
          type: InjuryType.kneeTendinitis,
          daysRemaining: 6,
          trainingAllowed: false,
        ),
      );
      final kneeProfile = RiderMuscleFatigueProfile.fromRiderHealth(kneeHealth);
      expect(kneeProfile.quadriceps, greaterThanOrEqualTo(0.86));
      expect(kneeProfile.calves, greaterThanOrEqualTo(0.72));
      expect(kneeProfile.mostFatiguedGroup, BodyFatigueGroup.quadriceps);

      const concussionHealth = RiderHealth(
        acuteTrainingLoad: 40,
        chronicTrainingLoad: 60,
        currentInjury: Injury(
          name: 'Wstrząśnienie mózgu',
          type: InjuryType.concussion,
          daysRemaining: 10,
          trainingAllowed: false,
        ),
      );
      final cnsProfile = RiderMuscleFatigueProfile.fromRiderHealth(concussionHealth);
      expect(cnsProfile.centralNervousSystem, greaterThanOrEqualTo(0.95));
      expect(cnsProfile.mostFatiguedGroup, BodyFatigueGroup.centralNervousSystem);
    });

    test('hitTestGroup returns null outside silhouette and detects groups inside', () {
      const canvasSize = Size(400, 320);
      expect(
        RiderFatigueBodyHeatmapPainter.hitTestGroup(const Offset(5, 5), canvasSize),
        isNull,
      );

      // Sprawdź czy wszystkie 5 grup mają osiągalne regiony trafienia
      final foundGroups = <BodyFatigueGroup>{};
      for (double x = 0; x < canvasSize.width; x += 6) {
        for (double y = 0; y < canvasSize.height; y += 6) {
          final hit = RiderFatigueBodyHeatmapPainter.hitTestGroup(
            Offset(x, y),
            canvasSize,
          );
          if (hit != null) {
            foundGroups.add(hit);
          }
        }
      }
      expect(foundGroups, containsAll(BodyFatigueGroup.values));
    });

    testWidgets('renders without overflow at 390x844, 1024x768 and 1600x900', (
      tester,
    ) async {
      const profile = RiderMuscleFatigueProfile(
        quadriceps: 0.88,
        calves: 0.62,
        glutes: 0.74,
        lumbarSpine: 0.41,
        centralNervousSystem: 0.91,
      );

      for (final viewportSize in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        tester.view.physicalSize = viewportSize;
        tester.view.devicePixelRatio = 1.0;

        BodyFatigueGroup? selected;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: AppColors.background,
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: RiderFatigueBodyHeatmapWidget(
                  profile: profile,
                  riderName: 'Tadej Pogačar',
                  onGroupSelected: (g) => selected = g,
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(find.text('Czworogłowe uda'), findsWidgets);
        expect(find.text('Układ nerwowy (CNS)'), findsWidgets);

        await tester.tap(find.text('Pośladki').first);
        await tester.pump(const Duration(milliseconds: 100));
        expect(selected, BodyFatigueGroup.glutes);
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('disabled state prevents selection callbacks', (tester) async {
      BodyFatigueGroup? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RiderFatigueBodyHeatmapWidget(
                profile: const RiderMuscleFatigueProfile.fresh(),
                enabled: false,
                onGroupSelected: (g) => selected = g,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Łydki').first);
      await tester.pump();
      expect(selected, isNull);
    });
  });
}
