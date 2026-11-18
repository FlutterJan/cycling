import 'dart:math' as math;

/// Okno czasowe przeprowadzenia kontroli technicznej UCI.
enum ScrutinyTimingWindow {
  preStartPaddock,
  preStartIttRamp,
  postFinishLine,
  randomMidStageZone,
  surpriseHotelRaid;

  String toJson() => name;

  static ScrutinyTimingWindow fromJson(String value) {
    return ScrutinyTimingWindow.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ScrutinyTimingWindow.preStartPaddock,
    );
  }

  String get displayNamePl {
    switch (this) {
      case ScrutinyTimingWindow.preStartPaddock:
        return 'Kontrola przedstartowa w padoku';
      case ScrutinyTimingWindow.preStartIttRamp:
        return 'Kontrola na 3 min przed rampą startową ITT';
      case ScrutinyTimingWindow.postFinishLine:
        return 'Kontrola na mecie etapu';
      case ScrutinyTimingWindow.randomMidStageZone:
        return 'Losowa kontrola po zmianie roweru na trasie';
      case ScrutinyTimingWindow.surpriseHotelRaid:
        return 'Niezapowiedziana inspekcja w hotelu drużyny';
    }
  }
}

/// Tryb wytypowania roweru i kolarza do inspekcji technicznej UCI.
enum ScrutinySelectionMode {
  randomLottery,
  targetedGcLeader,
  targetedStageWinner,
  targetedSuspectedAero,
  whistleblowerTip;

  String toJson() => name;

  static ScrutinySelectionMode fromJson(String value) {
    return ScrutinySelectionMode.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ScrutinySelectionMode.randomLottery,
    );
  }

  String get displayNamePl {
    switch (this) {
      case ScrutinySelectionMode.randomLottery:
        return 'Losowanie komisarza technicznego';
      case ScrutinySelectionMode.targetedGcLeader:
        return 'Celowana kontrola lidera klasyfikacji (GC)';
      case ScrutinySelectionMode.targetedStageWinner:
        return 'Obowiązkowa kontrola zwycięzcy etapu';
      case ScrutinySelectionMode.targetedSuspectedAero:
        return 'Celowana kontrola podejrzanej konfiguracji aero';
      case ScrutinySelectionMode.whistleblowerTip:
        return 'Kontrola po zgłoszeniu rywala / sygnalisty';
    }
  }
}

/// Urządzenie pomiarowe lub skaner użyty przez komisarza UCI.
enum ScrutinyDeviceType {
  magneticInductionTablet,
  mobileXrayScanner,
  uciFrameJigTemplate,
  sockHeightCaliper,
  leverAngleInclinometer,
  calibratedScale;

  String toJson() => name;

  static ScrutinyDeviceType fromJson(String value) {
    return ScrutinyDeviceType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ScrutinyDeviceType.magneticInductionTablet,
    );
  }

  String get displayNamePl {
    switch (this) {
      case ScrutinyDeviceType.magneticInductionTablet:
        return 'Tablet magnetyczno-indukcyjny UCI';
      case ScrutinyDeviceType.mobileXrayScanner:
        return 'Mobilny skaner rentgenowski X-Ray';
      case ScrutinyDeviceType.uciFrameJigTemplate:
        return 'Szablon wymiarów ramy UCI';
      case ScrutinyDeviceType.sockHeightCaliper:
        return 'Przymiar wysokości skarpetek (<= 50% goleni)';
      case ScrutinyDeviceType.leverAngleInclinometer:
        return 'Inklinometr kąta klamek (<= 10°)';
      case ScrutinyDeviceType.calibratedScale:
        return 'Waga wzorcowana UCI (min. 6.80 kg)';
    }
  }
}

/// Strefa roweru lub ekwipunku poddana inspekcji technicznej.
enum EquipmentInspectionZone {
  bottomBracketShell,
  seatTubeAndBattery,
  rearHubMotorCheck,
  handlebarBrakeLevers,
  ttExtensionLength,
  sockAndOvershoeHeight,
  frameTubeDimensions3to1,
  minimumBikeWeight68Kg;

  String toJson() => name;

  static EquipmentInspectionZone fromJson(String value) {
    return EquipmentInspectionZone.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EquipmentInspectionZone.bottomBracketShell,
    );
  }

  String get displayNamePl {
    switch (this) {
      case EquipmentInspectionZone.bottomBracketShell:
        return 'Mufa suportowa (detekcja mikrosilników)';
      case EquipmentInspectionZone.seatTubeAndBattery:
        return 'Rura podsiodłowa i sztyca (ukryte ogniwa)';
      case EquipmentInspectionZone.rearHubMotorCheck:
        return 'Tylna piasta i napęd (skan X-Ray)';
      case EquipmentInspectionZone.handlebarBrakeLevers:
        return 'Kąt pochylenia klamek kierownicy (<= 10°)';
      case EquipmentInspectionZone.ttExtensionLength:
        return 'Długość przedłużek lemondki TT';
      case EquipmentInspectionZone.sockAndOvershoeHeight:
        return 'Wysokość skarpetek / ochraniaczy (<= 50% goleni)';
      case EquipmentInspectionZone.frameTubeDimensions3to1:
        return 'Wymiary przekrojów ramy na szablonie UCI';
      case EquipmentInspectionZone.minimumBikeWeight68Kg:
        return 'Minimalna waga roweru (6.80 kg)';
    }
  }
}

/// Poziom wykrytej niezgodności w danej strefie.
enum ScrutinyFindingSeverity {
  compliant,
  minorTechnicalWarning,
  mandatory3MinRampCorrection,
  equipmentConfiscationAndDsq,
  technologicalFraudBan;

  String toJson() => name;

  static ScrutinyFindingSeverity fromJson(String value) {
    return ScrutinyFindingSeverity.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ScrutinyFindingSeverity.compliant,
    );
  }

  String get displayNamePl {
    switch (this) {
      case ScrutinyFindingSeverity.compliant:
        return 'Zgodny z regulaminem UCI';
      case ScrutinyFindingSeverity.minorTechnicalWarning:
        return 'Drobne uchybienie (ostrzeżenie techniczne)';
      case ScrutinyFindingSeverity.mandatory3MinRampCorrection:
        return 'Wymagana natychmiastowa korekta kluczem przed startem';
      case ScrutinyFindingSeverity.equipmentConfiscationAndDsq:
        return 'Konfiskata sprzętu i dyskwalifikacja (DSQ)';
      case ScrutinyFindingSeverity.technologicalFraudBan:
        return 'Oszustwo technologiczne (zawieszenie i przekazanie do CAS)';
    }
  }
}

/// Końcowy werdykt inspekcji technicznej dla kolarza.
enum ScrutinySessionOutcome {
  passedClean,
  passedAfterTorqueCorrection,
  relegatedOrTimePenalty,
  disqualifiedDsq,
  impoundedForLabXray;

  String toJson() => name;

  static ScrutinySessionOutcome fromJson(String value) {
    return ScrutinySessionOutcome.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ScrutinySessionOutcome.passedClean,
    );
  }

  String get displayNamePl {
    switch (this) {
      case ScrutinySessionOutcome.passedClean:
        return 'Pozytywna weryfikacja (brak zastrzeżeń)';
      case ScrutinySessionOutcome.passedAfterTorqueCorrection:
        return 'Dopuszczony po awaryjnej korekcie na starcie';
      case ScrutinySessionOutcome.relegatedOrTimePenalty:
        return 'Kara czasowa / grzywna techniczna';
      case ScrutinySessionOutcome.disqualifiedDsq:
        return 'Dyskwalifikacja z etapu / wyścigu (DSQ)';
      case ScrutinySessionOutcome.impoundedForLabXray:
        return 'Rower zabezpieczony do szczegółowej analizy X-Ray';
    }
  }
}

/// Podstawa prawna odwołania zespołu do Trybunału Arbitrażowego ds. Sportu (CAS w Lozannie).
enum CasAppealGround {
  proceduralErrorByCommissaire,
  sensorCalibrationDispute,
  aeroRuleAmbiguity,
  forceMajeureMechanicalShift,
  chainOfCustodyBreach;

  String toJson() => name;

