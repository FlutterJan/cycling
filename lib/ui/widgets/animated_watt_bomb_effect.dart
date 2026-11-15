// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Typ ataku kolarskiego o ekstremalnej mocy (Watt Bomb).
enum WattBombSurgeType {
  /// Brak ekstremalnego ataku
  none,

  /// Potężny atak górski (powyżej 12 W/kg na wzniesieniu)
  mountainSurge,

  /// Eksplozywna bomba watowa w sprincie (powyżej 1400 W)
  sprintBomb,

  /// Legendarny atak łączony (jednocześnie >1400 W oraz >12 W/kg)
  legendarySurge;

  bool get isActive => this != WattBombSurgeType.none;
}

/// Paleta barwna impulsu świetlnego i poświaty.
enum WattBombColorTheme {
  /// Szkarłatna czerwień (#8E4A49) – agresywny, beztlenowy atak rywala lub finiszera
  crimson(Color(0xFF8E4A49), 'Agresywna Czerwień (#8E4A49)'),

  /// Szlachetne złoto (#D4AF37) – atak lidera wyścigu / kolarza gracza w żółtej koszulce
  gold(Color(0xFFD4AF37), 'Złoto Lidera (#D4AF37)'),

  /// Automatyczny dobór (Złoto dla kolarza gracza / lidera, Czerwień dla rywali i puncherów)
  auto(Color(0xFF8E4A49), 'Automatyczny dobór');

  final Color primaryColor;
  final String label;

  const WattBombColorTheme(this.primaryColor, this.label);
}

/// Klasa pomocnicza analizująca i wykrywająca eksplozje mocy kolarza.
class WattBombDetector {
  WattBombDetector._();

  /// Próg ataku w górach (12.0 W/kg)
  static const double mountainThresholdWkg = 12.0;

  /// Próg bomby watowej w sprincie (1400.0 W)
  static const double sprintThresholdWatts = 1400.0;

  /// Sprawdza, czy wartości telemetryczne przekraczają próg "Watt Bomb".
  static bool isWattBomb({
    required double watts,
    required double wkg,
    bool isMountain = false,
  }) {
    if (watts >= sprintThresholdWatts) return true;
    if (wkg >= mountainThresholdWkg) return true;
    if (isMountain && wkg >= mountainThresholdWkg) return true;
    return false;
  }

  /// Wykrywa szczegółowy typ zrywu mocy.
  static WattBombSurgeType detectSurge({
    required double watts,
    required double wkg,
    bool isMountain = false,
  }) {
    final bool isSprint = watts >= sprintThresholdWatts;
    final bool isMountainAttack = wkg >= mountainThresholdWkg;

    if (isSprint && isMountainAttack) {
      return WattBombSurgeType.legendarySurge;
    }
    if (isSprint) {
      return WattBombSurgeType.sprintBomb;
    }
    if (isMountainAttack) {
      return WattBombSurgeType.mountainSurge;
    }
    return WattBombSurgeType.none;
  }

  /// Zwraca etykietę tekstową dla danego typu ataku.
  static String getSurgeLabel(WattBombSurgeType type) {
    switch (type) {
      case WattBombSurgeType.legendarySurge:
        return 'LEGENDARY SURGE!';
      case WattBombSurgeType.sprintBomb:
        return 'WATT BOMB!';
      case WattBombSurgeType.mountainSurge:
        return 'ATTACK SURGE!';
      case WattBombSurgeType.none:
        return '';
    }
  }

  /// Zwraca opis taktyczny zrywu kolarza.
  static String getSurgeDescription(WattBombSurgeType type, double watts, double wkg) {
    switch (type) {
      case WattBombSurgeType.legendarySurge:
        return 'Monstrualny zryw! ${watts.round()}W • ${wkg.toStringAsFixed(1)} W/kg!';
      case WattBombSurgeType.sprintBomb:
        return 'Eksplozja mocy finiszera: ${watts.round()} W!';
      case WattBombSurgeType.mountainSurge:
        return 'Brutalny atak na ścianie: ${wkg.toStringAsFixed(1)} W/kg!';
      case WattBombSurgeType.none:
        return '';
    }
  }
}

