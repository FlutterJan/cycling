import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_replay_recorder.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/services/database/community_stage_pack_sharing_service.dart';
import 'package:pro_peloton_manager/services/export/gpx_and_tcx_telemetry_exporter.dart';

/// Wynik ścisłej walidacji składniowej dokumentu XML.
class _XmlSyntaxCheckResult {
  final bool isWellFormed;
  final String? rootTag;
  final int elementCount;
  final List<String> errors;

  const _XmlSyntaxCheckResult({
    required this.isWellFormed,
    required this.rootTag,
    required this.elementCount,
    required this.errors,
  });
}

/// Ścisły walidator składni XML (prolog, zbalansowanie tagów, atrybuty w cudzysłowach,
/// brak niezescapowanych znaków `<` lub `&` w treści i atrybutach, pojedynczy element główny).
_XmlSyntaxCheckResult _verifyStrictXmlSyntax(String xml) {
  final errors = <String>[];
  final trimmed = xml.trim();
  if (trimmed.isEmpty) {
    return const _XmlSyntaxCheckResult(
      isWellFormed: false,
      rootTag: null,
      elementCount: 0,
      errors: ['Dokument XML jest pusty.'],
    );
  }

  int pos = 0;
  if (trimmed.startsWith('<?xml')) {
    final declEnd = trimmed.indexOf('?>', 5);
    if (declEnd == -1) {
      return const _XmlSyntaxCheckResult(
        isWellFormed: false,
        rootTag: null,
        elementCount: 0,
        errors: ['Niezamknięta deklaracja <?xml ... ?>.'],
      );
    }
    pos = declEnd + 2;
  } else {
    errors.add('Brak deklaracji <?xml ... ?> na początku dokumentu.');
  }

  final stack = <String>[];
  String? rootTag;
  int rootCount = 0;
  int elementCount = 0;

  bool isWhitespace(int codeUnit) =>
      codeUnit == 0x20 || codeUnit == 0x09 || codeUnit == 0x0A || codeUnit == 0x0D;

  bool isNameChar(int codeUnit) {
    return (codeUnit >= 0x41 && codeUnit <= 0x5A) || // A-Z
        (codeUnit >= 0x61 && codeUnit <= 0x7A) || // a-z
        (codeUnit >= 0x30 && codeUnit <= 0x39) || // 0-9
        codeUnit == 0x5F || // _
        codeUnit == 0x2D || // -
        codeUnit == 0x2E || // .
        codeUnit == 0x3A; // :
  }

  final entityPattern = RegExp(r'^&(amp|lt|gt|quot|apos|#\d+|#x[0-9a-fA-F]+);');

  void validateEntities(String text, String contextLabel) {
    int ampIdx = text.indexOf('&');
    while (ampIdx != -1) {
      final slice = text.substring(ampIdx);
      if (!entityPattern.hasMatch(slice)) {
        errors.add('Niezescapowany znak "&" w $contextLabel.');
        break;
      }
      ampIdx = text.indexOf('&', ampIdx + 1);
    }
  }

  while (pos < trimmed.length) {
    final nextLt = trimmed.indexOf('<', pos);
    if (nextLt == -1) {
      final trailing = trimmed.substring(pos).trim();
      if (trailing.isNotEmpty) {
        errors.add('Nadmiarowy tekst poza elementem głównym: "$trailing".');
      }
      break;
    }

    if (nextLt > pos) {
      final textNode = trimmed.substring(pos, nextLt);
      if (stack.isEmpty) {
        if (textNode.trim().isNotEmpty) {
          errors.add('Tekst poza elementem głównym: "${textNode.trim()}".');
        }
      } else {
        if (textNode.contains('>')) {
          errors.add('Niezescapowany znak ">" w treści elementu <${stack.last}>.');
        }
        validateEntities(textNode, 'treści elementu <${stack.last}>');
      }
    }

    if (trimmed.startsWith('<!--', nextLt)) {
      final commentEnd = trimmed.indexOf('-->', nextLt + 4);
      if (commentEnd == -1) {
        errors.add('Niezamknięty komentarz XML.');
        break;
      }
      pos = commentEnd + 3;
      continue;
    }

    final tagEnd = trimmed.indexOf('>', nextLt + 1);
    if (tagEnd == -1) {
      errors.add('Niezamknięty nawias tagu "<" na pozycji $nextLt.');
      break;
    }

    final rawInside = trimmed.substring(nextLt + 1, tagEnd);
    if (rawInside.contains('<')) {
      errors.add('Nielegalny znak "<" wewnątrz tagu.');
      pos = tagEnd + 1;
      continue;
    }

    final inside = rawInside.trim();
    if (inside.isEmpty) {
      errors.add('Pusty tag "<>" na pozycji $nextLt.');
      pos = tagEnd + 1;
      continue;
    }

    if (inside.startsWith('/')) {
      final closeName = inside.substring(1).trim();
      if (stack.isEmpty) {
        errors.add('Nadmiarowy tag zamykający </$closeName>.');
      } else if (stack.last != closeName) {
        errors.add(
          'Niezgodny tag zamykający </$closeName> (oczekiwano </${stack.last}>).',
        );
      } else {
        stack.removeLast();
      }
      pos = tagEnd + 1;
      continue;
    }

    final bool selfClosing = inside.endsWith('/');
    final String header =
        selfClosing ? inside.substring(0, inside.length - 1).trimRight() : inside;

    int nameEnd = 0;
    while (nameEnd < header.length && isNameChar(header.codeUnitAt(nameEnd))) {
      nameEnd++;
    }
    if (nameEnd == 0) {
      errors.add('Nieprawidłowa nazwa tagu w "<$inside>".');
      pos = tagEnd + 1;
      continue;
    }

    final tagName = header.substring(0, nameEnd);
    elementCount++;
    if (stack.isEmpty) {
      rootCount++;
      rootTag ??= tagName;
      if (rootCount > 1) {
        errors.add('Wykryto więcej niż jeden element główny ($tagName).');
      }
    }

    // Walidacja atrybutów w nagłówku tagu
    int attrPos = nameEnd;
    while (attrPos < header.length) {
      while (attrPos < header.length && isWhitespace(header.codeUnitAt(attrPos))) {
        attrPos++;
      }
      if (attrPos >= header.length) break;

      final attrNameStart = attrPos;
      while (attrPos < header.length && isNameChar(header.codeUnitAt(attrPos))) {
        attrPos++;
      }
      if (attrPos == attrNameStart) {
        errors.add('Nieprawidłowy atrybut w tagu <$tagName>.');
        break;
      }
      final attrName = header.substring(attrNameStart, attrPos);
      while (attrPos < header.length && isWhitespace(header.codeUnitAt(attrPos))) {
        attrPos++;
      }
      if (attrPos >= header.length || header[attrPos] != '=') {
        errors.add('Brak znaku "=" dla atrybutu $attrName w <$tagName>.');
        break;
      }
      attrPos++;
      while (attrPos < header.length && isWhitespace(header.codeUnitAt(attrPos))) {
        attrPos++;
      }
      if (attrPos >= header.length ||
          (header[attrPos] != '"' && header[attrPos] != '\'')) {
        errors.add('Wartość atrybutu $attrName w <$tagName> nie jest w cudzysłowie.');
        break;
      }
      final quote = header[attrPos];
      attrPos++;
      final valStart = attrPos;
      final valEnd = header.indexOf(quote, valStart);
      if (valEnd == -1) {
        errors.add('Niezamknięta wartość atrybutu $attrName w <$tagName>.');
        break;
      }
      final attrVal = header.substring(valStart, valEnd);
      validateEntities(attrVal, 'atrybucie $attrName tagu <$tagName>');
      attrPos = valEnd + 1;
    }

    if (!selfClosing) {
      stack.add(tagName);
    }
    pos = tagEnd + 1;
  }

  if (stack.isNotEmpty) {
    errors.add('Niezamknięte tagi XML: ${stack.join(', ')}.');
  }
  if (rootCount == 0) {
    errors.add('Brak elementu głównego XML.');
  }

  return _XmlSyntaxCheckResult(
    isWellFormed: errors.isEmpty,
    rootTag: rootTag,
    elementCount: elementCount,
    errors: errors,
  );
}

