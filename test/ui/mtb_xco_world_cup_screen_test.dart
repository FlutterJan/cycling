import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/mtb_suspension_damping_and_line_choice_solver.dart';
import 'package:pro_peloton_manager/models/race/mtb_xco_course_and_suspension_model.dart';
import 'package:pro_peloton_manager/ui/screens/mtb_xco_world_cup_screen.dart';

void main() {
  group('MtbXcoWorldCupCatalog & MtbXcoRaceSimulator', () {
    test('catalog contains 6 World Cup / Championship rounds', () {
      final rounds = MtbXcoWorldCupCatalog.buildCalendar();
      expect(rounds.length, 6);
      expect(rounds.first.id, 'nove_mesto');
      expect(rounds.last.id, 'lenzerheide_xcc');
      for (final r in rounds) {
        expect(r.course.segments, isNotEmpty);
        expect(r.course.lapDistanceKm, greaterThan(1.0));
      }
    });

    test('simulateRace produces valid standings and UCI points', () {
      final round = MtbXcoWorldCupCatalog.buildCalendar().first;
      final rec =
          MtbSuspensionDampingAndLineChoiceSolver.recommendOptimalSetup(
        course: round.course,
        riderMassKg: 68.0,
      );
      final config = MtbXcoBikeConfiguration(
        bikeId: 'test_xco',
        modelName: 'Test XCO 120',
        suspension: MtbForkAndShockSetup(
          forkTravelMm: rec.recommendedTravelMm,
          rearShockTravelMm: 120,
          forkAirPressurePsi: rec.recommendedForkPsi,
          rearShockAirPressurePsi: rec.recommendedRearShockPsi,
          forkReboundClicks: rec.recommendedForkReboundClicks,
          rearReboundClicks: rec.recommendedRearReboundClicks,
        ),
        tireSetup: MtbTire24Setup(
          widthInches: 2.4,
          treadPattern: rec.recommendedTreadPattern,
          frontPressureBar: rec.recommendedFrontTireBar,
          rearPressureBar: rec.recommendedRearTireBar,
          hasRimInsert: true,
        ),
      );

      final report = MtbXcoRaceSimulator.simulateRace(
        round: round,
        bikeConfig: config,
        soilCondition: round.course.soilCondition,
        riderMassKg: 68.0,
        riderPowerWatts: 375.0,
        bikeHandling: 88.0,
        linePolicy: MtbLineTacticalPolicy.balancedExpectedValue,
      );

      expect(report.standings.length, 13);
      expect(report.playerPosition, inInclusiveRange(1, 13));
      expect(report.uciPointsEarned, greaterThan(0));
      expect(report.standings.first.gapSeconds, 0.0);
    });
  });

  group('MtbXcoWorldCupScreen responsive & interaction tests', () {
    Future<void> pumpScreenAtSize(
      WidgetTester tester,
      Size size, {
      bool isReadOnly = false,
      bool show3dPreview = true,
      ValueChanged<MtbXcoRaceSimulationReport>? onRaceCompleted,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: MtbXcoWorldCupScreen(
            isReadOnly: isReadOnly,
            show3dPreview: show3dPreview,
            onRaceCompleted: onRaceCompleted,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders without overflow at 390x844 (mobile)', (tester) async {
      await pumpScreenAtSize(tester, const Size(390, 844));
      expect(tester.takeException(), isNull);
      expect(find.text('Puchar Świata MTB XCO'), findsOneWidget);
      expect(find.text('Konfigurator Widelca i Dampera'), findsOneWidget);

      await tester.tap(find.text('Kalendarz i Trasa'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('Nové Město na Moravě'), findsOneWidget);

      await tester.tap(find.text('Telemetria i Wyścig'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('Telemetria Fizyki i Gotowości XCO'), findsOneWidget);
    });

    testWidgets('renders without overflow at 1024x768 (tablet)', (tester) async {
      await pumpScreenAtSize(tester, const Size(1024, 768));
      expect(tester.takeException(), isNull);
      expect(find.text('Konfigurator Opon 2.4" i Sztycy Dropper'), findsOneWidget);
    });

    testWidgets('renders 3-column bento without overflow at 1600x900 (desktop)',
        (tester) async {
      MtbXcoRaceSimulationReport? receivedReport;
      await pumpScreenAtSize(
        tester,
        const Size(1600, 900),
        onRaceCompleted: (r) => receivedReport = r,
      );
      expect(tester.takeException(), isNull);

      expect(find.text('Kalendarz Pucharu Świata XCO'), findsOneWidget);
      expect(find.text('Konfigurator Widelca i Dampera'), findsOneWidget);
      expect(find.text('Telemetria Fizyki i Gotowości XCO'), findsOneWidget);

      await tester.tap(find.text('Auto-Optymalizuj'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Hardtail (100 mm przód)'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Ciśnienie dampera (Brak w Hardtailu)'), findsOneWidget);

      final simBtn = find.textContaining('Symuluj Wyścig PŚ XCO');
      await tester.ensureVisible(simBtn);
      await tester.tap(simBtn);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(receivedReport, isNotNull);
      expect(find.textContaining('Wyniki Wyścigu'), findsOneWidget);
    });

    testWidgets('isReadOnly disables interactions cleanly', (tester) async {
      MtbXcoRaceSimulationReport? receivedReport;
      await pumpScreenAtSize(
        tester,
        const Size(1600, 900),
        isReadOnly: true,
        show3dPreview: false,
        onRaceCompleted: (r) => receivedReport = r,
      );

      expect(find.text('Tylko podgląd'), findsOneWidget);
      final simBtn = find.textContaining('Symuluj Wyścig PŚ XCO');
      await tester.ensureVisible(simBtn);
      await tester.tap(simBtn);
      await tester.pump(const Duration(milliseconds: 200));
      expect(receivedReport, isNull);
    });
  });
}
