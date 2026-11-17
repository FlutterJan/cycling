import 'dart:math' as math;

/// Kategoria przepisu w regulaminie Kolegium Sędziów UCI.
enum UciRuleCategory {
  sprintConduct,
  equipmentAndWeight,
  aeroPostureAndPosition,
  vehicleDraftingAndStickyBottle,
  feedingAndLittering,
  safetyAndEquipmentStandards;

  String toJson() => name;

  static UciRuleCategory fromJson(String value) {
    return UciRuleCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UciRuleCategory.sprintConduct,
    );
  }

  String get displayNamePl {
    switch (this) {
      case UciRuleCategory.sprintConduct:
        return 'Przepisy sprinterskie i finiszowe';
      case UciRuleCategory.equipmentAndWeight:
        return 'Sprzęt i limit wagi roweru';
      case UciRuleCategory.aeroPostureAndPosition:
        return 'Pozycja aerodynamiczna na rowerze';
      case UciRuleCategory.vehicleDraftingAndStickyBottle:
        return 'Pojazdy wyścigu i Sticky Bottle';
      case UciRuleCategory.feedingAndLittering:
        return 'Strefy bufetu i strefy ekologiczne';
      case UciRuleCategory.safetyAndEquipmentStandards:
        return 'Standardy bezpieczeństwa i wyposażenia';
    }
  }
}

/// Poziom sankcji przewidzianej w taryfikatorze UCI.
enum UciPenaltyTier {
  noAction,
  warning,
  fineChfOnly,
  yellowCard,
  timePenaltyAndPoints,
  relegation,
  disqualification;

  String toJson() => name;

  static UciPenaltyTier fromJson(String value) {
    return UciPenaltyTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UciPenaltyTier.warning,
    );
  }

  String get displayNamePl {
    switch (this) {
      case UciPenaltyTier.noAction:
        return 'Brak sankcji (czysty przejazd)';
      case UciPenaltyTier.warning:
        return 'Oficjalne ostrzeżenie';
      case UciPenaltyTier.fineChfOnly:
        return 'Grzywna finansowa (CHF)';
      case UciPenaltyTier.yellowCard:
        return 'Żółta kartka UCI';
      case UciPenaltyTier.timePenaltyAndPoints:
        return 'Kara czasowa i odjęcie punktów UCI';
      case UciPenaltyTier.relegation:
        return 'Relegacja na koniec grupy';
      case UciPenaltyTier.disqualification:
        return 'Dyskwalifikacja (DSQ)';
    }
  }
}

/// Typ kartki dyscyplinarnej UCI (system wprowadzony od 2024/2025).
enum UciCardType {
  none,
  yellow,
  redDisqualification;

  String toJson() => name;

  static UciCardType fromJson(String value) {
    return UciCardType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UciCardType.none,
    );
  }
}

/// Kąt kamery wykorzystywany w analizie wideo Sprint Deviation VAR.
enum SprintVarCameraAngle {
  overheadHelicopter,
  finishLineHeadOn,
  rearPelotonCam,
  sideBarrierTracking;

  String toJson() => name;

  static SprintVarCameraAngle fromJson(String value) {
    return SprintVarCameraAngle.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SprintVarCameraAngle.overheadHelicopter,
    );
  }

  /// Waga precyzji pomiaru odchylenia bocznego dla danej kamery (0.0–1.0).
  double get lateralMeasurementWeight {
    switch (this) {
      case SprintVarCameraAngle.overheadHelicopter:
        return 0.96;
      case SprintVarCameraAngle.finishLineHeadOn:
        return 0.92;
      case SprintVarCameraAngle.rearPelotonCam:
        return 0.78;
      case SprintVarCameraAngle.sideBarrierTracking:
        return 0.68;
    }
  }

  String get displayNamePl {
    switch (this) {
      case SprintVarCameraAngle.overheadHelicopter:
        return 'Kamera z helikoptera (z góry)';
      case SprintVarCameraAngle.finishLineHeadOn:
        return 'Kamera czołowa na linii mety';
      case SprintVarCameraAngle.rearPelotonCam:
        return 'Kamera z motocykla za peletonem';
      case SprintVarCameraAngle.sideBarrierTracking:
        return 'Kamera boczna wzdłuż barierek';
    }
  }
}

/// Status werdyktu analizy wideo Sprint Deviation VAR.
enum SprintVarVerdictStatus {
  cleanSprint,
  underReview,
  warningIssued,
  yellowCardAndRelegated,
  disqualified;

  String toJson() => name;

  static SprintVarVerdictStatus fromJson(String value) {
    return SprintVarVerdictStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SprintVarVerdictStatus.cleanSprint,
    );
  }

  String get displayNamePl {
    switch (this) {
      case SprintVarVerdictStatus.cleanSprint:
        return 'Czysty sprint — wynik zatwierdzony';
      case SprintVarVerdictStatus.underReview:
        return 'W trakcie analizy VAR';
      case SprintVarVerdictStatus.warningIssued:
        return 'Ostrzeżenie sędziowskie (bez relegacji)';
      case SprintVarVerdictStatus.yellowCardAndRelegated:
        return 'Żółta kartka i relegacja na koniec grupy';
      case SprintVarVerdictStatus.disqualified:
        return 'Dyskwalifikacja (DSQ) za niebezpieczny sprint';
    }
  }
}

/// Typ poprawki regulaminowej w dynamicznej ewolucji przepisów UCI.
enum UciAmendmentType {
  bikeWeightLimitChange,
  aeroPostureBanOrUpdate,
  handlebarAndLeverGeometry,
  sprintProtectionZoneChange,
  yellowCardThresholdUpdate,
  gearRatioCap,
  wheelRimDepthLimit;

  String toJson() => name;

  static UciAmendmentType fromJson(String value) {
    return UciAmendmentType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UciAmendmentType.bikeWeightLimitChange,
    );
  }
}

/// Pojedynczy artykuł w regulaminie UCI.
class UciRulebookArticle {
  final String articleCode;
  final UciRuleCategory category;
  final String titlePl;
  final String descriptionPl;
  final UciPenaltyTier defaultPenalty;
  final int baseFineChf;
  final int baseUciPointsPenalty;
  final int baseTimePenaltySeconds;
  final bool issuesYellowCard;
  final int effectiveFromYear;

  const UciRulebookArticle({
    required this.articleCode,
    required this.category,
    required this.titlePl,
    required this.descriptionPl,
    required this.defaultPenalty,
    this.baseFineChf = 0,
    this.baseUciPointsPenalty = 0,
    this.baseTimePenaltySeconds = 0,
    this.issuesYellowCard = false,
    this.effectiveFromYear = 2024,
  });

