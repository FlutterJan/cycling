import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/team/cycling_team.dart';

/// 8 unikalnych geometrycznych wzorów koszulek kolarskich
enum JerseyPattern {
  /// 1. Jednolity, nowoczesny minimalizm z kontrastującymi mankietami i stójką
  solid('Gładka (Klasyczna)'),

  /// 2. Szeroki poziomy pas na klatce piersiowej pod logo sponsora
  chestStripe('Pas poziomy na piersi'),

  /// 3. Dynamiczny szewron w kształcie litery V biegnący przez klatkę
  chevron('Szewron (V-Stripe)'),

  /// 4. Płynne przejście tonalne od koloru podstawowego do wtórnego
  gradient('Gradient tonalny'),

  /// 5. Klasyczne pionowe pasy wyścigowe
  verticalStripes('Pasy pionowe'),

  /// 6. Raglanowe rękawy i barki w kontrastowym kolorze
  contrastSleeves('Rękawki kontrastowe'),

  /// 7. Zaszczytna koszulka mistrza kraju z pasami barw narodowych
  nationalChampion('Koszulka mistrza kraju'),

  /// 8. Prestiżowa koszulka lidera wyścigu z wstawkami barw zespołowych
  raceLeader('Koszulka lidera wyścigu');

  final String label;
  const JerseyPattern(this.label);
}

