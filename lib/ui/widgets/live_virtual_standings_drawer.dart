// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Filtr widoku tabeli Wirtualnej Klasyfikacji Generalnej.
enum VirtualGcFilter {
  /// Czołówka klasyfikacji (Top 15)
  top15,

  /// Kolarze jadący obecnie w odjeździe / ucieczce
  breakawayOnly,

  /// Zawodnicy zespołu gracza
  myTeamOnly,

  /// Czołowi faworyci klasyfikacji generalnej (top GC contenders)
  gcContenders;

  String get label {
    switch (this) {
      case VirtualGcFilter.top15:
        return 'Top 15';
      case VirtualGcFilter.breakawayOnly:
        return 'Ucieczka';
      case VirtualGcFilter.myTeamOnly:
        return 'Mój Zespół';
      case VirtualGcFilter.gcContenders:
        return 'Faworyci GC';
    }
  }

  IconData get icon {
    switch (this) {
      case VirtualGcFilter.top15:
        return Icons.format_list_numbered_rounded;
      case VirtualGcFilter.breakawayOnly:
        return Icons.whatshot_rounded;
      case VirtualGcFilter.myTeamOnly:
        return Icons.star_rounded;
      case VirtualGcFilter.gcContenders:
        return Icons.military_tech_rounded;
    }
  }
}

/// Wpis pojedynczego kolarza w Wirtualnej Klasyfikacji Generalnej na żywo.
class VirtualGcRiderEntry {
  final String riderId;
  final String riderName;
  final String teamName;
  final String teamCode;
  final String countryIso;
  final int bibNumber;

  /// Oficjalna pozycja w klasyfikacji generalnej przed rozpoczęciem etapu
  final int preStageRank;

  /// Oficjalna strata do lidera GC przed startem etapu [s] (0.0 dla faktycznego lidera)
  final double preStageGapSeconds;

  /// Nazwa grupy, w której jedzie kolarz (np. "Ucieczka", "Peleton", "Kontra")
  final String roadGroupName;

  /// Różnica czasowa grupy kolarza względem peletonu [s]
  /// Wartość dodatnia = kolarz ma przewagę nad peletonem (np. +240s = 4 minuty przewagi ucieczki)
  /// Wartość 0.0 = kolarz jedzie w peletonie
  /// Wartość ujemna = kolarz traci do peletonu (np. -60s = urwany 1 minutę za peletonem)
  final double roadGapToPelotonSeconds;

  /// Wirtualny czas łączny (bazowy czas GC minus przewaga z ucieczki)
  final double virtualCumulativeSeconds;

  /// Wirtualna strata do aktualnego wirtualnego lidera [s] (0.0 dla wirtualnego lidera)
  final double virtualGapToLeaderSeconds;

  /// Aktualne wirtualne miejsce w wyścigu (1, 2, 3...)
  final int virtualRank;

  /// Awans / spadek w wirtualnej klasyfikacji w stosunku do początku etapu (np. +13 pozycji w górę)
  final int rankChange;

  /// Czy jest w tej sekundzie wirtualnym posiadaczem żółtej koszulki lidera (Maillot Jaune)
  final bool isVirtualYellowJersey;

  /// Czy jest oficjalnym posiadaczem żółtej koszulki przed startem etapu
  final bool isActualYellowJersey;

  /// Czy jest zawodnikiem drużyny gracza
  final bool isPlayerRider;

  /// Czy jest zaliczany do grona faworytów GC
  final bool isGcContender;

  const VirtualGcRiderEntry({
    required this.riderId,
    required this.riderName,
    required this.teamName,
    required this.teamCode,
    required this.countryIso,
    required this.bibNumber,
    required this.preStageRank,
    required this.preStageGapSeconds,
    required this.roadGroupName,
    required this.roadGapToPelotonSeconds,
    required this.virtualCumulativeSeconds,
    required this.virtualGapToLeaderSeconds,
    required this.virtualRank,
    required this.rankChange,
    required this.isVirtualYellowJersey,
    required this.isActualYellowJersey,
    this.isPlayerRider = false,
    this.isGcContender = false,
  });

