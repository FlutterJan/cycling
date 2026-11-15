import 'dart:math' as math;
import 'bike_fit_configuration.dart';
import 'equipment_wear_and_maintenance.dart';
import 'frame_model.dart';
import 'wheelset_model.dart';
import 'groupset_model.dart';
import 'tire_model.dart';

class CompleteBike {
  static const double uciMinimumWeightLimitKg = 6.80;
  static const double peripheralComponentsWeightKg = 1.25; // Kokpit, sztyca, siodełko, pedały, koszyki na bidony

  final String id;
  final String name;
  final FrameModel frame;
  final WheelsetModel wheelset;
  final GroupsetModel groupset;
  final TireModel tire;

  // Parametry bike fittingu
  final int cockpitWidthMm; // Szerokość kierownicy w mm (np. 360, 380, 400, 420)
  final double hoodInwardTiltDegrees; // Kąt podgięcia klamkomanetek do wewnątrz (np. 0.0° - 14.0° wg regulacji UCI)
  final bool slammedStem; // Mostek opuszczony bezpośrednio na główkę ramy (brak podkładek spacerów)

  // Stan techniczny, zużycie i serwis sprzętu
  final EquipmentWearAndMaintenance? wearAndMaintenance;

  const CompleteBike({
    required this.id,
    required this.name,
    required this.frame,
    required this.wheelset,
    required this.groupset,
    required this.tire,
    required this.cockpitWidthMm,
    required this.hoodInwardTiltDegrees,
    required this.slammedStem,
    this.wearAndMaintenance,
  });

  /// Masa roweru bez balastu doważającego [kg]
  double get rawWeightKg {
    return frame.weightKg +
        wheelset.weightKg +
        groupset.weightKg +
        (tire.weightKg * 2.0) +
        peripheralComponentsWeightKg;
  }

  /// Czy rower wymaga balastu doważającego do limitu UCI 6.80 kg
  bool get hasUciBallast => rawWeightKg < uciMinimumWeightLimitKg;

  /// Masa balastu doważającego w gramach
  int get ballastGrams {
    if (!hasUciBallast) return 0;
    return ((uciMinimumWeightLimitKg - rawWeightKg) * 1000.0).round();
  }

  /// Całkowita masa startowa roweru w kilogramach (uwzględnia przepisowy limit UCI)
  double get totalWeightKg {
    return math.max(uciMinimumWeightLimitKg, rawWeightKg);
  }

  /// Łączny modyfikator współczynnika oporu czołowego CdA [m^2]
  /// Sumuje aero ramy, kół oraz geometrii bike fittingu (szerokość kierownicy, kąt klamek, mostek)
  double get totalCdaModifier {
    // Węższy kokpit redukuje powierzchnię czołową kolarza (baza 400mm)
    final cockpitAeroBonus = (cockpitWidthMm - 400) * 0.00025;

    // Podgięte do wewnątrz klamkomanetki zwężają ramiona i barki kolarza
    final hoodTiltAeroBonus = -(hoodInwardTiltDegrees.clamp(0.0, 15.0) / 15.0) * 0.004;

    // Slammed stem obniża pozycję tułowia
    final slammedStemBonus = slammedStem ? -0.0055 : 0.0;

    return frame.aeroCdaModifier +
        wheelset.aeroCdaModifier +
        cockpitAeroBonus +
        hoodTiltAeroBonus +
        slammedStemBonus;
  }

  /// Współczynnik oporu toczenia Crr
  double get totalCrr {
    return tire.rollingResistanceCrr;
  }

  /// Wskaźnik ryzyka defektu / przebicia opony (1.0 = baza, niżej = bezpieczniej, wyżej = większe ryzyko)
  double get punctureRiskFactor {
    final baseResistance = tire.punctureResistanceIndex.clamp(0.5, 5.0);
    final tubelessProtection = tire.isTubeless ? 1.45 : 1.0;
    return 1.0 / (baseResistance * tubelessProtection);
  }

