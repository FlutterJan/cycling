import 'dart:math' as math;

/// Dywizja sprzętowa i klasyfikacyjna w kolarstwie paraolimpijskim UCI Para-Cycling.
enum ParacyclingDivision {
  tandemB,
  handbike,
  bicycleC;

  String toJson() => name;

  static ParacyclingDivision fromJson(String value) {
    return ParacyclingDivision.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ParacyclingDivision.bicycleC,
    );
  }

  /// Czytelna nazwa dywizji po polsku.
  String get displayNamePl {
    switch (this) {
      case ParacyclingDivision.tandemB:
        return 'Tandemy (Klasa B)';
      case ParacyclingDivision.handbike:
        return 'Handbike (H1–H5)';
      case ParacyclingDivision.bicycleC:
        return 'Rowery Jednośladowe (C1–C5)';
    }
  }
}

/// Oficjalna klasa sportowa UCI Para-Cycling objęta modelem (B, H1–H5, C1–C5).
enum ParacyclingSportClass {
  b,
  h1,
  h2,
  h3,
  h4,
  h5,
  c1,
  c2,
  c3,
  c4,
  c5;

  String toJson() => name;

  static ParacyclingSportClass fromJson(String value) {
    return ParacyclingSportClass.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ParacyclingSportClass.c5,
    );
  }

  /// Kod klasy UCI (np. `B`, `H3`, `C5`).
  String get code => name.toUpperCase();

  /// Dywizja sprzętowa przypisana do danej klasy sportowej.
  ParacyclingDivision get division {
    switch (this) {
      case ParacyclingSportClass.b:
        return ParacyclingDivision.tandemB;
      case ParacyclingSportClass.h1:
      case ParacyclingSportClass.h2:
      case ParacyclingSportClass.h3:
      case ParacyclingSportClass.h4:
      case ParacyclingSportClass.h5:
        return ParacyclingDivision.handbike;
      case ParacyclingSportClass.c1:
      case ParacyclingSportClass.c2:
      case ParacyclingSportClass.c3:
      case ParacyclingSportClass.c4:
      case ParacyclingSportClass.c5:
        return ParacyclingDivision.bicycleC;
    }
  }

  /// Czy klasa wymaga widzącego pilota (wyłącznie Tandem Klasa B).
  bool get requiresPilot => this == ParacyclingSportClass.b;

  /// Liczba kół pojazdu regulaminowego UCI dla danej klasy.
  int get wheelCount =>
      division == ParacyclingDivision.handbike ? 3 : 2;

  /// Punktacja klasyfikacyjna używana w sztafecie drużynowej Handbike (H1=1 .. H5=5).
  int get relayClassificationPoints {
    switch (this) {
      case ParacyclingSportClass.h1:
        return 1;
      case ParacyclingSportClass.h2:
        return 2;
      case ParacyclingSportClass.h3:
        return 3;
      case ParacyclingSportClass.h4:
        return 4;
      case ParacyclingSportClass.h5:
        return 5;
      case ParacyclingSportClass.b:
      case ParacyclingSportClass.c1:
      case ParacyclingSportClass.c2:
      case ParacyclingSportClass.c3:
      case ParacyclingSportClass.c4:
      case ParacyclingSportClass.c5:
        return 0;
    }
  }

  /// Współczynnik wyrównawczy UCI (procentowy) dla wyścigów łączonych.
  double get uciFactorPercentage {
    switch (this) {
      case ParacyclingSportClass.b:
        return 100.0;
      case ParacyclingSportClass.h1:
        return 68.5;
      case ParacyclingSportClass.h2:
        return 81.2;
      case ParacyclingSportClass.h3:
        return 92.8;
      case ParacyclingSportClass.h4:
        return 97.4;
      case ParacyclingSportClass.h5:
        return 100.0;
      case ParacyclingSportClass.c1:
        return 86.0;
      case ParacyclingSportClass.c2:
        return 90.5;
      case ParacyclingSportClass.c3:
        return 94.2;
      case ParacyclingSportClass.c4:
        return 97.6;
      case ParacyclingSportClass.c5:
        return 100.0;
    }
  }

  /// Bazowy opór aerodynamiczny CdA [m²] charakterystyczny dla pozycji w klasie.
  double get referenceCdaM2 {
    switch (this) {
      case ParacyclingSportClass.b:
        return 0.315;
      case ParacyclingSportClass.h1:
      case ParacyclingSportClass.h2:
      case ParacyclingSportClass.h3:
        return 0.195;
      case ParacyclingSportClass.h4:
        return 0.205;
      case ParacyclingSportClass.h5:
        return 0.245;
      case ParacyclingSportClass.c1:
      case ParacyclingSportClass.c2:
      case ParacyclingSportClass.c3:
      case ParacyclingSportClass.c4:
      case ParacyclingSportClass.c5:
        return 0.240;
    }
  }

  /// Czytelna nazwa klasy po polsku.
  String get displayNamePl {
    switch (this) {
      case ParacyclingSportClass.b:
        return 'Klasa B — Tandem (Pilot + Stoker)';
      case ParacyclingSportClass.h1:
        return 'Klasa H1 — Handbike Leżący (Tetraplegia)';
      case ParacyclingSportClass.h2:
        return 'Klasa H2 — Handbike Leżący (Ograniczona stabilność)';
      case ParacyclingSportClass.h3:
        return 'Klasa H3 — Handbike Leżący (Paraplegia)';
      case ParacyclingSportClass.h4:
        return 'Klasa H4 — Handbike Leżący (Pełna praca tułowia)';
      case ParacyclingSportClass.h5:
        return 'Klasa H5 — Handbike Klęczący';
      case ParacyclingSportClass.c1:
        return 'Klasa C1 — Rower (Najwyższy stopień ograniczeń)';
      case ParacyclingSportClass.c2:
        return 'Klasa C2 — Rower (Znaczne ograniczenia)';
      case ParacyclingSportClass.c3:
        return 'Klasa C3 — Rower (Umiarkowane ograniczenia)';
      case ParacyclingSportClass.c4:
        return 'Klasa C4 — Rower (Łagodne ograniczenia kończyn)';
      case ParacyclingSportClass.c5:
        return 'Klasa C5 — Rower (Minimalne ograniczenia)';
    }
  }

  /// Krótki opis charakterystyki medyczno-sprzętowej UCI po polsku.
  String get uciDescriptionPl {
    switch (this) {
      case ParacyclingSportClass.b:
        return 'Zawodnik z dysfunkcją wzroku (stoker) jadący w parze z widzącym pilotem na dwuosobowym tandemie.';
      case ParacyclingSportClass.h1:
        return 'Trójkołowy handbike w pozycji leżącej, napędzany wyłącznie rękami przy minimalnej stabilizacji tułowia.';
      case ParacyclingSportClass.h2:
        return 'Trójkołowy handbike w pozycji leżącej z częściową stabilnością obręczy barkowej i ramion.';
      case ParacyclingSportClass.h3:
        return 'Trójkołowy handbike leżący dla zawodników bez stabilizacji dolnego odcinka tułowia.';
      case ParacyclingSportClass.h4:
        return 'Trójkołowy handbike leżący z pełną kontrolą górnej i środkowej części tułowia.';
      case ParacyclingSportClass.h5:
        return 'Trójkołowy handbike w pozycji klęczącej umożliwiającej dynamiczne wspomaganie pracy ramion tułowiem.';
      case ParacyclingSportClass.c1:
        return 'Standardowy rower szosowy lub czasowy UCI z zaawansowanymi adaptacjami (np. jazda jednonóż).';
      case ParacyclingSportClass.c2:
        return 'Rower jednośladowy z protezą lub adaptacją napędu dla znacznych ubytków funkcji ruchowej.';
      case ParacyclingSportClass.c3:
        return 'Rower jednośladowy z umiarkowaną adaptacją ergonomiczną i asymetrią generowania mocy.';
      case ParacyclingSportClass.c4:
        return 'Rower jednośladowy dla kolarzy z lekką dysfunkcją kończyny dolnej lub górnej.';
      case ParacyclingSportClass.c5:
        return 'Rower jednośladowy dla zawodników z minimalnymi ograniczeniami (np. ubytek przedramienia).';
    }
  }
}

