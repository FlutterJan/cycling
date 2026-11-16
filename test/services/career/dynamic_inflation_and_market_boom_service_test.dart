import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/models/team/sponsor_contract.dart';
import 'package:pro_peloton_manager/services/career/dynamic_inflation_and_market_boom_service.dart';

CyclingTeam _buildTestTeam({
  required String id,
  required String name,
  TeamDivision division = TeamDivision.worldTour,
  int sponsorBudgetEur = 22000000,
  int monthlyBurnEur = 1750000,
}) {
  return CyclingTeam(
    id: id,
    name: name,
    division: division,
    countryIso: 'PL',
    primaryJerseyColorHex: '#8E4A49',
    secondaryJerseyColorHex: '#181B22',
    accentJerseyColorHex: '#D4AF37',
    cashBalanceEur: 5000000,
    monthlyBurnRateEur: monthlyBurnEur,
    uciPointsSeason: 4200,
    rosterRiderIds: const ['r1', 'r2'],
    staff: const TeamStaff(
      trainersLevel: 82,
      sportsDirectorsLevel: 85,
      doctorsLevel: 80,
      mechanicsLevel: 84,
      scoutsLevel: 79,
    ),
    bikeDeal: const BikeManufacturerDeal(
      manufacturerId: 'velox_carbon',
      manufacturerName: 'Velox Carbon',
      prestigeLevel: 4,
      annualCashContributionEur: 1500000,
      freeBikesQuota: 80,
      researchAndDevelopmentLevel: 85,
      suppliedFrameIds: ['f1'],
      suppliedWheelsetIds: ['w1'],
      contractYearsLeft: 3,
      minimumUciRankingRequired: 15,
    ),
    sponsors: [
      SponsorContract(
        id: 'sp_$id',
        companyName: '$name Main Sponsor',
        industry: SponsorIndustry.finance,
        sponsorTier: SponsorTier.titlePrimary,
        annualBudgetEur: sponsorBudgetEur,
        contractDurationYears: 3,
        sponsorSatisfaction: 78.0,
        objectives: const [],
      ),
    ],
    inventoryBikes: const [],
  );
}

