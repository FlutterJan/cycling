// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../core/constants/physics_constants.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider_physiology.dart';
import '../../models/rider/rider_skills.dart';
import '../../services/career/equipment_sponsorship_bidding_engine.dart';

/// Typ mikroklimatu i warunków atmosferycznych na trasie etapu.
enum MountainWeatherType {
  /// Słoneczna, ciepła dolina
  sunnyValley,

  /// Umiarkowane zachmurzenie w terenie pagórkowatym
  partlyCloudy,

  /// Gęste, niskie chmury na płaskowyżu
  overcastPlateau,

  /// Wilgotna mgła na podejściu pod szczyt
  mountainMist,

  /// Gęsta chmura i mgła wysokogórska ograniczająca widoczność
  alpineFog,

  /// Lekka mżawka górska
  lightDrizzle,

  /// Ulewny deszcz alpejski
  heavyRain,

  /// Marznący deszcz na wysokich przełęczach (Freezing Rain)
  freezingRain,

  /// Grad i deszcz ze śniegiem (Sleet / Hail)
  sleetHail,

  /// Porywisty wicher graniowy / orograficzny (Ridge Gale)
  ridgeGale,

  /// Fala upałów w osłoniętej kotlinie górskiej
  heatWave;

  String toJson() => name;

  static MountainWeatherType fromJson(String value) {
    return MountainWeatherType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MountainWeatherType.sunnyValley,
    );
  }

  /// Mapowanie na standardową klasę [WeatherCondition] silnika wyścigu
  WeatherCondition toStandardCondition() {
    switch (this) {
      case MountainWeatherType.sunnyValley:
        return WeatherCondition.sunny;
      case MountainWeatherType.partlyCloudy:
      case MountainWeatherType.overcastPlateau:
      case MountainWeatherType.mountainMist:
      case MountainWeatherType.alpineFog:
        return WeatherCondition.overcast;
      case MountainWeatherType.lightDrizzle:
        return WeatherCondition.lightRain;
      case MountainWeatherType.heavyRain:
      case MountainWeatherType.freezingRain:
      case MountainWeatherType.sleetHail:
        return WeatherCondition.heavyStorm;
      case MountainWeatherType.ridgeGale:
        return WeatherCondition.crosswindGale;
      case MountainWeatherType.heatWave:
        return WeatherCondition.extremeHeat;
    }
  }

  /// Czy dany typ pogody niesie wilgoć i opady
  bool get hasPrecipitation {
    return this == MountainWeatherType.lightDrizzle ||
        this == MountainWeatherType.heavyRain ||
        this == MountainWeatherType.freezingRain ||
        this == MountainWeatherType.sleetHail;
  }

  /// Czy opady są marznące / ekstremalnie zimne
  bool get isFreezingCondition {
    return this == MountainWeatherType.freezingRain ||
        this == MountainWeatherType.sleetHail;
  }

  /// Polska nazwa opisowa
  String get displayNamePl {
    switch (this) {
      case MountainWeatherType.sunnyValley:
        return 'Słoneczna Dolina';
      case MountainWeatherType.partlyCloudy:
        return 'Umiarkowane Zachmurzenie';
      case MountainWeatherType.overcastPlateau:
        return 'Pochmurny Płaskowyż';
      case MountainWeatherType.mountainMist:
        return 'Górska Mgiełka';
      case MountainWeatherType.alpineFog:
        return 'Gęsta Mgła Alpejska';
      case MountainWeatherType.lightDrizzle:
        return 'Chłodna Mżawka';
      case MountainWeatherType.heavyRain:
        return 'Alpejska Ulewa';
      case MountainWeatherType.freezingRain:
        return 'Marznący Deszcz Graniowy';
      case MountainWeatherType.sleetHail:
        return 'Deszcz ze Śniegiem i Grad';
      case MountainWeatherType.ridgeGale:
        return 'Porywisty Wichr Graniowy';
      case MountainWeatherType.heatWave:
        return 'Upał Kotliny Górskiej';
    }
  }
}

/// Stan nawierzchni szosy w danym punkcie trasy.
enum RoadSurfaceState {
  /// Suchy, rozgrzany asfalt (maksymalna przyczepność)
  dry,

  /// Wilgotny asfalt (początek deszczu lub po przejściu chmury)
  damp,

  /// Mokry asfalt z filmem wodnym
  wet,

  /// Stojąca woda, spływające strugi deszczu (ryzyko aquaplaningu)
  standingWaterSpray,

  /// Marznąca maź / czarny lód na przełęczy (skrajnie śliska nawierzchnia)
  freezingGlaze;

  String toJson() => name;

  static RoadSurfaceState fromJson(String value) {
    return RoadSurfaceState.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RoadSurfaceState.dry,
    );
  }

  /// Współczynnik przyczepności opon (1.0 = suchy asfalt)
  double get gripFactor {
    switch (this) {
      case RoadSurfaceState.dry:
        return 1.00;
      case RoadSurfaceState.damp:
        return 0.90;
      case RoadSurfaceState.wet:
        return 0.74;
      case RoadSurfaceState.standingWaterSpray:
        return 0.62;
      case RoadSurfaceState.freezingGlaze:
        return 0.38;
    }
  }

  /// Mnożnik oporów toczenia opon Crr na mokrej nawierzchni
  double get rollingResistanceMultiplier {
    switch (this) {
      case RoadSurfaceState.dry:
        return 1.00;
      case RoadSurfaceState.damp:
        return 1.08;
      case RoadSurfaceState.wet:
        return 1.22;
      case RoadSurfaceState.standingWaterSpray:
        return 1.45;
      case RoadSurfaceState.freezingGlaze:
        return 1.35;
    }
  }

  /// Zwiększenie ryzyka kraksy na zjazdach
  double get descentCrashRiskMultiplier {
    switch (this) {
      case RoadSurfaceState.dry:
        return 1.0;
      case RoadSurfaceState.damp:
        return 1.4;
      case RoadSurfaceState.wet:
        return 2.2;
      case RoadSurfaceState.standingWaterSpray:
        return 3.2;
      case RoadSurfaceState.freezingGlaze:
        return 5.5;
    }
  }
}

/// Element odzieży termicznej i ochronnej kolarza.
enum RiderClothingType {
  /// Standardowy letni kombinezon / koszulka aero (brak ochrony przed deszczem)
  summerAeroJersey,

  /// Lekka kamizelka wiatroszczelna (Gilet) – chroni klatkę piersiową przed podmuchami
  windGilet,

  /// Profesjonalna kurtka przeciwdeszczowa z membraną hydrofobową (np. Gore-Tex Shakedry / Gabba)
  rainJacket,

  /// Ocieplana kurtka neoprenowo-termiczna na arktyczne warunki i śnieg
  thermalWinterJacket;

  String toJson() => name;

  static RiderClothingType fromJson(String value) {
    return RiderClothingType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RiderClothingType.summerAeroJersey,
    );
  }

  /// Współczynnik izolacji termicznej odzieży w jednostkach clo
  double get thermalInsulationClo {
    switch (this) {
      case RiderClothingType.summerAeroJersey:
        return 0.12;
      case RiderClothingType.windGilet:
        return 0.42;
      case RiderClothingType.rainJacket:
        return 0.88;
      case RiderClothingType.thermalWinterJacket:
        return 1.45;
    }
  }

  /// Skuteczność ochrony przed wiatrem (wind block factor: 0.0 = przewiewny, 1.0 = całkowicie szczelny)
  double get windBlockEfficiency {
    switch (this) {
      case RiderClothingType.summerAeroJersey:
        return 0.15;
      case RiderClothingType.windGilet:
        return 0.70;
      case RiderClothingType.rainJacket:
        return 0.95;
      case RiderClothingType.thermalWinterJacket:
        return 0.98;
    }
  }

  /// Bariera wodna (hydrofobowość: 0.0 = natychmiast przemaka, 1.0 = całkowicie nieprzemakalna)
  double get waterproofProtection {
    switch (this) {
      case RiderClothingType.summerAeroJersey:
        return 0.05;
      case RiderClothingType.windGilet:
        return 0.40;
      case RiderClothingType.rainJacket:
        return 0.96;
      case RiderClothingType.thermalWinterJacket:
        return 0.98;
    }
  }

  /// Bazowy narzut oporu aerodynamicznego CdA [m^2] wynikający z luźniejszego kroju / trzepotania materiału
  double get baseCdaPenalty {
    switch (this) {
      case RiderClothingType.summerAeroJersey:
        return 0.0;
      case RiderClothingType.windGilet:
        return 0.008; // Delikatne powiewanie kamizelki
      case RiderClothingType.rainJacket:
        return 0.024; // Trzepocząca kurtka membranowa (+15-22W przy 50 km/h)
      case RiderClothingType.thermalWinterJacket:
        return 0.034; // Gruba zimowa kurtka
    }
  }
}

