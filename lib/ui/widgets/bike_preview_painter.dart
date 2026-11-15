import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/equipment/frame_model.dart';
import '../../models/equipment/groupset_model.dart';
import '../../models/equipment/tire_model.dart';
import '../../models/equipment/wheelset_model.dart';

/// Zaawansowany widżet wizualizacji 2D skonfigurowanego roweru wyścigowego (`BikePreviewWidget`).
/// Rysuje profil boczny napędu (drive-side) z uwzględnieniem:
/// - Kształtu rur ramy (masywne profile aero z wycięciem na koło vs smukłe rury górskie vs TT),
/// - Wysokości stożków kół karbonowych (35mm vs 50mm vs 65mm vs pełny dysk aero),
/// - Kolorystyki ścianki opon (klasyczna bawełniana tan-wall vs czarna stealth),
/// - Kąta pochylenia kokpitu i mostka (slammed stem vs spacery) oraz koloru owijki,
/// - Kompletnego osprzętu (korba, kaseta, łańcuch, tarcze hamulcowe, przerzutka).
class BikePreviewWidget extends StatelessWidget {
  /// Skonfigurowana maszyna wyścigowa
  final CompleteBike bike;

  /// Szerokość widżetu (opcjonalna, dostosowuje się elastycznie)
  final double? width;

  /// Wysokość widżetu (opcjonalna, zachowuje proporcje 16:9/16:10)
  final double? height;

  /// Wymuszenie koloru ścianki opony (null = automatyczne wykrycie z modelu opony)
  final bool? isTanWallOverride;

  /// Wymuszenie koloru owijki kierownicy (null = elegancka czerń lub dopasowanie do ramy)
  final Color? barTapeColorOverride;

  /// Wymuszenie koloru ramy (null = pobierany z [bike.frame.primaryColorHex])
  final Color? frameColorOverride;

  /// Czy renderować tło i cień podłoża
  final bool showBackground;

  /// Kolor tła
  final Color? backgroundColor;

  /// Czy wyświetlać dolny pasek telemetryczny ze specyfikacją roweru (waga, CdA, stożki)
  final bool showSpecsPill;

  /// Czy wyświetlać cień podłoża
  final bool showFloorReflection;

  /// Akcja po kliknięciu w rower
  final VoidCallback? onTap;

