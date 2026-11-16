import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_peloton_manager/ui/widgets/animated_screen_transition_router.dart';

void main() {
  group('AnimatedScreenTransitionRouter', () {
    testWidgets('manager routes use 300ms SharedAxisTransition in GoRouter',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/manager/a',
        routes: [
          GoRoute(
            path: '/manager/a',
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildManagerPage(
              state: state,
              child: Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => context.go('/manager/b'),
                    child: const Text('Idź do Kadry'),
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/manager/b',
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildManagerPage(
              state: state,
              axis: SharedAxisDirection.vertical,
              child: const Scaffold(
                body: Center(child: Text('Panel Kadry')),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Idź do Kadry'), findsOneWidget);

      await tester.tap(find.text('Idź do Kadry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Panel Kadry'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Panel Kadry'), findsOneWidget);
    });

    testWidgets(
        'briefing to 3D race route performs aerial-to-road camera dive transition',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/briefing',
        routes: [
          GoRoute(
            path: '/briefing',
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildManagerPage(
              state: state,
              child: Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => context.go('/race-3d'),
                    child: const Text('Start Etapu'),
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/race-3d',
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildRaceDivePage(
              state: state,
              stageLabel: 'ETAP 18 • COL DU GALIBIER',
              subtitle: 'NAJAZD Z LOTU PTAKA',
              child: const Scaffold(
                body: Center(child: Text('Viewport Wyścigu 3D')),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Start Etapu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Viewport Wyścigu 3D'), findsOneWidget);
      expect(find.byType(Transform), findsWidgets);

      await tester.pump(const Duration(milliseconds: 650));
      expect(find.text('Viewport Wyścigu 3D'), findsOneWidget);
    });

    testWidgets('buildPageForPreset handles all presets including instant',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/podium',
        routes: [
          GoRoute(
            path: '/podium',
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildPageForPreset(
              state: state,
              preset: ScreenTransitionPreset.podiumCeremonyReveal,
              child: Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => context.go('/instant'),
                    child: const Text('Podium Gotowe'),
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/instant',
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildPageForPreset(
              state: state,
              preset: ScreenTransitionPreset.instant,
              child: const Scaffold(
                body: Center(child: Text('Ekran Natychmiastowy')),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Podium Gotowe'), findsOneWidget);

      await tester.tap(find.text('Podium Gotowe'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Ekran Natychmiastowy'), findsOneWidget);
    });

    testWidgets('respects MediaQuery disableAnimations for reduced motion',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/start',
        routes: [
          GoRoute(
            path: '/start',
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildRaceDivePage(
              state: state,
              child: const Scaffold(
                body: Center(child: Text('Widok Reduced Motion')),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Widok Reduced Motion'), findsOneWidget);
    });
  });

  group('ScreenTransitionPreviewPanel', () {
    testWidgets('interactive states: preset switch, hover, reduced motion, launch',
        (tester) async {
      ScreenTransitionPreset? lastPreset;
      bool launched = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ScreenTransitionPreviewPanel(
                onPresetSelected: (preset) => lastPreset = preset,
                onLaunchRacePressed: () => launched = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Router Przejść Ekranowych 3D & UI'), findsOneWidget);
      expect(find.text('LOT PTAKA -> 3D • 850 ms'), findsOneWidget);

      // Hover over replay button
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Odtwórz Przejście')));
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to SharedAxis Horizontal (300 ms)
      await tester.tap(find.text('Poziomy'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(lastPreset, ScreenTransitionPreset.managerSharedAxisHorizontal);
      expect(find.text('POZIOMY • 300 ms'), findsOneWidget);

      // Toggle Reduced Motion
      await tester.tap(find.text('Animacje: 120 FPS'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Reduced Motion: ON'), findsOneWidget);
      expect(find.text('POZIOMY • 120 ms'), findsOneWidget);

      // Tap Launch Race 3D
      await tester.tap(find.text('Start Wyścigu 3D'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(launched, isTrue);
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: ScreenTransitionPreviewPanel(
                  onLaunchRacePressed: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.text('Router Przejść Ekranowych 3D & UI'), findsOneWidget);
      });
    }
  });
}
