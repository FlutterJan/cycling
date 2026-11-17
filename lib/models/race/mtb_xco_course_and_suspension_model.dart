import 'dart:math' as math;

/// Ranga zawodów w Kolarstwie Górskim MTB Cross-Country Olympic (XCO) oraz Short Track (XCC).
enum MtbXcoRaceTier {
  worldCupXco,
  olympicGamesXco,
  worldChampionshipsXco,
  uciHorseClassHc,
  shortTrackXcc;

  String toJson() => name;

  static MtbXcoRaceTier fromJson(String value) {
    return MtbXcoRaceTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MtbXcoRaceTier.worldCupXco,
    );
  }

  /// Nazwa rangi po polsku.
  String get displayNamePl {
    switch (this) {
      case MtbXcoRaceTier.worldCupXco:
        return 'Puchar Świata UCI MTB XCO';
      case MtbXcoRaceTier.olympicGamesXco:
        return 'Igrzyska Olimpijskie MTB XCO';
      case MtbXcoRaceTier.worldChampionshipsXco:
        return 'Mistrzostwa Świata UCI MTB XCO';
      case MtbXcoRaceTier.uciHorseClassHc:
        return 'Wyścig UCI Hors Class (HC) XCO';
      case MtbXcoRaceTier.shortTrackXcc:
        return 'Puchar Świata Short Track (XCC)';
    }
  }

  /// Nazwa rangi po angielsku.
  String get displayNameEn {
    switch (this) {
      case MtbXcoRaceTier.worldCupXco:
        return 'UCI MTB XCO World Cup';
      case MtbXcoRaceTier.olympicGamesXco:
        return 'Olympic Games MTB XCO';
      case MtbXcoRaceTier.worldChampionshipsXco:
        return 'UCI MTB XCO World Championships';
      case MtbXcoRaceTier.uciHorseClassHc:
        return 'UCI Hors Class (HC) XCO';
      case MtbXcoRaceTier.shortTrackXcc:
        return 'UCI MTB Short Track (XCC)';
    }
  }

  /// Typowa długość pojedynczej rundy [km].
  double get typicalLapDistanceKm {
    switch (this) {
      case MtbXcoRaceTier.worldCupXco:
      case MtbXcoRaceTier.olympicGamesXco:
      case MtbXcoRaceTier.worldChampionshipsXco:
        return 4.2;
      case MtbXcoRaceTier.uciHorseClassHc:
        return 4.5;
      case MtbXcoRaceTier.shortTrackXcc:
        return 1.15;
    }
  }

  /// Typowa liczba okrążeń wyścigu elity.
  int get typicalLapCount {
    switch (this) {
      case MtbXcoRaceTier.worldCupXco:
      case MtbXcoRaceTier.worldChampionshipsXco:
        return 6;
      case MtbXcoRaceTier.olympicGamesXco:
        return 7;
      case MtbXcoRaceTier.uciHorseClassHc:
        return 5;
      case MtbXcoRaceTier.shortTrackXcc:
        return 9;
    }
  }
}

/// Typ przeszkody lub sekcji terenowej na rundzie MTB XCO.
enum MtbXcoFeatureType {
  startLoop,
  punchyClimb,
  rockGarden,
  rootSection,
  dropOff,
  woodBridge,
  bermSwitchback,
  pumpRollers,
  techZonePit,
  finishStraight;

  String toJson() => name;

  static MtbXcoFeatureType fromJson(String value) {
    return MtbXcoFeatureType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MtbXcoFeatureType.punchyClimb,
    );
  }

  /// Nazwa sekcji po polsku.
  String get displayNamePl {
    switch (this) {
      case MtbXcoFeatureType.startLoop:
        return 'Pętla startowa';
      case MtbXcoFeatureType.punchyClimb:
        return 'Stromy podjazd interwałowy';
      case MtbXcoFeatureType.rockGarden:
        return 'Ogród kamieni (Rock Garden)';
      case MtbXcoFeatureType.rootSection:
        return 'Sekcja korzeniowa';
      case MtbXcoFeatureType.dropOff:
        return 'Próg / Drop';
      case MtbXcoFeatureType.woodBridge:
        return 'Drewniany mostek / kładka';
      case MtbXcoFeatureType.bermSwitchback:
        return 'Bandy i agrafki';
      case MtbXcoFeatureType.pumpRollers:
        return 'Sekcja hopek i muld';
      case MtbXcoFeatureType.techZonePit:
        return 'Strefa techniczna / Bufet (Tech Zone)';
      case MtbXcoFeatureType.finishStraight:
        return 'Prosta finiszowa';
    }
  }

  /// Czy sekcja typowo posiada rozwidlenie na linię A-Line i B-Line.
  bool get hasTypicalLineChoice {
    switch (this) {
      case MtbXcoFeatureType.rockGarden:
      case MtbXcoFeatureType.dropOff:
      case MtbXcoFeatureType.rootSection:
        return true;
      case MtbXcoFeatureType.startLoop:
      case MtbXcoFeatureType.punchyClimb:
      case MtbXcoFeatureType.woodBridge:
      case MtbXcoFeatureType.bermSwitchback:
      case MtbXcoFeatureType.pumpRollers:
      case MtbXcoFeatureType.techZonePit:
      case MtbXcoFeatureType.finishStraight:
        return false;
    }
  }

  /// Zalecane ustawienie sztycy regulowanej (Dropper Post) w danej sekcji.
  DropperPostState get recommendedDropperState {
    switch (this) {
      case MtbXcoFeatureType.rockGarden:
      case MtbXcoFeatureType.dropOff:
        return DropperPostState.slammed;
      case MtbXcoFeatureType.rootSection:
      case MtbXcoFeatureType.bermSwitchback:
      case MtbXcoFeatureType.pumpRollers:
      case MtbXcoFeatureType.woodBridge:
        return DropperPostState.midDrop;
      case MtbXcoFeatureType.startLoop:
      case MtbXcoFeatureType.punchyClimb:
      case MtbXcoFeatureType.techZonePit:
      case MtbXcoFeatureType.finishStraight:
        return DropperPostState.extended;
    }
  }

  /// Zalecany tryb blokady zawieszenia w danej sekcji.
  SuspensionLockoutMode get recommendedLockout {
    switch (this) {
      case MtbXcoFeatureType.rockGarden:
      case MtbXcoFeatureType.dropOff:
      case MtbXcoFeatureType.rootSection:
      case MtbXcoFeatureType.bermSwitchback:
        return SuspensionLockoutMode.open;
      case MtbXcoFeatureType.pumpRollers:
      case MtbXcoFeatureType.woodBridge:
      case MtbXcoFeatureType.punchyClimb:
        return SuspensionLockoutMode.pedalTrail;
      case MtbXcoFeatureType.startLoop:
      case MtbXcoFeatureType.techZonePit:
      case MtbXcoFeatureType.finishStraight:
        return SuspensionLockoutMode.locked;
    }
  }
}

/// Wybór linii przejazdu na technicznej przeszkodzie MTB XCO.
enum MtbTrailLineChoice {
  /// Szybka, bezpośrednia i ryzykowna linia po największych głazach / dropie.
  aLine,

  /// Bezpieczna, dłuższa objazdowa linia z minimalnym ryzykiem defektu.
  bLine;

  String toJson() => name;

  static MtbTrailLineChoice fromJson(String value) {
    return MtbTrailLineChoice.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MtbTrailLineChoice.bLine,
    );
  }

  /// Nazwa linii po polsku.
  String get displayNamePl {
    switch (this) {
      case MtbTrailLineChoice.aLine:
        return 'Linia A (Szybka / Ryzykowna)';
      case MtbTrailLineChoice.bLine:
        return 'Linia B (Bezpieczna / Objazd)';
    }
  }

  /// Mnożnik ryzyka kraksy lub przebicia względem linii bazowej.
  double get crashRiskMultiplier {
    switch (this) {
      case MtbTrailLineChoice.aLine:
        return 1.85;
      case MtbTrailLineChoice.bLine:
        return 0.45;
    }
  }
}

/// Warunki podłoża i wilgotności szlaku leśnego MTB XCO.
enum MtbTrailSoilCondition {
  dryHardpack,
  looseDust,
  tackyLoam,
  wetRootsAndRock,
  muddyRut;

  String toJson() => name;

