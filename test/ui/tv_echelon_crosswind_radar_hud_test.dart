import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/echelon_crosswind_engine.dart';
import 'package:pro_peloton_manager/ui/widgets/tv_echelon_crosswind_radar_hud.dart';

void main() {
  group('TvEchelonCrosswindRadarData & EchelonRiskLevel', () {
    test('wylicza poprawny kąt natarcia i składową boczną wiatru', () {
      const TvEchelonCrosswindRadarData data = TvEchelonCrosswindRadarData(
        sectorName: 'TEST SECTOR',
        windSpeedKmh: 40.0,
        windDirectionDegrees: 105.0,
        roadHeadingDegrees: 15.0,
        echelons: <EchelonSplitRowData>[],
      );

      expect(data.signedAttackAngleDegrees, closeTo(90.0, 0.001));
      expect(data.attackAngleDegrees, closeTo(90.0, 0.001));
      expect(data.crosswindSpeedKmh, closeTo(40.0, 0.001));
      expect(data.headwindComponentKmh, closeTo(0.0, 0.001));
      expect(data.riskLevel, EchelonRiskLevel.extreme);
      expect(data.showHighRiskAlert, isTrue);
    });

    test('obsługuje wartości brzegowe NaN i wiatr osiowy bez błędów', () {
      const TvEchelonCrosswindRadarData data = TvEchelonCrosswindRadarData(
        sectorName: 'CALM',
        windSpeedKmh: double.nan,
        windDirectionDegrees: 10.0,
        roadHeadingDegrees: 10.0,
        echelons: <EchelonSplitRowData>[],
      );

      expect(data.attackAngleDegrees, 0.0);
      expect(data.crosswindSpeedKmh, 0.0);
      expect(data.riskLevel, EchelonRiskLevel.low);
      expect(data.showHighRiskAlert, isFalse);
    });

    test('konwertuje CrosswindEchelonResult do modelu HUD', () {
      const CrosswindEchelonResult result = CrosswindEchelonResult(
        isEchelonActive: true,
        crosswindSpeedKmh: 31.5,
        echelonCapacity: 10,
        echelons: <EchelonFormation>[
          EchelonFormation(
            echelonIndex: 1,
            riderIds: <String>['r1', 'r2'],
            capacity: 10,
            isGutterFormed: true,
            averageDraftingSavingsPercent: 35.0,
            gapToLeadEchelonSeconds: 0.0,
          ),
          EchelonFormation(
            echelonIndex: 2,
            riderIds: <String>['r3', 'r4', 'r5'],
            capacity: 10,
            isGutterFormed: true,
            averageDraftingSavingsPercent: 25.0,
            gapToLeadEchelonSeconds: 18.4,
          ),
          EchelonFormation(
            echelonIndex: 3,
            riderIds: <String>['r6'],
            capacity: 10,
            isGutterFormed: false,
            averageDraftingSavingsPercent: 18.0,
            gapToLeadEchelonSeconds: 72.0,
          ),
        ],
        resultingGroups: <PelotonGroup>[],
        gutterRiderIds: <String>['r2'],
      );

      final TvEchelonCrosswindRadarData hudData =
          TvEchelonCrosswindRadarData.fromCrosswindResult(
        result,
        windSpeedKmh: 36.0,
        windDirectionDegrees: 280.0,
        roadHeadingDegrees: 10.0,
        playerTeamRiderIds: const <String>{'r1', 'r3'},
        riderNamesById: const <String, String>{
          'r1': 'Kwiatek',
          'r3': 'Majka',
        },
      );

      expect(hudData.echelons.length, 3);
      expect(hudData.echelons[0].formattedGap, 'CZOŁO');
      expect(hudData.echelons[0].playerRidersCount, 1);
      expect(hudData.echelons[0].notableRiderNames, contains('Kwiatek'));
      expect(hudData.echelons[1].formattedGap, '+18.4s');
      expect(hudData.echelons[2].formattedGap, "+1'12\"");
      expect(hudData.showHighRiskAlert, isTrue);
    });
  });

  group('TvEchelonCrosswindRadarHud Widget', () {
    Widget buildHarness({
      required Size size,
      required TvEchelonCrosswindRadarData data,
      bool isEnabled = true,
      ValueChanged<EchelonSplitRowData>? onEchelonSelected,
      VoidCallback? onToggleCompact,
    }) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: size.width < 500 ? size.width - 16 : 620,
                child: SingleChildScrollView(
                  child: TvEchelonCrosswindRadarHud(
                    data: data,
                    isEnabled: isEnabled,
                    onEchelonSelected: onEchelonSelected,
                    onToggleCompact: onToggleCompact,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'wyświetla alert CROSSWIND ZONE — ECHELON RISK HIGH i ranty 1, 2, 3',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildHarness(
            size: const Size(1600, 900),
            data: TvEchelonCrosswindRadarData.demo(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 350));

        expect(
          find.text('CROSSWIND ZONE — ECHELON RISK HIGH'),
          findsOneWidget,
        );
        expect(find.text('RANT NR 1'), findsOneWidget);
        expect(find.text('RANT NR 2'), findsOneWidget);
        expect(find.text('RANT NR 3'), findsOneWidget);
        expect(find.text('CZOŁO'), findsOneWidget);
        expect(find.text('+24.6s'), findsOneWidget);
        expect(find.text("+1'08\""), findsOneWidget);
      },
    );

    testWidgets(
      'obsługuje wybór rantu, zwijanie oraz stan disabled',
      (WidgetTester tester) async {
        EchelonSplitRowData? selected;
        bool toggled = false;

        await tester.pumpWidget(
          buildHarness(
            size: const Size(1024, 768),
            data: TvEchelonCrosswindRadarData.demo(),
            onEchelonSelected: (EchelonSplitRowData row) => selected = row,
            onToggleCompact: () => toggled = true,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.text('RANT NR 2'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(selected?.echelonNumber, 2);
        expect(find.textContaining('Ganna, Pedersen'), findsOneWidget);

        await tester.tap(find.text('ZWIŃ'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(toggled, isTrue);
        expect(find.text('RANT NR 1'), findsNothing);

        await tester.tap(find.text('RANTY'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('RANT NR 1'), findsOneWidget);

        // Disabled state blocks interactions
        selected = null;
        await tester.pumpWidget(
          buildHarness(
            size: const Size(1024, 768),
            data: TvEchelonCrosswindRadarData.demo(),
            isEnabled: false,
            onEchelonSelected: (EchelonSplitRowData row) => selected = row,
          ),
        );
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.text('RANT NR 1'));
        await tester.pump();
        expect(selected, isNull);
      },
    );

    for (final Size viewport in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnień (overflow) w rozdzielczości '
        '${viewport.width.toInt()}x${viewport.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            buildHarness(
              size: viewport,
              data: TvEchelonCrosswindRadarData.demo(),
            ),
          );
          await tester.pump(const Duration(milliseconds: 350));

          expect(tester.takeException(), isNull);
          expect(find.byType(TvEchelonCrosswindRadarHud), findsOneWidget);
        },
      );
    }
  });
}
