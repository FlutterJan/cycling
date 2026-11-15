import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/rendering3d/glb_asset_loader_service.dart';
import 'package:pro_peloton_manager/engine/rendering3d/glb_mesh_integrity_validator.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

Uint8List _buildMinimalValidGlbBytes() {
  final jsonBytes = utf8.encode(jsonEncode({
    'asset': {'version': '2.0', 'generator': 'TestBuilder'},
    'scenes': [
      {'nodes': [0]}
    ],
    'nodes': [
      {'mesh': 0}
    ],
  }));
  final paddedJsonLen = (jsonBytes.length + 3) & ~3;
  final totalLen = 12 + 8 + paddedJsonLen;
  final buffer = ByteData(totalLen);
  buffer.setUint32(0, 0x46546C67, Endian.little); // glTF
  buffer.setUint32(4, 2, Endian.little);
  buffer.setUint32(8, totalLen, Endian.little);
  buffer.setUint32(12, paddedJsonLen, Endian.little);
  buffer.setUint32(16, 0x4E4F534A, Endian.little); // JSON

  final out = buffer.buffer.asUint8List();
  for (int i = 0; i < jsonBytes.length; i++) {
    out[20 + i] = jsonBytes[i];
  }
  for (int i = jsonBytes.length; i < paddedJsonLen; i++) {
    out[20 + i] = 0x20; // ASCII space padding per glTF spec
  }
  return out;
}

void main() {
  group('GlbMeshIntegrityValidator.inspectGlbBinaryStructure', () {
    test('akceptuje poprawny nagłówek GLB 2.0 i chunk JSON', () {
      final bytes = _buildMinimalValidGlbBytes();
      final res = GlbMeshIntegrityValidator.inspectGlbBinaryStructure(bytes);
      expect(res.isValid, isTrue);
      expect(res.gltfVersion, 2);
      expect(res.hasJsonChunk, isTrue);
      expect(res.errorReason, isNull);
    });

    test('odrzuca plik krótszy niż 12 bajtów', () {
      final res = GlbMeshIntegrityValidator.inspectGlbBinaryStructure(
        Uint8List.fromList([1, 2, 3, 4]),
      );
      expect(res.isValid, isFalse);
      expect(res.errorReason, isNotNull);
    });

    test('odrzuca nieprawidłową sygnaturę magic', () {
      final bytes = _buildMinimalValidGlbBytes();
      bytes[0] = 0x00;
      final res = GlbMeshIntegrityValidator.inspectGlbBinaryStructure(bytes);
      expect(res.isValid, isFalse);
      expect(res.errorReason, contains('magic'));
    });

    test('odrzuca nieprawidłową wersję glTF', () {
      final bytes = _buildMinimalValidGlbBytes();
      ByteData.sublistView(bytes).setUint32(4, 1, Endian.little);
      final res = GlbMeshIntegrityValidator.inspectGlbBinaryStructure(bytes);
      expect(res.isValid, isFalse);
      expect(res.errorReason, contains('wersja'));
    });

    test('odrzuca ucięty plik z niespójną długością', () {
      final bytes = _buildMinimalValidGlbBytes();
      final truncated = bytes.sublist(0, bytes.length - 4);
      final res = GlbMeshIntegrityValidator.inspectGlbBinaryStructure(truncated);
      expect(res.isValid, isFalse);
      expect(res.errorReason, isNotNull);
    });
  });

  group('GlbMeshIntegrityValidator.isGeometryValid', () {
    test('wykrywa NaN w wierzchołkach jako geometrię zdegenerowaną', () {
      final geometry = GlbModelGeometry(
        assetKey: 'bad_mesh',
        name: 'Bad Mesh',
        category: GlbAssetCategory.bike,
        primitives: [
          GlbMeshPrimitive(
            name: 'p0',
            vertices: [
              Vector3(double.nan, 0, 0),
              Vector3(1, 0, 0),
              Vector3(0, 1, 0),
            ],
            normals: [
              Vector3(0, 1, 0),
              Vector3(0, 1, 0),
              Vector3(0, 1, 0),
            ],
            uvs: [Vector2.zero(), Vector2.zero(), Vector2.zero()],
            indices: [0, 1, 2],
            material: GlbMaterialData.fallback(),
            boundingBox: Aabb3.minMax(Vector3.zero(), Vector3(1, 1, 1)),
          ),
        ],
        boundingBox: Aabb3.minMax(Vector3.zero(), Vector3(1, 1, 1)),
        boundingCenter: Vector3(0.5, 0.5, 0.5),
        boundingRadius: 1.0,
        totalVertices: 3,
        totalTriangles: 1,
      );

      expect(GlbMeshIntegrityValidator.isGeometryValid(geometry), isFalse);
    });
  });

  group('GlbMeshIntegrityValidator startup & RAM repair', () {
    test('naprawia brakujące i uszkodzone pliki .glb w RAM bez rzucania wyjątków',
        () async {
      final tempDir = await Directory.systemTemp.createTemp('glb_validator_test_');
      try {
        // Tworzymy uszkodzony plik dla jednego z modeli katalogowych i dodatkowy plik .glb
        final corruptedFile = File('${tempDir.path}/frame_aero.glb');
        await corruptedFile.writeAsBytes([0xDE, 0xAD, 0xBE, 0xEF, 0x00, 0x01]);

        final extraCorrupted = File('${tempDir.path}/custom_sponsor_totem.glb');
        await extraCorrupted.writeAsBytes([1, 2, 3]);

        final loader = GlbAssetLoaderService();
        final validator = GlbMeshIntegrityValidator(
          loaderService: loader,
          searchDirectories: [tempDir.path],
        );

        final report = await validator.validateStartupIntegrity(
          useRootBundle: false,
        );

        expect(report.totalAssetsChecked,
            greaterThanOrEqualTo(GlbAssetCatalog.allAssets.length + 1));
        expect(report.isZeroCrashGuaranteed, isTrue);
        expect(report.totalVerticesInRam, greaterThan(0));
        expect(report.totalTrianglesInRam, greaterThan(0));
        expect(report.corruptedRepairedCount, greaterThanOrEqualTo(2));

        final resolvedFrame = validator.resolveSafeGeometry('frame_aero');
        expect(resolvedFrame.totalVertices, greaterThan(0));
        expect(resolvedFrame.totalTriangles, greaterThan(0));

        final resolvedUnknown = validator.resolveSafeGeometry('non_existent_xyz');
        expect(resolvedUnknown.totalVertices, greaterThan(0));
        expect(resolvedUnknown.totalTriangles, greaterThan(0));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });

  group('GlbMeshIntegrityStatusPanel responsive UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnień przy ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final validator = GlbMeshIntegrityValidator(
            loaderService: GlbAssetLoaderService(),
            searchDirectories: const ['nonexistent_models_3d_dir'],
          );

          final container = ProviderContainer(
            overrides: [
              glbMeshIntegrityValidatorProvider.overrideWithValue(validator),
            ],
          );
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: AppTheme.darkTheme,
                home: const Scaffold(
                  body: SingleChildScrollView(
                    padding: EdgeInsets.all(12),
                    child: GlbMeshIntegrityStatusPanel(autoValidateOnMount: false),
                  ),
                ),
              ),
            ),
          );

          await tester.runAsync(
            () => container
                .read(glbMeshIntegrityProvider.notifier)
                .runStartupValidation(useRootBundle: false),
          );
          await tester.pumpAndSettle();

          expect(find.text('Sprawdzone modele'), findsOneWidget);
          expect(find.text('Naprawione w RAM'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
