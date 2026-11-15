// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'glb_asset_loader_service.dart';

/// Status integralności pojedynczego zasobu `.glb` po walidacji startowej.
enum GlbMeshValidationStatus {
  /// Plik `.glb` istnieje, ma poprawny nagłówek glTF 2.0 i spójną geometrię.
  validDisk(
    label: 'Poprawny (.glb)',
    color: AppColors.statusSuccess,
    icon: Icons.verified_rounded,
  ),

  /// Plik `.glb` nie został znaleziony; wygenerowano zastępczą siatkę w pamięci RAM.
  missingRepairedInRam(
    label: 'Brak pliku → RAM',
    color: AppColors.amberWarning,
    icon: Icons.memory_rounded,
  ),

  /// Plik `.glb` był uszkodzony lub ucięty; wygenerowano zastępczą siatkę w pamięci RAM.
  corruptedRepairedInRam(
    label: 'Uszkodzony → RAM',
    color: AppColors.crimsonAlert,
    icon: Icons.build_circle_rounded,
  ),

  /// Plik `.glb` miał zdegenerowaną geometrię (NaN, 0 trójkątów, błędne indeksy) → RAM.
  degenerateGeometryRepairedInRam(
    label: 'Błąd siatki → RAM',
    color: AppColors.primaryAccent,
    icon: Icons.auto_fix_high_rounded,
  );

  final String label;
  final Color color;
  final IconData icon;

  const GlbMeshValidationStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  bool get isRepairedInRam => this != GlbMeshValidationStatus.validDisk;
}

/// Wynik niskopoziomowej inspekcji nagłówka i chunków pliku binarnego GLB (glTF 2.0).
class GlbBinaryInspectionResult {
  final bool isValid;
  final int byteLength;
  final int declaredTotalLength;
  final int gltfVersion;
  final bool hasJsonChunk;
  final bool hasBinChunk;
  final String? errorReason;

  const GlbBinaryInspectionResult({
    required this.isValid,
    required this.byteLength,
    this.declaredTotalLength = 0,
    this.gltfVersion = 0,
    this.hasJsonChunk = false,
    this.hasBinChunk = false,
    this.errorReason,
  });
}

/// Raport z audytu pojedynczego modelu 3D.
class GlbMeshAssetAuditEntry {
  final String assetKey;
  final String displayName;
  final GlbAssetCategory category;
  final String expectedPath;
  final String? resolvedSourcePath;
  final GlbMeshValidationStatus status;
  final int fileSizeBytes;
  final int primitiveCount;
  final int vertexCount;
  final int triangleCount;
  final bool repairedInRam;
  final String? issueDetail;
  final int durationMs;

  const GlbMeshAssetAuditEntry({
    required this.assetKey,
    required this.displayName,
    required this.category,
    required this.expectedPath,
    required this.resolvedSourcePath,
    required this.status,
    required this.fileSizeBytes,
    required this.primitiveCount,
    required this.vertexCount,
    required this.triangleCount,
    required this.repairedInRam,
    this.issueDetail,
    required this.durationMs,
  });
}

/// Zbiorczy raport integralności wszystkich zasobów 3D po uruchomieniu aplikacji.
class GlbIntegrityValidationReport {
  final DateTime validatedAt;
  final List<String> scannedDirectories;
  final int totalAssetsChecked;
  final int validCount;
  final int missingRepairedCount;
  final int corruptedRepairedCount;
  final int degenerateRepairedCount;
  final int totalVerticesInRam;
  final int totalTrianglesInRam;
  final int totalDurationMs;
  final List<GlbMeshAssetAuditEntry> entries;

  const GlbIntegrityValidationReport({
    required this.validatedAt,
    required this.scannedDirectories,
    required this.totalAssetsChecked,
    required this.validCount,
    required this.missingRepairedCount,
    required this.corruptedRepairedCount,
    required this.degenerateRepairedCount,
    required this.totalVerticesInRam,
    required this.totalTrianglesInRam,
    required this.totalDurationMs,
    required this.entries,
  });

  /// Liczba modeli naprawionych w locie w pamięci RAM.
  int get repairedCount =>
      missingRepairedCount + corruptedRepairedCount + degenerateRepairedCount;

  /// Odsetek plików poprawnych bezpośrednio z dysku (0.0 – 1.0).
  double get diskIntegrityRatio =>
      totalAssetsChecked == 0 ? 1.0 : validCount / totalAssetsChecked;

  /// Gwarancja braku crashy: wszystkie sprawdzone modele posiadają ważną geometrię w RAM.
  bool get isZeroCrashGuaranteed =>
      entries.length == totalAssetsChecked &&
      entries.every((e) => e.vertexCount > 0 && e.triangleCount > 0);
}