  UciRulebookArticle copyWith({
    String? articleCode,
    UciRuleCategory? category,
    String? titlePl,
    String? descriptionPl,
    UciPenaltyTier? defaultPenalty,
    int? baseFineChf,
    int? baseUciPointsPenalty,
    int? baseTimePenaltySeconds,
    bool? issuesYellowCard,
    int? effectiveFromYear,
  }) {
    return UciRulebookArticle(
      articleCode: articleCode ?? this.articleCode,
      category: category ?? this.category,
      titlePl: titlePl ?? this.titlePl,
      descriptionPl: descriptionPl ?? this.descriptionPl,
      defaultPenalty: defaultPenalty ?? this.defaultPenalty,
      baseFineChf: baseFineChf ?? this.baseFineChf,
      baseUciPointsPenalty: baseUciPointsPenalty ?? this.baseUciPointsPenalty,
      baseTimePenaltySeconds:
          baseTimePenaltySeconds ?? this.baseTimePenaltySeconds,
      issuesYellowCard: issuesYellowCard ?? this.issuesYellowCard,
      effectiveFromYear: effectiveFromYear ?? this.effectiveFromYear,
    );
  }

  Map<String, dynamic> toJson() => {
        'articleCode': articleCode,
        'category': category.toJson(),
        'titlePl': titlePl,
        'descriptionPl': descriptionPl,
        'defaultPenalty': defaultPenalty.toJson(),
        'baseFineChf': baseFineChf,
        'baseUciPointsPenalty': baseUciPointsPenalty,
        'baseTimePenaltySeconds': baseTimePenaltySeconds,
        'issuesYellowCard': issuesYellowCard,
        'effectiveFromYear': effectiveFromYear,
      };

  factory UciRulebookArticle.fromJson(Map<String, dynamic> json) {
    return UciRulebookArticle(
      articleCode: json['articleCode'] as String? ?? 'UCI Art. 2.12.007',
      category: UciRuleCategory.fromJson(json['category'] as String? ?? ''),
      titlePl: json['titlePl'] as String? ?? '',
      descriptionPl: json['descriptionPl'] as String? ?? '',
      defaultPenalty:
          UciPenaltyTier.fromJson(json['defaultPenalty'] as String? ?? ''),
      baseFineChf: (json['baseFineChf'] as num?)?.toInt() ?? 0,
      baseUciPointsPenalty:
          (json['baseUciPointsPenalty'] as num?)?.toInt() ?? 0,
      baseTimePenaltySeconds:
          (json['baseTimePenaltySeconds'] as num?)?.toInt() ?? 0,
      issuesYellowCard: json['issuesYellowCard'] as bool? ?? false,
      effectiveFromYear: (json['effectiveFromYear'] as num?)?.toInt() ?? 2024,
    );
  }
}

/// Poprawka regulaminowa wprowadzona w konkretnym sezonie kariery.
class UciRuleAmendment {
  final String id;
  final int seasonYear;
  final UciAmendmentType type;
  final String titlePl;
  final String summaryPl;
  final double? previousNumericValue;
  final double? newNumericValue;
  final String? affectedPostureKey;
  final bool? postureAllowed;

  const UciRuleAmendment({
    required this.id,
    required this.seasonYear,
    required this.type,
    required this.titlePl,
    required this.summaryPl,
    this.previousNumericValue,
    this.newNumericValue,
    this.affectedPostureKey,
    this.postureAllowed,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'seasonYear': seasonYear,
        'type': type.toJson(),
        'titlePl': titlePl,
        'summaryPl': summaryPl,
        'previousNumericValue': previousNumericValue,
        'newNumericValue': newNumericValue,
        'affectedPostureKey': affectedPostureKey,
        'postureAllowed': postureAllowed,
      };

  factory UciRuleAmendment.fromJson(Map<String, dynamic> json) {
    return UciRuleAmendment(
      id: json['id'] as String? ?? '',
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2025,
      type: UciAmendmentType.fromJson(json['type'] as String? ?? ''),
      titlePl: json['titlePl'] as String? ?? '',
      summaryPl: json['summaryPl'] as String? ?? '',
      previousNumericValue:
          (json['previousNumericValue'] as num?)?.toDouble(),
      newNumericValue: (json['newNumericValue'] as num?)?.toDouble(),
      affectedPostureKey: json['affectedPostureKey'] as String?,
      postureAllowed: json['postureAllowed'] as bool?,
    );
  }
}

/// Pełna edycja regulaminu UCI obowiązująca w danym roku kariery.
class UciRulebookEdition {
  final int seasonYear;
  final double minBikeWeightKg;
  final double minHandlebarWidthCm;
  final double maxBrakeLeverInwardDeg;
  final double maxRimDepthMm;
  final double maxSockHeightRatio;
  final bool supertuckBanned;
  final bool puppyPawsBanned;
  final bool invisibleAerobarsBanned;
  final bool yellowCardSystemActive;
  final int yellowCardsForRaceDsq;
  final double sprintDeviationToleranceMeters;
  final double finalKmProtectionDistanceKm;
  final double stickyBottleMaxSeconds;
  final int? maxGearRolloutMeters;
  final List<UciRulebookArticle> articles;

  const UciRulebookEdition({
    required this.seasonYear,
    this.minBikeWeightKg = 6.80,
    this.minHandlebarWidthCm = 35.0,
    this.maxBrakeLeverInwardDeg = 10.0,
    this.maxRimDepthMm = 80.0,
    this.maxSockHeightRatio = 0.50,
    this.supertuckBanned = true,
    this.puppyPawsBanned = true,
    this.invisibleAerobarsBanned = true,
    this.yellowCardSystemActive = true,
    this.yellowCardsForRaceDsq = 2,
    this.sprintDeviationToleranceMeters = 0.85,
    this.finalKmProtectionDistanceKm = 3.0,
    this.stickyBottleMaxSeconds = 5.0,
    this.maxGearRolloutMeters,
    this.articles = const [],
  });

  /// Domyślny regulamin bazowy UCI (np. sezon 2024/2025).
  factory UciRulebookEdition.baseline({int seasonYear = 2025}) {
    return UciRulebookEdition(
      seasonYear: seasonYear,
      minBikeWeightKg: 6.80,
      minHandlebarWidthCm: 35.0,
      maxBrakeLeverInwardDeg: 10.0,
      maxRimDepthMm: 80.0,
      maxSockHeightRatio: 0.50,
      supertuckBanned: true,
      puppyPawsBanned: true,
      invisibleAerobarsBanned: true,
      yellowCardSystemActive: true,
      yellowCardsForRaceDsq: 2,
      sprintDeviationToleranceMeters: 0.85,
      finalKmProtectionDistanceKm: 3.0,
      stickyBottleMaxSeconds: 5.0,
      articles: defaultArticles(seasonYear: seasonYear),
    );
  }