  static CasAppealGround fromJson(String value) {
    return CasAppealGround.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CasAppealGround.proceduralErrorByCommissaire,
    );
  }

  String get displayNamePl {
    switch (this) {
      case CasAppealGround.proceduralErrorByCommissaire:
        return 'Błąd proceduralny komisarza technicznego UCI';
      case CasAppealGround.sensorCalibrationDispute:
        return 'Błędna kalibracja skanera X-Ray lub inklinometru';
      case CasAppealGround.aeroRuleAmbiguity:
        return 'Niejednoznaczna interpretacja przepisu aero w regulaminie';
      case CasAppealGround.forceMajeureMechanicalShift:
        return 'Przesunięcie klamki wskutek kraksy / siły wyższej na trasie';
      case CasAppealGround.chainOfCustodyBreach:
        return 'Naruszenie łańcucha dowodowego przy zabezpieczeniu roweru';
    }
  }

  /// Bazowy modyfikator szans powodzenia odwołania przed CAS (0.0–1.0).
  double get baseWinProbability {
    switch (this) {
      case CasAppealGround.proceduralErrorByCommissaire:
        return 0.44;
      case CasAppealGround.sensorCalibrationDispute:
        return 0.38;
      case CasAppealGround.aeroRuleAmbiguity:
        return 0.32;
      case CasAppealGround.forceMajeureMechanicalShift:
        return 0.48;
      case CasAppealGround.chainOfCustodyBreach:
        return 0.52;
    }
  }
}

/// Aktualny status postępowania przed Trybunałem CAS w Lozannie.
enum CasTribunalStatus {
  notFiled,
  filedPendingPreliminary,
  expeditedProvisionalStayGranted,
  hearingScheduledLausanne,
  verdictUpheldDsq,
  verdictOverturnedReinstated,
  verdictReducedToFine;

  String toJson() => name;

  static CasTribunalStatus fromJson(String value) {
    return CasTribunalStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CasTribunalStatus.notFiled,
    );
  }

  String get displayNamePl {
    switch (this) {
      case CasTribunalStatus.notFiled:
        return 'Nie złożono odwołania';
      case CasTribunalStatus.filedPendingPreliminary:
        return 'Wniosek zarejestrowany w kancelarii CAS (Lozanna)';
      case CasTribunalStatus.expeditedProvisionalStayGranted:
        return 'Tryb pilny: zawieszenie wykonania kary (Provisional Stay)';
      case CasTribunalStatus.hearingScheduledLausanne:
        return 'Wyznaczono rozprawę przed panelem arbitrów CAS';
      case CasTribunalStatus.verdictUpheldDsq:
        return 'Wyrok CAS: podtrzymano decyzję UCI (DSQ)';
      case CasTribunalStatus.verdictOverturnedReinstated:
        return 'Wyrok CAS: uchylono karę i przywrócono wyniki';
      case CasTribunalStatus.verdictReducedToFine:
        return 'Wyrok CAS: zamiana DSQ na grzywnę regulaminową';
    }
  }
}

/// Poziom reprezentacji prawnej wynajętej przez zespół przed CAS.
enum CasLegalCounselTier {
  clubInternalLegal,
  specialistSportsAttorney,
  lausanneSeniorArbitrationQc;

  String toJson() => name;

  static CasLegalCounselTier fromJson(String value) {
    return CasLegalCounselTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CasLegalCounselTier.specialistSportsAttorney,
    );
  }

  String get displayNamePl {
    switch (this) {
      case CasLegalCounselTier.clubInternalLegal:
        return 'Dział prawny klubu';
      case CasLegalCounselTier.specialistSportsAttorney:
        return 'Kancelaria prawa sportowego (CAS Specialist)';
      case CasLegalCounselTier.lausanneSeniorArbitrationQc:
        return 'Zespół starszych arbitrów z Lozanny (Tier 1 QC)';
    }
  }

  double get costChf {
    switch (this) {
      case CasLegalCounselTier.clubInternalLegal:
        return 2500.0;
      case CasLegalCounselTier.specialistSportsAttorney:
        return 12000.0;
      case CasLegalCounselTier.lausanneSeniorArbitrationQc:
        return 35000.0;
    }
  }

  double get winProbabilityBonus {
    switch (this) {
      case CasLegalCounselTier.clubInternalLegal:
        return 0.0;
      case CasLegalCounselTier.specialistSportsAttorney:
        return 0.14;
      case CasLegalCounselTier.lausanneSeniorArbitrationQc:
        return 0.28;
    }
  }
}

/// Aktualne progi regulaminu technicznego UCI.
class UciTechnicalRegulationLimits {
  final double maxSockHeightRatioToShin;
  final double maxBrakeLeverInwardTiltDeg;
  final double minBikeWeightKg;
  final double maxTtExtensionReachMm;
  final double minFrameTubeWidthMm;
  final double maxFrameTubeBoxMm;
  final double maxTubeAspectRatio;
  final double magneticAnomalyThresholdMicroTesla;
  final double xrayDensityAnomalyThreshold;

  const UciTechnicalRegulationLimits({
    this.maxSockHeightRatioToShin = 0.50,
    this.maxBrakeLeverInwardTiltDeg = 10.0,
    this.minBikeWeightKg = 6.80,
    this.maxTtExtensionReachMm = 800.0,
    this.minFrameTubeWidthMm = 10.0,
    this.maxFrameTubeBoxMm = 80.0,
    this.maxTubeAspectRatio = 8.0,
    this.magneticAnomalyThresholdMicroTesla = 45.0,
    this.xrayDensityAnomalyThreshold = 0.65,
  });

  /// Weryfikuje przepis UCI Art. 1.3.033: wysokość skarpetek <= 50% długości goleni.
  bool evaluateSockCompliance({
    required double sockHeightCm,
    required double shinLengthCm,
  }) {
    if (shinLengthCm <= 0) return false;
    final ratio = sockHeightCm / shinLengthCm;
    return ratio <= maxSockHeightRatioToShin + 1e-6;
  }

  /// Weryfikuje kąt pochylenia klamek kierownicy <= 10 stopni.
  bool evaluateLeverTiltCompliance(double inwardTiltDeg) {
    return inwardTiltDeg.abs() <= maxBrakeLeverInwardTiltDeg + 1e-6;
  }

  /// Weryfikuje minimalną wagę roweru (6.80 kg).
  bool evaluateWeightCompliance(double measuredWeightKg) {
    return measuredWeightKg >= minBikeWeightKg - 1e-6;
  }

  /// Weryfikuje zasięg przedłużek lemondki czasowej.
  bool evaluateTtExtensionCompliance(double extensionReachMm) {
    return extensionReachMm <= maxTtExtensionReachMm + 1e-6;
  }

  UciTechnicalRegulationLimits copyWith({
    double? maxSockHeightRatioToShin,
    double? maxBrakeLeverInwardTiltDeg,
    double? minBikeWeightKg,
    double? maxTtExtensionReachMm,
    double? minFrameTubeWidthMm,
    double? maxFrameTubeBoxMm,
    double? maxTubeAspectRatio,
    double? magneticAnomalyThresholdMicroTesla,
    double? xrayDensityAnomalyThreshold,
  }) {
    return UciTechnicalRegulationLimits(
      maxSockHeightRatioToShin:
          maxSockHeightRatioToShin ?? this.maxSockHeightRatioToShin,
      maxBrakeLeverInwardTiltDeg:
          maxBrakeLeverInwardTiltDeg ?? this.maxBrakeLeverInwardTiltDeg,
      minBikeWeightKg: minBikeWeightKg ?? this.minBikeWeightKg,
      maxTtExtensionReachMm:
          maxTtExtensionReachMm ?? this.maxTtExtensionReachMm,
      minFrameTubeWidthMm: minFrameTubeWidthMm ?? this.minFrameTubeWidthMm,
      maxFrameTubeBoxMm: maxFrameTubeBoxMm ?? this.maxFrameTubeBoxMm,
      maxTubeAspectRatio: maxTubeAspectRatio ?? this.maxTubeAspectRatio,
      magneticAnomalyThresholdMicroTesla: magneticAnomalyThresholdMicroTesla ??
          this.magneticAnomalyThresholdMicroTesla,
      xrayDensityAnomalyThreshold:
          xrayDensityAnomalyThreshold ?? this.xrayDensityAnomalyThreshold,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxSockHeightRatioToShin': maxSockHeightRatioToShin,
      'maxBrakeLeverInwardTiltDeg': maxBrakeLeverInwardTiltDeg,
      'minBikeWeightKg': minBikeWeightKg,
      'maxTtExtensionReachMm': maxTtExtensionReachMm,
      'minFrameTubeWidthMm': minFrameTubeWidthMm,
      'maxFrameTubeBoxMm': maxFrameTubeBoxMm,
      'maxTubeAspectRatio': maxTubeAspectRatio,
      'magneticAnomalyThresholdMicroTesla': magneticAnomalyThresholdMicroTesla,
      'xrayDensityAnomalyThreshold': xrayDensityAnomalyThreshold,
    };
  }

