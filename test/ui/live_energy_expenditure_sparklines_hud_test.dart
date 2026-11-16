import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/widgets/live_energy_expenditure_sparklines_hud.dart';

List<EnergyExpenditureSample> _build60sSamples({
  required double basePower,
  required int baseHr,
  required double baseKcalPerHour,
}) {
  return List<EnergyExpenditureSample>.generate(60, (int i) {
    final double wave = (i % 10) * 4.0 - 18.0;
    return EnergyExpenditureSample(
      timestampSeconds: i + 1,
      powerWatts: basePower + wave,
      heartRateBpm: baseHr + (i % 5) - 2,
      glycogenBurnKcalPerHour: baseKcalPerHour + wave * 1.5,
    );
  });
}

List<RiderEnergyTelemetryData> _build8Riders() {
  return <RiderEnergyTelemetryData>[
    RiderEnergyTelemetryData(
      riderId: 'r1',
      riderName: 'T. POGAČAR',
      roleTag: 'LDR',
      bibNumber: 1,
      ftpWatts: 415,
      maxHeartRateBpm: 196,
      currentPowerWatts: 410,
      currentHeartRateBpm: 174,
      currentSpeedKmh: 40.0,
      currentDistanceKm: 120.0,
      stageTotalKm: 195.0,
      glycogenRemainingGrams: 310.0,
      maxGlycogenGrams: 620.0,
      glycogenBurnKcalPerHour: 800.0, // 200 g/h -> (310-50)/200*40 = 52 km -> km 172
      last60SecondsSamples: _build60sSamples(
        basePower: 410,
        baseHr: 174,
        baseKcalPerHour: 800,
      ),
    ),
    RiderEnergyTelemetryData(
      riderId: 'r2',
      riderName: 'J. ALMEIDA',
      roleTag: 'DOM',
      bibNumber: 2,
      ftpWatts: 390,
      maxHeartRateBpm: 192,
      currentPowerWatts: 350,
      currentHeartRateBpm: 162,
      currentSpeedKmh: 40.0,
      currentDistanceKm: 120.0,
      stageTotalKm: 195.0,
      glycogenRemainingGrams: 460.0,
      maxGlycogenGrams: 580.0,
      glycogenBurnKcalPerHour: 640.0,
      last60SecondsSamples: _build60sSamples(
        basePower: 350,
        baseHr: 162,
        baseKcalPerHour: 640,
      ),
    ),
    RiderEnergyTelemetryData(
      riderId: 'r3',
      riderName: 'A. YATES',
      roleTag: 'CLM',
      bibNumber: 3,
      ftpWatts: 385,
      maxHeartRateBpm: 190,
      currentPowerWatts: 375,
      currentHeartRateBpm: 168,
      currentSpeedKmh: 40.0,
      currentDistanceKm: 120.0,
      stageTotalKm: 195.0,
      glycogenRemainingGrams: 180.0,
      maxGlycogenGrams: 550.0,
      glycogenBurnKcalPerHour: 760.0,
      last60SecondsSamples: _build60sSamples(
        basePower: 375,
        baseHr: 168,
        baseKcalPerHour: 760,
      ),
    ),
    RiderEnergyTelemetryData(
      riderId: 'r4',
      riderName: 'M. SOLER',
      roleTag: 'DOM',
      bibNumber: 4,
      ftpWatts: 380,
      maxHeartRateBpm: 188,
      currentPowerWatts: 290,
      currentHeartRateBpm: 148,
      currentSpeedKmh: 40.0,
      currentDistanceKm: 120.0,
      stageTotalKm: 195.0,
      glycogenRemainingGrams: 490.0,
      maxGlycogenGrams: 600.0,
      glycogenBurnKcalPerHour: 520.0,
      last60SecondsSamples: _build60sSamples(
        basePower: 290,
        baseHr: 148,
        baseKcalPerHour: 520,
      ),
    ),
    RiderEnergyTelemetryData(
      riderId: 'r5',
      riderName: 'P. SIVAKOV',
      roleTag: 'DOM',
      bibNumber: 5,
      ftpWatts: 395,
      maxHeartRateBpm: 191,
      currentPowerWatts: 325,
      currentHeartRateBpm: 155,
      currentSpeedKmh: 40.0,
      currentDistanceKm: 120.0,
      stageTotalKm: 195.0,
      glycogenRemainingGrams: 430.0,
      maxGlycogenGrams: 590.0,
      glycogenBurnKcalPerHour: 600.0,
      last60SecondsSamples: _build60sSamples(
        basePower: 325,
        baseHr: 155,
        baseKcalPerHour: 600,
      ),
    ),
    RiderEnergyTelemetryData(
      riderId: 'r6',
      riderName: 'N. POLITT',
      roleTag: 'ROL',
      bibNumber: 6,
      ftpWatts: 425,
      maxHeartRateBpm: 186,
      currentPowerWatts: 380,
      currentHeartRateBpm: 159,
      currentSpeedKmh: 40.0,
      currentDistanceKm: 120.0,
      stageTotalKm: 195.0,
      glycogenRemainingGrams: 520.0,
      maxGlycogenGrams: 640.0,
      glycogenBurnKcalPerHour: 710.0,
      last60SecondsSamples: _build60sSamples(
        basePower: 380,
        baseHr: 159,
        baseKcalPerHour: 710,
      ),
    ),
    RiderEnergyTelemetryData(
      riderId: 'r7',
      riderName: 'T. WELLENS',
      roleTag: 'PUN',
      bibNumber: 7,
      ftpWatts: 390,
      maxHeartRateBpm: 193,
      currentPowerWatts: 310,
      currentHeartRateBpm: 151,
      currentSpeedKmh: 40.0,
      currentDistanceKm: 120.0,
      stageTotalKm: 195.0,
      glycogenRemainingGrams: 440.0,
      maxGlycogenGrams: 580.0,
      glycogenBurnKcalPerHour: 580.0,
      last60SecondsSamples: _build60sSamples(
        basePower: 310,
        baseHr: 151,
        baseKcalPerHour: 580,
      ),
    ),
    const RiderEnergyTelemetryData(
      riderId: 'r8',
      riderName: 'J. AYUSO',
      roleTag: 'GC2',
      bibNumber: 8,
      ftpWatts: 405,
      maxHeartRateBpm: 195,
      currentPowerWatts: 0,
      currentHeartRateBpm: 0,
      currentSpeedKmh: 0.0,
      currentDistanceKm: 120.0,
      stageTotalKm: 195.0,
      glycogenRemainingGrams: 400.0,
      maxGlycogenGrams: 590.0,
      glycogenBurnKcalPerHour: 0.0,
      isDisabled: true,
      last60SecondsSamples: <EnergyExpenditureSample>[],
    ),
  ];
}

