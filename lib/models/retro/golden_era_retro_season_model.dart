import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable;

/// Dekady i epoki historyczne trybu „Złota Era Kolarstwa: 1970–2015”.
enum GoldenEraDecade {
  /// Lata 1970–1979: stal Columbus SL 9.2 kg, manetki cierne, wełniane koszulki, brak radia i watów.
  steelCannibalEra1970s,

  /// Lata 1980–1989: stal Columbus SLX, pierwsze rogi czasowe, nadal manetki na ramie i brak radia.
  badgerAndAeroDawn1980s,

  /// Lata 1990–1999: wczesne klamkomanetki STI/Ergopower, początki radia wyścigowego i lycry.
  stiAndRadioDawn1990s,

  /// Lata 2000–2015: karbon 6.8 kg, powszechne mierniki mocy i pełne radio drużynowe.
  carbonAndPowerEra2000s;

  String toJson() => name;

  static GoldenEraDecade fromJson(String value) {
    return GoldenEraDecade.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GoldenEraDecade.steelCannibalEra1970s,
    );
  }

  /// Dobiera epokę na podstawie roku (zakres 1970–2015).
  static GoldenEraDecade fromYear(int year) {
    final clamped = year.clamp(1970, 2015);
    if (clamped <= 1979) return GoldenEraDecade.steelCannibalEra1970s;
    if (clamped <= 1989) return GoldenEraDecade.badgerAndAeroDawn1980s;
    if (clamped <= 1999) return GoldenEraDecade.stiAndRadioDawn1990s;
    return GoldenEraDecade.carbonAndPowerEra2000s;
  }

  int get startYear {
    switch (this) {
      case GoldenEraDecade.steelCannibalEra1970s:
        return 1970;
      case GoldenEraDecade.badgerAndAeroDawn1980s:
        return 1980;
      case GoldenEraDecade.stiAndRadioDawn1990s:
        return 1990;
      case GoldenEraDecade.carbonAndPowerEra2000s:
        return 2000;
    }
  }

  int get endYear {
    switch (this) {
      case GoldenEraDecade.steelCannibalEra1970s:
        return 1979;
      case GoldenEraDecade.badgerAndAeroDawn1980s:
        return 1989;
      case GoldenEraDecade.stiAndRadioDawn1990s:
        return 1999;
      case GoldenEraDecade.carbonAndPowerEra2000s:
        return 2015;
    }
  }

  String get displayNamePl {
    switch (this) {
      case GoldenEraDecade.steelCannibalEra1970s:
        return '1970–1979 · Era Stali i Wełny';
      case GoldenEraDecade.badgerAndAeroDawn1980s:
        return '1980–1989 · Zmierzch Manetek Ciernych';
      case GoldenEraDecade.stiAndRadioDawn1990s:
        return '1990–1999 · Narodziny STI i Radia';
      case GoldenEraDecade.carbonAndPowerEra2000s:
        return '2000–2015 · Era Karbonu i Watów';
    }
  }

  String get displayNameEn {
    switch (this) {
      case GoldenEraDecade.steelCannibalEra1970s:
        return '1970–1979 · Steel & Wool Era';
      case GoldenEraDecade.badgerAndAeroDawn1980s:
        return '1980–1989 · Twilight of Friction Shifters';
      case GoldenEraDecade.stiAndRadioDawn1990s:
        return '1990–1999 · Dawn of STI & Race Radio';
      case GoldenEraDecade.carbonAndPowerEra2000s:
        return '2000–2015 · Carbon & Power Meter Era';
    }
  }

  RetroFrameMaterial get defaultFrameMaterial {
    switch (this) {
      case GoldenEraDecade.steelCannibalEra1970s:
        return RetroFrameMaterial.columbusSlSteel;
      case GoldenEraDecade.badgerAndAeroDawn1980s:
        return RetroFrameMaterial.columbusSlxSteel;
      case GoldenEraDecade.stiAndRadioDawn1990s:
        return RetroFrameMaterial.titaniumGr9;
      case GoldenEraDecade.carbonAndPowerEra2000s:
        return RetroFrameMaterial.earlyCarbonMonocoque;
    }
  }

  RetroShifterType get defaultShifterType {
    switch (this) {
      case GoldenEraDecade.steelCannibalEra1970s:
        return RetroShifterType.downtubeFriction;
      case GoldenEraDecade.badgerAndAeroDawn1980s:
        return RetroShifterType.downtubeIndexed;
      case GoldenEraDecade.stiAndRadioDawn1990s:
        return RetroShifterType.earlyIntegratedSti;
      case GoldenEraDecade.carbonAndPowerEra2000s:
        return RetroShifterType.modernMechanical11s;
    }
  }

  RetroJerseyMaterial get defaultJerseyMaterial {
    switch (this) {
      case GoldenEraDecade.steelCannibalEra1970s:
        return RetroJerseyMaterial.heavyMerinoWool;
      case GoldenEraDecade.badgerAndAeroDawn1980s:
        return RetroJerseyMaterial.woolAcrylicBlend;
      case GoldenEraDecade.stiAndRadioDawn1990s:
        return RetroJerseyMaterial.earlyPolyesterLycra;
      case GoldenEraDecade.carbonAndPowerEra2000s:
        return RetroJerseyMaterial.modernAeroSynthetic;
    }
  }

  RetroCommunicationMode get defaultCommunicationMode {
    switch (this) {
      case GoldenEraDecade.steelCannibalEra1970s:
      case GoldenEraDecade.badgerAndAeroDawn1980s:
        return RetroCommunicationMode.noRadioChalkboardAndMoto;
      case GoldenEraDecade.stiAndRadioDawn1990s:
        return RetroCommunicationMode.earlyOneWayRaceRadio;
      case GoldenEraDecade.carbonAndPowerEra2000s:
        return RetroCommunicationMode.fullTwoWayTeamRadio;
    }
  }

  RetroTelemetryMode get defaultTelemetryMode {
    switch (this) {
      case GoldenEraDecade.steelCannibalEra1970s:
        return RetroTelemetryMode.noPowerMeterRpeOnly;
      case GoldenEraDecade.badgerAndAeroDawn1980s:
        return RetroTelemetryMode.heartRateMonitorOnly;
      case GoldenEraDecade.stiAndRadioDawn1990s:
        return RetroTelemetryMode.earlySrmCrankPower;
      case GoldenEraDecade.carbonAndPowerEra2000s:
        return RetroTelemetryMode.fullPowerAndLiveWatts;
    }
  }

  String get tvFilterStyle {
    switch (this) {
      case GoldenEraDecade.steelCannibalEra1970s:
        return '16mm_sepia_grain';
      case GoldenEraDecade.badgerAndAeroDawn1980s:
        return 'vhs_analog_scanlines';
      case GoldenEraDecade.stiAndRadioDawn1990s:
        return 'pal_broadcast_crt';
      case GoldenEraDecade.carbonAndPowerEra2000s:
        return 'early_hd_broadcast';
    }
  }
}

/// Materiał i konstrukcja ramy historycznej.
enum RetroFrameMaterial {
  /// Legendarna stal chromowo-molibdenowa Columbus SL (kompletny rower 9.2 kg).
  columbusSlSteel,

  /// Klasyczna stal Reynolds 531 z mufami lutowanymi (9.5 kg).
  reynolds531Steel,

  /// Żebrowana stal wyścigowa Columbus SLX (9.0 kg).
  columbusSlxSteel,

  /// Klejone aluminium Vitus/Alan (8.3 kg, mniejsza sztywność boczna).
  bondedAluminum,

  /// Tytan 3Al-2.5V (7.9 kg, wysokie tłumienie).
  titaniumGr9,

