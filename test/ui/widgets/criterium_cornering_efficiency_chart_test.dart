import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/braking_zone_kinetic_energy_loss_solver.dart';
import 'package:pro_peloton_manager/ui/widgets/criterium_cornering_efficiency_chart.dart';

void main() {
  Widget buildTestHost({
    required Size size,
    bool enabled = true,
    bool useEnglishLabels = false,
    ValueChanged<WheelsetBrakingComparisonResult>? onComparisonChanged,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          backgroundColor: const Color(0xFF0F1115),
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: CriteriumCorneringEfficiencyChart(
                enabled: enabled,
                useEnglishLabels: useEnglishLabels,
                onComparisonChanged: onComparisonChanged,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders cleanly at 390x844, 1024x768, and 1600x900',
      (tester) async {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(buildTestHost(size: size));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(CriteriumCorneringEfficiencyChart), findsOneWidget);
      expect(find.text('Efektywność Kół na Trasach Krętych'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('switches discipline, view mode, surface and laps',
      (tester) async {
    WheelsetBrakingComparisonResult? latestComparison;
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    await tester.pumpWidget(
      buildTestHost(
        size: const Size(1024, 768),
        onComparisonChanged: (res) => latestComparison = res,
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));

    // Switch to 8-turn technical circuit.
    await tester.tap(find.text('Techniczny 8-zakr.'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(latestComparison, isNotNull);
    expect(
      latestComparison!.profileB.discipline,
      BrakingCourseDiscipline.technicalCircuit,
    );

    // Switch to Corner Breakdown view.
    await tester.tap(find.text('Widok: Krzywa'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Widok: Zakręty'), findsOneWidget);

    // Toggle wet surface.
    await tester.tap(find.text('Sucho'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Mokro'), findsOneWidget);

    // Increment laps.
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('14 Okr.'), findsOneWidget);

    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('respects disabled state and English labels', (tester) async {
    var callbackCount = 0;
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    await tester.pumpWidget(
      buildTestHost(
        size: const Size(1024, 768),
        enabled: false,
        useEnglishLabels: true,
        onComparisonChanged: (_) => callbackCount++,
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Criterium Cornering Wheelset Efficiency'), findsOneWidget);
    await tester.tap(find.text('8-Turn Tech'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(callbackCount, 0);

    await tester.binding.setSurfaceSize(null);
  });
}
