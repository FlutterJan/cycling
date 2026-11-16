// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/rendering3d/tire_deformation_and_spoke_glint_fx.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

void main() {
  group('TireDeformationAndSpokeGlintFx', () {
    const TireDeformationAndSpokeGlintFx fx = TireDeformationAndSpokeGlintFx();

    test(
      'spłaszczenie styku opony jest większe przy 3.8 bar na bruku niż przy 6.5 bar na czasówce',
      () {
        final TireDeformationAndSpokeGlintState cobbleState = fx.evaluateFrame(
          TireDeformationFrameInput(
            tirePressureBar: TireSurfacePreset.cobblestone.pressureBar,
            tireWidthMm: TireSurfacePreset.cobblestone.tireWidthMm,
            surfaceRoughness: TireSurfacePreset.cobblestone.surfaceRoughness,
            speedKmh: 38.0,
            timeSeconds: 0.25,
          ),
        );

        final TireDeformationAndSpokeGlintState ttState = fx.evaluateFrame(
          TireDeformationFrameInput(
            tirePressureBar: TireSurfacePreset.timeTrial.pressureBar,
            tireWidthMm: TireSurfacePreset.timeTrial.tireWidthMm,
            surfaceRoughness: TireSurfacePreset.timeTrial.surfaceRoughness,
            speedKmh: 54.0,
            isDiscWheel: true,
            timeSeconds: 0.25,
          ),
        );

        expect(
          cobbleState.rearTire.verticalDeflectionMm,
          greaterThan(ttState.rearTire.verticalDeflectionMm * 1.5),
        );
        expect(
          cobbleState.rearTire.contactPatchLengthMm,
          greaterThan(ttState.rearTire.contactPatchLengthMm),
        );
        expect(
          cobbleState.rearTire.bottomScaleY,
          lessThan(ttState.rearTire.bottomScaleY),
        );
        expect(
          cobbleState.rearTire.sidewallBulgeScaleX,
          greaterThan(ttState.rearTire.sidewallBulgeScaleX),
        );
      },
    );

    test(
      'tylne koło ma większe ugięcie niż przednie przy standardowym rozkładzie masy',
      () {
        final TireDeformationAndSpokeGlintState state = fx.evaluateFrame(
          TireDeformationFrameInput(
            tirePressureBar: 5.2,
            frontWeightDistribution: 0.42,
          ),
        );

        expect(
          state.rearTire.verticalDeflectionMm,
          greaterThan(state.frontTire.verticalDeflectionMm),
        );
      },
    );

    test(
      'błyski słońca na szprychach i tarczach hamulcowych zależą od kąta i światła',
      () {
        final TireDeformationAndSpokeGlintState litState = fx.evaluateFrame(
          TireDeformationFrameInput(
            wheelAngleRadians: 0.45,
            sunDirection: vm.Vector3(0.5, 0.8, 0.3).normalized(),
            sunlightIntensity: 1.0,
          ),
        );

        expect(litState.spokeGlints.length, equals(18));
        expect(litState.peakSpokeGlintIntensity, greaterThan(0.2));
        expect(litState.brakeRotorGlint.rotorGlintIntensity, greaterThan(0.2));

        final TireDeformationAndSpokeGlintState darkState = fx.evaluateFrame(
          TireDeformationFrameInput(
            wheelAngleRadians: 0.45,
            sunlightIntensity: 0.0,
          ),
        );

        expect(darkState.spokeGlints, isEmpty);
        expect(darkState.peakSpokeGlintIntensity, equals(0.0));
        expect(darkState.brakeRotorGlint.rotorGlintIntensity, equals(0.0));
      },
    );

    test(
      'dysk czasowy nie generuje błysków szprych, a wyłączenie tarcz zeruje błysk rotora',
      () {
        final TireDeformationAndSpokeGlintState discState = fx.evaluateFrame(
          TireDeformationFrameInput(
            isDiscWheel: true,
            hasDiscBrakes: false,
            sunlightIntensity: 1.0,
          ),
        );

        expect(discState.spokeGlints, isEmpty);
        expect(discState.brakeRotorGlint.rotorGlintIntensity, equals(0.0));
      },
    );

    test(
      'buildDeformedTireProfilePoints spłaszcza dolną granicę poniżej promienia nominalnego',
      () {
        final TireContactPatchDeformation deformation =
            fx.computeTireDeformation(
          pressureBar: 3.8,
          wheelLoadKg: 44.0,
          surfaceRoughness: 0.9,
        );
        const Offset center = Offset(100, 100);
        const double radius = 60.0;
        final List<Offset> points = fx.buildDeformedTireProfilePoints(
          wheelCenter: center,
          screenRadiusPx: radius,
          deformation: deformation,
        );

        expect(points.length, equals(56));
        final double maxY = points.map((Offset p) => p.dy).reduce(math.max);
        expect(maxY, lessThan(center.dy + radius));
      },
    );

    for (final Size viewport in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'TireDeformationAndSpokeGlintPanel renderuje bez overflow w ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: const Scaffold(
                body: Center(
                  child: TireDeformationAndSpokeGlintPanel(
                    animateByDefault: false,
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(
            find.text('Mikro-detale Kół 3D: Styk Opony & Błyski Szprych'),
            findsOneWidget,
          );

          await tester.tap(find.text('Czasówka 6.5 bar'));
          await tester.pump(const Duration(milliseconds: 250));
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