  /// Wczesny karbon monocoque zgodny z limitem UCI 6.8 kg (7.1 kg).
  earlyCarbonMonocoque;

  String toJson() => name;

  static RetroFrameMaterial fromJson(String value) {
    return RetroFrameMaterial.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RetroFrameMaterial.columbusSlSteel,
    );
  }

  /// Domyślna masa kompletnego roweru wyścigowego [kg].
  double get defaultCompleteBikeWeightKg {
    switch (this) {
      case RetroFrameMaterial.columbusSlSteel:
        return 9.2;
      case RetroFrameMaterial.reynolds531Steel:
        return 9.5;
      case RetroFrameMaterial.columbusSlxSteel:
        return 9.0;
      case RetroFrameMaterial.bondedAluminum:
        return 8.3;
      case RetroFrameMaterial.titaniumGr9:
        return 7.9;
      case RetroFrameMaterial.earlyCarbonMonocoque:
        return 7.1;
    }
  }

  /// Współczynnik sztywności transferu mocy w sprincie (1.0 = nowoczesny karbon).
  double get sprintStiffnessFactor {
    switch (this) {
      case RetroFrameMaterial.columbusSlSteel:
        return 0.86;
      case RetroFrameMaterial.reynolds531Steel:
        return 0.83;
      case RetroFrameMaterial.columbusSlxSteel:
        return 0.89;
      case RetroFrameMaterial.bondedAluminum:
        return 0.81;
      case RetroFrameMaterial.titaniumGr9:
        return 0.91;
      case RetroFrameMaterial.earlyCarbonMonocoque:
        return 0.97;
    }
  }

  /// Tłumienie drgań na bruku i dziurawym asfalcie (0.0–1.0).
  double get vibrationDamping {
    switch (this) {
      case RetroFrameMaterial.columbusSlSteel:
        return 0.84;
      case RetroFrameMaterial.reynolds531Steel:
        return 0.86;
      case RetroFrameMaterial.columbusSlxSteel:
        return 0.80;
      case RetroFrameMaterial.bondedAluminum:
        return 0.58;
      case RetroFrameMaterial.titaniumGr9:
        return 0.88;
      case RetroFrameMaterial.earlyCarbonMonocoque:
        return 0.68;
    }
  }

  /// Czy rama posiada chromowane mufy lutowane (istotne dla renderera 3D).
  bool get hasChromedLugs {
    return this == RetroFrameMaterial.columbusSlSteel ||
        this == RetroFrameMaterial.reynolds531Steel ||
        this == RetroFrameMaterial.columbusSlxSteel;
  }

  String get displayNamePl {
    switch (this) {
      case RetroFrameMaterial.columbusSlSteel:
        return 'Stal Columbus SL (9.2 kg)';
      case RetroFrameMaterial.reynolds531Steel:
        return 'Stal Reynolds 531 (9.5 kg)';
      case RetroFrameMaterial.columbusSlxSteel:
        return 'Stal Columbus SLX (9.0 kg)';
      case RetroFrameMaterial.bondedAluminum:
        return 'Aluminium klejone (8.3 kg)';
      case RetroFrameMaterial.titaniumGr9:
        return 'Tytan 3Al-2.5V (7.9 kg)';
      case RetroFrameMaterial.earlyCarbonMonocoque:
        return 'Karbon Monocoque (7.1 kg)';
    }
  }

  String get displayNameEn {
    switch (this) {
      case RetroFrameMaterial.columbusSlSteel:
        return 'Columbus SL Steel (9.2 kg)';
      case RetroFrameMaterial.reynolds531Steel:
        return 'Reynolds 531 Steel (9.5 kg)';
      case RetroFrameMaterial.columbusSlxSteel:
        return 'Columbus SLX Steel (9.0 kg)';
      case RetroFrameMaterial.bondedAluminum:
        return 'Bonded Aluminum (8.3 kg)';
      case RetroFrameMaterial.titaniumGr9:
        return 'Titanium 3Al-2.5V (7.9 kg)';
      case RetroFrameMaterial.earlyCarbonMonocoque:
        return 'Early Carbon Monocoque (7.1 kg)';
    }
  }
}

/// Typ manetek zmiany biegów w epoce historycznej.
enum RetroShifterType {
  /// Manetki cierne na dolnej rurze ramy — wymagają wyczucia i zdjęcia ręki z kierownicy.
  downtubeFriction,

  /// Manetki indeksowane na dolnej rurze ramy.
  downtubeIndexed,

  /// Wczesne klamkomanetki STI / Ergopower (lata 90.).
  earlyIntegratedSti,

  /// Precyzyjne mechaniczne klamkomanetki 10–11s.
  modernMechanical11s;

  String toJson() => name;

  static RetroShifterType fromJson(String value) {
    return RetroShifterType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RetroShifterType.downtubeFriction,
    );
  }

  /// Opóźnienie zmiany przełożenia [s] wynikające z sięgania do dolnej rury lub mechaniki.
  double get shiftDelaySeconds {
    switch (this) {
      case RetroShifterType.downtubeFriction:
        return 1.45;
      case RetroShifterType.downtubeIndexed:
        return 0.95;
      case RetroShifterType.earlyIntegratedSti:
        return 0.35;
      case RetroShifterType.modernMechanical11s:
        return 0.18;
    }
  }

  /// Bazowe prawdopodobieństwo nieprecyzyjnej zmiany biegu (np. ocieranie łańcucha / pudło).
  double get misshiftProbability {
    switch (this) {
      case RetroShifterType.downtubeFriction:
        return 0.16;
      case RetroShifterType.downtubeIndexed:
        return 0.06;
      case RetroShifterType.earlyIntegratedSti:
        return 0.02;
      case RetroShifterType.modernMechanical11s:
        return 0.005;
    }
  }

  /// Czy zmiana biegu wymaga zdjęcia jednej ręki z kierownicy.
  bool get requiresHandOffBar {
    return this == RetroShifterType.downtubeFriction ||
        this == RetroShifterType.downtubeIndexed;
  }

  String get displayNamePl {
    switch (this) {
      case RetroShifterType.downtubeFriction:
        return 'Manetki cierne (dolna rura)';
      case RetroShifterType.downtubeIndexed:
        return 'Manetki indeksowane (dolna rura)';
      case RetroShifterType.earlyIntegratedSti:
        return 'Wczesne klamkomanetki STI/Ergopower';
      case RetroShifterType.modernMechanical11s:
        return 'Klamkomanetki 10–11s';
    }
  }

  String get displayNameEn {
    switch (this) {
      case RetroShifterType.downtubeFriction:
        return 'Downtube Friction Shifters';
      case RetroShifterType.downtubeIndexed:
        return 'Downtube Indexed Shifters';
      case RetroShifterType.earlyIntegratedSti:
        return 'Early STI / Ergopower Levers';
      case RetroShifterType.modernMechanical11s:
        return '10–11s Integrated Mechanical';
    }
  }
}

/// Materiał stroju kolarskiego i jego zachowanie w deszczu.
enum RetroJerseyMaterial {
  /// Gruba wełna merynosowa — mocno nasiąka wodą w deszczu (+1.4 kg) i wychładza.
  heavyMerinoWool,

  /// Mieszanka wełny z akrylem — umiarkowane nasiąkanie (+0.85 kg).
  woolAcrylicBlend,

  /// Wczesny poliester / lycra — słabe nasiąkanie (+0.25 kg).
  earlyPolyesterLycra,

  /// Nowoczesna tkanina hydrofobowa (+0.08 kg).
  modernAeroSynthetic;

  String toJson() => name;

