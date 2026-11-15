// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/rider/rider.dart';
import '../../services/career/national_championships_and_worlds_service.dart';
import 'rider_avatar_painter.dart';

/// Oficjalne barwy 5 tęczowych pasów Mistrza Świata UCI (Rainbow Stripes / Maillot Arc-en-Ciel).
class UciRainbowColors {
  UciRainbowColors._();

  /// Niebieski / Błękitny (Cyan / Process Blue)
  static const Color blue = Color(0xFF0085C7);

  /// Czerwony (Pantone 186 C)
  static const Color red = Color(0xFFEE334E);

  /// Czarny (Pantone Black)
  static const Color black = Color(0xFF1E293B);

  /// Żółty (Pantone 123 C)
  static const Color yellow = Color(0xFFFCB131);

  /// Zielony (Pantone 355 C)
  static const Color green = Color(0xFF00A651);

  /// Wszystkie 5 pasów w oficjalnej kolejności UCI od góry do dołu
  static const List<Color> stripes = [blue, red, black, yellow, green];

  /// Elegancki gradient łączący pasy tęczy
  static const LinearGradient rainbowGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: stripes,
  );
}

/// Styl prezentacji oznaczenia mistrzowskiego w UI gry.
enum BadgeStyle {
  /// Kompaktowy mikroskopijny pasek / ikona do tabel wyników i klasyfikacji (np. 20x13px)
  tableCompact,

  /// Elegancka pigułka (Pill Chip) z napisem i obwódką do kart zawodników i nagłówków
  ribbonPill,

  /// Wektorowa miniatura koszulki kolarskiej z pasami
  jerseyMiniature,

  /// Oznaczenie dożywotnich pasów na mankietach rękawków byłego mistrza świata
  sleeveCuffTag,

  /// Okrągła/owalna przypinka na narożnik portretu kolarza (Avatar Corner)
  avatarCornerPill,
}

/// Główny widżet odznaki Tęczowej Koszulki Mistrza Świata oraz Koszulki Mistrza Kraju.
class RainbowAndNationalJerseyBadge extends StatelessWidget {
  /// Status koszulki specjalnej przysługującej kolarzowi
  final SpecialJerseyDesignation designation;

  /// Kod ISO kraju kolarza (np. 'POL', 'FRA', 'BEL', 'SLO')
  final String? countryIso;

  /// Wybrany styl renderowania
  final BadgeStyle style;

  /// Bazowy rozmiar widżetu (dopasowuje szerokość/wysokość w zależności od stylu)
  final double size;

  /// Własny tekst dymka pomocy (Tooltip). Jeśli null, generowany automatycznie.
  final String? customTooltip;

  /// Czy pokazywać animowany złoty połysk dla mistrza świata
  final bool enableShimmer;

  /// Opcjonalna akcja po kliknięciu
  final VoidCallback? onTap;

  const RainbowAndNationalJerseyBadge({
    super.key,
    required this.designation,
    this.countryIso,
    this.style = BadgeStyle.tableCompact,
    this.size = 20.0,
    this.customTooltip,
    this.enableShimmer = false,
    this.onTap,
  });

  /// Wygodny konstruktor tworzący odznakę bezpośrednio z modelu [Rider] i rejestru mistrzów [ReigningChampionsRegistry].
  factory RainbowAndNationalJerseyBadge.fromRider({
    Key? key,
    required Rider rider,
    required ReigningChampionsRegistry registry,
    BadgeStyle style = BadgeStyle.tableCompact,
    double size = 20.0,
    bool isTimeTrial = false,
    String? customTooltip,
    VoidCallback? onTap,
  }) {
    final designation = _resolveRiderDesignation(
      riderId: rider.id,
      nationalityIso: rider.nationalityIso,
      registry: registry,
      isTimeTrial: isTimeTrial,
    );

    return RainbowAndNationalJerseyBadge(
      key: key,
      designation: designation,
      countryIso: rider.nationalityIso,
      style: style,
      size: size,
      customTooltip: customTooltip,
      onTap: onTap,
    );
  }

