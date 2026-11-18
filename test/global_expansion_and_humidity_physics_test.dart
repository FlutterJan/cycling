import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/physics/tropical_humidity_and_desert_sandstorm_solver.dart';
import 'package:pro_peloton_manager/models/race/global_exotic_tours_expansion_model.dart';

void main() {
  group('GlobalExoticToursExpansionModel — Rwanda, Malezja, Oman', () {
    test('domyślny katalog zawiera Tour du Rwanda, Tour de Langkawi i Tour of Oman', () {
      final model = GlobalExoticToursExpansionModel.initial(seasonYear: 2026);

      final rwanda = model.tourById(ExoticTourId.tourDuRwanda);
      final langkawi = model.tourById(ExoticTourId.tourDeLangkawi);
      final oman = model.tourById(ExoticTourId.tourOfOman);

      expect(rwanda, isNotNull);
      expect(rwanda!.countryName, 'Rwanda');
      expect(rwanda.region, ExoticMarketRegion.eastAfrica);
      expect(rwanda.uciCode, '2.1');
      expect(rwanda.logistics.baseAltitudeMeters, greaterThanOrEqualTo(1500.0));
      expect(rwanda.stageTemplates, hasLength(4));

      expect(langkawi, isNotNull);
      expect(langkawi!.countryName, 'Malaysia');
      expect(langkawi.region, ExoticMarketRegion.southeastAsia);
      expect(langkawi.uciCode, '2.Pro');
      expect(langkawi.logistics.avgHumidityPercent, greaterThanOrEqualTo(85.0));
      expect(
        langkawi.stageTemplates.any(
          (s) => s.signatureFeature == ExoticStageSignatureFeature.gentingHighlandsHc,
        ),
        isTrue,
      );

      expect(oman, isNotNull);
      expect(oman!.countryName, 'Oman');
      expect(oman.region, ExoticMarketRegion.arabianPeninsula);
      expect(oman.uciCode, '2.Pro');
      expect(
        oman.climateChallenge,
        ExoticClimateChallenge.desertHeatAndCoastalCrosswinds,
      );
    });

    test('filtrowanie po regionie i miesiącu oraz generowanie TourRace do kalendarza', () {
      final model = GlobalExoticToursExpansionModel.initial(seasonYear: 2026);

      final arabianTours = model.toursByRegion(ExoticMarketRegion.arabianPeninsula);
      expect(arabianTours.map((t) => t.tourId), contains(ExoticTourId.tourOfOman));

      final februaryTours = model.toursForMonth(2);
      expect(februaryTours.map((t) => t.tourId), contains(ExoticTourId.tourDuRwanda));

      final calendarRaces = model.buildCalendarTourRaces(
        participatingTeamIds: const ['team_alpha', 'team_beta'],
      );
      expect(calendarRaces, hasLength(model.tours.length));
      for (final race in calendarRaces) {
        expect(race.stages, isNotEmpty);
        expect(race.participatingTeamIds, containsAll(['team_alpha', 'team_beta']));
      }
    });

    test('aklimatyzacja redukuje karę wydolnościową i poprawia gotowość w Rwandzie i Malezji', () {
      final model = GlobalExoticToursExpansionModel.initial();

      final rwandaUnprepared = model.evaluateTourParticipation(
        tourId: ExoticTourId.tourDuRwanda,
        daysAcclimatized: 0,
        protocol: AcclimatizationProtocolType.none,
      );
      final rwandaPrepared = model.evaluateTourParticipation(
        tourId: ExoticTourId.tourDuRwanda,
        daysAcclimatized: 5,
        protocol: AcclimatizationProtocolType.altitudeCamp,
        expectedGcFinishRank: 1,
      );

      expect(rwandaPrepared.readinessScore, greaterThan(rwandaUnprepared.readinessScore));
      expect(rwandaPrepared.readinessScore, closeTo(1.0, 0.001));
      expect(
        rwandaPrepared.performancePenaltyPercent,
        lessThan(rwandaUnprepared.performancePenaltyPercent),
      );
      expect(rwandaPrepared.projectedUciPoints, greaterThan(rwandaUnprepared.projectedUciPoints));
      expect(rwandaPrepared.isFinanciallyViable, isTrue);

      final langkawiPrepared = model.evaluateTourParticipation(
        tourId: ExoticTourId.tourDeLangkawi,
        daysAcclimatized: 6,
        protocol: AcclimatizationProtocolType.combinedJetLagAndHeat,
        expectedGcFinishRank: 2,
      );
      expect(langkawiPrepared.readinessScore, closeTo(1.0, 0.001));
      expect(langkawiPrepared.projectedFanGrowth, greaterThan(30000));
    });

    test('awans prestiżu wyścigu do WorldTour (2.UWT), zapis udziału oraz serializacja JSON', () {
      var model = GlobalExoticToursExpansionModel.initial(seasonYear: 2027);

      // Tour of Oman: establishedProSeries -> worldTourCandidate -> promotedWorldTour (2.UWT)
      model = model.promoteTourTier(ExoticTourId.tourOfOman);
      expect(
        model.tourById(ExoticTourId.tourOfOman)!.expansionTier,
        ExoticExpansionTier.worldTourCandidate,
      );
      model = model.promoteTourTier(ExoticTourId.tourOfOman);
      final promotedOman = model.tourById(ExoticTourId.tourOfOman)!;
      expect(promotedOman.expansionTier, ExoticExpansionTier.promotedWorldTour);
      expect(promotedOman.uciCode, '2.UWT');
      expect(model.promotedTourIds, contains(ExoticTourId.tourOfOman));

      model = model.recordParticipation(
        const TeamExoticTourParticipationRecord(
          tourId: ExoticTourId.tourDuRwanda,
          seasonYear: 2027,
          daysAcclimatized: 5,
          protocol: AcclimatizationProtocolType.altitudeCamp,
          bestGcRank: 2,
          stageWins: 2,
          uciPointsEarned: 95,
          netFinancialBalanceEur: 18500,
          fansGained: 14000,
        ),
      );
      expect(model.participationHistory, hasLength(1));
      expect(model.nonEuropeanFanBase, 12000 + 14000);
      expect(model.globalExpansionReputation, greaterThan(25.0));

      final restored = GlobalExoticToursExpansionModel.fromJson(model.toJson());
      expect(restored.seasonYear, model.seasonYear);
      expect(restored.tours.length, model.tours.length);
      expect(restored.promotedTourIds, model.promotedTourIds);
      expect(restored.participationHistory.length, model.participationHistory.length);
      expect(restored.nonEuropeanFanBase, model.nonEuropeanFanBase);
    });
  });

  group('TropicalHumidityAndDesertSandstormSolver — wilgotność 95% RH i piasek', () {
    test('wilgotność 95% RH drastycznie obniża parowanie potu i moc względem 40% RH', () {
      const dryHotInput = TropicalAndDesertClimateInput(
        temperatureCelsius: 33.5,
        relativeHumidityPercent: 40.0,
        altitudeMeters: 45.0,
        isRoadWet: false,
        riderPowerWatts: 320.0,
        heatAcclimatizationLevel: 0.25,
      );
      final humid95Input = dryHotInput.copyWith(relativeHumidityPercent: 95.0);

      final dryRes = TropicalHumidityAndDesertSandstormSolver.solve(dryHotInput);
      final humidRes = TropicalHumidityAndDesertSandstormSolver.solve(humid95Input);

      expect(
        humidRes.sweatEvaporationEfficiency,
        lessThan(dryRes.sweatEvaporationEfficiency),
      );
      expect(humidRes.sweatEvaporationEfficiency, lessThan(0.35));
      expect(humidRes.wbgtCelsius, greaterThan(dryRes.wbgtCelsius));
      expect(humidRes.sweatRateLitersPerHour, greaterThan(dryRes.sweatRateLitersPerHour));
      expect(
        humidRes.coreTempDriftCelsiusPerHour,
        greaterThan(dryRes.coreTempDriftCelsiusPerHour),
      );
      expect(
        humidRes.thermalPowerPenaltyFraction,
        greaterThan(dryRes.thermalPowerPenaltyFraction),
      );
      expect(
        humidRes.effectiveRiderPowerWatts,
        lessThan(dryRes.effectiveRiderPowerWatts),
      );
    });

    test('gęstość powietrza maleje wraz z wysokością (Rwanda 1550 m vs Langkawi 45 m) oraz wilgotnością', () {
      final drySeaLevel = TropicalHumidityAndDesertSandstormSolver.computeMoistAndDustyAirDensity(
        temperatureCelsius: 33.5,
        relativeHumidityPercent: 20.0,
        altitudeMeters: 45.0,
      );
      final humid95SeaLevel =
          TropicalHumidityAndDesertSandstormSolver.computeMoistAndDustyAirDensity(
        temperatureCelsius: 33.5,
        relativeHumidityPercent: 95.0,
        altitudeMeters: 45.0,
      );
      final rwandaHighland =
          TropicalHumidityAndDesertSandstormSolver.computeMoistAndDustyAirDensity(
        temperatureCelsius: 24.5,
        relativeHumidityPercent: 88.0,
        altitudeMeters: 1550.0,
      );

      // Para wodna ma mniejszą masę molową niż suche powietrze -> 95% RH ma nieco niższą gęstość
      expect(humid95SeaLevel, lessThan(drySeaLevel));
      // Wysokość 1550 m w Rwandzie wyraźnie obniża gęstość powietrza względem poziomu morza
      expect(rwandaHighland, lessThan(humid95SeaLevel * 0.90));
    });

    test('aklimatyzacja cieplno-wilgotnościowa redukuje dryf temperatury głębokiej i spadek mocy przy 95% RH', () {
      const unacclimatized = TropicalAndDesertClimateInput(
        temperatureCelsius: 33.5,
        relativeHumidityPercent: 95.0,
        heatAcclimatizationLevel: 0.0,
      );
      final acclimatized = unacclimatized.copyWith(heatAcclimatizationLevel: 0.90);

      final unaccRes = TropicalHumidityAndDesertSandstormSolver.solve(unacclimatized);
      final accRes = TropicalHumidityAndDesertSandstormSolver.solve(acclimatized);

      expect(
        accRes.coreTempDriftCelsiusPerHour,
        lessThan(unaccRes.coreTempDriftCelsiusPerHour),
      );
      expect(
        accRes.thermalPowerPenaltyFraction,
        lessThan(unaccRes.thermalPowerPenaltyFraction),
      );
      expect(
        accRes.effectiveRiderPowerWatts,
        greaterThan(unaccRes.effectiveRiderPowerWatts),
      );
    });

    test('pustynny piasek w Omanie podnosi Crr, a wosk na łańcuchu i szersza opona ograniczają straty', () {
      final cleanCrr = TropicalHumidityAndDesertSandstormSolver.computeEffectiveCrr(
        baseTireCrr: 0.0032,
        sandCondition: DesertSandCondition.cleanAsphalt,
        tireWidthMm: 28.0,
        isRoadWet: false,
      );
      final narrowSandCrr = TropicalHumidityAndDesertSandstormSolver.computeEffectiveCrr(
        baseTireCrr: 0.0032,
        sandCondition: DesertSandCondition.heavySandSheet,
        tireWidthMm: 25.0,
        isRoadWet: false,
      );
      final wideSandCrr = TropicalHumidityAndDesertSandstormSolver.computeEffectiveCrr(
        baseTireCrr: 0.0032,
        sandCondition: DesertSandCondition.heavySandSheet,
        tireWidthMm: 34.0,
        isRoadWet: false,
      );
      final wetMonsoonCrr = TropicalHumidityAndDesertSandstormSolver.computeEffectiveCrr(
        baseTireCrr: 0.0032,
        sandCondition: DesertSandCondition.cleanAsphalt,
        tireWidthMm: 28.0,
        isRoadWet: true,
      );

      expect(narrowSandCrr, greaterThan(cleanCrr * 1.8));
      expect(wideSandCrr, lessThan(narrowSandCrr));
      expect(wetMonsoonCrr, closeTo(cleanCrr * 1.12, 1e-6));

      final waxedSandEff = TropicalHumidityAndDesertSandstormSolver.computeDrivetrainEfficiency(
        sandCondition: DesertSandCondition.activeSandstorm,
        isChainWaxed: true,
        isRoadWet: true,
      );
      final oiledSandEff = TropicalHumidityAndDesertSandstormSolver.computeDrivetrainEfficiency(
        sandCondition: DesertSandCondition.activeSandstorm,
        isChainWaxed: false,
        isRoadWet: true,
      );
      expect(waxedSandEff, greaterThan(oiledSandEff));
    });

    test('progresja etapu w 95% RH oraz porównanie wariantów opon 25/28/32 mm i smarowania', () {
      const langkawiInput = TropicalAndDesertClimateInput(
        temperatureCelsius: 33.5,
        relativeHumidityPercent: 95.0,
        altitudeMeters: 45.0,
        sandCondition: DesertSandCondition.cleanAsphalt,
        isRoadWet: true,
        riderPowerWatts: 310.0,
        heatAcclimatizationLevel: 0.25,
      );

      final segments = TropicalHumidityAndDesertSandstormSolver.simulateStageProgression(
        baseInput: langkawiInput,
        totalDistanceKm: 160.0,
        segmentCount: 5,
        fluidIntakeLitersPerHour: 0.75,
      );

      expect(segments, hasLength(5));
      expect(segments.last.distanceKm, closeTo(160.0, 0.01));
      expect(
        segments.last.cumulativeCoreTempC,
        greaterThan(segments.first.cumulativeCoreTempC),
      );
      expect(
        segments.last.cumulativeDehydrationPercent,
        greaterThan(segments.first.cumulativeDehydrationPercent),
      );

      final setups = TropicalHumidityAndDesertSandstormSolver.compareTireAndLubeSetups(
        langkawiInput.copyWith(sandCondition: DesertSandCondition.sandDrifts),
      );
      expect(setups, hasLength(6));
      expect(setups.where((s) => s.deltaSecondsOver40Km == 0.0), hasLength(1));
      expect(setups.every((s) => s.deltaSecondsOver40Km >= 0.0), isTrue);
    });
  });

  group('TropicalHumidityAndDesertSandstormPanel — responsywność i interakcje UI', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      ValueChanged<TropicalAndDesertClimateResult>? onResultChanged,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: TropicalHumidityAndDesertSandstormPanel(
                initialPreset: ExoticClimatePreset.langkawiTropical95,
                onResultChanged: onResultChanged,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final viewport in <Size>[
      const Size(390, 844),
      const Size(1024, 768),
      const Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje panel bez przepełnień w rozdzielczości ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          await pumpPanelAtSize(tester, viewport);

          expect(find.text('Langkawi Monsun 95% RH'), findsOneWidget);
          expect(find.text('Rwanda Wyżyna Tropikalna'), findsOneWidget);
          expect(find.text('Oman Pustynny Wiatr'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('przełączanie presetów Rwanda/Oman i przełączników sprzętu aktualizuje telemetrię', (tester) async {
      TropicalAndDesertClimateResult? latestResult;
      await pumpPanelAtSize(
        tester,
        const Size(1024, 768),
        onResultChanged: (res) => latestResult = res,
      );

      await tester.tap(find.text('Rwanda Wyżyna Tropikalna'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(latestResult, isNotNull);
      final rwandaDensity = latestResult!.effectiveAirDensityKgM3;

      await tester.tap(find.text('Oman Pustynny Wiatr'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(latestResult!.effectiveAirDensityKgM3, greaterThan(rwandaDensity));
      expect(latestResult!.deltaCrr, greaterThan(0.0));
      expect(tester.takeException(), isNull);
    });
  });
}
