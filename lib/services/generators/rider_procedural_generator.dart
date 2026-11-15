import 'dart:math' as math;
import '../../models/rider/lactate_and_lab_profile.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_appearance.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/rider/rider_health.dart';
import '../../models/rider/rider_physiology.dart';
import '../../models/rider/rider_power_profile.dart';
import '../../models/rider/rider_skills.dart';
import '../../models/team/cycling_team.dart';

/// Poziom potencjału skautingowego młodego zawodnika.
enum ScoutingTier {
  /// Diament generacji (np. Tadej Pogačar, Remco Evenepoel) – potencjał 94-99
  generationalTalent,

  /// Przyszły lider World Tour – potencjał 86-93
  worldTourProspect,

  /// Solidny kolarz zawodowy (ProTeam / solidny pomocnik WT) – potencjał 78-85
  solidPro,

  /// Rzemieślnik peletonu / poziom kontynentalny – potencjał 68-77
  continentalHopeful;

  String get label {
    switch (this) {
      case ScoutingTier.generationalTalent:
        return 'Talent pokoleniowy (5★)';
      case ScoutingTier.worldTourProspect:
        return 'Perspektywa WorldTour (4★)';
      case ScoutingTier.solidPro:
        return 'Solidny zawodowiec (3★)';
      case ScoutingTier.continentalHopeful:
        return 'Kandydat kontynentalny (2★)';
    }
  }
}

/// Alias dla poziomów naboru talentów U19/U23
enum TalentScoutingTier {
  localJunior,
  nationalU19,
  internationalEspoirs,
  generationalDiamond;
}

/// Zaawansowany generator proceduralny kolarzy na start gry oraz corocznego naboru talentów U19/U23.
///
/// Gwarantuje:
/// 1. Realistyczną bazę imion i nazwisk z 25 czołowych państw kolarskich świata.
/// 2. Ścisłą korelację fizjologiczną – lekki góral (56-60 kg) osiąga wybitne W/kg (nawet 6.4-6.6 W/kg na 20 min),
///    ale jego bezwzględna moc sprinterska jest fizjologicznie ograniczona (950-1150 W). Z kolei masywny sprinter
///    czy klasykowiec (76-82 kg) generuje 1550-1850 W w sprincie i dysponuje potężnym zapasem beztlenowym W',
///    jednak cierpi na długich alpejskich wspinaczkach.
/// 3. Poprawne skalowanie parametrów dla młodych adeptów (U19/U23) z zachowaniem sufitu potencjału.
class RiderProceduralGenerator {
  RiderProceduralGenerator._();

  static final math.Random _defaultRandom = math.Random();

  /// 25 krajów kolarskich uwzględnionych w bazie generatora
  static const List<String> supportedNationalities = [
    'POL', 'FRA', 'BEL', 'ITA', 'ESP',
    'SLO', 'NED', 'COL', 'DEN', 'GBR',
    'GER', 'AUS', 'USA', 'NOR', 'SUI',
    'POR', 'AUT', 'ERI', 'KAZ', 'CZE',
    'ECU', 'IRL', 'NZL', 'RSA', 'SVK',
  ];

  /// Generuje pojedynczego, w pełni ukształtowanego kolarza zawodowego.
  static Rider generateRider({
    String? id,
    String? nationalityIso,
    RiderSpecialization? specialization,
    int? age,
    int? targetOverallRating, // Opcjonalny cel OVR (np. 85)
    String teamId = 'free_agent',
    RiderRole role = RiderRole.domestique,
    math.Random? random,
  }) {
    final rng = random ?? _defaultRandom;
    final nation = nationalityIso != null && _namesDatabase.containsKey(nationalityIso)
        ? nationalityIso
        : _pickRandomNationality(rng);

    final spec = specialization ?? _pickRandomSpecialization(rng, nation);
    final riderAge = age ?? (22 + rng.nextInt(13)); // 22 - 34 lata

    final names = _generateRiderName(nation, rng);
    final String firstName = names.$1;
    final String lastName = names.$2;

    // Poziom potencjału i docelowego ratingu
    final int ovrTarget = targetOverallRating ?? (68 + rng.nextInt(26)); // 68 - 93
    final int potential = (ovrTarget + rng.nextInt(6)).clamp(ovrTarget, 99);

    // Fizjologia i profil mocy skorelowany ze specjalizacją
    final physiology = _generatePhysiology(spec, ovrTarget, riderAge, rng);
    final powerProfile = _generatePowerProfile(spec, physiology, ovrTarget, rng);
    final skills = _generateSkills(spec, ovrTarget, rng);
    final appearance = _generateAppearance(spec, nation, rng);

    // Kontrakt
    final int salary = _calculateRealisticSalaryEur(ovrTarget, role, riderAge);
    final contract = RiderContract(
      teamId: teamId,
      role: role,
      monthlySalaryEur: salary,
      signingBonusEur: (salary * 2.5).round(),
      winBonusEur: (salary * 1.2).round(),
      releaseClauseEur: salary * 24,
      contractEndYear: DateTime.now().year + 1 + rng.nextInt(3),
      morale: 75.0 + rng.nextDouble() * 15.0,
      leaderLoyalty: 60.0 + rng.nextDouble() * 35.0,
      requiredRacesIds: const [],
    );

    // Zdrowie początkowe
    final health = RiderHealth(
      acuteTrainingLoad: 75.0 + rng.nextDouble() * 20.0,
      chronicTrainingLoad: 85.0 + rng.nextDouble() * 25.0,
      currentInjury: null,
      currentIllness: null,
    );

    final birthYear = DateTime.now().year - riderAge;
    final birthDate = DateTime(birthYear, 1 + rng.nextInt(12), 1 + rng.nextInt(28));

    final labProfile = LactateAndLabProfile.fromPhysiology(
      physiology,
      specialization: spec,
      powerProfile: powerProfile,
    );
    final finalPhysiology = physiology.copyWith(labProfile: labProfile);

    return Rider(
      id: id ?? 'rider_${nation.toLowerCase()}_${DateTime.now().microsecondsSinceEpoch}_${rng.nextInt(9999)}',
      firstName: firstName,
      lastName: lastName,
      nationalityIso: nation,
      birthDate: birthDate,
      potential: potential,
      specialization: spec,
      physiology: finalPhysiology,
      powerProfile: powerProfile,
      skills: skills,
      appearance: appearance,
      contract: contract,
      health: health,
      careerPointsUci: _estimateCareerPoints(ovrTarget, riderAge),
    );
  }

