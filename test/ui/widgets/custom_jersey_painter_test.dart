import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/models/team/sponsor_contract.dart';
import 'package:pro_peloton_manager/ui/widgets/custom_jersey_painter.dart';

void main() {
  group('CustomJerseyPainter & TeamJerseyWidget Tests', () {
    const primary = Color(0xFFE10600); // Czerwony
    const secondary = Color(0xFF1E293B); // Granatowy
    const accent = Color(0xFFFACC15); // Złoty

    testWidgets('Poprawnie renderuje wszystkie 8 wzorów koszulek kolarskich', (tester) async {
      for (final pattern in JerseyPattern.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: TeamJerseyWidget(
                  primaryColor: primary,
                  secondaryColor: secondary,
                  accentColor: accent,
                  pattern: pattern,
                  sponsorName: 'ORŁY MAZOWSZA',
                  width: 200,
                  height: 220,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Weryfikacja obecności CustomPaint
        expect(find.byType(CustomPaint), findsWidgets);
        expect(find.byType(TeamJerseyWidget), findsOneWidget);
      }
    });

    testWidgets('Poprawnie renderuje widok z tyłu z numerem startowym kolarza i kieszeniami', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: TeamJerseyWidget(
                primaryColor: primary,
                secondaryColor: secondary,
                accentColor: accent,
                pattern: JerseyPattern.chestStripe,
                isBackView: true,
                startNumber: 1,
                width: 180,
                height: 200,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TeamJerseyWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Konstruktor fabryczny TeamJerseyWidget.fromTeam z modelem CyclingTeam', (tester) async {
      const testDeal = BikeManufacturerDeal(
        manufacturerId: 'brand_aethel',
        manufacturerName: 'Aethel Cycles',
        prestigeLevel: 5,
        annualCashContributionEur: 1500000,
        freeBikesQuota: 80,
        researchAndDevelopmentLevel: 85,
        suppliedFrameIds: ['frame_aethel_aero'],
        suppliedWheelsetIds: ['wheels_aethel_50'],
        contractYearsLeft: 2,
        minimumUciRankingRequired: 18,
      );

      const team = CyclingTeam(
        id: 'team_test',
        name: 'Veloce Santander',
        division: TeamDivision.worldTour,
        countryIso: 'ESP',
        primaryJerseyColorHex: '#E11D48',
        secondaryJerseyColorHex: '#0F172A',
        accentJerseyColorHex: '#F59E0B',
        cashBalanceEur: 30000000,
        monthlyBurnRateEur: 2200000,
        uciPointsSeason: 1200,
        rosterRiderIds: ['r1', 'r2'],
        staff: TeamStaff(
          trainersLevel: 80,
          sportsDirectorsLevel: 85,
          doctorsLevel: 80,
          mechanicsLevel: 90,
          scoutsLevel: 75,
        ),
        bikeDeal: testDeal,
        sponsors: [
          SponsorContract(
            id: 'sp_1',
            companyName: 'Banco Santander',
            industry: SponsorIndustry.finance,
            sponsorTier: SponsorTier.titlePrimary,
            annualBudgetEur: 22000000,
            contractDurationYears: 3,
            sponsorSatisfaction: 90.0,
            objectives: [],
          ),
        ],
        inventoryBikes: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TeamJerseyWidget.fromTeam(
                team,
                pattern: JerseyPattern.chevron,
                width: 150,
                height: 170,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TeamJerseyWidget), findsOneWidget);
    });

    testWidgets('Konstruktor fabryczny TeamJerseyWidget.mini do miniatur', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: TeamJerseyWidget.mini(
                primaryColor: primary,
                secondaryColor: secondary,
                accentColor: accent,
                size: 40,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TeamJerseyWidget), findsOneWidget);
    });

    testWidgets('Interakcja onTap i stan zaznaczenia isSelected', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TeamJerseyWidget(
                primaryColor: primary,
                secondaryColor: secondary,
                accentColor: accent,
                pattern: JerseyPattern.raceLeader,
                isSelected: true,
                onTap: () => tapped = true,
                width: 160,
                height: 180,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TeamJerseyWidget), findsOneWidget);

      await tester.tap(find.byType(TeamJerseyWidget));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
