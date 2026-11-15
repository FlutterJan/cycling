import '../../models/career/career_save.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_health.dart';
import '../../models/rider/rider_physiology.dart';
import '../../models/rider/rider_power_profile.dart';
import '../../models/rider/rider_skills.dart';

/// Indywidualny kierunek i profil planu treningowego kolarza.
enum RiderTrainingFocus {
  /// Budowanie Bazy Tlenowej (Endurance Z2, pojemność glikogenu, niska intensywność)
  baseBuilding,

  /// Rozwój Mocy Progowej FTP / CP (Próg beztlenowy Z4, zdolność do długich podjazdów)
  ftpDevelopment,

  /// Interwały VO2max (Pułap tlenowy Z5, powtarzalność ataków pod górę 3-5 min)
  vo2maxIntervals,

  /// Trening Neuromuskularny i Sprintu (Moc maksymalna Z6/Z7, sprint z peletonu, W')
  sprintNeuromuscular,

  /// Specjalizacja Jazdy na Czas TT (Pozycja aerodynamiczna, jazda na lemondce)
  timeTrialAero,

  /// Aktywna Regeneracja i Tapering (Spadek zmęczenia ATL, wzrost świeżości TSB przed wyścigiem)
  activeRecovery;

  String toJson() => name;

  static RiderTrainingFocus fromJson(String value) {
    return RiderTrainingFocus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RiderTrainingFocus.baseBuilding,
    );
  }

  String get label {
    switch (this) {
      case RiderTrainingFocus.baseBuilding:
        return 'Budowanie Bazy Tlenowej (Z2)';
      case RiderTrainingFocus.ftpDevelopment:
        return 'Rozwój Mocy Progowej FTP (Z4)';
      case RiderTrainingFocus.vo2maxIntervals:
        return 'Interwały VO2max i Wspinaczka (Z5)';
      case RiderTrainingFocus.sprintNeuromuscular:
        return 'Trening Neuromuskularny Sprintu (Z7)';
      case RiderTrainingFocus.timeTrialAero:
        return 'Jazda na Czas i Pozycja Aero TT';
      case RiderTrainingFocus.activeRecovery:
        return 'Aktywna Regeneracja i Tapering (Z1)';
    }
  }

  String get description {
    switch (this) {
      case RiderTrainingFocus.baseBuilding:
        return 'Długie kilometry w tlenie. Wzrost pojemności magazynów glikogenu, spadek tętna spoczynkowego, stabilny wzrost CTL przy niskim ryzyku kontuzji.';
      case RiderTrainingFocus.ftpDevelopment:
        return 'Ciężkie powtórzenia na progu mleczanowym (SweetSpot/FTP). Podnosi bezwzględną i względną moc na 20-minutowych podjazdach.';
      case RiderTrainingFocus.vo2maxIntervals:
        return 'Katorżnicze interwały 3-5 minutowe na 110-120% FTP. Rozszerza pułap tlenowy, dynamikę na ściankach i baterię beztlenową W\'.';
      case RiderTrainingFocus.sprintNeuromuscular:
        return 'Maksymalne zrywy z zatrzymania i finisze z dużej prędkości. Buduje waty na 5-15 sekundach i koordynację układu nerwowego.';
      case RiderTrainingFocus.timeTrialAero:
        return 'Godziny na maszynie czasowej. Zwiększa tolerancję na skrajną pozycję aero na lemondce, redukuje współczynnik CdA i stabilizuje kadencję.';
      case RiderTrainingFocus.activeRecovery:
        return 'Spokojne kręcenie na małej tarczy, masaże i odnowa. Drastycznie obniża ostre zmęczenie (ATL), przywracając szczytową świeżość (TSB > +15).';
    }
  }
}

/// Intensywność realizowanego bloku treningowego.
enum TrainingIntensity {
  light,
  moderate,
  intensive,
  overreaching;

  String toJson() => name;

