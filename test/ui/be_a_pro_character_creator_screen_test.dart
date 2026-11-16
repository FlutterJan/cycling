import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/pro_cyclist_career_state.dart';
import 'package:pro_peloton_manager/ui/screens/be_a_pro_character_creator_screen.dart';

void main() {
  group('BeAProPhysicsCalculator & BeAProCharacterDraft', () {
    test('weight and height physically drive CdA and mountain vs flat balance', () {
      final lightClimber = BeAProPhysicsCalculator.evaluate(
        heightCm: 168.0,
        weightKg: 55.0,
        archetype: BeAProGeneticArchetype.alpineClimber,
      );
      final heavyRouleur = BeAProPhysicsCalculator.evaluate(
        heightCm: 192.0,
        weightKg: 82.0,
        archetype: BeAProGeneticArchetype.alpineClimber,
      );

      expect(lightClimber.baseCdaHoodsM2, lessThan(heavyRouleur.baseCdaHoodsM2));
      expect(lightClimber.bodySurfaceAreaM2, lessThan(heavyRouleur.bodySurfaceAreaM2));
      expect(lightClimber.wattsPerKg, greaterThan(heavyRouleur.wattsPerKg));
      expect(
        lightClimber.mountainPredisposition,
        greaterThan(heavyRouleur.mountainPredisposition),
      );
      expect(
        heavyRouleur.estimatedFtpWatts,
        greaterThan(lightClimber.estimatedFtpWatts),
      );
    });

    test('all 5 genetic archetypes have exact labels and build valid U23 career', () {
      expect(
        BeAProGeneticArchetype.values.map((e) => e.label).toList(),
        [
          'Alpejski Góral',
          'Klasykowiec Północy',
          'Wybuchowy Puncheur',
          'Sprinter',
          'Specjalista ITT / All-Rounder',
        ],
      );

      const draft = BeAProCharacterDraft(
        firstName: 'Michał',
        lastName: 'Zieliński',
        nationalityIso: 'POL',
        heightCm: 174.0,
        weightKg: 60.0,
        archetype: BeAProGeneticArchetype.alpineClimber,
        faceShapeIndex: 2,
        hairStyleIndex: 3,
        glassesModelId: 'pro_shield',
        shoeColorHex: '#D4AF37',
        selectedTeamId: 'u23_alpen_tyrol',
      );

      final result = draft.buildCareerResult(startDate: DateTime(2026, 1, 15));
      expect(result.playerRider.fullName, 'Michał Zieliński');
      expect(result.playerRider.appearance.faceShapeIndex, 2);
      expect(result.playerRider.appearance.hairStyleIndex, 3);
      expect(result.playerRider.appearance.glassesModelId, 'pro_shield');
      expect(result.playerRider.appearance.shoeColorHex, '#D4AF37');
      expect(result.careerState.careerTier, ProCyclistCareerTier.u23Continental);
      expect(result.careerState.currentTeamId, 'u23_alpen_tyrol');
    });
  });

  group('BeAProCharacterCreatorScreen responsive & interactive tests', () {
    Future<void> pumpScreenAtSize(
      WidgetTester tester,
      Size size, {
      void Function(BeAProCreatorResult)? onCareerCreated,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: BeAProCharacterCreatorScreen(
            onCareerCreated: onCareerCreated,
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
      testWidgets('renders without overflow at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        await pumpScreenAtSize(tester, size);
        expect(find.byType(BeAProCharacterCreatorScreen), findsOneWidget);
        final err = tester.takeException();
        expect(err, isNull, reason: err?.toString());
      });
    }

    testWidgets('can complete full 4-step creator flow and submit U23 career', (tester) async {
      BeAProCreatorResult? capturedResult;
      await pumpScreenAtSize(
        tester,
        const Size(1600, 900),
        onCareerCreated: (res) => capturedResult = res,
      );

      // Step 1 -> Step 2 (Archetyp)
      await tester.tap(find.text('Dalej: Archetyp'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Alpejski Góral'), findsOneWidget);

      await tester.tap(find.text('Alpejski Góral'));
      await tester.pump(const Duration(milliseconds: 200));

      // Step 2 -> Step 3 (Wygląd 3D)
      await tester.tap(find.text('Dalej: Wygląd 3D'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Kolor butów kolarskich (widoczne na modelu 3D)'), findsOneWidget);

      // Step 3 -> Step 4 (Drużyna U23)
      await tester.tap(find.text('Dalej: Drużyna U23'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Flanders Cobbles Espoirs'), findsOneWidget);

      await tester.tap(find.text('Flanders Cobbles Espoirs'));
      await tester.pump(const Duration(milliseconds: 200));

      // Submit
      await tester.tap(find.text('Rozpocznij Karierę U23'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(capturedResult, isNotNull);
      expect(capturedResult!.selectedTeam.id, 'u23_flanders_espoirs');
      expect(capturedResult!.careerState.currentTeamName, 'Flanders Cobbles Espoirs');
    });
  });
}
