import 'dart:math' as math;

class PhysicsConstants {
  PhysicsConstants._();

  // Przyspieszenie ziemskie (Standard gravity) [m/s^2]
  static const double gravity = 9.80665;

  // Bazowa gęstość powietrza na poziomie morza (15°C, 1013.25 hPa) [kg/m^3]
  static const double seaLevelAirDensity = 1.225;

  // Współczynnik skali wysokości atmosfery dla modelu wykładniczego [m]
  // Gęstość spada zgodnie z relacją: rho = rho0 * exp(-h / scaleHeight)
  static const double atmosphericScaleHeight = 8500.0;

  // Pionowy gradient temperatury atmosfery wzorcowej (ISA temperature lapse rate) [K/m]
  static const double temperatureLapseRate = 0.0065;

  // Straty napędu (Drivetrain friction losses jako ułamek mocy całkowitej)
  static const double drivetrainLossWaxed = 0.020; // Woskowany łańcuch / race day treatment (2.0%)
  static const double drivetrainLossStandard = 0.028; // Czysty, standardowy smar syntetyczny (2.8%)
  static const double drivetrainLossDirty = 0.035; // Brudny smar / zużyty napęd (3.5%)

  // Bazowe współczynniki oporu aerodynamicznego CdA [m^2] według pozycji kolarza
  static const double cdaHoods = 0.325; // Chwyty (ergopowery) – pozycja bazowa na płaskim
  static const double cdaDrops = 0.295; // Dolny chwyt kierownicy baranek – ucieczki, zjazdy
  static const double cdaTimeTrial = 0.225; // Lemondka (jazda indywidualna na czas / aero TT bars)
  static const double cdaPuppyPaws = 0.265; // Przedramiona na kierownicy (aero hoods)
  static const double cdaStanding = 0.415; // Jazda na stojąco / podjazdy o dużym nachyleniu

  // Współczynniki oporów toczenia opon (Crr)
  static const double crrSmoothAsphalt = 0.0033;
  static const double crrStandardAsphalt = 0.0045;
  static const double crrRoughAsphalt = 0.0065;
  static const double crrCobblestones = 0.0125;
  static const double crrGravel = 0.0085;

  // Współczynniki redukcji oporu powietrza w tunelu aero (Drafting Factors)
  // Wartość mnożona przez opór powietrza (0.60 oznacza 40% redukcji oporu)
  static const double draftingDirectBehind = 0.62; // Tuż za kołem poprzedzającego kolarza
  static const double draftingDeepPeloton = 0.38; // W środku peletonu
  static const double draftingSideEchelon = 0.78; // Na wachlarzu przy wietrze bocznym

  /// Oblicza gęstość powietrza (rho) w kg/m^3 dla danej wysokości n.p.m. w metrach.
  static double getAirDensityAtAltitude(double altitudeMeters) {
    if (altitudeMeters <= 0.0) {
      return seaLevelAirDensity;
    }
    return seaLevelAirDensity * math.exp(-altitudeMeters / atmosphericScaleHeight);
  }

  /// Zwraca współczynnik sprawności mechanicznej napędu (1.0 - strata).
  static double getMechanicalEfficiency({bool isWaxed = false, bool isDirty = false}) {
    if (isDirty) {
      return 1.0 - drivetrainLossDirty;
    }
    if (isWaxed) {
      return 1.0 - drivetrainLossWaxed;
    }
    return 1.0 - drivetrainLossStandard;
  }
}