  static TrainingIntensity fromJson(String value) {
    return TrainingIntensity.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TrainingIntensity.moderate,
    );
  }

  String get label {
    switch (this) {
      case TrainingIntensity.light:
        return 'Lekka (Regeneracyjna)';
      case TrainingIntensity.moderate:
        return 'Umiarkowana (Standard)';
      case TrainingIntensity.intensive:
        return 'Wysoka (Blok przedstartowy)';
      case TrainingIntensity.overreaching:
        return 'Ekstremalna (Przeciążenie adaptacyjne)';
    }
  }

  double get tssMultiplier {
    switch (this) {
      case TrainingIntensity.light:
        return 0.65;
      case TrainingIntensity.moderate:
        return 1.00;
      case TrainingIntensity.intensive:
        return 1.35;
      case TrainingIntensity.overreaching:
        return 1.70;
    }
  }
}

/// Ośrodek zgrupowań wysokogórskich i adaptacji do hipoksji.
class AltitudeCampLocation {
  final String id;
  final String name;
  final String countryIso;
  final int altitudeMeters;
  final int costPerRiderPerDayEur;
  final double vo2maxBoostPct;
  final int ftpGainWatts;
  final double atlFatigueDaily;
  final String description;

  const AltitudeCampLocation({
    required this.id,
    required this.name,
    required this.countryIso,
    required this.altitudeMeters,
    required this.costPerRiderPerDayEur,
    required this.vo2maxBoostPct,
    required this.ftpGainWatts,
    required this.atlFatigueDaily,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'countryIso': countryIso,
      'altitudeMeters': altitudeMeters,
      'costPerRiderPerDayEur': costPerRiderPerDayEur,
      'vo2maxBoostPct': vo2maxBoostPct,
      'ftpGainWatts': ftpGainWatts,
      'atlFatigueDaily': atlFatigueDaily,
      'description': description,
    };
  }

  factory AltitudeCampLocation.fromJson(Map<String, dynamic> json) {
    return AltitudeCampLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      countryIso: json['countryIso'] as String,
      altitudeMeters: (json['altitudeMeters'] as num).toInt(),
      costPerRiderPerDayEur: (json['costPerRiderPerDayEur'] as num).toInt(),
      vo2maxBoostPct: (json['vo2maxBoostPct'] as num).toDouble(),
      ftpGainWatts: (json['ftpGainWatts'] as num).toInt(),
      atlFatigueDaily: (json['atlFatigueDaily'] as num).toDouble(),
      description: json['description'] as String,
    );
  }

  @override
  String toString() => '$name ($altitudeMeters m n.p.m., €$costPerRiderPerDayEur/dzień)';
}

/// Rezultat przeprowadzonego obozu wysokogórskiego (Altitude Camp).
class AltitudeCampOutcome {
  final String campName;
  final int altitudeMeters;
  final int durationDays;
  final int totalCostEur;
  final List<Rider> updatedRiders;
  final double averageFtpGainWatts;
  final double averageVo2maxGain;
  final double averageAtlFatigueAdded;
  final String doctorMedicalReport;
  final DateTime completionDate;

  const AltitudeCampOutcome({
    required this.campName,
    required this.altitudeMeters,
    required this.durationDays,
    required this.totalCostEur,
    required this.updatedRiders,
    required this.averageFtpGainWatts,
    required this.averageVo2maxGain,
    required this.averageAtlFatigueAdded,
    required this.doctorMedicalReport,
    required this.completionDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'campName': campName,
      'altitudeMeters': altitudeMeters,
      'durationDays': durationDays,
      'totalCostEur': totalCostEur,
      'updatedRiders': updatedRiders.map((r) => r.toJson()).toList(),
      'averageFtpGainWatts': averageFtpGainWatts,
      'averageVo2maxGain': averageVo2maxGain,
      'averageAtlFatigueAdded': averageAtlFatigueAdded,
      'doctorMedicalReport': doctorMedicalReport,
      'completionDate': completionDate.toIso8601String(),
    };
  }

