import 'dart:math' as math;
import '../../models/equipment/complete_bike.dart';
import '../../models/equipment/frame_model.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/cycling_team.dart';
import '../../models/team/sponsor_contract.dart';
import 'fictional_brands_catalog.dart';
import 'rider_procedural_generator.dart';

/// Wynik wygenerowania pełnego ekosystemu światowego kolarstwa (53 drużyny, >1000 kolarzy).
class WorldTourGenerationResult {
  final List<CyclingTeam> teams;
  final List<Rider> allRiders;
  final Map<String, List<Rider>> ridersByTeamId;

  const WorldTourGenerationResult({
    required this.teams,
    required this.allRiders,
    required this.ridersByTeamId,
  });

  /// 18 drużyn WorldTour (najwyższa dywizja)
  List<CyclingTeam> get worldTourTeams =>
      teams.where((t) => t.division == TeamDivision.worldTour).toList();

  /// 15 drużyn ProTeam (druga dywizja)
  List<CyclingTeam> get proTeams =>
      teams.where((t) => t.division == TeamDivision.proTeam).toList();

  /// 20 drużyn Continental (trzecia dywizja)
  List<CyclingTeam> get continentalTeams =>
      teams.where((t) => t.division == TeamDivision.continental).toList();

  CyclingTeam? getTeamById(String id) {
    for (final t in teams) {
      if (t.id == id) return t;
    }
    return null;
  }

  Rider? getRiderById(String id) {
    for (final r in allRiders) {
      if (r.id == id) return r;
    }
    return null;
  }

  List<Rider> getTeamRoster(String teamId) {
    return ridersByTeamId[teamId] ?? const [];
  }

  /// Lider klasyfikacji generalnej (GC) danej drużyny
  Rider? getTeamGcLeader(String teamId) {
    final roster = getTeamRoster(teamId);
    if (roster.isEmpty) return null;
    final leaders = roster.where(
      (r) => r.contract.role == RiderRole.teamLeader &&
          (r.specialization == RiderSpecialization.gcClimber ||
              r.specialization == RiderSpecialization.pureClimber),
    );
    if (leaders.isNotEmpty) return leaders.first;
    return roster.reduce((a, b) => a.overallRating > b.overallRating ? a : b);
  }

  /// Lider na klasyki jednotygodniowe i brukowane
  Rider? getTeamClassicsLeader(String teamId) {
    final roster = getTeamRoster(teamId);
    if (roster.isEmpty) return null;
    final classics = roster.where(
      (r) => r.specialization == RiderSpecialization.classicCobbles ||
          r.specialization == RiderSpecialization.puncher,
    );
    if (classics.isNotEmpty) {
      return classics.reduce((a, b) => a.overallRating > b.overallRating ? a : b);
    }
    return null;
  }

  /// Główny sprinter zespołu na płaskie etapy
  Rider? getTeamSprinter(String teamId) {
    final roster = getTeamRoster(teamId);
    if (roster.isEmpty) return null;
    final sprinters = roster.where(
      (r) => r.specialization == RiderSpecialization.pureSprinter ||
          r.specialization == RiderSpecialization.versatileSprinter,
    );
    if (sprinters.isNotEmpty) {
      return sprinters.reduce((a, b) => a.overallRating > b.overallRating ? a : b);
    }
    return null;
  }
}

class _TeamPreset {
  final String id;
  final String name;
  final TeamDivision division;
  final String countryIso;
  final String primaryColorHex;
  final String secondaryColorHex;
  final String accentColorHex;
  final int cashBalanceEur;
  final int monthlyBurnRateEur;
  final String brandId;
  final int rosterSize;
  final String sponsorCompanyName;
  final SponsorIndustry sponsorIndustry;

  const _TeamPreset({
    required this.id,
    required this.name,
    required this.division,
    required this.countryIso,
    required this.primaryColorHex,
    required this.secondaryColorHex,
    required this.accentColorHex,
    required this.cashBalanceEur,
    required this.monthlyBurnRateEur,
    required this.brandId,
    required this.rosterSize,
    required this.sponsorCompanyName,
    required this.sponsorIndustry,
  });
}

/// Zaawansowany generator tworzący na start kariery 53 profesjonalne drużyny kolarskie
/// oraz ponad 1000 unikalnych kolarzy przypisanych do ról i kontraktów.
class WorldTeamsGenerator {
  WorldTeamsGenerator._();

  static final math.Random _defaultRandom = math.Random(42);

