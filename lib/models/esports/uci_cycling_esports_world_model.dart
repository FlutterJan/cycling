import 'dart:math' as math;

/// Poziom rozgrywek UCI Cycling Esports.
enum EsportsPlatformTier {
  uciWorldChampionships,
  virtualGrandTour,
  virtualTalentIdAcademy,
  communityCritSeries;

  String toJson() => name;

  static EsportsPlatformTier fromJson(String value) {
    return EsportsPlatformTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EsportsPlatformTier.uciWorldChampionships,
    );
  }

  /// Czytelna nazwa poziomu rozgrywek po polsku.
  String get displayNamePl {
    switch (this) {
      case EsportsPlatformTier.uciWorldChampionships:
        return 'Mistrzostwa Świata UCI Cycling Esports';
      case EsportsPlatformTier.virtualGrandTour:
        return 'Wirtualny Grand Tour';
      case EsportsPlatformTier.virtualTalentIdAcademy:
        return 'Akademia Talentów Virtual Talent ID';
      case EsportsPlatformTier.communityCritSeries:
        return 'Seria Kryteriów Społecznościowych';
    }
  }
}

/// Format wyścigu w świecie UCI Cycling Esports.
enum EsportsRaceFormat {
  eliminationEvery60s,
  pointsRace,
  scratchRace,
  climbPortal,
  teamTimeTrial;

  String toJson() => name;

  static EsportsRaceFormat fromJson(String value) {
    return EsportsRaceFormat.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EsportsRaceFormat.eliminationEvery60s,
    );
  }

  /// Czytelna nazwa formatu wyścigu po polsku.
  String get displayNamePl {
    switch (this) {
      case EsportsRaceFormat.eliminationEvery60s:
        return 'Wyścig Eliminacyjny (co 60 s)';
      case EsportsRaceFormat.pointsRace:
        return 'Wyścig Punktowy';
      case EsportsRaceFormat.scratchRace:
        return 'Wyścig Scratch';
      case EsportsRaceFormat.climbPortal:
        return 'Portal Górski';
      case EsportsRaceFormat.teamTimeTrial:
        return 'Drużynowa Jazda na Czas (TTT)';
    }
  }
}

/// Klasa trenażera interaktywnego Smart używanego przez kolarza.
enum SmartTrainerTier {
  smartBikeIntegrated,
  directDrivePro,
  directDriveStandard,
  wheelOnBasic;

  String toJson() => name;

  static SmartTrainerTier fromJson(String value) {
    return SmartTrainerTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SmartTrainerTier.directDrivePro,
    );
  }

  /// Czytelna nazwa klasy trenażera po polsku.
  String get displayNamePl {
    switch (this) {
      case SmartTrainerTier.smartBikeIntegrated:
        return 'Rower Smart Bike (Zintegrowany)';
      case SmartTrainerTier.directDrivePro:
        return 'Direct-Drive Pro (±1.0%)';
      case SmartTrainerTier.directDriveStandard:
        return 'Direct-Drive Standard (±2.0%)';
      case SmartTrainerTier.wheelOnBasic:
        return 'Trenażer Rolkowy Wheel-On (±3.5%)';
    }
  }

  /// Czy trenażer jest dopuszczony do oficjalnych zawodów UCI Cycling Esports.
  bool get isUciWorldChampionshipEligible {
    switch (this) {
      case SmartTrainerTier.smartBikeIntegrated:
      case SmartTrainerTier.directDrivePro:
        return true;
      case SmartTrainerTier.directDriveStandard:
      case SmartTrainerTier.wheelOnBasic:
        return false;
    }
  }
}

/// Status kalibracji i weryfikacji podwójnego pomiaru mocy (Dual Recording).
enum SmartTrainerCalibrationStatus {
  calibrated,
  warmUpRequired,
  driftDetected,
  dualRecordingMismatch;

  String toJson() => name;

  static SmartTrainerCalibrationStatus fromJson(String value) {
    return SmartTrainerCalibrationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SmartTrainerCalibrationStatus.calibrated,
    );
  }

  /// Czytelna etykieta statusu kalibracji po polsku.
  String get displayNamePl {
    switch (this) {
      case SmartTrainerCalibrationStatus.calibrated:
        return 'Skalibrowany (Spindown OK)';
      case SmartTrainerCalibrationStatus.warmUpRequired:
        return 'Wymagana rozgrzewka 10 min';
      case SmartTrainerCalibrationStatus.driftDetected:
        return 'Wykryto dryft termiczny';
      case SmartTrainerCalibrationStatus.dualRecordingMismatch:
        return 'Rozbieżność Dual-Recording';
    }
  }
}

/// Rodzaje Power-Upów dostępnych w wyścigach UCI Cycling Esports.
enum EsportsPowerUpType {
  aeroHelmet,
  featherweight,
  burrito,
  draftBoost,
  steamroller;

  String toJson() => name;

  static EsportsPowerUpType fromJson(String value) {
    return EsportsPowerUpType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EsportsPowerUpType.aeroHelmet,
    );
  }

  /// Oficjalna nazwa Power-Upa.
  String get displayName {
    switch (this) {
      case EsportsPowerUpType.aeroHelmet:
        return 'Aero Helmet';
      case EsportsPowerUpType.featherweight:
        return 'Featherweight';
      case EsportsPowerUpType.burrito:
        return 'Burrito';
      case EsportsPowerUpType.draftBoost:
        return 'Draft Boost';
      case EsportsPowerUpType.steamroller:
        return 'Steamroller';
    }
  }
}

/// Stan slotu Power-Upa u kolarza.
enum EsportsPowerUpSlotState {
  empty,
  ready,
  active,
  cooldown;

  String toJson() => name;

  static EsportsPowerUpSlotState fromJson(String value) {
    return EsportsPowerUpSlotState.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EsportsPowerUpSlotState.empty,
    );
  }
}

/// Status awatara kolarza w trakcie wyścigu e-Sports.
enum EsportsAvatarVerdict {
  active,
  eliminated,
  disqualifiedDualRecording,
  finished;

  String toJson() => name;

  static EsportsAvatarVerdict fromJson(String value) {
    return EsportsAvatarVerdict.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EsportsAvatarVerdict.active,
    );
  }

  /// Czytelny opis statusu zawodnika po polsku.
  String get displayNamePl {
    switch (this) {
      case EsportsAvatarVerdict.active:
        return 'W grze';
      case EsportsAvatarVerdict.eliminated:
        return 'Wyeliminowany';
      case EsportsAvatarVerdict.disqualifiedDualRecording:
        return 'DSQ (Dual-Recording)';
      case EsportsAvatarVerdict.finished:
        return 'Ukończył';
    }
  }
}

/// Motyw wizualny wirtualnego świata e-Sports.
enum VirtualWorldTheme {
  cyberVelodrome,
  glasgowUciCircuit,
  watopiaAlps,
  abuDhabiDesertLoop,
  tokyoNeonCrit;

  String toJson() => name;

  static VirtualWorldTheme fromJson(String value) {
    return VirtualWorldTheme.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => VirtualWorldTheme.cyberVelodrome,
    );
  }

  /// Czytelna nazwa motywu świata po polsku.
  String get displayNamePl {
    switch (this) {
      case VirtualWorldTheme.cyberVelodrome:
        return 'Cyber-Welodrom Neon';
      case VirtualWorldTheme.glasgowUciCircuit:
        return 'Glasgow UCI Virtual Circuit';
      case VirtualWorldTheme.watopiaAlps:
        return 'Alpy Wirtualne';
      case VirtualWorldTheme.abuDhabiDesertLoop:
        return 'Abu Dhabi Yas Marina Loop';
      case VirtualWorldTheme.tokyoNeonCrit:
        return 'Tokio Neon Crit';
    }
  }
}

