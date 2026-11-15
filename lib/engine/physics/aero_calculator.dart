import 'dart:math' as math;
import '../../core/constants/physics_constants.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider_physiology.dart';

/// Pozycja aerodynamiczna kolarza na rowerze szosowym/czasowym.
enum RiderPosition {
  /// Chwyty klamkomanetek (hoods) – standardowa pozycja szosowa
  hoods,

  /// Dolny chwyt kierownicy typu baranek (drops) – zjazdy, ucieczki, sprint
  drops,

  /// Pozycja na lemondce (time trial / aero bars) – jazda indywidualna na czas
  timeTrial,

  /// Jazda na stojąco (standing) – strome wspinaczki, przyspieszenia, finisz
  standing,

  /// Przedramiona oparte na kierownicy (puppy paws / aero hoods)
  puppyPaws;

  /// Bazowy współczynnik oporu aerodynamicznego CdA [m^2] dla pozycji wzorcowego kolarza
  double get baseCdA {
    switch (this) {
      case RiderPosition.hoods:
        return PhysicsConstants.cdaHoods;
      case RiderPosition.drops:
        return PhysicsConstants.cdaDrops;
      case RiderPosition.timeTrial:
        return PhysicsConstants.cdaTimeTrial;
      case RiderPosition.standing:
        return PhysicsConstants.cdaStanding;
      case RiderPosition.puppyPaws:
        return PhysicsConstants.cdaPuppyPaws;
    }
  }

  /// Współczynnik oporu kształtu Cd (bezwymiarowy) względem wzorcowej powierzchni czołowej
  double get dragCoefficientCd {
    return baseCdA / AeroCalculator.referenceFrontalAreaM2;
  }
}

/// Szczegółowy wynik obliczeń parametrów aerodynamicznych.
class AeroCalculationResult {
  /// Wymagana moc mechaniczna do pokonania oporu powietrza [W]
  final double aeroPowerWatts;

  /// Siła oporu aerodynamicznego wzdłuż osi ruchu kolarza [N]
  final double dragForceNewtons;

  /// Gęstość powietrza na danej wysokości i temperaturze [kg/m^3]
  final double airDensityKgM3;

  /// Efektywny współczynnik oporu CdA kolarza i roweru po uwzględnieniu draftingu i kąta wiatru [m^2]
  final double effectiveCdA;

  /// Pozorna prędkość napływającego powietrza (apparent airspeed) [m/s]
  final double apparentWindSpeedMs;

  /// Pozorna prędkość napływającego powietrza w km/h
  double get apparentWindSpeedKmh => apparentWindSpeedMs * 3.6;

  /// Kąt pozornego wiatru (yaw angle) względem osi roweru [stopnie 0° - 90°]
  final double yawAngleDegrees;

  /// Składowa wiatru czołowego/przeciwnego wzdłuż osi drogi [m/s] (>0 = w twarz, <0 = w plecy)
  final double headwindComponentMs;

  /// Składowa boczna wiatru prostopadła do osi drogi [m/s]
  final double crosswindComponentMs;

  /// Zastosowany współczynnik redukcji oporu w draftingu (0.0 - 0.48)
  final double draftingReduction;

  /// Czy wiatr w plecy jest silniejszy od kolarza i pcha rower do przodu
  bool get isAssistingTailwind => headwindComponentMs < 0.0 && aeroPowerWatts < 0.0;

  const AeroCalculationResult({
    required this.aeroPowerWatts,
    required this.dragForceNewtons,
    required this.airDensityKgM3,
    required this.effectiveCdA,
    required this.apparentWindSpeedMs,
    required this.yawAngleDegrees,
    required this.headwindComponentMs,
    required this.crosswindComponentMs,
    required this.draftingReduction,
  });

  @override
  String toString() {
    return 'AeroCalculationResult(power: ${aeroPowerWatts.toStringAsFixed(1)}W, '
        'CdA: ${effectiveCdA.toStringAsFixed(4)}m², '
        'rho: ${airDensityKgM3.toStringAsFixed(3)}kg/m³, '
        'vApp: ${apparentWindSpeedKmh.toStringAsFixed(1)}km/h, '
        'yaw: ${yawAngleDegrees.toStringAsFixed(1)}°, '
        'drafting: ${(draftingReduction * 100.0).toStringAsFixed(0)}%)';
  }
}

