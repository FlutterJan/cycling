import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/team_sprint_train_echelon_diagonal_formation.dart';
import 'package:pro_peloton_manager/ui/widgets/gutter_wind_protection_diagram_hud.dart';

void main() {
  group('GutterWindProtectionDiagramData & GutterDiagramRiderNode', () {
    test('serializuje i deserializuje JSON oraz normalizuje wartości NaN/Infinity', () {
      final GutterWindProtectionDiagramData sample =
          GutterWindProtectionDiagramData.sample();
      final Map<String, dynamic> json = sample.toJson();
      final GutterWindProtectionDiagramData restored =
          GutterWindProtectionDiagramData.fromJson(json);

      expect(restored.sectorLabel, sample.sectorLabel);
      expect(restored.crosswindKmh, sample.crosswindKmh);
      expect(restored.diagonalAngleDegrees, sample.diagonalAngleDegrees);
      expect(restored.isGutterClosed, isTrue);
      expect(restored.teamNodes.length, sample.teamNodes.length);
      expect(restored.rivalNodes.length, sample.rivalNodes.length);
      expect(restored.gutterTrappedCount, 2);
      expect(restored.averageTeamDraftSavingsPercent, closeTo(33.4, 0.2));

      const GutterWindProtectionDiagramData invalid =
          GutterWindProtectionDiagramData(
        sectorLabel: 'Invalid',
        crosswindKmh: double.nan,
        windAngleDegrees: double.infinity,
        crosswindSide: CrosswindSide.rightToLeft,
        roadWidthMeters: -4.0,
        diagonalAngleDegrees: double.nan,
        maxShelteredCapacity: 0,
        formationMode: DiagonalTrainFormationMode.standardInline,
        phase: DiagonalTrainPhase.positioning,
        isGutterClosed: false,
        curbGapMeters: double.negativeInfinity,
      );
      expect(invalid.safeCrosswindKmh, 0.0);
      expect(invalid.safeWindAngleDegrees, 0.0);
      expect(invalid.safeRoadWidthMeters, 2.5);
      expect(invalid.safeDiagonalAngleDegrees, 0.0);
      expect(invalid.safeCurbGapMeters, 0.0);
    });

    test('konwertuje wynik z TeamSprintTrainEchelonDiagonalFormation', () {
      final DiagonalEchelonEvaluation eval =
          TeamSprintTrainEchelonDiagonalFormation.evaluateDiagonalFormation(
        context: const DiagonalTrainWindContext(
          windSpeedKmh: 38.0,
          windAngleDegrees: 75.0,
          crosswindSide: CrosswindSide.leftToRight,
          roadWidthMeters: 6.0,
          distanceToFinishMeters: 1600.0,
          targetTrainSpeedKmh: 58.0,
        ),
        mode: DiagonalTrainFormationMode.aggressiveGutterPress,
        teamTrain: const <EchelonTrainRiderInput>[
          EchelonTrainRiderInput(
            riderId: 'p1',
            name: 'Lead 1',
            teamId: 'PPM',
            isPlayerTeam: true,
            isSprinter: false,
            roleOrder: 0,
            flatSkill: 85,
            sprintSkill: 72,
            bikeHandling: 82,
            raceIq: 84,
            draftingEfficiency: 85,
            ftpWatts: 430,
            wPrimeRemainingJoules: 19000,
            wPrimeMaxJoules: 21000,
          ),
          EchelonTrainRiderInput(
            riderId: 'p2',
            name: 'Sprinter',
            teamId: 'PPM',
            isPlayerTeam: true,
            isSprinter: true,
            roleOrder: 1,
            flatSkill: 80,
            sprintSkill: 92,
            bikeHandling: 86,
            raceIq: 84,
            draftingEfficiency: 88,
            ftpWatts: 405,
            wPrimeRemainingJoules: 22000,
            wPrimeMaxJoules: 24000,
          ),
        ],
        rivalContenders: const <EchelonTrainRiderInput>[
          EchelonTrainRiderInput(
            riderId: 'r1',
            name: 'Rival',
            teamId: 'SOQ',
            isPlayerTeam: false,
            isSprinter: true,
            roleOrder: 0,
            flatSkill: 78,
            sprintSkill: 89,
            bikeHandling: 78,
            raceIq: 79,
            draftingEfficiency: 76,
            ftpWatts: 390,
            wPrimeRemainingJoules: 15000,
            wPrimeMaxJoules: 20000,
          ),
        ],
      );

      final GutterWindProtectionDiagramData hudData =
          GutterWindProtectionDiagramData.fromEvaluation(eval);

      expect(hudData.teamNodes.length, 2);
      expect(hudData.rivalNodes.length, 1);
      expect(hudData.formationMode,
          DiagonalTrainFormationMode.aggressiveGutterPress);
      expect(hudData.safeCrosswindKmh, greaterThan(30.0));
    });
  });

  group('GutterWindProtectionDiagramHud Widget', () {
    Widget buildHarness({
      required GutterWindProtectionDiagramData data,
      bool enabled = true,
      bool initiallyExpanded = true,
      ValueChanged<DiagonalTrainFormationMode>? onFormationModeChanged,
      ValueChanged<GutterDiagramRiderNode>? onRiderSelected,
      Size surfaceSize = const Size(1024, 768),
    }) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0F1115),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: surfaceSize.width - 24,
                child: GutterWindProtectionDiagramHud(
                  data: data,
                  enabled: enabled,
                  initiallyExpanded: initiallyExpanded,
                  onFormationModeChanged: onFormationModeChanged,
                  onRiderSelected: onRiderSelected,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('wyświetla diagram schodkowy, telemetrię i inspektora kolarza',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildHarness(data: GutterWindProtectionDiagramData.sample()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('OCHRONA WIATRU BOCZNEGO'), findsOneWidget);
      expect(
        find.text('De Moeren — Otwarte Poldery (1.8 km do mety)'),
        findsOneWidget,
      );
      expect(find.text('RYNSZTOK ZAMKNIĘTY'), findsOneWidget);
      expect(find.text('36.4 km/h'), findsOneWidget);
      expect(find.text('26.5°'), findsOneWidget);
      expect(find.text('O. Kooij (PPM)'), findsOneWidget);
    });

    testWidgets('obsługuje stan pusty bez aktywnego wachlarza',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildHarness(data: GutterWindProtectionDiagramData.empty()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Brak aktywnego wachlarza — formacja w oczekiwaniu'),
        findsOneWidget,
      );
    });

    testWidgets('reaguje na wybór kolarza, zmianę trybu, zwijanie oraz hover',
        (WidgetTester tester) async {
      DiagonalTrainFormationMode? selectedMode;
      GutterDiagramRiderNode? selectedRider;

      await tester.pumpWidget(
        buildHarness(
          data: GutterWindProtectionDiagramData.sample(),
          onFormationModeChanged: (DiagonalTrainFormationMode m) {
            selectedMode = m;
          },
          onRiderSelected: (GutterDiagramRiderNode r) {
            selectedRider = r;
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Wybór kolarza z chipa
      await tester.tap(find.text('7. T. Merlier'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(selectedRider?.riderId, 'r2');
      expect(find.text('T. Merlier (SOQ)'), findsOneWidget);

      // Zmiana trybu formacji
      final Finder modeFinder = find.text('Rozrywający Wachlarz');
      await tester.ensureVisible(modeFinder);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(modeFinder);
      await tester.pump(const Duration(milliseconds: 250));
      expect(selectedMode, DiagonalTrainFormationMode.splitAndSnap);

      // Hover i zwinięcie nagłówka
      final Finder headerFinder = find.text('OCHRONA WIATRU BOCZNEGO');
      await tester.ensureVisible(headerFinder);
      await tester.pump(const Duration(milliseconds: 100));
      final TestGesture mouse =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(headerFinder));
      await tester.pump(const Duration(milliseconds: 200));
      await mouse.removePointer();

      await tester.tap(headerFinder);
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('TAKTYKA USTAWIENIA WACHLARZA'), findsNothing);
    });

    testWidgets('blokuje interakcję w stanie disabled (enabled: false)',
        (WidgetTester tester) async {
      DiagonalTrainFormationMode? selectedMode;
      GutterDiagramRiderNode? selectedRider;

      await tester.pumpWidget(
        buildHarness(
          data: GutterWindProtectionDiagramData.sample(),
          enabled: false,
          onFormationModeChanged: (DiagonalTrainFormationMode m) {
            selectedMode = m;
          },
          onRiderSelected: (GutterDiagramRiderNode r) {
            selectedRider = r;
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('7. T. Merlier'));
      await tester.pump(const Duration(milliseconds: 200));
      final Finder modeFinder = find.text('Rozrywający Wachlarz');
      await tester.ensureVisible(modeFinder);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(modeFinder);
      await tester.pump(const Duration(milliseconds: 200));

      expect(selectedRider, isNull);
      expect(selectedMode, isNull);
    });

    for (final Size size in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'renderuje się bez błędów przepełnienia na rozdzielczości ${size.width.toInt()}x${size.height.toInt()}',
          (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildHarness(
            data: GutterWindProtectionDiagramData.sample(),
            surfaceSize: size,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.byType(GutterWindProtectionDiagramHud), findsOneWidget);
      });
    }
  });
}
