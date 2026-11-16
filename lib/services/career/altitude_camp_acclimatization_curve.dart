import 'dart:math' as math;

import '../../models/rider/rider_physiology.dart';

/// Prestiżowe ośrodki obozów wysokogórskich obsługiwane przez model aklimatyzacji.
enum AltitudeCampSite {
  /// Sierra Nevada CAR (Andaluzja, Hiszpania) — 2320 m n.p.m.
  sierraNevada,

  /// Wulkan Teide (Teneryfa, Hiszpania) — 2150 m n.p.m.
  teide,

  /// Livigno & Passo dello Stelvio (Alpy, Włochy) — 1816 m n.p.m.
  livigno;

  /// Identyfikator spójny z `TrainingAndCampsService.availableCampLocations`.
  String get id {
    switch (this) {
      case AltitudeCampSite.sierraNevada:
        return 'camp_sierra_nevada';
      case AltitudeCampSite.teide:
        return 'camp_teide';
      case AltitudeCampSite.livigno:
        return 'camp_livigno';
    }
  }

  /// Czytelna nazwa ośrodka.
  String get displayName {
    switch (this) {
      case AltitudeCampSite.sierraNevada:
        return 'Sierra Nevada CAR';
      case AltitudeCampSite.teide:
        return 'Wulkan Teide';
      case AltitudeCampSite.livigno:
        return 'Livigno';
    }
  }

  /// Kod kraju ISO 3166-1 alpha-3.
  String get countryIso {
    switch (this) {
      case AltitudeCampSite.sierraNevada:
      case AltitudeCampSite.teide:
        return 'ESP';
      case AltitudeCampSite.livigno:
        return 'ITA';
    }
  }

  /// Wysokość położenia bazy treningowej [m n.p.m.].
  int get altitudeMeters {
    switch (this) {
      case AltitudeCampSite.sierraNevada:
        return 2320;
      case AltitudeCampSite.teide:
        return 2150;
      case AltitudeCampSite.livigno:
        return 1816;
    }
  }

  /// Szczytowy poziom ciężkości nóg w fazie adaptacji (dni 1–5 po zjeździe) [0.0 - 1.0].
  double get peakAdaptationLegHeaviness {
    switch (this) {
      case AltitudeCampSite.sierraNevada:
        return 0.30;
      case AltitudeCampSite.teide:
        return 0.26;
      case AltitudeCampSite.livigno:
        return 0.20;
    }
  }

  /// Szczytowy przyrost hematokrytu w punktach procentowych [p.p.] w fazie superkompensacji.
  double get peakHematocritDeltaPercentagePoints {
    switch (this) {
      case AltitudeCampSite.sierraNevada:
        return 2.4;
      case AltitudeCampSite.teide:
        return 2.2;
      case AltitudeCampSite.livigno:
        return 1.9;
    }
  }

  /// Szczytowy przyrost całkowitej masy hemoglobiny (Hbmass) [%].
  double get peakHemoglobinMassBoostPercent {
    switch (this) {
      case AltitudeCampSite.sierraNevada:
        return 5.4;
      case AltitudeCampSite.teide:
        return 5.0;
      case AltitudeCampSite.livigno:
        return 4.4;
    }
  }

  /// Minimalna zalecana długość obozu do uzyskania pełnej odpowiedzi erytropoetycznej [dni].
  int get optimalCampDurationDays {
    switch (this) {
      case AltitudeCampSite.sierraNevada:
        return 18;
      case AltitudeCampSite.teide:
        return 19;
      case AltitudeCampSite.livigno:
        return 21;
    }
  }

  String toJson() => name;

  static AltitudeCampSite fromJson(String value) {
    final normalized = value.trim().toLowerCase();
    for (final site in AltitudeCampSite.values) {
      if (site.name.toLowerCase() == normalized ||
          site.id.toLowerCase() == normalized ||
          site.displayName.toLowerCase() == normalized) {
        return site;
      }
    }
    if (normalized.contains('sierra')) return AltitudeCampSite.sierraNevada;
    if (normalized.contains('teide')) return AltitudeCampSite.teide;
    if (normalized.contains('livigno')) return AltitudeCampSite.livigno;
    return AltitudeCampSite.teide;
  }
}