  static RetroJerseyMaterial fromJson(String value) {
    return RetroJerseyMaterial.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RetroJerseyMaterial.heavyMerinoWool,
    );
  }

  /// Masa suchego stroju [g].
  int get dryWeightGrams {
    switch (this) {
      case RetroJerseyMaterial.heavyMerinoWool:
        return 420;
      case RetroJerseyMaterial.woolAcrylicBlend:
        return 330;
      case RetroJerseyMaterial.earlyPolyesterLycra:
        return 210;
      case RetroJerseyMaterial.modernAeroSynthetic:
        return 145;
    }
  }

  /// Maksymalna ilość wody pochłaniana przez materiał podczas ulewy [g].
  int get maxWaterAbsorptionGrams {
    switch (this) {
      case RetroJerseyMaterial.heavyMerinoWool:
        return 1400;
      case RetroJerseyMaterial.woolAcrylicBlend:
        return 850;
      case RetroJerseyMaterial.earlyPolyesterLycra:
        return 250;
      case RetroJerseyMaterial.modernAeroSynthetic:
        return 80;
    }
  }

  /// Maksymalna kara aerodynamiczna CdA wynikająca z rozciągniętej mokrej koszulki [m^2].
  double get maxWetCdaPenalty {
    switch (this) {
      case RetroJerseyMaterial.heavyMerinoWool:
        return 0.018;
      case RetroJerseyMaterial.woolAcrylicBlend:
        return 0.011;
      case RetroJerseyMaterial.earlyPolyesterLycra:
        return 0.004;
      case RetroJerseyMaterial.modernAeroSynthetic:
        return 0.001;
    }
  }

  /// Współczynnik wychłodzenia wiatrem przy przemoczonej koszulce (0.0–1.0).
  double get wetThermalChillFactor {
    switch (this) {
      case RetroJerseyMaterial.heavyMerinoWool:
        return 0.72;
      case RetroJerseyMaterial.woolAcrylicBlend:
        return 0.55;
      case RetroJerseyMaterial.earlyPolyesterLycra:
        return 0.28;
      case RetroJerseyMaterial.modernAeroSynthetic:
        return 0.12;
    }
  }

  String get displayNamePl {
    switch (this) {
      case RetroJerseyMaterial.heavyMerinoWool:
        return 'Koszulka wełniana 100% (nasiąka do +1.4 kg)';
      case RetroJerseyMaterial.woolAcrylicBlend:
        return 'Wełna z akrylem (nasiąka do +0.85 kg)';
      case RetroJerseyMaterial.earlyPolyesterLycra:
        return 'Wczesna Lycra / Poliester';
      case RetroJerseyMaterial.modernAeroSynthetic:
        return 'Nowoczesna tkanina hydrofobowa';
    }
  }

  String get displayNameEn {
    switch (this) {
      case RetroJerseyMaterial.heavyMerinoWool:
        return '100% Merino Wool Jersey (absorbs up to +1.4 kg)';
      case RetroJerseyMaterial.woolAcrylicBlend:
        return 'Wool-Acrylic Blend (absorbs up to +0.85 kg)';
      case RetroJerseyMaterial.earlyPolyesterLycra:
        return 'Early Polyester / Lycra';
      case RetroJerseyMaterial.modernAeroSynthetic:
        return 'Modern Hydrophobic Aero Fabric';
    }
  }
}

/// Tryb łączności taktycznej między dyrektorem sportowym a kolarzem.
enum RetroCommunicationMode {
  /// Brak radia wyścigowego — tylko tabliczka z motocykla (Ardoise) i wóz techniczny.
  noRadioChalkboardAndMoto,

  /// Wczesne radio jednokierunkowe z opóźnionymi komunikatami o różnicach.
  earlyOneWayRaceRadio,

  /// Pełne dwukierunkowe radio drużynowe z natychmiastową komunikacją.
  fullTwoWayTeamRadio;

  String toJson() => name;

  static RetroCommunicationMode fromJson(String value) {
    return RetroCommunicationMode.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RetroCommunicationMode.noRadioChalkboardAndMoto,
    );
  }

  /// Opóźnienie aktualizacji różnic czasowych [s] (tabliczka Ardoise ~45 s).
  int get timeGapUpdateDelaySeconds {
    switch (this) {
      case RetroCommunicationMode.noRadioChalkboardAndMoto:
        return 45;
      case RetroCommunicationMode.earlyOneWayRaceRadio:
        return 12;
      case RetroCommunicationMode.fullTwoWayTeamRadio:
        return 1;
    }
  }

  /// Opóźnienie wykonania rozkazu taktycznego DS [s].
  int get tacticalOrderLatencySeconds {
    switch (this) {
      case RetroCommunicationMode.noRadioChalkboardAndMoto:
        return 90;
      case RetroCommunicationMode.earlyOneWayRaceRadio:
        return 20;
      case RetroCommunicationMode.fullTwoWayTeamRadio:
        return 2;
    }
  }

  /// Czy można wydawać natychmiastowe rozkazy przez radio.
  bool get supportsInstantOrders =>
      this == RetroCommunicationMode.fullTwoWayTeamRadio;

  /// Mnożnik ryzyka przegapienia groźnej ucieczki z powodu braku radia.
  double get blindBreakawayRiskMultiplier {
    switch (this) {
      case RetroCommunicationMode.noRadioChalkboardAndMoto:
        return 1.65;
      case RetroCommunicationMode.earlyOneWayRaceRadio:
        return 1.20;
      case RetroCommunicationMode.fullTwoWayTeamRadio:
        return 1.0;
    }
  }

  String get displayNamePl {
    switch (this) {
      case RetroCommunicationMode.noRadioChalkboardAndMoto:
        return 'Brak radia (tabliczka Ardoise i wóz)';
      case RetroCommunicationMode.earlyOneWayRaceRadio:
        return 'Wczesne radio jednokierunkowe';
      case RetroCommunicationMode.fullTwoWayTeamRadio:
        return 'Pełne radio wyścigowe';
    }
  }

  String get displayNameEn {
    switch (this) {
      case RetroCommunicationMode.noRadioChalkboardAndMoto:
        return 'No Race Radio (Chalkboard & Team Car)';
      case RetroCommunicationMode.earlyOneWayRaceRadio:
        return 'Early One-Way Race Radio';
      case RetroCommunicationMode.fullTwoWayTeamRadio:
        return 'Full Two-Way Team Radio';
    }
  }
}

/// Tryb telemetrii fizjologicznej kolarza podczas wyścigu.
enum RetroTelemetryMode {
  /// Brak miernika mocy i pulsometru — wyłącznie subiektywna skala RPE (Borg 6–20).
  noPowerMeterRpeOnly,

  /// Sam pulsometr — brak watów, widoczny jedynie puls z dryfem sercowym.
  heartRateMonitorOnly,

  /// Wczesny miernik SRM z opóźnieniem i szumem odczytu.
  earlySrmCrankPower,

  /// Pełna nowoczesna telemetria mocy (W, W/kg, W').
  fullPowerAndLiveWatts;

  String toJson() => name;

