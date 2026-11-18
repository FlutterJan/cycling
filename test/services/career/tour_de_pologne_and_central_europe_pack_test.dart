import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/services/career/tour_de_pologne_and_central_europe_pack.dart';

void main() {
  group('TourDePologneAndCentralEuropePack', () {
    test('builds 7-stage Tour de Pologne with Karpacz Orlinek, Gliczarów and Kraków', () {
      final tdp = TourDePologneAndCentralEuropePack.buildTourDePologne(
        seasonYear: 2026,
        participatingTeamIds: const ['team_a', 'team_b'],
      );

      expect(tdp.countryIso, 'POL');
      expect(tdp.uciCategory, RaceCategory.worldTourStageRace);
      expect(tdp.ridersPerTeam, 7);
      expect(tdp.stages.length, 7);

      expect(tdp.stages[0].name, contains('Karpacz Orlinek'));
      expect(tdp.stages[0].stageType, StageType.summitFinish);
      expect(tdp.stages[1].name, contains('Karpacz Orlinek ITT'));
      expect(tdp.stages[1].stageType, StageType.individualTimeTrial);
      expect(tdp.stages[5].name, contains('Gliczarów'));
      expect(tdp.stages[5].stageType, StageType.summitFinish);
      expect(tdp.stages[6].name, contains('Kraków'));
      expect(tdp.stages[6].stageType, StageType.flat);

      for (final stage in tdp.stages) {
        expect(stage.segments, isNotEmpty);
        double expectedKm = 0.0;
        for (int i = 0; i < stage.segments.length; i++) {
          final seg = stage.segments[i];
          expect(seg.index, i);
          expect(seg.startKm, closeTo(expectedKm, 0.001));
          expectedKm += seg.lengthKm;
          if (i > 0) {
            expect(
              seg.startElevationM,
              closeTo(stage.segments[i - 1].endElevationM, 0.001),
            );
          }
        }
      }
    });

    test('builds complete Central Europe pack with 5 races and supports filtering', () {
      final races = TourDePologneAndCentralEuropePack.buildPack(
        seasonYear: 2026,
        participatingTeamIds: const ['team_player', 'team_rival'],
      );

      expect(races.length, 5);
      expect(
        races.map((r) => r.countryIso).toSet(),
        containsAll(['POL', 'HUN', 'CZE', 'SVK']),
      );

      final polSpecs = TourDePologneAndCentralEuropePack.filterSpecs(
        countryFilter: CentralEuropeCountry.poland,
      );
      expect(polSpecs.length, 2);

      final gliczarowSpecs = TourDePologneAndCentralEuropePack.filterSpecs(
        query: 'Gliczarów',
      );
      expect(gliczarowSpecs.length, 1);
      expect(gliczarowSpecs.first.raceId, CentralEuropeRaceId.tourDePologne);
    });

    test('CentralEuropeLandmark supports JSON serialization round-trip', () {
      const original = CentralEuropeLandmark(
        id: 'lm_test',
        name: 'Gliczarów',
        country: CentralEuropeCountry.poland,
        elevationM: 985,
        lengthKm: 5.5,
        avgGradientPercent: 8.6,
        maxGradientPercent: 22.0,
        tacticalNote: 'Test note',
      );
      final restored = CentralEuropeLandmark.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.country, original.country);
      expect(restored.elevationM, original.elevationM);
      expect(restored.maxGradientPercent, original.maxGradientPercent);
    });

    test('CentralEuropePackNotifier updates selected race, stage and career toggle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(centralEuropePackProvider.notifier);
      expect(
        container.read(centralEuropePackProvider).selectedRaceId,
        CentralEuropeRaceId.tourDePologne,
      );

      notifier.selectStage(5);
      expect(container.read(centralEuropePackProvider).selectedStageIndex, 5);

      notifier.selectRace(CentralEuropeRaceId.czechTour);
      final updated = container.read(centralEuropePackProvider);
      expect(updated.selectedRaceId, CentralEuropeRaceId.czechTour);
      expect(updated.selectedStageIndex, 0);

      notifier.togglePackInCareer();
      expect(container.read(centralEuropePackProvider).packEnabledInCareer, isFalse);
    });
  });

  group('TourDePologneAndCentralEuropePackPanel responsive UI', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TourDePologneAndCentralEuropePackPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844 mobile without overflow', (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.text('Tour de Pologne & Central Europe Pack'), findsOneWidget);
      expect(find.text('Etap 6'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1024x768 tablet and switches stage', (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('Tour de Pologne UCI WorldTour'), findsWidgets);

      await tester.ensureVisible(find.text('Etap 6'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Etap 6'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Gliczarów'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1600x900 desktop and filters by country', (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(find.text('Czech Tour'), findsOneWidget);

      await tester.tap(find.text('CZ • Czechy'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Czech Tour'), findsOneWidget);
      expect(find.text('Tour de Hongrie'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
