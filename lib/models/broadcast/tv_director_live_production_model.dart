import 'dart:math' as math;

/// Typ jednej z 12 niezależnych kamer transmisji telewizyjnej na żywo.
enum BroadcastCameraType {
  /// Helikopter 1 — główna kamera lotnicza nad ucieczką / czołówką wyścigu.
  heliCam1,

  /// Helikopter 2 — kamera taktyczna nad peletonem i grupą faworytów.
  heliCam2,

  /// Helikopter 3 — kamera przekaźnikowa / krajobrazowa i szerokie ujęcia górskie.
  heliCam3,

  /// Motocykl 1 (Front) — bezpośredni podgląd na ucieczkę dnia.
  motoCamFront,

  /// Motocykl 2 (Peloton) — jazda wewnątrz peletonu przy liderach klasyfikacji.
  motoCamPeloton,

  /// Motocykl 3 (Chase) — pościg za czołówką, kontrataki i odpadający faworyci.
  motoCamChase,

  /// Kamera akcji zamontowana na kierownicy roweru (140° FOV).
  onBoardHandlebarsCam,

  /// Kamera akcji pod siodełkiem skierowana na tylne koło i kasetę rywala.
  onBoardSaddleCam,

  /// Kamera bramki mety z góry (Finish Line Overhead) do sprintów i foto-finiszu.
  finishLineOverhead,

  /// Kamera wewnątrz wozu technicznego dyrektora sportowego (Team Car Interior).
  teamCarInterior,

  /// Stacjonarna kamera na kluczowym zakręcie podjazdu (serpentyna / tunel kibiców).
  fixedClimbCornerCam,

  /// Lekki dron pościgowy (Cine-Drone) lecący wzdłuż grani lub nad peletonem.
  droneTrackingCam;

  String toJson() => name;

  static BroadcastCameraType fromJson(String value) {
    return BroadcastCameraType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BroadcastCameraType.heliCam1,
    );
  }

  /// Krótki kod antenowy wyświetlany w reżyserce i na monitorach podglądu.
  String get shortCode {
    switch (this) {
      case BroadcastCameraType.heliCam1:
        return 'HELI 1';
      case BroadcastCameraType.heliCam2:
        return 'HELI 2';
      case BroadcastCameraType.heliCam3:
        return 'HELI 3';
      case BroadcastCameraType.motoCamFront:
        return 'MOTO FRONT';
      case BroadcastCameraType.motoCamPeloton:
        return 'MOTO PELOTON';
      case BroadcastCameraType.motoCamChase:
        return 'MOTO CHASE';
      case BroadcastCameraType.onBoardHandlebarsCam:
        return 'ONBOARD BAR';
      case BroadcastCameraType.onBoardSaddleCam:
        return 'ONBOARD SADDLE';
      case BroadcastCameraType.finishLineOverhead:
        return 'FINISH OH';
      case BroadcastCameraType.teamCarInterior:
        return 'TEAM CAR';
      case BroadcastCameraType.fixedClimbCornerCam:
        return 'CLIMB CAM';
      case BroadcastCameraType.droneTrackingCam:
        return 'CINE DRONE';
    }
  }

  String get displayNamePl {
    switch (this) {
      case BroadcastCameraType.heliCam1:
        return 'HeliCam 1 (Czołówka)';
      case BroadcastCameraType.heliCam2:
        return 'HeliCam 2 (Peleton)';
      case BroadcastCameraType.heliCam3:
        return 'HeliCam 3 (Panorama / Relay)';
      case BroadcastCameraType.motoCamFront:
        return 'MotoCam Front (Ucieczka)';
      case BroadcastCameraType.motoCamPeloton:
        return 'MotoCam Peloton (Faworyci)';
      case BroadcastCameraType.motoCamChase:
        return 'MotoCam Chase (Pościg)';
      case BroadcastCameraType.onBoardHandlebarsCam:
        return 'OnBoard Kierownica (140°)';
      case BroadcastCameraType.onBoardSaddleCam:
        return 'OnBoard Pod Siodełkiem';
      case BroadcastCameraType.finishLineOverhead:
        return 'Finish Line Overhead (Meta)';
      case BroadcastCameraType.teamCarInterior:
        return 'Team Car Interior (Wóz DS)';
      case BroadcastCameraType.fixedClimbCornerCam:
        return 'Kamera Serpentyny (Podjazd)';
      case BroadcastCameraType.droneTrackingCam:
        return 'Cine-Drone (Śledzenie)';
    }
  }

  String get displayNameEn {
    switch (this) {
      case BroadcastCameraType.heliCam1:
        return 'HeliCam 1 (Breakaway Lead)';
      case BroadcastCameraType.heliCam2:
        return 'HeliCam 2 (Peloton)';
      case BroadcastCameraType.heliCam3:
        return 'HeliCam 3 (Scenic / Relay)';
      case BroadcastCameraType.motoCamFront:
        return 'MotoCam Front (Breakaway)';
      case BroadcastCameraType.motoCamPeloton:
        return 'MotoCam Peloton (Favorites)';
      case BroadcastCameraType.motoCamChase:
        return 'MotoCam Chase (Pursuit)';
      case BroadcastCameraType.onBoardHandlebarsCam:
        return 'OnBoard Handlebars Cam';
      case BroadcastCameraType.onBoardSaddleCam:
        return 'OnBoard Under-Saddle Cam';
      case BroadcastCameraType.finishLineOverhead:
        return 'Finish Line Overhead';
      case BroadcastCameraType.teamCarInterior:
        return 'Team Car Interior';
      case BroadcastCameraType.fixedClimbCornerCam:
        return 'Fixed Climb Hairpin Cam';
      case BroadcastCameraType.droneTrackingCam:
        return 'Cine-Drone Tracking Cam';
    }
  }

  /// Domyślny kąt widzenia obiektywu w stopniach.
  double get defaultFovDegrees {
    switch (this) {
      case BroadcastCameraType.heliCam1:
      case BroadcastCameraType.heliCam2:
      case BroadcastCameraType.heliCam3:
        return 38.0;
      case BroadcastCameraType.motoCamFront:
      case BroadcastCameraType.motoCamPeloton:
      case BroadcastCameraType.motoCamChase:
        return 62.0;
      case BroadcastCameraType.onBoardHandlebarsCam:
      case BroadcastCameraType.onBoardSaddleCam:
        return 140.0;
      case BroadcastCameraType.finishLineOverhead:
        return 52.0;
      case BroadcastCameraType.teamCarInterior:
        return 95.0;
      case BroadcastCameraType.fixedClimbCornerCam:
        return 74.0;
      case BroadcastCameraType.droneTrackingCam:
        return 88.0;
    }
  }

  /// Koszt operacyjny pracy danej kamery w EUR na minutę transmisji.
  double get defaultCostPerMinuteEur {
    switch (this) {
      case BroadcastCameraType.heliCam1:
      case BroadcastCameraType.heliCam2:
      case BroadcastCameraType.heliCam3:
        return 185.0;
      case BroadcastCameraType.motoCamFront:
      case BroadcastCameraType.motoCamPeloton:
      case BroadcastCameraType.motoCamChase:
        return 58.0;
      case BroadcastCameraType.onBoardHandlebarsCam:
      case BroadcastCameraType.onBoardSaddleCam:
        return 24.0;
      case BroadcastCameraType.finishLineOverhead:
        return 35.0;
      case BroadcastCameraType.teamCarInterior:
        return 18.0;
      case BroadcastCameraType.fixedClimbCornerCam:
        return 22.0;
      case BroadcastCameraType.droneTrackingCam:
        return 72.0;
    }
  }

  bool get isAerial =>
      this == BroadcastCameraType.heliCam1 ||
      this == BroadcastCameraType.heliCam2 ||
      this == BroadcastCameraType.heliCam3 ||
      this == BroadcastCameraType.droneTrackingCam;

  bool get isMoto =>
      this == BroadcastCameraType.motoCamFront ||
      this == BroadcastCameraType.motoCamPeloton ||
      this == BroadcastCameraType.motoCamChase;

  bool get isOnBoard =>
      this == BroadcastCameraType.onBoardHandlebarsCam ||
      this == BroadcastCameraType.onBoardSaddleCam;
}

/// Stan sygnału pojedynczej kamery w wozie transmisyjnym OB Van.
enum CameraSignalStatus {
  /// Kamera gotowa do użycia na monitorze podglądu.
  liveReady,

  /// Kamera aktualnie nadawana na głównym wyjściu (PROGRAM OUT).
  onAirProgram,

  /// Kamera załadowana na szynę podglądu (PREVIEW BUS).
  previewReady,

  /// Słabszy sygnał RF (np. głęboki las lub tunel), możliwe zakłócenia.
  signalDegraded,

  /// Chwilowa utrata sygnału RF / brak zasięgu przekaźnika.
  rfDropOut,

  /// Kamera w trybie czuwania (oszczędzanie baterii / paliwa).
  standby;

  String toJson() => name;

  static CameraSignalStatus fromJson(String value) {
    return CameraSignalStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CameraSignalStatus.liveReady,
    );
  }

  bool get isTransmitting =>
      this != CameraSignalStatus.rfDropOut &&
      this != CameraSignalStatus.standby;
}

/// Typ przejścia w mikserze wizji reżyserki telewizyjnej.
enum BroadcastTransitionType {
  /// Natychmiastowe cięcie (CUT).
  cut,

  /// Płynne przenikanie (DISSOLVE).
  dissolve,

  /// Przejście graficzne (WIPE).
  wipe,

  /// Przejście ze stingerem powtórkowym (REPLAY STINGER).
  replayStinger;

  String toJson() => name;