/// Kategoria płciowa zawodów UCI Para-Cycling.
enum ParacyclingGenderCategory {
  men,
  women,
  mixedTeamRelay;

  String toJson() => name;

  static ParacyclingGenderCategory fromJson(String value) {
    return ParacyclingGenderCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ParacyclingGenderCategory.men,
    );
  }

  /// Czytelna nazwa kategorii po polsku.
  String get displayNamePl {
    switch (this) {
      case ParacyclingGenderCategory.men:
        return 'Mężczyźni';
      case ParacyclingGenderCategory.women:
        return 'Kobiety';
      case ParacyclingGenderCategory.mixedTeamRelay:
        return 'Sztafeta Mieszana';
    }
  }
}

/// Ranga zawodów w kalendarzu UCI Para-Cycling.
enum ParacyclingEventTier {
  paralympicGames,
  uciWorldChampionships,
  uciWorldCup,
  continentalChampionships;

  String toJson() => name;

  static ParacyclingEventTier fromJson(String value) {
    return ParacyclingEventTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ParacyclingEventTier.uciWorldCup,
    );
  }

  /// Mnożnik punktów rankingowych UCI dla rangi imprezy.
  double get pointsMultiplier {
    switch (this) {
      case ParacyclingEventTier.paralympicGames:
        return 2.0;
      case ParacyclingEventTier.uciWorldChampionships:
        return 1.6;
      case ParacyclingEventTier.uciWorldCup:
        return 1.0;
      case ParacyclingEventTier.continentalChampionships:
        return 0.75;
    }
  }

  /// Czytelna nazwa rangi zawodów po polsku.
  String get displayNamePl {
    switch (this) {
      case ParacyclingEventTier.paralympicGames:
        return 'Igrzyska Paralimpijskie';
      case ParacyclingEventTier.uciWorldChampionships:
        return 'Mistrzostwa Świata UCI Para-Cycling';
      case ParacyclingEventTier.uciWorldCup:
        return 'Puchar Świata UCI Para-Cycling';
      case ParacyclingEventTier.continentalChampionships:
        return 'Mistrzostwa Kontynentalne';
    }
  }
}

/// Konkurencja szosowa w UCI Para-Cycling.
enum ParacyclingDiscipline {
  roadRace,
  individualTimeTrial,
  teamRelay;

  String toJson() => name;

  static ParacyclingDiscipline fromJson(String value) {
    return ParacyclingDiscipline.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ParacyclingDiscipline.roadRace,
    );
  }

  /// Czytelna nazwa konkurencji po polsku.
  String get displayNamePl {
    switch (this) {
      case ParacyclingDiscipline.roadRace:
        return 'Wyścig ze Startu Wspólnego';
      case ParacyclingDiscipline.individualTimeTrial:
        return 'Jazda Indywidualna na Czas (ITT)';
      case ParacyclingDiscipline.teamRelay:
        return 'Sztafeta Drużynowa Handbike';
    }
  }
}

/// Charakterystyka trasy wyścigu paraolimpijskiego.
enum ParacyclingCourseProfile {
  flat,
  rolling,
  technicalCircuit,
  hilly;

  String toJson() => name;

  static ParacyclingCourseProfile fromJson(String value) {
    return ParacyclingCourseProfile.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ParacyclingCourseProfile.rolling,
    );
  }

  /// Czytelna nazwa profilu trasy po polsku.
  String get displayNamePl {
    switch (this) {
      case ParacyclingCourseProfile.flat:
        return 'Płaska i szybka';
      case ParacyclingCourseProfile.rolling:
        return 'Pagórkowata';
      case ParacyclingCourseProfile.technicalCircuit:
        return 'Runda techniczna (zakręty)';
      case ParacyclingCourseProfile.hilly:
        return 'Górska / selektywna';
    }
  }
}

/// Typ sprzętu dopuszczonego do zawodów UCI Para-Cycling.
enum ParacyclingEquipmentType {
  tandemRoadBike,
  tandemTimeTrialBike,
  recumbentHandbike,
  kneelingHandbike,
  soloParaRoadBike,
  soloParaTimeTrialBike;

  String toJson() => name;

  static ParacyclingEquipmentType fromJson(String value) {
    return ParacyclingEquipmentType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ParacyclingEquipmentType.soloParaRoadBike,
    );
  }

  /// Czy sprzęt jest rowerem dwuosobowym (tandemem).
  bool get isTandem =>
      this == ParacyclingEquipmentType.tandemRoadBike ||
      this == ParacyclingEquipmentType.tandemTimeTrialBike;

  /// Czy sprzęt jest trójkołowym handbike'iem.
  bool get isHandbike =>
      this == ParacyclingEquipmentType.recumbentHandbike ||
      this == ParacyclingEquipmentType.kneelingHandbike;

  /// Liczba kół danego typu sprzętu.
  int get wheelCount => isHandbike ? 3 : 2;

  /// Czytelna nazwa typu sprzętu po polsku.
  String get displayNamePl {
    switch (this) {
      case ParacyclingEquipmentType.tandemRoadBike:
        return 'Tandem Szosowy (Klasa B)';
      case ParacyclingEquipmentType.tandemTimeTrialBike:
        return 'Tandem Czasowy Aero (Klasa B)';
      case ParacyclingEquipmentType.recumbentHandbike:
        return 'Handbike Leżący (H1–H4)';
      case ParacyclingEquipmentType.kneelingHandbike:
        return 'Handbike Klęczący (H5)';
      case ParacyclingEquipmentType.soloParaRoadBike:
        return 'Rower Szosowy Para (C1–C5)';
      case ParacyclingEquipmentType.soloParaTimeTrialBike:
        return 'Rower Czasowy Para (C1–C5)';
    }
  }
}

/// Pozycja zawodnika na handbike'u (leżąca vs klęcząca).
enum HandbikePostureType {
  recumbentLow,
  recumbentAthletic,
  kneeling,
  notApplicable;

  String toJson() => name;

  static HandbikePostureType fromJson(String value) {
    return HandbikePostureType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => HandbikePostureType.notApplicable,
    );
  }
}

/// Zdobyty medal na imprezie mistrzowskiej lub pucharowej.
enum ParacyclingMedalType {
  gold,
  silver,
  bronze,
  none;

  String toJson() => name;

  static ParacyclingMedalType fromJson(String value) {
    return ParacyclingMedalType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ParacyclingMedalType.none,
    );
  }
}

/// Specyfikacja techniczna roweru paraolimpijskiego, tandemu lub handbike'a.
class ParacyclingBikeSpec {
  final String id;
  final String name;
  final ParacyclingEquipmentType equipmentType;
  final HandbikePostureType handbikePosture;
  final double weightKg;
  final double cdaM2;
  final double crr;
  final double drivetrainEfficiency;
  final double wheelbaseM;
  final double centerOfGravityHeightM;
  final double brakeCoolingRating;
  final String adaptationNotesPl;

