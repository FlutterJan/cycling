import 'lactate_and_lab_profile.dart';
import 'rider_physiology.dart';
import 'rider_power_profile.dart';
import 'rider_skills.dart';
import 'rider_appearance.dart';
import 'rider_contract.dart';
import 'rider_health.dart';

enum RiderSpecialization {
  gcClimber,
  pureClimber,
  puncher,
  classicCobbles,
  pureSprinter,
  versatileSprinter,
  timeTrialist,
  domestiqueEngine,
  breakawaySpecialist;

  String toJson() => name;

  String get displayName {
    switch (this) {
      case RiderSpecialization.gcClimber:
        return 'Lider GC / Góral';
      case RiderSpecialization.pureClimber:
        return 'Czysty Góral';
      case RiderSpecialization.puncher:
        return 'Puncher / Pagórki';
      case RiderSpecialization.classicCobbles:
        return 'Klasykowiec / Bruki';
      case RiderSpecialization.pureSprinter:
        return 'Czysty Sprinter';
      case RiderSpecialization.versatileSprinter:
        return 'Wszechstronny Sprinter';
      case RiderSpecialization.timeTrialist:
        return 'Czasowiec (TT)';
      case RiderSpecialization.domestiqueEngine:
        return 'Pomocnik (Domestique)';
      case RiderSpecialization.breakawaySpecialist:
        return 'Hulaka / Uciekinier';
    }
  }

  static RiderSpecialization fromJson(String value) {
    return RiderSpecialization.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RiderSpecialization.domestiqueEngine,
    );
  }
}

class Rider {
  final String id;
  final String firstName;
  final String lastName;
  final String nationalityIso;
  final DateTime birthDate;
  final int potential; // 1-100
  final RiderSpecialization specialization;
  final RiderPhysiology physiology;
  final RiderPowerProfile powerProfile;
  final RiderSkills skills;
  final RiderAppearance appearance;
  final RiderContract contract;
  final RiderHealth health;
  final int careerPointsUci;

  const Rider({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.nationalityIso,
    required this.birthDate,
    required this.potential,
    required this.specialization,
    required this.physiology,
    required this.powerProfile,
    required this.skills,
    required this.appearance,
    required this.contract,
    required this.health,
    required this.careerPointsUci,
  });

  String get fullName => '$firstName $lastName';
  String get countryIso => nationalityIso;

  /// Profil parametrów laboratoryjnych (LT1, LT2/MLSS, VLaMax, VO2max, Gross Efficiency)
  LactateAndLabProfile get labProfile =>
      physiology.labProfile ??
      LactateAndLabProfile.fromPhysiology(
        physiology,
        specialization: specialization,
        powerProfile: powerProfile,
      );

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Wylicza ocenę ogólną OVR (1-99) w zależności od profilu specjalizacji kolarza
  int get overallRating {
    final weight = physiology.weightKg > 0.0 ? physiology.weightKg : 70.0;
    final wPerKg20m = (powerProfile.watts20m / weight);
    final wPerKg5m = (powerProfile.watts5m / weight);
    final wPerKg1m = (powerProfile.watts1m / weight);

    // Skalowanie wskaźników do przedziału 40 - 99
    // Klasa światowa W/kg: 20m ~ 6.5 W/kg, 5m ~ 7.8 W/kg, 1m ~ 11.5 W/kg, sprint ~ 1600W
    final scoreClimb = ((wPerKg20m - 3.5) / (6.6 - 3.5) * 55 + 44).clamp(40.0, 99.0);
    final scoreVo2 = ((wPerKg5m - 4.5) / (8.0 - 4.5) * 55 + 44).clamp(40.0, 99.0);
    final scorePunch = ((wPerKg1m - 6.5) / (12.0 - 6.5) * 55 + 44).clamp(40.0, 99.0);
    final scoreSprint = ((powerProfile.watts5s - 900.0) / (1750.0 - 900.0) * 55 + 44).clamp(40.0, 99.0);
    final scoreTt = ((powerProfile.watts60m - 280.0) / (460.0 - 280.0) * 40 +
            (skills.timeTrialPositioning * 0.35) +
            (skills.aeroPositioning * 0.25)).clamp(40.0, 99.0);
    final scoreCobbles = (skills.cobbles * 0.65 + skills.bikeHandling * 0.35).clamp(40.0, 99.0);

    double weightedScore;
    switch (specialization) {
      case RiderSpecialization.gcClimber:
        weightedScore = scoreClimb * 0.45 + scoreTt * 0.25 + scoreVo2 * 0.15 + skills.raceIq * 0.15;
        break;
      case RiderSpecialization.pureClimber:
        weightedScore = scoreClimb * 0.60 + scoreVo2 * 0.30 + skills.descending * 0.10;
        break;
      case RiderSpecialization.puncher:
        weightedScore = scorePunch * 0.45 + scoreVo2 * 0.25 + scoreSprint * 0.15 + skills.raceIq * 0.15;
        break;
      case RiderSpecialization.classicCobbles:
        weightedScore = scoreCobbles * 0.50 + scorePunch * 0.20 + skills.rainResistance * 0.15 + skills.bikeHandling * 0.15;
        break;
      case RiderSpecialization.pureSprinter:
        weightedScore = scoreSprint * 0.65 + skills.bikeHandling * 0.20 + skills.draftingEfficiency * 0.15;
        break;
      case RiderSpecialization.versatileSprinter:
        weightedScore = scoreSprint * 0.45 + scorePunch * 0.25 + scoreVo2 * 0.15 + skills.bikeHandling * 0.15;
        break;
      case RiderSpecialization.timeTrialist:
        weightedScore = scoreTt * 0.65 + scoreClimb * 0.20 + skills.aeroPositioning * 0.15;
        break;
      case RiderSpecialization.domestiqueEngine:
        weightedScore = scoreClimb * 0.35 + scoreTt * 0.25 + skills.draftingEfficiency * 0.20 + contract.leaderLoyalty * 0.20;
        break;
      case RiderSpecialization.breakawaySpecialist:
        weightedScore = scoreTt * 0.30 + scorePunch * 0.25 + scoreVo2 * 0.25 + skills.raceIq * 0.20;
        break;
    }

    return weightedScore.round().clamp(1, 99);
  }

