import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_results_calculator.dart';
import 'package:pro_peloton_manager/models/career/team_esg_sustainability_and_green_fleet_model.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/services/analysis/post_race_ai_tactical_coach_analyzer.dart';
import 'package:pro_peloton_manager/ui/widgets/post_race_ai_coach_insights_card.dart';

List<PostRaceTelemetrySample> _buildShelteredOptimalSamples() {
  final List<PostRaceTelemetrySample> samples = <PostRaceTelemetrySample>[];
  for (int i = 0; i < 60; i++) {
    final bool isAttack = i >= 45 && i <= 50;
    samples.add(
      PostRaceTelemetrySample(
        timestampSeconds: i * 10.0,
        distanceMeters: 150000.0 + i * 120.0,
        speedMs: isAttack ? 14.5 : 12.2,
        powerWatts: isAttack ? 560 : 285,
        heartRateBpm: isAttack ? 182 : 148,
        gradientPercent: isAttack ? 6.5 : 1.0,
        wPrimeJoules: isAttack ? 21000.0 - (i - 45) * 1800.0 : 21000.0,
        wPrimeRatio: isAttack ? (1.0 - (i - 45) * 0.09).clamp(0.25, 1.0) : 0.95,
        isDrafting: !isAttack,
        draftingSavingsPercent: isAttack ? 0.0 : 35.0,
        windSpeedKmh: 18.0,
        windAngleDegrees: isAttack ? 170.0 : 15.0,
        isEchelonZone: false,
        isInGutter: false,
        isAttacking: isAttack,
        isPlannedPull: false,
      ),
    );
  }
  return samples;
}

List<PostRaceTelemetrySample> _buildWindExposedBlowupSamples() {
  final List<PostRaceTelemetrySample> samples = <PostRaceTelemetrySample>[];
  for (int i = 0; i < 60; i++) {
    final bool isExposed = i >= 10 && i <= 32;
    final bool isBlowupAttack = i >= 38 && i <= 45;
    samples.add(
      PostRaceTelemetrySample(
        timestampSeconds: i * 10.0,
        distanceMeters: 120000.0 + i * 115.0,
        speedMs: isBlowupAttack ? 10.2 : 11.8,
        powerWatts: isBlowupAttack ? 510 : (isExposed ? 415 : 290),
        heartRateBpm: isBlowupAttack ? 191 : 165,
        gradientPercent: 0.5,
        wPrimeJoules: isBlowupAttack ? 500.0 : 6000.0,
        wPrimeRatio: isBlowupAttack ? 0.02 : (i >= 35 ? 0.25 : 0.65),
        isDrafting: !isExposed && !isBlowupAttack,
        draftingSavingsPercent: isExposed ? 4.0 : 30.0,
        windSpeedKmh: 40.0,
        windAngleDegrees: isBlowupAttack ? 5.0 : 75.0,
        isEchelonZone: isExposed,
        isInGutter: isExposed && i <= 24,
        isAttacking: isBlowupAttack,
        isPlannedPull: false,
      ),
    );
  }
  return samples;
}

