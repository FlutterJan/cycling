import 'dart:math' as math;

import '../../models/career/womens_worldtour_and_mixed_relay_model.dart';
import '../../models/rider/lactate_and_lab_profile.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_appearance.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/rider/rider_health.dart';
import '../../models/rider/rider_physiology.dart';
import '../../models/rider/rider_power_profile.dart';
import '../../models/rider/rider_skills.dart';

/// Pełny profil wygenerowanej zawodniczki łączący model [Rider] z profilem [WomensPhysiologyProfile].
class WomensSeededRider {
  final Rider rider;
  final WomensPhysiologyProfile womensPhysiology;
  final int womensOverallRating;

  const WomensSeededRider({
    required this.rider,
    required this.womensPhysiology,
    required this.womensOverallRating,
  });

  String get id => rider.id;
  String get fullName => rider.fullName;
  String get teamId => rider.contract.teamId;
}

/// Wynik działania generatora kobiecego peletonu (24 drużyny, 360 zawodniczek, rynek transferowy).
class WomensWorldTourSeedResult {
  final int seasonYear;
  final List<WomensTeamProfile> teams;
  final List<WomensSeededRider> seededRiders;
  final List<Rider> allRiders;
  final Map<String, List<WomensSeededRider>> ridersByTeamId;
  final Map<String, WomensPhysiologyProfile> physiologyByRiderId;
  final List<WomensTransferListing> transferMarket;
  final List<WomensRaceEvent> calendarEvents;
  final WomensWorldTourSeasonState seasonState;

  const WomensWorldTourSeedResult({
    required this.seasonYear,
    required this.teams,
    required this.seededRiders,
    required this.allRiders,
    required this.ridersByTeamId,
    required this.physiologyByRiderId,
    required this.transferMarket,
    required this.calendarEvents,
    required this.seasonState,
  });

  List<WomensTeamProfile> get worldTourTeams => teams
      .where((t) => t.division == WomensDivision.womensWorldTour)
      .toList();

  List<WomensTeamProfile> get proTeams => teams
      .where((t) => t.division == WomensDivision.womensProTeam)
      .toList();

  List<WomensTeamProfile> get continentalTeams => teams
      .where((t) => t.division == WomensDivision.womensContinental)
      .toList();

  List<WomensTransferListing> get freeAgentListings =>
      transferMarket.where((l) => l.isFreeAgent).toList();

  List<WomensTransferListing> get contractedTransferListings =>
      transferMarket.where((l) => !l.isFreeAgent).toList();

  WomensTeamProfile? getTeamById(String teamId) {
    for (final team in teams) {
      if (team.teamId == teamId) return team;
    }
    return null;
  }

  List<WomensSeededRider> getTeamRoster(String teamId) =>
      ridersByTeamId[teamId] ?? const [];
}

class _WomensTeamPreset {
  final String teamId;
  final String name;
  final String shortCode;
  final String countryIso;
  final WomensDivision division;
  final String primaryColorHex;
  final String secondaryColorHex;
  final int annualBudgetEur;
  final int initialUciPoints;
  final String? linkedMensTeamId;
  final int staffLevel;
  final int equipmentTier;
  final int tierStrengthBonus;

  const _WomensTeamPreset({
    required this.teamId,
    required this.name,
    required this.shortCode,
    required this.countryIso,
    required this.division,
    required this.primaryColorHex,
    required this.secondaryColorHex,
    required this.annualBudgetEur,
    required this.initialUciPoints,
    this.linkedMensTeamId,
    required this.staffLevel,
    required this.equipmentTier,
    required this.tierStrengthBonus,
  });
}

/// Generator 24 kobiecych drużyn kolarskich (15 WWT, 6 ProTeam, 3 Continental)
/// oraz 360 zawodniczek (15 w każdym zespole) z fizjologią skalibrowaną pod kobiecy peleton
/// i kompletnym rynkiem transferowym (wolne agentki + zawodniczki na liście transferowej).
class WomensWorldtourTeamsAndRidersSeeder {
  WomensWorldtourTeamsAndRidersSeeder._();

  static const int totalTeamsCount = 24;
  static const int ridersPerTeam = 15;
  static const int totalRosterRidersCount = totalTeamsCount * ridersPerTeam; // 360