  /// Generuje młodego adepta kolarstwa (U19: 17-18 lat lub U23: 19-21 lat) w ramach draftu/skautingu.
  static Rider generateNeoProTalent({
    required int currentSeasonYear,
    ScoutingTier tier = ScoutingTier.worldTourProspect,
    String? preferredNationality,
    RiderSpecialization? preferredSpecialization,
    math.Random? random,
  }) {
    final rng = random ?? _defaultRandom;
    final nation = preferredNationality ?? _pickRandomNationality(rng);
    final spec = preferredSpecialization ?? _pickRandomSpecialization(rng, nation);

    // Wiek adepta: 17 - 21 lat
    final int age = 17 + rng.nextInt(5);
    final int birthYear = currentSeasonYear - age;
    final birthDate = DateTime(birthYear, 1 + rng.nextInt(12), 1 + rng.nextInt(28));

    final names = _generateRiderName(nation, rng);

    // Parametry potencjału według tiery
    int potential;
    int currentOvr;
    switch (tier) {
      case ScoutingTier.generationalTalent:
        potential = 94 + rng.nextInt(6); // 94 - 99
        currentOvr = (76 + rng.nextInt(7)).clamp(74, 84); // Już w młodym wieku potwór (jak Evenepoel/Pogačar)
        break;
      case ScoutingTier.worldTourProspect:
        potential = 86 + rng.nextInt(8); // 86 - 93
        currentOvr = (70 + rng.nextInt(7)).clamp(68, 77);
        break;
      case ScoutingTier.solidPro:
        potential = 78 + rng.nextInt(8); // 78 - 85
        currentOvr = (64 + rng.nextInt(7)).clamp(62, 72);
        break;
      case ScoutingTier.continentalHopeful:
        potential = 68 + rng.nextInt(10); // 68 - 77
        currentOvr = (58 + rng.nextInt(7)).clamp(56, 66);
        break;
    }

    final physiology = _generatePhysiology(spec, currentOvr, age, rng);
    final powerProfile = _generatePowerProfile(spec, physiology, currentOvr, rng);
    final skills = _generateSkills(spec, currentOvr, rng);
    final appearance = _generateAppearance(spec, nation, rng);

    final contract = RiderContract(
      teamId: 'free_agent',
      role: RiderRole.neoPro,
      monthlySalaryEur: 2200 + (currentOvr - 60) * 180,
      signingBonusEur: 5000,
      winBonusEur: 3000,
      releaseClauseEur: 350000 + (potential * 8000),
      contractEndYear: currentSeasonYear + 2,
      morale: 85.0 + rng.nextDouble() * 10.0,
      leaderLoyalty: 75.0 + rng.nextDouble() * 20.0,
      requiredRacesIds: const [],
    );

    final health = RiderHealth(
      acuteTrainingLoad: 45.0 + rng.nextDouble() * 20.0,
      chronicTrainingLoad: 55.0 + rng.nextDouble() * 20.0,
      currentInjury: null,
      currentIllness: null,
    );

    final labProfile = LactateAndLabProfile.fromPhysiology(
      physiology,
      specialization: spec,
      powerProfile: powerProfile,
    );
    final finalPhysiology = physiology.copyWith(labProfile: labProfile);

    return Rider(
      id: 'scout_${nation.toLowerCase()}_${currentSeasonYear}_${rng.nextInt(99999)}',
      firstName: names.$1,
      lastName: names.$2,
      nationalityIso: nation,
      birthDate: birthDate,
      potential: potential,
      specialization: spec,
      physiology: finalPhysiology,
      powerProfile: powerProfile,
      skills: skills,
      appearance: appearance,
      contract: contract,
      health: health,
      careerPointsUci: (currentOvr - 60) * 12,
    );
  }

  /// Generuje roczną pulę skautingową młodych talentów (Draft Pool) na nowy sezon.
  static List<Rider> generateScoutingPool({
    required int seasonYear,
    int count = 40,
    math.Random? random,
  }) {
    final rng = random ?? _defaultRandom;
    final List<Rider> pool = [];

    for (int i = 0; i < count; i++) {
      // Rozkład prawdopodobieństwa tierów
      ScoutingTier tier;
      final roll = rng.nextDouble();
      if (roll < 0.04) {
        tier = ScoutingTier.generationalTalent; // 4% szans na diament
      } else if (roll < 0.22) {
        tier = ScoutingTier.worldTourProspect; // 18% szans na prospekta WT
      } else if (roll < 0.65) {
        tier = ScoutingTier.solidPro; // 43% szans na solidnego kolarza
      } else {
        tier = ScoutingTier.continentalHopeful; // 35% szans
      }

      pool.add(
        generateNeoProTalent(
          currentSeasonYear: seasonYear,
          tier: tier,
          random: rng,
        ),
      );
    }

    return List<Rider>.unmodifiable(pool);
  }

  /// Generuje pulę talentów z określonym seedem (używane przy starcie nowej kariery)
  static List<Rider> generateTalentPool({
    TalentScoutingTier tier = TalentScoutingTier.nationalU19,
    int count = 24,
    int startingIdIndex = 9000,
    int seed = 42,
  }) {
    return generateScoutingPool(
      seasonYear: 2026,
      count: count,
      random: math.Random(seed),
    );
  }