TelemetryExportSession _buildExportSession({
  String stageName = 'Etap 18: Col du Galibier & Alpe d\'Huez <HC>',
  String riderName = 'Rafał "Krakus" Majka & Co.',
  String teamName = 'Apex & Visma <WorldTour>',
  int sampleCount = 30,
}) {
  final samples = <TelemetryExportSample>[];
  double lat = 45.0558;
  double lon = 6.0289;
  double dist = 0.0;
  double ele = 850.0;

  for (int i = 0; i < sampleCount; i++) {
    final speed = 7.8 + (i % 6) * 0.25;
    dist += speed;
    ele += 0.52;
    lat += 0.00005;
    lon += 0.00003;
    samples.add(
      TelemetryExportSample(
        elapsedSeconds: i.toDouble(),
        latitude: lat,
        longitude: lon,
        elevationMeters: ele,
        distanceMeters: dist,
        speedMs: speed,
        powerWatts: 335 + (i % 5) * 18,
        heartRateBpm: 164 + (i % 7),
        cadenceRpm: 84 + (i % 6),
        temperatureCelsius: 17.5 - i * 0.03,
      ),
    );
  }

  return TelemetryExportSession(
    stageId: 'stage_18_galibier',
    stageName: stageName,
    riderName: riderName,
    teamName: teamName,
    riderWeightKg: 64.0,
    startTimeUtc: DateTime.utc(2026, 7, 23, 13, 15, 0),
    samples: samples,
  );
}

