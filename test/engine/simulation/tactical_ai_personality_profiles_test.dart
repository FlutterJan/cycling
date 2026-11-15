import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/mountain_gc_ai_controller.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/simulation/tactical_ai_personality_profiles.dart';
import 'package:pro_peloton_manager/models/career/staff_member.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';

Rider _buildTestRider({
  required String id,
  String lastName = 'Kowalski',
  RiderSpecialization specialization = RiderSpecialization.gcClimber,
  int ftpWatts = 410,
  int wPrimeJoules = 23000,
  double weightKg = 64.0,
  int descending = 75,
  int raceIq = 80,
  int birthYear = 1998,
}) {
  return Rider(
    id: id,
    firstName: 'Jan',
    lastName: lastName,
    nationalityIso: 'PL',
    birthDate: DateTime(birthYear, 5, 12),
    potential: 92,
    specialization: specialization,
    physiology: RiderPhysiology(
      heightCm: 176.0,
      weightKg: weightKg,
      bodyFatPercentage: 7.2,
      ftpWatts: ftpWatts,
      wPrimeJoules: wPrimeJoules,
      vo2Max: 84.5,
      maxHr: 196,
      restingHr: 40,
      lactateThresholdHr: 178,
      recoveryRate: 0.92,
      glycogenCapacityGrams: 550.0,
    ),
    powerProfile: RiderPowerProfile(
      watts5s: 1280,
      watts15s: 1050,
      watts30s: 840,
      watts1m: 680,
      watts3m: 540,
      watts5m: 485,
      watts20m: 430,
      watts60m: ftpWatts,
    ),
    skills: RiderSkills(
      cobbles: 72,
      descending: descending,
      bikeHandling: 82,
      aeroPositioning: 80,
      draftingEfficiency: 82,
      raceIq: raceIq,
      rainResistance: 78,
      heatTolerance: 78,
      timeTrialPositioning: 80,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#E0AC69',
      hairStyleIndex: 2,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
      glassesModelId: 'aero_pro',
      glassesLensColorHex: '#D4AF37',
      helmetModelId: 'vent_pro',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.5,
      bodyBuildType: BodyBuildType.climberLean,
    ),
    contract: const RiderContract(
      teamId: 'team_alpha',
      role: RiderRole.teamLeader,
      monthlySalaryEur: 45000,
      signingBonusEur: 0,
      winBonusEur: 15000,
      releaseClauseEur: 1500000,
      contractEndYear: 2028,
      morale: 85.0,
      leaderLoyalty: 90.0,
      requiredRacesIds: [],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 55.0,
      chronicTrainingLoad: 82.0,
    ),
    careerPointsUci: 2400,
  );
}

StageSegment _segment({
  int index = 0,
  double startKm = 100.0,
  double lengthKm = 5.0,
  double startElevationM = 1000.0,
  double endElevationM = 1400.0,
  double technicalDifficulty = 40.0,
  SegmentClassification classification = SegmentClassification.none,
  SegmentSurfaceType surface = SegmentSurfaceType.smoothAsphalt,
}) {
  return StageSegment(
    index: index,
    startKm: startKm,
    lengthKm: lengthKm,
    startElevationM: startElevationM,
    endElevationM: endElevationM,
    surfaceType: surface,
    technicalDifficulty: technicalDifficulty,
    windDirectionDegrees: 90.0,
    roadBearingDegrees: 90.0,
    sprintOrKomClassification: classification,
  );
}