/// Poziom hipotermii (wychłodzenia organizmu).
enum HypothermiaStage {
  /// Brak hipotermii – temperatura głęboka w normie (36.5°C - 37.5°C)
  none,

  /// Lekka hipotermia (35.5°C - 36.5°C) – dreszcze, zimne stopy, gęsia skórka
  mildShivering,

  /// Umiarkowana hipotermia (34.0°C - 35.5°C) – silne drgawki, zdrętwiałe dłonie, utrata mocy
  moderate,

  /// Ciężka hipotermia (< 34.0°C) – sztywność mięśni, brak kontroli nad rowerem, ryzyko DNF
  severe;

  String toJson() => name;

  static HypothermiaStage fromJson(String value) {
    return HypothermiaStage.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => HypothermiaStage.none,
    );
  }

  /// Spadek mocy kolarza w procentach (Power Loss)
  double get powerLossPercent {
    switch (this) {
      case HypothermiaStage.none:
        return 0.0;
      case HypothermiaStage.mildShivering:
        return 8.5; // -8.5% mocy
      case HypothermiaStage.moderate:
        return 26.0; // -26% mocy (spadek FTP)
      case HypothermiaStage.severe:
        return 52.0; // -52% mocy (krytyczny spadek wydolności)
    }
  }

  /// Kara do umiejętności zjazdowych (brak czucia w palcach na klamkach hamulców)
  double get descendingPenaltyPercent {
    switch (this) {
      case HypothermiaStage.none:
        return 0.0;
      case HypothermiaStage.mildShivering:
        return 12.0;
      case HypothermiaStage.moderate:
        return 38.0;
      case HypothermiaStage.severe:
        return 75.0;
    }
  }
}

/// Poziom hipertermii (przegrzania organizmu).
enum HyperthermiaStage {
  /// Norma
  none,

  /// Przegrzanie wysiłkowe (37.8°C - 38.7°C) – nadmierne pocenie, wzrost tętna
  heatStrain,

  /// Udar cieplny / przegrzanie krytyczne (> 38.7°C) – gotowanie się pod górę w kurtce!
  heatExhaustion;

  String toJson() => name;

  static HyperthermiaStage fromJson(String value) {
    return HyperthermiaStage.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => HyperthermiaStage.none,
    );
  }

  /// Spadek mocy przy przegrzaniu
  double get powerLossPercent {
    switch (this) {
      case HyperthermiaStage.none:
        return 0.0;
      case HyperthermiaStage.heatStrain:
        return 7.0;
      case HyperthermiaStage.heatExhaustion:
        return 24.0;
    }
  }
}

/// Punktowa migawka pogody na trasie etapu dla danego kilometra i wysokości.
class LocalWeatherSnapshot {
  /// Kilometr trasy etapu [km]
  final double distanceKm;

  /// Wysokość n.p.m. w tym punkcie trasy [m]
  final double altitudeMeters;

  /// Rzeczywista temperatura otoczenia [°C]
  final double ambientTemperatureCelsius;

  /// Odczuwalna temperatura z uwzględnieniem wiatru i wilgoci (Wind Chill) [°C]
  final double apparentTemperatureCelsius;

  /// Szczegółowy typ mikroklimatu
  final MountainWeatherType weatherType;

  /// Zgodna kategoria bazowa pogody
  final WeatherCondition weatherCondition;

  /// Prędkość wiatru w km/h
  final double windSpeedKmh;

  /// Porywy wiatru w km/h (Wind gusts)
  final double windGustKmh;

  /// Kierunek wiatru [0-360°]
  final double windDirectionDegrees;

  /// Intensywność opadów atmosferycznych (0.0 = brak, 1.0 = ulewa/marznący deszcz)
  final double precipitationIntensity;

  /// Wilgotność względna powietrza [%] (0 - 100)
  final double relativeHumidityPercent;

  /// Gęstość powietrza rho [kg/m^3]
  final double airDensityKgM3;

  /// Stan nawierzchni drogi
  final RoadSurfaceState roadSurface;

  /// Czy punkt znajduje się na wysokiej przełęczy górskiej (> 1600m n.p.m.)
  final bool isHighMountainPass;

  /// Ostrzeżenie meteorologiczne lub informacja dla dyrektora sportowego
  final String? warningNote;

  const LocalWeatherSnapshot({
    required this.distanceKm,
    required this.altitudeMeters,
    required this.ambientTemperatureCelsius,
    required this.apparentTemperatureCelsius,
    required this.weatherType,
    required this.weatherCondition,
    required this.windSpeedKmh,
    required this.windGustKmh,
    required this.windDirectionDegrees,
    required this.precipitationIntensity,
    required this.relativeHumidityPercent,
    required this.airDensityKgM3,
    required this.roadSurface,
    required this.isHighMountainPass,
    this.warningNote,
  });

  /// Czy warunki wymagają założenia kurtki na zjeździe
  bool get requiresRainJacketForDescent {
    return apparentTemperatureCelsius <= 10.0 ||
        weatherType.hasPrecipitation ||
        weatherType.isFreezingCondition ||
        (isHighMountainPass && ambientTemperatureCelsius <= 12.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'distanceKm': distanceKm,
      'altitudeMeters': altitudeMeters,
      'ambientTemperatureCelsius': ambientTemperatureCelsius,
      'apparentTemperatureCelsius': apparentTemperatureCelsius,
      'weatherType': weatherType.toJson(),
      'weatherCondition': weatherCondition.toJson(),
      'windSpeedKmh': windSpeedKmh,
      'windGustKmh': windGustKmh,
      'windDirectionDegrees': windDirectionDegrees,
      'precipitationIntensity': precipitationIntensity,
      'relativeHumidityPercent': relativeHumidityPercent,
      'airDensityKgM3': airDensityKgM3,
      'roadSurface': roadSurface.toJson(),
      'isHighMountainPass': isHighMountainPass,
      if (warningNote != null) 'warningNote': warningNote,
    };
  }

  factory LocalWeatherSnapshot.fromJson(Map<String, dynamic> json) {
    return LocalWeatherSnapshot(
      distanceKm: (json['distanceKm'] as num).toDouble(),
      altitudeMeters: (json['altitudeMeters'] as num).toDouble(),
      ambientTemperatureCelsius: (json['ambientTemperatureCelsius'] as num).toDouble(),
      apparentTemperatureCelsius: (json['apparentTemperatureCelsius'] as num).toDouble(),
      weatherType: MountainWeatherType.fromJson(json['weatherType'] as String),
      weatherCondition: WeatherCondition.fromJson(json['weatherCondition'] as String),
      windSpeedKmh: (json['windSpeedKmh'] as num).toDouble(),
      windGustKmh: (json['windGustKmh'] as num).toDouble(),
      windDirectionDegrees: (json['windDirectionDegrees'] as num).toDouble(),
      precipitationIntensity: (json['precipitationIntensity'] as num).toDouble(),
      relativeHumidityPercent: (json['relativeHumidityPercent'] as num).toDouble(),
      airDensityKgM3: (json['airDensityKgM3'] as num).toDouble(),
      roadSurface: RoadSurfaceState.fromJson(json['roadSurface'] as String),
      isHighMountainPass: json['isHighMountainPass'] as bool? ?? false,
      warningNote: json['warningNote'] as String?,
    );
  }
}

