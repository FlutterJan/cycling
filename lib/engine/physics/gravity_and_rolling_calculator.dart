import 'dart:math' as math;
import '../../core/constants/physics_constants.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/equipment/tire_model.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider_physiology.dart';

/// Szczegółowy bilans składowych mocy mechanicznej kolarza na drodze.
class PowerBreakdownResult {
  /// Moc grawitacyjna wspinaczki lub zjazdu [W] (>0 na podjeździe, <0 na zjeździe)
  final double gravityWatts;

  /// Moc pokonania oporów toczenia opon po nawierzchni [W] (zawsze >= 0)
  final double rollingResistanceWatts;

  /// Moc oporu aerodynamicznego [W] (opcjonalna, 0.0 jeśli pominięta)
  final double aeroWatts;

  /// Całkowita moc netto przekazywana na koło/asfalt [W] (suma oporów na drodze)
  double get roadPowerWatts => gravityWatts + rollingResistanceWatts + aeroWatts;

  /// Straty tarcia napędu (łańcuch, kaseta, wózki, łożyska) [W]
  final double drivetrainLossWatts;

  /// Całkowita moc mechaniczna generowana przez nogi kolarza na korbie [W]
  final double totalLegPowerWatts;

  /// Całkowita masa układu (kolarz + rower + bidony/wyposażenie) [kg]
  final double totalMassKg;

  /// Siła nacisku prostopadła do nawierzchni (siła normalna) [N]
  final double normalForceNewtons;

  /// Siła grawitacji wzdłuż stoku drogi [N]
  final double gravityForceNewtons;

  /// Siła oporów toczenia opon [N]
  final double rollingForceNewtons;

  /// Zastosowany efektywny współczynnik oporów toczenia Crr
  final double effectiveCrr;

  /// Kąt nachylenia drogi względem poziomu w radianach
  final double slopeAngleRadians;

  /// Kąt nachylenia drogi w stopniach
  double get slopeAngleDegrees => slopeAngleRadians * (180.0 / math.pi);

  const PowerBreakdownResult({
    required this.gravityWatts,
    required this.rollingResistanceWatts,
    required this.aeroWatts,
    required this.drivetrainLossWatts,
    required this.totalLegPowerWatts,
    required this.totalMassKg,
    required this.normalForceNewtons,
    required this.gravityForceNewtons,
    required this.rollingForceNewtons,
    required this.effectiveCrr,
    required this.slopeAngleRadians,
  });

  @override
  String toString() {
    return 'PowerBreakdownResult(Legs: ${totalLegPowerWatts.toStringAsFixed(1)}W '
        '[Grav: ${gravityWatts.toStringAsFixed(1)}W, '
        'Roll: ${rollingResistanceWatts.toStringAsFixed(1)}W, '
        'Aero: ${aeroWatts.toStringAsFixed(1)}W, '
        'DrivetrainLoss: ${drivetrainLossWatts.toStringAsFixed(1)}W], '
        'Mass: ${totalMassKg.toStringAsFixed(1)}kg, '
        'Crr: ${effectiveCrr.toStringAsFixed(4)})';
  }
}

/// Kalkulator fizyki kolarskiej obliczający składowe mocy:
/// grawitacyjną, oporów toczenia oraz straty mechaniczne napędu.
class GravityAndRollingCalculator {
  GravityAndRollingCalculator._();

  /// Domyślna masa dwóch pełnych bidonów (2x 500ml wody + koszyki/bidony) [kg]
  static const double defaultBottlesWeightKg = 1.0;

  /// Oblicza całkowitą masę układu kolarz + rower + bidony [kg].
  static double calculateTotalMassKg({
    required double riderWeightKg,
    required double bikeWeightKg,
    double bottlesWeightKg = defaultBottlesWeightKg,
  }) {
    return math.max(10.0, riderWeightKg + bikeWeightKg + bottlesWeightKg);
  }

