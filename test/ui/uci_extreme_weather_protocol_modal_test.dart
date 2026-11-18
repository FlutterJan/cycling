import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/events/race_protest_and_course_reroute_engine.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/ui/widgets/uci_extreme_weather_protocol_modal.dart';

RaceStage _buildAlpineStage() {
  return const RaceStage(
    id: 'stage_gavia_test',
    stageNumber: 16,
    name: 'Lovere — Passo di Gavia',
    stageType: StageType.highMountain,
    baseTemperatureCelsius: 6.0,
    weatherCondition: WeatherCondition.heavyStorm,
    windSpeedKmh: 45.0,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 60.0,
        startElevationM: 210.0,
        endElevationM: 680.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 15.0,
        windDirectionDegrees: 270.0,
        roadBearingDegrees: 350.0,
        sprintOrKomClassification: SegmentClassification.intermediateSprint,
      ),
      StageSegment(
        index: 1,
        startKm: 60.0,
        lengthKm: 35.0,
        startElevationM: 680.0,
        endElevationM: 2621.0,
        surfaceType: SegmentSurfaceType.roughAsphalt,
        technicalDifficulty: 62.0,
        windDirectionDegrees: 290.0,
        roadBearingDegrees: 10.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      ),
      StageSegment(
        index: 2,
        startKm: 95.0,
        lengthKm: 30.0,
        startElevationM: 2621.0,
        endElevationM: 1225.0,
        surfaceType: SegmentSurfaceType.roughAsphalt,
        technicalDifficulty: 78.0,
        windDirectionDegrees: 300.0,
        roadBearingDegrees: 30.0,
        sprintOrKomClassification: SegmentClassification.finishLine,
      ),
    ],
  );
}

UciExtremeWeatherCommuniqueData _buildBlizzardData() {
  const engine = RaceProtestAndCourseRerouteEngine();
  final stage = _buildAlpineStage();
  final telemetry = ExtremeWeatherTelemetryInput(
    stage: stage,
    currentRaceKm: 42.0,
    airTemperatureCelsius: 3.5,
    summitTemperatureCelsius: -4.0,
    windGustKmh: 68.0,
    precipitationMmPerHour: 7.5,
    visibilityMeters: 75.0,
    iceOnRoadSurface: true,
    pelotonColdStressIndex: 0.82,
    cpaRepresentativeSupport: 0.78,
  );
  final eval = engine.evaluateExtremeWeather(telemetry);
  final reroute = engine.applyDynamicCourseReroute(
    stage: stage,
    currentRaceKm: 42.0,
    action: CourseRerouteAction.relocateFinishLower,
  );
  return UciExtremeWeatherCommuniqueData.fromEngineResults(
    evaluation: eval,
    rerouteResult: reroute,
    telemetry: telemetry,
    managerVoteStance: RiderProtestStance.protestShorten,
  );
}

void main() {
  group('UciExtremeWeatherCommuniqueData', () {
    test('serializes and deserializes cleanly to/from JSON', () {
      final original = _buildBlizzardData();
      final decoded =
          UciExtremeWeatherCommuniqueData.fromJson(original.toJson());

      expect(decoded.communiqueNumber, original.communiqueNumber);
      expect(decoded.stageName, original.stageName);
      expect(decoded.evaluation.hazardType, original.evaluation.hazardType);
      expect(decoded.evaluation.triggerLevel, original.evaluation.triggerLevel);
      expect(decoded.managerVoteStance, RiderProtestStance.protestShorten);

      final bulletin = original.formatOfficialBulletinText();
      expect(bulletin, contains('Art. 2.2.029bis'));
      expect(bulletin, contains('Lovere — Passo di Gavia'));
    });
  });

  group('UciExtremeWeatherProtocolModal', () {
    testWidgets('renders blizzard and landslide communiques and switches tabs',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final data = _buildBlizzardData();
      RiderProtestStance? submittedVote;
      CourseRerouteAction? confirmedReroute;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: UciExtremeWeatherProtocolModal(
              data: data,
              onSubmitVote: (stance) => submittedVote = stance,
              onConfirmReroute: (action) => confirmedReroute = action,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('OFICJALNY KOMUNIKAT UCI'), findsOneWidget);
      expect(find.textContaining('TRASA PIERWOTNA'), findsOneWidget);
      expect(find.textContaining('NOWA TRASA'), findsOneWidget);

      await tester.tap(find.text('Trasa i Profil'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('PORÓWNANIE PROFILU WYSOKOŚCIOWEGO'), findsOneWidget);

      await tester.tap(find.text('CPA i Przepisy'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('URUCHOMIONE KRYTERIA PROTOKOŁU UCI'), findsOneWidget);

      await tester.tap(find.text(RiderProtestStance.cautionRequested.labelPl));
      await tester.pump(const Duration(milliseconds: 300));
      expect(submittedVote, RiderProtestStance.cautionRequested);

      final applyFinder = find.textContaining('Zastosuj:');
      expect(applyFinder, findsOneWidget);
      await tester.tap(applyFinder);
      await tester.pump(const Duration(milliseconds: 300));
      expect(confirmedReroute, isNotNull);
    });

    testWidgets('respects isReadOnly and handles empty segments gracefully',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const emptyStage = RaceStage(
        id: 'empty_stage',
        stageNumber: 5,
        name: 'Etap Osuwiskowy',
        stageType: StageType.hilly,
        baseTemperatureCelsius: 12.0,
        weatherCondition: WeatherCondition.heavyStorm,
        windSpeedKmh: 20.0,
        segments: [],
      );
      const engine = RaceProtestAndCourseRerouteEngine();
      const telemetry = ExtremeWeatherTelemetryInput(
        stage: emptyStage,
        currentRaceKm: 15.0,
        airTemperatureCelsius: 12.0,
        summitTemperatureCelsius: 8.0,
        windGustKmh: 25.0,
        precipitationMmPerHour: 10.0,
        visibilityMeters: 300.0,
        hasLandslideReport: true,
        landslideKm: 48.0,
      );
      final eval = engine.evaluateExtremeWeather(telemetry);
      final data = UciExtremeWeatherCommuniqueData.fromEngineResults(
        evaluation: eval,
        telemetry: telemetry,
      );

      RiderProtestStance? submittedVote;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: UciExtremeWeatherProtocolModal(
              data: data,
              isReadOnly: true,
              onSubmitVote: (s) => submittedVote = s,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Trasa i Profil'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.textContaining('Zmiana trasy nie została jeszcze wygenerowana'),
        findsOneWidget,
      );

      await tester.tap(find.text('CPA i Przepisy'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text(RiderProtestStance.refuseToStartOrContinue.labelPl));
      await tester.pump(const Duration(milliseconds: 300));
      expect(submittedVote, isNull);
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without RenderFlex overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          final data = _buildBlizzardData();
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(
                body: UciExtremeWeatherProtocolModal(
                  data: data,
                  onConfirmReroute: (_) {},
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
