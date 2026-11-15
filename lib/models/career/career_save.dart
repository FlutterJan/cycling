import '../race/race_stage.dart';
import '../race/tour_race.dart';
import '../rider/rider.dart';
import '../rider/rider_contract.dart';
import '../team/cycling_team.dart';
import '../../services/career/team_chemistry_and_builder_service.dart';
import '../../services/career/race_calendar_selection_service.dart';
import '../../services/career/scouting_and_youth_academy_service.dart';
import 'season_calendar.dart';

/// Poziom trudności kariery menedżerskiej.
enum CareerDifficulty {
  easy,
  normal,
  hard,
  realistic;

  String toJson() => name;

  static CareerDifficulty fromJson(String value) {
    return CareerDifficulty.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CareerDifficulty.normal,
    );
  }

  String get label {
    switch (this) {
      case CareerDifficulty.easy:
        return 'Łatwy (Wysoki budżet, wyrozumiały zarząd)';
      case CareerDifficulty.normal:
        return 'Normalny (Zbalansowane finanse i rynek transferowy)';
      case CareerDifficulty.hard:
        return 'Trudny (Wymagający sponsorzy, ostra konkurencja)';
      case CareerDifficulty.realistic:
        return 'Realistyczny (Ścisłe limity budżetowe, bezlitosne UCI)';
    }
  }
}

/// Status oferty kontraktowej na rynku transferowym.
enum ContractOfferStatus {
  pending,
  accepted,
  rejected,
  counterOffer,
  expired;

  String toJson() => name;

  static ContractOfferStatus fromJson(String value) {
    return ContractOfferStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ContractOfferStatus.pending,
    );
  }
}

/// Oferta kontraktowa dla kolarza lub negocjacja na rynku transferowym.
class CareerContractOffer {
  final String offerId;
  final String riderId;
  final String riderName;
  final String offeringTeamId;
  final String offeringTeamName;
  final int annualSalaryEur;
  final int contractDurationYears;
  final int winBonusEur;
  final RiderRole proposedRole;
  final ContractOfferStatus status;
  final DateTime offeredDate;
  final String? rejectionReason;

  const CareerContractOffer({
    required this.offerId,
    required this.riderId,
    required this.riderName,
    required this.offeringTeamId,
    required this.offeringTeamName,
    required this.annualSalaryEur,
    required this.contractDurationYears,
    required this.winBonusEur,
    this.proposedRole = RiderRole.domestique,
    required this.status,
    required this.offeredDate,
    this.rejectionReason,
  });