  /// Wyliczona ocena sprintu (skala 40 - 99)
  double get scoreSprint => ((powerProfile.watts5s - 900.0) / (1750.0 - 900.0) * 55 + 44).clamp(40.0, 99.0);

  /// Wyliczona ocena jazdy po górach (skala 40 - 99)
  double get scoreClimb {
    final weight = physiology.weightKg > 0.0 ? physiology.weightKg : 70.0;
    final wPerKg20m = (powerProfile.watts20m / weight);
    return ((wPerKg20m - 3.5) / (6.6 - 3.5) * 55 + 44).clamp(40.0, 99.0);
  }

  int get sprintRating => scoreSprint.round();
  int get climbRating => scoreClimb.round();

  /// ID drużyny z aktywnego kontraktu kolarza
  String get teamId => contract.teamId;

  Rider copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? nationalityIso,
    DateTime? birthDate,
    int? age,
    int? potential,
    RiderSpecialization? specialization,
    RiderPhysiology? physiology,
    RiderPowerProfile? powerProfile,
    RiderSkills? skills,
    RiderAppearance? appearance,
    RiderContract? contract,
    RiderHealth? health,
    int? careerPointsUci,
  }) {
    DateTime effectiveBirthDate = birthDate ?? this.birthDate;
    if (age != null) {
      effectiveBirthDate = DateTime(DateTime.now().year - age, effectiveBirthDate.month, effectiveBirthDate.day);
    }

    return Rider(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nationalityIso: nationalityIso ?? this.nationalityIso,
      birthDate: effectiveBirthDate,
      potential: potential ?? this.potential,
      specialization: specialization ?? this.specialization,
      physiology: physiology ?? this.physiology,
      powerProfile: powerProfile ?? this.powerProfile,
      skills: skills ?? this.skills,
      appearance: appearance ?? this.appearance,
      contract: contract ?? this.contract,
      health: health ?? this.health,
      careerPointsUci: careerPointsUci ?? this.careerPointsUci,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'nationalityIso': nationalityIso,
      'birthDate': birthDate.toIso8601String(),
      'potential': potential,
      'specialization': specialization.toJson(),
      'physiology': physiology.toJson(),
      'powerProfile': powerProfile.toJson(),
      'skills': skills.toJson(),
      'appearance': appearance.toJson(),
      'contract': contract.toJson(),
      'health': health.toJson(),
      'careerPointsUci': careerPointsUci,
    };
  }

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      nationalityIso: json['nationalityIso'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      potential: (json['potential'] as num).toInt(),
      specialization: RiderSpecialization.fromJson(json['specialization'] as String),
      physiology: RiderPhysiology.fromJson(json['physiology'] as Map<String, dynamic>),
      powerProfile: RiderPowerProfile.fromJson(json['powerProfile'] as Map<String, dynamic>),
      skills: RiderSkills.fromJson(json['skills'] as Map<String, dynamic>),
      appearance: RiderAppearance.fromJson(json['appearance'] as Map<String, dynamic>),
      contract: RiderContract.fromJson(json['contract'] as Map<String, dynamic>),
      health: RiderHealth.fromJson(json['health'] as Map<String, dynamic>),
      careerPointsUci: (json['careerPointsUci'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Rider && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Rider($fullName, OVR: $overallRating, Spec: ${specialization.name}, UCI: $careerPointsUci)';
  }
}

