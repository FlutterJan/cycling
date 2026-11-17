// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/services/career/olympic_games_quadrennial_cycle_service.dart';

Rider _buildTestRider({
  required String id,
  required String firstName,
  required String lastName,
  required String nationalityIso,
  int ftpWatts = 410,
  double weightKg = 68.0,
  int raceIq = 82,
  int ttPos = 80,
  int aeroPos = 80,
  int careerPoints = 1500,
  Injury? injury,
}) {
  return Rider(
    id: id,
    firstName: firstName,
    lastName: lastName,
    nationalityIso: nationalityIso,
    birthDate: DateTime(1998, 5, 12),
    potential: 92,
    specialization: RiderSpecialization.puncher,
    physiology: RiderPhysiology(
      heightCm: 179.0,
      weightKg: weightKg,
      bodyFatPercentage: 6.8,
      ftpWatts: ftpWatts,
      wPrimeJoules: 24000,
      vo2Max: 83.5,
      maxHr: 194,
      restingHr: 38,
      lactateThresholdHr: 176,
      recoveryRate: 1.15,
      glycogenCapacityGrams: 580.0,
      form: 86.0,
      fatigue: 22.0,
    ),
    powerProfile: RiderPowerProfile(
      watts5s: 1320,
      watts15s: 1100,
      watts30s: 880,
      watts1m: 680,
      watts3m: 520,
      watts5m: 475,
      watts20m: ftpWatts + 20,
      watts60m: ftpWatts,
    ),
    skills: RiderSkills(
      cobbles: 78,
      descending: 84,
      bikeHandling: 86,
      aeroPositioning: aeroPos,
      draftingEfficiency: 82,
      raceIq: raceIq,
      rainResistance: 80,
      heatTolerance: 79,
      timeTrialPositioning: ttPos,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#F2C9AC',
      hairStyleIndex: 2,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
      glassesModelId: 'aero_gold',
      glassesLensColorHex: '#D4AF37',
      helmetModelId: 'pro_aero',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.48,
      bodyBuildType: BodyBuildType.allRounder,
    ),
    contract: const RiderContract(
      teamId: 'team_1',
      role: RiderRole.teamLeader,
      monthlySalaryEur: 85000,
      signingBonusEur: 50000,
      winBonusEur: 25000,
      releaseClauseEur: 1200000,
      contractEndYear: 2030,
      morale: 0.9,
      leaderLoyalty: 0.85,
      requiredRacesIds: [],
    ),
    health: RiderHealth(
      acuteTrainingLoad: 65.0,
      chronicTrainingLoad: 82.0,
      currentInjury: injury,
    ),
    careerPointsUci: careerPoints,
  );
}

