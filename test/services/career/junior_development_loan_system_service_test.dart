// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/services/career/junior_development_loan_system_service.dart';

void main() {
  const service = JuniorDevelopmentLoanSystemService();

  JuniorLoanCandidate buildJunior({
    String id = 'jr_1',
    int age = 19,
    int projectedWtRaceDays = 10,
    bool isInjured = false,
    bool isOnLoan = false,
  }) {
    return JuniorLoanCandidate(
      riderId: id,
      fullName: 'Kacper Kowalski',
      age: age,
      nationalityIso: 'PL',
      specialization: RiderSpecialization.gcClimber,
      overallRating: 69.0,
      potential: 89,
      projectedWtRaceDays: projectedWtRaceDays,
      currentRaceIq: 62,
      currentFtpWatts: 390,
      annualSalaryEur: 60000,
      isInjured: isInjured,
      isCurrentlyOnLoan: isOnLoan,
    );
  }

  group('JuniorDevelopmentLoanSystemService', () {
    test('detects 28-rider WT bench stagnation and injury plague', () {
      final junior = buildJunior();
      final auditNormal = service.auditWorldTourRoster(
        wtRosterSize: 28,
        injuredCount: 1,
        juniors: [junior],
        agreements: const [],
      );
      expect(auditNormal.isInjuryPlagueActive, isFalse);
      expect(auditNormal.benchStagnatingJuniorsCount, 1);
      expect(auditNormal.recommendedAction, contains('28/28'));

      final partner = service.createDefaultPartnerClubs().first;
      final loan = service.createLoanAgreement(
        candidate: junior,
        partner: partner,
        focus: LoanDevelopmentFocus.stageRacingGc,
        recallClause: LoanRecallClauseType.emergencyInjuryRecall,
        seasonYear: 2026,
      ).agreement!;

      final auditPlague = service.auditWorldTourRoster(
        wtRosterSize: 28,
        injuredCount: 5,
        juniors: [junior.copyWith(isCurrentlyOnLoan: true)],
        agreements: [loan],
      );
      expect(auditPlague.isInjuryPlagueActive, isTrue);
      expect(auditPlague.recommendedAction, contains('ALERT KONTUZJI'));
    });

    test('loan yields faster stat and race-day progression than WT bench', () {
      final junior = buildJunior(age: 19, projectedWtRaceDays: 11);
      final proTeam = service.createDefaultPartnerClubs().firstWhere(
            (p) => p.division == LoanPartnerDivision.proTeam,
          );

      final comparison = service.compareLoanVsBench(
        candidate: junior,
        partner: proTeam,
        focus: proTeam.calendarFocus,
      );

      expect(
        comparison.loanProjectedRaceDays,
        greaterThan(comparison.benchProjectedRaceDays),
      );
      expect(
        comparison.loanProjectedOvrGain,
        greaterThan(comparison.benchProjectedOvrGain),
      );
      expect(
        comparison.loanProjectedRaceIqGain,
        greaterThan(comparison.benchProjectedRaceIqGain),
      );
      expect(
        comparison.loanProjectedFtpGain,
        greaterThan(comparison.benchProjectedFtpGain),
      );
      expect(comparison.netDevelopmentAdvantagePercent, greaterThan(100.0));
    });

    test('validates eligibility and simulates 1-season progression to completion', () {
      final partners = service.createDefaultPartnerClubs();
      final partner = partners.first;

      final tooOld = buildJunior(age: 24);
      final oldRes = service.createLoanAgreement(
        candidate: tooOld,
        partner: partner,
        focus: LoanDevelopmentFocus.stageRacingGc,
        recallClause: LoanRecallClauseType.emergencyInjuryRecall,
        seasonYear: 2026,
      );
      expect(oldRes.success, isFalse);

      var junior = buildJunior(age: 19);
      final createRes = service.createLoanAgreement(
        candidate: junior,
        partner: partner,
        focus: LoanDevelopmentFocus.stageRacingGc,
        recallClause: LoanRecallClauseType.emergencyInjuryRecall,
        seasonYear: 2026,
      );
      expect(createRes.success, isTrue);
      var agreement = createRes.agreement!;
      junior = createRes.updatedCandidate!;
      expect(junior.isCurrentlyOnLoan, isTrue);

      // Advance full 240-day season in 30-day ticks
      for (int i = 0; i < 8; i++) {
        final tick = service.simulateLoanProgressTick(
          agreement: agreement,
          candidate: junior,
          partner: partner,
          daysElapsed: 30,
        );
        expect(tick.success, isTrue);
        agreement = tick.agreement!;
        junior = tick.updatedCandidate!;
      }

      expect(agreement.status, LoanContractStatus.completed);
      expect(junior.isCurrentlyOnLoan, isFalse);
      expect(junior.overallRating, greaterThan(69.0));
      expect(junior.currentRaceIq, greaterThan(62));
      expect(junior.currentFtpWatts, greaterThan(390));
    });

    test('instant recall during injury plague has 0 EUR fee while locked blocks', () {
      final partner = service.createDefaultPartnerClubs().first;
      final junior = buildJunior();

      final emergencyLoan = service.createLoanAgreement(
        candidate: junior,
        partner: partner,
        focus: LoanDevelopmentFocus.stageRacingGc,
        recallClause: LoanRecallClauseType.emergencyInjuryRecall,
        seasonYear: 2026,
      );

      final plagueAudit = service.auditWorldTourRoster(
        wtRosterSize: 28,
        injuredCount: 5,
        juniors: [emergencyLoan.updatedCandidate!],
        agreements: [emergencyLoan.agreement!],
      );

      final recallRes = service.recallRiderFromLoan(
        agreement: emergencyLoan.agreement!,
        candidate: emergencyLoan.updatedCandidate!,
        rosterAudit: plagueAudit,
      );
      expect(recallRes.success, isTrue);
      expect(recallRes.agreement!.status, LoanContractStatus.recalledEarly);
      expect(recallRes.agreement!.recallFeeEur, 0);
      expect(recallRes.updatedCandidate!.isCurrentlyOnLoan, isFalse);

      final lockedLoan = service.createLoanAgreement(
        candidate: junior,
        partner: partner,
        focus: LoanDevelopmentFocus.stageRacingGc,
        recallClause: LoanRecallClauseType.lockedFullSeason,
        seasonYear: 2026,
      );
      final lockedRecall = service.recallRiderFromLoan(
        agreement: lockedLoan.agreement!,
        candidate: lockedLoan.updatedCandidate!,
        rosterAudit: plagueAudit,
      );
      expect(lockedRecall.success, isFalse);
    });

    test('JSON round-trip serialization preserves all fields', () {
      final partner = service.createDefaultPartnerClubs().first;
      final partnerJson = PartnerClubProfile.fromJson(partner.toJson());
      expect(partnerJson.id, partner.id);
      expect(partnerJson.division, partner.division);

      final junior = buildJunior();
      final juniorJson = JuniorLoanCandidate.fromJson(junior.toJson());
      expect(juniorJson.riderId, junior.riderId);
      expect(juniorJson.age, 19);

      final loan = service.createLoanAgreement(
        candidate: junior,
        partner: partner,
        focus: LoanDevelopmentFocus.cobblesAndClassics,
        recallClause: LoanRecallClauseType.emergencyInjuryRecall,
        seasonYear: 2026,
      ).agreement!;
      final loanJson = JuniorLoanAgreement.fromJson(loan.toJson());
      expect(loanJson.loanId, loan.loanId);
      expect(loanJson.recallClause, LoanRecallClauseType.emergencyInjuryRecall);
      expect(loanJson.developmentFocus, LoanDevelopmentFocus.cobblesAndClassics);
    });
  });

  group('JuniorDevelopmentLoanSystemPanel responsive UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: JuniorDevelopmentLoanSystemPanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(
            find.text('System Wypożyczeń Młodych Talentów'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('supports sending junior on loan and emergency recall',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: JuniorDevelopmentLoanSystemPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final sendBtn = find.text('Wypożycz Kacper Kowalski na 1 sezon');
      expect(sendBtn, findsOneWidget);
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Wypożyczono Kacper Kowalski'), findsOneWidget);

      final plagueBtn = find.text('Symuluj plagę kontuzji');
      await tester.ensureVisible(plagueBtn);
      await tester.tap(plagueBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('ALERT KONTUZJI'), findsOneWidget);
    });
  });
}
