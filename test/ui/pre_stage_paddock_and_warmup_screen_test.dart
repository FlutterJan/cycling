import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/team/team_bus_and_warmup_protocol_model.dart';
import 'package:pro_peloton_manager/ui/screens/pre_stage_paddock_and_warmup_screen.dart';

void main() {
  Future<void> pumpScreenAtSize(
    WidgetTester tester, {
    required Size size,
    TeamBusAndWarmupProtocolModel? initialModel,
    bool isReadOnly = false,
    ValueChanged<TeamBusAndWarmupProtocolModel>? onModelChanged,
    ValueChanged<TeamBusAndWarmupProtocolModel>? onProceedToStart,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: PreStagePaddockAndWarmupScreen(
          initialModel: initialModel,
          autoPlay3d: false,
          isReadOnly: isReadOnly,
          onModelChanged: onModelChanged,
          onProceedToStart: onProceedToStart,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('PreStagePaddockAndWarmupScreen responsiveness', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await pumpScreenAtSize(tester, size: size);

          expect(find.byType(PreStagePaddockAndWarmupScreen), findsOneWidget);
          expect(find.text('Pre-Cooling Ice Vest + Slushie'), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('PreStagePaddockAndWarmupScreen interactions', () {
    testWidgets('updates protocol and Pre-Cooling Ice Vest for selected rider',
        (tester) async {
      TeamBusAndWarmupProtocolModel? latestModel;

      await pumpScreenAtSize(
        tester,
        size: const Size(1600, 900),
        onModelChanged: (model) => latestModel = model,
      );

      // Select second rider (starts with progressiveRamp and fanAndColdTowels).
      await tester.tap(find.text('L. Van Der Berg'));
      await tester.pump(const Duration(milliseconds: 300));

      final vo2Name =
          WarmupProtocolPreset.fromType(WarmupProtocolType.vo2PrimingItt).namePl;
      final vo2Finder = find.text(vo2Name).last;
      await tester.ensureVisible(vo2Finder);
      await tester.tap(vo2Finder);
      await tester.pump(const Duration(milliseconds: 300));

      expect(latestModel, isNotNull);
      expect(
        latestModel!.assignments[1].protocolType,
        WarmupProtocolType.vo2PrimingItt,
      );

      final iceVestFinder = find.text('Pre-Cooling Ice Vest + Slushie').last;
      await tester.ensureVisible(iceVestFinder);
      await tester.tap(iceVestFinder);
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        latestModel!.assignments[1].coolingStrategy,
        CoolingStrategyType.preCoolingIceVest,
      );
    });

    testWidgets(
        'disables Pre-Cooling Ice Vest when bus tier has no freezer (Continental)',
        (tester) async {
      TeamBusAndWarmupProtocolModel? latestModel;

      await pumpScreenAtSize(
        tester,
        size: const Size(1600, 900),
        onModelChanged: (model) => latestModel = model,
      );

      await tester.tap(find.text('2 stan. (1★)'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Brak zamrażarki Ice Vest'), findsOneWidget);
      expect(find.text('Wymaga autokaru WorldTour'), findsOneWidget);

      final iceVestFinder = find.text('Pre-Cooling Ice Vest + Slushie').last;
      await tester.ensureVisible(iceVestFinder);
      await tester.tap(iceVestFinder);
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        latestModel!.assignments.first.coolingStrategy,
        isNot(CoolingStrategyType.preCoolingIceVest),
      );
    });

    testWidgets('Auto-Optymalizuj and Start KM 0.0 callbacks fire',
        (tester) async {
      TeamBusAndWarmupProtocolModel? startedModel;

      await pumpScreenAtSize(
        tester,
        size: const Size(1600, 900),
        onProceedToStart: (model) => startedModel = model,
      );

      await tester.tap(find.text('Auto-Optymalizuj'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Start KM 0.0'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(startedModel, isNotNull);
      expect(
        startedModel!.assignments.every(
          (a) => a.protocolType == WarmupProtocolType.vo2PrimingItt,
        ),
        isTrue,
      );
    });

    testWidgets('respects isReadOnly and empty assignments state',
        (tester) async {
      TeamBusAndWarmupProtocolModel? changedModel;
      final emptyModel = PreStagePaddockAndWarmupScreen.buildDefaultModel()
          .copyWith(assignments: const []);

      await pumpScreenAtSize(
        tester,
        size: const Size(1024, 768),
        initialModel: emptyModel,
        isReadOnly: true,
        onModelChanged: (model) => changedModel = model,
      );

      expect(
        find.text('Brak przypisanych kolarzy na trenażerach w paddocku.'),
        findsWidgets,
      );

      await tester.tap(find.text('2 stan. (1★)'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(changedModel, isNull);
    });
  });
}
