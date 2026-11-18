import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/services/career/dynamic_rider_nickname_generator.dart';

void main() {
  const generator = DynamicRiderNicknameGenerator();

  const climberInput = RiderNicknameInput(
    riderId: 'r_climber',
    firstName: 'Tadej',
    lastName: 'Kralj',
    nationalityIso: 'SLO',
    age: 26,
    specialization: RiderSpecialization.pureClimber,
    ftpWatts: 420,
    weightKg: 62.0,
    watts5s: 1120,
    watts20m: 430,
    cobbles: 62,
    descending: 84,
    raceIq: 90,
    rainResistance: 75,
    heatTolerance: 78,
    timeTrialPositioning: 80,
    careerWins: 24,
    monumentWins: 2,
    grandTourStages: 7,
    combativityAwards: 3,
    crashesSurvived: 1,
    breakawayKm: 280,
    fanPopularity: 92,
    mediaHype: 95,
    seasonYear: 2026,
    notableRaceName: 'Tour de France',
    notableLocation: 'Col du Galibier',
  );

  const sprinterInput = RiderNicknameInput(
    riderId: 'r_sprinter',
    firstName: 'Mark',
    lastName: 'Swift',
    nationalityIso: 'GBR',
    age: 28,
    specialization: RiderSpecialization.pureSprinter,
    ftpWatts: 390,
    weightKg: 76.0,
    watts5s: 1680,
    watts20m: 400,
    cobbles: 65,
    descending: 70,
    raceIq: 82,
    rainResistance: 68,
    heatTolerance: 74,
    timeTrialPositioning: 66,
    careerWins: 18,
    monumentWins: 0,
    grandTourStages: 4,
    fanPopularity: 76,
    mediaHype: 74,
    seasonYear: 2026,
    notableRaceName: 'Giro d’Italia',
  );

  group('DynamicRiderNicknameGenerator', () {
    test('ocenia archetyp zgodnie ze specjalizacją i fizjologią', () {
      final climberRanks = generator.evaluateArchetypes(climberInput);
      expect(climberRanks.first.key, NicknameArchetype.mountainGoat);

      final sprinterRanks = generator.evaluateArchetypes(sprinterInput);
      expect(sprinterRanks.first.key, NicknameArchetype.sprintRocket);
    });

    test('wyznacza rzadkość przydomka od local do legendary', () {
      expect(
        generator.evaluateRarityTier(climberInput),
        NicknameRarityTier.legendary,
      );

      const rookie = RiderNicknameInput(
        riderId: 'r_rookie',
        firstName: 'Jan',
        lastName: 'Nowak',
        nationalityIso: 'POL',
        age: 20,
        specialization: RiderSpecialization.domestiqueEngine,
        ftpWatts: 350,
        weightKg: 70,
        watts5s: 1050,
        watts20m: 360,
        cobbles: 55,
        descending: 60,
        raceIq: 58,
        rainResistance: 60,
        heatTolerance: 60,
        timeTrialPositioning: 55,
        fanPopularity: 20,
        mediaHype: 15,
      );
      expect(generator.evaluateRarityTier(rookie), NicknameRarityTier.local);
    });

    test('generuje deterministycznych kandydatów bez duplikatów', () {
      final firstRun = generator.generateCandidates(
        climberInput,
        count: 4,
        seed: 42,
      );
      final secondRun = generator.generateCandidates(
        climberInput,
        count: 4,
        seed: 42,
      );

      expect(firstRun, hasLength(4));
      expect(
        firstRun.map((e) => e.nickname).toList(),
        equals(secondRun.map((e) => e.nickname).toList()),
      );

      final deduped = generator.generateCandidates(
        climberInput,
        count: 4,
        existingNicknames: {firstRun.first.nickname},
        seed: 42,
      );
      expect(
        deduped.any((c) => c.nickname == firstRun.first.nickname),
        isFalse,
      );
      expect(generator.generateCandidates(climberInput, count: 0), isEmpty);
    });

    test('waliduje własne przydomki i odrzuca błędne wartości', () {
      expect(generator.validateCustomNickname('ab').isValid, isFalse);
      expect(generator.validateCustomNickname('a' * 33).isValid, isFalse);
      expect(generator.validateCustomNickname('Król <script>').isValid, isFalse);

      final valid = generator.validateCustomNickname('  El   Tractor  ');
      expect(valid.isValid, isTrue);
      expect(valid.sanitized, 'El Tractor');
    });

    test('serializuje i odtwarza stan archiwum przydomków w JSON', () {
      final notifier = DynamicRiderNicknameNotifier(initialInput: climberInput);
      final candidate = notifier.state.candidates.first;
      final outcome = notifier.adoptCandidate(candidate);
      expect(outcome.success, isTrue);
      expect(outcome.impact.moraleBonus, greaterThan(0));
      expect(outcome.impact.fanMerchandiseMultiplier, greaterThan(1.0));

      final json = notifier.toJson();
      final restored = DynamicRiderNicknameNotifier();
      restored.loadFromJson(json);
      restored.selectRider(climberInput);

      expect(restored.state.activeRiderNicknames, hasLength(1));
      expect(
        restored.state.primaryNickname?.nickname,
        equals(candidate.nickname),
      );
    });
  });

  group('DynamicRiderNicknamePanel responsiveness & interactions', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: DynamicRiderNicknamePanel()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renderuje się bez przepełnień w 390x844, 1024x768 i 1600x900', (
      tester,
    ) async {
      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpPanelAtSize(tester, size);
        expect(tester.takeException(), isNull, reason: 'Overflow at $size');
        expect(find.text('Propozycje Mediów i Kibiców'), findsOneWidget);
        expect(find.text('Historia i Aktywne Przydomki'), findsOneWidget);
      }
    });

    testWidgets('nadaje przydomek kandydata i obsługuje filtry oraz dodawanie', (
      tester,
    ) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));

      final adoptButton = find.text('Nadaj Przydomek').first;
      await tester.tap(adoptButton);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('GŁÓWNY'), findsOneWidget);
      expect(find.text('Koszulka: TAK'), findsOneWidget);

      await tester.tap(find.text('Generuj Nowe'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });
}
