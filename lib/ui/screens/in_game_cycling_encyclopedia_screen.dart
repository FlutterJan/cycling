import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Categories for filtering topics in [InGameCyclingEncyclopediaScreen].
enum EncyclopediaCategory {
  all('Wszystkie', Icons.menu_book_rounded),
  physics('Fizyka', Icons.air_rounded),
  physiology('Fizjologia', Icons.monitor_heart_rounded),
  tactics('Taktyka', Icons.route_rounded),
  rules('Przepisy UCI', Icons.gavel_rounded);

  const EncyclopediaCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Unique identifiers for the 9 core encyclopedia topics.
enum EncyclopediaTopicId {
  cda,
  crr,
  wPrimeSkiba,
  vlaMax,
  lactateThresholds,
  vam,
  echelons,
  sprintTrains,
  threeKmRule,
}

/// Immutable data model describing one entry in the cycling encyclopedia.
class EncyclopediaEntry {
  const EncyclopediaEntry({
    required this.id,
    required this.title,
    required this.shortLabel,
    required this.subtitle,
    required this.category,
    required this.badge,
    required this.formula,
    required this.summary,
    required this.inGameImpact,
    required this.proTip,
    required this.keyMetrics,
    required this.accentColor,
    required this.icon,
  });

  final EncyclopediaTopicId id;
  final String title;
  final String shortLabel;
  final String subtitle;
  final EncyclopediaCategory category;
  final String badge;
  final String formula;
  final String summary;
  final String inGameImpact;
  final String proTip;
  final List<({String label, String value})> keyMetrics;
  final Color accentColor;
  final IconData icon;
}

/// Scenario model for the 3-Kilometer Rule interactive simulator.
class ThreeKmRuleScenario {
  const ThreeKmRuleScenario({
    required this.id,
    required this.title,
    required this.stageType,
    required this.distanceToFinishKm,
    required this.incidentType,
    required this.ruleApplies,
    required this.verdict,
    required this.explanation,
  });

  final String id;
  final String title;
  final String stageType;
  final double distanceToFinishKm;
  final String incidentType;
  final bool ruleApplies;
  final String verdict;
  final String explanation;
}

/// Pure physics, physiology, and tactical calculations used by the encyclopedia charts.
class EncyclopediaPhysicsCalculator {
  EncyclopediaPhysicsCalculator._();

  static const double gravity = 9.80665;
  static const double standardAirDensity = 1.225;

  /// Aerodynamic drag power: P = 0.5 * rho * CdA * v^3.
  static double aeroPowerWatts({
    required double cda,
    required double speedKmh,
    double airDensity = standardAirDensity,
  }) {
    final double vMs = math.max(0.0, speedKmh) / 3.6;
    return 0.5 * airDensity * cda * vMs * vMs * vMs;
  }

  /// Rolling resistance power: P = Crr * m * g * v.
  static double rollingPowerWatts({
    required double crr,
    required double totalMassKg,
    required double speedKmh,
  }) {
    final double vMs = math.max(0.0, speedKmh) / 3.6;
    return crr * totalMassKg * gravity * vMs;
  }

  /// Simulates Skiba W' balance over a 300-second interval profile:
  /// 0-60s warm-up (75% CP), 60-150s attack, 150-240s recovery, 240-300s kick.
  static List<({int second, double powerW, double wPrimeKj})>
      simulateSkibaWPrime({
    required double cpWatts,
    required double wPrimeMaxKj,
    required double attackWatts,
    required double recoveryWatts,
  }) {
    final List<({int second, double powerW, double wPrimeKj})> samples = [];
    double wBalJ = wPrimeMaxKj * 1000.0;
    final double wMaxJ = wPrimeMaxKj * 1000.0;

    for (int t = 0; t <= 300; t += 5) {
      final double power;
      if (t < 60) {
        power = cpWatts * 0.78;
      } else if (t < 150) {
        power = attackWatts;
      } else if (t < 240) {
        power = recoveryWatts;
      } else {
        power = cpWatts * 1.28;
      }

      if (t > 0) {
        const double dt = 5.0;
        if (power > cpWatts) {
          wBalJ = math.max(0.0, wBalJ - (power - cpWatts) * dt);
        } else {
          final double dCp = math.max(1.0, cpWatts - power);
          final double tau = 546.0 * math.exp(-0.01 * dCp) + 316.0;
          wBalJ = wMaxJ - (wMaxJ - wBalJ) * math.exp(-dt / tau);
        }
      }

      samples.add((
        second: t,
        powerW: power,
        wPrimeKj: (wBalJ / 1000.0).clamp(0.0, wPrimeMaxKj),
      ));
    }
    return samples;
  }

  /// Estimates FTP (W/kg) and 5s Peak (W/kg) from VLaMax (mmol/L/s) and VO2max.
  static ({double ftpWkg, double peak5sWkg, double vo2MaxWkg})
      vlaMaxProfileMetrics({
    required double vlaMax,
    double vo2Max = 78.0,
  }) {
    final double clampedVla = vlaMax.clamp(0.25, 0.95);
    // Higher VLaMax boosts anaerobic 5s sprint power, slightly lowers sustainable FTP ratio.
    final double vo2MaxWkg = 4.2 + (vo2Max - 60.0) * 0.085;
    final double ftpFraction = (0.88 - (clampedVla - 0.30) * 0.24).clamp(0.68, 0.90);
    final double ftpWkg = vo2MaxWkg * ftpFraction;
    final double peak5sWkg = 11.5 + clampedVla * 13.5;
    return (
      ftpWkg: ftpWkg,
      peak5sWkg: peak5sWkg,
      vo2MaxWkg: vo2MaxWkg,
    );
  }

  /// Generates blood lactate curve (mmol/L) across power intensities (150-500 W).
  static List<({double watts, double lactateMmol})> lactateCurve({
    required double vlaMax,
    required double aerobicThresholdW,
  }) {
    final List<({double watts, double lactateMmol})> points = [];
    final double steepness = 0.014 + vlaMax * 0.012;
    for (int w = 160; w <= 480; w += 20) {
      final double delta = w - aerobicThresholdW;
      final double lactate = delta <= 0
          ? 0.9 + 0.6 * math.exp(delta / 70.0)
          : 1.5 + 0.55 * math.exp(delta * steepness);
      points.add((
        watts: w.toDouble(),
        lactateMmol: lactate.clamp(0.8, 16.0),
      ));
    }
    return points;
  }

  /// Solves climbing speed & VAM (m/h) from W/kg, gradient (%), mass (kg), CdA, and Crr.
  static ({double vamMh, double speedKmh, double alpeDHuezMinutes})
      computeVam({
    required double wPerKg,
    required double gradientPercent,
    double riderMassKg = 64.0,
    double bikeMassKg = 6.8,
    double cda = 0.31,
    double crr = 0.0034,
  }) {
    final double totalMass = riderMassKg + bikeMassKg;
    final double totalPower = wPerKg * riderMassKg;
    final double slope = gradientPercent / 100.0;
    final double theta = math.atan(slope);
    final double fGravRoll = totalMass *
        gravity *
        (math.sin(theta) + crr * math.cos(theta));

    // Bisection for steady-state climbing speed v (m/s).
    double low = 0.5;
    double high = 20.0;
    for (int i = 0; i < 32; i++) {
      final double mid = 0.5 * (low + high);
      final double pReq =
          mid * (fGravRoll + 0.5 * standardAirDensity * cda * mid * mid);
      if (pReq < totalPower) {
        low = mid;
      } else {
        high = mid;
      }
    }
    final double vMs = 0.5 * (low + high);
    final double vamMh = vMs * math.sin(theta) * 3600.0;
    // Reference Alpe d'Huez vertical gain: 1120 m.
    final double alpeMinutes = vamMh > 10 ? (1120.0 / vamMh) * 60.0 : 99.0;
    return (
      vamMh: vamMh,
      speedKmh: vMs * 3.6,
      alpeDHuezMinutes: alpeMinutes,
    );
  }

  /// Computes crosswind echelon draft savings (%) for rider slots 1..8.
  static List<({int slot, double effortPercent, double draftSavingPercent})>
      echelonEffortDistribution({
    required double windSpeedKmh,
    required double windAngleDeg,
  }) {
    final double crosswindFactor =
        math.sin(windAngleDeg * math.pi / 180.0).abs().clamp(0.0, 1.0);
    final double windSeverity =
        ((windSpeedKmh / 50.0) * crosswindFactor).clamp(0.1, 1.2);

    return List<({int slot, double effortPercent, double draftSavingPercent})>.generate(
      8,
      (int idx) {
        final int slot = idx + 1;
        if (slot == 1) {
          final double leadEffort = (100.0 + windSeverity * 18.0).clamp(100.0, 125.0);
          return (slot: slot, effortPercent: leadEffort, draftSavingPercent: 0.0);
        }
        // Slots 2-5 sit diagonally in the echelon gutter shelter; slots 6-8 lose shelter ("in the gutter").
        final double maxShelter = slot <= 5
            ? (38.0 - (slot - 2) * 3.5) * (1.0 - windSeverity * 0.15)
            : math.max(4.0, 14.0 - (slot - 5) * 4.0);
        final double saving = maxShelter.clamp(4.0, 42.0);
        final double effort = (100.0 - saving + windSeverity * (slot > 5 ? 16.0 : 4.0))
            .clamp(58.0, 118.0);
        return (slot: slot, effortPercent: effort, draftSavingPercent: saving);
      },
    );
  }