/// CustomPainter malujący pulsujący impuls świetlny, koncentryczne fale uderzeniowe (shockwaves)
/// oraz iskry mocy (power sparks) wokół licznika mocy i sylwetki kolarza.
class WattBombAuraPainter extends CustomPainter {
  final double pulseProgress; // 0.0 - 1.0 z AnimationController
  final Color primaryColor;
  final Color secondaryColor;
  final double intensity; // 0.0 - 1.0
  final bool showSparks;

  WattBombAuraPainter({
    required this.pulseProgress,
    required this.primaryColor,
    required this.secondaryColor,
    this.intensity = 1.0,
    this.showSparks = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final minRadius = math.min(size.width, size.height) * 0.45;
    final maxRadius = math.max(size.width, size.height) * 0.95;

    // 1. Wewnętrzna, nasycona poświata radialna (Radial Inner Glow)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: 0.55 * intensity),
          secondaryColor.withValues(alpha: 0.25 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 0.85));

    canvas.drawCircle(center, maxRadius * 0.85, glowPaint);

    // 2. Trzy koncentryczne, rozszerzające się fale uderzeniowe (Shockwave Rings)
    const int ringCount = 3;
    for (int i = 0; i < ringCount; i++) {
      final ringProgress = (pulseProgress + (i / ringCount)) % 1.0;
      final ringRadius = minRadius + (maxRadius - minRadius) * ringProgress;

      // Płynny spadek przezroczystości wraz z oddalaniem się fali
      final ringAlpha = math.pow(1.0 - ringProgress, 1.6) * 0.85 * intensity;

      final ringPaint = Paint()
        ..color = primaryColor.withValues(alpha: ringAlpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = (3.5 * (1.0 - ringProgress) + 1.2);

      canvas.drawCircle(center, ringRadius, ringPaint);

      // Cień i rozmycie zewnętrznej fali
      if (ringProgress > 0.1 && ringProgress < 0.8) {
        final blurRingPaint = Paint()
          ..color = secondaryColor.withValues(alpha: (ringAlpha * 0.4).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0 * (1.0 - ringProgress)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

        canvas.drawCircle(center, ringRadius, blurRingPaint);
      }
    }

    // 3. Dynamiczne promienie / iskry energii (Power Sparks & Lightning Ticks)
    if (showSparks) {
      const int sparkCount = 14;
      final sparkPaint = Paint()
        ..color = secondaryColor.withValues(alpha: 0.9 * intensity)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.0;

      for (int i = 0; i < sparkCount; i++) {
        // Obrót promieni wokół środka z upływem czasu
        final angle = (i / sparkCount) * 2 * math.pi + (pulseProgress * 2 * math.pi);
        final sparkLength = 8.0 + math.sin(pulseProgress * math.pi * 4 + i) * 6.0;

        final startR = minRadius * 1.05;
        final endR = startR + sparkLength;

        final startPoint = Offset(
          center.dx + math.cos(angle) * startR,
          center.dy + math.sin(angle) * startR,
        );
        final endPoint = Offset(
          center.dx + math.cos(angle) * endR,
          center.dy + math.sin(angle) * endR,
        );

        canvas.drawLine(startPoint, endPoint, sparkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WattBombAuraPainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.intensity != intensity;
  }
}

/// Widget trzęsący kamerą (Camera Shake) imitujący przeciążenia prędkości i potężny zryw w peletonie.
class WattBombCameraShake extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final double intensity; // Amplituda drżenia w pikselach (np. 4.0 - 8.0)
  final Duration pulsePeriod;

  const WattBombCameraShake({
    super.key,
    required this.child,
    this.isActive = false,
    this.intensity = 5.0,
    this.pulsePeriod = const Duration(milliseconds: 320),
  });

  @override
  State<WattBombCameraShake> createState() => _WattBombCameraShakeState();
}

class _WattBombCameraShakeState extends State<WattBombCameraShake>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: widget.pulsePeriod,
    );

    if (widget.isActive) {
      _shakeController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WattBombCameraShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _shakeController.repeat();
      } else {
        _shakeController.animateTo(0.0, duration: const Duration(milliseconds: 150));
      }
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final t = _shakeController.value;

        // Wieloharmoniczne, pseudolosowe przesunięcie symulujące drżenie obiektywu kamery
        final dx = math.sin(t * 2 * math.pi * 3) * widget.intensity;
        final dy = math.cos(t * 2 * math.pi * 4.2) * (widget.intensity * 0.7);
        final angle = math.sin(t * 2 * math.pi * 2.1) * (widget.intensity * 0.0025);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.translationValues(dx, dy, 0.0)..rotateZ(angle),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Wizualna, animowana wstęga/odznaka informująca o eksplozji mocy (Watt Bomb Badge).
class WattBombSurgeBadge extends StatelessWidget {
  final WattBombSurgeType surgeType;
  final double watts;
  final double wkg;
  final Color primaryColor;
  final Color secondaryColor;
  final String? riderName;

  const WattBombSurgeBadge({
    super.key,
    required this.surgeType,
    required this.watts,
    required this.wkg,
    required this.primaryColor,
    required this.secondaryColor,
    this.riderName,
  });

  @override
  Widget build(BuildContext context) {
    final title = WattBombDetector.getSurgeLabel(surgeType);
    final isSprint = surgeType == WattBombSurgeType.sprintBomb;
    final icon = isSprint ? Icons.bolt : Icons.local_fire_department;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.6),
            blurRadius: 18,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: secondaryColor.withValues(alpha: 0.3),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: 0.25),
              border: Border.all(color: primaryColor, width: 1.5),
            ),
            child: Icon(icon, color: primaryColor, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (riderName != null && riderName!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      '• $riderName',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${watts.round()} W  |  ${wkg.toStringAsFixed(1)} W/kg',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Główny widget efektu wizualnego "Watt Bomb / Attack Surge".
///
/// Otacza licznik mocy, sylwetkę lub kartę kolarza:
/// - Gdy moc przekracza 1400 W lub 12 W/kg w górach (albo `isTriggered` = true),
///   uruchamia pulsujący impuls świetlny w kolorze czerwieni (#8E4A49) lub złota (#D4AF37).
/// - Wprowadza subtelne drżenie kamery (`WattBombCameraShake`) dla oddania prędkości i przeciążenia.
/// - Opcjonalnie wyświetla animowany baner HUD `WattBombSurgeBadge` oraz błysk winiety.
class AnimatedWattBombEffect extends StatefulWidget {
  /// Widget potomny (np. licznik mocy, awatar/sylwetka 3D kolarza, cała karta telemetryczna).
  final Widget child;

  /// Aktualna moc generowana przez kolarza w watach (W).
  final double currentWatts;

  /// Stosunek mocy do masy kolarza (W/kg).
  final double currentWkg;

  /// Czy odcinek trasy jest górski / podjazdowy.
  final bool isMountain;

  /// Opcjonalne bezpośrednie wymuszenie/wyzwolenie efektu (override).
  final bool? isTriggered;

  /// Wybór palety barw (szkarłatna czerwień #8E4A49, złoto #D4AF37 lub auto).
  final WattBombColorTheme colorTheme;

  /// Czy aktywować drżenie kamery od prędkości.
  final bool enableCameraShake;

  /// Amplituda drżenia kamery w pikselach.
  final double shakeIntensity;

  /// Czy wyświetlać animowaną odznakę informacyjną "WATT BOMB! / ATTACK SURGE!".
  final bool showSurgeBadge;

  /// Pozycja odznaki względem owijanego widgetu.
  final Alignment badgeAlignment;

  /// Czy wyświetlać pulsujący błysk winiety brzegowej.
  final bool showVignetteFlash;

  /// Imię lub nazwisko kolarza wykonującego zryw.
  final String? riderName;

  /// Czy kolarz reprezentuje zespół gracza (jeśli tak i colorTheme=auto, domyślnie używa złota).
  final bool isPlayerRider;

  /// Współczynnik powiększenia aury świetlnej wokół widgetu potomnego.
  final double auraScale;

  /// Czas trwania jednego pełnego cyklu pulsowania poświaty.
  final Duration pulseDuration;

  const AnimatedWattBombEffect({
    super.key,
    required this.child,
    this.currentWatts = 0.0,
    this.currentWkg = 0.0,
    this.isMountain = false,
    this.isTriggered,
    this.colorTheme = WattBombColorTheme.auto,
    this.enableCameraShake = true,
    this.shakeIntensity = 5.0,
    this.showSurgeBadge = true,
    this.badgeAlignment = Alignment.topCenter,
    this.showVignetteFlash = true,
    this.riderName,
    this.isPlayerRider = false,
    this.auraScale = 1.0,
    this.pulseDuration = const Duration(milliseconds: 550),
  });

  @override
  State<AnimatedWattBombEffect> createState() => _AnimatedWattBombEffectState();
}

class _AnimatedWattBombEffectState extends State<AnimatedWattBombEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: widget.pulseDuration,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (_shouldBeActive()) {
      _pulseController.repeat(reverse: true);
    }
  }

  bool _shouldBeActive() {
    if (widget.isTriggered != null) {
      return widget.isTriggered!;
    }
    return WattBombDetector.isWattBomb(
      watts: widget.currentWatts,
      wkg: widget.currentWkg,
      isMountain: widget.isMountain,
    );
  }

  WattBombSurgeType _getEffectiveSurgeType() {
    if (widget.isTriggered == true &&
        !WattBombDetector.isWattBomb(
          watts: widget.currentWatts,
          wkg: widget.currentWkg,
          isMountain: widget.isMountain,
        )) {
      // Jeśli wymuszono ręcznie, a parametry nie przekraczają progu
      return widget.isMountain
          ? WattBombSurgeType.mountainSurge
          : WattBombSurgeType.sprintBomb;
    }

    return WattBombDetector.detectSurge(
      watts: widget.currentWatts,
      wkg: widget.currentWkg,
      isMountain: widget.isMountain,
    );
  }

  Color _resolvePrimaryColor() {
    switch (widget.colorTheme) {
      case WattBombColorTheme.crimson:
        return const Color(0xFF8E4A49); // Dokładna czerwień z promptu
      case WattBombColorTheme.gold:
        return const Color(0xFFD4AF37); // Dokładne złoto z promptu
      case WattBombColorTheme.auto:
        // Złoto dla kolarza gracza lub lidera, Czerwień dla rywala/punchera
        if (widget.isPlayerRider) {
          return const Color(0xFFD4AF37);
        } else {
          return const Color(0xFF8E4A49);
        }
    }
  }

  Color _resolveSecondaryColor(Color primary) {
    if (primary == const Color(0xFF8E4A49)) {
      return const Color(0xFFDC2626); // Jaskrawsza czerwień akcentująca
    } else {
      return const Color(0xFFFFE066); // Błyszczące złoto akcentujące
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedWattBombEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nowActive = _shouldBeActive();
    final wasActive = oldWidget.isTriggered ??
        WattBombDetector.isWattBomb(
          watts: oldWidget.currentWatts,
          wkg: oldWidget.currentWkg,
          isMountain: oldWidget.isMountain,
        );

    if (nowActive != wasActive) {
      if (nowActive) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.animateTo(0.0, duration: const Duration(milliseconds: 200));
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = _shouldBeActive();
    final Color primaryColor = _resolvePrimaryColor();
    final Color secondaryColor = _resolveSecondaryColor(primaryColor);
    final surgeType = _getEffectiveSurgeType();

    Widget content = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // 1. Warstwa aury i fal uderzeniowych w tle (Aura Painter)
        if (isActive)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: WattBombAuraPainter(
                      pulseProgress: _pulseController.value,
                      primaryColor: primaryColor,
                      secondaryColor: secondaryColor,
                      intensity: 1.0,
                    ),
                  );
                },
              ),
            ),
          ),

