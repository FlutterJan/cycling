import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/services/career/rider_mentorship_and_tutoring_service.dart';

Rider _buildTestRider({
  required String id,
  required String firstName,
  required String lastName,
  required int ageYears,
  String teamId = 'team_wt_1',
  String nationalityIso = 'POL',
  RiderSpecialization specialization = RiderSpecialization.classicCobbles,
  int raceIq = 85,
  int bikeHandling = 85,
  int draftingEfficiency = 82,
  int cobbles = 80,
  int descending = 80,
  int potential = 88,
}) {
  final refNow = DateTime(2026, 6, 15);
  return Rider(
    id: id,
    firstName: firstName,
    lastName: lastName,
    nationalityIso: nationalityIso,
    birthDate: DateTime(refNow.year - ageYears, 1, 10),
    potential: potential,
    specialization: specialization,
    physiology: const RiderPhysiology(
      heightCm: 180,
      weightKg: 71.0,
      bodyFatPercentage: 7.0,
      ftpWatts: 405,
      wPrimeJoules: 24000,
      vo2Max: 83.0,
      maxHr: 192,
      restingHr: 40,
      lactateThresholdHr: 174,
      recoveryRate: 86.0,
      glycogenCapacityGrams: 520.0,
    ),
    powerProfile: const RiderPowerProfile(
      watts5s: 1320,
      watts15s: 1080,
      watts30s: 840,
      watts1m: 710,
      watts3m: 510,
      watts5m: 465,
      watts20m: 405,
      watts60m: 380,
    ),
    skills: RiderSkills(
      cobbles: cobbles,
      descending: descending,
      bikeHandling: bikeHandling,
      aeroPositioning: 80,
      draftingEfficiency: draftingEfficiency,
      raceIq: raceIq,
      rainResistance: 78,
      heatTolerance: 78,
      timeTrialPositioning: 76,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#F2C9AC',
      hairStyleIndex: 2,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
      glassesModelId: 'glasses_pro',
      glassesLensColorHex: '#D4AF37',
      helmetModelId: 'helmet_aero',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.5,
      bodyBuildType: BodyBuildType.allRounder,
    ),
    contract: RiderContract(
      teamId: teamId,
      role: ageYears >= 30 ? RiderRole.teamLeader : RiderRole.domestique,
      monthlySalaryEur: ageYears >= 30 ? 85000 : 12000,
      signingBonusEur: 15000,
      winBonusEur: 5000,
      releaseClauseEur: 500000,
      contractEndYear: 2028,
      morale: 84.0,
      leaderLoyalty: 88.0,
      requiredRacesIds: const ['roubaix'],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 38.0,
      chronicTrainingLoad: 82.0,
    ),
    careerPointsUci: ageYears >= 30 ? 1850 : 95,
  );
}

