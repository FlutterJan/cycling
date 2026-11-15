// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'rider.dart';
import 'rider_physiology.dart';
import 'rider_power_profile.dart';

/// Fenotyp metaboliczny kolarza wyznaczany na podstawie stosunku VO2max do VLaMax
/// oraz kinetyki produkcji i utleniania kwasu mlekowego (model Madera / INSCYD).
enum MetabolicPhenotype {
  /// Sprinter beztlenowy: bardzo wysoki VLaMax (> 0.70 mmol/l/s),
  /// potężna glikoliza beztlenowa, kosmiczny finisz, ale niższy próg LT2 względem VO2max.
  pureSprinter,

  /// Dynamiczny puncher: umiarkowanie wysoki VLaMax (0.50 - 0.70 mmol/l/s),
  /// znakomite przyspieszenie na krótkich wspinaczkach (1-3 min), wysokie W'.
  explosivePuncheur,

  /// Kolarz wszechstronny / Lider Grand Tour: zrównoważony VLaMax (0.35 - 0.50 mmol/l/s),
  /// świetny kompromis między mocą progową (LT2) na długich przełęczach a zachowaniem przyspieszenia.
  allRounder,

  /// Wytrzymały góral (diesel climber): niski VLaMax (0.28 - 0.35 mmol/l/s),
  /// bardzo wysokie LT2 względem VO2max (ponad 85%), oszczędność glikogenu, ale brak sprintu.
  dieselClimber,

  /// Ekstremalny diesel czasowy (pure time trialist): skrajnie niski VLaMax (< 0.28 mmol/l/s),
  /// minimalna produkcja mleczanu, wysokie utlenianie tłuszczów, jazda na progu przez 60 minut bez zakwaszenia.
  timeTrialistDiesel;

  String toJson() => name;

  static MetabolicPhenotype fromJson(String value) {
    return MetabolicPhenotype.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MetabolicPhenotype.allRounder,
    );
  }

  /// Czytelna polska nazwa profilu metabolicznego
  String get displayName {
    switch (this) {
      case MetabolicPhenotype.pureSprinter:
        return 'Sprinter Beztlenowy (Wysokie VLaMax)';
      case MetabolicPhenotype.explosivePuncheur:
        return 'Dynamiczny Puncher (Średnio-wysokie VLaMax)';
      case MetabolicPhenotype.allRounder:
        return 'Lider GC / All-Rounder (Zrównoważony Silnik)';
      case MetabolicPhenotype.dieselClimber:
        return 'Góral Wytrzymałościowy (Niskie VLaMax)';
      case MetabolicPhenotype.timeTrialistDiesel:
        return 'Czasowiec / Silnik Tlenowy (Bardzo niskie VLaMax)';
    }
  }

  /// Skrócony opis taktyczny
  String get description {
    switch (this) {
      case MetabolicPhenotype.pureSprinter:
        return 'Błyskawiczne tempo produkcji mleczanu pozwala na generowanie 1600-1900W w sprincie. Wymaga jednak dużej ilości węglowodanów i cierpi na długich podjazdach.';
      case MetabolicPhenotype.explosivePuncheur:
        return 'Bardzo wysoka moc beztlenowa na 1-3 minuty. Znakomity na krótkich, sztywnych murach flandryjskich i ardeńskich.';
      case MetabolicPhenotype.allRounder:
        return 'Złoty środek kolarstwa etapowego: wysoki próg tlenowy połączony ze zdolnością do decydującego zrywu na ostatnich kilometrach wspinaczki.';
      case MetabolicPhenotype.dieselClimber:
        return 'Tłumi produkcję mleczanu, co pozwala na równomierne, mordercze tempo na alpejskich przełęczach. Cierpi w nagłych zmianach rytmu.';
      case MetabolicPhenotype.timeTrialistDiesel:
        return 'Maksymalnie stłumiona glikoliza i wysokie spalanie tłuszczy pozwalają na jazdę na 88-90% VO2max przez 50 km jazdy na czas.';
    }
  }

  /// Główne atuty profilu
  String get strengths {
    switch (this) {
      case MetabolicPhenotype.pureSprinter:
        return 'Maksymalna moc szczytowa (1500-1900 W), zabójczy finisz z peletonu.';
      case MetabolicPhenotype.explosivePuncheur:
        return 'Potężne W\' (22-28 kJ), odporność na powtarzalne skoki na pagórkach.';
      case MetabolicPhenotype.allRounder:
        return 'Uniwersalność, regeneracja między etapami, wysokie W/kg w każdym terenie.';
      case MetabolicPhenotype.dieselClimber:
        return 'Ekstremalna wytrzymałość na podjazdach >30 min, wolne wypłukiwanie glikogenu.';
      case MetabolicPhenotype.timeTrialistDiesel:
        return 'Płaska krzywa spadku mocy na dystansie 40-60 km, wysoka sprawność mechaniczna.';
    }
  }

  /// Ograniczenia fizjologiczne
  String get limitations {
    switch (this) {
      case MetabolicPhenotype.pureSprinter:
        return 'Szybkie wypłukiwanie glikogenu przy tempie peletonu pod górę, wysokie ryzyko bonka.';
      case MetabolicPhenotype.explosivePuncheur:
        return 'Trudności z utrzymaniem tempa powyżej 40 minut na przełęczach powyżej 2000 m n.p.m.';
      case MetabolicPhenotype.allRounder:
        return 'W płaskim, czystym sprincie ustępuje kolarzom o skrajnie wysokim VLaMax.';
      case MetabolicPhenotype.dieselClimber:
        return 'Brak gwałtownej odpowiedzi na skok rywala na krótkiej ściance (brak zrywu).';
      case MetabolicPhenotype.timeTrialistDiesel:
        return 'Niemal całkowity brak finiszu z grupy, konieczność ucieczki solo.';
    }
  }
}

/// Pojedynczy punkt pomiarowy z krzywej mleczanowej i próby stopniowanej (Ramp Test).
class LactateSamplePoint {
  /// Obciążenie na ergometrze [W]
  final int powerWatts;

  /// Moc w odniesieniu do masy ciała [W/kg]
  final double wattsPerKg;

  /// Zmierzone stężenie kwasu mlekowego we krwi włośniczkowej [mmol/l]
  final double lactateMmolL;

  /// Zmierzone tętno [bpm]
  final int heartRateBpm;

  /// Pobór tlenu na danym stopniu [ml/kg/min]
  final double vo2MlKgMin;

  /// Współczynnik wymiany gazowej (Respiratory Exchange Ratio - VCO2 / VO2)
  final double respiratoryExchangeRatio;

  /// Szacowane tempo utleniania kwasów tłuszczowych [g/h]
  final double fatOxidationGramsPerHour;

  /// Szacowane tempo utleniania węglowodanów [g/h]
  final double carbOxidationGramsPerHour;

  const LactateSamplePoint({
    required this.powerWatts,
    required this.wattsPerKg,
    required this.lactateMmolL,
    required this.heartRateBpm,
    required this.vo2MlKgMin,
    required this.respiratoryExchangeRatio,
    required this.fatOxidationGramsPerHour,
    required this.carbOxidationGramsPerHour,
  });