/// CustomPainter precyzyjnie rysujący koszulkę kolarską zespołu w 8 wzorach
/// z trójkolorową paletą barw, logotypem sponsora na piersi, szwami i numerem startowym.
class TeamJerseyPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final JerseyPattern pattern;
  final String? sponsorName;
  final String? teamName;
  final String? teamTla;
  final String? secondarySponsorName;
  final Color? sponsorTextColor;
  final bool isBackView;
  final int? startNumber;
  final String? countryCode;
  final Color? leaderJerseyBaseColor;
  final bool showZipper;
  final bool showPockets;
  final bool showShadow;

  TeamJerseyPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.pattern = JerseyPattern.chestStripe,
    this.sponsorName,
    this.teamName,
    this.teamTla,
    this.secondarySponsorName,
    this.sponsorTextColor,
    this.isBackView = false,
    this.startNumber,
    this.countryCode = 'POL',
    this.leaderJerseyBaseColor,
    this.showZipper = true,
    this.showPockets = true,
    this.showShadow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double w = size.width;
    final double h = size.height;

    // 1. Zarys sylwetki koszulki (Raglan Cut - rękawy, kołnierzyk, taliowany korpus, ściągacz)
    final Path jerseyPath = _buildJerseySilhouettePath(w, h, isBackView);

    // 2. Miękki cień pod koszulką
    if (showShadow) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.save();
      canvas.translate(0, h * 0.025);
      canvas.drawPath(jerseyPath, shadowPaint);
      canvas.restore();
    }

    // 3. Kolor bazowy korpusu (podkład pod wzory)
    final Color effectiveBaseColor = _resolveBaseColor();
    final basePaint = Paint()
      ..color = effectiveBaseColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(jerseyPath, basePaint);

    // 4. Nakładanie wzoru geometrycznego (przycięte dokładnie do sylwetki koszulki)
    canvas.save();
    canvas.clipPath(jerseyPath);
    _paintPattern(canvas, w, h);
    canvas.restore();

    // 5. Szwy krawędziowe, rękawy, mankiety i stójka kołnierzyka
    _paintJerseyDetails(canvas, w, h, jerseyPath);

    // 6. Nazwa głównego sponsora na klatce piersiowej (lub numer startowy na plecach)
    final effectiveSponsor = sponsorName ?? teamName;
    if (isBackView) {
      if (showPockets) {
        _paintBackPockets(canvas, w, h);
      }
      if (startNumber != null) {
        _paintBackRaceNumber(canvas, w, h, startNumber!);
      } else if (effectiveSponsor != null && effectiveSponsor.isNotEmpty) {
        _paintSponsorName(canvas, w, h, effectiveSponsor, isBack: true);
      }
    } else {
      if (showZipper) {
        _paintFrontZipper(canvas, w, h);
      }
      if (effectiveSponsor != null && effectiveSponsor.isNotEmpty) {
        _paintSponsorName(canvas, w, h, effectiveSponsor, isBack: false);
      }
    }

    // 7. Kontur zewnętrzny koszulki dla ostrości
    final outlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, w * 0.008);
    canvas.drawPath(jerseyPath, outlinePaint);
  }

  /// Zwraca właściwy kolor bazowy w zależności od wzoru (np. żółty dla lidera, biały dla mistrza)
  Color _resolveBaseColor() {
    switch (pattern) {
      case JerseyPattern.raceLeader:
        return leaderJerseyBaseColor ?? const Color(0xFFFFD700); // Maillot Jaune
      case JerseyPattern.nationalChampion:
        return Colors.white;
      default:
        return primaryColor;
    }
  }

  /// Generuje precyzyjną, dopasowaną anatomicznie ścieżkę konturu koszulki kolarskiej
  Path _buildJerseySilhouettePath(double w, double h, bool isBack) {
    final Path path = Path();

    // Punkt startu: lewa krawędź stójki kołnierzyka
    path.moveTo(w * 0.38, h * 0.11);

    // Wycięcie kołnierzyka (płytsze z tyłu, głębsze z przodu)
    path.quadraticBezierTo(
      w * 0.50,
      isBack ? h * 0.12 : h * 0.17,
      w * 0.62,
      h * 0.11,
    );

    // Prawe ramię w dół
    path.lineTo(w * 0.83, h * 0.20);

    // Prawy rękaw: mankiet zewnętrzny
    path.lineTo(w * 0.96, h * 0.38);

    // Prawy mankiet ściągacz
    path.lineTo(w * 0.84, h * 0.44);

    // Prawa pacha
    path.lineTo(w * 0.75, h * 0.35);

    // Prawy bok korpusu (taliowany)
    path.quadraticBezierTo(w * 0.74, h * 0.62, w * 0.73, h * 0.87);

    // Dolny ściągacz koszulki (elastyczny aerodynamiczny łuk)
    path.quadraticBezierTo(w * 0.50, h * 0.91, w * 0.27, h * 0.87);

    // Lewy bok korpusu (taliowany w górę)
    path.quadraticBezierTo(w * 0.26, h * 0.62, w * 0.25, h * 0.35);

    // Lewa pacha i mankiet lewego rękawa
    path.lineTo(w * 0.16, h * 0.44);
    path.lineTo(w * 0.04, h * 0.38);

    // Lewe ramię w górę ku kołnierzykowi
    path.lineTo(w * 0.17, h * 0.20);

    path.close();
    return path;
  }

  /// Rysuje jeden z 8 geometrycznych wzorów koszulki
  void _paintPattern(Canvas canvas, double w, double h) {
    switch (pattern) {
      case JerseyPattern.solid:
        _paintPatternSolid(canvas, w, h);
        break;
      case JerseyPattern.chestStripe:
        _paintPatternChestStripe(canvas, w, h);
        break;
      case JerseyPattern.chevron:
        _paintPatternChevron(canvas, w, h);
        break;
      case JerseyPattern.gradient:
        _paintPatternGradient(canvas, w, h);
        break;
      case JerseyPattern.verticalStripes:
        _paintPatternVerticalStripes(canvas, w, h);
        break;
      case JerseyPattern.contrastSleeves:
        _paintPatternContrastSleeves(canvas, w, h);
        break;
      case JerseyPattern.nationalChampion:
        _paintPatternNationalChampion(canvas, w, h);
        break;
      case JerseyPattern.raceLeader:
        _paintPatternRaceLeader(canvas, w, h);
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // 1. WZÓR: GŁADKA (SOLID)
  // ---------------------------------------------------------------------------
  void _paintPatternSolid(Canvas canvas, double w, double h) {
    // Boczne panele wentylacyjne (oddychająca siateczka aero po bokach)
    final flankPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // Lewy panel boczny
    final leftFlank = Path()
      ..moveTo(w * 0.25, h * 0.38)
      ..lineTo(w * 0.33, h * 0.40)
      ..quadraticBezierTo(w * 0.32, h * 0.65, w * 0.34, h * 0.87)
      ..lineTo(w * 0.27, h * 0.87)
      ..quadraticBezierTo(w * 0.26, h * 0.62, w * 0.25, h * 0.38)
      ..close();
    canvas.drawPath(leftFlank, flankPaint);

    // Prawy panel boczny
    final rightFlank = Path()
      ..moveTo(w * 0.75, h * 0.38)
      ..lineTo(w * 0.67, h * 0.40)
      ..quadraticBezierTo(w * 0.68, h * 0.65, w * 0.66, h * 0.87)
      ..lineTo(w * 0.73, h * 0.87)
      ..quadraticBezierTo(w * 0.74, h * 0.62, w * 0.75, h * 0.38)
      ..close();
    canvas.drawPath(rightFlank, flankPaint);

    // Akcentowy pasek na dolnym ściągaczu
    final bottomAccent = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, h * 0.015);
    final bottomPath = Path()
      ..moveTo(w * 0.27, h * 0.87)
      ..quadraticBezierTo(w * 0.50, h * 0.91, w * 0.73, h * 0.87);
    canvas.drawPath(bottomPath, bottomAccent);
  }

  // ---------------------------------------------------------------------------
  // 2. WZÓR: PAS POZIOMY NA PIERSI (CHEST STRIPE)
  // ---------------------------------------------------------------------------
  void _paintPatternChestStripe(Canvas canvas, double w, double h) {
    final stripePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    final stripeY = h * 0.33;
    final stripeHeight = h * 0.22;
    canvas.drawRect(Rect.fromLTWH(0, stripeY, w, stripeHeight), stripePaint);

    // Górna i dolna lamówka akcentowa
    final borderPaint = Paint()
      ..color = accentColor
      ..strokeWidth = math.max(2.0, h * 0.016);
    canvas.drawLine(Offset(0, stripeY), Offset(w, stripeY), borderPaint);
    canvas.drawLine(Offset(0, stripeY + stripeHeight), Offset(w, stripeY + stripeHeight), borderPaint);
  }

  // ---------------------------------------------------------------------------
  // 3. WZÓR: SZEWRON (CHEVRON V-STRIPE)
  // ---------------------------------------------------------------------------
  void _paintPatternChevron(Canvas canvas, double w, double h) {
    final chevronPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    final chevronPath = Path()
      ..moveTo(w * 0.15, h * 0.28)
      ..lineTo(w * 0.50, h * 0.52)
      ..lineTo(w * 0.85, h * 0.28)
      ..lineTo(w * 0.85, h * 0.44)
      ..lineTo(w * 0.50, h * 0.68)
      ..lineTo(w * 0.15, h * 0.44)
      ..close();
    canvas.drawPath(chevronPath, chevronPaint);

    // Krawędź akcentowa szewronu
    final accentChevron = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.5, h * 0.018);
    final accentPath = Path()
      ..moveTo(w * 0.15, h * 0.44)
      ..lineTo(w * 0.50, h * 0.68)
      ..lineTo(w * 0.85, h * 0.44);
    canvas.drawPath(accentPath, accentChevron);
  }

  // ---------------------------------------------------------------------------
  // 4. WZÓR: GRADIENT TONALNY (GRADIENT)
  // ---------------------------------------------------------------------------
  void _paintPatternGradient(Canvas canvas, double w, double h) {
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [primaryColor, secondaryColor],
      stops: const [0.25, 0.90],
    );

    final gradPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), gradPaint);

    // Pasek akcentu przy dolnym ściągaczu
    final accentStripe = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, h * 0.82, w, h * 0.05), accentStripe);
  }

  // ---------------------------------------------------------------------------
  // 5. WZÓR: PASY PIONOWE (VERTICAL STRIPES)
  // ---------------------------------------------------------------------------
  void _paintPatternVerticalStripes(Canvas canvas, double w, double h) {
    final stripePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    final double stripeW = w * 0.09;
    // 3 pionowe pasy biegnące przez korpus
    canvas.drawRect(Rect.fromLTWH(w * 0.33, 0, stripeW, h), stripePaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.455, 0, stripeW, h), stripePaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.58, 0, stripeW, h), stripePaint);

    // Cienkie akcentowe linie przy pasach
    final accentLinePaint = Paint()
      ..color = accentColor
      ..strokeWidth = math.max(1.0, w * 0.007);
    canvas.drawLine(Offset(w * 0.33, 0), Offset(w * 0.33, h), accentLinePaint);
    canvas.drawLine(Offset(w * 0.67, 0), Offset(w * 0.67, h), accentLinePaint);

    // Poziomy szyld sponsorski na klatce piersiowej
    if (sponsorName != null && sponsorName!.isNotEmpty) {
      final bannerPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(w * 0.25, h * 0.35, w * 0.50, h * 0.18), bannerPaint);

      final bannerBorder = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRect(Rect.fromLTWH(w * 0.25, h * 0.35, w * 0.50, h * 0.18), bannerBorder);
    }
  }

  // ---------------------------------------------------------------------------
  // 6. WZÓR: RĘKAWKI KONTRASTOWE (CONTRAST SLEEVES)
  // ---------------------------------------------------------------------------
  void _paintPatternContrastSleeves(Canvas canvas, double w, double h) {
    final sleevePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    // Lewy rękaw i ramię
    final leftSleeve = Path()
      ..moveTo(w * 0.38, h * 0.11)
      ..lineTo(w * 0.17, h * 0.20)
      ..lineTo(w * 0.04, h * 0.38)
      ..lineTo(w * 0.16, h * 0.44)
      ..lineTo(w * 0.25, h * 0.35)
      ..lineTo(w * 0.38, h * 0.25)
      ..close();
    canvas.drawPath(leftSleeve, sleevePaint);

    // Prawy rękaw i ramię
    final rightSleeve = Path()
      ..moveTo(w * 0.62, h * 0.11)
      ..lineTo(w * 0.83, h * 0.20)
      ..lineTo(w * 0.96, h * 0.38)
      ..lineTo(w * 0.84, h * 0.44)
      ..lineTo(w * 0.75, h * 0.35)
      ..lineTo(w * 0.62, h * 0.25)
      ..close();
    canvas.drawPath(rightSleeve, sleevePaint);

    // Paski akcentowe na ramionach
    final accentLine = Paint()
      ..color = accentColor
      ..strokeWidth = math.max(2.0, h * 0.014);
    canvas.drawLine(Offset(w * 0.38, h * 0.11), Offset(w * 0.25, h * 0.35), accentLine);
    canvas.drawLine(Offset(w * 0.62, h * 0.11), Offset(w * 0.75, h * 0.35), accentLine);
  }

  // ---------------------------------------------------------------------------
  // 7. WZÓR: KOSZULKA MISTRZA KRAJU (NATIONAL CHAMPION)
  // ---------------------------------------------------------------------------
  void _paintPatternNationalChampion(Canvas canvas, double w, double h) {
    // 3 pasy w barwach narodowych na klatce piersiowej
    final stripeY = h * 0.35;
    final stripeH = h * 0.07;

    List<Color> flagColors;
    switch (countryCode?.toUpperCase()) {
      case 'POL':
        flagColors = [Colors.white, const Color(0xFFDC2626), const Color(0xFFDC2626)];
        break;
      case 'FRA':
        flagColors = [const Color(0xFF1D4ED8), Colors.white, const Color(0xFFDC2626)];
        break;
      case 'ITA':
        flagColors = [const Color(0xFF16A34A), Colors.white, const Color(0xFFDC2626)];
        break;
      case 'BEL':
        flagColors = [Colors.black87, const Color(0xFFFBBF24), const Color(0xFFDC2626)];
        break;
      case 'ESP':
        flagColors = [const Color(0xFFDC2626), const Color(0xFFFBBF24), const Color(0xFFDC2626)];
        break;
      default:
        // Uniwersalne pasy w barwach zespołu
        flagColors = [primaryColor, secondaryColor, accentColor];
        break;
    }

    for (int i = 0; i < 3; i++) {
      final p = Paint()
        ..color = flagColors[i]
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, stripeY + (i * stripeH), w, stripeH), p);
    }

    // Złote laury mistrzowskie / obwódki UCI
    final goldBorder = Paint()
      ..color = const Color(0xFFD4AF37)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, stripeY), Offset(w, stripeY), goldBorder);
    canvas.drawLine(Offset(0, stripeY + (3 * stripeH)), Offset(w, stripeY + (3 * stripeH)), goldBorder);
  }

  // ---------------------------------------------------------------------------
  // 8. WZÓR: KOSZULKA LIDERA WYŚCIGU (RACE LEADER)
  // ---------------------------------------------------------------------------
  void _paintPatternRaceLeader(Canvas canvas, double w, double h) {
    // Eleganckie wstawki tożsamości zespołu na rękawkach koszulki lidera
    final teamColorPaint1 = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    final teamColorPaint2 = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    // Prawy rękaw wstawka
    canvas.drawRect(Rect.fromLTWH(w * 0.86, h * 0.32, w * 0.10, h * 0.05), teamColorPaint1);
    canvas.drawRect(Rect.fromLTWH(w * 0.85, h * 0.37, w * 0.10, h * 0.05), teamColorPaint2);

    // Lewy rękaw wstawka
    canvas.drawRect(Rect.fromLTWH(w * 0.04, h * 0.32, w * 0.10, h * 0.05), teamColorPaint1);
    canvas.drawRect(Rect.fromLTWH(w * 0.05, h * 0.37, w * 0.10, h * 0.05), teamColorPaint2);

    // Biały panel na klatce piersiowej pod logo sponsora lidera
    final sponsorPanel = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.25, h * 0.32, w * 0.50, h * 0.22), const Radius.circular(4)),
      sponsorPanel,
    );

    final panelBorder = Paint()
      ..color = Colors.black.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.25, h * 0.32, w * 0.50, h * 0.22), const Radius.circular(4)),
      panelBorder,
    );
  }

  // ===========================================================================
  // SZCZEGÓŁY KOSZULKI (STÓJKA, MANKIETY, SZWY)
  // ===========================================================================

  void _paintJerseyDetails(Canvas canvas, double w, double h, Path silhouette) {
    // 1. Stójka kołnierzyka
    final collarPaint = Paint()
      ..color = (pattern == JerseyPattern.raceLeader ? primaryColor : accentColor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3.0, h * 0.022)
      ..strokeCap = StrokeCap.round;

    final collarPath = Path()
      ..moveTo(w * 0.38, h * 0.11)
      ..quadraticBezierTo(w * 0.50, isBackView ? h * 0.12 : h * 0.17, w * 0.62, h * 0.11);
    canvas.drawPath(collarPath, collarPaint);

    // 2. Mankiety rękawków
    final cuffPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.5, h * 0.018);

    // Lewy mankiet
    canvas.drawLine(Offset(w * 0.04, h * 0.38), Offset(w * 0.16, h * 0.44), cuffPaint);
    // Prawy mankiet
    canvas.drawLine(Offset(w * 0.96, h * 0.38), Offset(w * 0.84, h * 0.44), cuffPaint);

    // 3. Szwy raglanowe (pachy -> szyja)
    final seamPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawLine(Offset(w * 0.25, h * 0.35), Offset(w * 0.38, h * 0.11), seamPaint);
    canvas.drawLine(Offset(w * 0.75, h * 0.35), Offset(w * 0.62, h * 0.11), seamPaint);
  }

  // ===========================================================================
  // TYŁ KOSZULKI: KIESZENIE KOLARSKIE I NUMER STARTOWY
  // ===========================================================================

  void _paintBackPockets(Canvas canvas, double w, double h) {
    final pocketBg = Paint()
      ..color = secondaryColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    final pocketBorder = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final pocketTopY = h * 0.64;
    final pocketH = h * 0.22;

    // 3 kieszenie kolarskie
    final double leftX = w * 0.27;
    final double totalW = w * 0.46;
    final double singleW = totalW / 3.0;

    for (int i = 0; i < 3; i++) {
      final rect = Rect.fromLTWH(leftX + (i * singleW), pocketTopY, singleW, pocketH);
      canvas.drawRect(rect, pocketBg);
      canvas.drawRect(rect, pocketBorder);
    }
  }

  void _paintBackRaceNumber(Canvas canvas, double w, double h, int number) {
    final double boxW = w * 0.30;
    final double boxH = h * 0.18;
    final double boxX = (w - boxW) / 2.0;
    final double boxY = h * 0.42;

    // Biała tabliczka z numerem startowym
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(boxX, boxY, boxW, boxH), const Radius.circular(2)),
      bgPaint,
    );

    // Czerwona lub czarna ramka
    final borderPaint = Paint()
      ..color = const Color(0xFFDC2626)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(Rect.fromLTWH(boxX, boxY, boxW, boxH), borderPaint);

    // 4 czarne agrafki w rogach
    final pinPaint = Paint()..color = Colors.black54;
    canvas.drawCircle(Offset(boxX + 3, boxY + 3), 1.5, pinPaint);
    canvas.drawCircle(Offset(boxX + boxW - 3, boxY + 3), 1.5, pinPaint);
    canvas.drawCircle(Offset(boxX + 3, boxY + boxH - 3), 1.5, pinPaint);
    canvas.drawCircle(Offset(boxX + boxW - 3, boxY + boxH - 3), 1.5, pinPaint);

    // Cyfra numeru startowego
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          color: Colors.black87,
          fontSize: boxH * 0.65,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(boxX + (boxW - textPainter.width) / 2.0, boxY + (boxH - textPainter.height) / 2.0),
    );
  }

  // ===========================================================================
  // PRZÓD KOSZULKI: ZAMEK BŁYSKAWICZNY I NAZWA SPONSORA
  // ===========================================================================

  void _paintFrontZipper(Canvas canvas, double w, double h) {
    final zipperPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 1.2;

    canvas.drawLine(
      Offset(w * 0.50, h * 0.16),
      Offset(w * 0.50, h * 0.32),
      zipperPaint,
    );

    // Suwak zamka
    final pullPaint = Paint()..color = accentColor;
    canvas.drawCircle(Offset(w * 0.50, h * 0.18), 2.5, pullPaint);
  }

  void _paintSponsorName(Canvas canvas, double w, double h, String name, {required bool isBack}) {
    final double centerY = isBack ? h * 0.34 : (pattern == JerseyPattern.chestStripe ? h * 0.44 : h * 0.45);
    final double maxTextWidth = w * 0.44;

    // Dobór kontrastowego koloru tekstu
    final Color textColor = sponsorTextColor ?? _calculateContrastTextColor();

    // Obliczamy dynamiczny rozmiar czcionki
    double fontSize = w * 0.085;
    TextPainter painter = TextPainter(
      text: TextSpan(
        text: name.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.35),
              offset: const Offset(0.5, 0.5),
              blurRadius: 1.0,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    if (painter.width > maxTextWidth) {
      fontSize = fontSize * (maxTextWidth / painter.width);
      painter = TextPainter(
        text: TextSpan(
          text: name.toUpperCase(),
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.35),
                offset: const Offset(0.5, 0.5),
                blurRadius: 1.0,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    final double textX = (w - painter.width) / 2.0;
    final double textY = centerY - (painter.height / 2.0);

    painter.paint(canvas, Offset(textX, textY));
  }

  /// Wylicza kontrastowy kolor napisu (biały lub ciemny grafit) na bazie luminancji tła
  Color _calculateContrastTextColor() {
    Color bgSample;
    switch (pattern) {
      case JerseyPattern.chestStripe:
        bgSample = secondaryColor;
        break;
      case JerseyPattern.nationalChampion:
      case JerseyPattern.raceLeader:
        bgSample = Colors.white;
        break;
      default:
        bgSample = primaryColor;
        break;
    }

    return bgSample.computeLuminance() > 0.45 ? const Color(0xFF1E293B) : Colors.white;
  }

  @override
  bool shouldRepaint(covariant TeamJerseyPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.pattern != pattern ||
        oldDelegate.sponsorName != sponsorName ||
        oldDelegate.isBackView != isBackView ||
        oldDelegate.startNumber != startNumber ||
        oldDelegate.countryCode != countryCode ||
        oldDelegate.leaderJerseyBaseColor != leaderJerseyBaseColor;
  }
}

// =============================================================================
// WIDGET FLUTTER: TEAM JERSEY WIDGET
// =============================================================================

/// Gotowy do użycia komponent UI wyświetlający koszulkę kolarską zespołu
/// w jednym z 8 wzorów, z możliwością wyboru widoku przód/tył i interakcji.
class TeamJerseyWidget extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final JerseyPattern pattern;
  final String? sponsorName;
  final bool isBackView;
  final int? startNumber;
  final String? countryCode;
  final Color? leaderJerseyBaseColor;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool isSelected;

  const TeamJerseyWidget({
    super.key,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.pattern = JerseyPattern.chestStripe,
    this.sponsorName,
    this.isBackView = false,
    this.startNumber,
    this.countryCode = 'POL',
    this.leaderJerseyBaseColor,
    this.width,
    this.height,
    this.onTap,
    this.isSelected = false,
  });

  /// Wygodny konstruktor tworzący koszulkę na podstawie modelu [CyclingTeam]
  factory TeamJerseyWidget.fromTeam(
    CyclingTeam team, {
    Key? key,
    JerseyPattern pattern = JerseyPattern.chestStripe,
    bool isBackView = false,
    int? startNumber,
    double? width,
    double? height,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    final pColor = _parseHex(team.primaryJerseyColorHex, AppColors.accentBlue);
    final sColor = _parseHex(team.secondaryJerseyColorHex, AppColors.surfaceLight);
    final aColor = _parseHex(team.accentJerseyColorHex, AppColors.goldAccent);
    final sponsor = team.sponsors.isNotEmpty ? team.sponsors.first.companyName : team.name;

    return TeamJerseyWidget(
      key: key,
      primaryColor: pColor,
      secondaryColor: sColor,
      accentColor: aColor,
      pattern: pattern,
      sponsorName: sponsor,
      isBackView: isBackView,
      startNumber: startNumber,
      countryCode: team.countryIso,
      width: width,
      height: height,
      onTap: onTap,
      isSelected: isSelected,
    );
  }

  /// Miniaturowa koszulka (np. 32x32 do tabel wyników i list peletonu)
  const TeamJerseyWidget.mini({
    super.key,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.pattern = JerseyPattern.chestStripe,
    double size = 32.0,
  })  : sponsorName = null,
        isBackView = false,
        startNumber = null,
        countryCode = 'POL',
        leaderJerseyBaseColor = null,
        width = size,
        height = size,
        onTap = null,
        isSelected = false;

  static Color _parseHex(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double targetW = width ?? 140.0;
    final double targetH = height ?? 160.0;

    Widget jersey = CustomPaint(
      size: Size(targetW, targetH),
      painter: TeamJerseyPainter(
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        accentColor: accentColor,
        pattern: pattern,
        sponsorName: sponsorName,
        isBackView: isBackView,
        startNumber: startNumber,
        countryCode: countryCode,
        leaderJerseyBaseColor: leaderJerseyBaseColor,
      ),
    );

    if (isSelected) {
      jersey = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.goldAccent, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.goldAccent.withValues(alpha: 0.30),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: jersey,
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: jersey,
      );
    }

    return jersey;
  }
}

/// Alias dla elastyczności architektonicznej
typedef CustomJerseyPainter = TeamJerseyPainter;
