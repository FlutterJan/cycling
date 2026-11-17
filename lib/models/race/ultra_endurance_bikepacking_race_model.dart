import 'dart:math' as math;

/// Kategorie wyścigów Ultra-Endurance Bikepacking (samowystarczalne wyścigi non-stop).
enum UltraBikepackingRaceSeries {
  /// Transcontinental Race (~4000 km przez Europę od morza do morza).
  transcontinental,

  /// NorthCape4000 (~4000 km z Włoch na Przylądek Północny).
  northCape4000,

  /// Tour Divide (~4400 km wzdłuż Gór Skalistych na rowerach MTB/Gravel).
  tourDivide,

  /// Silk Road Mountain Race (~1800–2000 km wysokogórskiego bikepackingu w Kirgistanie).
  silkRoadMountainRace,

  /// Atlas Mountain Race (~1300 km przez Maroko).
  atlasMountainRace,

  /// Niestandardowy wyścig Ultra-Endurance stworzony przez gracza lub ligę.
  customUltra;

  String toJson() => name;

  static UltraBikepackingRaceSeries fromJson(String value) {
    return UltraBikepackingRaceSeries.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UltraBikepackingRaceSeries.transcontinental,
    );
  }

  String get displayNamePl {
    switch (this) {
      case UltraBikepackingRaceSeries.transcontinental:
        return 'Transcontinental 4000';
      case UltraBikepackingRaceSeries.northCape4000:
        return 'NorthCape 4000';
      case UltraBikepackingRaceSeries.tourDivide:
        return 'Continental Divide Ultra';
      case UltraBikepackingRaceSeries.silkRoadMountainRace:
        return 'Silk Road Mountain Ultra';
      case UltraBikepackingRaceSeries.atlasMountainRace:
        return 'Atlas Mountain Ultra';
      case UltraBikepackingRaceSeries.customUltra:
        return 'Niestandardowy Wyścig Ultra';
    }
  }

  String get displayNameEn {
    switch (this) {
      case UltraBikepackingRaceSeries.transcontinental:
        return 'Transcontinental 4000';
      case UltraBikepackingRaceSeries.northCape4000:
        return 'NorthCape 4000';
      case UltraBikepackingRaceSeries.tourDivide:
        return 'Continental Divide Ultra';
      case UltraBikepackingRaceSeries.silkRoadMountainRace:
        return 'Silk Road Mountain Ultra';
      case UltraBikepackingRaceSeries.atlasMountainRace:
        return 'Atlas Mountain Ultra';
      case UltraBikepackingRaceSeries.customUltra:
        return 'Custom Ultra-Endurance Race';
    }
  }
}

/// Rodzaj punktu kontrolnego na trasie wyścigu bikepackingowego.
enum UltraCheckpointType {
  startLine,
  mandatoryCheckpoint,
  parcoursSegment,
  resupplyTown,
  mountainRefuge,
  finishLine;

  String toJson() => name;

  static UltraCheckpointType fromJson(String value) {
    return UltraCheckpointType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UltraCheckpointType.mandatoryCheckpoint,
    );
  }

  bool get isMandatoryControl =>
      this == UltraCheckpointType.startLine ||
      this == UltraCheckpointType.mandatoryCheckpoint ||
      this == UltraCheckpointType.parcoursSegment ||
      this == UltraCheckpointType.finishLine;
}

/// Pozycja montażu torby bikepackingowej na rowerze.
enum BikepackingBagSlot {
  handlebarRoll,
  frameBag,
  saddlePack,
  topTubeBag,
  forkCages,
  hydrationVest;

  String toJson() => name;

  static BikepackingBagSlot fromJson(String value) {
    return BikepackingBagSlot.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BikepackingBagSlot.frameBag,
    );
  }

  String get displayNamePl {
    switch (this) {
      case BikepackingBagSlot.handlebarRoll:
        return 'Torba na kierownicę (Handlebar Roll)';
      case BikepackingBagSlot.frameBag:
        return 'Torba w ramę (Frame Bag)';
      case BikepackingBagSlot.saddlePack:
        return 'Torba podsiodłowa (Saddle Pack)';
      case BikepackingBagSlot.topTubeBag:
        return 'Torba na górną rurę (Top Tube)';
      case BikepackingBagSlot.forkCages:
        return 'Koszyki na widelec (Fork Cages)';
      case BikepackingBagSlot.hydrationVest:
        return 'Kamizelka nawadniająca (Hydration Vest)';
    }
  }

  String get displayNameEn {
    switch (this) {
      case BikepackingBagSlot.handlebarRoll:
        return 'Handlebar Roll';
      case BikepackingBagSlot.frameBag:
        return 'Frame Bag';
      case BikepackingBagSlot.saddlePack:
        return 'Saddle Pack';
      case BikepackingBagSlot.topTubeBag:
        return 'Top Tube Bag';
      case BikepackingBagSlot.forkCages:
        return 'Fork Cages';
      case BikepackingBagSlot.hydrationVest:
        return 'Hydration Vest';
    }
  }
}

/// Klasa piasty z dynamem przedniego koła.
enum DynamoHubTier {
  /// Brak dynama — jazda wyłącznie na powerbankach i bateriach.
  noneBatteryOnly,

  /// Standardowe dynamo turystyczne (wyższe opory toczenia, niższa sprawność).
  standardHubDynamo,

  /// Wysokosprawne dynamo wyprawowe klasy SON 28 (stabilne ładowanie przy niskiej prędkości).
  highEfficiencySon28,

  /// Lekkie dynamo wyścigowe aero-ultra (minimalny opór przy >25 km/h).
  ultraLowDragAeroDynamo;

  String toJson() => name;

  static DynamoHubTier fromJson(String value) {
    return DynamoHubTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DynamoHubTier.highEfficiencySon28,
    );
  }

  String get displayNamePl {
    switch (this) {
      case DynamoHubTier.noneBatteryOnly:
        return 'Brak dynama (tylko powerbanki)';
      case DynamoHubTier.standardHubDynamo:
        return 'Standardowa piasta z dynamem';
      case DynamoHubTier.highEfficiencySon28:
        return 'Piasta SON 28 Ultra-Efficiency';
      case DynamoHubTier.ultraLowDragAeroDynamo:
        return 'Piasta Aero-Dynamo Racing';
    }
  }
}

/// Strategia snu i odpoczynku w wyścigu non-stop.
enum UltraSleepStrategy {
  /// Mikrodrzemka na przystanku/ławce (20 min).
  microNap20Min,

  /// Pełny cykl snu w śpiworze/biwaku (90 min).
  powerSleep90Min,

  /// Biwak w śpiworze i bivy bagu (4 h).
  bivy4Hours,

  /// Nocleg w hotelu/schronisku z ładowaniem sprzętu (5 h).
  hotel5Hours,

  /// Jazda przez całą noc bez snu (ryzyko halucynacji).
  pushThroughNight;

  String toJson() => name;

  static UltraSleepStrategy fromJson(String value) {
    return UltraSleepStrategy.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UltraSleepStrategy.bivy4Hours,
    );
  }

  double get durationHours {
    switch (this) {
      case UltraSleepStrategy.microNap20Min:
        return 0.33;
      case UltraSleepStrategy.powerSleep90Min:
        return 1.5;
      case UltraSleepStrategy.bivy4Hours:
        return 4.0;
      case UltraSleepStrategy.hotel5Hours:
        return 5.0;
      case UltraSleepStrategy.pushThroughNight:
        return 0.0;
    }
  }
}

/// Naruszenia regulaminu samowystarczalności (Self-Supported Ultra Rules).
enum UltraSelfSupportedRuleViolation {
  outsideAssistance,
  draftingCompetitor,
  missedMandatoryParcours,
  missingCheckpointStamp,
  noWorkingLightsAtNight,
  littering;

  String toJson() => name;

  static UltraSelfSupportedRuleViolation fromJson(String value) {
    return UltraSelfSupportedRuleViolation.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UltraSelfSupportedRuleViolation.outsideAssistance,
    );
  }

  double get defaultTimePenaltyHours {
    switch (this) {
      case UltraSelfSupportedRuleViolation.outsideAssistance:
        return 12.0;
      case UltraSelfSupportedRuleViolation.draftingCompetitor:
        return 2.0;
      case UltraSelfSupportedRuleViolation.missedMandatoryParcours:
        return 6.0;
      case UltraSelfSupportedRuleViolation.missingCheckpointStamp:
        return 4.0;
      case UltraSelfSupportedRuleViolation.noWorkingLightsAtNight:
        return 3.0;
      case UltraSelfSupportedRuleViolation.littering:
        return 2.0;
    }
  }
}