/// Zaawansowany kalkulator aerodynamiczny kolarza i roweru.
///
/// Wylicza opór aerodynamiczny i wymaganą moc w watach na podstawie:
/// - Wzoru barometrycznego (wysokość n.p.m. oraz temperatura powietrza)
/// - Powierzchni czołowej kolarza i pozycji na rowerze
/// - Modyfikatora CdA roweru i kokpitu ([CompleteBike])
/// - Wektora wiatru (prędkość, azymut drogi i kierunek wiatru na segmencie)
/// - Redukcji oporu w tunelu aerodynamicznym / draftingu (0.0 do 0.48)
class AeroCalculator {
  AeroCalculator._();

  /// Wzorcowa powierzchnia czołowa przeciętnego kolarza szosowego [m^2]
  /// Odpowiada kolarzowi 70 kg / 178 cm (BSA ~1.859 m^2 * 0.268)
  static const double referenceFrontalAreaM2 = 0.498;

  /// Maksymalna fizjologiczna i geometryczna redukcja oporu w głębokim peletonie (48%)
  static const double maxDraftingReduction = 0.48;

  /// Minimalna fizyczna wartość CdA dla zestawu kolarz + rower czasowy [m^2]
  static const double minAllowedCdA = 0.150;

  /// Oblicza gęstość powietrza (rho) w kg/m^3 na podstawie wzoru barometrycznego
  /// z uwzględnieniem wysokości n.p.m. oraz temperatury otoczenia w stopniach Celsjusza.
  ///
  /// Parametry:
  /// - [altitudeMeters]: wysokość n.p.m. w metrach [m]
  /// - [temperatureCelsius]: temperatura powietrza w stopniach Celsjusza [°C]
  static double calculateAirDensity({
    required double altitudeMeters,
    required double temperatureCelsius,
  }) {
    final double h = math.max(0.0, altitudeMeters);
    final double tempKelvin = temperatureCelsius + 273.15;
    if (tempKelvin <= 50.0) {
      return PhysicsConstants.seaLevelAirDensity;
    }

    // Parametry standardowej atmosfery ISA (International Standard Atmosphere):
    // P0 = 101325 Pa (ciśnienie na poziomie morza)
    // T0 = 288.15 K (temperatura wzorcowa na poziomie morza, 15°C)
    // L = 0.0065 K/m (gradient spadku temperatury wraz z wysokością)
    // g = 9.80665 m/s^2, M = 0.0289644 kg/mol, R = 8.3144598 J/(mol*K)
    // Wykładnik potęgowy: (g * M) / (R * L) = 5.25588
    const double p0 = 101325.0;
    const double t0 = 288.15;
    const double exponent = 5.25588;
    const double lapseRate = PhysicsConstants.temperatureLapseRate; // 0.0065 K/m

    // Ciśnienie statyczne na wysokości h ze wzoru barometrycznego [Pa]:
    final double tempRatio = 1.0 - ((lapseRate * h) / t0);
    final double clampedTempRatio = math.max(0.05, tempRatio);
    final double pressurePa = p0 * math.pow(clampedTempRatio, exponent);

    // Gęstość z równania stanu gazu doskonałego: rho = P / (R_spec * T_real)
    // R_specific dla suchego powietrza = 287.05287 J/(kg * K)
    const double rSpecificAir = 287.05287;
    final double airDensity = pressurePa / (rSpecificAir * tempKelvin);

    return airDensity.clamp(0.40, 1.50);
  }

  /// Wylicza kąt natarcia wiatru względem kierunku jazdy kolarza [0° do 180°].
  ///
  /// - 0° = idealny wiatr czołowy (headwind - w twarz)
  /// - 90° = czysty wiatr boczny (crosswind)
  /// - 180° = idealny wiatr w plecy (tailwind)
  ///
  /// Parametry:
  /// - [windDirectionDegrees]: kierunek, SKĄD wieje wiatr (0-360°, 0° = Północ, 90° = Wschód)
  /// - [roadBearingDegrees]: azymut kierunku jazdy kolarza (0-360°, 0° = Północ)
  static double calculateRelativeWindAngle({
    required double windDirectionDegrees,
    required double roadBearingDegrees,
  }) {
    double diff = (windDirectionDegrees - roadBearingDegrees).abs() % 360.0;
    if (diff > 180.0) {
      diff = 360.0 - diff;
    }
    return diff;
  }