  static RetroTelemetryMode fromJson(String value) {
    return RetroTelemetryMode.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RetroTelemetryMode.noPowerMeterRpeOnly,
    );
  }

  bool get showsLiveWatts =>
      this == RetroTelemetryMode.earlySrmCrankPower ||
      this == RetroTelemetryMode.fullPowerAndLiveWatts;

  bool get showsLiveHeartRate =>
      this != RetroTelemetryMode.noPowerMeterRpeOnly;

  /// Błąd szacowania wysiłku przez kolarza (0.0 = idealna precyzja, 0.16 = ±16% przy RPE).
  double get rpeEstimationErrorFactor {
    switch (this) {
      case RetroTelemetryMode.noPowerMeterRpeOnly:
        return 0.16;
      case RetroTelemetryMode.heartRateMonitorOnly:
        return 0.10;
      case RetroTelemetryMode.earlySrmCrankPower:
        return 0.04;
      case RetroTelemetryMode.fullPowerAndLiveWatts:
        return 0.0;
    }
  }

  /// Mnożnik ryzyka odcięcia energetycznego ("ściany") z powodu braku kontroli watów.
  double get bonkRiskMultiplier {
    switch (this) {
      case RetroTelemetryMode.noPowerMeterRpeOnly:
        return 1.45;
      case RetroTelemetryMode.heartRateMonitorOnly:
        return 1.22;
      case RetroTelemetryMode.earlySrmCrankPower:
        return 1.05;
      case RetroTelemetryMode.fullPowerAndLiveWatts:
        return 1.0;
    }
  }

  String get displayNamePl {
    switch (this) {
      case RetroTelemetryMode.noPowerMeterRpeOnly:
        return 'Brak miernika mocy (tylko RPE Borg 6–20)';
      case RetroTelemetryMode.heartRateMonitorOnly:
        return 'Tylko pulsometr (brak watów)';
      case RetroTelemetryMode.earlySrmCrankPower:
        return 'Wczesny miernik mocy SRM';
      case RetroTelemetryMode.fullPowerAndLiveWatts:
        return 'Pełny miernik mocy (W / W/kg)';
    }
  }

  String get displayNameEn {
    switch (this) {
      case RetroTelemetryMode.noPowerMeterRpeOnly:
        return 'No Power Meter (RPE Borg 6–20 Only)';
      case RetroTelemetryMode.heartRateMonitorOnly:
        return 'Heart Rate Monitor Only';
      case RetroTelemetryMode.earlySrmCrankPower:
        return 'Early SRM Crank Power Meter';
      case RetroTelemetryMode.fullPowerAndLiveWatts:
        return 'Full Live Power Telemetry';
    }
  }
}

/// Konfiguracja historycznego sprzętu drużyny w trybie Złotej Ery.
@immutable
class RetroEquipmentSetup {
  final RetroFrameMaterial frameMaterial;
  final String frameName;
  final double completeBikeWeightKg;
  final RetroShifterType shifterType;
  final int rearSpeedCount;
  final List<int> frontChainrings;
  final int rearFreewheelMinTeeth;
  final int rearFreewheelMaxTeeth;
  final RetroJerseyMaterial jerseyMaterial;
  final bool hasToeClipsAndStraps;
  final bool hasHardShellHelmet;
  final bool handlebarBottleCage;

  const RetroEquipmentSetup({
    required this.frameMaterial,
    required this.frameName,
    required this.completeBikeWeightKg,
    required this.shifterType,
    required this.rearSpeedCount,
    required this.frontChainrings,
    required this.rearFreewheelMinTeeth,
    required this.rearFreewheelMaxTeeth,
    required this.jerseyMaterial,
    required this.hasToeClipsAndStraps,
    required this.hasHardShellHelmet,
    required this.handlebarBottleCage,
  });

  /// Klasyczny zestaw z lat 70.: stalowa rama Columbus SL 9.2 kg, manetki cierne 5s, wełniana koszulka.
  factory RetroEquipmentSetup.columbusSlClassic() {
    return const RetroEquipmentSetup(
      frameMaterial: RetroFrameMaterial.columbusSlSteel,
      frameName: 'Columbus SL Lugged Steel',
      completeBikeWeightKg: 9.2,
      shifterType: RetroShifterType.downtubeFriction,
      rearSpeedCount: 5,
      frontChainrings: [52, 42],
      rearFreewheelMinTeeth: 13,
      rearFreewheelMaxTeeth: 21,
      jerseyMaterial: RetroJerseyMaterial.heavyMerinoWool,
      hasToeClipsAndStraps: true,
      hasHardShellHelmet: false,
      handlebarBottleCage: true,
    );
  }

  /// Tworzy domyślną konfigurację sprzętową dla wybranego roku (1970–2015).
  factory RetroEquipmentSetup.forYear(int year) {
    final decade = GoldenEraDecade.fromYear(year);
    switch (decade) {
      case GoldenEraDecade.steelCannibalEra1970s:
        return RetroEquipmentSetup.columbusSlClassic();
      case GoldenEraDecade.badgerAndAeroDawn1980s:
        return const RetroEquipmentSetup(
          frameMaterial: RetroFrameMaterial.columbusSlxSteel,
          frameName: 'Columbus SLX Racing Steel',
          completeBikeWeightKg: 9.0,
          shifterType: RetroShifterType.downtubeIndexed,
          rearSpeedCount: 7,
          frontChainrings: [53, 42],
          rearFreewheelMinTeeth: 12,
          rearFreewheelMaxTeeth: 23,
          jerseyMaterial: RetroJerseyMaterial.woolAcrylicBlend,
          hasToeClipsAndStraps: false,
          hasHardShellHelmet: false,
          handlebarBottleCage: false,
        );
      case GoldenEraDecade.stiAndRadioDawn1990s:
        return const RetroEquipmentSetup(
          frameMaterial: RetroFrameMaterial.titaniumGr9,
          frameName: 'Titanium 3Al-2.5V Team Issue',
          completeBikeWeightKg: 7.9,
          shifterType: RetroShifterType.earlyIntegratedSti,
          rearSpeedCount: 9,
          frontChainrings: [53, 39],
          rearFreewheelMinTeeth: 11,
          rearFreewheelMaxTeeth: 25,
          jerseyMaterial: RetroJerseyMaterial.earlyPolyesterLycra,
          hasToeClipsAndStraps: false,
          hasHardShellHelmet: false,
          handlebarBottleCage: false,
        );
      case GoldenEraDecade.carbonAndPowerEra2000s:
        return const RetroEquipmentSetup(
          frameMaterial: RetroFrameMaterial.earlyCarbonMonocoque,
          frameName: 'Carbon Monocoque 6.8 Pro',
          completeBikeWeightKg: 7.1,
          shifterType: RetroShifterType.modernMechanical11s,
          rearSpeedCount: 11,
          frontChainrings: [53, 39],
          rearFreewheelMinTeeth: 11,
          rearFreewheelMaxTeeth: 28,
          jerseyMaterial: RetroJerseyMaterial.modernAeroSynthetic,
          hasToeClipsAndStraps: false,
          hasHardShellHelmet: true,
          handlebarBottleCage: false,
        );
    }
  }

  /// Dodatkowa masa wody [kg] wchłonięta przez koszulkę przy zadanym deszczu i nasiąknięciu (0..1).
  double calculateWetJerseyAddedWeightKg({
    required double rainIntensity01,
    required double wetnessProgress01,
  }) {
    final rain = rainIntensity01.clamp(0.0, 1.0);
    final progress = wetnessProgress01.clamp(0.0, 1.0);
    final effectiveSaturation = math.max(progress, rain * 0.35).clamp(0.0, 1.0);
    return (jerseyMaterial.maxWaterAbsorptionGrams / 1000.0) * effectiveSaturation;
  }

  /// Całkowita masa systemu (kolarz + rower + woda w koszulce) [kg].
  double calculateEffectiveSystemWeightKg({
    required double riderWeightKg,
    required double rainIntensity01,
    required double wetnessProgress01,
  }) {
    final safeRiderKg = riderWeightKg.clamp(45.0, 110.0);
    final wetAddedKg = calculateWetJerseyAddedWeightKg(
      rainIntensity01: rainIntensity01,
      wetnessProgress01: wetnessProgress01,
    );
    return safeRiderKg + completeBikeWeightKg + wetAddedKg;
  }