  Map<String, dynamic> toJson() => {
        'powerWatts': powerWatts,
        'wattsPerKg': wattsPerKg,
        'lactateMmolL': lactateMmolL,
        'heartRateBpm': heartRateBpm,
        'vo2MlKgMin': vo2MlKgMin,
        'respiratoryExchangeRatio': respiratoryExchangeRatio,
        'fatOxidationGramsPerHour': fatOxidationGramsPerHour,
        'carbOxidationGramsPerHour': carbOxidationGramsPerHour,
      };

  factory LactateSamplePoint.fromJson(Map<String, dynamic> json) => LactateSamplePoint(
        powerWatts: (json['powerWatts'] as num).toInt(),
        wattsPerKg: (json['wattsPerKg'] as num).toDouble(),
        lactateMmolL: (json['lactateMmolL'] as num).toDouble(),
        heartRateBpm: (json['heartRateBpm'] as num).toInt(),
        vo2MlKgMin: (json['vo2MlKgMin'] as num).toDouble(),
        respiratoryExchangeRatio: (json['respiratoryExchangeRatio'] as num).toDouble(),
        fatOxidationGramsPerHour: (json['fatOxidationGramsPerHour'] as num).toDouble(),
        carbOxidationGramsPerHour: (json['carbOxidationGramsPerHour'] as num).toDouble(),
      );
}

/// Spalanie substratów energetycznych (tłuszcze vs węglowodany) dla danej intensywności.
class SubstrateCombustion {
  /// Tempo spalania tłuszczu w gramach na godzinę [g/h]
  final double fatOxidationRateGramsPerHour;

  /// Tempo spalania węglowodanów w gramach na godzinę [g/h]
  final double carbOxidationRateGramsPerHour;

  /// Energia pochodząca ze spalania tłuszczu [kcal/h] (9.3 kcal/g)
  final double fatEnergyKcalPerHour;

  /// Energia pochodząca ze spalania węglowodanów [kcal/h] (4.1 kcal/g)
  final double carbEnergyKcalPerHour;

  /// Całkowity wydatek metaboliczny [kcal/h]
  final double totalMetabolicKcalPerHour;

  /// Szacowany współczynnik wymiany oddechowej (RER)
  final double respiratoryExchangeRatioRer;

  /// Procentowy udział tłuszczu w pokryciu zapotrzebowania energetycznego (0 - 100%)
  final double fatCombustionPercent;

  /// Procentowy udział węglowodanów w pokryciu zapotrzebowania energetycznego (0 - 100%)
  final double carbCombustionPercent;

  const SubstrateCombustion({
    required this.fatOxidationRateGramsPerHour,
    required this.carbOxidationRateGramsPerHour,
    required this.fatEnergyKcalPerHour,
    required this.carbEnergyKcalPerHour,
    required this.totalMetabolicKcalPerHour,
    required this.respiratoryExchangeRatioRer,
    required this.fatCombustionPercent,
    required this.carbCombustionPercent,
  });

  Map<String, dynamic> toJson() => {
        'fatOxidationRateGramsPerHour': fatOxidationRateGramsPerHour,
        'carbOxidationRateGramsPerHour': carbOxidationRateGramsPerHour,
        'fatEnergyKcalPerHour': fatEnergyKcalPerHour,
        'carbEnergyKcalPerHour': carbEnergyKcalPerHour,
        'totalMetabolicKcalPerHour': totalMetabolicKcalPerHour,
        'respiratoryExchangeRatioRer': respiratoryExchangeRatioRer,
        'fatCombustionPercent': fatCombustionPercent,
        'carbCombustionPercent': carbCombustionPercent,
      };

  factory SubstrateCombustion.fromJson(Map<String, dynamic> json) => SubstrateCombustion(
        fatOxidationRateGramsPerHour: (json['fatOxidationRateGramsPerHour'] as num).toDouble(),
        carbOxidationRateGramsPerHour: (json['carbOxidationRateGramsPerHour'] as num).toDouble(),
        fatEnergyKcalPerHour: (json['fatEnergyKcalPerHour'] as num).toDouble(),
        carbEnergyKcalPerHour: (json['carbEnergyKcalPerHour'] as num).toDouble(),
        totalMetabolicKcalPerHour: (json['totalMetabolicKcalPerHour'] as num).toDouble(),
        respiratoryExchangeRatioRer: (json['respiratoryExchangeRatioRer'] as num).toDouble(),
        fatCombustionPercent: (json['fatCombustionPercent'] as num).toDouble(),
        carbCombustionPercent: (json['carbCombustionPercent'] as num).toDouble(),
      );
}

/// Spersonalizowana strefa fizjologiczna oparta na progach LT1 i LT2.
class LabTrainingZone {
  final int zoneIndex; // 1 - 7
  final String code; // np. Z1, Z2, Z3...
  final String name; // np. "Baza Tlenowa (LT1 / FatMax)"
  final int minWatts;
  final int maxWatts;
  final int minHeartRateBpm;
  final int maxHeartRateBpm;
  final double typicalLactateMmolL;
  final String physiologicalAdaptation;

  const LabTrainingZone({
    required this.zoneIndex,
    required this.code,
    required this.name,
    required this.minWatts,
    required this.maxWatts,
    required this.minHeartRateBpm,
    required this.maxHeartRateBpm,
    required this.typicalLactateMmolL,
    required this.physiologicalAdaptation,
  });

  Map<String, dynamic> toJson() => {
        'zoneIndex': zoneIndex,
        'code': code,
        'name': name,
        'minWatts': minWatts,
        'maxWatts': maxWatts,
        'minHeartRateBpm': minHeartRateBpm,
        'maxHeartRateBpm': maxHeartRateBpm,
        'typicalLactateMmolL': typicalLactateMmolL,
        'physiologicalAdaptation': physiologicalAdaptation,
      };

  factory LabTrainingZone.fromJson(Map<String, dynamic> json) => LabTrainingZone(
        zoneIndex: (json['zoneIndex'] as num).toInt(),
        code: json['code'] as String,
        name: json['name'] as String,
        minWatts: (json['minWatts'] as num).toInt(),
        maxWatts: (json['maxWatts'] as num).toInt(),
        minHeartRateBpm: (json['minHeartRateBpm'] as num).toInt(),
        maxHeartRateBpm: (json['maxHeartRateBpm'] as num).toInt(),
        typicalLactateMmolL: (json['typicalLactateMmolL'] as num).toDouble(),
        physiologicalAdaptation: json['physiologicalAdaptation'] as String,
      );
}

