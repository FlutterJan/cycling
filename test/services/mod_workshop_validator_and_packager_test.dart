import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/database/custom_mod_importer_service.dart';
import 'package:pro_peloton_manager/services/database/mod_workshop_validator_and_packager.dart';

void main() {
  const packager = ModWorkshopValidatorAndPackager();

  group('ModWorkshopValidatorAndPackager unit tests', () {
    test('starter template validates cleanly and round-trips through JSON', () {
      final starter = packager.createStarterTemplatePackage();
      final report = packager.validatePackage(starter);

      expect(report.isValid, isTrue);
      expect(report.errors, isEmpty);
      expect(report.readinessScore, greaterThanOrEqualTo(90));
      expect(report.teamsCount, 1);
      expect(report.ridersCount, 1);
      expect(report.racesCount, 1);
      expect(report.brandsCount, 1);

      final decoded = PpmModPackage.fromJson(
        jsonDecode(jsonEncode(starter.toJson())) as Map<String, dynamic>,
      );
      expect(decoded.manifest.modId, starter.manifest.modId);
      expect(decoded.customModPackage?.riders.first.fullName, 'Jan Kowalski');
    });

    test('detects invalid manifest, duplicate IDs, bad HEX/ISO and unsafe asset path', () {
      final invalidPackage = PpmModPackage(
        manifest: PpmModManifest(
          modId: 'x',
          title: 'AB',
          author: '',
          version: 'v1',
          description: 'Short',
          contentType: PpmModContentType.databaseAndRoster,
          createdAt: DateTime.utc(2026),
        ),
        customModPackage: CustomModPackage(
          metadata: CustomModMetadata(
            id: 'x',
            name: 'AB',
            version: 'v1',
            author: '',
            description: 'Short',
            createdDate: DateTime.utc(2026),
          ),
          teams: const [
            TeamModEntry(
              matchId: 'dup_team',
              name: 'Team A',
              countryIso: 'PL',
              primaryJerseyColorHex: 'NOT_HEX',
              secondaryJerseyColorHex: '#FFFFFF',
              accentJerseyColorHex: '#8E4A49',
            ),
            TeamModEntry(
              matchId: 'dup_team',
              name: 'Team B',
              countryIso: 'FRA',
              primaryJerseyColorHex: '#0F1115',
              secondaryJerseyColorHex: '#FFFFFF',
              accentJerseyColorHex: '#D4AF37',
            ),
          ],
          riders: const [
            RiderModEntry(
              matchId: 'r1',
              firstName: 'Adam',
              lastName: 'Nowak',
              nationalityIso: 'POL',
              targetOverallRating: 105,
            ),
          ],
        ),
        assets: const [
          PpmModAssetEntry(
            relativePath: '../escape.png',
            assetKind: PpmModAssetKind.jerseyTexture,
            byteSize: 128,
            fnv1a64Checksum: '0000000000000000',
          ),
        ],
      );

      final report = packager.validatePackage(invalidPackage);
      expect(report.isValid, isFalse);
      expect(report.duplicateIdsDetected, 1);
      expect(report.invalidColorsDetected, 1);
      expect(report.invalidIsoCodesDetected, 1);
      expect(
        report.errors.map((e) => e.code),
        containsAll([
          'INVALID_MOD_ID',
          'EMPTY_MOD_TITLE',
          'EMPTY_MOD_AUTHOR',
          'INVALID_SEMVER',
          'DUPLICATE_TEAM_ID',
          'INVALID_TEAM_ISO',
          'INVALID_TEAM_HEX',
          'RIDER_OVR_OUT_OF_RANGE',
          'UNSAFE_ASSET_PATH',
        ]),
      );
    });

    test('encodes and decodes .ppmmod in GZip and plain JSON, rejecting tampered checksum', () {
      final starter = packager.createStarterTemplatePackage();

      final gzEncoded = packager.encodeToPpmModString(
        starter,
        compression: PpmModExportCompression.gzipBase64,
      );
      expect(gzEncoded.startsWith(kPpmModGzipPrefix), isTrue);

      final gzDecoded = packager.decodeFromPpmModString(gzEncoded);
      expect(gzDecoded.wasCompressed, isTrue);
      expect(gzDecoded.checksumVerified, isTrue);
      expect(gzDecoded.validationReport.isValid, isTrue);

      final jsonEncoded = packager.encodeToPpmModString(
        starter,
        compression: PpmModExportCompression.plainJson,
      );
      final jsonDecoded = packager.decodeFromPpmModString(jsonEncoded);
      expect(jsonDecoded.wasCompressed, isFalse);
      expect(jsonDecoded.checksumVerified, isTrue);

      final tampered = jsonEncoded.replaceFirst(
        'Pro Peloton Community Starter Pack',
        'Tampered Pack Title',
      );
      expect(
        () => packager.decodeFromPpmModString(tampered),
        throwsFormatException,
      );
    });

    test('exports atomically to disk and imports back with FNV-1a64 verification', () async {
      final tempDir = await Directory.systemTemp.createTemp('ppmmod_test_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final starter = packager.createStarterTemplatePackage();
      final outPath = '${tempDir.path}${Platform.pathSeparator}community_pack';
      final receipt = await packager.exportToFile(starter, outPath);

      expect(receipt.filePath.endsWith(kPpmModFileExtension), isTrue);
      expect(await File(receipt.filePath).exists(), isTrue);
      expect(receipt.checksumFnv1a64.length, 16);
      expect(receipt.validationReport.isValid, isTrue);

      final imported = await packager.importFromFile(receipt.filePath);
      expect(imported.checksumVerified, isTrue);
      expect(imported.package.manifest.modId, starter.manifest.modId);

      final emptyInvalid = PpmModPackage(
        manifest: PpmModManifest(
          modId: 'empty_mod',
          title: 'Empty Mod',
          author: 'Tester',
          version: '1.0.0',
          description: 'Valid description length here.',
          contentType: PpmModContentType.totalConversion,
          createdAt: DateTime.utc(2026),
        ),
      );
      await expectLater(
        packager.exportToFile(emptyInvalid, '${tempDir.path}/bad.ppmmod'),
        throwsStateError,
      );
    });

    test('notifier updates contentType, compression, and issue filter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(modWorkshopPackagerProvider.notifier);
      notifier.updateContentType(PpmModContentType.totalConversion);
      notifier.setCompression(PpmModExportCompression.plainJson);
      notifier.setIssueFilter(PpmModValidationSeverity.error);

      final state = container.read(modWorkshopPackagerProvider);
      expect(
        state.activePackage.manifest.contentType,
        PpmModContentType.totalConversion,
      );
      expect(state.compression, PpmModExportCompression.plainJson);
      expect(state.issueFilter, PpmModValidationSeverity.error);
    });
  });

  group('ModWorkshopValidatorAndPackagerPanel responsive widget tests', () {
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

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: ModWorkshopValidatorAndPackagerPanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Workshop .ppmmod Validator & Packager'), findsOneWidget);
          expect(find.text('Waliduj Paczkę'), findsOneWidget);
          expect(find.text('Eksportuj .ppmmod'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('supports interactive filter chips and read-only disabled state', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ModWorkshopValidatorAndPackagerPanel(isReadOnly: false),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('JSON (.ppmmod)'));
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Waliduj Paczkę'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.textContaining('Walidacja zakończona sukcesem'), findsOneWidget);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ModWorkshopValidatorAndPackagerPanel(isReadOnly: true),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);
    });
  });
}