  /// Dodatkowy opór aerodynamiczny CdA [m^2] z tytułu historycznych detali (bidon na kierownicy, mokra wełna).
  double calculateAeroCdaPenalty(double wetnessProgress01) {
    final clampedWet = wetnessProgress01.clamp(0.0, 1.0);
    double penalty = jerseyMaterial.maxWetCdaPenalty * clampedWet;
    if (handlebarBottleCage) {
      penalty += 0.008;
    }
    if (hasToeClipsAndStraps) {
      penalty += 0.003;
    }
    return penalty;
  }

  /// Najcięższe i najlżejsze przełożenie jako czytelna etykieta (np. `52/42T × 13-21T`).
  String get drivetrainSummary {
    final rings = frontChainrings.isEmpty ? '52/42' : frontChainrings.join('/');
    return '${rings}T × $rearFreewheelMinTeeth-${rearFreewheelMaxTeeth}T (${rearSpeedCount}s)';
  }

  RetroEquipmentSetup copyWith({
    RetroFrameMaterial? frameMaterial,
    String? frameName,
    double? completeBikeWeightKg,
    RetroShifterType? shifterType,
    int? rearSpeedCount,
    List<int>? frontChainrings,
    int? rearFreewheelMinTeeth,
    int? rearFreewheelMaxTeeth,
    RetroJerseyMaterial? jerseyMaterial,
    bool? hasToeClipsAndStraps,
    bool? hasHardShellHelmet,
    bool? handlebarBottleCage,
  }) {
    return RetroEquipmentSetup(
      frameMaterial: frameMaterial ?? this.frameMaterial,
      frameName: frameName ?? this.frameName,
      completeBikeWeightKg: completeBikeWeightKg ?? this.completeBikeWeightKg,
      shifterType: shifterType ?? this.shifterType,
      rearSpeedCount: rearSpeedCount ?? this.rearSpeedCount,
      frontChainrings: frontChainrings != null
          ? List<int>.unmodifiable(frontChainrings)
          : this.frontChainrings,
      rearFreewheelMinTeeth: rearFreewheelMinTeeth ?? this.rearFreewheelMinTeeth,
      rearFreewheelMaxTeeth: rearFreewheelMaxTeeth ?? this.rearFreewheelMaxTeeth,
      jerseyMaterial: jerseyMaterial ?? this.jerseyMaterial,
      hasToeClipsAndStraps: hasToeClipsAndStraps ?? this.hasToeClipsAndStraps,
      hasHardShellHelmet: hasHardShellHelmet ?? this.hasHardShellHelmet,
      handlebarBottleCage: handlebarBottleCage ?? this.handlebarBottleCage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frameMaterial': frameMaterial.toJson(),
      'frameName': frameName,
      'completeBikeWeightKg': completeBikeWeightKg,
      'shifterType': shifterType.toJson(),
      'rearSpeedCount': rearSpeedCount,
      'frontChainrings': frontChainrings,
      'rearFreewheelMinTeeth': rearFreewheelMinTeeth,
      'rearFreewheelMaxTeeth': rearFreewheelMaxTeeth,
      'jerseyMaterial': jerseyMaterial.toJson(),
      'hasToeClipsAndStraps': hasToeClipsAndStraps,
      'hasHardShellHelmet': hasHardShellHelmet,
      'handlebarBottleCage': handlebarBottleCage,
    };
  }