  const ParacyclingBikeSpec({
    required this.id,
    required this.name,
    required this.equipmentType,
    this.handbikePosture = HandbikePostureType.notApplicable,
    required this.weightKg,
    required this.cdaM2,
    required this.crr,
    this.drivetrainEfficiency = 0.975,
    required this.wheelbaseM,
    required this.centerOfGravityHeightM,
    this.brakeCoolingRating = 0.85,
    this.adaptationNotesPl = '',
  });

  /// Liczba kół pojazdu (2 dla tandemów i rowerów C, 3 dla handbike'ów).
  int get wheelCount => equipmentType.wheelCount;

  /// Czy dany rower jest dopuszczony dla wskazanej klasy sportowej UCI.
  bool isCompatibleWithClass(ParacyclingSportClass sportClass) {
    switch (sportClass) {
      case ParacyclingSportClass.b:
        return equipmentType.isTandem;
      case ParacyclingSportClass.h1:
      case ParacyclingSportClass.h2:
      case ParacyclingSportClass.h3:
      case ParacyclingSportClass.h4:
        return equipmentType == ParacyclingEquipmentType.recumbentHandbike;
      case ParacyclingSportClass.h5:
        return equipmentType == ParacyclingEquipmentType.kneelingHandbike;
      case ParacyclingSportClass.c1:
      case ParacyclingSportClass.c2:
      case ParacyclingSportClass.c3:
      case ParacyclingSportClass.c4:
      case ParacyclingSportClass.c5:
        return equipmentType == ParacyclingEquipmentType.soloParaRoadBike ||
            equipmentType == ParacyclingEquipmentType.soloParaTimeTrialBike;
    }
  }

  ParacyclingBikeSpec copyWith({
    String? id,
    String? name,
    ParacyclingEquipmentType? equipmentType,
    HandbikePostureType? handbikePosture,
    double? weightKg,
    double? cdaM2,
    double? crr,
    double? drivetrainEfficiency,
    double? wheelbaseM,
    double? centerOfGravityHeightM,
    double? brakeCoolingRating,
    String? adaptationNotesPl,
  }) {
    return ParacyclingBikeSpec(
      id: id ?? this.id,
      name: name ?? this.name,
      equipmentType: equipmentType ?? this.equipmentType,
      handbikePosture: handbikePosture ?? this.handbikePosture,
      weightKg: weightKg ?? this.weightKg,
      cdaM2: cdaM2 ?? this.cdaM2,
      crr: crr ?? this.crr,
      drivetrainEfficiency: drivetrainEfficiency ?? this.drivetrainEfficiency,
      wheelbaseM: wheelbaseM ?? this.wheelbaseM,
      centerOfGravityHeightM:
          centerOfGravityHeightM ?? this.centerOfGravityHeightM,
      brakeCoolingRating: brakeCoolingRating ?? this.brakeCoolingRating,
      adaptationNotesPl: adaptationNotesPl ?? this.adaptationNotesPl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'equipmentType': equipmentType.toJson(),
        'handbikePosture': handbikePosture.toJson(),
        'weightKg': weightKg,
        'cdaM2': cdaM2,
        'crr': crr,
        'drivetrainEfficiency': drivetrainEfficiency,
        'wheelbaseM': wheelbaseM,
        'centerOfGravityHeightM': centerOfGravityHeightM,
        'brakeCoolingRating': brakeCoolingRating,
        'adaptationNotesPl': adaptationNotesPl,
      };

  factory ParacyclingBikeSpec.fromJson(Map<String, dynamic> json) {
    return ParacyclingBikeSpec(
      id: json['id'] as String? ?? 'bike_default',
      name: json['name'] as String? ?? 'Rower UCI Para-Cycling',
      equipmentType: ParacyclingEquipmentType.fromJson(
        json['equipmentType'] as String? ?? 'soloParaRoadBike',
      ),
      handbikePosture: HandbikePostureType.fromJson(
        json['handbikePosture'] as String? ?? 'notApplicable',
      ),
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 7.4,
      cdaM2: (json['cdaM2'] as num?)?.toDouble() ?? 0.24,
      crr: (json['crr'] as num?)?.toDouble() ?? 0.0032,
      drivetrainEfficiency:
          (json['drivetrainEfficiency'] as num?)?.toDouble() ?? 0.975,
      wheelbaseM: (json['wheelbaseM'] as num?)?.toDouble() ?? 1.0,
      centerOfGravityHeightM:
          (json['centerOfGravityHeightM'] as num?)?.toDouble() ?? 0.95,
      brakeCoolingRating:
          (json['brakeCoolingRating'] as num?)?.toDouble() ?? 0.85,
      adaptationNotesPl: json['adaptationNotesPl'] as String? ?? '',
    );
  }

  /// Zestaw fabrycznych specyfikacji sprzętu dla klas B, H1–H5 i C1–C5.
  static List<ParacyclingBikeSpec> defaultFleet() {
    return const [
      ParacyclingBikeSpec(
        id: 'bike_tandem_road_pro',
        name: 'Carbon Tandem Road Pro (Klasa B)',
        equipmentType: ParacyclingEquipmentType.tandemRoadBike,
        weightKg: 11.4,
        cdaM2: 0.325,
        crr: 0.0031,
        drivetrainEfficiency: 0.970,
        wheelbaseM: 1.86,
        centerOfGravityHeightM: 0.96,
        brakeCoolingRating: 0.94,
        adaptationNotesPl:
            'Wzmocniona rama tandemowa, tarcze 203 mm do zjazdów >95 km/h.',
      ),
      ParacyclingBikeSpec(
        id: 'bike_tandem_tt_aero',
        name: 'Aero Tandem Chrono TT (Klasa B)',
        equipmentType: ParacyclingEquipmentType.tandemTimeTrialBike,
        weightKg: 12.1,
        cdaM2: 0.285,
        crr: 0.0028,
        drivetrainEfficiency: 0.974,
        wheelbaseM: 1.88,
        centerOfGravityHeightM: 0.91,
        brakeCoolingRating: 0.90,
        adaptationNotesPl:
            'Kokpit czasowy pilota i stokera, pełne koło tylne, napęd synchronizowany.',
      ),
      ParacyclingBikeSpec(
        id: 'bike_handbike_recumbent_pro',
        name: 'Carbon Recumbent Shark H1–H4',
        equipmentType: ParacyclingEquipmentType.recumbentHandbike,
        handbikePosture: HandbikePostureType.recumbentLow,
        weightKg: 10.6,
        cdaM2: 0.192,
        crr: 0.0034,
        drivetrainEfficiency: 0.962,
        wheelbaseM: 1.74,
        centerOfGravityHeightM: 0.27,
        brakeCoolingRating: 0.86,
        adaptationNotesPl:
            'Trójkołowa konstrukcja leżąca z niskim środkiem ciężkości i stabilizacją w zakrętach.',
      ),
      ParacyclingBikeSpec(
        id: 'bike_handbike_kneeling_pro',
        name: 'Carbon Kneeling Sprint H5',
        equipmentType: ParacyclingEquipmentType.kneelingHandbike,
        handbikePosture: HandbikePostureType.kneeling,
        weightKg: 11.2,
        cdaM2: 0.242,
        crr: 0.0035,
        drivetrainEfficiency: 0.965,
        wheelbaseM: 1.68,
        centerOfGravityHeightM: 0.42,
        brakeCoolingRating: 0.85,
        adaptationNotesPl:
            'Pozycja klęcząca pozwalająca na zaangażowanie mięśni grzbietu i brzucha.',
      ),
      ParacyclingBikeSpec(
        id: 'bike_para_solo_road',
        name: 'Aero Para-Road SL (C1–C5)',
        equipmentType: ParacyclingEquipmentType.soloParaRoadBike,
        weightKg: 7.05,
        cdaM2: 0.242,
        crr: 0.0030,
        drivetrainEfficiency: 0.980,
        wheelbaseM: 0.99,
        centerOfGravityHeightM: 0.94,
        brakeCoolingRating: 0.88,
        adaptationNotesPl:
            'Zintegrowana dźwignia hamulcowo-przerzutkowa po jednej stronie kierownicy.',
      ),
      ParacyclingBikeSpec(
        id: 'bike_para_solo_tt',
        name: 'Chrono Para-TT (C1–C5)',
        equipmentType: ParacyclingEquipmentType.soloParaTimeTrialBike,
        weightKg: 7.85,
        cdaM2: 0.205,
        crr: 0.0027,
        drivetrainEfficiency: 0.982,
        wheelbaseM: 1.01,
        centerOfGravityHeightM: 0.89,
        brakeCoolingRating: 0.82,
        adaptationNotesPl:
            'Adaptowany podłokietnik czasowy i indywidualna korba pod protezę.',
      ),
    ];
  }
}

/// Profil zawodnika UCI Para-Cycling (lub widzącego pilota dla tandemu Klasy B).
class ParacyclingAthleteProfile {
  final String id;
  final String name;
  final String nationalityCode;
  final int age;
  final ParacyclingSportClass sportClass;
  final ParacyclingGenderCategory gender;
  final double ftpWatts;
  final double peak5sWatts;
  final double vo2Max;
  final double weightKg;
  final int upperBodyEndurance;
  final int bikeHandling;
  final int downhillConfidence;
  final int lactateTolerance;
  final int uciRankingPoints;
  final bool isPilot;

