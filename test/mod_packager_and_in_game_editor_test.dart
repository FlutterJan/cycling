import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/models/equipment/complete_bike.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/models/team/sponsor_contract.dart';
import 'package:pro_peloton_manager/services/database/custom_mod_importer_service.dart';
import 'package:pro_peloton_manager/services/database/mod_workshop_validator_and_packager.dart';
import 'package:pro_peloton_manager/ui/screens/in_game_database_roster_editor_screen.dart';

CyclingTeam _buildTestTeam({
  required String id,
  required String name,
  TeamDivision division = TeamDivision.worldTour,
  String countryIso = 'POL',
  String primaryHex = '#8E4A49',
  String secondaryHex = '#181B22',
  String accentHex = '#D4AF37',
  List<String> rosterIds = const [],
}) {
  return CyclingTeam(
    id: id,
    name: name,
    division: division,
    countryIso: countryIso,
    primaryJerseyColorHex: primaryHex,
    secondaryJerseyColorHex: secondaryHex,
    accentJerseyColorHex: accentHex,
    cashBalanceEur: 4500000,
    monthlyBurnRateEur: 280000,
    uciPointsSeason: 1200,
    rosterRiderIds: rosterIds,
    staff: const TeamStaff(
      trainersLevel: 78,
      sportsDirectorsLevel: 80,
      doctorsLevel: 76,
      mechanicsLevel: 81,
      scoutsLevel: 75,
    ),
    bikeDeal: const BikeManufacturerDeal(
      manufacturerId: 'aethon_cycles',
      manufacturerName: 'Aethon Cycles',
      prestigeLevel: 4,
      annualCashContributionEur: 900000,
      freeBikesQuota: 80,
      researchAndDevelopmentLevel: 82,
      suppliedFrameIds: ['aethon_aero_sl'],
      suppliedWheelsetIds: ['aethon_carbon_50'],
      contractYearsLeft: 2,
      minimumUciRankingRequired: 20,
    ),
    sponsors: const <SponsorContract>[],
    inventoryBikes: const <CompleteBike>[],
  );
}

Rider _buildTestRider({
  required String id,
  required String teamId,
  String firstName = 'Marek',
  String lastName = 'Zieliński',
  String nationalityIso = 'POL',
  double weightKg = 67.5,
  int watts5s = 1350,
  int watts1m = 680,
  int watts20m = 420,
}) {
  return Rider(
    id: id,
    firstName: firstName,
    lastName: lastName,
    nationalityIso: nationalityIso,
    birthDate: DateTime(1998, 6, 15),
    potential: 86,
    specialization: RiderSpecialization.puncher,
    physiology: RiderPhysiology(
      heightCm: 180.0,
      weightKg: weightKg,
      bodyFatPercentage: 7.2,
      ftpWatts: 400,
      wPrimeJoules: 22000,
      vo2Max: 82.0,
      maxHr: 194,
      restingHr: 40,
      lactateThresholdHr: 175,
      recoveryRate: 1.1,
      glycogenCapacityGrams: 630.0,
    ),
    powerProfile: RiderPowerProfile(
      watts5s: watts5s,
      watts15s: 1100,
      watts30s: 890,
      watts1m: watts1m,
      watts3m: 520,
      watts5m: 475,
      watts20m: watts20m,
      watts60m: 385,
    ),
    skills: const RiderSkills(
      cobbles: 76,
      descending: 78,
      bikeHandling: 80,
      aeroPositioning: 77,
      draftingEfficiency: 79,
      raceIq: 81,
      rainResistance: 74,
      heatTolerance: 75,
      timeTrialPositioning: 76,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#F1C27D',
      hairStyleIndex: 2,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
      glassesModelId: 'aero_pro',
      glassesLensColorHex: '#38BDF8',
      helmetModelId: 'vent_pro',
      shoeColorHex: '#F3F4F6',
      sockHeightProportion: 0.72,
      bodyBuildType: BodyBuildType.allRounder,
    ),
    contract: RiderContract(
      teamId: teamId,
      role: RiderRole.domestique,
      monthlySalaryEur: 12000,
      signingBonusEur: 15000,
      winBonusEur: 4000,
      releaseClauseEur: 350000,
      contractEndYear: 2028,
      morale: 84.0,
      leaderLoyalty: 80.0,
      requiredRacesIds: const [],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 45.0,
      chronicTrainingLoad: 78.0,
    ),
    careerPointsUci: 145,
  );
}