  /// Sformatowany napis wirtualnej straty do wirtualnego lidera (np. "LIDER", "+0'45\"", "+3'12\"")
  String get formattedVirtualGap {
    if (isVirtualYellowJersey || virtualGapToLeaderSeconds <= 0.01) {
      return 'LIDER';
    }
    final int totalSec = virtualGapToLeaderSeconds.round();
    final int min = totalSec ~/ 60;
    final int sec = totalSec % 60;
    if (min >= 60) {
      final int hrs = min ~/ 60;
      final int remMin = min % 60;
      return "+${hrs}h ${remMin.toString().padLeft(2, '0')}'";
    }
    return "+$min'${sec.toString().padLeft(2, '0')}\"";
  }

  /// Sformatowany napis oficjalnej straty z początku etapu
  String get formattedPreStageGap {
    if (preStageGapSeconds <= 0.01) {
      return '0:00';
    }
    final int totalSec = preStageGapSeconds.round();
    final int min = totalSec ~/ 60;
    final int sec = totalSec % 60;
    return "+$min'${sec.toString().padLeft(2, '0')}\"";
  }

  /// Sformatowany napis przewagi na trasie względem peletonu
  String get formattedRoadGap {
    if (roadGapToPelotonSeconds.abs() <= 1.0) {
      return 'Peleton (0:00)';
    }
    final int totalSec = roadGapToPelotonSeconds.abs().round();
    final int min = totalSec ~/ 60;
    final int sec = totalSec % 60;
    final sign = roadGapToPelotonSeconds > 0 ? '+' : '-';
    return "$sign$min'${sec.toString().padLeft(2, '0')}\"";
  }

  /// Kopia obiektu z aktualizacją pól
  VirtualGcRiderEntry copyWith({
    String? riderId,
    String? riderName,
    String? teamName,
    String? teamCode,
    String? countryIso,
    int? bibNumber,
    int? preStageRank,
    double? preStageGapSeconds,
    String? roadGroupName,
    double? roadGapToPelotonSeconds,
    double? virtualCumulativeSeconds,
    double? virtualGapToLeaderSeconds,
    int? virtualRank,
    int? rankChange,
    bool? isVirtualYellowJersey,
    bool? isActualYellowJersey,
    bool? isPlayerRider,
    bool? isGcContender,
  }) {
    return VirtualGcRiderEntry(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      teamName: teamName ?? this.teamName,
      teamCode: teamCode ?? this.teamCode,
      countryIso: countryIso ?? this.countryIso,
      bibNumber: bibNumber ?? this.bibNumber,
      preStageRank: preStageRank ?? this.preStageRank,
      preStageGapSeconds: preStageGapSeconds ?? this.preStageGapSeconds,
      roadGroupName: roadGroupName ?? this.roadGroupName,
      roadGapToPelotonSeconds: roadGapToPelotonSeconds ?? this.roadGapToPelotonSeconds,
      virtualCumulativeSeconds: virtualCumulativeSeconds ?? this.virtualCumulativeSeconds,
      virtualGapToLeaderSeconds: virtualGapToLeaderSeconds ?? this.virtualGapToLeaderSeconds,
      virtualRank: virtualRank ?? this.virtualRank,
      rankChange: rankChange ?? this.rankChange,
      isVirtualYellowJersey: isVirtualYellowJersey ?? this.isVirtualYellowJersey,
      isActualYellowJersey: isActualYellowJersey ?? this.isActualYellowJersey,
      isPlayerRider: isPlayerRider ?? this.isPlayerRider,
      isGcContender: isGcContender ?? this.isGcContender,
    );
  }
}

/// Silnik przeliczający Wirtualną Klasyfikację Generalną na żywo.
class VirtualGcCalculator {
  VirtualGcCalculator._();