List<Rider> _buildWorldPool() {
  return [
    _buildTestRider(
      id: 'bel_1',
      firstName: 'Remco',
      lastName: 'Star',
      nationalityIso: 'BEL',
      ftpWatts: 435,
      weightKg: 62.0,
      raceIq: 91,
      ttPos: 97,
      aeroPos: 98,
      careerPoints: 4800,
    ),
    _buildTestRider(
      id: 'bel_2',
      firstName: 'Wout',
      lastName: 'Classic',
      nationalityIso: 'BEL',
      ftpWatts: 445,
      weightKg: 76.0,
      raceIq: 90,
      ttPos: 92,
      aeroPos: 90,
      careerPoints: 3900,
    ),
    _buildTestRider(
      id: 'bel_3',
      firstName: 'Jasper',
      lastName: 'Sprint',
      nationalityIso: 'BEL',
      ftpWatts: 410,
      weightKg: 74.0,
      raceIq: 84,
      careerPoints: 3100,
    ),
    _buildTestRider(
      id: 'bel_4',
      firstName: 'Tiesj',
      lastName: 'Dom',
      nationalityIso: 'BEL',
      ftpWatts: 395,
      weightKg: 71.0,
      raceIq: 86,
      careerPoints: 1800,
    ),
    _buildTestRider(
      id: 'bel_5',
      firstName: 'Yves',
      lastName: 'Extra',
      nationalityIso: 'BEL',
      ftpWatts: 380,
      weightKg: 72.0,
      raceIq: 80,
      careerPoints: 900,
    ),
    _buildTestRider(
      id: 'bel_6_inj',
      firstName: 'Injured',
      lastName: 'Rider',
      nationalityIso: 'BEL',
      ftpWatts: 460,
      injury: const Injury(
        name: 'Clavicle',
        type: InjuryType.clavicleFracture,
        daysRemaining: 21,
        trainingAllowed: false,
      ),
    ),
    _buildTestRider(
      id: 'pol_1',
      firstName: 'Michał',
      lastName: 'Orzeł',
      nationalityIso: 'POL',
      ftpWatts: 415,
      weightKg: 67.0,
      raceIq: 92,
      careerPoints: 2600,
    ),
    _buildTestRider(
      id: 'fra_1',
      firstName: 'Valentin',
      lastName: 'Bleu',
      nationalityIso: 'FRA',
      ftpWatts: 422,
      weightKg: 66.0,
      raceIq: 87,
      careerPoints: 2900,
    ),
  ];
}