  factory UciTechnicalRegulationLimits.fromJson(Map<String, dynamic> json) {
    return UciTechnicalRegulationLimits(
      maxSockHeightRatioToShin:
          (json['maxSockHeightRatioToShin'] as num?)?.toDouble() ?? 0.50,
      maxBrakeLeverInwardTiltDeg:
          (json['maxBrakeLeverInwardTiltDeg'] as num?)?.toDouble() ?? 10.0,
      minBikeWeightKg: (json['minBikeWeightKg'] as num?)?.toDouble() ?? 6.80,
      maxTtExtensionReachMm:
          (json['maxTtExtensionReachMm'] as num?)?.toDouble() ?? 800.0,
      minFrameTubeWidthMm:
          (json['minFrameTubeWidthMm'] as num?)?.toDouble() ?? 10.0,
      maxFrameTubeBoxMm: (json['maxFrameTubeBoxMm'] as num?)?.toDouble() ?? 80.0,
      maxTubeAspectRatio:
          (json['maxTubeAspectRatio'] as num?)?.toDouble() ?? 8.0,
      magneticAnomalyThresholdMicroTesla:
          (json['magneticAnomalyThresholdMicroTesla'] as num?)?.toDouble() ??
              45.0,
      xrayDensityAnomalyThreshold:
          (json['xrayDensityAnomalyThreshold'] as num?)?.toDouble() ?? 0.65,
    );
  }
}

/// Wynik pojedynczego skanu magnetycznego lub rentgenowskiego X-Ray roweru.
class XrayAndMagneticScanTelemetry {
  final String scanId;
  final ScrutinyDeviceType deviceType;
  final EquipmentInspectionZone zone;
  final double magneticFluxMicroTesla;
  final double xrayMetalDensityScore;
  final bool hiddenMotorSignatureDetected;
  final bool unusualBatteryCellDetected;
  final bool serialNumberVerified;
  final int scanDurationSeconds;
  final String operatorCommissaireId;
  final String timestampIso;

  const XrayAndMagneticScanTelemetry({
    required this.scanId,
    required this.deviceType,
    required this.zone,
    required this.magneticFluxMicroTesla,
    required this.xrayMetalDensityScore,
    required this.hiddenMotorSignatureDetected,
    required this.unusualBatteryCellDetected,
    required this.serialNumberVerified,
    required this.scanDurationSeconds,
    required this.operatorCommissaireId,
    required this.timestampIso,
  });

  bool get isClean =>
      !hiddenMotorSignatureDetected &&
      !unusualBatteryCellDetected &&
      magneticFluxMicroTesla <= 45.0 &&
      xrayMetalDensityScore <= 0.65;

  bool get requiresLabImpound =>
      hiddenMotorSignatureDetected ||
      unusualBatteryCellDetected ||
      xrayMetalDensityScore > 0.80;

  XrayAndMagneticScanTelemetry copyWith({
    String? scanId,
    ScrutinyDeviceType? deviceType,
    EquipmentInspectionZone? zone,
    double? magneticFluxMicroTesla,
    double? xrayMetalDensityScore,
    bool? hiddenMotorSignatureDetected,
    bool? unusualBatteryCellDetected,
    bool? serialNumberVerified,
    int? scanDurationSeconds,
    String? operatorCommissaireId,
    String? timestampIso,
  }) {
    return XrayAndMagneticScanTelemetry(
      scanId: scanId ?? this.scanId,
      deviceType: deviceType ?? this.deviceType,
      zone: zone ?? this.zone,
      magneticFluxMicroTesla:
          magneticFluxMicroTesla ?? this.magneticFluxMicroTesla,
      xrayMetalDensityScore:
          xrayMetalDensityScore ?? this.xrayMetalDensityScore,
      hiddenMotorSignatureDetected:
          hiddenMotorSignatureDetected ?? this.hiddenMotorSignatureDetected,
      unusualBatteryCellDetected:
          unusualBatteryCellDetected ?? this.unusualBatteryCellDetected,
      serialNumberVerified: serialNumberVerified ?? this.serialNumberVerified,
      scanDurationSeconds: scanDurationSeconds ?? this.scanDurationSeconds,
      operatorCommissaireId:
          operatorCommissaireId ?? this.operatorCommissaireId,
      timestampIso: timestampIso ?? this.timestampIso,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scanId': scanId,
      'deviceType': deviceType.toJson(),
      'zone': zone.toJson(),
      'magneticFluxMicroTesla': magneticFluxMicroTesla,
      'xrayMetalDensityScore': xrayMetalDensityScore,
      'hiddenMotorSignatureDetected': hiddenMotorSignatureDetected,
      'unusualBatteryCellDetected': unusualBatteryCellDetected,
      'serialNumberVerified': serialNumberVerified,
      'scanDurationSeconds': scanDurationSeconds,
      'operatorCommissaireId': operatorCommissaireId,
      'timestampIso': timestampIso,
    };
  }

  factory XrayAndMagneticScanTelemetry.fromJson(Map<String, dynamic> json) {
    return XrayAndMagneticScanTelemetry(
      scanId: json['scanId'] as String? ?? '',
      deviceType: ScrutinyDeviceType.fromJson(
        json['deviceType'] as String? ?? 'mobileXrayScanner',
      ),
      zone: EquipmentInspectionZone.fromJson(
        json['zone'] as String? ?? 'bottomBracketShell',
      ),
      magneticFluxMicroTesla:
          (json['magneticFluxMicroTesla'] as num?)?.toDouble() ?? 0.0,
      xrayMetalDensityScore:
          (json['xrayMetalDensityScore'] as num?)?.toDouble() ?? 0.0,
      hiddenMotorSignatureDetected:
          json['hiddenMotorSignatureDetected'] as bool? ?? false,
      unusualBatteryCellDetected:
          json['unusualBatteryCellDetected'] as bool? ?? false,
      serialNumberVerified: json['serialNumberVerified'] as bool? ?? true,
      scanDurationSeconds: (json['scanDurationSeconds'] as num?)?.toInt() ?? 18,
      operatorCommissaireId: json['operatorCommissaireId'] as String? ?? 'UCI-01',
      timestampIso: json['timestampIso'] as String? ?? '',
    );
  }
}

/// Zmierzona geometria i konfiguracja roweru oraz stroju kolarza podczas kontroli.
class RiderEquipmentMeasurements {
  final String riderId;
  final String riderName;
  final String teamId;
  final String frameSerialNumber;
  final double bikeWeightKg;
  final double sockHeightCm;
  final double shinLengthCm;
  final double brakeLeverTiltDeg;
  final double ttExtensionReachMm;
  final bool isTimeTrialSetup;
  final bool frameJigCompliant;
  final String measuredAtIso;

  const RiderEquipmentMeasurements({
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.frameSerialNumber,
    required this.bikeWeightKg,
    required this.sockHeightCm,
    required this.shinLengthCm,
    required this.brakeLeverTiltDeg,
    required this.ttExtensionReachMm,
    required this.isTimeTrialSetup,
    required this.frameJigCompliant,
    required this.measuredAtIso,
  });

  double get sockToShinRatio =>
      shinLengthCm > 0 ? sockHeightCm / shinLengthCm : 1.0;

  bool get isSockCompliant => sockToShinRatio <= 0.50 + 1e-6;

  bool get isLeverTiltCompliant => brakeLeverTiltDeg.abs() <= 10.0 + 1e-6;

  bool get isWeightCompliant => bikeWeightKg >= 6.80 - 1e-6;

