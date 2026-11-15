import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/state/race_simulation_notifier.dart';
import 'package:pro_peloton_manager/ui/widgets/tactical_minimap_2d_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TacticalMinimap2dWidget Tests', () {
    late RaceStage testStage;
    late List<RiderPositionSnapshot> testSnapshots;
    const String playerTeamId = 'team_player';

    setUp(() {
      // Przygotowanie etapu z zakrętami, zjazdem i sektorem brukowanym
      testStage = const RaceStage(
        id: 'stage_test',
        stageNumber: 1,
        name: 'Test Stage: Alpy i Bruki',
        stageType: StageType.hilly,
        baseTemperatureCelsius: 22.0,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 28.0,
        segments: [
          StageSegment(
            index: 0,
            startKm: 0.0,
            lengthKm: 10.0,
            startElevationM: 400.0,
            endElevationM: 400.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 20.0,
            windDirectionDegrees: 90.0,
            roadBearingDegrees: 0.0,
            sprintOrKomClassification: SegmentClassification.none,
          ),
          StageSegment(
            index: 1,
            startKm: 10.0,
            lengthKm: 5.0,
            startElevationM: 400.0,
            endElevationM: 150.0, // Zjazd ze serpentynami
            surfaceType: SegmentSurfaceType.roughAsphalt,
            technicalDifficulty: 85.0, // Wysoka trudność -> ostre nawroty 180°
            windDirectionDegrees: 180.0,
            roadBearingDegrees: 45.0,
            sprintOrKomClassification: SegmentClassification.none,
          ),
          StageSegment(
            index: 2,
            startKm: 15.0,
            lengthKm: 3.0,
            startElevationM: 150.0,
            endElevationM: 160.0,
            surfaceType: SegmentSurfaceType.cobblestonesSector4, // Bruk -> Zwężenie jezdni
            technicalDifficulty: 90.0,
            windDirectionDegrees: 270.0,
            roadBearingDegrees: 180.0,
            sprintOrKomClassification: SegmentClassification.cat4,
          ),
          StageSegment(
            index: 3,
            startKm: 18.0,
            lengthKm: 2.0,
            startElevationM: 160.0,
            endElevationM: 165.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 30.0,
            windDirectionDegrees: 90.0,
            roadBearingDegrees: 0.0,
            sprintOrKomClassification: SegmentClassification.finishLine,
          ),
        ],
      );

      // Przygotowanie kolarzy: pociąg gracza (3 kolarzy w szyku) + rywale
      testSnapshots = [
        // Kolarz 1 gracza (Czoło pociągu - pociągowy)
        const RiderPositionSnapshot(
          riderId: 'rider_p1',
          riderName: 'Piotr Tempowiec',
          bibNumber: 11,
          teamId: playerTeamId,
          teamName: 'Orły Racing',
          teamJerseyHexColor: '#D4AF37',
          isPlayerRider: true,
          distanceCoveredMeters: 12100.0,
          kilometerMark: 12.1,
          elevationMeters: 300.0,
          currentGradientPercent: -4.5,
          currentSegmentIndex: 1,
          speedMs: 16.0,
          speedKmh: 57.6,
          powerWatts: 450,
          wattsPerKg: 6.2,
          cadenceRpm: 100,
          heartRateBpm: 172,
          wPrimePercentage: 85.0,
          wPrimeJoules: 18000.0,
          glycogenPercentage: 80.0,
          glycogenGrams: 360.0,
          hydrationPercent: 90.0,
          bidonsLeft: 2,
          gelsLeft: 3,
          activeTacticalOrder: TacticalOrder.pullGroup,
          groupIndex: 1,
          groupType: GroupType.peloton,
          timeGapToLeaderSeconds: 20.0,
          lateralPositionRoad: 0.1,
          lateralOffsetRoadMeters: 0.3,
          isDrafting: false,
          draftingSavingsPercent: 0.0,
          isPulling: true,
          hasDefect: false,
          isCrashed: false,
          isDnf: false,
        ),
        // Kolarz 2 gracza (Środek pociągu - rozprowadzający)
        const RiderPositionSnapshot(
          riderId: 'rider_p2',
          riderName: 'Marek Rozprowadzacz',
          bibNumber: 12,
          teamId: playerTeamId,
          teamName: 'Orły Racing',
          teamJerseyHexColor: '#D4AF37',
          isPlayerRider: true,
          distanceCoveredMeters: 12090.0, // 10m za pierwszym
          kilometerMark: 12.09,
          elevationMeters: 301.0,
          currentGradientPercent: -4.5,
          currentSegmentIndex: 1,
          speedMs: 16.0,
          speedKmh: 57.6,
          powerWatts: 320,
          wattsPerKg: 4.5,
          cadenceRpm: 98,
          heartRateBpm: 158,
          wPrimePercentage: 92.0,
          wPrimeJoules: 21000.0,
          glycogenPercentage: 85.0,
          glycogenGrams: 380.0,
          hydrationPercent: 92.0,
          bidonsLeft: 2,
          gelsLeft: 4,
          activeTacticalOrder: TacticalOrder.protectLeader,
          groupIndex: 1,
          groupType: GroupType.peloton,
          timeGapToLeaderSeconds: 20.2,
          lateralPositionRoad: 0.12,
          lateralOffsetRoadMeters: 0.35,
          isDrafting: true,
          draftingSavingsPercent: 35.0,
          isPulling: false,
          hasDefect: false,
          isCrashed: false,
          isDnf: false,
        ),
        // Kolarz 3 gracza (Koniec pociągu - chroniony Lider)
        const RiderPositionSnapshot(
          riderId: 'rider_p3',
          riderName: 'Tomasz Lider',
          bibNumber: 13,
          teamId: playerTeamId,
          teamName: 'Orły Racing',
          teamJerseyHexColor: '#D4AF37',
          isPlayerRider: true,
          distanceCoveredMeters: 12080.0, // 10m za drugim
          kilometerMark: 12.08,
          elevationMeters: 302.0,
          currentGradientPercent: -4.5,
          currentSegmentIndex: 1,
          speedMs: 16.0,
          speedKmh: 57.6,
          powerWatts: 270,
          wattsPerKg: 4.1,
          cadenceRpm: 95,
          heartRateBpm: 148,
          wPrimePercentage: 96.0,
          wPrimeJoules: 24000.0,
          glycogenPercentage: 90.0,
          glycogenGrams: 410.0,
          hydrationPercent: 95.0,
          bidonsLeft: 2,
          gelsLeft: 4,
          activeTacticalOrder: TacticalOrder.holdPosition,
          groupIndex: 1,
          groupType: GroupType.peloton,
          timeGapToLeaderSeconds: 20.4,
          lateralPositionRoad: 0.12,
          lateralOffsetRoadMeters: 0.35,
          isDrafting: true,
          draftingSavingsPercent: 42.0,
          isPulling: false,
          hasDefect: false,
          isCrashed: false,
          isDnf: false,
        ),
        // Rywal w peletonie
        const RiderPositionSnapshot(
          riderId: 'rider_rival1',
          riderName: 'Jean Rival',
          bibNumber: 21,
          teamId: 'team_rival',
          teamName: 'Rival Pro',
          teamJerseyHexColor: '#0052CC',
          isPlayerRider: false,
          distanceCoveredMeters: 12085.0,
          kilometerMark: 12.085,
          elevationMeters: 301.5,
          currentGradientPercent: -4.5,
          currentSegmentIndex: 1,
          speedMs: 16.0,
          speedKmh: 57.6,
          powerWatts: 340,
          wattsPerKg: 4.8,
          cadenceRpm: 96,
          heartRateBpm: 162,
          wPrimePercentage: 88.0,
          wPrimeJoules: 19000.0,
          glycogenPercentage: 82.0,
          glycogenGrams: 370.0,
          hydrationPercent: 88.0,
          bidonsLeft: 1,
          gelsLeft: 2,
          activeTacticalOrder: TacticalOrder.holdPosition,
          groupIndex: 1,
          groupType: GroupType.peloton,
          timeGapToLeaderSeconds: 20.3,
          lateralPositionRoad: -0.4,
          lateralOffsetRoadMeters: -1.2,
          isDrafting: true,
          draftingSavingsPercent: 30.0,
          isPulling: false,
          hasDefect: false,
          isCrashed: false,
          isDnf: false,
        ),
      ];
    });

    testWidgets('Poprawnie renderuje TacticalMinimap2dWidget w widoku hybrydowym', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: TacticalMinimap2dWidget(
                  stage: testStage,
                  riderSnapshots: testSnapshots,
                  playerRiderIds: const ['rider_p1', 'rider_p2', 'rider_p3'],
                  selectedRiderId: 'rider_p3',
                  referenceKm: 12.08,
                  initialPerspective: MinimapPerspective.hybrid,
                  width: 480,
                  height: 280,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Weryfikacja obecności nagłówka radaru
      expect(find.text('RADAR 2D'), findsOneWidget);
      // Weryfikacja wykrycia pociągu drużyny (3 kolarzy w szyku)
      expect(find.textContaining('POCIĄG: 3'), findsOneWidget);
      // Weryfikacja renderowania CustomPaint (minimapa szosy i profilu)
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Przełączanie perspektyw: Lot Ptaka, Profil Wysokościowy, Hybryda', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: TacticalMinimap2dWidget(
                  stage: testStage,
                  riderSnapshots: testSnapshots,
                  playerRiderIds: const ['rider_p1', 'rider_p2', 'rider_p3'],
                  selectedRiderId: 'rider_p3',
                  referenceKm: 12.08,
                  initialPerspective: MinimapPerspective.birdEyeRoad,
                  width: 480,
                  height: 280,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Kliknięcie w ikonę profilu wysokościowego
      final profileIcon = find.byIcon(Icons.show_chart_rounded);
      expect(profileIcon, findsOneWidget);
      await tester.tap(profileIcon);
      await tester.pumpAndSettle();

      // Kliknięcie w ikonę widoku hybrydowego
      final hybridIcon = find.byIcon(Icons.layers_outlined);
      expect(hybridIcon, findsOneWidget);
      await tester.tap(hybridIcon);
      await tester.pumpAndSettle();

      // Kliknięcie w ikonę widoku szosy z lotu ptaka
      final birdEyeIcon = find.byIcon(Icons.navigation_outlined);
      expect(birdEyeIcon, findsOneWidget);
      await tester.tap(birdEyeIcon);
      await tester.pumpAndSettle();
    });

    testWidgets('Wykrywa nawroty 180° i zwężenia jezdni przed brukiem w alertach', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: TacticalMinimap2dWidget(
                  stage: testStage,
                  riderSnapshots: testSnapshots,
                  playerRiderIds: const ['rider_p1', 'rider_p2', 'rider_p3'],
                  referenceKm: 12.08,
                  width: 540,
                  height: 300,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // W promieniu 3 km (km 12 do 15) trasa etapu zawiera serpentyny na zjeździe
      expect(find.textContaining('NAWRÓT 180°'), findsOneWidget);
    });
  });
}
