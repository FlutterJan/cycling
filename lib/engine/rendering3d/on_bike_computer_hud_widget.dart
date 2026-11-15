// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../state/race_simulation_notifier.dart';

// =============================================================================
// 1. MODELE I TYPY DANYCH KOMPUTERA ROWEROWEGO
// =============================================================================

/// Styl fizycznej obudowy i interfejsu komputera rowerowego.
enum BikeComputerModel {
  /// Styl Garmin Edge 1040/840: elegancka grafitowa obudowa, pasek statusu Garmin,
  /// zaokrąglona ramka z akcentem chromu i charakterystyczna siatka danych.
  garminEdge(
    label: 'Garmin Edge Series',
    brandName: 'GARMIN',
    modelTag: 'EDGE 1040 SOLAR',
  ),

  /// Styl Wahoo Elemnt Bolt/Roam: aerodynamiczna ścięta obudowa z górnym
  /// rzędem diod QuickLook LEDs i kontrastowym wyświetlaczem LCD.
  wahooElemnt(
    label: 'Wahoo ELEMNT ROAM',
    brandName: 'wahoo',
    modelTag: 'ELEMNT ROAM v2',
  );

  final String label;
  final String brandName;
  final String modelTag;

  const BikeComputerModel({
    required this.label,
    required this.brandName,
    required this.modelTag,
  });
}

/// Tryb wyświetlania ekranu komputera rowerowego.
enum BikeComputerLayoutMode {
  /// Pełna siatka danych telemetrycznych (Moc, W/kg, HR, Cad, Prędkość, Przełożenie) + ClimbPro.
  standard,

  /// Widok skupiony na profilu podjazdu (duży wykres ClimbPro) z podstawowymi danymi mocy.
  climbProFocus,

  /// Pasek kompaktowy o zmniejszonej wysokości (dla minimalizacji zasłaniania sceny 3D).
  compact,

  /// Zminimalizowana pigułka telemetryczna (widoczna tylko moc 3s i prędkość).
  minimized;

  BikeComputerLayoutMode next() {
    switch (this) {
      case BikeComputerLayoutMode.standard:
        return BikeComputerLayoutMode.climbProFocus;
      case BikeComputerLayoutMode.climbProFocus:
        return BikeComputerLayoutMode.compact;
      case BikeComputerLayoutMode.compact:
        return BikeComputerLayoutMode.minimized;
      case BikeComputerLayoutMode.minimized:
        return BikeComputerLayoutMode.standard;
    }
  }
}

/// Wynik doboru przełożenia napędu (Chainring & Cassette Sprocket).
class BikeGearSelection {
  final int frontTeeth;
  final int rearTeeth;
  final double gearRatio;
  final int cassetteIndex12; // 1 (najmniejsza zębatka 11T) do 12 (największa 34T)
  final bool isLargeChainring;

  const BikeGearSelection({
    required this.frontTeeth,
    required this.rearTeeth,
    required this.gearRatio,
    required this.cassetteIndex12,
    required this.isLargeChainring,
  });

  /// Tekstowa reprezentacja przełożenia (np. "54x14", "40x28").
  String get displayString => '${frontTeeth}x$rearTeeth';
}

/// Wycinek profilu wysokościowego do renderowania wykresu ClimbPro.
class ClimbProfileSlice {
  final double startDistanceMeters;
  final double lengthMeters;
  final double startElevationM;
  final double endElevationM;
  final double gradientPercent;
  final Color gradientColor;

  const ClimbProfileSlice({
    required this.startDistanceMeters,
    required this.lengthMeters,
    required this.startElevationM,
    required this.endElevationM,
    required this.gradientPercent,
    required this.gradientColor,
  });
}

/// Zagregowane dane podjazdu ClimbPro dla bieżącej pozycji kolarza.
class ClimbProData {
  final bool hasClimb;
  final bool isActivelyClimbing;
  final String climbTitle;
  final String categoryTag;
  final Color categoryColor;
  final double climbStartMeters;
  final double climbEndMeters;
  final double remainingDistKm;
  final double remainingElevationGainM;
  final double avgRemainingGradientPercent;
  final double currentGradientPercent;
  final double climbProgressFraction; // 0.0 - 1.0
  final List<ClimbProfileSlice> slices;

  const ClimbProData({
    required this.hasClimb,
    required this.isActivelyClimbing,
    required this.climbTitle,
    required this.categoryTag,
    required this.categoryColor,
    required this.climbStartMeters,
    required this.climbEndMeters,
    required this.remainingDistKm,
    required this.remainingElevationGainM,
    required this.avgRemainingGradientPercent,
    required this.currentGradientPercent,
    required this.climbProgressFraction,
    required this.slices,
  });

  /// Pusty obiekt, gdy na trasie nie ma zbliżającego się ani aktywnego podjazdu.
  factory ClimbProData.empty() {
    return const ClimbProData(
      hasClimb: false,
      isActivelyClimbing: false,
      climbTitle: 'Płaski Sektor',
      categoryTag: '',
      categoryColor: Colors.transparent,
      climbStartMeters: 0.0,
      climbEndMeters: 0.0,
      remainingDistKm: 0.0,
      remainingElevationGainM: 0.0,
      avgRemainingGradientPercent: 0.0,
      currentGradientPercent: 0.0,
      climbProgressFraction: 0.0,
      slices: [],
    );
  }
}

