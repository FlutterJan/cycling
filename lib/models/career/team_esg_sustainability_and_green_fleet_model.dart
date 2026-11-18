import 'dart:math' as math;

/// Typ pojazdu w konwoju i flocie zespołu kolarskiego.
enum FleetVehicleType {
  /// Wóz dyrektora sportowego jadący bezpośrednio w kolumnie wyścigu.
  directorSportifCar,

  /// Wóz techniczny mechaników z zapasowymi rowerami na dachu.
  mechanicSupportCar,

  /// Autokar drużynowy dla kolarzy i sztabu.
  teamCoachBus,

  /// Ciężarówka sprzętowa / warsztat mobilny.
  equipmentCargoTruck,

  /// Van medyczny, fizjoterapii lub mobilna kuchnia.
  medicalAndKitchenVan;

  String toJson() => name;

  static FleetVehicleType fromJson(String value) {
    return FleetVehicleType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => FleetVehicleType.directorSportifCar,
    );
  }

  String get displayNamePl {
    switch (this) {
      case FleetVehicleType.directorSportifCar:
        return 'Wóz Dyrektora Sportowego';
      case FleetVehicleType.mechanicSupportCar:
        return 'Wóz Techniczny Mechaników';
      case FleetVehicleType.teamCoachBus:
        return 'Autokar Drużynowy';
      case FleetVehicleType.equipmentCargoTruck:
        return 'Ciężarówka Sprzętowa';
      case FleetVehicleType.medicalAndKitchenVan:
        return 'Van Medyczny / Kuchnia';
    }
  }

  String get displayNameEn {
    switch (this) {
      case FleetVehicleType.directorSportifCar:
        return 'Sports Director Car';
      case FleetVehicleType.mechanicSupportCar:
        return 'Mechanic Support Car';
      case FleetVehicleType.teamCoachBus:
        return 'Team Coach Bus';
      case FleetVehicleType.equipmentCargoTruck:
        return 'Equipment Cargo Truck';
      case FleetVehicleType.medicalAndKitchenVan:
        return 'Medical & Kitchen Van';
    }
  }
}

/// Rodzaj napędu pojazdu we flocie zespołu.
enum PowertrainType {
  /// Silnik wysokoprężny Euro 6.
  dieselEuro6,

  /// Miękka / klasyczna hybryda HEV.
  mildHybrid,

  /// Hybryda ładowana z gniazdka PHEV.
  plugInHybrid,

  /// Napęd w pełni elektryczny BEV.
  batteryElectric,

  /// Ogniwa wodorowe FCEV.
  hydrogenFuelCell;

  String toJson() => name;

  static PowertrainType fromJson(String value) {
    return PowertrainType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PowertrainType.dieselEuro6,
    );
  }

  String get displayNamePl {
    switch (this) {
      case PowertrainType.dieselEuro6:
        return 'Diesel Euro 6';
      case PowertrainType.mildHybrid:
        return 'Hybryda HEV';
      case PowertrainType.plugInHybrid:
        return 'Hybryda Plug-In (PHEV)';
      case PowertrainType.batteryElectric:
        return 'Elektryczny (BEV)';
      case PowertrainType.hydrogenFuelCell:
        return 'Wodorowy (FCEV)';
    }
  }

  String get displayNameEn {
    switch (this) {
      case PowertrainType.dieselEuro6:
        return 'Diesel Euro 6';
      case PowertrainType.mildHybrid:
        return 'Hybrid (HEV)';
      case PowertrainType.plugInHybrid:
        return 'Plug-In Hybrid (PHEV)';
      case PowertrainType.batteryElectric:
        return 'Battery Electric (BEV)';
      case PowertrainType.hydrogenFuelCell:
        return 'Hydrogen Fuel Cell (FCEV)';
    }
  }

  bool get isZeroTailpipeEmission =>
      this == PowertrainType.batteryElectric ||
      this == PowertrainType.hydrogenFuelCell;

  bool get isElectrified =>
      this == PowertrainType.plugInHybrid ||
      this == PowertrainType.batteryElectric ||
      this == PowertrainType.hydrogenFuelCell;

  /// Waga wkładu w wskaźnik elektryfikacji floty (0.0 – 1.0).
  double get electrificationWeight {
    switch (this) {
      case PowertrainType.dieselEuro6:
        return 0.0;
      case PowertrainType.mildHybrid:
        return 0.25;
      case PowertrainType.plugInHybrid:
        return 0.65;
      case PowertrainType.batteryElectric:
      case PowertrainType.hydrogenFuelCell:
        return 1.0;
    }
  }
}

/// Poziom infrastruktury ładowania i OZE zespołu.
enum ChargingInfrastructureTier {
  none,
  depotFastCharger,
  mobileSolarBatteryTrailer,
  solarMicrogridHq;

  String toJson() => name;

  static ChargingInfrastructureTier fromJson(String value) {
    return ChargingInfrastructureTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ChargingInfrastructureTier.none,
    );
  }

  String get displayNamePl {
    switch (this) {
      case ChargingInfrastructureTier.none:
        return 'Brak własnej stacji (publiczne)';
      case ChargingInfrastructureTier.depotFastCharger:
        return 'Ładowarki DC 150 kW w bazie';
      case ChargingInfrastructureTier.mobileSolarBatteryTrailer:
        return 'Mobilny magazyn energii + PV na wyścigi';
      case ChargingInfrastructureTier.solarMicrogridHq:
        return 'Mikrosieć solarna HQ + sieć wyścigowa';
    }
  }

  String get displayNameEn {
    switch (this) {
      case ChargingInfrastructureTier.none:
        return 'Public Charging Only';
      case ChargingInfrastructureTier.depotFastCharger:
        return 'HQ 150 kW DC Fast Chargers';
      case ChargingInfrastructureTier.mobileSolarBatteryTrailer:
        return 'Mobile Solar Battery Trailer';
      case ChargingInfrastructureTier.solarMicrogridHq:
        return 'HQ Solar Microgrid + Race Chargers';
    }
  }

  double get upgradeCostEur {
    switch (this) {
      case ChargingInfrastructureTier.none:
        return 0;
      case ChargingInfrastructureTier.depotFastCharger:
        return 120000;
      case ChargingInfrastructureTier.mobileSolarBatteryTrailer:
        return 260000;
      case ChargingInfrastructureTier.solarMicrogridHq:
        return 540000;
    }
  }

  double get esgScorePoints {
    switch (this) {
      case ChargingInfrastructureTier.none:
        return 0;
      case ChargingInfrastructureTier.depotFastCharger:
        return 6;
      case ChargingInfrastructureTier.mobileSolarBatteryTrailer:
        return 11;
      case ChargingInfrastructureTier.solarMicrogridHq:
        return 15;
    }
  }

  /// Redukcja śladu węglowego ładowania z sieci (np. energia z PV).
  double get gridCarbonReductionFactor {
    switch (this) {
      case ChargingInfrastructureTier.none:
        return 0.0;
      case ChargingInfrastructureTier.depotFastCharger:
        return 0.25;
      case ChargingInfrastructureTier.mobileSolarBatteryTrailer:
        return 0.60;
      case ChargingInfrastructureTier.solarMicrogridHq:
        return 0.90;
    }
  }
}

/// Rodzaj programu kompensacji emisji CO2.
enum CarbonOffsetProgramType {
  reforestation,
  renewableEnergy,
  cyclingInfrastructure,
  directAirCapture;

  String toJson() => name;

