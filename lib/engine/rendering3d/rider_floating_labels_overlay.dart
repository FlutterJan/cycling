// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../state/race_simulation_notifier.dart';
import '../peloton/rider_race_state.dart';
import 'peloton_instanced_renderer.dart';
import 'scene_3d_math_projection.dart';

// =============================================================================
// 1. TYPY I ENUMERACJE ETYKIET UNOSZĄCYCH SIĘ (NAMEPLATES)
// =============================================================================

/// Rodzaje koszulek lidera wyścigu (Grand Tour & WorldTour Classics).
enum LeaderJerseyType {
  /// Standardowa koszulka klubowa.
  none(
    label: 'Brak koszulki lidera',
    shortTag: '',
    primaryColor: Colors.transparent,
  ),

  /// Żółta koszulka lidera klasyfikacji generalnej (Tour de France - Maillot Jaune).
  yellowGC(
    label: 'Lider Klasyfikacji Generalnej (Żółta)',
    shortTag: 'GC',
    primaryColor: Color(0xFFFFD700), // Złoto / Żółty
  ),

  /// Zielona koszulka lidera klasyfikacji punktowej / sprinterskiej (Maillot Vert).
  greenPoints(
    label: 'Lider Klasyfikacji Punktowej (Zielona)',
    shortTag: 'SPRINT',
    primaryColor: Color(0xFF10B981), // Szmaragdowa zieleń
  ),

  /// Biała koszulka w czerwone grochy najlepszego górala (Maillot à Pois).
  polkaDotKOM(
    label: 'Król Gór (Koszulka w grochy)',
    shortTag: 'KOM',
    primaryColor: Color(0xFFEF4444), // Czerwone grochy
  ),

  /// Biała koszulka najlepszego młodzieżowca do lat 25 (Maillot Blanc).
  whiteYoung(
    label: 'Najlepszy Młodzieżowiec U25 (Biała)',
    shortTag: 'U25',
    primaryColor: Color(0xFFF8FAFC), // Czysta biel
  ),

  /// Różowa koszulka lidera Giro d'Italia (Maglia Rosa).
  pinkGC(
    label: 'Lider Giro d\'Italia (Różowa)',
    shortTag: 'ROSA',
    primaryColor: Color(0xFFF472B6), // Róż
  ),

  /// Czerwona koszulka lidera Vuelta a España (La Roja).
  redGC(
    label: 'Lider Vuelta a España (Czerwona)',
    shortTag: 'ROJA',
    primaryColor: Color(0xFFDC2626), // Czerwień
  );

  final String label;
  final String shortTag;
  final Color primaryColor;

  const LeaderJerseyType({
    required this.label,
    required this.shortTag,
    required this.primaryColor,
  });

  bool get isLeader => this != LeaderJerseyType.none;
}

/// Aktywny stan taktyczny kolarza wymagający specjalnego znacznika nad głową.
enum TacticalActionState {
  /// Standardowa jazda w szyku.
  none,

  /// Atak z peletonu / zryw ucieczkowy (pulsująca czerwona ikona ognia / błyskawicy).
  attacking,

  /// Pomocnik osłaniający lidera drużyny od czołowego i bocznego wiatru (niebieska tarcza aero).
  shelteringLeader,

  /// Kontratak / pościg za ucieczką.
  chasingBreakaway,
}

/// Konfiguracja parametrów wyświetlania pływających etykiet kolarzy (Nameplates).
class RiderFloatingLabelsConfig {
  /// Czy etykiety są włączone.
  final bool enabled;

  /// Maksymalny dystans od kamery, do którego etykiety są renderowane [m].
  final double maxLabelDistanceMeters;

  /// Dystans pełnej szczegółowości (flaga + nazwisko + W/kg + ikona koszulki + ikona taktyczna) [m].
  final double fullDetailDistanceMeters;

  /// Czy etykieta kolarza gracza jest zawsze wyświetlana bez względu na dystans.
  final bool showPlayerRiderAlways;

  /// Czy etykieta zaznaczonego kolarza jest zawsze wyświetlana.
  final bool showSelectedRiderAlways;

  /// Czy wyświetlać odznaki koszulek liderów (żółta/zielona/grochy/biała).
  final bool showLeaderJerseys;

  /// Czy wyświetlać ikony akcji taktycznych (atak / tarcza osłony lidera).
  final bool showTacticalIcons;

  /// Czy wyświetlać pigułkę W/kg z barwnym kodem strefy mocy Coggana.
  final bool showWkgPill;

