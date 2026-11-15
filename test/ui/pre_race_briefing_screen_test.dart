import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/services/generators/stage_profile_builder.dart';
import 'package:pro_peloton_manager/ui/screens/pre_race_briefing_screen.dart';
import 'package:pro_peloton_manager/ui/screens/team_bus_locker_room_screen.dart';
import 'package:pro_peloton_manager/ui/widgets/mechanic_workshop_panel.dart';

void main() {
  RaceStage buildTestStage() {
    return StageProfileBuilder.buildHighMountainStage(
      id: 'test_briefing_stage',
      stageNumber: 14,
      name: 'Pau > Tourmalet',
      distanceKm: 152.0,
      climbs: [StageProfileBuilder.tourmalet],
      baseTemperatureCelsius: 19.0,
      weatherCondition: WeatherCondition.overcast,
      windSpeedKmh: 24.0,
    );
  }

  Widget buildTestApp(Size size) {
    return ProviderScope(
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
          home: PreRaceBriefingScreen(
            stage: buildTestStage(),
            isStandalone: true,
          ),
        ),
      ),
    );
  }

  testWidgets('PreRaceBriefingScreen 4-step flow works end-to-end on 1600x900',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(const Size(1600, 900)));
    await tester.pumpAndSettle();

    // Krok 1: Trasa, Pogoda Górska (#151) i Rekonesans (#140)
    expect(find.text('1. Trasa & Pogoda'), findsOneWidget);
    expect(find.text('POGODA GÓRSKA & MIKROKLIMAT (#151)'), findsOneWidget);
    expect(find.text('REKONESANS TRASY (#140)'), findsOneWidget);

    // Przejście do Kroku 2: Warsztat Mechanika (#134)
    await tester.tap(find.text('Następny Krok'));
    await tester.pumpAndSettle();

    expect(find.byType(MechanicWorkshopPanel), findsOneWidget);
    expect(find.text('Zastosuj Optymalny Setup Mechanika'), findsOneWidget);

    await tester.tap(find.text('Zastosuj Optymalny Setup Mechanika'));
    await tester.pumpAndSettle();
    expect(find.text('OPTYMALNY SETUP MECHANIKA AKTYWNY'), findsOneWidget);

    // Przejście do Kroku 3: Autobus Drużyny (#188) & Role Taktyczne
    await tester.tap(find.text('3. Autobus & Role'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TeamBusLockerRoomScreen), findsOneWidget);
    expect(find.text('WYZNACZENIE RÓL TAKTYCZNYCH:'), findsOneWidget);

    // Przejście do Kroku 4: Start Honorowy KM 0.0
    await tester.tap(find.text('4. Start Honorowy'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text('WYJAZD NA START HONOROWY (KM 0.0) -> WIDOK 3D'),
      findsAtLeastNWidgets(1),
    );
  });

  for (final size in const [
    Size(390, 844),
    Size(1024, 768),
    Size(1600, 900),
  ]) {
    testWidgets(
        'PreRaceBriefingScreen renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(size));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Przejście przez wszystkie 4 kroki na danej rozdzielczości
      for (final stepLabel in [
        '1. Trasa & Pogoda',
        '2. Warsztat Mechanika',
        '3. Autobus & Role',
        '4. Start Honorowy',
      ]) {
        final stepFinder = find.text(stepLabel);
        if (stepFinder.evaluate().isNotEmpty) {
          await tester.tap(stepFinder.first);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
        } else {
          final nextBtn = find.text('Dalej');
          if (nextBtn.evaluate().isNotEmpty) {
            await tester.tap(nextBtn);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
          }
        }
      }

      expect(tester.takeException(), isNull);
    });
  }
}