  static CarbonOffsetProgramType fromJson(String value) {
    return CarbonOffsetProgramType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CarbonOffsetProgramType.reforestation,
    );
  }

  String get displayNamePl {
    switch (this) {
      case CarbonOffsetProgramType.reforestation:
        return 'Zalesianie i ochrona lasów';
      case CarbonOffsetProgramType.renewableEnergy:
        return 'Certyfikaty OZE / Farmy Wiatrowe';
      case CarbonOffsetProgramType.cyclingInfrastructure:
        return 'Miejska infrastruktura rowerowa';
      case CarbonOffsetProgramType.directAirCapture:
        return 'Wychwyt CO₂ z powietrza (DAC)';
    }
  }

  String get displayNameEn {
    switch (this) {
      case CarbonOffsetProgramType.reforestation:
        return 'Reforestation & Forest Protection';
      case CarbonOffsetProgramType.renewableEnergy:
        return 'Renewable Energy Certificates';
      case CarbonOffsetProgramType.cyclingInfrastructure:
        return 'Urban Cycling Infrastructure';
      case CarbonOffsetProgramType.directAirCapture:
        return 'Direct Air Capture (DAC)';
    }
  }

  /// Mnożnik ceny za tonę CO2 względem bazowej ceny kredytu węglowego.
  double get priceMultiplier {
    switch (this) {
      case CarbonOffsetProgramType.reforestation:
        return 1.0;
      case CarbonOffsetProgramType.renewableEnergy:
        return 1.15;
      case CarbonOffsetProgramType.cyclingInfrastructure:
        return 1.25;
      case CarbonOffsetProgramType.directAirCapture:
        return 2.40;
    }
  }
}

/// Klasa oceny ESG zespołu i zgodności z Kartą Klimatyczną UCI.
enum EsgRatingTier {
  bronze,
  silver,
  gold,
  platinumUciCharter;

  String toJson() => name;

  static EsgRatingTier fromJson(String value) {
    return EsgRatingTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EsgRatingTier.bronze,
    );
  }

  static EsgRatingTier fromScore(double score) {
    if (score >= 80.0) return EsgRatingTier.platinumUciCharter;
    if (score >= 60.0) return EsgRatingTier.gold;
    if (score >= 40.0) return EsgRatingTier.silver;
    return EsgRatingTier.bronze;
  }

  String get displayNamePl {
    switch (this) {
      case EsgRatingTier.bronze:
        return 'Brązowy Poziom ESG';
      case EsgRatingTier.silver:
        return 'Srebrny Poziom ESG';
      case EsgRatingTier.gold:
        return 'Złoty Poziom ESG';
      case EsgRatingTier.platinumUciCharter:
        return 'Platyna — Karta Klimatyczna UCI';
    }
  }

  String get displayNameEn {
    switch (this) {
      case EsgRatingTier.bronze:
        return 'Bronze ESG Tier';
      case EsgRatingTier.silver:
        return 'Silver ESG Tier';
      case EsgRatingTier.gold:
        return 'Gold ESG Tier';
      case EsgRatingTier.platinumUciCharter:
        return 'Platinum — UCI Climate Charter';
    }
  }
}

/// Branża zielonego sponsora nastawionego na cele zrównoważonego rozwoju.
enum GreenSponsorCategory {
  renewableEnergyUtility,
  electricMobility,
  sustainableApparel,
  organicNutrition,
  greenFinance;

  String toJson() => name;

  static GreenSponsorCategory fromJson(String value) {
    return GreenSponsorCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GreenSponsorCategory.renewableEnergyUtility,
    );
  }

  String get displayNamePl {
    switch (this) {
      case GreenSponsorCategory.renewableEnergyUtility:
        return 'Energetyka Odnawialna';
      case GreenSponsorCategory.electricMobility:
        return 'Elektromobilność (EV)';
      case GreenSponsorCategory.sustainableApparel:
        return 'Odzież z Recyklingu';
      case GreenSponsorCategory.organicNutrition:
        return 'Żywienie Organiczne';
      case GreenSponsorCategory.greenFinance:
        return 'Zielone Finanse ESG';
    }
  }

  String get displayNameEn {
    switch (this) {
      case GreenSponsorCategory.renewableEnergyUtility:
        return 'Renewable Energy';
      case GreenSponsorCategory.electricMobility:
        return 'Electric Mobility';
      case GreenSponsorCategory.sustainableApparel:
        return 'Sustainable Apparel';
      case GreenSponsorCategory.organicNutrition:
        return 'Organic Nutrition';
      case GreenSponsorCategory.greenFinance:
        return 'Green Finance';
    }
  }
}

/// Środek transportu delegacji zespołu na wyścig.
enum TravelTransportMode {
  shortHaulFlight,
  longHaulFlight,
  highSpeedRail,
  electricTeamBus,
  dieselTeamBus;

  String toJson() => name;

  static TravelTransportMode fromJson(String value) {
    return TravelTransportMode.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TravelTransportMode.highSpeedRail,
    );
  }

  /// Emisja CO2 w kg na pasażerokilometr.
  double get kgCo2PerPassengerKm {
    switch (this) {
      case TravelTransportMode.shortHaulFlight:
        return 0.255;
      case TravelTransportMode.longHaulFlight:
        return 0.195;
      case TravelTransportMode.highSpeedRail:
        return 0.014;
      case TravelTransportMode.electricTeamBus:
        return 0.018;
      case TravelTransportMode.dieselTeamBus:
        return 0.068;
    }
  }

  /// Koszt transportu w EUR na pasażerokilometr.
  double get costEurPerPassengerKm {
    switch (this) {
      case TravelTransportMode.shortHaulFlight:
        return 0.32;
      case TravelTransportMode.longHaulFlight:
        return 0.28;
      case TravelTransportMode.highSpeedRail:
        return 0.16;
      case TravelTransportMode.electricTeamBus:
        return 0.09;
      case TravelTransportMode.dieselTeamBus:
        return 0.11;
    }
  }
}

/// Kategoria wpisu w księdze bilansu węglowego zespołu.
enum CarbonLedgerCategory {
  fleetConvoy,
  teamTravel,
  logisticsFreight,
  hqOperations,
  offsetCredit;

  String toJson() => name;

  static CarbonLedgerCategory fromJson(String value) {
    return CarbonLedgerCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CarbonLedgerCategory.fleetConvoy,
    );
  }
}

/// Pojazd we flocie zespołu kolarskiego.
class TeamFleetVehicle {
  final String id;
  final String name;
  final FleetVehicleType vehicleType;
  final PowertrainType powertrain;
  final double batteryCapacityKwh;
  final double wltpRangeKm;
  final double co2GramsPerKm;
  final double purchaseCostEur;
  final double annualMaintenanceEur;
  final double conditionPercent;
  final double odometerKm;
  final bool isActiveInRaceConvoy;
  final String assignedRoleLabel;

  const TeamFleetVehicle({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.powertrain,
    required this.batteryCapacityKwh,
    required this.wltpRangeKm,
    required this.co2GramsPerKm,
    required this.purchaseCostEur,
    required this.annualMaintenanceEur,
    this.conditionPercent = 100.0,
    this.odometerKm = 0.0,
    this.isActiveInRaceConvoy = true,
    this.assignedRoleLabel = 'Convoy',
  });

  bool get isZeroEmission => powertrain.isZeroTailpipeEmission;

  /// Realistyczny zasięg na etapie z uwzględnieniem przewyższeń (bagażnik z rowerami na dachu) oraz temperatury.
  double effectiveRangeKm({
    double elevationGainM = 1500.0,
    double ambientTempC = 20.0,
  }) {
    if (wltpRangeKm <= 0) return 0.0;
    double penaltyFactor = 1.0;

    if (powertrain == PowertrainType.batteryElectric ||
        powertrain == PowertrainType.plugInHybrid) {
      // Bagazniki z rowerami i wolna jazda za peletonem + klima/ogrzewanie.
      final double climbPenalty =
          (elevationGainM.clamp(0.0, 6000.0) / 1000.0) * 0.045;
      final double coldPenalty =
          ambientTempC < 10.0 ? ((10.0 - ambientTempC).clamp(0.0, 25.0) * 0.008) : 0.0;
      final double heatPenalty =
          ambientTempC > 30.0 ? ((ambientTempC - 30.0).clamp(0.0, 20.0) * 0.005) : 0.0;
      penaltyFactor = (1.0 - climbPenalty - coldPenalty - heatPenalty).clamp(0.55, 1.0);
    } else if (powertrain == PowertrainType.hydrogenFuelCell) {
      final double climbPenalty =
          (elevationGainM.clamp(0.0, 6000.0) / 1000.0) * 0.02;
      penaltyFactor = (1.0 - climbPenalty).clamp(0.75, 1.0);
    }

    final double healthFactor = (0.85 + 0.15 * (conditionPercent.clamp(0.0, 100.0) / 100.0));
    return wltpRangeKm * penaltyFactor * healthFactor;
  }