  /// Czy wyświetlać flagę kraju pochodzenia kolarza.
  final bool showCountryFlag;

  /// Wysokość unoszenia się znacznika nad podłożem / kaskiem kolarza [m].
  final double headOffsetMeters;

  /// Maksymalna liczba etykiet wyświetlanych jednocześnie w kadrze (ochrona przed tłokiem).
  final int maxLabelsOnScreen;

  /// Wartość FTP [W] używana do wyznaczania 7 stref mocy Coggana (Z1-Z7).
  final int ftpWatts;

  const RiderFloatingLabelsConfig({
    this.enabled = true,
    this.maxLabelDistanceMeters = 55.0,
    this.fullDetailDistanceMeters = 32.0,
    this.showPlayerRiderAlways = true,
    this.showSelectedRiderAlways = true,
    this.showLeaderJerseys = true,
    this.showTacticalIcons = true,
    this.showWkgPill = true,
    this.showCountryFlag = true,
    this.headOffsetMeters = 1.95,
    this.maxLabelsOnScreen = 24,
    this.ftpWatts = 390,
  });
}

// =============================================================================
// 2. POMOCNIK FLAG PAŃSTWOWYCH I KRAJÓW POCHODZENIA
// =============================================================================

/// Konwerter kodów państw UCI / ISO na emotikony flag i 3-literowe kody.
class CountryFlagHelper {
  const CountryFlagHelper._();

  static const Map<String, (String emoji, String iso3)> _countryMap = {
    'SLO': ('🇸🇮', 'SLO'),
    'DEN': ('🇩🇰', 'DEN'),
    'POL': ('🇵🇱', 'POL'),
    'BEL': ('🇧🇪', 'BEL'),
    'NED': ('🇳🇱', 'NED'),
    'FRA': ('🇫🇷', 'FRA'),
    'ESP': ('🇪🇸', 'ESP'),
    'ITA': ('🇮🇹', 'ITA'),
    'GBR': ('🇬🇧', 'GBR'),
    'COL': ('🇨🇴', 'COL'),
    'USA': ('🇺🇸', 'USA'),
    'GER': ('🇩🇪', 'GER'),
    'AUS': ('🇦🇺', 'AUS'),
    'NOR': ('🇳🇴', 'NOR'),
    'SUI': ('🇨🇭', 'SUI'),
    'POR': ('🇵🇹', 'POR'),
    'ERI': ('🇪🇷', 'ERI'),
    'ECU': ('🇪🇨', 'ECU'),
    'KAZ': ('🇰🇿', 'KAZ'),
    'CAN': ('🇨🇦', 'CAN'),
    'NZL': ('🇳🇿', 'NZL'),
    'IRL': ('🇮🇪', 'IRL'),
    'AUT': ('🇦🇹', 'AUT'),
    'CZE': ('🇨🇿', 'CZE'),
    'SVK': ('🇸🇰', 'SVK'),
    'RSA': ('🇿🇦', 'RSA'),
  };

  /// Zwraca parę (emotikon flagi, 3-literowy kod ISO) dla zadanego kodu lub nazwiska kolarza.
  static (String emoji, String iso3) resolveCountry({
    String? explicitCountryIso,
    String? riderName,
  }) {
    if (explicitCountryIso != null) {
      final code = explicitCountryIso.toUpperCase().trim();
      final match = _countryMap[code];
      if (match != null) return match;
      if (code.length == 3) return ('🏳️', code);
    }

    if (riderName != null) {
      final lower = riderName.toLowerCase();
      if (lower.contains('pogacar') || lower.contains('pogačar') || lower.contains('roglic') || lower.contains('mohoric')) {
        return _countryMap['SLO']!;
      }
      if (lower.contains('vingegaard') || lower.contains('pedersen') || lower.contains('asgreen')) {
        return _countryMap['DEN']!;
      }
      if (lower.contains('majka') || lower.contains('kwiatkowski') || lower.contains('aniołkowski') || lower.contains('pol')) {
        return _countryMap['POL']!;
      }
      if (lower.contains('van aert') || lower.contains('evenepoel') || lower.contains('philipsen') || lower.contains('de lie')) {
        return _countryMap['BEL']!;
      }
      if (lower.contains('van der poel') || lower.contains('kooij') || lower.contains('groenewegen')) {
        return _countryMap['NED']!;
      }
      if (lower.contains('alaphilippe') || lower.contains('gaudu') || lower.contains('bardet') || lower.contains('madouas')) {
        return _countryMap['FRA']!;
      }
      if (lower.contains('rodriguez') || lower.contains('ayuso') || lower.contains('landa') || lower.contains('mas')) {
        return _countryMap['ESP']!;
      }
      if (lower.contains('ganna') || lower.contains('milan') || lower.contains('bettiol') || lower.contains('tiberi')) {
        return _countryMap['ITA']!;
      }
      if (lower.contains('pidcock') || lower.contains('yates') || lower.contains('thomas')) {
        return _countryMap['GBR']!;
      }
      if (lower.contains('bernal') || lower.contains('martinez') || lower.contains('buitrago')) {
        return _countryMap['COL']!;
      }
      if (lower.contains('kuss') || lower.contains('jorgenson') || lower.contains('mcnulty') || lower.contains('powless')) {
        return _countryMap['USA']!;
      }
      if (lower.contains('schachmann') || lower.contains('politt') || lower.contains('denz')) {
        return _countryMap['GER']!;
      }
      if (lower.contains('hindley') || lower.contains('matthews') || lower.contains('haig')) {
        return _countryMap['AUS']!;
      }
    }

    return ('🏳️', 'PRO');
  }
}

