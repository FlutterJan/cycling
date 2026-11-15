import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/models/team/sponsor_contract.dart';
import 'package:pro_peloton_manager/services/career/sponsor_negotiation_service.dart';
import 'package:pro_peloton_manager/ui/screens/sponsor_pitch_deck_negotiation_modal.dart';

Rider _buildTestRider({
  required String id,
  required String firstName,
  required String lastName,
  required int careerPointsUci,
  required int ftpWatts,
}) {
  return Rider(
    id: id,
    firstName: firstName,
    lastName: lastName,
    nationalityIso: 'POL',
    birthDate: DateTime(1998, 6, 12),
    potential: 92,
    specialization: RiderSpecialization.gcClimber,
    physiology: RiderPhysiology(
      heightCm: 179,
      weightKg: 66.0,
      bodyFatPercentage: 6.4,
      ftpWatts: ftpWatts,
      wPrimeJoules: 25000,
      vo2Max: 88.0,
      maxHr: 190,
      restingHr: 38,
      lactateThresholdHr: 173,
      recoveryRate: 85.0,
      glycogenCapacityGrams: 610,
    ),
    powerProfile: RiderPowerProfile(
      watts5s: (ftpWatts * 3.0).round(),
      watts15s: (ftpWatts * 2.4).round(),
      watts30s: (ftpWatts * 1.9).round(),
      watts1m: (ftpWatts * 1.6).round(),
      watts3m: (ftpWatts * 1.25).round(),
      watts5m: (ftpWatts * 1.15).round(),
      watts20m: (ftpWatts * 1.05).round(),
      watts60m: ftpWatts,
    ),
    skills: const RiderSkills(
      cobbles: 78,
      descending: 84,
      bikeHandling: 85,
      aeroPositioning: 82,
      draftingEfficiency: 84,
      raceIq: 88,
      rainResistance: 80,
      heatTolerance: 79,
      timeTrialPositioning: 84,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 0,
      skinToneHex: '#E8B89A',
      hairStyleIndex: 1,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
      glassesModelId: 'aero_pro',
      glassesLensColorHex: '#00E5FF',
      helmetModelId: 'aero_shell',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.65,
      bodyBuildType: BodyBuildType.allRounder,
    ),
    contract: const RiderContract(
      teamId: 'team_test',
      role: RiderRole.teamLeader,
      monthlySalaryEur: 110000,
      signingBonusEur: 200000,
      winBonusEur: 12000,
      releaseClauseEur: 4000000,
      contractEndYear: 2028,
      morale: 88.0,
      leaderLoyalty: 85.0,
      requiredRacesIds: [],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 55,
      chronicTrainingLoad: 76,
    ),
    careerPointsUci: careerPointsUci,
  );
}

CyclingTeam _buildTestTeam() {
  return const CyclingTeam(
    id: 'team_test',
    name: 'Orlen Apex Pro Cycling',
    division: TeamDivision.worldTour,
    countryIso: 'POL',
    primaryJerseyColorHex: '#8E4A49',
    secondaryJerseyColorHex: '#181B22',
    accentJerseyColorHex: '#D4AF37',
    cashBalanceEur: 6500000,
    monthlyBurnRateEur: 950000,
    uciPointsSeason: 8420,
    rosterRiderIds: ['r1', 'r2'],
    staff: TeamStaff(
      trainersLevel: 82,
      sportsDirectorsLevel: 85,
      doctorsLevel: 80,
      mechanicsLevel: 84,
      scoutsLevel: 78,
    ),
    bikeDeal: BikeManufacturerDeal(
      manufacturerId: 'bike_1',
      manufacturerName: 'Aether Cycles',
      prestigeLevel: 5,
      annualCashContributionEur: 1500000,
      freeBikesQuota: 90,
      researchAndDevelopmentLevel: 88,
      suppliedFrameIds: ['frame_1'],
      suppliedWheelsetIds: ['wheel_1'],
      contractYearsLeft: 2,
      minimumUciRankingRequired: 12,
    ),
    sponsors: [],
    inventoryBikes: [],
  );
}

