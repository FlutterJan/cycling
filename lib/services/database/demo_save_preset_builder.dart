import 'dart:math' as math;

import '../../models/career/career_save.dart';
import '../../models/career/season_calendar.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/bike_manufacturer_deal.dart';
import '../../models/team/cycling_team.dart';
import '../../models/team/sponsor_contract.dart';
import '../career/race_calendar_selection_service.dart';
import '../career/team_chemistry_and_builder_service.dart';
import '../generators/fictional_brands_catalog.dart';
import '../generators/initial_game_seeder.dart';
import '../generators/rider_procedural_generator.dart';

/// Identyfikator predefiniowanego scenariusza szybkiego startu kariery.
enum DemoSavePresetType {
  /// 1. Ambitna polska ekipa ProTeam walcząca o Dziką Kartę na Wielką Pętlę.
  polishWorldTourProject,

  /// 2. Zapis bezpośrednio przed 18. etapem alpejskim Wielkiego Touru (-14s do lidera).
  alpineTitansDuel,

  /// 3. Kwiecień — tydzień dwóch brukowanych Monumentów w deszczowej Belgii i Francji.
  cobbledCampaign,

  /// 4. Najbogatsza drużyna świata (45 mln EUR) z 3 gwiazdami i celem Potrójnej Korony GT.
  galacticEmpire;

  String toJson() => name;

  static DemoSavePresetType fromJson(String value) {
    return DemoSavePresetType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DemoSavePresetType.polishWorldTourProject,
    );
  }

  /// Czytelna nazwa scenariusza w interfejsie użytkownika.
  String get label {
    switch (this) {
      case DemoSavePresetType.polishWorldTourProject:
        return 'Polski Projekt WorldTour';
      case DemoSavePresetType.alpineTitansDuel:
        return 'Pojedynek Tytanów w Alpach';
      case DemoSavePresetType.cobbledCampaign:
        return 'Kampania Brukowana';
      case DemoSavePresetType.galacticEmpire:
        return 'Imperium Galaktyczne';
    }
  }
}

/// Metadane pojedynczego scenariusza szybkiego startu wyświetlane w kreatorze/menu.
class DemoSavePresetInfo {
  final DemoSavePresetType type;
  final String title;
  final String subtitle;
  final String description;
  final String teamName;
  final TeamDivision division;
  final int budgetEur;
  final String startDateLabel;
  final CareerDifficulty difficulty;
  final String difficultyBadge;
  final List<String> keyHighlights;
  final String accentHex;

  const DemoSavePresetInfo({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.teamName,
    required this.division,
    required this.budgetEur,
    required this.startDateLabel,
    required this.difficulty,
    required this.difficultyBadge,
    required this.keyHighlights,
    required this.accentHex,
  });
}

/// Builder generujący 4 gotowe, bogate w detale scenariusze startowe
/// ("Scenariusze Szybkiego Startu Kariery"), pozwalające graczowi od razu
/// wskoczyć w środek sezonu kolarskiego bez rozpoczynania od 1 stycznia.
class DemoSavePresetBuilder {
  DemoSavePresetBuilder._();

  /// Katalog metadanych wszystkich 4 scenariuszy szybkiego startu.
  static const List<DemoSavePresetInfo> presets = [
    DemoSavePresetInfo(
      type: DemoSavePresetType.polishWorldTourProject,
      title: 'Polski Projekt WorldTour',
      subtitle: 'Ekipa ProTeam • Budżet 8 mln EUR • Walka o Dziką Kartę',
      description:
          'Prowadzisz ambitną polską ekipę ProTeam z budżetem 8 mln EUR i '
          'pokoleniowym talentem górskim z Tatr. Zdobądź punkty UCI i przekonaj '
          'organizatorów do przyznania Dzikiej Karty na Wielką Pętlę.',
      teamName: 'Tatry Orlen Pro Cycling',
      division: TeamDivision.proTeam,
      budgetEur: 8000000,
      startDateLabel: '15 marca',
      difficulty: CareerDifficulty.hard,
      difficultyBadge: 'WYZWANIE PRO',
      keyHighlights: [
        'Budżet 8 000 000 € i status UCI ProTeam',
        '20-letni czysty góral z Tatr (Potencjał 96)',
        'Oczekujący wniosek o Dziką Kartę na Tour de France',
        'Główny cel: Tour de Pologne i awans do WorldTour',
      ],
      accentHex: '#8E4A49',
    ),
    DemoSavePresetInfo(
      type: DemoSavePresetType.alpineTitansDuel,
      title: 'Pojedynek Tytanów w Alpach',
      subtitle: '18. etap Wielkiego Touru • 3 przełęcze >2000m • Strata 14s',
      description:
          'Wskakujesz prosto do autobusu drużyny przed królewskim 18. etapem '
          'Wielkiego Touru. Trzy gigantyczne przełęcze powyżej 2000 m n.p.m., '
          'a Twój lider traci zaledwie 14 sekund do żółtej koszulki!',
      teamName: 'Apex Alpine Pro Cycling',
      division: TeamDivision.worldTour,
      budgetEur: 22000000,
      startDateLabel: '18 lipca',
      difficulty: CareerDifficulty.normal,
      difficultyBadge: 'KRYTYCZNY ETAP',
      keyHighlights: [
        'Bezpośrednio przed 18. etapem Tour de France',
        '3 przełęcze >2000 m n.p.m. (Croix de Fer, Galibier, Alpe d\'Huez)',
        '2. miejsce w GC — zaledwie 14 sekund za liderem',
        'Zmęczenie 3. tygodnia i gotowa taktyka ataku w górach',
      ],
      accentHex: '#D4AF37',
    ),
    DemoSavePresetInfo(
      type: DemoSavePresetType.cobbledCampaign,
      title: 'Kampania Brukowana',
      subtitle: 'Kwiecień • Flandria & Paryż-Roubaix • Deszcz i bruk',
      description:
          'Kwiecień w północnej Europie. Twój zespół flamandzkich specjalistów '
          'od klasyków staje przed decydującym tygodniem dwóch brukowanych '
          'Monumentów w ulewnym deszczu i bocznym wietrze.',
      teamName: 'Vlaanderen Lion Classics',
      division: TeamDivision.worldTour,
      budgetEur: 18500000,
      startDateLabel: '2 kwietnia',
      difficulty: CareerDifficulty.normal,
      difficultyBadge: 'PIEKIELNY BRUK',
      keyHighlights: [
        'Tydzień prawdy: Ronde van Vlaanderen oraz Paris-Roubaix',
        'Deszczowa aura, 8.5°C i boczny wiatr >28 km/h',
        'Skład naszpikowany specjalistami od bruku (OVR 85–91)',
        'Presja belgijskiego sponsora na wygranie Monumentu',
      ],
      accentHex: '#38BDF8',
    ),
    DemoSavePresetInfo(
      type: DemoSavePresetType.galacticEmpire,
      title: 'Imperium Galaktyczne',
      subtitle: 'Budżet 45 mln EUR • 3 Supergwiazdy • Potrójna Korona GT',
      description:
          'Zarządzasz najbogatszą drużyną świata z budżetem 45 mln EUR i trzema '
          'supergwiazdami w składzie. Musisz pogodzić ich wielkie ego, podzielić '
          'role liderów i wygrać wszystkie 3 Grand Toury w jednym sezonie.',
      teamName: 'Galacticos Emirates WorldTour',
      division: TeamDivision.worldTour,
      budgetEur: 45000000,
      startDateLabel: '1 lutego',
      difficulty: CareerDifficulty.realistic,
      difficultyBadge: 'GALAKTYCZNE EGO',
      keyHighlights: [
        'Najwyższy budżet w peletonie: 45 000 000 €',
        '3 supergwiazdy (OVR 91–94) z niską lojalnością i dużym ego',
        '3 dedykowane pociągi na Giro, Tour i Vueltę',
        'Cel sponsora: Zwycięstwo we wszystkich 3 Grand Tourach',
      ],
      accentHex: '#10B981',
    ),
  ];