  static BroadcastTransitionType fromJson(String value) {
    return BroadcastTransitionType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BroadcastTransitionType.cut,
    );
  }

  int get defaultDurationMs {
    switch (this) {
      case BroadcastTransitionType.cut:
        return 0;
      case BroadcastTransitionType.dissolve:
        return 320;
      case BroadcastTransitionType.wipe:
        return 450;
      case BroadcastTransitionType.replayStinger:
        return 600;
    }
  }
}

/// Typ grafiki telewizyjnej wywoływanej przez reżysera na antenę.
enum TvGraphicOverlayType {
  /// Porównanie W/kg i tętna dwóch liderów w bezpośrednim pojedynku.
  riderWkgComparison,

  /// Interaktywny profil podjazdu 3D z pozostałym dystansem i nachyleniem.
  climb3dProfile,

  /// Powtórka kluczowej akcji w zwolnionym tempie (Slow-Mo Replay).
  slowMotionReplay,

  /// Różnica czasowa między grupami i wirtualny lider klasyfikacji generalnej.
  virtualGapAndTimeSplit,

  /// Pasek telemetrii na żywo (Waty, RPM, km/h, tętno).
  liveHeartRateAndPowerHud,

  /// Wektor wiatru bocznego i prędkość peletonu.
  pelotonSpeedAndWindVector,

  /// Tabela lotnej premii i klasyfikacji punktowej (Zielona Koszulka).
  intermediateSprintStandings,

  /// Baner premii górskiej KOM / QOM (Koszulka w Grochy).
  komMountainPointsBanner,

  /// Transkrypcja emocjonalnej komunikacji z radia drużynowego (Team Radio).
  teamRadioSubtitles,

  /// Dolna belka oficjalnego partnera transmisji / sponsora etapu.
  stageSponsorLowerThird;

  String toJson() => name;

  static TvGraphicOverlayType fromJson(String value) {
    return TvGraphicOverlayType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TvGraphicOverlayType.virtualGapAndTimeSplit,
    );
  }

  String get displayNamePl {
    switch (this) {
      case TvGraphicOverlayType.riderWkgComparison:
        return 'Porównanie W/kg Liderów';
      case TvGraphicOverlayType.climb3dProfile:
        return 'Profil Podjazdu 3D';
      case TvGraphicOverlayType.slowMotionReplay:
        return 'Powtórka Slow-Motion';
      case TvGraphicOverlayType.virtualGapAndTimeSplit:
        return 'Różnica Czasu i Wirtualny Lider';
      case TvGraphicOverlayType.liveHeartRateAndPowerHud:
        return 'Telemetria Mocy & Tętna';
      case TvGraphicOverlayType.pelotonSpeedAndWindVector:
        return 'Prędkość & Wektor Wiatru';
      case TvGraphicOverlayType.intermediateSprintStandings:
        return 'Klasyfikacja Punktowa / Lotna Premia';
      case TvGraphicOverlayType.komMountainPointsBanner:
        return 'Premia Górska (KOM/QOM)';
      case TvGraphicOverlayType.teamRadioSubtitles:
        return 'Napisy Team Radio';
      case TvGraphicOverlayType.stageSponsorLowerThird:
        return 'Belka Sponsora Transmisji';
    }
  }

  String get displayNameEn {
    switch (this) {
      case TvGraphicOverlayType.riderWkgComparison:
        return 'Leader W/kg Comparison';
      case TvGraphicOverlayType.climb3dProfile:
        return '3D Climb Profile';
      case TvGraphicOverlayType.slowMotionReplay:
        return 'Slow-Motion Replay';
      case TvGraphicOverlayType.virtualGapAndTimeSplit:
        return 'Time Gap & Virtual GC';
      case TvGraphicOverlayType.liveHeartRateAndPowerHud:
        return 'Live Power & HR Telemetry';
      case TvGraphicOverlayType.pelotonSpeedAndWindVector:
        return 'Peloton Speed & Wind Vector';
      case TvGraphicOverlayType.intermediateSprintStandings:
        return 'Intermediate Sprint Standings';
      case TvGraphicOverlayType.komMountainPointsBanner:
        return 'KOM/QOM Mountain Banner';
      case TvGraphicOverlayType.teamRadioSubtitles:
        return 'Team Radio Subtitles';
      case TvGraphicOverlayType.stageSponsorLowerThird:
        return 'Broadcast Sponsor Lower Third';
    }
  }

  int get defaultDurationSeconds {
    switch (this) {
      case TvGraphicOverlayType.riderWkgComparison:
        return 12;
      case TvGraphicOverlayType.climb3dProfile:
        return 14;
      case TvGraphicOverlayType.slowMotionReplay:
        return 10;
      case TvGraphicOverlayType.virtualGapAndTimeSplit:
        return 9;
      case TvGraphicOverlayType.liveHeartRateAndPowerHud:
        return 11;
      case TvGraphicOverlayType.pelotonSpeedAndWindVector:
        return 8;
      case TvGraphicOverlayType.intermediateSprintStandings:
        return 10;
      case TvGraphicOverlayType.komMountainPointsBanner:
        return 9;
      case TvGraphicOverlayType.teamRadioSubtitles:
        return 7;
      case TvGraphicOverlayType.stageSponsorLowerThird:
        return 6;
    }
  }

  double get defaultProductionCostEur {
    switch (this) {
      case TvGraphicOverlayType.riderWkgComparison:
        return 420.0;
      case TvGraphicOverlayType.climb3dProfile:
        return 550.0;
      case TvGraphicOverlayType.slowMotionReplay:
        return 680.0;
      case TvGraphicOverlayType.virtualGapAndTimeSplit:
        return 210.0;
      case TvGraphicOverlayType.liveHeartRateAndPowerHud:
        return 340.0;
      case TvGraphicOverlayType.pelotonSpeedAndWindVector:
        return 260.0;
      case TvGraphicOverlayType.intermediateSprintStandings:
        return 180.0;
      case TvGraphicOverlayType.komMountainPointsBanner:
        return 190.0;
      case TvGraphicOverlayType.teamRadioSubtitles:
        return 150.0;
      case TvGraphicOverlayType.stageSponsorLowerThird:
        return 90.0;
    }
  }

  double get defaultDramaBoost {
    switch (this) {
      case TvGraphicOverlayType.riderWkgComparison:
        return 6.5;
      case TvGraphicOverlayType.climb3dProfile:
        return 4.5;
      case TvGraphicOverlayType.slowMotionReplay:
        return 7.5;
      case TvGraphicOverlayType.virtualGapAndTimeSplit:
        return 3.5;
      case TvGraphicOverlayType.liveHeartRateAndPowerHud:
        return 4.0;
      case TvGraphicOverlayType.pelotonSpeedAndWindVector:
        return 3.0;
      case TvGraphicOverlayType.intermediateSprintStandings:
        return 2.5;
      case TvGraphicOverlayType.komMountainPointsBanner:
        return 2.8;
      case TvGraphicOverlayType.teamRadioSubtitles:
        return 5.5;
      case TvGraphicOverlayType.stageSponsorLowerThird:
        return 0.5;
    }
  }
}

/// Status elementu w kolejce grafik telewizyjnych.
enum TvGraphicQueueStatus {
  /// Oczekuje w kolejce na wywołanie przez reżysera.
  queued,

  /// Aktualnie wyświetlana na antenie (PROGRAM OUT).
  onAir,

  /// Zakończyła emisję na antenie.
  completed,

  /// Anulowana przez reżysera przed emisją.
  cancelled;

  String toJson() => name;

  static TvGraphicQueueStatus fromJson(String value) {
    return TvGraphicQueueStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TvGraphicQueueStatus.queued,
    );
  }
}

/// Poziom emocji i oglądalności transmisji (Live TV Viewership & Drama Rating 0–100).
enum ViewershipDramaTier {
  /// Spokojna faza etapu (0–24).
  lull,

  /// Rosnące napięcie (25–49).
  building,

  /// Gorąca walka na trasie (50–74).
  heated,

  /// Thriller na finałowych kilometrach (75–89).
  thriller,

  /// Historyczny klasyk przyciągający rekordową widownię (90–100).
  historicClassic;

  String toJson() => name;

  static ViewershipDramaTier fromJson(String value) {
    return ViewershipDramaTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ViewershipDramaTier.building,
    );
  }

  static ViewershipDramaTier fromRating(double rating) {
    if (rating >= 90.0) return ViewershipDramaTier.historicClassic;
    if (rating >= 75.0) return ViewershipDramaTier.thriller;
    if (rating >= 50.0) return ViewershipDramaTier.heated;
    if (rating >= 25.0) return ViewershipDramaTier.building;
    return ViewershipDramaTier.lull;
  }

  String get displayNamePl {
    switch (this) {
      case ViewershipDramaTier.lull:
        return 'Spokojny Przejazd';
      case ViewershipDramaTier.building:
        return 'Budowanie Napięcia';
      case ViewershipDramaTier.heated:
        return 'Gorąca Rywalizacja';
      case ViewershipDramaTier.thriller:
        return 'Finałowy Thriller';
      case ViewershipDramaTier.historicClassic:
        return 'Historyczny Klasyk TV';
    }
  }

  String get displayNameEn {
    switch (this) {
      case ViewershipDramaTier.lull:
        return 'Quiet Cruise';
      case ViewershipDramaTier.building:
        return 'Building Tension';
      case ViewershipDramaTier.heated:
        return 'Heated Battle';
      case ViewershipDramaTier.thriller:
        return 'Finale Thriller';
      case ViewershipDramaTier.historicClassic:
        return 'Historic TV Classic';
    }
  }
}

