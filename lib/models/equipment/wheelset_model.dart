class WheelsetModel {
  final String id;
  final String brandId;
  final String name;
  final int rimDepthMm; // Wysokość stożka w mm (np. 33, 45, 60, 80; 0 lub 100 dla pełnego dysku TT)
  final int weightGrams; // Masa kompletu kół (np. 1150g - 1650g)
  final double aeroCdaModifier; // Zysk aerodynamiczny (np. -0.008 dla stożka 50mm, -0.018 dla dysku)
  final double crosswindStabilityPenalty; // Kara za boczny wiatr (0.0 dla niskiego profilu, do 1.0 dla dysku)
  final double momentOfInertia; // Moment bezwładności obrotowej [kg*m^2] (wpływa na zrywność i przyspieszenie)
  final double hubEngagementDragWatts; // Opory toczenia łożysk piasty ceramicznej/stalowej [W]
  final int priceEur;

  const WheelsetModel({
    required this.id,
    required this.brandId,
    required this.name,
    required this.rimDepthMm,
    required this.weightGrams,
    required this.aeroCdaModifier,
    required this.crosswindStabilityPenalty,
    required this.momentOfInertia,
    required this.hubEngagementDragWatts,
    required this.priceEur,
  });

  /// Waga kompletu kół w kilogramach
  double get weightKg => weightGrams / 1000.0;

  /// Czy koło jest pełnym dyskiem aero (Disc wheel)
  bool get isDiscWheel => rimDepthMm >= 90 || rimDepthMm == 0;

  WheelsetModel copyWith({
    String? id,
    String? brandId,
    String? name,
    int? rimDepthMm,
    int? weightGrams,
    double? aeroCdaModifier,
    double? crosswindStabilityPenalty,
    double? momentOfInertia,
    double? hubEngagementDragWatts,
    int? priceEur,
  }) {
    return WheelsetModel(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      name: name ?? this.name,
      rimDepthMm: rimDepthMm ?? this.rimDepthMm,
      weightGrams: weightGrams ?? this.weightGrams,
      aeroCdaModifier: aeroCdaModifier ?? this.aeroCdaModifier,
      crosswindStabilityPenalty: crosswindStabilityPenalty ?? this.crosswindStabilityPenalty,
      momentOfInertia: momentOfInertia ?? this.momentOfInertia,
      hubEngagementDragWatts: hubEngagementDragWatts ?? this.hubEngagementDragWatts,
      priceEur: priceEur ?? this.priceEur,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brandId': brandId,
      'name': name,
      'rimDepthMm': rimDepthMm,
      'weightGrams': weightGrams,
      'aeroCdaModifier': aeroCdaModifier,
      'crosswindStabilityPenalty': crosswindStabilityPenalty,
      'momentOfInertia': momentOfInertia,
      'hubEngagementDragWatts': hubEngagementDragWatts,
      'priceEur': priceEur,
    };
  }

  factory WheelsetModel.fromJson(Map<String, dynamic> json) {
    return WheelsetModel(
      id: json['id'] as String,
      brandId: json['brandId'] as String,
      name: json['name'] as String,
      rimDepthMm: (json['rimDepthMm'] as num).toInt(),
      weightGrams: (json['weightGrams'] as num).toInt(),
      aeroCdaModifier: (json['aeroCdaModifier'] as num).toDouble(),
      crosswindStabilityPenalty: (json['crosswindStabilityPenalty'] as num).toDouble(),
      momentOfInertia: (json['momentOfInertia'] as num).toDouble(),
      hubEngagementDragWatts: (json['hubEngagementDragWatts'] as num).toDouble(),
      priceEur: (json['priceEur'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WheelsetModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'WheelsetModel($name, ${rimDepthMm}mm, ${weightGrams}g, Inertia: $momentOfInertia)';
  }
}

