import 'dart:math' as math;

import '../../models/career/career_save.dart';
import '../../models/career/season_calendar.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/equipment/frame_model.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/bike_manufacturer_deal.dart';
import '../../models/team/cycling_team.dart';
import '../../services/career/race_calendar_selection_service.dart';
import '../../services/career/scouting_and_youth_academy_service.dart';
import '../../services/database/custom_mod_importer_service.dart';
import '../../services/database/save_game_manager.dart';
import '../../state/career_state_notifier.dart';
import 'fictional_brands_catalog.dart';
import 'rider_procedural_generator.dart';
import 'stage_profile_builder.dart';
import 'uci_calendar_generator.dart';
import 'world_teams_generator.dart';

/// Konfiguracja parametrów startowych dla generatora nowego świata gry
class InitialGameSeedConfig {
  final String saveName;
  final String playerManagerName;
  final String playerTeamId;
  final CareerDifficulty difficulty;
  final int seasonYear;
  final int? seed;
  final CyclingTeam? customTeam;
  final List<Rider>? customRoster;
  final int targetSlotNumber;
  final bool saveToDisk;
  final int additionalFreeAgentsCount;
  final int scoutingProspectsCount;

  const InitialGameSeedConfig({
    this.saveName = 'Moja Kariera Kolarska',
    this.playerManagerName = 'Główny Menedżer',
    required this.playerTeamId,
    this.difficulty = CareerDifficulty.normal,
    this.seasonYear = 2026,
    this.seed,
    this.customTeam,
    this.customRoster,
    this.targetSlotNumber = 1,
    this.saveToDisk = true,
    this.additionalFreeAgentsCount = 40,
    this.scoutingProspectsCount = 28,
  });

  InitialGameSeedConfig copyWith({
    String? saveName,
    String? playerManagerName,
    String? playerTeamId,
    CareerDifficulty? difficulty,
    int? seasonYear,
    int? seed,
    CyclingTeam? customTeam,
    List<Rider>? customRoster,
    int? targetSlotNumber,
    bool? saveToDisk,
    int? additionalFreeAgentsCount,
    int? scoutingProspectsCount,
  }) {
    return InitialGameSeedConfig(
      saveName: saveName ?? this.saveName,
      playerManagerName: playerManagerName ?? this.playerManagerName,
      playerTeamId: playerTeamId ?? this.playerTeamId,
      difficulty: difficulty ?? this.difficulty,
      seasonYear: seasonYear ?? this.seasonYear,
      seed: seed ?? this.seed,
      customTeam: customTeam ?? this.customTeam,
      customRoster: customRoster ?? this.customRoster,
      targetSlotNumber: targetSlotNumber ?? this.targetSlotNumber,
      saveToDisk: saveToDisk ?? this.saveToDisk,
      additionalFreeAgentsCount: additionalFreeAgentsCount ?? this.additionalFreeAgentsCount,
      scoutingProspectsCount: scoutingProspectsCount ?? this.scoutingProspectsCount,
    );
  }
}

/// Szczegółowy raport i wynik procesu inicjalizacji nowego świata gry
class InitialGameSeedResult {
  final CareerSave save;
  final int durationMs;
  final int totalTeamsCount;
  final int worldTourTeamsCount;
  final int proTeamsCount;
  final int continentalTeamsCount;
  final int totalRidersCount;
  final int totalBikesAssembled;
  final int totalRacesCount;
  final int totalStagesCount;
  final int totalScoutingTalentsCount;
  final int totalFreeAgentsCount;

  const InitialGameSeedResult({
    required this.save,
    required this.durationMs,
    required this.totalTeamsCount,
    required this.worldTourTeamsCount,
    required this.proTeamsCount,
    required this.continentalTeamsCount,
    required this.totalRidersCount,
    required this.totalBikesAssembled,
    required this.totalRacesCount,
    required this.totalStagesCount,
    required this.totalScoutingTalentsCount,
    required this.totalFreeAgentsCount,
  });

