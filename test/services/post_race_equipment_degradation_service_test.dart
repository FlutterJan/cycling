import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/equipment/complete_bike.dart';
import 'package:pro_peloton_manager/models/equipment/equipment_wear_and_maintenance.dart';
import 'package:pro_peloton_manager/models/equipment/frame_model.dart';
import 'package:pro_peloton_manager/models/equipment/groupset_model.dart';
import 'package:pro_peloton_manager/models/equipment/tire_model.dart';
import 'package:pro_peloton_manager/models/equipment/wheelset_model.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/career/post_race_equipment_degradation_service.dart';

CompleteBike _buildTestBike({
  String id = 'bike-1',
  EquipmentWearAndMaintenance? wear,
}) {
  return CompleteBike(
    id: id,
    name: 'Test Pro SL8',
    frame: const FrameModel(
      id: 'frame-1',
      brandId: 'brand-1',
      name: 'Pro SL8',
      category: FrameCategory.allRounder,
      weightGrams: 720,
      aeroCdaModifier: -0.012,
      stiffnessToWeightIndex: 2.1,
      comfortCompliance: 0.75,
      priceEur: 5500,
      mesh3dAssetPath: 'assets/3d/frame.glb',
      primaryColorHex: '#8E4A49',
    ),
    wheelset: const WheelsetModel(
      id: 'wheel-1',
      brandId: 'brand-1',
      name: 'Aero 50',
      rimDepthMm: 50,
      weightGrams: 1320,
      aeroCdaModifier: -0.008,
      crosswindStabilityPenalty: 0.25,
      momentOfInertia: 0.085,
      hubEngagementDragWatts: 0.4,
      priceEur: 2400,
    ),
    groupset: const GroupsetModel(
      id: 'grp-1',
      brandId: 'brand-2',
      name: 'Dura-Ace Di2 12s',
      weightGrams: 2250,
      isElectronic: true,
      speedCount: 12,
      mechanicalEfficiency: 0.985,
      priceEur: 3500,
    ),
    tire: const TireModel(
      id: 'tire-1',
      brandId: 'brand-3',
      name: 'GP5000 S TR 28',
      widthMm: 28,
      weightGrams: 270,
      rollingResistanceCrr: 0.0033,
      punctureResistanceIndex: 3.5,
      wetGripIndex: 4.2,
      isTubeless: true,
      priceEur: 80,
    ),
    cockpitWidthMm: 380,
    hoodInwardTiltDegrees: 8.0,
    slammedStem: true,
    wearAndMaintenance: wear ?? EquipmentWearAndMaintenance.brandNew(),
  );
}

RaceStage _buildStage({
  required WeatherCondition weather,
  required SegmentSurfaceType surface,
  StageType stageType = StageType.flat,
  double lengthKm = 180.0,
}) {
  return RaceStage(
    id: 'stage-1',
    stageNumber: 1,
    name: 'Test Stage',
    stageType: stageType,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: lengthKm,
        startElevationM: 100.0,
        endElevationM: 100.0,
        surfaceType: surface,
        technicalDifficulty: 20.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.finishLine,
      ),
    ],
    baseTemperatureCelsius: 18.0,
    weatherCondition: weather,
    windSpeedKmh: 15.0,
  );
}

CyclingTeam _buildTestTeam(CompleteBike bike) {
  return CyclingTeam(
    id: 'team-1',
    name: 'Test Pro Cycling',
    division: TeamDivision.worldTour,
    countryIso: 'PL',
    primaryJerseyColorHex: '#8E4A49',
    secondaryJerseyColorHex: '#181B22',
    accentJerseyColorHex: '#D4AF37',
    cashBalanceEur: 500000,
    monthlyBurnRateEur: 120000,
    uciPointsSeason: 1000,
    rosterRiderIds: const ['rider-1'],
    staff: const TeamStaff(
      trainersLevel: 75,
      sportsDirectorsLevel: 75,
      doctorsLevel: 75,
      mechanicsLevel: 70,
      scoutsLevel: 70,
    ),
    bikeDeal: const BikeManufacturerDeal(
      manufacturerId: 'brand-1',
      manufacturerName: 'TestCycles',
      prestigeLevel: 4, // 20% discount
      annualCashContributionEur: 400000,
      freeBikesQuota: 80,
      researchAndDevelopmentLevel: 80,
      suppliedFrameIds: ['frame-1'],
      suppliedWheelsetIds: ['wheel-1'],
      contractYearsLeft: 2,
      minimumUciRankingRequired: 15,
    ),
    sponsors: const [],
    inventoryBikes: [bike],
  );
}

