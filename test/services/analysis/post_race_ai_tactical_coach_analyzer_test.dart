import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/analysis/post_race_ai_tactical_coach_analyzer.dart';

void main() {
  const PostRaceAiTacticalCoachAnalyzer analyzer =
      PostRaceAiTacticalCoachAnalyzer();

  List<PostRaceTelemetrySample> buildWindyAndBlowupSamples() {
    final List<PostRaceTelemetrySample> samples = [];
    // 1. Jazda w grupie (0..30s)
    for (int i = 0; i < 30; i++) {
      samples.add(
        PostRaceTelemetrySample(
          timestampSeconds: i.toDouble(),
          distanceMeters: i * 12.0,
          speedMs: 12.0,
          powerWatts: 280,
          gradientPercent: 0.5,
          wPrimeJoules: 20000,
          wPrimeRatio: 0.90,
          isDrafting: true,
          draftingSavingsPercent: 36.0,
          windSpeedKmh: 28.0,
          windAngleDegrees: 75.0,
        ),
      );
    }
    // 2. Długa ekspozycja na wietrze bocznym i w rancie (30..90s)
    for (int i = 30; i < 90; i++) {
      samples.add(
        PostRaceTelemetrySample(
          timestampSeconds: i.toDouble(),
          distanceMeters: 360.0 + (i - 30) * 11.5,
          speedMs: 11.5,
          powerWatts: 390,
          gradientPercent: 0.2,
          wPrimeJoules: 16000 - (i - 30) * 120.0,
          wPrimeRatio: ((16000 - (i - 30) * 120.0) / 22000.0).clamp(0.0, 1.0),
          isDrafting: false,
          draftingSavingsPercent: 0.0,
          windSpeedKmh: 38.0,
          windAngleDegrees: 85.0,
          isEchelonZone: true,
          isInGutter: i >= 60,
        ),
      );
    }
    // 3. Zły atak przy niskim W' pod wiatr na płaskim -> wyzerowanie W' (90..110s)
    for (int i = 90; i < 110; i++) {
      final double ratio = (0.32 - (i - 90) * 0.017).clamp(0.0, 1.0);
      samples.add(
        PostRaceTelemetrySample(
          timestampSeconds: i.toDouble(),
          distanceMeters: 1050.0 + (i - 90) * 12.5,
          speedMs: 12.5,
          powerWatts: 540,
          gradientPercent: 0.0,
          wPrimeJoules: ratio * 22000.0,
          wPrimeRatio: ratio,
          isDrafting: false,
          draftingSavingsPercent: 0.0,
          windSpeedKmh: 26.0,
          windAngleDegrees: 10.0,
          isAttacking: true,
        ),
      );
    }
    // 4. Odcięcie po ataku (110..120s)
    for (int i = 110; i < 120; i++) {
      samples.add(
        PostRaceTelemetrySample(
          timestampSeconds: i.toDouble(),
          distanceMeters: 1300.0 + (i - 110) * 8.0,
          speedMs: 8.0,
          powerWatts: 210,
          gradientPercent: 0.0,
          wPrimeJoules: 400.0,
          wPrimeRatio: 0.02,
          isDrafting: true,
          draftingSavingsPercent: 25.0,
          windSpeedKmh: 15.0,
          windAngleDegrees: 0.0,
        ),
      );
    }
    return samples;
  }

  List<PostRaceTelemetrySample> buildOptimalClimbAttackSamples() {
    final List<PostRaceTelemetrySample> samples = [];
    for (int i = 0; i < 40; i++) {
      samples.add(
        PostRaceTelemetrySample(
          timestampSeconds: i.toDouble(),
          distanceMeters: 140000.0 + i * 11.0,
          speedMs: 11.0,
          powerWatts: 270,
          gradientPercent: 1.0,
          wPrimeJoules: 21000.0,
          wPrimeRatio: 0.95,
          isDrafting: true,
          draftingSavingsPercent: 38.0,
          windSpeedKmh: 12.0,
          windAngleDegrees: 45.0,
        ),
      );
    }
    // Optymalny atak na podjeździe 8.5% przy W' = 95% z finiszem powyżej 20% W'
    for (int i = 40; i < 58; i++) {
      final double ratio = (0.95 - (i - 40) * 0.035).clamp(0.25, 1.0);
      samples.add(
        PostRaceTelemetrySample(
          timestampSeconds: i.toDouble(),
          distanceMeters: 140440.0 + (i - 40) * 7.5,
          speedMs: 7.5,
          powerWatts: 560,
          gradientPercent: 8.5,
          wPrimeJoules: ratio * 22000.0,
          wPrimeRatio: ratio,
          isDrafting: false,
          draftingSavingsPercent: 0.0,
          windSpeedKmh: 8.0,
          windAngleDegrees: 90.0,
          isAttacking: true,
        ),
      );
    }
    return samples;
  }

  group('PostRaceAiTacticalCoachAnalyzer unit tests', () {
    test('handles empty telemetry safely', () {
      const PostRaceCoachAnalysisInput input = PostRaceCoachAnalysisInput(
        riderId: 'r_empty',
        riderName: 'Jan Kowalski',
        role: TacticalCoachRiderRole.gcLeader,
        ftpWatts: 390,
        maxWPrimeJoules: 22000,
        weightKg: 66,
        stageName: 'Etap 1',
        totalStageDistanceKm: 170,
        samples: [],
      );

      final PostRaceTacticalCoachReport report = analyzer.analyzeStage(input);
      expect(report.grade, TacticalCoachGrade.f);
      expect(report.overallTacticalScore, 0.0);
      expect(report.windSummary.topMistakeSegments, isEmpty);
      expect(report.attackSummary.attacks, isEmpty);
    });

    test('detects wind exposure losses, gutter and W-prime blowup', () {
      final PostRaceCoachAnalysisInput input = PostRaceCoachAnalysisInput(
        riderId: 'r_wind',
        riderName: 'Marek Nowak',
        role: TacticalCoachRiderRole.gcLeader,
        ftpWatts: 380,
        maxWPrimeJoules: 22000,
        weightKg: 68,
        stageName: 'Etap 4 — Wiatry Flandrii',
        totalStageDistanceKm: 165,
        samples: buildWindyAndBlowupSamples(),
      );

      final PostRaceTacticalCoachReport report = analyzer.analyzeStage(input);
      expect(report.windSummary.totalWastedEnergyKj, greaterThan(4.0));
      expect(report.windSummary.gutterExposureCount, greaterThan(0));
      expect(report.windSummary.topMistakeSegments, isNotEmpty);
      expect(report.attackSummary.totalAttacks, 1);
      expect(report.attackSummary.blowupCount, 1);
      expect(
        report.attackSummary.attacks.first.verdict,
        AttackTimingVerdict.emptyTankBlowup,
      );
      expect(report.overallTacticalScore, lessThan(65.0));
      expect(
        report.insights.any(
          (i) => i.category == TacticalInsightCategory.echelonPositioning,
        ),
        isTrue,
      );
    });

    test('rewards sheltered riding and optimal climb attack timing', () {
      final PostRaceCoachAnalysisInput input = PostRaceCoachAnalysisInput(
        riderId: 'r_opt',
        riderName: 'Tadeusz Górski',
        role: TacticalCoachRiderRole.climber,
        ftpWatts: 410,
        maxWPrimeJoules: 22000,
        weightKg: 62,
        stageName: 'Etap 15 — Alpe d\'Huez',
        totalStageDistanceKm: 155,
        samples: buildOptimalClimbAttackSamples(),
      );

      final PostRaceTacticalCoachReport report = analyzer.analyzeStage(input);
      expect(report.windSummary.shelteredPercentOfStage, greaterThan(95.0));
      expect(report.attackSummary.totalAttacks, 1);
      expect(report.attackSummary.optimalAttacks, 1);
      expect(report.attackSummary.blowupCount, 0);
      expect(
        report.attackSummary.attacks.first.verdict,
        AttackTimingVerdict.optimal,
      );
      expect(report.overallTacticalScore, greaterThanOrEqualTo(85.0));
      expect(
        report.grade == TacticalCoachGrade.s ||
            report.grade == TacticalCoachGrade.a,
        isTrue,
      );
    });

    test('analyzeTeam sorts riders from lowest score to highest', () {
      final PostRaceCoachAnalysisInput poorInput = PostRaceCoachAnalysisInput(
        riderId: 'r_1',
        riderName: 'Marek Nowak',
        role: TacticalCoachRiderRole.gcLeader,
        ftpWatts: 380,
        maxWPrimeJoules: 22000,
        weightKg: 68,
        stageName: 'Etap 4',
        totalStageDistanceKm: 165,
        samples: buildWindyAndBlowupSamples(),
      );
      final PostRaceCoachAnalysisInput goodInput = PostRaceCoachAnalysisInput(
        riderId: 'r_2',
        riderName: 'Tadeusz Górski',
        role: TacticalCoachRiderRole.climber,
        ftpWatts: 410,
        maxWPrimeJoules: 22000,
        weightKg: 62,
        stageName: 'Etap 4',
        totalStageDistanceKm: 165,
        samples: buildOptimalClimbAttackSamples(),
      );

      final List<PostRaceTacticalCoachReport> teamReports =
          analyzer.analyzeTeam([goodInput, poorInput]);

      expect(teamReports.length, 2);
      expect(teamReports.first.riderId, 'r_1');
      expect(teamReports.last.riderId, 'r_2');
    });

    test('supports full JSON round-trip for input and report', () {
      final PostRaceCoachAnalysisInput input = PostRaceCoachAnalysisInput(
        riderId: 'r_json',
        riderName: 'Piotr Zieliński',
        role: TacticalCoachRiderRole.puncheur,
        ftpWatts: 395,
        maxWPrimeJoules: 23000,
        weightKg: 70,
        stageName: 'Etap 7',
        totalStageDistanceKm: 180,
        samples: buildOptimalClimbAttackSamples(),
      );

      final PostRaceCoachAnalysisInput decodedInput =
          PostRaceCoachAnalysisInput.fromJson(input.toJson());
      expect(decodedInput.riderName, input.riderName);
      expect(decodedInput.samples.length, input.samples.length);

      final PostRaceTacticalCoachReport report =
          analyzer.analyzeStage(decodedInput);
      final PostRaceTacticalCoachReport decodedReport =
          PostRaceTacticalCoachReport.fromJson(report.toJson());
      expect(decodedReport.riderId, report.riderId);
      expect(decodedReport.grade, report.grade);
      expect(
        decodedReport.attackSummary.totalAttacks,
        report.attackSummary.totalAttacks,
      );
    });

    test('Riverpod notifier manages analysis state cleanly', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final PostRaceAiTacticalCoachNotifier notifier =
          container.read(postRaceAiTacticalCoachProvider.notifier);

      notifier.analyzeTeamStage([
        PostRaceCoachAnalysisInput(
          riderId: 'r_1',
          riderName: 'Kolarz A',
          role: TacticalCoachRiderRole.gcLeader,
          ftpWatts: 380,
          maxWPrimeJoules: 22000,
          weightKg: 68,
          stageName: 'Etap 1',
          totalStageDistanceKm: 165,
          samples: buildWindyAndBlowupSamples(),
        ),
        PostRaceCoachAnalysisInput(
          riderId: 'r_2',
          riderName: 'Kolarz B',
          role: TacticalCoachRiderRole.climber,
          ftpWatts: 410,
          maxWPrimeJoules: 22000,
          weightKg: 62,
          stageName: 'Etap 1',
          totalStageDistanceKm: 165,
          samples: buildOptimalClimbAttackSamples(),
        ),
      ]);

      final PostRaceAiTacticalCoachState state =
          container.read(postRaceAiTacticalCoachProvider);
      expect(state.reports.length, 2);
      expect(state.selectedReport?.riderId, 'r_1');

      notifier.selectRider(1);
      notifier.selectTab(TacticalCoachPanelTab.attackTiming);
      expect(
        container.read(postRaceAiTacticalCoachProvider).selectedReport?.riderId,
        'r_2',
      );
      expect(
        container.read(postRaceAiTacticalCoachProvider).activeTab,
        TacticalCoachPanelTab.attackTiming,
      );

      notifier.clearReports();
      expect(container.read(postRaceAiTacticalCoachProvider).reports, isEmpty);
    });
  });

  group('PostRaceAiTacticalCoachPanel widget & responsive tests', () {
    testWidgets('renders empty state and handles tab switching',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PostRaceAiTacticalCoachPanel(report: null),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Brak danych telemetrycznych do analizy AI'),
        findsOneWidget,
      );

      final PostRaceTacticalCoachReport report = analyzer.analyzeStage(
        PostRaceCoachAnalysisInput(
          riderId: 'r_ui',
          riderName: 'Michał Kolarz',
          role: TacticalCoachRiderRole.gcLeader,
          ftpWatts: 380,
          maxWPrimeJoules: 22000,
          weightKg: 68,
          stageName: 'Etap 4',
          totalStageDistanceKm: 165,
          samples: buildWindyAndBlowupSamples(),
        ),
      );

      TacticalCoachPanelTab? lastTab;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostRaceAiTacticalCoachPanel(
              report: report,
              onTabChanged: (t) => lastTab = t,
              onExportReport: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Michał Kolarz'), findsOneWidget);
      await tester.tap(find.text('Straty na wietrze'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(lastTab, TacticalCoachPanelTab.windLoss);

      await tester.tap(find.text('Timing ataków W\''));
      await tester.pump(const Duration(milliseconds: 300));
      expect(lastTab, TacticalCoachPanelTab.attackTiming);
    });

    for (final Size size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final PostRaceTacticalCoachReport report = analyzer.analyzeStage(
          PostRaceCoachAnalysisInput(
            riderId: 'r_resp',
            riderName: 'Jan Lider',
            role: TacticalCoachRiderRole.gcLeader,
            ftpWatts: 385,
            maxWPrimeJoules: 22000,
            weightKg: 67,
            stageName: 'Etap 12 — Tourmalet',
            totalStageDistanceKm: 175,
            samples: buildWindyAndBlowupSamples(),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: size.width,
                height: size.height,
                child: PostRaceAiTacticalCoachPanel(
                  report: report,
                  onExportReport: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
