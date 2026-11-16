import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/ui/widgets/contract_negotiation_chat_simulator.dart';

void main() {
  Widget buildTestApp({
    required Size size,
    ContractOfferTerms? initialDemand,
    ContractOfferTerms? initialOffer,
    int initialPatience = 70,
    ValueChanged<ContractNegotiationOutcome>? onComplete,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: ContractNegotiationChatSimulator(
              initialAgentDemand: initialDemand,
              initialManagerOffer: initialOffer,
              initialPatience: initialPatience,
              agentReplyDelay: const Duration(milliseconds: 50),
              onNegotiationComplete: onComplete,
            ),
          ),
        ),
      ),
    );
  }

  group('ContractNegotiationChatSimulator', () {
    testWidgets('renders cleanly without overflow at 390x844, 1024x768, 1600x900',
        (WidgetTester tester) async {
      for (final size in const <Size>[
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestApp(size: size));
        await tester.pumpAndSettle();

        expect(find.text('CIERPLIWOŚĆ AGENTA'), findsOneWidget);
        expect(find.text('Gwarancja startu w Tour de France'), findsOneWidget);
        expect(find.text('Dedykowany pociąg sprinterski'), findsOneWidget);
        expect(find.text('Wyższa premia za zwycięstwo'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('playing bargaining chips reduces demand and boosts patience',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestApp(
          size: const Size(1600, 900),
          initialPatience: 70,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('70%'), findsOneWidget);

      await tester.tap(find.text('Gwarancja startu w Tour de France'));
      await tester.pumpAndSettle();

      expect(find.text('80%'), findsOneWidget);
      expect(find.text('TDF GWARANCJA'), findsOneWidget);

      await tester.tap(find.text('Dedykowany pociąg sprinterski'));
      await tester.pumpAndSettle();

      expect(find.text('91%'), findsOneWidget);
      expect(find.text('POCIĄG SPRINT'), findsOneWidget);
    });

    testWidgets('sending low offer triggers real-time counteroffer and drops patience',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 840);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestApp(
          size: const Size(1280, 840),
          initialPatience: 75,
          initialDemand: const ContractOfferTerms(
            monthlySalaryEur: 30000,
            contractYears: 3,
            signingBonusEur: 20000,
            winBonusEur: 4000,
            role: RiderRole.sprinter,
          ),
          initialOffer: const ContractOfferTerms(
            monthlySalaryEur: 18000,
            contractYears: 3,
            signingBonusEur: 10000,
            winBonusEur: 4000,
            role: RiderRole.sprinter,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wyślij kontrofertę'));
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.textContaining('analizuje ofertę'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 80));
      await tester.pumpAndSettle();

      expect(find.text('Runda 2'), findsOneWidget);
      expect(find.text('75%'), findsNothing);
    });

    testWidgets('accepting agent demands completes negotiation with accepted status',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 840);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      ContractNegotiationOutcome? outcome;
      await tester.pumpWidget(
        buildTestApp(
          size: const Size(1280, 840),
          onComplete: (ContractNegotiationOutcome result) {
            outcome = result;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Akceptuj żądania'));
      await tester.pumpAndSettle();

      expect(outcome, isNotNull);
      expect(outcome!.status, ContractNegotiationStatus.accepted);
      expect(find.text('PODPISANY'), findsOneWidget);
    });
  });
}
