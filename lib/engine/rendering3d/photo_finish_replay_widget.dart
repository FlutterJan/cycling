// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/simulation/stage_results_calculator.dart';
import '../../models/race/race_stage.dart';

// =============================================================================
// 1. TYPY, STATUSY I MODELE DANYCH SYSTEMU PHOTO-FINISH
// =============================================================================

/// Status weryfikacji sędziowskiej panelu komisarzy UCI (Commissaires Panel).
enum PhotoFinishStatus {
  /// Fotokomórka poddawana szczegółowej analizie sędziowskiej w milisekundach.
  underReview(
    label: 'ANALIZA FOTOKOMÓRKI W TOKU...',
    badgeColor: Color(0xFFF59E0B),
    icon: Icons.hourglass_top_rounded,
  ),

  /// Oficjalny, zatwierdzony werdykt sędziowski – zwycięzca potwierdzony co do milimetra.
  officialConfirmed(
    label: 'OFICJALNY WERDYKT SĘDZIÓW UCI',
    badgeColor: Color(0xFF10B981),
    icon: Icons.verified_rounded,
  ),

  /// Złożony protest przez dyrektora sportowego rywala.
  protestFiled(
    label: 'PROTEST ZŁOŻONY PRZEZ ZESPÓŁ',
    badgeColor: Color(0xFFEF4444),
    icon: Icons.warning_amber_rounded,
  );

  final String label;
  final Color badgeColor;
  final IconData icon;

  const PhotoFinishStatus({
    required this.label,
    required this.badgeColor,
    required this.icon,
  });
}

/// Tryb matrycy i filtrów optycznych kamery szczelinowej (Line-Scan Camera).
enum PhotoFinishSensorMode {
  /// Standardowy, pełnokolorowy zapis szczelinowy (10 000 FPS).
  trueColorSlitScan(
    label: 'Kolor CCD (10k FPS)',
    description: 'Naturalna rejestracja barw strojów, rowerów i asfaltu.',
    icon: Icons.palette_outlined,
  ),

  /// Monochromatyczny skan w podczerwieni o wysokim kontraście (Infrared Monochrome).
  /// Służy sędziom do eliminacji cieni i precyzyjnego wyznaczenia krawędzi opony na białej linii.
  monochromeInfrared(
    label: 'Podczerwień IR (Sędziowski)',
    description: 'Maksymalny kontrast krawędzi opony na linii fotokomórki.',
    icon: Icons.filter_b_and_w_rounded,
  ),

  /// Filtr krawędziowy (Edge Contour Highlight) z uwypukleniem styku opony z laserem.
  edgeContour(
    label: 'Kontur Krawędzi',
    description: 'Wykrywanie obrysu ramy i przedniego koła co do mikrometra.',
    icon: Icons.blur_linear_rounded,
  );

  final String label;
  final String description;
  final IconData icon;

  const PhotoFinishSensorMode({
    required this.label,
    required this.description,
    required this.icon,
  });
}

/// Dane kolarza biorącego udział w finiszu uwiecznionego przez kamerę szczelinową.
class PhotoFinishRider {
  /// Oficjalna pozycja finiszowa (1, 2, 3...).
  final int rank;

  /// Identyfikator zawodnika.
  final String riderId;

  /// Imię i nazwisko kolarza (np. "Tadej Pogačar").
  final String riderName;

  /// Nazwa zespołu kolarskiego.
  final String teamName;

  /// Numer startowy (bib number).
  final int bibNumber;

  /// Kod ISO narodowości kolarza (np. "SLO", "DEN", "BEL").
  final String countryIso;

  /// Surowy czas przecięcia linii mety [s].
  final double finishTimeSeconds;

  /// Strata czasowa do zwycięzcy [s] (0.000 dla wygranego).
  final double gapToWinnerSeconds;

  /// Szacowana prędkość kolarza na kresce w kilometrach na godzinę [km/h].
  final double speedKmh;

  /// Główny kolor koszulki zespołu.
  final Color primaryJerseyColor;

  /// Pomocniczy kolor koszulki zespołu.
  final Color secondaryJerseyColor;

  /// Kolor ramy roweru.
  final Color bikeColor;

  /// Dodatkowe przesunięcie w milimetrach wynikające ze skutecznego rzutu rowerem na kreskę (Bike Throw).
  final double bikeThrowGainMm;

  /// Pozycja na szerokości szosy (od 0.0 - góra kadru/lewa strona do 1.0 - dół kadru/prawa strona).
  final double trackLaneY;

  const PhotoFinishRider({
    required this.rank,
    required this.riderId,
    required this.riderName,
    required this.teamName,
    required this.bibNumber,
    required this.countryIso,
    required this.finishTimeSeconds,
    required this.gapToWinnerSeconds,
    required this.speedKmh,
    required this.primaryJerseyColor,
    required this.secondaryJerseyColor,
    required this.bikeColor,
    this.bikeThrowGainMm = 180.0,
    this.trackLaneY = 0.5,
  });

  /// Strata w milisekundach [ms].
  double get gapMilliseconds => gapToWinnerSeconds * 1000.0;

  /// Różnica odległości do opony zwycięzcy w milimetrach [mm] przy danej prędkości finiszowej:
  /// d = v * t = (v_kmh / 3.6) * gap_seconds * 1000.
  double get gapMillimeters {
    if (gapToWinnerSeconds <= 0.0) return 0.0;
    final speedMs = speedKmh / 3.6;
    return speedMs * gapToWinnerSeconds * 1000.0;
  }

  /// Sformatowany tekst różnicy czasowej (np. "+0.004s" lub "ZWYCIĘZCA").
  String get formattedGapSeconds {
    if (rank == 1 || gapToWinnerSeconds <= 0.0) return '0.000s (Lider)';
    return '+${gapToWinnerSeconds.toStringAsFixed(3)}s';
  }

  /// Sformatowany tekst różnicy dystansowej w milimetrach lub centymetrach.
  String get formattedGapDistance {
    if (rank == 1 || gapToWinnerSeconds <= 0.0) return '0 mm';
    final mm = gapMillimeters;
    if (mm < 10.0) {
      return '+${mm.toStringAsFixed(1)} mm';
    } else if (mm < 100.0) {
      return '+${mm.toStringAsFixed(0)} mm';
    } else {
      return '+${(mm / 10.0).toStringAsFixed(1)} cm';
    }
  }

  PhotoFinishRider copyWith({
    int? rank,
    String? riderId,
    String? riderName,
    String? teamName,
    int? bibNumber,
    String? countryIso,
    double? finishTimeSeconds,
    double? gapToWinnerSeconds,
    double? speedKmh,
    Color? primaryJerseyColor,
    Color? secondaryJerseyColor,
    Color? bikeColor,
    double? bikeThrowGainMm,
    double? trackLaneY,
  }) {
    return PhotoFinishRider(
      rank: rank ?? this.rank,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      teamName: teamName ?? this.teamName,
      bibNumber: bibNumber ?? this.bibNumber,
      countryIso: countryIso ?? this.countryIso,
      finishTimeSeconds: finishTimeSeconds ?? this.finishTimeSeconds,
      gapToWinnerSeconds: gapToWinnerSeconds ?? this.gapToWinnerSeconds,
      speedKmh: speedKmh ?? this.speedKmh,
      primaryJerseyColor: primaryJerseyColor ?? this.primaryJerseyColor,
      secondaryJerseyColor: secondaryJerseyColor ?? this.secondaryJerseyColor,
      bikeColor: bikeColor ?? this.bikeColor,
      bikeThrowGainMm: bikeThrowGainMm ?? this.bikeThrowGainMm,
      trackLaneY: trackLaneY ?? this.trackLaneY,
    );
  }
}

