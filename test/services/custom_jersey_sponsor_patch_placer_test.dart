import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/rendering3d/peloton_3d_canvas_engine.dart';
import 'package:pro_peloton_manager/services/career/custom_jersey_sponsor_patch_placer.dart';
import 'package:pro_peloton_manager/state/race_simulation_notifier.dart';

void main() {
  group('CustomJerseySponsorPatchPlacer Unit Tests', () {
    test('defaultForTeam populates all 8 zones with proper roles', () {
      final layout = JerseySponsorPatchLayout.defaultForTeam(
        teamId: 'team_pol',
        primarySponsor: 'ORLEN',
        secondarySponsor: 'CCC',
        bikeBrand: 'COLNAGO',
        countryIso: 'POL',
      );

      expect(layout.patches.length, 8);
      expect(layout.patchFor(SponsorPatchZone.chestMain).label, 'ORLEN');
      expect(layout.patchFor(SponsorPatchZone.backMain).label, 'ORLEN');
      expect(layout.patchFor(SponsorPatchZone.leftSleeve).label, 'CCC');
      expect(layout.patchFor(SponsorPatchZone.rightSleeve).label, 'CCC');
      expect(layout.patchFor(SponsorPatchZone.leftBibSide).label, 'CCC');
      expect(layout.patchFor(SponsorPatchZone.rightBibSide).label, 'CCC');
      expect(layout.patchFor(SponsorPatchZone.collarLeft).label, 'COLNAGO');
      expect(layout.patchFor(SponsorPatchZone.collarRight).countryIso, 'POL');
    });

    test('JSON serialization round-trip preserves layout and 3D descriptor', () {
      final layout = JerseySponsorPatchLayout.defaultForTeam(
        teamId: 'team_fra',
        primarySponsor: 'DECATHLON',
        secondarySponsor: 'AG2R',
        bikeBrand: 'VAN RYSEL',
        countryIso: 'FRA',
      ).withUpdatedPatch(
        const JerseySponsorPatchSpec(
          zone: SponsorPatchZone.chestMain,
          role: SponsorPatchRole.primarySponsor,
          label: 'DECATHLON',
          crestShape: SponsorCrestShape.hexagon,
          offsetX: 0.04,
          offsetY: -0.02,
          scale: 1.15,
          rotationDeg: 5.0,
          backgroundColorHex: '#D4AF37',
          foregroundColorHex: '#111317',
        ),
      );

      final decodedLayout = JerseySponsorPatchLayout.fromJson(layout.toJson());
      expect(decodedLayout, equals(layout));
      expect(decodedLayout.patchFor(SponsorPatchZone.chestMain).crestShape, SponsorCrestShape.hexagon);
      expect(decodedLayout.patchFor(SponsorPatchZone.chestMain).scale, closeTo(1.15, 0.001));

      final descriptor = CustomJerseySponsorPatchPlacer.buildRace3dInheritance(decodedLayout);
      final decodedDesc = Race3dJerseyPatchDescriptor.fromJson(descriptor.toJson());
      expect(decodedDesc.teamId, 'team_fra');
      expect(decodedDesc.chestLabel, 'DECATHLON');
      expect(decodedDesc.collarBikeLabel, 'VAN RYSEL');
      expect(decodedDesc.collarCountryIso, 'FRA');
      expect(decodedDesc.collarFlagVertical, isTrue);
      expect(decodedDesc.hasVisiblePatches, isTrue);
    });

    test('mirrorSleevesAndBibs mirrors left offsets and rotation to right side', () {
      final base = JerseySponsorPatchLayout.defaultForTeam();
      final edited = base
          .withUpdatedPatch(base.patchFor(SponsorPatchZone.leftSleeve).copyWith(offsetX: -0.03, rotationDeg: -12.0))
          .withUpdatedPatch(base.patchFor(SponsorPatchZone.leftBibSide).copyWith(offsetX: 0.02, rotationDeg: -6.0));

      final mirrored = edited.mirrorSleevesAndBibs();
      expect(mirrored.patchFor(SponsorPatchZone.rightSleeve).offsetX, closeTo(0.03, 0.0001));
      expect(mirrored.patchFor(SponsorPatchZone.rightSleeve).rotationDeg, closeTo(12.0, 0.0001));
      expect(mirrored.patchFor(SponsorPatchZone.rightBibSide).offsetX, closeTo(-0.02, 0.0001));
      expect(mirrored.patchFor(SponsorPatchZone.rightBibSide).rotationDeg, closeTo(6.0, 0.0001));
    });

    test('hitTestZone respects front vs back visibility and applyDragDelta clamps bounds', () {
      final layout = JerseySponsorPatchLayout.defaultForTeam();
      const canvasSize = Size(300, 380);
      final chestCenter = CustomJerseySponsorPatchPlacer.resolveZoneCanvasCenter(
        layout.patchFor(SponsorPatchZone.chestMain),
        canvasSize,
      );

      expect(
        CustomJerseySponsorPatchPlacer.hitTestZone(chestCenter, canvasSize, layout, isBackView: false),
        SponsorPatchZone.chestMain,
      );
      expect(
        CustomJerseySponsorPatchPlacer.hitTestZone(chestCenter, canvasSize, layout, isBackView: true),
        SponsorPatchZone.backMain,
      );

      final dragged = CustomJerseySponsorPatchPlacer.applyDragDelta(
        layout.patchFor(SponsorPatchZone.chestMain),
        const Offset(500, -500),
        canvasSize,
      );
      expect(dragged.offsetX, 0.12);
      expect(dragged.offsetY, -0.12);
    });

    test('validateLayout flags hidden primary sponsor and oversized chest crest', () {
      final base = JerseySponsorPatchLayout.defaultForTeam();
      final invalid = base.withUpdatedPatch(
        base.patchFor(SponsorPatchZone.chestMain).copyWith(isVisible: false, scale: 1.42),
      );
      final report = CustomJerseySponsorPatchPlacer.validateLayout(invalid);
      expect(report.isValid, isFalse);
      expect(report.warnings.length, 2);
      expect(report.activePatchesCount, 7);
    });

    test('Peloton3dCanvasEngine inherits Race3dJerseyPatchDescriptor for player riders', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(customJerseySponsorPatchProvider.notifier).syncTeamMetadata(
            teamId: 'player_team',
            primarySponsor: 'APEX',
            secondarySponsor: 'TECH',
            bikeBrand: 'PINARELLO',
            countryIso: 'ITA',
          );
      final descriptor = container.read(customJerseySponsorPatchProvider).resolveForTeam('player_team');
      expect(descriptor, isNotNull);

      final engine = Peloton3dCanvasEngine();
      engine.stepFrame(
        dtSeconds: 0.016,
        snapshots: <RiderPositionSnapshot>[
          RiderPositionSnapshot(
            riderId: 'r1',
            riderName: 'Jan Kowalski',
            bibNumber: 1,
            teamId: 'player_team',
            teamName: 'APEX',
            teamJerseyHexColor: '#002B49',
            isPlayerRider: true,
            distanceCoveredMeters: 120.0,
            kilometerMark: 0.12,
            elevationMeters: 250.0,
            currentGradientPercent: 2.0,
            currentSegmentIndex: 0,
            speedMs: 12.0,
            speedKmh: 43.2,
            powerWatts: 310,
            wattsPerKg: 4.5,
            cadenceRpm: 92,
            heartRateBpm: 152,
            wPrimePercentage: 100.0,
            wPrimeJoules: 20000.0,
            glycogenPercentage: 95.0,
            glycogenGrams: 420.0,
            hydrationPercent: 95.0,
            bidonsLeft: 2,
            gelsLeft: 4,
            activeTacticalOrder: TacticalOrder.values.first,
            groupIndex: 0,
            groupType: GroupType.peloton,
            timeGapToLeaderSeconds: 0.0,
            lateralPositionRoad: 0.0,
            lateralOffsetRoadMeters: 0.0,
            isDrafting: true,
            draftingSavingsPercent: 32.0,
            isPulling: false,
          ),
          RiderPositionSnapshot(
            riderId: 'r2',
            riderName: 'Rival Rider',
            bibNumber: 2,
            teamId: 'rival_team',
            teamName: 'RIVAL',
            teamJerseyHexColor: '#DC2626',
            isPlayerRider: false,
            distanceCoveredMeters: 122.0,
            kilometerMark: 0.122,
            elevationMeters: 250.0,
            currentGradientPercent: 2.0,
            currentSegmentIndex: 0,
            speedMs: 12.0,
            speedKmh: 43.2,
            powerWatts: 300,
            wattsPerKg: 4.3,
            cadenceRpm: 90,
            heartRateBpm: 150,
            wPrimePercentage: 100.0,
            wPrimeJoules: 20000.0,
            glycogenPercentage: 95.0,
            glycogenGrams: 420.0,
            hydrationPercent: 95.0,
            bidonsLeft: 2,
            gelsLeft: 4,
            activeTacticalOrder: TacticalOrder.values.first,
            groupIndex: 0,
            groupType: GroupType.peloton,
            timeGapToLeaderSeconds: 0.0,
            lateralPositionRoad: 0.2,
            lateralOffsetRoadMeters: 0.7,
            isDrafting: false,
            draftingSavingsPercent: 0.0,
            isPulling: true,
          ),
        ],
        playerTeamPatchDescriptor: descriptor,
      );

      expect(engine.activeRiders.length, 2);
      expect(engine.activeRiders.first.patchDescriptor?.chestLabel, 'APEX');
      expect(engine.activeRiders.first.patchDescriptor?.collarBikeLabel, 'PINARELLO');
      expect(engine.activeRiders.first.patchDescriptor?.collarCountryIso, 'ITA');
      expect(engine.activeRiders.last.patchDescriptor, isNull);
    });
  });

  group('CustomJerseySponsorPatchPlacerPanel Responsive Widget Tests', () {
    final viewports = <String, Size>{
      'mobile_390x844': const Size(390, 844),
      'tablet_1024x768': const Size(1024, 768),
      'desktop_1600x900': const Size(1600, 900),
    };

    for (final entry in viewports.entries) {
      testWidgets('renders cleanly without overflow at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: CustomJerseySponsorPatchPlacerPanel(),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Strefy Logotypów i Flagi'), findsOneWidget);
        expect(find.text('Odbij Rękawki i Spodenki'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('supports zone switching, mirroring, and disabled state', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      JerseySponsorPatchLayout? latest;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CustomJerseySponsorPatchPlacerPanel(
                onLayoutChanged: (layout) => latest = layout,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Kołnierz Flaga'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Kołnierzyk Prawy (Flaga Narodowa)'), findsOneWidget);

      await tester.tap(find.text('Odbij Rękawki i Spodenki'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(latest, isNotNull);

      // Verify disabled state renders without errors
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CustomJerseySponsorPatchPlacerPanel(enabled: false),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);
    });
  });
}
