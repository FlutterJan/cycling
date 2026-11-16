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
import 'package:pro_peloton_manager/services/career/youth_race_calendar_u23_simulator.dart';

Rider _makeJuniorRider({
  required String id,
  required String firstName,
  required String lastName,
  required RiderSpecialization specialization,
  required double weightKg,
  required int watts20m,
  required int watts5m,
  required int watts1m,
  required int watts5s,
  required int ftpWatts,
  int cobbles = 65,
  int potential = 88,
}) {
  return Rider(
    id: id,
    firstName: firstName,
    lastName: lastName,
    nationalityIso: 'POL',
    birthDate: DateTime(2006, 4, 15),
    potential: potential,
    specialization: specialization,
    physiology: RiderPhysiology(
      heightCm: 176,
      weightKg: weightKg,
      bodyFatPercentage: 7.5,
      ftpWatts: ftpWatts,
      wPrimeJoules: 22000,
      vo2Max: 84.5,
      maxHr: 198,
      restingHr: 38,
      lactateThresholdHr: 178,
      recoveryRate: 0.90,
      glycogenCapacityGrams: 580,
      form: 88.0,
      fatigue: 12.0,
    ),
    powerProfile: RiderPowerProfile(
      watts5s: watts5s,
      watts15s: (watts5s * 0.85).round(),
      watts30s: (watts1m * 1.2).round(),
      watts1m: watts1m,
      watts3m: (watts5m * 1.08).round(),
      watts5m: watts5m,
      watts20m: watts20m,
      watts60m: ftpWatts,
    ),
    skills: RiderSkills(
      cobbles: cobbles,
      descending: 78,
      bikeHandling: 80,
      aeroPositioning: 74,
      draftingEfficiency: 76,
      raceIq: 82,
      rainResistance: 74,
      heatTolerance: 75,
      timeTrialPositioning: 74,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 0,
      skinToneHex: '#E8C3A0',
      hairStyleIndex: 1,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
      glassesModelId: 'aero_pro',
      glassesLensColorHex: '#D4AF37',
      helmetModelId: 'aero_carbon',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.75,
      bodyBuildType: BodyBuildType.allRounder,
    ),
    contract: const RiderContract(
      teamId: 'devo_team_1',
      role: RiderRole.neoPro,
      monthlySalaryEur: 2000,
      signingBonusEur: 0,
      winBonusEur: 800,
      releaseClauseEur: 75000,
      contractEndYear: 2026,
      morale: 85.0,
      leaderLoyalty: 80.0,
      requiredRacesIds: [],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 18.0,
      chronicTrainingLoad: 85.0,
    ),
    careerPointsUci: 45,
  );
}

