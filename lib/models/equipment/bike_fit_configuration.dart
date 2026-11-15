// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

/// Szczegółowy model konfiguracji pozycji kolarza na rowerze wyścigowym (Bike Fitting Configuration).
///
/// Precyzyjnie modeluje 9 parametrów geometrii kontaktu zawodnika z maszyną:
/// 1. **Strefa Siodła**:
///    - [saddleHeightMm]: Wysokość siodła mierzona od osi suportu (BB center) do wierzchołka siodła [mm].
///    - [saddleSetbackMm]: Cofnięcie czubka siodła za pionową oś suportu (BB Setback) [mm].
///    - [saddleTiltDegrees]: Kąt pochylenia siodła w stopniach (ujemny = nos w dół, np. -2.0°).
/// 2. **Strefa Kokpitu**:
///    - [cockpitWidthMm]: Szerokość kierownicy c-c / dropy (360, 380, 400, 420 mm).
///    - [stemLengthMm]: Długość mostka kierownicy (90–140 mm).
///    - [spacersStackMm]: Wysokość podkładek pod mostkiem (0 mm = slammed stem vs 20 mm).
///    - [hoodInwardTiltDegrees]: Kąt podgięcia klamkomanetek do wewnątrz (0°–35° pod pozycję "puppy paws").
/// 3. **Strefa Napędu i Pedałowania**:
///    - [crankArmLengthMm]: Długość ramion korby (165.0, 167.5, 170.0, 172.5, 175.0 mm).
///    - [cleatOffsetMm]: Przesunięcie wzdłużne bloków w butach względem osi śródstopia (np. -10 do +10 mm).
class BikeFitConfiguration {
  // Limity i normy techniczne UCI
  static const double uciMinSaddleSetbackStandardMm = 50.0;
  static const double uciMaxSaddleTiltDegrees = 9.0;
  static const int uciMinCockpitWidthMm = 350;
  static const double uciMaxLegalHoodInwardTiltDegrees = 14.0;

  // Domyślna baza neutralna do kalkulacji różnic CdA i watów (Endurance Baseline)
  static const int baselineCockpitWidthMm = 400;
  static const int baselineStemLengthMm = 110;
  static const int baselineSpacersStackMm = 20;
  static const double baselineCrankLengthMm = 172.5;

  /// Wysokość siodła od środka osi suportu do środka wierzchołka siodła [mm]
  /// Typowy zakres: 620.0 – 880.0 mm (ok. 88.3% przekroku kolarza).
  final double saddleHeightMm;

  /// Cofnięcie czubka siodełka za pionową linię przechodzącą przez oś suportu (BB Setback) [mm]
  /// Norma UCI: min. 50 mm (chyba że zawodnik ma morfologiczne odstępstwo UCI do 0 mm).
  final double saddleSetbackMm;

  /// Kąt pochylenia siodełka w stopniach [°]
  /// Wartości ujemne oznaczają pochylenie nosa w dół (np. -2.0°), wartości dodatnie nos w górę.
  /// Norma UCI dopuszcza do ±9.0° z tolerancją.
  final double saddleTiltDegrees;

  /// Szerokość kierownicy c-c na klamkach / dropach [mm]
  /// Typowe rozmiary: 360, 380, 400, 420, 440 mm (minimum UCI: 350 mm).
  final int cockpitWidthMm;

  /// Długość mostka kierownicy [mm]
  /// Zakres: 90 – 140 mm.
  final int stemLengthMm;

  /// Wysokość podkładek pod mostkiem na rurze sterowej [mm]
  /// 0 mm oznacza "slammed stem" (maksymalny spadek kierownicy względem siodła).
  final int spacersStackMm;

  /// Kąt rotacji / podgięcia klamkomanetek do wewnątrz [°]
  /// Zakres: 0.0° – 35.0°.
  /// Zgodnie z wytycznymi UCI od 2024 roku limit wynosi 14.0°. Wartości >14° to agresywna
  /// pozycja aerodynamiczna ("puppy paws" / aero hack), ryzykowna pod kątem kontroli sędziowskiej.
  final double hoodInwardTiltDegrees;

