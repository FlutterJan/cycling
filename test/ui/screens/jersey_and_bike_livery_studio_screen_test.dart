// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/screens/jersey_and_bike_livery_studio_screen.dart';
import 'package:pro_peloton_manager/ui/widgets/custom_jersey_painter.dart';

void main() {
  Widget createTestWidget({
    TeamLiveryConfiguration? initialConfig,
    VoidCallback? onBack,
    void Function(TeamLiveryConfiguration config)? onLiverySaved,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: JerseyAndBikeLiveryStudioScreen(
          initialConfig: initialConfig,
          onBack: onBack,
          onLiverySaved: onLiverySaved,
        ),
      ),
    );
  }

  group('Model TeamLiveryConfiguration & Enums', () {
    test('ChampionBandsType toJson and fromJson roundtrip', () {
      for (final band in ChampionBandsType.values) {
        final json = band.toJson();
        expect(ChampionBandsType.fromJson(json), equals(band));
      }
      expect(ChampionBandsType.fromJson('unknown_band'), equals(ChampionBandsType.none));
    });

    test('BikePaintFinishType attributes are properly defined', () {
      expect(BikePaintFinishType.matteRawCarbon.title, contains('Matowy'));
      expect(BikePaintFinishType.metallicSilver.title, contains('Chrom Metalik'));
      expect(BikePaintFinishType.chameleonPrism.title, contains('Kameleon'));
      expect(BikePaintFinishType.raceLeaderGold.title, contains('Złoto Lidera'));
      expect(BikePaintFinishType.fromJson('matteRawCarbon'), equals(BikePaintFinishType.matteRawCarbon));
      expect(BikePaintFinishType.fromJson('unknown'), equals(BikePaintFinishType.glossySolid));
    });

    test('TeamLiveryConfiguration toJson and fromJson roundtrip', () {
      const original = TeamLiveryConfiguration(
        primaryColorHex: '#123456',
        secondaryColorHex: '#654321',
        accentColorHex: '#ABCDEF',
        bibShortsColorHex: '#000000',
        bibShortsGripperColorHex: '#FFFFFF',
        jerseyPattern: JerseyPattern.chevron,
        championBands: ChampionBandsType.worldChampionRainbow,
        sponsorMainText: 'TEST SPONSOR',
        sponsorSecondaryText: 'SUB SPONSOR',
        bikeFinish: BikePaintFinishType.chameleonPrism,
        bikePrimaryColorHex: '#223344',
        bikeAccentColorHex: '#556677',
        bikeDecalColorHex: '#889900',
        barTapeColorHex: '#112233',
        isTanWallTires: true,
        bikeBrandName: 'SUPERBIKE',
      );

      final json = original.toJson();
      final restored = TeamLiveryConfiguration.fromJson(json);

      expect(restored.primaryColorHex, equals(original.primaryColorHex));
      expect(restored.secondaryColorHex, equals(original.secondaryColorHex));
      expect(restored.accentColorHex, equals(original.accentColorHex));
      expect(restored.bibShortsColorHex, equals(original.bibShortsColorHex));
      expect(restored.bibShortsGripperColorHex, equals(original.bibShortsGripperColorHex));
      expect(restored.jerseyPattern, equals(JerseyPattern.chevron));
      expect(restored.championBands, equals(ChampionBandsType.worldChampionRainbow));
      expect(restored.sponsorMainText, equals('TEST SPONSOR'));
      expect(restored.bikeFinish, equals(BikePaintFinishType.chameleonPrism));
      expect(restored.isTanWallTires, isTrue);
      expect(restored.bikeBrandName, equals('SUPERBIKE'));
    });

    test('TeamLiveryConfiguration copyWith works correctly', () {
      const base = TeamLiveryConfiguration();
      final modified = base.copyWith(
        primaryColorHex: '#FF0000',
        championBands: ChampionBandsType.poland,
        bikeFinish: BikePaintFinishType.raceLeaderGold,
      );

      expect(modified.primaryColorHex, equals('#FF0000'));
      expect(modified.championBands, equals(ChampionBandsType.poland));
      expect(modified.bikeFinish, equals(BikePaintFinishType.raceLeaderGold));
      expect(modified.secondaryColorHex, equals(base.secondaryColorHex));
    });
  });

  group('JerseyAndBikeLiveryStudioScreen - UI & Interakcje', () {
    testWidgets('Poprawnie renderuje ekran studia, zakładki i przyciski akcji', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tytuł i przycisk zapisu
      expect(find.text('Studio Wizerunku Drużyny'), findsOneWidget);
      expect(find.text('Zapisz Styl'), findsOneWidget);

      // Zakładki
      expect(find.text('Strój & Spodenki'), findsOneWidget);
      expect(find.text('Lakierowanie Ramy'), findsOneWidget);
      expect(find.text('Presety Pro Pelotonu'), findsOneWidget);

      // Przełącznik przód / tył koszulki
      expect(find.text('Widok z Przodu'), findsOneWidget);
      expect(find.text('Widok z Tyłu'), findsOneWidget);
    });

    testWidgets('Przełączanie widoku koszulki przód / tył', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final backButton = find.text('Widok z Tyłu');
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Przełącznik z powrotem na przód
      final frontButton = find.text('Widok z Przodu');
      await tester.tap(frontButton);
      await tester.pumpAndSettle();
      expect(frontButton, findsOneWidget);
    });

    testWidgets('Zmiana wzoru koszulki', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Znalezienie chipa wzoru Pasy pionowe
      final stripesChip = find.text('Pasy pionowe');
      expect(stripesChip, findsOneWidget);
      await tester.tap(stripesChip);
      await tester.pumpAndSettle();
    });

    testWidgets('Wybór pasków mistrza świata UCI na rękawkach', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Otwórz DropdownButton z paskami mistrzowskimi
      final dropdown = find.byType(DropdownButton<ChampionBandsType>);
      expect(dropdown, findsOneWidget);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Wybierz Tęcza Mistrza Świata UCI
      final rainbowOption = find.text('Tęcza Mistrza Świata UCI (Rainbow Bands)').last;
      await tester.tap(rainbowOption);
      await tester.pumpAndSettle();
    });

    testWidgets('Przejście do zakładki lakierowania ramy i wybór wykończenia Kameleon Prism', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Kliknięcie zakładki ramy
      await tester.tap(find.text('Lakierowanie Ramy'));
      await tester.pumpAndSettle();

      // Sprawdzenie obecności wykończeń lakierniczych
      expect(find.textContaining('Pryzmatyczny Kameleon'), findsOneWidget);
      expect(find.textContaining('Złoto Lidera Wyścigu'), findsOneWidget);

      // Kliknięcie w Kameleon
      await tester.tap(find.textContaining('Pryzmatyczny Kameleon'));
      await tester.pumpAndSettle();

      // Przewiń listę kontrolek lakierowania
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Przełączenie ścianek Tan-Wall
      final tanWallSwitch = find.byType(SwitchListTile);
      expect(tanWallSwitch, findsOneWidget);
      await tester.tap(tanWallSwitch);
      await tester.pumpAndSettle();
    });

    testWidgets('Wczytanie szablonu WorldTour (np. Team Visma | Lease a Bike)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Kliknięcie zakładki szablonów
      await tester.tap(find.text('Presety Pro Pelotonu'));
      await tester.pumpAndSettle();

      // Sprawdzenie listy szablonów
      expect(find.text('Team Visma | Lease a Bike Style'), findsOneWidget);
      expect(find.text('UAE Team Emirates Style'), findsOneWidget);
      expect(find.text('EF Education - EasyPost Style'), findsOneWidget);

      // Zastosowanie szablonu Visma
      final vismaTile = find.text('Team Visma | Lease a Bike Style');
      await tester.tap(vismaTile);
      await tester.pumpAndSettle();

      // SnackBar z informacją
      expect(find.text('Zastosowano paletę stylu: Team Visma | Lease a Bike Style'), findsOneWidget);
    });

    testWidgets('Zapisanie wizerunku wywołuje onLiverySaved i pokazuje dialog sukcesu', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      TeamLiveryConfiguration? savedResult;

      await tester.pumpWidget(createTestWidget(
        onLiverySaved: (cfg) {
          savedResult = cfg;
        },
      ));
      await tester.pumpAndSettle();

      // Kliknięcie w przycisk zapisu
      final saveButton = find.widgetWithText(ElevatedButton, 'Zapisz Styl');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Sprawdzenie dialogu sukcesu
      expect(find.text('Wizerunek Zespołu Zapisany!'), findsOneWidget);
      expect(savedResult, isNotNull);

      // Zamknięcie dialogu
      await tester.tap(find.text('Gotowe'));
      await tester.pumpAndSettle();
    });

    testWidgets('Kliknięcie przycisku wstecz wywołuje onBack', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      var backCalled = false;

      await tester.pumpWidget(createTestWidget(
        onBack: () => backCalled = true,
      ));
      await tester.pumpAndSettle();

      final backIcon = find.byIcon(Icons.arrow_back);
      expect(backIcon, findsOneWidget);
      await tester.tap(backIcon);
      await tester.pumpAndSettle();

      expect(backCalled, isTrue);
    });
  });
}
