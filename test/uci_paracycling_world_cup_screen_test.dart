import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/paracycling/uci_paracycling_tandem_handbike_model.dart';
import 'package:pro_peloton_manager/ui/screens/uci_paracycling_world_cup_screen.dart';

void main() {
  Future<void> pumpScreenAtSize(
    WidgetTester tester,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: UciParacyclingWorldCupScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('renders without overflow on 390x844 mobile layout', (
    WidgetTester tester,
  ) async {
    await pumpScreenAtSize(tester, const Size(390, 844));

    expect(
      find.text('UCI Para-Cycling & Igrzyska Paralimpijskie'),
      findsOneWidget,
    );
    expect(find.text('Kalendarz & Start'), findsOneWidget);
    expect(find.text('Kadra & Tandem B'), findsOneWidget);
    expect(find.text('Sztafeta & Wyniki'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Kadra & Tandem B'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Laboratorium Tandemu Klasy B'), findsOneWidget);

    await tester.tap(find.text('Sztafeta & Wyniki'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Sztafeta Handbike H1–H5 (Limit 11 pkt)'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without overflow on 1024x768 tablet layout', (
    WidgetTester tester,
  ) async {
    await pumpScreenAtSize(tester, const Size(1024, 768));

    expect(
      find.text('Kalendarz Pucharu Świata & Igrzysk'),
      findsOneWidget,
    );
    expect(find.text('Laboratorium Tandemu Klasy B'), findsOneWidget);
    expect(
      find.text('Klasyfikacja Generalna Pucharu Świata'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'simulates race and updates World Cup standings on 1600x900 desktop', (
    WidgetTester tester,
  ) async {
    await pumpScreenAtSize(tester, const Size(1600, 900));

    expect(
      find.text('Symuluj Start UCI (Puchar Świata)'),
      findsOneWidget,
    );

    await tester.tap(find.text('Symuluj Start UCI (Puchar Świata)'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Wynik Biegu:'), findsOneWidget);
    expect(find.textContaining('Miejsce #'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('ParacyclingRaceSimulator produces deterministic podium and points', () {
    final model =
        UciParacyclingTandemHandbikeModel.createDefaultWorldCupSeason();
    final event = model.events.first;
    final crew = model.tandemCrews.first;

    final summary = ParacyclingRaceSimulator.simulateEvent(
      event: event,
      sportClass: ParacyclingSportClass.b,
      competitorId: crew.id,
      displayName: crew.crewDisplayName,
      effectiveFtpWatts: crew.combinedFtpWatts,
      systemWeightKg: crew.totalSystemWeightKg,
      cdaM2: crew.tandemBike.cdaM2,
      crr: crew.tandemBike.crr,
      maxDescentOverrideKmh: crew.projectedMaxDescentKmh,
    );

    expect(summary.leaderboard.length, 7);
    expect(summary.leaderboard.first.rank, 1);
    expect(summary.leaderboard.first.medalEarned, ParacyclingMedalType.gold);
    expect(summary.playerResult.uciPointsEarned, greaterThan(0));
  });
}
