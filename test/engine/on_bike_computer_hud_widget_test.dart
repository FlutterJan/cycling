// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/rendering3d/on_bike_computer_hud_widget.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/state/race_simulation_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Pomocniczy generator snapshotu kolarza
  RiderPositionSnapshot createSnapshot({
    required String riderId,
    required double distMeters,
    required double speedKmh,
    required int powerWatts,
    required double wattsPerKg,
    required int cadenceRpm,
    required int heartRateBpm,
    required double gradientPercent,
    double elevationMeters = 500.0,
  }) {
    return RiderPositionSnapshot(
      riderId: riderId,
      riderName: 'T. Pogacar',
      bibNumber: 1,
      teamId: 'team_uae',
      teamName: 'UAE Team Emirates',
      teamJerseyHexColor: '#FFFFFF',
      isPlayerRider: true,
      distanceCoveredMeters: distMeters,
      kilometerMark: distMeters / 1000.0,
      elevationMeters: elevationMeters,
      currentGradientPercent: gradientPercent,
      currentSegmentIndex: 0,
      speedMs: speedKmh / 3.6,
      speedKmh: speedKmh,
      powerWatts: powerWatts,
      wattsPerKg: wattsPerKg,
      cadenceRpm: cadenceRpm,
      heartRateBpm: heartRateBpm,
      wPrimePercentage: 0.85,
      wPrimeJoules: 18000.0,
      glycogenPercentage: 0.80,
      glycogenGrams: 360.0,
      hydrationPercent: 0.92,
      bidonsLeft: 2,
      gelsLeft: 3,
      activeTacticalOrder: TacticalOrder.holdPosition,
      groupIndex: 0,
      groupType: GroupType.peloton,
      timeGapToLeaderSeconds: 0.0,
      lateralPositionRoad: 0.0,
      lateralOffsetRoadMeters: 0.0,
      isDrafting: false,
      draftingSavingsPercent: 0.0,
      isPulling: true,
      hasDefect: false,
      isCrashed: false,
      isDnf: false,
    );
  }

  /// Pomocnicza lista segmentów z podjazdami
  List<StageSegment> createSampleSegments() {
    return const [
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 10.0,
        startElevationM: 450.0,
        endElevationM: 520.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 20.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 1,
        startKm: 10.0,
        lengthKm: 8.0,
        startElevationM: 520.0,
        endElevationM: 1250.0, // Podjazd Kat. 1
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 65.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 45.0,
        sprintOrKomClassification: SegmentClassification.cat1,
      ),
      StageSegment(
        index: 2,
        startKm: 18.0,
        lengthKm: 12.0,
        startElevationM: 1250.0,
        endElevationM: 2150.0, // Podjazd HC
        surfaceType: SegmentSurfaceType.roughAsphalt,
        technicalDifficulty: 85.0,
        windDirectionDegrees: 240.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      ),
    ];
  }

  group('BikeDrivetrainSimulator - Kalkulator Przełożenia Napędu Di2', () {
    const simulator = BikeDrivetrainSimulator();

    test('dobiera twarde przełożenie 54x14 lub 54x13 na płaskim przy dużej prędkości', () {
      final gear = simulator.calculateGear(
        speedKmh: 46.5,
        cadenceRpm: 92,
        gradientPercent: 0.2,
      );

      expect(gear.frontTeeth, equals(54));
      expect(gear.isLargeChainring, isTrue);
      // Przy 46.5 km/h i 92 rpm rozwój wynosi ok. 8.42m / 2.105 = ratio ~4.0 (54/14 = 3.86 lub 54/13 = 4.15)
      expect(gear.rearTeeth, isIn([13, 14, 15]));
      expect(gear.displayString, contains('54x'));
    });

    test('dobiera miękkie przełożenie na stromej wspinaczce (mała tarcza 40T)', () {
      final gear = simulator.calculateGear(
        speedKmh: 14.5,
        cadenceRpm: 76,
        gradientPercent: 9.5, // 9.5% podjazdu
      );

      expect(gear.frontTeeth, equals(40));
      expect(gear.isLargeChainring, isFalse);
      expect(gear.rearTeeth, greaterThanOrEqualTo(24));
      expect(gear.displayString, contains('40x'));
    });

    test('dobiera najtwardszy bieg przy szybkiej jeździe na zjeździe bez pedałowania (luz)', () {
      final gear = simulator.calculateGear(
        speedKmh: 68.0,
        cadenceRpm: 0,
        gradientPercent: -6.5,
      );

      expect(gear.frontTeeth, equals(54));
      expect(gear.rearTeeth, equals(11));
      expect(gear.displayString, equals('54x11'));
    });
  });

  group('ClimbProAnalyzer - Analiza Podjazdów i Kolorów Gradientu', () {
    final segments = createSampleSegments();

    test('wykrywa aktywny podjazd Kat. 1 gdy kolarz jedzie na 14. kilometrze', () {
      final climbPro = ClimbProAnalyzer.analyzeClimb(
        currentDistanceMeters: 14000.0, // 14 km (środek segmentu 10-18 km)
        segments: segments,
        currentElevationMeters: 885.0,
        currentGradientPercent: 8.2,
      );

      expect(climbPro.hasClimb, isTrue);
      expect(climbPro.isActivelyClimbing, isTrue);
      expect(climbPro.categoryTag, equals('KAT. 1'));
      expect(climbPro.remainingDistKm, closeTo(4.0, 0.1)); // Do 18 km zostało 4 km
      expect(climbPro.remainingElevationGainM, closeTo(365.0, 5.0)); // 1250 - 885 m
      expect(climbPro.avgRemainingGradientPercent, greaterThan(7.0));
      expect(climbPro.slices.isNotEmpty, isTrue);
    });

    test('wykrywa zbliżający się podjazd gdy kolarz jedzie po płaskim w zasięgu 15 km', () {
      final climbPro = ClimbProAnalyzer.analyzeClimb(
        currentDistanceMeters: 4000.0, // 4 km (przed podjazdem zaczynającym się w 10 km)
        segments: segments,
        currentElevationMeters: 480.0,
        currentGradientPercent: 0.5,
      );

      expect(climbPro.hasClimb, isTrue);
      expect(climbPro.isActivelyClimbing, isFalse);
      expect(climbPro.remainingDistKm, closeTo(6.0, 0.1)); // 10 km - 4 km = 6 km do rozpoczęcia
    });

    test('zwraca prawidłowe kolory nachylenia Garmin ClimbPro', () {
      expect(ClimbProAnalyzer.getGradientColor(-3.0), equals(const Color(0xFF38BDF8))); // Zjazd
      expect(ClimbProAnalyzer.getGradientColor(2.0), equals(const Color(0xFF10B981))); // 0-3% zielony
      expect(ClimbProAnalyzer.getGradientColor(4.5), equals(const Color(0xFFEAB308))); // 3-6% żółty
      expect(ClimbProAnalyzer.getGradientColor(7.5), equals(const Color(0xFFF97316))); // 6-9% pomarańczowy
      expect(ClimbProAnalyzer.getGradientColor(10.5), equals(const Color(0xFFEF4444))); // 9-12% czerwony
      expect(ClimbProAnalyzer.getGradientColor(14.0), equals(const Color(0xFF9333EA))); // >12% fiolet
    });
  });

  group('OnBikeComputerHudWidget - Interfejs Użytkownika i Renderowanie HUD', () {
    testWidgets('poprawnie renderuje komputer Garmin Edge z pełną siatką danych', (tester) async {
      final snapshot = createSnapshot(
        riderId: 'pogi',
        distMeters: 14000.0,
        speedKmh: 46.2,
        powerWatts: 425,
        wattsPerKg: 6.4,
        cadenceRpm: 94,
        heartRateBpm: 172,
        gradientPercent: 7.8,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnBikeComputerHudWidget(
              riderSnapshot: snapshot,
              segments: createSampleSegments(),
              model: BikeComputerModel.garminEdge,
              initialLayoutMode: BikeComputerLayoutMode.standard,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 32));

      // 1. Sprawdzenie marki Garmin
      expect(find.text('GARMIN'), findsOneWidget);

      // 2. Sprawdzenie etykiet danych
      expect(find.text('MOC 3s'), findsOneWidget);
      expect(find.text('425'), findsOneWidget);
      expect(find.text('STOSUNEK'), findsOneWidget);
      expect(find.text('6.4'), findsOneWidget);

      // 3. Sprawdzenie prędkości i kadencji
      expect(find.text('PRĘDKOŚĆ'), findsOneWidget);
      expect(find.text('46.2'), findsOneWidget);
      expect(find.text('KADENCJA'), findsOneWidget);
      expect(find.text('94'), findsOneWidget);

      // 4. Sprawdzenie tętna i przełożenia
      expect(find.text('TĘTNO'), findsOneWidget);
      expect(find.text('172'), findsOneWidget);
      expect(find.text('PRZEŁOŻENIE'), findsOneWidget);
      expect(find.textContaining('x'), findsWidgets); // np. 54x14

      // 5. Sprawdzenie banera ClimbPro
      expect(find.textContaining('Podjazd'), findsOneWidget);
      expect(find.text('+7.8%'), findsOneWidget);
    });

    testWidgets('w trybie Wahoo Elemnt wyświetla matrycę diod QuickLook LEDs', (tester) async {
      final snapshot = createSnapshot(
        riderId: 'wout',
        distMeters: 5000.0,
        speedKmh: 44.0,
        powerWatts: 450,
        wattsPerKg: 5.8,
        cadenceRpm: 90,
        heartRateBpm: 168,
        gradientPercent: 1.2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnBikeComputerHudWidget(
              riderSnapshot: snapshot,
              segments: createSampleSegments(),
              model: BikeComputerModel.wahooElemnt,
              initialLayoutMode: BikeComputerLayoutMode.standard,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 32));

      // Sprawdzenie marki wahoo
      expect(find.text('wahoo'), findsOneWidget);
    });

    testWidgets('pozwala na przełączanie trybów ekranu poprzez kliknięcie w komputer', (tester) async {
      final snapshot = createSnapshot(
        riderId: 'jonas',
        distMeters: 14000.0,
        speedKmh: 22.0,
        powerWatts: 410,
        wattsPerKg: 6.8,
        cadenceRpm: 82,
        heartRateBpm: 178,
        gradientPercent: 8.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnBikeComputerHudWidget(
              riderSnapshot: snapshot,
              segments: createSampleSegments(),
              initialLayoutMode: BikeComputerLayoutMode.standard,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 32));

      // 1. Kliknięcie przełącza do ClimbPro Focus
      await tester.tap(find.byType(OnBikeComputerHudWidget));
      await tester.pump(const Duration(milliseconds: 32));
      expect(find.textContaining('W/kg'), findsWidgets);

      // 2. Kolejne kliknięcie przełącza do Compact Bar
      await tester.tap(find.byType(OnBikeComputerHudWidget));
      await tester.pump(const Duration(milliseconds: 32));
      expect(find.text('PWR'), findsOneWidget);
      expect(find.text('GEAR'), findsOneWidget);

      // 3. Kolejne kliknięcie przełącza do Minimized Pill
      await tester.tap(find.byType(OnBikeComputerHudWidget));
      await tester.pump(const Duration(milliseconds: 32));
      expect(find.textContaining('W'), findsWidgets);
    });

    testWidgets('zwraca pusty widget gdy isVisible = false lub riderSnapshot = null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnBikeComputerHudWidget(
              riderSnapshot: null,
              isVisible: true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('MOC 3s'), findsNothing);

      final snapshot = createSnapshot(
        riderId: 'remco',
        distMeters: 2000.0,
        speedKmh: 50.0,
        powerWatts: 460,
        wattsPerKg: 7.0,
        cadenceRpm: 98,
        heartRateBpm: 180,
        gradientPercent: 0.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnBikeComputerHudWidget(
              riderSnapshot: snapshot,
              isVisible: false, // Ukryty
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('MOC 3s'), findsNothing);
    });
  });
}