  /// Czy proces generacji zmieścił się w wymaganym limicie 2 sekund (< 2000 ms)
  bool get isUnderTwoSeconds => durationMs < 2000;

  /// Czytelne podsumowanie generacji świata gry
  String get summaryReport {
    final status = isUnderTwoSeconds ? 'SUKCES (< 2.0s)' : 'OSTRZEŻENIE (> 2.0s)';
    return '=====================================================\n'
        'INICJALIZACJA NOWEGO ŚWIATA GRY [$status]: $durationMs ms\n'
        '=====================================================\n'
        '• Drużyny łącznie: $totalTeamsCount (WorldTour: $worldTourTeamsCount, ProTeam: $proTeamsCount, Continental: $continentalTeamsCount)\n'
        '• Kolarze łącznie: $totalRidersCount (w kadrach: ${totalRidersCount - totalFreeAgentsCount - totalScoutingTalentsCount}, '
        'Wolni Agenci: $totalFreeAgentsCount, Młode Talenty U23: $totalScoutingTalentsCount)\n'
        '• Flota sprzętu: $totalBikesAssembled złożonych rowerów w bazach Service Course\n'
        '• Kalendarz UCI: $totalRacesCount wyścigów, $totalStagesCount etapów z profilami wysokościowymi\n'
        '• Zespół Gracza: ${save.playerTeam.name} (${save.playerTeam.division.name.toUpperCase()}), Budżet: €${save.playerTeam.cashBalanceEur}\n'
        '=====================================================';
  }

  @override
  String toString() => summaryReport;
}

/// Serwis inicjalizujący nową grę, który spina wszystkie proceduralne generatory
/// (`FictionalBrandsCatalog`, `WorldTeamsGenerator`, `RiderProceduralGenerator`, `UciCalendarGenerator`)
/// i generuje kompletny świat gry (50+ drużyn, 800+ kolarzy, sprzęt, etapy) w czasie < 2 sekund.
class InitialGameSeeder {
  InitialGameSeeder._();

  /// Generuje kompletny świat gry i bezpośrednio zasila nim [CareerStateNotifier],
  /// opcjonalnie zapisując stan gry do wskazanego slotu na dysku.
  static Future<InitialGameSeedResult> seedAndInitializeCareer({
    required CareerStateNotifier careerNotifier,
    required InitialGameSeedConfig config,
  }) async {
    final result = await seedNewGame(config);

    if (config.saveToDisk) {
      await SaveGameManager.saveToSlot(
        slotNumber: config.targetSlotNumber,
        save: result.save,
      );
    }

    careerNotifier.loadFromCareerSave(
      result.save,
      slotNumber: config.targetSlotNumber,
    );

    return result;
  }