void main() {
  group('TacticalAiPersonalityProfiles', () {
    test('udostępnia dokładnie 6 unikalnych archetypów AI', () {
      expect(TacticalAiPersonalityProfiles.allProfiles, hasLength(6));
      expect(TacticalAiArchetype.values, hasLength(6));
      final archetypes = TacticalAiPersonalityProfiles.allProfiles
          .map((p) => p.archetype)
          .toSet();
      expect(archetypes, hasLength(6));
    });

    test('CannibalAttacker atakuje 50 km przed metą na przedostatniej przełęczy przy słabości rywali', () {
      final rider = _buildTestRider(id: 'pog', lastName: 'Pogacar');
      final state = RiderRaceState.initial(
        riderId: rider.id,
        teamId: 'team_alpha',
        initialWPrimeJoules: 21000,
        initialGlycogenGrams: 320,
      );

      final context = TacticalAiRaceContext(
        rider: rider,
        riderState: state,
        currentSegment: _segment(
          startElevationM: 1100,
          endElevationM: 1550, // +9% podjazd
          lengthKm: 5.0,
        ),
        distanceRemainingKm: 50.0,
        isPenultimateOrEarlierMajorClimb: true,
        rivalsInGroup: const [
          RivalClimbingAssessment(
            riderId: 'rival_1',
            cadenceRpm: 72,
            isGrinding: true,
            rowInGroup: 4,
            isDriftingToBack: true,
            estimatedWPrimeRatio: 0.28,
            weaknessScore: 72.0,
          ),
        ],
        directorPhilosophy: DirectorTacticalPhilosophy.aggressiveAttacking,
      );

      final decision = TacticalAiPersonalityProfiles.cannibalAttacker
          .evaluateDecision(context);

      expect(decision.archetype, TacticalAiArchetype.cannibalAttacker);
      expect(decision.shouldLaunchAttack, isTrue);
      expect(decision.recommendedOrder, TacticalOrder.attack);
      expect(decision.targetPowerFractionOfFtp, greaterThan(1.15));
      expect(decision.radioCommentary, contains('50.0 km'));
    });

    test('DieselCalculator ignoruje szarpane zrywy i jedzie równym tempem na progu FTP', () {
      final rider = _buildTestRider(
        id: 'ving',
        lastName: 'Vingegaard',
        wPrimeJoules: 19000,
      );
      final state = RiderRaceState.initial(
        riderId: rider.id,
        teamId: 'team_alpha',
        initialWPrimeJoules: 18500,
        initialGlycogenGrams: 300,
      );

      final context = TacticalAiRaceContext(
        rider: rider,
        riderState: state,
        currentSegment: _segment(
          startElevationM: 1200,
          endElevationM: 1600,
          lengthKm: 5.0,
        ),
        distanceRemainingKm: 14.0,
        isNearClimbSummit: true,
        rivalAttacking: true,
        rivalsInGroup: const [
          RivalClimbingAssessment(
            riderId: 'overheated_attacker',
            cadenceRpm: 74,
            isGrinding: true,
            rowInGroup: 1,
            isDriftingToBack: false,
            estimatedWPrimeRatio: 0.14,
            weaknessScore: 78.0,
          ),
        ],
      );

      final decision = TacticalAiPersonalityProfiles.dieselCalculator
          .evaluateDecision(context);

      expect(decision.archetype, TacticalAiArchetype.dieselCalculator);
      expect(decision.shouldLaunchAttack, isFalse);
      expect(decision.recommendedOrder, TacticalOrder.holdPosition);
      expect(decision.targetPowerFractionOfFtp, inInclusiveRange(0.95, 1.08));
    });

    test('WheelsuckerOpportunist odmawia zmian w ucieczce i wyskakuje na ostatnich 300 m', () {
      final rider = _buildTestRider(
        id: 'opp',
        lastName: 'Opportunista',
        specialization: RiderSpecialization.versatileSprinter,
      );
      final state = RiderRaceState.initial(
        riderId: rider.id,
        teamId: 'team_alpha',
        initialWPrimeJoules: 20000,
        initialGlycogenGrams: 260,
      );

      final breakawayContext = TacticalAiRaceContext(
        rider: rider,
        riderState: state,
        currentSegment: _segment(startElevationM: 200, endElevationM: 205),
        distanceRemainingKm: 25.0,
        isInBreakaway: true,
      );
      final breakDecision = TacticalAiPersonalityProfiles.wheelsuckerOpportunist
          .evaluateDecision(breakawayContext);

      expect(breakDecision.pullContributionRatio, lessThan(0.1));
      expect(breakDecision.recommendedOrder, TacticalOrder.saveEnergy);
      expect(breakDecision.shouldLaunchFinal300mAmbush, isFalse);

      final final300mContext = TacticalAiRaceContext(
        rider: rider,
        riderState: state,
        currentSegment: _segment(startElevationM: 200, endElevationM: 200),
        distanceRemainingKm: 0.28,
        isInBreakaway: true,
      );
      final sprintDecision = TacticalAiPersonalityProfiles
          .wheelsuckerOpportunist
          .evaluateDecision(final300mContext);

      expect(sprintDecision.shouldLaunchFinal300mAmbush, isTrue);
      expect(sprintDecision.shouldLaunchAttack, isTrue);
      expect(sprintDecision.targetPowerFractionOfFtp, greaterThanOrEqualTo(1.45));
    });

    test('KamikazeDescender atakuje na szczycie i maksymalizuje ryzyko na krętym zjeździe', () {
      final rider = _buildTestRider(
        id: 'kamikaze',
        lastName: 'Mohoric',
        descending: 95,
      );
      final state = RiderRaceState.initial(
        riderId: rider.id,
        teamId: 'team_alpha',
        initialWPrimeJoules: 20000,
        initialGlycogenGrams: 300,
      );

      final crestContext = TacticalAiRaceContext(
        rider: rider,
        riderState: state,
        currentSegment: _segment(startElevationM: 1800, endElevationM: 2050),
        upcomingSegments: [
          _segment(
            index: 1,
            startElevationM: 2050,
            endElevationM: 1650, // -8% zjazd
            technicalDifficulty: 78.0,
          ),
        ],
        distanceRemainingKm: 22.0,
        isNearClimbSummit: true,
      );
      final crestDecision = TacticalAiPersonalityProfiles.kamikazeDescender
          .evaluateDecision(crestContext);

      expect(crestDecision.shouldLaunchAttack, isTrue);
      expect(crestDecision.descentRiskMultiplier, greaterThan(1.15));

      final descentContext = TacticalAiRaceContext(
        rider: rider,
        riderState: state,
        currentSegment: _segment(
          startElevationM: 2050,
          endElevationM: 1650,
          technicalDifficulty: 80.0,
        ),
        distanceRemainingKm: 17.0,
      );
      final descentDecision = TacticalAiPersonalityProfiles.kamikazeDescender
          .evaluateDecision(descentContext);

      expect(descentDecision.shouldLaunchAttack, isTrue);
      expect(descentDecision.descentRiskMultiplier, closeTo(1.25, 0.01));
    });

    test('BreakawayHunter skacze do odjazdu i walczy o każdą premię górską KOM', () {
      final rider = _buildTestRider(
        id: 'kom',
        lastName: 'Virenque',
        specialization: RiderSpecialization.breakawaySpecialist,
      );
      final state = RiderRaceState.initial(
        riderId: rider.id,
        teamId: 'team_alpha',
        initialWPrimeJoules: 19000,
        initialGlycogenGrams: 310,
      );

      final komContext = TacticalAiRaceContext(
        rider: rider,
        riderState: state,
        currentSegment: _segment(
          startElevationM: 1400,
          endElevationM: 1800,
          classification: SegmentClassification.cat1,
        ),
        distanceRemainingKm: 65.0,
        isInBreakaway: true,
      );
      final komDecision = TacticalAiPersonalityProfiles.breakawayHunter
          .evaluateDecision(komContext);

      expect(komDecision.shouldContestKomSprint, isTrue);
      expect(komDecision.shouldLaunchAttack, isTrue);
      expect(komDecision.radioCommentary, contains('grochy'));

      final formingContext = TacticalAiRaceContext(
        rider: rider,
        riderState: state,
        currentSegment: _segment(startElevationM: 300, endElevationM: 310),
        distanceRemainingKm: 130.0,
        isInBreakaway: false,
        isBreakawayForming: true,
      );
      final jumpDecision = TacticalAiPersonalityProfiles.breakawayHunter
          .evaluateDecision(formingContext);

      expect(jumpDecision.shouldLaunchAttack, isTrue);
      expect(jumpDecision.recommendedOrder, TacticalOrder.attack);
    });

    test('LoyalRoadCaptain natychmiast oddaje koło liderowi po defekcie i ustawia zespół przed zakrętami', () {
      final rider = _buildTestRider(
        id: 'captain',
        lastName: 'Rowe',
        specialization: RiderSpecialization.domestiqueEngine,
        raceIq: 90,
        birthYear: 1991,
      );
      final state = RiderRaceState.initial(
        riderId: rider.id,
        teamId: 'team_alpha',
        initialWPrimeJoules: 18000,
        initialGlycogenGrams: 290,
      );

      final mechanicalContext = TacticalAiRaceContext(
        rider: rider,
        riderState: state,
        currentSegment: _segment(startElevationM: 250, endElevationM: 255),
        distanceRemainingKm: 35.0,
        isLeaderInSameGroup: true,
        leaderHasMechanical: true,
        leaderId: 'leader_1',
      );
      final swapDecision = TacticalAiPersonalityProfiles.loyalRoadCaptain
          .evaluateDecision(mechanicalContext);

      expect(swapDecision.shouldSwapWheelWithLeader, isTrue);
      expect(swapDecision.recommendedOrder, TacticalOrder.protectLeader);
      expect(swapDecision.radioCommentary, contains('koło'));

      final cornerContext = TacticalAiRaceContext(
        rider: rider,
        riderState: state,
        currentSegment: _segment(
          startElevationM: 250,
          endElevationM: 250,
          technicalDifficulty: 75.0,
        ),
        distanceRemainingKm: 12.0,
        isLeaderInSameGroup: true,
        leaderHasMechanical: false,
      );
      final cornerDecision = TacticalAiPersonalityProfiles.loyalRoadCaptain
          .evaluateDecision(cornerContext);

      expect(cornerDecision.shouldOrganizeCornerLeadout, isTrue);
      expect(cornerDecision.recommendedOrder, TacticalOrder.protectLeader);
    });

    test('assignPelotonPersonalities i serializacja JSON działają poprawnie', () {
      final riders = [
        _buildTestRider(
          id: 'r1',
          specialization: RiderSpecialization.breakawaySpecialist,
        ),
        _buildTestRider(
          id: 'r2',
          specialization: RiderSpecialization.timeTrialist,
        ),
        _buildTestRider(
          id: 'r3',
          specialization: RiderSpecialization.pureSprinter,
        ),
        _buildTestRider(
          id: 'r4',
          specialization: RiderSpecialization.domestiqueEngine,
          raceIq: 85,
          birthYear: 1992,
        ),
      ];

      final map = TacticalAiPersonalityProfiles.assignPelotonPersonalities(
        riders,
        teamPhilosophies: {
          'team_alpha': DirectorTacticalPhilosophy.aggressiveAttacking,
        },
      );

      expect(map['r1'], TacticalAiArchetype.breakawayHunter);
      expect(map['r2'], TacticalAiArchetype.dieselCalculator);
      expect(map['r3'], TacticalAiArchetype.wheelsuckerOpportunist);
      expect(map['r4'], TacticalAiArchetype.loyalRoadCaptain);

      final traitsJson =
          TacticalAiPersonalityProfiles.cannibalAttacker.traits.toJson();
      final decodedTraits = AiPersonalityTraits.fromJson(traitsJson);
      expect(decodedTraits.attackDistanceToFinishKm, 50.0);
    });
  });
}