/// Bieżący stan termoregulacji i ubioru kolarza.
class RiderThermalSnapshot {
  final String riderId;
  final String riderName;

  /// Aktualnie ubrany element odzieży
  final RiderClothingType clothingType;

  /// Czy kurtka/kamizelka jest ubrana i zapięta
  final bool isJacketWorn;

  /// Temperatura wnętrza ciała (Core Body Temperature) [°C] (norma ~37.0°C)
  final double coreTemperatureCelsius;

  /// Temperatura skóry (Skin Temperature) [°C] (norma ~33.0°C)
  final double skinTemperatureCelsius;

  /// Stopień przemoczenia odzieży i ciała (0.0 = sucho, 1.0 = całkowicie przemoczony)
  final double wetnessLevel;

  /// Aktualne stadium hipotermii
  final HypothermiaStage hypothermiaStage;

  /// Aktualne stadium hipertermii (przegrzania)
  final HyperthermiaStage hyperthermiaStage;

  /// Łączny spadek mocy kolarza w procentach [%]
  final double totalPowerPenaltyPercent;

  /// Kara do umiejętności technicznych na zjeździe [%]
  final double descendingPenaltyPercent;

  /// Efektywny narzut oporu aerodynamicznego CdA [m^2]
  final double effectiveCdaPenalty;

  /// Poziom mimowolnych drgawek mięśniowych (shivering: 0.0 - 1.0)
  final double shiveringIntensity;

  /// Wzrost tempa spalania glikogenu z powodu drgawek termogenezy (mnożnik 1.0 - 1.45)
  final double shiveringGlycogenMultiplier;

  /// Komunikat diagnostyczny stanu kolarza
  final String statusDescription;

  const RiderThermalSnapshot({
    required this.riderId,
    required this.riderName,
    required this.clothingType,
    required this.isJacketWorn,
    required this.coreTemperatureCelsius,
    required this.skinTemperatureCelsius,
    required this.wetnessLevel,
    required this.hypothermiaStage,
    required this.hyperthermiaStage,
    required this.totalPowerPenaltyPercent,
    required this.descendingPenaltyPercent,
    required this.effectiveCdaPenalty,
    required this.shiveringIntensity,
    required this.shiveringGlycogenMultiplier,
    required this.statusDescription,
  });

  /// Inicjalny stan komfortu termicznego przed startem etapu
  factory RiderThermalSnapshot.initial({
    required String riderId,
    required String riderName,
    RiderClothingType startingClothing = RiderClothingType.summerAeroJersey,
  }) {
    return RiderThermalSnapshot(
      riderId: riderId,
      riderName: riderName,
      clothingType: startingClothing,
      isJacketWorn: startingClothing != RiderClothingType.summerAeroJersey,
      coreTemperatureCelsius: 37.0,
      skinTemperatureCelsius: 33.0,
      wetnessLevel: 0.0,
      hypothermiaStage: HypothermiaStage.none,
      hyperthermiaStage: HyperthermiaStage.none,
      totalPowerPenaltyPercent: 0.0,
      descendingPenaltyPercent: 0.0,
      effectiveCdaPenalty: startingClothing.baseCdaPenalty,
      shiveringIntensity: 0.0,
      shiveringGlycogenMultiplier: 1.0,
      statusDescription: 'Optymalny komfort termiczny na starcie.',
    );
  }

  RiderThermalSnapshot copyWith({
    String? riderId,
    String? riderName,
    RiderClothingType? clothingType,
    bool? isJacketWorn,
    double? coreTemperatureCelsius,
    double? skinTemperatureCelsius,
    double? wetnessLevel,
    HypothermiaStage? hypothermiaStage,
    HyperthermiaStage? hyperthermiaStage,
    double? totalPowerPenaltyPercent,
    double? descendingPenaltyPercent,
    double? effectiveCdaPenalty,
    double? shiveringIntensity,
    double? shiveringGlycogenMultiplier,
    String? statusDescription,
  }) {
    return RiderThermalSnapshot(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      clothingType: clothingType ?? this.clothingType,
      isJacketWorn: isJacketWorn ?? this.isJacketWorn,
      coreTemperatureCelsius: coreTemperatureCelsius ?? this.coreTemperatureCelsius,
      skinTemperatureCelsius: skinTemperatureCelsius ?? this.skinTemperatureCelsius,
      wetnessLevel: wetnessLevel ?? this.wetnessLevel,
      hypothermiaStage: hypothermiaStage ?? this.hypothermiaStage,
      hyperthermiaStage: hyperthermiaStage ?? this.hyperthermiaStage,
      totalPowerPenaltyPercent: totalPowerPenaltyPercent ?? this.totalPowerPenaltyPercent,
      descendingPenaltyPercent: descendingPenaltyPercent ?? this.descendingPenaltyPercent,
      effectiveCdaPenalty: effectiveCdaPenalty ?? this.effectiveCdaPenalty,
      shiveringIntensity: shiveringIntensity ?? this.shiveringIntensity,
      shiveringGlycogenMultiplier: shiveringGlycogenMultiplier ?? this.shiveringGlycogenMultiplier,
      statusDescription: statusDescription ?? this.statusDescription,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'clothingType': clothingType.toJson(),
      'isJacketWorn': isJacketWorn,
      'coreTemperatureCelsius': coreTemperatureCelsius,
      'skinTemperatureCelsius': skinTemperatureCelsius,
      'wetnessLevel': wetnessLevel,
      'hypothermiaStage': hypothermiaStage.toJson(),
      'hyperthermiaStage': hyperthermiaStage.toJson(),
      'totalPowerPenaltyPercent': totalPowerPenaltyPercent,
      'descendingPenaltyPercent': descendingPenaltyPercent,
      'effectiveCdaPenalty': effectiveCdaPenalty,
      'shiveringIntensity': shiveringIntensity,
      'shiveringGlycogenMultiplier': shiveringGlycogenMultiplier,
      'statusDescription': statusDescription,
    };
  }

  factory RiderThermalSnapshot.fromJson(Map<String, dynamic> json) {
    return RiderThermalSnapshot(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      clothingType: RiderClothingType.fromJson(json['clothingType'] as String),
      isJacketWorn: json['isJacketWorn'] as bool? ?? false,
      coreTemperatureCelsius: (json['coreTemperatureCelsius'] as num).toDouble(),
      skinTemperatureCelsius: (json['skinTemperatureCelsius'] as num).toDouble(),
      wetnessLevel: (json['wetnessLevel'] as num).toDouble(),
      hypothermiaStage: HypothermiaStage.fromJson(json['hypothermiaStage'] as String),
      hyperthermiaStage: HyperthermiaStage.fromJson(json['hyperthermiaStage'] as String),
      totalPowerPenaltyPercent: (json['totalPowerPenaltyPercent'] as num).toDouble(),
      descendingPenaltyPercent: (json['descendingPenaltyPercent'] as num).toDouble(),
      effectiveCdaPenalty: (json['effectiveCdaPenalty'] as num).toDouble(),
      shiveringIntensity: (json['shiveringIntensity'] as num).toDouble(),
      shiveringGlycogenMultiplier: (json['shiveringGlycogenMultiplier'] as num).toDouble(),
      statusDescription: json['statusDescription'] as String,
    );
  }
}

/// Pełny profil pogodowy wygenerowany wzdłuż całej trasy etapu.
class StageWeatherProfile {
  final String stageId;
  final String stageName;
  final double baseValleyAltitudeM;
  final double baseValleyTemperatureC;
  final double peakAltitudeM;
  final double minAltitudeM;
  final List<LocalWeatherSnapshot> waypoints;
  final List<String> meteorologicalAlerts;

