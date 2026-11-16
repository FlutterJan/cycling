import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/global_error_boundary_widget.dart';

void main() {
  group('DiagnosticErrorReport', () {
    test('tworzy czytelny log tekstowy oraz JSON z FlutterErrorDetails', () {
      final details = FlutterErrorDetails(
        exception: StateError('Brak danych telemetrycznych kolarza'),
        stack: StackTrace.fromString('#0 RiderHud.build (rider_hud.dart:42)'),
        library: 'widgets library',
        context: ErrorDescription('podczas budowania RiderHud'),
      );

      final report = DiagnosticErrorReport.fromFlutterError(details);
      final formatted = report.toFormattedLog();
      final jsonText = report.toPrettyJson();

      expect(report.exceptionType, 'StateError');
      expect(report.message, contains('Brak danych telemetrycznych kolarza'));
      expect(formatted, contains('PRO PELOTON MANAGER — DIAGNOSTIC ERROR REPORT'));
      expect(formatted, contains('Exception Type: StateError'));
      expect(formatted, contains('Library: widgets library'));
      expect(formatted, contains('podczas budowania RiderHud'));
      expect(formatted, contains('RiderHud.build'));
      expect(jsonText, contains('"exceptionType": "StateError"'));
    });
  });

  group('GlobalErrorBoundaryWidget', () {
    testWidgets(
      'renderuje bez przepełnień w rozdzielczościach 390x844, 1024x768 i 1600x900',
      (WidgetTester tester) async {
        final sizes = <Size>[
          const Size(390, 844),
          const Size(1024, 768),
          const Size(1600, 900),
        ];

        for (final size in sizes) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            MaterialApp(
              home: GlobalErrorBoundaryWidget(
                errorDetails: FlutterErrorDetails(
                  exception: ArgumentError('Nieprawidłowy profil etapu'),
                  stack: StackTrace.fromString(
                    '#0 StageProfile.paint (stage_profile.dart:112)',
                  ),
                  library: 'rendering library',
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(
            find.text('Wykryto nieoczekiwany błąd renderowania'),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('error_boundary_dashboard_button')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('error_boundary_export_button')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        }

        await tester.binding.setSurfaceSize(null);
      },
    );

    testWidgets(
      'działa poprawnie nawet bez nadrzędnego Directionality i obsługuje akcje',
      (WidgetTester tester) async {
        var returnedToDashboard = false;
        DiagnosticErrorReport? exportedReport;

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(1024, 768)),
            child: GlobalErrorBoundaryWidget(
              error: StateError('Awaria widżetu 3D'),
              stackTrace: StackTrace.fromString('#0 Peloton3d.build (p3d.dart:9)'),
              onReturnToDashboard: () {
                returnedToDashboard = true;
              },
              onExportLog: (DiagnosticErrorReport report) async {
                exportedReport = report;
                return true;
              },
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        // Rozwinięcie sekcji Stack Trace
        expect(find.textContaining('Peloton3d.build'), findsNothing);
        await tester.tap(find.text('Szczegóły techniczne i Stack Trace'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.textContaining('Peloton3d.build'), findsOneWidget);

        // Eksport logu
        await tester.tap(find.byKey(const Key('error_boundary_export_button')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(exportedReport, isNotNull);
        expect(exportedReport!.message, contains('Awaria widżetu 3D'));
        expect(find.text('Log skopiowano'), findsOneWidget);

        // Powrót do Dashboardu
        await tester.tap(
          find.byKey(const Key('error_boundary_dashboard_button')),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(returnedToDashboard, isTrue);

        // Odczekanie na wygaśnięcie timera resetującego status eksportu
        await tester.pump(const Duration(seconds: 3));
      },
    );

    testWidgets(
      'install() i restoreDefaultErrorWidget() podmieniają ErrorWidget.builder',
      (WidgetTester tester) async {
        GlobalErrorBoundaryWidget.install();
        try {
          final built = ErrorWidget.builder(
            FlutterErrorDetails(exception: Exception('TestErrorWidget')),
          );
          expect(built, isA<GlobalErrorBoundaryWidget>());

          await tester.pumpWidget(MaterialApp(home: built));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.textContaining('TestErrorWidget'), findsOneWidget);
        } finally {
          GlobalErrorBoundaryWidget.restoreDefaultErrorWidget();
        }
      },
    );
  });
}