/// Pełny zestaw danych sesji Photo-Finish dla rozstrzygnięcia finiszu etapu.
class PhotoFinishData {
  /// Próg czasowy aktywacji systemu Photo-Finish: różnica poniżej 0.15 sekundy (150 ms).
  static const double activationThresholdSeconds = 0.150;

  /// Nazwa etapu wyścigu.
  final String stageName;

  /// Numer etapu (np. 14).
  final int stageNumber;

  /// Miejscowość na linii mety.
  final String finishLocation;

  /// Średnia prędkość czołówki na kresce w km/h.
  final double finishSpeedKmh;

  /// Częstotliwość próbkowania kamery szczelinowej w Hz (np. 10 000 klatek na sekundę).
  final int cameraSamplingRateHz;

  /// Oficjalny status sędziowski.
  final PhotoFinishStatus status;

  /// Lista kolarzy uchwyconych na fotokomórce (posortowana według kolejności).
  final List<PhotoFinishRider> riders;

  /// Dodatkowa notatka sędziowska komisarza UCI.
  final String commissairesRuling;

  const PhotoFinishData({
    required this.stageName,
    required this.stageNumber,
    required this.finishLocation,
    required this.finishSpeedKmh,
    this.cameraSamplingRateHz = 10000,
    this.status = PhotoFinishStatus.officialConfirmed,
    required this.riders,
    required this.commissairesRuling,
  });

  /// Czy finisz kwalifikuje się do aktywacji Photo-Finish (różnica 1. i 2. miejsca < 0.15s).
  static bool isPhotoFinishRequired(double gapToSecondSeconds) {
    return gapToSecondSeconds >= 0.0 && gapToSecondSeconds < activationThresholdSeconds;
  }

  /// Zwycięzca etapu.
  PhotoFinishRider get winner => riders.first;

  /// Kolarz na drugim miejscu.
  PhotoFinishRider get secondPlace => riders.length > 1 ? riders[1] : riders.first;

  /// Różnica czasowa w sekundach pomiędzy zwycięzcą a drugim kolarzem.
  double get gapSecondsToSecondPlace {
    if (riders.length < 2) return 0.0;
    return riders[1].gapToWinnerSeconds;
  }

  /// Różnica dystansowa w milimetrach pomiędzy pierwszym a drugim kolarzem.
  double get gapMillimetersToSecondPlace {
    if (riders.length < 2) return 0.0;
    return riders[1].gapMillimeters;
  }

  /// Generator demonstracyjnego, niezwykle zaciętego finiszu sprinterskiego (różnica 4 milisekund / 68 mm).
  factory PhotoFinishData.demoSprintFinish({
    String stageName = 'Etap 11: Clermont-Ferrand > Moulins',
    int stageNumber = 11,
    String finishLocation = 'Moulins (Avenue de Paris)',
    double gapSeconds = 0.004,
    double speedKmh = 67.8,
  }) {
    return PhotoFinishData(
      stageName: stageName,
      stageNumber: stageNumber,
      finishLocation: finishLocation,
      finishSpeedKmh: speedKmh,
      cameraSamplingRateHz: 10000,
      status: PhotoFinishStatus.officialConfirmed,
      commissairesRuling: 'Rzut rowerem (Bike Throw) na kreskę rozstrzyga o wygranej o 6.8 cm (+0.004s).',
      riders: [
        PhotoFinishRider(
          rank: 1,
          riderId: 'rider_pogacar',
          riderName: 'Tadej Pogačar',
          teamName: 'UAE Team Emirates',
          bibNumber: 1,
          countryIso: 'SLO',
          finishTimeSeconds: 14228.312,
          gapToWinnerSeconds: 0.0,
          speedKmh: speedKmh,
          primaryJerseyColor: const Color(0xFFFFFFFF),
          secondaryJerseyColor: const Color(0xFFEF4444),
          bikeColor: const Color(0xFF0F1115),
          bikeThrowGainMm: 210.0,
          trackLaneY: 0.38,
        ),
        PhotoFinishRider(
          rank: 2,
          riderId: 'rider_vingegaard',
          riderName: 'Jonas Vingegaard',
          teamName: 'Team Visma | Lease a Bike',
          bibNumber: 11,
          countryIso: 'DEN',
          finishTimeSeconds: 14228.312 + gapSeconds,
          gapToWinnerSeconds: gapSeconds,
          speedKmh: speedKmh - 0.2,
          primaryJerseyColor: const Color(0xFFFFEB3B),
          secondaryJerseyColor: const Color(0xFF1E293B),
          bikeColor: const Color(0xFFF59E0B),
          bikeThrowGainMm: 175.0,
          trackLaneY: 0.62,
        ),
      ],
    );
  }

  /// Konwersja oficjalnych wyników etapu z kalkulatora [StageResultsCalculator] na obiekt fotokomórki.
  factory PhotoFinishData.fromStageResults({
    required RaceStage stage,
    required List<OfficialRiderStageResult> results,
    PhotoFinishStatus status = PhotoFinishStatus.officialConfirmed,
  }) {
    if (results.isEmpty) {
      return PhotoFinishData.demoSprintFinish(stageName: stage.name, stageNumber: stage.stageNumber);
    }

    final topResults = results.take(3).toList();
    final winnerResult = topResults.first;
    const defaultSpeed = 66.5;

    final ridersList = <PhotoFinishRider>[];
    for (int i = 0; i < topResults.length; i++) {
      final res = topResults[i];
      final rawGap = (res.rawFinishTimeSeconds - winnerResult.rawFinishTimeSeconds).abs();

      // Stylizacja strojów na podstawie teamId
      final primaryColor = (i == 0)
          ? const Color(0xFFFFFFFF)
          : (i == 1)
              ? const Color(0xFFFFEB3B)
              : const Color(0xFF38BDF8);

      ridersList.add(
        PhotoFinishRider(
          rank: i + 1,
          riderId: res.riderId,
          riderName: res.riderName,
          teamName: res.teamId.replaceAll('_', ' ').toUpperCase(),
          bibNumber: (i + 1) * 11,
          countryIso: 'UCI',
          finishTimeSeconds: res.rawFinishTimeSeconds,
          gapToWinnerSeconds: i == 0 ? 0.0 : rawGap,
          speedKmh: defaultSpeed - (i * 0.1),
          primaryJerseyColor: primaryColor,
          secondaryJerseyColor: AppColors.background,
          bikeColor: i == 0 ? AppColors.goldAccent : AppColors.cyanAccent,
          bikeThrowGainMm: 190.0 - (i * 20.0),
          trackLaneY: 0.35 + (i * 0.25),
        ),
      );
    }

    final secondPlaceGap = ridersList.length > 1 ? ridersList[1].gapToWinnerSeconds : 0.0;
    final ruling = secondPlaceGap < activationThresholdSeconds
        ? 'Finisz zweryfikowany przez panel sędziowski fotokomórki. Różnica: +${(secondPlaceGap * 1000).toStringAsFixed(1)} ms.'
        : 'Czysta wygrana etapowa bez konieczności rozstrzygania w tysięcznych sekundy.';

    return PhotoFinishData(
      stageName: stage.name,
      stageNumber: stage.stageNumber,
      finishLocation: 'Linia Mety Etapu ${stage.stageNumber}',
      finishSpeedKmh: defaultSpeed,
      cameraSamplingRateHz: 10000,
      status: status,
      riders: ridersList,
      commissairesRuling: ruling,
    );
  }
}

