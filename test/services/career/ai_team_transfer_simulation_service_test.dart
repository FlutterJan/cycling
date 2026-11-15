import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/career/ai_team_transfer_simulation_service.dart';
import 'package:pro_peloton_manager/services/career/uci_promotion_relegation_cycle_service.dart';
import 'package:pro_peloton_manager/state/career_state_notifier.dart';

Rider _buildTestRider({
  required String id,
  required String firstName,
  required String lastName,
  required String teamId,
  required int age,
  int potential = 82,
  RiderSpecialization specialization = RiderSpecialization.gcClimber,
  double weightKg = 64.0,
  int ftpWatts = 410,
  int watts5s = 1200,
  int watts20m = 425,
  int cobbles = 60,
  int uciPoints = 600,
  RiderRole role = RiderRole.teamLeader,
  int contractEndYear = 2026,
  int releaseClauseEur = 0,
  int monthlySalaryEur = 25000,
}) {
  final birthDate = DateTime(2026 - age, 5, 10);
  return Rider(
    id: id,
    firstName: firstName,
    lastName: lastName,
    nationalityIso: 'POL',
    birthDate: birthDate,
    potential: potential,
    specialization: specialization,
    physiology: RiderPhysiology(
      heightCm: 178.0,
      weightKg: weightKg,
      bodyFatPercentage: 7.5,
      ftpWatts: ftpWatts,
      wPrimeJoules: 22000,
      vo2Max: 83.0,
      maxHr: 194,
      restingHr: 40,
      lactateThresholdHr: 174,
      recoveryRate: 1.1,
      glycogenCapacityGrams: 520.0,
    ),
    powerProfile: RiderPowerProfile(
      watts5s: watts5s,
      watts15s: (watts5s * 0.86).round(),
      watts30s: (watts5s * 0.72).round(),
      watts1m: 680,
      watts3m: 510,
      watts5m: 470,
      watts20m: watts20m,
      watts60m: ftpWatts,
    ),
    skills: RiderSkills(
      cobbles: cobbles,
      descending: 76,
      bikeHandling: 78,
      aeroPositioning: 76,
      draftingEfficiency: 77,
      raceIq: 79,
      rainResistance: 74,
      heatTolerance: 75,
      timeTrialPositioning: 75,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 0,
      skinToneHex: '#F1C27D',
      hairStyleIndex: 1,
      hairColorHex: '#2C1E16',
      facialHairIndex: 0,
      glassesModelId: 'oakley_sutro',
      glassesLensColorHex: '#38BDF8',
      helmetModelId: 'aero_pro',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.5,
      bodyBuildType: BodyBuildType.climberLean,
    ),
    contract: RiderContract(
      teamId: teamId,
      role: role,
      monthlySalaryEur: monthlySalaryEur,
      signingBonusEur: 20000,
      winBonusEur: 5000,
      releaseClauseEur: releaseClauseEur,
      contractEndYear: contractEndYear,
      morale: 0.8,
      leaderLoyalty: 0.8,
      requiredRacesIds: const [],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 30.0,
      chronicTrainingLoad: 75.0,
    ),
    careerPointsUci: uciPoints,
  );
}

CyclingTeam _buildTestTeam({
  required String id,
  required String name,
  TeamDivision division = TeamDivision.worldTour,
  int cashBalanceEur = 8000000,
  int uciPointsSeason = 6500,
  List<String> rosterRiderIds = const [],
}) {
  return CyclingTeam(
    id: id,
    name: name,
    division: division,
    countryIso: 'BEL',
    primaryJerseyColorHex: '#181B22',
    secondaryJerseyColorHex: '#8E4A49',
    accentJerseyColorHex: '#D4AF37',
    cashBalanceEur: cashBalanceEur,
    monthlyBurnRateEur: 250000,
    uciPointsSeason: uciPointsSeason,
    rosterRiderIds: rosterRiderIds,
    staff: const TeamStaff(
      trainersLevel: 80,
      sportsDirectorsLevel: 80,
      doctorsLevel: 80,
      mechanicsLevel: 80,
      scoutsLevel: 80,
    ),
    bikeDeal: const BikeManufacturerDeal(
      manufacturerId: 'brand_1',
      manufacturerName: 'AeroVelo',
      prestigeLevel: 4,
      annualCashContributionEur: 1200000,
      freeBikesQuota: 80,
      researchAndDevelopmentLevel: 80,
      suppliedFrameIds: ['frame_1'],
      suppliedWheelsetIds: ['wheel_1'],
      contractYearsLeft: 2,
      minimumUciRankingRequired: 15,
    ),
    sponsors: const [],
    inventoryBikes: const [],
  );
}

