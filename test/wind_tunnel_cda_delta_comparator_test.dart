import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/equipment/bike_fit_configuration.dart';
import 'package:pro_peloton_manager/models/equipment/complete_bike.dart';
import 'package:pro_peloton_manager/models/equipment/frame_model.dart';
import 'package:pro_peloton_manager/models/equipment/groupset_model.dart';
import 'package:pro_peloton_manager/models/equipment/tire_model.dart';
import 'package:pro_peloton_manager/models/equipment/wheelset_model.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/ui/widgets/wind_tunnel_cda_delta_comparator.dart';

RiderPhysiology _samplePhysiology() {
  return const RiderPhysiology(
    heightCm: 179.0,
    weightKg: 68.0,
    bodyFatPercentage: 7.5,
    ftpWatts: 410,
    wPrimeJoules: 24000,
    vo2Max: 81.5,
    maxHr: 194,
    restingHr: 40,
    lactateThresholdHr: 176,
    recoveryRate: 1.15,
    glycogenCapacityGrams: 520.0,
  );
}

CompleteBike _sampleBike({
  double frameCda = -0.010,
  double wheelCda = -0.007,
}) {
  return CompleteBike(
    id: 'bike_test',
    name: 'Test Aero Bike',
    frame: FrameModel(
      id: 'f_test',
      brandId: 'b_test',
      name: 'Test Frame',
      category: FrameCategory.aero,
      weightGrams: 820,
      aeroCdaModifier: frameCda,
      stiffnessToWeightIndex: 2.0,
      comfortCompliance: 0.7,
      priceEur: 4000,
      mesh3dAssetPath: 'models/bike.glb',
      primaryColorHex: '#00E5FF',
    ),
    wheelset: WheelsetModel(
      id: 'w_test',
      brandId: 'b_test',
      name: 'Test Wheels',
      rimDepthMm: 45,
      weightGrams: 1320,
      aeroCdaModifier: wheelCda,
      crosswindStabilityPenalty: 0.2,
      momentOfInertia: 0.12,
      hubEngagementDragWatts: 0.5,
      priceEur: 1800,
    ),
    groupset: const GroupsetModel(
      id: 'g_test',
      brandId: 'b_test',
      name: 'Test Di2',
      weightGrams: 2250,
      isElectronic: true,
      speedCount: 12,
      mechanicalEfficiency: 0.985,
      priceEur: 2800,
    ),
    tire: const TireModel(
      id: 't_test',
      brandId: 'b_test',
      name: 'Test Tire',
      widthMm: 28,
      weightGrams: 225,
      rollingResistanceCrr: 0.0028,
      punctureResistanceIndex: 3.5,
      wetGripIndex: 4.0,
      isTubeless: true,
      priceEur: 80,
    ),
    cockpitWidthMm: 400,
    hoodInwardTiltDegrees: 0.0,
    slammedStem: false,
  );
}

BikeFitConfiguration _sampleFit({
  int spacersStackMm = 20,
  int cockpitWidthMm = 400,
  double hoodTilt = 0.0,
}) {
  return BikeFitConfiguration(
    saddleHeightMm: 745.0,
    saddleSetbackMm: 55.0,
    saddleTiltDegrees: 0.0,
    cockpitWidthMm: cockpitWidthMm,
    stemLengthMm: 110,
    spacersStackMm: spacersStackMm,
    hoodInwardTiltDegrees: hoodTilt,
    crankArmLengthMm: 172.5,
    cleatOffsetMm: -2.0,
  );
}