  /// Generuje kompletny ekosystem UCI Women's WorldTour na zadany sezon.
  static WomensWorldTourSeedResult seedWomensWorldTour({
    int seasonYear = 2026,
    int seed = 20260375,
    int freeAgentsCount = 30,
  }) {
    final rng = math.Random(seed);
    final List<WomensTeamProfile> teams = [];
    final List<WomensSeededRider> allSeededRiders = [];
    final List<Rider> allRiders = [];
    final Map<String, List<WomensSeededRider>> ridersByTeamId = {};
    final Map<String, WomensPhysiologyProfile> physiologyByRiderId = {};
    final List<WomensTransferListing> transferMarket = [];
    final Set<String> usedNames = <String>{};

    for (final preset in _teamPresets) {
      final teamRoster = _generateTeamRoster(
        preset: preset,
        seasonYear: seasonYear,
        rng: rng,
        usedNames: usedNames,
      );

      final riderIds = <String>[];
      for (final seeded in teamRoster) {
        riderIds.add(seeded.id);
        allSeededRiders.add(seeded);
        allRiders.add(seeded.rider);
        physiologyByRiderId[seeded.id] = seeded.womensPhysiology;

        // Zawodniczki z wygasającym kontraktem (1 rok) lub niezadowolone trafiają na rynek transferowy
        if (seeded.rider.contract.contractEndYear <= seasonYear + 1 ||
            seeded.rider.contract.morale < 72.0) {
          final annualSalary = seeded.rider.contract.monthlySalaryEur * 12;
          final isExpiring =
              seeded.rider.contract.contractEndYear <= seasonYear;
          final buyout = isExpiring
              ? 0
              : (seeded.rider.contract.releaseClauseEur * 0.65).round();
          transferMarket.add(
            WomensTransferListing(
              riderId: seeded.id,
              riderName: seeded.fullName,
              nationalityIso: seeded.rider.nationalityIso,
              currentTeamId: preset.teamId,
              overallRating: seeded.womensOverallRating,
              annualSalaryDemandEur: (annualSalary * 1.08).round(),
              buyoutFeeEur: buyout,
              contractYearsDesired: seeded.rider.age >= 30 ? 1 : 2 + rng.nextInt(2),
            ),
          );
        }
      }

      ridersByTeamId[preset.teamId] = List<WomensSeededRider>.unmodifiable(
        teamRoster,
      );

      teams.add(
        WomensTeamProfile(
          teamId: preset.teamId,
          name: preset.name,
          shortCode: preset.shortCode,
          countryIso: preset.countryIso,
          division: preset.division,
          primaryColorHex: preset.primaryColorHex,
          secondaryColorHex: preset.secondaryColorHex,
          annualBudgetEur: preset.annualBudgetEur,
          uciPoints: preset.initialUciPoints,
          seasonWins: 0,
          linkedMensTeamId: preset.linkedMensTeamId,
          rosterRiderIds: List<String>.unmodifiable(riderIds),
          staffLevel: preset.staffLevel,
          equipmentTier: preset.equipmentTier,
        ),
      );
    }

    // Generuj wolne agentki na rynku transferowym
    for (int i = 0; i < freeAgentsCount; i++) {
      final spec = _pickSpecializationForSlot(i % 15, rng);
      final targetOvr = 62 + rng.nextInt(22); // 62-83
      final seeded = _generateSingleRider(
        id: 'wwt_fa_${i.toString().padLeft(3, '0')}',
        teamId: 'free_agent',
        teamCountryIso: _supportedNations[rng.nextInt(_supportedNations.length)],
        role: RiderRole.domestique,
        specialization: spec,
        targetOvr: targetOvr,
        seasonYear: seasonYear,
        rng: rng,
        usedNames: usedNames,
        forceFreeAgent: true,
      );

      final annualSalary = seeded.rider.contract.monthlySalaryEur * 12;
      transferMarket.add(
        WomensTransferListing(
          riderId: seeded.id,
          riderName: seeded.fullName,
          nationalityIso: seeded.rider.nationalityIso,
          currentTeamId: null,
          overallRating: seeded.womensOverallRating,
          annualSalaryDemandEur: annualSalary,
          buyoutFeeEur: 0,
          contractYearsDesired: 1 + rng.nextInt(2),
        ),
      );
    }

    transferMarket.sort((a, b) => b.overallRating.compareTo(a.overallRating));

    final calendarEvents = _buildDefaultWomensCalendar(seasonYear);
    final seasonState = WomensWorldTourSeasonState(
      seasonYear: seasonYear,
      teams: List<WomensTeamProfile>.unmodifiable(teams),
      calendarEvents: List<WomensRaceEvent>.unmodifiable(calendarEvents),
      individualUciStandings: const {},
      youthUciStandings: const {},
      transferMarket: List<WomensTransferListing>.unmodifiable(transferMarket),
    );

    return WomensWorldTourSeedResult(
      seasonYear: seasonYear,
      teams: List<WomensTeamProfile>.unmodifiable(teams),
      seededRiders: List<WomensSeededRider>.unmodifiable(allSeededRiders),
      allRiders: List<Rider>.unmodifiable(allRiders),
      ridersByTeamId: Map<String, List<WomensSeededRider>>.unmodifiable(
        ridersByTeamId,
      ),
      physiologyByRiderId:
          Map<String, WomensPhysiologyProfile>.unmodifiable(
        physiologyByRiderId,
      ),
      transferMarket: List<WomensTransferListing>.unmodifiable(transferMarket),
      calendarEvents: List<WomensRaceEvent>.unmodifiable(calendarEvents),
      seasonState: seasonState,
    );
  }

  static List<WomensSeededRider> _generateTeamRoster({
    required _WomensTeamPreset preset,
    required int seasonYear,
    required math.Random rng,
    required Set<String> usedNames,
  }) {
    final List<WomensSeededRider> roster = [];
    final int baseOvr = switch (preset.division) {
      WomensDivision.womensWorldTour => 74 + preset.tierStrengthBonus,
      WomensDivision.womensProTeam => 67 + preset.tierStrengthBonus,
      WomensDivision.womensContinental => 61 + preset.tierStrengthBonus,
    };

    for (int slot = 0; slot < ridersPerTeam; slot++) {
      final role = _roleForSlot(slot);
      final spec = _pickSpecializationForSlot(slot, rng);
      final roleOvrDelta = switch (role) {
        RiderRole.teamLeader => 11 + rng.nextInt(5),
        RiderRole.coLeader => 8 + rng.nextInt(4),
        RiderRole.sprinter => 8 + rng.nextInt(5),
        RiderRole.superDomestique => 5 + rng.nextInt(4),
        RiderRole.breakawaySpecialist => 2 + rng.nextInt(5),
        RiderRole.domestique => -2 + rng.nextInt(5),
        RiderRole.neoPro => -5 + rng.nextInt(6),
      };

      final targetOvr = (baseOvr + roleOvrDelta).clamp(54, 96);
      final seeded = _generateSingleRider(
        id: '${preset.teamId}_r_${(slot + 1).toString().padLeft(2, '0')}',
        teamId: preset.teamId,
        teamCountryIso: preset.countryIso,
        role: role,
        specialization: spec,
        targetOvr: targetOvr,
        seasonYear: seasonYear,
        rng: rng,
        usedNames: usedNames,
      );
      roster.add(seeded);
    }

    return roster;
  }

  static RiderRole _roleForSlot(int slot) {
    if (slot == 0) return RiderRole.teamLeader;
    if (slot == 1) return RiderRole.coLeader;
    if (slot == 2) return RiderRole.sprinter;
    if (slot == 3 || slot == 4) return RiderRole.superDomestique;
    if (slot == 5 || slot == 6) return RiderRole.breakawaySpecialist;
    if (slot >= 13) return RiderRole.neoPro;
    return RiderRole.domestique;
  }

  static RiderSpecialization _pickSpecializationForSlot(
    int slot,
    math.Random rng,
  ) {
    switch (slot) {
      case 0:
        return rng.nextBool()
            ? RiderSpecialization.gcClimber
            : RiderSpecialization.puncher;
      case 1:
        return rng.nextBool()
            ? RiderSpecialization.pureClimber
            : RiderSpecialization.classicCobbles;
      case 2:
        return rng.nextBool()
            ? RiderSpecialization.pureSprinter
            : RiderSpecialization.versatileSprinter;
      case 3:
        return RiderSpecialization.timeTrialist;
      case 4:
        return RiderSpecialization.gcClimber;
      case 5:
      case 6:
        return RiderSpecialization.breakawaySpecialist;
      case 7:
      case 8:
        return RiderSpecialization.classicCobbles;
      case 9:
      case 10:
        return RiderSpecialization.versatileSprinter;
      default:
        return RiderSpecialization.domestiqueEngine;
    }
  }