/// Faza fizjologiczna krzywej aklimatyzacji po zjeździe z obozu wysokogórskiego.
enum AltitudeAcclimatizationPhase {
  /// Pobyt na obozie (dzień <= 0 po zjeździe): aktywna hipoksja i stymulacja EPO.
  onCampHypoxia,

  /// Dni 1–5 po zjeździe z gór: faza adaptacji (lekka ciężkość nóg, re-adaptacja osocza).
  postDescentAdaptation,

  /// Dzień 6 po zjeździe: stabilizacja nerwowo-mięśniowa i przejście do superkompensacji.
  transitionStabilization,

  /// Dni 7–24 po obozie: faza superkompensacji hematokrytu i masy hemoglobiny (+3.5% VO2max i regeneracji W').
  hematocritSupercompensation,

  /// Dni 25–32 po obozie: stopniowe wygasanie adaptacji hematologicznej.
  decayAndWashout,

  /// Powyżej 32 dni: powrót do wartości bazowych sprzed obozu.
  baseline;

  String get labelPl {
    switch (this) {
      case AltitudeAcclimatizationPhase.onCampHypoxia:
        return 'Hipoksja na obozie (stymulacja EPO)';
      case AltitudeAcclimatizationPhase.postDescentAdaptation:
        return 'Faza adaptacji (dni 1–5: lekka ciężkość nóg)';
      case AltitudeAcclimatizationPhase.transitionStabilization:
        return 'Stabilizacja po zjeździe (dzień 6)';
      case AltitudeAcclimatizationPhase.hematocritSupercompensation:
        return 'Superkompensacja hematokrytu i Hbmass (dni 7–24)';
      case AltitudeAcclimatizationPhase.decayAndWashout:
        return 'Wygasanie efektu wysokogórskiego (dni 25–32)';
      case AltitudeAcclimatizationPhase.baseline:
        return 'Poziom bazowy (poza oknem obozu)';
    }
  }

  String toJson() => name;

  static AltitudeAcclimatizationPhase fromJson(String value) {
    return AltitudeAcclimatizationPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AltitudeAcclimatizationPhase.baseline,
    );
  }
}

/// Punkt pomiarowy krzywej aklimatyzacji wysokogórskiej dla konkretnego dnia po zjeździe.
class AltitudeCampAcclimatizationPoint {
  /// Liczba dni od zjazdu z gór (0 = dzień zjazdu, 1..5 = adaptacja, 7..24 = superkompensacja).
  final int daysSinceDescent;

  /// Ośrodek wysokogórski, w którym odbył się obóz.
  final AltitudeCampSite campSite;

  /// Czas trwania obozu na wysokości [dni].
  final int campDurationDays;

  /// Aktualna faza krzywej fizjologicznej.
  final AltitudeAcclimatizationPhase phase;

  /// Wskaźnik ciężkości nóg w fazie adaptacji (0.0 = świeże nogi, 1.0 = skrajna ciężkość).
  final double legHeavinessPenalty;

  /// Chwilowy ujemny wpływ ciężkości nóg na odczuwalną dynamikę / świeżość [%].
  final double legHeavinessPercent;

  /// Mnożnik VO2max wynikający z obozu (np. 1.035 = +3.5%).
  final double vo2maxMultiplier;

  /// Procentowy bonus do VO2max (do +3.5%).
  final double vo2maxBoostPercent;

  /// Mnożnik tempa regeneracji baterii beztlenowej W' (np. 1.035 = +3.5%).
  final double wPrimeRecoveryMultiplier;

  /// Procentowy bonus do tempa regeneracji W' (do +3.5%).
  final double wPrimeRecoveryBoostPercent;