/// Konfiguracja parametrów wyświetlania i narzędzi analitycznych na powtórce Photo-Finish.
class PhotoFinishDisplayConfig {
  /// Czy wyświetlać główną pionową czerwoną linię referencyjną zwycięzcy (Zero Line).
  final bool showRedMeasurementLine;

  /// Czy wyświetlać linię pomiarową drugiego kolarza wraz z nawiasem wymiarowym (Δt / Δd).
  final bool showSecondMeasurementLine;

  /// Czy rysować precyzyjną siatkę milimetrową i czasową (Millimeter Vernier Ruler).
  final bool showMillimeterVernier;

  /// Czy aktywować lupę optyczną (Magnifier Loupe) na styku opon z linią mety.
  final bool showMagnifierLoupe;

  /// Krotność powiększenia lupy optycznej (np. 3.5x).
  final double magnifierZoom;

  /// Wybrany tryb sensora optycznego.
  final PhotoFinishSensorMode sensorMode;

  /// Poziom powiększenia całego kadru (1.0x - 3.0x).
  final double zoomScale;

  /// Pozycja interaktywnego kursora suwmiarki na osi czasu [s].
  final double caliperTimeOffsetSeconds;

  /// Środek lupy powiększającej w przestrzeni znormalizowanej (0..1, 0..1).
  final Offset loupeCenterNormalized;

  const PhotoFinishDisplayConfig({
    this.showRedMeasurementLine = true,
    this.showSecondMeasurementLine = true,
    this.showMillimeterVernier = true,
    this.showMagnifierLoupe = true,
    this.magnifierZoom = 3.5,
    this.sensorMode = PhotoFinishSensorMode.trueColorSlitScan,
    this.zoomScale = 1.0,
    this.caliperTimeOffsetSeconds = 0.0,
    this.loupeCenterNormalized = const Offset(0.52, 0.48),
  });

  PhotoFinishDisplayConfig copyWith({
    bool? showRedMeasurementLine,
    bool? showSecondMeasurementLine,
    bool? showMillimeterVernier,
    bool? showMagnifierLoupe,
    double? magnifierZoom,
    PhotoFinishSensorMode? sensorMode,
    double? zoomScale,
    double? caliperTimeOffsetSeconds,
    Offset? loupeCenterNormalized,
  }) {
    return PhotoFinishDisplayConfig(
      showRedMeasurementLine: showRedMeasurementLine ?? this.showRedMeasurementLine,
      showSecondMeasurementLine: showSecondMeasurementLine ?? this.showSecondMeasurementLine,
      showMillimeterVernier: showMillimeterVernier ?? this.showMillimeterVernier,
      showMagnifierLoupe: showMagnifierLoupe ?? this.showMagnifierLoupe,
      magnifierZoom: magnifierZoom ?? this.magnifierZoom,
      sensorMode: sensorMode ?? this.sensorMode,
      zoomScale: zoomScale ?? this.zoomScale,
      caliperTimeOffsetSeconds: caliperTimeOffsetSeconds ?? this.caliperTimeOffsetSeconds,
      loupeCenterNormalized: loupeCenterNormalized ?? this.loupeCenterNormalized,
    );
  }
}

// =============================================================================
// 2. PAINTER KAMERY SZCZELINOWEJ Z PIONOWĄ CZERWONĄ LINIĄ POMIAROWĄ
// =============================================================================

/// Canvas Painter renderujący widok z kamery liniowej (Line-Scan/Slit-Scan Camera)
/// z poziomym smużeniem tła, sylwetkami kolarzy w pozycji rzutu rowerem (Bike Throw),
/// czerwoną linią pomiarową z milimetrową precyzją oraz lupą optyczną.
class PhotoFinishSlitScanPainter extends CustomPainter {
  final PhotoFinishData data;
  final PhotoFinishDisplayConfig config;

  // Pamięć podręczna pędzli (Zero-GC podczas animacji i interakcji)
  final Paint _bgPaint = Paint();
  final Paint _streakPaint = Paint();
  final Paint _linePaint = Paint();
  final Paint _textBgPaint = Paint();

