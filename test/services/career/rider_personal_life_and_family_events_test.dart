import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/services/career/rider_personal_life_and_family_events.dart';

Rider _buildTestRider({
  required String id,
  required String firstName,
  required String lastName,
  String nationalityIso = 'POL',
  int ageYears = 29,
}) {
  final now = DateTime(2026, 5, 14);
  return Rider(
    id: id,
    firstName: firstName,
    lastName: lastName,
    nationalityIso: nationalityIso,
    birthDate: DateTime(now.year - ageYears, 3, 10),
    potential: 89,
    specialization: RiderSpecialization.gcClimber,
    physiology: const RiderPhysiology(
      heightCm: 177.0,
      weightKg: 66.0,
      bodyFatPercentage: 6.8,
      ftpWatts: 405,
      wPrimeJoules: 22000,
      vo2Max: 82.0,
      maxHr: 190,
      restingHr: 38,
      lactateThresholdHr: 172,
      recoveryRate: 85.0,
      glycogenCapacityGrams: 540.0,
    ),
    powerProfile: const RiderPowerProfile(
      watts5s: 1210,
      watts15s: 980,
      watts30s: 790,
      watts1m: 620,
      watts3m: 495,
      watts5m: 465,
      watts20m: 420,
      watts60m: 405,
    ),
    skills: const RiderSkills(
      cobbles: 78,
      descending: 85,
      bikeHandling: 86,
      aeroPositioning: 82,
      draftingEfficiency: 84,
      raceIq: 88,
      rainResistance: 80,
      heatTolerance: 79,
      timeTrialPositioning: 81,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#E0B495',
      hairStyleIndex: 2,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
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
      monthlySalaryEur: 38000,
      signingBonusEur: 25000,
      winBonusEur: 5000,
      releaseClauseEur: 450000,
      contractEndYear: 2028,
      morale: 75.0,
      leaderLoyalty: 80.0,
      requiredRacesIds: <String>[],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 68.0,
      chronicTrainingLoad: 84.0,
    ),
    careerPointsUci: 4200,
  );
}