/// Automatyczny walidator startowy integralności siatek `.glb` (Zadanie #197).
///
/// Sprawdza obecność i poprawność binarną wszystkich plików `.glb` w `assets/models_3d/`
/// oraz w katalogu `assets/3d/`, a w razie braku lub uszkodzenia generuje w locie
/// pełnowartościowe siatki geometryczne w pamięci RAM, gwarantując zero crashy przy starcie.
class GlbMeshIntegrityValidator {
  static const int _glbMagicGlTF = 0x46546C67; // 'glTF'
  static const int _glbChunkTypeJson = 0x4E4F534A; // 'JSON'
  static const int _glbChunkTypeBin = 0x004E4942; // 'BIN\0'

  /// Domyślne katalogi skanowane w poszukiwaniu wygenerowanych plików `.glb`.
  static const List<String> defaultSearchDirectories = [
    'assets/models_3d',
    'assets/3d',
  ];

  final GlbAssetLoaderService _loaderService;
  final GlbProceduralFallbackBuilder _fallbackBuilder;
  final List<String> _searchDirectories;

  /// Rejestr zweryfikowanych lub wygenerowanych w locie siatek w pamięci RAM.
  final Map<String, GlbModelGeometry> _ramMeshRegistry = {};

  GlbIntegrityValidationReport? _lastReport;

  GlbMeshIntegrityValidator({
    GlbAssetLoaderService? loaderService,
    GlbProceduralFallbackBuilder? fallbackBuilder,
    List<String>? searchDirectories,
  })  : _loaderService = loaderService ?? GlbAssetLoaderService.instance,
        _fallbackBuilder = fallbackBuilder ?? GlbProceduralFallbackBuilder(),
        _searchDirectories = List<String>.unmodifiable(
          searchDirectories ?? defaultSearchDirectories,
        );

  /// Ostatni wygenerowany raport integralności.
  GlbIntegrityValidationReport? get lastReport => _lastReport;

  /// Niemodyfikowalny widok rejestru siatek geometrycznych w pamięci RAM.
  Map<String, GlbModelGeometry> get ramMeshRegistry =>
      Map<String, GlbModelGeometry>.unmodifiable(_ramMeshRegistry);

  /// Katalogi skonfigurowane do skanowania plików `.glb`.
  List<String> get searchDirectories => _searchDirectories;

  /// Przeprowadza pełny audyt startowy wszystkich zasobów `.glb` i naprawia w RAM brakujące/uszkodzone siatki.
  ///
  /// Gwarancja: metoda nigdy nie rzuca wyjątku i zawsze zapewnia kompletną geometrię dla każdego klucza.
  Future<GlbIntegrityValidationReport> validateStartupIntegrity({
    bool useRootBundle = true,
    bool populateLoaderCache = true,
  }) async {
    final totalStopwatch = Stopwatch()..start();
    final entries = <GlbMeshAssetAuditEntry>[];
    final seenKeys = <String>{};

    int validCount = 0;
    int missingRepairedCount = 0;
    int corruptedRepairedCount = 0;
    int degenerateRepairedCount = 0;
    int totalVerticesInRam = 0;
    int totalTrianglesInRam = 0;

    // 1. Walidacja wszystkich zdefiniowanych modeli katalogowych
    for (final def in GlbAssetCatalog.allAssets) {
      seenKeys.add(def.id);
      final entry = await _validateAndRepairSingleAsset(
        assetKey: def.id,
        displayName: def.displayName,
        category: def.category,
        expectedPath: def.relativePath,
        fileName: def.fileName,
        useRootBundle: useRootBundle,
        populateLoaderCache: populateLoaderCache,
      );
      entries.add(entry);
    }

    // 2. Wykrycie dodatkowych plików .glb umieszczonych bezpośrednio w katalogach skanowania (np. assets/models_3d/)
    final extraFiles = await _discoverExtraGlbFiles(seenKeys);
    for (final file in extraFiles) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final fileName = normalizedPath.split('/').last;
      final key = _loaderService.normalizeAssetKey(fileName);
      if (seenKeys.contains(key)) {
        continue;
      }
      seenKeys.add(key);

      final entry = await _validateAndRepairSingleAsset(
        assetKey: key,
        displayName: 'Dodatkowy model ($fileName)',
        category: GlbAssetCategory.unknown,
        expectedPath: normalizedPath,
        fileName: fileName,
        useRootBundle: false,
        populateLoaderCache: populateLoaderCache,
      );
      entries.add(entry);
    }