  /// Szczegółowy profil pozycji bike fittingu kolarza
  BikeFitConfiguration get bikeFit => BikeFitConfiguration(
        saddleHeightMm: 745.0,
        saddleSetbackMm: 58.0,
        saddleTiltDegrees: -1.5,
        cockpitWidthMm: cockpitWidthMm,
        stemLengthMm: 120,
        spacersStackMm: slammedStem ? 0 : 15,
        hoodInwardTiltDegrees: hoodInwardTiltDegrees,
        crankArmLengthMm: 172.5,
        cleatOffsetMm: -3.0,
      );

  /// Stan techniczny, zużycie i serwis roweru
  EquipmentWearAndMaintenance get wear =>
      wearAndMaintenance ?? EquipmentWearAndMaintenance.brandNew();

  /// Zwraca zaktualizowany egzemplarz roweru z nowym stanem zużycia podzespołów
  CompleteBike applyWear(EquipmentWearAndMaintenance newWear) {
    return copyWith(wearAndMaintenance: newWear);
  }

  /// Zwraca zaktualizowany egzemplarz roweru z zastosowaną konfiguracją fittingu
  CompleteBike applyBikeFit(BikeFitConfiguration fit) {
    return copyWith(
      cockpitWidthMm: fit.cockpitWidthMm,
      hoodInwardTiltDegrees: fit.hoodInwardTiltDegrees,
      slammedStem: fit.isSlammedStem,
    );
  }

  CompleteBike copyWith({
    String? id,
    String? name,
    FrameModel? frame,
    WheelsetModel? wheelset,
    GroupsetModel? groupset,
    TireModel? tire,
    int? cockpitWidthMm,
    double? hoodInwardTiltDegrees,
    bool? slammedStem,
    EquipmentWearAndMaintenance? wearAndMaintenance,
  }) {
    return CompleteBike(
      id: id ?? this.id,
      name: name ?? this.name,
      frame: frame ?? this.frame,
      wheelset: wheelset ?? this.wheelset,
      groupset: groupset ?? this.groupset,
      tire: tire ?? this.tire,
      cockpitWidthMm: cockpitWidthMm ?? this.cockpitWidthMm,
      hoodInwardTiltDegrees: hoodInwardTiltDegrees ?? this.hoodInwardTiltDegrees,
      slammedStem: slammedStem ?? this.slammedStem,
      wearAndMaintenance: wearAndMaintenance ?? this.wearAndMaintenance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'frame': frame.toJson(),
      'wheelset': wheelset.toJson(),
      'groupset': groupset.toJson(),
      'tire': tire.toJson(),
      'cockpitWidthMm': cockpitWidthMm,
      'hoodInwardTiltDegrees': hoodInwardTiltDegrees,
      'slammedStem': slammedStem,
      if (wearAndMaintenance != null)
        'wearAndMaintenance': wearAndMaintenance!.toJson(),
    };
  }

  factory CompleteBike.fromJson(Map<String, dynamic> json) {
    return CompleteBike(
      id: json['id'] as String,
      name: json['name'] as String,
      frame: FrameModel.fromJson(json['frame'] as Map<String, dynamic>),
      wheelset: WheelsetModel.fromJson(json['wheelset'] as Map<String, dynamic>),
      groupset: GroupsetModel.fromJson(json['groupset'] as Map<String, dynamic>),
      tire: TireModel.fromJson(json['tire'] as Map<String, dynamic>),
      cockpitWidthMm: (json['cockpitWidthMm'] as num).toInt(),
      hoodInwardTiltDegrees: (json['hoodInwardTiltDegrees'] as num).toDouble(),
      slammedStem: json['slammedStem'] as bool,
      wearAndMaintenance: json['wearAndMaintenance'] != null
          ? EquipmentWearAndMaintenance.fromJson(
              json['wearAndMaintenance'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompleteBike && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CompleteBike($name, mass: ${totalWeightKg.toStringAsFixed(2)}kg (ballast: ${ballastGrams}g), CdA mod: ${totalCdaModifier.toStringAsFixed(4)})';
  }
}