// =============================================================================
// 2. LOGIKA MATEMATYCZNA I PRZELICZNIKI SPORTOWE
// =============================================================================

/// Kalkulator realistycznego przełożenia napędu szosowego (Shimano Dura-Ace Di2 12s / SRAM Red AXS).
class BikeDrivetrainSimulator {
  // Standardowa korba WorldTour 54/40T (lub 52/36T w trudnych górach)
  final int bigRingTeeth;
  final int smallRingTeeth;

  // Kaseta 12-rzędowa 11-34T (11, 12, 13, 14, 15, 17, 19, 21, 24, 27, 30, 34)
  final List<int> cassetteSprockets;

  // Obwód koła szosowego 700x28c (ok. 2.105 m)
  final double wheelCircumferenceMeters;

  const BikeDrivetrainSimulator({
    this.bigRingTeeth = 54,
    this.smallRingTeeth = 40,
    this.cassetteSprockets = const [11, 12, 13, 14, 15, 17, 19, 21, 24, 27, 30, 34],
    this.wheelCircumferenceMeters = 2.105,
  });

  /// Wylicza najbardziej prawdopodobne przełożenie napędu na podstawie prędkości, kadencji i nachylenia.
  BikeGearSelection calculateGear({
    required double speedKmh,
    required int cadenceRpm,
    double gradientPercent = 0.0,
  }) {
    // 1. Przypadek braku pedałowania (zjazd na luzie / jazda bez napędzania)
    if (cadenceRpm <= 10) {
      if (speedKmh > 58.0) {
        return BikeGearSelection(
          frontTeeth: bigRingTeeth,
          rearTeeth: cassetteSprockets.first, // 54x11
          gearRatio: bigRingTeeth / cassetteSprockets.first,
          cassetteIndex12: 1,
          isLargeChainring: true,
        );
      } else if (speedKmh > 42.0) {
        return BikeGearSelection(
          frontTeeth: bigRingTeeth,
          rearTeeth: cassetteSprockets[3], // 54x14
          gearRatio: bigRingTeeth / cassetteSprockets[3],
          cassetteIndex12: 4,
          isLargeChainring: true,
        );
      } else if (speedKmh > 26.0) {
        return BikeGearSelection(
          frontTeeth: bigRingTeeth,
          rearTeeth: cassetteSprockets[6], // 54x19
          gearRatio: bigRingTeeth / cassetteSprockets[6],
          cassetteIndex12: 7,
          isLargeChainring: true,
        );
      } else {
        return BikeGearSelection(
          frontTeeth: smallRingTeeth,
          rearTeeth: cassetteSprockets[9], // 40x27
          gearRatio: smallRingTeeth / cassetteSprockets[9],
          cassetteIndex12: 10,
          isLargeChainring: false,
        );
      }
    }

    // 2. Normalne pedałowanie: wyliczenie docelowego rozwoju metrycznego na obrót
    // Prędkość w m/s
    final double speedMs = speedKmh / 3.6;
    // Droga na minutę / kadencja = droga na 1 obrót korby
    final double metersPerRev = (speedMs * 60.0) / cadenceRpm;
    final double targetRatio = (metersPerRev / wheelCircumferenceMeters).clamp(1.0, 5.2);

    // Wybór tarczy z przodu:
    // Na stromych podjazdach (> 5.0%) lub przy niskich prędkościach (< 22 km/h) preferowana mała tarcza
    final bool useSmallRing = gradientPercent >= 5.0 || (speedKmh < 24.0 && targetRatio < 2.5);
    final int activeFront = useSmallRing ? smallRingTeeth : bigRingTeeth;

    // Dobór zębatki z kasety minimalizującej różnicę przełożenia
    int bestRear = cassetteSprockets.first;
    double minDiff = double.infinity;
    int bestIndex = 0;

    for (int i = 0; i < cassetteSprockets.length; i++) {
      final int rear = cassetteSprockets[i];
      final double ratio = activeFront / rear;
      final double diff = (ratio - targetRatio).abs();
      if (diff < minDiff) {
        minDiff = diff;
        bestRear = rear;
        bestIndex = i;
      }
    }

    return BikeGearSelection(
      frontTeeth: activeFront,
      rearTeeth: bestRear,
      gearRatio: activeFront / bestRear,
      cassetteIndex12: bestIndex + 1,
      isLargeChainring: !useSmallRing,
    );
  }
}

/// Analizator podjazdów ClimbPro wzdłuż trasy wyścigu.
class ClimbProAnalyzer {
  const ClimbProAnalyzer._();

