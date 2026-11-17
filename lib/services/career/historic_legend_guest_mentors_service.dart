import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'historic_legend_hall_of_fame_compare.dart';

/// Typ zlecenia dla byłej legendy kolarstwa zatrudnianej jako doradca.
enum LegendMentorAssignmentType {
  altitudeCamp(
    id: 'altitude_camp',
    displayName: 'Obóz Wysokogórski',
    shortLabel: 'Obóz Górski',
    durationDays: 14,
    description:
        '14-dniowe zgrupowanie na Teide lub w Sierra Nevada: poprawa wspinaczki, regeneracji i aklimatyzacji.',
    accentColor: AppColors.accentBlue,
    icon: Icons.terrain_rounded,
  ),
  cobblesAndClassicsCamp(
    id: 'cobbles_classics_camp',
    displayName: 'Obóz Brukowy & Klasyki',
    shortLabel: 'Obóz Brukowy',
    durationDays: 10,
    description:
        '10-dniowy rekonesans sektorów bruku i trening jazdy w wachlarzach pod okiem mistrza Monumentów.',
    accentColor: AppColors.amberWarning,
    icon: Icons.route_rounded,
  ),
  timeTrialAeroCamp(
    id: 'tt_aero_camp',
    displayName: 'Obóz TT & Aerodynamika',
    shortLabel: 'Obóz TT/Aero',
    durationDays: 7,
    description:
        '7-dniowa sesja na torze i szosie: optymalizacja pozycji czasowej, rozkładu mocy i zakrętów.',
    accentColor: AppColors.cyanAccent,
    icon: Icons.speed_rounded,
  ),
  grandTourAdvisory(
    id: 'grand_tour_advisory',
    displayName: 'Doradztwo Wielkiego Touru',
    shortLabel: 'Wielki Tour',
    durationDays: 21,
    description:
        'Pełna obecność w wozie i autobusie na 21 etapów: spokój lidera, redukcja zmęczenia 3. tygodnia i prestiż medialny.',
    accentColor: AppColors.goldAccent,
    icon: Icons.emoji_events_rounded,
  );

  final String id;
  final String displayName;
  final String shortLabel;
  final int durationDays;
  final String description;
  final Color accentColor;
  final IconData icon;

  const LegendMentorAssignmentType({
    required this.id,
    required this.displayName,
    required this.shortLabel,
    required this.durationDays,
    required this.description,
    required this.accentColor,
    required this.icon,
  });

  static LegendMentorAssignmentType fromId(String id) {
    return LegendMentorAssignmentType.values.firstWhere(
      (e) => e.id == id,
      orElse: () => LegendMentorAssignmentType.grandTourAdvisory,
    );
  }
}

/// Specjalizacja mentorska legendy kolarstwa.
enum LegendMentorSpecialty {
  grandTourGc(
    id: 'grand_tour_gc',
    displayName: 'Wielkie Toury & GC',
    accentColor: AppColors.goldAccent,
  ),
  cobblesAndClassics(
    id: 'cobbles_classics',
    displayName: 'Bruk & Monumenty',
    accentColor: AppColors.amberWarning,
  ),
  timeTrialMastery(
    id: 'tt_mastery',
    displayName: 'Jazda na Czas & Aero',
    accentColor: AppColors.cyanAccent,
  ),
  alpineClimbing(
    id: 'alpine_climbing',
    displayName: 'Góry Wysokie & Ataki',
    accentColor: AppColors.accentBlue,
  ),
  tacticalCannibal(
    id: 'tactical_cannibal',
    displayName: 'Taktyka Totalna',
    accentColor: AppColors.primaryAccent,
  );

  final String id;
  final String displayName;
  final Color accentColor;

  const LegendMentorSpecialty({
    required this.id,
    required this.displayName,
    required this.accentColor,
  });

  static LegendMentorSpecialty fromId(String id) {
    return LegendMentorSpecialty.values.firstWhere(
      (e) => e.id == id,
      orElse: () => LegendMentorSpecialty.grandTourGc,
    );
  }
}

/// Bieżący status dostępności doradcy-legendy.
enum LegendMentorAvailabilityStatus {
  available(
    displayName: 'Dostępny',
    accentColor: AppColors.statusSuccess,
  ),
  hiredActive(
    displayName: 'W trakcie zlecenia',
    accentColor: AppColors.goldAccent,
  ),
  cooldown(
    displayName: 'Odpoczynek / Karencja',
    accentColor: AppColors.amberWarning,
  );

  final String displayName;
  final Color accentColor;

  const LegendMentorAvailabilityStatus({
    required this.displayName,
    required this.accentColor,
  });
}

/// Zestaw wymiernych premii zapewnianych przez legendę drużynie i kolarzom.
class LegendMentorBonusProfile {
  final int moraleBoost;
  final double raceIqBonus;
  final double climbingSkillBonus;
  final double timeTrialSkillBonus;
  final double cobblesSkillBonus;
  final double descendingSkillBonus;
  final double recoveryEfficiencyBonus;
  final double thirdWeekFatigueReduction;
  final int mediaPrestigeBonus;
  final double youthDevelopmentMultiplier;

  const LegendMentorBonusProfile({
    this.moraleBoost = 0,
    this.raceIqBonus = 0.0,
    this.climbingSkillBonus = 0.0,
    this.timeTrialSkillBonus = 0.0,
    this.cobblesSkillBonus = 0.0,
    this.descendingSkillBonus = 0.0,
    this.recoveryEfficiencyBonus = 0.0,
    this.thirdWeekFatigueReduction = 0.0,
    this.mediaPrestigeBonus = 0,
    this.youthDevelopmentMultiplier = 1.0,
  });

  /// Skaluje bazowe premie legendy pod konkretny typ obozu lub Wielkiego Touru.
  LegendMentorBonusProfile scaledForAssignment(
    LegendMentorAssignmentType type, {
    required bool isPreferred,
  }) {
    final synergy = isPreferred ? 1.20 : 1.0;
    switch (type) {
      case LegendMentorAssignmentType.altitudeCamp:
        return LegendMentorBonusProfile(
          moraleBoost: (moraleBoost * 0.7 * synergy).round(),
          raceIqBonus: _round2(raceIqBonus * 0.4 * synergy),
          climbingSkillBonus: _round2(climbingSkillBonus * 1.35 * synergy),
          timeTrialSkillBonus: _round2(timeTrialSkillBonus * 0.3 * synergy),
          cobblesSkillBonus: 0.0,
          descendingSkillBonus: _round2(descendingSkillBonus * 0.8 * synergy),
          recoveryEfficiencyBonus:
              _round3(recoveryEfficiencyBonus * 1.25 * synergy),
          thirdWeekFatigueReduction:
              _round3(thirdWeekFatigueReduction * 0.6 * synergy),
          mediaPrestigeBonus: (mediaPrestigeBonus * 0.4).round(),
          youthDevelopmentMultiplier:
              _round2(1.0 + (youthDevelopmentMultiplier - 1.0) * 1.2 * synergy),
        );
      case LegendMentorAssignmentType.cobblesAndClassicsCamp:
        return LegendMentorBonusProfile(
          moraleBoost: (moraleBoost * 0.75 * synergy).round(),
          raceIqBonus: _round2(raceIqBonus * 0.75 * synergy),
          climbingSkillBonus: 0.0,
          timeTrialSkillBonus: _round2(timeTrialSkillBonus * 0.25 * synergy),
          cobblesSkillBonus: _round2(cobblesSkillBonus * 1.4 * synergy),
          descendingSkillBonus: _round2(descendingSkillBonus * 0.6 * synergy),
          recoveryEfficiencyBonus:
              _round3(recoveryEfficiencyBonus * 0.7 * synergy),
          thirdWeekFatigueReduction: 0.0,
          mediaPrestigeBonus: (mediaPrestigeBonus * 0.5).round(),
          youthDevelopmentMultiplier:
              _round2(1.0 + (youthDevelopmentMultiplier - 1.0) * 1.15 * synergy),
        );
      case LegendMentorAssignmentType.timeTrialAeroCamp:
        return LegendMentorBonusProfile(
          moraleBoost: (moraleBoost * 0.6 * synergy).round(),
          raceIqBonus: _round2(raceIqBonus * 0.5 * synergy),
          climbingSkillBonus: 0.0,
          timeTrialSkillBonus: _round2(timeTrialSkillBonus * 1.4 * synergy),
          cobblesSkillBonus: 0.0,
          descendingSkillBonus: _round2(descendingSkillBonus * 0.4 * synergy),
          recoveryEfficiencyBonus:
              _round3(recoveryEfficiencyBonus * 0.5 * synergy),
          thirdWeekFatigueReduction: 0.0,
          mediaPrestigeBonus: (mediaPrestigeBonus * 0.45).round(),
          youthDevelopmentMultiplier:
              _round2(1.0 + (youthDevelopmentMultiplier - 1.0) * 1.1 * synergy),
        );
      case LegendMentorAssignmentType.grandTourAdvisory:
        return LegendMentorBonusProfile(
          moraleBoost: (moraleBoost * 1.25 * synergy).round(),
          raceIqBonus: _round2(raceIqBonus * 1.3 * synergy),
          climbingSkillBonus: _round2(climbingSkillBonus * 0.5 * synergy),
          timeTrialSkillBonus: _round2(timeTrialSkillBonus * 0.5 * synergy),
          cobblesSkillBonus: _round2(cobblesSkillBonus * 0.4 * synergy),
          descendingSkillBonus: _round2(descendingSkillBonus * 0.5 * synergy),
          recoveryEfficiencyBonus:
              _round3(recoveryEfficiencyBonus * 1.15 * synergy),
          thirdWeekFatigueReduction:
              _round3(thirdWeekFatigueReduction * 1.3 * synergy),
          mediaPrestigeBonus: (mediaPrestigeBonus * 1.25 * synergy).round(),
          youthDevelopmentMultiplier:
              _round2(1.0 + (youthDevelopmentMultiplier - 1.0) * 0.9 * synergy),
        );
    }
  }

