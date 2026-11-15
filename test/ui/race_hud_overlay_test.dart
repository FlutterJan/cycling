import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/screens/race_hud_overlay.dart';
import 'package:pro_peloton_manager/ui/widgets/group_gaps_chalkboard_widget.dart';
import 'package:pro_peloton_manager/ui/widgets/rider_effort_slider_control.dart';
import 'package:pro_peloton_manager/ui/widgets/tactical_minimap_2d_widget.dart';
import 'package:pro_peloton_manager/ui/widgets/team_tactical_presets_bar.dart';
import 'package:pro_peloton_manager/engine/rendering3d/on_bike_computer_hud_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestHud({
    Size viewportSize = const Size(1600, 900),
    ValueChanged<String>? onRiderSelected,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: viewportSize),
          child: SizedBox(
            width: viewportSize.width,
            height: viewportSize.height,
            child: RaceHudOverlay(
              background: const ColoredBox(color: Color(0xFF0F1115)),
              onRiderSelected: onRiderSelected,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpAndSettleFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  group('RaceHudOverlay - ASO Broadcast & Zwift HUD', () {
    testWidgets('renderuje się poprawnie na 1600x900 bez błędów przepełnienia',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestHud(viewportSize: const Size(1600, 900)));
      await pumpAndSettleFrames(tester);

      expect(find.text('ASO WORLD FEED • LIVE'), findsOneWidget);
      expect(find.text('DRUŻYNA (8)'), findsOneWidget);
      expect(find.text('8x'), findsOneWidget);
      expect(find.text('SKOCZ DO AKCJI'), findsOneWidget);
      expect(find.text('Aero Vision Mode'), findsOneWidget);
      expect(find.byType(TacticalMinimap2dWidget), findsOneWidget);
      expect(find.byType(OnBikeComputerHudWidget), findsOneWidget);
      expect(find.byType(RiderEffortSliderControl), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się poprawnie na 1024x768 (tablet) bez przepełnień',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestHud(viewportSize: const Size(1024, 768)));
      await pumpAndSettleFrames(tester);

      expect(find.text('DRUŻYNA (8)'), findsOneWidget);
      expect(find.byType(OnBikeComputerHudWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się poprawnie na 390x844 (mobile) z domyślnie zwiniętymi panelami',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestHud(viewportSize: const Size(390, 844)));
      await pumpAndSettleFrames(tester);

      // Na wąskim ekranie panel lewy i prawy róg są domyślnie zwinięte, by nie zasłaniać 3D
      expect(find.text('DRUŻYNA (8)'), findsNothing);
      expect(find.text('Aero Vision Mode'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('kliknięcie karty kolarza wybiera go, a zakładki konsoli przełączają się płynnie',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? selectedId;
      await tester.pumpWidget(
        buildTestHud(
          viewportSize: const Size(1600, 900),
          onRiderSelected: (id) => selectedId = id,
        ),
      );
      await pumpAndSettleFrames(tester);

      await tester.tap(find.text('Adam Yates'));
      await pumpAndSettleFrames(tester);
      expect(selectedId, 'rider_demo_2');

      // Rozwiń tablicę Ardoisier
      await tester.tap(find.text('ARDOISIER • RÓŻNICE'));
      await pumpAndSettleFrames(tester);
      expect(find.byType(GroupGapsChalkboardWidget), findsOneWidget);

      // Przełącz zakładkę dolnej konsoli na Taktykę Drużyny
      await tester.tap(find.text('Taktyka Drużyny'));
      await pumpAndSettleFrames(tester);
      expect(find.byType(TeamTacticalPresetsBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
