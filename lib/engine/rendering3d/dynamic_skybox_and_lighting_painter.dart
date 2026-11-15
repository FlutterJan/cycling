// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';
import 'cyclist_3d_pose_animator.dart';
import 'peloton_instanced_renderer.dart';
import 'road_ribbon_mesh_builder.dart';
import 'scene_3d_math_projection.dart';
import 'support_vehicles_3d_renderer.dart';

/// Pora dnia etapu kolarskiego używana do wyliczania pozycji słońca i palety nieba.
enum StageLightingPhase {
  /// Świt i wczesny poranek (05:30 – 09:30).
  dawn,

  /// Pełne słońce w środku dnia (09:30 – 16:00), np. start o 11:30.
  midday,

  /// Złota godzina w Alpach / Pirenejach (16:00 – 19:15), np. finisz królewskiego etapu o 17:15.
  goldenHour,

  /// Zmierzch i niebieska godzina (19:15 – 20:30).
  twilight,

  /// Wieczorne kryterium / finisz w Paryżu przy światłach latarni (20:30 – 05:30).
  nightCriterium,
}

/// Reprezentacja godziny etapu (00:00 – 23:59) z gotowymi presetami wyścigowymi.
class StageTimeOfDay {
  final int hour;
  final int minute;

  const StageTimeOfDay({
    required this.hour,
    required this.minute,
  });

  /// Start etapu o 11:30 w pełnym słońcu.
  const StageTimeOfDay.morningStart()
      : hour = 11,
        minute = 30;

  /// Finisz królewskiego etapu w Alpach o 17:15 w ciepłym świetle Golden Hour.
  const StageTimeOfDay.alpineGoldenHour()
      : hour = 17,
        minute = 15;

  /// Wieczorne kryterium / finisz w Paryżu o 20:45 przy światłach latarni.
  const StageTimeOfDay.parisEveningCriterium()
      : hour = 20,
        minute = 45;

  /// Nocny finał przy sztucznym oświetleniu o 22:00.
  const StageTimeOfDay.nightFinale()
      : hour = 22,
        minute = 0;

  /// Wyznacza porę dnia na podstawie postępu etapu [progressRatio] (0.0 – 1.0) i typu etapu.
  factory StageTimeOfDay.forStageProgress({
    required StageType stageType,
    required double progressRatio,
    String stageName = '',
  }) {
    final double clampedProgress = progressRatio.clamp(0.0, 1.0);
    final String lowerName = stageName.toLowerCase();
    final bool isParisOrCriterium = lowerName.contains('paris') ||
        lowerName.contains('paryż') ||
        lowerName.contains('champs') ||
        lowerName.contains('kryterium') ||
        lowerName.contains('criterium');

    // Start o 11:30; królewski etap górski kończy się o 17:15 (Golden Hour),
    // a finisz w Paryżu / kryterium sięga 20:45 przy światłach latarni.
    final double startHours = isParisOrCriterium ? 17.0 : 11.5;
    final double endHours = isParisOrCriterium
        ? 20.75
        : (stageType == StageType.highMountain ||
                stageType == StageType.summitFinish ||
                stageType == StageType.hilly)
            ? 17.25
            : 16.25;

    final double currentHours = startHours + (endHours - startHours) * clampedProgress;
    final int h = currentHours.floor().clamp(0, 23);
    final int m = ((currentHours - h) * 60.0).round().clamp(0, 59);
    return StageTimeOfDay(hour: h, minute: m);
  }

  /// Czas dziesiętny w godzinach [0.0, 24.0).
  double get decimalHours => (hour.clamp(0, 23)) + (minute.clamp(0, 59) / 60.0);

  /// Faza oświetlenia atmosferycznego dla bieżącej godziny.
  StageLightingPhase get phase {
    final double h = decimalHours;
    if (h >= 5.5 && h < 9.5) return StageLightingPhase.dawn;
    if (h >= 9.5 && h < 16.0) return StageLightingPhase.midday;
    if (h >= 16.0 && h < 19.25) return StageLightingPhase.goldenHour;
    if (h >= 19.25 && h < 20.5) return StageLightingPhase.twilight;
    return StageLightingPhase.nightCriterium;
  }

  /// Czy latarnie uliczne są włączone (zmierzch / nocne kryterium).
  bool get areStreetlampsActive =>
      phase == StageLightingPhase.twilight ||
      phase == StageLightingPhase.nightCriterium;

  String get formatted =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StageTimeOfDay && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

/// Konfiguracja oświetlenia atmosferycznego, cieni i odbić na mokrym asfalcie.
class DynamicLightingConfig {
  /// Czy renderować dynamiczne cienie rzucane przez kolarzy i rowery.
  final bool enableProjectedDropShadows;

  /// Czy renderować odbicia na mokrym asfalcie podczas deszczu.
  final bool enableWetRoadSpecularReflection;

  /// Czy renderować tarczę słoneczną i poświatę atmosferyczną.
  final bool enableSunDiscAndCorona;

  /// Czy renderować błyski burzowe w oddali podczas deszczu/burzy.
  final bool enableStormLightning;

  /// Czy renderować stożki światła latarni podczas wieczornych etapów.
  final bool enableEveningStreetlamps;

  /// Maksymalna odległość od kamery, do której rysowane są rzutowane cienie kolarzy [m].
  final double maxShadowRenderDistanceMeters;

  /// Maksymalna odległość od kamery dla odbić na mokrym asfalcie [m].
  final double maxReflectionRenderDistanceMeters;

