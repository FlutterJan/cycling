import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/widgets/rival_managers_head_to_head_widget.dart';

void main() {
  group('RivalDirectorProfile model', () {
    test('computes win rate, net balance, initials and tier label', () {
      const profile = RivalDirectorProfile(
        id: 'ds_test',
        managerName: 'Matej Velasco',
        nationalityCode: 'SLO',
        teamName: 'Emirates Alpine Pro',
        teamShortCode: 'EAP',
        teamPrimaryColor: Color(0xFFEF4444),
        teamSecondaryColor: Color(0xFFF3F4F6),
        tacticalStyle: RivalTacticalStyle.aggressive,
        rivalryIntensity: 88,
        playerWins: 12,
        rivalWins: 8,
        draws: 2,
        signatureTactic: 'Atak z daleka',
      );

      expect(profile.totalDuels, 22);
      expect(profile.netBalance, 4);
      expect(profile.playerWinRate, closeTo(0.6, 0.001));
      expect(profile.initials, 'MV');
      expect(profile.rivalryTierLabel, 'Zaciekła Rywalizacja');
    });
  });

  group('RivalManagersHeadToHeadWidget UI & responsiveness', () {
    Widget buildHarness({
      Size size = const Size(1600, 900),
      List<RivalDirectorProfile>? rivals,
      void Function(RivalDirectorProfile, PressConferenceExchange)?
          onSendPressResponse,
    }) {
      return MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: RivalManagersHeadToHeadWidget(
                  rivals: rivals,
                  onSendPressResponse: onSendPressResponse,
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (final viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(buildHarness(size: viewport));
          await tester.pump(const Duration(milliseconds: 350));

          expect(
            find.text('Rywalizacja Dyrektorów Sportowych WorldTour'),
            findsOneWidget,
          );
          expect(find.text('Matej Velasco'), findsWidgets);
          expect(
            find.text('Bilans Bezpośrednich Pojedynków'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('filters by tactical style and handles empty state',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final onlyAggressive = RivalManagersSampleCatalog.defaultRivals()
          .where((r) => r.tacticalStyle == RivalTacticalStyle.aggressive)
          .toList();

      await tester.pumpWidget(
        buildHarness(size: const Size(1600, 900), rivals: onlyAggressive),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Kalkulujący').first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Brak dyrektorów spełniających kryteria'),
        findsOneWidget,
      );

      await tester.tap(find.text('Resetuj filtry'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Matej Velasco'), findsWidgets);
    });

    testWidgets('selects rival and publishes press conference response',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      PressConferenceExchange? capturedExchange;
      RivalDirectorProfile? capturedRival;

      await tester.pumpWidget(
        buildHarness(
          size: const Size(1600, 900),
          onSendPressResponse: (rival, exchange) {
            capturedRival = rival;
            capturedExchange = exchange;
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Henrik van Dijk').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Nordic Visma Dynamics • Taktyczny Szach'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField).last,
        'Na alpejskich przełęczach odpowiemy atakiem od podnóża.',
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.ensureVisible(find.text('Opublikuj wypowiedź'));
      await tester.pump();
      await tester.tap(find.text('Opublikuj wypowiedź'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(capturedRival?.id, 'ds_vandijk');
      expect(
        capturedExchange?.quote,
        'Na alpejskich przełęczach odpowiemy atakiem od podnóża.',
      );
      expect(
        find.text(
          '„Na alpejskich przełęczach odpowiemy atakiem od podnóża.”',
        ),
        findsOneWidget,
      );
    });
  });
}