// =============================================================================
// 3. MODEL ROBOCZY POJEDYNCZEJ ETYKIETY (NAMEPLATE CANDIDATE)
// =============================================================================

class _EvaluatedRiderLabel {
  final PelotonRenderItem item;
  final double screenX;
  final double screenY;
  final double perspectiveScale;
  final double cameraDistance;
  final double alpha;
  final bool isPlayer;
  final bool isSelected;
  final bool isFullDetail;
  final LeaderJerseyType leaderJersey;
  final TacticalActionState tacticalState;
  final String flagEmoji;
  final String countryIso;
  final int cogganZone;
  final Color powerZoneColor;

  const _EvaluatedRiderLabel({
    required this.item,
    required this.screenX,
    required this.screenY,
    required this.perspectiveScale,
    required this.cameraDistance,
    required this.alpha,
    required this.isPlayer,
    required this.isSelected,
    required this.isFullDetail,
    required this.leaderJersey,
    required this.tacticalState,
    required this.flagEmoji,
    required this.countryIso,
    required this.cogganZone,
    required this.powerZoneColor,
  });
}

// =============================================================================
// 4. GŁÓWNY RENDERER PŁYWAJĄCYCH ETYKIET 3D (ZWIFT NAMEPLATES OVERLAY)
// =============================================================================

/// Warstwa rysująca minimalistyczne znaczniki w przestrzeni 3D nad kolarzami
/// w stylu Zwift / MyWhoosh / Pro Cycling Manager.
///
/// Funkcjonalności:
/// 1. Nazwisko kolarza i numer startowy,
/// 2. Flaga kraju pochodzenia (np. 🇸🇮 SLO, 🇩🇰 DEN, 🇵🇱 POL),
/// 3. Aktualne W/kg z barwną pigułką według 7 stref mocy Coggana (Z1 - Z7),
/// 4. Odznaka koszulki lidera (żółta GC, zielona sprinterska, w grochy KOM, biała U25),
/// 5. Pulsująca czerwona ikona ataku / zrywu ucieczkowego,
/// 6. Niebieska ikona tarczy, gdy pomocnik osłania lidera od wiatru (aero shelter),
/// 7. Sortowanie głębokości (Painter's algorithm Back-to-Front) oraz antykolizyjne
///    schodkowanie wysokości, eliminujące zlanie się etykiet w peletonie.
class RiderFloatingLabelsOverlay {
  final RiderFloatingLabelsConfig config;

  // Prealokowane obiekty farb malarskich (Zero-GC 120 FPS performance)
  late final Paint _bgPaint;
  late final Paint _borderPaint;
  late final Paint _shadowPaint;
  late final Paint _wkgPillPaint;
  late final Paint _pointerPaint;
  late final Paint _pulseGlowPaint;
  late final Paint _badgePaint;
  late final Paint _polkaDotPaint;

  RiderFloatingLabelsOverlay({
    this.config = const RiderFloatingLabelsConfig(),
  }) {
    _initPaints();
  }