  static WomensSeededRider _generateSingleRider({
    required String id,
    required String teamId,
    required String teamCountryIso,
    required RiderRole role,
    required RiderSpecialization specialization,
    required int targetOvr,
    required int seasonYear,
    required math.Random rng,
    required Set<String> usedNames,
    bool forceFreeAgent = false,
  }) {
    // 45% szans na narodowość kraju drużyny, 55% międzynarodową
    final nation = (rng.nextDouble() < 0.45 &&
            _womensNamesDatabase.containsKey(teamCountryIso))
        ? teamCountryIso
        : _supportedNations[rng.nextInt(_supportedNations.length)];

    final (firstName, lastName) = _generateUniqueFemaleName(
      nation: nation,
      rng: rng,
      usedNames: usedNames,
    );

    final int age = switch (role) {
      RiderRole.neoPro => 19 + rng.nextInt(3), // 19-21
      RiderRole.teamLeader || RiderRole.coLeader => 23 + rng.nextInt(9),
      _ => 21 + rng.nextInt(13), // 21-33
    };

    final int potential = role == RiderRole.neoPro
        ? (targetOvr + 8 + rng.nextInt(12)).clamp(targetOvr, 97)
        : (targetOvr + rng.nextInt(5)).clamp(targetOvr, 99);

    final (physiology, womensPhysiology, powerProfile) =
        _generateWomensPhysiologyAndPower(
      specialization: specialization,
      targetOvr: targetOvr,
      age: age,
      rng: rng,
    );

    final skills = _generateSkills(specialization, targetOvr, rng);
    final appearance = _generateFemaleAppearance(specialization, nation, rng);

    final int annualSalaryEur = _calculateWomensAnnualSalaryEur(
      targetOvr: targetOvr,
      role: role,
      age: age,
    );
    final int monthlySalaryEur = (annualSalaryEur / 12.0).round();
    final int contractEndYear = forceFreeAgent
        ? seasonYear
        : seasonYear + (rng.nextDouble() < 0.25 ? 0 : 1 + rng.nextInt(3));

    final contract = RiderContract(
      teamId: teamId,
      role: role,
      monthlySalaryEur: monthlySalaryEur,
      signingBonusEur: (monthlySalaryEur * 1.5).round(),
      winBonusEur: (monthlySalaryEur * 0.8).round(),
      releaseClauseEur: annualSalaryEur * 2,
      contractEndYear: contractEndYear,
      morale: 68.0 + rng.nextDouble() * 26.0,
      leaderLoyalty: 58.0 + rng.nextDouble() * 38.0,
      requiredRacesIds: const [],
    );

    final health = RiderHealth(
      acuteTrainingLoad: 70.0 + rng.nextDouble() * 22.0,
      chronicTrainingLoad: 80.0 + rng.nextDouble() * 25.0,
      currentInjury: null,
      currentIllness: null,
    );

    final birthYear = seasonYear - age;
    final birthDate = DateTime(
      birthYear,
      1 + rng.nextInt(12),
      1 + rng.nextInt(28),
    );

    final labProfile = LactateAndLabProfile.fromPhysiology(
      physiology,
      specialization: specialization,
      powerProfile: powerProfile,
    );

    final rider = Rider(
      id: id,
      firstName: firstName,
      lastName: lastName,
      nationalityIso: nation,
      birthDate: birthDate,
      potential: potential,
      specialization: specialization,
      physiology: physiology.copyWith(labProfile: labProfile),
      powerProfile: powerProfile,
      skills: skills,
      appearance: appearance,
      contract: contract,
      health: health,
      careerPointsUci: (targetOvr - 50).clamp(0, 50) * (12 + rng.nextInt(25)),
    );

    return WomensSeededRider(
      rider: rider,
      womensPhysiology: womensPhysiology,
      womensOverallRating: womensPhysiology.overallRating,
    );
  }