  /// Koszt energii lub paliwa w EUR na 100 km.
  double get energyCostPer100KmEur {
    switch (powertrain) {
      case PowertrainType.dieselEuro6:
        return vehicleType == FleetVehicleType.teamCoachBus ||
                vehicleType == FleetVehicleType.equipmentCargoTruck
            ? 38.0
            : 16.5;
      case PowertrainType.mildHybrid:
        return 13.0;
      case PowertrainType.plugInHybrid:
        return 9.2;
      case PowertrainType.batteryElectric:
        return vehicleType == FleetVehicleType.teamCoachBus ||
                vehicleType == FleetVehicleType.equipmentCargoTruck
            ? 14.0
            : 5.5;
      case PowertrainType.hydrogenFuelCell:
        return 18.0;
    }
  }

  TeamFleetVehicle copyWith({
    String? id,
    String? name,
    FleetVehicleType? vehicleType,
    PowertrainType? powertrain,
    double? batteryCapacityKwh,
    double? wltpRangeKm,
    double? co2GramsPerKm,
    double? purchaseCostEur,
    double? annualMaintenanceEur,
    double? conditionPercent,
    double? odometerKm,
    bool? isActiveInRaceConvoy,
    String? assignedRoleLabel,
  }) {
    return TeamFleetVehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      vehicleType: vehicleType ?? this.vehicleType,
      powertrain: powertrain ?? this.powertrain,
      batteryCapacityKwh: batteryCapacityKwh ?? this.batteryCapacityKwh,
      wltpRangeKm: wltpRangeKm ?? this.wltpRangeKm,
      co2GramsPerKm: co2GramsPerKm ?? this.co2GramsPerKm,
      purchaseCostEur: purchaseCostEur ?? this.purchaseCostEur,
      annualMaintenanceEur: annualMaintenanceEur ?? this.annualMaintenanceEur,
      conditionPercent: conditionPercent ?? this.conditionPercent,
      odometerKm: odometerKm ?? this.odometerKm,
      isActiveInRaceConvoy: isActiveInRaceConvoy ?? this.isActiveInRaceConvoy,
      assignedRoleLabel: assignedRoleLabel ?? this.assignedRoleLabel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'vehicleType': vehicleType.toJson(),
      'powertrain': powertrain.toJson(),
      'batteryCapacityKwh': batteryCapacityKwh,
      'wltpRangeKm': wltpRangeKm,
      'co2GramsPerKm': co2GramsPerKm,
      'purchaseCostEur': purchaseCostEur,
      'annualMaintenanceEur': annualMaintenanceEur,
      'conditionPercent': conditionPercent,
      'odometerKm': odometerKm,
      'isActiveInRaceConvoy': isActiveInRaceConvoy,
      'assignedRoleLabel': assignedRoleLabel,
    };
  }

  factory TeamFleetVehicle.fromJson(Map<String, dynamic> json) {
    return TeamFleetVehicle(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Team Vehicle',
      vehicleType: FleetVehicleType.fromJson(
        json['vehicleType']?.toString() ?? 'directorSportifCar',
      ),
      powertrain: PowertrainType.fromJson(
        json['powertrain']?.toString() ?? 'dieselEuro6',
      ),
      batteryCapacityKwh: (json['batteryCapacityKwh'] as num?)?.toDouble() ?? 0.0,
      wltpRangeKm: (json['wltpRangeKm'] as num?)?.toDouble() ?? 600.0,
      co2GramsPerKm: (json['co2GramsPerKm'] as num?)?.toDouble() ?? 165.0,
      purchaseCostEur: (json['purchaseCostEur'] as num?)?.toDouble() ?? 45000.0,
      annualMaintenanceEur:
          (json['annualMaintenanceEur'] as num?)?.toDouble() ?? 4500.0,
      conditionPercent: (json['conditionPercent'] as num?)?.toDouble() ?? 100.0,
      odometerKm: (json['odometerKm'] as num?)?.toDouble() ?? 0.0,
      isActiveInRaceConvoy: json['isActiveInRaceConvoy'] as bool? ?? true,
      assignedRoleLabel: json['assignedRoleLabel']?.toString() ?? 'Convoy',
    );
  }
}

/// Pojedynczy wpis emisji lub kompensacji CO2 w bilansie zespołu.
class CarbonFootprintEntry {
  final String id;
  final String dateIso;
  final CarbonLedgerCategory category;
  final String description;
  final double distanceKm;
  /// Wartość dodatnia = emisja kg CO2, wartość ujemna = kompensacja/offset kg CO2.
  final double co2KgDelta;
  final double costEur;
  final String? raceId;

  const CarbonFootprintEntry({
    required this.id,
    required this.dateIso,
    required this.category,
    required this.description,
    required this.distanceKm,
    required this.co2KgDelta,
    required this.costEur,
    this.raceId,
  });

  bool get isOffset => co2KgDelta < 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateIso': dateIso,
      'category': category.toJson(),
      'description': description,
      'distanceKm': distanceKm,
      'co2KgDelta': co2KgDelta,
      'costEur': costEur,
      'raceId': raceId,
    };
  }

  factory CarbonFootprintEntry.fromJson(Map<String, dynamic> json) {
    return CarbonFootprintEntry(
      id: json['id']?.toString() ?? '',
      dateIso: json['dateIso']?.toString() ?? '2026-01-01',
      category: CarbonLedgerCategory.fromJson(
        json['category']?.toString() ?? 'fleetConvoy',
      ),
      description: json['description']?.toString() ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      co2KgDelta: (json['co2KgDelta'] as num?)?.toDouble() ?? 0.0,
      costEur: (json['costEur'] as num?)?.toDouble() ?? 0.0,
      raceId: json['raceId']?.toString(),
    );
  }
}

/// Oferta lub aktywny kontrakt zielonego sponsora z premiami ESG.
class GreenSponsorOffer {
  final String id;
  final String sponsorName;
  final GreenSponsorCategory category;
  final double annualBaseValueEur;
  final double esgBonusValueEur;
  final double requiredEsgScore;
  final double maxAllowedNetCo2Tons;
  final bool requiresZeroEmissionRaceCars;
  final int contractYears;
  final bool isActive;
  final int complianceStreakMonths;

  const GreenSponsorOffer({
    required this.id,
    required this.sponsorName,
    required this.category,
    required this.annualBaseValueEur,
    required this.esgBonusValueEur,
    required this.requiredEsgScore,
    required this.maxAllowedNetCo2Tons,
    this.requiresZeroEmissionRaceCars = false,
    this.contractYears = 2,
    this.isActive = false,
    this.complianceStreakMonths = 0,
  });

  bool isEligible(TeamEsgOverview overview) {
    if (overview.esgScore < requiredEsgScore) return false;
    final double netTons = overview.netCarbonBalanceKg / 1000.0;
    if (netTons > maxAllowedNetCo2Tons) return false;
    if (requiresZeroEmissionRaceCars && !overview.allRaceCarsZeroEmission) {
      return false;
    }
    return true;
  }

  double effectiveAnnualPayoutEur(TeamEsgOverview overview) {
    if (!isActive) return 0.0;
    if (!isEligible(overview)) {
      // Przy niespełnieniu wymogów ESG wypłacana jest tylko zredukowana podstawa (70%).
      return annualBaseValueEur * 0.70;
    }
    return annualBaseValueEur + esgBonusValueEur;
  }

