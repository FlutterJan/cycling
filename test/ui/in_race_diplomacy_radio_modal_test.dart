import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/in_race_peloton_diplomacy_engine.dart';
import 'package:pro_peloton_manager/ui/widgets/in_race_diplomacy_radio_modal.dart';

void main() {
  const playerTeam = DiplomacyTeamContext(
    teamId: 'team_player',
    teamName: 'Polonia Pro Cycling',
    riderId: 'rider_p1',
    riderName: 'Jan Kowalski',
    gcPosition: 2,
    gcGapToLeaderSeconds: 42.0,
  );

  const rivalBreakaway = DiplomacyTeamContext(
    teamId: 'team_rival_a',
    teamName: 'Alpecin-Deceuninck',
    riderId: 'rider_ra',
    riderName: 'Mathieu Van Der Berg',
    gcPosition: 28,
    gcGapToLeaderSeconds: 820.0,
    hasStageWinAmbition: true,
    isInSameGroup: true,
    trustScore: 78.0,
  );

  const rivalCoalition = DiplomacyTeamContext(
    teamId: 'team_rival_b',
    teamName: 'Ineos Grenadiers',
    riderId: 'rider_rb',
    riderName: 'Thomas Pidcock',
    gcPosition: 4,
    gcGapToLeaderSeconds: 75.0,
    isInSameGroup: true,
    trustScore: 74.0,
    aggressionFactor: 0.85,
  );

  const sampleOffer = IncomingRivalPactOffer(
    offerId: 'offer_1',
    pactType: DiplomacyPactType.stageForGcDeal,
    fromTeam: rivalBreakaway,
    offeredAtKm: 132.0,
    expiresAtKm: 168.0,
    headline: 'Alpecin-Deceuninck proponuje układ „Etap za GC”',
    termsSummary:
        'Dam Ci pełne zmiany do finałowego podjazdu, jeśli nie będziesz finiszował o zwycięstwo etapowe.',
  );

  Widget wrapForSize(Widget child, Size size) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }

  group('IncomingRivalPactOffer serialization', () {
    test('roundtrips to/from JSON', () {
      final json = sampleOffer.toJson();
      final restored = IncomingRivalPactOffer.fromJson(json);

      expect(restored.offerId, sampleOffer.offerId);
      expect(restored.pactType, sampleOffer.pactType);
      expect(restored.fromTeam.teamId, sampleOffer.fromTeam.teamId);
      expect(restored.offeredAtKm, sampleOffer.offeredAtKm);
      expect(restored.expiresAtKm, sampleOffer.expiresAtKm);
      expect(restored.headline, sampleOffer.headline);
      expect(restored.termsSummary, sampleOffer.termsSummary);
    });
  });

  group('InRaceDiplomacyRadioModal responsive & interaction tests', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapForSize(
              const InRaceDiplomacyRadioModal(
                initialState: PelotonDiplomacyState(),
                playerTeam: playerTeam,
                rivalCandidates: [rivalBreakaway, rivalCoalition],
                incomingOffers: [sampleOffer],
                currentStageKm: 135.0,
                totalStageKm: 168.0,
              ),
              size,
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.text('RADIO WYŚCIGOWE — DYPLOMACJA'), findsOneWidget);
          expect(find.text('Zawrzyj układ'), findsOneWidget);
          expect(find.text('Odrzuć ofertę'), findsOneWidget);
        },
      );
    }

    testWidgets('accepts incoming offer and creates active pact', (tester) async {
      PelotonDiplomacyState? latestState;
      InRaceDiplomacyRadioResult? closedResult;

      await tester.pumpWidget(
        wrapForSize(
          InRaceDiplomacyRadioModal(
            initialState: const PelotonDiplomacyState(),
            playerTeam: playerTeam,
            rivalCandidates: const [rivalBreakaway],
            incomingOffers: const [sampleOffer],
            currentStageKm: 135.0,
            totalStageKm: 168.0,
            onStateChanged: (s) => latestState = s,
            onCloseWithResult: (r) => closedResult = r,
          ),
          const Size(1024, 768),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Zawrzyj układ'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(latestState, isNotNull);
      expect(latestState!.activePacts, hasLength(1));
      expect(
        latestState!.activePacts.first.type,
        DiplomacyPactType.stageForGcDeal,
      );
      expect(find.text('Brak oczekujących ofert radiowych'), findsOneWidget);

      await tester.tap(find.text('Wróć na trasę'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(closedResult, isNotNull);
      expect(closedResult!.acceptedOfferIds, ['offer_1']);
      expect(closedResult!.newlyCreatedPacts, hasLength(1));
    });

    testWidgets('rejects incoming offer and logs rejection', (tester) async {
      InRaceDiplomacyRadioResult? closedResult;

      await tester.pumpWidget(
        wrapForSize(
          InRaceDiplomacyRadioModal(
            initialState: const PelotonDiplomacyState(),
            playerTeam: playerTeam,
            rivalCandidates: const [rivalBreakaway],
            incomingOffers: const [sampleOffer],
            currentStageKm: 135.0,
            totalStageKm: 168.0,
            onCloseWithResult: (r) => closedResult = r,
          ),
          const Size(1024, 768),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Odrzuć ofertę'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Wróć na trasę'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(closedResult, isNotNull);
      expect(closedResult!.rejectedOfferIds, ['offer_1']);
      expect(closedResult!.updatedState.activePacts, isEmpty);
    });

    testWidgets('proposes new pact and allows manual betrayal', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      PelotonDiplomacyState? latestState;

      await tester.pumpWidget(
        wrapForSize(
          InRaceDiplomacyRadioModal(
            initialState: const PelotonDiplomacyState(),
            playerTeam: playerTeam,
            rivalCandidates: const [rivalBreakaway, rivalCoalition],
            incomingOffers: const [],
            currentStageKm: 140.0,
            totalStageKm: 168.0,
            onStateChanged: (s) => latestState = s,
          ),
          const Size(1600, 900),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Nadaj propozycję do Alpecin-Deceuninck'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(latestState, isNotNull);
      expect(latestState!.activePacts, hasLength(1));

      await tester.tap(find.text('Aktywne Pakty'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Zerwij pakt (Zdrada!)'), findsOneWidget);
      await tester.tap(find.text('Zerwij pakt (Zdrada!)'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(latestState!.activePacts, isEmpty);
      expect(latestState!.betrayalHistory, hasLength(1));
      expect(find.text('ALERT ZDRADY (BETRAYAL!)'), findsOneWidget);
    });

    testWidgets('respects disabled state when isInteractiveEnabled is false',
        (tester) async {
      PelotonDiplomacyState? latestState;

      await tester.pumpWidget(
        wrapForSize(
          InRaceDiplomacyRadioModal(
            initialState: const PelotonDiplomacyState(),
            playerTeam: playerTeam,
            rivalCandidates: const [rivalBreakaway],
            incomingOffers: const [sampleOffer],
            currentStageKm: 135.0,
            totalStageKm: 168.0,
            isInteractiveEnabled: false,
            onStateChanged: (s) => latestState = s,
          ),
          const Size(1024, 768),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Zawrzyj układ'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(latestState, isNull);
    });

    testWidgets('showInRaceDiplomacyRadioModal opens dialog and returns result',
        (tester) async {
      InRaceDiplomacyRadioResult? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  dialogResult = await showInRaceDiplomacyRadioModal(
                    context,
                    initialState: const PelotonDiplomacyState(),
                    playerTeam: playerTeam,
                    rivalCandidates: const [rivalBreakaway],
                    incomingOffers: const [sampleOffer],
                    currentStageKm: 135.0,
                    totalStageKm: 168.0,
                  );
                },
                child: const Text('Otwórz Radio'),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Otwórz Radio'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('RADIO WYŚCIGOWE — DYPLOMACJA'), findsOneWidget);

      await tester.tap(find.text('Wróć na trasę'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(dialogResult, isNotNull);
    });
  });
}
