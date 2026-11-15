import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/ui/widgets/tv_intermediate_sprint_kom_popup.dart';

void main() {
  List<TvPrimeCrossingEntry> sampleSprintEntries() {
    return const <TvPrimeCrossingEntry>[
      TvPrimeCrossingEntry(
        position: 1,
        riderId: 'r1',
        riderName: 'J. PHILIPSEN',
        teamShortCode: 'ADC',
        nationalityIso: 'BEL',
        primaryJerseyHex: '#10B981',
        totalPointsBefore: 140,
        gapSeconds: 0.0,
        isClassificationLeader: true,
      ),
      TvPrimeCrossingEntry(
        position: 2,
        riderId: 'r2',
        riderName: 'B. GIRMAY',
        teamShortCode: 'IWA',
        nationalityIso: 'ERI',
        primaryJerseyHex: '#38BDF8',
        totalPointsBefore: 132,
        gapSeconds: 0.4,
      ),
      TvPrimeCrossingEntry(
        position: 3,
        riderId: 'r3',
        riderName: 'O. KOOIJ',
        teamShortCode: 'TVL',
        nationalityIso: 'NED',
        primaryJerseyHex: '#D4AF37',
        totalPointsBefore: 98,
        gapSeconds: 0.9,
        isPlayerTeam: true,
      ),
      TvPrimeCrossingEntry(
        position: 4,
        riderId: 'r4',
        riderName: 'M. PEDERSEN',
        teamShortCode: 'LTK',
        nationalityIso: 'DEN',
        primaryJerseyHex: '#EF4444',
        totalPointsBefore: 85,
        gapSeconds: 1.5,
      ),
      TvPrimeCrossingEntry(
        position: 5,
        riderId: 'r5',
        riderName: 'M. MATTHEWS',
        teamShortCode: 'JAY',
        nationalityIso: 'AUS',
        primaryJerseyHex: '#8E4A49',
        totalPointsBefore: 70,
        gapSeconds: 2.1,
      ),
    ];
  }

  test('TvPrimeClassificationType schedules match 20-17-15-13-11 and 20-15-12-10-8', () {
    expect(
      TvPrimeClassificationType.intermediateSprint.pointsSchedule,
      const <int>[20, 17, 15, 13, 11],
    );
    expect(
      TvPrimeClassificationType.horsCategorie.pointsSchedule,
      const <int>[20, 15, 12, 10, 8],
    );
    expect(
      TvPrimeClassificationType.fromSegmentClassification(
        SegmentClassification.intermediateSprint,
      ),
      TvPrimeClassificationType.intermediateSprint,
    );
    expect(
      TvPrimeClassificationType.fromSegmentClassification(
        SegmentClassification.horsCategorie,
      ),
      TvPrimeClassificationType.horsCategorie,
    );
    expect(
      TvPrimeClassificationType.fromSegmentClassification(
        SegmentClassification.none,
      ),
      isNull,
    );
  });

  testWidgets('animates points counting on intermediate sprint crossing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TvIntermediateSprintKomPopup(
              data: TvIntermediateSprintKomPopupData(
                primeId: 'sprint_1',
                primeName: 'Sprint Intermédiaire — Albertville',
                classificationType:
                    TvPrimeClassificationType.intermediateSprint,
                kilometerMark: 88.5,
                entries: sampleSprintEntries(),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sprint Intermédiaire — Albertville'), findsOneWidget);
    expect(find.text('SPRINT'), findsOneWidget);
    expect(find.text('J. PHILIPSEN'), findsOneWidget);
    expect(find.text('+20'), findsOneWidget);
    expect(find.text('160'), findsOneWidget);
    expect(find.text('+17'), findsOneWidget);
    expect(find.text('+15'), findsOneWidget);
    expect(find.text('+13'), findsOneWidget);
    expect(find.text('+11'), findsOneWidget);
  });

  testWidgets('renders HC KOM points 20-15-12-10-8 and handles interactions', (
    WidgetTester tester,
  ) async {
    bool dismissed = false;
    TvPrimeCrossingEntry? tappedEntry;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TvIntermediateSprintKomPopup(
              data: TvIntermediateSprintKomPopupData(
                primeId: 'kom_hc_1',
                primeName: 'Col du Galibier',
                classificationType: TvPrimeClassificationType.horsCategorie,
                kilometerMark: 142.0,
                elevationMeters: 2642,
                averageGradientPercent: 6.9,
                entries: sampleSprintEntries(),
              ),
              onDismiss: () => dismissed = true,
              onRiderTap: (TvPrimeCrossingEntry entry) => tappedEntry = entry,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('HC'), findsOneWidget);
    expect(find.text('Col du Galibier'), findsOneWidget);
    expect(find.text('KM 142.0 • 2642 m n.p.m. • 6.9%'), findsOneWidget);
    expect(find.text('+20'), findsOneWidget);
    expect(find.text('+15'), findsOneWidget);
    expect(find.text('+12'), findsOneWidget);
    expect(find.text('+10'), findsOneWidget);
    expect(find.text('+8'), findsOneWidget);

    await tester.tap(find.text('O. KOOIJ'));
    await tester.pump();
    expect(tappedEntry?.riderId, 'r3');

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(dismissed, isTrue);
  });

  testWidgets('disabled state blocks dismiss and rider tap', (
    WidgetTester tester,
  ) async {
    bool dismissed = false;
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TvIntermediateSprintKomPopup(
              isEnabled: false,
              data: TvIntermediateSprintKomPopupData(
                primeId: 'sprint_disabled',
                primeName: 'Sprint — Valence',
                classificationType:
                    TvPrimeClassificationType.intermediateSprint,
                kilometerMark: 64.0,
                entries: sampleSprintEntries().take(2).toList(),
              ),
              onDismiss: () => dismissed = true,
              onRiderTap: (_) => tapped = true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('J. PHILIPSEN'));
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(tapped, isFalse);
    expect(dismissed, isFalse);
  });

  for (final Size viewport in const <Size>[
    Size(390, 844),
    Size(1024, 768),
    Size(1600, 900),
  ]) {
    testWidgets(
      'responsive layout without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
      (WidgetTester tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TvIntermediateSprintKomPopup(
                    data: TvIntermediateSprintKomPopupData(
                      primeId: 'resp_${viewport.width.toInt()}',
                      primeName: 'Col de la Madeleine — Premia Górska',
                      classificationType:
                          TvPrimeClassificationType.horsCategorie,
                      kilometerMark: 118.4,
                      elevationMeters: 2000,
                      averageGradientPercent: 8.1,
                      entries: sampleSprintEntries(),
                    ),
                    onDismiss: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