  /// Przyrost hematokrytu ponad wartość bazową [punkty procentowe].
  final double hematocritDeltaPercentagePoints;

  /// Przyrost całkowitej masy hemoglobiny (Hbmass) [%].
  final double hemoglobinMassBoostPercent;

  /// Zbiorcza gotowość startowa kolarza w kontekście adaptacji (0.0 - 100.0).
  final double netRaceReadinessScore;

  /// Zwięzły komentarz fizjologiczny dla dyrektora sportowego i lekarza ekipy.
  final String clinicalSummaryPl;

  const AltitudeCampAcclimatizationPoint({
    required this.daysSinceDescent,
    required this.campSite,
    required this.campDurationDays,
    required this.phase,
    required this.legHeavinessPenalty,
    required this.legHeavinessPercent,
    required this.vo2maxMultiplier,
    required this.vo2maxBoostPercent,
    required this.wPrimeRecoveryMultiplier,
    required this.wPrimeRecoveryBoostPercent,
    required this.hematocritDeltaPercentagePoints,
    required this.hemoglobinMassBoostPercent,
    required this.netRaceReadinessScore,
    required this.clinicalSummaryPl,
  });

  /// Czy kolarz znajduje się w optymalnym oknie superkompensacji (dni 7–24).
  bool get isInSupercompensationWindow =>
      phase == AltitudeAcclimatizationPhase.hematocritSupercompensation;

  /// Czy kolarz odczuwa lekką ciężkość nóg (dni 1–5 po zjeździe).
  bool get hasPostDescentLegHeaviness =>
      phase == AltitudeAcclimatizationPhase.postDescentAdaptation &&
      legHeavinessPenalty > 0.0;

  Map<String, dynamic> toJson() {
    return {
      'daysSinceDescent': daysSinceDescent,
      'campSite': campSite.toJson(),
      'campDurationDays': campDurationDays,
      'phase': phase.toJson(),
      'legHeavinessPenalty': legHeavinessPenalty,
      'legHeavinessPercent': legHeavinessPercent,
      'vo2maxMultiplier': vo2maxMultiplier,
      'vo2maxBoostPercent': vo2maxBoostPercent,
      'wPrimeRecoveryMultiplier': wPrimeRecoveryMultiplier,
      'wPrimeRecoveryBoostPercent': wPrimeRecoveryBoostPercent,
      'hematocritDeltaPercentagePoints': hematocritDeltaPercentagePoints,
      'hemoglobinMassBoostPercent': hemoglobinMassBoostPercent,
      'netRaceReadinessScore': netRaceReadinessScore,
      'clinicalSummaryPl': clinicalSummaryPl,
    };
  }

  factory AltitudeCampAcclimatizationPoint.fromJson(Map<String, dynamic> json) {
    return AltitudeCampAcclimatizationPoint(
      daysSinceDescent: (json['daysSinceDescent'] as num).toInt(),
      campSite: AltitudeCampSite.fromJson(json['campSite'] as String),
      campDurationDays: (json['campDurationDays'] as num).toInt(),
      phase: AltitudeAcclimatizationPhase.fromJson(json['phase'] as String),
      legHeavinessPenalty: (json['legHeavinessPenalty'] as num).toDouble(),
      legHeavinessPercent: (json['legHeavinessPercent'] as num).toDouble(),
      vo2maxMultiplier: (json['vo2maxMultiplier'] as num).toDouble(),
      vo2maxBoostPercent: (json['vo2maxBoostPercent'] as num).toDouble(),
      wPrimeRecoveryMultiplier:
          (json['wPrimeRecoveryMultiplier'] as num).toDouble(),
      wPrimeRecoveryBoostPercent:
          (json['wPrimeRecoveryBoostPercent'] as num).toDouble(),
      hematocritDeltaPercentagePoints:
          (json['hematocritDeltaPercentagePoints'] as num).toDouble(),
      hemoglobinMassBoostPercent:
          (json['hemoglobinMassBoostPercent'] as num).toDouble(),
      netRaceReadinessScore:
          (json['netRaceReadinessScore'] as num).toDouble(),
      clinicalSummaryPl: json['clinicalSummaryPl'] as String,
    );
  }
}