  /// Zwraca metadane dla wybranego typu scenariusza.
  static DemoSavePresetInfo getInfo(DemoSavePresetType type) {
    return presets.firstWhere((p) => p.type == type);
  }

  /// Buduje kompletny, gotowy do gry zapis [CareerSave] dla wybranego scenariusza.
  static Future<CareerSave> buildPreset(
    DemoSavePresetType type, {
    int seasonYear = 2026,
    String playerManagerName = 'Dyrektor Sportowy',
    int? seed,
  }) async {
    final effectiveSeed = seed ?? (192000 + type.index * 777);
    switch (type) {
      case DemoSavePresetType.polishWorldTourProject:
        return _buildPolishWorldTourProject(
          seasonYear: seasonYear,
          playerManagerName: playerManagerName,
          seed: effectiveSeed,
        );
      case DemoSavePresetType.alpineTitansDuel:
        return _buildAlpineTitansDuel(
          seasonYear: seasonYear,
          playerManagerName: playerManagerName,
          seed: effectiveSeed,
        );
      case DemoSavePresetType.cobbledCampaign:
        return _buildCobbledCampaign(
          seasonYear: seasonYear,
          playerManagerName: playerManagerName,
          seed: effectiveSeed,
        );
      case DemoSavePresetType.galacticEmpire:
        return _buildGalacticEmpire(
          seasonYear: seasonYear,
          playerManagerName: playerManagerName,
          seed: effectiveSeed,
        );
    }
  }

  /// Buduje wszystkie 4 scenariusze naraz (np. na potrzeby testów lub pre-cache).
  static Future<Map<DemoSavePresetType, CareerSave>> buildAllPresets({
    int seasonYear = 2026,
    String playerManagerName = 'Dyrektor Sportowy',
    int? seed,
  }) async {
    final Map<DemoSavePresetType, CareerSave> result = {};
    for (final type in DemoSavePresetType.values) {
      result[type] = await buildPreset(
        type,
        seasonYear: seasonYear,
        playerManagerName: playerManagerName,
        seed: seed != null ? seed + type.index * 100 : null,
      );
    }
    return result;
  }

  // ===========================================================================
  // SCENARIUSZ 1: POLSKI PROJEKT WORLDTOUR
  // ===========================================================================