  /// Główna metoda generująca pełny świat gry na start kariery.
  static WorldTourGenerationResult generateWorldTourSystem({
    int? randomSeed,
    int? seed,
  }) {
    final effectiveSeed = seed ?? randomSeed;
    final rng = effectiveSeed != null ? math.Random(effectiveSeed) : _defaultRandom;

    final List<CyclingTeam> generatedTeams = [];
    final List<Rider> generatedRiders = [];
    final Map<String, List<Rider>> ridersMap = {};

    for (final preset in _teamPresets) {
      // 1. Wygeneruj kolarzy dla danej drużyny
      final teamRiders = _generateTeamRoster(preset, rng);
      generatedRiders.addAll(teamRiders);
      ridersMap[preset.id] = teamRiders;

      // 2. Sztab szkoleniowo-medyczny dopasowany do ligi
      final staff = _generateTeamStaff(preset.division, rng);

      // 3. Kontrakt z producentem rowerowym
      final bikeDeal = FictionalBrandsCatalog.createManufacturerDeal(
        brandId: preset.brandId,
        contractYearsLeft: 2 + rng.nextInt(2),
        minimumUciRankingRequired: preset.division == TeamDivision.worldTour
            ? 18
            : (preset.division == TeamDivision.proTeam ? 35 : 60),
      );

      // 4. Flota kompletnych rowerów
      final inventoryBikes = _generateInventoryBikes(preset.id, preset.brandId);

      // 5. Sponsorzy tytularni i cele sponsorskie
      final sponsors = _generateSponsors(preset, rng);

      // 6. Punkty UCI na start sezonu
      final int uciPoints = preset.division == TeamDivision.worldTour
          ? (4500 + rng.nextInt(6500))
          : (preset.division == TeamDivision.proTeam ? (1200 + rng.nextInt(2500)) : (250 + rng.nextInt(800)));

      final team = CyclingTeam(
        id: preset.id,
        name: preset.name,
        division: preset.division,
        countryIso: preset.countryIso,
        primaryJerseyColorHex: preset.primaryColorHex,
        secondaryJerseyColorHex: preset.secondaryColorHex,
        accentJerseyColorHex: preset.accentColorHex,
        cashBalanceEur: preset.cashBalanceEur,
        monthlyBurnRateEur: preset.monthlyBurnRateEur,
        uciPointsSeason: uciPoints,
        rosterRiderIds: teamRiders.map((r) => r.id).toList(),
        staff: staff,
        bikeDeal: bikeDeal,
        sponsors: sponsors,
        inventoryBikes: inventoryBikes,
      );

      generatedTeams.add(team);
    }

    return WorldTourGenerationResult(
      teams: List<CyclingTeam>.unmodifiable(generatedTeams),
      allRiders: List<Rider>.unmodifiable(generatedRiders),
      ridersByTeamId: Map<String, List<Rider>>.unmodifiable(ridersMap),
    );
  }

  static List<Rider> _generateTeamRoster(_TeamPreset preset, math.Random rng) {
    int baseOvr;
    switch (preset.division) {
      case TeamDivision.worldTour:
        baseOvr = 79;
        break;
      case TeamDivision.proTeam:
        baseOvr = 73;
        break;
      case TeamDivision.continental:
        baseOvr = 67;
        break;
    }

    final List<Rider> roster = [];

    // Lider klasyfikacji generalnej (GC Leader)
    roster.add(
      RiderProceduralGenerator.generateRider(
        nationalityIso: preset.countryIso,
        specialization: RiderSpecialization.gcClimber,
        role: RiderRole.teamLeader,
        targetOverallRating: baseOvr + 7 + rng.nextInt(4),
        age: 25 + rng.nextInt(6),
        teamId: preset.id,
        random: rng,
      ),
    );

    // Lider na klasyki i pagórki (Classics Leader / Puncheur)
    roster.add(
      RiderProceduralGenerator.generateRider(
        nationalityIso: preset.countryIso,
        specialization: RiderSpecialization.classicCobbles,
        role: RiderRole.teamLeader,
        targetOverallRating: baseOvr + 5 + rng.nextInt(4),
        age: 26 + rng.nextInt(6),
        teamId: preset.id,
        random: rng,
      ),
    );

    // Główny sprinter
    roster.add(
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.pureSprinter,
        role: RiderRole.sprinter,
        targetOverallRating: baseOvr + 6 + rng.nextInt(3),
        age: 24 + rng.nextInt(7),
        teamId: preset.id,
        random: rng,
      ),
    );

