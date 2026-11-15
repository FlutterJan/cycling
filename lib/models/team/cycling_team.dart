import 'bike_manufacturer_deal.dart';
import 'sponsor_contract.dart';
import '../equipment/complete_bike.dart';

enum TeamDivision {
  worldTour,
  proTeam,
  continental;

  String toJson() => name;

  String get label {
    switch (this) {
      case TeamDivision.worldTour:
        return 'UCI WorldTour';
      case TeamDivision.proTeam:
        return 'UCI ProTeam';
      case TeamDivision.continental:
        return 'UCI Continental';
    }
  }

  static TeamDivision fromJson(String value) {
    return TeamDivision.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TeamDivision.worldTour,
    );
  }
}

class TeamStaff {
  final int trainersLevel; // Poziom trenerów przygotowania fizycznego (1-100)
  final int sportsDirectorsLevel; // Poziom dyrektorów sportowych (taktyka w wyścigu) (1-100)
  final int doctorsLevel; // Poziom personelu medycznego (leczenie urazów i regeneracja) (1-100)
  final int mechanicsLevel; // Poziom mechaników (sprawność sprzętu, unikanie defektów) (1-100)
  final int scoutsLevel; // Poziom skautów (odkrywanie talentów u23/juniorów) (1-100)

  const TeamStaff({
    required this.trainersLevel,
    required this.sportsDirectorsLevel,
    required this.doctorsLevel,
    required this.mechanicsLevel,
    required this.scoutsLevel,
  });

  /// Średnia ogólna sztabu szkoleniowo-technicznego
  double get averageStaffLevel {
    return (trainersLevel +
            sportsDirectorsLevel +
            doctorsLevel +
            mechanicsLevel +
            scoutsLevel) /
        5.0;
  }

  TeamStaff copyWith({
    int? trainersLevel,
    int? sportsDirectorsLevel,
    int? doctorsLevel,
    int? mechanicsLevel,
    int? scoutsLevel,
  }) {
    return TeamStaff(
      trainersLevel: trainersLevel ?? this.trainersLevel,
      sportsDirectorsLevel: sportsDirectorsLevel ?? this.sportsDirectorsLevel,
      doctorsLevel: doctorsLevel ?? this.doctorsLevel,
      mechanicsLevel: mechanicsLevel ?? this.mechanicsLevel,
      scoutsLevel: scoutsLevel ?? this.scoutsLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trainersLevel': trainersLevel,
      'sportsDirectorsLevel': sportsDirectorsLevel,
      'doctorsLevel': doctorsLevel,
      'mechanicsLevel': mechanicsLevel,
      'scoutsLevel': scoutsLevel,
    };
  }

