// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/rendering3d/cold_breath_vapor_and_sweat_sheen.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

void main() {
  group('ColdBreathVaporAndSweatSheen', () {
    const ColdBreathVaporAndSweatSheen engine = ColdBreathVaporAndSweatSheen();

    test(
      'para wodna z ust jest aktywna poniżej 10°C i nieaktywna przy >= 10°C',
      () {
        final ColdBreathAndSweatState coldState = engine.evaluateFrame(
          ColdBreathAndSweatFrameInput(
            ambientTemperatureCelsius: 4.5,
            altitudeMeters: 2500.0,
            relativeHumidity: 0.80,
            powerWatts: 380.0,
            heartRateBpm: 172.0,
            riderSpeedMs: 7.0,
            timeSeconds: 0.72,
          ),
        );

        expect(coldState.breathVapor.isActive, isTrue);
        expect(coldState.breathVapor.vaporDensity, greaterThan(0.3));
        expect(coldState.breathVapor.particles, isNotEmpty);
        expect(coldState.sweatSheen.isActive, isFalse);

        final ColdBreathAndSweatState boundaryState = engine.evaluateFrame(
          ColdBreathAndSweatFrameInput(
            ambientTemperatureCelsius: 10.0,
            altitudeMeters: 2500.0,
            timeSeconds: 0.72,
          ),
        );

        expect(boundaryState.breathVapor.isActive, isFalse);
        expect(boundaryState.breathVapor.particles, isEmpty);
        expect(boundaryState.breathVapor.vaporDensity, equals(0.0));
      },
    );

    test(
      'rytm oddechu przyspiesza przy wyższej mocy i na wysokiej przełęczy',
      () {
        final ColdBreathAndSweatState easyValley = engine.evaluateFrame(
          ColdBreathAndSweatFrameInput(
            ambientTemperatureCelsius: 6.0,
            altitudeMeters: 300.0,
            powerWatts: 180.0,
            heartRateBpm: 115.0,
            timeSeconds: 0.5,
          ),
        );

        final ColdBreathAndSweatState hardAlpinePass = engine.evaluateFrame(
          ColdBreathAndSweatFrameInput(
            ambientTemperatureCelsius: 6.0,
            altitudeMeters: 2700.0,
            powerWatts: 430.0,
            heartRateBpm: 184.0,
            timeSeconds: 0.5,
          ),
        );

        expect(
          hardAlpinePass.breathVapor.respiratoryRateBpm,
          greaterThan(easyValley.breathVapor.respiratoryRateBpm),
        );
        expect(
          hardAlpinePass.breathVapor.vaporDensity,
          greaterThan(easyValley.breathVapor.vaporDensity),
        );
      },
    );

    test(
      'połysk potu na ramionach i nogach jest aktywny powyżej 28°C i nieaktywny przy <= 28°C',
      () {
        final ColdBreathAndSweatState hotState = engine.evaluateFrame(
          ColdBreathAndSweatFrameInput(
            ambientTemperatureCelsius: 34.5,
            altitudeMeters: 900.0,
            relativeHumidity: 0.55,
            powerWatts: 410.0,
            heartRateBpm: 182.0,
            riderSpeedMs: 5.5,
            sunlightIntensity: 1.0,
            timeSeconds: 1.2,
          ),
        );

        expect(hotState.sweatSheen.isActive, isTrue);
        expect(hotState.sweatSheen.skinWetness, greaterThan(0.3));
        expect(hotState.sweatSheen.peakSpecularIntensity, greaterThan(0.15));
        expect(
          hotState.sweatSheen.limbHighlights.map((e) => e.zone),
          containsAll(<LimbSheenZone>[
            LimbSheenZone.leftArm,
            LimbSheenZone.rightArm,
            LimbSheenZone.leftLeg,
            LimbSheenZone.rightLeg,
          ]),
        );
        expect(hotState.breathVapor.isActive, isFalse);

        final ColdBreathAndSweatState boundaryState = engine.evaluateFrame(
          ColdBreathAndSweatFrameInput(
            ambientTemperatureCelsius: 28.0,
            powerWatts: 410.0,
            timeSeconds: 1.2,
          ),
        );

        expect(boundaryState.sweatSheen.isActive, isFalse);
        expect(boundaryState.sweatSheen.limbHighlights, isEmpty);
        expect(boundaryState.sweatSheen.peakSpecularIntensity, equals(0.0));
      },
    );

    test(
      'natężenie połysku potu zależy od temperatury i światła słonecznego',
      () {
        final ColdBreathAndSweatState sunnyHot = engine.evaluateFrame(
          ColdBreathAndSweatFrameInput(
            ambientTemperatureCelsius: 38.0,
            powerWatts: 450.0,
            heartRateBpm: 185.0,
            sunDirection: vm.Vector3(0.4, 0.85, 0.35).normalized(),
            sunlightIntensity: 1.0,
            timeSeconds: 0.8,
          ),
        );

        final ColdBreathAndSweatState overcastWarm = engine.evaluateFrame(
          ColdBreathAndSweatFrameInput(
            ambientTemperatureCelsius: 29.5,
            powerWatts: 250.0,
            heartRateBpm: 140.0,
            sunlightIntensity: 0.1,
            timeSeconds: 0.8,
          ),
        );

        expect(
          sunnyHot.sweatSheen.peakSpecularIntensity,
          greaterThan(overcastWarm.sweatSheen.peakSpecularIntensity),
        );
        expect(
          sunnyHot.sweatSheen.estimatedSweatLossLitersPerHour,
          greaterThan(overcastWarm.sweatSheen.estimatedSweatLossLitersPerHour),
        );
      },
    );

    test('obsługuje bezpiecznie wartości brzegowe NaN i ujemne', () {
      final ColdBreathAndSweatState safeState = engine.evaluateFrame(
        ColdBreathAndSweatFrameInput(
          ambientTemperatureCelsius: double.nan,
          altitudeMeters: -200.0,
          relativeHumidity: 2.5,
          powerWatts: -50.0,
          riderSpeedMs: double.infinity,
          sunlightIntensity: -1.0,
          timeSeconds: -5.0,
        ),
      );

      expect(safeState.ambientTemperatureCelsius.isFinite, isTrue);
      expect(safeState.altitudeMeters, greaterThanOrEqualTo(0.0));
      expect(safeState.breathVapor.respiratoryRateBpm.isFinite, isTrue);
    });
  });

  group('ColdBreathAndSweatControlPanel responsive UI', () {
    for (final Size viewport in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnienia w rozdzielczości ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: const Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(12),
                  child: ColdBreathAndSweatControlPanel(
                    initialPreset:
                        ThermalPhysiologyConditionPreset.alpineSummitCold,
                  ),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          expect(
            find.text('Fizjologia 3D: Para Oddechowa i Połysk Potu'),
            findsOneWidget,
          );

          await tester.tap(find.text('Upał 33.5°C'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);

          await tester.tap(find.byIcon(Icons.pause_rounded));
          await tester.pump(const Duration(milliseconds: 200));
          expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
        },
      );
    }
  });
}
