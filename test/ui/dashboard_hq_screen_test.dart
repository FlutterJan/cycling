import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/services/database/demo_save_preset_builder.dart';
import 'package:pro_peloton_manager/state/career_controller.dart';
import 'package:pro_peloton_manager/ui/screens/dashboard_hq_screen.dart';
import 'package:pro_peloton_manager/ui/widgets/custom_carbon_and_glass_containers.dart';
import 'package:pro_peloton_manager/ui/widgets/cycling_news_feed_widget.dart';
import 'package:pro_peloton_manager/ui/widgets/pro_cycling_stats_table_widget.dart';

class _TestCareerController extends CareerController {
  _TestCareerController(CareerSave save) : super() {
    state = CareerUiState(save: save);
  }
}

void main() {
  late CareerSave testSave;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );
    testSave = await DemoSavePresetBuilder.buildPreset(
      DemoSavePresetType.polishWorldTourProject,
    );
  });

  Widget buildDashboardApp(Size size) {
    return ProviderScope(
      overrides: [
        careerProvider.overrideWith((ref) => _TestCareerController(testSave)),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: const MaterialApp(
          home: Scaffold(
            body: DashboardHqScreen(),
          ),
        ),
      ),
    );
  }

  for (final size in const [
    Size(1600, 900),
    Size(1024, 768),
    Size(390, 844),
  ]) {
    testWidgets(
      'DashboardHqScreen renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildDashboardApp(size));
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(CarbonFiberCard), findsWidgets);
        expect(find.byType(CyclingNewsFeedWidget), findsOneWidget);
        expect(find.byType(ProCyclingStatsTableWidget), findsOneWidget);
        expect(find.text('TRANSFER TICKER'), size.width < 520 ? findsNothing : findsOneWidget);
        expect(find.text('Szybkie Akcje HQ'), findsOneWidget);
        expect(find.text('Stan Kluczowych Liderów'), findsOneWidget);
        expect(find.text('3 GŁÓWNE CELE SEZONOWE'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'DashboardHqScreen toggles PCS startlist view in Nearest Race card',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildDashboardApp(const Size(1600, 900)));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Tabela PCS składu'), findsOneWidget);
      await tester.tap(find.text('Tabela PCS składu'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Widok kafelków'), findsOneWidget);
      expect(find.byType(ProCyclingStatsTableWidget), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
}