  /// Wyznacza efektywny współczynnik oporów toczenia Crr
  /// na podstawie modelu opony ([TireModel]) oraz nawierzchni segmentu ([SegmentSurfaceType]).
  ///
  /// Uwzględnia:
  /// - Bazowy opór opony w testach bębnowych/asfaltowych
  /// - Chropowatość nawierzchni (asfalt gładki, chropowaty, szuter, bruki 1-5 gwiazdek)
  /// - Korzyści technologii bezdętkowej (tubeless) na nierównościach i brukach
  /// - Szerokość opony (szersze opony 28-32mm lepiej tłumią mikrodrgania na bruku)
  static double calculateEffectiveCrr({
    required TireModel tire,
    required SegmentSurfaceType surfaceType,
  }) {
    // Współczynniki względnej chropowatości nawierzchni względem gładkiego asfaltu wzorcowego
    double surfaceMultiplier;
    bool isRoughSurface = false;

    switch (surfaceType) {
      case SegmentSurfaceType.smoothAsphalt:
        surfaceMultiplier = 1.0;
        break;
      case SegmentSurfaceType.concrete:
        surfaceMultiplier = 1.45;
        break;
      case SegmentSurfaceType.roughAsphalt:
        surfaceMultiplier = 1.67;
        isRoughSurface = true;
        break;
      case SegmentSurfaceType.gravelStrade:
        surfaceMultiplier = 2.73;
        isRoughSurface = true;
        break;
      case SegmentSurfaceType.cobblestonesSector1:
        surfaceMultiplier = 2.42;
        isRoughSurface = true;
        break;
      case SegmentSurfaceType.cobblestonesSector2:
        surfaceMultiplier = 3.03;
        isRoughSurface = true;
        break;
      case SegmentSurfaceType.cobblestonesSector3:
        surfaceMultiplier = 3.79;
        isRoughSurface = true;
        break;
      case SegmentSurfaceType.cobblestonesSector4:
        surfaceMultiplier = 4.55;
        isRoughSurface = true;
        break;
      case SegmentSurfaceType.cobblestonesSector5:
        surfaceMultiplier = 5.61;
        isRoughSurface = true;
        break;
    }

    // Na nierównych nawierzchniach opony Tubeless (niższe ciśnienie bez ryzyka snake-bite)
    // redukują straty wibracyjne o ~12%
    final double tubelessBenefit = (isRoughSurface && tire.isTubeless) ? 0.88 : 1.0;

    // Szersza opona (baza 28mm) redukuje impedancję na bruku i szutrze
    double widthModifier = 1.0;
    if (isRoughSurface) {
      widthModifier = 1.0 - ((tire.widthMm - 28) * 0.012);
      widthModifier = widthModifier.clamp(0.85, 1.15);
    }

    final double effectiveCrr = tire.rollingResistanceCrr *
        surfaceMultiplier *
        tubelessBenefit *
        widthModifier;

    return effectiveCrr.clamp(0.0025, 0.0350);
  }

  /// Pomocnicza funkcja normalizująca nachylenie do formatu ułamkowego (np. 0.08 dla 8%).
  static double _resolveGradientFraction({
    double? gradientFraction,
    double? gradientPercent,
  }) {
    if (gradientFraction != null) {
      return gradientFraction;
    }
    if (gradientPercent != null) {
      return gradientPercent / 100.0;
    }
    return 0.0;
  }

  /// 1. Oblicza moc grawitacyjną w watach [W]:
  /// Formuła: masa_całkowita (kolarz + rower + bidony) * g * sin(arctan(gradient)) * prędkość (m/s).
  ///
  /// Parametry:
  /// - [totalMassKg]: masa całkowita kolarza, roweru i bidonów [kg]
  /// - [speedMs]: prędkość kolarza wzdłuż drogi [m/s]
  /// - [gradientFraction]: nachylenie drogi w ułamku dziesiętnym (np. 0.08 dla 8% wspinaczki, -0.05 dla zjazdu)
  /// - [gradientPercent]: alternatywnie nachylenie w procentach (np. 8.0 dla 8%)
  ///
  /// Zwraca:
  /// Moc grawitacji w watach (wartość dodatnia na podjeździe, ujemna na zjeździe).
  static double calculateGravityWatts({
    required double totalMassKg,
    required double speedMs,
    double? gradientFraction,
    double? gradientPercent,
  }) {
    if (speedMs <= 0.0 || totalMassKg <= 0.0) {
      return 0.0;
    }

    final double gFraction = _resolveGradientFraction(
      gradientFraction: gradientFraction,
      gradientPercent: gradientPercent,
    );

    // Kąt drogi względem poziomu: theta = arctan(gradient)
    final double slopeAngleRad = math.atan(gFraction);
    final double sinTheta = math.sin(slopeAngleRad);

    // P_gravity = m * g * sin(arctan(gradient)) * v
    return totalMassKg * PhysicsConstants.gravity * sinTheta * speedMs;
  }