  const DynamicLightingConfig({
    this.enableProjectedDropShadows = true,
    this.enableWetRoadSpecularReflection = true,
    this.enableSunDiscAndCorona = true,
    this.enableStormLightning = true,
    this.enableEveningStreetlamps = true,
    this.maxShadowRenderDistanceMeters = 180.0,
    this.maxReflectionRenderDistanceMeters = 140.0,
  });
}

/// Wyliczony stan oświetlenia słonecznego i atmosferycznego w danej klatce.
class SunLightState {
  /// Jednostkowy wektor kierunku DO źródła światła w przestrzeni 3D świata.
  final Vector3 sunDirectionWorld;

  /// Kąt elewacji słońca nad horyzontem [rad].
  final double sunElevationRadians;

  /// Kąt azymutu słońca na płaszczyźnie poziomej [rad].
  final double sunAzimuthRadians;

  /// Kolor światła otoczenia (ambient) zależny od pogody i pory dnia.
  final Color ambientLightColor;

  /// Barwa światła słonecznego / latarni (np. złocista w Golden Hour).
  final Color sunTintColor;

  /// Krycie cieni rzucanych na asfalt [0.0 – 1.0].
  final double shadowOpacity;

  /// Współczynnik maksymalnej długości cienia (zapobiega nieskończonym cieniom o zmierzchu).
  final double shadowLengthMultiplier;

  /// Intensywność błysku pioruna w oddali [0.0 – 1.0].
  final double lightningFlashIntensity;

  /// Czy nawierzchnia drogi jest mokra (deszcz / burza).
  final bool isWetSurface;

  /// Czy latarnie miejskie emitują światło.
  final bool streetlampsActive;

  const SunLightState({
    required this.sunDirectionWorld,
    required this.sunElevationRadians,
    required this.sunAzimuthRadians,
    required this.ambientLightColor,
    required this.sunTintColor,
    required this.shadowOpacity,
    required this.shadowLengthMultiplier,
    required this.lightningFlashIntensity,
    required this.isWetSurface,
    required this.streetlampsActive,
  });
}

/// Wynik projekcji cienia pojedynczego kolarza i roweru na powierzchnię drogi.
class ProjectedShadowResult {
  /// Punkt 3D czubka cienia kolarza (głowa/tułów) na płaszczyźnie jezdni.
  final Vector3 headShadowWorld;

  /// Punkt 3D przedniego końca cienia roweru na płaszczyźnie jezdni.
  final Vector3 frontWheelWorld;

  /// Punkt 3D tylnego końca cienia roweru na płaszczyźnie jezdni.
  final Vector3 rearWheelWorld;

  /// Długość rzutu cienia na płaszczyźnie drogi [m].
  final double projectedLengthMeters;

  /// Azymut cienia w płaszczyźnie poziomej X-Z [rad].
  final double shadowAzimuthRadians;

  const ProjectedShadowResult({
    required this.headShadowWorld,
    required this.frontWheelWorld,
    required this.rearWheelWorld,
    required this.projectedLengthMeters,
    required this.shadowAzimuthRadians,
  });
}

/// Zaawansowany renderer oświetlenia atmosferycznego, nieba, cieni rzucanych
/// przez kolarzy oraz odbić na mokrym asfalcie (`WetRoadSpecularReflection`) dla widoku 3D.
class DynamicSkyboxAndLightingPainter extends CustomPainter {
  final StageTimeOfDay timeOfDay;
  final WeatherCondition weatherCondition;
  final double cameraBearingRadians;
  final double elapsedSeconds;
  final double horizonYRatio;
  final DynamicLightingConfig config;
  final Scene3DMathProjection? projection;
  final List<PelotonRenderItem> pelotonRenderItems;
  final List<SupportVehicleInstance3D> supportVehicles;
  final RoadRibbonMesh? roadMesh;
  final double roadGradientPercent;

  // Zbuforowane obiekty Paint w celu uniknięcia alokacji w pętli 60/120 FPS.
  static final Paint _skyPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _sunHaloPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _sunCorePaint = Paint()..style = PaintingStyle.fill;
  static final Paint _cloudPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _cloudUndersidePaint = Paint()..style = PaintingStyle.fill;
  static final Paint _lightningGlowPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _lightningBoltPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final Paint _starPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _lampGlowPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _lampPostPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _dropShadowPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _bikeShadowLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _reflectionPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _reflectionStreakPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  const DynamicSkyboxAndLightingPainter({
    this.timeOfDay = const StageTimeOfDay.morningStart(),
    this.weatherCondition = WeatherCondition.sunny,
    this.cameraBearingRadians = 0.0,
    this.elapsedSeconds = 0.0,
    this.horizonYRatio = 0.44,
    this.config = const DynamicLightingConfig(),
    this.projection,
    this.pelotonRenderItems = const [],
    this.supportVehicles = const [],
    this.roadMesh,
    this.roadGradientPercent = 0.0,
  });

