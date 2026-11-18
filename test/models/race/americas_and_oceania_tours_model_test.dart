import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/americas_and_oceania_tours_model.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';

void main() {
  group('AmericasAndOceaniaToursModel', () {
    test('standard factory contains all 6 authentic opener and closer races', () {
      final model = AmericasAndOceaniaToursModel.standard(seasonYear: 2026);
      expect(model.races.length, 6);
      expect(model.seasonOpeners.length, 4);
      expect(model.seasonClosers.length, 2);

      final tdu = model.findById(AmericasOceaniaRaceId.santosTourDownUnder)!;
      expect(tdu.logistics.minTemperatureCelsius, 38.0);
      expect(tdu.logistics.maxTemperatureCelsius, 43.0);
      expect(
        tdu.stageTemplates.any(
          (s) =>
              s.name.contains('Willunga Hill') &&
              s.weatherCondition == WeatherCondition.extremeHeat,
        ),
        isTrue,
      );

      final cadel = model.findById(
        AmericasOceaniaRaceId.cadelEvansGreatOceanRoadRace,
      )!;
      expect(
        cadel.climateHazard,
        AmericasOceaniaClimateHazard.southernOceanCoastalCrosswind,
      );
      expect(
        cadel.stageTemplates.first.weatherCondition,
        WeatherCondition.crosswindGale,
      );

      final sanJuan = model.findById(AmericasOceaniaRaceId.vueltaASanJuan)!;
      final altoStage = sanJuan.stageTemplates.last;
      expect(altoStage.startElevationM, 2500.0);
      expect(altoStage.endElevationM, 3265.0);
      expect(sanJuan.peakAltitudeMeters, 3265.0);

      final colombia = model.findById(AmericasOceaniaRaceId.tourColombia21)!;
      expect(colombia.uciCode, '2.1');
      expect(colombia.region, AmericasOceaniaRegion.southAmerica);

      final quebec = model.findById(AmericasOceaniaRaceId.gpCyclisteDeQuebec)!;
      final montreal = model.findById(
        AmericasOceaniaRaceId.gpCyclisteDeMontreal,
      )!;
      expect(quebec.seasonWindow, SeasonWindowPhase.seasonCloser);
      expect(montreal.seasonWindow, SeasonWindowPhase.seasonCloser);
      expect(quebec.startMonth, 9);
      expect(montreal.startMonth, 9);
    });

    test('builds TourRace calendar objects and evaluates readiness', () {
      final model = AmericasAndOceaniaToursModel.standard(seasonYear: 2026);
      final tourRaces = model.buildCalendarTourRaces(
        participatingTeamIds: const ['team_1', 'team_2'],
      );
      expect(tourRaces.length, 6);
      expect(model.buildSeasonOpenerRaces().length, 4);
      expect(model.buildSeasonCloserRaces().length, 2);

      final sanJuanEval = model.evaluateRaceEntry(
        raceId: AmericasOceaniaRaceId.vueltaASanJuan,
        daysOnSite: 8,
        method: AmericasOceaniaAcclimatizationMethod.hypobaricAltitudeCamp,
        availableBudgetEur: 100000,
      );
      expect(sanJuanEval.readinessScore, 1.0);
      expect(sanJuanEval.hypoxiaPowerDropPercent, greaterThan(10.0));
      expect(sanJuanEval.isRecommendedForSquad, isTrue);

      final updated = model.recordParticipation(
        const AmericasOceaniaParticipationRecord(
          raceId: AmericasOceaniaRaceId.santosTourDownUnder,
          seasonYear: 2026,
          daysAcclimatized: 7,
          acclimatizationMethod:
              AmericasOceaniaAcclimatizationMethod.heatChamberAndIceCooling,
          bestRank: 1,
          stageWins: 2,
          uciPointsEarned: 500,
          netTravelBalanceEur: 12000,
        ),
      );
      expect(updated.participationHistory.length, 1);
      expect(
        updated.americasOceaniaPrestigeScore,
        greaterThan(model.americasOceaniaPrestigeScore),
      );
    });

    test('JSON round-trip preserves full model state', () {
      final original = AmericasAndOceaniaToursModel.standard(seasonYear: 2027)
          .recordParticipation(
        const AmericasOceaniaParticipationRecord(
          raceId: AmericasOceaniaRaceId.gpCyclisteDeMontreal,
          seasonYear: 2027,
          daysAcclimatized: 4,
          acclimatizationMethod:
              AmericasOceaniaAcclimatizationMethod.puncheurVo2MaxSharpening,
          bestRank: 2,
          stageWins: 0,
          uciPointsEarned: 400,
          netTravelBalanceEur: 8500,
        ),
      );

      final json = original.toJson();
      final decoded = AmericasAndOceaniaToursModel.fromJson(json);

      expect(decoded, original);
      expect(decoded.races.length, original.races.length);
      expect(decoded.participationHistory.first.bestRank, 2);
    });
  });
}
