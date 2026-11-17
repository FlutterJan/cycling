import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/physics/gravel_rolling_resistance_and_sealant_solver.dart';
import '../../models/equipment/gravel_bike_and_tire_inserts_model.dart';
import '../../models/race/gravel_race_and_surface_model.dart';

/// Filtr rangi wyścigu w kalendarzu UCI Gravel World Series & Ultra-Gravel.
enum GravelCalendarFilter {
  all,
  worldSeries,
  worldChampionships,
  ultraGravel;

  String get labelPl {
    switch (this) {
      case GravelCalendarFilter.all:
        return 'Wszystkie';
      case GravelCalendarFilter.worldSeries:
        return 'World Series';
      case GravelCalendarFilter.worldChampionships:
        return 'MŚ UCI';
      case GravelCalendarFilter.ultraGravel:
        return 'Ultra-Gravel';
    }
  }
}

/// Zakładka mobilna / tabletowa w centrum szutrowym.
enum GravelHubSectionTab {
  calendar,
  tiresConfigurator,
  oasisZones;

  String get labelPl {
    switch (this) {
      case GravelHubSectionTab.calendar:
        return 'Kalendarz';
      case GravelHubSectionTab.tiresConfigurator:
        return 'Opony 40–50 mm';
      case GravelHubSectionTab.oasisZones:
        return 'Strefy Oasis';
    }
  }

  IconData get icon {
    switch (this) {
      case GravelHubSectionTab.calendar:
        return Icons.calendar_month_rounded;
      case GravelHubSectionTab.tiresConfigurator:
        return Icons.tire_repair_rounded;
      case GravelHubSectionTab.oasisZones:
        return Icons.water_drop_rounded;
    }
  }
}

/// Priorytet obsługi w strefie nawadniania i serwisu `Oasis`.
enum GravelOasisServicePriority {
  skipNonStop,
  splashAndDash,
  fullHydrationRefill,
  fullTechAndSealant;

  String get labelPl {
    switch (this) {
      case GravelOasisServicePriority.skipNonStop:
        return 'Pomiń (Non-Stop)';
      case GravelOasisServicePriority.splashAndDash:
        return 'Splash & Dash';
      case GravelOasisServicePriority.fullHydrationRefill:
        return 'Pełne Tankowanie';
      case GravelOasisServicePriority.fullTechAndSealant:
        return 'Serwis Mleczka & CO₂';
    }
  }

  String get shortDescriptionPl {
    switch (this) {
      case GravelOasisServicePriority.skipNonStop:
        return '0 s straty · brak uzupełnienia płynów';
      case GravelOasisServicePriority.splashAndDash:
        return '+18 s · +1000 ml płynów w bidony';
      case GravelOasisServicePriority.fullHydrationRefill:
        return '+42 s · pełny bukłak + bidony + 1 CO₂';
      case GravelOasisServicePriority.fullTechAndSealant:
        return '+68 s · pełne płyny + mleczko + 2 CO₂';
    }
  }

  int get stopDurationSeconds {
    switch (this) {
      case GravelOasisServicePriority.skipNonStop:
        return 0;
      case GravelOasisServicePriority.splashAndDash:
        return 18;
      case GravelOasisServicePriority.fullHydrationRefill:
        return 42;
      case GravelOasisServicePriority.fullTechAndSealant:
        return 68;
    }
  }

  double get addedFluidMl {
    switch (this) {
      case GravelOasisServicePriority.skipNonStop:
        return 0.0;
      case GravelOasisServicePriority.splashAndDash:
        return 1000.0;
      case GravelOasisServicePriority.fullHydrationRefill:
        return 2500.0;
      case GravelOasisServicePriority.fullTechAndSealant:
        return 2500.0;
    }
  }

  int get addedCo2Cartridges {
    switch (this) {
      case GravelOasisServicePriority.skipNonStop:
      case GravelOasisServicePriority.splashAndDash:
        return 0;
      case GravelOasisServicePriority.fullHydrationRefill:
        return 1;
      case GravelOasisServicePriority.fullTechAndSealant:
        return 2;
    }
  }

  double get addedSealantMl =>
      this == GravelOasisServicePriority.fullTechAndSealant ? 60.0 : 0.0;
}

/// Strefa `Oasis` (punkt kontrolny, nawadniania i wsparcia technicznego na trasie szutrowej).
class GravelOasisZoneSpec {
  final String id;
  final String name;
  final double kmMarker;
  final double distanceToNextKm;
  final bool hasWaterResupply;
  final bool hasMechanicalNeutral;
  final bool hasShadeAndIce;
  final double elevationMeters;
  final double ambientTempC;

  const GravelOasisZoneSpec({
    required this.id,
    required this.name,
    required this.kmMarker,
    required this.distanceToNextKm,
    this.hasWaterResupply = true,
    this.hasMechanicalNeutral = false,
    this.hasShadeAndIce = false,
    this.elevationMeters = 450.0,
    this.ambientTempC = 22.0,
  });
}

/// Wynik symulacji bilansu płynów i czasu postoju w pojedynczej strefie `Oasis`.
class GravelOasisZoneEvaluation {
  final GravelOasisZoneSpec zone;
  final GravelOasisServicePriority priority;
  final double arrivalFluidMl;
  final double departureFluidMl;
  final int stopDurationSeconds;
  final bool isCriticalLowOnArrival;

  const GravelOasisZoneEvaluation({
    required this.zone,
    required this.priority,
    required this.arrivalFluidMl,
    required this.departureFluidMl,
    required this.stopDurationSeconds,
    required this.isCriticalLowOnArrival,
  });
}

/// Zbiorcze podsumowanie strategii wszystkich stref `Oasis` w wybranym wyścigu.
class GravelOasisPlanSummary {
  final List<GravelOasisZoneEvaluation> zoneEvaluations;
  final int activeStopCount;
  final int totalStopTimeSeconds;
  final double totalFluidRefilledMl;
  final double minimumFluidMarginMl;
  final double finishRemainingFluidMl;
  final bool hasDehydrationRisk;

  const GravelOasisPlanSummary({
    required this.zoneEvaluations,
    required this.activeStopCount,
    required this.totalStopTimeSeconds,
    required this.totalFluidRefilledMl,
    required this.minimumFluidMarginMl,
    required this.finishRemainingFluidMl,
    required this.hasDehydrationRisk,
  });
}

/// Kalkulator bilansu płynów, autonomii i czasu postojów w strefach `Oasis`.
class GravelOasisPlannerCalculator {
  const GravelOasisPlannerCalculator();

  GravelOasisPlanSummary evaluatePlan({
    required GravelRaceAndSurfaceModel race,
    required List<GravelOasisZoneSpec> oasisZones,
    required Map<String, GravelOasisServicePriority> selectedPriorities,
    required GravelBikeAndTireInsertsModel bikeSetup,
    required double targetSpeedKmh,
  }) {
    final safeSpeedKmh = targetSpeedKmh.clamp(16.0, 42.0);
    final hourlyDemandMl =
        650.0 + ((race.ambientTemperatureC - 18.0).clamp(0.0, 22.0) * 18.0);
    final maxCapacityMl =
        bikeSetup.frameBottlesCapacityMl + bikeSetup.hydrationPack.bladderCapacityMl;
    var currentFluidMl =
        (bikeSetup.currentFrameBottlesFluidMl + bikeSetup.hydrationPack.currentFluidMl)
            .clamp(0.0, maxCapacityMl);

    var previousKm = 0.0;
    var activeStops = 0;
    var totalSeconds = 0;
    var totalRefilledMl = 0.0;
    var minMarginMl = currentFluidMl;
    var hasRisk = false;
    final evaluations = <GravelOasisZoneEvaluation>[];

    final sortedZones = List<GravelOasisZoneSpec>.from(oasisZones)
      ..sort((a, b) => a.kmMarker.compareTo(b.kmMarker));

    for (final zone in sortedZones) {
      final legKm = math.max(0.0, zone.kmMarker - previousKm);
      final legHours = legKm / safeSpeedKmh;
      final consumedMl = legHours * hourlyDemandMl;
      currentFluidMl = currentFluidMl - consumedMl;
      if (currentFluidMl < minMarginMl) {
        minMarginMl = currentFluidMl;
      }
      final criticalArrival = currentFluidMl < 250.0;
      if (currentFluidMl <= 0.0) {
        hasRisk = true;
        currentFluidMl = 0.0;
      }

      final priority = selectedPriorities[zone.id] ??
          (zone.hasWaterResupply
              ? GravelOasisServicePriority.splashAndDash
              : GravelOasisServicePriority.skipNonStop);

      final effectivePriority = !zone.hasWaterResupply &&
              priority == GravelOasisServicePriority.splashAndDash
          ? GravelOasisServicePriority.skipNonStop
          : priority;

      final addedFluid =
          zone.hasWaterResupply ? effectivePriority.addedFluidMl : 0.0;
      final afterRefill =
          (currentFluidMl + addedFluid).clamp(0.0, maxCapacityMl);
      final actualAdded = math.max(0.0, afterRefill - currentFluidMl);

      if (effectivePriority != GravelOasisServicePriority.skipNonStop) {
        activeStops += 1;
      }
      totalSeconds += effectivePriority.stopDurationSeconds;
      totalRefilledMl += actualAdded;

      evaluations.add(
        GravelOasisZoneEvaluation(
          zone: zone,
          priority: effectivePriority,
          arrivalFluidMl: currentFluidMl,
          departureFluidMl: afterRefill,
          stopDurationSeconds: effectivePriority.stopDurationSeconds,
          isCriticalLowOnArrival: criticalArrival,
        ),
      );

      currentFluidMl = afterRefill;
      previousKm = zone.kmMarker;
    }

    final finalLegKm = math.max(0.0, race.totalDistanceKm - previousKm);
    final finalConsumedMl = (finalLegKm / safeSpeedKmh) * hourlyDemandMl;
    currentFluidMl -= finalConsumedMl;
    if (currentFluidMl < minMarginMl) {
      minMarginMl = currentFluidMl;
    }
    if (currentFluidMl <= 0.0) {
      hasRisk = true;
      currentFluidMl = 0.0;
    }

    return GravelOasisPlanSummary(
      zoneEvaluations: evaluations,
      activeStopCount: activeStops,
      totalStopTimeSeconds: totalSeconds,
      totalFluidRefilledMl: totalRefilledMl,
      minimumFluidMarginMl: minMarginMl,
      finishRemainingFluidMl: currentFluidMl,
      hasDehydrationRisk: hasRisk,
    );
  }
}