void main() {
  const service = RiderPersonalLifeAndFamilyEventsService();

  group('RiderPersonalLifeAndFamilyEventsService', () {
    test('serializes and deserializes profile and event records cleanly', () {
      final rider = _buildTestRider(
        id: 'rider_1',
        firstName: 'Michał',
        lastName: 'Kowalski',
      );
      final profile = service.createInitialProfile(
        rider,
        hometown: 'Kraków',
        homeRegion: 'Małopolska',
        childrenCount: 1,
        expectingChildDueDate: DateTime(2026, 6, 1),
      );
      final roundTripProfile = RiderFamilyProfile.fromJson(profile.toJson());
      expect(roundTripProfile.riderId, 'rider_1');
      expect(roundTripProfile.hometownName, 'Kraków');
      expect(roundTripProfile.childrenCount, 1);
      expect(roundTripProfile.expectingChildDueDate, DateTime(2026, 6, 1));

      final birthEvent = service.triggerChildBirthEvent(
        rider: rider,
        profile: profile,
        birthDate: DateTime(2026, 5, 14),
      );
      final roundTripEvent =
          PersonalLifeEventRecord.fromJson(birthEvent.toJson());
      expect(roundTripEvent.eventId, birthEvent.eventId);
      expect(roundTripEvent.type, PersonalLifeEventType.childBirth);
      expect(roundTripEvent.requiresManagerDecision, isTrue);
    });

    test('resolving paternity leave updates availability, children, and morale',
        () {
      final rider = _buildTestRider(
        id: 'rider_2',
        firstName: 'Piotr',
        lastName: 'Nowak',
      );
      final profile = service.createInitialProfile(
        rider,
        hometown: 'Sobótka',
        homeRegion: 'Dolny Śląsk',
        childrenCount: 0,
        familyHappiness: 70,
      );
      final decisionDate = DateTime(2026, 5, 14);
      final birthEvent = service.triggerChildBirthEvent(
        rider: rider,
        profile: profile,
        birthDate: decisionDate,
      );

      final fullLeave = service.resolvePaternityLeaveDecision(
        event: birthEvent,
        profile: profile,
        option: PaternityLeaveOption.fullLeave14Days,
        decisionDate: decisionDate,
      );
      expect(fullLeave.profile.childrenCount, 1);
      expect(fullLeave.profile.familyHappiness, 90);
      expect(fullLeave.profile.teamLoyaltyDelta, 12);
      expect(
        fullLeave.profile.isOnPaternityLeaveAt(DateTime(2026, 5, 20)),
        isTrue,
      );
      expect(
        fullLeave.profile.isOnPaternityLeaveAt(DateTime(2026, 5, 29)),
        isFalse,
      );

      final modifiersDuringLeave = service.computeRaceModifiers(
        rider: rider,
        profile: fullLeave.profile,
        activeEvents: [fullLeave.event],
        raceDate: DateTime(2026, 5, 20),
      );
      expect(modifiersDuringLeave.isAvailableForSelection, isFalse);
      expect(modifiersDuringLeave.unavailabilityReason, isNotNull);

      final forcedStay = service.resolvePaternityLeaveDecision(
        event: birthEvent,
        profile: profile,
        option: PaternityLeaveOption.stayOnRaceRoster,
        decisionDate: decisionDate,
      );
      expect(forcedStay.profile.isOnPaternityLeaveAt(decisionDate), isFalse);
      expect(forcedStay.event.moraleDelta, -16);
      expect(forcedStay.event.loyaltyDelta, -10);
      expect(
        forcedStay.event.status,
        PersonalEventResolutionStatus.resolvedStrained,
      );
    });

    test('evaluates home race tiers accurately from city to country', () {
      final rider = _buildTestRider(
        id: 'rider_3',
        firstName: 'Jan',
        lastName: 'Zieliński',
        nationalityIso: 'POL',
      );
      final profile = service.createInitialProfile(
        rider,
        hometown: 'Kraków',
        homeRegion: 'Małopolska',
      );

      final hometownEvent = service.evaluateHomeRaceMotivation(
        rider: rider,
        profile: profile,
        raceName: 'Tour de Pologne',
        raceCountryIso: 'POL',
        raceRegionName: 'Małopolska',
        racePassThroughCity: 'Kraków',
        raceDate: DateTime(2026, 8, 5),
      );
      expect(hometownEvent, isNotNull);
      expect(hometownEvent!.homeRaceTier, HomeRaceBonusTier.hometownVillage);
      expect(hometownEvent.formAdrenalineMultiplier, 1.045);

      final regionEvent = service.evaluateHomeRaceMotivation(
        rider: rider,
        profile: profile,
        raceName: 'Małopolski Wyścig Górski',
        raceCountryIso: 'POL',
        raceRegionName: 'Małopolska',
        racePassThroughCity: 'Nowy Sącz',
        raceDate: DateTime(2026, 6, 4),
      );
      expect(regionEvent!.homeRaceTier, HomeRaceBonusTier.homeRegion);

      final countryEvent = service.evaluateHomeRaceMotivation(
        rider: rider,
        profile: profile,
        raceName: 'Wyścig Solidarności',
        raceCountryIso: 'POL',
        raceRegionName: 'Łódzkie',
        racePassThroughCity: 'Łódź',
        raceDate: DateTime(2026, 6, 28),
      );
      expect(countryEvent!.homeRaceTier, HomeRaceBonusTier.homeCountry);

      final foreignEvent = service.evaluateHomeRaceMotivation(
        rider: rider,
        profile: profile,
        raceName: 'Tour de France',
        raceCountryIso: 'FRA',
        raceRegionName: 'Sabaudia',
        racePassThroughCity: 'Chambéry',
        raceDate: DateTime(2026, 7, 15),
      );
      expect(foreignEvent, isNull);
    });

    test('daily tick triggers due birth and expires finished paternity leave',
        () {
      final rider = _buildTestRider(
        id: 'rider_4',
        firstName: 'Tomasz',
        lastName: 'Maj',
      );
      final dueDate = DateTime(2026, 5, 15);
      final profile = service.createInitialProfile(
        rider,
        expectingChildDueDate: dueDate,
      );

      final tick = service.evaluateDailyLifeEvents(
        roster: [rider],
        profiles: {rider.id: profile},
        existingEvents: const [],
        currentDate: dueDate,
      );
      expect(tick.newlyTriggeredEvents.length, 1);
      expect(
        tick.newlyTriggeredEvents.first.type,
        PersonalLifeEventType.childBirth,
      );
      expect(tick.updatedProfiles[rider.id]!.expectingChildDueDate, isNull);
    });
  });

  group('RiderPersonalLifeAndFamilyEventsPanel Widget Tests', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size,
      List<Rider> roster,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: RiderPersonalLifeAndFamilyEventsPanel(roster: roster),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders without overflow on 390x844, 1024x768, and 1600x900',
        (tester) async {
      final roster = [
        _buildTestRider(
          id: 'r1',
          firstName: 'Michał',
          lastName: 'Kwiatkowski',
        ),
        _buildTestRider(
          id: 'r2',
          firstName: 'Rafał',
          lastName: 'Majka',
        ),
      ];

      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpPanelAtSize(tester, size, roster);
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Michał Kwiatkowski'), findsWidgets);
      }
    });

    testWidgets('supports childbirth trigger, paternity decision, and home race check',
        (tester) async {
      final roster = [
        _buildTestRider(
          id: 'r1',
          firstName: 'Michał',
          lastName: 'Kwiatkowski',
          nationalityIso: 'POL',
        ),
      ];

      await pumpPanelAtSize(tester, const Size(1600, 900), roster);

      await tester.tap(find.text('Narodziny').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Pełny Urlop (14 dni)'), findsOneWidget);

      await tester.tap(find.text('Pełny Urlop (14 dni)'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Aktywny Urlop'), findsOneWidget);

      await tester.tap(find.text('Sprawdź Domowy Wyścig'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Tour de Pologne'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