  static Future<CareerSave> _buildPolishWorldTourProject({
    required int seasonYear,
    required String playerManagerName,
    required int seed,
  }) async {
    const teamId = 'team_pl_tatry_pro';
    final rng = math.Random(seed);

    // 1. Tworzenie składu: młody talent górski z Tatr + polski trzon ProTeam
    final tatraClimber = _customizeRider(
      RiderProceduralGenerator.generateRider(
        id: 'rider_pl_tatra_diamond',
        nationalityIso: 'POL',
        specialization: RiderSpecialization.pureClimber,
        age: 20,
        targetOverallRating: 82,
        teamId: teamId,
        role: RiderRole.teamLeader,
        random: rng,
      ),
      firstName: 'Kacper',
      lastName: 'Bachleda-Curuś',
      potential: 96,
      morale: 92.0,
      leaderLoyalty: 95.0,
      monthlySalaryEur: 28000,
    );

    final polishCaptain = _customizeRider(
      RiderProceduralGenerator.generateRider(
        id: 'rider_pl_road_captain',
        nationalityIso: 'POL',
        specialization: RiderSpecialization.puncher,
        age: 29,
        targetOverallRating: 80,
        teamId: teamId,
        role: RiderRole.coLeader,
        random: rng,
      ),
      firstName: 'Michał',
      lastName: 'Kowalski',
      potential: 82,
      morale: 86.0,
      leaderLoyalty: 90.0,
    );

    final polishSprinter = _customizeRider(
      RiderProceduralGenerator.generateRider(
        id: 'rider_pl_sprinter',
        nationalityIso: 'POL',
        specialization: RiderSpecialization.pureSprinter,
        age: 25,
        targetOverallRating: 79,
        teamId: teamId,
        role: RiderRole.sprinter,
        random: rng,
      ),
      firstName: 'Szymon',
      lastName: 'Banaszek',
      potential: 84,
      morale: 84.0,
      leaderLoyalty: 85.0,
    );

    final supportSpecs = <RiderSpecialization>[
      RiderSpecialization.gcClimber,
      RiderSpecialization.pureClimber,
      RiderSpecialization.timeTrialist,
      RiderSpecialization.classicCobbles,
      RiderSpecialization.classicCobbles,
      RiderSpecialization.breakawaySpecialist,
      RiderSpecialization.domestiqueEngine,
      RiderSpecialization.domestiqueEngine,
      RiderSpecialization.domestiqueEngine,
      RiderSpecialization.versatileSprinter,
      RiderSpecialization.domestiqueEngine,
    ];

    final roster = <Rider>[
      tatraClimber,
      polishCaptain,
      polishSprinter,
      for (int i = 0; i < supportSpecs.length; i++)
        RiderProceduralGenerator.generateRider(
          id: 'rider_pl_support_$i',
          nationalityIso: i < 7 ? 'POL' : (i % 2 == 0 ? 'CZE' : 'SVK'),
          specialization: supportSpecs[i],
          age: 21 + (i % 9),
          targetOverallRating: 72 + (i % 6),
          teamId: teamId,
          role: i < 2 ? RiderRole.superDomestique : RiderRole.domestique,
          random: rng,
        ),
    ];

    final tdfId = 'race_tour_de_france_$seasonYear';
    final tdpId = 'race_tour_de_pologne_$seasonYear';

    final customTeam = CyclingTeam(
      id: teamId,
      name: 'Tatry Orlen Pro Cycling',
      division: TeamDivision.proTeam,
      countryIso: 'POL',
      primaryJerseyColorHex: '#DC143C',
      secondaryJerseyColorHex: '#F3F4F6',
      accentJerseyColorHex: '#D4AF37',
      cashBalanceEur: 8000000,
      monthlyBurnRateEur: 420000,
      uciPointsSeason: 1420,
      rosterRiderIds: roster.map((r) => r.id).toList(),
      staff: const TeamStaff(
        trainersLevel: 76,
        sportsDirectorsLevel: 78,
        doctorsLevel: 74,
        mechanicsLevel: 75,
        scoutsLevel: 82,
      ),
      bikeDeal: _buildBikeDeal(prestigeLevel: 3, cashContributionEur: 450000),
      sponsors: const [
        SponsorContract(
          id: 'sp_orlen_pl',
          companyName: 'Orlen Petrochemia',
          industry: SponsorIndustry.energy,
          sponsorTier: SponsorTier.titlePrimary,
          annualBudgetEur: 5500000,
          contractDurationYears: 3,
          sponsorSatisfaction: 78.0,
          objectives: [
            SponsorObjective(
              id: 'obj_pl_tdf_wc',
              description: 'Zdobyć Dziką Kartę i ukończyć La Grande Boucle de France',
              bonusPaymentEur: 850000,
              importance: ObjectiveImportance.critical,
              isCompleted: false,
              currentProgress: 0.5,
              targetProgress: 1.0,
            ),
            SponsorObjective(
              id: 'obj_pl_tdp_win',
              description: 'Wygrać etap lub podium GC w Tour de Pologne',
              bonusPaymentEur: 450000,
              importance: ObjectiveImportance.high,
              isCompleted: false,
              currentProgress: 0.0,
              targetProgress: 1.0,
            ),
            SponsorObjective(
              id: 'obj_pl_pro_rank',
              description: 'Utrzymać miejsce w Top 3 najlepszych drużyn ProTeam UCI',
              bonusPaymentEur: 350000,
              importance: ObjectiveImportance.medium,
              isCompleted: false,
              currentProgress: 1420.0,
              targetProgress: 2800.0,
            ),
          ],
        ),
        SponsorContract(
          id: 'sp_ccc_pl',
          companyName: 'CCC Grupa Obuwnicza',
          industry: SponsorIndustry.apparel,
          sponsorTier: SponsorTier.titleSecondary,
          annualBudgetEur: 2500000,
          contractDurationYears: 2,
          sponsorSatisfaction: 82.0,
          objectives: [],
        ),
      ],
      inventoryBikes: const [],
    );

    final baseSave = await _seedWorldWithCustomTeam(
      saveName: 'Polski Projekt WorldTour',
      playerManagerName: playerManagerName,
      customTeam: customTeam,
      customRoster: roster,
      difficulty: CareerDifficulty.hard,
      seasonYear: seasonYear,
      seed: seed,
      exactBudgetEur: 8000000,
    );

    final scenarioDate = DateTime(seasonYear, 3, 15);
    final updatedCalendar = _advanceCalendarToDate(
      baseSave.calendar,
      targetDate: scenarioDate,
      seasonYear: seasonYear,
      allTeams: baseSave.teams,
      allRiders: baseSave.riders,
    );

    final wildcardApps = [
      WildcardApplication(
        id: 'wc_pl_tdf_$seasonYear',
        raceId: tdfId,
        raceName: 'La Grande Boucle de France Grand Tour',
        teamId: teamId,
        teamName: customTeam.name,
        applicationDate: DateTime(seasonYear, 2, 10),
        status: WildcardStatus.pending,
        overallScore: 76.5,
        rankingScore: 74.0,
        nationalityScore: 68.0,
        combativityScore: 84.0,
        rosterStarScore: 80.0,
        directorQuote:
            'Młody góral z Zakopanego może rozgrzać Alpy i Pireneje — dajcie nam szansę na wielkiej scenie!',
        officialLetter:
            'Komitet Organizacyjny ASO informuje, że Tatry Orlen Pro Cycling znajduje się na krótkiej liście do ostatniej Dzikiej Karty na La Grande Boucle.',
      ),
      WildcardApplication(
        id: 'wc_pl_tdp_$seasonYear',
        raceId: tdpId,
        raceName: 'Tour de Pologne UCI WorldTour',
        teamId: teamId,
        teamName: customTeam.name,
        applicationDate: DateTime(seasonYear, 1, 20),
        status: WildcardStatus.granted,
        overallScore: 95.0,
        rankingScore: 88.0,
        nationalityScore: 100.0,
        combativityScore: 92.0,
        rosterStarScore: 85.0,
        directorQuote: 'Domowy wyścig to nasze absolutne oczko w głowie.',
        officialLetter:
            'Organizator Tour de Pologne z dumą przyznaje polskiemu zespołowi oficjalną Dziką Kartę.',
        decisionDate: DateTime(seasonYear, 2, 1),
      ),
    ];

    return baseSave.copyWith(
      currentDate: scenarioDate,
      calendar: updatedCalendar,
      managerReputation: 58,
      serviceCourseLevel: 2,
      windTunnelLevel: 2,
      medicalCenterLevel: 2,
      wildcardApplications: wildcardApps,
      franchiseLeaders: [
        FranchiseRider(
          riderId: tatraClimber.id,
          riderName: tatraClimber.fullName,
          focus: FranchiseRoleFocus.grandTourGc,
          priorityRank: 1,
          designatedSquadId: 'squad_pl_tatry_gt',
        ),
      ],
      dedicatedSquads: [
        DedicatedSquad(
          id: 'squad_pl_tatry_gt',
          name: 'Pociąg Górski Tatry (Wielka Pętla)',
          leaderRiderId: tatraClimber.id,
          domestiqueRiderIds: roster
              .where((r) => r.id != tatraClimber.id)
              .take(7)
              .map((r) => r.id)
              .toList(),
          targetSeasonObjective: 'Walka o Dziką Kartę i koszulkę młodzieżową TdF',
          sharedRacesCount: 3,
          sharedStagesCount: 14,
          trainingCampsCount: 1,
          cohesionScore: 68.0,
        ),
      ],
      financeLedger: [
        CareerFinanceLedgerEntry(
          id: 'fin_pl_init',
          date: scenarioDate,
          category: FinanceCategory.sponsorPayout,
          amountEur: 8000000,
          description: 'Budżet operacyjny Tatry Orlen Pro Cycling (8 mln EUR)',
        ),
      ],
    );
  }

  // ===========================================================================
  // SCENARIUSZ 2: POJEDYNEK TYTANÓW W ALPACH (18. ETAP GT, -14s DO ŻÓŁTEJ)
  // ===========================================================================

