import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/full_navigation_routes_verifier.dart';
import 'package:pro_peloton_manager/core/router/app_router.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/screens/main_title_menu_screen.dart';
import 'package:pro_peloton_manager/ui/screens/new_career_setup_screen.dart';

void main() {
  group('FullNavigationRoutesVerifier', () {
    test('verifies all 30 AppRouter routes, parameters, 404 and 6 platforms', () {
      const verifier = FullNavigationRoutesVerifier();
      final report = verifier.runAudit();

      expect(report.totalRoutesChecked, 30);
      expect(report.failedRoutes, 0);
      expect(report.duplicatePaths, isEmpty);
      expect(report.duplicateNames, isEmpty);
      expect(report.unregisteredRouterPaths, isEmpty);
      expect(report.error404FallbackPassed, isTrue);
      expect(report.parameterChecksPassed, report.totalParameterChecks);
      expect(report.platformResults.length, NavigationTargetPlatform.values.length);
      expect(report.platformResults.every((p) => p.passed), isTrue);
      expect(report.allPassed, isTrue);

      final decoded = jsonDecode(report.toPrettyJson()) as Map<String, dynamic>;
      expect(decoded['allPassed'], isTrue);
      expect(decoded['totalRoutesChecked'], 30);
    });

    testWidgets('live GoRouter push, query/path params and Back pop work', (
      tester,
    ) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MainTitleMenuScreen), findsOneWidget);

      // Push trasy z parametrem query
      final pushFuture = router.push('${AppRoutes.newCareer}?slot=3');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(NewCareerSetupScreen), findsOneWidget);
      expect(router.canPop(), isTrue);

      // Cofnięcie przyciskiem Wstecz (pop)
      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await pushFuture;
      expect(find.byType(MainTitleMenuScreen), findsOneWidget);
      expect(router.canPop(), isFalse);
    });

    testWidgets(
      'FullNavigationRoutesVerifierPanel renders cleanly at 390x844, 1024x768, 1600x900',
      (tester) async {
        final viewports = <Size>[
          const Size(390, 844),
          const Size(1024, 768),
          const Size(1600, 900),
        ];

        for (final size in viewports) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: FullNavigationRoutesVerifierPanel(),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Weryfikator Nawigacji i Tras AppRouter'), findsOneWidget);
          expect(find.text('WSZYSTKIE TRASY SPRAWNE'), findsOneWidget);
        }

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets('FullNavigationRoutesVerifierPanel filters and searches routes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FullNavigationRoutesVerifierPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Z parametrami'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text(AppRoutes.riderDetail), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'settings');
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text(AppRoutes.settings), findsOneWidget);
      expect(find.text(AppRoutes.riderDetail), findsNothing);
    });
  });
}