  /// Kalibrowana fizjologia kobiecego peletonu UCI Women's WorldTour.
  /// - Góralki: 48-55 kg, 5.2-6.0 W/kg (20m), sprint 740-960 W
  /// - Sprinterki: 60-68 kg, 4.6-5.2 W/kg (20m), sprint 1060-1260 W
  /// - Klasykowce / Czasowczynie: 55-64 kg, 5.1-5.8 W/kg, niskie CdA
  static (RiderPhysiology, WomensPhysiologyProfile, RiderPowerProfile)
      _generateWomensPhysiologyAndPower({
    required RiderSpecialization specialization,
    required int targetOvr,
    required int age,
    required math.Random rng,
  }) {
    final double norm = ((targetOvr - 54) / (96 - 54)).clamp(0.0, 1.0);

    final (
      double minW,
      double maxW,
      double minH,
      double maxH,
      double baseFat,
      double cdaBase
    ) = switch (specialization) {
      RiderSpecialization.pureClimber => (47.5, 53.5, 156.0, 168.0, 11.5, 0.198),
      RiderSpecialization.gcClimber => (50.0, 56.5, 160.0, 172.0, 12.0, 0.203),
      RiderSpecialization.puncher => (53.0, 59.5, 162.0, 173.0, 12.8, 0.208),
      RiderSpecialization.classicCobbles => (
          56.5,
          63.5,
          166.0,
          176.0,
          13.2,
          0.214
        ),
      RiderSpecialization.timeTrialist => (
          55.0,
          62.5,
          165.0,
          176.0,
          12.5,
          0.194
        ),
      RiderSpecialization.pureSprinter => (
          60.0,
          68.0,
          167.0,
          178.0,
          14.0,
          0.224
        ),
      RiderSpecialization.versatileSprinter => (
          57.0,
          64.0,
          165.0,
          175.0,
          13.5,
          0.218
        ),
      RiderSpecialization.breakawaySpecialist => (
          54.0,
          61.0,
          163.0,
          174.0,
          13.0,
          0.210
        ),
      RiderSpecialization.domestiqueEngine => (
          55.0,
          63.0,
          164.0,
          175.0,
          13.6,
          0.215
        ),
    };

    final double weightKg =
        double.parse((minW + rng.nextDouble() * (maxW - minW)).toStringAsFixed(1));
    final double heightCm =
        double.parse((minH + rng.nextDouble() * (maxH - minH)).toStringAsFixed(1));
    final double bodyFat = double.parse(
      (baseFat + (rng.nextDouble() * 2.2 - 1.1)).clamp(10.5, 18.0).toStringAsFixed(1),
    );

    // Skalowanie W/kg dla FTP i 20m wg specjalizacji i OVR
    final double ftpWkgBase = switch (specialization) {
      RiderSpecialization.gcClimber ||
      RiderSpecialization.pureClimber =>
        3.95 + norm * 1.85, // 3.95 - 5.80 W/kg
      RiderSpecialization.timeTrialist => 3.90 + norm * 1.75,
      RiderSpecialization.puncher ||
      RiderSpecialization.classicCobbles =>
        3.80 + norm * 1.65,
      RiderSpecialization.versatileSprinter ||
      RiderSpecialization.breakawaySpecialist =>
        3.70 + norm * 1.50,
      RiderSpecialization.domestiqueEngine => 3.65 + norm * 1.45,
      RiderSpecialization.pureSprinter => 3.45 + norm * 1.35,
    };

    final double ftpWatts = (weightKg * ftpWkgBase).clamp(195.0, 385.0);
    final double watts20m = ftpWatts * (1.04 + rng.nextDouble() * 0.03);
    final double watts60m = ftpWatts * (0.94 + rng.nextDouble() * 0.03);
    final double watts5m = watts20m *
        (specialization == RiderSpecialization.puncher ||
                specialization == RiderSpecialization.gcClimber
            ? 1.18 + rng.nextDouble() * 0.05
            : 1.13 + rng.nextDouble() * 0.04);
    final double watts3m = watts5m * (1.07 + rng.nextDouble() * 0.04);

    // Moc beztlenowa i sprinterska (5s, 15s, 30s, 1m)
    final double sprintBase5s = switch (specialization) {
      RiderSpecialization.pureSprinter => 900.0 + norm * 360.0, // do ~1260 W
      RiderSpecialization.versatileSprinter => 840.0 + norm * 320.0,
      RiderSpecialization.classicCobbles => 790.0 + norm * 280.0,
      RiderSpecialization.puncher => 760.0 + norm * 260.0,
      RiderSpecialization.breakawaySpecialist => 730.0 + norm * 230.0,
      RiderSpecialization.timeTrialist => 710.0 + norm * 210.0,
      RiderSpecialization.domestiqueEngine => 700.0 + norm * 210.0,
      RiderSpecialization.gcClimber => 670.0 + norm * 200.0,
      RiderSpecialization.pureClimber => 640.0 + norm * 190.0,
    };
    final double watts5s =
        (sprintBase5s + (rng.nextDouble() * 40.0 - 20.0)).clamp(620.0, 1280.0);
    final double watts15s = watts5s * (0.88 + rng.nextDouble() * 0.04);
    final double watts30s = watts5s * (0.71 + rng.nextDouble() * 0.05);
    final double watts1m = math.max(
      watts3m * 1.15,
      watts5s * (0.50 + rng.nextDouble() * 0.06),
    );

    final double vo2Max =
        (60.0 + norm * 18.5 + (rng.nextDouble() * 2.4 - 1.2)).clamp(58.0, 81.5);
    final double wPrimeJoules = switch (specialization) {
      RiderSpecialization.pureSprinter ||
      RiderSpecialization.versatileSprinter =>
        15500.0 + norm * 8500.0,
      RiderSpecialization.puncher ||
      RiderSpecialization.classicCobbles =>
        14500.0 + norm * 7500.0,
      _ => 12000.0 + norm * 6500.0,
    };

    final double recoveryRate =
        (0.84 + norm * 0.34 + (rng.nextDouble() * 0.08 - 0.04)).clamp(0.75, 1.28);
    final double cda =
        (cdaBase + (rng.nextDouble() * 0.014 - 0.007)).clamp(0.185, 0.245);

    final int maxHr = (206 - (age * 0.7)).round() + rng.nextInt(7) - 3;
    final int restingHr = (52 - norm * 14).round() + rng.nextInt(5) - 2;
    final int lthr = (maxHr * (0.88 + rng.nextDouble() * 0.04)).round();

    final riderPhys = RiderPhysiology(
      heightCm: heightCm,
      weightKg: weightKg,
      bodyFatPercentage: bodyFat,
      ftpWatts: ftpWatts.round(),
      wPrimeJoules: wPrimeJoules.round(),
      vo2Max: double.parse(vo2Max.toStringAsFixed(1)),
      maxHr: maxHr.clamp(172, 206),
      restingHr: restingHr.clamp(36, 62),
      lactateThresholdHr: lthr.clamp(150, 190),
      recoveryRate: double.parse(recoveryRate.toStringAsFixed(2)),
      glycogenCapacityGrams: 460.0 + norm * 120.0,
      form: 72.0 + rng.nextDouble() * 14.0,
      fatigue: 18.0 + rng.nextDouble() * 14.0,
    );

    final womensPhys = WomensPhysiologyProfile(
      weightKg: weightKg,
      heightCm: heightCm,
      ftpWatts: double.parse(ftpWatts.toStringAsFixed(1)),
      vo2Max: double.parse(vo2Max.toStringAsFixed(1)),
      wPrimeJoules: wPrimeJoules.roundToDouble(),
      watts5s: watts5s.roundToDouble(),
      watts1m: watts1m.roundToDouble(),
      watts5m: watts5m.roundToDouble(),
      watts20m: watts20m.roundToDouble(),
      recoveryRate: double.parse(recoveryRate.toStringAsFixed(2)),
      aerodynamicsCda: double.parse(cda.toStringAsFixed(3)),
    );

    final powerProfile = RiderPowerProfile(
      watts5s: watts5s.round(),
      watts15s: watts15s.round(),
      watts30s: watts30s.round(),
      watts1m: watts1m.round(),
      watts3m: watts3m.round(),
      watts5m: watts5m.round(),
      watts20m: watts20m.round(),
      watts60m: watts60m.round(),
    );

    return (riderPhys, womensPhys, powerProfile);
  }

  static RiderSkills _generateSkills(
    RiderSpecialization spec,
    int targetOvr,
    math.Random rng,
  ) {
    int skill(int base, int bonus) =>
        (base + bonus + rng.nextInt(9) - 4).clamp(40, 99);

    final base = (targetOvr - 8).clamp(45, 90);
    return RiderSkills(
      cobbles: skill(base, spec == RiderSpecialization.classicCobbles ? 14 : 0),
      descending: skill(
        base,
        spec == RiderSpecialization.gcClimber ||
                spec == RiderSpecialization.puncher
            ? 8
            : 2,
      ),
      bikeHandling: skill(
        base,
        spec == RiderSpecialization.classicCobbles ||
                spec == RiderSpecialization.pureSprinter
            ? 10
            : 3,
      ),
      aeroPositioning: skill(
        base,
        spec == RiderSpecialization.timeTrialist ? 15 : 3,
      ),
      draftingEfficiency: skill(
        base,
        spec == RiderSpecialization.pureSprinter ||
                spec == RiderSpecialization.domestiqueEngine
            ? 10
            : 2,
      ),
      raceIq: skill(base, spec == RiderSpecialization.gcClimber ? 9 : 4),
      rainResistance: skill(base, spec == RiderSpecialization.classicCobbles ? 11 : 0),
      heatTolerance: skill(base, 2),
      timeTrialPositioning: skill(
        base,
        spec == RiderSpecialization.timeTrialist ? 16 : -2,
      ),
    );
  }