void main() {
  group('ESG CO2 Balance & Green Fleet Model', () {
    test('starter WorldTour computes baseline CO2 balance, electrification and sponsor revenue', () {
      final model = TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
        teamId: 'team_wt_1',
      );
      final overview = model.computeOverview();

      expect(overview.totalEmissionsKg, closeTo(6200.0, 0.01));
      expect(overview.totalOffsetsKg, closeTo(10000.0, 0.01));
      expect(overview.netCarbonBalanceKg, closeTo(-3800.0, 0.01));
      expect(overview.isCarbonNeutral, isTrue);
      expect(overview.fleetElectrificationRatio, closeTo((1.0 + 0.65 + 0.0 + 1.0) / 4.0, 0.001));
      expect(overview.allRaceCarsZeroEmission, isFalse);
      expect(overview.activeGreenSponsorsCount, 1);
      expect(overview.projectedGreenSponsorRevenueEur, greaterThanOrEqualTo(450000.0));
      expect(overview.esgScore, greaterThanOrEqualTo(60.0));
      expect(overview.uciCharterCompliant, isTrue);
    });

    test('railOverFlightPolicy converts short-haul flight <= 700 km to high-speed rail', () {
      final base = TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
        teamId: 'team_wt_rail',
      );
      final withPolicy = base.recordTeamTravel(
        description: 'Bruksela -> Paryż',
        mode: TravelTransportMode.shortHaulFlight,
        distanceKm: 320.0,
        delegationSize: 20,
        dateIso: '2026-04-01',
      );
      expect(withPolicy.success, isTrue);

      final withoutPolicyModel = base.togglePolicy(railOverFlight: false);
      final withoutPolicy = withoutPolicyModel.recordTeamTravel(
        description: 'Bruksela -> Paryż',
        mode: TravelTransportMode.shortHaulFlight,
        distanceKm: 320.0,
        delegationSize: 20,
        dateIso: '2026-04-01',
      );
      expect(withoutPolicy.success, isTrue);

      final railEmissions = withPolicy.data!.computeOverview().totalEmissionsKg;
      final flightEmissions = withoutPolicy.data!.computeOverview().totalEmissionsKg;
      expect(railEmissions, lessThan(flightEmissions));

      final invalid = base.recordTeamTravel(
        description: 'Błąd',
        mode: TravelTransportMode.dieselTeamBus,
        distanceKm: 0.0,
        delegationSize: 10,
        dateIso: '2026-04-01',
      );
      expect(invalid.success, isFalse);
    });

    test('recordRaceConvoyTrip updates vehicle odometers, deducts energy cost and adds CO2', () {
      final model = TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
        teamId: 'team_wt_convoy',
      );
      final beforeOverview = model.computeOverview();
      final res = model.recordRaceConvoyTrip(
        stageId: 'tdf_s12',
        stageName: 'Alpe d\'Huez',
        distanceKm: 185.0,
        elevationGainM: 4200.0,
        ambientTempC: 24.0,
        dateIso: '2026-07-16',
      );

      expect(res.success, isTrue);
      final updated = res.data!;
      final afterOverview = updated.computeOverview();

      expect(afterOverview.totalEmissionsKg, greaterThan(beforeOverview.totalEmissionsKg));
      expect(afterOverview.netCarbonBalanceKg, greaterThan(beforeOverview.netCarbonBalanceKg));
      expect(updated.cashBalanceEur, lessThan(model.cashBalanceEur));
      expect(
        updated.vehicles.firstWhere((v) => v.id == 'veh_ds_1').odometerKm,
        closeTo(14200.0 + 185.0 + 35.0, 0.01),
      );
    });

    test('evaluateStageConvoyReadiness flags range anxiety on cold mountain stage and resolves with charging stop', () {
      final model = TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
        teamId: 'team_wt_range',
      );

      final riskyReport = model.evaluateStageConvoyReadiness(
        const StageConvoyLogisticsPlan(
          stageId: 'alpine_250',
          stageName: 'Alpine Monster',
          stageDistanceKm: 390.0,
          elevationGainM: 4800.0,
          ambientTempC: 2.0,
          chargingStopsPlanned: 0,
        ),
      );
      expect(riskyReport.rangeAnxietyRisk, isTrue);
      expect(riskyReport.bottleneckVehicleNames, isNotEmpty);

      final mitigatedReport = model.evaluateStageConvoyReadiness(
        const StageConvoyLogisticsPlan(
          stageId: 'alpine_250',
          stageName: 'Alpine Monster',
          stageDistanceKm: 390.0,
          elevationGainM: 4800.0,
          ambientTempC: 2.0,
          chargingStopsPlanned: 1,
          hasMobileSolarSupport: true,
        ),
      );
      expect(mitigatedReport.rangeAnxietyRisk, isFalse);
      expect(mitigatedReport.totalConvoyCo2Kg, lessThan(riskyReport.totalConvoyCo2Kg));
    });

    test('carbon offsets restore neutrality and fleet upgrade unlocks zero-emission green sponsor', () {
      var model = TeamEsgSustainabilityAndGreenFleetModel.createStarterContinental(
        teamId: 'team_cont_1',
        cashBalanceEur: 900000.0,
      );

      // Emit 25 tons via travel
      final travelRes = model.recordTeamTravel(
        description: 'Long Haul Camp',
        mode: TravelTransportMode.longHaulFlight,
        distanceKm: 5000.0,
        delegationSize: 25,
        dateIso: '2026-03-10',
      );
      expect(travelRes.success, isTrue);
      model = travelRes.data!;
      expect(model.computeOverview().isCarbonNeutral, isFalse);

      // Offset enough CO2 to become carbon neutral
      final tonsNeeded = (model.computeOverview().netCarbonBalanceKg / 1000.0) + 1.0;
      final offsetRes = model.purchaseCarbonOffsets(
        tonsCo2: tonsNeeded,
        program: CarbonOffsetProgramType.reforestation,
        dateIso: '2026-03-15',
      );
      expect(offsetRes.success, isTrue);
      model = offsetRes.data!;
      expect(model.computeOverview().isCarbonNeutral, isTrue);

      // Upgrade Continental DS car to BEV and sign BioPulse sponsor
      final replaceRes = model.purchaseOrUpgradeVehicle(
        const TeamFleetVehicle(
          id: 'veh_cont_ds_bev',
          name: 'VW ID.7 Tourer DS',
          vehicleType: FleetVehicleType.directorSportifCar,
          powertrain: PowertrainType.batteryElectric,
          batteryCapacityKwh: 86.0,
          wltpRangeKm: 610.0,
          co2GramsPerKm: 0.0,
          purchaseCostEur: 58000.0,
          annualMaintenanceEur: 2800.0,
          isActiveInRaceConvoy: true,
        ),
        replaceVehicleId: 'veh_cont_ds_1',
      );
      expect(replaceRes.success, isTrue);
      model = replaceRes.data!.togglePolicy(
        railOverFlight: true,
        recycledKit: true,
        ecoBottles: true,
      );
      expect(model.computeOverview().allRaceCarsZeroEmission, isTrue);

      final signRes = model.signGreenSponsor('gsp_bio_fuel');
      expect(signRes.success, isTrue);
      model = signRes.data!;

      final cashBeforePayout = model.cashBalanceEur;
      final payoutRes = model.collectAnnualGreenSponsorPayouts();
      expect(payoutRes.success, isTrue);
      expect(payoutRes.data!.cashBalanceEur, greaterThan(cashBeforePayout));
    });

    test('JSON round-trip preserves ledger, vehicles and overview metrics identically', () {
      final original = TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
        teamId: 'team_json',
      ).togglePolicy(ecoBottles: true);

      final decoded = TeamEsgSustainabilityAndGreenFleetModel.fromJson(original.toJson());
      final o1 = original.computeOverview();
      final o2 = decoded.computeOverview();

      expect(decoded.teamId, original.teamId);
      expect(decoded.vehicles.length, original.vehicles.length);
      expect(decoded.ledger.length, original.ledger.length);
      expect(decoded.ecoBottleProgramEnabled, isTrue);
      expect(o2.esgScore, closeTo(o1.esgScore, 0.001));
      expect(o2.netCarbonBalanceKg, closeTo(o1.netCarbonBalanceKg, 0.001));
      expect(o2.projectedGreenSponsorRevenueEur, closeTo(o1.projectedGreenSponsorRevenueEur, 0.01));
    });
  });

  group('AI Tactical Coach Reports & Insights', () {
    const analyzer = PostRaceAiTacticalCoachAnalyzer();

    test('handles empty telemetry gracefully with fallback report', () {
      const input = PostRaceCoachAnalysisInput(
        riderId: 'r_empty',
        riderName: 'Jan Kowalski',
        role: TacticalCoachRiderRole.gcLeader,
        ftpWatts: 400,
        maxWPrimeJoules: 22000.0,
        weightKg: 66.0,
        stageName: 'Etap 1',
        totalStageDistanceKm: 150.0,
        samples: [],
      );

      final report = analyzer.analyzeStage(input);
      expect(report.riderId, 'r_empty');
      expect(report.windSummary.topMistakeSegments, isEmpty);
      expect(report.attackSummary.totalAttacks, 0);
    });

    test('scores sheltered rider with optimal W prime attack as grade S or A', () {
      final input = PostRaceCoachAnalysisInput(
        riderId: 'r_opt',
        riderName: 'Marek Lider',
        role: TacticalCoachRiderRole.gcLeader,
        ftpWatts: 410,
        maxWPrimeJoules: 22000.0,
        weightKg: 65.0,
        stageName: 'Etap 15: Mont Ventoux',
        totalStageDistanceKm: 168.0,
        finishPosition: 1,
        samples: _buildShelteredOptimalSamples(),
      );

      final report = analyzer.analyzeStage(input);
      expect(report.overallTacticalScore, greaterThanOrEqualTo(80.0));
      expect(
        report.grade == TacticalCoachGrade.s || report.grade == TacticalCoachGrade.a,
        isTrue,
      );
      expect(report.windSummary.shelteredPercentOfStage, greaterThan(80.0));
      expect(report.attackSummary.totalAttacks, greaterThanOrEqualTo(1));
      expect(report.attackSummary.blowupCount, 0);
      expect(report.insights, isNotEmpty);
    });

    test('detects wind gutter losses and empty-tank W prime blowup', () {
      final input = PostRaceCoachAnalysisInput(
        riderId: 'r_blowup',
        riderName: 'Piotr Pechowiec',
        role: TacticalCoachRiderRole.sprinter,
        ftpWatts: 360,
        maxWPrimeJoules: 20000.0,
        weightKg: 74.0,
        stageName: 'Etap 4: Wiatry Flandrii',
        totalStageDistanceKm: 175.0,
        finishPosition: 42,
        samples: _buildWindExposedBlowupSamples(),
      );

      final report = analyzer.analyzeStage(input);
      expect(report.windSummary.totalWastedEnergyKj, greaterThan(0.0));
      expect(report.windSummary.gutterExposureCount, greaterThan(0));
      expect(report.windSummary.topMistakeSegments, isNotEmpty);
      expect(report.attackSummary.totalAttacks, greaterThanOrEqualTo(1));
      expect(
        report.attackSummary.poorlyTimedAttacks + report.attackSummary.blowupCount,
        greaterThanOrEqualTo(1),
      );
      expect(report.overallTacticalScore, lessThan(80.0));
    });

    test('PostRaceTacticalCoachReport JSON round-trip preserves full report', () {
      final report = analyzer.analyzeStage(
        PostRaceCoachAnalysisInput(
          riderId: 'r_json',
          riderName: 'Adam Json',
          role: TacticalCoachRiderRole.puncheur,
          ftpWatts: 390,
          maxWPrimeJoules: 21000.0,
          weightKg: 69.0,
          stageName: 'Etap 8',
          totalStageDistanceKm: 180.0,
          samples: _buildWindExposedBlowupSamples(),
        ),
      );

      final decoded = PostRaceTacticalCoachReport.fromJson(report.toJson());
      expect(decoded.riderId, report.riderId);
      expect(decoded.grade, report.grade);
      expect(decoded.overallTacticalScore, closeTo(report.overallTacticalScore, 0.001));
      expect(
        decoded.windSummary.totalWastedEnergyKj,
        closeTo(report.windSummary.totalWastedEnergyKj, 0.001),
      );
      expect(decoded.attackSummary.totalAttacks, report.attackSummary.totalAttacks);
      expect(decoded.insights.length, report.insights.length);
    });

    test('PostRaceAiCoachInsightsData.fromStageReport synthesizes team reports and handles empty team', () {
      const stageReport = StageSummaryReport(
        stageId: 'st_5',
        stageNumber: 5,
        stageName: 'Etap 5: Ardennes',
        stageType: StageType.hilly,
        winnerRiderName: 'Kolarz A',
        winnerTeamId: 'player_team',
        winnerTimeSeconds: 14520.0,
        timeCutLimitSeconds: 16262.0,
        timeCutPercent: 12.0,
        otlEliminatedCount: 0,
        dnfCount: 0,
        teamPrizeMoneyTotals: {'player_team': 11000},
        mostCombativeRiderId: 'r2',
        results: [
          OfficialRiderStageResult(
            riderId: 'r1',
            riderName: 'Kolarz A',
            teamId: 'player_team',
            rank: 1,
            rawFinishTimeSeconds: 14520.0,
            officialFinishTimeSeconds: 14520.0,
            gapToWinnerSeconds: 0.0,
          ),
          OfficialRiderStageResult(
            riderId: 'r2',
            riderName: 'Kolarz B',
            teamId: 'player_team',
            rank: 14,
            rawFinishTimeSeconds: 14585.0,
            officialFinishTimeSeconds: 14585.0,
            gapToWinnerSeconds: 65.0,
          ),
        ],
      );

      final data = PostRaceAiCoachInsightsData.fromStageReport(
        report: stageReport,
        playerTeamId: 'player_team',
      );
      expect(data.reports.length, 2);
      expect(data.isFromLiveTelemetry, isFalse);

      final emptyData = PostRaceAiCoachInsightsData.fromStageReport(
        report: stageReport,
        playerTeamId: 'other_team',
      );
      expect(emptyData.reports, isEmpty);
    });
  });

  group('AI Tactical Coach Responsive UI Widgets', () {
    const analyzer = PostRaceAiTacticalCoachAnalyzer();

    Future<void> pumpInsightsCard(
      WidgetTester tester, {
      required Size size,
      required PostRaceAiCoachInsightsData data,
      bool isDisabled = false,
      ValueChanged<TacticalCoachingInsight>? onApplyInsight,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: PostRaceAiCoachInsightsCard(
                data: data,
                isDisabled: isDisabled,
                onApplyNextStageAction: onApplyInsight,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('PostRaceAiCoachInsightsCard renders without overflow across 390x844, 1024x768, 1600x900', (tester) async {
      final reports = [
        analyzer.analyzeStage(
          PostRaceCoachAnalysisInput(
            riderId: 'r1',
            riderName: 'Marek Lider',
            role: TacticalCoachRiderRole.gcLeader,
            ftpWatts: 410,
            maxWPrimeJoules: 22000.0,
            weightKg: 65.0,
            stageName: 'Etap 15',
            totalStageDistanceKm: 168.0,
            samples: _buildShelteredOptimalSamples(),
          ),
        ),
        analyzer.analyzeStage(
          PostRaceCoachAnalysisInput(
            riderId: 'r2',
            riderName: 'Piotr Sprinter',
            role: TacticalCoachRiderRole.sprinter,
            ftpWatts: 360,
            maxWPrimeJoules: 20000.0,
            weightKg: 74.0,
            stageName: 'Etap 15',
            totalStageDistanceKm: 168.0,
            samples: _buildWindExposedBlowupSamples(),
          ),
        ),
      ];

      final data = PostRaceAiCoachInsightsData.fromReports(
        stageName: 'Etap 15',
        reports: reports,
      );

      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpInsightsCard(tester, size: size, data: data);
        expect(find.text('Marek Lider'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('PostRaceAiCoachInsightsCard supports empty and disabled states', (tester) async {
      const emptyData = PostRaceAiCoachInsightsData(
        stageName: 'Etap Pusty',
        reports: [],
      );
      await pumpInsightsCard(tester, size: const Size(1024, 768), data: emptyData);
      expect(tester.takeException(), isNull);

      final report = analyzer.analyzeStage(
        PostRaceCoachAnalysisInput(
          riderId: 'r1',
          riderName: 'Marek Lider',
          role: TacticalCoachRiderRole.gcLeader,
          ftpWatts: 400,
          maxWPrimeJoules: 22000.0,
          weightKg: 66.0,
          stageName: 'Etap 1',
          totalStageDistanceKm: 150.0,
          samples: _buildWindExposedBlowupSamples(),
        ),
      );
      await pumpInsightsCard(
        tester,
        size: const Size(1024, 768),
        data: PostRaceAiCoachInsightsData.fromReports(
          stageName: 'Etap 1',
          reports: [report],
        ),
        isDisabled: true,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('PostRaceAiTacticalCoachPanel renders cleanly with ProviderScope at 390x844 and 1600x900', (tester) async {
      final report = analyzer.analyzeStage(
        PostRaceCoachAnalysisInput(
          riderId: 'r_panel',
          riderName: 'Jan Panel',
          role: TacticalCoachRiderRole.gcLeader,
          ftpWatts: 400,
          maxWPrimeJoules: 22000.0,
          weightKg: 66.0,
          stageName: 'Etap Panel',
          totalStageDistanceKm: 165.0,
          samples: _buildWindExposedBlowupSamples(),
        ),
      );

      for (final size in const [Size(390, 844), Size(1600, 900)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: PostRaceAiTacticalCoachPanel(report: report),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