  bool get isTtExtensionCompliant =>
      !isTimeTrialSetup || ttExtensionReachMm <= 800.0 + 1e-6;

  RiderEquipmentMeasurements copyWith({
    String? riderId,
    String? riderName,
    String? teamId,
    String? frameSerialNumber,
    double? bikeWeightKg,
    double? sockHeightCm,
    double? shinLengthCm,
    double? brakeLeverTiltDeg,
    double? ttExtensionReachMm,
    bool? isTimeTrialSetup,
    bool? frameJigCompliant,
    String? measuredAtIso,
  }) {
    return RiderEquipmentMeasurements(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      teamId: teamId ?? this.teamId,
      frameSerialNumber: frameSerialNumber ?? this.frameSerialNumber,
      bikeWeightKg: bikeWeightKg ?? this.bikeWeightKg,
      sockHeightCm: sockHeightCm ?? this.sockHeightCm,
      shinLengthCm: shinLengthCm ?? this.shinLengthCm,
      brakeLeverTiltDeg: brakeLeverTiltDeg ?? this.brakeLeverTiltDeg,
      ttExtensionReachMm: ttExtensionReachMm ?? this.ttExtensionReachMm,
      isTimeTrialSetup: isTimeTrialSetup ?? this.isTimeTrialSetup,
      frameJigCompliant: frameJigCompliant ?? this.frameJigCompliant,
      measuredAtIso: measuredAtIso ?? this.measuredAtIso,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'teamId': teamId,
      'frameSerialNumber': frameSerialNumber,
      'bikeWeightKg': bikeWeightKg,
      'sockHeightCm': sockHeightCm,
      'shinLengthCm': shinLengthCm,
      'brakeLeverTiltDeg': brakeLeverTiltDeg,
      'ttExtensionReachMm': ttExtensionReachMm,
      'isTimeTrialSetup': isTimeTrialSetup,
      'frameJigCompliant': frameJigCompliant,
      'measuredAtIso': measuredAtIso,
    };
  }

  factory RiderEquipmentMeasurements.fromJson(Map<String, dynamic> json) {
    return RiderEquipmentMeasurements(
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? '',
      teamId: json['teamId'] as String? ?? '',
      frameSerialNumber: json['frameSerialNumber'] as String? ?? '',
      bikeWeightKg: (json['bikeWeightKg'] as num?)?.toDouble() ?? 6.85,
      sockHeightCm: (json['sockHeightCm'] as num?)?.toDouble() ?? 18.0,
      shinLengthCm: (json['shinLengthCm'] as num?)?.toDouble() ?? 40.0,
      brakeLeverTiltDeg: (json['brakeLeverTiltDeg'] as num?)?.toDouble() ?? 6.0,
      ttExtensionReachMm:
          (json['ttExtensionReachMm'] as num?)?.toDouble() ?? 750.0,
      isTimeTrialSetup: json['isTimeTrialSetup'] as bool? ?? false,
      frameJigCompliant: json['frameJigCompliant'] as bool? ?? true,
      measuredAtIso: json['measuredAtIso'] as String? ?? '',
    );
  }
}

/// Wynik kontroli pojedynczej strefy roweru lub stroju.
class ScrutinyZoneCheckResult {
  final EquipmentInspectionZone zone;
  final ScrutinyFindingSeverity severity;
  final double measuredValue;
  final double limitValue;
  final String unit;
  final bool passed;
  final bool requiresImmediateTorqueCorrection;
  final String notePl;

  const ScrutinyZoneCheckResult({
    required this.zone,
    required this.severity,
    required this.measuredValue,
    required this.limitValue,
    required this.unit,
    required this.passed,
    required this.requiresImmediateTorqueCorrection,
    required this.notePl,
  });

  ScrutinyZoneCheckResult copyWith({
    EquipmentInspectionZone? zone,
    ScrutinyFindingSeverity? severity,
    double? measuredValue,
    double? limitValue,
    String? unit,
    bool? passed,
    bool? requiresImmediateTorqueCorrection,
    String? notePl,
  }) {
    return ScrutinyZoneCheckResult(
      zone: zone ?? this.zone,
      severity: severity ?? this.severity,
      measuredValue: measuredValue ?? this.measuredValue,
      limitValue: limitValue ?? this.limitValue,
      unit: unit ?? this.unit,
      passed: passed ?? this.passed,
      requiresImmediateTorqueCorrection: requiresImmediateTorqueCorrection ??
          this.requiresImmediateTorqueCorrection,
      notePl: notePl ?? this.notePl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'zone': zone.toJson(),
      'severity': severity.toJson(),
      'measuredValue': measuredValue,
      'limitValue': limitValue,
      'unit': unit,
      'passed': passed,
      'requiresImmediateTorqueCorrection': requiresImmediateTorqueCorrection,
      'notePl': notePl,
    };
  }