    // Drugi wspinacz / co-lider górski
    roster.add(
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.pureClimber,
        role: RiderRole.coLeader,
        targetOverallRating: baseOvr + 4 + rng.nextInt(3),
        age: 23 + rng.nextInt(8),
        teamId: preset.id,
        random: rng,
      ),
    );

    // Czasowiec
    roster.add(
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.timeTrialist,
        role: RiderRole.domestique,
        targetOverallRating: baseOvr + 3 + rng.nextInt(3),
        age: 24 + rng.nextInt(8),
        teamId: preset.id,
        random: rng,
      ),
    );

    // Pomocnicy, harcownicy i młodzieżowcy dopełniający kadrę
    while (roster.length < preset.rosterSize) {
      final isNeoPro = roster.length >= (preset.rosterSize - 2);
      final int targetOvr = isNeoPro
          ? (baseOvr - 5 + rng.nextInt(4))
          : (baseOvr - 1 + rng.nextInt(4));

      final spec = RiderSpecialization.values[rng.nextInt(RiderSpecialization.values.length)];
      final role = isNeoPro
          ? RiderRole.neoPro
          : (roster.length % 3 == 0 ? RiderRole.superDomestique : RiderRole.domestique);

      roster.add(
        RiderProceduralGenerator.generateRider(
          specialization: spec,
          role: role,
          targetOverallRating: targetOvr,
          age: isNeoPro ? (18 + rng.nextInt(4)) : (22 + rng.nextInt(11)),
          teamId: preset.id,
          random: rng,
        ),
      );
    }

    return roster;
  }

  static TeamStaff _generateTeamStaff(TeamDivision division, math.Random rng) {
    switch (division) {
      case TeamDivision.worldTour:
        return TeamStaff(
          trainersLevel: 80 + rng.nextInt(17), // 80 - 96
          sportsDirectorsLevel: 82 + rng.nextInt(15),
          doctorsLevel: 82 + rng.nextInt(15),
          mechanicsLevel: 84 + rng.nextInt(14),
          scoutsLevel: 78 + rng.nextInt(18),
        );
      case TeamDivision.proTeam:
        return TeamStaff(
          trainersLevel: 65 + rng.nextInt(16), // 65 - 80
          sportsDirectorsLevel: 68 + rng.nextInt(15),
          doctorsLevel: 66 + rng.nextInt(16),
          mechanicsLevel: 70 + rng.nextInt(15),
          scoutsLevel: 70 + rng.nextInt(16),
        );
      case TeamDivision.continental:
        return TeamStaff(
          trainersLevel: 48 + rng.nextInt(18), // 48 - 65
          sportsDirectorsLevel: 50 + rng.nextInt(18),
          doctorsLevel: 46 + rng.nextInt(18),
          mechanicsLevel: 55 + rng.nextInt(18),
          scoutsLevel: 58 + rng.nextInt(18),
        );
    }
  }

  static List<CompleteBike> _generateInventoryBikes(String teamId, String brandId) {
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

  static List<SponsorContract> _generateSponsors(_TeamPreset preset, math.Random rng) {
    final int titleBudget = (preset.cashBalanceEur * 0.70).round();
    final int secondaryBudget = (preset.cashBalanceEur * 0.25).round();

    return [
      SponsorContract(
        id: 'sponsor_${preset.id}_title',
        companyName: preset.sponsorCompanyName,
        industry: preset.sponsorIndustry,
        sponsorTier: SponsorTier.titlePrimary,
        annualBudgetEur: titleBudget,
        contractDurationYears: 3,
        sponsorSatisfaction: 85.0 + rng.nextDouble() * 10.0,
        objectives: [
          SponsorObjective(
            id: 'obj_${preset.id}_1',
            description: preset.division == TeamDivision.worldTour
                ? 'Zajmij miejsce w Top 5 klasyfikacji generalnej Grand Touru'
                : 'Wygraj etap w wyścigu rangi UCI ProSeries',
            bonusPaymentEur: (titleBudget * 0.08).round(),
            importance: ObjectiveImportance.critical,
            isCompleted: false,
            currentProgress: 0.0,
            targetProgress: 1.0,
          ),
          SponsorObjective(
            id: 'obj_${preset.id}_2',
            description: 'Przejedź minimum 600 km w ucieczkach dnia',
            bonusPaymentEur: (titleBudget * 0.03).round(),
            importance: ObjectiveImportance.medium,
            isCompleted: false,
            currentProgress: 0.0,
            targetProgress: 600.0,
          ),
        ],
      ),
      SponsorContract(
        id: 'sponsor_${preset.id}_sec',
        companyName: '${preset.name} Global Logistics',
        industry: SponsorIndustry.automotive,
        sponsorTier: SponsorTier.titleSecondary,
        annualBudgetEur: secondaryBudget,
        contractDurationYears: 2,
        sponsorSatisfaction: 80.0 + rng.nextDouble() * 15.0,
        objectives: [
          SponsorObjective(
            id: 'obj_${preset.id}_3',
            description: 'Zdobądź podium na etapie wyścigu WorldTour',
            bonusPaymentEur: (secondaryBudget * 0.06).round(),
            importance: ObjectiveImportance.high,
            isCompleted: false,
            currentProgress: 0.0,
            targetProgress: 1.0,
          ),
        ],
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // 53 REALISTYCZNE DRUŻYNY KOLARSKIE ŚWIATA
  // ---------------------------------------------------------------------------
  static const List<_TeamPreset> _teamPresets = [
    // -------------------------------------------------------------------------
    // 18 DRUŻYN WORLDTOUR (BUDŻET 26 - 45 MLN EUR, ROSTER 26 KOLARZY)
    // -------------------------------------------------------------------------
    _TeamPreset(
      id: 'team_aethel_ineos',
      name: 'Aethel Royal Grenadiers',
      division: TeamDivision.worldTour,
      countryIso: 'GBR',
      primaryColorHex: '#004225',
      secondaryColorHex: '#111111',
      accentColorHex: '#C5A059',
      cashBalanceEur: 45000000,
      monthlyBurnRateEur: 3200000,
      brandId: 'brand_aethel',
      rosterSize: 26,
      sponsorCompanyName: 'Aethel Petroleum Global',
      sponsorIndustry: SponsorIndustry.energy,
    ),
    _TeamPreset(
      id: 'team_veloce_santander',
      name: 'Veloce-Santander Corsa',
      division: TeamDivision.worldTour,
      countryIso: 'ITA',
      primaryColorHex: '#A31D1D',
      secondaryColorHex: '#FFFFFF',
      accentColorHex: '#1A1A1A',
      cashBalanceEur: 42000000,
      monthlyBurnRateEur: 2950000,
      brandId: 'brand_veloce',
      rosterSize: 26,
      sponsorCompanyName: 'Banco Santander Italia',
      sponsorIndustry: SponsorIndustry.finance,
    ),
    _TeamPreset(
      id: 'team_kronos_swiss',
      name: 'Kronos Precision Velo',
      division: TeamDivision.worldTour,
      countryIso: 'SUI',
      primaryColorHex: '#D32F2F',
      secondaryColorHex: '#1C2833',
      accentColorHex: '#F4D03F',
      cashBalanceEur: 44000000,
      monthlyBurnRateEur: 3100000,
      brandId: 'brand_kronos',
      rosterSize: 26,
      sponsorCompanyName: 'Chronos Swiss Watchmakers',
      sponsorIndustry: SponsorIndustry.tech,
    ),
    _TeamPreset(
      id: 'team_zenith_usa',
      name: 'Zenith-Apex Silicon Valley',
      division: TeamDivision.worldTour,
      countryIso: 'USA',
      primaryColorHex: '#0D47A1',
      secondaryColorHex: '#00B0FF',
      accentColorHex: '#263238',
      cashBalanceEur: 38000000,
      monthlyBurnRateEur: 2700000,
      brandId: 'brand_zenith',
      rosterSize: 26,
      sponsorCompanyName: 'Zenith Cloud Compute',
      sponsorIndustry: SponsorIndustry.tech,
    ),
    _TeamPreset(
      id: 'team_sovereign_ger',
      name: 'Sovereign-Lufthansa Team',
      division: TeamDivision.worldTour,
      countryIso: 'GER',
      primaryColorHex: '#D4AF37',
      secondaryColorHex: '#0A192F',
      accentColorHex: '#FFFFFF',
      cashBalanceEur: 40000000,
      monthlyBurnRateEur: 2850000,
      brandId: 'brand_sovereign',
      rosterSize: 26,
      sponsorCompanyName: 'Lufthansa Aviation Group',
      sponsorIndustry: SponsorIndustry.airlines,
    ),
    _TeamPreset(
      id: 'team_nordic_nor',
      name: 'Nordic-Equinor Arctic Squad',
      division: TeamDivision.worldTour,
      countryIso: 'NOR',
      primaryColorHex: '#0277BD',
      secondaryColorHex: '#E0F7FA',
      accentColorHex: '#1A237E',
      cashBalanceEur: 36000000,
      monthlyBurnRateEur: 2550000,
      brandId: 'brand_nordic',
      rosterSize: 26,
      sponsorCompanyName: 'Equinor Energy Norway',
      sponsorIndustry: SponsorIndustry.energy,
    ),
    _TeamPreset(
      id: 'team_flanders_vektor',
      name: 'Flanders-AeroVektor Lotto',
      division: TeamDivision.worldTour,
      countryIso: 'BEL',
      primaryColorHex: '#FBC02D',
      secondaryColorHex: '#212121',
      accentColorHex: '#D32F2F',
      cashBalanceEur: 35000000,
      monthlyBurnRateEur: 2500000,
      brandId: 'brand_vektor',
      rosterSize: 26,
      sponsorCompanyName: 'Nationale Loterij Flanders',
      sponsorIndustry: SponsorIndustry.finance,
    ),
    _TeamPreset(
      id: 'team_kuraudo_jpn',
      name: 'Kuraudo-Toyota Racing Team',
      division: TeamDivision.worldTour,
      countryIso: 'JPN',
      primaryColorHex: '#ECEFF1',
      secondaryColorHex: '#B71C1C',
      accentColorHex: '#263238',
      cashBalanceEur: 41000000,
      monthlyBurnRateEur: 2900000,
      brandId: 'brand_kuraudo',
      rosterSize: 26,
      sponsorCompanyName: 'Toyota Mobility Corp',
      sponsorIndustry: SponsorIndustry.automotive,
    ),
    _TeamPreset(
      id: 'team_ventus_ned',
      name: 'Ventus-Jumbo Wind Power',
      division: TeamDivision.worldTour,
      countryIso: 'NED',
      primaryColorHex: '#E65100',
      secondaryColorHex: '#212121',
      accentColorHex: '#FFD600',
      cashBalanceEur: 39000000,
      monthlyBurnRateEur: 2750000,
      brandId: 'brand_ventus',
      rosterSize: 26,
      sponsorCompanyName: 'Jumbo Supermarkten BV',
      sponsorIndustry: SponsorIndustry.supermarkets,
    ),
    _TeamPreset(
      id: 'team_corsa_armani',
      name: 'Corsa d\'Oro-Armani Squadra',
      division: TeamDivision.worldTour,
      countryIso: 'ITA',
      primaryColorHex: '#B78103',
      secondaryColorHex: '#111111',
      accentColorHex: '#ECEFF1',
      cashBalanceEur: 37000000,
      monthlyBurnRateEur: 2600000,
      brandId: 'brand_corsa_doro',
      rosterSize: 26,
      sponsorCompanyName: 'Giorgio Armani Luxury',
      sponsorIndustry: SponsorIndustry.apparel,
    ),
    _TeamPreset(
      id: 'team_gripmax_fra',
      name: 'GripMax-Michelin Velosport',
      division: TeamDivision.worldTour,
      countryIso: 'FRA',
      primaryColorHex: '#1A237E',
      secondaryColorHex: '#FFD600',
      accentColorHex: '#FFFFFF',
      cashBalanceEur: 33000000,
      monthlyBurnRateEur: 2350000,
      brandId: 'brand_gripmax',
      rosterSize: 26,
      sponsorCompanyName: 'Michelin Tyre Global',
      sponsorIndustry: SponsorIndustry.automotive,
    ),
    _TeamPreset(
      id: 'team_silvan_esp',
      name: 'Silvan-Euskadi Iberia',
      division: TeamDivision.worldTour,
      countryIso: 'ESP',
      primaryColorHex: '#C62828',
      secondaryColorHex: '#2E7D32',
      accentColorHex: '#FFFFFF',
      cashBalanceEur: 32000000,
      monthlyBurnRateEur: 2300000,
      brandId: 'brand_silvan',
      rosterSize: 26,
      sponsorCompanyName: 'Iberia Airlines Group',
      sponsorIndustry: SponsorIndustry.airlines,
    ),
    _TeamPreset(
      id: 'team_apex_aus',
      name: 'Apex-Qantas Pacific Velocity',
      division: TeamDivision.worldTour,
      countryIso: 'AUS',
      primaryColorHex: '#33691E',
      secondaryColorHex: '#212121',
      accentColorHex: '#76FF03',
      cashBalanceEur: 30000000,
      monthlyBurnRateEur: 2150000,
      brandId: 'brand_apex',
      rosterSize: 26,
      sponsorCompanyName: 'Qantas Airways Australia',
      sponsorIndustry: SponsorIndustry.airlines,
    ),
    _TeamPreset(
      id: 'team_boreas_den',
      name: 'Boreas-Maersk Nordic Line',
      division: TeamDivision.worldTour,
      countryIso: 'DEN',
      primaryColorHex: '#37474F',
      secondaryColorHex: '#00B0FF',
      accentColorHex: '#FFFFFF',
      cashBalanceEur: 31000000,
      monthlyBurnRateEur: 2200000,
      brandId: 'brand_boreas',
      rosterSize: 26,
      sponsorCompanyName: 'Maersk Global Shipping',
      sponsorIndustry: SponsorIndustry.energy,
    ),
    _TeamPreset(
      id: 'team_alpina_aut',
      name: 'Alpina-RedBull Energy Velo',
      division: TeamDivision.worldTour,
      countryIso: 'AUT',
      primaryColorHex: '#0D47A1',
      secondaryColorHex: '#D50000',
      accentColorHex: '#FFD600',
      cashBalanceEur: 43000000,
      monthlyBurnRateEur: 3050000,
      brandId: 'brand_kronos',
      rosterSize: 26,
      sponsorCompanyName: 'Red Bull Energy Drinks',
      sponsorIndustry: SponsorIndustry.supermarkets,
    ),
    _TeamPreset(
      id: 'team_oranje_ned',
      name: 'Oranje-Heineken Classic Velo',
      division: TeamDivision.worldTour,
      countryIso: 'NED',
      primaryColorHex: '#FF6D00',
      secondaryColorHex: '#1B5E20',
      accentColorHex: '#FFFFFF',
      cashBalanceEur: 29000000,
      monthlyBurnRateEur: 2050000,
      brandId: 'brand_ventus',
      rosterSize: 26,
      sponsorCompanyName: 'Heineken International',
      sponsorIndustry: SponsorIndustry.supermarkets,
    ),
    _TeamPreset(
      id: 'team_bavaria_ger',
      name: 'Canyon-Bavaria Motors',
      division: TeamDivision.worldTour,
      countryIso: 'GER',
      primaryColorHex: '#004D40',
      secondaryColorHex: '#00E676',
      accentColorHex: '#263238',
      cashBalanceEur: 28000000,
      monthlyBurnRateEur: 2000000,
      brandId: 'brand_sovereign',
      rosterSize: 26,
      sponsorCompanyName: 'Bavaria Motor Werke',
      sponsorIndustry: SponsorIndustry.automotive,
    ),
    _TeamPreset(
      id: 'team_azur_fra',
      name: 'Azur-TotalEnergies France',
      division: TeamDivision.worldTour,
      countryIso: 'FRA',
      primaryColorHex: '#0288D1',
      secondaryColorHex: '#E53935',
      accentColorHex: '#FFFFFF',
      cashBalanceEur: 26000000,
      monthlyBurnRateEur: 1850000,
      brandId: 'brand_gripmax',
      rosterSize: 26,
      sponsorCompanyName: 'TotalEnergies France',
      sponsorIndustry: SponsorIndustry.energy,
    ),

    // -------------------------------------------------------------------------
    // 15 DRUŻYN PROTEAM (BUDŻET 8 - 17 MLN EUR, ROSTER 20 KOLARZY)
    // -------------------------------------------------------------------------
    _TeamPreset(
      id: 'team_polonia_orlen',
      name: 'Polonia-Orlen Racing Team',
      division: TeamDivision.proTeam,
      countryIso: 'POL',
      primaryColorHex: '#D32F2F',
      secondaryColorHex: '#FFFFFF',
      accentColorHex: '#212121',
      cashBalanceEur: 17000000,
      monthlyBurnRateEur: 1200000,
      brandId: 'brand_aethel',
      rosterSize: 20,
      sponsorCompanyName: 'PKN Orlen Petroleum',
      sponsorIndustry: SponsorIndustry.energy,
    ),
    _TeamPreset(
      id: 'team_bravia_swe',
      name: 'Bravia-PostNord Velo',
      division: TeamDivision.proTeam,
      countryIso: 'SWE',
      primaryColorHex: '#0277BD',
      secondaryColorHex: '#FBC02D',
      accentColorHex: '#263238',
      cashBalanceEur: 16000000,
      monthlyBurnRateEur: 1150000,
      brandId: 'brand_nordic',
      rosterSize: 20,
      sponsorCompanyName: 'PostNord Logistics',
      sponsorIndustry: SponsorIndustry.tech,
    ),
    _TeamPreset(
      id: 'team_euskadi_esp',
      name: 'Euskadi-Kutxabank Passion',
      division: TeamDivision.proTeam,
      countryIso: 'ESP',
      primaryColorHex: '#E65100',
      secondaryColorHex: '#2E7D32',
      accentColorHex: '#111111',
      cashBalanceEur: 15000000,
      monthlyBurnRateEur: 1050000,
      brandId: 'brand_silvan',
      rosterSize: 20,
      sponsorCompanyName: 'Kutxabank Euskadi',
      sponsorIndustry: SponsorIndustry.finance,
    ),
    _TeamPreset(
      id: 'team_swiss_alps',
      name: 'Swiss-Alps PostAuto',
      division: TeamDivision.proTeam,
      countryIso: 'SUI',
      primaryColorHex: '#D50000',
      secondaryColorHex: '#FFD600',
      accentColorHex: '#263238',
      cashBalanceEur: 15000000,
      monthlyBurnRateEur: 1050000,
      brandId: 'brand_kronos',
      rosterSize: 20,
      sponsorCompanyName: 'PostAuto Schweiz',
      sponsorIndustry: SponsorIndustry.automotive,
    ),
    _TeamPreset(
      id: 'team_bretagne_fra',
      name: 'Bretagne-Armorique Velo',
      division: TeamDivision.proTeam,
      countryIso: 'FRA',
      primaryColorHex: '#212121',
      secondaryColorHex: '#ECEFF1',
      accentColorHex: '#B71C1C',
      cashBalanceEur: 14000000,
      monthlyBurnRateEur: 1000000,
      brandId: 'brand_gripmax',
      rosterSize: 20,
      sponsorCompanyName: 'Région Bretagne Tourisme',
      sponsorIndustry: SponsorIndustry.supermarkets,
    ),
    _TeamPreset(
      id: 'team_bogota_col',
      name: 'Bogota-Cafe de Colombia',
      division: TeamDivision.proTeam,
      countryIso: 'COL',
      primaryColorHex: '#FBC02D',
      secondaryColorHex: '#0D47A1',
      accentColorHex: '#C62828',
      cashBalanceEur: 14000000,
      monthlyBurnRateEur: 980000,
      brandId: 'brand_veloce',
      rosterSize: 20,
      sponsorCompanyName: 'Federación de Cafeteros',
      sponsorIndustry: SponsorIndustry.supermarkets,
    ),
    _TeamPreset(
      id: 'team_adria_slo',
      name: 'Adria-Krka Triglav Velo',
      division: TeamDivision.proTeam,
      countryIso: 'SLO',
      primaryColorHex: '#0288D1',
      secondaryColorHex: '#2E7D32',
      accentColorHex: '#FFFFFF',
      cashBalanceEur: 14000000,
      monthlyBurnRateEur: 980000,
      brandId: 'brand_olympus',
      rosterSize: 20,
      sponsorCompanyName: 'Krka Pharmaceuticals',
      sponsorIndustry: SponsorIndustry.tech,
    ),
    _TeamPreset(
      id: 'team_wallonie_bel',
      name: 'Wallonie-Ardennes Bpost',
      division: TeamDivision.proTeam,
      countryIso: 'BEL',
      primaryColorHex: '#B71C1C',
      secondaryColorHex: '#FFD600',
      accentColorHex: '#212121',
      cashBalanceEur: 13000000,
      monthlyBurnRateEur: 920000,
      brandId: 'brand_vektor',
      rosterSize: 20,
      sponsorCompanyName: 'Bpost Belgium',
      sponsorIndustry: SponsorIndustry.finance,
    ),
    _TeamPreset(
      id: 'team_padova_ita',
      name: 'Padova-Prosecco Cycling',
      division: TeamDivision.proTeam,
      countryIso: 'ITA',
      primaryColorHex: '#33691E',
      secondaryColorHex: '#FFD600',
      accentColorHex: '#212121',
      cashBalanceEur: 13000000,
      monthlyBurnRateEur: 920000,
      brandId: 'brand_corsa_doro',
      rosterSize: 20,
      sponsorCompanyName: 'Consorzio Prosecco DOC',
      sponsorIndustry: SponsorIndustry.supermarkets,
    ),
    _TeamPreset(
      id: 'team_tirol_aut',
      name: 'Tirol-KTM Berggeist',
      division: TeamDivision.proTeam,
      countryIso: 'AUT',
      primaryColorHex: '#E65100',
      secondaryColorHex: '#212121',
      accentColorHex: '#FFFFFF',
      cashBalanceEur: 12000000,
      monthlyBurnRateEur: 850000,
      brandId: 'brand_boreas',
      rosterSize: 20,
      sponsorCompanyName: 'KTM Sportmotorcycles',
      sponsorIndustry: SponsorIndustry.automotive,
    ),
    _TeamPreset(
      id: 'team_vlaanderen_bel',
      name: 'Vlaanderen-Gent Bicycles',
      division: TeamDivision.proTeam,
      countryIso: 'BEL',
      primaryColorHex: '#212121',
      secondaryColorHex: '#FDD835',
      accentColorHex: '#E53935',
      cashBalanceEur: 12000000,
      monthlyBurnRateEur: 850000,
      brandId: 'brand_vektor',
      rosterSize: 20,
      sponsorCompanyName: 'Sport Vlaanderen',
      sponsorIndustry: SponsorIndustry.finance,
    ),
    _TeamPreset(
      id: 'team_olympus_gre',
      name: 'Olympus-Hellenic Air',
      division: TeamDivision.proTeam,
      countryIso: 'GRE',
      primaryColorHex: '#00838F',
      secondaryColorHex: '#E0F7FA',
      accentColorHex: '#004D40',
      cashBalanceEur: 11000000,
      monthlyBurnRateEur: 780000,
      brandId: 'brand_olympus',
      rosterSize: 20,
      sponsorCompanyName: 'Aegean Airlines Greece',
      sponsorIndustry: SponsorIndustry.airlines,
    ),
    _TeamPreset(
      id: 'team_algarve_por',
      name: 'Algarve-Sagres Ciclismo',
      division: TeamDivision.proTeam,
      countryIso: 'POR',
      primaryColorHex: '#C2185B',
      secondaryColorHex: '#FFC107',
      accentColorHex: '#263238',
      cashBalanceEur: 10000000,
      monthlyBurnRateEur: 720000,
      brandId: 'brand_silvan',
      rosterSize: 20,
      sponsorCompanyName: 'Cerveja Sagres Portugal',
      sponsorIndustry: SponsorIndustry.supermarkets,
    ),
    _TeamPreset(
      id: 'team_caledonia_gbr',
      name: 'Caledonia-Highland Malt',
      division: TeamDivision.proTeam,
      countryIso: 'GBR',
      primaryColorHex: '#1A237E',
      secondaryColorHex: '#37474F',
      accentColorHex: '#FFFFFF',
      cashBalanceEur: 9000000,
      monthlyBurnRateEur: 650000,
      brandId: 'brand_aethel',
      rosterSize: 20,
      sponsorCompanyName: 'Highland Spring UK',
      sponsorIndustry: SponsorIndustry.supermarkets,
    ),
    _TeamPreset(
      id: 'team_auckland_nzl',
      name: 'Auckland-Kiwi Express',
      division: TeamDivision.proTeam,
      countryIso: 'NZL',
      primaryColorHex: '#111111',
      secondaryColorHex: '#ECEFF1',
      accentColorHex: '#00B0FF',
      cashBalanceEur: 8000000,
      monthlyBurnRateEur: 580000,
      brandId: 'brand_apex',
      rosterSize: 20,
      sponsorCompanyName: 'Air New Zealand',
      sponsorIndustry: SponsorIndustry.airlines,
    ),

    // -------------------------------------------------------------------------
    // 20 DRUŻYN CONTINENTAL (BUDŻET 1.8 - 4.2 MLN EUR, ROSTER 12 KOLARZY)
    // -------------------------------------------------------------------------
    _TeamPreset(
      id: 'team_mazovia_pol',
      name: 'Mazovia-Warszawa Continental',
      division: TeamDivision.continental,
      countryIso: 'POL',
      primaryColorHex: '#C62828',
      secondaryColorHex: '#FFFFFF',
      accentColorHex: '#1A237E',
      cashBalanceEur: 3800000,
      monthlyBurnRateEur: 280000,
      brandId: 'brand_aethel',
      rosterSize: 12,
      sponsorCompanyName: 'Mazovia Bank Spółdzielczy',
      sponsorIndustry: SponsorIndustry.finance,
    ),
    _TeamPreset(
      id: 'team_lombardia_ita',
      name: 'Lombardia-Como Talents',
      division: TeamDivision.continental,
      countryIso: 'ITA',
      primaryColorHex: '#0D47A1',
      secondaryColorHex: '#00B0FF',
      accentColorHex: '#212121',
      cashBalanceEur: 4200000,
      monthlyBurnRateEur: 310000,
      brandId: 'brand_veloce',
      rosterSize: 12,
      sponsorCompanyName: 'Banca Popolare di Milano',
      sponsorIndustry: SponsorIndustry.finance,
    ),
    _TeamPreset(
      id: 'team_almaty_kaz',
      name: 'Almaty-Kazakh Steppe',
      division: TeamDivision.continental,
      countryIso: 'KAZ',
      primaryColorHex: '#00B0FF',
      secondaryColorHex: '#FFD600',
      accentColorHex: '#263238',
      cashBalanceEur: 4100000,
      monthlyBurnRateEur: 300000,
      brandId: 'brand_kuraudo',
      rosterSize: 12,
      sponsorCompanyName: 'Samruk-Kazyna Fund',
      sponsorIndustry: SponsorIndustry.energy,
    ),
    _TeamPreset(
      id: 'team_medellin_col',
      name: 'Antioquia-Medellin Climbers',
      division: TeamDivision.continental,
      countryIso: 'COL',
      primaryColorHex: '#FBC02D',
      secondaryColorHex: '#2E7D32',
      accentColorHex: '#111111',
      cashBalanceEur: 3900000,
      monthlyBurnRateEur: 2850000,
      brandId: 'brand_veloce',
      rosterSize: 12,
      sponsorCompanyName: 'EPM Medellin Energia',
      sponsorIndustry: SponsorIndustry.energy,
    ),
    _TeamPreset(
      id: 'team_brabant_ned',
      name: 'Brabant-Eindhoven Tech',
      division: TeamDivision.continental,
      countryIso: 'NED',
      primaryColorHex: '#D50000',
      secondaryColorHex: '#FFFFFF',
      accentColorHex: '#212121',
      cashBalanceEur: 3600000,
      monthlyBurnRateEur: 265000,
      brandId: 'brand_ventus',
      rosterSize: 12,
      sponsorCompanyName: 'ASML Semiconductor Tech',
      sponsorIndustry: SponsorIndustry.tech,
    ),
    _TeamPreset(
      id: 'team_provence_fra',
      name: 'Provence-Lavande Cyclisme',
      division: TeamDivision.continental,
      countryIso: 'FRA',
      primaryColorHex: '#6A1B9A',
      secondaryColorHex: '#E1BEE7',
      accentColorHex: '#263238',
      cashBalanceEur: 3500000,
      monthlyBurnRateEur: 255000,
      brandId: 'brand_gripmax',
      rosterSize: 12,
      sponsorCompanyName: 'L\'Occitane en Provence',
      sponsorIndustry: SponsorIndustry.supermarkets,
    ),
    _TeamPreset(
      id: 'team_andalucia_esp',
      name: 'Andalucia-Sevilla Sol',
      division: TeamDivision.continental,
      countryIso: 'ESP',
      primaryColorHex: '#2E7D32',
      secondaryColorHex: '#FFFFFF',
      accentColorHex: '#FBC02D',
      cashBalanceEur: 3400000,
      monthlyBurnRateEur: 250000,
      brandId: 'brand_silvan',
      rosterSize: 12,
      sponsorCompanyName: 'Junta de Andalucia',
      sponsorIndustry: SponsorIndustry.finance,
    ),
    _TeamPreset(
      id: 'team_yorkshire_gbr',
      name: 'Yorkshire-Dales Cycling',
      division: TeamDivision.continental,
      countryIso: 'GBR',
      primaryColorHex: '#1B5E20',
      secondaryColorHex: '#FFD600',
      accentColorHex: '#212121',
      cashBalanceEur: 3300000,
      monthlyBurnRateEur: 240000,
      brandId: 'brand_aethel',
      rosterSize: 12,
      sponsorCompanyName: 'Yorkshire Tea & Co',
      sponsorIndustry: SponsorIndustry.supermarkets,
    ),
    _TeamPreset(
      id: 'team_bavaria_jr_ger',
      name: 'Bavaria-Alpen Junior Velo',
      division: TeamDivision.continental,
      countryIso: 'GER',
      primaryColorHex: '#0091EA',
      secondaryColorHex: '#FFFFFF',
      accentColorHex: '#37474F',
      cashBalanceEur: 3200000,
      monthlyBurnRateEur: 235000,
      brandId: 'brand_sovereign',
      rosterSize: 12,
      sponsorCompanyName: 'Allianz Junior Sport',
      sponsorIndustry: SponsorIndustry.finance,
    ),
    _TeamPreset(
      id: 'team_jutland_den',
      name: 'Jutland-Vejle Cycling',
      division: TeamDivision.continental,
      countryIso: 'DEN',
      primaryColorHex: '#C62828',
      secondaryColorHex: '#263238',
      accentColorHex: '#FFFFFF',
      cashBalanceEur: 3100000,
      monthlyBurnRateEur: 225000,
      brandId: 'brand_boreas',
      rosterSize: 12,
      sponsorCompanyName: 'Lego Group Denmark',
      sponsorIndustry: SponsorIndustry.tech,
    ),
    _TeamPreset(
      id: 'team_bohemia_cze',
      name: 'Bohemia-Praha Velo',
      division: TeamDivision.continental,
      countryIso: 'CZE',
      primaryColorHex: '#C62828',
      secondaryColorHex: '#0D47A1',
      accentColorHex: '#FFFFFF',
      cashBalanceEur: 3000000,
      monthlyBurnRateEur: 220000,
      brandId: 'brand_boreas',
      rosterSize: 12,
      sponsorCompanyName: 'Škoda Auto Mladá Boleslav',
      sponsorIndustry: SponsorIndustry.automotive,
    ),
    _TeamPreset(
      id: 'team_normandie_fra',
      name: 'Normandie-Rouen Velo Club',
      division: TeamDivision.continental,
      countryIso: 'FRA',
      primaryColorHex: '#B71C1C',
      secondaryColorHex: '#FFC107',
      accentColorHex: '#212121',
      cashBalanceEur: 2900000,
      monthlyBurnRateEur: 210000,
      brandId: 'brand_gripmax',
      rosterSize: 12,
      sponsorCompanyName: 'Crédit Agricole Normandie',
      sponsorIndustry: SponsorIndustry.finance,
    ),
    _TeamPreset(
      id: 'team_krakow_pol',
      name: 'Kraków-Wawel Academy',
      division: TeamDivision.continental,
      countryIso: 'POL',
      primaryColorHex: '#0D47A1',
      secondaryColorHex: '#FFFFFF',
      accentColorHex: '#D32F2F',
      cashBalanceEur: 2800000,
      monthlyBurnRateEur: 200000,
      brandId: 'brand_aethel',
      rosterSize: 12,
      sponsorCompanyName: 'Comarch Software Kraków',
      sponsorIndustry: SponsorIndustry.tech,
    ),
    _TeamPreset(
      id: 'team_limburg_ned',
      name: 'Limburg-Valkenburg Hills',
      division: TeamDivision.continental,
      countryIso: 'NED',
      primaryColorHex: '#FFD600',
      secondaryColorHex: '#212121',
      accentColorHex: '#1B5E20',
      cashBalanceEur: 2700000,
      monthlyBurnRateEur: 195000,
      brandId: 'brand_ventus',
      rosterSize: 12,
      sponsorCompanyName: 'DSM-Firmenich Nutrition',
      sponsorIndustry: SponsorIndustry.energy,
    ),
    _TeamPreset(
      id: 'team_sicilia_ita',
      name: 'Sicilia-Etna Vulcano',
      division: TeamDivision.continental,
      countryIso: 'ITA',
      primaryColorHex: '#BF360C',
      secondaryColorHex: '#212121',
      accentColorHex: '#FFD600',
      cashBalanceEur: 2600000,
      monthlyBurnRateEur: 185000,
      brandId: 'brand_corsa_doro',
      rosterSize: 12,
      sponsorCompanyName: 'Regione Siciliana',
      sponsorIndustry: SponsorIndustry.finance,
    ),
    _TeamPreset(
      id: 'team_asmara_eri',
      name: 'Asmara-Horn of Africa',
      division: TeamDivision.continental,
      countryIso: 'ERI',
      primaryColorHex: '#00838F',
      secondaryColorHex: '#C62828',
      accentColorHex: '#FBC02D',
      cashBalanceEur: 2500000,
      monthlyBurnRateEur: 175000,
      brandId: 'brand_olympus',
      rosterSize: 12,
      sponsorCompanyName: 'Eritrea Telecommunications',
      sponsorIndustry: SponsorIndustry.tech,
    ),
    _TeamPreset(
      id: 'team_galicia_esp',
      name: 'Galicia-Camino Ciclismo',
      division: TeamDivision.continental,
      countryIso: 'ESP',
      primaryColorHex: '#0288D1',
      secondaryColorHex: '#FFFFFF',
      accentColorHex: '#FFD600',
      cashBalanceEur: 2400000,
      monthlyBurnRateEur: 170000,
      brandId: 'brand_silvan',
      rosterSize: 12,
      sponsorCompanyName: 'Abanca Corporación Bancaria',
      sponsorIndustry: SponsorIndustry.finance,
    ),
    _TeamPreset(
      id: 'team_tatra_pol',
      name: 'Tatra-Zakopane Velo',
      division: TeamDivision.continental,
      countryIso: 'POL',
      primaryColorHex: '#37474F',
      secondaryColorHex: '#00B0FF',
      accentColorHex: '#ECEFF1',
      cashBalanceEur: 2200000,
      monthlyBurnRateEur: 155000,
      brandId: 'brand_olympus',
      rosterSize: 12,
      sponsorCompanyName: 'Tatrzański Związek Narciarski',
      sponsorIndustry: SponsorIndustry.apparel,
    ),
    _TeamPreset(
      id: 'team_sachsen_ger',
      name: 'Sachsen-Dresden Velo',
      division: TeamDivision.continental,
      countryIso: 'GER',
      primaryColorHex: '#2E7D32',
      secondaryColorHex: '#ECEFF1',
      accentColorHex: '#212121',
      cashBalanceEur: 2100000,
      monthlyBurnRateEur: 150000,
      brandId: 'brand_sovereign',
      rosterSize: 12,
      sponsorCompanyName: 'Freistaat Sachsen Sport',
      sponsorIndustry: SponsorIndustry.finance,
    ),
    _TeamPreset(
      id: 'team_bratislava_svk',
      name: 'Bratislava-Dunaj Cycling',
      division: TeamDivision.continental,
      countryIso: 'SVK',
      primaryColorHex: '#0D47A1',
      secondaryColorHex: '#C62828',
      accentColorHex: '#FFFFFF',
      cashBalanceEur: 1800000,
      monthlyBurnRateEur: 130000,
      brandId: 'brand_olympus',
      rosterSize: 12,
      sponsorCompanyName: 'Slovnaft Petroleum Bratislava',
      sponsorIndustry: SponsorIndustry.energy,
    ),
  ];
}

