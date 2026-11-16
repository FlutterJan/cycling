import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/rendering3d/jersey_zipper_and_fabric_flutter_fx.dart';

void main() {
  group('JerseyZipperAndFabricFlutterFx', () {
    test('rozpina zamek na piersi podczas wspinaczki w upale', () {
      final JerseyZipperAndFabricFlutterFx fx = JerseyZipperAndFabricFlutterFx();
      final JerseyFabricFlutterState state = fx.evaluateFrame(
        input: JerseyFabricFlutterFrameInput.fromPreset(
          FabricFlutterConditionPreset.alpineHeatClimb,
        ),
        elapsedSeconds: 1.25,
      );

      expect(state.zipperState.isAutoUnzippedForHeatClimb, isTrue);
      expect(state.zipperState.unzippedRatio, greaterThan(0.55));
      expect(state.zipperState.openingLengthCm, greaterThan(15.0));
      expect(state.zipperState.chestSkinExposureRatio, greaterThan(0.5));
    });

    test('dopina zamek przy dużej prędkości na finiszu lub zjeździe', () {
      final JerseyZipperAndFabricFlutterFx fx = JerseyZipperAndFabricFlutterFx();
      final JerseyFabricFlutterState sprintState = fx.evaluateFrame(
        input: JerseyFabricFlutterFrameInput.fromPreset(
          FabricFlutterConditionPreset.sprintFinish72Kmh,
        ),
        elapsedSeconds: 2.0,
      );

      expect(sprintState.zipperState.unzippedRatio, equals(0.0));
      expect(sprintState.zipperState.isAutoUnzippedForHeatClimb, isFalse);
    });

    test('kurtka przeciwdeszczowa łopocze znacznie mocniej niż koszulka aero i ma zamknięty zamek', () {
      final JerseyZipperAndFabricFlutterFx fx = JerseyZipperAndFabricFlutterFx();
      final JerseyFabricFlutterState aeroState = fx.evaluateFrame(
        input: const JerseyFabricFlutterFrameInput(
          riderId: 'r1',
          speedKmh: 60.0,
          temperatureCelsius: 14.0,
          gradientPercent: -5.0,
          powerWatts: 180.0,
          garmentType: GarmentOuterLayerType.raceAeroJersey,
          isWearingRainJacket: false,
        ),
        elapsedSeconds: 0.8,
      );
      final JerseyFabricFlutterState rainState = fx.evaluateFrame(
        input: const JerseyFabricFlutterFrameInput(
          riderId: 'r1',
          speedKmh: 60.0,
          temperatureCelsius: 14.0,
          gradientPercent: -5.0,
          powerWatts: 180.0,
          garmentType: GarmentOuterLayerType.rainShellJacket,
          isWearingRainJacket: true,
        ),
        elapsedSeconds: 0.8,
      );

      expect(rainState.leftSleeve.amplitudeMm, greaterThan(aeroState.leftSleeve.amplitudeMm * 2.5));
      expect(rainState.rainJacketCape.amplitudeMm, greaterThan(aeroState.rainJacketCape.amplitudeMm * 4.0));
      expect(rainState.zipperState.unzippedRatio, equals(0.0));
      expect(rainState.aeroDragPenaltyWatts, greaterThan(aeroState.aeroDragPenaltyWatts));
    });

    test('boczny wiatr różnicuje drgania lewego i prawego rękawka', () {
      final JerseyZipperAndFabricFlutterFx fx = JerseyZipperAndFabricFlutterFx();
      final JerseyFabricFlutterState state = fx.evaluateFrame(
        input: const JerseyFabricFlutterFrameInput(
          riderId: 'r2',
          speedKmh: 46.0,
          headwindKmh: 15.0,
          crosswindAngleRad: math.pi / 3.0,
          temperatureCelsius: 20.0,
          gradientPercent: 0.0,
          powerWatts: 310.0,
        ),
        elapsedSeconds: 0.5,
      );

      expect(state.leftSleeve.amplitudeMm, greaterThan(state.rightSleeve.amplitudeMm));
      expect(state.leftSleeve.crestOffsetsMm.length, equals(4));
      expect(state.rightSleeve.crestOffsetsMm.length, equals(4));
    });

    test('step płynnie wygładza rozpinanie i zapinanie zamka w czasie', () {
      final JerseyZipperAndFabricFlutterFx fx = JerseyZipperAndFabricFlutterFx();
      final JerseyFabricFlutterFrameInput climbInput = JerseyFabricFlutterFrameInput.fromPreset(
        FabricFlutterConditionPreset.alpineHeatClimb,
      );
      final JerseyFabricFlutterFrameInput sprintInput = JerseyFabricFlutterFrameInput.fromPreset(
        FabricFlutterConditionPreset.sprintFinish72Kmh,
      );

      final JerseyFabricFlutterState initial = fx.step(
        input: climbInput,
        dtSeconds: 0.016,
        elapsedSeconds: 0.016,
      );
      final JerseyFabricFlutterState transition = fx.step(
        input: sprintInput,
        dtSeconds: 0.1,
        elapsedSeconds: 0.116,
      );

      expect(initial.zipperState.unzippedRatio, greaterThan(0.5));
      expect(transition.zipperState.unzippedRatio, lessThan(initial.zipperState.unzippedRatio));
      expect(transition.zipperState.unzippedRatio, greaterThan(0.0));
    });
  });

  group('JerseyZipperAndFabricFlutterPanel UI', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: JerseyZipperAndFabricFlutterPanel(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renderuje się poprawnie bez przepełnień na 390x844 (mobile)', (WidgetTester tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.text('Aerodynamika Odzieży i Zamka 3D'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się poprawnie bez przepełnień na 1024x768 (tablet)', (WidgetTester tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('Aerodynamika Odzieży i Zamka 3D'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się poprawnie bez przepełnień na 1600x900 (desktop)', (WidgetTester tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(find.text('Aerodynamika Odzieży i Zamka 3D'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('przełącza scenariusze i warstwę kurtki przeciwdeszczowej', (WidgetTester tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));

      await tester.tap(find.text('Zjazd w deszczu'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Kurtka przeciwdeszczowa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
