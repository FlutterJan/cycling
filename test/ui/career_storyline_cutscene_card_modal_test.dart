import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/custom_team_sponsor_storyline_generator.dart';
import 'package:pro_peloton_manager/ui/widgets/career_storyline_cutscene_card_modal.dart';

void main() {
  group('CareerStorylineCutsceneCardData & serialization', () {
    test('round-trips toJson and fromJson cleanly', () {
      final sample = CareerStorylineCutsceneCatalog.billionaireRivalrySample(
        currentBudgetEur: 2500000,
      );
      final restored =
          CareerStorylineCutsceneCardData.fromJson(sample.toJson());

      expect(restored.id, sample.id);
      expect(restored.archetype, sample.archetype);
      expect(restored.sceneType, sample.sceneType);
      expect(restored.seasonYear, sample.seasonYear);
      expect(restored.chapterNumber, sample.chapterNumber);
      expect(restored.totalChapters, sample.totalChapters);
      expect(restored.title, sample.title);
      expect(restored.pressSource, sample.pressSource);
      expect(restored.pressQuote, sample.pressQuote);
      expect(restored.longTermGoalTitle, sample.longTermGoalTitle);
      expect(restored.currentBudgetEur, 2500000);
      expect(restored.options.length, sample.options.length);
    });

    test('converts from StorylineChapter and CareerStorylineArc', () {
      const generator = CustomTeamSponsorStorylineGenerator();
      final arc = generator.generateArcForArchetype(
        StorylineArchetype.nationalHomeRacePressure,
        const StorylineGenerationContext(
          teamName: 'Biało-Czerwoni WT',
          sponsorName: 'Orlen Aero',
          teamCountryCode: 'POL',
          featuredRiderName: 'M. Kwiatkowski',
          currentSeason: 2026,
          teamBudgetEur: 3200000,
          teamPrestige: 82,
        ),
      );

      final data = CareerStorylineCutsceneCardData.fromStorylineChapter(
        arc: arc,
        chapter: arc.chapters.first,
        currentBudgetEur: 3200000,
      );

      expect(data.archetype, StorylineArchetype.nationalHomeRacePressure);
      expect(data.sceneType, CutsceneIllustrationScene.pressStorm);
      expect(data.options, isNotEmpty);
      expect(data.longTermGoalTitle, arc.subtitle);
    });

    test('CareerStorylineCutsceneResult serializes and deserializes', () {
      final sample = CareerStorylineCutsceneCatalog.billionaireRivalrySample();
      final result = CareerStorylineCutsceneResult(
        cardId: sample.id,
        selectedOption: sample.options.first,
        previousBudgetEur: 2400000,
        updatedBudgetEur: 1950000,
        decidedAt: DateTime(2026, 6, 15),
      );

      final restored =
          CareerStorylineCutsceneResult.fromJson(result.toJson());
      expect(restored.cardId, sample.id);
      expect(restored.selectedOption.id, sample.options.first.id);
      expect(restored.previousBudgetEur, 2400000);
      expect(restored.updatedBudgetEur, 1950000);
    });
  });

  group('CareerStorylineCutsceneCardModal widget', () {
    Widget buildHarness({
      required Size size,
      required CareerStorylineCutsceneCardData data,
      ValueChanged<CareerStorylineCutsceneResult>? onConfirmed,
      VoidCallback? onClose,
      bool isReadOnly = false,
    }) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: CareerStorylineCutsceneCardModal(
                data: data,
                onDecisionConfirmed: onConfirmed,
                onClose: onClose,
                isReadOnly: isReadOnly,
              ),
            ),
          ),
        ),
      );
    }

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final data =
              CareerStorylineCutsceneCatalog.billionaireRivalrySample();
          await tester.pumpWidget(buildHarness(size: size, data: data));
          await tester.pump(const Duration(milliseconds: 350));

          expect(find.text(data.title), findsOneWidget);
          expect(find.text(data.pressSource), findsOneWidget);
          expect(find.text(data.pressQuote), findsOneWidget);
          expect(find.text(data.longTermGoalTitle), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('selects strategic option and confirms budget impact',
        (tester) async {
      const size = Size(1280, 800);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      CareerStorylineCutsceneResult? capturedResult;
      final data = CareerStorylineCutsceneCatalog.billionaireRivalrySample(
        currentBudgetEur: 2000000,
      );

      await tester.pumpWidget(
        buildHarness(
          size: size,
          data: data,
          onConfirmed: (res) => capturedResult = res,
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));

      // Bez wyboru przycisk zatwierdzenia nie emituje wyniku
      await tester.tap(find.byKey(const Key('cutscene_confirm_button')));
      await tester.pump(const Duration(milliseconds: 150));
      expect(capturedResult, isNull);

      // Wybór pierwszej opcji (-450k EUR)
      await tester.tap(find.byKey(const Key('cutscene_option_opt_aero_blitz')));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('WYBRANO'), findsOneWidget);
      expect(
        find.text(data.options.first.effect.outcomeSummary),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('cutscene_confirm_button')));
      await tester.pump(const Duration(milliseconds: 150));

      expect(capturedResult, isNotNull);
      expect(capturedResult!.selectedOption.id, 'opt_aero_blitz');
      expect(capturedResult!.previousBudgetEur, 2000000);
      expect(capturedResult!.updatedBudgetEur, 1550000);
    });

    testWidgets('disables unaffordable option and handles empty options',
        (tester) async {
      const size = Size(1024, 768);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final lowBudgetData =
          CareerStorylineCutsceneCatalog.billionaireRivalrySample(
        currentBudgetEur: 100000,
      );

      await tester.pumpWidget(buildHarness(size: size, data: lowBudgetData));
      await tester.pump(const Duration(milliseconds: 350));

      // Pierwsza opcja wymaga 450k EUR -> zablokowana
      await tester.tap(find.byKey(const Key('cutscene_option_opt_aero_blitz')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('WYBRANO'), findsNothing);
      expect(find.textContaining('Wymagany budżet:'), findsOneWidget);

      // Pusta lista opcji
      const emptyData = CareerStorylineCutsceneCardData(
        id: 'empty_case',
        archetype: StorylineArchetype.fallenChampionComeback,
        sceneType: CutsceneIllustrationScene.medicalComeback,
        seasonYear: 2027,
        chapterNumber: 2,
        totalChapters: 3,
        title: 'Powrót po Kontuzji',
        subtitle: 'Giro d\'Italia • Etap 16',
        narrativeBody: 'Badania kontrolne przed startem.',
        pressQuote: '„Forma rośnie z tygodnia na tydzień.”',
        pressSource: 'LA GAZZETTA',
        pressHeadline: 'POWRÓT MISTRZA',
        longTermGoalTitle: 'Podium Grand Touru',
        longTermGoalProgress: 0.66,
        currentBudgetEur: 500000,
        options: [],
      );

      await tester.pumpWidget(buildHarness(size: size, data: emptyData));
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        find.text('Brak dostępnych decyzji strategicznych dla tego rozdziału.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders all vector cutscene scenes cleanly', (tester) async {
      const size = Size(1024, 768);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final base = CareerStorylineCutsceneCatalog.billionaireRivalrySample();
      for (final scene in CutsceneIllustrationScene.values) {
        final variant = CareerStorylineCutsceneCardData(
          id: 'scene_${scene.name}',
          archetype: base.archetype,
          sceneType: scene,
          seasonYear: base.seasonYear,
          chapterNumber: 1,
          totalChapters: 3,
          title: base.title,
          subtitle: base.subtitle,
          narrativeBody: base.narrativeBody,
          pressQuote: base.pressQuote,
          pressSource: base.pressSource,
          pressHeadline: base.pressHeadline,
          longTermGoalTitle: base.longTermGoalTitle,
          longTermGoalProgress: 0.5,
          currentBudgetEur: base.currentBudgetEur,
          options: base.options,
        );

        await tester.pumpWidget(buildHarness(size: size, data: variant));
        await tester.pump(const Duration(milliseconds: 320));
        expect(tester.takeException(), isNull);
      }
    });
  });
}