/// Wpis wyścigu w kalendarzu UCI Gravel World Series & Ultra-Gravel.
class GravelSeriesRaceEntry {
  final String id;
  final int roundNumber;
  final String dateLabel;
  final String locationLabel;
  final String signatureFeature;
  final int uciPointsTop;
  final int prizePoolEur;
  final GravelRaceAndSurfaceModel raceModel;
  final List<GravelOasisZoneSpec> oasisZones;

  const GravelSeriesRaceEntry({
    required this.id,
    required this.roundNumber,
    required this.dateLabel,
    required this.locationLabel,
    required this.signatureFeature,
    required this.uciPointsTop,
    required this.prizePoolEur,
    required this.raceModel,
    required this.oasisZones,
  });

  bool get isWorldChampionship =>
      raceModel.tier == GravelRaceDisciplineTier.uciGravelWorldChampionships;

  bool get isUltraGravel =>
      raceModel.tier == GravelRaceDisciplineTier.ultraGravelSelfSupported;
}

/// Katalog sezonu UCI Gravel World Series & Ultra-Gravel.
class GravelWorldSeriesCalendarCatalog {
  GravelWorldSeriesCalendarCatalog._();

  static List<GravelSeriesRaceEntry> buildSeasonCalendar() {
    final traka = GravelRaceAndSurfaceModel.theTraka360();
    final unbound = GravelRaceAndSurfaceModel.unboundGravel200();
    final venetoWorlds = GravelRaceAndSurfaceModel.uciGravelWorldsVeneto();

    return [
      GravelSeriesRaceEntry(
        id: 'turnhout_gravel_qualifier',
        roundNumber: 1,
        dateLabel: '14 KWI',
        locationLabel: 'Turnhout, Belgia',
        signatureFeature: 'Szybkie leśne szutry Flandrii i wiatr na otwartych polach',
        uciPointsTop: 200,
        prizePoolEur: 12000,
        raceModel: GravelRaceAndSurfaceModel(
          id: 'turnhout_gravel_qualifier',
          name: 'Flanders Gravel Qualifier — Turnhout',
          countryCode: 'BEL',
          region: 'Antwerpia',
          tier: GravelRaceDisciplineTier.uciGravelWorldSeries,
          totalDistanceKm: 138.0,
          totalElevationGainM: 640.0,
          selfSupportedRules: SelfSupportedRulesConfig.uciGravelStandard(),
          recommendedTireWidthMm: 40.0,
          ambientTemperatureC: 16.0,
          rainIntensity: 0.25,
          cutOffTimeHours: 7.0,
          segments: const [
            GravelCourseSegment(
              index: 0,
              startKm: 0.0,
              lengthKm: 44.0,
              surfaceCategory: GravelSurfaceCategory.cat1ChampagneGravel,
              gradientPercent: 0.4,
              elevationGainM: 180.0,
            ),
            GravelCourseSegment(
              index: 1,
              startKm: 44.0,
              lengthKm: 48.0,
              surfaceCategory: GravelSurfaceCategory.cat2CompactedForestRoad,
              gradientPercent: 0.7,
              elevationGainM: 250.0,
              mudSaturationIndex: 0.2,
              isFeedOrCheckpointZone: true,
              checkpointName: 'Oasis 1 — Ravels Forest',
              hasWaterResupply: true,
            ),
            GravelCourseSegment(
              index: 2,
              startKm: 92.0,
              lengthKm: 46.0,
              surfaceCategory: GravelSurfaceCategory.cat2CompactedForestRoad,
              gradientPercent: 0.5,
              elevationGainM: 210.0,
              isFeedOrCheckpointZone: true,
              checkpointName: 'Oasis 2 — Arendonk Canal',
              hasWaterResupply: true,
            ),
          ],
        ),
        oasisZones: const [
          GravelOasisZoneSpec(
            id: 'turnhout_oasis_1',
            name: 'Oasis 1 — Ravels Forest',
            kmMarker: 48.0,
            distanceToNextKm: 46.0,
            hasWaterResupply: true,
            hasMechanicalNeutral: true,
            elevationMeters: 35.0,
            ambientTempC: 16.0,
          ),
          GravelOasisZoneSpec(
            id: 'turnhout_oasis_2',
            name: 'Oasis 2 — Arendonk Canal',
            kmMarker: 94.0,
            distanceToNextKm: 44.0,
            hasWaterResupply: true,
            hasMechanicalNeutral: false,
            elevationMeters: 28.0,
            ambientTempC: 17.0,
          ),
        ],
      ),
      GravelSeriesRaceEntry(
        id: traka.id,
        roundNumber: 2,
        dateLabel: '02 MAJ',
        locationLabel: 'Girona, Hiszpania',
        signatureFeature: 'Kataloński monument Ultra-Gravel z 5200 m przewyższenia',
        uciPointsTop: 320,
        prizePoolEur: 28000,
        raceModel: traka,
        oasisZones: const [
          GravelOasisZoneSpec(
            id: 'traka_oasis_1',
            name: 'Oasis 1 — Olot Volcano',
            kmMarker: 85.0,
            distanceToNextKm: 95.0,
            hasWaterResupply: true,
            hasMechanicalNeutral: true,
            hasShadeAndIce: true,
            elevationMeters: 445.0,
            ambientTempC: 23.0,
          ),
          GravelOasisZoneSpec(
            id: 'traka_oasis_2',
            name: 'Oasis 2 — Banyoles Lake',
            kmMarker: 180.0,
            distanceToNextKm: 95.0,
            hasWaterResupply: true,
            hasMechanicalNeutral: true,
            hasShadeAndIce: true,
            elevationMeters: 175.0,
            ambientTempC: 26.0,
          ),
          GravelOasisZoneSpec(
            id: 'traka_oasis_3',
            name: 'Oasis 3 — Les Gavarres Ridge',
            kmMarker: 275.0,
            distanceToNextKm: 85.0,
            hasWaterResupply: true,
            hasMechanicalNeutral: false,
            elevationMeters: 490.0,
            ambientTempC: 24.0,
          ),
        ],
      ),
      GravelSeriesRaceEntry(
        id: 'limburg_gravel_classic',
        roundNumber: 3,
        dateLabel: '24 MAJ',
        locationLabel: 'Valkenburg, Holandia',
        signatureFeature: 'Krótkie sztywne ścianki na białym żwirze i częste zjazdy',
        uciPointsTop: 200,
        prizePoolEur: 14000,
        raceModel: GravelRaceAndSurfaceModel(
          id: 'limburg_gravel_classic',
          name: 'Limburg White Roads — Valkenburg',
          countryCode: 'NED',
          region: 'Limburgia',
          tier: GravelRaceDisciplineTier.uciGravelWorldSeries,
          totalDistanceKm: 148.0,
          totalElevationGainM: 1920.0,
          selfSupportedRules: SelfSupportedRulesConfig.uciGravelStandard(),
          recommendedTireWidthMm: 42.0,
          ambientTemperatureC: 20.0,
          cutOffTimeHours: 7.5,
          segments: const [
            GravelCourseSegment(
              index: 0,
              startKm: 0.0,
              lengthKm: 52.0,
              surfaceCategory: GravelSurfaceCategory.cat1ChampagneGravel,
              gradientPercent: 2.2,
              elevationGainM: 640.0,
            ),
            GravelCourseSegment(
              index: 1,
              startKm: 52.0,
              lengthKm: 48.0,
              surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
              gradientPercent: 2.9,
              elevationGainM: 720.0,
              isFeedOrCheckpointZone: true,
              checkpointName: 'Oasis 1 — Cauberg Gravel Pit',
              hasWaterResupply: true,
            ),
            GravelCourseSegment(
              index: 2,
              startKm: 100.0,
              lengthKm: 48.0,
              surfaceCategory: GravelSurfaceCategory.cat2CompactedForestRoad,
              gradientPercent: 1.8,
              elevationGainM: 560.0,
              isFeedOrCheckpointZone: true,
              checkpointName: 'Oasis 2 — Gulpen',
              hasWaterResupply: true,
            ),
          ],
        ),
        oasisZones: const [
          GravelOasisZoneSpec(
            id: 'limburg_oasis_1',
            name: 'Oasis 1 — Cauberg Gravel Pit',
            kmMarker: 54.0,
            distanceToNextKm: 48.0,
            hasWaterResupply: true,
            hasMechanicalNeutral: true,
            elevationMeters: 140.0,
            ambientTempC: 20.0,
          ),
          GravelOasisZoneSpec(
            id: 'limburg_oasis_2',
            name: 'Oasis 2 — Gulpen',
            kmMarker: 102.0,
            distanceToNextKm: 46.0,
            hasWaterResupply: true,
            elevationMeters: 110.0,
            ambientTempC: 21.0,
          ),
        ],
      ),
      GravelSeriesRaceEntry(
        id: unbound.id,
        roundNumber: 4,
        dateLabel: '07 CZE',
        locationLabel: 'Emporia, Kansas USA',
        signatureFeature: 'Ostry krzemień Flint Hills niszczący ścianki boczne + 31°C upał',
        uciPointsTop: 350,
        prizePoolEur: 35000,
        raceModel: unbound,
        oasisZones: const [
          GravelOasisZoneSpec(
            id: 'unbound_oasis_1',
            name: 'Oasis 1 — Eureka Water Station',
            kmMarker: 82.0,
            distanceToNextKm: 92.0,
            hasWaterResupply: true,
            hasShadeAndIce: true,
            elevationMeters: 340.0,
            ambientTempC: 30.0,
          ),
          GravelOasisZoneSpec(
            id: 'unbound_oasis_2',
            name: 'Oasis 2 — Madison Neutral Oasis',
            kmMarker: 174.0,
            distanceToNextKm: 82.0,
            hasWaterResupply: true,
            hasMechanicalNeutral: true,
            hasShadeAndIce: true,
            elevationMeters: 365.0,
            ambientTempC: 33.0,
          ),
          GravelOasisZoneSpec(
            id: 'unbound_oasis_3',
            name: 'Oasis 3 — Council Grove',
            kmMarker: 256.0,
            distanceToNextKm: 66.0,
            hasWaterResupply: true,
            hasShadeAndIce: true,
            elevationMeters: 380.0,
            ambientTempC: 31.0,
          ),
        ],
      ),
      GravelSeriesRaceEntry(
        id: 'woerthersee_gravel',
        roundNumber: 5,
        dateLabel: '20 LIP',
        locationLabel: 'Velden, Austria',
        signatureFeature: 'Alpejskie drogi leśne wokół jeziora z długimi zjazdami szutrowymi',
        uciPointsTop: 220,
        prizePoolEur: 16500,
        raceModel: GravelRaceAndSurfaceModel(
          id: 'woerthersee_gravel',
          name: 'Wörthersee Alpine Gravel',
          countryCode: 'AUT',
          region: 'Karyntia',
          tier: GravelRaceDisciplineTier.uciGravelWorldSeries,
          totalDistanceKm: 154.0,
          totalElevationGainM: 2450.0,
          selfSupportedRules: SelfSupportedRulesConfig.uciGravelStandard(),
          recommendedTireWidthMm: 43.0,
          ambientTemperatureC: 24.0,
          cutOffTimeHours: 8.5,
          segments: const [
            GravelCourseSegment(
              index: 0,
              startKm: 0.0,
              lengthKm: 54.0,
              surfaceCategory: GravelSurfaceCategory.cat2CompactedForestRoad,
              gradientPercent: 2.5,
              elevationGainM: 880.0,
            ),
            GravelCourseSegment(
              index: 1,
              startKm: 54.0,
              lengthKm: 52.0,
              surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
              gradientPercent: 3.1,
              elevationGainM: 940.0,
              isFeedOrCheckpointZone: true,
              checkpointName: 'Oasis 1 — Pyramidenkogel',
              hasWaterResupply: true,
            ),
            GravelCourseSegment(
              index: 2,
              startKm: 106.0,
              lengthKm: 48.0,
              surfaceCategory: GravelSurfaceCategory.cat2CompactedForestRoad,
              gradientPercent: 1.4,
              elevationGainM: 630.0,
              isFeedOrCheckpointZone: true,
              checkpointName: 'Oasis 2 — Pörtschach',
              hasWaterResupply: true,
            ),
          ],
        ),
        oasisZones: const [
          GravelOasisZoneSpec(
            id: 'woerthersee_oasis_1',
            name: 'Oasis 1 — Pyramidenkogel',
            kmMarker: 56.0,
            distanceToNextKm: 52.0,
            hasWaterResupply: true,
            hasMechanicalNeutral: true,
            elevationMeters: 850.0,
            ambientTempC: 21.0,
          ),
          GravelOasisZoneSpec(
            id: 'woerthersee_oasis_2',
            name: 'Oasis 2 — Pörtschach',
            kmMarker: 108.0,
            distanceToNextKm: 46.0,
            hasWaterResupply: true,
            hasShadeAndIce: true,
            elevationMeters: 460.0,
            ambientTempC: 25.0,
          ),
        ],
      ),
      GravelSeriesRaceEntry(
        id: 'badlands_sierra_nevada',
        roundNumber: 6,
        dateLabel: '05 WRZ',
        locationLabel: 'Granada, Hiszpania',
        signatureFeature: 'Ekstremalny półpustynny szuter Sierra Nevada, głęboki pył i 34°C',
        uciPointsTop: 300,
        prizePoolEur: 24000,
        raceModel: GravelRaceAndSurfaceModel(
          id: 'badlands_sierra_nevada',
          name: 'Badlands Desert Ultra — Gorafe',
          countryCode: 'ESP',
          region: 'Andaluzja',
          tier: GravelRaceDisciplineTier.ultraGravelSelfSupported,
          totalDistanceKm: 285.0,
          totalElevationGainM: 4800.0,
          selfSupportedRules: SelfSupportedRulesConfig.ultraGravelStrict(
            allowAerobars: true,
          ),
          recommendedTireWidthMm: 48.0,
          ambientTemperatureC: 34.0,
          cutOffTimeHours: 22.0,
          segments: const [
            GravelCourseSegment(
              index: 0,
              startKm: 0.0,
              lengthKm: 70.0,
              surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
              gradientPercent: 2.1,
              elevationGainM: 1120.0,
              dustDensityIndex: 0.9,
            ),
            GravelCourseSegment(
              index: 1,
              startKm: 70.0,
              lengthKm: 80.0,
              surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
              gradientPercent: 2.7,
              elevationGainM: 1480.0,
              isFeedOrCheckpointZone: true,
              checkpointName: 'Oasis 1 — Desierto de Gorafe',
              hasWaterResupply: true,
            ),
            GravelCourseSegment(
              index: 2,
              startKm: 150.0,
              lengthKm: 75.0,
              surfaceCategory: GravelSurfaceCategory.cat5TechnicalSingletrackAndMud,
              gradientPercent: 3.0,
              elevationGainM: 1380.0,
              isFeedOrCheckpointZone: true,
              checkpointName: 'Oasis 2 — Pico Veleta Base',
              hasWaterResupply: true,
            ),
            GravelCourseSegment(
              index: 3,
              startKm: 225.0,
              lengthKm: 60.0,
              surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
              gradientPercent: 1.4,
              elevationGainM: 820.0,
            ),
          ],
        ),
        oasisZones: const [
          GravelOasisZoneSpec(
            id: 'badlands_oasis_1',
            name: 'Oasis 1 — Desierto de Gorafe',
            kmMarker: 72.0,
            distanceToNextKm: 82.0,
            hasWaterResupply: true,
            hasShadeAndIce: true,
            elevationMeters: 880.0,
            ambientTempC: 36.0,
          ),
          GravelOasisZoneSpec(
            id: 'badlands_oasis_2',
            name: 'Oasis 2 — Pico Veleta Base',
            kmMarker: 154.0,
            distanceToNextKm: 72.0,
            hasWaterResupply: true,
            hasMechanicalNeutral: true,
            hasShadeAndIce: true,
            elevationMeters: 1620.0,
            ambientTempC: 28.0,
          ),
          GravelOasisZoneSpec(
            id: 'badlands_oasis_3',
            name: 'Oasis 3 — Guadix',
            kmMarker: 226.0,
            distanceToNextKm: 59.0,
            hasWaterResupply: true,
            hasShadeAndIce: true,
            elevationMeters: 940.0,
            ambientTempC: 33.0,
          ),
        ],
      ),
      GravelSeriesRaceEntry(
        id: venetoWorlds.id,
        roundNumber: 7,
        dateLabel: '12 PAŹ',
        locationLabel: 'Veneto, Włochy',
        signatureFeature: 'Finał o Tęczową Koszulkę UCI na białych drogach Prosecco',
        uciPointsTop: 600,
        prizePoolEur: 50000,
        raceModel: venetoWorlds,
        oasisZones: const [
          GravelOasisZoneSpec(
            id: 'veneto_oasis_1',
            name: 'Oasis 1 — Bassano del Grappa',
            kmMarker: 42.0,
            distanceToNextKm: 42.0,
            hasWaterResupply: true,
            hasMechanicalNeutral: true,
            elevationMeters: 210.0,
            ambientTempC: 20.0,
          ),
          GravelOasisZoneSpec(
            id: 'veneto_oasis_2',
            name: 'Oasis 2 — Asolo Prosecco Hills',
            kmMarker: 84.0,
            distanceToNextKm: 42.0,
            hasWaterResupply: true,
            hasMechanicalNeutral: true,
            elevationMeters: 320.0,
            ambientTempC: 22.0,
          ),
          GravelOasisZoneSpec(
            id: 'veneto_oasis_3',
            name: 'Oasis 3 — Cittadella Walls',
            kmMarker: 126.0,
            distanceToNextKm: 36.0,
            hasWaterResupply: true,
            elevationMeters: 60.0,
            ambientTempC: 21.0,
          ),
        ],
      ),
    ];
  }
}

