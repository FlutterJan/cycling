import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/services/career/pre_season_wind_tunnel_camp_event.dart';
import 'package:pro_peloton_manager/ui/screens/winter_wind_tunnel_camp_screen.dart';

void main() {
  Widget buildTestApp({
    bool isReadOnly = false,
    ValueChanged<PreSeasonWindTunnelCampOutcome>? onCampCompleted,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: WinterWindTunnelCampScreen(
          seasonYear: 2027,
          teamBudgetEur: 250000,
          isReadOnly: isReadOnly,
          onCampCompleted: onCampCompleted,
        ),
      ),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    Size size, {
    bool isReadOnly = false,
    ValueChanged<PreSeasonWindTunnelCampOutcome>? onCampCompleted,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestApp(
        isReadOnly: isReadOnly,
        onCampCompleted: onCampCompleted,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  test('WinterWindTunnelCampTelemetry computes drag force in Newtons at 50 km/h',
      () {
    // At 50 km/h (13.8889 m/s), rho = 1.225, CdA = 0.240:
    // F = 0.5 * 1.225 * 0.240 * (50/3.6)^2 ≈ 28.356 N
    final dragN = WinterWindTunnelCampTelemetry.computeDragForceNewtons(
      cdaM2: 0.240,
      speedKmh: 50.0,
    );
    expect(dragN, closeTo(28.36, 0.05));
    expect(
      WinterWindTunnelCampTelemetry.computeDragForceNewtons(cdaM2: 0.0),
      0.0,
    );
  });

  testWidgets('responsive layout passes at 390x844, 1024x768, and 1600x900',
      (tester) async {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      await pumpScreen(tester, size);
      expect(find.byType(WinterWindTunnelCampScreen), findsOneWidget);
      expect(
        find.textContaining('Grudniowy Obóz Aerodynamiczny 2027'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'full interactive flow: rider selection, 50 km/h Newton measurements, and watts saved report',
      (tester) async {
    PreSeasonWindTunnelCampOutcome? outcome;
    await pumpScreen(
      tester,
      const Size(1600, 900),
      onCampCompleted: (res) => outcome = res,
    );

    expect(find.textContaining('Dobór Zawodników do Sesji'), findsOneWidget);

    // Select a different wind tunnel facility
    final a2Finder = find.text('A2 Wind Tunnel (Mooresville)');
    await tester.ensureVisible(a2Finder);
    await tester.tap(a2Finder);
    await tester.pump(const Duration(milliseconds: 250));

    // Proceed to testing sessions
    final proceedFinder = find.textContaining('Rozpocznij Sesje Testowe');
    await tester.ensureVisible(proceedFinder);
    await tester.tap(proceedFinder);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify 50 km/h Newton drag measurements & airflow painter
    expect(
      find.textContaining('Pomiary Oporu w Tunelu przy 50 km/h'),
      findsOneWidget,
    );
    expect(find.textContaining('Opór Bazowy (50 km/h)'), findsOneWidget);
    expect(find.textContaining('Zaoszczędzone Waty (50 km/h)'), findsAtLeastNWidgets(1));

    // Validate all riders on track
    final validateAllFinder = find.text('Waliduj Wszystkich na Torze');
    await tester.ensureVisible(validateAllFinder);
    await tester.tap(validateAllFinder);
    await tester.pump(const Duration(milliseconds: 250));

    // Finalize camp and check report
    final finalizeFinder = find.textContaining('Zatwierdź Obóz');
    await tester.ensureVisible(finalizeFinder);
    await tester.tap(finalizeFinder);
    await tester.pump(const Duration(milliseconds: 300));

    expect(outcome, isNotNull);
    expect(outcome!.riderResults, hasLength(6));
    expect(outcome!.totalWattsSavedAt50Kmh, greaterThan(0.0));
    expect(
      find.textContaining('Raport Zaoszczędzonych Watów'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders read-only banner and disables mutations when isReadOnly',
      (tester) async {
    await pumpScreen(tester, const Size(1024, 768), isReadOnly: true);

    expect(find.textContaining('Tryb tylko do odczytu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
