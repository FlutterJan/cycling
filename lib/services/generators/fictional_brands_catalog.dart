import '../../models/equipment/complete_bike.dart';
import '../../models/equipment/frame_model.dart';
import '../../models/equipment/groupset_model.dart';
import '../../models/equipment/tire_model.dart';
import '../../models/equipment/wheelset_model.dart';
import '../../models/team/bike_manufacturer_deal.dart';

/// Informacje o fikcyjnej marce rowerowej i komponentowej.
class FictionalBrand {
  final String id;
  final String name;
  final String countryIso;
  final int prestige; // 1-5 gwiazdek
  final String description;
  final String primaryColorHex;
  final List<FrameModel> frames;
  final List<WheelsetModel> wheelsets;
  final List<GroupsetModel> groupsets;
  final List<TireModel> tires;

  const FictionalBrand({
    required this.id,
    required this.name,
    required this.countryIso,
    required this.prestige,
    required this.description,
    required this.primaryColorHex,
    required this.frames,
    required this.wheelsets,
    required this.groupsets,
    required this.tires,
  });

  FictionalBrand copyWith({
    String? id,
    String? name,
    String? countryIso,
    int? prestige,
    String? description,
    String? primaryColorHex,
    List<FrameModel>? frames,
    List<WheelsetModel>? wheelsets,
    List<GroupsetModel>? groupsets,
    List<TireModel>? tires,
  }) {
    return FictionalBrand(
      id: id ?? this.id,
      name: name ?? this.name,
      countryIso: countryIso ?? this.countryIso,
      prestige: prestige ?? this.prestige,
      description: description ?? this.description,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      frames: frames != null ? List<FrameModel>.unmodifiable(frames) : this.frames,
      wheelsets: wheelsets != null ? List<WheelsetModel>.unmodifiable(wheelsets) : this.wheelsets,
      groupsets: groupsets != null ? List<GroupsetModel>.unmodifiable(groupsets) : this.groupsets,
      tires: tires != null ? List<TireModel>.unmodifiable(tires) : this.tires,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'countryIso': countryIso,
      'prestige': prestige,
      'description': description,
      'primaryColorHex': primaryColorHex,
      'frames': frames.map((f) => f.toJson()).toList(),
      'wheelsets': wheelsets.map((w) => w.toJson()).toList(),
      'groupsets': groupsets.map((g) => g.toJson()).toList(),
      'tires': tires.map((t) => t.toJson()).toList(),
    };
  }

