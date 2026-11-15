import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_appearance.dart';
import '../../models/team/cycling_team.dart';
import '../../services/career/national_championships_and_worlds_service.dart';

/// Zaawansowany widżet wektorowego portretu kolarza (`RiderAvatarWidget`).
/// Rysuje proceduralny, warstwowy portret kolarza o wysokiej szczegółowości
/// na podstawie [RiderAppearance] oraz barw drużyny [CyclingTeam].
class RiderAvatarWidget extends StatelessWidget {
  /// Cechy wyglądu kolarza (kształt twarzy, karnacja, fryzura, zarost, okulary, kask)
  final RiderAppearance appearance;

  /// Drużyna kolarza (używana do barw koszulki i akcentów kasku)
  final CyclingTeam? team;

  /// Bezpośrednie barwy drużyny (jeśli obiekt [team] nie jest dostępny)
  final String? primaryJerseyColorHex;
  final String? secondaryJerseyColorHex;
  final String? accentJerseyColorHex;

  /// Oznaczenie koszulki mistrzowskiej (Tęcza MŚ, Mistrz Kraju, Były MŚ)
  final SpecialJerseyDesignation specialJersey;

  /// Kod narodowości kolarza (dla koszulki mistrza kraju)
  final String? nationalityIso;

  /// Średnica / rozmiar widżetu w pikselach
  final double size;

  /// Czy kolarz ma założony kask aerodynamiczny
  final bool showHelmet;

  /// Czy kolarz ma założone sportowe okulary z soczewką polaryzacyjną
  final bool showGlasses;

  /// Czy renderować obramowanie portretu
  final bool showBorder;

  /// Kolor obramowania (domyślnie kolor akcentu drużyny lub złoty)
  final Color? borderColor;

  /// Grubość obramowania
  final double borderWidth;

  /// Tło za kolarzem (domyślnie elegancki ciemny gradient)
  final Color? backgroundColor;

  /// Opcjonalna akcja po kliknięciu w awatar
  final VoidCallback? onTap;

  const RiderAvatarWidget({
    super.key,
    required this.appearance,
    this.team,
    this.primaryJerseyColorHex,
    this.secondaryJerseyColorHex,
    this.accentJerseyColorHex,
    this.specialJersey = SpecialJerseyDesignation.standardTeamJersey,
    this.nationalityIso,
    this.size = 80.0,
    this.showHelmet = true,
    this.showGlasses = true,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 2.0,
    this.backgroundColor,
    this.onTap,
  });

