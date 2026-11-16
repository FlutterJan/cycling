import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/staff_member.dart';
import 'package:pro_peloton_manager/models/equipment/complete_bike.dart';
import 'package:pro_peloton_manager/models/equipment/frame_model.dart';
import 'package:pro_peloton_manager/models/equipment/groupset_model.dart';
import 'package:pro_peloton_manager/models/equipment/tire_model.dart';
import 'package:pro_peloton_manager/models/equipment/wheelset_model.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/career/agent_contract_clauses_engine.dart';

Rider _buildEliteGcRider({String id = 'rider_gc_1'}) {
  return Rider(
    id: id,
    firstName: 'Tadej',
    lastName: 'Kowalski',
    nationalityIso: 'POL',
    birthDate: DateTime(1998, 9, 21),
    potential: 94,
    specialization: RiderSpecialization.gcClimber,
    physiology: const RiderPhysiology(
      heightCm: 176,
      weightKg: 66.0,
      bodyFatPercentage: 6.2,
      ftpWatts: 430,
      wPrimeJoules: 26000,
      vo2Max: 88.0,
      maxHr: 196,
      restingHr: 38,
      lactateThresholdHr: 178,
      recoveryRate: 92.0,
      glycogenCapacityGrams: 540.0,
    ),
    powerProfile: const RiderPowerProfile(
      watts5s: 1220,
      watts15s: 1020,
      watts30s: 830,
      watts1m: 740,
      watts3m: 540,
      watts5m: 500,
      watts20m: 425,
      watts60m: 405,
    ),
    skills: const RiderSkills(
      cobbles: 74,
      descending: 88,
      bikeHandling: 86,
      aeroPositioning: 85,
      draftingEfficiency: 84,
      raceIq: 92,
      rainResistance: 80,
      heatTolerance: 82,
      timeTrialPositioning: 87,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#F2C9AC',
      hairStyleIndex: 2,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
      glassesModelId: 'glasses_pro',
      glassesLensColorHex: '#D4AF37',
      helmetModelId: 'helmet_aero',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.5,
      bodyBuildType: BodyBuildType.climberLean,
    ),
    contract: const RiderContract(
      teamId: 'team_wt_1',
      role: RiderRole.teamLeader,
      monthlySalaryEur: 140000,
      signingBonusEur: 250000,
      winBonusEur: 25000,
      releaseClauseEur: 2500000,
      contractEndYear: 2028,
      morale: 85.0,
      leaderLoyalty: 82.0,
      requiredRacesIds: ['tdf'],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 42.0,
      chronicTrainingLoad: 88.0,
    ),
    careerPointsUci: 4200,
  );
}

CompleteBike _buildBike({
  required int frameWeightGrams,
  required double stiffness,
  required int framePriceEur,
  required int wheelWeightGrams,
  required int wheelPriceEur,
}) {
  return CompleteBike(
    id: 'bike_${frameWeightGrams}_$wheelWeightGrams',
    name: 'Pro Team Bike',
    frame: FrameModel(
      id: 'frame_1',
      brandId: 'brand_1',
      name: 'Aero Carbon SL',
      category: FrameCategory.allRounder,
      weightGrams: frameWeightGrams,
      aeroCdaModifier: -0.015,
      stiffnessToWeightIndex: stiffness,
      comfortCompliance: 0.78,
      priceEur: framePriceEur,
      mesh3dAssetPath: 'assets/3d/frame.glb',
      primaryColorHex: '#8E4A49',
    ),
    wheelset: WheelsetModel(
      id: 'wheel_1',
      brandId: 'brand_w',
      name: 'Carbon 50 Pro',
      rimDepthMm: 50,
      weightGrams: wheelWeightGrams,
      aeroCdaModifier: -0.009,
      crosswindStabilityPenalty: 0.15,
      momentOfInertia: 0.085,
      hubEngagementDragWatts: 1.2,
      priceEur: wheelPriceEur,
    ),
    groupset: const GroupsetModel(
      id: 'grp_1',
      brandId: 'shimano',
      name: 'Dura-Ace Di2',
      weightGrams: 2150,
      isElectronic: true,
      speedCount: 12,
      mechanicalEfficiency: 0.985,
      priceEur: 3800,
    ),
    tire: const TireModel(
      id: 'tire_1',
      brandId: 'conti',
      name: 'GP5000 S TR',
      widthMm: 28,
      weightGrams: 250,
      rollingResistanceCrr: 0.0034,
      punctureResistanceIndex: 3.5,
      wetGripIndex: 4.5,
      isTubeless: true,
      priceEur: 90,
    ),
    cockpitWidthMm: 380,
    hoodInwardTiltDegrees: 8.0,
    slammedStem: true,
  );
}

