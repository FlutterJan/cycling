import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/team_bus_chef_and_microbiome_nutrition.dart';

void main() {
  group('TeamBusChefAndMicrobiomeNutritionService', () {
    const service = TeamBusChefAndMicrobiomeNutritionService();
    final chef =
        TeamBusChefAndMicrobiomeNutritionService.availableChefsCatalog.first;
    const kitchen = KitchenBusEquipmentTier.worldTourMetabolicBus;

    test('calculates caloric balance and RED-S risk accurately', () {
      const rider = RiderNutritionalProfile(
        riderId: 'r1',
        riderName: 'Janek Kowalski',
        role: 'Lider GC',
        bodyWeightKg: 62.0,
        targetRaceWeightKg: 61.5,
        stageExpenditureKcal: 5000.0,
        glycogenStorePercent: 30.0,
        glycogenCapacityG: 600.0,
        microbiomeDiversityIndex: 82.0,
        gutTrainingLevel: 85,
        assignedStrategy: NutritionMenuStrategy.highCarbGlycogenLoad,
        dailyProbioticCourseActive: true,
      );

      final balance = service.calculateCaloricBalance(
        rider,
        chef,
        kitchen,
        isRestDay: false,
      );

      expect(balance.totalDailyExpenditureKcal, greaterThan(6800.0));
      expect(balance.plannedIntakeKcal, greaterThan(7000.0));
      expect(balance.carbsPerKg, greaterThan(10.0));
      expect(balance.relativeEnergyDeficiencyRisk, isFalse);

      final cutBalance = service.calculateCaloricBalance(
        rider.copyWith(assignedStrategy: NutritionMenuStrategy.weightCutDeficit),
        chef,
        kitchen,
        isRestDay: false,
      );
      expect(cutBalance.netCaloricBalanceKcal, lessThan(0));
      expect(cutBalance.relativeEnergyDeficiencyRisk, isTrue);
    });

    test('probiotic reset improves microbiome and glycogen synthesis', () {
      const riderLowFlora = RiderNutritionalProfile(
        riderId: 'r2',
        riderName: 'Kasper Nielsen',
        role: 'Rouleur',
        bodyWeightKg: 78.0,
        targetRaceWeightKg: 78.0,
        stageExpenditureKcal: 4200.0,
        glycogenStorePercent: 40.0,
        glycogenCapacityG: 720.0,
        microbiomeDiversityIndex: 55.0,
        gutTrainingLevel: 70,
        assignedStrategy: NutritionMenuStrategy.gutMicrobiomeProbioticReset,
        dailyProbioticCourseActive: true,
      );

      final report = service.simulateOvernightRecovery(
        riderLowFlora,
        chef,
        kitchen,
        isRestDay: false,
      );

      expect(report.microbiomeAfter, greaterThan(report.microbiomeBefore));
      expect(report.endingGlycogenPercent, greaterThan(report.startingGlycogenPercent));
      expect(report.maxOnBikeCarbAbsorptionGPerHour, greaterThan(75.0));
    });

    test('autoOptimizeRosterMenu assigns probiotic reset for low microbiome', () {
      final roster =
          TeamBusChefAndMicrobiomeNutritionService.createDefaultGrandTourRoster();
      final optimized = service.autoOptimizeRosterMenu(roster, isRestDay: true);

      final kasper = optimized.firstWhere((r) => r.riderId == 'rider_rouleur_5');
      expect(
        kasper.assignedStrategy,
        NutritionMenuStrategy.gutMicrobiomeProbioticReset,
      );
      expect(kasper.dailyProbioticCourseActive, isTrue);

      final summary = service.processTeamDayCatering(
        dayIndex: 15,
        stageName: 'Dzień Przerwy',
        isRestDay: true,
        chef: chef,
        kitchen: kitchen,
        roster: optimized,
      );
      expect(summary.reports.length, roster.length);
      expect(summary.averageGlycogenPercent, greaterThan(80.0));
    });
  });

  group('TeamBusChefAndMicrobiomeNutritionPanel responsive UI', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TeamBusChefAndMicrobiomeNutritionPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844 mobile without overflow',
        (tester) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(find.text('SZEF KUCHNI DRUŻYNY & MIKROBIOM'), findsOneWidget);
      expect(find.text('Auto-Optymalizuj Menu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1024x768 tablet without overflow',
        (tester) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.text('PLAN POSIŁKÓW KOLARZY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1600x900 desktop and commits recovery',
        (tester) async {
      await pumpAtSize(tester, const Size(1600, 900));
      expect(find.textContaining('RAPORT METABOLICZNY:'), findsOneWidget);

      await tester.tap(find.text('Auto-Optymalizuj Menu'));
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Zatwierdź Regenerację'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.textContaining('Etap 15:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