  /// Wygodny konstruktor bezpośrednio z modelu [Rider]
  factory RiderAvatarWidget.fromRider({
    Key? key,
    required Rider rider,
    CyclingTeam? team,
    SpecialJerseyDesignation specialJersey = SpecialJerseyDesignation.standardTeamJersey,
    String? nationalityIso,
    ReigningChampionsRegistry? championsRegistry,
    bool isTimeTrial = false,
    double size = 80.0,
    bool showHelmet = true,
    bool showGlasses = true,
    bool showBorder = true,
    Color? borderColor,
    double borderWidth = 2.0,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    final effectiveJersey = championsRegistry != null
        ? (championsRegistry.isReigningWorldChampion(rider.id, isTimeTrial: isTimeTrial)
            ? SpecialJerseyDesignation.rainbowJersey
            : (championsRegistry.isReigningNationalChampion(rider.id, rider.nationalityIso, isTimeTrial: isTimeTrial)
                ? SpecialJerseyDesignation.nationalChampionJersey
                : (championsRegistry.isFormerWorldChampion(rider.id)
                    ? SpecialJerseyDesignation.formerWorldChampionRainbowBands
                    : specialJersey)))
        : specialJersey;

    return RiderAvatarWidget(
      key: key,
      appearance: rider.appearance,
      team: team,
      specialJersey: effectiveJersey,
      nationalityIso: nationalityIso ?? rider.nationalityIso,
      size: size,
      showHelmet: showHelmet,
      showGlasses: showGlasses,
      showBorder: showBorder,
      borderColor: borderColor,
      borderWidth: borderWidth,
      backgroundColor: backgroundColor,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color jerseyPrimary;
    Color jerseySecondary;
    Color jerseyAccent;

    if (specialJersey == SpecialJerseyDesignation.rainbowJersey) {
      jerseyPrimary = Colors.white;
      jerseySecondary = Colors.white;
      jerseyAccent = AppColors.goldAccent;
    } else if (specialJersey == SpecialJerseyDesignation.nationalChampionJersey) {
      final theme = NationalChampionshipsAndWorldsService.getNationalJerseyColorTheme(nationalityIso ?? 'POL');
      jerseyPrimary = _parseHexColor(theme['primaryHex'], Colors.white);
      jerseySecondary = _parseHexColor(theme['secondaryHex'], Colors.red);
      jerseyAccent = _parseHexColor(theme['accentHex'], Colors.white);
    } else {
      jerseyPrimary = _parseHexColor(
        team?.primaryJerseyColorHex ?? primaryJerseyColorHex,
        const Color(0xFF1E3A8A), // Domyślny granat WorldTour
      );
      jerseySecondary = _parseHexColor(
        team?.secondaryJerseyColorHex ?? secondaryJerseyColorHex,
        const Color(0xFF3B82F6), // Domyślny błękit
      );
      jerseyAccent = _parseHexColor(
        team?.accentJerseyColorHex ?? accentJerseyColorHex,
        AppColors.goldAccent,
      );
    }

    final resolvedBorderColor = borderColor ??
        (specialJersey == SpecialJerseyDesignation.rainbowJersey
            ? AppColors.goldAccent
            : (specialJersey == SpecialJerseyDesignation.formerWorldChampionRainbowBands
                ? const Color(0xFFE2E8F0)
                : jerseyAccent));

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: resolvedBorderColor,
                width: math.max(1.0, borderWidth * (size / 80.0)),
              )
            : null,
        boxShadow: showBorder
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: math.max(4.0, size * 0.08),
                  offset: Offset(0, math.max(2.0, size * 0.04)),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: CustomPaint(
          size: Size(size, size),
          painter: RiderAvatarPainter(
            appearance: appearance,
            jerseyPrimaryColor: jerseyPrimary,
            jerseySecondaryColor: jerseySecondary,
            jerseyAccentColor: jerseyAccent,
            specialJersey: specialJersey,
            showHelmet: showHelmet,
            showGlasses: showGlasses,
            backgroundColor: backgroundColor ?? const Color(0xFF131722),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
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

/// Wejściowy silnik malujący warstwy wektorowe kolarza w układzie współrzędnych 0..100.
class RiderAvatarPainter extends CustomPainter {
  final RiderAppearance appearance;
  final Color jerseyPrimaryColor;
  final Color jerseySecondaryColor;
  final Color jerseyAccentColor;
  final SpecialJerseyDesignation specialJersey;
  final bool showHelmet;
  final bool showGlasses;
  final Color backgroundColor;

  RiderAvatarPainter({
    required this.appearance,
    required this.jerseyPrimaryColor,
    required this.jerseySecondaryColor,
    required this.jerseyAccentColor,
    this.specialJersey = SpecialJerseyDesignation.standardTeamJersey,
    required this.showHelmet,
    required this.showGlasses,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Skalowanie wirtualnego płótna 100x100 do docelowego rozmiaru widżetu
    final double scale = size.width / 100.0;
    canvas.scale(scale, scale);

    // Przygotowanie palety barw kolarza
    final skinBase = _parseHexColor(appearance.skinToneHex, const Color(0xFFE8BA9B));
    final skinShadow = _adjustHsl(skinBase, lightnessDelta: -0.16, saturationDelta: 0.04);
    final skinDeepShadow = _adjustHsl(skinBase, lightnessDelta: -0.28, saturationDelta: 0.08);
    final skinHighlight = _adjustHsl(skinBase, lightnessDelta: 0.12, saturationDelta: -0.04);

    final hairColor = _parseHexColor(appearance.hairColorHex, const Color(0xFF2C1B18));
    final hairHighlight = _adjustHsl(hairColor, lightnessDelta: 0.18);
    final hairShadow = _adjustHsl(hairColor, lightnessDelta: -0.15);

    // 1. Tło portretu (Backdrop)
    _drawBackground(canvas);

    // 2. Ramiona, klatka piersiowa i koszulka kolarska (Jersey)
    _drawJerseyAndShoulders(canvas);

    // 3. Atletyczna szyja kolarza z cieniem podbródka
    _drawNeck(canvas, skinBase, skinShadow, skinDeepShadow, skinHighlight);

    // 4. Uszy
    _drawEars(canvas, skinBase, skinShadow, skinDeepShadow);

    // 5. Kształt głowy, kości policzkowe i szczęka (wg faceShapeIndex)
    _drawFaceStructure(canvas, skinBase, skinShadow, skinDeepShadow, skinHighlight);

    // 6. Rysy twarzy: nos, usta, oczy i brwi
    _drawFacialFeatures(canvas, skinBase, skinShadow, skinDeepShadow, skinHighlight, hairColor);

    // 7. Zarost kolarza (wg facialHairIndex)
    _drawFacialHair(canvas, hairColor, skinBase);

    // 8. Fryzura / baczki / włosy (wg hairStyleIndex)
    _drawHair(canvas, hairColor, hairHighlight, hairShadow);

    // 9. Kask aerodynamiczny z wlotami powietrza i paskami (wg helmetModelId)
    if (showHelmet) {
      _drawAeroHelmet(canvas, skinBase);
    }

    // 10. Sportowe okulary z soczewką polaryzacyjną / lustrzaną
    if (showGlasses) {
      _drawCyclingGlasses(canvas);
    }

    // 11. Ostateczny filtr oświetlenia i winieta
    _drawFinalGlossAndVignette(canvas);

    canvas.restore();
  }

  // ==========================================
  // 1. TŁO
  // ==========================================
  void _drawBackground(Canvas canvas) {
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.2),
        radius: 0.85,
        colors: [
          _adjustHsl(backgroundColor, lightnessDelta: 0.12),
          backgroundColor,
          _adjustHsl(backgroundColor, lightnessDelta: -0.08),
        ],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 100));

    canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), bgPaint);

    // Delikatna aerodynamiczna aura w barwach drużyny za głową kolarza
    final auraPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.1),
        radius: 0.65,
        colors: [
          jerseyPrimaryColor.withValues(alpha: 0.25),
          jerseySecondaryColor.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 100));

