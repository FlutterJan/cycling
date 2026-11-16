// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/pre_season_team_presentation_event.dart';
import 'package:pro_peloton_manager/ui/widgets/team_presentation_stage_modal.dart';

void main() {
  group('TeamPresentationStageModal Data & Serialization', () {
    test('StageLeaderPresentationEntry serializes and deserializes cleanly', () {
      const entry = StageLeaderPresentationEntry(
        id: 'r1',
        name: 'Marek Kowalski',
        roleLabel: 'Lider GC',
        nationalityIso: 'POL',
        overallRating: 88,
        quote: 'Jedziemy po podium!',
        isNewSigning: true,
      );

      final json = entry.toJson();
      final decoded = StageLeaderPresentationEntry.fromJson(json);

      expect(decoded.id, 'r1');
      expect(decoded.name, 'Marek Kowalski');
      expect(decoded.roleLabel, 'Lider GC');
      expect(decoded.nationalityIso, 'POL');
      expect(decoded.overallRating, 88);
      expect(decoded.isNewSigning, isTrue);
    });
  });

  group('TeamPresentationStageModal Widget & Responsiveness', () {
    Future<void> pumpModalAtSize(
      WidgetTester tester, {
      required Size size,
      required TeamPresentationStageData data,
      ValueChanged<TeamPresentationStageResult>? onConfirm,
      bool isConfirmEnabled = true,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamPresentationStageModal(
              data: data,
              isConfirmEnabled: isConfirmEnabled,
              onConfirmObjective: onConfirm,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final resolution in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${resolution.width.toInt()}x${resolution.height.toInt()}',
        (tester) async {
          await pumpModalAtSize(
            tester,
            size: resolution,
            data: TeamPresentationStageData.sample(),
          );

          expect(find.textContaining('GALA PREZENTACJI ZESPOŁU 2026'), findsOneWidget);
          expect(find.text('Marek Kowalski'), findsOneWidget);
          expect(find.text('Romet Aero Carbon SL-9'), findsOneWidget);
          expect(find.text('Ogłoś Cele Sezonu'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('handles empty leaders list gracefully', (tester) async {
      const emptyLeadersData = TeamPresentationStageData(
        teamName: 'Solo Cycling',
        teamTla: 'SOL',
        seasonYear: 2026,
        sponsorName: 'AeroTech',
        bikeModelName: 'Carbon X1',
        leaders: [],
      );

      await pumpModalAtSize(
        tester,
        size: const Size(1024, 768),
        data: emptyLeadersData,
      );

      expect(find.text('Carbon X1'), findsOneWidget);
      expect(
        find.textContaining('Oficjalna prezentacja maszyny Carbon X1'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('selects leader, triggers flash, changes objective & confirms', (tester) async {
      TeamPresentationStageResult? capturedResult;

      await pumpModalAtSize(
        tester,
        size: const Size(1280, 900),
        data: TeamPresentationStageData.sample(),
        onConfirm: (result) => capturedResult = result,
      );

      // Kliknij drugiego lidera na scenie
      await tester.tap(find.text('Lukas Van Der Berg'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.textContaining('sztywność węzła suportu', findRichText: true),
        findsOneWidget,
      );

      // Wyzwól błyski aparatów
      await tester.tap(find.byIcon(Icons.camera_alt_rounded));
      await tester.pump(const Duration(milliseconds: 300));

      // Wybierz inny cel sezonowy i poziom ambicji
      final objectiveFinder = find.text(
        SeasonMainObjectiveCategory.springMonumentsVictory.label,
      );
      await tester.ensureVisible(objectiveFinder);
      await tester.tap(objectiveFinder);
      await tester.pump(const Duration(milliseconds: 250));

      final ambitionFinder = find.text(
        SeasonObjectiveAmbitionLevel.allInGlory.label,
      );
      await tester.ensureVisible(ambitionFinder);
      await tester.tap(ambitionFinder);
      await tester.pump(const Duration(milliseconds: 250));

      // Zatwierdź deklarację celów
      final confirmFinder = find.text('Ogłoś Cele Sezonu');
      await tester.ensureVisible(confirmFinder);
      await tester.tap(confirmFinder);
      await tester.pump(const Duration(milliseconds: 300));

      expect(capturedResult, isNotNull);
      expect(
        capturedResult!.selectedObjective,
        SeasonMainObjectiveCategory.springMonumentsVictory,
      );
      expect(
        capturedResult!.ambitionLevel,
        SeasonObjectiveAmbitionLevel.allInGlory,
      );
      expect(capturedResult!.expectedMoraleDelta, 6);
    });

    testWidgets('respects disabled confirm button state', (tester) async {
      bool confirmed = false;

      await pumpModalAtSize(
        tester,
        size: const Size(1024, 768),
        data: TeamPresentationStageData.sample(),
        isConfirmEnabled: false,
        onConfirm: (_) => confirmed = true,
      );

      final confirmFinder = find.text('Ogłoś Cele Sezonu');
      await tester.ensureVisible(confirmFinder);
      await tester.tap(confirmFinder);
      await tester.pump(const Duration(milliseconds: 300));

      expect(confirmed, isFalse);
    });
  });
}
