import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/velodrome_track_and_hour_record_model.dart';
import 'package:pro_peloton_manager/ui/screens/track_omnium_madison_championship_screen.dart';

void main() {
  group('TrackChampionshipSimulationEngine', () {
    final facility = VelodromeTrackAndHourRecordModel.defaultVelodromes.first;
    const bike = VelodromeTrackAndHourRecordModel.defaultTrackBike;
    final athlete = TrackChampionshipAthlete.defaultRoster.first;

    test('symulacja Keirin zwraca 6 pozycji posortowanych wg czasu', () {
      final result = TrackChampionshipSimulationEngine.simulateKeirin(
        facility: facility,
        playerBike: bike,
        playerAthlete: athlete,
        playerStartingSlot: 2,
        dernyTargetSpeedKmh: 50.0,
      );

      expect(result.standings, hasLength(6));
      expect(result.standings.first.finishingPosition, 1);
      expect(
        result.standings.first.finishTimeSeconds,
        lessThanOrEqualTo(result.standings.last.finishTimeSeconds),
      );
      expect(result.dernyPullOffSpeedKmh, greaterThanOrEqualTo(48.0));
    });

    test('symulacja Madison zwraca klasyfikację 4 par i sprinty co 10 okr.', () {
      final result = TrackChampionshipSimulationEngine.simulateMadison(
        facility: facility,
        playerBike: bike,
        totalLaps: 40,
        exchangeIntervalLaps: 3,
        teamChemistry: 90.0,
      );

      expect(result.standings, hasLength(4));
      expect(result.sprintResults, hasLength(4));
      expect(result.standings.first.rank, 1);
      expect(
        result.standings.first.totalPoints,
        greaterThanOrEqualTo(result.standings.last.totalPoints),
      );
    });

    test('symulacja Omnium sumuje 4 konkurencje i sortuje liderów', () {
      final result = TrackChampionshipSimulationEngine.simulateOmnium(
        facility: facility,
        playerBike: bike,
        focusAthlete: athlete,
        seed: 2026,
      );

      expect(result.standings, hasLength(8));
      expect(result.standings.first.rank, 1);
      for (final row in result.standings) {
        expect(
          row.totalOmniumPoints,
          row.scratchPoints +
              row.tempoPoints +
              row.eliminationPoints +
              row.pointsRaceDelta,
        );
      }
      expect(
        result.standings.first.totalOmniumPoints,
        greaterThanOrEqualTo(result.standings.last.totalOmniumPoints),
      );
    });

    test('symulacja Wyścigu Punktowego generuje sprinty i finał podwójny', () {
      final result = TrackChampionshipSimulationEngine.simulatePointsRace(
        facility: facility,
        totalLaps: 100,
        sprintIntervalLaps: 10,
        aggressionLevel: 0.75,
        seed: 467,
      );

      expect(result.standings, hasLength(8));
      expect(result.sprintLogs, hasLength(10));
      expect(result.sprintLogs.last.isFinalDouble, isTrue);
      expect(result.sprintLogs.last.awardedTopPoints, 10);
    });
  });

  group('TrackOmniumMadisonChampionshipScreen responsive UI', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: TrackOmniumMadisonChampionshipScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renderuje się bez przepełnień w 390x844 (Mobile)',
        (tester) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(find.text('Mistrzostwa Torowe UCI'), findsOneWidget);
      expect(find.text('Keirin'), findsOneWidget);

      await tester.tap(find.text('Madison'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Laboratorium Fizyki Hand Sling'), findsOneWidget);

      await tester.tap(find.text('Omnium'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Tabela Generalna Omnium (4 Konkurencje)'), findsOneWidget);

      await tester.tap(find.text('Wyścig Punktowy'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Przebieg Sprintów Pośrednich'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się bez przepełnień w 1024x768 (Tablet)',
        (tester) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.text('Mistrzostwa Torowe UCI'), findsOneWidget);
      expect(find.text('Klasyfikacja Finału Keirin (1500 m)'), findsOneWidget);

      await tester.tap(find.text('Madison'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Laboratorium Fizyki Hand Sling'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się bez przepełnień w 1600x900 (Desktop)',
        (tester) async {
      await pumpAtSize(tester, const Size(1600, 900));
      expect(find.text('Mistrzostwa Torowe UCI'), findsOneWidget);
      expect(find.text('Klasyfikacja Finału Keirin (1500 m)'), findsOneWidget);

      await tester.tap(find.text('Omnium'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Tabela Generalna Omnium (4 Konkurencje)'), findsOneWidget);

      await tester.tap(find.text('Symuluj Omnium'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });
}
