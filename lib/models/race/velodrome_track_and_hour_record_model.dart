import 'dart:math' as math;

/// Kategoria wiekowa / płciowa Rekordu Godzinnego UCI.
enum UciHourRecordCategory {
  menElite,
  womenElite;

  String toJson() => name;

  static UciHourRecordCategory fromJson(String value) {
    return UciHourRecordCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UciHourRecordCategory.menElite,
    );
  }

  /// Czytelna nazwa kategorii po polsku.
  String get displayNamePl {
    switch (this) {
      case UciHourRecordCategory.menElite:
        return 'Elita Mężczyzn';
      case UciHourRecordCategory.womenElite:
        return 'Elita Kobiet';
    }
  }
}

/// Gatunek drewna stosowany na nawierzchni krytych welodromów UCI.
enum VelodromeWoodSurface {
  siberianPine,
  siberianSpruce,
  balticBirch,
  accoyaTreatedPine;

  String toJson() => name;

  static VelodromeWoodSurface fromJson(String value) {
    return VelodromeWoodSurface.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => VelodromeWoodSurface.siberianPine,
    );
  }

  /// Bazowy współczynnik oporu toczenia (CRR) dla szytki torowej na gładkim drewnie.
  double get baseRollingResistanceCrr {
    switch (this) {
      case VelodromeWoodSurface.siberianPine:
        return 0.0018;
      case VelodromeWoodSurface.siberianSpruce:
        return 0.00175;
      case VelodromeWoodSurface.balticBirch:
        return 0.0019;
      case VelodromeWoodSurface.accoyaTreatedPine:
        return 0.00172;
    }
  }

  /// Nazwa nawierzchni drewnianej po polsku.
  String get displayNamePl {
    switch (this) {
      case VelodromeWoodSurface.siberianPine:
        return 'Sosna syberyjska';
      case VelodromeWoodSurface.siberianSpruce:
        return 'Świerk syberyjski';
      case VelodromeWoodSurface.balticBirch:
        return 'Brzoza bałtycka';
      case VelodromeWoodSurface.accoyaTreatedPine:
        return 'Drewno Accoya';
    }
  }
}

/// Klasyfikacja wysokościowa welodromu wpływająca na gęstość powietrza i hipoksję.
enum VelodromeAltitudeTier {
  seaLevel,
  lowland,
  moderateAltitude,
  highAltitude;

  String toJson() => name;

  static VelodromeAltitudeTier fromJson(String value) {
    return VelodromeAltitudeTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => VelodromeAltitudeTier.lowland,
    );
  }

  /// Określa klasę wysokościową na podstawie wysokości n.p.m. [m].
  static VelodromeAltitudeTier fromAltitudeMeters(double altitudeMeters) {
    if (altitudeMeters < 150.0) return VelodromeAltitudeTier.seaLevel;
    if (altitudeMeters < 700.0) return VelodromeAltitudeTier.lowland;
    if (altitudeMeters < 1400.0) return VelodromeAltitudeTier.moderateAltitude;
    return VelodromeAltitudeTier.highAltitude;
  }

  /// Czytelna etykieta wysokościowa po polsku.
  String get displayNamePl {
    switch (this) {
      case VelodromeAltitudeTier.seaLevel:
        return 'Poziom morza';
      case VelodromeAltitudeTier.lowland:
        return 'Nizinny';
      case VelodromeAltitudeTier.moderateAltitude:
        return 'Umiarkowana wysokość';
      case VelodromeAltitudeTier.highAltitude:
        return 'Wysokogórski';
    }
  }
}

/// Specyfikacja krytego drewnianego welodromu o standardowej długości 250 m.
class VelodromeFacilitySpec {
  static const double standardTrackLengthMeters = 250.0;
  static const double minUciBankingDegrees = 42.0;
  static const double maxUciBankingDegrees = 45.0;

  final String id;
  final String name;
  final String city;
  final String countryCode;
  final double trackLengthMeters;
  final double turnBankingDegrees;
  final double straightBankingDegrees;
  final double altitudeMeters;
  final VelodromeWoodSurface woodSurface;
  final bool isIndoor;
  final double indoorTemperatureCelsius;
  final double relativeHumidityPercent;
  final double seaLevelPressureHpa;
  final double turnRadiusMeters;

  const VelodromeFacilitySpec({
    required this.id,
    required this.name,
    required this.city,
    required this.countryCode,
    this.trackLengthMeters = standardTrackLengthMeters,
    this.turnBankingDegrees = 43.0,
    this.straightBankingDegrees = 13.0,
    required this.altitudeMeters,
    this.woodSurface = VelodromeWoodSurface.siberianPine,
    this.isIndoor = true,
    this.indoorTemperatureCelsius = 26.0,
    this.relativeHumidityPercent = 45.0,
    this.seaLevelPressureHpa = 1013.25,
    this.turnRadiusMeters = 23.0,
  });

  /// Czy tor spełnia standard krytego drewnianego welodromu 250 m z wirażami 42°–45°.
  bool get isStandard250mHourRecordTrack {
    return isIndoor &&
        (trackLengthMeters - standardTrackLengthMeters).abs() < 0.1 &&
        turnBankingDegrees >= minUciBankingDegrees &&
        turnBankingDegrees <= maxUciBankingDegrees;
  }

  /// Klasa wysokościowa obiektu.
  VelodromeAltitudeTier get altitudeTier =>
      VelodromeAltitudeTier.fromAltitudeMeters(altitudeMeters);

  /// Liczba okrążeń potrzebna do pokonania zadanego dystansu w kilometrach.
  double lapsForDistanceKm(double distanceKm) {
    if (trackLengthMeters <= 0 || distanceKm <= 0) return 0.0;
    return (distanceKm * 1000.0) / trackLengthMeters;
  }

