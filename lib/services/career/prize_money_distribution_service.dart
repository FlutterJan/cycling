import '../../models/race/tour_race.dart';
import '../../models/team/cycling_team.dart';

/// Typ źródła nagrody finansowej w wyścigu kolarskim.
enum PrizeMoneySourceType {
  grandTourGc,
  stageWin,
  monumentWin,
  classificationJersey,
  teamClassification,
  intermediateSprintAndKom,
  other;

  String toJson() => name;

  static PrizeMoneySourceType fromJson(String value) {
    return PrizeMoneySourceType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PrizeMoneySourceType.other,
    );
  }

  String get label {
    switch (this) {
      case PrizeMoneySourceType.grandTourGc:
        return 'Klasyfikacja Generalna Grand Touru';
      case PrizeMoneySourceType.stageWin:
        return 'Zwycięstwo Etapowe';
      case PrizeMoneySourceType.monumentWin:
        return 'Zwycięstwo w Monumencie';
      case PrizeMoneySourceType.classificationJersey:
        return 'Koszulka Klasyfikacji (Punkty / Góry / Młodzież)';
      case PrizeMoneySourceType.teamClassification:
        return 'Klasyfikacja Drużynowa';
      case PrizeMoneySourceType.intermediateSprintAndKom:
        return 'Premie Lotne i Górskie';
      case PrizeMoneySourceType.other:
        return 'Inna Nagroda Wyścigowa';
    }
  }
}

/// Rola uczestnika w podziale puli nagród.
enum PrizeParticipantRole {
  winner,
  domestique,
  staff;

  String toJson() => name;

  static PrizeParticipantRole fromJson(String value) {
    return PrizeParticipantRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PrizeParticipantRole.domestique,
    );
  }

  String get label {
    switch (this) {
      case PrizeParticipantRole.winner:
        return 'Zwycięzca / Lider';
      case PrizeParticipantRole.domestique:
        return 'Pomocnik (Domestique)';
      case PrizeParticipantRole.staff:
        return 'Sztab Szkoleniowo-Techniczny';
    }
  }
}

/// Gotowe presety polityki podziału puli nagród.
enum PrizeMoneyDistributionPreset {
  grandTourStandard,
  traditionalPeloton,
  clubFirstCorporate,
  generousSquad;

  String toJson() => name;

  static PrizeMoneyDistributionPreset fromJson(String value) {
    return PrizeMoneyDistributionPreset.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PrizeMoneyDistributionPreset.grandTourStandard,
    );
  }

  String get label {
    switch (this) {
      case PrizeMoneyDistributionPreset.grandTourStandard:
        return 'Standard Grand Tour (20% Klub / 15% Lider / 55% Domestiques / 10% Sztab)';
      case PrizeMoneyDistributionPreset.traditionalPeloton:
        return 'Tradycja Peletonu (15% Klub / 10% Lider / 65% Domestiques / 10% Sztab)';
      case PrizeMoneyDistributionPreset.clubFirstCorporate:
        return 'Korporacyjny (35% Klub / 15% Lider / 40% Domestiques / 10% Sztab)';
      case PrizeMoneyDistributionPreset.generousSquad:
        return 'Hojna Ekipa (10% Klub / 10% Lider / 65% Domestiques / 15% Sztab)';
    }
  }
}

/// Polityka podziału puli nagród finansowych między klub, zwycięzcę,
/// pomocników (`domestiques`) oraz sztab drużyny.
class PrizeMoneyDistributionPolicy {
  final int clubSharePercent;
  final int winnerBonusPercent;
  final int domestiquesPoolPercent;
  final int staffBonusPercent;

  const PrizeMoneyDistributionPolicy({
    this.clubSharePercent = 20,
    this.winnerBonusPercent = 15,
    this.domestiquesPoolPercent = 55,
    this.staffBonusPercent = 10,
  });

  const PrizeMoneyDistributionPolicy.grandTourStandard()
      : clubSharePercent = 20,
        winnerBonusPercent = 15,
        domestiquesPoolPercent = 55,
        staffBonusPercent = 10;

  const PrizeMoneyDistributionPolicy.traditionalPeloton()
      : clubSharePercent = 15,
        winnerBonusPercent = 10,
        domestiquesPoolPercent = 65,
        staffBonusPercent = 10;

  const PrizeMoneyDistributionPolicy.clubFirstCorporate()
      : clubSharePercent = 35,
        winnerBonusPercent = 15,
        domestiquesPoolPercent = 40,
        staffBonusPercent = 10;

  const PrizeMoneyDistributionPolicy.generousSquad()
      : clubSharePercent = 10,
        winnerBonusPercent = 10,
        domestiquesPoolPercent = 65,
        staffBonusPercent = 15;

