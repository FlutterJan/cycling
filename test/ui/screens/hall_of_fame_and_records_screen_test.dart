import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/services/career/historical_records_and_palmares_service.dart';
import 'package:pro_peloton_manager/ui/screens/hall_of_fame_and_records_screen.dart';

void main() {
  late CyclingTeam testTeam;
  late HistoricalRecordsAndPalmaresService testService;

  setUp(() {
    testTeam = const CyclingTeam(
      id: 'team_veloce',
      name: 'Veloce Pro Team',
      division: TeamDivision.worldTour,
      countryIso: 'POL',
      primaryJerseyColorHex: '#003399',
      secondaryJerseyColorHex: '#FFFFFF',
      accentJerseyColorHex: '#FFCC00',
      cashBalanceEur: 4500000,
      monthlyBurnRateEur: 400000,
      uciPointsSeason: 4800,
      rosterRiderIds: [],
      staff: TeamStaff(
        trainersLevel: 85,
        sportsDirectorsLevel: 85,
        doctorsLevel: 85,
        mechanicsLevel: 85,
        scoutsLevel: 85,
      ),
      bikeDeal: BikeManufacturerDeal(
        manufacturerId: 'cervelo',
        manufacturerName: 'Cervélo',
        prestigeLevel: 5,
        annualCashContributionEur: 2000000,
        freeBikesQuota: 80,
        researchAndDevelopmentLevel: 90,
        suppliedFrameIds: [],
        suppliedWheelsetIds: [],
        contractYearsLeft: 2,
        minimumUciRankingRequired: 10,
      ),
      sponsors: [],
      inventoryBikes: [],
    );

    testService = HistoricalRecordsAndPalmaresService();
  });

  Widget createTestWidget({int initialTab = 0}) {
    return MaterialApp(
      home: HallOfFameAndRecordsScreen(
        palmaresService: testService,
        playerTeam: testTeam,
        currentSeasonYear: 2026,
        initialTab: initialTab,
      ),
    );
  }

  testWidgets('renders HallOfFameAndRecordsScreen header and 4 tabs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Gablota Trofeów & Palmarès'), findsOneWidget);
    expect(find.text('Gablota Trofeów'), findsOneWidget);
    expect(find.text('Rekordy Podjazdów'), findsOneWidget);
    expect(find.text('Historia Sezonów'), findsOneWidget);
    expect(find.text('Ranking Wszech Czasów'), findsOneWidget);
  });

  testWidgets('displays visual trophy showcase in Tab 1 (Gablota Trofeów)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Visual trophy stands
    expect(find.text('ZŁOTA SALA SŁAWY (TROPHY ROOM)'), findsOneWidget);
    expect(find.text('Bruk z Roubaix'), findsOneWidget);
    expect(find.text('Puchar z Paryża'), findsOneWidget);
    expect(find.text('Trofeo Senza Fine'), findsOneWidget);
    expect(find.text('Tęczowa Koszulka'), findsOneWidget);

    // Filter chips
    expect(find.text('Wszystkie Trofea'), findsOneWidget);
    expect(find.text('Grand Tour (Generalki)'), findsOneWidget);
    expect(find.text('Monumenty Kolarstwa'), findsOneWidget);
  });

  testWidgets('navigates to Tab 2 and displays KOM Climb Records table with VAM and W/kg', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget(initialTab: 1));
    await tester.pumpAndSettle();

    // Table headers
    expect(find.text('PODJAZD / GÓRA'), findsOneWidget);
    expect(find.text('POSIADACZ KOM'), findsOneWidget);
    expect(find.text('CZAS (KOM)'), findsOneWidget);
    expect(find.text('VAM & MOC'), findsOneWidget);

    // Climbs presence
    expect(find.text('Alpe d\'Huez (21 Virages)'), findsOneWidget);
    expect(find.text('Marco Pantani'), findsWidgets);
    expect(find.text('36:50'), findsOneWidget);
    expect(find.textContaining('1821 VAM'), findsOneWidget);

    expect(find.textContaining('Mont Ventoux'), findsOneWidget);
    expect(find.text('Iban Mayo'), findsOneWidget);
    expect(find.text('55:51'), findsOneWidget);
  });

  testWidgets('clicking on a climb row opens bottom sheet with attempts leaderboard', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    // Dodajemy próbę do Alpe d'Huez
    testService.recordClimbAttempt(
      climbId: 'climb_alpe_dhuez',
      riderId: 'rider_ace',
      riderName: 'Mateusz Alpejski',
      teamName: 'Veloce Pro Team',
      timeSeconds: 2180,
      seasonYear: 2026,
      raceName: 'Tour de France 2026',
    );

    await tester.pumpWidget(createTestWidget(initialTab: 1));
    await tester.pumpAndSettle();

    // Klikamy na wiersz Alpe d'Huez
    final alpeRow = find.text('Alpe d\'Huez (21 Virages)');
    expect(alpeRow, findsOneWidget);
    await tester.tap(alpeRow);
    await tester.pumpAndSettle();

    // Modal się otwiera
    expect(find.textContaining('Alpy Francuskie'), findsOneWidget);
    expect(find.text('Mateusz Alpejski'), findsWidgets);
    expect(find.text('36:20'), findsWidgets);
  });

  testWidgets('displays race archive season-by-season in Tab 3 (Historia Sezonów)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget(initialTab: 2));
    await tester.pumpAndSettle();

    expect(find.text('ARCHIWUM ROZGRYWEK'), findsOneWidget);
    expect(find.text('Sezon 2026'), findsOneWidget);
  });

  testWidgets('displays All-Time GOAT Hall of Fame leaderboard in Tab 4', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget(initialTab: 3));
    await tester.pumpAndSettle();

    expect(find.textContaining('PANTEON WSZECH CZASÓW'), findsOneWidget);
    expect(find.text('Eddy Merckx'), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('Bernard Hinault'), findsOneWidget);
    expect(find.text('Tadej Pogačar'), findsOneWidget);
    expect(find.textContaining('GOAT SCORE'), findsWidgets);
  });
}
