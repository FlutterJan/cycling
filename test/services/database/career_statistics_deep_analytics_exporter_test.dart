import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/models/career/season_calendar.dart';
import 'package:pro_peloton_manager/services/database/career_statistics_deep_analytics_exporter.dart';
import 'package:pro_peloton_manager/services/database/demo_save_preset_builder.dart';

Future<CareerSave> _buildSampleCareerSave() async {
  final baseSave = await DemoSavePresetBuilder.buildPreset(
    DemoSavePresetType.polishWorldTourProject,
  );
  final history = <String, RaceHistoryEntry>{
    'tdp_2026': RaceHistoryEntry(
      raceId: 'tdp_2026',
      raceName: 'Tour de Pologne "Orlen"',
      seasonYear: baseSave.currentSeasonYear,
      winnerRiderId: baseSave.playerRoster.first.id,
      winnerRiderName: baseSave.playerRoster.first.fullName,
      winnerTeamId: baseSave.playerTeamId,
      winnerTeamName: baseSave.playerTeam.name,
      winnerTotalTimeSeconds: 98412,
      pointsWinnerRiderName: baseSave.playerRoster.first.fullName,
      mountainsWinnerRiderName: 'Jan Kowalski',
      youthWinnerRiderName: baseSave.playerRoster.first.fullName,
      teamWinnerName: baseSave.playerTeam.name,
      completedDate: DateTime(baseSave.currentSeasonYear, 8, 12),
    ),
  };

  final ledger = <CareerFinanceLedgerEntry>[
    CareerFinanceLedgerEntry(
      id: 'fin_1',
      date: DateTime(baseSave.currentSeasonYear, 1, 15),
      category: FinanceCategory.sponsorPayout,
      amountEur: 4500000,
      description: 'Transza główna sponsora',
    ),
    CareerFinanceLedgerEntry(
      id: 'fin_2',
      date: DateTime(baseSave.currentSeasonYear, 2, 1),
      category: FinanceCategory.riderSalaries,
      amountEur: -2100000,
      description: 'Wypłaty kadry',
    ),
  ];

  return baseSave.copyWith(
    calendar: baseSave.calendar.copyWith(
      completedRaceIds: ['tdp_2026'],
      raceHistory: history,
    ),
    financeLedger: ledger,
    trophiesWon: ['Tour de Pologne 2026'],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CareerSave sampleSave;

  setUpAll(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      return Directory.systemTemp.path;
    });
    sampleSave = await _buildSampleCareerSave();
  });

  group('CareerStatisticsDeepAnalyticsExporter', () {
    const exporter = CareerStatisticsDeepAnalyticsExporter();

    test('ekstrahuje wieloletnie snapshoty, kolarzy, palmares i finanse', () async {
      final save = await _buildSampleCareerSave();
      final historical = [
        SeasonAnalyticsSnapshot(
          seasonYear: save.currentSeasonYear - 1,
          teamId: save.playerTeamId,
          teamName: save.playerTeam.name,
          divisionName: 'UCI Continental',
          uciPoints: 1850,
          winsCount: 9,
          podiumsCount: 24,
          racesCompleted: 32,
          totalIncomeEur: 3200000,
          totalExpensesEur: 2900000,
          netCashflowEur: 300000,
          cashBalanceEur: 1200000,
          averageRosterAge: 23.4,
          averageRosterFtpW: 398.5,
          averageRosterVo2Max: 79.2,
          managerReputation: 58,
        ),
      ];

      final dataset = exporter.extractDataset(
        save,
        historicalSnapshots: historical,
        config: const CareerAnalyticsExportConfig(
          playerTeamOnly: true,
        ),
      );

      expect(dataset.seasons.length, 2);
      expect(
        dataset.seasons.first.seasonYear,
        save.currentSeasonYear - 1,
      );
      expect(dataset.seasons.last.seasonYear, save.currentSeasonYear);
      expect(
        dataset.riders.every((r) => r.teamId == save.playerTeamId),
        isTrue,
      );
      expect(dataset.racePalmares.length, 1);
      expect(dataset.racePalmares.first.isPlayerTeamWin, isTrue);
      expect(dataset.financeBreakdown.length, 2);
      expect(dataset.summaryMetrics.playerTeamWins, 1);
      expect(dataset.summaryMetrics.trophiesCount, 1);
    });

    test('generuje poprawny CSV z BOM, escapowaniem RFC 4180 i separatorem', () async {
      final save = await _buildSampleCareerSave();
      final result = exporter.exportCareerAnalytics(
        save,
        config: const CareerAnalyticsExportConfig(
          format: AnalyticsExportFormat.csv,
          scope: AnalyticsDatasetScope.raceResultsAndPalmares,
          delimiter: CsvDelimiter.semicolon,
          includeBomForExcel: true,
          includeMetadataHeader: true,
        ),
      );

      expect(result.success, isTrue);
      expect(result.artifacts.length, 1);
      final csv = result.artifacts.first.content;
      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv.contains('# Pro Peloton Manager'), isTrue);
      expect(csv.contains('race_id;race_name;season_year'), isTrue);
      expect(csv.contains('"Tour de Pologne ""Orlen"""'), isTrue);
    });

    test('generuje poprawny JSON z sumą kontrolną FNV-1a64 oraz zapisuje na dysk', () async {
      final save = await _buildSampleCareerSave();
      final result = exporter.exportCareerAnalytics(
        save,
        config: const CareerAnalyticsExportConfig(
          format: AnalyticsExportFormat.csvAndJsonBundle,
          scope: AnalyticsDatasetScope.fullCareer,
          prettyPrintJson: false,
        ),
      );

      expect(result.artifacts.length, 2);
      final jsonArtifact = result.artifacts.firstWhere(
        (a) => a.format == AnalyticsExportFormat.json,
      );
      final decoded = jsonDecode(jsonArtifact.content) as Map<String, dynamic>;
      expect(decoded['schemaVersion'], kCareerAnalyticsExportSchemaVersion);
      expect((decoded['checksumFnv1a64'] as String).length, 16);
      expect(decoded['datasets'], isA<Map<String, dynamic>>());

      final tempDir = await Directory.systemTemp.createTemp('ppm_export_test_');
      try {
        final paths = await exporter.writeArtifactsToDirectory(result, tempDir);
        expect(paths.length, 2);
        for (final path in paths) {
          expect(await File(path).exists(), isTrue);
        }
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('anonimizuje rywali i filtruje zakres sezonów', () async {
      final save = await _buildSampleCareerSave();
      final dataset = exporter.extractDataset(
        save,
        config: CareerAnalyticsExportConfig(
          anonymizeRivalNames: true,
          seasonYearFrom: save.currentSeasonYear + 1,
        ),
      );

      expect(dataset.seasons, isEmpty);
      expect(dataset.racePalmares, isEmpty);
      final rivalRider = dataset.riders.firstWhere(
        (r) => r.teamId != save.playerTeamId,
      );
      expect(rivalRider.fullName.startsWith('Rider_'), isTrue);
      expect(rivalRider.teamName.startsWith('Rival_Team_'), isTrue);
    });

    test('CareerAnalyticsExporterNotifier aktualizuje konfigurację i historię', () async {
      final save = await _buildSampleCareerSave();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(careerAnalyticsExporterProvider.notifier);
      notifier.setFormat(AnalyticsExportFormat.json);
      notifier.setScope(AnalyticsDatasetScope.ridersAndPhysiology);
      notifier.togglePlayerTeamOnly(true);

      final res = notifier.runExport(save);
      final state = container.read(careerAnalyticsExporterProvider);

      expect(res.success, isTrue);
      expect(state.lastResult, isNotNull);
      expect(state.exportHistory.length, 1);
      expect(state.config.format, AnalyticsExportFormat.json);
      expect(state.config.playerTeamOnly, isTrue);
    });
  });

  group('CareerStatisticsDeepAnalyticsExporterPanel UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnienia dla ${size.width.toInt()}x${size.height.toInt()} i generuje eksport',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: CareerStatisticsDeepAnalyticsExporterPanel(
                    careerSave: sampleSave,
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(
            find.text('Eksporter Analityczny Kariery (CSV / JSON)'),
            findsOneWidget,
          );
          expect(find.text('Eksportuj Dane BI'), findsOneWidget);

          await tester.tap(find.text('Eksportuj Dane BI'));
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.textContaining('FNV-1a64:'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
