import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/pro_cyclist_career_state.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/career/pro_cyclist_lifestyle_and_wealth_service.dart';
import 'package:pro_peloton_manager/services/generators/world_teams_generator.dart';

ProCyclistCareerState _createTestCareerState({
  int balanceEur = 120000,
  double fameScore = 50.0,
  ProCyclistCareerTier tier = ProCyclistCareerTier.worldTourCoLeader,
}) {
  final world = WorldTeamsGenerator.generateWorldTourSystem(seed: 202604);
  final rider = world.allRiders.first;
  return ProCyclistCareerState.createNew(
    careerId: 'test_career_319',
    careerName: 'Sniper 319 Test',
    playerRider: rider,
    startDate: DateTime(2026, 1, 15),
    initialPrivateBalanceEur: balanceEur,
  ).copyWith(
    fameScore: fameScore,
    careerTier: tier,
    currentDivision: TeamDivision.worldTour,
  );
}

void main() {
  group('ProCyclistLifestyleAndWealthService', () {
    test('wybór i zakup rezydencji nalicza właściwe bonusy (Girona, Andora, Monako, Flandria)', () {
      var career = _createTestCareerState(balanceEur: 2500000);
      var lifestyle = const ProCyclistLifestyleState();

      // Girona: +10% treningu wytrzymałościowego
      final gironaSummary =
          ProCyclistLifestyleAndWealthService.computeBonusSummary(
        careerState: career,
        lifestyleState: lifestyle,
      );
      expect(gironaSummary.enduranceTrainingBonusPercent, 10.0);

      // Wynajem w Andorze (2000 m n.p.m. -> +4.5% hematokryt)
      final andorraRes =
          ProCyclistLifestyleAndWealthService.selectOrBuyResidence(
        careerState: career,
        lifestyleState: lifestyle,
        city: CyclistResidenceCity.andorra,
        buyProperty: false,
      );
      expect(andorraRes.success, isTrue);
      career = andorraRes.careerState;
      lifestyle = andorraRes.lifestyleState;

      final andorraSummary =
          ProCyclistLifestyleAndWealthService.computeBonusSummary(
        careerState: career,
        lifestyleState: lifestyle,
      );
      expect(andorraSummary.altitudeHematocritBonusPercent, 4.5);

      // Zakup penthouse'a w Monako (niższe podatki i +25% sławy)
      final monacoBuy =
          ProCyclistLifestyleAndWealthService.selectOrBuyResidence(
        careerState: career,
        lifestyleState: lifestyle,
        city: CyclistResidenceCity.monaco,
        buyProperty: true,
      );
      expect(monacoBuy.success, isTrue);
      expect(
        ProCyclistLifestyleAndWealthService.isResidenceOwned(
          monacoBuy.careerState,
          CyclistResidenceCity.monaco,
        ),
        isTrue,
      );
      final monacoSummary =
          ProCyclistLifestyleAndWealthService.computeBonusSummary(
        careerState: monacoBuy.careerState,
        lifestyleState: monacoBuy.lifestyleState,
      );
      expect(monacoSummary.effectiveTaxRatePercent, 3.0);
      expect(monacoSummary.fameGainMultiplier, 1.25);

      // Flandria: +15% bruku i wiatru
      final flandersRes =
          ProCyclistLifestyleAndWealthService.selectOrBuyResidence(
        careerState: career,
        lifestyleState: lifestyle,
        city: CyclistResidenceCity.flanders,
        buyProperty: false,
      );
      expect(flandersRes.success, isTrue);
      final flandersSummary =
          ProCyclistLifestyleAndWealthService.computeBonusSummary(
        careerState: flandersRes.careerState,
        lifestyleState: flandersRes.lifestyleState,
      );
      expect(flandersSummary.cobbleAndWindTrainingBonusPercent, 15.0);
    });

    test('zakup namiotu hipoksyjnego oraz zatrudnienie dietetyka i osteopaty', () {
      var career = _createTestCareerState(balanceEur: 50000);
      var lifestyle = const ProCyclistLifestyleState();

      final tentRes = ProCyclistLifestyleAndWealthService.purchaseUpgrade(
        careerState: career,
        lifestyleState: lifestyle,
        upgradeId: LifestyleUpgradeId.hypoxicTent,
      );
      expect(tentRes.success, isTrue);
      career = tentRes.careerState;
      lifestyle = tentRes.lifestyleState;

      // Duplikat zakupu powinien zostać odrzucony
      final duplicateTent = ProCyclistLifestyleAndWealthService.purchaseUpgrade(
        careerState: career,
        lifestyleState: lifestyle,
        upgradeId: LifestyleUpgradeId.hypoxicTent,
      );
      expect(duplicateTent.success, isFalse);

      // Zatrudnienie dietetyka i osteopaty
      final dietRes = ProCyclistLifestyleAndWealthService.togglePersonalStaff(
        careerState: career,
        lifestyleState: lifestyle,
        role: PersonalSupportStaffRole.personalDietitian,
      );
      expect(dietRes.success, isTrue);

      final osteoRes = ProCyclistLifestyleAndWealthService.togglePersonalStaff(
        careerState: dietRes.careerState,
        lifestyleState: dietRes.lifestyleState,
        role: PersonalSupportStaffRole.personalOsteopath,
      );
      expect(osteoRes.success, isTrue);

      final summary = ProCyclistLifestyleAndWealthService.computeBonusSummary(
        careerState: osteoRes.careerState,
        lifestyleState: osteoRes.lifestyleState,
      );
      expect(summary.altitudeHematocritBonusPercent, 3.5);
      expect(summary.glycogenEfficiencyBonusPercent, 10.0);
      expect(summary.injuryRiskReductionPercent, 30.0);
      expect(summary.recoveryBonusPercent, greaterThan(15.0));
    });

    test('kontrakty reklamowe dla osobnych slotów (buty, okulary, zegarek) z walidacją sławy', () {
      var career = _createTestCareerState(
        fameScore: 48.0,
        tier: ProCyclistCareerTier.worldTourCoLeader,
      );
      var lifestyle = const ProCyclistLifestyleState();

      final shoes = ProCyclistLifestyleAndWealthService.signPersonalSponsor(
        careerState: career,
        lifestyleState: lifestyle,
        sponsorId: 'shoe_apex_aero',
      );
      expect(shoes.success, isTrue);
      career = shoes.careerState;
      lifestyle = shoes.lifestyleState;

      final eyewear = ProCyclistLifestyleAndWealthService.signPersonalSponsor(
        careerState: career,
        lifestyleState: lifestyle,
        sponsorId: 'eye_alpine_prism',
      );
      expect(eyewear.success, isTrue);
      career = eyewear.careerState;
      lifestyle = eyewear.lifestyleState;

      final watch = ProCyclistLifestyleAndWealthService.signPersonalSponsor(
        careerState: career,
        lifestyleState: lifestyle,
        sponsorId: 'watch_helvetia_chrono',
      );
      expect(watch.success, isTrue);
      career = watch.careerState;
      lifestyle = watch.lifestyleState;

      expect(lifestyle.activeSponsorsBySlot.length, 3);
      expect(career.activePersonalSponsors.length, 3);

      // Zbyt mała sława dla topowego zegarka (min 78)
      final lockedWatch =
          ProCyclistLifestyleAndWealthService.signPersonalSponsor(
        careerState: career,
        lifestyleState: lifestyle,
        sponsorId: 'watch_geneve_tourbillon',
      );
      expect(lockedWatch.success, isFalse);
    });

    test('inwestycje, wypłata oraz rozliczenie miesięczne i serializacja JSON', () {
      var career = _createTestCareerState(balanceEur: 150000);
      var lifestyle = const ProCyclistLifestyleState();

      final investRes = ProCyclistLifestyleAndWealthService.investSavings(
        careerState: career,
        lifestyleState: lifestyle,
        type: WealthInvestmentType.globalEtfIndex,
        amountEur: 50000,
      );
      expect(investRes.success, isTrue);
      career = investRes.careerState;
      lifestyle = investRes.lifestyleState;
      expect(career.privateBalanceEur, 100000);

      final monthRes =
          ProCyclistLifestyleAndWealthService.processMonthlyFinances(
        careerState: career,
        lifestyleState: lifestyle,
      );
      expect(monthRes.success, isTrue);
      expect(
        monthRes.lifestyleState.lastMonthlyInvestmentYieldEur,
        greaterThan(0),
      );

      final roundTrip = ProCyclistLifestyleState.fromJson(
        monthRes.lifestyleState.toJson(),
      );
      expect(roundTrip.activeCity, monthRes.lifestyleState.activeCity);
      expect(roundTrip.investments.length, 1);

      final withdrawRes =
          ProCyclistLifestyleAndWealthService.liquidateInvestment(
        careerState: monthRes.careerState,
        lifestyleState: monthRes.lifestyleState,
        type: WealthInvestmentType.globalEtfIndex,
      );
      expect(withdrawRes.success, isTrue);
      expect(withdrawRes.lifestyleState.investments, isEmpty);
    });
  });

  group('ProCyclistLifestyleAndWealthPanel Responsive Widget Tests', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnień w rozdzielczości ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final notifier = ProCyclistLifestyleNotifier(
            initialCareer: _createTestCareerState(balanceEur: 500000),
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ProCyclistLifestyleAndWealthPanel(
                  session: notifier.state,
                  onSelectOrBuyResidence: (city, buy) =>
                      notifier.selectOrBuyResidence(city, buyProperty: buy),
                  onPurchaseUpgrade: notifier.purchaseUpgrade,
                  onToggleStaff: notifier.togglePersonalStaff,
                  onSignSponsor: notifier.signPersonalSponsor,
                  onInvest: notifier.investSavings,
                  onLiquidateInvestment: notifier.liquidateInvestment,
                  onProcessMonth: notifier.processMonthlyFinances,
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('Girona'), findsOneWidget);

          // Przełączanie wszystkich zakładek bez błędów layoutu
          await tester.tap(find.text('Sprzęt & Sztab'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            find.text('Prywatny Namiot Hipoksyjny Pro'),
            findsOneWidget,
          );

          await tester.tap(find.text('Sponsorzy'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('Apex Aero Pro'), findsOneWidget);

          await tester.tap(find.text('Inwestycje'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('Globalny Indeks ETF Akcji'), findsOneWidget);

          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
