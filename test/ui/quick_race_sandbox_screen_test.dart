import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/router/app_router.dart';
import 'package:pro_peloton_manager/state/race_simulation_notifier.dart';
import 'package:pro_peloton_manager/ui/screens/quick_race_sandbox_screen.dart';
import 'package:pro_peloton_manager/ui/screens/race_3d_viewport_widget.dart';
import 'package:pro_peloton_manager/ui/widgets/elevation_profile_chart.dart';

void main() {
  Future<void> pumpSandboxAtSize(
    WidgetTester tester,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: QuickRaceSandboxScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('QuickRaceSandboxScreen renders cleanly on 1600x900 desktop',
      (tester) async {
    await pumpSandboxAtSize(tester, const Size(1600, 900));

    expect(find.byType(ElevationProfileChart), findsOneWidget);
    expect(find.text("Alpe d'Huez Summit Finish"), findsWidgets);
    expect(find.text('Paryż-Roubaix 5-Star Cobbles'), findsOneWidget);
    expect(find.text('Champs-Élysées Sprint'), findsOneWidget);
    expect(find.text('Wachlarze w Katarze 50 km/h Crosswind'), findsOneWidget);
    expect(find.text('Górska Czasówka ITT'), findsOneWidget);
    expect(find.text('Auto-Pick Optimal Roster'), findsOneWidget);
    expect(find.text('Full Aero 65mm'), findsOneWidget);
    expect(find.text('Ultralight Climbing 6.8kg'), findsWidgets);
    expect(find.text('Cobble Tubeless 32mm 3.8 bar'), findsOneWidget);
    expect(find.text('START SYMULACJI 3D'), findsOneWidget);
  });

  testWidgets('QuickRaceSandboxScreen renders cleanly on 1024x768 tablet',
      (tester) async {
    await pumpSandboxAtSize(tester, const Size(1024, 768));

    expect(find.byType(ElevationProfileChart), findsOneWidget);
    expect(find.text('Auto-Pick Optimal Roster'), findsOneWidget);
    expect(find.text('START SYMULACJI 3D'), findsOneWidget);
  });

  testWidgets('QuickRaceSandboxScreen collapses to tabs on 390x844 mobile',
      (tester) async {
    await pumpSandboxAtSize(tester, const Size(390, 844));

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Trasa'), findsOneWidget);
    expect(find.text('Skład (8)'), findsOneWidget);
    expect(find.text('Sprzęt 3D'), findsOneWidget);
    expect(find.text('START SYMULACJI 3D'), findsOneWidget);

    await tester.tap(find.text('Skład (8)'));
    await tester.pumpAndSettle();
    expect(find.text('Auto-Pick Optimal Roster'), findsOneWidget);

    await tester.tap(find.text('Sprzęt 3D'));
    await tester.pumpAndSettle();
    expect(find.text('Full Aero 65mm'), findsOneWidget);
  });

  testWidgets(
      'Selecting presets, weather, bike and starting 3D simulation initializes RaceSimulationNotifier',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = createAppRouter(initialLocation: AppRoutes.quickRaceSandbox);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Wybierz preset Paryż-Roubaix i przetestuj Auto-Pick oraz sprzęt
    await tester.tap(find.text('Paryż-Roubaix 5-Star Cobbles'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Auto-Pick Optimal Roster'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cobble Tubeless 32mm 3.8 bar'));
    await tester.pumpAndSettle();

    // Uruchom symulację 3D
    await tester.tap(find.text('START SYMULACJI 3D'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final simState = container.read(raceSimulationProvider);
    expect(simState.simulationState, isNotNull);
    expect(simState.simulationState!.stage.name, 'Paryż-Roubaix 5-Star Cobbles');
    expect(find.byType(Race3DViewportWidget), findsOneWidget);

    // Zatrzymaj ticker i posprzątaj przed zakończeniem testu
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
}
