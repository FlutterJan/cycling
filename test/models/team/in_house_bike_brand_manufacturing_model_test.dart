import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/team/in_house_bike_brand_manufacturing_model.dart';

void main() {
  group('InHouseBikeBrandModel', () {
    test('createStarter builds valid brand with 2 homologated blueprints and JSON round-trip', () {
      final brand = InHouseBikeBrandModel.createStarter(
        brandId: 'brand_valkyrie',
        ownerTeamId: 'team_ppm',
        ownerTeamName: 'Team PPM Pro',
        brandName: 'Valkyrie Cycles',
        seasonYear: 2026,
      );

      expect(brand.blueprints.length, 2);
      expect(brand.homologatedBlueprints.length, 2);
      expect(brand.availableLicenseSlots, 1);
      expect(brand.annualProductionCapacityFrames, 140);

      final json = brand.toJson();
      final decoded = InHouseBikeBrandModel.fromJson(json);
      expect(decoded, brand);
    });

    test('asOwnTeamManufacturerDeal produces valid deal with supplied frame ids', () {
      final brand = InHouseBikeBrandModel.createStarter(
        brandId: 'brand_apex',
        ownerTeamId: 'team_1',
        ownerTeamName: 'Apex Racing',
        brandName: 'Apex Engineering',
        seasonYear: 2026,
      );

      final deal = brand.asOwnTeamManufacturerDeal();
      expect(deal.manufacturerId, 'brand_apex');
      expect(deal.suppliedFrameIds.length, 2);
      expect(deal.researchAndDevelopmentLevel, brand.rdEngineeringLevel);
    });

    test('upgradeFacility validates budget and tier order', () {
      final brand = InHouseBikeBrandModel.createStarter(
        brandId: 'brand_1',
        ownerTeamId: 'team_1',
        ownerTeamName: 'Team 1',
        brandName: 'VeloLab',
        seasonYear: 2026,
      );

      final insufficient = brand.upgradeFacility(
        nextTier: ManufacturingFacilityTier.carbonBoutiqueLab,
        availableTeamCashEur: 200000,
      );
      expect(insufficient.success, isFalse);

      final upgraded = brand.upgradeFacility(
        nextTier: ManufacturingFacilityTier.carbonBoutiqueLab,
        availableTeamCashEur: 2000000,
      );
      expect(upgraded.success, isTrue);
      expect(upgraded.cashDeltaEur, -1200000);
      expect(upgraded.model.facilityTier, ManufacturingFacilityTier.carbonBoutiqueLab);
      expect(upgraded.model.availableLicenseSlots, 3);
    });

    test('startRdProject and advanceRdProjects improve target blueprint upon completion', () {
      final brand = InHouseBikeBrandModel.createStarter(
        brandId: 'brand_rd',
        ownerTeamId: 'team_1',
        ownerTeamName: 'Team 1',
        brandName: 'AeroForge',
        seasonYear: 2026,
      );
      final targetId = brand.blueprints.first.blueprintId;
      final initialWeight = brand.blueprints.first.weightGrams;

      final started = brand.startRdProject(
        projectId: 'rd_1',
        title: 'Carbon Layup Evo 2',
        targetBlueprintId: targetId,
        focus: RdProjectFocus.ultralightLayup,
        budgetEur: 180000,
        availableTeamCashEur: 500000,
      );
      expect(started.success, isTrue);
      expect(started.model.activeRdProjects.length, 1);

      final completed = started.model.advanceRdProjects(60);
      expect(completed.activeRdProjects.first.isCompleted, isTrue);
      expect(completed.blueprints.first.weightGrams, lessThan(initialWeight));
      expect(completed.blueprints.first.rdGeneration, 2);
    });

    test('signLicenseContract and simulateQuarterFinancials compute revenue and reports', () {
      final brand = InHouseBikeBrandModel.createStarter(
        brandId: 'brand_biz',
        ownerTeamId: 'team_1',
        ownerTeamName: 'Team 1',
        brandName: 'Kinetix',
        seasonYear: 2026,
      ).upgradeFacility(
        nextTier: ManufacturingFacilityTier.worldTourRdFactory,
        availableTeamCashEur: 5000000,
      ).model;

      final blueprintId = brand.blueprints.first.blueprintId;
      final signed = brand.signLicenseContract(
        ExternalTeamLicenseContract(
          contractId: 'lic_1',
          partnerTeamId: 'team_partner',
          partnerTeamName: 'Nordic Pro Cycling',
          targetDivision: TeamFrameTargetDivision.proTeam,
          suppliedBlueprintId: blueprintId,
          annualLicenseFeeEur: 320000,
          framesOrderedPerSeason: 80,
          pricePerFrameEur: 2650,
          royaltyPerWorldTourWinEur: 15000,
          yearsRemaining: 2,
          status: BrandLicenseDealStatus.active,
          satisfactionScore: 88.0,
        ),
      );

      expect(signed.success, isTrue);
      expect(signed.model.contractedAnnualLicenseRevenueEur, 320000 + 80 * 2650);

      final quarterResult = signed.model.simulateQuarterFinancials(
        seasonYear: 2026,
        quarter: 1,
        ownTeamFramesConsumed: 25,
        partnerWorldTourWins: 2,
      );

      expect(quarterResult.success, isTrue);
      expect(quarterResult.model.quarterlyReports.length, 1);
      final report = quarterResult.model.quarterlyReports.first;
      expect(report.framesSoldToTeams, 20);
      expect(report.licenseRevenueEur, 80000 + 30000);
      expect(report.frameSalesRevenueEur, 20 * 2650);
    });
  });
}
