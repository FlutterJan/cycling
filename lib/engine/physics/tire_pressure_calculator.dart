// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import '../../models/equipment/complete_bike.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider_physiology.dart';

/// Typ systemu ogumienia koła (Tubeless vs dętki).
enum TireSystemType {
  /// System bezdętkowy z płynem uszczelniającym (Tubeless).
  /// Umożliwia najniższe bezpieczne ciśnienie, brak tarcia dętki o karkas,
  /// 0% ryzyka klasycznego przyszczypnięcia dętki (snakebite).
  tubeless,

  /// Dętka z termoplastycznego poliuretanu (TPU) – np. Tubolito, Schwalbe Aerothan.
  /// Bardzo lekka, niskie opory toczenia bliskie lateksowi,
  /// wyższa odporność na przebicie niż lateks, wymaga ok. +4% ciśnienia vs tubeless.
  tpuTube,

  /// Dętka lateksowa (Latex Tube) – tradycyjny wybór do jazdy na czas.
  /// Bardzo elastyczna, minimalne straty histerezy, ale podatna na przyszczypnięcie
  /// o krawędź obręczy (snakebite) przy uderzeniach w kanty; wymaga +5% ciśnienia.
  latexTube,

  /// Standardowa dętka butylowa (Butyl Tube).
  /// Wyższa sztywność ścianki dętki, najwyższe opory toczenia (+3-4W),
  /// duża podatność na snakebite przy niskim ciśnieniu; wymaga +8% ciśnienia.
  butylTube;

  /// Czytelna nazwa techniczna systemu ogumienia.
  String get displayName {
    switch (this) {
      case TireSystemType.tubeless:
        return 'Tubeless (System bezdętkowy z mleczkiem)';
      case TireSystemType.tpuTube:
        return 'Dętka TPU (Termoplastyczny Poliuretan)';
      case TireSystemType.latexTube:
        return 'Dętka Lateksowa (Latex)';
      case TireSystemType.butylTube:
        return 'Dętka Butylowa (Standard Butyl)';
    }
  }

  /// Mnożnik ciśnienia bazowego względem systemu tubeless.
  double get pressureMultiplier {
    switch (this) {
      case TireSystemType.tubeless:
        return 1.00;
      case TireSystemType.tpuTube:
        return 1.04;
      case TireSystemType.latexTube:
        return 1.05;
      case TireSystemType.butylTube:
        return 1.08;
    }
  }

  /// Współczynnik odporności na przyszczypnięcie dętki (snakebite pinch-flat).
  /// 1.0 = całkowity brak ryzyka dętki (tubeless), 0.2 = wysokie ryzyko (butyl).
  double get pinchFlatResistanceFactor {
    switch (this) {
      case TireSystemType.tubeless:
        return 1.00;
      case TireSystemType.tpuTube:
        return 0.65;
      case TireSystemType.latexTube:
        return 0.50;
      case TireSystemType.butylTube:
        return 0.25;
    }
  }

  /// Straty tarcia wewnętrznego dętki względem tubeless [Waty] przy 40 km/h.
  double get internalTubeLossWatts {
    switch (this) {
      case TireSystemType.tubeless:
        return 0.0;
      case TireSystemType.tpuTube:
        return 0.8;
      case TireSystemType.latexTube:
        return 0.5;
      case TireSystemType.butylTube:
        return 3.5;
    }
  }
}

/// Kategoria nawierzchni drogi pod kątem chropowatości i wibracji.
enum RoadSurfaceCategory {
  /// Gładki, nowy asfalt lub tor welodromowy (Smooth / Fresh Tarmac).
  /// Znikoma chropowatość, wysoki punkt przegięcia (breakpoint) ciśnienia.
  smoothAsphalt,

  /// Przeciętny asfalt drogowy (Average / Standard Road).
  /// Umiarkowana tekstura, typowa dla większości etapów szosowych.
  averageAsphalt,

  /// Chropowaty, zużyty asfalt lub nawierzchnia typu chip-seal (Rough Tarmac).
  /// Wyraźne mikrodrgania, obniżony punkt breakpointu ciśnienia.
  roughAsphalt,

  /// Mokry chropowaty asfalt w trakcie deszczu (Wet Tarmac).
  /// Wymaga redukcji ciśnienia o 4-8% dla powiększenia powierzchni styku i przyczepności.
  wetRoughAsphalt,

  /// Bruk (Cobblestones / Pavé) – suchy (np. Paryż-Roubaix, Flandria w słońcu).
  /// Duże uderzenia o krawędzie kamieni; zbyt wysokie ciśnienie wywołuje gigantyczne odbicia.
  cobblestones,

  /// Mokry, śliski bruk (Wet Cobblestones / Wet Pavé).
  /// Ekstremalne warunki; wymaga maksymalnego bezpiecznego obniżenia ciśnienia,
  /// by opona układała się na śliskich kamieniach i nie zrywała przyczepności.
  wetCobblestones,

  /// Szuter ubity / białe drogi toskańskie (Gravel / Strade Bianche).
  /// Luźne kamienie, tłumienie wibracji decyduje o prędkości i komforcie.
  gravel;

  /// Nazwa czytelna nawierzchni.
  String get displayName {
    switch (this) {
      case RoadSurfaceCategory.smoothAsphalt:
        return 'Gładki, nowy asfalt (Fresh Tarmac)';
      case RoadSurfaceCategory.averageAsphalt:
        return 'Przeciętny asfalt drogowy';
      case RoadSurfaceCategory.roughAsphalt:
        return 'Chropowaty asfalt / Chip-seal';
      case RoadSurfaceCategory.wetRoughAsphalt:
        return 'Mokry asfalt w deszczu';
      case RoadSurfaceCategory.cobblestones:
        return 'Bruk (Pavé) – suchy';
      case RoadSurfaceCategory.wetCobblestones:
        return 'Bruk (Pavé) – mokry i śliski';
      case RoadSurfaceCategory.gravel:
        return 'Szuter (Gravel / Strade Bianche)';
    }
  }