  CareerContractOffer copyWith({
    String? offerId,
    String? riderId,
    String? riderName,
    String? offeringTeamId,
    String? offeringTeamName,
    int? annualSalaryEur,
    int? contractDurationYears,
    int? winBonusEur,
    RiderRole? proposedRole,
    ContractOfferStatus? status,
    DateTime? offeredDate,
    String? rejectionReason,
  }) {
    return CareerContractOffer(
      offerId: offerId ?? this.offerId,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      offeringTeamId: offeringTeamId ?? this.offeringTeamId,
      offeringTeamName: offeringTeamName ?? this.offeringTeamName,
      annualSalaryEur: annualSalaryEur ?? this.annualSalaryEur,
      contractDurationYears: contractDurationYears ?? this.contractDurationYears,
      winBonusEur: winBonusEur ?? this.winBonusEur,
      proposedRole: proposedRole ?? this.proposedRole,
      status: status ?? this.status,
      offeredDate: offeredDate ?? this.offeredDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offerId': offerId,
      'riderId': riderId,
      'riderName': riderName,
      'offeringTeamId': offeringTeamId,
      'offeringTeamName': offeringTeamName,
      'annualSalaryEur': annualSalaryEur,
      'contractDurationYears': contractDurationYears,
      'winBonusEur': winBonusEur,
      'proposedRole': proposedRole.toJson(),
      'status': status.toJson(),
      'offeredDate': offeredDate.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  factory CareerContractOffer.fromJson(Map<String, dynamic> json) {
    return CareerContractOffer(
      offerId: json['offerId'] as String,
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      offeringTeamId: json['offeringTeamId'] as String,
      offeringTeamName: json['offeringTeamName'] as String,
      annualSalaryEur: (json['annualSalaryEur'] as num).toInt(),
      contractDurationYears: (json['contractDurationYears'] as num).toInt(),
      winBonusEur: (json['winBonusEur'] as num).toInt(),
      proposedRole: json['proposedRole'] != null
          ? RiderRole.fromJson(json['proposedRole'] as String)
          : RiderRole.domestique,
      status: ContractOfferStatus.fromJson(json['status'] as String),
      offeredDate: DateTime.parse(json['offeredDate'] as String),
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CareerContractOffer && other.offerId == offerId;
  }

  @override
  int get hashCode => offerId.hashCode;

  @override
  String toString() =>
      'CareerContractOffer($riderName -> $offeringTeamName: €${annualSalaryEur ~/ 1000}k/yr, ${status.name})';
}

/// Kategoria wpisu w księdze finansowej drużyny (przychód lub wydatek).
enum FinanceCategory {
  sponsorPayout,
  bikeManufacturerCash,
  prizeMoney,
  racePrizeMoney,
  riderBuyoutIncome,
  riderSalaries,
  staffSalaries,
  travelExpenses,
  raceLogistics,
  trainingCamps,
  physiologicalTesting,
  equipmentUpgrade,
  facilityUpgrade,
  scoutingCosts;

  String toJson() => name;

  static FinanceCategory fromJson(String value) {
    return FinanceCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => FinanceCategory.travelExpenses,
    );
  }

  String get label {
    switch (this) {
      case FinanceCategory.sponsorPayout:
        return 'Transza sponsorska';
      case FinanceCategory.bikeManufacturerCash:
        return 'Wsparcie producenta rowerów';
      case FinanceCategory.prizeMoney:
      case FinanceCategory.racePrizeMoney:
        return 'Nagrody z wyścigów (Prize Money)';
      case FinanceCategory.riderBuyoutIncome:
        return 'Wykup klauzuli / Odstępne za kolarza';
      case FinanceCategory.riderSalaries:
        return 'Pensje kolarzy';
      case FinanceCategory.staffSalaries:
        return 'Pensje sztabu szkoleniowego';
      case FinanceCategory.travelExpenses:
      case FinanceCategory.raceLogistics:
        return 'Logistyka wyścigowa (autokary, wóz techniczny, przeloty)';
      case FinanceCategory.trainingCamps:
        return 'Obozy wysokogórskie i zgrupowania';
      case FinanceCategory.physiologicalTesting:
        return 'Badania wydolnościowe (ergospirometria, mleczan)';
      case FinanceCategory.equipmentUpgrade:
        return 'Serwis i zakup sprzętu';
      case FinanceCategory.facilityUpgrade:
        return 'Infrastruktura i baza logistyczna';
      case FinanceCategory.scoutingCosts:
        return 'Skauting młodzieży (U19/U23)';
    }
  }

  bool get isIncomeCategory {
    return this == FinanceCategory.sponsorPayout ||
        this == FinanceCategory.bikeManufacturerCash ||
        this == FinanceCategory.prizeMoney ||
        this == FinanceCategory.racePrizeMoney ||
        this == FinanceCategory.riderBuyoutIncome;
  }
}

/// Pojedynczy wpis w historii transakcji finansowych klubu.
class CareerFinanceLedgerEntry {
  final String id;
  final DateTime date;
  final FinanceCategory category;
  final int amountEur; // Wartość dodatnia = przychód, ujemna = wydatek
  final String description;

  const CareerFinanceLedgerEntry({
    required this.id,
    required this.date,
    required this.category,
    required this.amountEur,
    required this.description,
  });

  bool get isIncome => amountEur > 0;
  bool get isExpense => amountEur < 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'category': category.toJson(),
      'amountEur': amountEur,
      'description': description,
    };
  }

