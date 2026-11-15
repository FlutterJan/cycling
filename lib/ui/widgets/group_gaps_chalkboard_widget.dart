// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/peloton/drafting_grid_system.dart';
import '../../state/race_simulation_notifier.dart';

/// Kierunek trendu różnicy czasowej (Time Gap Trend).
enum GapTrend {
  /// Przewaga ucieczki rośnie (peleton traci dystans / odpuszcza pościg).
  growing,

  /// Przewaga topnieje (peleton mocno goni i odrabia straty).
  shrinking,

  /// Przewaga jest ustabilizowana (różnica nie ulega istotnym zmianom).
  stable;

  /// Kredowy symbol trendu czasowego.
  String get symbol {
    switch (this) {
      case GapTrend.growing:
        return '▲';
      case GapTrend.shrinking:
        return '▼';
      case GapTrend.stable:
        return '—';
    }
  }

  /// Kolor wskaźnika trendu.
  Color get color {
    switch (this) {
      case GapTrend.growing:
        return const Color(0xFF10B981); // Zielony - przewaga rośnie
      case GapTrend.shrinking:
        return const Color(0xFFEF4444); // Czerwony - strata maleje / ucieczka łapana
      case GapTrend.stable:
        return const Color(0xFFF59E0B); // Żółty - tempo wyrównane
    }
  }

  /// Czytelna etykieta tekstowa.
  String get label {
    switch (this) {
      case GapTrend.growing:
        return 'Rośnie';
      case GapTrend.shrinking:
        return 'Topnieje';
      case GapTrend.stable:
        return 'Stała';
    }
  }
}

/// Model pojedynczej grupy kolarzy prezentowanej na Tablicy Motocyklisty (Ardoisier Board).
class ChalkboardGroup {
  final String id;

  /// Typ taktyczny formacji (Ucieczka, Kontra, Peleton, Grupetto, Solo).
  final GroupType type;

  /// Nazwa grupy w tradycyjnej terminologii kolarskiej (np. "Tête de la Course", "Poursuivants").
  final String title;

  /// Liczba zawodników znajdujących się w tej grupie.
  final int riderCount;

  /// Różnica czasowa do lidera wyścigu w sekundach [s] (0.0 dla czoła wyścigu).
  final double gapToLeaderSeconds;

  /// Opcjonalna różnica czasowa do grupy jadącej bezpośrednio przed nią [s].
  final double? gapToPreviousGroupSeconds;

  /// Trend czasowy przewagi (rośnie, maleje, stabilna).
  final GapTrend trend;

  /// Zmiana różnicy czasowej w sekundach na kilometr [s/km] (np. +3.5 s/km, -7.2 s/km).
  final double gapChangeSecondsPerKm;

  /// Imię i nazwisko kolarza nadającego aktualnie tempo na czele formacji.
  final String? pacemakerName;

  /// Kod lub nazwa zespołu kolarza nadającego tempo (np. "UAE", "Visma", "Ineos").
  final String? pacemakerTeamCode;

  /// Kolor koszulki pacemakera w formacie hex (np. "#D4AF37").
  final String? pacemakerTeamJerseyHex;

  /// Czy w tej grupie jedzie zawodnik drużyny gracza.
  final bool hasPlayerRider;

  /// Nazwiska zawodników drużyny gracza jadących w tej grupie.
  final List<String> playerRiderNames;

  /// Pełna lista nazwisk kolarzy w grupie (do rozwijanego podglądu).
  final List<String> allRiderNames;

  /// Średnia aktualna prędkość grupy w km/h.
  final double speedKmh;

  /// Pozycja kilometrowa grupy na trasie etapu [km].
  final double distanceCoveredKm;

