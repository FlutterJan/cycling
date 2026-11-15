import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/models/career/season_calendar.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/services/database/preset_real_names_template_generator.dart';
import 'package:pro_peloton_manager/services/generators/fictional_brands_catalog.dart';
import 'package:pro_peloton_manager/services/generators/uci_calendar_generator.dart';
import 'package:pro_peloton_manager/services/generators/world_teams_generator.dart';

CareerSave _createActiveCareerSaveFixture() {
  final world = WorldTeamsGenerator.generateWorldTourSystem(seed: 42);
  final teams = world.teams;
  final riders = world.allRiders;
  final races = UciCalendarGenerator.generateFullSeasonCalendar(
    seasonYear: 2026,
    participatingTeamIds: teams.map((t) => t.id).toList(),
  );

  final firstTeam = teams.first;
  final firstRider = riders.firstWhere((r) => r.contract.teamId == firstTeam.id);
  final secondRider = riders.firstWhere(
    (r) => r.id != firstRider.id && r.contract.teamId == firstTeam.id,
  );

  // Symulujemy trwający wyścig z zapisanymi klasyfikacjami oraz ukończony wyścig w historii
  final firstRace = races.first;
  final activeRace = races[1].copyWith(
    classifications: RaceClassifications(
      generalClassification: [
        RiderClassificationEntry(
          riderId: firstRider.id,
          riderName: firstRider.fullName,
          teamId: firstTeam.id,
          totalTimeSeconds: 14520,
          points: 0,
          rank: 1,
          timeBehindLeaderSeconds: 0,
        ),
        RiderClassificationEntry(
          riderId: secondRider.id,
          riderName: secondRider.fullName,
          teamId: firstTeam.id,
          totalTimeSeconds: 14545,
          points: 0,
          rank: 2,
          timeBehindLeaderSeconds: 25,
        ),
      ],
      pointsClassification: [
        RiderClassificationEntry(
          riderId: firstRider.id,
          riderName: firstRider.fullName,
          teamId: firstTeam.id,
          totalTimeSeconds: 0,
          points: 45,
          rank: 1,
          timeBehindLeaderSeconds: 0,
        ),
      ],
      mountainsClassification: const [],
      youthClassification: const [],
      teamClassification: [
        TeamClassificationEntry(
          teamId: firstTeam.id,
          teamName: firstTeam.name,
          totalTimeSeconds: 43600,
          rank: 1,
          timeBehindLeaderSeconds: 0,
        ),
      ],
    ),
  );

  final updatedRaces = List<TourRace>.from(races);
  updatedRaces[1] = activeRace;

  final calendar = SeasonCalendar(
    seasonYear: 2026,
    races: updatedRaces,
    currentRaceIndex: 1,
    activeRaceId: activeRace.id,
    activeStageIndex: 2,
    completedRaceIds: [firstRace.id],
    raceHistory: {
      firstRace.id: RaceHistoryEntry(
        raceId: firstRace.id,
        raceName: firstRace.name,
        seasonYear: 2026,
        winnerRiderId: firstRider.id,
        winnerRiderName: firstRider.fullName,
        winnerTeamId: firstTeam.id,
        winnerTeamName: firstTeam.name,
        winnerTotalTimeSeconds: 32100,
        completedDate: DateTime(2026, 1, 25),
      ),
    },
  );

  return CareerSave(
    id: 'career_test_168',
    saveName: 'Test Live Patch Career',
    createdAt: DateTime(2026, 1, 1),
    lastSavedAt: DateTime(2026, 2, 10),
    difficulty: CareerDifficulty.normal,
    playerManagerName: 'Jan Kowalski',
    playerTeamId: firstTeam.id,
    currentDate: DateTime(2026, 2, 10),
    currentSeasonYear: 2026,
    calendar: calendar,
    teams: teams,
    riders: riders,
    contractOffers: [
      CareerContractOffer(
        offerId: 'offer_1',
        riderId: firstRider.id,
        riderName: firstRider.fullName,
        offeringTeamId: firstTeam.id,
        offeringTeamName: firstTeam.name,
        annualSalaryEur: 2500000,
        contractDurationYears: 3,
        winBonusEur: 50000,
        proposedRole: firstRider.contract.role,
        status: ContractOfferStatus.pending,
        offeredDate: DateTime(2026, 2, 9),
      ),
    ],
  );
}