void main() {
  group('OlympicGamesQuadrennialCycleService', () {
    test('enforces 4-year quadrennial cycle and resolves host editions', () {
      final service = OlympicGamesQuadrennialCycleService();

      expect(service.isOlympicYear(2024), isTrue);
      expect(service.isOlympicYear(2025), isFalse);
      expect(service.isOlympicYear(2028), isTrue);
      expect(service.isOlympicYear(2032), isTrue);
      expect(service.isOlympicYear(2036), isTrue);

      expect(service.nextOlympicYear(2025), 2028);
      expect(service.yearsUntilNextOlympics(2025), 3);

      expect(
        service.evaluateCyclePhase(DateTime(2028, 8, 3)),
        OlympicCyclePhase.olympicGamesWindow,
      );
      expect(
        service.evaluateCyclePhase(DateTime(2028, 4, 15)),
        OlympicCyclePhase.qualificationWindow,
      );

      final paris = service.getEditionForYear(2024);
      final la = service.getEditionForYear(2028);
      final future = service.getEditionForYear(2036);

      expect(paris.hostCity, 'Paryż');
      expect(la.hostCity, 'Los Angeles');
      expect(future.year, 2036);
    });

    test('enforces No Race Radio rules and autonomous rider decisions', () {
      final service = OlympicGamesQuadrennialCycleService();
      final rrRules = service.getNoRaceRadioRules(OlympicDiscipline.roadRace);
      final ittRules =
          service.getNoRaceRadioRules(OlympicDiscipline.individualTimeTrial);

      expect(rrRules.raceRadioEnabled, isFalse);
      expect(rrRules.canReceiveLiveTimeGaps, isFalse);
      expect(rrRules.canIssueInstantTacticalOrders, isFalse);
      expect(rrRules.motoChalkboardDelaySeconds, greaterThan(0));
      expect(rrRules.breakawayChaosMultiplier, greaterThan(1.0));
      expect(ittRules.raceRadioEnabled, isFalse);

      final rider = _buildWorldPool().first;
      final decision = service.evaluateNoRadioRiderDecision(
        rider: rider,
        actualGapToBreakawaySeconds: 45,
        distanceRemainingKm: 14.0,
        nearestTeammateDistanceMeters: 20.0,
        seed: 42,
      );

      expect(decision.teammateInVisualContact, isTrue);
      expect(decision.tacticalAccuracy, inInclusiveRange(0.35, 1.0));
      expect(decision.rationale, isNotEmpty);
    });

    test('builds small national squads respecting max 4 RR / max 2 ITT quotas',
        () {
      final service = OlympicGamesQuadrennialCycleService();
      final pool = _buildWorldPool();

      final belRr = service.buildNationalTeamRoster(
        olympicYear: 2028,
        nationalityIso: 'BEL',
        discipline: OlympicDiscipline.roadRace,
        worldRiders: pool,
        nationUciRank: 1,
      );
      expect(belRr.maxAllowedQuota, 4);
      expect(belRr.squadSize, 4);
      expect(belRr.isWithinOlympicLimit, isTrue);
      expect(belRr.selectedRiderIds, isNot(contains('bel_6_inj')));

      final belItt = service.buildNationalTeamRoster(
        olympicYear: 2028,
        nationalityIso: 'BEL',
        discipline: OlympicDiscipline.individualTimeTrial,
        worldRiders: pool,
        nationUciRank: 1,
      );
      expect(belItt.maxAllowedQuota, 2);
      expect(belItt.squadSize, 2);
      expect(belItt.isWithinOlympicLimit, isTrue);
    });

    test(
        'awards Gold Helmet & Gold Frame for 4-year reign and expires on next cycle',
        () {
      final service = OlympicGamesQuadrennialCycleService();
      final pool = _buildWorldPool();

      final report = service.simulateOlympicRace(
        olympicYear: 2028,
        discipline: OlympicDiscipline.roadRace,
        worldRiders: pool,
        nationUciRanks: {'BEL': 1, 'POL': 8, 'FRA': 4},
        seed: 2028,
      );

      expect(report.standings, isNotEmpty);
      expect(report.goldMedalist?.medal, OlympicMedalTier.gold);
      expect(report.awardedGoldGear, isNotNull);

      final champId = report.goldMedalist!.riderId;
      final appearance2028 = service.resolveEquipmentAppearanceForRace(
        riderId: champId,
        currentYear: 2028,
        raceDiscipline: OlympicDiscipline.roadRace,
      );
      final appearance2031 = service.resolveEquipmentAppearanceForRace(
        riderId: champId,
        currentYear: 2031,
        raceDiscipline: OlympicDiscipline.roadRace,
      );
      final appearance2032 = service.resolveEquipmentAppearanceForRace(
        riderId: champId,
        currentYear: 2032,
        raceDiscipline: OlympicDiscipline.roadRace,
      );

      expect(appearance2028.usesGoldHelmet, isTrue);
      expect(appearance2028.usesGoldFrame, isTrue);
      expect(appearance2028.helmetHex, '#D4AF37');
      expect(appearance2031.usesGoldHelmet, isTrue);
      expect(appearance2032.usesGoldHelmet, isFalse);

      // JSON roundtrip check
      final restored =
          OlympicGamesQuadrennialCycleService.fromJson(service.toJson());
      expect(restored.goldGearRegistry.length, 1);
      expect(restored.simulationHistory.length, 1);
    });

    test('handles empty world rider pool gracefully', () {
      final service = OlympicGamesQuadrennialCycleService();
      final report = service.simulateOlympicRace(
        olympicYear: 2028,
        discipline: OlympicDiscipline.roadRace,
        worldRiders: const [],
      );
      expect(report.standings, isEmpty);
      expect(report.awardedGoldGear, isNull);
    });
  });

  group('OlympicGamesQuadrennialCyclePanel responsive UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final notifier = OlympicGamesQuadrennialCycleNotifier(initialYear: 2028);
        notifier.runOlympicSimulation(_buildWorldPool(), seed: 77);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OlympicGamesQuadrennialCyclePanel(
                state: notifier.state,
                onSelectDiscipline: notifier.selectDiscipline,
                onSimulateRace: () {},
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('Igrzyska Olimpijskie'), findsOneWidget);
        expect(find.textContaining('Wyścig bez radia'), findsOneWidget);
        expect(
          find.textContaining('Złoty Kask i Rama Mistrza Olimpijskiego'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