/// Pojedynczy kanał jednej z 12 niezależnych kamer na trasie.
class BroadcastCameraFeed {
  const BroadcastCameraFeed({
    required this.cameraId,
    required this.type,
    required this.label,
    required this.signalStatus,
    required this.signalStrengthPercent,
    required this.batteryOrFuelPercent,
    required this.targetGroupLabel,
    required this.focusedRiderIds,
    required this.currentKilometer,
    required this.actionHeatScore,
    required this.isAudioActive,
    required this.operatingCostPerMinuteEur,
    required this.fovDegrees,
    required this.hasStabilizerLocked,
    required this.lastCutTimestampSec,
  });

  final String cameraId;
  final BroadcastCameraType type;
  final String label;
  final CameraSignalStatus signalStatus;
  final double signalStrengthPercent;
  final double batteryOrFuelPercent;
  final String targetGroupLabel;
  final List<String> focusedRiderIds;
  final double currentKilometer;
  final double actionHeatScore;
  final bool isAudioActive;
  final double operatingCostPerMinuteEur;
  final double fovDegrees;
  final bool hasStabilizerLocked;
  final int lastCutTimestampSec;

  bool get isAvailableForCut =>
      signalStatus != CameraSignalStatus.rfDropOut &&
      signalStatus != CameraSignalStatus.standby &&
      batteryOrFuelPercent > 0.5;

  BroadcastCameraFeed copyWith({
    String? cameraId,
    BroadcastCameraType? type,
    String? label,
    CameraSignalStatus? signalStatus,
    double? signalStrengthPercent,
    double? batteryOrFuelPercent,
    String? targetGroupLabel,
    List<String>? focusedRiderIds,
    double? currentKilometer,
    double? actionHeatScore,
    bool? isAudioActive,
    double? operatingCostPerMinuteEur,
    double? fovDegrees,
    bool? hasStabilizerLocked,
    int? lastCutTimestampSec,
  }) {
    return BroadcastCameraFeed(
      cameraId: cameraId ?? this.cameraId,
      type: type ?? this.type,
      label: label ?? this.label,
      signalStatus: signalStatus ?? this.signalStatus,
      signalStrengthPercent:
          (signalStrengthPercent ?? this.signalStrengthPercent)
              .clamp(0.0, 100.0),
      batteryOrFuelPercent:
          (batteryOrFuelPercent ?? this.batteryOrFuelPercent).clamp(0.0, 100.0),
      targetGroupLabel: targetGroupLabel ?? this.targetGroupLabel,
      focusedRiderIds: focusedRiderIds ?? List<String>.from(this.focusedRiderIds),
      currentKilometer: currentKilometer ?? this.currentKilometer,
      actionHeatScore:
          (actionHeatScore ?? this.actionHeatScore).clamp(0.0, 100.0),
      isAudioActive: isAudioActive ?? this.isAudioActive,
      operatingCostPerMinuteEur:
          operatingCostPerMinuteEur ?? this.operatingCostPerMinuteEur,
      fovDegrees: fovDegrees ?? this.fovDegrees,
      hasStabilizerLocked: hasStabilizerLocked ?? this.hasStabilizerLocked,
      lastCutTimestampSec: lastCutTimestampSec ?? this.lastCutTimestampSec,
    );
  }

  Map<String, dynamic> toJson() => {
        'cameraId': cameraId,
        'type': type.toJson(),
        'label': label,
        'signalStatus': signalStatus.toJson(),
        'signalStrengthPercent': signalStrengthPercent,
        'batteryOrFuelPercent': batteryOrFuelPercent,
        'targetGroupLabel': targetGroupLabel,
        'focusedRiderIds': focusedRiderIds,
        'currentKilometer': currentKilometer,
        'actionHeatScore': actionHeatScore,
        'isAudioActive': isAudioActive,
        'operatingCostPerMinuteEur': operatingCostPerMinuteEur,
        'fovDegrees': fovDegrees,
        'hasStabilizerLocked': hasStabilizerLocked,
        'lastCutTimestampSec': lastCutTimestampSec,
      };

