// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/engine/physics/bike_fit_and_wind_tunnel_engine.dart';
import 'package:pro_peloton_manager/models/equipment/bike_fit_configuration.dart';
import 'package:pro_peloton_manager/models/equipment/complete_bike.dart';
import 'package:pro_peloton_manager/models/equipment/frame_model.dart';
import 'package:pro_peloton_manager/models/equipment/groupset_model.dart';
import 'package:pro_peloton_manager/models/equipment/tire_model.dart';
import 'package:pro_peloton_manager/models/equipment/wheelset_model.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';
import 'package:pro_peloton_manager/ui/screens/wind_tunnel_and_bike_fit_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Rider testRider;
  late CompleteBike testBike;

  setUp(() {
    testRider = RiderProceduralGenerator.generateRider(
      specialization: RiderSpecialization.timeTrialist,
      targetOverallRating: 88,
    );

    testBike = const CompleteBike(
      id: 'test_bike_01',
      name: 'Aero Test Machine',
      frame: FrameModel(
        id: 'f_test',
        brandId: 'brand_test',
        name: 'Aero Speed Frame',
        category: FrameCategory.aero,
        weightGrams: 890,
        aeroCdaModifier: -0.016,
        stiffnessToWeightIndex: 2.1,
        comfortCompliance: 0.65,
        priceEur: 4000,
        mesh3dAssetPath: 'models/bike.glb',
        primaryColorHex: '#00E5FF',
      ),
      wheelset: WheelsetModel(
        id: 'w_test',
        brandId: 'brand_test',
        name: 'Aero 60mm Wheels',
        rimDepthMm: 60,
        weightGrams: 1400,
        aeroCdaModifier: -0.012,
        crosswindStabilityPenalty: 0.25,
        momentOfInertia: 0.12,
        hubEngagementDragWatts: 0.5,
        priceEur: 1800,
      ),
      groupset: GroupsetModel(
        id: 'g_test',
        brandId: 'brand_shim',
        name: 'Electronic 12s',
        weightGrams: 2200,
        isElectronic: true,
        speedCount: 12,
        mechanicalEfficiency: 0.985,
        priceEur: 2500,
      ),
      tire: TireModel(
        id: 't_test',
        brandId: 'brand_conti',
        name: 'Race Tire 28mm',
        widthMm: 28,
        weightGrams: 220,
        rollingResistanceCrr: 0.0030,
        punctureResistanceIndex: 3.5,
        wetGripIndex: 4.2,
        isTubeless: true,
        priceEur: 80,
      ),
      cockpitWidthMm: 380,
      hoodInwardTiltDegrees: 12.0,
      slammedStem: true,
    );
  });

  Widget createTestWidget({String? riderId, bool showAppBar = true}) {
    return ProviderScope(
      child: MaterialApp(
        home: WindTunnelAndBikeFitScreen(
          initialRiderId: riderId,
          showAppBar: showAppBar,
        ),
      ),
    );
  }

  group('WindTunnelAndBikeFitScreen - Renderowanie i Elementy UI', () {
    testWidgets('Poprawnie renderuje ekran z nagłówkiem i komorą tunelu',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget(showAppBar: true));
      await tester.pump(const Duration(milliseconds: 100));

      // Weryfikacja nagłówka AppBar
      expect(find.text('TUNEL AERODYNAMICZNY & BIKE FITTING'), findsOneWidget);

      // Weryfikacja komory tunelu
      expect(find.text('KOMORA TESTOWA TUNELU AERODYNAMICZNEGO'), findsOneWidget);

      // Weryfikacja prędkości wiatru 45 KM/H
      expect(find.text('V_WIND: 45 KM/H'), findsOneWidget);

      // Weryfikacja kart telemetrii
      expect(find.text('WSPÓŁCZYNNIK OPORU (CdA)'), findsOneWidget);
      expect(find.text('WYMAGANA MOC @ 45 KM/H'), findsOneWidget);
      expect(find.text('DARMOWE WATY (FREE WATTS)'), findsOneWidget);
      expect(find.text('SIŁA BOCZNA & CZAS 40 KM'), findsOneWidget);

      // Weryfikacja panelu zdrowotnego
      expect(find.text('KOMFORT, ZDROWIE STAWÓW I SPADEK MOCY W GÓRACH'), findsOneWidget);
      expect(find.text('Komfort Ogólny:'), findsOneWidget);
      expect(find.text('Ryzyko Urazu Kolan:'), findsOneWidget);
      expect(find.text('Przeciążenie Pleców:'), findsOneWidget);
      expect(find.text('Kara Mocy w Górach:'), findsOneWidget);

      // Weryfikacja panelu suwaków studia
      expect(find.text('STUDIO BIKE FITTINGU'), findsOneWidget);
      expect(find.text('1. STREFA SIODEŁKA (SADDLE)'), findsOneWidget);
      expect(find.text('2. KOKPIT, MOSTEK I KLAMKI'), findsOneWidget);
      expect(find.text('3. DŁUGOŚĆ KORB I BLOKI'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Renderuje w trybie bez AppBara (np. w Shellu kariery)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget(showAppBar: false));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('STUDIO BIKE FITTINGU & TUNEL AERODYNAMICZNY'), findsOneWidget);
      expect(find.text('Cyfrowy tunel aerodynamiczny WorldTour i analiza kinematyki stawów'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });
  });

  group('WindTunnelAndBikeFitScreen - Interaktywne Kontrolki i Presety', () {
    testWidgets('Przełączanie presetów aktualizuje fitting i zysk watów',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Kliknięcie w preset "Slammed Aero Road"
      final slammedChip = find.text('Slammed Aero Road');
      expect(slammedChip, findsOneWidget);
      await tester.tap(slammedChip);
      await tester.pump(const Duration(milliseconds: 100));

      // Weryfikacja, że podkładki są 0 mm (Slammed)
      expect(find.text('0 mm (Slammed)'), findsOneWidget);

      // Kliknięcie w preset "Cobbled Endurance"
      final cobbledChip = find.text('Cobbled Endurance');
      expect(cobbledChip, findsOneWidget);
      await tester.tap(cobbledChip);
      await tester.pump(const Duration(milliseconds: 100));

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Przełączanie fazy korby (GMP / Faza Mocy / DMP / Animacja)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Domyślnie GMP
      expect(find.text('GMP (TDC - 12:00) • Kąt Biodra'), findsOneWidget);

      // Przełączenie na DMP
      final dmpChip = find.text('DMP (BDC - 6:00) • Kąt Kolana');
      expect(dmpChip, findsOneWidget);
      await tester.tap(dmpChip);
      await tester.pump(const Duration(milliseconds: 100));

      // Przełączenie na Fazę Mocy
      final powerChip = find.text('Faza Mocy (3:00)');
      expect(powerChip, findsOneWidget);
      await tester.tap(powerChip);
      await tester.pump(const Duration(milliseconds: 100));

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Toggling dymu i kątów biomechanicznych',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Kliknięcie chipu 'Dym Tunelu'
      final smokeChip = find.text('Dym Tunelu');
      expect(smokeChip, findsOneWidget);
      await tester.tap(smokeChip);
      await tester.pump(const Duration(milliseconds: 100));

      // Kliknięcie chipu 'Kąty Biomechaniczne'
      final angleChip = find.text('Kąty Biomechaniczne');
      expect(angleChip, findsOneWidget);
      await tester.tap(angleChip);
      await tester.pump(const Duration(milliseconds: 100));

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Zapisanie fittingu wyświetla SnackBar z potwierdzeniem watów',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      final saveButton = find.text('Zapisz Fitting');
      expect(saveButton, findsOneWidget);
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump(const Duration(milliseconds: 350));

      // SnackBar
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Zapisano fitting dla'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });
  });

  group('RiderBikeFitGeometryPainter & WindTunnelPolarChartPainter - Testy Rysowania', () {
    test('RiderBikeFitGeometryPainter rysuje kolarza bez rzucania wyjątków', () {
      final fit = BikeFitConfiguration.slammedAeroRoad();
      final eval = BikeFitAndWindTunnelEngine.evaluateFit(
        fit: fit,
        physiology: testRider.physiology,
        skills: testRider.skills,
        bike: testBike,
        riderAge: testRider.age,
        testingAirSpeedKmh: 45.0,
      );

      final painter = RiderBikeFitGeometryPainter(
        fit: fit,
        rider: testRider,
        bike: testBike,
        crankMode: CrankKinematicMode.topDeadCenter,
        animationPhase: 0.35,
        yawAngleDegrees: 7.5,
        showSmokeStreamers: true,
        showJointAngleBadges: true,
        evaluationReport: eval,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(520, 360);

      expect(() => painter.paint(canvas, size), returnsNormally);
      final picture = recorder.endRecording();
      picture.dispose();
    });

    test('WindTunnelPolarChartPainter rysuje wykres polarny bez wyjątków', () {
      final fit = BikeFitConfiguration.uciWorldTourBalanced();
      final polarReport = BikeFitAndWindTunnelEngine.simulateWindTunnelSweep(
        fit: fit,
        physiology: testRider.physiology,
        airSpeedKmh: 45.0,
      );

      final painter = WindTunnelPolarChartPainter(
        report: polarReport,
        currentYawDegrees: 5.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(400, 120);

      expect(() => painter.paint(canvas, size), returnsNormally);
      final picture = recorder.endRecording();
      picture.dispose();
    });
  });
}