  const StageWeatherProfile({
    required this.stageId,
    required this.stageName,
    required this.baseValleyAltitudeM,
    required this.baseValleyTemperatureC,
    required this.peakAltitudeM,
    required this.minAltitudeM,
    required this.waypoints,
    required this.meteorologicalAlerts,
  });

  /// Zwraca interpolowaną pogodę w dowolnym kilometrze etapu
  LocalWeatherSnapshot getWeatherAtDistance(double distanceKm) {
    if (waypoints.isEmpty) {
      return LocalWeatherSnapshot(
        distanceKm: distanceKm,
        altitudeMeters: baseValleyAltitudeM,
        ambientTemperatureCelsius: baseValleyTemperatureC,
        apparentTemperatureCelsius: baseValleyTemperatureC,
        weatherType: MountainWeatherType.sunnyValley,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 12.0,
        windGustKmh: 18.0,
        windDirectionDegrees: 180.0,
        precipitationIntensity: 0.0,
        relativeHumidityPercent: 45.0,
        airDensityKgM3: 1.21,
        roadSurface: RoadSurfaceState.dry,
        isHighMountainPass: false,
      );
    }

    if (distanceKm <= waypoints.first.distanceKm) {
      return waypoints.first;
    }
    if (distanceKm >= waypoints.last.distanceKm) {
      return waypoints.last;
    }

    // Wyszukanie sąsiadujących punktów
    int idx = 0;
    while (idx < waypoints.length - 1 && waypoints[idx + 1].distanceKm < distanceKm) {
      idx++;
    }

    final p1 = waypoints[idx];
    final p2 = waypoints[idx + 1];
    final double span = p2.distanceKm - p1.distanceKm;
    if (span <= 0.0001) return p1;

    final double t = (distanceKm - p1.distanceKm) / span;

    final double interpAlt = p1.altitudeMeters + (p2.altitudeMeters - p1.altitudeMeters) * t;
    final double interpTemp = p1.ambientTemperatureCelsius + (p2.ambientTemperatureCelsius - p1.ambientTemperatureCelsius) * t;
    final double interpApparent = p1.apparentTemperatureCelsius + (p2.apparentTemperatureCelsius - p1.apparentTemperatureCelsius) * t;
    final double interpWind = p1.windSpeedKmh + (p2.windSpeedKmh - p1.windSpeedKmh) * t;
    final double interpGust = p1.windGustKmh + (p2.windGustKmh - p1.windGustKmh) * t;
    final double interpPrecip = p1.precipitationIntensity + (p2.precipitationIntensity - p1.precipitationIntensity) * t;
    final double interpHumidity = p1.relativeHumidityPercent + (p2.relativeHumidityPercent - p1.relativeHumidityPercent) * t;
    final double interpRho = p1.airDensityKgM3 + (p2.airDensityKgM3 - p1.airDensityKgM3) * t;

    // Typ mikroklimatu i nawierzchni bierzemy z punktu o wyższej dotkliwości
    final activeWeather = interpPrecip > 0.45 ? p2.weatherType : (t > 0.5 ? p2.weatherType : p1.weatherType);
    final activeRoad = interpPrecip > 0.25 ? (interpApparent < 1.0 ? RoadSurfaceState.freezingGlaze : RoadSurfaceState.wet) : p1.roadSurface;

    return LocalWeatherSnapshot(
      distanceKm: distanceKm,
      altitudeMeters: interpAlt,
      ambientTemperatureCelsius: interpTemp,
      apparentTemperatureCelsius: interpApparent,
      weatherType: activeWeather,
      weatherCondition: activeWeather.toStandardCondition(),
      windSpeedKmh: interpWind,
      windGustKmh: interpGust,
      windDirectionDegrees: p1.windDirectionDegrees,
      precipitationIntensity: interpPrecip,
      relativeHumidityPercent: interpHumidity,
      airDensityKgM3: interpRho,
      roadSurface: activeRoad,
      isHighMountainPass: interpAlt >= 1600.0,
      warningNote: t > 0.5 ? p2.warningNote : p1.warningNote,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stageId': stageId,
      'stageName': stageName,
      'baseValleyAltitudeM': baseValleyAltitudeM,
      'baseValleyTemperatureC': baseValleyTemperatureC,
      'peakAltitudeM': peakAltitudeM,
      'minAltitudeM': minAltitudeM,
      'waypoints': waypoints.map((w) => w.toJson()).toList(),
      'meteorologicalAlerts': meteorologicalAlerts,
    };
  }

  factory StageWeatherProfile.fromJson(Map<String, dynamic> json) {
    return StageWeatherProfile(
      stageId: json['stageId'] as String,
      stageName: json['stageName'] as String,
      baseValleyAltitudeM: (json['baseValleyAltitudeM'] as num).toDouble(),
      baseValleyTemperatureC: (json['baseValleyTemperatureC'] as num).toDouble(),
      peakAltitudeM: (json['peakAltitudeM'] as num).toDouble(),
      minAltitudeM: (json['minAltitudeM'] as num).toDouble(),
      waypoints: (json['waypoints'] as List<dynamic>)
          .map((e) => LocalWeatherSnapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
      meteorologicalAlerts: List<String>.from(json['meteorologicalAlerts'] as List<dynamic>),
    );
  }
}

/// Dynamiczny silnik symulacji pogody wysokogórskiej i termoregulacji kolarzy.
///
/// Implementuje:
/// - Pionowy gradient temperatury ISA: spadek o 0.65°C na każde 100 m wysokości
/// - Chłodzenie ewaporacyjne deszczu i fronty orograficzne na przełęczach (Cols)
/// - Potęgowanie wiatru (efekt Venturi) na odsłoniętych szczytach
/// - Obliczenia odczuwalnego chłodu wiatru (Wind Chill Index) przy dużych prędkościach zjazdowych
/// - Bilans cieplny kolarza: produkcja ciepła na podjeździe vs gwałtowne wychłodzenie na zjeździe
/// - Mechanikę zakupu i użycia kurtek przeciwdeszczowych (ochrona przed hipotermią vs opór aero CdA)
class DynamicMountainWeatherEngine {
  DynamicMountainWeatherEngine._();

  /// Standardowy pionowy gradient temperatury atmosfery wzorcowej (ISA Lapse Rate) [°C/m]
  /// 0.0065 °C na 1 metr = 0.65 °C na 100 metrów wysokości
  static const double standardLapseRatePerMeter = PhysicsConstants.temperatureLapseRate; // 0.0065

  /// Dodatkowe schłodzenie powietrza przez deszcz i chmury orograficzne [°C]
  static const double rainEvaporativeCoolingDeltaC = 1.7;

  /// Pułap wysokości n.p.m., powyżej którego gwałtownie rośnie ryzyko burzy i marznącego deszczu [m]
  static const double highAltitudePassThresholdM = 1600.0;

  /// Pułap ekstremalnej wysokości (Cima Coppi / Hors Catégorie) [m]
  static const double extremePassThresholdM = 2200.0;

