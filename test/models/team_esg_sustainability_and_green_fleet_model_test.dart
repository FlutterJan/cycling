import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/team_esg_sustainability_and_green_fleet_model.dart';

void main() {
  group('TeamEsgSustainabilityAndGreenFleetModel', () {
    test('starter WorldTour model computes valid overview and ESG tier', () {
      final model = TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
        teamId: 'team_wt_1',
      );

      final overview = model.computeOverview();
      expect(overview.esgScore, greaterThan(50.0));
      expect(overview.esgScore, lessThanOrEqualTo(100.0));
      expect(overview.fleetElectrificationRatio, greaterThan(0.5));
      expect(overview.activeGreenSponsorsCount, 1);
      expect(overview.projectedGreenSponsorRevenueEur, 700000.0);
    });

    test('JSON serialization round-trip preserves all fields', () {
      final original = TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
        teamId: 'team_wt_json',
        seasonYear: 2027,
        cashBalanceEur: 980000.0,
      );

      final json = original.toJson();
      final restored = TeamEsgSustainabilityAndGreenFleetModel.fromJson(json);

      expect(restored.teamId, original.teamId);
      expect(restored.seasonYear, 2027);
      expect(restored.cashBalanceEur, 980000.0);
      expect(restored.vehicles.length, original.vehicles.length);
      expect(restored.ledger.length, original.ledger.length);
      expect(restored.greenSponsors.length, original.greenSponsors.length);
      expect(restored.infrastructureTier, original.infrastructureTier);
      expect(
        restored.computeOverview().esgScore,
        closeTo(original.computeOverview().esgScore, 0.0001),
      );
    });

    test('upgrading diesel vehicle to BEV increases electrification and deducts net cost', () {
      final starter = TeamEsgSustainabilityAndGreenFleetModel.createStarterContinental(
        teamId: 'team_cont_1',
        cashBalanceEur: 300000.0,
      );

      const newEvCar = TeamFleetVehicle(
        id: 'veh_ev_ds_1',
        name: 'Kia EV6 GT-Line DS',
        vehicleType: FleetVehicleType.directorSportifCar,
        powertrain: PowertrainType.batteryElectric,
        batteryCapacityKwh: 77.4,
        wltpRangeKm: 528.0,
        co2GramsPerKm: 0.0,
        purchaseCostEur: 58000.0,
        annualMaintenanceEur: 2800.0,
        isActiveInRaceConvoy: true,
        assignedRoleLabel: 'DS Car #1',
      );

      final result = starter.purchaseOrUpgradeVehicle(
        newEvCar,
        replaceVehicleId: 'veh_cont_ds_1',
      );

      expect(result.success, isTrue);
      final updated = result.data!;
      expect(
        updated.computeOverview().fleetElectrificationRatio,
        greaterThan(starter.computeOverview().fleetElectrificationRatio),
      );
      expect(updated.cashBalanceEur, lessThan(starter.cashBalanceEur));
    });

    test('mountain cold stage reduces BEV effective range and flags range anxiety when needed', () {
      final model = TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
        teamId: 'team_wt_range',
      );

      final readiness = model.evaluateStageConvoyReadiness(
        const StageConvoyLogisticsPlan(
          stageId: 'stage_alpe_2026',
          stageName: 'Alpe d\'Huez Queen Stage',
          stageDistanceKm: 420.0, // extreme + 35 km = 455 km
          elevationGainM: 5200.0,
          ambientTempC: 2.0,
          chargingStopsPlanned: 0,
        ),
      );

      expect(readiness.rangeAnxietyRisk, isTrue);
      expect(readiness.bottleneckVehicleNames, isNotEmpty);
      expect(readiness.warnings, isNotEmpty);
    });

    test('recording convoy trip and team travel updates CO2 ledger and rail policy converts short flights', () {
      final model = TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
        teamId: 'team_wt_travel',
      );

      final stageRes = model.recordRaceConvoyTrip(
        stageId: 'st_1',
        stageName: 'Paris-Roubaix',
        distanceKm: 257.0,
        elevationGainM: 1200.0,
        ambientTempC: 14.0,
        dateIso: '2026-04-12',
      );
      expect(stageRes.success, isTrue);

      final travelRes = stageRes.data!.recordTeamTravel(
        description: 'Brussels to Roubaix Transfer',
        mode: TravelTransportMode.shortHaulFlight,
        distanceKm: 120.0,
        delegationSize: 22,
        dateIso: '2026-04-11',
      );
      expect(travelRes.success, isTrue);

      final travelEntry = travelRes.data!.ledger.last;
      // With railOverFlightPolicyEnabled = true, short-haul < 700 km uses highSpeedRail (0.014 kg/pkm)
      expect(travelEntry.co2KgDelta, closeTo(120.0 * 22 * 0.014, 0.01));
    });

    test('purchasing carbon offsets reduces net carbon balance and can achieve neutrality', () {
      final model = TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
        teamId: 'team_wt_offset',
        cashBalanceEur: 1500000.0,
      );

      final offsetRes = model.purchaseCarbonOffsets(
        tonsCo2: 20.0,
        program: CarbonOffsetProgramType.directAirCapture,
        dateIso: '2026-06-01',
      );

      expect(offsetRes.success, isTrue);
      final overview = offsetRes.data!.computeOverview();
      expect(overview.isCarbonNeutral, isTrue);
      expect(overview.netCarbonBalanceKg, lessThanOrEqualTo(0.0));
    });

    test('green sponsor signing requires ESG score & zero-emission race cars when configured', () {
      final model = TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
        teamId: 'team_wt_sponsor',
      );

      // VoltDrive Mobility requires zero-emission race cars (mechanic car is PHEV)
      final failRes = model.signGreenSponsor('gsp_volt_mobility');
      expect(failRes.success, isFalse);

      // Replace PHEV mechanic car with BEV and upgrade infrastructure + eco bottles
      const evMech = TeamFleetVehicle(
        id: 'veh_mech_bev',
        name: 'VW ID.7 Tourer Support #2',
        vehicleType: FleetVehicleType.mechanicSupportCar,
        powertrain: PowertrainType.batteryElectric,
        batteryCapacityKwh: 86.0,
        wltpRangeKm: 610.0,
        co2GramsPerKm: 0.0,
        purchaseCostEur: 68000.0,
        annualMaintenanceEur: 3100.0,
        isActiveInRaceConvoy: true,
        assignedRoleLabel: 'Mechanic #2',
      );

      final step1 = model
          .purchaseOrUpgradeVehicle(evMech, replaceVehicleId: 'veh_mech_1')
          .data!;
      final step2 = step1
          .upgradeChargingInfrastructure(
            ChargingInfrastructureTier.solarMicrogridHq,
          )
          .data!
          .togglePolicy(ecoBottles: true);

      final signRes = step2.signGreenSponsor('gsp_volt_mobility');
      expect(signRes.success, isTrue);
      expect(signRes.data!.computeOverview().activeGreenSponsorsCount, 2);

      final payoutRes = signRes.data!.collectAnnualGreenSponsorPayouts();
      expect(payoutRes.success, isTrue);
      expect(
        payoutRes.data!.cashBalanceEur,
        greaterThan(signRes.data!.cashBalanceEur),
      );
    });
  });
}