  /// Przelicza wirtualne różnice czasowe i pozycje na trasie
  ///
  /// Parametry:
  /// - [riders]: Lista kolarzy z danymi wyjściowymi (oficjalny czas GC, strata, grupa na trasie)
  /// - [breakawayRoadGapSeconds]: Aktualna przewaga ucieczki nad peletonem w sekundach (np. 240.0 = 4 minuty)
  static List<VirtualGcRiderEntry> calculateStandings({
    required List<VirtualGcRiderEntry> riders,
    double breakawayRoadGapSeconds = 240.0,
  }) {
    if (riders.isEmpty) return const [];

    // 1. Wyznaczenie wirtualnego czasu łącznego dla każdego kolarza:
    // Wirtualny czas względem lidera GC = preStageGapSeconds - roadGainRelativeToPeloton
    final List<_VirtualCalcTemp> rawList = [];

    for (final r in riders) {
      double roadGain = 0.0;
      if (r.roadGroupName.toLowerCase().contains('ucieczk') ||
          r.roadGroupName.toLowerCase().contains('breakaway') ||
          r.roadGroupName.toLowerCase().contains('tête')) {
        roadGain = breakawayRoadGapSeconds;
      } else if (r.roadGroupName.toLowerCase().contains('kontr') ||
          r.roadGroupName.toLowerCase().contains('chase')) {
        roadGain = breakawayRoadGapSeconds * 0.45; // Kontra np. w połowie dystansu
      } else if (r.roadGroupName.toLowerCase().contains('grupetto') ||
          r.roadGroupName.toLowerCase().contains('autobus')) {
        roadGain = -360.0; // Grupetto traci 6 minut do peletonu
      } else {
        // Peleton: brak zysku na trasie
        roadGain = 0.0;
      }

      // Wirtualna różnica względem oficjalnego lidera z początku etapu
      final double virtualNetGapToActualLeader = r.preStageGapSeconds - roadGain;

      rawList.add(_VirtualCalcTemp(
        entry: r,
        roadGain: roadGain,
        virtualNetGapToActualLeader: virtualNetGapToActualLeader,
      ));
    }

    // 2. Sortowanie rosnąco według wirtualnego czasu (najniższa wartość wygrywa)
    rawList.sort((a, b) {
      final cmp = a.virtualNetGapToActualLeader.compareTo(b.virtualNetGapToActualLeader);
      if (cmp != 0) return cmp;
      return a.entry.preStageRank.compareTo(b.entry.preStageRank);
    });

    // 3. Wirtualnym liderem (Virtual Yellow Jersey) jest pierwszy na liście
    final double bestNetGap = rawList.first.virtualNetGapToActualLeader;

    final List<VirtualGcRiderEntry> result = [];

    for (int i = 0; i < rawList.length; i++) {
      final item = rawList[i];
      final int virtualRank = i + 1;
      final double virtualGapToLeader = item.virtualNetGapToActualLeader - bestNetGap;
      final int rankChange = item.entry.preStageRank - virtualRank; // dodatnie = awans

      result.add(item.entry.copyWith(
        virtualRank: virtualRank,
        virtualGapToLeaderSeconds: virtualGapToLeader,
        roadGapToPelotonSeconds: item.roadGain,
        rankChange: rankChange,
        isVirtualYellowJersey: virtualRank == 1,
        virtualCumulativeSeconds: 144000.0 + item.virtualNetGapToActualLeader,
      ));
    }

    return result;
  }