  factory PrizeMoneyDistributionPolicy.fromPreset(
    PrizeMoneyDistributionPreset preset,
  ) {
    switch (preset) {
      case PrizeMoneyDistributionPreset.grandTourStandard:
        return const PrizeMoneyDistributionPolicy.grandTourStandard();
      case PrizeMoneyDistributionPreset.traditionalPeloton:
        return const PrizeMoneyDistributionPolicy.traditionalPeloton();
      case PrizeMoneyDistributionPreset.clubFirstCorporate:
        return const PrizeMoneyDistributionPolicy.clubFirstCorporate();
      case PrizeMoneyDistributionPreset.generousSquad:
        return const PrizeMoneyDistributionPolicy.generousSquad();
    }
  }

  int get totalPercent =>
      clubSharePercent +
      winnerBonusPercent +
      domestiquesPoolPercent +
      staffBonusPercent;

  bool get isValid =>
      clubSharePercent >= 0 &&
      winnerBonusPercent >= 0 &&
      domestiquesPoolPercent >= 0 &&
      staffBonusPercent >= 0 &&
      totalPercent == 100;

  /// Normalizuje udziały tak, aby zawsze sumowały się dokładnie do 100%.
  PrizeMoneyDistributionPolicy normalized() {
    final safeClub = clubSharePercent.clamp(0, 100);
    final safeWinner = winnerBonusPercent.clamp(0, 100);
    final safeDomestiques = domestiquesPoolPercent.clamp(0, 100);
    final safeStaff = staffBonusPercent.clamp(0, 100);
    final sum = safeClub + safeWinner + safeDomestiques + safeStaff;

    if (sum == 100) {
      return PrizeMoneyDistributionPolicy(
        clubSharePercent: safeClub,
        winnerBonusPercent: safeWinner,
        domestiquesPoolPercent: safeDomestiques,
        staffBonusPercent: safeStaff,
      );
    }
    if (sum <= 0) {
      return const PrizeMoneyDistributionPolicy.grandTourStandard();
    }

    final normClub = ((safeClub * 100) / sum).round();
    final normWinner = ((safeWinner * 100) / sum).round();
    final normDomestiques = ((safeDomestiques * 100) / sum).round();
    final normStaff = 100 - normClub - normWinner - normDomestiques;

    if (normStaff < 0) {
      // Korygujemy największy udział, aby uniknąć wartości ujemnych po zaokrągleniu.
      final adjustedDomestiques =
          (normDomestiques + normStaff).clamp(0, 100);
      final remaining = 100 - normClub - normWinner - adjustedDomestiques;
      return PrizeMoneyDistributionPolicy(
        clubSharePercent: normClub,
        winnerBonusPercent: normWinner,
        domestiquesPoolPercent: adjustedDomestiques,
        staffBonusPercent: remaining.clamp(0, 100),
      );
    }

    return PrizeMoneyDistributionPolicy(
      clubSharePercent: normClub,
      winnerBonusPercent: normWinner,
      domestiquesPoolPercent: normDomestiques,
      staffBonusPercent: normStaff,
    );
  }

  /// Wpływ polityki podziału na morale pomocników (-0.08 do +0.08).
  double get domestiqueMoraleModifier {
    if (domestiquesPoolPercent >= 60) return 0.06;
    if (domestiquesPoolPercent >= 50) return 0.03;
    if (domestiquesPoolPercent >= 40) return 0.0;
    return -0.05;
  }

  /// Wpływ polityki podziału na morale lidera/zwycięzcy (-0.04 do +0.05).
  double get winnerMoraleModifier {
    if (winnerBonusPercent >= 20) return 0.05;
    if (winnerBonusPercent >= 10) return 0.02;
    if (winnerBonusPercent >= 5) return 0.0;
    return -0.02;
  }

  /// Wpływ polityki podziału na lojalność pomocników (-0.05 do +0.06).
  double get domestiqueLoyaltyModifier {
    if (domestiquesPoolPercent >= 60 && clubSharePercent <= 20) return 0.06;
    if (domestiquesPoolPercent >= 50) return 0.03;
    if (clubSharePercent > 35) return -0.05;
    return 0.0;
  }

  PrizeMoneyDistributionPolicy copyWith({
    int? clubSharePercent,
    int? winnerBonusPercent,
    int? domestiquesPoolPercent,
    int? staffBonusPercent,
  }) {
    return PrizeMoneyDistributionPolicy(
      clubSharePercent: clubSharePercent ?? this.clubSharePercent,
      winnerBonusPercent: winnerBonusPercent ?? this.winnerBonusPercent,
      domestiquesPoolPercent:
          domestiquesPoolPercent ?? this.domestiquesPoolPercent,
      staffBonusPercent: staffBonusPercent ?? this.staffBonusPercent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clubSharePercent': clubSharePercent,
      'winnerBonusPercent': winnerBonusPercent,
      'domestiquesPoolPercent': domestiquesPoolPercent,
      'staffBonusPercent': staffBonusPercent,
    };
  }