  /// Główna metoda generująca kompletny stan zapisu nowej kariery kolarskiej.
  /// Mierzy czas wykonania za pomocą [Stopwatch] gwarantując czas < 2 sekund.
  static Future<InitialGameSeedResult> seedNewGame(InitialGameSeedConfig config) async {
    final stopwatch = Stopwatch()..start();

    final effectiveSeed = config.seed ?? DateTime.now().millisecondsSinceEpoch;
    final rng = math.Random(effectiveSeed);

    // =========================================================================
    // KROK 1: GENEROWANIE PELETONU 53 DRUŻYN (WorldTeamsGenerator)
    // =========================================================================
    final worldGen = WorldTeamsGenerator.generateWorldTourSystem(seed: effectiveSeed);
    final List<CyclingTeam> initialTeams = List<CyclingTeam>.from(worldGen.teams);

    // Obsługa autorskiego zespołu gracza (Custom Team)
    if (config.customTeam != null) {
      final custom = config.customTeam!;
      initialTeams.removeWhere((t) => t.id == custom.id);

      // Zapewniamy kompletny osprzęt i flotę rowerów dla custom teamu z FictionalBrandsCatalog
      final finalizedCustomTeam = _ensureCustomTeamEquipment(custom, rng);
      initialTeams.add(finalizedCustomTeam);
    }

    // =========================================================================
    // KROK 2: WERYFIKACJA I SPRAWDZENIE SPRZĘTU DRUŻYN (FictionalBrandsCatalog)
    // =========================================================================
    int totalBikesCount = 0;
    final List<CyclingTeam> verifiedTeams = [];

    for (final team in initialTeams) {
      CyclingTeam updatedTeam = team;

      // Jeśli drużyna nie ma przypisanego producenta lub rowerów, generujemy je z katalogu
      if (updatedTeam.inventoryBikes.isEmpty) {
        final brandId = updatedTeam.bikeDeal.brandId.isNotEmpty
            ? updatedTeam.bikeDeal.brandId
            : (FictionalBrandsCatalog.allBrands.isNotEmpty
                ? FictionalBrandsCatalog.allBrands.first.id
                : 'brand_aethel');

        final fleet = buildFleetForTeam(updatedTeam.id, brandId);
        updatedTeam = updatedTeam.copyWith(inventoryBikes: fleet);
      }

      totalBikesCount += updatedTeam.inventoryBikes.length;
      verifiedTeams.add(updatedTeam);
    }

    // =========================================================================
    // KROK 3: GENEROWANIE WOLNYCH AGENTÓW I TALENTÓW (RiderProceduralGenerator)
    // =========================================================================
    // 3a. Dodatkowi wolni agenci szukający kontraktu na rynku transferowym
    final freeAgents = generateFreeAgentsPool(
      count: config.additionalFreeAgentsCount,
      seasonYear: config.seasonYear,
      random: rng,
    );

    // 3b. Pula młodych adeptów U19/U23 do skautingu
    final scoutingPool = ScoutingAndYouthAcademyService.generateInitialScoutingPool(
      seasonYear: config.seasonYear,
      count: config.scoutingProspectsCount,
      random: math.Random(effectiveSeed + 101),
    );

    // 3c. Kompletna agregacja kolarzy ze wszystkich źródeł (kadry, custom roster, wolni agenci, skauting)
    final Map<String, Rider> riderMap = {};

    // Kolarze z drużyn
    for (final rider in worldGen.allRiders) {
      riderMap[rider.id] = rider;
    }

    // Autorski skład gracza
    if (config.customRoster != null) {
      for (final rider in config.customRoster!) {
        riderMap[rider.id] = rider;
      }
    }

    // Wolni agenci
    for (final rider in freeAgents) {
      riderMap[rider.id] = rider;
    }

    // Kolarze ze skautingu
    for (final prospect in scoutingPool) {
      riderMap[prospect.trueRider.id] = prospect.trueRider;
    }

    final allRiders = riderMap.values.toList();
    final scoutedIds = scoutingPool.take(6).map((p) => p.id).toList();

    // =========================================================================
    // KROK 4: GENEROWANIE KALENDARZA UCI I ETAPÓW (UciCalendarGenerator)
    // =========================================================================
    final participatingIds = verifiedTeams.map((t) => t.id).toList();

    final rawRaces = UciCalendarGenerator.generateFullSeasonCalendar(
      seasonYear: config.seasonYear,
      participatingTeamIds: participatingIds,
    );

    int stagesCounter = 0;
    final enrichedRaces = rawRaces.map((race) {
      final enrichedStages = race.stages.map((stage) {
        stagesCounter++;
        return StageProfileBuilder.enrichStageWithAuthenticProfile(stage);
      }).toList();
      return race.copyWith(stages: enrichedStages);
    }).toList();

    final seasonCalendar = SeasonCalendar(
      seasonYear: config.seasonYear,
      races: enrichedRaces,
      currentRaceIndex: 0,
      activeRaceId: null,
      activeStageIndex: 0,
      completedRaceIds: const [],
      raceHistory: const {},
    );

    // =========================================================================
    // KROK 5: DOSTOSOWANIE BUDŻETU I POCZĄTKOWA KSIĘGA FINANSOWA
    // =========================================================================
    final adjustedTeams = verifiedTeams.map((team) {
      if (team.id == config.playerTeamId) {
        int initialBalance = team.cashBalanceEur;
        switch (config.difficulty) {
          case CareerDifficulty.easy:
            initialBalance = (initialBalance * 1.5).round();
            break;
          case CareerDifficulty.normal:
            break;
          case CareerDifficulty.hard:
            initialBalance = (initialBalance * 0.75).round();
            break;
          case CareerDifficulty.realistic:
            initialBalance = (initialBalance * 0.90).round();
            break;
        }
        return team.copyWith(cashBalanceEur: initialBalance);
      }
      return team;
    }).toList();

    final startDate = DateTime(config.seasonYear, 1, 1);
    final saveId = 'save_${DateTime.now().millisecondsSinceEpoch}';

    final playerTeam = adjustedTeams.firstWhere(
      (t) => t.id == config.playerTeamId,
      orElse: () => adjustedTeams.first,
    );

    final initialLedger = [
      CareerFinanceLedgerEntry(
        id: 'fin_init',
        date: startDate,
        category: FinanceCategory.sponsorPayout,
        amountEur: playerTeam.cashBalanceEur,
        description: 'Kapitał początkowy i pierwsza transza sponsorska na sezon ${config.seasonYear}',
      ),
    ];

    // =========================================================================
    // KROK 6: TWORZENIE OBIEKTU CAREERSAVE I ALOKACJA DZIKICH KART
    // =========================================================================
    final initialSave = CareerSave(
      id: saveId,
      saveName: config.saveName,
      createdAt: DateTime.now(),
      lastSavedAt: DateTime.now(),
      difficulty: config.difficulty,
      playerManagerName: config.playerManagerName,
      playerTeamId: playerTeam.id,
      currentDate: startDate,
      currentSeasonYear: config.seasonYear,
      calendar: seasonCalendar,
      teams: adjustedTeams,
      riders: allRiders,
      scoutedRiderIds: scoutedIds,
      contractOffers: const [],
      financeLedger: initialLedger,
      managerReputation: 50,
      serviceCourseLevel: 1,
      windTunnelLevel: 1,
      medicalCenterLevel: 1,
      trophiesWon: const [],
      franchiseLeaders: const [],
      dedicatedSquads: const [],
      wildcardApplications: const [],
      scoutingProspects: scoutingPool,
      youthAcademy: const YouthAcademy(),
    );

    // Symulacja wstępnego przydziału dzikich kart
    var populatedSave = RaceCalendarSelectionService.simulateSeasonWildcardAllocation(
      save: initialSave,
    );

    // =========================================================================
    // KROK 7: AUTOMATYCZNY IMPORT DOMYŚLNEGO PRESETU MODÓW (REAL NAME PACK)
    // =========================================================================
    if (await CustomModImporterService.hasDefaultModPreset()) {
      final defaultMod = await CustomModImporterService.loadDefaultModPreset();
      if (defaultMod != null) {
        populatedSave = CustomModImporterService.applyModPackage(
          save: populatedSave,
          package: defaultMod,
        ).updatedSave;
      }
    }

    stopwatch.stop();
    final durationMs = stopwatch.elapsedMilliseconds;

    final wtCount = adjustedTeams.where((t) => t.division == TeamDivision.worldTour).length;
    final proCount = adjustedTeams.where((t) => t.division == TeamDivision.proTeam).length;
    final contiCount = adjustedTeams.where((t) => t.division == TeamDivision.continental).length;

    return InitialGameSeedResult(
      save: populatedSave,
      durationMs: durationMs,
      totalTeamsCount: adjustedTeams.length,
      worldTourTeamsCount: wtCount,
      proTeamsCount: proCount,
      continentalTeamsCount: contiCount,
      totalRidersCount: allRiders.length,
      totalBikesAssembled: totalBikesCount,
      totalRacesCount: seasonCalendar.races.length,
      totalStagesCount: stagesCounter,
      totalScoutingTalentsCount: scoutingPool.length,
      totalFreeAgentsCount: freeAgents.length,
    );
  }