/// Pełny profil laboratoryjny i mleczanowy kolarza.
///
/// Integruje złoty standard diagnostyki wydolnościowej w kolarstwie szosowym:
/// 1. Próg tlenowy $LT_1$ (Aerobic Threshold):
///    - Moc w Watach i W/kg
///    - Stężenie mleczanu we krwi (np. 1.8 mmol/l)
///    - Punkt szczytowego utleniania tłuszczu (FatMax)
/// 2. Próg beztlenowy $LT_2$ / MLSS (Maximal Lactate Steady State):
///    - Moc w Watach i W/kg (funkcjonalny odpowiednik laboratoryjnego FTP)
///    - Stężenie mleczanu we krwi (np. 4.0 mmol/l lub indywidualne stężenie równowagi)
/// 3. $VLaMax$ (Maksymalne tempo produkcji mleczanu w mmol/l/s):
///    - Kluczowe rozróżnienie sprintera (>0.75) od czasowca/górala (<0.32)
/// 4. Maksymalny pobór tlenu $VO_2max$:
///    - Względny [ml/kg/min] oraz bezwzględny [l/min]
///    - Moc maksymalna na pułapie tlenowym (MAP - Maximal Aerobic Power)
/// 5. Ekonomia jazdy (Gross Efficiency %):
///    - Sprawność mechaniczna kolarza (stosunek pracy mechanicznej na korbie do energii metabolicznej)
class LactateAndLabProfile {
  // --- 1. PRÓG TLENOWY (LT1 / AEROBIC THRESHOLD) ---
  /// Moc na progu tlenowym [W] (typ. 65% - 80% LT2)
  final int lt1Watts;

  /// Stężenie kwasu mlekowego we krwi w punkcie LT1 [mmol/l] (zazwyczaj 1.5 - 2.2 mmol/l, standard 1.8 mmol/l)
  final double lt1LactateMmolL;

  /// Tętno na progu tlenowym [bpm]
  final int lt1HeartRateBpm;

  /// Moc w punkcie maksymalnego utleniania tłuszczów (FatMax) [W]
  final int fatMaxWatts;

  /// Maksymalne tempo spalania tłuszczu w punkcie FatMax [g/h] (typ. 40 - 85 g/h)
  final double fatMaxOxidationRateGramsPerHour;

  // --- 2. PRÓG BEZTLENOWY (LT2 / MLSS - MAXIMAL LACTATE STEADY STATE) ---
  /// Moc na progu beztlenowym / MLSS [W] (odpowiada mocy 40-60 min / FTP)
  final int lt2Watts;

  /// Stężenie kwasu mlekowego we krwi w punkcie MLSS / LT2 [mmol/l] (zazwyczaj 3.5 - 4.5 mmol/l, standard 4.0 mmol/l)
  final double lt2LactateMmolL;

  /// Tętno na progu mleczanowym / LTHR [bpm]
  final int lt2HeartRateBpm;

  // --- 3. VLAMAX (MAXIMAL GLYCOLYTIC RATE) ---
  /// Maksymalna szybkość produkcji kwasu mlekowego w glikolizie beztlenowej [mmol · l⁻¹ · s⁻¹]
  /// Kluczowe rozróżnienie fizjologiczne:
  /// - Sprinter: 0.70 - 0.95 mmol/l/s
  /// - Puncheur: 0.50 - 0.70 mmol/l/s
  /// - Lider GC / All-Rounder: 0.32 - 0.50 mmol/l/s
  /// - Czasowiec / Diesel: 0.20 - 0.32 mmol/l/s
  final double vlaMaxMmolLPerSec;

  // --- 4. VO2MAX (MAXIMAL OXYGEN UPTAKE) ---
  /// Maksymalny względny pobór tlenu [ml/kg/min] (elita szosowa: 72 - 90 ml/kg/min)
  final double vo2MaxMlKgMin;

  /// Moc na pułapie tlenowym (Maximal Aerobic Power - MAP) [W]
  final int powerAtVo2MaxWatts;

  // --- 5. EKONOMIA JAZDY (GROSS EFFICIENCY) ---
  /// Sprawność mechaniczna brutto (Gross Efficiency) [%]
  /// Procent energii metabolicznej zamieniany w pracę mechaniczną na pedałach (typ. 20.0% - 24.5%)
  final double grossEfficiencyPercent;

  /// Sprawność krańcowa (Delta Efficiency) [%] (typ. 23.5% - 26.0%)
  final double deltaEfficiencyPercent;

  // --- PARAMETR REFERENCYJNY ---
  /// Referencyjna masa ciała kolarza podczas badania laboratoryjnego [kg]
  final double referenceWeightKg;

  const LactateAndLabProfile({
    required this.lt1Watts,
    this.lt1LactateMmolL = 1.8,
    required this.lt1HeartRateBpm,
    required this.fatMaxWatts,
    required this.fatMaxOxidationRateGramsPerHour,
    required this.lt2Watts,
    this.lt2LactateMmolL = 4.0,
    required this.lt2HeartRateBpm,
    required this.vlaMaxMmolLPerSec,
    required this.vo2MaxMlKgMin,
    required this.powerAtVo2MaxWatts,
    required this.grossEfficiencyPercent,
    this.deltaEfficiencyPercent = 24.8,
    required this.referenceWeightKg,
  });

  // =========================================================================
  // PARAMETRY WYLICZANE I INTERPRETACJE
  // =========================================================================

  /// Moc na progu tlenowym w przeliczeniu na masę ciała [W/kg]
  double get lt1WattsPerKg =>
      referenceWeightKg > 0 ? lt1Watts / referenceWeightKg : 0.0;

  /// Moc na progu beztlenowym MLSS w przeliczeniu na masę ciała [W/kg]
  double get lt2WattsPerKg =>
      referenceWeightKg > 0 ? lt2Watts / referenceWeightKg : 0.0;

  /// Moc na pułapie tlenowym MAP w przeliczeniu na masę ciała [W/kg]
  double get powerAtVo2MaxWattsPerKg =>
      referenceWeightKg > 0 ? powerAtVo2MaxWatts / referenceWeightKg : 0.0;

  /// Bezwzględny pobór tlenu w litrach na minutę [l/min]
  double get vo2MaxAbsoluteLitersMin =>
      referenceWeightKg > 0 ? (vo2MaxMlKgMin * referenceWeightKg) / 1000.0 : 0.0;

  /// Wykorzystanie frakcyjne pułapu tlenowego na progu LT2 (Fractional Utilization: LT2 / MAP)
  /// Wartości rzędu 0.75 - 0.90 (75% - 90%)
  double get fractionalUtilization => powerAtVo2MaxWatts > 0
      ? (lt2Watts / powerAtVo2MaxWatts).clamp(0.60, 0.95)
      : 0.82;

  /// Stosunek progu tlenowego LT1 do progu beztlenowego LT2 w procentach [%]
  double get lt1PercentOfLt2 =>
      lt2Watts > 0 ? ((lt1Watts / lt2Watts) * 100.0).clamp(50.0, 95.0) : 72.0;

  /// Ilość kilokalorii wydatkowanych metabolicznie na wyprodukowanie 1 kilodżula (kJ) pracy mechanicznej.
  /// Standard fizyczny: 1 kJ = 0.2390057 kcal. Przy 22.5% sprawności: ~1.062 kcal / kJ.
  double get metabolicKcalPerKjWork {
    final eff = grossEfficiencyPercent.clamp(18.0, 26.0) / 100.0;
    return 0.2390057 / eff;
  }

