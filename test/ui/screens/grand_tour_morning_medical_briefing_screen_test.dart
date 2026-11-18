import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/screens/grand_tour_morning_medical_briefing_screen.dart';

void main() {
  Widget buildTestApp({
    bool isReadOnly = false,
    ValueChanged<GrandTourMorningBriefingAllocationResult>? onCommitBriefing,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: GrandTourMorningMedicalBriefingScreen(
          isReadOnly: isReadOnly,
          onCommitBriefing: onCommitBriefing,
        ),
      ),
    );
  }

  Future<void> pumpResponsiveScreen(
    WidgetTester tester,
    Size size, {
    bool isReadOnly = false,
    ValueChanged<GrandTourMorningBriefingAllocationResult>? onCommitBriefing,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestApp(
        isReadOnly: isReadOnly,
        onCommitBriefing: onCommitBriefing,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('renders 8 rider cards with HRV trend and physio sliders', (
    tester,
  ) async {
    await pumpResponsiveScreen(tester, const Size(1600, 900));

    expect(find.textContaining('Poranny Raport Medyczny'), findsOneWidget);
    expect(find.textContaining('Trend Nocnego HRV (7 dni)'), findsNWidgets(8));
    expect(find.text('Gotowość mięśniowa'), findsNWidgets(8));
    expect(find.byType(Slider), findsNWidgets(8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('responsive layout passes at 390x844, 1024x768, and 1600x900', (
    tester,
  ) async {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      await pumpResponsiveScreen(tester, size);
      expect(find.byType(GrandTourMorningMedicalBriefingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('supports physio slider updates, filters, and commit action', (
    tester,
  ) async {
    GrandTourMorningBriefingAllocationResult? committedResult;
    await pumpResponsiveScreen(
      tester,
      const Size(1280, 900),
      onCommitBriefing: (res) => committedResult = res,
    );

    await tester.tap(find.text('Wyzeruj'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('0 / 360 min'), findsOneWidget);

    await tester.tap(find.text('Auto-Przydział'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('0 / 360 min'), findsNothing);

    await tester.tap(find.text('Liderzy'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(Slider), findsNWidgets(2));

    await tester.tap(find.text('Wszyscy (8)'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(Slider), findsNWidgets(8));

    final commitFinder = find.textContaining('Zatwierdź Raport');
    await tester.ensureVisible(commitFinder);
    await tester.tap(commitFinder);
    await tester.pump(const Duration(milliseconds: 250));

    expect(committedResult, isNotNull);
    expect(committedResult!.totalAllocatedMinutes, greaterThan(0));
    expect(find.text('Protokół Zatwierdzony'), findsOneWidget);
  });

  testWidgets('respects isReadOnly disabled state', (tester) async {
    GrandTourMorningBriefingAllocationResult? committedResult;
    await pumpResponsiveScreen(
      tester,
      const Size(1024, 768),
      isReadOnly: true,
      onCommitBriefing: (res) => committedResult = res,
    );

    expect(find.text('Tylko podgląd'), findsOneWidget);

    final firstSlider = tester.widget<Slider>(find.byType(Slider).first);
    expect(firstSlider.onChanged, isNull);

    await tester.tap(find.textContaining('Zatwierdź Raport'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(committedResult, isNull);
  });
}
