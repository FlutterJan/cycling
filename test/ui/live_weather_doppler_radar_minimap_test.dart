import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/events/weather_radar_live_forecast_shift.dart';
import 'package:pro_peloton_manager/ui/widgets/live_weather_doppler_radar_minimap.dart';

void main() {
  WeatherRadarLiveState buildDemoState({bool withStorms = true}) {
    const engine = WeatherRadarLiveForecastShiftEngine();
    final demo = engine.createDemoAlpineStormScenario();
    if (withStorms) return demo;
    return demo.copyWith(
      stormCells: const [],
      alertLevel: WeatherShiftAlertLevel.clear,
      clearSelectedCell: true,
    );
  }

  Widget wrapForTest(
    Widget child, {
    Size size = const Size(1024, 768),
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('DopplerRadarMinimapSummary', () {
    test('computes max dBZ, wind gust and primary threat cell from state', () {
      final state = buildDemoState();
      final summary = DopplerRadarMinimapSummary.fromState(
        state,
        horizon: RadarForecastHorizon.now,
      );

      expect(summary.activeCellCount, state.stormCells.length);
      expect(summary.maxRouteDbz, greaterThan(0.0));
      expect(summary.maxWindGustKmh, greaterThanOrEqualTo(state.baseWindKmh));
      expect(summary.primaryThreatCell, isNotNull);
    });

    test('handles empty stormCells list gracefully', () {
      final state = buildDemoState(withStorms: false);
      final summary = DopplerRadarMinimapSummary.fromState(
        state,
        horizon: RadarForecastHorizon.plus30m,
      );

      expect(summary.activeCellCount, 0);
      expect(summary.maxRouteDbz, 0.0);
      expect(summary.pelotonIntensity, RadarPrecipitationIntensity.none);
      expect(summary.primaryThreatCell, isNull);
    });
  });

  group('LiveWeatherDopplerRadarMinimap widget', () {
    testWidgets('renders header, horizon pills, layer toggles and telemetry',
        (tester) async {
      final state = buildDemoState();
      RadarForecastHorizon? selectedHorizon;

      await tester.pumpWidget(
        wrapForTest(
          LiveWeatherDopplerRadarMinimap(
            radarState: state,
            animateSweep: false,
            onHorizonChanged: (h) => selectedHorizon = h,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('RADAR DOPPLERA'), findsOneWidget);
      expect(find.text('Teraz'), findsOneWidget);
      expect(find.text('+15 min'), findsOneWidget);
      expect(find.text('+30 min'), findsOneWidget);
      expect(find.text('+60 min'), findsOneWidget);
      expect(find.text('Siatka i Skan'), findsOneWidget);
      expect(find.text('Wektory Frontów'), findsOneWidget);
      expect(find.text('Skala dBZ'), findsOneWidget);

      await tester.tap(find.text('+30 min'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(selectedHorizon, RadarForecastHorizon.plus30m);

      // Toggle legend off
      await tester.tap(find.text('Skala dBZ'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Odbiciowość:'), findsNothing);
    });

    testWidgets('supports compact toggle and disabled state', (tester) async {
      final state = buildDemoState();
      var horizonTapped = false;

      await tester.pumpWidget(
        wrapForTest(
          LiveWeatherDopplerRadarMinimap(
            radarState: state,
            enabled: false,
            animateSweep: false,
            onHorizonChanged: (_) => horizonTapped = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('+15 min'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(horizonTapped, isFalse);
    });

    testWidgets('renders without overflow on 390x844, 1024x768, 1600x900',
        (tester) async {
      final state = buildDemoState();
      const viewports = [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ];

      for (final viewport in viewports) {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          wrapForTest(
            LiveWeatherDopplerRadarMinimap(
              radarState: state,
              animateSweep: true,
            ),
            size: viewport,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          tester.takeException(),
          isNull,
          reason: 'No overflow or exception expected at $viewport',
        );
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
