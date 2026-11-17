import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/rendering3d/camera_rig_controller.dart';
import 'package:pro_peloton_manager/models/organizer/race_organizer_empire_model.dart';
import 'package:pro_peloton_manager/ui/screens/race_organizer_hq_dashboard_screen.dart';

void main() {
  group('RaceOrganizerHqNotifier unit tests', () {
    test('awards and rejects host city bids and updates empire ledger', () {
      final notifier = RaceOrganizerHqNotifier();
      final initialCash = notifier.state.empire.budgetLedger.liquidCashEur;

      notifier.setContractLengthYears(2);
      notifier.awardSelectedBid();

      expect(notifier.state.isLastActionSuccess, isTrue);
      expect(
        notifier.state.empire.budgetLedger.liquidCashEur,
        greaterThan(initialCash),
      );

      notifier.selectBid('bid_grenoble_s1');
      notifier.rejectSelectedBid();
      final grenoble = notifier.state.empire.pendingHostCityBids
          .firstWhere((b) => b.bidId == 'bid_grenoble_s1');
      expect(grenoble.status, HostBidStatus.rejected);
    });

    test('signs TV package, switches camera, and advances season', () {
      final notifier = RaceOrganizerHqNotifier();
      final startYear = notifier.state.empire.seasonYear;

      notifier.setCameraMode(RaceCameraMode.motoTvCam);
      expect(notifier.state.cameraMode, RaceCameraMode.motoTvCam);

      notifier.signNewTvPackage(
        tier: TvBroadcastTier.panContinentalSports,
        territory: TvRightsTerritory.europeCore,
      );
      expect(notifier.state.isLastActionSuccess, isTrue);

      notifier.advanceSeason();
      expect(notifier.state.empire.seasonYear, startYear + 1);
    });

    test('read-only mode blocks mutating actions', () {
      final notifier = RaceOrganizerHqNotifier(isReadOnly: true);
      final initialCash = notifier.state.empire.budgetLedger.liquidCashEur;
      final initialYear = notifier.state.empire.seasonYear;

      notifier.awardSelectedBid();
      notifier.advanceSeason();

      expect(notifier.state.empire.budgetLedger.liquidCashEur, initialCash);
      expect(notifier.state.empire.seasonYear, initialYear);
    });
  });

  group('RaceOrganizerHqDashboardScreen responsive widget tests', () {
    Future<void> pumpAtSize(
      WidgetTester tester,
      Size size, {
      bool isReadOnly = false,
      RaceOrganizerEmpireModel? empire,
    }) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: RaceOrganizerHqDashboardScreen(
              initialEmpire: empire,
              isReadOnly: isReadOnly,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final entry in <String, Size>{
      'mobile 390x844': const Size(390, 844),
      'tablet 1024x768': const Size(1024, 768),
      'desktop 1600x900': const Size(1600, 900),
    }.entries) {
      testWidgets('renders without overflow at ${entry.key}', (tester) async {
        await pumpAtSize(tester, entry.value);

        expect(find.textContaining('Amaury Cycling Syndicate'), findsOneWidget);
        expect(find.text('Transmisja 3D Własnego Wyścigu'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.text('Mapa Przetargów'));
        await tester.tap(find.text('Mapa Przetargów'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Mapa Przetargów Miast Gospodarzy'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.text('Prawa TV & Budżet'));
        await tester.tap(find.text('Prawa TV & Budżet'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Księga Przepływów Organizatora'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('supports broadcast pause/resume, bid award, and read-only',
        (tester) async {
      await pumpAtSize(tester, const Size(1600, 900));

      await tester.tap(find.text('Wstrzymaj'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Wznów 3D'), findsOneWidget);

      await tester.tap(find.text('Mapa Przetargów'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Przyznaj Przetarg'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.textContaining('Przyznano przetarg miastu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles empty empire gracefully', (tester) async {
      const emptyEmpire = RaceOrganizerEmpireModel(
        organizerId: 'org_empty',
        syndicateName: 'Empty Syndicate',
        archetype: OrganizerSyndicateArchetype.independentProSeries,
        headquartersCountryCode: 'PL',
        seasonYear: 2026,
        uciBoardInfluence: 20.0,
        budgetLedger: OrganizerBudgetLedger(
          liquidCashEur: 500000,
          reserveFundEur: 100000,
          annualOperatingOverheadEur: 150000,
          prizePoolCommitmentEur: 0,
          appearanceFeesAllocatedEur: 0,
          safetyInfrastructureBudgetEur: 0,
        ),
      );
      await pumpAtSize(tester, const Size(1024, 768), empire: emptyEmpire);
      expect(
        find.text('Brak wyścigów w portfolio organizatora.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