/// Opcja wkładki antyprzebiciowej w konfiguratorze.
enum GravelInsertOption {
  none,
  ultralightRace,
  flintGuardEnduro;

  String get labelPl {
    switch (this) {
      case GravelInsertOption.none:
        return 'Brak wkładki';
      case GravelInsertOption.ultralightRace:
        return 'Ultralight Race (32 g)';
      case GravelInsertOption.flintGuardEnduro:
        return 'Flint-Guard HD (68 g)';
    }
  }

  FoamTireInsertSpec toSpec() {
    switch (this) {
      case GravelInsertOption.none:
        return const FoamTireInsertSpec.none();
      case GravelInsertOption.ultralightRace:
        return const FoamTireInsertSpec.ultralightRace();
      case GravelInsertOption.flintGuardEnduro:
        return const FoamTireInsertSpec.flintGuardEnduro();
    }
  }
}

/// Opcja mleczka Tubeless w konfiguratorze.
enum GravelSealantOption {
  none,
  raceMicrofiber,
  ultraEndurance;

  String get labelPl {
    switch (this) {
      case GravelSealantOption.none:
        return 'Bez mleczka (Dętka)';
      case GravelSealantOption.raceMicrofiber:
        return 'Race Microfiber (80 ml)';
      case GravelSealantOption.ultraEndurance:
        return 'Ultra-Endurance (110 ml)';
    }
  }