  factory RetroEquipmentSetup.fromJson(Map<String, dynamic> json) {
    final parsedRings = (json['frontChainrings'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        const [52, 42];
    return RetroEquipmentSetup(
      frameMaterial: RetroFrameMaterial.fromJson(
        json['frameMaterial'] as String? ?? 'columbusSlSteel',
      ),
      frameName: json['frameName'] as String? ?? 'Columbus SL Lugged Steel',
      completeBikeWeightKg:
          (json['completeBikeWeightKg'] as num?)?.toDouble() ?? 9.2,
      shifterType: RetroShifterType.fromJson(
        json['shifterType'] as String? ?? 'downtubeFriction',
      ),
      rearSpeedCount: (json['rearSpeedCount'] as num?)?.toInt() ?? 5,
      frontChainrings: List<int>.unmodifiable(parsedRings),
      rearFreewheelMinTeeth:
          (json['rearFreewheelMinTeeth'] as num?)?.toInt() ?? 13,
      rearFreewheelMaxTeeth:
          (json['rearFreewheelMaxTeeth'] as num?)?.toInt() ?? 21,
      jerseyMaterial: RetroJerseyMaterial.fromJson(
        json['jerseyMaterial'] as String? ?? 'heavyMerinoWool',
      ),
      hasToeClipsAndStraps: json['hasToeClipsAndStraps'] as bool? ?? true,
      hasHardShellHelmet: json['hasHardShellHelmet'] as bool? ?? false,
      handlebarBottleCage: json['handlebarBottleCage'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RetroEquipmentSetup) return false;
    if (other.frameMaterial != frameMaterial ||
        other.frameName != frameName ||
        other.completeBikeWeightKg != completeBikeWeightKg ||
        other.shifterType != shifterType ||
        other.rearSpeedCount != rearSpeedCount ||
        other.rearFreewheelMinTeeth != rearFreewheelMinTeeth ||
        other.rearFreewheelMaxTeeth != rearFreewheelMaxTeeth ||
        other.jerseyMaterial != jerseyMaterial ||
        other.hasToeClipsAndStraps != hasToeClipsAndStraps ||
        other.hasHardShellHelmet != hasHardShellHelmet ||
        other.handlebarBottleCage != handlebarBottleCage ||
        other.frontChainrings.length != frontChainrings.length) {
      return false;
    }
    for (int i = 0; i < frontChainrings.length; i++) {
      if (other.frontChainrings[i] != frontChainrings[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        frameMaterial,
        frameName,
        completeBikeWeightKg,
        shifterType,
        rearSpeedCount,
        Object.hashAll(frontChainrings),
        rearFreewheelMinTeeth,
        rearFreewheelMaxTeeth,
        jerseyMaterial,
        hasToeClipsAndStraps,
        hasHardShellHelmet,
        handlebarBottleCage,
      );
}

/// Regulamin i ograniczenia technologiczne wybranego roku historycznego (1970–2015).
@immutable
class RetroSeasonRuleset {
  final int year;
  final GoldenEraDecade era;
  final RetroCommunicationMode communicationMode;
  final RetroTelemetryMode telemetryMode;
  final int maxRidersPerTeam;
  final double uciMinimumWeightKg;
  final bool mandatoryHelmetRule;
  final bool allowNeutralServiceMoto;

  const RetroSeasonRuleset({
    required this.year,
    required this.era,
    required this.communicationMode,
    required this.telemetryMode,
    required this.maxRidersPerTeam,
    required this.uciMinimumWeightKg,
    required this.mandatoryHelmetRule,
    required this.allowNeutralServiceMoto,
  });

  factory RetroSeasonRuleset.forYear(int year) {
    final safeYear = year.clamp(1970, 2015);
    final era = GoldenEraDecade.fromYear(safeYear);
    return RetroSeasonRuleset(
      year: safeYear,
      era: era,
      communicationMode: era.defaultCommunicationMode,
      telemetryMode: era.defaultTelemetryMode,
      maxRidersPerTeam: safeYear < 1988 ? 10 : 9,
      uciMinimumWeightKg: safeYear >= 2000 ? 6.8 : 0.0,
      mandatoryHelmetRule: safeYear >= 2003,
      allowNeutralServiceMoto: safeYear >= 1973,
    );
  }

  bool get hasRaceRadio =>
      communicationMode != RetroCommunicationMode.noRadioChalkboardAndMoto;

  bool get hasPowerMeter => telemetryMode.showsLiveWatts;

  RetroSeasonRuleset copyWith({
    int? year,
    GoldenEraDecade? era,
    RetroCommunicationMode? communicationMode,
    RetroTelemetryMode? telemetryMode,
    int? maxRidersPerTeam,
    double? uciMinimumWeightKg,
    bool? mandatoryHelmetRule,
    bool? allowNeutralServiceMoto,
  }) {
    return RetroSeasonRuleset(
      year: year ?? this.year,
      era: era ?? this.era,
      communicationMode: communicationMode ?? this.communicationMode,
      telemetryMode: telemetryMode ?? this.telemetryMode,
      maxRidersPerTeam: maxRidersPerTeam ?? this.maxRidersPerTeam,
      uciMinimumWeightKg: uciMinimumWeightKg ?? this.uciMinimumWeightKg,
      mandatoryHelmetRule: mandatoryHelmetRule ?? this.mandatoryHelmetRule,
      allowNeutralServiceMoto:
          allowNeutralServiceMoto ?? this.allowNeutralServiceMoto,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'era': era.toJson(),
      'communicationMode': communicationMode.toJson(),
      'telemetryMode': telemetryMode.toJson(),
      'maxRidersPerTeam': maxRidersPerTeam,
      'uciMinimumWeightKg': uciMinimumWeightKg,
      'mandatoryHelmetRule': mandatoryHelmetRule,
      'allowNeutralServiceMoto': allowNeutralServiceMoto,
    };
  }

  factory RetroSeasonRuleset.fromJson(Map<String, dynamic> json) {
    final parsedYear = ((json['year'] as num?)?.toInt() ?? 1976).clamp(1970, 2015);
    return RetroSeasonRuleset(
      year: parsedYear,
      era: RetroDecadeParser.parse(json['era'] as String?, parsedYear),
      communicationMode: RetroCommunicationMode.fromJson(
        json['communicationMode'] as String? ?? 'noRadioChalkboardAndMoto',
      ),
      telemetryMode: RetroTelemetryMode.fromJson(
        json['telemetryMode'] as String? ?? 'noPowerMeterRpeOnly',
      ),
      maxRidersPerTeam: (json['maxRidersPerTeam'] as num?)?.toInt() ?? 10,
      uciMinimumWeightKg:
          (json['uciMinimumWeightKg'] as num?)?.toDouble() ?? 0.0,
      mandatoryHelmetRule: json['mandatoryHelmetRule'] as bool? ?? false,
      allowNeutralServiceMoto:
          json['allowNeutralServiceMoto'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RetroSeasonRuleset &&
        other.year == year &&
        other.era == era &&
        other.communicationMode == communicationMode &&
        other.telemetryMode == telemetryMode &&
        other.maxRidersPerTeam == maxRidersPerTeam &&
        other.uciMinimumWeightKg == uciMinimumWeightKg &&
        other.mandatoryHelmetRule == mandatoryHelmetRule &&
        other.allowNeutralServiceMoto == allowNeutralServiceMoto;
  }

  @override
  int get hashCode => Object.hash(
        year,
        era,
        communicationMode,
        telemetryMode,
        maxRidersPerTeam,
        uciMinimumWeightKg,
        mandatoryHelmetRule,
        allowNeutralServiceMoto,
      );
}

class RetroDecadeParser {
  RetroDecadeParser._();

  static GoldenEraDecade parse(String? raw, int fallbackYear) {
    if (raw == null || raw.isEmpty) {
      return GoldenEraDecade.fromYear(fallbackYear);
    }
    return GoldenEraDecade.values.firstWhere(
      (e) => e.name.toLowerCase() == raw.toLowerCase(),
      orElse: () => GoldenEraDecade.fromYear(fallbackYear),
    );
  }
}

/// Historyczny wyścig z kalendarza kampanii Złotej Ery.
@immutable
class RetroHistoricalRaceEvent {
  final String id;
  final String name;
  final int year;
  final String countryCode;
  final double distanceKm;
  final int elevationGainMeters;
  final bool isMonument;
  final bool isGrandTour;
  final String historicalWinner;
  final int historicalWinningMarginSeconds;
  final double rainProbability;
  final int cobbleSectorsCount;
  final String surfaceSummaryPl;
  final String surfaceSummaryEn;

  const RetroHistoricalRaceEvent({
    required this.id,
    required this.name,
    required this.year,
    required this.countryCode,
    required this.distanceKm,
    required this.elevationGainMeters,
    required this.isMonument,
    required this.isGrandTour,
    required this.historicalWinner,
    required this.historicalWinningMarginSeconds,
    required this.rainProbability,
    required this.cobbleSectorsCount,
    required this.surfaceSummaryPl,
    required this.surfaceSummaryEn,
  });

  RetroHistoricalRaceEvent copyWith({
    String? id,
    String? name,
    int? year,
    String? countryCode,
    double? distanceKm,
    int? elevationGainMeters,
    bool? isMonument,
    bool? isGrandTour,
    String? historicalWinner,
    int? historicalWinningMarginSeconds,
    double? rainProbability,
    int? cobbleSectorsCount,
    String? surfaceSummaryPl,
    String? surfaceSummaryEn,
  }) {
    return RetroHistoricalRaceEvent(
      id: id ?? this.id,
      name: name ?? this.name,
      year: year ?? this.year,
      countryCode: countryCode ?? this.countryCode,
      distanceKm: distanceKm ?? this.distanceKm,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      isMonument: isMonument ?? this.isMonument,
      isGrandTour: isGrandTour ?? this.isGrandTour,
      historicalWinner: historicalWinner ?? this.historicalWinner,
      historicalWinningMarginSeconds:
          historicalWinningMarginSeconds ?? this.historicalWinningMarginSeconds,
      rainProbability: rainProbability ?? this.rainProbability,
      cobbleSectorsCount: cobbleSectorsCount ?? this.cobbleSectorsCount,
      surfaceSummaryPl: surfaceSummaryPl ?? this.surfaceSummaryPl,
      surfaceSummaryEn: surfaceSummaryEn ?? this.surfaceSummaryEn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'year': year,
      'countryCode': countryCode,
      'distanceKm': distanceKm,
      'elevationGainMeters': elevationGainMeters,
      'isMonument': isMonument,
      'isGrandTour': isGrandTour,
      'historicalWinner': historicalWinner,
      'historicalWinningMarginSeconds': historicalWinningMarginSeconds,
      'rainProbability': rainProbability,
      'cobbleSectorsCount': cobbleSectorsCount,
      'surfaceSummaryPl': surfaceSummaryPl,
      'surfaceSummaryEn': surfaceSummaryEn,
    };
  }

  factory RetroHistoricalRaceEvent.fromJson(Map<String, dynamic> json) {
    return RetroHistoricalRaceEvent(
      id: json['id'] as String? ?? 'retro_event',
      name: json['name'] as String? ?? 'Paris–Roubaix',
      year: (json['year'] as num?)?.toInt() ?? 1976,
      countryCode: json['countryCode'] as String? ?? 'FR',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 270.0,
      elevationGainMeters: (json['elevationGainMeters'] as num?)?.toInt() ?? 1400,
      isMonument: json['isMonument'] as bool? ?? true,
      isGrandTour: json['isGrandTour'] as bool? ?? false,
      historicalWinner: json['historicalWinner'] as String? ?? 'Marc Demeyer',
      historicalWinningMarginSeconds:
          (json['historicalWinningMarginSeconds'] as num?)?.toInt() ?? 0,
      rainProbability: (json['rainProbability'] as num?)?.toDouble() ?? 0.45,
      cobbleSectorsCount: (json['cobbleSectorsCount'] as num?)?.toInt() ?? 22,
      surfaceSummaryPl: json['surfaceSummaryPl'] as String? ??
          'Surowy bruk północny i szutrowe pobocza',
      surfaceSummaryEn: json['surfaceSummaryEn'] as String? ??
          'Raw northern cobbles and gravel verges',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RetroHistoricalRaceEvent &&
        other.id == id &&
        other.year == year &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, year, name);
}

/// Główny model sezonu i kampanii historycznej „Złota Era Kolarstwa: 1970–2015”.
@immutable
class GoldenEraRetroSeasonModel {
  final String seasonId;
  final String campaignTitle;
  final int seasonYear;
  final RetroSeasonRuleset ruleset;
  final String teamName;
  final RetroEquipmentSetup teamEquipment;
  final List<RetroHistoricalRaceEvent> calendarEvents;
  final List<String> completedEventIds;
  final int seasonPrestigePoints;
  final double historicalAuthenticityScore;
  final double activeWetnessFactor;

  const GoldenEraRetroSeasonModel({
    required this.seasonId,
    required this.campaignTitle,
    required this.seasonYear,
    required this.ruleset,
    required this.teamName,
    required this.teamEquipment,
    required this.calendarEvents,
    required this.completedEventIds,
    required this.seasonPrestigePoints,
    required this.historicalAuthenticityScore,
    required this.activeWetnessFactor,
  });

  /// Sztandarowy preset 1976: stal Columbus SL 9.2 kg, manetki cierne, wełniana koszulka, brak watów i radia.
  factory GoldenEraRetroSeasonModel.columbusSl1976Classic({
    String teamName = 'Molteni–Columbus',
    String seasonId = 'retro_1976_columbus_sl',
  }) {
    return GoldenEraRetroSeasonModel(
      seasonId: seasonId,
      campaignTitle: 'Złota Era 1976 · Stal Columbus SL & Wełna',
      seasonYear: 1976,
      ruleset: RetroSeasonRuleset.forYear(1976),
      teamName: teamName,
      teamEquipment: RetroEquipmentSetup.columbusSlClassic(),
      calendarEvents: List<RetroHistoricalRaceEvent>.unmodifiable(
        _defaultCalendarForYear(1976),
      ),
      completedEventIds: const [],
      seasonPrestigePoints: 0,
      historicalAuthenticityScore: 100.0,
      activeWetnessFactor: 0.0,
    );
  }

  /// Tworzy kompletny sezon historyczny dla dowolnego roku z przedziału 1970–2015.
  factory GoldenEraRetroSeasonModel.createForYear(
    int year, {
    String teamName = 'Retro Heritage Pro Team',
    String? seasonId,
  }) {
    final safeYear = year.clamp(1970, 2015);
    final ruleset = RetroSeasonRuleset.forYear(safeYear);
    final equipment = RetroEquipmentSetup.forYear(safeYear);
    return GoldenEraRetroSeasonModel(
      seasonId: seasonId ?? 'retro_${safeYear}_season',
      campaignTitle: 'Złota Era $safeYear · ${ruleset.era.displayNamePl}',
      seasonYear: safeYear,
      ruleset: ruleset,
      teamName: teamName,
      teamEquipment: equipment,
      calendarEvents: List<RetroHistoricalRaceEvent>.unmodifiable(
        _defaultCalendarForYear(safeYear),
      ),
      completedEventIds: const [],
      seasonPrestigePoints: 0,
      historicalAuthenticityScore: 100.0,
      activeWetnessFactor: 0.0,
    );
  }

  /// Zestaw gotowych kampanii z różnych dekad 1970–2015.
  static List<GoldenEraRetroSeasonModel> presets() {
    return [
      GoldenEraRetroSeasonModel.columbusSl1976Classic(),
      GoldenEraRetroSeasonModel.createForYear(
        1985,
        teamName: 'La Vie Claire Heritage',
        seasonId: 'retro_1985_badger',
      ),
      GoldenEraRetroSeasonModel.createForYear(
        1998,
        teamName: 'Mapei–QuickStep Retro',
        seasonId: 'retro_1998_sti',
      ),
      GoldenEraRetroSeasonModel.createForYear(
        2010,
        teamName: 'Saxo Bank Classic 2010',
        seasonId: 'retro_2010_carbon',
      ),
    ];
  }

  /// Czy sezon to w pełni analogowa epoka (brak miernika mocy i brak radia wyścigowego).
  bool get isPureAnalogEra => !ruleset.hasPowerMeter && !ruleset.hasRaceRadio;

  /// Postęp ukończenia kalendarza historycznego (0.0–1.0).
  double get calendarCompletionProgress {
    if (calendarEvents.isEmpty) return 0.0;
    final completedSet = completedEventIds.toSet();
    final matched =
        calendarEvents.where((e) => completedSet.contains(e.id)).length;
    return (matched / calendarEvents.length).clamp(0.0, 1.0);
  }

  /// Oblicza całkowitą masę kolarza i sprzętu z uwzględnieniem nasiąkniętej wełnianej koszulki [kg].
  double computeTotalWetWeightKg({
    required double riderWeightKg,
    required double rainIntensity01,
    double? wetnessProgress01,
  }) {
    return teamEquipment.calculateEffectiveSystemWeightKg(
      riderWeightKg: riderWeightKg,
      rainIntensity01: rainIntensity01,
      wetnessProgress01: wetnessProgress01 ?? activeWetnessFactor,
    );
  }

  /// Szacuje dodatkowy koszt energetyczny [W] wynikający z nasiąknięcia wełnianej koszulki deszczem
  /// (wzrost masy na podjeździe + pogorszenie aerodynamiki rozciągniętego materiału).
  double computeWoolJerseyPenaltyWatts({
    required double rainIntensity01,
    required double speedMs,
    required double gradientPercent,
    double? wetnessProgress01,
  }) {
    final wet = (wetnessProgress01 ?? activeWetnessFactor).clamp(0.0, 1.0);
    final addedWeightKg = teamEquipment.calculateWetJerseyAddedWeightKg(
      rainIntensity01: rainIntensity01,
      wetnessProgress01: wet,
    );
    final safeSpeed = speedMs.clamp(0.0, 30.0);
    final slopeRad = math.atan(gradientPercent.clamp(-25.0, 30.0) / 100.0);
    final gravityPenaltyWatts =
        math.max(0.0, addedWeightKg * 9.80665 * math.sin(slopeRad) * safeSpeed);

    final cdaPenalty =
        teamEquipment.jerseyMaterial.maxWetCdaPenalty * wet;
    final aeroPenaltyWatts =
        0.5 * 1.225 * cdaPenalty * math.pow(safeSpeed, 3);

    return gravityPenaltyWatts + aeroPenaltyWatts;
  }

  /// Zwraca nowy stan modelu z oznaczonym ukończonym wyścigiem historycznym.
  GoldenEraRetroSeasonModel markEventCompleted(
    String eventId, {
    int prestigeEarned = 150,
  }) {
    if (completedEventIds.contains(eventId)) return this;
    final nextCompleted = List<String>.unmodifiable([...completedEventIds, eventId]);
    return copyWith(
      completedEventIds: nextCompleted,
      seasonPrestigePoints: seasonPrestigePoints + math.max(0, prestigeEarned),
    );
  }

  GoldenEraRetroSeasonModel copyWith({
    String? seasonId,
    String? campaignTitle,
    int? seasonYear,
    RetroSeasonRuleset? ruleset,
    String? teamName,
    RetroEquipmentSetup? teamEquipment,
    List<RetroHistoricalRaceEvent>? calendarEvents,
    List<String>? completedEventIds,
    int? seasonPrestigePoints,
    double? historicalAuthenticityScore,
    double? activeWetnessFactor,
  }) {
    return GoldenEraRetroSeasonModel(
      seasonId: seasonId ?? this.seasonId,
      campaignTitle: campaignTitle ?? this.campaignTitle,
      seasonYear: seasonYear ?? this.seasonYear,
      ruleset: ruleset ?? this.ruleset,
      teamName: teamName ?? this.teamName,
      teamEquipment: teamEquipment ?? this.teamEquipment,
      calendarEvents: calendarEvents != null
          ? List<RetroHistoricalRaceEvent>.unmodifiable(calendarEvents)
          : this.calendarEvents,
      completedEventIds: completedEventIds != null
          ? List<String>.unmodifiable(completedEventIds)
          : this.completedEventIds,
      seasonPrestigePoints: seasonPrestigePoints ?? this.seasonPrestigePoints,
      historicalAuthenticityScore:
          historicalAuthenticityScore ?? this.historicalAuthenticityScore,
      activeWetnessFactor: activeWetnessFactor ?? this.activeWetnessFactor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seasonId': seasonId,
      'campaignTitle': campaignTitle,
      'seasonYear': seasonYear,
      'ruleset': ruleset.toJson(),
      'teamName': teamName,
      'teamEquipment': teamEquipment.toJson(),
      'calendarEvents': calendarEvents.map((e) => e.toJson()).toList(),
      'completedEventIds': completedEventIds,
      'seasonPrestigePoints': seasonPrestigePoints,
      'historicalAuthenticityScore': historicalAuthenticityScore,
      'activeWetnessFactor': activeWetnessFactor,
    };
  }

  factory GoldenEraRetroSeasonModel.fromJson(Map<String, dynamic> json) {
    final year = ((json['seasonYear'] as num?)?.toInt() ?? 1976).clamp(1970, 2015);
    final rawEvents = json['calendarEvents'] as List<dynamic>?;
    final parsedEvents = rawEvents != null
        ? rawEvents
            .whereType<Map<String, dynamic>>()
            .map(RetroHistoricalRaceEvent.fromJson)
            .toList()
        : _defaultCalendarForYear(year);
    final parsedCompleted = (json['completedEventIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    return GoldenEraRetroSeasonModel(
      seasonId: json['seasonId'] as String? ?? 'retro_${year}_season',
      campaignTitle: json['campaignTitle'] as String? ?? 'Złota Era $year',
      seasonYear: year,
      ruleset: json['ruleset'] is Map<String, dynamic>
          ? RetroSeasonRuleset.fromJson(json['ruleset'] as Map<String, dynamic>)
          : RetroSeasonRuleset.forYear(year),
      teamName: json['teamName'] as String? ?? 'Molteni–Columbus',
      teamEquipment: json['teamEquipment'] is Map<String, dynamic>
          ? RetroEquipmentSetup.fromJson(
              json['teamEquipment'] as Map<String, dynamic>,
            )
          : RetroEquipmentSetup.forYear(year),
      calendarEvents: List<RetroHistoricalRaceEvent>.unmodifiable(parsedEvents),
      completedEventIds: List<String>.unmodifiable(parsedCompleted),
      seasonPrestigePoints:
          (json['seasonPrestigePoints'] as num?)?.toInt() ?? 0,
      historicalAuthenticityScore:
          (json['historicalAuthenticityScore'] as num?)?.toDouble() ?? 100.0,
      activeWetnessFactor:
          (json['activeWetnessFactor'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static List<RetroHistoricalRaceEvent> _defaultCalendarForYear(int year) {
    return [
      RetroHistoricalRaceEvent(
        id: 'retro_${year}_roubaix',
        name: 'Paris–Roubaix $year',
        year: year,
        countryCode: 'FR',
        distanceKm: 270.5,
        elevationGainMeters: 1420,
        isMonument: true,
        isGrandTour: false,
        historicalWinner: year == 1976 ? 'Marc Demeyer' : 'Retro Champion',
        historicalWinningMarginSeconds: 0,
        rainProbability: 0.55,
        cobbleSectorsCount: 24,
        surfaceSummaryPl: 'Surowy bruk północny, głębokie błoto i szytki 25 mm',
        surfaceSummaryEn: 'Raw northern cobbles, deep mud and 25 mm tubulars',
      ),
      RetroHistoricalRaceEvent(
        id: 'retro_${year}_flanders',
        name: 'Ronde van Vlaanderen $year',
        year: year,
        countryCode: 'BE',
        distanceKm: 261.0,
        elevationGainMeters: 2350,
        isMonument: true,
        isGrandTour: false,
        historicalWinner: year == 1976 ? 'Walter Planckaert' : 'Flemish Lion',
        historicalWinningMarginSeconds: 0,
        rainProbability: 0.65,
        cobbleSectorsCount: 16,
        surfaceSummaryPl: 'Strome brukowane bergi i boczny wiatr Flandrii',
        surfaceSummaryEn: 'Steep cobbled bergs and Flemish crosswinds',
      ),
      RetroHistoricalRaceEvent(
        id: 'retro_${year}_tour_alpe',
        name: 'Tour de France $year · Alpe d\'Huez',
        year: year,
        countryCode: 'FR',
        distanceKm: 196.0,
        elevationGainMeters: 4450,
        isMonument: false,
        isGrandTour: true,
        historicalWinner: year == 1976 ? 'Joop Zoetemelk' : 'Alpine King',
        historicalWinningMarginSeconds: 18,
        rainProbability: 0.25,
        cobbleSectorsCount: 0,
        surfaceSummaryPl: '21 serpentyn Alpe d\'Huez na stalowej ramie',
        surfaceSummaryEn: '21 hairpins of Alpe d\'Huez on a steel frame',
      ),
      RetroHistoricalRaceEvent(
        id: 'retro_${year}_lombardia',
        name: 'Giro di Lombardia $year',
        year: year,
        countryCode: 'IT',
        distanceKm: 253.0,
        elevationGainMeters: 3780,
        isMonument: true,
        isGrandTour: false,
        historicalWinner: year == 1976 ? 'Roger De Vlaeminck' : 'Il Campionissimo',
        historicalWinningMarginSeconds: 4,
        rainProbability: 0.50,
        cobbleSectorsCount: 2,
        surfaceSummaryPl: 'Jesienne liście, deszcz nad Como i podjazd pod Ghisallo',
        surfaceSummaryEn: 'Autumn leaves, rain over Como and Madonna del Ghisallo',
      ),
    ];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GoldenEraRetroSeasonModel) return false;
    if (other.seasonId != seasonId ||
        other.campaignTitle != campaignTitle ||
        other.seasonYear != seasonYear ||
        other.ruleset != ruleset ||
        other.teamName != teamName ||
        other.teamEquipment != teamEquipment ||
        other.seasonPrestigePoints != seasonPrestigePoints ||
        other.historicalAuthenticityScore != historicalAuthenticityScore ||
        other.activeWetnessFactor != activeWetnessFactor ||
        other.calendarEvents.length != calendarEvents.length ||
        other.completedEventIds.length != completedEventIds.length) {
      return false;
    }
    for (int i = 0; i < calendarEvents.length; i++) {
      if (other.calendarEvents[i] != calendarEvents[i]) return false;
    }
    for (int i = 0; i < completedEventIds.length; i++) {
      if (other.completedEventIds[i] != completedEventIds[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        seasonId,
        campaignTitle,
        seasonYear,
        ruleset,
        teamName,
        teamEquipment,
        Object.hashAll(calendarEvents),
        Object.hashAll(completedEventIds),
        seasonPrestigePoints,
        historicalAuthenticityScore,
        activeWetnessFactor,
      );
}
