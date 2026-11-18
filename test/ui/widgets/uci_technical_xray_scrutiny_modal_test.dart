import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/ui/widgets/uci_technical_xray_scrutiny_modal.dart';

void main() {
  Widget wrapWithSize(Widget child, Size size) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  group('UciTechnicalXrayScrutinyModal', () {
    testWidgets(
      'displays X-Ray zones, cockpit alarm, and resolves after torque correction',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1600, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        UciXrayScrutinyModalResult? completedResult;

        await tester.pumpWidget(
          wrapWithSize(
            UciTechnicalXrayScrutinyModal(
              autoStartScan: false,
              inspectionRecord:
                  UciTechnicalXrayScrutinyModal.buildDefaultPreStartRecord(
                withCockpitAlarm: true,
              ),
              onCompleted: (result) => completedResult = result,
            ),
            const Size(1600, 900),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text('KONTROLA TECHNICZNA UCI — SKANER X-RAY'),
          findsOneWidget,
        );
        expect(find.text('Suport (mufa suportowa)'), findsOneWidget);
        expect(find.text('Rura podsiodłowa i sztyca'), findsOneWidget);
        expect(find.text('Piasty i tylny napęd'), findsOneWidget);
        expect(find.text('Kokpit i klamki kierownicy'), findsOneWidget);
        expect(
          find.text('ALARM UCI: NIEREGULAMINOWE USTAWIENIE KOKPITU'),
          findsOneWidget,
        );
        expect(find.text('UCI OK'), findsNWidgets(3));
        expect(find.text('ALARM'), findsOneWidget);

        // Dopuść do startu jest zablokowane przed korektą kokpitu
        await tester.tap(find.text('Dopuść do startu'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(completedResult, isNull);

        // Wykonaj korektę kluczem dynamometrycznym
        await tester.tap(find.text('Korekta kokpitu (klucz dynamometryczny)'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text('ALARM UCI: NIEREGULAMINOWE USTAWIENIE KOKPITU'),
          findsNothing,
        );
        expect(find.text('UCI OK'), findsNWidgets(4));

        // Teraz dopuszczenie do startu działa
        await tester.tap(find.text('Dopuść do startu'));
        await tester.pump(const Duration(milliseconds: 200));

        expect(completedResult, isNotNull);
        expect(
          completedResult!.action,
          UciXrayScrutinyModalAction.torqueCorrectionApplied,
        );
        expect(completedResult!.cockpitCorrected, isTrue);
      },
    );

    testWidgets(
      'allows immediate start clearance when all UCI zones are compliant',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1600, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        UciXrayScrutinyModalResult? completedResult;

        await tester.pumpWidget(
          wrapWithSize(
            UciTechnicalXrayScrutinyModal(
              autoStartScan: false,
              inspectionRecord:
                  UciTechnicalXrayScrutinyModal.buildDefaultPreStartRecord(
                withCockpitAlarm: false,
              ),
              onCompleted: (result) => completedResult = result,
            ),
            const Size(1024, 768),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('ZGODNOŚĆ UCI POTWIERDZONA'), findsOneWidget);
        expect(find.text('UCI OK'), findsNWidgets(4));

        await tester.tap(find.text('Piasty i tylny napęd'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          find.text('Tylna i przednia piasta wolne od pola elektromagnetycznego.'),
          findsOneWidget,
        );

        await tester.tap(find.text('Dopuść do startu'));
        await tester.pump(const Duration(milliseconds: 200));

        expect(completedResult, isNotNull);
        expect(
          completedResult!.action,
          UciXrayScrutinyModalAction.clearedForStart,
        );
        expect(completedResult!.cockpitCorrected, isFalse);
      },
    );

    for (final viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(viewport);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            wrapWithSize(
              UciTechnicalXrayScrutinyModal(
                autoStartScan: true,
                inspectionRecord:
                    UciTechnicalXrayScrutinyModal.buildDefaultPreStartRecord(
                  withCockpitAlarm: true,
                ),
              ),
              viewport,
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.byType(UciTechnicalXrayScrutinyModal), findsOneWidget);
        },
      );
    }
  });
}