  const ChalkboardGroup({
    required this.id,
    required this.type,
    required this.title,
    required this.riderCount,
    this.gapToLeaderSeconds = 0.0,
    this.gapToPreviousGroupSeconds,
    this.trend = GapTrend.stable,
    this.gapChangeSecondsPerKm = 0.0,
    this.pacemakerName,
    this.pacemakerTeamCode,
    this.pacemakerTeamJerseyHex,
    this.hasPlayerRider = false,
    this.playerRiderNames = const [],
    this.allRiderNames = const [],
    this.speedKmh = 42.0,
    this.distanceCoveredKm = 0.0,
  });

  /// Czy jest to grupa prowadząca wyścig (Tête de la Course / Lider).
  bool get isRaceLeader => gapToLeaderSeconds <= 0.01;

  /// Sformatowany napis straty czasowej do czoła wyścigu (np. "LIDER", "+1'45\"", "+12'30\"").
  String get formattedGapToLeader {
    if (isRaceLeader) {
      return 'LIDER';
    }
    final int totalSec = gapToLeaderSeconds.round();
    final int minutes = totalSec ~/ 60;
    final int seconds = totalSec % 60;
    if (minutes >= 60) {
      final int hours = minutes ~/ 60;
      final int remMin = minutes % 60;
      return "+${hours}h ${remMin.toString().padLeft(2, '0')}'";
    }
    return "+$minutes'${seconds.toString().padLeft(2, '0')}\"";
  }

  /// Sformatowany napis różnicy czasowej do poprzedzającej grupy.
  String get formattedGapToPrevious {
    if (isRaceLeader || gapToPreviousGroupSeconds == null) {
      return '0"';
    }
    final int totalSec = gapToPreviousGroupSeconds!.round();
    final int minutes = totalSec ~/ 60;
    final int seconds = totalSec % 60;
    return "+$minutes'${seconds.toString().padLeft(2, '0')}\"";
  }

  /// Sformatowana zmiana tempa na kilometr (np. "+4.2s/km" lub "-8.1s/km").
  String get formattedTrendRate {
    if (trend == GapTrend.stable || gapChangeSecondsPerKm.abs() < 0.1) {
      return 'tempo równe';
    }
    final sign = gapChangeSecondsPerKm > 0 ? '+' : '';
    return '$sign${gapChangeSecondsPerKm.toStringAsFixed(1)}s/km';
  }

  /// Fabryka demonstracyjna do podglądu i testów widgetu.
  static List<ChalkboardGroup> demoGroups() {
    return const [
      ChalkboardGroup(
        id: 'group_breakaway',
        type: GroupType.breakaway,
        title: 'Tête de la Course (Ucieczka)',
        riderCount: 4,
        gapToLeaderSeconds: 0.0,
        trend: GapTrend.growing,
        gapChangeSecondsPerKm: 3.5,
        pacemakerName: 'R. Majka',
        pacemakerTeamCode: 'UAD',
        pacemakerTeamJerseyHex: '#D4AF37',
        hasPlayerRider: true,
        playerRiderNames: ['R. Majka'],
        allRiderNames: ['R. Majka', 'K. Neilands', 'M. Cort', 'N. Politt'],
        speedKmh: 45.2,
        distanceCoveredKm: 135.2,
      ),
      ChalkboardGroup(
        id: 'group_chase',
        type: GroupType.chaseGroup,
        title: 'Poursuivants (Kontra)',
        riderCount: 2,
        gapToLeaderSeconds: 42.0,
        gapToPreviousGroupSeconds: 42.0,
        trend: GapTrend.shrinking,
        gapChangeSecondsPerKm: -4.5,
        pacemakerName: 'W. Van Aert',
        pacemakerTeamCode: 'TVL',
        pacemakerTeamJerseyHex: '#F59E0B',
        hasPlayerRider: false,
        allRiderNames: ['W. Van Aert', 'M. Mohoric'],
        speedKmh: 46.8,
        distanceCoveredKm: 134.7,
      ),
      ChalkboardGroup(
        id: 'group_peloton',
        type: GroupType.peloton,
        title: 'Peloton Principal',
        riderCount: 124,
        gapToLeaderSeconds: 135.0,
        gapToPreviousGroupSeconds: 93.0,
        trend: GapTrend.shrinking,
        gapChangeSecondsPerKm: -7.8,
        pacemakerName: 'J. Castroviejo',
        pacemakerTeamCode: 'IGD',
        pacemakerTeamJerseyHex: '#DC2626',
        hasPlayerRider: true,
        playerRiderNames: ['T. Pogačar', 'P. Sivakov'],
        allRiderNames: ['J. Castroviejo', 'M. Kwiatkowski', 'T. Pogačar', 'J. Vingegaard', 'R. Evenepoel'],
        speedKmh: 47.5,
        distanceCoveredKm: 133.6,
      ),
      ChalkboardGroup(
        id: 'group_grupetto',
        type: GroupType.grupetto,
        title: 'Grupetto (Autobus)',
        riderCount: 28,
        gapToLeaderSeconds: 760.0,
        gapToPreviousGroupSeconds: 625.0,
        trend: GapTrend.growing,
        gapChangeSecondsPerKm: 12.0,
        pacemakerName: 'M. Cavendish',
        pacemakerTeamCode: 'AST',
        pacemakerTeamJerseyHex: '#0284C7',
        hasPlayerRider: false,
        allRiderNames: ['M. Cavendish', 'F. Jakobsen', 'C. Ewan', 'D. Groenewegen'],
        speedKmh: 37.8,
        distanceCoveredKm: 126.5,
      ),
    ];
  }
}

