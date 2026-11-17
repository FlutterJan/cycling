import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/custom_team_sponsor_storyline_generator.dart';

void main() {
  const generator = CustomTeamSponsorStorylineGenerator();

  const defaultContext = StorylineGenerationContext(
    teamName: 'Veloce Orlen Pro',
    teamCountryCode: 'PL',
    sponsorName: 'Orlen Aero Tech',
    sponsorBillionaireName: 'Marek Solski',
    currentSeason: 2026,
    teamBudgetEur: 5000000,
    rivalTeamName: 'Apex Horizon Global',
    rivalBillionaireName: 'Henrik Lindqvist',
    featuredRiderName: 'Kacper Kowalski',
    featuredRiderAge: 30,
    hadRecentMajorInjury: true,
    seed: 202607,
  );

  group('CustomTeamSponsorStorylineGenerator unit tests', () {
    test('generates all 4 multi-season storyline archetypes deterministically', () {
      final arcs1 = generator.generateInitialStorylines(defaultContext, maxArcs: 4);
      final arcs2 = generator.generateInitialStorylines(defaultContext, maxArcs: 4);

      expect(arcs1.length, 4);
      expect(arcs1.map((a) => a.archetype).toSet(), {
        StorylineArchetype.billionaireRivalry,
        StorylineArchetype.nationalHomeRacePressure,
        StorylineArchetype.fallenChampionComeback,
        StorylineArchetype.historicDynastyBuilder,
      });

      for (var i = 0; i < arcs1.length; i++) {
        expect(arcs1[i].id, arcs2[i].id);
        expect(arcs1[i].chapters.length, greaterThanOrEqualTo(3));
        expect(arcs1[i].homeRaceName, 'Tour de Pologne');
      }
    });

    test('resolves home race by country code and supports override', () {
      expect(generator.resolveHomeRaceName('FR'), 'Tour de France');
      expect(generator.resolveHomeRaceName('IT'), 'Giro d\'Italia');
      expect(
        generator.resolveHomeRaceName('PL', override: 'Wyścig Pokoju'),
        'Wyścig Pokoju',
      );
    });

    test('applyDecision advances multi-year chapters and completes arc', () {
      var arc = generator.generateArcForArchetype(
        StorylineArchetype.billionaireRivalry,
        defaultContext,
      );
      expect(arc.totalPlannedSeasons, 3);
      expect(arc.currentChapterIndex, 0);
      expect(arc.status, StorylineStatus.active);

      for (var step = 0; step < 3; step++) {
        final optionId = arc.activeChapter!.options.first.id;
        final res = generator.applyDecision(
          arc,
          optionId,
          currentBudgetEur: 5000000,
        );
        arc = res.updatedArc;
        expect(res.appliedEffect, isNotNull);
        if (step < 2) {
          expect(res.isArcFinished, isFalse);
          expect(arc.status, StorylineStatus.active);
          expect(arc.currentChapterIndex, step + 1);
        } else {
          expect(res.isArcFinished, isTrue);
          expect(arc.status, StorylineStatus.completed);
        }
      }
    });

    test('applyDecision rejects unaffordable option and unknown optionId', () {
      final arc = generator.generateArcForArchetype(
        StorylineArchetype.billionaireRivalry,
        defaultContext,
      );
      final expensiveOption = arc.activeChapter!.options.first;
      expect(expensiveOption.requiresMinBudgetEur, greaterThan(0));

      final poorResult = generator.applyDecision(
        arc,
        expensiveOption.id,
        currentBudgetEur: 100000,
      );
      expect(poorResult.appliedEffect, isNull);
      expect(poorResult.updatedArc.currentChapterIndex, 0);

      final unknownResult = generator.applyDecision(
        arc,
        'non_existent_option',
        currentBudgetEur: 5000000,
      );
      expect(unknownResult.appliedEffect, isNull);
    });

    test('evaluateSeasonProgress handles multi-season success and failure', () {
      var dynastyArc = generator.generateArcForArchetype(
        StorylineArchetype.historicDynastyBuilder,
        defaultContext,
      );
      expect(dynastyArc.chapters.length, 4);

      final s1 = generator.evaluateSeasonProgress(
        dynastyArc,
        const StorylineSeasonProgressInput(
          seasonYear: 2026,
          uciTeamRank: 6,
        ),
      );
      expect(s1.updatedArc.chapters[0].isCompleted, isTrue);
      expect(s1.updatedArc.currentChapterIndex, 1);
      expect(s1.updatedArc.dynastyPoints, 25);

      var nationalArc = generator.generateArcForArchetype(
        StorylineArchetype.nationalHomeRacePressure,
        defaultContext,
      );
      for (var i = 0; i < 3; i++) {
        nationalArc = generator
            .evaluateSeasonProgress(
              nationalArc,
              StorylineSeasonProgressInput(
                seasonYear: 2026 + i,
                homeRaceWon: false,
                homeRacePodium: false,
              ),
            )
            .updatedArc;
      }
      expect(nationalArc.status, StorylineStatus.failed);
    });

    test('JSON round-trip preserves CareerStorylineArc completely', () {
      final arc = generator.generateArcForArchetype(
        StorylineArchetype.fallenChampionComeback,
        defaultContext,
      );
      final json = arc.toJson();
      final restored = CareerStorylineArc.fromJson(json);

      expect(restored.id, arc.id);
      expect(restored.archetype, arc.archetype);
      expect(restored.title, arc.title);
      expect(restored.featuredRiderName, arc.featuredRiderName);
      expect(restored.chapters.length, arc.chapters.length);
      expect(
        restored.chapters.first.options.first.id,
        arc.chapters.first.options.first.id,
      );
    });

    test('Riverpod notifier manages arcs, filters, and decisions', () {
      final notifier = CustomTeamSponsorStorylineNotifier(
        initialContext: defaultContext,
      );
      expect(notifier.state.arcs.length, 4);

      notifier.setFilter(StorylineArchetype.historicDynastyBuilder);
      expect(notifier.state.filteredArcs.length, 1);

      notifier.setFilter(null);
      expect(notifier.state.filteredArcs.length, 4);

      final firstArc = notifier.state.arcs.first;
      final firstOption = firstArc.activeChapter!.options.first;
      notifier.makeDecision(firstArc.id, firstOption.id);
      expect(
        notifier.state.arcs.first.currentChapterIndex,
        1,
      );
    });
  });

  group('CustomTeamSponsorStorylinePanel responsive widget tests', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      List<CareerStorylineArc>? arcs,
      bool enabled = true,
      StorylineArchetype? filter,
      ValueChanged<StorylineArchetype?>? onFilterChanged,
      void Function(String, String)? onDecisionSelected,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testArcs =
          arcs ?? generator.generateInitialStorylines(defaultContext, maxArcs: 4);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTeamSponsorStorylinePanel(
              arcs: testArcs,
              availableBudgetEur: 5000000,
              filterArchetype: filter,
              enabled: enabled,
              statusMessage: 'Nowy raport medialny ze świata peletonu.',
              onFilterChanged: onFilterChanged,
              onDecisionSelected: onDecisionSelected,
              onGenerateNewArc: () {},
              onEvaluateSeason: (_) {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final entry in {
      'mobile 390x844': const Size(390, 844),
      'tablet 1024x768': const Size(1024, 768),
      'desktop 1600x900': const Size(1600, 900),
    }.entries) {
      testWidgets('renders cleanly without overflow on ${entry.key}', (
        tester,
      ) async {
        await pumpPanelAtSize(tester, entry.value);
        expect(tester.takeException(), isNull);
        expect(find.text('Wieloletnie Wątki Fabularne Kariery'), findsOneWidget);
        expect(find.text('Decyzje Strategiczne Zarządu'), findsOneWidget);
      });
    }

    testWidgets('handles filter, decision tap, empty state, and disabled state', (
      tester,
    ) async {
      StorylineArchetype? capturedFilter;
      String? capturedOption;

      await pumpPanelAtSize(
        tester,
        const Size(1280, 800),
        onFilterChanged: (f) => capturedFilter = f,
        onDecisionSelected: (_, optionId) => capturedOption = optionId,
      );

      await tester.tap(find.text('Dynastia'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(capturedFilter, StorylineArchetype.historicDynastyBuilder);

      final optionFinder = find.text('Inwestycja w Tunel Aero i R&D');
      await tester.ensureVisible(optionFinder);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(optionFinder);
      await tester.pump(const Duration(milliseconds: 250));
      expect(capturedOption, 'bill_s1_aero');

      await pumpPanelAtSize(
        tester,
        const Size(1280, 800),
        arcs: const [],
        enabled: false,
      );
      expect(
        find.text('Brak wątków fabularnych dla wybranego filtra'),
        findsOneWidget,
      );
    });
  });
}