  /// Fenotyp metaboliczny kolarza na podstawie VLaMax
  MetabolicPhenotype get metabolicPhenotype {
    if (vlaMaxMmolLPerSec >= 0.70) return MetabolicPhenotype.pureSprinter;
    if (vlaMaxMmolLPerSec >= 0.50) return MetabolicPhenotype.explosivePuncheur;
    if (vlaMaxMmolLPerSec >= 0.35) return MetabolicPhenotype.allRounder;
    if (vlaMaxMmolLPerSec >= 0.28) return MetabolicPhenotype.dieselClimber;
    return MetabolicPhenotype.timeTrialistDiesel;
  }

  /// Czy kolarz ma dominujący fenotyp sprintersko-beztlenowy
  bool get isSprinterPhenotype => vlaMaxMmolLPerSec >= 0.65;

  /// Czy kolarz ma dominujący fenotyp diesla tlenowego / czasowca
  bool get isDieselPhenotype => vlaMaxMmolLPerSec <= 0.32;

  // =========================================================================
  // FORMATOWANIE I PODSUMOWANIA TEKSTOWE
  // =========================================================================

  String get lt1Summary =>
      '${lt1Watts}W (${lt1WattsPerKg.toStringAsFixed(2)} W/kg) @ ${lt1LactateMmolL.toStringAsFixed(1)} mmol/l';

  String get lt2Summary =>
      '${lt2Watts}W (${lt2WattsPerKg.toStringAsFixed(2)} W/kg) @ ${lt2LactateMmolL.toStringAsFixed(1)} mmol/l (MLSS)';

  String get vlaMaxSummary =>
      '${vlaMaxMmolLPerSec.toStringAsFixed(2)} mmol/l/s (${metabolicPhenotype.displayName})';

  String get vo2MaxSummary =>
      '${vo2MaxMlKgMin.toStringAsFixed(1)} ml/kg/min (${vo2MaxAbsoluteLitersMin.toStringAsFixed(2)} L/min, MAP: ${powerAtVo2MaxWatts}W)';

  String get grossEfficiencySummary =>
      '${grossEfficiencyPercent.toStringAsFixed(1)}% (Delta: ${deltaEfficiencyPercent.toStringAsFixed(1)}%)';

  // =========================================================================
  // MODELOWANIE KINETYKI MLECZANU I SPALANIA SUBSTRATÓW
  // =========================================================================

  /// Szacuje stężenie kwasu mlekowego we krwi [mmol/l] przy zadanej mocy ciągłej [powerWatts].
  ///
  /// Wykorzystuje model sigmoidalno-wykładniczy oparty na fizjologii Madera i Heck:
  /// - Poniżej LT1: stałe tło spoczynkowe ~1.0 - 1.8 mmol/l.
  /// - Pomiędzy LT1 a LT2: łagodny wzrost od lt1Lactate do lt2Lactate (kontrolowane utlenianie).
  /// - Powyżej LT2 (MLSS): gwałtowny, wykładniczy przyrost napędzany parametrem VLaMax.
  double estimateLactateAtPower(double powerWatts) {
    if (powerWatts <= 0) return 0.9;

    // Faza 1: Poniżej progu tlenowego LT1
    if (powerWatts <= lt1Watts) {
      final double fraction = (powerWatts / math.max(50.0, lt1Watts.toDouble())).clamp(0.0, 1.0);
      return 0.9 + (lt1LactateMmolL - 0.9) * math.pow(fraction, 1.4);
    }

    // Faza 2: Pomiędzy progiem tlenowym LT1 a beztlenowym LT2
    if (powerWatts <= lt2Watts) {
      final double fraction = ((powerWatts - lt1Watts) /
              math.max(10.0, (lt2Watts - lt1Watts).toDouble()))
          .clamp(0.0, 1.0);
      return lt1LactateMmolL + (lt2LactateMmolL - lt1LactateMmolL) * math.pow(fraction, 1.3);
    }

    // Faza 3: Powyżej MLSS (LT2) – eksponencjalne zakwaszenie mięśni
    final double overWatts = powerWatts - lt2Watts;
    final double mapSpan = math.max(40.0, (powerAtVo2MaxWatts - lt2Watts).toDouble());
    final double intensityOver = overWatts / mapSpan;

    // Mnożnik VLaMax: kolarz z VLaMax 0.85 zakwasza się 2.5x szybciej niż z VLaMax 0.28!
    final double vlaMaxFactor = (vlaMaxMmolLPerSec / 0.35).clamp(0.6, 2.8);
    final double exponentialRise = math.pow(intensityOver, 1.65) * 4.2 * vlaMaxFactor;

    return (lt2LactateMmolL + exponentialRise).clamp(lt2LactateMmolL, 22.0);
  }

  /// Oblicza tempo utleniania substratów (tłuszcze i węglowodany) dla zadanej mocy [powerWatts].
  SubstrateCombustion estimateSubstrateOxidation(double powerWatts) {
    if (powerWatts <= 10.0) {
      return const SubstrateCombustion(
        fatOxidationRateGramsPerHour: 12.0,
        carbOxidationRateGramsPerHour: 15.0,
        fatEnergyKcalPerHour: 111.6,
        carbEnergyKcalPerHour: 61.5,
        totalMetabolicKcalPerHour: 173.1,
        respiratoryExchangeRatioRer: 0.78,
        fatCombustionPercent: 64.5,
        carbCombustionPercent: 35.5,
      );
    }

    // Całkowity wydatek energii metabolicznej w kcal/h
    final double workKjPerHour = (powerWatts * 3600.0) / 1000.0;
    final double totalMetabolicKcal = workKjPerHour * metabolicKcalPerKjWork;

    // Obliczanie krzywej FatMax:
    // Tłuszcze osiągają szczyt w okolicach fatMaxWatts (~LT1), po czym spadają gwałtownie do zera przy LT2/MAP
    final double safeFatMaxWatts = fatMaxWatts > 0 ? fatMaxWatts.toDouble() : lt1Watts * 0.95;
    double fatGramsPerHour;

    if (powerWatts <= safeFatMaxWatts) {
      final double ratio = powerWatts / safeFatMaxWatts;
      fatGramsPerHour = 15.0 + (fatMaxOxidationRateGramsPerHour - 15.0) * math.sqrt(ratio);
    } else {
      // Spadek powyżej FatMax aż do zera w okolicach 105% LT2
      final double excessRatio = (powerWatts - safeFatMaxWatts) /
          math.max(20.0, (lt2Watts * 1.08) - safeFatMaxWatts);
      final double decay = math.exp(-2.2 * math.pow(excessRatio.clamp(0.0, 3.0), 1.8));
      fatGramsPerHour = fatMaxOxidationRateGramsPerHour * decay;
    }
    fatGramsPerHour = fatGramsPerHour.clamp(0.0, fatMaxOxidationRateGramsPerHour * 1.1);

    final double fatKcalPerHour = fatGramsPerHour * 9.3;

    // Reszta zapotrzebowania energetycznego pokrywana jest przez węglowodany
    final double remainingKcal = math.max(0.0, totalMetabolicKcal - fatKcalPerHour);
    final double carbGramsPerHour = remainingKcal / 4.1;
    final double carbKcalPerHour = carbGramsPerHour * 4.1;

    final double fatPercent = totalMetabolicKcal > 0
        ? (fatKcalPerHour / totalMetabolicKcal * 100.0).clamp(0.0, 100.0)
        : 50.0;
    final double carbPercent = 100.0 - fatPercent;

    // RER rośnie od ~0.75 (czyste tłuszcze) do 1.00 (czyste węglowodany przy LT2) i >1.00 powyżej LT2
    final double rer = (0.70 + 0.30 * (carbPercent / 100.0) +
            (powerWatts > lt2Watts ? (powerWatts - lt2Watts) / 300.0 : 0.0))
        .clamp(0.72, 1.25);

    return SubstrateCombustion(
      fatOxidationRateGramsPerHour: double.parse(fatGramsPerHour.toStringAsFixed(1)),
      carbOxidationRateGramsPerHour: double.parse(carbGramsPerHour.toStringAsFixed(1)),
      fatEnergyKcalPerHour: double.parse(fatKcalPerHour.toStringAsFixed(1)),
      carbEnergyKcalPerHour: double.parse(carbKcalPerHour.toStringAsFixed(1)),
      totalMetabolicKcalPerHour: double.parse(totalMetabolicKcal.toStringAsFixed(1)),
      respiratoryExchangeRatioRer: double.parse(rer.toStringAsFixed(2)),
      fatCombustionPercent: double.parse(fatPercent.toStringAsFixed(1)),
      carbCombustionPercent: double.parse(carbPercent.toStringAsFixed(1)),
    );
  }

