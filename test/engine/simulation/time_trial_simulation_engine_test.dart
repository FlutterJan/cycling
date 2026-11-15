import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/constants/physics_constants.dart';
import 'package:pro_peloton_manager/engine/simulation/time_trial_simulation_engine.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/generators/stage_profile_builder.dart';
import 'package:pro_peloton_manager/services/generators/world_teams_generator.dart';

void main() {
  group('TimeTrialSimulationEngine Tests', () {
    late Rider timeTrialChampion;
    late Rider balancedRider;
    late Rider amateurRider;
    late CyclingTeam testTeamA;
    late RaceStage testIttStage;
    late RaceStage testTttStage;

    setUp(() {
      final world = WorldTeamsGenerator.generateWorldTourSystem(seed: 42);
      testTeamA = world.teams.first;

      final ttCandidate = world.allRiders.firstWhere(
        (r) => r.specialization == RiderSpecialization.timeTrialist,
        orElse: () => world.allRiders.first,
      );

      timeTrialChampion = ttCandidate.copyWith(
        id: 'rider_champion_tt',
        firstName: 'Filippo',
        lastName: 'Aero',
        physiology: const RiderPhysiology(
          heightCm: 193.0,
          weightKg: 82.0,
          bodyFatPercentage: 6.8,
          ftpWatts: 470,
          wPrimeJoules: 28000,
          vo2Max: 84.0,
          maxHr: 195,
          restingHr: 38,
          lactateThresholdHr: 176,
          recoveryRate: 1.25,
          glycogenCapacityGrams: 520.0,
        ),
      );

      balancedRider = ttCandidate.copyWith(
        id: 'rider_balanced',
        firstName: 'Stefan',
        lastName: 'Rouleur',
        physiology: const RiderPhysiology(
          heightCm: 184.0,
          weightKg: 74.0,
          bodyFatPercentage: 7.2,
          ftpWatts: 410,
          wPrimeJoules: 22000,
          vo2Max: 79.0,
          maxHr: 190,
          restingHr: 42,
          lactateThresholdHr: 172,
          recoveryRate: 1.10,
          glycogenCapacityGrams: 470.0,
        ),
      );

      amateurRider = ttCandidate.copyWith(
        id: 'rider_light_climber',
        firstName: 'Nairo',
        lastName: 'Scalatore',
        specialization: RiderSpecialization.pureClimber,
        physiology: const RiderPhysiology(
          heightCm: 167.0,
          weightKg: 58.0,
          bodyFatPercentage: 6.0,
          ftpWatts: 330,
          wPrimeJoules: 16000,
          vo2Max: 82.0,
          maxHr: 202,
          restingHr: 40,
          lactateThresholdHr: 180,
          recoveryRate: 1.15,
          glycogenCapacityGrams: 390.0,
        ),
      );

      // Etap 1: Płaska jazda indywidualna na czas (ITT) 24.0 km
      testIttStage = StageProfileBuilder.buildTimeTrialStage(
        id: 'stage_itt_24km',
        stageNumber: 7,
        name: 'Tour de France - Etap 7 ITT (Gevrey-Chambertin)',
        distanceKm: 24.0,
      );

      // Etap 2: Jazda drużynowa na czas (TTT) 27.5 km
      testTttStage = const RaceStage(
        id: 'stage_ttt_27km',
        stageNumber: 3,
        name: 'Vuelta a España - Etap 3 TTT',
        stageType: StageType.teamTimeTrial,
        segments: [
          StageSegment(
            index: 0,
            startKm: 0.0,
            lengthKm: 10.0,
            startElevationM: 40.0,
            endElevationM: 60.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 25.0,
            windDirectionDegrees: 180.0,
            roadBearingDegrees: 180.0,
            sprintOrKomClassification: SegmentClassification.none,
          ),
          StageSegment(
            index: 1,
            startKm: 10.0,
            lengthKm: 10.0,
            startElevationM: 60.0,
            endElevationM: 85.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 30.0,
            windDirectionDegrees: 200.0,
            roadBearingDegrees: 190.0,
            sprintOrKomClassification: SegmentClassification.none,
          ),
          StageSegment(
            index: 2,
            startKm: 20.0,
            lengthKm: 7.5,
            startElevationM: 85.0,
            endElevationM: 50.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 20.0,
            windDirectionDegrees: 180.0,
            roadBearingDegrees: 180.0,
            sprintOrKomClassification: SegmentClassification.finishLine,
          ),
        ],
        baseTemperatureCelsius: 22.0,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 12.0,
      );
    });

    test('1. Wyodrębnia lub generuje prawidłowe punkty pomiaru czasu (checkpoints)', () {
      final checkpoints = TimeTrialSimulationEngine.extractOrGenerateCheckpoints(testIttStage);

      // Dla etapu 24.0 km powinny powstać punkty pośrednie i linia mety
      expect(checkpoints.isNotEmpty, isTrue);
      expect(checkpoints.last.isFinish, isTrue);
      expect(checkpoints.last.distanceKm, equals(testIttStage.totalDistanceKm));

      // Sprawdź rosnący dystans punktów pomiarowych
      for (int i = 0; i < checkpoints.length - 1; i++) {
        expect(checkpoints[i].distanceKm, lessThan(checkpoints[i + 1].distanceKm));
        expect(checkpoints[i].name.isNotEmpty, isTrue);
      }
    });

    test('2. Weryfikuje brak draftingu (drafting = 0.0) w jeździe indywidualnej na czas (ITT)', () {
      final cdaItt = TimeTrialSimulationEngine.calculateRiderEffectiveCdA(
        timeTrialChampion,
        draftingReduction: 0.0,
      );

      final cdaWithDraftAttempt = TimeTrialSimulationEngine.calculateRiderEffectiveCdA(
        timeTrialChampion,
        draftingReduction: 0.40,
      );

      // Lemondka daje bardzo niski opór bazowy (poniżej standardowej szosy hoods 0.32)
      expect(cdaItt, lessThan(PhysicsConstants.cdaHoods));
      expect(cdaItt, greaterThan(0.16));

      // Z draftem opór jest jeszcze niższy (używany wyłącznie w TTT)
      expect(cdaWithDraftAttempt, lessThan(cdaItt));
    });

    test('3. Pacing Strategy w ITT: Strategia zrównoważona vs Pełen ogień (All-Out Blow-Up)', () {
      final riderBalanced = balancedRider.copyWith(id: 'rider_pacing_balanced');
      final riderAllOut = balancedRider.copyWith(id: 'rider_pacing_allout');

      final teamsMap = {testTeamA.id: testTeamA};

      final result = TimeTrialSimulationEngine.simulateIttStage(
        stage: testIttStage,
        riders: [riderBalanced, riderAllOut],
        teamsMap: teamsMap,
        customPacing: {
          riderBalanced.id: PacingStrategy.balanced,
          riderAllOut.id: PacingStrategy.allOut,
        },
        startIntervalSeconds: 60.0,
      );

      expect(result.riderResults.length, equals(2));

      final balancedRes = result.riderResults.firstWhere((r) => r.riderId == riderBalanced.id);
      final allOutRes = result.riderResults.firstWhere((r) => r.riderId == riderAllOut.id);

      // Kolarz jadący All-Out powinien doznać odcięcia beztlenowego (bomba)
      expect(allOutRes.isBlownUp, isTrue);
      expect(allOutRes.blowUpKm, isNotNull);
      expect(allOutRes.remainingWPrimePercentage, lessThan(15.0));

      // Kolarz zrównoważony powinien zachować bezpieczny poziom W' i nie zaliczyć bomby
      expect(balancedRes.isBlownUp, isFalse);

      // Kolarz, który spalił się na początku (All-Out), osiąga gorszy czas końcowy niż równomierny!
      expect(balancedRes.finishTimeSeconds, lessThan(allOutRes.finishTimeSeconds));
      expect(balancedRes.rank, equals(1));
      expect(allOutRes.rank, equals(2));

      // Weryfikacja zarejestrowanych punktów pomiaru czasu
      expect(balancedRes.splits.isNotEmpty, isTrue);
      expect(balancedRes.splits.last.distanceKm, equals(testIttStage.totalDistanceKm));
      expect(balancedRes.splits.first.splitRank, inInclusiveRange(1, 2));
    });

    test('4. Pacing Strategy w ITT: Negatywny split (Negative Split) osiąga znakomity czas finałowy', () {
      final riderNegativeSplit = timeTrialChampion.copyWith(id: 'rider_neg_split');
      final riderConservative = timeTrialChampion.copyWith(id: 'rider_conservative');

      final result = TimeTrialSimulationEngine.simulateIttStage(
        stage: testIttStage,
        riders: [riderNegativeSplit, riderConservative],
        teamsMap: {testTeamA.id: testTeamA},
        customPacing: {
          riderNegativeSplit.id: PacingStrategy.negativeSplit,
          riderConservative.id: PacingStrategy.conservative,
        },
      );

      final negSplitRes = result.riderResults.firstWhere((r) => r.riderId == riderNegativeSplit.id);
      final consRes = result.riderResults.firstWhere((r) => r.riderId == riderConservative.id);

      // Żaden z nich nie doznał bomby
      expect(negSplitRes.isBlownUp, isFalse);
      expect(consRes.isBlownUp, isFalse);

      // Negatywny split (95% -> 108% FTP) jest szybszy od oszczędnego 92% FTP
      expect(negSplitRes.finishTimeSeconds, lessThan(consRes.finishTimeSeconds));
      expect(negSplitRes.averageSpeedKmh, greaterThan(consRes.averageSpeedKmh));
    });

    test('5. TTT: Jazda drużynowa w pociągu na lemondkach, rotacja zmian (15-30s) i zasada 4. kolarza', () {
      final r1 = timeTrialChampion.copyWith(id: 't_r1', firstName: 'Lider');
      final r2 = timeTrialChampion.copyWith(id: 't_r2', firstName: 'Aero Motor');
      final r3 = balancedRider.copyWith(id: 't_r3', firstName: 'Rouleur 1');
      final r4 = balancedRider.copyWith(id: 't_r4', firstName: 'Rouleur 2');
      final r5 = balancedRider.copyWith(id: 't_r5', firstName: 'Pomocnik');
      final r6 = amateurRider.copyWith(id: 't_r6', firstName: 'Lekki Góral');

      final teamRosters = {
        testTeamA.id: [r1, r2, r3, r4, r5, r6],
      };

      final result = TimeTrialSimulationEngine.simulateTttStage(
        stage: testTttStage,
        teams: [testTeamA],
        teamRosters: teamRosters,
        teamTurnDurations: {testTeamA.id: TttTurnDuration.standard20s},
      );

      expect(result.teamResults.length, equals(1));
      final teamRes = result.teamResults.first;

      // Sprawdź czy oficjalny czas drużyny jest zdefiniowany
      expect(teamRes.officialTimeSeconds, greaterThan(0.0));
      expect(teamRes.averageSpeedKmh, greaterThan(40.0));
      expect(teamRes.rank, equals(1));

      // Weryfikacja oficjalnej zasady UCI liczenia czasu wg 4. kolarza na mecie:
      final indTimes = teamRes.individualFinishTimesSeconds;
      expect(indTimes.length, equals(6));

      // Czas kolarza 1, 2, 3 oraz 4 musi być dokładnie równy oficjalnemu czasowi drużyny!
      expect(indTimes[r1.id], equals(teamRes.officialTimeSeconds));
      expect(indTimes[r2.id], equals(teamRes.officialTimeSeconds));
      expect(indTimes[r3.id], equals(teamRes.officialTimeSeconds));
      expect(indTimes[r4.id], equals(teamRes.officialTimeSeconds));

      // Sprawdź czy kolarze finiszujący po 4. zawodniku otrzymują swój czas
      if (teamRes.activeFinishersCount >= 5) {
        expect(indTimes[r5.id], greaterThanOrEqualTo(teamRes.officialTimeSeconds));
      }

      // Sprawdź punkty pomiaru czasu dla TTT
      expect(teamRes.splits.isNotEmpty, isTrue);
      expect(teamRes.splits.last.distanceKm, equals(testTttStage.totalDistanceKm));
    });

    test('6. TTT: Odpadający kolarz otrzymuje gorszy czas indywidualny bez psucia czasu 4. kolarza', () {
      final weakDomestique = amateurRider.copyWith(
        id: 't_weak_domestique',
        firstName: 'Zmęczony',
        lastName: 'Domestique',
        physiology: amateurRider.physiology.copyWith(
          ftpWatts: 240,
          wPrimeJoules: 8000,
        ),
      );

      final squad = [
        timeTrialChampion.copyWith(id: 'tt_1'),
        timeTrialChampion.copyWith(id: 'tt_2'),
        balancedRider.copyWith(id: 'tt_3'),
        balancedRider.copyWith(id: 'tt_4'),
        weakDomestique,
      ];

      final result = TimeTrialSimulationEngine.simulateTttStage(
        stage: testTttStage,
        teams: [testTeamA],
        teamRosters: {testTeamA.id: squad},
        teamTurnDurations: {testTeamA.id: TttTurnDuration.long30s},
      );

      final teamRes = result.teamResults.first;
      final indTimes = teamRes.individualFinishTimesSeconds;

      // Słaby kolarz powinien mieć zarejestrowaną stratę
      if (teamRes.droppedCount > 0) {
        expect(teamRes.droppedRiderNames.isNotEmpty, isTrue);
        expect(indTimes[weakDomestique.id], greaterThan(teamRes.officialTimeSeconds));
      }

      // Jednak czas pierwszych 4 kolarzy nadal decyduje o oficjalnym wyniku drużyny!
      expect(indTimes['tt_1'], equals(teamRes.officialTimeSeconds));
      expect(indTimes['tt_4'], equals(teamRes.officialTimeSeconds));
    });

    test('7. Interaktywna sesja krokowa (IttSimulationSession) i zmiana taktyki w locie', () {
      final session = TimeTrialSimulationEngine.createIttSession(
        stage: testIttStage,
        riders: [timeTrialChampion, balancedRider],
        teamsMap: {testTeamA.id: testTeamA},
        startIntervalSeconds: 60.0,
      );

      expect(session.riderStates.length, equals(2));
      expect(session.isCompleted, isFalse);

      // Krok 1: Przesunięcie czasu o 10 sekund
      TimeTrialSimulationEngine.tickIttSession(session, 10.0);

      expect(session.globalElapsedSeconds, equals(10.0));
      // Pierwszy kolarz wystartował
      expect(session.riderStates[0].hasStarted, isTrue);
      expect(session.riderStates[0].distanceTraveledMeters, greaterThan(0.0));
      // Drugi kolarz ma start po 60 sekundach, więc jeszcze czeka na rampie
      expect(session.riderStates[1].hasStarted, isFalse);

      // Zmiana taktyki kolarza w locie przez gracza
      TimeTrialSimulationEngine.updateRiderPacing(
        session.riderStates[0],
        PacingStrategy.aggressive,
      );
      expect(session.riderStates[0].pacingStrategy, equals(PacingStrategy.aggressive));

      // Przepchnięcie symulacji do 120 sekund
      for (int i = 0; i < 11; i++) {
        TimeTrialSimulationEngine.tickIttSession(session, 10.0);
      }

      // Teraz obaj kolarze jadą na trasie
      expect(session.riderStates[0].hasStarted, isTrue);
      expect(session.riderStates[1].hasStarted, isTrue);
      expect(session.riderStates[1].distanceTraveledMeters, greaterThan(0.0));
    });
  });
}