/// Klasyczny kolarski widget "Tablicy Motocyklisty" (Ardoisier / Time Gaps Board).
///
/// Wyświetlany w górnej części ekranu wyścigu:
/// - Prezentuje ułożone kafelki wszystkich aktywnych grup (Ucieczka, Kontra, Peleton, Grupetto).
/// - Liczbę kolarzy w każdej grupie.
/// - Nazwisko i zespół kolarza dyktującego aktualnie tempo na czele.
/// - Precyzyjne różnice czasowe do lidera oraz trend (strzałka ▲/▼ pokazująca, czy przewaga rośnie, czy maleje).
/// - Złote wyróżnienie grup, w których jadą zawodnicy drużyny gracza.
class GroupGapsChalkboardWidget extends ConsumerStatefulWidget {
  /// Lista grup do wyświetlenia (jeśli null, pobiera stan dynamicznie z symulacji Riverpod).
  final List<ChalkboardGroup>? groups;

  /// Czy tablica może być zwijana przez użytkownika do kompaktowego paska.
  final bool isCollapsible;

  /// Czy początkowo tablica ma być zwinięta.
  final bool initiallyCollapsed;

  /// Callback wywoływany po kliknięciu na kafelek grupy (np. by wycentrować kamerę na tej grupie).
  final ValueChanged<ChalkboardGroup>? onGroupSelected;

  const GroupGapsChalkboardWidget({
    super.key,
    this.groups,
    this.isCollapsible = true,
    this.initiallyCollapsed = false,
    this.onGroupSelected,
  });

  @override
  ConsumerState<GroupGapsChalkboardWidget> createState() => _GroupGapsChalkboardWidgetState();
}

class _GroupGapsChalkboardWidgetState extends ConsumerState<GroupGapsChalkboardWidget> {
  late bool _isCollapsed;
  String? _selectedGroupId;

  // Autentyczna kolorystyka tablicy kredowej Ardoisier (Slate Blackboard)
  static const Color _chalkSlateBg = Color(0xFF141A17);
  static const Color _chalkBorderColor = Color(0x38FFFFFF);
  static const Color _chalkTextWhite = Color(0xFFFFFDF5);
  static const Color _chalkYellowAccent = Color(0xFFFFE600);

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.initiallyCollapsed;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Pobranie danych grup (albo przekazane jawnie, albo z Riverpod, albo demo)
    final activeGroups = widget.groups ?? _resolveGroupsFromRiverpod();

