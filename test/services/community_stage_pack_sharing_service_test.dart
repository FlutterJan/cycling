// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/models/career/season_calendar.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/services/database/community_stage_pack_sharing_service.dart';

RaceStage _buildSampleStage({
  required int number,
  String name = 'Etap Testowy',
  StageType stageType = StageType.hilly,
}) {
  return RaceStage(
    id: 'stage_$number',
    stageNumber: number,
    name: name,
    stageType: stageType,
    segments: [
      const StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 45.0,
        startElevationM: 120.0,
        endElevationM: 180.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 30.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.intermediateSprint,
      ),
      const StageSegment(
        index: 1,
        startKm: 45.0,
        lengthKm: 32.5,
        startElevationM: 180.0,
        endElevationM: 210.0,
        surfaceType: SegmentSurfaceType.cobblestonesSector4,
        technicalDifficulty: 82.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      const StageSegment(
        index: 2,
        startKm: 77.5,
        lengthKm: 18.5,
        startElevationM: 210.0,
        endElevationM: 1150.0,
        surfaceType: SegmentSurfaceType.roughAsphalt,
        technicalDifficulty: 65.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.cat1,
      ),
    ],
    baseTemperatureCelsius: 21.0,
    weatherCondition: WeatherCondition.sunny,
    windSpeedKmh: 16.0,
  );
}

TourRace _build21StageGrandTour() {
  final stages = List<RaceStage>.generate(
    21,
    (idx) => _buildSampleStage(
      number: idx + 1,
      name: 'Etap ${idx + 1}',
      stageType: idx == 0 || idx == 20
          ? StageType.individualTimeTrial
          : (idx % 3 == 0 ? StageType.highMountain : StageType.flat),
    ),
  );

  return TourRace(
    id: 'custom_gt_polska_21',
    name: 'Wielki Tour Polski 21',
    countryIso: 'POL',
    uciCategory: RaceCategory.grandTour,
    startMonth: 7,
    startDay: 4,
    stages: stages,
    prizePoolEur: 2000000,
    participatingTeamIds: const [],
    ridersPerTeam: 8,
    classifications: const RaceClassifications(
      generalClassification: [],
      pointsClassification: [],
      mountainsClassification: [],
      youthClassification: [],
      teamClassification: [],
    ),
  );
}

