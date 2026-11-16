import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_simulation_loop.dart';
import 'package:pro_peloton_manager/ui/widgets/mobile_one_handed_thumb_hud_mode.dart';
import 'package:pro_peloton_manager/ui/widgets/rider_effort_slider_control.dart';

void main() {
  Widget buildTestApp(Widget child, {Size size = const Size(390, 844)}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }

  group('MobileOneHandedThumbHudMode', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildTestApp(const MobileOneHandedThumbHudMode(), size: size),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(MobileOneHandedThumbHudMode), findsOneWidget);
        expect(find.byKey(const Key('thumb_effort_slider')), findsOneWidget);
        expect(find.byKey(const Key('thumb_telemetry_collapse_btn')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('collapses and expands top telemetry bar', (tester) async {
      bool? lastCollapsed;
      await tester.pumpWidget(
        buildTestApp(
          MobileOneHandedThumbHudMode(
            onTelemetryCollapsedChanged: (collapsed) {
              lastCollapsed = collapsed;
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tour de France — Col du Galibier'), findsOneWidget);

      await tester.tap(find.byKey(const Key('thumb_telemetry_collapse_btn')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(lastCollapsed, isTrue);
      expect(find.text('24.6 km • 8.2% • 28.4 km/h'), findsOneWidget);

      await tester.tap(find.byKey(const Key('thumb_telemetry_collapse_btn')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(lastCollapsed, isFalse);
    });

    testWidgets(
        'selects rider, issues tactical order, adjusts power, aero and nutrition',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? selectedRider;
      String? orderedRider;
      TacticalOrder? issuedOrder;
      double? updatedEffort;
      RiderAeroPosition? updatedAero;
      String? gelRider;
      String? bidonRider;
      ThumbHandedness? handedness;
      SimulationTimeSpeed? selectedSpeed;
      bool pausedToggled = false;

      await tester.pumpWidget(
        buildTestApp(
          MobileOneHandedThumbHudMode(
            onRiderSelected: (id) => selectedRider = id,
            onOrderIssued: (id, order) {
              orderedRider = id;
              issuedOrder = order;
            },
            onEffortChanged: (_, effort) => updatedEffort = effort,
            onAeroPositionChanged: (_, pos) => updatedAero = pos,
            onFeedGel: (id) => gelRider = id,
            onFeedBidon: (id) => bidonRider = id,
            onHandednessChanged: (h) => handedness = h,
            onSpeedSelected: (s) => selectedSpeed = s,
            onTogglePause: () => pausedToggled = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('thumb_rider_r2')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(selectedRider, 'r2');

      await tester.tap(find.byKey(const Key('thumb_order_attack')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(orderedRider, 'r2');
      expect(issuedOrder, TacticalOrder.attack);
      expect(updatedEffort, 118.0);

      await tester.tap(find.byKey(const Key('thumb_power_minus')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(updatedEffort, 113.0);

      await tester.tap(
        find.byKey(const Key('thumb_aero_aggressiveAero')),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(updatedAero, RiderAeroPosition.aggressiveAero);

      await tester.tap(find.byKey(const Key('thumb_feed_gel')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(gelRider, 'r2');

      await tester.tap(find.byKey(const Key('thumb_feed_bidon')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(bidonRider, 'r2');

      await tester.tap(find.byKey(const Key('thumb_handedness_toggle')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(handedness, ThumbHandedness.leftHanded);

      await tester.tap(find.byKey(const Key('thumb_speed_x4')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(selectedSpeed, SimulationTimeSpeed.x4);

      await tester.tap(find.byKey(const Key('thumb_pause_toggle')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(pausedToggled, isTrue);
    });

    testWidgets('respects disabled state and empty riders list', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestApp(
          MobileOneHandedThumbHudMode(
            isEnabled: false,
            riders: const [],
            onOrderIssued: (_, __) => tapped = true,
            onTogglePause: () => tapped = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Brak kolarzy w składzie etapu.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('thumb_pause_toggle')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tapped, isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}