  static MtbTrailSoilCondition fromJson(String value) {
    return MtbTrailSoilCondition.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MtbTrailSoilCondition.tackyLoam,
    );
  }

  /// Nazwa warunków podłoża po polsku.
  String get displayNamePl {
    switch (this) {
      case MtbTrailSoilCondition.dryHardpack:
        return 'Suchy, ubity szlak (Hardpack)';
      case MtbTrailSoilCondition.looseDust:
        return 'Sypki pył i luźne kamienie';
      case MtbTrailSoilCondition.tackyLoam:
        return 'Wilgotna, przyczepna ściółka (Tacky Loam)';
      case MtbTrailSoilCondition.wetRootsAndRock:
        return 'Mokre, śliskie korzenie i głazy';
      case MtbTrailSoilCondition.muddyRut:
        return 'Głębokie błoto i koleiny';
    }
  }

  /// Bazowy mnożnik przyczepności opon (1.0 = idealne podłoże).
  double get gripMultiplier {
    switch (this) {
      case MtbTrailSoilCondition.dryHardpack:
        return 0.96;
      case MtbTrailSoilCondition.looseDust:
        return 0.78;
      case MtbTrailSoilCondition.tackyLoam:
        return 1.05;
      case MtbTrailSoilCondition.wetRootsAndRock:
        return 0.62;
      case MtbTrailSoilCondition.muddyRut:
        return 0.55;
    }
  }

  /// Mnożnik oporu toczenia CRR względem suchego szlaku.
  double get crrMultiplier {
    switch (this) {
      case MtbTrailSoilCondition.dryHardpack:
        return 1.00;
      case MtbTrailSoilCondition.looseDust:
        return 1.18;
      case MtbTrailSoilCondition.tackyLoam:
        return 1.08;
      case MtbTrailSoilCondition.wetRootsAndRock:
        return 1.24;
      case MtbTrailSoilCondition.muddyRut:
        return 1.55;
    }
  }
}

/// Architektura zawieszenia roweru górskiego XC.
enum MtbSuspensionArchitecture {
  /// Klasyczny Hardtail ze skokiem 100–110 mm z przodu i sztywnym tyłem.
  hardtail,

  /// Wyścigowy Full-Suspension XC o skoku 100 mm przód / 100 mm tył.
  fullSuspensionXc100,

  /// Nowoczesny Full-Suspension XCO / Downcountry o skoku 120 mm przód / 120 mm tył.
  fullSuspensionDowncountry120;

  String toJson() => name;

  static MtbSuspensionArchitecture fromJson(String value) {
    return MtbSuspensionArchitecture.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MtbSuspensionArchitecture.fullSuspensionDowncountry120,
    );
  }

  /// Nazwa architektury po polsku.
  String get displayNamePl {
    switch (this) {
      case MtbSuspensionArchitecture.hardtail:
        return 'Hardtail (100 mm przód)';
      case MtbSuspensionArchitecture.fullSuspensionXc100:
        return 'Full-Suspension XC (100/100 mm)';
      case MtbSuspensionArchitecture.fullSuspensionDowncountry120:
        return 'Full-Suspension XCO (120/120 mm)';
    }
  }

  /// Nominalny skok widelca przedniego [mm].
  int get frontTravelMm {
    switch (this) {
      case MtbSuspensionArchitecture.hardtail:
      case MtbSuspensionArchitecture.fullSuspensionXc100:
        return 100;
      case MtbSuspensionArchitecture.fullSuspensionDowncountry120:
        return 120;
    }
  }

  /// Nominalny skok dampera tylnego [mm] (0 dla Hardtaila).
  int get rearTravelMm {
    switch (this) {
      case MtbSuspensionArchitecture.hardtail:
        return 0;
      case MtbSuspensionArchitecture.fullSuspensionXc100:
        return 100;
      case MtbSuspensionArchitecture.fullSuspensionDowncountry120:
        return 120;
    }
  }

  /// Bazowa waga kompletnego roweru wyścigowego [kg].
  double get baseBikeWeightKg {
    switch (this) {
      case MtbSuspensionArchitecture.hardtail:
        return 8.7;
      case MtbSuspensionArchitecture.fullSuspensionXc100:
        return 9.8;
      case MtbSuspensionArchitecture.fullSuspensionDowncountry120:
        return 10.3;
    }
  }

  /// Efektywność przenoszenia mocy na gładkich podjazdach (1.0 = brak strat pompowania).
  double get pedalingEfficiencyFactor {
    switch (this) {
      case MtbSuspensionArchitecture.hardtail:
        return 0.995;
      case MtbSuspensionArchitecture.fullSuspensionXc100:
        return 0.975;
      case MtbSuspensionArchitecture.fullSuspensionDowncountry120:
        return 0.962;
    }
  }
}

/// Tryb pracy manetki blokady zawieszenia (3-pozycyjny Remote Lockout).
enum SuspensionLockoutMode {
  /// Pełne otwarcie tłumienia na rock gardeny, dropy i korzenie.
  open,

  /// Tryb pośredni (Platforma / Trail) ograniczający bujanie na technicznych podjazdach.
  pedalTrail,

  /// Pełna blokada skoku na start, asfalt i gładkie podjazdy na stojąco.
  locked;

  String toJson() => name;

  static SuspensionLockoutMode fromJson(String value) {
    return SuspensionLockoutMode.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SuspensionLockoutMode.open,
    );
  }

  /// Nazwa trybu po polsku.
  String get displayNamePl {
    switch (this) {
      case SuspensionLockoutMode.open:
        return 'Open (Pełny skok)';
      case SuspensionLockoutMode.pedalTrail:
        return 'Pedal / Trail (Platforma)';
      case SuspensionLockoutMode.locked:
        return 'Locked (Blokada)';
    }
  }

  /// Współczynnik pochłaniania uderzeń (0.08 przy blokadzie, 1.0 przy pełnym otwarciu).
  double get dampingAbsorptionFactor {
    switch (this) {
      case SuspensionLockoutMode.open:
        return 1.00;
      case SuspensionLockoutMode.pedalTrail:
        return 0.58;
      case SuspensionLockoutMode.locked:
        return 0.08;
    }
  }

  /// Współczynnik strat mocy na "bujanie" zawieszenia podczas pedałowania.
  double get pedalBobLossFactor {
    switch (this) {
      case SuspensionLockoutMode.open:
        return 0.032;
      case SuspensionLockoutMode.pedalTrail:
        return 0.011;
      case SuspensionLockoutMode.locked:
        return 0.002;
    }
  }
}

/// Pozycja sztycy regulowanej (Dropper Post) w trakcie jazdy.
enum DropperPostState {
  /// Pełna wysokość siodła do maksymalnej efektywności pedałowania.
  extended,

  /// Częściowe opuszczenie (ok. 50% skoku) na korzenie i szybkie bandy.
  midDrop,

  /// Maksymalne opuszczenie siodła na strome dropy i rock gardeny.
  slammed;

  String toJson() => name;

  static DropperPostState fromJson(String value) {
    return DropperPostState.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DropperPostState.extended,
    );
  }

  /// Nazwa pozycji sztycy po polsku.
  String get displayNamePl {
    switch (this) {
      case DropperPostState.extended:
        return 'Podniesiona (100% pedałowania)';
      case DropperPostState.midDrop:
        return 'Pośrednia (50% opuszczona)';
      case DropperPostState.slammed:
        return 'Opuszczona (100% Dropper)';
    }
  }

  /// Ułamek wykorzystanego skoku sztycy (0.0–1.0).
  double get dropFraction {
    switch (this) {
      case DropperPostState.extended:
        return 0.0;
      case DropperPostState.midDrop:
        return 0.5;
      case DropperPostState.slammed:
        return 1.0;
    }
  }

  /// Bonus do kontroli roweru i stabilności na zjeździe (0.0–0.28).
  double get technicalControlBonus {
    switch (this) {
      case DropperPostState.extended:
        return 0.0;
      case DropperPostState.midDrop:
        return 0.14;
      case DropperPostState.slammed:
        return 0.28;
    }
  }
}

/// Typ bieżnika opony MTB XC 2.4".
enum MtbTireTreadPattern {
  fastSemiSlick,
  allRoundXcKnob,
  aggressiveMudSpike;

  String toJson() => name;

  static MtbTireTreadPattern fromJson(String value) {
    return MtbTireTreadPattern.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MtbTireTreadPattern.allRoundXcKnob,
    );
  }

  /// Nazwa bieżnika po polsku.
  String get displayNamePl {
    switch (this) {
      case MtbTireTreadPattern.fastSemiSlick:
        return 'Szybki bieżnik XC (Semi-Slick)';
      case MtbTireTreadPattern.allRoundXcKnob:
        return 'Uniwersalny klocek XC (All-Round)';
      case MtbTireTreadPattern.aggressiveMudSpike:
        return 'Agresywny bieżnik błotny (Mud Spike)';
    }
  }

  /// Bazowy współczynnik oporu toczenia (CRR) na twardym podłożu.
  double get baseCrr {
    switch (this) {
      case MtbTireTreadPattern.fastSemiSlick:
        return 0.0062;
      case MtbTireTreadPattern.allRoundXcKnob:
        return 0.0074;
      case MtbTireTreadPattern.aggressiveMudSpike:
        return 0.0092;
    }
  }

  /// Bonus przyczepności na mokrych korzeniach i błocie.
  double get wetGripBonus {
    switch (this) {
      case MtbTireTreadPattern.fastSemiSlick:
        return 0.0;
      case MtbTireTreadPattern.allRoundXcKnob:
        return 0.14;
      case MtbTireTreadPattern.aggressiveMudSpike:
        return 0.30;
    }
  }
}

