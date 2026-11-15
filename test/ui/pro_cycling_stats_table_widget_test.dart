import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/widgets/pro_cycling_stats_table_widget.dart';

void main() {
  final List<PcsRiderRowData> sampleRows = [
    const PcsRiderRowData(
      id: 'r1',
      rank: 1,
      bibNumber: '1',
      firstName: 'Tadej',
      lastName: 'Pogacar',
      nationalityIso: 'SLO',
      teamId: 'uae',
      teamName: 'UAE Team Emirates',
      teamShortCode: 'UAD',
      teamPrimaryColor: Color(0xFFFFFFFF),
      age: 26,
      specialization: PcsSpecializationCategory.climber,
      timeSeconds: 15155,
      points: 500,
      secondaryMetric: 2450,
      isLeader: true,
    ),
    const PcsRiderRowData(
      id: 'r2',
      rank: 2,
      bibNumber: '11',
      firstName: 'Michal',
      lastName: 'Kwiatkowski',
      nationalityIso: 'POL',
      teamId: 'player',
      teamName: 'Polonia Pro Cycling',
      teamShortCode: 'PLK',
      teamPrimaryColor: Color(0xFFDC143C),
      age: 34,
      specialization: PcsSpecializationCategory.timeTrial,
      timeSeconds: 14,
      isTimeGap: true,
      points: 320,
      secondaryMetric: 1420,
      isPlayerTeam: true,
    ),
    const PcsRiderRowData(
      id: 'r3',
      rank: 3,
      bibNumber: '21',
      firstName: 'Jasper',
      lastName: 'Philipsen',
      nationalityIso: 'BEL',
      teamId: 'adc',
      teamName: 'Alpecin-Deceuninck',
      teamShortCode: 'ADC',
      teamPrimaryColor: Color(0xFF1D4ED8),
      age: 27,
      specialization: PcsSpecializationCategory.sprint,
      timeSeconds: 45,
      isTimeGap: true,
      points: 260,
      secondaryMetric: 1890,
    ),
    const PcsRiderRowData(
      id: 'r4',
      rank: 4,
      bibNumber: '31',
      firstName: 'Mathieu',
      lastName: 'Van Der Poel',
      nationalityIso: 'NED',
      teamId: 'adc',
      teamName: 'Alpecin-Deceuninck',
      teamShortCode: 'ADC',
      teamPrimaryColor: Color(0xFF1D4ED8),
      age: 30,
      specialization: PcsSpecializationCategory.cobbles,
      timeSeconds: 62,
      isTimeGap: true,
      points: 210,
      secondaryMetric: 2110,
    ),
    const PcsRiderRowData(
      id: 'r5',
      rank: null,
      statusLabel: 'DNF',
      firstName: 'Filippo',
      lastName: 'Ganna',
      nationalityIso: 'ITA',
      teamId: 'igd',
      teamName: 'INEOS Grenadiers',
      teamShortCode: 'IGD',
      teamPrimaryColor: Color(0xFFEA580C),
      age: 28,
      specialization: PcsSpecializationCategory.timeTrial,
      points: 0,
      isDisabled: true,
    ),
  ];

  Widget wrapWithViewport(
    Size size, {
    required Widget child,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('ProCyclingStatsTableWidget', () {
    testWidgets('renderuje dane kolarzy, flagi, drużyny i specjalizacje',
        (tester) async {
      await tester.pumpWidget(
        wrapWithViewport(
          const Size(1600, 900),
          child: ProCyclingStatsTableWidget(
            title: 'Klasyfikacja Etapu 5',
            subtitle: 'Tour de France',
            rows: sampleRows,
          ),
        ),
      );

      expect(find.text('Klasyfikacja Etapu 5'), findsOneWidget);
      expect(find.byType(PcsCountryFlagBadge), findsNWidgets(5));
      expect(find.text('UAE Team Emirates'), findsOneWidget);
      expect(find.text('Polonia Pro Cycling'), findsOneWidget);
      expect(find.text('04:12:35'), findsOneWidget);
      expect(find.text("+0'14\""), findsOneWidget);
      expect(find.text('DNF'), findsWidgets);
    });

    testWidgets('filtruje na żywo po wpisaniu frazy i po specjalizacji',
        (tester) async {
      await tester.pumpWidget(
        wrapWithViewport(
          const Size(1280, 800),
          child: ProCyclingStatsTableWidget(
            rows: sampleRows,
          ),
        ),
      );

      expect(find.text('5/5'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Kwiatkowski');
      await tester.pumpAndSettle();
      expect(find.text('1/5'), findsOneWidget);

      await tester.tap(find.byTooltip('Wyczyść filtr'));
      await tester.pumpAndSettle();
      expect(find.text('5/5'), findsOneWidget);

      await tester.tap(find.text('Sprint').first);
      await tester.pumpAndSettle();
      expect(find.text('1/5'), findsOneWidget);

      await tester.tap(find.text('Moja ekipa'));
      await tester.pumpAndSettle();
      expect(find.text('0/5'), findsOneWidget);
      expect(find.text('Resetuj filtry'), findsOneWidget);

      await tester.tap(find.text('Resetuj filtry'));
      await tester.pumpAndSettle();
      expect(find.text('5/5'), findsOneWidget);
    });

    testWidgets('sortuje po kliknięciu nagłówka kolumny', (tester) async {
      await tester.pumpWidget(
        wrapWithViewport(
          const Size(1280, 800),
          child: ProCyclingStatsTableWidget(
            rows: sampleRows,
          ),
        ),
      );

      await tester.tap(find.text('WIEK'));
      await tester.pumpAndSettle();

      // Najmłodszy (26) powinien być pierwszy w kolejności wieku rosnąco
      final firstAgeY = tester.getTopLeft(find.text('26')).dy;
      final oldestAgeY = tester.getTopLeft(find.text('34')).dy;
      expect(firstAgeY, lessThan(oldestAgeY));

      // Drugie kliknięcie odwraca kolejność (34 przed 26)
      await tester.tap(find.text('WIEK'));
      await tester.pumpAndSettle();
      final firstAgeDescY = tester.getTopLeft(find.text('34')).dy;
      final youngestAgeDescY = tester.getTopLeft(find.text('26')).dy;
      expect(firstAgeDescY, lessThan(youngestAgeDescY));
    });

    testWidgets('wywołuje callbacki onRiderTap i onTeamTap oraz respektuje disabled',
        (tester) async {
      PcsRiderRowData? tappedRider;
      String? tappedTeamId;

      await tester.pumpWidget(
        wrapWithViewport(
          const Size(1280, 800),
          child: ProCyclingStatsTableWidget(
            rows: sampleRows,
            onRiderTap: (r) => tappedRider = r,
            onTeamTap: (id, _) => tappedTeamId = id,
          ),
        ),
      );

      await tester.tap(find.text('Polonia Pro Cycling'));
      await tester.pumpAndSettle();
      expect(tappedTeamId, equals('player'));

      await tester.tap(find.textContaining('POGACAR'));
      await tester.pumpAndSettle();
      expect(tappedRider?.id, equals('r1'));

      // Wyłączony wiersz (DNF) nie powinien wyzwalać onRiderTap
      tappedRider = null;
      await tester.tap(find.textContaining('GANNA'));
      await tester.pumpAndSettle();
      expect(tappedRider, isNull);
    });

    for (final viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'brak przepełnień RenderFlex w rozdzielczości ${viewport.width.toInt()}x${viewport.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          wrapWithViewport(
            viewport,
            child: ProCyclingStatsTableWidget(
              title: 'Lista Startowa',
              mode: PcsTableMode.startlist,
              rows: sampleRows,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ProCyclingStatsTableWidget), findsOneWidget);
      });
    }
  });
}