  static RiderAppearance _generateFemaleAppearance(
    RiderSpecialization spec,
    String nation,
    math.Random rng,
  ) {
    final build = switch (spec) {
      RiderSpecialization.pureClimber ||
      RiderSpecialization.gcClimber =>
        BodyBuildType.climberLean,
      RiderSpecialization.pureSprinter ||
      RiderSpecialization.versatileSprinter =>
        BodyBuildType.sprinterMuscular,
      _ => BodyBuildType.allRounder,
    };

    const skinTones = ['#F5D0B5', '#EAC0A2', '#D8A47F', '#C6865C', '#8D5524'];
    const hairColors = ['#1F1B18', '#4A3728', '#8D6E48', '#D4A857', '#A54A2A'];
    const shoeColors = ['#FFFFFF', '#D4AF37', '#38BDF8', '#EC4899', '#181B22'];

    final skinIdx = nation == 'COL' || nation == 'RSA'
        ? 2 + rng.nextInt(3)
        : rng.nextInt(3);

    return RiderAppearance(
      faceShapeIndex: rng.nextInt(5),
      skinToneHex: skinTones[skinIdx],
      hairStyleIndex: 10 + rng.nextInt(8), // style kobiece (kucyk, warkocz, bob)
      hairColorHex: hairColors[rng.nextInt(hairColors.length)],
      facialHairIndex: 0,
      glassesModelId: 'aero_pro_${1 + rng.nextInt(4)}',
      glassesLensColorHex: '#38BDF8',
      helmetModelId: 'wwt_aero_${1 + rng.nextInt(3)}',
      shoeColorHex: shoeColors[rng.nextInt(shoeColors.length)],
      sockHeightProportion: 0.72 + rng.nextDouble() * 0.16,
      bodyBuildType: build,
    );
  }

  static int _calculateWomensAnnualSalaryEur({
    required int targetOvr,
    required RiderRole role,
    required int age,
  }) {
    final double norm = ((targetOvr - 54) / (96 - 54)).clamp(0.0, 1.0);
    double base = 36000.0 + math.pow(norm, 2.2) * 380000.0;
    if (role == RiderRole.teamLeader) base *= 1.18;
    if (role == RiderRole.neoPro || age <= 21) base *= 0.72;
    return ((base / 1000.0).round() * 1000).clamp(32000, 520000);
  }

  static (String, String) _generateUniqueFemaleName({
    required String nation,
    required math.Random rng,
    required Set<String> usedNames,
  }) {
    final db = _womensNamesDatabase[nation] ?? _womensNamesDatabase['NED']!;
    final firstNames = db.$1;
    final lastNames = db.$2;

    for (int attempt = 0; attempt < 25; attempt++) {
      final first = firstNames[rng.nextInt(firstNames.length)];
      final last = lastNames[rng.nextInt(lastNames.length)];
      final full = '$first $last';
      if (usedNames.add(full)) {
        return (first, last);
      }
    }

    final first = firstNames[rng.nextInt(firstNames.length)];
    final last =
        '${lastNames[rng.nextInt(lastNames.length)]}-${lastNames[rng.nextInt(lastNames.length)]}';
    usedNames.add('$first $last');
    return (first, last);
  }

  static List<WomensRaceEvent> _buildDefaultWomensCalendar(int seasonYear) {
    return [
      WomensRaceEvent(
        raceId: 'wwt_strade_bianche_$seasonYear',
        name: 'Strade Bianche Donne',
        countryIso: 'ITA',
        tier: WomensRaceTier.wwtOneDay,
        startDate: DateTime(seasonYear, 3, 7),
        stageCount: 1,
        totalDistanceKm: 137.0,
        elevationGainM: 2150,
        prizePoolEur: 45000,
      ),
      WomensRaceEvent(
        raceId: 'wwt_ronde_van_vlaanderen_$seasonYear',
        name: 'Ronde van Vlaanderen Women',
        countryIso: 'BEL',
        tier: WomensRaceTier.wwtMonument,
        startDate: DateTime(seasonYear, 4, 5),
        stageCount: 1,
        totalDistanceKm: 163.0,
        elevationGainM: 1850,
        prizePoolEur: 65000,
      ),
      WomensRaceEvent(
        raceId: 'wwt_paris_roubaix_femmes_$seasonYear',
        name: 'Paris-Roubaix Femmes',
        countryIso: 'FRA',
        tier: WomensRaceTier.wwtMonument,
        startDate: DateTime(seasonYear, 4, 11),
        stageCount: 1,
        totalDistanceKm: 148.5,
        elevationGainM: 520,
        prizePoolEur: 60000,
      ),
      WomensRaceEvent(
        raceId: 'wwt_vuelta_femenina_$seasonYear',
        name: 'La Vuelta Femenina',
        countryIso: 'ESP',
        tier: WomensRaceTier.wwtGrandTour,
        startDate: DateTime(seasonYear, 5, 3),
        stageCount: 7,
        totalDistanceKm: 885.0,
        elevationGainM: 13400,
        prizePoolEur: 145000,
      ),
      WomensRaceEvent(
        raceId: 'wwt_giro_women_$seasonYear',
        name: 'Giro d\'Italia Women',
        countryIso: 'ITA',
        tier: WomensRaceTier.wwtGrandTour,
        startDate: DateTime(seasonYear, 7, 5),
        stageCount: 8,
        totalDistanceKm: 940.0,
        elevationGainM: 14800,
        prizePoolEur: 185000,
      ),
      WomensRaceEvent(
        raceId: 'wwt_tour_de_france_femmes_$seasonYear',
        name: 'Tour de France Femmes',
        countryIso: 'FRA',
        tier: WomensRaceTier.wwtGrandTour,
        startDate: DateTime(seasonYear, 8, 1),
        stageCount: 8,
        totalDistanceKm: 1025.0,
        elevationGainM: 17200,
        prizePoolEur: 260000,
      ),
      WomensRaceEvent(
        raceId: 'wwt_tour_of_scandinavia_$seasonYear',
        name: 'Tour of Scandinavia',
        countryIso: 'NOR',
        tier: WomensRaceTier.wwtStageRace,
        startDate: DateTime(seasonYear, 8, 25),
        stageCount: 5,
        totalDistanceKm: 645.0,
        elevationGainM: 6900,
        prizePoolEur: 80000,
      ),
    ];
  }

  static const List<String> _supportedNations = [
    'NED', 'BEL', 'ITA', 'FRA', 'POL',
    'GBR', 'GER', 'USA', 'AUS', 'ESP',
    'SUI', 'DEN', 'NOR', 'SWE', 'AUT',
    'CAN', 'NZL', 'COL', 'RSA', 'CZE',
  ];