  TubelessSealantSpec toSpec() {
    switch (this) {
      case GravelSealantOption.none:
        return const TubelessSealantSpec.none();
      case GravelSealantOption.raceMicrofiber:
        return const TubelessSealantSpec.raceMicrofiber(volumeMlPerTire: 80.0);
      case GravelSealantOption.ultraEndurance:
        return const TubelessSealantSpec.ultraEndurance(volumeMlPerTire: 110.0);
    }
  }
}

/// Opcja plecaka bukłakowego w konfiguratorze.
enum GravelHydrationPackOption {
  none,
  aeroVest1500,
  endurance2000,
  ultraExpedition3000;

  String get labelPl {
    switch (this) {
      case GravelHydrationPackOption.none:
        return 'Tylko bidony';
      case GravelHydrationPackOption.aeroVest1500:
        return 'Aero Vest 1.5 L';
      case GravelHydrationPackOption.endurance2000:
        return 'Endurance 2.0 L';
      case GravelHydrationPackOption.ultraExpedition3000:
        return 'Ultra Expedition 3.0 L';
    }
  }

  AeroHydrationPackSpec toSpec() {
    switch (this) {
      case GravelHydrationPackOption.none:
        return const AeroHydrationPackSpec.none();
      case GravelHydrationPackOption.aeroVest1500:
        return const AeroHydrationPackSpec.aeroVest1500Ml();
      case GravelHydrationPackOption.endurance2000:
        return const AeroHydrationPackSpec.enduranceRace2000Ml();
      case GravelHydrationPackOption.ultraExpedition3000:
        return const AeroHydrationPackSpec.ultraExpedition3000Ml();
    }
  }
}

/// Katalog 3 ram szutrowych z różnym limitem prześwitu opony (44–52 mm).
class GravelFrameCatalog {
  GravelFrameCatalog._();

  static const List<GravelBikeFrameSpec> availableFrames = [
    GravelBikeFrameSpec(
      id: 'frame_aero_gravel_cfr',
      brandId: 'canyon',
      name: 'Grail CFR Aero (Max 44 mm)',
      geometryCategory: GravelBikeGeometryCategory.aeroGravelRace,
      frameWeightGrams: 930,
      maxTireClearanceMm: 44.0,
      vibrationDampingIndex: 3.5,
      aeroCdaModifier: -0.0065,
      bottleCageMountsCount: 2,
      priceEur: 4500,
    ),
    GravelBikeFrameSpec(
      id: 'frame_endurance_gravel_slx',
      brandId: 'trek',
      name: 'Checkpoint SLR (Max 48 mm)',
      geometryCategory: GravelBikeGeometryCategory.allRoadEnduranceGravel,
      frameWeightGrams: 1040,
      maxTireClearanceMm: 48.0,
      vibrationDampingIndex: 4.4,
      aeroCdaModifier: -0.0020,
      bottleCageMountsCount: 3,
      priceEur: 4200,
    ),
    GravelBikeFrameSpec(
      id: 'frame_ultra_adventure_52',
      brandId: 'salsa',
      name: 'Cutthroat 52 (Max 52 mm)',
      geometryCategory: GravelBikeGeometryCategory.ultraAdventureGravel,
      frameWeightGrams: 1150,
      maxTireClearanceMm: 52.0,
      vibrationDampingIndex: 4.8,
      aeroCdaModifier: 0.0025,
      bottleCageMountsCount: 4,
      priceEur: 3800,
    ),
  ];
}

/// Ekran centrum wyścigów szutrowych UCI Gravel World Series & Ultra-Gravel
/// z kalendarzem, konfiguratorem opon 40–50 mm i planowaniem stref `Oasis`.
class GravelWorldSeriesHubScreen extends StatefulWidget {
  final String? initialRaceId;
  final double initialTireWidthMm;
  final bool isReadOnly;
  final void Function(
    GravelSeriesRaceEntry race,
    GravelBikeAndTireInsertsModel setup,
    GravelOasisPlanSummary oasisPlan,
  )? onApplyConfiguration;
  final void Function(
    GravelSeriesRaceEntry race,
    GravelBikeAndTireInsertsModel setup,
    GravelOasisPlanSummary oasisPlan,
  )? onLaunchRace;

  const GravelWorldSeriesHubScreen({
    super.key,
    this.initialRaceId,
    this.initialTireWidthMm = 42.0,
    this.isReadOnly = false,
    this.onApplyConfiguration,
    this.onLaunchRace,
  });

  @override
  State<GravelWorldSeriesHubScreen> createState() =>
      _GravelWorldSeriesHubScreenState();
}