  GreenSponsorOffer copyWith({
    String? id,
    String? sponsorName,
    GreenSponsorCategory? category,
    double? annualBaseValueEur,
    double? esgBonusValueEur,
    double? requiredEsgScore,
    double? maxAllowedNetCo2Tons,
    bool? requiresZeroEmissionRaceCars,
    int? contractYears,
    bool? isActive,
    int? complianceStreakMonths,
  }) {
    return GreenSponsorOffer(
      id: id ?? this.id,
      sponsorName: sponsorName ?? this.sponsorName,
      category: category ?? this.category,
      annualBaseValueEur: annualBaseValueEur ?? this.annualBaseValueEur,
      esgBonusValueEur: esgBonusValueEur ?? this.esgBonusValueEur,
      requiredEsgScore: requiredEsgScore ?? this.requiredEsgScore,
      maxAllowedNetCo2Tons: maxAllowedNetCo2Tons ?? this.maxAllowedNetCo2Tons,
      requiresZeroEmissionRaceCars:
          requiresZeroEmissionRaceCars ?? this.requiresZeroEmissionRaceCars,
      contractYears: contractYears ?? this.contractYears,
      isActive: isActive ?? this.isActive,
      complianceStreakMonths:
          complianceStreakMonths ?? this.complianceStreakMonths,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sponsorName': sponsorName,
      'category': category.toJson(),
      'annualBaseValueEur': annualBaseValueEur,
      'esgBonusValueEur': esgBonusValueEur,
      'requiredEsgScore': requiredEsgScore,
      'maxAllowedNetCo2Tons': maxAllowedNetCo2Tons,
      'requiresZeroEmissionRaceCars': requiresZeroEmissionRaceCars,
      'contractYears': contractYears,
      'isActive': isActive,
      'complianceStreakMonths': complianceStreakMonths,
    };
  }

