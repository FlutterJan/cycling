// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/services/career/pre_season_wind_tunnel_camp_event.dart';

Rider _buildTestRider({
  required String id,
  required String firstName,
  required String lastName,
  RiderSpecialization specialization = RiderSpecialization.timeTrialist,
  int ftpWatts = 410,
  int aeroPositioning = 65,
  int ttPositioning = 70,
}) {
  return Rider(
    id: id,
    firstName: firstName,
    lastName: lastName,
    nationalityIso: 'PL',
    birthDate: DateTime(1998, 5, 14),
    potential: 88,
    specialization: specialization,
    physiology: RiderPhysiology(
      heightCm: 181.0,
      weightKg: 70.0,
      bodyFatPercentage: 7.5,
      ftpWatts: ftpWatts,
      wPrimeJoules: 22000,
      vo2Max: 78.0,
      maxHr: 192,
      restingHr: 40,
      lactateThresholdHr: 174,
      recoveryRate: 1.1,
      glycogenCapacityGrams: 560.0,
    ),
    powerProfile: const RiderPowerProfile(
      watts5s: 1220,
      watts15s: 980,
      watts30s: 810,
      watts1m: 640,
      watts3m: 515,
      watts5m: 475,
      watts20m: 430,
      watts60m: 405,
    ),
    skills: RiderSkills(
      cobbles: 72,
      descending: 74,
      bikeHandling: 78,
      aeroPositioning: aeroPositioning,
      draftingEfficiency: 75,
      raceIq: 76,
      rainResistance: 72,
      heatTolerance: 74,
      timeTrialPositioning: ttPositioning,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#F1C27D',
      hairStyleIndex: 2,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
      glassesModelId: 'aero_shield',
      glassesLensColorHex: '#00E5FF',
      helmetModelId: 'tt_default',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.7,
      bodyBuildType: BodyBuildType.allRounder,
    ),
    contract: const RiderContract(
      teamId: 'team_1',
      role: RiderRole.teamLeader,
      monthlySalaryEur: 25000,
      signingBonusEur: 0,
      winBonusEur: 5000,
      releaseClauseEur: 1200000,
      contractEndYear: 2028,
      morale: 0.85,
      leaderLoyalty: 0.85,
      requiredRacesIds: [],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 30.0,
      chronicTrainingLoad: 68.0,
    ),
    careerPointsUci: 850,
  );
}

List<Rider> _buildRoster8() {
  return [
    _buildTestRider(
      id: 'r1',
      firstName: 'Michał',
      lastName: 'Kwiatkowski',
      specialization: RiderSpecialization.timeTrialist,
      ftpWatts: 420,
      aeroPositioning: 74,
      ttPositioning: 78,
    ),
    _buildTestRider(
      id: 'r2',
      firstName: 'Filip',
      lastName: 'Maciejuk',
      specialization: RiderSpecialization.timeTrialist,
      ftpWatts: 415,
      aeroPositioning: 68,
      ttPositioning: 72,
    ),
    _buildTestRider(
      id: 'r3',
      firstName: 'Rafał',
      lastName: 'Majka',
      specialization: RiderSpecialization.gcClimber,
      ftpWatts: 395,
      aeroPositioning: 64,
      ttPositioning: 68,
    ),
    _buildTestRider(
      id: 'r4',
      firstName: 'Stanisław',
      lastName: 'Aniołkowski',
      specialization: RiderSpecialization.pureSprinter,
      ftpWatts: 385,
      aeroPositioning: 62,
      ttPositioning: 60,
    ),
    _buildTestRider(
      id: 'r5',
      firstName: 'Kamil',
      lastName: 'Gradek',
      specialization: RiderSpecialization.classicCobbles,
      ftpWatts: 405,
      aeroPositioning: 66,
      ttPositioning: 70,
    ),
    _buildTestRider(
      id: 'r6',
      firstName: 'Cesare',
      lastName: 'Benedetti',
      specialization: RiderSpecialization.domestiqueEngine,
      ftpWatts: 380,
      aeroPositioning: 60,
      ttPositioning: 62,
    ),
    _buildTestRider(
      id: 'r7',
      firstName: 'Łukasz',
      lastName: 'Wiśniowski',
      specialization: RiderSpecialization.classicCobbles,
      ftpWatts: 390,
      aeroPositioning: 61,
      ttPositioning: 64,
    ),
    _buildTestRider(
      id: 'r8',
      firstName: 'Piotr',
      lastName: 'Pękala',
      specialization: RiderSpecialization.pureClimber,
      ftpWatts: 375,
      aeroPositioning: 58,
      ttPositioning: 59,
    ),
  ];
}