  /// Zwraca kolor nachylenia zgodny ze standardem Garmin ClimbPro.
  static Color getGradientColor(double gradientPercent) {
    if (gradientPercent < 0.0) {
      return const Color(0xFF38BDF8); // Błękitny zjazd
    } else if (gradientPercent < 3.0) {
      return const Color(0xFF10B981); // Zielony: łagodny 0-3%
    } else if (gradientPercent < 6.0) {
      return const Color(0xFFEAB308); // Żółty: umiarkowany 3-6%
    } else if (gradientPercent < 9.0) {
      return const Color(0xFFF97316); // Pomarańczowy: stromy 6-9%
    } else if (gradientPercent < 12.0) {
      return const Color(0xFFEF4444); // Czerwony: bardzo stromy 9-12%
    } else {
      return const Color(0xFF9333EA); // Fioletowy: ściana > 12%
    }
  }

  /// Zwraca kolor kategorii podjazdu.
  static Color getCategoryColor(SegmentClassification classification) {
    switch (classification) {
      case SegmentClassification.horsCategorie:
        return const Color(0xFFA855F7); // Fioletowy HC
      case SegmentClassification.cat1:
        return const Color(0xFFEF4444); // Czerwony Cat 1
      case SegmentClassification.cat2:
        return const Color(0xFFF97316); // Pomarańczowy Cat 2
      case SegmentClassification.cat3:
        return const Color(0xFFEAB308); // Żółty Cat 3
      case SegmentClassification.cat4:
        return const Color(0xFF10B981); // Zielony Cat 4
      default:
        return const Color(0xFF64748B);
    }
  }

  /// Buduje stan ClimbPro dla kolarza na podstawie listy segmentów etapu.
  static ClimbProData analyzeClimb({
    required double currentDistanceMeters,
    required List<StageSegment> segments,
    required double currentElevationMeters,
    required double currentGradientPercent,
  }) {
    if (segments.isEmpty) {
      return ClimbProData.empty();
    }

    final currentKm = currentDistanceMeters / 1000.0;

    // Krok 1: Wyszukiwanie aktywnego podjazdu (na którym kolarz aktualnie jedzie)
    StageSegment? activeClimbSeg;
    int climbIndexInStage = 0;
    int totalClimbsCount = 0;

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final bool isKom = seg.sprintOrKomClassification != SegmentClassification.none &&
          seg.sprintOrKomClassification != SegmentClassification.intermediateSprint &&
          seg.sprintOrKomClassification != SegmentClassification.finishLine;
      final bool isClimb = seg.isClimb || isKom;

      if (isClimb) {
        totalClimbsCount++;
        if (currentKm >= seg.startKm && currentKm <= seg.endKm) {
          activeClimbSeg = seg;
          climbIndexInStage = totalClimbsCount;
        }
      }
    }

    // Krok 2: Jeśli kolarz jest na podjeździe -> pełne dane ClimbPro
    if (activeClimbSeg != null) {
      final double climbStartM = activeClimbSeg.startKm * 1000.0;
      final double climbEndM = activeClimbSeg.endKm * 1000.0;
      final double climbLengthM = math.max(100.0, climbEndM - climbStartM);

      final double remainingDistM = math.max(0.0, climbEndM - currentDistanceMeters);
      final double remainingDistKm = remainingDistM / 1000.0;

      final double remainingElevGainM = math.max(0.0, activeClimbSeg.endElevationM - currentElevationMeters);
      final double avgRemainingGrade = (remainingDistM > 0.0) ? (remainingElevGainM / remainingDistM) * 100.0 : 0.0;
      final double progressFraction = ((currentDistanceMeters - climbStartM) / climbLengthM).clamp(0.0, 1.0);

      final catTag = activeClimbSeg.climbCategory != null ? 'KAT. ${activeClimbSeg.climbCategory}' : 'WSPINACZKA';
      final catColor = getCategoryColor(activeClimbSeg.sprintOrKomClassification);

      // Generowanie 6 mikrosegmentów profilu podjazdu
      final slices = <ClimbProfileSlice>[];
      const int sliceCount = 6;
      final sliceLen = climbLengthM / sliceCount;

      for (int i = 0; i < sliceCount; i++) {
        final sStart = climbStartM + (i * sliceLen);
        final t1 = i / sliceCount;
        final t2 = (i + 1) / sliceCount;
        final sElev1 = activeClimbSeg.startElevationM + (activeClimbSeg.endElevationM - activeClimbSeg.startElevationM) * t1;
        final sElev2 = activeClimbSeg.startElevationM + (activeClimbSeg.endElevationM - activeClimbSeg.startElevationM) * t2;

        // Lekka modulacja nachylenia dla autentycznego wykresu
        final pseudoVariance = (math.sin(i * 1.6 + activeClimbSeg.index) * 1.8);
        final grade = (activeClimbSeg.gradientPercent + pseudoVariance).clamp(1.5, 18.0);

        slices.add(ClimbProfileSlice(
          startDistanceMeters: sStart,
          lengthMeters: sliceLen,
          startElevationM: sElev1,
          endElevationM: sElev2,
          gradientPercent: grade,
          gradientColor: getGradientColor(grade),
        ));
      }

      return ClimbProData(
        hasClimb: true,
        isActivelyClimbing: true,
        climbTitle: 'Podjazd $climbIndexInStage/$totalClimbsCount',
        categoryTag: catTag,
        categoryColor: catColor,
        climbStartMeters: climbStartM,
        climbEndMeters: climbEndM,
        remainingDistKm: remainingDistKm,
        remainingElevationGainM: remainingElevGainM,
        avgRemainingGradientPercent: avgRemainingGrade,
        currentGradientPercent: currentGradientPercent,
        climbProgressFraction: progressFraction,
        slices: slices,
      );
    }