void main() {
  final company = SponsorNegotiationService.availableSponsorCompanies.first;
  final team = _buildTestTeam();
  final roster = [
    _buildTestRider(
      id: 'r1',
      firstName: 'Michał',
      lastName: 'Kowalski',
      careerPointsUci: 3100,
      ftpWatts: 418,
    ),
    _buildTestRider(
      id: 'r2',
      firstName: 'Jan',
      lastName: 'Nowak',
      careerPointsUci: 1650,
      ftpWatts: 392,
    ),
  ];

  group('SponsorPitchDeckNegotiationModal', () {
    test('calculateMediaForecast scales with WorldTour starts and leader popularity', () {
      final lowExposure = SponsorPitchDeckNegotiationModal.calculateMediaForecast(
        worldTourStartsCount: 4,
        roster: [roster.last],
      );
      final highExposure = SponsorPitchDeckNegotiationModal.calculateMediaForecast(
        worldTourStartsCount: 30,
        roster: roster,
        featuredLeader: roster.first,
      );

      expect(highExposure.mediaValueIndex, greaterThan(lowExposure.mediaValueIndex));
      expect(highExposure.worldTourStartsCount, 30);
      expect(highExposure.estimatedTvAirtimeHours, greaterThan(lowExposure.estimatedTvAirtimeHours));
      expect(highExposure.estimatedAveEur, greaterThan(lowExposure.estimatedAveEur));
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders without overflow at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: SponsorPitchDeckNegotiationModal(
                company: company,
                team: team,
                roster: roster,
                worldTourStartsCount: 28,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('PITCH DECK & NEGOCJACJE'), findsOneWidget);
        expect(find.text('PREZENTACJA STROJU ZESPOŁU'), findsOneWidget);
        expect(find.text('PROGNOZA EKSPOZYCJI TV (MEDIA VALUE INDEX)'), findsOneWidget);
        expect(find.text('CIERPLIWOŚĆ DYREKTORA MARKETINGU'), findsOneWidget);
        expect(find.text('3 CELE OBOWIĄZKOWE SEZONU'), findsOneWidget);
        expect(find.text('Złóż Ofertę (Runda 1/3)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('live patience reacts to budget slider and front/back kit toggle works', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SponsorPitchDeckNegotiationModal(
              company: company,
              team: team,
              roster: roster,
              worldTourStartsCount: 28,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle kit back view
      await tester.tap(find.text('Tył'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Drag first slider (annual budget) to the far right to test live patience drop
      final budgetSlider = find.byType(Slider).first;
      await tester.drag(budgetSlider, const Offset(420, 0));
      await tester.pumpAndSettle();

      // Submitting an excessive demand triggers Round 2 counter-offer
      await tester.tap(find.text('Złóż Ofertę (Runda 1/3)'));
      await tester.pumpAndSettle();

      expect(find.text('RUNDA 2/3'), findsOneWidget);
      expect(find.text('Złóż Ofertę (Runda 2/3)'), findsOneWidget);
      expect(find.textContaining('Akceptuj'), findsOneWidget);
    });

    testWidgets('accepting offer signs contract and invokes callback', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SponsorContract? signed;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SponsorPitchDeckNegotiationModal(
              company: company,
              team: team,
              roster: roster,
              worldTourStartsCount: 28,
              onContractSigned: (contract) => signed = contract,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default offer with 3 objectives is within acceptable base budget -> accepted in Round 1
      await tester.tap(find.text('Złóż Ofertę (Runda 1/3)'));
      await tester.pumpAndSettle();

      expect(find.text('PODPISANO'), findsOneWidget);
      expect(find.text('Podpisz Kontrakt'), findsOneWidget);

      await tester.tap(find.text('Podpisz Kontrakt'));
      await tester.pumpAndSettle();

      expect(signed, isNotNull);
      expect(signed!.companyName, company.name);
      expect(signed!.objectives.length, 3);
    });
  });
}