  factory TeamStaff.fromJson(Map<String, dynamic> json) {
    return TeamStaff(
      trainersLevel: (json['trainersLevel'] as num).toInt(),
      sportsDirectorsLevel: (json['sportsDirectorsLevel'] as num).toInt(),
      doctorsLevel: (json['doctorsLevel'] as num).toInt(),
      mechanicsLevel: (json['mechanicsLevel'] as num).toInt(),
      scoutsLevel: (json['scoutsLevel'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamStaff &&
        other.trainersLevel == trainersLevel &&
        other.sportsDirectorsLevel == sportsDirectorsLevel &&
        other.doctorsLevel == doctorsLevel &&
        other.mechanicsLevel == mechanicsLevel &&
        other.scoutsLevel == scoutsLevel;
  }

  @override
  int get hashCode {
    return Object.hash(
      trainersLevel,
      sportsDirectorsLevel,
      doctorsLevel,
      mechanicsLevel,
      scoutsLevel,
    );
  }

  @override
  String toString() {
    return 'TeamStaff(Avg: ${averageStaffLevel.toStringAsFixed(1)}, DS: $sportsDirectorsLevel, Trainers: $trainersLevel, Docs: $doctorsLevel, Mech: $mechanicsLevel)';
  }
}

class CyclingTeam {
  final String id;
  final String name;
  final TeamDivision division;
  final String countryIso;
  final String primaryJerseyColorHex;
  final String secondaryJerseyColorHex;
  final String accentJerseyColorHex;
  final int cashBalanceEur;
  final int monthlyBurnRateEur;
  final int uciPointsSeason;
  final List<String> rosterRiderIds;
  final TeamStaff staff;
  final BikeManufacturerDeal bikeDeal;
  final List<SponsorContract> sponsors;
  final List<CompleteBike> inventoryBikes;

  const CyclingTeam({
    required this.id,
    required this.name,
    required this.division,
    required this.countryIso,
    required this.primaryJerseyColorHex,
    required this.secondaryJerseyColorHex,
    required this.accentJerseyColorHex,
    required this.cashBalanceEur,
    required this.monthlyBurnRateEur,
    required this.uciPointsSeason,
    required this.rosterRiderIds,
    required this.staff,
    required this.bikeDeal,
    required this.sponsors,
    required this.inventoryBikes,
  });

  /// Łączny roczny przychód ze sponsoringu i kontraktu rowerowego w Euro
  int get annualSponsorIncomeEur {
    int total = bikeDeal.annualCashContributionEur;
    for (final sponsor in sponsors) {
      total += sponsor.annualBudgetEur;
    }
    return total;
  }

  /// Szacunkowy miesięczny przychód sponsorski
  int get monthlySponsorIncomeEur => (annualSponsorIncomeEur / 12).round();

  /// Miesięczny bilans netto (przychody - koszty stałe)
  int get netMonthlyCashflowEur => monthlySponsorIncomeEur - monthlyBurnRateEur;

  /// Liczba miesięcy płynności finansowej przy obecnym tempie wydatków
  double get runwayMonths {
    if (monthlyBurnRateEur <= 0) return 999.0;
    return cashBalanceEur / monthlyBurnRateEur;
  }

  /// Czy zespół posiada dodatni bilans konta
  bool get isFinanciallySolvent => cashBalanceEur > 0;

  /// Rowery wyścigowe na wyposażeniu zespołu
  List<CompleteBike> get teamBikes => inventoryBikes;
  List<CompleteBike> get bikes => inventoryBikes;

  CyclingTeam copyWith({
    String? id,
    String? name,
    TeamDivision? division,
    String? countryIso,
    String? primaryJerseyColorHex,
    String? secondaryJerseyColorHex,
    String? accentJerseyColorHex,
    int? cashBalanceEur,
    int? monthlyBurnRateEur,
    int? uciPointsSeason,
    List<String>? rosterRiderIds,
    TeamStaff? staff,
    BikeManufacturerDeal? bikeDeal,
    List<SponsorContract>? sponsors,
    List<CompleteBike>? inventoryBikes,
  }) {
    return CyclingTeam(
      id: id ?? this.id,
      name: name ?? this.name,
      division: division ?? this.division,
      countryIso: countryIso ?? this.countryIso,
      primaryJerseyColorHex: primaryJerseyColorHex ?? this.primaryJerseyColorHex,
      secondaryJerseyColorHex: secondaryJerseyColorHex ?? this.secondaryJerseyColorHex,
      accentJerseyColorHex: accentJerseyColorHex ?? this.accentJerseyColorHex,
      cashBalanceEur: cashBalanceEur ?? this.cashBalanceEur,
      monthlyBurnRateEur: monthlyBurnRateEur ?? this.monthlyBurnRateEur,
      uciPointsSeason: uciPointsSeason ?? this.uciPointsSeason,
      rosterRiderIds: rosterRiderIds != null
          ? List<String>.unmodifiable(rosterRiderIds)
          : this.rosterRiderIds,
      staff: staff ?? this.staff,
      bikeDeal: bikeDeal ?? this.bikeDeal,
      sponsors: sponsors != null
          ? List<SponsorContract>.unmodifiable(sponsors)
          : this.sponsors,
      inventoryBikes: inventoryBikes != null
          ? List<CompleteBike>.unmodifiable(inventoryBikes)
          : this.inventoryBikes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'division': division.toJson(),
      'countryIso': countryIso,
      'primaryJerseyColorHex': primaryJerseyColorHex,
      'secondaryJerseyColorHex': secondaryJerseyColorHex,
      'accentJerseyColorHex': accentJerseyColorHex,
      'cashBalanceEur': cashBalanceEur,
      'monthlyBurnRateEur': monthlyBurnRateEur,
      'uciPointsSeason': uciPointsSeason,
      'rosterRiderIds': rosterRiderIds,
      'staff': staff.toJson(),
      'bikeDeal': bikeDeal.toJson(),
      'sponsors': sponsors.map((s) => s.toJson()).toList(),
      'inventoryBikes': inventoryBikes.map((b) => b.toJson()).toList(),
    };
  }

  factory CyclingTeam.fromJson(Map<String, dynamic> json) {
    return CyclingTeam(
      id: json['id'] as String,
      name: json['name'] as String,
      division: TeamDivision.fromJson(json['division'] as String),
      countryIso: json['countryIso'] as String,
      primaryJerseyColorHex: json['primaryJerseyColorHex'] as String,
      secondaryJerseyColorHex: json['secondaryJerseyColorHex'] as String,
      accentJerseyColorHex: json['accentJerseyColorHex'] as String,
      cashBalanceEur: (json['cashBalanceEur'] as num).toInt(),
      monthlyBurnRateEur: (json['monthlyBurnRateEur'] as num).toInt(),
      uciPointsSeason: (json['uciPointsSeason'] as num).toInt(),
      rosterRiderIds: (json['rosterRiderIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      staff: TeamStaff.fromJson(json['staff'] as Map<String, dynamic>),
      bikeDeal: BikeManufacturerDeal.fromJson(json['bikeDeal'] as Map<String, dynamic>),
      sponsors: (json['sponsors'] as List<dynamic>?)
              ?.map((e) => SponsorContract.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      inventoryBikes: (json['inventoryBikes'] as List<dynamic>?)
              ?.map((e) => CompleteBike.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CyclingTeam && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CyclingTeam($name, ${division.name}, UCI: $uciPointsSeason pts, Cash: €$cashBalanceEur)';
  }
}