    // Krok 3: Jeśli kolarz nie jedzie pod górę, wyszukaj kolejny podjazd przed nim
    StageSegment? nextClimb;
    int nextClimbIndex = 0;
    int scannedClimbs = 0;

    for (final seg in segments) {
      final bool isKom = seg.sprintOrKomClassification != SegmentClassification.none &&
          seg.sprintOrKomClassification != SegmentClassification.intermediateSprint &&
          seg.sprintOrKomClassification != SegmentClassification.finishLine;
      final bool isClimb = seg.isClimb || isKom;

      if (isClimb) {
        scannedClimbs++;
        if (seg.startKm > currentKm && nextClimb == null) {
          nextClimb = seg;
          nextClimbIndex = scannedClimbs;
        }
      }
    }

    if (nextClimb != null) {
      final distToStartKm = nextClimb.startKm - currentKm;
      // Jeśli kolejny podjazd jest w zasięgu 15 km, pokaż baner przygotowawczy ClimbPro
      if (distToStartKm <= 15.0) {
        final catTag = nextClimb.climbCategory != null ? 'KAT. ${nextClimb.climbCategory}' : 'WSPINACZKA';
        final catColor = getCategoryColor(nextClimb.sprintOrKomClassification);

        return ClimbProData(
          hasClimb: true,
          isActivelyClimbing: false,
          climbTitle: 'Kolejny: Podjazd $nextClimbIndex/$totalClimbsCount',
          categoryTag: catTag,
          categoryColor: catColor,
          climbStartMeters: nextClimb.startKm * 1000.0,
          climbEndMeters: nextClimb.endKm * 1000.0,
          remainingDistKm: distToStartKm,
          remainingElevationGainM: nextClimb.elevationGainM,
          avgRemainingGradientPercent: nextClimb.gradientPercent,
          currentGradientPercent: currentGradientPercent,
          climbProgressFraction: 0.0,
          slices: [],
        );
      }
    }

    return ClimbProData.empty();
  }
}

// =============================================================================
// 3. GŁÓWNY WIDGET KOMPUTERA ROWEROWEGO (HUD)
// =============================================================================

/// Realistyczny widget komputera rowerowego (w stylu Garmin Edge 1040 / Wahoo Elemnt)
/// renderowany w rogu ekranu podczas śledzenia kamery wyścigowej kolarza gracza.
///
/// Wyświetla w czasie rzeczywistym:
/// - Moc 3s (W) z kolorystyką 7 stref Coggana i etykietą Z1-Z7,
/// - Moc względną W/kg,
/// - Tętno (bpm) z bijącą animacją serca i strefą tętna (Z1-Z5),
/// - Kadencję (rpm) z optymalnym zakresem pedałowania,
/// - Prędkość (km/h),
/// - Nachylenie (%) z kodem kolorystycznym,
/// - Pozostałe kilometry i profil podjazdu w stylu Garmin ClimbPro / Wahoo Summit,
/// - Aktualne przełożenie napędu (np. `54x14`, `40x28`).
class OnBikeComputerHudWidget extends StatefulWidget {
  final RiderPositionSnapshot? riderSnapshot;
  final RaceStage? stage;
  final List<StageSegment> segments;
  final bool isVisible;
  final BikeComputerModel model;
  final BikeComputerLayoutMode initialLayoutMode;
  final double scale;
  final int ftpWatts;
  final int maxHeartRateBpm;
  final VoidCallback? onCloseOrToggle;

  const OnBikeComputerHudWidget({
    super.key,
    required this.riderSnapshot,
    this.stage,
    this.segments = const [],
    this.isVisible = true,
    this.model = BikeComputerModel.garminEdge,
    this.initialLayoutMode = BikeComputerLayoutMode.standard,
    this.scale = 1.0,
    this.ftpWatts = 390,
    this.maxHeartRateBpm = 195,
    this.onCloseOrToggle,
  });

  @override
  State<OnBikeComputerHudWidget> createState() => _OnBikeComputerHudWidgetState();
}

class _OnBikeComputerHudWidgetState extends State<OnBikeComputerHudWidget> with SingleTickerProviderStateMixin {
  late BikeComputerLayoutMode _layoutMode;
  late final BikeDrivetrainSimulator _drivetrainSimulator;

  // Kolejka do wygładzania mocy 3-sekundowej (Rolling Average 3s)
  final Queue<(DateTime, int)> _powerHistory = Queue();
  int _cachedPower3s = 0;

