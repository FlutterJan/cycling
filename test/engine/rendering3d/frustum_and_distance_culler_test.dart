import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/frustum_and_distance_culler.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  group('FrustumAndDistanceCuller', () {
    late Scene3DMathProjection projection;
    late FrustumAndDistanceCuller culler;

    setUp(() {
      projection = Scene3DMathProjection(
        viewportWidth: 1600,
        viewportHeight: 900,
        fovYDegrees: 60.0,
        zNear: 0.35,
        zFar: 600.0,
      );
      projection.setView(
        eye: Vector3(0.0, 2.5, 0.0),
        target: Vector3(0.0, 2.5, 50.0),
        up: Vector3(0.0, 1.0, 0.0),
      );
      culler = FrustumAndDistanceCuller();
      culler.updateFromProjection(projection);
      culler.beginFrame();
    });

    test('odrzuca kolarzy, drzewa i budynki znajdujące się za kamerą', () {
      final riderBehind = culler.evaluateRider(Vector3(0.0, 1.0, -10.0));
      final treeBehind = culler.evaluateTree(Vector3(5.0, 0.0, -25.0));
      final buildingBehind = culler.evaluateBuilding(Vector3(-12.0, 4.0, -30.0));

      expect(riderBehind.isVisible, isFalse);
      expect(riderBehind.rejectionReason, CullRejectionReason.behindCamera);

      expect(treeBehind.isVisible, isFalse);
      expect(treeBehind.rejectionReason, CullRejectionReason.behindCamera);

      expect(buildingBehind.isVisible, isFalse);
      expect(buildingBehind.rejectionReason, CullRejectionReason.behindCamera);
      expect(culler.currentStats.rejectedBehindCamera, 3);
    });

    test('odrzuca obiekty w odległości > 450 m i akceptuje <= 450 m', () {
      final riderTooFar = culler.evaluateRider(Vector3(0.0, 2.0, 451.0));
      final treeTooFar = culler.evaluateTree(Vector3(4.0, 2.0, 500.0));
      final buildingTooFar = culler.evaluateBuilding(Vector3(-10.0, 5.0, 620.0));

      expect(riderTooFar.isVisible, isFalse);
      expect(riderTooFar.rejectionReason, CullRejectionReason.beyondMaxDistance);
      expect(treeTooFar.isVisible, isFalse);
      expect(treeTooFar.rejectionReason, CullRejectionReason.beyondMaxDistance);
      expect(buildingTooFar.isVisible, isFalse);
      expect(buildingTooFar.rejectionReason, CullRejectionReason.beyondMaxDistance);

      final riderInRange = culler.evaluateRider(Vector3(0.0, 2.0, 440.0));
      expect(riderInRange.isVisible, isTrue);
      expect(riderInRange.rejectionReason, CullRejectionReason.none);
    });

    test('odrzuca obiekty poza bocznym polem widzenia (Frustum)', () {
      final farLeftRider = culler.evaluateRider(Vector3(-120.0, 2.0, 30.0));
      final farRightTree = culler.evaluateTree(Vector3(150.0, 2.0, 40.0));

      expect(farLeftRider.isVisible, isFalse);
      expect(farLeftRider.rejectionReason, CullRejectionReason.outsideFrustum);
      expect(farRightTree.isVisible, isFalse);
      expect(farRightTree.rejectionReason, CullRejectionReason.outsideFrustum);
    });

    test('płynnie wygasza mgłę odległościową do granicy 450 m', () {
      expect(culler.computeDistanceFogFactor(100.0), 0.0);
      expect(culler.computeDistanceFogFactor(280.0), 0.0);

      final midFog = culler.computeDistanceFogFactor(365.0);
      final nearEndFog = culler.computeDistanceFogFactor(430.0);
      final endFog = culler.computeDistanceFogFactor(450.0);

      expect(midFog, greaterThan(0.0));
      expect(midFog, lessThan(nearEndFog));
      expect(nearEndFog, lessThan(1.0));
      expect(endFog, 1.0);

      final faded = culler.applyDistanceFog(const Color(0xFFD4AF37), nearEndFog);
      expect(faded.a, lessThan(0.5));
      expect(faded.a, greaterThan(0.0));
    });

    test('obsługuje nieprawidłowe współrzędne (NaN / Infinity) bez wyjątku', () {
      final nanDecision = culler.evaluateRider(Vector3(double.nan, 0.0, 10.0));
      final infDecision =
          culler.evaluateTree(Vector3(0.0, double.infinity, 10.0));

      expect(nanDecision.isVisible, isFalse);
      expect(nanDecision.rejectionReason, CullRejectionReason.invalidCoordinates);
      expect(infDecision.isVisible, isFalse);
      expect(infDecision.rejectionReason, CullRejectionReason.invalidCoordinates);
    });

    test('cullAndSortBackToFront sortuje od najdalszych i zlicza statystyki', () {
      final items = <({String id, Vector3 pos, CullableObjectCategory cat})>[
        (id: 'near', pos: Vector3(0.0, 2.0, 20.0), cat: CullableObjectCategory.rider),
        (id: 'far', pos: Vector3(0.0, 2.0, 200.0), cat: CullableObjectCategory.tree),
        (id: 'mid', pos: Vector3(0.0, 2.0, 90.0), cat: CullableObjectCategory.building),
        (id: 'behind', pos: Vector3(0.0, 2.0, -5.0), cat: CullableObjectCategory.rider),
        (id: 'too_far', pos: Vector3(0.0, 2.0, 480.0), cat: CullableObjectCategory.building),
      ];

      final visible = culler.cullAndSortBackToFront(
        items: items,
        positionOf: (e) => e.pos,
        categoryOf: (e) => e.cat,
      );

      expect(visible.map((e) => e.item.id).toList(), ['far', 'mid', 'near']);
      final stats = culler.currentStats;
      expect(stats.totalEvaluated, 5);
      expect(stats.visibleCount, 3);
      expect(stats.ridersEvaluated, 2);
      expect(stats.ridersVisible, 1);
      expect(stats.treesEvaluated, 1);
      expect(stats.treesVisible, 1);
      expect(stats.buildingsEvaluated, 2);
      expect(stats.buildingsVisible, 1);
      expect(stats.cullRatePercent, closeTo(40.0, 0.01));
    });
  });

  group('FrustumCullingInspectorPanel', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się poprawnie bez przepełnień w ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          var config = const FrustumCullingConfig();
          const stats = CullingFrameStats(
            totalEvaluated: 250,
            visibleCount: 110,
            rejectedBehindCamera: 80,
            rejectedBeyondDistance: 40,
            rejectedOutsideFrustum: 20,
            ridersEvaluated: 176,
            ridersVisible: 84,
            treesEvaluated: 60,
            treesVisible: 20,
            buildingsEvaluated: 14,
            buildingsVisible: 6,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: FrustumCullingInspectorPanel(
                    config: config,
                    stats: stats,
                    onConfigChanged: (next) => config = next,
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.textContaining('450 m'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
