import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/pro_cyclist_career_state.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';

Rider _buildTestYoungRider() {
  return Rider(
    id: 'pro_player_1',
    firstName: 'Kacper',
    lastName: 'Kowalski',
    nationalityIso: 'POL',
    birthDate: DateTime(2008, 4, 15),
    potential: 92,
    specialization: RiderSpecialization.gcClimber,
    physiology: const RiderPhysiology(
      heightCm: 178.0,
      weightKg: 64.5,
      bodyFatPercentage: 7.2,
      ftpWatts: 345,
      wPrimeJoules: 21500,
      vo2Max: 76.5,
      maxHr: 198,
      restingHr: 41,
      lactateThresholdHr: 176,
      recoveryRate: 82.0,
      glycogenCapacityGrams: 540.0,
    ),
    powerProfile: const RiderPowerProfile(
      watts5s: 1120,
      watts15s: 920,
      watts30s: 740,
      watts1m: 580,
      watts3m: 445,
      watts5m: 415,
      watts20m: 365,
      watts60m: 335,
    ),
    skills: const RiderSkills(
      cobbles: 64,
      descending: 74,
      bikeHandling: 76,
      aeroPositioning: 72,
      draftingEfficiency: 75,
      raceIq: 78,
      rainResistance: 70,
      heatTolerance: 73,
      timeTrialPositioning: 71,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#F1C27D',
      hairStyleIndex: 2,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
      glassesModelId: 'aero_pro_01',
      glassesLensColorHex: '#38BDF8',
      helmetModelId: 'helm_carbon_02',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.72,
      bodyBuildType: BodyBuildType.climberLean,
    ),
    contract: const RiderContract(
      teamId: 'u23_dev_team',
      role: RiderRole.neoPro,
      monthlySalaryEur: 1800,
      signingBonusEur: 1000,
      winBonusEur: 400,
      releaseClauseEur: 45000,
      contractEndYear: 2027,
      morale: 85.0,
      leaderLoyalty: 80.0,
      requiredRacesIds: ['tour_de_lavenir'],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 42.0,
      chronicTrainingLoad: 58.0,
    ),
    careerPointsUci: 120,
  );
}