  /// Zwraca tempo spalania węglowodanów w gramach na sekundę [g/s]
  /// przydatne do bezpośredniej integracji z silnikiem NutritionAndGlycogenEngine.
  double estimateCarbBurnRateGramsPerSecond(double powerWatts) {
    final combustion = estimateSubstrateOxidation(powerWatts);
    return combustion.carbOxidationRateGramsPerHour / 3600.0;
  }

  /// Szacuje tętno [bpm] przy danej mocy w oparciu o progi LT1 i LT2
  int estimateHeartRateAtPower(double powerWatts, {int restingHr = 42, int maxHr = 190}) {
    if (powerWatts <= 0) return restingHr;

    if (powerWatts <= lt1Watts) {
      final double fraction = powerWatts / math.max(1.0, lt1Watts.toDouble());
      return (restingHr + (lt1HeartRateBpm - restingHr) * fraction).round().clamp(restingHr, lt1HeartRateBpm);
    }

    if (powerWatts <= lt2Watts) {
      final double fraction = (powerWatts - lt1Watts) /
          math.max(1.0, (lt2Watts - lt1Watts).toDouble());
      return (lt1HeartRateBpm + (lt2HeartRateBpm - lt1HeartRateBpm) * fraction)
          .round()
          .clamp(lt1HeartRateBpm, lt2HeartRateBpm);
    }

    // Powyżej LT2 tętno zbliża się asympotycznie do MaxHR
    final double fraction = (powerWatts - lt2Watts) /
        math.max(10.0, (powerAtVo2MaxWatts - lt2Watts).toDouble());
    return (lt2HeartRateBpm + (maxHr - lt2HeartRateBpm) * math.min(1.0, fraction))
        .round()
        .clamp(lt2HeartRateBpm, maxHr);
  }

  /// Generuje kompletną symulowaną serię pomiarów testu stopniowanego (Ramp Test)
  /// np. do wizualizacji krzywej mleczanowej na wykresach w UI.
  List<LactateSamplePoint> generateLactateCurveSteps({
    int startWatts = 100,
    int stepWatts = 40,
    int? endWatts,
  }) {
    final maxPower = endWatts ?? (powerAtVo2MaxWatts + 60);
    final List<LactateSamplePoint> points = [];

    for (int p = startWatts; p <= maxPower; p += stepWatts) {
      final double wKg = referenceWeightKg > 0 ? p / referenceWeightKg : 0.0;
      final double lactate = estimateLactateAtPower(p.toDouble());
      final int hr = estimateHeartRateAtPower(p.toDouble());
      final combustion = estimateSubstrateOxidation(p.toDouble());

      // Estymacja VO2 na danym stopniu
      final double vo2Fraction = (p / math.max(1.0, powerAtVo2MaxWatts.toDouble())).clamp(0.2, 1.15);
      final double vo2 = (vo2MaxMlKgMin * vo2Fraction).clamp(12.0, vo2MaxMlKgMin * 1.08);

      points.add(
        LactateSamplePoint(
          powerWatts: p,
          wattsPerKg: double.parse(wKg.toStringAsFixed(2)),
          lactateMmolL: double.parse(lactate.toStringAsFixed(2)),
          heartRateBpm: hr,
          vo2MlKgMin: double.parse(vo2.toStringAsFixed(1)),
          respiratoryExchangeRatio: combustion.respiratoryExchangeRatioRer,
          fatOxidationGramsPerHour: combustion.fatOxidationRateGramsPerHour,
          carbOxidationGramsPerHour: combustion.carbOxidationRateGramsPerHour,
        ),
      );
    }

    return points;
  }