/// Specyfikacja sprzętowa trenażera interaktywnego Smart oraz weryfikacja UCI.
class SmartTrainerHardwareSpec {
  final String id;
  final String brand;
  final String modelName;
  final SmartTrainerTier tier;
  final double accuracyPercent;
  final double maxSimulatedGradientPercent;
  final double flywheelInertiaKg;
  final int maxPowerWatts;
  final bool supportsVirtualShifting;
  final bool supportsErgMode;
  final double calibrationDriftWatts;
  final SmartTrainerCalibrationStatus calibrationStatus;
  final bool dualPowerMeterVerified;

  const SmartTrainerHardwareSpec({
    required this.id,
    required this.brand,
    required this.modelName,
    required this.tier,
    required this.accuracyPercent,
    required this.maxSimulatedGradientPercent,
    required this.flywheelInertiaKg,
    required this.maxPowerWatts,
    this.supportsVirtualShifting = true,
    this.supportsErgMode = true,
    this.calibrationDriftWatts = 0.0,
    this.calibrationStatus = SmartTrainerCalibrationStatus.calibrated,
    this.dualPowerMeterVerified = true,
  });

  /// Preset flagowego trenażera klasy UCI World Championships.
  factory SmartTrainerHardwareSpec.proDirectDrive({
    String id = 'trainer_pro_dd',
    String brand = 'Tacx / Wahoo',
    String modelName = 'Neo Kicker Pro 2T',
  }) {
    return SmartTrainerHardwareSpec(
      id: id,
      brand: brand,
      modelName: modelName,
      tier: SmartTrainerTier.directDrivePro,
      accuracyPercent: 1.0,
      maxSimulatedGradientPercent: 25.0,
      flywheelInertiaKg: 7.2,
      maxPowerWatts: 2200,
      supportsVirtualShifting: true,
      supportsErgMode: true,
      calibrationDriftWatts: 0.0,
      calibrationStatus: SmartTrainerCalibrationStatus.calibrated,
      dualPowerMeterVerified: true,
    );
  }

  /// Preset zintegrowanego roweru Smart Bike najwyższej klasy.
  factory SmartTrainerHardwareSpec.smartBike({
    String id = 'trainer_smart_bike',
    String brand = 'Wahoo / Stages',
    String modelName = 'SB20 Pro Bike',
  }) {
    return SmartTrainerHardwareSpec(
      id: id,
      brand: brand,
      modelName: modelName,
      tier: SmartTrainerTier.smartBikeIntegrated,
      accuracyPercent: 0.5,
      maxSimulatedGradientPercent: 25.0,
      flywheelInertiaKg: 22.0,
      maxPowerWatts: 2500,
      supportsVirtualShifting: true,
      supportsErgMode: true,
      calibrationDriftWatts: 0.0,
      calibrationStatus: SmartTrainerCalibrationStatus.calibrated,
      dualPowerMeterVerified: true,
    );
  }

  /// Maksymalny margines błędu mocy [W] dla zadanej mocy wyjściowej.
  double effectivePowerErrorMarginWatts(double rawWatts) {
    final safeWatts = math.max(0.0, rawWatts);
    return (safeWatts * (accuracyPercent / 100.0)) +
        calibrationDriftWatts.abs();
  }

  /// Efektywne nachylenie, które trenażer jest w stanie oddać na oporze koła zamachowego.
  double clampSimulatedGradient(double targetGradientPercent) {
    return targetGradientPercent.clamp(
      -maxSimulatedGradientPercent * 0.5,
      maxSimulatedGradientPercent,
    );
  }

  /// Czy sprzęt spełnia wymogi techniczne oficjalnych zawodów UCI Cycling Esports.
  bool get isUciCompliant =>
      tier.isUciWorldChampionshipEligible &&
      dualPowerMeterVerified &&
      calibrationStatus == SmartTrainerCalibrationStatus.calibrated;

  SmartTrainerHardwareSpec copyWith({
    String? id,
    String? brand,
    String? modelName,
    SmartTrainerTier? tier,
    double? accuracyPercent,
    double? maxSimulatedGradientPercent,
    double? flywheelInertiaKg,
    int? maxPowerWatts,
    bool? supportsVirtualShifting,
    bool? supportsErgMode,
    double? calibrationDriftWatts,
    SmartTrainerCalibrationStatus? calibrationStatus,
    bool? dualPowerMeterVerified,
  }) {
    return SmartTrainerHardwareSpec(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      modelName: modelName ?? this.modelName,
      tier: tier ?? this.tier,
      accuracyPercent: accuracyPercent ?? this.accuracyPercent,
      maxSimulatedGradientPercent:
          maxSimulatedGradientPercent ?? this.maxSimulatedGradientPercent,
      flywheelInertiaKg: flywheelInertiaKg ?? this.flywheelInertiaKg,
      maxPowerWatts: maxPowerWatts ?? this.maxPowerWatts,
      supportsVirtualShifting:
          supportsVirtualShifting ?? this.supportsVirtualShifting,
      supportsErgMode: supportsErgMode ?? this.supportsErgMode,
      calibrationDriftWatts:
          calibrationDriftWatts ?? this.calibrationDriftWatts,
      calibrationStatus: calibrationStatus ?? this.calibrationStatus,
      dualPowerMeterVerified:
          dualPowerMeterVerified ?? this.dualPowerMeterVerified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'modelName': modelName,
      'tier': tier.toJson(),
      'accuracyPercent': accuracyPercent,
      'maxSimulatedGradientPercent': maxSimulatedGradientPercent,
      'flywheelInertiaKg': flywheelInertiaKg,
      'maxPowerWatts': maxPowerWatts,
      'supportsVirtualShifting': supportsVirtualShifting,
      'supportsErgMode': supportsErgMode,
      'calibrationDriftWatts': calibrationDriftWatts,
      'calibrationStatus': calibrationStatus.toJson(),
      'dualPowerMeterVerified': dualPowerMeterVerified,
    };
  }

  factory SmartTrainerHardwareSpec.fromJson(Map<String, dynamic> json) {
    return SmartTrainerHardwareSpec(
      id: json['id'] as String? ?? 'trainer_pro_dd',
      brand: json['brand'] as String? ?? 'Tacx / Wahoo',
      modelName: json['modelName'] as String? ?? 'Neo Kicker Pro 2T',
      tier: SmartTrainerTier.fromJson(json['tier'] as String? ?? ''),
      accuracyPercent: (json['accuracyPercent'] as num?)?.toDouble() ?? 1.0,
      maxSimulatedGradientPercent:
          (json['maxSimulatedGradientPercent'] as num?)?.toDouble() ?? 25.0,
      flywheelInertiaKg:
          (json['flywheelInertiaKg'] as num?)?.toDouble() ?? 7.2,
      maxPowerWatts: (json['maxPowerWatts'] as num?)?.toInt() ?? 2200,
      supportsVirtualShifting:
          json['supportsVirtualShifting'] as bool? ?? true,
      supportsErgMode: json['supportsErgMode'] as bool? ?? true,
      calibrationDriftWatts:
          (json['calibrationDriftWatts'] as num?)?.toDouble() ?? 0.0,
      calibrationStatus: SmartTrainerCalibrationStatus.fromJson(
        json['calibrationStatus'] as String? ?? '',
      ),
      dualPowerMeterVerified: json['dualPowerMeterVerified'] as bool? ?? true,
    );
  }
}