  PhotoFinishSlitScanPainter({
    required this.data,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Tło kamery szczelinowej: poziome rozmycie smugowe (Streak Blur)
    _drawSlitScanBackground(canvas, size);

    // 2. Pozioma szachownica i asfalt na wysokości szczeliny
    _drawFinishLineTarmacStrip(canvas, size);

    // 3. Rysowanie kolarzy finiszujących w pozycji rzutu rowerem (Bike Throw)
    _drawSprintersInBikeThrow(canvas, size);

    // 4. Siatka milimetrowa i skala czasowa komisarzy UCI
    if (config.showMillimeterVernier) {
      _drawVernierTimeAndDistanceScale(canvas, size);
    }

    // 5. Główna pionowa CZERWONA LINIA POMIAROWA (Winner Zero Line)
    if (config.showRedMeasurementLine) {
      _drawWinnerRedMeasurementLine(canvas, size);
    }

    // 6. Druga pionowa linia pomiarowa i nawias wymiarowy (Δt i Δd)
    if (config.showSecondMeasurementLine && data.riders.length > 1) {
      _drawSecondRiderMeasurementLineAndBracket(canvas, size);
    }

    // 7. Interaktywny kursor suwmiarki użytkownika (jeśli przesunięty)
    if (config.caliperTimeOffsetSeconds.abs() > 0.0001) {
      _drawInteractiveCaliper(canvas, size);
    }

    // 8. Optyczna lupa powiększająca (Magnifying Loupe) z siatką sub-milimetrową
    if (config.showMagnifierLoupe) {
      _drawMagnifierLoupe(canvas, size);
    }

    // 9. Oficjalne stemple telemetryczne i znak wodny UCI / Tissot
    _drawCameraTelemetryWatermark(canvas, size);
  }

  /// Rysuje charakterystyczne dla kamery szczelinowej poziome smugi tła
  /// (efekt rejestrowania 1-pikselowej szczeliny w czasie).
  void _drawSlitScanBackground(Canvas canvas, Size size) {
    // Bazowy odcień w zależności od trybu sensora
    Color baseBg;
    Color streakColor1;
    Color streakColor2;

    switch (config.sensorMode) {
      case PhotoFinishSensorMode.trueColorSlitScan:
        baseBg = const Color(0xFF14171E);
        streakColor1 = const Color(0xFF1E222D);
        streakColor2 = const Color(0xFF262C3A);
        break;
      case PhotoFinishSensorMode.monochromeInfrared:
        baseBg = const Color(0xFF101010);
        streakColor1 = const Color(0xFF1C1C1C);
        streakColor2 = const Color(0xFF2E2E2E);
        break;
      case PhotoFinishSensorMode.edgeContour:
        baseBg = const Color(0xFF090A0F);
        streakColor1 = const Color(0xFF151928);
        streakColor2 = const Color(0xFF00E5FF).withValues(alpha: 0.15);
        break;
    }

    _bgPaint.color = baseBg;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _bgPaint);

    // Poziome smugi tła (statyczne barierki i niebo rozciągnięte w osi czasu)
    final random = math.Random(42); // Stały seed dla stabilnego renderowania
    _streakPaint.style = PaintingStyle.fill;

    for (int i = 0; i < 40; i++) {
      final y = (i / 40.0) * size.height;
      final height = 1.0 + (random.nextDouble() * 4.0);
      final alpha = 0.05 + (random.nextDouble() * 0.12);

      _streakPaint.color = (i % 2 == 0 ? streakColor1 : streakColor2).withValues(alpha: alpha);
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, height), _streakPaint);
    }
  }

  /// Rysuje pas asfaltu z białą linią mety i szachownicą na dnie kadru.
  void _drawFinishLineTarmacStrip(Canvas canvas, Size size) {
    final tarmacHeight = size.height * 0.12;
    final tarmacTop = size.height - tarmacHeight;

    // Pas ciemnego asfaltu
    _bgPaint.color = const Color(0xFF1A1C22);
    canvas.drawRect(Rect.fromLTWH(0, tarmacTop, size.width, tarmacHeight), _bgPaint);

    // Cienka biała linia wyznaczająca krawędź szczeliny
    _linePaint.color = Colors.white.withValues(alpha: 0.4);
    _linePaint.strokeWidth = 1.5;
    canvas.drawLine(Offset(0, tarmacTop), Offset(size.width, tarmacTop), _linePaint);

    // Subtelna szachownica fotokomórki u dołu
    const checkSize = 14.0;
    final cols = (size.width / checkSize).ceil();
    _bgPaint.color = Colors.white.withValues(alpha: 0.08);

    for (int col = 0; col < cols; col++) {
      if (col % 2 == 0) {
        canvas.drawRect(
          Rect.fromLTWH(col * checkSize, tarmacTop + 4, checkSize, tarmacHeight - 8),
          _bgPaint,
        );
      }
    }
  }

  /// Rysuje sylwetki kolarzy finiszujących w dramatycznej pozycji rzutu rowerem (Bike Throw).
  void _drawSprintersInBikeThrow(Canvas canvas, Size size) {
    final riders = data.riders;
    if (riders.isEmpty) return;

    // Pozycja X głównej pionowej linii mety zwycięzcy (punkt referencyjny X = 0.52 szerokości ekranu)
    final double winnerLineX = size.width * 0.52;

    // Przelicznik: ile pikseli odpowiada 1 milisekundzie różnicy czasowej
    // Przy prędkości 67 km/h: 1 ms = ~18.6 mm.
    // Na ekranie skalujemy tak, by 150 ms mieściło się w zakresie widoku.
    final double pixelsPerSecond = size.width * 2.8;

    // Rysujemy kolarzy od najdalszego do zwycięzcy (z-order)
    for (int i = riders.length - 1; i >= 0; i--) {
      final rider = riders[i];
      final double deltaSec = rider.gapToWinnerSeconds;

      // Kolarz za zwycięzcą jest przesunięty w lewo (jego koło jeszcze nie dotarło do szczeliny)
      final double frontTireApexX = winnerLineX - (deltaSec * pixelsPerSecond);

      final double riderCenterY = size.height * rider.trackLaneY;
      final double riderScale = (size.height * 0.38) / 160.0;

      _renderBikeThrowSprinter(
        canvas: canvas,
        apexX: frontTireApexX,
        centerY: riderCenterY,
        scale: riderScale,
        rider: rider,
        isWinner: i == 0,
      );
    }
  }

  /// Renderuje wektorowo pojedynczego kolarza z rowerem w agresywnej pozycji Bike Throw:
  /// - Przednie koło wysunięte do przodu
  /// - Ramiona całkowicie wyprostowane w łokciach, wypychające kierownicę
  /// - Tułów płasko pochylony
  /// - Biodra przesunięte daleko za siodełko (za pionową oś tylnego koła)
  void _renderBikeThrowSprinter({
    required Canvas canvas,
    required double apexX,
    required double centerY,
    required double scale,
    required PhotoFinishRider rider,
    required bool isWinner,
  }) {
    canvas.save();
    canvas.translate(apexX, centerY);
    canvas.scale(scale);

    // Kąt pochylenia ramy i roweru
    // Punkt (0, 0) to najbardziej wysunięty punkt przedniej opony (Apex)!
    const double wheelRadius = 42.0;
    const double tireThickness = 4.5;
    const double rimDepth = 12.0;

    Color jerseyMain = rider.primaryJerseyColor;
    Color jerseySec = rider.secondaryJerseyColor;
    Color bikeColor = rider.bikeColor;
    Color skinColor = const Color(0xFFE0AC69);
    Color tireColor = const Color(0xFF1E2024);
    Color rimColor = const Color(0xFF2C3038);

    // Modyfikacja barw w trybie monochromatycznym / podczerwieni IR
    if (config.sensorMode == PhotoFinishSensorMode.monochromeInfrared) {
      jerseyMain = _toGrayscale(jerseyMain);
      jerseySec = _toGrayscale(jerseySec);
      bikeColor = _toGrayscale(bikeColor);
      skinColor = const Color(0xFF888888);
      tireColor = const Color(0xFF0A0A0A);
      rimColor = const Color(0xFF333333);
    } else if (config.sensorMode == PhotoFinishSensorMode.edgeContour) {
      jerseyMain = jerseyMain.withValues(alpha: 0.3);
      bikeColor = AppColors.cyanAccent;
    }

    // 1. Przednie koło (Front Wheel): środek koła w (-wheelRadius, 0)
    const frontWheelCenter = Offset(-wheelRadius, 0);

    // Karbonowa obręcz aero
    _linePaint.color = rimColor;
    _linePaint.style = PaintingStyle.stroke;
    _linePaint.strokeWidth = rimDepth;
    canvas.drawCircle(frontWheelCenter, wheelRadius - (rimDepth / 2), _linePaint);

    // Opona szosowa (Tubular 700x28c) z beżowym bokiem (Skinwall)
    _linePaint.color = config.sensorMode == PhotoFinishSensorMode.trueColorSlitScan
        ? const Color(0xFFD4A373)
        : const Color(0xFF555555);
    _linePaint.strokeWidth = 2.0;
    canvas.drawCircle(frontWheelCenter, wheelRadius - 1.5, _linePaint);

    // Czarny bieżnik zewnętrzny
    _linePaint.color = tireColor;
    _linePaint.strokeWidth = tireThickness;
    canvas.drawCircle(frontWheelCenter, wheelRadius, _linePaint);

    // Szprychy aerodynamiczne
    _linePaint.color = Colors.white.withValues(alpha: 0.2);
    _linePaint.strokeWidth = 1.0;
    for (int s = 0; s < 12; s++) {
      final angle = (s * math.pi) / 6.0;
      final spokeEnd = frontWheelCenter + Offset(math.cos(angle) * (wheelRadius - rimDepth), math.sin(angle) * (wheelRadius - rimDepth));
      canvas.drawLine(frontWheelCenter, spokeEnd, _linePaint);
    }

    // 2. Widelec (Fork) i główka ramy
    const forkTop = Offset(-wheelRadius - 18, -38);
    _linePaint.color = bikeColor;
    _linePaint.strokeWidth = 4.5;
    _linePaint.strokeCap = StrokeCap.round;
    canvas.drawLine(frontWheelCenter, forkTop, _linePaint);

    // 3. Wypchnięta do przodu kierownica typu Bar Drop (Rzut rowerem)
    const handlebarPos = Offset(-wheelRadius - 10, -42);
    _linePaint.color = const Color(0xFF111317);
    _linePaint.strokeWidth = 3.5;
    canvas.drawLine(forkTop, handlebarPos, _linePaint);

    // 4. Rama roweru (Górna rura, dolna rura, suport, tylne widełki)
    const bottomBracket = Offset(-wheelRadius - 70, -10);
    const seatCluster = Offset(-wheelRadius - 78, -48);
    const rearDropout = Offset(-wheelRadius - 110, 0);

    final framePath = Path()
      ..moveTo(forkTop.dx, forkTop.dy)
      ..lineTo(seatCluster.dx, seatCluster.dy) // Górna rura
      ..lineTo(bottomBracket.dx, bottomBracket.dy) // Rura podsiodłowa
      ..lineTo(forkTop.dx, forkTop.dy) // Dolna rura
      ..moveTo(seatCluster.dx, seatCluster.dy)
      ..lineTo(rearDropout.dx, rearDropout.dy) // Tylny trójkąt górny
      ..lineTo(bottomBracket.dx, bottomBracket.dy); // Tylny trójkąt dolny

    _linePaint.color = bikeColor;
    _linePaint.strokeWidth = 4.0;
    _linePaint.style = PaintingStyle.stroke;
    canvas.drawPath(framePath, _linePaint);

    // 5. Tylne koło (Rear Wheel)
    _linePaint.color = rimColor;
    _linePaint.strokeWidth = rimDepth;
    canvas.drawCircle(rearDropout, wheelRadius - (rimDepth / 2), _linePaint);
    _linePaint.color = tireColor;
    _linePaint.strokeWidth = tireThickness;
    canvas.drawCircle(rearDropout, wheelRadius, _linePaint);

    // 6. Siodełko (Saddle)
    const saddleFront = Offset(-wheelRadius - 72, -54);
    const saddleRear = Offset(-wheelRadius - 92, -55);
    _linePaint.color = const Color(0xFF1E2024);
    _linePaint.strokeWidth = 4.0;
    canvas.drawLine(saddleFront, saddleRear, _linePaint);

    // 7. SYLWETKA KOLARZA W POZYCJI "BIKE THROW":
    // Ramiona całkowicie wyprostowane w stronę kierownicy!
    const shoulderPos = Offset(-wheelRadius - 52, -52);
    _linePaint.color = skinColor;
    _linePaint.strokeWidth = 5.0;
    canvas.drawLine(shoulderPos, handlebarPos, _linePaint); // Wyprostowane ręce rzucające rower

    // Kask aerodynamiczny i głowa opuszczona nisko
    const headCenter = Offset(-wheelRadius - 46, -62);
    final helmetPath = Path()
      ..moveTo(headCenter.dx + 12, headCenter.dy + 2)
      ..lineTo(headCenter.dx - 14, headCenter.dy - 6)
      ..lineTo(headCenter.dx - 22, headCenter.dy + 6) // Ogon kasku aero
      ..close();
    _bgPaint.color = isWinner ? AppColors.goldAccent : jerseyMain;
    _bgPaint.style = PaintingStyle.fill;
    canvas.drawPath(helmetPath, _bgPaint);

    // Okulary przeciwsłoneczne / wizjer kasku
    _linePaint.color = AppColors.cyanAccent;
    _linePaint.strokeWidth = 2.5;
    canvas.drawLine(Offset(headCenter.dx + 6, headCenter.dy + 2), Offset(headCenter.dx + 12, headCenter.dy + 2), _linePaint);

    // Tułów (Torso) w koszulce drużyny – pochylony poziomo
    const hipsPos = Offset(-wheelRadius - 96, -58); // Biodra cofnięte ZA SIODEŁKO!
    final torsoPath = Path()
      ..moveTo(shoulderPos.dx, shoulderPos.dy - 6)
      ..lineTo(hipsPos.dx, hipsPos.dy - 6)
      ..lineTo(hipsPos.dx, hipsPos.dy + 6)
      ..lineTo(shoulderPos.dx, shoulderPos.dy + 6)
      ..close();

    _bgPaint.color = jerseyMain;
    canvas.drawPath(torsoPath, _bgPaint);

    // Pasek sponsorów / barw pomocniczych na koszulce
    _bgPaint.color = jerseySec;
    canvas.drawRect(Rect.fromLTWH(hipsPos.dx + 12, hipsPos.dy - 6, 16, 12), _bgPaint);

    // Numer startowy (Bib Number) na boku koszulki
    _drawBibNumber(canvas, Offset(hipsPos.dx + 20, hipsPos.dy), rider.bibNumber);

    // Nogi kolarza (Legs) – biodra za siodłem, pedałowanie z maksymalną kadencją
    _linePaint.color = const Color(0xFF111317); // Spodenki kolarskie (Bib shorts)
    _linePaint.strokeWidth = 7.0;
    const kneePos = Offset(-wheelRadius - 74, -30);
    canvas.drawLine(hipsPos, kneePos, _linePaint);

    _linePaint.color = skinColor; // Łydka
    _linePaint.strokeWidth = 5.0;
    const pedalPos = Offset(-wheelRadius - 70, -4);
    canvas.drawLine(kneePos, pedalPos, _linePaint);

    // But kolarski
    _linePaint.color = Colors.white;
    _linePaint.strokeWidth = 4.0;
    canvas.drawLine(pedalPos, Offset(pedalPos.dx + 8, pedalPos.dy), _linePaint);

    canvas.restore();
  }

  /// Rysuje miniaturowy numer startowy na boku kolarza.
  void _drawBibNumber(Canvas canvas, Offset pos, int bib) {
    _bgPaint.color = Colors.white;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: pos, width: 14, height: 10), const Radius.circular(2)), _bgPaint);

    final textSpan = TextSpan(
      text: '$bib',
      style: const TextStyle(
        color: Colors.black,
        fontSize: 7,
        fontWeight: FontWeight.w900,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(pos.dx - (textPainter.width / 2), pos.dy - (textPainter.height / 2)));
  }

  /// Rysuje główną PIONOWĄ CZERWONĄ LINIĘ POMIAROWĄ (Zero Reference Line)
  /// przechodzącą dokładnie przez czoło przedniej opony zwycięzcy.
  void _drawWinnerRedMeasurementLine(Canvas canvas, Size size) {
    final double winnerLineX = size.width * 0.52;

    // Poświata neonowa lasera pomiarowego
    _linePaint.color = const Color(0xFFFF003B).withValues(alpha: 0.35);
    _linePaint.strokeWidth = 5.0;
    _linePaint.style = PaintingStyle.stroke;
    canvas.drawLine(Offset(winnerLineX, 0), Offset(winnerLineX, size.height), _linePaint);

    // Ostra pionowa czerwona linia pomiarowa co do milimetra
    _linePaint.color = const Color(0xFFFF003B);
    _linePaint.strokeWidth = 1.75;
    canvas.drawLine(Offset(winnerLineX, 0), Offset(winnerLineX, size.height), _linePaint);

    // Górny znacznik kalibracyjny (Target Pin)
    final topPinPath = Path()
      ..moveTo(winnerLineX - 9, 0)
      ..lineTo(winnerLineX + 9, 0)
      ..lineTo(winnerLineX, 14)
      ..close();
    _bgPaint.color = const Color(0xFFFF003B);
    canvas.drawPath(topPinPath, _bgPaint);

    // Etykieta referencyjna na górze
    _drawPillBadge(
      canvas: canvas,
      center: Offset(winnerLineX, 26),
      text: '0.000s | LINIA REFERENCYJNA ZWYCIĘZCY',
      bgColor: const Color(0xFFFF003B),
      textColor: Colors.white,
    );

    // Dolny znacznik kalibracyjny
    final bottomPinPath = Path()
      ..moveTo(winnerLineX - 9, size.height)
      ..lineTo(winnerLineX + 9, size.height)
      ..lineTo(winnerLineX, size.height - 14)
      ..close();
    canvas.drawPath(bottomPinPath, _bgPaint);
  }

  /// Rysuje drugą pionową linię pomiarową na krawędzi opony 2. kolarza
  /// wraz z wymiarowaniem w tysięcznych sekundy (+0.004s) i milimetrach (+68 mm).
  void _drawSecondRiderMeasurementLineAndBracket(Canvas canvas, Size size) {
    final double winnerLineX = size.width * 0.52;
    final double pixelsPerSecond = size.width * 2.8;

    final rider2 = data.secondPlace;
    final double deltaSec = rider2.gapToWinnerSeconds;
    final double secondLineX = winnerLineX - (deltaSec * pixelsPerSecond);

    // Pionowa linia pomocnicza (żółto-bursztynowa lub cyjanowa)
    _linePaint.color = const Color(0xFFFFD54F);
    _linePaint.strokeWidth = 1.5;
    canvas.drawLine(Offset(secondLineX, 0), Offset(secondLineX, size.height), _linePaint);

    // Górny i dolny znacznik 2. kolarza
    final topPin = Path()
      ..moveTo(secondLineX - 7, 0)
      ..lineTo(secondLineX + 7, 0)
      ..lineTo(secondLineX, 10)
      ..close();
    _bgPaint.color = const Color(0xFFFFD54F);
    canvas.drawPath(topPin, _bgPaint);

    // Wymiarowanie poziome pomiędzy oponami (Measurement Dimension Bracket)
    final double bracketY = size.height * 0.22;
    _linePaint.color = Colors.white;
    _linePaint.strokeWidth = 1.5;

    // Pozioma linia wymiaru
    canvas.drawLine(Offset(secondLineX, bracketY), Offset(winnerLineX, bracketY), _linePaint);

    // Grotki strzałek na końcach wymiaru
    _drawArrowHead(canvas, Offset(winnerLineX, bracketY), isPointingRight: true);
    _drawArrowHead(canvas, Offset(secondLineX, bracketY), isPointingRight: false);

    // Etykieta wymiarowa ze stratą co do tysięcznej części sekundy i milimetra
    final double midX = (winnerLineX + secondLineX) / 2.0;
    final String diffText = 'Δt = +${deltaSec.toStringAsFixed(3)}s  |  Δd = ${rider2.formattedGapDistance}';

    _drawPillBadge(
      canvas: canvas,
      center: Offset(midX.clamp(120.0, size.width - 120.0), bracketY - 14),
      text: diffText,
      bgColor: const Color(0xFF1E222D),
      borderColor: const Color(0xFFFFD54F),
      textColor: const Color(0xFFFFD54F),
    );
  }

  /// Rysuje grot strzałki wymiarowej.
  void _drawArrowHead(Canvas canvas, Offset tip, {required bool isPointingRight}) {
    final double dir = isPointingRight ? -1.0 : 1.0;
    final arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + (dir * 6), tip.dy - 3)
      ..lineTo(tip.dx + (dir * 6), tip.dy + 3)
      ..close();
    _bgPaint.color = Colors.white;
    canvas.drawPath(arrowPath, _bgPaint);
  }

  /// Rysuje podziałkę milimetrową i skalę czasową (Vernier Ruler) na górnej i dolnej krawędzi.
  void _drawVernierTimeAndDistanceScale(Canvas canvas, Size size) {
    final double winnerLineX = size.width * 0.52;
    final double pixelsPerSecond = size.width * 2.8;

    // Podziałka czasowa co 10 ms (główne kreski) i co 2 ms (drobne kreski)
    _linePaint.color = Colors.white.withValues(alpha: 0.35);
    _linePaint.strokeWidth = 1.0;

    // Rysujemy podziałki od -100 ms do +50 ms
    for (int ms = -120; ms <= 60; ms += 2) {
      final double sec = ms / 1000.0;
      final double x = winnerLineX - (sec * pixelsPerSecond);

      if (x < 0 || x > size.width) continue;

      final bool isMajor = (ms % 10 == 0);
      final double tickHeight = isMajor ? 12.0 : 5.0;

      // Górne kreski podziałki
      canvas.drawLine(Offset(x, 0), Offset(x, tickHeight), _linePaint);

      // Dolne kreski podziałki (nad asfaltem)
      final double bottomY = size.height * 0.88;
      canvas.drawLine(Offset(x, bottomY), Offset(x, bottomY - tickHeight), _linePaint);

      // Etykiety czasowe przy głównych podziałkach co 20 ms
      if (ms % 20 == 0 && ms != 0) {
        final labelText = '${ms > 0 ? "+" : ""}$ms ms';
        final textSpan = TextSpan(
          text: labelText,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
          ),
        );
        final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
        tp.paint(canvas, Offset(x - (tp.width / 2), 14));
      }
    }
  }

  /// Rysuje interaktywny kursor suwmiarki przesuwany palcem/myszką przez gracza.
  void _drawInteractiveCaliper(Canvas canvas, Size size) {
    final double winnerLineX = size.width * 0.52;
    final double pixelsPerSecond = size.width * 2.8;
    final double caliperX = winnerLineX - (config.caliperTimeOffsetSeconds * pixelsPerSecond);

    _linePaint.color = AppColors.cyanAccent;
    _linePaint.strokeWidth = 1.5;
    canvas.drawLine(Offset(caliperX, 0), Offset(caliperX, size.height), _linePaint);

    final String cursorText = 'KURSOR: ${config.caliperTimeOffsetSeconds >= 0 ? "+" : ""}${(config.caliperTimeOffsetSeconds * 1000).toStringAsFixed(1)} ms';
    _drawPillBadge(
      canvas: canvas,
      center: Offset(caliperX.clamp(60.0, size.width - 60.0), size.height * 0.5),
      text: cursorText,
      bgColor: const Color(0xFF0F172A),
      borderColor: AppColors.cyanAccent,
      textColor: AppColors.cyanAccent,
    );
  }

  /// Rysuje optyczną lupę powiększającą (Magnifier Loupe) na styku opon z linią mety.
  void _drawMagnifierLoupe(Canvas canvas, Size size) {
    final loupeCenter = Offset(
      config.loupeCenterNormalized.dx * size.width,
      config.loupeCenterNormalized.dy * size.height,
    );
    const double loupeRadius = 68.0;

    canvas.save();

    // 1. Zewnętrzny cień lupy
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(loupeCenter, loupeRadius + 2, shadowPaint);

    // 2. Klip do koła lupy
    final clipPath = Path()..addOval(Rect.fromCircle(center: loupeCenter, radius: loupeRadius));
    canvas.clipPath(clipPath);

    // 3. Tło powiększenia
    _bgPaint.color = const Color(0xFF0B0D13);
    canvas.drawCircle(loupeCenter, loupeRadius, _bgPaint);

    // 4. Powiększenie zawartości sceny (zoom x3.5)
    canvas.translate(loupeCenter.dx, loupeCenter.dy);
    canvas.scale(config.magnifierZoom);
    canvas.translate(-loupeCenter.dx, -loupeCenter.dy);

    // Rysujemy elementy powiększone: opony i czerwoną linię
    _drawSprintersInBikeThrow(canvas, size);
    _drawWinnerRedMeasurementLine(canvas, size);
    if (data.riders.length > 1) {
      _drawSecondRiderMeasurementLineAndBracket(canvas, size);
    }

    // Cofnięcie transformacji zoomu dla siatki mikrometrycznej lupy
    canvas.restore();

    // 5. Celownik i mikrometryczna siatka pomiarowa lupy
    _linePaint.color = AppColors.cyanAccent.withValues(alpha: 0.45);
    _linePaint.strokeWidth = 1.0;
    // Oś pozioma i pionowa celownika
    canvas.drawLine(Offset(loupeCenter.dx - loupeRadius, loupeCenter.dy), Offset(loupeCenter.dx + loupeRadius, loupeCenter.dy), _linePaint);
    canvas.drawLine(Offset(loupeCenter.dx, loupeCenter.dy - loupeRadius), Offset(loupeCenter.dx, loupeCenter.dy + loupeRadius), _linePaint);

    // Okręgi skali co 15 px
    _linePaint.style = PaintingStyle.stroke;
    canvas.drawCircle(loupeCenter, 25.0, _linePaint);
    canvas.drawCircle(loupeCenter, 50.0, _linePaint);

    // 6. Metalowa chromowana oprawa lupy ze śrubami i oznaczeniem powiększenia
    final rimPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(loupeCenter.dx - loupeRadius, loupeCenter.dy - loupeRadius),
        Offset(loupeCenter.dx + loupeRadius, loupeCenter.dy + loupeRadius),
        const [
          Color(0xFF94A3B8),
          Color(0xFF334155),
          Color(0xFFCBD5E1),
          Color(0xFF1E293B),
        ],
        const [0.0, 0.35, 0.65, 1.0],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    canvas.drawCircle(loupeCenter, loupeRadius, rimPaint);

    // Etykieta lupy (np. "3.5x OPTICAL LOUPE")
    _drawPillBadge(
      canvas: canvas,
      center: Offset(loupeCenter.dx, loupeCenter.dy + loupeRadius - 12),
      text: '${config.magnifierZoom.toStringAsFixed(1)}x LUPA SUB-MM',
      bgColor: const Color(0xFF0F172A).withValues(alpha: 0.85),
      borderColor: AppColors.cyanAccent,
      textColor: AppColors.cyanAccent,
      fontSize: 8.0,
    );
  }

  /// Rysuje profesjonalny znak wodny kamery szczelinowej UCI / Swiss Timing / Tissot.
  void _drawCameraTelemetryWatermark(Canvas canvas, Size size) {
    const watermarkText = 'UCI OFFICIAL PHOTO FINISH SYSTEM • LINE-SCAN 10,000 FPS • RESOLUTION 0.0001s';
    final textSpan = TextSpan(
      text: watermarkText,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 9.0,
        letterSpacing: 1.0,
        fontWeight: FontWeight.w700,
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(size.width - tp.width - 16, size.height - 22));
  }

  /// Pomocnicza metoda rysowania kapsułki informacyjnej (Pill Badge).
  void _drawPillBadge({
    required Canvas canvas,
    required Offset center,
    required String text,
    required Color bgColor,
    Color? borderColor,
    required Color textColor,
    double fontSize = 9.5,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.4,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final width = textPainter.width + 16;
    final height = textPainter.height + 8;
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    _textBgPaint.color = bgColor;
    _textBgPaint.style = PaintingStyle.fill;
    canvas.drawRRect(rrect, _textBgPaint);

    if (borderColor != null) {
      _linePaint.color = borderColor;
      _linePaint.style = PaintingStyle.stroke;
      _linePaint.strokeWidth = 1.0;
      canvas.drawRRect(rrect, _linePaint);
    }

    textPainter.paint(
      canvas,
      Offset(center.dx - (textPainter.width / 2), center.dy - (textPainter.height / 2)),
    );
  }

  Color _toGrayscale(Color color) {
    final gray = (0.299 * (color.r * 255) + 0.587 * (color.g * 255) + 0.114 * (color.b * 255)).round().clamp(0, 255);
    return Color.fromARGB(255, gray, gray, gray);
  }

  @override
  bool shouldRepaint(covariant PhotoFinishSlitScanPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.config != config;
  }
}