  factory AltitudeCampOutcome.fromJson(Map<String, dynamic> json) {
    return AltitudeCampOutcome(
      campName: json['campName'] as String,
      altitudeMeters: (json['altitudeMeters'] as num).toInt(),
      durationDays: (json['durationDays'] as num).toInt(),
      totalCostEur: (json['totalCostEur'] as num).toInt(),
      updatedRiders: (json['updatedRiders'] as List<dynamic>)
          .map((e) => Rider.fromJson(e as Map<String, dynamic>))
          .toList(),
      averageFtpGainWatts: (json['averageFtpGainWatts'] as num).toDouble(),
      averageVo2maxGain: (json['averageVo2maxGain'] as num).toDouble(),
      averageAtlFatigueAdded: (json['averageAtlFatigueAdded'] as num).toDouble(),
      doctorMedicalReport: json['doctorMedicalReport'] as String,
      completionDate: DateTime.parse(json['completionDate'] as String),
    );
  }
}

/// Zaawansowany serwis zarządzania periodyzacją treningową, adaptacją fizjologiczną i obozami wysokogórskimi.
class TrainingAndCampsService {
  TrainingAndCampsService._();

  // ===========================================================================
  // BAZA PRESTIŻOWYCH OŚRODKÓW WYSOKOGÓRSKICH (ALTITUDE BASES)
  // ===========================================================================

  static const List<AltitudeCampLocation> availableCampLocations = [
    AltitudeCampLocation(
      id: 'camp_teide',
      name: 'Wulkan Teide (Teneryfa)',
      countryIso: 'ESP',
      altitudeMeters: 2150,
      costPerRiderPerDayEur: 320,
      vo2maxBoostPct: 2.8,
      ftpGainWatts: 11,
      atlFatigueDaily: 3.4,
      description:
          'Kultowa baza zwycięzców Tour de France (Parador de Las Cañadas). Bezwzględna hipoksja, stabilna pogoda i 40-kilometrowe podjazdy z poziomu oceanu na wulkan.',
    ),
    AltitudeCampLocation(
      id: 'camp_sierra_nevada',
      name: 'Sierra Nevada CAR (Andaluzja)',
      countryIso: 'ESP',
      altitudeMeters: 2320,
      costPerRiderPerDayEur: 290,
      vo2maxBoostPct: 3.1,
      ftpGainWatts: 12,
      atlFatigueDaily: 3.8,
      description:
          'Najwyżej położony olimpijski ośrodek w Europie (Centro de Alto Rendimiento). Ekstremalna wysokość i podjazdy pod Pico Veleta budują żelazną odporność na alpejskie szczyty.',
    ),
    AltitudeCampLocation(
      id: 'camp_livigno',
      name: 'Livigno & Passo dello Stelvio (Alpy)',
      countryIso: 'ITA',
      altitudeMeters: 1816,
      costPerRiderPerDayEur: 260,
      vo2maxBoostPct: 2.3,
      ftpGainWatts: 9,
      atlFatigueDaily: 2.9,
      description:
          'Włoska stolica kolarstwa wysokogórskiego u stóp przełęczy Stelvio, Gavia i Mortirolo. Idealne przygotowanie pod Giro d\'Italia i chłodne etapy alpejskie.',
    ),
    AltitudeCampLocation(
      id: 'camp_font_romeu',
      name: 'Font-Romeu (Pireneje)',
      countryIso: 'FRA',
      altitudeMeters: 1850,
      costPerRiderPerDayEur: 230,
      vo2maxBoostPct: 2.2,
      ftpGainWatts: 8,
      atlFatigueDaily: 2.6,
      description:
          'Prestiżowy francuski ośrodek przygotowań olimpijskich. Śródziemnomorski mikroklimat i zbalansowane obciążenie hipoksyjne przed blokiem pirenejskim.',
    ),
    AltitudeCampLocation(
      id: 'camp_st_moritz',
      name: 'St. Moritz & Bernina (Szwajcaria)',
      countryIso: 'SUI',
      altitudeMeters: 1822,
      costPerRiderPerDayEur: 420,
      vo2maxBoostPct: 2.5,
      ftpGainWatts: 10,
      atlFatigueDaily: 2.8,
      description:
          'Luksusowy kurort wysokogórski oferujący najwyższy standard odnowy biologicznej, komory kriogeniczne i perfekcyjną infrastrukturę szosową w dolinie Engadyny.',
    ),
  ];

