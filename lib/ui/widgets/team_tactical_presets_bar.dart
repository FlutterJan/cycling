// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/peloton/rider_race_state.dart';
import '../../models/rider/rider.dart';

/// Predefiniowane taktyki drużynowe uruchamiane jednym kliknięciem (1-Click Team Tactics).
enum TeamTacticalPreset {
  /// Uformuj Pociąg Górski (automatycznie ustawia górali od najsłabszego do lidera na czele peletonu)
  mountainTrain,

  /// Uformuj Pociąg Sprinterski (ustawia lead-out train pod wybranego sprintera)
  sprintTrain,

  /// Złóż Wachlarz (Echelon Attack) (cała drużyna wychodzi na wiatr boczny, aby rozerwać peleton)
  echelonAttack,

  /// Wszyscy chrońcie Lidera (alarm w razie kraksy lub defektu lidera)
  protectLeader;

  /// Pełny oficjalny tytuł taktyki
  String get title {
    switch (this) {
      case TeamTacticalPreset.mountainTrain:
        return 'Uformuj Pociąg Górski';
      case TeamTacticalPreset.sprintTrain:
        return 'Uformuj Pociąg Sprinterski';
      case TeamTacticalPreset.echelonAttack:
        return 'Złóż Wachlarz (Echelon Attack)';
      case TeamTacticalPreset.protectLeader:
        return 'Wszyscy chrońcie Lidera';
    }
  }

  /// Skrócony tytuł do kompaktowych kafelków
  String get shortTitle {
    switch (this) {
      case TeamTacticalPreset.mountainTrain:
        return 'Pociąg Górski';
      case TeamTacticalPreset.sprintTrain:
        return 'Pociąg Sprinterski';
      case TeamTacticalPreset.echelonAttack:
        return 'Złóż Wachlarz';
      case TeamTacticalPreset.protectLeader:
        return 'Chrońcie Lidera';
    }
  }

  /// Podtytuł i zwięzły opis działania
  String get subtitle {
    switch (this) {
      case TeamTacticalPreset.mountainTrain:
        return 'Schodkowi górale • Ostre tempo podjazdowe';
      case TeamTacticalPreset.sprintTrain:
        return 'Lead-out train • Rozprowadzenie sprintera';
      case TeamTacticalPreset.echelonAttack:
        return 'Ranty na wietrze • Rozerwanie peletonu';
      case TeamTacticalPreset.protectLeader:
        return 'Alarm kryzysowy • Eskorta i odholowanie lidera';
    }
  }

  /// Ikona reprezentująca daną taktykę
  IconData get icon {
    switch (this) {
      case TeamTacticalPreset.mountainTrain:
        return Icons.terrain_rounded;
      case TeamTacticalPreset.sprintTrain:
        return Icons.fast_forward_rounded;
      case TeamTacticalPreset.echelonAttack:
        return Icons.air_rounded;
      case TeamTacticalPreset.protectLeader:
        return Icons.shield_rounded;
    }
  }

  /// Kolor akcentu wizualnego
  Color get accentColor {
    switch (this) {
      case TeamTacticalPreset.mountainTrain:
        return AppColors.powerZone5; // Pomarańczowy / górski
      case TeamTacticalPreset.sprintTrain:
        return AppColors.powerZone4; // Żółty / sprinterski
      case TeamTacticalPreset.echelonAttack:
        return AppColors.cyanAccent; // Błękitny / wiatr
      case TeamTacticalPreset.protectLeader:
        return AppColors.crimsonAlert; // Czerwony / alarm lidera
    }
  }

  /// Komunikat Dyrektora Sportowego przez Radio Wyścigowe
  String get dsRadioOrder {
    switch (this) {
      case TeamTacticalPreset.mountainTrain:
        return 'Dyrektor Sportowy: "Panowie, formujemy pociąg górski! Ustawić się w schodki od Rafała po Tadeusza, narzucamy ostre tempo!"';
      case TeamTacticalPreset.sprintTrain:
        return 'Dyrektor Sportowy: "Pociąg sprinterski na pierwszą linię! Lokomotywy trzymać 60 km/h, pilot wypuszcza sprintera na 200m!"';
      case TeamTacticalPreset.echelonAttack:
        return 'Dyrektor Sportowy: "Wiatr boczny! Wszyscy na prawy rant szosy, kręcimy wachlarz na pełnej mocy i rwiemy grupę!"';
      case TeamTacticalPreset.protectLeader:
        return 'Dyrektor Sportowy: "ALARM W DRUŻYNIE! Lider ma defekt/kraksę! Wszyscy natychmiast zwalniają, tworzymy tunel i holujemy go do peletonu!"';
    }
  }
}