  /// Bezpośrednia odznaka Tęczowej Koszulki Mistrza Świata
  factory RainbowAndNationalJerseyBadge.rainbow({
    Key? key,
    BadgeStyle style = BadgeStyle.tableCompact,
    double size = 20.0,
    String? customTooltip,
    VoidCallback? onTap,
  }) {
    return RainbowAndNationalJerseyBadge(
      key: key,
      designation: SpecialJerseyDesignation.rainbowJersey,
      style: style,
      size: size,
      customTooltip: customTooltip,
      enableShimmer: true,
      onTap: onTap,
    );
  }

  /// Bezpośrednia odznaka Koszulki Mistrza Kraju
  factory RainbowAndNationalJerseyBadge.national({
    Key? key,
    required String countryIso,
    BadgeStyle style = BadgeStyle.tableCompact,
    double size = 20.0,
    String? customTooltip,
    VoidCallback? onTap,
  }) {
    return RainbowAndNationalJerseyBadge(
      key: key,
      designation: SpecialJerseyDesignation.nationalChampionJersey,
      countryIso: countryIso,
      style: style,
      size: size,
      customTooltip: customTooltip,
      onTap: onTap,
    );
  }

  /// Bezpośrednia odznaka byłego mistrza świata z tęczowymi paskami na rękawkach
  factory RainbowAndNationalJerseyBadge.formerWorldChampion({
    Key? key,
    BadgeStyle style = BadgeStyle.tableCompact,
    double size = 20.0,
    String? customTooltip,
    VoidCallback? onTap,
  }) {
    return RainbowAndNationalJerseyBadge(
      key: key,
      designation: SpecialJerseyDesignation.formerWorldChampionRainbowBands,
      style: style,
      size: size,
      customTooltip: customTooltip,
      onTap: onTap,
    );
  }

  static SpecialJerseyDesignation _resolveRiderDesignation({
    required String riderId,
    required String nationalityIso,
    required ReigningChampionsRegistry registry,
    bool isTimeTrial = false,
  }) {
    if (registry.isReigningWorldChampion(riderId, isTimeTrial: isTimeTrial)) {
      return SpecialJerseyDesignation.rainbowJersey;
    }
    if (registry.isReigningNationalChampion(riderId, nationalityIso, isTimeTrial: isTimeTrial)) {
      return SpecialJerseyDesignation.nationalChampionJersey;
    }
    if (registry.isFormerWorldChampion(riderId)) {
      return SpecialJerseyDesignation.formerWorldChampionRainbowBands;
    }
    return SpecialJerseyDesignation.standardTeamJersey;
  }