  /// Generuje zbalansowany, realistyczny skład dla drużyny (Roster 24-28 kolarzy).
  static List<Rider> generateRosterForTeam({
    required String teamId,
    required TeamDivision division,
    int rosterSize = 26,
    math.Random? random,
  }) {
    final rng = random ?? _defaultRandom;
    final List<Rider> roster = [];

    // Poziom docelowy w zależności od ligi
    int baseOvr;
    switch (division) {
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

    // Struktura składu profesjonalnego teamu kolarskiego:
    // 2-3 Liderów GC / Wspinaczy
    // 2 Sprinterów (Czysty + Wszechstronny)
    // 3-4 Puncheurów i klasyków
    // 1-2 Czasowców
    // 2 Harcowników
    // Reszta: wszechstronni pomocnicy (Domestiques) oraz 2-3 Neo-pro
    final requiredRoles = <(RiderSpecialization, RiderRole, int)>[
      (RiderSpecialization.gcClimber, RiderRole.teamLeader, baseOvr + 7),
      (RiderSpecialization.pureClimber, RiderRole.coLeader, baseOvr + 5),
      (RiderSpecialization.pureSprinter, RiderRole.sprinter, baseOvr + 6),
      (RiderSpecialization.versatileSprinter, RiderRole.sprinter, baseOvr + 3),
      (RiderSpecialization.classicCobbles, RiderRole.teamLeader, baseOvr + 4),
      (RiderSpecialization.puncher, RiderRole.coLeader, baseOvr + 4),
      (RiderSpecialization.timeTrialist, RiderRole.domestique, baseOvr + 3),
      (RiderSpecialization.breakawaySpecialist, RiderRole.breakawaySpecialist, baseOvr + 2),
      (RiderSpecialization.domestiqueEngine, RiderRole.superDomestique, baseOvr + 3),
      (RiderSpecialization.domestiqueEngine, RiderRole.superDomestique, baseOvr + 2),
    ];

    for (final roleSpec in requiredRoles) {
      roster.add(
        generateRider(
          specialization: roleSpec.$1,
          role: roleSpec.$2,
          targetOverallRating: roleSpec.$3,
          teamId: teamId,
          random: rng,
        ),
      );
    }

    // Dodanie pozostałych pomocników i młodych talentów
    while (roster.length < rosterSize) {
      final isNeoPro = roster.length >= (rosterSize - 3);
      final spec = _pickRandomSpecialization(rng, 'POL');
      final targetOvr = isNeoPro ? (baseOvr - 6 + rng.nextInt(5)) : (baseOvr - 2 + rng.nextInt(5));

      roster.add(
        generateRider(
          specialization: spec,
          role: isNeoPro ? RiderRole.neoPro : RiderRole.domestique,
          targetOverallRating: targetOvr,
          age: isNeoPro ? (19 + rng.nextInt(3)) : (23 + rng.nextInt(10)),
          teamId: teamId,
          random: rng,
        ),
      );
    }

    return List<Rider>.unmodifiable(roster);
  }

  // ---------------------------------------------------------------------------
  // GENERATORY PODSYSTEMÓW FIZJOLOGII I MOCY (ŚCISŁA KORELACJA Z MASĄ I ROLĄ)
  // ---------------------------------------------------------------------------

  static RiderPhysiology _generatePhysiology(
    RiderSpecialization spec,
    int ovrTarget,
    int age,
    math.Random rng,
  ) {
    double heightCm;
    double weightKg;
    double bodyFat;
    double vo2Max;
    int wPrime;
    double recoveryRate;

    // Przelicznik poziomu (0.0 dla OVR 60 do 1.0 dla OVR 95)
    final double qualityFactor = ((ovrTarget - 60) / 35.0).clamp(0.0, 1.0);

    switch (spec) {
      case RiderSpecialization.pureClimber:
        // Czysty góral: ultralekki, niski/średni wzrost, minimalny tłuszcz, wysoki VO2max
        heightCm = 168.0 + rng.nextDouble() * 9.0; // 168 - 177 cm
        weightKg = 54.0 + rng.nextDouble() * 6.5; // 54 - 60.5 kg
        bodyFat = 4.8 + rng.nextDouble() * 1.6; // 4.8 - 6.4%
        vo2Max = 75.0 + (qualityFactor * 13.0) + (rng.nextDouble() * 2.5); // 75 - 90 ml/kg/min
        wPrime = (13000 + (qualityFactor * 4000) + rng.nextInt(2000)).round(); // 13-19 kJ (niski bufor beztlenowy)
        recoveryRate = 1.05 + (qualityFactor * 0.20) + (rng.nextDouble() * 0.08);
        break;

      case RiderSpecialization.gcClimber:
        // Lider GC: zbalansowany, lekki ale z mocą na czasówkę
        heightCm = 173.0 + rng.nextDouble() * 10.0; // 173 - 183 cm
        weightKg = 61.0 + rng.nextDouble() * 6.0; // 61 - 67 kg
        bodyFat = 5.2 + rng.nextDouble() * 1.5;
        vo2Max = 76.0 + (qualityFactor * 14.0) + (rng.nextDouble() * 2.0); // do 92 ml/kg/min
        wPrime = (17000 + (qualityFactor * 6000) + rng.nextInt(2500)).round(); // 17-25 kJ
        recoveryRate = 1.10 + (qualityFactor * 0.22) + (rng.nextDouble() * 0.08);
        break;

      case RiderSpecialization.pureSprinter:
        // Sprinter: potężna masa mięśniowa nóg, wysoki wzrost, potężny bufor W'
        heightCm = 178.0 + rng.nextDouble() * 11.0; // 178 - 189 cm
        weightKg = 74.0 + rng.nextDouble() * 8.5; // 74 - 82.5 kg
        bodyFat = 6.8 + rng.nextDouble() * 2.0;
        vo2Max = 65.0 + (qualityFactor * 9.0) + (rng.nextDouble() * 2.0); // 65 - 76 ml/kg/min
        wPrime = (26000 + (qualityFactor * 9000) + rng.nextInt(3500)).round(); // 26-38 kJ (olbrzymi bufor)
        recoveryRate = 0.90 + (qualityFactor * 0.18);
        break;

      case RiderSpecialization.versatileSprinter:
        heightCm = 175.0 + rng.nextDouble() * 9.0;
        weightKg = 69.0 + rng.nextDouble() * 7.0; // 69 - 76 kg
        bodyFat = 6.0 + rng.nextDouble() * 1.8;
        vo2Max = 69.0 + (qualityFactor * 10.0) + (rng.nextDouble() * 2.0);
        wPrime = (23000 + (qualityFactor * 7000) + rng.nextInt(3000)).round();
        recoveryRate = 0.98 + (qualityFactor * 0.18);
        break;

      case RiderSpecialization.puncher:
        // Puncheur: eksplozywny na 1-3 minuty, średnia waga
        heightCm = 173.0 + rng.nextDouble() * 9.0;
        weightKg = 64.0 + rng.nextDouble() * 6.5; // 64 - 70.5 kg
        bodyFat = 5.5 + rng.nextDouble() * 1.6;
        vo2Max = 72.0 + (qualityFactor * 12.0) + (rng.nextDouble() * 2.0);
        wPrime = (22000 + (qualityFactor * 6500) + rng.nextInt(2500)).round();
        recoveryRate = 1.02 + (qualityFactor * 0.18);
        break;

      case RiderSpecialization.classicCobbles:
        // Klasykowiec na bruki: wysoki, ciężki, potężny diesel
        heightCm = 180.0 + rng.nextDouble() * 12.0; // 180 - 192 cm
        weightKg = 75.0 + rng.nextDouble() * 8.0; // 75 - 83 kg
        bodyFat = 6.5 + rng.nextDouble() * 2.0;
        vo2Max = 70.0 + (qualityFactor * 10.0) + (rng.nextDouble() * 2.0);
        wPrime = (23000 + (qualityFactor * 7000) + rng.nextInt(3000)).round();
        recoveryRate = 0.98 + (qualityFactor * 0.18);
        break;

      case RiderSpecialization.timeTrialist:
        // Czasowiec: wysoki, aerodynamiczny, ogromna moc bezwzględna
        heightCm = 181.0 + rng.nextDouble() * 13.0; // 181 - 194 cm
        weightKg = 72.0 + rng.nextDouble() * 8.0; // 72 - 80 kg
        bodyFat = 5.8 + rng.nextDouble() * 1.6;
        vo2Max = 73.0 + (qualityFactor * 12.0) + (rng.nextDouble() * 2.0);
        wPrime = (20000 + (qualityFactor * 6000) + rng.nextInt(2500)).round();
        recoveryRate = 1.00 + (qualityFactor * 0.20);
        break;

      case RiderSpecialization.domestiqueEngine:
      case RiderSpecialization.breakawaySpecialist:
        heightCm = 174.0 + rng.nextDouble() * 11.0;
        weightKg = 67.0 + rng.nextDouble() * 8.0; // 67 - 75 kg
        bodyFat = 5.8 + rng.nextDouble() * 1.8;
        vo2Max = 71.0 + (qualityFactor * 11.0) + (rng.nextDouble() * 2.0);
        wPrime = (20000 + (qualityFactor * 6000) + rng.nextInt(3000)).round();
        recoveryRate = 1.02 + (qualityFactor * 0.20);
        break;
    }

    // Wyliczenie FTP w watach w ścisłym powiązaniu z W/kg
    // Elita wspinaczki: 6.0 - 6.6 W/kg; Elita płaskiego: 5.4 - 5.8 W/kg
    double targetWPerKg;
    if (spec == RiderSpecialization.pureClimber || spec == RiderSpecialization.gcClimber) {
      targetWPerKg = 4.6 + (qualityFactor * 1.85) + (rng.nextDouble() * 0.15); // 4.6 do 6.6 W/kg
    } else if (spec == RiderSpecialization.puncher || spec == RiderSpecialization.timeTrialist) {
      targetWPerKg = 4.4 + (qualityFactor * 1.65) + (rng.nextDouble() * 0.15);
    } else {
      targetWPerKg = 4.0 + (qualityFactor * 1.45) + (rng.nextDouble() * 0.15); // Sprinterzy 4.0 do 5.5 W/kg
    }

    final int ftpWatts = (weightKg * targetWPerKg).round();

    // Parametry tętna
    final int maxHr = (208 - (0.7 * age).round() + rng.nextInt(9) - 4).clamp(175, 210);
    final int restingHr = (38 + rng.nextInt(12) - (qualityFactor * 6).round()).clamp(32, 54);
    final int lthr = (maxHr * (0.86 + qualityFactor * 0.06)).round().clamp(155, 192);

    // Pojemność glikogenu (350g - 580g proporcjonalnie do masy mięśniowej)
    final double glycogenGrams = (weightKg * (1.0 - bodyFat / 100.0) * 7.5).clamp(380.0, 580.0);

    return RiderPhysiology(
      heightCm: double.parse(heightCm.toStringAsFixed(1)),
      weightKg: double.parse(weightKg.toStringAsFixed(1)),
      bodyFatPercentage: double.parse(bodyFat.toStringAsFixed(1)),
      ftpWatts: ftpWatts,
      wPrimeJoules: wPrime,
      vo2Max: double.parse(vo2Max.toStringAsFixed(1)),
      maxHr: maxHr,
      restingHr: restingHr,
      lactateThresholdHr: lthr,
      recoveryRate: double.parse(recoveryRate.toStringAsFixed(2)),
      glycogenCapacityGrams: double.parse(glycogenGrams.toStringAsFixed(1)),
    );
  }

  static RiderPowerProfile _generatePowerProfile(
    RiderSpecialization spec,
    RiderPhysiology phys,
    int ovrTarget,
    math.Random rng,
  ) {
    final double weight = phys.weightKg;
    final int ftp = phys.ftpWatts;
    final double q = ((ovrTarget - 60) / 35.0).clamp(0.0, 1.0);

    int watts5s;
    int watts15s;
    int watts30s;
    int watts1m;
    int watts3m;
    int watts5m;
    int watts20m;
    int watts60m;

    switch (spec) {
      case RiderSpecialization.pureSprinter:
        // Czysty sprinter: kosmiczny sprint 5s (do 1850 W), potężne 15s i 30s, słabsze 20m/60m
        watts5s = (1350 + (q * 420) + rng.nextInt(100)).round(); // 1350 - 1870 W
        watts15s = (watts5s * (0.84 + rng.nextDouble() * 0.04)).round();
        watts30s = (watts15s * (0.76 + rng.nextDouble() * 0.04)).round();
        watts1m = (watts30s * (0.74 + rng.nextDouble() * 0.04)).round();
        watts3m = (ftp * (1.28 + q * 0.12)).round();
        watts5m = (ftp * (1.18 + q * 0.08)).round();
        watts20m = (ftp * 1.04).round();
        watts60m = (ftp * 0.96).round();
        break;

      case RiderSpecialization.versatileSprinter:
        watts5s = (1250 + (q * 360) + rng.nextInt(80)).round(); // 1250 - 1690 W
        watts15s = (watts5s * (0.83 + rng.nextDouble() * 0.03)).round();
        watts30s = (watts15s * (0.77 + rng.nextDouble() * 0.03)).round();
        watts1m = (watts30s * (0.76 + rng.nextDouble() * 0.03)).round();
        watts3m = (ftp * (1.32 + q * 0.14)).round();
        watts5m = (ftp * (1.20 + q * 0.09)).round();
        watts20m = (ftp * 1.045).round();
        watts60m = (ftp * 0.97).round();
        break;

      case RiderSpecialization.puncher:
        // Puncheur: wybitne 1m i 3m, solidny finisz pod górę
        watts5s = (1100 + (q * 320) + rng.nextInt(80)).round(); // 1100 - 1500 W
        watts15s = (watts5s * (0.82 + rng.nextDouble() * 0.03)).round();
        watts30s = (watts15s * (0.80 + rng.nextDouble() * 0.03)).round();
        // 1m: kluczowy wskaźnik pod ścianki (11 - 13.5 W/kg)
        watts1m = (weight * (9.5 + q * 3.8 + rng.nextDouble() * 0.3)).round();
        watts3m = (ftp * (1.38 + q * 0.16)).round();
        watts5m = (ftp * (1.24 + q * 0.10)).round();
        watts20m = (ftp * 1.05).round();
        watts60m = (ftp * 0.97).round();
        break;

      case RiderSpecialization.pureClimber:
        // Czysty góral: niski sprint bezwzględny (950-1180W), ale kosmiczne 20m i 60m w W/kg!
        watts5s = (880 + (q * 250) + rng.nextInt(60)).round(); // 880 - 1190 W (nigdy 1800W!)
        watts15s = (watts5s * (0.82 + rng.nextDouble() * 0.03)).round();
        watts30s = (watts15s * (0.78 + rng.nextDouble() * 0.03)).round();
        watts1m = (weight * (8.5 + q * 2.5)).round(); // 8.5 - 11 W/kg
        watts3m = (ftp * (1.30 + q * 0.12)).round();
        watts5m = (ftp * (1.22 + q * 0.10)).round(); // 6.8 - 7.8 W/kg
        watts20m = (ftp * 1.055).round(); // 6.0 - 6.6 W/kg na 20 min
        watts60m = (ftp * 0.985).round();
        break;

      case RiderSpecialization.gcClimber:
        watts5s = (1050 + (q * 280) + rng.nextInt(70)).round(); // 1050 - 1400 W
        watts15s = (watts5s * (0.82 + rng.nextDouble() * 0.03)).round();
        watts30s = (watts15s * (0.79 + rng.nextDouble() * 0.03)).round();
        watts1m = (weight * (9.2 + q * 3.0)).round();
        watts3m = (ftp * (1.34 + q * 0.14)).round();
        watts5m = (ftp * (1.23 + q * 0.10)).round();
        watts20m = (ftp * 1.055).round();
        watts60m = (ftp * 0.985).round();
        break;

      case RiderSpecialization.timeTrialist:
        // Czasowiec: ogromna moc 20m i 60m bliska progowej
        watts5s = (1120 + (q * 300) + rng.nextInt(80)).round();
        watts15s = (watts5s * (0.83 + rng.nextDouble() * 0.03)).round();
        watts30s = (watts15s * (0.80 + rng.nextDouble() * 0.03)).round();
        watts1m = (ftp * 1.55).round();
        watts3m = (ftp * 1.30).round();
        watts5m = (ftp * 1.19).round();
        watts20m = (ftp * 1.06).round();
        watts60m = (ftp * 0.995).round(); // Znakomita tolerancja 1h wysiłku
        break;

      case RiderSpecialization.classicCobbles:
      case RiderSpecialization.domestiqueEngine:
      case RiderSpecialization.breakawaySpecialist:
        watts5s = (1150 + (q * 340) + rng.nextInt(70)).round();
        watts15s = (watts5s * (0.83 + rng.nextDouble() * 0.03)).round();
        watts30s = (watts15s * (0.78 + rng.nextDouble() * 0.03)).round();
        watts1m = (ftp * 1.60).round();
        watts3m = (ftp * 1.30).round();
        watts5m = (ftp * 1.20).round();
        watts20m = (ftp * 1.05).round();
        watts60m = (ftp * 0.975).round();
        break;
    }

    return RiderPowerProfile(
      watts5s: watts5s,
      watts15s: watts15s,
      watts30s: watts30s,
      watts1m: watts1m,
      watts3m: watts3m,
      watts5m: watts5m,
      watts20m: watts20m,
      watts60m: watts60m,
    );
  }

  static RiderSkills _generateSkills(
    RiderSpecialization spec,
    int ovrTarget,
    math.Random rng,
  ) {
    final double q = ((ovrTarget - 60) / 35.0).clamp(0.0, 1.0);
    final int baseSkill = (55 + q * 30).round();

    int cobbles = (baseSkill + rng.nextInt(15) - 7).clamp(40, 99);
    int descending = (baseSkill + rng.nextInt(15) - 7).clamp(40, 99);
    int bikeHandling = (baseSkill + rng.nextInt(15) - 7).clamp(40, 99);
    int aero = (baseSkill + rng.nextInt(15) - 7).clamp(40, 99);
    int drafting = (baseSkill + rng.nextInt(15) - 7).clamp(40, 99);
    int raceIq = (baseSkill + rng.nextInt(15) - 7).clamp(40, 99);
    int rain = (baseSkill + rng.nextInt(15) - 7).clamp(40, 99);
    int heat = (baseSkill + rng.nextInt(15) - 7).clamp(40, 99);
    int ttPos = (baseSkill + rng.nextInt(15) - 7).clamp(40, 99);

    // Modyfikatory specjalizacji
    switch (spec) {
      case RiderSpecialization.classicCobbles:
        cobbles = (82 + q * 16 + rng.nextInt(5)).round().clamp(80, 99);
        bikeHandling = (80 + q * 16 + rng.nextInt(5)).round().clamp(78, 99);
        rain = (78 + q * 18 + rng.nextInt(5)).round().clamp(76, 99);
        break;
      case RiderSpecialization.pureClimber:
        descending = (60 + q * 25 + rng.nextInt(10)).round().clamp(50, 95);
        heat = (75 + q * 20 + rng.nextInt(6)).round().clamp(70, 99);
        cobbles = (45 + q * 20 + rng.nextInt(8)).round().clamp(40, 75); // Górale cierpią na brukach
        break;
      case RiderSpecialization.timeTrialist:
        ttPos = (85 + q * 14 + rng.nextInt(5)).round().clamp(84, 99);
        aero = (84 + q * 14 + rng.nextInt(5)).round().clamp(82, 99);
        break;
      case RiderSpecialization.pureSprinter:
        bikeHandling = (80 + q * 16 + rng.nextInt(5)).round().clamp(78, 99);
        drafting = (82 + q * 16 + rng.nextInt(5)).round().clamp(80, 99);
        break;
      case RiderSpecialization.breakawaySpecialist:
        raceIq = (82 + q * 16 + rng.nextInt(5)).round().clamp(80, 99);
        aero = (78 + q * 16 + rng.nextInt(5)).round().clamp(75, 98);
        break;
      default:
        break;
    }

    return RiderSkills(
      cobbles: cobbles,
      descending: descending,
      bikeHandling: bikeHandling,
      aeroPositioning: aero,
      draftingEfficiency: drafting,
      raceIq: raceIq,
      rainResistance: rain,
      heatTolerance: heat,
      timeTrialPositioning: ttPos,
    );
  }

  static RiderAppearance _generateAppearance(
    RiderSpecialization spec,
    String nationIso,
    math.Random rng,
  ) {
    BodyBuildType build;
    switch (spec) {
      case RiderSpecialization.pureClimber:
      case RiderSpecialization.gcClimber:
        build = BodyBuildType.climberLean;
        break;
      case RiderSpecialization.pureSprinter:
      case RiderSpecialization.classicCobbles:
        build = BodyBuildType.sprinterMuscular;
        break;
      default:
        build = BodyBuildType.allRounder;
        break;
    }

    // Odcienie skóry dopasowane kulturowo/geograficznie
    String skinTone;
    if (nationIso == 'ERI' || nationIso == 'RSA') {
      skinTone = rng.nextDouble() < 0.85 ? '#3B2219' : '#D2A17E';
    } else if (nationIso == 'COL' || nationIso == 'ECU') {
      skinTone = '#B88258';
    } else if (nationIso == 'ESP' || nationIso == 'ITA' || nationIso == 'POR' || nationIso == 'GRE') {
      skinTone = rng.nextDouble() < 0.6 ? '#E0B589' : '#F5D0A9';
    } else {
      skinTone = '#FCE2C6';
    }

    final hairColors = ['#1C1C1C', '#3E2723', '#5D4037', '#A1887F', '#F5DEB3', '#D7CCC8'];
    final hairColor = hairColors[rng.nextInt(hairColors.length)];

    return RiderAppearance(
      faceShapeIndex: rng.nextInt(8),
      skinToneHex: skinTone,
      hairStyleIndex: rng.nextInt(12),
      hairColorHex: hairColor,
      facialHairIndex: rng.nextInt(6),
      glassesModelId: 'glasses_pro_${1 + rng.nextInt(5)}',
      glassesLensColorHex: rng.nextBool() ? '#FFD700' : '#1E88E5',
      helmetModelId: 'helmet_aero_${1 + rng.nextInt(4)}',
      shoeColorHex: rng.nextBool() ? '#FFFFFF' : '#000000',
      sockHeightProportion: 0.65 + rng.nextDouble() * 0.20,
      bodyBuildType: build,
    );
  }

  static int _calculateRealisticSalaryEur(int ovr, RiderRole role, int age) {
    if (ovr < 65) return 2500;
    if (ovr < 70) return 4000;
    if (ovr < 75) return 8000;
    if (ovr < 80) return 18000;
    if (ovr < 85) return 45000;
    if (ovr < 90) return 120000;
    // Supergwiazdy (>90 OVR) zarabiają 250k - 500k EUR miesięcznie (€3m - €6m rocznie)
    return 280000 + (ovr - 90) * 65000;
  }

  static int _estimateCareerPoints(int ovr, int age) {
    if (age <= 21) return (ovr - 60) * 15;
    final int seasons = math.max(1, age - 21);
    final int annualPoints = ((ovr - 65) * (ovr - 65) * 1.5).round().clamp(20, 2200);
    return annualPoints * seasons;
  }

  static String _pickRandomNationality(math.Random rng) {
    // Wagi państw kolarskich (większa szansa na tradycyjne potęgi kolarskie)
    final roll = rng.nextInt(100);
    if (roll < 12) return 'FRA';
    if (roll < 24) return 'BEL';
    if (roll < 34) return 'ITA';
    if (roll < 44) return 'ESP';
    if (roll < 52) return 'NED';
    if (roll < 60) return 'GBR';
    if (roll < 66) return 'POL';
    if (roll < 72) return 'DEN';
    if (roll < 78) return 'SLO';
    if (roll < 84) return 'COL';
    if (roll < 89) return 'AUS';
    if (roll < 93) return 'GER';
    if (roll < 96) return 'USA';
    // Pozostałe kraje
    final rest = ['NOR', 'SUI', 'POR', 'AUT', 'ERI', 'KAZ', 'CZE', 'ECU', 'IRL', 'NZL', 'RSA', 'SVK'];
    return rest[rng.nextInt(rest.length)];
  }

  static RiderSpecialization _pickRandomSpecialization(math.Random rng, String nation) {
    // Profilowanie narodowe: Kolumbijczycy częściej są góralami, Belgowie na bruki, Holendrzy sprinterami
    if (nation == 'COL' || nation == 'ECU') {
      return rng.nextDouble() < 0.65 ? RiderSpecialization.pureClimber : RiderSpecialization.gcClimber;
    }
    if (nation == 'BEL') {
      return rng.nextDouble() < 0.40 ? RiderSpecialization.classicCobbles : RiderSpecialization.puncher;
    }
    if (nation == 'NED') {
      return rng.nextDouble() < 0.35 ? RiderSpecialization.pureSprinter : RiderSpecialization.classicCobbles;
    }

    const specs = RiderSpecialization.values;
    return specs[rng.nextInt(specs.length)];
  }

  static (String, String) _generateRiderName(String nationIso, math.Random rng) {
    final entry = _namesDatabase[nationIso] ?? _namesDatabase['POL']!;
    final firstNames = entry.firstNames;
    final lastNames = entry.lastNames;

    final first = firstNames[rng.nextInt(firstNames.length)];
    final last = lastNames[rng.nextInt(lastNames.length)];
    return (first, last);
  }

  // ---------------------------------------------------------------------------
  // BAZA DANYCH IMION I NAZWISK Z 25 KRAJÓW KOLARSKICH
  // ---------------------------------------------------------------------------
  static const Map<String, _NationNames> _namesDatabase = {
    'POL': _NationNames(
      firstNames: ['Stanisław', 'Michał', 'Maciej', 'Rafał', 'Tomasz', 'Filip', 'Bartłomiej', 'Piotr', 'Szymon', 'Mateusz', 'Łukasz', 'Kamil', 'Jakub', 'Kacper'],
      lastNames: ['Wiśniewski', 'Kamiński', 'Lewandowski', 'Zieliński', 'Dąbrowski', 'Kozłowski', 'Jankowski', 'Kwiatkowski', 'Majewski', 'Nowak', 'Wójcik', 'Kowalski', 'Kaczmarek'],
    ),
    'FRA': _NationNames(
      firstNames: ['Julian', 'Thibaut', 'Romain', 'Arnaud', 'Guillaume', 'Valentin', 'Benoît', 'Anthony', 'David', 'Pierre', 'Hugo', 'Axel', 'Lenny', 'Paul'],
      lastNames: ['Laurent', 'Alaphilippe', 'Bardet', 'Pinot', 'Démare', 'Martin', 'Gaudu', 'Madouas', 'Cosnefroy', 'Thomas', 'Vauquelin', 'Grégoire', 'Martinez', 'Paret-Peintre'],
    ),
    'BEL': _NationNames(
      firstNames: ['Remco', 'Wout', 'Jasper', 'Tim', 'Tiesj', 'Dylan', 'Arnaud', 'Maxim', 'Yves', 'Victor', 'Florian', 'Lennert', 'Cian', 'Ilan'],
      lastNames: ['Van Aert', 'Evenepoel', 'Philipsen', 'De Lie', 'Wellens', 'Benoot', 'Teuns', 'Van Gils', 'Lampaert', 'Campenaerts', 'Vermeersch', 'Van Eetvelt', 'Uijtdebroeks', 'Van Wilder'],
    ),
    'ITA': _NationNames(
      firstNames: ['Filippo', 'Matteo', 'Giulio', 'Damiano', 'Alberto', 'Vincenzo', 'Antonio', 'Lorenzo', 'Davide', 'Andrea', 'Edoardo', 'Jonathan', 'Samuele'],
      lastNames: ['Ganna', 'Bagioli', 'Ciccone', 'Caruso', 'Bettiol', 'Milan', 'Fortunato', 'Rota', 'Formolo', 'Sobrero', 'Affini', 'Tiberi', 'Battistella', 'Piganzoli'],
    ),
    'ESP': _NationNames(
      firstNames: ['Enric', 'Mikel', 'Juan', 'Carlos', 'Pello', 'Alex', 'Ion', 'Marc', 'Oier', 'Roger', 'Pelayo', 'Igor', 'Raúl', 'Pablo'],
      lastNames: ['Mas', 'Landa', 'Ayuso', 'Rodríguez', 'Bilbao', 'Aranburu', 'Izagirre', 'Soler', 'Lazkano', 'Adrià', 'Sánchez', 'Castrillo', 'García', 'Romero'],
    ),
    'SLO': _NationNames(
      firstNames: ['Tadej', 'Primož', 'Matej', 'Jan', 'Domen', 'Luka', 'Kristijan', 'Grega', 'Jaka', 'Bor', 'Gal', 'Anže'],
      lastNames: ['Pogačar', 'Roglič', 'Mohorič', 'Tratnik', 'Novak', 'Mezgec', 'Koren', 'Bole', 'Primožič', 'Glivar', 'Govekar', 'Štangelj'],
    ),
    'NED': _NationNames(
      firstNames: ['Mathieu', 'Dylan', 'Bauke', 'Wilco', 'Thymen', 'Olav', 'Koen', 'Sam', 'Pascal', 'Danny', 'Marijn', 'Frank', 'Tibor'],
      lastNames: ['Van der Poel', 'Groenewegen', 'Mollema', 'Kelderman', 'Arensman', 'Kooij', 'Bouwman', 'Oomen', 'Eenkhoorn', 'Van Poppel', 'Van den Berg', 'Van Dijke', 'Del Grosso'],
    ),
    'COL': _NationNames(
      firstNames: ['Egan', 'Nairo', 'Rigoberto', 'Daniel', 'Sergio', 'Esteban', 'Harold', 'Einer', 'Santiago', 'Brandon', 'Diego', 'Jesus'],
      lastNames: ['Bernal', 'Quintana', 'Urán', 'Martínez', 'Higuita', 'Chaves', 'Tejada', 'Rubio', 'Buitrago', 'Rivera', 'Camargo', 'Pena'],
    ),
    'DEN': _NationNames(
      firstNames: ['Jonas', 'Mads', 'Kasper', 'Mikkel', 'Søren', 'Magnus', 'Mattias', 'Andreas', 'Michael', 'Johan', 'Tobias', 'Albert'],
      lastNames: ['Vingegaard', 'Pedersen', 'Asgreen', 'Bjerg', 'Kragh', 'Cort', 'Skjelmose', 'Kron', 'Valgren', 'Price-Pejtersen', 'Lund', 'Philipsen'],
    ),
    'GBR': _NationNames(
      firstNames: ['Geraint', 'Thomas', 'Adam', 'Simon', 'Fred', 'Ethan', 'Mark', 'Tao', 'Ben', 'Jake', 'Joseph', 'Leo', 'Finlay'],
      lastNames: ['Thomas', 'Pidcock', 'Yates', 'Wright', 'Hayter', 'Cavendish', 'Geoghegan', 'Tulett', 'Stewart', 'Turner', 'Blackmore', 'Hayter', 'Onley'],
    ),
    'GER': _NationNames(
      firstNames: ['Emanuel', 'Maximilian', 'Lennard', 'Nils', 'Georg', 'Pascal', 'John', 'Florian', 'Nico', 'Jasha', 'Marco', 'Emil'],
      lastNames: ['Buchmann', 'Schachmann', 'Kämna', 'Politt', 'Zimmermann', 'Ackermann', 'Degenkolb', 'Lipowitz', 'Denz', 'Sütterlin', 'Brenner', 'Herzog'],
    ),
    'AUS': _NationNames(
      firstNames: ['Jai', 'Ben', 'Michael', 'Kaden', 'Caleb', 'Lucas', 'Luke', 'Rohan', 'Chris', 'Jack', 'Luke', 'Kelland'],
      lastNames: ['Hindley', 'O\'Connor', 'Matthews', 'Groves', 'Ewan', 'Plapp', 'Durbridge', 'Dennis', 'Hamilton', 'Haig', 'Plowright', 'O\'Brien'],
    ),
    'USA': _NationNames(
      firstNames: ['Sepp', 'Matteo', 'Magnus', 'Neilson', 'Brandon', 'Quinn', 'Kevin', 'Luke', 'Lawson', 'Chad', 'Matthew', 'Artem'],
      lastNames: ['Kuss', 'Jorgenson', 'Sheffield', 'Powless', 'McNulty', 'Simmons', 'Vermaerke', 'Lamperti', 'Craddock', 'Haga', 'Riccitello', 'Shmidt'],
    ),
    'NOR': _NationNames(
      firstNames: ['Tobias', 'Alexander', 'Johannes', 'Andreas', 'Torstein', 'Søren', 'Odd Christian', 'Rasmus', 'Idar', 'Markus', 'Per Strand'],
      lastNames: ['Foss', 'Kristoff', 'Staune-Mittet', 'Leknessund', 'Træen', 'Wærenskjold', 'Eiking', 'Tiller', 'Andersen', 'Hoelgaard', 'Hagenes'],
    ),
    'SUI': _NationNames(
      firstNames: ['Stefan', 'Marc', 'Gino', 'Silvan', 'Mauro', 'Fabian', 'Mathias', 'Johan', 'Yannis', 'Alexandre', 'Robin'],
      lastNames: ['Küng', 'Hirschi', 'Mäder', 'Dillier', 'Schmid', 'Bissegger', 'Cancellara', 'Frank', 'Jacobs', 'Voisard', 'Froidevaux'],
    ),
    'POR': _NationNames(
      firstNames: ['João', 'Rui', 'Nelson', 'Ruben', 'António', 'Ivo', 'Iúri', 'Afonso', 'André', 'Tiago'],
      lastNames: ['Almeida', 'Costa', 'Oliveira', 'Guerreiro', 'Morgado', 'Leitão', 'Carvalho', 'Eulálio', 'Silva', 'Antunes'],
    ),
    'AUT': _NationNames(
      firstNames: ['Felix', 'Gregor', 'Patrick', 'Michael', 'Marco', 'Lukas', 'Sebastian', 'Rainer', 'Hermann', 'Tobias'],
      lastNames: ['Großschartner', 'Mühlberger', 'Konrad', 'Gogl', 'Haller', 'Pöstlberger', 'Schönberger', 'Kepplinger', 'Pernsteiner', 'Bayer'],
    ),
    'ERI': _NationNames(
      firstNames: ['Biniam', 'Natnael', 'Merhawi', 'Amanuel', 'Henok', 'Daniel', 'Metkel', 'Dawit', 'Nahom', 'Biniyam'],
      lastNames: ['Girmay', 'Berhane', 'Kudus', 'Ghebreigzabhier', 'Mulubrhan', 'Teklehaimanot', 'Eyob', 'Yemane', 'Zeray', 'Araya'],
    ),
    'KAZ': _NationNames(
      firstNames: ['Alexey', 'Yevgeniy', 'Vadim', 'Dmitriy', 'Gleb', 'Igor', 'Daniil', 'Nicolas', 'Anton', 'Andrey'],
      lastNames: ['Lutsenko', 'Fedorov', 'Pronskiy', 'Gruzdev', 'Brussenskiy', 'Chzhan', 'Fominykh', 'Vinokurov', 'Kuzmin', 'Zeits'],
    ),
    'CZE': _NationNames(
      firstNames: ['Zdeněk', 'Jan', 'Mathias', 'Petr', 'Josef', 'Michal', 'Karel', 'Pavel', 'Roman', 'Jakub'],
      lastNames: ['Štybar', 'Hirt', 'Vacek', 'Kelemen', 'Černý', 'Schlegel', 'Bittner', 'Kreuziger', 'Otruba', 'Ťoupalík'],
    ),
    'ECU': _NationNames(
      firstNames: ['Richard', 'Jhonatan', 'Alexander', 'Jefferson', 'Harold', 'Byron', 'Steven', 'Nixon', 'Jorge', 'Martín'],
      lastNames: ['Carapaz', 'Narváez', 'Cepeda', 'Alveiro', 'Guamá', 'Haro', 'Montenegro', 'Rosero', 'Huera', 'López'],
    ),
    'IRL': _NationNames(
      firstNames: ['Sam', 'Eddie', 'Ben', 'Ryan', 'Darren', 'Archie', 'Matthew', 'Rory', 'Cormac', 'Jesse'],
      lastNames: ['Bennett', 'Dunbar', 'Healy', 'Mullen', 'Rafferty', 'Townsend', 'Teggart', 'O\'Brien', 'Ewart', 'Devins'],
    ),
    'NZL': _NationNames(
      firstNames: ['George', 'Laurence', 'Corbin', 'Finn', 'Patrick', 'Dion', 'Sam', 'Jack', 'Reuben', 'Campbell'],
      lastNames: ['Bennett', 'Pithie', 'Strong', 'Fisher-Black', 'Bevin', 'Smith', 'Bewley', 'Bauer', 'Thompson', 'Stewart'],
    ),
    'RSA': _NationNames(
      firstNames: ['Louis', 'Daryl', 'Ryan', 'Stefan', 'Nicholas', 'Willie', 'Clint', 'Gustav', 'Jaco', 'Kent'],
      lastNames: ['Meintjes', 'Impey', 'Gibbons', 'de Bod', 'Dlamini', 'Smit', 'Hendricks', 'Basson', 'Venter', 'Main'],
    ),
    'SVK': _NationNames(
      firstNames: ['Peter', 'Juraj', 'Martin', 'Lukáš', 'Marek', 'Matúš', 'Erik', 'Samuel', 'Patrik', 'Šimon'],
      lastNames: ['Sagan', 'Velits', 'Svrček', 'Kubiš', 'Čanecký', 'Štoček', 'Baška', 'Kováč', 'Tybor', 'Haring'],
    ),
  };
}

class _NationNames {
  final List<String> firstNames;
  final List<String> lastNames;

  const _NationNames({
    required this.firstNames,
    required this.lastNames,
  });
}

