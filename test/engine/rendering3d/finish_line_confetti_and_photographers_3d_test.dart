import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/finish_line_confetti_and_photographers_3d.dart';

void main() {
  group('FinishLineConfettiAndPhotographers3dEngine', () {
    test('initializes photographers, soigneurs, riders and confetti', () {
      final engine = FinishLineConfettiAndPhotographers3dEngine(
        config: const FinishLineZoneConfig(
          photographerCount: 16,
          soigneurCount: 12,
        ),
      );

      expect(engine.photographers.length, 16);
      expect(engine.soigneurs.length, 12);
      expect(engine.riders, isNotEmpty);
      expect(engine.confetti, isNotEmpty);
    });

    test('confetti particles fall under gravity and settle on asphalt', () {
      final engine = FinishLineConfettiAndPhotographers3dEngine(
        config: const FinishLineZoneConfig(maxConfettiParticles: 150),
      );
      engine.triggerConfettiCannonBurst(count: 60);

      for (int i = 0; i < 240; i++) {
        engine.step(0.04);
      }

      final telemetry = engine.telemetry;
      expect(telemetry.settledConfettiCount, greaterThan(0));
    });

    test('triggering flash volley increases flash count and decays over time', () {
      final engine = FinishLineConfettiAndPhotographers3dEngine();
      final int before = engine.totalFlashesTriggered;

      engine.triggerPhotographerFlashVolley(bursts: 5);
      expect(engine.totalFlashesTriggered, before + 5);
      expect(engine.flashes.length, 5);

      final CameraFlashBurst3D firstBurst = engine.flashes.first;
      expect(firstBurst.currentIntensity, greaterThan(0.8));
      final CameraFlashBurst3D expired = firstBurst.advance(0.4);
      expect(expired.isExpired, isTrue);
      expect(expired.currentIntensity, 0.0);
    });

    test('winner crossing finish line automatically triggers confetti and flashes', () {
      final engine = FinishLineConfettiAndPhotographers3dEngine();
      final int initialFlashes = engine.totalFlashesTriggered;

      // Symulujemy dojazd lidera z -6 m za linię mety
      for (int i = 0; i < 35; i++) {
        engine.step(0.03);
      }

      expect(engine.telemetry.winnerDistanceMeters, greaterThan(0.0));
      expect(engine.totalFlashesTriggered, greaterThan(initialFlashes));
    });
  });

  group('FinishLineConfettiAndPhotographers3dPanel responsive UI', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FinishLineConfettiAndPhotographers3dPanel(autoPlay: false),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders without overflow at 390x844 (mobile)', (tester) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(find.text('META 3D'), findsOneWidget);
      expect(find.text('Armata Konfetti'), findsOneWidget);
    });

    testWidgets('renders without overflow at 1024x768 (tablet)', (tester) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.text('FINAŁ ETAPU • LINIA METY'), findsOneWidget);
      expect(find.text('Opiekunowie'), findsOneWidget);
    });

    testWidgets('renders without overflow at 1600x900 (desktop)', (tester) async {
      await pumpAtSize(tester, const Size(1600, 900));
      expect(find.text('STREFY METY 3D'), findsOneWidget);
      expect(find.text('Flesze Prasy'), findsOneWidget);
    });

    testWidgets('interactive buttons trigger confetti, flashes and camera switch',
        (tester) async {
      await pumpAtSize(tester, const Size(1600, 900));

      await tester.tap(find.text('Opiekunowie'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Armata Konfetti'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Flesze Prasy'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Wznów Symulację'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Pauza Symulacji'), findsOneWidget);
    });
  });
}