  static Future<CareerSave> _buildAlpineTitansDuel({
    required int seasonYear,
    required String playerManagerName,
    required int seed,
  }) async {
    const teamId = 'team_wt_alpine_titans';
    final rng = math.Random(seed);

    final gcLeader = _customizeRider(
      RiderProceduralGenerator.generateRider(
        id: 'rider_alpine_gc_leader',
        nationalityIso: 'SLO',
        specialization: RiderSpecialization.gcClimber,
        age: 26,
        targetOverallRating: 91,
        teamId: teamId,
        role: RiderRole.teamLeader,
        random: rng,
      ),
      firstName: 'Luka',
      lastName: 'Kovačič',
      potential: 95,
      morale: 88.0,
      leaderLoyalty: 92.0,
      acuteLoad: 128.0,
      chronicLoad: 112.0,
    );

    final mountainLieutenants = [
      RiderProceduralGenerator.generateRider(
        id: 'rider_alpine_dom_1',
        nationalityIso: 'ESP',
        specialization: RiderSpecialization.pureClimber,
        age: 27,
        targetOverallRating: 85,
        teamId: teamId,
        role: RiderRole.superDomestique,
        random: rng,
      ).copyWith(
        health: gcLeader.health.copyWith(acuteTrainingLoad: 122.0, chronicTrainingLoad: 108.0),
      ),
      RiderProceduralGenerator.generateRider(
        id: 'rider_alpine_dom_2',
        nationalityIso: 'COL',
        specialization: RiderSpecialization.pureClimber,
        age: 24,
        targetOverallRating: 84,
        teamId: teamId,
        role: RiderRole.superDomestique,
        random: rng,
      ).copyWith(
        health: gcLeader.health.copyWith(acuteTrainingLoad: 120.0, chronicTrainingLoad: 106.0),
      ),
    ];

    final remainingRoster = <Rider>[
      for (int i = 0; i < 19; i++)
        RiderProceduralGenerator.generateRider(
          id: 'rider_alpine_wt_$i',
          specialization: i < 5
              ? RiderSpecialization.gcClimber
              : (i < 10 ? RiderSpecialization.domestiqueEngine : RiderSpecialization.puncher),
          age: 22 + (i % 10),
          targetOverallRating: 76 + (i % 7),
          teamId: teamId,
          role: i < 5 ? RiderRole.domestique : RiderRole.domestique,
          random: rng,
        ),
    ];

    final roster = [gcLeader, ...mountainLieutenants, ...remainingRoster];

    final customTeam = CyclingTeam(
      id: teamId,
      name: 'Apex Alpine Pro Cycling',
      division: TeamDivision.worldTour,
      countryIso: 'SUI',
      primaryJerseyColorHex: '#1E293B',
      secondaryJerseyColorHex: '#D4AF37',
      accentJerseyColorHex: '#38BDF8',
      cashBalanceEur: 22000000,
      monthlyBurnRateEur: 1450000,
      uciPointsSeason: 8950,
      rosterRiderIds: roster.map((r) => r.id).toList(),
      staff: const TeamStaff(
        trainersLevel: 90,
        sportsDirectorsLevel: 92,
        doctorsLevel: 89,
        mechanicsLevel: 88,
        scoutsLevel: 85,
      ),
      bikeDeal: _buildBikeDeal(prestigeLevel: 5, cashContributionEur: 1800000),
      sponsors: const [
        SponsorContract(
          id: 'sp_apex_alpine',
          companyName: 'Apex Swiss Precision',
          industry: SponsorIndustry.tech,
          sponsorTier: SponsorTier.titlePrimary,
          annualBudgetEur: 22000000,
          contractDurationYears: 3,
          sponsorSatisfaction: 86.0,
          objectives: [
            SponsorObjective(
              id: 'obj_alpine_yellow',
              description: 'Wygrać klasyfikację generalną La Grande Boucle de France',
              bonusPaymentEur: 3000000,
              importance: ObjectiveImportance.critical,
              isCompleted: false,
              currentProgress: 0.85,
              targetProgress: 1.0,
            ),
          ],
        ),
      ],
      inventoryBikes: const [],
    );

    final baseSave = await _seedWorldWithCustomTeam(
      saveName: 'Pojedynek Tytanów w Alpach',
      playerManagerName: playerManagerName,
      customTeam: customTeam,
      customRoster: roster,
      difficulty: CareerDifficulty.normal,
      seasonYear: seasonYear,
      seed: seed,
      exactBudgetEur: 22000000,
    );

    final tdfId = 'race_tour_de_france_$seasonYear';
    final scenarioDate = DateTime(seasonYear, 7, 18);

    // Wybieramy rywala noszącego Żółtą Koszulkę z innej mocnej ekipy WT
    final rivalTeam = baseSave.teams.firstWhere(
      (t) => t.id != teamId && t.division == TeamDivision.worldTour,
      orElse: () => baseSave.teams.first,
    );
    final rivalRiders = baseSave.riders
        .where((r) => rivalTeam.rosterRiderIds.contains(r.id))
        .toList();
    final yellowJerseyRival = rivalRiders.isNotEmpty
        ? rivalRiders.reduce((a, b) => a.overallRating >= b.overallRating ? a : b)
        : gcLeader;

    // Zbieramy kilku innych pretendentów GC do Top 10
    final otherContenders = baseSave.riders
        .where((r) =>
            r.id != gcLeader.id &&
            r.id != yellowJerseyRival.id &&
            r.contract.teamId != 'free_agent' &&
            (r.specialization == RiderSpecialization.gcClimber ||
                r.specialization == RiderSpecialization.pureClimber))
        .take(8)
        .toList();

    const leaderTimeSeconds = 258420; // ~71h 47m 00s po 17 etapach
    final gcStandings = <RiderClassificationEntry>[
      RiderClassificationEntry(
        riderId: yellowJerseyRival.id,
        riderName: yellowJerseyRival.fullName,
        teamId: yellowJerseyRival.contract.teamId,
        totalTimeSeconds: leaderTimeSeconds,
        points: 185,
        rank: 1,
        timeBehindLeaderSeconds: 0,
      ),
      RiderClassificationEntry(
        riderId: gcLeader.id,
        riderName: gcLeader.fullName,
        teamId: teamId,
        totalTimeSeconds: leaderTimeSeconds + 14,
        points: 174,
        rank: 2,
        timeBehindLeaderSeconds: 14,
      ),
      for (int i = 0; i < otherContenders.length; i++)
        RiderClassificationEntry(
          riderId: otherContenders[i].id,
          riderName: otherContenders[i].fullName,
          teamId: otherContenders[i].contract.teamId,
          totalTimeSeconds: leaderTimeSeconds + 72 + (i * 58),
          points: 140 - i * 10,
          rank: i + 3,
          timeBehindLeaderSeconds: 72 + (i * 58),
        ),
    ];

    final updatedRaces = baseSave.calendar.races.map((race) {
      if (race.id != tdfId) return race;
      final updatedStages = List<RaceStage>.from(race.stages);
      if (updatedStages.length > 17) {
        updatedStages[17] = _buildAlpineQueenStage18();
      }
      final teamEntries = <TeamClassificationEntry>[
        TeamClassificationEntry(
          teamId: teamId,
          teamName: customTeam.name,
          totalTimeSeconds: leaderTimeSeconds * 3 + 180,
          rank: 1,
          timeBehindLeaderSeconds: 0,
        ),
        TeamClassificationEntry(
          teamId: rivalTeam.id,
          teamName: rivalTeam.name,
          totalTimeSeconds: leaderTimeSeconds * 3 + 245,
          rank: 2,
          timeBehindLeaderSeconds: 65,
        ),
      ];
      return race.copyWith(
        stages: updatedStages,
        classifications: race.classifications.copyWith(
          generalClassification: gcStandings,
          mountainsClassification: [
            gcStandings[1].copyWith(rank: 1, points: 118, totalTimeSeconds: 0, timeBehindLeaderSeconds: 0),
            gcStandings[0].copyWith(rank: 2, points: 112, totalTimeSeconds: 0, timeBehindLeaderSeconds: 0),
          ],
          pointsClassification: [
            gcStandings[0].copyWith(rank: 1, points: 245, totalTimeSeconds: 0, timeBehindLeaderSeconds: 0),
            gcStandings[1].copyWith(rank: 2, points: 210, totalTimeSeconds: 0, timeBehindLeaderSeconds: 0),
          ],
          youthClassification: [
            gcStandings[1].copyWith(rank: 1, timeBehindLeaderSeconds: 0),
          ],
          teamClassification: teamEntries,
        ),
      );
    }).toList();

    final baseCalendar = _advanceCalendarToDate(
      baseSave.calendar.copyWith(races: updatedRaces),
      targetDate: scenarioDate,
      seasonYear: seasonYear,
      allTeams: baseSave.teams,
      allRiders: baseSave.riders,
      stopBeforeRaceId: tdfId,
    );

    final tdfIndex = baseCalendar.races.indexWhere((r) => r.id == tdfId);
    final activeCalendar = baseCalendar.copyWith(
      activeRaceId: tdfId,
      activeStageIndex: 17, // Bezpośrednio przed 18. etapem (indeks 0-based = 17)
      currentRaceIndex: tdfIndex >= 0 ? tdfIndex : baseCalendar.currentRaceIndex,
    );

    return baseSave.copyWith(
      currentDate: scenarioDate,
      calendar: activeCalendar,
      managerReputation: 84,
      serviceCourseLevel: 4,
      windTunnelLevel: 4,
      medicalCenterLevel: 4,
      franchiseLeaders: [
        FranchiseRider(
          riderId: gcLeader.id,
          riderName: gcLeader.fullName,
          focus: FranchiseRoleFocus.grandTourGc,
          priorityRank: 1,
          designatedSquadId: 'squad_alpine_tdf',
        ),
      ],
      dedicatedSquads: [
        DedicatedSquad(
          id: 'squad_alpine_tdf',
          name: 'Alpejska Ósemka GC',
          leaderRiderId: gcLeader.id,
          domestiqueRiderIds: roster
              .where((r) => r.id != gcLeader.id)
              .take(7)
              .map((r) => r.id)
              .toList(),
          targetSeasonObjective: 'Odrobić 14s na 18. etapie alpejskim i zdobyć Żółtą Koszulkę',
          sharedRacesCount: 5,
          sharedStagesCount: 38,
          trainingCampsCount: 2,
          cohesionScore: 88.5,
        ),
      ],
    );
  }