  /// Generuje kompletny profil pogodowy dla całej trasy danego etapu.
  static StageWeatherProfile generateStageWeatherProfile({
    required RaceStage stage,
    double? customValleyTemperatureC,
    double? customValleyAltitudeM,
    WeatherCondition? customValleyWeather,
    double? customBaseWindSpeedKmh,
  }) {
    final double minAlt = stage.segments.isNotEmpty ? stage.minElevationM : 200.0;
    final double maxAlt = stage.segments.isNotEmpty ? stage.maxElevationM : 2400.0;
    final double valleyAlt = customValleyAltitudeM ?? math.max(50.0, minAlt);
    final double valleyTemp = customValleyTemperatureC ?? stage.baseTemperatureCelsius;
    final WeatherCondition valleyCondition = customValleyWeather ?? stage.weatherCondition;
    final double baseWind = customBaseWindSpeedKmh ?? stage.windSpeedKmh;

    final List<LocalWeatherSnapshot> waypoints = [];
    final List<String> alerts = [];

    // Generujemy punkty kontrolne na granicach i środkach każdego segmentu etapu
    for (int i = 0; i < stage.segments.length; i++) {
      final seg = stage.segments[i];
      final bool isSummit = seg.sprintOrKomClassification == SegmentClassification.horsCategorie ||
          seg.sprintOrKomClassification == SegmentClassification.cat1 ||
          (seg.isClimb && (i == stage.segments.length - 1 || stage.segments[i + 1].isDescent));
      final bool isDescent = seg.isDescent;

      // 1. Punkt początkowy segmentu
      final startSnap = calculateLocalWeather(
        distanceKm: seg.startKm,
        altitudeMeters: seg.startElevationM,
        baseValleyAltM: valleyAlt,
        baseValleyTempC: valleyTemp,
        baseWindSpeedKmh: baseWind,
        baseWindDirectionDeg: seg.windDirectionDegrees,
        baseCondition: valleyCondition,
        isSummit: false,
        isDescent: isDescent,
      );
      waypoints.add(startSnap);

      // 2. Punkt szczytowy / końcowy segmentu
      final endSnap = calculateLocalWeather(
        distanceKm: seg.endKm,
        altitudeMeters: seg.endElevationM,
        baseValleyAltM: valleyAlt,
        baseValleyTempC: valleyTemp,
        baseWindSpeedKmh: baseWind,
        baseWindDirectionDeg: seg.windDirectionDegrees,
        baseCondition: valleyCondition,
        isSummit: isSummit,
        isDescent: isDescent,
      );
      waypoints.add(endSnap);

      // Sprawdzenie czy dany segment generuje ostrzeżenie pogodowe dla dyrektora sportowego
      if (endSnap.altitudeMeters >= highAltitudePassThresholdM && endSnap.requiresRainJacketForDescent) {
        final alertMsg = 'Przełęcz na km ${seg.endKm.toStringAsFixed(1)} (${endSnap.altitudeMeters.round()}m n.p.m.): '
            '${endSnap.weatherType.displayNamePl}, temp. ${endSnap.ambientTemperatureCelsius.toStringAsFixed(1)}°C '
            '(odczuwalna ${endSnap.apparentTemperatureCelsius.toStringAsFixed(1)}°C), wiatr ${endSnap.windSpeedKmh.round()} km/h. '
            'Zalecane kurtki przeciwdeszczowe na zjazd!';
        if (!alerts.contains(alertMsg)) {
          alerts.add(alertMsg);
        }
      }
    }

    return StageWeatherProfile(
      stageId: stage.id,
      stageName: stage.name,
      baseValleyAltitudeM: valleyAlt,
      baseValleyTemperatureC: valleyTemp,
      peakAltitudeM: maxAlt,
      minAltitudeM: minAlt,
      waypoints: waypoints,
      meteorologicalAlerts: alerts,
    );
  }

  /// Wylicza mikroklimat i parametry atmosferyczne w konkretnym punkcie trasy.
  ///
  /// Dokładnie odwzorowuje regułę:
  /// - Dolina (200m n.p.m.): np. +24.0°C słonecznie
  /// - Przełęcz (2400m n.p.m.): spadek o 0.65°C / 100m (14.3°C spadek ISA),
  ///   plus chłodzenie deszczem (1.7°C), dając dokładnie +8.0°C, porywisty wiatr i marznący deszcz!
  static LocalWeatherSnapshot calculateLocalWeather({
    required double distanceKm,
    required double altitudeMeters,
    required double baseValleyAltM,
    required double baseValleyTempC,
    required double baseWindSpeedKmh,
    required double baseWindDirectionDeg,
    required WeatherCondition baseCondition,
    bool isSummit = false,
    bool isDescent = false,
  }) {
    final double altDiffM = math.max(0.0, altitudeMeters - baseValleyAltM);

    // 1. Spadek temperatury zgodnie z pionowym gradientem ISA (0.65°C / 100m)
    final double dryLapseDelta = altDiffM * standardLapseRatePerMeter;
    double calculatedTemp = baseValleyTempC - dryLapseDelta;

    // 2. Efekt orograficzny i wypiętrzanie chmur na wysokości
    final double altitudeRatio = ((altitudeMeters - 800.0) / 1600.0).clamp(0.0, 1.0);
    final bool isHighAltitude = altitudeMeters >= highAltitudePassThresholdM;
    final bool isExtremeAltitude = altitudeMeters >= extremePassThresholdM;

    // 3. Wiatr: w dolinie osłonięty, na przełęczy porywisty (efekt Venturi)
    double windMultiplier = 1.0;
    if (altitudeMeters > 1000.0) {
      windMultiplier += (altitudeMeters - 1000.0) / 750.0; // Na 2500m mnożnik ~3.0
    }
    if (isSummit) {
      windMultiplier *= 1.35; // Dodatkowe przyspieszenie wiatru w siodle przełęczy
    }
    final double localWindSpeed = (baseWindSpeedKmh * windMultiplier).clamp(5.0, 110.0);
    final double localWindGust = (localWindSpeed * 1.42).clamp(8.0, 140.0);

    // 4. Określenie typu mikroklimatu
    MountainWeatherType localType;
    double precipIntensity = 0.0;
    double humidity = 45.0 + (altitudeRatio * 45.0);

    if (baseCondition == WeatherCondition.extremeHeat) {
      if (isHighAltitude) {
        localType = MountainWeatherType.sunnyValley;
        calculatedTemp = math.max(14.0, calculatedTemp);
      } else {
        localType = MountainWeatherType.heatWave;
      }
    } else if (isHighAltitude) {
      // Wysokie partie górskie: chmury kłębiaste, deszcz, spadek temp.
      if (calculatedTemp <= 10.5 && (isExtremeAltitude || isSummit || calculatedTemp <= 4.0)) {
        localType = MountainWeatherType.freezingRain;
        precipIntensity = 0.85;
        humidity = 98.0;
        calculatedTemp -= rainEvaporativeCoolingDeltaC;
      } else if (calculatedTemp <= 7.0 && localWindSpeed > 45.0) {
        localType = MountainWeatherType.sleetHail;
        precipIntensity = 0.75;
        humidity = 95.0;
        calculatedTemp -= rainEvaporativeCoolingDeltaC;
      } else if (localWindSpeed > 55.0) {
        localType = MountainWeatherType.ridgeGale;
        precipIntensity = 0.40;
        humidity = 85.0;
        calculatedTemp -= 1.0;
      } else if (baseCondition == WeatherCondition.heavyStorm || isSummit) {
        localType = MountainWeatherType.heavyRain;
        precipIntensity = 0.90;
        humidity = 95.0;
        calculatedTemp -= rainEvaporativeCoolingDeltaC;
      } else {
        localType = MountainWeatherType.alpineFog;
        precipIntensity = 0.30;
        humidity = 92.0;
      }
    } else if (altitudeMeters > 900.0) {
      // Średnie partie podjazdu
      if (baseCondition == WeatherCondition.heavyStorm || baseCondition == WeatherCondition.lightRain) {
        localType = MountainWeatherType.heavyRain;
        precipIntensity = 0.70;
        humidity = 88.0;
        calculatedTemp -= 1.0;
      } else {
        localType = MountainWeatherType.mountainMist;
        precipIntensity = 0.15;
        humidity = 75.0;
      }
    } else {
      // Dolina
      if (baseCondition == WeatherCondition.sunny) {
        localType = MountainWeatherType.sunnyValley;
        precipIntensity = 0.0;
        humidity = 48.0;
      } else if (baseCondition == WeatherCondition.lightRain) {
        localType = MountainWeatherType.lightDrizzle;
        precipIntensity = 0.35;
        humidity = 70.0;
      } else if (baseCondition == WeatherCondition.heavyStorm) {
        localType = MountainWeatherType.heavyRain;
        precipIntensity = 0.80;
        humidity = 90.0;
      } else if (baseCondition == WeatherCondition.crosswindGale) {
        localType = MountainWeatherType.ridgeGale;
        precipIntensity = 0.10;
        humidity = 60.0;
      } else {
        localType = MountainWeatherType.overcastPlateau;
        precipIntensity = 0.05;
        humidity = 62.0;
      }
    }

    // Zaokrąglenie temperatury do 1 miejsca po przecinku
    final double ambientT = double.parse(calculatedTemp.toStringAsFixed(1));

    // 5. Temperatura odczuwalna (Wind Chill)
    final double apparentT = calculateWindChill(
      ambientTempC: ambientT,
      effectiveAirspeedKmh: localWindSpeed,
      wetnessLevel: precipIntensity > 0.3 ? 0.8 : 0.0,
    );

    // 6. Gęstość powietrza
    final double rho = calculateAirDensityAtPoint(altitudeMeters, ambientT);

    // 7. Stan nawierzchni
    RoadSurfaceState surface;
    if (precipIntensity > 0.6 && apparentT <= 1.0) {
      surface = RoadSurfaceState.freezingGlaze;
    } else if (precipIntensity > 0.6) {
      surface = RoadSurfaceState.standingWaterSpray;
    } else if (precipIntensity > 0.2) {
      surface = RoadSurfaceState.wet;
    } else if (precipIntensity > 0.05 || humidity > 85.0) {
      surface = RoadSurfaceState.damp;
    } else {
      surface = RoadSurfaceState.dry;
    }

    String? note;
    if (isHighAltitude && (surface == RoadSurfaceState.freezingGlaze || apparentT < 5.0)) {
      note = 'Ekstremalne ochłodzenie i marznące opady na wysokości ${altitudeMeters.round()}m n.p.m.!';
    }

    return LocalWeatherSnapshot(
      distanceKm: distanceKm,
      altitudeMeters: altitudeMeters,
      ambientTemperatureCelsius: ambientT,
      apparentTemperatureCelsius: apparentT,
      weatherType: localType,
      weatherCondition: localType.toStandardCondition(),
      windSpeedKmh: double.parse(localWindSpeed.toStringAsFixed(1)),
      windGustKmh: double.parse(localWindGust.toStringAsFixed(1)),
      windDirectionDegrees: baseWindDirectionDeg,
      precipitationIntensity: double.parse(precipIntensity.toStringAsFixed(2)),
      relativeHumidityPercent: double.parse(humidity.toStringAsFixed(1)),
      airDensityKgM3: double.parse(rho.toStringAsFixed(3)),
      roadSurface: surface,
      isHighMountainPass: isHighAltitude,
      warningNote: note,
    );
  }