  /// Wylicza deterministyczny stan oświetlenia słonecznego i burzowego na podstawie
  /// pory dnia, pogody i czasu animacji.
  static SunLightState computeSunLightState({
    required StageTimeOfDay timeOfDay,
    required WeatherCondition weatherCondition,
    double elapsedSeconds = 0.0,
  }) {
    final double h = timeOfDay.decimalHours;
    final bool isRain = weatherCondition == WeatherCondition.lightRain ||
        weatherCondition == WeatherCondition.heavyStorm;
    final bool isStorm = weatherCondition == WeatherCondition.heavyStorm;
    final bool isOvercast = weatherCondition == WeatherCondition.overcast ||
        weatherCondition == WeatherCondition.crosswindGale;

    // Elewacja słońca: maksimum w okolicach 13:00 (~62°), nisko o 17:15 (~14°),
    // pod horyzontem w nocy (wówczas zastępuje je oświetlenie latarni z góry pod kątem).
    final double solarNoonDiff = (h - 13.0) / 7.2;
    final double rawElevationDeg = (62.0 * (1.0 - solarNoonDiff * solarNoonDiff)).clamp(-25.0, 65.0);

    // Azymut słońca przesuwa się ze wschodu (~85°) przez południe (~180°) na zachód (~275°).
    final double azimuthDeg = 75.0 + ((h - 6.0).clamp(0.0, 16.0) / 16.0) * 205.0;
    final double azimuthRad = azimuthDeg * (math.pi / 180.0);

    final bool streetlampsActive = timeOfDay.areStreetlampsActive;
    // W dzień gwarantujemy minimalny kąt elewacji 11°, aby cienie były wyraźne i czytelne na asfalcie;
    // w nocy światło pochodzi z wysokich latarni ulicznych (~52°).
    final double effectiveElevationDeg = streetlampsActive
        ? 52.0
        : rawElevationDeg.clamp(11.0, 65.0);
    final double elevationRad = effectiveElevationDeg * (math.pi / 180.0);

    final double cosEl = math.cos(elevationRad);
    final Vector3 sunDir = Vector3(
      math.sin(azimuthRad) * cosEl,
      math.sin(elevationRad),
      math.cos(azimuthRad) * cosEl,
    )..normalize();

    // Kolory światła i krycie cieni zależne od fazy dnia i pogody.
    Color ambientColor;
    Color sunTint;
    double baseShadowOpacity;

    switch (timeOfDay.phase) {
      case StageLightingPhase.dawn:
        ambientColor = const Color(0xFF8CA6C8);
        sunTint = const Color(0xFFFDBA74);
        baseShadowOpacity = 0.36;
      case StageLightingPhase.midday:
        ambientColor = const Color(0xFFDCEEFF);
        sunTint = weatherCondition == WeatherCondition.extremeHeat
            ? const Color(0xFFFFFBEB)
            : const Color(0xFFFFFFFF);
        baseShadowOpacity = 0.48;
      case StageLightingPhase.goldenHour:
        ambientColor = const Color(0xFFB46B5A);
        sunTint = AppColors.goldAccent;
        baseShadowOpacity = 0.44;
      case StageLightingPhase.twilight:
        ambientColor = const Color(0xFF475569);
        sunTint = const Color(0xFFF59E0B);
        baseShadowOpacity = 0.30;
      case StageLightingPhase.nightCriterium:
        ambientColor = const Color(0xFF1E293B);
        sunTint = const Color(0xFFFCD34D);
        baseShadowOpacity = 0.32;
    }

    if (isStorm) {
      ambientColor = Color.lerp(ambientColor, const Color(0xFF283244), 0.72)!;
      baseShadowOpacity *= 0.38;
    } else if (isRain) {
      ambientColor = Color.lerp(ambientColor, const Color(0xFF3E4A5E), 0.58)!;
      baseShadowOpacity *= 0.45;
    } else if (isOvercast) {
      ambientColor = Color.lerp(ambientColor, const Color(0xFF64748B), 0.45)!;
      baseShadowOpacity *= 0.58;
    }

    // Deterministyczne błyski burzowe w oddali podczas deszczu/ulewy.
    double lightningIntensity = 0.0;
    if (isRain) {
      final double cycle = elapsedSeconds % (isStorm ? 4.3 : 7.8);
      if (cycle < 0.14) {
        lightningIntensity = isStorm ? 0.95 : 0.55;
      } else if (cycle >= 0.22 && cycle < 0.34) {
        lightningIntensity = isStorm ? 0.72 : 0.35;
      }
    }

    final double lengthMultiplier = (1.0 / math.tan(elevationRad)).clamp(0.45, 3.8);

    return SunLightState(
      sunDirectionWorld: sunDir,
      sunElevationRadians: elevationRad,
      sunAzimuthRadians: azimuthRad,
      ambientLightColor: ambientColor,
      sunTintColor: sunTint,
      shadowOpacity: baseShadowOpacity.clamp(0.10, 0.60),
      shadowLengthMultiplier: lengthMultiplier,
      lightningFlashIntensity: lightningIntensity,
      isWetSurface: isRain,
      streetlampsActive: streetlampsActive,
    );
  }

