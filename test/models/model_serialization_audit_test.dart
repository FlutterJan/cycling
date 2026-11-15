import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/models/model_serialization_audit.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return Directory.systemTemp.path;
      }
      return null;
    });
  });

  group('ModelSerializationAudit', () {
    test('audits all models in a full generated game world without errors', () async {
      final report = await ModelSerializationAudit.auditGeneratedWorld();

      expect(
        report.isSuccess,
        isTrue,
        reason: report.summaryReport,
      );
      expect(report.totalModelsChecked, greaterThan(1000));
      expect(report.ridersChecked, greaterThan(100));
      expect(report.teamsChecked, greaterThan(20));
      expect(report.racesChecked, greaterThan(10));
      expect(report.stagesChecked, greaterThan(10));
      expect(report.segmentsChecked, greaterThan(100));
      expect(report.staffChecked, greaterThan(5));
    });

    test('handles int-to-double coercion and null/missing newer fields safely', () {
      // 1. RiderPhysiology: int values for double fields + null form/fatigue/labProfile
      final physJson = <String, dynamic>{
        'heightCm': 180, // int instead of double
        'weightKg': 68, // int instead of double
        'bodyFatPercentage': 7, // int instead of double
        'ftpWatts': 410,
        'wPrimeJoules': 22000,
        'vo2Max': 82, // int instead of double
        'maxHr': 195,
        'restingHr': 40,
        'lactateThresholdHr': 176,
        'recoveryRate': 90, // int instead of double
        'glycogenCapacityGrams': 550, // int instead of double
        // form, fatigue, labProfile omitted (null)
      };
      final phys = RiderPhysiology.fromJson(physJson);
      expect(phys.heightCm, 180.0);
      expect(phys.form, 75.0);
      expect(phys.fatigue, 25.0);
      expect(phys.labProfile, isNull);

      // 2. RiderContract: int for double morale/leaderLoyalty + null requiredRacesIds
      final contractJson = <String, dynamic>{
        'teamId': 't_1',
        'role': 'leader',
        'monthlySalaryEur': 25000,
        'signingBonusEur': 10000,
        'winBonusEur': 5000,
        'releaseClauseEur': 200000,
        'contractEndYear': 2028,
        'morale': 90, // int instead of double
        'leaderLoyalty': 85, // int instead of double
        'requiredRacesIds': null,
      };
      final contract = RiderContract.fromJson(contractJson);
      expect(contract.morale, 90.0);
      expect(contract.requiredRacesIds, isEmpty);

      // 3. CyclingTeam: null lists
      final teamJson = <String, dynamic>{
        'id': 't_test',
        'name': 'Test Team',
        'division': 'worldTour',
        'countryIso': 'PL',
        'primaryJerseyColorHex': '#FFFFFF',
        'secondaryJerseyColorHex': '#000000',
        'accentJerseyColorHex': '#D4AF37',
        'cashBalanceEur': 1000000,
        'monthlyBurnRateEur': 50000,
        'uciPointsSeason': 100,
        'rosterRiderIds': null,
        'staff': {
          'trainersLevel': 70,
          'sportsDirectorsLevel': 70,
          'doctorsLevel': 70,
          'mechanicsLevel': 70,
          'scoutsLevel': 70,
        },
        'bikeDeal': {
          'manufacturerId': 'm_1',
          'manufacturerName': 'Aethel',
          'prestigeLevel': 80,
          'annualCashContributionEur': 200000,
          'freeBikesQuota': 30,
          'researchAndDevelopmentLevel': 75,
          'suppliedFrameIds': null,
          'suppliedWheelsetIds': null,
          'contractYearsLeft': 2,
          'minimumUciRankingRequired': 18,
        },
        'sponsors': null,
        'inventoryBikes': null,
      };
      final team = CyclingTeam.fromJson(teamJson);
      expect(team.rosterRiderIds, isEmpty);
      expect(team.sponsors, isEmpty);
      expect(team.inventoryBikes, isEmpty);
      expect(team.bikeDeal.suppliedFrameIds, isEmpty);

      // 4. TourRace: null stages, participatingTeamIds, classifications
      final raceJson = <String, dynamic>{
        'id': 'race_1',
        'name': 'Test Tour',
        'countryIso': 'PL',
        'uciCategory': 'worldTour',
        'startMonth': 5,
        'startDay': 10,
        'stages': null,
        'prizePoolEur': 100000,
        'participatingTeamIds': null,
        'ridersPerTeam': 7,
        'classifications': null,
      };
      final race = TourRace.fromJson(raceJson);
      expect(race.stages, isEmpty);
      expect(race.participatingTeamIds, isEmpty);
      expect(race.classifications.generalClassification, isEmpty);

      // 5. CareerSave: null newer fields
      final saveJson = <String, dynamic>{
        'id': 'save_1',
        'saveName': 'Test',
        'createdAt': '2026-01-01T00:00:00.000',
        'lastSavedAt': '2026-01-01T00:00:00.000',
        'difficulty': 'normal',
        'playerManagerName': 'Manager',
        'playerTeamId': 't_test',
        'currentDate': '2026-01-01T00:00:00.000',
        'currentSeasonYear': 2026,
        'calendar': {
          'seasonYear': 2026,
          'races': null,
        },
        'teams': null,
        'riders': null,
      };
      final save = CareerSave.fromJson(saveJson);
      expect(save.teams, isEmpty);
      expect(save.riders, isEmpty);
      expect(save.franchiseLeaders, isEmpty);
      expect(save.dedicatedSquads, isEmpty);
      expect(save.wildcardApplications, isEmpty);
      expect(save.scoutingProspects, isEmpty);
      expect(save.youthAcademy.level, 1);
    });
  });
}