  /// Wyznacza spersonalizowane strefy treningowe kolarza w oparciu o progi laboratoryjne LT1 i LT2.
  List<LabTrainingZone> getTrainingZones() {
    final int z1Max = (lt1Watts * 0.75).round();
    final int z2Max = lt1Watts;
    final int z4Min = (lt2Watts * 0.94).round();
    final int z3Max = z4Min - 1;
    final int z4Max = (lt2Watts * 1.05).round();
    final int z5Max = powerAtVo2MaxWatts;
    final int z6Max = (powerAtVo2MaxWatts * 1.25).round();

    return [
      LabTrainingZone(
        zoneIndex: 1,
        code: 'Z1',
        name: 'Regeneracja Aktywna',
        minWatts: 0,
        maxWatts: z1Max,
        minHeartRateBpm: 0,
        maxHeartRateBpm: (lt1HeartRateBpm * 0.78).round(),
        typicalLactateMmolL: 1.1,
        physiologicalAdaptation: 'Regeneracja mięśniowa, przepłukanie metabolitów, lekki wydatek tlenowy.',
      ),
      LabTrainingZone(
        zoneIndex: 2,
        code: 'Z2',
        name: 'Baza Tlenowa / LT1 (FatMax)',
        minWatts: z1Max + 1,
        maxWatts: z2Max,
        minHeartRateBpm: (lt1HeartRateBpm * 0.78).round() + 1,
        maxHeartRateBpm: lt1HeartRateBpm,
        typicalLactateMmolL: lt1LactateMmolL,
        physiologicalAdaptation: 'Maksymalne utlenianie tłuszczów, rozwój mitochondriów i naczyń włosowatych.',
      ),
      LabTrainingZone(
        zoneIndex: 3,
        code: 'Z3',
        name: 'Tempo / SweetSpot',
        minWatts: z2Max + 1,
        maxWatts: z3Max,
        minHeartRateBpm: lt1HeartRateBpm + 1,
        maxHeartRateBpm: (lt2HeartRateBpm * 0.95).round(),
        typicalLactateMmolL: (lt1LactateMmolL + lt2LactateMmolL) / 2.0,
        physiologicalAdaptation: 'Budowa pojemności glikogenowej, tolerancja średniego stężenia mleczanu.',
      ),
      LabTrainingZone(
        zoneIndex: 4,
        code: 'Z4',
        name: 'Próg Mleczanowy / LT2 (MLSS)',
        minWatts: z4Min,
        maxWatts: z4Max,
        minHeartRateBpm: (lt2HeartRateBpm * 0.95).round() + 1,
        maxHeartRateBpm: (lt2HeartRateBpm * 1.03).round(),
        typicalLactateMmolL: lt2LactateMmolL,
        physiologicalAdaptation: 'Równowaga wytwarzania i usuwania mleczanu, maksymalizacja mocy progowej (FTP).',
      ),
      LabTrainingZone(
        zoneIndex: 5,
        code: 'Z5',
        name: 'Pułap Tlenowy (VO2max / MAP)',
        minWatts: z4Max + 1,
        maxWatts: z5Max,
        minHeartRateBpm: (lt2HeartRateBpm * 1.03).round() + 1,
        maxHeartRateBpm: 195,
        typicalLactateMmolL: 6.5,
        physiologicalAdaptation: 'Maksymalny rzut serca, pojemność minutowa układu krążenia, kinetyka VO2.',
      ),
      LabTrainingZone(
        zoneIndex: 6,
        code: 'Z6',
        name: 'Pojemność Beztlenowa (VLaMax & W\')',
        minWatts: z5Max + 1,
        maxWatts: z6Max,
        minHeartRateBpm: 0,
        maxHeartRateBpm: 210,
        typicalLactateMmolL: 11.5,
        physiologicalAdaptation: 'Glikoliza beztlenowa, tolerancja ostrego zakwaszenia jonami wodorowymi H+.',
      ),
      LabTrainingZone(
        zoneIndex: 7,
        code: 'Z7',
        name: 'Moc Nerwowo-Mięśniowa (Sprint)',
        minWatts: z6Max + 1,
        maxWatts: 2200,
        minHeartRateBpm: 0,
        maxHeartRateBpm: 220,
        typicalLactateMmolL: 15.0,
        physiologicalAdaptation: 'Układ fosfagenowy (ATP-PCr), rekrutacja szybkokurczliwych włókien IIx.',
      ),
    ];
  }

  // =========================================================================
  // FABRYKI I WZORCE DLA KATEGORII KOLARZY (BENCHMARKS)
  // =========================================================================

  /// Wzorcowy profil laboratoryjny czołowego sprintera WorldTour (np. Jasper Philipsen / Caleb Ewan).
  ///
  /// Cechy: bardzo wysoki VLaMax (0.85 mmol/l/s), ogromna moc beztlenowa,
  /// niższy udział LT2 w VO2max (74%), wysokie spalanie węglowodanów.
  factory LactateAndLabProfile.benchmarkWorldTourSprinter({
    double weightKg = 74.0,
    int ftpWatts = 405,
  }) {
    final int lt1 = (ftpWatts * 0.68).round();
    final int map = (ftpWatts * 1.28).round();
    return LactateAndLabProfile(
      lt1Watts: lt1,
      lt1LactateMmolL: 1.9,
      lt1HeartRateBpm: 146,
      fatMaxWatts: (lt1 * 0.94).round(),
      fatMaxOxidationRateGramsPerHour: 48.0,
      lt2Watts: ftpWatts,
      lt2LactateMmolL: 4.1,
      lt2HeartRateBpm: 173,
      vlaMaxMmolLPerSec: 0.86,
      vo2MaxMlKgMin: 74.5,
      powerAtVo2MaxWatts: map,
      grossEfficiencyPercent: 21.8,
      deltaEfficiencyPercent: 23.9,
      referenceWeightKg: weightKg,
    );
  }

  /// Wzorcowy profil laboratoryjny lidera Grand Tour / górala światowej klasy (np. Jonas Vingegaard / Tadej Pogačar).
  ///
  /// Cechy: umiarkowanie niski VLaMax (0.33 mmol/l/s), potężny pułap tlenowy VO2max (86 ml/kg/min),
  /// bardzo wysokie LT2 (ponad 85% MAP), znakomita sprawność mechaniczna (23.8%).
  factory LactateAndLabProfile.benchmarkWorldTourClimber({
    double weightKg = 60.0,
    int ftpWatts = 390, // 6.5 W/kg!
  }) {
    final int lt1 = (ftpWatts * 0.79).round(); // 308W (5.13 W/kg w strefie tlenowej!)
    final int map = (ftpWatts * 1.18).round();
    return LactateAndLabProfile(
      lt1Watts: lt1,
      lt1LactateMmolL: 1.6,
      lt1HeartRateBpm: 154,
      fatMaxWatts: (lt1 * 0.98).round(),
      fatMaxOxidationRateGramsPerHour: 74.0,
      lt2Watts: ftpWatts,
      lt2LactateMmolL: 3.8,
      lt2HeartRateBpm: 178,
      vlaMaxMmolLPerSec: 0.33,
      vo2MaxMlKgMin: 86.5,
      powerAtVo2MaxWatts: map,
      grossEfficiencyPercent: 23.8,
      deltaEfficiencyPercent: 25.4,
      referenceWeightKg: weightKg,
    );
  }

  /// Wzorcowy profil laboratoryjny mistrza jazdy indywidualnej na czas (np. Filippo Ganna / Remco Evenepoel).
  ///
  /// Cechy: ekstremalnie niski VLaMax (0.24 mmol/l/s), ogromna bezwzględna moc progowa (460W+),
  /// niemal całkowite stłumienie produkcji kwasu mlekowego przy jeździe tempem.
  factory LactateAndLabProfile.benchmarkWorldTourTimeTrialist({
    double weightKg = 76.0,
    int ftpWatts = 460, // 6.05 W/kg bezwzględnej machiny
  }) {
    final int lt1 = (ftpWatts * 0.81).round(); // 372W
    final int map = (ftpWatts * 1.16).round();
    return LactateAndLabProfile(
      lt1Watts: lt1,
      lt1LactateMmolL: 1.5,
      lt1HeartRateBpm: 152,
      fatMaxWatts: (lt1 * 0.97).round(),
      fatMaxOxidationRateGramsPerHour: 78.0,
      lt2Watts: ftpWatts,
      lt2LactateMmolL: 3.7,
      lt2HeartRateBpm: 176,
      vlaMaxMmolLPerSec: 0.24,
      vo2MaxMlKgMin: 83.0,
      powerAtVo2MaxWatts: map,
      grossEfficiencyPercent: 24.2,
      deltaEfficiencyPercent: 25.8,
      referenceWeightKg: weightKg,
    );
  }