CyclingTeam _buildTeam({
  TeamDivision division = TeamDivision.worldTour,
  int trainersLevel = 84,
  List<CompleteBike> inventoryBikes = const [],
}) {
  return CyclingTeam(
    id: 'team_wt_1',
    name: 'Polonia Racing WorldTour',
    division: division,
    countryIso: 'POL',
    primaryJerseyColorHex: '#8E4A49',
    secondaryJerseyColorHex: '#0F1115',
    accentJerseyColorHex: '#D4AF37',
    cashBalanceEur: 4500000,
    monthlyBurnRateEur: 350000,
    uciPointsSeason: 9800,
    rosterRiderIds: const ['rider_gc_1'],
    staff: TeamStaff(
      trainersLevel: trainersLevel,
      sportsDirectorsLevel: 85,
      doctorsLevel: 82,
      mechanicsLevel: 86,
      scoutsLevel: 80,
    ),
    bikeDeal: const BikeManufacturerDeal(
      manufacturerId: 'brand_1',
      manufacturerName: 'Romet Pro Carbon',
      prestigeLevel: 5,
      annualCashContributionEur: 1200000,
      freeBikesQuota: 90,
      researchAndDevelopmentLevel: 88,
      suppliedFrameIds: ['frame_1'],
      suppliedWheelsetIds: ['wheel_1'],
      contractYearsLeft: 2,
      minimumUciRankingRequired: 18,
    ),
    sponsors: const [],
    inventoryBikes: inventoryBikes,
  );
}

PerformanceCoach _buildCoach({String id = 'coach_1', int experience = 88}) {
  return PerformanceCoach(
    id: id,
    firstName: 'Marek',
    lastName: 'Nowak',
    nationalityIso: 'POL',
    age: 44,
    experienceLevel: experience,
    monthlySalaryEur: 6500,
    contractEndYear: 2028,
    reputation: 86,
    ftpDevelopmentEfficiency: 90,
    sprintAndNeuromuscularFocus: 75,
    winterGymPeriodizationSkill: 84,
    overtrainingPrevention: 88,
    specialization: CoachSpecialization.enduranceAndClimbing,
  );
}

