import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/database/save_service.dart';
import 'package:pro_peloton_manager/services/generators/world_teams_generator.dart';
import 'package:pro_peloton_manager/ui/widgets/global_search_spotlight_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CareerSave careerSave;

  setUpAll(() async {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });

    final world = WorldTeamsGenerator.generateWorldTourSystem(seed: 42);
    careerSave = await SaveService.createNewCareer(
      saveName: 'Spotlight Test Career',
      playerManagerName: 'Dyrektor Sportowy',
      playerTeamId: world.teams.first.id,
      difficulty: CareerDifficulty.normal,
      seasonYear: 2026,
    );
  });

  group('SpotlightSearchIndex', () {
    test('indeksuje wszystkich kolarzy, drużyny, wyścigi i podjazdy', () {
      final index = SpotlightSearchIndex.fromCareerSave(careerSave);

      expect(careerSave.riders.length, greaterThanOrEqualTo(500));
      expect(careerSave.teams.length, greaterThanOrEqualTo(18));
      expect(careerSave.calendar.races.isNotEmpty, isTrue);

      final counts = index.countByCategory('');
      expect(counts[SpotlightSearchCategory.rider], equals(careerSave.riders.length));
      expect(counts[SpotlightSearchCategory.team], equals(careerSave.teams.length));
      expect(
        counts[SpotlightSearchCategory.race],
        equals(careerSave.calendar.races.length),
      );
      expect(counts[SpotlightSearchCategory.climb], greaterThan(10));
    });

    test('wyszukuje natychmiastowo z normalizacją polskich znaków i kategorii', () {
      final index = SpotlightSearchIndex.fromCareerSave(careerSave);
      final targetRider = careerSave.riders.first;
      final targetTeam = careerSave.teams.first;

      final riderHits = index.search(
        query: targetRider.lastName,
        category: SpotlightSearchCategory.rider,
      );
      expect(riderHits.any((e) => e.rider?.id == targetRider.id), isTrue);

      final teamHits = index.search(
        query: targetTeam.name,
        category: SpotlightSearchCategory.team,
      );
      expect(teamHits.any((e) => e.team?.id == targetTeam.id), isTrue);

      final climbHits = index.search(
        query: 'galibier',
        category: SpotlightSearchCategory.climb,
      );
      expect(climbHits.any((e) => e.title.contains('Galibier')), isTrue);
    });
  });

  group('GlobalSearchSpotlightModal Widget & Responsiveness', () {
    Future<void> pumpModalAtSize(
      WidgetTester tester,
      Size size, {
      ValueChanged<Rider>? onRider,
      ValueChanged<CyclingTeam>? onTeam,
      ValueChanged<TourRace>? onRace,
    }) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlobalSearchSpotlightModal(
              careerSave: careerSave,
              onNavigateToRider: onRider,
              onNavigateToTeam: onTeam,
              onNavigateToRace: onRace,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renderuje się poprawnie bez przepełnień na 390x844 (mobile)', (
      tester,
    ) async {
      await pumpModalAtSize(tester, const Size(390, 844));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Wszystko'), findsOneWidget);
      expect(find.text('Kolarze'), findsOneWidget);
    });

    testWidgets('renderuje się poprawnie bez przepełnień na 1024x768 (tablet)', (
      tester,
    ) async {
      await pumpModalAtSize(tester, const Size(1024, 768));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Podjazdy'), findsOneWidget);
    });

    testWidgets('renderuje się poprawnie bez przepełnień na 1600x900 (desktop)', (
      tester,
    ) async {
      await pumpModalAtSize(tester, const Size(1600, 900));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('Indeks:'), findsOneWidget);
    });

    testWidgets('filtruje wyniki, otwiera profil kolarza i profil drużyny', (
      tester,
    ) async {
      Rider? selectedRider;
      final targetRider = careerSave.riders.first;

      await pumpModalAtSize(
        tester,
        const Size(1280, 800),
        onRider: (r) => selectedRider = r,
      );

      await tester.enterText(find.byType(TextField), targetRider.fullName);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Otwórz Profil Kolarza'));
      await tester.pumpAndSettle();

      expect(selectedRider?.id, equals(targetRider.id));
    });

    testWidgets('otwiera wbudowany profil drużyny z listą kolarzy', (
      tester,
    ) async {
      final targetTeam = careerSave.teams.first;

      await pumpModalAtSize(tester, const Size(1280, 800));

      await tester.tap(find.text('Drużyny'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), targetTeam.name);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Otwórz Profil Drużyny'));
      await tester.pumpAndSettle();

      expect(find.text('Wróć'), findsOneWidget);
      expect(find.text(targetTeam.name), findsWidgets);
    });
  });
}
