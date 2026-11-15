import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/engine/rendering3d/broadcast_tv_graphics_overlay.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/ui/widgets/tv_climb_gradient_3d_ribbon_hud.dart';

void main() {
  TvClimbGradient3dRibbonData buildSampleClimbData({
    int kmCount = 10,
    double remainingKm = 4.2,
  }) {
    final List<double> gradients = <double>[
      3.5,
      5.2,
      6.4,
      7.8,
      8.9,
      10.4,
      11.8,
      13.6,
      14.2,
      9.1,
    ];
    final List<ClimbKilometerSegment> segments = List<ClimbKilometerSegment>.generate(
      kmCount,
      (int i) => ClimbKilometerSegment(
        kilometerIndex: i + 1,
        lengthKm: 1.0,
        gradientPercent: gradients[i % gradients.length],
      ),
    );

    return TvClimbGradient3dRibbonData(
      climbName: "Alpe d'Huez",
      category: SegmentClassification.horsCategorie,
      totalLengthKm: kmCount.toDouble(),
      remainingKm: remainingKm,
      averageGradientPercent: 8.1,
      currentGradientPercent: 10.4,
      summitElevationM: 1850,
      currentElevationM: 1410,
      leaderVamMetersPerHour: 1764,
      leaderName: 'T. Pogačar',
      kilometerSegments: segments,
    );
  }

  group('ClimbGradientDifficultyBand', () {
    test('maps exact gradient thresholds to required TV colors', () {
      expect(
        ClimbGradientDifficultyBand.fromGradient(3.9),
        ClimbGradientDifficultyBand.gentle,
      );
      expect(
        ClimbGradientDifficultyBand.fromGradient(4.0),
        ClimbGradientDifficultyBand.yellow,
      );
      expect(
        ClimbGradientDifficultyBand.fromGradient(6.0),
        ClimbGradientDifficultyBand.yellow,
      );
      expect(
        ClimbGradientDifficultyBand.fromGradient(6.9),
        ClimbGradientDifficultyBand.yellow,
      );
      expect(
        ClimbGradientDifficultyBand.fromGradient(7.0),
        ClimbGradientDifficultyBand.orange,
      );
      expect(
        ClimbGradientDifficultyBand.fromGradient(9.5),
        ClimbGradientDifficultyBand.orange,
      );
      expect(
        ClimbGradientDifficultyBand.fromGradient(10.0),
        ClimbGradientDifficultyBand.red,
      );
      expect(
        ClimbGradientDifficultyBand.fromGradient(12.0),
        ClimbGradientDifficultyBand.red,
      );
      expect(
        ClimbGradientDifficultyBand.fromGradient(12.1),
        ClimbGradientDifficultyBand.black,
      );
      expect(
        ClimbGradientDifficultyBand.fromGradient(16.5),
        ClimbGradientDifficultyBand.black,
      );

      expect(ClimbGradientDifficultyBand.yellow.frontColor, AppColors.powerZone4);
      expect(ClimbGradientDifficultyBand.orange.frontColor, AppColors.powerZone5);
      expect(ClimbGradientDifficultyBand.red.frontColor, AppColors.crimsonAlert);
      expect(
        ClimbGradientDifficultyBand.black.frontColor,
        const Color(0xFF0A0C10),
      );
    });

    test('converts BroadcastClimbTelemetryData into kilometer segments', () {
      const BroadcastClimbTelemetryData telemetry = BroadcastClimbTelemetryData(
        climbName: 'Col du Galibier',
        category: SegmentClassification.horsCategorie,
        totalLengthKm: 6.0,
        remainingKm: 2.5,
        averageGradientPercent: 8.5,
        currentGradientPercent: 11.2,
        summitElevationM: 2642,
        currentElevationM: 2380,
        estimatedClimbTimeSeconds: 1120,
        leaderGroupVamMetersPerHour: 1685,
        elevationProfileSamples: <double>[
          2130,
          2190,
          2260,
          2340,
          2430,
          2530,
          2642,
        ],
      );

      final TvClimbGradient3dRibbonData converted =
          TvClimbGradient3dRibbonData.fromBroadcastTelemetry(
        telemetry,
        leaderName: 'J. Vingegaard',
      );

      expect(converted.climbName, 'Col du Galibier');
      expect(converted.kilometerSegments.length, 6);
      expect(converted.leaderVamMetersPerHour, 1685);
      expect(converted.leaderName, 'J. Vingegaard');
      expect(converted.progressFraction, closeTo(3.5 / 6.0, 0.001));
    });
  });

  group('TvClimbGradient3dRibbonHud widget', () {
    testWidgets('renders climb header, leader VAM, legend and 3D bars',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TvClimbGradient3dRibbonHud(
                  data: buildSampleClimbData(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text("ALPE D'HUEZ"), findsOneWidget);
      expect(find.text('HC'), findsOneWidget);
      expect(find.text('ŚR. VAM LIDERA'), findsOneWidget);
      expect(find.text('1764 m/h'), findsOneWidget);
      expect(find.text('4–6%'), findsOneWidget);
      expect(find.text('7–9%'), findsOneWidget);
      expect(find.text('10–12%'), findsOneWidget);
      expect(find.text('>12%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('toggles collapse/expand and handles disabled state',
        (WidgetTester tester) async {
      bool toggled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TvClimbGradient3dRibbonHud(
              data: buildSampleClimbData(),
              onToggleExpand: () => toggled = true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('4–6%'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
      await tester.pump(const Duration(milliseconds: 300));

      expect(toggled, isTrue);
      expect(find.text('Do szczytu 4.2 km'), findsOneWidget);

      // Disabled state should ignore toggle
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TvClimbGradient3dRibbonHud(
              data: buildSampleClimbData(),
              enabled: false,
              onToggleExpand: () => toggled = false,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pump(const Duration(milliseconds: 100));
      expect(toggled, isTrue);
    });

    testWidgets('supports keyboard segment inspection and click callback',
        (WidgetTester tester) async {
      ClimbKilometerSegment? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TvClimbGradient3dRibbonHud(
              data: buildSampleClimbData(kmCount: 6),
              onSegmentSelected: (ClimbKilometerSegment? seg) => selected = seg,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Focus the HUD and step right
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(selected, isNotNull);
      expect(find.textContaining('KM ${selected!.kilometerIndex}'), findsOneWidget);
    });

    for (final Size viewport in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(viewport);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                backgroundColor: AppColors.background,
                body: SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TvClimbGradient3dRibbonHud(
                        data: buildSampleClimbData(kmCount: 15),
                        onFocusClimbCamera: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 150));
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