  static List<UciRulebookArticle> defaultArticles({int seasonYear = 2025}) {
    return [
      UciRulebookArticle(
        articleCode: 'UCI Art. 1.3.019',
        category: UciRuleCategory.equipmentAndWeight,
        titlePl: 'Minimalna masa roweru wyścigowego',
        descriptionPl:
            'Rower gotowy do startu (bez bidonów i komputera) musi spełniać aktualny limit masy UCI.',
        defaultPenalty: UciPenaltyTier.disqualification,
        baseFineChf: 2000,
        effectiveFromYear: seasonYear,
      ),
      const UciRulebookArticle(
        articleCode: 'UCI Art. 2.2.025',
        category: UciRuleCategory.aeroPostureAndPosition,
        titlePl: 'Zakaz niebezpiecznych pozycji aerodynamicznych',
        descriptionPl:
            'Zakaz zjazdu na ramie (Supertuck) oraz opierania przedramion na kierownicy bez przystawki (Puppy Paws).',
        defaultPenalty: UciPenaltyTier.yellowCard,
        baseFineChf: 500,
        baseUciPointsPenalty: 25,
        issuesYellowCard: true,
        effectiveFromYear: 2021,
      ),
      const UciRulebookArticle(
        articleCode: 'UCI Art. 2.12.007 / 5.1',
        category: UciRuleCategory.sprintConduct,
        titlePl: 'Odbiegnięcie od toru jazdy w sprincie (Sprint Deviation)',
        descriptionPl:
            'Kolarz musi utrzymać obrany tor jazdy na ostatnich 250 m i nie może zajeżdżać drogi rywalom.',
        defaultPenalty: UciPenaltyTier.relegation,
        baseFineChf: 500,
        baseUciPointsPenalty: 20,
        issuesYellowCard: true,
        effectiveFromYear: 2024,
      ),
      const UciRulebookArticle(
        articleCode: 'UCI Art. 2.12.007 / 4.2',
        category: UciRuleCategory.vehicleDraftingAndStickyBottle,
        titlePl: 'Przedłużone podawanie bidonu (Sticky Bottle)',
        descriptionPl:
            'Kontakt dłoni kolarza z bidonem przy wozie technicznym nie może przekraczać 5 sekund.',
        defaultPenalty: UciPenaltyTier.timePenaltyAndPoints,
        baseFineChf: 200,
        baseTimePenaltySeconds: 20,
        baseUciPointsPenalty: 10,
        effectiveFromYear: 2020,
      ),
      const UciRulebookArticle(
        articleCode: 'UCI Art. 2.2.025 / Green',
        category: UciRuleCategory.feedingAndLittering,
        titlePl: 'Wyrzucanie odpadków poza strefą Green Zone',
        descriptionPl:
            'Pozbywanie się bidonów lub opakowań po żelach poza wyznaczoną strefą bufetu i zbiórki.',
        defaultPenalty: UciPenaltyTier.timePenaltyAndPoints,
        baseFineChf: 500,
        baseTimePenaltySeconds: 30,
        baseUciPointsPenalty: 15,
        issuesYellowCard: true,
        effectiveFromYear: 2022,
      ),
    ];
  }

  UciRulebookEdition copyWith({
    int? seasonYear,
    double? minBikeWeightKg,
    double? minHandlebarWidthCm,
    double? maxBrakeLeverInwardDeg,
    double? maxRimDepthMm,
    double? maxSockHeightRatio,
    bool? supertuckBanned,
    bool? puppyPawsBanned,
    bool? invisibleAerobarsBanned,
    bool? yellowCardSystemActive,
    int? yellowCardsForRaceDsq,
    double? sprintDeviationToleranceMeters,
    double? finalKmProtectionDistanceKm,
    double? stickyBottleMaxSeconds,
    int? maxGearRolloutMeters,
    bool clearMaxGearRollout = false,
    List<UciRulebookArticle>? articles,
  }) {
    return UciRulebookEdition(
      seasonYear: seasonYear ?? this.seasonYear,
      minBikeWeightKg: minBikeWeightKg ?? this.minBikeWeightKg,
      minHandlebarWidthCm: minHandlebarWidthCm ?? this.minHandlebarWidthCm,
      maxBrakeLeverInwardDeg:
          maxBrakeLeverInwardDeg ?? this.maxBrakeLeverInwardDeg,
      maxRimDepthMm: maxRimDepthMm ?? this.maxRimDepthMm,
      maxSockHeightRatio: maxSockHeightRatio ?? this.maxSockHeightRatio,
      supertuckBanned: supertuckBanned ?? this.supertuckBanned,
      puppyPawsBanned: puppyPawsBanned ?? this.puppyPawsBanned,
      invisibleAerobarsBanned:
          invisibleAerobarsBanned ?? this.invisibleAerobarsBanned,
      yellowCardSystemActive:
          yellowCardSystemActive ?? this.yellowCardSystemActive,
      yellowCardsForRaceDsq:
          yellowCardsForRaceDsq ?? this.yellowCardsForRaceDsq,
      sprintDeviationToleranceMeters:
          sprintDeviationToleranceMeters ?? this.sprintDeviationToleranceMeters,
      finalKmProtectionDistanceKm:
          finalKmProtectionDistanceKm ?? this.finalKmProtectionDistanceKm,
      stickyBottleMaxSeconds:
          stickyBottleMaxSeconds ?? this.stickyBottleMaxSeconds,
      maxGearRolloutMeters: clearMaxGearRollout
          ? null
          : (maxGearRolloutMeters ?? this.maxGearRolloutMeters),
      articles: articles ?? this.articles,
    );
  }

  Map<String, dynamic> toJson() => {
        'seasonYear': seasonYear,
        'minBikeWeightKg': minBikeWeightKg,
        'minHandlebarWidthCm': minHandlebarWidthCm,
        'maxBrakeLeverInwardDeg': maxBrakeLeverInwardDeg,
        'maxRimDepthMm': maxRimDepthMm,
        'maxSockHeightRatio': maxSockHeightRatio,
        'supertuckBanned': supertuckBanned,
        'puppyPawsBanned': puppyPawsBanned,
        'invisibleAerobarsBanned': invisibleAerobarsBanned,
        'yellowCardSystemActive': yellowCardSystemActive,
        'yellowCardsForRaceDsq': yellowCardsForRaceDsq,
        'sprintDeviationToleranceMeters': sprintDeviationToleranceMeters,
        'finalKmProtectionDistanceKm': finalKmProtectionDistanceKm,
        'stickyBottleMaxSeconds': stickyBottleMaxSeconds,
        'maxGearRolloutMeters': maxGearRolloutMeters,
        'articles': articles.map((a) => a.toJson()).toList(),
      };

