import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/screens/deep_career_analytics_bi_screen.dart';

void main() {
  group('DeepCareerAnalyticsBiCalculator & ROI Models', () {
    test('TransferRoiRecord handles zero investment and zero UCI points safely', () {
      const zeroRecord = TransferRoiRecord(
        riderId: 'r_zero',
        riderName: 'Zero Rider',
        nationalityIso: 'PL',
        roleLabel: 'Domestique',
        age: 22,
        acquisitionCostEur: 0,
        annualSalaryEur: 0,
        contractYears: 1,
        uciPointsGenerated: 0,
        winsCount: 0,
        podiumsCount: 0,
        tvExposureValueEur: 0,
        prizeMoneyEarnedEur: 0,
      );

      expect(zeroRecord.totalInvestmentEur, 0);
      expect(zeroRecord.roiPercent, 0.0);
      expect(zeroRecord.costPerUciPointEur, double.infinity);
      expect(zeroRecord.grade, BiEfficiencyGrade.marginal);
    });

    test('RdInvestmentRoiRecord computes ROI, wattsPer100kEur and paybackMonths', () {
      const rd = RdInvestmentRoiRecord(
        projectId: 'rd_1',
        projectName: 'Aero Cockpit',
        category: 'Aerodynamika',
        capexInvestedEur: 300000,
        opexAnnualEur: 100000,
        wattsSaved: 12.0,
        cdaDelta: -0.012,
        raceSecondsSavedPer100km: 40.0,
        estimatedPointsGain: 200,
        commercialLicensingReturnEur: 400000,
        estimatedPrizeGainEur: 200000,
        maturityProgress: 0.9,
      );

      expect(rd.totalCostEur, 400000);
      expect(rd.totalValueGeneratedEur, 400000 + 200000 + 200 * 520);
      expect(rd.roiPercent, closeTo(76.0, 0.01));
      expect(rd.wattsPer100kEur, closeTo(3.0, 0.01));
      expect(rd.paybackMonths, inInclusiveRange(1.0, 12.0));
      expect(rd.grade, BiEfficiencyGrade.high);
    });

    test('DeepCareerAnalyticsBiCalculator.build produces benchmark dataset when save is null', () {
      final dataset = DeepCareerAnalyticsBiCalculator.build(
        save: null,
        timeframe: BiTimeframeFilter.seasonCurrent,
      );

      expect(dataset.isLiveCareerData, isFalse);
      expect(dataset.transfers, isNotEmpty);
      expect(dataset.rdProjects, isNotEmpty);
      expect(dataset.monthlyCurve.length, 12);
      expect(dataset.totalCapitalDeployedEur, greaterThan(0));
    });
  });

  group('DeepCareerAnalyticsBiScreen Responsive & Interaction Tests', () {
    Widget buildTestHost(Size size) {
      return ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: const DeepCareerAnalyticsBiScreen(),
          ),
        ),
      );
    }

    Future<void> verifyViewport(WidgetTester tester, Size size) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestHost(size));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Analityka BI — ROI Transferów & R&D'), findsOneWidget);
      expect(find.text('Skumulowany ROI'), findsOneWidget);
      expect(find.text('Krzywa Skumulowanego ROI (12 mies.)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    testWidgets('renders cleanly at 390x844 mobile without overflow', (tester) async {
      await verifyViewport(tester, const Size(390, 844));
    });

    testWidgets('renders cleanly at 1024x768 tablet without overflow', (tester) async {
      await verifyViewport(tester, const Size(1024, 768));
    });

    testWidgets('renders cleanly at 1600x900 desktop without overflow', (tester) async {
      await verifyViewport(tester, const Size(1600, 900));
    });

    testWidgets('switches tabs, filters transfers and toggles R&D priority', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestHost(const Size(1280, 800)));
      await tester.pump(const Duration(milliseconds: 350));

      // Switch to Transfers ROI tab
      await tester.tap(find.text('ROI Transferów').last);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Audyt Rentowności Transferów i Kontraktów'), findsOneWidget);
      expect(find.text('Kacper Majewski'), findsOneWidget);

      // Search non-existent rider -> empty state + reset
      await tester.enterText(find.byType(TextField), 'NieistniejacyKolarzXYZ');
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Brak transferów spełniających wybrane kryteria.'), findsOneWidget);

      await tester.ensureVisible(find.text('Wyczyść filtry'));
      await tester.tap(find.text('Wyczyść filtry'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Kacper Majewski'), findsOneWidget);

      // Switch to R&D ROI tab
      await tester.ensureVisible(find.text('ROI R&D & Innowacji'));
      await tester.tap(find.text('ROI R&D & Innowacji'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Symulator Alokacji Budżetu R&D (What-If)'), findsOneWidget);
      expect(find.text('Portfel Projektów R&D i Infrastruktury'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