    if (activeGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _chalkSlateBg.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _chalkBorderColor, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Pasek nagłówka Ardoisier (Chalkboard Header)
          _buildChalkboardHeader(activeGroups),

          // 2. Poziomy rząd kafelków grup (jeśli tablica nie jest zwinięta)
          if (!_isCollapsed) ...[
            const Divider(color: _chalkBorderColor, height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: activeGroups.map((group) {
                    final bool isSelected = group.id == _selectedGroupId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildGroupChalkTile(group, isSelected),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Buduje górną listwę z tytułem "ARDOISIER • ÉCARTS" i przyciskiem zwijania.
  Widget _buildChalkboardHeader(List<ChalkboardGroup> groups) {
    final leaderGroup = groups.firstWhere((g) => g.isRaceLeader, orElse: () => groups.first);
    final pelotonGroup = groups.firstWhere((g) => g.type == GroupType.peloton, orElse: () => groups.last);

    return InkWell(
      onTap: widget.isCollapsible
          ? () {
              setState(() {
                _isCollapsed = !_isCollapsed;
              });
            }
          : null,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            // Ikona motocykla sędziowskiego / tablicy
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _chalkYellowAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _chalkYellowAccent.withValues(alpha: 0.5), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.two_wheeler_rounded, size: 14, color: _chalkYellowAccent),
                  SizedBox(width: 4),
                  Text(
                    'ARDOISIER',
                    style: TextStyle(
                      color: _chalkYellowAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Oficjalny napis z różnicami
            const Flexible(
              child: Text(
                'RÓŻNICE CZASOWE • TIME GAPS',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: _chalkTextWhite,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Szybki podgląd w trybie zwiniętym (np. "Ucieczka vs Peleton: 2'15" ▼")
            if (_isCollapsed) ...[
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${leaderGroup.title.split(' ').first} (${leaderGroup.riderCount}) vs Peleton: ',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          pelotonGroup.formattedGapToLeader,
                          style: const TextStyle(color: _chalkYellowAccent, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          pelotonGroup.trend.symbol,
                          style: TextStyle(
                            color: pelotonGroup.trend.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            if (widget.isCollapsible)
              Icon(
                _isCollapsed ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                size: 18,
                color: Colors.white70,
              ),
          ],
        ),
      ),
    );
  }

  /// Pojedynczy kredowy kafelek grupy kolarskiej na tablicy motocyklisty.
  Widget _buildGroupChalkTile(ChalkboardGroup group, bool isSelected) {
    final bool isLead = group.isRaceLeader;
    final bool isPlayerGroup = group.hasPlayerRider;

    // Styl obramowania (wyróżnienie zawodnika gracza złotym kolorem)
    final Border border = isPlayerGroup
        ? Border.all(color: AppColors.goldAccent, width: 1.8)
        : Border.all(
            color: isSelected ? AppColors.cyanAccent : const Color(0x33FFFFFF),
            width: isSelected ? 1.5 : 1.0,
          );

    final Color badgeBg = _resolveGroupBadgeColor(group.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedGroupId = group.id;
          });
          widget.onGroupSelected?.call(group);
          _showGroupDetailsModal(context, group);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 230,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isPlayerGroup
                ? const Color(0xFF24221A).withValues(alpha: 0.95)
                : const Color(0xFF1B231E).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(8),
            border: border,
            boxShadow: isPlayerGroup
                ? [
                    BoxShadow(
                      color: AppColors.goldAccent.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Linia 1: Typ grupy + Licznik kolarzy
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: badgeBg.withValues(alpha: 0.7), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_resolveGroupIcon(group.type), size: 10, color: badgeBg),
                        const SizedBox(width: 4),
                        Text(
                          _resolveGroupTypeName(group.type).toUpperCase(),
                          style: TextStyle(
                            color: badgeBg,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Liczba kolarzy w grupie
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Text(
                      '${group.riderCount} KOL.',
                      style: const TextStyle(
                        color: _chalkTextWhite,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Linia 2: Duża kredowa różnica czasowa i wskaźnik trendu
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      group.formattedGapToLeader,
                      style: TextStyle(
                        color: isLead ? _chalkYellowAccent : _chalkTextWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (!isLead) ...[
                      // Strzałka trendu i tempo
                      Text(
                        group.trend.symbol,
                        style: TextStyle(
                          color: group.trend.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        group.formattedTrendRate,
                        style: TextStyle(
                          color: group.trend.color,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 5),

              // Linia 3: Kto nadaje tempo na czele (Pacemaker)
              Row(
                children: [
                  const Icon(Icons.flash_on_rounded, size: 11, color: AppColors.cyanAccent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      group.pacemakerName != null
                          ? 'Czoło: ${group.pacemakerName} (${group.pacemakerTeamCode ?? "—"})'
                          : 'Śr. prędkość: ${group.speedKmh.toStringAsFixed(1)} km/h',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Linia 4: Wyróżnienie obecności kolarza gracza
              if (isPlayerGroup) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 10, color: AppColors.goldAccent),
                      const SizedBox(width: 3),
                      Text(
                        'Twój: ${group.playerRiderNames.isNotEmpty ? group.playerRiderNames.first : "Kolarz"}',
                        style: const TextStyle(
                          color: AppColors.goldAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Wyświetla modal z pełną listą zawodników w wybranej grupie.
  void _showGroupDetailsModal(BuildContext context, ChalkboardGroup group) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: const BoxConstraints(maxWidth: 550),
        decoration: BoxDecoration(
          color: const Color(0xFF0F121C).withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_resolveGroupIcon(group.type), color: _resolveGroupBadgeColor(group.type), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${group.riderCount} kolarzy',
                  style: const TextStyle(color: AppColors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Strata do lidera: ${group.formattedGapToLeader} • Prędkość: ${group.speedKmh.toStringAsFixed(1)} km/h • Trend: ${group.trend.label} (${group.formattedTrendRate})',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            const Divider(color: Color(0xFF262C3A), height: 20),
            const Text(
              'SKŁAD GRUPY:',
              style: TextStyle(color: AppColors.goldAccent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (group.allRiderNames.isNotEmpty
                      ? group.allRiderNames
                      : ['Kolarze grupy (${group.riderCount})'])
                  .map((name) {
                final isPlayer = group.playerRiderNames.contains(name);
                return Chip(
                  backgroundColor: isPlayer ? AppColors.goldAccent.withValues(alpha: 0.2) : const Color(0xFF1E2430),
                  side: BorderSide(color: isPlayer ? AppColors.goldAccent : Colors.white24, width: 1),
                  label: Text(
                    name,
                    style: TextStyle(
                      color: isPlayer ? AppColors.goldAccent : Colors.white,
                      fontSize: 11,
                      fontWeight: isPlayer ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Pomocnicze rozpoznawanie grup bezpośrednio ze stanu Riverpod.
  List<ChalkboardGroup> _resolveGroupsFromRiverpod() {
    try {
      final simState = ref.watch(raceSimulationProvider);
      final loopState = simState.simulationState;
      if (loopState == null || loopState.groups.isEmpty) {
        return ChalkboardGroup.demoGroups();
      }

      final playerRiderIds = loopState.playerRiderIds;
      final snapshotMap = {for (final s in simState.riderPositions) s.riderId: s};

      final groupsList = <ChalkboardGroup>[];

      for (int i = 0; i < loopState.groups.length; i++) {
        final g = loopState.groups[i];
        final bool hasPlayer = g.riderIds.any((id) => playerRiderIds.contains(id));
        final playerNames = g.riderIds
            .where((id) => playerRiderIds.contains(id))
            .map((id) => snapshotMap[id]?.riderName ?? 'Zawodnik')
            .toList();

        final allNames = g.riderIds.take(12).map((id) => snapshotMap[id]?.riderName ?? id).toList();

        final pacemakerId = g.pacemakerRiderIds.isNotEmpty ? g.pacemakerRiderIds.first : g.leadRiderId;
        final pacemakerSnapshot = pacemakerId != null ? snapshotMap[pacemakerId] : null;

        // Ustalenie trendu (dla ucieczki domyślnie porównanie do peletonu)
        GapTrend trend = GapTrend.stable;
        double gapChangeRate = 0.0;
        if (i == 0) {
          trend = GapTrend.stable;
        } else {
          // Jeśli średnia prędkość grupy jest wyższa od lidera, strata maleje
          final speedDiff = g.averageSpeedKmh - loopState.groups.first.averageSpeedKmh;
          if (speedDiff > 1.2) {
            trend = GapTrend.shrinking;
            gapChangeRate = -speedDiff * 1.5;
          } else if (speedDiff < -1.2) {
            trend = GapTrend.growing;
            gapChangeRate = -speedDiff * 1.5;
          }
        }

        groupsList.add(ChalkboardGroup(
          id: g.id,
          type: g.type,
          title: _resolveGroupTitle(g.type, i),
          riderCount: g.riderCount,
          gapToLeaderSeconds: g.gapToRaceLeaderSeconds,
          gapToPreviousGroupSeconds: i > 0
              ? math.max(0.0, g.gapToRaceLeaderSeconds - loopState.groups[i - 1].gapToRaceLeaderSeconds)
              : 0.0,
          trend: trend,
          gapChangeSecondsPerKm: gapChangeRate,
          pacemakerName: pacemakerSnapshot?.riderName,
          pacemakerTeamCode: pacemakerSnapshot?.teamName.split(' ').first,
          pacemakerTeamJerseyHex: pacemakerSnapshot?.teamJerseyHexColor,
          hasPlayerRider: hasPlayer,
          playerRiderNames: playerNames,
          allRiderNames: allNames,
          speedKmh: g.averageSpeedKmh,
          distanceCoveredKm: g.distanceCoveredKm,
        ));
      }

      return groupsList.isNotEmpty ? groupsList : ChalkboardGroup.demoGroups();
    } catch (_) {
      return ChalkboardGroup.demoGroups();
    }
  }

  String _resolveGroupTitle(GroupType type, int index) {
    switch (type) {
      case GroupType.solo:
        return 'Échappée Solitaire';
      case GroupType.breakaway:
        return index == 0 ? 'Tête de la Course' : 'Ucieczka G$index';
      case GroupType.chaseGroup:
        return 'Poursuivants (Kontra)';
      case GroupType.peloton:
        return 'Peloton Principal';
      case GroupType.grupetto:
        return 'Grupetto (Autobus)';
    }
  }

  String _resolveGroupTypeName(GroupType type) {
    switch (type) {
      case GroupType.solo:
        return 'Solo';
      case GroupType.breakaway:
        return 'Ucieczka';
      case GroupType.chaseGroup:
        return 'Kontra';
      case GroupType.peloton:
        return 'Peleton';
      case GroupType.grupetto:
        return 'Grupetto';
    }
  }

  Color _resolveGroupBadgeColor(GroupType type) {
    switch (type) {
      case GroupType.solo:
        return const Color(0xFFF97316); // Pomarańczowy
      case GroupType.breakaway:
        return const Color(0xFFFFD700); // Złoty
      case GroupType.chaseGroup:
        return const Color(0xFF38BDF8); // Błękitny
      case GroupType.peloton:
        return const Color(0xFF94A3B8); // Szary / slate
      case GroupType.grupetto:
        return const Color(0xFF10B981); // Zielony
    }
  }

  IconData _resolveGroupIcon(GroupType type) {
    switch (type) {
      case GroupType.solo:
        return Icons.person_rounded;
      case GroupType.breakaway:
        return Icons.whatshot_rounded;
      case GroupType.chaseGroup:
        return Icons.bolt_rounded;
      case GroupType.peloton:
        return Icons.groups_rounded;
      case GroupType.grupetto:
        return Icons.directions_bus_rounded;
    }
  }
}
