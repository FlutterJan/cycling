import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/screens/credits_and_architecture_showcase_screen.dart';

void main() {
  group('ArchitectureShowcaseCalculator', () {
    test('Skiba W\' depletes linearly above CP and recovers exponentially below CP', () {
      final depletion = ArchitectureShowcaseCalculator.computeSkibaWPrime(
        wPrimeJoules: 22000,
        criticalPowerWatts: 380,
        powerWatts: 480,
        durationSeconds: 50,
        initialFraction: 1.0,
      );
      expect(depletion.isDepleting, isTrue);
      expect(depletion.remainingJoules, closeTo(17000, 1e-6));

      final recovery = ArchitectureShowcaseCalculator.computeSkibaWPrime(
        wPrimeJoules: 22000,
        criticalPowerWatts: 380,
        powerWatts: 250,
        durationSeconds: 120,
        initialFraction: 0.5,
      );
      expect(recovery.isDepleting, isFalse);
      expect(recovery.remainingJoules, greaterThan(11000));
      expect(recovery.tauSeconds, greaterThan(316));
    });

    test('Martin cycling power computes aero, gravity, rolling, and total watts', () {
      final flat = ArchitectureShowcaseCalculator.computeMartinPower(
        riderMassKg: 68,
        velocityKmh: 45,
        gradePercent: 0,
      );
      expect(flat.aeroWatts, greaterThan(250));
      expect(flat.gravityWatts, closeTo(0, 1e-6));
      expect(flat.rollingWatts, greaterThan(20));
      expect(flat.totalWatts, greaterThan(flat.aeroWatts + flat.rollingWatts));

      final climb = ArchitectureShowcaseCalculator.computeMartinPower(
        riderMassKg: 68,
        velocityKmh: 20,
        gradePercent: 8,
      );
      expect(climb.gravityWatts, greaterThan(300));
      expect(climb.wattsPerKg, greaterThan(4.5));
    });

    test('Boids separation magnitude is positive inside 1.85x0.65 ellipse and 0 outside', () {
      final inside = ArchitectureShowcaseCalculator.computeBoidsSeparationMagnitude(
        dxLongitudinalMeters: 0.8,
        dyLateralMeters: 0.2,
      );
      expect(inside, greaterThan(0.0));
      expect(inside, lessThanOrEqualTo(1.0));

      final outside = ArchitectureShowcaseCalculator.computeBoidsSeparationMagnitude(
        dxLongitudinalMeters: 2.2,
        dyLateralMeters: 0.8,
      );
      expect(outside, equals(0.0));
    });
  });

  group('CreditsAndArchitectureShowcaseScreen Widget & Responsive Tests', () {
    Future<void> pumpShowcase(
      WidgetTester tester, {
      required Size size,
      VoidCallback? onBack,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: CreditsAndArchitectureShowcaseScreen(onBack: onBack),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final viewport in const [
      (name: '390x844 mobile', size: Size(390, 844)),
      (name: '1024x768 tablet', size: Size(1024, 768)),
      (name: '1600x900 desktop', size: Size(1600, 900)),
    ]) {
      testWidgets('renders without overflow at ${viewport.name}', (tester) async {
        await pumpShowcase(tester, size: viewport.size);

        expect(
          find.text('Silnik Naukowy, Pipeline 3D & Podziękowania'),
          findsOneWidget,
        );
        expect(find.text('Model Skiby W\' (W\'bal)'), findsWidgets);
        expect(
          find.text('Proceduralny Pipeline Blender 5.3 → .glb'),
          findsOneWidget,
        );
        expect(
          find.text('Podziękowania, Inspiracje Naukowe & Stack Technologiczny'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('switches models, pipeline stages, filters, and compact mode', (tester) async {
      var backCalled = false;
      await pumpShowcase(
        tester,
        size: const Size(1600, 900),
        onBack: () => backCalled = true,
      );

      // Switch to Martin Cycling Power model
      await tester.tap(find.text('Równania Martina dla Mocy Kolarskiej').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('KALKULATOR MARTINA (68 kg + 6.8 kg, CdA 0.245)'),
        findsOneWidget,
      );

      // Switch to Boids model
      await tester.tap(find.text('Algorytm Boids & Spatial Hash').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('POLE SEPARACJI BOIDS (1.85 m × 0.65 m)'),
        findsOneWidget,
      );

      // Switch to Blender .glb model and select stage 3
      await tester.tap(find.text('Proceduralny Pipeline Blender .glb').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('AKTYWNY ETAP PIPELINE\'U BLENDER .GLB'),
        findsOneWidget,
      );

      final stage3Chip = find.text('3. Materiały PBR & Wypalanie Koszulek');
      await tester.ensureVisible(stage3Chip);
      await tester.tap(stage3Chip);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Etap 3: Materiały PBR & Wypalanie Koszulek'),
        findsOneWidget,
      );

      // Toggle compact mode
      final compactChip = find.text('Tryb kompaktowy');
      await tester.ensureVisible(compactChip);
      await tester.tap(compactChip);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Pokaż równania'), findsOneWidget);

      // Filter to Credits only
      final creditsChip = find.text('Podziękowania & Stack');
      await tester.ensureVisible(creditsChip);
      await tester.tap(creditsChip);
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.text('Dr Philip Skiba & Prof. James C. Martin'),
        findsOneWidget,
      );

      // Trigger back button
      final backChip = find.text('Powrót');
      await tester.ensureVisible(backChip);
      await tester.tap(backChip);
      await tester.pump(const Duration(milliseconds: 100));
      expect(backCalled, isTrue);
    });
  });
}
