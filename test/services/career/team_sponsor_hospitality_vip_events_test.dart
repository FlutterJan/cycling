import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/models/team/sponsor_contract.dart';
import 'package:pro_peloton_manager/services/career/team_sponsor_hospitality_vip_events.dart';

void main() {
  const service = TeamSponsorHospitalityVipEvents();

  const ceoGuest = VipSponsorGuestProfile(
    id: 'guest_ceo_1',
    fullName: 'Jean-Luc Moreau',
    title: 'CEO',
    companyName: 'VeloBank Group',
    sponsorId: 'sp_velobank',
    roleTier: VipGuestRoleTier.sponsorCeo,
    industry: SponsorIndustry.finance,
    personalPreference: VipHospitalityExperiencePackage.secondTeamCarConvoy,
    patienceScore: 80.0,
    affinityScore: 72.0,
  );

  const sampleContract = SponsorContract(
    id: 'sp_velobank',
    companyName: 'VeloBank Group',
    industry: SponsorIndustry.finance,
    sponsorTier: SponsorTier.titlePrimary,
    annualBudgetEur: 12000000,
    contractDurationYears: 1,
    sponsorSatisfaction: 74.0,
    objectives: [],
  );

  group('TeamSponsorHospitalityVipEvents service', () {
    test('rejects empty guests or insufficient budget', () {
      final noGuests = service.createVipInvitation(
        eventId: 'evt_1',
        seasonYear: 2026,
        stageId: 'roubaix',
        stageName: 'Paris-Roubaix',
        venue: VipHospitalityStageVenue.parisRoubaixVelodrome,
        eventDate: DateTime(2026, 4, 12),
        sponsorId: sampleContract.id,
        sponsorCompanyName: sampleContract.companyName,
        guests: const [],
        selectedPackages: const [
          VipHospitalityExperiencePackage.finishLineVipLounge,
        ],
        availableTeamBudgetEur: 500000,
      );
      expect(noGuests.success, isFalse);

      final lowBudget = service.createVipInvitation(
        eventId: 'evt_2',
        seasonYear: 2026,
        stageId: 'champs',
        stageName: 'Champs-Élysées',
        venue: VipHospitalityStageVenue.champsElyseesFinale,
        eventDate: DateTime(2026, 7, 26),
        sponsorId: sampleContract.id,
        sponsorCompanyName: sampleContract.companyName,
        guests: const [ceoGuest],
        selectedPackages: const [
          VipHospitalityExperiencePackage.fullExecutiveHospitalitySuite,
        ],
        availableTeamBudgetEur: 5000,
      );
      expect(lowBudget.success, isFalse);
    });

    test(
      'creates Paris-Roubaix VIP invite, runs 2nd car ride, and boosts multi-year renewal',
      () {
        final invite = service.createVipInvitation(
          eventId: 'evt_roubaix',
          seasonYear: 2026,
          stageId: 'paris_roubaix',
          stageName: 'Paris-Roubaix',
          venue: VipHospitalityStageVenue.parisRoubaixVelodrome,
          eventDate: DateTime(2026, 4, 12),
          sponsorId: sampleContract.id,
          sponsorCompanyName: sampleContract.companyName,
          guests: const [ceoGuest],
          selectedPackages: const [
            VipHospitalityExperiencePackage.finishLineVipLounge,
            VipHospitalityExperiencePackage.secondTeamCarConvoy,
          ],
          availableTeamBudgetEur: 500000,
        );

        expect(invite.success, isTrue);
        expect(invite.eventRecord, isNotNull);
        expect(invite.eventRecord!.status, VipInvitationStatus.confirmed);
        expect(invite.budgetSpentEur, greaterThan(0));

        final rideResult = service.simulateSecondTeamCarRide(
          event: invite.eventRecord!,
          seed: 7,
        );
        expect(rideResult.success, isTrue);
        expect(rideResult.eventRecord!.secondCarTelemetry, isNotNull);
        expect(
          rideResult.eventRecord!.secondCarTelemetry!.carNumber,
          equals(2),
        );

        final resolved = service.resolveHospitalityEvent(
          event: rideResult.eventRecord!,
          teamStagePlacement: 2,
          wonStageOrPodium: true,
        );
        expect(resolved.success, isTrue);
        expect(resolved.eventRecord!.status, VipInvitationStatus.completed);
        expect(resolved.eventRecord!.hospitalityScore, greaterThanOrEqualTo(75));

        final summary = service.evaluateSponsorContractRenewalImpact(
          contract: sampleContract,
          events: [resolved.eventRecord!],
        );
        expect(summary.completedVipEventsCount, equals(1));
        expect(summary.secondCarRidesCompleted, equals(1));
        expect(summary.recommendedContractYears, greaterThanOrEqualTo(2));

        final renewedContract = service.applyRenewalImpactToContract(
          contract: sampleContract,
          summary: summary,
          executeMultiYearRenewal: true,
        );
        expect(renewedContract.contractDurationYears, greaterThanOrEqualTo(2));
        expect(
          renewedContract.annualBudgetEur,
          greaterThan(sampleContract.annualBudgetEur),
        );

        // JSON round-trip check
        final roundTripEvent = VipHospitalityEventRecord.fromJson(
          resolved.eventRecord!.toJson(),
        );
        expect(roundTripEvent.id, equals(resolved.eventRecord!.id));
        expect(
          roundTripEvent.secondCarTelemetry?.driverName,
          equals(resolved.eventRecord!.secondCarTelemetry?.driverName),
        );
      },
    );
  });

  group('TeamSponsorHospitalityVipPanel UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: TeamSponsorHospitalityVipPanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(
            find.text('Gościnność VIP Sponsora & Konwój 2. Wozu'),
            findsOneWidget,
          );
          expect(find.text('Wyślij Zaproszenie'), findsOneWidget);

          // Trigger sending invitation
          await tester.ensureVisible(find.text('Wyślij Zaproszenie'));
          await tester.pump(const Duration(milliseconds: 200));
          await tester.tap(find.text('Wyślij Zaproszenie'));
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Przejazd 2. Wozem'), findsWidgets);
        },
      );
    }
  });
}
