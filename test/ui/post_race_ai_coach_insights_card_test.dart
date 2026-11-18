import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_results_calculator.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/services/analysis/post_race_ai_tactical_coach_analyzer.dart';
import 'package:pro_peloton_manager/ui/widgets/post_race_ai_coach_insights_card.dart';

PostRaceAiCoachInsightsData _buildSampleData() {
  const PostRaceTacticalCoachReport leaderReport = PostRaceTacticalCoachReport(
    riderId: 'r_leader',
    riderName: 'Jan Kowalski',
    stageName: 'Etap 14 • Tourmalet',
    role: TacticalCoachRiderRole.gcLeader,
    overallTacticalScore: 86.0,
    grade: TacticalCoachGrade.a,
    executiveVerdict:
        'Bardzo dobra ochrona w peletonie i precyzyjny atak na finałowym podjeździe.',
    windSummary: WindAeroEfficiencySummary(
      totalWastedEnergyKj: 38.5,
      averageWastedWattsWhenExposed: 42.0,
      exposedDurationSeconds: 180.0,
      shelteredPercentOfStage: 89.0,
      equivalentFtpMinutesWasted: 1.6,
      gutterExposureCount: 0,
      topMistakeSegments: <WindExposureSegment>[
        WindExposureSegment(
          startKm: 84.0,
          endKm: 86.5,
          durationSeconds: 180.0,
          averageWastedWatts: 42.0,
          wastedEnergyKj: 38.5,
          averageCrosswindKmh: 28.0,
          averageDraftingPercent: 14.0,
          occurredInEchelon: true,
          occurredInGutter: false,
          diagnosis: 'Krótka ekspozycja na boczny wiatr w dolinie przed podjazdem.',
        ),
      ],
    ),
    attackSummary: WPrimeAttackTimingSummary(
      totalAttacks: 2,
      optimalAttacks: 2,
      poorlyTimedAttacks: 0,
      blowupCount: 0,
      averagePreAttackWPrimePercent: 84.0,
      averageTimingScore: 92.0,
      attacks: <AttackTimingEvaluation>[
        AttackTimingEvaluation(
          attackIndex: 1,
          startKm: 152.0,
          endKm: 154.0,
          distanceToFinishKm: 8.0,
          durationSeconds: 95.0,
          peakWatts: 620,
          averageWatts: 515,
          preAttackWPrimeRatio: 0.88,
          minWPrimeRatioDuringAttack: 0.42,
          averageGradientPercent: 8.6,
          headwindComponentKmh: 2.0,
          causedWPrimeBlowup: false,
          timingScore: 94.0,
          verdict: AttackTimingVerdict.optimal,
          coachingNote: 'Czyste przyspieszenie z pełną baterią W\' na ściance >8%.',
        ),
      ],
    ),
    insights: <TacticalCoachingInsight>[
      TacticalCoachingInsight(
        id: 'ins_wind_1',
        category: TacticalInsightCategory.windProtection,
        severity: TacticalInsightSeverity.positive,
        title: 'Wysoka efektywność aerodynamiczna',
        description:
            'Kolarz spędził 89% dystansu w osłonie grupy, minimalizując straty energetyczne.',
        impactMetricLabel: '38.5 kJ straty',
        nextStageAction:
            'Utrzymaj dwóch pomocników na zmianach przy wietrze >25 km/h.',
      ),
      TacticalCoachingInsight(
        id: 'ins_wp_1',
        category: TacticalInsightCategory.wPrimeTiming,
        severity: TacticalInsightSeverity.tip,
        title: 'Perfekcyjny timing ataku W\'',
        description:
            'Atak na 8 km przed metą rozpoczął się przy 88% naładowania W\'.',
        impactMetricLabel: '94/100 pkt',
        nextStageAction:
            'Powtórz schemat ataku na kolejnym etapie górskim przy >80% W\'.',
      ),
    ],
  );

  const PostRaceTacticalCoachReport domestiqueReport =
      PostRaceTacticalCoachReport(
    riderId: 'r_dom',
    riderName: 'Marek Nowak',
    stageName: 'Etap 14 • Tourmalet',
    role: TacticalCoachRiderRole.domestique,
    overallTacticalScore: 68.0,
    grade: TacticalCoachGrade.c,
    executiveVerdict:
        'Kosztowna jazda w rancie na 60. kilometrze obniżyła rezerwę przed podjazdem.',
    windSummary: WindAeroEfficiencySummary(
      totalWastedEnergyKj: 112.0,
      averageWastedWattsWhenExposed: 68.0,
      exposedDurationSeconds: 420.0,
      shelteredPercentOfStage: 64.0,
      equivalentFtpMinutesWasted: 5.1,
      gutterExposureCount: 2,
      topMistakeSegments: <WindExposureSegment>[],
    ),
    attackSummary: WPrimeAttackTimingSummary(
      totalAttacks: 0,
      optimalAttacks: 0,
      poorlyTimedAttacks: 0,
      blowupCount: 0,
      averagePreAttackWPrimePercent: 0.0,
      averageTimingScore: 100.0,
      attacks: <AttackTimingEvaluation>[],
    ),
    insights: <TacticalCoachingInsight>[
      TacticalCoachingInsight(
        id: 'ins_ech_1',
        category: TacticalInsightCategory.echelonPositioning,
        severity: TacticalInsightSeverity.critical,
        title: 'Utrata pozycji w rancie',
        description:
            'Dwukrotna jazda na krawędzi asfaltu kosztowała 112 kJ ponad normę.',
        impactMetricLabel: '2x rant',
        nextStageAction:
            'Przesuń kolarza do Top 15 peletonu przed strefą wiatru bocznego.',
      ),
    ],
  );

  return PostRaceAiCoachInsightsData.fromReports(
    stageName: 'Etap 14 • Tourmalet',
    reports: <PostRaceTacticalCoachReport>[leaderReport, domestiqueReport],
  );
}

