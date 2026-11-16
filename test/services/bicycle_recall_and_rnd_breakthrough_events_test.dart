import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/career/bicycle_recall_and_rnd_breakthrough_events.dart';
import 'package:pro_peloton_manager/state/career_state_notifier.dart';

void main() {
  const service = BicycleRecallAndRndBreakthroughEvents();

  const deal = BikeManufacturerDeal(
    manufacturerId: 'aero_works',
    manufacturerName: 'AeroWorks Carbon',
    prestigeLevel: 5,
    annualCashContributionEur: 1200000,
    freeBikesQuota: 90,
    researchAndDevelopmentLevel: 92,
    suppliedFrameIds: ['aw_sl8'],
    suppliedWheelsetIds: ['aw_60'],
    contractYearsLeft: 2,
    minimumUciRankingRequired: 10,
  );

  const staff = TeamStaff(
    trainersLevel: 85,
    sportsDirectorsLevel: 88,
    doctorsLevel: 82,
    mechanicsLevel: 86,
    scoutsLevel: 80,
  );

  group('BicycleRecallAndRndBreakthroughEvents unit tests', () {
    test('creates R&D aero fork breakthrough with -2.5% CdA before Tour de France', () {
      final date = DateTime(2026, 6, 18);
      final tdfStart = DateTime(2026, 7, 4);

      final event = service.createRndAeroBreakthroughEvent(
        date: date,
        manufacturerDeal: deal,
        component: RndPrototypeComponent.aeroForkPrototype,
        tourDeFranceStartDate: tdfStart,
      );

      expect(event.kind, TechnicalEventKind.rndAeroBreakthrough);
      expect(event.status, TechnicalEventStatus.pendingDecision);
      expect(event.impact.cdaMultiplier, 0.975);
      expect(event.impact.cdaDeltaPercent, -2.5);
      expect(event.deadlineDate, tdfStart.subtract(const Duration(days: 2)));
      expect(event.impact.uciHomologated, isTrue);

      final roundTrip = BicycleTechnicalEventRecord.fromJson(event.toJson());
      expect(roundTrip, event);
    });

    test('resolving R&D breakthrough applies 0.975 CdA multiplier and calculates watts saved', () {
      final date = DateTime(2026, 6, 20);
      final event = service.createRndAeroBreakthroughEvent(
        date: date,
        manufacturerDeal: deal,
        component: RndPrototypeComponent.aeroHandlebarCockpit,
      );

      final outcome = service.resolveRndBreakthrough(
        event: event,
        choice: RndBreakthroughChoice.deployBeforeTourDeFrance,
        actionDate: date.add(const Duration(days: 1)),
      );

      expect(outcome.updatedEvent.status, TechnicalEventStatus.activeInService);
      expect(outcome.cdaMultiplierApplied, 0.975);
      expect(outcome.budgetDeltaEur, 0);

      final effectiveMultiplier = service.computeEffectiveCdaMultiplier([
        outcome.updatedEvent,
      ]);
      expect(effectiveMultiplier, closeTo(0.975, 1e-6));

      final wattsSaved = service.estimateWattsSavedAtSpeed(effectiveMultiplier);
      expect(wattsSaved, greaterThan(6.0));
    });

    test('creates rim batch recall event and updates risk penalty on resolution', () {
      final date = DateTime(2026, 5, 12);
      final recall = service.createRimBatchRecallEvent(
        date: date,
        manufacturerDeal: deal,
        rimBatchCode: 'RIM-26-404-QC',
        affectedWheelsetCount: 24,
      );

      expect(recall.kind, TechnicalEventKind.rimBatchRecall);
      expect(recall.isUrgentRecall, isTrue);
      expect(recall.affectedWheelsetCount, 24);
      expect(recall.impact.mechanicalFailureRiskDelta, greaterThan(0.15));

      final urgentMsg = service.toInboxMessage(recall);
      expect(urgentMsg.priority, InboxPriority.urgent);

      final swapOutcome = service.resolveRimRecall(
        event: recall,
        choice: RecallActionChoice.emergencyFactorySwap,
        actionDate: date.add(const Duration(days: 1)),
      );

      expect(swapOutcome.updatedEvent.status, TechnicalEventStatus.resolved);
      expect(swapOutcome.updatedEvent.impact.mechanicalFailureRiskDelta, 0.0);
      expect(swapOutcome.budgetDeltaEur, lessThan(0));
      expect(
        service.computeMechanicalFailureRiskPenalty([swapOutcome.updatedEvent]),
        0.0,
      );
    });

    test('rollDailyTechnicalEvent can trigger events deterministically over pre-Tour window', () {
      var foundBreakthrough = false;
      var foundRecall = false;

      for (int day = 0; day < 2500; day++) {
        final currentDate = DateTime(2026, 6, 1).add(Duration(days: day % 28));
        final rolled = service.rollDailyTechnicalEvent(
          BicycleTechnicalEventContext(
            currentDate: currentDate,
            tourDeFranceStartDate: DateTime(2026, 7, 4),
            manufacturerDeal: deal,
            teamStaff: staff,
            teamDivision: TeamDivision.worldTour,
            currentTeamBudgetEur: 2500000,
            seed: 1000 + day,
          ),
        );
        if (rolled?.kind == TechnicalEventKind.rndAeroBreakthrough) {
          foundBreakthrough = true;
        }
        if (rolled?.kind == TechnicalEventKind.rimBatchRecall) {
          foundRecall = true;
        }
      }

      expect(foundBreakthrough, isTrue);
      expect(foundRecall, isTrue);
    });

    test('notifier manages events, filters, and cumulative CdA / risk state', () {
      final notifier = BicycleRecallAndRndNotifier();
      final date = DateTime(2026, 6, 15);
      final rndEvent = service.createRndAeroBreakthroughEvent(
        date: date,
        manufacturerDeal: deal,
        component: RndPrototypeComponent.aeroForkPrototype,
      );
      final recallEvent = service.createRimBatchRecallEvent(
        date: date,
        manufacturerDeal: deal,
        rimBatchCode: 'RIM-26-777-QC',
      );

      notifier.registerEvent(rndEvent);
      notifier.registerEvent(recallEvent);
      expect(notifier.state.events.length, 2);
      expect(notifier.state.pendingRecallCount, 1);

      notifier.decideRndBreakthrough(
        eventId: rndEvent.id,
        choice: RndBreakthroughChoice.deployBeforeTourDeFrance,
        actionDate: date,
      );
      expect(notifier.state.activeCdaMultiplier, closeTo(0.975, 1e-6));

      notifier.decideRimRecall(
        eventId: recallEvent.id,
        choice: RecallActionChoice.emergencyFactorySwap,
        actionDate: date,
      );
      expect(notifier.state.activeMechanicalRiskPenalty, 0.0);
      expect(notifier.state.totalSpentOnServiceEur, greaterThan(0));

      notifier.setFilter(TechnicalEventFilter.recalls);
      expect(notifier.state.filteredEvents.length, 1);
      expect(
        notifier.state.filteredEvents.first.kind,
        TechnicalEventKind.rimBatchRecall,
      );
    });
  });

  group('BicycleRecallAndRndBreakthroughPanel responsive widget tests', () {
    Widget buildTestHost({
      required Size size,
      required BicycleRecallAndRndState state,
      TechnicalEventFilter filter = TechnicalEventFilter.all,
      ValueChanged<TechnicalEventFilter>? onFilterChanged,
      void Function(String, RndBreakthroughChoice)? onRndDecision,
      void Function(String, RecallActionChoice)? onRecallDecision,
      bool isLocked = false,
    }) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: SingleChildScrollView(
                  child: BicycleRecallAndRndBreakthroughPanel(
                    state: state,
                    activeFilter: filter,
                    onFilterChanged: onFilterChanged ?? (_) {},
                    onRndDecision: onRndDecision ?? (_, __) {},
                    onRecallDecision: onRecallDecision ?? (_, __) {},
                    availableBudgetEur: 500000,
                    isInteractionLocked: isLocked,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final sampleDate = DateTime(2026, 6, 18);
    final sampleState = BicycleRecallAndRndState(
      events: [
        service.createRndAeroBreakthroughEvent(
          date: sampleDate,
          manufacturerDeal: deal,
          component: RndPrototypeComponent.aeroForkPrototype,
        ),
        service.createRimBatchRecallEvent(
          date: sampleDate,
          manufacturerDeal: deal,
          rimBatchCode: 'RIM-26-888-QC',
        ),
      ],
      activeCdaMultiplier: 1.0,
      activeMechanicalRiskPenalty: 0.22,
    );

    for (final viewport in [
      const Size(390, 844),
      const Size(1024, 768),
      const Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            buildTestHost(size: viewport, state: sampleState),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(
            find.text('Inżynieria R&D i Kontrola Jakości Sprzętu'),
            findsOneWidget,
          );
          expect(
            find.text('Przełom R&D: Nowy prototyp widelca aero (-2.5% CdA)'),
            findsOneWidget,
          );
          expect(
            find.text('PILNA AKCJA SERWISOWA: Wada fabryczna partii obręczy'),
            findsOneWidget,
          );
        },
      );
    }

    testWidgets('handles empty state, filter taps, and action callbacks', (
      tester,
    ) async {
      String? decidedRndId;
      RndBreakthroughChoice? rndChoice;
      TechnicalEventFilter? selectedFilter;

      await tester.pumpWidget(
        buildTestHost(
          size: const Size(1024, 768),
          state: sampleState,
          onFilterChanged: (f) => selectedFilter = f,
          onRndDecision: (id, choice) {
            decidedRndId = id;
            rndChoice = choice;
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Przełomy R&D'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(selectedFilter, TechnicalEventFilter.breakthroughs);

      await tester.tap(find.text('Wdróż przed Tour de France (-2.5% CdA)'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(decidedRndId, isNotNull);
      expect(rndChoice, RndBreakthroughChoice.deployBeforeTourDeFrance);

      await tester.pumpWidget(
        buildTestHost(
          size: const Size(390, 844),
          state: const BicycleRecallAndRndState(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Brak aktywnych biuletynów technicznych R&D'),
        findsOneWidget,
      );
    });
  });
}