  /// Oblicza temperaturę odczuwalną (Wind Chill Index) z uwzględnieniem prędkości powietrza i wilgoci.
  ///
  /// Wzór Environment Canada / JAG/TI dla T <= 10°C:
  /// Twc = 13.12 + 0.6215 * T - 11.37 * V^0.16 + 0.3965 * T * V^0.16
  /// Dodatkowo mokra odzież drastycznie potęguje przewodzenie ciepła (woda przewodzi ciepło ~25x szybciej niż powietrze).
  static double calculateWindChill({
    required double ambientTempC,
    required double effectiveAirspeedKmh,
    required double wetnessLevel,
  }) {
    final double v = math.max(4.8, effectiveAirspeedKmh);
    double windChill = ambientTempC;

    if (ambientTempC <= 10.0) {
      final double vPow = math.pow(v, 0.16).toDouble();
      windChill = 13.12 + (0.6215 * ambientTempC) - (11.37 * vPow) + (0.3965 * ambientTempC * vPow);
    } else if (ambientTempC <= 20.0 && v > 20.0) {
      // Umiarkowany efekt chłodzenia wiatrem
      final double cooling = ((v - 15.0) / 20.0) * 2.2;
      windChill = ambientTempC - cooling;
    }

    // Kara za przemoczenie (przewodzenie cieplne wody)
    if (wetnessLevel > 0.1) {
      final double wetnessCoolingDelta = wetnessLevel * 5.5;
      windChill -= wetnessCoolingDelta;
    }

    return double.parse(windChill.toStringAsFixed(1));
  }

  /// Wylicza gęstość powietrza rho [kg/m^3] dla zadanej wysokości i temperatury.
  static double calculateAirDensityAtPoint(double altitudeM, double tempC) {
    final double h = math.max(0.0, altitudeM);
    final double tKelvin = tempC + 273.15;
    if (tKelvin <= 100.0) return PhysicsConstants.seaLevelAirDensity;

    // Ciśnienie barometryczne ze wzoru barometrycznego ISA:
    // P = P0 * (1 - L*h / T0)^(g*M / (R*L))
    const double p0 = 101325.0; // Pa
    const double t0 = 288.15; // 15°C
    const double l = 0.0065; // K/m
    const double exponent = 5.25588; // (g*M)/(R*L)
    const double rSpecific = 287.058; // J/(kg*K) dla suchego powietrza

    final double basePressure = (1.0 - (l * h) / t0);
    final double pressure = p0 * math.pow(math.max(0.1, basePressure), exponent);

    final double rho = pressure / (rSpecific * tKelvin);
    return rho.clamp(0.70, 1.35);
  }