// =============================================================================
// 3. WIDGET POWTÓRKI PHOTO-FINISH Z PEŁNĄ INTERAKTYWNOŚCIĄ (REPLAY WIDGET)
// =============================================================================

/// Główny widget powtórki Photo-Finish aktywowany przy różnicy na kresce mety < 0.15s.
/// Umożliwia sędziowską inspekcję opon, przesuwanie suwmiarki pomiarowej, lupę powiększającą
/// oraz oficjalne zatwierdzenie werdyktu sędziów UCI.
class PhotoFinishReplayWidget extends StatefulWidget {
  /// Dane finiszu z fotokomórki.
  final PhotoFinishData data;

  /// Początkowa konfiguracja wyświetlania.
  final PhotoFinishDisplayConfig initialConfig;

  /// Callback wywoływany po oficjalnym zatwierdzeniu werdyktu sędziowskiego przez gracza.
  final VoidCallback? onConfirmResult;

  /// Czy widget ma być renderowany w trybie pełnoekranowym (np. w oknie dialogowym).
  final bool isFullScreenDialog;

  const PhotoFinishReplayWidget({
    super.key,
    required this.data,
    this.initialConfig = const PhotoFinishDisplayConfig(),
    this.onConfirmResult,
    this.isFullScreenDialog = true,
  });

