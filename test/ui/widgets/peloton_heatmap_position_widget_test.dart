// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/widgets/peloton_heatmap_position_widget.dart';

void main() {
  List<PlayerPelotonRider> createTestTeam() {
    return [
      const PlayerPelotonRider(
        id: 'r1',
        name: 'Tadej Pogačar',
        bibNumber: 1,
        isLeader: true,
        lateralOffset: 0.0,
        depthPercent: 0.25,
        currentWatts: 310.0,
        draftingSavingsPercent: 42.0,
      ),
      const PlayerPelotonRider(
        id: 'r2',
        name: 'Rafał Majka',
        bibNumber: 2,
        lateralOffset: -0.1,
        depthPercent: 0.20,
        currentWatts: 340.0,
        draftingSavingsPercent: 38.0,
      ),
      const PlayerPelotonRider(
        id: 'r3',
        name: 'Domen Novak',
        bibNumber: 3,
        lateralOffset: 0.1,
        depthPercent: 0.18,
        currentWatts: 360.0,
        draftingSavingsPercent: 35.0,
      ),
      const PlayerPelotonRider(
        id: 'r4',
        name: 'Tim Wellens',
        bibNumber: 4,
        lateralOffset: -0.2,
        depthPercent: 0.32,
        currentWatts: 280.0,
        draftingSavingsPercent: 40.0,
      ),
      const PlayerPelotonRider(
        id: 'r5',
        name: 'Nils Politt',
        bibNumber: 5,
        lateralOffset: 0.2,
        depthPercent: 0.15,
        currentWatts: 390.0,
        draftingSavingsPercent: 28.0,
      ),
      const PlayerPelotonRider(
        id: 'r6',
        name: 'Marc Soler',
        bibNumber: 6,
        lateralOffset: 0.0,
        depthPercent: 0.40,
        currentWatts: 260.0,
        draftingSavingsPercent: 41.0,
      ),
      const PlayerPelotonRider(
        id: 'r7',
        name: 'Pavel Sivakov',
        bibNumber: 7,
        lateralOffset: -0.3,
        depthPercent: 0.38,
        currentWatts: 270.0,
        draftingSavingsPercent: 39.0,
      ),
      const PlayerPelotonRider(
        id: 'r8',
        name: 'Mikkel Bjerg',
        bibNumber: 8,
        lateralOffset: 0.0,
        depthPercent: 0.12,
        currentWatts: 420.0,
        draftingSavingsPercent: 22.0,
      ),
    ];
  }

  group('Modele i Enums - Siatka Peletonu', () {
    test('RoadGutterTarget fromOffset poprawnie mapuje pozycje szosy', () {
      expect(RoadGutterTarget.fromOffset(-0.85), equals(RoadGutterTarget.farLeft));
      expect(RoadGutterTarget.fromOffset(-0.50), equals(RoadGutterTarget.leftGutter));
      expect(RoadGutterTarget.fromOffset(0.0), equals(RoadGutterTarget.centerPack));
      expect(RoadGutterTarget.fromOffset(0.50), equals(RoadGutterTarget.rightGutter));
      expect(RoadGutterTarget.fromOffset(0.85), equals(RoadGutterTarget.farRight));
    });

    test('PelotonShapeType odkształca szyk zależnie od tempa i wiatru', () {
      // Wolne tempo 34 km/h -> Szeroka Ława
      expect(
        PelotonShapeType.fromSpeedAndWind(34.0),
        equals(PelotonShapeType.broadBunch),
      );

      // Średnie tempo 44 km/h -> Standardowy Szyk
      expect(
        PelotonShapeType.fromSpeedAndWind(44.0),
        equals(PelotonShapeType.standardPack),
      );

      // Piekielne tempo 60 km/h -> Pojedyncza Kreska (Single File)
      expect(
        PelotonShapeType.fromSpeedAndWind(60.0),
        equals(PelotonShapeType.strungOutSingleFile),
      );

      // Silny wiatr boczny 35 km/h -> Wachlarz (Echelon)
      expect(
        PelotonShapeType.fromSpeedAndWind(45.0, crosswindKmh: 35.0),
        equals(PelotonShapeType.crosswindEchelon),
      );
    });

    test('PlayerPelotonRider serializacja JSON i copyWith', () {
      const original = PlayerPelotonRider(
        id: 'test_1',
        name: 'Michał Kwiatkowski',
        bibNumber: 7,
        lateralOffset: -0.45,
        depthPercent: 0.22,
        isLeader: false,
        currentWatts: 320.0,
        draftingSavingsPercent: 39.5,
      );

      final json = original.toJson();
      final restored = PlayerPelotonRider.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.bibNumber, equals(7));
      expect(restored.lateralOffset, equals(-0.45));
      expect(restored.depthPercent, equals(0.22));

      final modified = original.copyWith(lateralOffset: 0.5, isLeader: true);
      expect(modified.lateralOffset, equals(0.5));
      expect(modified.isLeader, isTrue);
      expect(modified.id, equals(original.id));
    });
  });

  group('PelotonHeatmapPainter - Testy malowania', () {
    test('PelotonHeatmapPainter maluje szosę, heatmapę i kolarzy bez błędów', () {
      final painter = PelotonHeatmapPainter(
        pelotonSpeedKmh: 48.0,
        crosswindKmh: 20.0,
        crosswindAngleDeg: 45.0,
        targetLateralOffset: -0.5,
        playerRiders: createTestTeam(),
        upcomingHazard: const UpcomingRoadHazard(
          title: 'Ostry zakręt w lewo',
          description: 'Zajmij lewą stronę szosy',
          distanceMeters: 500,
          icon: Icons.turn_left,
          recommendedGutter: RoadGutterTarget.leftGutter,
        ),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(400, 400));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('shouldRepaint prawidłowo wykrywa zmiany prędkości i rozkazu', () {
      final p1 = PelotonHeatmapPainter(
        pelotonSpeedKmh: 40.0,
        targetLateralOffset: 0.0,
        playerRiders: createTestTeam(),
      );
      final p2 = PelotonHeatmapPainter(
        pelotonSpeedKmh: 55.0,
        targetLateralOffset: 0.0,
        playerRiders: createTestTeam(),
      );
      final p3 = PelotonHeatmapPainter(
        pelotonSpeedKmh: 40.0,
        targetLateralOffset: 0.6,
        playerRiders: createTestTeam(),
      );

      expect(p1.shouldRepaint(p2), isTrue);
      expect(p1.shouldRepaint(p3), isTrue);
      expect(p1.shouldRepaint(p1), isFalse);
    });
  });

  group('PelotonHeatmapPositionWidget - Testy UI i Interakcji Gestów', () {
    testWidgets('Poprawnie renderuje nagłówek, prędkość 34 km/h i Szeroką Ławę', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 700));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PelotonHeatmapPositionWidget(
              pelotonSpeedKmh: 34.0,
              playerRiders: createTestTeam(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Nagłówek i tempo
      expect(find.text('Przekrój Peletonu (Positioning Grid)'), findsOneWidget);
      expect(find.text('34 km/h'), findsOneWidget);
      expect(find.text('• Szeroka Ława'), findsOneWidget);

      // Presety stron
      expect(find.text('Lewa Strona'), findsOneWidget);
      expect(find.text('Środek Szosy'), findsOneWidget);
      expect(find.text('Prawa Strona'), findsOneWidget);

      // Telemetria
      expect(find.textContaining('Drafting: -'), findsOneWidget);
    });

    testWidgets('Przy prędkości 60 km/h szyk zmienia się na Pojedynczą Kreskę (Single File)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 700));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PelotonHeatmapPositionWidget(
              pelotonSpeedKmh: 60.0,
              playerRiders: createTestTeam(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('60 km/h'), findsOneWidget);
      expect(find.text('• Pojedyncza Kreska (Single File)'), findsOneWidget);
    });

    testWidgets('Wyświetla baner ostrzeżenia o zakręcie i pozwala zastosować pozycję jednym kliknięciem', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 700));
      double? callbackOffset;
      RoadGutterTarget? callbackPreset;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PelotonHeatmapPositionWidget(
              pelotonSpeedKmh: 46.0,
              playerRiders: createTestTeam(),
              upcomingHazard: const UpcomingRoadHazard(
                title: 'Ostry zakręt w lewo',
                description: 'Przesuń pociąg na lewo',
                distanceMeters: 650,
                icon: Icons.turn_left,
                recommendedGutter: RoadGutterTarget.leftGutter,
              ),
              onTeamGutterChanged: (offset) => callbackOffset = offset,
              onPresetSelected: (preset) => callbackPreset = preset,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Ostry zakręt w lewo (650m)'), findsOneWidget);

      // Kliknięcie "Zastosuj pozycję"
      final applyButton = find.text('Zastosuj pozycję');
      expect(applyButton, findsOneWidget);
      await tester.tap(applyButton);
      await tester.pump();

      expect(callbackPreset, equals(RoadGutterTarget.leftGutter));
      expect(callbackOffset, equals(RoadGutterTarget.leftGutter.lateralOffset));
    });

    testWidgets('Przeciągnięcie palcem (Pan Gesture) zmienia rozkaz strony szosy', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 700));
      double? reportedOffset;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PelotonHeatmapPositionWidget(
              pelotonSpeedKmh: 45.0,
              playerRiders: createTestTeam(),
              onTeamGutterChanged: (val) => reportedOffset = val,
            ),
          ),
        ),
      );
      await tester.pump();

      // Znalezienie dedykowanego obszaru CustomPaint szosy
      final canvasFinder = find.byKey(const ValueKey('peloton_heatmap_canvas'));
      expect(canvasFinder, findsOneWidget);

      // Wykonanie gestu przeciągnięcia w lewą stronę szosy
      await tester.drag(canvasFinder, const Offset(-150, 0));
      await tester.pump();

      expect(reportedOffset, isNotNull);
      expect(reportedOffset!, lessThan(0.0)); // Przesunięto w lewo
    });

    testWidgets('Kliknięcie w chip presetu Prawej Strony aktualizuje rozkaz', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 700));
      double? changedOffset;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PelotonHeatmapPositionWidget(
              pelotonSpeedKmh: 40.0,
              playerRiders: createTestTeam(),
              onTeamGutterChanged: (val) => changedOffset = val,
            ),
          ),
        ),
      );
      await tester.pump();

      final rightChip = find.text('Prawa Strona');
      expect(rightChip, findsOneWidget);
      await tester.tap(rightChip);
      await tester.pump();

      expect(changedOffset, equals(RoadGutterTarget.rightGutter.lateralOffset));
    });

    testWidgets('Kliknięcie w kolarza wywołuje onRiderTapped', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 700));
      PlayerPelotonRider? tappedRider;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PelotonHeatmapPositionWidget(
              pelotonSpeedKmh: 42.0,
              playerRiders: createTestTeam(),
              onRiderTapped: (r) => tappedRider = r,
            ),
          ),
        ),
      );
      await tester.pump();

      // Kliknięcie dokładnie w kolarza r1 (lider, offset 0.0, depth 0.25)
      final canvasFinder = find.byKey(const ValueKey('peloton_heatmap_canvas'));
      final canvasRect = tester.getRect(canvasFinder);
      final roadLeft = canvasRect.left + (canvasRect.width * 0.08);
      final roadRight = canvasRect.left + (canvasRect.width * 0.92);
      final riderX = roadLeft + ((roadRight - roadLeft) / 2.0);
      final riderY = canvasRect.top + (canvasRect.height * 0.25);

      await tester.tapAt(Offset(riderX, riderY));
      await tester.pump();

      expect(tappedRider, isNotNull);
      expect(tappedRider?.id, equals('r1'));
    });
  });
}