  /// Długość ramienia korby [mm]
  /// Dostępne standardy: 165.0, 167.5, 170.0, 172.5, 175.0, 177.5 mm.
  /// Krótsze ramiona (165 mm) otwierają kąt biodrowy w niskiej pozycji aero.
  final double crankArmLengthMm;

  /// Przesunięcie bloków zatrzaskowych w butach wzdłuż podeszwy względem osi śródstopia [mm]
  /// Zakres: -10.0 mm (przesunięcie w stronę śródstopia / mid-foot) do +10.0 mm (w stronę palców).
  /// Ujemny offset stabilizuje staw skokowy i odciąża ścięgno Achillesa na długich etapach.
  final double cleatOffsetMm;

  const BikeFitConfiguration({
    required this.saddleHeightMm,
    required this.saddleSetbackMm,
    required this.saddleTiltDegrees,
    required this.cockpitWidthMm,
    required this.stemLengthMm,
    required this.spacersStackMm,
    required this.hoodInwardTiltDegrees,
    required this.crankArmLengthMm,
    required this.cleatOffsetMm,
  });

  // ===========================================================================
  // 1. WERYFIKACJA REGULAMINU UCI I BEZPIECZEŃSTWA
  // ===========================================================================

  /// Czy mostek jest zamontowany bezpośrednio na główce ramy (brak spacerów)
  bool get isSlammedStem => spacersStackMm <= 0;

  /// Czy klamkomanetki są podgięte w sposób ekstremalny (powyżej limitu UCI 14°)
  bool get hasExtremeAeroHoods => hoodInwardTiltDegrees > uciMaxLegalHoodInwardTiltDegrees;

  /// Kąt przekroczenia limitu przepisów UCI dla klamkomanetek [°]
  double get uciHoodTiltExcessDegrees =>
      math.max(0.0, hoodInwardTiltDegrees - uciMaxLegalHoodInwardTiltDegrees);

  /// Czy cała konfiguracja bike fittingu spełnia oficjalne przepisy techniczne UCI
  bool get isUciLegal {
    // 1. Cofnięcie siodła min 50mm (chyba że morfologiczne dopuszczenie do 0mm dla niższych kolarzy)
    if (saddleSetbackMm < 0.0) return false;

    // 2. Kąt siodła max ±9°
    if (saddleTiltDegrees.abs() > uciMaxSaddleTiltDegrees) return false;

    // 3. Szerokość kierownicy min 350mm
    if (cockpitWidthMm < uciMinCockpitWidthMm) return false;

    // 4. Podgięcie klamek max 14°
    if (hoodInwardTiltDegrees > uciMaxLegalHoodInwardTiltDegrees) return false;

    return true;
  }

  /// Lista uwag i ostrzeżeń biomechanicznych lub regulaminowych dla sztabu mechaników
  List<String> get biomechanicalWarnings {
    final warnings = <String>[];

    if (hasExtremeAeroHoods) {
      warnings.add(
        'Klamkomanetki podgięte o ${hoodInwardTiltDegrees.toStringAsFixed(1)}° (limit UCI: 14.0°). Ryzyko dyskwalifikacji technicznej!',
      );
    }

    if (saddleSetbackMm < uciMinSaddleSetbackStandardMm) {
      warnings.add(
        'Cofnięcie siodła ${saddleSetbackMm.toStringAsFixed(1)} mm < 50 mm. Wymaga zgłoszenia morfologicznego do komisarzy UCI.',
      );
    }

    if (saddleTiltDegrees < -4.0) {
      warnings.add(
        'Pochylenie nosa siodła (${saddleTiltDegrees.toStringAsFixed(1)}°) może powodować zsuwanie się i nadmierne obciążenie nadgarstków.',
      );
    }

    if (isSlammedStem && cockpitWidthMm <= 360) {
      warnings.add(
        'Ekstremalna pozycja super-aero (slammed stem + 360mm). Może ograniczać wentylację płuc VE na stromych podjazdach.',
      );
    }

    if (crankArmLengthMm >= 175.0 && isSlammedStem) {
      warnings.add(
        'Długa korba (${crankArmLengthMm}mm) przy braku podkładek domyka kąt biodrowy w GMP, zwiększając ryzyko bólu biodra.',
      );
    }

    return warnings;
  }