/// Okno szczytowej dyspozycji wyznaczone przez krzywą poobozową.
class AltitudePeakWindowRecommendation {
  final AltitudeCampSite campSite;
  final int supercompensationStartDay;
  final int optimalPeakDay;
  final int supercompensationEndDay;
  final double peakVo2maxBoostPercent;
  final double peakWPrimeRecoveryBoostPercent;
  final int recommendedDescentDaysBeforeTargetRace;

  const AltitudePeakWindowRecommendation({
    required this.campSite,
    required this.supercompensationStartDay,
    required this.optimalPeakDay,
    required this.supercompensationEndDay,
    required this.peakVo2maxBoostPercent,
    required this.peakWPrimeRecoveryBoostPercent,
    required this.recommendedDescentDaysBeforeTargetRace,
  });
}

/// Fizjologiczny model obozów wysokogórskich (Sierra Nevada, Teide, Livigno).
///
/// Modeluje dwufazową dynamikę powrotu na poziom morza po zgrupowaniu wysokogórskim:
/// 1. **Faza adaptacji (dni 1–5 po zjeździe z gór)**: lekka ciężkość nóg wynikająca
///    z przesunięcia objętości osocza i ponownej adaptacji nerwowo-mięśniowej.
/// 2. **Faza superkompensacji hematokrytu i masy hemoglobiny (dni 7–24 po obozie)**:
///    pełne wykorzystanie zwiększonej masy hemoglobiny (Hbmass) i hematokrytu,
///    przynoszące **+3.5% do VO2max** oraz **+3.5% do tempa regeneracji W'**.
class AltitudeCampAcclimatizationCurve {
  const AltitudeCampAcclimatizationCurve();

  /// Maksymalny fizjologiczny bonus do VO2max w fazie superkompensacji (+3.5%).
  static const double maxVo2maxBoostFraction = 0.035;

  /// Maksymalny fizjologiczny bonus do tempa regeneracji W' w fazie superkompensacji (+3.5%).
  static const double maxWPrimeRecoveryBoostFraction = 0.035;

  /// Granice czasowe fazy adaptacji (lekka ciężkość nóg).
  static const int adaptationStartDay = 1;
  static const int adaptationEndDay = 5;

  /// Dzień przejściowy pomiędzy fazą adaptacji a superkompensacją.
  static const int transitionDay = 6;

  /// Granice czasowe fazy superkompensacji hematokrytu i Hbmass.
  static const int supercompensationStartDay = 7;
  static const int supercompensationEndDay = 24;

  /// Koniec okna wygasania adaptacji hematologicznej.
  static const int washoutEndDay = 32;