  /// Oblicza modyfikator CdA wynikający ze zjawiska "efektu żagla" (sailing effect)
  /// nowoczesnych kół stożkowych i ram aero przy kątach wiatru pozornego yaw [0° - 90°].
  static double calculateYawCdaFactor(double yawAngleRadians) {
    final double yawDeg = (yawAngleRadians * (180.0 / math.pi)).abs();

    if (yawDeg <= 12.0) {
      // Dla kątów do ~12° głębokie profile generują ciąg aerodynamiczny (spadek CdA o do ~4%)
      final double progress = math.sin((yawDeg / 12.0) * (math.pi / 2.0));
      return 1.0 - (0.04 * progress);
    } else if (yawDeg <= 20.0) {
      // Przejście od optymalnego przepływu do początku odrywania strugi
      final double t = (yawDeg - 12.0) / 8.0;
      return 0.96 + (t * 0.08); // od 0.96 do 1.04
    } else {
      // Przy wietrze mocno poprzecznym następuje pełne zerwanie strugi (wzrost oporu)
      final double excess = math.min(30.0, yawDeg - 20.0);
      return 1.04 + (excess * 0.005);
    }
  }

  /// Oblicza łączny efektywny współczynnik oporu aerodynamicznego CdA [m^2].
  ///
  /// Uwzględnia:
  /// - Powierzchnię czołową kolarza [riderFrontalAreaM2]
  /// - Pozycję aerodynamiczną [position]
  /// - Modyfikator roweru i kokpitu ([bike] lub [bikeCdaModifier])
  /// - Współczynnik draftingu ([draftingReduction]: 0.0 do 0.48)
  /// - Opcjonalny współczynnik kąta pozornego wiatru ([yawAngleRadians])
  static double calculateEffectiveCdA({
    required double riderFrontalAreaM2,
    required RiderPosition position,
    CompleteBike? bike,
    double bikeCdaModifier = 0.0,
    double draftingReduction = 0.0,
    double yawAngleRadians = 0.0,
  }) {
    // 1. Skalowanie bazowego CdA pozycji proporcjonalnie do powierzchni czołowej kolarza
    final double safeFrontalArea = math.max(0.20, riderFrontalAreaM2);
    final double areaScaling = safeFrontalArea / referenceFrontalAreaM2;
    final double riderCdA = position.baseCdA * areaScaling;

    // 2. Uwzględnienie modyfikatora roweru (rama, koła, kokpit, klamki)
    final double bikeMod = bike != null ? bike.totalCdaModifier : bikeCdaModifier;
    final double unshieldedCdA = math.max(minAllowedCdA, riderCdA + bikeMod);

    // 3. Wpływ kąta wiatru pozornego (yaw angle)
    final double yawFactor = calculateYawCdaFactor(yawAngleRadians);

    // 4. Współczynnik redukcji oporu w draftingu (0.0 = brak draftingu, 0.48 = maks. w peletonie)
    final double clampedReduction = draftingReduction.clamp(0.0, maxDraftingReduction);
    final double draftingMultiplier = 1.0 - clampedReduction;

    return unshieldedCdA * yawFactor * draftingMultiplier;
  }