    for (final entry in entries) {
      totalVerticesInRam += entry.vertexCount;
      totalTrianglesInRam += entry.triangleCount;
      switch (entry.status) {
        case GlbMeshValidationStatus.validDisk:
          validCount++;
          break;
        case GlbMeshValidationStatus.missingRepairedInRam:
          missingRepairedCount++;
          break;
        case GlbMeshValidationStatus.corruptedRepairedInRam:
          corruptedRepairedCount++;
          break;
        case GlbMeshValidationStatus.degenerateGeometryRepairedInRam:
          degenerateRepairedCount++;
          break;
      }
    }

    totalStopwatch.stop();
    final report = GlbIntegrityValidationReport(
      validatedAt: DateTime.now(),
      scannedDirectories: _searchDirectories,
      totalAssetsChecked: entries.length,
      validCount: validCount,
      missingRepairedCount: missingRepairedCount,
      corruptedRepairedCount: corruptedRepairedCount,
      degenerateRepairedCount: degenerateRepairedCount,
      totalVerticesInRam: totalVerticesInRam,
      totalTrianglesInRam: totalTrianglesInRam,
      totalDurationMs: totalStopwatch.elapsedMilliseconds,
      entries: List<GlbMeshAssetAuditEntry>.unmodifiable(entries),
    );