  factory GreenSponsorOffer.fromJson(Map<String, dynamic> json) {
    return GreenSponsorOffer(
      id: json['id']?.toString() ?? '',
      sponsorName: json['sponsorName']?.toString() ?? 'Green Partner',
      category: GreenSponsorCategory.fromJson(
        json['category']?.toString() ?? 'renewableEnergyUtility',
      ),
      annualBaseValueEur:
          (json['annualBaseValueEur'] as num?)?.toDouble() ?? 250000.0,
      esgBonusValueEur:
          (json['esgBonusValueEur'] as num?)?.toDouble() ?? 100000.0,
      requiredEsgScore: (json['requiredEsgScore'] as num?)?.toDouble() ?? 60.0,
      maxAllowedNetCo2Tons:
          (json['maxAllowedNetCo2Tons'] as num?)?.toDouble() ?? 120.0,
      requiresZeroEmissionRaceCars:
          json['requiresZeroEmissionRaceCars'] as bool? ?? false,
      contractYears: (json['contractYears'] as num?)?.toInt() ?? 2,
      isActive: json['isActive'] as bool? ?? false,
      complianceStreakMonths:
          (json['complianceStreakMonths'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Plan logistyczny konwoju przed konkretnym etapem wyścigu.
class StageConvoyLogisticsPlan {
  final String stageId;
  final String stageName;
  final double stageDistanceKm;
  final double elevationGainM;
  final double ambientTempC;
  final List<String> selectedVehicleIds;
  final int chargingStopsPlanned;
  final bool hasMobileSolarSupport;

  const StageConvoyLogisticsPlan({
    required this.stageId,
    required this.stageName,
    required this.stageDistanceKm,
    this.elevationGainM = 1200.0,
    this.ambientTempC = 20.0,
    this.selectedVehicleIds = const [],
    this.chargingStopsPlanned = 0,
    this.hasMobileSolarSupport = false,
  });
}

/// Raport gotowości energetycznej i emisyjnej konwoju przed etapem.
class ConvoyStageReadinessReport {
  final String stageId;
  final double totalConvoyCo2Kg;
  final double totalEnergyCostEur;
  final double minMarginRangeKm;
  final bool rangeAnxietyRisk;
  final List<String> bottleneckVehicleNames;
  final bool isFullyZeroEmission;
  final List<String> warnings;

  const ConvoyStageReadinessReport({
    required this.stageId,
    required this.totalConvoyCo2Kg,
    required this.totalEnergyCostEur,
    required this.minMarginRangeKm,
    required this.rangeAnxietyRisk,
    required this.bottleneckVehicleNames,
    required this.isFullyZeroEmission,
    required this.warnings,
  });
}

/// Zagregowany podgląd wskaźników ESG i bilansu węglowego zespołu.
class TeamEsgOverview {
  final double esgScore;
  final EsgRatingTier ratingTier;
  final double fleetElectrificationRatio;
  final bool allRaceCarsZeroEmission;
  final double totalEmissionsKg;
  final double totalOffsetsKg;
  final double netCarbonBalanceKg;
  final double annualBudgetEmissionsCapKg;
  final bool isCarbonNeutral;
  final int activeGreenSponsorsCount;
  final double projectedGreenSponsorRevenueEur;
  final bool uciCharterCompliant;

  const TeamEsgOverview({
    required this.esgScore,
    required this.ratingTier,
    required this.fleetElectrificationRatio,
    required this.allRaceCarsZeroEmission,
    required this.totalEmissionsKg,
    required this.totalOffsetsKg,
    required this.netCarbonBalanceKg,
    required this.annualBudgetEmissionsCapKg,
    required this.isCarbonNeutral,
    required this.activeGreenSponsorsCount,
    required this.projectedGreenSponsorRevenueEur,
    required this.uciCharterCompliant,
  });
}

/// Wynik operacji na modelu ESG i Zielonej Floty.
class EsgOperationResult<T> {
  final bool success;
  final String messagePl;
  final String messageEn;
  final T? data;

  const EsgOperationResult({
    required this.success,
    required this.messagePl,
    required this.messageEn,
    this.data,
  });
}

/// Główny model Ekonomii ESG i Zielonej Floty Zespołu (Zadanie #571).
class TeamEsgSustainabilityAndGreenFleetModel {
  final String teamId;
  final int seasonYear;
  final List<TeamFleetVehicle> vehicles;
  final ChargingInfrastructureTier infrastructureTier;
  final List<CarbonFootprintEntry> ledger;
  final List<GreenSponsorOffer> greenSponsors;
  final double annualCo2BudgetTons;
  final double carbonCreditPricePerTonEur;
  final bool railOverFlightPolicyEnabled;
  final bool recycledKitEnabled;
  final bool ecoBottleProgramEnabled;
  final double cashBalanceEur;

  const TeamEsgSustainabilityAndGreenFleetModel({
    required this.teamId,
    required this.seasonYear,
    required this.vehicles,
    required this.infrastructureTier,
    required this.ledger,
    required this.greenSponsors,
    this.annualCo2BudgetTons = 140.0,
    this.carbonCreditPricePerTonEur = 85.0,
    this.railOverFlightPolicyEnabled = false,
    this.recycledKitEnabled = false,
    this.ecoBottleProgramEnabled = false,
    this.cashBalanceEur = 1200000.0,
  });

  /// Tworzy startowy stan ESG dla zespołu WorldTour z mieszaną flotą i katalogiem zielonych sponsorów.
  factory TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour({
    required String teamId,
    int seasonYear = 2026,
    double cashBalanceEur = 1500000.0,
  }) {
    return TeamEsgSustainabilityAndGreenFleetModel(
      teamId: teamId,
      seasonYear: seasonYear,
      infrastructureTier: ChargingInfrastructureTier.depotFastCharger,
      railOverFlightPolicyEnabled: true,
      recycledKitEnabled: true,
      ecoBottleProgramEnabled: false,
      cashBalanceEur: cashBalanceEur,
      annualCo2BudgetTons: 120.0,
      vehicles: const [
        TeamFleetVehicle(
          id: 'veh_ds_1',
          name: 'Skoda Enyaq iV DS #1',
          vehicleType: FleetVehicleType.directorSportifCar,
          powertrain: PowertrainType.batteryElectric,
          batteryCapacityKwh: 82.0,
          wltpRangeKm: 530.0,
          co2GramsPerKm: 0.0,
          purchaseCostEur: 62000.0,
          annualMaintenanceEur: 3200.0,
          conditionPercent: 98.0,
          odometerKm: 14200.0,
          isActiveInRaceConvoy: true,
          assignedRoleLabel: 'DS Car #1',
        ),
        TeamFleetVehicle(
          id: 'veh_mech_1',
          name: 'Volvo V90 Recharge Support #2',
          vehicleType: FleetVehicleType.mechanicSupportCar,
          powertrain: PowertrainType.plugInHybrid,
          batteryCapacityKwh: 18.8,
          wltpRangeKm: 780.0,
          co2GramsPerKm: 42.0,
          purchaseCostEur: 74000.0,
          annualMaintenanceEur: 4900.0,
          conditionPercent: 94.0,
          odometerKm: 28500.0,
          isActiveInRaceConvoy: true,
          assignedRoleLabel: 'Mechanic #2',
        ),
        TeamFleetVehicle(
          id: 'veh_bus_1',
          name: 'Mercedes Tourismo Team Coach',
          vehicleType: FleetVehicleType.teamCoachBus,
          powertrain: PowertrainType.dieselEuro6,
          batteryCapacityKwh: 0.0,
          wltpRangeKm: 1100.0,
          co2GramsPerKm: 640.0,
          purchaseCostEur: 420000.0,
          annualMaintenanceEur: 18500.0,
          conditionPercent: 89.0,
          odometerKm: 64000.0,
          isActiveInRaceConvoy: true,
          assignedRoleLabel: 'Team Bus',
        ),
        TeamFleetVehicle(
          id: 'veh_truck_1',
          name: 'MAN eTGX Equipment Truck',
          vehicleType: FleetVehicleType.equipmentCargoTruck,
          powertrain: PowertrainType.batteryElectric,
          batteryCapacityKwh: 480.0,
          wltpRangeKm: 500.0,
          co2GramsPerKm: 0.0,
          purchaseCostEur: 310000.0,
          annualMaintenanceEur: 11000.0,
          conditionPercent: 97.0,
          odometerKm: 11800.0,
          isActiveInRaceConvoy: false,
          assignedRoleLabel: 'Service Course Truck',
        ),
      ],
      ledger: const [
        CarbonFootprintEntry(
          id: 'led_init_1',
          dateIso: '2026-01-15',
          category: CarbonLedgerCategory.hqOperations,
          description: 'Service Course Winter Operations',
          distanceKm: 0.0,
          co2KgDelta: 6200.0,
          costEur: 4100.0,
        ),
        CarbonFootprintEntry(
          id: 'led_init_2',
          dateIso: '2026-02-01',
          category: CarbonLedgerCategory.offsetCredit,
          description: 'Early Season Reforestation Offset (10 t CO2)',
          distanceKm: 0.0,
          co2KgDelta: -10000.0,
          costEur: 850.0,
        ),
      ],
      greenSponsors: const [
        GreenSponsorOffer(
          id: 'gsp_nordic_wind',
          sponsorName: 'NordicWind Energy',
          category: GreenSponsorCategory.renewableEnergyUtility,
          annualBaseValueEur: 450000.0,
          esgBonusValueEur: 250000.0,
          requiredEsgScore: 55.0,
          maxAllowedNetCo2Tons: 110.0,
          requiresZeroEmissionRaceCars: false,
          contractYears: 3,
          isActive: true,
          complianceStreakMonths: 4,
        ),
        GreenSponsorOffer(
          id: 'gsp_volt_mobility',
          sponsorName: 'VoltDrive Mobility',
          category: GreenSponsorCategory.electricMobility,
          annualBaseValueEur: 680000.0,
          esgBonusValueEur: 420000.0,
          requiredEsgScore: 75.0,
          maxAllowedNetCo2Tons: 60.0,
          requiresZeroEmissionRaceCars: true,
          contractYears: 3,
          isActive: false,
        ),
        GreenSponsorOffer(
          id: 'gsp_eco_weave',
          sponsorName: 'EcoWeave Cycling Apparel',
          category: GreenSponsorCategory.sustainableApparel,
          annualBaseValueEur: 280000.0,
          esgBonusValueEur: 140000.0,
          requiredEsgScore: 45.0,
          maxAllowedNetCo2Tons: 120.0,
          requiresZeroEmissionRaceCars: false,
          contractYears: 2,
          isActive: false,
        ),
      ],
    );
  }

  /// Tworzy startowy stan ESG dla mniejszej drużyny Continental.
  factory TeamEsgSustainabilityAndGreenFleetModel.createStarterContinental({
    required String teamId,
    int seasonYear = 2026,
    double cashBalanceEur = 320000.0,
  }) {
    return TeamEsgSustainabilityAndGreenFleetModel(
      teamId: teamId,
      seasonYear: seasonYear,
      infrastructureTier: ChargingInfrastructureTier.none,
      cashBalanceEur: cashBalanceEur,
      annualCo2BudgetTons: 85.0,
      vehicles: const [
        TeamFleetVehicle(
          id: 'veh_cont_ds_1',
          name: 'Team Wagon Diesel #1',
          vehicleType: FleetVehicleType.directorSportifCar,
          powertrain: PowertrainType.dieselEuro6,
          batteryCapacityKwh: 0.0,
          wltpRangeKm: 920.0,
          co2GramsPerKm: 158.0,
          purchaseCostEur: 36000.0,
          annualMaintenanceEur: 4200.0,
          conditionPercent: 86.0,
          odometerKm: 52000.0,
          isActiveInRaceConvoy: true,
          assignedRoleLabel: 'DS Car #1',
        ),
        TeamFleetVehicle(
          id: 'veh_cont_van_1',
          name: 'Continental Team Van',
          vehicleType: FleetVehicleType.medicalAndKitchenVan,
          powertrain: PowertrainType.mildHybrid,
          batteryCapacityKwh: 2.0,
          wltpRangeKm: 800.0,
          co2GramsPerKm: 142.0,
          purchaseCostEur: 49000.0,
          annualMaintenanceEur: 4600.0,
          conditionPercent: 91.0,
          odometerKm: 31000.0,
          isActiveInRaceConvoy: true,
          assignedRoleLabel: 'Rider Van',
        ),
      ],
      ledger: const [],
      greenSponsors: const [
        GreenSponsorOffer(
          id: 'gsp_bio_fuel',
          sponsorName: 'BioPulse Organic Nutrition',
          category: GreenSponsorCategory.organicNutrition,
          annualBaseValueEur: 120000.0,
          esgBonusValueEur: 65000.0,
          requiredEsgScore: 40.0,
          maxAllowedNetCo2Tons: 80.0,
          requiresZeroEmissionRaceCars: false,
          contractYears: 2,
          isActive: false,
        ),
      ],
    );
  }

  /// Wylicza bieżący przegląd wskaźników ESG, bilans CO2 oraz przychody od zielonych sponsorów.
  TeamEsgOverview computeOverview() {
    final double electrificationRatio = vehicles.isEmpty
        ? 0.0
        : vehicles
                .map((v) => v.powertrain.electrificationWeight)
                .reduce((a, b) => a + b) /
            vehicles.length;

    final raceCars = vehicles
        .where(
          (v) =>
              v.isActiveInRaceConvoy &&
              (v.vehicleType == FleetVehicleType.directorSportifCar ||
                  v.vehicleType == FleetVehicleType.mechanicSupportCar),
        )
        .toList();
    final bool allRaceCarsZeroEmission =
        raceCars.isNotEmpty && raceCars.every((v) => v.isZeroEmission);

    double totalEmissionsKg = 0.0;
    double totalOffsetsKg = 0.0;
    for (final entry in ledger) {
      if (entry.co2KgDelta >= 0) {
        totalEmissionsKg += entry.co2KgDelta;
      } else {
        totalOffsetsKg += entry.co2KgDelta.abs();
      }
    }

    final double netCarbonBalanceKg = totalEmissionsKg - totalOffsetsKg;
    final double annualCapKg = math.max(1000.0, annualCo2BudgetTons * 1000.0);
    final bool isCarbonNeutral = netCarbonBalanceKg <= 0.0;

    // Punktacja ESG (0–100 pkt):
    // 1) Elektryfikacja floty: max 35 pkt
    final double fleetScore = electrificationRatio * 35.0;

    // 2) Bilans CO2 względem budżetu rocznego: max 30 pkt
    final double carbonRatio = (netCarbonBalanceKg / annualCapKg).clamp(-0.5, 2.0);
    final double carbonScore = carbonRatio <= 0.0
        ? 30.0
        : (30.0 * (1.0 - (carbonRatio / 1.5))).clamp(0.0, 30.0);

    // 3) Infrastruktura ładowania i OZE: max 15 pkt
    final double infraScore = infrastructureTier.esgScorePoints;

    // 4) Polityki zrównoważone zespołu: max 20 pkt
    double policyScore = 0.0;
    if (railOverFlightPolicyEnabled) policyScore += 9.0;
    if (recycledKitEnabled) policyScore += 6.0;
    if (ecoBottleProgramEnabled) policyScore += 5.0;

    final double esgScore =
        (fleetScore + carbonScore + infraScore + policyScore).clamp(0.0, 100.0);
    final EsgRatingTier ratingTier = EsgRatingTier.fromScore(esgScore);
    final bool uciCharterCompliant =
        esgScore >= 60.0 && netCarbonBalanceKg <= annualCapKg;

    final preliminaryOverview = TeamEsgOverview(
      esgScore: esgScore,
      ratingTier: ratingTier,
      fleetElectrificationRatio: electrificationRatio,
      allRaceCarsZeroEmission: allRaceCarsZeroEmission,
      totalEmissionsKg: totalEmissionsKg,
      totalOffsetsKg: totalOffsetsKg,
      netCarbonBalanceKg: netCarbonBalanceKg,
      annualBudgetEmissionsCapKg: annualCapKg,
      isCarbonNeutral: isCarbonNeutral,
      activeGreenSponsorsCount: greenSponsors.where((s) => s.isActive).length,
      projectedGreenSponsorRevenueEur: 0.0,
      uciCharterCompliant: uciCharterCompliant,
    );

    double projectedRevenue = 0.0;
    for (final sponsor in greenSponsors) {
      if (sponsor.isActive) {
        projectedRevenue += sponsor.effectiveAnnualPayoutEur(preliminaryOverview);
      }
    }

    return TeamEsgOverview(
      esgScore: esgScore,
      ratingTier: ratingTier,
      fleetElectrificationRatio: electrificationRatio,
      allRaceCarsZeroEmission: allRaceCarsZeroEmission,
      totalEmissionsKg: totalEmissionsKg,
      totalOffsetsKg: totalOffsetsKg,
      netCarbonBalanceKg: netCarbonBalanceKg,
      annualBudgetEmissionsCapKg: annualCapKg,
      isCarbonNeutral: isCarbonNeutral,
      activeGreenSponsorsCount: preliminaryOverview.activeGreenSponsorsCount,
      projectedGreenSponsorRevenueEur: projectedRevenue,
      uciCharterCompliant: uciCharterCompliant,
    );
  }

  /// Kupuje nowy pojazd do floty lub wymienia wskazany stary pojazd (z wartością rezydualną 40%).
  EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel>
      purchaseOrUpgradeVehicle(
    TeamFleetVehicle newVehicle, {
    String? replaceVehicleId,
  }) {
    if (vehicles.any((v) => v.id == newVehicle.id)) {
      return const EsgOperationResult(
        success: false,
        messagePl: 'Pojazd o tym identyfikatorze już istnieje we flocie.',
        messageEn: 'A vehicle with this ID already exists in the fleet.',
      );
    }

    double tradeInValue = 0.0;
    final updatedVehicles = List<TeamFleetVehicle>.from(vehicles);
    if (replaceVehicleId != null) {
      final idx = updatedVehicles.indexWhere((v) => v.id == replaceVehicleId);
      if (idx == -1) {
        return const EsgOperationResult(
          success: false,
          messagePl: 'Nie znaleziono pojazdu do wymiany.',
          messageEn: 'Vehicle to replace was not found.',
        );
      }
      final oldVehicle = updatedVehicles[idx];
      tradeInValue =
          oldVehicle.purchaseCostEur * 0.40 * (oldVehicle.conditionPercent / 100.0);
      updatedVehicles[idx] = newVehicle;
    } else {
      updatedVehicles.add(newVehicle);
    }

    final double netCost = math.max(0.0, newVehicle.purchaseCostEur - tradeInValue);
    if (cashBalanceEur < netCost) {
      return EsgOperationResult(
        success: false,
        messagePl:
            'Niewystarczające środki (${cashBalanceEur.toStringAsFixed(0)} € < ${netCost.toStringAsFixed(0)} €).',
        messageEn:
            'Insufficient funds (${cashBalanceEur.toStringAsFixed(0)} € < ${netCost.toStringAsFixed(0)} €).',
      );
    }

    final updated = copyWith(
      vehicles: updatedVehicles,
      cashBalanceEur: cashBalanceEur - netCost,
    );

    return EsgOperationResult(
      success: true,
      messagePl: 'Dodano ${newVehicle.name} do zielonej floty zespołu.',
      messageEn: 'Added ${newVehicle.name} to the team green fleet.',
      data: updated,
    );
  }

  /// Ulepsza infrastrukturę ładowania i OZE w bazie / na wyścigach.
  EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel>
      upgradeChargingInfrastructure(ChargingInfrastructureTier targetTier) {
    if (targetTier.index <= infrastructureTier.index) {
      return const EsgOperationResult(
        success: false,
        messagePl: 'Zespół posiada już ten lub wyższy poziom infrastruktury.',
        messageEn: 'The team already operates this or a higher infrastructure tier.',
      );
    }

    final double cost = targetTier.upgradeCostEur;
    if (cashBalanceEur < cost) {
      return const EsgOperationResult(
        success: false,
        messagePl: 'Brak wystarczających środków na modernizację stacji ładowania.',
        messageEn: 'Insufficient funds for charging infrastructure upgrade.',
      );
    }

    final updated = copyWith(
      infrastructureTier: targetTier,
      cashBalanceEur: cashBalanceEur - cost,
    );

    return EsgOperationResult(
      success: true,
      messagePl: 'Zainstalowano: ${targetTier.displayNamePl}.',
      messageEn: 'Installed: ${targetTier.displayNameEn}.',
      data: updated,
    );
  }

  /// Ocenia gotowość energetyczną i emisję konwoju na dany etap wyścigu.
  ConvoyStageReadinessReport evaluateStageConvoyReadiness(
    StageConvoyLogisticsPlan plan,
  ) {
    final selected = plan.selectedVehicleIds.isEmpty
        ? vehicles.where((v) => v.isActiveInRaceConvoy).toList()
        : vehicles
            .where((v) => plan.selectedVehicleIds.contains(v.id))
            .toList();

    if (selected.isEmpty) {
      return ConvoyStageReadinessReport(
        stageId: plan.stageId,
        totalConvoyCo2Kg: 0.0,
        totalEnergyCostEur: 0.0,
        minMarginRangeKm: 0.0,
        rangeAnxietyRisk: true,
        bottleneckVehicleNames: const [],
        isFullyZeroEmission: false,
        warnings: const ['Brak aktywnych pojazdów w konwoju etapowym.'],
      );
    }

    // Konwój pokonuje dystans etapu + ok. 35 km dojazdów start/meta.
    final double convoyTripKm = plan.stageDistanceKm + 35.0;
    double totalCo2Kg = 0.0;
    double totalEnergyCost = 0.0;
    double minMarginKm = double.infinity;
    final bottlenecks = <String>[];
    final warnings = <String>[];

    final double gridReduction =
        (plan.hasMobileSolarSupport ? 0.50 : infrastructureTier.gridCarbonReductionFactor)
            .clamp(0.0, 0.95);

    for (final v in selected) {
      double vehicleCo2GramsPerKm = v.co2GramsPerKm;
      if (v.powertrain == PowertrainType.batteryElectric) {
        // Pośredni ślad sieciowy przy ładowaniu elektryków (bazowo 28 g/km zredukowany przez PV).
        vehicleCo2GramsPerKm = 28.0 * (1.0 - gridReduction);
      }

      totalCo2Kg += (vehicleCo2GramsPerKm * convoyTripKm) / 1000.0;
      totalEnergyCost += (convoyTripKm / 100.0) * v.energyCostPer100KmEur;

      final double baseRange = v.effectiveRangeKm(
        elevationGainM: plan.elevationGainM,
        ambientTempC: plan.ambientTempC,
      );
      final double chargingBonusKm =
          (v.powertrain == PowertrainType.batteryElectric ||
                  v.powertrain == PowertrainType.plugInHybrid)
              ? plan.chargingStopsPlanned * (baseRange * 0.45)
              : 0.0;

      final double margin = (baseRange + chargingBonusKm) - convoyTripKm;
      if (margin < minMarginKm) {
        minMarginKm = margin;
      }
      if (margin < 30.0) {
        bottlenecks.add(v.name);
        warnings.add(
          'Niski zapas zasięgu dla ${v.name} (margines ${margin.toStringAsFixed(0)} km).',
        );
      }
    }

    final bool isZeroEmission = selected.every((v) => v.isZeroEmission);
    final bool rangeAnxiety = bottlenecks.isNotEmpty;

    return ConvoyStageReadinessReport(
      stageId: plan.stageId,
      totalConvoyCo2Kg: totalCo2Kg,
      totalEnergyCostEur: totalEnergyCost,
      minMarginRangeKm: minMarginKm.isFinite ? minMarginKm : 0.0,
      rangeAnxietyRisk: rangeAnxiety,
      bottleneckVehicleNames: bottlenecks,
      isFullyZeroEmission: isZeroEmission,
      warnings: warnings,
    );
  }

  /// Rejestruje przejazd konwoju wyścigowego na etapie, aktualizując przebieg i bilans CO2.
  EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel>
      recordRaceConvoyTrip({
    required String stageId,
    required String stageName,
    required double distanceKm,
    required double elevationGainM,
    required double ambientTempC,
    required String dateIso,
  }) {
    if (distanceKm <= 0) {
      return const EsgOperationResult(
        success: false,
        messagePl: 'Dystans etapu musi być dodatni.',
        messageEn: 'Stage distance must be positive.',
      );
    }

    final plan = StageConvoyLogisticsPlan(
      stageId: stageId,
      stageName: stageName,
      stageDistanceKm: distanceKm,
      elevationGainM: elevationGainM,
      ambientTempC: ambientTempC,
      hasMobileSolarSupport:
          infrastructureTier == ChargingInfrastructureTier.mobileSolarBatteryTrailer ||
              infrastructureTier == ChargingInfrastructureTier.solarMicrogridHq,
    );
    final report = evaluateStageConvoyReadiness(plan);

    final double convoyTripKm = distanceKm + 35.0;
    final updatedVehicles = vehicles.map((v) {
      if (!v.isActiveInRaceConvoy) return v;
      return v.copyWith(
        odometerKm: v.odometerKm + convoyTripKm,
        conditionPercent: (v.conditionPercent - 0.15).clamp(20.0, 100.0),
      );
    }).toList();

    final entry = CarbonFootprintEntry(
      id: 'led_stage_${stageId}_${ledger.length + 1}',
      dateIso: dateIso,
      category: CarbonLedgerCategory.fleetConvoy,
      description: 'Konwój wyścigowy: $stageName',
      distanceKm: convoyTripKm,
      co2KgDelta: report.totalConvoyCo2Kg,
      costEur: report.totalEnergyCostEur,
      raceId: stageId,
    );

    final updated = copyWith(
      vehicles: updatedVehicles,
      ledger: [...ledger, entry],
      cashBalanceEur: cashBalanceEur - report.totalEnergyCostEur,
    );

    return EsgOperationResult(
      success: true,
      messagePl:
          'Zarejestrowano przejazd konwoju ($stageName): ${report.totalConvoyCo2Kg.toStringAsFixed(1)} kg CO₂.',
      messageEn:
          'Recorded convoy trip ($stageName): ${report.totalConvoyCo2Kg.toStringAsFixed(1)} kg CO₂.',
      data: updated,
    );
  }

  /// Rejestruje podróż delegacji zespołu (loty vs kolej dużych prędkości / autokar).
  EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel> recordTeamTravel({
    required String description,
    required TravelTransportMode mode,
    required double distanceKm,
    required int delegationSize,
    required String dateIso,
    String? raceId,
  }) {
    if (distanceKm <= 0 || delegationSize <= 0) {
      return const EsgOperationResult(
        success: false,
        messagePl: 'Dystans i wielkość delegacji muszą być dodatnie.',
        messageEn: 'Distance and delegation size must be positive.',
      );
    }

    // Jeśli polityka kolejowa jest włączona, krótkie loty < 700 km automatycznie zamieniane są na kolej.
    final TravelTransportMode effectiveMode =
        (railOverFlightPolicyEnabled &&
                mode == TravelTransportMode.shortHaulFlight &&
                distanceKm <= 700.0)
            ? TravelTransportMode.highSpeedRail
            : mode;

    final double passengerKm = distanceKm * delegationSize;
    final double co2Kg = passengerKm * effectiveMode.kgCo2PerPassengerKm;
    final double costEur = passengerKm * effectiveMode.costEurPerPassengerKm;

    final entry = CarbonFootprintEntry(
      id: 'led_travel_${ledger.length + 1}',
      dateIso: dateIso,
      category: CarbonLedgerCategory.teamTravel,
      description: description,
      distanceKm: distanceKm,
      co2KgDelta: co2Kg,
      costEur: costEur,
      raceId: raceId,
    );

    final updated = copyWith(
      ledger: [...ledger, entry],
      cashBalanceEur: cashBalanceEur - costEur,
    );

    return EsgOperationResult(
      success: true,
      messagePl:
          'Podróż zespołu ($description): ${co2Kg.toStringAsFixed(1)} kg CO₂.',
      messageEn:
          'Team travel ($description): ${co2Kg.toStringAsFixed(1)} kg CO₂.',
      data: updated,
    );
  }

  /// Kupuje certyfikaty kompensacji CO2 (Carbon Offsets), zmniejszając bilans netto.
  EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel>
      purchaseCarbonOffsets({
    required double tonsCo2,
    required CarbonOffsetProgramType program,
    required String dateIso,
  }) {
    if (tonsCo2 <= 0) {
      return const EsgOperationResult(
        success: false,
        messagePl: 'Wolumen kompensacji musi być większy od zera.',
        messageEn: 'Offset volume must be greater than zero.',
      );
    }

    final double totalCost =
        tonsCo2 * carbonCreditPricePerTonEur * program.priceMultiplier;
    if (cashBalanceEur < totalCost) {
      return const EsgOperationResult(
        success: false,
        messagePl: 'Niewystarczające środki na zakup kredytów węglowych.',
        messageEn: 'Insufficient funds to purchase carbon offsets.',
      );
    }

    final entry = CarbonFootprintEntry(
      id: 'led_offset_${ledger.length + 1}',
      dateIso: dateIso,
      category: CarbonLedgerCategory.offsetCredit,
      description:
          'Kompensacja ${tonsCo2.toStringAsFixed(1)} t CO₂ (${program.displayNamePl})',
      distanceKm: 0.0,
      co2KgDelta: -(tonsCo2 * 1000.0),
      costEur: totalCost,
    );

    final updated = copyWith(
      ledger: [...ledger, entry],
      cashBalanceEur: cashBalanceEur - totalCost,
    );

    return EsgOperationResult(
      success: true,
      messagePl:
          'Skupiono kompensację ${tonsCo2.toStringAsFixed(1)} t CO₂ za ${totalCost.toStringAsFixed(0)} €.',
      messageEn:
          'Purchased ${tonsCo2.toStringAsFixed(1)} t CO₂ offsets for ${totalCost.toStringAsFixed(0)} €.',
      data: updated,
    );
  }

  /// Podpisuje kontrakt z zielonym sponsorem, jeśli zespół spełnia progi ESG.
  EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel> signGreenSponsor(
    String sponsorId,
  ) {
    final idx = greenSponsors.indexWhere((s) => s.id == sponsorId);
    if (idx == -1) {
      return const EsgOperationResult(
        success: false,
        messagePl: 'Nie znaleziono oferty zielonego sponsora.',
        messageEn: 'Green sponsor offer not found.',
      );
    }

    final target = greenSponsors[idx];
    if (target.isActive) {
      return const EsgOperationResult(
        success: false,
        messagePl: 'Kontrakt z tym sponsorem jest już aktywny.',
        messageEn: 'This green sponsor contract is already active.',
      );
    }

    final overview = computeOverview();
    if (!target.isEligible(overview)) {
      return EsgOperationResult(
        success: false,
        messagePl:
            'Zespół nie spełnia jeszcze wymogów ESG sponsora ${target.sponsorName} (wymagane ${target.requiredEsgScore.toStringAsFixed(0)} pkt).',
        messageEn:
            'Team does not meet ESG requirements for ${target.sponsorName} (requires ${target.requiredEsgScore.toStringAsFixed(0)} pts).',
      );
    }

    final updatedSponsors = List<GreenSponsorOffer>.from(greenSponsors);
    updatedSponsors[idx] = target.copyWith(isActive: true);

    return EsgOperationResult(
      success: true,
      messagePl: 'Podpisano umowę z zielonym sponsorem ${target.sponsorName}.',
      messageEn: 'Signed green sponsor deal with ${target.sponsorName}.',
      data: copyWith(greenSponsors: updatedSponsors),
    );
  }

  /// Wypłaca roczne środki od aktywnych zielonych sponsorów (z premią za cele ESG).
  EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel>
      collectAnnualGreenSponsorPayouts() {
    final overview = computeOverview();
    final double payout = overview.projectedGreenSponsorRevenueEur;
    if (payout <= 0) {
      return const EsgOperationResult(
        success: false,
        messagePl: 'Brak aktywnych zielonych sponsorów do rozliczenia.',
        messageEn: 'No active green sponsors to settle.',
      );
    }

    final updatedSponsors = greenSponsors.map((s) {
      if (!s.isActive) return s;
      return s.copyWith(
        complianceStreakMonths:
            s.isEligible(overview) ? s.complianceStreakMonths + 12 : 0,
      );
    }).toList();

    return EsgOperationResult(
      success: true,
      messagePl:
          'Zaksięgowano ${payout.toStringAsFixed(0)} € od zielonych sponsorów.',
      messageEn:
          'Settled ${payout.toStringAsFixed(0)} € from green sponsors.',
      data: copyWith(
        greenSponsors: updatedSponsors,
        cashBalanceEur: cashBalanceEur + payout,
      ),
    );
  }

  /// Przełącza wewnętrzne polityki zrównoważonego rozwoju zespołu.
  TeamEsgSustainabilityAndGreenFleetModel togglePolicy({
    bool? railOverFlight,
    bool? recycledKit,
    bool? ecoBottles,
  }) {
    return copyWith(
      railOverFlightPolicyEnabled: railOverFlight ?? railOverFlightPolicyEnabled,
      recycledKitEnabled: recycledKit ?? recycledKitEnabled,
      ecoBottleProgramEnabled: ecoBottles ?? ecoBottleProgramEnabled,
    );
  }

  TeamEsgSustainabilityAndGreenFleetModel copyWith({
    String? teamId,
    int? seasonYear,
    List<TeamFleetVehicle>? vehicles,
    ChargingInfrastructureTier? infrastructureTier,
    List<CarbonFootprintEntry>? ledger,
    List<GreenSponsorOffer>? greenSponsors,
    double? annualCo2BudgetTons,
    double? carbonCreditPricePerTonEur,
    bool? railOverFlightPolicyEnabled,
    bool? recycledKitEnabled,
    bool? ecoBottleProgramEnabled,
    double? cashBalanceEur,
  }) {
    return TeamEsgSustainabilityAndGreenFleetModel(
      teamId: teamId ?? this.teamId,
      seasonYear: seasonYear ?? this.seasonYear,
      vehicles: vehicles ?? this.vehicles,
      infrastructureTier: infrastructureTier ?? this.infrastructureTier,
      ledger: ledger ?? this.ledger,
      greenSponsors: greenSponsors ?? this.greenSponsors,
      annualCo2BudgetTons: annualCo2BudgetTons ?? this.annualCo2BudgetTons,
      carbonCreditPricePerTonEur:
          carbonCreditPricePerTonEur ?? this.carbonCreditPricePerTonEur,
      railOverFlightPolicyEnabled:
          railOverFlightPolicyEnabled ?? this.railOverFlightPolicyEnabled,
      recycledKitEnabled: recycledKitEnabled ?? this.recycledKitEnabled,
      ecoBottleProgramEnabled:
          ecoBottleProgramEnabled ?? this.ecoBottleProgramEnabled,
      cashBalanceEur: cashBalanceEur ?? this.cashBalanceEur,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'seasonYear': seasonYear,
      'vehicles': vehicles.map((v) => v.toJson()).toList(),
      'infrastructureTier': infrastructureTier.toJson(),
      'ledger': ledger.map((e) => e.toJson()).toList(),
      'greenSponsors': greenSponsors.map((s) => s.toJson()).toList(),
      'annualCo2BudgetTons': annualCo2BudgetTons,
      'carbonCreditPricePerTonEur': carbonCreditPricePerTonEur,
      'railOverFlightPolicyEnabled': railOverFlightPolicyEnabled,
      'recycledKitEnabled': recycledKitEnabled,
      'ecoBottleProgramEnabled': ecoBottleProgramEnabled,
      'cashBalanceEur': cashBalanceEur,
    };
  }

  factory TeamEsgSustainabilityAndGreenFleetModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawVehicles = json['vehicles'] as List<dynamic>? ?? const [];
    final rawLedger = json['ledger'] as List<dynamic>? ?? const [];
    final rawSponsors = json['greenSponsors'] as List<dynamic>? ?? const [];

    return TeamEsgSustainabilityAndGreenFleetModel(
      teamId: json['teamId']?.toString() ?? 'team_default',
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      vehicles: rawVehicles
          .whereType<Map<String, dynamic>>()
          .map(TeamFleetVehicle.fromJson)
          .toList(),
      infrastructureTier: ChargingInfrastructureTier.fromJson(
        json['infrastructureTier']?.toString() ?? 'none',
      ),
      ledger: rawLedger
          .whereType<Map<String, dynamic>>()
          .map(CarbonFootprintEntry.fromJson)
          .toList(),
      greenSponsors: rawSponsors
          .whereType<Map<String, dynamic>>()
          .map(GreenSponsorOffer.fromJson)
          .toList(),
      annualCo2BudgetTons:
          (json['annualCo2BudgetTons'] as num?)?.toDouble() ?? 140.0,
      carbonCreditPricePerTonEur:
          (json['carbonCreditPricePerTonEur'] as num?)?.toDouble() ?? 85.0,
      railOverFlightPolicyEnabled:
          json['railOverFlightPolicyEnabled'] as bool? ?? false,
      recycledKitEnabled: json['recycledKitEnabled'] as bool? ?? false,
      ecoBottleProgramEnabled: json['ecoBottleProgramEnabled'] as bool? ?? false,
      cashBalanceEur: (json['cashBalanceEur'] as num?)?.toDouble() ?? 1200000.0,
    );
  }
}