  /// Generates speed (km/h) over the final 3000 m of a sprint train.
  static List<({double metersToFinish, double speedKmh, String phase})>
      sprintTrainProfile({
    required bool eliteLeadout,
  }) {
    final double bonus = eliteLeadout ? 4.2 : 0.0;
    return [
      (metersToFinish: 3000, speedKmh: 54.0 + bonus * 0.4, phase: 'Ustawienie'),
      (metersToFinish: 2200, speedKmh: 57.5 + bonus * 0.5, phase: 'Silnik #1'),
      (metersToFinish: 1500, speedKmh: 60.5 + bonus * 0.6, phase: 'Silnik #2'),
      (metersToFinish: 1000, speedKmh: 63.0 + bonus * 0.7, phase: 'Flamme Rouge'),
      (metersToFinish: 600, speedKmh: 65.5 + bonus * 0.8, phase: 'Rozprowadzający'),
      (metersToFinish: 250, speedKmh: 67.2 + bonus * 0.9, phase: 'Proca Aero'),
      (metersToFinish: 120, speedKmh: 71.8 + bonus, phase: 'Sprint Max'),
      (metersToFinish: 0, speedKmh: 70.4 + bonus * 0.9, phase: 'Linia Mety'),
    ];
  }
}

/// Built-in Cycling Tactics & Physiology Encyclopedia screen.
class InGameCyclingEncyclopediaScreen extends StatefulWidget {
  const InGameCyclingEncyclopediaScreen({
    super.key,
    this.initialTopic = EncyclopediaTopicId.cda,
    this.onClose,
  });

  final EncyclopediaTopicId initialTopic;
  final VoidCallback? onClose;

