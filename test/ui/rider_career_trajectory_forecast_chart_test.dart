import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/services/career/scouting_and_youth_academy_service.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';
import 'package:pro_peloton_manager/ui/widgets/rider_career_trajectory_forecast_chart.dart';

void main() {
  Rider buildTestRider({int targetOvr = 78, int age = 20}) {
    final base = RiderProceduralGenerator.generateRider(
      specialization: RiderSpecialization.gcClimber,
      targetOverallRating: targetOvr,
    );
    return Rider(
      id: base.id,
      firstName: base.firstName,
      lastName: base.lastName,
      nationalityIso: base.nationalityIso,
      birthDate: DateTime(2026 - age, 5, 12),
      potential: 92,
      specialization: base.specialization,
      physiology: base.physiology,
      powerProfile: base.powerProfile,
      skills: base.skills,
      appearance: base.appearance,
      contract: base.contract,
      health: base.health,
      careerPointsUci: base.careerPointsUci,
    );
  }

  ScoutedProspect buildTestProspect({
    required ScoutingDiscoveryStage stage,
    required Rider trueRider,
  }) {
    return ScoutedProspect(
      id: 'prospect_test_1',
      firstName: trueRider.firstName,
      lastName: trueRider.lastName,
      nationalityIso: trueRider.nationalityIso,
      age: 19,
      source: ScoutingSource.espoirsU23,
      discoveryStage: stage,
      estimatedMinFtpWatts: 330,
      estimatedMaxFtpWatts: 390,
      estimatedMinVo2Max: 74.0,
      estimatedMaxVo2Max: 84.0,
      estimatedMinPotential: 78,
      estimatedMaxPotential: 94,
      probableSpecialization: RiderSpecialization.gcClimber,
      scoutReport: 'Obiecujący góral U23 z mocnym progiem.',
      trueRider: trueRider,
    );
  }

  group('RiderCareerTrajectoryForecastCalculator', () {
    test('generuje dokładnie 6 punktów (Sezon 0..+5) i przedział ufności zależy od dokładności skauta', () {
      final rider = buildTestRider(targetOvr: 77, age: 20);

      final lowConfidence = RiderCareerTrajectoryForecastCalculator.buildFromRider(
        rider: rider,
        startSeasonYear: 2026,
        scoutAccuracy: 0.35,
      );
      final highConfidence = RiderCareerTrajectoryForecastCalculator.buildFromRider(
        rider: rider,
        startSeasonYear: 2026,
        scoutAccuracy: 0.96,
      );

      expect(lowConfidence.points.length, 6);
      expect(highConfidence.points.length, 6);
      expect(lowConfidence.points.first.seasonYear, 2026);
      expect(lowConfidence.points.last.seasonYear, 2031);

      // Niższa dokładność skauta => szerszy przedział ufności OVR i FTP
      expect(
        lowConfidence.points.last.confidenceBandOvr,
        greaterThan(highConfidence.points.last.confidenceBandOvr),
      );
      expect(
        lowConfidence.points.last.confidenceBandFtp,
        greaterThan(highConfidence.points.last.confidenceBandFtp),
      );

      // Przedział ufności rośnie z czasem (Sezon +5 > Sezon 0)
      expect(
        lowConfidence.points.last.confidenceBandOvr,
        greaterThan(lowConfidence.points.first.confidenceBandOvr),
      );
    });

    test('buildFromProspect zawęża przedział ufności po przejściu z rawTalent do laboratoryTested', () {
      final rider = buildTestRider(targetOvr: 75, age: 19);
      final rawProspect = buildTestProspect(
        stage: ScoutingDiscoveryStage.rawTalent,
        trueRider: rider,
      );
      final labProspect = buildTestProspect(
        stage: ScoutingDiscoveryStage.laboratoryTested,
        trueRider: rider,
      );

      final rawForecast = RiderCareerTrajectoryForecastCalculator.buildFromProspect(
        prospect: rawProspect,
        startSeasonYear: 2026,
      );
      final labForecast = RiderCareerTrajectoryForecastCalculator.buildFromProspect(
        prospect: labProspect,
        startSeasonYear: 2026,
      );

      expect(rawForecast.scoutAccuracyPercent, 35);
      expect(labForecast.scoutAccuracyPercent, 96);
      expect(
        rawForecast.points.first.confidenceBandFtp,
        greaterThan(labForecast.points.first.confidenceBandFtp),
      );
    });

    test('serializacja JSON toJson/fromJson zachowuje komplet danych prognozy', () {
      final rider = buildTestRider(targetOvr: 80, age: 22);
      final original = RiderCareerTrajectoryForecastCalculator.buildFromRider(
        rider: rider,
        startSeasonYear: 2026,
        scoutAccuracy: 0.72,
      );

      final decoded = RiderCareerTrajectoryForecastData.fromJson(original.toJson());
      expect(decoded.riderId, original.riderId);
      expect(decoded.points.length, original.points.length);
      expect(decoded.peakProjectedFtp, original.peakProjectedFtp);
      expect(decoded.points.last.ovrUpperBound, original.points.last.ovrUpperBound);
    });
  });

  group('RiderCareerTrajectoryForecastChart UI & Responsywność', () {
    Widget buildHost({
      required Size viewportSize,
      Rider? rider,
      ScoutedProspect? prospect,
      bool enabled = true,
      bool allowAccuracySimulation = false,
    }) {
      return MediaQuery(
        data: MediaQueryData(size: viewportSize),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: RiderCareerTrajectoryForecastChart(
                  rider: rider,
                  prospect: prospect,
                  startSeasonYear: 2026,
                  enabled: enabled,
                  allowAccuracySimulation: allowAccuracySimulation,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renderuje stan pusty oraz stan wyłączony bez błędów', (tester) async {
      await tester.pumpWidget(buildHost(viewportSize: const Size(1024, 768)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Brak danych kolarza'), findsOneWidget);

      final rider = buildTestRider();
      await tester.pumpWidget(
        buildHost(
          viewportSize: const Size(1024, 768),
          rider: rider,
          enabled: false,
          allowAccuracySimulation: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.textContaining('PROGNOZA ROZWOJU 5-LETNIEGO'), findsOneWidget);
    });

    testWidgets('przełącza metryki OVR / FTP (W) / OVR + FTP', (tester) async {
      final rider = buildTestRider();
      await tester.pumpWidget(
        buildHost(
          viewportSize: const Size(1200, 800),
          rider: rider,
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.text('OVR'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Prognoza OVR'), findsOneWidget);

      await tester.tap(find.text('FTP (W)'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Prognoza FTP (W)'), findsOneWidget);
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('brak przepełnień RenderFlex w rozdzielczości ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final rider = buildTestRider();
        final prospect = buildTestProspect(
          stage: ScoutingDiscoveryStage.scoutedByObserver,
          trueRider: rider,
        );

        await tester.pumpWidget(
          buildHost(
            viewportSize: size,
            prospect: prospect,
            allowAccuracySimulation: true,
          ),
        );
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.byType(RiderCareerTrajectoryForecastChart), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
