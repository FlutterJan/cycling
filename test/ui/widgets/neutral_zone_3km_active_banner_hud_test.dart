import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/late_race_mechanical_neutral_zone_3km.dart';
import 'package:pro_peloton_manager/ui/widgets/neutral_zone_3km_active_banner_hud.dart';

void main() {
  NeutralZoneBannerHudData buildSampleData({
    NeutralZoneStageType stageType = NeutralZoneStageType.flatSprint,
    NeutralZoneDistancePreset distancePreset =
        NeutralZoneDistancePreset.standard3Km,
    bool juryExtendedTo5Km = false,
    String? extensionReason,
    double remainingToFinishMeters = 2400.0,
    double zoneLengthMeters = 3000.0,
    int neutralizedIncidentsCount = 2,
    int pendingReviewCount = 1,
    bool isEnabled = true,
  }) {
    return NeutralZoneBannerHudData(
      stageName: 'Etap 4: Orleans – Saint-Amand-Montrond',
      stageType: stageType,
      distancePreset: distancePreset,
      juryExtendedTo5Km: juryExtendedTo5Km,
      extensionReason: extensionReason,
      remainingToFinishMeters: remainingToFinishMeters,
      zoneLengthMeters: zoneLengthMeters,
      neutralizedIncidentsCount: neutralizedIncidentsCount,
      pendingReviewCount: pendingReviewCount,
      isEnabled: isEnabled,
    );
  }

  group('NeutralZoneBannerHudData', () {
    test('returns active 3 KM ZONE headline when inside 3000m zone', () {
      final data = buildSampleData(remainingToFinishMeters: 2100.0);
      expect(data.status, NeutralZoneBannerStatus.active);
      expect(data.zoneBadgeText, '3 KM ZONE');
      expect(data.tvHeadlineText, '3 KM ZONE — GC TIMES NEUTRALIZED');
      expect(data.zoneProgress, closeTo(0.3, 0.001));
    });

    test('returns active 5 KM ZONE headline when jury extended to 5 km', () {
      final data = buildSampleData(
        distancePreset: NeutralZoneDistancePreset.extended5Km,
        juryExtendedTo5Km: true,
        extensionReason: 'Mokre ronda w końcówce',
        remainingToFinishMeters: 4000.0,
        zoneLengthMeters: 5000.0,
      );
      expect(data.status, NeutralZoneBannerStatus.active);
      expect(data.isFiveKmZone, isTrue);
      expect(data.zoneBadgeText, '5 KM ZONE');
      expect(data.tvHeadlineText, '5 KM ZONE — GC TIMES NEUTRALIZED');
    });

    test('returns approaching status when within 2 km before zone entry', () {
      final data = buildSampleData(remainingToFinishMeters: 4200.0);
      expect(data.status, NeutralZoneBannerStatus.approaching);
      expect(data.distanceToZoneEntryMeters, closeTo(1200.0, 0.001));
      expect(data.tvHeadlineText, '3 KM ZONE — ENTERING IN 1.2 km');
    });

    test('returns inactive for summitFinish stage type', () {
      final data = buildSampleData(
        stageType: NeutralZoneStageType.summitFinish,
        remainingToFinishMeters: 1500.0,
        zoneLengthMeters: 0.0,
      );
      expect(data.isProtectionEligible, isFalse);
      expect(data.status, NeutralZoneBannerStatus.inactive);
      expect(data.zoneBadgeText, 'NO NEUTRAL ZONE');
    });

    test('builds accurately from LateRaceNeutralZoneState', () {
      const config = NeutralZoneConfig(
        stageId: 's_test',
        stageName: 'Etap 7: Bordeaux',
        stageTotalDistanceMeters: 170000.0,
        stageType: NeutralZoneStageType.flatSprint,
      );
      const state = LateRaceNeutralZoneState(
        config: config,
        currentLeadDistanceMeters: 168200.0,
        groupFinishTimesSeconds: {0: 14000.0},
        incidents: [],
        resolutions: [],
        summary: NeutralZoneAuditSummary(
          totalIncidentsReviewed: 1,
          neutralizedCount: 1,
          pendingCount: 0,
          rejectedCount: 0,
          dnfCount: 0,
          totalGcSecondsSaved: 42.0,
          maxSingleRiderSavedSeconds: 42.0,
        ),
      );
      final data = NeutralZoneBannerHudData.fromNeutralZoneState(state);
      expect(data.status, NeutralZoneBannerStatus.active);
      expect(data.remainingToFinishMeters, closeTo(1800.0, 0.001));
      expect(data.neutralizedIncidentsCount, 1);
    });
  });

  group('NeutralZone3kmActiveBannerHud Widget', () {
    for (final viewport in <Size>[
      const Size(390, 844),
      const Size(1024, 768),
      const Size(1600, 900),
    ]) {
      testWidgets(
          'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: NeutralZone3kmActiveBannerHud(
                    data: buildSampleData(
                      juryExtendedTo5Km: true,
                      extensionReason: 'Wąski dojazd z rondami',
                      zoneLengthMeters: 5000.0,
                      remainingToFinishMeters: 3500.0,
                    ),
                    initiallyExpanded: true,
                    onOpenJuryPanel: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('5 KM ZONE — GC TIMES NEUTRALIZED'), findsOneWidget);
        expect(find.text('Kolegium Sędziów UCI'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('toggles expanded details on tap and fires onOpenJuryPanel',
        (tester) async {
      bool? expandedState;
      bool juryOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeutralZone3kmActiveBannerHud(
                data: buildSampleData(),
                onExpandedChanged: (v) => expandedState = v,
                onOpenJuryPanel: () => juryOpened = true,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Kolegium Sędziów UCI'), findsNothing);

      await tester.tap(find.text('3 KM ZONE — GC TIMES NEUTRALIZED'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(expandedState, isTrue);
      expect(find.text('Kolegium Sędziów UCI'), findsOneWidget);

      await tester.tap(find.text('Kolegium Sędziów UCI'));
      await tester.pump();
      expect(juryOpened, isTrue);
    });

    testWidgets('ignores taps when disabled and handles mouse hover',
        (tester) async {
      bool? expandedState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeutralZone3kmActiveBannerHud(
                data: buildSampleData(),
                isDisabled: true,
                onExpandedChanged: (v) => expandedState = v,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('3 KM ZONE — GC TIMES NEUTRALIZED'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(expandedState, isNull);

      final gesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(
        tester.getCenter(find.byType(NeutralZone3kmActiveBannerHud)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Riverpod connector renders from lateRaceNeutralZoneProvider',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: NeutralZone3kmBannerHudConnector(),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(NeutralZone3kmActiveBannerHud), findsOneWidget);
      expect(find.text('3 KM ZONE — GC TIMES NEUTRALIZED'), findsOneWidget);
    });
  });
}
