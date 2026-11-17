import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/organizer/race_organizer_empire_model.dart';
import 'package:pro_peloton_manager/services/organizer/course_safety_barriers_and_marshals_planner.dart';

void main() {
  group('CourseSafetyBarriersAndMarshalsPlanner — Unit & Logic', () {
    const planner = CourseSafetyBarriersAndMarshalsPlanner();

    test('Boplan Air-Cushion reduces sprint crash risk vs metal barriers', () {
      const sprintMetal = CourseHazardZone(
        zoneId: 'sprint_1',
        name: 'Finisz Sprinterski',
        kilometerMark: 180.0,
        lengthMeters: 400,
        zoneType: CourseHazardZoneType.finalSprintChute,
        expectedPelotonSpeedKmh: 75.0,
        crowdDensityIndex: 0.95,
        assignedBarrier: SafetyBarrierSystemType.standardMetalCrowds,
        assignedMarshalDensity: MarshalDeploymentDensity.standard,
      );

      final sprintBoplan = sprintMetal.copyWith(
        assignedBarrier: SafetyBarrierSystemType.boplanAirCushion,
        assignedMarshalDensity: MarshalDeploymentDensity.uciProSafeR,
        hasLedWarningTotem: true,
      );

      expect(sprintMetal.isUciMinimumMet, isFalse);
      expect(sprintBoplan.isUciMinimumMet, isTrue);
      expect(sprintBoplan.boplanUnitsRequired, 200);
      expect(
        sprintBoplan.residualCrashRisk,
        lessThan(sprintMetal.residualCrashRisk),
      );
      expect(
        sprintBoplan.severityReductionPct,
        greaterThan(sprintMetal.severityReductionPct),
      );
    });

    test('Catch-Net + Foam Mattress satisfies alpine cliff dropoff UCI rule', () {
      const cliffNone = CourseHazardZone(
        zoneId: 'cliff_1',
        name: 'Przepaść Alpejska',
        kilometerMark: 112.0,
        lengthMeters: 250,
        zoneType: CourseHazardZoneType.alpineCliffDropoff,
        expectedPelotonSpeedKmh: 64.0,
        cliffExposureSeverity: 0.9,
        assignedBarrier: SafetyBarrierSystemType.none,
        assignedMarshalDensity: MarshalDeploymentDensity.minimal,
      );

      final cliffNet = cliffNone.copyWith(
        assignedBarrier: SafetyBarrierSystemType.catchNetAndFoamMattress,
        assignedMarshalDensity: MarshalDeploymentDensity.standard,
      );

      expect(cliffNone.isUciMinimumMet, isFalse);
      expect(cliffNet.isUciMinimumMet, isTrue);
      expect(cliffNet.catchNetMetersRequired, 250);
    });

    test('autoOptimizeSafeRDeployment upgrades critical zones within budget', () {
      final baseline =
          CourseSafetyBarriersAndMarshalsPlanner.createDefaultStageHazardZones();
      final baselineReport = planner.auditCourseSafety(
        raceId: 'race_tdf',
        raceName: 'Tour de France',
        stageNumber: 14,
        zones: baseline,
      );
      expect(
        baselineReport.complianceGrade,
        SafetyAuditComplianceGrade.criticalFailure,
      );

      const budgetLimit = 120000;
      final optimized = planner.autoOptimizeSafeRDeployment(
        zones: baseline,
        maxBudgetEur: budgetLimit,
      );
      final optimizedReport = planner.auditCourseSafety(
        raceId: 'race_tdf',
        raceName: 'Tour de France',
        stageNumber: 14,
        zones: optimized,
        availableBudgetEur: budgetLimit,
      );

      expect(optimizedReport.totalDeploymentCostEur, lessThanOrEqualTo(budgetLimit));
      expect(
        optimizedReport.overallSafetyScore,
        greaterThan(baselineReport.overallSafetyScore),
      );
      expect(
        optimizedReport.uciCompliantZones,
        greaterThan(baselineReport.uciCompliantZones),
      );
    });

    test('applySafetyPlanToEmpire records ledger transaction and updates race', () {
      final baseline =
          CourseSafetyBarriersAndMarshalsPlanner.createDefaultStageHazardZones();
      final optimized = planner.autoOptimizeSafeRDeployment(
        zones: baseline,
        maxBudgetEur: 140000,
      );
      final report = planner.auditCourseSafety(
        raceId: 'race_tdf',
        raceName: 'Tour de France',
        stageNumber: 14,
        zones: optimized,
      );

      const ledger = OrganizerBudgetLedger(
        liquidCashEur: 500000,
        reserveFundEur: 100000,
        annualOperatingOverheadEur: 120000,
        prizePoolCommitmentEur: 200000,
        appearanceFeesAllocatedEur: 150000,
        safetyInfrastructureBudgetEur: 140000,
      );
      const race = ManagedRacePortfolioItem(
        raceId: 'race_tdf',
        raceName: 'Tour de France',
        countryCode: 'FR',
        tier: UciRaceClassificationTier.grandTour,
        stageCount: 21,
        prestigeScore: 95.0,
        globalViewershipIndex: 94.0,
        courseQualityScore: 92.0,
        safetyRatingScore: 76.0,
        starPowerScore: 93.0,
        uciComplianceScore: 88.0,
        titleSponsorName: 'LCL',
        titleSponsorAnnualEur: 15000000,
        prizePoolEur: 2300000,
        consecutivelyHeldYears: 112,
      );

      final result = planner.applySafetyPlanToEmpire(
        ledger: ledger,
        race: race,
        auditReport: report,
        seasonYear: 2026,
      );

      expect(result.entryRecorded, isNotNull);
      expect(
        result.entryRecorded!.category,
        OrganizerCashflowCategory.safetyAndLogistics,
      );
      expect(
        result.updatedLedger.liquidCashEur,
        500000 - report.totalDeploymentCostEur,
      );
      expect(
        result.updatedRace.safetyRatingScore,
        greaterThan(race.safetyRatingScore),
      );
    });

    test('JSON serialization round-trip preserves CourseHazardZone and inventory', () {
      final zone = CourseSafetyBarriersAndMarshalsPlanner
          .createDefaultStageHazardZones()
          .last
          .copyWith(hasLedWarningTotem: true);
      final decodedZone = CourseHazardZone.fromJson(zone.toJson());
      expect(decodedZone, equals(zone));

      final inv = CourseSafetyBarriersAndMarshalsPlanner.createDefaultInventory();
      final decodedInv = SafetyEquipmentInventory.fromJson(inv.toJson());
      expect(decodedInv, equals(inv));
    });
  });

  group('CourseSafetyBarriersAndMarshalsPanel — Responsive UI', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CourseSafetyBarriersAndMarshalsPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final entry in {
      'Mobile 390x844': const Size(390, 844),
      'Tablet 1024x768': const Size(1024, 768),
      'Desktop 1600x900': const Size(1600, 900),
    }.entries) {
      testWidgets('renders without overflow at ${entry.key}', (tester) async {
        await pumpPanelAtSize(tester, entry.value);
        expect(find.text('Planer Barier Boplan, Siatek i Marshali'), findsOneWidget);
        expect(find.text('Auto-Optymalizacja SafeR'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('interactive auto-optimization updates status and compliance',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));

      await tester.tap(find.text('Auto-Optymalizacja SafeR'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text(
          'Zastosowano automatyczną optymalizację UCI SafeR w ramach budżetu.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