  /// Zestaw danych demonstracyjnych odtwarzający scenariusz z ucieczką mającą 4 minuty przewagi
  static List<VirtualGcRiderEntry> demoStandings({double breakawayGapSeconds = 240.0}) {
    // Oficjalny lider: Tadej Pogačar (UAD) - 0:00
    // Kolarz w ucieczce: Matej Mohorič (TBV) - strata z początku etapu: 3 min 15 sek (195s)
    // Przy 4 minutach przewagi ucieczki (240s), Mohorič wyprzedza Pogačara o 45 sekund!
    const baseRiders = [
      VirtualGcRiderEntry(
        riderId: 'r_pogacar',
        riderName: 'T. Pogačar',
        teamName: 'UAE Team Emirates',
        teamCode: 'UAD',
        countryIso: 'SLO',
        bibNumber: 1,
        preStageRank: 1,
        preStageGapSeconds: 0.0,
        roadGroupName: 'Peleton Główny',
        roadGapToPelotonSeconds: 0.0,
        virtualCumulativeSeconds: 144000.0,
        virtualGapToLeaderSeconds: 0.0,
        virtualRank: 1,
        rankChange: 0,
        isVirtualYellowJersey: false,
        isActualYellowJersey: true,
        isPlayerRider: true,
        isGcContender: true,
      ),
      VirtualGcRiderEntry(
        riderId: 'r_vingegaard',
        riderName: 'J. Vingegaard',
        teamName: 'Team Visma | Lease a Bike',
        teamCode: 'TVL',
        countryIso: 'DEN',
        bibNumber: 11,
        preStageRank: 2,
        preStageGapSeconds: 38.0,
        roadGroupName: 'Peleton Główny',
        roadGapToPelotonSeconds: 0.0,
        virtualCumulativeSeconds: 144038.0,
        virtualGapToLeaderSeconds: 38.0,
        virtualRank: 2,
        rankChange: 0,
        isVirtualYellowJersey: false,
        isActualYellowJersey: false,
        isPlayerRider: false,
        isGcContender: true,
      ),
      VirtualGcRiderEntry(
        riderId: 'r_evenepoel',
        riderName: 'R. Evenepoel',
        teamName: 'Soudal Quick-Step',
        teamCode: 'SOQ',
        countryIso: 'BEL',
        bibNumber: 21,
        preStageRank: 3,
        preStageGapSeconds: 74.0,
        roadGroupName: 'Peleton Główny',
        roadGapToPelotonSeconds: 0.0,
        virtualCumulativeSeconds: 144074.0,
        virtualGapToLeaderSeconds: 74.0,
        virtualRank: 3,
        rankChange: 0,
        isVirtualYellowJersey: false,
        isActualYellowJersey: false,
        isPlayerRider: false,
        isGcContender: true,
      ),
      VirtualGcRiderEntry(
        riderId: 'r_mohoric',
        riderName: 'M. Mohorič',
        teamName: 'Bahrain Victorious',
        teamCode: 'TBV',
        countryIso: 'SLO',
        bibNumber: 42,
        preStageRank: 14,
        preStageGapSeconds: 195.0, // +3'15" na starcie
        roadGroupName: 'Ucieczka (Breakaway)',
        roadGapToPelotonSeconds: 240.0, // +4'00" przewagi na trasie
        virtualCumulativeSeconds: 143955.0, // wyprzedza lidera o 45 sekund!
        virtualGapToLeaderSeconds: 0.0,
        virtualRank: 1,
        rankChange: 13,
        isVirtualYellowJersey: true,
        isActualYellowJersey: false,
        isPlayerRider: false,
        isGcContender: false,
      ),
      VirtualGcRiderEntry(
        riderId: 'r_cort',
        riderName: 'M. Cort Nielsen',
        teamName: 'Uno-X Mobility',
        teamCode: 'UXM',
        countryIso: 'DEN',
        bibNumber: 55,
        preStageRank: 28,
        preStageGapSeconds: 320.0, // +5'20"
        roadGroupName: 'Ucieczka (Breakaway)',
        roadGapToPelotonSeconds: 240.0,
        virtualCumulativeSeconds: 144080.0,
        virtualGapToLeaderSeconds: 125.0,
        virtualRank: 6,
        rankChange: 22,
        isVirtualYellowJersey: false,
        isActualYellowJersey: false,
        isPlayerRider: false,
        isGcContender: false,
      ),
      VirtualGcRiderEntry(
        riderId: 'r_majka',
        riderName: 'R. Majka',
        teamName: 'UAE Team Emirates',
        teamCode: 'UAD',
        countryIso: 'POL',
        bibNumber: 2,
        preStageRank: 19,
        preStageGapSeconds: 245.0, // +4'05"
        roadGroupName: 'Ucieczka (Breakaway)',
        roadGapToPelotonSeconds: 240.0,
        virtualCumulativeSeconds: 144005.0,
        virtualGapToLeaderSeconds: 50.0,
        virtualRank: 4,
        rankChange: 15,
        isVirtualYellowJersey: false,
        isActualYellowJersey: false,
        isPlayerRider: true,
        isGcContender: false,
      ),
      VirtualGcRiderEntry(
        riderId: 'r_roglik',
        riderName: 'P. Roglič',
        teamName: 'Red Bull - BORA - hansgrohe',
        teamCode: 'RBH',
        countryIso: 'SLO',
        bibNumber: 31,
        preStageRank: 4,
        preStageGapSeconds: 96.0,
        roadGroupName: 'Peleton Główny',
        roadGapToPelotonSeconds: 0.0,
        virtualCumulativeSeconds: 144096.0,
        virtualGapToLeaderSeconds: 96.0,
        virtualRank: 5,
        rankChange: -1,
        isVirtualYellowJersey: false,
        isActualYellowJersey: false,
        isPlayerRider: false,
        isGcContender: true,
      ),
      VirtualGcRiderEntry(
        riderId: 'r_rodriguez',
        riderName: 'C. Rodríguez',
        teamName: 'INEOS Grenadiers',
        teamCode: 'IGD',
        countryIso: 'ESP',
        bibNumber: 61,
        preStageRank: 5,
        preStageGapSeconds: 112.0,
        roadGroupName: 'Peleton Główny',
        roadGapToPelotonSeconds: 0.0,
        virtualCumulativeSeconds: 144112.0,
        virtualGapToLeaderSeconds: 112.0,
        virtualRank: 7,
        rankChange: -2,
        isVirtualYellowJersey: false,
        isActualYellowJersey: false,
        isPlayerRider: false,
        isGcContender: true,
      ),
      VirtualGcRiderEntry(
        riderId: 'r_almeida',
        riderName: 'J. Almeida',
        teamName: 'UAE Team Emirates',
        teamCode: 'UAD',
        countryIso: 'POR',
        bibNumber: 4,
        preStageRank: 6,
        preStageGapSeconds: 128.0,
        roadGroupName: 'Peleton Główny',
        roadGapToPelotonSeconds: 0.0,
        virtualCumulativeSeconds: 144128.0,
        virtualGapToLeaderSeconds: 128.0,
        virtualRank: 8,
        rankChange: -2,
        isVirtualYellowJersey: false,
        isActualYellowJersey: false,
        isPlayerRider: true,
        isGcContender: true,
      ),
      VirtualGcRiderEntry(
        riderId: 'r_ayuso',
        riderName: 'J. Ayuso',
        teamName: 'UAE Team Emirates',
        teamCode: 'UAD',
        countryIso: 'ESP',
        bibNumber: 3,
        preStageRank: 7,
        preStageGapSeconds: 145.0,
        roadGroupName: 'Peleton Główny',
        roadGapToPelotonSeconds: 0.0,
        virtualCumulativeSeconds: 144145.0,
        virtualGapToLeaderSeconds: 145.0,
        virtualRank: 9,
        rankChange: -2,
        isVirtualYellowJersey: false,
        isActualYellowJersey: false,
        isPlayerRider: true,
        isGcContender: true,
      ),
    ];

    return calculateStandings(
      riders: baseRiders,
      breakawayRoadGapSeconds: breakawayGapSeconds,
    );
  }
}

