import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/team_service_course_hq_upgrades.dart';
import 'package:pro_peloton_manager/ui/screens/service_course_hq_facility_screen.dart';

void main() {
  Widget buildTestApp({
    TeamServiceCourseHqState? initialState,
    ValueChanged<TeamServiceCourseHqState>? onStateChanged,
    Size size = const Size(1600, 900),
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: ServiceCourseHqFacilityScreen(
            initialState: initialState,
            onStateChanged: onStateChanged,
          ),
        ),
      ),
    );
  }

  testWidgets('renders 5 Service Course departments and Poziom 1-5 roadmap',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final initialState = TeamServiceCourseHqUpgrades.initialState(
      teamName: 'Bora - Test Team',
      availableBudgetEur: 2500000,
    );

    await tester.pumpWidget(buildTestApp(initialState: initialState));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Service Course HQ'), findsOneWidget);
    expect(find.text('Wizualizacja 5 działów Service Course'), findsOneWidget);
    expect(find.text('Poziomy rozbudowy (Poziom 1–5)'), findsOneWidget);
    expect(find.text('Koszty utrzymania i czas inwestycji'), findsOneWidget);

    for (final id in ServiceCourseModuleId.values) {
      expect(find.text(id.shortTitle), findsWidgets);
    }

    for (int level = 1; level <= 5; level++) {
      expect(find.text('Poziom $level'), findsOneWidget);
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'can select department, start upgrade, advance days, and cancel construction',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    TeamServiceCourseHqState latestState =
        TeamServiceCourseHqUpgrades.initialState(
      teamName: 'Test ProTeam',
      availableBudgetEur: 2000000,
    );

    await tester.pumpWidget(
      buildTestApp(
        initialState: latestState,
        onStateChanged: (next) => latestState = next,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Switch to Centrum Hipoksji
    await tester.tap(find.text('Centrum Hipoksji').first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Centrum Hipoksji i Komór Niskociśnieniowych'),
      findsOneWidget,
    );

    // Start upgrade to level 1
    final upgradeBtn = find.textContaining('Rozbuduj do Poziomu 1').first;
    await tester.ensureVisible(upgradeBtn);
    await tester.tap(upgradeBtn);
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      latestState.moduleState(ServiceCourseModuleId.hypoxiaCenter).isUnderConstruction,
      isTrue,
    );
    expect(find.text('Anuluj budowę (zwrot 50%)'), findsOneWidget);

    // Advance by 7 days
    final advance7Btn = find.text('+7 dni').first;
    await tester.ensureVisible(advance7Btn);
    await tester.tap(advance7Btn);
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      latestState
          .moduleState(ServiceCourseModuleId.hypoxiaCenter)
          .remainingConstructionDays,
      lessThan(
        latestState
            .moduleState(ServiceCourseModuleId.hypoxiaCenter)
            .totalConstructionDays,
      ),
    );

    // Cancel construction
    final cancelBtn = find.text('Anuluj budowę (zwrot 50%)').first;
    await tester.ensureVisible(cancelBtn);
    await tester.tap(cancelBtn);
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      latestState.moduleState(ServiceCourseModuleId.hypoxiaCenter).isUnderConstruction,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('disables upgrade when budget is insufficient', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final poorState = TeamServiceCourseHqUpgrades.initialState(
      teamName: 'Budget Team',
      availableBudgetEur: 10000,
    );

    await tester.pumpWidget(buildTestApp(initialState: poorState));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Niewystarczający budżet'), findsOneWidget);

    // Tapping disabled button must not crash or change state
    await tester.tap(find.textContaining('Rozbuduj do Poziomu 1').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'responsive layout without overflow on 390x844, 1024x768, and 1600x900',
      (tester) async {
    const viewports = <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ];

    final state = TeamServiceCourseHqUpgrades.initialState(
      teamName: 'Responsive Cycling Club',
      availableBudgetEur: 5000000,
    );

    for (final size in viewports) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        buildTestApp(initialState: state, size: size),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        tester.takeException(),
        isNull,
        reason: 'Unexpected layout exception at ${size.width}x${size.height}',
      );
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