  factory CareerFinanceLedgerEntry.fromJson(Map<String, dynamic> json) {
    return CareerFinanceLedgerEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      category: FinanceCategory.fromJson(json['category'] as String),
      amountEur: (json['amountEur'] as num).toInt(),
      description: json['description'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CareerFinanceLedgerEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CareerFinanceLedgerEntry(${date.toIso8601String().substring(0, 10)}: $category €$amountEur - $description)';
}

/// Główny model stanu zapisu gry (Career Save).
///
/// Zawiera całościowy stan świata symulacji kolarskiej:
/// - drużynę gracza i pozostałe 52 zespoły,
/// - pełny skład ponad 800 kolarzy,
/// - kalendarz sezonu wraz z historią wyścigów,
/// - infrastrukturę klubu (baza logistyczna, tunel aerodynamiczny, centrum medyczne),
/// - rynek transferowy i finanse.
class CareerSave {
  final String id;
  final String saveName;
  final DateTime createdAt;
  final DateTime lastSavedAt;
  final CareerDifficulty difficulty;
  final String playerManagerName;
  final String playerTeamId;
  final DateTime currentDate;
  final int currentSeasonYear;
  final SeasonCalendar calendar;
  final List<CyclingTeam> teams;
  final List<Rider> riders;
  final List<String> scoutedRiderIds;
  final List<CareerContractOffer> contractOffers;
  final List<CareerFinanceLedgerEntry> financeLedger;
  final int managerReputation; // 1 - 100
  final int serviceCourseLevel; // 1 - 5 (Zaplecze sprzętowe i logistyka)
  final int windTunnelLevel; // 1 - 5 (Rozwój aerodynamiki i CdA)
  final int medicalCenterLevel; // 1 - 5 (Szybkość leczenia urazów i regeneracja)
  final List<String> trophiesWon;
  final List<FranchiseRider> franchiseLeaders; // 1-3 Głównych Liderów zespołu
  final List<DedicatedSquad> dedicatedSquads; // Dedykowane pociągi (np. TdF, Klasyki)
  final List<WildcardApplication> wildcardApplications; // Wnioski o Dzikie Karty (Wildcards)
  final List<ScoutedProspect> scoutingProspects; // Pula obserwowanych młodych adeptów
  final YouthAcademy youthAcademy; // Akademia młodzieżowa / Development Team

  const CareerSave({
    required this.id,
    required this.saveName,
    required this.createdAt,
    required this.lastSavedAt,
    required this.difficulty,
    required this.playerManagerName,
    required this.playerTeamId,
    required this.currentDate,
    required this.currentSeasonYear,
    required this.calendar,
    required this.teams,
    required this.riders,
    this.scoutedRiderIds = const [],
    this.contractOffers = const [],
    this.financeLedger = const [],
    this.managerReputation = 50,
    this.serviceCourseLevel = 1,
    this.windTunnelLevel = 1,
    this.medicalCenterLevel = 1,
    this.trophiesWon = const [],
    this.franchiseLeaders = const [],
    this.dedicatedSquads = const [],
    this.wildcardApplications = const [],
    this.scoutingProspects = const [],
    this.youthAcademy = const YouthAcademy(),
  });

  /// Drużyna prowadzona przez gracza
  CyclingTeam get playerTeam {
    return teams.firstWhere(
      (t) => t.id == playerTeamId,
      orElse: () => teams.first,
    );
  }

  /// Skład kolarzy w drużynie gracza
  List<Rider> get playerRoster {
    final teamRiderIds = playerTeam.rosterRiderIds;
    return riders.where((r) => teamRiderIds.contains(r.id)).toList();
  }

  /// Stan konta drużyny gracza [EUR]
  int get playerCashBalanceEur => playerTeam.cashBalanceEur;

  /// Czy dzień dzisiejszy jest dniem wyścigowym dla drużyny gracza
  bool get isRaceDay => calendar.activeRaceId != null;

  /// Aktualnie trwający wyścig (jeśli istnieje)
  TourRace? get activeRace => calendar.activeRace;

  /// Aktualnie rozgrywany etap wyścigu
  RaceStage? get activeStage => calendar.activeStage;

  /// Wyszukuje kolarza po identyfikatorze
  Rider? getRiderById(String riderId) {
    for (final r in riders) {
      if (r.id == riderId) return r;
    }
    return null;
  }

  /// Wyszukuje drużynę po identyfikatorze
  CyclingTeam? getTeamById(String teamId) {
    for (final t in teams) {
      if (t.id == teamId) return t;
    }
    return null;
  }

  /// Zwraca zaktualizowany zapis z dodanym wpisem do księgi finansowej
  CareerSave addFinanceTransaction({
    required FinanceCategory category,
    required int amountEur,
    required String description,
  }) {
    final newEntry = CareerFinanceLedgerEntry(
      id: 'fin_${DateTime.now().millisecondsSinceEpoch}',
      date: currentDate,
      category: category,
      amountEur: amountEur,
      description: description,
    );

    // Aktualizujemy saldo drużyny gracza
    final updatedTeams = teams.map((team) {
      if (team.id == playerTeamId) {
        return team.copyWith(
          cashBalanceEur: team.cashBalanceEur + amountEur,
        );
      }
      return team;
    }).toList();

    return copyWith(
      teams: updatedTeams,
      financeLedger: [newEntry, ...financeLedger],
      lastSavedAt: DateTime.now(),
    );
  }

  /// Aktualizuje stan jednego kolarza w bazie (np. po etapie, zmęczeniu lub kontuzji)
  CareerSave updateRider(Rider updatedRider) {
    final updatedRiders = riders.map((r) {
      return r.id == updatedRider.id ? updatedRider : r;
    }).toList();

    return copyWith(
      riders: updatedRiders,
      lastSavedAt: DateTime.now(),
    );
  }

  CareerSave copyWith({
    String? id,
    String? saveName,
    DateTime? createdAt,
    DateTime? lastSavedAt,
    CareerDifficulty? difficulty,
    String? playerManagerName,
    String? playerTeamId,
    DateTime? currentDate,
    int? currentSeasonYear,
    SeasonCalendar? calendar,
    List<CyclingTeam>? teams,
    List<Rider>? riders,
    List<String>? scoutedRiderIds,
    List<CareerContractOffer>? contractOffers,
    List<CareerFinanceLedgerEntry>? financeLedger,
    int? managerReputation,
    int? serviceCourseLevel,
    int? windTunnelLevel,
    int? medicalCenterLevel,
    List<String>? trophiesWon,
    List<FranchiseRider>? franchiseLeaders,
    List<DedicatedSquad>? dedicatedSquads,
    List<WildcardApplication>? wildcardApplications,
    List<ScoutedProspect>? scoutingProspects,
    YouthAcademy? youthAcademy,
  }) {
    return CareerSave(
      id: id ?? this.id,
      saveName: saveName ?? this.saveName,
      createdAt: createdAt ?? this.createdAt,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      difficulty: difficulty ?? this.difficulty,
      playerManagerName: playerManagerName ?? this.playerManagerName,
      playerTeamId: playerTeamId ?? this.playerTeamId,
      currentDate: currentDate ?? this.currentDate,
      currentSeasonYear: currentSeasonYear ?? this.currentSeasonYear,
      calendar: calendar ?? this.calendar,
      teams: teams != null ? List<CyclingTeam>.unmodifiable(teams) : this.teams,
      riders: riders != null ? List<Rider>.unmodifiable(riders) : this.riders,
      scoutedRiderIds: scoutedRiderIds != null
          ? List<String>.unmodifiable(scoutedRiderIds)
          : this.scoutedRiderIds,
      contractOffers: contractOffers != null
          ? List<CareerContractOffer>.unmodifiable(contractOffers)
          : this.contractOffers,
      financeLedger: financeLedger != null
          ? List<CareerFinanceLedgerEntry>.unmodifiable(financeLedger)
          : this.financeLedger,
      managerReputation: managerReputation ?? this.managerReputation,
      serviceCourseLevel: serviceCourseLevel ?? this.serviceCourseLevel,
      windTunnelLevel: windTunnelLevel ?? this.windTunnelLevel,
      medicalCenterLevel: medicalCenterLevel ?? this.medicalCenterLevel,
      trophiesWon: trophiesWon != null
          ? List<String>.unmodifiable(trophiesWon)
          : this.trophiesWon,
      franchiseLeaders: franchiseLeaders != null
          ? List<FranchiseRider>.unmodifiable(franchiseLeaders)
          : this.franchiseLeaders,
      dedicatedSquads: dedicatedSquads != null
          ? List<DedicatedSquad>.unmodifiable(dedicatedSquads)
          : this.dedicatedSquads,
      wildcardApplications: wildcardApplications != null
          ? List<WildcardApplication>.unmodifiable(wildcardApplications)
          : this.wildcardApplications,
      scoutingProspects: scoutingProspects != null
          ? List<ScoutedProspect>.unmodifiable(scoutingProspects)
          : this.scoutingProspects,
      youthAcademy: youthAcademy ?? this.youthAcademy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saveName': saveName,
      'createdAt': createdAt.toIso8601String(),
      'lastSavedAt': lastSavedAt.toIso8601String(),
      'difficulty': difficulty.toJson(),
      'playerManagerName': playerManagerName,
      'playerTeamId': playerTeamId,
      'currentDate': currentDate.toIso8601String(),
      'currentSeasonYear': currentSeasonYear,
      'calendar': calendar.toJson(),
      'teams': teams.map((t) => t.toJson()).toList(),
      'riders': riders.map((r) => r.toJson()).toList(),
      'scoutedRiderIds': scoutedRiderIds,
      'contractOffers': contractOffers.map((o) => o.toJson()).toList(),
      'financeLedger': financeLedger.map((f) => f.toJson()).toList(),
      'managerReputation': managerReputation,
      'serviceCourseLevel': serviceCourseLevel,
      'windTunnelLevel': windTunnelLevel,
      'medicalCenterLevel': medicalCenterLevel,
      'trophiesWon': trophiesWon,
      'franchiseLeaders': franchiseLeaders.map((l) => l.toJson()).toList(),
      'dedicatedSquads': dedicatedSquads.map((s) => s.toJson()).toList(),
      'wildcardApplications': wildcardApplications.map((w) => w.toJson()).toList(),
      'scoutingProspects': scoutingProspects.map((p) => p.toJson()).toList(),
      'youthAcademy': youthAcademy.toJson(),
    };
  }

  factory CareerSave.fromJson(Map<String, dynamic> json) {
    return CareerSave(
      id: json['id'] as String,
      saveName: json['saveName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastSavedAt: DateTime.parse(json['lastSavedAt'] as String),
      difficulty: CareerDifficulty.fromJson(json['difficulty'] as String),
      playerManagerName: json['playerManagerName'] as String,
      playerTeamId: json['playerTeamId'] as String,
      currentDate: DateTime.parse(json['currentDate'] as String),
      currentSeasonYear: (json['currentSeasonYear'] as num).toInt(),
      calendar: SeasonCalendar.fromJson(json['calendar'] as Map<String, dynamic>),
      teams: (json['teams'] as List<dynamic>)
          .map((e) => CyclingTeam.fromJson(e as Map<String, dynamic>))
          .toList(),
      riders: (json['riders'] as List<dynamic>)
          .map((e) => Rider.fromJson(e as Map<String, dynamic>))
          .toList(),
      scoutedRiderIds: (json['scoutedRiderIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      contractOffers: (json['contractOffers'] as List<dynamic>?)
              ?.map((e) => CareerContractOffer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      financeLedger: (json['financeLedger'] as List<dynamic>?)
              ?.map((e) => CareerFinanceLedgerEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      managerReputation: (json['managerReputation'] as num?)?.toInt() ?? 50,
      serviceCourseLevel: (json['serviceCourseLevel'] as num?)?.toInt() ?? 1,
      windTunnelLevel: (json['windTunnelLevel'] as num?)?.toInt() ?? 1,
      medicalCenterLevel: (json['medicalCenterLevel'] as num?)?.toInt() ?? 1,
      trophiesWon: (json['trophiesWon'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      franchiseLeaders: (json['franchiseLeaders'] as List<dynamic>?)
              ?.map((e) => FranchiseRider.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      dedicatedSquads: (json['dedicatedSquads'] as List<dynamic>?)
              ?.map((e) => DedicatedSquad.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      wildcardApplications: (json['wildcardApplications'] as List<dynamic>?)
              ?.map((e) => WildcardApplication.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      scoutingProspects: (json['scoutingProspects'] as List<dynamic>?)
              ?.map((e) => ScoutedProspect.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      youthAcademy: json['youthAcademy'] != null
          ? YouthAcademy.fromJson(json['youthAcademy'] as Map<String, dynamic>)
          : const YouthAcademy(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CareerSave && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CareerSave($saveName, Team: $playerTeamId, Year: $currentSeasonYear, Date: ${currentDate.toIso8601String().substring(0, 10)})';
}

