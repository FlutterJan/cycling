import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/services/career/historical_records_and_palmares_service.dart';
import 'package:pro_peloton_manager/services/export/career_almanac_html_report_exporter.dart';

CareerAlmanacReportInput _buildSampleInput() {
  return CareerAlmanacReportInput(
    generatedAtUtc: DateTime.utc(2028, 10, 20, 18, 30, 0),
    teamStats: const CareerAlmanacTeamStats(
      teamId: 'team_pol_wt',
      teamName: 'Biało-Czerwoni Cycling <WT>',
      divisionName: 'UCI WorldTour',
      countryIso: 'pol',
      managerName: 'Jan Kowalski',
      currentSeasonYear: 2028,
      seasonsManaged: 3,
      totalWins: 84,
      grandTourGcWins: 2,
      monumentWins: 4,
      stageWins: 31,
      worldTourWins: 56,
      uciWorldRanking: 1,
      totalUciPoints: 18450,
      budgetEur: 32500000,
      teamPrestige: 94.5,
      primaryColorHex: '#8E4A49',
      secondaryColorHex: '#D4AF37',
      topRiderName: 'Kacper Nowak',
      topRiderWins: 27,
    ),
    seasonHistory: const [
      CareerAlmanacSeasonSummary(
        seasonYear: 2026,
        wins: 18,
        podiums: 42,
        uciPoints: 8900,
        uciRank: 7,
        budgetEur: 18000000,
        highlightAchievement: 'Podium Paryż-Roubaix',
      ),
      CareerAlmanacSeasonSummary(
        seasonYear: 2027,
        wins: 31,
        podiums: 66,
        uciPoints: 14200,
        uciRank: 3,
        budgetEur: 24500000,
        highlightAchievement: 'Zwycięstwo Giro d\'Italia GC',
      ),
      CareerAlmanacSeasonSummary(
        seasonYear: 2028,
        wins: 35,
        podiums: 74,
        uciPoints: 18450,
        uciRank: 1,
        budgetEur: 32500000,
        highlightAchievement: 'Dublet Tour de France & Il Lombardia',
      ),
    ],
    climbRecords: const [
      ClimbKomRecord(
        climbId: 'alpe_dhuez',
        climbName: 'Alpe d\'Huez',
        mountainRange: 'Alpy',
        countryIso: 'FRA',
        lengthKm: 13.8,
        averageGradientPct: 8.1,
        elevationGainM: 1120,
        recordTimeSeconds: 2295,
        recordHolderRiderId: 'r_nowak',
        recordHolderRiderName: 'Kacper Nowak',
        recordHolderTeamName: 'Biało-Czerwoni Cycling',
        achievedInSeasonYear: 2028,
        achievedInRaceName: 'Tour de France',
        vamMetersPerHour: 1756.8,
        estimatedWattsPerKg: 6.48,
      ),
      ClimbKomRecord(
        climbId: 'mortirolo',
        climbName: 'Passo del Mortirolo',
        mountainRange: 'Alpy Retyckie',
        countryIso: 'ITA',
        lengthKm: 12.4,
        averageGradientPct: 10.5,
        elevationGainM: 1302,
        recordTimeSeconds: 2510,
        recordHolderRiderId: 'r_wisniewski',
        recordHolderRiderName: 'Marek Wiśniewski',
        recordHolderTeamName: 'Biało-Czerwoni Cycling',
        achievedInSeasonYear: 2027,
        achievedInRaceName: 'Giro d\'Italia',
        vamMetersPerHour: 1867.4,
        estimatedWattsPerKg: 6.32,
      ),
    ],
    trophies: [
      PalmaresEntry(
        id: 't1',
        riderId: 'r_nowak',
        riderName: 'Kacper Nowak',
        teamId: 'team_pol_wt',
        teamName: 'Biało-Czerwoni Cycling',
        seasonYear: 2028,
        date: DateTime.utc(2028, 7, 23),
        raceId: 'tdf',
        raceName: 'Tour de France',
        raceCategory: RaceCategory.grandTour,
        achievementType: PalmaresAchievementType.grandTourGeneralClassification,
        details: 'Przewaga 1:42 nad 2. miejscem',
        jerseyWorn: 'Maillot Jaune',
      ),
      PalmaresEntry(
        id: 't2',
        riderId: 'r_zielinski',
        riderName: 'Piotr Zieliński',
        teamId: 'team_pol_wt',
        teamName: 'Biało-Czerwoni Cycling',
        seasonYear: 2028,
        date: DateTime.utc(2028, 4, 7),
        raceId: 'pr',
        raceName: 'Paris-Roubaix',
        raceCategory: RaceCategory.monument,
        achievementType: PalmaresAchievementType.monumentClassic,
        details: 'Solo atak na Carrefour de l\'Arbre',
      ),
    ],
    topRiders: const [
      RiderPalmares(
        riderId: 'r_nowak',
        riderName: 'Kacper Nowak',
        nationalityIso: 'pl',
        grandTourOverallWins: 2,
        tourDeFranceGcWins: 1,
        giroDItaliaGcWins: 1,
        grandTourStageWins: 7,
        monumentWins: 1,
        liegeBastogneLiegeWins: 1,
        daysInYellowJersey: 14,
        daysInPinkJersey: 11,
        totalCareerVictories: 27,
      ),
    ],
  );
}