RaceStage _buildComplexStage({
  required String id,
  required int stageNumber,
  required String name,
  StageType stageType = StageType.cobbleClassic,
  WeatherCondition weather = WeatherCondition.lightRain,
}) {
  return RaceStage(
    id: id,
    stageNumber: stageNumber,
    name: name,
    stageType: stageType,
    baseTemperatureCelsius: 14.5,
    weatherCondition: weather,
    windSpeedKmh: 28.5,
    segments: [
      const StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 42.5,
        startElevationM: 45.0,
        endElevationM: 82.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 18.0,
        windDirectionDegrees: 245.0,
        roadBearingDegrees: 35.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      const StageSegment(
        index: 1,
        startKm: 42.5,
        lengthKm: 3.7,
        startElevationM: 82.0,
        endElevationM: 94.0,
        surfaceType: SegmentSurfaceType.cobblestonesSector5,
        technicalDifficulty: 95.0,
        windDirectionDegrees: 260.0,
        roadBearingDegrees: 15.0,
        sprintOrKomClassification: SegmentClassification.intermediateSprint,
      ),
      const StageSegment(
        index: 2,
        startKm: 46.2,
        lengthKm: 16.8,
        startElevationM: 94.0,
        endElevationM: 1210.0,
        surfaceType: SegmentSurfaceType.roughAsphalt,
        technicalDifficulty: 64.0,
        windDirectionDegrees: 190.0,
        roadBearingDegrees: 112.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      ),
      const StageSegment(
        index: 3,
        startKm: 63.0,
        lengthKm: 12.0,
        startElevationM: 1210.0,
        endElevationM: 540.0,
        surfaceType: SegmentSurfaceType.gravelStrade,
        technicalDifficulty: 72.0,
        windDirectionDegrees: 130.0,
        roadBearingDegrees: 210.0,
        sprintOrKomClassification: SegmentClassification.finishLine,
      ),
    ],
  );
}

void _expectStagesEqual(RaceStage actual, RaceStage expected) {
  expect(actual.id, expected.id);
  expect(actual.stageNumber, expected.stageNumber);
  expect(actual.name, expected.name);
  expect(actual.stageType, expected.stageType);
  expect(actual.baseTemperatureCelsius, closeTo(expected.baseTemperatureCelsius, 1e-9));
  expect(actual.weatherCondition, expected.weatherCondition);
  expect(actual.windSpeedKmh, closeTo(expected.windSpeedKmh, 1e-9));
  expect(actual.segments.length, expected.segments.length);

  for (int i = 0; i < expected.segments.length; i++) {
    final a = actual.segments[i];
    final e = expected.segments[i];
    expect(a.index, e.index);
    expect(a.startKm, closeTo(e.startKm, 1e-9));
    expect(a.lengthKm, closeTo(e.lengthKm, 1e-9));
    expect(a.startElevationM, closeTo(e.startElevationM, 1e-9));
    expect(a.endElevationM, closeTo(e.endElevationM, 1e-9));
    expect(a.surfaceType, e.surfaceType);
    expect(a.technicalDifficulty, closeTo(e.technicalDifficulty, 1e-9));
    expect(a.windDirectionDegrees, closeTo(e.windDirectionDegrees, 1e-9));
    expect(a.roadBearingDegrees, closeTo(e.roadBearingDegrees, 1e-9));
    expect(a.sprintOrKomClassification, e.sprintOrKomClassification);
  }
}

