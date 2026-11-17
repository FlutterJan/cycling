import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/uci_commissaire_rulebook_and_var_model.dart';

void main() {
  group('UciCommissaireRulebookAndVarModel', () {
    test('initial baseline rulebook and JSON round-trip', () {
      final model = UciCommissaireRulebookAndVarModel.initial(seasonYear: 2025);
      expect(model.activeRulebook.seasonYear, 2025);
      expect(model.activeRulebook.minBikeWeightKg, 6.80);
      expect(model.activeRulebook.supertuckBanned, isTrue);
      expect(model.activeRulebook.articles, isNotEmpty);

      final json = model.toJson();
      final restored = UciCommissaireRulebookAndVarModel.fromJson(json);

      expect(restored.activeRulebook.seasonYear, 2025);
      expect(restored.activeRulebook.minBikeWeightKg, 6.80);
      expect(
        restored.activeRulebook.articles.length,
        model.activeRulebook.articles.length,
      );
    });

    test('equipment and aero posture compliance detects violations', () {
      final model = UciCommissaireRulebookAndVarModel.initial(seasonYear: 2025);

      final compliant = model.checkEquipmentAndPostureCompliance(
        bikeWeightKg: 6.85,
        handlebarWidthCm: 38.0,
        brakeLeverInwardDeg: 8.0,
        rimDepthMm: 60.0,
        sockHeightRatio: 0.45,
      );
      expect(compliant.isCompliant, isTrue);
      expect(compliant.violationsPl, isEmpty);
      expect(compliant.totalFineChf, 0);
      expect(compliant.resultsInDisqualification, isFalse);

      final nonCompliant = model.checkEquipmentAndPostureCompliance(
        bikeWeightKg: 6.55,
        handlebarWidthCm: 34.0,
        brakeLeverInwardDeg: 14.0,
        rimDepthMm: 60.0,
        sockHeightRatio: 0.45,
        usesSupertuck: true,
      );
      expect(nonCompliant.isCompliant, isFalse);
      expect(nonCompliant.violationsPl.length, 4);
      expect(nonCompliant.resultsInDisqualification, isTrue);
      expect(nonCompliant.totalFineChf, greaterThanOrEqualTo(3500));
    });

    test('Sprint Deviation VAR detects clean sprint vs irregular relegation vs DSQ', () {
      var model = UciCommissaireRulebookAndVarModel.initial(seasonYear: 2025);

      // 1. Clean sprint
      model = model.evaluateAndRecordSprintVar(
        const SprintVarIncidentInput(
          incidentId: 'inc_clean',
          stageId: 'stage_1',
          riderId: 'rider_1',
          riderName: 'Jasper Clean',
          teamId: 'team_a',
          finishingPosition: 1,
          groupEndPosition: 35,
          trajectorySamples: [
            SprintVarFrameSample(
              timestampSeconds: 0.0,
              distanceToFinishMeters: 200,
              lateralPositionMeters: 4.0,
              speedKmh: 68.0,
              nearestRivalClearanceMeters: 1.5,
            ),
            SprintVarFrameSample(
              timestampSeconds: 2.0,
              distanceToFinishMeters: 160,
              lateralPositionMeters: 4.3,
              speedKmh: 71.0,
              nearestRivalClearanceMeters: 1.2,
            ),
          ],
        ),
      );
      expect(model.varVerdicts.last.status, SprintVarVerdictStatus.cleanSprint);
      expect(model.varVerdicts.last.finalPosition, 1);
      expect(model.varVerdicts.last.cardIssued, UciCardType.none);

      // 2. Irregular sprint (deviation > 0.85m and rival forced to brake)
      model = model.evaluateAndRecordSprintVar(
        const SprintVarIncidentInput(
          incidentId: 'inc_relegated',
          stageId: 'stage_2',
          riderId: 'rider_2',
          riderName: 'Sander Swerve',
          teamId: 'team_b',
          finishingPosition: 1,
          groupEndPosition: 42,
          rivalForcedToBrake: true,
          availableCameras: [SprintVarCameraAngle.rearPelotonCam],
          trajectorySamples: [
            SprintVarFrameSample(
              timestampSeconds: 0.0,
              distanceToFinishMeters: 150,
              lateralPositionMeters: 2.0,
              speedKmh: 69.0,
              nearestRivalClearanceMeters: 1.0,
            ),
            SprintVarFrameSample(
              timestampSeconds: 1.0,
              distanceToFinishMeters: 130,
              lateralPositionMeters: 3.5,
              speedKmh: 70.0,
              nearestRivalClearanceMeters: 0.35,
            ),
          ],
        ),
      );
      final relegatedVerdict = model.varVerdicts.last;
      expect(
        relegatedVerdict.status,
        SprintVarVerdictStatus.yellowCardAndRelegated,
      );
      expect(relegatedVerdict.finalPosition, 42);
      expect(relegatedVerdict.cardIssued, UciCardType.yellow);
      expect(model.riderYellowCardsInRace['rider_2'], 1);
      expect(relegatedVerdict.isAppealable, isTrue);

      // Appeal with strong evidence
      const analyzer = SprintDeviationVarAnalyzer();
      final appealed = analyzer.processAppeal(
        verdict: relegatedVerdict,
        teamEvidenceStrength: 0.95,
      );
      expect(appealed.appealSubmitted, isTrue);
      expect(appealed.appealUpheld, isTrue);
      expect(appealed.status, SprintVarVerdictStatus.cleanSprint);
      expect(appealed.finalPosition, 1);

      // 3. Crash caused -> Disqualified
      model = model.evaluateAndRecordSprintVar(
        const SprintVarIncidentInput(
          incidentId: 'inc_crash',
          stageId: 'stage_3',
          riderId: 'rider_3',
          riderName: 'Crasher',
          teamId: 'team_c',
          finishingPosition: 2,
          groupEndPosition: 50,
          causedCrash: true,
          handOffHandlebarOrElbow: true,
          trajectorySamples: [
            SprintVarFrameSample(
              timestampSeconds: 0.0,
              distanceToFinishMeters: 100,
              lateralPositionMeters: 4.0,
              speedKmh: 68.0,
              nearestRivalClearanceMeters: 0.2,
            ),
            SprintVarFrameSample(
              timestampSeconds: 0.8,
              distanceToFinishMeters: 85,
              lateralPositionMeters: 5.2,
              speedKmh: 66.0,
              nearestRivalClearanceMeters: 0.05,
            ),
          ],
        ),
      );
      expect(
        model.varVerdicts.last.status,
        SprintVarVerdictStatus.disqualified,
      );
      expect(
        model.varVerdicts.last.cardIssued,
        UciCardType.redDisqualification,
      );
      expect(model.riderSuspensionDays['rider_3'], 7);
    });

    test('dynamic rulebook evolution lowers bike weight limit to 6.50 kg in 2027', () {
      var model = UciCommissaireRulebookAndVarModel.initial(seasonYear: 2025);

      // 6.55 kg bike is illegal in 2025
      expect(
        model
            .checkEquipmentAndPostureCompliance(
              bikeWeightKg: 6.55,
              handlebarWidthCm: 38.0,
              brakeLeverInwardDeg: 5.0,
              rimDepthMm: 50.0,
              sockHeightRatio: 0.40,
            )
            .isCompliant,
        isFalse,
      );

      // Advance to 2026 (5 km sprint protection zone)
      model = model.advanceToNextSeason(targetYear: 2026);
      expect(model.activeRulebook.seasonYear, 2026);
      expect(model.activeRulebook.finalKmProtectionDistanceKm, 5.0);

      // Advance to 2027 (6.50 kg bike weight limit)
      model = model.advanceToNextSeason(targetYear: 2027);
      expect(model.activeRulebook.seasonYear, 2027);
      expect(model.activeRulebook.minBikeWeightKg, 6.50);
      expect(model.evolutionHistory.length, greaterThanOrEqualTo(2));

      // Now 6.55 kg bike is compliant!
      expect(
        model
            .checkEquipmentAndPostureCompliance(
              bikeWeightKg: 6.55,
              handlebarWidthCm: 38.0,
              brakeLeverInwardDeg: 5.0,
              rimDepthMm: 50.0,
              sockHeightRatio: 0.40,
            )
            .isCompliant,
        isTrue,
      );
    });

    test('yellow card accumulation triggers 7-day and 14-day suspensions', () {
      var model = UciCommissaireRulebookAndVarModel.initial(seasonYear: 2025);

      model = model.recordYellowCard('r_10');
      expect(model.riderYellowCardsInRace['r_10'], 1);
      expect(model.riderSuspensionDays['r_10'], isNull);

      model = model.recordYellowCard('r_10');
      expect(model.riderYellowCardsInRace['r_10'], 2);
      expect(model.riderSuspensionDays['r_10'], 7);

      model = model.clearRaceYellowCards();
      expect(model.riderYellowCardsInRace, isEmpty);

      model = model.recordYellowCard('r_10');
      expect(model.riderYellowCardsRolling30Days['r_10'], 3);
      expect(model.riderSuspensionDays['r_10'], 14);
    });
  });
}
