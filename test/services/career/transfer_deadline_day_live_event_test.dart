import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/services/career/transfer_deadline_day_live_event.dart';

void main() {
  group('TransferDeadlineDayLiveEventService', () {
    const service = TransferDeadlineDayLiveEventService();

    test('createInitialState populates offers, ticker and full countdown', () {
      final state = service.createInitialState();

      expect(state.remainingWindowMinutes, 720);
      expect(state.formattedCountdown, '12h 00m');
      expect(state.currentClockLabel, '12:00');
      expect(state.currentPhase, DeadlinePhase.openingHours);
      expect(state.offers.length, greaterThanOrEqualTo(5));
      expect(state.tickerFeed, isNotEmpty);
      expect(state.selectedOfferId, state.offers.first.id);
    });

    test('JSON serialization round-trip preserves full state', () {
      final original = service.createInitialState();
      final decoded = TransferDeadlineDayState.fromJson(original.toJson());

      expect(decoded.remainingWindowMinutes, original.remainingWindowMinutes);
      expect(decoded.offers.length, original.offers.length);
      expect(decoded.offers.first.riderName, original.offers.first.riderName);
      expect(decoded.tickerFeed.length, original.tickerFeed.length);
      expect(decoded.remainingWageBudgetEur, original.remainingWageBudgetEur);
    });

    test('advanceTime decrements window and expires timed-out offers', () {
      var state = service.createInitialState();
      state = service.advanceTime(state, minutes: 70, seed: 42);

      expect(state.remainingWindowMinutes, 650);
      expect(state.formattedCountdown, '10h 50m');
      final theo = state.offers.firstWhere((o) => o.id == 'dl_offer_4');
      expect(
        theo.status == DeadlineOfferStatus.expired ||
            theo.status == DeadlineOfferStatus.hijackedByRival,
        isTrue,
      );
    });

    test('acceptOffer registers deal and updates budgets and slots', () {
      final initial = service.createInitialState();
      final target = initial.offers.firstWhere((o) => o.id == 'dl_offer_1');

      final updated = service.acceptOffer(initial, target.id);

      expect(updated.completedDeals.length, 1);
      expect(updated.completedDeals.first.riderName, target.riderName);
      expect(
        updated.remainingWageBudgetEur,
        initial.remainingWageBudgetEur - target.askingSalaryEur,
      );
      expect(
        updated.remainingTransferBudgetEur,
        initial.remainingTransferBudgetEur -
            (target.signingBonusEur + target.releaseBuyoutEur),
      );
      expect(updated.remainingRosterSlots, initial.remainingRosterSlots - 1);
    });

    test('submitCounterOffer handles acceptance, counter and walk-away', () {
      final initial = service.createInitialState();
      final target = initial.offers.firstWhere((o) => o.id == 'dl_offer_1');

      final accepted = service.submitCounterOffer(
        initial,
        offerId: target.id,
        counterSalaryEur: (target.askingSalaryEur * 0.96).round(),
        counterYears: 3,
        counterRole: RiderRole.teamLeader,
        seed: 7,
      );
      expect(accepted.completedDeals.length, 1);
      expect(accepted.completedDeals.first.role, RiderRole.teamLeader);

      final walkedAway = service.submitCounterOffer(
        initial,
        offerId: target.id,
        counterSalaryEur: (target.askingSalaryEur * 0.50).round(),
        counterYears: 2,
        counterRole: RiderRole.domestique,
        seed: 7,
      );
      final rejectedOffer =
          walkedAway.offers.firstWhere((o) => o.id == target.id);
      expect(rejectedOffer.status, DeadlineOfferStatus.rejected);
    });

    test('closing window locks remaining offers and builds summary report', () {
      var state = service.createInitialState();
      state = service.acceptOffer(state, 'dl_offer_1');
      state = service.advanceTime(state, minutes: 720, seed: 99);

      expect(state.isWindowClosed, isTrue);
      expect(state.currentPhase, DeadlinePhase.windowClosed);
      expect(state.activeOffersCount, 0);

      final report = service.buildSummaryReport(state);
      expect(report.totalDealsSigned, 1);
      expect(report.windowGrade, isNotEmpty);
    });
  });

  group('TransferDeadlineDayPanel responsive widget tests', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TransferDeadlineDayPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844 mobile without overflow',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));

      expect(find.textContaining('UCI Transfer Deadline Day'), findsOneWidget);
      expect(find.text('12h 00m'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1024x768 tablet without overflow',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));

      expect(find.text('Stół Negocjacyjny (Kontroferta)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1600x900 desktop and supports actions',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));

      expect(find.text('Pasek Transferowy Na Żywo'), findsOneWidget);
      await tester.tap(find.text('Podpisz Natychmiast'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Zamknięte Kontrakty (1)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
