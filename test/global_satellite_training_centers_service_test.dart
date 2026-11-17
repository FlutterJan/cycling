import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/global_satellite_training_centers_service.dart';

void main() {
  group('GlobalSatelliteTrainingCentersService', () {
    const service = GlobalSatelliteTrainingCentersService();
    final baseDate = DateTime(2026, 2, 1);

    test('createInitialNetwork creates all 4 canonical satellite regions', () {
      final network = service.createInitialNetwork(currentDate: baseDate);

      expect(network.length, 4);
      expect(
        network.keys,
        containsAll(SatelliteAcademyRegionId.values),
      );
      expect(
        network[SatelliteAcademyRegionId.sierraNevadaGranada]!.isBuilt,
        isTrue,
      );
      expect(
        network[SatelliteAcademyRegionId.colombiaBoyaca]!.isBuilt,
        isFalse,
      );
      expect(
        network[SatelliteAcademyRegionId.eastAfricaRiftValley]!
            .regionId
            .altitudeMeters,
        2400,
      );
    });

    test('unlockOrUpgradeAcademy validates budget and advances tiers up to 4', () {
      final network = service.createInitialNetwork(currentDate: baseDate);
      var colombia = network[SatelliteAcademyRegionId.colombiaBoyaca]!;

      final failResult = service.unlockOrUpgradeAcademy(
        node: colombia,
        availableBudgetEur: 50000,
        currentDate: baseDate,
      );
      expect(failResult.success, isFalse);

      var budget = 5000000.0;
      for (int expectedTier = 1; expectedTier <= 4; expectedTier++) {
        final res = service.unlockOrUpgradeAcademy(
          node: colombia,
          availableBudgetEur: budget,
          currentDate: baseDate,
        );
        expect(res.success, isTrue);
        expect(res.updatedNode!.tier, expectedTier);
        budget -= res.costEur;
        colombia = res.updatedNode!;
      }

      expect(colombia.status, SatelliteAcademyStatus.eliteFlagship);

      final maxRes = service.unlockOrUpgradeAcademy(
        node: colombia,
        availableBudgetEur: budget,
        currentDate: baseDate,
      );
      expect(maxRes.success, isFalse);
    });

    test('enrollRiderInCamp and advanceNetworkDays produce physiological gains', () {
      final network = service.createInitialNetwork(currentDate: baseDate);
      final sierra = network[SatelliteAcademyRegionId.sierraNevadaGranada]!;

      final enrollRes = service.enrollRiderInCamp(
        node: sierra,
        riderId: 'r_001',
        riderName: 'Jan Kowalski',
        durationDays: 14,
        intensity: AcademyCampIntensity.peakSupercompensation,
        currentDate: baseDate,
      );
      expect(enrollRes.success, isTrue);

      final updatedNetwork = Map<SatelliteAcademyRegionId, SatelliteAcademyNode>.from(
        network,
      )..[SatelliteAcademyRegionId.sierraNevadaGranada] = enrollRes.updatedNode!;

      final after14Days = service.advanceNetworkDays(
        network: updatedNetwork,
        days: 14,
        newCurrentDate: baseDate.add(const Duration(days: 14)),
      );

      final completedNode =
          after14Days[SatelliteAcademyRegionId.sierraNevadaGranada]!;
      final stint = completedNode.activeStints.first;
      expect(stint.isCompleted, isTrue);
      expect(stint.daysCompleted, 14);
      expect(stint.ftpGainWatts, greaterThan(0.0));
      expect(stint.altitudeGainPercent, greaterThan(0.0));
      expect(stint.vo2MaxGain, greaterThan(0.0));
    });

    test('scoutLocalProspect generates region-authentic profiles and promotes', () {
      final network = service.createInitialNetwork(currentDate: baseDate);
      final unlockedColombia = service.unlockOrUpgradeAcademy(
        node: network[SatelliteAcademyRegionId.colombiaBoyaca]!,
        availableBudgetEur: 1000000,
        currentDate: baseDate,
      ).updatedNode!;

      final scoutRes = service.scoutLocalProspect(
        node: unlockedColombia,
        availableBudgetEur: 500000,
        currentDate: baseDate,
        seed: 123,
      );
      expect(scoutRes.success, isTrue);
      expect(scoutRes.newProspect, isNotNull);
      expect(scoutRes.newProspect!.weightKg, lessThan(58.5));
      expect(
        ['COL', 'ECU'],
        contains(scoutRes.newProspect!.nationalityIso),
      );

      final promoteRes = service.promoteProspectToProRoster(
        node: scoutRes.updatedNode!,
        prospectId: scoutRes.newProspect!.id,
        currentDate: baseDate,
      );
      expect(promoteRes.success, isTrue);
      expect(promoteRes.updatedNode!.totalGraduatesPromoted, 1);
    });

    test('GlobalSatelliteTrainingCentersState JSON round-trip preserves data', () {
      final notifier = GlobalSatelliteTrainingCentersNotifier(
        initialBudgetEur: 2400000.0,
        initialDate: baseDate,
      );
      notifier.unlockOrUpgradeRegion(SatelliteAcademyRegionId.flandersKortrijk);
      notifier.setFocusMode(
        SatelliteAcademyRegionId.flandersKortrijk,
        SatelliteAcademyFocusMode.skillMastery,
      );

      final json = notifier.state.toJson();
      final restored = GlobalSatelliteTrainingCentersState.fromJson(json);

      expect(restored.teamBudgetEur, notifier.state.teamBudgetEur);
      expect(
        restored.nodes[SatelliteAcademyRegionId.flandersKortrijk]!.tier,
        1,
      );
      expect(
        restored.nodes[SatelliteAcademyRegionId.flandersKortrijk]!.focusMode,
        SatelliteAcademyFocusMode.skillMastery,
      );
    });
  });

  group('GlobalSatelliteTrainingCentersPanel responsive UI', () {
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
                  body: GlobalSatelliteTrainingCentersPanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Globalne Akademie Satelickie'), findsOneWidget);
          expect(find.text('Kolumbia'), findsOneWidget);
          expect(find.text('Sierra Nevada'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('interactive selection and simulation advance update UI', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GlobalSatelliteTrainingCentersPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Kolumbia'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Kolumbia — Boyacá / Andy'), findsOneWidget);

      await tester.tap(find.text('+7 dni symulacji'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.text('Zasymulowano 7 dni pracy sieci akademii.'),
        findsOneWidget,
      );
    });
  });
}
