import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/career/sponsor_custom_color_rebrand_events.dart';

CyclingTeam _buildTestTeam({String primaryHex = '#FACC15'}) {
  return CyclingTeam(
    id: 'team_test',
    name: 'Velo Apex Racing',
    division: TeamDivision.worldTour,
    countryIso: 'PL',
    primaryJerseyColorHex: primaryHex,
    secondaryJerseyColorHex: '#181B22',
    accentJerseyColorHex: '#38BDF8',
    cashBalanceEur: 4500000,
    monthlyBurnRateEur: 320000,
    uciPointsSeason: 6800,
    rosterRiderIds: const ['r1', 'r2'],
    staff: const TeamStaff(
      trainersLevel: 82,
      sportsDirectorsLevel: 85,
      doctorsLevel: 80,
      mechanicsLevel: 84,
      scoutsLevel: 78,
    ),
    bikeDeal: const BikeManufacturerDeal(
      manufacturerId: 'bike_1',
      manufacturerName: 'Cervélo Pro',
      prestigeLevel: 5,
      annualCashContributionEur: 1200000,
      freeBikesQuota: 90,
      researchAndDevelopmentLevel: 88,
      suppliedFrameIds: ['f1'],
      suppliedWheelsetIds: ['w1'],
      contractYearsLeft: 2,
      minimumUciRankingRequired: 10,
    ),
    sponsors: const [],
    inventoryBikes: const [],
  );
}

void main() {
  const service = SponsorCustomColorRebrandEventsService();

  group('SponsorCustomColorRebrandEventsService', () {
    test('detects UCI jersey clash when primary color matches Grand Tour leader jersey', () {
      final yellowTeam = _buildTestTeam(primaryHex: '#FACC15');
      final clash = service.detectUciJerseyClash(
        team: yellowTeam,
        grandTour: GrandTourLiveryEvent.tourDeFrance,
      );
      expect(clash.hasClash, isTrue);
      expect(clash.similarityScore, greaterThanOrEqualTo(0.72));

      final navyTeam = _buildTestTeam(primaryHex: '#0F172A');
      final noClash = service.detectUciJerseyClash(
        team: navyTeam,
        grandTour: GrandTourLiveryEvent.tourDeFrance,
      );
      expect(noClash.hasClash, isFalse);
    });

    test('generates 3 proposals, approves deployment, applies and reverts team colors', () {
      final team = _buildTestTeam(primaryHex: '#FACC15');
      final proposals = service.generateGrandTourLiveryProposals(
        team: team,
        grandTour: GrandTourLiveryEvent.tourDeFrance,
        seasonYear: 2026,
      );

      expect(proposals, hasLength(3));
      expect(proposals.first.theme, SpecialLiveryThemeType.uciClashRebrand);
      expect(proposals.first.uciClashResolved, isTrue);

      final customized = service.customizeProposalColors(
        proposal: proposals.first,
        accentJerseyHex: '#D4AF37',
        bikeFinish: BikePaintFinish.satinRaw,
      );
      expect(customized.palette.accentJerseyHex, '#D4AF37');
      expect(customized.bikeFinish, BikePaintFinish.satinRaw);
      expect(customized.status, SpecialLiveryStatus.customized);

      final deployment = service.approveLiveryProposal(
        proposal: customized,
        team: team,
        seasonYear: 2026,
      );
      final rebrandedTeam = deployment.applyToTeam(team);
      expect(rebrandedTeam.primaryJerseyColorHex, customized.palette.primaryJerseyHex);

      final revertedTeam = deployment.revertTeamColors(rebrandedTeam);
      expect(revertedTeam.primaryJerseyColorHex, team.primaryJerseyColorHex);

      final report = service.simulateMerchandiseAndExposure(
        deployment: deployment,
        stageWinsInLivery: 2,
        podiumGcFinish: true,
      );
      expect(report.grossMerchRevenueEur, greaterThan(deployment.estimatedMerchRevenueEur));
      expect(report.jerseysSoldCount, greaterThan(0));
      expect(report.replicaFramesSoldCount, greaterThanOrEqualTo(12));
    });

    test('SponsorCustomColorRebrandState supports JSON round-trip', () {
      final notifier = SponsorCustomColorRebrandNotifier(service: service);
      final team = _buildTestTeam(primaryHex: '#1E293B');
      notifier.initializeForTeam(
        team: team,
        grandTour: GrandTourLiveryEvent.giroDItalia,
        seasonYear: 2027,
      );
      notifier.approveSelectedProposal(team: team);

      final json = notifier.state.toJson();
      final restored = SponsorCustomColorRebrandState.fromJson(json);

      expect(restored.selectedTour, GrandTourLiveryEvent.giroDItalia);
      expect(restored.seasonYear, 2027);
      expect(restored.proposals, hasLength(3));
      expect(restored.activeDeployment, isNotNull);
    });
  });

  group('SponsorCustomColorRebrandPanel responsive layout', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final team = _buildTestTeam(primaryHex: '#FACC15');

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SponsorCustomColorRebrandPanel(team: team, seasonYear: 2026),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('SPECIAL EDITION LIVERY'), findsOneWidget);
        expect(find.textContaining('Tour de France'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