  static double _round2(double v) => (v * 100).round() / 100.0;
  static double _round3(double v) => (v * 1000).round() / 1000.0;

  Map<String, dynamic> toJson() => {
        'moraleBoost': moraleBoost,
        'raceIqBonus': raceIqBonus,
        'climbingSkillBonus': climbingSkillBonus,
        'timeTrialSkillBonus': timeTrialSkillBonus,
        'cobblesSkillBonus': cobblesSkillBonus,
        'descendingSkillBonus': descendingSkillBonus,
        'recoveryEfficiencyBonus': recoveryEfficiencyBonus,
        'thirdWeekFatigueReduction': thirdWeekFatigueReduction,
        'mediaPrestigeBonus': mediaPrestigeBonus,
        'youthDevelopmentMultiplier': youthDevelopmentMultiplier,
      };

  factory LegendMentorBonusProfile.fromJson(Map<String, dynamic> json) {
    return LegendMentorBonusProfile(
      moraleBoost: (json['moraleBoost'] as num?)?.toInt() ?? 0,
      raceIqBonus: (json['raceIqBonus'] as num?)?.toDouble() ?? 0.0,
      climbingSkillBonus:
          (json['climbingSkillBonus'] as num?)?.toDouble() ?? 0.0,
      timeTrialSkillBonus:
          (json['timeTrialSkillBonus'] as num?)?.toDouble() ?? 0.0,
      cobblesSkillBonus: (json['cobblesSkillBonus'] as num?)?.toDouble() ?? 0.0,
      descendingSkillBonus:
          (json['descendingSkillBonus'] as num?)?.toDouble() ?? 0.0,
      recoveryEfficiencyBonus:
          (json['recoveryEfficiencyBonus'] as num?)?.toDouble() ?? 0.0,
      thirdWeekFatigueReduction:
          (json['thirdWeekFatigueReduction'] as num?)?.toDouble() ?? 0.0,
      mediaPrestigeBonus: (json['mediaPrestigeBonus'] as num?)?.toInt() ?? 0,
      youthDevelopmentMultiplier:
          (json['youthDevelopmentMultiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Profil byłej legendy kolarstwa dostępnej jako gościnny doradca.
class HistoricLegendGuestMentor {
  final String id;
  final String legendProfileId;
  final String name;
  final String nickname;
  final String nationalityIso;
  final CyclingEra era;
  final LegendMentorSpecialty specialty;
  final String signatureQuote;
  final String palmaresSummary;
  final int prestigeRating;
  final int dailyFeeEur;
  final int campPackageFeeEur;
  final int grandTourPackageFeeEur;
  final int cooldownDaysAfterStint;
  final LegendMentorBonusProfile baseBonuses;
  final List<LegendMentorAssignmentType> preferredAssignments;

  const HistoricLegendGuestMentor({
    required this.id,
    required this.legendProfileId,
    required this.name,
    required this.nickname,
    required this.nationalityIso,
    required this.era,
    required this.specialty,
    required this.signatureQuote,
    required this.palmaresSummary,
    required this.prestigeRating,
    required this.dailyFeeEur,
    required this.campPackageFeeEur,
    required this.grandTourPackageFeeEur,
    required this.cooldownDaysAfterStint,
    required this.baseBonuses,
    required this.preferredAssignments,
  });

  bool prefers(LegendMentorAssignmentType type) =>
      preferredAssignments.contains(type);

  /// Zwraca koszt pakietu zależny od wybranego typu zlecenia.
  int feeForAssignment(LegendMentorAssignmentType type) {
    switch (type) {
      case LegendMentorAssignmentType.altitudeCamp:
        return campPackageFeeEur;
      case LegendMentorAssignmentType.cobblesAndClassicsCamp:
        return (campPackageFeeEur * 0.85).round();
      case LegendMentorAssignmentType.timeTrialAeroCamp:
        return (campPackageFeeEur * 0.70).round();
      case LegendMentorAssignmentType.grandTourAdvisory:
        return grandTourPackageFeeEur;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'legendProfileId': legendProfileId,
        'name': name,
        'nickname': nickname,
        'nationalityIso': nationalityIso,
        'eraPeakYear': era == CyclingEra.goldenEra1960_1979
            ? 1972
            : era == CyclingEra.classicEra1980_1999
                ? 1990
                : 2010,
        'specialty': specialty.id,
        'signatureQuote': signatureQuote,
        'palmaresSummary': palmaresSummary,
        'prestigeRating': prestigeRating,
        'dailyFeeEur': dailyFeeEur,
        'campPackageFeeEur': campPackageFeeEur,
        'grandTourPackageFeeEur': grandTourPackageFeeEur,
        'cooldownDaysAfterStint': cooldownDaysAfterStint,
        'baseBonuses': baseBonuses.toJson(),
        'preferredAssignments':
            preferredAssignments.map((e) => e.id).toList(growable: false),
      };

  factory HistoricLegendGuestMentor.fromJson(Map<String, dynamic> json) {
    final peakYear = (json['eraPeakYear'] as num?)?.toInt() ?? 1990;
    final rawPrefs = json['preferredAssignments'] as List<dynamic>? ?? const [];
    return HistoricLegendGuestMentor(
      id: json['id'] as String? ?? '',
      legendProfileId: json['legendProfileId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      nationalityIso: json['nationalityIso'] as String? ?? 'INT',
      era: CyclingEra.fromPeakYear(peakYear),
      specialty:
          LegendMentorSpecialty.fromId(json['specialty'] as String? ?? ''),
      signatureQuote: json['signatureQuote'] as String? ?? '',
      palmaresSummary: json['palmaresSummary'] as String? ?? '',
      prestigeRating: (json['prestigeRating'] as num?)?.toInt() ?? 80,
      dailyFeeEur: (json['dailyFeeEur'] as num?)?.toInt() ?? 4000,
      campPackageFeeEur: (json['campPackageFeeEur'] as num?)?.toInt() ?? 45000,
      grandTourPackageFeeEur:
          (json['grandTourPackageFeeEur'] as num?)?.toInt() ?? 85000,
      cooldownDaysAfterStint:
          (json['cooldownDaysAfterStint'] as num?)?.toInt() ?? 14,
      baseBonuses: LegendMentorBonusProfile.fromJson(
        (json['baseBonuses'] as Map<String, dynamic>?) ?? const {},
      ),
      preferredAssignments: rawPrefs
          .map((e) => LegendMentorAssignmentType.fromId(e.toString()))
          .toList(growable: false),
    );
  }
}

/// Katalog emerytowanych legend peletonu możliwych do zakontraktowania.
class HistoricLegendMentorsCatalog {
  HistoricLegendMentorsCatalog._();

  static const List<HistoricLegendGuestMentor> mentors = [
    HistoricLegendGuestMentor(
      id: 'mentor_eddy_merckx',
      legendProfileId: 'legend_eddy_merckx',
      name: 'Eddy Merckx',
      nickname: 'Kanibal',
      nationalityIso: 'BEL',
      era: CyclingEra.goldenEra1960_1979,
      specialty: LegendMentorSpecialty.tacticalCannibal,
      signatureQuote:
          'Nie oszczędzaj się na jutro — jeśli dziś możesz złamać rywala, zrób to na pierwszym podjeździe.',
      palmaresSummary: '11× Wielki Tour GC • 19× Monument • 3× MŚ',
      prestigeRating: 99,
      dailyFeeEur: 6500,
      campPackageFeeEur: 75000,
      grandTourPackageFeeEur: 145000,
      cooldownDaysAfterStint: 21,
      baseBonuses: LegendMentorBonusProfile(
        moraleBoost: 10,
        raceIqBonus: 5.5,
        climbingSkillBonus: 2.2,
        timeTrialSkillBonus: 2.0,
        cobblesSkillBonus: 2.5,
        descendingSkillBonus: 2.0,
        recoveryEfficiencyBonus: 0.04,
        thirdWeekFatigueReduction: 0.11,
        mediaPrestigeBonus: 20,
        youthDevelopmentMultiplier: 1.35,
      ),
      preferredAssignments: [
        LegendMentorAssignmentType.grandTourAdvisory,
        LegendMentorAssignmentType.cobblesAndClassicsCamp,
      ],
    ),
    HistoricLegendGuestMentor(
      id: 'mentor_bernard_hinault',
      legendProfileId: 'legend_bernard_hinault',
      name: 'Bernard Hinault',
      nickname: 'Borsuk',
      nationalityIso: 'FRA',
      era: CyclingEra.classicEra1980_1999,
      specialty: LegendMentorSpecialty.grandTourGc,
      signatureQuote:
          'Dopóki oddycham, atakuję. W trzecim tygodniu wygrywa głowa twardsza niż asfalt.',
      palmaresSummary: '10× Wielki Tour GC • 5× Monument • MŚ 1980',
      prestigeRating: 96,
      dailyFeeEur: 5800,
      campPackageFeeEur: 64000,
      grandTourPackageFeeEur: 125000,
      cooldownDaysAfterStint: 18,
      baseBonuses: LegendMentorBonusProfile(
        moraleBoost: 9,
        raceIqBonus: 5.0,
        climbingSkillBonus: 2.4,
        timeTrialSkillBonus: 2.1,
        cobblesSkillBonus: 1.5,
        descendingSkillBonus: 1.6,
        recoveryEfficiencyBonus: 0.05,
        thirdWeekFatigueReduction: 0.14,
        mediaPrestigeBonus: 17,
        youthDevelopmentMultiplier: 1.30,
      ),
      preferredAssignments: [
        LegendMentorAssignmentType.grandTourAdvisory,
        LegendMentorAssignmentType.altitudeCamp,
      ],
    ),
    HistoricLegendGuestMentor(
      id: 'mentor_miguel_indurain',
      legendProfileId: 'legend_miguel_indurain',
      name: 'Miguel Induráin',
      nickname: 'Big Mig',
      nationalityIso: 'ESP',
      era: CyclingEra.classicEra1980_1999,
      specialty: LegendMentorSpecialty.timeTrialMastery,
      signatureQuote:
          'Stałe waty i zero nerwowych ruchów. Na czasówce zyskujesz minuty, w górach tylko ich pilnujesz.',
      palmaresSummary: '5× Tour de France • 2× Giro • Złoto IO ITT • MŚ ITT',
      prestigeRating: 95,
      dailyFeeEur: 5200,
      campPackageFeeEur: 58000,
      grandTourPackageFeeEur: 115000,
      cooldownDaysAfterStint: 16,
      baseBonuses: LegendMentorBonusProfile(
        moraleBoost: 7,
        raceIqBonus: 4.5,
        climbingSkillBonus: 1.8,
        timeTrialSkillBonus: 3.6,
        cobblesSkillBonus: 0.4,
        descendingSkillBonus: 1.2,
        recoveryEfficiencyBonus: 0.06,
        thirdWeekFatigueReduction: 0.12,
        mediaPrestigeBonus: 15,
        youthDevelopmentMultiplier: 1.28,
      ),
      preferredAssignments: [
        LegendMentorAssignmentType.timeTrialAeroCamp,
        LegendMentorAssignmentType.grandTourAdvisory,
      ],
    ),
    HistoricLegendGuestMentor(
      id: 'mentor_fausto_coppi',
      legendProfileId: 'legend_fausto_coppi',
      name: 'Fausto Coppi',
      nickname: 'Il Campionissimo',
      nationalityIso: 'ITA',
      era: CyclingEra.goldenEra1960_1979,
      specialty: LegendMentorSpecialty.alpineClimbing,
      signatureQuote:
          'Samotny odjazd na przełęczy powyżej 2000 metrów wymaga perfekcyjnego rytmu oddechu.',
      palmaresSummary: '5× Giro d\'Italia • 2× Tour de France • 9× Monument',
      prestigeRating: 95,
      dailyFeeEur: 5400,
      campPackageFeeEur: 62000,
      grandTourPackageFeeEur: 118000,
      cooldownDaysAfterStint: 18,
      baseBonuses: LegendMentorBonusProfile(
        moraleBoost: 8,
        raceIqBonus: 4.2,
        climbingSkillBonus: 3.5,
        timeTrialSkillBonus: 1.4,
        cobblesSkillBonus: 0.5,
        descendingSkillBonus: 2.3,
        recoveryEfficiencyBonus: 0.065,
        thirdWeekFatigueReduction: 0.11,
        mediaPrestigeBonus: 16,
        youthDevelopmentMultiplier: 1.32,
      ),
      preferredAssignments: [
        LegendMentorAssignmentType.altitudeCamp,
        LegendMentorAssignmentType.grandTourAdvisory,
      ],
    ),
    HistoricLegendGuestMentor(
      id: 'mentor_jacques_anquetil',
      legendProfileId: 'legend_jacques_anquetil',
      name: 'Jacques Anquetil',
      nickname: 'Monsieur Chrono',
      nationalityIso: 'FRA',
      era: CyclingEra.goldenEra1960_1979,
      specialty: LegendMentorSpecialty.timeTrialMastery,
      signatureQuote:
          'Elegancja pozycji aero i chłodna kalkulacja sekund są warte więcej niż tysiąc zbędnych ataków.',
      palmaresSummary: '8× Wielki Tour GC • 9× Grand Prix des Nations',
      prestigeRating: 93,
      dailyFeeEur: 4900,
      campPackageFeeEur: 54000,
      grandTourPackageFeeEur: 105000,
      cooldownDaysAfterStint: 14,
      baseBonuses: LegendMentorBonusProfile(
        moraleBoost: 6,
        raceIqBonus: 4.6,
        climbingSkillBonus: 1.5,
        timeTrialSkillBonus: 3.4,
        cobblesSkillBonus: 0.3,
        descendingSkillBonus: 1.4,
        recoveryEfficiencyBonus: 0.045,
        thirdWeekFatigueReduction: 0.09,
        mediaPrestigeBonus: 14,
        youthDevelopmentMultiplier: 1.24,
      ),
      preferredAssignments: [
        LegendMentorAssignmentType.timeTrialAeroCamp,
        LegendMentorAssignmentType.grandTourAdvisory,
      ],
    ),
    HistoricLegendGuestMentor(
      id: 'mentor_roger_de_vlaeminck',
      legendProfileId: 'legend_roger_de_vlaeminck',
      name: 'Roger De Vlaeminck',
      nickname: 'Monsieur Paris-Roubaix',
      nationalityIso: 'BEL',
      era: CyclingEra.goldenEra1960_1979,
      specialty: LegendMentorSpecialty.cobblesAndClassics,
      signatureQuote:
          'Na bruku nie trzymasz kierownicy kurczowo — płyniesz po koronie drogi i czytasz wiatr przed zakrętem.',
      palmaresSummary: '4× Paris-Roubaix • 11× Monument • 22× etap Giro',
      prestigeRating: 92,
      dailyFeeEur: 4600,
      campPackageFeeEur: 50000,
      grandTourPackageFeeEur: 92000,
      cooldownDaysAfterStint: 12,
      baseBonuses: LegendMentorBonusProfile(
        moraleBoost: 7,
        raceIqBonus: 4.4,
        climbingSkillBonus: 0.6,
        timeTrialSkillBonus: 1.0,
        cobblesSkillBonus: 3.8,
        descendingSkillBonus: 2.2,
        recoveryEfficiencyBonus: 0.035,
        thirdWeekFatigueReduction: 0.05,
        mediaPrestigeBonus: 13,
        youthDevelopmentMultiplier: 1.30,
      ),
      preferredAssignments: [
        LegendMentorAssignmentType.cobblesAndClassicsCamp,
      ],
    ),
    HistoricLegendGuestMentor(
      id: 'mentor_fabian_cancellara',
      legendProfileId: 'legend_fabian_cancellara',
      name: 'Fabian Cancellara',
      nickname: 'Spartakus',
      nationalityIso: 'SUI',
      era: CyclingEra.modernEra2000_2019,
      specialty: LegendMentorSpecialty.cobblesAndClassics,
      signatureQuote:
          'Kiedy przyspieszasz z siodła na Paterbergu przy 1100 W, cały peleton musi zostać z tyłu.',
      palmaresSummary: '7× Monument • 2× Złoto IO ITT • 4× MŚ ITT',
      prestigeRating: 94,
      dailyFeeEur: 5000,
      campPackageFeeEur: 56000,
      grandTourPackageFeeEur: 98000,
      cooldownDaysAfterStint: 14,
      baseBonuses: LegendMentorBonusProfile(
        moraleBoost: 8,
        raceIqBonus: 4.3,
        climbingSkillBonus: 0.7,
        timeTrialSkillBonus: 3.1,
        cobblesSkillBonus: 3.4,
        descendingSkillBonus: 2.4,
        recoveryEfficiencyBonus: 0.04,
        thirdWeekFatigueReduction: 0.06,
        mediaPrestigeBonus: 16,
        youthDevelopmentMultiplier: 1.34,
      ),
      preferredAssignments: [
        LegendMentorAssignmentType.cobblesAndClassicsCamp,
        LegendMentorAssignmentType.timeTrialAeroCamp,
      ],
    ),
    HistoricLegendGuestMentor(
      id: 'mentor_sean_kelly',
      legendProfileId: 'legend_sean_kelly',
      name: 'Sean Kelly',
      nickname: 'King Kelly',
      nationalityIso: 'IRL',
      era: CyclingEra.classicEra1980_1999,
      specialty: LegendMentorSpecialty.tacticalCannibal,
      signatureQuote:
          'Prawdziwy klasyk zaczyna się po 220 kilometrze w deszczu. Wtedy wygrywa ten, kto jeszcze potrafi myśleć.',
      palmaresSummary: 'Vuelta a España GC • 9× Monument • 4× Zielona Koszulka TdF',
      prestigeRating: 91,
      dailyFeeEur: 4400,
      campPackageFeeEur: 48000,
      grandTourPackageFeeEur: 90000,
      cooldownDaysAfterStint: 12,
      baseBonuses: LegendMentorBonusProfile(
        moraleBoost: 8,
        raceIqBonus: 4.8,
        climbingSkillBonus: 1.5,
        timeTrialSkillBonus: 1.4,
        cobblesSkillBonus: 2.8,
        descendingSkillBonus: 2.6,
        recoveryEfficiencyBonus: 0.05,
        thirdWeekFatigueReduction: 0.08,
        mediaPrestigeBonus: 12,
        youthDevelopmentMultiplier: 1.29,
      ),
      preferredAssignments: [
        LegendMentorAssignmentType.cobblesAndClassicsCamp,
        LegendMentorAssignmentType.grandTourAdvisory,
      ],
    ),
  ];
}

/// Aktywny kontrakt doradcy-legendy na obóz lub Wielki Tour.
class ActiveLegendMentorContract {
  final String contractId;
  final String mentorId;
  final String mentorName;
  final LegendMentorAssignmentType assignmentType;
  final String targetEventName;
  final int startDay;
  final int durationDays;
  final int totalFeeEur;
  final List<String> assignedRiderIds;
  final LegendMentorBonusProfile appliedBonuses;
  final int daysCompleted;

  const ActiveLegendMentorContract({
    required this.contractId,
    required this.mentorId,
    required this.mentorName,
    required this.assignmentType,
    required this.targetEventName,
    required this.startDay,
    required this.durationDays,
    required this.totalFeeEur,
    required this.assignedRiderIds,
    required this.appliedBonuses,
    this.daysCompleted = 0,
  });

  int get remainingDays => math.max(0, durationDays - daysCompleted);
  bool get isCompleted => daysCompleted >= durationDays;
  double get progressRatio =>
      durationDays <= 0 ? 1.0 : (daysCompleted / durationDays).clamp(0.0, 1.0);

  ActiveLegendMentorContract copyWith({
    int? daysCompleted,
  }) {
    return ActiveLegendMentorContract(
      contractId: contractId,
      mentorId: mentorId,
      mentorName: mentorName,
      assignmentType: assignmentType,
      targetEventName: targetEventName,
      startDay: startDay,
      durationDays: durationDays,
      totalFeeEur: totalFeeEur,
      assignedRiderIds: assignedRiderIds,
      appliedBonuses: appliedBonuses,
      daysCompleted: daysCompleted ?? this.daysCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'contractId': contractId,
        'mentorId': mentorId,
        'mentorName': mentorName,
        'assignmentType': assignmentType.id,
        'targetEventName': targetEventName,
        'startDay': startDay,
        'durationDays': durationDays,
        'totalFeeEur': totalFeeEur,
        'assignedRiderIds': assignedRiderIds,
        'appliedBonuses': appliedBonuses.toJson(),
        'daysCompleted': daysCompleted,
      };

  factory ActiveLegendMentorContract.fromJson(Map<String, dynamic> json) {
    return ActiveLegendMentorContract(
      contractId: json['contractId'] as String? ?? '',
      mentorId: json['mentorId'] as String? ?? '',
      mentorName: json['mentorName'] as String? ?? '',
      assignmentType: LegendMentorAssignmentType.fromId(
        json['assignmentType'] as String? ?? '',
      ),
      targetEventName: json['targetEventName'] as String? ?? '',
      startDay: (json['startDay'] as num?)?.toInt() ?? 1,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 14,
      totalFeeEur: (json['totalFeeEur'] as num?)?.toInt() ?? 0,
      assignedRiderIds: (json['assignedRiderIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      appliedBonuses: LegendMentorBonusProfile.fromJson(
        (json['appliedBonuses'] as Map<String, dynamic>?) ?? const {},
      ),
      daysCompleted: (json['daysCompleted'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Wpis archiwalny zakończonej współpracy z legendą.
class LegendMentorHistoryEntry {
  final String contractId;
  final String mentorId;
  final String mentorName;
  final LegendMentorAssignmentType assignmentType;
  final String targetEventName;
  final int completedDay;
  final int totalFeeEur;
  final String impactSummary;

  const LegendMentorHistoryEntry({
    required this.contractId,
    required this.mentorId,
    required this.mentorName,
    required this.assignmentType,
    required this.targetEventName,
    required this.completedDay,
    required this.totalFeeEur,
    required this.impactSummary,
  });

  Map<String, dynamic> toJson() => {
        'contractId': contractId,
        'mentorId': mentorId,
        'mentorName': mentorName,
        'assignmentType': assignmentType.id,
        'targetEventName': targetEventName,
        'completedDay': completedDay,
        'totalFeeEur': totalFeeEur,
        'impactSummary': impactSummary,
      };

  factory LegendMentorHistoryEntry.fromJson(Map<String, dynamic> json) {
    return LegendMentorHistoryEntry(
      contractId: json['contractId'] as String? ?? '',
      mentorId: json['mentorId'] as String? ?? '',
      mentorName: json['mentorName'] as String? ?? '',
      assignmentType: LegendMentorAssignmentType.fromId(
        json['assignmentType'] as String? ?? '',
      ),
      targetEventName: json['targetEventName'] as String? ?? '',
      completedDay: (json['completedDay'] as num?)?.toInt() ?? 1,
      totalFeeEur: (json['totalFeeEur'] as num?)?.toInt() ?? 0,
      impactSummary: json['impactSummary'] as String? ?? '',
    );
  }
}

/// Wynik walidacji i zawarcia kontraktu z legendą.
class LegendMentorHireResult {
  final bool success;
  final String message;
  final ActiveLegendMentorContract? contract;
  final int remainingBudgetEur;

  const LegendMentorHireResult({
    required this.success,
    required this.message,
    this.contract,
    required this.remainingBudgetEur,
  });
}

/// Zagregowane modyfikatory wszystkich aktywnych doradców w drużynie.
class TeamLegendMentorAggregateBuffs {
  final int activeMentorsCount;
  final int totalMoraleBoost;
  final double totalRaceIqBonus;
  final double totalClimbingBonus;
  final double totalTimeTrialBonus;
  final double totalCobblesBonus;
  final double totalDescendingBonus;
  final double totalRecoveryEfficiencyBonus;
  final double totalThirdWeekFatigueReduction;
  final int totalMediaPrestigeBonus;
  final double effectiveYouthMultiplier;

  const TeamLegendMentorAggregateBuffs({
    required this.activeMentorsCount,
    required this.totalMoraleBoost,
    required this.totalRaceIqBonus,
    required this.totalClimbingBonus,
    required this.totalTimeTrialBonus,
    required this.totalCobblesBonus,
    required this.totalDescendingBonus,
    required this.totalRecoveryEfficiencyBonus,
    required this.totalThirdWeekFatigueReduction,
    required this.totalMediaPrestigeBonus,
    required this.effectiveYouthMultiplier,
  });

  static const TeamLegendMentorAggregateBuffs empty =
      TeamLegendMentorAggregateBuffs(
    activeMentorsCount: 0,
    totalMoraleBoost: 0,
    totalRaceIqBonus: 0,
    totalClimbingBonus: 0,
    totalTimeTrialBonus: 0,
    totalCobblesBonus: 0,
    totalDescendingBonus: 0,
    totalRecoveryEfficiencyBonus: 0,
    totalThirdWeekFatigueReduction: 0,
    totalMediaPrestigeBonus: 0,
    effectiveYouthMultiplier: 1.0,
  );
}

/// Serwis domenowy zarządzający zatrudnianiem Legend Kolarstwa jako doradców.
class HistoricLegendGuestMentorsService {
  const HistoricLegendGuestMentorsService();

  List<HistoricLegendGuestMentor> get allMentors =>
      HistoricLegendMentorsCatalog.mentors;

  HistoricLegendGuestMentor? getMentorById(String id) {
    for (final mentor in allMentors) {
      if (mentor.id == id) return mentor;
    }
    return null;
  }

  LegendMentorAvailabilityStatus getMentorAvailability({
    required String mentorId,
    required int currentDay,
    required List<ActiveLegendMentorContract> activeContracts,
    required Map<String, int> cooldownUntilDayByMentor,
  }) {
    if (activeContracts.any((c) => c.mentorId == mentorId && !c.isCompleted)) {
      return LegendMentorAvailabilityStatus.hiredActive;
    }
    final cooldownUntil = cooldownUntilDayByMentor[mentorId] ?? 0;
    if (cooldownUntil > currentDay) {
      return LegendMentorAvailabilityStatus.cooldown;
    }
    return LegendMentorAvailabilityStatus.available;
  }

  int remainingCooldownDays({
    required String mentorId,
    required int currentDay,
    required Map<String, int> cooldownUntilDayByMentor,
  }) {
    final until = cooldownUntilDayByMentor[mentorId] ?? 0;
    return math.max(0, until - currentDay);
  }

  String? evaluateHireBlocker({
    required HistoricLegendGuestMentor mentor,
    required LegendMentorAssignmentType assignmentType,
    required int teamBudgetEur,
    required int currentDay,
    required List<ActiveLegendMentorContract> activeContracts,
    required Map<String, int> cooldownUntilDayByMentor,
    required int maxConcurrentMentors,
    required String targetEventName,
  }) {
    if (targetEventName.trim().isEmpty) {
      return 'Podaj nazwę obozu lub Wielkiego Touru.';
    }
    final status = getMentorAvailability(
      mentorId: mentor.id,
      currentDay: currentDay,
      activeContracts: activeContracts,
      cooldownUntilDayByMentor: cooldownUntilDayByMentor,
    );
    if (status == LegendMentorAvailabilityStatus.hiredActive) {
      return '${mentor.name} realizuje już aktywne zlecenie dla drużyny.';
    }
    if (status == LegendMentorAvailabilityStatus.cooldown) {
      final left = remainingCooldownDays(
        mentorId: mentor.id,
        currentDay: currentDay,
        cooldownUntilDayByMentor: cooldownUntilDayByMentor,
      );
      return '${mentor.name} jest w okresie karencji (pozostało $left dni).';
    }
    final activeCount = activeContracts.where((c) => !c.isCompleted).length;
    if (activeCount >= maxConcurrentMentors) {
      return 'Osiągnięto limit jednoczesnych doradców ($maxConcurrentMentors).';
    }
    final fee = mentor.feeForAssignment(assignmentType);
    if (teamBudgetEur < fee) {
      return 'Niewystarczający budżet drużyny (wymagane €${_formatInt(fee)}).';
    }
    return null;
  }

  LegendMentorHireResult hireMentor({
    required HistoricLegendGuestMentor mentor,
    required LegendMentorAssignmentType assignmentType,
    required String targetEventName,
    required int teamBudgetEur,
    required int currentDay,
    required List<ActiveLegendMentorContract> activeContracts,
    required Map<String, int> cooldownUntilDayByMentor,
    int maxConcurrentMentors = 2,
    List<String> assignedRiderIds = const [],
  }) {
    final trimmedEvent = targetEventName.trim();
    final blocker = evaluateHireBlocker(
      mentor: mentor,
      assignmentType: assignmentType,
      teamBudgetEur: teamBudgetEur,
      currentDay: currentDay,
      activeContracts: activeContracts,
      cooldownUntilDayByMentor: cooldownUntilDayByMentor,
      maxConcurrentMentors: maxConcurrentMentors,
      targetEventName: trimmedEvent,
    );
    if (blocker != null) {
      return LegendMentorHireResult(
        success: false,
        message: blocker,
        remainingBudgetEur: teamBudgetEur,
      );
    }

    final fee = mentor.feeForAssignment(assignmentType);
    final scaledBonuses = mentor.baseBonuses.scaledForAssignment(
      assignmentType,
      isPreferred: mentor.prefers(assignmentType),
    );
    final contract = ActiveLegendMentorContract(
      contractId: 'mentor_contract_${mentor.id}_d$currentDay',
      mentorId: mentor.id,
      mentorName: mentor.name,
      assignmentType: assignmentType,
      targetEventName: trimmedEvent,
      startDay: currentDay,
      durationDays: assignmentType.durationDays,
      totalFeeEur: fee,
      assignedRiderIds: List<String>.unmodifiable(assignedRiderIds),
      appliedBonuses: scaledBonuses,
      daysCompleted: 0,
    );

    return LegendMentorHireResult(
      success: true,
      message:
          'Zakontraktowano ${mentor.name} („${mentor.nickname}”) na ${assignmentType.displayName}: $trimmedEvent.',
      contract: contract,
      remainingBudgetEur: teamBudgetEur - fee,
    );
  }

  /// Oblicza zsumowane premie aktywnych legend z miękkim limitem zapobiegającym kumulacji ponad realizm.
  TeamLegendMentorAggregateBuffs computeAggregateBuffs(
    List<ActiveLegendMentorContract> activeContracts,
  ) {
    final running =
        activeContracts.where((c) => !c.isCompleted).toList(growable: false);
    if (running.isEmpty) {
      return TeamLegendMentorAggregateBuffs.empty;
    }

    var morale = 0;
    var raceIq = 0.0;
    var climbing = 0.0;
    var tt = 0.0;
    var cobbles = 0.0;
    var descending = 0.0;
    var recovery = 0.0;
    var thirdWeek = 0.0;
    var media = 0;
    var youth = 1.0;

    for (final c in running) {
      final b = c.appliedBonuses;
      morale += b.moraleBoost;
      raceIq += b.raceIqBonus;
      climbing += b.climbingSkillBonus;
      tt += b.timeTrialSkillBonus;
      cobbles += b.cobblesSkillBonus;
      descending += b.descendingSkillBonus;
      recovery += b.recoveryEfficiencyBonus;
      thirdWeek += b.thirdWeekFatigueReduction;
      media += b.mediaPrestigeBonus;
      youth += math.max(0.0, b.youthDevelopmentMultiplier - 1.0);
    }

    return TeamLegendMentorAggregateBuffs(
      activeMentorsCount: running.length,
      totalMoraleBoost: morale.clamp(0, 20),
      totalRaceIqBonus: math.min(10.0, raceIq),
      totalClimbingBonus: math.min(6.0, climbing),
      totalTimeTrialBonus: math.min(6.0, tt),
      totalCobblesBonus: math.min(6.0, cobbles),
      totalDescendingBonus: math.min(5.0, descending),
      totalRecoveryEfficiencyBonus: math.min(0.15, recovery),
      totalThirdWeekFatigueReduction: math.min(0.25, thirdWeek),
      totalMediaPrestigeBonus: media.clamp(0, 35),
      effectiveYouthMultiplier: math.min(1.65, youth),
    );
  }

  static String _formatInt(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final revIdx = s.length - i;
      buf.write(s[i]);
      if (revIdx > 1 && revIdx % 3 == 1) {
        buf.write(' ');
      }
    }
    return buf.toString();
  }
}

/// Stan modułu zatrudniania Legend Kolarstwa jako doradców.
class HistoricLegendGuestMentorsState {
  final int currentDay;
  final int teamBudgetEur;
  final int maxConcurrentMentors;
  final LegendMentorSpecialty? selectedSpecialtyFilter;
  final LegendMentorAssignmentType selectedAssignmentType;
  final String selectedMentorId;
  final List<ActiveLegendMentorContract> activeContracts;
  final Map<String, int> cooldownUntilDayByMentor;
  final List<LegendMentorHistoryEntry> history;
  final String? lastStatusMessage;
  final bool lastActionWasError;

  const HistoricLegendGuestMentorsState({
    this.currentDay = 120,
    this.teamBudgetEur = 420000,
    this.maxConcurrentMentors = 2,
    this.selectedSpecialtyFilter,
    this.selectedAssignmentType = LegendMentorAssignmentType.grandTourAdvisory,
    this.selectedMentorId = 'mentor_eddy_merckx',
    this.activeContracts = const [],
    this.cooldownUntilDayByMentor = const {},
    this.history = const [],
    this.lastStatusMessage,
    this.lastActionWasError = false,
  });

  HistoricLegendGuestMentorsState copyWith({
    int? currentDay,
    int? teamBudgetEur,
    int? maxConcurrentMentors,
    LegendMentorSpecialty? selectedSpecialtyFilter,
    bool clearSpecialtyFilter = false,
    LegendMentorAssignmentType? selectedAssignmentType,
    String? selectedMentorId,
    List<ActiveLegendMentorContract>? activeContracts,
    Map<String, int>? cooldownUntilDayByMentor,
    List<LegendMentorHistoryEntry>? history,
    String? lastStatusMessage,
    bool clearStatusMessage = false,
    bool? lastActionWasError,
  }) {
    return HistoricLegendGuestMentorsState(
      currentDay: currentDay ?? this.currentDay,
      teamBudgetEur: teamBudgetEur ?? this.teamBudgetEur,
      maxConcurrentMentors: maxConcurrentMentors ?? this.maxConcurrentMentors,
      selectedSpecialtyFilter: clearSpecialtyFilter
          ? null
          : (selectedSpecialtyFilter ?? this.selectedSpecialtyFilter),
      selectedAssignmentType:
          selectedAssignmentType ?? this.selectedAssignmentType,
      selectedMentorId: selectedMentorId ?? this.selectedMentorId,
      activeContracts: activeContracts ?? this.activeContracts,
      cooldownUntilDayByMentor:
          cooldownUntilDayByMentor ?? this.cooldownUntilDayByMentor,
      history: history ?? this.history,
      lastStatusMessage: clearStatusMessage
          ? null
          : (lastStatusMessage ?? this.lastStatusMessage),
      lastActionWasError: lastActionWasError ?? this.lastActionWasError,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentDay': currentDay,
        'teamBudgetEur': teamBudgetEur,
        'maxConcurrentMentors': maxConcurrentMentors,
        'selectedSpecialtyFilter': selectedSpecialtyFilter?.id,
        'selectedAssignmentType': selectedAssignmentType.id,
        'selectedMentorId': selectedMentorId,
        'activeContracts':
            activeContracts.map((e) => e.toJson()).toList(growable: false),
        'cooldownUntilDayByMentor': cooldownUntilDayByMentor,
        'history': history.map((e) => e.toJson()).toList(growable: false),
      };

  factory HistoricLegendGuestMentorsState.fromJson(Map<String, dynamic> json) {
    final filterId = json['selectedSpecialtyFilter'] as String?;
    final rawCooldowns =
        json['cooldownUntilDayByMentor'] as Map<String, dynamic>? ?? const {};
    return HistoricLegendGuestMentorsState(
      currentDay: (json['currentDay'] as num?)?.toInt() ?? 120,
      teamBudgetEur: (json['teamBudgetEur'] as num?)?.toInt() ?? 420000,
      maxConcurrentMentors:
          (json['maxConcurrentMentors'] as num?)?.toInt() ?? 2,
      selectedSpecialtyFilter: filterId == null || filterId.isEmpty
          ? null
          : LegendMentorSpecialty.fromId(filterId),
      selectedAssignmentType: LegendMentorAssignmentType.fromId(
        json['selectedAssignmentType'] as String? ?? '',
      ),
      selectedMentorId:
          json['selectedMentorId'] as String? ?? 'mentor_eddy_merckx',
      activeContracts: (json['activeContracts'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ActiveLegendMentorContract.fromJson)
          .toList(growable: false),
      cooldownUntilDayByMentor: rawCooldowns.map(
        (k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0),
      ),
      history: (json['history'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LegendMentorHistoryEntry.fromJson)
          .toList(growable: false),
    );
  }
}

/// Kontroler Riverpod zarządzający zatrudnianiem i postępem zleceń legend.
class HistoricLegendGuestMentorsNotifier
    extends StateNotifier<HistoricLegendGuestMentorsState> {
  final HistoricLegendGuestMentorsService _service;

  HistoricLegendGuestMentorsNotifier({
    HistoricLegendGuestMentorsService service =
        const HistoricLegendGuestMentorsService(),
    HistoricLegendGuestMentorsState? initialState,
  })  : _service = service,
        super(initialState ?? const HistoricLegendGuestMentorsState());

  void selectSpecialtyFilter(LegendMentorSpecialty? filter) {
    if (filter == null) {
      state = state.copyWith(clearSpecialtyFilter: true);
    } else {
      state = state.copyWith(selectedSpecialtyFilter: filter);
    }
  }

  void selectAssignmentType(LegendMentorAssignmentType type) {
    state = state.copyWith(
      selectedAssignmentType: type,
      clearStatusMessage: true,
    );
  }

  void selectMentor(String mentorId) {
    state = state.copyWith(
      selectedMentorId: mentorId,
      clearStatusMessage: true,
    );
  }

  void setBudget(int budgetEur) {
    state = state.copyWith(teamBudgetEur: math.max(0, budgetEur));
  }

  LegendMentorHireResult hireSelectedMentor({
    required String targetEventName,
    List<String> assignedRiderIds = const [],
  }) {
    final mentor = _service.getMentorById(state.selectedMentorId);
    if (mentor == null) {
      const result = LegendMentorHireResult(
        success: false,
        message: 'Nie znaleziono wybranej legendy w katalogu.',
        remainingBudgetEur: 0,
      );
      state = state.copyWith(
        lastStatusMessage: result.message,
        lastActionWasError: true,
      );
      return result;
    }

    final result = _service.hireMentor(
      mentor: mentor,
      assignmentType: state.selectedAssignmentType,
      targetEventName: targetEventName,
      teamBudgetEur: state.teamBudgetEur,
      currentDay: state.currentDay,
      activeContracts: state.activeContracts,
      cooldownUntilDayByMentor: state.cooldownUntilDayByMentor,
      maxConcurrentMentors: state.maxConcurrentMentors,
      assignedRiderIds: assignedRiderIds,
    );

    if (!result.success || result.contract == null) {
      state = state.copyWith(
        lastStatusMessage: result.message,
        lastActionWasError: true,
      );
      return result;
    }

    state = state.copyWith(
      teamBudgetEur: result.remainingBudgetEur,
      activeContracts: [...state.activeContracts, result.contract!],
      lastStatusMessage: result.message,
      lastActionWasError: false,
    );
    return result;
  }

  void cancelActiveContract(String contractId) {
    final idx =
        state.activeContracts.indexWhere((c) => c.contractId == contractId);
    if (idx < 0) return;
    final contract = state.activeContracts[idx];
    final ratioRemaining = contract.durationDays <= 0
        ? 0.0
        : (contract.remainingDays / contract.durationDays).clamp(0.0, 1.0);
    final refund = (contract.totalFeeEur * ratioRemaining * 0.5).round();

    final updated = List<ActiveLegendMentorContract>.from(state.activeContracts)
      ..removeAt(idx);
    final updatedCooldowns =
        Map<String, int>.from(state.cooldownUntilDayByMentor);
    updatedCooldowns[contract.mentorId] = state.currentDay + 7;

    state = state.copyWith(
      teamBudgetEur: state.teamBudgetEur + refund,
      activeContracts: updated,
      cooldownUntilDayByMentor: updatedCooldowns,
      lastStatusMessage:
          'Rozwiązano kontrakt z ${contract.mentorName}. Zwrot budżetu: €${HistoricLegendGuestMentorsService._formatInt(refund)}.',
      lastActionWasError: false,
    );
  }

  void advanceDay({int days = 1}) {
    final steps = math.max(1, days);
    var day = state.currentDay;
    var contracts = List<ActiveLegendMentorContract>.from(state.activeContracts);
    final cooldowns = Map<String, int>.from(state.cooldownUntilDayByMentor);
    final history = List<LegendMentorHistoryEntry>.from(state.history);
    final completedNames = <String>[];

    for (var s = 0; s < steps; s++) {
      day += 1;
      final stillActive = <ActiveLegendMentorContract>[];
      for (final c in contracts) {
        final advanced = c.copyWith(daysCompleted: c.daysCompleted + 1);
        if (advanced.isCompleted) {
          final mentor = _service.getMentorById(advanced.mentorId);
          final cdDays = mentor?.cooldownDaysAfterStint ?? 14;
          cooldowns[advanced.mentorId] = day + cdDays;
          history.insert(
            0,
            LegendMentorHistoryEntry(
              contractId: advanced.contractId,
              mentorId: advanced.mentorId,
              mentorName: advanced.mentorName,
              assignmentType: advanced.assignmentType,
              targetEventName: advanced.targetEventName,
              completedDay: day,
              totalFeeEur: advanced.totalFeeEur,
              impactSummary:
                  'Morale +${advanced.appliedBonuses.moraleBoost}, Race IQ +${advanced.appliedBonuses.raceIqBonus.toStringAsFixed(1)}, Prestiż +${advanced.appliedBonuses.mediaPrestigeBonus}',
            ),
          );
          completedNames.add(advanced.mentorName);
        } else {
          stillActive.add(advanced);
        }
      }
      contracts = stillActive;
    }

    state = state.copyWith(
      currentDay: day,
      activeContracts: contracts,
      cooldownUntilDayByMentor: cooldowns,
      history: history,
      lastStatusMessage: completedNames.isEmpty
          ? null
          : 'Zakończono zlecenie: ${completedNames.join(', ')}.',
      lastActionWasError: false,
    );
  }
}

final historicLegendGuestMentorsProvider = StateNotifierProvider<
    HistoricLegendGuestMentorsNotifier, HistoricLegendGuestMentorsState>(
  (ref) => HistoricLegendGuestMentorsNotifier(),
);

/// Produkcyjny panel UI do przeglądania, filtrowania i zatrudniania byłych Legend Kolarstwa.
class HistoricLegendGuestMentorsPanel extends ConsumerStatefulWidget {
  const HistoricLegendGuestMentorsPanel({super.key});

  @override
  ConsumerState<HistoricLegendGuestMentorsPanel> createState() =>
      _HistoricLegendGuestMentorsPanelState();
}

class _HistoricLegendGuestMentorsPanelState
    extends ConsumerState<HistoricLegendGuestMentorsPanel> {
  static const HistoricLegendGuestMentorsService _service =
      HistoricLegendGuestMentorsService();
  late final TextEditingController _eventNameController;

  @override
  void initState() {
    super.initState();
    _eventNameController = TextEditingController(
      text: _defaultEventFor(LegendMentorAssignmentType.grandTourAdvisory),
    );
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    super.dispose();
  }

  static String _defaultEventFor(LegendMentorAssignmentType type) {
    switch (type) {
      case LegendMentorAssignmentType.altitudeCamp:
        return 'Obóz Wysokogórski Teide';
      case LegendMentorAssignmentType.cobblesAndClassicsCamp:
        return 'Rekonesans Flandria & Roubaix';
      case LegendMentorAssignmentType.timeTrialAeroCamp:
        return 'Sesja Aero & Chrono';
      case LegendMentorAssignmentType.grandTourAdvisory:
        return 'Tour de France';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historicLegendGuestMentorsProvider);
    final notifier = ref.read(historicLegendGuestMentorsProvider.notifier);
    final buffs = _service.computeAggregateBuffs(state.activeContracts);

    final filteredMentors = HistoricLegendMentorsCatalog.mentors.where((m) {
      if (state.selectedSpecialtyFilter == null) return true;
      return m.specialty == state.selectedSpecialtyFilter;
    }).toList(growable: false);

    final selectedMentor = _service.getMentorById(state.selectedMentorId) ??
        HistoricLegendMentorsCatalog.mentors.first;

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1120;
          final isTablet =
              constraints.maxWidth >= 700 && constraints.maxWidth < 1120;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(state, buffs, notifier, isCompact: !isDesktop && !isTablet),
                const SizedBox(height: 16),
                if (state.lastStatusMessage != null) ...[
                  _buildStatusBanner(
                    state.lastStatusMessage!,
                    isError: state.lastActionWasError,
                  ),
                  const SizedBox(height: 16),
                ],
                _buildFilterBar(state, notifier),
                const SizedBox(height: 16),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildMentorsGrid(
                          filteredMentors,
                          state,
                          notifier,
                          columns: 2,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _buildDetailAndHireCard(
                              selectedMentor,
                              state,
                              notifier,
                            ),
                            const SizedBox(height: 16),
                            _buildActiveContractsCard(state, notifier),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildMentorsGrid(
                    filteredMentors,
                    state,
                    notifier,
                    columns: isTablet ? 2 : 1,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailAndHireCard(selectedMentor, state, notifier),
                  const SizedBox(height: 16),
                  _buildActiveContractsCard(state, notifier),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    HistoricLegendGuestMentorsState state,
    TeamLegendMentorAggregateBuffs buffs,
    HistoricLegendGuestMentorsNotifier notifier, {
    required bool isCompact,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCompact) ...[
            _buildHeaderTitleRow(isCompact: true),
            const SizedBox(height: 12),
            _buildHeaderMetricsWrap(state, buffs, notifier),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _buildHeaderTitleRow(isCompact: false)),
                const SizedBox(width: 16),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _buildHeaderMetricsWrap(state, buffs, notifier),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _BuffBadge(
                label: 'Morale',
                value: '+${buffs.totalMoraleBoost}',
                color: AppColors.statusSuccess,
              ),
              _BuffBadge(
                label: 'Race IQ',
                value: '+${buffs.totalRaceIqBonus.toStringAsFixed(1)}',
                color: AppColors.accentBlue,
              ),
              _BuffBadge(
                label: '3. Tydzień GT',
                value:
                    '-${(buffs.totalThirdWeekFatigueReduction * 100).round()}% zmęcz.',
                color: AppColors.goldAccent,
              ),
              _BuffBadge(
                label: 'Regeneracja',
                value:
                    '+${(buffs.totalRecoveryEfficiencyBonus * 100).toStringAsFixed(1)}%',
                color: AppColors.cyanAccent,
              ),
              _BuffBadge(
                label: 'Prestiż TV',
                value: '+${buffs.totalMediaPrestigeBonus}',
                color: AppColors.primaryAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTitleRow({required bool isCompact}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.goldAccent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.4),
            ),
          ),
          child: const Icon(
            Icons.military_tech_rounded,
            color: AppColors.goldAccent,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Doradcy & Legendy Kolarstwa',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Zatrudnij ikony peletonu na obozy wysokogórskie, klasyki i Wielkie Toury',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 12 : 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderMetricsWrap(
    HistoricLegendGuestMentorsState state,
    TeamLegendMentorAggregateBuffs buffs,
    HistoricLegendGuestMentorsNotifier notifier,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MetricPill(
          label: 'Budżet',
          value:
              '€${HistoricLegendGuestMentorsService._formatInt(state.teamBudgetEur)}',
          accent: AppColors.statusSuccess,
        ),
        _MetricPill(
          label: 'Dzień sezonu',
          value: 'Dzień ${state.currentDay}',
          accent: AppColors.accentBlue,
        ),
        _MetricPill(
          label: 'Aktywni',
          value: '${buffs.activeMentorsCount}/${state.maxConcurrentMentors}',
          accent: AppColors.goldAccent,
        ),
        _InteractiveActionButton(
          label: '+1 Dzień',
          icon: Icons.fast_forward_rounded,
          onPressed: () => notifier.advanceDay(days: 1),
          isSecondary: true,
        ),
      ],
    );
  }

  Widget _buildStatusBanner(String message, {required bool isError}) {
    final color = isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    HistoricLegendGuestMentorsState state,
    HistoricLegendGuestMentorsNotifier notifier,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChipButton(
          label: 'Wszystkie Legendy',
          selected: state.selectedSpecialtyFilter == null,
          accentColor: AppColors.goldAccent,
          onTap: () => notifier.selectSpecialtyFilter(null),
        ),
        for (final specialty in LegendMentorSpecialty.values)
          _FilterChipButton(
            label: specialty.displayName,
            selected: state.selectedSpecialtyFilter == specialty,
            accentColor: specialty.accentColor,
            onTap: () => notifier.selectSpecialtyFilter(specialty),
          ),
      ],
    );
  }

  Widget _buildMentorsGrid(
    List<HistoricLegendGuestMentor> mentors,
    HistoricLegendGuestMentorsState state,
    HistoricLegendGuestMentorsNotifier notifier, {
    required int columns,
  }) {
    if (mentors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: Text(
            'Brak legend spełniających wybrane kryterium specjalizacji.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    if (columns == 1) {
      return Column(
        children: [
          for (var i = 0; i < mentors.length; i++) ...[
            _buildMentorCard(mentors[i], state, notifier),
            if (i < mentors.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < mentors.length; i += columns) {
      final rowItems = mentors.skip(i).take(columns).toList(growable: false);
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < columns; j++) ...[
                Expanded(
                  child: j < rowItems.length
                      ? _buildMentorCard(rowItems[j], state, notifier)
                      : const SizedBox.shrink(),
                ),
                if (j < columns - 1) const SizedBox(width: 12),
              ],
            ],
          ),
        ),
      );
      if (i + columns < mentors.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    return Column(children: rows);
  }

  Widget _buildMentorCard(
    HistoricLegendGuestMentor mentor,
    HistoricLegendGuestMentorsState state,
    HistoricLegendGuestMentorsNotifier notifier,
  ) {
    final isSelected = mentor.id == state.selectedMentorId;
    final availability = _service.getMentorAvailability(
      mentorId: mentor.id,
      currentDay: state.currentDay,
      activeContracts: state.activeContracts,
      cooldownUntilDayByMentor: state.cooldownUntilDayByMentor,
    );
    final cooldownLeft = _service.remainingCooldownDays(
      mentorId: mentor.id,
      currentDay: state.currentDay,
      cooldownUntilDayByMentor: state.cooldownUntilDayByMentor,
    );
    final fee = mentor.feeForAssignment(state.selectedAssignmentType);

    return _InteractiveCard(
      isSelected: isSelected,
      accentColor: mentor.specialty.accentColor,
      onTap: () => notifier.selectMentor(mentor.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  mentor.nationalityIso,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mentor.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: availability.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  cooldownLeft > 0
                      ? 'Karencja ${cooldownLeft}d'
                      : availability.displayName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: availability.accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '„${mentor.nickname}” • ${mentor.specialty.displayName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: mentor.specialty.accentColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            mentor.palmaresSummary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prestiż ${mentor.prestigeRating}/100',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.goldAccent,
                ),
              ),
              Text(
                '€${HistoricLegendGuestMentorsService._formatInt(fee)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailAndHireCard(
    HistoricLegendGuestMentor mentor,
    HistoricLegendGuestMentorsState state,
    HistoricLegendGuestMentorsNotifier notifier,
  ) {
    final assignment = state.selectedAssignmentType;
    final scaled = mentor.baseBonuses.scaledForAssignment(
      assignment,
      isPreferred: mentor.prefers(assignment),
    );
    final fee = mentor.feeForAssignment(assignment);
    final blocker = _service.evaluateHireBlocker(
      mentor: mentor,
      assignmentType: assignment,
      teamBudgetEur: state.teamBudgetEur,
      currentDay: state.currentDay,
      activeContracts: state.activeContracts,
      cooldownUntilDayByMentor: state.cooldownUntilDayByMentor,
      maxConcurrentMentors: state.maxConcurrentMentors,
      targetEventName: _eventNameController.text,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mentor.name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '„${mentor.nickname}” • ${mentor.era.displayName}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (mentor.prefers(assignment))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.goldAccent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Text(
                    'Synergia +20%',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              '„${mentor.signatureQuote}”',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Typ zlecenia doradczego',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in LegendMentorAssignmentType.values)
                _FilterChipButton(
                  label: '${type.shortLabel} (${type.durationDays}d)',
                  selected: type == assignment,
                  accentColor: type.accentColor,
                  onTap: () {
                    notifier.selectAssignmentType(type);
                    _eventNameController.text = _defaultEventFor(type);
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            assignment.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _eventNameController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Docelowy obóz lub Wielki Tour',
              labelStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.surfaceLight,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.goldAccent),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _BuffBadge(
                label: 'Morale',
                value: '+${scaled.moraleBoost}',
                color: AppColors.statusSuccess,
              ),
              _BuffBadge(
                label: 'Race IQ',
                value: '+${scaled.raceIqBonus.toStringAsFixed(1)}',
                color: AppColors.accentBlue,
              ),
              if (scaled.climbingSkillBonus > 0)
                _BuffBadge(
                  label: 'Góry',
                  value: '+${scaled.climbingSkillBonus.toStringAsFixed(1)}',
                  color: AppColors.accentBlue,
                ),
              if (scaled.timeTrialSkillBonus > 0)
                _BuffBadge(
                  label: 'Czasówka',
                  value: '+${scaled.timeTrialSkillBonus.toStringAsFixed(1)}',
                  color: AppColors.cyanAccent,
                ),
              if (scaled.cobblesSkillBonus > 0)
                _BuffBadge(
                  label: 'Bruk',
                  value: '+${scaled.cobblesSkillBonus.toStringAsFixed(1)}',
                  color: AppColors.amberWarning,
                ),
              if (scaled.thirdWeekFatigueReduction > 0)
                _BuffBadge(
                  label: '3. tydzień GT',
                  value:
                      '-${(scaled.thirdWeekFatigueReduction * 100).round()}%',
                  color: AppColors.goldAccent,
                ),
              _BuffBadge(
                label: 'Rozwój U23',
                value:
                    'x${scaled.youthDevelopmentMultiplier.toStringAsFixed(2)}',
                color: AppColors.primaryAccent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Honorarium pakietu',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '€${HistoricLegendGuestMentorsService._formatInt(fee)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ],
                ),
              ),
              _InteractiveActionButton(
                label: 'Zatrudnij Legendę',
                icon: Icons.handshake_rounded,
                enabled: blocker == null,
                onPressed: () {
                  notifier.hireSelectedMentor(
                    targetEventName: _eventNameController.text,
                  );
                },
              ),
            ],
          ),
          if (blocker != null) ...[
            const SizedBox(height: 8),
            Text(
              blocker,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.amberWarning,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveContractsCard(
    HistoricLegendGuestMentorsState state,
    HistoricLegendGuestMentorsNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Aktywne kontrakty doradcze',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${state.activeContracts.length}/${state.maxConcurrentMentors}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.goldAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.activeContracts.isEmpty)
            const Text(
              'Brak aktywnych legend przy drużynie. Wybierz doradcę z listy, aby wzmocnić obóz lub Wielki Tour.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < state.activeContracts.length; i++) ...[
                  _buildContractTile(state.activeContracts[i], notifier),
                  if (i < state.activeContracts.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildContractTile(
    ActiveLegendMentorContract contract,
    HistoricLegendGuestMentorsNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                contract.assignmentType.icon,
                color: contract.assignmentType.accentColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${contract.mentorName} — ${contract.targetEventName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    notifier.cancelActiveContract(contract.contractId),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.crimsonAlert,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Zakończ',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: contract.progressRatio,
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                contract.assignmentType.accentColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Dzień ${contract.daysCompleted}/${contract.durationDays} • pozostało ${contract.remainingDays} dni',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveCard extends StatefulWidget {
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;
  final Widget child;

  const _InteractiveCard({
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
    required this.child,
  });

  @override
  State<_InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<_InteractiveCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? widget.accentColor
        : (_focused || _hovered)
            ? widget.accentColor.withValues(alpha: 0.6)
            : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedScale(
            scale: _pressed ? 0.99 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.isSelected || _hovered
                    ? AppColors.surfaceLight
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: widget.isSelected ? 1.5 : 1.0,
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatefulWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_FilterChipButton> createState() => _FilterChipButtonState();
}

class _FilterChipButtonState extends State<_FilterChipButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.accentColor.withValues(alpha: 0.18)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: widget.selected || _focused
                  ? widget.accentColor
                  : AppColors.cardBorder,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color:
                  widget.selected ? widget.accentColor : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;
  final bool isSecondary;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSecondary ? AppColors.surfaceLight : AppColors.primaryAccent;
    const fg = AppColors.textPrimary;

    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.surfaceLight.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.pressed)) {
            return bg.withValues(alpha: 0.85);
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return isSecondary
                ? AppColors.cardBorder
                : AppColors.goldAccent.withValues(alpha: 0.9);
          }
          return bg;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textSecondary;
          }
          if (!isSecondary &&
              (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused))) {
            return AppColors.background;
          }
          return fg;
        }),
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSecondary ? AppColors.cardBorder : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuffBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BuffBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