class _VirtualCalcTemp {
  final VirtualGcRiderEntry entry;
  final double roadGain;
  final double virtualNetGapToActualLeader;

  const _VirtualCalcTemp({
    required this.entry,
    required this.roadGain,
    required this.virtualNetGapToActualLeader,
  });
}

/// Wysuwany panel podczas wyścigu pokazujący Wirtualną Klasyfikację Generalną na żywo (Virtual GC).
///
/// Oblicza na bieżąco:
/// - Kto w danej sekundzie jest wirtualnym posiadaczem żółtej koszulki (*Maillot Jaune Virtuel*).
/// - O ile sekund wirtualny lider wyprzedza rywali na trasie.
/// - Awans/spadek pozycji kolarzy w ucieczce i peletonie.
/// - Filtry: Top 15, Ucieczka, Mój Zespół, Faworyci GC.
class LiveVirtualStandingsDrawer extends StatefulWidget {
  /// Lista kolarzy do wirtualnej klasyfikacji (domyślnie [VirtualGcCalculator.demoStandings])
  final List<VirtualGcRiderEntry>? initialStandings;

  /// Aktualna przewaga ucieczki nad peletonem w sekundach (domyślnie 240.0 = 4 minuty)
  final double breakawayRoadGapSeconds;

  /// Czy panel jest domyślnie otwarty / rozwinięty
  final bool initiallyExpanded;

