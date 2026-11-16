import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/peloton/combativity_award_jury_evaluator.dart';

void main() {
  const evaluator = CombativityAwardJuryEvaluator();

  group('CombativityAwardJuryEvaluator unit tests', () {
    test('wybiera uciekiniera z największym kilometrażem i pracą na zmianach, przyznając czerwony numer i 2000 EUR', () {
      final decision = evaluator.evaluateStage(
        stageNumber: 6,
        stageName: 'Bayeux → Vire Normandie',
        terrain: CombativityStageTerrain.hilly,
        candidates: const [
          CombativityRiderStageTelemetry(
            riderId: 'r1',
            riderName: 'Kacper Majewski',
            teamId: 't1',
            teamName: 'Polska Grupa WT',
            teamShortCode: 'PGW',
            bibNumber: 44,
            isPlayerTeam: true,
            stageDistanceKm: 195.0,
            breakawayKilometers: 162.0,
            frontLeadPullKilometers: 94.0,
            longestSoloLeadKm: 28.0,
            mountainAttacksInitiated: 2,
            komPointsEarned: 8,
            stageRank: 18,
          ),
          CombativityRiderStageTelemetry(
            riderId: 'r2',
            riderName: 'Lucas Moreau',
            teamId: 't2',
            teamName: 'Equipe France',
            teamShortCode: 'EQF',
            bibNumber: 71,
            stageDistanceKm: 195.0,
            breakawayKilometers: 140.0,
            frontLeadPullKilometers: 22.0,
            longestSoloLeadKm: 0.0,
            stageRank: 34,
          ),
          CombativityRiderStageTelemetry(
            riderId: 'r3',
            riderName: 'Matteo Rossi',
            teamId: 't3',
            teamName: 'Italia Pro',
            teamShortCode: 'ITA',
            bibNumber: 12,
            stageDistanceKm: 195.0,
            breakawayKilometers: 180.0,
            frontLeadPullKilometers: 100.0,
            isDisqualifiedOrDnf: true,
          ),
        ],
      );

      expect(decision.isAwarded, isTrue);
      expect(decision.prizeMoneyEur, equals(2000));
      expect(decision.redDossardNextStageRiderId, equals('r1'));
      expect(decision.redDossardNextStageBibNumber, equals(44));
      expect(decision.winner, isNotNull);
      expect(decision.winner!.awardedRedDossardNextStage, isTrue);
      expect(decision.winner!.prizeMoneyEur, equals(2000));
      expect(decision.rankedNominees.length, equals(2));
      expect(decision.rankedNominees[1].prizeMoneyEur, equals(0));
      expect(decision.rankedNominees[1].awardedRedDossardNextStage, isFalse);

      final modalWinner = decision.toCombativityAwardWinner();
      expect(modalWinner, isNotNull);
      expect(modalWinner!.riderId, equals('r1'));
      expect(modalWinner.bibNumber, equals(44));
      expect(modalWinner.breakawayKilometers, equals(162.0));
    });

    test('premiuje ataki w górach na etapie górskim oraz jazdę na wietrze na płaskim', () {
      final mountainDecision = evaluator.evaluateStage(
        stageNumber: 14,
        stageName: 'Pau → Luchon-Superbagnères',
        terrain: CombativityStageTerrain.mountain,
        candidates: const [
          CombativityRiderStageTelemetry(
            riderId: 'm1',
            riderName: 'Carlos Mendoza',
            teamId: 't_col',
            teamName: 'Andes Cycling',
            teamShortCode: 'AND',
            bibNumber: 31,
            stageDistanceKm: 182.0,
            breakawayKilometers: 95.0,
            frontLeadPullKilometers: 48.0,
            mountainAttacksInitiated: 5,
            mountainAttackKilometers: 34.0,
            komPointsEarned: 42,
          ),
          CombativityRiderStageTelemetry(
            riderId: 'm2',
            riderName: 'Jan Kowalski',
            teamId: 't_pol',
            teamName: 'Polska Grupa',
            teamShortCode: 'POL',
            bibNumber: 88,
            stageDistanceKm: 182.0,
            breakawayKilometers: 105.0,
            frontLeadPullKilometers: 30.0,
          ),
        ],
      );

      expect(mountainDecision.winner?.telemetry.riderId, equals('m1'));
      expect(
        mountainDecision.winner?.breakdown.dominantHighlight,
        equals(CombativityHighlightTag.mountainAttacker),
      );

      final crosswindDecision = evaluator.evaluateStage(
        stageNumber: 4,
        stageName: 'Dunkierka → Calais',
        terrain: CombativityStageTerrain.flat,
        candidates: const [
          CombativityRiderStageTelemetry(
            riderId: 'w1',
            riderName: 'Wout Van Der Berg',
            teamId: 't_bel',
            teamName: 'Flandria Pro',
            teamShortCode: 'FLA',
            bibNumber: 5,
            stageDistanceKm: 170.0,
            breakawayKilometers: 45.0,
            crosswindEchelonPullKm: 52.0,
            crosswindAttacksInitiated: 3,
          ),
          CombativityRiderStageTelemetry(
            riderId: 'w2',
            riderName: 'Pierre Dubois',
            teamId: 't_fra',
            teamName: 'France Team',
            teamShortCode: 'FRA',
            bibNumber: 92,
            stageDistanceKm: 170.0,
            breakawayKilometers: 85.0,
            frontLeadPullKilometers: 20.0,
          ),
        ],
      );

      expect(crosswindDecision.winner?.telemetry.riderId, equals('w1'));
      expect(
        crosswindDecision.winner?.breakdown.dominantHighlight,
        equals(CombativityHighlightTag.crosswindEchelonInstigator),
      );
    });

    test('nie przyznaje nagrody na etapie jazdy na czas oraz przy pustej liście', () {
      final ttDecision = evaluator.evaluateStage(
        stageNumber: 5,
        stageName: 'Caen ITT',
        terrain: CombativityStageTerrain.timeTrial,
        candidates: const [
          CombativityRiderStageTelemetry(
            riderId: 'tt1',
            riderName: 'Remco Janssens',
            teamId: 't1',
            teamName: 'Belgium Pro',
            teamShortCode: 'BEL',
            bibNumber: 1,
            stageDistanceKm: 33.0,
            longestSoloLeadKm: 33.0,
          ),
        ],
      );

      expect(ttDecision.isAwarded, isFalse);
      expect(ttDecision.winner, isNull);
      expect(ttDecision.prizeMoneyEur, equals(0));
      expect(ttDecision.redDossardNextStageRiderId, isNull);

      final emptyDecision = evaluator.evaluateStage(
        stageNumber: 2,
        stageName: 'Empty Stage',
        terrain: CombativityStageTerrain.flat,
        candidates: const [],
      );

      expect(emptyDecision.isAwarded, isFalse);
      expect(emptyDecision.rankedNominees, isEmpty);
    });

    test('serializacja JSON zachowuje wszystkie pola werdyktu', () {
      final original = evaluator.evaluateStage(
        stageNumber: 9,
        stageName: 'Troyes → Troyes',
        terrain: CombativityStageTerrain.cobbles,
        candidates: const [
          CombativityRiderStageTelemetry(
            riderId: 'c1',
            riderName: 'Mads Lindholm',
            teamId: 't_den',
            teamName: 'Nordic Cycling',
            teamShortCode: 'NOR',
            bibNumber: 14,
            stageDistanceKm: 199.0,
            breakawayKilometers: 120.0,
            frontLeadPullKilometers: 60.0,
            crosswindEchelonPullKm: 25.0,
            crosswindAttacksInitiated: 2,
          ),
        ],
      );

      final restored = CombativityStageAwardDecision.fromJson(original.toJson());
      expect(restored.stageNumber, equals(9));
      expect(restored.terrain, equals(CombativityStageTerrain.cobbles));
      expect(restored.isAwarded, isTrue);
      expect(restored.prizeMoneyEur, equals(2000));
      expect(restored.redDossardNextStageBibNumber, equals(14));
      expect(restored.winner?.telemetry.riderName, equals('Mads Lindholm'));
    });
  });

  group('CombativityAwardJuryPanel responsive widget tests', () {
    final decision = evaluator.evaluateStage(
      stageNumber: 12,
      stageName: 'Aurillac → Villeneuve-sur-Lot',
      terrain: CombativityStageTerrain.hilly,
      candidates: const [
        CombativityRiderStageTelemetry(
          riderId: 'p1',
          riderName: 'Michał Kwiatkowski',
          teamId: 't_pol',
          teamName: 'Polska Grupa WT',
          teamShortCode: 'PGW',
          bibNumber: 23,
          isPlayerTeam: true,
          stageDistanceKm: 204.0,
          breakawayKilometers: 148.0,
          frontLeadPullKilometers: 72.0,
          longestSoloLeadKm: 24.0,
          mountainAttacksInitiated: 3,
          crosswindEchelonPullKm: 18.0,
          komPointsEarned: 12,
        ),
        CombativityRiderStageTelemetry(
          riderId: 'p2',
          riderName: 'Julien Bernard',
          teamId: 't_fra',
          teamName: 'Team Gallia',
          teamShortCode: 'GAL',
          bibNumber: 65,
          stageDistanceKm: 204.0,
          breakawayKilometers: 125.0,
          frontLeadPullKilometers: 40.0,
          mountainAttacksInitiated: 1,
        ),
      ],
    );

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnień w rozdzielczości ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: CombativityAwardJuryPanel(decision: decision),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('CZERWONY NUMER #23'), findsOneWidget);
          expect(find.text('+2000 EUR'), findsOneWidget);
          expect(find.textContaining('Michał Kwiatkowski'), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('filtry i wybór nominowanego aktualizują podgląd punktacji', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: CombativityAwardJuryPanel(decision: decision),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Góry i wiatr'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.textContaining('Julien Bernard'), findsWidgets);

      await tester.tap(find.textContaining('Julien Bernard').first);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.textContaining('Punktacja Jury • Julien Bernard'), findsOneWidget);
    });
  });
}
