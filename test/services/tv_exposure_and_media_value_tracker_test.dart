import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/services/career/tv_exposure_and_media_value_tracker.dart';

void main() {
  group('TvExposureAndMediaValueTracker', () {
    test('zlicza sekundy z ucieczki, peletonu, ataku w górach i podium oraz wylicza M EUR', () {
      final tracker = TvExposureAndMediaValueTracker();

      // 1. Jazda w ucieczce dnia: 1000s (mnożnik 1.20 => 1200 ważonych s)
      tracker.recordSimulationTick(
        deltaSeconds: 1000,
        isInBreakaway: true,
        activeRiderName: 'M. Kwiatkowski',
      );

      // 2. Prowadzenie peletonu przez 3 kolarzy: 500s (1.00 * (1 + 0.44) = 720 ważonych s)
      tracker.recordSimulationTick(
        deltaSeconds: 500,
        isPullingPeloton: true,
        visibleTeamRidersCount: 3,
        activeRiderName: 'R. Majka',
      );

      // 3. Atak w górach: 200s (1.65 * 1.35 closeUp = 445.5 ważonych s)
      tracker.recordSimulationTick(
        deltaSeconds: 200,
        isMountainAttacking: true,
        activeRiderName: 'R. Majka',
      );

      // 4. Dekoracja na podium w koszulce lidera: 120s (2.40 * 1.35 * 1.25 = 486 ważonych s)
      tracker.recordPodiumCeremony(
        durationSeconds: 120,
        riderName: 'R. Majka',
        hasLeaderJersey: true,
      );

      expect(tracker.currentStageRawSeconds, closeTo(1820.0, 0.001));
      expect(tracker.currentStageWeightedSeconds, closeTo(2851.5, 0.001));

      final previewMillions = tracker.previewCurrentStageMediaValueMillionsEur(
        raceCategory: RaceCategory.grandTour,
      );
      // 2851.5 * 1650 EUR = 4,704,975 EUR = 4.704975 M EUR
      expect(previewMillions, closeTo(4.704975, 0.0001));

      final report = tracker.finalizeStageReport(
        stageId: 'tdf_s15',
        raceName: 'Tour de France - Etap 15',
        raceCategory: RaceCategory.grandTour,
        sponsorName: 'Orlen Aero',
      );

      expect(report.totalRawSeconds, closeTo(1820.0, 0.001));
      expect(report.totalAdvertisingValueMillionsEur, closeTo(4.704975, 0.0001));
      expect(report.topExposedRiderName, 'M. Kwiatkowski');
      expect(
        report.sourceBreakdowns[TvCameraExposureSource.breakawayOfTheDay]?.rawSeconds,
        closeTo(1000.0, 0.001),
      );
      expect(
        report.sourceBreakdowns[TvCameraExposureSource.podiumCeremony]?.rawSeconds,
        closeTo(120.0, 0.001),
      );

      // Po finalizacji z resetAfterFinalize=true liczniki bieżącego etapu są wyzerowane
      expect(tracker.currentStageRawSeconds, 0.0);
      expect(tracker.seasonHistory.length, 1);
    });

    test('obsługuje wartości brzegowe i serializację JSON', () {
      final tracker = TvExposureAndMediaValueTracker();

      tracker.recordSimulationTick(deltaSeconds: -10, isInBreakaway: true);
      tracker.recordSimulationTick(deltaSeconds: double.nan, isPullingPeloton: true);
      tracker.recordSample(
        const TvExposureCameraSample(
          source: TvCameraExposureSource.mountainAttack,
          durationSeconds: 0,
        ),
      );

      expect(tracker.currentStageRawSeconds, 0.0);

      tracker.recordSample(
        const TvExposureCameraSample(
          source: TvCameraExposureSource.sprintFinish,
          durationSeconds: 60,
          visibleTeamRidersCount: 2,
          riderName: 'O. Kooij',
        ),
      );

      final report = tracker.finalizeStageReport(
        stageId: 'paris_roubaix',
        raceName: 'Paris-Roubaix',
        raceCategory: RaceCategory.monument,
        sponsorName: 'Visma Lab',
      );

      final json = report.toJson();
      final decoded = StageTvExposureReport.fromJson(json);

      expect(decoded.stageId, report.stageId);
      expect(decoded.raceCategory, RaceCategory.monument);
      expect(
        decoded.totalAdvertisingValueMillionsEur,
        closeTo(report.totalAdvertisingValueMillionsEur, 0.00001),
      );
      expect(decoded.topExposedRiderName, 'O. Kooij');
    });

    test('agreguje sezon i ocenia klasę ROI sponsora', () {
      final tracker = TvExposureAndMediaValueTracker();

      tracker.recordSimulationTick(deltaSeconds: 1200, isInBreakaway: true);
      final r1 = tracker.finalizeStageReport(
        stageId: 's1',
        raceName: 'Tour de France',
        raceCategory: RaceCategory.grandTour,
        sponsorName: 'Apex Energy',
      );

      tracker.recordSimulationTick(deltaSeconds: 800, isMountainAttacking: true);
      final r2 = tracker.finalizeStageReport(
        stageId: 's2',
        raceName: 'Tour de France',
        raceCategory: RaceCategory.grandTour,
        sponsorName: 'Apex Energy',
      );

      final summary = TvExposureAndMediaValueTracker.aggregateSeasonMediaValue(
        sponsorName: 'Apex Energy',
        annualSponsorBudgetEur: 2000000,
        reports: [r1, r2],
      );

      expect(summary.totalStagesTracked, 2);
      expect(summary.totalRawSeconds, closeTo(2000.0, 0.001));
      expect(summary.roiMultiplier, greaterThan(2.0));
      expect(
        TvExposureAndMediaValueTracker.evaluateSponsorRoiGrade(3.2),
        SponsorMediaRoiGrade.tierS,
      );
      expect(
        TvExposureAndMediaValueTracker.evaluateSponsorRoiGrade(0.5),
        SponsorMediaRoiGrade.tierD,
      );
    });
  });

  group('TvExposureMediaValuePanel', () {
    StageTvExposureReport buildSampleReport() {
      final tracker = TvExposureAndMediaValueTracker();
      tracker.recordSimulationTick(
        deltaSeconds: 900,
        isInBreakaway: true,
        activeRiderName: 'K. Gradek',
      );
      tracker.recordSimulationTick(
        deltaSeconds: 450,
        isPullingPeloton: true,
        visibleTeamRidersCount: 3,
        activeRiderName: 'M. Kwiatkowski',
      );
      tracker.recordSimulationTick(
        deltaSeconds: 180,
        isMountainAttacking: true,
        activeRiderName: 'R. Majka',
      );
      tracker.recordPodiumCeremony(
        durationSeconds: 90,
        riderName: 'R. Majka',
      );
      return tracker.finalizeStageReport(
        stageId: 'tdf_17',
        raceName: 'Tour de France — Col du Galibier',
        raceCategory: RaceCategory.grandTour,
        sponsorName: 'VeloCore Pro',
      );
    }

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się poprawnie bez przepełnień w ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          final report = buildSampleReport();
          TvCameraExposureSource? selected;
          var resetCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                backgroundColor: const Color(0xFF0F1115),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: TvExposureMediaValuePanel(
                    report: report,
                    annualSponsorBudgetEur: 12000000,
                    onSourceSelected: (src) => selected = src,
                    onResetPressed: () => resetCount++,
                  ),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.text('Jazda w ucieczce dnia'), findsOneWidget);
          expect(find.text('Dekoracja na podium'), findsOneWidget);

          await tester.tap(find.text('Jazda w ucieczce dnia'));
          await tester.pump(const Duration(milliseconds: 250));
          expect(selected, TvCameraExposureSource.breakawayOfTheDay);

          await tester.tap(find.text('Resetuj etap'));
          await tester.pump(const Duration(milliseconds: 250));
          expect(resetCount, 1);
        },
      );
    }

    testWidgets('ignoruje kliknięcia gdy isActionEnabled == false', (tester) async {
      final report = buildSampleReport();
      var resetCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TvExposureMediaValuePanel(
                report: report,
                isActionEnabled: false,
                onResetPressed: () => resetCount++,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Resetuj etap'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(resetCount, 0);
    });
  });
}