void main() {
  group('BonkPredictionCalculator', () {
    test('predicts exact bonk kilometer ("Bonk Warning at km 172")', () {
      final BonkPredictionResult result = BonkPredictionCalculator.predict(
        currentDistanceKm: 120.0,
        stageTotalKm: 195.0,
        currentSpeedKmh: 40.0,
        glycogenRemainingGrams: 310.0,
        glycogenBurnKcalPerHour: 800.0,
      );

      expect(result.isAlreadyBonked, isFalse);
      expect(result.willBonkBeforeFinish, isTrue);
      expect(result.predictedBonkKm, closeTo(172.0, 0.01));
      expect(result.statusLabel, equals('Bonk Warning at km 172'));
    });

    test('reports active bonk when glycogen is at or below threshold', () {
      final BonkPredictionResult result = BonkPredictionCalculator.predict(
        currentDistanceKm: 145.4,
        stageTotalKm: 195.0,
        currentSpeedKmh: 36.0,
        glycogenRemainingGrams: 45.0,
        glycogenBurnKcalPerHour: 700.0,
      );

      expect(result.isAlreadyBonked, isTrue);
      expect(result.isCriticalWarning, isTrue);
      expect(result.statusLabel, equals('Bonk Active at km 145'));
    });

    test('reports safe to finish when predicted bonk exceeds stage distance', () {
      final BonkPredictionResult result = BonkPredictionCalculator.predict(
        currentDistanceKm: 120.0,
        stageTotalKm: 180.0,
        currentSpeedKmh: 42.0,
        glycogenRemainingGrams: 520.0,
        glycogenBurnKcalPerHour: 600.0,
      );

      expect(result.willBonkBeforeFinish, isFalse);
      expect(result.isCriticalWarning, isFalse);
      expect(result.statusLabel, equals('Safe to Finish (180 km)'));
    });
  });

  group('LiveEnergyExpenditureSparklinesHud widget', () {
    testWidgets('renders 8 riders, metrics, Bonk Warning at km 172 and handles interactions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? selectedId;
      String? gelFedId;
      final List<RiderEnergyTelemetryData> riders = _build8Riders();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 1400,
                child: LiveEnergyExpenditureSparklinesHud(
                  riders: riders,
                  selectedRiderId: 'r1',
                  onRiderSelected: (RiderEnergyTelemetryData r) =>
                      selectedId = r.riderId,
                  onFeedGelPressed: (RiderEnergyTelemetryData r) =>
                      gelFedId = r.riderId,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ENERGY & GLYCOGEN HUD'), findsOneWidget);
      expect(find.text('T. POGAČAR'), findsOneWidget);
      expect(find.text('J. AYUSO'), findsOneWidget);
      expect(find.text('Bonk Warning at km 172'), findsOneWidget);
      expect(find.text('410 W'), findsOneWidget);
      expect(find.text('174 BPM'), findsOneWidget);
      expect(find.text('800 kcal/h'), findsOneWidget);
      expect(find.text('TELEMETRY OFFLINE'), findsOneWidget);

      // Select active rider
      await tester.tap(find.text('J. ALMEIDA'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(selectedId, equals('r2'));

      // Disabled rider should not trigger callback
      selectedId = null;
      await tester.tap(find.text('J. AYUSO'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(selectedId, isNull);

      // Feed gel button
      await tester.tap(find.text('GEL').first);
      await tester.pump(const Duration(milliseconds: 200));
      expect(gelFedId, isNotNull);

      // Metric filter chips
      await tester.tap(find.text('BPM'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('KCAL'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('ALL'));
      await tester.pump(const Duration(milliseconds: 200));

      // Sort button
      await tester.tap(find.text('Roster'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Bonk Risk'), findsOneWidget);

      // Collapse and expand
      await tester.tap(find.text('Hide'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Show'), findsOneWidget);
    });

    for (final Size size in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('no RenderFlex overflow at ${size.width.toInt()}x${size.height.toInt()}',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: LiveEnergyExpenditureSparklinesHud(
                  riders: _build8Riders(),
                  enableCriticalPulse: false,
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.text('ENERGY & GLYCOGEN HUD'), findsOneWidget);
      });
    }
  });
}