  const ParacyclingAthleteProfile({
    required this.id,
    required this.name,
    required this.nationalityCode,
    required this.age,
    required this.sportClass,
    required this.gender,
    required this.ftpWatts,
    required this.peak5sWatts,
    required this.vo2Max,
    required this.weightKg,
    this.upperBodyEndurance = 75,
    this.bikeHandling = 80,
    this.downhillConfidence = 80,
    this.lactateTolerance = 78,
    this.uciRankingPoints = 0,
    this.isPilot = false,
  });

  /// Stosunek mocy progowej do masy ciała [W/kg].
  double get wPerKg => weightKg > 0 ? ftpWatts / weightKg : 0.0;

  ParacyclingAthleteProfile copyWith({
    String? id,
    String? name,
    String? nationalityCode,
    int? age,
    ParacyclingSportClass? sportClass,
    ParacyclingGenderCategory? gender,
    double? ftpWatts,
    double? peak5sWatts,
    double? vo2Max,
    double? weightKg,
    int? upperBodyEndurance,
    int? bikeHandling,
    int? downhillConfidence,
    int? lactateTolerance,
    int? uciRankingPoints,
    bool? isPilot,
  }) {
    return ParacyclingAthleteProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      nationalityCode: nationalityCode ?? this.nationalityCode,
      age: age ?? this.age,
      sportClass: sportClass ?? this.sportClass,
      gender: gender ?? this.gender,
      ftpWatts: ftpWatts ?? this.ftpWatts,
      peak5sWatts: peak5sWatts ?? this.peak5sWatts,
      vo2Max: vo2Max ?? this.vo2Max,
      weightKg: weightKg ?? this.weightKg,
      upperBodyEndurance: upperBodyEndurance ?? this.upperBodyEndurance,
      bikeHandling: bikeHandling ?? this.bikeHandling,
      downhillConfidence: downhillConfidence ?? this.downhillConfidence,
      lactateTolerance: lactateTolerance ?? this.lactateTolerance,
      uciRankingPoints: uciRankingPoints ?? this.uciRankingPoints,
      isPilot: isPilot ?? this.isPilot,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nationalityCode': nationalityCode,
        'age': age,
        'sportClass': sportClass.toJson(),
        'gender': gender.toJson(),
        'ftpWatts': ftpWatts,
        'peak5sWatts': peak5sWatts,
        'vo2Max': vo2Max,
        'weightKg': weightKg,
        'upperBodyEndurance': upperBodyEndurance,
        'bikeHandling': bikeHandling,
        'downhillConfidence': downhillConfidence,
        'lactateTolerance': lactateTolerance,
        'uciRankingPoints': uciRankingPoints,
        'isPilot': isPilot,
      };

  factory ParacyclingAthleteProfile.fromJson(Map<String, dynamic> json) {
    return ParacyclingAthleteProfile(
      id: json['id'] as String? ?? 'athlete_unknown',
      name: json['name'] as String? ?? 'Nieznany Zawodnik',
      nationalityCode: json['nationalityCode'] as String? ?? 'POL',
      age: (json['age'] as num?)?.toInt() ?? 28,
      sportClass: ParacyclingSportClass.fromJson(
        json['sportClass'] as String? ?? 'c5',
      ),
      gender: ParacyclingGenderCategory.fromJson(
        json['gender'] as String? ?? 'men',
      ),
      ftpWatts: (json['ftpWatts'] as num?)?.toDouble() ?? 280.0,
      peak5sWatts: (json['peak5sWatts'] as num?)?.toDouble() ?? 850.0,
      vo2Max: (json['vo2Max'] as num?)?.toDouble() ?? 68.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 70.0,
      upperBodyEndurance:
          (json['upperBodyEndurance'] as num?)?.toInt() ?? 75,
      bikeHandling: (json['bikeHandling'] as num?)?.toInt() ?? 80,
      downhillConfidence:
          (json['downhillConfidence'] as num?)?.toInt() ?? 80,
      lactateTolerance: (json['lactateTolerance'] as num?)?.toInt() ?? 78,
      uciRankingPoints: (json['uciRankingPoints'] as num?)?.toInt() ?? 0,
      isPilot: json['isPilot'] as bool? ?? false,
    );
  }
}

/// Dwuosobowa załoga tandemu Klasy B (widzący Pilot + niewidomy/słabowidzący Stoker).
class TandemCrewPairing {
  final String id;
  final ParacyclingAthleteProfile pilot;
  final ParacyclingAthleteProfile stoker;
  final double synchronizationIndex;
  final int communicationChemistry;
  final ParacyclingBikeSpec tandemBike;

  const TandemCrewPairing({
    required this.id,
    required this.pilot,
    required this.stoker,
    this.synchronizationIndex = 0.94,
    this.communicationChemistry = 88,
    required this.tandemBike,
  });

  /// Nazwa duetu prezentowana na listach startowych.
  String get crewDisplayName => '${pilot.name} / ${stoker.name}';

  /// Czy załoga spełnia wymogi formalne UCI dla Klasy B.
  bool get isUciValid =>
      pilot.isPilot &&
      !stoker.isPilot &&
      stoker.sportClass == ParacyclingSportClass.b &&
      tandemBike.equipmentType.isTandem;

  /// Mnożnik synchronizacji pedałowania (0.88–1.02) wynikający ze zgrania duetu.
  double get effectiveSyncMultiplier {
    final clampedSync = synchronizationIndex.clamp(0.0, 1.0);
    return 0.88 + (clampedSync * 0.14);
  }

  /// Łączna moc progowa tandemu [W] (u elity przekracza 800 W).
  double get combinedFtpWatts =>
      (pilot.ftpWatts + stoker.ftpWatts) * effectiveSyncMultiplier;

  /// Łączna moc szczytowa 5s tandemu [W] przy sprincie.
  double get combinedPeak5sWatts =>
      (pilot.peak5sWatts + stoker.peak5sWatts) *
      (0.90 + synchronizationIndex.clamp(0.0, 1.0) * 0.10);

