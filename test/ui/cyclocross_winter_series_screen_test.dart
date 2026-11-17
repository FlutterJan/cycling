import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/cyclocross_course_and_mud_model.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/ui/screens/cyclocross_winter_series_screen.dart';

void main() {
  group('CyclocrossWinterSeriesScreen — Logika i Fizyka', () {
    test('katalog zawiera 8 kultowych wyścigów CX od listopada do stycznia z MŚ', () {
      final races = CyclocrossWinterCalendarCatalog.build8IconicRaces();

      expect(races.length, 8);
      expect(
        races.every((r) => r.course.isWinterWindowValid),
        isTrue,
      );
      expect(
        races.where((r) => r.isWorldChampionship).length,
        1,
      );
      expect(
        races.map((r) => r.course.raceMonth).toSet(),
        containsAll([
          CyclocrossMonth.november,
          CyclocrossMonth.december,
          CyclocrossMonth.january,
        ]),
      );
    });

    test('dobór ciśnienia w szytkach (1.30–1.80 bar) wykrywa okno optymalne i ryzyko dobicia', () {
      final races = CyclocrossWinterCalendarCatalog.build8IconicRaces();
      final gavere = races[3].course;

      final optimal = CyclocrossPhysicsAdvisor.analyzeTirePressure(
        course: gavere,
        pressureBar: 1.44,
        tread: CyclocrossTubularTread.mudAggressive,
        riderWeightKg: 70.0,
      );
      final tooLow = CyclocrossPhysicsAdvisor.analyzeTirePressure(
        course: gavere,
        pressureBar: 1.30,
        tread: CyclocrossTubularTread.mudAggressive,
        riderWeightKg: 78.0,
      );
      final tooHigh = CyclocrossPhysicsAdvisor.analyzeTirePressure(
        course: gavere,
        pressureBar: 1.80,
        tread: CyclocrossTubularTread.sandFile,
        riderWeightKg: 70.0,
      );

      expect(optimal.isOptimalWindow, isTrue);
      expect(tooLow.rimStrikeRiskPercent, greaterThan(optimal.rimStrikeRiskPercent));
      expect(tooHigh.tractionScorePercent, lessThan(optimal.tractionScorePercent));
    });

    test('start zimowy CX podnosi bikeHandling, cobbles oraz moc 1m i 5m kolarza szosowego', () {
      final races = CyclocrossWinterCalendarCatalog.build8IconicRaces();
      final worlds = races.last;

      Rider? capturedUpdated;
      const screen = CyclocrossWinterSeriesScreen();
      expect(screen, isNotNull);

      final baseResult = CyclocrossPhysicsAdvisor.simulateWinterRace(
        race: worlds,
        rider: _sampleTestRider(),
        pressureBar: 1.45,
        tread: CyclocrossTubularTread.mudAggressive,
      );
      final before = _sampleTestRider();
      capturedUpdated = baseResult.careerBonus.applyToRider(before);

      expect(
        capturedUpdated.skills.bikeHandling,
        greaterThan(before.skills.bikeHandling),
      );
      expect(
        capturedUpdated.skills.cobbles,
        greaterThan(before.skills.cobbles),
      );
      expect(
        capturedUpdated.powerProfile.watts1m,
        greaterThan(before.powerProfile.watts1m),
      );
      expect(
        capturedUpdated.powerProfile.watts5m,
        greaterThan(before.powerProfile.watts5m),
      );
      expect(
        capturedUpdated.careerPointsUci,
        greaterThan(before.careerPointsUci),
      );
    });
  });

  group('CyclocrossWinterSeriesScreen — Widget i Responsywność', () {
    Future<void> pumpWithSize(
      WidgetTester tester,
      Size size, {
      ValueChanged<Rider>? onRiderUpdated,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: CyclocrossWinterSeriesScreen(
            onRiderUpdated: onRiderUpdated,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnień w rozdzielczości ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await pumpWithSize(tester, size);

          expect(find.text('Zimowy Puchar Przełajowy (CX)'), findsOneWidget);
          expect(find.text('Koppenbergcross'), findsOneWidget);
          expect(find.text('Ciśnienie Szytek CX (1.30–1.80 bar)'), findsOneWidget);
          expect(find.text('Integracja z Karierą Szosową'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('interakcja: filtr miesiąca, regulacja ciśnienia i start w przełaju',
        (tester) async {
      Rider? updatedRider;
      await pumpWithSize(
        tester,
        const Size(1600, 900),
        onRiderUpdated: (r) => updatedRider = r,
      );

      // Filtracja do stycznia (GP Adrie van der Poel + Mistrzostwa Świata CX UCI)
      await tester.tap(find.text('Styczeń'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Mistrzostwa Świata CX UCI'), findsOneWidget);
      expect(find.text('Koppenbergcross'), findsNothing);

      // Wybór Mistrzostw Świata CX
      await tester.tap(find.text('Mistrzostwa Świata CX UCI'));
      await tester.pump(const Duration(milliseconds: 300));

      // Start w wyścigu i weryfikacja aktualizacji kariery szosowej
      await tester.tap(find.text('Wystartuj w Mistrzostwa Świata CX UCI'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(updatedRider, isNotNull);
      expect(find.text('Start ukończony — premia dodana'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Rider _sampleTestRider() => _buildRider();

Rider _buildRider() {
  return const CyclocrossRoadCareerBonus(
    bikeHandlingGain: 0,
    cobblesGain: 0,
    watts1mGain: 0,
    watts5mGain: 0,
    ctlFitnessDelta: 0,
    atlFatigueDelta: 0,
    uciPointsEarned: 0,
  ).applyToRider(
    Rider(
      id: 'test_r1',
      firstName: 'Jan',
      lastName: 'Nowak',
      nationalityIso: 'POL',
      birthDate: DateTime(1999, 3, 15),
      potential: 88,
      specialization: RiderSpecialization.classicCobbles,
      physiology: const RiderPhysiology(
        heightCm: 181.0,
        weightKg: 71.0,
        bodyFatPercentage: 7.5,
        ftpWatts: 410,
        wPrimeJoules: 26000,
        vo2Max: 82.0,
        maxHr: 195,
        restingHr: 40,
        lactateThresholdHr: 177,
        recoveryRate: 1.12,
        glycogenCapacityGrams: 520.0,
      ),
      powerProfile: const RiderPowerProfile(
        watts5s: 1300,
        watts15s: 1050,
        watts30s: 840,
        watts1m: 690,
        watts3m: 520,
        watts5m: 475,
        watts20m: 430,
        watts60m: 410,
      ),
      skills: const RiderSkills(
        cobbles: 78,
        descending: 80,
        bikeHandling: 82,
        aeroPositioning: 78,
        draftingEfficiency: 80,
        raceIq: 81,
        rainResistance: 82,
        heatTolerance: 75,
        timeTrialPositioning: 76,
      ),
      appearance: const RiderAppearance(
        faceShapeIndex: 0,
        skinToneHex: '#FFDBAC',
        hairStyleIndex: 1,
        hairColorHex: '#3B2F2F',
        facialHairIndex: 0,
        glassesModelId: 'aero_pro',
        glassesLensColorHex: '#D4AF37',
        helmetModelId: 'aero_road',
        shoeColorHex: '#FFFFFF',
        sockHeightProportion: 0.70,
        bodyBuildType: BodyBuildType.allRounder,
      ),
      contract: const RiderContract(
        teamId: 'player_team',
        role: RiderRole.teamLeader,
        monthlySalaryEur: 50000,
        signingBonusEur: 50000,
        winBonusEur: 10000,
        releaseClauseEur: 1000000,
        contractEndYear: 2028,
        morale: 85.0,
        leaderLoyalty: 85.0,
        requiredRacesIds: [],
      ),
      health: const RiderHealth(
        acuteTrainingLoad: 30.0,
        chronicTrainingLoad: 75.0,
      ),
      careerPointsUci: 1000,
    ),
  );
}