void main() {
  const service = DynamicInflationAndMarketBoomService();

  group('DynamicInflationAndMarketBoomService', () {
    test('simulateMultiYearTrajectory covers 2026-2040 and grows WorldTour budgets', () {
      final trajectory = service.simulateMultiYearTrajectory(seed: 42);

      expect(trajectory.length, equals(15));
      expect(trajectory.first.seasonYear, equals(2026));
      expect(trajectory.last.seasonYear, equals(2040));

      final y2026 = trajectory.first;
      final y2033 = trajectory.firstWhere((s) => s.seasonYear == 2033);
      final y2040 = trajectory.last;

      expect(y2026.worldTourAverageBudgetEur, equals(24000000));
      expect(y2033.worldTourAverageBudgetEur, greaterThan(y2026.worldTourAverageBudgetEur));
      expect(y2040.worldTourAverageBudgetEur, greaterThan(y2033.worldTourAverageBudgetEur));
      expect(y2040.worldTourAverageBudgetEur, greaterThan(45000000));

      expect(y2040.salaryInflationMultiplier, greaterThan(y2026.salaryInflationMultiplier));
      expect(
        y2040.transferFeeInflationMultiplier,
        greaterThan(y2040.cumulativeInflationMultiplier),
      );

      final allEntrants = trajectory.expand((s) => s.newEntrantsThisSeason).toList();
      expect(allEntrants.length, greaterThanOrEqualTo(6));
      expect(
        allEntrants.any((e) => e.archetype == MegaSponsorArchetype.sovereignWealthFund),
        isTrue,
      );
      expect(
        allEntrants.any((e) => e.archetype == MegaSponsorArchetype.globalAiCloudConsortium),
        isTrue,
      );
    });

    test('SeasonMacroEconomySnapshot serializes and deserializes cleanly', () {
      final trajectory = service.simulateMultiYearTrajectory(seed: 99);
      final target = trajectory.firstWhere((s) => s.seasonYear == 2035);

      final json = target.toJson();
      final restored = SeasonMacroEconomySnapshot.fromJson(json);

      expect(restored.seasonYear, equals(target.seasonYear));
      expect(restored.cyclePhase, equals(target.cyclePhase));
      expect(
        restored.worldTourAverageBudgetEur,
        equals(target.worldTourAverageBudgetEur),
      );
      expect(
        restored.activeMegaSponsors.length,
        equals(target.activeMegaSponsors.length),
      );
    });

    test('applyEconomyToTeams updates team budgets and awards mega-sponsor to AI team', () {
      final trajectory = service.simulateMultiYearTrajectory(seed: 12);
      final snapshot2027 = trajectory.firstWhere((s) => s.seasonYear == 2027);

      final playerTeam = _buildTestTeam(
        id: 'player_wt',
        name: 'Polska Pro Cycling',
        sponsorBudgetEur: 20000000,
      );
      final aiTeam = _buildTestTeam(
        id: 'ai_wt',
        name: 'Team Horizon',
        sponsorBudgetEur: 24000000,
      );

      final results = service.applyEconomyToTeams(
        teams: [playerTeam, aiTeam],
        snapshot: snapshot2027,
        playerTeamId: playerTeam.id,
      );

      expect(results.length, equals(2));
      final playerRes = results.firstWhere((r) => r.updatedTeam.id == playerTeam.id);
      final aiRes = results.firstWhere((r) => r.updatedTeam.id == aiTeam.id);

      expect(playerRes.awardedMegaSponsor, isNull);
      expect(playerRes.newAnnualIncomeEur, greaterThan(playerRes.previousAnnualIncomeEur));
      expect(aiRes.awardedMegaSponsor, isNotNull);
      expect(aiRes.newAnnualIncomeEur, greaterThan(aiRes.previousAnnualIncomeEur));
      expect(
        service.applyEconomyToTeams(teams: const [], snapshot: snapshot2027),
        isEmpty,
      );
    });

    test('scaleAmountForYear and evaluatePlayerCompetitiveness compute valid outputs', () {
      final trajectory = service.simulateMultiYearTrajectory(seed: 7);
      final snapshot2039 = trajectory.firstWhere((s) => s.seasonYear == 2039);

      final scaledSalary = service.scaleAmountForYear(
        baseAmount2026Eur: 1000000,
        seasonYear: 2039,
        isSalary: true,
      );
      final scaledTransfer = service.scaleAmountForYear(
        baseAmount2026Eur: 1000000,
        seasonYear: 2039,
        isTransferFee: true,
      );

      expect(scaledSalary, greaterThan(1500000));
      expect(scaledTransfer, greaterThan(scaledSalary));
      expect(
        service.scaleAmountForYear(baseAmount2026Eur: 0, seasonYear: 2035),
        equals(0),
      );

      final playerTeam = _buildTestTeam(
        id: 'p1',
        name: 'Vistula WorldTour',
        sponsorBudgetEur: 22000000,
      );
      final report = service.evaluatePlayerCompetitiveness(
        playerTeam: playerTeam,
        snapshot: snapshot2039,
      );

      expect(report.isAboveDivisionAverage, isFalse);
      expect(report.gapToAverageEur, lessThan(0));
      expect(report.estimatedBudgetPercentile, inInclusiveRange(4, 99));
      expect(report.strategicRecommendation, isNotEmpty);
    });
  });

  group('DynamicInflationMarketBoomPanel responsive UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          int? lastSelectedYear;
          final playerTeam = _buildTestTeam(
            id: 'player_ui',
            name: 'Vistula Racing',
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                backgroundColor: const Color(0xFF0F1115),
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: DynamicInflationMarketBoomPanel(
                      initialSelectedYear: 2028,
                      playerTeam: playerTeam,
                      onYearSelected: (snap) => lastSelectedYear = snap.seasonYear,
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));

          expect(
            find.text('Ekonomia Świata Kolarstwa (2026–2040)'),
            findsOneWidget,
          );
          expect(find.text('2035'), findsOneWidget);

          await tester.ensureVisible(find.text('2035'));
          await tester.tap(find.text('2035'));
          await tester.pump(const Duration(milliseconds: 300));

          expect(lastSelectedYear, equals(2035));
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