  /// Wylicza dokładną geometrię 3D rzucanego cienia kolarza i roweru na pochyłą płaszczyznę drogi.
  ///
  /// Uwzględnia zarówno kierunek padania światła [sunState.sunDirectionWorld],
  /// jak i nachylenie drogi wyrażone przez wektor styczny [roadTangent], normalną [roadNormal]
  /// lub jawny spadek [roadGradientPercent].
  static ProjectedShadowResult computeProjectedShadowGeometry({
    required Vector3 riderBaseWorld,
    required Vector3 roadTangent,
    required Vector3 roadNormal,
    required SunLightState sunState,
    double riderHeightMeters = 1.48,
    double wheelbaseHalfMeters = 0.52,
    double? roadGradientPercent,
  }) {
    final Vector3 tangentNorm = roadTangent.normalized();
    Vector3 normalNorm = roadNormal.normalized();

    // Jeśli podano jawne nachylenie procentowe i normalna jest bliska pionowi,
    // przechylamy normalną zgodnie ze spadkiem drogi.
    if (roadGradientPercent != null && roadGradientPercent.abs() > 0.01) {
      final double slopeRad = math.atan(roadGradientPercent / 100.0);
      final Vector3 horizDir = Vector3(tangentNorm.x, 0.0, tangentNorm.z);
      if (horizDir.length2 > 1e-6) {
        horizDir.normalize();
        normalNorm = Vector3(
          -horizDir.x * math.sin(slopeRad),
          math.cos(slopeRad),
          -horizDir.z * math.sin(slopeRad),
        )..normalize();
      }
    }

    final Vector3 lightDir = sunState.sunDirectionWorld;
    // Rzutowanie punktu szczytowego kolarza wzdłuż promienia -L na płaszczyznę drogi (normalNorm).
    final double lDotN = lightDir.dot(normalNorm).clamp(0.24, 1.0);
    final double rayScale = (riderHeightMeters / lDotN).clamp(0.3, riderHeightMeters * 4.0);

    final Vector3 topPoint = riderBaseWorld + (normalNorm * riderHeightMeters);
    final Vector3 rawHit = topPoint - (lightDir * rayScale);

    // Rzutujemy punkt na płaszczyznę wyznaczoną przez riderBaseWorld i normalNorm dla pewności numerycznej.
    final Vector3 delta = rawHit - riderBaseWorld;
    final double distOffPlane = delta.dot(normalNorm);
    final Vector3 headShadowWorld = rawHit - (normalNorm * distOffPlane);

    final Vector3 shadowVector = headShadowWorld - riderBaseWorld;
    final double projectedLength = shadowVector.length;
    final double shadowAzimuth = math.atan2(shadowVector.x, shadowVector.z);

    final Vector3 frontWheelWorld = riderBaseWorld + (tangentNorm * wheelbaseHalfMeters);
    final Vector3 rearWheelWorld = riderBaseWorld - (tangentNorm * wheelbaseHalfMeters);

    return ProjectedShadowResult(
      headShadowWorld: headShadowWorld,
      frontWheelWorld: frontWheelWorld,
      rearWheelWorld: rearWheelWorld,
      projectedLengthMeters: projectedLength,
      shadowAzimuthRadians: shadowAzimuth,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double horizonY = (size.height * horizonYRatio).clamp(size.height * 0.15, size.height * 0.85);
    final SunLightState sunState = computeSunLightState(
      timeOfDay: timeOfDay,
      weatherCondition: weatherCondition,
      elapsedSeconds: elapsedSeconds,
    );

    renderSkybox(
      canvas: canvas,
      size: size,
      horizonY: horizonY,
      sunState: sunState,
    );

    final proj = projection;
    if (proj != null) {
      if (sunState.isWetSurface && config.enableWetRoadSpecularReflection) {
        renderWetRoadSpecularReflections(
          canvas: canvas,
          size: size,
          projection: proj,
          pelotonItems: pelotonRenderItems,
          supportVehicles: supportVehicles,
          sunState: sunState,
        );
      }

      if (config.enableProjectedDropShadows && pelotonRenderItems.isNotEmpty) {
        renderProjectedDropShadows(
          canvas: canvas,
          projection: proj,
          pelotonItems: pelotonRenderItems,
          sunState: sunState,
          roadGradientPercent: roadGradientPercent,
        );
      }
    }
  }

  // ===========================================================================
  // 1. PROCEDURALNY GRADIENT NIEBA, SŁOŃCE, CHMURY BURZOWE I LATARNIE PARYSKIE
  // ===========================================================================

  /// Renderuje proceduralne niebo zależne od pory dnia i pogody, tarczę słońca,
  /// stalowe chmury burzowe z błyskami w oddali oraz światła latarni w wieczornym kryterium.
  void renderSkybox({
    required Canvas canvas,
    required Size size,
    required double horizonY,
    required SunLightState sunState,
  }) {
    final double w = size.width;
    final double skyH = horizonY.clamp(1.0, size.height);
    final bool isRain = weatherCondition == WeatherCondition.lightRain ||
        weatherCondition == WeatherCondition.heavyStorm;
    final bool isStorm = weatherCondition == WeatherCondition.heavyStorm;
    final bool isOvercast = weatherCondition == WeatherCondition.overcast ||
        weatherCondition == WeatherCondition.crosswindGale;

    final List<Color> gradientColors = _resolveSkyPalette(
      phase: timeOfDay.phase,
      weather: weatherCondition,
      lightningIntensity: config.enableStormLightning ? sunState.lightningFlashIntensity : 0.0,
    );

    final skyRect = Rect.fromLTWH(0.0, 0.0, w, skyH + 2.0);
    _skyPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.0, 0.42, 0.78, 1.0],
      colors: gradientColors,
    ).createShader(skyRect);
    canvas.drawRect(skyRect, _skyPaint);
    _skyPaint.shader = null;

    // Gwiazdy w nocy (gdy brak ciężkiego deszczu).
    if (timeOfDay.phase == StageLightingPhase.nightCriterium && !isRain) {
      _drawNightStars(canvas, w, skyH);
    }

    // Tarcza słońca i korona atmosferyczna (poza nocą i ulewną burzą).
    if (config.enableSunDiscAndCorona &&
        timeOfDay.phase != StageLightingPhase.nightCriterium &&
        !isStorm) {
      _drawSunDiscAndCorona(
        canvas: canvas,
        w: w,
        horizonY: skyH,
        sunState: sunState,
        isObscuredByClouds: isRain || isOvercast,
      );
    }

    // Błysk burzowy w oddali na horyzoncie i podświetlenie chmur.
    if (isRain && config.enableStormLightning && sunState.lightningFlashIntensity > 0.01) {
      _drawDistantLightning(
        canvas: canvas,
        w: w,
        horizonY: skyH,
        intensity: sunState.lightningFlashIntensity,
      );
    }

    // Proceduralne warstwy chmur (stalowe chmury burzowe lub lekkie obłoki Golden Hour).
    _drawProceduralClouds(
      canvas: canvas,
      w: w,
      horizonY: skyH,
      sunState: sunState,
      isRain: isRain,
      isStorm: isStorm,
    );