/// Specyfikacja działania Power-Upa w wyścigu e-Sports.
class EsportsPowerUpSpec {
  final EsportsPowerUpType type;
  final String displayName;
  final String descriptionPl;
  final double durationSeconds;
  final double cdaMultiplier;
  final double massMultiplier;
  final double crrMultiplier;
  final double draftMultiplier;
  final bool disablesRivalDraftBehind;
  final double disablesRivalDraftRadiusMeters;
  final double idealSlopeMinPercent;
  final double idealSlopeMaxPercent;

  const EsportsPowerUpSpec({
    required this.type,
    required this.displayName,
    required this.descriptionPl,
    required this.durationSeconds,
    this.cdaMultiplier = 1.0,
    this.massMultiplier = 1.0,
    this.crrMultiplier = 1.0,
    this.draftMultiplier = 1.0,
    this.disablesRivalDraftBehind = false,
    this.disablesRivalDraftRadiusMeters = 0.0,
    this.idealSlopeMinPercent = -10.0,
    this.idealSlopeMaxPercent = 20.0,
  });

  /// Katalog oficjalnych Power-Upów w grze.
  static const Map<EsportsPowerUpType, EsportsPowerUpSpec> catalog = {
    EsportsPowerUpType.aeroHelmet: EsportsPowerUpSpec(
      type: EsportsPowerUpType.aeroHelmet,
      displayName: 'Aero Helmet',
      descriptionPl:
          'Zmniejsza opór aerodynamiczny (CdA) o 25% na 15 s — idealny do sprintów i zjazdów.',
      durationSeconds: 15.0,
      cdaMultiplier: 0.75,
      idealSlopeMinPercent: -15.0,
      idealSlopeMaxPercent: 2.5,
    ),
    EsportsPowerUpType.featherweight: EsportsPowerUpSpec(
      type: EsportsPowerUpType.featherweight,
      displayName: 'Featherweight',
      descriptionPl:
          'Obniża wirtualną masę kolarza o 10% na 15 s — maksymalna przewaga na stromych podjazdach.',
      durationSeconds: 15.0,
      massMultiplier: 0.90,
      idealSlopeMinPercent: 4.5,
      idealSlopeMaxPercent: 25.0,
    ),
    EsportsPowerUpType.burrito: EsportsPowerUpSpec(
      type: EsportsPowerUpType.burrito,
      displayName: 'Burrito',
      descriptionPl:
          'Odłącza cień aerodynamiczny (draft) rywalom w promieniu 10 m za Tobą na 10 s.',
      durationSeconds: 10.0,
      disablesRivalDraftBehind: true,
      disablesRivalDraftRadiusMeters: 10.0,
      idealSlopeMinPercent: -5.0,
      idealSlopeMaxPercent: 4.0,
    ),
    EsportsPowerUpType.draftBoost: EsportsPowerUpSpec(
      type: EsportsPowerUpType.draftBoost,
      displayName: 'Draft Boost',
      descriptionPl:
          'Zwiększa skuteczność jazdy na kole (drafting) o 35% przez 20 s.',
      durationSeconds: 20.0,
      draftMultiplier: 1.35,
      idealSlopeMinPercent: -6.0,
      idealSlopeMaxPercent: 3.0,
    ),
    EsportsPowerUpType.steamroller: EsportsPowerUpSpec(
      type: EsportsPowerUpType.steamroller,
      displayName: 'Steamroller',
      descriptionPl:
          'Redukuje opór toczenia opon (CRR) o 50% na szutrze i bruku przez 20 s.',
      durationSeconds: 20.0,
      crrMultiplier: 0.50,
      idealSlopeMinPercent: -4.0,
      idealSlopeMaxPercent: 6.0,
    ),
  };

  /// Pobiera specyfikację dla wybranego typu Power-Upa.
  static EsportsPowerUpSpec forType(EsportsPowerUpType type) {
    return catalog[type] ?? catalog[EsportsPowerUpType.aeroHelmet]!;
  }

  /// Sprawdza, czy bieżące nachylenie trasy odpowiada optymalnemu oknu użycia Power-Upa.
  bool isOptimalForGradient(double gradientPercent) {
    return gradientPercent >= idealSlopeMinPercent &&
        gradientPercent <= idealSlopeMaxPercent;
  }
}

/// Aktywny lub gotowy do użycia slot Power-Upa kolarza.
class EsportsPowerUpInventorySlot {
  final int slotIndex;
  final EsportsPowerUpType? powerUp;
  final EsportsPowerUpSlotState state;
  final double remainingActiveSeconds;
  final double cooldownSeconds;

  const EsportsPowerUpInventorySlot({
    this.slotIndex = 0,
    this.powerUp,
    this.state = EsportsPowerUpSlotState.empty,
    this.remainingActiveSeconds = 0.0,
    this.cooldownSeconds = 0.0,
  });

  /// Aktywuje Power-Up, jeśli slot jest gotowy.
  EsportsPowerUpInventorySlot activate() {
    if (powerUp == null || state != EsportsPowerUpSlotState.ready) {
      return this;
    }
    final spec = EsportsPowerUpSpec.forType(powerUp!);
    return copyWith(
      state: EsportsPowerUpSlotState.active,
      remainingActiveSeconds: spec.durationSeconds,
      cooldownSeconds: 0.0,
    );
  }

  /// Aktualizuje liczniki aktywacji / odnowienia o krok czasowy [dtSeconds].
  EsportsPowerUpInventorySlot tick(double dtSeconds) {
    final dt = math.max(0.0, dtSeconds);
    if (dt == 0.0) return this;

    if (state == EsportsPowerUpSlotState.active) {
      final nextRemaining = remainingActiveSeconds - dt;
      if (nextRemaining > 0.0) {
        return copyWith(remainingActiveSeconds: nextRemaining);
      }
      return const EsportsPowerUpInventorySlot().copyWith(
        slotIndex: slotIndex,
        state: EsportsPowerUpSlotState.empty,
      );
    }

    if (state == EsportsPowerUpSlotState.cooldown) {
      final nextCooldown = cooldownSeconds - dt;
      if (nextCooldown > 0.0) {
        return copyWith(cooldownSeconds: nextCooldown);
      }
      return copyWith(
        state: powerUp != null
            ? EsportsPowerUpSlotState.ready
            : EsportsPowerUpSlotState.empty,
        cooldownSeconds: 0.0,
      );
    }

    return this;
  }

  EsportsPowerUpInventorySlot copyWith({
    int? slotIndex,
    EsportsPowerUpType? powerUp,
    bool clearPowerUp = false,
    EsportsPowerUpSlotState? state,
    double? remainingActiveSeconds,
    double? cooldownSeconds,
  }) {
    return EsportsPowerUpInventorySlot(
      slotIndex: slotIndex ?? this.slotIndex,
      powerUp: clearPowerUp ? null : (powerUp ?? this.powerUp),
      state: state ?? this.state,
      remainingActiveSeconds:
          remainingActiveSeconds ?? this.remainingActiveSeconds,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slotIndex': slotIndex,
      'powerUp': powerUp?.toJson(),
      'state': state.toJson(),
      'remainingActiveSeconds': remainingActiveSeconds,
      'cooldownSeconds': cooldownSeconds,
    };
  }

