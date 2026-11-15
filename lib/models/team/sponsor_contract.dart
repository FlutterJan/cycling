enum SponsorIndustry {
  finance,
  tech,
  energy,
  automotive,
  airlines,
  supermarkets,
  crypto,
  apparel;

  String toJson() => name;

  static SponsorIndustry fromJson(String value) {
    return SponsorIndustry.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SponsorIndustry.finance,
    );
  }
}

enum SponsorTier {
  titlePrimary,
  titleSecondary,
  majorPartner,
  technicalSupplier;

  String toJson() => name;

  static SponsorTier fromJson(String value) {
    return SponsorTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SponsorTier.majorPartner,
    );
  }
}

enum ObjectiveImportance {
  low,
  medium,
  high,
  critical;

  String toJson() => name;

  static ObjectiveImportance fromJson(String value) {
    return ObjectiveImportance.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ObjectiveImportance.medium,
    );
  }
}

class SponsorObjective {
  final String id;
  final String description; // np. "Wygraj etap w Grand Tour", "Top 5 w klasyku brukowanym", "500 km w ucieczkach"
  final int bonusPaymentEur;
  final ObjectiveImportance importance;
  final bool isCompleted;
  final double currentProgress;
  final double targetProgress;

  const SponsorObjective({
    required this.id,
    required this.description,
    required this.bonusPaymentEur,
    required this.importance,
    required this.isCompleted,
    required this.currentProgress,
    required this.targetProgress,
  });

  /// Procent wykonania celu (0.0 - 100.0)
  double get progressPercentage {
    if (targetProgress <= 0.0) return isCompleted ? 100.0 : 0.0;
    return (currentProgress / targetProgress * 100.0).clamp(0.0, 100.0);
  }

  SponsorObjective copyWith({
    String? id,
    String? description,
    int? bonusPaymentEur,
    ObjectiveImportance? importance,
    bool? isCompleted,
    double? currentProgress,
    double? targetProgress,
  }) {
    return SponsorObjective(
      id: id ?? this.id,
      description: description ?? this.description,
      bonusPaymentEur: bonusPaymentEur ?? this.bonusPaymentEur,
      importance: importance ?? this.importance,
      isCompleted: isCompleted ?? this.isCompleted,
      currentProgress: currentProgress ?? this.currentProgress,
      targetProgress: targetProgress ?? this.targetProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'bonusPaymentEur': bonusPaymentEur,
      'importance': importance.toJson(),
      'isCompleted': isCompleted,
      'currentProgress': currentProgress,
      'targetProgress': targetProgress,
    };
  }

  factory SponsorObjective.fromJson(Map<String, dynamic> json) {
    return SponsorObjective(
      id: json['id'] as String,
      description: json['description'] as String,
      bonusPaymentEur: (json['bonusPaymentEur'] as num).toInt(),
      importance: ObjectiveImportance.fromJson(json['importance'] as String),
      isCompleted: json['isCompleted'] as bool,
      currentProgress: (json['currentProgress'] as num).toDouble(),
      targetProgress: (json['targetProgress'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SponsorObjective && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SponsorObjective($description, ${progressPercentage.toStringAsFixed(0)}%, done: $isCompleted)';
  }
}

class SponsorContract {
  final String id;
  final String companyName;
  final SponsorIndustry industry;
  final SponsorTier sponsorTier;
  final int annualBudgetEur;
  final int contractDurationYears;
  final double sponsorSatisfaction; // 0.0 - 100.0
  final List<SponsorObjective> objectives;

  const SponsorContract({
    required this.id,
    required this.companyName,
    required this.industry,
    required this.sponsorTier,
    required this.annualBudgetEur,
    required this.contractDurationYears,
    required this.sponsorSatisfaction,
    required this.objectives,
  });

  /// Liczba zrealizowanych celów
  int get completedObjectivesCount => objectives.where((o) => o.isCompleted).length;

  /// Aliasy dla zgodności wstecznej
  String get sponsorName => companyName;
  SponsorTier get importanceTier => sponsorTier;

  /// Łączna liczba wyznaczonych celów
  int get totalObjectivesCount => objectives.length;

  /// Czy wszystkie cele zostały spełnione
  bool get allObjectivesCompleted =>
      objectives.isNotEmpty && objectives.every((o) => o.isCompleted);

  /// Łączna suma potencjalnych premii za zrealizowane cele sponsorskie w Euro
  int get totalEarnedBonusesEur {
    int sum = 0;
    for (final obj in objectives) {
      if (obj.isCompleted) {
        sum += obj.bonusPaymentEur;
      }
    }
    return sum;
  }

  SponsorContract copyWith({
    String? id,
    String? companyName,
    SponsorIndustry? industry,
    SponsorTier? sponsorTier,
    int? annualBudgetEur,
    int? contractDurationYears,
    double? sponsorSatisfaction,
    List<SponsorObjective>? objectives,
  }) {
    return SponsorContract(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      industry: industry ?? this.industry,
      sponsorTier: sponsorTier ?? this.sponsorTier,
      annualBudgetEur: annualBudgetEur ?? this.annualBudgetEur,
      contractDurationYears: contractDurationYears ?? this.contractDurationYears,
      sponsorSatisfaction: sponsorSatisfaction ?? this.sponsorSatisfaction,
      objectives: objectives != null
          ? List<SponsorObjective>.unmodifiable(objectives)
          : this.objectives,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'industry': industry.toJson(),
      'sponsorTier': sponsorTier.toJson(),
      'annualBudgetEur': annualBudgetEur,
      'contractDurationYears': contractDurationYears,
      'sponsorSatisfaction': sponsorSatisfaction,
      'objectives': objectives.map((o) => o.toJson()).toList(),
    };
  }

  factory SponsorContract.fromJson(Map<String, dynamic> json) {
    return SponsorContract(
      id: json['id'] as String,
      companyName: json['companyName'] as String,
      industry: SponsorIndustry.fromJson(json['industry'] as String),
      sponsorTier: SponsorTier.fromJson(json['sponsorTier'] as String),
      annualBudgetEur: (json['annualBudgetEur'] as num).toInt(),
      contractDurationYears: (json['contractDurationYears'] as num).toInt(),
      sponsorSatisfaction: (json['sponsorSatisfaction'] as num).toDouble(),
      objectives: (json['objectives'] as List<dynamic>?)
              ?.map((e) => SponsorObjective.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SponsorContract && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SponsorContract($companyName, tier: ${sponsorTier.name}, budget: €$annualBudgetEur/rok, satisfaction: ${sponsorSatisfaction.toStringAsFixed(1)}%)';
  }
}