    _lastReport = report;
    return report;
  }

  /// Zwraca zweryfikowaną siatkę z RAM lub natychmiast syntetyzuje ją w locie (Zero-Crash).
  GlbModelGeometry resolveSafeGeometry(String assetKeyOrPath) {
    final key = _loaderService.normalizeAssetKey(assetKeyOrPath);
    final cached = _ramMeshRegistry[key];
    if (cached != null && isGeometryValid(cached)) {
      return cached;
    }

    final synthesized = _buildAndRegisterFallback(
      key,
      reason: 'Synteza awaryjna w locie w pamięci RAM (resolveSafeGeometry)',
      populateLoaderCache: true,
    );
    return synthesized;
  }

  /// Szybka walidacja struktury binarnej nagłówka i chunków GLB (glTF 2.0).
  static GlbBinaryInspectionResult inspectGlbBinaryStructure(Uint8List bytes) {
    if (bytes.length < 12) {
      return GlbBinaryInspectionResult(
        isValid: false,
        byteLength: bytes.length,
        errorReason: 'Plik krótszy niż 12-bajtowy nagłówek GLB (${bytes.length} B)',
      );
    }

    final bd = ByteData.sublistView(bytes);
    final magic = bd.getUint32(0, Endian.little);
    if (magic != _glbMagicGlTF) {
      return GlbBinaryInspectionResult(
        isValid: false,
        byteLength: bytes.length,
        errorReason:
            'Nieprawidłowa sygnatura magic: 0x${magic.toRadixString(16)} (oczekiwano glTF)',
      );
    }

    final version = bd.getUint32(4, Endian.little);
    if (version != 2) {
      return GlbBinaryInspectionResult(
        isValid: false,
        byteLength: bytes.length,
        gltfVersion: version,
        errorReason: 'Nieobsługiwana wersja glTF: $version (wymagana 2)',
      );
    }

    final declaredLength = bd.getUint32(8, Endian.little);
    if (declaredLength < 20 || declaredLength > bytes.length) {
      return GlbBinaryInspectionResult(
        isValid: false,
        byteLength: bytes.length,
        declaredTotalLength: declaredLength,
        gltfVersion: version,
        errorReason:
            'Niespójna długość zadeklarowana w nagłówku ($declaredLength B vs ${bytes.length} B)',
      );
    }

    // Chunk 0: JSON
    if (bytes.length < 20) {
      return GlbBinaryInspectionResult(
        isValid: false,
        byteLength: bytes.length,
        declaredTotalLength: declaredLength,
        gltfVersion: version,
        errorReason: 'Brak nagłówka pierwszego chunku JSON',
      );
    }

    final jsonChunkLength = bd.getUint32(12, Endian.little);
    final jsonChunkType = bd.getUint32(16, Endian.little);
    if (jsonChunkType != _glbChunkTypeJson) {
      return GlbBinaryInspectionResult(
        isValid: false,
        byteLength: bytes.length,
        declaredTotalLength: declaredLength,
        gltfVersion: version,
        errorReason:
            'Pierwszy chunk nie jest typu JSON (0x${jsonChunkType.toRadixString(16)})',
      );
    }

    final jsonEnd = 20 + jsonChunkLength;
    if (jsonChunkLength == 0 || jsonEnd > declaredLength) {
      return GlbBinaryInspectionResult(
        isValid: false,
        byteLength: bytes.length,
        declaredTotalLength: declaredLength,
        gltfVersion: version,
        errorReason: 'Chunk JSON wykracza poza rozmiar pliku ($jsonEnd > $declaredLength)',
      );
    }

    // Weryfikacja poprawności składni JSON i sekcji asset.version
    try {
      final jsonString = utf8.decode(bytes.sublist(20, jsonEnd)).trim();
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return GlbBinaryInspectionResult(
          isValid: false,
          byteLength: bytes.length,
          declaredTotalLength: declaredLength,
          gltfVersion: version,
          errorReason: 'Root dokumentu glTF JSON nie jest obiektem',
        );
      }
      final assetMap = decoded['asset'];
      if (assetMap is! Map<String, dynamic> || assetMap['version'] == null) {
        return GlbBinaryInspectionResult(
          isValid: false,
          byteLength: bytes.length,
          declaredTotalLength: declaredLength,
          gltfVersion: version,
          errorReason: 'Brak wymaganego pola asset.version w metadanych glTF',
        );
      }
    } catch (e) {
      return GlbBinaryInspectionResult(
        isValid: false,
        byteLength: bytes.length,
        declaredTotalLength: declaredLength,
        gltfVersion: version,
        errorReason: 'Uszkodzony JSON glTF: $e',
      );
    }

    // Chunk 1 (opcjonalny BIN)
    bool hasBin = false;
    if (jsonEnd < declaredLength) {
      if (jsonEnd + 8 > declaredLength) {
        return GlbBinaryInspectionResult(
          isValid: false,
          byteLength: bytes.length,
          declaredTotalLength: declaredLength,
          gltfVersion: version,
          hasJsonChunk: true,
          errorReason: 'Ucięty nagłówek chunku BIN',
        );
      }
      final binChunkLength = bd.getUint32(jsonEnd, Endian.little);
      final binChunkType = bd.getUint32(jsonEnd + 4, Endian.little);
      if (binChunkType != _glbChunkTypeBin) {
        return GlbBinaryInspectionResult(
          isValid: false,
          byteLength: bytes.length,
          declaredTotalLength: declaredLength,
          gltfVersion: version,
          hasJsonChunk: true,
          errorReason:
              'Nieprawidłowy typ drugiego chunku: 0x${binChunkType.toRadixString(16)}',
        );
      }
      final binEnd = jsonEnd + 8 + binChunkLength;
      if (binEnd > declaredLength) {
        return GlbBinaryInspectionResult(
          isValid: false,
          byteLength: bytes.length,
          declaredTotalLength: declaredLength,
          gltfVersion: version,
          hasJsonChunk: true,
          errorReason: 'Chunk BIN wykracza poza rozmiar pliku ($binEnd > $declaredLength)',
        );
      }
      hasBin = true;
    }

    return GlbBinaryInspectionResult(
      isValid: true,
      byteLength: bytes.length,
      declaredTotalLength: declaredLength,
      gltfVersion: version,
      hasJsonChunk: true,
      hasBinChunk: hasBin,
    );
  }

  /// Weryfikuje spójność matematyczną geometrii (brak NaN/Infinity, poprawne indeksy i bounding box).
  static bool isGeometryValid(GlbModelGeometry geometry) {
    if (geometry.primitives.isEmpty ||
        geometry.totalVertices <= 0 ||
        geometry.totalTriangles <= 0) {
      return false;
    }

    if (!_isFiniteVector3(geometry.boundingBox.min) ||
        !_isFiniteVector3(geometry.boundingBox.max) ||
        !_isFiniteVector3(geometry.boundingCenter) ||
        geometry.boundingRadius.isNaN ||
        geometry.boundingRadius.isInfinite) {
      return false;
    }

    for (final prim in geometry.primitives) {
      if (prim.vertices.isEmpty ||
          prim.indices.length < 3 ||
          prim.indices.length % 3 != 0) {
        return false;
      }

      final vertexCount = prim.vertices.length;
      for (final v in prim.vertices) {
        if (!_isFiniteVector3(v)) {
          return false;
        }
      }
      for (final n in prim.normals) {
        if (!_isFiniteVector3(n)) {
          return false;
        }
      }
      for (final idx in prim.indices) {
        if (idx < 0 || idx >= vertexCount) {
          return false;
        }
      }
    }

    return true;
  }

  static bool _isFiniteVector3(Vector3 v) {
    return v.x.isFinite && v.y.isFinite && v.z.isFinite;
  }

  Future<GlbMeshAssetAuditEntry> _validateAndRepairSingleAsset({
    required String assetKey,
    required String displayName,
    required GlbAssetCategory category,
    required String expectedPath,
    required String fileName,
    required bool useRootBundle,
    required bool populateLoaderCache,
  }) async {
    final sw = Stopwatch()..start();

    try {
      final loaded = await _readAssetBytes(
        expectedPath: expectedPath,
        fileName: fileName,
        useRootBundle: useRootBundle,
      );

      // 1. Brak pliku na dysku i w bundlu -> synteza proceduralna w RAM
      if (loaded == null) {
        final fallback = _buildAndRegisterFallback(
          assetKey,
          reason: 'Brak pliku .glb w ${_searchDirectories.join(', ')}',
          populateLoaderCache: populateLoaderCache,
        );
        sw.stop();
        return GlbMeshAssetAuditEntry(
          assetKey: assetKey,
          displayName: displayName,
          category: category,
          expectedPath: expectedPath,
          resolvedSourcePath: null,
          status: GlbMeshValidationStatus.missingRepairedInRam,
          fileSizeBytes: 0,
          primitiveCount: fallback.primitives.length,
          vertexCount: fallback.totalVertices,
          triangleCount: fallback.totalTriangles,
          repairedInRam: true,
          issueDetail:
              'Plik nie istnieje na dysku ani w AssetBundle — wygenerowano siatkę proceduralną w RAM.',
          durationMs: sw.elapsedMilliseconds,
        );
      }

      final bytes = loaded.bytes;
      final inspection = inspectGlbBinaryStructure(bytes);
      if (!inspection.isValid) {
        final fallback = _buildAndRegisterFallback(
          assetKey,
          reason: inspection.errorReason ?? 'Uszkodzony plik GLB',
          populateLoaderCache: populateLoaderCache,
        );
        sw.stop();
        return GlbMeshAssetAuditEntry(
          assetKey: assetKey,
          displayName: displayName,
          category: category,
          expectedPath: expectedPath,
          resolvedSourcePath: loaded.sourcePath,
          status: GlbMeshValidationStatus.corruptedRepairedInRam,
          fileSizeBytes: bytes.length,
          primitiveCount: fallback.primitives.length,
          vertexCount: fallback.totalVertices,
          triangleCount: fallback.totalTriangles,
          repairedInRam: true,
          issueDetail: inspection.errorReason,
          durationMs: sw.elapsedMilliseconds,
        );
      }

      // 2. Pełne parsowanie geometrii 3D
      GlbModelGeometry parsed;
      try {
        parsed = _loaderService.parseGlbBinary(
          bytes,
          assetKey: assetKey,
          category: category,
          displayName: displayName,
        );
      } catch (e) {
        final fallback = _buildAndRegisterFallback(
          assetKey,
          reason: 'Wyjątek parsowania GLB: $e',
          populateLoaderCache: populateLoaderCache,
        );
        sw.stop();
        return GlbMeshAssetAuditEntry(
          assetKey: assetKey,
          displayName: displayName,
          category: category,
          expectedPath: expectedPath,
          resolvedSourcePath: loaded.sourcePath,
          status: GlbMeshValidationStatus.corruptedRepairedInRam,
          fileSizeBytes: bytes.length,
          primitiveCount: fallback.primitives.length,
          vertexCount: fallback.totalVertices,
          triangleCount: fallback.totalTriangles,
          repairedInRam: true,
          issueDetail: 'Wyjątek parsera GLB: $e',
          durationMs: sw.elapsedMilliseconds,
        );
      }

      // 3. Walidacja matematyczna siatki (NaN, puste prymitywy, błędne indeksy)
      if (!isGeometryValid(parsed)) {
        final fallback = _buildAndRegisterFallback(
          assetKey,
          reason: 'Zdegenerowana geometria w pliku .glb',
          populateLoaderCache: populateLoaderCache,
        );
        sw.stop();
        return GlbMeshAssetAuditEntry(
          assetKey: assetKey,
          displayName: displayName,
          category: category,
          expectedPath: expectedPath,
          resolvedSourcePath: loaded.sourcePath,
          status: GlbMeshValidationStatus.degenerateGeometryRepairedInRam,
          fileSizeBytes: bytes.length,
          primitiveCount: fallback.primitives.length,
          vertexCount: fallback.totalVertices,
          triangleCount: fallback.totalTriangles,
          repairedInRam: true,
          issueDetail:
              'Siatka zawiera puste prymitywy, wartości NaN/Inf lub błędne indeksy — zastąpiono w RAM.',
          durationMs: sw.elapsedMilliseconds,
        );
      }

      // 4. Sukces: rejestrujemy zwalidowaną geometrię w RAM
      _ramMeshRegistry[assetKey] = parsed;
      sw.stop();
      return GlbMeshAssetAuditEntry(
        assetKey: assetKey,
        displayName: displayName,
        category: category,
        expectedPath: expectedPath,
        resolvedSourcePath: loaded.sourcePath,
        status: GlbMeshValidationStatus.validDisk,
        fileSizeBytes: bytes.length,
        primitiveCount: parsed.primitives.length,
        vertexCount: parsed.totalVertices,
        triangleCount: parsed.totalTriangles,
        repairedInRam: false,
        durationMs: sw.elapsedMilliseconds,
      );
    } catch (unexpected) {
      // Ostateczna bariera zero-crash
      final fallback = _buildAndRegisterFallback(
        assetKey,
        reason: 'Nieoczekiwany błąd walidacji: $unexpected',
        populateLoaderCache: populateLoaderCache,
      );
      sw.stop();
      return GlbMeshAssetAuditEntry(
        assetKey: assetKey,
        displayName: displayName,
        category: category,
        expectedPath: expectedPath,
        resolvedSourcePath: null,
        status: GlbMeshValidationStatus.corruptedRepairedInRam,
        fileSizeBytes: 0,
        primitiveCount: fallback.primitives.length,
        vertexCount: fallback.totalVertices,
        triangleCount: fallback.totalTriangles,
        repairedInRam: true,
        issueDetail: 'Nieoczekiwany błąd odzyskiwania: $unexpected',
        durationMs: sw.elapsedMilliseconds,
      );
    }
  }

  GlbModelGeometry _buildAndRegisterFallback(
    String assetKey, {
    required String reason,
    required bool populateLoaderCache,
  }) {
    final fallback = _fallbackBuilder.buildFallback(assetKey, reason: reason);
    _ramMeshRegistry[assetKey] = fallback;
    if (populateLoaderCache) {
      // Zapewniamy synchroniczną dostępność w GlbAssetLoaderService bez ponownego IO
      _loaderService.getModel(assetKey);
    }
    return fallback;
  }

  Future<_ResolvedGlbBytes?> _readAssetBytes({
    required String expectedPath,
    required String fileName,
    required bool useRootBundle,
  }) async {
    final candidates = <String>{
      for (final dir in _searchDirectories) ...[
        '$dir/$fileName',
        if (expectedPath.contains('3d/'))
          '$dir/${expectedPath.split('3d/').last}',
      ],
      expectedPath,
    };

    for (final path in candidates) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          return _ResolvedGlbBytes(sourcePath: path, bytes: bytes);
        }
      } catch (_) {
        // Ignorujemy pojedyncze błędy IO i próbujemy kolejne ścieżki
      }
    }

    if (useRootBundle) {
      for (final path in candidates) {
        try {
          final data = await rootBundle.load(path);
          final bytes = data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
          return _ResolvedGlbBytes(sourcePath: 'bundle://$path', bytes: bytes);
        } catch (_) {
          // Asset nie znajduje się w paczce pod tą ścieżką
        }
      }
    }

    return null;
  }

  Future<List<File>> _discoverExtraGlbFiles(Set<String> knownKeys) async {
    final discovered = <File>[];
    for (final dirPath in _searchDirectories) {
      try {
        final dir = Directory(dirPath);
        if (!await dir.exists()) {
          continue;
        }
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File && entity.path.toLowerCase().endsWith('.glb')) {
            final fileName = entity.path.replaceAll('\\', '/').split('/').last;
            final key = _loaderService.normalizeAssetKey(fileName);
            if (!knownKeys.contains(key)) {
              discovered.add(entity);
            }
          }
        }
      } catch (_) {
        // Brak dostępu do katalogu nie może przerywać walidacji startowej
      }
    }
    return discovered;
  }
}

