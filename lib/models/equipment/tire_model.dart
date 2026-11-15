class TireModel {
  final String id;
  final String brandId;
  final String name;
  final int widthMm; // Szerokość opony w mm (np. 25, 28, 30, 32)
  final int weightGrams; // Masa jednej opony w gramach (np. 220g - 310g)
  final double rollingResistanceCrr; // Współczynnik oporu toczenia Crr (np. 0.0033 dla tubeless TT do 0.0050 dla opony treningowej)
  final double punctureResistanceIndex; // Odporność na przebicia (1.0 = opona czasowa bez wkładki, do 5.0 = pancerny pancerz kevlarowy)
  final double wetGripIndex; // Przyczepność na mokrej nawierzchni (1.0 - 5.0)
  final bool isTubeless;
  final int priceEur;

  const TireModel({
    required this.id,
    required this.brandId,
    required this.name,
    required this.widthMm,
    required this.weightGrams,
    required this.rollingResistanceCrr,
    required this.punctureResistanceIndex,
    required this.wetGripIndex,
    required this.isTubeless,
    required this.priceEur,
  });

  double get weightKg => weightGrams / 1000.0;

  TireModel copyWith({
    String? id,
    String? brandId,
    String? name,
    int? widthMm,
    int? weightGrams,
    double? rollingResistanceCrr,
    double? punctureResistanceIndex,
    double? wetGripIndex,
    bool? isTubeless,
    int? priceEur,
  }) {
    return TireModel(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      name: name ?? this.name,
      widthMm: widthMm ?? this.widthMm,
      weightGrams: weightGrams ?? this.weightGrams,
      rollingResistanceCrr: rollingResistanceCrr ?? this.rollingResistanceCrr,
      punctureResistanceIndex: punctureResistanceIndex ?? this.punctureResistanceIndex,
      wetGripIndex: wetGripIndex ?? this.wetGripIndex,
      isTubeless: isTubeless ?? this.isTubeless,
      priceEur: priceEur ?? this.priceEur,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brandId': brandId,
      'name': name,
      'widthMm': widthMm,
      'weightGrams': weightGrams,
      'rollingResistanceCrr': rollingResistanceCrr,
      'punctureResistanceIndex': punctureResistanceIndex,
      'wetGripIndex': wetGripIndex,
      'isTubeless': isTubeless,
      'priceEur': priceEur,
    };
  }

  factory TireModel.fromJson(Map<String, dynamic> json) {
    return TireModel(
      id: json['id'] as String,
      brandId: json['brandId'] as String,
      name: json['name'] as String,
      widthMm: (json['widthMm'] as num).toInt(),
      weightGrams: (json['weightGrams'] as num).toInt(),
      rollingResistanceCrr: (json['rollingResistanceCrr'] as num).toDouble(),
      punctureResistanceIndex: (json['punctureResistanceIndex'] as num).toDouble(),
      wetGripIndex: (json['wetGripIndex'] as num).toDouble(),
      isTubeless: json['isTubeless'] as bool,
      priceEur: (json['priceEur'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TireModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TireModel($name, ${widthMm}mm, Crr: $rollingResistanceCrr, tubeless: $isTubeless)';
  }
}