  factory BroadcastCameraFeed.fromJson(Map<String, dynamic> json) {
    final type = BroadcastCameraType.fromJson(
      json['type'] as String? ?? 'heliCam1',
    );
    return BroadcastCameraFeed(
      cameraId: json['cameraId'] as String? ?? type.name,
      type: type,
      label: json['label'] as String? ?? type.shortCode,
      signalStatus: CameraSignalStatus.fromJson(
        json['signalStatus'] as String? ?? 'liveReady',
      ),
      signalStrengthPercent:
          ((json['signalStrengthPercent'] as num?)?.toDouble() ?? 95.0)
              .clamp(0.0, 100.0),
      batteryOrFuelPercent:
          ((json['batteryOrFuelPercent'] as num?)?.toDouble() ?? 100.0)
              .clamp(0.0, 100.0),
      targetGroupLabel: json['targetGroupLabel'] as String? ?? 'Peloton',
      focusedRiderIds: (json['focusedRiderIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      currentKilometer:
          (json['currentKilometer'] as num?)?.toDouble() ?? 0.0,
      actionHeatScore:
          ((json['actionHeatScore'] as num?)?.toDouble() ?? 35.0)
              .clamp(0.0, 100.0),
      isAudioActive: json['isAudioActive'] as bool? ?? true,
      operatingCostPerMinuteEur:
          (json['operatingCostPerMinuteEur'] as num?)?.toDouble() ??
              type.defaultCostPerMinuteEur,
      fovDegrees: (json['fovDegrees'] as num?)?.toDouble() ??
          type.defaultFovDegrees,
      hasStabilizerLocked: json['hasStabilizerLocked'] as bool? ?? true,
      lastCutTimestampSec:
          (json['lastCutTimestampSec'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Próbka telemetrii oglądalności i emocji w określonej sekundzie etapu.
class ViewershipTelemetrySample {
  const ViewershipTelemetrySample({
    required this.raceSecond,
    required this.dramaRating,
    required this.viewershipMillions,
    required this.activeCameraId,
  });

  final int raceSecond;
  final double dramaRating;
  final double viewershipMillions;
  final String activeCameraId;

  Map<String, dynamic> toJson() => {
        'raceSecond': raceSecond,
        'dramaRating': dramaRating,
        'viewershipMillions': viewershipMillions,
        'activeCameraId': activeCameraId,
      };

  factory ViewershipTelemetrySample.fromJson(Map<String, dynamic> json) {
    return ViewershipTelemetrySample(
      raceSecond: (json['raceSecond'] as num?)?.toInt() ?? 0,
      dramaRating:
          ((json['dramaRating'] as num?)?.toDouble() ?? 50.0).clamp(0.0, 100.0),
      viewershipMillions:
          math.max(0.0, (json['viewershipMillions'] as num?)?.toDouble() ?? 1.0),
      activeCameraId: json['activeCameraId'] as String? ?? 'heliCam1',
    );
  }
}

/// Wskaźnik emocji widzów oraz oglądalności na żywo (Live TV Viewership & Drama Rating 0–100).
class LiveTvViewershipAndDramaMetrics {
  const LiveTvViewershipAndDramaMetrics({
    required this.dramaRating,
    required this.viewershipMillions,
    required this.peakViewershipMillions,
    required this.audienceEngagementTrend,
    required this.directorSkillScore,
    required this.sponsorExposureScore,
    required this.adBreakPressure,
    required this.consecutiveDeadAirSeconds,
    required this.historySamples,
  });

  /// Główny wskaźnik emocji widzów w skali 0–100.
  final double dramaRating;

  /// Aktualna oglądalność międzynarodowa w milionach widzów.
  final double viewershipMillions;

  /// Rekord oglądalności osiągnięty podczas bieżącej transmisji (mln).
  final double peakViewershipMillions;

  /// Trend zaangażowania widzów na minutę (np. -5.0 do +5.0).
  final double audienceEngagementTrend;

  /// Ocena jakości reżyserii na żywo (0–100).
  final double directorSkillScore;

  /// Ekspozycja sponsorów i koszulek liderów (0–100).
  final double sponsorExposureScore;

  /// Presja na wyemitowanie bloku reklamowego (0–100).
  final double adBreakPressure;

  /// Liczba kolejnych sekund na kamerze bez akcji lub z utratą sygnału.
  final int consecutiveDeadAirSeconds;

  /// Historia próbek oglądalności do wykresów w reżyserce.
  final List<ViewershipTelemetrySample> historySamples;

  ViewershipDramaTier get dramaTier => ViewershipDramaTier.fromRating(dramaRating);

  LiveTvViewershipAndDramaMetrics copyWith({
    double? dramaRating,
    double? viewershipMillions,
    double? peakViewershipMillions,
    double? audienceEngagementTrend,
    double? directorSkillScore,
    double? sponsorExposureScore,
    double? adBreakPressure,
    int? consecutiveDeadAirSeconds,
    List<ViewershipTelemetrySample>? historySamples,
  }) {
    final clampedDrama =
        (dramaRating ?? this.dramaRating).clamp(0.0, 100.0);
    final currentViewers =
        math.max(0.1, viewershipMillions ?? this.viewershipMillions);
    final nextPeak = math.max(
      peakViewershipMillions ?? this.peakViewershipMillions,
      currentViewers,
    );
    return LiveTvViewershipAndDramaMetrics(
      dramaRating: clampedDrama,
      viewershipMillions: currentViewers,
      peakViewershipMillions: nextPeak,
      audienceEngagementTrend: audienceEngagementTrend ?? this.audienceEngagementTrend,
      directorSkillScore:
          (directorSkillScore ?? this.directorSkillScore).clamp(0.0, 100.0),
      sponsorExposureScore:
          (sponsorExposureScore ?? this.sponsorExposureScore).clamp(0.0, 100.0),
      adBreakPressure:
          (adBreakPressure ?? this.adBreakPressure).clamp(0.0, 100.0),
      consecutiveDeadAirSeconds:
          math.max(0, consecutiveDeadAirSeconds ?? this.consecutiveDeadAirSeconds),
      historySamples:
          historySamples ?? List<ViewershipTelemetrySample>.from(this.historySamples),
    );
  }

  Map<String, dynamic> toJson() => {
        'dramaRating': dramaRating,
        'viewershipMillions': viewershipMillions,
        'peakViewershipMillions': peakViewershipMillions,
        'audienceEngagementTrend': audienceEngagementTrend,
        'directorSkillScore': directorSkillScore,
        'sponsorExposureScore': sponsorExposureScore,
        'adBreakPressure': adBreakPressure,
        'consecutiveDeadAirSeconds': consecutiveDeadAirSeconds,
        'historySamples': historySamples.map((e) => e.toJson()).toList(),
      };

  factory LiveTvViewershipAndDramaMetrics.fromJson(Map<String, dynamic> json) {
    return LiveTvViewershipAndDramaMetrics(
      dramaRating:
          ((json['dramaRating'] as num?)?.toDouble() ?? 42.0).clamp(0.0, 100.0),
      viewershipMillions: math.max(
        0.1,
        (json['viewershipMillions'] as num?)?.toDouble() ?? 6.5,
      ),
      peakViewershipMillions: math.max(
        0.1,
        (json['peakViewershipMillions'] as num?)?.toDouble() ?? 6.5,
      ),
      audienceEngagementTrend:
          (json['audienceEngagementTrend'] as num?)?.toDouble() ?? 0.4,
      directorSkillScore:
          ((json['directorSkillScore'] as num?)?.toDouble() ?? 75.0)
              .clamp(0.0, 100.0),
      sponsorExposureScore:
          ((json['sponsorExposureScore'] as num?)?.toDouble() ?? 70.0)
              .clamp(0.0, 100.0),
      adBreakPressure:
          ((json['adBreakPressure'] as num?)?.toDouble() ?? 20.0)
              .clamp(0.0, 100.0),
      consecutiveDeadAirSeconds:
          math.max(0, (json['consecutiveDeadAirSeconds'] as num?)?.toInt() ?? 0),
      historySamples: (json['historySamples'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ViewershipTelemetrySample.fromJson)
              .toList() ??
          const <ViewershipTelemetrySample>[],
    );
  }
}

/// Budżet produkcyjny pojedynczej transmisji telewizyjnej etapu.
class BroadcastProductionBudget {
  const BroadcastProductionBudget({
    required this.allocatedStageBudgetEur,
    required this.spentToDateEur,
    required this.helicopterFlightCostEur,
    required this.motoCrewAndRfRelayCostEur,
    required this.graphicsAndReplayOpsCostEur,
    required this.overtimePenaltyEur,
    required this.viewershipBonusEarnedEur,
  });

  final double allocatedStageBudgetEur;
  final double spentToDateEur;
  final double helicopterFlightCostEur;
  final double motoCrewAndRfRelayCostEur;
  final double graphicsAndReplayOpsCostEur;
  final double overtimePenaltyEur;
  final double viewershipBonusEarnedEur;

  double get remainingBudgetEur =>
      allocatedStageBudgetEur + viewershipBonusEarnedEur - spentToDateEur;

  double get budgetUtilizationRatio {
    final effectiveCap = allocatedStageBudgetEur + viewershipBonusEarnedEur;
    if (effectiveCap <= 0.0) return 1.0;
    return spentToDateEur / effectiveCap;
  }

  bool get isOverBudget => remainingBudgetEur < 0.0;

  bool canAfford(double costEur) => remainingBudgetEur >= costEur;

  BroadcastProductionBudget recordCameraTick({
    required BroadcastCameraType cameraType,
    required double deltaSeconds,
  }) {
    final cost = (cameraType.defaultCostPerMinuteEur / 60.0) * deltaSeconds;
    final heliAdd = cameraType.isAerial ? cost : 0.0;
    final motoAdd = cameraType.isMoto ? cost : 0.0;
    return BroadcastProductionBudget(
      allocatedStageBudgetEur: allocatedStageBudgetEur,
      spentToDateEur: spentToDateEur + cost,
      helicopterFlightCostEur: helicopterFlightCostEur + heliAdd,
      motoCrewAndRfRelayCostEur: motoCrewAndRfRelayCostEur + motoAdd,
      graphicsAndReplayOpsCostEur: graphicsAndReplayOpsCostEur,
      overtimePenaltyEur: overtimePenaltyEur,
      viewershipBonusEarnedEur: viewershipBonusEarnedEur,
    );
  }

  BroadcastProductionBudget recordGraphicCost(double costEur) {
    return BroadcastProductionBudget(
      allocatedStageBudgetEur: allocatedStageBudgetEur,
      spentToDateEur: spentToDateEur + costEur,
      helicopterFlightCostEur: helicopterFlightCostEur,
      motoCrewAndRfRelayCostEur: motoCrewAndRfRelayCostEur,
      graphicsAndReplayOpsCostEur: graphicsAndReplayOpsCostEur + costEur,
      overtimePenaltyEur: overtimePenaltyEur,
      viewershipBonusEarnedEur: viewershipBonusEarnedEur,
    );
  }

  BroadcastProductionBudget recordViewershipBonus(double bonusEur) {
    return BroadcastProductionBudget(
      allocatedStageBudgetEur: allocatedStageBudgetEur,
      spentToDateEur: spentToDateEur,
      helicopterFlightCostEur: helicopterFlightCostEur,
      motoCrewAndRfRelayCostEur: motoCrewAndRfRelayCostEur,
      graphicsAndReplayOpsCostEur: graphicsAndReplayOpsCostEur,
      overtimePenaltyEur: overtimePenaltyEur,
      viewershipBonusEarnedEur: viewershipBonusEarnedEur + math.max(0.0, bonusEur),
    );
  }

  BroadcastProductionBudget copyWith({
    double? allocatedStageBudgetEur,
    double? spentToDateEur,
    double? helicopterFlightCostEur,
    double? motoCrewAndRfRelayCostEur,
    double? graphicsAndReplayOpsCostEur,
    double? overtimePenaltyEur,
    double? viewershipBonusEarnedEur,
  }) {
    return BroadcastProductionBudget(
      allocatedStageBudgetEur:
          allocatedStageBudgetEur ?? this.allocatedStageBudgetEur,
      spentToDateEur: spentToDateEur ?? this.spentToDateEur,
      helicopterFlightCostEur:
          helicopterFlightCostEur ?? this.helicopterFlightCostEur,
      motoCrewAndRfRelayCostEur:
          motoCrewAndRfRelayCostEur ?? this.motoCrewAndRfRelayCostEur,
      graphicsAndReplayOpsCostEur:
          graphicsAndReplayOpsCostEur ?? this.graphicsAndReplayOpsCostEur,
      overtimePenaltyEur: overtimePenaltyEur ?? this.overtimePenaltyEur,
      viewershipBonusEarnedEur:
          viewershipBonusEarnedEur ?? this.viewershipBonusEarnedEur,
    );
  }

  Map<String, dynamic> toJson() => {
        'allocatedStageBudgetEur': allocatedStageBudgetEur,
        'spentToDateEur': spentToDateEur,
        'helicopterFlightCostEur': helicopterFlightCostEur,
        'motoCrewAndRfRelayCostEur': motoCrewAndRfRelayCostEur,
        'graphicsAndReplayOpsCostEur': graphicsAndReplayOpsCostEur,
        'overtimePenaltyEur': overtimePenaltyEur,
        'viewershipBonusEarnedEur': viewershipBonusEarnedEur,
      };

  factory BroadcastProductionBudget.fromJson(Map<String, dynamic> json) {
    return BroadcastProductionBudget(
      allocatedStageBudgetEur:
          (json['allocatedStageBudgetEur'] as num?)?.toDouble() ?? 180000.0,
      spentToDateEur: (json['spentToDateEur'] as num?)?.toDouble() ?? 0.0,
      helicopterFlightCostEur:
          (json['helicopterFlightCostEur'] as num?)?.toDouble() ?? 0.0,
      motoCrewAndRfRelayCostEur:
          (json['motoCrewAndRfRelayCostEur'] as num?)?.toDouble() ?? 0.0,
      graphicsAndReplayOpsCostEur:
          (json['graphicsAndReplayOpsCostEur'] as num?)?.toDouble() ?? 0.0,
      overtimePenaltyEur:
          (json['overtimePenaltyEur'] as num?)?.toDouble() ?? 0.0,
      viewershipBonusEarnedEur:
          (json['viewershipBonusEarnedEur'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Element kolejki grafik telewizyjnych do wywołania na antenie przez reżysera.
class BroadcastGraphicOverlayItem {
  const BroadcastGraphicOverlayItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.primaryRiderId,
    this.secondaryRiderId,
    this.payloadData = const <String, dynamic>{},
    required this.durationSeconds,
    required this.remainingOnAirSeconds,
    required this.status,
    required this.priority,
    required this.productionCostEur,
    required this.dramaBoost,
    required this.queuedAtRaceSec,
    this.airedAtRaceSec,
  });

  final String id;
  final TvGraphicOverlayType type;
  final String title;
  final String subtitle;
  final String? primaryRiderId;
  final String? secondaryRiderId;
  final Map<String, dynamic> payloadData;
  final int durationSeconds;
  final int remainingOnAirSeconds;
  final TvGraphicQueueStatus status;
  final int priority;
  final double productionCostEur;
  final double dramaBoost;
  final int queuedAtRaceSec;
  final int? airedAtRaceSec;

  bool get isQueued => status == TvGraphicQueueStatus.queued;
  bool get isOnAir => status == TvGraphicQueueStatus.onAir;

  BroadcastGraphicOverlayItem copyWith({
    String? id,
    TvGraphicOverlayType? type,
    String? title,
    String? subtitle,
    String? primaryRiderId,
    String? secondaryRiderId,
    Map<String, dynamic>? payloadData,
    int? durationSeconds,
    int? remainingOnAirSeconds,
    TvGraphicQueueStatus? status,
    int? priority,
    double? productionCostEur,
    double? dramaBoost,
    int? queuedAtRaceSec,
    int? airedAtRaceSec,
  }) {
    return BroadcastGraphicOverlayItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      primaryRiderId: primaryRiderId ?? this.primaryRiderId,
      secondaryRiderId: secondaryRiderId ?? this.secondaryRiderId,
      payloadData: payloadData ?? Map<String, dynamic>.from(this.payloadData),
      durationSeconds: math.max(1, durationSeconds ?? this.durationSeconds),
      remainingOnAirSeconds:
          math.max(0, remainingOnAirSeconds ?? this.remainingOnAirSeconds),
      status: status ?? this.status,
      priority: (priority ?? this.priority).clamp(1, 5),
      productionCostEur:
          math.max(0.0, productionCostEur ?? this.productionCostEur),
      dramaBoost: dramaBoost ?? this.dramaBoost,
      queuedAtRaceSec: queuedAtRaceSec ?? this.queuedAtRaceSec,
      airedAtRaceSec: airedAtRaceSec ?? this.airedAtRaceSec,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toJson(),
        'title': title,
        'subtitle': subtitle,
        'primaryRiderId': primaryRiderId,
        'secondaryRiderId': secondaryRiderId,
        'payloadData': payloadData,
        'durationSeconds': durationSeconds,
        'remainingOnAirSeconds': remainingOnAirSeconds,
        'status': status.toJson(),
        'priority': priority,
        'productionCostEur': productionCostEur,
        'dramaBoost': dramaBoost,
        'queuedAtRaceSec': queuedAtRaceSec,
        'airedAtRaceSec': airedAtRaceSec,
      };

  factory BroadcastGraphicOverlayItem.fromJson(Map<String, dynamic> json) {
    final type = TvGraphicOverlayType.fromJson(
      json['type'] as String? ?? 'virtualGapAndTimeSplit',
    );
    final duration = math.max(
      1,
      (json['durationSeconds'] as num?)?.toInt() ?? type.defaultDurationSeconds,
    );
    return BroadcastGraphicOverlayItem(
      id: json['id'] as String? ?? 'gfx_${type.name}',
      type: type,
      title: json['title'] as String? ?? type.displayNameEn,
      subtitle: json['subtitle'] as String? ?? '',
      primaryRiderId: json['primaryRiderId'] as String?,
      secondaryRiderId: json['secondaryRiderId'] as String?,
      payloadData: (json['payloadData'] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
      durationSeconds: duration,
      remainingOnAirSeconds: math.max(
        0,
        (json['remainingOnAirSeconds'] as num?)?.toInt() ?? duration,
      ),
      status: TvGraphicQueueStatus.fromJson(
        json['status'] as String? ?? 'queued',
      ),
      priority: ((json['priority'] as num?)?.toInt() ?? 3).clamp(1, 5),
      productionCostEur:
          (json['productionCostEur'] as num?)?.toDouble() ??
              type.defaultProductionCostEur,
      dramaBoost: (json['dramaBoost'] as num?)?.toDouble() ??
          type.defaultDramaBoost,
      queuedAtRaceSec: (json['queuedAtRaceSec'] as num?)?.toInt() ?? 0,
      airedAtRaceSec: (json['airedAtRaceSec'] as num?)?.toInt(),
    );
  }
}

/// Główny model danych trybu Reżysera Transmisji Telewizyjnej na Żywo
/// (inspirowany pracą reżysera sygnału międzynarodowego Tour de France).
class TvDirectorLiveProductionModel {
  const TvDirectorLiveProductionModel({
    required this.productionId,
    required this.raceName,
    required this.stageTitle,
    required this.stageKilometersTotal,
    required this.currentRaceSecond,
    required this.isLiveOnAir,
    required this.isCommercialBreakActive,
    required this.cameraFeeds,
    required this.programCameraId,
    required this.previewCameraId,
    required this.sixMonitorDeckIds,
    required this.lastTransitionType,
    required this.lastTransitionDurationMs,
    required this.totalCameraCuts,
    required this.capturedPeakMomentsCount,
    required this.missedActionEventsCount,
    required this.viewershipMetrics,
    required this.productionBudget,
    required this.graphicsQueue,
  });

  final String productionId;
  final String raceName;
  final String stageTitle;
  final double stageKilometersTotal;
  final int currentRaceSecond;
  final bool isLiveOnAir;
  final bool isCommercialBreakActive;

  /// Lista 12 niezależnych kamer rozlokowanych na trasie wyścigu.
  final List<BroadcastCameraFeed> cameraFeeds;

  /// ID kamery aktualnie nadawanej na wyjście główne (PROGRAM OUT).
  final String programCameraId;

  /// ID kamery przygotowanej na szynie podglądu (PREVIEW).
  final String previewCameraId;

  /// 6 identyfikatorów kamer przypisanych do dolnego rzędu monitorów podglądu.
  final List<String> sixMonitorDeckIds;

  final BroadcastTransitionType lastTransitionType;
  final int lastTransitionDurationMs;
  final int totalCameraCuts;
  final int capturedPeakMomentsCount;
  final int missedActionEventsCount;

  final LiveTvViewershipAndDramaMetrics viewershipMetrics;
  final BroadcastProductionBudget productionBudget;

  /// Kolejka grafik telewizyjnych (oczekujące, na antenie i wyemitowane).
  final List<BroadcastGraphicOverlayItem> graphicsQueue;

  /// Zwraca aktualnie nadawaną kamerę `PROGRAM OUT`.
  BroadcastCameraFeed get programCamera {
    return cameraFeeds.firstWhere(
      (cam) => cam.cameraId == programCameraId,
      orElse: () => cameraFeeds.first,
    );
  }

  /// Zwraca kamerę przygotowaną na szynie `PREVIEW`.
  BroadcastCameraFeed get previewCamera {
    return cameraFeeds.firstWhere(
      (cam) => cam.cameraId == previewCameraId,
      orElse: () =>
          cameraFeeds.length > 1 ? cameraFeeds[1] : cameraFeeds.first,
    );
  }

  /// Zwraca kamerę o najwyższym aktualnym wskaźniku akcji (`actionHeatScore`).
  BroadcastCameraFeed get hottestCameraFeed {
    final available =
        cameraFeeds.where((c) => c.isAvailableForCut).toList();
    if (available.isEmpty) return programCamera;
    available.sort((a, b) => b.actionHeatScore.compareTo(a.actionHeatScore));
    return available.first;
  }

  /// Zwraca listę 6 kamer przypisanych do dolnego panelu monitorów podglądu.
  List<BroadcastCameraFeed> get sixMonitorDeckFeeds {
    final result = <BroadcastCameraFeed>[];
    for (final id in sixMonitorDeckIds) {
      final found = cameraFeeds.where((c) => c.cameraId == id);
      if (found.isNotEmpty) {
        result.add(found.first);
      }
    }
    return result;
  }

  /// Aktualnie wyświetlana grafika na antenie (jeśli istnieje).
  BroadcastGraphicOverlayItem? get activeOnAirGraphic {
    for (final item in graphicsQueue) {
      if (item.isOnAir) return item;
    }
    return null;
  }

  /// Kolejka grafik oczekujących na wywołanie, posortowana po priorytecie.
  List<BroadcastGraphicOverlayItem> get pendingGraphicsQueue {
    final pending = graphicsQueue.where((g) => g.isQueued).toList();
    pending.sort((a, b) => b.priority.compareTo(a.priority));
    return pending;
  }

  /// Przełącza wybraną kamerę bezpośrednio na `PROGRAM OUT` z wybranym przejściem.
  TvDirectorLiveProductionModel switchProgramCamera(
    String targetCameraId, {
    BroadcastTransitionType transition = BroadcastTransitionType.cut,
    int? raceSecondOverride,
  }) {
    final targetIndex =
        cameraFeeds.indexWhere((c) => c.cameraId == targetCameraId);
    if (targetIndex == -1) return this;

    final targetFeed = cameraFeeds[targetIndex];
    if (!targetFeed.isAvailableForCut || targetCameraId == programCameraId) {
      return this;
    }

    final sec = raceSecondOverride ?? currentRaceSecond;
    final previousProgramId = programCameraId;

    final updatedFeeds = cameraFeeds.map((cam) {
      if (cam.cameraId == targetCameraId) {
        return cam.copyWith(
          signalStatus: CameraSignalStatus.onAirProgram,
          lastCutTimestampSec: sec,
        );
      }
      if (cam.cameraId == previousProgramId) {
        final nextStatus = cam.cameraId == previewCameraId
            ? CameraSignalStatus.previewReady
            : CameraSignalStatus.liveReady;
        return cam.copyWith(signalStatus: nextStatus);
      }
      return cam;
    }).toList();

    final caughtHotAction = targetFeed.actionHeatScore >= 70.0;
    final skillDelta = caughtHotAction ? 1.8 : -0.3;
    final dramaDelta = caughtHotAction ? 3.5 : 0.0;

    return copyWith(
      currentRaceSecond: sec,
      cameraFeeds: updatedFeeds,
      programCameraId: targetCameraId,
      lastTransitionType: transition,
      lastTransitionDurationMs: transition.defaultDurationMs,
      totalCameraCuts: totalCameraCuts + 1,
      capturedPeakMomentsCount:
          capturedPeakMomentsCount + (caughtHotAction ? 1 : 0),
      viewershipMetrics: viewershipMetrics.copyWith(
        dramaRating: viewershipMetrics.dramaRating + dramaDelta,
        directorSkillScore: viewershipMetrics.directorSkillScore + skillDelta,
        consecutiveDeadAirSeconds:
            caughtHotAction ? 0 : viewershipMetrics.consecutiveDeadAirSeconds,
      ),
    );
  }

  /// Ustawia kamerę na szynie podglądu (`PREVIEW`).
  TvDirectorLiveProductionModel cuePreviewCamera(String targetCameraId) {
    final exists = cameraFeeds.any((c) => c.cameraId == targetCameraId);
    if (!exists || targetCameraId == previewCameraId) return this;

    final updatedFeeds = cameraFeeds.map((cam) {
      if (cam.cameraId == targetCameraId &&
          cam.cameraId != programCameraId &&
          cam.isAvailableForCut) {
        return cam.copyWith(signalStatus: CameraSignalStatus.previewReady);
      }
      if (cam.cameraId == previewCameraId && cam.cameraId != programCameraId) {
        return cam.copyWith(signalStatus: CameraSignalStatus.liveReady);
      }
      return cam;
    }).toList();

    return copyWith(
      cameraFeeds: updatedFeeds,
      previewCameraId: targetCameraId,
    );
  }

  /// Wykonuje zamianę szyny `PREVIEW` z `PROGRAM OUT` (klasyczny przycisk TAKE).
  TvDirectorLiveProductionModel takePreviewToProgram({
    BroadcastTransitionType transition = BroadcastTransitionType.dissolve,
    int? raceSecondOverride,
  }) {
    final oldProgram = programCameraId;
    final switched = switchProgramCamera(
      previewCameraId,
      transition: transition,
      raceSecondOverride: raceSecondOverride,
    );
    return switched.cuePreviewCamera(oldProgram);
  }

  /// Przypisuje wybraną kamerę do jednego z 6 monitorów dolnego podglądu.
  TvDirectorLiveProductionModel assignMonitorDeckSlot(
    int slotIndex,
    String cameraId,
  ) {
    if (slotIndex < 0 || slotIndex >= 6) return this;
    if (!cameraFeeds.any((c) => c.cameraId == cameraId)) return this;
    final nextDeck = List<String>.from(sixMonitorDeckIds);
    while (nextDeck.length < 6) {
      nextDeck.add(cameraFeeds.first.cameraId);
    }
    nextDeck[slotIndex] = cameraId;
    return copyWith(sixMonitorDeckIds: nextDeck);
  }

  /// Dodaje nową grafikę telewizyjną do kolejki reżyserki.
  TvDirectorLiveProductionModel enqueueGraphic(
    BroadcastGraphicOverlayItem item,
  ) {
    final filtered = graphicsQueue.where((g) => g.id != item.id).toList();
    filtered.add(item);
    return copyWith(graphicsQueue: filtered);
  }

  /// Wywołuje grafikę z kolejki na antenę (`PROGRAM OUT`).
  TvDirectorLiveProductionModel triggerGraphicOnAir(
    String graphicId, {
    int? raceSecondOverride,
  }) {
    final targetIdx = graphicsQueue.indexWhere((g) => g.id == graphicId);
    if (targetIdx == -1) return this;

    final target = graphicsQueue[targetIdx];
    if (!target.isQueued) return this;
    if (!productionBudget.canAfford(target.productionCostEur)) return this;

    final sec = raceSecondOverride ?? currentRaceSecond;

    final updatedQueue = graphicsQueue.map((item) {
      if (item.isOnAir) {
        return item.copyWith(
          status: TvGraphicQueueStatus.completed,
          remainingOnAirSeconds: 0,
        );
      }
      if (item.id == graphicId) {
        return item.copyWith(
          status: TvGraphicQueueStatus.onAir,
          remainingOnAirSeconds: item.durationSeconds,
          airedAtRaceSec: sec,
        );
      }
      return item;
    }).toList();

    return copyWith(
      currentRaceSecond: sec,
      graphicsQueue: updatedQueue,
      productionBudget:
          productionBudget.recordGraphicCost(target.productionCostEur),
      viewershipMetrics: viewershipMetrics.copyWith(
        dramaRating: viewershipMetrics.dramaRating + target.dramaBoost,
        viewershipMillions:
            viewershipMetrics.viewershipMillions + (target.dramaBoost * 0.04),
        sponsorExposureScore: target.type ==
                TvGraphicOverlayType.stageSponsorLowerThird
            ? viewershipMetrics.sponsorExposureScore + 8.0
            : viewershipMetrics.sponsorExposureScore,
      ),
    );
  }

  /// Zdejmuje aktualnie wyświetlaną grafikę z anteny.
  TvDirectorLiveProductionModel dismissActiveGraphic() {
    final updatedQueue = graphicsQueue.map((item) {
      if (item.isOnAir) {
        return item.copyWith(
          status: TvGraphicQueueStatus.completed,
          remainingOnAirSeconds: 0,
        );
      }
      return item;
    }).toList();
    return copyWith(graphicsQueue: updatedQueue);
  }

  /// Usuwa oczekującą grafikę z kolejki.
  TvDirectorLiveProductionModel removeQueuedGraphic(String graphicId) {
    final updatedQueue = graphicsQueue.map((item) {
      if (item.id == graphicId && item.isQueued) {
        return item.copyWith(status: TvGraphicQueueStatus.cancelled);
      }
      return item;
    }).toList();
    return copyWith(graphicsQueue: updatedQueue);
  }

  /// Aktualizuje stan produkcji telewizyjnej o kolejną sekundę wyścigu na żywo.
  TvDirectorLiveProductionModel tickSecond({
    int deltaSeconds = 1,
    double stageActionIntensity = 50.0,
  }) {
    if (deltaSeconds <= 0 || !isLiveOnAir) return this;

    final nextSec = currentRaceSecond + deltaSeconds;
    final activeCam = programCamera;
    final hottestCam = hottestCameraFeed;

    // Aktualizacja kolejki grafik na antenie.
    final updatedQueue = graphicsQueue.map((item) {
      if (!item.isOnAir) return item;
      final remaining = item.remainingOnAirSeconds - deltaSeconds;
      if (remaining <= 0) {
        return item.copyWith(
          status: TvGraphicQueueStatus.completed,
          remainingOnAirSeconds: 0,
        );
      }
      return item.copyWith(remainingOnAirSeconds: remaining);
    }).toList();

    // Koszt pracy aktywnej kamery oraz bonus za wysoką oglądalność.
    var nextBudget = productionBudget.recordCameraTick(
      cameraType: activeCam.type,
      deltaSeconds: deltaSeconds.toDouble(),
    );

    final isDeadAir = !activeCam.isAvailableForCut ||
        (hottestCam.actionHeatScore - activeCam.actionHeatScore > 32.0);

    final nextDeadAirSec =
        isDeadAir ? viewershipMetrics.consecutiveDeadAirSeconds + deltaSeconds : 0;
    final missedPeak =
        isDeadAir && hottestCam.actionHeatScore >= 80.0 ? 1 : 0;

    final dramaDelta = isDeadAir
        ? -0.45 * deltaSeconds
        : ((activeCam.actionHeatScore * 0.6 + stageActionIntensity * 0.4) -
                viewershipMetrics.dramaRating) *
            0.05;

    final nextDrama =
        (viewershipMetrics.dramaRating + dramaDelta).clamp(0.0, 100.0);
    final viewersDelta = (nextDrama - 45.0) * 0.003 * deltaSeconds;
    final nextViewers =
        math.max(0.5, viewershipMetrics.viewershipMillions + viewersDelta);

    if (nextDrama >= 75.0) {
      nextBudget = nextBudget.recordViewershipBonus(12.0 * deltaSeconds);
    }

    final samples =
        List<ViewershipTelemetrySample>.from(viewershipMetrics.historySamples);
    if (nextSec % 15 == 0) {
      samples.add(
        ViewershipTelemetrySample(
          raceSecond: nextSec,
          dramaRating: nextDrama,
          viewershipMillions: nextViewers,
          activeCameraId: activeCam.cameraId,
        ),
      );
      if (samples.length > 240) {
        samples.removeAt(0);
      }
    }

    return copyWith(
      currentRaceSecond: nextSec,
      missedActionEventsCount: missedActionEventsCount + missedPeak,
      graphicsQueue: updatedQueue,
      productionBudget: nextBudget,
      viewershipMetrics: viewershipMetrics.copyWith(
        dramaRating: nextDrama,
        viewershipMillions: nextViewers,
        audienceEngagementTrend: viewersDelta * 60.0,
        directorSkillScore: isDeadAir
            ? viewershipMetrics.directorSkillScore - 0.15 * deltaSeconds
            : viewershipMetrics.directorSkillScore + 0.05 * deltaSeconds,
        adBreakPressure: isCommercialBreakActive
            ? 0.0
            : viewershipMetrics.adBreakPressure + 0.04 * deltaSeconds,
        consecutiveDeadAirSeconds: nextDeadAirSec,
        historySamples: samples,
      ),
    );
  }

  /// Tworzy kompletny, gotowy do gry zestaw 12 kamer, budżetu i grafik dla etapu Tour de France.
  factory TvDirectorLiveProductionModel.createDefaultTourDeFranceStage({
    String productionId = 'tdf_world_feed_stage_17',
    String raceName = 'Tour de France — International World Feed',
    String stageTitle = 'Etap 17: Saint-Gervais → Courchevel (Col de la Loze)',
    double stageKilometersTotal = 165.7,
    double allocatedBudgetEur = 220000.0,
  }) {
    final defaultCameras = <BroadcastCameraFeed>[
      const BroadcastCameraFeed(
        cameraId: 'heliCam1',
        type: BroadcastCameraType.heliCam1,
        label: 'HELI 1',
        signalStatus: CameraSignalStatus.onAirProgram,
        signalStrengthPercent: 98.0,
        batteryOrFuelPercent: 86.0,
        targetGroupLabel: 'Breakaway (4 riders)',
        focusedRiderIds: ['rider_break_1', 'rider_break_2'],
        currentKilometer: 112.4,
        actionHeatScore: 68.0,
        isAudioActive: true,
        operatingCostPerMinuteEur: 185.0,
        fovDegrees: 38.0,
        hasStabilizerLocked: true,
        lastCutTimestampSec: 0,
      ),
      const BroadcastCameraFeed(
        cameraId: 'heliCam2',
        type: BroadcastCameraType.heliCam2,
        label: 'HELI 2',
        signalStatus: CameraSignalStatus.previewReady,
        signalStrengthPercent: 96.0,
        batteryOrFuelPercent: 84.0,
        targetGroupLabel: 'Yellow Jersey Peloton',
        focusedRiderIds: ['rider_gc_1', 'rider_gc_2'],
        currentKilometer: 109.1,
        actionHeatScore: 62.0,
        isAudioActive: false,
        operatingCostPerMinuteEur: 185.0,
        fovDegrees: 38.0,
        hasStabilizerLocked: true,
        lastCutTimestampSec: 0,
      ),
      const BroadcastCameraFeed(
        cameraId: 'heliCam3',
        type: BroadcastCameraType.heliCam3,
        label: 'HELI 3',
        signalStatus: CameraSignalStatus.liveReady,
        signalStrengthPercent: 94.0,
        batteryOrFuelPercent: 90.0,
        targetGroupLabel: 'Col de la Loze Ridge',
        focusedRiderIds: [],
        currentKilometer: 148.0,
        actionHeatScore: 44.0,
        isAudioActive: false,
        operatingCostPerMinuteEur: 185.0,
        fovDegrees: 42.0,
        hasStabilizerLocked: true,
        lastCutTimestampSec: 0,
      ),
      const BroadcastCameraFeed(
        cameraId: 'motoCamFront',
        type: BroadcastCameraType.motoCamFront,
        label: 'MOTO FRONT',
        signalStatus: CameraSignalStatus.liveReady,
        signalStrengthPercent: 91.0,
        batteryOrFuelPercent: 78.0,
        targetGroupLabel: 'Breakaway Lead',
        focusedRiderIds: ['rider_break_1'],
        currentKilometer: 112.5,
        actionHeatScore: 74.0,
        isAudioActive: true,
        operatingCostPerMinuteEur: 58.0,
        fovDegrees: 62.0,
        hasStabilizerLocked: true,
        lastCutTimestampSec: 0,
      ),
      const BroadcastCameraFeed(
        cameraId: 'motoCamPeloton',
        type: BroadcastCameraType.motoCamPeloton,
        label: 'MOTO PELOTON',
        signalStatus: CameraSignalStatus.liveReady,
        signalStrengthPercent: 89.0,
        batteryOrFuelPercent: 75.0,
        targetGroupLabel: 'GC Favorites Train',
        focusedRiderIds: ['rider_gc_1', 'rider_gc_2'],
        currentKilometer: 109.2,
        actionHeatScore: 79.0,
        isAudioActive: true,
        operatingCostPerMinuteEur: 58.0,
        fovDegrees: 62.0,
        hasStabilizerLocked: true,
        lastCutTimestampSec: 0,
      ),
      const BroadcastCameraFeed(
        cameraId: 'motoCamChase',
        type: BroadcastCameraType.motoCamChase,
        label: 'MOTO CHASE',
        signalStatus: CameraSignalStatus.liveReady,
        signalStrengthPercent: 87.0,
        batteryOrFuelPercent: 80.0,
        targetGroupLabel: 'Counter-Attack Group',
        focusedRiderIds: ['rider_chase_1'],
        currentKilometer: 110.6,
        actionHeatScore: 71.0,
        isAudioActive: true,
        operatingCostPerMinuteEur: 58.0,
        fovDegrees: 62.0,
        hasStabilizerLocked: true,
        lastCutTimestampSec: 0,
      ),
      const BroadcastCameraFeed(
        cameraId: 'onBoardHandlebarsCam',
        type: BroadcastCameraType.onBoardHandlebarsCam,
        label: 'ONBOARD BAR',
        signalStatus: CameraSignalStatus.liveReady,
        signalStrengthPercent: 82.0,
        batteryOrFuelPercent: 68.0,
        targetGroupLabel: 'Peloton Sprint / Climb POV',
        focusedRiderIds: ['rider_gc_1'],
        currentKilometer: 109.2,
        actionHeatScore: 66.0,
        isAudioActive: true,
        operatingCostPerMinuteEur: 24.0,
        fovDegrees: 140.0,
        hasStabilizerLocked: true,
        lastCutTimestampSec: 0,
      ),
      const BroadcastCameraFeed(
        cameraId: 'onBoardSaddleCam',
        type: BroadcastCameraType.onBoardSaddleCam,
        label: 'ONBOARD SADDLE',
        signalStatus: CameraSignalStatus.liveReady,
        signalStrengthPercent: 84.0,
        batteryOrFuelPercent: 70.0,
        targetGroupLabel: 'Rear Wheel & Cassette POV',
        focusedRiderIds: ['rider_gc_2'],
        currentKilometer: 109.2,
        actionHeatScore: 59.0,
        isAudioActive: true,
        operatingCostPerMinuteEur: 24.0,
        fovDegrees: 140.0,
        hasStabilizerLocked: true,
        lastCutTimestampSec: 0,
      ),
      BroadcastCameraFeed(
        cameraId: 'finishLineOverhead',
        type: BroadcastCameraType.finishLineOverhead,
        label: 'FINISH OH',
        signalStatus: CameraSignalStatus.liveReady,
        signalStrengthPercent: 100.0,
        batteryOrFuelPercent: 100.0,
        targetGroupLabel: 'Courchevel Altiport Finish',
        focusedRiderIds: const [],
        currentKilometer: stageKilometersTotal,
        actionHeatScore: 25.0,
        isAudioActive: false,
        operatingCostPerMinuteEur: 35.0,
        fovDegrees: 52.0,
        hasStabilizerLocked: true,
        lastCutTimestampSec: 0,
      ),
      const BroadcastCameraFeed(
        cameraId: 'teamCarInterior',
        type: BroadcastCameraType.teamCarInterior,
        label: 'TEAM CAR',
        signalStatus: CameraSignalStatus.liveReady,
        signalStrengthPercent: 92.0,
        batteryOrFuelPercent: 95.0,
        targetGroupLabel: 'DS Car #1 Cockpit',
        focusedRiderIds: [],
        currentKilometer: 108.8,
        actionHeatScore: 52.0,
        isAudioActive: true,
        operatingCostPerMinuteEur: 18.0,
        fovDegrees: 95.0,
        hasStabilizerLocked: true,
        lastCutTimestampSec: 0,
      ),
      const BroadcastCameraFeed(
        cameraId: 'fixedClimbCornerCam',
        type: BroadcastCameraType.fixedClimbCornerCam,
        label: 'CLIMB CAM',
        signalStatus: CameraSignalStatus.liveReady,
        signalStrengthPercent: 99.0,
        batteryOrFuelPercent: 100.0,
        targetGroupLabel: 'Switchback #14 Spectator Zone',
        focusedRiderIds: [],
        currentKilometer: 138.0,
        actionHeatScore: 40.0,
        isAudioActive: true,
        operatingCostPerMinuteEur: 22.0,
        fovDegrees: 74.0,
        hasStabilizerLocked: true,
        lastCutTimestampSec: 0,
      ),
      const BroadcastCameraFeed(
        cameraId: 'droneTrackingCam',
        type: BroadcastCameraType.droneTrackingCam,
        label: 'CINE DRONE',
        signalStatus: CameraSignalStatus.liveReady,
        signalStrengthPercent: 90.0,
        batteryOrFuelPercent: 64.0,
        targetGroupLabel: 'Mountain Crest Tracking',
        focusedRiderIds: ['rider_break_1'],
        currentKilometer: 112.4,
        actionHeatScore: 65.0,
        isAudioActive: false,
        operatingCostPerMinuteEur: 72.0,
        fovDegrees: 88.0,
        hasStabilizerLocked: true,
        lastCutTimestampSec: 0,
      ),
    ];

    final defaultQueue = <BroadcastGraphicOverlayItem>[
      const BroadcastGraphicOverlayItem(
        id: 'gfx_wkg_battle_01',
        type: TvGraphicOverlayType.riderWkgComparison,
        title: 'GC DUEL: W/KG COMPARISON',
        subtitle: '6.42 W/kg vs 6.38 W/kg on 11.4% slope',
        primaryRiderId: 'rider_gc_1',
        secondaryRiderId: 'rider_gc_2',
        durationSeconds: 12,
        remainingOnAirSeconds: 12,
        status: TvGraphicQueueStatus.queued,
        priority: 5,
        productionCostEur: 420.0,
        dramaBoost: 6.5,
        queuedAtRaceSec: 0,
      ),
      const BroadcastGraphicOverlayItem(
        id: 'gfx_climb_3d_01',
        type: TvGraphicOverlayType.climb3dProfile,
        title: 'COL DE LA LOZE — 3D PROFILE',
        subtitle: '28.1 km @ 6.0% avg (max 24%)',
        durationSeconds: 14,
        remainingOnAirSeconds: 14,
        status: TvGraphicQueueStatus.queued,
        priority: 4,
        productionCostEur: 550.0,
        dramaBoost: 4.5,
        queuedAtRaceSec: 0,
      ),
      const BroadcastGraphicOverlayItem(
        id: 'gfx_gap_split_01',
        type: TvGraphicOverlayType.virtualGapAndTimeSplit,
        title: 'VIRTUAL YELLOW JERSEY GAP',
        subtitle: 'Breakaway +2:48 ahead of GC Peloton',
        durationSeconds: 9,
        remainingOnAirSeconds: 9,
        status: TvGraphicQueueStatus.queued,
        priority: 3,
        productionCostEur: 210.0,
        dramaBoost: 3.5,
        queuedAtRaceSec: 0,
      ),
    ];

    return TvDirectorLiveProductionModel(
      productionId: productionId,
      raceName: raceName,
      stageTitle: stageTitle,
      stageKilometersTotal: stageKilometersTotal,
      currentRaceSecond: 0,
      isLiveOnAir: true,
      isCommercialBreakActive: false,
      cameraFeeds: defaultCameras,
      programCameraId: 'heliCam1',
      previewCameraId: 'heliCam2',
      sixMonitorDeckIds: const [
        'motoCamFront',
        'motoCamPeloton',
        'motoCamChase',
        'onBoardHandlebarsCam',
        'teamCarInterior',
        'finishLineOverhead',
      ],
      lastTransitionType: BroadcastTransitionType.cut,
      lastTransitionDurationMs: 0,
      totalCameraCuts: 0,
      capturedPeakMomentsCount: 0,
      missedActionEventsCount: 0,
      viewershipMetrics: const LiveTvViewershipAndDramaMetrics(
        dramaRating: 54.0,
        viewershipMillions: 9.8,
        peakViewershipMillions: 9.8,
        audienceEngagementTrend: 1.2,
        directorSkillScore: 80.0,
        sponsorExposureScore: 76.0,
        adBreakPressure: 18.0,
        consecutiveDeadAirSeconds: 0,
        historySamples: [],
      ),
      productionBudget: BroadcastProductionBudget(
        allocatedStageBudgetEur: allocatedBudgetEur,
        spentToDateEur: 0.0,
        helicopterFlightCostEur: 0.0,
        motoCrewAndRfRelayCostEur: 0.0,
        graphicsAndReplayOpsCostEur: 0.0,
        overtimePenaltyEur: 0.0,
        viewershipBonusEarnedEur: 0.0,
      ),
      graphicsQueue: defaultQueue,
    );
  }

  TvDirectorLiveProductionModel copyWith({
    String? productionId,
    String? raceName,
    String? stageTitle,
    double? stageKilometersTotal,
    int? currentRaceSecond,
    bool? isLiveOnAir,
    bool? isCommercialBreakActive,
    List<BroadcastCameraFeed>? cameraFeeds,
    String? programCameraId,
    String? previewCameraId,
    List<String>? sixMonitorDeckIds,
    BroadcastTransitionType? lastTransitionType,
    int? lastTransitionDurationMs,
    int? totalCameraCuts,
    int? capturedPeakMomentsCount,
    int? missedActionEventsCount,
    LiveTvViewershipAndDramaMetrics? viewershipMetrics,
    BroadcastProductionBudget? productionBudget,
    List<BroadcastGraphicOverlayItem>? graphicsQueue,
  }) {
    return TvDirectorLiveProductionModel(
      productionId: productionId ?? this.productionId,
      raceName: raceName ?? this.raceName,
      stageTitle: stageTitle ?? this.stageTitle,
      stageKilometersTotal:
          stageKilometersTotal ?? this.stageKilometersTotal,
      currentRaceSecond: currentRaceSecond ?? this.currentRaceSecond,
      isLiveOnAir: isLiveOnAir ?? this.isLiveOnAir,
      isCommercialBreakActive:
          isCommercialBreakActive ?? this.isCommercialBreakActive,
      cameraFeeds:
          cameraFeeds ?? List<BroadcastCameraFeed>.from(this.cameraFeeds),
      programCameraId: programCameraId ?? this.programCameraId,
      previewCameraId: previewCameraId ?? this.previewCameraId,
      sixMonitorDeckIds:
          sixMonitorDeckIds ?? List<String>.from(this.sixMonitorDeckIds),
      lastTransitionType: lastTransitionType ?? this.lastTransitionType,
      lastTransitionDurationMs:
          lastTransitionDurationMs ?? this.lastTransitionDurationMs,
      totalCameraCuts: totalCameraCuts ?? this.totalCameraCuts,
      capturedPeakMomentsCount:
          capturedPeakMomentsCount ?? this.capturedPeakMomentsCount,
      missedActionEventsCount:
          missedActionEventsCount ?? this.missedActionEventsCount,
      viewershipMetrics: viewershipMetrics ?? this.viewershipMetrics,
      productionBudget: productionBudget ?? this.productionBudget,
      graphicsQueue: graphicsQueue ??
          List<BroadcastGraphicOverlayItem>.from(this.graphicsQueue),
    );
  }

  Map<String, dynamic> toJson() => {
        'productionId': productionId,
        'raceName': raceName,
        'stageTitle': stageTitle,
        'stageKilometersTotal': stageKilometersTotal,
        'currentRaceSecond': currentRaceSecond,
        'isLiveOnAir': isLiveOnAir,
        'isCommercialBreakActive': isCommercialBreakActive,
        'cameraFeeds': cameraFeeds.map((e) => e.toJson()).toList(),
        'programCameraId': programCameraId,
        'previewCameraId': previewCameraId,
        'sixMonitorDeckIds': sixMonitorDeckIds,
        'lastTransitionType': lastTransitionType.toJson(),
        'lastTransitionDurationMs': lastTransitionDurationMs,
        'totalCameraCuts': totalCameraCuts,
        'capturedPeakMomentsCount': capturedPeakMomentsCount,
        'missedActionEventsCount': missedActionEventsCount,
        'viewershipMetrics': viewershipMetrics.toJson(),
        'productionBudget': productionBudget.toJson(),
        'graphicsQueue': graphicsQueue.map((e) => e.toJson()).toList(),
      };

  factory TvDirectorLiveProductionModel.fromJson(Map<String, dynamic> json) {
    final feeds = (json['cameraFeeds'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(BroadcastCameraFeed.fromJson)
            .toList() ??
        TvDirectorLiveProductionModel.createDefaultTourDeFranceStage()
            .cameraFeeds;

    return TvDirectorLiveProductionModel(
      productionId: json['productionId'] as String? ?? 'tdf_world_feed',
      raceName:
          json['raceName'] as String? ?? 'Tour de France — World Feed',
      stageTitle: json['stageTitle'] as String? ?? 'Mountain Stage',
      stageKilometersTotal:
          (json['stageKilometersTotal'] as num?)?.toDouble() ?? 165.0,
      currentRaceSecond: (json['currentRaceSecond'] as num?)?.toInt() ?? 0,
      isLiveOnAir: json['isLiveOnAir'] as bool? ?? true,
      isCommercialBreakActive:
          json['isCommercialBreakActive'] as bool? ?? false,
      cameraFeeds: feeds,
      programCameraId: json['programCameraId'] as String? ??
          (feeds.isNotEmpty ? feeds.first.cameraId : 'heliCam1'),
      previewCameraId: json['previewCameraId'] as String? ??
          (feeds.length > 1 ? feeds[1].cameraId : 'heliCam2'),
      sixMonitorDeckIds: (json['sixMonitorDeckIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'motoCamFront',
            'motoCamPeloton',
            'motoCamChase',
            'onBoardHandlebarsCam',
            'teamCarInterior',
            'finishLineOverhead',
          ],
      lastTransitionType: BroadcastTransitionType.fromJson(
        json['lastTransitionType'] as String? ?? 'cut',
      ),
      lastTransitionDurationMs:
          (json['lastTransitionDurationMs'] as num?)?.toInt() ?? 0,
      totalCameraCuts: (json['totalCameraCuts'] as num?)?.toInt() ?? 0,
      capturedPeakMomentsCount:
          (json['capturedPeakMomentsCount'] as num?)?.toInt() ?? 0,
      missedActionEventsCount:
          (json['missedActionEventsCount'] as num?)?.toInt() ?? 0,
      viewershipMetrics: json['viewershipMetrics'] is Map<String, dynamic>
          ? LiveTvViewershipAndDramaMetrics.fromJson(
              json['viewershipMetrics'] as Map<String, dynamic>,
            )
          : const LiveTvViewershipAndDramaMetrics(
              dramaRating: 50.0,
              viewershipMillions: 8.0,
              peakViewershipMillions: 8.0,
              audienceEngagementTrend: 0.0,
              directorSkillScore: 75.0,
              sponsorExposureScore: 70.0,
              adBreakPressure: 15.0,
              consecutiveDeadAirSeconds: 0,
              historySamples: [],
            ),
      productionBudget: json['productionBudget'] is Map<String, dynamic>
          ? BroadcastProductionBudget.fromJson(
              json['productionBudget'] as Map<String, dynamic>,
            )
          : const BroadcastProductionBudget(
              allocatedStageBudgetEur: 200000.0,
              spentToDateEur: 0.0,
              helicopterFlightCostEur: 0.0,
              motoCrewAndRfRelayCostEur: 0.0,
              graphicsAndReplayOpsCostEur: 0.0,
              overtimePenaltyEur: 0.0,
              viewershipBonusEarnedEur: 0.0,
            ),
      graphicsQueue: (json['graphicsQueue'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(BroadcastGraphicOverlayItem.fromJson)
              .toList() ??
          const <BroadcastGraphicOverlayItem>[],
    );
  }
}