  const BikePreviewWidget({
    super.key,
    required this.bike,
    this.width,
    this.height,
    this.isTanWallOverride,
    this.barTapeColorOverride,
    this.frameColorOverride,
    this.showBackground = true,
    this.backgroundColor,
    this.showSpecsPill = false,
    this.showFloorReflection = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Automatyczne wykrycie ścianki tan-wall po nazwie opony lub nadpisanie
    final bool isTanWall = isTanWallOverride ?? _detectTanWall(bike.tire.name);

    final resolvedFrameColor = frameColorOverride ??
        _parseHexColor(bike.frame.primaryColorHex, const Color(0xFFDC2626));

    final resolvedBarTapeColor = barTapeColorOverride ??
        (bike.frame.category == FrameCategory.lightweightClimbing
            ? Colors.white
            : const Color(0xFF1C1D22));

    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final double effectiveWidth = width ?? constraints.maxWidth;
        final double effectiveHeight = height ?? (effectiveWidth / 1.7);

        return Container(
          width: effectiveWidth,
          height: effectiveHeight,
          decoration: showBackground
              ? BoxDecoration(
                  color: backgroundColor ?? const Color(0xFF11141B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                )
              : null,
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              // Wektorowy silnik malujący profil roweru
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(effectiveHeight * 0.05),
                  child: CustomPaint(
                    painter: BikePreviewPainter(
                      bike: bike,
                      frameColor: resolvedFrameColor,
                      barTapeColor: resolvedBarTapeColor,
                      isTanWall: isTanWall,
                      showFloorReflection: showFloorReflection,
                    ),
                  ),
                ),
              ),

              // Opcjonalna plakietka specyfikacji UCI na dole widżetu
              if (showSpecsPill)
                Positioned(
                  left: 12,
                  bottom: 8,
                  right: 12,
                  child: _buildSpecsPill(),
                ),
            ],
          ),
        );
      },
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }

  Widget _buildSpecsPill() {
    final frame = bike.frame;
    final wheelset = bike.wheelset;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                frame.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getCategoryLabel(frame.category),
                  style: const TextStyle(
                    color: AppColors.goldAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '${bike.totalWeightKg.toStringAsFixed(2)} kg',
                style: TextStyle(
                  color: bike.hasUciBallast ? AppColors.goldAccent : AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Stożek: ${wheelset.isDiscWheel ? "Dysk TT" : "${wheelset.rimDepthMm}mm"}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _getCategoryLabel(FrameCategory cat) {
    switch (cat) {
      case FrameCategory.aero:
        return 'AERO';
      case FrameCategory.lightweightClimbing:
        return 'CLIMB';
      case FrameCategory.timeTrial:
        return 'TT';
      case FrameCategory.cobbleEndurance:
        return 'ROUBAIX';
      case FrameCategory.allRounder:
        return 'ALL-ROUND';
    }
  }

  static bool _detectTanWall(String tireName) {
    final lower = tireName.toLowerCase();
    return lower.contains('tan') ||
        lower.contains('cotton') ||
        lower.contains('classic') ||
        lower.contains('corsa') ||
        lower.contains('gum');
  }

  static Color _parseHexColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      String clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        clean = 'FF$clean';
      }
      return Color(int.parse(clean, radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}

/// Wejściowy silnik malujący profil boczny roweru w znormalizowanym układzie współrzędnych 240x140.
class BikePreviewPainter extends CustomPainter {
  final CompleteBike bike;
  final Color frameColor;
  final Color barTapeColor;
  final bool isTanWall;
  final bool showFloorReflection;

  BikePreviewPainter({
    required this.bike,
    required this.frameColor,
    required this.barTapeColor,
    required this.isTanWall,
    required this.showFloorReflection,
  });

  // Główne punkty geometrii ramy (Współrzędne wirtualne 240 x 140)
  static const double rearAxleX = 48.0;
  static const double rearAxleY = 90.0;
  static const double frontAxleX = 186.0;
  static const double frontAxleY = 90.0;
  static const double bbX = 96.0;
  static const double bbY = 96.0;
  static const double wheelRadius = 30.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Skalowanie płótna do docelowego rozmiaru widżetu
    final double scaleX = size.width / 240.0;
    final double scaleY = size.height / 140.0;
    final double scale = math.min(scaleX, scaleY);

    // Wycentrowanie roweru w obszarze widżetu
    final double offsetX = (size.width - 240.0 * scale) / 2.0;
    final double offsetY = (size.height - 140.0 * scale) / 2.0;

    canvas.translate(offsetX, offsetY);
    canvas.scale(scale, scale);

    final isAero = bike.frame.category == FrameCategory.aero;
    final isClimbing = bike.frame.category == FrameCategory.lightweightClimbing;
    final isTT = bike.frame.category == FrameCategory.timeTrial;

    // 1. Cień podłoża i kół (Floor shadow)
    if (showFloorReflection) {
      _drawFloorShadow(canvas);
    }

    // 2. Tylne koło (Obręcz karbonowa, szprychy / Dysk TT, tarcza hamulcowa, opona)
    _drawWheel(
      canvas: canvas,
      centerX: rearAxleX,
      centerY: rearAxleY,
      isRearWheel: true,
      wheelset: bike.wheelset,
      tire: bike.tire,
    );

    // 3. Przednie koło
    _drawWheel(
      canvas: canvas,
      centerX: frontAxleX,
      centerY: frontAxleY,
      isRearWheel: false,
      wheelset: bike.wheelset,
      tire: bike.tire,
    );

    // 4. Rama rowerowa: trójkąt przedni i tylny (zależnie od Aero / Climb / TT)
    _drawFrameAndFork(canvas, isAero: isAero, isClimbing: isClimbing, isTT: isTT);

    // 5. Napęd (Korba z tarczami 54/40T, kaseta, łańcuch, tylna przerzutka)
    _drawDrivetrain(canvas, bike.groupset);

    // 6. Sztyca podsiodłowa i siodełko
    _drawSeatpostAndSaddle(canvas, isAero: isAero, isTT: isTT);

    // 7. Kokpit: mostek, podkładki (slammed stem), kierownica, owijka i klamkomanetki
    _drawCockpit(canvas, isTT: isTT);

    // 8. Koszyki na bidony (na rurze skośnej i podsiodłowej)
    _drawBottleCages(canvas);

    canvas.restore();
  }

  // ==========================================
  // 1. CIEŃ PODŁOŻA
  // ==========================================
  void _drawFloorShadow(Canvas canvas) {
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.85,
        colors: [
          Colors.black.withValues(alpha: 0.45),
          Colors.transparent,
        ],
      ).createShader(const Rect.fromLTWH(20, 118, 200, 12));

    canvas.drawOval(const Rect.fromLTWH(26, 118, 188, 7), shadowPaint);
  }

  // ==========================================
  // 2. KOŁA, OBRĘCZE, SZPRYCHY I OPONY
  // ==========================================
  void _drawWheel({
    required Canvas canvas,
    required double centerX,
    required double centerY,
    required bool isRearWheel,
    required WheelsetModel wheelset,
    required TireModel tire,
  }) {
    final center = Offset(centerX, centerY);

    // A. Pełny dysk aerodynamiczny TT (Disc wheel na tylnym kole)
    final bool isDisc = isRearWheel && wheelset.isDiscWheel;

    if (isDisc) {
      // Monolityczny dysk karbonowy
      final discPaint = Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.2, -0.3),
          radius: 0.9,
          colors: [
            Color(0xFF2C2F36),
            Color(0xFF191B20),
            Color(0xFF0F1014),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 27.5));

      canvas.drawCircle(center, 27.5, discPaint);

      // Karbonowy refleks soczewkowy
      final reflectionPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.transparent,
            Colors.white.withValues(alpha: 0.04),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: 27.5));

      canvas.drawCircle(center, 27.5, reflectionPaint);

      // Logotyp wyścigowy na dysku
      final decalPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, 18.0, decalPaint);
    } else {
      // B. Klasyczne koło ze szprychami i stożkiem karbonowym
      // Wysokość stożka: rimDepthMm (np. 35mm -> 3.5, 50mm -> 5.2, 65mm -> 7.0, 80mm -> 9.0)
      final double rimDepth = (wheelset.rimDepthMm / 10.0).clamp(2.5, 9.5);
      final double innerRimRadius = 27.5 - rimDepth;

      // Szprychy aerodynamiczne (Aero bladed spokes)
      final spokePaint = Paint()
        ..color = const Color(0xFF1A1A1A)
        ..strokeWidth = 0.7;

      const int spokeCount = 18;
      for (int i = 0; i < spokeCount; i++) {
        final double angle = (i * 2.0 * math.pi) / spokeCount;
        final double cosA = math.cos(angle);
        final double sinA = math.sin(angle);

        final p1 = Offset(centerX + cosA * 4.0, centerY + sinA * 4.0);
        final p2 = Offset(centerX + cosA * innerRimRadius, centerY + sinA * innerRimRadius);
        canvas.drawLine(p1, p2, spokePaint);
      }

      // Karbonowy profil stożka (Carbon Fairing Rim)
      final rimPath = Path()
        ..addOval(Rect.fromCircle(center: center, radius: 27.5))
        ..addOval(Rect.fromCircle(center: center, radius: innerRimRadius))
        ..fillType = PathFillType.evenOdd;

      final rimShader = const SweepGradient(
        center: Alignment.center,
        colors: [
          Color(0xFF262830),
          Color(0xFF141518),
          Color(0xFF2B2D36),
          Color(0xFF141518),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 27.5));

      canvas.drawPath(rimPath, Paint()..shader = rimShader);

      // Krawędź wewnętrzna obręczy
      canvas.drawCircle(
        center,
        innerRimRadius,
        Paint()
          ..color = const Color(0xFF0D0E12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // C. Opona szosowa (Bieżnik + Ścianka Tan-Wall / Black-Wall)
    const double tireInnerRadius = 27.5;
    const double tireOuterRadius = wheelRadius; // 30.0

    if (isTanWall) {
      // Klasyczna bawełniana ścianka gumowa (Tan-Wall / Gumwall)
      final tanWallPath = Path()
        ..addOval(Rect.fromCircle(center: center, radius: 29.2))
        ..addOval(Rect.fromCircle(center: center, radius: tireInnerRadius))
        ..fillType = PathFillType.evenOdd;

      final tanWallPaint = Paint()..color = const Color(0xFFD2A679);
      canvas.drawPath(tanWallPath, tanWallPaint);

      // Czarna gumowa strefa styku z asfaltem (Tread)
      final treadPath = Path()
        ..addOval(Rect.fromCircle(center: center, radius: tireOuterRadius))
        ..addOval(Rect.fromCircle(center: center, radius: 29.2))
        ..fillType = PathFillType.evenOdd;

      final treadPaint = Paint()..color = const Color(0xFF1A1A1E);
      canvas.drawPath(treadPath, treadPaint);
    } else {
      // Jednolita czarna opona wyścigowa (All-Black Stealth)
      final blackTirePath = Path()
        ..addOval(Rect.fromCircle(center: center, radius: tireOuterRadius))
        ..addOval(Rect.fromCircle(center: center, radius: tireInnerRadius))
        ..fillType = PathFillType.evenOdd;

      final blackTirePaint = Paint()..color = const Color(0xFF18191D);
      canvas.drawPath(blackTirePath, blackTirePaint);

      // Cień bieżnika
      canvas.drawCircle(
        center,
        29.6,
        Paint()
          ..color = const Color(0xFF25272E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // D. Tarcza hamulcowa (Disc Brake Rotor - 160mm/140mm)
    final rotorPaint = Paint()..color = const Color(0xFF9CA3AF);
    canvas.drawCircle(center, 9.5, Paint()..color = const Color(0xFF2E3138));
    canvas.drawCircle(
      center,
      9.0,
      Paint()
        ..color = rotorPaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Otwory chłodzące w tarczy
    for (int i = 0; i < 6; i++) {
      final double rAngle = (i * math.pi) / 3.0;
      final double rX = centerX + math.cos(rAngle) * 6.5;
      final double rY = centerY + math.sin(rAngle) * 6.5;
      canvas.drawCircle(Offset(rX, rY), 0.7, Paint()..color = const Color(0xFF141518));
    }

    // Zacisk hamulca tarczowego (Caliper)
    final caliperPaint = Paint()..color = const Color(0xFF1E2024);
    if (isRearWheel) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(53, 83, 4.5, 7), const Radius.circular(1.0)),
        caliperPaint,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(180, 83, 4.5, 7), const Radius.circular(1.0)),
        caliperPaint,
      );
    }

    // E. Piasta koła z osią Thru-Axle
    canvas.drawCircle(center, 3.8, Paint()..color = const Color(0xFF111215));
    canvas.drawCircle(center, 1.8, Paint()..color = const Color(0xFF6B7280));
  }

  // ==========================================
  // 3. RAMA I WIDELEC (AERO / CLIMB / TT)
  // ==========================================
  void _drawFrameAndFork(
    Canvas canvas, {
    required bool isAero,
    required bool isClimbing,
    required bool isTT,
  }) {
    // Węzły geometryczne ramy
    const forkCrown = Offset(171.0, 48.0);
    final headTubeTop = isTT
        ? const Offset(167.0, 31.0)
        : (isClimbing ? const Offset(165.0, 34.5) : const Offset(166.0, 32.5));

    final seatCluster = isTT
        ? const Offset(87.0, 48.0) // Bardziej stromy kąt 78° dla pozycji czasowej
        : const Offset(83.0, 49.0);

    const bb = Offset(bbX, bbY); // (96.0, 96.0)

    // Grubość rur w zależności od kategorii ramy
    final double downTubeWidth = isTT ? 9.5 : (isAero ? 7.6 : (isClimbing ? 3.6 : 5.4));
    final double topTubeWidth = isTT ? 5.2 : (isAero ? 4.8 : (isClimbing ? 3.2 : 4.0));
    final double seatStayWidth = isClimbing ? 2.0 : (isAero ? 3.2 : 2.6);
    final double chainStayWidth = isAero ? 4.8 : 3.4;

    // Paleta cieniowania lakieru ramy
    final frameBase = frameColor;
    final frameHighlight = _adjustHsl(frameBase, lightnessDelta: 0.16);
    final frameShadow = _adjustHsl(frameBase, lightnessDelta: -0.18);

    final frameShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [frameHighlight, frameBase, frameShadow],
    ).createShader(const Rect.fromLTWH(40, 25, 150, 75));

    final mainFramePaint = Paint()..shader = frameShader;

    // A. Tylny trójkąt: Dolne widełki (Chainstays)
    final chainstayPath = Path()
      ..moveTo(rearAxleX, rearAxleY - 1.5)
      ..lineTo(bbX, bbY - 2.0)
      ..lineTo(bbX, bbY + (chainStayWidth - 2.0))
      ..lineTo(rearAxleX, rearAxleY + 2.0)
      ..close();
    canvas.drawPath(chainstayPath, mainFramePaint);

    // B. Tylny trójkąt: Górne widełki (Seatstays)
    // Nowoczesne ramy aero i all-rounder mają obniżone widełki (Dropped seatstays)
    final seatstayAttachment = isClimbing
        ? seatCluster // Wspinaczkowe: widełki łączą się bezpośrednio przy sztycy
        : (isTT ? const Offset(88.5, 58.0) : const Offset(85.5, 60.5)); // Aero/TT: obniżone

    final seatstayPath = Path()
      ..moveTo(rearAxleX, rearAxleY - 1.8)
      ..lineTo(seatstayAttachment.dx, seatstayAttachment.dy)
      ..lineTo(seatstayAttachment.dx + 1.8, seatstayAttachment.dy + 1.8)
      ..lineTo(rearAxleX + 2.5, rearAxleY + 1.0)
      ..close();
    canvas.drawPath(seatstayPath, mainFramePaint);

    // C. Rura podsiodłowa (Seat Tube)
    final seatTubePath = Path();
    if (isAero || isTT) {
      // Aerodynamiczne wycięcie obejmujące tylne koło (Rear Wheel Fairing Cutout)
      seatTubePath.moveTo(seatCluster.dx - 2.5, seatCluster.dy);
      seatTubePath.lineTo(seatCluster.dx + 3.0, seatCluster.dy);
      seatTubePath.lineTo(bb.dx + 3.5, bb.dy - 1.0);
      seatTubePath.lineTo(bb.dx - 3.5, bb.dy);
      // Krzywizna wycięcia aero na koło
      seatTubePath.cubicTo(
        bb.dx - 12.0,
        bb.dy - 15.0,
        rearAxleX + 28.5,
        rearAxleY - 12.0,
        seatCluster.dx - 2.5,
        seatCluster.dy,
      );
      seatTubePath.close();
    } else {
      // Klasyczna smukła rura podsiodłowa
      seatTubePath.moveTo(seatCluster.dx - 2.0, seatCluster.dy);
      seatTubePath.lineTo(seatCluster.dx + 2.0, seatCluster.dy);
      seatTubePath.lineTo(bb.dx + 2.4, bb.dy);
      seatTubePath.lineTo(bb.dx - 2.4, bb.dy);
      seatTubePath.close();
    }
    canvas.drawPath(seatTubePath, mainFramePaint);

    // D. Rura dolna (Down Tube) - Masywny profil Kammtail w aero
    final downTubePath = Path()
      ..moveTo(forkCrown.dx - 1.0, forkCrown.dy)
      ..lineTo(forkCrown.dx + 2.5, forkCrown.dy + 2.5)
      ..lineTo(bb.dx + 4.0, bb.dy - 1.0)
      ..lineTo(bb.dx - (downTubeWidth - 4.0), bb.dy + 1.0)
      ..close();
    canvas.drawPath(downTubePath, mainFramePaint);

    // Opcjonalny napis / pasek aerodynamiczny na rurze dolnej
    final decalStripe = Path()
      ..moveTo(forkCrown.dx - 0.5, forkCrown.dy + 1.5)
      ..lineTo(forkCrown.dx + 1.5, forkCrown.dy + 3.0)
      ..lineTo(bb.dx + 2.5, bb.dy - 1.0)
      ..lineTo(bb.dx + 0.5, bb.dy - 1.0)
      ..close();
    canvas.drawPath(decalStripe, Paint()..color = Colors.white.withValues(alpha: 0.28));

    // E. Rura górna (Top Tube)
    final topTubePath = Path()
      ..moveTo(seatCluster.dx - 1.0, seatCluster.dy - 1.5)
      ..lineTo(headTubeTop.dx, headTubeTop.dy - 1.0)
      ..lineTo(headTubeTop.dx + 1.0, headTubeTop.dy + topTubeWidth)
      ..lineTo(seatCluster.dx, seatCluster.dy + topTubeWidth)
      ..close();
    canvas.drawPath(topTubePath, mainFramePaint);

    // F. Główka ramy (Head Tube)
    final headTubePath = Path()
      ..moveTo(headTubeTop.dx - 2.0, headTubeTop.dy)
      ..lineTo(headTubeTop.dx + 4.5, headTubeTop.dy)
      ..lineTo(forkCrown.dx + 4.5, forkCrown.dy)
      ..lineTo(forkCrown.dx - 2.0, forkCrown.dy)
      ..close();
    canvas.drawPath(headTubePath, mainFramePaint);

    // G. Widelec przedni (Aero Bladed Fork)
    final forkPath = Path()
      ..moveTo(forkCrown.dx - 1.5, forkCrown.dy)
      ..lineTo(forkCrown.dx + 3.5, forkCrown.dy)
      ..lineTo(frontAxleX + 2.0, frontAxleY)
      ..lineTo(frontAxleX - 2.0, frontAxleY)
      ..close();
    canvas.drawPath(forkPath, mainFramePaint);
  }

  // ==========================================
  // 4. NAPĘD (DRIVETRAIN)
  // ==========================================
  void _drawDrivetrain(Canvas canvas, GroupsetModel groupset) {
    const bb = Offset(bbX, bbY);

    // A. Tarcze korby (Duża 54T i Mała 40T)
    final chainringOuter = Paint()
      ..shader = const SweepGradient(
        center: Alignment.center,
        colors: [
          Color(0xFF374151),
          Color(0xFF1F2937),
          Color(0xFF4B5563),
          Color(0xFF1F2937),
        ],
      ).createShader(Rect.fromCircle(center: bb, radius: 9.5));

    canvas.drawCircle(bb, 9.5, chainringOuter);
    canvas.drawCircle(bb, 7.2, Paint()..color = const Color(0xFF111827));

    // B. Ramię korby z pedałem zatrzaskowym
    final crankArmPaint = Paint()
      ..color = const Color(0xFF1F2937)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    // Ramię korby skierowane w dół/do przodu (pozycja dynamiczna)
    const pedalCenter = Offset(bbX + 8.5, bbY + 12.0);
    canvas.drawLine(bb, pedalCenter, crankArmPaint);

    // Pedał zatrzaskowy (Clipless pedal)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pedalCenter, width: 4.5, height: 2.2),
        const Radius.circular(0.6),
      ),
      Paint()..color = const Color(0xFF9CA3AF),
    );

    // C. Kaseta zębatek (12-speed Cassette) na tylnej piaście
    final cassettePaint = Paint()
      ..color = const Color(0xFF6B7280)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(const Offset(rearAxleX, rearAxleY), 6.5, Paint()..color = const Color(0xFF374151));
    canvas.drawCircle(const Offset(rearAxleX, rearAxleY), 5.0, cassettePaint);
    canvas.drawCircle(const Offset(rearAxleX, rearAxleY), 3.5, cassettePaint);

    // D. Tylna przerzutka (Rear Derailleur & Jockey Wheels)
    const derailleurUpper = Offset(rearAxleX + 3.0, rearAxleY + 6.0);
    const derailleurLower = Offset(rearAxleX + 5.0, rearAxleY + 12.0);

    final derailleurPaint = Paint()
      ..color = const Color(0xFF111827)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(rearAxleX, rearAxleY), derailleurUpper, derailleurPaint);
    canvas.drawLine(derailleurUpper, derailleurLower, derailleurPaint);

    // Kółka wózka przerzutki
    canvas.drawCircle(derailleurUpper, 1.4, Paint()..color = const Color(0xFF4B5563));
    canvas.drawCircle(derailleurLower, 1.4, Paint()..color = const Color(0xFF4B5563));

    // E. Łańcuch wyścigowy (Racing Chain)
    final chainPaint = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    // Górny bieg łańcucha (napięty)
    canvas.drawLine(
      const Offset(rearAxleX, rearAxleY - 5.5),
      const Offset(bbX, bbY - 8.5),
      chainPaint,
    );

    // Dolny bieg łańcucha (przez wózek przerzutki)
    final chainLower = Path()
      ..moveTo(bbX, bbY + 8.5)
      ..lineTo(derailleurLower.dx, derailleurLower.dy)
      ..lineTo(derailleurUpper.dx, derailleurUpper.dy);

    canvas.drawPath(chainLower, chainPaint);
  }

  // ==========================================
  // 5. SZTYCA I SIODEŁKO
  // ==========================================
  void _drawSeatpostAndSaddle(Canvas canvas, {required bool isAero, required bool isTT}) {
    final seatCluster = isTT ? const Offset(87.0, 48.0) : const Offset(83.0, 49.0);
    final seatClamp = isTT ? const Offset(82.0, 31.0) : const Offset(77.0, 33.0);

    // A. Sztyca podsiodłowa (Aero Wing Seatpost vs Round Carbon)
    final seatpostPaint = Paint()..color = const Color(0xFF1E2024);

    if (isAero || isTT) {
      // Skrzydłowy profil aerodynamiczny sztycy
      final aeroPostPath = Path()
        ..moveTo(seatCluster.dx - 2.8, seatCluster.dy)
        ..lineTo(seatCluster.dx + 2.8, seatCluster.dy)
        ..lineTo(seatClamp.dx + 2.5, seatClamp.dy)
        ..lineTo(seatClamp.dx - 2.8, seatClamp.dy)
        ..close();
      canvas.drawPath(aeroPostPath, seatpostPaint);
    } else {
      // Okrągła smukła sztyca wspinaczkowa
      final postPath = Path()
        ..moveTo(seatCluster.dx - 1.6, seatCluster.dy)
        ..lineTo(seatCluster.dx + 1.6, seatCluster.dy)
        ..lineTo(seatClamp.dx + 1.6, seatClamp.dy)
        ..lineTo(seatClamp.dx - 1.6, seatClamp.dy)
        ..close();
      canvas.drawPath(postPath, seatpostPaint);
    }

    // Jarzmo siodełka (Seat clamp & carbon rails)
    canvas.drawRect(
      Rect.fromCenter(center: seatClamp, width: 4.0, height: 1.6),
      Paint()..color = const Color(0xFF4B5563),
    );

    // B. Nowoczesne siodełko z krótkim nosem (Short-nose Racing Saddle)
    final saddlePath = Path();
    if (isTT) {
      // Płaskie siodełko czasowe z mocno ściętym nosem przesunięte do przodu
      saddlePath.moveTo(seatClamp.dx - 8.0, seatClamp.dy - 2.5);
      saddlePath.cubicTo(seatClamp.dx - 4.0, seatClamp.dy - 3.5, seatClamp.dx + 6.0, seatClamp.dy - 3.5, seatClamp.dx + 10.0, seatClamp.dy - 2.8);
      saddlePath.lineTo(seatClamp.dx + 9.5, seatClamp.dy - 1.2);
      saddlePath.cubicTo(seatClamp.dx + 4.0, seatClamp.dy - 1.5, seatClamp.dx - 4.0, seatClamp.dy - 1.2, seatClamp.dx - 8.0, seatClamp.dy - 1.2);
      saddlePath.close();
    } else {
      // Wyścigowe siodło szosowe z anatomicznym podcięciem
      saddlePath.moveTo(seatClamp.dx - 10.0, seatClamp.dy - 2.0);
      saddlePath.cubicTo(seatClamp.dx - 5.0, seatClamp.dy - 3.5, seatClamp.dx + 4.0, seatClamp.dy - 3.5, seatClamp.dx + 9.0, seatClamp.dy - 2.4);
      saddlePath.lineTo(seatClamp.dx + 8.5, seatClamp.dy - 1.2);
      saddlePath.cubicTo(seatClamp.dx + 3.0, seatClamp.dy - 1.6, seatClamp.dx - 5.0, seatClamp.dy - 1.2, seatClamp.dx - 9.5, seatClamp.dy - 1.0);
      saddlePath.close();
    }

    final saddlePaint = Paint()..color = const Color(0xFF141518);
    canvas.drawPath(saddlePath, saddlePaint);
  }

  // ==========================================
  // 6. KOKPIT, MOSTEK I KIEROWNICA
  // ==========================================
  void _drawCockpit(Canvas canvas, {required bool isTT}) {
    final headTubeTop = isTT
        ? const Offset(167.0, 31.0)
        : (bike.frame.category == FrameCategory.lightweightClimbing
            ? const Offset(165.0, 34.5)
            : const Offset(166.0, 32.5));

    // A. Podkładki pod mostek (Spacers)
    Offset stemBase = headTubeTop;
    if (!bike.slammedStem) {
      // 3 karbonowe podkładki dystansowe (15mm spacer stack)
      final spacerPath = Path()
        ..moveTo(headTubeTop.dx - 1.5, headTubeTop.dy)
        ..lineTo(headTubeTop.dx + 3.0, headTubeTop.dy)
        ..lineTo(headTubeTop.dx + 2.0, headTubeTop.dy - 4.0)
        ..lineTo(headTubeTop.dx - 2.2, headTubeTop.dy - 4.0)
        ..close();
      canvas.drawPath(spacerPath, Paint()..color = const Color(0xFF2B2D35));
      stemBase = Offset(headTubeTop.dx - 0.2, headTubeTop.dy - 4.0);
    }

    // B. Mostek aerodynamiczny (Stem)
    final barClamp = isTT
        ? Offset(stemBase.dx + 11.0, stemBase.dy - 1.5)
        : Offset(stemBase.dx + 10.0, stemBase.dy - 1.0);

    final stemPath = Path()
      ..moveTo(stemBase.dx - 1.8, stemBase.dy)
      ..lineTo(stemBase.dx + 2.8, stemBase.dy)
      ..lineTo(barClamp.dx + 2.0, barClamp.dy + 1.8)
      ..lineTo(barClamp.dx - 1.8, barClamp.dy - 1.8)
      ..close();

    final stemPaint = Paint()..color = const Color(0xFF1E2024);
    canvas.drawPath(stemPath, stemPaint);

    if (isTT) {
      // C. Kokpit czasowy TT: Base-bar + Lemondka (Aero Extensions)
      final baseBarPaint = Paint()
        ..color = const Color(0xFF141518)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;

      // Rogi czasowe (Bullhorns / Base-bar)
      canvas.drawLine(barClamp, Offset(barClamp.dx + 5.0, barClamp.dy + 3.0), baseBarPaint);

      // Wysięgniki lemondki (Aero ski-bend extensions) skierowane do przodu
      final extensionPaint = Paint()
        ..color = const Color(0xFF4B5563)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;

      final extensionPath = Path()
        ..moveTo(barClamp.dx + 1.0, barClamp.dy - 2.5)
        ..lineTo(barClamp.dx + 16.0, barClamp.dy - 3.5)
        ..lineTo(barClamp.dx + 19.5, barClamp.dy - 6.5); // Ski-bend chwyt

      canvas.drawPath(extensionPath, extensionPaint);

      // Podłokietniki (Armrest pads)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(barClamp.dx + 5.5, barClamp.dy - 4.5), width: 5.5, height: 1.8),
          const Radius.circular(0.8),
        ),
        Paint()..color = const Color(0xFF1F2228),
      );
    } else {
      // D. Klasyczna kierownica szosowa typu baranek (Drop Bar)
      final dropPath = Path()
        ..moveTo(barClamp.dx, barClamp.dy)
        ..cubicTo(
          barClamp.dx + 5.0,
          barClamp.dy - 1.0,
          barClamp.dx + 8.5,
          barClamp.dy + 2.0,
          barClamp.dx + 8.0,
          barClamp.dy + 8.5,
        )
        ..cubicTo(
          barClamp.dx + 7.5,
          barClamp.dy + 12.0,
          barClamp.dx + 2.0,
          barClamp.dy + 13.0,
          barClamp.dx - 2.0,
          barClamp.dy + 12.5,
        );

      // Owijka kierownicy (Bar Tape)
      final tapePaint = Paint()
        ..color = barTapeColor
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(dropPath, tapePaint);

      // E. Klamkomanetka (Brake / Shift Hood)
      final hoodBase = Offset(barClamp.dx + 7.0, barClamp.dy + 1.0);
      final hoodTip = Offset(barClamp.dx + 10.5, barClamp.dy - 2.5);

      final hoodPath = Path()
        ..moveTo(hoodBase.dx, hoodBase.dy)
        ..quadraticBezierTo(hoodBase.dx + 2.0, hoodBase.dy - 3.0, hoodTip.dx, hoodTip.dy)
        ..lineTo(hoodTip.dx - 1.2, hoodTip.dy + 2.5)
        ..close();

      canvas.drawPath(hoodPath, Paint()..color = const Color(0xFF141518));

      // Dźwignia hamulca z uwzględnieniem kąta podgięcia do wewnątrz (hoodInwardTiltDegrees)
      final double tiltOffset = (bike.hoodInwardTiltDegrees / 15.0).clamp(0.0, 1.0) * 1.5;
      final leverPaint = Paint()
        ..color = const Color(0xFF9CA3AF)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(hoodTip.dx - 0.5, hoodTip.dy + 2.0),
        Offset(hoodBase.dx + 1.5 - tiltOffset, hoodBase.dy + 9.5),
        leverPaint,
      );
    }
  }

  // ==========================================
  // 7. KOSZYKI NA BIDONY
  // ==========================================
  void _drawBottleCages(Canvas canvas) {
    final cagePaint = Paint()
      ..color = const Color(0xFF1F2228)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    // Koszyk na rurze dolnej (Downtube cage)
    final downCage = Path()
      ..moveTo(122.0, 77.0)
      ..lineTo(127.5, 74.0)
      ..lineTo(131.0, 79.5)
      ..lineTo(126.0, 82.5);
    canvas.drawPath(downCage, cagePaint);

    // Koszyk na rurze podsiodłowej (Seat tube cage)
    final seatCage = Path()
      ..moveTo(89.0, 70.0)
      ..lineTo(94.0, 71.5)
      ..lineTo(92.5, 77.5)
      ..lineTo(88.0, 76.0);
    canvas.drawPath(seatCage, cagePaint);
  }

  @override
  bool shouldRepaint(covariant BikePreviewPainter oldDelegate) {
    return oldDelegate.bike != bike ||
        oldDelegate.frameColor != frameColor ||
        oldDelegate.barTapeColor != barTapeColor ||
        oldDelegate.isTanWall != isTanWall ||
        oldDelegate.showFloorReflection != showFloorReflection;
  }

  static Color _adjustHsl(
    Color color, {
    double lightnessDelta = 0.0,
    double saturationDelta = 0.0,
  }) {
    final hsl = HSLColor.fromColor(color);
    final newL = (hsl.lightness + lightnessDelta).clamp(0.0, 1.0);
    final newS = (hsl.saturation + saturationDelta).clamp(0.0, 1.0);
    return hsl.withLightness(newL).withSaturation(newS).toColor();
  }
}

