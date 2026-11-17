import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/ui/widgets/quick_tactical_macro_recorder_widget.dart';

void main() {
  group('QuickTacticalMacroManager & Models', () {
    test('JSON round-trip preserves QuickTacticalMacro and TacticalMacroStep', () {
      final macros = QuickTacticalMacroManager.defaultTeamMacros();
      final jsonString = QuickTacticalMacroManager.exportMacrosToJson(macros);
      final restored = QuickTacticalMacroManager.importMacrosFromJson(jsonString);

      expect(restored.length, macros.length);
      expect(restored.first.id, macros.first.id);
      expect(restored.first.name, macros.first.name);
      expect(restored.first.category, macros.first.category);
      expect(restored.first.steps.length, macros.first.steps.length);
      expect(restored.first.steps.first.order, macros.first.steps.first.order);
      expect(
        restored.first.steps.first.targetEffortPercent,
        macros.first.steps.first.targetEffortPercent,
      );
    });

    test('importMacrosFromJson throws FormatException on non-list JSON', () {
      expect(
        () => QuickTacticalMacroManager.importMacrosFromJson('{"invalid": true}'),
        throwsFormatException,
      );
    });

    test('validateMacro catches empty name, long name, and empty steps', () {
      const sampleStep = TacticalMacroStep(
        id: 's1',
        stepIndex: 0,
        targetId: MacroTargetScope.allTeam,
        targetLabel: 'Cała drużyna',
        order: TacticalOrder.attack,
        targetEffortPercent: 110,
      );

      expect(
        QuickTacticalMacroManager.validateMacro(name: '   ', steps: [sampleStep]),
        isNotNull,
      );
      expect(
        QuickTacticalMacroManager.validateMacro(
          name: 'A' * 49,
          steps: [sampleStep],
        ),
        isNotNull,
      );
      expect(
        QuickTacticalMacroManager.validateMacro(name: 'Kontra', steps: const []),
        isNotNull,
      );
      expect(
        QuickTacticalMacroManager.validateMacro(
          name: 'Kontra na przełęczy',
          steps: [sampleStep],
        ),
        isNull,
      );
    });

    test('countAffectedRiders counts active riders matching scopes', () {
      final roster = [
        const MacroTeamRiderSlot(
          id: 'r1',
          name: 'Lider',
          bibNumber: 1,
          roleLabel: 'GC',
          isLeader: true,
          isActive: true,
        ),
        const MacroTeamRiderSlot(
          id: 'r2',
          name: 'Pomocnik 1',
          bibNumber: 2,
          roleLabel: 'Dom',
          isLeader: false,
          isActive: true,
        ),
        const MacroTeamRiderSlot(
          id: 'r3',
          name: 'Wycofany',
          bibNumber: 3,
          roleLabel: 'Dom',
          isLeader: false,
          isActive: false,
        ),
      ];

      final macro = QuickTacticalMacro(
        id: 'm1',
        name: 'Test',
        category: TacticalMacroCategory.attack,
        createdAt: DateTime(2026, 1, 1),
        steps: const [
          TacticalMacroStep(
            id: 's1',
            stepIndex: 0,
            targetId: MacroTargetScope.allTeam,
            targetLabel: 'Cała drużyna',
            order: TacticalOrder.pullGroup,
            targetEffortPercent: 95,
          ),
        ],
      );

      expect(QuickTacticalMacroManager.countAffectedRiders(macro, roster), 2);
    });
  });

  group('QuickTacticalMacroRecorderWidget UI', () {
    Widget buildTestHost({
      required Size size,
      List<QuickTacticalMacro>? initialMacros,
      List<MacroTeamRiderSlot>? roster,
      bool enabled = true,
      ValueChanged<MacroExecutionResult>? onExecuteMacro,
      ValueChanged<TacticalMacroStep>? onApplyStep,
      ValueChanged<List<QuickTacticalMacro>>? onMacrosChanged,
    }) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: QuickTacticalMacroRecorderWidget(
                  roster: roster ?? QuickTacticalMacroManager.defaultRoster(),
                  initialMacros: initialMacros,
                  enabled: enabled,
                  onExecuteMacro: onExecuteMacro,
                  onApplyStep: onApplyStep,
                  onMacrosChanged: onMacrosChanged,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('records steps and saves a new tactical macro', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      List<QuickTacticalMacro>? updatedMacros;
      await tester.pumpWidget(
        buildTestHost(
          size: const Size(1280, 900),
          onMacrosChanged: (list) => updatedMacros = list,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Start recording
      await tester.tap(find.text('Nagraj Makro'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Studio Przechwytywania Kroków'), findsOneWidget);

      // Capture two tactical orders
      await tester.tap(find.text(TacticalOrder.pullGroup.label));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text(TacticalOrder.attack.label));
      await tester.pump(const Duration(milliseconds: 250));

      // Enter macro name and save
      await tester.enterText(
        find.widgetWithText(TextField, 'Nazwa makra'),
        'Atak Finiszowy',
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Zapisz Makro'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Atak Finiszowy'), findsOneWidget);
      expect(updatedMacros, isNotNull);
      expect(updatedMacros!.first.name, 'Atak Finiszowy');
      expect(updatedMacros!.first.steps.length, 2);
    });

    testWidgets('executes macro with one click and triggers callbacks',
        (tester) async {
      MacroExecutionResult? executed;
      final appliedSteps = <TacticalMacroStep>[];

      await tester.pumpWidget(
        buildTestHost(
          size: const Size(1280, 820),
          onExecuteMacro: (res) => executed = res,
          onApplyStep: appliedSteps.add,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Odpal').first);
      await tester.pump(const Duration(milliseconds: 350));

      expect(executed, isNotNull);
      expect(executed!.affectedRidersCount, 6);
      expect(appliedSteps, isNotEmpty);

      // Allow playback timer to finish cleanly
      await tester.pump(const Duration(milliseconds: 1200));
    });

    testWidgets('renders empty state and disabled state cleanly', (tester) async {
      MacroExecutionResult? executed;
      await tester.pumpWidget(
        buildTestHost(
          size: const Size(1024, 768),
          initialMacros: const [],
          enabled: false,
          onExecuteMacro: (res) => executed = res,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Brak zapisanych makr w tej kategorii'), findsOneWidget);
      await tester.tap(find.text('Nagraj Makro'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Studio Przechwytywania Kroków'), findsNothing);
      expect(executed, isNull);
    });

    for (final viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(buildTestHost(size: viewport));
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.text('Nagrywarka Makr Taktycznych'), findsOneWidget);
        },
      );
    }
  });
}
