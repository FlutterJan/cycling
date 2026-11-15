enum FrameCategory {
  aero,
  lightweightClimbing,
  allRounder,
  cobbleEndurance,
  timeTrial;

  String toJson() => name;

  static FrameCategory fromJson(String value) {
    return FrameCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => FrameCategory.allRounder,
    );
  }
}

class FrameModel {
  final String id;
  final String brandId;
  final String name;
  final FrameCategory category;
  final int weightGrams; // np. 680g (ultralekka rama górska) do 1150g (aero/TT)
  final double aeroCdaModifier; // np. -0.018 dla aero, +0.005 dla endurance
  final double stiffnessToWeightIndex; // Wpływ na transfer mocy w sprincie i na podjazdach (np. 1.0 - 2.5)
  final double comfortCompliance; // Tłumienie drgań na brukach i nierównościach (0.0 - 1.0)
  final int priceEur;
  final String mesh3dAssetPath; // Ścieżka do pliku siatki 3D (.gltf/.glb)
  final String primaryColorHex;

  const FrameModel({
    required this.id,
    required this.brandId,
    required this.name,
    required this.category,
    required this.weightGrams,
    required this.aeroCdaModifier,
    required this.stiffnessToWeightIndex,
    required this.comfortCompliance,
    required this.priceEur,
    required this.mesh3dAssetPath,
    required this.primaryColorHex,
  });

  /// Waga ramy w kilogramach
  double get weightKg => weightGrams / 1000.0;

  FrameModel copyWith({
    String? id,
    String? brandId,
    String? name,
    FrameCategory? category,
    int? weightGrams,
    double? aeroCdaModifier,
    double? stiffnessToWeightIndex,
    double? comfortCompliance,
    int? priceEur,
    String? mesh3dAssetPath,
    String? primaryColorHex,
  }) {
    return FrameModel(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      name: name ?? this.name,
      category: category ?? this.category,
      weightGrams: weightGrams ?? this.weightGrams,
      aeroCdaModifier: aeroCdaModifier ?? this.aeroCdaModifier,
      stiffnessToWeightIndex: stiffnessToWeightIndex ?? this.stiffnessToWeightIndex,
      comfortCompliance: comfortCompliance ?? this.comfortCompliance,
      priceEur: priceEur ?? this.priceEur,
      mesh3dAssetPath: mesh3dAssetPath ?? this.mesh3dAssetPath,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brandId': brandId,
      'name': name,
      'category': category.toJson(),
      'weightGrams': weightGrams,
      'aeroCdaModifier': aeroCdaModifier,
      'stiffnessToWeightIndex': stiffnessToWeightIndex,
      'comfortCompliance': comfortCompliance,
      'priceEur': priceEur,
      'mesh3dAssetPath': mesh3dAssetPath,
      'primaryColorHex': primaryColorHex,
    };
  }

  factory FrameModel.fromJson(Map<String, dynamic> json) {
    return FrameModel(
      id: json['id'] as String,
      brandId: json['brandId'] as String,
      name: json['name'] as String,
      category: FrameCategory.fromJson(json['category'] as String),
      weightGrams: (json['weightGrams'] as num).toInt(),
      aeroCdaModifier: (json['aeroCdaModifier'] as num).toDouble(),
      stiffnessToWeightIndex: (json['stiffnessToWeightIndex'] as num).toDouble(),
      comfortCompliance: (json['comfortCompliance'] as num).toDouble(),
      priceEur: (json['priceEur'] as num).toInt(),
      mesh3dAssetPath: json['mesh3dAssetPath'] as String,
      primaryColorHex: json['primaryColorHex'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FrameModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FrameModel($name, ${category.name}, ${weightGrams}g, CdA: ${aeroCdaModifier >= 0 ? "+" : ""}$aeroCdaModifier)';
  }
}

