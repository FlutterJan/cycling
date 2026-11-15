// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/staff_member.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/services/career/rider_ego_and_conflicts_service.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';

void main() {
  late Rider leaderAlpha;
  late Rider leaderChallenger;
  late Rider loyalDomestique;
  late Rider primaSprinter;
  late SportsDirector eliteDs;
  late SportsDirector weakDs;
  late TourRace tourDeFrance;

  setUp(() {
    // 1. Doświadczony samiec alfa (Leader #1)
    leaderAlpha = RiderProceduralGenerator.generateRider(
      id: 'leader_alpha_01',
      specialization: RiderSpecialization.gcClimber,
      targetOverallRating: 89,
    ).copyWith(
      age: 29,
      contract: const RiderContract(
        teamId: 'team_01',
        role: RiderRole.teamLeader,
        monthlySalaryEur: 180000,
        signingBonusEur: 50000,
        winBonusEur: 100000,
        releaseClauseEur: 5000000,
        contractEndYear: 2028,
        morale: 85.0,
        leaderLoyalty: 60.0,
        requiredRacesIds: ['tdf_2026'],
      ),
    );

    // 2. Młody ambitny wilczek (Leader #2 / Co-Leader)
    leaderChallenger = RiderProceduralGenerator.generateRider(
      id: 'leader_challenger_02',
      specialization: RiderSpecialization.gcClimber,
      targetOverallRating: 87,
    ).copyWith(
      age: 23,
      contract: const RiderContract(
        teamId: 'team_01',
        role: RiderRole.teamLeader,
        monthlySalaryEur: 120000,
        signingBonusEur: 30000,
        winBonusEur: 80000,
        releaseClauseEur: 4000000,
        contractEndYear: 2029,
        morale: 88.0,
        leaderLoyalty: 55.0,
        requiredRacesIds: ['tdf_2026'],
      ),
    );

    // 3. Lojalny pomocnik górski (Super-domestique)
    loyalDomestique = RiderProceduralGenerator.generateRider(
      id: 'domestique_kuss',
      specialization: RiderSpecialization.domestiqueEngine,
      targetOverallRating: 81,
    ).copyWith(
      age: 28,
      contract: const RiderContract(
        teamId: 'team_01',
        role: RiderRole.superDomestique,
        monthlySalaryEur: 45000,
        signingBonusEur: 15000,
        winBonusEur: 20000,
        releaseClauseEur: 1000000,
        contractEndYear: 2027,
        morale: 90.0,
        leaderLoyalty: 95.0,
        requiredRacesIds: [],
      ),
    );

    // 4. Sprinter
    primaSprinter = RiderProceduralGenerator.generateRider(
      id: 'sprinter_cav',
      specialization: RiderSpecialization.pureSprinter,
      targetOverallRating: 85,
    ).copyWith(
      contract: const RiderContract(
        teamId: 'team_01',
        role: RiderRole.sprinter,
        monthlySalaryEur: 80000,
        signingBonusEur: 25000,
        winBonusEur: 40000,
        releaseClauseEur: 2000000,
        contractEndYear: 2027,
        morale: 80.0,
        leaderLoyalty: 50.0,
        requiredRacesIds: [],
      ),
    );

    eliteDs = const SportsDirector(
      id: 'ds_elite',
      firstName: 'Patrick',
      lastName: 'Lefevere',
      nationalityIso: 'BEL',
      age: 58,
      experienceLevel: 94,
      monthlySalaryEur: 18000,
      contractEndYear: 2028,
      reputation: 92,
      convoyCarDrivingSkill: 90,
      tacticalAiInsight: 92,
      preRaceBriefingCharisma: 94, // Potężna charyzma
      radioCommunicationClarity: 90,
    );

    weakDs = const SportsDirector(
      id: 'ds_weak',
      firstName: 'Jean',
      lastName: 'Debiutant',
      nationalityIso: 'FRA',
      age: 33,
      experienceLevel: 40,
      monthlySalaryEur: 3500,
      contractEndYear: 2027,
      reputation: 40,
      convoyCarDrivingSkill: 50,
      tacticalAiInsight: 45,
      preRaceBriefingCharisma: 35, // Bardzo niska charyzma
      radioCommunicationClarity: 40,
    );

    tourDeFrance = const TourRace(
      id: 'tdf_2026',
      name: 'Tour de France 2026',
      countryIso: 'FR',
      uciCategory: RaceCategory.grandTour,
      startMonth: 7,
      startDay: 4,
      stages: [],
      prizePoolEur: 2500000,
      participatingTeamIds: ['team_01'],
      ridersPerTeam: 8,
      classifications: RaceClassifications(
        generalClassification: [],
        pointsClassification: [],
        mountainsClassification: [],
        youthClassification: [],
        teamClassification: [],
      ),
    );
  });

  group('RiderEgoAndConflictsService - 1. Generowanie Profili Psychologicznych', () {
    test('generatePersonalityProfile precyzyjnie przypisuje archetypy i cechy ego', () {
      final profileAlpha = RiderEgoAndConflictsService.generatePersonalityProfile(leaderAlpha);
      expect(profileAlpha.archetype, equals(PersonalityArchetype.alphaLeader));
      expect(profileAlpha.egoLevel, greaterThanOrEqualTo(85));
      expect(profileAlpha.ambition, greaterThanOrEqualTo(90));

      final profileChallenger = RiderEgoAndConflictsService.generatePersonalityProfile(leaderChallenger);
      expect(profileChallenger.archetype, equals(PersonalityArchetype.youngAmbitiousChallenger));
      expect(profileChallenger.tacticalPatience, lessThanOrEqualTo(45));

      final profileDomestique = RiderEgoAndConflictsService.generatePersonalityProfile(loyalDomestique);
      expect(profileDomestique.archetype, equals(PersonalityArchetype.loyalLieutenant));
      expect(profileDomestique.teamLoyalty, greaterThanOrEqualTo(90));
      expect(profileDomestique.mediaDramaProneness, lessThan(30));

      final profileSprinter = RiderEgoAndConflictsService.generatePersonalityProfile(primaSprinter);
      expect(profileSprinter.archetype, equals(PersonalityArchetype.primaDonnaSprinter));
      expect(profileSprinter.mediaDramaProneness, greaterThanOrEqualTo(70));
    });
  });

  group('RiderEgoAndConflictsService - 2. Weryfikacja Składu na Grand Tour & Złamane Obietnice', () {
    test('validateGrandTourSquadEgoClash wykrywa starcie dwóch liderów na tym samym Grand Tourze', () {
      final squadWithTwoLeaders = [leaderAlpha, leaderChallenger, loyalDomestique];

      final report = RiderEgoAndConflictsService.validateGrandTourSquadEgoClash(
        race: tourDeFrance,
        squadRiders: squadWithTwoLeaders,
        activePromises: [],
      );

      expect(report.hasDualLeaderClash, isTrue);
      expect(report.conflictingLeaders.length, equals(2));
      expect(report.estimatedClashRiskPercent, greaterThanOrEqualTo(50));
      expect(report.diagnosisSummary, contains('ALARM EGO'));
    });

    test('validateGrandTourSquadEgoClash alarmuje o złamaniu obietnicy soleLeaderGrandTour', () {
      final squadWithTwoLeaders = [leaderAlpha, leaderChallenger, loyalDomestique];

      // Kolarzowi Alpha obiecano, że będzie jedynym liderem na Tour de France
      final promise = RiderContractPromise(
        id: 'prom_alpha_sole',
        riderId: leaderAlpha.id,
        type: ContractPromiseType.soleLeaderGrandTour,
        targetRaceId: tourDeFrance.id,
        targetRaceName: tourDeFrance.name,
        promisedDate: DateTime(2026, 1, 15),
      );

      final report = RiderEgoAndConflictsService.validateGrandTourSquadEgoClash(
        race: tourDeFrance,
        squadRiders: squadWithTwoLeaders,
        activePromises: [promise],
      );

      expect(report.hasDualLeaderClash, isTrue);
      expect(report.brokenPromises.length, equals(1));
      expect(report.tacticalWarnings.first, contains('ZŁAMANA OBIETNICA KONTRAKTOWA'));
      expect(report.estimatedClashRiskPercent, greaterThanOrEqualTo(80));
    });

    test('Skład z jednym liderem jest bezpieczny i zbalansowany', () {
      final balancedSquad = [leaderAlpha, loyalDomestique];

      final report = RiderEgoAndConflictsService.validateGrandTourSquadEgoClash(
        race: tourDeFrance,
        squadRiders: balancedSquad,
        activePromises: [],
      );

      expect(report.hasDualLeaderClash, isFalse);
      expect(report.brokenPromises.isEmpty, isTrue);
      expect(report.estimatedClashRiskPercent, equals(0));
      expect(report.diagnosisSummary, contains('zbalansowany'));
    });
  });

  group('RiderEgoAndConflictsService - 3. Odprawa Przedstartowa & Deklaracja Hierarchii', () {
    test('declareRaceHierarchy: silny sztab narzuca hierarchię, słaby sztab wywołuje sprzeciw', () {
      final profiles = {
        leaderAlpha.id: RiderEgoAndConflictsService.generatePersonalityProfile(leaderAlpha),
        leaderChallenger.id: RiderEgoAndConflictsService.generatePersonalityProfile(leaderChallenger),
      };

      // 1. Z elitarnym Dyrektorem Sportowym i wysoką reputacją menedżera (90)
      final declWithAuthority = RiderEgoAndConflictsService.declareRaceHierarchy(
        race: tourDeFrance,
        primaryLeaderId: leaderAlpha.id,
        strategy: RaceHierarchyStrategy.absoluteSoleLeader,
        squadRiders: [leaderAlpha, leaderChallenger],
        profiles: profiles,
        sportsDirector: eliteDs,
        managerReputation: 90,
      );

      // Challenger podporządkował się autorytetowi
      expect(declWithAuthority.dissentingRiderIds.isEmpty, isTrue);
      expect(declWithAuthority.agreedRiderIds, contains(leaderChallenger.id));

      // 2. Ze słabym sztabem (charyzma 35, reputacja menedżera 30)
      final declWeakAuthority = RiderEgoAndConflictsService.declareRaceHierarchy(
        race: tourDeFrance,
        primaryLeaderId: leaderAlpha.id,
        strategy: RaceHierarchyStrategy.absoluteSoleLeader,
        squadRiders: [leaderAlpha, leaderChallenger],
        profiles: profiles,
        sportsDirector: weakDs,
        managerReputation: 30,
      );

      // Challenger buntuje się przeciwko degradacji do pomocnika!
      expect(declWeakAuthority.dissentingRiderIds, contains(leaderChallenger.id));
    });
  });

  group('RiderEgoAndConflictsService - 4. Symulacja Buntu na Etapie Górskim', () {
    test('evaluateStageInRaceConflictRisk: atak na kolegę z zespołu przy słabości lidera i braku hierarchii', () {
      final profiles = {
        leaderAlpha.id: RiderEgoAndConflictsService.generatePersonalityProfile(leaderAlpha),
        leaderChallenger.id: RiderEgoAndConflictsService.generatePersonalityProfile(leaderChallenger),
      };

      final unsettledDecl = RaceHierarchyDeclaration(
        raceId: 'tdf_2026',
        raceName: 'Tour de France',
        primaryLeaderId: 'leader_alpha_01',
        strategy: RaceHierarchyStrategy.undefinedAmbiguity, // Chaos taktyczny
        declarationDate: DateTime(2026, 7, 1),
        agreedRiderIds: const [],
        dissentingRiderIds: const ['leader_challenger_02'],
      );

      // Lider A traci 45 sekund na alpejskim podjeździe
      final rng = math.Random(42);
      final incident = RiderEgoAndConflictsService.evaluateStageInRaceConflictRisk(
        race: tourDeFrance,
        stageNumber: 15,
        stageName: 'Alpe d\'Huez Summit Finish',
        squadRiders: [leaderAlpha, leaderChallenger],
        hierarchy: unsettledDecl,
        profiles: profiles,
        isHighMountainStage: true,
        primaryLeaderTimeLossSeconds: 45.0,
        rng: rng,
      );

      expect(incident, isNotNull);
      expect(incident!.aggressorRiderId, equals(leaderChallenger.id));
      expect(incident.victimRiderId, equals(leaderAlpha.id));
      expect(incident.incidentType, equals(IntraTeamIncidentType.mountainAttackOnTeammate));
      expect(incident.radioTranscript, contains('natychmiast zwolnij'));
      expect(incident.mediaHeadline, contains('WOJNA DOMOWA'));
    });

    test('Na płaskim etapie incydent nie występuje', () {
      final profiles = {
        leaderAlpha.id: RiderEgoAndConflictsService.generatePersonalityProfile(leaderAlpha),
        leaderChallenger.id: RiderEgoAndConflictsService.generatePersonalityProfile(leaderChallenger),
      };

      final incidentFlat = RiderEgoAndConflictsService.evaluateStageInRaceConflictRisk(
        race: tourDeFrance,
        stageNumber: 4,
        stageName: 'Bordeaux Sprint',
        squadRiders: [leaderAlpha, leaderChallenger],
        hierarchy: null,
        profiles: profiles,
        isHighMountainStage: false,
      );

      expect(incidentFlat, isNull);
    });
  });

  group('RiderEgoAndConflictsService - 5. Rozmowy Indywidualne w 4 Oczy', () {
    test('conductPrivateTalk z obietnicą wolnej ręki lub premii łagodzi konflikt', () {
      final profile = RiderEgoAndConflictsService.generatePersonalityProfile(leaderChallenger);

      const feud = ActiveTeamFeud(
        feudId: 'feud_01',
        riderAId: 'leader_alpha_01',
        riderAName: 'Lider Alpha',
        riderBId: 'leader_challenger_02',
        riderBName: 'Lider Challenger',
        hostilityScore: 75,
        publicMediaDramaLevel: 80,
        teamDivisionSeverity: 60,
        status: FeudStatus.openWarfare,
      );

      // Sukces rozmowy przy obietnicy wolnej ręki na kolejnym etapie
      final rngSuccess = math.Random(1);
      final resultFreedom = RiderEgoAndConflictsService.conductPrivateTalk(
        rider: leaderChallenger,
        topic: PrivateTalkTopic.promiseFutureStageFreedom,
        feud: feud,
        profile: profile,
        sportsDirector: eliteDs,
        managerReputation: 85,
        rng: rngSuccess,
      );

      expect(
        resultFreedom.outcome,
        anyOf(equals(PrivateTalkOutcomeType.peaceRestored), equals(PrivateTalkOutcomeType.grudgingCompliance)),
      );
      expect(resultFreedom.hostilityChange, lessThanOrEqualTo(0));
      expect(resultFreedom.dialogueSummary, contains('dżentelmeńską umowę'));
    });

    test('Ostra reprymenda wobec samca alfa może zaognić bunt', () {
      final profileAlpha = RiderEgoAndConflictsService.generatePersonalityProfile(leaderAlpha);

      // Reprymenda dla samca alfa z niskim rzutem
      final rngFail = math.Random(999);
      final resultEscalate = RiderEgoAndConflictsService.conductPrivateTalk(
        rider: leaderAlpha,
        topic: PrivateTalkTopic.sternDisciplinaryReprimand,
        feud: null,
        profile: profileAlpha,
        sportsDirector: weakDs,
        managerReputation: 30,
        rng: rngFail,
      );

      expect(resultEscalate.outcome, equals(PrivateTalkOutcomeType.rebellionEscalated));
      expect(resultEscalate.hostilityChange, greaterThan(0));
      expect(resultEscalate.riderMoraleChange, lessThan(0));
      expect(resultEscalate.riderQuote, contains('mój agent już szuka nowego zespołu'));
    });
  });

  group('RiderEgoAndConflictsService - 6. Obietnice Kontraktowe - Kary i Nagrody', () {
    test('applyBrokenPromisePenalty drastycznie obniża lojalność i morale', () {
      final promise = RiderContractPromise(
        id: 'p1',
        riderId: 'leader_alpha_01',
        type: ContractPromiseType.soleLeaderGrandTour,
        promisedDate: DateTime(2026, 1, 15),
      );

      final initialMorale = leaderAlpha.contract.morale;
      final initialLoyalty = leaderAlpha.contract.leaderLoyalty;

      final punishedRider = RiderEgoAndConflictsService.applyBrokenPromisePenalty(leaderAlpha, promise);

      expect(punishedRider.contract.morale, equals(initialMorale - 35.0));
      expect(punishedRider.contract.leaderLoyalty, equals(initialLoyalty - 45.0));
    });

    test('applyFulfilledPromiseReward podnosi lojalność i morale', () {
      final promise = RiderContractPromise(
        id: 'p2',
        riderId: 'leader_alpha_01',
        type: ContractPromiseType.soleLeaderGrandTour,
        promisedDate: DateTime(2026, 1, 15),
      );

      final initialMorale = leaderAlpha.contract.morale;
      final initialLoyalty = leaderAlpha.contract.leaderLoyalty;

      final rewardedRider = RiderEgoAndConflictsService.applyFulfilledPromiseReward(leaderAlpha, promise);

      expect(rewardedRider.contract.morale, equals((initialMorale + 15.0).clamp(0.0, 100.0)));
      expect(rewardedRider.contract.leaderLoyalty, equals((initialLoyalty + 20.0).clamp(0.0, 100.0)));
    });
  });

  group('RiderEgoAndConflictsService - 7. Serializacja JSON', () {
    test('Wszystkie modele psychologii i konfliktów serializują się bezstratnie', () {
      const profile = RiderPersonalityProfile(
        riderId: 'r1',
        archetype: PersonalityArchetype.alphaLeader,
        ambition: 92,
        egoLevel: 88,
        teamLoyalty: 60,
        mediaDramaProneness: 70,
        tacticalPatience: 45,
      );
      final jsonProf = profile.toJson();
      final restoredProf = RiderPersonalityProfile.fromJson(jsonProf);
      expect(restoredProf.archetype, equals(profile.archetype));
      expect(restoredProf.egoLevel, equals(profile.egoLevel));

      final promise = RiderContractPromise(
        id: 'prom_1',
        riderId: 'r1',
        type: ContractPromiseType.soleLeaderGrandTour,
        targetRaceId: 'tdf_2026',
        targetRaceName: 'Tour de France',
        status: ContractPromiseStatus.pending,
        promisedDate: DateTime(2026, 1, 10),
      );
      final restoredProm = RiderContractPromise.fromJson(promise.toJson());
      expect(restoredProm.type, equals(ContractPromiseType.soleLeaderGrandTour));
      expect(restoredProm.targetRaceName, equals('Tour de France'));

      final decl = RaceHierarchyDeclaration(
        raceId: 'tdf_2026',
        raceName: 'Tour de France',
        primaryLeaderId: 'r1',
        secondaryLeaderId: 'r2',
        strategy: RaceHierarchyStrategy.dualLeaderMeritocracy,
        declarationDate: DateTime(2026, 7, 1),
        agreedRiderIds: ['r1'],
        dissentingRiderIds: ['r2'],
      );
      final restoredDecl = RaceHierarchyDeclaration.fromJson(decl.toJson());
      expect(restoredDecl.strategy, equals(RaceHierarchyStrategy.dualLeaderMeritocracy));
      expect(restoredDecl.dissentingRiderIds, contains('r2'));

      final incident = TeamConflictIncident(
        id: 'inc_1',
        raceId: 'tdf_2026',
        stageNumber: 15,
        stageName: 'Alpe d\'Huez',
        aggressorRiderId: 'r2',
        aggressorRiderName: 'Kolarz Dwa',
        victimRiderId: 'r1',
        victimRiderName: 'Kolarz Jeden',
        incidentType: IntraTeamIncidentType.mountainAttackOnTeammate,
        severity: 85,
        radioTranscript: 'Zwolnij!',
        mediaHeadline: 'SKANDAL',
        moraleDamage: 15.0,
        incidentDate: DateTime(2026, 7, 15),
      );
      final restoredInc = TeamConflictIncident.fromJson(incident.toJson());
      expect(restoredInc.incidentType, equals(IntraTeamIncidentType.mountainAttackOnTeammate));
      expect(restoredInc.severity, equals(85));

      const feud = ActiveTeamFeud(
        feudId: 'f1',
        riderAId: 'r1',
        riderAName: 'Kolarz Jeden',
        riderBId: 'r2',
        riderBName: 'Kolarz Dwa',
        hostilityScore: 70,
        publicMediaDramaLevel: 80,
        teamDivisionSeverity: 60,
        status: FeudStatus.openWarfare,
      );
      final restoredFeud = ActiveTeamFeud.fromJson(feud.toJson());
      expect(restoredFeud.status, equals(FeudStatus.openWarfare));
      expect(restoredFeud.hostilityScore, equals(70));
    });
  });
}