Widget _wrapForViewport(Widget child, Size size) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: size.width - 24,
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('PostRaceAiCoachInsightsData', () {
    test('synthesizes reports from StageSummaryReport and round-trips JSON', () {
      const StageSummaryReport stageReport = StageSummaryReport(
        stageId: 'st_14',
        stageNumber: 14,
        stageName: 'Etap 14 • Tourmalet',
        stageType: StageType.highMountain,
        winnerRiderName: 'Jan Kowalski',
        winnerTeamId: 'team_player',
        winnerTimeSeconds: 14520.0,
        timeCutLimitSeconds: 16800.0,
        timeCutPercent: 16.0,
        otlEliminatedCount: 0,
        dnfCount: 0,
        teamPrizeMoneyTotals: <String, int>{'team_player': 15000},
        mostCombativeRiderId: 'r_2',
        results: <OfficialRiderStageResult>[
          OfficialRiderStageResult(
            riderId: 'r_1',
            riderName: 'Jan Kowalski',
            teamId: 'team_player',
            rank: 1,
            rawFinishTimeSeconds: 14520.0,
            officialFinishTimeSeconds: 14520.0,
            gapToWinnerSeconds: 0.0,
          ),
          OfficialRiderStageResult(
            riderId: 'r_2',
            riderName: 'Marek Nowak',
            teamId: 'team_player',
            rank: 18,
            rawFinishTimeSeconds: 14710.0,
            officialFinishTimeSeconds: 14710.0,
            gapToWinnerSeconds: 190.0,
          ),
        ],
      );

      final PostRaceAiCoachInsightsData data =
          PostRaceAiCoachInsightsData.fromStageReport(
        report: stageReport,
        playerTeamId: 'team_player',
      );

      expect(data.isFromLiveTelemetry, isFalse);
      expect(data.reports.length, 2);
      expect(
        data.reports.map((r) => r.riderName),
        containsAll(<String>['Jan Kowalski', 'Marek Nowak']),
      );

      final PostRaceAiCoachInsightsData restored =
          PostRaceAiCoachInsightsData.fromJson(data.toJson());
      expect(restored.stageName, data.stageName);
      expect(restored.reports.length, 2);
      expect(restored.reports.first.grade, data.reports.first.grade);
    });
  });

  group('PostRaceAiCoachInsightsCard widget tests', () {
    const List<Size> viewports = <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ];

    for (final Size size in viewports) {
      testWidgets(
        'renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            _wrapForViewport(
              PostRaceAiCoachInsightsCard(data: _buildSampleData()),
              size,
            ),
          );
          await tester.pump(const Duration(milliseconds: 360));

          expect(find.text('ASYSTENT TAKTYCZNY AI'), findsOneWidget);
          expect(find.text('Jan Kowalski'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'supports rider switching, detail tabs, expanding and applying insights',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        TacticalCoachingInsight? applied;
        PostRaceTacticalCoachReport? selectedRider;

        await tester.pumpWidget(
          _wrapForViewport(
            PostRaceAiCoachInsightsCard(
              data: _buildSampleData(),
              onRiderSelected: (r) => selectedRider = r,
              onApplyNextStageAction: (i) => applied = i,
            ),
            const Size(1024, 900),
          ),
        );
        await tester.pump(const Duration(milliseconds: 350));

        // Expand first insight and apply action
        final Finder insightTitle =
            find.text('Wysoka efektywność aerodynamiczna');
        await tester.ensureVisible(insightTitle);
        await tester.pump();
        await tester.tap(insightTitle);
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('PLAN NA KOLEJNY ETAP'), findsOneWidget);

        final Finder applyButton = find.text('Zastosuj wskazówkę');
        await tester.ensureVisible(applyButton);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(applyButton);
        await tester.pump(const Duration(milliseconds: 220));
        expect(applied?.id, 'ins_wind_1');
        expect(find.text('Zastosowano w planie'), findsOneWidget);

        // Switch to wind segments tab
        final Finder windTab = find.text('Odcinki Wiatru');
        await tester.ensureVisible(windTab);
        await tester.pump();
        await tester.tap(windTab);
        await tester.pump(const Duration(milliseconds: 260));
        expect(find.text('km 84.0 – 86.5'), findsOneWidget);

        // Switch to attack timings tab
        final Finder attackTab = find.text('Ocena Ataków W\'');
        await tester.ensureVisible(attackTab);
        await tester.pump();
        await tester.tap(attackTab);
        await tester.pump(const Duration(milliseconds: 260));
        expect(find.text('Atak #1'), findsOneWidget);

        // Switch rider
        final Finder riderChip = find.text('Marek Nowak');
        await tester.ensureVisible(riderChip);
        await tester.pump();
        await tester.tap(riderChip);
        await tester.pump(const Duration(milliseconds: 260));
        expect(selectedRider?.riderId, 'r_dom');
      },
    );

    testWidgets(
      'renders empty state and respects isDisabled',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _wrapForViewport(
            const PostRaceAiCoachInsightsCard(
              data: PostRaceAiCoachInsightsData(
                stageName: 'Etap 1',
                reports: <PostRaceTacticalCoachReport>[],
              ),
            ),
            const Size(390, 844),
          ),
        );
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('Brak raportów Asystenta Taktycznego AI'), findsOneWidget);

        bool callbackFired = false;
        await tester.pumpWidget(
          _wrapForViewport(
            PostRaceAiCoachInsightsCard(
              data: _buildSampleData(),
              isDisabled: true,
              onRiderSelected: (_) => callbackFired = true,
            ),
            const Size(1024, 768),
          ),
        );
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.text('Marek Nowak'), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 200));
        expect(callbackFired, isFalse);
      },
    );
  });
}