  /// 24 kobiece drużyny (15 Women's WorldTour, 6 Women's ProTeam, 3 Women's Continental).
  static const List<_WomensTeamPreset> _teamPresets = [
    // --- 15 UCI Women's WorldTeams ---
    _WomensTeamPreset(
      teamId: 'wwt_sdworx_protime',
      name: 'Team SD Worx-Protime',
      shortCode: 'SDW',
      countryIso: 'NED',
      division: WomensDivision.womensWorldTour,
      primaryColorHex: '#6B21A8',
      secondaryColorHex: '#F97316',
      annualBudgetEur: 4800000,
      initialUciPoints: 14200,
      staffLevel: 95,
      equipmentTier: 5,
      tierStrengthBonus: 7,
    ),
    _WomensTeamPreset(
      teamId: 'wwt_canyon_sram',
      name: 'Canyon//SRAM Racing',
      shortCode: 'CSR',
      countryIso: 'GER',
      division: WomensDivision.womensWorldTour,
      primaryColorHex: '#0F172A',
      secondaryColorHex: '#EC4899',
      annualBudgetEur: 4300000,
      initialUciPoints: 12950,
      staffLevel: 92,
      equipmentTier: 5,
      tierStrengthBonus: 6,
    ),
    _WomensTeamPreset(
      teamId: 'wwt_lidl_trek_women',
      name: 'Lidl-Trek Women',
      shortCode: 'LTK',
      countryIso: 'USA',
      division: WomensDivision.womensWorldTour,
      primaryColorHex: '#1D4ED8',
      secondaryColorHex: '#EF4444',
      annualBudgetEur: 4500000,
      initialUciPoints: 13400,
      linkedMensTeamId: 'wt_lidl_trek',
      staffLevel: 93,
      equipmentTier: 5,
      tierStrengthBonus: 6,
    ),
    _WomensTeamPreset(
      teamId: 'wwt_fdj_suez',
      name: 'FDJ-Suez',
      shortCode: 'FST',
      countryIso: 'FRA',
      division: WomensDivision.womensWorldTour,
      primaryColorHex: '#1E3A8A',
      secondaryColorHex: '#38BDF8',
      annualBudgetEur: 4100000,
      initialUciPoints: 11850,
      linkedMensTeamId: 'wt_groupama_fdj',
      staffLevel: 90,
      equipmentTier: 5,
      tierStrengthBonus: 5,
    ),
    _WomensTeamPreset(
      teamId: 'wwt_visma_lease_women',
      name: 'Team Visma | Lease a Bike Women',
      shortCode: 'TVL',
      countryIso: 'NED',
      division: WomensDivision.womensWorldTour,
      primaryColorHex: '#FACC15',
      secondaryColorHex: '#111827',
      annualBudgetEur: 4200000,
      initialUciPoints: 12100,
      linkedMensTeamId: 'wt_visma_lease',
      staffLevel: 92,
      equipmentTier: 5,
      tierStrengthBonus: 5,
    ),
    _WomensTeamPreset(
      teamId: 'wwt_movistar_women',
      name: 'Movistar Team Women',
      shortCode: 'MOV',
      countryIso: 'ESP',
      division: WomensDivision.womensWorldTour,
      primaryColorHex: '#0284C7',
      secondaryColorHex: '#E0F2FE',
      annualBudgetEur: 3650000,
      initialUciPoints: 9800,
      linkedMensTeamId: 'wt_movistar',
      staffLevel: 88,
      equipmentTier: 5,
      tierStrengthBonus: 4,
    ),
    _WomensTeamPreset(
      teamId: 'wwt_uae_adq',
      name: 'UAE Team ADQ',
      shortCode: 'UAD',
      countryIso: 'ITA',
      division: WomensDivision.womensWorldTour,
      primaryColorHex: '#111827',
      secondaryColorHex: '#10B981',
      annualBudgetEur: 3900000,
      initialUciPoints: 10600,
      linkedMensTeamId: 'wt_uae_emirates',
      staffLevel: 90,
      equipmentTier: 5,
      tierStrengthBonus: 5,
    ),
    _WomensTeamPreset(
      teamId: 'wwt_dsm_firmenich_women',
      name: 'Team dsm-firmenich PostNL Women',
      shortCode: 'DFP',
      countryIso: 'NED',
      division: WomensDivision.womensWorldTour,
      primaryColorHex: '#0F172A',
      secondaryColorHex: '#38BDF8',
      annualBudgetEur: 3400000,
      initialUciPoints: 9200,
      linkedMensTeamId: 'wt_dsm_firmenich',
      staffLevel: 87,
      equipmentTier: 5,
      tierStrengthBonus: 4,
    ),
    _WomensTeamPreset(
      teamId: 'wwt_liv_alula_jayco',
      name: 'Liv AlUla Jayco',
      shortCode: 'LAJ',
      countryIso: 'AUS',
      division: WomensDivision.womensWorldTour,
      primaryColorHex: '#7C3AED',
      secondaryColorHex: '#06B6D4',
      annualBudgetEur: 3350000,
      initialUciPoints: 8950,
      linkedMensTeamId: 'wt_jayco_alula',
      staffLevel: 86,
      equipmentTier: 4,
      tierStrengthBonus: 3,
    ),
    _WomensTeamPreset(
      teamId: 'wwt_fenix_deceuninck',
      name: 'Fenix-Deceuninck',
      shortCode: 'FED',
      countryIso: 'BEL',
      division: WomensDivision.womensWorldTour,
      primaryColorHex: '#1E293B',
      secondaryColorHex: '#EF4444',
      annualBudgetEur: 3250000,
      initialUciPoints: 8700,
      linkedMensTeamId: 'wt_alpecin_deceuninck',
      staffLevel: 85,
      equipmentTier: 4,
      tierStrengthBonus: 3,
    ),
    _WomensTeamPreset(
      teamId: 'wwt_ag_insurance_soudal',
      name: 'AG Insurance-Soudal Team',
      shortCode: 'AGS',
      countryIso: 'BEL',
      division: WomensDivision.womensWorldTour,
      primaryColorHex: '#1D4ED8',
      secondaryColorHex: '#F59E0B',
      annualBudgetEur: 3100000,
      initialUciPoints: 8400,
      linkedMensTeamId: 'wt_soudal_quickstep',
      staffLevel: 85,
      equipmentTier: 4,
      tierStrengthBonus: 3,
    ),
    _WomensTeamPreset(
      teamId: 'wwt_uno_x_mobility_women',
      name: 'Uno-X Mobility Women',
      shortCode: 'UXM',
      countryIso: 'NOR',
      division: WomensDivision.womensWorldTour,
      primaryColorHex: '#DC2626',
      secondaryColorHex: '#FACC15',
      annualBudgetEur: 2950000,
      initialUciPoints: 7900,
      staffLevel: 84,
      equipmentTier: 4,
      tierStrengthBonus: 2,
    ),
    _WomensTeamPreset(
      teamId: 'wwt_ceratizit_wnt',
      name: 'Ceratizit-WNT Pro Cycling',
      shortCode: 'WNT',
      countryIso: 'GER',
      division: WomensDivision.womensWorldTour,
      primaryColorHex: '#334155',
      secondaryColorHex: '#D4AF37',
      annualBudgetEur: 2700000,
      initialUciPoints: 7350,
      staffLevel: 82,
      equipmentTier: 4,
      tierStrengthBonus: 2,
    ),
    _WomensTeamPreset(
      teamId: 'wwt_human_powered_health',
      name: 'Human Powered Health',
      shortCode: 'HPH',
      countryIso: 'USA',
      division: WomensDivision.womensWorldTour,
      primaryColorHex: '#EA580C',
      secondaryColorHex: '#1E293B',
      annualBudgetEur: 2650000,
      initialUciPoints: 6900,
      staffLevel: 81,
      equipmentTier: 4,
      tierStrengthBonus: 1,
    ),
    _WomensTeamPreset(
      teamId: 'wwt_roland_cycling',
      name: 'Roland Cycling Team',
      shortCode: 'CGS',
      countryIso: 'SUI',
      division: WomensDivision.womensWorldTour,
      primaryColorHex: '#B91C1C',
      secondaryColorHex: '#F3F4F6',
      annualBudgetEur: 2450000,
      initialUciPoints: 6400,
      staffLevel: 79,
      equipmentTier: 4,
      tierStrengthBonus: 1,
    ),

    // --- 6 UCI Women's ProTeams ---
    _WomensTeamPreset(
      teamId: 'wpt_ef_oatly_cannondale',
      name: 'EF-Oatly-Cannondale',
      shortCode: 'EOC',
      countryIso: 'USA',
      division: WomensDivision.womensProTeam,
      primaryColorHex: '#EC4899',
      secondaryColorHex: '#FACC15',
      annualBudgetEur: 2300000,
      initialUciPoints: 5900,
      linkedMensTeamId: 'wt_ef_easypost',
      staffLevel: 82,
      equipmentTier: 4,
      tierStrengthBonus: 4,
    ),
    _WomensTeamPreset(
      teamId: 'wpt_volkerwessels_women',
      name: 'VolkerWessels Women',
      shortCode: 'VWT',
      countryIso: 'NED',
      division: WomensDivision.womensProTeam,
      primaryColorHex: '#0369A1',
      secondaryColorHex: '#F8FAFC',
      annualBudgetEur: 1850000,
      initialUciPoints: 5100,
      staffLevel: 77,
      equipmentTier: 3,
      tierStrengthBonus: 2,
    ),
    _WomensTeamPreset(
      teamId: 'wpt_cofidis_women',
      name: 'Cofidis Women Team',
      shortCode: 'COF',
      countryIso: 'FRA',
      division: WomensDivision.womensProTeam,
      primaryColorHex: '#DC2626',
      secondaryColorHex: '#F8FAFC',
      annualBudgetEur: 1900000,
      initialUciPoints: 4950,
      linkedMensTeamId: 'wt_cofidis',
      staffLevel: 78,
      equipmentTier: 4,
      tierStrengthBonus: 2,
    ),
    _WomensTeamPreset(
      teamId: 'wpt_arkea_bb_hotels_women',
      name: 'Arkéa-B&B Hotels Women',
      shortCode: 'ARK',
      countryIso: 'FRA',
      division: WomensDivision.womensProTeam,
      primaryColorHex: '#991B1B',
      secondaryColorHex: '#18181B',
      annualBudgetEur: 1750000,
      initialUciPoints: 4600,
      linkedMensTeamId: 'wt_arkea_bb',
      staffLevel: 76,
      equipmentTier: 3,
      tierStrengthBonus: 2,
    ),
    _WomensTeamPreset(
      teamId: 'wpt_laboral_kutxa',
      name: 'Laboral Kutxa-Fundación Euskadi',
      shortCode: 'LKF',
      countryIso: 'ESP',
      division: WomensDivision.womensProTeam,
      primaryColorHex: '#7C2D12',
      secondaryColorHex: '#EC4899',
      annualBudgetEur: 1650000,
      initialUciPoints: 4350,
      staffLevel: 75,
      equipmentTier: 3,
      tierStrengthBonus: 1,
    ),
    _WomensTeamPreset(
      teamId: 'wpt_mat_atom_poland',
      name: 'MAT Atom Deweloper Wrocław',
      shortCode: 'MAW',
      countryIso: 'POL',
      division: WomensDivision.womensProTeam,
      primaryColorHex: '#BE123C',
      secondaryColorHex: '#F3F4F6',
      annualBudgetEur: 1450000,
      initialUciPoints: 3900,
      staffLevel: 74,
      equipmentTier: 3,
      tierStrengthBonus: 1,
    ),

    // --- 3 UCI Women's Continental Teams ---
    _WomensTeamPreset(
      teamId: 'wct_lotto_dstny_ladies',
      name: 'Lotto Dstny Ladies',
      shortCode: 'LDL',
      countryIso: 'BEL',
      division: WomensDivision.womensContinental,
      primaryColorHex: '#B91C1C',
      secondaryColorHex: '#0EA5E9',
      annualBudgetEur: 1050000,
      initialUciPoints: 2800,
      staffLevel: 71,
      equipmentTier: 3,
      tierStrengthBonus: 2,
    ),
    _WomensTeamPreset(
      teamId: 'wct_bepink_bongioanni',
      name: 'BePink-Bongioanni',
      shortCode: 'BPK',
      countryIso: 'ITA',
      division: WomensDivision.womensContinental,
      primaryColorHex: '#DB2777',
      secondaryColorHex: '#1E293B',
      annualBudgetEur: 950000,
      initialUciPoints: 2450,
      staffLevel: 70,
      equipmentTier: 3,
      tierStrengthBonus: 1,
    ),
    _WomensTeamPreset(
      teamId: 'wct_tasmanian_dev_women',
      name: 'Tasmanian Tigers Women Cycling',
      shortCode: 'TTW',
      countryIso: 'AUS',
      division: WomensDivision.womensContinental,
      primaryColorHex: '#047857',
      secondaryColorHex: '#FACC15',
      annualBudgetEur: 880000,
      initialUciPoints: 2150,
      staffLevel: 68,
      equipmentTier: 2,
      tierStrengthBonus: 0,
    ),
  ];