  /// Wzorcowy profil punchera / mistrza klasyków ardeńskich i brukowanych (np. Mathieu van der Poel / Wout van Aert).
  ///
  /// Cechy: zbalansowany, wszechstronny VLaMax (0.55 mmol/l/s), łączący eksplozywne przyspieszenie z mocną bazą.
  factory LactateAndLabProfile.benchmarkWorldTourPuncheur({
    double weightKg = 73.0,
    int ftpWatts = 435,
  }) {
    final int lt1 = (ftpWatts * 0.74).round();
    final int map = (ftpWatts * 1.22).round();
    return LactateAndLabProfile(
      lt1Watts: lt1,
      lt1LactateMmolL: 1.8,
      lt1HeartRateBpm: 150,
      fatMaxWatts: (lt1 * 0.96).round(),
      fatMaxOxidationRateGramsPerHour: 62.0,
      lt2Watts: ftpWatts,
      lt2LactateMmolL: 4.0,
      lt2HeartRateBpm: 175,
      vlaMaxMmolLPerSec: 0.55,
      vo2MaxMlKgMin: 81.5,
      powerAtVo2MaxWatts: map,
      grossEfficiencyPercent: 22.9,
      deltaEfficiencyPercent: 24.7,
      referenceWeightKg: weightKg,
    );
  }

  /// Fabryka generująca realistyczny profil laboratoryjny na podstawie parametrów [RiderPhysiology],
  /// specjalizacji kolarskiej [RiderSpecialization] oraz opcjonalnego [RiderPowerProfile].
  factory LactateAndLabProfile.fromPhysiology(
    RiderPhysiology physiology, {
    RiderSpecialization specialization = RiderSpecialization.gcClimber,
    RiderPowerProfile? powerProfile,
  }) {
    final double weight = math.max(45.0, physiology.weightKg);
    final int ftp = math.max(120, physiology.ftpWatts);
    final double vo2 = math.max(45.0, physiology.vo2Max);
    final int lthr = physiology.lactateThresholdHr;

    // 1. Wyznaczenie VLaMax w zależności od specjalizacji i mocy sprinterskiej
    double vlaMax;
    double lt1Ratio;
    double lt1Lactate;
    double lt2Lactate;
    double efficiency;

    switch (specialization) {
      case RiderSpecialization.pureSprinter:
        vlaMax = 0.82;
        lt1Ratio = 0.67;
        lt1Lactate = 2.0;
        lt2Lactate = 4.2;
        efficiency = 21.6;
        break;
      case RiderSpecialization.versatileSprinter:
        vlaMax = 0.72;
        lt1Ratio = 0.70;
        lt1Lactate = 1.9;
        lt2Lactate = 4.1;
        efficiency = 22.0;
        break;
      case RiderSpecialization.puncher:
        vlaMax = 0.58;
        lt1Ratio = 0.73;
        lt1Lactate = 1.8;
        lt2Lactate = 4.0;
        efficiency = 22.6;
        break;
      case RiderSpecialization.classicCobbles:
        vlaMax = 0.52;
        lt1Ratio = 0.74;
        lt1Lactate = 1.8;
        lt2Lactate = 4.0;
        efficiency = 22.8;
        break;
      case RiderSpecialization.gcClimber:
        vlaMax = 0.35;
        lt1Ratio = 0.78;
        lt1Lactate = 1.7;
        lt2Lactate = 3.9;
        efficiency = 23.6;
        break;
      case RiderSpecialization.pureClimber:
        vlaMax = 0.31;
        lt1Ratio = 0.79;
        lt1Lactate = 1.6;
        lt2Lactate = 3.9;
        efficiency = 23.4;
        break;
      case RiderSpecialization.timeTrialist:
        vlaMax = 0.25;
        lt1Ratio = 0.81;
        lt1Lactate = 1.6;
        lt2Lactate = 3.8;
        efficiency = 24.1;
        break;
      case RiderSpecialization.domestiqueEngine:
        vlaMax = 0.40;
        lt1Ratio = 0.75;
        lt1Lactate = 1.8;
        lt2Lactate = 4.0;
        efficiency = 22.8;
        break;
      case RiderSpecialization.breakawaySpecialist:
        vlaMax = 0.46;
        lt1Ratio = 0.75;
        lt1Lactate = 1.8;
        lt2Lactate = 4.0;
        efficiency = 23.0;
        break;
    }

    // Korekta VLaMax na podstawie realnego profilu mocy jeśli dostępny
    if (powerProfile != null && powerProfile.watts5s > 0) {
      final double sprintWPerKg = powerProfile.watts5s / weight;
      if (sprintWPerKg > 20.0) {
        vlaMax = math.max(vlaMax, 0.78);
      } else if (sprintWPerKg < 15.0) {
        vlaMax = math.min(vlaMax, 0.38);
      }
    }

    // 2. Wyznaczenie mocy MAP (Maximal Aerobic Power / pułapu tlenowego)
    int mapWatts;
    if (powerProfile != null && powerProfile.watts5m > 0) {
      mapWatts = powerProfile.watts5m;
    } else {
      // Szacunek MAP na podstawie VO2max i sprawności mechanicznej
      // 1 L O2 zużywa ok. 20.9 kJ energii. Praca zależy od Gross Efficiency.
      final double lO2Min = (vo2 * weight) / 1000.0;
      final double totalMetabolicWatts = (lO2Min * 20900.0) / 60.0;
      mapWatts = (totalMetabolicWatts * (efficiency / 100.0)).round();
      if (mapWatts <= ftp) {
        mapWatts = (ftp * 1.20).round();
      }
    }

    // 3. Progi LT1 i LT2
    final int lt1 = (ftp * lt1Ratio).round();
    final int lt1Hr = (lthr * 0.85).round();
    final int fatMax = (lt1 * 0.96).round();
    final double fatMaxOxidation = (40.0 + (efficiency - 20.0) * 8.0 + (1.0 - vlaMax) * 20.0)
        .clamp(35.0, 85.0);

    return LactateAndLabProfile(
      lt1Watts: lt1,
      lt1LactateMmolL: lt1Lactate,
      lt1HeartRateBpm: lt1Hr,
      fatMaxWatts: fatMax,
      fatMaxOxidationRateGramsPerHour: double.parse(fatMaxOxidation.toStringAsFixed(1)),
      lt2Watts: ftp,
      lt2LactateMmolL: lt2Lactate,
      lt2HeartRateBpm: lthr,
      vlaMaxMmolLPerSec: double.parse(vlaMax.toStringAsFixed(2)),
      vo2MaxMlKgMin: vo2,
      powerAtVo2MaxWatts: mapWatts,
      grossEfficiencyPercent: double.parse(efficiency.toStringAsFixed(1)),
      deltaEfficiencyPercent: double.parse((efficiency + 1.8).toStringAsFixed(1)),
      referenceWeightKg: weight,
    );
  }