    // Wieczorne latarnie miejskie (np. Paryż / kryterium nocne).
    if (sunState.streetlampsActive && config.enableEveningStreetlamps) {
      _drawEveningStreetlampsHorizon(canvas, w, skyH);
    }
  }

  List<Color> _resolveSkyPalette({
    required StageLightingPhase phase,
    required WeatherCondition weather,
    required double lightningIntensity,
  }) {
    List<Color> base;
    switch (phase) {
      case StageLightingPhase.dawn:
        base = const [
          Color(0xFF162447),
          Color(0xFF3E4E78),
          Color(0xFFD97757),
          Color(0xFFFDE68A),
        ];
      case StageLightingPhase.midday:
        if (weather == WeatherCondition.extremeHeat) {
          base = const [
            Color(0xFF0A325C),
            Color(0xFF1D65A6),
            Color(0xFF6BB2DB),
            Color(0xFFFDE8C8),
          ];
        } else {
          base = const [
            Color(0xFF0B2A4A),
            Color(0xFF195287),
            Color(0xFF4B91C2),
            Color(0xFFA7D3EC),
          ];
        }
      case StageLightingPhase.goldenHour:
        base = const [
          Color(0xFF1A223E),
          Color(0xFF5D3A58),
          Color(0xFFD97736),
          Color(0xFFF5C26B),
        ];
      case StageLightingPhase.twilight:
        base = const [
          Color(0xFF0B1120),
          Color(0xFF1E293B),
          Color(0xFF58384E),
          Color(0xFFB45309),
        ];
      case StageLightingPhase.nightCriterium:
        base = const [
          Color(0xFF060911),
          Color(0xFF0D1322),
          Color(0xFF1B2336),
          Color(0xFF2D2434),
        ];
    }

    if (weather == WeatherCondition.heavyStorm) {
      base = [
        Color.lerp(base[0], const Color(0xFF10151F), 0.85)!,
        Color.lerp(base[1], const Color(0xFF1D2535), 0.85)!,
        Color.lerp(base[2], const Color(0xFF2B3548), 0.82)!,
        Color.lerp(base[3], const Color(0xFF3E4A60), 0.80)!,
      ];
    } else if (weather == WeatherCondition.lightRain) {
      base = [
        Color.lerp(base[0], const Color(0xFF18202E), 0.72)!,
        Color.lerp(base[1], const Color(0xFF283347), 0.72)!,
        Color.lerp(base[2], const Color(0xFF3B485E), 0.68)!,
        Color.lerp(base[3], const Color(0xFF52627A), 0.65)!,
      ];
    } else if (weather == WeatherCondition.overcast ||
        weather == WeatherCondition.crosswindGale) {
      base = [
        Color.lerp(base[0], const Color(0xFF263345), 0.55)!,
        Color.lerp(base[1], const Color(0xFF3C4D63), 0.55)!,
        Color.lerp(base[2], const Color(0xFF64748B), 0.52)!,
        Color.lerp(base[3], const Color(0xFF94A3B8), 0.48)!,
      ];
    }

    if (lightningIntensity > 0.01) {
      final double flashMix = (lightningIntensity * 0.35).clamp(0.0, 0.4);
      base = [
        base[0],
        Color.lerp(base[1], const Color(0xFF7DD3FC), flashMix * 0.5)!,
        Color.lerp(base[2], const Color(0xFFBAE6FD), flashMix * 0.75)!,
        Color.lerp(base[3], const Color(0xFFE0F2FE), flashMix)!,
      ];
    }

    return base;
  }

  void _drawSunDiscAndCorona({
    required Canvas canvas,
    required double w,
    required double horizonY,
    required SunLightState sunState,
    required bool isObscuredByClouds,
  }) {
    // Rzutujemy azymut słońca względem kierunku patrzenia kamery na szerokość ekranu.
    double relAzimuth = sunState.sunAzimuthRadians - cameraBearingRadians;
    while (relAzimuth > math.pi) {
      relAzimuth -= math.pi * 2.0;
    }
    while (relAzimuth < -math.pi) {
      relAzimuth += math.pi * 2.0;
    }

    // Jeśli słońce jest z boku lub z przodu w szerokim polu widzenia.
    if (relAzimuth.abs() > 1.85) return;

    final double sunX = w * 0.5 + (relAzimuth / 1.55) * (w * 0.48);
    final double elevNorm = (sunState.sunElevationRadians / (math.pi * 0.4)).clamp(0.08, 1.0);
    final double sunY = horizonY * (1.0 - elevNorm * 0.82);

    final double opacityFactor = isObscuredByClouds ? 0.25 : 1.0;
    final double coronaRadius = (horizonY * 0.45).clamp(55.0, 180.0);

    _sunHaloPaint.shader = RadialGradient(
      colors: [
        sunState.sunTintColor.withValues(alpha: 0.45 * opacityFactor),
        sunState.sunTintColor.withValues(alpha: 0.14 * opacityFactor),
        sunState.sunTintColor.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.42, 1.0],
    ).createShader(Rect.fromCircle(center: Offset(sunX, sunY), radius: coronaRadius));
    canvas.drawCircle(Offset(sunX, sunY), coronaRadius, _sunHaloPaint);
    _sunHaloPaint.shader = null;

    if (!isObscuredByClouds) {
      final double discRadius = (horizonY * 0.055).clamp(8.0, 22.0);
      _sunCorePaint.color = Color.lerp(sunState.sunTintColor, Colors.white, 0.65)!
          .withValues(alpha: 0.92);
      canvas.drawCircle(Offset(sunX, sunY), discRadius, _sunCorePaint);
    }
  }