  // Kontroler pulsowania serca i diod LED
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _layoutMode = widget.initialLayoutMode;
    _drivetrainSimulator = const BikeDrivetrainSimulator();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant OnBikeComputerHudWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.riderSnapshot != null) {
      _updatePower3s(widget.riderSnapshot!.powerWatts);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _updatePower3s(int currentWatts) {
    final now = DateTime.now();
    _powerHistory.addLast((now, currentWatts));

    // Usuwanie próbek starszych niż 3.0 sekundy
    while (_powerHistory.isNotEmpty && now.difference(_powerHistory.first.$1).inMilliseconds > 3000) {
      _powerHistory.removeFirst();
    }

    if (_powerHistory.isNotEmpty) {
      int sum = 0;
      for (final p in _powerHistory) {
        sum += p.$2;
      }
      _cachedPower3s = (sum / _powerHistory.length).round();
    } else {
      _cachedPower3s = currentWatts;
    }
  }

  void _cycleLayoutMode() {
    setState(() {
      _layoutMode = _layoutMode.next();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible || widget.riderSnapshot == null) {
      return const SizedBox.shrink();
    }

    final rider = widget.riderSnapshot!;

    // 1. Obliczenie mocy 3s i strefy Coggana (Z1 - Z7)
    final int power3s = _cachedPower3s > 0 ? _cachedPower3s : rider.powerWatts;
    final int cogganZone = _calculateCogganZone(power3s, widget.ftpWatts);
    final Color powerZoneColor = AppColors.getPowerZoneColor(cogganZone);
    final String powerZoneTag = 'Z$cogganZone ${_getCogganZoneLabel(cogganZone)}';

    // 2. Obliczenie strefy tętna (Z1 - Z5)
    final (int hrZone, Color hrColor, String hrLabel) = _calculateHeartRateZone(rider.heartRateBpm, widget.maxHeartRateBpm);

    // 3. Obliczenie biegu napędu (Chainring x Cassette)
    final gear = _drivetrainSimulator.calculateGear(
      speedKmh: rider.speedKmh,
      cadenceRpm: rider.cadenceRpm,
      gradientPercent: rider.currentGradientPercent,
    );

    // 4. Analiza podjazdu ClimbPro
    final climbPro = ClimbProAnalyzer.analyzeClimb(
      currentDistanceMeters: rider.distanceCoveredMeters,
      segments: widget.segments,
      currentElevationMeters: rider.elevationMeters,
      currentGradientPercent: rider.currentGradientPercent,
    );

    return Transform.scale(
      scale: widget.scale,
      alignment: Alignment.bottomLeft,
      child: GestureDetector(
        onTap: _cycleLayoutMode,
        child: _buildChassisContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Pasek diod Wahoo QuickLook LEDs (jeśli styl Wahoo i nie w trybie zminimalizowanym)
              if (widget.model == BikeComputerModel.wahooElemnt && _layoutMode != BikeComputerLayoutMode.minimized)
                _buildWahooLedMatrix(cogganZone, powerZoneColor),

              // 2. Górny pasek statusu (Status Bar: Time, Battery, ANT+ Sensors) - tylko gdy nie zminimalizowany
              if (_layoutMode != BikeComputerLayoutMode.minimized)
                _buildTopStatusBar(rider),

              // 3. Widok zawartości zależny od trybu ekranu
              if (_layoutMode == BikeComputerLayoutMode.standard)
                _buildStandardDataGrid(
                  rider: rider,
                  power3s: power3s,
                  powerZoneColor: powerZoneColor,
                  powerZoneTag: powerZoneTag,
                  hrZoneColor: hrColor,
                  hrZoneLabel: hrLabel,
                  gear: gear,
                  climbPro: climbPro,
                )
              else if (_layoutMode == BikeComputerLayoutMode.climbProFocus)
                _buildClimbProFocusView(
                  rider: rider,
                  power3s: power3s,
                  powerZoneColor: powerZoneColor,
                  gear: gear,
                  climbPro: climbPro,
                )
              else if (_layoutMode == BikeComputerLayoutMode.compact)
                _buildCompactHorizontalBar(
                  rider: rider,
                  power3s: power3s,
                  powerZoneColor: powerZoneColor,
                  hrZoneColor: hrColor,
                  gear: gear,
                )
              else
                _buildMinimizedPill(
                  power3s: power3s,
                  powerZoneColor: powerZoneColor,
                  speedKmh: rider.speedKmh,
                  gear: gear,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. OBUDOWA FIZYCZNA (CHASSIS & BEZEL)
  // ===========================================================================

  Widget _buildChassisContainer({required Widget child}) {
    final bool isGarmin = widget.model == BikeComputerModel.garminEdge;

    return Container(
      width: 310.0,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D14), // Głęboka czerń obudowy komputera
        borderRadius: BorderRadius.circular(isGarmin ? 22.0 : 16.0),
        border: Border.all(
          color: isGarmin ? const Color(0xFF2B3242) : const Color(0xFF1E2430),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 18.0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: (isGarmin ? const Color(0xFF38BDF8) : const Color(0xFF00E5FF)).withValues(alpha: 0.08),
            blurRadius: 4.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isGarmin ? 20.0 : 14.0),
        child: Stack(
          children: [
            // Subtelny gradient szkła ochronnego Gorilla Glass z powłoką antyrefleksyjną
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                    ],
                    stops: const [0.0, 0.35, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. PASEK STATUSU I DIODY WAHOO QUICKLOOK LEDS
  // ===========================================================================

  Widget _buildWahooLedMatrix(int currentZone, Color zoneColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(7, (index) {
          final zoneIdx = index + 1;
          final bool isActive = zoneIdx <= currentZone;
          final ledColor = isActive ? AppColors.getPowerZoneColor(zoneIdx) : const Color(0xFF1F2937);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3.5),
            width: 7.0,
            height: 7.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ledColor,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: ledColor.withValues(alpha: 0.8),
                        blurRadius: 6.0,
                        spreadRadius: 1.0,
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTopStatusBar(RiderPositionSnapshot rider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nazwa modelu lub serii (Garmin / Wahoo)
          Flexible(
            child: Text(
              widget.model.brandName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Pasek sensorów ANT+ / Bluetooth (Miernik mocy, Pas HR, Satelita GPS)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSensorPill(Icons.flash_on_rounded, 'PWR', const Color(0xFF38BDF8)),
              const SizedBox(width: 4),
              _buildSensorPill(Icons.favorite_rounded, 'HR', const Color(0xFFEF4444)),
              const SizedBox(width: 4),
              _buildSensorPill(Icons.gps_fixed_rounded, 'GPS', const Color(0xFF10B981)),
              const SizedBox(width: 6),

              // Bateria 86%
              Row(
                children: [
                  const Text(
                    '86%',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 8.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.battery_5_bar_rounded,
                    color: const Color(0xFF10B981).withValues(alpha: 0.9),
                    size: 13,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorPill(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 9, color: color),
        const SizedBox(width: 1),
      ],
    );
  }

  // ===========================================================================
  // 6. GŁÓWNA SIATKA DANYCH TELEMETRYCZNYCH (STANDARD GRID)
  // ===========================================================================

  Widget _buildStandardDataGrid({
    required RiderPositionSnapshot rider,
    required int power3s,
    required Color powerZoneColor,
    required String powerZoneTag,
    required Color hrZoneColor,
    required String hrZoneLabel,
    required BikeGearSelection gear,
    required ClimbProData climbPro,
  }) {
    return Column(
      children: [
        // RZĄD 1: MOC 3s (W) oraz W/KG
        Row(
          children: [
            Expanded(
              child: _buildDataTile(
                label: 'MOC 3s',
                unit: 'W',
                value: '$power3s',
                valueColor: powerZoneColor,
                badgeText: powerZoneTag,
                badgeColor: powerZoneColor,
                isLarge: true,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildDataTile(
                label: 'STOSUNEK',
                unit: 'W/KG',
                value: rider.wattsPerKg.toStringAsFixed(1),
                valueColor: Colors.white,
                isLarge: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // RZĄD 2: PRĘDKOŚĆ (KM/H) oraz KADENCJA (RPM)
        Row(
          children: [
            Expanded(
              child: _buildDataTile(
                label: 'PRĘDKOŚĆ',
                unit: 'KM/H',
                value: rider.speedKmh.toStringAsFixed(1),
                valueColor: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildDataTile(
                label: 'KADENCJA',
                unit: 'RPM',
                value: '${rider.cadenceRpm}',
                valueColor: (rider.cadenceRpm >= 85 && rider.cadenceRpm <= 100)
                    ? const Color(0xFF10B981)
                    : (rider.cadenceRpm > 0)
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // RZĄD 3: TĘTNO (BPM + STREFA) oraz PRZEŁOŻENIE NAPĘDU (np. 54x14)
        Row(
          children: [
            Expanded(
              child: _buildDataTile(
                label: 'TĘTNO',
                unit: 'BPM',
                value: '${rider.heartRateBpm}',
                valueColor: hrZoneColor,
                leadingWidget: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Icon(Icons.favorite_rounded, size: 11, color: hrZoneColor),
                  ),
                ),
                badgeText: hrZoneLabel,
                badgeColor: hrZoneColor,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildDataTile(
                label: 'PRZEŁOŻENIE',
                unit: 'DI2',
                value: gear.displayString,
                valueColor: const Color(0xFFE2E8F0),
                leadingWidget: const Icon(Icons.settings_suggest_rounded, size: 10, color: Color(0xFF94A3B8)),
                badgeText: gear.isLargeChainring ? 'DUŻY BLAT' : 'MAŁA TARCZA',
                badgeColor: const Color(0xFF334155),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // SEKCJA DOLNA: KARTA CLIMBPRO (PODJAZD I NACHYLENIE)
        _buildClimbProBanner(climbPro, rider.currentGradientPercent),
      ],
    );
  }

  // ===========================================================================
  // 7. WIDOKI ALTERNATYWNE: CLIMBPRO FOCUS, COMPACT & MINIMIZED
  // ===========================================================================

  Widget _buildClimbProFocusView({
    required RiderPositionSnapshot rider,
    required int power3s,
    required Color powerZoneColor,
    required BikeGearSelection gear,
    required ClimbProData climbPro,
  }) {
    return Column(
      children: [
        // Skrót telemetryczny na górze
        Row(
          children: [
            Expanded(
              child: Text(
                '${power3s}W (${rider.wattsPerKg.toStringAsFixed(1)} W/kg)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: powerZoneColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              gear.displayString,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11.0,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${rider.speedKmh.toStringAsFixed(1)} km/h',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Rozszerzona karta ClimbPro
        _buildClimbProBanner(climbPro, rider.currentGradientPercent, isExpanded: true),
      ],
    );
  }

  Widget _buildCompactHorizontalBar({
    required RiderPositionSnapshot rider,
    required int power3s,
    required Color powerZoneColor,
    required Color hrZoneColor,
    required BikeGearSelection gear,
  }) {
    return Row(
      children: [
        Expanded(child: _buildMiniCompactItem('PWR', '${power3s}W', powerZoneColor)),
        Expanded(child: _buildMiniCompactItem('W/KG', rider.wattsPerKg.toStringAsFixed(1), Colors.white)),
        Expanded(child: _buildMiniCompactItem('HR', '${rider.heartRateBpm}', hrZoneColor)),
        Expanded(child: _buildMiniCompactItem('CAD', '${rider.cadenceRpm}', const Color(0xFF10B981))),
        Expanded(child: _buildMiniCompactItem('GEAR', gear.displayString, const Color(0xFFE2E8F0))),
        Expanded(
          child: _buildMiniCompactItem(
            'GRADE',
            '${rider.currentGradientPercent >= 0 ? "+" : ""}${rider.currentGradientPercent.toStringAsFixed(1)}%',
            ClimbProAnalyzer.getGradientColor(rider.currentGradientPercent),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimizedPill({
    required int power3s,
    required Color powerZoneColor,
    required double speedKmh,
    required BikeGearSelection gear,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: powerZoneColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$power3s W',
                style: TextStyle(
                  color: powerZoneColor,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Text(
            gear.displayString,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${speedKmh.toStringAsFixed(1)} km/h',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCompactItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 7.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 8. KAFELEK DANYCH I BANER CLIMBPRO (GARMIN / WAHOO STYLE)
  // ===========================================================================

  Widget _buildDataTile({
    required String label,
    required String unit,
    required String value,
    required Color valueColor,
    String? badgeText,
    Color? badgeColor,
    Widget? leadingWidget,
    bool isLarge = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.5),
      decoration: BoxDecoration(
        color: const Color(0xFF111622),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: const Color(0xFF1E2638),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etykieta i jednostka
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 8.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: const TextStyle(
                  color: Color(0xFF4A5568),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Wartość liczbowa
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (leadingWidget != null) ...[
                leadingWidget,
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: isLarge ? 22.0 : 16.5,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          // Opcjonalna pigułka strefy (np. "Z4 PRÓG")
          if (badgeText != null) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.0),
              decoration: BoxDecoration(
                color: (badgeColor ?? const Color(0xFF334155)).withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: (badgeColor ?? const Color(0xFF334155)).withValues(alpha: 0.55),
                  width: 0.8,
                ),
              ),
              child: Text(
                badgeText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: badgeColor ?? const Color(0xFF94A3B8),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClimbProBanner(ClimbProData climbPro, double currentGradient, {bool isExpanded = false}) {
    final Color gradeColor = ClimbProAnalyzer.getGradientColor(currentGradient);

    return Container(
      padding: const EdgeInsets.all(7.5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141F),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: climbPro.isActivelyClimbing ? climbPro.categoryColor.withValues(alpha: 0.6) : const Color(0xFF232D3F),
          width: climbPro.isActivelyClimbing ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek ClimbPro: Tytuł, Kategoria, Nachylenie %
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.landscape_rounded,
                      size: 13,
                      color: climbPro.isActivelyClimbing ? climbPro.categoryColor : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        climbPro.climbTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (climbPro.categoryTag.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.8),
                        decoration: BoxDecoration(
                          color: climbPro.categoryColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(3.0),
                        ),
                        child: Text(
                          climbPro.categoryTag,
                          style: TextStyle(
                            color: climbPro.categoryColor,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),

              // Pigułka aktualnego nachylenia (%)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2.0),
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(5.0),
                  border: Border.all(color: gradeColor.withValues(alpha: 0.7), width: 0.8),
                ),
                child: Text(
                  '${currentGradient >= 0 ? "+" : ""}${currentGradient.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: gradeColor,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Metryki podjazdu: Pozostało km, Przewyższenie, Średnie nachylenie
          if (climbPro.hasClimb) ...[
            Row(
              children: [
                Expanded(
                  child: _buildClimbSubmetric(
                    'POZOSTAŁO',
                    '${climbPro.remainingDistKm.toStringAsFixed(1)} km',
                    const Color(0xFFE2E8F0),
                  ),
                ),
                Expanded(
                  child: _buildClimbSubmetric(
                    'WYS. (+)',
                    '+${climbPro.remainingElevationGainM.round()} m',
                    const Color(0xFFCBD5E1),
                  ),
                ),
                Expanded(
                  child: _buildClimbSubmetric(
                    'ŚR. NACH.',
                    '${climbPro.avgRemainingGradientPercent.toStringAsFixed(1)}%',
                    ClimbProAnalyzer.getGradientColor(climbPro.avgRemainingGradientPercent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Wykres profilu podjazdu (CustomPainter)
            SizedBox(
              height: isExpanded ? 44.0 : 26.0,
              child: CustomPaint(
                painter: _ClimbProProfilePainter(
                  slices: climbPro.slices,
                  progressFraction: climbPro.climbProgressFraction,
                  isActivelyClimbing: climbPro.isActivelyClimbing,
                ),
                size: Size.infinite,
              ),
            ),
          ] else ...[
            const Row(
              children: [
                Icon(Icons.trending_flat_rounded, size: 12, color: Color(0xFF64748B)),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Płaski profil trasy – brak podjazdów',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClimbSubmetric(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 7.0,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 10.0,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 9. METODY POMOCNICZE: STREFY MOCY I TĘTNA
  // ===========================================================================

  int _calculateCogganZone(int powerWatts, int ftpWatts) {
    if (ftpWatts <= 0) return 1;
    final double pct = (powerWatts / ftpWatts) * 100.0;
    if (pct < 55.0) return 1; // Active Recovery
    if (pct < 75.0) return 2; // Endurance
    if (pct < 90.0) return 3; // Tempo
    if (pct < 105.0) return 4; // Lactate Threshold / SweetSpot
    if (pct < 120.0) return 5; // VO2 Max
    if (pct < 150.0) return 6; // Anaerobic Capacity
    return 7; // Neuromuscular Sprint
  }

  String _getCogganZoneLabel(int zone) {
    switch (zone) {
      case 1:
        return 'REGEN';
      case 2:
        return 'TLEN';
      case 3:
        return 'TEMPO';
      case 4:
        return 'PRÓG';
      case 5:
        return 'VO2';
      case 6:
        return 'BEZTLEN';
      case 7:
        return 'SPRINT';
      default:
        return 'Z$zone';
    }
  }

  (int zone, Color color, String label) _calculateHeartRateZone(int hrBpm, int maxHrBpm) {
    if (maxHrBpm <= 0) return (1, const Color(0xFF64748B), 'Z1 REGEN');
    final double pct = (hrBpm / maxHrBpm) * 100.0;
    if (pct < 60.0) {
      return (1, const Color(0xFF64748B), 'Z1 REGEN');
    } else if (pct < 70.0) {
      return (2, const Color(0xFF3B82F6), 'Z2 TLEN');
    } else if (pct < 80.0) {
      return (3, const Color(0xFF10B981), 'Z3 TEMPO');
    } else if (pct < 90.0) {
      return (4, const Color(0xFFEAB308), 'Z4 PRÓG');
    } else {
      return (5, const Color(0xFFEF4444), 'Z5 MAX');
    }
  }
}

// =============================================================================
// 10. PAINTER MINI WYKRESU PROFILU PODJAZDU CLIMBPRO
// =============================================================================

class _ClimbProProfilePainter extends CustomPainter {
  final List<ClimbProfileSlice> slices;
  final double progressFraction;
  final bool isActivelyClimbing;

  _ClimbProProfilePainter({
    required this.slices,
    required this.progressFraction,
    required this.isActivelyClimbing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Tło siatki wykresu ClimbPro
    final bgPaint = Paint()..color = const Color(0xFF0A0D14);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(5.0)), bgPaint);

    if (slices.isEmpty) return;

    final double sliceWidth = w / slices.length;

    // Rysowanie segmentów profilu podjazdu z kolorami nachylenia
    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final double x1 = i * sliceWidth;
      final double x2 = (i + 1) * sliceWidth;

      // Wyznaczenie wysokości wierzchołka w profilu
      final double y1 = h - (10.0 + (i * (h - 14.0) / slices.length));
      final double y2 = h - (10.0 + ((i + 1) * (h - 14.0) / slices.length));

      final path = Path()
        ..moveTo(x1, h)
        ..lineTo(x1, y1)
        ..lineTo(x2, y2)
        ..lineTo(x2, h)
        ..close();

      final slicePaint = Paint()
        ..color = slice.gradientColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, slicePaint);

      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
    }

    // Rysowanie pinezki / znacznika pozycji kolarza na wykresie
    if (isActivelyClimbing) {
      final double riderX = (progressFraction * w).clamp(2.0, w - 2.0);

      // Interpolacja wysokości na profilu
      final int activeIndex = (progressFraction * slices.length).floor().clamp(0, slices.length - 1);
      final double riderY = h - (10.0 + ((activeIndex + 0.5) * (h - 14.0) / slices.length));

      // Pionowa linia pozycji
      final markerLinePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.6;
      canvas.drawLine(Offset(riderX, riderY - 4.0), Offset(riderX, h), markerLinePaint);

      // Świecąca kropka kolarza
      final glowPaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawCircle(Offset(riderX, riderY), 4.5, glowPaint);

      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(riderX, riderY), 2.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ClimbProProfilePainter oldDelegate) {
    return oldDelegate.progressFraction != progressFraction ||
        oldDelegate.slices.length != slices.length ||
        oldDelegate.isActivelyClimbing != isActivelyClimbing;
  }
}