  @override
  State<PhotoFinishReplayWidget> createState() => _PhotoFinishReplayWidgetState();
}

class _PhotoFinishReplayWidgetState extends State<PhotoFinishReplayWidget> with SingleTickerProviderStateMixin {
  late PhotoFinishDisplayConfig _config;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final winner = widget.data.winner;
    final second = widget.data.secondPlace;
    final gapSec = widget.data.gapSecondsToSecondPlace;
    final gapMm = widget.data.gapMillimetersToSecondPlace;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D13),
        borderRadius: BorderRadius.circular(widget.isFullScreenDialog ? 16 : 8),
        border: Border.all(color: const Color(0xFFFF003B).withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFFFF003B).withValues(alpha: 0.15),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Górna belka sędziowska UCI (Header Bar)
          _buildTopCommissairesHeader(gapSec, gapMm),

          // 2. Główny kadr kamery szczelinowej (Canvas Slit-Scan Replay)
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      // Przesuwanie lupy optycznej
                      final RenderBox box = context.findRenderObject() as RenderBox;
                      final localPos = box.globalToLocal(details.globalPosition);
                      final normalizedX = (localPos.dx / box.size.width).clamp(0.1, 0.9);
                      final normalizedY = (localPos.dy / box.size.height).clamp(0.1, 0.9);
                      setState(() {
                        _config = _config.copyWith(
                          loupeCenterNormalized: Offset(normalizedX, normalizedY),
                        );
                      });
                    },
                    child: CustomPaint(
                      painter: PhotoFinishSlitScanPainter(
                        data: widget.data,
                        config: _config,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),

                // Nakładka boczna: etykiety kolarzy na linii
                Positioned(
                  top: 12,
                  left: 14,
                  child: _buildRidersPillOverlay(winner, second),
                ),
              ],
            ),
          ),

          // 3. Pasek narzędzi inspekcyjnych (Inspection Toolset)
          _buildInspectionControlToolbar(),

          // 4. Dolna belka podsumowująca i przycisk zatwierdzenia wyniku
          _buildBottomConfirmationBar(winner, second, gapSec, gapMm),
        ],
      ),
    );
  }

  /// Górna oficjalna belka komisarzy UCI ze statusem, etapem i parametrami kamery.
  Widget _buildTopCommissairesHeader(double gapSec, double gapMm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF131720),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        border: Border(bottom: BorderSide(color: Color(0xFF262C3A), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo i tytuł fotokomórki
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF003B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF003B), width: 1.5),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Color(0xFFFF003B),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'PHOTO FINISH REPLAY',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF003B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LINE-SCAN 10kHz',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.data.stageName} • ${widget.data.finishLocation}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Status sędziowski (Under Review / Confirmed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: widget.data.status.badgeColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: widget.data.status.badgeColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.data.status.icon,
                  size: 14,
                  color: widget.data.status.badgeColor,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.data.status.label,
                  style: TextStyle(
                    color: widget.data.status.badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Nakładka z kartami kolarzy walczących o zwycięstwo w lewym górnym rogu.
  Widget _buildRidersPillOverlay(PhotoFinishRider winner, PhotoFinishRider second) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRiderCompactRow(winner, isWinner: true),
          const SizedBox(height: 6),
          _buildRiderCompactRow(second, isWinner: false),
        ],
      ),
    );
  }

  Widget _buildRiderCompactRow(PhotoFinishRider rider, {required bool isWinner}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isWinner ? const Color(0xFFFF003B) : const Color(0xFFFFD54F),
            shape: BoxShape.circle,
          ),
          child: Text(
            '${rider.rank}',
            style: TextStyle(
              color: isWinner ? Colors.white : Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '#${rider.bibNumber} ${rider.riderName}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          rider.formattedGapSeconds,
          style: TextStyle(
            color: isWinner ? const Color(0xFF10B981) : const Color(0xFFFFD54F),
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  /// Pasek narzędzi inspekcyjnych: filtry optyczne, lupa, suwmiarka, siatka milimetrowa.
  Widget _buildInspectionControlToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF10131B),
        border: Border(
          top: BorderSide(color: Color(0xFF1F2430), width: 1),
          bottom: BorderSide(color: Color(0xFF1F2430), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Przełącznik filtrów sensora optycznego
          Row(
            children: [
              const Text(
                'SENSOR:',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              ...PhotoFinishSensorMode.values.map((mode) {
                final isSelected = _config.sensorMode == mode;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _config = _config.copyWith(sensorMode: mode);
                      });
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.cyanAccent.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSelected ? AppColors.cyanAccent : Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            mode.icon,
                            size: 12,
                            color: isSelected ? AppColors.cyanAccent : Colors.white60,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mode.label.split(' ').first,
                            style: TextStyle(
                              color: isSelected ? AppColors.cyanAccent : Colors.white70,
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),

          // Przełączniki lupy i siatki milimetrowej
          Row(
            children: [
              // Przełącznik lupy optycznej
              _buildToggleChip(
                label: 'LUPA 3.5x',
                icon: Icons.zoom_in_rounded,
                isActive: _config.showMagnifierLoupe,
                onTap: () {
                  setState(() {
                    _config = _config.copyWith(showMagnifierLoupe: !_config.showMagnifierLoupe);
                  });
                },
              ),
              const SizedBox(width: 6),
              // Przełącznik siatki milimetrowej
              _buildToggleChip(
                label: 'SIATKA MM',
                icon: Icons.straighten_rounded,
                isActive: _config.showMillimeterVernier,
                onTap: () {
                  setState(() {
                    _config = _config.copyWith(showMillimeterVernier: !_config.showMillimeterVernier);
                  });
                },
              ),
              const SizedBox(width: 6),
              // Przełącznik linii pomiarowej 2. kolarza
              _buildToggleChip(
                label: 'LINIA 2. MIEJSCA',
                icon: Icons.compare_arrows_rounded,
                isActive: _config.showSecondMeasurementLine,
                onTap: () {
                  setState(() {
                    _config = _config.copyWith(showSecondMeasurementLine: !_config.showSecondMeasurementLine);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF003B).withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? const Color(0xFFFF003B) : Colors.white24,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: isActive ? const Color(0xFFFF003B) : Colors.white60,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFFFF003B) : Colors.white70,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dolna belka podsumowująca werdykt fotokomórki oraz przycisk potwierdzenia.
  Widget _buildBottomConfirmationBar(
    PhotoFinishRider winner,
    PhotoFinishRider second,
    double gapSec,
    double gapMm,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF131720),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Precyzyjne dane różnicy w mm i tysięcznych sekundy
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'RÓŻNICA NA KRESCE: ',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '+${(gapSec * 1000).toStringAsFixed(1)} ms  (${second.formattedGapDistance})',
                      style: const TextStyle(
                        color: Color(0xFFFFD54F),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '@ ${widget.data.finishSpeedKmh.toStringAsFixed(1)} km/h',
                      style: const TextStyle(
                        color: AppColors.cyanAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.data.commissairesRuling,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Przycisk zatwierdzenia wyniku
          ElevatedButton.icon(
            onPressed: () {
              if (widget.onConfirmResult != null) {
                widget.onConfirmResult!();
              } else if (widget.isFullScreenDialog && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.check_circle_rounded, size: 16),
            label: const Text('ZATWIERDŹ WYNIK I PODIUM'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 4. FUNKCJA POMOCNICZA OTWIERANIA MODALNEGO OKNA PHOTO-FINISH
// =============================================================================

/// Otwiera pełnoekranowe okno dialogowe z powtórką Photo-Finish w dowolnym miejscu aplikacji
/// (np. w symulacji wyścigu lub ekranie podsumowania etapu).
Future<void> showPhotoFinishReplayDialog(
  BuildContext context, {
  required PhotoFinishData data,
  VoidCallback? onConfirmResult,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.88),
    builder: (BuildContext ctx) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1080,
            maxHeight: 640,
          ),
          child: Material(
            color: Colors.transparent,
            child: PhotoFinishReplayWidget(
              data: data,
              isFullScreenDialog: true,
              onConfirmResult: () {
                Navigator.of(ctx).pop();
                if (onConfirmResult != null) {
                  onConfirmResult();
                }
              },
            ),
          ),
        ),
      );
    },
  );
}