/// Punkt kontrolny (Checkpoint) lub odcinek obowiązkowy (Parcours) na trasie 4000 km.
class UltraCheckpointSpec {
  final String id;
  final int index;
  final String name;
  final double distanceKm;
  final double elevationM;
  final UltraCheckpointType type;
  final double mandatoryParcoursKm;
  final double cutOffHoursFromStart;
  final bool hasWaterResupply;
  final bool hasHotFood;
  final bool hasBikeShop;
  final bool hasLodging;
  final bool stampRequired;
  final String notesPl;
  final String notesEn;

  const UltraCheckpointSpec({
    required this.id,
    required this.index,
    required this.name,
    required this.distanceKm,
    required this.elevationM,
    required this.type,
    this.mandatoryParcoursKm = 0.0,
    required this.cutOffHoursFromStart,
    this.hasWaterResupply = true,
    this.hasHotFood = false,
    this.hasBikeShop = false,
    this.hasLodging = false,
    this.stampRequired = true,
    this.notesPl = '',
    this.notesEn = '',
  });

  bool get isMandatory => type.isMandatoryControl;

  bool isWithinCutoff(double elapsedHours) =>
      elapsedHours <= cutOffHoursFromStart;

  UltraCheckpointSpec copyWith({
    String? id,
    int? index,
    String? name,
    double? distanceKm,
    double? elevationM,
    UltraCheckpointType? type,
    double? mandatoryParcoursKm,
    double? cutOffHoursFromStart,
    bool? hasWaterResupply,
    bool? hasHotFood,
    bool? hasBikeShop,
    bool? hasLodging,
    bool? stampRequired,
    String? notesPl,
    String? notesEn,
  }) {
    return UltraCheckpointSpec(
      id: id ?? this.id,
      index: index ?? this.index,
      name: name ?? this.name,
      distanceKm: distanceKm ?? this.distanceKm,
      elevationM: elevationM ?? this.elevationM,
      type: type ?? this.type,
      mandatoryParcoursKm: mandatoryParcoursKm ?? this.mandatoryParcoursKm,
      cutOffHoursFromStart: cutOffHoursFromStart ?? this.cutOffHoursFromStart,
      hasWaterResupply: hasWaterResupply ?? this.hasWaterResupply,
      hasHotFood: hasHotFood ?? this.hasHotFood,
      hasBikeShop: hasBikeShop ?? this.hasBikeShop,
      hasLodging: hasLodging ?? this.hasLodging,
      stampRequired: stampRequired ?? this.stampRequired,
      notesPl: notesPl ?? this.notesPl,
      notesEn: notesEn ?? this.notesEn,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'index': index,
        'name': name,
        'distanceKm': distanceKm,
        'elevationM': elevationM,
        'type': type.toJson(),
        'mandatoryParcoursKm': mandatoryParcoursKm,
        'cutOffHoursFromStart': cutOffHoursFromStart,
        'hasWaterResupply': hasWaterResupply,
        'hasHotFood': hasHotFood,
        'hasBikeShop': hasBikeShop,
        'hasLodging': hasLodging,
        'stampRequired': stampRequired,
        'notesPl': notesPl,
        'notesEn': notesEn,
      };

  factory UltraCheckpointSpec.fromJson(Map<String, dynamic> json) {
    return UltraCheckpointSpec(
      id: json['id'] as String? ?? 'cp_0',
      index: (json['index'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Checkpoint',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      elevationM: (json['elevationM'] as num?)?.toDouble() ?? 0.0,
      type: UltraCheckpointType.fromJson(
        json['type'] as String? ?? 'mandatoryCheckpoint',
      ),
      mandatoryParcoursKm:
          (json['mandatoryParcoursKm'] as num?)?.toDouble() ?? 0.0,
      cutOffHoursFromStart:
          (json['cutOffHoursFromStart'] as num?)?.toDouble() ?? 360.0,
      hasWaterResupply: json['hasWaterResupply'] as bool? ?? true,
      hasHotFood: json['hasHotFood'] as bool? ?? false,
      hasBikeShop: json['hasBikeShop'] as bool? ?? false,
      hasLodging: json['hasLodging'] as bool? ?? false,
      stampRequired: json['stampRequired'] as bool? ?? true,
      notesPl: json['notesPl'] as String? ?? '',
      notesEn: json['notesEn'] as String? ?? '',
    );
  }
}

/// Odcinek trasy między kolejnymi punktami kontrolnymi.
class UltraRouteSegmentSpec {
  final String id;
  final String name;
  final double startKm;
  final double endKm;
  final double elevationGainM;
  final double elevationLossM;
  final double asphaltRatio;
  final double gravelRatio;
  final double singletrackRatio;
  final double nightHazardFactor;
  final double remoteWildernessFactor;

  const UltraRouteSegmentSpec({
    required this.id,
    required this.name,
    required this.startKm,
    required this.endKm,
    required this.elevationGainM,
    required this.elevationLossM,
    this.asphaltRatio = 0.75,
    this.gravelRatio = 0.22,
    this.singletrackRatio = 0.03,
    this.nightHazardFactor = 1.0,
    this.remoteWildernessFactor = 0.3,
  });

  double get distanceKm => math.max(0.0, endKm - startKm);

  double get averageClimbGradientPercent {
    if (distanceKm <= 0.0) return 0.0;
    return (elevationGainM / (distanceKm * 1000.0)) * 100.0;
  }

  /// Efektywny mnożnik oporu toczenia wynikający z proporcji nawierzchni.
  double get surfaceCrrMultiplier =>
      (asphaltRatio * 1.0) +
      (gravelRatio * 1.42) +
      (singletrackRatio * 2.05);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startKm': startKm,
        'endKm': endKm,
        'elevationGainM': elevationGainM,
        'elevationLossM': elevationLossM,
        'asphaltRatio': asphaltRatio,
        'gravelRatio': gravelRatio,
        'singletrackRatio': singletrackRatio,
        'nightHazardFactor': nightHazardFactor,
        'remoteWildernessFactor': remoteWildernessFactor,
      };

  factory UltraRouteSegmentSpec.fromJson(Map<String, dynamic> json) {
    return UltraRouteSegmentSpec(
      id: json['id'] as String? ?? 'seg_1',
      name: json['name'] as String? ?? 'Segment',
      startKm: (json['startKm'] as num?)?.toDouble() ?? 0.0,
      endKm: (json['endKm'] as num?)?.toDouble() ?? 100.0,
      elevationGainM: (json['elevationGainM'] as num?)?.toDouble() ?? 1000.0,
      elevationLossM: (json['elevationLossM'] as num?)?.toDouble() ?? 1000.0,
      asphaltRatio: (json['asphaltRatio'] as num?)?.toDouble() ?? 0.75,
      gravelRatio: (json['gravelRatio'] as num?)?.toDouble() ?? 0.22,
      singletrackRatio: (json['singletrackRatio'] as num?)?.toDouble() ?? 0.03,
      nightHazardFactor:
          (json['nightHazardFactor'] as num?)?.toDouble() ?? 1.0,
      remoteWildernessFactor:
          (json['remoteWildernessFactor'] as num?)?.toDouble() ?? 0.3,
    );
  }
}

/// Pojedyncza torba bikepackingowa zamontowana na rowerze.
class BikepackingBagSpec {
  final String id;
  final BikepackingBagSlot slot;
  final String name;
  final double capacityLiters;
  final double emptyWeightGrams;
  final double packedWeightGrams;
  final double cdaPenaltyM2;
  final int waterproofRatingIp;
  final bool isPacked;
  final String contentsSummary;

  const BikepackingBagSpec({
    required this.id,
    required this.slot,
    required this.name,
    required this.capacityLiters,
    required this.emptyWeightGrams,
    required this.packedWeightGrams,
    required this.cdaPenaltyM2,
    this.waterproofRatingIp = 65,
    this.isPacked = true,
    this.contentsSummary = '',
  });

  double get totalWeightKg =>
      math.max(0.0, (emptyWeightGrams + (isPacked ? packedWeightGrams : 0.0)) / 1000.0);

  /// Straty aerodynamiczne w watach przy zadanej prędkości (m/s).
  double aeroDragWatts(double speedMs, {double airDensity = 1.225}) {
    if (!isPacked && emptyWeightGrams <= 0) return 0.0;
    final v = math.max(0.0, speedMs);
    return 0.5 * airDensity * cdaPenaltyM2 * v * v * v;
  }

  BikepackingBagSpec copyWith({
    String? id,
    BikepackingBagSlot? slot,
    String? name,
    double? capacityLiters,
    double? emptyWeightGrams,
    double? packedWeightGrams,
    double? cdaPenaltyM2,
    int? waterproofRatingIp,
    bool? isPacked,
    String? contentsSummary,
  }) {
    return BikepackingBagSpec(
      id: id ?? this.id,
      slot: slot ?? this.slot,
      name: name ?? this.name,
      capacityLiters: capacityLiters ?? this.capacityLiters,
      emptyWeightGrams: emptyWeightGrams ?? this.emptyWeightGrams,
      packedWeightGrams: packedWeightGrams ?? this.packedWeightGrams,
      cdaPenaltyM2: cdaPenaltyM2 ?? this.cdaPenaltyM2,
      waterproofRatingIp: waterproofRatingIp ?? this.waterproofRatingIp,
      isPacked: isPacked ?? this.isPacked,
      contentsSummary: contentsSummary ?? this.contentsSummary,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slot': slot.toJson(),
        'name': name,
        'capacityLiters': capacityLiters,
        'emptyWeightGrams': emptyWeightGrams,
        'packedWeightGrams': packedWeightGrams,
        'cdaPenaltyM2': cdaPenaltyM2,
        'waterproofRatingIp': waterproofRatingIp,
        'isPacked': isPacked,
        'contentsSummary': contentsSummary,
      };

  factory BikepackingBagSpec.fromJson(Map<String, dynamic> json) {
    return BikepackingBagSpec(
      id: json['id'] as String? ?? 'bag_frame',
      slot: BikepackingBagSlot.fromJson(json['slot'] as String? ?? 'frameBag'),
      name: json['name'] as String? ?? 'Bikepacking Bag',
      capacityLiters: (json['capacityLiters'] as num?)?.toDouble() ?? 4.0,
      emptyWeightGrams: (json['emptyWeightGrams'] as num?)?.toDouble() ?? 180.0,
      packedWeightGrams:
          (json['packedWeightGrams'] as num?)?.toDouble() ?? 900.0,
      cdaPenaltyM2: (json['cdaPenaltyM2'] as num?)?.toDouble() ?? 0.004,
      waterproofRatingIp: (json['waterproofRatingIp'] as num?)?.toInt() ?? 65,
      isPacked: json['isPacked'] as bool? ?? true,
      contentsSummary: json['contentsSummary'] as String? ?? '',
    );
  }
}

/// Zestaw toreb bikepackingowych i obowiązkowego ekwipunku przetrwania.
class BikepackingLoadout {
  final List<BikepackingBagSpec> bags;
  final bool hasBivyBag;
  final bool hasSleepingBag;
  final bool hasDownJacket;
  final bool hasRainShell;
  final int headlightLumens;
  final int rearLightLumens;
  final bool hasGpsTracker;
  final int spareTubesCount;
  final bool hasFirstAidKit;
  final double waterCapacityLiters;

  const BikepackingLoadout({
    required this.bags,
    this.hasBivyBag = true,
    this.hasSleepingBag = true,
    this.hasDownJacket = true,
    this.hasRainShell = true,
    this.headlightLumens = 800,
    this.rearLightLumens = 60,
    this.hasGpsTracker = true,
    this.spareTubesCount = 2,
    this.hasFirstAidKit = true,
    this.waterCapacityLiters = 2.25,
  });

  double get totalBagVolumeLiters =>
      bags.fold<double>(0.0, (sum, b) => sum + b.capacityLiters);

  double get totalGearWeightKg =>
      bags.fold<double>(0.0, (sum, b) => sum + b.totalWeightKg);

  double get totalAeroCdAPenaltyM2 =>
      bags.fold<double>(0.0, (sum, b) => sum + (b.isPacked ? b.cdaPenaltyM2 : 0.0));

  /// Dodatkowa moc potrzebna na podjeździe przez masę ekwipunku.
  double climbingWeightPenaltyWatts({
    required double gradePercent,
    required double speedMs,
  }) {
    if (gradePercent <= 0.0 || speedMs <= 0.0) return 0.0;
    final slopeSin = math.sin(math.atan(gradePercent / 100.0));
    return totalGearWeightKg * 9.80665 * slopeSin * speedMs;
  }

  /// Łączne straty aerodynamiczne toreb przy prędkości [speedMs].
  double totalAeroDragWatts(double speedMs, {double airDensity = 1.225}) {
    final v = math.max(0.0, speedMs);
    return 0.5 * airDensity * totalAeroCdAPenaltyM2 * v * v * v;
  }

  List<String> get missingMandatoryItems {
    final missing = <String>[];
    if (!hasBivyBag) missing.add('Bivy Bag');
    if (!hasRainShell) missing.add('Waterproof Rain Shell');
    if (headlightLumens < 400) missing.add('Front Light (>=400 lm)');
    if (rearLightLumens < 30) missing.add('Rear Light (>=30 lm)');
    if (!hasGpsTracker) missing.add('Satellite GPS Tracker');
    if (spareTubesCount < 1) missing.add('Spare Tube / Repair Kit');
    if (!hasFirstAidKit) missing.add('First Aid Kit');
    if (waterCapacityLiters < 1.5) missing.add('Water Capacity (>=1.5 L)');
    return missing;
  }

  bool get isMandatoryGearComplete => missingMandatoryItems.isEmpty;

  BikepackingLoadout copyWith({
    List<BikepackingBagSpec>? bags,
    bool? hasBivyBag,
    bool? hasSleepingBag,
    bool? hasDownJacket,
    bool? hasRainShell,
    int? headlightLumens,
    int? rearLightLumens,
    bool? hasGpsTracker,
    int? spareTubesCount,
    bool? hasFirstAidKit,
    double? waterCapacityLiters,
  }) {
    return BikepackingLoadout(
      bags: bags ?? this.bags,
      hasBivyBag: hasBivyBag ?? this.hasBivyBag,
      hasSleepingBag: hasSleepingBag ?? this.hasSleepingBag,
      hasDownJacket: hasDownJacket ?? this.hasDownJacket,
      hasRainShell: hasRainShell ?? this.hasRainShell,
      headlightLumens: headlightLumens ?? this.headlightLumens,
      rearLightLumens: rearLightLumens ?? this.rearLightLumens,
      hasGpsTracker: hasGpsTracker ?? this.hasGpsTracker,
      spareTubesCount: spareTubesCount ?? this.spareTubesCount,
      hasFirstAidKit: hasFirstAidKit ?? this.hasFirstAidKit,
      waterCapacityLiters: waterCapacityLiters ?? this.waterCapacityLiters,
    );
  }

  Map<String, dynamic> toJson() => {
        'bags': bags.map((b) => b.toJson()).toList(),
        'hasBivyBag': hasBivyBag,
        'hasSleepingBag': hasSleepingBag,
        'hasDownJacket': hasDownJacket,
        'hasRainShell': hasRainShell,
        'headlightLumens': headlightLumens,
        'rearLightLumens': rearLightLumens,
        'hasGpsTracker': hasGpsTracker,
        'spareTubesCount': spareTubesCount,
        'hasFirstAidKit': hasFirstAidKit,
        'waterCapacityLiters': waterCapacityLiters,
      };

  factory BikepackingLoadout.fromJson(Map<String, dynamic> json) {
    final rawBags = json['bags'] as List<dynamic>? ?? const [];
    return BikepackingLoadout(
      bags: rawBags
          .whereType<Map<String, dynamic>>()
          .map(BikepackingBagSpec.fromJson)
          .toList(),
      hasBivyBag: json['hasBivyBag'] as bool? ?? true,
      hasSleepingBag: json['hasSleepingBag'] as bool? ?? true,
      hasDownJacket: json['hasDownJacket'] as bool? ?? true,
      hasRainShell: json['hasRainShell'] as bool? ?? true,
      headlightLumens: (json['headlightLumens'] as num?)?.toInt() ?? 800,
      rearLightLumens: (json['rearLightLumens'] as num?)?.toInt() ?? 60,
      hasGpsTracker: json['hasGpsTracker'] as bool? ?? true,
      spareTubesCount: (json['spareTubesCount'] as num?)?.toInt() ?? 2,
      hasFirstAidKit: json['hasFirstAidKit'] as bool? ?? true,
      waterCapacityLiters:
          (json['waterCapacityLiters'] as num?)?.toDouble() ?? 2.25,
    );
  }

  /// Standardowy zestaw ultra-race na 4000 km (~14.5 L, ~3.4 kg).
  factory BikepackingLoadout.ultraRaceMinimal() {
    return const BikepackingLoadout(
      bags: [
        BikepackingBagSpec(
          id: 'bag_saddle',
          slot: BikepackingBagSlot.saddlePack,
          name: 'Aero Saddle Pack 6L',
          capacityLiters: 6.0,
          emptyWeightGrams: 265,
          packedWeightGrams: 1150,
          cdaPenaltyM2: 0.0022,
          contentsSummary: 'Bivy, puchówka, warstwa termo',
        ),
        BikepackingBagSpec(
          id: 'bag_frame',
          slot: BikepackingBagSlot.frameBag,
          name: 'Full-Length Aero Frame Bag 4.5L',
          capacityLiters: 4.5,
          emptyWeightGrams: 210,
          packedWeightGrams: 980,
          cdaPenaltyM2: 0.0011,
          contentsSummary: 'Powerbank, narzędzia, żele, kurtka',
        ),
        BikepackingBagSpec(
          id: 'bag_handlebar',
          slot: BikepackingBagSlot.handlebarRoll,
          name: 'Compact Bar Roll 3L',
          capacityLiters: 3.0,
          emptyWeightGrams: 185,
          packedWeightGrams: 620,
          cdaPenaltyM2: 0.0045,
          contentsSummary: 'Śpiwór ultra-light / odzież nocna',
        ),
        BikepackingBagSpec(
          id: 'bag_toptube',
          slot: BikepackingBagSlot.topTubeBag,
          name: 'Bolt-On Top Tube Pack 1.0L',
          capacityLiters: 1.0,
          emptyWeightGrams: 95,
          packedWeightGrams: 340,
          cdaPenaltyM2: 0.0005,
          contentsSummary: 'Batoniki, przewody USB, dokumenty',
        ),
      ],
    );
  }
}

/// Specyfikacja piasty z dynamem w przednim kole.
class DynamoHubSpec {
  final String id;
  final String name;
  final DynamoHubTier tier;
  final double nominalOutputWattsAt20Kmh;
  final double peakOutputWatts;
  final double mechanicalDragWattsEngaged;
  final double mechanicalDragWattsDisengaged;
  final double weightGrams;
  final double usbCacheBatteryMah;
  final bool isEngaged;

  const DynamoHubSpec({
    required this.id,
    required this.name,
    required this.tier,
    required this.nominalOutputWattsAt20Kmh,
    required this.peakOutputWatts,
    required this.mechanicalDragWattsEngaged,
    required this.mechanicalDragWattsDisengaged,
    required this.weightGrams,
    this.usbCacheBatteryMah = 2200.0,
    this.isEngaged = true,
  });

  /// Generowana moc elektryczna [W] dla prędkości [speedKmh].
  double electricalOutputWattsAtSpeed(double speedKmh) {
    if (tier == DynamoHubTier.noneBatteryOnly || !isEngaged) return 0.0;
    if (speedKmh < 6.0) return 0.0;
    if (speedKmh <= 20.0) {
      final ratio = (speedKmh - 6.0) / 14.0;
      return nominalOutputWattsAt20Kmh * math.pow(ratio, 0.85);
    }
    final extraRatio = math.min(1.0, (speedKmh - 20.0) / 15.0);
    return nominalOutputWattsAt20Kmh +
        (peakOutputWatts - nominalOutputWattsAt20Kmh) * extraRatio;
  }

  /// Opór mechaniczny piasty [W] przy prędkości [speedKmh].
  double mechanicalDragWattsAtSpeed(double speedKmh) {
    if (tier == DynamoHubTier.noneBatteryOnly || speedKmh <= 0.5) return 0.0;
    final speedFactor = math.min(1.35, 0.65 + (speedKmh / 35.0) * 0.7);
    if (!isEngaged) {
      return mechanicalDragWattsDisengaged * speedFactor;
    }
    return mechanicalDragWattsEngaged * speedFactor;
  }

  /// Bilans ładowania netto [W] po odjęciu bieżącego poboru elektroniki.
  double netChargingWatts({
    required double speedKmh,
    required double activeLoadWatts,
  }) {
    return electricalOutputWattsAtSpeed(speedKmh) - activeLoadWatts;
  }

  DynamoHubSpec copyWith({
    String? id,
    String? name,
    DynamoHubTier? tier,
    double? nominalOutputWattsAt20Kmh,
    double? peakOutputWatts,
    double? mechanicalDragWattsEngaged,
    double? mechanicalDragWattsDisengaged,
    double? weightGrams,
    double? usbCacheBatteryMah,
    bool? isEngaged,
  }) {
    return DynamoHubSpec(
      id: id ?? this.id,
      name: name ?? this.name,
      tier: tier ?? this.tier,
      nominalOutputWattsAt20Kmh:
          nominalOutputWattsAt20Kmh ?? this.nominalOutputWattsAt20Kmh,
      peakOutputWatts: peakOutputWatts ?? this.peakOutputWatts,
      mechanicalDragWattsEngaged:
          mechanicalDragWattsEngaged ?? this.mechanicalDragWattsEngaged,
      mechanicalDragWattsDisengaged:
          mechanicalDragWattsDisengaged ?? this.mechanicalDragWattsDisengaged,
      weightGrams: weightGrams ?? this.weightGrams,
      usbCacheBatteryMah: usbCacheBatteryMah ?? this.usbCacheBatteryMah,
      isEngaged: isEngaged ?? this.isEngaged,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tier': tier.toJson(),
        'nominalOutputWattsAt20Kmh': nominalOutputWattsAt20Kmh,
        'peakOutputWatts': peakOutputWatts,
        'mechanicalDragWattsEngaged': mechanicalDragWattsEngaged,
        'mechanicalDragWattsDisengaged': mechanicalDragWattsDisengaged,
        'weightGrams': weightGrams,
        'usbCacheBatteryMah': usbCacheBatteryMah,
        'isEngaged': isEngaged,
      };

  factory DynamoHubSpec.fromJson(Map<String, dynamic> json) {
    return DynamoHubSpec(
      id: json['id'] as String? ?? 'dynamo_son28',
      name: json['name'] as String? ?? 'SON 28 Dynamo Hub',
      tier: DynamoHubTier.fromJson(
        json['tier'] as String? ?? 'highEfficiencySon28',
      ),
      nominalOutputWattsAt20Kmh:
          (json['nominalOutputWattsAt20Kmh'] as num?)?.toDouble() ?? 4.6,
      peakOutputWatts: (json['peakOutputWatts'] as num?)?.toDouble() ?? 7.2,
      mechanicalDragWattsEngaged:
          (json['mechanicalDragWattsEngaged'] as num?)?.toDouble() ?? 5.8,
      mechanicalDragWattsDisengaged:
          (json['mechanicalDragWattsDisengaged'] as num?)?.toDouble() ?? 0.65,
      weightGrams: (json['weightGrams'] as num?)?.toDouble() ?? 430.0,
      usbCacheBatteryMah:
          (json['usbCacheBatteryMah'] as num?)?.toDouble() ?? 2200.0,
      isEngaged: json['isEngaged'] as bool? ?? true,
    );
  }

  factory DynamoHubSpec.son28Ultra() {
    return const DynamoHubSpec(
      id: 'dynamo_son28_ultra',
      name: 'SON 28 + Sinewave Reactor',
      tier: DynamoHubTier.highEfficiencySon28,
      nominalOutputWattsAt20Kmh: 4.8,
      peakOutputWatts: 7.5,
      mechanicalDragWattsEngaged: 5.6,
      mechanicalDragWattsDisengaged: 0.6,
      weightGrams: 430,
      usbCacheBatteryMah: 2500,
      isEngaged: true,
    );
  }

  factory DynamoHubSpec.batteryOnly() {
    return const DynamoHubSpec(
      id: 'dynamo_none',
      name: 'Brak dynama (piasta klasyczna)',
      tier: DynamoHubTier.noneBatteryOnly,
      nominalOutputWattsAt20Kmh: 0.0,
      peakOutputWatts: 0.0,
      mechanicalDragWattsEngaged: 0.0,
      mechanicalDragWattsDisengaged: 0.0,
      weightGrams: 115,
      usbCacheBatteryMah: 0,
      isEngaged: false,
    );
  }
}

/// Wynik kroku symulacji budżetu energetycznego dynama i baterii.
class DynamoPowerStepResult {
  final ElectronicsPowerState updatedState;
  final double generatedWh;
  final double consumedWh;
  final double netWh;
  final bool hasLightsOutRisk;
  final bool hasGpsBlackoutRisk;

  const DynamoPowerStepResult({
    required this.updatedState,
    required this.generatedWh,
    required this.consumedWh,
    required this.netWh,
    required this.hasLightsOutRisk,
    required this.hasGpsBlackoutRisk,
  });
}

/// Stan baterii elektroniki pokładowej podczas wyścigu 4000 km.
class ElectronicsPowerState {
  final double headlightBatteryPercent;
  final double gpsComputerBatteryPercent;
  final double trackerBatteryPercent;
  final double di2ShiftingBatteryPercent;
  final double powerBankMah;
  final double powerBankCapacityMah;
  final bool isNightLightingActive;
  final double headlightDrawWatts;
  final double gpsDrawWatts;
  final double trackerDrawWatts;

  const ElectronicsPowerState({
    this.headlightBatteryPercent = 100.0,
    this.gpsComputerBatteryPercent = 100.0,
    this.trackerBatteryPercent = 100.0,
    this.di2ShiftingBatteryPercent = 100.0,
    this.powerBankMah = 10000.0,
    this.powerBankCapacityMah = 10000.0,
    this.isNightLightingActive = false,
    this.headlightDrawWatts = 3.2,
    this.gpsDrawWatts = 0.9,
    this.trackerDrawWatts = 0.25,
  });

  double get totalActiveDrawWatts =>
      (isNightLightingActive ? headlightDrawWatts : 0.0) +
      gpsDrawWatts +
      trackerDrawWatts;

  double get powerBankPercent => powerBankCapacityMah <= 0.0
      ? 0.0
      : (powerBankMah / powerBankCapacityMah * 100.0).clamp(0.0, 100.0);

  /// Aktualizuje stan baterii i powerbanku na podstawie prędkości oraz dynama.
  DynamoPowerStepResult stepPowerBudget({
    required double durationHours,
    required double avgSpeedKmh,
    required DynamoHubSpec dynamoHub,
    required bool isNight,
  }) {
    final hours = math.max(0.0, durationHours);
    final activeHeadlightW = isNight ? headlightDrawWatts : 0.0;
    final totalDrawW = activeHeadlightW + gpsDrawWatts + trackerDrawWatts;
    final generatedW = dynamoHub.electricalOutputWattsAtSpeed(avgSpeedKmh);

    final generatedWh = generatedW * hours;
    final consumedWh = totalDrawW * hours;
    final netWh = generatedWh - consumedWh;

    // 1 Wh przy 3.7 V ~ 270.27 mAh.
    final deltaMah = netWh * 270.27;
    var nextBankMah = (powerBankMah + deltaMah).clamp(0.0, powerBankCapacityMah);

    var nextHeadlight = headlightBatteryPercent;
    var nextGps = gpsComputerBatteryPercent;
    var nextTracker = trackerBatteryPercent;

    if (nextBankMah <= 0.0 && deltaMah < 0.0) {
      final deficitWh = -netWh - (powerBankMah / 270.27);
      if (isNight) {
        nextHeadlight = (nextHeadlight - (deficitWh / 12.0) * 100.0).clamp(0.0, 100.0);
      }
      nextGps = (nextGps - (deficitWh / 8.0) * 100.0).clamp(0.0, 100.0);
      nextTracker = (nextTracker - (deficitWh / 18.0) * 100.0).clamp(0.0, 100.0);
    } else if (deltaMah > 0.0) {
      nextHeadlight = math.min(100.0, nextHeadlight + 8.0 * hours);
      nextGps = math.min(100.0, nextGps + 10.0 * hours);
    }

    final nextDi2 = (di2ShiftingBatteryPercent - 0.12 * hours).clamp(0.0, 100.0);
    final updated = copyWith(
      headlightBatteryPercent: nextHeadlight,
      gpsComputerBatteryPercent: nextGps,
      trackerBatteryPercent: nextTracker,
      di2ShiftingBatteryPercent: nextDi2,
      powerBankMah: nextBankMah,
      isNightLightingActive: isNight,
    );

    return DynamoPowerStepResult(
      updatedState: updated,
      generatedWh: generatedWh,
      consumedWh: consumedWh,
      netWh: netWh,
      hasLightsOutRisk: isNight && nextHeadlight < 15.0 && nextBankMah <= 100.0,
      hasGpsBlackoutRisk: nextGps < 15.0 && nextBankMah <= 100.0,
    );
  }

  ElectronicsPowerState copyWith({
    double? headlightBatteryPercent,
    double? gpsComputerBatteryPercent,
    double? trackerBatteryPercent,
    double? di2ShiftingBatteryPercent,
    double? powerBankMah,
    double? powerBankCapacityMah,
    bool? isNightLightingActive,
    double? headlightDrawWatts,
    double? gpsDrawWatts,
    double? trackerDrawWatts,
  }) {
    return ElectronicsPowerState(
      headlightBatteryPercent:
          headlightBatteryPercent ?? this.headlightBatteryPercent,
      gpsComputerBatteryPercent:
          gpsComputerBatteryPercent ?? this.gpsComputerBatteryPercent,
      trackerBatteryPercent:
          trackerBatteryPercent ?? this.trackerBatteryPercent,
      di2ShiftingBatteryPercent:
          di2ShiftingBatteryPercent ?? this.di2ShiftingBatteryPercent,
      powerBankMah: powerBankMah ?? this.powerBankMah,
      powerBankCapacityMah: powerBankCapacityMah ?? this.powerBankCapacityMah,
      isNightLightingActive:
          isNightLightingActive ?? this.isNightLightingActive,
      headlightDrawWatts: headlightDrawWatts ?? this.headlightDrawWatts,
      gpsDrawWatts: gpsDrawWatts ?? this.gpsDrawWatts,
      trackerDrawWatts: trackerDrawWatts ?? this.trackerDrawWatts,
    );
  }

  Map<String, dynamic> toJson() => {
        'headlightBatteryPercent': headlightBatteryPercent,
        'gpsComputerBatteryPercent': gpsComputerBatteryPercent,
        'trackerBatteryPercent': trackerBatteryPercent,
        'di2ShiftingBatteryPercent': di2ShiftingBatteryPercent,
        'powerBankMah': powerBankMah,
        'powerBankCapacityMah': powerBankCapacityMah,
        'isNightLightingActive': isNightLightingActive,
        'headlightDrawWatts': headlightDrawWatts,
        'gpsDrawWatts': gpsDrawWatts,
        'trackerDrawWatts': trackerDrawWatts,
      };

  factory ElectronicsPowerState.fromJson(Map<String, dynamic> json) {
    return ElectronicsPowerState(
      headlightBatteryPercent:
          (json['headlightBatteryPercent'] as num?)?.toDouble() ?? 100.0,
      gpsComputerBatteryPercent:
          (json['gpsComputerBatteryPercent'] as num?)?.toDouble() ?? 100.0,
      trackerBatteryPercent:
          (json['trackerBatteryPercent'] as num?)?.toDouble() ?? 100.0,
      di2ShiftingBatteryPercent:
          (json['di2ShiftingBatteryPercent'] as num?)?.toDouble() ?? 100.0,
      powerBankMah: (json['powerBankMah'] as num?)?.toDouble() ?? 10000.0,
      powerBankCapacityMah:
          (json['powerBankCapacityMah'] as num?)?.toDouble() ?? 10000.0,
      isNightLightingActive: json['isNightLightingActive'] as bool? ?? false,
      headlightDrawWatts:
          (json['headlightDrawWatts'] as num?)?.toDouble() ?? 3.2,
      gpsDrawWatts: (json['gpsDrawWatts'] as num?)?.toDouble() ?? 0.9,
      trackerDrawWatts: (json['trackerDrawWatts'] as num?)?.toDouble() ?? 0.25,
    );
  }
}

/// Postęp kolarza w wyścigu Ultra-Endurance 4000 km non-stop.
class UltraBikepackingRiderProgress {
  final String riderId;
  final double distanceCoveredKm;
  final double elapsedHours;
  final double movingHours;
  final double stoppedHours;
  final double totalSleepHours;
  final double hoursSinceLastSleep;
  final double sleepDebtHours;
  final double cognitiveAlertnessPercent;
  final double hydrationLiters;
  final double caloriesDeficitKcal;
  final List<String> visitedCheckpointIds;
  final List<String> collectedStampIds;
  final double penaltiesHours;
  final ElectronicsPowerState electronicsState;
  final bool isScratched;
  final String? scratchReason;

  const UltraBikepackingRiderProgress({
    required this.riderId,
    this.distanceCoveredKm = 0.0,
    this.elapsedHours = 0.0,
    this.movingHours = 0.0,
    this.stoppedHours = 0.0,
    this.totalSleepHours = 0.0,
    this.hoursSinceLastSleep = 0.0,
    this.sleepDebtHours = 0.0,
    this.cognitiveAlertnessPercent = 100.0,
    this.hydrationLiters = 2.0,
    this.caloriesDeficitKcal = 0.0,
    this.visitedCheckpointIds = const [],
    this.collectedStampIds = const [],
    this.penaltiesHours = 0.0,
    this.electronicsState = const ElectronicsPowerState(),
    this.isScratched = false,
    this.scratchReason,
  });

  double get averageMovingSpeedKmh =>
      movingHours <= 0.0 ? 0.0 : distanceCoveredKm / movingHours;

  double get averageOverallSpeedKmh =>
      elapsedHours <= 0.0 ? 0.0 : distanceCoveredKm / elapsedHours;

  double remainingDistanceKm(double totalRaceDistanceKm) =>
      math.max(0.0, totalRaceDistanceKm - distanceCoveredKm);

  double get officialElapsedWithPenaltiesHours => elapsedHours + penaltiesHours;

  /// Mnożnik degradacji mocy wynikający z deficytu snu (0.68–1.0).
  double get sleepDeprivationPowerMultiplier {
    if (hoursSinceLastSleep <= 18.0 && sleepDebtHours <= 4.0) return 1.0;
    final acuteDrop = math.max(0.0, (hoursSinceLastSleep - 18.0) * 0.0065);
    final chronicDrop = math.max(0.0, (sleepDebtHours - 4.0) * 0.008);
    return (1.0 - acuteDrop - chronicDrop).clamp(0.68, 1.0);
  }

  /// Ryzyko halucynacji i błędu zjazdowego (0.0–1.0).
  double hallucinationAndCrashRisk({required bool isNight}) {
    final base = math.max(0.0, (hoursSinceLastSleep - 22.0) / 30.0);
    final nightMult = isNight ? 1.45 : 0.85;
    return (base * nightMult).clamp(0.0, 1.0);
  }

  /// Zastosowanie postoju na sen i ewentualnego ładowania elektroniki w hotelu.
  UltraBikepackingRiderProgress applySleepStop(
    UltraSleepStrategy strategy, {
    required bool isWarmShelter,
  }) {
    final sleepHours = strategy.durationHours;
    if (sleepHours <= 0.0) {
      return copyWith(
        cognitiveAlertnessPercent:
            (cognitiveAlertnessPercent - 12.0).clamp(15.0, 100.0),
      );
    }

    final shelterEfficiency = isWarmShelter ? 1.15 : 0.88;
    final recoveredAlertness = sleepHours * 18.0 * shelterEfficiency;
    final reducedDebt = math.max(0.0, sleepDebtHours - sleepHours * shelterEfficiency);

    var nextElectronics = electronicsState;
    if (strategy == UltraSleepStrategy.hotel5Hours) {
      nextElectronics = electronicsState.copyWith(
        headlightBatteryPercent: 100.0,
        gpsComputerBatteryPercent: 100.0,
        trackerBatteryPercent: 100.0,
        di2ShiftingBatteryPercent: 100.0,
        powerBankMah: electronicsState.powerBankCapacityMah,
      );
    }

    return copyWith(
      elapsedHours: elapsedHours + sleepHours,
      stoppedHours: stoppedHours + sleepHours,
      totalSleepHours: totalSleepHours + sleepHours,
      hoursSinceLastSleep: 0.0,
      sleepDebtHours: reducedDebt,
      cognitiveAlertnessPercent:
          (cognitiveAlertnessPercent + recoveredAlertness).clamp(0.0, 100.0),
      electronicsState: nextElectronics,
    );
  }

  UltraBikepackingRiderProgress copyWith({
    String? riderId,
    double? distanceCoveredKm,
    double? elapsedHours,
    double? movingHours,
    double? stoppedHours,
    double? totalSleepHours,
    double? hoursSinceLastSleep,
    double? sleepDebtHours,
    double? cognitiveAlertnessPercent,
    double? hydrationLiters,
    double? caloriesDeficitKcal,
    List<String>? visitedCheckpointIds,
    List<String>? collectedStampIds,
    double? penaltiesHours,
    ElectronicsPowerState? electronicsState,
    bool? isScratched,
    String? scratchReason,
  }) {
    return UltraBikepackingRiderProgress(
      riderId: riderId ?? this.riderId,
      distanceCoveredKm: distanceCoveredKm ?? this.distanceCoveredKm,
      elapsedHours: elapsedHours ?? this.elapsedHours,
      movingHours: movingHours ?? this.movingHours,
      stoppedHours: stoppedHours ?? this.stoppedHours,
      totalSleepHours: totalSleepHours ?? this.totalSleepHours,
      hoursSinceLastSleep: hoursSinceLastSleep ?? this.hoursSinceLastSleep,
      sleepDebtHours: sleepDebtHours ?? this.sleepDebtHours,
      cognitiveAlertnessPercent:
          cognitiveAlertnessPercent ?? this.cognitiveAlertnessPercent,
      hydrationLiters: hydrationLiters ?? this.hydrationLiters,
      caloriesDeficitKcal: caloriesDeficitKcal ?? this.caloriesDeficitKcal,
      visitedCheckpointIds: visitedCheckpointIds ?? this.visitedCheckpointIds,
      collectedStampIds: collectedStampIds ?? this.collectedStampIds,
      penaltiesHours: penaltiesHours ?? this.penaltiesHours,
      electronicsState: electronicsState ?? this.electronicsState,
      isScratched: isScratched ?? this.isScratched,
      scratchReason: scratchReason ?? this.scratchReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'distanceCoveredKm': distanceCoveredKm,
        'elapsedHours': elapsedHours,
        'movingHours': movingHours,
        'stoppedHours': stoppedHours,
        'totalSleepHours': totalSleepHours,
        'hoursSinceLastSleep': hoursSinceLastSleep,
        'sleepDebtHours': sleepDebtHours,
        'cognitiveAlertnessPercent': cognitiveAlertnessPercent,
        'hydrationLiters': hydrationLiters,
        'caloriesDeficitKcal': caloriesDeficitKcal,
        'visitedCheckpointIds': visitedCheckpointIds,
        'collectedStampIds': collectedStampIds,
        'penaltiesHours': penaltiesHours,
        'electronicsState': electronicsState.toJson(),
        'isScratched': isScratched,
        'scratchReason': scratchReason,
      };

  factory UltraBikepackingRiderProgress.fromJson(Map<String, dynamic> json) {
    return UltraBikepackingRiderProgress(
      riderId: json['riderId'] as String? ?? 'rider_1',
      distanceCoveredKm: (json['distanceCoveredKm'] as num?)?.toDouble() ?? 0.0,
      elapsedHours: (json['elapsedHours'] as num?)?.toDouble() ?? 0.0,
      movingHours: (json['movingHours'] as num?)?.toDouble() ?? 0.0,
      stoppedHours: (json['stoppedHours'] as num?)?.toDouble() ?? 0.0,
      totalSleepHours: (json['totalSleepHours'] as num?)?.toDouble() ?? 0.0,
      hoursSinceLastSleep:
          (json['hoursSinceLastSleep'] as num?)?.toDouble() ?? 0.0,
      sleepDebtHours: (json['sleepDebtHours'] as num?)?.toDouble() ?? 0.0,
      cognitiveAlertnessPercent:
          (json['cognitiveAlertnessPercent'] as num?)?.toDouble() ?? 100.0,
      hydrationLiters: (json['hydrationLiters'] as num?)?.toDouble() ?? 2.0,
      caloriesDeficitKcal:
          (json['caloriesDeficitKcal'] as num?)?.toDouble() ?? 0.0,
      visitedCheckpointIds:
          (json['visitedCheckpointIds'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      collectedStampIds:
          (json['collectedStampIds'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      penaltiesHours: (json['penaltiesHours'] as num?)?.toDouble() ?? 0.0,
      electronicsState: json['electronicsState'] is Map<String, dynamic>
          ? ElectronicsPowerState.fromJson(
              json['electronicsState'] as Map<String, dynamic>,
            )
          : const ElectronicsPowerState(),
      isScratched: json['isScratched'] as bool? ?? false,
      scratchReason: json['scratchReason'] as String?,
    );
  }
}

/// Raport gotowości zestawu bikepackingowego i dynama przed startem wyścigu 4000 km.
class UltraBikepackingReadinessReport {
  final bool isRaceLegal;
  final double totalPackWeightKg;
  final double totalAeroPenaltyWattsAt30Kmh;
  final double dynamoDragWattsAt25Kmh;
  final double netDynamoWattsAt25KmhNight;
  final List<String> missingMandatoryItems;
  final List<String> warnings;

  const UltraBikepackingReadinessReport({
    required this.isRaceLegal,
    required this.totalPackWeightKg,
    required this.totalAeroPenaltyWattsAt30Kmh,
    required this.dynamoDragWattsAt25Kmh,
    required this.netDynamoWattsAt25KmhNight,
    required this.missingMandatoryItems,
    required this.warnings,
  });
}

/// Główny model wyścigu Ultra-Endurance Bikepacking (4000 km non-stop).
class UltraEnduranceBikepackingRaceModel {
  final String id;
  final String name;
  final UltraBikepackingRaceSeries series;
  final double totalDistanceKm;
  final double totalElevationGainM;
  final double timeLimitHours;
  final List<UltraCheckpointSpec> checkpoints;
  final List<UltraRouteSegmentSpec> routeSegments;
  final bool selfSupportedDraftingForbidden;
  final bool nightLightsMandatory;
  final bool gpsTrackingMandatory;
  final BikepackingLoadout defaultLoadout;
  final DynamoHubSpec defaultDynamoHub;

  const UltraEnduranceBikepackingRaceModel({
    required this.id,
    required this.name,
    required this.series,
    this.totalDistanceKm = 4000.0,
    required this.totalElevationGainM,
    required this.timeLimitHours,
    required this.checkpoints,
    required this.routeSegments,
    this.selfSupportedDraftingForbidden = true,
    this.nightLightsMandatory = true,
    this.gpsTrackingMandatory = true,
    required this.defaultLoadout,
    required this.defaultDynamoHub,
  });

  List<UltraCheckpointSpec> get mandatoryCheckpoints =>
      checkpoints.where((cp) => cp.isMandatory).toList();

  /// Zwraca kolejny nieodwiedzony punkt kontrolny na podstawie listy odwiedzonych ID.
  UltraCheckpointSpec? nextPendingCheckpoint(List<String> visitedIds) {
    final visitedSet = visitedIds.toSet();
    for (final cp in checkpoints) {
      if (!visitedSet.contains(cp.id)) return cp;
    }
    return null;
  }

  /// Ocenia legalność oraz parametry fizyczne zestawu przed startem.
  UltraBikepackingReadinessReport evaluateSetupReadiness({
    required BikepackingLoadout loadout,
    required DynamoHubSpec dynamoHub,
    required ElectronicsPowerState electronics,
  }) {
    final missing = loadout.missingMandatoryItems;
    final warnings = <String>[];

    const speedMs30 = 30.0 / 3.6;
    final aeroW = loadout.totalAeroDragWatts(speedMs30);
    final dynamoDragW = dynamoHub.mechanicalDragWattsAtSpeed(25.0);
    final nightDrawW =
        electronics.headlightDrawWatts +
        electronics.gpsDrawWatts +
        electronics.trackerDrawWatts;
    final netDynamoW = dynamoHub.netChargingWatts(
      speedKmh: 25.0,
      activeLoadWatts: nightDrawW,
    );

    if (dynamoHub.tier == DynamoHubTier.noneBatteryOnly &&
        electronics.powerBankCapacityMah < 15000) {
      warnings.add(
        'Brak piasty z dynamem przy powerbanku <15000 mAh zwiększa ryzyko utraty świateł w nocy.',
      );
    }
    if (loadout.totalGearWeightKg > 6.5) {
      warnings.add(
        'Masa bagażu (${loadout.totalGearWeightKg.toStringAsFixed(1)} kg) przekracza optymalny próg wyścigowy 6.5 kg.',
      );
    }
    if (!loadout.isMandatoryGearComplete) {
      warnings.add('Brakuje obowiązkowego ekwipunku regulaminowego.');
    }

    return UltraBikepackingReadinessReport(
      isRaceLegal: missing.isEmpty,
      totalPackWeightKg: loadout.totalGearWeightKg,
      totalAeroPenaltyWattsAt30Kmh: aeroW,
      dynamoDragWattsAt25Kmh: dynamoDragW,
      netDynamoWattsAt25KmhNight: netDynamoW,
      missingMandatoryItems: missing,
      warnings: warnings,
    );
  }

  /// Symuluje pokonanie odcinka do kolejnego punktu kontrolnego (lub zadanej liczby godzin).
  UltraBikepackingRiderProgress simulateRidingBlock({
    required UltraBikepackingRiderProgress progress,
    required double durationHours,
    required double baseCruisingSpeedKmh,
    required BikepackingLoadout loadout,
    required DynamoHubSpec dynamoHub,
    required bool isNight,
    UltraRouteSegmentSpec? segment,
  }) {
    if (progress.isScratched || durationHours <= 0.0) return progress;

    final sleepMult = progress.sleepDeprivationPowerMultiplier;
    final surfaceMult =
        segment != null ? (1.0 / math.sqrt(segment.surfaceCrrMultiplier)) : 1.0;
    final weightPenaltyFactor =
        (1.0 - (loadout.totalGearWeightKg * 0.008)).clamp(0.88, 1.0);
    final nightFactor = isNight ? 0.89 : 1.0;

    final effectiveSpeedKmh = math.max(
      6.0,
      baseCruisingSpeedKmh *
          sleepMult *
          surfaceMult *
          weightPenaltyFactor *
          nightFactor,
    );

    final coveredKm = effectiveSpeedKmh * durationHours;
    final nextDistanceKm =
        math.min(totalDistanceKm, progress.distanceCoveredKm + coveredKm);
    final nextElapsed = progress.elapsedHours + durationHours;
    final nextMoving = progress.movingHours + durationHours;
    final nextSinceSleep = progress.hoursSinceLastSleep + durationHours;
    final extraSleepDebt = math.max(0.0, durationHours * 0.25);

    final powerStep = progress.electronicsState.stepPowerBudget(
      durationHours: durationHours,
      avgSpeedKmh: effectiveSpeedKmh,
      dynamoHub: dynamoHub,
      isNight: isNight,
    );

    final visited = List<String>.from(progress.visitedCheckpointIds);
    final stamps = List<String>.from(progress.collectedStampIds);
    var penaltyHours = progress.penaltiesHours;
    var scratched = progress.isScratched;
    var scratchReason = progress.scratchReason;

    for (final cp in checkpoints) {
      if (nextDistanceKm >= cp.distanceKm && !visited.contains(cp.id)) {
        visited.add(cp.id);
        if (cp.stampRequired) {
          stamps.add(cp.id);
        }
        if (!cp.isWithinCutoff(nextElapsed)) {
          scratched = true;
          scratchReason = 'Przekroczono limit czasu w punkcie ${cp.name}.';
        }
      }
    }

    if (nightLightsMandatory &&
        isNight &&
        powerStep.updatedState.headlightBatteryPercent <= 0.0) {
      penaltyHours +=
          UltraSelfSupportedRuleViolation.noWorkingLightsAtNight.defaultTimePenaltyHours;
    }

    final alertnessDrop = durationHours * (isNight ? 3.2 : 1.8);

    return progress.copyWith(
      distanceCoveredKm: nextDistanceKm,
      elapsedHours: nextElapsed,
      movingHours: nextMoving,
      hoursSinceLastSleep: nextSinceSleep,
      sleepDebtHours: progress.sleepDebtHours + extraSleepDebt,
      cognitiveAlertnessPercent:
          (progress.cognitiveAlertnessPercent - alertnessDrop).clamp(10.0, 100.0),
      visitedCheckpointIds: visited,
      collectedStampIds: stamps,
      penaltiesHours: penaltyHours,
      electronicsState: powerStep.updatedState,
      isScratched: scratched,
      scratchReason: scratchReason,
    );
  }

  UltraEnduranceBikepackingRaceModel copyWith({
    String? id,
    String? name,
    UltraBikepackingRaceSeries? series,
    double? totalDistanceKm,
    double? totalElevationGainM,
    double? timeLimitHours,
    List<UltraCheckpointSpec>? checkpoints,
    List<UltraRouteSegmentSpec>? routeSegments,
    bool? selfSupportedDraftingForbidden,
    bool? nightLightsMandatory,
    bool? gpsTrackingMandatory,
    BikepackingLoadout? defaultLoadout,
    DynamoHubSpec? defaultDynamoHub,
  }) {
    return UltraEnduranceBikepackingRaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      series: series ?? this.series,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      totalElevationGainM: totalElevationGainM ?? this.totalElevationGainM,
      timeLimitHours: timeLimitHours ?? this.timeLimitHours,
      checkpoints: checkpoints ?? this.checkpoints,
      routeSegments: routeSegments ?? this.routeSegments,
      selfSupportedDraftingForbidden:
          selfSupportedDraftingForbidden ?? this.selfSupportedDraftingForbidden,
      nightLightsMandatory: nightLightsMandatory ?? this.nightLightsMandatory,
      gpsTrackingMandatory: gpsTrackingMandatory ?? this.gpsTrackingMandatory,
      defaultLoadout: defaultLoadout ?? this.defaultLoadout,
      defaultDynamoHub: defaultDynamoHub ?? this.defaultDynamoHub,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'series': series.toJson(),
        'totalDistanceKm': totalDistanceKm,
        'totalElevationGainM': totalElevationGainM,
        'timeLimitHours': timeLimitHours,
        'checkpoints': checkpoints.map((c) => c.toJson()).toList(),
        'routeSegments': routeSegments.map((s) => s.toJson()).toList(),
        'selfSupportedDraftingForbidden': selfSupportedDraftingForbidden,
        'nightLightsMandatory': nightLightsMandatory,
        'gpsTrackingMandatory': gpsTrackingMandatory,
        'defaultLoadout': defaultLoadout.toJson(),
        'defaultDynamoHub': defaultDynamoHub.toJson(),
      };

  factory UltraEnduranceBikepackingRaceModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return UltraEnduranceBikepackingRaceModel(
      id: json['id'] as String? ?? 'ultra_tcr_4000',
      name: json['name'] as String? ?? 'Transcontinental 4000',
      series: UltraBikepackingRaceSeries.fromJson(
        json['series'] as String? ?? 'transcontinental',
      ),
      totalDistanceKm:
          (json['totalDistanceKm'] as num?)?.toDouble() ?? 4000.0,
      totalElevationGainM:
          (json['totalElevationGainM'] as num?)?.toDouble() ?? 42000.0,
      timeLimitHours: (json['timeLimitHours'] as num?)?.toDouble() ?? 360.0,
      checkpoints: (json['checkpoints'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(UltraCheckpointSpec.fromJson)
          .toList(),
      routeSegments: (json['routeSegments'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(UltraRouteSegmentSpec.fromJson)
          .toList(),
      selfSupportedDraftingForbidden:
          json['selfSupportedDraftingForbidden'] as bool? ?? true,
      nightLightsMandatory: json['nightLightsMandatory'] as bool? ?? true,
      gpsTrackingMandatory: json['gpsTrackingMandatory'] as bool? ?? true,
      defaultLoadout: json['defaultLoadout'] is Map<String, dynamic>
          ? BikepackingLoadout.fromJson(
              json['defaultLoadout'] as Map<String, dynamic>,
            )
          : BikepackingLoadout.ultraRaceMinimal(),
      defaultDynamoHub: json['defaultDynamoHub'] is Map<String, dynamic>
          ? DynamoHubSpec.fromJson(
              json['defaultDynamoHub'] as Map<String, dynamic>,
            )
          : DynamoHubSpec.son28Ultra(),
    );
  }

  /// Preset flagowego wyścigu Transcontinental 4000 km non-stop.
  factory UltraEnduranceBikepackingRaceModel.transcontinental4000KmPreset() {
    return UltraEnduranceBikepackingRaceModel(
      id: 'ultra_transcontinental_4000',
      name: 'Transcontinental Race 4000',
      series: UltraBikepackingRaceSeries.transcontinental,
      totalDistanceKm: 4000.0,
      totalElevationGainM: 43500.0,
      timeLimitHours: 360.0,
      checkpoints: const [
        UltraCheckpointSpec(
          id: 'cp_0_start',
          index: 0,
          name: 'Roubaix Velodrome (Start)',
          distanceKm: 0.0,
          elevationM: 32.0,
          type: UltraCheckpointType.startLine,
          cutOffHoursFromStart: 2.0,
          hasHotFood: true,
          hasBikeShop: true,
          hasLodging: true,
        ),
        UltraCheckpointSpec(
          id: 'cp_1_alps',
          index: 1,
          name: 'CP1 — Passo dello Stelvio (Parcours)',
          distanceKm: 1080.0,
          elevationM: 2758.0,
          type: UltraCheckpointType.parcoursSegment,
          mandatoryParcoursKm: 46.0,
          cutOffHoursFromStart: 105.0,
          hasHotFood: true,
          hasLodging: true,
        ),
        UltraCheckpointSpec(
          id: 'cp_2_balkans',
          index: 2,
          name: 'CP2 — Durmitor National Park',
          distanceKm: 2350.0,
          elevationM: 1456.0,
          type: UltraCheckpointType.mandatoryCheckpoint,
          mandatoryParcoursKm: 62.0,
          cutOffHoursFromStart: 220.0,
          hasHotFood: true,
          hasLodging: true,
        ),
        UltraCheckpointSpec(
          id: 'cp_3_carpathians',
          index: 3,
          name: 'CP3 — Transfagarasan Pass',
          distanceKm: 3240.0,
          elevationM: 2042.0,
          type: UltraCheckpointType.mountainRefuge,
          mandatoryParcoursKm: 54.0,
          cutOffHoursFromStart: 300.0,
          hasHotFood: true,
        ),
        UltraCheckpointSpec(
          id: 'cp_4_finish',
          index: 4,
          name: 'Constanta Black Sea (Finish)',
          distanceKm: 4000.0,
          elevationM: 12.0,
          type: UltraCheckpointType.finishLine,
          cutOffHoursFromStart: 360.0,
          hasHotFood: true,
          hasBikeShop: true,
          hasLodging: true,
        ),
      ],
      routeSegments: const [
        UltraRouteSegmentSpec(
          id: 'seg_1_benelux_alps',
          name: 'Roubaix -> Alpy Wschodnie',
          startKm: 0.0,
          endKm: 1080.0,
          elevationGainM: 12400.0,
          elevationLossM: 9674.0,
          asphaltRatio: 0.85,
          gravelRatio: 0.13,
          singletrackRatio: 0.02,
        ),
        UltraRouteSegmentSpec(
          id: 'seg_2_adriatic_durmitor',
          name: 'Alpy -> Góry Dynarskie',
          startKm: 1080.0,
          endKm: 2350.0,
          elevationGainM: 14200.0,
          elevationLossM: 15502.0,
          asphaltRatio: 0.72,
          gravelRatio: 0.24,
          singletrackRatio: 0.04,
          remoteWildernessFactor: 0.55,
        ),
        UltraRouteSegmentSpec(
          id: 'seg_3_balkan_carpathians',
          name: 'Durmitor -> Transfagarasan',
          startKm: 2350.0,
          endKm: 3240.0,
          elevationGainM: 11100.0,
          elevationLossM: 10514.0,
          asphaltRatio: 0.68,
          gravelRatio: 0.27,
          singletrackRatio: 0.05,
          remoteWildernessFactor: 0.65,
        ),
        UltraRouteSegmentSpec(
          id: 'seg_4_danube_blacksea',
          name: 'Karpaty -> Morze Czarne',
          startKm: 3240.0,
          endKm: 4000.0,
          elevationGainM: 5800.0,
          elevationLossM: 7830.0,
          asphaltRatio: 0.80,
          gravelRatio: 0.18,
          singletrackRatio: 0.02,
        ),
      ],
      defaultLoadout: BikepackingLoadout.ultraRaceMinimal(),
      defaultDynamoHub: DynamoHubSpec.son28Ultra(),
    );
  }
}
