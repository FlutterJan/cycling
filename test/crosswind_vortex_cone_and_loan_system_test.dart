import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/physics/aerodynamic_cross_drafting_echelon_vortex.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/services/career/junior_development_loan_system_service.dart';

void main() {
  group('AerodynamicCrossDraftingEchelonVortex — stożek draftingu w wachlarzu', () {
    test('kanoniczny wachlarz 35° daje ~38% redukcji oporu w przesuniętym stożku', () {
      final input = EchelonVortexInput.canonical35DegreeEchelon(
        riderSpeedMs: 12.5,
        longitudinalGapMeters: 0.55,
        windFromLeft: true,
      );

      final result = AerodynamicCrossDraftingEchelonVortex.evaluateSingleDraft(
        input,
      );

      expect(result.wakeShiftAngleDegrees, closeTo(35.0, 0.01));
      expect(result.windSide, EchelonWindSide.fromLeft);
      expect(result.coneZone, EchelonConeZone.optimalVortexCone);
      expect(result.effectiveDragReduction, closeTo(0.38, 0.01));
      expect(result.dragReductionPercent, closeTo(38.0, 1.0));
      expect(result.powerSavedWatts, greaterThan(100.0));
      expect(result.isWheelOverlap, isFalse);
      expect(result.angularDeviationFromConeDegrees.abs(), lessThan(0.5));
    });

    test('wiatr z prawej strony przesuwa stożek cienia w lewo (ujemny offset)', () {
      final input = EchelonVortexInput.canonical35DegreeEchelon(
        riderSpeedMs: 12.5,
        longitudinalGapMeters: 0.55,
        windFromLeft: false,
      );

      final result = AerodynamicCrossDraftingEchelonVortex.evaluateSingleDraft(
        input,
      );

      expect(result.wakeShiftAngleDegrees, closeTo(-35.0, 0.01));
      expect(result.windSide, EchelonWindSide.fromRight);
      expect(result.optimalLateralOffsetMeters, lessThan(0.0));
      expect(result.coneZone, EchelonConeZone.optimalVortexCone);
      expect(result.effectiveDragReduction, closeTo(0.38, 0.01));
    });

    test('jazda bezpośrednio za kołem w wachlarzu 35° spada do ~12% redukcji', () {
      final optimalResult =
          AerodynamicCrossDraftingEchelonVortex.evaluateSingleDraft(
            EchelonVortexInput.canonical35DegreeEchelon(),
          );
      final directWheelResult =
          AerodynamicCrossDraftingEchelonVortex.evaluateSingleDraft(
            EchelonVortexInput.canonical35DegreeEchelon(
              alignDirectlyBehindWheel: true,
            ),
          );

      expect(
        directWheelResult.coneZone,
        EchelonConeZone.directWheelMisaligned,
      );
      expect(directWheelResult.effectiveDragReduction, closeTo(0.12, 0.015));
      expect(
        directWheelResult.powerSavedWatts,
        lessThan(optimalResult.powerSavedWatts * 0.4),
      );
      expect(
        directWheelResult.lateralCorrectionNeededMeters,
        greaterThan(0.5),
      );
    });

    test('jazda po stronie nawietrznej daje pełną ekspozycję (<10% redukcji)', () {
      final windwardInput = EchelonVortexInput.canonical35DegreeEchelon(
        windFromLeft: true,
        lateralOffsetMeters: -0.60,
      );

      final result = AerodynamicCrossDraftingEchelonVortex.evaluateSingleDraft(
        windwardInput,
      );

      expect(result.coneZone, EchelonConeZone.windwardExposed);
      expect(result.effectiveDragReduction, lessThan(0.10));
    });

    test('wiatr osiowy (0°) klasyfikuje się jako neutralny bez przesunięcia bocznego', () {
      const headwindInput = EchelonVortexInput(
        riderSpeedMs: 12.5,
        windSpeedMs: 6.0,
        windRelativeAngleDegrees: 0.0,
        longitudinalGapMeters: 0.50,
        lateralOffsetMeters: 0.0,
      );

      final result = AerodynamicCrossDraftingEchelonVortex.evaluateSingleDraft(
        headwindInput,
      );

      expect(result.windSide, EchelonWindSide.neutral);
      expect(result.wakeShiftAngleDegrees, closeTo(0.0, 0.01));
      expect(result.coneZone, EchelonConeZone.optimalVortexCone);
      expect(result.effectiveDragReduction, closeTo(0.38, 0.01));
    });

    test('nakładanie kół (ujemny odstęp podłużny) ustawia flagę isWheelOverlap', () {
      final overlapInput = EchelonVortexInput.canonical35DegreeEchelon(
        longitudinalGapMeters: -0.15,
      );

      final result = AerodynamicCrossDraftingEchelonVortex.evaluateSingleDraft(
        overlapInput,
      );

      expect(result.isWheelOverlap, isTrue);
    });

    test('evaluateEchelonFormation analizuje cały szyk i wskazuje najbardziej odsłoniętego', () {
      final emptySummary =
          AerodynamicCrossDraftingEchelonVortex.evaluateEchelonFormation(
            riders: const [],
          );
      expect(emptySummary.riders, isEmpty);
      expect(emptySummary.mostExposedFollower, isNull);
      expect(emptySummary.totalPowerSavedWatts, 0.0);

      final optimalOffset =
          AerodynamicCrossDraftingEchelonVortex.computeOptimalLateralOffsetMeters(
            longitudinalGapMeters: 0.55,
            wakeShiftAngleDegrees: 35.0,
          );

      final summary =
          AerodynamicCrossDraftingEchelonVortex.evaluateEchelonFormation(
            riders: [
              const EchelonFormationRiderInput(
                riderId: 'r1',
                riderName: 'Lider',
                longitudinalGapFromLeaderMeters: 0.0,
                lateralOffsetFromLeaderMeters: 0.0,
              ),
              EchelonFormationRiderInput(
                riderId: 'r2',
                riderName: 'Pomocnik W Stożku',
                longitudinalGapFromLeaderMeters: 0.55,
                lateralOffsetFromLeaderMeters: optimalOffset,
              ),
              EchelonFormationRiderInput(
                riderId: 'r3',
                riderName: 'Spóźniony Na Wietrze',
                longitudinalGapFromLeaderMeters: 1.10,
                lateralOffsetFromLeaderMeters: optimalOffset - 0.65,
              ),
            ],
            overrideWakeShiftAngleDegrees: 35.0,
          );

      expect(summary.riders, hasLength(3));
      expect(summary.riders.first.vortexResult.effectiveDragReduction, 0.0);
      expect(
        summary.riders[1].vortexResult.coneZone,
        EchelonConeZone.optimalVortexCone,
      );
      expect(summary.mostExposedFollower?.input.riderId, 'r3');
      expect(summary.totalPowerSavedWatts, greaterThan(100.0));
      expect(summary.averageDragReduction, greaterThan(0.15));
    });
  });

  group('JuniorDevelopmentLoanSystemService — wypożyczenia juniorów do ProTeam', () {
    const service = JuniorDevelopmentLoanSystemService();

    JuniorLoanCandidate makeCandidate({
      String id = 'jr_test_1',
      int age = 19,
      double ovr = 69.0,
      int potential = 88,
      int wtDays = 10,
      bool injured = false,
      bool onLoan = false,
    }) {
      return JuniorLoanCandidate(
        riderId: id,
        fullName: 'Jan Testowy',
        age: age,
        nationalityIso: 'PL',
        specialization: RiderSpecialization.gcClimber,
        overallRating: ovr,
        potential: potential,
        projectedWtRaceDays: wtDays,
        currentRaceIq: 62,
        currentFtpWatts: 390,
        annualSalaryEur: 60000,
        isInjured: injured,
        isCurrentlyOnLoan: onLoan,
      );
    }

    test('createDefaultPartnerClubs dostarcza kluby ProTeam i Continental z wolnymi miejscami', () {
      final clubs = service.createDefaultPartnerClubs();

      expect(clubs, isNotEmpty);
      expect(
        clubs.where((c) => c.division == LoanPartnerDivision.proTeam),
        isNotEmpty,
      );
      expect(
        clubs.where((c) => c.division == LoanPartnerDivision.continental),
        isNotEmpty,
      );
      expect(clubs.every((c) => c.hasOpenSlot), isTrue);
    });

    test('compareLoanVsBench wykazuje wyraźną przewagę rozwoju w ProTeam nad ławką WT', () {
      final junior = makeCandidate(wtDays: 10);
      final proTeam = service.createDefaultPartnerClubs().firstWhere(
        (c) => c.division == LoanPartnerDivision.proTeam,
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
      expect(comparison.salarySavedEur, greaterThan(0));
      expect(comparison.netDevelopmentAdvantagePercent, greaterThan(50.0));
    });

    test('createLoanAgreement waliduje wiek, kontuzje, aktywne wypożyczenie i sloty klubu', () {
      final proTeam = service.createDefaultPartnerClubs().first;

      final okResult = service.createLoanAgreement(
        candidate: makeCandidate(),
        partner: proTeam,
        focus: LoanDevelopmentFocus.stageRacingGc,
        recallClause: LoanRecallClauseType.emergencyInjuryRecall,
        seasonYear: 2026,
      );
      expect(okResult.success, isTrue);
      expect(okResult.agreement?.status, LoanContractStatus.active);
      expect(okResult.updatedCandidate?.isCurrentlyOnLoan, isTrue);
      expect(okResult.financialDeltaEur, greaterThan(0));

      final injuredFail = service.createLoanAgreement(
        candidate: makeCandidate(injured: true),
        partner: proTeam,
        focus: LoanDevelopmentFocus.stageRacingGc,
        recallClause: LoanRecallClauseType.emergencyInjuryRecall,
        seasonYear: 2026,
      );
      expect(injuredFail.success, isFalse);

      final tooOldFail = service.createLoanAgreement(
        candidate: makeCandidate(age: 23),
        partner: proTeam,
        focus: LoanDevelopmentFocus.stageRacingGc,
        recallClause: LoanRecallClauseType.emergencyInjuryRecall,
        seasonYear: 2026,
      );
      expect(tooOldFail.success, isFalse);

      final alreadyOnLoanFail = service.createLoanAgreement(
        candidate: makeCandidate(onLoan: true),
        partner: proTeam,
        focus: LoanDevelopmentFocus.stageRacingGc,
        recallClause: LoanRecallClauseType.emergencyInjuryRecall,
        seasonYear: 2026,
      );
      expect(alreadyOnLoanFail.success, isFalse);

      final fullClubFail = service.createLoanAgreement(
        candidate: makeCandidate(),
        partner: proTeam.copyWith(availableRosterSlots: 0),
        focus: LoanDevelopmentFocus.stageRacingGc,
        recallClause: LoanRecallClauseType.emergencyInjuryRecall,
        seasonYear: 2026,
      );
      expect(fullClubFail.success, isFalse);
    });

    test('simulateLoanProgressTick nalicza progres i kończy wypożyczenie po 240 dniach', () {
      final proTeam = service.createDefaultPartnerClubs().first;
      final candidate = makeCandidate();
      final created = service.createLoanAgreement(
        candidate: candidate,
        partner: proTeam,
        focus: LoanDevelopmentFocus.stageRacingGc,
        recallClause: LoanRecallClauseType.emergencyInjuryRecall,
        seasonYear: 2026,
      );

      var agreement = created.agreement!;
      var updatedCand = created.updatedCandidate!;

      for (int i = 0; i < 8; i++) {
        final tick = service.simulateLoanProgressTick(
          agreement: agreement,
          candidate: updatedCand,
          partner: proTeam,
          daysElapsed: 30,
        );
        expect(tick.success, isTrue);
        agreement = tick.agreement!;
        updatedCand = tick.updatedCandidate!;
      }

      expect(agreement.elapsedSeasonDays, 240);
      expect(agreement.status, LoanContractStatus.completed);
      expect(agreement.accumulatedRaceDays, greaterThan(40));
      expect(agreement.accumulatedOvrGain, greaterThan(1.0));
      expect(updatedCand.overallRating, greaterThan(candidate.overallRating));
      expect(updatedCand.currentFtpWatts, greaterThan(candidate.currentFtpWatts));
      expect(updatedCand.isCurrentlyOnLoan, isFalse);
    });

    test('auditWorldTourRoster i recallRiderFromLoan obsługują plagę kontuzji oraz klauzule', () {
      final proTeam = service.createDefaultPartnerClubs().first;
      final candidate = makeCandidate();
      final created = service.createLoanAgreement(
        candidate: candidate,
        partner: proTeam,
        focus: LoanDevelopmentFocus.stageRacingGc,
        recallClause: LoanRecallClauseType.emergencyInjuryRecall,
        seasonYear: 2026,
      );

      final plagueAudit = service.auditWorldTourRoster(
        wtRosterSize: 28,
        injuredCount: 5,
        juniors: [created.updatedCandidate!],
        agreements: [created.agreement!],
      );
      expect(plagueAudit.isInjuryPlagueActive, isTrue);
      expect(plagueAudit.recommendedAction, contains('ALERT KONTUZJI'));

      final emergencyRecall = service.recallRiderFromLoan(
        agreement: created.agreement!,
        candidate: created.updatedCandidate!,
        rosterAudit: plagueAudit,
      );
      expect(emergencyRecall.success, isTrue);
      expect(emergencyRecall.financialDeltaEur, 0);
      expect(
        emergencyRecall.agreement?.status,
        LoanContractStatus.recalledEarly,
      );
      expect(emergencyRecall.updatedCandidate?.isCurrentlyOnLoan, isFalse);

      // Klauzula 14 dni bez plagi kontuzji nalicza opłatę 15 000 EUR
      final noticeCreated = service.createLoanAgreement(
        candidate: makeCandidate(id: 'jr_notice'),
        partner: proTeam,
        focus: LoanDevelopmentFocus.stageRacingGc,
        recallClause: LoanRecallClauseType.mutualNotice14Days,
        seasonYear: 2026,
      );
      final calmAudit = service.auditWorldTourRoster(
        wtRosterSize: 28,
        injuredCount: 1,
        juniors: [noticeCreated.updatedCandidate!],
        agreements: [noticeCreated.agreement!],
      );
      final paidRecall = service.recallRiderFromLoan(
        agreement: noticeCreated.agreement!,
        candidate: noticeCreated.updatedCandidate!,
        rosterAudit: calmAudit,
      );
      expect(paidRecall.success, isTrue);
      expect(paidRecall.financialDeltaEur, -15000);

      // Klauzula lockedFullSeason blokuje wcześniejsze ściągnięcie
      final lockedCreated = service.createLoanAgreement(
        candidate: makeCandidate(id: 'jr_locked'),
        partner: proTeam,
        focus: LoanDevelopmentFocus.stageRacingGc,
        recallClause: LoanRecallClauseType.lockedFullSeason,
        seasonYear: 2026,
      );
      final lockedRecall = service.recallRiderFromLoan(
        agreement: lockedCreated.agreement!,
        candidate: lockedCreated.updatedCandidate!,
        rosterAudit: plagueAudit,
      );
      expect(lockedRecall.success, isFalse);
    });

    test('serializacja JSON modeli wypożyczeń działa 1:1', () {
      final club = service.createDefaultPartnerClubs().first;
      final clubRoundTrip = PartnerClubProfile.fromJson(club.toJson());
      expect(clubRoundTrip.id, club.id);
      expect(clubRoundTrip.division, club.division);
      expect(clubRoundTrip.guaranteedRaceDays, club.guaranteedRaceDays);

      final cand = makeCandidate();
      final candRoundTrip = JuniorLoanCandidate.fromJson(cand.toJson());
      expect(candRoundTrip.riderId, cand.riderId);
      expect(candRoundTrip.specialization, cand.specialization);
      expect(candRoundTrip.potential, cand.potential);

      final agreement = service
          .createLoanAgreement(
            candidate: cand,
            partner: club,
            focus: LoanDevelopmentFocus.cobblesAndClassics,
            recallClause: LoanRecallClauseType.mutualNotice14Days,
            seasonYear: 2026,
          )
          .agreement!;
      final agreementRoundTrip = JuniorLoanAgreement.fromJson(
        agreement.toJson(),
      );
      expect(agreementRoundTrip.loanId, agreement.loanId);
      expect(agreementRoundTrip.recallClause, agreement.recallClause);
      expect(agreementRoundTrip.developmentFocus, agreement.developmentFocus);
      expect(agreementRoundTrip.status, agreement.status);
    });

    test('JuniorLoanSystemNotifier zarządza cyklem wypożyczenia przez Riverpod', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(juniorDevelopmentLoanProvider.notifier);
      final initialState = container.read(juniorDevelopmentLoanProvider);
      expect(initialState.agreements, hasLength(1));

      final initialSlots = initialState.selectedPartner!.availableRosterSlots;
      notifier.sendSelectedJuniorOnLoan();

      final afterLoan = container.read(juniorDevelopmentLoanProvider);
      expect(afterLoan.agreements, hasLength(2));
      expect(afterLoan.lastFeedbackIsError, isFalse);
      expect(
        afterLoan.selectedPartner!.availableRosterSlots,
        initialSlots - 1,
      );

      notifier.advanceActiveLoansMonth();
      final afterMonth = container.read(juniorDevelopmentLoanProvider);
      expect(afterMonth.agreements.first.elapsedSeasonDays, 30);

      notifier.toggleInjuryPlagueSimulation();
      expect(
        container.read(juniorDevelopmentLoanProvider).injuredWtCount,
        greaterThanOrEqualTo(4),
      );

      final newLoanId = afterMonth.agreements.first.loanId;
      notifier.recallLoanById(newLoanId);
      final afterRecall = container.read(juniorDevelopmentLoanProvider);
      final recalled = afterRecall.agreements.firstWhere(
        (a) => a.loanId == newLoanId,
      );
      expect(recalled.status, LoanContractStatus.recalledEarly);
      expect(
        afterRecall.selectedPartner!.availableRosterSlots,
        initialSlots,
      );
    });
  });

  group('Testy widgetowe i responsywności (390x844, 1024x768, 1600x900)', () {
    const viewports = [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ];

    for (final size in viewports) {
      testWidgets(
        'AerodynamicCrossDraftingEchelonVortexPanel renderuje się bez overflow na ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          EchelonVortexResult? lastResult;

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: AerodynamicCrossDraftingEchelonVortexPanel(
                    onResultChanged: (res) => lastResult = res,
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.byType(CustomPaint), findsWidgets);

          final directWheelButton = find.textContaining('Bezpośrednio');
          if (directWheelButton.evaluate().isNotEmpty) {
            await tester.tap(directWheelButton.first);
            await tester.pump(const Duration(milliseconds: 300));
            expect(tester.takeException(), isNull);
            expect(
              lastResult?.coneZone,
              EchelonConeZone.directWheelMisaligned,
            );
          }
        },
      );

      testWidgets(
        'JuniorDevelopmentLoanSystemPanel renderuje się bez overflow na ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.darkTheme,
                home: const Scaffold(
                  body: JuniorDevelopmentLoanSystemPanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.byType(JuniorDevelopmentLoanSystemPanel), findsOneWidget);
          expect(find.textContaining('Kacper Kowalski'), findsWidgets);

          final activeFilter = find.text('Na wypożyczeniu');
          if (activeFilter.evaluate().isNotEmpty) {
            await tester.tap(activeFilter.first);
            await tester.pump(const Duration(milliseconds: 300));
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  });
}