/// Pojedyncze zadanie taktyczne przydzielone kolarzowi w ramach 1-Click Team Tactics.
class TeamRiderAssignment {
  final String riderId;
  final String riderName;
  final int bibNumber;
  final RiderSpecialization specialization;
  final int trainPosition; // 1 = pierwsza zmiana (czoło), 8 = ogon / lider chroniony
  final TacticalOrder order;
  final String roleName;
  final double targetEffortPercent;
  final int targetWatts;
  final double wattsPerKg;
  final String tacticalNote;

  const TeamRiderAssignment({
    required this.riderId,
    required this.riderName,
    required this.bibNumber,
    required this.specialization,
    required this.trainPosition,
    required this.order,
    required this.roleName,
    required this.targetEffortPercent,
    required this.targetWatts,
    required this.wattsPerKg,
    required this.tacticalNote,
  });

  @override
  String toString() {
    return '#$trainPosition $riderName ($roleName): ${order.name} @ ${targetEffortPercent.toStringAsFixed(0)}% FTP (${targetWatts}W)';
  }
}

/// Kompletny plan taktyczny dla 8 kolarzy wygenerowany przez 1-Click Team Tactics.
class TeamTacticalPlan {
  final TeamTacticalPreset preset;
  final String title;
  final String radioMessage;
  final List<TeamRiderAssignment> assignments;
  final DateTime timestamp;