  /// Oblicza pełny stan fizjologiczny kolarza w zadanym dniu po zjeździe z obozu.
  ///
  /// - [campSite]: ośrodek wysokogórski (Sierra Nevada, Teide, Livigno).
  /// - [daysSinceDescent]: dni od zjazdu z gór (`0` = dzień zjazdu, `1..5` = adaptacja,
  ///   `7..24` = superkompensacja, `> 24` = wygasanie).
  /// - [campDurationDays]: długość obozu w dniach (domyślnie `21`). Krótsze obozy
  ///   (< 14 dni) dają proporcjonalnie słabszą odpowiedź erytropoetyczną.
  /// - [individualResponderFactor]: indywidualna podatność kolarza na hipoksję
  ///   (`0.75` – `1.15`, domyślnie `1.0`).
  AltitudeCampAcclimatizationPoint evaluateDay({
    required AltitudeCampSite campSite,
    required int daysSinceDescent,
    int campDurationDays = 21,
    double individualResponderFactor = 1.0,
  }) {
    final safeDuration = campDurationDays.clamp(1, 42);
    final safeResponder = individualResponderFactor.clamp(0.5, 1.25);

    // Współczynnik nasycenia bodźca hipoksyjnego (pełne 100% przy >= optimalCampDurationDays).
    final durationSaturation = _computeDurationSaturation(
      campSite: campSite,
      campDurationDays: safeDuration,
    );
    final effectiveMagnitude =
        (durationSaturation * safeResponder).clamp(0.0, 1.15);

    final phase = _resolvePhase(daysSinceDescent);

    switch (phase) {
      case AltitudeAcclimatizationPhase.onCampHypoxia:
        final progress = (safeDuration / campSite.optimalCampDurationDays)
            .clamp(0.15, 1.0);
        final hctDelta =
            campSite.peakHematocritDeltaPercentagePoints * 0.55 * progress;
        final hbBoost =
            campSite.peakHemoglobinMassBoostPercent * 0.55 * progress;
        return AltitudeCampAcclimatizationPoint(
          daysSinceDescent: daysSinceDescent,
          campSite: campSite,
          campDurationDays: safeDuration,
          phase: phase,
          legHeavinessPenalty: 0.12,
          legHeavinessPercent: 1.0,
          vo2maxMultiplier: 1.0,
          vo2maxBoostPercent: 0.0,
          wPrimeRecoveryMultiplier: 1.0,
          wPrimeRecoveryBoostPercent: 0.0,
          hematocritDeltaPercentagePoints: _round2(hctDelta),
          hemoglobinMassBoostPercent: _round2(hbBoost),
          netRaceReadinessScore: 68.0,
          clinicalSummaryPl:
              '${campSite.displayName} (${campSite.altitudeMeters} m): aktywna stymulacja EPO w hipoksji.',
        );

      case AltitudeAcclimatizationPhase.postDescentAdaptation:
        // Dni 1–5: lekka ciężkość nóg (najwyższa w dniach 1–2, stopniowo maleje do dnia 5).
        final normalizedDay =
            (daysSinceDescent - adaptationStartDay) /
            (adaptationEndDay - adaptationStartDay); // 0.0 .. 1.0
        final heavinessCurve =
            math.sin((1.0 - normalizedDay * 0.72) * (math.pi / 2.0));
        final legHeavinessPenalty =
            (campSite.peakAdaptationLegHeaviness * heavinessCurve)
                .clamp(0.05, 0.45);
        final legHeavinessPercent =
            _round2(legHeavinessPenalty * 8.0); // ok. 0.6% - 2.4% ciężkości

        // Hematokryt i Hbmass są już podniesione, lecz układ krążenia reguluje objętość osocza.
        final hctDelta = campSite.peakHematocritDeltaPercentagePoints *
            0.78 *
            effectiveMagnitude;
        final hbBoost = campSite.peakHemoglobinMassBoostPercent *
            0.82 *
            effectiveMagnitude;
        final readiness = (74.0 - legHeavinessPenalty * 30.0 + normalizedDay * 8.0)
            .clamp(55.0, 88.0);

        return AltitudeCampAcclimatizationPoint(
          daysSinceDescent: daysSinceDescent,
          campSite: campSite,
          campDurationDays: safeDuration,
          phase: phase,
          legHeavinessPenalty: _round3(legHeavinessPenalty),
          legHeavinessPercent: legHeavinessPercent,
          vo2maxMultiplier: 1.0,
          vo2maxBoostPercent: 0.0,
          wPrimeRecoveryMultiplier: 1.0,
          wPrimeRecoveryBoostPercent: 0.0,
          hematocritDeltaPercentagePoints: _round2(hctDelta),
          hemoglobinMassBoostPercent: _round2(hbBoost),
          netRaceReadinessScore: _round1(readiness),
          clinicalSummaryPl:
              'Dzień $daysSinceDescent po zjeździe z ${campSite.displayName}: faza adaptacji, lekka ciężkość nóg (-${legHeavinessPercent.toStringAsFixed(1)}% świeżości). Zalecane rozjazdy regeneracyjne.',
        );

      case AltitudeAcclimatizationPhase.transitionStabilization:
        // Dzień 6: ustąpienie ciężkości nóg, płynne wejście w superkompensację.
        final vo2Fraction = maxVo2maxBoostFraction * 0.55 * effectiveMagnitude;
        final wPrimeFraction =
            maxWPrimeRecoveryBoostFraction * 0.55 * effectiveMagnitude;
        final hctDelta = campSite.peakHematocritDeltaPercentagePoints *
            0.92 *
            effectiveMagnitude;
        final hbBoost = campSite.peakHemoglobinMassBoostPercent *
            0.94 *
            effectiveMagnitude;

        return AltitudeCampAcclimatizationPoint(
          daysSinceDescent: daysSinceDescent,
          campSite: campSite,
          campDurationDays: safeDuration,
          phase: phase,
          legHeavinessPenalty: 0.0,
          legHeavinessPercent: 0.0,
          vo2maxMultiplier: _round4(1.0 + vo2Fraction),
          vo2maxBoostPercent: _round2(vo2Fraction * 100.0),
          wPrimeRecoveryMultiplier: _round4(1.0 + wPrimeFraction),
          wPrimeRecoveryBoostPercent: _round2(wPrimeFraction * 100.0),
          hematocritDeltaPercentagePoints: _round2(hctDelta),
          hemoglobinMassBoostPercent: _round2(hbBoost),
          netRaceReadinessScore: 89.0,
          clinicalSummaryPl:
              'Dzień 6 po obozie (${campSite.displayName}): ciężkość nóg ustąpiła, organizm wchodzi w okno superkompensacji.',
        );

      case AltitudeAcclimatizationPhase.hematocritSupercompensation:
        // Dni 7–24: pełna faza superkompensacji hematokrytu i masy hemoglobiny (+3.5% VO2max i W' recovery).
        final vo2Fraction =
            (maxVo2maxBoostFraction * effectiveMagnitude).clamp(0.0, 0.042);
        final wPrimeFraction =
            (maxWPrimeRecoveryBoostFraction * effectiveMagnitude)
                .clamp(0.0, 0.042);
        final hctDelta =
            campSite.peakHematocritDeltaPercentagePoints * effectiveMagnitude;
        final hbBoost =
            campSite.peakHemoglobinMassBoostPercent * effectiveMagnitude;

        // Najwyższa gotowość w środkowym oknie (dni 10–19)
        final distanceFromCenter = (daysSinceDescent - 15).abs() / 9.0;
        final readiness =
            (99.0 - distanceFromCenter * 4.0).clamp(92.0, 100.0);

        return AltitudeCampAcclimatizationPoint(
          daysSinceDescent: daysSinceDescent,
          campSite: campSite,
          campDurationDays: safeDuration,
          phase: phase,
          legHeavinessPenalty: 0.0,
          legHeavinessPercent: 0.0,
          vo2maxMultiplier: _round4(1.0 + vo2Fraction),
          vo2maxBoostPercent: _round2(vo2Fraction * 100.0),
          wPrimeRecoveryMultiplier: _round4(1.0 + wPrimeFraction),
          wPrimeRecoveryBoostPercent: _round2(wPrimeFraction * 100.0),
          hematocritDeltaPercentagePoints: _round2(hctDelta),
          hemoglobinMassBoostPercent: _round2(hbBoost),
          netRaceReadinessScore: _round1(readiness),
          clinicalSummaryPl:
              'Dzień $daysSinceDescent po obozie (${campSite.displayName}): superkompensacja Hct (+${hctDelta.toStringAsFixed(1)} p.p.) i Hbmass (+${hbBoost.toStringAsFixed(1)}%) — +${(vo2Fraction * 100.0).toStringAsFixed(1)}% VO2max i regeneracji W\'.',
        );

      case AltitudeAcclimatizationPhase.decayAndWashout:
        // Dni 25–32: łagodne wygasanie (krzywa cosinusowa od 1.0 do 0.0).
        final washoutProgress = ((daysSinceDescent - supercompensationEndDay) /
                (washoutEndDay - supercompensationEndDay))
            .clamp(0.0, 1.0);
        final retention = 0.5 * (1.0 + math.cos(washoutProgress * math.pi));

        final vo2Fraction =
            maxVo2maxBoostFraction * effectiveMagnitude * retention;
        final wPrimeFraction =
            maxWPrimeRecoveryBoostFraction * effectiveMagnitude * retention;
        final hctDelta = campSite.peakHematocritDeltaPercentagePoints *
            effectiveMagnitude *
            retention;
        final hbBoost = campSite.peakHemoglobinMassBoostPercent *
            effectiveMagnitude *
            retention;
        final readiness = 78.0 + retention * 16.0;

        return AltitudeCampAcclimatizationPoint(
          daysSinceDescent: daysSinceDescent,
          campSite: campSite,
          campDurationDays: safeDuration,
          phase: phase,
          legHeavinessPenalty: 0.0,
          legHeavinessPercent: 0.0,
          vo2maxMultiplier: _round4(1.0 + vo2Fraction),
          vo2maxBoostPercent: _round2(vo2Fraction * 100.0),
          wPrimeRecoveryMultiplier: _round4(1.0 + wPrimeFraction),
          wPrimeRecoveryBoostPercent: _round2(wPrimeFraction * 100.0),
          hematocritDeltaPercentagePoints: _round2(hctDelta),
          hemoglobinMassBoostPercent: _round2(hbBoost),
          netRaceReadinessScore: _round1(readiness),
          clinicalSummaryPl:
              'Dzień $daysSinceDescent po obozie (${campSite.displayName}): wygasanie adaptacji hematologicznej (+${(vo2Fraction * 100.0).toStringAsFixed(1)}% VO2max).',
        );

      case AltitudeAcclimatizationPhase.baseline:
        return AltitudeCampAcclimatizationPoint(
          daysSinceDescent: daysSinceDescent,
          campSite: campSite,
          campDurationDays: safeDuration,
          phase: phase,
          legHeavinessPenalty: 0.0,
          legHeavinessPercent: 0.0,
          vo2maxMultiplier: 1.0,
          vo2maxBoostPercent: 0.0,
          wPrimeRecoveryMultiplier: 1.0,
          wPrimeRecoveryBoostPercent: 0.0,
          hematocritDeltaPercentagePoints: 0.0,
          hemoglobinMassBoostPercent: 0.0,
          netRaceReadinessScore: 78.0,
          clinicalSummaryPl:
              'Efekt obozu w ${campSite.displayName} wygasł — parametry wróciły do poziomu bazowego.',
        );
    }
  }