void main() {
  group('PresetRealNamesTemplateGenerator & ModSchemaValidator', () {
    test('exports all in-game IDs and writes pro_peloton_real_names_pack_template.json to disk', () async {
      final tempDir = await Directory.systemTemp.createTemp('ppm_template_test_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final file = await PresetRealNamesTemplateGenerator.generateTemplateFileOnDisk(
        targetDirectory: tempDir,
        includeBuiltInRealismDefaults: true,
      );

      expect(await file.exists(), isTrue);
      expect(
        file.path.endsWith(PresetRealNamesTemplateGenerator.templateFileName),
        isTrue,
      );

      final rawJson = await file.readAsString();
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;

      expect(decoded['structureType'], PresetRealNamesTemplateGenerator.communityPatchStructureName);
      expect(decoded['schemaVersion'], PresetRealNamesTemplateGenerator.schemaVersion);

      final teams = decoded['teams'] as List<dynamic>;
      final riders = decoded['riders'] as List<dynamic>;
      final races = decoded['races'] as List<dynamic>;
      final brands = decoded['brands'] as List<dynamic>;

      expect(teams, isNotEmpty);
      expect(riders, isNotEmpty);
      expect(races, isNotEmpty);
      expect(brands.length, FictionalBrandsCatalog.allBrands.length);

      final sampleTeam = teams.first as Map<String, dynamic>;
      for (final requiredKey in ModSchemaValidator.requiredEntryKeys) {
        expect(sampleTeam.containsKey(requiredKey), isTrue);
      }
    });

    test('ModSchemaValidator validates valid template and detects invalid HEX, duplicate IDs and missing keys', () {
      final patch = PresetRealNamesTemplateGenerator.buildCommunityRealismPatchStructure();
      final validReport = ModSchemaValidator.validateJson(patch.toPrettyJson());

      expect(validReport.isValid, isTrue);
      expect(validReport.errors, isEmpty);
      expect(validReport.teamsReplacedCount, patch.teams.length);
      expect(validReport.ridersReplacedCount, patch.riders.length);
      expect(validReport.racesReplacedCount, patch.races.length);
      expect(validReport.brandsReplacedCount, patch.brands.length);

      // Zła mapa z duplikatem ID, złym HEX i brakującym kluczem
      final brokenMap = patch.toJson();
      final brokenTeams = List<Map<String, dynamic>>.from(
        (brokenMap['teams'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      brokenTeams[0]['primaryHex'] = 'NOT_A_HEX';
      brokenTeams[1]['originalId'] = brokenTeams[0]['originalId']; // duplikat
      brokenTeams[2].remove('customShortName'); // brak wymaganego klucza
      brokenMap['teams'] = brokenTeams;

      final invalidReport = ModSchemaValidator.validateRawMap(brokenMap);
      expect(invalidReport.isValid, isFalse);
      expect(invalidReport.errors.any((e) => e.field == 'primaryHex'), isTrue);
      expect(invalidReport.errors.any((e) => e.field == 'originalId'), isTrue);
      expect(invalidReport.errors.any((e) => e.field == 'customShortName'), isTrue);
    });

    test('applyLivePatchToActiveCareer updates names without breaking progress, contracts or classifications', () {
      final activeSave = _createActiveCareerSaveFixture();
      final firstTeam = activeSave.teams.first;
      final firstRider = activeSave.riders.firstWhere((r) => r.contract.teamId == firstTeam.id);
      final activeRace = activeSave.calendar.races[1];
      final completedRace = activeSave.calendar.races.first;

      final basePatch = PresetRealNamesTemplateGenerator.buildTemplateFromCareerSave(activeSave);
      final patchedTeams = basePatch.teams.map((t) {
        if (t.originalId == firstTeam.id) {
          return t.copyWith(
            customName: 'UAE Team Emirates XRG',
            customShortName: 'UAD',
            customCountryIso: 'ARE',
            primaryHex: '#FFFFFF',
            secondaryHex: '#0F1115',
            jerseyPatternIndex: 3,
          );
        }
        return t;
      }).toList();

      final patchedRiders = basePatch.riders.map((r) {
        if (r.originalId == firstRider.id) {
          return r.copyWith(
            customName: 'Tadej Pogacar',
            customShortName: 'T. POGACAR',
            customCountryIso: 'SVN',
          );
        }
        return r;
      }).toList();

      final patchedRaces = basePatch.races.map((rc) {
        if (rc.originalId == activeRace.id) {
          return rc.copyWith(
            customName: 'Tour de France Official',
            customShortName: 'TDF',
            customCountryIso: 'FRA',
          );
        }
        return rc;
      }).toList();

      final customPatch = basePatch.copyWith(
        teams: patchedTeams,
        riders: patchedRiders,
        races: patchedRaces,
      );

      final result = PresetRealNamesTemplateGenerator.applyLivePatchToActiveCareer(
        activeSave: activeSave,
        patch: customPatch,
      );

      expect(result.validationReport.isValid, isTrue);
      expect(result.teamsReplaced, activeSave.teams.length);
      expect(result.ridersReplaced, activeSave.riders.length);
      expect(result.racesReplaced, activeSave.calendar.races.length);

      final updatedSave = result.updatedSave;
      final updatedTeam = updatedSave.getTeamById(firstTeam.id)!;
      final updatedRider = updatedSave.getRiderById(firstRider.id)!;
      final updatedActiveRace = updatedSave.calendar.getRaceById(activeRace.id)!;

      // Nazwy zaktualizowane
      expect(updatedTeam.name, 'UAE Team Emirates XRG');
      expect(updatedRider.fullName, 'Tadej Pogacar');
      expect(updatedRider.nationalityIso, 'SVN');
      expect(updatedActiveRace.name, 'Tour de France Official');

      // Postępy kariery, kontrakty, finanse i wyniki klasyfikacji nienaruszone
      expect(updatedSave.calendar.currentRaceIndex, 1);
      expect(updatedSave.calendar.activeRaceId, activeRace.id);
      expect(updatedSave.calendar.activeStageIndex, 2);
      expect(updatedSave.calendar.completedRaceIds, [completedRace.id]);

      expect(updatedTeam.cashBalanceEur, firstTeam.cashBalanceEur);
      expect(updatedRider.contract, firstRider.contract);
      expect(updatedRider.careerPointsUci, firstRider.careerPointsUci);

      final gcLeader = updatedActiveRace.classifications.generalClassification.first;
      expect(gcLeader.riderId, firstRider.id);
      expect(gcLeader.riderName, 'Tadej Pogacar');
      expect(gcLeader.totalTimeSeconds, 14520);
      expect(gcLeader.rank, 1);

      final teamGcLeader = updatedActiveRace.classifications.teamClassification.first;
      expect(teamGcLeader.teamId, firstTeam.id);
      expect(teamGcLeader.teamName, 'UAE Team Emirates XRG');
      expect(teamGcLeader.totalTimeSeconds, 43600);

      final historyEntry = updatedSave.calendar.raceHistory[completedRace.id]!;
      expect(historyEntry.winnerRiderName, 'Tadej Pogacar');
      expect(historyEntry.winnerTeamName, 'UAE Team Emirates XRG');
      expect(historyEntry.winnerTotalTimeSeconds, 32100);

      final updatedOffer = updatedSave.contractOffers.first;
      expect(updatedOffer.riderName, 'Tadej Pogacar');
      expect(updatedOffer.offeringTeamName, 'UAE Team Emirates XRG');
      expect(updatedOffer.annualSalaryEur, 2500000);
    });
  });
}