void main() {
  group('ProCyclistCareerState', () {
    test('createNew initializes 18-year-old U23 Continental career with debut entry', () {
      final rider = _buildTestYoungRider();
      final startDate = DateTime(2026, 5, 1);

      final state = ProCyclistCareerState.createNew(
        careerId: 'career_be_a_pro_1',
        careerName: 'Droga na Champs-Élysées',
        playerRider: rider,
        startDate: startDate,
      );

      expect(state.careerTier, ProCyclistCareerTier.u23Continental);
      expect(state.currentDivision, TeamDivision.continental);
      expect(state.careerAgeYears, 18);
      expect(state.dsTrustScore, 35.0);
      expect(state.dsTrustTier, DsTrustTier.probation);
      expect(state.skillPoints, 5);
      expect(state.privateBalanceEur, 2500);
      expect(state.achievementJournal, hasLength(1));
      expect(state.achievementJournal.first.category, ProCyclistJournalCategory.debut);
      expect(state.achievementJournal.first.isKeyMilestone, isTrue);
    });

    test('DS trust deltas clamp between 0 and 100 and unlock tactical permissions', () {
      final state = ProCyclistCareerState.createNew(
        careerId: 'c1',
        careerName: 'Test',
        playerRider: _buildTestYoungRider(),
        startDate: DateTime(2026, 6, 1),
      );

      final trusted = state.applyDsTrustDelta(30.0);
      expect(trusted.dsTrustScore, 65.0);
      expect(trusted.dsTrustTier, DsTrustTier.trusted);
      expect(trusted.canRequestBreakawayOrFreeRole, isTrue);
      expect(trusted.hasProtectedLeaderStatus, isFalse);

      final untouchable = trusted.applyDsTrustDelta(90.0);
      expect(untouchable.dsTrustScore, 100.0);
      expect(untouchable.dsTrustTier, DsTrustTier.untouchable);
      expect(untouchable.hasProtectedLeaderStatus, isTrue);

      final minimum = untouchable.applyDsTrustDelta(-150.0);
      expect(minimum.dsTrustScore, 0.0);
      expect(minimum.dsTrustTier, DsTrustTier.skeptical);
    });

    test('grantExperienceXp levels up rider and spendSkillPoints validates balance', () {
      final state = ProCyclistCareerState.createNew(
        careerId: 'c2',
        careerName: 'XP Test',
        playerRider: _buildTestYoungRider(),
        startDate: DateTime(2026, 6, 1),
      );

      // Level 1 requires 500 XP, Level 2 requires 1000 XP -> 1600 XP gives +2 levels (4 SP) and 100 remainder
      final leveled = state.grantExperienceXp(1600);
      expect(leveled.careerLevel, 3);
      expect(leveled.experienceXp, 100);
      expect(leveled.skillPoints, 9);
      expect(leveled.totalSkillPointsEarned, 9);

      final afterSpend = leveled.spendSkillPoints(4);
      expect(afterSpend.skillPoints, 5);
      expect(afterSpend.totalSkillPointsSpent, 4);

      final invalidSpend = afterSpend.spendSkillPoints(99);
      expect(invalidSpend.skillPoints, 5);
    });

    test('computes real estate, private equipment, sponsors and net worth accurately', () {
      final base = ProCyclistCareerState.createNew(
        careerId: 'c3',
        careerName: 'Assets Test',
        playerRider: _buildTestYoungRider(),
        startDate: DateTime(2026, 6, 1),
        initialPrivateBalanceEur: 150000,
      );

      final chalet = ProCyclistRealEstate(
        id: 'prop_andorra',
        name: 'Andorra La Vella Loft',
        location: 'Andora',
        altitudeMeters: 1650,
        category: ProCyclistPropertyCategory.mountainChalet,
        purchasePriceEur: 320000,
        monthlyUpkeepEur: 1400,
        recoveryBonusPercent: 8.5,
        altitudeAcclimatizationBonus: 12.0,
        taxShieldPercent: 18.0,
        purchasedDate: DateTime(2026, 5, 15),
        isPrimaryResidence: true,
      );

      final boots = ProCyclistPrivateEquipment(
        id: 'eq_recovery_boots',
        name: 'Normatec Pro 3.0',
        brand: 'Hyperice',
        category: ProCyclistEquipmentCategory.recoveryTech,
        purchasePriceEur: 1200,
        recoveryBonusPercent: 4.5,
        trainingXpBonusPercent: 6.0,
        wattSavings: 0.0,
        purchasedDate: DateTime(2026, 5, 20),
        isEquipped: true,
      );

      final wheelset = ProCyclistPrivateEquipment(
        id: 'eq_wheels',
        name: 'Aero Carbon 50mm',
        brand: 'Velocita',
        category: ProCyclistEquipmentCategory.aeroWheelset,
        purchasePriceEur: 2800,
        wattSavings: 6.5,
        purchasedDate: DateTime(2026, 5, 22),
        isEquipped: true,
      );

      const sponsor = ProCyclistPersonalSponsor(
        sponsorId: 'sp_oak',
        brandName: 'OptiVision',
        categoryLabel: 'Okulary',
        monthlyRetainerEur: 2500,
        winBonusEur: 1500,
        contractEndYear: 2028,
      );

      final updated = base.copyWith(
        ownedProperties: [chalet],
        ownedPrivateEquipment: [boots, wheelset],
        activePersonalSponsors: [sponsor],
      );

      expect(updated.totalMonthlyPropertyUpkeepEur, 1400);
      expect(updated.totalMonthlyPersonalSponsorIncomeEur, 2500);
      // 1800 salary + 2500 sponsor - 950 living - 1400 property = 1950
      expect(updated.projectedMonthlyNetCashflowEur, 1950);
      expect(updated.totalNetWorthEur, 150000 + 320000 + 1200 + 2800);
      expect(updated.totalRecoveryBonusPercent, 13.0);
      expect(updated.totalTrainingXpBonusPercent, 6.0);
      expect(updated.totalPrivateEquipmentWattSavings, 6.5);
    });

    test('full JSON round-trip preserves all fields including race assignment and journal', () {
      final base = ProCyclistCareerState.createNew(
        careerId: 'career_json_1',
        careerName: 'Legend Run',
        playerRider: _buildTestYoungRider(),
        startDate: DateTime(2026, 7, 10),
      );

      final assignment = ProCyclistRaceAssignment(
        assignmentId: 'assign_01',
        raceId: 'tour_de_lavenir_s3',
        raceName: "Tour de l'Avenir",
        stageNumber: 3,
        type: ProCyclistAssignmentType.protectLeader,
        title: 'Ochraniaj lidera na finałowym podjeździe',
        description: 'Utrzymuj się w odległości < 3m od lidera ekipy na ostatnich 15 km.',
        targetMetricLabel: 'km ochrony',
        targetValue: 15.0,
        currentProgress: 10.5,
        rewardTrustDelta: 6.5,
        penaltyTrustDelta: -4.0,
        rewardSkillPoints: 2,
        rewardXp: 250,
        rewardBonusEur: 500,
        status: ProCyclistAssignmentStatus.inProgress,
        assignedDate: DateTime(2026, 7, 10),
      );

      final enriched = base
          .copyWith(
            currentRaceAssignment: assignment,
            completedAssignmentsCount: 4,
            failedAssignmentsCount: 1,
            palmares: const ProCyclistPalmares(
              raceDays: 22,
              careerWins: 2,
              careerPodiums: 5,
              u23Wins: 2,
            ),
          )
          .appendJournalEntry(
            ProCyclistJournalEntry(
              entryId: 'win_u23_1',
              date: DateTime(2026, 7, 9),
              seasonYear: 2026,
              category: ProCyclistJournalCategory.victory,
              title: 'Pierwsze zwycięstwo U23',
              description: 'Wygrany etap górski po samotnym ataku.',
              raceName: 'Giro Next Gen',
              trustDelta: 8.0,
              xpDelta: 350,
              eurDelta: 1200,
              isKeyMilestone: true,
            ),
          );

      final jsonMap = enriched.toJson();
      final decoded = ProCyclistCareerState.fromJson(jsonMap);

      expect(decoded, equals(enriched));
      expect(decoded.currentRaceAssignment, equals(assignment));
      expect(decoded.currentRaceAssignment?.completionRatio, closeTo(0.7, 0.001));
      expect(decoded.assignmentSuccessRate, closeTo(0.8, 0.001));
      expect(decoded.achievementJournal, hasLength(2));
      expect(decoded.palmares.u23Wins, 2);
      expect(decoded.palmares.careerPodiums, 5);
    });
  });
}
