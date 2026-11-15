// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/ui/widgets/team_tactical_presets_bar.dart';

void main() {
  group('TeamTacticalPresetsBar - Pasek Szybkich Rozkazów Drużyny (1-Click Tactics)', () {
    Widget buildTestBar({
      List<TeamRosterMember>? roster,
      TeamTacticalPreset? activePreset,
      ValueChanged<TeamTacticalPreset>? onPresetSelected,
      ValueChanged<TeamTacticalPlan>? onPlanExecuted,
      VoidCallback? onResetTactics,
      bool isCompact = false,
      double width = 800,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: TeamTacticalPresetsBar(
                roster: roster ?? TeamRosterMember.demoRoster(),
                activePreset: activePreset,
                onPresetSelected: onPresetSelected,
                onPlanExecuted: onPlanExecuted,
                onResetTactics: onResetTactics,
                isCompact: isCompact,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renderuje nagłówek i 4 wymagane taktyki 1-Click Team Tactics', (tester) async {
      await tester.pumpWidget(buildTestBar());
      await tester.pumpAndSettle();

      expect(find.text('TAKTYKI DRUŻYNY • 1-CLICK TEAM TACTICS'), findsOneWidget);

      // 4 główne rozkazy
      expect(find.text('Uformuj Pociąg Górski'), findsOneWidget);
      expect(find.text('Uformuj Pociąg Sprinterski'), findsOneWidget);
      expect(find.text('Złóż Wachlarz (Echelon Attack)'), findsOneWidget);
      expect(find.text('Wszyscy chrońcie Lidera'), findsOneWidget);
    });

    testWidgets('Uformuj Pociąg Górski automatycznie ustawia kolarzy od najsłabszego do lidera', (tester) async {
      TeamTacticalPreset? selectedPreset;
      TeamTacticalPlan? executedPlan;

      await tester.pumpWidget(buildTestBar(
        onPresetSelected: (p) => selectedPreset = p,
        onPlanExecuted: (plan) => executedPlan = plan,
      ));
      await tester.pumpAndSettle();

      // Kliknięcie w pociąg górski
      await tester.tap(find.byKey(const Key('preset_mountain_train')));
      await tester.pumpAndSettle();

      expect(selectedPreset, equals(TeamTacticalPreset.mountainTrain));
      expect(executedPlan, isNotNull);
      expect(executedPlan!.preset, equals(TeamTacticalPreset.mountainTrain));

      // Sprawdzenie 8 kolarzy w planie
      expect(executedPlan!.assignments.length, equals(8));

      // Pierwszy kolarz na czele (najsłabszy wspinacz) nadaje tempo (pullGroup)
      final firstRider = executedPlan!.assignments.first;
      expect(firstRider.trainPosition, equals(1));
      expect(firstRider.order, equals(TacticalOrder.pullGroup));

      // Ostatni kolarz w pociągu (lider GC - Pogačar) chroniony na końcu (saveEnergy)
      final lastRider = executedPlan!.assignments.last;
      expect(lastRider.trainPosition, equals(8));
      expect(lastRider.order, equals(TacticalOrder.saveEnergy));
      expect(lastRider.riderName, equals('T. Pogačar'));
      expect(lastRider.roleName, contains('Lider GC'));

      // Wyświetla się komunikat radiowy DS
      expect(find.textContaining('Dyrektor Sportowy: "Panowie, formujemy pociąg górski'), findsOneWidget);

      // Widoczna plakietka AKTYWNA oraz przycisk podglądu pociągu
      expect(find.text('AKTYWNA'), findsOneWidget);
      expect(find.byKey(const Key('button_view_train_roster')), findsOneWidget);
    });

    testWidgets('Uformuj Pociąg Sprinterski przygotowuje lead-out pod wyznaczonego sprintera', (tester) async {
      TeamTacticalPlan? executedPlan;

      await tester.pumpWidget(buildTestBar(
        onPlanExecuted: (plan) => executedPlan = plan,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('preset_sprint_train')));
      await tester.pumpAndSettle();

      expect(executedPlan, isNotNull);
      expect(executedPlan!.preset, equals(TeamTacticalPreset.sprintTrain));

      // Sprinter (Molano) na końcu pociągu (pozycja 8) z rozkazem holdPosition
      final sprinterAssignment = executedPlan!.assignments.last;
      expect(sprinterAssignment.riderName, equals('J. S. Molano'));
      expect(sprinterAssignment.specialization, equals(RiderSpecialization.pureSprinter));
      expect(sprinterAssignment.roleName, contains('Sprinter'));
      expect(sprinterAssignment.order, equals(TacticalOrder.holdPosition));

      // Przedostatni kolarz to Ostatni Pilot z wysoką mocą nadprogową (120% FTP)
      final pilot = executedPlan!.assignments[executedPlan!.assignments.length - 2];
      expect(pilot.roleName, contains('Pilot'));
      expect(pilot.targetEffortPercent, equals(120.0));
      expect(pilot.order, equals(TacticalOrder.pullGroup));
    });

    testWidgets('Złóż Wachlarz (Echelon Attack) rozstawia drużynę na wietrze bocznym', (tester) async {
      TeamTacticalPlan? executedPlan;

      await tester.pumpWidget(buildTestBar(
        onPlanExecuted: (plan) => executedPlan = plan,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('preset_echelon_attack')));
      await tester.pumpAndSettle();

      expect(executedPlan, isNotNull);
      expect(executedPlan!.preset, equals(TeamTacticalPreset.echelonAttack));

      // Czołowe 4 pozycje rotują na wietrze na 112% FTP
      final frontEchelonRider = executedPlan!.assignments.first;
      expect(frontEchelonRider.targetEffortPercent, equals(112.0));
      expect(frontEchelonRider.order, equals(TacticalOrder.pullGroup));

      expect(find.textContaining('Wiatr boczny! Wszyscy na prawy rant szosy'), findsOneWidget);
    });

    testWidgets('Wszyscy chrońcie Lidera przydziela rozkaz ochrony lidera całemu zespołowi', (tester) async {
      TeamTacticalPlan? executedPlan;

      await tester.pumpWidget(buildTestBar(
        onPlanExecuted: (plan) => executedPlan = plan,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('preset_protect_leader')));
      await tester.pumpAndSettle();

      expect(executedPlan, isNotNull);
      expect(executedPlan!.preset, equals(TeamTacticalPreset.protectLeader));

      // Wszyscy pomocnicy otrzymują rozkaz protectLeader
      final domestiques = executedPlan!.assignments.where((a) => a.order == TacticalOrder.protectLeader).toList();
      expect(domestiques.length, equals(7));

      // Lider jedzie w eskorcie (followWheels)
      final leader = executedPlan!.assignments.firstWhere((a) => a.roleName.contains('Lider'));
      expect(leader.order, equals(TacticalOrder.followWheels));
      expect(leader.riderName, equals('T. Pogačar'));

      expect(find.textContaining('ALARM W DRUŻYNIE! Lider ma defekt/kraksę'), findsOneWidget);
    });

    testWidgets('kliknięcie Pociąg (8) otwiera modal z pełnym składem 8 kolarzy', (tester) async {
      await tester.pumpWidget(buildTestBar());
      await tester.pumpAndSettle();

      // Uruchomienie pociągu górskiego
      await tester.tap(find.byKey(const Key('preset_mountain_train')));
      await tester.pumpAndSettle();

      // Kliknięcie przycisku podglądu pociągu
      final trainButton = find.byKey(const Key('button_view_train_roster'));
      expect(trainButton, findsOneWidget);
      await tester.tap(trainButton);
      await tester.pumpAndSettle();

      // Modal powinien wyświetlać 8 kolarzy z numerami pozycji w pociągu
      expect(find.text('Skład formacji drużynowej (8 kolarzy)'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#8'), findsOneWidget);
      expect(find.text('T. Pogačar'), findsOneWidget);
      expect(find.text('R. Majka'), findsOneWidget);
    });

    testWidgets('przycisk Neutralny anuluje aktywną taktykę i resetuje stan', (tester) async {
      bool resetCalled = false;

      await tester.pumpWidget(buildTestBar(
        onResetTactics: () => resetCalled = true,
      ));
      await tester.pumpAndSettle();

      // Uruchomienie taktyki
      await tester.tap(find.byKey(const Key('preset_sprint_train')));
      await tester.pumpAndSettle();
      expect(find.text('AKTYWNA'), findsOneWidget);

      // Kliknięcie w przycisk "Neutralny"
      await tester.tap(find.byKey(const Key('button_reset_tactics')));
      await tester.pumpAndSettle();

      expect(resetCalled, isTrue);
      expect(find.text('AKTYWNA'), findsNothing);
      expect(find.byKey(const Key('button_view_train_roster')), findsNothing);
    });
  });
}

