import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/models/career/staff_member.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/services/career/end_of_season_contract_extension_window.dart';

Rider _buildTestRider({
  required String id,
  required String firstName,
  required String lastName,
  required int contractEndYear,
  int monthlySalaryEur = 18000,
  double loyalty = 72.0,
  int ftp = 415,
}) {
  return Rider(
    id: id,
    firstName: firstName,
    lastName: lastName,
    nationalityIso: 'POL',
    birthDate: DateTime(1998, 5, 14),
    potential: 88,
    specialization: RiderSpecialization.gcClimber,
    physiology: RiderPhysiology(
      heightCm: 177.0,
      weightKg: 64.0,
      bodyFatPercentage: 6.2,
      ftpWatts: ftp,
      wPrimeJoules: 24500,
      vo2Max: 84.0,
      maxHr: 192,
      restingHr: 38,
      lactateThresholdHr: 174,
      recoveryRate: 85.0,
      glycogenCapacityGrams: 560.0,
    ),
    powerProfile: const RiderPowerProfile(
      watts5s: 1180,
      watts15s: 950,
      watts30s: 780,
      watts1m: 670,
      watts3m: 520,
      watts5m: 485,
      watts20m: 418,
      watts60m: 380,
    ),
    skills: const RiderSkills(
      cobbles: 64,
      descending: 79,
      bikeHandling: 80,
      aeroPositioning: 80,
      draftingEfficiency: 82,
      raceIq: 83,
      rainResistance: 75,
      heatTolerance: 78,
      timeTrialPositioning: 81,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#E8C3A8',
      hairStyleIndex: 1,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
      glassesModelId: 'oakley_sutro',
      glassesLensColorHex: '#D4AF37',
      helmetModelId: 'aero_pro',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.75,
      bodyBuildType: BodyBuildType.climberLean,
    ),
    contract: RiderContract(
      teamId: 'player_team',
      role: RiderRole.teamLeader,
      monthlySalaryEur: monthlySalaryEur,
      signingBonusEur: 15000,
      winBonusEur: 5000,
      releaseClauseEur: 250000,
      contractEndYear: contractEndYear,
      morale: 82.0,
      leaderLoyalty: loyalty,
      requiredRacesIds: const [],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 88.0,
      chronicTrainingLoad: 95.0,
    ),
    careerPointsUci: 1420,
  );
}

SportsDirector _buildTestDirector({
  required String id,
  required String firstName,
  required String lastName,
  required int contractEndYear,
  int monthlySalaryEur = 12000,
}) {
  return SportsDirector(
    id: id,
    firstName: firstName,
    lastName: lastName,
    nationalityIso: 'BEL',
    age: 46,
    experienceLevel: 85,
    monthlySalaryEur: monthlySalaryEur,
    contractEndYear: contractEndYear,
    reputation: 84,
    convoyCarDrivingSkill: 84,
    tacticalAiInsight: 87,
    preRaceBriefingCharisma: 82,
    radioCommunicationClarity: 86,
  );
}

List<ExpiringContractEntry> _sampleEntries() {
  return [
    ExpiringContractEntry(
      entryId: 'r1',
      kind: ExtensionTargetKind.rider,
      fullName: 'Michał Kowalski',
      nationalityIso: 'POL',
      age: 27,
      roleLabel: 'Lider Zespołu • Lider GC / Góral',
      ratingOrLevel: 86,
      currentMonthlySalaryEur: 25000,
      contractEndYear: 2026,
      morale: 84,
      loyalty: 65,
      stance: NegotiationStance.temptedByRival,
      proposedMonthlySalaryEur: 31000,
      proposedYears: 3,
      proposedSigningBonusEur: 15000,
      rivalOffers: [
        RivalWorldTourPreOffer(
          offerId: 'o1',
          teamId: 'wt_uae',
          teamName: 'UAE Team Emirates XRG',
          teamCountryIso: 'ARE',
          offeredMonthlySalaryEur: 31000,
          offeredYears: 3,
          signingBonusEur: 20000,
          offeredRoleLabel: 'Co-Lider GT',
          urgencyScore: 88,
          submittedDate: DateTime(2026, 9, 4),
          isHeadlineThreat: true,
        ),
      ],
    ),
    const ExpiringContractEntry(
      entryId: 's1',
      kind: ExtensionTargetKind.staff,
      fullName: 'Jan De Vries',
      nationalityIso: 'BEL',
      age: 46,
      roleLabel: 'Dyrektor Sportowy',
      ratingOrLevel: 85,
      currentMonthlySalaryEur: 12000,
      contractEndYear: 2026,
      morale: 88,
      loyalty: 85,
      stance: NegotiationStance.loyalStay,
      proposedMonthlySalaryEur: 13000,
      proposedYears: 2,
      proposedSigningBonusEur: 5000,
    ),
  ];
}

