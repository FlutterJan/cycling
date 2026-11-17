import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/router/app_router.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/state/career_controller.dart';
import 'package:pro_peloton_manager/ui/screens/be_a_pro_character_creator_screen.dart';
import 'package:pro_peloton_manager/ui/screens/be_a_pro_dashboard_and_apartment_screen.dart';
import 'package:pro_peloton_manager/ui/screens/cyclocross_winter_series_screen.dart';
import 'package:pro_peloton_manager/ui/screens/legends_card_album_and_packs_screen.dart';
import 'package:pro_peloton_manager/ui/screens/race_replay_director_theater_screen.dart';
import 'package:pro_peloton_manager/ui/screens/uci_hour_record_attempt_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer testContainer;

  setUpAll(() async {
    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });

    testContainer = ProviderContainer();
    await testContainer.read(careerProvider.notifier).startNewCareer(
          saveName: 'Test Router Package 4',
          playerManagerName: 'Dyrektor Sportowy',
          playerTeamId: 'wt_aethel_veloce',
        );
  });

  tearDownAll(() {
    testContainer.dispose();
  });

  Future<void> pumpRoute(
    WidgetTester tester, {
    required String initialLocation,
  }) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final router = createAppRouter(initialLocation: initialLocation);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: testContainer,
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('Zadanie #361 — Stałe tras i nazw w AppRouter', () {
    test('Nowe stałe ścieżek i nazw są poprawne oraz unikalne', () {
      expect(AppRoutes.beAProCreator, equals('/be-a-pro/creator'));
      expect(AppRoutes.beAProDashboard, equals('/be-a-pro/dashboard'));
      expect(AppRoutes.cyclocross, equals('/career/cyclocross'));
      expect(AppRoutes.velodromeHourRecord, equals('/velodrome/hour-record'));
      expect(AppRoutes.replayTheater, equals('/race/replay-theater'));
      expect(AppRoutes.legendsAlbum, equals('/career/legends-album'));

      final newNames = {
        AppRouteNames.beAProCreator,
        AppRouteNames.beAProDashboard,
        AppRouteNames.cyclocross,
        AppRouteNames.velodromeHourRecord,
        AppRouteNames.replayTheater,
        AppRouteNames.legendsAlbum,
      };
      expect(newNames.length, equals(6));
    });
  });

  group('Zadanie #361 — Rozwiązywanie nowych tras GoRouter', () {
    testWidgets('Trasa "/be-a-pro/creator" renderuje BeAProCharacterCreatorScreen',
        (tester) async {
      await pumpRoute(tester, initialLocation: AppRoutes.beAProCreator);
      expect(find.byType(BeAProCharacterCreatorScreen), findsOneWidget);
    });

    testWidgets(
        'Trasa "/be-a-pro/dashboard" renderuje BeAProDashboardAndApartmentScreen',
        (tester) async {
      await pumpRoute(tester, initialLocation: AppRoutes.beAProDashboard);
      expect(find.byType(BeAProDashboardAndApartmentScreen), findsOneWidget);
    });

    testWidgets(
        'Trasa "/career/cyclocross" renderuje CyclocrossWinterSeriesScreen',
        (tester) async {
      await pumpRoute(tester, initialLocation: AppRoutes.cyclocross);
      expect(find.byType(CyclocrossWinterSeriesScreen), findsOneWidget);
    });

    testWidgets(
        'Trasa "/velodrome/hour-record" renderuje UciHourRecordAttemptScreen',
        (tester) async {
      await pumpRoute(tester, initialLocation: AppRoutes.velodromeHourRecord);
      expect(find.byType(UciHourRecordAttemptScreen), findsOneWidget);
    });

    testWidgets(
        'Trasa "/race/replay-theater" renderuje RaceReplayDirectorTheaterScreen',
        (tester) async {
      await pumpRoute(tester, initialLocation: AppRoutes.replayTheater);
      expect(find.byType(RaceReplayDirectorTheaterScreen), findsOneWidget);
    });

    testWidgets(
        'Trasa "/career/legends-album" renderuje LegendsCardAlbumAndPacksScreen',
        (tester) async {
      await pumpRoute(tester, initialLocation: AppRoutes.legendsAlbum);
      expect(find.byType(LegendsCardAlbumAndPacksScreen), findsOneWidget);
    });
  });

  group('Zadanie #361 — Rozszerzenia nawigacji BuildContext', () {
    testWidgets('Rozszerzenia goTo* nawigują do wszystkich 6 nowych ekranów',
        (tester) async {
      await pumpRoute(tester, initialLocation: AppRoutes.beAProCreator);
      expect(find.byType(BeAProCharacterCreatorScreen), findsOneWidget);

      tester.element(find.byType(BeAProCharacterCreatorScreen)).goToBeAProDashboard();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BeAProDashboardAndApartmentScreen), findsOneWidget);

      tester.element(find.byType(BeAProDashboardAndApartmentScreen)).goToCyclocross();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CyclocrossWinterSeriesScreen), findsOneWidget);

      tester.element(find.byType(CyclocrossWinterSeriesScreen)).goToLegendsAlbum();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LegendsCardAlbumAndPacksScreen), findsOneWidget);

      tester.element(find.byType(LegendsCardAlbumAndPacksScreen)).goToVelodromeHourRecord();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(UciHourRecordAttemptScreen), findsOneWidget);

      tester.element(find.byType(UciHourRecordAttemptScreen)).goToReplayTheater();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(RaceReplayDirectorTheaterScreen), findsOneWidget);
    });
  });
}
