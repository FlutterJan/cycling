import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/global_exotic_tours_expansion_model.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';

void main() {
  group('GlobalExoticToursExpansionModel', () {
    test('initial() zawiera wszystkie 4 pozaeuropejskie wyścigi UCI', () {
      final model = GlobalExoticToursExpansionModel.initial(seasonYear: 2027);

      expect(model.seasonYear, 2027);
      expect(model.tours, hasLength(4));
      expect(model.tourById(ExoticTourId.tourDuRwanda)?.countryIso, 'RWA');
      expect(model.tourById(ExoticTourId.tourDeLangkawi)?.countryIso, 'MAS');
      expect(model.tourById(ExoticTourId.tourOfOman)?.countryIso, 'OMA');
      expect(model.tourById(ExoticTourId.alUlaTour)?.countryIso, 'KSA');
    });

    test('filtruje wyścigi po regionie oraz miesiącu kalendarzowym', () {
      final model = GlobalExoticToursExpansionModel.initial();

      final arabianTours = model.toursByRegion(
        ExoticMarketRegion.arabianPeninsula,
      );
      expect(arabianTours, hasLength(2));
      expect(
        arabianTours.map((e) => e.tourId),
        containsAll([ExoticTourId.tourOfOman, ExoticTourId.alUlaTour]),
      );

      final febTours = model.toursForMonth(2);
      expect(febTours, hasLength(2));
      expect(
        febTours.map((e) => e.tourId),
        containsAll([ExoticTourId.tourDuRwanda, ExoticTourId.tourOfOman]),
      );
    });

    test('oblicza gotowość aklimatyzacyjną i karę wydolnościową', () {
      final model = GlobalExoticToursExpansionModel.initial();
      final langkawi = model.tourById(ExoticTourId.tourDeLangkawi)!;

      final unprepared = model.evaluateTourParticipation(
        tourId: ExoticTourId.tourDeLangkawi,
        daysAcclimatized: 0,
        protocol: AcclimatizationProtocolType.none,
        expectedGcFinishRank: 3,
      );
      final prepared = model.evaluateTourParticipation(
        tourId: ExoticTourId.tourDeLangkawi,
        daysAcclimatized: langkawi.logistics.recommendedAcclimatizationDays,
        protocol: langkawi.logistics.recommendedProtocol,
        expectedGcFinishRank: 3,
      );

      expect(unprepared.readinessScore, 0.0);
      expect(unprepared.performancePenaltyPercent, greaterThan(5.0));
      expect(prepared.readinessScore, 1.0);
      expect(prepared.performancePenaltyPercent, 0.0);
      expect(prepared.isFinanciallyViable, isTrue);
      expect(prepared.projectedUciPoints, greaterThan(150));
    });

    test('promoteTourTier podnosi rangę wyścigu aż do WorldTour', () {
      final initial = GlobalExoticToursExpansionModel.initial();
      final alUlaBefore = initial.tourById(ExoticTourId.alUlaTour)!;
      expect(alUlaBefore.expansionTier, ExoticExpansionTier.worldTourCandidate);

      final promoted = initial.promoteTourTier(ExoticTourId.alUlaTour);
      final alUlaAfter = promoted.tourById(ExoticTourId.alUlaTour)!;

      expect(alUlaAfter.expansionTier, ExoticExpansionTier.promotedWorldTour);
      expect(alUlaAfter.uciCode, '2.UWT');
      expect(alUlaAfter.uciCategory, RaceCategory.worldTourStageRace);
      expect(alUlaAfter.prizePoolEur, greaterThan(alUlaBefore.prizePoolEur));
      expect(promoted.promotedTourIds, contains(ExoticTourId.alUlaTour));
      expect(
        promoted.globalExpansionReputation,
        greaterThan(initial.globalExpansionReputation),
      );
    });

    test('recordParticipation aktualizuje historię, reputację i bazę fanów', () {
      final initial = GlobalExoticToursExpansionModel.initial();
      final updated = initial.recordParticipation(
        const TeamExoticTourParticipationRecord(
          tourId: ExoticTourId.tourDuRwanda,
          seasonYear: 2026,
          daysAcclimatized: 5,
          protocol: AcclimatizationProtocolType.altitudeCamp,
          bestGcRank: 1,
          stageWins: 2,
          uciPointsEarned: 125,
          netFinancialBalanceEur: 27250,
          fansGained: 28000,
        ),
      );

      expect(updated.participationHistory, hasLength(1));
      expect(
        updated.nonEuropeanFanBase,
        initial.nonEuropeanFanBase + 28000,
      );
      expect(
        updated.globalExpansionReputation,
        greaterThan(initial.globalExpansionReputation),
      );
    });

    test('konwertuje definicje wyścigów na obiekty TourRace z etapami', () {
      final model = GlobalExoticToursExpansionModel.initial();
      final races = model.buildCalendarTourRaces(
        participatingTeamIds: const ['team_player', 'team_rival'],
      );

      expect(races, hasLength(4));
      for (final race in races) {
        expect(race.stages, isNotEmpty);
        expect(race.participatingTeamIds, ['team_player', 'team_rival']);
        for (final stage in race.stages) {
          expect(stage.totalDistanceKm, greaterThan(0.0));
          expect(stage.segments, hasLength(3));
        }
      }
    });

    test('zachowuje pełną spójność serializacji JSON round-trip', () {
      final initial = GlobalExoticToursExpansionModel.initial(seasonYear: 2028)
          .promoteTourTier(ExoticTourId.tourOfOman)
          .recordParticipation(
            const TeamExoticTourParticipationRecord(
              tourId: ExoticTourId.tourOfOman,
              seasonYear: 2028,
              daysAcclimatized: 4,
              protocol: AcclimatizationProtocolType.heatChamberAndHydration,
              bestGcRank: 2,
              stageWins: 1,
              uciPointsEarned: 150,
              netFinancialBalanceEur: 62600,
              fansGained: 24000,
            ),
          );

      final json = initial.toJson();
      final restored = GlobalExoticToursExpansionModel.fromJson(json);

      expect(restored, initial);
      expect(restored.tours.length, 4);
      expect(
        restored.tourById(ExoticTourId.tourOfOman)?.expansionTier,
        ExoticExpansionTier.worldTourCandidate,
      );
      expect(restored.participationHistory.first.bestGcRank, 2);
    });
  });
}