  /// Generuje pełną krzywą aklimatyzacji dla zadanego zakresu dni po zjeździe.
  List<AltitudeCampAcclimatizationPoint> generateCurve({
    required AltitudeCampSite campSite,
    int campDurationDays = 21,
    int fromDay = 0,
    int toDay = 32,
    double individualResponderFactor = 1.0,
  }) {
    final start = math.min(fromDay, toDay);
    final end = math.max(fromDay, toDay);
    return List<AltitudeCampAcclimatizationPoint>.generate(
      end - start + 1,
      (index) => evaluateDay(
        campSite: campSite,
        daysSinceDescent: start + index,
        campDurationDays: campDurationDays,
        individualResponderFactor: individualResponderFactor,
      ),
    );
  }

  /// Nakłada efekt aktualnego dnia po obozie wysokogórskim na profil fizjologiczny kolarza.
  ///
  /// - W fazie adaptacji (dni 1–5) lekko podnosi odczuwalne zmęczenie (`fatigue`) z tytułu ciężkich nóg.
  /// - W fazie superkompensacji (dni 7–24) zwiększa `vo2Max` oraz `recoveryRate` (regeneracja W') o +3.5%.
  RiderPhysiology applyToPhysiology(
    RiderPhysiology physiology, {
    required AltitudeCampSite campSite,
    required int daysSinceDescent,
    int campDurationDays = 21,
    double individualResponderFactor = 1.0,
  }) {
    final point = evaluateDay(
      campSite: campSite,
      daysSinceDescent: daysSinceDescent,
      campDurationDays: campDurationDays,
      individualResponderFactor: individualResponderFactor,
    );

    final updatedVo2Max =
        _round2(physiology.vo2Max * point.vo2maxMultiplier);
    final updatedRecoveryRate =
        _round3(physiology.recoveryRate * point.wPrimeRecoveryMultiplier);
    final heavinessFatigueDelta = point.legHeavinessPenalty * 14.0;
    final updatedFatigue =
        (physiology.fatigue + heavinessFatigueDelta).clamp(0.0, 100.0);

    return physiology.copyWith(
      vo2Max: updatedVo2Max,
      recoveryRate: updatedRecoveryRate,
      fatigue: _round2(updatedFatigue),
    );
  }