  // ===========================================================================
  // SCENARIUSZ 3: KAMPANIA BRUKOWANA (KWIECIEŃ, FLANDRIA + ROUBAIX W DESZCZU)
  // ===========================================================================

  static Future<CareerSave> _buildCobbledCampaign({
    required int seasonYear,
    required String playerManagerName,
    required int seed,
  }) async {
    const teamId = 'team_wt_flanders_cobbles';
    final rng = math.Random(seed);

    final cobbleKing = _customizeRider(
      RiderProceduralGenerator.generateRider(
        id: 'rider_bel_cobble_king',
        nationalityIso: 'BEL',
        specialization: RiderSpecialization.classicCobbles,
        age: 27,
        targetOverallRating: 91,
        teamId: teamId,
        role: RiderRole.teamLeader,
        random: rng,
      ),
      firstName: 'Wout',
      lastName: 'Van Der Bruggen',
      potential: 94,
      morale: 91.0,
      leaderLoyalty: 93.0,
      cobblesBoost: 96,
      rainBoost: 94,
    );

    final cobbleCoLeader = _customizeRider(
      RiderProceduralGenerator.generateRider(
        id: 'rider_ned_cobble_coleader',
        nationalityIso: 'NED',
        specialization: RiderSpecialization.classicCobbles,
        age: 26,
        targetOverallRating: 87,
        teamId: teamId,
        role: RiderRole.coLeader,
        random: rng,
      ),
      firstName: 'Mathieu',
      lastName: 'De Vries',
      potential: 90,
      morale: 86.0,
      leaderLoyalty: 82.0,
      cobblesBoost: 92,
      rainBoost: 89,
    );

    final roster = <Rider>[
      cobbleKing,
      cobbleCoLeader,
      for (int i = 0; i < 18; i++)
        RiderProceduralGenerator.generateRider(
          id: 'rider_cobble_squad_$i',
          nationalityIso: i < 10 ? 'BEL' : (i < 14 ? 'NED' : 'FRA'),
          specialization: i < 6
              ? RiderSpecialization.classicCobbles
              : (i < 10 ? RiderSpecialization.puncher : RiderSpecialization.domestiqueEngine),
          age: 23 + (i % 9),
          targetOverallRating: i < 4 ? 82 : (75 + (i % 6)),
          teamId: teamId,
          role: i < 3 ? RiderRole.superDomestique : RiderRole.domestique,
          random: rng,
        ),
    ];

    final customTeam = CyclingTeam(
      id: teamId,
      name: 'Vlaanderen Lion Classics',
      division: TeamDivision.worldTour,
      countryIso: 'BEL',
      primaryJerseyColorHex: '#F59E0B',
      secondaryJerseyColorHex: '#181B22',
      accentJerseyColorHex: '#F3F4F6',
      cashBalanceEur: 18500000,
      monthlyBurnRateEur: 1180000,
      uciPointsSeason: 4650,
      rosterRiderIds: roster.map((r) => r.id).toList(),
      staff: const TeamStaff(
        trainersLevel: 85,
        sportsDirectorsLevel: 90,
        doctorsLevel: 84,
        mechanicsLevel: 94, // Kluczowi mechanicy na bruk i niskie ciśnienie opon!
        scoutsLevel: 82,
      ),
      bikeDeal: _buildBikeDeal(prestigeLevel: 4, cashContributionEur: 1200000),
      sponsors: const [
        SponsorContract(
          id: 'sp_flanders_lion',
          companyName: 'Brugge Brouwerij & Ceramics',
          industry: SponsorIndustry.finance,
          sponsorTier: SponsorTier.titlePrimary,
          annualBudgetEur: 18500000,
          contractDurationYears: 3,
          sponsorSatisfaction: 84.0,
          objectives: [
            SponsorObjective(
              id: 'obj_cobbles_monument',
              description: 'Wygrać Ronde van Vlaanderen lub Piekło Północy (Paris-Roubaix)',
              bonusPaymentEur: 1500000,
              importance: ObjectiveImportance.critical,
              isCompleted: false,
              currentProgress: 0.0,
              targetProgress: 1.0,
            ),
            SponsorObjective(
              id: 'obj_cobbles_double_top5',
              description: 'Wprowadzić 2 kolarzy do Top 10 w obu brukowanych Monumentach',
              bonusPaymentEur: 750000,
              importance: ObjectiveImportance.high,
              isCompleted: false,
              currentProgress: 0.0,
              targetProgress: 2.0,
            ),
          ],
        ),
      ],
      inventoryBikes: const [],
    );

    final baseSave = await _seedWorldWithCustomTeam(
      saveName: 'Kampania Brukowana',
      playerManagerName: playerManagerName,
      customTeam: customTeam,
      customRoster: roster,
      difficulty: CareerDifficulty.normal,
      seasonYear: seasonYear,
      seed: seed,
      exactBudgetEur: 18500000,
    );

    final flandersId = 'race_flanders_monument_$seasonYear';
    final roubaixId = 'race_roubaix_monument_$seasonYear';
    final scenarioDate = DateTime(seasonYear, 4, 2);

    // Ustawiamy ulewny deszcz i silny wiatr w obu brukowanych Monumentach
    final updatedRaces = baseSave.calendar.races.map((race) {
      if (race.id == flandersId || race.id == roubaixId) {
        final rainyStages = race.stages
            .map(
              (s) => s.copyWith(
                weatherCondition: race.id == roubaixId
                    ? WeatherCondition.heavyStorm
                    : WeatherCondition.lightRain,
                baseTemperatureCelsius: 8.5,
                windSpeedKmh: race.id == roubaixId ? 34.0 : 29.0,
              ),
            )
            .toList();
        return race.copyWith(stages: rainyStages);
      }
      return race;
    }).toList();

    final calendar = _advanceCalendarToDate(
      baseSave.calendar.copyWith(races: updatedRaces),
      targetDate: scenarioDate,
      seasonYear: seasonYear,
      allTeams: baseSave.teams,
      allRiders: baseSave.riders,
      stopBeforeRaceId: flandersId,
    );

    return baseSave.copyWith(
      currentDate: scenarioDate,
      calendar: calendar,
      managerReputation: 78,
      serviceCourseLevel: 4,
      windTunnelLevel: 3,
      medicalCenterLevel: 3,
      franchiseLeaders: [
        FranchiseRider(
          riderId: cobbleKing.id,
          riderName: cobbleKing.fullName,
          focus: FranchiseRoleFocus.springCobbledClassics,
          priorityRank: 1,
          designatedSquadId: 'squad_cobbles_monuments',
        ),
        FranchiseRider(
          riderId: cobbleCoLeader.id,
          riderName: cobbleCoLeader.fullName,
          focus: FranchiseRoleFocus.springCobbledClassics,
          priorityRank: 2,
          designatedSquadId: 'squad_cobbles_monuments',
        ),
      ],
      dedicatedSquads: [
        DedicatedSquad(
          id: 'squad_cobbles_monuments',
          name: 'Flamandzka Gwardia Brukowa',
          leaderRiderId: cobbleKing.id,
          domestiqueRiderIds: roster
              .where((r) => r.id != cobbleKing.id)
              .take(6)
              .map((r) => r.id)
              .toList(),
          targetSeasonObjective: 'Dublet: Flandria i Paryż-Roubaix w deszczu',
          sharedRacesCount: 6,
          sharedStagesCount: 6,
          trainingCampsCount: 1,
          cohesionScore: 84.0,
        ),
      ],
    );
  }

