class GroupsetModel {
  final String id;
  final String brandId;
  final String name;
  final int weightGrams; // Masa kompletnej grupy (klamkomanetki, przerzutki, korba, kaseta, łańcuch, hamulce tarczowe) np. 2050 - 2500g
  final bool isElectronic; // Elektroniczna zmiana biegów (Di2, AXS, Super Record EPS)
  final int speedCount; // np. 12 biegów
  final double mechanicalEfficiency; // Sprawność przekładni (np. 0.978 - 0.985)
  final int priceEur;

  const GroupsetModel({
    required this.id,
    required this.brandId,
    required this.name,
    required this.weightGrams,
    required this.isElectronic,
    required this.speedCount,
    required this.mechanicalEfficiency,
    required this.priceEur,
  });

  double get weightKg => weightGrams / 1000.0;

  GroupsetModel copyWith({
    String? id,
    String? brandId,
    String? name,
    int? weightGrams,
    bool? isElectronic,
    int? speedCount,
    double? mechanicalEfficiency,
    int? priceEur,
  }) {
    return GroupsetModel(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      name: name ?? this.name,
      weightGrams: weightGrams ?? this.weightGrams,
      isElectronic: isElectronic ?? this.isElectronic,
      speedCount: speedCount ?? this.speedCount,
      mechanicalEfficiency: mechanicalEfficiency ?? this.mechanicalEfficiency,
      priceEur: priceEur ?? this.priceEur,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brandId': brandId,
      'name': name,
      'weightGrams': weightGrams,
      'isElectronic': isElectronic,
      'speedCount': speedCount,
      'mechanicalEfficiency': mechanicalEfficiency,
      'priceEur': priceEur,
    };
  }

  factory GroupsetModel.fromJson(Map<String, dynamic> json) {
    return GroupsetModel(
      id: json['id'] as String,
      brandId: json['brandId'] as String,
      name: json['name'] as String,
      weightGrams: (json['weightGrams'] as num).toInt(),
      isElectronic: json['isElectronic'] as bool,
      speedCount: (json['speedCount'] as num).toInt(),
      mechanicalEfficiency: (json['mechanicalEfficiency'] as num).toDouble(),
      priceEur: (json['priceEur'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupsetModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GroupsetModel($name, electronic: $isElectronic, ${weightGrams}g)';
  }
}