  // ===========================================================================
  // 2. WPŁYW AERODYNAMICZNY (CdA) I WATY ZAOSZCZĘDZONE
  // ===========================================================================

  /// Łączny modyfikator współczynnika oporu czołowego CdA kolarza wynikający z bike fittingu [m²]
  /// Wartości ujemne oznaczają redukcję oporu powietrza (bardziej aerodynamiczna sylwetka).
  double get totalCdaModifier {
    // A. Szerokość kierownicy: każdy centymetr węższej kierownicy redukuje powierzchnię rzutu czołowego
    // 360mm daje -0.0100 m² względem 400mm
    final double cockpitAero = (cockpitWidthMm - baselineCockpitWidthMm) * 0.00025;

    // B. Podgięcie klamek do wewnątrz: zwęża łokcie i barki, tworząc pozycję "puppy paws"
    // Do 14° daje do -0.0042 m², ekstremalne 30° daje -0.0065 m² z malejącym przyrostem krańcowym
    final double clampedTilt = hoodInwardTiltDegrees.clamp(0.0, 35.0);
    final double hoodTiltAero = clampedTilt <= 14.0
        ? -(clampedTilt / 14.0) * 0.0042
        : -0.0042 - ((clampedTilt - 14.0) / 21.0) * 0.0023;

    // C. Podkładki pod mostkiem (Spacers Stack): obniżenie kokpitu spłaszcza plecy zawodnika
    // 0 mm (slammed stem) daje -0.0055 m² względem 20 mm
    final double spacersAero = ((spacersStackMm - baselineSpacersStackMm) / 20.0) * 0.0055;

    // D. Długość mostka: dłuższy mostek rozciąga tułów, redukując zawirowania powietrza
    final double stemAero = -(stemLengthMm - baselineStemLengthMm) * 0.00007;

    // E. Pochylenie nosa siodła i cofnięcie: nos w dół umożliwia rotację miednicy (anterior pelvic tilt)
    final double pelvicAero = (saddleTiltDegrees.clamp(-5.0, 0.0) / 5.0) * 0.0018;

    return cockpitAero + hoodTiltAero + spacersAero + stemAero + pelvicAero;
  }

  /// Szacowana oszczędność mocy w Watach przy danej prędkości [km/h]
  /// Porównana z tradycyjną pozycją rekreacyjną (420 mm, 20 mm podkładek, 0° klamki).
  int estimatedWattsSavedAtSpeed(double speedKmh) {
    const double airDensity = 1.225; // kg/m³
    final double velocityMs = speedKmh / 3.6;
    // P_aero = 0.5 * rho * CdA * v^3
    final double baselineDeltaCda = totalCdaModifier - 0.005; // różnica względem 420mm relaks
    final double wattsDifference = 0.5 * airDensity * baselineDeltaCda.abs() * math.pow(velocityMs, 3);
    return wattsDifference.round().clamp(0, 50);
  }

  /// Oszczędność mocy w Watach przy prędkości peletonu 45 km/h
  int get estimatedWattsSavedAt45Kmh => estimatedWattsSavedAtSpeed(45.0);

  // ===========================================================================
  // 3. STEROWNOŚĆ, KOMFORT I BIOMECHANIKA
  // ===========================================================================