  /// Mnożnik optymalnego ciśnienia (punktu breakpointu) dla danej nawierzchni.
  /// Im gorsza nawierzchnia, tym niższe ciśnienie minimalizuje sumę histerezy i impedancji.
  double get breakpointPressureMultiplier {
    switch (this) {
      case RoadSurfaceCategory.smoothAsphalt:
        return 1.08;
      case RoadSurfaceCategory.averageAsphalt:
        return 1.00;
      case RoadSurfaceCategory.roughAsphalt:
        return 0.94;
      case RoadSurfaceCategory.wetRoughAsphalt:
        return 0.88;
      case RoadSurfaceCategory.cobblestones:
        return 0.79;
      case RoadSurfaceCategory.wetCobblestones:
        return 0.72;
      case RoadSurfaceCategory.gravel:
        return 0.82;
    }
  }

  /// Wrażliwość nawierzchni na straty impedancji (odbijania opony) [W/(BAR^2)].
  /// Na bruku przepompowana opona traci aż kilkanaście-kilkadziesiąt watów!
  double get impedanceSensitivityCoefficient {
    switch (this) {
      case RoadSurfaceCategory.smoothAsphalt:
        return 0.8;
      case RoadSurfaceCategory.averageAsphalt:
        return 2.2;
      case RoadSurfaceCategory.roughAsphalt:
        return 3.8;
      case RoadSurfaceCategory.wetRoughAsphalt:
        return 4.2;
      case RoadSurfaceCategory.cobblestones:
        return 10.5; // Potężne straty odbijania od kamieni
      case RoadSurfaceCategory.wetCobblestones:
        return 12.0; // Straty odbijania połączone z uślizgiem napędu
      case RoadSurfaceCategory.gravel:
        return 5.8;
    }
  }

  /// Czy nawierzchnia jest mokra/deszczowa.
  bool get isWet =>
      this == RoadSurfaceCategory.wetRoughAsphalt ||
      this == RoadSurfaceCategory.wetCobblestones;

  /// Czy nawierzchnia jest brukiem (Pavé).
  bool get isCobblestones =>
      this == RoadSurfaceCategory.cobblestones ||
      this == RoadSurfaceCategory.wetCobblestones;
}

/// Typ konstrukcji rantu obręczy koła.
enum RimType {
  /// Tradycyjne obręcze z rantem haczykowym (Hooked).
  /// Bezpieczne ciśnienie robocze do 8.0 - 8.5 BAR (116 - 123 PSI).
  hooked,

  /// Nowoczesne obręcze proste bez haczyka (Hookless / TSS).
  /// Zgodnie z normami ETRTO / ISO 5775 absolutny limit bezpieczeństwa to 5.0 BAR (72.5 PSI).
  hookless;

  /// Maksymalne dopuszczalne ciśnienie bezpieczne [BAR].
  double get maxSafePressureBar {
    switch (this) {
      case RimType.hooked:
        return 8.5;
      case RimType.hookless:
        return 5.0; // Ścisła norma ETRTO dla kół szosowych hookless
    }
  }

  /// Maksymalne dopuszczalne ciśnienie bezpieczne [PSI].
  double get maxSafePressurePsi => maxSafePressureBar * 14.50377;
}

/// Wynik kalkulacji optymalnego ciśnienia w oponach według metodologii Silca / SRAM.
class TirePressureRecommendation {
  /// Rekomendowane ciśnienie przedniego koła [BAR]
  final double frontPressureBar;

  /// Rekomendowane ciśnienie przedniego koła [PSI]
  final double frontPressurePsi;

  /// Rekomendowane ciśnienie tylnego koła [BAR]
  final double rearPressureBar;

  /// Rekomendowane ciśnienie tylnego koła [PSI]
  final double rearPressurePsi;

  /// Minimalne bezpieczne ciśnienie przedniego koła chroniące przed snakebite [BAR]
  final double minSafeFrontPressureBar;

  /// Minimalne bezpieczne ciśnienie tylnego koła chroniące przed snakebite [BAR]
  final double minSafeRearPressureBar;

  /// Maksymalne dopuszczalne ciśnienie przedniego koła (przed progiem skrajnej impedancji/limit obręczy) [BAR]
  final double maxSafeFrontPressureBar;

  /// Maksymalne dopuszczalne ciśnienie tylnego koła [BAR]
  final double maxSafeRearPressureBar;

  /// Całkowita masa układu (kolarz + rower + bidony/osprzęt) [kg]
  final double totalMassKg;

  /// Nominalna szerokość opony podana przez producenta [mm] (np. 25, 28, 30, 32)
  final int nominalTireWidthMm;

  /// Efektywna zmierzona szerokość opony po założeniu na obręcz o danej szerokości wewnętrznej [mm]
  final double effectiveTireWidthMm;

  /// Wewnętrzna szerokość obręczy [mm] (Internal Rim Width, np. 19mm, 21mm, 23mm, 25mm)
  final double internalRimWidthMm;

  /// Zastosowany system ogumienia (Tubeless, TPU, Latex, Butyl)
  final TireSystemType tireSystem;

  /// Kategoria nawierzchni drogi
  final RoadSurfaceCategory surface;

  /// Typ konstrukcji rantu obręczy (Hooked vs Hookless)
  final RimType rimType;