/// Parametry pojedynczego wariantu linii przejazdu (A-Line vs B-Line) na przeszkodzie XCO.
class MtbXcoLineOption {
  final MtbTrailLineChoice lineChoice;
  final double lengthMeters;
  final double dropHeightMeters;
  final double technicalDifficulty;
  final double timeAdvantageSeconds;
  final double crashRiskBase;
  final int minSuspensionTravelMm;
  final bool requiresDropperPost;

  const MtbXcoLineOption({
    required this.lineChoice,
    required this.lengthMeters,
    this.dropHeightMeters = 0.0,
    this.technicalDifficulty = 5.0,
    this.timeAdvantageSeconds = 0.0,
    this.crashRiskBase = 0.04,
    this.minSuspensionTravelMm = 100,
    this.requiresDropperPost = false,
  });

  MtbXcoLineOption copyWith({
    MtbTrailLineChoice? lineChoice,
    double? lengthMeters,
    double? dropHeightMeters,
    double? technicalDifficulty,
    double? timeAdvantageSeconds,
    double? crashRiskBase,
    int? minSuspensionTravelMm,
    bool? requiresDropperPost,
  }) {
    return MtbXcoLineOption(
      lineChoice: lineChoice ?? this.lineChoice,
      lengthMeters: lengthMeters ?? this.lengthMeters,
      dropHeightMeters: dropHeightMeters ?? this.dropHeightMeters,
      technicalDifficulty: technicalDifficulty ?? this.technicalDifficulty,
      timeAdvantageSeconds: timeAdvantageSeconds ?? this.timeAdvantageSeconds,
      crashRiskBase: crashRiskBase ?? this.crashRiskBase,
      minSuspensionTravelMm:
          minSuspensionTravelMm ?? this.minSuspensionTravelMm,
      requiresDropperPost: requiresDropperPost ?? this.requiresDropperPost,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lineChoice': lineChoice.toJson(),
      'lengthMeters': lengthMeters,
      'dropHeightMeters': dropHeightMeters,
      'technicalDifficulty': technicalDifficulty,
      'timeAdvantageSeconds': timeAdvantageSeconds,
      'crashRiskBase': crashRiskBase,
      'minSuspensionTravelMm': minSuspensionTravelMm,
      'requiresDropperPost': requiresDropperPost,
    };
  }

  factory MtbXcoLineOption.fromJson(Map<String, dynamic> json) {
    return MtbXcoLineOption(
      lineChoice: MtbTrailLineChoice.fromJson(
        json['lineChoice']?.toString() ?? 'bLine',
      ),
      lengthMeters: (json['lengthMeters'] as num?)?.toDouble() ?? 40.0,
      dropHeightMeters: (json['dropHeightMeters'] as num?)?.toDouble() ?? 0.0,
      technicalDifficulty:
          (json['technicalDifficulty'] as num?)?.toDouble() ?? 5.0,
      timeAdvantageSeconds:
          (json['timeAdvantageSeconds'] as num?)?.toDouble() ?? 0.0,
      crashRiskBase: (json['crashRiskBase'] as num?)?.toDouble() ?? 0.04,
      minSuspensionTravelMm:
          (json['minSuspensionTravelMm'] as num?)?.toInt() ?? 100,
      requiresDropperPost: json['requiresDropperPost'] as bool? ?? false,
    );
  }
}

/// Pojedynczy segment rundy MTB Cross-Country Olympic (XCO).
class MtbXcoCourseSegment {
  final int index;
  final String name;
  final double startMeter;
  final double lengthMeters;
  final MtbXcoFeatureType featureType;
  final double gradientPercent;
  final double roughnessIndex;
  final double rockSizeCm;
  final double rootDensityPerMeter;
  final double dropHeightMeters;
  final MtbXcoLineOption? aLine;
  final MtbXcoLineOption? bLine;
  final SuspensionLockoutMode recommendedLockout;
  final DropperPostState recommendedDropper;
  final bool isTechFeedZone;

  const MtbXcoCourseSegment({
    required this.index,
    required this.name,
    required this.startMeter,
    required this.lengthMeters,
    required this.featureType,
    this.gradientPercent = 0.0,
    this.roughnessIndex = 0.25,
    this.rockSizeCm = 0.0,
    this.rootDensityPerMeter = 0.0,
    this.dropHeightMeters = 0.0,
    this.aLine,
    this.bLine,
    this.recommendedLockout = SuspensionLockoutMode.open,
    this.recommendedDropper = DropperPostState.extended,
    this.isTechFeedZone = false,
  });

  /// Końcowy metr segmentu na rundzie [m].
  double get endMeter => startMeter + lengthMeters;

  /// Czy segment ma wybór między linią A-Line i B-Line.
  bool get hasLineSplit => aLine != null && bLine != null;

  /// Przewyższenie netto w obrębie segmentu [m].
  double get elevationGainMeters =>
      gradientPercent > 0 ? lengthMeters * (gradientPercent / 100.0) : 0.0;

  /// Czy jest to techniczny zjazd wymagający aktywnego zawieszenia i opuszczonego siodła.
  bool get isTechnicalDescent =>
      gradientPercent < -3.0 &&
      (roughnessIndex >= 0.50 ||
          dropHeightMeters >= 0.4 ||
          featureType == MtbXcoFeatureType.rockGarden ||
          featureType == MtbXcoFeatureType.dropOff);

  MtbXcoCourseSegment copyWith({
    int? index,
    String? name,
    double? startMeter,
    double? lengthMeters,
    MtbXcoFeatureType? featureType,
    double? gradientPercent,
    double? roughnessIndex,
    double? rockSizeCm,
    double? rootDensityPerMeter,
    double? dropHeightMeters,
    MtbXcoLineOption? aLine,
    MtbXcoLineOption? bLine,
    SuspensionLockoutMode? recommendedLockout,
    DropperPostState? recommendedDropper,
    bool? isTechFeedZone,
  }) {
    return MtbXcoCourseSegment(
      index: index ?? this.index,
      name: name ?? this.name,
      startMeter: startMeter ?? this.startMeter,
      lengthMeters: lengthMeters ?? this.lengthMeters,
      featureType: featureType ?? this.featureType,
      gradientPercent: gradientPercent ?? this.gradientPercent,
      roughnessIndex: roughnessIndex ?? this.roughnessIndex,
      rockSizeCm: rockSizeCm ?? this.rockSizeCm,
      rootDensityPerMeter: rootDensityPerMeter ?? this.rootDensityPerMeter,
      dropHeightMeters: dropHeightMeters ?? this.dropHeightMeters,
      aLine: aLine ?? this.aLine,
      bLine: bLine ?? this.bLine,
      recommendedLockout: recommendedLockout ?? this.recommendedLockout,
      recommendedDropper: recommendedDropper ?? this.recommendedDropper,
      isTechFeedZone: isTechFeedZone ?? this.isTechFeedZone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'name': name,
      'startMeter': startMeter,
      'lengthMeters': lengthMeters,
      'featureType': featureType.toJson(),
      'gradientPercent': gradientPercent,
      'roughnessIndex': roughnessIndex,
      'rockSizeCm': rockSizeCm,
      'rootDensityPerMeter': rootDensityPerMeter,
      'dropHeightMeters': dropHeightMeters,
      'aLine': aLine?.toJson(),
      'bLine': bLine?.toJson(),
      'recommendedLockout': recommendedLockout.toJson(),
      'recommendedDropper': recommendedDropper.toJson(),
      'isTechFeedZone': isTechFeedZone,
    };
  }