Widget _buildTestApp({
  required Size size,
  required List<ExpiringContractEntry> entries,
  bool isReadOnly = false,
  DateTime? currentDate,
}) {
  return ProviderScope(
    overrides: [
      endOfSeasonExtensionWindowProvider.overrideWith((ref) {
        final notifier = EndOfSeasonExtensionWindowNotifier();
        notifier.loadPrebuilt(
          seasonYear: 2026,
          currentDate: currentDate ?? DateTime(2026, 9, 12),
          entries: entries,
          availableBudgetEur: 1500000,
        );
        return notifier;
      }),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: EndOfSeasonContractExtensionWindowPanel(
              isReadOnly: isReadOnly,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('EndOfSeasonContractExtensionWindow service', () {
    const service = EndOfSeasonContractExtensionWindow();

    test('isSeptemberWindowOpen returns true only in September', () {
      expect(service.isSeptemberWindowOpen(DateTime(2026, 9, 1)), isTrue);
      expect(service.isSeptemberWindowOpen(DateTime(2026, 9, 30)), isTrue);
      expect(service.isSeptemberWindowOpen(DateTime(2026, 8, 31)), isFalse);
      expect(service.isSeptemberWindowOpen(DateTime(2026, 10, 1)), isFalse);
    });

    test('scanExpiringContracts filters expiring riders & staff and creates alerts', () {
      final riders = [
        _buildTestRider(
          id: 'r_exp',
          firstName: 'Adam',
          lastName: 'Nowak',
          contractEndYear: 2026,
        ),
        _buildTestRider(
          id: 'r_safe',
          firstName: 'Piotr',
          lastName: 'Zieliński',
          contractEndYear: 2028,
        ),
      ];
      final staff = [
        _buildTestDirector(
          id: 's_exp',
          firstName: 'Marc',
          lastName: 'Peeters',
          contractEndYear: 2026,
        ),
        _buildTestDirector(
          id: 's_safe',
          firstName: 'Luc',
          lastName: 'Maes',
          contractEndYear: 2027,
        ),
      ];

      final entries = service.scanExpiringContracts(
        seasonYear: 2026,
        riders: riders,
        staff: staff,
        seed: 7,
      );

      expect(entries.length, 2);
      expect(entries.any((e) => e.entryId == 'r_exp'), isTrue);
      expect(entries.any((e) => e.entryId == 's_exp'), isTrue);
      expect(entries.any((e) => e.entryId == 'r_safe'), isFalse);

      final alerts = service.buildAutomaticAlerts(entries);
      for (final alert in alerts) {
        expect(alert.rivalTeamName, isNotEmpty);
        expect(alert.rivalMonthlySalaryEur, greaterThan(0));
      }
    });

    test('evaluateExtensionProposal handles acceptance, counter and budget guard', () {
      final entry = _sampleEntries().first;

      final accepted = service.evaluateExtensionProposal(
        entry: entry,
        offeredMonthlySalaryEur: 31500,
        offeredYears: 3,
        signingBonusEur: 15000,
        availableBudgetEur: 500000,
      );
      expect(accepted.accepted, isTrue);
      expect(accepted.updatedEntry.status, ContractExtensionStatus.extended);
      expect(accepted.updatedEntry.contractEndYear, 2029);

      final countered = service.evaluateExtensionProposal(
        entry: entry,
        offeredMonthlySalaryEur: 27000,
        offeredYears: 2,
        signingBonusEur: 5000,
        availableBudgetEur: 500000,
      );
      expect(countered.countered, isTrue);
      expect(countered.updatedEntry.status, ContractExtensionStatus.negotiating);

      final overBudget = service.evaluateExtensionProposal(
        entry: entry,
        offeredMonthlySalaryEur: 35000,
        offeredYears: 2,
        signingBonusEur: 50000,
        availableBudgetEur: 10000,
      );
      expect(overBudget.valid, isFalse);
    });

    test('JSON round-trip preserves EndOfSeasonExtensionWindowState', () {
      final entries = _sampleEntries();
      final alerts = service.buildAutomaticAlerts(entries);
      final state = EndOfSeasonExtensionWindowState(
        seasonYear: 2026,
        currentDate: DateTime(2026, 9, 15),
        isWindowOpen: true,
        entries: entries,
        alerts: alerts,
        selectedEntryId: 'r1',
        availableBudgetEur: 950000,
      );

      final decoded = EndOfSeasonExtensionWindowState.fromJson(state.toJson());
      expect(decoded.seasonYear, 2026);
      expect(decoded.entries.length, 2);
      expect(decoded.alerts.length, 1);
      expect(decoded.entries.first.rivalOffers.first.teamName,
          'UAE Team Emirates XRG');
    });
  });

  group('EndOfSeasonContractExtensionWindowPanel UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            _buildTestApp(size: size, entries: _sampleEntries()),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(
            find.text('Wrześniowe Okno Przedłużeń Kontraktów'),
            findsOneWidget,
          );
          expect(find.text('Michał Kowalski'), findsAtLeastNWidgets(1));
        },
      );
    }

    testWidgets('matches WorldTour rival offer and updates status', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 840));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(size: const Size(1280, 840), entries: _sampleEntries()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final matchButton = find.text('Wyrównaj Ofertę WorldTour');
      expect(matchButton, findsOneWidget);
      await tester.ensureVisible(matchButton);
      await tester.tap(matchButton);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Przedłużono'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows empty state when no expiring contracts exist', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(size: const Size(1024, 768), entries: const []),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Brak wygasających kontraktów spełniających kryteria'),
        findsOneWidget,
      );
    });
  });
}
