import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/events/weather_radar_live_forecast_shift.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

void main() {
  group('WeatherRadarLiveForecastShiftEngine', () {
    const engine = WeatherRadarLiveForecastShiftEngine();

    test('createDemoAlpineStormScenario builds valid route, cells and 4 horizons', () {
      final state = engine.createDemoAlpineStormScenario();
      expect(state.routePoints.length, greaterThan(10));
      expect(state.stormCells.length, 3);
      expect(state.timelineForecast.length, 4);
      expect(
        state.timelineForecast.map((e) => e.minutesAhead).toList(),
        equals([0, 15, 30, 60]),
      );
    });

    test('advanceStormCells moves cells along velocity vector', () {
      final initial = engine.createDemoAlpineStormScenario().stormCells;
      final moved = engine.advanceStormCells(initial, 30.0, raceTimeMinutes: 30.0);
      expect(moved.length, initial.length);
      expect(moved.first.centerXKm, isNot(equals(initial.first.centerXKm)));
      expect(moved.first.centerYKm, isNot(equals(initial.first.centerYKm)));
    });

    test('evaluateImpactAtRouteKm computes rain, grip and crosswind under storm core', () {
      final route = [
        const RadarRoutePoint(
          routeKm: 0.0,
          xKm: 0.0,
          yKm: 0.0,
          elevationM: 500.0,
          roadBearingDegrees: 0.0,
        ),
        const RadarRoutePoint(
          routeKm: 50.0,
          xKm: 0.0,
          yKm: 50.0,
          elevationM: 1200.0,
          roadBearingDegrees: 0.0,
        ),
      ];
      const cell = StormFrontCell(
        id: 'c1',
        name: 'Rdzeń',
        frontType: StormFrontType.convectiveSupercell,
        centerXKm: 0.0,
        centerYKm: 25.0,
        radiusKm: 15.0,
        velocityXKmPerHour: 0.0,
        velocityYKmPerHour: 0.0,
        peakIntensityDbz: 58.0,
        precipitationMmPerHour: 32.0,
        windGustKmh: 55.0,
        windDirectionDeg: 90.0,
        temperatureDropC: 6.0,
      );

      final impact = engine.evaluateImpactAtRouteKm(
        routePoints: route,
        stormCells: const [cell],
        routeKm: 25.0,
        forecastMinutesAhead: 0,
        baseTemperatureC: 22.0,
        baseWindKmh: 12.0,
        baseWindDirectionDeg: 90.0,
      );

      expect(impact.intensity, RadarPrecipitationIntensity.torrentialHail);
      expect(impact.asphaltGripMultiplier, lessThan(0.55));
      expect(impact.crosswindComponentKmh, closeTo(55.0, 1.0));
      expect(impact.activeFrontIds, contains('c1'));
    });

    test('createStateFromStage maps RaceStage segments into radar coordinates', () {
      const stage = RaceStage(
        id: 'st_1',
        stageNumber: 4,
        name: 'Etap 4: Roubaix',
        stageType: StageType.cobbleClassic,
        baseTemperatureCelsius: 14.0,
        weatherCondition: WeatherCondition.heavyStorm,
        windSpeedKmh: 34.0,
        segments: [
          StageSegment(
            index: 0,
            startKm: 0.0,
            lengthKm: 40.0,
            startElevationM: 40.0,
            endElevationM: 60.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 25.0,
            windDirectionDegrees: 270.0,
            roadBearingDegrees: 45.0,
            sprintOrKomClassification: SegmentClassification.none,
          ),
          StageSegment(
            index: 1,
            startKm: 40.0,
            lengthKm: 45.0,
            startElevationM: 60.0,
            endElevationM: 90.0,
            surfaceType: SegmentSurfaceType.cobblestonesSector4,
            technicalDifficulty: 75.0,
            windDirectionDegrees: 280.0,
            roadBearingDegrees: 15.0,
            sprintOrKomClassification: SegmentClassification.finishLine,
          ),
        ],
      );

      final state = engine.createStateFromStage(stage, pelotonKm: 22.0);
      expect(state.stageDistanceKm, closeTo(85.0, 0.01));
      expect(state.routePoints.length, 3);
      expect(state.pelotonKm, 22.0);
    });

    test('StormFrontCell JSON round-trip preserves values', () {
      const cell = StormFrontCell(
        id: 'test_cell',
        name: 'Test',
        frontType: StormFrontType.squallLine,
        centerXKm: 12.5,
        centerYKm: -8.0,
        radiusKm: 16.0,
        velocityXKmPerHour: 30.0,
        velocityYKmPerHour: -15.0,
        peakIntensityDbz: 50.0,
        precipitationMmPerHour: 14.0,
        windGustKmh: 48.0,
        windDirectionDeg: 295.0,
        temperatureDropC: 5.0,
      );
      final decoded = StormFrontCell.fromJson(cell.toJson());
      expect(decoded.id, cell.id);
      expect(decoded.frontType, cell.frontType);
      expect(decoded.centerXKm, cell.centerXKm);
      expect(decoded.peakIntensityDbz, cell.peakIntensityDbz);
    });
  });

  group('WeatherRadarLiveNotifier', () {
    test('tick advances race time and triggerSuddenFrontShift raises alert', () {
      final notifier = WeatherRadarLiveNotifier();
      final initialTime = notifier.state.raceTimeMinutes;
      notifier.tick(5.0);
      expect(notifier.state.raceTimeMinutes, closeTo(initialTime + 5.0, 0.01));

      notifier.triggerSuddenFrontShift();
      expect(
        notifier.state.alertLevel,
        anyOf(WeatherShiftAlertLevel.activeImpact, WeatherShiftAlertLevel.imminent),
      );
      expect(notifier.state.selectedCellId, isNotNull);

      notifier.togglePause();
      expect(notifier.state.isPaused, isTrue);
      final pausedTime = notifier.state.raceTimeMinutes;
      notifier.tick(5.0);
      expect(notifier.state.raceTimeMinutes, pausedTime);
    });
  });

  group('WeatherRadarLiveForecastPanel responsive UI', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: WeatherRadarLiveForecastPanel(
                    enableLiveSimulation: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    }

    testWidgets('renders cleanly without overflow at 390x844 (mobile)',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.text('RADAR BURZOWY LIVE'), findsOneWidget);
      expect(find.text('Przesuń front'), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow at 1024x768 (tablet)',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('PROGNOZA PRZESUNIĘCIA FRONTÓW'), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow at 1600x900 (desktop) and handles interactions',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));

      await tester.tap(find.text('+30 min').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('WARUNKI NA POZYCJI PELETONU (+30 MIN)'),
        findsOneWidget,
      );

      await tester.tap(find.text('Przesuń front'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('PILNE PRZESUNIĘCIE FRONTU'), findsOneWidget);
    });
  });
}
