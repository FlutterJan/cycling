import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/youth_talent_summer_combine_camp.dart';

void main() {
  group('YouthTalentSummerCombineCampService', () {
    const service = YouthTalentSummerCombineCampService();

    test('launches annual combine with 17-year-olds from global regions and serializes JSON', () {
      final edition = service.launchAnnualCombine(
        seasonYear: 2027,
        location: CombineCampLocation.aigleUciWcc,
        candidateCount: 14,
        maxSlotsToSign: 3,
        random: math.Random(42),
      );

      expect(edition.seasonYear, 2027);
      expect(edition.candidates.length, 14);
      expect(edition.remainingSignSlots, 3);
      expect(edition.phase, CombineCampPhase.labTestingInProgress);

      final regionsPresent = edition.candidates.map((c) => c.region).toSet();
      expect(regionsPresent.length, CombineRegion.values.length);

      for (final candidate in edition.candidates) {
        expect(candidate.rider.birthDate.year, 2027 - 17);
        expect(
          candidate.estimatedPotentialMin <= candidate.estimatedPotentialMax,
          isTrue,
        );
      }

      final json = edition.toJson();
      final restored = CombineCampEdition.fromJson(json);
      expect(restored.seasonYear, edition.seasonYear);
      expect(restored.location, edition.location);
      expect(restored.candidates.length, edition.candidates.length);
      expect(restored.candidates.first.id, edition.candidates.first.id);
    });

    test('lab stations narrow potential fog-of-war and update composite score', () {
      final initial = service.launchAnnualCombine(
        seasonYear: 2026,
        candidateCount: 10,
        random: math.Random(101),
      );
      final target = initial.candidates.first;
      final initialSpread = target.potentialSpread;

      final res = service.runAllLabTestsForCandidate(
        edition: initial,
        candidateId: target.id,
        scoutSkill: 90,
        availableBudgetEur: 200000,
        random: math.Random(102),
      );

      expect(res.success, isTrue);
      expect(res.costEur, greaterThan(0));
      final updated = res.updatedEdition.findCandidate(target.id)!;
      expect(updated.isFullyLabTested, isTrue);
      expect(updated.combineCompositeScore, greaterThan(0));
      expect(updated.potentialSpread, lessThanOrEqualTo(initialSpread));
    });

    test('selection road race ranks all candidates and opens drafting window', () {
      var edition = service.launchAnnualCombine(
        seasonYear: 2026,
        candidateCount: 12,
        random: math.Random(7),
      );
      edition = service
          .runBatchLabTestsForAll(
            edition: edition,
            availableBudgetEur: 500000,
            random: math.Random(8),
          )
          .updatedEdition;

      final raceOutcome = service.simulateSelectionRoadRace(
        edition: edition,
        random: math.Random(9),
      );

      expect(raceOutcome.success, isTrue);
      expect(raceOutcome.updatedEdition.phase, CombineCampPhase.draftingWindowOpen);
      expect(raceOutcome.updatedEdition.isSelectionRaceCompleted, isTrue);

      final ranks = raceOutcome.updatedEdition.candidates
          .map((c) => c.raceResult!.rank)
          .toList()
        ..sort();
      expect(ranks, List.generate(12, (i) => i + 1));

      final winner = raceOutcome.updatedEdition.candidates
          .firstWhere((c) => c.raceResult!.rank == 1);
      expect(winner.raceResult!.timeGapSeconds, 0);
    });

    test('signs talent up to maxSlotsToSign and concludes camp with history entry', () {
      var edition = service.launchAnnualCombine(
        seasonYear: 2026,
        candidateCount: 8,
        maxSlotsToSign: 2,
        random: math.Random(15),
      );

      final firstId = edition.candidates[0].id;
      final secondId = edition.candidates[1].id;
      final thirdId = edition.candidates[2].id;

      final sign1 = service.signTalentFromCombine(
        edition: edition,
        candidateId: firstId,
        targetTeamId: 'my_team',
        availableBudgetEur: 500000,
        toSeniorProSquad: false,
      );
      expect(sign1.success, isTrue);
      expect(sign1.signedRider?.contract.teamId, 'my_team');
      edition = sign1.updatedEdition;
      expect(edition.remainingSignSlots, 1);

      final sign2 = service.signTalentFromCombine(
        edition: edition,
        candidateId: secondId,
        targetTeamId: 'my_team',
        availableBudgetEur: 500000,
        toSeniorProSquad: true,
      );
      expect(sign2.success, isTrue);
      edition = sign2.updatedEdition;
      expect(edition.remainingSignSlots, 0);

      final sign3 = service.signTalentFromCombine(
        edition: edition,
        candidateId: thirdId,
        targetTeamId: 'my_team',
        availableBudgetEur: 500000,
      );
      expect(sign3.success, isFalse);

      final concluded = service.concludeCombineCamp(edition: edition);
      expect(concluded.edition.phase, CombineCampPhase.concluded);
      expect(concluded.historyEntry.signedCount, 2);
      expect(concluded.historyEntry.totalCandidates, 8);
    });
  });

  group('YouthTalentSummerCombineCampPanel responsive UI', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: YouthTalentSummerCombineCampPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844, 1024x768 and 1600x900 without overflow',
        (tester) async {
      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpAtSize(tester, size);
        expect(find.text('GLOBAL YOUNG TALENT COMBINE'), findsOneWidget);
        expect(find.text('Otwórz Global Young Talent Combine'), findsOneWidget);
      }
    });

    testWidgets('launches combine, runs lab tests and simulates race in UI',
        (tester) async {
      await pumpAtSize(tester, const Size(1600, 900));

      await tester.tap(find.text('Otwórz Global Young Talent Combine'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Testy Lab (Wszyscy)'), findsOneWidget);
      expect(find.text('Symuluj Wyścig 85 km'), findsOneWidget);

      await tester.tap(find.text('Symuluj Wyścig 85 km'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Wyścig Rozegrany'), findsOneWidget);
    });
  });
}
