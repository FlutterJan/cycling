import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/models/career/season_calendar.dart';
import 'package:pro_peloton_manager/models/career/staff_member.dart';
import 'package:pro_peloton_manager/models/equipment/complete_bike.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/career/agent_contract_clauses_engine.dart';
import 'package:pro_peloton_manager/services/career/ai_team_transfer_simulation_service.dart';
import 'package:pro_peloton_manager/services/career/finance_and_budget_service.dart';
import 'package:pro_peloton_manager/services/career/transfer_market_service.dart';
import 'package:pro_peloton_manager/services/generators/uci_calendar_generator.dart';
import 'package:pro_peloton_manager/services/generators/world_teams_generator.dart';

void main() {
  late WorldTourGenerationResult world;

  setUpAll(() {
    world = WorldTeamsGenerator.generateWorldTourSystem(seed: 20260801);
  });

  CompleteBike buildBike({
    required CompleteBike baseBike,
    required String id,
    required String name,
    required int frameWeightGrams,
    required double stiffnessIndex,
    required int framePriceEur,
    required int wheelWeightGrams,
    required int wheelPriceEur,
  }) {
    return baseBike.copyWith(
      id: id,
      name: name,
      frame: baseBike.frame.copyWith(
        id: '${id}_frame',
        name: '$name Frame',
        weightGrams: frameWeightGrams,
        stiffnessToWeightIndex: stiffnessIndex,
        priceEur: framePriceEur,
      ),
      wheelset: baseBike.wheelset.copyWith(
        id: '${id}_wheel',
        name: '$name Wheels',
        weightGrams: wheelWeightGrams,
        priceEur: wheelPriceEur,
      ),
    );
  }

  CareerSave buildTestSave({
    required DateTime currentDate,
    required List<CyclingTeam> teams,
    required List<Rider> riders,
    required String playerTeamId,
    int currentSeasonYear = 2026,
  }) {
    final calendar = SeasonCalendar(
      seasonYear: currentSeasonYear,
      races: UciCalendarGenerator.generateFullSeasonCalendar(
        seasonYear: currentSeasonYear,
      ),
    );
    return CareerSave(
      id: 'test_transfer_save',
      saveName: 'Transfer & Clauses Test',
      difficulty: CareerDifficulty.normal,
      playerManagerName: 'Tester',
      playerTeamId: playerTeamId,
      currentDate: currentDate,
      currentSeasonYear: currentSeasonYear,
      teams: teams,
      riders: riders,
      calendar: calendar,
      createdAt: currentDate,
      lastSavedAt: currentDate,
    );
  }

  group('1. Licytacje drużyn AI (AiTeamTransferSimulationService)', () {
    test('okno transferowe jest otwarte wyłącznie od 1 sierpnia do 15 listopada', () {
      expect(
        AiTeamTransferSimulationService.isTransferWindowOpen(DateTime(2026, 7, 31)),
        isFalse,
      );
      expect(
        AiTeamTransferSimulationService.isTransferWindowOpen(DateTime(2026, 8, 1)),
        isTrue,
      );
      expect(
        AiTeamTransferSimulationService.isTransferWindowOpen(DateTime(2026, 11, 15)),
        isTrue,
      );
      expect(
        AiTeamTransferSimulationService.isTransferWindowOpen(DateTime(2026, 11, 16)),
        isFalse,
      );
    });

    test('bogate drużyny WorldTour AI prowadzą licytację o topowego wolnego agenta', () {
      final wtTeams = world.worldTourTeams;
      expect(wtTeams.length, greaterThanOrEqualTo(4));

      final playerTeamId = wtTeams.first.id;
      final sellerTeam = wtTeams[1];
      final bidderA = wtTeams[2];
      final bidderB = wtTeams[3];

      // Zapewniamy dwóm rywalom AI wysokie budżety transferowe i brak pełnego składu
      final updatedTeams = world.teams.map((t) {
        if (t.id == bidderA.id || t.id == bidderB.id) {
          return t.copyWith(
            cashBalanceEur: 9500000,
            uciPointsSeason: 4200,
            rosterRiderIds: t.rosterRiderIds.take(18).toList(),
          );
        }
        return t;
      }).toList();

      // Wybieramy gwiazdę z zespołu sellerTeam i ustawiamy wygasający kontrakt
      final starRider = world.ridersByTeamId[sellerTeam.id]!
          .reduce((a, b) => a.overallRating >= b.overallRating ? a : b);
      final expiringStar = starRider.copyWith(
        contract: starRider.contract.copyWith(
          contractEndYear: 2026,
          monthlySalaryEur: 35000,
          releaseClauseEur: 0,
        ),
        careerPointsUci: math.max(1200, starRider.careerPointsUci),
      );

      final updatedRiders = world.allRiders
          .where((r) => r.teamId != bidderA.id && r.teamId != bidderB.id)
          .map((r) => r.id == expiringStar.id ? expiringStar : r)
          .toList();
      // Zostawiamy po 18 kolarzy w bidderA i bidderB, aby mieli zapotrzebowanie
      for (final bId in [bidderA.id, bidderB.id]) {
        final keepIds = updatedTeams
            .firstWhere((t) => t.id == bId)
            .rosterRiderIds
            .toSet();
        updatedRiders.addAll(
          world.ridersByTeamId[bId]!.where((r) => keepIds.contains(r.id)),
        );
      }

      final result = AiTeamTransferSimulationService.simulateMarketDay(
        currentDate: DateTime(2026, 8, 15),
        currentSeasonYear: 2026,
        playerTeamId: playerTeamId,
        teams: updatedTeams,
        riders: updatedRiders,
        maxEventsPerStep: 8,
        randomSeed: 42,
      );

      expect(result.biddingWars, isNotEmpty);
      for (final war in result.biddingWars) {
        expect(war.competingOffers.length, greaterThanOrEqualTo(2));
        for (int i = 1; i < war.competingOffers.length; i++) {
          expect(
            war.competingOffers[i - 1].bidScore,
            greaterThanOrEqualTo(war.competingOffers[i].bidScore),
          );
        }

        final winningTeam =
            result.updatedTeams.firstWhere((t) => t.id == war.winningTeamId);
        expect(winningTeam.rosterRiderIds, contains(war.riderId));
        expect(winningTeam.cashBalanceEur, greaterThanOrEqualTo(0));

        final signedRider =
            result.updatedRiders.firstWhere((r) => r.id == war.riderId);
        expect(signedRider.teamId, equals(war.winningTeamId));
        expect(signedRider.contract.contractEndYear, greaterThan(2026));
      }
    });

    test('licytacja z klauzulą wykupu przekazuje opłatę sprzedającemu klubowi AI i chroni gracza przed cichym wykupem', () {
      final wtTeams = world.worldTourTeams;
      final playerTeam = wtTeams[0];
      final aiSeller = wtTeams[1];
      final bidderA = wtTeams[2];
      final bidderB = wtTeams[3];

      // Tworzymy kolarza AI oraz kolarza gracza z niską klauzulą wykupu
      final aiStarBase = world.ridersByTeamId[aiSeller.id]!.first;
      final aiStarWithClause = aiStarBase.copyWith(
        careerPointsUci: 1800,
        contract: aiStarBase.contract.copyWith(
          contractEndYear: 2028,
          releaseClauseEur: 450000,
          monthlySalaryEur: 25000,
        ),
      );

      final playerStarBase = world.ridersByTeamId[playerTeam.id]!.first;
      final playerStarWithClause = playerStarBase.copyWith(
        careerPointsUci: 2200,
        contract: playerStarBase.contract.copyWith(
          contractEndYear: 2028,
          releaseClauseEur: 400000,
          monthlySalaryEur: 25000,
        ),
      );

      const initialSellerCash = 1000000;
      final teams = [
        playerTeam.copyWith(cashBalanceEur: 3000000),
        aiSeller.copyWith(cashBalanceEur: initialSellerCash),
        bidderA.copyWith(cashBalanceEur: 12000000, uciPointsSeason: 5000),
        bidderB.copyWith(cashBalanceEur: 12000000, uciPointsSeason: 4800),
      ];

      // Ograniczamy pulę kandydatów, aby licytacja dotyczyła dokładnie tych dwóch gwiazd
      final riders = [
        playerStarWithClause,
        aiStarWithClause,
        ...world.ridersByTeamId[bidderA.id]!.take(10).map(
              (r) => r.copyWith(
                contract: r.contract.copyWith(
                  contractEndYear: 2029,
                  releaseClauseEur: 0,
                ),
                careerPointsUci: 100,
              ),
            ),
        ...world.ridersByTeamId[bidderB.id]!.take(10).map(
              (r) => r.copyWith(
                contract: r.contract.copyWith(
                  contractEndYear: 2029,
                  releaseClauseEur: 0,
                ),
                careerPointsUci: 100,
              ),
            ),
      ];

      final result = AiTeamTransferSimulationService.simulateMarketDay(
        currentDate: DateTime(2026, 8, 20),
        currentSeasonYear: 2026,
        playerTeamId: playerTeam.id,
        teams: teams,
        riders: riders,
        maxEventsPerStep: 6,
        autoExecutePlayerBuyouts: false,
        randomSeed: 7,
      );

      // Sprawdzamy, że wykup gracza trafił do playerBuyoutOffers, ale nie zabrał kolarza po cichu
      final playerOffers = result.playerBuyoutOffers;
      if (playerOffers.isNotEmpty) {
        expect(playerOffers.first.isReleaseClauseBuyout, isTrue);
        expect(playerOffers.first.targetsPlayerTeam, isTrue);
        final playerRosterAfter = result.updatedTeams
            .firstWhere((t) => t.id == playerTeam.id)
            .rosterRiderIds;
        expect(playerRosterAfter, contains(playerStarWithClause.id));
        expect(
          result.newsItems.any(
            (n) => n.newsType == TransferNewsType.playerRiderBuyoutOffer,
          ),
          isTrue,
        );
      }

      // Sprawdzamy wykup kolarza AI (jeśli został wylosowany w puli)
      final aiBuyoutWars = result.biddingWars
          .where((w) => !w.targetsPlayerTeam && w.isReleaseClauseBuyout)
          .toList();
      if (aiBuyoutWars.isNotEmpty) {
        final war = aiBuyoutWars.first;
        final sellerAfter =
            result.updatedTeams.firstWhere((t) => t.id == aiSeller.id);
        expect(
          sellerAfter.cashBalanceEur,
          equals(initialSellerCash + war.winningOffer.offeredBuyoutFeeEur),
        );
        expect(sellerAfter.rosterRiderIds, isNot(contains(war.riderId)));
      }

      for (final team in result.updatedTeams) {
        expect(team.cashBalanceEur, greaterThanOrEqualTo(0));
      }
    });
  });

  group('2. Działanie klauzul kontraktowych (AgentContractClausesEngine & TransferMarketService)', () {
    const engine = AgentContractClausesEngine();

    test('rabat płacowy za aktywne klauzule ma limit 28% i podłogę 2500 EUR', () {
      final allFourClauses = [
        AgentContractClause.guaranteedGrandTourLeadership(),
        AgentContractClause.equipmentVeto(),
        AgentContractClause.personalSoigneurOrCoach(),
        AgentContractClause.relegationFreeRelease(),
      ];

      final discounted = engine.calculateNegotiatedSalaryWithClauses(
        baseSalaryDemandEur: 10000,
        activeClauses: allFourClauses,
      );
      // Suma rabatów 0.09 + 0.05 + 0.06 + 0.08 = 0.28 -> 7200 EUR
      expect(discounted, equals(7200));

      final floored = engine.calculateNegotiatedSalaryWithClauses(
        baseSalaryDemandEur: 3000,
        activeClauses: allFourClauses,
      );
      expect(floored, equals(2500));
    });

    test('Guaranteed Grand Tour Leadership: compliant, warning i breached z karą morale/lojalności', () {
      final team = world.worldTourTeams.first;
      final rider = world.ridersByTeamId[team.id]!.first.copyWith(
        contract: world.ridersByTeamId[team.id]!.first.contract.copyWith(
          morale: 80.0,
          leaderLoyalty: 80.0,
        ),
      );
      final bundle = RiderContractClausesBundle(
        riderId: rider.id,
        clauses: [
          AgentContractClause.guaranteedGrandTourLeadership(
            targetGrandTour: GrandTourTarget.tourDeFrance,
          ),
        ],
      );

      // 1. Spełniona (jeden lider na TDF)
      final compliantReport = engine.evaluateClauses(
        bundle,
        ClauseEvaluationContext(
          rider: rider,
          team: team,
          assignedGrandTourLeaderIds: {
            GrandTourTarget.tourDeFrance: [rider.id],
          },
        ),
      );
      expect(compliantReport.hasAnyBreach, isFalse);
      expect(
        compliantReport.results.single.status,
        equals(ClauseComplianceStatus.compliant),
      );

      // 2. Ostrzeżenie (rozmyte przywództwo >2 liderów)
      final warningReport = engine.evaluateClauses(
        bundle,
        ClauseEvaluationContext(
          rider: rider,
          team: team,
          assignedGrandTourLeaderIds: {
            GrandTourTarget.tourDeFrance: [rider.id, 'r2', 'r3'],
          },
        ),
      );
      expect(warningReport.hasAnyBreach, isFalse);
      expect(
        warningReport.results.single.status,
        equals(ClauseComplianceStatus.warning),
      );

      // 3. Naruszenie (kolarz pominięty w składzie liderów TDF)
      final breachedReport = engine.evaluateClauses(
        bundle,
        ClauseEvaluationContext(
          rider: rider,
          team: team,
          assignedGrandTourLeaderIds: const {
            GrandTourTarget.tourDeFrance: ['other_leader'],
          },
        ),
      );
      expect(breachedReport.hasAnyBreach, isTrue);
      expect(
        breachedReport.results.single.status,
        equals(ClauseComplianceStatus.breached),
      );
      expect(breachedReport.totalMoraleDelta, lessThan(0));
      expect(breachedReport.totalLoyaltyDelta, lessThan(0));
      expect(
        breachedReport.updatedContract.morale,
        lessThan(rider.contract.morale),
      );
      expect(
        breachedReport.updatedContract.leaderLoyalty,
        lessThan(rider.contract.leaderLoyalty),
      );
    });

    test('Equipment Veto blokuje za słaby/ciężki rower i akceptuje zestaw WorldTour Pro', () {
      final team = world.worldTourTeams.first;
      final rider = world.ridersByTeamId[team.id]!.first;
      final bundle = RiderContractClausesBundle(
        riderId: rider.id,
        clauses: [
          AgentContractClause.equipmentVeto(
            minimumFrameStiffnessIndex: 1.85,
            maximumFrameWeightGrams: 800,
            maximumWheelsetWeightGrams: 1350,
            minimumEquipmentTierPriceEur: 11000,
          ),
        ],
      );

      final baseBike = team.inventoryBikes.first;
      final weakBike = buildBike(
        baseBike: baseBike,
        id: 'bike_weak',
        name: 'Heavy Alloy',
        frameWeightGrams: 1050,
        stiffnessIndex: 1.45,
        framePriceEur: 3200,
        wheelWeightGrams: 1650,
        wheelPriceEur: 1800,
      );
      final proBike = buildBike(
        baseBike: baseBike,
        id: 'bike_pro',
        name: 'VeloLab SL9',
        frameWeightGrams: 740,
        stiffnessIndex: 1.95,
        framePriceEur: 6800,
        wheelWeightGrams: 1280,
        wheelPriceEur: 5200,
      );

      final breachReport = engine.evaluateClauses(
        bundle,
        ClauseEvaluationContext(
          rider: rider,
          team: team,
          assignedBike: weakBike,
        ),
      );
      expect(breachReport.hasAnyBreach, isTrue);
      expect(breachReport.hasEquipmentVetoBlock, isTrue);
      expect(breachReport.results.single.allowsEquipmentVetoSwap, isTrue);

      final okReport = engine.evaluateClauses(
        bundle,
        ClauseEvaluationContext(
          rider: rider,
          team: team,
          assignedBike: proBike,
        ),
      );
      expect(okReport.hasAnyBreach, isFalse);
      expect(okReport.hasEquipmentVetoBlock, isFalse);
      expect(okReport.results.single.status, equals(ClauseComplianceStatus.compliant));
    });

    test('Personal Soigneur/Coach i Relegation Free Release aktywują się poprawnie', () {
      final team = world.worldTourTeams.first;
      final rider = world.ridersByTeamId[team.id]!.first.copyWith(
        contract: world.ridersByTeamId[team.id]!.first.contract.copyWith(
          releaseClauseEur: 1500000,
          morale: 85.0,
          leaderLoyalty: 85.0,
        ),
      );

      const preferredCoach = PerformanceCoach(
        id: 'coach_vip_1',
        firstName: 'Jan',
        lastName: 'Kowalski',
        nationalityIso: 'POL',
        age: 44,
        experienceLevel: 92,
        monthlySalaryEur: 8500,
        contractEndYear: 2028,
        reputation: 90,
        ftpDevelopmentEfficiency: 92,
        sprintAndNeuromuscularFocus: 80,
        winterGymPeriodizationSkill: 85,
        overtrainingPrevention: 88,
      );

      final bundle = RiderContractClausesBundle(
        riderId: rider.id,
        clauses: [
          AgentContractClause.personalSoigneurOrCoach(
            preferredCoachId: preferredCoach.id,
            preferredCoachName: preferredCoach.fullName,
            minimumCoachExperienceLevel: 85,
          ),
          AgentContractClause.relegationFreeRelease(),
        ],
      );

      // W WorldTour z ulubionym trenerem -> wszystko spełnione
      final safeReport = engine.evaluateClauses(
        bundle,
        ClauseEvaluationContext(
          rider: rider,
          team: team,
          teamStaffMembers: const [preferredCoach],
          wasRelegatedFromWorldTour: false,
        ),
      );
      expect(safeReport.isFreeAgentReleaseTriggered, isFalse);
      expect(safeReport.hasAnyBreach, isFalse);
      expect(safeReport.updatedContract.releaseClauseEur, equals(1500000));

      // Po spadku z WorldTour -> Relegation Free Release zeruje klauzulę odstępnego (0 EUR)
      final relegatedTeam = team.copyWith(division: TeamDivision.proTeam);
      final relegatedReport = engine.evaluateClauses(
        bundle,
        ClauseEvaluationContext(
          rider: rider,
          team: relegatedTeam,
          teamStaffMembers: const [preferredCoach],
          previousDivision: TeamDivision.worldTour,
          wasRelegatedFromWorldTour: true,
        ),
      );
      expect(relegatedReport.isFreeAgentReleaseTriggered, isTrue);
      expect(relegatedReport.updatedContract.releaseClauseEur, equals(0));
      expect(
        relegatedReport.results
            .firstWhere(
              (r) => r.clause.type == AgentContractClauseType.relegationFreeRelease,
            )
            .status,
        equals(ClauseComplianceStatus.triggered),
      );
    });

    test('TransferMarketService wykrywa konflikt lidera GT i ocenia ofertę kontraktową', () {
      final team = world.worldTourTeams.first.copyWith(cashBalanceEur: 6000000);
      final existingRoster = world.ridersByTeamId[team.id]!;
      final existingLeader = existingRoster.first.copyWith(
        contract: existingRoster.first.contract.copyWith(
          role: RiderRole.teamLeader,
        ),
      );
      final otherTeamRider = world.ridersByTeamId[world.worldTourTeams[1].id]!.first;

      final conflict = TransferMarketService.checkGrandTourLeaderConflict(
        candidateRider: otherTeamRider,
        offeringTeam: team,
        proposedRole: RiderRole.teamLeader,
        teamRoster: [existingLeader, ...existingRoster.skip(1)],
      );
      expect(conflict.hasConflict, isTrue);
      expect(conflict.conflictingLeaderName, equals(existingLeader.fullName));
      expect(conflict.penalty, greaterThan(0));

      final fairMarket = TransferMarketService.calculateMarketValue(otherTeamRider);
      final lowballResult = TransferMarketService.evaluateOffer(
        candidateRider: otherTeamRider,
        offeringTeam: team,
        teamRoster: existingRoster,
        annualSalaryEur: (fairMarket * 0.25).round(),
        proposedRole: RiderRole.domestique,
        contractDurationYears: 1,
        winBonusEur: 0,
        currentDate: DateTime(2026, 8, 10),
      );
      expect(lowballResult.isAccepted, isFalse);
    });
  });

  group('3. Budżet płacowy i raporty finansowe (FinanceAndBudgetService & TeamRosterNeedsAnalyzer)', () {
    test('kalkulacja miesięcznego budżetu płacowego kolarzy i sztabu oraz raport przepływów', () {
      final team = world.worldTourTeams.first.copyWith(cashBalanceEur: 4500000);
      final roster = world.ridersByTeamId[team.id]!;

      final riderSalaries = FinanceAndBudgetService.calculateRiderMonthlySalaries(roster);
      final staffSalaries = FinanceAndBudgetService.calculateStaffMonthlySalaries(team.staff);
      final expectedRiderSum = roster.fold<int>(
        0,
        (sum, r) => sum + r.contract.monthlySalaryEur,
      );

      expect(riderSalaries, equals(expectedRiderSum));
      expect(riderSalaries, greaterThan(0));
      expect(staffSalaries, greaterThan(0));

      final save = buildTestSave(
        currentDate: DateTime(2026, 5, 1),
        teams: world.teams.map((t) => t.id == team.id ? team : t).toList(),
        riders: world.allRiders,
        playerTeamId: team.id,
      );

      final report = FinanceAndBudgetService.generateMonthlyCashflowReport(
        save: save,
        targetYear: 2026,
        targetMonth: 5,
      );

      expect(report.riderSalariesEur, equals(riderSalaries));
      expect(report.staffSalariesEur, equals(staffSalaries));
      expect(
        report.totalIncomeEur,
        equals(
          report.sponsorPayoutEur +
              report.bikeManufacturerCashEur +
              report.prizeMoneyClubShareEur +
              report.prizeMoneyRidersShareEur +
              report.riderBuyoutIncomeEur +
              report.otherIncomeEur,
        ),
      );
      expect(
        report.totalExpensesEur,
        equals(
          report.riderSalariesEur +
              report.staffSalariesEur +
              report.raceLogisticsEur +
              report.trainingCampsEur +
              report.physiologicalTestingEur +
              report.equipmentServiceAndPurchasesEur +
              report.facilitiesMaintenanceEur,
        ),
      );
      expect(
        report.netCashflowEur,
        equals(report.totalIncomeEur - report.totalExpensesEur),
      );
    });

    test('TeamRosterNeedsAnalyzer wylicza dostępny budżet transferowy i blokuje biedne kluby AI', () {
      final wtTeam = world.worldTourTeams[1];
      final roster = world.ridersByTeamId[wtTeam.id]!;

      final richReport = TeamRosterNeedsAnalyzer.analyzeTeam(
        team: wtTeam.copyWith(cashBalanceEur: 5000000),
        teamRiders: roster,
        currentSeasonYear: 2026,
        referenceDate: DateTime(2026, 8, 15),
      );
      final brokeReport = TeamRosterNeedsAnalyzer.analyzeTeam(
        team: wtTeam.copyWith(
          cashBalanceEur: 0,
          sponsors: const [],
        ),
        teamRiders: roster,
        currentSeasonYear: 2026,
        referenceDate: DateTime(2026, 8, 15),
      );

      expect(richReport.availableTransferBudgetEur, greaterThan(900000));
      expect(
        richReport.availableTransferBudgetEur,
        greaterThan(brokeReport.availableTransferBudgetEur),
      );
      expect(brokeReport.availableTransferBudgetEur, greaterThanOrEqualTo(350000));
      expect(brokeReport.availableTransferBudgetEur, lessThan(900000));
    });
  });

  group('4. Brak ujemnych sald w klubach AI podczas symulacji rynku', () {
    test('wielodniowa symulacja rynku transferowego AI nigdy nie generuje ujemnego salda cashBalanceEur', () {
      final playerTeamId = world.worldTourTeams.first.id;

      // Celowo ustawiamy części klubów AI niskie lub zerowe salda obok bogatych klubów
      var currentTeams = <CyclingTeam>[];
      for (int i = 0; i < world.teams.length; i++) {
        final t = world.teams[i];
        if (t.id == playerTeamId) {
          currentTeams.add(t);
        } else if (i % 4 == 0) {
          currentTeams.add(t.copyWith(cashBalanceEur: 0));
        } else if (i % 4 == 1) {
          currentTeams.add(t.copyWith(cashBalanceEur: 45000));
        } else {
          currentTeams.add(t);
        }
      }

      // Części kolarzy AI ustawiamy wygasające kontrakty i klauzule wykupu
      var currentRiders = world.allRiders.asMap().entries.map((entry) {
        final idx = entry.key;
        final r = entry.value;
        if (r.teamId == playerTeamId) return r;
        if (idx % 3 == 0) {
          return r.copyWith(
            contract: r.contract.copyWith(contractEndYear: 2026),
          );
        }
        return r;
      }).toList();

      // Symulujemy 30 dni w oknie transferowym (sierpień–wrzesień)
      for (int day = 0; day < 30; day++) {
        final date = DateTime(2026, 8, 1).add(Duration(days: day));
        final simResult = AiTeamTransferSimulationService.simulateMarketDay(
          currentDate: date,
          currentSeasonYear: 2026,
          playerTeamId: playerTeamId,
          teams: currentTeams,
          riders: currentRiders,
          maxEventsPerStep: 6,
          autoExecutePlayerBuyouts: false,
          randomSeed: 20260801 + day,
        );

        currentTeams = simResult.updatedTeams;
        currentRiders = simResult.updatedRiders;

        for (final team in currentTeams) {
          if (team.id == playerTeamId) continue;
          expect(
            team.cashBalanceEur,
            greaterThanOrEqualTo(0),
            reason:
                'Klub AI ${team.name} (${team.id}) osiągnął ujemne saldo ${team.cashBalanceEur} EUR w dniu ${date.toIso8601String()}',
          );
          expect(
            team.rosterRiderIds.toSet().length,
            equals(team.rosterRiderIds.length),
            reason: 'Duplikat ID kolarza w składzie ${team.name}',
          );
        }
      }
    });

    test('TransferMarketService.simulateAiTransferMarket pomija ubogie kluby AI i zachowuje salda >= 0', () {
      final playerTeamId = world.worldTourTeams.first.id;
      final teamsWithPoorAi = world.teams.map((t) {
        if (t.id == playerTeamId) return t;
        return t.copyWith(cashBalanceEur: 5000);
      }).toList();

      final ridersWithExpiring = world.allRiders.map((r) {
        if (r.teamId == playerTeamId) return r;
        return r.copyWith(
          contract: r.contract.copyWith(contractEndYear: 2026),
        );
      }).toList();

      final initialSave = buildTestSave(
        currentDate: DateTime(2026, 9, 1),
        teams: teamsWithPoorAi,
        riders: ridersWithExpiring,
        playerTeamId: playerTeamId,
      );

      final afterSave = TransferMarketService.simulateAiTransferMarket(
        currentSave: initialSave,
        maxAiTransfersPerWeek: 10,
        random: math.Random(99),
      );

      for (final team in afterSave.teams) {
        if (team.id == playerTeamId) continue;
        expect(team.cashBalanceEur, greaterThanOrEqualTo(0));
      }
    });
  });
}