void main() {
  group('WindTunnelCdaDeltaCalculator', () {
    test('reports zero delta for identical setups', () {
      final phys = _samplePhysiology();
      final fit = _sampleFit();
      final bike = _sampleBike();

      final result = WindTunnelCdaDeltaCalculator.compare(
        physiology: phys,
        baselineFit: fit,
        baselineBike: bike,
        currentFit: fit,
        currentBike: bike,
      );

      expect(result.isNeutral, isTrue);
      expect(result.deltaCdaM2, closeTo(0.0, 1e-6));
      expect(result.wattsSavedAtSpeed, closeTo(0.0, 1e-6));
      expect(result.timeDeltaSeconds40KmItt, closeTo(0.0, 1e-6));
      expect(
        result.formatHeadlineSummary(),
        contains('Brak zmian: 0.000 m² CdA'),
      );
    });

    test('calculates aero gain when removing stem spacers and upgrading wheels',
        () {
      final phys = _samplePhysiology();
      final baseFit = _sampleFit(spacersStackMm: 20);
      final aeroFit = _sampleFit(spacersStackMm: 0);
      final baseBike = _sampleBike(frameCda: -0.010, wheelCda: -0.002);
      final aeroBike = _sampleBike(frameCda: -0.016, wheelCda: -0.012);

      final result = WindTunnelCdaDeltaCalculator.compare(
        physiology: phys,
        baselineFit: baseFit,
        baselineBike: baseBike,
        currentFit: aeroFit,
        currentBike: aeroBike,
        speedKmh: 45.0,
      );

      expect(result.isGain, isTrue);
      expect(result.deltaCdaM2, lessThan(-0.020));
      expect(result.wattsSavedAtSpeed, greaterThan(20.0));
      expect(result.timeDeltaSeconds40KmItt, lessThan(-60.0));
      expect(result.formatHeadlineSummary(), startsWith('Zysk: -'));
      expect(result.formatHeadlineSummary(), contains('przy 45 km/h'));
      expect(result.formatHeadlineSummary(), contains('na 40 km ITT'));
    });

    test('calculates aero loss when adding spacers', () {
      final phys = _samplePhysiology();
      final baseFit = _sampleFit(spacersStackMm: 0);
      final uprightFit = _sampleFit(spacersStackMm: 30);
      final bike = _sampleBike();

      final result = WindTunnelCdaDeltaCalculator.compare(
        physiology: phys,
        baselineFit: baseFit,
        baselineBike: bike,
        currentFit: uprightFit,
        currentBike: bike,
      );

      expect(result.isLoss, isTrue);
      expect(result.deltaCdaM2, greaterThan(0.0));
      expect(result.wattsSavedAtSpeed, lessThan(0.0));
      expect(result.timeDeltaSeconds40KmItt, greaterThan(0.0));
      expect(result.formatHeadlineSummary(), startsWith('Strata: +'));
    });
  });

  group('WindTunnelCdaDeltaComparator Widget', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          int currentSpacers = 15;
          CompleteBike currentBike = _sampleBike();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return WindTunnelCdaDeltaComparator(
                        physiology: _samplePhysiology(),
                        currentFit: _sampleFit(spacersStackMm: currentSpacers),
                        currentBike: currentBike,
                        onBikeChanged: (b) => setState(() => currentBike = b),
                        onSpacersChanged: (s) =>
                            setState(() => currentSpacers = s),
                      );
                    },
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          expect(find.textContaining('KOMPARATOR DELTY CdA'), findsOneWidget);
          expect(find.textContaining('m² CdA ='), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('updates spacers and bike presets interactively', (tester) async {
      int currentSpacers = 20;
      CompleteBike currentBike = _sampleBike();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return WindTunnelCdaDeltaComparator(
                    physiology: _samplePhysiology(),
                    currentFit: _sampleFit(spacersStackMm: currentSpacers),
                    currentBike: currentBike,
                    onBikeChanged: (b) => setState(() => currentBike = b),
                    onSpacersChanged: (s) => setState(() => currentSpacers = s),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Slammed (0 mm)'));
      await tester.pumpAndSettle();
      expect(currentSpacers, 0);

      await tester.tap(find.text('Czasowa TT'));
      await tester.pumpAndSettle();
      expect(currentBike.frame.category, FrameCategory.timeTrial);

      await tester.tap(find.text('Ustaw jako Bazę A'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Brak zmian:'), findsOneWidget);
    });
  });
}