  TeamTacticalPlan({
    required this.preset,
    required this.title,
    required this.radioMessage,
    required this.assignments,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Zwraca przypisanie dla konkretnego identyfikatora kolarza
  TeamRiderAssignment? getAssignmentForRider(String riderId) {
    for (final a in assignments) {
      if (a.riderId == riderId) return a;
    }
    return null;
  }
}

/// Lekka reprezentacja zawodnika drużyny gracza do celów przypisywania ról taktycznych.
class TeamRosterMember {
  final String id;
  final String name;
  final int bibNumber;
  final RiderSpecialization specialization;
  final int ftpWatts;
  final double weightKg;
  final int sprintWatts5s;
  final int oneMinWatts;
  final int bikeHandling;
  final int overallRating;
  final bool isGcLeader;
  final bool isPrimarySprinter;

  const TeamRosterMember({
    required this.id,
    required this.name,
    required this.bibNumber,
    required this.specialization,
    required this.ftpWatts,
    required this.weightKg,
    required this.sprintWatts5s,
    required this.oneMinWatts,
    required this.bikeHandling,
    required this.overallRating,
    this.isGcLeader = false,
    this.isPrimarySprinter = false,
  });

  double get wattsPerKg => weightKg > 0.0 ? (ftpWatts / weightKg) : 0.0;

  /// Konwersja z pełnego modelu kolarza [Rider]
  factory TeamRosterMember.fromRider(Rider r, {int bibNumber = 1, bool isLeader = false, bool isSprinter = false}) {
    return TeamRosterMember(
      id: r.id,
      name: r.fullName,
      bibNumber: bibNumber,
      specialization: r.specialization,
      ftpWatts: r.physiology.ftpWatts,
      weightKg: r.physiology.weightKg,
      sprintWatts5s: r.powerProfile.watts5s,
      oneMinWatts: r.powerProfile.watts1m,
      bikeHandling: r.skills.bikeHandling,
      overallRating: r.overallRating,
      isGcLeader: isLeader || r.specialization == RiderSpecialization.gcClimber,
      isPrimarySprinter: isSprinter || r.specialization == RiderSpecialization.pureSprinter,
    );
  }

  /// Domyślny 8-osobowy skład demonstracyjny drużyny WorldTour
  static List<TeamRosterMember> demoRoster() {
    return const [
      TeamRosterMember(
        id: 'r_pogacar',
        name: 'T. Pogačar',
        bibNumber: 1,
        specialization: RiderSpecialization.gcClimber,
        ftpWatts: 425,
        weightKg: 66.0,
        sprintWatts5s: 1420,
        oneMinWatts: 780,
        bikeHandling: 94,
        overallRating: 97,
        isGcLeader: true,
      ),
      TeamRosterMember(
        id: 'r_majka',
        name: 'R. Majka',
        bibNumber: 2,
        specialization: RiderSpecialization.pureClimber,
        ftpWatts: 385,
        weightKg: 62.0,
        sprintWatts5s: 1080,
        oneMinWatts: 620,
        bikeHandling: 85,
        overallRating: 84,
      ),
      TeamRosterMember(
        id: 'r_ayuso',
        name: 'J. Ayuso',
        bibNumber: 3,
        specialization: RiderSpecialization.gcClimber,
        ftpWatts: 395,
        weightKg: 65.0,
        sprintWatts5s: 1210,
        oneMinWatts: 690,
        bikeHandling: 86,
        overallRating: 88,
      ),
      TeamRosterMember(
        id: 'r_almeida',
        name: 'J. Almeida',
        bibNumber: 4,
        specialization: RiderSpecialization.timeTrialist,
        ftpWatts: 410,
        weightKg: 67.0,
        sprintWatts5s: 1150,
        oneMinWatts: 680,
        bikeHandling: 87,
        overallRating: 89,
      ),
      TeamRosterMember(
        id: 'r_politt',
        name: 'N. Politt',
        bibNumber: 5,
        specialization: RiderSpecialization.classicCobbles,
        ftpWatts: 430,
        weightKg: 80.0,
        sprintWatts5s: 1380,
        oneMinWatts: 740,
        bikeHandling: 91,
        overallRating: 85,
      ),
      TeamRosterMember(
        id: 'r_wellens',
        name: 'T. Wellens',
        bibNumber: 6,
        specialization: RiderSpecialization.puncher,
        ftpWatts: 405,
        weightKg: 71.0,
        sprintWatts5s: 1350,
        oneMinWatts: 750,
        bikeHandling: 90,
        overallRating: 86,
      ),
      TeamRosterMember(
        id: 'r_bjerg',
        name: 'M. Bjerg',
        bibNumber: 7,
        specialization: RiderSpecialization.timeTrialist,
        ftpWatts: 420,
        weightKg: 74.0,
        sprintWatts5s: 1290,
        oneMinWatts: 710,
        bikeHandling: 88,
        overallRating: 83,
      ),
      TeamRosterMember(
        id: 'r_molano',
        name: 'J. S. Molano',
        bibNumber: 8,
        specialization: RiderSpecialization.pureSprinter,
        ftpWatts: 380,
        weightKg: 73.0,
        sprintWatts5s: 1680,
        oneMinWatts: 820,
        bikeHandling: 89,
        overallRating: 84,
        isPrimarySprinter: true,
      ),
    ];
  }
}

/// Silnik generujący zoptymalizowane plany taktyczne dla 8 kolarzy na podstawie wybranego presetu.
class TeamTacticsPlanner {
  TeamTacticsPlanner._();

  /// Tworzy zoptymalizowany plan taktyczny dla całego składu
  static TeamTacticalPlan createPlan({
    required TeamTacticalPreset preset,
    required List<TeamRosterMember> roster,
  }) {
    final activeRoster = List<TeamRosterMember>.from(roster.isNotEmpty ? roster : TeamRosterMember.demoRoster());

    switch (preset) {
      case TeamTacticalPreset.mountainTrain:
        return _planMountainTrain(activeRoster);
      case TeamTacticalPreset.sprintTrain:
        return _planSprintTrain(activeRoster);
      case TeamTacticalPreset.echelonAttack:
        return _planEchelonAttack(activeRoster);
      case TeamTacticalPreset.protectLeader:
        return _planProtectLeader(activeRoster);
    }
  }

  /// 1. Pociąg Górski: automatycznie ustawia górali od najsłabszego do lidera na czele peletonu
  static TeamTacticalPlan _planMountainTrain(List<TeamRosterMember> roster) {
    // 1. Wyłonienie lidera GC (najwyższe W/kg lub flaga lidera)
    final leader = roster.firstWhere(
      (r) => r.isGcLeader,
      orElse: () => roster.reduce((a, b) => a.wattsPerKg > b.wattsPerKg ? a : b),
    );

    // 2. Pomocnicy posortowani rosnąco według W/kg (od najsłabszego na czele do najmocniejszego przed liderem)
    final domestiques = roster.where((r) => r.id != leader.id).toList()
      ..sort((a, b) => a.wattsPerKg.compareTo(b.wattsPerKg));

    final assignments = <TeamRiderAssignment>[];

    for (int i = 0; i < domestiques.length; i++) {
      final rider = domestiques[i];
      final trainPos = i + 1;
      final bool isLastLieutenant = i == domestiques.length - 1;
      final double effort = isLastLieutenant ? 110.0 : (95.0 + (i * 2.5)).clamp(95.0, 108.0);
      final role = isLastLieutenant
          ? 'Ostatni Porucznik (Selekcja)'
          : trainPos <= 2
              ? 'Lokomotywa płaska / tempo wstępne'
              : 'Górski pomocnik (Schodek $trainPos)';

      assignments.add(TeamRiderAssignment(
        riderId: rider.id,
        riderName: rider.name,
        bibNumber: rider.bibNumber,
        specialization: rider.specialization,
        trainPosition: trainPos,
        order: TacticalOrder.pullGroup,
        roleName: role,
        targetEffortPercent: effort,
        targetWatts: (rider.ftpWatts * (effort / 100.0)).round(),
        wattsPerKg: (rider.wattsPerKg * (effort / 100.0)),
        tacticalNote: 'Narzuca ostre tempo na czele, wykruszając rywali lidera.',
      ));
    }

    // Lider na końcu pociągu (osłonięty w aerodynamicznym tunelu zespołu)
    assignments.add(TeamRiderAssignment(
      riderId: leader.id,
      riderName: leader.name,
      bibNumber: leader.bibNumber,
      specialization: leader.specialization,
      trainPosition: assignments.length + 1,
      order: TacticalOrder.saveEnergy,
      roleName: 'Lider GC (Osłonięty)',
      targetEffortPercent: 88.0,
      targetWatts: (leader.ftpWatts * 0.88).round(),
      wattsPerKg: leader.wattsPerKg * 0.88,
      tacticalNote: 'Jedzie w najgłębszym tunelu pociągu, oszczędzając W\' na finałowy atak.',
    ));

    return TeamTacticalPlan(
      preset: TeamTacticalPreset.mountainTrain,
      title: TeamTacticalPreset.mountainTrain.title,
      radioMessage: TeamTacticalPreset.mountainTrain.dsRadioOrder,
      assignments: assignments,
    );
  }

  /// 2. Pociąg Sprinterski: ustawia lead-out train pod wybranego sprintera
  static TeamTacticalPlan _planSprintTrain(List<TeamRosterMember> roster) {
    // 1. Główny sprinter (najwyższa moc 5s lub flaga sprintera)
    final sprinter = roster.firstWhere(
      (r) => r.isPrimarySprinter || r.specialization == RiderSpecialization.pureSprinter,
      orElse: () => roster.reduce((a, b) => a.sprintWatts5s > b.sprintWatts5s ? a : b),
    );

    // 2. Ostatni pilot finiszu (wysoka moc 1-minutowa / punch)
    final remaining = roster.where((r) => r.id != sprinter.id).toList();
    remaining.sort((a, b) => b.oneMinWatts.compareTo(a.oneMinWatts));
    final finalPilot = remaining.removeAt(0);

    // 3. Rozprowadzający podkręcający prędkość (speed lifter)
    final speedLifter = remaining.isNotEmpty ? remaining.removeAt(0) : null;

    // 4. Lokomotywy płaskie (najwyższe FTP)
    remaining.sort((a, b) => a.ftpWatts.compareTo(b.ftpWatts));

    final assignments = <TeamRiderAssignment>[];
    int currentPos = 1;

    for (final loco in remaining) {
      assignments.add(TeamRiderAssignment(
        riderId: loco.id,
        riderName: loco.name,
        bibNumber: loco.bibNumber,
        specialization: loco.specialization,
        trainPosition: currentPos++,
        order: TacticalOrder.pullGroup,
        roleName: 'Lokomotywa płaska ($currentPos. zmiana)',
        targetEffortPercent: 105.0,
        targetWatts: (loco.ftpWatts * 1.05).round(),
        wattsPerKg: loco.wattsPerKg * 1.05,
        tacticalNote: 'Trzyma prędkość peletonu > 58 km/h na dojeździe do strefy sprintu.',
      ));
    }

    if (speedLifter != null) {
      assignments.add(TeamRiderAssignment(
        riderId: speedLifter.id,
        riderName: speedLifter.name,
        bibNumber: speedLifter.bibNumber,
        specialization: speedLifter.specialization,
        trainPosition: currentPos++,
        order: TacticalOrder.pullGroup,
        roleName: 'Podkręcający (1500m - 700m)',
        targetEffortPercent: 112.0,
        targetWatts: (speedLifter.ftpWatts * 1.12).round(),
        wattsPerKg: speedLifter.wattsPerKg * 1.12,
        tacticalNote: 'Podnosi tempo do 64 km/h, kasując próby wczesnego finiszu rywali.',
      ));
    }

    assignments.add(TeamRiderAssignment(
      riderId: finalPilot.id,
      riderName: finalPilot.name,
      bibNumber: finalPilot.bibNumber,
      specialization: finalPilot.specialization,
      trainPosition: currentPos++,
      order: TacticalOrder.pullGroup,
      roleName: 'Ostatni Pilot (Lead-out)',
      targetEffortPercent: 120.0,
      targetWatts: (finalPilot.ftpWatts * 1.20).round(),
      wattsPerKg: finalPilot.wattsPerKg * 1.20,
      tacticalNote: 'Maksymalny zryw na 600m - 200m przed kreską. Wypuszcza sprintera z koła.',
    ));

    assignments.add(TeamRiderAssignment(
      riderId: sprinter.id,
      riderName: sprinter.name,
      bibNumber: sprinter.bibNumber,
      specialization: sprinter.specialization,
      trainPosition: currentPos,
      order: TacticalOrder.holdPosition,
      roleName: 'Główny Sprinter (Finisz)',
      targetEffortPercent: 90.0,
      targetWatts: (sprinter.ftpWatts * 0.90).round(),
      wattsPerKg: sprinter.wattsPerKg * 0.90,
      tacticalNote: 'Siedzi w cieniu pilota z palcem na spuście. Odpala sprint na 200m do mety!',
    ));

    return TeamTacticalPlan(
      preset: TeamTacticalPreset.sprintTrain,
      title: TeamTacticalPreset.sprintTrain.title,
      radioMessage: TeamTacticalPreset.sprintTrain.dsRadioOrder,
      assignments: assignments,
    );
  }

  /// 3. Złóż Wachlarz (Echelon Attack): cała drużyna wychodzi na wiatr boczny, aby rozerwać peleton
  static TeamTacticalPlan _planEchelonAttack(List<TeamRosterMember> roster) {
    // Sortowanie według umiejętności jazdy na wietrze i sterowności (bikeHandling + ftpWatts)
    final sorted = List<TeamRosterMember>.from(roster)
      ..sort((a, b) {
        final scoreA = (a.bikeHandling * 0.6) + (a.ftpWatts * 0.4);
        final scoreB = (b.bikeHandling * 0.6) + (b.ftpWatts * 0.4);
        return scoreB.compareTo(scoreA);
      });

    final assignments = <TeamRiderAssignment>[];

    for (int i = 0; i < sorted.length; i++) {
      final rider = sorted[i];
      final int pos = i + 1;
      final bool isFrontRoller = pos <= 4;
      final double effort = isFrontRoller ? 112.0 : 100.0;
      final role = isFrontRoller
          ? 'Rotacyjna zmiana na wietrze (#$pos)'
          : 'Skrzydłowy wachlarza (Osłona #$pos)';

      assignments.add(TeamRiderAssignment(
        riderId: rider.id,
        riderName: rider.name,
        bibNumber: rider.bibNumber,
        specialization: rider.specialization,
        trainPosition: pos,
        order: isFrontRoller ? TacticalOrder.pullGroup : TacticalOrder.holdPosition,
        roleName: role,
        targetEffortPercent: effort,
        targetWatts: (rider.ftpWatts * (effort / 100.0)).round(),
        wattsPerKg: rider.wattsPerKg * (effort / 100.0),
        tacticalNote: isFrontRoller
            ? 'Cięcie wiatru na ranie szosy z maksymalną siłą, spychanie rywali do rynsztoka.'
            : 'Utrzymanie idealnego kąta draftingu, zabezpieczenie tyłu formacji.',
      ));
    }

    return TeamTacticalPlan(
      preset: TeamTacticalPreset.echelonAttack,
      title: TeamTacticalPreset.echelonAttack.title,
      radioMessage: TeamTacticalPreset.echelonAttack.dsRadioOrder,
      assignments: assignments,
    );
  }

  /// 4. Wszyscy chrońcie Lidera: alarm w razie kraksy lub defektu lidera
  static TeamTacticalPlan _planProtectLeader(List<TeamRosterMember> roster) {
    // Lider GC
    final leader = roster.firstWhere(
      (r) => r.isGcLeader,
      orElse: () => roster.reduce((a, b) => a.wattsPerKg > b.wattsPerKg ? a : b),
    );

    // Wszyscy pozostali pomocnicy posortowani według siły na płaskim (ftpWatts)
    final domestiques = roster.where((r) => r.id != leader.id).toList()
      ..sort((a, b) => b.ftpWatts.compareTo(a.ftpWatts));

    final assignments = <TeamRiderAssignment>[];

    for (int i = 0; i < domestiques.length; i++) {
      final rider = domestiques[i];
      final int pos = i + 1;
      final role = pos <= 2
          ? 'Holownik główny (Eskorta #$pos)'
          : 'Mur ochronny (Boczna osłona #$pos)';

      assignments.add(TeamRiderAssignment(
        riderId: rider.id,
        riderName: rider.name,
        bibNumber: rider.bibNumber,
        specialization: rider.specialization,
        trainPosition: pos,
        order: TacticalOrder.protectLeader,
        roleName: role,
        targetEffortPercent: 104.0,
        targetWatts: (rider.ftpWatts * 1.04).round(),
        wattsPerKg: rider.wattsPerKg * 1.04,
        tacticalNote: 'Tworzy tunel aerodynamiczny przed liderem, by dociągnąć go do grupy.',
      ));
    }

    // Lider chroniony
    assignments.add(TeamRiderAssignment(
      riderId: leader.id,
      riderName: leader.name,
      bibNumber: leader.bibNumber,
      specialization: leader.specialization,
      trainPosition: assignments.length + 1,
      order: TacticalOrder.followWheels,
      roleName: 'Lider Ratowany (Konwój)',
      targetEffortPercent: 92.0,
      targetWatts: (leader.ftpWatts * 0.92).round(),
      wattsPerKg: leader.wattsPerKg * 0.92,
      tacticalNote: 'Trzyma się wyłącznie koła swoich pomocników, unikając kontaktu z wiatrem.',
    ));

    return TeamTacticalPlan(
      preset: TeamTacticalPreset.protectLeader,
      title: TeamTacticalPreset.protectLeader.title,
      radioMessage: TeamTacticalPreset.protectLeader.dsRadioOrder,
      assignments: assignments,
    );
  }
}

/// Pasek szybkich rozkazów taktycznych dla całej drużyny (1-Click Team Tactics).
///
/// Umożliwia graczowi w krytycznych momentach wyścigu uruchomienie jednej z 4 taktyk drużynowych:
/// 1. **Uformuj Pociąg Górski** (sortowanie schodkowe górali od najsłabszego do lidera)
/// 2. **Uformuj Pociąg Sprinterski** (rozprowadzający, pilot i finiszujący sprinter)
/// 3. **Złóż Wachlarz (Echelon Attack)** (agresywne wyjście na wiatr boczny i rwanie peletonu)
/// 4. **Wszyscy chrońcie Lidera** (alarm kryzysowy po kraksie lub defekcie)
class TeamTacticalPresetsBar extends StatefulWidget {
  /// Skład drużyny gracza (domyślnie [TeamRosterMember.demoRoster])
  final List<TeamRosterMember> roster;

  /// Aktualnie aktywna taktyka drużynowa (jeśli jakakolwiek jest włączona)
  final TeamTacticalPreset? activePreset;

  /// Callback wywoływany po kliknięciu presetu
  final ValueChanged<TeamTacticalPreset>? onPresetSelected;

  /// Callback przekazujący szczegółowy wygenerowany plan dla 8 kolarzy
  final ValueChanged<TeamTacticalPlan>? onPlanExecuted;

  /// Callback przywracający neutralny/domyślny szyk drużyny
  final VoidCallback? onResetTactics;

  /// Czy pasek ma być zwinięty w kompaktowy widget
  final bool isCompact;

  const TeamTacticalPresetsBar({
    super.key,
    this.roster = const [],
    this.activePreset,
    this.onPresetSelected,
    this.onPlanExecuted,
    this.onResetTactics,
    this.isCompact = false,
  });

  @override
  State<TeamTacticalPresetsBar> createState() => _TeamTacticalPresetsBarState();
}

class _TeamTacticalPresetsBarState extends State<TeamTacticalPresetsBar> {
  TeamTacticalPreset? _activePreset;
  TeamTacticalPlan? _currentPlan;
  String? _recentRadioMessage;

  @override
  void initState() {
    super.initState();
    _activePreset = widget.activePreset;
  }

  @override
  void didUpdateWidget(covariant TeamTacticalPresetsBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activePreset != widget.activePreset) {
      _activePreset = widget.activePreset;
    }
  }

  void _executePreset(TeamTacticalPreset preset) {
    final plan = TeamTacticsPlanner.createPlan(
      preset: preset,
      roster: widget.roster,
    );

    setState(() {
      _activePreset = preset;
      _currentPlan = plan;
      _recentRadioMessage = preset.dsRadioOrder;
    });

    widget.onPresetSelected?.call(preset);
    widget.onPlanExecuted?.call(plan);
  }

  void _resetTactics() {
    setState(() {
      _activePreset = null;
      _currentPlan = null;
      _recentRadioMessage = null;
    });
    widget.onResetTactics?.call();
  }

  void _showRosterPlanModal(BuildContext context, TeamTacticalPlan plan) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: const BoxConstraints(maxWidth: 680),
        decoration: BoxDecoration(
          color: const Color(0xFF10131B).withValues(alpha: 0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          border: Border.all(color: AppTheme.borderColor, width: 1.5),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nagłówek modalu
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: plan.preset.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(plan.preset.icon, size: 20, color: plan.preset.accentColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Skład formacji drużynowej (${plan.assignments.length} kolarzy)',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Komunikat radiowy DS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: plan.preset.accentColor.withValues(alpha: 0.4), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.radio_rounded, size: 16, color: AppColors.cyanAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plan.radioMessage,
                      style: const TextStyle(
                        color: AppColors.cyanAccent,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Lista 8 kolarzy z pozycjami w pociągu
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: plan.assignments.length,
                separatorBuilder: (_, __) => const Divider(color: Color(0xFF1E2330), height: 8),
                itemBuilder: (ctx, index) {
                  final a = plan.assignments[index];
                  final isLeader = a.roleName.contains('Lider');

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLeader ? AppColors.goldAccent.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isLeader
                          ? Border.all(color: AppColors.goldAccent.withValues(alpha: 0.4), width: 1)
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Numer pozycji w pociągu (1..8)
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isLeader ? AppColors.goldAccent : const Color(0xFF232838),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '#${a.trainPosition}',
                            style: TextStyle(
                              color: isLeader ? Colors.black : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Kolarz i rola
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    a.riderName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${a.specialization.displayName.split(' ').first})',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${a.roleName} • ${a.tacticalNote}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isLeader ? AppColors.goldAccent : AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Docelowe Waty i % FTP
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${a.targetWatts} W',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              '${a.targetEffortPercent.toStringAsFixed(0)}% FTP • ${a.wattsPerKg.toStringAsFixed(1)} W/kg',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131720).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(widget.isCompact ? 10 : 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Belka nagłówkowa z tytułem i statusem aktywnej taktyki
          _buildHeaderBar(),

          // 2. Opcjonalny pasek radia DS po wydaniu rozkazu
          if (_recentRadioMessage != null) ...[
            const SizedBox(height: 8),
            _buildDsRadioPill(),
          ],

          const SizedBox(height: 10),

          // 3. Pasek 4 przycisków 1-Click Team Tactics
          _buildTacticalPresetButtonsRow(),
        ],
      ),
    );
  }

  /// Belka nagłówkowa z tytułem modułu i przyciskiem podglądu pociągu / neutralizacji
  Widget _buildHeaderBar() {
    final active = _activePreset;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: (active?.accentColor ?? AppColors.cyanAccent).withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (active?.accentColor ?? AppColors.cyanAccent).withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Icon(
            active?.icon ?? Icons.hub_rounded,
            size: 16,
            color: active?.accentColor ?? AppColors.cyanAccent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TAKTYKI DRUŻYNY • 1-CLICK TEAM TACTICS',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                active != null
                    ? 'AKTYWNY ROZKAZ: ${active.title.toUpperCase()}'
                    : 'Wybierz manewr, by wydać skoordynowany rozkaz dla 8 kolarzy',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active != null ? active.accentColor : AppColors.textSecondary,
                  fontSize: 9.5,
                  fontWeight: active != null ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 6),

        // Przycisk podglądu składu 8 kolarzy (jeśli jest aktywny plan)
        if (_currentPlan != null) ...[
          InkWell(
            key: const Key('button_view_train_roster'),
            onTap: () => _showRosterPlanModal(context, _currentPlan!),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2232),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.format_list_numbered_rounded, size: 12, color: AppColors.cyanAccent),
                  SizedBox(width: 4),
                  Text(
                    'Pociąg (8)',
                    style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],

        // Przycisk przerwania / neutralnego szyku
        if (active != null) ...[
          InkWell(
            key: const Key('button_reset_tactics'),
            onTap: _resetTactics,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stop_circle_outlined, size: 12, color: Colors.white70),
                  SizedBox(width: 4),
                  Text(
                    'Neutralny',
                    style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Pigułka z komunikatem z Radia Wyścigowego
  Widget _buildDsRadioPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF101726),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.volume_up_rounded, size: 13, color: AppColors.cyanAccent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _recentRadioMessage ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.cyanAccent,
                fontSize: 9.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Poziomy rząd 4 przycisków taktycznych
  Widget _buildTacticalPresetButtonsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Jeśli szerokość jest duża (>= 680px), wyświetlamy pełny rząd 4 kolumn
        // Jeśli szerokość jest mniejsza, pozwalamy na horyzontalne przewijanie lub 2x2
        final bool isWide = constraints.maxWidth >= 640;

        if (isWide) {
          return Row(
            children: [
              Expanded(child: _buildPresetCard(TeamTacticalPreset.mountainTrain, const Key('preset_mountain_train'))),
              const SizedBox(width: 8),
              Expanded(child: _buildPresetCard(TeamTacticalPreset.sprintTrain, const Key('preset_sprint_train'))),
              const SizedBox(width: 8),
              Expanded(child: _buildPresetCard(TeamTacticalPreset.echelonAttack, const Key('preset_echelon_attack'))),
              const SizedBox(width: 8),
              Expanded(child: _buildPresetCard(TeamTacticalPreset.protectLeader, const Key('preset_protect_leader'))),
            ],
          );
        }

        // Tryb responsywny ze scrollem poziomym
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              SizedBox(
                width: 175,
                child: _buildPresetCard(TeamTacticalPreset.mountainTrain, const Key('preset_mountain_train')),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 175,
                child: _buildPresetCard(TeamTacticalPreset.sprintTrain, const Key('preset_sprint_train')),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 175,
                child: _buildPresetCard(TeamTacticalPreset.echelonAttack, const Key('preset_echelon_attack')),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 175,
                child: _buildPresetCard(TeamTacticalPreset.protectLeader, const Key('preset_protect_leader')),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Pojedynczy kafelek akcji taktycznej
  Widget _buildPresetCard(TeamTacticalPreset preset, Key key) {
    final bool isActive = _activePreset == preset;
    final Color accent = preset.accentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: () => _executePreset(preset),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? accent.withValues(alpha: 0.16)
                : const Color(0xFF161B26),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? accent : const Color(0xFF262C3A),
              width: isActive ? 1.8 : 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ikona i wskaźnik statusu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isActive ? accent.withValues(alpha: 0.3) : const Color(0xFF202636),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      preset.icon,
                      size: 14,
                      color: isActive ? accent : Colors.white70,
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AKTYWNA',
                        style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 6),

              // Tytuł rozkazu
              Text(
                preset.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                ),
              ),

              const SizedBox(height: 2),

              // Podtytuł rozkazu
              Text(
                preset.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

