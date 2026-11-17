import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/organizer/race_organizer_empire_model.dart';
import 'package:pro_peloton_manager/services/organizer/star_rider_appearance_fee_negotiator.dart';

void main() {
  group('StarRiderAppearanceFeeNegotiator — Unit & Logic', () {
    const negotiator = StarRiderAppearanceFeeNegotiator();

    test('CourseBlueprintSpec scores GC vs Sprinters and applies presets', () {
      final base = StarRiderAppearanceFeeNegotiator.createDefaultCourseBlueprint(
        totalStages: 7,
      );

      final mountainCourse = base.applyPreset(
        CourseAttractionFocus.highMountainGcBattle,
      );
      final sprintCourse = base.applyPreset(
        CourseAttractionFocus.sprinterFestival,
      );

      expect(
        mountainCourse.gcAttractivenessScore,
        greaterThan(mountainCourse.sprinterAttractivenessScore),
      );
      expect(
        sprintCourse.sprinterAttractivenessScore,
        greaterThan(sprintCourse.gcAttractivenessScore),
      );
      expect(mountainCourse.inferredFocus, CourseAttractionFocus.highMountainGcBattle);
      expect(sprintCourse.inferredFocus, CourseAttractionFocus.sprinterFestival);
    });

    test('Dynamic appearance fee drops when course fits rider archetype', () {
      final catalog = StarRiderAppearanceFeeNegotiator.createDefaultCatalog();
      final gcStar = catalog.firstWhere(
        (r) => r.archetype == StarRiderArchetype.gcContender,
      );
      final base = StarRiderAppearanceFeeNegotiator.createDefaultCourseBlueprint(
        totalStages: 7,
      );

      final mountainCourse = base.applyPreset(
        CourseAttractionFocus.highMountainGcBattle,
      );
      final sprintCourse = base.applyPreset(
        CourseAttractionFocus.sprinterFestival,
      );

      final demandOnMountains = gcStar.calculateDynamicDemandEur(mountainCourse);
      final demandOnFlat = gcStar.calculateDynamicDemandEur(sprintCourse);

      expect(demandOnMountains, lessThan(demandOnFlat));
    });

    test('Negotiation flow: counter-offer, acceptance, walk-away and ledger entry', () {
      final catalog = StarRiderAppearanceFeeNegotiator.createDefaultCatalog();
      final sessions =
          StarRiderAppearanceFeeNegotiator.createInitialSessions(catalog);
      final course = StarRiderAppearanceFeeNegotiator.createDefaultCourseBlueprint();
      final sprinterSession = sessions.firstWhere(
        (s) => s.rider.archetype == StarRiderArchetype.pureSprinter,
      );

      // Lowball offer triggers counter-offer and drops patience
      final lowOffer = AppearanceOfferTerms(
        offeredFeeEur: (sprinterSession.rider.minimumAcceptableFeeEur * 0.5).round(),
      );
      final round1 = negotiator.evaluateOffer(
        session: sprinterSession,
        offer: lowOffer,
        course: course,
        availableBudgetEur: 1000000,
      );
      expect(round1.accepted, isFalse);
      expect(round1.walkedAway, isFalse);
      expect(round1.session.status, AppearanceNegotiationStatus.inNegotiation);
      expect(round1.session.counterOfferFeeEur, isNotNull);
      expect(round1.session.patienceRemaining, lessThan(sprinterSession.patienceRemaining));

      // Accepting counter-offer signs the star
      final fairOffer = AppearanceOfferTerms(
        offeredFeeEur: round1.session.counterOfferFeeEur!,
        includeGuaranteedTvSpotlight: true,
      );
      final round2 = negotiator.evaluateOffer(
        session: round1.session,
        offer: fairOffer,
        course: course,
        availableBudgetEur: 1000000,
      );
      expect(round2.accepted, isTrue);
      expect(round2.session.status, AppearanceNegotiationStatus.signed);
      expect(round2.ledgerCostEur, fairOffer.totalGuaranteedCostEur);

      // Ledger integration with #513
      const ledger = OrganizerBudgetLedger(
        liquidCashEur: 1000000,
        reserveFundEur: 100000,
        annualOperatingOverheadEur: 150000,
        prizePoolCommitmentEur: 250000,
        appearanceFeesAllocatedEur: 400000,
        safetyInfrastructureBudgetEur: 100000,
      );
      final updatedLedger = negotiator.recordSignedFeeInLedger(
        ledger: ledger,
        session: round2.session,
        raceId: course.raceId,
        seasonYear: 2026,
      );
      expect(
        updatedLedger.liquidCashEur,
        1000000 - fairOffer.totalGuaranteedCostEur,
      );
      expect(updatedLedger.recentTransactions.length, 1);
      expect(
        updatedLedger.recentTransactions.first.category,
        OrganizerCashflowCategory.appearanceFee,
      );
    });

    test('State JSON round-trip preserves course and sessions', () {
      final state = StarAppearanceNegotiatorState.initial(
        availableBudgetEur: 950000,
      );
      final restored = StarAppearanceNegotiatorState.fromJson(state.toJson());
      expect(restored.availableBudgetEur, 950000);
      expect(restored.course.raceId, state.course.raceId);
      expect(restored.sessions.length, state.sessions.length);
    });
  });

  group('StarRiderAppearanceFeeNegotiatorPanel — Responsive UI', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      bool isReadOnly = false,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StarRiderAppearanceFeeNegotiatorPanel(
                isReadOnlyOverride: isReadOnly,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('Renders without overflow on 390x844 mobile', (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.textContaining('Negocjacje Gwiazd'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders without overflow on 1024x768 tablet', (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('Projektant Trasy (GC vs Sprinterzy)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders without overflow on 1600x900 desktop and supports readOnly',
        (tester) async {
      await pumpPanelAtSize(
        tester,
        const Size(1600, 900),
        isReadOnly: true,
      );
      expect(find.text('Tylko Odczyt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