  /// Całkowita masa układu (pilot + stoker + tandem) [kg].
  double get totalSystemWeightKg =>
      pilot.weightKg + stoker.weightKg + tandemBike.weightKg;

  /// Efektywny stosunek mocy do masy samej załogi [W/kg].
  double get effectiveWPerKg {
    final riderMass = pilot.weightKg + stoker.weightKg;
    return riderMass > 0 ? combinedFtpWatts / riderMass : 0.0;
  }

  /// Szacowana maksymalna prędkość zjazdowa tandemu [km/h] na stromym zjeździe (8–10%).
  /// Dzięki podwójnej masie przy relatywnie małym CdA elitarne tandemy przekraczają 95 km/h.
  double get projectedMaxDescentKmh {
    final massFactor = (totalSystemWeightKg / 145.0).clamp(0.85, 1.25);
    final aeroFactor = (0.325 / math.max(0.24, tandemBike.cdaM2)).clamp(0.85, 1.20);
    final confidenceFactor =
        ((pilot.downhillConfidence * 0.7 + stoker.downhillConfidence * 0.3) / 100.0)
            .clamp(0.75, 1.08);
    return (97.5 * massFactor * math.sqrt(aeroFactor) * confidenceFactor)
        .clamp(75.0, 112.0);
  }

  TandemCrewPairing copyWith({
    String? id,
    ParacyclingAthleteProfile? pilot,
    ParacyclingAthleteProfile? stoker,
    double? synchronizationIndex,
    int? communicationChemistry,
    ParacyclingBikeSpec? tandemBike,
  }) {
    return TandemCrewPairing(
      id: id ?? this.id,
      pilot: pilot ?? this.pilot,
      stoker: stoker ?? this.stoker,
      synchronizationIndex: synchronizationIndex ?? this.synchronizationIndex,
      communicationChemistry:
          communicationChemistry ?? this.communicationChemistry,
      tandemBike: tandemBike ?? this.tandemBike,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pilot': pilot.toJson(),
        'stoker': stoker.toJson(),
        'synchronizationIndex': synchronizationIndex,
        'communicationChemistry': communicationChemistry,
        'tandemBike': tandemBike.toJson(),
      };

  factory TandemCrewPairing.fromJson(Map<String, dynamic> json) {
    return TandemCrewPairing(
      id: json['id'] as String? ?? 'tandem_crew_default',
      pilot: ParacyclingAthleteProfile.fromJson(
        Map<String, dynamic>.from(json['pilot'] as Map? ?? {}),
      ),
      stoker: ParacyclingAthleteProfile.fromJson(
        Map<String, dynamic>.from(json['stoker'] as Map? ?? {}),
      ),
      synchronizationIndex:
          (json['synchronizationIndex'] as num?)?.toDouble() ?? 0.94,
      communicationChemistry:
          (json['communicationChemistry'] as num?)?.toInt() ?? 88,
      tandemBike: ParacyclingBikeSpec.fromJson(
        Map<String, dynamic>.from(json['tandemBike'] as Map? ?? {}),
      ),
    );
  }
}

/// Zgłoszenie trzyosobowej sztafety drużynowej Handbike (H1–H5) zgodnie z limitem punktów UCI.
class HandbikeTeamRelayEntry {
  final String id;
  final String teamName;
  final String nationalityCode;
  final List<ParacyclingAthleteProfile> riders;
  final int maxClassificationPoints;

  const HandbikeTeamRelayEntry({
    required this.id,
    required this.teamName,
    required this.nationalityCode,
    required this.riders,
    this.maxClassificationPoints = 11,
  });

  /// Suma punktów klasyfikacyjnych 3 zawodników (H1=1 .. H5=5).
  int get totalClassificationPoints => riders.fold<int>(
        0,
        (sum, r) => sum + r.sportClass.relayClassificationPoints,
      );

  /// Czy wszyscy zawodnicy należą do klas handbike (H1–H5) i mieszczą się w limicie UCI.
  bool get isRulesCompliant =>
      riders.length == 3 &&
      riders.every(
        (r) => r.sportClass.division == ParacyclingDivision.handbike,
      ) &&
      totalClassificationPoints <= maxClassificationPoints &&
      totalClassificationPoints > 0;

  /// Łączna moc progowa trójki sztafetowej [W].
  double get combinedRelayFtpWatts =>
      riders.fold<double>(0.0, (sum, r) => sum + r.ftpWatts);