  factory FictionalBrand.fromJson(Map<String, dynamic> json) {
    return FictionalBrand(
      id: json['id'] as String,
      name: json['name'] as String,
      countryIso: json['countryIso'] as String,
      prestige: (json['prestige'] as num).toInt(),
      description: json['description'] as String,
      primaryColorHex: json['primaryColorHex'] as String,
      frames: (json['frames'] as List<dynamic>)
          .map((e) => FrameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      wheelsets: (json['wheelsets'] as List<dynamic>)
          .map((e) => WheelsetModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      groupsets: (json['groupsets'] as List<dynamic>)
          .map((e) => GroupsetModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      tires: (json['tires'] as List<dynamic>)
          .map((e) => TireModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String toString() {
    return 'FictionalBrand($name, $countryIso, $prestige★, frames: ${frames.length}, wheels: ${wheelsets.length})';
  }
}

/// Bogaty, w 100% bezpieczny prawnie katalog fikcyjnych, realistycznych marek rowerowych i komponentowych.
///
/// Zawiera 15 zbalansowanych producentów z dokładnymi fizycznymi parametrami (waga co do grama,
/// modyfikatory CdA, opory toczenia Crr, momenty bezwładności i sprawności napędów).
class FictionalBrandsCatalog {
  FictionalBrandsCatalog._();

  static final List<FictionalBrand> _brands = _generateBrands();

  /// Wszystkie 15 marek dostępnych w grze
  static List<FictionalBrand> get allBrands => List.unmodifiable(_brands);

  /// Szybkie indeksy wyszukiwania
  static final Map<String, FictionalBrand> _brandsMap = {
    for (final b in _brands) b.id: b,
  };

  static final Map<String, FrameModel> _framesMap = {
    for (final b in _brands)
      for (final f in b.frames) f.id: f,
  };

  static final Map<String, WheelsetModel> _wheelsetsMap = {
    for (final b in _brands)
      for (final w in b.wheelsets) w.id: w,
  };

  static final Map<String, GroupsetModel> _groupsetsMap = {
    for (final b in _brands)
      for (final g in b.groupsets) g.id: g,
  };

  static final Map<String, TireModel> _tiresMap = {
    for (final b in _brands)
      for (final t in b.tires) t.id: t,
  };

  /// Pobiera markę po identyfikatorze
  static FictionalBrand? getBrand(String brandId) => _brandsMap[brandId];

  /// Pobiera wszystkie ramy w grze (45 modeli)
  static List<FrameModel> get allFrames => List.unmodifiable(_framesMap.values);

  /// Pobiera wszystkie zestawy kół w grze (45 modeli)
  static List<WheelsetModel> get allWheelsets => List.unmodifiable(_wheelsetsMap.values);

  /// Pobiera wszystkie grupy osprzętu w grze
  static List<GroupsetModel> get allGroupsets => List.unmodifiable(_groupsetsMap.values);

  /// Pobiera wszystkie opony w grze
  static List<TireModel> get allTires => List.unmodifiable(_tiresMap.values);

  /// Wyszukiwanie komponentów po unikalnym ID
  static FrameModel? getFrame(String id) => _framesMap[id];
  static WheelsetModel? getWheelset(String id) => _wheelsetsMap[id];
  static GroupsetModel? getGroupset(String id) => _groupsetsMap[id];
  static TireModel? getTire(String id) => _tiresMap[id];

  /// Pobiera ramy według zadanej kategorii (aero, lightweightClimbing, timeTrial)
  static List<FrameModel> getFramesByCategory(FrameCategory category) {
    return _framesMap.values.where((f) => f.category == category).toList();
  }

  /// Najlżejsza rama górska w katalogu
  static FrameModel get lightestClimbingFrame {
    return _framesMap.values
        .where((f) => f.category == FrameCategory.lightweightClimbing)
        .reduce((a, b) => a.weightGrams < b.weightGrams ? a : b);
  }

  /// Najbardziej aerodynamiczna rama szosowa
  static FrameModel get mostAeroRoadFrame {
    return _framesMap.values
        .where((f) => f.category == FrameCategory.aero)
        .reduce((a, b) => a.aeroCdaModifier < b.aeroCdaModifier ? a : b);
  }

  /// Najszybsza rama do jazdy na czas (TT)
  static FrameModel get fastestTimeTrialFrame {
    return _framesMap.values
        .where((f) => f.category == FrameCategory.timeTrial)
        .reduce((a, b) => a.aeroCdaModifier < b.aeroCdaModifier ? a : b);
  }

  /// Najlżejszy zestaw kół wspinaczkowych
  static WheelsetModel get lightestClimbingWheelset {
    return _wheelsetsMap.values
        .where((w) => w.rimDepthMm <= 35)
        .reduce((a, b) => a.weightGrams < b.weightGrams ? a : b);
  }

  /// Najbardziej aerodynamiczny zestaw kół szosowych ze stożkiem 50-60mm
  static WheelsetModel get mostAeroRoadWheelset {
    return _wheelsetsMap.values
        .where((w) => w.rimDepthMm >= 45 && w.rimDepthMm <= 65)
        .reduce((a, b) => a.aeroCdaModifier < b.aeroCdaModifier ? a : b);
  }

  /// Najszybszy pełny dysk aero do czasówek
  static WheelsetModel get fastestDiscWheelset {
    return _wheelsetsMap.values
        .where((w) => w.isDiscWheel)
        .reduce((a, b) => a.aeroCdaModifier < b.aeroCdaModifier ? a : b);
  }

  /// Najszybsza opona z najniższym współczynnikiem oporu toczenia Crr
  static TireModel get fastestTire {
    return _tiresMap.values
        .reduce((a, b) => a.rollingResistanceCrr < b.rollingResistanceCrr ? a : b);
  }

  /// Opona o najwyższej odporności na przebicia (idealna na bruki Paryż-Roubaix)
  static TireModel get toughestCobbleTire {
    return _tiresMap.values
        .reduce((a, b) => a.punctureResistanceIndex > b.punctureResistanceIndex ? a : b);
  }

  /// Zestawia gotowy kompletny rower wyścigowy z komponentów danej marki
  static CompleteBike assembleBike({
    required String brandId,
    required FrameCategory frameCategory,
    int? cockpitWidthMm,
    double? hoodInwardTiltDegrees,
    bool slammedStem = true,
  }) {
    final brand = getBrand(brandId) ?? _brands.first;

    final frame = brand.frames.firstWhere(
      (f) => f.category == frameCategory,
      orElse: () => brand.frames.first,
    );

    WheelsetModel wheelset;
    if (frameCategory == FrameCategory.timeTrial) {
      wheelset = brand.wheelsets.firstWhere(
        (w) => w.isDiscWheel,
        orElse: () => brand.wheelsets.last,
      );
    } else if (frameCategory == FrameCategory.lightweightClimbing) {
      wheelset = brand.wheelsets.firstWhere(
        (w) => w.rimDepthMm <= 35,
        orElse: () => brand.wheelsets.first,
      );
    } else {
      wheelset = brand.wheelsets.firstWhere(
        (w) => w.rimDepthMm >= 45 && w.rimDepthMm <= 65,
        orElse: () => brand.wheelsets[1],
      );
    }

    final groupset = brand.groupsets.first;
    final tire = brand.tires.first;

    return CompleteBike(
      id: 'bike_${brand.id}_${frame.category.name}',
      name: '${brand.name} ${frame.name} Team Pro',
      frame: frame,
      wheelset: wheelset,
      groupset: groupset,
      tire: tire,
      cockpitWidthMm: cockpitWidthMm ?? (frameCategory == FrameCategory.aero ? 380 : 400),
      hoodInwardTiltDegrees: hoodInwardTiltDegrees ?? (frameCategory == FrameCategory.aero ? 12.0 : 6.0),
      slammedStem: slammedStem,
    );
  }

  /// Tworzy realistyczny kontrakt sponsorski z producentem rowerów
  static BikeManufacturerDeal createManufacturerDeal({
    required String brandId,
    int contractYearsLeft = 2,
    int minimumUciRankingRequired = 18,
  }) {
    final brand = getBrand(brandId) ?? _brands.first;
    final int cash = (brand.prestige * 450000) + 200000;
    final int bikes = (brand.prestige * 18) + 30;
    final int rdLevel = (brand.prestige * 16) + 18;

    return BikeManufacturerDeal(
      manufacturerId: brand.id,
      manufacturerName: brand.name,
      prestigeLevel: brand.prestige,
      annualCashContributionEur: cash,
      freeBikesQuota: bikes,
      researchAndDevelopmentLevel: rdLevel.clamp(1, 100),
      suppliedFrameIds: brand.frames.map((f) => f.id).toList(),
      suppliedWheelsetIds: brand.wheelsets.map((w) => w.id).toList(),
      contractYearsLeft: contractYearsLeft,
      minimumUciRankingRequired: minimumUciRankingRequired,
    );
  }

  /// Główny generator 15 fikcyjnych marek
  static List<FictionalBrand> _generateBrands() {
    return [
      // 1. Aethel Bikes (Wielka Brytania - arystokracja inżynierii i CFD)
      const FictionalBrand(
        id: 'brand_aethel',
        name: 'Aethel Bikes',
        countryIso: 'GBR',
        prestige: 5,
        description: 'Cambridge Aerodynamics & Aerospace Carbon Craftsmanship.',
        primaryColorHex: '#004225', // Racing Green
        frames: [
          FrameModel(
            id: 'frame_aethel_aero',
            brandId: 'brand_aethel',
            name: 'Aethel Excalibur Aero',
            category: FrameCategory.aero,
            weightGrams: 895,
            aeroCdaModifier: -0.0210,
            stiffnessToWeightIndex: 2.35,
            comfortCompliance: 0.42,
            priceEur: 5200,
            mesh3dAssetPath: 'assets/models/frames/aethel_excalibur.glb',
            primaryColorHex: '#004225',
          ),
          FrameModel(
            id: 'frame_aethel_climb',
            brandId: 'brand_aethel',
            name: 'Aethel Pendragon SL',
            category: FrameCategory.lightweightClimbing,
            weightGrams: 685,
            aeroCdaModifier: -0.0075,
            stiffnessToWeightIndex: 2.55,
            comfortCompliance: 0.68,
            priceEur: 5100,
            mesh3dAssetPath: 'assets/models/frames/aethel_pendragon.glb',
            primaryColorHex: '#004225',
          ),
          FrameModel(
            id: 'frame_aethel_tt',
            brandId: 'brand_aethel',
            name: 'Aethel Chronos TT',
            category: FrameCategory.timeTrial,
            weightGrams: 1140,
            aeroCdaModifier: -0.0335,
            stiffnessToWeightIndex: 2.65,
            comfortCompliance: 0.28,
            priceEur: 6800,
            mesh3dAssetPath: 'assets/models/frames/aethel_chronos.glb',
            primaryColorHex: '#004225',
          ),
        ],
        wheelsets: [
          WheelsetModel(
            id: 'wheels_aethel_32',
            brandId: 'brand_aethel',
            name: 'Aethel Zephyr 32 Carbon',
            rimDepthMm: 32,
            weightGrams: 1210,
            aeroCdaModifier: -0.0055,
            crosswindStabilityPenalty: 0.08,
            momentOfInertia: 0.088,
            hubEngagementDragWatts: 0.75,
            priceEur: 2200,
          ),
          WheelsetModel(
            id: 'wheels_aethel_55',
            brandId: 'brand_aethel',
            name: 'Aethel Zephyr 55 Aero',
            rimDepthMm: 55,
            weightGrams: 1420,
            aeroCdaModifier: -0.0125,
            crosswindStabilityPenalty: 0.38,
            momentOfInertia: 0.118,
            hubEngagementDragWatts: 0.80,
            priceEur: 2450,
          ),
          WheelsetModel(
            id: 'wheels_aethel_disc',
            brandId: 'brand_aethel',
            name: 'Aethel Vortex Disc TT',
            rimDepthMm: 100,
            weightGrams: 1690,
            aeroCdaModifier: -0.0220,
            crosswindStabilityPenalty: 0.85,
            momentOfInertia: 0.155,
            hubEngagementDragWatts: 0.90,
            priceEur: 2900,
          ),
        ],
        groupsets: [
          GroupsetModel(
            id: 'group_aethel_sov12',
            brandId: 'brand_aethel',
            name: 'Aethel Sovereign Electronic 12s',
            weightGrams: 2095,
            isElectronic: true,
            speedCount: 12,
            mechanicalEfficiency: 0.985,
            priceEur: 2950,
          ),
        ],
        tires: [
          TireModel(
            id: 'tire_aethel_tlr28',
            brandId: 'brand_aethel',
            name: 'Aethel Velocita Corsa TLR',
            widthMm: 28,
            weightGrams: 240,
            rollingResistanceCrr: 0.00345,
            punctureResistanceIndex: 3.8,
            wetGripIndex: 4.5,
            isTubeless: true,
            priceEur: 85,
          ),
        ],
      ),

      // 2. Veloce Carbon (Włochy - lekkość, wspinaczka, agresywny design)
      const FictionalBrand(
        id: 'brand_veloce',
        name: 'Veloce Carbon',
        countryIso: 'ITA',
        prestige: 5,
        description: 'Passione per la salita. Pure Italian carbon lightweight perfection.',
        primaryColorHex: '#A31D1D', // Corsa Red
        frames: [
          FrameModel(
            id: 'frame_veloce_aero',
            brandId: 'brand_veloce',
            name: 'Veloce Mach 1 Aero',
            category: FrameCategory.aero,
            weightGrams: 920,
            aeroCdaModifier: -0.0195,
            stiffnessToWeightIndex: 2.30,
            comfortCompliance: 0.45,
            priceEur: 4900,
            mesh3dAssetPath: 'assets/models/frames/veloce_mach1.glb',
            primaryColorHex: '#A31D1D',
          ),
          FrameModel(
            id: 'frame_veloce_climb',
            brandId: 'brand_veloce',
            name: 'Veloce Superleggera Oltre',
            category: FrameCategory.lightweightClimbing,
            weightGrams: 670,
            aeroCdaModifier: -0.0065,
            stiffnessToWeightIndex: 2.60,
            comfortCompliance: 0.65,
            priceEur: 5400,
            mesh3dAssetPath: 'assets/models/frames/veloce_superleggera.glb',
            primaryColorHex: '#A31D1D',
          ),
          FrameModel(
            id: 'frame_veloce_tt',
            brandId: 'brand_veloce',
            name: 'Veloce Freccia TT',
            category: FrameCategory.timeTrial,
            weightGrams: 1180,
            aeroCdaModifier: -0.0315,
            stiffnessToWeightIndex: 2.50,
            comfortCompliance: 0.30,
            priceEur: 6200,
            mesh3dAssetPath: 'assets/models/frames/veloce_freccia.glb',
            primaryColorHex: '#A31D1D',
          ),
        ],
        wheelsets: [
          WheelsetModel(
            id: 'wheels_veloce_30',
            brandId: 'brand_veloce',
            name: 'Veloce Passo 30 Ultra',
            rimDepthMm: 30,
            weightGrams: 1165,
            aeroCdaModifier: -0.0048,
            crosswindStabilityPenalty: 0.06,
            momentOfInertia: 0.084,
            hubEngagementDragWatts: 0.70,
            priceEur: 2400,
          ),
          WheelsetModel(
            id: 'wheels_veloce_50',
            brandId: 'brand_veloce',
            name: 'Veloce Passo 50 Speed',
            rimDepthMm: 50,
            weightGrams: 1385,
            aeroCdaModifier: -0.0118,
            crosswindStabilityPenalty: 0.34,
            momentOfInertia: 0.114,
            hubEngagementDragWatts: 0.75,
            priceEur: 2600,
          ),
          WheelsetModel(
            id: 'wheels_veloce_80',
            brandId: 'brand_veloce',
            name: 'Veloce Passo 80 TT Wheel',
            rimDepthMm: 80,
            weightGrams: 1580,
            aeroCdaModifier: -0.0185,
            crosswindStabilityPenalty: 0.72,
            momentOfInertia: 0.148,
            hubEngagementDragWatts: 0.85,
            priceEur: 2750,
          ),
        ],
        groupsets: [
          GroupsetModel(
            id: 'group_veloce_sr12',
            brandId: 'brand_veloce',
            name: 'Veloce Corsa Super Record 12s',
            weightGrams: 2080,
            isElectronic: true,
            speedCount: 12,
            mechanicalEfficiency: 0.986,
            priceEur: 3100,
          ),
        ],
        tires: [
          TireModel(
            id: 'tire_veloce_tlr28',
            brandId: 'brand_veloce',
            name: 'Veloce Pavimento Tubeless',
            widthMm: 28,
            weightGrams: 245,
            rollingResistanceCrr: 0.00350,
            punctureResistanceIndex: 3.6,
            wetGripIndex: 4.6,
            isTubeless: true,
            priceEur: 88,
          ),
        ],
      ),

      // 3. Kronos Aero Dynamics (Szwajcaria - precyzja tunelu aero i zegarmistrzowska sztywność)
      const FictionalBrand(
        id: 'brand_kronos',
        name: 'Kronos Aero Dynamics',
        countryIso: 'SUI',
        prestige: 5,
        description: 'Swiss precision aerodynamics. Engineered in the wind tunnel.',
        primaryColorHex: '#D32F2F', // Swiss Red
        frames: [
          FrameModel(
            id: 'frame_kronos_aero',
            brandId: 'brand_kronos',
            name: 'Kronos Aerofoil Prime',
            category: FrameCategory.aero,
            weightGrams: 910,
            aeroCdaModifier: -0.0225,
            stiffnessToWeightIndex: 2.45,
            comfortCompliance: 0.38,
            priceEur: 5500,
            mesh3dAssetPath: 'assets/models/frames/kronos_aerofoil.glb',
            primaryColorHex: '#D32F2F',
          ),
          FrameModel(
            id: 'frame_kronos_climb',
            brandId: 'brand_kronos',
            name: 'Kronos Alpinist Carbon',
            category: FrameCategory.lightweightClimbing,
            weightGrams: 710,
            aeroCdaModifier: -0.0080,
            stiffnessToWeightIndex: 2.40,
            comfortCompliance: 0.62,
            priceEur: 4800,
            mesh3dAssetPath: 'assets/models/frames/kronos_alpinist.glb',
            primaryColorHex: '#D32F2F',
          ),
          FrameModel(
            id: 'frame_kronos_tt',
            brandId: 'brand_kronos',
            name: 'Kronos Zeitjaeger TT',
            category: FrameCategory.timeTrial,
            weightGrams: 1110,
            aeroCdaModifier: -0.0350,
            stiffnessToWeightIndex: 2.70,
            comfortCompliance: 0.25,
            priceEur: 7200,
            mesh3dAssetPath: 'assets/models/frames/kronos_zeitjaeger.glb',
            primaryColorHex: '#D32F2F',
          ),
        ],
        wheelsets: [
          WheelsetModel(
            id: 'wheels_kronos_35',
            brandId: 'brand_kronos',
            name: 'Kronos Turbine 35 Light',
            rimDepthMm: 35,
            weightGrams: 1240,
            aeroCdaModifier: -0.0062,
            crosswindStabilityPenalty: 0.10,
            momentOfInertia: 0.091,
            hubEngagementDragWatts: 0.65,
            priceEur: 2350,
          ),
          WheelsetModel(
            id: 'wheels_kronos_58',
            brandId: 'brand_kronos',
            name: 'Kronos Turbine 58 Aero',
            rimDepthMm: 58,
            weightGrams: 1445,
            aeroCdaModifier: -0.0135,
            crosswindStabilityPenalty: 0.42,
            momentOfInertia: 0.122,
            hubEngagementDragWatts: 0.70,
            priceEur: 2650,
          ),
          WheelsetModel(
            id: 'wheels_kronos_disc',
            brandId: 'brand_kronos',
            name: 'Kronos AeroDisc Chrono',
            rimDepthMm: 100,
            weightGrams: 1660,
            aeroCdaModifier: -0.0235,
            crosswindStabilityPenalty: 0.90,
            momentOfInertia: 0.152,
            hubEngagementDragWatts: 0.75,
            priceEur: 3200,
          ),
        ],
        groupsets: [
          GroupsetModel(
            id: 'group_kronos_di12',
            brandId: 'brand_kronos',
            name: 'Kronos SwissPrecision Di-12',
            weightGrams: 2110,
            isElectronic: true,
            speedCount: 12,
            mechanicalEfficiency: 0.987,
            priceEur: 3250,
          ),
        ],
        tires: [
          TireModel(
            id: 'tire_kronos_speed25',
            brandId: 'brand_kronos',
            name: 'Kronos Chrono Speed TLR',
            widthMm: 25,
            weightGrams: 218,
            rollingResistanceCrr: 0.00325,
            punctureResistanceIndex: 2.8,
            wetGripIndex: 4.2,
            isTubeless: true,
            priceEur: 92,
          ),
        ],
      ),

      // 4. Zenith Wheels & Components (USA - szerokie profile, hookless, bezkompromisowa sztywność)
      const FictionalBrand(
        id: 'brand_zenith',
        name: 'Zenith Wheels',
        countryIso: 'USA',
        prestige: 4,
        description: 'California carbon composites revolution. Hookless tubeless specialists.',
        primaryColorHex: '#0D47A1', // Cobalt Blue
        frames: [
          FrameModel(
            id: 'frame_zenith_aero',
            brandId: 'brand_zenith',
            name: 'Zenith Velocity SL',
            category: FrameCategory.aero,
            weightGrams: 935,
            aeroCdaModifier: -0.0190,
            stiffnessToWeightIndex: 2.25,
            comfortCompliance: 0.48,
            priceEur: 4400,
            mesh3dAssetPath: 'assets/models/frames/zenith_velocity.glb',
            primaryColorHex: '#0D47A1',
          ),
          FrameModel(
            id: 'frame_zenith_climb',
            brandId: 'brand_zenith',
            name: 'Zenith Sierra Ultra',
            category: FrameCategory.lightweightClimbing,
            weightGrams: 695,
            aeroCdaModifier: -0.0068,
            stiffnessToWeightIndex: 2.38,
            comfortCompliance: 0.70,
            priceEur: 4600,
            mesh3dAssetPath: 'assets/models/frames/zenith_sierra.glb',
            primaryColorHex: '#0D47A1',
          ),
          FrameModel(
            id: 'frame_zenith_tt',
            brandId: 'brand_zenith',
            name: 'Zenith Apex TimeMachine',
            category: FrameCategory.timeTrial,
            weightGrams: 1160,
            aeroCdaModifier: -0.0305,
            stiffnessToWeightIndex: 2.52,
            comfortCompliance: 0.32,
            priceEur: 5900,
            mesh3dAssetPath: 'assets/models/frames/zenith_timemachine.glb',
            primaryColorHex: '#0D47A1',
          ),
        ],
        wheelsets: [
          WheelsetModel(
            id: 'wheels_zenith_33',
            brandId: 'brand_zenith',
            name: 'Zenith Skyline 33 Hookless',
            rimDepthMm: 33,
            weightGrams: 1195,
            aeroCdaModifier: -0.0052,
            crosswindStabilityPenalty: 0.07,
            momentOfInertia: 0.086,
            hubEngagementDragWatts: 0.80,
            priceEur: 2100,
          ),
          WheelsetModel(
            id: 'wheels_zenith_50',
            brandId: 'brand_zenith',
            name: 'Zenith AeroMax 50 Carbon',
            rimDepthMm: 50,
            weightGrams: 1390,
            aeroCdaModifier: -0.0120,
            crosswindStabilityPenalty: 0.35,
            momentOfInertia: 0.115,
            hubEngagementDragWatts: 0.82,
            priceEur: 2300,
          ),
          WheelsetModel(
            id: 'wheels_zenith_disc',
            brandId: 'brand_zenith',
            name: 'Zenith DiscPro TT',
            rimDepthMm: 100,
            weightGrams: 1720,
            aeroCdaModifier: -0.0215,
            crosswindStabilityPenalty: 0.88,
            momentOfInertia: 0.158,
            hubEngagementDragWatts: 0.95,
            priceEur: 2650,
          ),
        ],
        groupsets: [
          GroupsetModel(
            id: 'group_zenith_w12',
            brandId: 'brand_zenith',
            name: 'Zenith AeroShift Wireless 12',
            weightGrams: 2130,
            isElectronic: true,
            speedCount: 12,
            mechanicalEfficiency: 0.984,
            priceEur: 2700,
          ),
        ],
        tires: [
          TireModel(
            id: 'tire_zenith_race28',
            brandId: 'brand_zenith',
            name: 'Zenith RaceGrip Tubeless 28',
            widthMm: 28,
            weightGrams: 250,
            rollingResistanceCrr: 0.00355,
            punctureResistanceIndex: 4.0,
            wetGripIndex: 4.7,
            isTubeless: true,
            priceEur: 82,
          ),
        ],
      ),

      // 5. Sovereign Drivetrain Systems (Niemcy - maksymalna sprawność, łożyska ceramiczne)
      const FictionalBrand(
        id: 'brand_sovereign',
        name: 'Sovereign Drivetrain',
        countryIso: 'GER',
        prestige: 5,
        description: 'Bavarian mechanical perfection. Zero watt loss drivetrain engineering.',
        primaryColorHex: '#D4AF37', // German Gold
        frames: [
          FrameModel(
            id: 'frame_sovereign_aero',
            brandId: 'brand_sovereign',
            name: 'Sovereign Imperator Aero',
            category: FrameCategory.aero,
            weightGrams: 905,
            aeroCdaModifier: -0.0205,
            stiffnessToWeightIndex: 2.40,
            comfortCompliance: 0.40,
            priceEur: 5100,
            mesh3dAssetPath: 'assets/models/frames/sovereign_imperator.glb',
            primaryColorHex: '#D4AF37',
          ),
          FrameModel(
            id: 'frame_sovereign_climb',
            brandId: 'brand_sovereign',
            name: 'Sovereign Edelweiss SL',
            category: FrameCategory.lightweightClimbing,
            weightGrams: 680,
            aeroCdaModifier: -0.0070,
            stiffnessToWeightIndex: 2.50,
            comfortCompliance: 0.65,
            priceEur: 5200,
            mesh3dAssetPath: 'assets/models/frames/sovereign_edelweiss.glb',
            primaryColorHex: '#D4AF37',
          ),
          FrameModel(
            id: 'frame_sovereign_tt',
            brandId: 'brand_sovereign',
            name: 'Sovereign Chronarch TT',
            category: FrameCategory.timeTrial,
            weightGrams: 1130,
            aeroCdaModifier: -0.0325,
            stiffnessToWeightIndex: 2.62,
            comfortCompliance: 0.27,
            priceEur: 6500,
            mesh3dAssetPath: 'assets/models/frames/sovereign_chronarch.glb',
            primaryColorHex: '#D4AF37',
          ),
        ],
        wheelsets: [
          WheelsetModel(
            id: 'wheels_sovereign_34',
            brandId: 'brand_sovereign',
            name: 'Sovereign Ceramic 34',
            rimDepthMm: 34,
            weightGrams: 1215,
            aeroCdaModifier: -0.0058,
            crosswindStabilityPenalty: 0.09,
            momentOfInertia: 0.089,
            hubEngagementDragWatts: 0.55,
            priceEur: 2500,
          ),
          WheelsetModel(
            id: 'wheels_sovereign_54',
            brandId: 'brand_sovereign',
            name: 'Sovereign Ceramic 54 Aero',
            rimDepthMm: 54,
            weightGrams: 1410,
            aeroCdaModifier: -0.0128,
            crosswindStabilityPenalty: 0.37,
            momentOfInertia: 0.117,
            hubEngagementDragWatts: 0.58,
            priceEur: 2800,
          ),
          WheelsetModel(
            id: 'wheels_sovereign_disc',
            brandId: 'brand_sovereign',
            name: 'Sovereign SpeedDisc Pro',
            rimDepthMm: 100,
            weightGrams: 1680,
            aeroCdaModifier: -0.0228,
            crosswindStabilityPenalty: 0.86,
            momentOfInertia: 0.154,
            hubEngagementDragWatts: 0.62,
            priceEur: 3300,
          ),
        ],
        groupsets: [
          GroupsetModel(
            id: 'group_sovereign_cer12',
            brandId: 'brand_sovereign',
            name: 'Sovereign Ultimate Ceramic Di-12',
            weightGrams: 2070,
            isElectronic: true,
            speedCount: 12,
            mechanicalEfficiency: 0.988,
            priceEur: 3400,
          ),
        ],
        tires: [
          TireModel(
            id: 'tire_sovereign_tlr28',
            brandId: 'brand_sovereign',
            name: 'Sovereign BlackChili TLR 28',
            widthMm: 28,
            weightGrams: 238,
            rollingResistanceCrr: 0.00340,
            punctureResistanceIndex: 4.2,
            wetGripIndex: 4.8,
            isTubeless: true,
            priceEur: 90,
          ),
        ],
      ),

      // 6. GripMax Tires (Francja - nanokompozyty gumowe, przyczepność i ochrona)
      const FictionalBrand(
        id: 'brand_gripmax',
        name: 'GripMax Tires',
        countryIso: 'FRA',
        prestige: 4,
        description: 'Clermont-Ferrand silica rubber engineering. Unyielding grip in wet and pavé.',
        primaryColorHex: '#1A237E', // French Navy
        frames: [
          FrameModel(
            id: 'frame_gripmax_aero',
            brandId: 'brand_gripmax',
            name: 'GripMax Mistral Aero',
            category: FrameCategory.aero,
            weightGrams: 945,
            aeroCdaModifier: -0.0185,
            stiffnessToWeightIndex: 2.20,
            comfortCompliance: 0.52,
            priceEur: 4200,
            mesh3dAssetPath: 'assets/models/frames/gripmax_mistral.glb',
            primaryColorHex: '#1A237E',
          ),
          FrameModel(
            id: 'frame_gripmax_climb',
            brandId: 'brand_gripmax',
            name: 'GripMax Ventoux Climber',
            category: FrameCategory.lightweightClimbing,
            weightGrams: 715,
            aeroCdaModifier: -0.0060,
            stiffnessToWeightIndex: 2.32,
            comfortCompliance: 0.72,
            priceEur: 4300,
            mesh3dAssetPath: 'assets/models/frames/gripmax_ventoux.glb',
            primaryColorHex: '#1A237E',
          ),
          FrameModel(
            id: 'frame_gripmax_tt',
            brandId: 'brand_gripmax',
            name: 'GripMax Mirage Chrono',
            category: FrameCategory.timeTrial,
            weightGrams: 1190,
            aeroCdaModifier: -0.0295,
            stiffnessToWeightIndex: 2.45,
            comfortCompliance: 0.35,
            priceEur: 5600,
            mesh3dAssetPath: 'assets/models/frames/gripmax_mirage.glb',
            primaryColorHex: '#1A237E',
          ),
        ],
        wheelsets: [
          WheelsetModel(
            id: 'wheels_gripmax_30',
            brandId: 'brand_gripmax',
            name: 'GripMax Tourmalet 30',
            rimDepthMm: 30,
            weightGrams: 1230,
            aeroCdaModifier: -0.0049,
            crosswindStabilityPenalty: 0.06,
            momentOfInertia: 0.090,
            hubEngagementDragWatts: 0.85,
            priceEur: 1950,
          ),
          WheelsetModel(
            id: 'wheels_gripmax_48',
            brandId: 'brand_gripmax',
            name: 'GripMax Galibier 48 Aero',
            rimDepthMm: 48,
            weightGrams: 1435,
            aeroCdaModifier: -0.0112,
            crosswindStabilityPenalty: 0.33,
            momentOfInertia: 0.119,
            hubEngagementDragWatts: 0.90,
            priceEur: 2150,
          ),
          WheelsetModel(
            id: 'wheels_gripmax_disc',
            brandId: 'brand_gripmax',
            name: 'GripMax Discodrome TT',
            rimDepthMm: 100,
            weightGrams: 1750,
            aeroCdaModifier: -0.0205,
            crosswindStabilityPenalty: 0.82,
            momentOfInertia: 0.160,
            hubEngagementDragWatts: 1.05,
            priceEur: 2450,
          ),
        ],
        groupsets: [
          GroupsetModel(
            id: 'group_gripmax_e12',
            brandId: 'brand_gripmax',
            name: 'GripMax Corsa Electronic 12s',
            weightGrams: 2160,
            isElectronic: true,
            speedCount: 12,
            mechanicalEfficiency: 0.981,
            priceEur: 2400,
          ),
        ],
        tires: [
          TireModel(
            id: 'tire_gripmax_pro28',
            brandId: 'brand_gripmax',
            name: 'GripMax Graphene Pro Tubeless',
            widthMm: 28,
            weightGrams: 242,
            rollingResistanceCrr: 0.00348,
            punctureResistanceIndex: 4.5,
            wetGripIndex: 4.9,
            isTubeless: true,
            priceEur: 80,
          ),
        ],
      ),

      // 7. Nordic Glide Works (Norwegia - twardość, bruki, odporność na chłód)
      const FictionalBrand(
        id: 'brand_nordic',
        name: 'Nordic Glide Works',
        countryIso: 'NOR',
        prestige: 4,
        description: 'Hardened in the Norwegian fjords. Extreme weather and rough road endurance.',
        primaryColorHex: '#0277BD', // Fjord Blue
        frames: [
          FrameModel(
            id: 'frame_nordic_aero',
            brandId: 'brand_nordic',
            name: 'Nordic Fjord Aero',
            category: FrameCategory.aero,
            weightGrams: 930,
            aeroCdaModifier: -0.0192,
            stiffnessToWeightIndex: 2.32,
            comfortCompliance: 0.50,
            priceEur: 4500,
            mesh3dAssetPath: 'assets/models/frames/nordic_fjord.glb',
            primaryColorHex: '#0277BD',
          ),
          FrameModel(
            id: 'frame_nordic_climb',
            brandId: 'brand_nordic',
            name: 'Nordic Jotunheimen Light',
            category: FrameCategory.lightweightClimbing,
            weightGrams: 705,
            aeroCdaModifier: -0.0067,
            stiffnessToWeightIndex: 2.42,
            comfortCompliance: 0.70,
            priceEur: 4700,
            mesh3dAssetPath: 'assets/models/frames/nordic_jotunheimen.glb',
            primaryColorHex: '#0277BD',
          ),
          FrameModel(
            id: 'frame_nordic_tt',
            brandId: 'brand_nordic',
            name: 'Nordic Valkyrie TT',
            category: FrameCategory.timeTrial,
            weightGrams: 1155,
            aeroCdaModifier: -0.0310,
            stiffnessToWeightIndex: 2.58,
            comfortCompliance: 0.30,
            priceEur: 6100,
            mesh3dAssetPath: 'assets/models/frames/nordic_valkyrie.glb',
            primaryColorHex: '#0277BD',
          ),
        ],
        wheelsets: [
          WheelsetModel(
            id: 'wheels_nordic_35',
            brandId: 'brand_nordic',
            name: 'Nordic Storm 35 All-Weather',
            rimDepthMm: 35,
            weightGrams: 1225,
            aeroCdaModifier: -0.0056,
            crosswindStabilityPenalty: 0.09,
            momentOfInertia: 0.089,
            hubEngagementDragWatts: 0.78,
            priceEur: 2050,
          ),
          WheelsetModel(
            id: 'wheels_nordic_52',
            brandId: 'brand_nordic',
            name: 'Nordic Storm 52 Aero',
            rimDepthMm: 52,
            weightGrams: 1425,
            aeroCdaModifier: -0.0122,
            crosswindStabilityPenalty: 0.36,
            momentOfInertia: 0.117,
            hubEngagementDragWatts: 0.82,
            priceEur: 2250,
          ),
          WheelsetModel(
            id: 'wheels_nordic_disc',
            brandId: 'brand_nordic',
            name: 'Nordic Mjolnir Disc',
            rimDepthMm: 100,
            weightGrams: 1710,
            aeroCdaModifier: -0.0218,
            crosswindStabilityPenalty: 0.86,
            momentOfInertia: 0.156,
            hubEngagementDragWatts: 0.92,
            priceEur: 2600,
          ),
        ],
        groupsets: [
          GroupsetModel(
            id: 'group_nordic_di12',
            brandId: 'brand_nordic',
            name: 'Nordic SealTech Di-12',
            weightGrams: 2140,
            isElectronic: true,
            speedCount: 12,
            mechanicalEfficiency: 0.983,
            priceEur: 2650,
          ),
        ],
        tires: [
          TireModel(
            id: 'tire_nordic_wet30',
            brandId: 'brand_nordic',
            name: 'Nordic All-Weather WetGrip 30',
            widthMm: 30,
            weightGrams: 265,
            rollingResistanceCrr: 0.00390,
            punctureResistanceIndex: 4.7,
            wetGripIndex: 4.95,
            isTubeless: true,
            priceEur: 85,
          ),
        ],
      ),

      // 8. AeroVektor Bikes (Belgia - wiatry boczne, bruki flamandzkie)
      const FictionalBrand(
        id: 'brand_vektor',
        name: 'AeroVektor Bikes',
        countryIso: 'BEL',
        prestige: 5,
        description: 'Flemish crosswind dominators. Unshakable on cobbles and gutter echelons.',
        primaryColorHex: '#FBC02D', // Flanders Yellow
        frames: [
          FrameModel(
            id: 'frame_vektor_aero',
            brandId: 'brand_vektor',
            name: 'AeroVektor Flanders Aero',
            category: FrameCategory.aero,
            weightGrams: 915,
            aeroCdaModifier: -0.0202,
            stiffnessToWeightIndex: 2.42,
            comfortCompliance: 0.55,
            priceEur: 5000,
            mesh3dAssetPath: 'assets/models/frames/aerovektor_flanders.glb',
            primaryColorHex: '#FBC02D',
          ),
          FrameModel(
            id: 'frame_vektor_climb',
            brandId: 'brand_vektor',
            name: 'AeroVektor Ardennes Feather',
            category: FrameCategory.lightweightClimbing,
            weightGrams: 690,
            aeroCdaModifier: -0.0072,
            stiffnessToWeightIndex: 2.48,
            comfortCompliance: 0.67,
            priceEur: 4900,
            mesh3dAssetPath: 'assets/models/frames/aerovektor_ardennes.glb',
            primaryColorHex: '#FBC02D',
          ),
          FrameModel(
            id: 'frame_vektor_tt',
            brandId: 'brand_vektor',
            name: 'AeroVektor HourRecord TT',
            category: FrameCategory.timeTrial,
            weightGrams: 1135,
            aeroCdaModifier: -0.0330,
            stiffnessToWeightIndex: 2.65,
            comfortCompliance: 0.28,
            priceEur: 6600,
            mesh3dAssetPath: 'assets/models/frames/aerovektor_hourrecord.glb',
            primaryColorHex: '#FBC02D',
          ),
        ],
        wheelsets: [
          WheelsetModel(
            id: 'wheels_vektor_33',
            brandId: 'brand_vektor',
            name: 'AeroVektor Kwaremont 33',
            rimDepthMm: 33,
            weightGrams: 1205,
            aeroCdaModifier: -0.0054,
            crosswindStabilityPenalty: 0.07,
            momentOfInertia: 0.087,
            hubEngagementDragWatts: 0.72,
            priceEur: 2300,
          ),
          WheelsetModel(
            id: 'wheels_vektor_55',
            brandId: 'brand_vektor',
            name: 'AeroVektor Pave 55 Carbon',
            rimDepthMm: 55,
            weightGrams: 1415,
            aeroCdaModifier: -0.0126,
            crosswindStabilityPenalty: 0.35,
            momentOfInertia: 0.116,
            hubEngagementDragWatts: 0.76,
            priceEur: 2500,
          ),
          WheelsetModel(
            id: 'wheels_vektor_disc',
            brandId: 'brand_vektor',
            name: 'AeroVektor Velodrome Disc',
            rimDepthMm: 100,
            weightGrams: 1675,
            aeroCdaModifier: -0.0225,
            crosswindStabilityPenalty: 0.84,
            momentOfInertia: 0.153,
            hubEngagementDragWatts: 0.82,
            priceEur: 3000,
          ),
        ],
        groupsets: [
          GroupsetModel(
            id: 'group_vektor_cp12',
            brandId: 'brand_vektor',
            name: 'AeroVektor CobblePro Wireless 12',
            weightGrams: 2100,
            isElectronic: true,
            speedCount: 12,
            mechanicalEfficiency: 0.985,
            priceEur: 2900,
          ),
        ],
        tires: [
          TireModel(
            id: 'tire_vektor_pave30',
            brandId: 'brand_vektor',
            name: 'AeroVektor Roubaix Pave TLR 30',
            widthMm: 30,
            weightGrams: 270,
            rollingResistanceCrr: 0.00385,
            punctureResistanceIndex: 4.8,
            wetGripIndex: 4.8,
            isTubeless: true,
            priceEur: 88,
          ),
        ],
      ),

      // 9. Olympus Velo (Grecja - lekkość i agresywne podjazdy)
      const FictionalBrand(
        id: 'brand_olympus',
        name: 'Olympus Velo',
        countryIso: 'GRE',
        prestige: 3,
        description: 'Modern carbon climber bikes born under the Mediterranean sun.',
        primaryColorHex: '#00838F', // Aegean Cyan
        frames: [
          FrameModel(
            id: 'frame_olympus_aero',
            brandId: 'brand_olympus',
            name: 'Olympus Poseidon Aero',
            category: FrameCategory.aero,
            weightGrams: 960,
            aeroCdaModifier: -0.0175,
            stiffnessToWeightIndex: 2.15,
            comfortCompliance: 0.45,
            priceEur: 3600,
            mesh3dAssetPath: 'assets/models/frames/olympus_poseidon.glb',
            primaryColorHex: '#00838F',
          ),
          FrameModel(
            id: 'frame_olympus_climb',
            brandId: 'brand_olympus',
            name: 'Olympus Pantheon Superlight',
            category: FrameCategory.lightweightClimbing,
            weightGrams: 695,
            aeroCdaModifier: -0.0062,
            stiffnessToWeightIndex: 2.45,
            comfortCompliance: 0.65,
            priceEur: 3900,
            mesh3dAssetPath: 'assets/models/frames/olympus_pantheon.glb',
            primaryColorHex: '#00838F',
          ),
          FrameModel(
            id: 'frame_olympus_tt',
            brandId: 'brand_olympus',
            name: 'Olympus Hermes Chrono',
            category: FrameCategory.timeTrial,
            weightGrams: 1210,
            aeroCdaModifier: -0.0285,
            stiffnessToWeightIndex: 2.38,
            comfortCompliance: 0.32,
            priceEur: 4800,
            mesh3dAssetPath: 'assets/models/frames/olympus_hermes.glb',
            primaryColorHex: '#00838F',
          ),
        ],
        wheelsets: [
          WheelsetModel(
            id: 'wheels_olympus_30',
            brandId: 'brand_olympus',
            name: 'Olympus Delphi 30 Carbon',
            rimDepthMm: 30,
            weightGrams: 1220,
            aeroCdaModifier: -0.0048,
            crosswindStabilityPenalty: 0.06,
            momentOfInertia: 0.088,
            hubEngagementDragWatts: 0.95,
            priceEur: 1600,
          ),
          WheelsetModel(
            id: 'wheels_olympus_50',
            brandId: 'brand_olympus',
            name: 'Olympus Delphi 50 Aero',
            rimDepthMm: 50,
            weightGrams: 1440,
            aeroCdaModifier: -0.0110,
            crosswindStabilityPenalty: 0.35,
            momentOfInertia: 0.120,
            hubEngagementDragWatts: 1.00,
            priceEur: 1800,
          ),
          WheelsetModel(
            id: 'wheels_olympus_disc',
            brandId: 'brand_olympus',
            name: 'Olympus Chronos Disc',
            rimDepthMm: 100,
            weightGrams: 1780,
            aeroCdaModifier: -0.0195,
            crosswindStabilityPenalty: 0.85,
            momentOfInertia: 0.165,
            hubEngagementDragWatts: 1.15,
            priceEur: 2100,
          ),
        ],
        groupsets: [
          GroupsetModel(
            id: 'group_olympus_z12',
            brandId: 'brand_olympus',
            name: 'Olympus Zeus Electronic 12s',
            weightGrams: 2220,
            isElectronic: true,
            speedCount: 12,
            mechanicalEfficiency: 0.979,
            priceEur: 1950,
          ),
        ],
        tires: [
          TireModel(
            id: 'tire_olympus_race28',
            brandId: 'brand_olympus',
            name: 'Olympus Helios Race 28',
            widthMm: 28,
            weightGrams: 255,
            rollingResistanceCrr: 0.00365,
            punctureResistanceIndex: 3.5,
            wetGripIndex: 4.4,
            isTubeless: true,
            priceEur: 68,
          ),
        ],
      ),

      // 10. Kuraudo Performance Carbon (Japonia - włókna Torayca T1100G, zero tolerancji błędów)
      const FictionalBrand(
        id: 'brand_kuraudo',
        name: 'Kuraudo Performance',
        countryIso: 'JPN',
        prestige: 5,
        description: 'Osaka Torayca T1100G ultra-high-modulus aerospace carbon frames.',
        primaryColorHex: '#ECEFF1', // Pearl White
        frames: [
          FrameModel(
            id: 'frame_kuraudo_aero',
            brandId: 'brand_kuraudo',
            name: 'Kuraudo Shinkansen Aero',
            category: FrameCategory.aero,
            weightGrams: 890,
            aeroCdaModifier: -0.0215,
            stiffnessToWeightIndex: 2.48,
            comfortCompliance: 0.44,
            priceEur: 5600,
            mesh3dAssetPath: 'assets/models/frames/kuraudo_shinkansen.glb',
            primaryColorHex: '#ECEFF1',
          ),
          FrameModel(
            id: 'frame_kuraudo_climb',
            brandId: 'brand_kuraudo',
            name: 'Kuraudo Fuji Featherweight',
            category: FrameCategory.lightweightClimbing,
            weightGrams: 665,
            aeroCdaModifier: -0.0078,
            stiffnessToWeightIndex: 2.65,
            comfortCompliance: 0.66,
            priceEur: 5800,
            mesh3dAssetPath: 'assets/models/frames/kuraudo_fuji.glb',
            primaryColorHex: '#ECEFF1',
          ),
          FrameModel(
            id: 'frame_kuraudo_tt',
            brandId: 'brand_kuraudo',
            name: 'Kuraudo Hayabusa TT',
            category: FrameCategory.timeTrial,
            weightGrams: 1115,
            aeroCdaModifier: -0.0345,
            stiffnessToWeightIndex: 2.75,
            comfortCompliance: 0.26,
            priceEur: 7400,
            mesh3dAssetPath: 'assets/models/frames/kuraudo_hayabusa.glb',
            primaryColorHex: '#ECEFF1',
          ),
        ],
        wheelsets: [
          WheelsetModel(
            id: 'wheels_kuraudo_32',
            brandId: 'brand_kuraudo',
            name: 'Kuraudo Katana 32 Light',
            rimDepthMm: 32,
            weightGrams: 1150,
            aeroCdaModifier: -0.0058,
            crosswindStabilityPenalty: 0.07,
            momentOfInertia: 0.082,
            hubEngagementDragWatts: 0.50,
            priceEur: 2700,
          ),
          WheelsetModel(
            id: 'wheels_kuraudo_52',
            brandId: 'brand_kuraudo',
            name: 'Kuraudo Katana 52 Aero',
            rimDepthMm: 52,
            weightGrams: 1360,
            aeroCdaModifier: -0.0130,
            crosswindStabilityPenalty: 0.34,
            momentOfInertia: 0.112,
            hubEngagementDragWatts: 0.52,
            priceEur: 2950,
          ),
          WheelsetModel(
            id: 'wheels_kuraudo_disc',
            brandId: 'brand_kuraudo',
            name: 'Kuraudo Katana Disc Zero',
            rimDepthMm: 100,
            weightGrams: 1630,
            aeroCdaModifier: -0.0238,
            crosswindStabilityPenalty: 0.84,
            momentOfInertia: 0.149,
            hubEngagementDragWatts: 0.55,
            priceEur: 3500,
          ),
        ],
        groupsets: [
          GroupsetModel(
            id: 'group_kuraudo_ace12',
            brandId: 'brand_kuraudo',
            name: 'Kuraudo Precision Di-Ace 12',
            weightGrams: 2065,
            isElectronic: true,
            speedCount: 12,
            mechanicalEfficiency: 0.989,
            priceEur: 3500,
          ),
        ],
        tires: [
          TireModel(
            id: 'tire_kuraudo_sakura28',
            brandId: 'brand_kuraudo',
            name: 'Kuraudo Sakura Tubeless 28',
            widthMm: 28,
            weightGrams: 235,
            rollingResistanceCrr: 0.00335,
            punctureResistanceIndex: 4.1,
            wetGripIndex: 4.85,
            isTubeless: true,
            priceEur: 95,
          ),
        ],
      ),

      // 11. Ventus Aero Labs (Holandia - inżynieria wiatrowa, profile V-Airflow)
      const FictionalBrand(
        id: 'brand_ventus',
        name: 'Ventus Aero Labs',
        countryIso: 'NED',
        prestige: 4,
        description: 'Dutch North Sea wind engineering. Patented yaw-angle drag minimization.',
        primaryColorHex: '#E65100', // Dutch Orange
        frames: [
          FrameModel(
            id: 'frame_ventus_aero',
            brandId: 'brand_ventus',
            name: 'Ventus V-Turbine 1',
            category: FrameCategory.aero,
            weightGrams: 900,
            aeroCdaModifier: -0.0220,
            stiffnessToWeightIndex: 2.38,
            comfortCompliance: 0.41,
            priceEur: 4800,
            mesh3dAssetPath: 'assets/models/frames/ventus_vturbine.glb',
            primaryColorHex: '#E65100',
          ),
          FrameModel(
            id: 'frame_ventus_climb',
            brandId: 'brand_ventus',
            name: 'Ventus Zeeland Climbing',
            category: FrameCategory.lightweightClimbing,
            weightGrams: 720,
            aeroCdaModifier: -0.0070,
            stiffnessToWeightIndex: 2.35,
            comfortCompliance: 0.68,
            priceEur: 4400,
            mesh3dAssetPath: 'assets/models/frames/ventus_zeeland.glb',
            primaryColorHex: '#E65100',
          ),
          FrameModel(
            id: 'frame_ventus_tt',
            brandId: 'brand_ventus',
            name: 'Ventus NorthSea TT',
            category: FrameCategory.timeTrial,
            weightGrams: 1125,
            aeroCdaModifier: -0.0340,
            stiffnessToWeightIndex: 2.68,
            comfortCompliance: 0.27,
            priceEur: 6400,
            mesh3dAssetPath: 'assets/models/frames/ventus_northsea.glb',
            primaryColorHex: '#E65100',
          ),
        ],
        wheelsets: [
          WheelsetModel(
            id: 'wheels_ventus_35',
            brandId: 'brand_ventus',
            name: 'Ventus Zephyr 35',
            rimDepthMm: 35,
            weightGrams: 1220,
            aeroCdaModifier: -0.0060,
            crosswindStabilityPenalty: 0.08,
            momentOfInertia: 0.088,
            hubEngagementDragWatts: 0.75,
            priceEur: 2150,
          ),
          WheelsetModel(
            id: 'wheels_ventus_60',
            brandId: 'brand_ventus',
            name: 'Ventus WindTunnel 60',
            rimDepthMm: 60,
            weightGrams: 1430,
            aeroCdaModifier: -0.0138,
            crosswindStabilityPenalty: 0.40,
            momentOfInertia: 0.120,
            hubEngagementDragWatts: 0.78,
            priceEur: 2450,
          ),
          WheelsetModel(
            id: 'wheels_ventus_disc',
            brandId: 'brand_ventus',
            name: 'Ventus SolidDisc Aero',
            rimDepthMm: 100,
            weightGrams: 1670,
            aeroCdaModifier: -0.0230,
            crosswindStabilityPenalty: 0.88,
            momentOfInertia: 0.153,
            hubEngagementDragWatts: 0.85,
            priceEur: 2950,
          ),
        ],
        groupsets: [
          GroupsetModel(
            id: 'group_ventus_e12',
            brandId: 'brand_ventus',
            name: 'Ventus AeroShift 12 Electronic',
            weightGrams: 2115,
            isElectronic: true,
            speedCount: 12,
            mechanicalEfficiency: 0.984,
            priceEur: 2800,
          ),
        ],
        tires: [
          TireModel(
            id: 'tire_ventus_lowdrag25',
            brandId: 'brand_ventus',
            name: 'Ventus LowDrag Race 25',
            widthMm: 25,
            weightGrams: 222,
            rollingResistanceCrr: 0.00330,
            punctureResistanceIndex: 3.2,
            wetGripIndex: 4.4,
            isTubeless: true,
            priceEur: 84,
          ),
        ],
      ),

      // 12. Corsa d'Oro (Włochy - toskańskie rzemiosło, złote akcenty, tradycja)
      const FictionalBrand(
        id: 'brand_corsa_doro',
        name: 'Corsa d\'Oro',
        countryIso: 'ITA',
        prestige: 5,
        description: 'Tuscan artisan heritage since 1948. Hand-laid carbon with royal aesthetics.',
        primaryColorHex: '#B78103', // Noble Gold
        frames: [
          FrameModel(
            id: 'frame_corsa_aero',
            brandId: 'brand_corsa_doro',
            name: 'Corsa d\'Oro Maestoso Aero',
            category: FrameCategory.aero,
            weightGrams: 925,
            aeroCdaModifier: -0.0198,
            stiffnessToWeightIndex: 2.35,
            comfortCompliance: 0.52,
            priceEur: 5300,
            mesh3dAssetPath: 'assets/models/frames/corsa_maestoso.glb',
            primaryColorHex: '#B78103',
          ),
          FrameModel(
            id: 'frame_corsa_climb',
            brandId: 'brand_corsa_doro',
            name: 'Corsa d\'Oro Stelvio Leggera',
            category: FrameCategory.lightweightClimbing,
            weightGrams: 678,
            aeroCdaModifier: -0.0068,
            stiffnessToWeightIndex: 2.58,
            comfortCompliance: 0.69,
            priceEur: 5500,
            mesh3dAssetPath: 'assets/models/frames/corsa_stelvio.glb',
            primaryColorHex: '#B78103',
          ),
          FrameModel(
            id: 'frame_corsa_tt',
            brandId: 'brand_corsa_doro',
            name: 'Corsa d\'Oro Cronometro Reale',
            category: FrameCategory.timeTrial,
            weightGrams: 1150,
            aeroCdaModifier: -0.0320,
            stiffnessToWeightIndex: 2.60,
            comfortCompliance: 0.32,
            priceEur: 6700,
            mesh3dAssetPath: 'assets/models/frames/corsa_cronometro.glb',
            primaryColorHex: '#B78103',
          ),
        ],
        wheelsets: [
          WheelsetModel(
            id: 'wheels_corsa_30',
            brandId: 'brand_corsa_doro',
            name: 'Corsa d\'Oro Ghisallo 30',
            rimDepthMm: 30,
            weightGrams: 1180,
            aeroCdaModifier: -0.0050,
            crosswindStabilityPenalty: 0.06,
            momentOfInertia: 0.085,
            hubEngagementDragWatts: 0.68,
            priceEur: 2450,
          ),
          WheelsetModel(
            id: 'wheels_corsa_50',
            brandId: 'brand_corsa_doro',
            name: 'Corsa d\'Oro Chianti 50',
            rimDepthMm: 50,
            weightGrams: 1395,
            aeroCdaModifier: -0.0120,
            crosswindStabilityPenalty: 0.34,
            momentOfInertia: 0.115,
            hubEngagementDragWatts: 0.70,
            priceEur: 2700,
          ),
          WheelsetModel(
            id: 'wheels_corsa_disc',
            brandId: 'brand_corsa_doro',
            name: 'Corsa d\'Oro Ruota Aureo Disc',
            rimDepthMm: 100,
            weightGrams: 1690,
            aeroCdaModifier: -0.0222,
            crosswindStabilityPenalty: 0.86,
            momentOfInertia: 0.155,
            hubEngagementDragWatts: 0.78,
            priceEur: 3100,
          ),
        ],
        groupsets: [
          GroupsetModel(
            id: 'group_corsa_c12',
            brandId: 'brand_corsa_doro',
            name: 'Corsa d\'Oro Campione Di-12',
            weightGrams: 2090,
            isElectronic: true,
            speedCount: 12,
            mechanicalEfficiency: 0.986,
            priceEur: 3200,
          ),
        ],
        tires: [
          TireModel(
            id: 'tire_corsa_velluto28',
            brandId: 'brand_corsa_doro',
            name: 'Corsa d\'Oro Velluto TLR 28',
            widthMm: 28,
            weightGrams: 244,
            rollingResistanceCrr: 0.00345,
            punctureResistanceIndex: 3.9,
            wetGripIndex: 4.75,
            isTubeless: true,
            priceEur: 92,
          ),
        ],
      ),

      // 13. Apex Precision Cycling (Australia - specjaliści sprintu i kokpitów)
      const FictionalBrand(
        id: 'brand_apex',
        name: 'Apex Precision Cycling',
        countryIso: 'AUS',
        prestige: 4,
        description: 'Melbourne velodrome sprinting DNA meets WorldTour road performance.',
        primaryColorHex: '#33691E', // Outback Lime
        frames: [
          FrameModel(
            id: 'frame_apex_aero',
            brandId: 'brand_apex',
            name: 'Apex Velocity Sprint Aero',
            category: FrameCategory.aero,
            weightGrams: 910,
            aeroCdaModifier: -0.0210,
            stiffnessToWeightIndex: 2.44,
            comfortCompliance: 0.40,
            priceEur: 4700,
            mesh3dAssetPath: 'assets/models/frames/apex_velocity.glb',
            primaryColorHex: '#33691E',
          ),
          FrameModel(
            id: 'frame_apex_climb',
            brandId: 'brand_apex',
            name: 'Apex Alpine Razor',
            category: FrameCategory.lightweightClimbing,
            weightGrams: 700,
            aeroCdaModifier: -0.0070,
            stiffnessToWeightIndex: 2.42,
            comfortCompliance: 0.65,
            priceEur: 4600,
            mesh3dAssetPath: 'assets/models/frames/apex_alpine.glb',
            primaryColorHex: '#33691E',
          ),
          FrameModel(
            id: 'frame_apex_tt',
            brandId: 'brand_apex',
            name: 'Apex Pursuit TT',
            category: FrameCategory.timeTrial,
            weightGrams: 1130,
            aeroCdaModifier: -0.0330,
            stiffnessToWeightIndex: 2.64,
            comfortCompliance: 0.28,
            priceEur: 6200,
            mesh3dAssetPath: 'assets/models/frames/apex_pursuit.glb',
            primaryColorHex: '#33691E',
          ),
        ],
        wheelsets: [
          WheelsetModel(
            id: 'wheels_apex_35',
            brandId: 'brand_apex',
            name: 'Apex Sprint 35 Carbon',
            rimDepthMm: 35,
            weightGrams: 1225,
            aeroCdaModifier: -0.0058,
            crosswindStabilityPenalty: 0.08,
            momentOfInertia: 0.089,
            hubEngagementDragWatts: 0.76,
            priceEur: 2100,
          ),
          WheelsetModel(
            id: 'wheels_apex_55',
            brandId: 'brand_apex',
            name: 'Apex Sprint 55 Monocoque',
            rimDepthMm: 55,
            weightGrams: 1420,
            aeroCdaModifier: -0.0128,
            crosswindStabilityPenalty: 0.36,
            momentOfInertia: 0.117,
            hubEngagementDragWatts: 0.80,
            priceEur: 2350,
          ),
          WheelsetModel(
            id: 'wheels_apex_disc',
            brandId: 'brand_apex',
            name: 'Apex AeroDisc Velodrome',
            rimDepthMm: 100,
            weightGrams: 1685,
            aeroCdaModifier: -0.0226,
            crosswindStabilityPenalty: 0.86,
            momentOfInertia: 0.154,
            hubEngagementDragWatts: 0.88,
            priceEur: 2800,
          ),
        ],
        groupsets: [
          GroupsetModel(
            id: 'group_apex_s12',
            brandId: 'brand_apex',
            name: 'Apex SwiftShift Wireless 12',
            weightGrams: 2125,
            isElectronic: true,
            speedCount: 12,
            mechanicalEfficiency: 0.983,
            priceEur: 2600,
          ),
        ],
        tires: [
          TireModel(
            id: 'tire_apex_crit28',
            brandId: 'brand_apex',
            name: 'Apex CritRacer Tubeless 28',
            widthMm: 28,
            weightGrams: 246,
            rollingResistanceCrr: 0.00352,
            punctureResistanceIndex: 4.2,
            wetGripIndex: 4.8,
            isTubeless: true,
            priceEur: 82,
          ),
        ],
      ),

      // 14. Boreas Composites (Dania - ergonomia, sztywność węzła suportu, skandynawski minimalizm)
      const FictionalBrand(
        id: 'brand_boreas',
        name: 'Boreas Composites',
        countryIso: 'DEN',
        prestige: 4,
        description: 'Danish aerodynamic architecture. Integrated cockpit & bottom bracket rigidity.',
        primaryColorHex: '#37474F', // Arctic Charcoal
        frames: [
          FrameModel(
            id: 'frame_boreas_aero',
            brandId: 'brand_boreas',
            name: 'Boreas Skadi Aero',
            category: FrameCategory.aero,
            weightGrams: 918,
            aeroCdaModifier: -0.0205,
            stiffnessToWeightIndex: 2.36,
            comfortCompliance: 0.46,
            priceEur: 4600,
            mesh3dAssetPath: 'assets/models/frames/boreas_skadi.glb',
            primaryColorHex: '#37474F',
          ),
          FrameModel(
            id: 'frame_boreas_climb',
            brandId: 'brand_boreas',
            name: 'Boreas Himmelbjerget SL',
            category: FrameCategory.lightweightClimbing,
            weightGrams: 692,
            aeroCdaModifier: -0.0069,
            stiffnessToWeightIndex: 2.46,
            comfortCompliance: 0.68,
            priceEur: 4750,
            mesh3dAssetPath: 'assets/models/frames/boreas_himmelbjerget.glb',
            primaryColorHex: '#37474F',
          ),
          FrameModel(
            id: 'frame_boreas_tt',
            brandId: 'brand_boreas',
            name: 'Boreas Thor Chrono',
            category: FrameCategory.timeTrial,
            weightGrams: 1145,
            aeroCdaModifier: -0.0325,
            stiffnessToWeightIndex: 2.62,
            comfortCompliance: 0.29,
            priceEur: 6300,
            mesh3dAssetPath: 'assets/models/frames/boreas_thor.glb',
            primaryColorHex: '#37474F',
          ),
        ],
        wheelsets: [
          WheelsetModel(
            id: 'wheels_boreas_34',
            brandId: 'brand_boreas',
            name: 'Boreas Kattegat 34',
            rimDepthMm: 34,
            weightGrams: 1210,
            aeroCdaModifier: -0.0055,
            crosswindStabilityPenalty: 0.08,
            momentOfInertia: 0.088,
            hubEngagementDragWatts: 0.74,
            priceEur: 2150,
          ),
          WheelsetModel(
            id: 'wheels_boreas_54',
            brandId: 'brand_boreas',
            name: 'Boreas Kattegat 54 Aero',
            rimDepthMm: 54,
            weightGrams: 1410,
            aeroCdaModifier: -0.0124,
            crosswindStabilityPenalty: 0.36,
            momentOfInertia: 0.116,
            hubEngagementDragWatts: 0.78,
            priceEur: 2400,
          ),
          WheelsetModel(
            id: 'wheels_boreas_disc',
            brandId: 'brand_boreas',
            name: 'Boreas FullDisc Aero',
            rimDepthMm: 100,
            weightGrams: 1695,
            aeroCdaModifier: -0.0220,
            crosswindStabilityPenalty: 0.87,
            momentOfInertia: 0.155,
            hubEngagementDragWatts: 0.86,
            priceEur: 2850,
          ),
        ],
        groupsets: [
          GroupsetModel(
            id: 'group_boreas_e12',
            brandId: 'brand_boreas',
            name: 'Boreas AeroTech Electronic 12',
            weightGrams: 2120,
            isElectronic: true,
            speedCount: 12,
            mechanicalEfficiency: 0.984,
            priceEur: 2750,
          ),
        ],
        tires: [
          TireModel(
            id: 'tire_boreas_speed28',
            brandId: 'brand_boreas',
            name: 'Boreas SpeedGrip TLR 28',
            widthMm: 28,
            weightGrams: 245,
            rollingResistanceCrr: 0.00348,
            punctureResistanceIndex: 4.3,
            wetGripIndex: 4.7,
            isTubeless: true,
            priceEur: 84,
          ),
        ],
      ),

      // 15. Silvan Cycles (Hiszpania - baskijska geometria, zwinność na serpentynach Pirenejów)
      const FictionalBrand(
        id: 'brand_silvan',
        name: 'Silvan Cycles',
        countryIso: 'ESP',
        prestige: 4,
        description: 'Basque mountain heritage. Ruthless agility and responsiveness on Pyrenean hairpins.',
        primaryColorHex: '#C62828', // Basque Red
        frames: [
          FrameModel(
            id: 'frame_silvan_aero',
            brandId: 'brand_silvan',
            name: 'Silvan Iberico Aero',
            category: FrameCategory.aero,
            weightGrams: 935,
            aeroCdaModifier: -0.0188,
            stiffnessToWeightIndex: 2.28,
            comfortCompliance: 0.48,
            priceEur: 4300,
            mesh3dAssetPath: 'assets/models/frames/silvan_iberico.glb',
            primaryColorHex: '#C62828',
          ),
          FrameModel(
            id: 'frame_silvan_climb',
            brandId: 'brand_silvan',
            name: 'Silvan Pyrenees Superleggera',
            category: FrameCategory.lightweightClimbing,
            weightGrams: 675,
            aeroCdaModifier: -0.0066,
            stiffnessToWeightIndex: 2.62,
            comfortCompliance: 0.67,
            priceEur: 5100,
            mesh3dAssetPath: 'assets/models/frames/silvan_pyrenees.glb',
            primaryColorHex: '#C62828',
          ),
          FrameModel(
            id: 'frame_silvan_tt',
            brandId: 'brand_silvan',
            name: 'Silvan Angliru Chrono',
            category: FrameCategory.timeTrial,
            weightGrams: 1170,
            aeroCdaModifier: -0.0305,
            stiffnessToWeightIndex: 2.55,
            comfortCompliance: 0.31,
            priceEur: 5800,
            mesh3dAssetPath: 'assets/models/frames/silvan_angliru.glb',
            primaryColorHex: '#C62828',
          ),
        ],
        wheelsets: [
          WheelsetModel(
            id: 'wheels_silvan_30',
            brandId: 'brand_silvan',
            name: 'Silvan Sierra 30 UltraLight',
            rimDepthMm: 30,
            weightGrams: 1175,
            aeroCdaModifier: -0.0050,
            crosswindStabilityPenalty: 0.06,
            momentOfInertia: 0.085,
            hubEngagementDragWatts: 0.70,
            priceEur: 2200,
          ),
          WheelsetModel(
            id: 'wheels_silvan_50',
            brandId: 'brand_silvan',
            name: 'Silvan Sierra 50 Speed',
            rimDepthMm: 50,
            weightGrams: 1395,
            aeroCdaModifier: -0.0116,
            crosswindStabilityPenalty: 0.34,
            momentOfInertia: 0.115,
            hubEngagementDragWatts: 0.75,
            priceEur: 2450,
          ),
          WheelsetModel(
            id: 'wheels_silvan_disc',
            brandId: 'brand_silvan',
            name: 'Silvan Angliru Disc TT',
            rimDepthMm: 100,
            weightGrams: 1725,
            aeroCdaModifier: -0.0210,
            crosswindStabilityPenalty: 0.85,
            momentOfInertia: 0.158,
            hubEngagementDragWatts: 0.88,
            priceEur: 2700,
          ),
        ],
        groupsets: [
          GroupsetModel(
            id: 'group_silvan_f12',
            brandId: 'brand_silvan',
            name: 'Silvan Furia Electronic 12s',
            weightGrams: 2135,
            isElectronic: true,
            speedCount: 12,
            mechanicalEfficiency: 0.983,
            priceEur: 2600,
          ),
        ],
        tires: [
          TireModel(
            id: 'tire_silvan_agarre28',
            brandId: 'brand_silvan',
            name: 'Silvan Agarre Tubeless 28',
            widthMm: 28,
            weightGrams: 248,
            rollingResistanceCrr: 0.00355,
            punctureResistanceIndex: 4.1,
            wetGripIndex: 4.8,
            isTubeless: true,
            priceEur: 80,
          ),
        ],
      ),
    ];
  }
}