  /// Aktualizuje stan termiczny kolarza w kolejnym kroku symulacji czasowej [timeStepSeconds].
  ///
  /// Oblicza:
  /// - Produkcję ciepła metabolicznego: Q_met = P_mech * (1 - eta) / eta, gdzie eta ~ 0.235 (sprawność mięśni)
  /// - Utratę ciepła przez konwekcję z pędem powietrza (zależną od prędkości kolarza i zjazdu!)
  /// - Ochronę oferowaną przez odzież ([RiderClothingType]) oraz kontrakt techniczny sponsora ([ApparelTechnicalPerks])
  /// - Zagrożenie hipotermią na zjazdach oraz hipertermią na podjazdach
  static RiderThermalSnapshot updateRiderThermalState({
    required RiderThermalSnapshot currentThermal,
    required RiderPhysiology physiology,
    required RiderSkills skills,
    required LocalWeatherSnapshot weather,
    required double riderSpeedKmh,
    required double powerOutputWatts,
    required double timeStepSeconds,
    ApparelTechnicalPerks? teamApparel,
  }) {
    final double dtMinutes = timeStepSeconds / 60.0;

    // 1. Parametry odzieży kolarza z uwzględnieniem technologii sponsora odzieżowego
    final RiderClothingType clothing = currentThermal.clothingType;
    final double clothingInsulation = clothing.thermalInsulationClo;
    final double windBlock = clothing.windBlockEfficiency;
    final double waterBlock = clothing.waterproofProtection;

    // Bonus odzieży technicznej drużyny (np. membrany Castelli Gabba / Santini)
    final double sponsorThermalBonus = teamApparel != null
        ? (teamApparel.badWeatherThermalProtectionScore / 100.0) * 0.20
        : 0.0;

    final double effectiveInsulation = clothingInsulation + sponsorThermalBonus;
    final double effectiveWaterBlock = (waterBlock + (sponsorThermalBonus * 0.5)).clamp(0.0, 1.0);
    final double effectiveWindBlock = (windBlock + (sponsorThermalBonus * 0.4)).clamp(0.0, 1.0);

    // 2. Dynamika przemoczenia odzieży (Wetness Level)
    double newWetness = currentThermal.wetnessLevel;
    if (weather.precipitationIntensity > 0.1) {
      final double waterPenetrationRate = (1.0 - effectiveWaterBlock) * weather.precipitationIntensity * 0.12 * dtMinutes;
      newWetness = (newWetness + waterPenetrationRate).clamp(0.0, 1.0);
    } else {
      // Wysychanie na wietrze i w słońcu
      final double dryingRate = (weather.ambientTemperatureCelsius > 18.0 ? 0.08 : 0.02) * dtMinutes;
      newWetness = (newWetness - dryingRate).clamp(0.0, 1.0);
    }

    // 3. Efektywna prędkość opływu powietrza wokół ciała kolarza (redukowana przez wiatroszczelną membranę)
    final double rawRelativeAirspeedKmh = riderSpeedKmh + (weather.windSpeedKmh * 0.5);
    final double windPenetrationFactor = (1.0 - (effectiveWindBlock * 0.70)).clamp(0.15, 1.0);
    final double effectiveAirspeedKmh = rawRelativeAirspeedKmh * windPenetrationFactor;

    // 4. Bilans cieplny kolarza:
    // A) Produkcja ciepła metabolicznego (Metabolic Heat Production) [Watts]
    // Sprawność pracy mięśniowej wynosi ok. 23.5%, reszta to czyste ciepło.
    const double muscleEfficiency = 0.235;
    final double metabolicHeatWatts = powerOutputWatts * ((1.0 - muscleEfficiency) / muscleEfficiency);

    // B) Pole powierzchni ciała (BSA)
    final double bsa = physiology.bodySurfaceAreaM2 > 0.0 ? physiology.bodySurfaceAreaM2 : 1.85;

    // C) Tłuszczowa izolacja ciała (zawartość tkanki tłuszczowej chroni przed zimnem)
    final double bodyFatInsulation = (physiology.bodyFatPercentage / 100.0) * 0.15;

    // D) Współczynnik konwekcyjnej utraty ciepła h_c w funkcji prędkości opływu
    final double airspeedMs = effectiveAirspeedKmh / 3.6;
    // Wzór Nixona/Mitchell dla kolarza: h_c = 8.3 * v^0.6
    double hc = 8.3 * math.pow(math.max(1.0, airspeedMs), 0.6);

    // Jeśli strój jest mokry, przewodzenie rośnie nawet 12-20x
    final double wetnessMultiplier = 1.0 + (newWetness * 8.5);
    hc *= wetnessMultiplier;

    // Ochrona odzieży redukuje h_c (zwłaszcza windstopper i izolacja clo)
    final double insulationResistance = (effectiveInsulation + bodyFatInsulation) * 0.155; // 1 clo = 0.155 m^2*K/W
    final double totalThermalResistance = (1.0 / math.max(1.0, hc)) + insulationResistance;
    final double effectiveHc = 1.0 / math.max(0.05, totalThermalResistance);

    // E) Utrata ciepła przez konwekcję [Watts]
    final double tempGradient = currentThermal.skinTemperatureCelsius - weather.ambientTemperatureCelsius;
    final double convectiveLossWatts = effectiveHc * bsa * tempGradient;

    // F) Utrata ciepła przez parowanie potu (Evaporative heat loss)
    double evaporativeLossWatts = 0.0;
    if (powerOutputWatts > 150.0 && weather.ambientTemperatureCelsius > 15.0) {
      evaporativeLossWatts = math.min(metabolicHeatWatts * 0.60, 450.0);
      if (clothing == RiderClothingType.rainJacket && weather.ambientTemperatureCelsius > 20.0) {
        // Zapięta kurtka przeciwdeszczowa w upale ogranicza odparowywanie potu do 25%!
        evaporativeLossWatts *= 0.35;
      }
    }

    // G) Bilans netto strumienia ciepła [Watts]
    final double netHeatFlowWatts = metabolicHeatWatts - convectiveLossWatts - evaporativeLossWatts;

    // 5. Zmiana temperatury głębokiej ciała (Core Temperature)
    // Pojemność cieplna ciała ludzkiego: C = masa * 3470 J/(kg * K)
    final double riderMassKg = physiology.weightKg > 30.0 ? physiology.weightKg : 68.0;
    final double heatCapacityJoulesPerKelvin = riderMassKg * 3470.0;

    // deltaT_core = (Q_net * dt_seconds) / C
    final double deltaCoreTempCelsius = (netHeatFlowWatts * timeStepSeconds) / heatCapacityJoulesPerKelvin;

    // Zmiana temperatury skóry
    double targetSkinTemp = 33.0 + (weather.ambientTemperatureCelsius - 20.0) * 0.25;
    if (effectiveInsulation > 0.5) targetSkinTemp += 2.0;
    if (newWetness > 0.5) targetSkinTemp -= 5.0;
    targetSkinTemp = targetSkinTemp.clamp(14.0, 36.5);

    final double newSkinTemp = currentThermal.skinTemperatureCelsius +
        (targetSkinTemp - currentThermal.skinTemperatureCelsius) * (0.05 * dtMinutes);

    // Odporność kolarza na deszcz i chłód (RiderSkills.rainResistance)
    final double rainResistBonus = (skills.rainResistance / 100.0) * 0.4;
    double dampedDeltaCore = deltaCoreTempCelsius;
    if (dampedDeltaCore < 0.0) {
      dampedDeltaCore *= (1.0 - rainResistBonus); // Wolniejsza utrata ciepła dla kolarzy odpornych na złą pogodę
    }

    double newCoreTemp = (currentThermal.coreTemperatureCelsius + dampedDeltaCore).clamp(32.5, 41.0);

    // 6. Identyfikacja stadiów hipotermii i hipertermii
    HypothermiaStage hypoStage = HypothermiaStage.none;
    HyperthermiaStage hyperStage = HyperthermiaStage.none;
    double shivering = 0.0;
    double shiveringGlycogenMult = 1.0;

    if (newCoreTemp < 34.0) {
      hypoStage = HypothermiaStage.severe;
      shivering = 0.90;
      shiveringGlycogenMult = 1.45;
    } else if (newCoreTemp < 35.5) {
      hypoStage = HypothermiaStage.moderate;
      shivering = 0.70;
      shiveringGlycogenMult = 1.30;
    } else if (newCoreTemp < 36.5) {
      hypoStage = HypothermiaStage.mildShivering;
      shivering = 0.35;
      shiveringGlycogenMult = 1.15;
    } else if (newCoreTemp > 38.7) {
      hyperStage = HyperthermiaStage.heatExhaustion;
    } else if (newCoreTemp > 37.8) {
      hyperStage = HyperthermiaStage.heatStrain;
    }

    // 7. Spadek mocy kolarza (Power Loss Penalty)
    double totalPowerPenalty = 0.0;
    if (hypoStage != HypothermiaStage.none) {
      totalPowerPenalty += hypoStage.powerLossPercent;
    }
    if (hyperStage != HyperthermiaStage.none) {
      totalPowerPenalty += hyperStage.powerLossPercent;
    }
    totalPowerPenalty = totalPowerPenalty.clamp(0.0, 75.0);

    // 8. Kara do umiejętności zjazdowych (zdrętwiałe palce i sztywność rąk na klamkach hamulcowych)
    double descPenalty = hypoStage.descendingPenaltyPercent;
    if (newWetness > 0.6 && weather.apparentTemperatureCelsius < 5.0) {
      descPenalty += 15.0; // Przemarznięte dłonie w mokrych rękawiczkach
    }
    descPenalty = descPenalty.clamp(0.0, 85.0);

    // 9. Efektywny narzut oporu aero CdA
    double cdaPenalty = clothing.baseCdaPenalty;
    if (teamApparel != null && clothing == RiderClothingType.rainJacket) {
      // Profesjonalny aerodynamiczny krój z tunelem aero
      final double aeroImprovement = (teamApparel.customWindTunnelFittingsCount * 0.002).clamp(0.0, 0.010);
      cdaPenalty = math.max(0.008, cdaPenalty - aeroImprovement);
    }

    // 10. Status opisowy
    String desc;
    if (hypoStage == HypothermiaStage.severe) {
      desc = 'KRYTYCZNA HIPOTERMIA (${newCoreTemp.toStringAsFixed(1)}°C)! Kolarz trzęsie się z zimna i traci kontrolę!';
    } else if (hypoStage == HypothermiaStage.moderate) {
      desc = 'Umiarkowane wychłodzenie (${newCoreTemp.toStringAsFixed(1)}°C) – zdrętwiałe dłonie i utrata ${totalPowerPenalty.round()}% mocy.';
    } else if (hypoStage == HypothermiaStage.mildShivering) {
      desc = 'Lekkie drgawki z zimna na zjeździe (${newCoreTemp.toStringAsFixed(1)}°C).';
    } else if (hyperStage == HyperthermiaStage.heatExhaustion) {
      desc = 'PRZEGRZANIE (${newCoreTemp.toStringAsFixed(1)}°C)! Kolarz gotuje się w kurtce na podjeździe!';
    } else if (hyperStage == HyperthermiaStage.heatStrain) {
      desc = 'Wzmożone pocenie i dyskomfort cieplny (${newCoreTemp.toStringAsFixed(1)}°C).';
    } else if (currentThermal.isJacketWorn && weather.requiresRainJacketForDescent) {
      desc = 'Optymalna ochrona termiczna w kurtce przeciwdeszczowej na chłodnym zjeździe.';
    } else {
      desc = 'Komfort termiczny w normie (${newCoreTemp.toStringAsFixed(1)}°C).';
    }

    return RiderThermalSnapshot(
      riderId: currentThermal.riderId,
      riderName: currentThermal.riderName,
      clothingType: clothing,
      isJacketWorn: currentThermal.isJacketWorn,
      coreTemperatureCelsius: double.parse(newCoreTemp.toStringAsFixed(2)),
      skinTemperatureCelsius: double.parse(newSkinTemp.toStringAsFixed(1)),
      wetnessLevel: double.parse(newWetness.toStringAsFixed(2)),
      hypothermiaStage: hypoStage,
      hyperthermiaStage: hyperStage,
      totalPowerPenaltyPercent: double.parse(totalPowerPenalty.toStringAsFixed(1)),
      descendingPenaltyPercent: double.parse(descPenalty.toStringAsFixed(1)),
      effectiveCdaPenalty: double.parse(cdaPenalty.toStringAsFixed(4)),
      shiveringIntensity: double.parse(shivering.toStringAsFixed(2)),
      shiveringGlycogenMultiplier: double.parse(shiveringGlycogenMult.toStringAsFixed(2)),
      statusDescription: desc,
    );
  }

