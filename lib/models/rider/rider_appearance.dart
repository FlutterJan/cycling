enum BodyBuildType {
  climberLean,
  allRounder,
  sprinterMuscular;

  String toJson() => name;

  static BodyBuildType fromJson(String value) {
    return BodyBuildType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BodyBuildType.allRounder,
    );
  }
}

class RiderAppearance {
  final int faceShapeIndex;
  final String skinToneHex;
  final int hairStyleIndex;
  final String hairColorHex;
  final int facialHairIndex;
  final String glassesModelId;
  final String glassesLensColorHex;
  final String helmetModelId;
  final String shoeColorHex;
  final double sockHeightProportion;
  final BodyBuildType bodyBuildType;

  const RiderAppearance({
    required this.faceShapeIndex,
    required this.skinToneHex,
    required this.hairStyleIndex,
    required this.hairColorHex,
    required this.facialHairIndex,
    required this.glassesModelId,
    required this.glassesLensColorHex,
    required this.helmetModelId,
    required this.shoeColorHex,
    required this.sockHeightProportion,
    required this.bodyBuildType,
  });

  RiderAppearance copyWith({
    int? faceShapeIndex,
    String? skinToneHex,
    int? hairStyleIndex,
    String? hairColorHex,
    int? facialHairIndex,
    String? glassesModelId,
    String? glassesLensColorHex,
    String? helmetModelId,
    String? shoeColorHex,
    double? sockHeightProportion,
    BodyBuildType? bodyBuildType,
  }) {
    return RiderAppearance(
      faceShapeIndex: faceShapeIndex ?? this.faceShapeIndex,
      skinToneHex: skinToneHex ?? this.skinToneHex,
      hairStyleIndex: hairStyleIndex ?? this.hairStyleIndex,
      hairColorHex: hairColorHex ?? this.hairColorHex,
      facialHairIndex: facialHairIndex ?? this.facialHairIndex,
      glassesModelId: glassesModelId ?? this.glassesModelId,
      glassesLensColorHex: glassesLensColorHex ?? this.glassesLensColorHex,
      helmetModelId: helmetModelId ?? this.helmetModelId,
      shoeColorHex: shoeColorHex ?? this.shoeColorHex,
      sockHeightProportion: sockHeightProportion ?? this.sockHeightProportion,
      bodyBuildType: bodyBuildType ?? this.bodyBuildType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'faceShapeIndex': faceShapeIndex,
      'skinToneHex': skinToneHex,
      'hairStyleIndex': hairStyleIndex,
      'hairColorHex': hairColorHex,
      'facialHairIndex': facialHairIndex,
      'glassesModelId': glassesModelId,
      'glassesLensColorHex': glassesLensColorHex,
      'helmetModelId': helmetModelId,
      'shoeColorHex': shoeColorHex,
      'sockHeightProportion': sockHeightProportion,
      'bodyBuildType': bodyBuildType.toJson(),
    };
  }

  factory RiderAppearance.fromJson(Map<String, dynamic> json) {
    return RiderAppearance(
      faceShapeIndex: (json['faceShapeIndex'] as num).toInt(),
      skinToneHex: json['skinToneHex'] as String,
      hairStyleIndex: (json['hairStyleIndex'] as num).toInt(),
      hairColorHex: json['hairColorHex'] as String,
      facialHairIndex: (json['facialHairIndex'] as num).toInt(),
      glassesModelId: json['glassesModelId'] as String,
      glassesLensColorHex: json['glassesLensColorHex'] as String,
      helmetModelId: json['helmetModelId'] as String,
      shoeColorHex: json['shoeColorHex'] as String,
      sockHeightProportion: (json['sockHeightProportion'] as num).toDouble(),
      bodyBuildType: BodyBuildType.fromJson(json['bodyBuildType'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiderAppearance &&
        other.faceShapeIndex == faceShapeIndex &&
        other.skinToneHex == skinToneHex &&
        other.hairStyleIndex == hairStyleIndex &&
        other.hairColorHex == hairColorHex &&
        other.facialHairIndex == facialHairIndex &&
        other.glassesModelId == glassesModelId &&
        other.glassesLensColorHex == glassesLensColorHex &&
        other.helmetModelId == helmetModelId &&
        other.shoeColorHex == shoeColorHex &&
        other.sockHeightProportion == sockHeightProportion &&
        other.bodyBuildType == bodyBuildType;
  }

  @override
  int get hashCode {
    return Object.hash(
      faceShapeIndex,
      skinToneHex,
      hairStyleIndex,
      hairColorHex,
      facialHairIndex,
      glassesModelId,
      glassesLensColorHex,
      helmetModelId,
      shoeColorHex,
      sockHeightProportion,
      bodyBuildType,
    );
  }

  @override
  String toString() {
    return 'RiderAppearance(face: $faceShapeIndex, hair: $hairStyleIndex, glasses: $glassesModelId, helmet: $helmetModelId, build: ${bodyBuildType.name})';
  }
}