  /// Fabryka tworząca profil laboratoryjny bezpośrednio z obiektu zawodnika [Rider].
  factory LactateAndLabProfile.fromRider(Rider rider) {
    return LactateAndLabProfile.fromPhysiology(
      rider.physiology,
      specialization: rider.specialization,
      powerProfile: rider.powerProfile,
    );
  }

  // =========================================================================
  // BOILERPLATE: copyWith, toJson, fromJson, ==, hashCode, toString
  // =========================================================================

  LactateAndLabProfile copyWith({
    int? lt1Watts,
    double? lt1LactateMmolL,
    int? lt1HeartRateBpm,
    int? fatMaxWatts,
    double? fatMaxOxidationRateGramsPerHour,
    int? lt2Watts,
    double? lt2LactateMmolL,
    int? lt2HeartRateBpm,
    double? vlaMaxMmolLPerSec,
    double? vo2MaxMlKgMin,
    int? powerAtVo2MaxWatts,
    double? grossEfficiencyPercent,
    double? deltaEfficiencyPercent,
    double? referenceWeightKg,
  }) {
    return LactateAndLabProfile(
      lt1Watts: lt1Watts ?? this.lt1Watts,
      lt1LactateMmolL: lt1LactateMmolL ?? this.lt1LactateMmolL,
      lt1HeartRateBpm: lt1HeartRateBpm ?? this.lt1HeartRateBpm,
      fatMaxWatts: fatMaxWatts ?? this.fatMaxWatts,
      fatMaxOxidationRateGramsPerHour:
          fatMaxOxidationRateGramsPerHour ?? this.fatMaxOxidationRateGramsPerHour,
      lt2Watts: lt2Watts ?? this.lt2Watts,
      lt2LactateMmolL: lt2LactateMmolL ?? this.lt2LactateMmolL,
      lt2HeartRateBpm: lt2HeartRateBpm ?? this.lt2HeartRateBpm,
      vlaMaxMmolLPerSec: vlaMaxMmolLPerSec ?? this.vlaMaxMmolLPerSec,
      vo2MaxMlKgMin: vo2MaxMlKgMin ?? this.vo2MaxMlKgMin,
      powerAtVo2MaxWatts: powerAtVo2MaxWatts ?? this.powerAtVo2MaxWatts,
      grossEfficiencyPercent: grossEfficiencyPercent ?? this.grossEfficiencyPercent,
      deltaEfficiencyPercent: deltaEfficiencyPercent ?? this.deltaEfficiencyPercent,
      referenceWeightKg: referenceWeightKg ?? this.referenceWeightKg,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lt1Watts': lt1Watts,
      'lt1LactateMmolL': lt1LactateMmolL,
      'lt1HeartRateBpm': lt1HeartRateBpm,
      'fatMaxWatts': fatMaxWatts,
      'fatMaxOxidationRateGramsPerHour': fatMaxOxidationRateGramsPerHour,
      'lt2Watts': lt2Watts,
      'lt2LactateMmolL': lt2LactateMmolL,
      'lt2HeartRateBpm': lt2HeartRateBpm,
      'vlaMaxMmolLPerSec': vlaMaxMmolLPerSec,
      'vo2MaxMlKgMin': vo2MaxMlKgMin,
      'powerAtVo2MaxWatts': powerAtVo2MaxWatts,
      'grossEfficiencyPercent': grossEfficiencyPercent,
      'deltaEfficiencyPercent': deltaEfficiencyPercent,
      'referenceWeightKg': referenceWeightKg,
    };
  }

  factory LactateAndLabProfile.fromJson(Map<String, dynamic> json) {
    return LactateAndLabProfile(
      lt1Watts: (json['lt1Watts'] as num).toInt(),
      lt1LactateMmolL: (json['lt1LactateMmolL'] as num).toDouble(),
      lt1HeartRateBpm: (json['lt1HeartRateBpm'] as num).toInt(),
      fatMaxWatts: (json['fatMaxWatts'] as num).toInt(),
      fatMaxOxidationRateGramsPerHour:
          (json['fatMaxOxidationRateGramsPerHour'] as num).toDouble(),
      lt2Watts: (json['lt2Watts'] as num).toInt(),
      lt2LactateMmolL: (json['lt2LactateMmolL'] as num).toDouble(),
      lt2HeartRateBpm: (json['lt2HeartRateBpm'] as num).toInt(),
      vlaMaxMmolLPerSec: (json['vlaMaxMmolLPerSec'] as num).toDouble(),
      vo2MaxMlKgMin: (json['vo2MaxMlKgMin'] as num).toDouble(),
      powerAtVo2MaxWatts: (json['powerAtVo2MaxWatts'] as num).toInt(),
      grossEfficiencyPercent: (json['grossEfficiencyPercent'] as num).toDouble(),
      deltaEfficiencyPercent: (json['deltaEfficiencyPercent'] as num?)?.toDouble() ?? 24.8,
      referenceWeightKg: (json['referenceWeightKg'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LactateAndLabProfile &&
        other.lt1Watts == lt1Watts &&
        other.lt1LactateMmolL == lt1LactateMmolL &&
        other.lt1HeartRateBpm == lt1HeartRateBpm &&
        other.fatMaxWatts == fatMaxWatts &&
        other.fatMaxOxidationRateGramsPerHour == fatMaxOxidationRateGramsPerHour &&
        other.lt2Watts == lt2Watts &&
        other.lt2LactateMmolL == lt2LactateMmolL &&
        other.lt2HeartRateBpm == lt2HeartRateBpm &&
        other.vlaMaxMmolLPerSec == vlaMaxMmolLPerSec &&
        other.vo2MaxMlKgMin == vo2MaxMlKgMin &&
        other.powerAtVo2MaxWatts == powerAtVo2MaxWatts &&
        other.grossEfficiencyPercent == grossEfficiencyPercent &&
        other.deltaEfficiencyPercent == deltaEfficiencyPercent &&
        other.referenceWeightKg == referenceWeightKg;
  }

  @override
  int get hashCode {
    return Object.hash(
      lt1Watts,
      lt1LactateMmolL,
      lt1HeartRateBpm,
      fatMaxWatts,
      fatMaxOxidationRateGramsPerHour,
      lt2Watts,
      lt2LactateMmolL,
      lt2HeartRateBpm,
      vlaMaxMmolLPerSec,
      vo2MaxMlKgMin,
      powerAtVo2MaxWatts,
      grossEfficiencyPercent,
      referenceWeightKg,
    );
  }

  @override
  String toString() {
    return 'LactateAndLabProfile('
        'LT1: ${lt1Watts}W (${lt1WattsPerKg.toStringAsFixed(2)} W/kg) @ ${lt1LactateMmolL}mmol/l, '
        'LT2: ${lt2Watts}W (${lt2WattsPerKg.toStringAsFixed(2)} W/kg) @ ${lt2LactateMmolL}mmol/l, '
        'VLaMax: ${vlaMaxMmolLPerSec}mmol/l/s [${metabolicPhenotype.name}], '
        'VO2max: ${vo2MaxMlKgMin}ml/kg/min, '
        'GrossEff: $grossEfficiencyPercent%)';
  }
}