    canvas.drawCircle(const Offset(50, 45), 44, auraPaint);
  }

  // ==========================================
  // 2. KOSZULKA I RAMIONA
  // ==========================================
  void _drawJerseyAndShoulders(Canvas canvas) {
    // Kształt ramion i klatki piersiowej kolarza w pozycji aerodynamicznej
    final torsoPath = Path()
      ..moveTo(12, 100)
      ..cubicTo(16, 84, 26, 76, 37, 74)
      ..lineTo(63, 74)
      ..cubicTo(74, 76, 84, 84, 88, 100)
      ..close();

    final jerseyShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        jerseyPrimaryColor,
        _adjustHsl(jerseyPrimaryColor, lightnessDelta: -0.14),
      ],
    ).createShader(const Rect.fromLTWH(10, 70, 80, 30));

    canvas.drawPath(torsoPath, Paint()..shader = jerseyShader);

    // Oznaczenia specjalne: pasy tęczy Mistrza Świata lub pasy narodowe
    if (specialJersey == SpecialJerseyDesignation.rainbowJersey) {
      canvas.save();
      canvas.clipPath(torsoPath);
      const rainbowColors = [
        Color(0xFF0085C7),
        Color(0xFFEE334E),
        Color(0xFF1E293B),
        Color(0xFFFCB131),
        Color(0xFF00A651),
      ];
      const double bandStartY = 85.0;
      const double stripeHeight = 1.6;
      for (int i = 0; i < rainbowColors.length; i++) {
        final p = Paint()..color = rainbowColors[i];
        canvas.drawRect(Rect.fromLTWH(10, bandStartY + (i * stripeHeight), 80, stripeHeight), p);
      }
      canvas.restore();
    } else if (specialJersey == SpecialJerseyDesignation.nationalChampionJersey) {
      canvas.save();
      canvas.clipPath(torsoPath);
      final pSec = Paint()..color = jerseySecondaryColor;
      final pAcc = Paint()..color = jerseyAccentColor;
      canvas.drawRect(const Rect.fromLTWH(10, 85.0, 80, 4.0), pSec);
      canvas.drawRect(const Rect.fromLTWH(10, 89.0, 80, 4.0), pAcc);
      canvas.restore();
    }

    // Panele boczne koszulki / rękawki aerodynamiczne (Secondary color)
    final leftSleeve = Path()
      ..moveTo(12, 100)
      ..cubicTo(16, 84, 24, 79, 31, 80)
      ..lineTo(25, 100)
      ..close();

    final rightSleeve = Path()
      ..moveTo(88, 100)
      ..cubicTo(84, 84, 76, 79, 69, 80)
      ..lineTo(75, 100)
      ..close();

    final sleevePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          jerseySecondaryColor,
          _adjustHsl(jerseySecondaryColor, lightnessDelta: -0.18),
        ],
      ).createShader(const Rect.fromLTWH(10, 75, 80, 25));

    canvas.drawPath(leftSleeve, sleevePaint);
    canvas.drawPath(rightSleeve, sleevePaint);

    // Ergonomiczny, aerodynamiczny kołnierzyk koszulki (Aero Collar)
    final collarPath = Path()
      ..moveTo(37, 74)
      ..cubicTo(43, 77, 57, 77, 63, 74)
      ..lineTo(63, 78)
      ..cubicTo(57, 81, 43, 81, 37, 78)
      ..close();

    final collarPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _adjustHsl(jerseyPrimaryColor, lightnessDelta: -0.2),
          jerseySecondaryColor,
          _adjustHsl(jerseyPrimaryColor, lightnessDelta: -0.2),
        ],
      ).createShader(const Rect.fromLTWH(35, 73, 30, 8));

    canvas.drawPath(collarPath, collarPaint);

    // Były Mistrz Świata: dożywotnie tęczowe paski na mankietach rękawków i kołnierzyku!
    if (specialJersey == SpecialJerseyDesignation.formerWorldChampionRainbowBands) {
      const rainbowColors = [
        Color(0xFF0085C7),
        Color(0xFFEE334E),
        Color(0xFF1E293B),
        Color(0xFFFCB131),
        Color(0xFF00A651),
      ];

      // Lewy mankiet
      canvas.save();
      canvas.clipPath(leftSleeve);
      for (int i = 0; i < rainbowColors.length; i++) {
        final p = Paint()..color = rainbowColors[i];
        canvas.drawRect(Rect.fromLTWH(10, 95.0 + (i * 0.9), 20, 0.9), p);
      }
      canvas.restore();

      // Prawy mankiet
      canvas.save();
      canvas.clipPath(rightSleeve);
      for (int i = 0; i < rainbowColors.length; i++) {
        final p = Paint()..color = rainbowColors[i];
        canvas.drawRect(Rect.fromLTWH(70, 95.0 + (i * 0.9), 20, 0.9), p);
      }
      canvas.restore();

      // Kołnierzyk
      canvas.save();
      canvas.clipPath(collarPath);
      for (int i = 0; i < rainbowColors.length; i++) {
        final p = Paint()..color = rainbowColors[i];
        canvas.drawRect(Rect.fromLTWH(35, 74.0 + (i * 0.8), 30, 0.8), p);
      }
      canvas.restore();
    }

    // Centralny zamek błyskawiczny (Aero Zipper)
    final zipPaint = Paint()
      ..color = jerseyAccentColor
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(50, 77.5), const Offset(50, 96), zipPaint);

    // Suwak zamka
    final pullPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(49.1, 79.5, 1.8, 3.8),
        const Radius.circular(0.8),
      ),
      pullPaint,
    );
  }

  // ==========================================
  // 3. SZYJA I MIĘŚNIE
  // ==========================================
  void _drawNeck(
    Canvas canvas,
    Color skinBase,
    Color skinShadow,
    Color skinDeepShadow,
    Color skinHighlight,
  ) {
    final neckPath = Path()
      ..moveTo(39, 58)
      ..lineTo(37, 75)
      ..cubicTo(45, 78, 55, 78, 63, 75)
      ..lineTo(61, 58)
      ..close();

    // Bazowy odcień szyi
    canvas.drawPath(neckPath, Paint()..color = skinShadow);

    // Głęboki cień rzucany przez szczękę kolarza (Okluzja otoczenia)
    final jawShadowPath = Path()
      ..moveTo(39, 58)
      ..cubicTo(42, 66, 58, 66, 61, 58)
      ..lineTo(61, 62)
      ..cubicTo(56, 70, 44, 70, 39, 62)
      ..close();

    canvas.drawPath(jawShadowPath, Paint()..color = skinDeepShadow);

    // Mięsień mostkowo-obojczykowo-sutkowy (kontur atletyczny)
    final musclePaint = Paint()
      ..color = skinHighlight.withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final leftMuscle = Path()
      ..moveTo(43, 62)
      ..quadraticBezierTo(44, 69, 47, 75);

    final rightMuscle = Path()
      ..moveTo(57, 62)
      ..quadraticBezierTo(56, 69, 53, 75);

    canvas.drawPath(leftMuscle, musclePaint);
    canvas.drawPath(rightMuscle, musclePaint);
  }

  // ==========================================
  // 4. USZY
  // ==========================================
  void _drawEars(
    Canvas canvas,
    Color skinBase,
    Color skinShadow,
    Color skinDeepShadow,
  ) {
    final leftEar = Path()
      ..moveTo(34.5, 43)
      ..cubicTo(29.0, 43.5, 29.5, 52.5, 34.5, 53.5)
      ..close();

    final rightEar = Path()
      ..moveTo(65.5, 43)
      ..cubicTo(71.0, 43.5, 70.5, 52.5, 65.5, 53.5)
      ..close();

    final earPaint = Paint()..color = skinBase;
    canvas.drawPath(leftEar, earPaint);
    canvas.drawPath(rightEar, earPaint);

    // Wewnętrzne fałdy ucha (Grobelka i muszla)
    final earFoldPaint = Paint()
      ..color = skinDeepShadow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final leftFold = Path()
      ..moveTo(33, 45)
      ..quadraticBezierTo(31.5, 48, 33.5, 50);

    final rightFold = Path()
      ..moveTo(67, 45)
      ..quadraticBezierTo(68.5, 48, 66.5, 50);

    canvas.drawPath(leftFold, earFoldPaint);
    canvas.drawPath(rightFold, earFoldPaint);
  }

  // ==========================================
  // 5. KSZTAŁT TWARZY I SZCZĘKI
  // ==========================================
  void _drawFaceStructure(
    Canvas canvas,
    Color skinBase,
    Color skinShadow,
    Color skinDeepShadow,
    Color skinHighlight,
  ) {
    final facePath = Path();

    // Modelowanie geometrii twarzy zależnie od faceShapeIndex
    switch (appearance.faceShapeIndex % 5) {
      case 0:
        // Owalna atletyczna (zbalansowana, harmonijna)
        facePath.moveTo(33, 32);
        facePath.cubicTo(32.5, 43, 34, 52, 38, 59);
        facePath.cubicTo(42, 65, 45, 67.5, 50, 67.5);
        facePath.cubicTo(55, 67.5, 58, 65, 62, 59);
        facePath.cubicTo(66, 52, 67.5, 43, 67, 32);
        facePath.close();
        break;

      case 1:
        // Kwadratowa (mocna, wyrazista szczęka sprintera)
        facePath.moveTo(32.5, 32);
        facePath.cubicTo(32, 44, 33, 53, 35.5, 59);
        facePath.cubicTo(38, 64, 43, 67.5, 47, 67.5);
        facePath.lineTo(53, 67.5);
        facePath.cubicTo(57, 67.5, 62, 64, 64.5, 59);
        facePath.cubicTo(67, 53, 68, 44, 67.5, 32);
        facePath.close();
        break;

      case 2:
        // Ostro zarysowana / trójkątna (wychudzona twarz górala z niską tkanką tłuszczową)
        facePath.moveTo(34, 32);
        facePath.cubicTo(33.5, 43, 36, 52, 39, 58);
        facePath.cubicTo(42, 64, 47, 68.8, 50, 68.8);
        facePath.cubicTo(53, 68.8, 58, 64, 61, 58);
        facePath.cubicTo(64, 52, 66.5, 43, 66, 32);
        facePath.close();
        break;

      case 3:
        // Zaokrąglona (zwarta twarz dynamicznego punchera / klasyka)
        facePath.moveTo(32.5, 32);
        facePath.cubicTo(32, 44, 33.5, 54, 38, 60);
        facePath.cubicTo(42, 64.5, 46, 66.5, 50, 66.5);
        facePath.cubicTo(54, 66.5, 58, 64.5, 62, 60);
        facePath.cubicTo(66.5, 54, 68, 44, 67.5, 32);
        facePath.close();
        break;

      case 4:
      default:
        // Podłużna aerodynamiczna (smukła twarz czasowca)
        facePath.moveTo(34.5, 32);
        facePath.cubicTo(34, 43, 35, 53, 38.5, 60);
        facePath.cubicTo(42, 66, 46, 69.8, 50, 69.8);
        facePath.cubicTo(54, 69.8, 58, 66, 61.5, 60);
        facePath.cubicTo(65, 53, 66, 43, 65.5, 32);
        facePath.close();
        break;
    }

    // Gradient przestrzenny twarzy (światłocień 3D)
    final faceShader = RadialGradient(
      center: const Alignment(0.0, -0.1),
      radius: 0.75,
      colors: [
        skinHighlight,
        skinBase,
        skinShadow,
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(const Rect.fromLTWH(30, 30, 40, 40));

    canvas.drawPath(facePath, Paint()..shader = faceShader);

    // Cieniowanie zapadniętych policzków u górala (Kolarz profesjonalny)
    final cheekShadowPaint = Paint()
      ..color = skinShadow.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);

    canvas.drawOval(const Rect.fromLTWH(34, 50, 5, 8), cheekShadowPaint);
    canvas.drawOval(const Rect.fromLTWH(61, 50, 5, 8), cheekShadowPaint);

    // Podkreślenie dolnej krawędzi brody (Jawline contour)
    final jawlinePaint = Paint()
      ..color = skinDeepShadow.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawPath(facePath, jawlinePaint);
  }

  // ==========================================
  // 6. RYSY TWARZY (NOS, USTA, OCZY, BRWI)
  // ==========================================
  void _drawFacialFeatures(
    Canvas canvas,
    Color skinBase,
    Color skinShadow,
    Color skinDeepShadow,
    Color skinHighlight,
    Color hairColor,
  ) {
    // A. Brwi (widoczne za lub nad okularami)
    final browPaint = Paint()
      ..color = hairColor
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final leftBrow = Path()
      ..moveTo(37, 39.5)
      ..quadraticBezierTo(41.5, 38.0, 46, 39.0);

    final rightBrow = Path()
      ..moveTo(54, 39.0)
      ..quadraticBezierTo(58.5, 38.0, 63, 39.5);

    canvas.drawPath(leftBrow, browPaint);
    canvas.drawPath(rightBrow, browPaint);

    // B. Oczy kolarza (skupiony wzrok w dal)
    final eyeWhite = Paint()..color = const Color(0xFFE8ECEF);
    final pupilPaint = Paint()..color = const Color(0xFF1A1A1A);
    final catchlightPaint = Paint()..color = Colors.white;

    // Lewe oko
    final leftEyeRect = Rect.fromCenter(center: const Offset(41.5, 42.5), width: 7.2, height: 3.8);
    canvas.drawOval(leftEyeRect, eyeWhite);
    canvas.drawCircle(const Offset(41.5, 42.5), 1.7, pupilPaint);
    canvas.drawCircle(const Offset(41.0, 42.0), 0.6, catchlightPaint);

    // Prawe oko
    final rightEyeRect = Rect.fromCenter(center: const Offset(58.5, 42.5), width: 7.2, height: 3.8);
    canvas.drawOval(rightEyeRect, eyeWhite);
    canvas.drawCircle(const Offset(58.5, 42.5), 1.7, pupilPaint);
    canvas.drawCircle(const Offset(58.0, 42.0), 0.6, catchlightPaint);

    // Powieka górna
    final eyelidPaint = Paint()
      ..color = skinDeepShadow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawArc(leftEyeRect, math.pi, math.pi, false, eyelidPaint);
    canvas.drawArc(rightEyeRect, math.pi, math.pi, false, eyelidPaint);

    // C. Nos (grzbiet, czubek i skrzydełka)
    final noseRidge = Path()
      ..moveTo(49, 41)
      ..lineTo(49.2, 51.5)
      ..lineTo(50.8, 53)
      ..lineTo(51.8, 52);

    final noseShadowPaint = Paint()
      ..color = skinShadow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(noseRidge, noseShadowPaint);

    // Skrzydełka nosa
    final leftNostril = Path()
      ..moveTo(46.5, 52.8)
      ..quadraticBezierTo(47.5, 53.5, 49.5, 53.2);

    final rightNostril = Path()
      ..moveTo(53.5, 52.8)
      ..quadraticBezierTo(52.5, 53.5, 50.5, 53.2);

    final nostrilPaint = Paint()
      ..color = skinDeepShadow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    canvas.drawPath(leftNostril, nostrilPaint);
    canvas.drawPath(rightNostril, nostrilPaint);

    // Jasny punkt na czubku nosa
    canvas.drawCircle(
      const Offset(50, 51.8),
      0.9,
      Paint()..color = skinHighlight.withValues(alpha: 0.6),
    );

    // D. Usta kolarza (zacięty wyraz twarzy sportowca na finiszu)
    final mouthLine = Path()
      ..moveTo(44, 60.2)
      ..quadraticBezierTo(50, 60.8, 56, 60.2);

    final mouthPaint = Paint()
      ..color = _adjustHsl(skinDeepShadow, lightnessDelta: -0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(mouthLine, mouthPaint);

    // Dolna warga
    final lowerLip = Path()
      ..moveTo(46.5, 61.2)
      ..quadraticBezierTo(50, 62.6, 53.5, 61.2);

    final lowerLipPaint = Paint()
      ..color = skinShadow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    canvas.drawPath(lowerLip, lowerLipPaint);

    // Cień pod dolną wargą (zagłębienie bródkowe)
    final chinCrease = Path()
      ..moveTo(48, 63.8)
      ..quadraticBezierTo(50, 64.3, 52, 63.8);

    canvas.drawPath(chinCrease, lowerLipPaint);
  }

  // ==========================================
  // 7. ZAROST (FACIAL HAIR)
  // ==========================================
  void _drawFacialHair(Canvas canvas, Color hairColor, Color skinBase) {
    final int idx = appearance.facialHairIndex % 6;
    if (idx == 0) return; // Gładko ogolony (Clean shaven)

    final beardColor = hairColor.withValues(alpha: 0.88);
    final stubbleColor = hairColor.withValues(alpha: 0.38);

    switch (idx) {
      case 1:
        // 3-dniowy zarost (Stubble) - lekki cień na szczęce i brodzie
        final stubblePath = Path()
          ..moveTo(37, 57)
          ..cubicTo(41, 64, 46, 67, 50, 67)
          ..cubicTo(54, 67, 59, 64, 63, 57)
          ..lineTo(61, 62)
          ..cubicTo(56, 68, 44, 68, 39, 62)
          ..close();

        canvas.drawPath(stubblePath, Paint()..color = stubbleColor);

        // Lekki wąsik z kilkudniowego zarostu
        final stubbleMoustache = Path()
          ..moveTo(44, 59)
          ..quadraticBezierTo(50, 58.5, 56, 59)
          ..lineTo(56, 59.8)
          ..quadraticBezierTo(50, 59.2, 44, 59.8)
          ..close();

        canvas.drawPath(stubbleMoustache, Paint()..color = stubbleColor);
        break;

      case 2:
        // Stylowa krótka broda (Short Trimmed Beard)
        final shortBeard = Path()
          ..moveTo(34.5, 51)
          ..cubicTo(36, 62, 43, 68, 50, 68)
          ..cubicTo(57, 68, 64, 62, 65.5, 51)
          ..lineTo(63.5, 54)
          ..cubicTo(60, 64, 55, 66, 50, 66)
          ..cubicTo(45, 66, 40, 64, 36.5, 54)
          ..close();

        canvas.drawPath(shortBeard, Paint()..color = beardColor);

        // Połączony krótki wąs
        final moustache = Path()
          ..moveTo(43, 59.2)
          ..quadraticBezierTo(50, 57.5, 57, 59.2)
          ..quadraticBezierTo(50, 59.8, 43, 59.2);

        canvas.drawPath(
          moustache,
          Paint()
            ..color = beardColor
            ..strokeWidth = 1.4
            ..style = PaintingStyle.stroke,
        );
        break;

      case 3:
        // Kozia bródka z wąsem (Goatee)
        final goatee = Path()
          ..moveTo(45, 59)
          ..lineTo(44, 61.5)
          ..quadraticBezierTo(47, 67.5, 50, 67.8)
          ..quadraticBezierTo(53, 67.5, 56, 61.5)
          ..lineTo(55, 59)
          ..lineTo(53.5, 59)
          ..quadraticBezierTo(50, 63.5, 46.5, 59)
          ..close();

        canvas.drawPath(goatee, Paint()..color = beardColor);
        break;

      case 4:
        // Klasyczny wąs kolarski w stylu mistrzów lat 70/80
        final classicMoustache = Path()
          ..moveTo(42.5, 59.4)
          ..cubicTo(46, 57.2, 50, 58.0, 50, 58.0)
          ..cubicTo(50, 58.0, 54, 57.2, 57.5, 59.4)
          ..cubicTo(54, 60.5, 50, 59.6, 50, 59.6)
          ..cubicTo(50, 59.6, 46, 60.5, 42.5, 59.4)
          ..close();

        canvas.drawPath(classicMoustache, Paint()..color = beardColor);
        break;

      case 5:
        // Pełna, gęsta zadbana broda (Full Athletic Beard)
        final fullBeard = Path()
          ..moveTo(34, 48)
          ..cubicTo(34, 60, 42, 69.2, 50, 69.2)
          ..cubicTo(58, 69.2, 66, 60, 66, 48)
          ..lineTo(63.5, 52)
          ..cubicTo(60, 62, 55, 64, 50, 64)
          ..cubicTo(45, 64, 40, 62, 36.5, 52)
          ..close();

        canvas.drawPath(fullBeard, Paint()..color = beardColor);

        // Gęsty wąs
        final thickMoustache = Path()
          ..moveTo(42, 59.4)
          ..cubicTo(46, 56.8, 50, 57.8, 50, 57.8)
          ..cubicTo(50, 57.8, 54, 56.8, 58, 59.4)
          ..lineTo(57, 60.5)
          ..quadraticBezierTo(50, 59.8, 43, 60.5)
          ..close();

        canvas.drawPath(thickMoustache, Paint()..color = beardColor);
        break;
    }
  }

  // ==========================================
  // 8. FRYZURA / WŁOSY
  // ==========================================
  void _drawHair(Canvas canvas, Color hairColor, Color hairHighlight, Color hairShadow) {
    final int style = appearance.hairStyleIndex % 6;

    // A. Jeśli kolarz nie ma kasku, rysujemy pełną fryzurę
    if (!showHelmet) {
      final hairDome = Path()
        ..moveTo(31, 38)
        ..cubicTo(26, 22, 36, 12, 50, 12)
        ..cubicTo(64, 12, 74, 22, 69, 38)
        ..cubicTo(64, 33, 36, 33, 31, 38)
        ..close();

      final hairShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [hairHighlight, hairColor, hairShadow],
      ).createShader(const Rect.fromLTWH(26, 12, 48, 28));

      canvas.drawPath(hairDome, Paint()..shader = hairShader);
    }

    // B. Baczki i włosy na skroniach wystające spod kasku
    final sideburnPaint = Paint()..color = hairColor;

    switch (style) {
      case 0:
        // Buzz cut / Fade - minimalne, cieniowane baczki
        final leftFade = Path()
          ..moveTo(33, 36)
          ..lineTo(34.2, 44)
          ..lineTo(33, 44)
          ..close();
        final rightFade = Path()
          ..moveTo(67, 36)
          ..lineTo(65.8, 44)
          ..lineTo(67, 44)
          ..close();
        canvas.drawPath(leftFade, sideburnPaint);
        canvas.drawPath(rightFade, sideburnPaint);
        break;

      case 1:
        // Textured crop - proste baczki
        canvas.drawRect(const Rect.fromLTWH(33, 36, 1.8, 9), sideburnPaint);
        canvas.drawRect(const Rect.fromLTWH(65.2, 36, 1.8, 9), sideburnPaint);
        break;

      case 2:
        // Curly / Wavy - lekko kręcone kosmyki wystające spod kasku
        final leftCurl = Path()
          ..moveTo(33, 36)
          ..quadraticBezierTo(31.5, 41, 34, 45)
          ..quadraticBezierTo(32, 46, 33.5, 48);
        final rightCurl = Path()
          ..moveTo(67, 36)
          ..quadraticBezierTo(68.5, 41, 66, 45)
          ..quadraticBezierTo(68, 46, 66.5, 48);

        final curlPaint = Paint()
          ..color = hairColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;

        canvas.drawPath(leftCurl, curlPaint);
        canvas.drawPath(rightCurl, curlPaint);
        break;

      case 3:
        // Przedziałek (Side parted) - schludne baczki
        canvas.drawRect(const Rect.fromLTWH(32.8, 36, 2.2, 11), sideburnPaint);
        canvas.drawRect(const Rect.fromLTWH(65.0, 36, 2.2, 11), sideburnPaint);
        break;

      case 4:
        // Swept back flow - dłuższe pasma włosów schodzące za ucho
        final leftFlow = Path()
          ..moveTo(33, 36)
          ..cubicTo(30, 42, 31, 52, 33.5, 54)
          ..lineTo(34.8, 52)
          ..cubicTo(32.5, 48, 33, 40, 34, 36)
          ..close();
        final rightFlow = Path()
          ..moveTo(67, 36)
          ..cubicTo(70, 42, 69, 52, 66.5, 54)
          ..lineTo(65.2, 52)
          ..cubicTo(67.5, 48, 67, 40, 66, 36)
          ..close();
        canvas.drawPath(leftFlow, sideburnPaint);
        canvas.drawPath(rightFlow, sideburnPaint);
        break;

      case 5:
      default:
        // Bald / gładka głowa - brak dodatkowych włosów
        break;
    }
  }

  // ==========================================
  // 9. KASK AERODYNAMICZNY (AERO HELMET)
  // ==========================================
  void _drawAeroHelmet(Canvas canvas, Color skinBase) {
    // A. Paski kasku (Straps) biegnące od wnętrza kasku pod brodę
    final strapPaint = Paint()
      ..color = const Color(0xFF1F2228)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    // Lewy pasek Y-Divider
    final leftStrap = Path()
      ..moveTo(33.5, 36)
      ..lineTo(34.5, 51)
      ..lineTo(49, 68);

    // Prawy pasek Y-Divider
    final rightStrap = Path()
      ..moveTo(66.5, 36)
      ..lineTo(65.5, 51)
      ..lineTo(51, 68);

    canvas.drawPath(leftStrap, strapPaint);
    canvas.drawPath(rightStrap, strapPaint);

    // Sprzączka paska pod brodą
    canvas.drawRect(
      const Rect.fromLTWH(48.5, 67.2, 3.0, 1.8),
      Paint()..color = const Color(0xFF404552),
    );

    // B. Skorupa kasku aero (Aerodynamic Shell)
    final helmetShell = Path()
      ..moveTo(26.5, 36)
      ..cubicTo(24, 21, 35, 12.5, 50, 12.0)
      ..cubicTo(65, 12.5, 76, 21, 73.5, 36)
      ..cubicTo(66, 37.5, 34, 37.5, 26.5, 36)
      ..close();

    final helmetShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _adjustHsl(jerseyPrimaryColor, lightnessDelta: 0.14),
        jerseyPrimaryColor,
        _adjustHsl(jerseyPrimaryColor, lightnessDelta: -0.18),
      ],
    ).createShader(const Rect.fromLTWH(24, 12, 52, 26));

    canvas.drawPath(helmetShell, Paint()..shader = helmetShader);

    // C. Wloty powietrza (Aero Intake Vents) - kanały z czarnego karbonu
    final ventPaint = Paint()..color = const Color(0xFF14171E);

    // Centralny wlot powietrza
    final centerVent = Path()
      ..moveTo(47.2, 17)
      ..lineTo(52.8, 17)
      ..lineTo(51.8, 25.5)
      ..lineTo(48.2, 25.5)
      ..close();
    canvas.drawPath(centerVent, ventPaint);

    // Lewy wlot powietrza
    final leftVent = Path()
      ..moveTo(37, 21)
      ..lineTo(43, 19)
      ..lineTo(42.5, 26.5)
      ..lineTo(37.5, 27)
      ..close();
    canvas.drawPath(leftVent, ventPaint);

    // Prawy wlot powietrza
    final rightVent = Path()
      ..moveTo(63, 21)
      ..lineTo(57, 19)
      ..lineTo(57.5, 26.5)
      ..lineTo(62.5, 27)
      ..close();
    canvas.drawPath(rightVent, ventPaint);

    // D. Pasek wyścigowy / dekoracyjny (Racing Aero Decal) w barwach zespołu
    final decalPath = Path()
      ..moveTo(48.5, 12)
      ..lineTo(51.5, 12)
      ..lineTo(51.5, 36.5)
      ..lineTo(48.5, 36.5)
      ..close();

    canvas.drawPath(decalPath, Paint()..color = jerseySecondaryColor);

    final thinStripe = Path()
      ..moveTo(49.4, 12)
      ..lineTo(50.6, 12)
      ..lineTo(50.6, 36.5)
      ..lineTo(49.4, 36.5)
      ..close();

    canvas.drawPath(thinStripe, Paint()..color = jerseyAccentColor);

    // E. Odblask światła na skorupie kasku (Gloss Specular Highlight)
    final highlightPath = Path()
      ..moveTo(32, 26)
      ..cubicTo(33, 17, 42, 14, 49, 13.5)
      ..cubicTo(45, 15, 37, 19, 35, 27)
      ..close();

    final highlightPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(const Rect.fromLTWH(30, 13, 20, 15));

    canvas.drawPath(highlightPath, highlightPaint);

    // F. Spód kasku / krawędź EPS (pianka polistyrenowa)
    final rimPath = Path()
      ..moveTo(26.5, 36)
      ..cubicTo(34, 37.5, 66, 37.5, 73.5, 36)
      ..lineTo(73, 37.2)
      ..cubicTo(66, 38.5, 34, 38.5, 27, 37.2)
      ..close();

    canvas.drawPath(rimPath, Paint()..color = const Color(0xFF1B1D22));
  }

  // ==========================================
  // 10. SPORTOWE OKULARY Z SOCZEWKĄ POLARYZACYJNĄ
  // ==========================================
  void _drawCyclingGlasses(Canvas canvas) {
    // Bazowy kolor soczewki ze statystyk kolarza
    final baseLensColor = _parseHexColor(
      appearance.glassesLensColorHex,
      const Color(0xFFFF4500), // Domyślna soczewka Prizm Road / Fire Iridium
    );

    // Generowanie tęczowego przesunięcia polaryzacyjnego (Iridescent shift)
    final hsl = HSLColor.fromColor(baseLensColor);
    final polarizedAccent = hsl
        .withHue((hsl.hue + 45.0) % 360.0)
        .withLightness((hsl.lightness * 1.15).clamp(0.0, 1.0))
        .toColor();
    final polarizedShadow = hsl
        .withHue((hsl.hue - 25.0 + 360.0) % 360.0)
        .withLightness((hsl.lightness * 0.75).clamp(0.0, 1.0))
        .toColor();

    // A. Górna ramka aerodynamiczna okularów (Top Frame Brow Bar)
    final framePath = Path()
      ..moveTo(27, 36.5)
      ..cubicTo(36, 35.0, 64, 35.0, 73, 36.5)
      ..lineTo(73, 38.2)
      ..cubicTo(64, 36.8, 36, 36.8, 27, 38.2)
      ..close();

    final framePaint = Paint()
      ..color = const Color(0xFF181A20); // Stealth Carbon Frame

    canvas.drawPath(framePath, framePaint);

    // B. Jednoczęściowa panoramiczna soczewka aerodynamiczna (Shield Lens)
    final lensPath = Path()
      ..moveTo(27.5, 37.5)
      ..cubicTo(36, 36.0, 64, 36.0, 72.5, 37.5)
      ..cubicTo(74.5, 43.5, 72.0, 49.5, 65.5, 49.8)
      ..cubicTo(59.0, 50.2, 55.0, 46.5, 50.0, 46.5) // Wycięcie na grzbiet nosa
      ..cubicTo(45.0, 46.5, 41.0, 50.2, 34.5, 49.8)
      ..cubicTo(28.0, 49.5, 25.5, 43.5, 27.5, 37.5)
      ..close();

    // Wielobarwny gradient polaryzacyjny (Multi-stop Polarized Mirror Iridium)
    final lensShader = LinearGradient(
      begin: const Alignment(-0.8, -0.9),
      end: const Alignment(0.8, 0.9),
      colors: [
        baseLensColor.withValues(alpha: 0.88),
        polarizedAccent.withValues(alpha: 0.92),
        polarizedShadow.withValues(alpha: 0.85),
      ],
      stops: const [0.0, 0.52, 1.0],
    ).createShader(const Rect.fromLTWH(26, 36, 48, 15));

    canvas.drawPath(lensPath, Paint()..shader = lensShader);

    // C. Błysk polaryzacyjny i refleks słońca na soczewce (Specular Flare Streak)
    final reflectionStreak = Path()
      ..moveTo(31, 37.5)
      ..lineTo(37, 37.2)
      ..lineTo(44, 48.5)
      ..lineTo(38, 49.0)
      ..close();

    final flareShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.55),
        Colors.white.withValues(alpha: 0.0),
      ],
    ).createShader(const Rect.fromLTWH(30, 36, 16, 14));

    canvas.drawPath(reflectionStreak, Paint()..shader = flareShader);

    // Dodatkowy subtelny punktowy blask po prawej stronie
    canvas.drawCircle(
      const Offset(65.5, 40.5),
      1.1,
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );

    // D. Gumowe noski okularów (Nose Pads)
    final nosePadPaint = Paint()..color = const Color(0xFF2A2D35);
    canvas.drawCircle(const Offset(47.5, 48.0), 1.2, nosePadPaint);
    canvas.drawCircle(const Offset(52.5, 48.0), 1.2, nosePadPaint);
  }

  // ==========================================
  // 11. WINIETA I OŚWIETLENIE
  // ==========================================
  void _drawFinalGlossAndVignette(Canvas canvas) {
    // Subtelna winieta głębi na obrzeżach portretu
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.95,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.35),
        ],
        stops: const [0.72, 1.0],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 100));

    canvas.drawCircle(const Offset(50, 50), 49, vignettePaint);
  }

  @override
  bool shouldRepaint(covariant RiderAvatarPainter oldDelegate) {
    return oldDelegate.appearance != appearance ||
        oldDelegate.jerseyPrimaryColor != jerseyPrimaryColor ||
        oldDelegate.jerseySecondaryColor != jerseySecondaryColor ||
        oldDelegate.jerseyAccentColor != jerseyAccentColor ||
        oldDelegate.showHelmet != showHelmet ||
        oldDelegate.showGlasses != showGlasses ||
        oldDelegate.backgroundColor != backgroundColor;
  }

  // ==========================================
  // POMOCNIKI MATEMATYCZNE I KOLORYSTYCZNE
  // ==========================================

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