  @override
  Widget build(BuildContext context) {
    if (designation == SpecialJerseyDesignation.standardTeamJersey) {
      return const SizedBox.shrink();
    }

    final tooltipText = customTooltip ?? _resolveDefaultTooltip();

    Widget badgeContent;
    switch (style) {
      case BadgeStyle.tableCompact:
        badgeContent = _buildTableCompact();
        break;
      case BadgeStyle.ribbonPill:
        badgeContent = _buildRibbonPill();
        break;
      case BadgeStyle.jerseyMiniature:
        badgeContent = _buildJerseyMiniature();
        break;
      case BadgeStyle.sleeveCuffTag:
        badgeContent = _buildSleeveCuffTag();
        break;
      case BadgeStyle.avatarCornerPill:
        badgeContent = _buildAvatarCornerPill();
        break;
    }

    final interactive = GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltipText,
        waitDuration: const Duration(milliseconds: 250),
        child: badgeContent,
      ),
    );

    return interactive;
  }

  // ---------------------------------------------------------------------------
  // 1. STYL: TABLE COMPACT (DO TABEL WYNIKÓW I LIST STARTOWYCH)
  // ---------------------------------------------------------------------------
  Widget _buildTableCompact() {
    final double width = size * 1.5;
    final double height = size;

    if (designation == SpecialJerseyDesignation.rainbowJersey) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2.5),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 2.0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1.5),
        child: const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(1.0)),
          child: RainbowJerseyStripesBar(),
        ),
      );
    } else if (designation == SpecialJerseyDesignation.formerWorldChampionRainbowBands) {
      // Były mistrz świata w tabeli: biało-szary prostokąt z tęczowymi paskami po bokach (mankiety)
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1E222B),
          borderRadius: BorderRadius.circular(2.5),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 3.0,
              decoration: const BoxDecoration(
                gradient: UciRainbowColors.rainbowGradient,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'WC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: math.max(7.0, size * 0.45),
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            Container(
              width: 3.0,
              decoration: const BoxDecoration(
                gradient: UciRainbowColors.rainbowGradient,
              ),
            ),
          ],
        ),
      );
    } else {
      // Mistrz Kraju
      final iso = countryIso ?? 'POL';
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF181B22),
          borderRadius: BorderRadius.circular(2.5),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 2.0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: NationalJerseyStripesBar(countryIso: iso),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 2. STYL: RIBBON PILL (PIGUŁKA DO PROFILI I KART)
  // ---------------------------------------------------------------------------
  Widget _buildRibbonPill() {
    if (designation == SpecialJerseyDesignation.rainbowJersey) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E2415), Color(0xFF181B22)],
          ),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.goldAccent, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.goldAccent.withValues(alpha: 0.25),
              blurRadius: 6.0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14.0,
              height: 10.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0),
              child: const RainbowJerseyStripesBar(),
            ),
            const SizedBox(width: 6.0),
            const Text(
              'MISTRZ ŚWIATA UCI',
              style: TextStyle(
                color: AppColors.goldAccent,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
    } else if (designation == SpecialJerseyDesignation.formerWorldChampionRainbowBands) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1E222D),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.0,
              height: 10.0,
              decoration: const BoxDecoration(
                gradient: UciRainbowColors.rainbowGradient,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6.0),
            Text(
              'B. MISTRZ ŚWIATA (PASKI NA RĘKAWKACH)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    } else {
      final iso = countryIso ?? 'POL';
      final countryName = NationalChampionshipsAndWorldsService.getCountryName(iso);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
        decoration: BoxDecoration(
          color: const Color(0xFF181B22),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14.0,
              height: 10.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1.5),
                child: NationalJerseyStripesBar(countryIso: iso),
              ),
            ),
            const SizedBox(width: 6.0),
            Text(
              'MISTRZ: ${countryName.toUpperCase()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 3. STYL: MINIATURA KOSZULKI (JERSEY MINIATURE)
  // ---------------------------------------------------------------------------
  Widget _buildJerseyMiniature() {
    return SizedBox(
      width: size * 1.25,
      height: size,
      child: CustomPaint(
        painter: _MiniatureJerseyPainter(
          designation: designation,
          countryIso: countryIso ?? 'POL',
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. STYL: SLEEVE CUFF TAG (MANKIET BYŁEGO MISTRZA ŚWIATA)
  // ---------------------------------------------------------------------------
  Widget _buildSleeveCuffTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: const Color(0xFF131722),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4.0,
            height: size * 0.75,
            decoration: const BoxDecoration(
              gradient: UciRainbowColors.rainbowGradient,
              borderRadius: BorderRadius.all(Radius.circular(1.0)),
            ),
          ),
          const SizedBox(width: 4.0),
          Text(
            'RAINBOW CUFFS',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. STYL: AVATAR CORNER PILL (PRZYPINKA NAROŻNA DO AWATARA)
  // ---------------------------------------------------------------------------
  Widget _buildAvatarCornerPill() {
    final double diameter = size;

    if (designation == SpecialJerseyDesignation.rainbowJersey) {
      return Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.goldAccent, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2.5),
        child: const ClipOval(
          child: RainbowJerseyStripesBar(),
        ),
      );
    } else if (designation == SpecialJerseyDesignation.formerWorldChampionRainbowBands) {
      return Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: const Color(0xFF181B22),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 3.0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3.0),
        child: Container(
          decoration: const BoxDecoration(
            gradient: UciRainbowColors.rainbowGradient,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.star,
              color: Colors.white,
              size: 10.0,
            ),
          ),
        ),
      );
    } else {
      final iso = countryIso ?? 'POL';
      return Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 3.0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: NationalJerseyStripesBar(countryIso: iso),
      );
    }
  }

  String _resolveDefaultTooltip() {
    switch (designation) {
      case SpecialJerseyDesignation.rainbowJersey:
        return 'Aktualny Mistrz Świata UCI (Rainbow Jersey) • Oficjalne tęczowe pasy czempiona globu';
      case SpecialJerseyDesignation.nationalChampionJersey:
        final iso = countryIso ?? 'POL';
        final theme = NationalChampionshipsAndWorldsService.getNationalJerseyColorTheme(iso);
        return 'Aktualny Mistrz Kraju (${theme['country']}) • ${theme['description']}';
      case SpecialJerseyDesignation.formerWorldChampionRainbowBands:
        return 'Były Mistrz Świata UCI • Dożywotnie tęczowe paski na mankietach rękawków i kołnierzyku';
      case SpecialJerseyDesignation.standardTeamJersey:
        return 'Standardowy strój drużynowy';
    }
  }
}