  /// Taktyczna akcja kolarza / dyrektora sportowego: założenie kurtki przeciwdeszczowej lub kamizelki.
  ///
  /// Może nastąpić przed szczytem przełęczy lub na początku zjazdu.
  static RiderThermalSnapshot orderPutOnJacket({
    required RiderThermalSnapshot current,
    required RiderClothingType newClothing,
    ApparelTechnicalPerks? teamApparel,
  }) {
    if (newClothing == RiderClothingType.summerAeroJersey) {
      return orderTakeOffJacket(current: current);
    }

    double cda = newClothing.baseCdaPenalty;
    if (teamApparel != null && newClothing == RiderClothingType.rainJacket) {
      final double aeroImprovement = (teamApparel.customWindTunnelFittingsCount * 0.002).clamp(0.0, 0.010);
      cda = math.max(0.008, cda - aeroImprovement);
    }

    return current.copyWith(
      clothingType: newClothing,
      isJacketWorn: true,
      effectiveCdaPenalty: cda,
      statusDescription: 'Założono kurtkę ochronną (${newClothing.name}). Ochrona przed wiatrem i deszczem aktywna.',
    );
  }

  /// Taktyczna akcja kolarza / dyrektora sportowego: zdjęcie kurtki przeciwdeszczowej.
  ///
  /// Niezbędna po zjeździe do ciepłej doliny, aby uniknąć przegrzania na kolejnym podjeździe!
  static RiderThermalSnapshot orderTakeOffJacket({
    required RiderThermalSnapshot current,
  }) {
    return current.copyWith(
      clothingType: RiderClothingType.summerAeroJersey,
      isJacketWorn: false,
      effectiveCdaPenalty: 0.0,
      statusDescription: 'Zdjęto kurtkę przeciwdeszczową. Maksymalna aerodynamika i chłodzenie powrotne.',
    );
  }

  /// Inteligentne podejmowanie decyzji o odzieży dla kolarzy SI oraz rekomendacje dla gracza.
  ///
  /// Sprawdza profil trasy przed kolarzem na dystansie [lookaheadKm]:
  /// - Jeśli zbliża się szczyt przełęczy i rozpoczyna zjazd w deszczu/chłodzie (< 12°C), kolarz powinien założyć kurtkę!
  /// - Jeśli kolarz znajduje się w ciepłej dolinie (> 19°C) i rozpoczyna podjazd, musi zdjąć kurtkę, by się nie przegrzać!
  static TacticalClothingRecommendation evaluateTacticalClothingDecision({
    required RiderThermalSnapshot currentThermal,
    required LocalWeatherSnapshot currentWeather,
    required StageSegment currentSegment,
    StageSegment? nextSegment,
  }) {
    // 1. Sprawdzamy czy kolarz jest na podjeździe w dolinie i ma ubraną kurtkę
    if (currentThermal.isJacketWorn &&
        currentWeather.ambientTemperatureCelsius >= 18.0 &&
        currentSegment.isClimb) {
      return TacticalClothingRecommendation(
        recommendedAction: TacticalClothingAction.takeOffJacket,
        recommendedClothing: RiderClothingType.summerAeroJersey,
        priority: 0.90,
        reasonPl: 'Zdjęcie kurtki przed podjazdem w dolinie (+${currentWeather.ambientTemperatureCelsius.toStringAsFixed(1)}°C) – groźba przegrzania!',
      );
    }

    // 2. Sprawdzamy czy kolarz zbliża się do zjazdu z wysokiej przełęczy lub zjeżdża w zimnie
    final bool onOrApproachingColdDescent =
        (currentSegment.isDescent || (nextSegment != null && nextSegment.isDescent)) &&
        (currentWeather.apparentTemperatureCelsius <= 11.0 || currentWeather.weatherType.hasPrecipitation);

    if (!currentThermal.isJacketWorn && onOrApproachingColdDescent) {
      final targetClothing = currentWeather.apparentTemperatureCelsius <= 6.0
          ? RiderClothingType.rainJacket
          : RiderClothingType.windGilet;

      return TacticalClothingRecommendation(
        recommendedAction: TacticalClothingAction.putOnJacket,
        recommendedClothing: targetClothing,
        priority: 0.98,
        reasonPl: 'Konieczne założenie kurtki na zjazd z przełęczy! Temp. odczuwalna ${currentWeather.apparentTemperatureCelsius.toStringAsFixed(1)}°C grozi natychmiastową hipotermią i spadkiem mocy!',
      );
    }

    // 3. Kolarz już ma objawy hipotermii (drgawki) i nadal nie ma kurtki
    if (!currentThermal.isJacketWorn && currentThermal.hypothermiaStage != HypothermiaStage.none) {
      return const TacticalClothingRecommendation(
        recommendedAction: TacticalClothingAction.putOnJacket,
        recommendedClothing: RiderClothingType.rainJacket,
        priority: 1.00,
        reasonPl: 'PILNE: Kolarz trzęsie się z zimna! Załóż kurtkę membranową z wozu technicznego natychmiast!',
      );
    }

    return const TacticalClothingRecommendation(
      recommendedAction: TacticalClothingAction.maintainCurrent,
      recommendedClothing: RiderClothingType.summerAeroJersey,
      priority: 0.10,
      reasonPl: 'Aktualny stan odzieży jest optymalny.',
    );
  }
}

/// Typ rekomendacji taktycznej ubioru.
enum TacticalClothingAction {
  maintainCurrent,
  putOnJacket,
  takeOffJacket,
}

/// Raport rekomendacji taktycznej dla dyrektora sportowego.
class TacticalClothingRecommendation {
  final TacticalClothingAction recommendedAction;
  final RiderClothingType recommendedClothing;
  final double priority; // 0.0 - 1.0
  final String reasonPl;

  const TacticalClothingRecommendation({
    required this.recommendedAction,
    required this.recommendedClothing,
    required this.priority,
    required this.reasonPl,
  });
}