  // ===========================================================================
  // SCENARIUSZ 4: IMPERIUM GALAKTYCZNE (45 MLN EUR, 3 GWIAZDY Z EGO, 3 GT)
  // ===========================================================================

  static Future<CareerSave> _buildGalacticEmpire({
    required int seasonYear,
    required String playerManagerName,
    required int seed,
  }) async {
    const teamId = 'team_wt_galactic_empire';
    final rng = math.Random(seed);

    // Trzy wielkie gwiazdy o ogromnym potencjale i trudnym, rywalizującym ego
    final star1Alpha = _customizeRider(
      RiderProceduralGenerator.generateRider(
        id: 'rider_gal_star_1',
        nationalityIso: 'SLO',
        specialization: RiderSpecialization.gcClimber,
        age: 26,
        targetOverallRating: 94,
        teamId: teamId,
        role: RiderRole.teamLeader,
        random: rng,
      ),
      firstName: 'Matej',
      lastName: 'Kralj',
      potential: 98,
      morale: 74.0,
      leaderLoyalty: 42.0, // Wysokie ego, niska lojalność przy dzieleniu władzy
      monthlySalaryEur: 420000,
    );

    final star2Giro = _customizeRider(
      RiderProceduralGenerator.generateRider(
        id: 'rider_gal_star_2',
        nationalityIso: 'DEN',
        specialization: RiderSpecialization.gcClimber,
        age: 27,
        targetOverallRating: 92,
        teamId: teamId,
        role: RiderRole.teamLeader,
        random: rng,
      ),
      firstName: 'Mikkel',
      lastName: 'Lindqvist',
      potential: 95,
      morale: 68.0,
      leaderLoyalty: 38.0,
      monthlySalaryEur: 360000,
    );

    final star3Vuelta = _customizeRider(
      RiderProceduralGenerator.generateRider(
        id: 'rider_gal_star_3',
        nationalityIso: 'BEL',
        specialization: RiderSpecialization.timeTrialist,
        age: 25,
        targetOverallRating: 91,
        teamId: teamId,
        role: RiderRole.coLeader,
        random: rng,
      ),
      firstName: 'Remco',
      lastName: 'Vermeulen',
      potential: 96,
      morale: 70.0,
      leaderLoyalty: 44.0,
      monthlySalaryEur: 340000,
    );

    final roster = <Rider>[
      star1Alpha,
      star2Giro,
      star3Vuelta,
      for (int i = 0; i < 23; i++)
        RiderProceduralGenerator.generateRider(
          id: 'rider_gal_dom_$i',
          specialization: i < 8
              ? RiderSpecialization.pureClimber
              : (i < 14
                  ? RiderSpecialization.domestiqueEngine
                  : (i < 19
                      ? RiderSpecialization.classicCobbles
                      : RiderSpecialization.pureSprinter)),
          age: 22 + (i % 10),
          targetOverallRating: i < 6 ? 84 : (78 + (i % 5)),
          teamId: teamId,
          role: i < 5 ? RiderRole.superDomestique : RiderRole.domestique,
          random: rng,
        ),
    ];

    final customTeam = CyclingTeam(
      id: teamId,
      name: 'Galacticos Emirates WorldTour',
      division: TeamDivision.worldTour,
      countryIso: 'UAE',
      primaryJerseyColorHex: '#0F1115',
      secondaryJerseyColorHex: '#D4AF37',
      accentJerseyColorHex: '#8E4A49',
      cashBalanceEur: 45000000,
      monthlyBurnRateEur: 2950000,
      uciPointsSeason: 12400,
      rosterRiderIds: roster.map((r) => r.id).toList(),
      staff: const TeamStaff(
        trainersLevel: 96,
        sportsDirectorsLevel: 94,
        doctorsLevel: 95,
        mechanicsLevel: 95,
        scoutsLevel: 92,
      ),
      bikeDeal: _buildBikeDeal(prestigeLevel: 5, cashContributionEur: 3500000),
      sponsors: const [
        SponsorContract(
          id: 'sp_galactic_fund',
          companyName: 'Galactic Sovereign Fund',
          industry: SponsorIndustry.finance,
          sponsorTier: SponsorTier.titlePrimary,
          annualBudgetEur: 32000000,
          contractDurationYears: 4,
          sponsorSatisfaction: 80.0,
          objectives: [
            SponsorObjective(
              id: 'obj_gal_giro',
              description: 'Wygrać klasyfikację generalną Corsa Rosa d\'Italia (Giro)',
              bonusPaymentEur: 2500000,
              importance: ObjectiveImportance.critical,
              isCompleted: false,
              currentProgress: 0.0,
              targetProgress: 1.0,
            ),
            SponsorObjective(
              id: 'obj_gal_tdf',
              description: 'Wygrać klasyfikację generalną La Grande Boucle de France (Tour)',
              bonusPaymentEur: 4000000,
              importance: ObjectiveImportance.critical,
              isCompleted: false,
              currentProgress: 0.0,
              targetProgress: 1.0,
            ),
            SponsorObjective(
              id: 'obj_gal_vuelta',
              description: 'Wygrać klasyfikację generalną La Vuelta Ibérica (Vuelta)',
              bonusPaymentEur: 2500000,
              importance: ObjectiveImportance.critical,
              isCompleted: false,
              currentProgress: 0.0,
              targetProgress: 1.0,
            ),
          ],
        ),
        SponsorContract(
          id: 'sp_aerojet',
          companyName: 'AeroJet Global Airlines',
          industry: SponsorIndustry.airlines,
          sponsorTier: SponsorTier.titleSecondary,
          annualBudgetEur: 13000000,
          contractDurationYears: 3,
          sponsorSatisfaction: 85.0,
          objectives: [],
        ),
      ],
      inventoryBikes: const [],
    );

    final baseSave = await _seedWorldWithCustomTeam(
      saveName: 'Imperium Galaktyczne',
      playerManagerName: playerManagerName,
      customTeam: customTeam,
      customRoster: roster,
      difficulty: CareerDifficulty.realistic,
      seasonYear: seasonYear,
      seed: seed,
      exactBudgetEur: 45000000,
    );

    final scenarioDate = DateTime(seasonYear, 2, 1);
    final calendar = _advanceCalendarToDate(
      baseSave.calendar,
      targetDate: scenarioDate,
      seasonYear: seasonYear,
      allTeams: baseSave.teams,
      allRiders: baseSave.riders,
    );

    final supportIds = roster.skip(3).map((r) => r.id).toList();

    return baseSave.copyWith(
      currentDate: scenarioDate,
      calendar: calendar,
      managerReputation: 90,
      serviceCourseLevel: 5,
      windTunnelLevel: 5,
      medicalCenterLevel: 5,
      franchiseLeaders: [
        FranchiseRider(
          riderId: star1Alpha.id,
          riderName: star1Alpha.fullName,
          focus: FranchiseRoleFocus.grandTourGc,
          priorityRank: 1,
          designatedSquadId: 'squad_gal_tdf',
        ),
        FranchiseRider(
          riderId: star2Giro.id,
          riderName: star2Giro.fullName,
          focus: FranchiseRoleFocus.grandTourGc,
          priorityRank: 2,
          designatedSquadId: 'squad_gal_giro',
        ),
        FranchiseRider(
          riderId: star3Vuelta.id,
          riderName: star3Vuelta.fullName,
          focus: FranchiseRoleFocus.grandTourGc,
          priorityRank: 3,
          designatedSquadId: 'squad_gal_vuelta',
        ),
      ],
      dedicatedSquads: [
        DedicatedSquad(
          id: 'squad_gal_giro',
          name: 'Jednostka Giro d\'Italia',
          leaderRiderId: star2Giro.id,
          domestiqueRiderIds: supportIds.take(7).toList(),
          targetSeasonObjective: 'Zwycięstwo w klasyfikacji generalnej Giro',
          cohesionScore: 55.0,
        ),
        DedicatedSquad(
          id: 'squad_gal_tdf',
          name: 'Jednostka Tour de France',
          leaderRiderId: star1Alpha.id,
          domestiqueRiderIds: supportIds.skip(7).take(7).toList(),
          targetSeasonObjective: 'Obrona Żółtej Koszulki w Paryżu/Nicei',
          cohesionScore: 58.0,
        ),
        DedicatedSquad(
          id: 'squad_gal_vuelta',
          name: 'Jednostka La Vuelta',
          leaderRiderId: star3Vuelta.id,
          domestiqueRiderIds: supportIds.skip(14).take(7).toList(),
          targetSeasonObjective: 'Komplet Potrójnej Korony Grand Tourów',
          cohesionScore: 52.0,
        ),
      ],
      financeLedger: [
        CareerFinanceLedgerEntry(
          id: 'fin_gal_init',
          date: scenarioDate,
          category: FinanceCategory.sponsorPayout,
          amountEur: 45000000,
          description: 'Kapitał Galacticos Emirates WorldTour (45 mln EUR)',
        ),
      ],
    );
  }

