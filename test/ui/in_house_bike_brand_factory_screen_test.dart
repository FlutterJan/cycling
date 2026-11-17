import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/equipment/frame_model.dart';
import 'package:pro_peloton_manager/models/team/in_house_bike_brand_manufacturing_model.dart';
import 'package:pro_peloton_manager/ui/screens/in_house_bike_brand_factory_screen.dart';

void main() {
  group('FrameGeometryCalculator', () {
    test('evaluates aero vs climbing geometry and carbon grades accurately', () {
      final aeroEval = FrameGeometryCalculator.evaluate(
        spec: FrameGeometrySpec.presetForCategory(FrameCategory.aero),
        category: FrameCategory.aero,
        carbonGrade: CarbonLayupGrade.ultraHighModulusT1100,
        rdEngineeringLevel: 72,
      );
      final climbEval = FrameGeometryCalculator.evaluate(
        spec: FrameGeometrySpec.presetForCategory(
          FrameCategory.lightweightClimbing,
        ),
        category: FrameCategory.lightweightClimbing,
        carbonGrade: CarbonLayupGrade.ultraHighModulusT1100,
        rdEngineeringLevel: 72,
      );

      expect(aeroEval.aeroCdaModifier, lessThan(climbEval.aeroCdaModifier));
      expect(climbEval.estimatedWeightGrams, lessThan(aeroEval.estimatedWeightGrams));
      expect(aeroEval.uciLegal, isTrue);
      expect(climbEval.uciLegal, isTrue);
      expect(aeroEval.retailMsrpEur, greaterThan(aeroEval.wholesalePriceEur));
    });
  });

  group('InHouseBikeBrandFactoryScreen', () {
    Widget buildTestHost({
      required Size size,
      InHouseBikeBrandFactoryState? initialState,
      ValueChanged<InHouseBikeBrandFactoryState>? onStateChanged,
    }) {
      return ProviderScope(
        child: MediaQuery(
          data: MediaQueryData(size: size),
          child: MaterialApp(
            home: SizedBox(
              width: size.width,
              height: size.height,
              child: InHouseBikeBrandFactoryScreen(
                initialState: initialState,
                onStateChanged: onStateChanged,
              ),
            ),
          ),
        ),
      );
    }

    for (final viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders all tabs without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          void checkNoError() {
            expect(tester.takeException(), isNull);
          }

          await tester.pumpWidget(
            buildTestHost(
              size: viewport,
              initialState: InHouseBikeBrandFactoryState.initial(),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          checkNoError();
          expect(find.text('Infrastruktura Produkcyjna'), findsOneWidget);

          await tester.tap(find.text('Studio Geometrii'));
          await tester.pump(const Duration(milliseconds: 300));
          checkNoError();
          expect(find.text('Rysunek Techniczny CAD 2D'), findsOneWidget);

          await tester.tap(find.text('Licencje B2B'));
          await tester.pump(const Duration(milliseconds: 300));
          checkNoError();
          expect(find.text('Zapytania Ofertowe Drużyn'), findsOneWidget);

          await tester.tap(find.text('Sprzedaż & Finanse'));
          await tester.pump(const Duration(milliseconds: 300));
          checkNoError();
          expect(find.text('Historia Raportów Kwartalnych'), findsOneWidget);
        },
      );
    }

    testWidgets(
      'supports upgrading facility, starting R&D, signing license and simulating quarter',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        InHouseBikeBrandFactoryState latest =
            InHouseBikeBrandFactoryState.initial();

        await tester.pumpWidget(
          buildTestHost(
            size: const Size(1600, 900),
            initialState: latest,
            onStateChanged: (next) => latest = next,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        // 1. Start R&D project
        await tester.ensureVisible(find.text('Uruchom Projekt R&D'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.text('Uruchom Projekt R&D'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(latest.model.activeRdProjects.length, 1);

        // 2. Advance R&D days
        await tester.ensureVisible(find.text('+15 dni R&D'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.text('+15 dni R&D'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(latest.model.activeRdProjects.first.progressRatio, greaterThan(0.0));

        // 3. Sign external license
        await tester.ensureVisible(find.text('Licencje B2B'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.text('Licencje B2B'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.ensureVisible(find.textContaining('Podpisz Kontrakt').first);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.textContaining('Podpisz Kontrakt').first);
        await tester.pump(const Duration(milliseconds: 300));
        expect(latest.model.activeLicenseContracts.length, 1);

        // 4. Close quarter and check retail report
        await tester.ensureVisible(find.text('Sprzedaż & Finanse'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.text('Sprzedaż & Finanse'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.ensureVisible(find.textContaining('Zamknij Kwartał'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.textContaining('Zamknij Kwartał'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(latest.model.quarterlyReports.length, 2);
      },
    );
  });
}