  /// Wskaźnik stabilności i sterowności roweru (Handling Control Index) w skali 0–100.
  /// 100 = maksymalna kontrola, stabilne prowadzenie na brukach i zjazdach.
  /// <60 = nerwowe prowadzenie, zwiększone ryzyko kraksy w gęstym peletonie lub przy bocznym wietrze.
  double get handlingControlScore {
    double score = 85.0;

    // Szerokość kierownicy: 420mm = +8 pkt, 360mm = -15 pkt (krótsze ramię dźwigni)
    score += (cockpitWidthMm - 400) * 0.35;

    // Podgięcie klamek: powyżej 14° drastycznie utrudnia chwyt dźwigni hamulca w nagłym hamowaniu
    if (hoodInwardTiltDegrees > 14.0) {
      score -= (hoodInwardTiltDegrees - 14.0) * 1.2;
    }

    // Długość mostka: mostki >130mm opóźniają reakcję na skręt
    if (stemLengthMm > 120) {
      score -= (stemLengthMm - 120) * 0.4;
    }

    // Slammed stem obniża środek ciężkości (dobrze), ale ogranicza widoczność do przodu w tłoku
    if (isSlammedStem) {
      score -= 4.0;
    }

    return score.clamp(35.0, 99.0);
  }

  /// Wskaźnik komfortu biomechanicznego i wytrzymałości odcinka lędźwiowego (0–100).
  /// Niższy komfort oznacza szybszą akumulację zmęczenia pleców na etapach powyżej 160 km.
  double get comfortScore {
    double score = 80.0;

    // Podkładki pod mostkiem: wyższy kokpit = mniejszy nacisk na odcinek lędźwiowy
    score += (spacersStackMm - 10) * 0.9;

    // Kąt siodełka: nos w dół odciąża tkanki miękkie, ale zbyt duży kąt przeciąża ramiona
    if (saddleTiltDegrees >= -3.0 && saddleTiltDegrees <= -1.0) {
      score += 5.0; // sweet spot
    } else if (saddleTiltDegrees < -4.0) {
      score -= (saddleTiltDegrees.abs() - 4.0) * 4.0;
    }

    // Długość mostka: zbyt długi mostek powoduje przeprost kręgosłupa
    if (stemLengthMm > 120) {
      score -= (stemLengthMm - 120) * 0.6;
    }

    // Krótsza korba otwiera kąt biodrowy, co zwiększa komfort dolnego odcinka pleców
    if (crankArmLengthMm <= 167.5) {
      score += 4.5;
    } else if (crankArmLengthMm >= 175.0) {
      score -= 4.0;
    }

    // Cofnięcie bloków (mid-foot) odciąża łydki i rozcięgno podeszwowe
    if (cleatOffsetMm < -3.0) {
      score += 3.5;
    }

    return score.clamp(30.0, 98.0);
  }

  /// Szacowany kąt stawu biodrowego w Górnym Martwym Punkcie (Top Dead Center) [°]
  /// Kąt <45° powoduje zaciśnięcie naczyń krwionośnych i spadek mocy progowej.
  double get hipAngleAtTdcDegrees {
    // Baza: 55° przy standardowej geometrii
    double angle = 55.0;

    // Obniżenie kokpitu zamyka kąt biodrowy
    angle -= (25 - spacersStackMm) * 0.35;

    // Krótsze ramię korby (np. 165 mm vs 175 mm) unosi udo o 10 mm mniej w najwyższym punkcie
    angle += (baselineCrankLengthMm - crankArmLengthMm) * 0.32;

    // Pochylenie nosa siodła w dół rotuje miednicę i otwiera przestrzeń biodrową
    angle += saddleTiltDegrees.abs() * 0.45;

    return angle.clamp(40.0, 68.0);
  }

  /// Optymalna preferowana kadencja pedałowania wynikająca z długości korby [RPM]
  /// Krótsze ramię korby (mniejszy promień obrotu stopy) sprzyja wyższej, płynniejszej kadencji.
  int get optimalCadenceRpm {
    if (crankArmLengthMm <= 165.0) return 96;
    if (crankArmLengthMm <= 170.0) return 92;
    if (crankArmLengthMm <= 172.5) return 89;
    return 86; // 175mm+
  }

