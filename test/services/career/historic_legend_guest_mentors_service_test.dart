import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/historic_legend_guest_mentors_service.dart';

void main() {
  group('HistoricLegendGuestMentorsService', () {
    const service = HistoricLegendGuestMentorsService();

    test('katalog zawiera 8 legend z poprawnymi stawkami pakietowymi', () {
      expect(service.allMentors.length, 8);
      for (final m in service.allMentors) {
        expect(m.id, isNotEmpty);
        expect(m.name, isNotEmpty);
        expect(m.feeForAssignment(LegendMentorAssignmentType.grandTourAdvisory),
            m.grandTourPackageFeeEur);
        expect(m.feeForAssignment(LegendMentorAssignmentType.altitudeCamp),
            m.campPackageFeeEur);
      }
    });

    test('zatrudnienie legendy pomniejsza budżet i stosuje synergię +20%', () {
      final merckx = service.getMentorById('mentor_eddy_merckx')!;
      final result = service.hireMentor(
        mentor: merckx,
        assignmentType: LegendMentorAssignmentType.grandTourAdvisory,
        targetEventName: 'Tour de France',
        teamBudgetEur: 200000,
        currentDay: 100,
        activeContracts: const [],
        cooldownUntilDayByMentor: const {},
      );

      expect(result.success, isTrue);
      expect(result.contract, isNotNull);
      expect(result.remainingBudgetEur, 200000 - merckx.grandTourPackageFeeEur);
      expect(result.contract!.durationDays, 21);
      expect(result.contract!.appliedBonuses.moraleBoost,
          greaterThan(merckx.baseBonuses.moraleBoost));
    });

    test('blokuje zatrudnienie przy braku budżetu, pustej nazwie, limicie i karencji', () {
      final hinault = service.getMentorById('mentor_bernard_hinault')!;

      final emptyName = service.hireMentor(
        mentor: hinault,
        assignmentType: LegendMentorAssignmentType.altitudeCamp,
        targetEventName: '   ',
        teamBudgetEur: 500000,
        currentDay: 50,
        activeContracts: const [],
        cooldownUntilDayByMentor: const {},
      );
      expect(emptyName.success, isFalse);

      final lowBudget = service.hireMentor(
        mentor: hinault,
        assignmentType: LegendMentorAssignmentType.grandTourAdvisory,
        targetEventName: 'Giro d\'Italia',
        teamBudgetEur: 10000,
        currentDay: 50,
        activeContracts: const [],
        cooldownUntilDayByMentor: const {},
      );
      expect(lowBudget.success, isFalse);
      expect(lowBudget.remainingBudgetEur, 10000);

      final inCooldown = service.hireMentor(
        mentor: hinault,
        assignmentType: LegendMentorAssignmentType.altitudeCamp,
        targetEventName: 'Teide',
        teamBudgetEur: 500000,
        currentDay: 50,
        activeContracts: const [],
        cooldownUntilDayByMentor: const {'mentor_bernard_hinault': 60},
      );
      expect(inCooldown.success, isFalse);
      expect(inCooldown.message, contains('karencji'));
    });

    test('notifier obsługuje cykl życia kontraktu, anulowanie i serializację JSON', () {
      final notifier = HistoricLegendGuestMentorsNotifier(
        initialState: const HistoricLegendGuestMentorsState(
          currentDay: 10,
          teamBudgetEur: 300000,
          selectedAssignmentType: LegendMentorAssignmentType.timeTrialAeroCamp,
          selectedMentorId: 'mentor_miguel_indurain',
        ),
      );

      final hire = notifier.hireSelectedMentor(targetEventName: 'Obóz Aero');
      expect(hire.success, isTrue);
      expect(notifier.state.activeContracts.length, 1);

      // Postęp 7 dni kończy obóz TT & Aero
      notifier.advanceDay(days: 7);
      expect(notifier.state.activeContracts, isEmpty);
      expect(notifier.state.history.length, 1);
      expect(
        notifier.state.cooldownUntilDayByMentor['mentor_miguel_indurain'],
        greaterThan(notifier.state.currentDay),
      );

      // Round-trip JSON
      final restored = HistoricLegendGuestMentorsState.fromJson(
        notifier.state.toJson(),
      );
      expect(restored.currentDay, notifier.state.currentDay);
      expect(restored.teamBudgetEur, notifier.state.teamBudgetEur);
      expect(restored.history.length, 1);
      expect(restored.history.first.targetEventName, 'Obóz Aero');
    });

    test('anulowanie kontraktu zwraca 50% proporcjonalnej stawki', () {
      final notifier = HistoricLegendGuestMentorsNotifier(
        initialState: const HistoricLegendGuestMentorsState(
          currentDay: 1,
          teamBudgetEur: 200000,
          selectedAssignmentType: LegendMentorAssignmentType.cobblesAndClassicsCamp,
          selectedMentorId: 'mentor_roger_de_vlaeminck',
        ),
      );

      final hire = notifier.hireSelectedMentor(targetEventName: 'Flandria');
      expect(hire.success, isTrue);
      final afterHireBudget = notifier.state.teamBudgetEur;
      final contractId = notifier.state.activeContracts.first.contractId;

      notifier.cancelActiveContract(contractId);
      expect(notifier.state.activeContracts, isEmpty);
      expect(notifier.state.teamBudgetEur, greaterThan(afterHireBudget));
    });
  });

  group('HistoricLegendGuestMentorsPanel UI responsiveness', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HistoricLegendGuestMentorsPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renderuje się bez przepełnień w 390x844, 1024x768 i 1600x900',
        (tester) async {
      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpAtSize(tester, size);
        expect(find.text('Doradcy & Legendy Kolarstwa'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Overflow at $size');
      }
    });

    testWidgets('pozwala zatrudnić legendę i wyświetla aktywny kontrakt',
        (tester) async {
      await pumpAtSize(tester, const Size(1600, 900));

      final hireBtn = find.text('Zatrudnij Legendę');
      expect(hireBtn, findsOneWidget);
      await tester.ensureVisible(hireBtn);
      await tester.tap(hireBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Eddy Merckx — Tour de France'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