  /// Callback przy zamknięciu / zwinięciu panelu
  final VoidCallback? onClose;

  /// Callback po kliknięciu na kolarza
  final ValueChanged<VirtualGcRiderEntry>? onRiderSelected;

  const LiveVirtualStandingsDrawer({
    super.key,
    this.initialStandings,
    this.breakawayRoadGapSeconds = 240.0,
    this.initiallyExpanded = true,
    this.onClose,
    this.onRiderSelected,
  });

  @override
  State<LiveVirtualStandingsDrawer> createState() => _LiveVirtualStandingsDrawerState();
}

class _LiveVirtualStandingsDrawerState extends State<LiveVirtualStandingsDrawer>
    with SingleTickerProviderStateMixin {
  late List<VirtualGcRiderEntry> _standings;
  late double _breakawayGap;
  VirtualGcFilter _currentFilter = VirtualGcFilter.top15;
  String _searchQuery = '';
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _breakawayGap = widget.breakawayRoadGapSeconds;
    _standings = widget.initialStandings ?? VirtualGcCalculator.demoStandings(breakawayGapSeconds: _breakawayGap);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    if (widget.initiallyExpanded) {
      _animController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant LiveVirtualStandingsDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.breakawayRoadGapSeconds != widget.breakawayRoadGapSeconds ||
        oldWidget.initialStandings != widget.initialStandings) {
      _breakawayGap = widget.breakawayRoadGapSeconds;
      final source = widget.initialStandings ?? _standings;
      setState(() {
        _standings = VirtualGcCalculator.calculateStandings(
          riders: source,
          breakawayRoadGapSeconds: _breakawayGap,
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  List<VirtualGcRiderEntry> _filterStandings(List<VirtualGcRiderEntry> list) {
    var filtered = list;

    switch (_currentFilter) {
      case VirtualGcFilter.top15:
        filtered = filtered.take(15).toList();
        break;
      case VirtualGcFilter.breakawayOnly:
        filtered = filtered.where((r) => r.roadGapToPelotonSeconds > 10.0).toList();
        break;
      case VirtualGcFilter.myTeamOnly:
        filtered = filtered.where((r) => r.isPlayerRider).toList();
        break;
      case VirtualGcFilter.gcContenders:
        filtered = filtered.where((r) => r.isGcContender || r.preStageRank <= 10).toList();
        break;
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((r) {
        return r.riderName.toLowerCase().contains(q) ||
            r.teamCode.toLowerCase().contains(q) ||
            r.countryIso.toLowerCase().contains(q);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final virtualLeader = _standings.firstWhere(
      (r) => r.isVirtualYellowJersey,
      orElse: () => _standings.first,
    );
    final actualLeader = _standings.firstWhere(
      (r) => r.isActualYellowJersey,
      orElse: () => _standings.first,
    );

    final displayList = _filterStandings(_standings);

    return SizeTransition(
      sizeFactor: _slideAnimation,
      alignment: Alignment.topCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
        decoration: BoxDecoration(
          color: const Color(0xFF11141D).withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Nagłówek panelu z żółtą wstęgą Virtual GC
            _buildDrawerHeader(virtualLeader),

            // Opcjonalne pole wyszukiwania kolarza
            if (_isSearchOpen) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: TextField(
                  key: const Key('input_search_rider'),
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  decoration: InputDecoration(
                    hintText: 'Szukaj kolarza lub zespołu...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: const Color(0xFF19202E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF2C3446)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.cyanAccent),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 14, color: Colors.white54),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
            ],

            // 2. Karta wyróżnienia Wirtualnego Lidera (Maillot Jaune Virtuel)
            _buildVirtualLeaderHighlightCard(virtualLeader, actualLeader),

            // 3. Pasek filtrów (Top 15, Ucieczka, Mój Zespół, Faworyci)
            _buildFilterChipsRow(),

            const SizedBox(height: 6),

            // 4. Tabela z listą kolarzy
            Flexible(
              child: displayList.isNotEmpty
                  ? _buildStandingsListView(displayList)
                  : _buildEmptyState(),
            ),

            // 5. Belka dolna z informacją o przewadze ucieczki
            _buildDrawerFooter(),
          ],
        ),
      ),
    );
  }

  /// Górna listwa z oficjalnym tytułem i wskaźnikiem live
  Widget _buildDrawerHeader(VirtualGcRiderEntry virtualLeader) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF161B26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(bottom: BorderSide(color: Color(0xFF262C3A), width: 1)),
      ),
      child: Row(
        children: [
          // Żółta koszulka Maillot Jaune
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
            ),
            child: const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFD700)),
          ),
          const SizedBox(width: 10),

          // Tytuł i migający wskaźnik na żywo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'WIRTUALNA KLASYFIKACJA GC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.statusSuccess.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.statusSuccess, width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 6, color: AppColors.statusSuccess),
                            SizedBox(width: 3),
                            Text(
                              'LIVE',
                              style: TextStyle(color: AppColors.statusSuccess, fontSize: 8.5, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Przeliczenia różnic czasowych na trasie w czasie rzeczywistym',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
                ),
              ],
            ),
          ),

          // Przycisk wyszukiwania
          IconButton(
            key: const Key('button_toggle_search_gc'),
            icon: Icon(
              _isSearchOpen ? Icons.search_off_rounded : Icons.search_rounded,
              size: 18,
              color: _isSearchOpen ? AppColors.cyanAccent : Colors.white70,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          const SizedBox(width: 8),

          // Przycisk zamknięcia panelu
          IconButton(
            key: const Key('button_close_virtual_gc'),
            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              widget.onClose?.call();
            },
          ),
        ],
      ),
    );
  }

  /// Wyróżniony baner Wirtualnego Lidera wyścigu
  Widget _buildVirtualLeaderHighlightCard(
    VirtualGcRiderEntry virtualLeader,
    VirtualGcRiderEntry actualLeader,
  ) {
    final bool leaderChanged = virtualLeader.riderId != actualLeader.riderId;
    final double leadSeconds = (actualLeader.virtualGapToLeaderSeconds);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF42370A).withValues(alpha: 0.7),
            const Color(0xFF1E1D13).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ikona koszulki lidera
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.sports_score_rounded, size: 24, color: Colors.black),
          ),
          const SizedBox(width: 10),

          // Opis wirtualnego lidera
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'WIRTUALNY LIDER (MAILLOT JAUNE)',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (virtualLeader.isPlayerRider) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.star_rounded, size: 12, color: AppColors.goldAccent),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${virtualLeader.riderName} (${virtualLeader.teamCode})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    leaderChanged
                        ? 'Awans o +${virtualLeader.rankChange} pozycji • ${virtualLeader.roadGroupName} (+${leadSeconds.toStringAsFixed(0)}s nad Pogačarem)'
                        : 'Utrzymuje żółtą koszulkę • Jedzie bezpiecznie w peletonie',
                    style: TextStyle(
                      color: leaderChanged ? const Color(0xFFFFE57F) : AppColors.textSecondary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Przewaga wirtualna
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'PRZEWAGA',
                  style: TextStyle(color: Color(0xFFFFD700), fontSize: 8, fontWeight: FontWeight.w800),
                ),
                Text(
                  virtualLeader.formattedVirtualGap,
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pasek filtrów tabeli
  Widget _buildFilterChipsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: VirtualGcFilter.values.map((filter) {
          final isSelected = _currentFilter == filter;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                key: Key('filter_${filter.name}'),
                onTap: () {
                  setState(() {
                    _currentFilter = filter;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF263044) : const Color(0xFF151922),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? AppColors.cyanAccent : const Color(0xFF252B3A),
                      width: isSelected ? 1.4 : 1.0,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filter.icon,
                          size: 11,
                          color: isSelected ? AppColors.cyanAccent : Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          filter.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Lista kolarzy w wirtualnej klasyfikacji
  Widget _buildStandingsListView(List<VirtualGcRiderEntry> list) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(color: Color(0xFF1C2230), height: 4),
      itemBuilder: (context, index) {
        final rider = list[index];
        return _buildRiderRow(rider);
      },
    );
  }

  /// Pojedynczy wiersz kolarza w tabeli
  Widget _buildRiderRow(VirtualGcRiderEntry rider) {
    final bool isYellow = rider.isVirtualYellowJersey;
    final bool isPlayer = rider.isPlayerRider;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onRiderSelected?.call(rider),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: isYellow
                ? const Color(0xFFFFD700).withValues(alpha: 0.12)
                : isPlayer
                    ? AppColors.goldAccent.withValues(alpha: 0.08)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isYellow
                ? Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4), width: 1)
                : isPlayer
                    ? Border.all(color: AppColors.goldAccent.withValues(alpha: 0.3), width: 0.8)
                    : null,
          ),
          child: Row(
            children: [
              // 1. Pozycja wirtualna i zmiana
              SizedBox(
                width: 42,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${rider.virtualRank}',
                      style: TextStyle(
                        color: isYellow ? const Color(0xFFFFD700) : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                    _buildRankChangeIndicator(rider.rankChange),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // 2. Kolarz, zespół i flaga
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            rider.riderName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isYellow
                                  ? const Color(0xFFFFD700)
                                  : isPlayer
                                      ? AppColors.goldAccent
                                      : Colors.white,
                              fontSize: 11.5,
                              fontWeight: isYellow || isPlayer ? FontWeight.w900 : FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${rider.teamCode})',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
                        ),
                        if (isPlayer) ...[
                          const SizedBox(width: 3),
                          const Icon(Icons.star_rounded, size: 10, color: AppColors.goldAccent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${rider.roadGroupName} • Start GC: ${rider.formattedPreStageGap}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 8.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // 3. Wirtualna strata do lidera
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rider.formattedVirtualGap,
                    style: TextStyle(
                      color: isYellow ? const Color(0xFFFFD700) : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    rider.formattedRoadGap,
                    style: TextStyle(
                      color: rider.roadGapToPelotonSeconds > 10.0
                          ? AppColors.emeraldGreen
                          : AppColors.textSecondary,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Wskaźnik zmiany pozycji (np. ▲ +13 lub ▼ -2)
  Widget _buildRankChangeIndicator(int change) {
    if (change > 0) {
      return Text(
        '▲ +$change',
        style: const TextStyle(
          color: AppColors.emeraldGreen,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      );
    } else if (change < 0) {
      return Text(
        '▼ $change',
        style: const TextStyle(
          color: AppColors.crimsonAlert,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      );
    }
    return const Text(
      '—',
      style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Text(
          'Brak kolarzy spełniających kryteria wybranego filtra.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ),
    );
  }

  /// Dolny pasek z podsumowaniem sytuacji na trasie
  Widget _buildDrawerFooter() {
    final int breakawayCount = _standings.where((r) => r.roadGapToPelotonSeconds > 10.0).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF141722),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
        border: Border(top: BorderSide(color: Color(0xFF262C3A), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 12, color: AppColors.cyanAccent),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Przewaga ucieczki: +${(_breakawayGap / 60.0).toStringAsFixed(1)} min ($breakawayCount kolarzy)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'UCI Regulations',
            style: TextStyle(color: Colors.white30, fontSize: 8),
          ),
        ],
      ),
    );
  }
}
