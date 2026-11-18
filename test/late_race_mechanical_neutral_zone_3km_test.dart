import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/events/race_incident_engine.dart';
import 'package:pro_peloton_manager/engine/peloton/late_race_mechanical_neutral_zone_3km.dart';

void main() {
  const engine = LateRaceMechanicalNeutralZoneEngine();

  const pelotonRider = RiderNeutralZoneEntry(
    riderId: 'r1',
    riderName: 'T. Pogacar',
    teamId: 'uae',
    teamShortCode: 'UAD',
    bibNumber: 1,
    groupIndexAtIncident: 1,
    groupLabel: 'Peleton główny',
    groupSizeAtIncident: 130,
    isGcContender: true,
  );

  const sprintConfig3Km = NeutralZoneConfig(
    stageId: 's1',
    stageName: 'Etap 1',
    stageTotalDistanceMeters: 180000.0,
    stageType: NeutralZoneStageType.flatSprint,
    distancePreset: NeutralZoneDistancePreset.standard3Km,
  );

  const sprintConfig5Km = NeutralZoneConfig(
    stageId: 's1',
    stageName: 'Etap 1',
    stageTotalDistanceMeters: 180000.0,
    stageType: NeutralZoneStageType.flatSprint,
    distancePreset: NeutralZoneDistancePreset.extended5Km,
    juryExtendedTo5Km: true,
  );

  final groupTimes = <int, double>{
    0: 14000.0,
    1: 14015.0,
    2: 14500.0,
  };

  group('LateRaceMechanicalNeutralZoneEngine', () {
    test('neutralizes crash/puncture inside 3 km and preserves stage rank', () {
      const incident = NeutralZoneIncidentRecord(
        incidentId: 'i1',
        rider: pelotonRider,
        incidentType: NeutralZoneIncidentType.puncture,
        distanceToFinishMeters: 2100.0,
        incidentRaceTimeSeconds: 13880.0,
        actualFinishTimeSeconds: 14105.0,
        actualStageRank: 118,
        details: 'Przebicie opony',
      );

      final result = engine.evaluateIncident(
        config: sprintConfig3Km,
        incident: incident,
        groupFinishTimesSeconds: groupTimes,
      );

      expect(result.status, NeutralZoneVerdictStatus.neutralized);
      expect(result.creditedGcTimeSeconds, 14015.0);
      expect(result.savedGcSeconds, 90.0);
      expect(result.stagePlacementRank, 118);
      expect(result.eligibleForStagePointsAndBonuses, isFalse);
    });

    test('3.65 km incident is rejected under 3 km rule but neutralized under 5 km', () {
      const incident = NeutralZoneIncidentRecord(
        incidentId: 'i2',
        rider: pelotonRider,
        incidentType: NeutralZoneIncidentType.mechanicalFailure,
        distanceToFinishMeters: 3650.0,
        incidentRaceTimeSeconds: 13750.0,
        actualFinishTimeSeconds: 14095.0,
        actualStageRank: 99,
        details: 'Spadnięty łańcuch',
      );

      final res3Km = engine.evaluateIncident(
        config: sprintConfig3Km,
        incident: incident,
        groupFinishTimesSeconds: groupTimes,
      );
      expect(res3Km.status, NeutralZoneVerdictStatus.rejected);
      expect(res3Km.creditedGcTimeSeconds, 14095.0);
      expect(res3Km.savedGcSeconds, 0.0);

      final res5Km = engine.evaluateIncident(
        config: sprintConfig5Km,
        incident: incident,
        groupFinishTimesSeconds: groupTimes,
      );
      expect(res5Km.status, NeutralZoneVerdictStatus.neutralized);
      expect(res5Km.creditedGcTimeSeconds, 14015.0);
      expect(res5Km.savedGcSeconds, 80.0);
    });

    test('summit finish, ITT and one-day classic disable neutral zone', () {
      for (final stageType in [
        NeutralZoneStageType.summitFinish,
        NeutralZoneStageType.individualTimeTrial,
        NeutralZoneStageType.teamTimeTrial,
        NeutralZoneStageType.oneDayClassic,
      ]) {
        final cfg = sprintConfig3Km.copyWith(stageType: stageType);
        expect(cfg.isProtectionActiveForStage, isFalse);
        expect(cfg.activeZoneLengthMeters, 0.0);
        expect(cfg.isDistanceInsideZone(178500.0), isFalse);
      }
    });

    test('dropped on pace inside 3 km is not neutralized', () {
      const incident = NeutralZoneIncidentRecord(
        incidentId: 'i3',
        rider: pelotonRider,
        incidentType: NeutralZoneIncidentType.droppedOnPace,
        distanceToFinishMeters: 1500.0,
        incidentRaceTimeSeconds: 13900.0,
        actualFinishTimeSeconds: 14075.0,
        actualStageRank: 85,
        details: 'Brak sił',
      );

      final result = engine.evaluateIncident(
        config: sprintConfig3Km,
        incident: incident,
        groupFinishTimesSeconds: groupTimes,
      );

      expect(result.status, NeutralZoneVerdictStatus.rejected);
      expect(result.savedGcSeconds, 0.0);
    });

    test('DNF inside neutral zone receives dnfNoTime', () {
      const incident = NeutralZoneIncidentRecord(
        incidentId: 'i4',
        rider: pelotonRider,
        incidentType: NeutralZoneIncidentType.crash,
        distanceToFinishMeters: 800.0,
        incidentRaceTimeSeconds: 13960.0,
        actualFinishTimeSeconds: 0.0,
        actualStageRank: 0,
        crossedFinishLine: false,
        details: 'Złamany obojczyk',
      );

      final result = engine.evaluateIncident(
        config: sprintConfig3Km,
        incident: incident,
        groupFinishTimesSeconds: groupTimes,
      );

      expect(result.status, NeutralZoneVerdictStatus.dnfNoTime);
      expect(result.creditedGcTimeSeconds, 0.0);
    });

    test('maps IncidentType and supports JSON round-trip', () {
      expect(
        NeutralZoneIncidentType.fromEngineIncident(IncidentType.pelotonPileup),
        NeutralZoneIncidentType.crash,
      );

      final cfgJson = sprintConfig5Km.toJson();
      final restored = NeutralZoneConfig.fromJson(cfgJson);
      expect(restored.stageId, sprintConfig5Km.stageId);
      expect(restored.activeZoneLengthMeters, 5000.0);
    });
  });

  group('LateRaceMechanicalNeutralZonePanel', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LateRaceMechanicalNeutralZonePanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844, 1024x768 and 1600x900',
        (tester) async {
      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpPanelAtSize(tester, size);
        expect(tester.takeException(), isNull);
        expect(find.text('3 KM ZONE'), findsOneWidget);
      }
    });

    testWidgets('switching to 5 km preset updates badge and neutralizes 3.65 km',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1200, 840));

      await tester.tap(find.text('5 km (Rozszerzona Sprint)'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('5 KM ZONE'), findsOneWidget);
      expect(find.text('GC ZNEUTRALIZOWANE'), findsNWidgets(2));
    });

    testWidgets('switching to summit finish disables neutral zone',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1200, 840));

      await tester.tap(find.text('Szczytowy'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('NO NEUTRAL ZONE'), findsOneWidget);
    });
  });
}
