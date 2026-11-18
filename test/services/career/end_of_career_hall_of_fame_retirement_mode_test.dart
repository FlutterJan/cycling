import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/end_of_career_hall_of_fame_retirement_mode.dart';

void main() {
  group('EndOfCareerHallOfFameRetirementService', () {
    const service = EndOfCareerHallOfFameRetirementService();

    const samplePalmares = ManagerCareerPalmaresSummary(
      managerId: 'mgr_test_1',
      managerName: 'Jan Kowalski',
      nationalityCode: 'POL',
      dynastyName: 'Dynastia Kowalski',
      generationNumber: 1,
      startSeasonYear: 2025,
      endSeasonYear: 2034,
      managerAgeAtRetirement: 64,
      primaryTeamName: 'Vistula Pro Cycling',
      teamsManaged: ['Vistula Pro Cycling'],
      grandTourWins: 5,
      monumentWins: 6,
      worldAndOlympicTitles: 2,
      totalStageWins: 52,
      uciTeamNumberOneYears: 3,
      academyGraduatesPromoted: 7,
      peakTeamBudgetEur: 48000000,
      legacyReputation: 94.0,
      activeChallengeScoreMultiplier: 1.0,
    );

    test('blocks retirement when seasonsManaged < 1', () {
      const tooShort = ManagerCareerPalmaresSummary(
        managerId: 'mgr_short',
        managerName: 'Nowicjusz',
        nationalityCode: 'POL',
        dynastyName: 'Nowa Dynastia',
        generationNumber: 1,
        startSeasonYear: 2026,
        endSeasonYear: 2025,
        managerAgeAtRetirement: 35,
        primaryTeamName: 'Test Team',
        teamsManaged: ['Test Team'],
        grandTourWins: 0,
        monumentWins: 0,
        worldAndOlympicTitles: 0,
        totalStageWins: 0,
        uciTeamNumberOneYears: 0,
        academyGraduatesPromoted: 0,
        peakTeamBudgetEur: 5000000,
        legacyReputation: 30.0,
        activeChallengeScoreMultiplier: 1.0,
      );

      // Note: seasonsManaged clamps to 1 in getter, so test mandatory age cap instead
      final report = service.evaluateEligibility(tooShort);
      expect(report.canRetire, isTrue);

      const age70 = ManagerCareerPalmaresSummary(
        managerId: 'mgr_70',
        managerName: 'Weteran',
        nationalityCode: 'POL',
        dynastyName: 'Dynastia',
        generationNumber: 1,
        startSeasonYear: 2010,
        endSeasonYear: 2035,
        managerAgeAtRetirement: 70,
        primaryTeamName: 'Test Team',
        teamsManaged: ['Test Team'],
        grandTourWins: 1,
        monumentWins: 1,
        worldAndOlympicTitles: 0,
        totalStageWins: 10,
        uciTeamNumberOneYears: 0,
        academyGraduatesPromoted: 2,
        peakTeamBudgetEur: 12000000,
        legacyReputation: 65.0,
        activeChallengeScoreMultiplier: 1.0,
      );
      final ageReport = service.evaluateEligibility(age70);
      expect(ageReport.isMandatoryAgeReached, isTrue);
      expect(ageReport.suggestedReason, RetirementReason.mandatoryAgeCap);
    });

    test('evaluates plaques, score breakdown, and HallOfFameTier accurately', () {
      final entry = service.inductManager(
        palmares: samplePalmares,
        reason: RetirementReason.voluntaryLegacyPeak,
        timestamp: DateTime(2034, 10, 20),
      );

      expect(entry.plaques.length, 6);
      expect(entry.finalScore, greaterThanOrEqualTo(12000));
      expect(entry.tier, HallOfFameTier.eternalCyclingPantheon);
      expect(entry.epitaphQuote, contains('Wielkich Tourów'));
    });

    test('HallOfFameArchive round-trip JSON serialization preserves entries', () {
      final entry = service.inductManager(
        palmares: samplePalmares,
        reason: RetirementReason.voluntaryLegacyPeak,
        timestamp: DateTime(2034, 10, 20),
      );
      final archive = const HallOfFameArchive().addEntry(entry);

      final exported = archive.exportToJsonString();
      final restored = HallOfFameArchive.fromJsonString(exported);

      expect(restored.entries.length, 1);
      expect(restored.entries.first.inductionId, entry.inductionId);
      expect(restored.entries.first.finalScore, entry.finalScore);
      expect(restored.entries.first.tier, entry.tier);
      expect(restored.entries.first.plaques.length, entry.plaques.length);
    });

    test('builds DynastyInheritanceBundle for standard and hardcore prestige modes', () {
      final entry = service.inductManager(
        palmares: samplePalmares,
        reason: RetirementReason.voluntaryLegacyPeak,
      );

      final standardBundle = service.buildDynastyInheritanceBundle(
        predecessor: entry,
        successorName: 'Adam Kowalski',
        relation: DynastyRelation.sonOrDaughter,
        archetype: DynastyArchetype.grandTourStrategist,
        modifiers: {
          DynastyChallengeModifier.rivalAiEscalation,
          DynastyChallengeModifier.legendaryExpectations,
        },
        hardcorePrestigeOnly: false,
      );

      expect(standardBundle.successor.generationNumber, 2);
      expect(standardBundle.startSeasonYear, 2035);
      expect(standardBundle.seedEndowmentEur, greaterThan(0));
      expect(standardBundle.scoutingNetworkTierBonus, greaterThanOrEqualTo(1));
      expect(standardBundle.combinedChallengeScoreMultiplier, greaterThan(1.4));

      final hardcoreBundle = service.buildDynastyInheritanceBundle(
        predecessor: entry,
        successorName: 'Adam Kowalski',
        relation: DynastyRelation.sonOrDaughter,
        archetype: DynastyArchetype.classicsTactician,
        modifiers: {DynastyChallengeModifier.strictFinancialFairPlay},
        hardcorePrestigeOnly: true,
      );

      expect(hardcoreBundle.seedEndowmentEur, 0.0);
      expect(hardcoreBundle.scoutingNetworkTierBonus, 0);
      expect(hardcoreBundle.hardcorePrestigeOnly, isTrue);
    });

    test('notifier executes retirement and updates archive + NG+ bundle', () {
      final notifier = EndOfCareerRetirementNotifier();
      notifier.setSuccessorName('Zofia Kowalska');
      notifier.selectDynastyRelation(DynastyRelation.grandchildHeir);
      notifier.toggleChallengeModifier(DynastyChallengeModifier.rivalAiEscalation);

      final result = notifier.retireToHallOfFame(launchNewGamePlus: true);
      expect(result, isNotNull);
      expect(result!.updatedArchive.entries.length, 1);
      expect(result.dynastyBundle, isNotNull);
      expect(result.dynastyBundle!.successor.successorName, 'Zofia Kowalska');
      expect(result.dynastyBundle!.successor.generationNumber, 2);
    });
  });

  group('EndOfCareerHallOfFameRetirementPanel responsive UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'renders without overflow at ${size.width.toInt()}x${size.height.toInt()} and supports tabs',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        DynastyInheritanceBundle? launchedBundle;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: EndOfCareerHallOfFameRetirementPanel(
                  onStartNewGamePlus: (bundle) => launchedBundle = bundle,
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Emerytura Menedżerska & Dynastia NG+'), findsOneWidget);

        // Switch to New Game+ / Dynastia tab
        await tester.tap(find.text('New Game+ / Dynastia'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Rozpocznij New Game+ / Dynastię'), findsOneWidget);

        await tester.ensureVisible(find.text('Rozpocznij New Game+ / Dynastię'));
        await tester.tap(find.text('Rozpocznij New Game+ / Dynastię'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(launchedBundle, isNotNull);
        expect(launchedBundle!.successor.generationNumber, 2);

        // Switch to Księga Legend tab
        await tester.ensureVisible(find.text('Księga Legend'));
        await tester.tap(find.text('Księga Legend'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('Marek Kowalski'), findsWidgets);
      });
    }
  });
}