  // ===========================================================================
  // 1. ORGANIZACJA I PRZEPROWADZENIE OBOZU WYSOKOGÓRSKIEGO (ALTITUDE CAMP)
  // ===========================================================================

  /// Organizuje i przeprowadza obóz wysokogórski dla wybranej grupy kolarzy:
  ///
  /// - Pobiera opłatę z budżetu klubu (koszt za osobodzień * liczba kolarzy * dni).
  /// - Trwale zwiększa parametry tlenowe: pułap VO2max, moc progową FTP i pojemność glikogenu.
  /// - Generuje wysokie chwilowe zmęczenie (ATL), które po powrocie (taperingu)
  ///   przekształca się w szczyt formy (superkompensacja TSB > +15).
  static ({CareerSave updatedSave, AltitudeCampOutcome outcome}) conductAltitudeCamp({
    required CareerSave currentSave,
    required AltitudeCampLocation location,
    required List<String> riderIds,
    required int durationDays, // np. 10, 14, 21 dni
  }) {
    if (riderIds.isEmpty) {
      throw ArgumentError('Lista kolarzy na obóz nie może być pusta.');
    }
    if (durationDays < 7 || durationDays > 28) {
      throw ArgumentError('Czas trwania obozu wysokogórskiego musi wynosić od 7 do 28 dni.');
    }

    final playerTeam = currentSave.playerTeam;
    final int totalCostEur = location.costPerRiderPerDayEur * riderIds.length * durationDays;

    if (playerTeam.cashBalanceEur < totalCostEur) {
      throw StateError(
        'Niewystarczające środki w budżecie drużyny (€$totalCostEur wymagane na obóz w ${location.name}).',
      );
    }

    final coachLevel = playerTeam.staff.trainersLevel;
    final doctorLevel = playerTeam.staff.doctorsLevel;
    final staffQualityMultiplier = 0.85 + (coachLevel + doctorLevel) / 200.0 * 0.30;

    final List<Rider> updatedCampRiders = [];
    double totalFtpGain = 0.0;
    double totalVo2Gain = 0.0;
    double totalAtlAdded = 0.0;

    for (final rId in riderIds) {
      final rider = currentSave.getRiderById(rId);
      if (rider == null) continue;

      // Adaptacja zależna od wieku i potencjału (młodsi i z potencjałem > 80 zyskują najwięcej)
      final double potentialFactor = (rider.potential / 80.0).clamp(0.85, 1.25);
      final double ageFactor = rider.age <= 28 ? 1.05 : (rider.age <= 33 ? 0.95 : 0.82);

      final double actualFtpGain =
          (location.ftpGainWatts * (durationDays / 14.0) * potentialFactor * ageFactor * staffQualityMultiplier)
              .clamp(3.0, 18.0);

      final double actualVo2Gain =
          (location.vo2maxBoostPct * (durationDays / 14.0) * potentialFactor * 0.01 * rider.physiology.vo2Max)
              .clamp(0.4, 3.2);

      final double actualAtlFatigue = (location.atlFatigueDaily * durationDays * 0.85).clamp(18.0, 55.0);
      final double ctlFitnessGain = (actualAtlFatigue * 0.42).clamp(8.0, 26.0);

      totalFtpGain += actualFtpGain;
      totalVo2Gain += actualVo2Gain;
      totalAtlAdded += actualAtlFatigue;

      // Aktualizacja fizjologii
      final newFtp = (rider.physiology.ftpWatts + actualFtpGain.round()).clamp(250, 520);
      final newVo2 = (rider.physiology.vo2Max + actualVo2Gain).clamp(55.0, 94.0);
      final newGlycogen = (rider.physiology.glycogenCapacityGrams + (durationDays * 2.5)).clamp(400.0, 750.0);

      final updatedPhysiology = rider.physiology.copyWith(
        ftpWatts: newFtp,
        vo2Max: newVo2,
        glycogenCapacityGrams: newGlycogen,
      );

      // Aktualizacja profilu mocy MMP (wzrost mocy 5m, 20m, 60m)
      final updatedPowerProfile = rider.powerProfile.copyWith(
        watts5m: (rider.powerProfile.watts5m + (actualFtpGain * 1.15).round()),
        watts20m: (rider.powerProfile.watts20m + actualFtpGain.round()),
        watts60m: (rider.powerProfile.watts60m + (actualFtpGain * 0.95).round()),
      );

      // Aktualizacja zmęczenia i bazy (ATL / CTL)
      final updatedHealth = rider.health.copyWith(
        acuteTrainingLoad: (rider.health.acuteTrainingLoad + actualAtlFatigue).clamp(10.0, 150.0),
        chronicTrainingLoad: (rider.health.chronicTrainingLoad + ctlFitnessGain).clamp(20.0, 160.0),
      );

      final updatedRider = rider.copyWith(
        physiology: updatedPhysiology,
        powerProfile: updatedPowerProfile,
        health: updatedHealth,
      );

      updatedCampRiders.add(updatedRider);
    }

    // Aktualizacja mapy kolarzy w zapisie
    final Map<String, Rider> ridersMap = {
      for (final r in currentSave.riders) r.id: r,
    };
    for (final r in updatedCampRiders) {
      ridersMap[r.id] = r;
    }

    // Wpis do księgi finansowej
    final ledgerEntry = CareerFinanceLedgerEntry(
      id: 'camp_${DateTime.now().millisecondsSinceEpoch}',
      date: currentSave.currentDate,
      category: FinanceCategory.facilityUpgrade,
      amountEur: -totalCostEur,
      description:
          'Zgrupowanie wysokogórskie w ${location.name} (${riderIds.length} kolarzy, $durationDays dni)',
    );

    final updatedTeams = currentSave.teams.map((t) {
      if (t.id == currentSave.playerTeamId) {
        return t.copyWith(cashBalanceEur: t.cashBalanceEur - totalCostEur);
      }
      return t;
    }).toList();

    final updatedSave = currentSave.copyWith(
      riders: ridersMap.values.toList(),
      teams: updatedTeams,
      financeLedger: [ledgerEntry, ...currentSave.financeLedger],
      lastSavedAt: DateTime.now(),
    );

    final double avgFtp = updatedCampRiders.isNotEmpty ? totalFtpGain / updatedCampRiders.length : 0.0;
    final double avgVo2 = updatedCampRiders.isNotEmpty ? totalVo2Gain / updatedCampRiders.length : 0.0;
    final double avgAtl = updatedCampRiders.isNotEmpty ? totalAtlAdded / updatedCampRiders.length : 0.0;

    final String doctorReport =
        'Zakończono $durationDays-dniowy blok hipoksyjny na wysokości ${location.altitudeMeters} m n.p.m. '
        'Badania krwi wykazały skok masy hemoglobiny oraz wzrost pułapu tlenowego o średnio +${avgVo2.toStringAsFixed(1)} ml/kg/min '
        'i mocy progowej o +${avgFtp.toStringAsFixed(1)}W. Kolarze kończą zgrupowanie z podwyższonym zmęczeniem (ATL +${avgAtl.round()}). '
        'Zalecam 5–7 dni aktywnego taperingu przed startem w Grand Tourze dla osiągnięcia szczytu superkompensacji!';

    final outcome = AltitudeCampOutcome(
      campName: location.name,
      altitudeMeters: location.altitudeMeters,
      durationDays: durationDays,
      totalCostEur: totalCostEur,
      updatedRiders: updatedCampRiders,
      averageFtpGainWatts: avgFtp,
      averageVo2maxGain: avgVo2,
      averageAtlFatigueAdded: avgAtl,
      doctorMedicalReport: doctorReport,
      completionDate: currentSave.currentDate,
    );

    return (updatedSave: updatedSave, outcome: outcome);
  }

