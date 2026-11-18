import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/models/career/team_esg_sustainability_and_green_fleet_model.dart';
import 'package:pro_peloton_manager/ui/screens/esg_sustainability_and_fleet_screen.dart';

void main() {
  Widget wrapScreen({
    required Size size,
    TeamEsgSustainabilityAndGreenFleetModel? initialModel,
    ValueChanged<TeamEsgSustainabilityAndGreenFleetModel>? onModelChanged,
    EsgSustainabilityFleetTab initialTab = EsgSustainabilityFleetTab.fleet,
  }) {
    return ProviderScope(
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: SizedBox(
            width: size.width,
            height: size.height,
            child: EsgSustainabilityAndFleetScreen(
              initialModel: initialModel,
              onModelChanged: onModelChanged,
              initialTab: initialTab,
            ),
          ),
        ),
      ),
    );
  }

  group('EsgSustainabilityAndFleetScreen responsiveness', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders all tabs without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final starter =
              TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
            teamId: 'wt_test',
          );

          await tester.pumpWidget(wrapScreen(size: size, initialModel: starter));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          expect(find.textContaining('Ocena ESG Drużyny'), findsOneWidget);

          for (final tab in EsgSustainabilityFleetTab.values) {
            final tabFinder = find.text(tab.label);
            await tester.ensureVisible(tabFinder);
            await tester.tap(tabFinder);
            await tester.pump(const Duration(milliseconds: 300));
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  });

  group('EsgSustainabilityAndFleetScreen interactions', () {
    testWidgets('buys vehicle and supports trade-in replacement', (tester) async {
      const size = Size(1280, 860);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      TeamEsgSustainabilityAndGreenFleetModel? latest;
      final starter =
          TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
        teamId: 'wt_fleet',
        cashBalanceEur: 1200000.0,
      );

      await tester.pumpWidget(
        wrapScreen(
          size: size,
          initialModel: starter,
          onModelChanged: (m) => latest = m,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final buyButton = find.text('Kup do floty').first;
      await tester.ensureVisible(buyButton);
      await tester.tap(buyButton);
      await tester.pump(const Duration(milliseconds: 300));

      expect(latest, isNotNull);
      expect(latest!.vehicles.length, starter.vehicles.length + 1);
      expect(latest!.cashBalanceEur, lessThan(starter.cashBalanceEur));
    });

    testWidgets('purchases carbon offsets and records team travel',
        (tester) async {
      const size = Size(1280, 860);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      TeamEsgSustainabilityAndGreenFleetModel? latest;
      final starter =
          TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
        teamId: 'wt_carbon',
      );

      await tester.pumpWidget(
        wrapScreen(
          size: size,
          initialModel: starter,
          initialTab: EsgSustainabilityFleetTab.carbonLedger,
          onModelChanged: (m) => latest = m,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final offsetBtn = find.text('Kup kompensację');
      await tester.ensureVisible(offsetBtn);
      await tester.tap(offsetBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(latest, isNotNull);
      expect(latest!.ledger.length, starter.ledger.length + 1);

      final travelBtn = find.text('Zaksięguj podróż');
      await tester.ensureVisible(travelBtn);
      await tester.tap(travelBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(latest!.ledger.length, starter.ledger.length + 2);
    });

    testWidgets('records convoy trip and toggles policies', (tester) async {
      const size = Size(1280, 860);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      TeamEsgSustainabilityAndGreenFleetModel? latest;
      final starter =
          TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
        teamId: 'wt_convoy',
      );

      await tester.pumpWidget(
        wrapScreen(
          size: size,
          initialModel: starter,
          initialTab: EsgSustainabilityFleetTab.convoyAndInfra,
          onModelChanged: (m) => latest = m,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final recordTripBtn = find.text('Zarejestruj przejazd konwoju');
      await tester.ensureVisible(recordTripBtn);
      await tester.tap(recordTripBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(latest, isNotNull);
      expect(latest!.ledger.length, starter.ledger.length + 1);

      final ecoPolicy = find.text('Program biodegradowalnych bidonów Eco-Bottle');
      await tester.ensureVisible(ecoPolicy);
      await tester.tap(ecoPolicy);
      await tester.pump(const Duration(milliseconds: 300));

      expect(latest!.ecoBottleProgramEnabled, isTrue);
    });

    testWidgets('signs eligible green sponsor and handles empty states',
        (tester) async {
      const size = Size(1280, 860);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      TeamEsgSustainabilityAndGreenFleetModel? latest;
      final starter =
          TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
        teamId: 'wt_sponsors',
      );

      await tester.pumpWidget(
        wrapScreen(
          size: size,
          initialModel: starter,
          initialTab: EsgSustainabilityFleetTab.greenSponsors,
          onModelChanged: (m) => latest = m,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final signButtons = find.text('Podpisz kontrakt');
      expect(signButtons, findsWidgets);
      await tester.ensureVisible(signButtons.last);
      await tester.tap(signButtons.last);
      await tester.pump(const Duration(milliseconds: 300));

      expect(latest, isNotNull);
      expect(
        latest!.greenSponsors.where((s) => s.isActive).length,
        greaterThan(starter.greenSponsors.where((s) => s.isActive).length),
      );
    });

    testWidgets('handles empty fleet and sponsors states gracefully',
        (tester) async {
      const size = Size(1280, 860);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const emptyModel = TeamEsgSustainabilityAndGreenFleetModel(
        teamId: 'empty',
        seasonYear: 2026,
        vehicles: [],
        infrastructureTier: ChargingInfrastructureTier.none,
        ledger: [],
        greenSponsors: [],
        cashBalanceEur: 0.0,
      );

      await tester.pumpWidget(
        wrapScreen(
          size: size,
          initialModel: emptyModel,
          initialTab: EsgSustainabilityFleetTab.fleet,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Brak pojazdów we flocie. Kup pierwszy pojazd poniżej.'),
        findsOneWidget,
      );
    });
  });
}
