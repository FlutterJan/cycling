import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/models/equipment/frame_model.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/models/team/sponsor_contract.dart';
import 'package:pro_peloton_manager/services/generators/fictional_brands_catalog.dart';
import 'package:pro_peloton_manager/services/generators/initial_game_seeder.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';
import 'package:pro_peloton_manager/state/career_state_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
  });

  group('InitialGameSeeder Tests', () {
    test('Generuje kompletny świat gry w czasie < 2 sekund (>800 kolarzy, 50+ drużyn, kalendarz, sprzęt)', () async {
      const config = InitialGameSeedConfig(
        saveName: 'Test Seeder Career',
        playerManagerName: 'Tomasz Majewski',
        playerTeamId: 'team_aethel_ineos',
        difficulty: CareerDifficulty.normal,
        seasonYear: 2026,
        seed: 42,
        saveToDisk: false,
      );

      final result = await InitialGameSeeder.seedNewGame(config);

      // 1. Weryfikacja wymogu wydajnościowego: wykonanie w mniej niż 2 sekundy (< 2000 ms)
      expect(result.durationMs, lessThan(2000));
      expect(result.isUnderTwoSeconds, isTrue);

      // 2. Weryfikacja liczby drużyn (ponad 50 drużyn: 18 WT + 15 Pro + 20 Conti = 53)
      expect(result.totalTeamsCount, greaterThanOrEqualTo(50));
      expect(result.totalTeamsCount, equals(53));
      expect(result.worldTourTeamsCount, equals(18));
      expect(result.proTeamsCount, equals(15));
      expect(result.continentalTeamsCount, equals(20));

      // 3. Weryfikacja liczby kolarzy (wymóg: ponad 800 kolarzy)
      expect(result.totalRidersCount, greaterThan(800));
      expect(result.totalRidersCount, greaterThanOrEqualTo(1000));
      expect(result.totalFreeAgentsCount, greaterThan(0));
      expect(result.totalScoutingTalentsCount, greaterThan(0));

      // 4. Weryfikacja sprzętu i flot rowerowych (FictionalBrandsCatalog)
      expect(result.totalBikesAssembled, greaterThan(150));
      for (final team in result.save.teams) {
        expect(team.inventoryBikes.isNotEmpty, isTrue, reason: 'Drużyna ${team.name} musi posiadać rowery');
        expect(team.bikeDeal.brandId.isNotEmpty, isTrue, reason: 'Drużyna ${team.name} musi mieć markę rowerów');
      }

      // 5. Weryfikacja kalendarza wyścigów UCI (UciCalendarGenerator)
      expect(result.totalRacesCount, greaterThan(25));
      expect(result.totalStagesCount, greaterThan(100));
      expect(result.save.calendar.races.isNotEmpty, isTrue);

      // 6. Weryfikacja zespołu gracza i budżetu
      expect(result.save.playerTeamId, equals('team_aethel_ineos'));
      expect(result.save.playerTeam.name.isNotEmpty, isTrue);
      expect(result.save.playerRoster.isNotEmpty, isTrue);
      expect(result.save.financeLedger.isNotEmpty, isTrue);

      // 7. Weryfikacja formatowania raportu
      expect(result.summaryReport, contains('INICJALIZACJA NOWEGO ŚWIATA GRY [SUKCES'));
      expect(result.summaryReport, contains('Drużyny łącznie: 53'));
      expect(result.summaryReport, contains('Kolarze łącznie:'));
    });

    test('Poprawnie integruje autorski zespół gracza (Custom Team) i flotę maszyn FictionalBrandsCatalog', () async {
      const customId = 'custom_tatry_racing';
      const brandId = 'brand_ventoux';

      final customDeal = FictionalBrandsCatalog.createManufacturerDeal(
        brandId: brandId,
        contractYearsLeft: 3,
      );

      final customBikes = [
        FictionalBrandsCatalog.assembleBike(
          brandId: brandId,
          frameCategory: FrameCategory.lightweightClimbing,
        ),
        FictionalBrandsCatalog.assembleBike(
          brandId: brandId,
          frameCategory: FrameCategory.aero,
        ),
      ];

      final customTeam = CyclingTeam(
        id: customId,
        name: 'Tatry Pro Cycling',
        division: TeamDivision.proTeam,
        countryIso: 'POL',
        primaryJerseyColorHex: '#E11D48',
        secondaryJerseyColorHex: '#FFFFFF',
        accentJerseyColorHex: '#1E293B',
        cashBalanceEur: 3500000,
        monthlyBurnRateEur: 180000,
        uciPointsSeason: 0,
        rosterRiderIds: const ['custom_r1', 'custom_r2'],
        staff: const TeamStaff(
          trainersLevel: 65,
          sportsDirectorsLevel: 70,
          doctorsLevel: 65,
          mechanicsLevel: 75,
          scoutsLevel: 60,
        ),
        bikeDeal: customDeal,
        sponsors: const [
          SponsorContract(
            id: 'sponsor_custom_title',
            companyName: 'Tatrzańskie Wody Termalne',
            industry: SponsorIndustry.energy,
            sponsorTier: SponsorTier.titlePrimary,
            annualBudgetEur: 2000000,
            contractDurationYears: 2,
            sponsorSatisfaction: 85.0,
            objectives: [
              SponsorObjective(
                id: 'obj_custom_1',
                description: 'Ukończ w Top 10 Monumentu',
                bonusPaymentEur: 150000,
                importance: ObjectiveImportance.critical,
                isCompleted: false,
                currentProgress: 0.0,
                targetProgress: 1.0,
              ),
            ],
          ),
        ],
        inventoryBikes: customBikes,
      );

      final customRiders = [
        RiderProceduralGenerator.generateRider(
          teamId: customId,
          role: RiderRole.teamLeader,
          age: 26,
        ).copyWith(id: 'custom_r1', firstName: 'Kamil', lastName: 'Tatrzak'),
        RiderProceduralGenerator.generateRider(
          teamId: customId,
          role: RiderRole.domestique,
          age: 23,
        ).copyWith(id: 'custom_r2', firstName: 'Michał', lastName: 'Górski'),
      ];

      final config = InitialGameSeedConfig(
        saveName: 'Kariera Tatry',
        playerManagerName: 'Jan Zakopiański',
        playerTeamId: customId,
        difficulty: CareerDifficulty.hard, // 75% budżetu
        seasonYear: 2026,
        seed: 777,
        customTeam: customTeam,
        customRoster: customRiders,
        saveToDisk: false,
      );

      final result = await InitialGameSeeder.seedNewGame(config);

      // Weryfikacja obecności zespołu
      expect(result.save.playerTeamId, equals(customId));
      expect(result.save.playerTeam.name, equals('Tatry Pro Cycling'));
      // Weryfikacja skalowania budżetu w poziomie hard (3.5M * 0.75 = 2.625M)
      expect(result.save.playerTeam.cashBalanceEur, equals(2625000));
      // Weryfikacja składu
      expect(result.save.playerRoster.length, equals(2));
      expect(result.save.playerRoster.any((r) => r.lastName == 'Tatrzak'), isTrue);
      // Weryfikacja obecności w kalendarzu
      expect(result.save.calendar.races.isNotEmpty, isTrue);
    });

    test('Bezpośrednio zasila CareerStateNotifier stanem nowo wygenerowanego świata', () async {
      final notifier = CareerStateNotifier();

      const config = InitialGameSeedConfig(
        saveName: 'Notifier Seed Test',
        playerManagerName: 'Menedżer Testowy',
        playerTeamId: 'team_corsa_armani',
        difficulty: CareerDifficulty.easy, // +50% budżetu
        seasonYear: 2026,
        seed: 1234,
        saveToDisk: false,
      );

      final result = await InitialGameSeeder.seedAndInitializeCareer(
        careerNotifier: notifier,
        config: config,
      );

      // Weryfikacja że stan w notifierze został natychmiast zaktualizowany
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.rawSave, isNotNull);
      expect(notifier.state.playerTeam.id, equals('team_corsa_armani'));
      expect(notifier.state.playerTeam.name, contains('Corsa'));
      expect(notifier.state.riders.length, greaterThan(800));
      expect(result.isUnderTwoSeconds, isTrue);
    });

    test('generateFreeAgentsPool tworzy poprawnych wolnych agentów z kontraktem do końca sezonu', () {
      final pool = InitialGameSeeder.generateFreeAgentsPool(
        count: 20,
        seasonYear: 2026,
      );

      expect(pool.length, equals(20));
      for (final rider in pool) {
        expect(rider.contract.teamId, isEmpty);
        expect(rider.contract.contractEndYear, equals(2026));
      }
    });

    test('buildFleetForTeam tworzy kompletną flotę maszyn wyścigowych z katalogu', () {
      final fleet = InitialGameSeeder.buildFleetForTeam('team_test', 'brand_aethel');

      expect(fleet.length, equals(3));
      final categories = fleet.map((b) => b.frame.category).toSet();
      expect(categories.contains(FrameCategory.aero), isTrue);
      expect(categories.contains(FrameCategory.lightweightClimbing), isTrue);
      expect(categories.contains(FrameCategory.timeTrial), isTrue);
    });
  });
}