  /// Główna metoda wyliczająca dokładną moc oporu aerodynamicznego kolarza w watach [W].
  ///
  /// Formuła opiera się na równaniach mechaniki ruchu rowerowego Martina (1998)
  /// oraz aerodynamiki płynów:
  /// P_aero = F_drag_forward * v_rider
  /// F_drag_forward = 0.5 * rho * CdA * v_app * v_ax
  ///
  /// Parametry:
  /// - [altitudeMeters]: wysokość n.p.m. trasy [m]
  /// - [temperatureCelsius]: temperatura otoczenia [°C]
  /// - [riderFrontalAreaM2]: powierzchnia rzutu czołowego kolarza [m^2] (np. z `RiderPhysiology.frontalAreaM2`)
  /// - [riderPosition]: pozycja kolarza (chwyty, dolny chwyt, lemondka, stojąc)
  /// - [riderSpeedMs]: prędkość kolarza względem podłoża [m/s]
  /// - [bike]: kompletny rower wyposażony w koła i ramę (opcjonalny, alternatywnie [bikeCdaModifier])
  /// - [bikeCdaModifier]: bezpośredni modyfikator CdA roweru [m^2] (gdy nie przekazano obiektu [bike])
  /// - [windSpeedMs]: prędkość wiatru względem ziemi [m/s]
  /// - [relativeWindAngleDegrees]: kąt wiatru względem kierunku jazdy [0°-180°] (0° = w twarz, 180° = w plecy)
  /// - [windDirectionDegrees]: kierunek skąd wieje wiatr [0°-360°] (używany jeśli nie podano [relativeWindAngleDegrees])
  /// - [roadBearingDegrees]: azymut drogi [0°-360°] (używany jeśli nie podano [relativeWindAngleDegrees])
  /// - [draftingReduction]: stopień redukcji oporu w jeździe za kimś (0.0 = solo, do 0.48 = w peletonie)
  ///
  /// Zwraca:
  /// Dokładną wartość mocy oporu aerodynamicznego w watach (`aeroPowerWatts`).
  static double calculateAeroPowerWatts({
    required double altitudeMeters,
    required double temperatureCelsius,
    required double riderFrontalAreaM2,
    required RiderPosition riderPosition,
    required double riderSpeedMs,
    CompleteBike? bike,
    double bikeCdaModifier = 0.0,
    double windSpeedMs = 0.0,
    double? relativeWindAngleDegrees,
    double? windDirectionDegrees,
    double? roadBearingDegrees,
    double draftingReduction = 0.0,
  }) {
    if (riderSpeedMs <= 0.0) {
      return 0.0;
    }

    final result = calculateDetailed(
      altitudeMeters: altitudeMeters,
      temperatureCelsius: temperatureCelsius,
      riderFrontalAreaM2: riderFrontalAreaM2,
      riderPosition: riderPosition,
      riderSpeedMs: riderSpeedMs,
      bike: bike,
      bikeCdaModifier: bikeCdaModifier,
      windSpeedMs: windSpeedMs,
      relativeWindAngleDegrees: relativeWindAngleDegrees,
      windDirectionDegrees: windDirectionDegrees,
      roadBearingDegrees: roadBearingDegrees,
      draftingReduction: draftingReduction,
    );

    return result.aeroPowerWatts;
  }