  factory PrizeMoneyDistributionPolicy.fromJson(Map<String, dynamic> json) {
    return PrizeMoneyDistributionPolicy(
      clubSharePercent: (json['clubSharePercent'] as num?)?.toInt() ?? 20,
      winnerBonusPercent: (json['winnerBonusPercent'] as num?)?.toInt() ?? 15,
      domestiquesPoolPercent:
          (json['domestiquesPoolPercent'] as num?)?.toInt() ?? 55,
      staffBonusPercent: (json['staffBonusPercent'] as num?)?.toInt() ?? 10,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrizeMoneyDistributionPolicy &&
        other.clubSharePercent == clubSharePercent &&
        other.winnerBonusPercent == winnerBonusPercent &&
        other.domestiquesPoolPercent == domestiquesPoolPercent &&
        other.staffBonusPercent == staffBonusPercent;
  }

  @override
  int get hashCode => Object.hash(
        clubSharePercent,
        winnerBonusPercent,
        domestiquesPoolPercent,
        staffBonusPercent,
      );
}

/// Dane kolarza biorącego udział w podziale nagrody wyścigowej.
class PrizeMoneyRiderInput {
  final String riderId;
  final String riderName;
  final bool isWinner;

  const PrizeMoneyRiderInput({
    required this.riderId,
    required this.riderName,
    this.isWinner = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'isWinner': isWinner,
    };
  }

  factory PrizeMoneyRiderInput.fromJson(Map<String, dynamic> json) {
    return PrizeMoneyRiderInput(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      isWinner: (json['isWinner'] as bool?) ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrizeMoneyRiderInput &&
        other.riderId == riderId &&
        other.riderName == riderName &&
        other.isWinner == isWinner;
  }

  @override
  int get hashCode => Object.hash(riderId, riderName, isWinner);
}

/// Dane członka sztabu biorącego udział w podziale premii sztabowej.
class PrizeMoneyStaffInput {
  final String staffId;
  final String staffName;
  final String roleLabel;

  const PrizeMoneyStaffInput({
    required this.staffId,
    required this.staffName,
    required this.roleLabel,
  });

  Map<String, dynamic> toJson() {
    return {
      'staffId': staffId,
      'staffName': staffName,
      'roleLabel': roleLabel,
    };
  }