  /// Wskaźnik przeciążenia mięśni łydek i ścięgna Achillesa wynikający z pozycji bloków (0.0 - 1.0)
  /// Wartości niższe oznaczają bezpieczniejsze odciążenie ścięgna (mid-foot cleat).
  double get calfStrainIndex {
    // 0.5 to neutralna baza przy cleatOffset = 0mm
    final base = 0.5 + (cleatOffsetMm / 20.0);
    return base.clamp(0.2, 0.95);
  }

  // ===========================================================================
  // 4. PREDEFINIOWANE KONFIGURACJE BAZOWE (PRESETS)
  // ===========================================================================

  /// Konfiguracja agresywna super-aero (Breakaway & Flat Aero Attack)
  /// Wąska kierownica 360mm, mostek 130mm bez podkładek, klamki 22°, krótka korba 165mm.
  factory BikeFitConfiguration.slammedAeroRoad({
    double saddleHeightMm = 745.0,
    double saddleSetbackMm = 52.0,
  }) {
    return BikeFitConfiguration(
      saddleHeightMm: saddleHeightMm,
      saddleSetbackMm: saddleSetbackMm,
      saddleTiltDegrees: -2.5,
      cockpitWidthMm: 360,
      stemLengthMm: 130,
      spacersStackMm: 0,
      hoodInwardTiltDegrees: 22.0,
      crankArmLengthMm: 165.0,
      cleatOffsetMm: -5.0,
    );
  }

  /// Wzorcowa wyścigowa konfiguracja WorldTour zgodna z przepisami technicznymi UCI
  /// Kierownica 380mm, mostek 120mm z 1 podkładką 5mm, klamki 12° (legalne UCI), korba 170mm.
  factory BikeFitConfiguration.uciWorldTourBalanced({
    double saddleHeightMm = 745.0,
    double saddleSetbackMm = 58.0,
  }) {
    return BikeFitConfiguration(
      saddleHeightMm: saddleHeightMm,
      saddleSetbackMm: saddleSetbackMm,
      saddleTiltDegrees: -1.5,
      cockpitWidthMm: 380,
      stemLengthMm: 120,
      spacersStackMm: 5,
      hoodInwardTiltDegrees: 12.0,
      crankArmLengthMm: 170.0,
      cleatOffsetMm: -3.0,
    );
  }

  /// Konfiguracja wspinaczkowa pod wysokogórskie podjazdy (Climber Lightweight)
  /// Kierownica 400mm (otwiera klatkę piersiową pod wentylację płuc VE), mostek 110mm, 10mm podkładek.
  factory BikeFitConfiguration.climberLightweight({
    double saddleHeightMm = 745.0,
    double saddleSetbackMm = 60.0,
  }) {
    return BikeFitConfiguration(
      saddleHeightMm: saddleHeightMm,
      saddleSetbackMm: saddleSetbackMm,
      saddleTiltDegrees: -1.0,
      cockpitWidthMm: 400,
      stemLengthMm: 110,
      spacersStackMm: 10,
      hoodInwardTiltDegrees: 8.0,
      crankArmLengthMm: 170.0,
      cleatOffsetMm: 0.0,
    );
  }

  /// Konfiguracja na brukowane klasyki i długie etapy (Cobbled Endurance & Roubaix)
  /// Szeroka kierownica 420mm dla maksymalnej kontroli w błocie i na sektorach bruku, 20mm podkładek.
  factory BikeFitConfiguration.cobbledEnduranceComfort({
    double saddleHeightMm = 740.0,
    double saddleSetbackMm = 65.0,
  }) {
    return BikeFitConfiguration(
      saddleHeightMm: saddleHeightMm,
      saddleSetbackMm: saddleSetbackMm,
      saddleTiltDegrees: 0.0,
      cockpitWidthMm: 420,
      stemLengthMm: 100,
      spacersStackMm: 20,
      hoodInwardTiltDegrees: 4.0,
      crankArmLengthMm: 172.5,
      cleatOffsetMm: -6.0,
    );
  }