void main() {
  const service = PostRaceEquipmentDegradationService();

  group('PostRaceEquipmentDegradationService', () {
    test('Deszcz zwiększa 3-krotnie zużycie łańcucha, kasety, opon i łożysk', () {
      final dryStage = _buildStage(
        weather: WeatherCondition.sunny,
        surface: SegmentSurfaceType.smoothAsphalt,
      );
      final rainStage = _buildStage(
        weather: WeatherCondition.heavyStorm,
        surface: SegmentSurfaceType.smoothAsphalt,
      );

      final usage = RiderBikeStageUsage(
        riderId: 'rider-1',
        riderName: 'Jan Kowalski',
        bike: _buildTestBike(),
      );

      final dryReport = service.processPostStageDegradation(
        stage: dryStage,
        usages: [usage],
        autoReplaceWornParts: false,
      );
      final rainReport = service.processPostStageDegradation(
        stage: rainStage,
        usages: [usage],
        autoReplaceWornParts: false,
      );

      expect(dryReport.rainWearMultiplier, 1.0);
      expect(rainReport.rainWearMultiplier, 3.0);

      final dryBike = dryReport.bikeReports.single;
      final rainBike = rainReport.bikeReports.single;

      expect(
        rainBike.cassetteWearDeltaPercent,
        closeTo(dryBike.cassetteWearDeltaPercent * 3.0, 0.001),
      );
      expect(
        rainBike.bearingsWearDeltaPercent,
        closeTo(dryBike.bearingsWearDeltaPercent * 3.0, 0.001),
      );
      expect(
        rainBike.frontTireWearDeltaPercent,
        closeTo(dryBike.frontTireWearDeltaPercent * 3.0, 0.001),
      );
      expect(
        rainBike.rearTireWearDeltaPercent,
        closeTo(dryBike.rearTireWearDeltaPercent * 3.0, 0.001),
      );
      expect(
        rainBike.chainElongationDeltaPercent,
        greaterThanOrEqualTo(dryBike.chainElongationDeltaPercent * 3.0),
      );
    });

    test('Bruk zwiększa 3-krotnie zużycie łańcucha, kasety, opon i łożysk', () {
      final asphaltStage = _buildStage(
        weather: WeatherCondition.sunny,
        surface: SegmentSurfaceType.smoothAsphalt,
      );
      final cobbleStage = _buildStage(
        weather: WeatherCondition.sunny,
        surface: SegmentSurfaceType.cobblestonesSector4,
        stageType: StageType.cobbleClassic,
      );

      final usage = RiderBikeStageUsage(
        riderId: 'rider-1',
        riderName: 'Marek Nowak',
        bike: _buildTestBike(),
      );

      final asphaltReport = service.processPostStageDegradation(
        stage: asphaltStage,
        usages: [usage],
        autoReplaceWornParts: false,
      );
      final cobbleReport = service.processPostStageDegradation(
        stage: cobbleStage,
        usages: [usage],
        autoReplaceWornParts: false,
      );

      expect(asphaltReport.cobblestoneWearMultiplier, 1.0);
      expect(cobbleReport.cobblestoneWearMultiplier, 3.0);

      final asphaltBike = asphaltReport.bikeReports.single;
      final cobbleBike = cobbleReport.bikeReports.single;

      expect(
        cobbleBike.cassetteWearDeltaPercent,
        closeTo(asphaltBike.cassetteWearDeltaPercent * 3.0, 0.001),
      );
      expect(
        cobbleBike.bearingsWearDeltaPercent,
        closeTo(asphaltBike.bearingsWearDeltaPercent * 3.0, 0.001),
      );
      expect(
        cobbleBike.frontTireWearDeltaPercent,
        closeTo(asphaltBike.frontTireWearDeltaPercent * 3.0, 0.001),
      );
      expect(
        cobbleBike.rearTireWearDeltaPercent,
        closeTo(asphaltBike.rearTireWearDeltaPercent * 3.0, 0.001),
      );
      expect(
        cobbleBike.chainElongationDeltaPercent,
        closeTo(asphaltBike.chainElongationDeltaPercent * 3.0, 0.0001),
      );
    });

    test('Generuje raport kosztów części zamiennych i obciąża budżet drużyny', () {
      final wornBike = _buildTestBike(
        wear: EquipmentWearAndMaintenance(
          chain: const ChainAndWaxCondition(
            lubricantType: DrivetrainLubricantType.hotMeltWaxStandard,
            waxFilmRemainingPercent: 30.0,
            chainElongationPercent: 0.49,
            totalChainMileageKm: 2800.0,
            mileageSinceLastWaxKm: 180.0,
            isWashedOut: false,
          ),
          frontTire: const TireWearCondition(
            treadWearPercent: 78.0,
            microCutsCount: 2,
            tubelessSealantVolumeMl: 30.0,
            tubelessSealantFreshnessPercent: 70.0,
            totalMileageKm: 2500.0,
          ),
          rearTire: const TireWearCondition(
            treadWearPercent: 79.0,
            microCutsCount: 3,
            tubelessSealantVolumeMl: 30.0,
            tubelessSealantFreshnessPercent: 70.0,
            totalMileageKm: 2500.0,
          ),
          frontBrake: BrakeWearCondition.brandNew(),
          rearBrake: BrakeWearCondition.brandNew(),
          electronicBatteryPercent: 90.0,
        ),
      );

      final team = _buildTestTeam(wornBike);
      final stage = _buildStage(
        weather: WeatherCondition.lightRain,
        surface: SegmentSurfaceType.cobblestonesSector5,
        stageType: StageType.cobbleClassic,
        lengthKm: 200.0,
      );

      final report = service.processPostStageDegradation(
        stage: stage,
        usages: [
          RiderBikeStageUsage(
            riderId: 'rider-1',
            riderName: 'Jan Kowalski',
            bike: wornBike,
            cassetteAndBearingWear: const CassetteAndBearingWear(
              cassetteWearPercent: 75.0,
              bearingsWearPercent: 70.0,
              cassetteMileageKm: 4000.0,
              bearingsMileageKm: 5000.0,
            ),
          ),
        ],
        bikeDeal: team.bikeDeal,
        mechanicsLevel: team.staff.mechanicsLevel,
      );

      expect(report.combinedWearMultiplier, 9.0);
      expect(report.chainsReplacedCount, 1);
      expect(report.cassettesReplacedCount, 1);
      expect(report.tiresReplacedCount, 2);
      expect(report.bearingsReplacedCount, 1);
      expect(report.grossPartsCostEur, greaterThan(0));
      expect(report.manufacturerDiscountEur, greaterThan(0));
      expect(
        report.netTeamBudgetCostEur,
        report.grossPartsCostEur - report.manufacturerDiscountEur,
      );

      final updatedTeam = report.applyToTeam(team);
      expect(
        updatedTeam.cashBalanceEur,
        team.cashBalanceEur - report.netTeamBudgetCostEur,
      );
      expect(
        updatedTeam.inventoryBikes.single.wear.chain.chainElongationPercent,
        lessThan(0.10),
      );
    });

    test('Obsługuje pustą listę kolarzy i zerowy dystans bez błędów', () {
      final stage = _buildStage(
        weather: WeatherCondition.sunny,
        surface: SegmentSurfaceType.smoothAsphalt,
        lengthKm: 0.0,
      );

      final report = service.processPostStageDegradation(
        stage: stage,
        usages: const [],
      );

      expect(report.bikeReports, isEmpty);
      expect(report.grossPartsCostEur, 0);
      expect(report.netTeamBudgetCostEur, 0);
      expect(report.summaryLines, isNotEmpty);
    });
  });
}
