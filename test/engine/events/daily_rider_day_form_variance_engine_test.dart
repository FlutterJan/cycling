import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/events/daily_rider_day_form_variance_engine.dart';
import 'package:pro_peloton_manager/engine/events/race_radio_generator.dart';

void main() {
  group('DailyRiderDayFormVarianceEngine', () {
    test('probability distribution sums to 1.0 across -3..+3 diamonds', () {
      const DailyRiderDayFormInput neutralInput = DailyRiderDayFormInput(
        riderId: 'r1',
        riderName: 'Jan Kowalski',
        trainingStressBalance: 0.0,
        sleepQuality: 0.72,
      );

      final Map<int, double> dist =
          DailyRiderDayFormVarianceEngine.computeProbabilityDistribution(
        neutralInput,
      );

      expect(dist.keys.toSet(), equals({-3, -2, -1, 0, 1, 2, 3}));
      final double sum = dist.values.fold(0.0, (a, b) => a + b);
      expect(sum, closeTo(1.0, 1e-9));
    });

    test('high TSB and high sleep quality strongly shift average towards +2/+3',
        () {
      final DailyRiderDayFormVarianceEngine engine =
          DailyRiderDayFormVarianceEngine(seed: 42);
      const DailyRiderDayFormInput peakInput = DailyRiderDayFormInput(
        riderId: 'r_peak',
        riderName: 'Tadej P.',
        teamName: 'UAE',
        trainingStressBalance: 22.0,
        sleepQuality: 0.96,
        morale: 0.90,
        didWarmup: true,
      );

      const DailyRiderDayFormInput fatiguedInput = DailyRiderDayFormInput(
        riderId: 'r_tired',
        riderName: 'Tired Rider',
        teamName: 'Team B',
        trainingStressBalance: -28.0,
        sleepQuality: 0.32,
        morale: 0.40,
      );

      double peakTotal = 0;
      double fatiguedTotal = 0;
      const int samples = 300;
      for (int i = 0; i < samples; i++) {
        peakTotal += engine.drawInitialDayForm(peakInput).actualDiamonds;
        fatiguedTotal += engine.drawInitialDayForm(fatiguedInput).actualDiamonds;
      }

      final double peakMean = peakTotal / samples;
      final double fatiguedMean = fatiguedTotal / samples;

      expect(peakMean, greaterThan(1.5));
      expect(fatiguedMean, lessThan(-1.5));
      expect(peakMean - fatiguedMean, greaterThan(3.0));
    });

    test('gradual discovery transitions hidden -> sensing -> revealed within 30 km and emits radio once',
        () {
      final DailyRiderDayFormVarianceEngine engine =
          DailyRiderDayFormVarianceEngine(seed: 7);
      const DailyRiderDayFormInput input = DailyRiderDayFormInput(
        riderId: 'r2',
        riderName: 'Michał Kwiatkowski',
        teamName: 'INEOS',
        trainingStressBalance: 10.0,
        sleepQuality: 0.85,
      );

      final RiderDayFormState initial = engine.drawInitialDayForm(input);
      expect(initial.discoveryPhase, equals(DayFormDiscoveryPhase.hidden));
      expect(initial.visibleDiamonds, isNull);
      expect(initial.formattedVisibleScore, equals('?'));
      expect(initial.hasEmittedRadioMessage, isFalse);

      final DayFormDiscoveryStepResult at5Km = engine.stepDiscovery(
        currentState: initial,
        distanceCoveredKm: 5.0,
        elapsedSeconds: 420.0,
      );
      expect(at5Km.state.discoveryPhase, equals(DayFormDiscoveryPhase.hidden));
      expect(at5Km.newlyRevealed, isFalse);
      expect(at5Km.emittedRadioMessage, isNull);

      final DayFormDiscoveryStepResult at12Km = engine.stepDiscovery(
        currentState: at5Km.state,
        distanceCoveredKm: 12.0,
        elapsedSeconds: 1020.0,
      );
      expect(
        at12Km.state.discoveryPhase,
        equals(DayFormDiscoveryPhase.sensing),
      );
      expect(at12Km.newlyRevealed, isFalse);
      expect(at12Km.state.sensingTrend, isNotNull);

      final DayFormDiscoveryStepResult at30Km = engine.stepDiscovery(
        currentState: at12Km.state,
        distanceCoveredKm: 30.0,
        elapsedSeconds: 2550.0,
      );
      expect(at30Km.newlyRevealed, isTrue);
      expect(at30Km.state.isFullyRevealed, isTrue);
      expect(
        at30Km.state.visibleDiamonds,
        equals(initial.actualDiamonds),
      );
      expect(at30Km.emittedRadioMessage, isNotNull);
      expect(
        at30Km.emittedRadioMessage!.channel,
        equals(RadioChannel.directeurSportif),
      );

      // Kolejne kroki po 30 km nie duplikują komunikatu radiowego.
      final DayFormDiscoveryStepResult at45Km = engine.stepDiscovery(
        currentState: at30Km.state,
        distanceCoveredKm: 45.0,
        elapsedSeconds: 3800.0,
      );
      expect(at45Km.newlyRevealed, isFalse);
      expect(at45Km.emittedRadioMessage, isNull);
    });

    test('radio quotes match expected +2 and -2 messages and cover full -3..+3 range',
        () {
      expect(
        DailyRiderDayFormVarianceEngine.radioQuoteForDiamonds(2),
        equals('Czuję dzisiaj niesamowity gaz w nogach! (+2)'),
      );
      expect(
        DailyRiderDayFormVarianceEngine.radioQuoteForDiamonds(-2),
        equals('Mam dziś ciężkie nogi (-2)'),
      );

      for (int s = -3; s <= 3; s++) {
        final RaceRadioMessage msg =
            DailyRiderDayFormVarianceEngine.buildRadioMessageForDayForm(
          riderId: 'id_$s',
          riderName: 'Rider $s',
          teamName: 'Team',
          diamonds: s,
          kilometerMark: 25.0,
          elapsedSeconds: 2100.0,
        );
        expect(msg.message, isNotEmpty);
        expect(msg.channel, equals(RadioChannel.directeurSportif));
      }
    });

    test('modifiers and JSON serialization roundtrip preserve values', () {
      final DayFormPerformanceModifiers plus3 =
          DayFormPerformanceModifiers.fromDiamonds(3);
      final DayFormPerformanceModifiers minus3 =
          DayFormPerformanceModifiers.fromDiamonds(-3);

      expect(plus3.applyToFtp(400), greaterThan(400));
      expect(minus3.applyToFtp(400), lessThan(400));
      expect(plus3.applyToWPrime(20000), greaterThan(20000));

      final DailyRiderDayFormVarianceEngine engine =
          DailyRiderDayFormVarianceEngine(seed: 99);
      final RiderDayFormState drawn = engine.drawInitialDayForm(
        const DailyRiderDayFormInput(
          riderId: 'r_json',
          riderName: 'Rafał Majka',
          teamName: 'UAE',
          trainingStressBalance: 8.0,
          sleepQuality: 0.80,
        ),
      );
      final RiderDayFormState revealed = engine
          .stepDiscovery(
            currentState: drawn,
            distanceCoveredKm: 30.0,
            elapsedSeconds: 2400.0,
          )
          .state;

      final Map<String, dynamic> json = revealed.toJson();
      final RiderDayFormState restored = RiderDayFormState.fromJson(json);

      expect(restored.riderId, equals(revealed.riderId));
      expect(restored.actualDiamonds, equals(revealed.actualDiamonds));
      expect(restored.discoveryPhase, equals(revealed.discoveryPhase));
      expect(restored.radioMessage?.message, equals(revealed.radioMessage?.message));
    });
  });

  group('DailyRiderDayFormVariancePanel widget tests', () {
    List<RiderDayFormState> buildSampleStates() {
      final DailyRiderDayFormVarianceEngine engine =
          DailyRiderDayFormVarianceEngine(seed: 12);
      final List<RiderDayFormState> drawn = engine.drawForRoster(const [
        DailyRiderDayFormInput(
          riderId: 'r1',
          riderName: 'Jan Kowalski',
          teamName: 'Polska Pro',
          trainingStressBalance: 16.0,
          sleepQuality: 0.90,
        ),
        DailyRiderDayFormInput(
          riderId: 'r2',
          riderName: 'Adam Nowak',
          teamName: 'Polska Pro',
          trainingStressBalance: -18.0,
          sleepQuality: 0.45,
        ),
      ]);
      return [
        engine
            .stepDiscovery(
              currentState: drawn[0],
              distanceCoveredKm: 30.0,
              elapsedSeconds: 2400.0,
            )
            .state,
        engine
            .stepDiscovery(
              currentState: drawn[1],
              distanceCoveredKm: 12.0,
              elapsedSeconds: 950.0,
            )
            .state,
      ];
    }

    for (final Size viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'renders cleanly without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
          (WidgetTester tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final List<RiderDayFormState> states = buildSampleStates();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: viewport.width,
                height: viewport.height,
                child: DailyRiderDayFormVariancePanel(
                  initialStates: states,
                  currentDistanceKm: 18.0,
                  onAdvance5Km: () {},
                  onRedrawForm: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Dyspozycja Dnia ("The Legs")'), findsOneWidget);
        expect(find.text('Jan Kowalski'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('supports phase filtering and rider selection',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final List<RiderDayFormState> states = buildSampleStates();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailyRiderDayFormVariancePanel(
              initialStates: states,
              currentDistanceKm: 30.0,
              onAdvance5Km: () {},
              onRedrawForm: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Filtruj po fazie "Pierwsze odczucia" (Adam Nowak)
      await tester.tap(find.text('Pierwsze odczucia (1)'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Adam Nowak'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
