class BikeManufacturerDeal {
  final String manufacturerId;
  final String manufacturerName;
  final int prestigeLevel; // 1-5 gwiazdek prestiżu marki
  final int annualCashContributionEur; // Roczny wkład gotówkowy sponsora technicznego w Euro
  final int freeBikesQuota; // Pula bezpłatnych rowerów/ram na sezon (np. 60-120 sztuk)
  final int researchAndDevelopmentLevel; // Poziom R&D (1-100) wpływający na ewolucję sprzętu w trakcie sezonu
  final List<String> suppliedFrameIds; // Identyfikatory ram dostarczanych zespołowi
  final List<String> suppliedWheelsetIds; // Identyfikatory kół dostarczanych zespołowi
  final int contractYearsLeft; // Pozostałe lata obowiązywania umowy
  final int minimumUciRankingRequired; // Minimalna wymagana pozycja w rankingu UCI drużyn (np. top 10)

  const BikeManufacturerDeal({
    required this.manufacturerId,
    required this.manufacturerName,
    required this.prestigeLevel,
    required this.annualCashContributionEur,
    required this.freeBikesQuota,
    required this.researchAndDevelopmentLevel,
    required this.suppliedFrameIds,
    required this.suppliedWheelsetIds,
    required this.contractYearsLeft,
    required this.minimumUciRankingRequired,
  });

  /// Czy umowa wygasa z końcem bieżącego sezonu
  bool get isExpiring => contractYearsLeft <= 1;

  /// Identyfikator marki (alias dla manufacturerId)
  String get brandId => manufacturerId;

  /// Czy drużyna spełnia wymagania rankingowe producenta
  bool isRankingRequirementSatisfied(int currentTeamUciRanking) {
    return currentTeamUciRanking <= minimumUciRankingRequired;
  }

  BikeManufacturerDeal copyWith({
    String? manufacturerId,
    String? manufacturerName,
    int? prestigeLevel,
    int? annualCashContributionEur,
    int? freeBikesQuota,
    int? researchAndDevelopmentLevel,
    List<String>? suppliedFrameIds,
    List<String>? suppliedWheelsetIds,
    int? contractYearsLeft,
    int? minimumUciRankingRequired,
  }) {
    return BikeManufacturerDeal(
      manufacturerId: manufacturerId ?? this.manufacturerId,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      prestigeLevel: prestigeLevel ?? this.prestigeLevel,
      annualCashContributionEur: annualCashContributionEur ?? this.annualCashContributionEur,
      freeBikesQuota: freeBikesQuota ?? this.freeBikesQuota,
      researchAndDevelopmentLevel: researchAndDevelopmentLevel ?? this.researchAndDevelopmentLevel,
      suppliedFrameIds: suppliedFrameIds != null
          ? List<String>.unmodifiable(suppliedFrameIds)
          : this.suppliedFrameIds,
      suppliedWheelsetIds: suppliedWheelsetIds != null
          ? List<String>.unmodifiable(suppliedWheelsetIds)
          : this.suppliedWheelsetIds,
      contractYearsLeft: contractYearsLeft ?? this.contractYearsLeft,
      minimumUciRankingRequired: minimumUciRankingRequired ?? this.minimumUciRankingRequired,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'manufacturerId': manufacturerId,
      'manufacturerName': manufacturerName,
      'prestigeLevel': prestigeLevel,
      'annualCashContributionEur': annualCashContributionEur,
      'freeBikesQuota': freeBikesQuota,
      'researchAndDevelopmentLevel': researchAndDevelopmentLevel,
      'suppliedFrameIds': suppliedFrameIds,
      'suppliedWheelsetIds': suppliedWheelsetIds,
      'contractYearsLeft': contractYearsLeft,
      'minimumUciRankingRequired': minimumUciRankingRequired,
    };
  }

  factory BikeManufacturerDeal.fromJson(Map<String, dynamic> json) {
    return BikeManufacturerDeal(
      manufacturerId: json['manufacturerId'] as String,
      manufacturerName: json['manufacturerName'] as String,
      prestigeLevel: (json['prestigeLevel'] as num).toInt(),
      annualCashContributionEur: (json['annualCashContributionEur'] as num).toInt(),
      freeBikesQuota: (json['freeBikesQuota'] as num).toInt(),
      researchAndDevelopmentLevel: (json['researchAndDevelopmentLevel'] as num).toInt(),
      suppliedFrameIds: (json['suppliedFrameIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      suppliedWheelsetIds: (json['suppliedWheelsetIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      contractYearsLeft: (json['contractYearsLeft'] as num).toInt(),
      minimumUciRankingRequired: (json['minimumUciRankingRequired'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BikeManufacturerDeal) return false;

    if (other.manufacturerId != manufacturerId ||
        other.manufacturerName != manufacturerName ||
        other.prestigeLevel != prestigeLevel ||
        other.annualCashContributionEur != annualCashContributionEur ||
        other.freeBikesQuota != freeBikesQuota ||
        other.researchAndDevelopmentLevel != researchAndDevelopmentLevel ||
        other.contractYearsLeft != contractYearsLeft ||
        other.minimumUciRankingRequired != minimumUciRankingRequired ||
        other.suppliedFrameIds.length != suppliedFrameIds.length ||
        other.suppliedWheelsetIds.length != suppliedWheelsetIds.length) {
      return false;
    }

    for (int i = 0; i < suppliedFrameIds.length; i++) {
      if (other.suppliedFrameIds[i] != suppliedFrameIds[i]) return false;
    }

    for (int i = 0; i < suppliedWheelsetIds.length; i++) {
      if (other.suppliedWheelsetIds[i] != suppliedWheelsetIds[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      manufacturerId,
      manufacturerName,
      prestigeLevel,
      annualCashContributionEur,
      freeBikesQuota,
      researchAndDevelopmentLevel,
      contractYearsLeft,
      minimumUciRankingRequired,
      Object.hashAll(suppliedFrameIds),
      Object.hashAll(suppliedWheelsetIds),
    );
  }

  @override
  String toString() {
    return 'BikeManufacturerDeal($manufacturerName, €$annualCashContributionEur/rok, Prestige: $prestigeLevel★, R&D: $researchAndDevelopmentLevel, left: ${contractYearsLeft}y)';
  }
}

