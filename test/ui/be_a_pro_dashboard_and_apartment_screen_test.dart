import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/pro_cyclist_career_state.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/ui/screens/be_a_pro_dashboard_and_apartment_screen.dart';

void main() {
  Future<void> pumpScreenAtSize(
    WidgetTester tester, {
    required Size size,
    ValueChanged<ProCyclistCareerState>? onStateChanged,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BeAProDashboardAndApartmentScreen(
          onStateChanged: onStateChanged,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('BeAProDashboardAndApartmentScreen', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders all 5 sections without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await pumpScreenAtSize(tester, size: size);

          expect(
            find.textContaining('Apartament & Baza Treningowa'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);

          for (final tabLabel in const [
            'Rozwój XP',
            'SMS (DS & Agent)',
            'Oferty WT',
            'Gablota',
            'Apartament',
          ]) {
            final tabFinder = find.text(tabLabel, skipOffstage: false).first;
            await tester.ensureVisible(tabFinder);
            await tester.pump(const Duration(milliseconds: 100));
            await tester.tap(tabFinder);
            await tester.pump(const Duration(milliseconds: 300));
          }
        },
      );
    }

    testWidgets('upgrades skill node using SP and grants XP from training', (
      tester,
    ) async {
      ProCyclistCareerState? latestState;
      await pumpScreenAtSize(
        tester,
        size: const Size(1600, 900),
        onStateChanged: (s) => latestState = s,
      );

      // Indoor training grants XP
      await tester.tap(find.text('Trenuj na Trenażerze (+XP)'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(latestState, isNotNull);
      expect(latestState!.experienceXp, greaterThan(0));

      // Switch to Skill Tree and upgrade FTP
      await tester.tap(find.text('Rozwój XP').first);
      await tester.pump(const Duration(milliseconds: 300));

      final prevFtp = latestState!.playerRider.physiology.ftpWatts;
      final prevSp = latestState!.skillPoints;

      await tester.tap(find.text('Próg Mleczanowy FTP'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(latestState!.playerRider.physiology.ftpWatts, prevFtp + 4);
      expect(latestState!.skillPoints, prevSp - 1);
    });

    testWidgets('sends SMS quick reply and signs WorldTour contract', (
      tester,
    ) async {
      ProCyclistCareerState? latestState;
      await pumpScreenAtSize(
        tester,
        size: const Size(1600, 900),
        onStateChanged: (s) => latestState = s,
      );

      // Open SMS tab and send a quick reply
      await tester.tap(find.text('SMS (DS & Agent)').first);
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(
        find.text('Biorę pełną odpowiedzialność. Zbieram pomocników na finał!'),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(latestState, isNotNull);
      expect(latestState!.dsTrustScore, greaterThan(76.0));
      expect(
        find.textContaining('Takiej pewności siebie oczekuję'),
        findsOneWidget,
      );

      // Open WorldTour Contract Offers and sign Team Visma-Veloce
      await tester.tap(find.text('Oferty WT').first);
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Podpisz Kontrakt').first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(latestState!.currentTeamName, 'Team Visma-Veloce');
      expect(latestState!.currentDivision, TeamDivision.worldTour);
    });

    testWidgets('filters trophy cabinet items', (tester) async {
      await pumpScreenAtSize(tester, size: const Size(1280, 800));

      await tester.tap(find.text('Gablota').first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Koszulka w Grochy KOM'), findsOneWidget);
      expect(find.text('Kostka Bruku Roubaix'), findsOneWidget);

      await tester.tap(find.text('Koszulki').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Koszulka w Grochy KOM'), findsOneWidget);
      expect(find.text('Kostka Bruku Roubaix'), findsNothing);

      await tester.tap(find.text('Puchary').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Kostka Bruku Roubaix'), findsOneWidget);
      expect(find.text('Koszulka w Grochy KOM'), findsNothing);
    });
  });
}