void main() {
  const packager = ModWorkshopValidatorAndPackager();

  group('DatabaseEditorCodec validation and JSON round-trip', () {
    test('validates valid teams and riders with zero issues', () {
      final team = _buildTestTeam(
        id: 'team_pol_wt',
        name: 'Veloce Polska WT',
        rosterIds: ['r1', 'r2', 'r3', 'r4', 'r5'],
      );
      final riders = List.generate(
        5,
        (i) => _buildTestRider(
          id: 'r${i + 1}',
          teamId: 'team_pol_wt',
          firstName: 'Kolarz',
          lastName: 'Numer${i + 1}',
        ),
      );

      final issues = DatabaseEditorCodec.validateDatabase(
        teams: [team],
        riders: riders,
      );

      expect(issues, isEmpty);
      expect(DatabaseEditorCodec.isValidHexColor('#D4AF37'), isTrue);
      expect(DatabaseEditorCodec.isValidHexColor('D4AF37'), isFalse);
      expect(
        DatabaseEditorCodec.parseHexColor('#D4AF37'),
        const Color(0xFFD4AF37),
      );
      expect(
        DatabaseEditorCodec.parseHexColor('invalid'),
        AppColors.primaryAccent,
      );
    });

    test('detects empty names, bad HEX colors, WT roster warning and power/weight anomalies',
        () {
      final badTeam = _buildTestTeam(
        id: 'team_bad',
        name: '   ',
        division: TeamDivision.worldTour,
        primaryHex: 'NOT_HEX',
      );
      final badRider = _buildTestRider(
        id: 'rider_bad',
        teamId: 'team_bad',
        firstName: '',
        lastName: 'Test',
        weightKg: 39.0,
        watts5s: 600,
        watts1m: 700,
        watts20m: 420,
      );

      final issues = DatabaseEditorCodec.validateDatabase(
        teams: [badTeam],
        riders: [badRider],
      );

      final errors = issues.where((i) => i.isError).toList();
      final warnings = issues.where((i) => !i.isError).toList();

      expect(errors.length, 3); // empty team name, bad HEX, empty rider firstName
      expect(warnings.length, 3); // WT < 5 riders, weight < 45, non-monotonic power
    });

    test('exports and imports teams and riders losslessly through JSON', () {
      final team = _buildTestTeam(
        id: 'team_json',
        name: 'Baltic Pro Cycling',
        division: TeamDivision.proTeam,
        rosterIds: ['r_json_1'],
      );
      final rider = _buildTestRider(
        id: 'r_json_1',
        teamId: 'team_json',
        firstName: 'Piotr',
        lastName: 'Kowalski',
      );

      final rawJson = DatabaseEditorCodec.exportToJson(
        teams: [team],
        riders: [rider],
      );
      final imported = DatabaseEditorCodec.importFromJson(rawJson);

      expect(imported.teams.length, 1);
      expect(imported.riders.length, 1);
      expect(imported.teams.first.id, 'team_json');
      expect(imported.teams.first.name, 'Baltic Pro Cycling');
      expect(imported.teams.first.primaryJerseyColorHex, '#8E4A49');
      expect(imported.riders.first.fullName, 'Piotr Kowalski');
      expect(imported.riders.first.physiology.ftpWatts, 400);

      expect(
        () => DatabaseEditorCodec.importFromJson('{"teams": "bad"}'),
        throwsFormatException,
      );
    });
  });

  group('ModWorkshopValidatorAndPackager .ppmmod packaging & security', () {
    test('encodes and decodes .ppmmod in GZip and plain JSON with FNV-1a64 verification',
        () {
      final starter = packager.createStarterTemplatePackage();

      final gzipEncoded = packager.encodeToPpmModString(
        starter,
        compression: PpmModExportCompression.gzipBase64,
      );
      expect(gzipEncoded.startsWith(kPpmModGzipPrefix), isTrue);

      final gzipDecoded = packager.decodeFromPpmModString(gzipEncoded);
      expect(gzipDecoded.wasCompressed, isTrue);
      expect(gzipDecoded.checksumVerified, isTrue);
      expect(gzipDecoded.validationReport.isValid, isTrue);
      expect(gzipDecoded.package.manifest.modId, starter.manifest.modId);

      final plainEncoded = packager.encodeToPpmModString(
        starter,
        compression: PpmModExportCompression.plainJson,
      );
      expect(plainEncoded.startsWith('{'), isTrue);

      final plainDecoded = packager.decodeFromPpmModString(plainEncoded);
      expect(plainDecoded.wasCompressed, isFalse);
      expect(plainDecoded.checksumVerified, isTrue);

      // Tampering checksum must throw FormatException
      final tampered = plainEncoded.replaceFirst(
        '"title":"${starter.manifest.title}"',
        '"title":"Tampered Mod Title"',
      );
      expect(
        () => packager.decodeFromPpmModString(tampered, verifyChecksum: true),
        throwsFormatException,
      );
    });

    test('blocks path traversal, invalid checksums, duplicate assets and oversized assets',
        () {
      final validBytes = utf8.encode('jersey_texture_bytes');
      final validB64 = base64Encode(validBytes);
      final validChecksum = ModWorkshopValidatorAndPackager.computeFnv1a64(validB64);

      final riskyPackage = packager.createStarterTemplatePackage().copyWith(
        assets: [
          PpmModAssetEntry(
            relativePath: '../../secrets/key.txt',
            assetKind: PpmModAssetKind.jerseyTexture,
            byteSize: validBytes.length,
            fnv1a64Checksum: validChecksum,
            payloadBase64: validB64,
          ),
          PpmModAssetEntry(
            relativePath: 'jerseys/team_a.png',
            assetKind: PpmModAssetKind.jerseyTexture,
            byteSize: validBytes.length,
            fnv1a64Checksum: '0000000000000000',
            payloadBase64: validB64,
          ),
          PpmModAssetEntry(
            relativePath: 'jerseys/team_a.png',
            assetKind: PpmModAssetKind.jerseyTexture,
            byteSize: kMaxPpmModSingleAssetBytes + 1,
            fnv1a64Checksum: validChecksum,
            payloadBase64: 'NOT_VALID_BASE64!!!',
          ),
        ],
      );

      final report = packager.validatePackage(riskyPackage);
      final codes = report.errors.map((e) => e.code).toSet();

      expect(report.isValid, isFalse);
      expect(codes, contains('UNSAFE_ASSET_PATH'));
      expect(codes, contains('ASSET_CHECKSUM_MISMATCH'));
      expect(codes, contains('DUPLICATE_ASSET_PATH'));
      expect(codes, contains('ASSET_SIZE_INVALID'));
      expect(codes, contains('ASSET_INVALID_BASE64'));
    });

    test('bridges in-game editor database into .ppmmod file and re-imports atomically',
        () async {
      final tempDir = await Directory.systemTemp.createTemp('ppm_editor_mod_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final team = _buildTestTeam(
        id: 'team_bridge',
        name: 'Warszawa Continental',
        division: TeamDivision.continental,
      );
      final rider = _buildTestRider(
        id: 'rider_bridge',
        teamId: 'team_bridge',
        firstName: 'Adam',
        lastName: 'Mazur',
      );

      final exportedJson = DatabaseEditorCodec.exportToJson(
        teams: [team],
        riders: [rider],
      );
      final reimportedDb = DatabaseEditorCodec.importFromJson(exportedJson);

      final modPackage = PpmModPackage.fromCustomModPackage(
        CustomModPackage(
          metadata: CustomModMetadata(
            id: 'warszawa_editor_export',
            name: 'Warszawa Editor Export',
            version: '1.2.0',
            author: 'Sniper QA',
            description:
                'Paczka wygenerowana z edytora bazy danych do testów integralności .ppmmod.',
            createdDate: DateTime.utc(2026, 11, 17),
          ),
          teams: reimportedDb.teams
              .map(
                (t) => TeamModEntry(
                  matchId: t.id,
                  name: t.name,
                  countryIso: t.countryIso,
                  primaryJerseyColorHex: t.primaryJerseyColorHex,
                  secondaryJerseyColorHex: t.secondaryJerseyColorHex,
                  accentJerseyColorHex: t.accentJerseyColorHex,
                ),
              )
              .toList(),
          riders: reimportedDb.riders
              .map(
                (r) => RiderModEntry(
                  matchId: r.id,
                  matchTeamId: r.contract.teamId,
                  firstName: r.firstName,
                  lastName: r.lastName,
                  nationalityIso: r.nationalityIso,
                  birthYear: r.birthDate.year,
                  targetOverallRating: r.overallRating,
                ),
              )
              .toList(),
        ),
        tags: const ['database', 'editor'],
      );

      final outPath = '${tempDir.path}${Platform.pathSeparator}warszawa_export';
      final receipt = await packager.exportToFile(modPackage, outPath);

      expect(receipt.filePath.endsWith(kPpmModFileExtension), isTrue);
      expect(await File(receipt.filePath).exists(), isTrue);
      expect(await File('${receipt.filePath}.tmp').exists(), isFalse);
      expect(receipt.validationReport.isValid, isTrue);

      final loaded = await packager.importFromFile(receipt.filePath);
      expect(loaded.checksumVerified, isTrue);
      expect(loaded.wasCompressed, isTrue);
      expect(loaded.package.customModPackage?.teams.first.name, 'Warszawa Continental');
      expect(loaded.package.customModPackage?.riders.first.fullName, 'Adam Mazur');

      expect(
        () => packager.importFromFile('${tempDir.path}/missing_file.ppmmod'),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('ModWorkshopPackagerNotifier Riverpod state', () {
    test('updates contentType, compression, filter and exports/imports .ppmmod',
        () async {
      final tempDir = await Directory.systemTemp.createTemp('ppm_notifier_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(modWorkshopPackagerProvider.notifier);
      expect(container.read(modWorkshopPackagerProvider).lastReport?.isValid, isTrue);

      notifier.updateContentType(PpmModContentType.totalConversion);
      expect(
        container.read(modWorkshopPackagerProvider).activePackage.manifest.contentType,
        PpmModContentType.totalConversion,
      );

      notifier.setCompression(PpmModExportCompression.plainJson);
      notifier.setIssueFilter(PpmModValidationSeverity.warning);
      expect(
        container.read(modWorkshopPackagerProvider).issueFilter,
        PpmModValidationSeverity.warning,
      );

      final exportPath = '${tempDir.path}${Platform.pathSeparator}notifier_test.ppmmod';
      final receipt = await notifier.exportActivePackage(exportPath);
      expect(receipt, isNotNull);
      expect(receipt!.compression, PpmModExportCompression.plainJson);

      final imported = await notifier.importPackageFromFile(receipt.filePath);
      expect(imported, isNotNull);
      expect(imported!.checksumVerified, isTrue);
    });
  });

  group('InGameDatabaseRosterEditorScreen & ModWorkshopValidatorAndPackagerPanel UI',
      () {
    Future<void> pumpResponsiveWidget(
      WidgetTester tester, {
      required Size size,
      required Widget child,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(body: child),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final viewport in const [
      (name: '390x844 mobile', size: Size(390, 844)),
      (name: '1024x768 tablet', size: Size(1024, 768)),
      (name: '1600x900 desktop', size: Size(1600, 900)),
    ]) {
      testWidgets(
          'InGameDatabaseRosterEditorScreen renders without overflow at ${viewport.name}',
          (tester) async {
        final team = _buildTestTeam(
          id: 'team_ui_1',
          name: 'Alpe Adria WT',
          rosterIds: ['r_ui_1', 'r_ui_2'],
        );
        final riders = [
          _buildTestRider(id: 'r_ui_1', teamId: 'team_ui_1'),
          _buildTestRider(
            id: 'r_ui_2',
            teamId: 'team_ui_1',
            firstName: 'Tomasz',
            lastName: 'Majka',
          ),
        ];

        await pumpResponsiveWidget(
          tester,
          size: viewport.size,
          child: InGameDatabaseRosterEditorScreen(
            initialTeams: [team],
            initialRiders: riders,
          ),
        );

        expect(find.text('Edytor Bazy Danych i Składów'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
          'ModWorkshopValidatorAndPackagerPanel renders without overflow at ${viewport.name}',
          (tester) async {
        await pumpResponsiveWidget(
          tester,
          size: viewport.size,
          child: const SingleChildScrollView(
            child: ModWorkshopValidatorAndPackagerPanel(),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        'InGameDatabaseRosterEditorScreen supports adding rider, undo/redo and applying database',
        (tester) async {
      final team = _buildTestTeam(
        id: 'team_flow',
        name: 'Kraków Cycling',
        rosterIds: ['r_flow_1'],
      );
      final rider = _buildTestRider(id: 'r_flow_1', teamId: 'team_flow');

      List<CyclingTeam>? appliedTeams;
      List<Rider>? appliedRiders;

      await pumpResponsiveWidget(
        tester,
        size: const Size(1600, 900),
        child: InGameDatabaseRosterEditorScreen(
          initialTeams: [team],
          initialRiders: [rider],
          onApplyDatabase: (teams, riders) {
            appliedTeams = teams;
            appliedRiders = riders;
          },
        ),
      );

      expect(find.textContaining('1 drużyn • 1 kolarzy'), findsOneWidget);

      await tester.tap(find.text('+ Kolarz'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('1 drużyn • 2 kolarzy'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.undo_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('1 drużyn • 1 kolarzy'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.redo_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('1 drużyn • 2 kolarzy'), findsOneWidget);

      await tester.tap(find.text('Zastosuj Zmiany'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(appliedTeams, isNotNull);
      expect(appliedRiders, isNotNull);
      expect(appliedTeams!.length, 1);
      expect(appliedRiders!.length, 2);
      expect(tester.takeException(), isNull);
    });
  });
}