  /// Czy warunki są mokre (deszcz/mokra jezdnia)
  final bool isWet;

  /// Rozkład masy na przednie koło (np. 0.45 dla 45% przód / 55% tył)
  final double frontWeightRatio;

  /// Czy wyliczone optymalne ciśnienie przekracza limit 5.0 BAR (72.5 PSI) dla obręczy hookless
  final bool isHooklessExceededWarning;

  /// Podsumowanie taktyczne i zalecenia dla kolarza / mechanika
  final String adviceSummary;

  /// Szczegółowe uwagi inżynieryjne
  final List<String> technicalNotes;

  const TirePressureRecommendation({
    required this.frontPressureBar,
    required this.frontPressurePsi,
    required this.rearPressureBar,
    required this.rearPressurePsi,
    required this.minSafeFrontPressureBar,
    required this.minSafeRearPressureBar,
    required this.maxSafeFrontPressureBar,
    required this.maxSafeRearPressureBar,
    required this.totalMassKg,
    required this.nominalTireWidthMm,
    required this.effectiveTireWidthMm,
    required this.internalRimWidthMm,
    required this.tireSystem,
    required this.surface,
    required this.rimType,
    required this.isWet,
    required this.frontWeightRatio,
    required this.isHooklessExceededWarning,
    required this.adviceSummary,
    required this.technicalNotes,
  });

  Map<String, dynamic> toJson() => {
        'frontPressureBar': frontPressureBar,
        'frontPressurePsi': frontPressurePsi,
        'rearPressureBar': rearPressureBar,
        'rearPressurePsi': rearPressurePsi,
        'minSafeFrontPressureBar': minSafeFrontPressureBar,
        'minSafeRearPressureBar': minSafeRearPressureBar,
        'maxSafeFrontPressureBar': maxSafeFrontPressureBar,
        'maxSafeRearPressureBar': maxSafeRearPressureBar,
        'totalMassKg': totalMassKg,
        'nominalTireWidthMm': nominalTireWidthMm,
        'effectiveTireWidthMm': effectiveTireWidthMm,
        'internalRimWidthMm': internalRimWidthMm,
        'tireSystem': tireSystem.name,
        'surface': surface.name,
        'rimType': rimType.name,
        'isWet': isWet,
        'frontWeightRatio': frontWeightRatio,
        'isHooklessExceededWarning': isHooklessExceededWarning,
        'adviceSummary': adviceSummary,
        'technicalNotes': technicalNotes,
      };

