import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/finance_and_budget_service.dart';
import 'package:pro_peloton_manager/ui/widgets/team_budget_cashflow_projection_chart.dart';

List<MonthlyCashflowProjectionPoint> _buildSample12Months({
  required double startingBalanceEur,
  required double monthlySponsorTrancheEur,
  required double monthlySalariesEur,
  required double campCostInWinterMonthsEur,
}) {
  final inputs = List<MonthlyCashflowProjectionPoint>.generate(12, (index) {
    final month = index + 1;
    final bool isCampMonth = month == 1 || month == 2 || month == 5 || month == 6;
    return MonthlyCashflowProjectionPoint(
      monthIndex: month,
      monthLabel: TeamCashflowProjectionCalculator.defaultMonthLabel(month),
      sponsorTrancheEur: monthlySponsorTrancheEur,
      salariesExpenseEur: monthlySalariesEur,
      trainingCampsExpenseEur: isCampMonth ? campCostInWinterMonthsEur : 0.0,
      projectedEndingBalanceEur: 0.0,
    );
  });

  return TeamCashflowProjectionCalculator.buildProjectedSeries(
    startingBalanceEur: startingBalanceEur,
    monthlyInputs: inputs,
  );
}

void main() {
  group('TeamCashflowProjectionCalculator', () {
    test('wylicza narastające saldo końcowe oraz wykrywa pierwszy miesiąc deficytu', () {
      final months = _buildSample12Months(
        startingBalanceEur: 120000,
        monthlySponsorTrancheEur: 100000,
        monthlySalariesEur: 140000,
        campCostInWinterMonthsEur: 40000,
      );

      expect(months.length, 12);
      // STY: 120k + 100k - 140k - 40k = 40k
      expect(months[0].projectedEndingBalanceEur, closeTo(40000, 0.01));
      // LUT: 40k + 100k - 140k - 40k = -40k (pierwszy deficyt)
      expect(months[1].projectedEndingBalanceEur, closeTo(-40000, 0.01));
      expect(months[1].isDeficit, isTrue);

      final summary = TeamCashflowProjectionCalculator.summarize(
        startingBalanceEur: 120000,
        months: months,
      );
      expect(summary.hasDeficitWarning, isTrue);
      expect(summary.isEndOfSeasonDeficit, isTrue);
      expect(summary.firstDeficitMonthIndex, 2);
      expect(summary.firstDeficitMonthLabel, 'LUT');
      expect(summary.totalSponsorTranchesEur, closeTo(1200000, 0.01));
      expect(summary.totalSalariesEur, closeTo(1680000, 0.01));
      expect(summary.totalCampsEur, closeTo(160000, 0.01));
    });

    test('konwertuje MonthlyCashflowReport na MonthlyCashflowProjectionPoint', () {
      final report = MonthlyCashflowReport(
        period: DateTime(2026, 3, 1),
        sponsorPayoutEur: 250000,
        bikeManufacturerCashEur: 20000,
        prizeMoneyClubShareEur: 15000,
        prizeMoneyRidersShareEur: 10000,
        riderBuyoutIncomeEur: 0,
        otherIncomeEur: 5000,
        totalIncomeEur: 290000,
        riderSalariesEur: 180000,
        staffSalariesEur: 45000,
        raceLogisticsEur: 25000,
        trainingCampsEur: 30000,
        physiologicalTestingEur: 5000,
        equipmentServiceAndPurchasesEur: 10000,
        facilitiesMaintenanceEur: 5000,
        totalExpensesEur: 300000,
        netCashflowEur: -10000,
        startingBalanceEur: 500000,
        endingBalanceEur: 490000,
        runwayMonths: 12.0,
        financialHealthScore: 82,
        recommendations: const [],
      );

      final point = MonthlyCashflowProjectionPoint.fromMonthlyReport(report);
      expect(point.monthIndex, 3);
      expect(point.monthLabel, 'MAR');
      expect(point.sponsorTrancheEur, 250000);
      expect(point.otherIncomeEur, 40000);
      expect(point.salariesExpenseEur, 225000);
      expect(point.trainingCampsExpenseEur, 30000);
      expect(point.logisticsAndOtherExpenseEur, 45000);
      expect(point.projectedEndingBalanceEur, 490000);
    });
  });

  group('TeamBudgetCashflowProjectionChart Widget', () {
    Future<void> pumpChartAtSize(
      WidgetTester tester, {
      required Size viewportSize,
      required List<MonthlyCashflowProjectionPoint> months,
      double startingBalanceEur = 500000,
      bool enabled = true,
      ValueChanged<MonthlyCashflowProjectionPoint>? onMonthSelected,
      VoidCallback? onDeficitActionPressed,
    }) async {
      tester.view.physicalSize = viewportSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: TeamBudgetCashflowProjectionChart(
                months: months,
                startingBalanceEur: startingBalanceEur,
                enabled: enabled,
                onMonthSelected: onMonthSelected,
                onDeficitActionPressed: onDeficitActionPressed,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renderuje się poprawnie bez przepełnień w 390x844, 1024x768 i 1600x900',
        (tester) async {
      final months = _buildSample12Months(
        startingBalanceEur: 600000,
        monthlySponsorTrancheEur: 220000,
        monthlySalariesEur: 180000,
        campCostInWinterMonthsEur: 35000,
      );

      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpChartAtSize(
          tester,
          viewportSize: size,
          months: months,
          startingBalanceEur: 600000,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('PROGNOZA PRZEPŁYWÓW PIENIĘŻNYCH (12 MIES.)'), findsOneWidget);
        expect(find.text('PROGNOZOWANE SALDO KOŃCOWE'), findsOneWidget);
        expect(find.text('Transze sponsorów'), findsWidgets);
        expect(find.text('Wypłaty pensji'), findsWidgets);
        expect(find.text('Koszty obozów'), findsWidgets);
      }
    });

    testWidgets('wyświetla ostrzeżenie o deficycie i obsługuje przycisk akcji', (tester) async {
      bool actionTriggered = false;
      final deficitMonths = _buildSample12Months(
        startingBalanceEur: 50000,
        monthlySponsorTrancheEur: 90000,
        monthlySalariesEur: 130000,
        campCostInWinterMonthsEur: 25000,
      );

      await pumpChartAtSize(
        tester,
        viewportSize: const Size(1024, 768),
        months: deficitMonths,
        startingBalanceEur: 50000,
        onDeficitActionPressed: () => actionTriggered = true,
      );

      expect(find.textContaining('Ostrzeżenie o deficycie'), findsOneWidget);
      expect(find.text('DEFICYT'), findsOneWidget);

      await tester.tap(find.text('Przegląd cięć kosztów'));
      await tester.pumpAndSettle();
      expect(actionTriggered, isTrue);
    });

    testWidgets('obsługuje przełączanie serii, stan pusty, wyłączenie i nawigację klawiaturą',
        (tester) async {
      MonthlyCashflowProjectionPoint? selectedMonth;
      final months = _buildSample12Months(
        startingBalanceEur: 400000,
        monthlySponsorTrancheEur: 200000,
        monthlySalariesEur: 150000,
        campCostInWinterMonthsEur: 20000,
      );

      await pumpChartAtSize(
        tester,
        viewportSize: const Size(1024, 768),
        months: months,
        startingBalanceEur: 400000,
        onMonthSelected: (m) => selectedMonth = m,
      );

      // Przełączenie chipa serii
      await tester.tap(find.text('Koszty obozów').first);
      await tester.pumpAndSettle();

      // Wybór miesiąca kliknięciem w obszar wykresu + nawigacja strzałką w prawo
      final customPaintFinder = find.byType(CustomPaint).last;
      await tester.tapAt(tester.getTopLeft(customPaintFinder) + const Offset(85, 100));
      await tester.pumpAndSettle();
      expect(selectedMonth, isNotNull);
      final int firstIndex = selectedMonth!.monthIndex;

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(selectedMonth!.monthIndex, (firstIndex + 1).clamp(1, 12));

      // Stan pusty
      await pumpChartAtSize(
        tester,
        viewportSize: const Size(1024, 768),
        months: const [],
      );
      expect(find.text('Brak danych prognozy przepływów pieniężnych.'), findsOneWidget);

      // Stan disabled
      await pumpChartAtSize(
        tester,
        viewportSize: const Size(1024, 768),
        months: months,
        enabled: false,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