  void _drawDistantLightning({
    required Canvas canvas,
    required double w,
    required double horizonY,
    required double intensity,
  }) {
    final int seed = (elapsedSeconds * 0.5).floor();
    final double boltX = w * (0.22 + ((seed * 37) % 56) / 100.0);
    final double topY = horizonY * 0.14;

    // Poświata rozświetlająca horyzont za chmurami.
    final glowRadius = (horizonY * 0.55).clamp(60.0, 220.0);
    _lightningGlowPaint.shader = RadialGradient(
      colors: [
        const Color(0xFFE0F2FE).withValues(alpha: 0.55 * intensity),
        const Color(0xFF38BDF8).withValues(alpha: 0.18 * intensity),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset(boltX, topY + 25.0), radius: glowRadius));
    canvas.drawCircle(Offset(boltX, topY + 25.0), glowRadius, _lightningGlowPaint);
    _lightningGlowPaint.shader = null;

    // Zygzak wyładowania w oddali.
    final path = Path()..moveTo(boltX, topY);
    double curX = boltX;
    double curY = topY;
    final double stepY = (horizonY - topY) / 5.0;
    for (int i = 0; i < 5; i++) {
      curX += ((i.isEven ? 1.0 : -1.0) * (10.0 + ((seed + i) % 14)));
      curY += stepY;
      path.lineTo(curX, curY);
    }

    _lightningBoltPaint
      ..color = const Color(0xFFE0F2FE).withValues(alpha: 0.85 * intensity)
      ..strokeWidth = 2.0;
    canvas.drawPath(path, _lightningBoltPaint);
  }