void main() {
  const engine = AgentContractClausesEngine();

  group('AgentContractClausesEngine', () {
    test('generates all 4 special clauses for elite WorldTour GC rider', () {
      final rider = _buildEliteGcRider();
      final coach = _buildCoach();
      final bundle = engine.generateRecommendedClausesForRider(
        rider,
        currentDivision: TeamDivision.worldTour,
        availableStaff: [coach],
      );

      expect(bundle.clauses.length, 4);
      expect(bundle.hasClause(AgentContractClauseType.guaranteedGrandTourLeadership), isTrue);
      expect(bundle.hasClause(AgentContractClauseType.equipmentVeto), isTrue);
      expect(bundle.hasClause(AgentContractClauseType.personalSoigneurOrCoach), isTrue);
      expect(bundle.hasClause(AgentContractClauseType.relegationFreeRelease), isTrue);
      expect(
        bundle.findClause(AgentContractClauseType.personalSoigneurOrCoach)?.preferredCoachId,
        coach.id,
      );
    });

    test('calculates negotiated salary discount capped at 28%', () {
      final clauses = [
        AgentContractClause.guaranteedGrandTourLeadership(salaryDiscountFactor: 0.12),
        AgentContractClause.equipmentVeto(salaryDiscountFactor: 0.10),
        AgentContractClause.personalSoigneurOrCoach(salaryDiscountFactor: 0.10),
        AgentContractClause.relegationFreeRelease(salaryDiscountFactor: 0.10),
      ];

      final negotiated = engine.calculateNegotiatedSalaryWithClauses(
        baseSalaryDemandEur: 100000,
        activeClauses: clauses,
      );
      expect(negotiated, 72000);
    });

    test('evaluates all 4 clauses as compliant when team meets requirements', () {
      final rider = _buildEliteGcRider();
      final coach = _buildCoach(id: 'coach_fav', experience: 90);
      final proBike = _buildBike(
        frameWeightGrams: 720,
        stiffness: 2.05,
        framePriceEur: 6800,
        wheelWeightGrams: 1280,
        wheelPriceEur: 3800,
      );
      final team = _buildTeam(
        division: TeamDivision.worldTour,
        trainersLevel: 90,
        inventoryBikes: [proBike],
      );

      final bundle = RiderContractClausesBundle(
        riderId: rider.id,
        clauses: [
          AgentContractClause.guaranteedGrandTourLeadership(
            targetGrandTour: GrandTourTarget.tourDeFrance,
          ),
          AgentContractClause.equipmentVeto(
            maximumFrameWeightGrams: 800,
            minimumFrameStiffnessIndex: 1.80,
            maximumWheelsetWeightGrams: 1380,
            minimumEquipmentTierPriceEur: 10000,
          ),
          AgentContractClause.personalSoigneurOrCoach(
            preferredCoachId: coach.id,
            preferredCoachName: coach.fullName,
            minimumCoachExperienceLevel: 85,
          ),
          AgentContractClause.relegationFreeRelease(),
        ],
      );

      final report = engine.evaluateClauses(
        bundle,
        ClauseEvaluationContext(
          rider: rider,
          team: team,
          assignedGrandTourLeaderIds: {
            GrandTourTarget.tourDeFrance: [rider.id],
          },
          assignedBike: proBike,
          teamStaffMembers: [coach],
        ),
      );

      expect(report.hasAnyBreach, isFalse);
      expect(report.isFreeAgentReleaseTriggered, isFalse);
      expect(report.results.every((r) => r.status == ClauseComplianceStatus.compliant), isTrue);
    });

    test('detects breaches for GT leadership, Equipment Veto and Personal Coach', () {
      final rider = _buildEliteGcRider();
      final heavyBike = _buildBike(
        frameWeightGrams: 1120,
        stiffness: 1.35,
        framePriceEur: 2800,
        wheelWeightGrams: 1680,
        wheelPriceEur: 1400,
      );
      final team = _buildTeam(
        division: TeamDivision.worldTour,
        trainersLevel: 60,
        inventoryBikes: [heavyBike],
      );

      final bundle = RiderContractClausesBundle(
        riderId: rider.id,
        clauses: [
          AgentContractClause.guaranteedGrandTourLeadership(
            targetGrandTour: GrandTourTarget.giroDItalia,
          ),
          AgentContractClause.equipmentVeto(),
          AgentContractClause.personalSoigneurOrCoach(
            preferredCoachId: 'coach_missing',
            preferredCoachName: 'Jan Kowal',
            minimumCoachExperienceLevel: 85,
          ),
        ],
      );

      final report = engine.evaluateClauses(
        bundle,
        ClauseEvaluationContext(
          rider: rider,
          team: team,
          assignedGrandTourLeaderIds: const {
            GrandTourTarget.giroDItalia: ['other_rider'],
          },
          assignedBike: heavyBike,
          teamStaffMembers: const [],
        ),
      );

      expect(report.hasAnyBreach, isTrue);
      expect(report.hasEquipmentVetoBlock, isTrue);
      expect(report.totalMoraleDelta, lessThan(0));
      expect(report.totalLoyaltyDelta, lessThan(0));
      expect(report.updatedContract.morale, lessThan(rider.contract.morale));
      expect(report.updatedContract.leaderLoyalty, lessThan(rider.contract.leaderLoyalty));
    });

    test('triggers Relegation Free Release and zeroes releaseClauseEur on WorldTour relegation', () {
      final rider = _buildEliteGcRider();
      final team = _buildTeam(division: TeamDivision.proTeam);
      final bundle = RiderContractClausesBundle(
        riderId: rider.id,
        clauses: [AgentContractClause.relegationFreeRelease()],
      );

      final report = engine.evaluateClauses(
        bundle,
        ClauseEvaluationContext(
          rider: rider,
          team: team,
          previousDivision: TeamDivision.worldTour,
          wasRelegatedFromWorldTour: true,
        ),
      );

      expect(report.isFreeAgentReleaseTriggered, isTrue);
      expect(report.updatedContract.releaseClauseEur, 0);
      expect(report.results.first.status, ClauseComplianceStatus.triggered);
    });

    test('supports JSON serialization round-trip for RiderContractClausesBundle', () {
      final rider = _buildEliteGcRider();
      final original = engine.generateRecommendedClausesForRider(rider);
      final json = original.toJson();
      final restored = RiderContractClausesBundle.fromJson(json);

      expect(restored.riderId, original.riderId);
      expect(restored.clauses.length, original.clauses.length);
      expect(restored.clauses, equals(original.clauses));
    });
  });

  group('AgentContractClausesPanel Widget', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final rider = _buildEliteGcRider();
        var bundle = engine.generateRecommendedClausesForRider(rider);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AgentContractClausesPanel(
                  bundle: bundle,
                  baseMonthlySalaryEur: 140000,
                  isNegotiationEditable: true,
                  onBundleChanged: (updated) => bundle = updated,
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Klauzule Specjalne Agenta'), findsOneWidget);
        expect(find.text('Guaranteed Grand Tour Leadership'), findsOneWidget);
        expect(find.text('Equipment Veto'), findsOneWidget);
        expect(find.text('Personal Soigneur/Coach'), findsOneWidget);
        expect(find.text('Relegation Free Release'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