  factory EsportsPowerUpInventorySlot.fromJson(Map<String, dynamic> json) {
    final rawPowerUp = json['powerUp'] as String?;
    return EsportsPowerUpInventorySlot(
      slotIndex: (json['slotIndex'] as num?)?.toInt() ?? 0,
      powerUp:
          rawPowerUp != null ? EsportsPowerUpType.fromJson(rawPowerUp) : null,
      state: EsportsPowerUpSlotState.fromJson(json['state'] as String? ?? ''),
      remainingActiveSeconds:
          (json['remainingActiveSeconds'] as num?)?.toDouble() ?? 0.0,
      cooldownSeconds: (json['cooldownSeconds'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Segment wirtualnej trasy w świecie e-Sports.
class EsportsVirtualCourseSegment {
  final int index;
  final String name;
  final double startDistanceMeters;
  final double endDistanceMeters;
  final double gradientPercent;
  final double surfaceCrr;
  final bool isPowerUpBannerGate;
  final bool isSprintOrKomPrime;
  final bool draftingEnabled;

  const EsportsVirtualCourseSegment({
    required this.index,
    required this.name,
    required this.startDistanceMeters,
    required this.endDistanceMeters,
    required this.gradientPercent,
    this.surfaceCrr = 0.0028,
    this.isPowerUpBannerGate = false,
    this.isSprintOrKomPrime = false,
    this.draftingEnabled = true,
  });

  double get lengthMeters =>
      math.max(0.0, endDistanceMeters - startDistanceMeters);

  bool containsDistance(double distanceOnLapMeters) {
    return distanceOnLapMeters >= startDistanceMeters &&
        distanceOnLapMeters < endDistanceMeters;
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'name': name,
      'startDistanceMeters': startDistanceMeters,
      'endDistanceMeters': endDistanceMeters,
      'gradientPercent': gradientPercent,
      'surfaceCrr': surfaceCrr,
      'isPowerUpBannerGate': isPowerUpBannerGate,
      'isSprintOrKomPrime': isSprintOrKomPrime,
      'draftingEnabled': draftingEnabled,
    };
  }

  factory EsportsVirtualCourseSegment.fromJson(Map<String, dynamic> json) {
    return EsportsVirtualCourseSegment(
      index: (json['index'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Segment',
      startDistanceMeters:
          (json['startDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      endDistanceMeters:
          (json['endDistanceMeters'] as num?)?.toDouble() ?? 1000.0,
      gradientPercent: (json['gradientPercent'] as num?)?.toDouble() ?? 0.0,
      surfaceCrr: (json['surfaceCrr'] as num?)?.toDouble() ?? 0.0028,
      isPowerUpBannerGate: json['isPowerUpBannerGate'] as bool? ?? false,
      isSprintOrKomPrime: json['isSprintOrKomPrime'] as bool? ?? false,
      draftingEnabled: json['draftingEnabled'] as bool? ?? true,
    );
  }
}

/// Specyfikacja wirtualnego świata i pętli wyścigowej UCI Cycling Esports.
class EsportsVirtualWorldSpec {
  final String id;
  final String name;
  final VirtualWorldTheme theme;
  final double lapLengthMeters;
  final int totalLaps;
  final double elevationGainPerLapMeters;
  final double airDensityKgM3;
  final List<EsportsVirtualCourseSegment> segments;

  const EsportsVirtualWorldSpec({
    required this.id,
    required this.name,
    required this.theme,
    required this.lapLengthMeters,
    required this.totalLaps,
    required this.elevationGainPerLapMeters,
    this.airDensityKgM3 = 1.225,
    required this.segments,
  });

  double get totalRaceDistanceMeters => lapLengthMeters * totalLaps;

  /// Domyślna arena Mistrzostw Świata — Cyber-Welodrom & Neon City Loop.
  factory EsportsVirtualWorldSpec.cyberVelodromeArena() {
    return const EsportsVirtualWorldSpec(
      id: 'world_cyber_velodrome',
      name: 'Cyber-Welodrom & Neon Circuit',
      theme: VirtualWorldTheme.cyberVelodrome,
      lapLengthMeters: 4000.0,
      totalLaps: 6,
      elevationGainPerLapMeters: 48.0,
      airDensityKgM3: 1.205,
      segments: [
        EsportsVirtualCourseSegment(
          index: 0,
          name: 'Brama Startowa / Szklana Prosta',
          startDistanceMeters: 0.0,
          endDistanceMeters: 1000.0,
          gradientPercent: 0.2,
          isPowerUpBannerGate: true,
        ),
        EsportsVirtualCourseSegment(
          index: 1,
          name: 'Rampa Holograficzna (6.5%)',
          startDistanceMeters: 1000.0,
          endDistanceMeters: 1700.0,
          gradientPercent: 6.5,
          isSprintOrKomPrime: true,
        ),
        EsportsVirtualCourseSegment(
          index: 2,
          name: 'Zjazd Neonowy (-4.0%)',
          startDistanceMeters: 1700.0,
          endDistanceMeters: 2500.0,
          gradientPercent: -4.0,
          isPowerUpBannerGate: true,
        ),
        EsportsVirtualCourseSegment(
          index: 3,
          name: 'Finiszowa Pętla Eliminacyjna',
          startDistanceMeters: 2500.0,
          endDistanceMeters: 4000.0,
          gradientPercent: 0.8,
          isSprintOrKomPrime: true,
        ),
      ],
    );
  }

  /// Zwraca segment odpowiadający bieżącemu dystansowi wyścigu.
  EsportsVirtualCourseSegment segmentAtDistance(double totalDistanceMeters) {
    if (segments.isEmpty) {
      return const EsportsVirtualCourseSegment(
        index: 0,
        name: 'Domyślna Pętla',
        startDistanceMeters: 0.0,
        endDistanceMeters: 4000.0,
        gradientPercent: 0.0,
      );
    }
    final safeLapLength = math.max(1.0, lapLengthMeters);
    final lapDistance =
        ((totalDistanceMeters % safeLapLength) + safeLapLength) % safeLapLength;
    for (final segment in segments) {
      if (segment.containsDistance(lapDistance)) {
        return segment;
      }
    }
    return segments.last;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'theme': theme.toJson(),
      'lapLengthMeters': lapLengthMeters,
      'totalLaps': totalLaps,
      'elevationGainPerLapMeters': elevationGainPerLapMeters,
      'airDensityKgM3': airDensityKgM3,
      'segments': segments.map((s) => s.toJson()).toList(),
    };
  }

  factory EsportsVirtualWorldSpec.fromJson(Map<String, dynamic> json) {
    final rawSegments = json['segments'] as List<dynamic>? ?? const [];
    return EsportsVirtualWorldSpec(
      id: json['id'] as String? ?? 'world_cyber_velodrome',
      name: json['name'] as String? ?? 'Cyber-Welodrom & Neon Circuit',
      theme: VirtualWorldTheme.fromJson(json['theme'] as String? ?? ''),
      lapLengthMeters: (json['lapLengthMeters'] as num?)?.toDouble() ?? 4000.0,
      totalLaps: (json['totalLaps'] as num?)?.toInt() ?? 6,
      elevationGainPerLapMeters:
          (json['elevationGainPerLapMeters'] as num?)?.toDouble() ?? 48.0,
      airDensityKgM3: (json['airDensityKgM3'] as num?)?.toDouble() ?? 1.205,
      segments: rawSegments
          .whereType<Map<String, dynamic>>()
          .map(EsportsVirtualCourseSegment.fromJson)
          .toList(),
    );
  }
}

/// Stan pojedynczego zawodnika w wyścigu UCI Cycling Esports.
class EsportsRiderLiveState {
  final String riderId;
  final String riderName;
  final String teamCode;
  final double weightKg;
  final double ftpWatts;
  final double currentPowerWatts;
  final int heartRateBpm;
  final int cadenceRpm;
  final double speedKmh;
  final double distanceMeters;
  final int lap;
  final int rank;
  final double gapToLeaderSeconds;
  final double wPrimeRemainingJoules;
  final double wPrimeMaxJoules;
  final SmartTrainerHardwareSpec trainerSpec;
  final EsportsPowerUpInventorySlot powerUpSlot;
  final EsportsAvatarVerdict verdict;
  final int? eliminatedAtSecond;
  final int? eliminatedRound;
  final int pointsAccumulated;
  final double dualRecordingDeltaPercent;

  const EsportsRiderLiveState({
    required this.riderId,
    required this.riderName,
    required this.teamCode,
    required this.weightKg,
    required this.ftpWatts,
    this.currentPowerWatts = 0.0,
    this.heartRateBpm = 145,
    this.cadenceRpm = 92,
    this.speedKmh = 42.0,
    this.distanceMeters = 0.0,
    this.lap = 1,
    this.rank = 1,
    this.gapToLeaderSeconds = 0.0,
    this.wPrimeRemainingJoules = 20000.0,
    this.wPrimeMaxJoules = 20000.0,
    required this.trainerSpec,
    this.powerUpSlot = const EsportsPowerUpInventorySlot(),
    this.verdict = EsportsAvatarVerdict.active,
    this.eliminatedAtSecond,
    this.eliminatedRound,
    this.pointsAccumulated = 0,
    this.dualRecordingDeltaPercent = 0.6,
  });

  /// Bieżący stosunek mocy do masy [W/kg].
  double get currentWkg =>
      weightKg > 0.0 ? currentPowerWatts / weightKg : 0.0;

  /// Czy kolarz pozostaje w wyścigu.
  bool get isActiveInRace => verdict == EsportsAvatarVerdict.active;

  /// Czy kolarz odpadł w wyścigu eliminacyjnym.
  bool get isEliminated => verdict == EsportsAvatarVerdict.eliminated;

  /// Aktualnie odpalony Power-Up (jeśli aktywny).
  EsportsPowerUpType? get activePowerUpType =>
      powerUpSlot.state == EsportsPowerUpSlotState.active
          ? powerUpSlot.powerUp
          : null;

  /// Frakcja pozostałej baterii beztlenowej W' [0.0 – 1.0].
  double get wPrimeFraction => wPrimeMaxJoules > 0.0
      ? (wPrimeRemainingJoules / wPrimeMaxJoules).clamp(0.0, 1.0)
      : 0.0;

  EsportsRiderLiveState copyWith({
    String? riderId,
    String? riderName,
    String? teamCode,
    double? weightKg,
    double? ftpWatts,
    double? currentPowerWatts,
    int? heartRateBpm,
    int? cadenceRpm,
    double? speedKmh,
    double? distanceMeters,
    int? lap,
    int? rank,
    double? gapToLeaderSeconds,
    double? wPrimeRemainingJoules,
    double? wPrimeMaxJoules,
    SmartTrainerHardwareSpec? trainerSpec,
    EsportsPowerUpInventorySlot? powerUpSlot,
    EsportsAvatarVerdict? verdict,
    int? eliminatedAtSecond,
    int? eliminatedRound,
    int? pointsAccumulated,
    double? dualRecordingDeltaPercent,
  }) {
    return EsportsRiderLiveState(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      teamCode: teamCode ?? this.teamCode,
      weightKg: weightKg ?? this.weightKg,
      ftpWatts: ftpWatts ?? this.ftpWatts,
      currentPowerWatts: currentPowerWatts ?? this.currentPowerWatts,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      cadenceRpm: cadenceRpm ?? this.cadenceRpm,
      speedKmh: speedKmh ?? this.speedKmh,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      lap: lap ?? this.lap,
      rank: rank ?? this.rank,
      gapToLeaderSeconds: gapToLeaderSeconds ?? this.gapToLeaderSeconds,
      wPrimeRemainingJoules:
          wPrimeRemainingJoules ?? this.wPrimeRemainingJoules,
      wPrimeMaxJoules: wPrimeMaxJoules ?? this.wPrimeMaxJoules,
      trainerSpec: trainerSpec ?? this.trainerSpec,
      powerUpSlot: powerUpSlot ?? this.powerUpSlot,
      verdict: verdict ?? this.verdict,
      eliminatedAtSecond: eliminatedAtSecond ?? this.eliminatedAtSecond,
      eliminatedRound: eliminatedRound ?? this.eliminatedRound,
      pointsAccumulated: pointsAccumulated ?? this.pointsAccumulated,
      dualRecordingDeltaPercent:
          dualRecordingDeltaPercent ?? this.dualRecordingDeltaPercent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'teamCode': teamCode,
      'weightKg': weightKg,
      'ftpWatts': ftpWatts,
      'currentPowerWatts': currentPowerWatts,
      'heartRateBpm': heartRateBpm,
      'cadenceRpm': cadenceRpm,
      'speedKmh': speedKmh,
      'distanceMeters': distanceMeters,
      'lap': lap,
      'rank': rank,
      'gapToLeaderSeconds': gapToLeaderSeconds,
      'wPrimeRemainingJoules': wPrimeRemainingJoules,
      'wPrimeMaxJoules': wPrimeMaxJoules,
      'trainerSpec': trainerSpec.toJson(),
      'powerUpSlot': powerUpSlot.toJson(),
      'verdict': verdict.toJson(),
      'eliminatedAtSecond': eliminatedAtSecond,
      'eliminatedRound': eliminatedRound,
      'pointsAccumulated': pointsAccumulated,
      'dualRecordingDeltaPercent': dualRecordingDeltaPercent,
    };
  }

  factory EsportsRiderLiveState.fromJson(Map<String, dynamic> json) {
    return EsportsRiderLiveState(
      riderId: json['riderId'] as String? ?? 'rider_unknown',
      riderName: json['riderName'] as String? ?? 'Nieznany Kolarz',
      teamCode: json['teamCode'] as String? ?? 'ESP',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 68.0,
      ftpWatts: (json['ftpWatts'] as num?)?.toDouble() ?? 380.0,
      currentPowerWatts:
          (json['currentPowerWatts'] as num?)?.toDouble() ?? 0.0,
      heartRateBpm: (json['heartRateBpm'] as num?)?.toInt() ?? 145,
      cadenceRpm: (json['cadenceRpm'] as num?)?.toInt() ?? 92,
      speedKmh: (json['speedKmh'] as num?)?.toDouble() ?? 42.0,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      lap: (json['lap'] as num?)?.toInt() ?? 1,
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      gapToLeaderSeconds:
          (json['gapToLeaderSeconds'] as num?)?.toDouble() ?? 0.0,
      wPrimeRemainingJoules:
          (json['wPrimeRemainingJoules'] as num?)?.toDouble() ?? 20000.0,
      wPrimeMaxJoules:
          (json['wPrimeMaxJoules'] as num?)?.toDouble() ?? 20000.0,
      trainerSpec: json['trainerSpec'] is Map<String, dynamic>
          ? SmartTrainerHardwareSpec.fromJson(
              json['trainerSpec'] as Map<String, dynamic>,
            )
          : SmartTrainerHardwareSpec.proDirectDrive(),
      powerUpSlot: json['powerUpSlot'] is Map<String, dynamic>
          ? EsportsPowerUpInventorySlot.fromJson(
              json['powerUpSlot'] as Map<String, dynamic>,
            )
          : const EsportsPowerUpInventorySlot(),
      verdict: EsportsAvatarVerdict.fromJson(json['verdict'] as String? ?? ''),
      eliminatedAtSecond: (json['eliminatedAtSecond'] as num?)?.toInt(),
      eliminatedRound: (json['eliminatedRound'] as num?)?.toInt(),
      pointsAccumulated: (json['pointsAccumulated'] as num?)?.toInt() ?? 0,
      dualRecordingDeltaPercent:
          (json['dualRecordingDeltaPercent'] as num?)?.toDouble() ?? 0.6,
    );
  }
}

/// Zapis pojedynczej eliminacji w cyklu co 60 sekund.
class EliminationRoundRecord {
  final int roundNumber;
  final int triggerTimeSeconds;
  final String eliminatedRiderId;
  final String eliminatedRiderName;
  final double eliminatedWkg;
  final int remainingRidersCount;
  final double photoFinishGapSeconds;

  const EliminationRoundRecord({
    required this.roundNumber,
    required this.triggerTimeSeconds,
    required this.eliminatedRiderId,
    required this.eliminatedRiderName,
    required this.eliminatedWkg,
    required this.remainingRidersCount,
    this.photoFinishGapSeconds = 0.04,
  });

  Map<String, dynamic> toJson() {
    return {
      'roundNumber': roundNumber,
      'triggerTimeSeconds': triggerTimeSeconds,
      'eliminatedRiderId': eliminatedRiderId,
      'eliminatedRiderName': eliminatedRiderName,
      'eliminatedWkg': eliminatedWkg,
      'remainingRidersCount': remainingRidersCount,
      'photoFinishGapSeconds': photoFinishGapSeconds,
    };
  }

  factory EliminationRoundRecord.fromJson(Map<String, dynamic> json) {
    return EliminationRoundRecord(
      roundNumber: (json['roundNumber'] as num?)?.toInt() ?? 1,
      triggerTimeSeconds: (json['triggerTimeSeconds'] as num?)?.toInt() ?? 60,
      eliminatedRiderId: json['eliminatedRiderId'] as String? ?? '',
      eliminatedRiderName: json['eliminatedRiderName'] as String? ?? '',
      eliminatedWkg: (json['eliminatedWkg'] as num?)?.toDouble() ?? 0.0,
      remainingRidersCount:
          (json['remainingRidersCount'] as num?)?.toInt() ?? 0,
      photoFinishGapSeconds:
          (json['photoFinishGapSeconds'] as num?)?.toDouble() ?? 0.04,
    );
  }
}

/// Harmonogram i stan wyścigu eliminacyjnego co 60 sekund.
class Elimination60sScheduleState {
  static const int defaultIntervalSeconds = 60;

  final int intervalSeconds;
  final int currentRound;
  final int elapsedSeconds;
  final int warningThresholdSeconds;
  final String? lastEliminatedRiderId;
  final List<EliminationRoundRecord> eliminationHistory;

  const Elimination60sScheduleState({
    this.intervalSeconds = defaultIntervalSeconds,
    this.currentRound = 1,
    this.elapsedSeconds = 0,
    this.warningThresholdSeconds = 10,
    this.lastEliminatedRiderId,
    this.eliminationHistory = const [],
  });

  /// Czas kolejnego odcięcia ostatniego kolarza [s].
  int get nextTriggerSecond => currentRound * math.max(1, intervalSeconds);

  /// Ile sekund pozostało do najbliższej eliminacji.
  int get secondsUntilNextElimination =>
      math.max(0, nextTriggerSecond - elapsedSeconds);

  /// Czy wyścig wszedł w ostatnie 10 s przed eliminacją (alarm HUD).
  bool get isInFinalTenSecondsWarning =>
      secondsUntilNextElimination <= warningThresholdSeconds &&
      secondsUntilNextElimination > 0;

  /// Postęp bieżącej 60-sekundowej rundy [0.0 – 1.0].
  double get progressFraction {
    final safeInterval = math.max(1, intervalSeconds);
    final elapsedInRound = safeInterval - secondsUntilNextElimination;
    return (elapsedInRound / safeInterval).clamp(0.0, 1.0);
  }

  /// Rejestruje eliminację ostatniego zawodnika i przechodzi do kolejnej rundy.
  Elimination60sScheduleState recordElimination({
    required EsportsRiderLiveState eliminatedRider,
    required int remainingCount,
    double photoFinishGapSeconds = 0.05,
  }) {
    final record = EliminationRoundRecord(
      roundNumber: currentRound,
      triggerTimeSeconds: elapsedSeconds,
      eliminatedRiderId: eliminatedRider.riderId,
      eliminatedRiderName: eliminatedRider.riderName,
      eliminatedWkg: eliminatedRider.currentWkg,
      remainingRidersCount: remainingCount,
      photoFinishGapSeconds: photoFinishGapSeconds,
    );
    return copyWith(
      currentRound: currentRound + 1,
      lastEliminatedRiderId: eliminatedRider.riderId,
      eliminationHistory: [...eliminationHistory, record],
    );
  }

  Elimination60sScheduleState copyWith({
    int? intervalSeconds,
    int? currentRound,
    int? elapsedSeconds,
    int? warningThresholdSeconds,
    String? lastEliminatedRiderId,
    List<EliminationRoundRecord>? eliminationHistory,
  }) {
    return Elimination60sScheduleState(
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
      currentRound: currentRound ?? this.currentRound,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      warningThresholdSeconds:
          warningThresholdSeconds ?? this.warningThresholdSeconds,
      lastEliminatedRiderId:
          lastEliminatedRiderId ?? this.lastEliminatedRiderId,
      eliminationHistory: eliminationHistory ?? this.eliminationHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intervalSeconds': intervalSeconds,
      'currentRound': currentRound,
      'elapsedSeconds': elapsedSeconds,
      'warningThresholdSeconds': warningThresholdSeconds,
      'lastEliminatedRiderId': lastEliminatedRiderId,
      'eliminationHistory':
          eliminationHistory.map((e) => e.toJson()).toList(),
    };
  }

  factory Elimination60sScheduleState.fromJson(Map<String, dynamic> json) {
    final rawHistory =
        json['eliminationHistory'] as List<dynamic>? ?? const [];
    return Elimination60sScheduleState(
      intervalSeconds: (json['intervalSeconds'] as num?)?.toInt() ?? 60,
      currentRound: (json['currentRound'] as num?)?.toInt() ?? 1,
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
      warningThresholdSeconds:
          (json['warningThresholdSeconds'] as num?)?.toInt() ?? 10,
      lastEliminatedRiderId: json['lastEliminatedRiderId'] as String?,
      eliminationHistory: rawHistory
          .whereType<Map<String, dynamic>>()
          .map(EliminationRoundRecord.fromJson)
          .toList(),
    );
  }
}

/// Kandydat z programu naboru talentów Virtual Talent ID Academy.
class VirtualTalentIdCandidate {
  final String id;
  final String athleteName;
  final String nationalityCode;
  final int age;
  final double weightKg;
  final double verifiedFtpWatts;
  final double verifiedFiveMinWkg;
  final int peakSprintWatts;
  final int esportsElo;
  final int dualRecordingScore;
  final bool isSignedToDevelopmentSquad;

  const VirtualTalentIdCandidate({
    required this.id,
    required this.athleteName,
    required this.nationalityCode,
    required this.age,
    required this.weightKg,
    required this.verifiedFtpWatts,
    required this.verifiedFiveMinWkg,
    required this.peakSprintWatts,
    required this.esportsElo,
    this.dualRecordingScore = 96,
    this.isSignedToDevelopmentSquad = false,
  });

  double get ftpWkg => weightKg > 0.0 ? verifiedFtpWatts / weightKg : 0.0;

  VirtualTalentIdCandidate copyWith({
    bool? isSignedToDevelopmentSquad,
    int? esportsElo,
    int? dualRecordingScore,
  }) {
    return VirtualTalentIdCandidate(
      id: id,
      athleteName: athleteName,
      nationalityCode: nationalityCode,
      age: age,
      weightKg: weightKg,
      verifiedFtpWatts: verifiedFtpWatts,
      verifiedFiveMinWkg: verifiedFiveMinWkg,
      peakSprintWatts: peakSprintWatts,
      esportsElo: esportsElo ?? this.esportsElo,
      dualRecordingScore: dualRecordingScore ?? this.dualRecordingScore,
      isSignedToDevelopmentSquad:
          isSignedToDevelopmentSquad ?? this.isSignedToDevelopmentSquad,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'athleteName': athleteName,
      'nationalityCode': nationalityCode,
      'age': age,
      'weightKg': weightKg,
      'verifiedFtpWatts': verifiedFtpWatts,
      'verifiedFiveMinWkg': verifiedFiveMinWkg,
      'peakSprintWatts': peakSprintWatts,
      'esportsElo': esportsElo,
      'dualRecordingScore': dualRecordingScore,
      'isSignedToDevelopmentSquad': isSignedToDevelopmentSquad,
    };
  }

  factory VirtualTalentIdCandidate.fromJson(Map<String, dynamic> json) {
    return VirtualTalentIdCandidate(
      id: json['id'] as String? ?? 'talent_1',
      athleteName: json['athleteName'] as String? ?? 'Kandydat Academy',
      nationalityCode: json['nationalityCode'] as String? ?? 'POL',
      age: (json['age'] as num?)?.toInt() ?? 19,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 66.0,
      verifiedFtpWatts: (json['verifiedFtpWatts'] as num?)?.toDouble() ?? 390.0,
      verifiedFiveMinWkg:
          (json['verifiedFiveMinWkg'] as num?)?.toDouble() ?? 6.8,
      peakSprintWatts: (json['peakSprintWatts'] as num?)?.toInt() ?? 1380,
      esportsElo: (json['esportsElo'] as num?)?.toInt() ?? 1850,
      dualRecordingScore: (json['dualRecordingScore'] as num?)?.toInt() ?? 96,
      isSignedToDevelopmentSquad:
          json['isSignedToDevelopmentSquad'] as bool? ?? false,
    );
  }
}

/// Główny model świata UCI Cycling Esports: trenażery Smart, Power-Upy i eliminacja co 60 s.
class UciCyclingEsportsWorldModel {
  final String eventId;
  final String eventName;
  final EsportsPlatformTier platformTier;
  final EsportsRaceFormat raceFormat;
  final EsportsVirtualWorldSpec worldSpec;
  final Elimination60sScheduleState eliminationSchedule;
  final List<EsportsRiderLiveState> riders;
  final List<VirtualTalentIdCandidate> talentIdPool;
  final double uciDualRecordingMaxDeltaPercent;
  final int uciMinWeighInHoursBeforeStart;
  final bool isUciSanctioned;
  final double prizePoolEur;

  const UciCyclingEsportsWorldModel({
    required this.eventId,
    required this.eventName,
    required this.platformTier,
    required this.raceFormat,
    required this.worldSpec,
    required this.eliminationSchedule,
    required this.riders,
    this.talentIdPool = const [],
    this.uciDualRecordingMaxDeltaPercent = 2.5,
    this.uciMinWeighInHoursBeforeStart = 24,
    this.isUciSanctioned = true,
    this.prizePoolEur = 50000.0,
  });

  /// Tworzy gotowy scenariusz Mistrzostw Świata UCI Cycling Esports (eliminacja co 60 s).
  factory UciCyclingEsportsWorldModel.uciWorldChampionshipElimination() {
    final world = EsportsVirtualWorldSpec.cyberVelodromeArena();
    final proTrainer = SmartTrainerHardwareSpec.proDirectDrive();
    final smartBike = SmartTrainerHardwareSpec.smartBike();

    return UciCyclingEsportsWorldModel(
      eventId: 'uci_esports_wc_elimination',
      eventName: 'UCI Cycling Esports World Championships — Elimination',
      platformTier: EsportsPlatformTier.uciWorldChampionships,
      raceFormat: EsportsRaceFormat.eliminationEvery60s,
      worldSpec: world,
      eliminationSchedule: const Elimination60sScheduleState(
        intervalSeconds: 60,
        currentRound: 1,
        elapsedSeconds: 0,
      ),
      riders: [
        EsportsRiderLiveState(
          riderId: 'esp_r1',
          riderName: 'Kacper Majewski',
          teamCode: 'POL',
          weightKg: 66.5,
          ftpWatts: 415.0,
          currentPowerWatts: 430.0,
          speedKmh: 46.8,
          distanceMeters: 1200.0,
          rank: 1,
          trainerSpec: smartBike,
          powerUpSlot: const EsportsPowerUpInventorySlot(
            powerUp: EsportsPowerUpType.aeroHelmet,
            state: EsportsPowerUpSlotState.ready,
          ),
        ),
        EsportsRiderLiveState(
          riderId: 'esp_r2',
          riderName: 'Jason Osborne',
          teamCode: 'GER',
          weightKg: 65.0,
          ftpWatts: 410.0,
          currentPowerWatts: 422.0,
          speedKmh: 46.5,
          distanceMeters: 1192.0,
          rank: 2,
          gapToLeaderSeconds: 0.6,
          trainerSpec: proTrainer,
          powerUpSlot: const EsportsPowerUpInventorySlot(
            powerUp: EsportsPowerUpType.featherweight,
            state: EsportsPowerUpSlotState.ready,
          ),
        ),
        EsportsRiderLiveState(
          riderId: 'esp_r3',
          riderName: 'Björn Andreassen',
          teamCode: 'DEN',
          weightKg: 71.0,
          ftpWatts: 435.0,
          currentPowerWatts: 428.0,
          speedKmh: 46.2,
          distanceMeters: 1184.0,
          rank: 3,
          gapToLeaderSeconds: 1.2,
          trainerSpec: proTrainer,
          powerUpSlot: const EsportsPowerUpInventorySlot(
            powerUp: EsportsPowerUpType.burrito,
            state: EsportsPowerUpSlotState.ready,
          ),
        ),
        EsportsRiderLiveState(
          riderId: 'esp_r4',
          riderName: 'Freddy Ovett',
          teamCode: 'AUS',
          weightKg: 69.5,
          ftpWatts: 405.0,
          currentPowerWatts: 398.0,
          speedKmh: 45.4,
          distanceMeters: 1170.0,
          rank: 4,
          gapToLeaderSeconds: 2.3,
          trainerSpec: proTrainer,
          powerUpSlot: const EsportsPowerUpInventorySlot(
            powerUp: EsportsPowerUpType.aeroHelmet,
            state: EsportsPowerUpSlotState.ready,
          ),
        ),
      ],
      talentIdPool: const [
        VirtualTalentIdCandidate(
          id: 'vt_id_1',
          athleteName: 'Mikołaj Zieliński',
          nationalityCode: 'POL',
          age: 19,
          weightKg: 64.2,
          verifiedFtpWatts: 402.0,
          verifiedFiveMinWkg: 7.15,
          peakSprintWatts: 1320,
          esportsElo: 2140,
          dualRecordingScore: 99,
        ),
        VirtualTalentIdCandidate(
          id: 'vt_id_2',
          athleteName: 'Lukas Lindholm',
          nationalityCode: 'SWE',
          age: 20,
          weightKg: 70.4,
          verifiedFtpWatts: 428.0,
          verifiedFiveMinWkg: 6.88,
          peakSprintWatts: 1490,
          esportsElo: 2085,
          dualRecordingScore: 97,
        ),
      ],
    );
  }

  /// Aktywni zawodnicy w grze, posortowani malejąco po przejechanym dystansie.
  List<EsportsRiderLiveState> get activeRiders {
    final active = riders.where((r) => r.isActiveInRace).toList();
    active.sort((a, b) => b.distanceMeters.compareTo(a.distanceMeters));
    return active;
  }

  /// Zawodnicy wyeliminowani lub zdyskwalifikowani.
  List<EsportsRiderLiveState> get eliminatedRiders {
    return riders
        .where(
          (r) =>
              r.verdict == EsportsAvatarVerdict.eliminated ||
              r.verdict == EsportsAvatarVerdict.disqualifiedDualRecording,
        )
        .toList();
  }

  /// Ostatni aktywny kolarz w klasyfikacji — kandydat do eliminacji w bieżącej rundzie.
  EsportsRiderLiveState? get atRiskEliminationRider {
    if (raceFormat != EsportsRaceFormat.eliminationEvery60s) return null;
    final active = activeRiders;
    if (active.length <= 1) return null;
    return active.last;
  }

  /// Weryfikuje zgodność podwójnego pomiaru mocy (Dual-Recording) i sprzętu z przepisami UCI.
  bool checkDualRecordingCompliance(EsportsRiderLiveState rider) {
    if (!isUciSanctioned) return true;
    return rider.trainerSpec.isUciCompliant &&
        rider.dualRecordingDeltaPercent.abs() <= uciDualRecordingMaxDeltaPercent;
  }

  UciCyclingEsportsWorldModel copyWith({
    String? eventId,
    String? eventName,
    EsportsPlatformTier? platformTier,
    EsportsRaceFormat? raceFormat,
    EsportsVirtualWorldSpec? worldSpec,
    Elimination60sScheduleState? eliminationSchedule,
    List<EsportsRiderLiveState>? riders,
    List<VirtualTalentIdCandidate>? talentIdPool,
    double? uciDualRecordingMaxDeltaPercent,
    int? uciMinWeighInHoursBeforeStart,
    bool? isUciSanctioned,
    double? prizePoolEur,
  }) {
    return UciCyclingEsportsWorldModel(
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      platformTier: platformTier ?? this.platformTier,
      raceFormat: raceFormat ?? this.raceFormat,
      worldSpec: worldSpec ?? this.worldSpec,
      eliminationSchedule: eliminationSchedule ?? this.eliminationSchedule,
      riders: riders ?? this.riders,
      talentIdPool: talentIdPool ?? this.talentIdPool,
      uciDualRecordingMaxDeltaPercent: uciDualRecordingMaxDeltaPercent ??
          this.uciDualRecordingMaxDeltaPercent,
      uciMinWeighInHoursBeforeStart:
          uciMinWeighInHoursBeforeStart ?? this.uciMinWeighInHoursBeforeStart,
      isUciSanctioned: isUciSanctioned ?? this.isUciSanctioned,
      prizePoolEur: prizePoolEur ?? this.prizePoolEur,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventName': eventName,
      'platformTier': platformTier.toJson(),
      'raceFormat': raceFormat.toJson(),
      'worldSpec': worldSpec.toJson(),
      'eliminationSchedule': eliminationSchedule.toJson(),
      'riders': riders.map((r) => r.toJson()).toList(),
      'talentIdPool': talentIdPool.map((t) => t.toJson()).toList(),
      'uciDualRecordingMaxDeltaPercent': uciDualRecordingMaxDeltaPercent,
      'uciMinWeighInHoursBeforeStart': uciMinWeighInHoursBeforeStart,
      'isUciSanctioned': isUciSanctioned,
      'prizePoolEur': prizePoolEur,
    };
  }

  factory UciCyclingEsportsWorldModel.fromJson(Map<String, dynamic> json) {
    final rawRiders = json['riders'] as List<dynamic>? ?? const [];
    final rawTalents = json['talentIdPool'] as List<dynamic>? ?? const [];

    return UciCyclingEsportsWorldModel(
      eventId: json['eventId'] as String? ?? 'uci_esports_wc_elimination',
      eventName: json['eventName'] as String? ??
          'UCI Cycling Esports World Championships',
      platformTier:
          EsportsPlatformTier.fromJson(json['platformTier'] as String? ?? ''),
      raceFormat:
          EsportsRaceFormat.fromJson(json['raceFormat'] as String? ?? ''),
      worldSpec: json['worldSpec'] is Map<String, dynamic>
          ? EsportsVirtualWorldSpec.fromJson(
              json['worldSpec'] as Map<String, dynamic>,
            )
          : EsportsVirtualWorldSpec.cyberVelodromeArena(),
      eliminationSchedule:
          json['eliminationSchedule'] is Map<String, dynamic>
              ? Elimination60sScheduleState.fromJson(
                  json['eliminationSchedule'] as Map<String, dynamic>,
                )
              : const Elimination60sScheduleState(),
      riders: rawRiders
          .whereType<Map<String, dynamic>>()
          .map(EsportsRiderLiveState.fromJson)
          .toList(),
      talentIdPool: rawTalents
          .whereType<Map<String, dynamic>>()
          .map(VirtualTalentIdCandidate.fromJson)
          .toList(),
      uciDualRecordingMaxDeltaPercent:
          (json['uciDualRecordingMaxDeltaPercent'] as num?)?.toDouble() ?? 2.5,
      uciMinWeighInHoursBeforeStart:
          (json['uciMinWeighInHoursBeforeStart'] as num?)?.toInt() ?? 24,
      isUciSanctioned: json['isUciSanctioned'] as bool? ?? true,
      prizePoolEur: (json['prizePoolEur'] as num?)?.toDouble() ?? 50000.0,
    );
  }
}