  void _drawProceduralClouds({
    required Canvas canvas,
    required double w,
    required double horizonY,
    required SunLightState sunState,
    required bool isRain,
    required bool isStorm,
  }) {
    final int cloudCount = isStorm ? 8 : (isRain ? 6 : 4);
    final double speed = weatherCondition == WeatherCondition.crosswindGale ? 26.0 : 12.0;
    final double panOffset = (elapsedSeconds * speed - cameraBearingRadians * 85.0);

    final Color baseCloudColor = isStorm
        ? const Color(0xFF1F2736)
        : isRain
            ? const Color(0xFF334155)
            : Color.lerp(Colors.white, sunState.sunTintColor, 0.35)!;

    final double cloudAlpha = isStorm ? 0.72 : (isRain ? 0.55 : 0.22);
    _cloudPaint.color = baseCloudColor.withValues(alpha: cloudAlpha);
    _cloudUndersidePaint.color =
        const Color(0xFF0F172A).withValues(alpha: isStorm ? 0.45 : (isRain ? 0.28 : 0.06));

    for (int i = 0; i < cloudCount; i++) {
      final double wrapSpan = w + 320.0;
      final double rawX = (i * (wrapSpan / cloudCount) + panOffset) % wrapSpan;
      final double cx = (rawX < 0 ? rawX + wrapSpan : rawX) - 160.0;
      final double cy = horizonY * (0.18 + (i % 3) * 0.14);
      final double cw = 150.0 + (i % 4) * 42.0;
      final double ch = isStorm ? 46.0 : 32.0;

      // Ciemniejszy spód chmury burzowej.
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + ch * 0.22), width: cw * 0.92, height: ch * 0.7),
        _cloudUndersidePaint,
      );
      // Główna masa chmury (2 nachodzące płaty).
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: cw, height: ch),
        _cloudPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx - cw * 0.22, cy - ch * 0.14),
          width: cw * 0.58,
          height: ch * 0.75,
        ),
        _cloudPaint,
      );
    }
  }

  void _drawNightStars(Canvas canvas, double w, double horizonY) {
    _starPaint.color = Colors.white.withValues(alpha: 0.55);
    for (int i = 0; i < 28; i++) {
      final double sx = ((i * 197 + 43) % 1000) / 1000.0 * w;
      final double sy = ((i * 113 + 17) % 1000) / 1000.0 * (horizonY * 0.65);
      final double twinkle = 0.6 + 0.4 * math.sin(elapsedSeconds * 1.8 + i);
      _starPaint.color = Colors.white.withValues(alpha: 0.45 * twinkle);
      canvas.drawCircle(Offset(sx, sy), (i % 3 == 0) ? 1.5 : 1.0, _starPaint);
    }
  }

  void _drawEveningStreetlampsHorizon(Canvas canvas, double w, double horizonY) {
    final int lampCount = (w / 140.0).ceil().clamp(4, 14);
    final double spacing = w / lampCount;
    final double scroll = (cameraBearingRadians * 60.0) % spacing;

    _lampPostPaint
      ..color = const Color(0xFF334155)
      ..strokeWidth = 2.0;

    for (int i = -1; i <= lampCount; i++) {
      final double lx = i * spacing - scroll;
      final double topY = horizonY - 26.0;

      canvas.drawLine(Offset(lx, horizonY), Offset(lx, topY), _lampPostPaint);

      _lampGlowPaint.shader = RadialGradient(
        colors: [
          const Color(0xFFFDE68A).withValues(alpha: 0.85),
          const Color(0xFFF59E0B).withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(lx, topY), radius: 28.0));
      canvas.drawCircle(Offset(lx, topY), 28.0, _lampGlowPaint);
      _lampGlowPaint.shader = null;
    }
  }

  // ===========================================================================
  // 2. DYNAMICZNE CIENIE RZUCANE PRZEZ KOLARZY I ROWERY (PROJECTED DROP SHADOWS)
  // ===========================================================================

  /// Renderuje rzucane na asfalt cienie kolarzy i rowerów wyliczone z pozycji słońca
  /// oraz lokalnego nachylenia drogi.
  void renderProjectedDropShadows({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required List<PelotonRenderItem> pelotonItems,
    required SunLightState sunState,
    double? roadGradientPercent,
  }) {
    if (!config.enableProjectedDropShadows || pelotonItems.isEmpty) return;

    for (final item in pelotonItems) {
      if (!item.isVisibleInFrustum) continue;
      if (item.cameraDistance > config.maxShadowRenderDistanceMeters) continue;

      final double distanceFade =
          (1.0 - (item.cameraDistance / config.maxShadowRenderDistanceMeters)).clamp(0.0, 1.0);
      final double alpha = (sunState.shadowOpacity * distanceFade).clamp(0.04, 0.58);

      final RidingPosture? posture = item.animatedPose?.posture;
      final bool isStanding = posture == RidingPosture.standingClimb ||
          posture == RidingPosture.standingSprint;
      final bool isAeroTuck = posture == RidingPosture.superTuck;
      final double riderHeight = isStanding ? 1.62 : (isAeroTuck ? 1.24 : 1.46);

      final ProjectedShadowResult shadowGeom = computeProjectedShadowGeometry(
        riderBaseWorld: item.worldPosition,
        roadTangent: item.tangent,
        roadNormal: item.up,
        sunState: sunState,
        riderHeightMeters: riderHeight,
        roadGradientPercent: roadGradientPercent,
      );

      final pFront = projection.worldToScreen(shadowGeom.frontWheelWorld);
      final pRear = projection.worldToScreen(shadowGeom.rearWheelWorld);
      final pHeadShadow = projection.worldToScreen(shadowGeom.headShadowWorld);

      if (!pFront.isInFrontOfCamera || !pRear.isInFrontOfCamera || !pHeadShadow.isInFrontOfCamera) {
        continue;
      }

      // 1. Cień rzucany przez sylwetkę kolarza (rozciągnięty wielokąt od kół w stronę rzutu słońca).
      final Offset frontPt = Offset(pFront.screenX, pFront.screenY);
      final Offset rearPt = Offset(pRear.screenX, pRear.screenY);
      final Offset headPt = Offset(pHeadShadow.screenX, pHeadShadow.screenY);
      final Offset midWheel = Offset(
        (frontPt.dx + rearPt.dx) * 0.5,
        (frontPt.dy + rearPt.dy) * 0.5,
      );

      // Szerokość ramion kolarza w przestrzeni ekranowej.
      final double shoulderHalfPx = (item.screenScale * 5.2).clamp(1.5, 22.0);
      final Offset shadowDir = headPt - midWheel;
      final double shadowLenPx = shadowDir.distance;

      if (shadowLenPx > 1.5) {
        final Offset perp = Offset(-shadowDir.dy / shadowLenPx, shadowDir.dx / shadowLenPx);
        final Offset torsoMid = Offset.lerp(midWheel, headPt, 0.55)!;

        final shadowPath = Path()
          ..moveTo(rearPt.dx, rearPt.dy)
          ..lineTo(torsoMid.dx + perp.dx * shoulderHalfPx, torsoMid.dy + perp.dy * shoulderHalfPx)
          ..lineTo(headPt.dx + perp.dx * (shoulderHalfPx * 0.45), headPt.dy + perp.dy * (shoulderHalfPx * 0.45))
          ..lineTo(headPt.dx - perp.dx * (shoulderHalfPx * 0.45), headPt.dy - perp.dy * (shoulderHalfPx * 0.45))
          ..lineTo(torsoMid.dx - perp.dx * shoulderHalfPx, torsoMid.dy - perp.dy * shoulderHalfPx)
          ..lineTo(frontPt.dx, frontPt.dy)
          ..close();

        _dropShadowPaint.color = const Color(0xFF05080F).withValues(alpha: alpha * 0.72);
        canvas.drawPath(shadowPath, _dropShadowPaint);
      }

      // 2. Wyraźny cień kontaktowy ramy i kół na asfalcie.
      _bikeShadowLinePaint
        ..color = const Color(0xFF04060C).withValues(alpha: alpha)
        ..strokeWidth = (item.screenScale * 2.4).clamp(1.2, 8.0);
      canvas.drawLine(rearPt, frontPt, _bikeShadowLinePaint);
    }
  }

  // ===========================================================================
  // 3. EFEKT MOKREGO ASFALTU (WET ROAD SPECULAR REFLECTION)
  // ===========================================================================

  /// Renderuje lustrzane, rozmyte odbicia koszulek peletonu oraz czerwonych świateł tylnych
  /// samochodów dyrektora sportowego na mokrym asfalcie podczas deszczu.
  void renderWetRoadSpecularReflections({
    required Canvas canvas,
    required Size size,
    required Scene3DMathProjection projection,
    required List<PelotonRenderItem> pelotonItems,
    required List<SupportVehicleInstance3D> supportVehicles,
    required SunLightState sunState,
  }) {
    if (!config.enableWetRoadSpecularReflection || !sunState.isWetSurface) return;

    final bool isHeavyStorm = weatherCondition == WeatherCondition.heavyStorm;
    final double rainIntensity = isHeavyStorm ? 1.0 : 0.72;

    // 1. Odbicia przytłumionych kolorów koszulek peletonu na mokrym asfalcie.
    for (final item in pelotonItems) {
      if (!item.isVisibleInFrustum) continue;
      if (item.cameraDistance > config.maxReflectionRenderDistanceMeters) continue;

      final double distFade =
          (1.0 - (item.cameraDistance / config.maxReflectionRenderDistanceMeters)).clamp(0.0, 1.0);

      final Vector3 groundWorld = item.worldPosition;
      final Vector3 mirrorTipWorld = groundWorld - (item.up * 0.85);

      final pGround = projection.worldToScreen(groundWorld);
      final pMirror = projection.worldToScreen(mirrorTipWorld);
      if (!pGround.isInFrontOfCamera || !pMirror.isInFrontOfCamera) continue;

      final double streakHeight = (pMirror.screenY - pGround.screenY).abs().clamp(6.0, 56.0);
      final double streakWidth = (item.screenScale * 6.5).clamp(2.5, 22.0);

      // Przytłumiony kolor koszulki (zdesaturowany i wtopiony w ciemny mokry asfalt).
      final Color mutedJersey = Color.lerp(
        item.jerseyColor,
        const Color(0xFF1A2230),
        0.48,
      )!;
      final double alpha = (0.28 * rainIntensity * distFade).clamp(0.03, 0.30);

      final Rect streakRect = Rect.fromLTWH(
        pGround.screenX - streakWidth * 0.5,
        pGround.screenY,
        streakWidth,
        streakHeight,
      );

      _reflectionPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          mutedJersey.withValues(alpha: alpha),
          mutedJersey.withValues(alpha: alpha * 0.35),
          mutedJersey.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(streakRect);
      canvas.drawOval(streakRect, _reflectionPaint);
      _reflectionPaint.shader = null;
    }

    // 2. Czerwone światła tylne samochodów dyrektora sportowego i motocykli na mokrym asfalcie.
    for (final vehicle in supportVehicles) {
      final double distToCam = (vehicle.worldPosition - projection.cameraPosition).length;
      if (distToCam > config.maxReflectionRenderDistanceMeters * 1.25) continue;

      final double distFade =
          (1.0 - (distToCam / (config.maxReflectionRenderDistanceMeters * 1.25))).clamp(0.0, 1.0);
      final double halfLength = vehicle.type.lengthMeters * 0.48;
      final double halfWidth = vehicle.type.widthMeters * 0.36;

      final Vector3 rearCenter = vehicle.worldPosition - (vehicle.tangent * halfLength);
      final List<Vector3> tailLightsWorld = vehicle.type.isMotorbike
          ? [rearCenter]
          : [
              rearCenter - (vehicle.lateralRight * halfWidth),
              rearCenter + (vehicle.lateralRight * halfWidth),
            ];

      for (final lightPos in tailLightsWorld) {
        final Vector3 lightMirrorEnd = lightPos - (vehicle.surfaceNormal * 1.15);
        final pLight = projection.worldToScreen(lightPos);
        final pEnd = projection.worldToScreen(lightMirrorEnd);
        if (!pLight.isInFrontOfCamera || !pEnd.isInFrontOfCamera) continue;

        final double streakLen = (pEnd.screenY - pLight.screenY).abs().clamp(12.0, 92.0);
        final double streakW = (pLight.perspectiveScale * 5.0).clamp(2.5, 14.0);
        final double ripple = 0.85 + 0.15 * math.sin(elapsedSeconds * 11.0 + pLight.screenX * 0.1);
        final double redAlpha = (0.62 * rainIntensity * distFade * ripple).clamp(0.08, 0.68);

        final Rect tailRect = Rect.fromLTWH(
          pLight.screenX - streakW * 0.5,
          pLight.screenY,
          streakW,
          streakLen,
        );

        _reflectionPaint.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFEF4444).withValues(alpha: redAlpha),
            const Color(0xFFDC2626).withValues(alpha: redAlpha * 0.48),
            const Color(0xFF991B1B).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(tailRect);
        canvas.drawRect(tailRect, _reflectionPaint);
        _reflectionPaint.shader = null;

        // Wąski, ostry rdzeń odbicia światła tylnego.
        _reflectionStreakPaint
          ..color = const Color(0xFFFCA5A5).withValues(alpha: redAlpha * 0.65)
          ..strokeWidth = (streakW * 0.35).clamp(1.0, 4.0);
        canvas.drawLine(
          Offset(pLight.screenX, pLight.screenY),
          Offset(pLight.screenX, pLight.screenY + streakLen * 0.55),
          _reflectionStreakPaint,
        );
      }

      // Opcjonalne odbicie koguta ostrzegawczego wozu technicznego.
      if (vehicle.isBeaconFlashing) {
        final pBeaconGround = projection.worldToScreen(vehicle.worldPosition);
        if (pBeaconGround.isInFrontOfCamera) {
          final double pulse = 0.5 + 0.5 * math.sin(elapsedSeconds * 14.0 + vehicle.convoyIndex);
          final double r = (pBeaconGround.perspectiveScale * 18.0).clamp(6.0, 32.0);
          _reflectionPaint.shader = RadialGradient(
            colors: [
              AppColors.amberWarning.withValues(alpha: 0.25 * pulse * distFade),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(
            center: Offset(pBeaconGround.screenX, pBeaconGround.screenY + 4.0),
            radius: r,
          ));
          canvas.drawCircle(
            Offset(pBeaconGround.screenX, pBeaconGround.screenY + 4.0),
            r,
            _reflectionPaint,
          );
          _reflectionPaint.shader = null;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant DynamicSkyboxAndLightingPainter oldDelegate) {
    return oldDelegate.timeOfDay != timeOfDay ||
        oldDelegate.weatherCondition != weatherCondition ||
        (oldDelegate.cameraBearingRadians - cameraBearingRadians).abs() > 1e-4 ||
        (oldDelegate.elapsedSeconds - elapsedSeconds).abs() > 1e-4 ||
        oldDelegate.pelotonRenderItems.length != pelotonRenderItems.length ||
        oldDelegate.supportVehicles.length != supportVehicles.length ||
        oldDelegate.roadGradientPercent != roadGradientPercent;
  }
}
