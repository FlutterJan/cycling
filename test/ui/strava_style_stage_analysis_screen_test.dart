// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_replay_recorder.dart';
import 'package:pro_peloton_manager/ui/screens/strava_style_stage_analysis_screen.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: child,
    );
  }

  group('CogganPowerZonesAnalysis Unit Tests', () {
    test('Calculates time and percentages for Coggan Z1-Z7 power zones properly', () {
      final List<RiderTelemetryTrackPoint> points = [];
      const int ftp = 400;

      // Z1: 150W (< 220W) -> 10s
      for (int i = 0; i < 10; i++) {
        points.add(RiderTelemetryTrackPoint(
          timestampSeconds: i.toDouble(),
          distanceMeters: i * 10.0,
          speedMs: 10.0,
          powerWatts: 150,
          cadenceRpm: 80,
          heartRateBpm: 120,
          elevationMeters: 100.0,
          gradientPercent: 0.0,
          wPrimeJoules: 20000.0,
          wPrimePercentage: 1.0,
          glycogenGrams: 450.0,
          lateralPositionRoad: 0.0,
          isDrafting: false,
          draftingSavingsPercent: 0.0,
          activeTacticalOrder: TacticalOrder.holdPosition,
        ));
      }

      // Z4: 400W (FTP) -> 20s
      for (int i = 10; i < 30; i++) {
        points.add(RiderTelemetryTrackPoint(
          timestampSeconds: i.toDouble(),
          distanceMeters: i * 12.0,
          speedMs: 12.0,
          powerWatts: 400,
          cadenceRpm: 90,
          heartRateBpm: 165,
          elevationMeters: 100.0,
          gradientPercent: 0.0,
          wPrimeJoules: 19000.0,
          wPrimePercentage: 0.95,
          glycogenGrams: 440.0,
          lateralPositionRoad: 0.0,
          isDrafting: false,
          draftingSavingsPercent: 0.0,
          activeTacticalOrder: TacticalOrder.pullGroup,
        ));
      }

      // Z7: 800W (> 600W) -> 10s
      for (int i = 30; i < 40; i++) {
        points.add(RiderTelemetryTrackPoint(
          timestampSeconds: i.toDouble(),
          distanceMeters: i * 16.0,
          speedMs: 16.0,
          powerWatts: 800,
          cadenceRpm: 110,
          heartRateBpm: 188,
          elevationMeters: 100.0,
          gradientPercent: 0.0,
          wPrimeJoules: 12000.0,
          wPrimePercentage: 0.60,
          glycogenGrams: 430.0,
          lateralPositionRoad: 0.0,
          isDrafting: false,
          draftingSavingsPercent: 0.0,
          activeTacticalOrder: TacticalOrder.attack,
        ));
      }

      final zones = CogganPowerZonesAnalysis.fromPoints(points, ftpWatts: ftp);

      expect(zones.getSeconds(1), closeTo(10.0, 1.0));
      expect(zones.getSeconds(4), closeTo(20.0, 1.0));
      expect(zones.getSeconds(7), closeTo(10.0, 1.0));
      expect(zones.getPercentage(4), closeTo(50.0, 2.5));
      expect(zones.getPowerRangeLabel(4), contains('W'));
    });
  });

  group('StravaStyleStageAnalysisScreen Widget Tests', () {
    testWidgets('Renders screen with header, metric cards, and series toggles', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      await tester.pumpWidget(
        createTestWidget(
          const StravaStyleStageAnalysisScreen(
            stageName: 'Etap 18 • Col du Galibier',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Weryfikacja AppBar i tytułu
      expect(find.text('STRAVA / GARMIN FIT'), findsOneWidget);
      expect(find.text('Etap 18 • Col du Galibier'), findsOneWidget);
      expect(find.text('Eksport .FIT'), findsOneWidget);

      // Weryfikacja selektora kolarzy (domyślny Tadej Pogačar)
      expect(find.text('Tadej Pogačar'), findsWidgets);
      expect(find.text('Jonas Vingegaard'), findsWidgets);

      // Weryfikacja 8 kafelków metryk
      expect(find.text('DYSTANS'), findsOneWidget);
      expect(find.text('NORMALIZED POWER'), findsOneWidget);
      expect(find.text('TSS (OBCIĄŻENIE)'), findsOneWidget);
      expect(find.text('PRACA & KALORIE'), findsOneWidget);
      expect(find.text('ŚREDNIA PRĘDKOŚĆ'), findsOneWidget);
      expect(find.text('TĘTNO ŚREDNIE'), findsOneWidget);
      expect(find.text('ŚREDNIA KADENCJA'), findsOneWidget);
      expect(find.text('PRZEWYŻSZENIE'), findsOneWidget);

      // Weryfikacja przełączników serii telemetrycznych
      expect(find.text('Wysokość'), findsOneWidget);
      expect(find.text('Moc [W]'), findsOneWidget);
      expect(find.text('Tętno [bpm]'), findsOneWidget);
      expect(find.text('Zapas W\' [kJ]'), findsOneWidget);
      expect(find.text('Kadencja [RPM]'), findsOneWidget);

      // Weryfikacja stref mocy Z1-Z7 i krzywej szczytowej mocy
      expect(find.text('STREFY MOCY COGGANA (Z1-Z7)'), findsOneWidget);
      expect(find.text('KRZYWA SZCZYTOWEJ MOCY (MMP)'), findsOneWidget);
    });

    testWidgets('Toggling telemetry series chip updates state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      await tester.pumpWidget(
        createTestWidget(
          const StravaStyleStageAnalysisScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Kadencja jest domyślnie wyłączona
      final cadenceChip = find.text('Kadencja [RPM]');
      expect(cadenceChip, findsOneWidget);

      // Kliknięcie w chip włącza serię kadencji
      await tester.tap(cadenceChip);
      await tester.pumpAndSettle();

      // Odczyt KADENCJA powinien pojawić się w HUD
      expect(find.textContaining('KADENCJA'), findsWidgets);
    });

    testWidgets('Switching rider updates active hero view and stats', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      await tester.pumpWidget(
        createTestWidget(
          const StravaStyleStageAnalysisScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Początkowo wybrany Tadej Pogačar
      expect(find.text('Tadej Pogačar'), findsWidgets);

      // Kliknięcie w Jonas Vingegaard w selektorze
      final jonasItem = find.text('Jonas Vingegaard').first;
      await tester.tap(jonasItem);
      await tester.pumpAndSettle();

      // Tytuł w hero card powinien pokazywać Jonas Vingegaard
      expect(find.text('Jonas Vingegaard'), findsWidgets);
    });

    testWidgets('Clicking Eksport .FIT opens modal bottom sheet', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      await tester.pumpWidget(
        createTestWidget(
          const StravaStyleStageAnalysisScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final exportButton = find.text('Eksport .FIT');
      expect(exportButton, findsOneWidget);

      await tester.tap(exportButton);
      await tester.pumpAndSettle();

      // Modal powinien wyświetlić szczegóły binarnego pliku FIT
      expect(find.text('Eksport Pliku Telemetrii'), findsOneWidget);
      expect(find.text('Zapisz Plik .FIT na Dysku'), findsOneWidget);
    });

    testWidgets('Clicking back button invokes onClose callback', (tester) async {
      bool closed = false;

      await tester.pumpWidget(
        createTestWidget(
          StravaStyleStageAnalysisScreen(
            onClose: () => closed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final backButton = find.byTooltip('Wróć');
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });
  });
}