  /// Szacowane ciśnienie atmosferyczne na wysokości welodromu [hPa] (wzór barometryczny).
  double get localBarometricPressureHpa {
    final double h = math.max(0.0, altitudeMeters);
    return seaLevelPressureHpa * math.pow(1.0 - 2.25577e-5 * h, 5.25588);
  }

  /// Gęstość powietrza na torze [kg/m³] z uwzględnieniem wysokości, temperatury i wilgotności.
  double get airDensityKgPerM3 {
    final double tempK = indoorTemperatureCelsius + 273.15;
    final double pTotalPa = localBarometricPressureHpa * 100.0;
    // Ciśnienie nasycenia pary wodnej (Magnus-Tetens) [Pa].
    final double esPa = 610.78 *
        math.exp(
          (17.27 * indoorTemperatureCelsius) /
              (indoorTemperatureCelsius + 237.3),
        );
    final double pvPa =
        (relativeHumidityPercent.clamp(0.0, 100.0) / 100.0) * esPa;
    final double pdPa = math.max(0.0, pTotalPa - pvPa);
    const double rDry = 287.058;
    const double rVapor = 461.495;
    return (pdPa / (rDry * tempK)) + (pvPa / (rVapor * tempK));
  }

  /// Procentowa redukcja oporu aerodynamicznego względem poziomu morza (1.225 kg/m³).
  double get aeroDragReductionPercentVsSeaLevel {
    const double seaLevelRho = 1.225;
    return ((seaLevelRho - airDensityKgPerM3) / seaLevelRho) * 100.0;
  }

  /// Współczynnik spadku wydolności tlenowej (VO2max / FTP) wynikający z hipoksji na wysokości.
  /// Poniżej 600 m n.p.m. wpływ jest pomijalny; powyżej rośnie nieliniowo.
  double get hypoxiaPowerPenaltyFactor {
    if (altitudeMeters <= 600.0) return 1.0;
    final double excessHundreds = (altitudeMeters - 600.0) / 100.0;
    final double penalty = 0.0052 * math.pow(excessHundreds, 1.15);
    return (1.0 - penalty).clamp(0.70, 1.0);
  }

  /// Efektywny współczynnik obciążenia grawitacyjno-odśrodkowego na wirażu o zadanym nachyleniu.
  double bankingNormalLoadFactor(double speedMetersPerSecond) {
    final double radius = math.max(15.0, turnRadiusMeters);
    final double lateralAccel =
        (speedMetersPerSecond * speedMetersPerSecond) / radius;
    const double g = 9.80665;
    final double bankRad = turnBankingDegrees * (math.pi / 180.0);
    return math.cos(bankRad) + (lateralAccel / g) * math.sin(bankRad);
  }

  VelodromeFacilitySpec copyWith({
    String? id,
    String? name,
    String? city,
    String? countryCode,
    double? trackLengthMeters,
    double? turnBankingDegrees,
    double? straightBankingDegrees,
    double? altitudeMeters,
    VelodromeWoodSurface? woodSurface,
    bool? isIndoor,
    double? indoorTemperatureCelsius,
    double? relativeHumidityPercent,
    double? seaLevelPressureHpa,
    double? turnRadiusMeters,
  }) {
    return VelodromeFacilitySpec(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      countryCode: countryCode ?? this.countryCode,
      trackLengthMeters: trackLengthMeters ?? this.trackLengthMeters,
      turnBankingDegrees: turnBankingDegrees ?? this.turnBankingDegrees,
      straightBankingDegrees:
          straightBankingDegrees ?? this.straightBankingDegrees,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      woodSurface: woodSurface ?? this.woodSurface,
      isIndoor: isIndoor ?? this.isIndoor,
      indoorTemperatureCelsius:
          indoorTemperatureCelsius ?? this.indoorTemperatureCelsius,
      relativeHumidityPercent:
          relativeHumidityPercent ?? this.relativeHumidityPercent,
      seaLevelPressureHpa: seaLevelPressureHpa ?? this.seaLevelPressureHpa,
      turnRadiusMeters: turnRadiusMeters ?? this.turnRadiusMeters,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'countryCode': countryCode,
      'trackLengthMeters': trackLengthMeters,
      'turnBankingDegrees': turnBankingDegrees,
      'straightBankingDegrees': straightBankingDegrees,
      'altitudeMeters': altitudeMeters,
      'woodSurface': woodSurface.toJson(),
      'isIndoor': isIndoor,
      'indoorTemperatureCelsius': indoorTemperatureCelsius,
      'relativeHumidityPercent': relativeHumidityPercent,
      'seaLevelPressureHpa': seaLevelPressureHpa,
      'turnRadiusMeters': turnRadiusMeters,
    };
  }

