import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/services/database/cloud_cross_save_json_sync_adapter.dart';
import 'package:pro_peloton_manager/ui/widgets/cross_device_save_transfer_modal.dart';

void main() {
  Map<String, dynamic> buildSampleSaveJson() {
    return <String, dynamic>{
      'saveId': 'save_test_596',
      'saveName': 'Testowa Kariera WorldTour',
      'managerName': 'Jan Kowalski',
      'teamName': 'Polska Ekipa Pro',
      'seasonYear': 2026,
      'inGameDateIso': '2026-07-12T10:00:00Z',
      'schemaVersion': 7,
      'budgetEur': 12500000,
    };
  }

  Widget buildTestHost({
    required Size viewportSize,
    required Directory tempDir,
    Map<String, dynamic>? saveJson,
    CrossDeviceTransferTab initialTab = CrossDeviceTransferTab.exportArchive,
    ValueChanged<Map<String, dynamic>>? onSaveImported,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
          data: MediaQueryData(size: viewportSize),
          child: Scaffold(
            body: CrossDeviceSaveTransferModal(
              currentSaveJson: saveJson,
              initialDirectoryPath: tempDir.path,
              initialTab: initialTab,
              onSaveImported: onSaveImported,
            ),
          ),
        ),
      ),
    );
  }

  for (final size in const [
    Size(390, 844),
    Size(1024, 768),
    Size(1600, 900),
  ]) {
    testWidgets(
      'renders CrossDeviceSaveTransferModal without overflow at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final tempDir = Directory.systemTemp.createTempSync('ppm_modal_test_');
        addTearDown(() {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });

        await tester.pumpWidget(
          buildTestHost(
            viewportSize: size,
            tempDir: tempDir,
            saveJson: buildSampleSaveJson(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('Transfer Zapisów Cross-Device'), findsOneWidget);
        expect(find.text('Eksportuj .ppmsave.gz'), findsOneWidget);
      },
    );
  }

  testWidgets('exports .ppmsave.gz file and imports it back with checksum verification',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final tempDir = Directory.systemTemp.createTempSync('ppm_export_import_');
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    Map<String, dynamic>? importedResult;

    await tester.pumpWidget(
      buildTestHost(
        viewportSize: const Size(1280, 800),
        tempDir: tempDir,
        saveJson: buildSampleSaveJson(),
        onSaveImported: (json) => importedResult = json,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Export .ppmsave.gz
    final exportBtn = find.text('Eksportuj .ppmsave.gz');
    await tester.ensureVisible(exportBtn);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() async {
      await tester.tap(exportBtn);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(milliseconds: 300));

    final expectedFile = File(
      '${tempDir.path}${Platform.pathSeparator}save_test_596$kCrossSaveFileExtension',
    );
    expect(expectedFile.existsSync(), isTrue);

    // Switch to Import tab
    await tester.tap(find.text('Import .ppmsave.gz'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify file
    final verifyBtn = find.text('Weryfikuj plik');
    await tester.ensureVisible(verifyBtn);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() async {
      await tester.tap(verifyBtn);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('ZWERYFIKOWANO'), findsOneWidget);
    final loadBtn = find.text('Załaduj zapis do gry');
    expect(loadBtn, findsOneWidget);

    await tester.ensureVisible(loadBtn);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(loadBtn);
    await tester.pump(const Duration(milliseconds: 300));

    expect(importedResult, isNotNull);
    expect(importedResult!['saveId'], 'save_test_596');
    expect(importedResult!['teamName'], 'Polska Ekipa Pro');
  });

  testWidgets('shows integrity error for invalid PPMCS1 token', (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final tempDir = Directory.systemTemp.createTempSync('ppm_token_err_');
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    await tester.pumpWidget(
      buildTestHost(
        viewportSize: const Size(1024, 768),
        tempDir: tempDir,
        initialTab: CrossDeviceTransferTab.portableToken,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField).first, 'INVALID_TOKEN_123');
    await tester.tap(find.text('Dekoduj token'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Błędny token:'), findsOneWidget);
  });
}
