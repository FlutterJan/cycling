import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/screens/golden_era_retro_campaigns_screen.dart';

void main() {
  Future<void> pumpAtSize(
    WidgetTester tester,
    Size size, {
    int initialYear = 1976,
    ValueChanged<GoldenEraRaceSimulationOutcome>? onRaceSimulated,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: GoldenEraRetroCampaignsScreen(
          initialYear: initialYear,
          onRaceSimulated: onRaceSimulated,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('renders without overflow at 390x844, 1024x768, 1600x900', (
    tester,
  ) async {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      await pumpAtSize(tester, size);
      expect(find.byType(GoldenEraRetroCampaignsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('simulates historical race and updates prestige and progress', (
    tester,
  ) async {
    GoldenEraRaceSimulationOutcome? capturedOutcome;
    await pumpAtSize(
      tester,
      const Size(1600, 900),
      onRaceSimulated: (outcome) => capturedOutcome = outcome,
    );

    expect(find.text('0 PTS'), findsOneWidget);
    expect(find.text('Kalendarz Historyczny (0/4)'), findsOneWidget);

    final startRaceBtn = find.text('Rozpocznij Wyścig').first;
    await tester.ensureVisible(startRaceBtn);
    await tester.tap(startRaceBtn);
    await tester.pump(const Duration(milliseconds: 300));

    expect(capturedOutcome, isNotNull);
    expect(find.text('Kalendarz Historyczny (1/4)'), findsOneWidget);
    expect(find.text('0 PTS'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches mobile tabs and creates custom 1984 campaign', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(390, 844));

    // Switch to Garage & RPE tab
    await tester.tap(find.text('Garaż & RPE'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Garaż Stalowy & Koszulka Wełniana'), findsOneWidget);
    expect(find.text('Percepcja RPE (Borg 6–20) & Manetki'), findsOneWidget);

    // Switch to 3D Cinema tab
    await tester.tap(find.text('Kino 3D'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Kino Archiwalne 3D'), findsOneWidget);

    // Back to Campaign tab and activate
    await tester.tap(find.text('Kampania'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Aktywuj Kampanię'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Aktywowano kampanię'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