  static const Map<String, (List<String>, List<String>)>
      _womensNamesDatabase = {
    'NED': (
      ['Demi', 'Lorena', 'Marianne', 'Puck', 'Shirin', 'Riejanne', 'Mischa', 'Anouska', 'Yara', 'Fem'],
      ['Vollering', 'Wiebes', 'Vos', 'Pieterse', 'van Anrooij', 'Markus', 'Bredewold', 'Koster', 'Kastelijn', 'van Empel', 'Kool', 'van Dijk'],
    ),
    'BEL': (
      ['Lotte', 'Justine', 'Julie', 'Sanne', 'Marthe', 'Margaux', 'Fien', 'Febe', 'Shari', 'Lone'],
      ['Kopecky', 'Ghekiere', 'De Wilde', 'Cant', 'Truyen', 'Vanhove', 'Van Eynde', 'Jooris', 'Bossuyt', 'Meertens'],
    ),
    'ITA': (
      ['Elisa', 'Silvia', 'Chiara', 'Letizia', 'Marta', 'Gaia', 'Elena', 'Soraya', 'Vittoria', 'Erica'],
      ['Longo Borghini', 'Balsamo', 'Persico', 'Consonni', 'Paternoster', 'Cavalli', 'Realini', 'Cecchini', 'Paladin', 'Guazzini', 'Magnaldi'],
    ),
    'FRA': (
      ['Juliette', 'Evita', 'Cédrine', 'Victoire', 'Audrey', 'Marie', 'Jade', 'Clara', 'Maëva', 'Léa'],
      ['Labous', 'Muzic', 'Kerbaol', 'Berteau', 'Cordon-Ragot', 'Le Net', 'Wiel', 'Copponi', 'Squiban', 'Curinier'],
    ),
    'POL': (
      ['Katarzyna', 'Marta', 'Dominika', 'Agnieszka', 'Karolina', 'Wiktoria', 'Nikol', 'Daria', 'Maja', 'Zuzanna'],
      ['Niewiadoma', 'Lach', 'Włodarczyk', 'Skalniak-Sójka', 'Kumięga', 'Pikulik', 'Płosaj', 'Kowalska', 'Wróbel', 'Jaskulska'],
    ),
    'GBR': (
      ['Pfeiffer', 'Lizzie', 'Anna', 'Cat', 'Claire', 'Joscelin', 'Elinor', 'Flora', 'Alice', 'Imogen'],
      ['Georgi', 'Deignan', 'Henderson', 'Ferguson', 'Steels', 'Lowden', 'Barker', 'Perkins', 'Barnes', 'Wolff'],
    ),
    'GER': (
      ['Liane', 'Ricarda', 'Antonia', 'Franziska', 'Kathrin', 'Clara', 'Linda', 'Hannah', 'Romy', 'Justyna'],
      ['Lippert', 'Bauernfeind', 'Niedermaier', 'Koch', 'Hammes', 'Koppenburg', 'Riedmann', 'Ludwig', 'Kasper', 'Czapla'],
    ),
    'USA': (
      ['Chloe', 'Kristen', 'Lauren', 'Ruth', 'Skylar', 'Megan', 'Veronica', 'Katie', 'Emma', 'Lily'],
      ['Dygert', 'Faulkner', 'Stephens', 'Edwards', 'Schneider', 'Jastrab', 'Ewers', 'Clouse', 'Langley', 'Williams'],
    ),
    'AUS': (
      ['Grace', 'Amanda', 'Sarah', 'Ruby', 'Neve', 'Brodie', 'Alexandra', 'Georgia', 'Chloe', 'Maeve'],
      ['Brown', 'Spratt', 'Gigante', 'Roseman-Gannon', 'Bradbury', 'Chapman', 'Manly', 'Baker', 'Hosking', 'Plouffe'],
    ),
    'ESP': (
      ['Mavi', 'Ane', 'Usoa', 'Sandra', 'Sara', 'Sheyla', 'Mireia', 'Alicia', 'Paula', 'Lucía'],
      ['García', 'Santesteban', 'Ostolaza', 'Alonso', 'Martín', 'Gutiérrez', 'Benito', 'González', 'Blasi', 'Ruiz'],
    ),
    'SUI': (
      ['Marlen', 'Elise', 'Noemi', 'Elena', 'Linda', 'Michelle', 'Jasmin', 'Nicole', 'Lea', 'Sina'],
      ['Reusser', 'Chabbey', 'Rüegg', 'Hartmann', 'Zanetti', 'Stark', 'Liechti', 'Koller', 'Fuchs', 'Frei'],
    ),
    'DEN': (
      ['Cecilie', 'Emma', 'Amalie', 'Rebecca', 'Julie', 'Christina', 'Alberte', 'Solbjørk', 'Mie', 'Ellen'],
      ['Uttrup Ludwig', 'Norsgaard', 'Dideriksen', 'Koerner', 'Leth', 'Siggard', 'Greve', 'Anderson', 'Madsen', 'Klinge'],
    ),
    'NOR': (
      ['Ingvild', 'Katrine', 'Susanne', 'Mie', 'Marte', 'Anne', 'Stine', 'Amalie', 'Nora', 'Tuva'],
      ['Gåskjenn', 'Aalerud', 'Andersen', 'Bjørndal Ottestad', 'Berg Edseth', 'Dorthe Ysland', 'Borge', 'Lutro', 'Tveit', 'Byberg'],
    ),
    'SWE': (
      ['Emilia', 'Caroline', 'Julia', 'Hanna', 'Nathalie', 'Wilma', 'Clara', 'Jenny', 'Tilda', 'Maja'],
      ['Fahlin', 'Andersson', 'Borgström', 'Nilsson', 'Eklund', 'Olausson', 'Lundmark', 'Rissveds', 'Hylén', 'Johansson'],
    ),
    'AUT': (
      ['Christina', 'Anna', 'Kathrin', 'Carina', 'Sarah', 'Gabriela', 'Valentina', 'Leila', 'Elena', 'Tabea'],
      ['Schweinberger', 'Kiesenhofer', 'Schweinberger', 'Schrempf', 'Rijkes', 'Erath', 'Cavallar', 'Gschwentner', 'Piringer', 'Huys'],
    ),
    'CAN': (
      ['Alison', 'Magdeleine', 'Olivia', 'Simone', 'Clara', 'Ngaire', 'Ava', 'Isabella', 'Laury', 'Kiara'],
      ['Jackson', 'Vallieres', 'Baril', 'Boilard', 'Emond', 'Barraclough', 'Holmgren', 'Holmgren', 'Milette', 'Lylyk'],
    ),
    'NZL': (
      ['Niamh', 'Ally', 'Kim', 'Mikayla', 'Georgia', 'Ella', 'Bryony', 'Henrietta', 'Sharlotte', 'Samara'],
      ['Fisher-Black', 'Wollaston', 'Cadzow', 'Harvey', 'Williams', 'Wyllie', 'Botha', 'Christie', 'Lucas', 'Maxwell'],
    ),
    'COL': (
      ['Paula', 'Diana', 'Carolina', 'Jessenia', 'Camila', 'Lina', 'Natalia', 'Estefanía', 'Juliana', 'Laura'],
      ['Patiño', 'Peñuela', 'Vargas', 'Meneses', 'Valbuena', 'Hernández', 'Franco', 'Herrera', 'Londoño', 'Rojas'],
    ),
    'RSA': (
      ['Ashleigh', 'Hayley', 'Tiffany', 'Kerry', 'Frances', 'Zanri', 'Maude', 'Candice', 'Maroesjka', 'Carla'],
      ['Moolman-Pasio', 'Preen', 'Keep', 'Jonker', 'Janse van Rensburg', 'Rossouw', 'Le Roux', 'Lill', 'Matthee', 'Oberholzer'],
    ),
    'CZE': (
      ['Tereza', 'Nikola', 'Julia', 'Barbora', 'Eliška', 'Kristýna', 'Markéta', 'Kateřina', 'Veronika', 'Adéla'],
      ['Neumanová', 'Nosková', 'Kopecky', 'Němcová', 'Kvasničková', 'Burlová', 'Hájková', 'Nash', 'Jandová', 'Pittnerová'],
    ),
  };
}
