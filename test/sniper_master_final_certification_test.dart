import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/sniper_master_final_certification.dart';

void main() {
  group('SniperMasterFinalCertification', () {
    test('parses and verifies all 312 tasks from docs/QUEUE.md', () async {
      const certification = SniperMasterFinalCertification();
      final report = await certification.runCertification(
        runFlutterAnalyze: false,
        runFlutterTest: false,
      );

      expect(report.totalTasksChecked, 312);
      expect(report.packageSummaries.length, 4);
      final sumTasks = report.packageSummaries.fold<int>(
        0,
        (sum, item) => sum + item.totalTasks,
      );
      expect(sumTasks, 312);
      expect(report.codeMapResult.exists, isTrue);
      expect(report.toMarkdownSummary(), contains('312'));
      expect(report.toJson()['targetTasksCount'], 312);
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'SniperMasterFinalCertificationPanel renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
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
                  body: SniperMasterFinalCertificationPanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Uruchom Certyfikację'), findsOneWidget);
          expect(find.text('flutter analyze'), findsOneWidget);
          expect(find.text('flutter test'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