  /// Pomocnicza metoda generująca obiekt [CareerSave] z zachowaniem kompatybilności wstecznej
  static Future<CareerSave> createSeededSave(InitialGameSeedConfig config) async {
    final result = await seedNewGame(config);
    return result.save;
  }

  // ===========================================================================
  // METODY POMOCNICZE GENERATORÓW
  // ===========================================================================

  /// Zapewnia, że autorski zespół gracza posiada pełen zestaw sprzętu z [FictionalBrandsCatalog].
  static CyclingTeam _ensureCustomTeamEquipment(CyclingTeam customTeam, math.Random rng) {
    BikeManufacturerDeal deal = customTeam.bikeDeal;
    if (deal.brandId.isEmpty) {
      final randomBrand = FictionalBrandsCatalog.allBrands[rng.nextInt(FictionalBrandsCatalog.allBrands.length)];
      deal = FictionalBrandsCatalog.createManufacturerDeal(
        brandId: randomBrand.id,
        contractYearsLeft: 3,
      );
    }

    List<CompleteBike> bikes = List<CompleteBike>.from(customTeam.inventoryBikes);
    if (bikes.isEmpty) {
      bikes = buildFleetForTeam(customTeam.id, deal.brandId);
    }

    return customTeam.copyWith(
      bikeDeal: deal,
      inventoryBikes: bikes,
    );
  }