  static const List<EncyclopediaEntry> entries = [
    EncyclopediaEntry(
      id: EncyclopediaTopicId.cda,
      title: 'CdA — Opór Aerodynamiczny',
      shortLabel: 'CdA',
      subtitle: 'Współczynnik powierzchni czołowej i oporu powietrza (m²)',
      category: EncyclopediaCategory.physics,
      badge: 'FIZYKA AERO',
      formula: 'P_aero = 0.5 · ρ · CdA · v³',
      summary:
          'CdA to iloczyn współczynnika oporu kształtu (Cd) oraz powierzchni czołowej kolarza z rowerem (A). Ponieważ opór rośnie z trzecią potęgą prędkości (v³), powyżej 35 km/h to właśnie CdA pochłania 75–90% całej mocy kolarza.',
      inGameImpact:
          'W silniku gry pozycja na rowerze (Aero Tuck, chwyty dolne Drops, klamkomanetki Hoods), kask czasowy, profil kół i Bike Fit bezpośrednio zmieniają CdA. Redukcja o 0.020 m² oszczędza ok. 22 W przy 45 km/h.',
      proTip:
          'Na etapach jazdy na czas (ITT/TTT) oraz w ucieczkach na płaskim każdy 0.01 m² CdA jest wart więcej niż oszczędność 400 g masy roweru.',
      keyMetrics: [
        (label: 'Aero Tuck / TT', value: '0.19 – 0.22 m²'),
        (label: 'Drops (Wyścig)', value: '0.26 – 0.28 m²'),
        (label: 'Hoods (Peleton)', value: '0.31 – 0.34 m²'),
      ],
      accentColor: AppColors.accentBlue,
      icon: Icons.air_rounded,
    ),
    EncyclopediaEntry(
      id: EncyclopediaTopicId.crr,
      title: 'Crr — Opór Toczenia Opon',
      shortLabel: 'Crr',
      subtitle: 'Straty energii na styku opony z nawierzchnią',
      category: EncyclopediaCategory.physics,
      badge: 'SPRZĘT & NAWIERZCHNIA',
      formula: 'P_roll = Crr · m · g · v',
      summary:
          'Crr określa, jaka część nacisku (masy kolarza i roweru) zamienia się w opór toczenia podczas odkształcania opony. W przeciwieństwie do CdA, opór toczenia rośnie liniowo z prędkością i zależy od mieszanki gumy, ciśnienia BAR oraz jakości asfaltu.',
      inGameImpact:
          'W Warsztacie Mechanika wybór opon (TT Slick vs Cobble), woskowany łańcuch i optymalne ciśnienie BAR/PSI redukują Crr. Zbyt wysokie ciśnienie na bruku powoduje podskakiwanie koła i gwałtowny skok Crr.',
      proTip:
          'Na Paryż–Roubaix obniż ciśnienie do 3.6–4.2 BAR na szerszych oponach 32 mm — wyższe ugięcie pochłania drgania bruku i utrzymuje wyższą prędkość.',
      keyMetrics: [
        (label: 'Opona TT (Asfalt)', value: '0.0024 – 0.0028'),
        (label: 'Wyścigowa 28 mm', value: '0.0032 – 0.0038'),
        (label: 'Mokry Bruk 5★', value: '0.0085 – 0.0110'),
      ],
      accentColor: AppColors.cyanAccent,
      icon: Icons.tire_repair_rounded,
    ),
    EncyclopediaEntry(
      id: EncyclopediaTopicId.wPrimeSkiba,
      title: "Model Skiba W' (Bateria Beztlenowa)",
      shortLabel: "Skiba W'",
      subtitle: 'Dynamiczne zużycie i wykładnicza odbudowa energii powyżej CP',
      category: EncyclopediaCategory.physiology,
      badge: 'FIZJOLOGIA SILNIKA',
      formula: "W'bal(t) = W' - ∫ (P - CP) · e^(-(t-u)/τ) du",
      summary:
          "W' (W-prime, wyrażane w kJ) to skończony zapas pracy, jaką kolarz może wykonać powyżej swojej Mocy Krytycznej (CP / FTP). Gdy moc przekracza CP, bateria W' się rozładowuje; gdy spada poniżej CP, odbudowuje się wykładniczo ze stałą czasową τ.",
      inGameImpact:
          "Ataki na podjazdach i finisze zużywają pasek W' na HUD-zie. Zejście W' do 0 kJ powoduje natychmiastowe 'odcięcie' i spadek mocy poniżej FTP do czasu częściowej regeneracji.",
      proTip:
          "Im głębiej zjedziesz z mocą poniżej CP podczas odpoczynku na kole (np. 65% FTP zamiast 90% FTP), tym krótsza staje się stała czasowa τ i szybciej odzyskasz 'zapałki' na kolejny atak.",
      keyMetrics: [
        (label: 'Sprinter / Puncheur', value: '24 – 32 kJ'),
        (label: 'Góral GC', value: '16 – 22 kJ'),
        (label: 'Stała τ (odbudowa)', value: '316 – 780 s'),
      ],
      accentColor: AppColors.powerZone6,
      icon: Icons.battery_charging_full_rounded,
    ),
    EncyclopediaEntry(
      id: EncyclopediaTopicId.vlaMax,
      title: 'VLaMax — Maksymalna Glikoliza',
      shortLabel: 'VLaMax',
      subtitle: 'Szybkość produkcji mleczanu i profil metaboliczny kolarza',
      category: EncyclopediaCategory.physiology,
      badge: 'LAB WYDOLNOŚCIOWE',
      formula: 'VLaMax [mmol/L/s] ↔ Sprint vs FTP',
      summary:
          'VLaMax mierzy maksymalną wydajność systemu beztlenowego (glikolizy). Wysokie VLaMax daje potężny sprint i przyspieszenie, ale powoduje szybszą produkcję mleczanu już przy umiarkowanych mocach, obniżając ułamek VO2max dostępny na progu FTP.',
      inGameImpact:
          'Profil mleczanowy w grze kształtuje charakterystykę kolarza: sprinterzy mają wysokie VLaMax (0.75–0.90), a kolarze na Wielkie Toury niskie (0.28–0.38), co pozwala im utrzymywać bardzo wysoki procent VO2max przez 40 minut wspinaczki.',
      proTip:
          'Podczas obozów treningowych treningi Sweet Spot i długie podjazdy w strefie Z3/Z4 obniżają VLaMax, poprawiając wytrzymałość GC kosztem szczytowego sprintu.',
      keyMetrics: [
        (label: 'Góral GT / Czasowiec', value: '0.28 – 0.38 mmol/L/s'),
        (label: 'Klasyk / Puncheur', value: '0.48 – 0.62 mmol/L/s'),
        (label: 'Sprinter', value: '0.75 – 0.92 mmol/L/s'),
      ],
      accentColor: AppColors.amberWarning,
      icon: Icons.bolt_rounded,
    ),
    EncyclopediaEntry(
      id: EncyclopediaTopicId.lactateThresholds,
      title: 'Progi Mleczanowe LT1 / LT2',
      shortLabel: 'LT1 / LT2',
      subtitle: 'Próg tlenowy (FatMax) oraz próg beztlenowy (FTP / MLSS)',
      category: EncyclopediaCategory.physiology,
      badge: 'KRZYWA MLECZANOWA',
      formula: 'LT1 ≈ 2.0 mmol/L | LT2 ≈ 4.0 mmol/L',
      summary:
          'LT1 (pierwszy próg mleczanowy) oznacza punkt, w którym stężenie mleczanu zaczyna rosnąć powyżej wartości spoczynkowej — to górna granica ekonomicznej jazdy wytrzymałościowej. LT2 (drugi próg, bliski FTP) to maksymalna moc, przy której produkcja i utylizacja mleczanu pozostają w równowadze.',
      inGameImpact:
          'Jazda powyżej LT1 zużywa znacznie więcej glikogenu niż tłuszczów, co przyspiesza ryzyko głodu (bonka) na długich etapach >200 km. W silniku gry przekroczenie LT1 na podjeździe ujawnia też ukrytą dyspozycję dnia (?).',
      proTip:
          'W pierwszej części górskiego etapu utrzymuj pomocników poniżej LT1, aby oszczędzili zapasy węglowodanów na finałowe 2 przełęcze.',
      keyMetrics: [
        (label: 'LT1 (Strefa Z2/Z3)', value: '~2.0 mmol/L (~72% FTP)'),
        (label: 'LT2 / FTP (Z4)', value: '~4.0 mmol/L (100% FTP)'),
        (label: 'VO2max (Z5)', value: '8 – 14 mmol/L'),
      ],
      accentColor: AppColors.statusSuccess,
      icon: Icons.show_chart_rounded,
    ),
    EncyclopediaEntry(
      id: EncyclopediaTopicId.vam,
      title: 'VAM — Prędkość Wspinaczki Pionowej',
      shortLabel: 'VAM',
      subtitle: 'Liczba metrów przewyższenia pokonywana w ciągu godziny (m/h)',
      category: EncyclopediaCategory.physics,
      badge: 'TELEMETRIA GÓRSKA',
      formula: 'VAM = v · sin(θ) · 3600  [m/h]',
      summary:
          'VAM (Velocità Ascensionale Media) wyraża tempo zdobywania wysokości w metrach na godzinę. Ponieważ na stromych podjazdach (>7%) większość mocy idzie na pokonanie grawitacji, VAM jest wprost proporcjonalne do stosunku mocy do masy (W/kg) i rośnie wraz z nachyleniem.',
      inGameImpact:
          'W nakładce TV Broadcast oraz na ekranie analizy etapu VAM pozwala natychmiast ocenić intensywność ataku w górach niezależnie od długości podjazdu. Na Alpe d’Huez elita WorldTour osiąga 1700–1850 m/h.',
      proTip:
          'Na podjeździe o nachyleniu 10% przy 6.0 W/kg kolarz osiąga wyższe VAM niż przy tej samej mocy na 5%, ponieważ niższa prędkość jazdy redukuje straty aerodynamiczne.',
      keyMetrics: [
        (label: 'Grupetto / Tempo Z2', value: '950 – 1150 m/h'),
        (label: 'Peleton Faworytów', value: '1450 – 1620 m/h'),
        (label: 'Atak HC WorldTour', value: '1720 – 1920 m/h'),
      ],
      accentColor: AppColors.goldAccent,
      icon: Icons.terrain_rounded,
    ),
    EncyclopediaEntry(
      id: EncyclopediaTopicId.echelons,
      title: 'Wachlarze (Echelons) na Wietrze Bocznym',
      shortLabel: 'Wachlarze',
      subtitle: 'Skośne formacje i pękanie peletonu na ranty przy wietrze bocznym',
      category: EncyclopediaCategory.tactics,
      badge: 'TAKTYKA WIATROWA',
      formula: 'V_cross = V_wind · sin(α) > 25 km/h',
      summary:
          'Gdy silny wiatr wieje z boku, kolarze nie mogą chować się bezpośrednio za kołem poprzednika — muszą ustawić się ukośnie w stronę zawietrznej krawędzi jezdni. Ponieważ szerokość drogi mieści tylko 5–8 kolarzy w wachlarzu, reszta peletonu zostaje w tzw. rynsztoku (gutter) bez cienia aerodynamicznego.',
      inGameImpact:
          'Silnik EchelonCrosswindEngine aktywuje strefy zagrożenia wiatrem bocznym. Drużyny z wysokim ustawieniem na czele i dobrą komunikacją formują 1. rant, podczas gdy spóźnieni liderzy GC mogą stracić minuty na płaskim etapie.',
      proTip:
          'Przed strefą otwartego wiatru bocznego przesuń lidera i 3 silnych rouleurów do Top 15 peletonu (rozkaz Pozycja Przód).',
      keyMetrics: [
        (label: 'Próg ryzyka wiatru', value: '> 28 km/h boczny'),
        (label: 'Pojemność 1. rantu', value: '5 – 8 kolarzy'),
        (label: 'Oszczędność w wachlarzu', value: '28% – 38% mocy'),
      ],
      accentColor: AppColors.accentBlue,
      icon: Icons.swap_calls_rounded,
    ),
    EncyclopediaEntry(
      id: EncyclopediaTopicId.sprintTrains,
      title: 'Pociągi Sprinterskie & Proca Aero',
      shortLabel: 'Pociągi',
      subtitle: 'Sekwencyjne rozprowadzanie od 3 km do mety i wyskok na 250 m',
      category: EncyclopediaCategory.tactics,
      badge: 'FINISZ GRUPOWY',
      formula: 'Slingshot: Δv +6–9 km/h przy 250 m',
      summary:
          'Pociąg sprinterski to precyzyjnie zgrana kolejka 3–5 kolarzy, w której każdy pomocnik daje maksymalną zmianę przez 400–600 m i schodzi na bok, utrzymując prędkość powyżej 63–67 km/h. Dzięki temu nikt z tyłu nie może zaatakować, a sprinter oszczędza W’ aż do ostatnich 200–250 m.',
      inGameImpact:
          'W grze SprintTrainAiController ustawia kolejność: Silnik Płaski -> Leadout Man -> Sprinter. Na 250 m przed metą silnik SprintLeadoutAerodynamicSlingshot generuje efekt procy (+6 do +9 km/h dzięki opóźnieniu narastania oporu czołowego).',
      proTip:
          'Zacznij formować pociąg najpóźniej na 4 km przed metą. Jeśli Twój ostatni rozprowadzający ma wysokie statystyki Sprint i Bike Handling, sprinter wyskoczy z koła z niemal pełnym W’.',
      keyMetrics: [
        (label: 'Prędkość na 1 km', value: '63 – 66 km/h'),
        (label: 'Moment wyskoku', value: '180 – 250 m'),
        (label: 'Prędkość maksymalna', value: '71 – 76 km/h'),
      ],
      accentColor: AppColors.primaryAccent,
      icon: Icons.speed_rounded,
    ),
    EncyclopediaEntry(
      id: EncyclopediaTopicId.threeKmRule,
      title: 'Zasada 3 Kilometrów (Przepis UCI)',
      shortLabel: 'Zasada 3 km',
      subtitle: 'Ochrona czasu GC przy kraksach i defektach w końcówce etapu',
      category: EncyclopediaCategory.rules,
      badge: 'REGULAMIN UCI',
      formula: 'Incydent ≤ 3.0 km (Płaski) ⇒ Czas grupy',
      summary:
          'Przepis UCI stworzony dla bezpieczeństwa na szybkich finiszach: jeśli kolarz ulegnie kraksie lub defektowi mechanicznemu w strefie ostatnich 3 kilometrów etapu płaskiego (lub pagórkowatego bez mety na podjeździe), otrzymuje na mecie czas grupy, w której jechał w momencie incydentu.',
      inGameImpact:
          'Kolegium Sędziów w grze automatycznie stosuje Zasadę 3 km na płaskich końcówkach: Twój lider GC nie straci czasu po kraksie na 1.8 km przed metą, ale wciąż musi ukończyć etap. Zasada NIE obowiązuje na metach górskich (Summit Finish), w ITT ani przy zwykłym odpadnięciu z braku sił.',
      proTip:
          'Na etapach sprinterskich po minięciu bramy 3 km głównym celem lidera GC jest bezpieczne dojechanie do mety bez podejmowania zbędnego ryzyka w walce o pozycję ze sprinterami.',
      keyMetrics: [
        (label: 'Strefa ochrony', value: 'Ostatnie 3.0 km'),
        (label: 'Etapy objęte ochroną', value: 'Płaskie / Sprint'),
        (label: 'Wyłączenia', value: 'Summit Finish, ITT, brak sił'),
      ],
      accentColor: AppColors.goldAccent,
      icon: Icons.shield_rounded,
    ),
  ];