void main() {
  group('CareerAlmanacHtmlReportExporter unit tests', () {
    const exporter = CareerAlmanacHtmlReportExporter();

    test('generates self-contained valid HTML report with escaped characters', () {
      final input = _buildSampleInput();
      final result = exporter.export(
        input: input,
        format: CareerAlmanacExportFormat.html,
        themeStyle: CareerAlmanacThemeStyle.pelotonNoirGold,
      );

      final validation = exporter.validateExportedReport(
        result.content,
        CareerAlmanacExportFormat.html,
      );

      expect(validation.isValid, isTrue);
      expect(validation.hasTeamHeader, isTrue);
      expect(validation.hasTrophiesSection, isTrue);
      expect(validation.hasClimbRecordsSection, isTrue);
      expect(result.suggestedFileName, endsWith('.html'));
      expect(result.trophyCount, 2);
      expect(result.climbRecordCount, 2);
      expect(result.seasonCount, 3);
      expect(result.riderLeaderCount, 1);
      expect(result.content, contains('Biało-Czerwoni Cycling &lt;WT&gt;'));
      expect(result.content, contains('Alpe d&#39;Huez'));
      expect(result.content, contains('Maillot Jaune'));
      expect(result.content, contains('18 450'));
    });

    test('generates valid Markdown report with tables and sections', () {
      final input = _buildSampleInput();
      final result = exporter.export(
        input: input,
        format: CareerAlmanacExportFormat.markdown,
      );

      final validation = exporter.validateExportedReport(
        result.content,
        CareerAlmanacExportFormat.markdown,
      );

      expect(validation.isValid, isTrue);
      expect(result.suggestedFileName, endsWith('.md'));
      expect(result.content, contains('# Kronika Kariery — Biało-Czerwoni Cycling <WT>'));
      expect(result.content, contains('## Statystyki Drużyny'));
      expect(result.content, contains('## Kronika Sezonów'));
      expect(result.content, contains('## Rekordy Podjazdów (KOM)'));
      expect(result.content, contains('## Gablota Trofeów'));
      expect(result.content, contains('## Gwiazdy i Legendy Drużyny'));
    });

    test('respects section inclusion toggles and writes file to disk', () async {
      final input = _buildSampleInput();
      final tempDir = await Directory.systemTemp.createTemp('almanac_test_');
      try {
        final file = await exporter.exportToFile(
          input: input,
          targetDirectory: tempDir,
          format: CareerAlmanacExportFormat.html,
          themeStyle: CareerAlmanacThemeStyle.grandTourEditorial,
          includeClimbRecords: false,
          includeTrophies: false,
        );

        expect(await file.exists(), isTrue);
        final saved = await file.readAsString();
        expect(saved, contains('<!DOCTYPE html>'));
        expect(saved, isNot(contains('id="climbs"')));
        expect(saved, isNot(contains('id="trophies"')));
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('validation detects invalid or empty reports', () {
      final emptyReport = exporter.validateExportedReport(
        '   ',
        CareerAlmanacExportFormat.html,
      );
      expect(emptyReport.isValid, isFalse);
      expect(emptyReport.errors, isNotEmpty);

      final invalidMd = exporter.validateExportedReport(
        'Brak nagłówka',
        CareerAlmanacExportFormat.markdown,
      );
      expect(invalidMd.isValid, isFalse);
    });
  });

  group('CareerAlmanacExporterPanel widget & responsiveness tests', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders without overflow at ${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        CareerAlmanacExportResult? exported;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: size.width,
                height: size.height,
                child: CareerAlmanacExporterPanel(
                  input: _buildSampleInput(),
                  onExported: (res) => exported = res,
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('KRONIKA KARIERY (.HTML / .MD)'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.text('Eksportuj Kronikę (.html)'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Eksportuj Kronikę (.html)'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(exported, isNotNull);
        expect(exported!.format, CareerAlmanacExportFormat.html);

        // Switch to Markdown format and toggle preview
        await tester.ensureVisible(find.text('Kronika Markdown (.md)'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Kronika Markdown (.md)'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Eksportuj Kronikę (.md)'), findsOneWidget);

        await tester.ensureVisible(find.text('Podgląd źródła'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Podgląd źródła'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Ukryj podgląd'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('renders empty state when input is null and respects disabled state', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CareerAlmanacExporterPanel(
              input: null,
              enabled: false,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Rozpocznij karierę, aby wygenerować Kronikę'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