class _ResolvedGlbBytes {
  final String sourcePath;
  final Uint8List bytes;

  const _ResolvedGlbBytes({
    required this.sourcePath,
    required this.bytes,
  });
}

/// Stan Riverpoda dla walidatora integralności siatek 3D.
class GlbMeshIntegrityState {
  final bool isValidating;
  final GlbIntegrityValidationReport? report;
  final GlbMeshValidationStatus? statusFilter;
  final String searchQuery;

  const GlbMeshIntegrityState({
    this.isValidating = false,
    this.report,
    this.statusFilter,
    this.searchQuery = '',
  });

  GlbMeshIntegrityState copyWith({
    bool? isValidating,
    GlbIntegrityValidationReport? report,
    GlbMeshValidationStatus? statusFilter,
    bool clearStatusFilter = false,
    String? searchQuery,
  }) {
    return GlbMeshIntegrityState(
      isValidating: isValidating ?? this.isValidating,
      report: report ?? this.report,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<GlbMeshAssetAuditEntry> get filteredEntries {
    final entries = report?.entries ?? const <GlbMeshAssetAuditEntry>[];
    return entries.where((entry) {
      if (statusFilter != null && entry.status != statusFilter) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return entry.assetKey.toLowerCase().contains(q) ||
            entry.displayName.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }
}

/// Kontroler Riverpoda uruchamiający walidację startową i udostępniający raport UI.
class GlbMeshIntegrityNotifier extends StateNotifier<GlbMeshIntegrityState> {
  final GlbMeshIntegrityValidator _validator;

  GlbMeshIntegrityNotifier(this._validator)
      : super(const GlbMeshIntegrityState());

  /// Uruchamia pełną walidację plików `.glb` i naprawę brakujących siatek w RAM.
  Future<GlbIntegrityValidationReport> runStartupValidation({
    bool useRootBundle = true,
  }) async {
    if (state.isValidating && _validator.lastReport != null) {
      return _validator.lastReport!;
    }
    state = state.copyWith(isValidating: true);
    final report = await _validator.validateStartupIntegrity(
      useRootBundle: useRootBundle,
    );
    if (mounted) {
      state = state.copyWith(isValidating: false, report: report);
    }
    return report;
  }

  void setStatusFilter(GlbMeshValidationStatus? status) {
    if (status == null || state.statusFilter == status) {
      state = state.copyWith(clearStatusFilter: true);
    } else {
      state = state.copyWith(statusFilter: status);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

/// Provider walidatora integralności modeli `.glb`.
final glbMeshIntegrityValidatorProvider =
    Provider<GlbMeshIntegrityValidator>((ref) {
  final loader = ref.watch(glbAssetLoaderServiceProvider);
  return GlbMeshIntegrityValidator(loaderService: loader);
});

/// Provider stanu walidacji startowej i diagnostyki siatek 3D.
final glbMeshIntegrityProvider =
    StateNotifierProvider<GlbMeshIntegrityNotifier, GlbMeshIntegrityState>(
  (ref) {
    final validator = ref.watch(glbMeshIntegrityValidatorProvider);
    return GlbMeshIntegrityNotifier(validator);
  },
);

/// Panel diagnostyczny integralności modeli 3D (.glb) i generatora RAM fallback.
///
/// Responsywny dla rozdzielczości 390x844 (mobile), 1024x768 (tablet) i 1600x900 (desktop).
class GlbMeshIntegrityStatusPanel extends ConsumerStatefulWidget {
  final bool autoValidateOnMount;

  const GlbMeshIntegrityStatusPanel({
    super.key,
    this.autoValidateOnMount = true,
  });

  @override
  ConsumerState<GlbMeshIntegrityStatusPanel> createState() =>
      _GlbMeshIntegrityStatusPanelState();
}

class _GlbMeshIntegrityStatusPanelState
    extends ConsumerState<GlbMeshIntegrityStatusPanel> {
  String? _expandedAssetKey;

  @override
  void initState() {
    super.initState();
    if (widget.autoValidateOnMount) {
      Future.microtask(() {
        if (!mounted) return;
        final current = ref.read(glbMeshIntegrityProvider);
        if (current.report == null && !current.isValidating) {
          ref.read(glbMeshIntegrityProvider.notifier).runStartupValidation();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(glbMeshIntegrityProvider);
    final notifier = ref.read(glbMeshIntegrityProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 600;
        final isTablet = width >= 600 && width < 1100;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1),
          ),
          padding: EdgeInsets.all(isMobile ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(state, notifier, isMobile),
              const SizedBox(height: 16),
              if (state.report != null) ...[
                _buildKpiGrid(state.report!, isMobile: isMobile, isTablet: isTablet),
                const SizedBox(height: 16),
                _buildFilterBar(state, notifier, isMobile: isMobile),
                const SizedBox(height: 12),
                _buildAuditList(state, isMobile: isMobile),
              ] else if (state.isValidating)
                _buildLoadingCard()
              else
                _buildEmptyPrompt(notifier),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    GlbMeshIntegrityState state,
    GlbMeshIntegrityNotifier notifier,
    bool isMobile,
  ) {
    final titleRow = Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.5),
            ),
          ),
          child: const Icon(
            Icons.view_in_ar_rounded,
            color: AppColors.goldAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Walidator Integralności Siatki 3D (.glb)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                state.report != null
                    ? 'Zero-Crash RAM Guard aktywny • ${state.report!.totalDurationMs} ms'
                    : 'Automatyczna weryfikacja zasobów assets/models_3d/ i RAM fallback',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  letterSpacing: -0.2,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    final actionButton = _InteractiveActionButton(
      label: state.isValidating ? 'Skanowanie...' : 'Skanuj i napraw',
      icon: Icons.refresh_rounded,
      enabled: !state.isValidating,
      onPressed: () => notifier.runStartupValidation(),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleRow,
          const SizedBox(height: 12),
          actionButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: titleRow),
        const SizedBox(width: 12),
        actionButton,
      ],
    );
  }

  Widget _buildKpiGrid(
    GlbIntegrityValidationReport report, {
    required bool isMobile,
    required bool isTablet,
  }) {
    final cards = [
      _KpiMetricCard(
        label: 'Sprawdzone modele',
        value: '${report.totalAssetsChecked}',
        accent: AppColors.accentBlue,
      ),
      _KpiMetricCard(
        label: 'Poprawne (.glb)',
        value: '${report.validCount}',
        accent: AppColors.statusSuccess,
      ),
      _KpiMetricCard(
        label: 'Naprawione w RAM',
        value: '${report.repairedCount}',
        accent: report.repairedCount > 0
            ? AppColors.amberWarning
            : AppColors.goldAccent,
      ),
      _KpiMetricCard(
        label: 'Trójkąty w RAM',
        value: '${report.totalTrianglesInRam}',
        accent: AppColors.goldAccent,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 10),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) SizedBox(width: isTablet ? 10 : 12),
        ],
      ],
    );
  }

  Widget _buildFilterBar(
    GlbMeshIntegrityState state,
    GlbMeshIntegrityNotifier notifier, {
    required bool isMobile,
  }) {
    final chips = [
      _InteractiveFilterChip(
        label: 'Wszystkie',
        selected: state.statusFilter == null,
        accent: AppColors.goldAccent,
        onTap: () => notifier.setStatusFilter(null),
      ),
      for (final status in GlbMeshValidationStatus.values)
        _InteractiveFilterChip(
          label: status.label,
          selected: state.statusFilter == status,
          accent: status.color,
          onTap: () => notifier.setStatusFilter(status),
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < chips.length; i++) ...[
            chips[i],
            if (i < chips.length - 1) SizedBox(width: isMobile ? 6 : 8),
          ],
        ],
      ),
    );
  }

  Widget _buildAuditList(
    GlbMeshIntegrityState state, {
    required bool isMobile,
  }) {
    final entries = state.filteredEntries;
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: Text(
            'Brak modeli spełniających wybrane kryteria filtra.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: isMobile ? 280 : 340),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final entry = entries[index];
          final isExpanded = _expandedAssetKey == entry.assetKey;
          return _InteractiveAuditRow(
            entry: entry,
            expanded: isExpanded,
            isMobile: isMobile,
            onTap: () {
              setState(() {
                _expandedAssetKey = isExpanded ? null : entry.assetKey;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.goldAccent,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Weryfikacja nagłówków GLB i synteza brakujących siatek w RAM...',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPrompt(GlbMeshIntegrityNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Center(
        child: Text(
          'Kliknij „Skanuj i napraw”, aby uruchomić audyt zasobów 3D.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _KpiMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _KpiMetricCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.5)
        : _pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.8)
            : _hovered
                ? AppColors.primaryAccent
                : AppColors.primaryAccent.withValues(alpha: 0.9);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : AppColors.goldAccent.withValues(alpha: widget.enabled ? 0.55 : 0.2),
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _InteractiveFilterChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_InteractiveFilterChip> createState() => _InteractiveFilterChipState();
}

class _InteractiveFilterChipState extends State<_InteractiveFilterChip> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? widget.accent.withValues(alpha: 0.22)
        : _pressed
            ? AppColors.surfaceLight.withValues(alpha: 0.9)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : widget.selected
                      ? widget.accent
                      : AppColors.cardBorder,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: widget.selected ? widget.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveAuditRow extends StatefulWidget {
  final GlbMeshAssetAuditEntry entry;
  final bool expanded;
  final bool isMobile;
  final VoidCallback onTap;

  const _InteractiveAuditRow({
    required this.entry,
    required this.expanded,
    required this.isMobile,
    required this.onTap,
  });

  @override
  State<_InteractiveAuditRow> createState() => _InteractiveAuditRowState();
}

class _InteractiveAuditRowState extends State<_InteractiveAuditRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.surfaceLight
                : AppColors.background.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : widget.expanded
                      ? entry.status.color.withValues(alpha: 0.7)
                      : AppColors.cardBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(entry.status.icon, size: 18, color: entry.status.color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.displayName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          entry.expectedPath,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!widget.isMobile) ...[
                    Text(
                      '${entry.triangleCount} Δ',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: entry.status.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.status.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: entry.status.color,
                      ),
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10, left: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Klucz: ${entry.assetKey} • Prymitywy: ${entry.primitiveCount} • '
                        'Wierzchołki: ${entry.vertexCount} • Trójkąty: ${entry.triangleCount} • '
                        'Czas: ${entry.durationMs} ms',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (entry.issueDetail != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          entry.issueDetail!,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: entry.status.color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                crossFadeState: widget.expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
                sizeCurve: Curves.easeOutCubic,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