  // ===========================================================================
  // WSPÓLNE HELPERY KONSTRUKCYJNE
  // ===========================================================================

  /// Generuje bazowy świat przez [InitialGameSeeder] i gwarantuje dokładny budżet początkowy.
  static Future<CareerSave> _seedWorldWithCustomTeam({
    required String saveName,
    required String playerManagerName,
    required CyclingTeam customTeam,
    required List<Rider> customRoster,
    required CareerDifficulty difficulty,
    required int seasonYear,
    required int seed,
    required int exactBudgetEur,
  }) async {
    final seedResult = await InitialGameSeeder.seedNewGame(
      InitialGameSeedConfig(
        saveName: saveName,
        playerManagerName: playerManagerName,
        playerTeamId: customTeam.id,
        difficulty: difficulty,
        seasonYear: seasonYear,
        seed: seed,
        customTeam: customTeam,
        customRoster: customRoster,
        saveToDisk: false,
      ),
    );

    final updatedTeams = seedResult.save.teams.map((t) {
      if (t.id == customTeam.id) {
        return t.copyWith(cashBalanceEur: exactBudgetEur);
      }
      return t;
    }).toList();

    return seedResult.save.copyWith(teams: updatedTeams);
  }

  /// Przesuwa kalendarz do docelowej daty i oznacza wcześniejsze wyścigi jako ukończone.
  static SeasonCalendar _advanceCalendarToDate(
    SeasonCalendar calendar, {
    required DateTime targetDate,
    required int seasonYear,
    required List<CyclingTeam> allTeams,
    required List<Rider> allRiders,
    String? stopBeforeRaceId,
  }) {
    final completedIds = <String>[];
    final history = <String, RaceHistoryEntry>{};
    int nextIndex = 0;

    final wtTeams = allTeams
        .where((t) => t.division == TeamDivision.worldTour)
        .toList();
    final fallbackTeam = wtTeams.isNotEmpty ? wtTeams.first : allTeams.first;

    for (int i = 0; i < calendar.races.length; i++) {
      final race = calendar.races[i];
      if (stopBeforeRaceId != null && race.id == stopBeforeRaceId) {
        nextIndex = i;
        break;
      }

      final raceStart = DateTime(seasonYear, race.startMonth, race.startDay);
      if (raceStart.isBefore(targetDate)) {
        completedIds.add(race.id);
        final team = wtTeams.isNotEmpty
            ? wtTeams[i % wtTeams.length]
            : fallbackTeam;
        final rider = allRiders.firstWhere(
          (r) => team.rosterRiderIds.contains(r.id),
          orElse: () => allRiders.first,
        );
        history[race.id] = RaceHistoryEntry(
          raceId: race.id,
          raceName: race.name,
          seasonYear: seasonYear,
          winnerRiderId: rider.id,
          winnerRiderName: rider.fullName,
          winnerTeamId: team.id,
          winnerTeamName: team.name,
          winnerTotalTimeSeconds: race.isOneDayRace ? 19840 : 94320,
          completedDate: raceStart,
        );
        nextIndex = i + 1;
      } else {
        nextIndex = i;
        break;
      }
    }

    return calendar.copyWith(
      currentRaceIndex: nextIndex.clamp(0, math.max(0, calendar.races.length - 1)),
      completedRaceIds: completedIds,
      raceHistory: history,
    );
  }

