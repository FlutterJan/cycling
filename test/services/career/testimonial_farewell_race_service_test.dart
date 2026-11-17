import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/staff_member.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/services/career/testimonial_farewell_race_service.dart';

Rider _buildTestRider({
  required String id,
  required String firstName,
  required String lastName,
  required DateTime birthDate,
  int careerPointsUci = 9800,
  RiderSpecialization specialization = RiderSpecialization.classicCobbles,
  int raceIq = 91,
}) {
  return Rider(
    id: id,
    firstName: firstName,
    lastName: lastName,
    nationalityIso: 'POL',
    birthDate: birthDate,
    potential: 92,
    specialization: specialization,
    physiology: const RiderPhysiology(
      heightCm: 179.0,
      weightKg: 71.0,
      bodyFatPercentage: 7.2,
      ftpWatts: 415,
      wPrimeJoules: 24500,
      vo2Max: 81.0,
      maxHr: 188,
      restingHr: 39,
      lactateThresholdHr: 170,
      recoveryRate: 86.0,
      glycogenCapacityGrams: 560.0,
    ),
    powerProfile: const RiderPowerProfile(
      watts5s: 1380,
      watts15s: 1120,
      watts30s: 890,
      watts1m: 670,
      watts3m: 510,
      watts5m: 475,
      watts20m: 430,
      watts60m: 415,
    ),
    skills: RiderSkills(
      cobbles: 92,
      descending: 88,
      bikeHandling: 90,
      aeroPositioning: 84,
      draftingEfficiency: 89,
      raceIq: raceIq,
      rainResistance: 88,
      heatTolerance: 82,
      timeTrialPositioning: 80,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#E0B495',
      hairStyleIndex: 2,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 1,
      glassesModelId: 'oakley_pro',
      glassesLensColorHex: '#D4AF37',
      helmetModelId: 'aero_pro',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.55,
      bodyBuildType: BodyBuildType.allRounder,
    ),
    contract: const RiderContract(
      teamId: 'team_pol_wt',
      role: RiderRole.teamLeader,
      monthlySalaryEur: 45000,
      signingBonusEur: 50000,
      winBonusEur: 25000,
      releaseClauseEur: 1200000,
      contractEndYear: 2026,
      morale: 92.0,
      leaderLoyalty: 95.0,
      requiredRacesIds: <String>['paris_roubaix', 'il_lombardia'],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 62.0,
      chronicTrainingLoad: 78.0,
    ),
    careerPointsUci: careerPointsUci,
  );
}