  HandbikeTeamRelayEntry copyWith({
    String? id,
    String? teamName,
    String? nationalityCode,
    List<ParacyclingAthleteProfile>? riders,
    int? maxClassificationPoints,
  }) {
    return HandbikeTeamRelayEntry(
      id: id ?? this.id,
      teamName: teamName ?? this.teamName,
      nationalityCode: nationalityCode ?? this.nationalityCode,
      riders: riders ?? this.riders,
      maxClassificationPoints:
          maxClassificationPoints ?? this.maxClassificationPoints,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'teamName': teamName,
        'nationalityCode': nationalityCode,
        'riders': riders.map((r) => r.toJson()).toList(),
        'maxClassificationPoints': maxClassificationPoints,
      };

  factory HandbikeTeamRelayEntry.fromJson(Map<String, dynamic> json) {
    final rawRiders = json['riders'] as List<dynamic>? ?? const [];
    return HandbikeTeamRelayEntry(
      id: json['id'] as String? ?? 'relay_default',
      teamName: json['teamName'] as String? ?? 'Sztafeta Handbike',
      nationalityCode: json['nationalityCode'] as String? ?? 'POL',
      riders: rawRiders
          .map(
            (e) => ParacyclingAthleteProfile.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      maxClassificationPoints:
          (json['maxClassificationPoints'] as num?)?.toInt() ?? 11,
    );
  }
}

/// Wydarzenie wyścigowe w kalendarzu UCI Para-Cycling.
class ParacyclingRaceEvent {
  final String id;
  final String name;
  final String location;
  final String countryCode;
  final ParacyclingEventTier tier;
  final ParacyclingDiscipline discipline;
  final ParacyclingCourseProfile courseProfile;
  final double distanceKm;
  final int elevationGainM;
  final int laps;
  final List<ParacyclingSportClass> eligibleClasses;
  final String startDateIso;
  final int baseUciPoints;
  final double prizePoolEur;

  const ParacyclingRaceEvent({
    required this.id,
    required this.name,
    required this.location,
    required this.countryCode,
    required this.tier,
    required this.discipline,
    required this.courseProfile,
    required this.distanceKm,
    required this.elevationGainM,
    this.laps = 1,
    required this.eligibleClasses,
    required this.startDateIso,
    this.baseUciPoints = 100,
    this.prizePoolEur = 12000.0,
  });

  /// Maksymalna liczba punktów UCI za zwycięstwo z uwzględnieniem rangi zawodów.
  int get winnerUciPoints =>
      (baseUciPoints * tier.pointsMultiplier).round();

  ParacyclingRaceEvent copyWith({
    String? id,
    String? name,
    String? location,
    String? countryCode,
    ParacyclingEventTier? tier,
    ParacyclingDiscipline? discipline,
    ParacyclingCourseProfile? courseProfile,
    double? distanceKm,
    int? elevationGainM,
    int? laps,
    List<ParacyclingSportClass>? eligibleClasses,
    String? startDateIso,
    int? baseUciPoints,
    double? prizePoolEur,
  }) {
    return ParacyclingRaceEvent(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      countryCode: countryCode ?? this.countryCode,
      tier: tier ?? this.tier,
      discipline: discipline ?? this.discipline,
      courseProfile: courseProfile ?? this.courseProfile,
      distanceKm: distanceKm ?? this.distanceKm,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      laps: laps ?? this.laps,
      eligibleClasses: eligibleClasses ?? this.eligibleClasses,
      startDateIso: startDateIso ?? this.startDateIso,
      baseUciPoints: baseUciPoints ?? this.baseUciPoints,
      prizePoolEur: prizePoolEur ?? this.prizePoolEur,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'countryCode': countryCode,
        'tier': tier.toJson(),
        'discipline': discipline.toJson(),
        'courseProfile': courseProfile.toJson(),
        'distanceKm': distanceKm,
        'elevationGainM': elevationGainM,
        'laps': laps,
        'eligibleClasses': eligibleClasses.map((c) => c.toJson()).toList(),
        'startDateIso': startDateIso,
        'baseUciPoints': baseUciPoints,
        'prizePoolEur': prizePoolEur,
      };

  factory ParacyclingRaceEvent.fromJson(Map<String, dynamic> json) {
    final rawClasses = json['eligibleClasses'] as List<dynamic>? ?? const [];
    return ParacyclingRaceEvent(
      id: json['id'] as String? ?? 'event_default',
      name: json['name'] as String? ?? 'Wyścig UCI Para-Cycling',
      location: json['location'] as String? ?? 'Ostend',
      countryCode: json['countryCode'] as String? ?? 'BEL',
      tier: ParacyclingEventTier.fromJson(
        json['tier'] as String? ?? 'uciWorldCup',
      ),
      discipline: ParacyclingDiscipline.fromJson(
        json['discipline'] as String? ?? 'roadRace',
      ),
      courseProfile: ParacyclingCourseProfile.fromJson(
        json['courseProfile'] as String? ?? 'rolling',
      ),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 62.0,
      elevationGainM: (json['elevationGainM'] as num?)?.toInt() ?? 420,
      laps: (json['laps'] as num?)?.toInt() ?? 4,
      eligibleClasses: rawClasses
          .map((e) => ParacyclingSportClass.fromJson(e as String))
          .toList(),
      startDateIso: json['startDateIso'] as String? ?? '2026-05-14',
      baseUciPoints: (json['baseUciPoints'] as num?)?.toInt() ?? 100,
      prizePoolEur: (json['prizePoolEur'] as num?)?.toDouble() ?? 12000.0,
    );
  }
}

/// Wynik pojedynczego startu w zawodach UCI Para-Cycling.
class ParacyclingRaceResult {
  final String eventId;
  final String competitorId;
  final String displayName;
  final ParacyclingSportClass sportClass;
  final double finishTimeSeconds;
  final int rank;
  final int uciPointsEarned;
  final double averagePowerWatts;
  final double maxSpeedKmh;
  final ParacyclingMedalType medalEarned;

  const ParacyclingRaceResult({
    required this.eventId,
    required this.competitorId,
    required this.displayName,
    required this.sportClass,
    required this.finishTimeSeconds,
    required this.rank,
    required this.uciPointsEarned,
    required this.averagePowerWatts,
    required this.maxSpeedKmh,
    this.medalEarned = ParacyclingMedalType.none,
  });

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'competitorId': competitorId,
        'displayName': displayName,
        'sportClass': sportClass.toJson(),
        'finishTimeSeconds': finishTimeSeconds,
        'rank': rank,
        'uciPointsEarned': uciPointsEarned,
        'averagePowerWatts': averagePowerWatts,
        'maxSpeedKmh': maxSpeedKmh,
        'medalEarned': medalEarned.toJson(),
      };

  factory ParacyclingRaceResult.fromJson(Map<String, dynamic> json) {
    return ParacyclingRaceResult(
      eventId: json['eventId'] as String? ?? '',
      competitorId: json['competitorId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      sportClass: ParacyclingSportClass.fromJson(
        json['sportClass'] as String? ?? 'c5',
      ),
      finishTimeSeconds:
          (json['finishTimeSeconds'] as num?)?.toDouble() ?? 0.0,
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      uciPointsEarned: (json['uciPointsEarned'] as num?)?.toInt() ?? 0,
      averagePowerWatts:
          (json['averagePowerWatts'] as num?)?.toDouble() ?? 0.0,
      maxSpeedKmh: (json['maxSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      medalEarned: ParacyclingMedalType.fromJson(
        json['medalEarned'] as String? ?? 'none',
      ),
    );
  }
}

/// Pozycja w klasyfikacji generalnej Pucharu Świata UCI Para-Cycling.
class ParacyclingStandingsEntry {
  final String competitorId;
  final String displayName;
  final ParacyclingSportClass sportClass;
  final int totalPoints;
  final int startsCount;
  final int podiumsCount;

  const ParacyclingStandingsEntry({
    required this.competitorId,
    required this.displayName,
    required this.sportClass,
    required this.totalPoints,
    required this.startsCount,
    required this.podiumsCount,
  });
}

/// Raport gotowości kadrowej i sprzętowej dla danej klasy sportowej UCI.
class ParacyclingReadinessReport {
  final ParacyclingSportClass sportClass;
  final int eligibleCompetitorsCount;
  final int compatibleBikesCount;
  final double averageFtpWatts;
  final bool isReadyForCompetition;
  final String summaryPl;

  const ParacyclingReadinessReport({
    required this.sportClass,
    required this.eligibleCompetitorsCount,
    required this.compatibleBikesCount,
    required this.averageFtpWatts,
    required this.isReadyForCompetition,
    required this.summaryPl,
  });
}

/// Główny model świata UCI Para-Cycling:
/// - Tandemy Klasy B (Pilot + Stoker, łączna moc >800 W)
/// - Handbike H1–H5 (leżące H1–H4 i klęczące H5 + sztafeta drużynowa)
/// - Rowery jednośladowe C1–C5
class UciParacyclingTandemHandbikeModel {
  final int seasonYear;
  final String teamName;
  final List<ParacyclingAthleteProfile> athletes;
  final List<TandemCrewPairing> tandemCrews;
  final List<ParacyclingBikeSpec> bikes;
  final List<ParacyclingRaceEvent> events;
  final List<HandbikeTeamRelayEntry> relayEntries;
  final List<ParacyclingRaceResult> results;

  const UciParacyclingTandemHandbikeModel({
    required this.seasonYear,
    required this.teamName,
    required this.athletes,
    required this.tandemCrews,
    required this.bikes,
    required this.events,
    required this.relayEntries,
    this.results = const [],
  });

  /// Zwraca zawodników przypisanych do wskazanej klasy sportowej (bez pilotów).
  List<ParacyclingAthleteProfile> athletesInClass(
    ParacyclingSportClass sportClass,
  ) {
    return athletes
        .where((a) => !a.isPilot && a.sportClass == sportClass)
        .toList();
  }

  /// Zwraca listę widzących pilotów dostępnych dla tandemów Klasy B.
  List<ParacyclingAthleteProfile> get availablePilots =>
      athletes.where((a) => a.isPilot).toList();

  /// Zwraca rowery kompatybilne z wybraną klasą sportową UCI.
  List<ParacyclingBikeSpec> compatibleBikesForClass(
    ParacyclingSportClass sportClass,
  ) {
    return bikes.where((b) => b.isCompatibleWithClass(sportClass)).toList();
  }

  /// Wylicza klasyfikację generalną Pucharu Świata (opcjonalnie filtrowaną po klasie).
  List<ParacyclingStandingsEntry> computeWorldCupStandings({
    ParacyclingSportClass? filterClass,
  }) {
    final Map<String, List<ParacyclingRaceResult>> grouped = {};
    for (final result in results) {
      if (filterClass != null && result.sportClass != filterClass) {
        continue;
      }
      grouped.putIfAbsent(result.competitorId, () => []).add(result);
    }

    final entries = grouped.entries.map((entry) {
      final list = entry.value;
      final first = list.first;
      final totalPts =
          list.fold<int>(0, (sum, r) => sum + r.uciPointsEarned);
      final podiums = list.where((r) => r.rank >= 1 && r.rank <= 3).length;
      return ParacyclingStandingsEntry(
        competitorId: entry.key,
        displayName: first.displayName,
        sportClass: first.sportClass,
        totalPoints: totalPts,
        startsCount: list.length,
        podiumsCount: podiums,
      );
    }).toList();

    entries.sort((a, b) {
      final ptsCmp = b.totalPoints.compareTo(a.totalPoints);
      if (ptsCmp != 0) return ptsCmp;
      return b.podiumsCount.compareTo(a.podiumsCount);
    });
    return entries;
  }

  /// Ocenia gotowość kadrową i sprzętową dla wybranej klasy UCI Para-Cycling.
  ParacyclingReadinessReport evaluateClassReadiness(
    ParacyclingSportClass sportClass,
  ) {
    final compatibleBikes = compatibleBikesForClass(sportClass);
    if (sportClass == ParacyclingSportClass.b) {
      final validCrews = tandemCrews.where((c) => c.isUciValid).toList();
      final avgFtp = validCrews.isEmpty
          ? 0.0
          : validCrews.fold<double>(
                0.0,
                (sum, c) => sum + c.combinedFtpWatts,
              ) /
              validCrews.length;
      final ready = validCrews.isNotEmpty && compatibleBikes.isNotEmpty;
      return ParacyclingReadinessReport(
        sportClass: sportClass,
        eligibleCompetitorsCount: validCrews.length,
        compatibleBikesCount: compatibleBikes.length,
        averageFtpWatts: avgFtp,
        isReadyForCompetition: ready,
        summaryPl: ready
            ? 'Gotowość Tandem B: ${validCrews.length} par(y), śr. ${avgFtp.round()} W.'
            : 'Brak pełnej załogi Tandem B lub kompatybilnego tandemu.',
      );
    }

    final classAthletes = athletesInClass(sportClass);
    final avgFtp = classAthletes.isEmpty
        ? 0.0
        : classAthletes.fold<double>(0.0, (sum, a) => sum + a.ftpWatts) /
            classAthletes.length;
    final ready = classAthletes.isNotEmpty && compatibleBikes.isNotEmpty;
    return ParacyclingReadinessReport(
      sportClass: sportClass,
      eligibleCompetitorsCount: classAthletes.length,
      compatibleBikesCount: compatibleBikes.length,
      averageFtpWatts: avgFtp,
      isReadyForCompetition: ready,
      summaryPl: ready
          ? 'Gotowość ${sportClass.code}: ${classAthletes.length} zaw., śr. ${avgFtp.round()} W.'
          : 'Brak zawodników lub sprzętu dla klasy ${sportClass.code}.',
    );
  }

  /// Dodaje nowy wynik wyścigu i zwraca zaktualizowany model.
  UciParacyclingTandemHandbikeModel recordResult(
    ParacyclingRaceResult result,
  ) {
    return copyWith(results: [...results, result]);
  }

  UciParacyclingTandemHandbikeModel copyWith({
    int? seasonYear,
    String? teamName,
    List<ParacyclingAthleteProfile>? athletes,
    List<TandemCrewPairing>? tandemCrews,
    List<ParacyclingBikeSpec>? bikes,
    List<ParacyclingRaceEvent>? events,
    List<HandbikeTeamRelayEntry>? relayEntries,
    List<ParacyclingRaceResult>? results,
  }) {
    return UciParacyclingTandemHandbikeModel(
      seasonYear: seasonYear ?? this.seasonYear,
      teamName: teamName ?? this.teamName,
      athletes: athletes ?? this.athletes,
      tandemCrews: tandemCrews ?? this.tandemCrews,
      bikes: bikes ?? this.bikes,
      events: events ?? this.events,
      relayEntries: relayEntries ?? this.relayEntries,
      results: results ?? this.results,
    );
  }

  Map<String, dynamic> toJson() => {
        'seasonYear': seasonYear,
        'teamName': teamName,
        'athletes': athletes.map((a) => a.toJson()).toList(),
        'tandemCrews': tandemCrews.map((c) => c.toJson()).toList(),
        'bikes': bikes.map((b) => b.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
        'relayEntries': relayEntries.map((r) => r.toJson()).toList(),
        'results': results.map((res) => res.toJson()).toList(),
      };

  factory UciParacyclingTandemHandbikeModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawAthletes = json['athletes'] as List<dynamic>? ?? const [];
    final rawCrews = json['tandemCrews'] as List<dynamic>? ?? const [];
    final rawBikes = json['bikes'] as List<dynamic>? ?? const [];
    final rawEvents = json['events'] as List<dynamic>? ?? const [];
    final rawRelays = json['relayEntries'] as List<dynamic>? ?? const [];
    final rawResults = json['results'] as List<dynamic>? ?? const [];

    return UciParacyclingTandemHandbikeModel(
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      teamName: json['teamName'] as String? ?? 'Kadra Narodowa Para-Cycling',
      athletes: rawAthletes
          .map(
            (e) => ParacyclingAthleteProfile.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      tandemCrews: rawCrews
          .map(
            (e) => TandemCrewPairing.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      bikes: rawBikes
          .map(
            (e) => ParacyclingBikeSpec.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      events: rawEvents
          .map(
            (e) => ParacyclingRaceEvent.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      relayEntries: rawRelays
          .map(
            (e) => HandbikeTeamRelayEntry.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      results: rawResults
          .map(
            (e) => ParacyclingRaceResult.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  /// Tworzy domyślny sezon Pucharu Świata UCI Para-Cycling z pełnym przekrojem klas B, H1–H5 i C1–C5.
  factory UciParacyclingTandemHandbikeModel.createDefaultWorldCupSeason({
    int seasonYear = 2026,
    String teamName = 'Polska Reprezentacja Para-Cycling',
  }) {
    final fleet = ParacyclingBikeSpec.defaultFleet();
    final tandemRoad = fleet.firstWhere(
      (b) => b.equipmentType == ParacyclingEquipmentType.tandemRoadBike,
    );

    const pilotMen = ParacyclingAthleteProfile(
      id: 'para_pilot_m_1',
      name: 'Kacper Kowalski',
      nationalityCode: 'POL',
      age: 27,
      sportClass: ParacyclingSportClass.b,
      gender: ParacyclingGenderCategory.men,
      ftpWatts: 435,
      peak5sWatts: 1290,
      vo2Max: 77.5,
      weightKg: 74.0,
      bikeHandling: 92,
      downhillConfidence: 94,
      lactateTolerance: 86,
      uciRankingPoints: 410,
      isPilot: true,
    );

    const stokerMen = ParacyclingAthleteProfile(
      id: 'para_stoker_m_1',
      name: 'Michał Nowak',
      nationalityCode: 'POL',
      age: 29,
      sportClass: ParacyclingSportClass.b,
      gender: ParacyclingGenderCategory.men,
      ftpWatts: 425,
      peak5sWatts: 1210,
      vo2Max: 76.0,
      weightKg: 73.0,
      bikeHandling: 82,
      downhillConfidence: 84,
      lactateTolerance: 89,
      uciRankingPoints: 410,
    );

    const handbikeH2 = ParacyclingAthleteProfile(
      id: 'para_h2_1',
      name: 'Tomasz Zieliński',
      nationalityCode: 'POL',
      age: 31,
      sportClass: ParacyclingSportClass.h2,
      gender: ParacyclingGenderCategory.men,
      ftpWatts: 185,
      peak5sWatts: 490,
      vo2Max: 56.0,
      weightKg: 66.0,
      upperBodyEndurance: 88,
      bikeHandling: 84,
      downhillConfidence: 85,
      uciRankingPoints: 260,
    );

    const handbikeH3 = ParacyclingAthleteProfile(
      id: 'para_h3_1',
      name: 'Rafał Wilk',
      nationalityCode: 'POL',
      age: 34,
      sportClass: ParacyclingSportClass.h3,
      gender: ParacyclingGenderCategory.men,
      ftpWatts: 235,
      peak5sWatts: 620,
      vo2Max: 61.5,
      weightKg: 69.0,
      upperBodyEndurance: 93,
      bikeHandling: 89,
      downhillConfidence: 90,
      uciRankingPoints: 390,
    );

    const handbikeH4 = ParacyclingAthleteProfile(
      id: 'para_h4_1',
      name: 'Krystian Mazur',
      nationalityCode: 'POL',
      age: 30,
      sportClass: ParacyclingSportClass.h4,
      gender: ParacyclingGenderCategory.men,
      ftpWatts: 255,
      peak5sWatts: 680,
      vo2Max: 63.0,
      weightKg: 71.0,
      upperBodyEndurance: 91,
      bikeHandling: 87,
      downhillConfidence: 88,
      uciRankingPoints: 340,
    );

    const handbikeH5 = ParacyclingAthleteProfile(
      id: 'para_h5_1',
      name: 'Anna Kamińska',
      nationalityCode: 'POL',
      age: 26,
      sportClass: ParacyclingSportClass.h5,
      gender: ParacyclingGenderCategory.women,
      ftpWatts: 215,
      peak5sWatts: 570,
      vo2Max: 60.0,
      weightKg: 61.0,
      upperBodyEndurance: 90,
      bikeHandling: 88,
      downhillConfidence: 86,
      uciRankingPoints: 355,
    );

    const soloC2 = ParacyclingAthleteProfile(
      id: 'para_c2_1',
      name: 'Jakub Wiśniewski',
      nationalityCode: 'POL',
      age: 25,
      sportClass: ParacyclingSportClass.c2,
      gender: ParacyclingGenderCategory.men,
      ftpWatts: 275,
      peak5sWatts: 820,
      vo2Max: 67.0,
      weightKg: 64.0,
      bikeHandling: 86,
      downhillConfidence: 83,
      uciRankingPoints: 310,
    );

    const soloC4 = ParacyclingAthleteProfile(
      id: 'para_c4_1',
      name: 'Patryk Lewandowski',
      nationalityCode: 'POL',
      age: 28,
      sportClass: ParacyclingSportClass.c4,
      gender: ParacyclingGenderCategory.men,
      ftpWatts: 345,
      peak5sWatts: 1050,
      vo2Max: 72.5,
      weightKg: 68.5,
      bikeHandling: 90,
      downhillConfidence: 89,
      uciRankingPoints: 375,
    );

    const soloC5 = ParacyclingAthleteProfile(
      id: 'para_c5_1',
      name: 'Marta Wójcik',
      nationalityCode: 'POL',
      age: 24,
      sportClass: ParacyclingSportClass.c5,
      gender: ParacyclingGenderCategory.women,
      ftpWatts: 285,
      peak5sWatts: 890,
      vo2Max: 69.0,
      weightKg: 58.0,
      bikeHandling: 89,
      downhillConfidence: 87,
      uciRankingPoints: 380,
    );

    final tandemCrew = TandemCrewPairing(
      id: 'crew_pol_b_1',
      pilot: pilotMen,
      stoker: stokerMen,
      synchronizationIndex: 0.96,
      communicationChemistry: 94,
      tandemBike: tandemRoad,
    );

    const relayTeam = HandbikeTeamRelayEntry(
      id: 'relay_pol_h_1',
      teamName: 'Polska Sztafeta H2–H3–H5',
      nationalityCode: 'POL',
      riders: [handbikeH2, handbikeH3, handbikeH5],
      maxClassificationPoints: 11,
    );

    final calendarEvents = [
      ParacyclingRaceEvent(
        id: 'wc_ostend_itt',
        name: 'UCI Para-Cycling World Cup — Ostend ITT',
        location: 'Ostend',
        countryCode: 'BEL',
        tier: ParacyclingEventTier.uciWorldCup,
        discipline: ParacyclingDiscipline.individualTimeTrial,
        courseProfile: ParacyclingCourseProfile.flat,
        distanceKm: 28.4,
        elevationGainM: 85,
        laps: 2,
        eligibleClasses: ParacyclingSportClass.values,
        startDateIso: '$seasonYear-05-02',
        baseUciPoints: 100,
      ),
      ParacyclingRaceEvent(
        id: 'wc_maniago_rr',
        name: 'UCI Para-Cycling World Cup — Maniago Road Race',
        location: 'Maniago',
        countryCode: 'ITA',
        tier: ParacyclingEventTier.uciWorldCup,
        discipline: ParacyclingDiscipline.roadRace,
        courseProfile: ParacyclingCourseProfile.hilly,
        distanceKm: 98.0,
        elevationGainM: 1420,
        laps: 7,
        eligibleClasses: ParacyclingSportClass.values,
        startDateIso: '$seasonYear-05-18',
        baseUciPoints: 110,
      ),
      ParacyclingRaceEvent(
        id: 'wc_huntsville_relay',
        name: 'UCI Para-Cycling World Cup — Huntsville Team Relay',
        location: 'Huntsville',
        countryCode: 'USA',
        tier: ParacyclingEventTier.uciWorldCup,
        discipline: ParacyclingDiscipline.teamRelay,
        courseProfile: ParacyclingCourseProfile.technicalCircuit,
        distanceKm: 18.0,
        elevationGainM: 160,
        laps: 9,
        eligibleClasses: const [
          ParacyclingSportClass.h1,
          ParacyclingSportClass.h2,
          ParacyclingSportClass.h3,
          ParacyclingSportClass.h4,
          ParacyclingSportClass.h5,
        ],
        startDateIso: '$seasonYear-06-08',
        baseUciPoints: 120,
      ),
      ParacyclingRaceEvent(
        id: 'paralympics_road_final',
        name: 'Igrzyska Paralimpijskie — Wyścig Szosowy',
        location: 'Paryż / Clichy-sous-Bois',
        countryCode: 'FRA',
        tier: ParacyclingEventTier.paralympicGames,
        discipline: ParacyclingDiscipline.roadRace,
        courseProfile: ParacyclingCourseProfile.rolling,
        distanceKm: 112.0,
        elevationGainM: 1280,
        laps: 8,
        eligibleClasses: ParacyclingSportClass.values,
        startDateIso: '$seasonYear-09-05',
        baseUciPoints: 200,
        prizePoolEur: 45000.0,
      ),
    ];

    return UciParacyclingTandemHandbikeModel(
      seasonYear: seasonYear,
      teamName: teamName,
      athletes: const [
        pilotMen,
        stokerMen,
        handbikeH2,
        handbikeH3,
        handbikeH4,
        handbikeH5,
        soloC2,
        soloC4,
        soloC5,
      ],
      tandemCrews: [tandemCrew],
      bikes: fleet,
      events: calendarEvents,
      relayEntries: [relayTeam],
    );
  }
}
