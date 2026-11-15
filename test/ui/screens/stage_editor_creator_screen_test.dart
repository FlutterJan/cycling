// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/ui/screens/stage_editor_creator_screen.dart';

void main() {
  Widget createTestWidget({
    VoidCallback? onBack,
    void Function(TourRace race)? onRaceSaved,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: StageEditorCreatorScreen(
          onBack: onBack,
          onRaceSaved: onRaceSaved,
        ),
      ),
    );
  }

  group('StageEditorCreatorScreen - Inicjalizacja i Presety', () {
    testWidgets('Poprawnie renderuje domyślny preset Wrocław - Sobótka (Ślęża)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Nagłówek i tytuł
      expect(find.text('Kreator Etapów i Wyścigów'), findsOneWidget);
      expect(find.text('Zapisz do Kalendarza'), findsOneWidget);

      // Pasek statystyk
      expect(find.text('Dystans'), findsOneWidget);
      expect(find.text('Przewyższenie'), findsOneWidget);
      expect(find.text('Premie KOM'), findsOneWidget);
      expect(find.text('Bruk'), findsOneWidget);

      // Zakładki
      expect(find.textContaining('Edycja Punktu'), findsOneWidget);
      expect(find.text('Lista Wszystkich Odcinków'), findsOneWidget);
      expect(find.text('Parametry Wyścigu & Pogoda'), findsOneWidget);
    });

    testWidgets('Załadowanie szablonu Tatry aktualizuje trasę na etap wysokogórski HC', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Kliknięcie w menu szablonów (ikona auto_awesome)
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();

      // Wybór szablonu Tatry
      final tatryOption = find.text('Królewski Etap w Tatrach (Zakopane - Morskie Oko)');
      expect(tatryOption, findsOneWidget);
      await tester.tap(tatryOption);
      await tester.pumpAndSettle();

      // Weryfikacja zmiany szczytu n.p.m. na 1850m
      expect(find.text('1850 m'), findsOneWidget);
    });

    testWidgets('Załadowanie szablonu Paris-Roubaix aktywuje sektory bruku 1-5★', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();

      final roubaixOption = find.text('Piekło Północy (Paris-Roubaix Bruk 1-5★)');
      expect(roubaixOption, findsOneWidget);
      await tester.tap(roubaixOption);
      await tester.pumpAndSettle();

      // Przejście do zakładki listy odcinków
      await tester.tap(find.text('Lista Wszystkich Odcinków'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Arenberg'), findsOneWidget);
    });
  });

  group('StageEditorCreatorScreen - Edycja Punktów Profilu', () {
    testWidgets('Przełączanie punktów i edycja nawierzchni na szuter Strade Bianche', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Wybór nawierzchni "Szuter Toskański (Strade)" w edytorze pierwszego punktu
      final gravelChip = find.text('Szuter Toskański (Strade)');
      expect(gravelChip, findsOneWidget);

      await tester.tap(gravelChip);
      await tester.pumpAndSettle();

      // W pasku statystyk pojawia się etykieta Szuter
      expect(find.text('Szuter'), findsOneWidget);
    });

    testWidgets('Dodanie nowego punktu wstawia węzeł do trasy', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Liczba początkowych punktów (11 w Sobótce)
      expect(find.textContaining('Punkt 1 z 11'), findsOneWidget);

      // Kliknięcie "Wstaw po tym"
      final addBtn = find.text('Wstaw po tym');
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Liczba punktów wzrasta do 12
      expect(find.textContaining('Punkt 2 z 12'), findsOneWidget);
    });
  });

  group('StageEditorCreatorScreen - Zapis do Kalendarza Kariery', () {
    testWidgets('Kliknięcie Zapisz do Kalendarza generuje obiekt TourRace i wywołuje callback', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      TourRace? savedRace;

      await tester.pumpWidget(createTestWidget(
        onRaceSaved: (race) {
          savedRace = race;
        },
      ));
      await tester.pumpAndSettle();

      // Kliknięcie przycisku Zapisz do Kalendarza
      final saveBtn = find.text('Zapisz do Kalendarza');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Weryfikacja wywołania callbacku z poprawnym obiektem TourRace
      expect(savedRace, isNotNull);
      expect(savedRace!.name, contains('Wrocław - Sobótka'));
      expect(savedRace!.stages.length, equals(1));
      expect(savedRace!.stages.first.segments.length, greaterThanOrEqualTo(10));
      expect(savedRace!.totalRaceDistanceKm, closeTo(174.0, 5.0));

      // Okno dialogowe potwierdzenia
      expect(find.text('Wyścig Zapisany do Kalendarza!'), findsOneWidget);
      expect(find.text('Powrót do Gry'), findsOneWidget);
      expect(find.text('Kopiuj JSON'), findsOneWidget);

      // Zamknięcie dialogu
      await tester.tap(find.text('Powrót do Gry'));
      await tester.pumpAndSettle();
      expect(find.text('Wyścig Zapisany do Kalendarza!'), findsNothing);
    });
  });

  group('StageEditorCreatorScreen - Serializacja StageEditorPoint', () {
    test('StageEditorPoint poprawnie serializuje się i deserializuje z JSON', () {
      const pt = StageEditorPoint(
        id: 'p_custom_1',
        distanceKm: 82.5,
        elevationMeters: 718.0,
        surfaceType: SegmentSurfaceType.cobblestonesSector4,
        classification: SegmentClassification.cat1,
        technicalDifficulty: 78.0,
        note: 'Szczyt Ślęży - Brukowa Ściana',
        roadBearingDegrees: 180.0,
        windDirectionDegrees: 220.0,
      );

      final json = pt.toJson();
      final reconstituted = StageEditorPoint.fromJson(json);

      expect(reconstituted.id, equals('p_custom_1'));
      expect(reconstituted.distanceKm, equals(82.5));
      expect(reconstituted.elevationMeters, equals(718.0));
      expect(reconstituted.surfaceType, equals(SegmentSurfaceType.cobblestonesSector4));
      expect(reconstituted.classification, equals(SegmentClassification.cat1));
      expect(reconstituted.note, equals('Szczyt Ślęży - Brukowa Ściana'));
    });
  });
}