/// Widżet rysujący 5 oficjalnych pasów tęczy UCI.
class RainbowJerseyStripesBar extends StatelessWidget {
  final Axis axis;

  const RainbowJerseyStripesBar({
    super.key,
    this.axis = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final children = UciRainbowColors.stripes
        .map((c) => Expanded(child: Container(color: c)))
        .toList();

    return axis == Axis.vertical
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
  }
}

/// Widżet rysujący narodowe pasy mistrza kraju dla danego kodu [countryIso].
class NationalJerseyStripesBar extends StatelessWidget {
  final String countryIso;

  const NationalJerseyStripesBar({
    super.key,
    required this.countryIso,
  });

  @override
  Widget build(BuildContext context) {
    final theme = NationalChampionshipsAndWorldsService.getNationalJerseyColorTheme(countryIso);
    final primary = _parseHex(theme['primaryHex'], Colors.white);
    final secondary = _parseHex(theme['secondaryHex'], Colors.red);
    final accent = _parseHex(theme['accentHex'], Colors.white);

    switch (countryIso.toUpperCase()) {
      case 'POL':
        // Biel na górze, czerwień na dole
        return Column(
          children: [
            Expanded(child: Container(color: primary)),
            Expanded(child: Container(color: secondary)),
          ],
        );
      case 'FRA':
      case 'ITA':
      case 'BEL':
      case 'GER':
        // Układ tricolor 3 pasy poziome lub pionowe
        return Column(
          children: [
            Expanded(child: Container(color: primary)),
            Expanded(child: Container(color: secondary)),
            Expanded(child: Container(color: accent)),
          ],
        );
      case 'ESP':
        // Rojigualda: Czerwony, Żółty (szerszy), Czerwony
        return Column(
          children: [
            Expanded(flex: 1, child: Container(color: primary)),
            Expanded(flex: 2, child: Container(color: secondary)),
            Expanded(flex: 1, child: Container(color: accent)),
          ],
        );
      default:
        return Column(
          children: [
            Expanded(child: Container(color: primary)),
            Expanded(child: Container(color: secondary)),
          ],
        );
    }
  }