  void _initPaints() {
    _bgPaint = Paint()..style = PaintingStyle.fill;
    _borderPaint = Paint()..style = PaintingStyle.stroke;
    _shadowPaint = Paint()
      ..color = const Color(0x99000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    _wkgPillPaint = Paint()..style = PaintingStyle.fill;

    _pointerPaint = Paint()..style = PaintingStyle.fill;

    _pulseGlowPaint = Paint()..style = PaintingStyle.fill;

    _badgePaint = Paint()..style = PaintingStyle.fill;

    _polkaDotPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
  }

  // ===========================================================================
  // 5. GŁÓWNA METODA RENDEROWANIA WARSTWY NA CANVAS
  // ===========================================================================

  /// Rysuje warstwę etykiet unoszących się w przestrzeni 3D nad kolarzami peletonu.
  void renderFloatingLabels({
    required Canvas canvas,
    required Size size,
    required Scene3DMathProjection projection,
    required List<PelotonRenderItem> renderItems,
    String? selectedRiderId,
    List<String> playerRiderIds = const [],
    Map<String, LeaderJerseyType> leaderJerseys = const {},
    Map<String, String> riderNationalities = const {},
    double animSeconds = 0.0,
  }) {
    if (!config.enabled || renderItems.isEmpty) return;

    // Krok 1: Filtrowanie i rzutowanie 3D pozycji głów kolarzy na ekran
    final candidates = <_EvaluatedRiderLabel>[];
    final Vector3 headOffsetWorld = Vector3(0.0, config.headOffsetMeters, 0.0);

    for (final item in renderItems) {
      final riderId = item.snapshot.riderId;
      final bool isPlayer = item.snapshot.isPlayerRider || playerRiderIds.contains(riderId);
      final bool isSelected = riderId == selectedRiderId;
      final double dist = item.cameraDistance;

      // Selekcja widoczności: kolarz gracza i zaznaczony są zawsze widoczni;
      // pozostali kolarze wyświetlają etykiety do maxLabelDistanceMeters
      if (!isPlayer && !isSelected && dist > config.maxLabelDistanceMeters) {
        continue;
      }

      // Rzutowanie punktu nad głową kolarza na ekran 2D
      final worldHead = item.worldPosition + headOffsetWorld;
      final proj = projection.worldToScreen(worldHead);

      if (!proj.isInFrontOfCamera || !proj.isInViewport) {
        continue;
      }

      // Obliczenie współczynnika zanikania z odległością (Alpha Fade)
      double alpha = 1.0;
      if (!isPlayer && !isSelected) {
        if (dist > config.fullDetailDistanceMeters) {
          final fadeLen = math.max(1.0, config.maxLabelDistanceMeters - config.fullDetailDistanceMeters);
          alpha = (1.0 - ((dist - config.fullDetailDistanceMeters) / fadeLen)).clamp(0.0, 1.0);
        }
      }

      if (alpha <= 0.05) continue;

      // Wyznaczenie koszulki lidera
      final jersey = leaderJerseys[riderId] ?? _inferLeaderJersey(item.snapshot);

      // Wyznaczenie stanu taktycznego (atak vs tarcza pomocnika)
      final tacticalState = _inferTacticalState(item.snapshot, isPlayer);

      // Wyznaczenie narodowości
      final (flagEmoji, countryIso) = CountryFlagHelper.resolveCountry(
        explicitCountryIso: riderNationalities[riderId],
        riderName: item.snapshot.riderName,
      );

      // Wyznaczenie strefy mocy Coggana (Z1 - Z7)
      final int zone = _calculateCogganZone(item.snapshot.powerWatts, config.ftpWatts);
      final Color zoneColor = AppColors.getPowerZoneColor(zone);

      final bool isFullDetail = isPlayer || isSelected || dist <= config.fullDetailDistanceMeters || jersey.isLeader || tacticalState == TacticalActionState.attacking;

      candidates.add(_EvaluatedRiderLabel(
        item: item,
        screenX: proj.screenX,
        screenY: proj.screenY,
        perspectiveScale: proj.perspectiveScale,
        cameraDistance: dist,
        alpha: alpha,
        isPlayer: isPlayer,
        isSelected: isSelected,
        isFullDetail: isFullDetail,
        leaderJersey: jersey,
        tacticalState: tacticalState,
        flagEmoji: flagEmoji,
        countryIso: countryIso,
        cogganZone: zone,
        powerZoneColor: zoneColor,
      ));
    }

    if (candidates.isEmpty) return;

    // Krok 2: Ograniczenie liczby etykiet do maxLabelsOnScreen z priorytetem dla gracza i liderów
    if (candidates.length > config.maxLabelsOnScreen) {
      candidates.sort((a, b) {
        // Najwyższy priorytet: Gracz i Wybrany
        if (a.isPlayer != b.isPlayer) return a.isPlayer ? -1 : 1;
        if (a.isSelected != b.isSelected) return a.isSelected ? -1 : 1;
        // Drugi priorytet: Liderzy koszulek i Atakujący
        if (a.leaderJersey.isLeader != b.leaderJersey.isLeader) {
          return a.leaderJersey.isLeader ? -1 : 1;
        }
        if ((a.tacticalState == TacticalActionState.attacking) != (b.tacticalState == TacticalActionState.attacking)) {
          return a.tacticalState == TacticalActionState.attacking ? -1 : 1;
        }
        // Trzeci priorytet: Odległość od kamery
        return a.cameraDistance.compareTo(b.cameraDistance);
      });
      candidates.removeRange(config.maxLabelsOnScreen, candidates.length);
    }

    // Krok 3: Sortowanie głębokości Painter's Algorithm: od najdalszych do najbliższych
    // Dzięki temu etykiety kolarzy na pierwszym planie rysują się NA WIERZCHU etykiet w tle
    candidates.sort((a, b) => b.cameraDistance.compareTo(a.cameraDistance));

    // Krok 4: Rysowanie poszczególnych etykiet Nameplates
    for (final label in candidates) {
      _drawSingleNameplate(
        canvas: canvas,
        label: label,
        animSeconds: animSeconds,
      );
    }
  }

  // ===========================================================================
  // 6. RYSOWANIE POJEDYNCZEGO ZNACZNIKA (NAMEPLATE)
  // ===========================================================================

  void _drawSingleNameplate({
    required Canvas canvas,
    required _EvaluatedRiderLabel label,
    required double animSeconds,
  }) {
    // Skalowanie perspektywiczne: bliżej kamery etykieta jest nieco większa, ale ograniczona do czytelnych granic
    final double scale = (label.perspectiveScale * 15.5).clamp(0.65, 1.25);
    final double alpha = label.alpha;

    // 1. Pomiary tekstów i komponentów etykiety
    final String displayName = _formatSurname(label.item.snapshot.riderName);
    final String wkgText = '${label.item.snapshot.wattsPerKg.toStringAsFixed(1)} w/kg';

    const textDirection = TextDirection.ltr;

    // Nazwisko kolarza
    final namePainter = TextPainter(
      text: TextSpan(
        text: displayName,
        style: TextStyle(
          color: label.isPlayer
              ? const Color(0xFFFFD700)
              : label.isSelected
                  ? const Color(0xFF38BDF8)
                  : Colors.white.withValues(alpha: alpha),
          fontSize: (10.0 * scale).clamp(8.0, 13.0),
          fontWeight: (label.isPlayer || label.isSelected) ? FontWeight.w900 : FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: textDirection,
    )..layout();

    // Flaga państwa (jeśli aktywna)
    TextPainter? flagPainter;
    if (config.showCountryFlag && label.isFullDetail) {
      flagPainter = TextPainter(
        text: TextSpan(
          text: label.flagEmoji,
          style: TextStyle(
            fontSize: (11.0 * scale).clamp(9.0, 14.0),
          ),
        ),
        textDirection: textDirection,
      )..layout();
    }

    // W/kg
    TextPainter? wkgPainter;
    if (config.showWkgPill) {
      wkgPainter = TextPainter(
        text: TextSpan(
          text: wkgText,
          style: TextStyle(
            color: Colors.white.withValues(alpha: alpha),
            fontSize: (8.5 * scale).clamp(7.0, 11.0),
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: textDirection,
      )..layout();
    }

    // 2. Obliczenie szerokości i wysokości etykiety
    final double padX = 7.0 * scale;
    final double itemSpacing = 5.0 * scale;

    double contentWidth = namePainter.width;

    if (flagPainter != null) {
      contentWidth += flagPainter.width + itemSpacing;
    }

    // Odznaka koszulki lidera
    final bool hasLeaderBadge = config.showLeaderJerseys && label.leaderJersey.isLeader;
    final double badgeSize = 13.0 * scale;
    if (hasLeaderBadge) {
      contentWidth += badgeSize + itemSpacing;
    }

    // Ikona akcji taktycznej (atak / tarcza osłony)
    final bool hasTacticalIcon = config.showTacticalIcons && label.tacticalState != TacticalActionState.none;
    final double tacticalIconSize = 13.0 * scale;
    if (hasTacticalIcon) {
      contentWidth += tacticalIconSize + itemSpacing;
    }

    // Pigułka W/kg
    double wkgPillWidth = 0.0;
    if (wkgPainter != null) {
      wkgPillWidth = wkgPainter.width + (8.0 * scale);
      contentWidth += (itemSpacing * 1.5) + wkgPillWidth;
    }

    final double totalPlateWidth = contentWidth + (padX * 2.0);
    final double totalPlateHeight = (18.0 * scale).clamp(14.0, 24.0);

    // Pozycja środka etykiety nad kaskiem kolarza
    final double plateCenterX = label.screenX;
    final double pointerHeight = 4.5 * scale;
    final double plateCenterY = label.screenY - (totalPlateHeight * 0.5) - pointerHeight - (2.0 * scale);

    final plateRect = Rect.fromCenter(
      center: Offset(plateCenterX, plateCenterY),
      width: totalPlateWidth,
      height: totalPlateHeight,
    );

    final plateRRect = RRect.fromRectAndRadius(
      plateRect,
      Radius.circular(6.0 * scale),
    );

    // 3. Rysowanie cienia
    canvas.drawRRect(plateRRect.shift(Offset(0, 2.5 * scale)), _shadowPaint);

    // 4. Rysowanie tła etykiety
    _bgPaint.color = const Color(0xFF0C101A).withValues(alpha: 0.90 * alpha);
    canvas.drawRRect(plateRRect, _bgPaint);

    // 5. Rysowanie ramki (Złota dla gracza, błękitna dla wybranego, czerwona dla ataku, standardowa stalowa)
    Color borderColor = const Color(0xFF1E293B).withValues(alpha: alpha);
    double borderWidth = 1.0;

    if (label.isPlayer) {
      borderColor = const Color(0xFFFFD700).withValues(alpha: 0.95 * alpha);
      borderWidth = 1.6;
    } else if (label.isSelected) {
      borderColor = const Color(0xFF38BDF8).withValues(alpha: 0.95 * alpha);
      borderWidth = 1.6;
    } else if (label.tacticalState == TacticalActionState.attacking) {
      // Pulsująca ramka podczas ataku
      final pulse = (0.5 + 0.5 * math.sin(animSeconds * 9.0));
      borderColor = Color.lerp(const Color(0xFFEF4444), const Color(0xFFFBBF24), pulse)!;
      borderWidth = 1.5;
    }

    _borderPaint
      ..color = borderColor
      ..strokeWidth = borderWidth;
    canvas.drawRRect(plateRRect, _borderPaint);

    // 6. Rysowanie dolnego wskaźnika (Pointer Chevron) skierowanego w stronę głowy kolarza
    _drawPointerChevron(
      canvas: canvas,
      centerX: plateCenterX,
      bottomY: plateRect.bottom,
      pointerHeight: pointerHeight,
      fillColor: _bgPaint.color,
      borderColor: borderColor,
    );

    // 7. Układanie komponentów wewnątrz etykiety od lewej do prawej
    double currentX = plateRect.left + padX;
    final double centerY = plateRect.center.dy;

    // A. Flaga kraju
    if (flagPainter != null) {
      flagPainter.paint(
        canvas,
        Offset(currentX, centerY - (flagPainter.height * 0.5)),
      );
      currentX += flagPainter.width + itemSpacing;
    }

    // B. Nazwisko kolarza
    namePainter.paint(
      canvas,
      Offset(currentX, centerY - (namePainter.height * 0.5)),
    );
    currentX += namePainter.width + itemSpacing;

    // C. Odznaka koszulki lidera (Żółta, Zielona, w Grochy, Biała)
    if (hasLeaderBadge) {
      _drawLeaderJerseyBadge(
        canvas: canvas,
        center: Offset(currentX + (badgeSize * 0.5), centerY),
        size: badgeSize,
        type: label.leaderJersey,
        scale: scale,
      );
      currentX += badgeSize + itemSpacing;
    }

    // D. Ikona akcji taktycznej (Pulsujący atak / Niebieska tarcza)
    if (hasTacticalIcon) {
      _drawTacticalActionIcon(
        canvas: canvas,
        center: Offset(currentX + (tacticalIconSize * 0.5), centerY),
        size: tacticalIconSize,
        state: label.tacticalState,
        animSeconds: animSeconds,
        scale: scale,
      );
      currentX += tacticalIconSize + itemSpacing;
    }

    // E. Pigułka W/kg
    if (wkgPainter != null) {
      final wkgRect = Rect.fromCenter(
        center: Offset(currentX + (wkgPillWidth * 0.5), centerY),
        width: wkgPillWidth,
        height: totalPlateHeight - (5.0 * scale),
      );

      _wkgPillPaint.color = label.powerZoneColor.withValues(alpha: 0.90 * alpha);
      canvas.drawRRect(
        RRect.fromRectAndRadius(wkgRect, Radius.circular(4.0 * scale)),
        _wkgPillPaint,
      );

      wkgPainter.paint(
        canvas,
        Offset(
          wkgRect.center.dx - (wkgPainter.width * 0.5),
          wkgRect.center.dy - (wkgPainter.height * 0.5),
        ),
      );
    }
  }

  // ===========================================================================
  // 7. RYSOWANIE KOSZULEK LIDERA (GC, SPRINT, KOM, U25)
  // ===========================================================================

  void _drawLeaderJerseyBadge({
    required Canvas canvas,
    required Offset center,
    required double size,
    required LeaderJerseyType type,
    required double scale,
  }) {
    final double radius = size * 0.5;

    // Tło odznaki koszulki
    _badgePaint.color = type.primaryColor;
    canvas.drawCircle(center, radius, _badgePaint);

    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, radius, borderPaint);

    if (type == LeaderJerseyType.polkaDotKOM) {
      // Czerwone grochy na białej koszulce górala (Polka Dots)
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

      final dotR = 1.4 * scale;
      canvas.drawCircle(center + Offset(-dotR * 1.5, -dotR * 1.2), dotR, _polkaDotPaint);
      canvas.drawCircle(center + Offset(dotR * 1.5, -dotR * 1.2), dotR, _polkaDotPaint);
      canvas.drawCircle(center + Offset(0, dotR * 1.2), dotR, _polkaDotPaint);
      canvas.drawCircle(center, dotR * 0.9, _polkaDotPaint);

      canvas.restore();
    } else {
      // Litera / skrót na koszulce (np. 'GC', 'S', 'U')
      final text = type == LeaderJerseyType.yellowGC
          ? 'GC'
          : type == LeaderJerseyType.greenPoints
              ? 'S'
              : 'Y';

      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: type == LeaderJerseyType.yellowGC ? Colors.black : Colors.white,
            fontSize: (7.5 * scale).clamp(6.0, 9.5),
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(center.dx - tp.width * 0.5, center.dy - tp.height * 0.5));
    }
  }

  // ===========================================================================
  // 8. RYSOWANIE IKON TAKTYCZNYCH (ATAK / TARCZA OSŁONY)
  // ===========================================================================

  void _drawTacticalActionIcon({
    required Canvas canvas,
    required Offset center,
    required double size,
    required TacticalActionState state,
    required double animSeconds,
    required double scale,
  }) {
    if (state == TacticalActionState.attacking) {
      // Pulsująca czerwona ikona ataku / zrywu
      final double pulse = (0.5 + 0.5 * math.sin(animSeconds * 9.0));
      final double r = (size * 0.48) * (0.92 + 0.16 * pulse);

      // Poświata wyładowania ataku
      _pulseGlowPaint
        ..color = const Color(0xFFEF4444).withValues(alpha: 0.45 * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 * scale);
      canvas.drawCircle(center, r + (2.0 * scale), _pulseGlowPaint);
      _pulseGlowPaint.maskFilter = null;

      // Czerwona tarcza kołowa
      _badgePaint.color = const Color(0xFFDC2626);
      canvas.drawCircle(center, r, _badgePaint);

      // Stylizowany płomień / błyskawica ataku (Path)
      final flamePath = Path()
        ..moveTo(center.dx, center.dy - (r * 0.65))
        ..lineTo(center.dx + (r * 0.50), center.dy + (r * 0.55))
        ..lineTo(center.dx + (r * 0.05), center.dy + (r * 0.15))
        ..lineTo(center.dx + (r * 0.15), center.dy + (r * 0.70))
        ..lineTo(center.dx - (r * 0.50), center.dy - (r * 0.15))
        ..lineTo(center.dx - (r * 0.05), center.dy + (r * 0.05))
        ..close();

      final flamePaint = Paint()
        ..color = const Color(0xFFFFFBEB)
        ..style = PaintingStyle.fill;
      canvas.drawPath(flamePath, flamePaint);
    } else if (state == TacticalActionState.shelteringLeader) {
      // Niebieska ikona tarczy, gdy pomocnik osłania lidera od wiatru (Aero Shield)
      final double r = size * 0.48;

      // Półprzezroczysta niebieska poświata
      _pulseGlowPaint
        ..color = const Color(0xFF0284C7).withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0 * scale);
      canvas.drawCircle(center, r + (1.5 * scale), _pulseGlowPaint);
      _pulseGlowPaint.maskFilter = null;

      // Kształt tarczy rycerskiej (Shield Path)
      final shieldPath = Path()
        ..moveTo(center.dx - (r * 0.65), center.dy - (r * 0.65))
        ..lineTo(center.dx + (r * 0.65), center.dy - (r * 0.65))
        ..lineTo(center.dx + (r * 0.65), center.dy)
        ..quadraticBezierTo(
          center.dx + (r * 0.55),
          center.dy + (r * 0.65),
          center.dx,
          center.dy + (r * 0.85),
        )
        ..quadraticBezierTo(
          center.dx - (r * 0.55),
          center.dy + (r * 0.65),
          center.dx - (r * 0.65),
          center.dy,
        )
        ..close();

      _badgePaint.color = const Color(0xFF0284C7);
      canvas.drawPath(shieldPath, _badgePaint);

      // Wewnętrzny obrys strugi wiatru na tarczy
      final strokePaint = Paint()
        ..color = const Color(0xFFBAE6FD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(shieldPath, strokePaint);
    }
  }

  // ===========================================================================
  // 9. RYSOWANIE WSKAŹNIKA CHEVRON (STRZAŁKI WSKAZUJĄCEJ GŁOWĘ KOLARZA)
  // ===========================================================================

  void _drawPointerChevron({
    required Canvas canvas,
    required double centerX,
    required double bottomY,
    required double pointerHeight,
    required Color fillColor,
    required Color borderColor,
  }) {
    final double halfW = pointerHeight * 0.85;

    final path = Path()
      ..moveTo(centerX - halfW, bottomY - 0.5)
      ..lineTo(centerX + halfW, bottomY - 0.5)
      ..lineTo(centerX, bottomY + pointerHeight)
      ..close();

    _pointerPaint.color = fillColor;
    canvas.drawPath(path, _pointerPaint);

    final linePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(centerX - halfW, bottomY), Offset(centerX, bottomY + pointerHeight), linePaint);
    canvas.drawLine(Offset(centerX + halfW, bottomY), Offset(centerX, bottomY + pointerHeight), linePaint);
  }

  // ===========================================================================
  // 10. HEURYSTYKI I WNIOSKOWANIE O STANIE KOLARZA
  // ===========================================================================

  LeaderJerseyType _inferLeaderJersey(RiderPositionSnapshot snapshot) {
    if (snapshot.bibNumber == 1) return LeaderJerseyType.yellowGC;
    if (snapshot.bibNumber == 21) return LeaderJerseyType.greenPoints;
    if (snapshot.bibNumber == 31) return LeaderJerseyType.polkaDotKOM;
    return LeaderJerseyType.none;
  }

  TacticalActionState _inferTacticalState(RiderPositionSnapshot snapshot, bool isPlayer) {
    // 1. Atak
    if (snapshot.activeTacticalOrder == TacticalOrder.attack ||
        (snapshot.isPulling && snapshot.powerWatts > 460) ||
        snapshot.wattsPerKg > 6.8) {
      return TacticalActionState.attacking;
    }

    // 2. Tarcza osłony lidera od wiatru
    if (snapshot.activeTacticalOrder == TacticalOrder.protectLeader ||
        (snapshot.isPulling && !isPlayer)) {
      return TacticalActionState.shelteringLeader;
    }

    return TacticalActionState.none;
  }

  int _calculateCogganZone(int powerWatts, int ftpWatts) {
    if (ftpWatts <= 0) return 1;
    final double pct = (powerWatts / ftpWatts) * 100.0;
    if (pct < 55.0) return 1;
    if (pct < 75.0) return 2;
    if (pct < 90.0) return 3;
    if (pct < 105.0) return 4;
    if (pct < 120.0) return 5;
    if (pct < 150.0) return 6;
    return 7;
  }

  String _formatSurname(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length > 1) {
      final initial = parts.first.isNotEmpty ? '${parts.first[0]}. ' : '';
      return '$initial${parts.sublist(1).join(' ')}';
    }
    return fullName;
  }
}