  /// 2. Oblicza moc oporów toczenia w watach [W]:
  /// Formuła: masa_całkowita * g * cos(arctan(gradient)) * Crr * prędkość (m/s).
  ///
  /// Parametry:
  /// - [totalMassKg]: masa całkowita kolarza, roweru i wyposażenia [kg]
  /// - [speedMs]: prędkość kolarza [m/s]
  /// - [crr]: bezpośredni współczynnik oporów toczenia (opcjonalny, jeśli podano [tire] i [surfaceType])
  /// - [tire]: model opony ([TireModel])
  /// - [surfaceType]: typ nawierzchni odcinka ([SegmentSurfaceType])
  /// - [gradientFraction]: nachylenie drogi w ułamku (np. 0.05 dla 5%)
  /// - [gradientPercent]: nachylenie drogi w procentach
  ///
  /// Zwraca:
  /// Moc oporów toczenia w watach [W] (zawsze >= 0 dla v > 0).
  static double calculateRollingResistanceWatts({
    required double totalMassKg,
    required double speedMs,
    double? crr,
    TireModel? tire,
    SegmentSurfaceType? surfaceType,
    double? gradientFraction,
    double? gradientPercent,
  }) {
    if (speedMs <= 0.0 || totalMassKg <= 0.0) {
      return 0.0;
    }

    // Wyznaczenie współczynnika Crr
    double resolvedCrr;
    if (crr != null) {
      resolvedCrr = crr;
    } else if (tire != null && surfaceType != null) {
      resolvedCrr = calculateEffectiveCrr(tire: tire, surfaceType: surfaceType);
    } else if (tire != null) {
      resolvedCrr = tire.rollingResistanceCrr;
    } else {
      resolvedCrr = PhysicsConstants.crrStandardAsphalt;
    }

    final double gFraction = _resolveGradientFraction(
      gradientFraction: gradientFraction,
      gradientPercent: gradientPercent,
    );

    // Kąt drogi: theta = arctan(gradient)
    final double slopeAngleRad = math.atan(gFraction);
    final double cosTheta = math.cos(slopeAngleRad);

    // P_rolling = m * g * cos(arctan(gradient)) * Crr * v
    return totalMassKg * PhysicsConstants.gravity * cosTheta * resolvedCrr * speedMs;
  }

  /// Łączy moc grawitacji i oporów toczenia (oraz opcjonalną moc aerodynamiczną)
  /// ze stratami mechanicznymi napędu kolarza ([drivetrainLoss]).
  ///
  /// Formuła:
  /// P_road = P_gravity + P_rolling + P_aero
  /// P_legs = P_road / (1.0 - drivetrainLoss)
  ///
  /// Parametry:
  /// - [gravityWatts]: moc grawitacji wyliczona z [calculateGravityWatts]
  /// - [rollingResistanceWatts]: moc oporów toczenia wyliczona z [calculateRollingResistanceWatts]
  /// - [aeroWatts]: moc aerodynamiczna pokonania oporu powietrza (domyślnie 0.0)
  /// - [drivetrainLoss]: ułamek strat napędu (np. 0.020 dla łańcucha woskowanego, 0.028 standardowego)
  ///
  /// Zwraca:
  /// Wymaganą moc wyjściową z nóg kolarza na korbie w watach [W].
  /// Jeśli opory na drodze są ujemne (np. stromy zjazd, gdzie grawitacja przewyższa opory),
  /// zwracane jest 0.0 W (jazda z wybiegu / coasting).
  static double combineWithDrivetrainLoss({
    required double gravityWatts,
    required double rollingResistanceWatts,
    double aeroWatts = 0.0,
    double drivetrainLoss = PhysicsConstants.drivetrainLossStandard,
  }) {
    final double netRoadPowerWatts = gravityWatts + rollingResistanceWatts + aeroWatts;

    // Na stromym zjeździe grawitacja pcha kolarza do przodu; kolarz nie musi pedałować
    if (netRoadPowerWatts <= 0.0) {
      return 0.0;
    }

    final double clampedLoss = drivetrainLoss.clamp(0.0, 0.20);
    final double mechanicalEfficiency = 1.0 - clampedLoss;

    if (mechanicalEfficiency <= 0.0) {
      return netRoadPowerWatts;
    }

    return netRoadPowerWatts / mechanicalEfficiency;
  }