void _expectPacksLosslessEqual(
  CommunityStagePack actual,
  CommunityStagePack expected,
) {
  expect(actual.formatMagic, expected.formatMagic);
  expect(actual.schemaVersion, expected.schemaVersion);
  expect(actual.checksumFnv1a64, expected.checksumFnv1a64);

  expect(actual.metadata.packId, expected.metadata.packId);
  expect(actual.metadata.title, expected.metadata.title);
  expect(actual.metadata.author, expected.metadata.author);
  expect(actual.metadata.description, expected.metadata.description);
  expect(actual.metadata.version, expected.metadata.version);
  expect(
    actual.metadata.createdAt.toUtc().toIso8601String(),
    expected.metadata.createdAt.toUtc().toIso8601String(),
  );
  expect(actual.metadata.packKind, expected.metadata.packKind);
  expect(actual.metadata.tags, expected.metadata.tags);

  expect(actual.race.id, expected.race.id);
  expect(actual.race.name, expected.race.name);
  expect(actual.race.countryIso, expected.race.countryIso);
  expect(actual.race.uciCategory, expected.race.uciCategory);
  expect(actual.race.startMonth, expected.race.startMonth);
  expect(actual.race.startDay, expected.race.startDay);
  expect(actual.race.prizePoolEur, expected.race.prizePoolEur);
  expect(actual.race.ridersPerTeam, expected.race.ridersPerTeam);
  expect(actual.race.stages.length, expected.race.stages.length);

  for (int i = 0; i < expected.race.stages.length; i++) {
    _expectStagesEqual(actual.race.stages[i], expected.race.stages[i]);
  }
}

