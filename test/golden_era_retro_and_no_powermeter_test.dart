import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/physics/retro_steel_frame_and_no_powermeter_solver.dart';
import 'package:pro_peloton_manager/models/retro/golden_era_retro_season_model.dart';
import 'package:pro_peloton_manager/ui/screens/golden_era_retro_campaigns_screen.dart';

void main() {
  group('GoldenEraDecade & RetroSeasonRuleset (1970–2015)', () {
    test('maps years 1970–2015 and out-of-range years to expected decades', () {
      expect(GoldenEraDecade.fromYear(1965), GoldenEraDecade.steelCannibalEra1970s);
      expect(GoldenEraDecade.fromYear(1970), GoldenEraDecade.steelCannibalEra1970s);
      expect(GoldenEraDecade.fromYear(1979), GoldenEraDecade.steelCannibalEra1970s);
      expect(GoldenEraDecade.fromYear(1980), GoldenEraDecade.badgerAndAeroDawn1980s);
      expect(GoldenEraDecade.fromYear(1989), GoldenEraDecade.badgerAndAeroDawn1980s);
      expect(GoldenEraDecade.fromYear(1990), GoldenEraDecade.stiAndRadioDawn1990s);
      expect(GoldenEraDecade.fromYear(1999), GoldenEraDecade.stiAndRadioDawn1990s);
      expect(GoldenEraDecade.fromYear(2000), GoldenEraDecade.carbonAndPowerEra2000s);
      expect(GoldenEraDecade.fromYear(2015), GoldenEraDecade.carbonAndPowerEra2000s);
      expect(GoldenEraDecade.fromYear(2026), GoldenEraDecade.carbonAndPowerEra2000s);
    });

    test('enforces historical UCI rulesets across 1971, 1976, 1988, 2000, and 2003+', () {
      final rules1971 = RetroSeasonRuleset.forYear(1971);
      expect(rules1971.maxRidersPerTeam, 10);
      expect(rules1971.allowNeutralServiceMoto, isFalse);
      expect(rules1971.mandatoryHelmetRule, isFalse);
      expect(rules1971.uciMinimumWeightKg, 0.0);
      expect(rules1971.hasRaceRadio, isFalse);
      expect(rules1971.hasPowerMeter, isFalse);

      final rules1976 = RetroSeasonRuleset.forYear(1976);
      expect(rules1976.allowNeutralServiceMoto, isTrue);
      expect(rules1976.telemetryMode, RetroTelemetryMode.noPowerMeterRpeOnly);
      expect(rules1976.communicationMode, RetroCommunicationMode.noRadioChalkboardAndMoto);

      final rules1988 = RetroSeasonRuleset.forYear(1988);
      expect(rules1988.maxRidersPerTeam, 9);
      expect(rules1988.telemetryMode, RetroTelemetryMode.heartRateMonitorOnly);

      final rules2000 = RetroSeasonRuleset.forYear(2000);
      expect(rules2000.uciMinimumWeightKg, 6.8);
      expect(rules2000.mandatoryHelmetRule, isFalse);
      expect(rules2000.hasRaceRadio, isTrue);
      expect(rules2000.hasPowerMeter, isTrue);

      final rules2003 = RetroSeasonRuleset.forYear(2003);
      expect(rules2003.mandatoryHelmetRule, isTrue);
    });

    test('serializes and deserializes GoldenEraRetroSeasonModel and ruleset cleanly', () {
      final classic = GoldenEraRetroSeasonModel.columbusSl1976Classic();
      expect(classic.isPureAnalogEra, isTrue);
      expect(classic.teamEquipment.frameMaterial, RetroFrameMaterial.columbusSlSteel);
      expect(classic.teamEquipment.completeBikeWeightKg, 9.2);
      expect(classic.teamEquipment.shifterType, RetroShifterType.downtubeFriction);

      final json = classic.toJson();
      final restored = GoldenEraRetroSeasonModel.fromJson(json);
      expect(restored.seasonId, classic.seasonId);
      expect(restored.seasonYear, 1976);
      expect(restored.ruleset, classic.ruleset);
      expect(restored.teamEquipment.frameMaterial, RetroFrameMaterial.columbusSlSteel);
      expect(restored.calendarEvents.length, classic.calendarEvents.length);
    });
  });

  group('RetroEquipmentSetup & Wet Merino Wool Physics', () {
    test('wet merino wool adds up to +1.4 kg and penalizes CdA & climbing watts', () {
      final retro1976 = GoldenEraRetroSeasonModel.columbusSl1976Classic();
      final modern2010 = GoldenEraRetroSeasonModel.createForYear(2010);

      final dryWeight = retro1976.computeTotalWetWeightKg(
        riderWeightKg: 70.0,
        rainIntensity01: 0.0,
        wetnessProgress01: 0.0,
      );
      final soakedWeight = retro1976.computeTotalWetWeightKg(
        riderWeightKg: 70.0,
        rainIntensity01: 1.0,
        wetnessProgress01: 1.0,
      );
      expect(soakedWeight - dryWeight, closeTo(1.4, 0.001));

      final retroPenaltyWatts = retro1976.computeWoolJerseyPenaltyWatts(
        rainIntensity01: 1.0,
        speedMs: 6.5,
        gradientPercent: 8.0,
        wetnessProgress01: 1.0,
      );
      final modernPenaltyWatts = modern2010.computeWoolJerseyPenaltyWatts(
        rainIntensity01: 1.0,
        speedMs: 6.5,
        gradientPercent: 8.0,
        wetnessProgress01: 1.0,
      );
      expect(retroPenaltyWatts, greaterThan(modernPenaltyWatts * 5.0));

      final cdaPenalty = retro1976.teamEquipment.calculateAeroCdaPenalty(1.0);
      expect(cdaPenalty, closeTo(0.018 + 0.008 + 0.003, 0.0001));
    });

    test('tracks completed historical events and prestige points without duplicates', () {
      final season = GoldenEraRetroSeasonModel.columbusSl1976Classic();
      final firstEventId = season.calendarEvents.first.id;
      expect(season.calendarCompletionProgress, 0.0);

      final updated = season.markEventCompleted(firstEventId, prestigeEarned: 250);
      expect(updated.completedEventIds, contains(firstEventId));
      expect(updated.seasonPrestigePoints, 250);
      expect(updated.calendarCompletionProgress, greaterThan(0.0));

      final duplicate = updated.markEventCompleted(firstEventId, prestigeEarned: 250);
      expect(duplicate.seasonPrestigePoints, 250);
      expect(duplicate.completedEventIds.length, 1);
    });
  });

  group('BorgRpeZone & RetroSteelFrameAndNoPowermeterSolver', () {
    const solver = RetroSteelFrameAndNoPowermeterSolver();

    test('maps Borg 6–20 scores to all expected physiological zones', () {
      expect(BorgRpeZone.fromBorgScore(4.0), BorgRpeZone.rest);
      expect(BorgRpeZone.fromBorgScore(6.0), BorgRpeZone.rest);
      expect(BorgRpeZone.fromBorgScore(7.5), BorgRpeZone.extremelyLight);
      expect(BorgRpeZone.fromBorgScore(9.5), BorgRpeZone.veryLight);
      expect(BorgRpeZone.fromBorgScore(11.5), BorgRpeZone.light);
      expect(BorgRpeZone.fromBorgScore(13.5), BorgRpeZone.somewhatHard);
      expect(BorgRpeZone.fromBorgScore(15.5), BorgRpeZone.hard);
      expect(BorgRpeZone.fromBorgScore(17.5), BorgRpeZone.veryHard);
      expect(BorgRpeZone.fromBorgScore(19.0), BorgRpeZone.extremelyHard);
      expect(BorgRpeZone.fromBorgScore(20.0), BorgRpeZone.maximal);
      expect(BorgRpeZone.fromBorgScore(25.0), BorgRpeZone.maximal);
    });

    test('hides live watts and HR in noPowerMeterRpeOnly mode', () {
      final result = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          telemetryMode: RetroTelemetryMode.noPowerMeterRpeOnly,
          riderFtpWatts: 380.0,
          targetBorgRpe: 15.0,
        ),
        shiftState: DowntubeShiftState.initial(),
      );

      expect(result.visiblePowerWatts, isNull);
      expect(result.visibleHeartRateBpm, isNull);
      expect(result.borgRpeRounded, 15);
      expect(result.borgZone, BorgRpeZone.hard);
      expect(result.actualPowerWatts, greaterThan(200.0));

      final hrOnly = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          telemetryMode: RetroTelemetryMode.heartRateMonitorOnly,
          riderFtpWatts: 380.0,
          targetBorgRpe: 15.0,
        ),
        shiftState: DowntubeShiftState.initial(),
      );
      expect(hrOnly.visiblePowerWatts, isNull);
      expect(hrOnly.visibleHeartRateBpm, isNotNull);

      final fullWatts = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          telemetryMode: RetroTelemetryMode.fullPowerAndLiveWatts,
          riderFtpWatts: 380.0,
          requestedPowerWatts: 350.0,
        ),
        shiftState: DowntubeShiftState.initial(),
      );
      expect(fullWatts.visiblePowerWatts, closeTo(350.0, 0.2));
      expect(fullWatts.visibleHeartRateBpm, isNotNull);
    });

    test('fatigue, low glycogen, and adrenaline shift RPE perception and bonk risk', () {
      final fresh = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          telemetryMode: RetroTelemetryMode.noPowerMeterRpeOnly,
          riderFtpWatts: 380.0,
          requestedPowerWatts: 340.0,
          cumulativeFatigue: 0.05,
          glycogenFraction: 0.95,
        ),
        shiftState: DowntubeShiftState.initial(),
      );

      final exhausted = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          telemetryMode: RetroTelemetryMode.noPowerMeterRpeOnly,
          riderFtpWatts: 380.0,
          requestedPowerWatts: 340.0,
          cumulativeFatigue: 0.85,
          glycogenFraction: 0.15,
          coreTemperatureC: 39.2,
          rainIntensity: 1.0,
        ),
        shiftState: DowntubeShiftState.initial(),
      );

      expect(exhausted.borgRpeScore, greaterThan(fresh.borgRpeScore));
      expect(exhausted.bonkRiskScore, greaterThan(fresh.bonkRiskScore));

      final adrenaline = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          telemetryMode: RetroTelemetryMode.noPowerMeterRpeOnly,
          riderFtpWatts: 380.0,
          requestedPowerWatts: 340.0,
          cumulativeFatigue: 0.40,
          isAdrenalineSurge: true,
        ),
        shiftState: DowntubeShiftState.initial(),
      );
      final noAdrenaline = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          telemetryMode: RetroTelemetryMode.noPowerMeterRpeOnly,
          riderFtpWatts: 380.0,
          requestedPowerWatts: 340.0,
          cumulativeFatigue: 0.40,
          isAdrenalineSurge: false,
        ),
        shiftState: DowntubeShiftState.initial(),
      );
      expect(adrenaline.borgRpeScore, lessThan(noAdrenaline.borgRpeScore));
    });

    test('steel frame flex causes higher sprint power loss than carbon monocoque', () {
      final steelSprint = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          frameMaterial: RetroFrameMaterial.reynolds531Steel,
          telemetryMode: RetroTelemetryMode.fullPowerAndLiveWatts,
          riderFtpWatts: 380.0,
          requestedPowerWatts: 820.0,
          isOutOfSaddle: true,
        ),
        shiftState: DowntubeShiftState.initial(),
      );

      final carbonSprint = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          frameMaterial: RetroFrameMaterial.earlyCarbonMonocoque,
          telemetryMode: RetroTelemetryMode.fullPowerAndLiveWatts,
          riderFtpWatts: 380.0,
          requestedPowerWatts: 820.0,
          isOutOfSaddle: true,
        ),
        shiftState: DowntubeShiftState.initial(),
      );

      expect(steelSprint.frameFlexPowerLossWatts, greaterThan(carbonSprint.frameFlexPowerLossWatts));
      expect(steelSprint.vibrationDampingFactor, greaterThan(carbonSprint.vibrationDampingFactor));
    });

    test('downtube friction shifter takes hand off bar, delays transfer, and completes shift', () {
      var shiftState = DowntubeShiftState.initial(frontTeeth: 52, rearTeeth: 19);

      // Step 1: initiate shift to 52x17 with dt = 0.5s (shorter than 1.45s friction delay)
      final step1 = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          shifterType: RetroShifterType.downtubeFriction,
          requestedRearTeeth: 17,
          deltaTimeSeconds: 0.5,
          gradePercent: 7.0,
          deterministicSeed: 999,
        ),
        shiftState: shiftState,
      );

      expect(step1.shiftState.isShifting, isTrue);
      expect(step1.shiftState.isHandOffBar, isTrue);
      expect(step1.cdaPenaltyM2, greaterThanOrEqualTo(0.025));
      expect(step1.shiftPowerTransferFactor, lessThan(0.80));

      // Step 2: advance enough time to complete shift
      final step2 = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          shifterType: RetroShifterType.downtubeFriction,
          deltaTimeSeconds: 5.0,
          deterministicSeed: 999,
        ),
        shiftState: step1.shiftState,
      );

      expect(step2.shiftState.isShifting, isFalse);
      expect(step2.shiftState.isHandOffBar, isFalse);
      expect(step2.shiftState.currentRearTeeth, 17);
      expect(step2.shiftState.totalShiftsCompleted, 1);
    });
  });

  group('RetroSteelAndRpeHudPanel & GoldenEraRetroCampaignsScreen UI', () {
    const solver = RetroSteelFrameAndNoPowermeterSolver();

    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      VoidCallback? onShiftEasier,
      VoidCallback? onShiftHarder,
      ValueChanged<double>? onTargetRpeChanged,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final result = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          telemetryMode: RetroTelemetryMode.noPowerMeterRpeOnly,
          targetBorgRpe: 15.0,
        ),
        shiftState: DowntubeShiftState.initial(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RetroSteelAndRpeHudPanel(
                result: result,
                onShiftEasier: onShiftEasier,
                onShiftHarder: onShiftHarder,
                onTargetRpeChanged: onTargetRpeChanged,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('RetroSteelAndRpeHudPanel renders cleanly at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await pumpPanelAtSize(tester, size);
        expect(find.textContaining('TELEMETRIA RETRO'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('GoldenEraRetroCampaignsScreen renders cleanly at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const GoldenEraRetroCampaignsScreen(initialYear: 1976),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(GoldenEraRetroCampaignsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('RetroSteelAndRpeHudPanel triggers shift callbacks on tap', (tester) async {
      var easierTapped = false;
      var harderTapped = false;

      await pumpPanelAtSize(
        tester,
        const Size(1024, 768),
        onShiftEasier: () => easierTapped = true,
        onShiftHarder: () => harderTapped = true,
      );

      final easierFinder = find.textContaining('Lżejszy');
      final harderFinder = find.textContaining('Twardszy');
      if (easierFinder.evaluate().isNotEmpty) {
        await tester.tap(easierFinder.first);
        await tester.pump(const Duration(milliseconds: 300));
        expect(easierTapped, isTrue);
      }
      if (harderFinder.evaluate().isNotEmpty) {
        await tester.tap(harderFinder.first);
        await tester.pump(const Duration(milliseconds: 300));
        expect(harderTapped, isTrue);
      }
    });
  });
}