  /// Konfiguracja czasowa do jazdy indywidualnej na czas (Time Trial Aero Pursuit)
  /// Skrajnie aerodynamiczna pozycja z krótkimi ramionami korby 165mm i przesuniętym do przodu siodłem.
  factory BikeFitConfiguration.timeTrialAeroPursuit({
    double saddleHeightMm = 750.0,
    double saddleSetbackMm = 50.0,
  }) {
    return BikeFitConfiguration(
      saddleHeightMm: saddleHeightMm,
      saddleSetbackMm: saddleSetbackMm,
      saddleTiltDegrees: -3.5,
      cockpitWidthMm: 380,
      stemLengthMm: 120,
      spacersStackMm: 0,
      hoodInwardTiltDegrees: 14.0,
      crankArmLengthMm: 165.0,
      cleatOffsetMm: -8.0,
    );
  }

  /// Proceduralny generator konfiguracji bike fittingu dopasowany do anatomii kolarza
  /// Wylicza siodło wg formuły LeMonda / Hamleya na podstawie wzrostu i stylu jazdy.
  factory BikeFitConfiguration.proceduralForRider({
    required double heightCm,
    required double weightKg,
    bool isAeroFocus = true,
    bool isClimberFocus = false,
  }) {
    // 1. Szacowanie długości przekroku (Inseam) ~46.5% wysokości ciała
    final double estimatedInseamMm = heightCm * 10.0 * 0.465;

    // 2. Wysokość siodła wg wzoru Greg LeMond (Inseam * 0.883)
    final double saddleHeight = (estimatedInseamMm * 0.883).roundToDouble();

    // 3. Cofnięcie siodła w zależności od wzrostu (wyżsi kolarze mają większe cofnięcie)
    final double saddleSetback = (50.0 + (heightCm - 170.0) * 0.45).clamp(45.0, 85.0);

    // 4. Dobór szerokości kierownicy (nowoczesny trend pro: węższa kierownica dla każdego)
    int cockpitWidth;
    if (heightCm < 174.0 || isAeroFocus) {
      cockpitWidth = 380;
    } else if (heightCm > 188.0 && !isAeroFocus) {
      cockpitWidth = 420;
    } else {
      cockpitWidth = 400;
    }

    // 5. Długość mostka kierownicy proporcjonalna do zasięgu rąk (Reach)
    final int stemLength = (100 + ((heightCm - 168.0) * 0.65).round()).clamp(90, 140);

    // 6. Podkładki i klamki
    final int spacers = isAeroFocus ? 0 : (isClimberFocus ? 10 : 15);
    final double hoodTilt = isAeroFocus ? 14.0 : 8.0;

    // 7. Długość ramion korby
    double crankLength;
    if (isAeroFocus || heightCm < 172.0) {
      crankLength = 165.0;
    } else if (heightCm < 184.0) {
      crankLength = 170.0;
    } else {
      crankLength = 172.5;
    }

    return BikeFitConfiguration(
      saddleHeightMm: saddleHeight,
      saddleSetbackMm: saddleSetback,
      saddleTiltDegrees: isAeroFocus ? -2.0 : -1.0,
      cockpitWidthMm: cockpitWidth,
      stemLengthMm: stemLength,
      spacersStackMm: spacers,
      hoodInwardTiltDegrees: hoodTilt,
      crankArmLengthMm: crankLength,
      cleatOffsetMm: -4.0,
    );
  }

  // ===========================================================================
  // 5. KOPIOWANIE I SERIALIZACJA JSON
  // ===========================================================================