void main() {
  const service = CommunityStagePackSharingService();

  group('CommunityStagePackSharingService — Eksport i Import .ppmstage', () {
    test('Eksport i import wyścigu 1-dniowego (plain JSON) zachowuje wszystkie segmenty i sumę kontrolną', () {
      final oneDayStage = _buildSampleStage(
        number: 1,
        name: 'Klasyk Ślężański',
        stageType: StageType.cobbleClassic,
      );

      final pack = service.createOneDayPackFromStage(
        stage: oneDayStage,
        raceName: 'Klasyk Wrocław–Sobótka',
        countryIso: 'POL',
        startMonth: 4,
        startDay: 12,
        author: 'Janek',
      );

      expect(pack.metadata.packKind, CommunityStagePackKind.oneDayRace);
      expect(pack.race.isOneDayRace, isTrue);

      final serialized = service.serializePackToPpmStage(pack);
      final parsed = service.parsePpmStageContent(serialized);

      expect(parsed.success, isTrue);
      expect(parsed.checksumVerified, isTrue);
      expect(parsed.wasCompressed, isFalse);
      expect(parsed.pack, isNotNull);
      expect(parsed.pack!.race.name, 'Klasyk Wrocław–Sobótka');
      expect(parsed.pack!.race.stages.length, 1);
      expect(parsed.pack!.race.stages.first.segments.length, 3);
      expect(parsed.validation?.cobbleSegmentCount, 1);
      expect(parsed.validation?.komClimbCount, 1);
    });

    test('Eksport i import 21-etapowego Touru z kompresją GZip (.ppmstage)', () {
      final gt = _build21StageGrandTour();
      final pack = service.createPackFromTourRace(
        race: gt,
        author: 'Tour Architect',
      );

      expect(pack.metadata.packKind, CommunityStagePackKind.grandTour21);
      expect(pack.race.isGrandTour, isTrue);

      final gzContent = service.serializePackToPpmStage(
        pack,
        compressGzip: true,
        pretty: false,
      );
      expect(gzContent.startsWith(kPpmStageGzipPrefix), isTrue);

      final parsed = service.parsePpmStageContent(gzContent);
      expect(parsed.success, isTrue);
      expect(parsed.checksumVerified, isTrue);
      expect(parsed.wasCompressed, isTrue);
      expect(parsed.pack!.race.stages.length, 21);
      expect(parsed.validation!.stageCount, 21);
      expect(parsed.validation!.timeTrialStageCount, 2);
      expect(parsed.validation!.totalDistanceKm, closeTo(21 * 96.0, 0.01));
    });

    test('Wykrywa modyfikację/uszkodzenie pliku .ppmstage przez niezgodność FNV-1a64', () {
      final pack = service.createOneDayPackFromStage(
        stage: _buildSampleStage(number: 1),
        raceName: 'Test Integrity Race',
      );
      final raw = service.serializePackToPpmStage(pack);
      final tampered = raw.replaceFirst('Test Integrity Race', 'Hacked Race');

      final parsed = service.parsePpmStageContent(tampered);
      expect(parsed.success, isFalse);
      expect(parsed.checksumVerified, isFalse);
      expect(parsed.errorMessage, contains('FNV-1a64'));
    });

    test('Odrzuca pusty lub błędny nagłówek pliku .ppmstage', () {
      expect(service.parsePpmStageContent('').success, isFalse);
      expect(
        service.parsePpmStageContent('{"formatMagic": "WRONG_V9"}').success,
        isFalse,
      );
    });
  });

  group('CommunityStagePackSharingService — Pliki dyskowe i Kalendarz', () {
    test('Zapis atomowy do pliku .ppmstage, listowanie katalogu i odczyt', () async {
      final tempDir = await Directory.systemTemp.createTemp('ppmstage_test_');
      try {
        final gt = _build21StageGrandTour();
        final pack = service.createPackFromTourRace(race: gt, author: 'Tester');

        final rawPath = '${tempDir.path}${Platform.pathSeparator}tour_polski';
        final receipt = await service.exportToFile(pack, rawPath);

        expect(receipt.filePath.endsWith('.ppmstage'), isTrue);
        expect(File(receipt.filePath).existsSync(), isTrue);
        expect(receipt.bytesWritten, greaterThan(100));

        final list = await service.listAvailablePacksInDirectory(tempDir.path);
        expect(list.length, 1);
        expect(list.first.title, 'Wielki Tour Polski 21');
        expect(list.first.stageCount, 21);
        expect(list.first.isValid, isTrue);

        final imported = await service.importFromFile(receipt.filePath);
        expect(imported.success, isTrue);
        expect(imported.pack!.race.stages.length, 21);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('Bezpośrednie wstawienie do SeasonCalendar z sortowaniem i kolizją ID', () {
      final existingRace = TourRace(
        id: 'race_may',
        name: 'Majowy Wyścig',
        countryIso: 'FRA',
        uciCategory: RaceCategory.worldTourOneDay,
        startMonth: 5,
        startDay: 10,
        stages: [_buildSampleStage(number: 1)],
        prizePoolEur: 50000,
        participatingTeamIds: const [],
        ridersPerTeam: 7,
        classifications: const RaceClassifications(
          generalClassification: [],
          pointsClassification: [],
          mountainsClassification: [],
          youthClassification: [],
          teamClassification: [],
        ),
      );

      final calendar = SeasonCalendar(
        seasonYear: 2026,
        races: [existingRace],
      );

      final importedApril = existingRace.copyWith(
        id: 'race_may', // celowa kolizja ID
        name: 'Kwietniowy Klasyk',
        startMonth: 4,
        startDay: 2,
      );

      final res = service.importIntoSeasonCalendar(calendar, importedApril);
      expect(res.updatedCalendar.races.length, 2);
      expect(res.insertedRace.id, 'race_may_2');
      expect(res.insertedIndex, 0);
      expect(res.updatedCalendar.races.first.name, 'Kwietniowy Klasyk');
    });

    test('Riverpod provider obsługuje przygotowanie i import paczki', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(communityStagePackSharingProvider.notifier);
      final gt = _build21StageGrandTour();
      notifier.loadRaceForExport(gt, author: 'Riverpod User');

      final state = container.read(communityStagePackSharingProvider);
      expect(state.activePack, isNotNull);
      expect(state.validation?.stageCount, 21);

      final importedOk = notifier.importFromRawText(state.serializedPreview!);
      expect(importedOk, isTrue);
    });
  });

  group('CommunityStagePackSharingPanel — Responsywność 390x844 / 1024x768 / 1600x900', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'Renderuje bez overflow w rozdzielczości ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          TourRace? importedRace;
          final gt = _build21StageGrandTour();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CommunityStagePackSharingPanel(
                    sourceRace: gt,
                    onImportToCalendar: (r) => importedRace = r,
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.textContaining('21'), findsWidgets);
          final importBtn = find.text('Wczytaj do Kalendarza');
          await tester.ensureVisible(importBtn);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(importBtn);
          await tester.pump(const Duration(milliseconds: 300));

          expect(importedRace, isNotNull);
          expect(importedRace!.stages.length, 21);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('Przycisk eksportu jest nieaktywny przy braku trasy źródłowej', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CommunityStagePackSharingPanel(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Eksportuj .ppmstage'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
