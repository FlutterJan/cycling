import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/ui/screens/stage_editor_creator_screen.dart';
import 'package:pro_peloton_manager/ui/widgets/custom_race_route_elevation_brush.dart';

void main() {
  group('ClimbCategoryCalculator', () {
    test('oblicza poprawne nachylenie procentowe odcinka', () {
      const a = StageEditorPoint(id: 'a', distanceKm: 10.0, elevationMeters: 200.0);
      const b = StageEditorPoint(id: 'b', distanceKm: 15.0, elevationMeters: 500.0);

      final grad = ClimbCategoryCalculator.calculateSegmentGradientPercent(a, b);
      expect(grad, closeTo(6.0, 0.001));
    });

    test('klasyfikuje podjazdy na kategorie Cat 4, 3, 2, 1 oraz HC', () {
      expect(
        ClimbCategoryCalculator.classifyClimb(
          lengthKm: 1.5,
          elevationGainM: 65.0,
          avgGradientPercent: 4.3,
        ),
        SegmentClassification.cat4,
      );
      expect(
        ClimbCategoryCalculator.classifyClimb(
          lengthKm: 3.5,
          elevationGainM: 175.0,
          avgGradientPercent: 5.0,
        ),
        SegmentClassification.cat3,
      );
      expect(
        ClimbCategoryCalculator.classifyClimb(
          lengthKm: 5.5,
          elevationGainM: 330.0,
          avgGradientPercent: 6.0,
        ),
        SegmentClassification.cat2,
      );
      expect(
        ClimbCategoryCalculator.classifyClimb(
          lengthKm: 8.5,
          elevationGainM: 560.0,
          avgGradientPercent: 6.6,
        ),
        SegmentClassification.cat1,
      );
      expect(
        ClimbCategoryCalculator.classifyClimb(
          lengthKm: 13.8,
          elevationGainM: 1120.0,
          avgGradientPercent: 8.1,
        ),
        SegmentClassification.horsCategorie,
      );
    });

    test('automatycznie wykrywa podjazdy i zachowuje sprinty oraz metę', () {
      final points = [
        const StageEditorPoint(id: '0', distanceKm: 0.0, elevationMeters: 200.0),
        const StageEditorPoint(
          id: '1',
          distanceKm: 10.0,
          elevationMeters: 220.0,
          classification: SegmentClassification.intermediateSprint,
        ),
        const StageEditorPoint(id: '2', distanceKm: 22.0, elevationMeters: 1200.0),
        const StageEditorPoint(
          id: '3',
          distanceKm: 35.0,
          elevationMeters: 400.0,
          classification: SegmentClassification.finishLine,
        ),
      ];

      final climbs = ClimbCategoryCalculator.analyzeClimbs(points);
      expect(climbs.length, 1);
      expect(climbs.first.category, SegmentClassification.horsCategorie);
      expect(climbs.first.summitPointIndex, 2);

      final classified =
          ClimbCategoryCalculator.applyAutoClimbClassifications(points);
      expect(classified[1].classification, SegmentClassification.intermediateSprint);
      expect(classified[2].classification, SegmentClassification.horsCategorie);
      expect(classified[3].classification, SegmentClassification.finishLine);
    });

    test('rzeźbienie, wygładzanie i wypłaszczanie modyfikują profil', () {
      final flat = List.generate(
        21,
        (i) => StageEditorPoint(
          id: 'p_$i',
          distanceKm: i * 2.0,
          elevationMeters: 200.0,
        ),
      );

      final sculpted = ClimbCategoryCalculator.applySculptBrush(
        points: flat,
        centerKm: 20.0,
        targetElevationM: 900.0,
        radiusKm: 10.0,
        strength: 1.0,
      );
      expect(sculpted[10].elevationMeters, closeTo(900.0, 0.1));
      expect(sculpted[0].elevationMeters, 200.0);

      final smoothed = ClimbCategoryCalculator.applySmoothBrush(
        points: sculpted,
        centerKm: 20.0,
        radiusKm: 6.0,
        strength: 0.8,
      );
      expect(smoothed[10].elevationMeters, lessThan(sculpted[10].elevationMeters));

      final flattened = ClimbCategoryCalculator.applyFlattenBrush(
        points: sculpted,
        centerKm: 20.0,
        radiusKm: 10.0,
        strength: 1.0,
      );
      expect(flattened[10].elevationMeters, lessThan(900.0));
    });
  });

  group('CustomRaceRouteElevationBrush Widget', () {
    List<StageEditorPoint> samplePoints() => const [
          StageEditorPoint(id: 'p0', distanceKm: 0.0, elevationMeters: 150.0),
          StageEditorPoint(id: 'p1', distanceKm: 20.0, elevationMeters: 220.0),
          StageEditorPoint(id: 'p2', distanceKm: 40.0, elevationMeters: 950.0),
          StageEditorPoint(
            id: 'p3',
            distanceKm: 60.0,
            elevationMeters: 300.0,
            classification: SegmentClassification.finishLine,
          ),
        ];

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje bez błędów przepełnienia przy ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: size.width,
                  height: size.height * 0.45,
                  child: CustomRaceRouteElevationBrush(
                    points: samplePoints(),
                    selectedPointIndex: 0,
                    onPointsChanged: (_) {},
                    onPointSelected: (_) {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(CustomRaceRouteElevationBrush), findsOneWidget);
        },
      );
    }

    testWidgets('przeciągnięcie pędzlem aktualizuje profil wysokościowy i pozwala cofnąć',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      List<StageEditorPoint> currentPoints = samplePoints();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  width: 960,
                  height: 360,
                  child: CustomRaceRouteElevationBrush(
                    points: currentPoints,
                    selectedPointIndex: 0,
                    onPointsChanged: (pts) => setState(() => currentPoints = pts),
                    onPointSelected: (_) {},
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final paintFinder = find.byType(CustomPaint).last;
      final center = tester.getCenter(paintFinder);
      await tester.dragFrom(center, const Offset(80, -70));
      await tester.pumpAndSettle();

      expect(currentPoints.length, greaterThan(4));

      final undoFinder = find.text('Cofnij');
      expect(undoFinder, findsOneWidget);
      await tester.tap(undoFinder);
      await tester.pumpAndSettle();

      expect(currentPoints.length, 4);
    });
  });
}
