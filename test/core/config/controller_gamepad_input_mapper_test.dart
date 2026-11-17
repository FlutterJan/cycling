import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/config/controller_gamepad_input_mapper.dart';

void main() {
  group('GamepadHardwareProfile detection & glyphs', () {
    test('detects Xbox, DualSense and Steam Deck by name and vendorId', () {
      expect(
        GamepadHardwareProfile.detectFromDeviceName('Xbox Wireless Controller'),
        GamepadHardwareProfile.xboxSeries,
      );
      expect(
        GamepadHardwareProfile.detectFromDeviceName(
          'DualSense Wireless Controller',
        ),
        GamepadHardwareProfile.playStationDualSense,
      );
      expect(
        GamepadHardwareProfile.detectFromDeviceName('Valve Steam Deck',
            vendorId: 0x28DE),
        GamepadHardwareProfile.steamDeck,
      );
      expect(
        GamepadHardwareProfile.detectFromDeviceName('Unknown Pad',
            vendorId: 0x054C),
        GamepadHardwareProfile.playStationDualSense,
      );
    });

    test('returns console-authentic glyphs for Xbox, DualSense and Steam Deck',
        () {
      expect(
        GamepadLogicalButton.south
            .glyphFor(GamepadHardwareProfile.xboxSeries)
            .symbol,
        'A',
      );
      expect(
        GamepadLogicalButton.south
            .glyphFor(GamepadHardwareProfile.playStationDualSense)
            .symbol,
        '✕',
      );
      expect(
        GamepadLogicalButton.north
            .glyphFor(GamepadHardwareProfile.playStationDualSense)
            .symbol,
        '△',
      );
      expect(
        GamepadLogicalButton.paddleL4
            .glyphFor(GamepadHardwareProfile.steamDeck)
            .symbol,
        'L4',
      );
    });
  });

  group('ControllerGamepadInputMapper math & processing', () {
    test('radial deadzone zeroes small drift and rescales outside deadzone', () {
      final inside = ControllerGamepadInputMapper.applyRadialDeadzoneAndCurve(
        rawX: 0.05,
        rawY: 0.05,
        deadzone: 0.12,
        curveExponent: 1.5,
      );
      expect(inside, Offset.zero);

      final maxEdge = ControllerGamepadInputMapper.applyRadialDeadzoneAndCurve(
        rawX: 1.0,
        rawY: 0.0,
        deadzone: 0.12,
        curveExponent: 1.5,
      );
      expect(maxEdge.dx, closeTo(1.0, 0.001));
      expect(maxEdge.dy, closeTo(0.0, 0.001));
    });

    test('DualSense adaptive triggers respond to cobbles and steep climbs', () {
      final xboxResult =
          ControllerGamepadInputMapper.computeDualSenseTriggerModes(
        profile: GamepadHardwareProfile.xboxSeries,
        adaptiveTriggersEnabled: true,
        cobbleStars: 5,
        gradientPercent: 14.0,
        isWetRoad: true,
        riderFatiguePercent: 85.0,
      );
      expect(xboxResult.left, DualSenseTriggerResistanceMode.off);
      expect(xboxResult.right, DualSenseTriggerResistanceMode.off);

      final ps5Result =
          ControllerGamepadInputMapper.computeDualSenseTriggerModes(
        profile: GamepadHardwareProfile.playStationDualSense,
        adaptiveTriggersEnabled: true,
        cobbleStars: 5,
        gradientPercent: 14.0,
        isWetRoad: false,
        riderFatiguePercent: 85.0,
      );
      expect(ps5Result.left, DualSenseTriggerResistanceMode.cobbleFeedback);
      expect(
        ps5Result.right,
        DualSenseTriggerResistanceMode.steepClimbResistance,
      );
    });

    test('processFrame computes rising/falling button edges and gyro steering',
        () {
      const mapper = ControllerGamepadInputMapper();
      final bindings = ControllerGamepadInputMapper.defaultBindingsFor(
        GamepadControlPreset.steamDeckHandheld,
      );
      const config = GamepadDeadzoneAndCurveConfig(
        leftStickDeadzone: 0.10,
        rightStickDeadzone: 0.10,
        invertCameraY: true,
        enableGyroDescentSteering: true,
      );

      final output = mapper.processFrame(
        rawFrame: const GamepadRawInputFrame(
          leftStickX: 0.0,
          rightStickY: 0.5,
          gyroRollRad: 0.4,
          pressedButtons: {GamepadLogicalButton.paddleR4},
        ),
        previousFrame: const GamepadRawInputFrame(
          pressedButtons: {GamepadLogicalButton.south},
        ),
        profile: GamepadHardwareProfile.steamDeck,
        config: config,
        bindings: bindings,
      );

      expect(output.lateralSteerNormalized, greaterThan(0.15));
      expect(output.cameraOrbitY, lessThan(0.0));
      expect(
        output.justTriggeredActions,
        contains(CyclingGamepadAction.gearShiftUp),
      );
      expect(
        output.justReleasedActions,
        contains(CyclingGamepadAction.snapToWheel),
      );
    });
  });

  group('ControllerGamepadMapperNotifier', () {
    test('switches hardware profile and remaps buttons without conflicts', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(controllerGamepadMapperProvider.notifier);

      notifier.selectHardwareProfile(GamepadHardwareProfile.steamDeck);
      var state = container.read(controllerGamepadMapperProvider);
      expect(state.activeProfile, GamepadHardwareProfile.steamDeck);
      expect(state.activePreset, GamepadControlPreset.steamDeckHandheld);

      notifier.remapButton(
        GamepadLogicalButton.south,
        CyclingGamepadAction.gearShiftUp,
      );
      state = container.read(controllerGamepadMapperProvider);
      expect(
        state.bindings[GamepadLogicalButton.south],
        CyclingGamepadAction.gearShiftUp,
      );
      expect(
        state.bindings[GamepadLogicalButton.paddleR4],
        CyclingGamepadAction.snapToWheel,
      );
    });
  });

  group('ControllerGamepadMapperPanel responsive UI', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ControllerGamepadMapperPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844 mobile without overflow',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.text('Kontrolery i Mapowanie Wejścia'), findsOneWidget);
      expect(find.text('DualSense'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1024x768 tablet without overflow',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('Profil Sprzętowy Kontrolera'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1600x900 desktop and switches profile',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      await tester.tap(find.text('DualSense'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Adaptacyjne spusty DualSense (L2/R2)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