  factory MtbXcoCourseSegment.fromJson(Map<String, dynamic> json) {
    return MtbXcoCourseSegment(
      index: (json['index'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Segment XCO',
      startMeter: (json['startMeter'] as num?)?.toDouble() ?? 0.0,
      lengthMeters: (json['lengthMeters'] as num?)?.toDouble() ?? 100.0,
      featureType: MtbXcoFeatureType.fromJson(
        json['featureType']?.toString() ?? 'punchyClimb',
      ),
      gradientPercent: (json['gradientPercent'] as num?)?.toDouble() ?? 0.0,
      roughnessIndex: (json['roughnessIndex'] as num?)?.toDouble() ?? 0.25,
      rockSizeCm: (json['rockSizeCm'] as num?)?.toDouble() ?? 0.0,
      rootDensityPerMeter:
          (json['rootDensityPerMeter'] as num?)?.toDouble() ?? 0.0,
      dropHeightMeters: (json['dropHeightMeters'] as num?)?.toDouble() ?? 0.0,
      aLine: json['aLine'] is Map<String, dynamic>
          ? MtbXcoLineOption.fromJson(json['aLine'] as Map<String, dynamic>)
          : null,
      bLine: json['bLine'] is Map<String, dynamic>
          ? MtbXcoLineOption.fromJson(json['bLine'] as Map<String, dynamic>)
          : null,
      recommendedLockout: SuspensionLockoutMode.fromJson(
        json['recommendedLockout']?.toString() ?? 'open',
      ),
      recommendedDropper: DropperPostState.fromJson(
        json['recommendedDropper']?.toString() ?? 'extended',
      ),
      isTechFeedZone: json['isTechFeedZone'] as bool? ?? false,
    );
  }
}

/// Główny model trasy i specyfiki Kolarstwa Górskiego MTB Cross-Country Olympic (XCO).
class MtbXcoCourseAndSuspensionModel {
  final String courseId;
  final String name;
  final String venueLocation;
  final MtbXcoRaceTier raceTier;
  final double lapDistanceKm;
  final int totalLaps;
  final double startLoopMeters;
  final double elevationGainPerLapMeters;
  final double altitudeMeters;
  final MtbTrailSoilCondition soilCondition;
  final List<MtbXcoCourseSegment> segments;
  final int techZoneCountPerLap;

  const MtbXcoCourseAndSuspensionModel({
    required this.courseId,
    required this.name,
    required this.venueLocation,
    this.raceTier = MtbXcoRaceTier.worldCupXco,
    this.lapDistanceKm = 4.2,
    this.totalLaps = 6,
    this.startLoopMeters = 850.0,
    this.elevationGainPerLapMeters = 165.0,
    this.altitudeMeters = 620.0,
    this.soilCondition = MtbTrailSoilCondition.tackyLoam,
    this.segments = const [],
    this.techZoneCountPerLap = 2,
  });

  /// Całkowity dystans wyścigu z pętlą startową [km].
  double get totalRaceDistanceKm =>
      (startLoopMeters / 1000.0) + (lapDistanceKm * totalLaps);

  /// Całkowite przewyższenie wyścigu [m].
  double get totalElevationGainMeters => elevationGainPerLapMeters * totalLaps;

  /// Liczba ogrodów kamieni (Rock Garden) na jednej rundzie.
  int get rockGardenCount => segments
      .where((s) => s.featureType == MtbXcoFeatureType.rockGarden)
      .length;

  /// Liczba dropów na jednej rundzie.
  int get dropCount =>
      segments.where((s) => s.featureType == MtbXcoFeatureType.dropOff).length;

  /// Liczba sekcji korzeniowych na jednej rundzie.
  int get rootSectionCount => segments
      .where((s) => s.featureType == MtbXcoFeatureType.rootSection)
      .length;

  /// Średni ważony indeks nierówności trasy (0.0–1.0).
  double get averageRoughnessIndex {
    if (segments.isEmpty) return 0.35;
    double weightedSum = 0.0;
    double totalLen = 0.0;
    for (final s in segments) {
      weightedSum += s.roughnessIndex * s.lengthMeters;
      totalLen += s.lengthMeters;
    }
    if (totalLen <= 0) return 0.35;
    return (weightedSum / totalLen).clamp(0.0, 1.0);
  }

  /// Udział segmentów posiadających rozwidlenie A-Line / B-Line (0.0–1.0).
  double get aLineShareRatio {
    if (segments.isEmpty) return 0.0;
    final splitCount = segments.where((s) => s.hasLineSplit).length;
    return splitCount / segments.length;
  }

  /// Rekomendowany skok zawieszenia [mm] na podstawie trudności rundy (100 lub 120 mm).
  int get recommendedTravelMm {
    final maxRock = segments.fold<double>(
      0.0,
      (prev, s) => math.max(prev, s.rockSizeCm),
    );
    final maxDrop = segments.fold<double>(
      0.0,
      (prev, s) => math.max(prev, s.dropHeightMeters),
    );
    if (averageRoughnessIndex >= 0.48 || maxRock >= 28.0 || maxDrop >= 0.9) {
      return 120;
    }
    return 100;
  }

  /// Zwraca segment rundy dla zadanego dystansu w ramach okrążenia [m].
  MtbXcoCourseSegment? segmentAtDistance(double lapDistanceMeters) {
    if (segments.isEmpty) return null;
    final lapMeters = lapDistanceKm * 1000.0;
    final normalized = lapMeters > 0
        ? (lapDistanceMeters % lapMeters).clamp(0.0, lapMeters)
        : lapDistanceMeters;
    for (final segment in segments) {
      if (normalized >= segment.startMeter && normalized < segment.endMeter) {
        return segment;
      }
    }
    return segments.last;
  }

  /// Predefiniowana runda Pucharu Świata w Nové Město na Moravě (4.2 km).
  factory MtbXcoCourseAndSuspensionModel.noveMestoWorldCup() {
    return const MtbXcoCourseAndSuspensionModel(
      courseId: 'xco_nove_mesto_wc',
      name: 'Vysočina Arena XCO Circuit',
      venueLocation: 'Nové Město na Moravě, Czechia',
      raceTier: MtbXcoRaceTier.worldCupXco,
      lapDistanceKm: 4.2,
      totalLaps: 6,
      startLoopMeters: 820.0,
      elevationGainPerLapMeters: 168.0,
      altitudeMeters: 615.0,
      soilCondition: MtbTrailSoilCondition.tackyLoam,
      techZoneCountPerLap: 2,
      segments: [
        MtbXcoCourseSegment(
          index: 0,
          name: 'Start Arena & Asphalt Climb',
          startMeter: 0.0,
          lengthMeters: 420.0,
          featureType: MtbXcoFeatureType.startLoop,
          gradientPercent: 6.5,
          roughnessIndex: 0.08,
          recommendedLockout: SuspensionLockoutMode.locked,
          recommendedDropper: DropperPostState.extended,
        ),
        MtbXcoCourseSegment(
          index: 1,
          name: 'Mitas Choice Rock Garden',
          startMeter: 420.0,
          lengthMeters: 340.0,
          featureType: MtbXcoFeatureType.rockGarden,
          gradientPercent: -9.5,
          roughnessIndex: 0.88,
          rockSizeCm: 34.0,
          dropHeightMeters: 0.65,
          recommendedLockout: SuspensionLockoutMode.open,
          recommendedDropper: DropperPostState.slammed,
          aLine: MtbXcoLineOption(
            lineChoice: MtbTrailLineChoice.aLine,
            lengthMeters: 315.0,
            dropHeightMeters: 0.65,
            technicalDifficulty: 8.6,
            timeAdvantageSeconds: 2.8,
            crashRiskBase: 0.085,
            minSuspensionTravelMm: 120,
            requiresDropperPost: true,
          ),
          bLine: MtbXcoLineOption(
            lineChoice: MtbTrailLineChoice.bLine,
            lengthMeters: 355.0,
            dropHeightMeters: 0.20,
            technicalDifficulty: 4.2,
            timeAdvantageSeconds: 0.0,
            crashRiskBase: 0.02,
            minSuspensionTravelMm: 100,
            requiresDropperPost: false,
          ),
        ),
        MtbXcoCourseSegment(
          index: 2,
          name: 'BMX Forest Roots Climb',
          startMeter: 760.0,
          lengthMeters: 780.0,
          featureType: MtbXcoFeatureType.rootSection,
          gradientPercent: 11.2,
          roughnessIndex: 0.64,
          rootDensityPerMeter: 1.8,
          recommendedLockout: SuspensionLockoutMode.pedalTrail,
          recommendedDropper: DropperPostState.extended,
        ),
        MtbXcoCourseSegment(
          index: 3,
          name: 'Tech Zone 1 / Feed',
          startMeter: 1540.0,
          lengthMeters: 180.0,
          featureType: MtbXcoFeatureType.techZonePit,
          gradientPercent: 0.5,
          roughnessIndex: 0.10,
          recommendedLockout: SuspensionLockoutMode.locked,
          recommendedDropper: DropperPostState.extended,
          isTechFeedZone: true,
        ),
        MtbXcoCourseSegment(
          index: 4,
          name: 'Expert Climb & Switchbacks',
          startMeter: 1720.0,
          lengthMeters: 920.0,
          featureType: MtbXcoFeatureType.punchyClimb,
          gradientPercent: 13.8,
          roughnessIndex: 0.42,
          rootDensityPerMeter: 0.9,
          recommendedLockout: SuspensionLockoutMode.pedalTrail,
          recommendedDropper: DropperPostState.extended,
        ),
        MtbXcoCourseSegment(
          index: 5,
          name: 'AC/DC Rock Drop',
          startMeter: 2640.0,
          lengthMeters: 280.0,
          featureType: MtbXcoFeatureType.dropOff,
          gradientPercent: -14.0,
          roughnessIndex: 0.92,
          rockSizeCm: 38.0,
          dropHeightMeters: 1.25,
          recommendedLockout: SuspensionLockoutMode.open,
          recommendedDropper: DropperPostState.slammed,
          aLine: MtbXcoLineOption(
            lineChoice: MtbTrailLineChoice.aLine,
            lengthMeters: 260.0,
            dropHeightMeters: 1.25,
            technicalDifficulty: 9.1,
            timeAdvantageSeconds: 3.4,
            crashRiskBase: 0.10,
            minSuspensionTravelMm: 120,
            requiresDropperPost: true,
          ),
          bLine: MtbXcoLineOption(
            lineChoice: MtbTrailLineChoice.bLine,
            lengthMeters: 310.0,
            dropHeightMeters: 0.35,
            technicalDifficulty: 4.8,
            timeAdvantageSeconds: 0.0,
            crashRiskBase: 0.025,
            minSuspensionTravelMm: 100,
            requiresDropperPost: true,
          ),
        ),
        MtbXcoCourseSegment(
          index: 6,
          name: 'Mercedes-Benz Root Descent',
          startMeter: 2920.0,
          lengthMeters: 640.0,
          featureType: MtbXcoFeatureType.rootSection,
          gradientPercent: -7.5,
          roughnessIndex: 0.72,
          rootDensityPerMeter: 2.3,
          recommendedLockout: SuspensionLockoutMode.open,
          recommendedDropper: DropperPostState.midDrop,
        ),
        MtbXcoCourseSegment(
          index: 7,
          name: 'Biathlon Bridge & Berm Rollers',
          startMeter: 3560.0,
          lengthMeters: 400.0,
          featureType: MtbXcoFeatureType.woodBridge,
          gradientPercent: 1.5,
          roughnessIndex: 0.22,
          recommendedLockout: SuspensionLockoutMode.pedalTrail,
          recommendedDropper: DropperPostState.midDrop,
        ),
        MtbXcoCourseSegment(
          index: 8,
          name: 'Stadium Finish Straight',
          startMeter: 3960.0,
          lengthMeters: 240.0,
          featureType: MtbXcoFeatureType.finishStraight,
          gradientPercent: 0.0,
          roughnessIndex: 0.05,
          recommendedLockout: SuspensionLockoutMode.locked,
          recommendedDropper: DropperPostState.extended,
        ),
      ],
    );
  }

  /// Predefiniowana runda olimpijska MTB XCO 4.2 km (wysokogórska / skalista).
  factory MtbXcoCourseAndSuspensionModel.olympicXcoDefault() {
    return const MtbXcoCourseAndSuspensionModel(
      courseId: 'xco_olympic_default',
      name: 'Olympic Mountain Bike Park XCO',
      venueLocation: 'Élancourt / Alpine Olympic Venue',
      raceTier: MtbXcoRaceTier.olympicGamesXco,
      lapDistanceKm: 4.2,
      totalLaps: 7,
      startLoopMeters: 800.0,
      elevationGainPerLapMeters: 155.0,
      altitudeMeters: 940.0,
      soilCondition: MtbTrailSoilCondition.dryHardpack,
      techZoneCountPerLap: 2,
      segments: [
        MtbXcoCourseSegment(
          index: 0,
          name: 'Olympic Start Gate Climb',
          startMeter: 0.0,
          lengthMeters: 600.0,
          featureType: MtbXcoFeatureType.startLoop,
          gradientPercent: 7.5,
          roughnessIndex: 0.14,
          recommendedLockout: SuspensionLockoutMode.locked,
          recommendedDropper: DropperPostState.extended,
        ),
        MtbXcoCourseSegment(
          index: 1,
          name: 'Granite Boulder Rock Garden',
          startMeter: 600.0,
          lengthMeters: 450.0,
          featureType: MtbXcoFeatureType.rockGarden,
          gradientPercent: -8.2,
          roughnessIndex: 0.84,
          rockSizeCm: 30.0,
          dropHeightMeters: 0.75,
          recommendedLockout: SuspensionLockoutMode.open,
          recommendedDropper: DropperPostState.slammed,
          aLine: MtbXcoLineOption(
            lineChoice: MtbTrailLineChoice.aLine,
            lengthMeters: 425.0,
            dropHeightMeters: 0.75,
            technicalDifficulty: 8.2,
            timeAdvantageSeconds: 2.5,
            crashRiskBase: 0.075,
            minSuspensionTravelMm: 110,
            requiresDropperPost: true,
          ),
          bLine: MtbXcoLineOption(
            lineChoice: MtbTrailLineChoice.bLine,
            lengthMeters: 470.0,
            dropHeightMeters: 0.25,
            technicalDifficulty: 4.0,
            timeAdvantageSeconds: 0.0,
            crashRiskBase: 0.02,
            minSuspensionTravelMm: 100,
            requiresDropperPost: false,
          ),
        ),
        MtbXcoCourseSegment(
          index: 2,
          name: 'Switchback Punch Climb',
          startMeter: 1050.0,
          lengthMeters: 980.0,
          featureType: MtbXcoFeatureType.punchyClimb,
          gradientPercent: 12.4,
          roughnessIndex: 0.36,
          recommendedLockout: SuspensionLockoutMode.pedalTrail,
          recommendedDropper: DropperPostState.extended,
        ),
        MtbXcoCourseSegment(
          index: 3,
          name: 'Tech Zone & Water Feed',
          startMeter: 2030.0,
          lengthMeters: 170.0,
          featureType: MtbXcoFeatureType.techZonePit,
          gradientPercent: 0.0,
          roughnessIndex: 0.08,
          recommendedLockout: SuspensionLockoutMode.locked,
          recommendedDropper: DropperPostState.extended,
          isTechFeedZone: true,
        ),
        MtbXcoCourseSegment(
          index: 4,
          name: 'Pine Root Traverse',
          startMeter: 2200.0,
          lengthMeters: 760.0,
          featureType: MtbXcoFeatureType.rootSection,
          gradientPercent: -3.5,
          roughnessIndex: 0.66,
          rootDensityPerMeter: 1.9,
          recommendedLockout: SuspensionLockoutMode.open,
          recommendedDropper: DropperPostState.midDrop,
        ),
        MtbXcoCourseSegment(
          index: 5,
          name: 'Timber Drop & Berm Series',
          startMeter: 2960.0,
          lengthMeters: 540.0,
          featureType: MtbXcoFeatureType.dropOff,
          gradientPercent: -11.0,
          roughnessIndex: 0.78,
          dropHeightMeters: 1.10,
          recommendedLockout: SuspensionLockoutMode.open,
          recommendedDropper: DropperPostState.slammed,
          aLine: MtbXcoLineOption(
            lineChoice: MtbTrailLineChoice.aLine,
            lengthMeters: 515.0,
            dropHeightMeters: 1.10,
            technicalDifficulty: 8.5,
            timeAdvantageSeconds: 2.9,
            crashRiskBase: 0.08,
            minSuspensionTravelMm: 120,
            requiresDropperPost: true,
          ),
          bLine: MtbXcoLineOption(
            lineChoice: MtbTrailLineChoice.bLine,
            lengthMeters: 560.0,
            dropHeightMeters: 0.30,
            technicalDifficulty: 4.4,
            timeAdvantageSeconds: 0.0,
            crashRiskBase: 0.02,
            minSuspensionTravelMm: 100,
            requiresDropperPost: false,
          ),
        ),
        MtbXcoCourseSegment(
          index: 6,
          name: 'Pump Rollers & Finish',
          startMeter: 3500.0,
          lengthMeters: 700.0,
          featureType: MtbXcoFeatureType.finishStraight,
          gradientPercent: 1.2,
          roughnessIndex: 0.18,
          recommendedLockout: SuspensionLockoutMode.locked,
          recommendedDropper: DropperPostState.extended,
        ),
      ],
    );
  }

  MtbXcoCourseAndSuspensionModel copyWith({
    String? courseId,
    String? name,
    String? venueLocation,
    MtbXcoRaceTier? raceTier,
    double? lapDistanceKm,
    int? totalLaps,
    double? startLoopMeters,
    double? elevationGainPerLapMeters,
    double? altitudeMeters,
    MtbTrailSoilCondition? soilCondition,
    List<MtbXcoCourseSegment>? segments,
    int? techZoneCountPerLap,
  }) {
    return MtbXcoCourseAndSuspensionModel(
      courseId: courseId ?? this.courseId,
      name: name ?? this.name,
      venueLocation: venueLocation ?? this.venueLocation,
      raceTier: raceTier ?? this.raceTier,
      lapDistanceKm: lapDistanceKm ?? this.lapDistanceKm,
      totalLaps: totalLaps ?? this.totalLaps,
      startLoopMeters: startLoopMeters ?? this.startLoopMeters,
      elevationGainPerLapMeters:
          elevationGainPerLapMeters ?? this.elevationGainPerLapMeters,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      soilCondition: soilCondition ?? this.soilCondition,
      segments: segments ?? this.segments,
      techZoneCountPerLap: techZoneCountPerLap ?? this.techZoneCountPerLap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'name': name,
      'venueLocation': venueLocation,
      'raceTier': raceTier.toJson(),
      'lapDistanceKm': lapDistanceKm,
      'totalLaps': totalLaps,
      'startLoopMeters': startLoopMeters,
      'elevationGainPerLapMeters': elevationGainPerLapMeters,
      'altitudeMeters': altitudeMeters,
      'soilCondition': soilCondition.toJson(),
      'segments': segments.map((e) => e.toJson()).toList(),
      'techZoneCountPerLap': techZoneCountPerLap,
    };
  }

  factory MtbXcoCourseAndSuspensionModel.fromJson(Map<String, dynamic> json) {
    final rawSegments = json['segments'];
    final parsedSegments = rawSegments is List
        ? rawSegments
            .whereType<Map<String, dynamic>>()
            .map(MtbXcoCourseSegment.fromJson)
            .toList()
        : <MtbXcoCourseSegment>[];
    return MtbXcoCourseAndSuspensionModel(
      courseId: json['courseId']?.toString() ?? 'xco_custom',
      name: json['name']?.toString() ?? 'MTB XCO Circuit',
      venueLocation: json['venueLocation']?.toString() ?? 'Unknown Venue',
      raceTier: MtbXcoRaceTier.fromJson(
        json['raceTier']?.toString() ?? 'worldCupXco',
      ),
      lapDistanceKm: (json['lapDistanceKm'] as num?)?.toDouble() ?? 4.2,
      totalLaps: (json['totalLaps'] as num?)?.toInt() ?? 6,
      startLoopMeters: (json['startLoopMeters'] as num?)?.toDouble() ?? 850.0,
      elevationGainPerLapMeters:
          (json['elevationGainPerLapMeters'] as num?)?.toDouble() ?? 165.0,
      altitudeMeters: (json['altitudeMeters'] as num?)?.toDouble() ?? 620.0,
      soilCondition: MtbTrailSoilCondition.fromJson(
        json['soilCondition']?.toString() ?? 'tackyLoam',
      ),
      segments: parsedSegments,
      techZoneCountPerLap:
          (json['techZoneCountPerLap'] as num?)?.toInt() ?? 2,
    );
  }
}

/// Konfiguracja zawieszenia przedniego i tylnego Full-Suspension 100–120 mm.
class MtbForkAndShockSetup {
  final MtbSuspensionArchitecture architecture;
  final int forkTravelMm;
  final int rearShockTravelMm;
  final double forkAirPressurePsi;
  final double rearShockAirPressurePsi;
  final double forkSagPercent;
  final double rearShockSagPercent;
  final int forkReboundClicks;
  final int rearReboundClicks;
  final int volumeSpacersCount;
  final SuspensionLockoutMode remoteLockoutMode;
  final bool hasElectronicFlightAttendant;

  const MtbForkAndShockSetup({
    this.architecture =
        MtbSuspensionArchitecture.fullSuspensionDowncountry120,
    this.forkTravelMm = 120,
    this.rearShockTravelMm = 120,
    this.forkAirPressurePsi = 88.0,
    this.rearShockAirPressurePsi = 162.0,
    this.forkSagPercent = 18.0,
    this.rearShockSagPercent = 24.0,
    this.forkReboundClicks = 9,
    this.rearReboundClicks = 8,
    this.volumeSpacersCount = 2,
    this.remoteLockoutMode = SuspensionLockoutMode.open,
    this.hasElectronicFlightAttendant = false,
  });

  /// Zalecane ciśnienie widelca [PSI] dla wagi kolarza [kg] (~1.32 PSI/kg).
  static double computeRecommendedForkPsi(double riderWeightKg) {
    return (riderWeightKg.clamp(45.0, 110.0) * 1.32).roundToDouble();
  }

  /// Zalecane ciśnienie dampera [PSI] dla wagi kolarza [kg] (~2.42 PSI/kg).
  static double computeRecommendedRearPsi(double riderWeightKg) {
    return (riderWeightKg.clamp(45.0, 110.0) * 2.42).roundToDouble();
  }

  /// Ocena jakości tłumienia nierówności (0.0–1.0) dla zadanego indeksu terenu.
  double dampingQualityScore(double roughnessIndex) {
    final travelFactor =
        ((forkTravelMm.clamp(100, 120) + rearShockTravelMm.clamp(0, 120)) /
                240.0)
            .clamp(0.42, 1.0);
    final sagPenalty =
        ((forkSagPercent - 18.0).abs() * 0.015) +
        (rearShockTravelMm > 0
            ? (rearShockSagPercent - 24.0).abs() * 0.015
            : 0.0);
    final lockoutFactor = hasElectronicFlightAttendant
        ? 1.0
        : remoteLockoutMode.dampingAbsorptionFactor;
    final raw = (0.55 + 0.45 * travelFactor) *
        (0.65 + 0.35 * lockoutFactor) -
        sagPenalty -
        (roughnessIndex > 0.75 && rearShockTravelMm == 0 ? 0.18 : 0.0);
    return raw.clamp(0.15, 1.0);
  }

  /// Ryzyko dobicia zawieszenia (Bottom-Out) na dropie o zadanej wysokości [m].
  double bottomOutRisk(double dropHeightMeters, double riderWeightKg) {
    if (dropHeightMeters <= 0.25) return 0.01;
    final recForkPsi = computeRecommendedForkPsi(riderWeightKg);
    final underPressureRatio =
        ((recForkPsi - forkAirPressurePsi) / recForkPsi).clamp(-0.3, 0.5);
    final spacerProtection = volumeSpacersCount.clamp(0, 4) * 0.045;
    final travelMargin = forkTravelMm >= 120 ? 0.08 : 0.0;
    final risk = (dropHeightMeters * 0.14) +
        (underPressureRatio * 0.35) -
        spacerProtection -
        travelMargin;
    return risk.clamp(0.01, 0.85);
  }

  MtbForkAndShockSetup copyWith({
    MtbSuspensionArchitecture? architecture,
    int? forkTravelMm,
    int? rearShockTravelMm,
    double? forkAirPressurePsi,
    double? rearShockAirPressurePsi,
    double? forkSagPercent,
    double? rearShockSagPercent,
    int? forkReboundClicks,
    int? rearReboundClicks,
    int? volumeSpacersCount,
    SuspensionLockoutMode? remoteLockoutMode,
    bool? hasElectronicFlightAttendant,
  }) {
    return MtbForkAndShockSetup(
      architecture: architecture ?? this.architecture,
      forkTravelMm: forkTravelMm ?? this.forkTravelMm,
      rearShockTravelMm: rearShockTravelMm ?? this.rearShockTravelMm,
      forkAirPressurePsi: forkAirPressurePsi ?? this.forkAirPressurePsi,
      rearShockAirPressurePsi:
          rearShockAirPressurePsi ?? this.rearShockAirPressurePsi,
      forkSagPercent: forkSagPercent ?? this.forkSagPercent,
      rearShockSagPercent: rearShockSagPercent ?? this.rearShockSagPercent,
      forkReboundClicks: forkReboundClicks ?? this.forkReboundClicks,
      rearReboundClicks: rearReboundClicks ?? this.rearReboundClicks,
      volumeSpacersCount: volumeSpacersCount ?? this.volumeSpacersCount,
      remoteLockoutMode: remoteLockoutMode ?? this.remoteLockoutMode,
      hasElectronicFlightAttendant:
          hasElectronicFlightAttendant ?? this.hasElectronicFlightAttendant,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'architecture': architecture.toJson(),
      'forkTravelMm': forkTravelMm,
      'rearShockTravelMm': rearShockTravelMm,
      'forkAirPressurePsi': forkAirPressurePsi,
      'rearShockAirPressurePsi': rearShockAirPressurePsi,
      'forkSagPercent': forkSagPercent,
      'rearShockSagPercent': rearShockSagPercent,
      'forkReboundClicks': forkReboundClicks,
      'rearReboundClicks': rearReboundClicks,
      'volumeSpacersCount': volumeSpacersCount,
      'remoteLockoutMode': remoteLockoutMode.toJson(),
      'hasElectronicFlightAttendant': hasElectronicFlightAttendant,
    };
  }

  factory MtbForkAndShockSetup.fromJson(Map<String, dynamic> json) {
    return MtbForkAndShockSetup(
      architecture: MtbSuspensionArchitecture.fromJson(
        json['architecture']?.toString() ?? 'fullSuspensionDowncountry120',
      ),
      forkTravelMm: (json['forkTravelMm'] as num?)?.toInt() ?? 120,
      rearShockTravelMm: (json['rearShockTravelMm'] as num?)?.toInt() ?? 120,
      forkAirPressurePsi:
          (json['forkAirPressurePsi'] as num?)?.toDouble() ?? 88.0,
      rearShockAirPressurePsi:
          (json['rearShockAirPressurePsi'] as num?)?.toDouble() ?? 162.0,
      forkSagPercent: (json['forkSagPercent'] as num?)?.toDouble() ?? 18.0,
      rearShockSagPercent:
          (json['rearShockSagPercent'] as num?)?.toDouble() ?? 24.0,
      forkReboundClicks: (json['forkReboundClicks'] as num?)?.toInt() ?? 9,
      rearReboundClicks: (json['rearReboundClicks'] as num?)?.toInt() ?? 8,
      volumeSpacersCount: (json['volumeSpacersCount'] as num?)?.toInt() ?? 2,
      remoteLockoutMode: SuspensionLockoutMode.fromJson(
        json['remoteLockoutMode']?.toString() ?? 'open',
      ),
      hasElectronicFlightAttendant:
          json['hasElectronicFlightAttendant'] as bool? ?? false,
    );
  }
}

/// Specyfikacja sztycy regulowanej (Dropper Post) w rowerze MTB XCO.
class DropperPostSpec {
  final int travelMm;
  final double weightGrams;
  final int actuationLatencyMs;
  final DropperPostState currentState;
  final bool isWirelessElectronic;

  const DropperPostSpec({
    this.travelMm = 100,
    this.weightGrams = 415.0,
    this.actuationLatencyMs = 120,
    this.currentState = DropperPostState.extended,
    this.isWirelessElectronic = true,
  });

  /// Aktualne obniżenie siodła względem maksymalnej wysokości [mm].
  double get effectiveDropMm => travelMm * currentState.dropFraction;

  /// Zysk kontroli technicznej na zadanym segmencie (0.0–0.32).
  double controlGainOnSegment(MtbXcoCourseSegment segment) {
    if (!segment.isTechnicalDescent &&
        segment.featureType != MtbXcoFeatureType.rockGarden &&
        segment.featureType != MtbXcoFeatureType.dropOff) {
      return 0.0;
    }
    final travelRatio = (travelMm.clamp(60, 150) / 100.0).clamp(0.6, 1.3);
    final baseBonus =
        segment.recommendedDropper.technicalControlBonus * travelRatio;
    final latencyBonus = isWirelessElectronic ? 0.025 : 0.0;
    return (baseBonus + latencyBonus).clamp(0.0, 0.35);
  }

  DropperPostSpec copyWith({
    int? travelMm,
    double? weightGrams,
    int? actuationLatencyMs,
    DropperPostState? currentState,
    bool? isWirelessElectronic,
  }) {
    return DropperPostSpec(
      travelMm: travelMm ?? this.travelMm,
      weightGrams: weightGrams ?? this.weightGrams,
      actuationLatencyMs: actuationLatencyMs ?? this.actuationLatencyMs,
      currentState: currentState ?? this.currentState,
      isWirelessElectronic: isWirelessElectronic ?? this.isWirelessElectronic,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'travelMm': travelMm,
      'weightGrams': weightGrams,
      'actuationLatencyMs': actuationLatencyMs,
      'currentState': currentState.toJson(),
      'isWirelessElectronic': isWirelessElectronic,
    };
  }

  factory DropperPostSpec.fromJson(Map<String, dynamic> json) {
    return DropperPostSpec(
      travelMm: (json['travelMm'] as num?)?.toInt() ?? 100,
      weightGrams: (json['weightGrams'] as num?)?.toDouble() ?? 415.0,
      actuationLatencyMs: (json['actuationLatencyMs'] as num?)?.toInt() ?? 120,
      currentState: DropperPostState.fromJson(
        json['currentState']?.toString() ?? 'extended',
      ),
      isWirelessElectronic: json['isWirelessElectronic'] as bool? ?? true,
    );
  }
}

/// Konfiguracja szerokich opon bezdętkowych MTB XC 2.4".
class MtbTire24Setup {
  final double widthInches;
  final MtbTireTreadPattern treadPattern;
  final double frontPressureBar;
  final double rearPressureBar;
  final bool hasRimInsert;
  final int sealantVolumeMl;
  final int casingTpi;

  const MtbTire24Setup({
    this.widthInches = 2.4,
    this.treadPattern = MtbTireTreadPattern.allRoundXcKnob,
    this.frontPressureBar = 1.32,
    this.rearPressureBar = 1.42,
    this.hasRimInsert = true,
    this.sealantVolumeMl = 90,
    this.casingTpi = 120,
  });

  /// Przyczepność opony na zadanym podłożu (0.3–1.25).
  double gripScore(MtbTrailSoilCondition soil) {
    final avgPressure = (frontPressureBar + rearPressureBar) / 2.0;
    final pressureBonus = ((1.55 - avgPressure) * 0.25).clamp(-0.15, 0.14);
    final widthBonus = ((widthInches - 2.25) * 0.35).clamp(0.0, 0.10);
    return (soil.gripMultiplier + treadPattern.wetGripBonus + pressureBonus + widthBonus)
        .clamp(0.30, 1.25);
  }

  /// Efektywny współczynnik oporu toczenia (CRR) na danym podłożu.
  double rollingResistanceCrr(MtbTrailSoilCondition soil) {
    final avgPressure = (frontPressureBar + rearPressureBar) / 2.0;
    final pressureFactor = 1.0 + ((1.40 - avgPressure) * 0.08);
    return (treadPattern.baseCrr * soil.crrMultiplier * pressureFactor)
        .clamp(0.0045, 0.0250);
  }

  /// Ryzyko dobicia opony do obręczy ("snakebite") na ostrych kamieniach.
  double pinchFlatRisk(double roughnessIndex, double riderWeightKg) {
    final minBar = (0.95 + (riderWeightKg / 145.0)).clamp(1.10, 1.65);
    final deficit = (minBar - rearPressureBar).clamp(0.0, 0.6);
    final insertFactor = hasRimInsert ? 0.28 : 1.0;
    return (roughnessIndex * 0.06 + deficit * 0.32) * insertFactor;
  }

  MtbTire24Setup copyWith({
    double? widthInches,
    MtbTireTreadPattern? treadPattern,
    double? frontPressureBar,
    double? rearPressureBar,
    bool? hasRimInsert,
    int? sealantVolumeMl,
    int? casingTpi,
  }) {
    return MtbTire24Setup(
      widthInches: widthInches ?? this.widthInches,
      treadPattern: treadPattern ?? this.treadPattern,
      frontPressureBar: frontPressureBar ?? this.frontPressureBar,
      rearPressureBar: rearPressureBar ?? this.rearPressureBar,
      hasRimInsert: hasRimInsert ?? this.hasRimInsert,
      sealantVolumeMl: sealantVolumeMl ?? this.sealantVolumeMl,
      casingTpi: casingTpi ?? this.casingTpi,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'widthInches': widthInches,
      'treadPattern': treadPattern.toJson(),
      'frontPressureBar': frontPressureBar,
      'rearPressureBar': rearPressureBar,
      'hasRimInsert': hasRimInsert,
      'sealantVolumeMl': sealantVolumeMl,
      'casingTpi': casingTpi,
    };
  }

  factory MtbTire24Setup.fromJson(Map<String, dynamic> json) {
    return MtbTire24Setup(
      widthInches: (json['widthInches'] as num?)?.toDouble() ?? 2.4,
      treadPattern: MtbTireTreadPattern.fromJson(
        json['treadPattern']?.toString() ?? 'allRoundXcKnob',
      ),
      frontPressureBar: (json['frontPressureBar'] as num?)?.toDouble() ?? 1.32,
      rearPressureBar: (json['rearPressureBar'] as num?)?.toDouble() ?? 1.42,
      hasRimInsert: json['hasRimInsert'] as bool? ?? true,
      sealantVolumeMl: (json['sealantVolumeMl'] as num?)?.toInt() ?? 90,
      casingTpi: (json['casingTpi'] as num?)?.toInt() ?? 120,
    );
  }
}

/// Raport gotowości i dopasowania roweru MTB XCO do konkretnej rundy.
class MtbXcoSetupReadinessReport {
  final double overallScore;
  final double suspensionMatchScore;
  final double tireGripScore;
  final double climbingEfficiencyScore;
  final double aLineConfidenceScore;
  final double estimatedLapTimeSeconds;
  final List<String> warnings;
  final List<String> recommendations;

  const MtbXcoSetupReadinessReport({
    required this.overallScore,
    required this.suspensionMatchScore,
    required this.tireGripScore,
    required this.climbingEfficiencyScore,
    required this.aLineConfidenceScore,
    required this.estimatedLapTimeSeconds,
    this.warnings = const [],
    this.recommendations = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'suspensionMatchScore': suspensionMatchScore,
      'tireGripScore': tireGripScore,
      'climbingEfficiencyScore': climbingEfficiencyScore,
      'aLineConfidenceScore': aLineConfidenceScore,
      'estimatedLapTimeSeconds': estimatedLapTimeSeconds,
      'warnings': warnings,
      'recommendations': recommendations,
    };
  }

  factory MtbXcoSetupReadinessReport.fromJson(Map<String, dynamic> json) {
    return MtbXcoSetupReadinessReport(
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0.0,
      suspensionMatchScore:
          (json['suspensionMatchScore'] as num?)?.toDouble() ?? 0.0,
      tireGripScore: (json['tireGripScore'] as num?)?.toDouble() ?? 0.0,
      climbingEfficiencyScore:
          (json['climbingEfficiencyScore'] as num?)?.toDouble() ?? 0.0,
      aLineConfidenceScore:
          (json['aLineConfidenceScore'] as num?)?.toDouble() ?? 0.0,
      estimatedLapTimeSeconds:
          (json['estimatedLapTimeSeconds'] as num?)?.toDouble() ?? 780.0,
      warnings: (json['warnings'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      recommendations: (json['recommendations'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

/// Kompletna konfiguracja roweru MTB XCO (rama, zawieszenie 100–120 mm, sztyca Dropper Post i opony 2.4").
class MtbXcoBikeConfiguration {
  final String bikeId;
  final String modelName;
  final double totalWeightKg;
  final MtbForkAndShockSetup suspension;
  final DropperPostSpec dropperPost;
  final MtbTire24Setup tireSetup;
  final int chainringTeeth;
  final String cassetteRange;

  const MtbXcoBikeConfiguration({
    required this.bikeId,
    required this.modelName,
    this.totalWeightKg = 10.2,
    this.suspension = const MtbForkAndShockSetup(),
    this.dropperPost = const DropperPostSpec(),
    this.tireSetup = const MtbTire24Setup(),
    this.chainringTeeth = 34,
    this.cassetteRange = '10-52T',
  });

  /// Ocenia dopasowanie sprzętu do danej rundy MTB XCO i wagi kolarza.
  MtbXcoSetupReadinessReport evaluateCourseReadiness(
    MtbXcoCourseAndSuspensionModel course,
    double riderWeightKg,
  ) {
    final warnings = <String>[];
    final recommendations = <String>[];

    final roughness = course.averageRoughnessIndex;
    final damping = suspension.dampingQualityScore(roughness);
    final recTravel = course.recommendedTravelMm;
    final travelPenalty =
        suspension.forkTravelMm < recTravel ? 12.0 : 0.0;
    final suspensionScore = (damping * 100.0 - travelPenalty).clamp(0.0, 100.0);

    if (suspension.forkTravelMm < recTravel) {
      warnings.add(
        'Trasa wymaga skoku $recTravel mm na rock gardenach (obecnie ${suspension.forkTravelMm} mm).',
      );
      recommendations.add('Rozważ ramę Full-Suspension 120/120 mm.');
    }

    final grip = tireSetup.gripScore(course.soilCondition);
    final tireScore = (grip / 1.15 * 100.0).clamp(0.0, 100.0);
    final pinchRisk = tireSetup.pinchFlatRisk(roughness, riderWeightKg);
    if (pinchRisk > 0.08) {
      warnings.add(
        'Podwyższone ryzyko dobicia opony do obręczy (${(pinchRisk * 100).toStringAsFixed(1)}%).',
      );
      recommendations.add(
        'Zwiększ ciśnienie o +0.10 bar lub zamontuj wkładki antyprzebiciowe.',
      );
    }

    final weightFactor = ((11.5 - totalWeightKg) / 2.8).clamp(0.0, 1.0);
    final efficiency =
        suspension.architecture.pedalingEfficiencyFactor * 100.0;
    final climbingScore =
        (efficiency * 0.72 + weightFactor * 28.0).clamp(0.0, 100.0);

    final dropperBonus = dropperPost.travelMm >= 100 ? 18.0 : 8.0;
    final aLineConfidence =
        (suspensionScore * 0.45 + tireScore * 0.37 + dropperBonus)
            .clamp(0.0, 100.0);

    if (dropperPost.travelMm < 100 && course.dropCount > 0) {
      recommendations.add(
        'Zainstaluj sztycę regulowaną Dropper Post >=100 mm dla pewnego pokonywania dropów.',
      );
    }

    final overall = (suspensionScore * 0.32 +
            tireScore * 0.28 +
            climbingScore * 0.22 +
            aLineConfidence * 0.18)
        .clamp(0.0, 100.0);

    // Bazowe okrążenie 4.2 km ~ 12 min 45 s (765 s) w tempie World Cup
    final baseLapSeconds = course.lapDistanceKm * 182.0 +
        course.elevationGainPerLapMeters * 0.48;
    final setupDeltaSeconds = (85.0 - overall) * 0.45;
    final estimatedLap = (baseLapSeconds + setupDeltaSeconds).clamp(180.0, 1800.0);

    return MtbXcoSetupReadinessReport(
      overallScore: double.parse(overall.toStringAsFixed(1)),
      suspensionMatchScore: double.parse(suspensionScore.toStringAsFixed(1)),
      tireGripScore: double.parse(tireScore.toStringAsFixed(1)),
      climbingEfficiencyScore: double.parse(climbingScore.toStringAsFixed(1)),
      aLineConfidenceScore: double.parse(aLineConfidence.toStringAsFixed(1)),
      estimatedLapTimeSeconds: double.parse(estimatedLap.toStringAsFixed(1)),
      warnings: warnings,
      recommendations: recommendations,
    );
  }

  MtbXcoBikeConfiguration copyWith({
    String? bikeId,
    String? modelName,
    double? totalWeightKg,
    MtbForkAndShockSetup? suspension,
    DropperPostSpec? dropperPost,
    MtbTire24Setup? tireSetup,
    int? chainringTeeth,
    String? cassetteRange,
  }) {
    return MtbXcoBikeConfiguration(
      bikeId: bikeId ?? this.bikeId,
      modelName: modelName ?? this.modelName,
      totalWeightKg: totalWeightKg ?? this.totalWeightKg,
      suspension: suspension ?? this.suspension,
      dropperPost: dropperPost ?? this.dropperPost,
      tireSetup: tireSetup ?? this.tireSetup,
      chainringTeeth: chainringTeeth ?? this.chainringTeeth,
      cassetteRange: cassetteRange ?? this.cassetteRange,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bikeId': bikeId,
      'modelName': modelName,
      'totalWeightKg': totalWeightKg,
      'suspension': suspension.toJson(),
      'dropperPost': dropperPost.toJson(),
      'tireSetup': tireSetup.toJson(),
      'chainringTeeth': chainringTeeth,
      'cassetteRange': cassetteRange,
    };
  }

  factory MtbXcoBikeConfiguration.fromJson(Map<String, dynamic> json) {
    return MtbXcoBikeConfiguration(
      bikeId: json['bikeId']?.toString() ?? 'mtb_xco_pro',
      modelName: json['modelName']?.toString() ?? 'Factory XC 120 Team',
      totalWeightKg: (json['totalWeightKg'] as num?)?.toDouble() ?? 10.2,
      suspension: json['suspension'] is Map<String, dynamic>
          ? MtbForkAndShockSetup.fromJson(
              json['suspension'] as Map<String, dynamic>,
            )
          : const MtbForkAndShockSetup(),
      dropperPost: json['dropperPost'] is Map<String, dynamic>
          ? DropperPostSpec.fromJson(
              json['dropperPost'] as Map<String, dynamic>,
            )
          : const DropperPostSpec(),
      tireSetup: json['tireSetup'] is Map<String, dynamic>
          ? MtbTire24Setup.fromJson(
              json['tireSetup'] as Map<String, dynamic>,
            )
          : const MtbTire24Setup(),
      chainringTeeth: (json['chainringTeeth'] as num?)?.toInt() ?? 34,
      cassetteRange: json['cassetteRange']?.toString() ?? '10-52T',
    );
  }
}