  factory TirePressureRecommendation.fromJson(Map<String, dynamic> json) {
    return TirePressureRecommendation(
      frontPressureBar: (json['frontPressureBar'] as num).toDouble(),
      frontPressurePsi: (json['frontPressurePsi'] as num).toDouble(),
      rearPressureBar: (json['rearPressureBar'] as num).toDouble(),
      rearPressurePsi: (json['rearPressurePsi'] as num).toDouble(),
      minSafeFrontPressureBar:
          (json['minSafeFrontPressureBar'] as num).toDouble(),
      minSafeRearPressureBar:
          (json['minSafeRearPressureBar'] as num).toDouble(),
      maxSafeFrontPressureBar:
          (json['maxSafeFrontPressureBar'] as num).toDouble(),
      maxSafeRearPressureBar:
          (json['maxSafeRearPressureBar'] as num).toDouble(),
      totalMassKg: (json['totalMassKg'] as num).toDouble(),
      nominalTireWidthMm: (json['nominalTireWidthMm'] as num).toInt(),
      effectiveTireWidthMm: (json['effectiveTireWidthMm'] as num).toDouble(),
      internalRimWidthMm: (json['internalRimWidthMm'] as num).toDouble(),
      tireSystem: TireSystemType.values.firstWhere(
        (e) => e.name == json['tireSystem'],
        orElse: () => TireSystemType.tubeless,
      ),
      surface: RoadSurfaceCategory.values.firstWhere(
        (e) => e.name == json['surface'],
        orElse: () => RoadSurfaceCategory.averageAsphalt,
      ),
      rimType: RimType.values.firstWhere(
        (e) => e.name == json['rimType'],
        orElse: () => RimType.hooked,
      ),
      isWet: json['isWet'] as bool? ?? false,
      frontWeightRatio: (json['frontWeightRatio'] as num).toDouble(),
      isHooklessExceededWarning:
          json['isHooklessExceededWarning'] as bool? ?? false,
      adviceSummary: json['adviceSummary'] as String? ?? '',
      technicalNotes: (json['technicalNotes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  @override
  String toString() {
    return 'TirePressureRecommendation(Front: ${frontPressureBar.toStringAsFixed(2)} BAR / '
        '${frontPressurePsi.toStringAsFixed(1)} PSI, '
        'Rear: ${rearPressureBar.toStringAsFixed(2)} BAR / '
        '${rearPressurePsi.toStringAsFixed(1)} PSI, '
        'Width: ${effectiveTireWidthMm.toStringAsFixed(1)}mm, '
        'Surface: ${surface.name}, System: ${tireSystem.name})';
  }
}

/// Werdykt oceny ciśnienia zadanego przez kolarza lub mechanika.
enum PressureEvaluationVerdict {
  /// Idealne ciśnienie w optymalnym oknie pracy opony (niska histereza i zerowa impedancja).
  optimal,

  /// Ciśnienie minimalnie za wysokie (drobne straty komfortu, marginalny wzrost oporów).
  slightlyHigh,

  /// Ciśnienie skrajnie za wysokie (drastyczne odbijanie od nierówności, potężna strata watów).
  severeOverpressureImpedance,

  /// Ciśnienie minimalnie za niskie (delikatnie zwiększona histereza karkasu).
  slightlyLow,

  /// Skrajnie za niskie ciśnienie – groźba snakebite / dobicia obręczy lub zsunięcia opony.
  dangerouslyLowPinchFlatRisk,

  /// Niebezpieczeństwo rozerwania obręczy hookless (przekroczono limit 5.0 BAR).
  hooklessDanger;

  String get displayName {
    switch (this) {
      case PressureEvaluationVerdict.optimal:
        return 'Optymalne ciśnienie wyścigowe';
      case PressureEvaluationVerdict.slightlyHigh:
        return 'Ciśnienie nieco za wysokie';
      case PressureEvaluationVerdict.severeOverpressureImpedance:
        return 'Skrajne nadciśnienie – wysokie straty impedancji (+15-25W)';
      case PressureEvaluationVerdict.slightlyLow:
        return 'Ciśnienie nieco za niskie';
      case PressureEvaluationVerdict.dangerouslyLowPinchFlatRisk:
        return 'Krytyczne niedociśnienie – ryzyko snakebite / dobicia obręczy';
      case PressureEvaluationVerdict.hooklessDanger:
        return 'Naruszenie normy Hookless (>5.0 BAR / 72.5 PSI)';
    }
  }
}

/// Szczegółowa ocena fizyczna ciśnienia w kołach:
/// straty mocy (impedancja vs histereza), przyczepność w zakrętach i ryzyko snakebite.
class TirePressureEvaluation {
  /// Zmierzone/ustawione ciśnienie przednie [BAR]
  final double actualFrontBar;

  /// Zmierzone/ustawione ciśnienie przednie [PSI]
  final double actualFrontPsi;

  /// Zmierzone/ustawione ciśnienie tylne [BAR]
  final double actualRearBar;

  /// Zmierzone/ustawione ciśnienie tylne [PSI]
  final double actualRearPsi;

  /// Odchylenie ciśnienia przedniego od optimum [BAR] (>0 = za wysokie, <0 = za niskie)
  final double frontPressureDeltaBar;

  /// Odchylenie ciśnienia tylnego od optimum [BAR] (>0 = za wysokie, <0 = za niskie)
  final double rearPressureDeltaBar;

  /// Straty mocy wynikające z impedancji (odbijania opony i wibracji) [Waty] przy 40 km/h.
  /// Przy nadciśnieniu na bruku strata sięga od +15 do +25 Watów!
  final double impedanceLossWatts;

  /// Dodatkowe straty histerezy wynikające ze zbyt mocnego uginania niedopompowanej opony [Waty]
  final double hysteresisLossDeltaWatts;

  /// Łączna strata watów na kołach względem optymalnego ciśnienia [Waty]
  double get totalRollingPenaltyWatts =>
      impedanceLossWatts + hysteresisLossDeltaWatts;

  /// Wskaźnik przyczepności w zakrętach (0.0% do 100.0%, 100% = idealny kontakt gumy z asfaltem).
  /// Nadciśnienie powoduje odskakiwanie koła i drastyczny spadek przyczepności (zwłaszcza w deszczu).
  final double corneringGripPercent;

  /// Ryzyko przyszczypnięcia dętki (snakebite pinch-flat) [0.0% do 100.0%]
  final double pinchFlatRiskPercent;

  /// Ryzyko uszkodzenia obręczy od uderzenia w krawędź kamienia/dziury [0.0% do 100.0%]
  final double rimDamageRiskPercent;

  /// Czy przekroczono dopuszczalny limit 5.0 BAR na obręczach hookless
  final bool isHooklessExceededDanger;

  /// Końcowy werdykt diagnostyczny
  final PressureEvaluationVerdict verdict;

  /// Podsumowanie diagnostyczne w języku polskim
  final String diagnosticMessage;

  const TirePressureEvaluation({
    required this.actualFrontBar,
    required this.actualFrontPsi,
    required this.actualRearBar,
    required this.actualRearPsi,
    required this.frontPressureDeltaBar,
    required this.rearPressureDeltaBar,
    required this.impedanceLossWatts,
    required this.hysteresisLossDeltaWatts,
    required this.corneringGripPercent,
    required this.pinchFlatRiskPercent,
    required this.rimDamageRiskPercent,
    required this.isHooklessExceededDanger,
    required this.verdict,
    required this.diagnosticMessage,
  });

  @override
  String toString() {
    return 'TirePressureEvaluation(${verdict.displayName}: '
        '+${totalRollingPenaltyWatts.toStringAsFixed(1)}W strat '
        '[Impedancja: ${impedanceLossWatts.toStringAsFixed(1)}W, Histereza: ${hysteresisLossDeltaWatts.toStringAsFixed(1)}W], '
        'Przyczepność: ${corneringGripPercent.toStringAsFixed(1)}%, '
        'Snakebite: ${pinchFlatRiskPercent.toStringAsFixed(1)}%)';
  }
}

/// Fizyczny kalkulator ciśnienia w oponach kolarskich wzorowany na badaniach
/// Josha Poertnera (Silca) oraz SRAM AXS Tire Pressure Guide.
///
/// Wylicza punkt przegięcia (breakpoint pressure), w którym suma strat histerezy
/// gumy i karkasu oraz strat impedancji wibracyjnej (suspension losses) osiąga minimum.
class TirePressureCalculator {
  TirePressureCalculator._();

  /// Stała przeliczeniowa z BAR na PSI: 1 BAR = 14.50377 PSI.
  static const double barToPsiFactor = 14.50377;

  /// Bazowa referencyjna szerokość obręczy wewnętrznej [mm] wg normy ETRTO
  static const double standardInternalRimWidthMm = 19.0;

  /// Konwersja BAR na PSI
  static double barToPsi(double bar) => bar * barToPsiFactor;

  /// Konwersja PSI na BAR
  static double psiToBar(double psi) => psi / barToPsiFactor;

  /// Oblicza efektywną (zmierzoną suwmiarką) szerokość opony [mm]
  /// w oparciu o szerokość nominalną (np. 25, 28, 30, 32) i wewnętrzną szerokość obręczy.
  ///
  /// Reguła ETRTO: każdy 1 mm szerszej obręczy ponad standard 19mm poszerza balon opony o ~0.35-0.40 mm.
  static double calculateEffectiveTireWidth({
    required int nominalWidthMm,
    double internalRimWidthMm = 21.0,
  }) {
    final double rimDelta = internalRimWidthMm - standardInternalRimWidthMm;
    final double effective = nominalWidthMm + (rimDelta * 0.36);
    return effective.clamp(20.0, 50.0);
  }

  /// Wylicza rekomendowane ciśnienie w oponach (BAR i PSI) dla przedniego i tylnego koła.
  ///
  /// Parametry wejściowe:
  /// - [totalMassKg]: łączna masa (kolarz + rower + bidony i ekwipunek) w kg.
  /// - [tireWidthMm]: nominalna szerokość opony w mm (25, 28, 30, 32 mm itp.).
  /// - [tireSystem]: system ogumienia (Tubeless, dętka TPU, lateks, butyl).
  /// - [surface]: kategoria nawierzchni (asfalt gładki, chropowaty, suchy/mokry bruk, szuter).
  /// - [isWet]: flaga deszczu/mokrej nawierzchni (jeśli surface nie specyfikuje jej bezpośrednio).
  /// - [rimType]: rodzaj obręczy (Hooked vs Hookless).
  /// - [internalRimWidthMm]: wewnętrzna szerokość obręczy [mm] (domyślnie 21.0 mm).
  /// - [frontWeightRatio]: rozkład obciążenia na przednie koło (domyślnie 0.45, czyli 45% przód / 55% tył).
  static TirePressureRecommendation calculateOptimalPressure({
    required double totalMassKg,
    required int tireWidthMm,
    TireSystemType tireSystem = TireSystemType.tubeless,
    RoadSurfaceCategory surface = RoadSurfaceCategory.averageAsphalt,
    bool isWet = false,
    RimType rimType = RimType.hooked,
    double internalRimWidthMm = 21.0,
    double frontWeightRatio = 0.45,
  }) {
    // 1. Zabezpieczenie minimalnej i maksymalnej masy układu
    final double safeMassKg = totalMassKg.clamp(45.0, 130.0);
    final double clampedFrontRatio = frontWeightRatio.clamp(0.38, 0.52);
    final double rearWeightRatio = 1.0 - clampedFrontRatio;

    // 2. Efektywna szerokość opony na danej feldze
    final double effectiveWidth = calculateEffectiveTireWidth(
      nominalWidthMm: tireWidthMm,
      internalRimWidthMm: internalRimWidthMm,
    );

    // 3. Obliczenie obciążenia przypadającego na każde koło [kg]
    final double frontWheelLoadKg = safeMassKg * clampedFrontRatio;
    final double rearWheelLoadKg = safeMassKg * rearWeightRatio;

    // 4. Wyznaczenie bazowego ciśnienia wg formuły Berto-Poertnera (12-15% ugięcia karkasu)
    // Kalibracja referencyjna: dla obciążenia 40 kg na oponie 28mm na przeciętnym asfalcie
    // baza tubeless wynosi dokładnie 4.00 BAR (58 PSI).
    const double referenceLoadKg = 40.0;
    const double referenceWidthMm = 28.0;
    const double referencePressureBar = 4.00;

    // Potęgi ugięcia: obciążenie do potęgi 0.68 (zgodnie z prawem Berto dla ugięcia 15%),
    // szerokość opony do potęgi -1.35
    double rawFrontBar = referencePressureBar *
        math.pow(frontWheelLoadKg / referenceLoadKg, 0.68) *
        math.pow(referenceWidthMm / effectiveWidth, 1.35);

    double rawRearBar = referencePressureBar *
        math.pow(rearWheelLoadKg / referenceLoadKg, 0.68) *
        math.pow(referenceWidthMm / effectiveWidth, 1.35);

    // 5. Modyfikator nawierzchni (punkt breakpointu impedancji)
    // Na chropowatym asfalcie, szutrach i bruku ciśnienie musi być obniżone!
    RoadSurfaceCategory effectiveSurface = surface;
    if (isWet &&
        surface != RoadSurfaceCategory.wetRoughAsphalt &&
        surface != RoadSurfaceCategory.wetCobblestones) {
      if (surface == RoadSurfaceCategory.cobblestones) {
        effectiveSurface = RoadSurfaceCategory.wetCobblestones;
      } else {
        effectiveSurface = RoadSurfaceCategory.wetRoughAsphalt;
      }
    }

    final double surfaceMult = effectiveSurface.breakpointPressureMultiplier;
    rawFrontBar *= surfaceMult;
    rawRearBar *= surfaceMult;

    // 6. Modyfikator systemu ogumienia (Tubeless vs dętka TPU / Lateks / Butyl)
    final double systemMult = tireSystem.pressureMultiplier;
    rawFrontBar *= systemMult;
    rawRearBar *= systemMult;

    // 7. Bezpieczne limity minimalne (chroniące przed dobiciem dętki / rim-strike)
    // Szersza opona (30-32mm) i tubeless dopuszczają znacznie niższe ciśnienie.
    double minSafeFront;
    double minSafeRear;

    if (effectiveWidth >= 31.0) {
      minSafeFront = tireSystem == TireSystemType.tubeless ? 2.0 : 2.5;
      minSafeRear = tireSystem == TireSystemType.tubeless ? 2.3 : 2.8;
    } else if (effectiveWidth >= 27.5) {
      minSafeFront = tireSystem == TireSystemType.tubeless ? 2.4 : 3.0;
      minSafeRear = tireSystem == TireSystemType.tubeless ? 2.8 : 3.4;
    } else {
      // Wąskie opony 25mm i mniej
      minSafeFront = tireSystem == TireSystemType.tubeless ? 3.0 : 3.8;
      minSafeRear = tireSystem == TireSystemType.tubeless ? 3.5 : 4.3;
    }

    // Na brukach zwiększamy minimalny margines bezpieczeństwa dla dętek, by uniknąć snakebite!
    if (effectiveSurface.isCobblestones &&
        tireSystem != TireSystemType.tubeless) {
      minSafeFront += 0.3;
      minSafeRear += 0.3;
    }

    // 8. Bezpieczne limity maksymalne
    final double maxRimBar = rimType.maxSafePressureBar;
    final double maxSafeFront = math.min(maxRimBar, 8.0);
    final double maxSafeRear = math.min(maxRimBar, 8.5);

    // Zaokrąglenie do 2 miejsc po przecinku (krok 0.05 bar odpowiada manometrom cyfrowym)
    final double finalFrontBar =
        _roundToQuarterTenth(rawFrontBar.clamp(minSafeFront, maxSafeFront));
    final double finalRearBar =
        _roundToQuarterTenth(rawRearBar.clamp(minSafeRear, maxSafeRear));

    final double frontPsi = barToPsi(finalFrontBar);
    final double rearPsi = barToPsi(finalRearBar);

    // 9. Weryfikacja normy Hookless (zarówno surowego zapotrzebowania, jak i końcowego)
    final bool isHooklessExceeded = rimType == RimType.hookless &&
        (rawFrontBar > 5.0 || rawRearBar > 5.0 || finalFrontBar > 5.0 || finalRearBar > 5.0);

    // 10. Generowanie uwag i zaleceń inżynieryjnych
    final List<String> technicalNotes = [];
    String adviceSummary = '';

    if (effectiveSurface.isCobblestones) {
      if (effectiveWidth < 29.0) {
        technicalNotes.add(
          'OSTRZEŻENIE: Szerokość opony ${tireWidthMm}mm jest zbyt wąska na sektory bruku (Paris-Roubaix/Flandria). '
          'Zalecane minimum to opony 30-32mm, aby bezpiecznie obniżyć ciśnienie poniżej 3.5 BAR.',
        );
      }
      if (tireSystem != TireSystemType.tubeless) {
        technicalNotes.add(
          'UWAGA: Zastosowanie dętki na bruku drastycznie zwiększa ryzyko przyszczypnięcia (snakebite) przy uderzeniu w kant kamienia. '
          'W peletonie WorldTour na bruki stosuje się wyłącznie Tubeless z płynem uszczelniającym.',
        );
      }
      adviceSummary =
          'Ustawienie na bruk: obniżone ciśnienie (${finalFrontBar.toStringAsFixed(1)}F / ${finalRearBar.toStringAsFixed(1)}R BAR) '
          'zapobiega odbijaniu opony i oszczędza od 15W do 25W strat impedancyjnych!';
    } else if (effectiveSurface.isWet) {
      adviceSummary =
          'Ustawienie na deszcz: ciśnienie zredukowane o ~8% dla maksymalizacji powierzchni styku gumy i pewności prowadzenia w mokrych łukach.';
    } else {
      adviceSummary =
          'Optymalne ciśnienie szosowe Silca/SRAM: ${finalFrontBar.toStringAsFixed(2)} BAR (${frontPsi.toStringAsFixed(0)} PSI) przód, '
          '${finalRearBar.toStringAsFixed(2)} BAR (${rearPsi.toStringAsFixed(0)} PSI) tył.';
    }

    if (isHooklessExceeded) {
      technicalNotes.add(
        'KRYTYCZNE ZAGROŻENIE: Wyliczone ciśnienie przekracza limit 5.0 BAR (72.5 PSI) dla obręczy Hookless! '
        'Zwiększ szerokość opony (np. do 28mm lub 30mm) lub zmniejsz masę, by uniknąć zsunięcia opony z felgi.',
      );
    }

    return TirePressureRecommendation(
      frontPressureBar: finalFrontBar,
      frontPressurePsi: _roundToOneDecimal(frontPsi),
      rearPressureBar: finalRearBar,
      rearPressurePsi: _roundToOneDecimal(rearPsi),
      minSafeFrontPressureBar: _roundToOneDecimal(minSafeFront),
      minSafeRearPressureBar: _roundToOneDecimal(minSafeRear),
      maxSafeFrontPressureBar: _roundToOneDecimal(maxSafeFront),
      maxSafeRearPressureBar: _roundToOneDecimal(maxSafeRear),
      totalMassKg: safeMassKg,
      nominalTireWidthMm: tireWidthMm,
      effectiveTireWidthMm: _roundToOneDecimal(effectiveWidth),
      internalRimWidthMm: internalRimWidthMm,
      tireSystem: tireSystem,
      surface: effectiveSurface,
      rimType: rimType,
      isWet: isWet || effectiveSurface.isWet,
      frontWeightRatio: clampedFrontRatio,
      isHooklessExceededWarning: isHooklessExceeded,
      adviceSummary: adviceSummary,
      technicalNotes: technicalNotes,
    );
  }

  /// Wylicza ciśnienie na podstawie gotowego zestawu roweru ([CompleteBike])
  /// oraz parametrów fizjologicznych kolarza ([RiderPhysiology]).
  static TirePressureRecommendation calculateFromBikeAndRider({
    required CompleteBike bike,
    required RiderPhysiology physiology,
    SegmentSurfaceType surfaceType = SegmentSurfaceType.smoothAsphalt,
    bool isWet = false,
    RimType rimType = RimType.hooked,
    TireSystemType? overrideSystem,
    int? overrideTireWidthMm,
    double extraGearWeightKg = 1.0, // Bidony z izotonikiem, licznik, narzędziownik
  }) {
    final double totalMassKg =
        physiology.weightKg + bike.totalWeightKg + extraGearWeightKg;

    final int widthMm = overrideTireWidthMm ?? bike.tire.widthMm;

    final TireSystemType system = overrideSystem ??
        (bike.tire.isTubeless ? TireSystemType.tubeless : TireSystemType.tpuTube);

    final RoadSurfaceCategory roadSurface = _mapSegmentSurfaceToCategory(
      surfaceType: surfaceType,
      isWet: isWet,
    );

    return calculateOptimalPressure(
      totalMassKg: totalMassKg,
      tireWidthMm: widthMm,
      tireSystem: system,
      surface: roadSurface,
      isWet: isWet,
      rimType: rimType,
      internalRimWidthMm: 21.0,
      frontWeightRatio: 0.45,
    );
  }

  /// Szczegółowa ocena fizyczna ciśnienia zadanego przez kolarza/mechanika
  /// w odniesieniu do rekomendacji optymalnej.
  ///
  /// Analizuje:
  /// - Nadciśnienie na nierównościach i bruku: wywołuje gwałtowne straty odbijania (impedancji)
  ///   dochodzące do 15-25W oraz utratę przyczepności.
  /// - Niedociśnienie: wywołuje uginanie karkasu (straty histerezy), pływanie w zakrętach
  ///   oraz groźbę dobicia obręczy (snakebite pinch-flat w dętkach lub rim-strike w tubeless).
  static TirePressureEvaluation evaluatePressure({
    required double frontPressureBar,
    required double rearPressureBar,
    required TirePressureRecommendation recommendation,
    double speedKmh = 40.0,
  }) {
    final double frontDelta = frontPressureBar - recommendation.frontPressureBar;
    final double rearDelta = rearPressureBar - recommendation.rearPressureBar;

    final double speedFactor = math.pow(speedKmh / 40.0, 1.5).toDouble();
    final double surfaceSens =
        recommendation.surface.impedanceSensitivityCoefficient;

    // 1. Straty impedancji wibracyjnej (wyłącznie gdy ciśnienie jest wyższe niż optymalne breakpoint)
    double impedanceWatts = 0.0;
    if (frontDelta > 0.05) {
      // Straty na przednim kole
      impedanceWatts +=
          surfaceSens * 0.42 * math.pow(frontDelta, 1.75) * speedFactor;
    }
    if (rearDelta > 0.05) {
      // Straty na tylnym kole (bardziej obciążonym)
      impedanceWatts +=
          surfaceSens * 0.58 * math.pow(rearDelta, 1.75) * speedFactor;
    }

    // 2. Straty histerezy (gdy ciśnienie jest poniżej optymalnego – nadmierne uginanie gumy)
    double hysteresisDeltaWatts = 0.0;
    if (frontDelta < -0.05) {
      hysteresisDeltaWatts += 1.8 * math.pow(frontDelta.abs(), 1.35);
    }
    if (rearDelta < -0.05) {
      hysteresisDeltaWatts += 2.4 * math.pow(rearDelta.abs(), 1.35);
    }

    // 3. Wskaźnik przyczepności w zakrętach (Cornering Grip %)
    // Nadciśnienie powoduje odrywanie opony od chropowatej nawierzchni
    double grip = 100.0;
    if (frontDelta > 0.2) {
      final double overFactor = frontDelta * (recommendation.isWet ? 14.0 : 8.5);
      grip -= overFactor;
    } else if (frontDelta < -0.5) {
      // Za niskie ciśnienie: opona zaczyna "pływać" i składać się w zakręcie
      final double squirmFactor = (frontDelta.abs() - 0.5) * 12.0;
      grip -= squirmFactor;
    }
    grip = grip.clamp(15.0, 100.0);

    // 4. Ryzyko dobicia dętki (Snakebite Pinch-Flat)
    double pinchFlatRisk = 0.0;
    final double worstUnderDelta = math.min(
      frontPressureBar - recommendation.minSafeFrontPressureBar,
      rearPressureBar - recommendation.minSafeRearPressureBar,
    );

    if (worstUnderDelta < 0.0) {
      final double underBar = worstUnderDelta.abs();
      // Współczynnik podatności danego systemu na przyszczypnięcie
      final double vulnFactor =
          (1.0 - recommendation.tireSystem.pinchFlatResistanceFactor);

      // Bruk dramatycznie podnosi ryzyko dobicia o ostre krawędzie
      final double surfaceHazard =
          recommendation.surface.isCobblestones ? 2.5 : 1.2;

      pinchFlatRisk = (underBar * 55.0 * vulnFactor * surfaceHazard).clamp(0.0, 99.0);
    }

    // 5. Ryzyko uszkodzenia obręczy (Rim Strike)
    double rimDamageRisk = 0.0;
    if (worstUnderDelta < -0.3) {
      final double severeUnder = worstUnderDelta.abs() - 0.3;
      final double cobbleMult =
          recommendation.surface.isCobblestones ? 2.8 : 1.0;
      rimDamageRisk = (severeUnder * 45.0 * cobbleMult).clamp(0.0, 95.0);
    }

    // 6. Weryfikacja normy Hookless
    final bool isHooklessExceeded = recommendation.rimType == RimType.hookless &&
        (frontPressureBar > 5.0 || rearPressureBar > 5.0);

    // 7. Ustalenie werdyktu i komunikatu diagnostycznego
    PressureEvaluationVerdict verdict;
    String diagnosticMsg;

    if (isHooklessExceeded) {
      verdict = PressureEvaluationVerdict.hooklessDanger;
      diagnosticMsg =
          'NIEBEZPIECZEŃSTWO: Ciśnienie przekracza limit 5.0 BAR na obręczy Hookless! '
          'Ryzyko zerwania opony z felgi.';
    } else if (pinchFlatRisk > 40.0) {
      verdict = PressureEvaluationVerdict.dangerouslyLowPinchFlatRisk;
      diagnosticMsg =
          'Krytycznie niskie ciśnienie! Poważne ryzyko snakebite (dobicie dętki) '
          'oraz uszkodzenia karbonowej obręczy na nierównościach (${pinchFlatRisk.toStringAsFixed(0)}% ryzyka).';
    } else if (impedanceWatts >= 15.0) {
      verdict = PressureEvaluationVerdict.severeOverpressureImpedance;
      diagnosticMsg =
          'Ekstremalne nadciśnienie! Na tej nawierzchni opona odbija się od kamieni zamiast toczyć. '
          'Tracisz aż +${impedanceWatts.toStringAsFixed(1)}W czystej mocy w wibracjach, a przyczepność spadła o ${(100.0 - grip).toStringAsFixed(0)}%!';
    } else if (frontDelta > 0.4 || rearDelta > 0.4) {
      verdict = PressureEvaluationVerdict.slightlyHigh;
      diagnosticMsg =
          'Ciśnienie nieco za wysokie (+${impedanceWatts.toStringAsFixed(1)}W strat impedancyjnych). '
          'Obniżenie ciśnienia poprawi komfort i prędkość.';
    } else if (frontDelta < -0.3 || rearDelta < -0.3) {
      verdict = PressureEvaluationVerdict.slightlyLow;
      diagnosticMsg =
          'Ciśnienie nieco za niskie (+${hysteresisDeltaWatts.toStringAsFixed(1)}W strat histerezy karkasu). '
          'Dopompuj koła, aby zoptymalizować toczenie.';
    } else {
      verdict = PressureEvaluationVerdict.optimal;
      diagnosticMsg =
          'Ciśnienie idealne! Minimalne opory toczenia, pełna przyczepność w zakrętach i brak strat impedancyjnych.';
    }

    return TirePressureEvaluation(
      actualFrontBar: _roundToOneDecimal(frontPressureBar),
      actualFrontPsi: _roundToOneDecimal(barToPsi(frontPressureBar)),
      actualRearBar: _roundToOneDecimal(rearPressureBar),
      actualRearPsi: _roundToOneDecimal(barToPsi(rearPressureBar)),
      frontPressureDeltaBar: _roundToOneDecimal(frontDelta),
      rearPressureDeltaBar: _roundToOneDecimal(rearDelta),
      impedanceLossWatts: _roundToOneDecimal(impedanceWatts),
      hysteresisLossDeltaWatts: _roundToOneDecimal(hysteresisDeltaWatts),
      corneringGripPercent: _roundToOneDecimal(grip),
      pinchFlatRiskPercent: _roundToOneDecimal(pinchFlatRisk),
      rimDamageRiskPercent: _roundToOneDecimal(rimDamageRisk),
      isHooklessExceededDanger: isHooklessExceeded,
      verdict: verdict,
      diagnosticMessage: diagnosticMsg,
    );
  }

  /// Pomocnicza metoda mapująca typ nawierzchni segmentu wyścigu ([SegmentSurfaceType])
  /// na kategorię nawierzchni opony ([RoadSurfaceCategory]).
  static RoadSurfaceCategory _mapSegmentSurfaceToCategory({
    required SegmentSurfaceType surfaceType,
    required bool isWet,
  }) {
    switch (surfaceType) {
      case SegmentSurfaceType.smoothAsphalt:
        return isWet
            ? RoadSurfaceCategory.wetRoughAsphalt
            : RoadSurfaceCategory.smoothAsphalt;
      case SegmentSurfaceType.concrete:
        return isWet
            ? RoadSurfaceCategory.wetRoughAsphalt
            : RoadSurfaceCategory.averageAsphalt;
      case SegmentSurfaceType.roughAsphalt:
        return isWet
            ? RoadSurfaceCategory.wetRoughAsphalt
            : RoadSurfaceCategory.roughAsphalt;
      case SegmentSurfaceType.cobblestonesSector1:
      case SegmentSurfaceType.cobblestonesSector2:
      case SegmentSurfaceType.cobblestonesSector3:
      case SegmentSurfaceType.cobblestonesSector4:
      case SegmentSurfaceType.cobblestonesSector5:
        return isWet
            ? RoadSurfaceCategory.wetCobblestones
            : RoadSurfaceCategory.cobblestones;
      case SegmentSurfaceType.gravelStrade:
        return RoadSurfaceCategory.gravel;
    }
  }

  /// Zaokrągla wartość do 0.05 (np. 3.82 -> 3.80, 3.84 -> 3.85)
  static double _roundToQuarterTenth(double value) {
    return (value * 20.0).round() / 20.0;
  }

  /// Zaokrągla wartość do jednego miejsca po przecinku
  static double _roundToOneDecimal(double value) {
    return (value * 10.0).round() / 10.0;
  }
}
