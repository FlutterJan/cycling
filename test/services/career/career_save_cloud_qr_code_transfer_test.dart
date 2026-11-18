import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/services/career/career_save_cloud_qr_code_transfer.dart';

void main() {
  group('CareerSaveCloudQrCodeTransfer', () {
    const service = CareerSaveCloudQrCodeTransfer();

    test('eksport i skanowanie profilu Be a Pro działa w pełnym round-tripie', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(careerSaveCloudQrTransferProvider.notifier);
      notifier.selectMode(TransferPayloadKind.beAProProfile);
      notifier.generateDemoExportForActiveMode();

      final state = container.read(careerSaveCloudQrTransferProvider);
      final bundle = state.currentExportBundle;
      expect(bundle, isNotNull);
      expect(bundle!.token.startsWith('PPM1:BAP.'), isTrue);
      expect(service.verifyQrMatrixStructure(bundle.qrMatrix), isTrue);

      final scan = service.decodeToken(bundle.token);
      expect(scan.isValid, isTrue);
      expect(scan.status, TransferScanValidationStatus.valid);
      expect(scan.envelope?.beAProSnapshot, isNotNull);
      expect(
        scan.envelope!.beAProSnapshot!.playerRider.fullName,
        'Kacper Majewski',
      );
      expect(
        scan.envelope!.beAProSnapshot!.toProCyclistCareerState().careerName,
        'Droga po Żółtą Koszulkę',
      );
    });

    test('eksport i skanowanie składu wyścigowego drużyny zachowuje wszystkich kolarzy', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(careerSaveCloudQrTransferProvider.notifier);
      notifier.selectMode(TransferPayloadKind.teamRaceRoster);
      notifier.generateDemoExportForActiveMode();

      final bundle =
          container.read(careerSaveCloudQrTransferProvider).currentExportBundle!;
      expect(bundle.token.startsWith('PPM1:TRS.'), isTrue);
      expect(service.verifyQrMatrixStructure(bundle.qrMatrix), isTrue);

      final scan = service.decodeToken('  ${bundle.token}\n  ');
      expect(scan.isValid, isTrue);
      final roster = scan.envelope!.teamRosterSnapshot!;
      expect(roster.teamName, 'Obsidian Sovereign Cycling');
      expect(roster.raceRoster.length, 4);
      expect(roster.leaderRiderId, 'r_1');
      expect(roster.sprinterRiderId, 'r_4');
      expect(roster.averageFtpWkg, greaterThan(5.0));
    });

    test('walidator tokenów wykrywa błędy formatu, Base64 i sumy CRC32', () {
      expect(
        service.decodeToken('   ').status,
        TransferScanValidationStatus.emptyInput,
      );
      expect(
        service.decodeToken('INVALID_TOKEN').status,
        TransferScanValidationStatus.invalidPrefix,
      );
      expect(
        service.decodeToken('PPM9:BAP.abc.00000000').status,
        TransferScanValidationStatus.unsupportedVersion,
      );
      expect(
        service.decodeToken('PPM1:BAP.%%%BAD%%%.12345678').status,
        TransferScanValidationStatus.corruptedBase64,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(careerSaveCloudQrTransferProvider.notifier)
          .generateDemoExportForActiveMode();
      final validToken = container
          .read(careerSaveCloudQrTransferProvider)
          .currentExportBundle!
          .token;

      final tampered =
          '${validToken.substring(0, validToken.length - 2)}FF';
      expect(
        service.decodeToken(tampered).status,
        TransferScanValidationStatus.checksumMismatch,
      );
    });

    test('generator QR obsługuje różne poziomy korekcji błędów L/M/Q/H', () {
      for (final level in TransferQrErrorCorrectionLevel.values) {
        final matrix = QrCodeMatrixGenerator.generate(
          'PPM1:BAP.eJwLAAAAAA.00000000',
          errorCorrectionLevel: level,
        );
        expect(service.verifyQrMatrixStructure(matrix), isTrue);
        expect(matrix.errorCorrectionLevel, level);
      }
    });
  });

  group('CareerSaveCloudQrCodeTransferPanel UI responsiveness', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CareerSaveCloudQrCodeTransferPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    }

    testWidgets('renderuje się bez overflow w 390x844 (mobile)', (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.textContaining('Szybki Transfer QR'), findsOneWidget);
    });

    testWidgets('renderuje się bez overflow w 1024x768 (tablet)', (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.textContaining('Generator Kodu QR'), findsOneWidget);
    });

    testWidgets('renderuje się bez overflow w 1600x900 (desktop)', (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(find.textContaining('Skaner & Importer Tokena'), findsOneWidget);
    });
  });
}
