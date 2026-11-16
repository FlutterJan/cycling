import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/widgets/thermoregulation_and_hydration_hud_gauge.dart';

void main() {
  group('ThermoregulationAndHydrationHudGauge — logika progów', () {
    test('klasyfikuje temperaturę i zmienia kolor powyżej 38.8 °C na pomarańczowy/czerwony', () {
      expect(
        ThermoregulationAndHydrationHudGauge.classifyThermalLevel(37.4),
        ThermoregulationThermalLevel.optimal,
      );
      expect(
        ThermoregulationAndHydrationHudGauge.thermometerColorForTemperature(37.4),
        AppColors.statusSuccess,
      );

      expect(
        ThermoregulationAndHydrationHudGauge.classifyThermalLevel(38.8),
        ThermoregulationThermalLevel.elevated,
      );
      expect(
        ThermoregulationAndHydrationHudGauge.thermometerColorForTemperature(38.8),
        AppColors.accentBlue,
      );

      expect(
        ThermoregulationAndHydrationHudGauge.classifyThermalLevel(38.9),
        ThermoregulationThermalLevel.warning,
      );
      expect(
        ThermoregulationAndHydrationHudGauge.thermometerColorForTemperature(38.9),
        AppColors.amberWarning,
      );

      expect(
        ThermoregulationAndHydrationHudGauge.classifyThermalLevel(39.4),
        ThermoregulationThermalLevel.critical,
      );
      expect(
        ThermoregulationAndHydrationHudGauge.thermometerColorForTemperature(39.4),
        AppColors.crimsonAlert,
      );
    });

    test('normalizuje wartości brzegowe oraz NaN/Infinity', () {
      expect(
        ThermoregulationAndHydrationHudGauge.sanitizeTemperature(double.nan),
        37.4,
      );
      expect(
        ThermoregulationAndHydrationHudGauge.sanitizeTemperature(double.infinity),
        37.4,
      );
      expect(
        ThermoregulationAndHydrationHudGauge.sanitizeTemperature(50.0),
        42.0,
      );
      expect(
        ThermoregulationAndHydrationHudGauge.sanitizeHydration(double.nan),
        100.0,
      );
      expect(
        ThermoregulationAndHydrationHudGauge.sanitizeHydration(-12.0),
        0.0,
      );
      expect(
        ThermoregulationAndHydrationHudGauge.sanitizeHydration(135.0),
        100.0,
      );
    });

    test('klasyfikuje poziomy nawodnienia i dobiera kolory kropli', () {
      expect(
        ThermoregulationAndHydrationHudGauge.classifyHydrationLevel(84.0),
        HydrationStatusLevel.optimal,
      );
      expect(
        ThermoregulationAndHydrationHudGauge.hydrationColorForPercent(84.0),
        AppColors.cyanAccent,
      );

      expect(
        ThermoregulationAndHydrationHudGauge.classifyHydrationLevel(55.0),
        HydrationStatusLevel.moderate,
      );
      expect(
        ThermoregulationAndHydrationHudGauge.hydrationColorForPercent(55.0),
        AppColors.amberWarning,
      );

      expect(
        ThermoregulationAndHydrationHudGauge.classifyHydrationLevel(28.0),
        HydrationStatusLevel.dehydrated,
      );
      expect(
        ThermoregulationAndHydrationHudGauge.hydrationColorForPercent(28.0),
        AppColors.crimsonAlert,
      );
    });
  });

  group('ThermoregulationAndHydrationHudGauge — testy widgetowe i responsywność', () {
    Widget buildTestHost({
      required Size viewportSize,
      required Widget child,
    }) {
      return MediaQuery(
        data: MediaQueryData(size: viewportSize),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets('ikona termometru zmienia kolor na pomarańczowy (38.9 °C) i czerwony (39.5 °C)', (tester) async {
      await tester.pumpWidget(
        buildTestHost(
          viewportSize: const Size(1024, 768),
          child: const SizedBox(
            width: 340,
            child: ThermoregulationAndHydrationHudGauge(
              coreTemperatureCelsius: 38.9,
              hydrationPercent: 78.0,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      Icon thermometerIcon = tester.widget<Icon>(
        find.byKey(const ValueKey<String>('thermoregulation_thermometer_icon')),
      );
      expect(thermometerIcon.color, AppColors.amberWarning);
      expect(find.text('38.9°C'), findsOneWidget);
      expect(find.text('78%'), findsOneWidget);

      await tester.pumpWidget(
        buildTestHost(
          viewportSize: const Size(1024, 768),
          child: const SizedBox(
            width: 340,
            child: ThermoregulationAndHydrationHudGauge(
              coreTemperatureCelsius: 39.5,
              hydrationPercent: 35.0,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      thermometerIcon = tester.widget<Icon>(
        find.byKey(const ValueKey<String>('thermoregulation_thermometer_icon')),
      );
      expect(thermometerIcon.color, AppColors.crimsonAlert);

      final Icon dropIcon = tester.widget<Icon>(
        find.byKey(const ValueKey<String>('hydration_drop_icon')),
      );
      expect(dropIcon.color, AppColors.crimsonAlert);
    });

    testWidgets('obsługuje kliknięcia przycisków Lód na kark i Rozepnij koszulkę oraz stany disabled/hover', (tester) async {
      int iceCount = 0;
      int jerseyCount = 0;

      await tester.pumpWidget(
        buildTestHost(
          viewportSize: const Size(1600, 900),
          child: SizedBox(
            width: 380,
            child: ThermoregulationAndHydrationHudGauge(
              coreTemperatureCelsius: 39.1,
              hydrationPercent: 64.0,
              iceSocksRemaining: 2,
              onIceSockPressed: () => iceCount++,
              onToggleJerseyZipper: () => jerseyCount++,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Lód na kark'), findsOneWidget);
      expect(find.text('Rozepnij koszulkę'), findsOneWidget);
      expect(find.text('(+Chłodzenie / +Opór CdA)'), findsOneWidget);

      // Test hover
      final TestGesture mouseGesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouseGesture.addPointer(location: Offset.zero);
      addTearDown(mouseGesture.removePointer);
      await mouseGesture.moveTo(
        tester.getCenter(find.byKey(const ValueKey<String>('ice_sock_action_button'))),
      );
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.byKey(const ValueKey<String>('ice_sock_action_button')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(iceCount, 1);

      await tester.tap(find.byKey(const ValueKey<String>('jersey_zipper_action_button')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(jerseyCount, 1);

      // Test obsługi klawiatury (focus + Enter)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump(const Duration(milliseconds: 100));

      // Test stanu disabled
      await tester.pumpWidget(
        buildTestHost(
          viewportSize: const Size(1600, 900),
          child: SizedBox(
            width: 380,
            child: ThermoregulationAndHydrationHudGauge(
              coreTemperatureCelsius: 39.1,
              hydrationPercent: 64.0,
              iceSocksRemaining: 0,
              isDisabled: true,
              onIceSockPressed: () => iceCount++,
              onToggleJerseyZipper: () => jerseyCount++,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const ValueKey<String>('ice_sock_action_button')));
      await tester.tap(find.byKey(const ValueKey<String>('jersey_zipper_action_button')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(iceCount, 1);
      expect(jerseyCount, 1);
    });

    for (final Size size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnienia LayoutBuilder w rozdzielczości ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            buildTestHost(
              viewportSize: size,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ThermoregulationAndHydrationHudGauge(
                      coreTemperatureCelsius: 38.9,
                      hydrationPercent: 72.0,
                      isIceSockActive: true,
                      isJerseyUnzipped: true,
                      onIceSockPressed: () {},
                      onToggleJerseyZipper: () {},
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 240,
                      child: ThermoregulationAndHydrationHudGauge(
                        coreTemperatureCelsius: 39.4,
                        hydrationPercent: 39.0,
                        compact: true,
                        onIceSockPressed: () {},
                        onToggleJerseyZipper: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.byType(ThermoregulationAndHydrationHudGauge), findsNWidgets(2));
        },
      );
    }
  });
}