  // ===========================================================================
  // 2. SYMULACJA TYGODNIOWEGO PLANU TRENINGOWEGO (INDIVIDUAL WEEKLY TRAINING)
  // ===========================================================================

  /// Aplikuje tygodniową dawkę adaptacji treningowej w wybranym kierunku ([RiderTrainingFocus]):
  ///
  /// - Uwzględnia wiek kolarza, potencjał, jakość trenerów w sztabie oraz wybraną intensywność.
  /// - Modyfikuje parametry fizjologiczne, profil mocy MMP oraz równowagę zmęczenia (ATL / CTL).
  static Rider applyWeeklyTrainingFocus({
    required Rider rider,
    required RiderTrainingFocus focus,
    TrainingIntensity intensity = TrainingIntensity.moderate,
    int coachStaffLevel = 75,
  }) {
    if (!rider.health.canTrain) {
      // Kolarz kontuzjowany – tylko powolny spadek zmęczenia
      final healedAtl = (rider.health.acuteTrainingLoad * 0.75).clamp(0.0, 150.0);
      final decayedCtl = (rider.health.chronicTrainingLoad * 0.95).clamp(0.0, 160.0);
      return rider.copyWith(
        health: rider.health.copyWith(
          acuteTrainingLoad: healedAtl,
          chronicTrainingLoad: decayedCtl,
        ),
      );
    }

    final double coachMult = 0.80 + (coachStaffLevel / 100.0) * 0.35;
    final double intensityMult = intensity.tssMultiplier;
    final double potentialMult = (rider.potential / 80.0).clamp(0.85, 1.25);
    final double ageMult = rider.age <= 27 ? 1.05 : (rider.age <= 32 ? 0.95 : 0.80);

    RiderPhysiology phys = rider.physiology;
    RiderPowerProfile pprof = rider.powerProfile;
    RiderSkills skills = rider.skills;
    double atlDelta = 0.0;
    double ctlDelta = 0.0;

    switch (focus) {
      case RiderTrainingFocus.baseBuilding:
        // Wzrost bazy CTL i glikogenu przy niskim ATL
        final double glycogenGain = (8.0 * intensityMult * coachMult).clamp(2.0, 15.0);
        phys = phys.copyWith(
          glycogenCapacityGrams: (phys.glycogenCapacityGrams + glycogenGain).clamp(400.0, 750.0),
        );
        atlDelta = 10.0 * intensityMult;
        ctlDelta = 7.0 * intensityMult * potentialMult;
        break;

      case RiderTrainingFocus.ftpDevelopment:
        // Wzrost mocy progowej FTP i mocy 20m
        final int ftpGain = (1.5 * intensityMult * coachMult * potentialMult * ageMult).round();
        if (ftpGain > 0) {
          phys = phys.copyWith(ftpWatts: (phys.ftpWatts + ftpGain).clamp(250, 520));
          pprof = pprof.copyWith(
            watts20m: pprof.watts20m + ftpGain,
            watts60m: pprof.watts60m + (ftpGain * 0.9).round(),
          );
        }
        atlDelta = 18.0 * intensityMult;
        ctlDelta = 11.0 * intensityMult;
        break;

      case RiderTrainingFocus.vo2maxIntervals:
        // Wzrost VO2max i mocy 3m / 5m
        final double vo2Gain = (0.25 * intensityMult * coachMult * potentialMult * ageMult).clamp(0.05, 0.60);
        final int w5mGain = (4 * intensityMult * coachMult).round();
        phys = phys.copyWith(
          vo2Max: (phys.vo2Max + vo2Gain).clamp(55.0, 94.0),
          wPrimeJoules: (phys.wPrimeJoules + 150).clamp(12000, 32000),
        );
        pprof = pprof.copyWith(
          watts3m: pprof.watts3m + (w5mGain * 1.15).round(),
          watts5m: pprof.watts5m + w5mGain,
        );
        atlDelta = 24.0 * intensityMult; // Bardzo wyczerpujące
        ctlDelta = 12.0 * intensityMult;
        break;

      case RiderTrainingFocus.sprintNeuromuscular:
        // Eksplozywność 5s i 15s oraz bateria W'
        final int sprintGain = (12 * intensityMult * coachMult * ageMult).round();
        final int wPrimeGain = (300 * intensityMult * coachMult).round();
        phys = phys.copyWith(
          wPrimeJoules: (phys.wPrimeJoules + wPrimeGain).clamp(12000, 34000),
        );
        pprof = pprof.copyWith(
          watts5s: pprof.watts5s + sprintGain,
          watts15s: pprof.watts15s + (sprintGain * 0.85).round(),
        );
        atlDelta = 16.0 * intensityMult;
        ctlDelta = 8.0 * intensityMult;
        break;

      case RiderTrainingFocus.timeTrialAero:
        // Poprawa pozycji aero TT i koordynacji na lemondce
        final int ttSkillGain = (1.2 * intensityMult * coachMult).round();
        skills = skills.copyWith(
          timeTrialPositioning: (skills.timeTrialPositioning + ttSkillGain).clamp(20, 99),
          aeroPositioning: (skills.aeroPositioning + (ttSkillGain > 0 ? 1 : 0)).clamp(20, 99),
        );
        pprof = pprof.copyWith(
          watts20m: pprof.watts20m + (1 * intensityMult).round(),
        );
        atlDelta = 15.0 * intensityMult;
        ctlDelta = 9.0 * intensityMult;
        break;

      case RiderTrainingFocus.activeRecovery:
        // Gwałtowny spadek zmęczenia ATL (tapering)
        atlDelta = -28.0;
        ctlDelta = -3.0; // Minimalny ubytek bazy
        break;
    }

    final newAtl = (rider.health.acuteTrainingLoad + atlDelta).clamp(0.0, 150.0);
    final newCtl = (rider.health.chronicTrainingLoad + ctlDelta).clamp(0.0, 160.0);

    return rider.copyWith(
      physiology: phys,
      powerProfile: pprof,
      skills: skills,
      health: rider.health.copyWith(
        acuteTrainingLoad: newAtl,
        chronicTrainingLoad: newCtl,
      ),
    );
  }