  factory UciRulebookEdition.fromJson(Map<String, dynamic> json) {
    final rawArticles = json['articles'] as List<dynamic>? ?? const [];
    return UciRulebookEdition(
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2025,
      minBikeWeightKg:
          (json['minBikeWeightKg'] as num?)?.toDouble() ?? 6.80,
      minHandlebarWidthCm:
          (json['minHandlebarWidthCm'] as num?)?.toDouble() ?? 35.0,
      maxBrakeLeverInwardDeg:
          (json['maxBrakeLeverInwardDeg'] as num?)?.toDouble() ?? 10.0,
      maxRimDepthMm: (json['maxRimDepthMm'] as num?)?.toDouble() ?? 80.0,
      maxSockHeightRatio:
          (json['maxSockHeightRatio'] as num?)?.toDouble() ?? 0.50,
      supertuckBanned: json['supertuckBanned'] as bool? ?? true,
      puppyPawsBanned: json['puppyPawsBanned'] as bool? ?? true,
      invisibleAerobarsBanned:
          json['invisibleAerobarsBanned'] as bool? ?? true,
      yellowCardSystemActive:
          json['yellowCardSystemActive'] as bool? ?? true,
      yellowCardsForRaceDsq:
          (json['yellowCardsForRaceDsq'] as num?)?.toInt() ?? 2,
      sprintDeviationToleranceMeters:
          (json['sprintDeviationToleranceMeters'] as num?)?.toDouble() ?? 0.85,
      finalKmProtectionDistanceKm:
          (json['finalKmProtectionDistanceKm'] as num?)?.toDouble() ?? 3.0,
      stickyBottleMaxSeconds:
          (json['stickyBottleMaxSeconds'] as num?)?.toDouble() ?? 5.0,
      maxGearRolloutMeters:
          (json['maxGearRolloutMeters'] as num?)?.toInt(),
      articles: rawArticles
          .whereType<Map<String, dynamic>>()
          .map(UciRulebookArticle.fromJson)
          .toList(),
    );
  }
}

/// Wynik kontroli technicznej roweru i pozycji kolarza przed lub po etapie.
class EquipmentComplianceCheckResult {
  final bool isCompliant;
  final List<String> violationsPl;
  final int totalFineChf;
  final bool resultsInDisqualification;

  const EquipmentComplianceCheckResult({
    required this.isCompliant,
    required this.violationsPl,
    required this.totalFineChf,
    required this.resultsInDisqualification,
  });

  Map<String, dynamic> toJson() => {
        'isCompliant': isCompliant,
        'violationsPl': violationsPl,
        'totalFineChf': totalFineChf,
        'resultsInDisqualification': resultsInDisqualification,
      };