  /// Szczegółowa analiza fizyczna generująca pełny obiekt [PowerBreakdownResult].
  static PowerBreakdownResult calculateDetailed({
    required double totalMassKg,
    required double speedMs,
    required double gradientPercent,
    required double crr,
    double aeroWatts = 0.0,
    double drivetrainLoss = PhysicsConstants.drivetrainLossStandard,
  }) {
    final double gradientFraction = gradientPercent / 100.0;
    final double slopeAngleRad = math.atan(gradientFraction);
    final double sinTheta = math.sin(slopeAngleRad);
    final double cosTheta = math.cos(slopeAngleRad);

    final double normalForce = totalMassKg * PhysicsConstants.gravity * cosTheta;
    final double gravityForce = totalMassKg * PhysicsConstants.gravity * sinTheta;
    final double rollingForce = normalForce * crr;

    final double gravityWatts = gravityForce * speedMs;
    final double rollingWatts = rollingForce * speedMs;

    final double totalLegPower = combineWithDrivetrainLoss(
      gravityWatts: gravityWatts,
      rollingResistanceWatts: rollingWatts,
      aeroWatts: aeroWatts,
      drivetrainLoss: drivetrainLoss,
    );

    final double netRoadPower = gravityWatts + rollingWatts + aeroWatts;
    final double drivetrainLossWatts = totalLegPower > 0.0
        ? math.max(0.0, totalLegPower - netRoadPower)
        : 0.0;

    return PowerBreakdownResult(
      gravityWatts: gravityWatts,
      rollingResistanceWatts: rollingWatts,
      aeroWatts: aeroWatts,
      drivetrainLossWatts: drivetrainLossWatts,
      totalLegPowerWatts: totalLegPower,
      totalMassKg: totalMassKg,
      normalForceNewtons: normalForce,
      gravityForceNewtons: gravityForce,
      rollingForceNewtons: rollingForce,
      effectiveCrr: crr,
      slopeAngleRadians: slopeAngleRad,
    );
  }

  /// Wygodna metoda integrująca pełne modele symulacji:
  /// [RiderPhysiology], [CompleteBike], [StageSegment] oraz prędkość.
  static PowerBreakdownResult calculateForSegment({
    required RiderPhysiology riderPhysiology,
    required CompleteBike bike,
    required StageSegment segment,
    required double speedMs,
    double bottlesWeightKg = defaultBottlesWeightKg,
    double aeroWatts = 0.0,
  }) {
    final double totalMass = calculateTotalMassKg(
      riderWeightKg: riderPhysiology.weightKg,
      bikeWeightKg: bike.totalWeightKg,
      bottlesWeightKg: bottlesWeightKg,
    );

    final double effectiveCrr = calculateEffectiveCrr(
      tire: bike.tire,
      surfaceType: segment.surfaceType,
    );

    // Sprawność napędu z grupy osprzętu (GroupsetModel)
    final double drivetrainLoss = 1.0 - bike.groupset.mechanicalEfficiency;

    return calculateDetailed(
      totalMassKg: totalMass,
      speedMs: speedMs,
      gradientPercent: segment.gradientPercent,
      crr: effectiveCrr,
      aeroWatts: aeroWatts,
      drivetrainLoss: drivetrainLoss,
    );
  }
}

