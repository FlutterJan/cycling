enum RiderRole {
  teamLeader,
  coLeader,
  superDomestique,
  sprinter,
  breakawaySpecialist,
  domestique,
  neoPro;

  String toJson() => name;

  String get label {
    switch (this) {
      case RiderRole.teamLeader:
        return 'Lider Zespołu';
      case RiderRole.coLeader:
        return 'Co-Lider';
      case RiderRole.superDomestique:
        return 'Super-Domestique';
      case RiderRole.sprinter:
        return 'Główny Sprinter';
      case RiderRole.breakawaySpecialist:
        return 'Specjalista od ucieczek';
      case RiderRole.domestique:
        return 'Pomocnik';
      case RiderRole.neoPro:
        return 'Młody Talent (Neo-Pro)';
    }
  }

  static RiderRole fromJson(String value) {
    return RiderRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() ||
             (e == RiderRole.domestique && value.toLowerCase() == 'domestic'),
      orElse: () => RiderRole.domestique,
    );
  }
}

class RiderContract {
  final String teamId;
  final RiderRole role;
  final int monthlySalaryEur;
  final int signingBonusEur;
  final int winBonusEur;
  final int releaseClauseEur;
  final int contractEndYear;
  final double morale;
  final double leaderLoyalty;
  final List<String> requiredRacesIds;

  const RiderContract({
    required this.teamId,
    required this.role,
    required this.monthlySalaryEur,
    required this.signingBonusEur,
    required this.winBonusEur,
    required this.releaseClauseEur,
    required this.contractEndYear,
    required this.morale,
    required this.leaderLoyalty,
    required this.requiredRacesIds,
  });

  /// Roczne wynagrodzenie bazowe w Euro
  int get annualSalaryEur => monthlySalaryEur * 12;

  /// Sprawdza, czy kontrakt wygasa w danym roku kalendarzowym
  bool isExpiring(int currentYear) => contractEndYear <= currentYear;

  RiderContract copyWith({
    String? teamId,
    RiderRole? role,
    int? monthlySalaryEur,
    int? signingBonusEur,
    int? winBonusEur,
    int? releaseClauseEur,
    int? contractEndYear,
    double? morale,
    double? leaderLoyalty,
    List<String>? requiredRacesIds,
  }) {
    return RiderContract(
      teamId: teamId ?? this.teamId,
      role: role ?? this.role,
      monthlySalaryEur: monthlySalaryEur ?? this.monthlySalaryEur,
      signingBonusEur: signingBonusEur ?? this.signingBonusEur,
      winBonusEur: winBonusEur ?? this.winBonusEur,
      releaseClauseEur: releaseClauseEur ?? this.releaseClauseEur,
      contractEndYear: contractEndYear ?? this.contractEndYear,
      morale: morale ?? this.morale,
      leaderLoyalty: leaderLoyalty ?? this.leaderLoyalty,
      requiredRacesIds: requiredRacesIds != null
          ? List<String>.unmodifiable(requiredRacesIds)
          : this.requiredRacesIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'role': role.toJson(),
      'monthlySalaryEur': monthlySalaryEur,
      'signingBonusEur': signingBonusEur,
      'winBonusEur': winBonusEur,
      'releaseClauseEur': releaseClauseEur,
      'contractEndYear': contractEndYear,
      'morale': morale,
      'leaderLoyalty': leaderLoyalty,
      'requiredRacesIds': requiredRacesIds,
    };
  }

  factory RiderContract.fromJson(Map<String, dynamic> json) {
    return RiderContract(
      teamId: json['teamId'] as String,
      role: RiderRole.fromJson(json['role'] as String),
      monthlySalaryEur: (json['monthlySalaryEur'] as num).toInt(),
      signingBonusEur: (json['signingBonusEur'] as num).toInt(),
      winBonusEur: (json['winBonusEur'] as num).toInt(),
      releaseClauseEur: (json['releaseClauseEur'] as num).toInt(),
      contractEndYear: (json['contractEndYear'] as num).toInt(),
      morale: (json['morale'] as num).toDouble(),
      leaderLoyalty: (json['leaderLoyalty'] as num).toDouble(),
      requiredRacesIds: (json['requiredRacesIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RiderContract) return false;

    if (other.teamId != teamId ||
        other.role != role ||
        other.monthlySalaryEur != monthlySalaryEur ||
        other.signingBonusEur != signingBonusEur ||
        other.winBonusEur != winBonusEur ||
        other.releaseClauseEur != releaseClauseEur ||
        other.contractEndYear != contractEndYear ||
        other.morale != morale ||
        other.leaderLoyalty != leaderLoyalty ||
        other.requiredRacesIds.length != requiredRacesIds.length) {
      return false;
    }

    for (int i = 0; i < requiredRacesIds.length; i++) {
      if (other.requiredRacesIds[i] != requiredRacesIds[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      teamId,
      role,
      monthlySalaryEur,
      signingBonusEur,
      winBonusEur,
      releaseClauseEur,
      contractEndYear,
      morale,
      leaderLoyalty,
      Object.hashAll(requiredRacesIds),
    );
  }

  @override
  String toString() {
    return 'RiderContract(team: $teamId, role: ${role.name}, salary: €$monthlySalaryEur/mo, ends: $contractEndYear, morale: $morale)';
  }
}