  factory VelodromeFacilitySpec.fromJson(Map<String, dynamic> json) {
    return VelodromeFacilitySpec(
      id: json['id'] as String? ?? 'unknown_velodrome',
      name: json['name'] as String? ?? 'Velodrome',
      city: json['city'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? 'INT',
      trackLengthMeters:
          (json['trackLengthMeters'] as num?)?.toDouble() ?? 250.0,
      turnBankingDegrees:
          (json['turnBankingDegrees'] as num?)?.toDouble() ?? 43.0,
      straightBankingDegrees:
          (json['straightBankingDegrees'] as num?)?.toDouble() ?? 13.0,
      altitudeMeters: (json['altitudeMeters'] as num?)?.toDouble() ?? 0.0,
      woodSurface: VelodromeWoodSurface.fromJson(
        json['woodSurface'] as String? ?? 'siberianPine',
      ),
      isIndoor: json['isIndoor'] as bool? ?? true,
      indoorTemperatureCelsius:
          (json['indoorTemperatureCelsius'] as num?)?.toDouble() ?? 26.0,
      relativeHumidityPercent:
          (json['relativeHumidityPercent'] as num?)?.toDouble() ?? 45.0,
      seaLevelPressureHpa:
          (json['seaLevelPressureHpa'] as num?)?.toDouble() ?? 1013.25,
      turnRadiusMeters:
          (json['turnRadiusMeters'] as num?)?.toDouble() ?? 23.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VelodromeFacilitySpec &&
        other.id == id &&
        other.name == name &&
        other.city == city &&
        other.countryCode == countryCode &&
        other.trackLengthMeters == trackLengthMeters &&
        other.turnBankingDegrees == turnBankingDegrees &&
        other.straightBankingDegrees == straightBankingDegrees &&
        other.altitudeMeters == altitudeMeters &&
        other.woodSurface == woodSurface &&
        other.isIndoor == isIndoor &&
        other.indoorTemperatureCelsius == indoorTemperatureCelsius &&
        other.relativeHumidityPercent == relativeHumidityPercent &&
        other.seaLevelPressureHpa == seaLevelPressureHpa &&
        other.turnRadiusMeters == turnRadiusMeters;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        city,
        countryCode,
        trackLengthMeters,
        turnBankingDegrees,
        straightBankingDegrees,
        altitudeMeters,
        woodSurface,
        isIndoor,
        indoorTemperatureCelsius,
        relativeHumidityPercent,
        seaLevelPressureHpa,
        turnRadiusMeters,
      );
}

/// Rower torowy ostrokołowy (`Fixed Gear Track Bike`) bez hamulców i wolnobiegu.
/// Obsługuje tarcze 58T–64T oraz tylne zębatki 13T–15T.
class FixedGearTrackBike {
  static const int minChainringTeeth = 58;
  static const int maxChainringTeeth = 64;
  static const int minCogTeeth = 13;
  static const int maxCogTeeth = 15;
  static const double uciMinWeightKg = 6.8;
  static const double standardWheelCircumferenceMeters = 2.096;

  final String modelName;
  final String frameMaterial;
  final bool isFixedGear;
  final bool hasBrakes;
  final bool hasFreewheel;
  final int chainringTeeth;
  final int cogTeeth;
  final double bikeWeightKg;
  final double crankLengthMm;
  final double wheelCircumferenceMeters;
  final double cdaMetersSquared;
  final double drivetrainEfficiency;

  const FixedGearTrackBike({
    required this.modelName,
    this.frameMaterial = 'Carbon Monocoque 3D-Printed Aero',
    this.isFixedGear = true,
    this.hasBrakes = false,
    this.hasFreewheel = false,
    this.chainringTeeth = 62,
    this.cogTeeth = 14,
    this.bikeWeightKg = 7.1,
    this.crankLengthMm = 170.0,
    this.wheelCircumferenceMeters = standardWheelCircumferenceMeters,
    this.cdaMetersSquared = 0.178,
    this.drivetrainEfficiency = 0.985,
  })  : assert(chainringTeeth >= minChainringTeeth &&
            chainringTeeth <= maxChainringTeeth),
        assert(cogTeeth >= minCogTeeth && cogTeeth <= maxCogTeeth),
        assert(bikeWeightKg >= uciMinWeightKg),
        assert(isFixedGear && !hasBrakes && !hasFreewheel);

  /// Przełożenie napędu `i = tarcza / zębatka`.
  double get gearRatio => chainringTeeth / cogTeeth;

  /// Rozwinięcie na jeden obrót korby [m].
  double get developmentMeters => gearRatio * wheelCircumferenceMeters;

  /// Klasyczna miara torowa w calach (`Gear Inches`, koło ~27").
  double get gearInches => gearRatio * 27.0;

  /// Zapis tekstowy przełożenia, np. `64x14`.
  String get gearingLabel => '${chainringTeeth}x$cogTeeth';

  /// Czy konfiguracja spełnia przepisy UCI dla roweru torowego (ostre koło, brak hamulców, >= 6.8 kg).
  bool get isUciTrackLegal =>
      isFixedGear &&
      !hasBrakes &&
      !hasFreewheel &&
      bikeWeightKg >= uciMinWeightKg &&
      chainringTeeth >= minChainringTeeth &&
      chainringTeeth <= maxChainringTeeth &&
      cogTeeth >= minCogTeeth &&
      cogTeeth <= maxCogTeeth;

  /// Prędkość liniowa [km/h] dla zadanej kadencji [RPM] na ostrym kole.
  double speedKmhFromCadence(double cadenceRpm) {
    if (cadenceRpm <= 0) return 0.0;
    final double metersPerMinute = cadenceRpm * developmentMeters;
    return (metersPerMinute * 60.0) / 1000.0;
  }

  /// Kadencja [RPM] wymuszona przez ostre koło przy zadanej prędkości [km/h].
  double cadenceRpmFromSpeedKmh(double speedKmh) {
    if (speedKmh <= 0 || developmentMeters <= 0) return 0.0;
    final double metersPerMinute = (speedKmh * 1000.0) / 60.0;
    return metersPerMinute / developmentMeters;
  }

  FixedGearTrackBike copyWith({
    String? modelName,
    String? frameMaterial,
    int? chainringTeeth,
    int? cogTeeth,
    double? bikeWeightKg,
    double? crankLengthMm,
    double? wheelCircumferenceMeters,
    double? cdaMetersSquared,
    double? drivetrainEfficiency,
  }) {
    final int safeChainring = (chainringTeeth ?? this.chainringTeeth)
        .clamp(minChainringTeeth, maxChainringTeeth);
    final int safeCog =
        (cogTeeth ?? this.cogTeeth).clamp(minCogTeeth, maxCogTeeth);
    final double safeWeight =
        math.max(uciMinWeightKg, bikeWeightKg ?? this.bikeWeightKg);

    return FixedGearTrackBike(
      modelName: modelName ?? this.modelName,
      frameMaterial: frameMaterial ?? this.frameMaterial,
      isFixedGear: true,
      hasBrakes: false,
      hasFreewheel: false,
      chainringTeeth: safeChainring,
      cogTeeth: safeCog,
      bikeWeightKg: safeWeight,
      crankLengthMm: crankLengthMm ?? this.crankLengthMm,
      wheelCircumferenceMeters:
          wheelCircumferenceMeters ?? this.wheelCircumferenceMeters,
      cdaMetersSquared: cdaMetersSquared ?? this.cdaMetersSquared,
      drivetrainEfficiency: drivetrainEfficiency ?? this.drivetrainEfficiency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modelName': modelName,
      'frameMaterial': frameMaterial,
      'isFixedGear': isFixedGear,
      'hasBrakes': hasBrakes,
      'hasFreewheel': hasFreewheel,
      'chainringTeeth': chainringTeeth,
      'cogTeeth': cogTeeth,
      'bikeWeightKg': bikeWeightKg,
      'crankLengthMm': crankLengthMm,
      'wheelCircumferenceMeters': wheelCircumferenceMeters,
      'cdaMetersSquared': cdaMetersSquared,
      'drivetrainEfficiency': drivetrainEfficiency,
    };
  }

  factory FixedGearTrackBike.fromJson(Map<String, dynamic> json) {
    final int chainring = ((json['chainringTeeth'] as num?)?.toInt() ?? 62)
        .clamp(minChainringTeeth, maxChainringTeeth);
    final int cog = ((json['cogTeeth'] as num?)?.toInt() ?? 14)
        .clamp(minCogTeeth, maxCogTeeth);
    final double weight = math.max(
      uciMinWeightKg,
      (json['bikeWeightKg'] as num?)?.toDouble() ?? 7.1,
    );

    return FixedGearTrackBike(
      modelName: json['modelName'] as String? ?? 'Track Aero Prototype',
      frameMaterial: json['frameMaterial'] as String? ??
          'Carbon Monocoque 3D-Printed Aero',
      isFixedGear: true,
      hasBrakes: false,
      hasFreewheel: false,
      chainringTeeth: chainring,
      cogTeeth: cog,
      bikeWeightKg: weight,
      crankLengthMm: (json['crankLengthMm'] as num?)?.toDouble() ?? 170.0,
      wheelCircumferenceMeters:
          (json['wheelCircumferenceMeters'] as num?)?.toDouble() ??
              standardWheelCircumferenceMeters,
      cdaMetersSquared:
          (json['cdaMetersSquared'] as num?)?.toDouble() ?? 0.178,
      drivetrainEfficiency:
          (json['drivetrainEfficiency'] as num?)?.toDouble() ?? 0.985,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FixedGearTrackBike &&
        other.modelName == modelName &&
        other.frameMaterial == frameMaterial &&
        other.isFixedGear == isFixedGear &&
        other.hasBrakes == hasBrakes &&
        other.hasFreewheel == hasFreewheel &&
        other.chainringTeeth == chainringTeeth &&
        other.cogTeeth == cogTeeth &&
        other.bikeWeightKg == bikeWeightKg &&
        other.crankLengthMm == crankLengthMm &&
        other.wheelCircumferenceMeters == wheelCircumferenceMeters &&
        other.cdaMetersSquared == cdaMetersSquared &&
        other.drivetrainEfficiency == drivetrainEfficiency;
  }

  @override
  int get hashCode => Object.hash(
        modelName,
        frameMaterial,
        isFixedGear,
        hasBrakes,
        hasFreewheel,
        chainringTeeth,
        cogTeeth,
        bikeWeightKg,
        crankLengthMm,
        wheelCircumferenceMeters,
        cdaMetersSquared,
        drivetrainEfficiency,
      );
}

/// Wpis w historii Rekordu Godzinnego UCI (UCI Hour Record).
class UciHourRecordEntry {
  final String id;
  final String riderName;
  final String nationalityCode;
  final UciHourRecordCategory category;
  final double distanceKm;
  final String dateIso;
  final String velodromeId;
  final String velodromeName;
  final double altitudeMeters;
  final int chainringTeeth;
  final int cogTeeth;
  final bool isCurrentWorldRecord;
  final String notes;

  const UciHourRecordEntry({
    required this.id,
    required this.riderName,
    required this.nationalityCode,
    required this.category,
    required this.distanceKm,
    required this.dateIso,
    required this.velodromeId,
    required this.velodromeName,
    required this.altitudeMeters,
    required this.chainringTeeth,
    required this.cogTeeth,
    this.isCurrentWorldRecord = false,
    this.notes = '',
  });

  /// Średnia prędkość z 60 minut [km/h] (numerycznie równa dystansowi w km).
  double get averageSpeedKmh => distanceKm;

  /// Liczba pełnych i ułamkowych okrążeń na welodromie 250 m.
  double get lapsOn250mTrack =>
      (distanceKm * 1000.0) / VelodromeFacilitySpec.standardTrackLengthMeters;

  /// Średni czas pojedynczego okrążenia 250 m [s].
  double get averageLapTimeSeconds {
    final double laps = lapsOn250mTrack;
    if (laps <= 0) return 0.0;
    return 3600.0 / laps;
  }

  /// Zapis przełożenia użytego podczas próby, np. `64x14`.
  String get gearingLabel => '${chainringTeeth}x$cogTeeth';

  UciHourRecordEntry copyWith({
    String? id,
    String? riderName,
    String? nationalityCode,
    UciHourRecordCategory? category,
    double? distanceKm,
    String? dateIso,
    String? velodromeId,
    String? velodromeName,
    double? altitudeMeters,
    int? chainringTeeth,
    int? cogTeeth,
    bool? isCurrentWorldRecord,
    String? notes,
  }) {
    return UciHourRecordEntry(
      id: id ?? this.id,
      riderName: riderName ?? this.riderName,
      nationalityCode: nationalityCode ?? this.nationalityCode,
      category: category ?? this.category,
      distanceKm: distanceKm ?? this.distanceKm,
      dateIso: dateIso ?? this.dateIso,
      velodromeId: velodromeId ?? this.velodromeId,
      velodromeName: velodromeName ?? this.velodromeName,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      chainringTeeth: chainringTeeth ?? this.chainringTeeth,
      cogTeeth: cogTeeth ?? this.cogTeeth,
      isCurrentWorldRecord: isCurrentWorldRecord ?? this.isCurrentWorldRecord,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'riderName': riderName,
      'nationalityCode': nationalityCode,
      'category': category.toJson(),
      'distanceKm': distanceKm,
      'dateIso': dateIso,
      'velodromeId': velodromeId,
      'velodromeName': velodromeName,
      'altitudeMeters': altitudeMeters,
      'chainringTeeth': chainringTeeth,
      'cogTeeth': cogTeeth,
      'isCurrentWorldRecord': isCurrentWorldRecord,
      'notes': notes,
    };
  }

  factory UciHourRecordEntry.fromJson(Map<String, dynamic> json) {
    return UciHourRecordEntry(
      id: json['id'] as String? ?? 'unknown_record',
      riderName: json['riderName'] as String? ?? 'Unknown Rider',
      nationalityCode: json['nationalityCode'] as String? ?? 'INT',
      category: UciHourRecordCategory.fromJson(
        json['category'] as String? ?? 'menElite',
      ),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 50.0,
      dateIso: json['dateIso'] as String? ?? '2022-10-08',
      velodromeId: json['velodromeId'] as String? ?? 'grenchen_tissot',
      velodromeName:
          json['velodromeName'] as String? ?? 'Tissot Velodrome Grenchen',
      altitudeMeters: (json['altitudeMeters'] as num?)?.toDouble() ?? 450.0,
      chainringTeeth: (json['chainringTeeth'] as num?)?.toInt() ?? 62,
      cogTeeth: (json['cogTeeth'] as num?)?.toInt() ?? 14,
      isCurrentWorldRecord: json['isCurrentWorldRecord'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UciHourRecordEntry &&
        other.id == id &&
        other.riderName == riderName &&
        other.nationalityCode == nationalityCode &&
        other.category == category &&
        other.distanceKm == distanceKm &&
        other.dateIso == dateIso &&
        other.velodromeId == velodromeId &&
        other.velodromeName == velodromeName &&
        other.altitudeMeters == altitudeMeters &&
        other.chainringTeeth == chainringTeeth &&
        other.cogTeeth == cogTeeth &&
        other.isCurrentWorldRecord == isCurrentWorldRecord &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(
        id,
        riderName,
        nationalityCode,
        category,
        distanceKm,
        dateIso,
        velodromeId,
        velodromeName,
        altitudeMeters,
        chainringTeeth,
        cogTeeth,
        isCurrentWorldRecord,
        notes,
      );
}

/// Wynik symulacji próby bicia Rekordu Godzinnego UCI na wybranym welodromie.
class HourRecordAttemptSimulation {
  final String velodromeId;
  final String bikeModelName;
  final double targetPowerWatts;
  final double effectivePowerWatts;
  final double airDensityKgPerM3;
  final double predictedSpeedKmh;
  final double predictedDistanceKm;
  final double predictedLaps;
  final double requiredCadenceRpm;
  final double currentRecordDistanceKm;
  final double deltaToRecordMeters;

  const HourRecordAttemptSimulation({
    required this.velodromeId,
    required this.bikeModelName,
    required this.targetPowerWatts,
    required this.effectivePowerWatts,
    required this.airDensityKgPerM3,
    required this.predictedSpeedKmh,
    required this.predictedDistanceKm,
    required this.predictedLaps,
    required this.requiredCadenceRpm,
    required this.currentRecordDistanceKm,
    required this.deltaToRecordMeters,
  });

  /// Czy próba kończy się pobiciem aktualnego Rekordu Godzinnego UCI.
  bool get beatsCurrentRecord => deltaToRecordMeters > 0.0;

  Map<String, dynamic> toJson() {
    return {
      'velodromeId': velodromeId,
      'bikeModelName': bikeModelName,
      'targetPowerWatts': targetPowerWatts,
      'effectivePowerWatts': effectivePowerWatts,
      'airDensityKgPerM3': airDensityKgPerM3,
      'predictedSpeedKmh': predictedSpeedKmh,
      'predictedDistanceKm': predictedDistanceKm,
      'predictedLaps': predictedLaps,
      'requiredCadenceRpm': requiredCadenceRpm,
      'currentRecordDistanceKm': currentRecordDistanceKm,
      'deltaToRecordMeters': deltaToRecordMeters,
    };
  }

  factory HourRecordAttemptSimulation.fromJson(Map<String, dynamic> json) {
    return HourRecordAttemptSimulation(
      velodromeId: json['velodromeId'] as String? ?? 'grenchen_tissot',
      bikeModelName: json['bikeModelName'] as String? ?? 'Track Aero Prototype',
      targetPowerWatts:
          (json['targetPowerWatts'] as num?)?.toDouble() ?? 420.0,
      effectivePowerWatts:
          (json['effectivePowerWatts'] as num?)?.toDouble() ?? 420.0,
      airDensityKgPerM3:
          (json['airDensityKgPerM3'] as num?)?.toDouble() ?? 1.13,
      predictedSpeedKmh:
          (json['predictedSpeedKmh'] as num?)?.toDouble() ?? 54.0,
      predictedDistanceKm:
          (json['predictedDistanceKm'] as num?)?.toDouble() ?? 54.0,
      predictedLaps: (json['predictedLaps'] as num?)?.toDouble() ?? 216.0,
      requiredCadenceRpm:
          (json['requiredCadenceRpm'] as num?)?.toDouble() ?? 98.0,
      currentRecordDistanceKm:
          (json['currentRecordDistanceKm'] as num?)?.toDouble() ?? 56.792,
      deltaToRecordMeters:
          (json['deltaToRecordMeters'] as num?)?.toDouble() ?? -2792.0,
    );
  }
}

/// Główny model danych Kolarstwa Torowego na Welodromie i Rekordu Godzinnego UCI.
class VelodromeTrackAndHourRecordModel {
  static const double currentMenHourRecordKm = 56.792;
  static const double currentWomenHourRecordKm = 50.455;

  final VelodromeFacilitySpec activeVelodrome;
  final FixedGearTrackBike trackBike;
  final List<VelodromeFacilitySpec> availableVelodromes;
  final List<UciHourRecordEntry> hourRecordHistory;

  const VelodromeTrackAndHourRecordModel({
    required this.activeVelodrome,
    required this.trackBike,
    required this.availableVelodromes,
    required this.hourRecordHistory,
  });

  /// Tworzy domyślną instancję modelu z oficjalnym katalogiem welodromów i historią Rekordu Godzinnego UCI.
  factory VelodromeTrackAndHourRecordModel.standard({
    String initialVelodromeId = 'grenchen_tissot',
    FixedGearTrackBike? customBike,
  }) {
    const List<VelodromeFacilitySpec> velodromes = defaultVelodromes;
    final VelodromeFacilitySpec selected = velodromes.firstWhere(
      (v) => v.id == initialVelodromeId,
      orElse: () => velodromes.first,
    );
    return VelodromeTrackAndHourRecordModel(
      activeVelodrome: selected,
      trackBike: customBike ?? defaultTrackBike,
      availableVelodromes: velodromes,
      hourRecordHistory: defaultHourRecordHistory,
    );
  }

  /// Domyślny rower torowy ostrokołowy (tarcza 64T x zębatka 14T, bez hamulców).
  static const FixedGearTrackBike defaultTrackBike = FixedGearTrackBike(
    modelName: 'Pinarello Bolide F HR 3D',
    frameMaterial: '3D-Printed Scalmalloy & Carbon',
    isFixedGear: true,
    hasBrakes: false,
    hasFreewheel: false,
    chainringTeeth: 64,
    cogTeeth: 14,
    bikeWeightKg: 7.2,
    crankLengthMm: 170.0,
    cdaMetersSquared: 0.168,
    drivetrainEfficiency: 0.986,
  );

  /// Katalog certyfikowanych krytych drewnianych welodromów 250 m.
  static const List<VelodromeFacilitySpec> defaultVelodromes = [
    VelodromeFacilitySpec(
      id: 'grenchen_tissot',
      name: 'Tissot Velodrome Grenchen',
      city: 'Grenchen',
      countryCode: 'SUI',
      trackLengthMeters: 250.0,
      turnBankingDegrees: 42.0,
      straightBankingDegrees: 12.5,
      altitudeMeters: 450.0,
      woodSurface: VelodromeWoodSurface.siberianPine,
      isIndoor: true,
      indoorTemperatureCelsius: 25.0,
      relativeHumidityPercent: 45.0,
      turnRadiusMeters: 23.0,
    ),
    VelodromeFacilitySpec(
      id: 'aguascalientes_bicentenario',
      name: 'Velódromo Bicentenario Aguascalientes',
      city: 'Aguascalientes',
      countryCode: 'MEX',
      trackLengthMeters: 250.0,
      turnBankingDegrees: 45.0,
      straightBankingDegrees: 14.0,
      altitudeMeters: 1880.0,
      woodSurface: VelodromeWoodSurface.siberianSpruce,
      isIndoor: true,
      indoorTemperatureCelsius: 27.0,
      relativeHumidityPercent: 38.0,
      turnRadiusMeters: 22.5,
    ),
    VelodromeFacilitySpec(
      id: 'london_lee_valley',
      name: 'Lee Valley VeloPark',
      city: 'London',
      countryCode: 'GBR',
      trackLengthMeters: 250.0,
      turnBankingDegrees: 42.0,
      straightBankingDegrees: 12.0,
      altitudeMeters: 12.0,
      woodSurface: VelodromeWoodSurface.siberianPine,
      isIndoor: true,
      indoorTemperatureCelsius: 28.0,
      relativeHumidityPercent: 40.0,
      turnRadiusMeters: 23.5,
    ),
    VelodromeFacilitySpec(
      id: 'pruszkow_arena',
      name: 'BGŻ BNP Paribas Arena Pruszków',
      city: 'Pruszków',
      countryCode: 'POL',
      trackLengthMeters: 250.0,
      turnBankingDegrees: 42.5,
      straightBankingDegrees: 12.5,
      altitudeMeters: 105.0,
      woodSurface: VelodromeWoodSurface.siberianPine,
      isIndoor: true,
      indoorTemperatureCelsius: 24.0,
      relativeHumidityPercent: 46.0,
      turnRadiusMeters: 23.0,
    ),
    VelodromeFacilitySpec(
      id: 'apeldoorn_omnisport',
      name: 'Omnisport Apeldoorn',
      city: 'Apeldoorn',
      countryCode: 'NED',
      trackLengthMeters: 250.0,
      turnBankingDegrees: 43.0,
      straightBankingDegrees: 13.0,
      altitudeMeters: 16.0,
      woodSurface: VelodromeWoodSurface.siberianSpruce,
      isIndoor: true,
      indoorTemperatureCelsius: 25.5,
      relativeHumidityPercent: 44.0,
      turnRadiusMeters: 23.0,
    ),
  ];

  /// Historyczny i aktualny wykaz Rekordu Godzinnego UCI (era zunifikowana).
  static const List<UciHourRecordEntry> defaultHourRecordHistory = [
    UciHourRecordEntry(
      id: 'hr_ganna_2022',
      riderName: 'Filippo Ganna',
      nationalityCode: 'ITA',
      category: UciHourRecordCategory.menElite,
      distanceKm: 56.792,
      dateIso: '2022-10-08',
      velodromeId: 'grenchen_tissot',
      velodromeName: 'Tissot Velodrome Grenchen',
      altitudeMeters: 450.0,
      chainringTeeth: 64,
      cogTeeth: 14,
      isCurrentWorldRecord: true,
      notes: 'Aktualny Rekord Godzinny UCI Elity Mężczyzn (227.168 okrążeń).',
    ),
    UciHourRecordEntry(
      id: 'hr_bigham_2022',
      riderName: 'Dan Bigham',
      nationalityCode: 'GBR',
      category: UciHourRecordCategory.menElite,
      distanceKm: 55.548,
      dateIso: '2022-08-19',
      velodromeId: 'grenchen_tissot',
      velodromeName: 'Tissot Velodrome Grenchen',
      altitudeMeters: 450.0,
      chainringTeeth: 62,
      cogTeeth: 14,
      isCurrentWorldRecord: false,
      notes: 'Inżynierski przełom aero INEOS przed próbą Ganny.',
    ),
    UciHourRecordEntry(
      id: 'hr_campenaerts_2019',
      riderName: 'Victor Campenaerts',
      nationalityCode: 'BEL',
      category: UciHourRecordCategory.menElite,
      distanceKm: 55.089,
      dateIso: '2019-04-16',
      velodromeId: 'aguascalientes_bicentenario',
      velodromeName: 'Velódromo Bicentenario Aguascalientes',
      altitudeMeters: 1880.0,
      chainringTeeth: 60,
      cogTeeth: 14,
      isCurrentWorldRecord: false,
      notes: 'Próba wysokogórska na 1880 m n.p.m. przy niskiej gęstości powietrza.',
    ),
    UciHourRecordEntry(
      id: 'hr_wiggins_2015',
      riderName: 'Bradley Wiggins',
      nationalityCode: 'GBR',
      category: UciHourRecordCategory.menElite,
      distanceKm: 54.526,
      dateIso: '2015-06-07',
      velodromeId: 'london_lee_valley',
      velodromeName: 'Lee Valley VeloPark',
      altitudeMeters: 12.0,
      chainringTeeth: 58,
      cogTeeth: 14,
      isCurrentWorldRecord: false,
      notes: 'Rekord ustanowiony na poziomie morza przy wysokim ciśnieniu.',
    ),
    UciHourRecordEntry(
      id: 'hr_voigt_2014',
      riderName: 'Jens Voigt',
      nationalityCode: 'GER',
      category: UciHourRecordCategory.menElite,
      distanceKm: 51.110,
      dateIso: '2014-09-18',
      velodromeId: 'grenchen_tissot',
      velodromeName: 'Tissot Velodrome Grenchen',
      altitudeMeters: 450.0,
      chainringTeeth: 58,
      cogTeeth: 14,
      isCurrentWorldRecord: false,
      notes: 'Pierwszy rekord po unifikacji przepisów UCI w 2014 roku.',
    ),
    UciHourRecordEntry(
      id: 'hr_bussi_2025',
      riderName: 'Vittoria Bussi',
      nationalityCode: 'ITA',
      category: UciHourRecordCategory.womenElite,
      distanceKm: 50.455,
      dateIso: '2025-05-10',
      velodromeId: 'aguascalientes_bicentenario',
      velodromeName: 'Velódromo Bicentenario Aguascalientes',
      altitudeMeters: 1880.0,
      chainringTeeth: 59,
      cogTeeth: 14,
      isCurrentWorldRecord: true,
      notes: 'Aktualny Rekord Godzinny UCI Elity Kobiet powyżej 50 km.',
    ),
    UciHourRecordEntry(
      id: 'hr_van_dijk_2022',
      riderName: 'Ellen van Dijk',
      nationalityCode: 'NED',
      category: UciHourRecordCategory.womenElite,
      distanceKm: 49.254,
      dateIso: '2022-05-23',
      velodromeId: 'grenchen_tissot',
      velodromeName: 'Tissot Velodrome Grenchen',
      altitudeMeters: 450.0,
      chainringTeeth: 58,
      cogTeeth: 14,
      isCurrentWorldRecord: false,
      notes: 'Rekord świata ustanowiony w Grenchen.',
    ),
  ];

  /// Zwraca aktualny Rekord Godzinny UCI dla wybranej kategorii.
  UciHourRecordEntry currentRecordForCategory(UciHourRecordCategory category) {
    final List<UciHourRecordEntry> matching = hourRecordHistory
        .where((entry) => entry.category == category)
        .toList()
      ..sort((a, b) => b.distanceKm.compareTo(a.distanceKm));

    if (matching.isEmpty) {
      return defaultHourRecordHistory.first;
    }
    return matching.firstWhere(
      (entry) => entry.isCurrentWorldRecord,
      orElse: () => matching.first,
    );
  }

  /// Wylicza moc wymaganą na korbie [W] do utrzymania zadanej prędkości [km/h] na aktywnym welodromie.
  double requiredPowerWattsForSpeedKmh({
    required double speedKmh,
    required double riderMassKg,
    VelodromeFacilitySpec? velodromeOverride,
    FixedGearTrackBike? bikeOverride,
  }) {
    if (speedKmh <= 0) return 0.0;
    final VelodromeFacilitySpec velodrome = velodromeOverride ?? activeVelodrome;
    final FixedGearTrackBike bike = bikeOverride ?? trackBike;

    final double v = speedKmh / 3.6;
    final double totalMassKg = riderMassKg + bike.bikeWeightKg;
    final double rho = velodrome.airDensityKgPerM3;

    // Opór aerodynamiczny: 0.5 * rho * CdA * v^2
    final double fAero = 0.5 * rho * bike.cdaMetersSquared * v * v;

    // Opór toczenia uwzględniający średnie dociążenie odśrodkowe na wirażach (ok. 48% długości toru).
    final double turnLoadFactor = velodrome.bankingNormalLoadFactor(v);
    final double avgLoadFactor = 0.52 * 1.0 + 0.48 * turnLoadFactor;
    final double fRolling = totalMassKg *
        9.80665 *
        velodrome.woodSurface.baseRollingResistanceCrr *
        avgLoadFactor;

    final double wheelPowerWatts = (fAero + fRolling) * v;
    return wheelPowerWatts / bike.drivetrainEfficiency;
  }

  /// Symuluje 60-minutową próbę bicia Rekordu Godzinnego UCI dla zadanej mocy progowej (FTP) [W].
  HourRecordAttemptSimulation simulateHourRecordAttempt({
    required double sustainableHourPowerWatts,
    required double riderMassKg,
    UciHourRecordCategory category = UciHourRecordCategory.menElite,
    double altitudeAcclimatizationBonus = 0.0,
    VelodromeFacilitySpec? velodromeOverride,
    FixedGearTrackBike? bikeOverride,
  }) {
    final VelodromeFacilitySpec velodrome = velodromeOverride ?? activeVelodrome;
    final FixedGearTrackBike bike = bikeOverride ?? trackBike;

    // Uwzględnienie hipoksji wysokościowej z możliwością częściowej kompensacji przez aklimatyzację.
    final double baseHypoxiaFactor = velodrome.hypoxiaPowerPenaltyFactor;
    final double penaltyReduction =
        (1.0 - baseHypoxiaFactor) * altitudeAcclimatizationBonus.clamp(0.0, 0.7);
    final double effectiveHypoxiaFactor =
        (baseHypoxiaFactor + penaltyReduction).clamp(0.70, 1.0);
    final double effectivePowerWatts =
        math.max(50.0, sustainableHourPowerWatts * effectiveHypoxiaFactor);

    // Rozwiązanie numeryczne metodą bisekcji dla v [km/h] w zakresie [20, 80] km/h.
    double low = 20.0;
    double high = 80.0;
    for (int i = 0; i < 40; i++) {
      final double mid = (low + high) * 0.5;
      final double neededWatts = requiredPowerWattsForSpeedKmh(
        speedKmh: mid,
        riderMassKg: riderMassKg,
        velodromeOverride: velodrome,
        bikeOverride: bike,
      );
      if (neededWatts < effectivePowerWatts) {
        low = mid;
      } else {
        high = mid;
      }
    }

    final double predictedSpeedKmh = (low + high) * 0.5;
    final double predictedDistanceKm = predictedSpeedKmh; // 1 godzina = 1.0 h
    final double predictedLaps = velodrome.lapsForDistanceKm(predictedDistanceKm);
    final double requiredCadenceRpm =
        bike.cadenceRpmFromSpeedKmh(predictedSpeedKmh);
    final UciHourRecordEntry currentRecord = currentRecordForCategory(category);
    final double deltaMeters =
        (predictedDistanceKm - currentRecord.distanceKm) * 1000.0;

    return HourRecordAttemptSimulation(
      velodromeId: velodrome.id,
      bikeModelName: bike.modelName,
      targetPowerWatts: sustainableHourPowerWatts,
      effectivePowerWatts: effectivePowerWatts,
      airDensityKgPerM3: velodrome.airDensityKgPerM3,
      predictedSpeedKmh: predictedSpeedKmh,
      predictedDistanceKm: predictedDistanceKm,
      predictedLaps: predictedLaps,
      requiredCadenceRpm: requiredCadenceRpm,
      currentRecordDistanceKm: currentRecord.distanceKm,
      deltaToRecordMeters: deltaMeters,
    );
  }

  VelodromeTrackAndHourRecordModel copyWith({
    VelodromeFacilitySpec? activeVelodrome,
    FixedGearTrackBike? trackBike,
    List<VelodromeFacilitySpec>? availableVelodromes,
    List<UciHourRecordEntry>? hourRecordHistory,
  }) {
    return VelodromeTrackAndHourRecordModel(
      activeVelodrome: activeVelodrome ?? this.activeVelodrome,
      trackBike: trackBike ?? this.trackBike,
      availableVelodromes: availableVelodromes ?? this.availableVelodromes,
      hourRecordHistory: hourRecordHistory ?? this.hourRecordHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeVelodrome': activeVelodrome.toJson(),
      'trackBike': trackBike.toJson(),
      'availableVelodromes':
          availableVelodromes.map((v) => v.toJson()).toList(),
      'hourRecordHistory': hourRecordHistory.map((e) => e.toJson()).toList(),
    };
  }

  factory VelodromeTrackAndHourRecordModel.fromJson(Map<String, dynamic> json) {
    final List<VelodromeFacilitySpec> velodromes =
        (json['availableVelodromes'] as List<dynamic>?)
                ?.map((e) =>
                    VelodromeFacilitySpec.fromJson(e as Map<String, dynamic>))
                .toList() ??
            defaultVelodromes;
    final List<UciHourRecordEntry> records =
        (json['hourRecordHistory'] as List<dynamic>?)
                ?.map((e) =>
                    UciHourRecordEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            defaultHourRecordHistory;

    return VelodromeTrackAndHourRecordModel(
      activeVelodrome: json['activeVelodrome'] is Map<String, dynamic>
          ? VelodromeFacilitySpec.fromJson(
              json['activeVelodrome'] as Map<String, dynamic>,
            )
          : defaultVelodromes.first,
      trackBike: json['trackBike'] is Map<String, dynamic>
          ? FixedGearTrackBike.fromJson(
              json['trackBike'] as Map<String, dynamic>,
            )
          : defaultTrackBike,
      availableVelodromes: velodromes,
      hourRecordHistory: records,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VelodromeTrackAndHourRecordModel) return false;
    if (other.activeVelodrome != activeVelodrome ||
        other.trackBike != trackBike ||
        other.availableVelodromes.length != availableVelodromes.length ||
        other.hourRecordHistory.length != hourRecordHistory.length) {
      return false;
    }
    for (int i = 0; i < availableVelodromes.length; i++) {
      if (other.availableVelodromes[i] != availableVelodromes[i]) return false;
    }
    for (int i = 0; i < hourRecordHistory.length; i++) {
      if (other.hourRecordHistory[i] != hourRecordHistory[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        activeVelodrome,
        trackBike,
        Object.hashAll(availableVelodromes),
        Object.hashAll(hourRecordHistory),
      );
}
