import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/ui/widgets/elevation_profile_chart.dart';
import 'package:pro_peloton_manager/ui/widgets/interactive_stage_timeline_scrubber.dart';

void main() {
  final sampleEvents = <StageTimelineEvent>[
    const StageTimelineEvent(
      id: 'ev_attack',
      type: StageTimelineEventType.attack,
      kilometer: 28.5,
      raceTimeLabel: '12:45',
      title: 'Atak w ucieczce',
      description: '3 kolarzy odjeżdża od peletonu na płaskim odcinku.',
    ),
    const StageTimelineEvent(
      id: 'ev_feed',
      type: StageTimelineEventType.feedZone,
      kilometer: 72.0,
      raceTimeLabel: '13:38',
      title: 'Strefa bufetu',
      description: 'Pobranie bidonów i żeli przez liderów zespołu.',
    ),
    const StageTimelineEvent(
      id: 'ev_mech',
      type: StageTimelineEventType.mechanical,
      kilometer: 94.6,
      raceTimeLabel: '14:09',
      title: 'Defekt tylnego koła',
      description: 'Szybka wymiana koła przez wóz techniczny.',
    ),
    const StageTimelineEvent(
      id: 'ev_crash',
      type: StageTimelineEventType.crash,
      kilometer: 114.2,
      raceTimeLabel: '14:32',
      title: 'Kraksa w peletonie',
      description: 'Kraksa w środku peletonu (12 kolarzy zatrzymanych)',
      gcImpactSeconds: 48,
      isDecisiveGcMoment: true,
    ),
    const StageTimelineEvent(
      id: 'ev_kom',
      type: StageTimelineEventType.komResult,
      kilometer: 158.0,
      raceTimeLabel: '15:44',
      title: 'Premia górska HC',
      description: 'Lider GC zdobywa komplet punktów na szczycie Col du Galibier.',
      gcImpactSeconds: -32,
      isDecisiveGcMoment: true,
    ),
  ];

  const sampleStage = RaceStage(
    id: 'stage_test_1',
    stageNumber: 12,
    name: 'Etap Królewski',
    stageType: StageType.highMountain,
    baseTemperatureCelsius: 21.0,
    weatherCondition: WeatherCondition.sunny,
    windSpeedKmh: 12.0,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 90.0,
        startElevationM: 400.0,
        endElevationM: 650.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 20.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 1,
        startKm: 90.0,
        lengthKm: 90.0,
        startElevationM: 650.0,
        endElevationM: 2100.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 55.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      ),
    ],
  );

  Widget wrapWithApp(Widget child, {Size size = const Size(1024, 768)}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          backgroundColor: const Color(0xFF0F1115),
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders only events up to currentKm in live mode and displays all 5 icon types in summary mode',
      (tester) async {
    await tester.pumpWidget(
      wrapWithApp(
        InteractiveStageTimelineScrubber(
          totalDistanceKm: 180.0,
          currentKm: 100.0,
          events: sampleEvents,
          isSummaryMode: false,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('OŚ CZASU ETAPU'), findsOneWidget);
    // Do km 100.0 widoczne są: atak (28.5), bufet (72.0), defekt (94.6)
    expect(find.byTooltip(sampleEvents[0].formattedTooltipText), findsOneWidget);
    expect(find.byTooltip(sampleEvents[1].formattedTooltipText), findsOneWidget);
    expect(find.byTooltip(sampleEvents[2].formattedTooltipText), findsOneWidget);
    // Kraksa (114.2) i KOM (158.0) jeszcze się nie wydarzyły
    expect(find.byTooltip(sampleEvents[3].formattedTooltipText), findsNothing);
    expect(find.byTooltip(sampleEvents[4].formattedTooltipText), findsNothing);

    // Tryb podsumowania pokazuje wszystkie 5 wydarzeń i ich ikony
    await tester.pumpWidget(
      wrapWithApp(
        InteractiveStageTimelineScrubber(
          totalDistanceKm: 180.0,
          currentKm: 180.0,
          events: sampleEvents,
          isSummaryMode: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ANALIZA OSI CZASU GC'), findsOneWidget);
    for (final ev in sampleEvents) {
      expect(find.byTooltip(ev.formattedTooltipText), findsOneWidget);
    }
    expect(find.byIcon(Icons.bolt_rounded), findsAtLeastNWidgets(2));
    expect(find.byIcon(Icons.build_rounded), findsAtLeastNWidgets(2));
    expect(find.byIcon(Icons.warning_amber_rounded), findsAtLeastNWidgets(2));
    expect(find.byIcon(Icons.landscape_rounded), findsAtLeastNWidgets(2));
    expect(find.byIcon(Icons.local_drink_rounded), findsAtLeastNWidgets(2));
  });

  testWidgets('tooltip contains exact km, time and description and tapping event updates scrubbedKm',
      (tester) async {
    double? latestKm;
    StageTimelineEvent? selectedEvent;

    await tester.pumpWidget(
      wrapWithApp(
        InteractiveStageTimelineScrubber(
          totalDistanceKm: 180.0,
          currentKm: 180.0,
          events: sampleEvents,
          isSummaryMode: true,
          onScrubKmChanged: (km) => latestKm = km,
          onEventSelected: (ev) => selectedEvent = ev,
        ),
      ),
    );
    await tester.pump();

    final crashTooltip = find.byWidgetPredicate(
      (widget) =>
          widget is Tooltip &&
          (widget.message?.contains('Km 114.2 (14:32): Kraksa w środku peletonu (12 kolarzy zatrzymanych)') ??
              false),
    );
    expect(crashTooltip, findsOneWidget);

    await tester.tap(crashTooltip);
    await tester.pump();

    expect(latestKm, closeTo(114.2, 0.01));
    expect(selectedEvent?.id, 'ev_crash');
    expect(find.text('ROZSTRZYGNIĘCIE GC'), findsOneWidget);
  });

  testWidgets('StageProfileWithTimelineScrubber renders scrubber above ElevationProfileChart without overflow across viewports',
      (tester) async {
    for (final viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        wrapWithApp(
          SingleChildScrollView(
            child: StageProfileWithTimelineScrubber(
              stage: sampleStage,
              events: sampleEvents,
              currentLeadKm: 120.0,
              isSummaryMode: true,
              chartHeight: 200,
            ),
          ),
          size: viewport,
        ),
      );
      await tester.pump();

      expect(find.byType(InteractiveStageTimelineScrubber), findsOneWidget);
      expect(find.byType(ElevationProfileChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