  BikeFitConfiguration copyWith({
    double? saddleHeightMm,
    double? saddleSetbackMm,
    double? saddleTiltDegrees,
    int? cockpitWidthMm,
    int? stemLengthMm,
    int? spacersStackMm,
    double? hoodInwardTiltDegrees,
    double? crankArmLengthMm,
    double? cleatOffsetMm,
  }) {
    return BikeFitConfiguration(
      saddleHeightMm: saddleHeightMm ?? this.saddleHeightMm,
      saddleSetbackMm: saddleSetbackMm ?? this.saddleSetbackMm,
      saddleTiltDegrees: saddleTiltDegrees ?? this.saddleTiltDegrees,
      cockpitWidthMm: cockpitWidthMm ?? this.cockpitWidthMm,
      stemLengthMm: stemLengthMm ?? this.stemLengthMm,
      spacersStackMm: spacersStackMm ?? this.spacersStackMm,
      hoodInwardTiltDegrees: hoodInwardTiltDegrees ?? this.hoodInwardTiltDegrees,
      crankArmLengthMm: crankArmLengthMm ?? this.crankArmLengthMm,
      cleatOffsetMm: cleatOffsetMm ?? this.cleatOffsetMm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'saddleHeightMm': saddleHeightMm,
      'saddleSetbackMm': saddleSetbackMm,
      'saddleTiltDegrees': saddleTiltDegrees,
      'cockpitWidthMm': cockpitWidthMm,
      'stemLengthMm': stemLengthMm,
      'spacersStackMm': spacersStackMm,
      'hoodInwardTiltDegrees': hoodInwardTiltDegrees,
      'crankArmLengthMm': crankArmLengthMm,
      'cleatOffsetMm': cleatOffsetMm,
    };
  }

  factory BikeFitConfiguration.fromJson(Map<String, dynamic> json) {
    return BikeFitConfiguration(
      saddleHeightMm: (json['saddleHeightMm'] as num).toDouble(),
      saddleSetbackMm: (json['saddleSetbackMm'] as num).toDouble(),
      saddleTiltDegrees: (json['saddleTiltDegrees'] as num).toDouble(),
      cockpitWidthMm: (json['cockpitWidthMm'] as num).toInt(),
      stemLengthMm: (json['stemLengthMm'] as num).toInt(),
      spacersStackMm: (json['spacersStackMm'] as num).toInt(),
      hoodInwardTiltDegrees: (json['hoodInwardTiltDegrees'] as num).toDouble(),
      crankArmLengthMm: (json['crankArmLengthMm'] as num).toDouble(),
      cleatOffsetMm: (json['cleatOffsetMm'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BikeFitConfiguration &&
        other.saddleHeightMm == saddleHeightMm &&
        other.saddleSetbackMm == saddleSetbackMm &&
        other.saddleTiltDegrees == saddleTiltDegrees &&
        other.cockpitWidthMm == cockpitWidthMm &&
        other.stemLengthMm == stemLengthMm &&
        other.spacersStackMm == spacersStackMm &&
        other.hoodInwardTiltDegrees == hoodInwardTiltDegrees &&
        other.crankArmLengthMm == crankArmLengthMm &&
        other.cleatOffsetMm == cleatOffsetMm;
  }

  @override
  int get hashCode => Object.hash(
        saddleHeightMm,
        saddleSetbackMm,
        saddleTiltDegrees,
        cockpitWidthMm,
        stemLengthMm,
        spacersStackMm,
        hoodInwardTiltDegrees,
        crankArmLengthMm,
        cleatOffsetMm,
      );

  @override
  String toString() {
    return 'BikeFitConfiguration(saddle: ${saddleHeightMm.round()}mm/setback: ${saddleSetbackMm.round()}mm/tilt: $saddleTiltDegrees° | cockpit: ${cockpitWidthMm}mm/stem: ${stemLengthMm}mm/spacers: ${spacersStackMm}mm/hoods: $hoodInwardTiltDegrees° | cranks: ${crankArmLengthMm}mm/cleats: ${cleatOffsetMm}mm | CdA: ${totalCdaModifier.toStringAsFixed(4)})';
  }
}