void main() {
  const exporter = GpxAndTcxTelemetryExporter();
  const sharingService = CommunityStagePackSharingService();

  group('Poprawność składni XML wyeksportowanych plików .tcx i .gpx', () {
    test('wyeksportowany plik .tcx przechodzi ścisłą walidację składni XML oraz walidację TCX v2', () async {
      final session = _buildExportSession(sampleCount: 45);
      final tempDir = await Directory.systemTemp.createTemp('ppm_tcx_syntax_test_');
      try {
        final file = await exporter.exportToFile(
          session: session,
          format: TelemetryExportFormat.tcx,
          targetDirectory: tempDir,
        );
        expect(await file.exists(), isTrue);
        expect(file.path.toLowerCase(), endsWith('.tcx'));

        final xmlContent = await file.readAsString();
        final syntaxCheck = _verifyStrictXmlSyntax(xmlContent);
        expect(
          syntaxCheck.isWellFormed,
          isTrue,
          reason: 'Błędy XML TCX: ${syntaxCheck.errors.join('; ')}',
        );
        expect(syntaxCheck.rootTag, 'TrainingCenterDatabase');
        expect(syntaxCheck.elementCount, greaterThan(45 * 8));

        final schemaReport = exporter.validateExportedXml(
          xmlContent,
          TelemetryExportFormat.tcx,
        );
        expect(schemaReport.isValid, isTrue, reason: schemaReport.errors.join('; '));
        expect(schemaReport.detectedTrackpoints, 45);
        expect(schemaReport.hasPowerData, isTrue);
        expect(schemaReport.hasHeartRateData, isTrue);
        expect(schemaReport.hasCadenceData, isTrue);
        expect(schemaReport.hasElevationData, isTrue);
        expect(schemaReport.hasMonotonicTimestamps, isTrue);

        // Weryfikacja escapowania znaków specjalnych w elementach tekstowych XML
        expect(xmlContent, contains('&amp;'));
        expect(xmlContent, contains('&lt;HC&gt;'));
        expect(xmlContent, contains('&quot;Krakus&quot;'));
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('wyeksportowany plik .gpx przechodzi ścisłą walidację składni XML oraz walidację GPX 1.1', () async {
      final session = _buildExportSession(sampleCount: 45);
      final tempDir = await Directory.systemTemp.createTemp('ppm_gpx_syntax_test_');
      try {
        final file = await exporter.exportToFile(
          session: session,
          format: TelemetryExportFormat.gpx,
          targetDirectory: tempDir,
        );
        expect(await file.exists(), isTrue);
        expect(file.path.toLowerCase(), endsWith('.gpx'));

        final xmlContent = await file.readAsString();
        final syntaxCheck = _verifyStrictXmlSyntax(xmlContent);
        expect(
          syntaxCheck.isWellFormed,
          isTrue,
          reason: 'Błędy XML GPX: ${syntaxCheck.errors.join('; ')}',
        );
        expect(syntaxCheck.rootTag, 'gpx');
        expect(syntaxCheck.elementCount, greaterThan(45 * 6));

        final schemaReport = exporter.validateExportedXml(
          xmlContent,
          TelemetryExportFormat.gpx,
        );
        expect(schemaReport.isValid, isTrue, reason: schemaReport.errors.join('; '));
        expect(schemaReport.detectedTrackpoints, 45);
        expect(schemaReport.hasPowerData, isTrue);
        expect(schemaReport.hasHeartRateData, isTrue);
        expect(schemaReport.hasCadenceData, isTrue);
        expect(schemaReport.hasElevationData, isTrue);
        expect(schemaReport.hasMonotonicTimestamps, isTrue);

        expect(xmlContent, contains('xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1"'));
        expect(xmlContent, contains('<gpxtpx:atemp>'));
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('konwersja ze StageReplayRecorder (RiderTelemetryTrackPoint) produkuje poprawny XML w obu formatach', () {
      final stage = _buildComplexStage(
        id: 'replay_stage',
        stageNumber: 1,
        name: 'Strade & Roubaix <Test>',
      );
      final trackPoints = List<RiderTelemetryTrackPoint>.generate(
        20,
        (i) => RiderTelemetryTrackPoint(
          timestampSeconds: i * 1.5,
          distanceMeters: i * 16.5,
          elevationMeters: 120.0 + i * 0.9,
          gradientPercent: 5.4,
          speedMs: 11.0,
          powerWatts: 375 + i * 3,
          heartRateBpm: 158 + (i % 8),
          cadenceRpm: 92,
          wPrimeJoules: 16500.0 - i * 120.0,
          wPrimePercentage: (16500.0 - i * 120.0) / 20000.0,
          glycogenGrams: 380.0 - i * 0.5,
          isDrafting: true,
          draftingSavingsPercent: 32.0,
          activeTacticalOrder: TacticalOrder.holdPosition,
          lateralPositionRoad: (i % 3 - 1) * 0.4,
        ),
      );

      final session = GpxAndTcxTelemetryExporter.fromStageReplayTrackPoints(
        stage: stage,
        riderName: 'Michał Kwiatkowski',
        teamName: 'Team Polska',
        riderWeightKg: 68.0,
        trackPoints: trackPoints,
        originPreset: GpsOriginPreset.siena,
      );

      final tcx = exporter.export(
        session: session,
        format: TelemetryExportFormat.tcx,
        resampleOneSecond: true,
      );
      final gpx = exporter.export(
        session: session,
        format: TelemetryExportFormat.gpx,
        resampleOneSecond: true,
      );

      expect(_verifyStrictXmlSyntax(tcx.xmlContent).isWellFormed, isTrue);
      expect(_verifyStrictXmlSyntax(gpx.xmlContent).isWellFormed, isTrue);
      expect(
        exporter.validateExportedXml(tcx.xmlContent, TelemetryExportFormat.tcx).isValid,
        isTrue,
      );
      expect(
        exporter.validateExportedXml(gpx.xmlContent, TelemetryExportFormat.gpx).isValid,
        isTrue,
      );
    });
  });

  group('Bezstratny zapis i odczyt pliku trasy .ppmstage', () {
    test('bezstratny zapis i odczyt wyścigu jednodniowego .ppmstage (nieskompresowany JSON)', () async {
      final stage = _buildComplexStage(
        id: 'monument_poland_1d',
        stageNumber: 1,
        name: 'Kraków – Zakopane Klasyk Górski',
        stageType: StageType.cobbleClassic,
        weather: WeatherCondition.crosswindGale,
      );
      final originalPack = sharingService.createOneDayPackFromStage(
        stage: stage,
        raceName: 'Memoriał Tatrzański 2026',
        countryIso: 'POL',
        uciCategory: RaceCategory.monument,
        startMonth: 4,
        startDay: 19,
        prizePoolEur: 145000,
        author: 'Janek Studio',
        description: 'Trasa z brukiem 5★, podjazdem HC oraz odcinkiem szutrowym.',
        tags: const ['monument', 'bruk', 'góry', 'POL'],
      );

      final tempDir = await Directory.systemTemp.createTemp('ppm_stage_json_test_');
      try {
        final targetPath = '${tempDir.path}${Platform.pathSeparator}memorial_tatrzanski';
        final receipt = await sharingService.exportToFile(
          originalPack,
          targetPath,
          compressGzip: false,
        );

        expect(receipt.filePath, endsWith(kPpmStageFileExtension));
        expect(receipt.compressed, isFalse);
        expect(receipt.bytesWritten, greaterThan(100));
        expect(receipt.validation.isValid, isTrue);

        final parsed = await sharingService.importFromFile(receipt.filePath);
        expect(parsed.success, isTrue, reason: parsed.errorMessage);
        expect(parsed.checksumVerified, isTrue);
        expect(parsed.wasCompressed, isFalse);
        expect(parsed.validation?.isValid, isTrue);
        expect(parsed.pack, isNotNull);

        _expectPacksLosslessEqual(parsed.pack!, originalPack);

        final listed = await sharingService.listAvailablePacksInDirectory(tempDir.path);
        expect(listed.length, 1);
        expect(listed.first.isValid, isTrue);
        expect(listed.first.title, originalPack.metadata.title);
        expect(listed.first.stageCount, 1);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('bezstratny zapis i odczyt 21-etapowego Grand Touru .ppmstage z kompresją GZip', () async {
      final stages = List<RaceStage>.generate(21, (idx) {
        const stageTypes = StageType.values;
        const weathers = WeatherCondition.values;
        return _buildComplexStage(
          id: 'gt_stage_${idx + 1}',
          stageNumber: idx + 1,
          name: 'Etap ${idx + 1}: Odcinek Alpejsko-Brukowy',
          stageType: stageTypes[idx % stageTypes.length],
          weather: weathers[idx % weathers.length],
        );
      });

      final grandTour = TourRace(
        id: 'tour_of_central_europe_2026',
        name: 'Tour of Central Europe 2026',
        countryIso: 'POL',
        uciCategory: RaceCategory.grandTour,
        startMonth: 7,
        startDay: 4,
        stages: stages,
        prizePoolEur: 2300000,
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

      final originalPack = sharingService.createPackFromTourRace(
        race: grandTour,
        author: 'ProPeloton Architect',
        description: 'Pełny 21-etapowy Grand Tour z różnymi nawierzchniami i pogodą.',
        version: '2.1.0',
        tags: const ['GrandTour', '21stages', 'GZip'],
        createdAt: DateTime.utc(2026, 5, 10, 9, 30, 0),
      );

      final tempDir = await Directory.systemTemp.createTemp('ppm_stage_gzip_test_');
      try {
        final targetPath = '${tempDir.path}${Platform.pathSeparator}grand_tour_21.ppmstage';
        final receipt = await sharingService.exportToFile(
          originalPack,
          targetPath,
          compressGzip: true,
        );

        expect(receipt.compressed, isTrue);
        expect(receipt.validation.isValid, isTrue);
        expect(receipt.validation.stageCount, 21);

        final rawText = await File(receipt.filePath).readAsString();
        expect(rawText.startsWith(kPpmStageGzipPrefix), isTrue);

        final parsed = await sharingService.importFromFile(receipt.filePath);
        expect(parsed.success, isTrue, reason: parsed.errorMessage);
        expect(parsed.checksumVerified, isTrue);
        expect(parsed.wasCompressed, isTrue);
        expect(parsed.pack, isNotNull);

        _expectPacksLosslessEqual(parsed.pack!, originalPack);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('wykrywa naruszenie integralności pliku .ppmstage po modyfikacji zawartości', () async {
      final stage = _buildComplexStage(
        id: 'tamper_stage',
        stageNumber: 1,
        name: 'Test Integralności',
      );
      final pack = sharingService.createOneDayPackFromStage(
        stage: stage,
        raceName: 'Integrity Check Classic',
      );

      final tempDir = await Directory.systemTemp.createTemp('ppm_stage_tamper_test_');
      try {
        final filePath = '${tempDir.path}${Platform.pathSeparator}integrity.ppmstage';
        await sharingService.exportToFile(pack, filePath, compressGzip: false);

        final originalContent = await File(filePath).readAsString();
        final tamperedContent = originalContent.replaceFirst(
          'Integrity Check Classic',
          'Tampered Race Name',
        );
        expect(tamperedContent, isNot(originalContent));
        await File(filePath).writeAsString(tamperedContent, flush: true);

        final parsed = await sharingService.importFromFile(filePath);
        expect(parsed.success, isFalse);
        expect(parsed.checksumVerified, isFalse);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