  factory EquipmentComplianceCheckResult.fromJson(Map<String, dynamic> json) {
    return EquipmentComplianceCheckResult(
      isCompliant: json['isCompliant'] as bool? ?? true,
      violationsPl: (json['violationsPl'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      totalFineChf: (json['totalFineChf'] as num?)?.toInt() ?? 0,
      resultsInDisqualification:
          json['resultsInDisqualification'] as bool? ?? false,
    );
  }
}

/// Pojedyncza próbka telemetrii wideo z ostatnich 250 m sprintu.
class SprintVarFrameSample {
  final double timestampSeconds;
  final double distanceToFinishMeters;

  /// Pozycja poprzeczna na jezdni w metrach (np. 0.0 = lewa barierka, 8.0 = prawa).
  final double lateralPositionMeters;
  final double speedKmh;
  final double nearestRivalClearanceMeters;

  const SprintVarFrameSample({
    required this.timestampSeconds,
    required this.distanceToFinishMeters,
    required this.lateralPositionMeters,
    required this.speedKmh,
    required this.nearestRivalClearanceMeters,
  });

  Map<String, dynamic> toJson() => {
        'timestampSeconds': timestampSeconds,
        'distanceToFinishMeters': distanceToFinishMeters,
        'lateralPositionMeters': lateralPositionMeters,
        'speedKmh': speedKmh,
        'nearestRivalClearanceMeters': nearestRivalClearanceMeters,
      };

  factory SprintVarFrameSample.fromJson(Map<String, dynamic> json) {
    return SprintVarFrameSample(
      timestampSeconds:
          (json['timestampSeconds'] as num?)?.toDouble() ?? 0.0,
      distanceToFinishMeters:
          (json['distanceToFinishMeters'] as num?)?.toDouble() ?? 0.0,
      lateralPositionMeters:
          (json['lateralPositionMeters'] as num?)?.toDouble() ?? 4.0,
      speedKmh: (json['speedKmh'] as num?)?.toDouble() ?? 60.0,
      nearestRivalClearanceMeters:
          (json['nearestRivalClearanceMeters'] as num?)?.toDouble() ?? 1.5,
    );
  }
}

/// Dane wejściowe incydentu sprinterskiego przekazanego do systemu VAR.
class SprintVarIncidentInput {
  final String incidentId;
  final String stageId;
  final String riderId;
  final String riderName;
  final String teamId;
  final int finishingPosition;
  final int groupEndPosition;
  final double roadWidthMeters;
  final List<SprintVarFrameSample> trajectorySamples;
  final List<SprintVarCameraAngle> availableCameras;
  final bool rivalForcedToBrake;
  final bool causedCrash;
  final bool handOffHandlebarOrElbow;
  final bool rainOrLowVisibility;

  const SprintVarIncidentInput({
    required this.incidentId,
    required this.stageId,
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.finishingPosition,
    required this.groupEndPosition,
    this.roadWidthMeters = 8.0,
    this.trajectorySamples = const [],
    this.availableCameras = const [
      SprintVarCameraAngle.overheadHelicopter,
      SprintVarCameraAngle.finishLineHeadOn,
    ],
    this.rivalForcedToBrake = false,
    this.causedCrash = false,
    this.handOffHandlebarOrElbow = false,
    this.rainOrLowVisibility = false,
  });
}

/// Wynik analizy wideo VAR sprintu (`Sprint Deviation VAR`).
class SprintVarVerdict {
  final String incidentId;
  final String stageId;
  final String riderId;
  final String riderName;
  final String teamId;
  final SprintVarVerdictStatus status;
  final UciCardType cardIssued;
  final int originalPosition;
  final int finalPosition;
  final double maxLateralDeviationMeters;
  final double peakLateralVelocityMps;
  final double minimumRivalClearanceMeters;
  final double lineHoldingScore;
  final double varConfidenceScore;
  final int fineChf;
  final int uciPointsDeducted;
  final bool isAppealable;
  final bool appealSubmitted;
  final bool? appealUpheld;
  final String rationalePl;

  const SprintVarVerdict({
    required this.incidentId,
    required this.stageId,
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.status,
    required this.cardIssued,
    required this.originalPosition,
    required this.finalPosition,
    required this.maxLateralDeviationMeters,
    required this.peakLateralVelocityMps,
    required this.minimumRivalClearanceMeters,
    required this.lineHoldingScore,
    required this.varConfidenceScore,
    required this.fineChf,
    required this.uciPointsDeducted,
    required this.isAppealable,
    this.appealSubmitted = false,
    this.appealUpheld,
    required this.rationalePl,
  });

  SprintVarVerdict copyWith({
    SprintVarVerdictStatus? status,
    UciCardType? cardIssued,
    int? finalPosition,
    int? fineChf,
    int? uciPointsDeducted,
    bool? isAppealable,
    bool? appealSubmitted,
    bool? appealUpheld,
    String? rationalePl,
  }) {
    return SprintVarVerdict(
      incidentId: incidentId,
      stageId: stageId,
      riderId: riderId,
      riderName: riderName,
      teamId: teamId,
      status: status ?? this.status,
      cardIssued: cardIssued ?? this.cardIssued,
      originalPosition: originalPosition,
      finalPosition: finalPosition ?? this.finalPosition,
      maxLateralDeviationMeters: maxLateralDeviationMeters,
      peakLateralVelocityMps: peakLateralVelocityMps,
      minimumRivalClearanceMeters: minimumRivalClearanceMeters,
      lineHoldingScore: lineHoldingScore,
      varConfidenceScore: varConfidenceScore,
      fineChf: fineChf ?? this.fineChf,
      uciPointsDeducted: uciPointsDeducted ?? this.uciPointsDeducted,
      isAppealable: isAppealable ?? this.isAppealable,
      appealSubmitted: appealSubmitted ?? this.appealSubmitted,
      appealUpheld: appealUpheld ?? this.appealUpheld,
      rationalePl: rationalePl ?? this.rationalePl,
    );
  }

  Map<String, dynamic> toJson() => {
        'incidentId': incidentId,
        'stageId': stageId,
        'riderId': riderId,
        'riderName': riderName,
        'teamId': teamId,
        'status': status.toJson(),
        'cardIssued': cardIssued.name,
        'originalPosition': originalPosition,
        'finalPosition': finalPosition,
        'maxLateralDeviationMeters': maxLateralDeviationMeters,
        'peakLateralVelocityMps': peakLateralVelocityMps,
        'minimumRivalClearanceMeters': minimumRivalClearanceMeters,
        'lineHoldingScore': lineHoldingScore,
        'varConfidenceScore': varConfidenceScore,
        'fineChf': fineChf,
        'uciPointsDeducted': uciPointsDeducted,
        'isAppealable': isAppealable,
        'appealSubmitted': appealSubmitted,
        'appealUpheld': appealUpheld,
        'rationalePl': rationalePl,
      };

  factory SprintVarVerdict.fromJson(Map<String, dynamic> json) {
    return SprintVarVerdict(
      incidentId: json['incidentId'] as String? ?? '',
      stageId: json['stageId'] as String? ?? '',
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? '',
      teamId: json['teamId'] as String? ?? '',
      status: SprintVarVerdictStatus.fromJson(json['status'] as String? ?? ''),
      cardIssued: UciCardType.fromJson(json['cardIssued'] as String? ?? ''),
      originalPosition: (json['originalPosition'] as num?)?.toInt() ?? 1,
      finalPosition: (json['finalPosition'] as num?)?.toInt() ?? 1,
      maxLateralDeviationMeters:
          (json['maxLateralDeviationMeters'] as num?)?.toDouble() ?? 0.0,
      peakLateralVelocityMps:
          (json['peakLateralVelocityMps'] as num?)?.toDouble() ?? 0.0,
      minimumRivalClearanceMeters:
          (json['minimumRivalClearanceMeters'] as num?)?.toDouble() ?? 1.0,
      lineHoldingScore:
          (json['lineHoldingScore'] as num?)?.toDouble() ?? 100.0,
      varConfidenceScore:
          (json['varConfidenceScore'] as num?)?.toDouble() ?? 0.9,
      fineChf: (json['fineChf'] as num?)?.toInt() ?? 0,
      uciPointsDeducted:
          (json['uciPointsDeducted'] as num?)?.toInt() ?? 0,
      isAppealable: json['isAppealable'] as bool? ?? false,
      appealSubmitted: json['appealSubmitted'] as bool? ?? false,
      appealUpheld: json['appealUpheld'] as bool?,
      rationalePl: json['rationalePl'] as String? ?? '',
    );
  }
}

/// Analizator wideo VAR dla incydentów sprinterskich (`Sprint Deviation VAR`).
class SprintDeviationVarAnalyzer {
  const SprintDeviationVarAnalyzer();

  /// Analizuje trajektorię kolarza na finiszu względem aktualnego regulaminu UCI.
  SprintVarVerdict analyze({
    required SprintVarIncidentInput input,
    required UciRulebookEdition rulebook,
  }) {
    final samples = input.trajectorySamples;
    double maxDeviation = 0.0;
    double peakLateralVel = 0.0;
    double minClearance = 3.0;

    if (samples.isNotEmpty) {
      final baselineLat = samples.first.lateralPositionMeters;
      for (var i = 0; i < samples.length; i++) {
        final s = samples[i];
        final dev = (s.lateralPositionMeters - baselineLat).abs();
        if (dev > maxDeviation) {
          maxDeviation = dev;
        }
        if (s.nearestRivalClearanceMeters < minClearance) {
          minClearance = s.nearestRivalClearanceMeters;
        }
        if (i > 0) {
          final prev = samples[i - 1];
          final dt = (s.timestampSeconds - prev.timestampSeconds).abs();
          if (dt > 0.001) {
            final latVel =
                (s.lateralPositionMeters - prev.lateralPositionMeters).abs() /
                    dt;
            if (latVel > peakLateralVel) {
              peakLateralVel = latVel;
            }
          }
        }
      }
    }

    // Pewność VAR na podstawie dostępnych kamer i widoczności.
    var camConfidence = 0.55;
    if (input.availableCameras.isNotEmpty) {
      final bestWeight = input.availableCameras
          .map((c) => c.lateralMeasurementWeight)
          .reduce(math.max);
      final multiCamBonus =
          math.min(0.08, (input.availableCameras.length - 1) * 0.03);
      camConfidence = bestWeight + multiCamBonus;
    }
    if (input.rainOrLowVisibility) {
      camConfidence -= 0.10;
    }
    final varConfidence = camConfidence.clamp(0.35, 0.99);

    // Ocena trzymania toru jazdy (0..100).
    final deviationRatio =
        maxDeviation / math.max(0.25, rulebook.sprintDeviationToleranceMeters);
    var lineScore = 100.0 - (deviationRatio * 34.0) - (peakLateralVel * 7.5);
    if (input.rivalForcedToBrake) lineScore -= 18.0;
    if (input.handOffHandlebarOrElbow) lineScore -= 15.0;
    if (input.causedCrash) lineScore -= 35.0;
    lineScore = lineScore.clamp(0.0, 100.0);

    // Logika wydania werdyktu sędziowskiego.
    final tolerance = rulebook.sprintDeviationToleranceMeters;
    final severeDeviation = maxDeviation > tolerance * 1.45;
    final moderateDeviation = maxDeviation > tolerance;
    final closeEncroachment = minClearance < 0.45;

    SprintVarVerdictStatus status;
    UciCardType card = UciCardType.none;
    int finalPos = input.finishingPosition;
    int fineChf = 0;
    int pointsDeducted = 0;
    String rationale;

    if (input.causedCrash &&
        (moderateDeviation || input.handOffHandlebarOrElbow)) {
      status = SprintVarVerdictStatus.disqualified;
      card = rulebook.yellowCardSystemActive
          ? UciCardType.redDisqualification
          : UciCardType.none;
      finalPos = math.max(input.groupEndPosition, input.finishingPosition);
      fineChf = 1000;
      pointsDeducted = 50;
      rationale =
          'Spowodowanie kraksy na finiszu (odchylenie ${maxDeviation.toStringAsFixed(2)} m) — dyskwalifikacja.';
    } else if (severeDeviation ||
        (moderateDeviation &&
            (input.rivalForcedToBrake || closeEncroachment)) ||
        (input.handOffHandlebarOrElbow && closeEncroachment)) {
      status = SprintVarVerdictStatus.yellowCardAndRelegated;
      card = rulebook.yellowCardSystemActive
          ? UciCardType.yellow
          : UciCardType.none;
      finalPos = math.max(input.groupEndPosition, input.finishingPosition);
      fineChf = 500;
      pointsDeducted = 20;
      rationale =
          'Nieprzepisowa zmiana toru jazdy (${maxDeviation.toStringAsFixed(2)} m > limit ${tolerance.toStringAsFixed(2)} m) i zagrożenie dla rywala — relegacja na pozycję $finalPos.';
    } else if (moderateDeviation || input.handOffHandlebarOrElbow) {
      status = SprintVarVerdictStatus.warningIssued;
      card = UciCardType.none;
      fineChf = 200;
      rationale =
          'Niewielkie odchylenie toru (${maxDeviation.toStringAsFixed(2)} m) bez wymuszenia hamowania — oficjalne ostrzeżenie.';
    } else {
      status = SprintVarVerdictStatus.cleanSprint;
      rationale =
          'Tor jazdy utrzymany w granicach tolerancji UCI (${maxDeviation.toStringAsFixed(2)} m <= ${tolerance.toStringAsFixed(2)} m).';
    }

    final isAppealable = (status == SprintVarVerdictStatus.yellowCardAndRelegated ||
            status == SprintVarVerdictStatus.warningIssued) &&
        !input.causedCrash &&
        varConfidence < 0.94;

    return SprintVarVerdict(
      incidentId: input.incidentId,
      stageId: input.stageId,
      riderId: input.riderId,
      riderName: input.riderName,
      teamId: input.teamId,
      status: status,
      cardIssued: card,
      originalPosition: input.finishingPosition,
      finalPosition: finalPos,
      maxLateralDeviationMeters: maxDeviation,
      peakLateralVelocityMps: peakLateralVel,
      minimumRivalClearanceMeters: minClearance,
      lineHoldingScore: lineScore,
      varConfidenceScore: varConfidence,
      fineChf: fineChf,
      uciPointsDeducted: pointsDeducted,
      isAppealable: isAppealable,
      rationalePl: rationale,
    );
  }

  /// Rozpatruje odwołanie dyrektora sportowego od werdyktu VAR.
  SprintVarVerdict processAppeal({
    required SprintVarVerdict verdict,
    required double teamEvidenceStrength,
  }) {
    if (!verdict.isAppealable || verdict.appealSubmitted) {
      return verdict;
    }
    final clampedEvidence = teamEvidenceStrength.clamp(0.0, 1.0);
    // Szansa powodzenia rośnie przy niskiej pewności VAR i mocnej telemetrii drużyny.
    final threshold = verdict.varConfidenceScore * 0.85;
    final upheld = clampedEvidence > threshold;

    if (upheld) {
      return verdict.copyWith(
        status: SprintVarVerdictStatus.cleanSprint,
        cardIssued: UciCardType.none,
        finalPosition: verdict.originalPosition,
        fineChf: 0,
        uciPointsDeducted: 0,
        isAppealable: false,
        appealSubmitted: true,
        appealUpheld: true,
        rationalePl:
            'Odwołanie drużyny uwzględnione przez Kolegium Sędziów — przywrócono pozycję ${verdict.originalPosition}.',
      );
    }

    return verdict.copyWith(
      isAppealable: false,
      appealSubmitted: true,
      appealUpheld: false,
      rationalePl: '${verdict.rationalePl} Odwołanie odrzucone po powtórce VAR.',
    );
  }
}

/// Główny model przepisów sędziowskich UCI, analizy Sprint Deviation VAR i ewolucji regulaminów.
class UciCommissaireRulebookAndVarModel {
  final UciRulebookEdition activeRulebook;
  final List<UciRuleAmendment> evolutionHistory;
  final List<SprintVarVerdict> varVerdicts;
  final Map<String, int> riderYellowCardsInRace;
  final Map<String, int> riderYellowCardsRolling30Days;
  final Map<String, int> riderSuspensionDays;

  const UciCommissaireRulebookAndVarModel({
    required this.activeRulebook,
    this.evolutionHistory = const [],
    this.varVerdicts = const [],
    this.riderYellowCardsInRace = const {},
    this.riderYellowCardsRolling30Days = const {},
    this.riderSuspensionDays = const {},
  });

  factory UciCommissaireRulebookAndVarModel.initial({int seasonYear = 2025}) {
    return UciCommissaireRulebookAndVarModel(
      activeRulebook: UciRulebookEdition.baseline(seasonYear: seasonYear),
    );
  }

  /// Sprawdza zgodność sprzętu i pozycji kolarza z aktualnym regulaminem UCI.
  EquipmentComplianceCheckResult checkEquipmentAndPostureCompliance({
    required double bikeWeightKg,
    required double handlebarWidthCm,
    required double brakeLeverInwardDeg,
    required double rimDepthMm,
    required double sockHeightRatio,
    bool usesSupertuck = false,
    bool usesPuppyPaws = false,
    bool usesInvisibleAerobars = false,
    int? gearRolloutMeters,
  }) {
    final violations = <String>[];
    var fineChf = 0;
    var dsq = false;

    if (bikeWeightKg + 1e-6 < activeRulebook.minBikeWeightKg) {
      violations.add(
        'Zbyt niska masa roweru: ${bikeWeightKg.toStringAsFixed(2)} kg < limit ${activeRulebook.minBikeWeightKg.toStringAsFixed(2)} kg (Art. 1.3.019).',
      );
      fineChf += 2000;
      dsq = true;
    }

    if (handlebarWidthCm + 1e-6 < activeRulebook.minHandlebarWidthCm) {
      violations.add(
        'Zbyt wąska kierownica: ${handlebarWidthCm.toStringAsFixed(1)} cm < ${activeRulebook.minHandlebarWidthCm.toStringAsFixed(1)} cm.',
      );
      fineChf += 500;
      dsq = true;
    }

    if (brakeLeverInwardDeg - 1e-6 > activeRulebook.maxBrakeLeverInwardDeg) {
      violations.add(
        'Nadmierne pochylenie klamek do wewnątrz: ${brakeLeverInwardDeg.toStringAsFixed(1)}° > ${activeRulebook.maxBrakeLeverInwardDeg.toStringAsFixed(1)}°.',
      );
      fineChf += 500;
    }

    if (rimDepthMm - 1e-6 > activeRulebook.maxRimDepthMm) {
      violations.add(
        'Stożek obręczy powyżej limitu: ${rimDepthMm.toStringAsFixed(0)} mm > ${activeRulebook.maxRimDepthMm.toStringAsFixed(0)} mm.',
      );
      fineChf += 500;
      dsq = true;
    }

    if (sockHeightRatio - 1e-6 > activeRulebook.maxSockHeightRatio) {
      violations.add(
        'Wysokość skarpet powyżej limitu (${(sockHeightRatio * 100).toStringAsFixed(0)}% > ${(activeRulebook.maxSockHeightRatio * 100).toStringAsFixed(0)}%).',
      );
      fineChf += 200;
    }

    if (activeRulebook.supertuckBanned && usesSupertuck) {
      violations.add('Niedozwolona pozycja zjazdowa Supertuck (Art. 2.2.025).');
      fineChf += 500;
      dsq = true;
    }

    if (activeRulebook.puppyPawsBanned && usesPuppyPaws) {
      violations.add(
        'Niedozwolona pozycja aero Puppy Paws na przedramionach (Art. 2.2.025).',
      );
      fineChf += 500;
    }

    if (activeRulebook.invisibleAerobarsBanned && usesInvisibleAerobars) {
      violations.add('Niedozwolona pozycja Invisible Aerobars.');
      fineChf += 500;
    }

    if (activeRulebook.maxGearRolloutMeters != null &&
        gearRolloutMeters != null &&
        gearRolloutMeters > activeRulebook.maxGearRolloutMeters!) {
      violations.add(
        'Przekroczony limit twardości przełożenia: $gearRolloutMeters m > ${activeRulebook.maxGearRolloutMeters} m.',
      );
      fineChf += 1000;
      dsq = true;
    }

    return EquipmentComplianceCheckResult(
      isCompliant: violations.isEmpty,
      violationsPl: violations,
      totalFineChf: fineChf,
      resultsInDisqualification: dsq,
    );
  }

  /// Przeprowadza analizę VAR incydentu sprinterskiego i aktualizuje rejestr kartek.
  UciCommissaireRulebookAndVarModel evaluateAndRecordSprintVar(
    SprintVarIncidentInput input, {
    SprintDeviationVarAnalyzer analyzer = const SprintDeviationVarAnalyzer(),
  }) {
    final verdict = analyzer.analyze(input: input, rulebook: activeRulebook);
    final updatedVerdicts = [...varVerdicts, verdict];

    var updatedModel = copyWith(varVerdicts: updatedVerdicts);
    if (verdict.cardIssued == UciCardType.yellow) {
      updatedModel = updatedModel.recordYellowCard(input.riderId);
    } else if (verdict.cardIssued == UciCardType.redDisqualification) {
      final newSuspensions = Map<String, int>.from(updatedModel.riderSuspensionDays);
      newSuspensions[input.riderId] =
          math.max(newSuspensions[input.riderId] ?? 0, 7);
      updatedModel = updatedModel.copyWith(riderSuspensionDays: newSuspensions);
    }
    return updatedModel;
  }

  /// Rejestruje żółtą kartkę UCI i nalicza automatyczne zawieszenia (2 w wyścigu / 3 w 30 dni).
  UciCommissaireRulebookAndVarModel recordYellowCard(String riderId) {
    if (!activeRulebook.yellowCardSystemActive) {
      return this;
    }
    final raceCards = Map<String, int>.from(riderYellowCardsInRace);
    final rollingCards = Map<String, int>.from(riderYellowCardsRolling30Days);
    final suspensions = Map<String, int>.from(riderSuspensionDays);

    final newRaceCount = (raceCards[riderId] ?? 0) + 1;
    final newRollingCount = (rollingCards[riderId] ?? 0) + 1;

    raceCards[riderId] = newRaceCount;
    rollingCards[riderId] = newRollingCount;

    if (newRaceCount >= activeRulebook.yellowCardsForRaceDsq) {
      suspensions[riderId] = math.max(suspensions[riderId] ?? 0, 7);
    }
    if (newRollingCount >= 3) {
      suspensions[riderId] = math.max(suspensions[riderId] ?? 0, 14);
    }

    return copyWith(
      riderYellowCardsInRace: raceCards,
      riderYellowCardsRolling30Days: rollingCards,
      riderSuspensionDays: suspensions,
    );
  }

  /// Resetuje licznik kartek wyścigowych po zakończeniu wyścigu wieloetapowego.
  UciCommissaireRulebookAndVarModel clearRaceYellowCards() {
    return copyWith(riderYellowCardsInRace: const {});
  }

  /// Stosuje zestaw poprawek regulaminowych na kolejny sezon kariery.
  UciCommissaireRulebookAndVarModel applySeasonAmendments({
    required int nextSeasonYear,
    required List<UciRuleAmendment> amendments,
  }) {
    var updated = activeRulebook.copyWith(seasonYear: nextSeasonYear);

    for (final amendment in amendments) {
      switch (amendment.type) {
        case UciAmendmentType.bikeWeightLimitChange:
          if (amendment.newNumericValue != null) {
            updated = updated.copyWith(
              minBikeWeightKg:
                  amendment.newNumericValue!.clamp(5.80, 7.50),
            );
          }
          break;
        case UciAmendmentType.aeroPostureBanOrUpdate:
          final key = amendment.affectedPostureKey?.toLowerCase();
          final allowed = amendment.postureAllowed ?? false;
          if (key == 'supertuck') {
            updated = updated.copyWith(supertuckBanned: !allowed);
          } else if (key == 'puppypaws') {
            updated = updated.copyWith(puppyPawsBanned: !allowed);
          } else if (key == 'invisibleaerobars') {
            updated = updated.copyWith(invisibleAerobarsBanned: !allowed);
          }
          break;
        case UciAmendmentType.handlebarAndLeverGeometry:
          if (amendment.newNumericValue != null) {
            if (amendment.id.contains('lever')) {
              updated = updated.copyWith(
                maxBrakeLeverInwardDeg:
                    amendment.newNumericValue!.clamp(0.0, 25.0),
              );
            } else {
              updated = updated.copyWith(
                minHandlebarWidthCm:
                    amendment.newNumericValue!.clamp(30.0, 44.0),
              );
            }
          }
          break;
        case UciAmendmentType.sprintProtectionZoneChange:
          if (amendment.newNumericValue != null) {
            updated = updated.copyWith(
              finalKmProtectionDistanceKm:
                  amendment.newNumericValue!.clamp(1.0, 8.0),
            );
          }
          break;
        case UciAmendmentType.yellowCardThresholdUpdate:
          if (amendment.newNumericValue != null) {
            updated = updated.copyWith(
              yellowCardsForRaceDsq:
                  amendment.newNumericValue!.round().clamp(1, 5),
            );
          }
          break;
        case UciAmendmentType.gearRatioCap:
          if (amendment.newNumericValue != null) {
            updated = updated.copyWith(
              maxGearRolloutMeters:
                  amendment.newNumericValue!.round().clamp(8, 12),
            );
          }
          break;
        case UciAmendmentType.wheelRimDepthLimit:
          if (amendment.newNumericValue != null) {
            updated = updated.copyWith(
              maxRimDepthMm: amendment.newNumericValue!.clamp(40.0, 100.0),
            );
          }
          break;
      }
    }

    return copyWith(
      activeRulebook: updated,
      evolutionHistory: [...evolutionHistory, ...amendments],
      riderYellowCardsInRace: const {},
    );
  }

  /// Generuje deterministyczne reformy UCI dla kolejnych lat kariery (np. 6.8 kg -> 6.5 kg).
  UciCommissaireRulebookAndVarModel advanceToNextSeason({
    int? targetYear,
    int seed = 463,
  }) {
    final nextYear = targetYear ?? (activeRulebook.seasonYear + 1);
    final proposed = buildScheduledOrDynamicAmendments(
      targetYear: nextYear,
      currentRulebook: activeRulebook,
      seed: seed,
    );
    return applySeasonAmendments(
      nextSeasonYear: nextYear,
      amendments: proposed,
    );
  }

  /// Buduje listę realistycznych zmian regulaminowych UCI na dany rok kariery.
  static List<UciRuleAmendment> buildScheduledOrDynamicAmendments({
    required int targetYear,
    required UciRulebookEdition currentRulebook,
    int seed = 463,
  }) {
    final amendments = <UciRuleAmendment>[];

    // Przykładowa ewolucja historyczno-przyszłościowa (2026: 5 km strefa ochrony, 2027: 6.5 kg limit wagi).
    if (targetYear == 2026 && currentRulebook.finalKmProtectionDistanceKm < 5.0) {
      amendments.add(
        UciRuleAmendment(
          id: 'uci_${targetYear}_sprint_zone_5km',
          seasonYear: targetYear,
          type: UciAmendmentType.sprintProtectionZoneChange,
          titlePl: 'Rozszerzenie strefy ochronnej do 5 km',
          summaryPl:
              'Na etapach sprinterskich neutralizacja czasu po kraksie obowiązuje od 5 km przed metą.',
          previousNumericValue: currentRulebook.finalKmProtectionDistanceKm,
          newNumericValue: 5.0,
        ),
      );
    }

    if (targetYear >= 2027 && currentRulebook.minBikeWeightKg > 6.55) {
      amendments.add(
        UciRuleAmendment(
          id: 'uci_${targetYear}_weight_6_5kg',
          seasonYear: targetYear,
          type: UciAmendmentType.bikeWeightLimitChange,
          titlePl: 'Obniżenie minimalnej wagi roweru do 6.50 kg',
          summaryPl:
              'Kongres UCI obniża limit masy roweru z ${currentRulebook.minBikeWeightKg.toStringAsFixed(2)} kg do 6.50 kg dzięki nowym standardom włókien węglowych.',
          previousNumericValue: currentRulebook.minBikeWeightKg,
          newNumericValue: 6.50,
        ),
      );
    }

    if (amendments.isEmpty) {
      final rng = math.Random(seed ^ (targetYear * 97));
      final choice = rng.nextInt(3);
      if (choice == 0) {
        final newWidth = currentRulebook.minHandlebarWidthCm < 38.0 ? 38.0 : 36.0;
        amendments.add(
          UciRuleAmendment(
            id: 'uci_${targetYear}_handlebar_width',
            seasonYear: targetYear,
            type: UciAmendmentType.handlebarAndLeverGeometry,
            titlePl: 'Korekta minimalnej szerokości kierownicy',
            summaryPl:
                'Nowy wymóg ergonomiczny dla kierownic szosowych: minimum ${newWidth.toStringAsFixed(0)} cm.',
            previousNumericValue: currentRulebook.minHandlebarWidthCm,
            newNumericValue: newWidth,
          ),
        );
      } else if (choice == 1) {
        final newRim = currentRulebook.maxRimDepthMm > 65.0 ? 65.0 : 75.0;
        amendments.add(
          UciRuleAmendment(
            id: 'uci_${targetYear}_rim_depth',
            seasonYear: targetYear,
            type: UciAmendmentType.wheelRimDepthLimit,
            titlePl: 'Limit wysokości stożka obręczy na etapach szosowych',
            summaryPl:
                'Ze względów bezpieczeństwa przy wietrze bocznym limit obręczy wynosi ${newRim.toStringAsFixed(0)} mm.',
            previousNumericValue: currentRulebook.maxRimDepthMm,
            newNumericValue: newRim,
          ),
        );
      } else {
        amendments.add(
          UciRuleAmendment(
            id: 'uci_${targetYear}_gear_cap',
            seasonYear: targetYear,
            type: UciAmendmentType.gearRatioCap,
            titlePl: 'Testowy limit twardości przełożenia',
            summaryPl:
                'Wprowadzenie maksymalnego rozwinięcia koła na jeden obrót korby (10 m) w wyścigach szosowych.',
            previousNumericValue:
                currentRulebook.maxGearRolloutMeters?.toDouble(),
            newNumericValue: 10.0,
          ),
        );
      }
    }

    return amendments;
  }

  UciCommissaireRulebookAndVarModel copyWith({
    UciRulebookEdition? activeRulebook,
    List<UciRuleAmendment>? evolutionHistory,
    List<SprintVarVerdict>? varVerdicts,
    Map<String, int>? riderYellowCardsInRace,
    Map<String, int>? riderYellowCardsRolling30Days,
    Map<String, int>? riderSuspensionDays,
  }) {
    return UciCommissaireRulebookAndVarModel(
      activeRulebook: activeRulebook ?? this.activeRulebook,
      evolutionHistory: evolutionHistory ?? this.evolutionHistory,
      varVerdicts: varVerdicts ?? this.varVerdicts,
      riderYellowCardsInRace:
          riderYellowCardsInRace ?? this.riderYellowCardsInRace,
      riderYellowCardsRolling30Days:
          riderYellowCardsRolling30Days ?? this.riderYellowCardsRolling30Days,
      riderSuspensionDays: riderSuspensionDays ?? this.riderSuspensionDays,
    );
  }

  Map<String, dynamic> toJson() => {
        'activeRulebook': activeRulebook.toJson(),
        'evolutionHistory': evolutionHistory.map((e) => e.toJson()).toList(),
        'varVerdicts': varVerdicts.map((v) => v.toJson()).toList(),
        'riderYellowCardsInRace': riderYellowCardsInRace,
        'riderYellowCardsRolling30Days': riderYellowCardsRolling30Days,
        'riderSuspensionDays': riderSuspensionDays,
      };

  factory UciCommissaireRulebookAndVarModel.fromJson(
    Map<String, dynamic> json,
  ) {
    Map<String, int> parseIntMap(dynamic raw) {
      if (raw is! Map) return const {};
      return raw.map(
        (key, value) => MapEntry(
          key.toString(),
          (value as num?)?.toInt() ?? 0,
        ),
      );
    }

    return UciCommissaireRulebookAndVarModel(
      activeRulebook: UciRulebookEdition.fromJson(
        json['activeRulebook'] as Map<String, dynamic>? ?? const {},
      ),
      evolutionHistory:
          (json['evolutionHistory'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(UciRuleAmendment.fromJson)
              .toList(),
      varVerdicts: (json['varVerdicts'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SprintVarVerdict.fromJson)
          .toList(),
      riderYellowCardsInRace: parseIntMap(json['riderYellowCardsInRace']),
      riderYellowCardsRolling30Days:
          parseIntMap(json['riderYellowCardsRolling30Days']),
      riderSuspensionDays: parseIntMap(json['riderSuspensionDays']),
    );
  }
}