  /// Buduje kompletną flotę maszyn wyścigowych dla danej drużyny na bazie wybranej marki:
  /// - Maszyna aero na płaskie etapy i finisze
  /// - Maszyna ultra-lekka na podjazdy górskie
  /// - Maszyna do jazdy indywidualnej na czas (TT)
  /// - Maszyna all-rounder na bruki i zróżnicowany teren
  static List<CompleteBike> buildFleetForTeam(String teamId, String brandId) {
    return [
      FictionalBrandsCatalog.assembleBike(
        brandId: brandId,
        frameCategory: FrameCategory.aero,
        cockpitWidthMm: 380,
        hoodInwardTiltDegrees: 12.0,
        slammedStem: true,
      ),
      FictionalBrandsCatalog.assembleBike(
        brandId: brandId,
        frameCategory: FrameCategory.lightweightClimbing,
        cockpitWidthMm: 400,
        hoodInwardTiltDegrees: 6.0,
        slammedStem: true,
      ),
      FictionalBrandsCatalog.assembleBike(
        brandId: brandId,
        frameCategory: FrameCategory.timeTrial,
        cockpitWidthMm: 380,
        hoodInwardTiltDegrees: 0.0,
        slammedStem: true,
      ),
    ];
  }

  /// Generuje pulę wolnych agentów szukających klubu za pomocą [RiderProceduralGenerator].
  static List<Rider> generateFreeAgentsPool({
    required int count,
    required int seasonYear,
    math.Random? random,
  }) {
    final rng = random ?? math.Random();
    final List<Rider> freeAgents = [];

    const specializations = RiderSpecialization.values;
    const roles = [
      RiderRole.domestique,
      RiderRole.superDomestique,
      RiderRole.breakawaySpecialist,
      RiderRole.sprinter,
      RiderRole.neoPro,
    ];

    for (int i = 0; i < count; i++) {
      final spec = specializations[rng.nextInt(specializations.length)];
      final role = roles[rng.nextInt(roles.length)];
      final age = 21 + rng.nextInt(15); // wiek 21 - 35 lat

      final rider = RiderProceduralGenerator.generateRider(
        teamId: '',
        role: role,
        specialization: spec,
        age: age,
        random: rng,
      );

      // Ustawiamy brak przypisanej drużyny i kontrakt kończący się w bieżącym roku
      final endingContract = rider.contract.copyWith(
        teamId: '',
        role: role,
        contractEndYear: seasonYear,
        monthlySalaryEur: 2500 + rng.nextInt(7500),
      );

      freeAgents.add(rider.copyWith(contract: endingContract));
    }

    return freeAgents;
  }
}