  /// Szczegółowa analiza aerodynamiczna zwracająca pełen zestaw wektorów i sił.
  static AeroCalculationResult calculateDetailed({
    required double altitudeMeters,
    required double temperatureCelsius,
    required double riderFrontalAreaM2,
    required RiderPosition riderPosition,
    required double riderSpeedMs,
    CompleteBike? bike,
    double bikeCdaModifier = 0.0,
    double windSpeedMs = 0.0,
    double? relativeWindAngleDegrees,
    double? windDirectionDegrees,
    double? roadBearingDegrees,
    double draftingReduction = 0.0,
  }) {
    // 1. Obliczenie gęstości powietrza na danej wysokości i temperaturze
    final double airDensity = calculateAirDensity(
      altitudeMeters: altitudeMeters,
      temperatureCelsius: temperatureCelsius,
    );

    if (riderSpeedMs <= 0.0) {
      final double staticCdA = calculateEffectiveCdA(
        riderFrontalAreaM2: riderFrontalAreaM2,
        position: riderPosition,
        bike: bike,
        bikeCdaModifier: bikeCdaModifier,
        draftingReduction: draftingReduction,
      );

      return AeroCalculationResult(
        aeroPowerWatts: 0.0,
        dragForceNewtons: 0.0,
        airDensityKgM3: airDensity,
        effectiveCdA: staticCdA,
        apparentWindSpeedMs: windSpeedMs,
        yawAngleDegrees: 0.0,
        headwindComponentMs: 0.0,
        crosswindComponentMs: windSpeedMs,
        draftingReduction: draftingReduction.clamp(0.0, maxDraftingReduction),
      );
    }

    // 2. Wyznaczenie kąta natarcia wiatru (beta: 0° = czołowy, 180° = w plecy)
    double betaDeg = 0.0;
    if (relativeWindAngleDegrees != null) {
      betaDeg = relativeWindAngleDegrees.clamp(0.0, 180.0);
    } else if (windDirectionDegrees != null && roadBearingDegrees != null) {
      betaDeg = calculateRelativeWindAngle(
        windDirectionDegrees: windDirectionDegrees,
        roadBearingDegrees: roadBearingDegrees,
      );
    }

    final double betaRad = betaDeg * (math.pi / 180.0);

    // 3. Rozkład wektora wiatru na osie kolarza:
    // vAx: składowa wzdłużna napływu powietrza na kolarza (prędkość własna + wiatr w twarz)
    // vAy: składowa boczna (crosswind)
    final double headwindComponent = windSpeedMs * math.cos(betaRad);
    final double crosswindComponent = windSpeedMs * math.sin(betaRad);

    final double vAx = riderSpeedMs + headwindComponent;
    final double vAy = crosswindComponent;

    // Prędkość wypadkowa napływu strugi (apparent airspeed)
    final double vApp = math.sqrt((vAx * vAx) + (vAy * vAy));

    // Kąt wiatru pozornego yaw względem kolarza [radiany i stopnie]
    final double yawRad = vApp > 0.001 ? math.atan2(vAy.abs(), vAx.abs()) : 0.0;
    final double yawDeg = yawRad * (180.0 / math.pi);

    // 4. Efektywny współczynnik oporu CdA
    final double clampedDrafting = draftingReduction.clamp(0.0, maxDraftingReduction);
    final double effectiveCdA = calculateEffectiveCdA(
      riderFrontalAreaM2: riderFrontalAreaM2,
      position: riderPosition,
      bike: bike,
      bikeCdaModifier: bikeCdaModifier,
      draftingReduction: clampedDrafting,
      yawAngleRadians: yawRad,
    );

    // 5. Obliczenie siły oporu aerodynamicznego wzdłuż kierunku jazdy [N]
    // F_drag = 0.5 * rho * CdA * v_app^2
    // F_drag_forward = F_drag * cos(yaw) = 0.5 * rho * CdA * v_app * v_ax
    final double dragForceForwardNewtons = 0.5 * airDensity * effectiveCdA * vApp * vAx;

    // 6. Moc aerodynamiczna w watach [W]: P_aero = F_drag_forward * v_rider
    final double aeroPowerWatts = dragForceForwardNewtons * riderSpeedMs;

    return AeroCalculationResult(
      aeroPowerWatts: aeroPowerWatts,
      dragForceNewtons: dragForceForwardNewtons,
      airDensityKgM3: airDensity,
      effectiveCdA: effectiveCdA,
      apparentWindSpeedMs: vApp,
      yawAngleDegrees: yawDeg,
      headwindComponentMs: headwindComponent,
      crosswindComponentMs: crosswindComponent,
      draftingReduction: clampedDrafting,
    );
  }

  /// Wygodna metoda obliczeniowa integrująca pełne modele symulacji:
  /// [RiderPhysiology], [CompleteBike] oraz odcinek trasy [StageSegment].
  static double calculateForSegment({
    required RiderPhysiology riderPhysiology,
    required CompleteBike bike,
    required StageSegment segment,
    required RiderPosition position,
    required double riderSpeedMs,
    required double temperatureCelsius,
    required double windSpeedKmh,
    double draftingReduction = 0.0,
  }) {
    final double windSpeedMs = windSpeedKmh / 3.6;

    return calculateAeroPowerWatts(
      altitudeMeters: (segment.startElevationM + segment.endElevationM) / 2.0,
      temperatureCelsius: temperatureCelsius,
      riderFrontalAreaM2: riderPhysiology.frontalAreaM2,
      riderPosition: position,
      riderSpeedMs: riderSpeedMs,
      bike: bike,
      windSpeedMs: windSpeedMs,
      windDirectionDegrees: segment.windDirectionDegrees,
      roadBearingDegrees: segment.roadBearingDegrees,
      draftingReduction: draftingReduction,
    );
  }
}