class _GravelWorldSeriesHubScreenState
    extends State<GravelWorldSeriesHubScreen> {
  static const double _minConfigTireMm = 40.0;
  static const double _maxConfigTireMm = 50.0;

  final GravelRollingResistanceAndSealantSolver _physicsSolver =
      const GravelRollingResistanceAndSealantSolver();
  final GravelOasisPlannerCalculator _oasisCalculator =
      const GravelOasisPlannerCalculator();

  late final List<GravelSeriesRaceEntry> _calendar;
  late String _selectedRaceId;
  GravelCalendarFilter _calendarFilter = GravelCalendarFilter.all;
  GravelHubSectionTab _activeMobileTab = GravelHubSectionTab.calendar;

  // Konfiguracja opon 40–50 mm i roweru szutrowego.
  late double _tireWidthMm;
  double _frontPressureBar = 2.25;
  double _rearPressureBar = 2.35;
  GravelTireTreadPattern _treadPattern =
      GravelTireTreadPattern.allRounderMediumKnob;
  GravelTireCasingType _casingType = GravelTireCasingType.allRoundReinforced;
  GravelBikeFrameSpec _selectedFrame = GravelFrameCatalog.availableFrames[1];
  GravelInsertOption _insertOption = GravelInsertOption.ultralightRace;
  GravelSealantOption _sealantOption = GravelSealantOption.ultraEndurance;
  GravelHydrationPackOption _hydrationPackOption =
      GravelHydrationPackOption.endurance2000;

  // Parametry kolarza i pogody.
  final double _riderMassKg = 72.0;
  final double _targetSpeedKmh = 31.0;
  double _rainIntensity = 0.0;

  // Zestaw naprawczy Self-Supported.
  int _co2Cartridges = 3;
  int _tubelessPlugs = 6;
  int _spareInnerTubes = 1;
  bool _hasMiniPump = true;

  // Priorytety stref Oasis indeksowane po ID strefy.
  final Map<String, GravelOasisServicePriority> _oasisPriorities = {};
  String? _lastFeedbackMessage;

  @override
  void initState() {
    super.initState();
    _calendar = GravelWorldSeriesCalendarCatalog.buildSeasonCalendar();
    _tireWidthMm = widget.initialTireWidthMm
        .clamp(_minConfigTireMm, _maxConfigTireMm)
        .toDouble();

    final hasInitial = widget.initialRaceId != null &&
        _calendar.any((r) => r.id == widget.initialRaceId);
    _selectedRaceId =
        hasInitial ? widget.initialRaceId! : _calendar.first.id;

    _seedDefaultOasisForRace(_selectedRace);
  }

  GravelSeriesRaceEntry get _selectedRace => _calendar.firstWhere(
        (r) => r.id == _selectedRaceId,
        orElse: () => _calendar.first,
      );

  List<GravelSeriesRaceEntry> get _filteredCalendar {
    return _calendar.where((entry) {
      switch (_calendarFilter) {
        case GravelCalendarFilter.all:
          return true;
        case GravelCalendarFilter.worldSeries:
          return entry.raceModel.tier ==
              GravelRaceDisciplineTier.uciGravelWorldSeries;
        case GravelCalendarFilter.worldChampionships:
          return entry.isWorldChampionship;
        case GravelCalendarFilter.ultraGravel:
          return entry.isUltraGravel;
      }
    }).toList();
  }

  void _seedDefaultOasisForRace(GravelSeriesRaceEntry race) {
    for (final zone in race.oasisZones) {
      _oasisPriorities.putIfAbsent(
        zone.id,
        () => race.isUltraGravel
            ? GravelOasisServicePriority.fullHydrationRefill
            : GravelOasisServicePriority.splashAndDash,
      );
    }
    _rainIntensity = race.raceModel.rainIntensity;
  }

  GravelSurfaceCategory _dominantSurfaceForRace(GravelRaceAndSurfaceModel race) {
    if (race.segments.isEmpty) {
      return GravelSurfaceCategory.cat2CompactedForestRoad;
    }
    final breakdown = race.surfaceBreakdownKm;
    var bestCat = GravelSurfaceCategory.cat2CompactedForestRoad;
    var bestKm = -1.0;
    for (final entry in breakdown.entries) {
      if (entry.value > bestKm) {
        bestKm = entry.value;
        bestCat = entry.key;
      }
    }
    return bestCat;
  }

  GravelBikeAndTireInsertsModel _buildCurrentBikeSetup() {
    final width = _tireWidthMm.clamp(_minConfigTireMm, _maxConfigTireMm);
    final baseCrr = switch (_treadPattern) {
      GravelTireTreadPattern.fileTreadSlick => 0.0042,
      GravelTireTreadPattern.semiSlickMicroKnob => 0.0046,
      GravelTireTreadPattern.allRounderMediumKnob => 0.0051,
      GravelTireTreadPattern.aggressiveMudAndFlintKnob => 0.0059,
    };
    final tireWeightGrams = (390 + ((width - 40.0) * 18.0)).round() +
        (_casingType == GravelTireCasingType.armoredFlintGuard ? 45 : 0);

    final tireSpec = GravelTireSpec(
      id: 'custom_gravel_tire_${width.toStringAsFixed(0)}',
      brandId: 'custom_pro',
      name: 'Gravel Pro ${width.toStringAsFixed(0)} mm',
      widthMm: width,
      weightGramsPerTire: tireWeightGrams,
      baseCrr: baseCrr,
      treadPattern: _treadPattern,
      casingType: _casingType,
      punctureResistanceIndex:
          _casingType == GravelTireCasingType.armoredFlintGuard ? 4.6 : 3.4,
      sidewallProtectionIndex:
          _casingType == GravelTireCasingType.armoredFlintGuard ? 4.7 : 3.2,
      mudClearanceScore:
          _treadPattern == GravelTireTreadPattern.aggressiveMudAndFlintKnob
              ? 4.7
              : 3.5,
      priceEur: 74,
    );

    final bottleCap =
        _selectedFrame.bottleCageMountsCount >= 3 ? 2000.0 : 1500.0;

    return GravelBikeAndTireInsertsModel(
      id: 'hub_configured_setup',
      name: '${_selectedFrame.name} · ${width.toStringAsFixed(0)} mm',
      frame: _selectedFrame,
      frontTire: tireSpec,
      rearTire: tireSpec,
      frontPressureBar: _frontPressureBar,
      rearPressureBar: _rearPressureBar,
      tireInserts: _insertOption.toSpec(),
      tubelessSealant: _sealantOption.toSpec(),
      hydrationPack: _hydrationPackOption.toSpec(),
      frameBottlesCapacityMl: bottleCap,
      currentFrameBottlesFluidMl: bottleCap,
    );
  }

  GravelRepairKitState _buildCurrentRepairKit() {
    return GravelRepairKitState(
      co2CartridgesRemaining: _co2Cartridges,
      co2CartridgeGrams: _selectedRace.isUltraGravel ? 25 : 16,
      tubelessPlugsRemaining: _tubelessPlugs,
      spareInnerTubesRemaining: _spareInnerTubes,
      hasMiniPumpBackup: _hasMiniPump,
      sealantMlRemaining: _sealantOption.toSpec().initialVolumeMlPerTire * 2,
    );
  }

  void _selectRace(GravelSeriesRaceEntry entry) {
    if (widget.isReadOnly) return;
    setState(() {
      _selectedRaceId = entry.id;
      _seedDefaultOasisForRace(entry);
      _lastFeedbackMessage =
          'Wybrano rundę #${entry.roundNumber}: ${entry.raceModel.name}';
    });
  }

  void _applyEquipmentPreset(GravelBikeAndTireInsertsModel preset) {
    if (widget.isReadOnly) return;
    setState(() {
      _tireWidthMm = preset.frontTire.widthMm
          .clamp(_minConfigTireMm, _maxConfigTireMm)
          .toDouble();
      _frontPressureBar = preset.frontPressureBar;
      _rearPressureBar = preset.rearPressureBar;
      _treadPattern = preset.frontTire.treadPattern;
      _casingType = preset.frontTire.casingType;
      _selectedFrame = GravelFrameCatalog.availableFrames.firstWhere(
        (f) => f.id == preset.frame.id,
        orElse: () => GravelFrameCatalog.availableFrames.last,
      );
      if (!preset.tireInserts.isInstalled) {
        _insertOption = GravelInsertOption.none;
      } else if (preset.tireInserts.weightGramsPerWheel < 45) {
        _insertOption = GravelInsertOption.ultralightRace;
      } else {
        _insertOption = GravelInsertOption.flintGuardEnduro;
      }
      if (preset.tubelessSealant.initialVolumeMlPerTire <= 0) {
        _sealantOption = GravelSealantOption.none;
      } else if (preset.tubelessSealant.initialVolumeMlPerTire <= 85) {
        _sealantOption = GravelSealantOption.raceMicrofiber;
      } else {
        _sealantOption = GravelSealantOption.ultraEndurance;
      }
      if (!preset.hydrationPack.isEquipped) {
        _hydrationPackOption = GravelHydrationPackOption.none;
      } else if (preset.hydrationPack.bladderCapacityMl <= 1600) {
        _hydrationPackOption = GravelHydrationPackOption.aeroVest1500;
      } else if (preset.hydrationPack.bladderCapacityMl <= 2200) {
        _hydrationPackOption = GravelHydrationPackOption.endurance2000;
      } else {
        _hydrationPackOption = GravelHydrationPackOption.ultraExpedition3000;
      }
      _lastFeedbackMessage = 'Zastosowano preset: ${preset.name}';
    });
  }

  void _autoOptimizeTirePressure(GravelBikeAndTireInsertsModel bikeSetup) {
    if (widget.isReadOnly) return;
    final dominant = _dominantSurfaceForRace(_selectedRace.raceModel);
    final optimal = _physicsSolver.calculateOptimalGravelPressure(
      bikeSetup: bikeSetup,
      surfaceCategory: dominant,
      riderMassKg: _riderMassKg,
      rainIntensity: _rainIntensity,
    );
    setState(() {
      _frontPressureBar = (optimal.frontBar * 20).round() / 20.0;
      _rearPressureBar = (optimal.rearBar * 20).round() / 20.0;
      _lastFeedbackMessage =
          'Zoptymalizowano ciśnienie: ${_frontPressureBar.toStringAsFixed(2)} / ${_rearPressureBar.toStringAsFixed(2)} bar';
    });
  }

  @override
  Widget build(BuildContext context) {
    final raceEntry = _selectedRace;
    final bikeSetup = _buildCurrentBikeSetup();
    final dominantSurface = _dominantSurfaceForRace(raceEntry.raceModel);
    final physicsResult = _physicsSolver.solveRollingResistance(
      GravelImpedanceInput(
        bikeSetup: bikeSetup,
        surfaceCategory: dominantSurface,
        speedMetersPerSecond: _targetSpeedKmh / 3.6,
        riderMassKg: _riderMassKg,
        rainIntensity: _rainIntensity,
        ambientTempC: raceEntry.raceModel.ambientTemperatureC,
      ),
    );
    final readiness = bikeSetup.evaluateForRace(raceEntry.raceModel);
    final oasisPlan = _oasisCalculator.evaluatePlan(
      race: raceEntry.raceModel,
      oasisZones: raceEntry.oasisZones,
      selectedPriorities: _oasisPriorities,
      bikeSetup: bikeSetup,
      targetSpeedKmh: _targetSpeedKmh,
    );
    final repairKit = _buildCurrentRepairKit();
    final isKitCompliant =
        raceEntry.raceModel.selfSupportedRules.isRepairKitCompliant(repairKit);

    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobile = width < 760;
              final isTablet = width >= 760 && width < 1280;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderBar(
                    raceEntry: raceEntry,
                    readiness: readiness,
                    isMobile: isMobile,
                    isKitCompliant: isKitCompliant,
                    oasisPlan: oasisPlan,
                    bikeSetup: bikeSetup,
                  ),
                  if (_lastFeedbackMessage != null)
                    _buildFeedbackBanner(_lastFeedbackMessage!),
                  if (isMobile)
                    _buildMobileTabSelector()
                  else if (isTablet)
                    _buildTabletModeBar(),
                  Expanded(
                    child: isMobile
                        ? _buildMobileBody(
                            raceEntry: raceEntry,
                            bikeSetup: bikeSetup,
                            physicsResult: physicsResult,
                            readiness: readiness,
                            oasisPlan: oasisPlan,
                            isKitCompliant: isKitCompliant,
                          )
                        : isTablet
                            ? _buildTabletBody(
                                raceEntry: raceEntry,
                                bikeSetup: bikeSetup,
                                physicsResult: physicsResult,
                                readiness: readiness,
                                oasisPlan: oasisPlan,
                                isKitCompliant: isKitCompliant,
                              )
                            : _buildDesktopBentoBody(
                                raceEntry: raceEntry,
                                bikeSetup: bikeSetup,
                                physicsResult: physicsResult,
                                readiness: readiness,
                                oasisPlan: oasisPlan,
                                isKitCompliant: isKitCompliant,
                              ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBar({
    required GravelSeriesRaceEntry raceEntry,
    required GravelEquipmentRaceReadinessReport readiness,
    required bool isMobile,
    required bool isKitCompliant,
    required GravelOasisPlanSummary oasisPlan,
    required GravelBikeAndTireInsertsModel bikeSetup,
  }) {
    final scoreColor = readiness.suitabilityScore >= 82
        ? AppColors.statusSuccess
        : readiness.suitabilityScore >= 65
            ? AppColors.amberWarning
            : AppColors.crimsonAlert;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryAccent),
                ),
                child: const Icon(
                  Icons.terrain_rounded,
                  color: AppColors.goldAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GRAVEL WORLD SERIES HUB',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Runda #${raceEntry.roundNumber} · ${raceEntry.locationLabel} · ${raceEntry.raceModel.totalDistanceKm.toStringAsFixed(0)} km',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetricBadgePill(
                label: 'Gotowość',
                value: '${readiness.suitabilityScore.toStringAsFixed(0)}/100',
                accentColor: scoreColor,
              ),
              _MetricBadgePill(
                label: 'Opona',
                value: '${_tireWidthMm.toStringAsFixed(0)} mm',
                accentColor: readiness.isClearanceValid
                    ? AppColors.accentBlue
                    : AppColors.crimsonAlert,
              ),
              _MetricBadgePill(
                label: 'Oasis',
                value: '${oasisPlan.activeStopCount}/${raceEntry.oasisZones.length}',
                accentColor: oasisPlan.hasDehydrationRisk
                    ? AppColors.crimsonAlert
                    : AppColors.statusSuccess,
              ),
              _GravelActionButton(
                label: 'Zapisz Setup',
                icon: Icons.check_circle_outline_rounded,
                isPrimary: false,
                enabled: !widget.isReadOnly,
                onTap: () {
                  widget.onApplyConfiguration?.call(
                    raceEntry,
                    bikeSetup,
                    oasisPlan,
                  );
                  setState(() {
                    _lastFeedbackMessage =
                        'Zapisano setup (${_tireWidthMm.toStringAsFixed(0)} mm) i plan ${oasisPlan.activeStopCount} stref Oasis.';
                  });
                },
              ),
              _GravelActionButton(
                label: 'Start Wyścigu',
                icon: Icons.play_arrow_rounded,
                isPrimary: true,
                enabled: !widget.isReadOnly &&
                    readiness.isClearanceValid &&
                    isKitCompliant,
                onTap: () {
                  widget.onLaunchRace?.call(
                    raceEntry,
                    bikeSetup,
                    oasisPlan,
                  );
                  setState(() {
                    _lastFeedbackMessage =
                        'Uruchomiono odprawę szutrową dla ${raceEntry.raceModel.name}.';
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withValues(alpha: 0.12),
        border: const Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.goldAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTabSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Row(
        children: GravelHubSectionTab.values.map((tab) {
          final isSelected = _activeMobileTab == tab;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _GravelInteractiveSurface(
                enabled: true,
                isSelected: isSelected,
                borderRadius: 12,
                onTap: () => setState(() => _activeMobileTab = tab),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab.icon,
                      size: 15,
                      color: isSelected
                          ? AppColors.goldAccent
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        tab.labelPl,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabletModeBar() {
    final rightTab = _activeMobileTab == GravelHubSectionTab.oasisZones
        ? GravelHubSectionTab.oasisZones
        : GravelHubSectionTab.tiresConfigurator;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'Widok prawy:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          for (final tab in [
            GravelHubSectionTab.tiresConfigurator,
            GravelHubSectionTab.oasisZones,
          ]) ...[
            _GravelInteractiveSurface(
              enabled: true,
              isSelected: rightTab == tab,
              borderRadius: 10,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              onTap: () => setState(() => _activeMobileTab = tab),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab.icon,
                    size: 15,
                    color: rightTab == tab
                        ? AppColors.goldAccent
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tab.labelPl,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight:
                          rightTab == tab ? FontWeight.w700 : FontWeight.w500,
                      color: rightTab == tab
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileBody({
    required GravelSeriesRaceEntry raceEntry,
    required GravelBikeAndTireInsertsModel bikeSetup,
    required GravelImpedanceResult physicsResult,
    required GravelEquipmentRaceReadinessReport readiness,
    required GravelOasisPlanSummary oasisPlan,
    required bool isKitCompliant,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: switch (_activeMobileTab) {
        GravelHubSectionTab.calendar => _buildCalendarSection(raceEntry),
        GravelHubSectionTab.tiresConfigurator => _buildTireConfiguratorSection(
            raceEntry: raceEntry,
            bikeSetup: bikeSetup,
            physicsResult: physicsResult,
            readiness: readiness,
          ),
        GravelHubSectionTab.oasisZones => _buildOasisZonesSection(
            raceEntry: raceEntry,
            oasisPlan: oasisPlan,
            isKitCompliant: isKitCompliant,
          ),
      },
    );
  }

  Widget _buildTabletBody({
    required GravelSeriesRaceEntry raceEntry,
    required GravelBikeAndTireInsertsModel bikeSetup,
    required GravelImpedanceResult physicsResult,
    required GravelEquipmentRaceReadinessReport readiness,
    required GravelOasisPlanSummary oasisPlan,
    required bool isKitCompliant,
  }) {
    final showOasis = _activeMobileTab == GravelHubSectionTab.oasisZones;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: _buildCalendarSection(raceEntry),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 7,
            child: SingleChildScrollView(
              child: showOasis
                  ? _buildOasisZonesSection(
                      raceEntry: raceEntry,
                      oasisPlan: oasisPlan,
                      isKitCompliant: isKitCompliant,
                    )
                  : _buildTireConfiguratorSection(
                      raceEntry: raceEntry,
                      bikeSetup: bikeSetup,
                      physicsResult: physicsResult,
                      readiness: readiness,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopBentoBody({
    required GravelSeriesRaceEntry raceEntry,
    required GravelBikeAndTireInsertsModel bikeSetup,
    required GravelImpedanceResult physicsResult,
    required GravelEquipmentRaceReadinessReport readiness,
    required GravelOasisPlanSummary oasisPlan,
    required bool isKitCompliant,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: _buildCalendarSection(raceEntry),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: _buildTireConfiguratorSection(
                raceEntry: raceEntry,
                bikeSetup: bikeSetup,
                physicsResult: physicsResult,
                readiness: readiness,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: _buildOasisZonesSection(
                raceEntry: raceEntry,
                oasisPlan: oasisPlan,
                isKitCompliant: isKitCompliant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SEKCJA 1: KALENDARZ WYŚCIGÓW SZUTROWYCH
  // ---------------------------------------------------------------------------
  Widget _buildCalendarSection(GravelSeriesRaceEntry selected) {
    final filtered = _filteredCalendar;
    return _SectionCard(
      title: 'Kalendarz Gravel World Series',
      subtitle: '7 rund · Kwalifikacje UCI, Ultra-Gravel i MŚ',
      icon: Icons.calendar_today_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: GravelCalendarFilter.values.map((filter) {
              final isSelected = _calendarFilter == filter;
              return _GravelInteractiveSurface(
                enabled: !widget.isReadOnly,
                isSelected: isSelected,
                borderRadius: 10,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onTap: () => setState(() => _calendarFilter = filter),
                child: Text(
                  filter.labelPl,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Brak wyścigów dla wybranego filtra.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...filtered.map((entry) {
              final isSelected = entry.id == selected.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildRaceCalendarCard(entry, isSelected),
              );
            }),
          const SizedBox(height: 4),
          _buildSelectedRaceSurfaceBreakdown(selected),
        ],
      ),
    );
  }

  Widget _buildRaceCalendarCard(
    GravelSeriesRaceEntry entry,
    bool isSelected,
  ) {
    final tierColor = entry.isWorldChampionship
        ? AppColors.goldAccent
        : entry.isUltraGravel
            ? AppColors.primaryAccent
            : AppColors.accentBlue;

    return _GravelInteractiveSurface(
      enabled: !widget.isReadOnly,
      isSelected: isSelected,
      borderRadius: 14,
      padding: const EdgeInsets.all(12),
      onTap: () => _selectRace(entry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tierColor.withValues(alpha: 0.6)),
                ),
                child: Text(
                  '#${entry.roundNumber} · ${entry.dateLabel}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: tierColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.raceModel.tier.displayName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.goldAccent,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.raceModel.name,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            entry.signatureFeature,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              _MiniStatChip(
                icon: Icons.route_rounded,
                text: '${entry.raceModel.totalDistanceKm.toStringAsFixed(0)} km',
              ),
              _MiniStatChip(
                icon: Icons.landscape_rounded,
                text:
                    '${entry.raceModel.totalElevationGainM.toStringAsFixed(0)} m',
              ),
              _MiniStatChip(
                icon: Icons.tire_repair_rounded,
                text:
                    'Zal. ${entry.raceModel.recommendedTireWidthMm.toStringAsFixed(0)} mm',
              ),
              _MiniStatChip(
                icon: Icons.water_drop_outlined,
                text: '${entry.oasisZones.length} Oasis',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedRaceSurfaceBreakdown(GravelSeriesRaceEntry entry) {
    final breakdown = entry.raceModel.surfaceBreakdownPercent;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Struktura nawierzchni (Kat. 1–5)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Trudność: ${entry.raceModel.weightedSurfaceDifficulty.toStringAsFixed(1)}/5.0',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: GravelSurfaceCategory.values.map((cat) {
                  final pct = breakdown[cat] ?? 0.0;
                  if (pct <= 0.5) return const SizedBox.shrink();
                  return Expanded(
                    flex: math.max(1, pct.round()),
                    child: Container(color: _surfaceColor(cat)),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: GravelSurfaceCategory.values.map((cat) {
              final pct = breakdown[cat] ?? 0.0;
              if (pct <= 0.1) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _surfaceColor(cat),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Kat.${cat.categoryNumber} ${pct.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _surfaceColor(GravelSurfaceCategory cat) {
    switch (cat) {
      case GravelSurfaceCategory.cat1ChampagneGravel:
        return AppColors.statusSuccess;
      case GravelSurfaceCategory.cat2CompactedForestRoad:
        return AppColors.accentBlue;
      case GravelSurfaceCategory.cat3LooseWashboardsAndRuts:
        return AppColors.amberWarning;
      case GravelSurfaceCategory.cat4SharpFlintAndChunkyRock:
        return AppColors.primaryAccent;
      case GravelSurfaceCategory.cat5TechnicalSingletrackAndMud:
        return AppColors.crimsonAlert;
    }
  }

  // ---------------------------------------------------------------------------
  // SEKCJA 2: KONFIGURATOR OPON 40–50 MM I SPRZĘTU SZUTROWEGO
  // ---------------------------------------------------------------------------
  Widget _buildTireConfiguratorSection({
    required GravelSeriesRaceEntry raceEntry,
    required GravelBikeAndTireInsertsModel bikeSetup,
    required GravelImpedanceResult physicsResult,
    required GravelEquipmentRaceReadinessReport readiness,
  }) {
    final isClearanceOk = bikeSetup.isTireClearanceValid;
    return _SectionCard(
      title: 'Konfigurator Opon 40–50 mm',
      subtitle: 'Szerokość, ciśnienie BAR, wkładki Foam Inserts i mleczko',
      icon: Icons.settings_input_component_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Presety fabryczne
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _GravelInteractiveSurface(
                enabled: !widget.isReadOnly,
                isSelected: false,
                borderRadius: 10,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onTap: () => _applyEquipmentPreset(
                  GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset(),
                ),
                child: const Text(
                  'Preset: UCI Aero 40 mm',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentBlue,
                  ),
                ),
              ),
              _GravelInteractiveSurface(
                enabled: !widget.isReadOnly,
                isSelected: false,
                borderRadius: 10,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onTap: () => _applyEquipmentPreset(
                  GravelBikeAndTireInsertsModel.flintHillsUltraPreset(),
                ),
                child: const Text(
                  'Preset: Flint Ultra 45 mm',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldAccent,
                  ),
                ),
              ),
              _GravelInteractiveSurface(
                enabled: !widget.isReadOnly,
                isSelected: false,
                borderRadius: 10,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onTap: () => _applyEquipmentPreset(
                  GravelBikeAndTireInsertsModel.technicalMudAndSingletrackPreset(),
                ),
                child: const Text(
                  'Preset: Trail 50 mm',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusSuccess,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Suwak szerokości opony 40–50 mm + szybkie przyciski
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isClearanceOk
                    ? AppTheme.borderColor
                    : AppColors.crimsonAlert,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Szerokość opon (40–50 mm)',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_tireWidthMm.toStringAsFixed(0)} mm',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isClearanceOk
                            ? AppColors.goldAccent
                            : AppColors.crimsonAlert,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _tireWidthMm,
                  min: _minConfigTireMm,
                  max: _maxConfigTireMm,
                  divisions: 10,
                  activeColor: isClearanceOk
                      ? AppColors.goldAccent
                      : AppColors.crimsonAlert,
                  inactiveColor: AppTheme.borderColor,
                  onChanged: widget.isReadOnly
                      ? null
                      : (v) => setState(() => _tireWidthMm = v.roundToDouble()),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [40.0, 42.0, 45.0, 48.0, 50.0].map((mm) {
                    final selected = (_tireWidthMm - mm).abs() < 0.1;
                    return _GravelInteractiveSurface(
                      enabled: !widget.isReadOnly,
                      isSelected: selected,
                      borderRadius: 8,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      onTap: () => setState(() => _tireWidthMm = mm),
                      child: Text(
                        '${mm.toStringAsFixed(0)} mm',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? AppColors.goldAccent
                              : AppColors.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (!isClearanceOk) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Przekroczono prześwit ramy (${_selectedFrame.maxTireClearanceMm.toStringAsFixed(0)} mm)! Wybierz szerszą ramę lub węższą oponę.',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.crimsonAlert,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Ciśnienie przód/tył + przycisk Solvera
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ciśnienie Tubeless [bar]',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _GravelActionButton(
                      label: 'Optymalizuj BAR',
                      icon: Icons.auto_fix_high_rounded,
                      isPrimary: false,
                      enabled: !widget.isReadOnly,
                      onTap: () => _autoOptimizeTirePressure(bikeSetup),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _PressureSliderRow(
                  label: 'Przód',
                  value: _frontPressureBar,
                  optimalValue: physicsResult.optimalFrontPressureBar,
                  enabled: !widget.isReadOnly,
                  onChanged: (v) => setState(() => _frontPressureBar = v),
                ),
                _PressureSliderRow(
                  label: 'Tył',
                  value: _rearPressureBar,
                  optimalValue: physicsResult.optimalRearPressureBar,
                  enabled: !widget.isReadOnly,
                  onChanged: (v) => setState(() => _rearPressureBar = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Rama, bieżnik i oplot
          _buildSelectorGroup<GravelBikeFrameSpec>(
            title: 'Rama szutrowa i prześwit',
            items: GravelFrameCatalog.availableFrames,
            selected: _selectedFrame,
            labelBuilder: (f) => f.name,
            onSelect: (f) => setState(() => _selectedFrame = f),
          ),
          const SizedBox(height: 10),
          _buildSelectorGroup<GravelTireTreadPattern>(
            title: 'Wzór bieżnika',
            items: GravelTireTreadPattern.values,
            selected: _treadPattern,
            labelBuilder: (t) => t.displayNamePl,
            onSelect: (t) => setState(() => _treadPattern = t),
          ),
          const SizedBox(height: 10),
          _buildSelectorGroup<GravelTireCasingType>(
            title: 'Oplot i wzmocnienie ścianki',
            items: GravelTireCasingType.values,
            selected: _casingType,
            labelBuilder: (c) => c.displayNamePl,
            onSelect: (c) => setState(() => _casingType = c),
          ),
          const SizedBox(height: 10),
          _buildSelectorGroup<GravelInsertOption>(
            title: 'Wkładki antyprzebiciowe (Foam Inserts)',
            items: GravelInsertOption.values,
            selected: _insertOption,
            labelBuilder: (i) => i.labelPl,
            onSelect: (i) => setState(() => _insertOption = i),
          ),
          const SizedBox(height: 10),
          _buildSelectorGroup<GravelSealantOption>(
            title: 'Mleczko Tubeless Sealant',
            items: GravelSealantOption.values,
            selected: _sealantOption,
            labelBuilder: (s) => s.labelPl,
            onSelect: (s) => setState(() => _sealantOption = s),
          ),
          const SizedBox(height: 12),

          // Telemetria fizyki szutrowej na żywo
          _buildPhysicsTelemetryPanel(physicsResult, readiness),
        ],
      ),
    );
  }

  Widget _buildSelectorGroup<T>({
    required String title,
    required List<T> items,
    required T selected,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items.map((item) {
            final isSelected = item == selected;
            return _GravelInteractiveSurface(
              enabled: !widget.isReadOnly,
              isSelected: isSelected,
              borderRadius: 10,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              onTap: () => onSelect(item),
              child: Text(
                labelBuilder(item),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPhysicsTelemetryPanel(
    GravelImpedanceResult physicsResult,
    GravelEquipmentRaceReadinessReport readiness,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Telemetria Impedancji & Odporności',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TelemetryCell(
                  label: 'Efektywne CRR',
                  value: physicsResult.effectiveCrr.toStringAsFixed(4),
                  color: AppColors.accentBlue,
                ),
              ),
              Expanded(
                child: _TelemetryCell(
                  label: 'Straty Toczenia',
                  value:
                      '${physicsResult.totalRollingPowerWatts.toStringAsFixed(1)} W',
                  color: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: _TelemetryCell(
                  label: 'Ochrona Przebić',
                  value:
                      '${readiness.punctureProtectionRating.toStringAsFixed(0)}%',
                  color: AppColors.statusSuccess,
                ),
              ),
            ],
          ),
          if (readiness.warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...readiness.warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: AppColors.amberWarning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        warning,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.amberWarning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SEKCJA 3: STREFY OASIS & REGULAMIN SELF-SUPPORTED
  // ---------------------------------------------------------------------------
  Widget _buildOasisZonesSection({
    required GravelSeriesRaceEntry raceEntry,
    required GravelOasisPlanSummary oasisPlan,
    required bool isKitCompliant,
  }) {
    final rules = raceEntry.raceModel.selfSupportedRules;

    return _SectionCard(
      title: 'Strefy Oasis & Nawadnianie',
      subtitle: 'Planowanie tankowania, serwisu i zestawu Self-Supported',
      icon: Icons.water_drop_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSelectorGroup<GravelHydrationPackOption>(
            title: 'Plecak bukłakowy (Aero Hydration Pack)',
            items: GravelHydrationPackOption.values,
            selected: _hydrationPackOption,
            labelBuilder: (h) => h.labelPl,
            onSelect: (h) => setState(() => _hydrationPackOption = h),
          ),
          const SizedBox(height: 12),

          // Podsumowanie planu Oasis
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: oasisPlan.hasDehydrationRisk
                    ? AppColors.crimsonAlert
                    : AppTheme.borderColor,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TelemetryCell(
                    label: 'Czas Postojów',
                    value: '${oasisPlan.totalStopTimeSeconds} s',
                    color: AppColors.goldAccent,
                  ),
                ),
                Expanded(
                  child: _TelemetryCell(
                    label: 'Dobrane Płyny',
                    value:
                        '+${(oasisPlan.totalFluidRefilledMl / 1000.0).toStringAsFixed(1)} L',
                    color: AppColors.accentBlue,
                  ),
                ),
                Expanded(
                  child: _TelemetryCell(
                    label: 'Zapas na Mecie',
                    value:
                        '${oasisPlan.finishRemainingFluidMl.toStringAsFixed(0)} ml',
                    color: oasisPlan.hasDehydrationRisk
                        ? AppColors.crimsonAlert
                        : AppColors.statusSuccess,
                  ),
                ),
              ],
            ),
          ),
          if (oasisPlan.hasDehydrationRisk) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.crimsonAlert.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.crimsonAlert),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: AppColors.crimsonAlert,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ryzyko odwodnienia na trasie! Włącz tankowanie w strefach Oasis lub załóż większy bukłak.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.crimsonAlert,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Lista stref Oasis na trasie
          ...oasisPlan.zoneEvaluations.map(
            (eval) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildOasisZoneCard(eval),
            ),
          ),

          const SizedBox(height: 4),

          // Zestaw naprawczy Self-Supported
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isKitCompliant
                    ? AppTheme.borderColor
                    : AppColors.crimsonAlert,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Zestaw Naprawczy (Self-Supported)',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (isKitCompliant
                                ? AppColors.statusSuccess
                                : AppColors.crimsonAlert)
                            .withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isKitCompliant ? 'ZGODNY Z UCI' : 'BRAKI SPRZĘTOWE',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isKitCompliant
                              ? AppColors.statusSuccess
                              : AppColors.crimsonAlert,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  rules.isStrictlySelfSupported
                      ? 'Rygor Ultra-Gravel: zakaz pomocy z zewnątrz (min. ${rules.minMandatoryCo2Cartridges}x CO₂, pompka, dętka, knoty).'
                      : 'Regulamin UCI Gravel: wsparcie techniczne tylko w wyznaczonych strefach Oasis.',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StepperChip(
                      label: 'Naboje CO₂',
                      value: _co2Cartridges,
                      minValue: 0,
                      maxValue: 6,
                      enabled: !widget.isReadOnly,
                      onChanged: (v) => setState(() => _co2Cartridges = v),
                    ),
                    _StepperChip(
                      label: 'Knoty (Plugs)',
                      value: _tubelessPlugs,
                      minValue: 0,
                      maxValue: 12,
                      enabled: !widget.isReadOnly,
                      onChanged: (v) => setState(() => _tubelessPlugs = v),
                    ),
                    _StepperChip(
                      label: 'Dętki zapas.',
                      value: _spareInnerTubes,
                      minValue: 0,
                      maxValue: 4,
                      enabled: !widget.isReadOnly,
                      onChanged: (v) => setState(() => _spareInnerTubes = v),
                    ),
                    _GravelInteractiveSurface(
                      enabled: !widget.isReadOnly,
                      isSelected: _hasMiniPump,
                      borderRadius: 10,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      onTap: () => setState(() => _hasMiniPump = !_hasMiniPump),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _hasMiniPump
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 15,
                            color: _hasMiniPump
                                ? AppColors.statusSuccess
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Mini-pompka',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOasisZoneCard(GravelOasisZoneEvaluation eval) {
    final zone = eval.zone;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: eval.isCriticalLowOnArrival
              ? AppColors.amberWarning
              : AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'KM ${zone.kmMarker.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentBlue,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  zone.name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (zone.hasMechanicalNeutral)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Tooltip(
                    message: 'Neutralny serwis techniczny',
                    child: Icon(
                      Icons.build_circle_outlined,
                      size: 16,
                      color: AppColors.goldAccent,
                    ),
                  ),
                ),
              if (zone.hasShadeAndIce)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Tooltip(
                    message: 'Lód i strefa cienia',
                    child: Icon(
                      Icons.ac_unit_rounded,
                      size: 16,
                      color: AppColors.cyanAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Przyjazd: ${eval.arrivalFluidMl.toStringAsFixed(0)} ml → Wyjazd: ${eval.departureFluidMl.toStringAsFixed(0)} ml · Postój: ${eval.stopDurationSeconds} s',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: eval.isCriticalLowOnArrival
                  ? AppColors.amberWarning
                  : AppColors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: GravelOasisServicePriority.values.map((priority) {
              final isSelected = eval.priority == priority;
              return _GravelInteractiveSurface(
                enabled: !widget.isReadOnly,
                isSelected: isSelected,
                borderRadius: 9,
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                onTap: () {
                  setState(() {
                    _oasisPriorities[zone.id] = priority;
                    _lastFeedbackMessage =
                        '${zone.name}: ustawiono "${priority.labelPl}"';
                  });
                },
                child: Text(
                  priority.labelPl,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// KOMPONENTY POMOCNICZE UI Z PEŁNYMI STANAMI HOVER / ACTIVE / DISABLED / FOCUS
// -----------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.goldAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _GravelInteractiveSurface extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isSelected;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const _GravelInteractiveSurface({
    required this.child,
    required this.enabled,
    required this.isSelected,
    this.onTap,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  State<_GravelInteractiveSurface> createState() =>
      _GravelInteractiveSurfaceState();
}

class _GravelInteractiveSurfaceState extends State<_GravelInteractiveSurface> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.isSelected
            ? AppColors.primaryAccent.withValues(alpha: 0.25)
            : _isPressed
                ? AppColors.surfaceLight
                : _isHovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.85)
                    : AppColors.background;

    final borderColor = !widget.enabled
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : _isFocused
            ? AppColors.accentBlue
            : widget.isSelected
                ? AppColors.goldAccent
                : _isHovered
                    ? AppColors.textSecondary
                    : AppTheme.borderColor;

    return Focus(
      canRequestFocus: widget.enabled,
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        cursor:
            widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: widget.enabled
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: widget.enabled
              ? () => setState(() => _isPressed = false)
              : null,
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: borderColor,
                width: _isFocused || widget.isSelected ? 1.3 : 1.0,
              ),
            ),
            child: Opacity(
              opacity: widget.enabled ? 1.0 : 0.5,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _GravelActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback? onTap;

  const _GravelActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.enabled,
    this.onTap,
  });

  @override
  State<_GravelActionButton> createState() => _GravelActionButtonState();
}

class _GravelActionButtonState extends State<_GravelActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.isPrimary
            ? (_isPressed
                ? AppColors.primaryAccent.withValues(alpha: 0.8)
                : _isHovered
                    ? AppColors.primaryAccent
                    : AppColors.primaryAccent.withValues(alpha: 0.9))
            : (_isHovered ? AppColors.surfaceLight : AppColors.background);

    final borderColor = !widget.enabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _isFocused
            ? AppColors.accentBlue
            : widget.isPrimary
                ? AppColors.goldAccent.withValues(alpha: 0.7)
                : AppTheme.borderColor;

    return Focus(
      canRequestFocus: widget.enabled,
      onFocusChange: (f) => setState(() => _isFocused = f),
      child: MouseRegion(
        cursor:
            widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: widget.enabled
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: widget.enabled
              ? () => setState(() => _isPressed = false)
              : null,
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Opacity(
              opacity: widget.enabled ? 1.0 : 0.45,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 16,
                    color: widget.isPrimary
                        ? AppColors.goldAccent
                        : AppColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricBadgePill extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _MetricBadgePill({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accentColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniStatChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _PressureSliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double optimalValue;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _PressureSliderRow({
    required this.label,
    required this.value,
    required this.optimalValue,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(1.30, 3.60),
            min: 1.30,
            max: 3.60,
            divisions: 46,
            activeColor: AppColors.accentBlue,
            inactiveColor: AppTheme.borderColor,
            onChanged: enabled ? onChanged : null,
          ),
        ),
        SizedBox(
          width: 82,
          child: Text(
            '${value.toStringAsFixed(2)} (opt ${optimalValue.toStringAsFixed(2)})',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _TelemetryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TelemetryCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _StepperChip extends StatelessWidget {
  final String label;
  final int value;
  final int minValue;
  final int maxValue;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _StepperChip({
    required this.label,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          InkWell(
            onTap: enabled && value > minValue
                ? () => onChanged(value - 1)
                : null,
            child: Icon(
              Icons.remove_circle_outline_rounded,
              size: 16,
              color: enabled && value > minValue
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.35),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$value',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          InkWell(
            onTap: enabled && value < maxValue
                ? () => onChanged(value + 1)
                : null,
            child: Icon(
              Icons.add_circle_outline_rounded,
              size: 16,
              color: enabled && value < maxValue
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}