  static const List<ThreeKmRuleScenario> threeKmScenarios = [
    ThreeKmRuleScenario(
      id: 'flat_crash',
      title: 'Kraksa na płaskim finiszu (1.8 km)',
      stageType: 'Etap Płaski',
      distanceToFinishKm: 1.8,
      incidentType: 'Kraksa w peletonie',
      ruleApplies: true,
      verdict: 'ZASADA 3 KM AKTYWNA — ZALICZONY CZAS PELETONU',
      explanation:
          'Lider GC był w głównej grupie w momencie kraksy w strefie ochronnej ≤3.0 km. Sędziowie przyznają mu czas peletonu (0 s straty w GC).',
    ),
    ThreeKmRuleScenario(
      id: 'flat_mech',
      title: 'Defekt koła na 0.9 km przed metą',
      stageType: 'Etap Płaski',
      distanceToFinishKm: 0.9,
      incidentType: 'Przebita opona (defekt)',
      ruleApplies: true,
      verdict: 'ZASADA 3 KM AKTYWNA — ZALICZONY CZAS GRUPY',
      explanation:
          'Udokumentowany defekt mechaniczny w ostatnich 3 km uprawnia do neutralizacji straty czasowej, o ile kolarz ukończy etap.',
    ),
    ThreeKmRuleScenario(
      id: 'summit_crash',
      title: 'Kraksa na podjeździe do mety (2.1 km)',
      stageType: 'Meta Górska (Summit Finish)',
      distanceToFinishKm: 2.1,
      incidentType: 'Kraksa na finałowym podjeździe',
      ruleApplies: false,
      verdict: 'BRAK OCHRONY — LICZY SIĘ REALNA STRATA',
      explanation:
          'Zasada 3 km nie obowiązuje na etapach kończących się podjazdem (Summit Finish), ponieważ finisz nie ma charakteru masowego sprintu.',
    ),
    ThreeKmRuleScenario(
      id: 'dropped_legs',
      title: 'Odpadnięcie z braku sił na 2.4 km',
      stageType: 'Etap Pagórkowaty',
      distanceToFinishKm: 2.4,
      incidentType: 'Brak sił / odcięcie W\'',
      ruleApplies: false,
      verdict: 'BRAK OCHRONY — LICZY SIĘ REALNA STRATA',
      explanation:
          'Ochrona dotyczy wyłącznie kraks i defektów mechanicznych. Kolarz, który po prostu nie utrzymał koła na rantach lub hopce, traci realne sekundy.',
    ),
  ];

  @override
  State<InGameCyclingEncyclopediaScreen> createState() =>
      _InGameCyclingEncyclopediaScreenState();
}

class _InGameCyclingEncyclopediaScreenState
    extends State<InGameCyclingEncyclopediaScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  EncyclopediaCategory _selectedCategory = EncyclopediaCategory.all;
  late EncyclopediaTopicId _selectedTopic;
  String _searchQuery = '';

  // Interactive chart parameters
  double _cdaSpeedKmh = 45.0;
  double _crrMassKg = 74.0;
  double _skibaAttackWatts = 520.0;
  double _skibaRecoveryWatts = 240.0;
  double _vlaMaxValue = 0.45;
  double _lactateVlaMax = 0.45;
  double _vamWkg = 5.8;
  double _vamGradient = 8.5;
  double _windSpeedKmh = 38.0;
  double _windAngleDeg = 65.0;
  bool _eliteSprintLeadout = true;
  String _selectedThreeKmScenarioId = 'flat_crash';

