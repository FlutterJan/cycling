// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/widgets/animated_watt_bomb_effect.dart';

void main() {
  group('WattBombDetector - Logika progów mocy i zrywu', () {
    test('Wykrywa sprint powyżej 1400 W jako Watt Bomb', () {
      expect(
        WattBombDetector.isWattBomb(watts: 1450.0, wkg: 10.0),
        isTrue,
      );
      expect(
        WattBombDetector.detectSurge(watts: 1450.0, wkg: 10.0),
        equals(WattBombSurgeType.sprintBomb),
      );
      expect(
        WattBombDetector.getSurgeLabel(WattBombSurgeType.sprintBomb),
        equals('WATT BOMB!'),
      );
    });

    test('Wykrywa atak górski powyżej 12.0 W/kg jako Attack Surge', () {
      expect(
        WattBombDetector.isWattBomb(watts: 850.0, wkg: 12.8, isMountain: true),
        isTrue,
      );
      expect(
        WattBombDetector.detectSurge(watts: 850.0, wkg: 12.8, isMountain: true),
        equals(WattBombSurgeType.mountainSurge),
      );
      expect(
        WattBombDetector.getSurgeLabel(WattBombSurgeType.mountainSurge),
        equals('ATTACK SURGE!'),
      );
    });

    test('Wykrywa legendarny zryw przekraczający oba progi', () {
      expect(
        WattBombDetector.detectSurge(watts: 1420.0, wkg: 12.5),
        equals(WattBombSurgeType.legendarySurge),
      );
      expect(
        WattBombDetector.getSurgeLabel(WattBombSurgeType.legendarySurge),
        equals('LEGENDARY SURGE!'),
      );
    });

    test('Zwykła jazda w peletonie nie aktywuje zrywu', () {
      expect(
        WattBombDetector.isWattBomb(watts: 400.0, wkg: 5.8),
        isFalse,
      );
      expect(
        WattBombDetector.detectSurge(watts: 400.0, wkg: 5.8),
        equals(WattBombSurgeType.none),
      );
      expect(
        WattBombDetector.getSurgeLabel(WattBombSurgeType.none),
        isEmpty,
      );
    });

    test('Generuje czytelne opisy taktyczne zrywu', () {
      final descSprint = WattBombDetector.getSurgeDescription(
        WattBombSurgeType.sprintBomb,
        1480.0,
        10.5,
      );
      expect(descSprint, contains('1480 W'));

      final descClimb = WattBombDetector.getSurgeDescription(
        WattBombSurgeType.mountainSurge,
        780.0,
        12.4,
      );
      expect(descClimb, contains('12.4 W/kg'));
    });
  });

  group('WattBombColorTheme & Paleta barwna', () {
    test('Kolory odpowiadają specyfikacji z promptu (#8E4A49 oraz #D4AF37)', () {
      expect(
        WattBombColorTheme.crimson.primaryColor,
        equals(const Color(0xFF8E4A49)),
      );
      expect(
        WattBombColorTheme.gold.primaryColor,
        equals(const Color(0xFFD4AF37)),
      );
    });
  });

  group('WattBombAuraPainter - CustomPainter testy', () {
    test('Aura painter maluje fale i iskry bez wyjątków', () {
      final painter = WattBombAuraPainter(
        pulseProgress: 0.5,
        primaryColor: const Color(0xFF8E4A49),
        secondaryColor: const Color(0xFFDC2626),
        intensity: 1.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(200, 200));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('shouldRepaint poprawnie reaguje na zmianę stanu animacji i kolorów', () {
      final p1 = WattBombAuraPainter(
        pulseProgress: 0.1,
        primaryColor: const Color(0xFF8E4A49),
        secondaryColor: const Color(0xFFDC2626),
      );
      final p2 = WattBombAuraPainter(
        pulseProgress: 0.2,
        primaryColor: const Color(0xFF8E4A49),
        secondaryColor: const Color(0xFFDC2626),
      );
      final p3 = WattBombAuraPainter(
        pulseProgress: 0.1,
        primaryColor: const Color(0xFFD4AF37),
        secondaryColor: const Color(0xFFFFE066),
      );

      expect(p1.shouldRepaint(p2), isTrue);
      expect(p1.shouldRepaint(p3), isTrue);
      expect(p1.shouldRepaint(p1), isFalse);
    });
  });

  group('AnimatedWattBombEffect - Widget UI testy', () {
    testWidgets('Gdy moc kolarza jest niska, efekt nie jest aktywny', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedWattBombEffect(
              currentWatts: 350.0,
              currentWkg: 5.0,
              child: Text('Licznik Mocy: 350W'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Licznik Mocy: 350W'), findsOneWidget);
      expect(find.text('WATT BOMB!'), findsNothing);
      expect(find.text('ATTACK SURGE!'), findsNothing);
      expect(find.byType(WattBombSurgeBadge), findsNothing);
    });

    testWidgets('Atak w sprincie >1400 W aktywuje WATT BOMB i odznakę', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedWattBombEffect(
              currentWatts: 1450.0,
              currentWkg: 9.8,
              riderName: 'Tadej Pogačar',
              colorTheme: WattBombColorTheme.gold,
              child: SizedBox(
                width: 100,
                height: 100,
                child: Text('Licznik Mocy'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('WATT BOMB!'), findsOneWidget);
      expect(find.textContaining('Tadej Pogačar'), findsOneWidget);
      expect(find.textContaining('1450 W'), findsOneWidget);
      expect(find.byType(WattBombSurgeBadge), findsOneWidget);
    });

    testWidgets('Atak na podjeździe >12.0 W/kg w górach aktywuje ATTACK SURGE w czerwieni', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedWattBombEffect(
              currentWatts: 820.0,
              currentWkg: 12.6,
              isMountain: true,
              riderName: 'Jonas Vingegaard',
              colorTheme: WattBombColorTheme.crimson,
              child: SizedBox(
                width: 120,
                height: 120,
                child: Text('Licznik Mocy Góry'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('ATTACK SURGE!'), findsOneWidget);
      expect(find.textContaining('Jonas Vingegaard'), findsOneWidget);
      expect(find.textContaining('12.6 W/kg'), findsOneWidget);
    });

    testWidgets('isTriggered wymusza aktywację efektu niezależnie od watów', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedWattBombEffect(
              currentWatts: 250.0,
              currentWkg: 3.5,
              isTriggered: true,
              riderName: 'Kolarz Gracza',
              isPlayerRider: true,
              child: Text('Spokojna jazda'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(WattBombSurgeBadge), findsOneWidget);
    });

    testWidgets('Wyłączenie efektu przy spadku mocy usuwa baner z ekranu', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedWattBombEffect(
              currentWatts: 1450.0,
              currentWkg: 10.0,
              child: Text('Miernik Mocy'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('WATT BOMB!'), findsOneWidget);

      // Aktualizacja widgetu ze spadkiem mocy do 400 W
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedWattBombEffect(
              currentWatts: 400.0,
              currentWkg: 5.5,
              child: Text('Miernik Mocy'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('WATT BOMB!'), findsNothing);
    });

    testWidgets('WattBombCameraShake trzęsie widokiem gdy isActive jest true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WattBombCameraShake(
              isActive: true,
              intensity: 8.0,
              child: Text('Kamera Wyścigu'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Kamera Wyścigu'), findsOneWidget);
      expect(find.byType(Transform), findsWidgets);
    });
  });
}