void main() {
  group('YouthRaceCalendarU23Simulator', () {
    const simulator = YouthRaceCalendarU23Simulator(seed: 231);

    final eliteClimber = _makeJuniorRider(
      id: 'jr_climber',
      firstName: 'Jan',
      lastName: 'Kowalski',
      specialization: RiderSpecialization.gcClimber,
      weightKg: 59.0,
      watts20m: 382, // ~6.47 W/kg
      watts5m: 445,
      watts1m: 580,
      watts5s: 1050,
      ftpWatts: 360,
      potential: 94,
    );

    final eliteCobbler = _makeJuniorRider(
      id: 'jr_cobbler',
      firstName: 'Piotr',
      lastName: 'Nowak',
      specialization: RiderSpecialization.classicCobbles,
      weightKg: 74.0,
      watts20m: 418,
      watts5m: 495,
      watts1m: 740,
      watts5s: 1460,
      ftpWatts: 400,
      cobbles: 92,
      potential: 89,
    );

    test('officialCalendar contains Tour de l\'Avenir, Giro Next Gen and Paris-Roubaix Espoirs', () {
      final calendar = simulator.getCalendar();
      final names = calendar.map((r) => r.name).toList();

      expect(names, contains('Tour de l\'Avenir'));
      expect(names, contains('Giro Next Gen (Baby Giro)'));
      expect(names, contains('Paris-Roubaix Espoirs'));
      expect(calendar.first.month, lessThanOrEqualTo(calendar.last.month));
    });

    test('simulateRace records detailed W/kg telemetry and stage breakdown for Tour de l\'Avenir', () {
      final avenir = simulator.getCalendar().firstWhere(
            (r) => r.id == 'u23_tour_de_lavenir',
          );

      final report = simulator.simulateRace(
        race: avenir,
        playerDevoRiders: [eliteClimber, eliteCobbler],
        seasonYear: 2026,
      );

      expect(report.standings.length, greaterThanOrEqualTo(32));
      expect(report.playerDevoResults.length, 2);

      final climberResult = report.standings.firstWhere(
        (e) => e.riderId == eliteClimber.id,
      );
      expect(climberResult.stageBreakdown.length, avenir.stageCount);
      expect(climberResult.telemetry.peak20mWattsPerKg, greaterThan(5.8));
      expect(climberResult.telemetry.vamMetersPerHour, greaterThan(1500));
      expect(climberResult.gcPosition, lessThanOrEqualTo(5));
    });

    test('Paris-Roubaix Espoirs favors cobbles specialist over pure lightweight climber', () {
      final roubaix = simulator.getCalendar().firstWhere(
            (r) => r.id == 'u23_paris_roubaix_espoirs',
          );

      final report = simulator.simulateRace(
        race: roubaix,
        playerDevoRiders: [eliteClimber, eliteCobbler],
        seasonYear: 2026,
      );

      final cobblerPos = report.standings
          .firstWhere((e) => e.riderId == eliteCobbler.id)
          .gcPosition;
      final climberPos = report.standings
          .firstWhere((e) => e.riderId == eliteClimber.id)
          .gcPosition;

      expect(cobblerPos, lessThan(climberPos));
    });

    test('buildProContractScoutingDossier evaluates readiness tier and W/kg stats', () {
      final avenir = simulator.getCalendar().firstWhere(
            (r) => r.id == 'u23_tour_de_lavenir',
          );
      final giro = simulator.getCalendar().firstWhere(
            (r) => r.id == 'u23_giro_next_gen',
          );

      final r1 = simulator.simulateRace(
        race: avenir,
        playerDevoRiders: [eliteClimber],
      );
      final r2 = simulator.simulateRace(
        race: giro,
        playerDevoRiders: [eliteClimber],
      );

      final dossier = simulator.buildProContractScoutingDossier(
        rider: eliteClimber,
        seasonReports: [r1, r2],
      );

      expect(dossier.racesTracked, 2);
      expect(dossier.best20mWattsPerKg, greaterThan(6.0));
      expect(dossier.readinessTier, ProContractReadinessTier.worldTourReady);
      expect(dossier.isReadyForProContract, isTrue);
      expect(dossier.recommendedContractYears, 3);

      final unproven = simulator.buildProContractScoutingDossier(
        rider: eliteCobbler,
        seasonReports: const [],
      );
      expect(unproven.readinessTier, ProContractReadinessTier.unprovenProspect);
      expect(unproven.isReadyForProContract, isFalse);
    });

    test('YouthU23RaceSimulationReport serializes and deserializes cleanly', () {
      final giro = simulator.getCalendar().firstWhere(
            (r) => r.id == 'u23_giro_next_gen',
          );
      final report = simulator.simulateRace(
        race: giro,
        playerDevoRiders: [eliteClimber],
      );

      final json = report.toJson();
      final decoded = YouthU23RaceSimulationReport.fromJson(json);

      expect(decoded.race.id, report.race.id);
      expect(decoded.standings.length, report.standings.length);
      expect(
        decoded.standings.first.telemetry.peak20mWattsPerKg,
        report.standings.first.telemetry.peak20mWattsPerKg,
      );
    });
  });

  group('YouthRaceCalendarU23Panel responsive & interaction tests', () {
    final rider = _makeJuniorRider(
      id: 'jr_ui_1',
      firstName: 'Marek',
      lastName: 'Wójcik',
      specialization: RiderSpecialization.gcClimber,
      weightKg: 60.0,
      watts20m: 378,
      watts5m: 440,
      watts1m: 590,
      watts5s: 1120,
      ftpWatts: 356,
    );

    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      void Function(JuniorProContractScoutingDossier)? onSign,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: YouthRaceCalendarU23Panel(
              devoRiders: [rider],
              simulator: const YouthRaceCalendarU23Simulator(seed: 231),
              onSignProContract: onSign,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844 mobile without overflow', (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.textContaining('Kalendarz Wyścigów U23'), findsOneWidget);
      expect(find.text('Paris-Roubaix Espoirs'), findsWidgets);
    });

    testWidgets('renders cleanly at 1024x768 tablet and simulates race', (tester) async {
      JuniorProContractScoutingDossier? signedDossier;
      await pumpPanelAtSize(
        tester,
        const Size(1024, 768),
        onSign: (d) => signedDossier = d,
      );

      final simBtn = find.text('Symuluj wyścig');
      expect(simBtn, findsOneWidget);
      await tester.tap(simBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('W/kg'), findsWidgets);
      final signBtn = find.textContaining('Podpisz pierwszy kontrakt Pro');
      expect(signBtn, findsOneWidget);
      await tester.ensureVisible(signBtn);
      await tester.tap(signBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(signedDossier, isNotNull);
      expect(signedDossier!.racesTracked, 1);
    });

    testWidgets('renders cleanly at 1600x900 desktop', (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      await tester.tap(find.text('Symuluj cały sezon'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Sezon ukończony'), findsOneWidget);
      expect(find.text('20 min W/kg'), findsOneWidget);
    });
  });
}
