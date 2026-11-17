import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/core/diagnostics/save_compatibility_v4_migrator.dart';
import 'package:pro_peloton_manager/models/career/pro_cyclist_career_state.dart';
import 'package:pro_peloton_manager/models/race/velodrome_track_and_hour_record_model.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';
import 'package:pro_peloton_manager/ui/screens/legends_card_album_and_packs_screen.dart';

Map<String, dynamic> _buildLegacyV1SavePayload() {
  final rider = RiderProceduralGenerator.generateRider(
    id: 'r1',
    nationalityIso: 'POL',
    age: 25,
    targetOverallRating: 78,
    teamId: 'team_pol',
  );
  return {
    'id': 'legacy_career_01',
    'saveName': 'Klasyczna Kariera v1',
    'createdAt': '2026-01-01T08:00:00.000Z',
    'lastSavedAt': '2026-03-10T18:00:00.000Z',
    'difficulty': 'normal',
    'playerManagerName': 'Jan Kowalski',
    'playerTeamId': 'team_pol',
    'currentDate': '2026-03-10T08:00:00.000Z',
    'currentSeasonYear': 2026,
    'calendar': {
      'seasonYear': 2026,
      'races': const [],
    },
    'teams': const [],
    'riders': [rider.toJson()],
  };
}

void main() {
  group('SaveCompatibilityV4Migrator', () {
    test('migrates legacy v1 save and initializes Paczka #4 structures', () {
      final legacyJson = jsonEncode(_buildLegacyV1SavePayload());

      final report = SaveCompatibilityV4Migrator.migrateRawJson(
        saveId: 'legacy_slot_1',
        rawJson: legacyJson,
        initializeProCyclistIfMissing: true,
      );

      expect(report.status.isSuccess, isTrue);
      expect(report.status, V4MigrationStatus.repairedAndMigrated);
      expect(report.sourceSchemaVersion, 1);
      expect(report.targetSchemaVersion, 4);
      expect(report.migratedEnvelope, isNotNull);
      expect(report.migratedEnvelope!.schemaVersion, 4);

      expect(report.hydratedProCyclistState, isNotNull);
      expect(
        report.hydratedProCyclistState!.careerTier,
        ProCyclistCareerTier.u23Continental,
      );

      expect(report.hydratedVelodromeModel, isNotNull);
      expect(
        report.hydratedVelodromeModel!.hourRecordHistory,
        isNotEmpty,
      );
      expect(
        report.hydratedVelodromeModel!.availableVelodromes.length,
        VelodromeTrackAndHourRecordModel.defaultVelodromes.length,
      );

      expect(report.hydratedCyclocrossCup, isNotNull);
      expect(report.hydratedCyclocrossCup!.seasonYear, 2026);
      expect(report.hydratedCyclocrossCup!.calendarRaceIds.length, 8);

      expect(report.hydratedLegendsAlbum, isNotNull);
      expect(
        report.hydratedLegendsAlbum!.totalCards,
        LegendsAlbumCatalog.buildDefaultEntries().length,
      );
      expect(report.hydratedLegendsAlbum!.unopenedPacks, isNotEmpty);
    });

    test('is idempotent when migrating already migrated v4 envelope', () {
      final firstReport = SaveCompatibilityV4Migrator.migrateRawJson(
        saveId: 'slot_idempotent',
        rawJson: jsonEncode(_buildLegacyV1SavePayload()),
        initializeProCyclistIfMissing: false,
      );

      expect(firstReport.migratedEnvelope, isNotNull);
      final v4Json = jsonEncode(firstReport.migratedEnvelope!.toJson());

      final secondReport = SaveCompatibilityV4Migrator.migrateRawJson(
        saveId: 'slot_idempotent',
        rawJson: v4Json,
        initializeProCyclistIfMissing: false,
      );

      expect(secondReport.status, V4MigrationStatus.alreadyCompatible);
      expect(secondReport.actions, isEmpty);
      expect(secondReport.checksumBefore, secondReport.checksumAfter);
    });

    test('repairs partial Paczka #4 fields and preserves existing player progress', () {
      final payload = _buildLegacyV1SavePayload();
      final defaultCards = LegendsAlbumCatalog.buildDefaultEntries();
      final firstUnlocked = defaultCards.first.copyWith(
        isUnlocked: true,
        duplicateCount: 2,
        isFavorite: true,
      );

      payload['proCyclistCareer'] = {
        'careerId': '',
        'dsTrustScore': 142.0,
        'skillPoints': -5,
        'privateBalanceEur': 10000,
      };
      payload['hourRecords'] = {
        'hourRecordHistory': [
          {
            'id': 'custom_hr_player',
            'riderName': 'Michał Nowak',
            'nationalityCode': 'POL',
            'category': 'menElite',
            'distanceKm': 57.150,
            'dateIso': '2026-10-01',
            'velodromeId': 'aguascalientes_bicentenario',
            'velodromeName': 'Velódromo Bicentenario Aguascalientes',
            'altitudeMeters': 1880.0,
            'chainringTeeth': 64,
            'cogTeeth': 14,
            'isCurrentWorldRecord': false,
          },
        ],
      };
      payload['cyclocrossCup'] = {
        'completedResults': [
          {
            'raceId': 'cx_gavere',
            'raceName': 'UCI World Cup Gavere',
            'riderId': 'r1',
            'riderName': 'Michał Nowak',
            'placement': 2,
            'totalTimeSeconds': 3615,
            'pitSwapsCount': 3,
            'bunnyHopsSucceeded': 6,
            'rimStrikeIncident': false,
            'pressureBarUsed': 1.45,
            'treadUsed': 'mudAggressive',
            'careerBonus': {
              'bikeHandlingGain': 2,
              'cobblesGain': 1,
              'watts1mGain': 8,
              'watts5mGain': 5,
              'ctlFitnessDelta': 2.5,
              'atlFatigueDelta': 4.0,
              'uciPointsEarned': 160,
            },
          },
        ],
      };
      payload['legendsCardAlbum'] = {
        'entries': [firstUnlocked.toJson()],
        'worldTourWinsCount': 4,
      };

      final report = SaveCompatibilityV4Migrator.migratePayloadMap(
        saveId: 'slot_partial_p4',
        payload: payload,
        sourceSchemaVersion: 3,
      );

      expect(report.status, V4MigrationStatus.repairedAndMigrated);
      expect(report.hydratedProCyclistState!.dsTrustScore, 100.0);
      expect(report.hydratedProCyclistState!.skillPoints, 0);

      final hrHistory = report.hydratedVelodromeModel!.hourRecordHistory;
      final playerHr =
          hrHistory.firstWhere((e) => e.id == 'custom_hr_player');
      expect(playerHr.isCurrentWorldRecord, isTrue);

      expect(report.hydratedCyclocrossCup!.completedResults.length, 1);
      expect(report.hydratedCyclocrossCup!.podiumsCount, 1);
      expect(report.hydratedCyclocrossCup!.totalCupPoints, 160);

      final album = report.hydratedLegendsAlbum!;
      expect(album.totalCards, defaultCards.length);
      final preserved =
          album.entries.firstWhere((e) => e.riderId == firstUnlocked.riderId);
      expect(preserved.isUnlocked, isTrue);
      expect(preserved.duplicateCount, 2);
      expect(preserved.isFavorite, isTrue);
    });

    test('returns failed report on empty or invalid JSON', () {
      final emptyReport = SaveCompatibilityV4Migrator.migrateRawJson(
        saveId: 'empty',
        rawJson: '   ',
      );
      expect(emptyReport.status, V4MigrationStatus.failed);
      expect(emptyReport.errorMessage, 'EMPTY_JSON_PAYLOAD');

      final invalidReport = SaveCompatibilityV4Migrator.migrateRawJson(
        saveId: 'bad',
        rawJson: '[1, 2, 3]',
      );
      expect(invalidReport.status, V4MigrationStatus.failed);
      expect(invalidReport.errorMessage, 'INVALID_JSON_ROOT');
    });
  });

  group('SaveCompatibilityV4MigratorPanel', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      Map<String, dynamic>? payload,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SaveCompatibilityV4MigratorPanel(
                  saveId: 'test_slot',
                  samplePayload: payload,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders and migrates cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await pumpPanelAtSize(
            tester,
            size,
            payload: _buildLegacyV1SavePayload(),
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Uruchom Migrację v4'), findsOneWidget);

          await tester.tap(find.text('Inicjalizuj Be a Pro jeśli brak'));
          await tester.pump(const Duration(milliseconds: 250));

          await tester.tap(find.text('Uruchom Migrację v4'));
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(
            find.textContaining('v3 -> v4'),
            findsOneWidget,
          );
          expect(
            find.text('Kariera Be a Pro (ProCyclistCareerState)'),
            findsOneWidget,
          );
          expect(
            find.text('Rekordy Godzinne UCI i Welodromy'),
            findsOneWidget,
          );
          expect(
            find.text('Zimowy Puchar Cyclo-Cross'),
            findsOneWidget,
          );
          expect(
            find.text('Kolekcja Kart Legend i Paczek'),
            findsOneWidget,
          );
        },
      );
    }

    testWidgets('disables run button when no sample payload is provided',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768), payload: null);

      await tester.tap(find.text('Uruchom Migrację v4'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.textContaining('Uruchom migrację v4, aby automatycznie'),
        findsOneWidget,
      );
    });
  });
}