  factory PrizeMoneyStaffInput.fromJson(Map<String, dynamic> json) {
    return PrizeMoneyStaffInput(
      staffId: json['staffId'] as String,
      staffName: json['staffName'] as String,
      roleLabel: json['roleLabel'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrizeMoneyStaffInput &&
        other.staffId == staffId &&
        other.staffName == staffName &&
        other.roleLabel == roleLabel;
  }

  @override
  int get hashCode => Object.hash(staffId, staffName, roleLabel);
}

/// Wejście do podziału puli nagród z konkretnego wyścigu lub etapu.
class PrizeMoneyPoolInput {
  final String raceId;
  final String raceName;
  final RaceCategory raceCategory;
  final PrizeMoneySourceType sourceType;
  final int totalPoolEur;
  final List<PrizeMoneyRiderInput> riders;
  final List<PrizeMoneyStaffInput> staffMembers;
  final DateTime awardedAt;

  const PrizeMoneyPoolInput({
    required this.raceId,
    required this.raceName,
    required this.raceCategory,
    required this.sourceType,
    required this.totalPoolEur,
    required this.riders,
    this.staffMembers = const [],
    required this.awardedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'raceId': raceId,
      'raceName': raceName,
      'raceCategory': raceCategory.toJson(),
      'sourceType': sourceType.toJson(),
      'totalPoolEur': totalPoolEur,
      'riders': riders.map((e) => e.toJson()).toList(),
      'staffMembers': staffMembers.map((e) => e.toJson()).toList(),
      'awardedAt': awardedAt.toIso8601String(),
    };
  }

  factory PrizeMoneyPoolInput.fromJson(Map<String, dynamic> json) {
    return PrizeMoneyPoolInput(
      raceId: json['raceId'] as String,
      raceName: json['raceName'] as String,
      raceCategory: RaceCategory.fromJson(
        (json['raceCategory'] as String?) ?? 'worldTourStageRace',
      ),
      sourceType: PrizeMoneySourceType.fromJson(
        (json['sourceType'] as String?) ?? 'other',
      ),
      totalPoolEur: (json['totalPoolEur'] as num).toInt(),
      riders: (json['riders'] as List<dynamic>? ?? const [])
          .map((e) => PrizeMoneyRiderInput.fromJson(e as Map<String, dynamic>))
          .toList(),
      staffMembers: (json['staffMembers'] as List<dynamic>? ?? const [])
          .map((e) => PrizeMoneyStaffInput.fromJson(e as Map<String, dynamic>))
          .toList(),
      awardedAt: DateTime.parse(json['awardedAt'] as String),
    );
  }
}

/// Indywidualna wypłata z puli nagród dla kolarza lub członka sztabu.
class IndividualPrizePayout {
  final String recipientId;
  final String recipientName;
  final PrizeParticipantRole role;
  final String roleLabel;
  final int amountEur;
  final double shareOfTotalPercent;
  final double moraleDelta;
  final double loyaltyDelta;

  const IndividualPrizePayout({
    required this.recipientId,
    required this.recipientName,
    required this.role,
    required this.roleLabel,
    required this.amountEur,
    required this.shareOfTotalPercent,
    required this.moraleDelta,
    required this.loyaltyDelta,
  });

  Map<String, dynamic> toJson() {
    return {
      'recipientId': recipientId,
      'recipientName': recipientName,
      'role': role.toJson(),
      'roleLabel': roleLabel,
      'amountEur': amountEur,
      'shareOfTotalPercent': shareOfTotalPercent,
      'moraleDelta': moraleDelta,
      'loyaltyDelta': loyaltyDelta,
    };
  }

  factory IndividualPrizePayout.fromJson(Map<String, dynamic> json) {
    return IndividualPrizePayout(
      recipientId: json['recipientId'] as String,
      recipientName: json['recipientName'] as String,
      role: PrizeParticipantRole.fromJson(json['role'] as String),
      roleLabel: json['roleLabel'] as String,
      amountEur: (json['amountEur'] as num).toInt(),
      shareOfTotalPercent: (json['shareOfTotalPercent'] as num).toDouble(),
      moraleDelta: (json['moraleDelta'] as num).toDouble(),
      loyaltyDelta: (json['loyaltyDelta'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IndividualPrizePayout &&
        other.recipientId == recipientId &&
        other.role == role &&
        other.amountEur == amountEur;
  }

  @override
  int get hashCode => Object.hash(recipientId, role, amountEur);
}

/// Kompletny raport podziału puli nagród po wyścigu.
class PrizeMoneyDistributionResult {
  final String raceId;
  final String raceName;
  final RaceCategory raceCategory;
  final PrizeMoneySourceType sourceType;
  final DateTime awardedAt;
  final int totalPoolEur;
  final int clubShareEur;
  final int winnerBonusEur;
  final int domestiquesPoolEur;
  final int perDomestiqueShareEur;
  final int staffBonusPoolEur;
  final int perStaffShareEur;
  final int roundingRemainderEur;
  final List<IndividualPrizePayout> riderPayouts;
  final List<IndividualPrizePayout> staffPayouts;
  final PrizeMoneyDistributionPolicy appliedPolicy;
  final double averageDomestiqueMoraleDelta;
  final double winnerMoraleDelta;
  final String summaryNote;

  const PrizeMoneyDistributionResult({
    required this.raceId,
    required this.raceName,
    required this.raceCategory,
    required this.sourceType,
    required this.awardedAt,
    required this.totalPoolEur,
    required this.clubShareEur,
    required this.winnerBonusEur,
    required this.domestiquesPoolEur,
    required this.perDomestiqueShareEur,
    required this.staffBonusPoolEur,
    required this.perStaffShareEur,
    required this.roundingRemainderEur,
    required this.riderPayouts,
    required this.staffPayouts,
    required this.appliedPolicy,
    required this.averageDomestiqueMoraleDelta,
    required this.winnerMoraleDelta,
    required this.summaryNote,
  });

  int get totalRidersDistributedEur =>
      riderPayouts.fold<int>(0, (sum, p) => sum + p.amountEur);

  int get totalStaffDistributedEur =>
      staffPayouts.fold<int>(0, (sum, p) => sum + p.amountEur);

  int get totalDistributedEur =>
      clubShareEur + totalRidersDistributedEur + totalStaffDistributedEur;

  /// Weryfikuje pełną zgodność księgową (co do 1 EUR).
  bool get isBalanced => totalDistributedEur == totalPoolEur;

  Map<String, dynamic> toJson() {
    return {
      'raceId': raceId,
      'raceName': raceName,
      'raceCategory': raceCategory.toJson(),
      'sourceType': sourceType.toJson(),
      'awardedAt': awardedAt.toIso8601String(),
      'totalPoolEur': totalPoolEur,
      'clubShareEur': clubShareEur,
      'winnerBonusEur': winnerBonusEur,
      'domestiquesPoolEur': domestiquesPoolEur,
      'perDomestiqueShareEur': perDomestiqueShareEur,
      'staffBonusPoolEur': staffBonusPoolEur,
      'perStaffShareEur': perStaffShareEur,
      'roundingRemainderEur': roundingRemainderEur,
      'riderPayouts': riderPayouts.map((e) => e.toJson()).toList(),
      'staffPayouts': staffPayouts.map((e) => e.toJson()).toList(),
      'appliedPolicy': appliedPolicy.toJson(),
      'averageDomestiqueMoraleDelta': averageDomestiqueMoraleDelta,
      'winnerMoraleDelta': winnerMoraleDelta,
      'summaryNote': summaryNote,
    };
  }

  factory PrizeMoneyDistributionResult.fromJson(Map<String, dynamic> json) {
    return PrizeMoneyDistributionResult(
      raceId: json['raceId'] as String,
      raceName: json['raceName'] as String,
      raceCategory: RaceCategory.fromJson(
        (json['raceCategory'] as String?) ?? 'worldTourStageRace',
      ),
      sourceType: PrizeMoneySourceType.fromJson(
        (json['sourceType'] as String?) ?? 'other',
      ),
      awardedAt: DateTime.parse(json['awardedAt'] as String),
      totalPoolEur: (json['totalPoolEur'] as num).toInt(),
      clubShareEur: (json['clubShareEur'] as num).toInt(),
      winnerBonusEur: (json['winnerBonusEur'] as num).toInt(),
      domestiquesPoolEur: (json['domestiquesPoolEur'] as num).toInt(),
      perDomestiqueShareEur: (json['perDomestiqueShareEur'] as num).toInt(),
      staffBonusPoolEur: (json['staffBonusPoolEur'] as num).toInt(),
      perStaffShareEur: (json['perStaffShareEur'] as num).toInt(),
      roundingRemainderEur: (json['roundingRemainderEur'] as num).toInt(),
      riderPayouts: (json['riderPayouts'] as List<dynamic>? ?? const [])
          .map((e) => IndividualPrizePayout.fromJson(e as Map<String, dynamic>))
          .toList(),
      staffPayouts: (json['staffPayouts'] as List<dynamic>? ?? const [])
          .map((e) => IndividualPrizePayout.fromJson(e as Map<String, dynamic>))
          .toList(),
      appliedPolicy: PrizeMoneyDistributionPolicy.fromJson(
        json['appliedPolicy'] as Map<String, dynamic>,
      ),
      averageDomestiqueMoraleDelta:
          (json['averageDomestiqueMoraleDelta'] as num).toDouble(),
      winnerMoraleDelta: (json['winnerMoraleDelta'] as num).toDouble(),
      summaryNote: json['summaryNote'] as String,
    );
  }
}

/// Zbiorcze zestawienie podziału nagród z wielu wyścigów / całego sezonu.
class SeasonPrizeMoneyLedgerSummary {
  final int totalPoolEur;
  final int totalClubShareEur;
  final int totalWinnerBonusEur;
  final int totalDomestiquesPoolEur;
  final int totalStaffBonusEur;
  final Map<String, int> riderTotalsEur;
  final List<PrizeMoneyDistributionResult> distributions;

  const SeasonPrizeMoneyLedgerSummary({
    required this.totalPoolEur,
    required this.totalClubShareEur,
    required this.totalWinnerBonusEur,
    required this.totalDomestiquesPoolEur,
    required this.totalStaffBonusEur,
    required this.riderTotalsEur,
    required this.distributions,
  });

  bool get isBalanced =>
      (totalClubShareEur +
          totalWinnerBonusEur +
          totalDomestiquesPoolEur +
          totalStaffBonusEur) ==
      totalPoolEur;
}

/// Serwis podziału nagród finansowych drużyny kolarskiej (`PrizeMoneyDistributionService`).
///
/// Realizuje tradycyjny kolarski podział puli wygranych (np. 500 000 EUR za
/// zwycięstwo w Grand Tourze) na:
/// - procent dla budżetu klubu,
/// - premię indywidualną dla zwycięzcy,
/// - tradycyjną pulę dzieloną równo między pomocników (`domestiques`),
/// - premię dla sztabu szkoleniowo-technicznego.
class PrizeMoneyDistributionService {
  /// Domyślna pula za zwycięstwo w klasyfikacji generalnej Grand Touru (500 000 EUR).
  static const int defaultGrandTourWinnerPoolEur = 500000;

  /// Domyślny skład sztabu wyścigowego, gdy nie podano listy imiennej.
  static const List<PrizeMoneyStaffInput> defaultRaceStaffRoster = [
    PrizeMoneyStaffInput(
      staffId: 'staff_ds_lead',
      staffName: 'Dyrektor Sportowy',
      roleLabel: 'Dyrektor Sportowy',
    ),
    PrizeMoneyStaffInput(
      staffId: 'staff_mech_1',
      staffName: 'Główny Mechanik',
      roleLabel: 'Mechanik',
    ),
    PrizeMoneyStaffInput(
      staffId: 'staff_soigneur_1',
      staffName: 'Fizjoterapeuta / Masażysta',
      roleLabel: 'Soigneur',
    ),
    PrizeMoneyStaffInput(
      staffId: 'staff_doctor_1',
      staffName: 'Lekarz Drużyny',
      roleLabel: 'Lekarz',
    ),
  ];

  const PrizeMoneyDistributionService();

  /// Dzieli pulę nagród według zadanej polityki z pełnym uzgodnieniem groszowym (1 EUR).
  PrizeMoneyDistributionResult distributePrizePool({
    required PrizeMoneyPoolInput input,
    PrizeMoneyDistributionPolicy policy =
        const PrizeMoneyDistributionPolicy.grandTourStandard(),
  }) {
    final safePolicy = policy.normalized();
    final safeTotal = input.totalPoolEur < 0 ? 0 : input.totalPoolEur;

    if (safeTotal == 0) {
      return PrizeMoneyDistributionResult(
        raceId: input.raceId,
        raceName: input.raceName,
        raceCategory: input.raceCategory,
        sourceType: input.sourceType,
        awardedAt: input.awardedAt,
        totalPoolEur: 0,
        clubShareEur: 0,
        winnerBonusEur: 0,
        domestiquesPoolEur: 0,
        perDomestiqueShareEur: 0,
        staffBonusPoolEur: 0,
        perStaffShareEur: 0,
        roundingRemainderEur: 0,
        riderPayouts: const [],
        staffPayouts: const [],
        appliedPolicy: safePolicy,
        averageDomestiqueMoraleDelta: 0.0,
        winnerMoraleDelta: 0.0,
        summaryNote: 'Brak puli nagród do podziału dla ${input.raceName}.',
      );
    }

    final winners = input.riders.where((r) => r.isWinner).toList();
    final domestiques = input.riders.where((r) => !r.isWinner).toList();
    final staffList = input.staffMembers.isNotEmpty
        ? input.staffMembers
        : defaultRaceStaffRoster;

    // Obliczenie bazowych koszyków z całkowitej puli.
    int clubShare = (safeTotal * safePolicy.clubSharePercent) ~/ 100;
    int winnerPool = (safeTotal * safePolicy.winnerBonusPercent) ~/ 100;
    int domestiquesPool =
        (safeTotal * safePolicy.domestiquesPoolPercent) ~/ 100;
    int staffPool = (safeTotal * safePolicy.staffBonusPercent) ~/ 100;

    // Uzgodnienie reszty z dzielenia procentowego trafia do klubu.
    final baseAllocated = clubShare + winnerPool + domestiquesPool + staffPool;
    final percentRemainder = safeTotal - baseAllocated;
    clubShare += percentRemainder;

    // Obsługa przypadków brzegowych (brak zwycięzcy lub brak pomocników).
    if (winners.isEmpty && domestiques.isNotEmpty) {
      domestiquesPool += winnerPool;
      winnerPool = 0;
    } else if (winners.isNotEmpty && domestiques.isEmpty) {
      winnerPool += domestiquesPool;
      domestiquesPool = 0;
    } else if (winners.isEmpty && domestiques.isEmpty) {
      clubShare += winnerPool + domestiquesPool;
      winnerPool = 0;
      domestiquesPool = 0;
    }

    final riderPayouts = <IndividualPrizePayout>[];
    final staffPayouts = <IndividualPrizePayout>[];
    int totalDivisionRemainder = percentRemainder;

    final scaleFactor = _poolScaleMoraleFactor(safeTotal);

    // 1. Wypłaty dla zwycięzców (zwykle 1 zwycięzca, ale obsługuje też ex aequo).
    double winnerMoraleDelta = 0.0;
    if (winners.isNotEmpty) {
      final perWinner = winnerPool ~/ winners.length;
      final winnerRem = winnerPool - (perWinner * winners.length);
      if (winnerRem > 0) {
        clubShare += winnerRem;
        totalDivisionRemainder += winnerRem;
      }
      winnerMoraleDelta =
          (safePolicy.winnerMoraleModifier + 0.03 * scaleFactor).clamp(-0.1, 0.12);

      for (final winner in winners) {
        riderPayouts.add(
          IndividualPrizePayout(
            recipientId: winner.riderId,
            recipientName: winner.riderName,
            role: PrizeParticipantRole.winner,
            roleLabel: PrizeParticipantRole.winner.label,
            amountEur: perWinner,
            shareOfTotalPercent: (perWinner / safeTotal) * 100.0,
            moraleDelta: winnerMoraleDelta,
            loyaltyDelta: (winnerMoraleDelta * 0.6).clamp(-0.08, 0.08),
          ),
        );
      }
    }

    // 2. Tradycyjna pula dzielona równo między pomocników (domestiques).
    int perDomestiqueShare = 0;
    double domestiqueMoraleDelta = 0.0;
    if (domestiques.isNotEmpty) {
      perDomestiqueShare = domestiquesPool ~/ domestiques.length;
      final domRem = domestiquesPool - (perDomestiqueShare * domestiques.length);
      if (domRem > 0) {
        clubShare += domRem;
        totalDivisionRemainder += domRem;
      }
      domestiquesPool = perDomestiqueShare * domestiques.length;
      domestiqueMoraleDelta =
          (safePolicy.domestiqueMoraleModifier + 0.03 * scaleFactor)
              .clamp(-0.1, 0.12);
      final domLoyaltyDelta =
          (safePolicy.domestiqueLoyaltyModifier + 0.02 * scaleFactor)
              .clamp(-0.08, 0.10);

      for (final dom in domestiques) {
        riderPayouts.add(
          IndividualPrizePayout(
            recipientId: dom.riderId,
            recipientName: dom.riderName,
            role: PrizeParticipantRole.domestique,
            roleLabel: PrizeParticipantRole.domestique.label,
            amountEur: perDomestiqueShare,
            shareOfTotalPercent: (perDomestiqueShare / safeTotal) * 100.0,
            moraleDelta: domestiqueMoraleDelta,
            loyaltyDelta: domLoyaltyDelta,
          ),
        );
      }
    }

    // 3. Premia dla sztabu szkoleniowo-technicznego dzielona równo.
    int perStaffShare = 0;
    if (staffList.isNotEmpty) {
      perStaffShare = staffPool ~/ staffList.length;
      final staffRem = staffPool - (perStaffShare * staffList.length);
      if (staffRem > 0) {
        clubShare += staffRem;
        totalDivisionRemainder += staffRem;
      }
      staffPool = perStaffShare * staffList.length;
      final staffMoraleDelta =
          (safePolicy.staffBonusPercent >= 10 ? 0.04 : 0.01) * scaleFactor;

      for (final staff in staffList) {
        staffPayouts.add(
          IndividualPrizePayout(
            recipientId: staff.staffId,
            recipientName: staff.staffName,
            role: PrizeParticipantRole.staff,
            roleLabel: staff.roleLabel,
            amountEur: perStaffShare,
            shareOfTotalPercent: (perStaffShare / safeTotal) * 100.0,
            moraleDelta: staffMoraleDelta,
            loyaltyDelta: staffMoraleDelta * 0.8,
          ),
        );
      }
    } else {
      clubShare += staffPool;
      staffPool = 0;
    }

    final winnerActualEur = winners.isNotEmpty
        ? riderPayouts
            .where((p) => p.role == PrizeParticipantRole.winner)
            .fold<int>(0, (s, p) => s + p.amountEur)
        : 0;

    final summaryNote =
        'Podział puli $safeTotal EUR (${input.raceName}): '
        'Klub $clubShare EUR, Zwycięzca $winnerActualEur EUR, '
        'Domestiques ${domestiques.length}x $perDomestiqueShare EUR, '
        'Sztab ${staffList.length}x $perStaffShare EUR.';

    return PrizeMoneyDistributionResult(
      raceId: input.raceId,
      raceName: input.raceName,
      raceCategory: input.raceCategory,
      sourceType: input.sourceType,
      awardedAt: input.awardedAt,
      totalPoolEur: safeTotal,
      clubShareEur: clubShare,
      winnerBonusEur: winnerActualEur,
      domestiquesPoolEur: domestiquesPool,
      perDomestiqueShareEur: perDomestiqueShare,
      staffBonusPoolEur: staffPool,
      perStaffShareEur: perStaffShare,
      roundingRemainderEur: totalDivisionRemainder,
      riderPayouts: List.unmodifiable(riderPayouts),
      staffPayouts: List.unmodifiable(staffPayouts),
      appliedPolicy: safePolicy,
      averageDomestiqueMoraleDelta: domestiqueMoraleDelta,
      winnerMoraleDelta: winnerMoraleDelta,
      summaryNote: summaryNote,
    );
  }

  /// Dedykowany skrót dla klasycznego podziału wygranej w Grand Tourze
  /// (domyślnie 500 000 EUR).
  PrizeMoneyDistributionResult distributeGrandTourVictory({
    required String raceId,
    required String raceName,
    required PrizeMoneyRiderInput winner,
    required List<PrizeMoneyRiderInput> domestiques,
    List<PrizeMoneyStaffInput> staffMembers = const [],
    int totalPoolEur = defaultGrandTourWinnerPoolEur,
    PrizeMoneyDistributionPolicy policy =
        const PrizeMoneyDistributionPolicy.grandTourStandard(),
    DateTime? awardedAt,
  }) {
    final normalizedWinner = PrizeMoneyRiderInput(
      riderId: winner.riderId,
      riderName: winner.riderName,
      isWinner: true,
    );
    final normalizedDomestiques = domestiques
        .map(
          (d) => PrizeMoneyRiderInput(
            riderId: d.riderId,
            riderName: d.riderName,
            isWinner: false,
          ),
        )
        .toList();

    return distributePrizePool(
      input: PrizeMoneyPoolInput(
        raceId: raceId,
        raceName: raceName,
        raceCategory: RaceCategory.grandTour,
        sourceType: PrizeMoneySourceType.grandTourGc,
        totalPoolEur: totalPoolEur,
        riders: [normalizedWinner, ...normalizedDomestiques],
        staffMembers: staffMembers,
        awardedAt: awardedAt ?? DateTime.now(),
      ),
      policy: policy,
    );
  }

  /// Agreguje podziały z wielu wyścigów lub etapów w jeden raport księgowy.
  SeasonPrizeMoneyLedgerSummary distributeMultiplePools({
    required List<PrizeMoneyPoolInput> pools,
    PrizeMoneyDistributionPolicy policy =
        const PrizeMoneyDistributionPolicy.grandTourStandard(),
  }) {
    final results = <PrizeMoneyDistributionResult>[];
    final riderTotals = <String, int>{};

    int totalPool = 0;
    int totalClub = 0;
    int totalWinner = 0;
    int totalDomestiques = 0;
    int totalStaff = 0;

    for (final pool in pools) {
      final result = distributePrizePool(input: pool, policy: policy);
      results.add(result);
      totalPool += result.totalPoolEur;
      totalClub += result.clubShareEur;
      totalWinner += result.winnerBonusEur;
      totalDomestiques += result.domestiquesPoolEur;
      totalStaff += result.staffBonusPoolEur;

      for (final payout in result.riderPayouts) {
        riderTotals[payout.recipientId] =
            (riderTotals[payout.recipientId] ?? 0) + payout.amountEur;
      }
    }

    return SeasonPrizeMoneyLedgerSummary(
      totalPoolEur: totalPool,
      totalClubShareEur: totalClub,
      totalWinnerBonusEur: totalWinner,
      totalDomestiquesPoolEur: totalDomestiques,
      totalStaffBonusEur: totalStaff,
      riderTotalsEur: Map.unmodifiable(riderTotals),
      distributions: List.unmodifiable(results),
    );
  }

  /// Księguje udział klubu bezpośrednio na saldo drużyny `CyclingTeam`.
  CyclingTeam applyClubShareToTeamBudget({
    required CyclingTeam team,
    required PrizeMoneyDistributionResult distribution,
  }) {
    if (distribution.clubShareEur <= 0) return team;
    return team.copyWith(
      cashBalanceEur: team.cashBalanceEur + distribution.clubShareEur,
    );
  }

  /// Rekomenduje politykę podziału nagród na podstawie kondycji finansowej
  /// klubu oraz średniego morale kadry.
  PrizeMoneyDistributionPolicy recommendPolicyForTeam({
    required CyclingTeam team,
    required double averageRosterMorale,
  }) {
    final monthlyBurn =
        team.monthlyBurnRateEur <= 0 ? 1 : team.monthlyBurnRateEur;
    final runwayMonths = team.cashBalanceEur / monthlyBurn;

    if (runwayMonths < 2.5) {
      return const PrizeMoneyDistributionPolicy.clubFirstCorporate();
    }
    if (averageRosterMorale < 0.55) {
      return const PrizeMoneyDistributionPolicy.generousSquad();
    }
    if (averageRosterMorale >= 0.78 && runwayMonths >= 6.0) {
      return const PrizeMoneyDistributionPolicy.traditionalPeloton();
    }
    return const PrizeMoneyDistributionPolicy.grandTourStandard();
  }

  double _poolScaleMoraleFactor(int totalPoolEur) {
    if (totalPoolEur >= 250000) return 1.5;
    if (totalPoolEur >= 50000) return 1.1;
    if (totalPoolEur >= 10000) return 0.75;
    return 0.4;
  }
}