  // ===========================================================================
  // 3. KALKULACJA WSKAŹNIKA SUPERKOMPENSACJI I SZCZYTU FORMY (TSB PEAK)
  // ===========================================================================

  /// Wylicza współczynnik dyspozycji startowej kolarza w oparciu o model Banistera:
  ///
  /// - TSB = CTL - ATL
  /// - Optymalny szczyt formy (Peak Form): TSB od +12 do +25 pkt (+4.0% do mocy bezwzględnej).
  /// - Przetrenowanie / wyczerpanie: TSB < -25 pkt (-8.0% do mocy, ryzyko kraksy i choroby).
  static double calculateRiderSupercompensationFactor(RiderHealth health) {
    final double tsb = health.trainingStressBalance;

    if (tsb >= 10.0 && tsb <= 25.0) {
      // Idealny szczyt formy (Sweet Spot TSB)
      return 1.04; // +4% mocy i odporności na zakwaszenie
    } else if (tsb > 25.0) {
      // Zbyt duży de-load (utrata napięcia mięśniowego)
      return 1.00 - ((tsb - 25.0) * 0.002).clamp(0.0, 0.05);
    } else if (tsb >= 0.0 && tsb < 10.0) {
      // Dobra dyspozycja robocza
      return 1.01;
    } else if (tsb >= -15.0 && tsb < 0.0) {
      // Umiarkowane zmęczenie po etapach
      return 0.98;
    } else if (tsb >= -30.0 && tsb < -15.0) {
      // Wyraźne zmęczenie (ciężkie nogi)
      return 0.94;
    } else {
      // Skrajne wyczerpanie / stan przeciążenia
      return 0.88;
    }
  }
}