  /// Tworzy epicki 18. etap alpejski z 3 przełęczami powyżej 2000 m n.p.m.
  static RaceStage _buildAlpineQueenStage18() {
    const segments = <StageSegment>[
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 24.0,
        startElevationM: 720.0,
        endElevationM: 780.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 20.0,
        windDirectionDegrees: 240.0,
        roadBearingDegrees: 110.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      // Przełęcz #1: Col de la Croix de Fer (2067 m n.p.m.)
      StageSegment(
        index: 1,
        startKm: 24.0,
        lengthKm: 26.0,
        startElevationM: 780.0,
        endElevationM: 2067.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 58.0,
        windDirectionDegrees: 260.0,
        roadBearingDegrees: 135.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      ),
      StageSegment(
        index: 2,
        startKm: 50.0,
        lengthKm: 28.0,
        startElevationM: 2067.0,
        endElevationM: 850.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 72.0,
        windDirectionDegrees: 250.0,
        roadBearingDegrees: 150.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      // Przełęcz #2: Col du Galibier (2642 m n.p.m.)
      StageSegment(
        index: 3,
        startKm: 78.0,
        lengthKm: 32.0,
        startElevationM: 850.0,
        endElevationM: 2642.0,
        surfaceType: SegmentSurfaceType.roughAsphalt,
        technicalDifficulty: 65.0,
        windDirectionDegrees: 280.0,
        roadBearingDegrees: 180.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      ),
      StageSegment(
        index: 4,
        startKm: 110.0,
        lengthKm: 34.0,
        startElevationM: 2642.0,
        endElevationM: 940.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 76.0,
        windDirectionDegrees: 270.0,
        roadBearingDegrees: 220.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 5,
        startKm: 144.0,
        lengthKm: 18.5,
        startElevationM: 940.0,
        endElevationM: 960.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 24.0,
        windDirectionDegrees: 240.0,
        roadBearingDegrees: 250.0,
        sprintOrKomClassification: SegmentClassification.intermediateSprint,
      ),
      // Przełęcz #3 (Meta na szczycie): Col de Sarenne / Alpe d'Huez Extension (2115 m n.p.m.)
      StageSegment(
        index: 6,
        startKm: 162.5,
        lengthKm: 24.0,
        startElevationM: 960.0,
        endElevationM: 2115.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 70.0,
        windDirectionDegrees: 255.0,
        roadBearingDegrees: 45.0,
        sprintOrKomClassification: SegmentClassification.finishLine,
      ),
    ];

    return const RaceStage(
      id: 'st_tdf_18_alpine_titans',
      stageNumber: 18,
      name: 'Croix de Fer • Galibier • Alpe d\'Huez (3x >2000m)',
      stageType: StageType.summitFinish,
      segments: segments,
      baseTemperatureCelsius: 11.0,
      weatherCondition: WeatherCondition.overcast,
      windSpeedKmh: 22.0,
    );
  }

  /// Buduje umowę z producentem rowerów z katalogu marek.
  static BikeManufacturerDeal _buildBikeDeal({
    required int prestigeLevel,
    required int cashContributionEur,
  }) {
    final brands = FictionalBrandsCatalog.allBrands;
    final brand = brands.isNotEmpty ? brands.first : null;
    final brandId = brand?.id ?? 'brand_aethel';
    final brandName = brand?.name ?? 'Aethel Carbon';

    return BikeManufacturerDeal(
      manufacturerId: brandId,
      manufacturerName: brandName,
      prestigeLevel: prestigeLevel,
      annualCashContributionEur: cashContributionEur,
      freeBikesQuota: prestigeLevel >= 4 ? 90 : 60,
      researchAndDevelopmentLevel: prestigeLevel >= 5 ? 95 : 75,
      suppliedFrameIds: const ['frame_aero_pro', 'frame_climb_sl'],
      suppliedWheelsetIds: const ['wheel_deep_50', 'wheel_climb_32'],
      contractYearsLeft: 2,
      minimumUciRankingRequired: prestigeLevel >= 5 ? 5 : 22,
    );
  }

  /// Personalizuje wygenerowanego kolarza (imię, nazwisko, ego/morale, specjalne atrybuty).
  static Rider _customizeRider(
    Rider base, {
    required String firstName,
    required String lastName,
    int? potential,
    double? morale,
    double? leaderLoyalty,
    int? monthlySalaryEur,
    double? acuteLoad,
    double? chronicLoad,
    int? cobblesBoost,
    int? rainBoost,
  }) {
    return base.copyWith(
      firstName: firstName,
      lastName: lastName,
      potential: potential ?? base.potential,
      contract: base.contract.copyWith(
        morale: morale ?? base.contract.morale,
        leaderLoyalty: leaderLoyalty ?? base.contract.leaderLoyalty,
        monthlySalaryEur: monthlySalaryEur ?? base.contract.monthlySalaryEur,
      ),
      health: base.health.copyWith(
        acuteTrainingLoad: acuteLoad ?? base.health.acuteTrainingLoad,
        chronicTrainingLoad: chronicLoad ?? base.health.chronicTrainingLoad,
      ),
      skills: base.skills.copyWith(
        cobbles: cobblesBoost ?? base.skills.cobbles,
        rainResistance: rainBoost ?? base.skills.rainResistance,
      ),
    );
  }
}