void main() {
  const service = TestimonialFarewellRaceService();

  group('TestimonialFarewellRaceService', () {
    test('verifies minimum age >= 36 for farewell season eligibility', () {
      final youngVeteran = _buildTestRider(
        id: 'r_35',
        firstName: 'Marek',
        lastName: 'Kowal',
        birthDate: DateTime(1991, 5, 10),
      );
      final legend36 = _buildTestRider(
        id: 'r_36',
        firstName: 'Michał',
        lastName: 'Kwiatkowski',
        birthDate: DateTime(1990, 1, 5),
      );

      final refDate = DateTime(2026, 2, 1);
      final report35 = service.evaluateEligibility(
        youngVeteran,
        referenceDate: refDate,
        yearsWithTeam: 7,
      );
      final report36 = service.evaluateEligibility(
        legend36,
        referenceDate: refDate,
        yearsWithTeam: 8,
      );

      expect(report35.ageYears, 34);
      expect(report35.isEligible, isFalse);
      expect(report35.recommendedTier, isNull);

      expect(report36.ageYears, 36);
      expect(report36.isEligible, isTrue);
      expect(report36.recommendedTier, FarewellLegendTier.cyclingImmortal);

      expect(
        () => service.announceFinalSeason(
          youngVeteran,
          seasonYear: 2026,
          announcedAt: refDate,
        ),
        throwsArgumentError,
      );
    });

    test('awards Final Season badge, schedules final race, and performs guard of honor', () {
      final legend = _buildTestRider(
        id: 'legend_1',
        firstName: 'Rafał',
        lastName: 'Majka',
        birthDate: DateTime(1989, 9, 12),
        careerPointsUci: 7400,
        specialization: RiderSpecialization.gcClimber,
      );

      final announced = service.announceFinalSeason(
        legend,
        seasonYear: 2026,
        yearsWithTeam: 6,
        announcedAt: DateTime(2026, 1, 15),
      );

      expect(announced.hasFinalSeasonBadge, isTrue);
      expect(announced.badge.label, 'Final Season');
      expect(announced.badge.badgeCode, 'FINAL_SEASON');
      expect(announced.phase, FarewellPhase.announcedFinalSeason);
      expect(announced.ageAtAnnouncement, 36);

      final scheduled = service.scheduleFinalRace(
        announced,
        raceId: 'il_lombardia_2026',
        raceName: 'Il Lombardia',
      );
      expect(scheduled.phase, FarewellPhase.finalRaceScheduled);
      expect(scheduled.finalRaceId, 'il_lombardia_2026');

      final withGuard = service.triggerPelotonGuardOfHonor(
        scheduled,
        pelotonSize: 176,
      );
      expect(withGuard.hasGuardOfHonor, isTrue);
      expect(withGuard.phase, FarewellPhase.guardOfHonorPerformed);
      expect(withGuard.guardOfHonor!.participatingPelotonCount, 176);
      expect(withGuard.guardOfHonor!.moraleBoostApplied, greaterThan(0));
      expect(withGuard.guardOfHonor!.saluteQuotes, isNotEmpty);
    });

    test('generates Sports Director offer upon retirement and hires immediately', () {
      final legend = _buildTestRider(
        id: 'legend_2',
        firstName: 'Maciej',
        lastName: 'Bodnar',
        birthDate: DateTime(1985, 3, 7),
        careerPointsUci: 5200,
        specialization: RiderSpecialization.classicCobbles,
        raceIq: 93,
      );

      final announced = service.announceFinalSeason(
        legend,
        seasonYear: 2026,
        yearsWithTeam: 7,
        announcedAt: DateTime(2026, 1, 15),
        finalRaceId: 'paris_tours_2026',
        finalRaceName: 'Paris–Tours',
      );
      final afterGuard = service.triggerPelotonGuardOfHonor(announced);
      final retired = service.completeCareerAndGenerateDsOffer(
        afterGuard,
        legend,
        contractYears: 3,
      );

      expect(retired.phase, FarewellPhase.retiredPendingDsDecision);
      expect(retired.canHireAsSportsDirector, isTrue);
      expect(retired.directorOffer, isNotNull);
      expect(retired.directorOffer!.isLoyaltyDiscountApplied, isTrue);
      expect(retired.directorOffer!.signingBonusEur, 0);
      expect(
        retired.directorOffer!.proposedDirector.tacticalPhilosophy,
        DirectorTacticalPhilosophy.aggressiveAttacking,
      );

      final hireResult = service.hireLegendAsSportsDirector(retired);
      expect(
        hireResult.updatedRecord.phase,
        FarewellPhase.hiredAsSportsDirector,
      );
      expect(hireResult.hiredDirector.role, StaffRole.sportsDirector);
      expect(hireResult.hiredDirector.fullName, 'Maciej Bodnar');
      expect(hireResult.hiredDirector.contractEndYear, 2029);

      // JSON round-trip check
      final json = hireResult.updatedRecord.toJson();
      final decoded = FarewellLegendRecord.fromJson(json);
      expect(decoded.riderId, hireResult.updatedRecord.riderId);
      expect(decoded.phase, FarewellPhase.hiredAsSportsDirector);
      expect(decoded.hiredDirector?.fullName, 'Maciej Bodnar');
      expect(decoded.guardOfHonor?.raceName, 'Paris–Tours');
    });

    test('supports declining Sports Director offer cleanly', () {
      final legend = _buildTestRider(
        id: 'legend_3',
        firstName: 'Tomasz',
        lastName: 'Marczyński',
        birthDate: DateTime(1984, 3, 6),
        careerPointsUci: 3100,
      );

      final announced = service.announceFinalSeason(
        legend,
        seasonYear: 2026,
        yearsWithTeam: 3,
        announcedAt: DateTime(2026, 1, 15),
      );
      final retired = service.completeCareerAndGenerateDsOffer(
        announced,
        legend,
      );
      final declined = service.declineSportsDirectorOffer(retired);

      expect(declined.phase, FarewellPhase.retiredToPrivateLife);
      expect(declined.canHireAsSportsDirector, isFalse);
    });
  });

  group('TestimonialFarewellRacePanel responsive UI', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      required List<FarewellLegendRecord> records,
      ValueChanged<FarewellLegendRecord>? onGuard,
      ValueChanged<FarewellLegendRecord>? onHire,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestimonialFarewellRacePanel(
              records: records,
              onTriggerGuardOfHonor: onGuard,
              onHireAsSportsDirector: onHire,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders without overflow on 390x844, 1024x768, and 1600x900',
        (tester) async {
      final legend = _buildTestRider(
        id: 'ui_legend',
        firstName: 'Michał',
        lastName: 'Kwiatkowski',
        birthDate: DateTime(1990, 1, 5),
      );
      final record = service.completeCareerAndGenerateDsOffer(
        service.announceFinalSeason(
          legend,
          seasonYear: 2026,
          yearsWithTeam: 6,
          announcedAt: DateTime(2026, 1, 15),
          finalRaceId: 'il_lombardia',
          finalRaceName: 'Il Lombardia',
        ),
        legend,
      );

      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpPanelAtSize(tester, size, records: [record]);
        final exception = tester.takeException();
        expect(exception, isNull, reason: 'At $size: $exception');
        expect(find.text('FINAL SEASON 2026'), findsOneWidget);
        expect(find.text('Szpaler Honorowy Peletonu'), findsOneWidget);
        expect(
          find.text('Zatrudnij jako Dyrektora Sportowego'),
          findsOneWidget,
        );
      }
    });

    testWidgets('triggers guard of honor and hires legend as Sports Director',
        (tester) async {
      final legend = _buildTestRider(
        id: 'ui_legend_2',
        firstName: 'Rafał',
        lastName: 'Majka',
        birthDate: DateTime(1989, 9, 12),
      );
      FarewellLegendRecord? hiredRecord;
      FarewellLegendRecord? guardRecord;

      final record = service.completeCareerAndGenerateDsOffer(
        service.announceFinalSeason(
          legend,
          seasonYear: 2026,
          yearsWithTeam: 5,
          announcedAt: DateTime(2026, 1, 15),
          finalRaceId: 'il_lombardia',
          finalRaceName: 'Il Lombardia',
        ),
        legend,
      );

      await pumpPanelAtSize(
        tester,
        const Size(1280, 800),
        records: [record],
        onGuard: (r) => guardRecord = r,
        onHire: (r) => hiredRecord = r,
      );

      await tester.tap(find.text('Rozpocznij Szpaler Honorowy'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(guardRecord, isNotNull);

      await tester.tap(find.text('Zatrudnij jako Dyrektora Sportowego'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(hiredRecord, isNotNull);
    });
  });
}