void main() {
  const service = RiderMentorshipAndTutoringService();
  final refDate = DateTime(2026, 6, 15);

  group('RiderMentorshipAndTutoringService - Eligibility & Compatibility', () {
    test('veteran >32 lat z wysokim raceIq i bikeHandling kwalifikuje się jako mentor', () {
      final veteran = _buildTestRider(
        id: 'vet_1',
        firstName: 'Michał',
        lastName: 'Kwiatkowski',
        ageYears: 35,
        raceIq: 93,
        bikeHandling: 90,
      );
      final assessment = service.assessMentorCandidate(
        veteran,
        referenceDate: refDate,
      );
      expect(assessment.isEligible, isTrue);
      expect(assessment.ageYears, 35);
      expect(assessment.mentorRating, greaterThanOrEqualTo(85));
    });

    test('kolarz w wieku 32 lat lub ze zbyt niskimi umiejętnościami nie jest mentorem', () {
      final age32 = _buildTestRider(
        id: 'vet_32',
        firstName: 'Jan',
        lastName: 'Nowak',
        ageYears: 32,
        raceIq: 90,
        bikeHandling: 90,
      );
      final lowSkills = _buildTestRider(
        id: 'vet_low',
        firstName: 'Piotr',
        lastName: 'Zieliński',
        ageYears: 34,
        raceIq: 68,
        bikeHandling: 70,
      );

      expect(
        service.assessMentorCandidate(age32, referenceDate: refDate).status,
        MentorshipEligibilityStatus.ineligibleAge,
      );
      expect(
        service.assessMentorCandidate(lowSkills, referenceDate: refDate).status,
        MentorshipEligibilityStatus.ineligibleSkills,
      );
    });

    test('19-letni neoprofesjonalista kwalifikuje się z flagą isNeoPro19', () {
      final neoPro = _buildTestRider(
        id: 'neo_19',
        firstName: 'Kacper',
        lastName: 'Młody',
        ageYears: 19,
        raceIq: 58,
        bikeHandling: 60,
        draftingEfficiency: 59,
        potential: 92,
      );

      final assessment = service.assessMenteeCandidate(
        neoPro,
        referenceDate: refDate,
      );
      expect(assessment.isEligible, isTrue);
      expect(assessment.isNeoPro19, isTrue);
      expect(assessment.ageYears, 19);
    });

    test('evaluateCompatibility gwarantuje co najmniej +40% przyspieszenia rozwoju', () {
      final veteran = _buildTestRider(
        id: 'vet_1',
        firstName: 'Greg',
        lastName: 'Van Avermaet',
        ageYears: 36,
        nationalityIso: 'BEL',
        specialization: RiderSpecialization.classicCobbles,
        raceIq: 91,
        bikeHandling: 89,
      );
      final neoPro = _buildTestRider(
        id: 'neo_19',
        firstName: 'Arnaud',
        lastName: 'De Lie Jr',
        ageYears: 19,
        nationalityIso: 'BEL',
        specialization: RiderSpecialization.classicCobbles,
        raceIq: 55,
        bikeHandling: 58,
        draftingEfficiency: 56,
      );

      final compatibility = service.evaluateCompatibility(
        mentor: veteran,
        mentee: neoPro,
        focusArea: MentorshipFocusArea.holisticRoadCaptaincy,
        referenceDate: refDate,
      );

      expect(compatibility.baseAccelerationMultiplier, 1.40);
      expect(compatibility.effectiveDevelopmentMultiplier, greaterThanOrEqualTo(1.40));
      expect(compatibility.accelerationPercent, greaterThanOrEqualTo(40));
      expect(compatibility.sameSpecialization, isTrue);
      expect(compatibility.sameNationality, isTrue);
    });
  });

  group('RiderMentorshipAndTutoringService - Assignment & Progression', () {
    test('przypisanie mentora i symulacja bloków rozwijają taktykę oraz jazdę w peletonie', () {
      final veteran = _buildTestRider(
        id: 'vet_1',
        firstName: 'Maciej',
        lastName: 'Bodnar',
        ageYears: 35,
        raceIq: 90,
        bikeHandling: 88,
        draftingEfficiency: 90,
      );
      final neoPro = _buildTestRider(
        id: 'neo_19',
        firstName: 'Filip',
        lastName: 'Maciejuk',
        ageYears: 19,
        raceIq: 56,
        bikeHandling: 58,
        draftingEfficiency: 55,
        cobbles: 54,
        descending: 57,
      );

      final assignResult = service.tryAssignMentor(
        mentor: veteran,
        mentee: neoPro,
        existingAssignments: const [],
        focusArea: MentorshipFocusArea.pelotonPositioningAndDrafting,
        assignedDate: refDate,
      );

      expect(assignResult.success, isTrue);
      expect(assignResult.assignment, isNotNull);
      expect(assignResult.assignment!.tacticalAccelerationBonus, 0.40);
      expect(assignResult.assignment!.pelotonAccelerationBonus, 0.40);

      final step = service.applyMentorshipDevelopmentTick(
        assignment: assignResult.assignment!,
        mentor: veteran,
        mentee: neoPro,
        daysElapsed: 30,
        racedTogether: true,
        sessionDate: refDate.add(const Duration(days: 30)),
      );

      expect(step.appliedDevelopmentMultiplier, greaterThanOrEqualTo(1.40));
      expect(step.totalPointsGainedThisStep, greaterThan(0));
      expect(step.updatedMentee.skills.raceIq, greaterThan(neoPro.skills.raceIq));
      expect(
        step.updatedMentee.skills.draftingEfficiency +
            step.updatedMentee.skills.bikeHandling,
        greaterThan(
          neoPro.skills.draftingEfficiency + neoPro.skills.bikeHandling,
        ),
      );
      expect(step.updatedAssignment.completedDays, 30);
      expect(step.updatedAssignment.sessionsCompleted, 1);

      // Round-trip JSON
      final restored = MentorshipAssignment.fromJson(
        step.updatedAssignment.toJson(),
      );
      expect(restored.id, step.updatedAssignment.id);
      expect(restored.completedDays, 30);
      expect(restored.tacticalAccelerationBonus, 0.40);
    });

    test('walidacja odrzuca przypisanie z innej drużyny lub tego samego kolarza', () {
      final veteran = _buildTestRider(
        id: 'vet_1',
        firstName: 'Marek',
        lastName: 'Rutkiewicz',
        ageYears: 36,
        teamId: 'team_a',
      );
      final neoOtherTeam = _buildTestRider(
        id: 'neo_2',
        firstName: 'Antoni',
        lastName: 'Kowal',
        ageYears: 19,
        teamId: 'team_b',
      );

      final sameRiderResult = service.tryAssignMentor(
        mentor: veteran,
        mentee: veteran,
        existingAssignments: const [],
        assignedDate: refDate,
      );
      expect(sameRiderResult.success, isFalse);
      expect(sameRiderResult.failureReason, MentorshipEligibilityStatus.sameRider);

      final diffTeamResult = service.tryAssignMentor(
        mentor: veteran,
        mentee: neoOtherTeam,
        existingAssignments: const [],
        assignedDate: refDate,
      );
      expect(diffTeamResult.success, isFalse);
      expect(diffTeamResult.failureReason, MentorshipEligibilityStatus.differentTeam);
    });
  });

  group('RiderMentorshipAndTutoringPanel - Responsive UI', () {
    final roster = [
      _buildTestRider(
        id: 'vet_1',
        firstName: 'Michał',
        lastName: 'Kwiatkowski',
        ageYears: 35,
        raceIq: 92,
        bikeHandling: 90,
      ),
      _buildTestRider(
        id: 'neo_19',
        firstName: 'Kacper',
        lastName: 'Młody',
        ageYears: 19,
        raceIq: 58,
        bikeHandling: 60,
        draftingEfficiency: 57,
      ),
    ];

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnień dla ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RiderMentorshipAndTutoringPanel(roster: roster),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Akademia Mentoringu Weteranów'), findsOneWidget);
          expect(find.text('Michał Kwiatkowski'), findsOneWidget);
          expect(find.text('Kacper Młody'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('przypisanie mentora i symulacja 14 dni działają interaktywnie',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      List<MentorshipAssignment> capturedAssignments = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RiderMentorshipAndTutoringPanel(
              roster: roster,
              onAssignmentsChanged: (a) => capturedAssignments = a,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Przypisz Mentora (+40% Taktyka & Peleton)'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(capturedAssignments.length, 1);
      expect(find.text('Symuluj Blok (14 dni)'), findsOneWidget);

      await tester.tap(find.text('Symuluj Blok (14 dni)'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(capturedAssignments.first.completedDays, 14);
      expect(tester.takeException(), isNull);
    });
  });
}