void main() {
  group('PreSeasonWindTunnelCampEvent domain logic', () {
    test('detects December camp window accurately', () {
      expect(
        PreSeasonWindTunnelCampEvent.isDecemberCampWindow(DateTime(2026, 12, 8)),
        isTrue,
      );
      expect(
        PreSeasonWindTunnelCampEvent.isDecemberCampWindow(DateTime(2026, 1, 15)),
        isFalse,
      );
    });

    test('selectKeySixRiders caps selection at 6 and prioritizes TT/GC', () {
      const event = PreSeasonWindTunnelCampEvent();
      final roster = _buildRoster8();
      final keySix = event.selectKeySixRiders(roster);

      expect(keySix.length, 6);
      expect(
        keySix.first.specialization,
        RiderSpecialization.timeTrialist,
      );
    });

    test('evaluateRiderSetup calculates CdA drop, watts saved, and track bonus', () {
      const event = PreSeasonWindTunnelCampEvent();
      final rider = _buildRoster8().first;
      final baseline = RiderWindTunnelBaseline.fromRider(rider);

      final withoutTrack = event.evaluateRiderSetup(
        baseline: baseline,
        facility: WindTunnelFacility.silverstoneSportsHub,
        config: WindTunnelRiderTestConfig(
          riderId: rider.id,
          testedPosture: TimeTrialPostureOption.lowAggressiveSuperman,
          testedHelmet: AeroHelmetOption.custom3dPrintedVisor,
          testedSkinsuit: SkinsuitOption.customTailoredWindTunnelSuit,
          trackValidationCompleted: false,
        ),
      );

      final withTrack = event.evaluateRiderSetup(
        baseline: baseline,
        facility: WindTunnelFacility.silverstoneSportsHub,
        config: WindTunnelRiderTestConfig(
          riderId: rider.id,
          testedPosture: TimeTrialPostureOption.lowAggressiveSuperman,
          testedHelmet: AeroHelmetOption.custom3dPrintedVisor,
          testedSkinsuit: SkinsuitOption.customTailoredWindTunnelSuit,
          trackValidationCompleted: true,
        ),
      );

      expect(withoutTrack.cdaReductionM2, greaterThan(0.015));
      expect(withTrack.cdaReductionM2, greaterThan(withoutTrack.cdaReductionM2));
      expect(withTrack.wattsSavedAt50Kmh, greaterThan(withTrack.wattsSavedAt45Kmh));
      expect(withTrack.estimated40KmTtGainSeconds, greaterThan(20.0));
    });

    test('finalizeCamp permanently lowers base CdA for up to 6 key riders', () {
      const event = PreSeasonWindTunnelCampEvent();
      final roster = _buildRoster8();
      final selectedIds = roster.take(6).map((r) => r.id).toList();
      final configs = {
        for (final id in selectedIds)
          id: WindTunnelRiderTestConfig(
            riderId: id,
            testedPosture: TimeTrialPostureOption.highHandsPrayingMantis,
            testedHelmet: AeroHelmetOption.wideVisorStubby,
            testedSkinsuit: SkinsuitOption.ribbedSleeveAero,
            trackValidationCompleted: true,
          ),
      };

      final outcome = event.finalizeCamp(
        seasonYear: 2027,
        facility: WindTunnelFacility.a2WindTunnel,
        fullRoster: roster,
        selectedRiderIds: selectedIds,
        configsByRiderId: configs,
      );

      expect(outcome.riderResults.length, 6);
      expect(outcome.seasonCdaGrants.length, 6);
      expect(outcome.averageCdaReductionM2, greaterThan(0.01));
      expect(outcome.totalWattsSavedAt50Kmh, greaterThan(100.0));

      for (int i = 0; i < 6; i++) {
        final beforeCda = PreSeasonWindTunnelCampEvent.computeBaselineCdaM2(roster[i]);
        final afterCda = PreSeasonWindTunnelCampEvent.computeBaselineCdaM2(
          outcome.updatedRoster[i],
        );
        expect(afterCda, lessThan(beforeCda));
      }

      // Unselected riders remain untouched
      expect(
        outcome.updatedRoster[6].skills.aeroPositioning,
        roster[6].skills.aeroPositioning,
      );
    });
  });

  group('PreSeasonWindTunnelCampPanel responsive UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders and completes camp without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          final roster = _buildRoster8();
          final container = ProviderContainer();
          addTearDown(container.dispose);

          container.read(preSeasonWindTunnelCampProvider.notifier).initializeCamp(
                seasonYear: 2027,
                teamBudgetEur: 500000,
                roster: roster,
              );

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(
                home: Scaffold(
                  body: PreSeasonWindTunnelCampPanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.textContaining('Grudniowy Obóz Aerodynamiczny 2027'), findsOneWidget);
          expect(find.textContaining('Silverstone Sports Engineering Hub'), findsWidgets);

          final proceedBtn = find.text('Rozpocznij Testy w Tunelu i na Torze');
          await tester.ensureVisible(proceedBtn);
          await tester.tap(proceedBtn);
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.textContaining('3 Pozycje Czasowe (TT)'), findsOneWidget);

          final finalizeBtn =
              find.text('Zatwierdź Obóz i Obniż Bazowe CdA na Cały Rok');
          await tester.ensureVisible(finalizeBtn);
          await tester.tap(finalizeBtn);
          await tester.pump(const Duration(milliseconds: 300));

          expect(
            find.textContaining('Raport Końcowy Obozu Aerodynamicznego 2027'),
            findsOneWidget,
          );
        },
      );
    }
  });
}