  @override
  void initState() {
    super.initState();
    _selectedTopic = widget.initialTopic;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<EncyclopediaEntry> get _filteredEntries {
    final String q = _searchQuery.trim().toLowerCase();
    return InGameCyclingEncyclopediaScreen.entries.where((entry) {
      final bool matchesCategory = _selectedCategory == EncyclopediaCategory.all ||
          entry.category == _selectedCategory;
      if (!matchesCategory) return false;
      if (q.isEmpty) return true;
      return entry.title.toLowerCase().contains(q) ||
          entry.shortLabel.toLowerCase().contains(q) ||
          entry.subtitle.toLowerCase().contains(q) ||
          entry.summary.toLowerCase().contains(q) ||
          entry.badge.toLowerCase().contains(q);
    }).toList();
  }

  EncyclopediaEntry get _activeEntry {
    return InGameCyclingEncyclopediaScreen.entries.firstWhere(
      (e) => e.id == _selectedTopic,
      orElse: () => InGameCyclingEncyclopediaScreen.entries.first,
    );
  }

  bool get _isCurrentTopicAtDefault {
    switch (_selectedTopic) {
      case EncyclopediaTopicId.cda:
        return (_cdaSpeedKmh - 45.0).abs() < 0.01;
      case EncyclopediaTopicId.crr:
        return (_crrMassKg - 74.0).abs() < 0.01;
      case EncyclopediaTopicId.wPrimeSkiba:
        return (_skibaAttackWatts - 520.0).abs() < 0.01 &&
            (_skibaRecoveryWatts - 240.0).abs() < 0.01;
      case EncyclopediaTopicId.vlaMax:
        return (_vlaMaxValue - 0.45).abs() < 0.005;
      case EncyclopediaTopicId.lactateThresholds:
        return (_lactateVlaMax - 0.45).abs() < 0.005;
      case EncyclopediaTopicId.vam:
        return (_vamWkg - 5.8).abs() < 0.01 && (_vamGradient - 8.5).abs() < 0.01;
      case EncyclopediaTopicId.echelons:
        return (_windSpeedKmh - 38.0).abs() < 0.01 &&
            (_windAngleDeg - 65.0).abs() < 0.01;
      case EncyclopediaTopicId.sprintTrains:
        return _eliteSprintLeadout;
      case EncyclopediaTopicId.threeKmRule:
        return _selectedThreeKmScenarioId == 'flat_crash';
    }
  }

  void _resetActiveTopicParameters() {
    setState(() {
      switch (_selectedTopic) {
        case EncyclopediaTopicId.cda:
          _cdaSpeedKmh = 45.0;
        case EncyclopediaTopicId.crr:
          _crrMassKg = 74.0;
        case EncyclopediaTopicId.wPrimeSkiba:
          _skibaAttackWatts = 520.0;
          _skibaRecoveryWatts = 240.0;
        case EncyclopediaTopicId.vlaMax:
          _vlaMaxValue = 0.45;
        case EncyclopediaTopicId.lactateThresholds:
          _lactateVlaMax = 0.45;
        case EncyclopediaTopicId.vam:
          _vamWkg = 5.8;
          _vamGradient = 8.5;
        case EncyclopediaTopicId.echelons:
          _windSpeedKmh = 38.0;
          _windAngleDeg = 65.0;
        case EncyclopediaTopicId.sprintTrains:
          _eliteSprintLeadout = true;
        case EncyclopediaTopicId.threeKmRule:
          _selectedThreeKmScenarioId = 'flat_crash';
      }
    });
  }

  void _selectTopic(EncyclopediaTopicId id) {
    if (_selectedTopic == id) return;
    setState(() => _selectedTopic = id);
  }

  void _stepTopic(int delta) {
    const list = InGameCyclingEncyclopediaScreen.entries;
    final idx = list.indexWhere((e) => e.id == _selectedTopic);
    final nextIdx = idx + delta;
    if (nextIdx >= 0 && nextIdx < list.length) {
      setState(() => _selectedTopic = list[nextIdx].id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            final bool isMobile = width < 760;
            final bool isDesktop = width >= 1280;

            return Column(
              children: [
                _buildTopHeader(isMobile: isMobile),
                Expanded(
                  child: isMobile
                      ? _buildMobileBody()
                      : _buildWideBody(isDesktop: isDesktop),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader({required bool isMobile}) {
    const entries = InGameCyclingEncyclopediaScreen.entries;
    final int activeIdx = entries.indexWhere((e) => e.id == _selectedTopic);
    final bool canGoPrev = activeIdx > 0;
    final bool canGoNext = activeIdx >= 0 && activeIdx < entries.length - 1;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 10 : 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.onClose != null || Navigator.of(context).canPop()) ...[
                _InteractiveIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Powrót',
                  onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 10),
              ],
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: AppColors.goldAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ENCYKLOPEDIA TAKTYKI I FIZJOLOGII KOLARSKIEJ',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: 0.5,
                        fontSize: isMobile ? 13 : 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Interaktywna baza wiedzy silnika fizyki, mleczanu i przepisów UCI',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.2,
                        fontSize: isMobile ? 11 : 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                _InteractiveIconButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Poprzednie hasło',
                  onPressed: canGoPrev ? () => _stepTopic(-1) : null,
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    '${activeIdx + 1}/${entries.length}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldAccent,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _InteractiveIconButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'Następne hasło',
                  onPressed: canGoNext ? () => _stepTopic(1) : null,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 260,
                height: 38,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Szukaj pojęcia (np. CdA, VAM, W\')...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            color: AppColors.textSecondary,
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.goldAccent,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              ...EncyclopediaCategory.values.map((category) {
                final bool selected = _selectedCategory == category;
                return _CategoryFilterChip(
                  category: category,
                  selected: selected,
                  onTap: () => setState(() => _selectedCategory = category),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBody() {
    final filtered = _filteredEntries;
    final entry = _activeEntry;

    return Column(
      children: [
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(
              bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
            ),
          ),
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'Brak pasujących haseł',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final bool isSelected = item.id == _selectedTopic;
                    return _TopicPillButton(
                      entry: item,
                      selected: isSelected,
                      onTap: () => _selectTopic(item.id),
                    );
                  },
                ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              child: _buildDetailContent(
                entry,
                isMobile: true,
                isDesktop: false,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWideBody({required bool isDesktop}) {
    final filtered = _filteredEntries;
    final entry = _activeEntry;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: isDesktop ? 320 : 270,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                right: BorderSide(color: AppTheme.borderColor, width: 1.0),
              ),
            ),
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 36,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Brak haseł spełniających kryteria.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ActionPillButton(
                            label: 'Wyczyść filtry',
                            icon: Icons.refresh_rounded,
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedCategory = EncyclopediaCategory.all;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _TopicSidebarTile(
                        entry: item,
                        selected: item.id == _selectedTopic,
                        onTap: () => _selectTopic(item.id),
                      );
                    },
                  ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              child: _buildDetailContent(
                entry,
                isMobile: false,
                isDesktop: isDesktop,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailContent(
    EncyclopediaEntry entry, {
    required bool isMobile,
    required bool isDesktop,
  }) {
    return KeyedSubtree(
      key: ValueKey<EncyclopediaTopicId>(entry.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopicHeroCard(entry, isMobile: isMobile),
          const SizedBox(height: 16),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _buildInteractiveChartCard(entry, isMobile: false),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: _buildExplanationColumn(entry),
                ),
              ],
            )
          else ...[
            _buildInteractiveChartCard(entry, isMobile: isMobile),
            const SizedBox(height: 16),
            _buildExplanationColumn(entry),
          ],
        ],
      ),
    );
  }

  Widget _buildTopicHeroCard(
    EncyclopediaEntry entry, {
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: entry.accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: entry.accentColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  entry.badge,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: entry.accentColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  entry.formula,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: entry.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: entry.accentColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(entry.icon, color: entry.accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.3,
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: entry.keyMetrics.map((metric) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      metric.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      metric.value,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveChartCard(
    EncyclopediaEntry entry, {
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_rounded,
                size: 18,
                color: AppColors.goldAccent,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'INTERAKTYWNY WYKRES SYMULACYJNY',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: AppColors.goldAccent,
                  ),
                ),
              ),
              _ActionPillButton(
                label: 'Reset',
                icon: Icons.restart_alt_rounded,
                onPressed:
                    _isCurrentTopicAtDefault ? null : _resetActiveTopicParameters,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildChartForTopic(entry.id, isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildExplanationColumn(EncyclopediaEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoSectionCard(
          title: 'DEFINICJA I MECHANIKA',
          icon: Icons.science_rounded,
          accentColor: entry.accentColor,
          body: entry.summary,
        ),
        const SizedBox(height: 12),
        _InfoSectionCard(
          title: 'WPŁYW NA SYMULACJĘ W GRZE',
          icon: Icons.videogame_asset_rounded,
          accentColor: AppColors.accentBlue,
          body: entry.inGameImpact,
        ),
        const SizedBox(height: 12),
        _InfoSectionCard(
          title: 'WSKAZÓWKA DYREKTORA SPORTOWEGO',
          icon: Icons.tips_and_updates_rounded,
          accentColor: AppColors.goldAccent,
          body: entry.proTip,
        ),
      ],
    );
  }

  Widget _buildChartForTopic(
    EncyclopediaTopicId id, {
    required bool isMobile,
  }) {
    switch (id) {
      case EncyclopediaTopicId.cda:
        return _buildCdaChart(isMobile: isMobile);
      case EncyclopediaTopicId.crr:
        return _buildCrrChart(isMobile: isMobile);
      case EncyclopediaTopicId.wPrimeSkiba:
        return _buildSkibaWPrimeChart(isMobile: isMobile);
      case EncyclopediaTopicId.vlaMax:
        return _buildVlaMaxChart(isMobile: isMobile);
      case EncyclopediaTopicId.lactateThresholds:
        return _buildLactateThresholdChart(isMobile: isMobile);
      case EncyclopediaTopicId.vam:
        return _buildVamChart(isMobile: isMobile);
      case EncyclopediaTopicId.echelons:
        return _buildEchelonDiagram(isMobile: isMobile);
      case EncyclopediaTopicId.sprintTrains:
        return _buildSprintTrainChart(isMobile: isMobile);
      case EncyclopediaTopicId.threeKmRule:
        return _buildThreeKmRuleExplorer(isMobile: isMobile);
    }
  }

  // 1. CdA Chart
  Widget _buildCdaChart({required bool isMobile}) {
    final double pAeroTuck = EncyclopediaPhysicsCalculator.aeroPowerWatts(
      cda: 0.21,
      speedKmh: _cdaSpeedKmh,
    );
    final double pDrops = EncyclopediaPhysicsCalculator.aeroPowerWatts(
      cda: 0.27,
      speedKmh: _cdaSpeedKmh,
    );
    final double pHoods = EncyclopediaPhysicsCalculator.aeroPowerWatts(
      cda: 0.32,
      speedKmh: _cdaSpeedKmh,
    );

    List<FlSpot> buildSpots(double cda) {
      return [
        for (int s = 20; s <= 65; s += 5)
          FlSpot(
            s.toDouble(),
            EncyclopediaPhysicsCalculator.aeroPowerWatts(
              cda: cda,
              speedKmh: s.toDouble(),
            ),
          ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TelemetryReadoutChip(
              label: 'Aero Tuck (0.21)',
              value: '${pAeroTuck.round()} W',
              color: AppColors.cyanAccent,
            ),
            _TelemetryReadoutChip(
              label: 'Drops (0.27)',
              value: '${pDrops.round()} W',
              color: AppColors.accentBlue,
            ),
            _TelemetryReadoutChip(
              label: 'Hoods (0.32)',
              value: '${pHoods.round()} W',
              color: AppColors.amberWarning,
            ),
            _TelemetryReadoutChip(
              label: 'Oszczędność Tuck vs Hoods',
              value: '-${(pHoods - pAeroTuck).round()} W',
              color: AppColors.statusSuccess,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: isMobile ? 220 : 270,
          child: LineChart(
            LineChartData(
              minX: 20,
              maxX: 65,
              minY: 0,
              maxY: 1200,
              gridData: _defaultGridData(horizontalInterval: 300),
              borderData: _defaultBorderData(),
              titlesData: _defaultTitlesData(
                xUnit: ' km/h',
                yUnit: ' W',
                xInterval: 10,
                yInterval: 300,
              ),
              extraLinesData: ExtraLinesData(
                verticalLines: [
                  VerticalLine(
                    x: _cdaSpeedKmh,
                    color: AppColors.goldAccent.withValues(alpha: 0.8),
                    strokeWidth: 1.5,
                    dashArray: [5, 4],
                  ),
                ],
              ),
              lineBarsData: [
                _lineSeries(buildSpots(0.32), AppColors.amberWarning),
                _lineSeries(buildSpots(0.27), AppColors.accentBlue),
                _lineSeries(buildSpots(0.21), AppColors.cyanAccent),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ParameterSlider(
          label: 'Prędkość jazdy',
          valueText: '${_cdaSpeedKmh.toStringAsFixed(0)} km/h',
          value: _cdaSpeedKmh,
          min: 20,
          max: 65,
          divisions: 45,
          accentColor: AppColors.accentBlue,
          onChanged: (v) => setState(() => _cdaSpeedKmh = v),
        ),
      ],
    );
  }

  // 2. Crr Chart
  Widget _buildCrrChart({required bool isMobile}) {
    const double refSpeed = 40.0;
    final configs = [
      (label: 'TT Slick', crr: 0.0025, color: AppColors.statusSuccess),
      (label: 'Asfalt', crr: 0.0034, color: AppColors.accentBlue),
      (label: 'Chropowaty', crr: 0.0048, color: AppColors.amberWarning),
      (label: 'Bruk 5★', crr: 0.0095, color: AppColors.crimsonAlert),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: configs.map((c) {
            final double w = EncyclopediaPhysicsCalculator.rollingPowerWatts(
              crr: c.crr,
              totalMassKg: _crrMassKg,
              speedKmh: refSpeed,
            );
            return _TelemetryReadoutChip(
              label: '${c.label} (${c.crr.toStringAsFixed(4)})',
              value: '${w.toStringAsFixed(1)} W',
              color: c.color,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: isMobile ? 220 : 260,
          child: BarChart(
            BarChartData(
              maxY: 95,
              gridData: _defaultGridData(horizontalInterval: 20),
              borderData: _defaultBorderData(),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: 20,
                    getTitlesWidget: (val, _) => Text(
                      '${val.toInt()}W',
                      style: _axisLabelStyle,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (val, _) {
                      final idx = val.toInt();
                      if (idx < 0 || idx >= configs.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(configs[idx].label, style: _axisLabelStyle),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List<BarChartGroupData>.generate(configs.length, (i) {
                final double w = EncyclopediaPhysicsCalculator.rollingPowerWatts(
                  crr: configs[i].crr,
                  totalMassKg: _crrMassKg,
                  speedKmh: refSpeed,
                );
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: w,
                      width: isMobile ? 24 : 36,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      color: configs[i].color,
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ParameterSlider(
          label: 'Masa kolarza + roweru (przy 40 km/h)',
          valueText: '${_crrMassKg.toStringAsFixed(0)} kg',
          value: _crrMassKg,
          min: 60,
          max: 92,
          divisions: 32,
          accentColor: AppColors.cyanAccent,
          onChanged: (v) => setState(() => _crrMassKg = v),
        ),
      ],
    );
  }

  // 3. Skiba W' Chart
  Widget _buildSkibaWPrimeChart({required bool isMobile}) {
    const double cp = 380.0;
    const double wMaxKj = 22.0;
    final samples = EncyclopediaPhysicsCalculator.simulateSkibaWPrime(
      cpWatts: cp,
      wPrimeMaxKj: wMaxKj,
      attackWatts: _skibaAttackWatts,
      recoveryWatts: _skibaRecoveryWatts,
    );
    final double minWPrime = samples.map((s) => s.wPrimeKj).reduce(math.min);
    final double endWPrime = samples.last.wPrimeKj;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const _TelemetryReadoutChip(
              label: 'Moc Krytyczna (CP)',
              value: '380 W',
              color: AppColors.goldAccent,
            ),
            _TelemetryReadoutChip(
              label: "Min. stan W'",
              value: '${minWPrime.toStringAsFixed(1)} kJ',
              color: minWPrime < 3.0 ? AppColors.crimsonAlert : AppColors.powerZone5,
            ),
            _TelemetryReadoutChip(
              label: "W' na finiszu (300 s)",
              value: '${endWPrime.toStringAsFixed(1)} kJ',
              color: endWPrime < 1.5 ? AppColors.crimsonAlert : AppColors.statusSuccess,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: isMobile ? 220 : 260,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 300,
              minY: 0,
              maxY: 24,
              gridData: _defaultGridData(horizontalInterval: 6),
              borderData: _defaultBorderData(),
              titlesData: _defaultTitlesData(
                xUnit: 's',
                yUnit: ' kJ',
                xInterval: 60,
                yInterval: 6,
              ),
              lineBarsData: [
                _lineSeries(
                  samples
                      .map((s) => FlSpot(s.second.toDouble(), s.wPrimeKj))
                      .toList(),
                  AppColors.powerZone6,
                  showArea: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ParameterSlider(
          label: 'Moc ataku (60–150 s)',
          valueText: '${_skibaAttackWatts.round()} W',
          value: _skibaAttackWatts,
          min: 400,
          max: 620,
          divisions: 22,
          accentColor: AppColors.powerZone6,
          onChanged: (v) => setState(() => _skibaAttackWatts = v),
        ),
        _ParameterSlider(
          label: 'Moc regeneracji (150–240 s)',
          valueText: '${_skibaRecoveryWatts.round()} W',
          value: _skibaRecoveryWatts,
          min: 140,
          max: 350,
          divisions: 21,
          accentColor: AppColors.statusSuccess,
          onChanged: (v) => setState(() => _skibaRecoveryWatts = v),
        ),
      ],
    );
  }

  // 4. VLaMax Chart
  Widget _buildVlaMaxChart({required bool isMobile}) {
    final current = EncyclopediaPhysicsCalculator.vlaMaxProfileMetrics(
      vlaMax: _vlaMaxValue,
    );
    final String archetype = _vlaMaxValue < 0.40
        ? 'Góral GT / Czasowiec'
        : _vlaMaxValue < 0.62
            ? 'Klasyk / Puncheur'
            : 'Sprinter';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TelemetryReadoutChip(
              label: 'Profil metaboliczny',
              value: archetype,
              color: AppColors.amberWarning,
            ),
            _TelemetryReadoutChip(
              label: 'FTP (W/kg)',
              value: '${current.ftpWkg.toStringAsFixed(2)} W/kg',
              color: AppColors.statusSuccess,
            ),
            _TelemetryReadoutChip(
              label: 'Sprint 5s',
              value: '${current.peak5sWkg.toStringAsFixed(1)} W/kg',
              color: AppColors.powerZone7,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: isMobile ? 210 : 250,
          child: BarChart(
            BarChartData(
              maxY: 26,
              gridData: _defaultGridData(horizontalInterval: 5),
              borderData: _defaultBorderData(),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: 5,
                    getTitlesWidget: (v, _) =>
                        Text('${v.toInt()}', style: _axisLabelStyle),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) {
                      const labels = ['FTP (W/kg)', 'VO2max (W/kg)', 'Sprint 5s'];
                      final i = v.toInt();
                      if (i < 0 || i >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(labels[i], style: _axisLabelStyle),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: current.ftpWkg,
                      width: 32,
                      color: AppColors.statusSuccess,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: current.vo2MaxWkg,
                      width: 32,
                      color: AppColors.powerZone5,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 2,
                  barRods: [
                    BarChartRodData(
                      toY: current.peak5sWkg,
                      width: 32,
                      color: AppColors.powerZone7,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ParameterSlider(
          label: 'VLaMax (produkcja mleczanu)',
          valueText: '${_vlaMaxValue.toStringAsFixed(2)} mmol/L/s',
          value: _vlaMaxValue,
          min: 0.25,
          max: 0.90,
          divisions: 65,
          accentColor: AppColors.amberWarning,
          onChanged: (v) => setState(() => _vlaMaxValue = v),
        ),
      ],
    );
  }

  // 5. LT1 / LT2 Lactate Threshold Chart
  Widget _buildLactateThresholdChart({required bool isMobile}) {
    final double aerobicThresholdW = 310.0 - (_lactateVlaMax - 0.35) * 90.0;
    final curve = EncyclopediaPhysicsCalculator.lactateCurve(
      vlaMax: _lactateVlaMax,
      aerobicThresholdW: aerobicThresholdW,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TelemetryReadoutChip(
              label: 'Próg LT1 (2.0 mmol/L)',
              value: '${aerobicThresholdW.round()} W',
              color: AppColors.statusSuccess,
            ),
            _TelemetryReadoutChip(
              label: 'Próg LT2 / FTP (4.0 mmol/L)',
              value: '${(aerobicThresholdW + 65).round()} W',
              color: AppColors.amberWarning,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: isMobile ? 220 : 260,
          child: LineChart(
            LineChartData(
              minX: 160,
              maxX: 480,
              minY: 0,
              maxY: 14,
              gridData: _defaultGridData(horizontalInterval: 2),
              borderData: _defaultBorderData(),
              titlesData: _defaultTitlesData(
                xUnit: 'W',
                yUnit: '',
                xInterval: 80,
                yInterval: 2,
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 2.0,
                    color: AppColors.statusSuccess,
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      labelResolver: (_) => 'LT1 (2.0)',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.statusSuccess,
                      ),
                    ),
                  ),
                  HorizontalLine(
                    y: 4.0,
                    color: AppColors.amberWarning,
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      labelResolver: (_) => 'LT2 (4.0)',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amberWarning,
                      ),
                    ),
                  ),
                ],
              ),
              lineBarsData: [
                _lineSeries(
                  curve.map((p) => FlSpot(p.watts, p.lactateMmol)).toList(),
                  AppColors.powerZone6,
                  showArea: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ParameterSlider(
          label: 'VLaMax kolarza (przesunięcie krzywej)',
          valueText: '${_lactateVlaMax.toStringAsFixed(2)} mmol/L/s',
          value: _lactateVlaMax,
          min: 0.25,
          max: 0.85,
          divisions: 60,
          accentColor: AppColors.statusSuccess,
          onChanged: (v) => setState(() => _lactateVlaMax = v),
        ),
      ],
    );
  }

  // 6. VAM Chart
  Widget _buildVamChart({required bool isMobile}) {
    final current = EncyclopediaPhysicsCalculator.computeVam(
      wPerKg: _vamWkg,
      gradientPercent: _vamGradient,
    );

    List<FlSpot> buildVamCurve(double wkg) {
      return [
        for (int g = 4; g <= 16; g += 2)
          FlSpot(
            g.toDouble(),
            EncyclopediaPhysicsCalculator.computeVam(
              wPerKg: wkg,
              gradientPercent: g.toDouble(),
            ).vamMh,
          ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TelemetryReadoutChip(
              label: 'VAM',
              value: '${current.vamMh.round()} m/h',
              color: AppColors.goldAccent,
            ),
            _TelemetryReadoutChip(
              label: 'Prędkość na podjeździe',
              value: '${current.speedKmh.toStringAsFixed(1)} km/h',
              color: AppColors.accentBlue,
            ),
            _TelemetryReadoutChip(
              label: "Czas Alpe d'Huez (1120 m)",
              value: '${current.alpeDHuezMinutes.toStringAsFixed(1)} min',
              color: AppColors.statusSuccess,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: isMobile ? 220 : 260,
          child: LineChart(
            LineChartData(
              minX: 4,
              maxX: 16,
              minY: 600,
              maxY: 2200,
              gridData: _defaultGridData(horizontalInterval: 400),
              borderData: _defaultBorderData(),
              titlesData: _defaultTitlesData(
                xUnit: '%',
                yUnit: '',
                xInterval: 2,
                yInterval: 400,
              ),
              extraLinesData: ExtraLinesData(
                verticalLines: [
                  VerticalLine(
                    x: _vamGradient,
                    color: AppColors.goldAccent,
                    strokeWidth: 1.5,
                    dashArray: [5, 4],
                  ),
                ],
              ),
              lineBarsData: [
                _lineSeries(buildVamCurve(4.8), AppColors.textSecondary),
                _lineSeries(buildVamCurve(_vamWkg), AppColors.goldAccent, showArea: true),
                _lineSeries(buildVamCurve(6.4), AppColors.statusSuccess),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ParameterSlider(
          label: 'Moc względna (W/kg)',
          valueText: '${_vamWkg.toStringAsFixed(1)} W/kg',
          value: _vamWkg,
          min: 4.0,
          max: 6.8,
          divisions: 28,
          accentColor: AppColors.goldAccent,
          onChanged: (v) => setState(() => _vamWkg = v),
        ),
        _ParameterSlider(
          label: 'Nachylenie podjazdu',
          valueText: '${_vamGradient.toStringAsFixed(1)} %',
          value: _vamGradient,
          min: 4.0,
          max: 16.0,
          divisions: 24,
          accentColor: AppColors.accentBlue,
          onChanged: (v) => setState(() => _vamGradient = v),
        ),
      ],
    );
  }

  // 7. Echelons Tactical Diagram
  Widget _buildEchelonDiagram({required bool isMobile}) {
    final slots = EncyclopediaPhysicsCalculator.echelonEffortDistribution(
      windSpeedKmh: _windSpeedKmh,
      windAngleDeg: _windAngleDeg,
    );
    final double crosswindKmh =
        _windSpeedKmh * math.sin(_windAngleDeg * math.pi / 180.0).abs();
    final bool highRisk = crosswindKmh >= 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TelemetryReadoutChip(
              label: 'Składowa boczna wiatru',
              value: '${crosswindKmh.toStringAsFixed(1)} km/h',
              color: highRisk ? AppColors.crimsonAlert : AppColors.statusSuccess,
            ),
            _TelemetryReadoutChip(
              label: 'Ryzyko rantów',
              value: highRisk ? 'WYSOKIE (WACHLARZ)' : 'NISKIE',
              color: highRisk ? AppColors.amberWarning : AppColors.statusSuccess,
            ),
            _TelemetryReadoutChip(
              label: 'Oszczędność w 3. kole',
              value: '-${slots[2].draftSavingPercent.round()}% mocy',
              color: AppColors.accentBlue,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: isMobile ? 200 : 230,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: CustomPaint(
              painter: _EchelonTacticalPainter(
                windAngleDeg: _windAngleDeg,
                windSpeedKmh: _windSpeedKmh,
                slots: slots,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ParameterSlider(
          label: 'Prędkość wiatru',
          valueText: '${_windSpeedKmh.round()} km/h',
          value: _windSpeedKmh,
          min: 10,
          max: 60,
          divisions: 50,
          accentColor: AppColors.accentBlue,
          onChanged: (v) => setState(() => _windSpeedKmh = v),
        ),
        _ParameterSlider(
          label: 'Kąt natarcia na szosę',
          valueText: '${_windAngleDeg.round()}°',
          value: _windAngleDeg,
          min: 15,
          max: 90,
          divisions: 15,
          accentColor: AppColors.amberWarning,
          onChanged: (v) => setState(() => _windAngleDeg = v),
        ),
      ],
    );
  }

  // 8. Sprint Trains Chart
  Widget _buildSprintTrainChart({required bool isMobile}) {
    final profile = EncyclopediaPhysicsCalculator.sprintTrainProfile(
      eliteLeadout: _eliteSprintLeadout,
    );
    final double peakSpeed = profile.map((p) => p.speedKmh).reduce(math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _TelemetryReadoutChip(
              label: 'Prędkość szczytowa (Slingshot)',
              value: '${peakSpeed.toStringAsFixed(1)} km/h',
              color: AppColors.primaryAccent,
            ),
            _TelemetryReadoutChip(
              label: 'Prędkość na Flamme Rouge',
              value: '${profile[3].speedKmh.toStringAsFixed(1)} km/h',
              color: AppColors.goldAccent,
            ),
            _ActionPillButton(
              label: _eliteSprintLeadout
                  ? 'Tryb: Elitarny Pociąg WT'
                  : 'Tryb: Pociąg Kontynentalny',
              icon: Icons.swap_horiz_rounded,
              onPressed: () =>
                  setState(() => _eliteSprintLeadout = !_eliteSprintLeadout),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: isMobile ? 220 : 260,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 3000,
              minY: 50,
              maxY: 80,
              gridData: _defaultGridData(horizontalInterval: 5),
              borderData: _defaultBorderData(),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    interval: 5,
                    getTitlesWidget: (v, _) =>
                        Text('${v.toInt()} km/h', style: _axisLabelStyle),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 500,
                    getTitlesWidget: (v, _) {
                      final int dist = (3000 - v).round();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('${dist}m', style: _axisLabelStyle),
                      );
                    },
                  ),
                ),
              ),
              extraLinesData: ExtraLinesData(
                verticalLines: [
                  VerticalLine(
                    x: 2000,
                    color: AppColors.crimsonAlert.withValues(alpha: 0.75),
                    strokeWidth: 1.5,
                    dashArray: [5, 4],
                    label: VerticalLineLabel(
                      show: true,
                      labelResolver: (_) => '1 km',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.crimsonAlert,
                      ),
                    ),
                  ),
                  VerticalLine(
                    x: 2750,
                    color: AppColors.goldAccent,
                    strokeWidth: 1.5,
                    dashArray: [4, 4],
                    label: VerticalLineLabel(
                      show: true,
                      labelResolver: (_) => '250m Proca',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                ],
              ),
              lineBarsData: [
                _lineSeries(
                  profile
                      .map(
                        (p) => FlSpot(3000.0 - p.metersToFinish, p.speedKmh),
                      )
                      .toList(),
                  AppColors.goldAccent,
                  showArea: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 9. 3-Kilometer Rule Interactive Explorer
  Widget _buildThreeKmRuleExplorer({required bool isMobile}) {
    final scenario = InGameCyclingEncyclopediaScreen.threeKmScenarios.firstWhere(
      (s) => s.id == _selectedThreeKmScenarioId,
      orElse: () => InGameCyclingEncyclopediaScreen.threeKmScenarios.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: InGameCyclingEncyclopediaScreen.threeKmScenarios.map((s) {
            final bool selected = s.id == _selectedThreeKmScenarioId;
            return _ScenarioSelectorChip(
              label: s.title,
              selected: selected,
              applies: s.ruleApplies,
              onTap: () => setState(() => _selectedThreeKmScenarioId = s.id),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Container(
          height: isMobile ? 140 : 155,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: CustomPaint(
              painter: _ThreeKmRuleTimelinePainter(scenario: scenario),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (scenario.ruleApplies
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (scenario.ruleApplies
                      ? AppColors.statusSuccess
                      : AppColors.crimsonAlert)
                  .withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    scenario.ruleApplies
                        ? Icons.verified_user_rounded
                        : Icons.warning_amber_rounded,
                    size: 18,
                    color: scenario.ruleApplies
                        ? AppColors.statusSuccess
                        : AppColors.crimsonAlert,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      scenario.verdict,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: scenario.ruleApplies
                            ? AppColors.statusSuccess
                            : AppColors.crimsonAlert,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                scenario.explanation,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static const TextStyle _axisLabelStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10.5,
    color: AppColors.textSecondary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  FlGridData _defaultGridData({required double horizontalInterval}) {
    return FlGridData(
      show: true,
      drawVerticalLine: true,
      horizontalInterval: horizontalInterval,
      getDrawingHorizontalLine: (_) => FlLine(
        color: AppTheme.borderColor.withValues(alpha: 0.7),
        strokeWidth: 1,
      ),
      getDrawingVerticalLine: (_) => FlLine(
        color: AppTheme.borderColor.withValues(alpha: 0.45),
        strokeWidth: 1,
      ),
    );
  }

  FlBorderData _defaultBorderData() {
    return FlBorderData(
      show: true,
      border: Border.all(color: AppTheme.borderColor, width: 1),
    );
  }

  FlTitlesData _defaultTitlesData({
    required String xUnit,
    required String yUnit,
    required double xInterval,
    required double yInterval,
  }) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 48,
          interval: yInterval,
          getTitlesWidget: (val, _) => Text(
            '${val.toInt()}$yUnit',
            style: _axisLabelStyle,
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: xInterval,
          getTitlesWidget: (val, _) => Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('${val.toInt()}$xUnit', style: _axisLabelStyle),
          ),
        ),
      ),
    );
  }

  LineChartBarData _lineSeries(
    List<FlSpot> spots,
    Color color, {
    bool showArea = false,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.28,
      color: color,
      barWidth: 2.8,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: showArea,
        color: color.withValues(alpha: 0.14),
      ),
    );
  }
}

class _EchelonTacticalPainter extends CustomPainter {
  const _EchelonTacticalPainter({
    required this.windAngleDeg,
    required this.windSpeedKmh,
    required this.slots,
  });

  final double windAngleDeg;
  final double windSpeedKmh;
  final List<({int slot, double effortPercent, double draftSavingPercent})> slots;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint roadPaint = Paint()..color = const Color(0xFF1F242D);
    final double roadTop = size.height * 0.22;
    final double roadBottom = size.height * 0.86;
    canvas.drawRect(
      Rect.fromLTRB(0, roadTop, size.width, roadBottom),
      roadPaint,
    );

    final Paint edgePaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.4)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, roadTop), Offset(size.width, roadTop), edgePaint);
    canvas.drawLine(
      Offset(0, roadBottom),
      Offset(size.width, roadBottom),
      edgePaint,
    );

    // Draw wind vector arrows at top
    final double windRad = windAngleDeg * math.pi / 180.0;
    final Paint windPaint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final Offset start = Offset(size.width * (0.18 + i * 0.22), 14);
      final Offset end = start +
          Offset(-math.cos(windRad) * 26, math.sin(windRad) * 26);
      canvas.drawLine(start, end, windPaint);
      canvas.drawCircle(end, 2.5, windPaint);
    }

    // Draw 8 riders forming a diagonal echelon across the road
    final double startX = size.width * 0.82;
    final double stepX = size.width * 0.085;
    for (int i = 0; i < slots.length; i++) {
      final s = slots[i];
      final bool inGutter = s.slot > 5;
      final double x = startX - i * stepX;
      final double y = inGutter
          ? roadBottom - 16
          : roadTop + 20 + i * ((roadBottom - roadTop - 44) / 5.0);

      final Color dotColor = s.slot == 1
          ? AppColors.goldAccent
          : inGutter
              ? AppColors.crimsonAlert
              : AppColors.statusSuccess;

      canvas.drawCircle(
        Offset(x, y),
        9,
        Paint()..color = dotColor.withValues(alpha: 0.22),
      );
      canvas.drawCircle(
        Offset(x, y),
        5.5,
        Paint()..color = dotColor,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${s.effortPercent.round()}%',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: dotColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - 20));
    }
  }

  @override
  bool shouldRepaint(covariant _EchelonTacticalPainter oldDelegate) {
    return oldDelegate.windAngleDeg != windAngleDeg ||
        oldDelegate.windSpeedKmh != windSpeedKmh;
  }
}

class _ThreeKmRuleTimelinePainter extends CustomPainter {
  const _ThreeKmRuleTimelinePainter({required this.scenario});

  final ThreeKmRuleScenario scenario;

  @override
  void paint(Canvas canvas, Size size) {
    final double y = size.height * 0.56;
    const double leftX = 28;
    final double rightX = size.width - 28;
    final double width = rightX - leftX;

    // 5 km total timeline: left = 5.0 km, right = 0.0 km (Meta)
    final double threeKmX = leftX + width * (2.0 / 5.0);
    final double incidentX =
        leftX + width * ((5.0 - scenario.distanceToFinishKm) / 5.0);

    // Highlight protected 3 km zone
    canvas.drawRect(
      Rect.fromLTRB(threeKmX, y - 26, rightX, y + 26),
      Paint()
        ..color = (scenario.ruleApplies
                ? AppColors.statusSuccess
                : AppColors.amberWarning)
            .withValues(alpha: 0.14),
    );

    // Main road line
    canvas.drawLine(
      Offset(leftX, y),
      Offset(rightX, y),
      Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.6)
        ..strokeWidth = 3,
    );

    // 3 km arch marker
    canvas.drawLine(
      Offset(threeKmX, y - 32),
      Offset(threeKmX, y + 32),
      Paint()
        ..color = AppColors.goldAccent
        ..strokeWidth = 2,
    );

    // Finish line marker
    canvas.drawLine(
      Offset(rightX, y - 32),
      Offset(rightX, y + 32),
      Paint()
        ..color = AppColors.textPrimary
        ..strokeWidth = 2.5,
    );

    // Incident marker
    final Color incColor =
        scenario.ruleApplies ? AppColors.statusSuccess : AppColors.crimsonAlert;
    canvas.drawCircle(Offset(incidentX, y), 8, Paint()..color = incColor);

    void drawLabel(String text, Offset pos, Color color) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy));
    }

    drawLabel('5 km', Offset(leftX, y + 36), AppColors.textSecondary);
    drawLabel('STREFA 3 KM', Offset(threeKmX, y - 48), AppColors.goldAccent);
    drawLabel('META', Offset(rightX, y + 36), AppColors.textPrimary);
    drawLabel(
      '-${scenario.distanceToFinishKm.toStringAsFixed(1)} km',
      Offset(incidentX, y + 14),
      incColor,
    );
  }

  @override
  bool shouldRepaint(covariant _ThreeKmRuleTimelinePainter oldDelegate) {
    return oldDelegate.scenario.id != scenario.id;
  }
}

class _InfoSectionCard extends StatelessWidget {
  const _InfoSectionCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.body,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryReadoutChip extends StatelessWidget {
  const _TelemetryReadoutChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
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
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParameterSlider extends StatelessWidget {
  const _ParameterSlider({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.accentColor,
    required this.onChanged,
  });

  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              valueText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: accentColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accentColor,
            inactiveTrackColor: AppColors.surfaceLight,
            thumbColor: accentColor,
            overlayColor: accentColor.withValues(alpha: 0.18),
            trackHeight: 4,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _InteractiveIconButton extends StatefulWidget {
  const _InteractiveIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  State<_InteractiveIconButton> createState() => _InteractiveIconButtonState();
}

class _InteractiveIconButtonState extends State<_InteractiveIconButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final Color bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.35)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;
    final Color borderColor = !enabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _focused
            ? AppColors.goldAccent
            : AppTheme.borderColor;

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionPillButton extends StatefulWidget {
  const _ActionPillButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  State<_ActionPillButton> createState() => _ActionPillButtonState();
}

class _ActionPillButtonState extends State<_ActionPillButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final Color bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : _pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.35)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused ? AppColors.goldAccent : AppTheme.borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: enabled
                    ? AppColors.goldAccent
                    : AppColors.textSecondary.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterChip extends StatefulWidget {
  const _CategoryFilterChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final EncyclopediaCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_CategoryFilterChip> createState() => _CategoryFilterChipState();
}

class _CategoryFilterChipState extends State<_CategoryFilterChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.28)
        : _hovered
            ? AppColors.surfaceLight
            : AppColors.background;
    final Color border = widget.selected
        ? AppColors.goldAccent
        : _focused
            ? AppColors.goldAccent.withValues(alpha: 0.7)
            : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.category.icon,
                size: 14,
                color: widget.selected
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.category.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicPillButton extends StatefulWidget {
  const _TopicPillButton({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final EncyclopediaEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_TopicPillButton> createState() => _TopicPillButtonState();
}

class _TopicPillButtonState extends State<_TopicPillButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.entry.accentColor.withValues(alpha: 0.2)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.selected
                  ? widget.entry.accentColor
                  : AppTheme.borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.entry.icon,
                size: 14,
                color: widget.selected
                    ? widget.entry.accentColor
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.entry.shortLabel,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicSidebarTile extends StatefulWidget {
  const _TopicSidebarTile({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final EncyclopediaEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_TopicSidebarTile> createState() => _TopicSidebarTileState();
}

class _TopicSidebarTileState extends State<_TopicSidebarTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.selected
        ? widget.entry.accentColor.withValues(alpha: 0.14)
        : _hovered
            ? AppColors.surfaceLight
            : AppColors.background;
    final Color border = widget.selected
        ? widget.entry.accentColor
        : _focused
            ? AppColors.goldAccent
            : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: widget.selected ? 1.4 : 1.0),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: widget.entry.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.entry.icon,
                  size: 18,
                  color: widget.entry.accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.entry.shortLabel,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: widget.selected
                            ? AppColors.textPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.entry.badge,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: widget.entry.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.selected)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: widget.entry.accentColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScenarioSelectorChip extends StatefulWidget {
  const _ScenarioSelectorChip({
    required this.label,
    required this.selected,
    required this.applies,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool applies;
  final VoidCallback onTap;

  @override
  State<_ScenarioSelectorChip> createState() => _ScenarioSelectorChipState();
}

class _ScenarioSelectorChipState extends State<_ScenarioSelectorChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color statusColor =
        widget.applies ? AppColors.statusSuccess : AppColors.crimsonAlert;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: widget.selected
                ? statusColor.withValues(alpha: 0.16)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.selected ? statusColor : AppTheme.borderColor,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.selected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