  factory ScrutinyZoneCheckResult.fromJson(Map<String, dynamic> json) {
    return ScrutinyZoneCheckResult(
      zone: EquipmentInspectionZone.fromJson(
        json['zone'] as String? ?? 'bottomBracketShell',
      ),
      severity: ScrutinyFindingSeverity.fromJson(
        json['severity'] as String? ?? 'compliant',
      ),
      measuredValue: (json['measuredValue'] as num?)?.toDouble() ?? 0.0,
      limitValue: (json['limitValue'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      passed: json['passed'] as bool? ?? true,
      requiresImmediateTorqueCorrection:
          json['requiresImmediateTorqueCorrection'] as bool? ?? false,
      notePl: json['notePl'] as String? ?? '',
    );
  }
}

/// Pełny protokół inspekcji technicznej UCI przeprowadzonej przed startem lub na mecie.
class TechnicalScrutinyInspectionRecord {
  final String inspectionId;
  final String raceId;
  final int stageNumber;
  final String riderId;
  final String riderName;
  final String teamId;
  final ScrutinyTimingWindow timingWindow;
  final ScrutinySelectionMode selectionMode;
  final List<ScrutinyDeviceType> devicesUsed;
  final RiderEquipmentMeasurements measurements;
  final List<XrayAndMagneticScanTelemetry> xrayScans;
  final List<ScrutinyZoneCheckResult> zoneResults;
  final ScrutinySessionOutcome overallOutcome;
  final double fineChf;
  final int uciPointsDeducted;
  final double riderStressSpikeDelta;
  final double riderFocusDropDelta;
  final int torqueCorrectionSeconds;
  final String commissaireName;
  final String inspectedAtIso;

  const TechnicalScrutinyInspectionRecord({
    required this.inspectionId,
    required this.raceId,
    required this.stageNumber,
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.timingWindow,
    required this.selectionMode,
    required this.devicesUsed,
    required this.measurements,
    required this.xrayScans,
    required this.zoneResults,
    required this.overallOutcome,
    required this.fineChf,
    required this.uciPointsDeducted,
    required this.riderStressSpikeDelta,
    required this.riderFocusDropDelta,
    required this.torqueCorrectionSeconds,
    required this.commissaireName,
    required this.inspectedAtIso,
  });

  List<ScrutinyZoneCheckResult> get failedZones =>
      zoneResults.where((z) => !z.passed).toList(growable: false);

  bool get hasAnyViolation => failedZones.isNotEmpty;

  bool get isAppealableToCas =>
      overallOutcome == ScrutinySessionOutcome.disqualifiedDsq ||
      overallOutcome == ScrutinySessionOutcome.impoundedForLabXray ||
      overallOutcome == ScrutinySessionOutcome.relegatedOrTimePenalty;

  TechnicalScrutinyInspectionRecord copyWith({
    String? inspectionId,
    String? raceId,
    int? stageNumber,
    String? riderId,
    String? riderName,
    String? teamId,
    ScrutinyTimingWindow? timingWindow,
    ScrutinySelectionMode? selectionMode,
    List<ScrutinyDeviceType>? devicesUsed,
    RiderEquipmentMeasurements? measurements,
    List<XrayAndMagneticScanTelemetry>? xrayScans,
    List<ScrutinyZoneCheckResult>? zoneResults,
    ScrutinySessionOutcome? overallOutcome,
    double? fineChf,
    int? uciPointsDeducted,
    double? riderStressSpikeDelta,
    double? riderFocusDropDelta,
    int? torqueCorrectionSeconds,
    String? commissaireName,
    String? inspectedAtIso,
  }) {
    return TechnicalScrutinyInspectionRecord(
      inspectionId: inspectionId ?? this.inspectionId,
      raceId: raceId ?? this.raceId,
      stageNumber: stageNumber ?? this.stageNumber,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      teamId: teamId ?? this.teamId,
      timingWindow: timingWindow ?? this.timingWindow,
      selectionMode: selectionMode ?? this.selectionMode,
      devicesUsed: devicesUsed ?? this.devicesUsed,
      measurements: measurements ?? this.measurements,
      xrayScans: xrayScans ?? this.xrayScans,
      zoneResults: zoneResults ?? this.zoneResults,
      overallOutcome: overallOutcome ?? this.overallOutcome,
      fineChf: fineChf ?? this.fineChf,
      uciPointsDeducted: uciPointsDeducted ?? this.uciPointsDeducted,
      riderStressSpikeDelta:
          riderStressSpikeDelta ?? this.riderStressSpikeDelta,
      riderFocusDropDelta: riderFocusDropDelta ?? this.riderFocusDropDelta,
      torqueCorrectionSeconds:
          torqueCorrectionSeconds ?? this.torqueCorrectionSeconds,
      commissaireName: commissaireName ?? this.commissaireName,
      inspectedAtIso: inspectedAtIso ?? this.inspectedAtIso,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inspectionId': inspectionId,
      'raceId': raceId,
      'stageNumber': stageNumber,
      'riderId': riderId,
      'riderName': riderName,
      'teamId': teamId,
      'timingWindow': timingWindow.toJson(),
      'selectionMode': selectionMode.toJson(),
      'devicesUsed': devicesUsed.map((d) => d.toJson()).toList(),
      'measurements': measurements.toJson(),
      'xrayScans': xrayScans.map((s) => s.toJson()).toList(),
      'zoneResults': zoneResults.map((z) => z.toJson()).toList(),
      'overallOutcome': overallOutcome.toJson(),
      'fineChf': fineChf,
      'uciPointsDeducted': uciPointsDeducted,
      'riderStressSpikeDelta': riderStressSpikeDelta,
      'riderFocusDropDelta': riderFocusDropDelta,
      'torqueCorrectionSeconds': torqueCorrectionSeconds,
      'commissaireName': commissaireName,
      'inspectedAtIso': inspectedAtIso,
    };
  }

  factory TechnicalScrutinyInspectionRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    final devicesList = (json['devicesUsed'] as List<dynamic>? ?? const [])
        .map((e) => ScrutinyDeviceType.fromJson(e.toString()))
        .toList();
    final scansList = (json['xrayScans'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(XrayAndMagneticScanTelemetry.fromJson)
        .toList();
    final zonesList = (json['zoneResults'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ScrutinyZoneCheckResult.fromJson)
        .toList();

    return TechnicalScrutinyInspectionRecord(
      inspectionId: json['inspectionId'] as String? ?? '',
      raceId: json['raceId'] as String? ?? '',
      stageNumber: (json['stageNumber'] as num?)?.toInt() ?? 1,
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? '',
      teamId: json['teamId'] as String? ?? '',
      timingWindow: ScrutinyTimingWindow.fromJson(
        json['timingWindow'] as String? ?? 'preStartPaddock',
      ),
      selectionMode: ScrutinySelectionMode.fromJson(
        json['selectionMode'] as String? ?? 'randomLottery',
      ),
      devicesUsed: devicesList,
      measurements: RiderEquipmentMeasurements.fromJson(
        json['measurements'] as Map<String, dynamic>? ?? const {},
      ),
      xrayScans: scansList,
      zoneResults: zonesList,
      overallOutcome: ScrutinySessionOutcome.fromJson(
        json['overallOutcome'] as String? ?? 'passedClean',
      ),
      fineChf: (json['fineChf'] as num?)?.toDouble() ?? 0.0,
      uciPointsDeducted: (json['uciPointsDeducted'] as num?)?.toInt() ?? 0,
      riderStressSpikeDelta:
          (json['riderStressSpikeDelta'] as num?)?.toDouble() ?? 0.0,
      riderFocusDropDelta:
          (json['riderFocusDropDelta'] as num?)?.toDouble() ?? 0.0,
      torqueCorrectionSeconds:
          (json['torqueCorrectionSeconds'] as num?)?.toInt() ?? 0,
      commissaireName: json['commissaireName'] as String? ?? 'Komisarz UCI',
      inspectedAtIso: json['inspectedAtIso'] as String? ?? '',
    );
  }
}

/// Sprawa odwoławcza zespołu przed Trybunałem Arbitrażowym ds. Sportu (CAS w Lozannie).
class CasTribunalAppealCase {
  final String caseId;
  final String inspectionId;
  final String raceId;
  final String teamId;
  final String riderId;
  final String riderName;
  final List<CasAppealGround> grounds;
  final CasLegalCounselTier counselTier;
  final CasTribunalStatus status;
  final double filingFeeChf;
  final double legalDefenseCostChf;
  final double winProbability;
  final bool provisionalStayRequested;
  final bool provisionalStayGranted;
  final String hearingDateIso;
  final String lausannePanelChair;
  final String submittedEvidenceSummaryPl;
  final String verdictSummaryPl;
  final double reputationImpactDelta;
  final String updatedAtIso;

  const CasTribunalAppealCase({
    required this.caseId,
    required this.inspectionId,
    required this.raceId,
    required this.teamId,
    required this.riderId,
    required this.riderName,
    required this.grounds,
    required this.counselTier,
    required this.status,
    required this.filingFeeChf,
    required this.legalDefenseCostChf,
    required this.winProbability,
    required this.provisionalStayRequested,
    required this.provisionalStayGranted,
    required this.hearingDateIso,
    required this.lausannePanelChair,
    required this.submittedEvidenceSummaryPl,
    required this.verdictSummaryPl,
    required this.reputationImpactDelta,
    required this.updatedAtIso,
  });

  double get totalLegalSpendChf => filingFeeChf + legalDefenseCostChf;

  bool get isResolved =>
      status == CasTribunalStatus.verdictUpheldDsq ||
      status == CasTribunalStatus.verdictOverturnedReinstated ||
      status == CasTribunalStatus.verdictReducedToFine;

  bool get isSuccessfulForTeam =>
      status == CasTribunalStatus.verdictOverturnedReinstated ||
      status == CasTribunalStatus.verdictReducedToFine;

  CasTribunalAppealCase copyWith({
    String? caseId,
    String? inspectionId,
    String? raceId,
    String? teamId,
    String? riderId,
    String? riderName,
    List<CasAppealGround>? grounds,
    CasLegalCounselTier? counselTier,
    CasTribunalStatus? status,
    double? filingFeeChf,
    double? legalDefenseCostChf,
    double? winProbability,
    bool? provisionalStayRequested,
    bool? provisionalStayGranted,
    String? hearingDateIso,
    String? lausannePanelChair,
    String? submittedEvidenceSummaryPl,
    String? verdictSummaryPl,
    double? reputationImpactDelta,
    String? updatedAtIso,
  }) {
    return CasTribunalAppealCase(
      caseId: caseId ?? this.caseId,
      inspectionId: inspectionId ?? this.inspectionId,
      raceId: raceId ?? this.raceId,
      teamId: teamId ?? this.teamId,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      grounds: grounds ?? this.grounds,
      counselTier: counselTier ?? this.counselTier,
      status: status ?? this.status,
      filingFeeChf: filingFeeChf ?? this.filingFeeChf,
      legalDefenseCostChf: legalDefenseCostChf ?? this.legalDefenseCostChf,
      winProbability: winProbability ?? this.winProbability,
      provisionalStayRequested:
          provisionalStayRequested ?? this.provisionalStayRequested,
      provisionalStayGranted:
          provisionalStayGranted ?? this.provisionalStayGranted,
      hearingDateIso: hearingDateIso ?? this.hearingDateIso,
      lausannePanelChair: lausannePanelChair ?? this.lausannePanelChair,
      submittedEvidenceSummaryPl:
          submittedEvidenceSummaryPl ?? this.submittedEvidenceSummaryPl,
      verdictSummaryPl: verdictSummaryPl ?? this.verdictSummaryPl,
      reputationImpactDelta:
          reputationImpactDelta ?? this.reputationImpactDelta,
      updatedAtIso: updatedAtIso ?? this.updatedAtIso,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caseId': caseId,
      'inspectionId': inspectionId,
      'raceId': raceId,
      'teamId': teamId,
      'riderId': riderId,
      'riderName': riderName,
      'grounds': grounds.map((g) => g.toJson()).toList(),
      'counselTier': counselTier.toJson(),
      'status': status.toJson(),
      'filingFeeChf': filingFeeChf,
      'legalDefenseCostChf': legalDefenseCostChf,
      'winProbability': winProbability,
      'provisionalStayRequested': provisionalStayRequested,
      'provisionalStayGranted': provisionalStayGranted,
      'hearingDateIso': hearingDateIso,
      'lausannePanelChair': lausannePanelChair,
      'submittedEvidenceSummaryPl': submittedEvidenceSummaryPl,
      'verdictSummaryPl': verdictSummaryPl,
      'reputationImpactDelta': reputationImpactDelta,
      'updatedAtIso': updatedAtIso,
    };
  }

  factory CasTribunalAppealCase.fromJson(Map<String, dynamic> json) {
    final groundsList = (json['grounds'] as List<dynamic>? ?? const [])
        .map((e) => CasAppealGround.fromJson(e.toString()))
        .toList();

    return CasTribunalAppealCase(
      caseId: json['caseId'] as String? ?? '',
      inspectionId: json['inspectionId'] as String? ?? '',
      raceId: json['raceId'] as String? ?? '',
      teamId: json['teamId'] as String? ?? '',
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? '',
      grounds: groundsList,
      counselTier: CasLegalCounselTier.fromJson(
        json['counselTier'] as String? ?? 'specialistSportsAttorney',
      ),
      status: CasTribunalStatus.fromJson(
        json['status'] as String? ?? 'filedPendingPreliminary',
      ),
      filingFeeChf: (json['filingFeeChf'] as num?)?.toDouble() ?? 1000.0,
      legalDefenseCostChf:
          (json['legalDefenseCostChf'] as num?)?.toDouble() ?? 12000.0,
      winProbability: (json['winProbability'] as num?)?.toDouble() ?? 0.35,
      provisionalStayRequested:
          json['provisionalStayRequested'] as bool? ?? false,
      provisionalStayGranted: json['provisionalStayGranted'] as bool? ?? false,
      hearingDateIso: json['hearingDateIso'] as String? ?? '',
      lausannePanelChair:
          json['lausannePanelChair'] as String? ?? 'Prof. Dr. Lukas Meyer (CAS)',
      submittedEvidenceSummaryPl:
          json['submittedEvidenceSummaryPl'] as String? ?? '',
      verdictSummaryPl: json['verdictSummaryPl'] as String? ?? '',
      reputationImpactDelta:
          (json['reputationImpactDelta'] as num?)?.toDouble() ?? 0.0,
      updatedAtIso: json['updatedAtIso'] as String? ?? '',
    );
  }
}

/// Główny model danych dla Kontroli Technicznych UCI, Skanerów X-Ray i Trybunału CAS.
class TechnicalScrutinyAndCasTribunalModel {
  final int seasonYear;
  final UciTechnicalRegulationLimits regulationLimits;
  final List<TechnicalScrutinyInspectionRecord> inspectionHistory;
  final List<CasTribunalAppealCase> casCases;
  final double teamComplianceAuditScore;
  final double scrutinyTargetProbabilityBias;
  final double totalFinesPaidChf;
  final String lastUpdatedIso;

  const TechnicalScrutinyAndCasTribunalModel({
    required this.seasonYear,
    required this.regulationLimits,
    required this.inspectionHistory,
    required this.casCases,
    required this.teamComplianceAuditScore,
    required this.scrutinyTargetProbabilityBias,
    required this.totalFinesPaidChf,
    required this.lastUpdatedIso,
  });

  factory TechnicalScrutinyAndCasTribunalModel.initial({
    int seasonYear = 2026,
    String? nowIso,
  }) {
    return TechnicalScrutinyAndCasTribunalModel(
      seasonYear: seasonYear,
      regulationLimits: const UciTechnicalRegulationLimits(),
      inspectionHistory: const [],
      casCases: const [],
      teamComplianceAuditScore: 100.0,
      scrutinyTargetProbabilityBias: 0.05,
      totalFinesPaidChf: 0.0,
      lastUpdatedIso: nowIso ?? DateTime(seasonYear, 1, 1).toIso8601String(),
    );
  }

  List<CasTribunalAppealCase> get pendingCasCases =>
      casCases.where((c) => !c.isResolved).toList(growable: false);

  List<CasTribunalAppealCase> get resolvedCasCases =>
      casCases.where((c) => c.isResolved).toList(growable: false);

  double get appealSuccessRate {
    final resolved = resolvedCasCases;
    if (resolved.isEmpty) return 0.0;
    final won = resolved.where((c) => c.isSuccessfulForTeam).length;
    return won / resolved.length;
  }

  List<TechnicalScrutinyInspectionRecord> inspectionsForRider(String riderId) {
    return inspectionHistory
        .where((r) => r.riderId == riderId)
        .toList(growable: false);
  }

  /// Przeprowadza pełną ocenę techniczną roweru i stroju kolarza wobec limitów UCI.
  TechnicalScrutinyInspectionRecord evaluateInspection({
    required String inspectionId,
    required String raceId,
    required int stageNumber,
    required ScrutinyTimingWindow timingWindow,
    required ScrutinySelectionMode selectionMode,
    required RiderEquipmentMeasurements measurements,
    required List<XrayAndMagneticScanTelemetry> xrayScans,
    String commissaireName = 'Jean-Luc Moreau (UCI Technical)',
    String? inspectedAtIso,
  }) {
    final zoneResults = <ScrutinyZoneCheckResult>[];
    final devices = <ScrutinyDeviceType>{
      ScrutinyDeviceType.sockHeightCaliper,
      ScrutinyDeviceType.leverAngleInclinometer,
      ScrutinyDeviceType.uciFrameJigTemplate,
      ScrutinyDeviceType.calibratedScale,
    };

    // 1. Wysokość skarpetek <= 50% długości goleni
    final sockRatio = measurements.sockToShinRatio;
    final sockPass = regulationLimits.evaluateSockCompliance(
      sockHeightCm: measurements.sockHeightCm,
      shinLengthCm: measurements.shinLengthCm,
    );
    final isPreStart = timingWindow == ScrutinyTimingWindow.preStartPaddock ||
        timingWindow == ScrutinyTimingWindow.preStartIttRamp;
    zoneResults.add(
      ScrutinyZoneCheckResult(
        zone: EquipmentInspectionZone.sockAndOvershoeHeight,
        severity: sockPass
            ? ScrutinyFindingSeverity.compliant
            : (isPreStart
                ? ScrutinyFindingSeverity.mandatory3MinRampCorrection
                : ScrutinyFindingSeverity.minorTechnicalWarning),
        measuredValue: double.parse((sockRatio * 100.0).toStringAsFixed(1)),
        limitValue:
            regulationLimits.maxSockHeightRatioToShin * 100.0,
        unit: '% goleni',
        passed: sockPass,
        requiresImmediateTorqueCorrection: !sockPass && isPreStart,
        notePl: sockPass
            ? 'Wysokość skarpetek w normie UCI (<= 50% długości goleni).'
            : 'Przekroczona wysokość skarpetek aero: wymóg opuszczenia przed startem.',
      ),
    );

    // 2. Kąt pochylenia klamek kierownicy <= 10 stopni
    final leverPass = regulationLimits
        .evaluateLeverTiltCompliance(measurements.brakeLeverTiltDeg);
    zoneResults.add(
      ScrutinyZoneCheckResult(
        zone: EquipmentInspectionZone.handlebarBrakeLevers,
        severity: leverPass
            ? ScrutinyFindingSeverity.compliant
            : (isPreStart
                ? ScrutinyFindingSeverity.mandatory3MinRampCorrection
                : ScrutinyFindingSeverity.equipmentConfiscationAndDsq),
        measuredValue: measurements.brakeLeverTiltDeg.abs(),
        limitValue: regulationLimits.maxBrakeLeverInwardTiltDeg,
        unit: '°',
        passed: leverPass,
        requiresImmediateTorqueCorrection: !leverPass && isPreStart,
        notePl: leverPass
            ? 'Kąt nachylenia klamek zgodny z regulaminem UCI (<= 10°).'
            : 'Nieregulaminowe zagięcie klamek do środka (> 10°).',
      ),
    );

    // 3. Minimalna waga roweru >= 6.80 kg
    final weightPass =
        regulationLimits.evaluateWeightCompliance(measurements.bikeWeightKg);
    zoneResults.add(
      ScrutinyZoneCheckResult(
        zone: EquipmentInspectionZone.minimumBikeWeight68Kg,
        severity: weightPass
            ? ScrutinyFindingSeverity.compliant
            : ScrutinyFindingSeverity.equipmentConfiscationAndDsq,
        measuredValue: measurements.bikeWeightKg,
        limitValue: regulationLimits.minBikeWeightKg,
        unit: 'kg',
        passed: weightPass,
        requiresImmediateTorqueCorrection: false,
        notePl: weightPass
            ? 'Waga roweru spełnia minimum UCI (>= 6.80 kg).'
            : 'Rower poniżej limitu wagi 6.80 kg — dyskwalifikacja techniczna.',
      ),
    );

    // 4. Wymiary ramy na szablonie UCI
    zoneResults.add(
      ScrutinyZoneCheckResult(
        zone: EquipmentInspectionZone.frameTubeDimensions3to1,
        severity: measurements.frameJigCompliant
            ? ScrutinyFindingSeverity.compliant
            : ScrutinyFindingSeverity.equipmentConfiscationAndDsq,
        measuredValue: measurements.frameJigCompliant ? 1.0 : 0.0,
        limitValue: 1.0,
        unit: 'szablon',
        passed: measurements.frameJigCompliant,
        requiresImmediateTorqueCorrection: false,
        notePl: measurements.frameJigCompliant
            ? 'Geometria i profile ramy mieszczą się w szablonie UCI.'
            : 'Rama nie mieści się w szablonie wymiarowym UCI.',
      ),
    );

    // 5. Przedłużki lemondki TT (jeśli dotyczy)
    if (measurements.isTimeTrialSetup) {
      final ttPass = regulationLimits
          .evaluateTtExtensionCompliance(measurements.ttExtensionReachMm);
      zoneResults.add(
        ScrutinyZoneCheckResult(
          zone: EquipmentInspectionZone.ttExtensionLength,
          severity: ttPass
              ? ScrutinyFindingSeverity.compliant
              : (isPreStart
                  ? ScrutinyFindingSeverity.mandatory3MinRampCorrection
                  : ScrutinyFindingSeverity.equipmentConfiscationAndDsq),
          measuredValue: measurements.ttExtensionReachMm,
          limitValue: regulationLimits.maxTtExtensionReachMm,
          unit: 'mm',
          passed: ttPass,
          requiresImmediateTorqueCorrection: !ttPass && isPreStart,
          notePl: ttPass
              ? 'Zasięg przedłużek czasowych TT mieści się w limicie UCI.'
              : 'Przekroczona długość przedłużek lemondki TT przed startem.',
        ),
      );
    }

    // 6. Skanowanie magnetyczne i rentgenowskie X-Ray (suport, sztyca, tylna piasta)
    var fraudDetected = false;
    for (final scan in xrayScans) {
      devices.add(scan.deviceType);
      final isScanClean = scan.isClean &&
          scan.magneticFluxMicroTesla <=
              regulationLimits.magneticAnomalyThresholdMicroTesla &&
          scan.xrayMetalDensityScore <=
              regulationLimits.xrayDensityAnomalyThreshold;
      if (!isScanClean) {
        fraudDetected = true;
      }
      zoneResults.add(
        ScrutinyZoneCheckResult(
          zone: scan.zone,
          severity: isScanClean
              ? ScrutinyFindingSeverity.compliant
              : (scan.requiresLabImpound
                  ? ScrutinyFindingSeverity.technologicalFraudBan
                  : ScrutinyFindingSeverity.equipmentConfiscationAndDsq),
          measuredValue: scan.magneticFluxMicroTesla,
          limitValue: regulationLimits.magneticAnomalyThresholdMicroTesla,
          unit: 'µT',
          passed: isScanClean,
          requiresImmediateTorqueCorrection: false,
          notePl: isScanClean
              ? 'Skan ${scan.deviceType.displayNamePl}: brak anomalii w strefie ${scan.zone.displayNamePl}.'
              : 'ALARM X-RAY / magnetyczny: wykryto podejrzaną sygnaturę w strefie ${scan.zone.displayNamePl}.',
        ),
      );
    }

    // Wyznacz wynik zbiorczy
    final anyTorqueFix =
        zoneResults.any((z) => z.requiresImmediateTorqueCorrection);
    final anyHardDsq = zoneResults.any(
      (z) =>
          !z.passed &&
          (z.severity == ScrutinyFindingSeverity.equipmentConfiscationAndDsq ||
              z.severity == ScrutinyFindingSeverity.technologicalFraudBan),
    );

    late final ScrutinySessionOutcome outcome;
    var fineChf = 0.0;
    var uciPoints = 0;
    var stressSpike = 0.0;
    var focusDrop = 0.0;
    var correctionSec = 0;

    if (fraudDetected) {
      outcome = ScrutinySessionOutcome.impoundedForLabXray;
      fineChf = 20000.0;
      uciPoints = 250;
      stressSpike = 35.0;
      focusDrop = 25.0;
    } else if (anyHardDsq) {
      outcome = ScrutinySessionOutcome.disqualifiedDsq;
      fineChf = 2000.0;
      uciPoints = 50;
      stressSpike = 24.0;
      focusDrop = 18.0;
    } else if (anyTorqueFix) {
      outcome = ScrutinySessionOutcome.passedAfterTorqueCorrection;
      fineChf = 500.0;
      stressSpike = timingWindow == ScrutinyTimingWindow.preStartIttRamp
          ? 22.0
          : 12.0;
      focusDrop = timingWindow == ScrutinyTimingWindow.preStartIttRamp
          ? 14.0
          : 7.0;
      correctionSec =
          timingWindow == ScrutinyTimingWindow.preStartIttRamp ? 95 : 45;
    } else if (zoneResults.any((z) => !z.passed)) {
      outcome = ScrutinySessionOutcome.relegatedOrTimePenalty;
      fineChf = 500.0;
      uciPoints = 15;
      stressSpike = 10.0;
      focusDrop = 6.0;
    } else {
      outcome = ScrutinySessionOutcome.passedClean;
    }

    return TechnicalScrutinyInspectionRecord(
      inspectionId: inspectionId,
      raceId: raceId,
      stageNumber: stageNumber,
      riderId: measurements.riderId,
      riderName: measurements.riderName,
      teamId: measurements.teamId,
      timingWindow: timingWindow,
      selectionMode: selectionMode,
      devicesUsed: devices.toList(growable: false),
      measurements: measurements,
      xrayScans: xrayScans,
      zoneResults: zoneResults,
      overallOutcome: outcome,
      fineChf: fineChf,
      uciPointsDeducted: uciPoints,
      riderStressSpikeDelta: stressSpike,
      riderFocusDropDelta: focusDrop,
      torqueCorrectionSeconds: correctionSec,
      commissaireName: commissaireName,
      inspectedAtIso:
          inspectedAtIso ?? DateTime.now().toUtc().toIso8601String(),
    );
  }

  /// Rejestruje zakończoną inspekcję i aktualizuje wskaźnik zaufania UCI zespołu.
  TechnicalScrutinyAndCasTribunalModel recordInspection(
    TechnicalScrutinyInspectionRecord record,
  ) {
    final updatedHistory = [...inspectionHistory, record];
    var scoreDelta = 0.0;
    var biasDelta = 0.0;

    switch (record.overallOutcome) {
      case ScrutinySessionOutcome.passedClean:
        scoreDelta = 1.5;
        biasDelta = -0.01;
        break;
      case ScrutinySessionOutcome.passedAfterTorqueCorrection:
        scoreDelta = -4.0;
        biasDelta = 0.05;
        break;
      case ScrutinySessionOutcome.relegatedOrTimePenalty:
        scoreDelta = -8.0;
        biasDelta = 0.08;
        break;
      case ScrutinySessionOutcome.disqualifiedDsq:
        scoreDelta = -16.0;
        biasDelta = 0.15;
        break;
      case ScrutinySessionOutcome.impoundedForLabXray:
        scoreDelta = -30.0;
        biasDelta = 0.30;
        break;
    }

    return copyWith(
      inspectionHistory: updatedHistory,
      teamComplianceAuditScore:
          (teamComplianceAuditScore + scoreDelta).clamp(0.0, 100.0),
      scrutinyTargetProbabilityBias:
          (scrutinyTargetProbabilityBias + biasDelta).clamp(0.02, 0.85),
      totalFinesPaidChf: totalFinesPaidChf + record.fineChf,
      lastUpdatedIso: record.inspectedAtIso,
    );
  }

  /// Składa odwołanie zespołu od decyzji komisarza UCI do Trybunału CAS w Lozannie.
  TechnicalScrutinyAndCasTribunalModel fileCasAppeal({
    required String caseId,
    required TechnicalScrutinyInspectionRecord inspection,
    required List<CasAppealGround> grounds,
    required CasLegalCounselTier counselTier,
    required bool requestProvisionalStay,
    required String submittedEvidenceSummaryPl,
    String lausannePanelChair = 'Prof. Dr. Lukas Meyer (CAS Lausanne)',
    String? nowIso,
  }) {
    final effectiveGrounds = grounds.isEmpty
        ? const [CasAppealGround.proceduralErrorByCommissaire]
        : grounds;
    final avgGroundWin = effectiveGrounds
            .map((g) => g.baseWinProbability)
            .reduce((a, b) => a + b) /
        effectiveGrounds.length;

    final auditBonus = ((teamComplianceAuditScore - 70.0) / 300.0)
        .clamp(-0.12, 0.10);
    final winProb =
        (avgGroundWin + counselTier.winProbabilityBonus + auditBonus)
            .clamp(0.08, 0.92);

    final timestamp = nowIso ?? DateTime.now().toUtc().toIso8601String();
    final stayGranted = requestProvisionalStay &&
        inspection.overallOutcome != ScrutinySessionOutcome.impoundedForLabXray &&
        winProb >= 0.42;

    final newCase = CasTribunalAppealCase(
      caseId: caseId,
      inspectionId: inspection.inspectionId,
      raceId: inspection.raceId,
      teamId: inspection.teamId,
      riderId: inspection.riderId,
      riderName: inspection.riderName,
      grounds: effectiveGrounds,
      counselTier: counselTier,
      status: stayGranted
          ? CasTribunalStatus.expeditedProvisionalStayGranted
          : CasTribunalStatus.filedPendingPreliminary,
      filingFeeChf: 1000.0,
      legalDefenseCostChf: counselTier.costChf,
      winProbability: double.parse(winProb.toStringAsFixed(3)),
      provisionalStayRequested: requestProvisionalStay,
      provisionalStayGranted: stayGranted,
      hearingDateIso: timestamp,
      lausannePanelChair: lausannePanelChair,
      submittedEvidenceSummaryPl: submittedEvidenceSummaryPl,
      verdictSummaryPl: stayGranted
          ? 'CAS przyznał tymczasowe zawieszenie kary do czasu rozprawy w Lozannie.'
          : 'Sprawa oczekuje na wyznaczenie składu orzekającego w Lozannie.',
      reputationImpactDelta: 0.0,
      updatedAtIso: timestamp,
    );

    return copyWith(
      casCases: [...casCases, newCase],
      lastUpdatedIso: timestamp,
    );
  }

  /// Rozstrzyga lub aktualizuje sprawę przed Trybunałem CAS w Lozannie.
  TechnicalScrutinyAndCasTribunalModel resolveCasCase({
    required String caseId,
    required CasTribunalStatus finalStatus,
    required String verdictSummaryPl,
    double? fineRefundChf,
    String? nowIso,
  }) {
    final timestamp = nowIso ?? DateTime.now().toUtc().toIso8601String();
    var complianceBoost = 0.0;
    var reputationDelta = 0.0;

    if (finalStatus == CasTribunalStatus.verdictOverturnedReinstated) {
      complianceBoost = 12.0;
      reputationDelta = 6.0;
    } else if (finalStatus == CasTribunalStatus.verdictReducedToFine) {
      complianceBoost = 5.0;
      reputationDelta = 1.5;
    } else if (finalStatus == CasTribunalStatus.verdictUpheldDsq) {
      complianceBoost = -5.0;
      reputationDelta = -8.0;
    }

    final updatedCases = casCases.map((c) {
      if (c.caseId != caseId) return c;
      return c.copyWith(
        status: finalStatus,
        verdictSummaryPl: verdictSummaryPl,
        reputationImpactDelta: reputationDelta,
        updatedAtIso: timestamp,
      );
    }).toList(growable: false);

    final updatedFines = math.max(
      0.0,
      totalFinesPaidChf - (fineRefundChf ?? 0.0),
    );

    return copyWith(
      casCases: updatedCases,
      teamComplianceAuditScore:
          (teamComplianceAuditScore + complianceBoost).clamp(0.0, 100.0),
      totalFinesPaidChf: updatedFines,
      lastUpdatedIso: timestamp,
    );
  }

  TechnicalScrutinyAndCasTribunalModel copyWith({
    int? seasonYear,
    UciTechnicalRegulationLimits? regulationLimits,
    List<TechnicalScrutinyInspectionRecord>? inspectionHistory,
    List<CasTribunalAppealCase>? casCases,
    double? teamComplianceAuditScore,
    double? scrutinyTargetProbabilityBias,
    double? totalFinesPaidChf,
    String? lastUpdatedIso,
  }) {
    return TechnicalScrutinyAndCasTribunalModel(
      seasonYear: seasonYear ?? this.seasonYear,
      regulationLimits: regulationLimits ?? this.regulationLimits,
      inspectionHistory: inspectionHistory ?? this.inspectionHistory,
      casCases: casCases ?? this.casCases,
      teamComplianceAuditScore:
          teamComplianceAuditScore ?? this.teamComplianceAuditScore,
      scrutinyTargetProbabilityBias:
          scrutinyTargetProbabilityBias ?? this.scrutinyTargetProbabilityBias,
      totalFinesPaidChf: totalFinesPaidChf ?? this.totalFinesPaidChf,
      lastUpdatedIso: lastUpdatedIso ?? this.lastUpdatedIso,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seasonYear': seasonYear,
      'regulationLimits': regulationLimits.toJson(),
      'inspectionHistory':
          inspectionHistory.map((r) => r.toJson()).toList(),
      'casCases': casCases.map((c) => c.toJson()).toList(),
      'teamComplianceAuditScore': teamComplianceAuditScore,
      'scrutinyTargetProbabilityBias': scrutinyTargetProbabilityBias,
      'totalFinesPaidChf': totalFinesPaidChf,
      'lastUpdatedIso': lastUpdatedIso,
    };
  }

  factory TechnicalScrutinyAndCasTribunalModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final history = (json['inspectionHistory'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TechnicalScrutinyInspectionRecord.fromJson)
        .toList();
    final cases = (json['casCases'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CasTribunalAppealCase.fromJson)
        .toList();

    return TechnicalScrutinyAndCasTribunalModel(
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      regulationLimits: UciTechnicalRegulationLimits.fromJson(
        json['regulationLimits'] as Map<String, dynamic>? ?? const {},
      ),
      inspectionHistory: history,
      casCases: cases,
      teamComplianceAuditScore:
          (json['teamComplianceAuditScore'] as num?)?.toDouble() ?? 100.0,
      scrutinyTargetProbabilityBias:
          (json['scrutinyTargetProbabilityBias'] as num?)?.toDouble() ?? 0.05,
      totalFinesPaidChf:
          (json['totalFinesPaidChf'] as num?)?.toDouble() ?? 0.0,
      lastUpdatedIso: json['lastUpdatedIso'] as String? ?? '',
    );
  }
}