        // 2. Poświata krawędziowa i winieta świetlna wokół widgetu
        if (isActive && widget.showVignetteFlash)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final alpha = (0.25 + _pulseController.value * 0.25).clamp(0.0, 1.0);
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: alpha),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: alpha * 0.7),
                          blurRadius: 20 * widget.auraScale,
                          spreadRadius: 3 * widget.auraScale,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

        // 3. Właściwy widget potomny (licznik mocy / avatar / HUD) z pulsacją skali
        if (isActive)
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: widget.child,
          )
        else
          widget.child,

        // 4. Odznaka / Baner "WATT BOMB! / ATTACK SURGE!"
        if (isActive && widget.showSurgeBadge && surgeType.isActive)
          Align(
            alignment: widget.badgeAlignment,
            child: FractionalTranslation(
              translation: const Offset(0.0, -0.65),
              child: WattBombSurgeBadge(
                surgeType: surgeType,
                watts: widget.currentWatts,
                wkg: widget.currentWkg,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                riderName: widget.riderName,
              ),
            ),
          ),
      ],
    );

    // 5. Nałożenie efektu drżenia kamery od prędkości (Camera Shake)
    if (widget.enableCameraShake) {
      return WattBombCameraShake(
        isActive: isActive,
        intensity: widget.shakeIntensity,
        child: content,
      );
    }

    return content;
  }
}
