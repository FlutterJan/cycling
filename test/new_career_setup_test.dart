import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/models/equipment/frame_model.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/models/team/sponsor_contract.dart';
import 'package:pro_peloton_manager/services/database/save_service.dart';
import 'package:pro_peloton_manager/services/generators/fictional_brands_catalog.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';
import 'package:pro_peloton_manager/services/generators/world_teams_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
  });

  group('New Career Setup & Creation Tests', () {
    test('Tworzenie kariery z istniejącym zespołem WorldTour', () async {
      final world = WorldTeamsGenerator.generateWorldTourSystem(seed: 42);
      final firstTeamId = world.teams.first.id;

      // Inicjalizacja nowej kariery
      final save = await SaveService.createNewCareer(
        saveName: 'Test WT Career',
        playerManagerName: 'Test Manager',
        playerTeamId: firstTeamId,
        difficulty: CareerDifficulty.normal,
        seasonYear: 2026,
      );

      expect(save.playerTeamId, equals(firstTeamId));
      expect(save.playerManagerName, equals('Test Manager'));
      expect(save.currentSeasonYear, equals(2026));
      expect(save.teams.any((t) => t.id == firstTeamId), isTrue);
      expect(save.riders.isNotEmpty, isTrue);
      expect(save.calendar.races.isNotEmpty, isTrue);
      expect(save.financeLedger.isNotEmpty, isTrue);
    });

    test('Tworzenie kariery z własnym autorskim zespołem (Custom Team)', () async {
      const customTeamId = 'custom_omz_1234';
      const customTeamName = 'Orły Mazowsza';

      final bikeDeal = FictionalBrandsCatalog.createManufacturerDeal(
        brandId: 'brand_aethel',
      );

      final inventoryBikes = [
        FictionalBrandsCatalog.assembleBike(
          brandId: 'brand_aethel',
          frameCategory: FrameCategory.aero,
        ),
      ];

      const sponsor = SponsorContract(
        id: 'sponsor_omz_title',
        companyName: 'Orlen Energia',
        industry: SponsorIndustry.energy,
        sponsorTier: SponsorTier.titlePrimary,
        annualBudgetEur: 7000000,
        contractDurationYears: 3,
        sponsorSatisfaction: 85.0,
        objectives: [],
      );

      final draftedRiders = <Rider>[
        RiderProceduralGenerator.generateRider(
          specialization: RiderSpecialization.gcClimber,
          role: RiderRole.teamLeader,
          targetOverallRating: 82,
        ).copyWith(
          contract: const RiderContract(
            teamId: customTeamId,
            role: RiderRole.teamLeader,
            monthlySalaryEur: 35000,
            signingBonusEur: 50000,
            winBonusEur: 20000,
            releaseClauseEur: 2000000,
            contractEndYear: 2027,
            morale: 95.0,
            leaderLoyalty: 90.0,
            requiredRacesIds: [],
          ),
        ),
      ];

      final customTeam = CyclingTeam(
        id: customTeamId,
        name: customTeamName,
        division: TeamDivision.continental,
        countryIso: 'POL',
        primaryJerseyColorHex: '#E10600',
        secondaryJerseyColorHex: '#1E293B',
        accentJerseyColorHex: '#FACC15',
        cashBalanceEur: 9500000,
        monthlyBurnRateEur: 80000,
        uciPointsSeason: 0,
        rosterRiderIds: draftedRiders.map((r) => r.id).toList(),
        staff: const TeamStaff(
          trainersLevel: 70,
          sportsDirectorsLevel: 70,
          doctorsLevel: 70,
          mechanicsLevel: 70,
          scoutsLevel: 70,
        ),
        bikeDeal: bikeDeal,
        sponsors: [sponsor],
        inventoryBikes: inventoryBikes,
      );

      final save = await SaveService.createNewCareer(
        saveName: 'Test Custom Career',
        playerManagerName: 'Jan Kowalski',
        playerTeamId: customTeamId,
        difficulty: CareerDifficulty.normal,
        seasonYear: 2026,
        customTeam: customTeam,
        customRoster: draftedRiders,
      );

      expect(save.playerTeamId, equals(customTeamId));
      expect(save.playerManagerName, equals('Jan Kowalski'));
      expect(save.teams.any((t) => t.id == customTeamId), isTrue);

      final teamInSave = save.teams.firstWhere((t) => t.id == customTeamId);
      expect(teamInSave.name, equals(customTeamName));
      expect(teamInSave.countryIso, equals('POL'));
      expect(teamInSave.primaryJerseyColorHex, equals('#E10600'));

      expect(save.riders.any((r) => r.id == draftedRiders.first.id), isTrue);
      expect(save.financeLedger.first.amountEur, equals(teamInSave.cashBalanceEur));
    });
  });
}