  static Color _parseHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      String clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) clean = 'FF$clean';
      return Color(int.parse(clean, radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}

/// Zaawansowany widżet portretu kolarza wzbogacony o oznaczenia mistrzowskie.
/// Łączy [RiderAvatarWidget] z narożną odznaką i automatyczną aktualizacją barw koszulki.
class RiderChampionshipAvatar extends StatelessWidget {
  final Rider rider;
  final ReigningChampionsRegistry? registry;
  final SpecialJerseyDesignation? manualDesignation;
  final double size;
  final bool showBadge;
  final bool isTimeTrial;
  final VoidCallback? onTap;

  const RiderChampionshipAvatar({
    super.key,
    required this.rider,
    this.registry,
    this.manualDesignation,
    this.size = 80.0,
    this.showBadge = true,
    this.isTimeTrial = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final designation = manualDesignation ??
        (registry != null
            ? RainbowAndNationalJerseyBadge._resolveRiderDesignation(
                riderId: rider.id,
                nationalityIso: rider.nationalityIso,
                registry: registry!,
                isTimeTrial: isTimeTrial,
              )
            : SpecialJerseyDesignation.standardTeamJersey);

    final avatar = RiderAvatarWidget.fromRider(
      rider: rider,
      specialJersey: designation,
      nationalityIso: rider.nationalityIso,
      size: size,
      onTap: onTap,
    );

    if (!showBadge || designation == SpecialJerseyDesignation.standardTeamJersey) {
      return avatar;
    }

    final badgeSize = math.max(16.0, size * 0.32);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -1,
            bottom: -1,
            child: RainbowAndNationalJerseyBadge(
              designation: designation,
              countryIso: rider.nationalityIso,
              style: BadgeStyle.avatarCornerPill,
              size: badgeSize,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rysownik miniatury koszulki kolarskiej z pasami mistrzowskimi.
class _MiniatureJerseyPainter extends CustomPainter {
  final SpecialJerseyDesignation designation;
  final String countryIso;

  _MiniatureJerseyPainter({
    required this.designation,
    required this.countryIso,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Sylwetka koszulki (ramiona, rękawki, boki)
    final jerseyPath = Path()
      ..moveTo(w * 0.35, h * 0.1) // Kołnierzyk lewy
      ..lineTo(w * 0.65, h * 0.1) // Kołnierzyk prawy
      ..lineTo(w * 0.95, h * 0.32) // Prawy rękawek
      ..lineTo(w * 0.82, h * 0.48) // Koniec prawego rękawka
      ..lineTo(w * 0.72, h * 0.40) // Pacha prawa
      ..lineTo(w * 0.74, h * 0.95) // Dół prawy
      ..lineTo(w * 0.26, h * 0.95) // Dół lewy
      ..lineTo(w * 0.28, h * 0.40) // Pacha lewa
      ..lineTo(w * 0.18, h * 0.48) // Koniec lewego rękawka
      ..lineTo(w * 0.05, h * 0.32) // Lewy rękawek
      ..close();

    Color baseColor = const Color(0xFF1E3A8A); // Domyślny granat
    if (designation == SpecialJerseyDesignation.rainbowJersey) {
      baseColor = Colors.white;
    } else if (designation == SpecialJerseyDesignation.nationalChampionJersey) {
      final theme = NationalChampionshipsAndWorldsService.getNationalJerseyColorTheme(countryIso);
      baseColor = NationalJerseyStripesBar._parseHex(theme['primaryHex'], Colors.white);
    }

    final paintBase = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(jerseyPath, paintBase);

    // Krawędź obrysu koszulki
    final strokePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(jerseyPath, strokePaint);

    // Rysowanie pasów w zależności od statusu
    canvas.save();
    canvas.clipPath(jerseyPath);

    if (designation == SpecialJerseyDesignation.rainbowJersey) {
      // 5 poziomych tęczowych pasów na klatce piersiowej
      final double bandTop = h * 0.45;
      final double bandH = h * 0.05;
      for (int i = 0; i < UciRainbowColors.stripes.length; i++) {
        final p = Paint()..color = UciRainbowColors.stripes[i];
        canvas.drawRect(Rect.fromLTWH(0, bandTop + (i * bandH), w, bandH), p);
      }
    } else if (designation == SpecialJerseyDesignation.formerWorldChampionRainbowBands) {
      // Tęczowe paski na mankietach rękawków i kołnierzyku!
      final leftCuff = Rect.fromLTWH(w * 0.05, h * 0.38, w * 0.16, h * 0.08);
      final rightCuff = Rect.fromLTWH(w * 0.79, h * 0.38, w * 0.16, h * 0.08);

      final cuffGradient = Paint()
        ..shader = UciRainbowColors.rainbowGradient.createShader(leftCuff);
      canvas.drawRect(leftCuff, cuffGradient);
      canvas.drawRect(rightCuff, cuffGradient);

      // Kołnierzyk
      final collarRect = Rect.fromLTWH(w * 0.35, h * 0.08, w * 0.30, h * 0.06);
      canvas.drawRect(collarRect, cuffGradient);
    } else if (designation == SpecialJerseyDesignation.nationalChampionJersey) {
      final theme = NationalChampionshipsAndWorldsService.getNationalJerseyColorTheme(countryIso);
      final secColor = NationalJerseyStripesBar._parseHex(theme['secondaryHex'], Colors.red);
      final accentColor = NationalJerseyStripesBar._parseHex(theme['accentHex'], Colors.white);

      // Poziomy pas narodowy
      final p1 = Paint()..color = secColor;
      final p2 = Paint()..color = accentColor;
      canvas.drawRect(Rect.fromLTWH(0, h * 0.45, w, h * 0.14), p1);
      canvas.drawRect(Rect.fromLTWH(0, h * 0.59, w, h * 0.14), p2);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniatureJerseyPainter oldDelegate) {
    return oldDelegate.designation != designation || oldDelegate.countryIso != countryIso;
  }
}

/// Narzędzia pomocnicze do renderowania barw mistrzowskich w silniku 3D peletonu (`PelotonInstancedRenderer`).
class Championship3DVisuals {
  Championship3DVisuals._();

  /// Zwraca kolor bazowy koszulki kolarza 3D w zależności od statusu mistrzowskiego.
  static Color resolve3DPrimaryJerseyColor({
    required SpecialJerseyDesignation designation,
    required Color defaultTeamColor,
    String? countryIso,
  }) {
    switch (designation) {
      case SpecialJerseyDesignation.rainbowJersey:
        return Colors.white;
      case SpecialJerseyDesignation.nationalChampionJersey:
        final theme = NationalChampionshipsAndWorldsService.getNationalJerseyColorTheme(countryIso ?? 'POL');
        return NationalJerseyStripesBar._parseHex(theme['primaryHex'], defaultTeamColor);
      case SpecialJerseyDesignation.formerWorldChampionRainbowBands:
      case SpecialJerseyDesignation.standardTeamJersey:
        return defaultTeamColor;
    }
  }

  /// Rysuje tęczowe akcenty lub narodowe pasy na kolarzu 3D na płótnie [Canvas].
  static void paint3DChampionshipAccents({
    required Canvas canvas,
    required SpecialJerseyDesignation designation,
    required Rect torsoRect,
    required double scale,
    String? countryIso,
    Offset? leftWrist,
    Offset? rightWrist,
  }) {
    if (designation == SpecialJerseyDesignation.standardTeamJersey) return;

    if (designation == SpecialJerseyDesignation.rainbowJersey) {
      // 5 pasów na klatce piersiowej modelu 3D
      final double bandH = math.max(1.0, 1.2 * scale);
      final double startY = torsoRect.center.dy - (bandH * 2.5);

      for (int i = 0; i < UciRainbowColors.stripes.length; i++) {
        final paint = Paint()
          ..color = UciRainbowColors.stripes[i]
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTWH(torsoRect.left, startY + (i * bandH), torsoRect.width, bandH),
          paint,
        );
      }
    } else if (designation == SpecialJerseyDesignation.formerWorldChampionRainbowBands) {
      // Dożywotnie tęczowe paski na mankietach rękawów (nadgarstki 3D)
      if (leftWrist != null) {
        _draw3DCuffRainbow(canvas, leftWrist, scale);
      }
      if (rightWrist != null) {
        _draw3DCuffRainbow(canvas, rightWrist, scale);
      }
    } else if (designation == SpecialJerseyDesignation.nationalChampionJersey) {
      final theme = NationalChampionshipsAndWorldsService.getNationalJerseyColorTheme(countryIso ?? 'POL');
      final secColor = NationalJerseyStripesBar._parseHex(theme['secondaryHex'], Colors.red);
      final double bandH = math.max(1.2, 2.2 * scale);

      final paint = Paint()..color = secColor;
      canvas.drawRect(
        Rect.fromCenter(center: torsoRect.center, width: torsoRect.width, height: bandH),
        paint,
      );
    }
  }

  static void _draw3DCuffRainbow(Canvas canvas, Offset wrist, double scale) {
    final double bandWidth = 3.5 * scale;
    final double stripeH = math.max(0.6, 0.8 * scale);

    for (int i = 0; i < UciRainbowColors.stripes.length; i++) {
      final p = Paint()..color = UciRainbowColors.stripes[i];
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(wrist.dx, wrist.dy - (2.0 * stripeH) + (i * stripeH)),
          width: bandWidth,
          height: stripeH,
        ),
        p,
      );
    }
  }
}