void main() {
  group('AiTeamTransferSimulationService', () {
    test('isTransferWindowOpen respects Aug 1 to Nov 15 boundaries', () {
      expect(
        AiTeamTransferSimulationService.isTransferWindowOpen(
          DateTime(2026, 7, 31),
        ),
        isFalse,
      );
      expect(
        AiTeamTransferSimulationService.isTransferWindowOpen(
          DateTime(2026, 8, 1),
        ),
        isTrue,
      );
      expect(
        AiTeamTransferSimulationService.isTransferWindowOpen(
          DateTime(2026, 10, 12),
        ),
        isTrue,
      );
      expect(
        AiTeamTransferSimulationService.isTransferWindowOpen(
          DateTime(2026, 11, 15),
        ),
        isTrue,
      );
      expect(
        AiTeamTransferSimulationService.isTransferWindowOpen(
          DateTime(2026, 11, 16),
        ),
        isFalse,
      );
    });

    test('evaluateRiderValuation peaks at age 24-28 and scales with W/kg, UCI pts, potential', () {
      final refDate = DateTime(2026, 9, 1);
      final young = _buildTestRider(
        id: 'r_20',
        firstName: 'Jan',
        lastName: 'Młody',
        teamId: 't1',
        age: 20,
        potential: 88,
        uciPoints: 400,
      );
      final prime = _buildTestRider(
        id: 'r_26',
        firstName: 'Piotr',
        lastName: 'Szczyt',
        teamId: 't1',
        age: 26,
        potential: 88,
        uciPoints: 1800,
      );
      final veteran = _buildTestRider(
        id: 'r_35',
        firstName: 'Marek',
        lastName: 'Weteran',
        teamId: 't1',
        age: 35,
        potential: 80,
        uciPoints: 400,
      );

      final vYoung = AiTeamTransferSimulationService.evaluateRiderValuation(
        young,
        referenceDate: refDate,
      );
      final vPrime = AiTeamTransferSimulationService.evaluateRiderValuation(
        prime,
        referenceDate: refDate,
      );
      final vVeteran = AiTeamTransferSimulationService.evaluateRiderValuation(
        veteran,
        referenceDate: refDate,
      );

      expect(vPrime.ageCurveMultiplier, greaterThan(vYoung.ageCurveMultiplier));
      expect(vPrime.ageCurveMultiplier, greaterThan(vVeteran.ageCurveMultiplier));
      expect(vPrime.marketValueEur, greaterThan(vVeteran.marketValueEur));
      expect(vPrime.uciPointsBonusEur, greaterThan(vYoung.uciPointsBonusEur));
    });

    test('TeamRosterNeedsAnalyzer detects position deficits, high avg age, and relegation threat', () {
      final refDate = DateTime(2026, 9, 1);
      final oldSprinter = _buildTestRider(
        id: 'r1',
        firstName: 'Adam',
        lastName: 'Sprint',
        teamId: 'ai_1',
        age: 32,
        specialization: RiderSpecialization.pureSprinter,
        weightKg: 76.0,
        ftpWatts: 380,
        watts5s: 1620,
        contractEndYear: 2028,
      );

      final team = _buildTestTeam(
        id: 'ai_1',
        name: 'Struggling WT Squad',
        uciPointsSeason: 2100,
        rosterRiderIds: ['r1'],
      );

      final report = TeamRosterNeedsAnalyzer.analyzeTeam(
        team: team,
        teamRiders: [oldSprinter],
        currentSeasonYear: 2026,
        referenceDate: refDate,
        relegationStatus: RelegationStatus.relegationThreatened,
      );

      expect(report.isRelegationThreatened, isTrue);
      expect(report.needsYouthInjection, isTrue);
      expect(report.positionDeficits[RosterNeedPosition.gcLeader], 2);
      expect(report.positionDeficits[RosterNeedPosition.classicCobbles], 2);
      expect(report.positionDeficits[RosterNeedPosition.superDomestique], 4);
      expect(report.positionDeficits[RosterNeedPosition.pureSprinter], 1);
      expect(report.urgencyScore, greaterThan(50.0));
    });

    test('simulateMarketDay runs bidding wars including player buyout offers and generates TransferNewsItem', () {
      final playerStar = _buildTestRider(
        id: 'p_star',
        firstName: 'Kacper',
        lastName: 'Lider',
        teamId: 'player_team',
        age: 24,
        potential: 92,
        specialization: RiderSpecialization.gcClimber,
        weightKg: 61.0,
        ftpWatts: 405,
        watts20m: 425,
        uciPoints: 2200,
        contractEndYear: 2028,
        releaseClauseEur: 1200000,
      );

      final freeAgentSprinter = _buildTestRider(
        id: 'fa_sprint',
        firstName: 'Lucas',
        lastName: 'Fast',
        teamId: 'ai_3',
        age: 26,
        potential: 86,
        specialization: RiderSpecialization.pureSprinter,
        weightKg: 75.0,
        ftpWatts: 390,
        watts5s: 1680,
        uciPoints: 1400,
        contractEndYear: 2026,
      );

      final teams = [
        _buildTestTeam(
          id: 'player_team',
          name: 'Polonia Pro Cycling',
          rosterRiderIds: ['p_star'],
        ),
        _buildTestTeam(
          id: 'ai_1',
          name: 'UAE Mega Team',
          cashBalanceEur: 18000000,
          uciPointsSeason: 12000,
        ),
        _buildTestTeam(
          id: 'ai_2',
          name: 'Visma Giants',
          cashBalanceEur: 16000000,
          uciPointsSeason: 11500,
        ),
        _buildTestTeam(
          id: 'ai_3',
          name: 'Midfield Pro',
          division: TeamDivision.proTeam,
          cashBalanceEur: 1500000,
          uciPointsSeason: 1800,
          rosterRiderIds: ['fa_sprint'],
        ),
      ];

      final result = AiTeamTransferSimulationService.simulateMarketDay(
        currentDate: DateTime(2026, 8, 15),
        currentSeasonYear: 2026,
        playerTeamId: 'player_team',
        teams: teams,
        riders: [playerStar, freeAgentSprinter],
        maxEventsPerStep: 4,
        randomSeed: 42,
      );

      expect(result.biddingWars, isNotEmpty);
      expect(result.newsItems, isNotEmpty);
      expect(result.inboxMessages, isNotEmpty);

      for (final item in result.newsItems) {
        expect(item.tickerHeadline, isNotEmpty);
        expect(item.expertComment, isNotEmpty);
        final inbox = item.toInboxMessage();
        expect(inbox.category, InboxCategory.transferMarket);
      }
    });

    test('simulateMarketDay handles in-season contract extensions outside transfer window', () {
      final expiringStar = _buildTestRider(
        id: 'ai_star',
        firstName: 'Mateo',
        lastName: 'Sierra',
        teamId: 'ai_1',
        age: 26,
        potential: 86,
        contractEndYear: 2026,
      );

      final teams = [
        _buildTestTeam(id: 'player_team', name: 'Player Team'),
        _buildTestTeam(
          id: 'ai_1',
          name: 'Movistar AI',
          cashBalanceEur: 6000000,
          rosterRiderIds: ['ai_star'],
        ),
      ];

      final result = AiTeamTransferSimulationService.simulateMarketDay(
        currentDate: DateTime(2026, 5, 10),
        currentSeasonYear: 2026,
        playerTeamId: 'player_team',
        teams: teams,
        riders: [expiringStar],
        randomSeed: 7,
      );

      expect(result.newsItems, isNotEmpty);
      expect(
        result.newsItems.first.newsType,
        TransferNewsType.contractExtension,
      );
      expect(
        result.updatedRiders.first.contract.contractEndYear,
        greaterThan(2026),
      );
    });
  });
}
