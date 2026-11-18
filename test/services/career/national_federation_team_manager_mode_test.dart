import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/services/career/national_federation_team_manager_mode.dart';

void main() {
  group('NationalFederationTeamManagerService', () {
    const service = NationalFederationTeamManagerService();

    test('autoSelectOptimalSquad respects UCI quota and excludes injured riders',
        () {
      final poland =
          NationalFederationTeamManagerService.createDefaultPolandCampaign();
      final maxStarters = poland.activeMaxStarters;

      expect(poland.activeStarters.length, maxStarters);
      expect(poland.reserves.length, lessThanOrEqualTo(poland.quota.maxReserves));
      for (final entry in poland.activeStarters) {
        final candidate = poland.findCandidate(entry.riderId);
        expect(candidate, isNotNull);
        expect(candidate!.isInjured, isFalse);
      }
      expect(
        poland.activeStarters
            .any((e) => e.role == NationalRiderTacticalRole.protectedLeader),
        isTrue,
      );
    });

    test('evaluateSquadChemistry detects ego conflicts and club rivalries', () {
      final presets =
          NationalFederationTeamManagerService.createSampleNationPresets();
      final belgium = presets.firstWhere((p) => p.quota.nationCode == 'BEL');

      // Force Wout van Aert (ego 84, rival of Remco) into a domestique role
      final modified = service.assignRiderRole(
        belgium,
        'bel_wout',
        NationalRiderTacticalRole.leadoutAndTempo,
      );

      final report = service.evaluateSquadChemistry(modified);
      expect(report.egoConflictCount, greaterThanOrEqualTo(1));
      expect(report.rivalryCount, greaterThanOrEqualTo(1));
      expect(report.warnings, isNotEmpty);
      expect(report.cohesionScore, lessThan(80.0));
    });

    test('resolveClubReleaseNegotiation clears club conflict and deducts budget',
        () {
      final poland =
          NationalFederationTeamManagerService.createDefaultPolandCampaign();
      final initialBudget = poland.quota.federationBudgetEur;

      final resolved =
          service.resolveClubReleaseNegotiation(poland, 'pol_majka');
      final majka = resolved.findCandidate('pol_majka');

      expect(majka, isNotNull);
      expect(majka!.hasClubConflict, isFalse);
      expect(
        resolved.quota.federationBudgetEur,
        closeTo(
          initialBudget -
              NationalFederationTeamManagerService
                  .clubReleaseNegotiationCostEur,
          0.01,
        ),
      );
    });

    test('switchEventAndCourse adjusts starter quota for Olympic Games & ITT',
        () {
      final poland =
          NationalFederationTeamManagerService.createDefaultPolandCampaign();
      expect(poland.activeMaxStarters, 6);

      final olympic = service.switchEventAndCourse(
        poland,
        eventType: NationalChampionshipEventType.olympicRoadRace,
      );
      expect(olympic.activeMaxStarters, 3);
      expect(olympic.activeStarters.length, 3);

      final itt = service.switchEventAndCourse(
        olympic,
        eventType: NationalChampionshipEventType.uciIttWorldChampionships,
      );
      expect(itt.activeMaxStarters, 2);
      expect(itt.courseProfile, NationalTeamCourseProfile.technicalTimeTrial);
    });

    test('simulateChampionshipRace produces deterministic result and updates history',
        () {
      final presets =
          NationalFederationTeamManagerService.createSampleNationPresets();
      final slovenia = presets.firstWhere((p) => p.quota.nationCode == 'SLO');

      final sim1 = service.simulateChampionshipRace(
        slovenia,
        deterministicSeed: 42,
      );
      final sim2 = service.simulateChampionshipRace(
        slovenia,
        deterministicSeed: 42,
      );

      expect(sim1.lastSimulationResult, isNotNull);
      expect(
        sim1.lastSimulationResult!.bestFinishPosition,
        sim2.lastSimulationResult!.bestFinishPosition,
      );
      expect(sim1.history.length, 1);
      expect(sim1.isSelectionLocked, isTrue);
      expect(sim1.lastSimulationResult!.uciNationPointsEarned, greaterThan(0));
    });

    test('JSON round-trip preserves NationalChampionshipCampaignState', () {
      final poland =
          NationalFederationTeamManagerService.createDefaultPolandCampaign();
      final simulated = service.simulateChampionshipRace(
        poland,
        deterministicSeed: 77,
      );

      final json = simulated.toJson();
      final restored = NationalChampionshipCampaignState.fromJson(json);

      expect(restored.seasonYear, simulated.seasonYear);
      expect(restored.eventType, simulated.eventType);
      expect(restored.courseProfile, simulated.courseProfile);
      expect(restored.quota.nationCode, simulated.quota.nationCode);
      expect(restored.candidatePool.length, simulated.candidatePool.length);
      expect(restored.selectedSquad.length, simulated.selectedSquad.length);
      expect(restored.history.length, simulated.history.length);
      expect(
        restored.lastSimulationResult?.bestFinishPosition,
        simulated.lastSimulationResult?.bestFinishPosition,
      );
    });
  });

  group('NationalFederationTeamManagerPanel Responsive UI', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NationalFederationTeamManagerPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844 mobile without overflow',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.text('Selekcjoner Reprezentacji Narodowej'), findsOneWidget);
      expect(find.text('Chemia Kadry & Taktyka'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1024x768 tablet without overflow',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('Selekcjoner Reprezentacji Narodowej'), findsOneWidget);
      expect(find.text('Symuluj Finał'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1600x900 desktop and simulates final',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(find.text('Selekcjoner Reprezentacji Narodowej'), findsOneWidget);

      await tester.tap(find.text('Symuluj Finał'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Wynik:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