  /// Wyznacza optymalne okno startowe oraz zalecany termin zjazdu z gór przed głównym celem.
  AltitudePeakWindowRecommendation recommendPeakWindow({
    required AltitudeCampSite campSite,
    int campDurationDays = 21,
    double individualResponderFactor = 1.0,
  }) {
    final peakPoint = evaluateDay(
      campSite: campSite,
      daysSinceDescent: 14,
      campDurationDays: campDurationDays,
      individualResponderFactor: individualResponderFactor,
    );

    return AltitudePeakWindowRecommendation(
      campSite: campSite,
      supercompensationStartDay: supercompensationStartDay,
      optimalPeakDay: 14,
      supercompensationEndDay: supercompensationEndDay,
      peakVo2maxBoostPercent: peakPoint.vo2maxBoostPercent,
      peakWPrimeRecoveryBoostPercent: peakPoint.wPrimeRecoveryBoostPercent,
      recommendedDescentDaysBeforeTargetRace: 12,
    );
  }

  AltitudeAcclimatizationPhase _resolvePhase(int daysSinceDescent) {
    if (daysSinceDescent <= 0) {
      return AltitudeAcclimatizationPhase.onCampHypoxia;
    }
    if (daysSinceDescent <= adaptationEndDay) {
      return AltitudeAcclimatizationPhase.postDescentAdaptation;
    }
    if (daysSinceDescent == transitionDay) {
      return AltitudeAcclimatizationPhase.transitionStabilization;
    }
    if (daysSinceDescent <= supercompensationEndDay) {
      return AltitudeAcclimatizationPhase.hematocritSupercompensation;
    }
    if (daysSinceDescent < washoutEndDay) {
      return AltitudeAcclimatizationPhase.decayAndWashout;
    }
    return AltitudeAcclimatizationPhase.baseline;
  }

  double _computeDurationSaturation({
    required AltitudeCampSite campSite,
    required int campDurationDays,
  }) {
    if (campDurationDays >= campSite.optimalCampDurationDays) {
      return 1.0;
    }
    if (campDurationDays <= 4) {
      return 0.15;
    }
    final ratio = campDurationDays / campSite.optimalCampDurationDays;
    return math.pow(ratio, 0.85).toDouble().clamp(0.15, 1.0);
  }

  static double _round1(double value) => (value * 10.0).round() / 10.0;
  static double _round2(double value) => (value * 100.0).round() / 100.0;
  static double _round3(double value) => (value * 1000.0).round() / 1000.0;
  static double _round4(double value) => (value * 10000.0).round() / 10000.0;
}
