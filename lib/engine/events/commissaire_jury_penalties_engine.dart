import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../models/rider/rider.dart';
import '../simulation/stage_results_calculator.dart';

/// Rodzaj wykroczenia podlegającego jurysdykcji Kolegium Sędziów UCI (Commissaires' Panel).
enum UciInfractionType {
  /// Zbyt długie holowanie / trzymanie się bidonu przy wozie technicznym ("Sticky Bottle").
  stickyBottle,

  /// Niebezpieczne zajechanie drogi lub zmiana toru jazdy w sprincie ("Irregular Sprint").
  irregularSprint,

  /// Nieprzepisowe korzystanie z cienia aerodynamicznego za pojazdem wyścigu.
  illegalDraftingBehindCar,

  /// Przyjmowanie prowiantu poza strefą bufetu lub w ostatnich 20 km.
  unprotectedFeedingZone,

  /// Jazda po chodniku, ścieżce rowerowej lub poboczu stanowiącym zagrożenie.
  sidewalkOrBikePathShortcut,

  /// Naruszenie przepisów technicznych (waga roweru < 6.80 kg, strój, numer).
  jerseyOrEquipmentViolation,

  /// Niesportowe zachowanie, popychanie lub obraza uczestników/sędziów.
  unsportingConduct;

  String toJson() => name;

  static UciInfractionType fromJson(String value) {
    return UciInfractionType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UciInfractionType.stickyBottle,
    );
  }

  String get displayLabelPl {
    switch (this) {
      case UciInfractionType.stickyBottle:
        return 'Sticky Bottle (holowanie za wozem)';
      case UciInfractionType.irregularSprint:
        return 'Irregular Sprint (zajechanie drogi)';
      case UciInfractionType.illegalDraftingBehindCar:
        return 'Jazda w tunelu za pojazdem';
      case UciInfractionType.unprotectedFeedingZone:
        return 'Nieprzepisowy bufet (<20 km / poza strefą)';
      case UciInfractionType.sidewalkOrBikePathShortcut:
        return 'Jazda po chodniku / ścieżce';
      case UciInfractionType.jerseyOrEquipmentViolation:
        return 'Naruszenie regulaminu sprzętu/stroju';
      case UciInfractionType.unsportingConduct:
        return 'Niesportowe zachowanie';
    }
  }

  String get uciArticleCode {
    switch (this) {
      case UciInfractionType.stickyBottle:
        return 'UCI Art. 2.12.007 / 4.2';
      case UciInfractionType.irregularSprint:
        return 'UCI Art. 2.12.007 / 5.1';
      case UciInfractionType.illegalDraftingBehindCar:
        return 'UCI Art. 2.12.007 / 4.3';
      case UciInfractionType.unprotectedFeedingZone:
        return 'UCI Art. 2.12.007 / 4.5';
      case UciInfractionType.sidewalkOrBikePathShortcut:
        return 'UCI Art. 2.12.007 / 7.1';
      case UciInfractionType.jerseyOrEquipmentViolation:
        return 'UCI Art. 2.12.007 / 1.1';
      case UciInfractionType.unsportingConduct:
        return 'UCI Art. 2.12.007 / 8.2';
    }
  }
}

/// Poziom dotkliwości sankcji sędziowskiej UCI.
enum PenaltySeverity {
  warning,
  minor,
  major,
  severe,
  disqualification;

  String toJson() => name;

  static PenaltySeverity fromJson(String value) {
    return PenaltySeverity.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PenaltySeverity.minor,
    );
  }

  String get labelPl {
    switch (this) {
      case PenaltySeverity.warning:
        return 'Ostrzeżenie';
      case PenaltySeverity.minor:
        return 'Kara drobna';
      case PenaltySeverity.major:
        return 'Kara poważna';
      case PenaltySeverity.severe:
        return 'Kara surowa';
      case PenaltySeverity.disqualification:
        return 'Dyskwalifikacja (DSQ)';
    }
  }
}

/// Zdarzenie zaobserwowane przez sędziów na trasie etapu przed wydaniem werdyktu.
class CommissaireObservationInput {
  final String riderId;
  final String riderName;
  final String teamId;
  final String teamName;
  final int bibNumber;
  final UciInfractionType infractionType;
  final double kilometerMark;

  /// Czas trzymania bidonu lub holowania przy wozie technicznym [s].
  final double stickyBottleDurationSeconds;

  /// Boczny odchyl toru jazdy w sprincie [m].
  final double sprintDeviationMeters;

  /// Czy manewr doprowadził do kraksy lub groźnej sytuacji na finiszu.
  final bool causedCrashOrNearMiss;

  /// Liczba wcześniejszych przewinień kolarza w tym wyścigu (0 = pierwsze).
  final int repeatOffenseCount;

  /// Czy zdarzenie nastąpiło w finałowych 20 km etapu.
  final bool isInFinal20Km;

  /// Czy zdarzenie miało miejsce podczas finiszu sprinterskiego.
  final bool isSprintFinish;

  /// Dodatkowy opis sytuacyjny od sędziego na motocyklu.
  final String? notes;

  const CommissaireObservationInput({
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.teamName,
    this.bibNumber = 1,
    required this.infractionType,
    required this.kilometerMark,
    this.stickyBottleDurationSeconds = 0.0,
    this.sprintDeviationMeters = 0.0,
    this.causedCrashOrNearMiss = false,
    this.repeatOffenseCount = 0,
    this.isInFinal20Km = false,
    this.isSprintFinish = false,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'teamId': teamId,
      'teamName': teamName,
      'bibNumber': bibNumber,
      'infractionType': infractionType.toJson(),
      'kilometerMark': kilometerMark,
      'stickyBottleDurationSeconds': stickyBottleDurationSeconds,
      'sprintDeviationMeters': sprintDeviationMeters,
      'causedCrashOrNearMiss': causedCrashOrNearMiss,
      'repeatOffenseCount': repeatOffenseCount,
      'isInFinal20Km': isInFinal20Km,
      'isSprintFinish': isSprintFinish,
      'notes': notes,
    };
  }

  factory CommissaireObservationInput.fromJson(Map<String, dynamic> json) {
    return CommissaireObservationInput(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      bibNumber: (json['bibNumber'] as num?)?.toInt() ?? 1,
      infractionType: UciInfractionType.fromJson(json['infractionType'] as String),
      kilometerMark: (json['kilometerMark'] as num).toDouble(),
      stickyBottleDurationSeconds: (json['stickyBottleDurationSeconds'] as num?)?.toDouble() ?? 0.0,
      sprintDeviationMeters: (json['sprintDeviationMeters'] as num?)?.toDouble() ?? 0.0,
      causedCrashOrNearMiss: json['causedCrashOrNearMiss'] as bool? ?? false,
      repeatOffenseCount: (json['repeatOffenseCount'] as num?)?.toInt() ?? 0,
      isInFinal20Km: json['isInFinal20Km'] as bool? ?? false,
      isSprintFinish: json['isSprintFinish'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }
}

/// Oficjalna decyzja dyscyplinarna Kolegium Sędziów UCI.
class CommissairePenaltyDecision {
  final String id;
  final String riderId;
  final String riderName;
  final String teamId;
  final String teamName;
  final int bibNumber;
  final UciInfractionType infractionType;
  final PenaltySeverity severity;
  final double kilometerMark;

  /// Nałożona kara czasowa do klasyfikacji generalnej/etapu [s].
  final int timePenaltySeconds;

  /// Relegacja na koniec grupy, w której kolarz przekroczył linię mety.
  final bool relegateToBackOfGroup;

  /// Wykluczenie z wyścigu (DSQ).
  final bool disqualified;

  /// Grzywna finansowa nałożona na kolarza w frankach szwajcarskich [CHF].
  final int fineChf;

  /// Grzywna nałożona na dyrektora sportowego / wóz techniczny [CHF].
  final int teamDirectorFineChf;

  /// Odjęte punkty w klasyfikacji punktowej (zielona koszulka).
  final int pointsClassificationPenalty;

  /// Odjęte punkty w klasyfikacji górskiej (KOM).
  final int komPointsPenalty;

  /// Odjęte punkty w rankingu światowym UCI.
  final int uciPointsPenalty;

  /// Czy przyznano żółtą kartkę UCI (system kartek 2025+).
  final bool yellowCardIssued;

  /// Uzasadnienie decyzji w języku polskim.
  final String officialReasonPl;

  /// Uzasadnienie decyzji w języku angielskim (komunikat UCI).
  final String officialReasonEn;

  /// Kod artykułu z regulaminu UCI.
  final String uciArticleCode;

  const CommissairePenaltyDecision({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.teamName,
    required this.bibNumber,
    required this.infractionType,
    required this.severity,
    required this.kilometerMark,
    required this.timePenaltySeconds,
    required this.relegateToBackOfGroup,
    required this.disqualified,
    required this.fineChf,
    this.teamDirectorFineChf = 0,
    this.pointsClassificationPenalty = 0,
    this.komPointsPenalty = 0,
    this.uciPointsPenalty = 0,
    this.yellowCardIssued = false,
    required this.officialReasonPl,
    required this.officialReasonEn,
    required this.uciArticleCode,
  });

  /// Łączna grzywna (kolarz + dyrektor sportowy) w CHF.
  int get totalFineChf => fineChf + teamDirectorFineChf;

  /// Równowartość grzywny w EUR wg kursu regulaminowego.
  int get fineEurEquivalent => CommissaireJuryPenaltiesEngine.convertChfToEur(totalFineChf);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'riderId': riderId,
      'riderName': riderName,
      'teamId': teamId,
      'teamName': teamName,
      'bibNumber': bibNumber,
      'infractionType': infractionType.toJson(),
      'severity': severity.toJson(),
      'kilometerMark': kilometerMark,
      'timePenaltySeconds': timePenaltySeconds,
      'relegateToBackOfGroup': relegateToBackOfGroup,
      'disqualified': disqualified,
      'fineChf': fineChf,
      'teamDirectorFineChf': teamDirectorFineChf,
      'pointsClassificationPenalty': pointsClassificationPenalty,
      'komPointsPenalty': komPointsPenalty,
      'uciPointsPenalty': uciPointsPenalty,
      'yellowCardIssued': yellowCardIssued,
      'officialReasonPl': officialReasonPl,
      'officialReasonEn': officialReasonEn,
      'uciArticleCode': uciArticleCode,
    };
  }

  factory CommissairePenaltyDecision.fromJson(Map<String, dynamic> json) {
    return CommissairePenaltyDecision(
      id: json['id'] as String,
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      bibNumber: (json['bibNumber'] as num?)?.toInt() ?? 1,
      infractionType: UciInfractionType.fromJson(json['infractionType'] as String),
      severity: PenaltySeverity.fromJson(json['severity'] as String),
      kilometerMark: (json['kilometerMark'] as num).toDouble(),
      timePenaltySeconds: (json['timePenaltySeconds'] as num).toInt(),
      relegateToBackOfGroup: json['relegateToBackOfGroup'] as bool,
      disqualified: json['disqualified'] as bool,
      fineChf: (json['fineChf'] as num).toInt(),
      teamDirectorFineChf: (json['teamDirectorFineChf'] as num?)?.toInt() ?? 0,
      pointsClassificationPenalty: (json['pointsClassificationPenalty'] as num?)?.toInt() ?? 0,
      komPointsPenalty: (json['komPointsPenalty'] as num?)?.toInt() ?? 0,
      uciPointsPenalty: (json['uciPointsPenalty'] as num?)?.toInt() ?? 0,
      yellowCardIssued: json['yellowCardIssued'] as bool? ?? false,
      officialReasonPl: json['officialReasonPl'] as String,
      officialReasonEn: json['officialReasonEn'] as String,
      uciArticleCode: json['uciArticleCode'] as String,
    );
  }
}

/// Zbiorczy komunikat Kolegium Sędziów po etapie.
class CommissaireStageCommunique {
  final int stageNumber;
  final String stageName;
  final List<CommissairePenaltyDecision> decisions;
  final int totalTimePenaltiesSeconds;
  final int totalFinesChf;
  final int relegationsCount;
  final int yellowCardsCount;
  final int disqualificationsCount;
  final Map<String, int> finesByTeamChf;

  const CommissaireStageCommunique({
    required this.stageNumber,
    required this.stageName,
    required this.decisions,
    required this.totalTimePenaltiesSeconds,
    required this.totalFinesChf,
    required this.relegationsCount,
    required this.yellowCardsCount,
    required this.disqualificationsCount,
    required this.finesByTeamChf,
  });

  int get totalFinesEur => CommissaireJuryPenaltiesEngine.convertChfToEur(totalFinesChf);

  bool get hasAnyPenalties => decisions.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'stageNumber': stageNumber,
      'stageName': stageName,
      'decisions': decisions.map((d) => d.toJson()).toList(),
      'totalTimePenaltiesSeconds': totalTimePenaltiesSeconds,
      'totalFinesChf': totalFinesChf,
      'relegationsCount': relegationsCount,
      'yellowCardsCount': yellowCardsCount,
      'disqualificationsCount': disqualificationsCount,
      'finesByTeamChf': finesByTeamChf,
    };
  }

  factory CommissaireStageCommunique.fromJson(Map<String, dynamic> json) {
    final rawFines = json['finesByTeamChf'] as Map<String, dynamic>? ?? const {};
    return CommissaireStageCommunique(
      stageNumber: (json['stageNumber'] as num).toInt(),
      stageName: json['stageName'] as String,
      decisions: (json['decisions'] as List<dynamic>)
          .map((e) => CommissairePenaltyDecision.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalTimePenaltiesSeconds: (json['totalTimePenaltiesSeconds'] as num).toInt(),
      totalFinesChf: (json['totalFinesChf'] as num).toInt(),
      relegationsCount: (json['relegationsCount'] as num).toInt(),
      yellowCardsCount: (json['yellowCardsCount'] as num).toInt(),
      disqualificationsCount: (json['disqualificationsCount'] as num).toInt(),
      finesByTeamChf: rawFines.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }
}

/// Wewnętrzna definicja bazowej tabeli taryfikatora kar UCI.
class _UciPenaltyRuleSpec {
  final int baseTimePenaltySeconds;
  final int baseRiderFineChf;
  final int baseDirectorFineChf;
  final bool relegatesByDefault;
  final int basePointsPenalty;
  final int baseUciPointsPenalty;
  final bool issuesYellowCard;
  final PenaltySeverity baseSeverity;

  const _UciPenaltyRuleSpec({
    required this.baseTimePenaltySeconds,
    required this.baseRiderFineChf,
    this.baseDirectorFineChf = 0,
    this.relegatesByDefault = false,
    this.basePointsPenalty = 0,
    this.baseUciPointsPenalty = 0,
    this.issuesYellowCard = false,
    required this.baseSeverity,
  });
}

/// System sędziowski UCI oceniający przewinienia na trasie, nakładający kary czasowe,
/// relegacje w sprincie i grzywny finansowe w CHF oraz modyfikujący oficjalne wyniki etapu.
class CommissaireJuryPenaltiesEngine {
  static const int stickyBottleTimePenaltySeconds = 20;
  static const double stickyBottleThresholdSeconds = 3.5;
  static const int stickyBottleRiderFineChf = 200;
  static const int stickyBottleDirectorFineChf = 200;

  static const int irregularSprintFineChf = 500;
  static const int irregularSprintPointsPenalty = 15;
  static const double irregularSprintDeviationThresholdMeters = 1.2;

  static const double chfToEurRate = 1.04;

  static const Map<UciInfractionType, _UciPenaltyRuleSpec> _penaltySchedule = {
    UciInfractionType.stickyBottle: _UciPenaltyRuleSpec(
      baseTimePenaltySeconds: stickyBottleTimePenaltySeconds,
      baseRiderFineChf: stickyBottleRiderFineChf,
      baseDirectorFineChf: stickyBottleDirectorFineChf,
      basePointsPenalty: 4,
      baseUciPointsPenalty: 5,
      baseSeverity: PenaltySeverity.minor,
    ),
    UciInfractionType.irregularSprint: _UciPenaltyRuleSpec(
      baseTimePenaltySeconds: 0,
      baseRiderFineChf: irregularSprintFineChf,
      relegatesByDefault: true,
      basePointsPenalty: irregularSprintPointsPenalty,
      baseUciPointsPenalty: 15,
      issuesYellowCard: true,
      baseSeverity: PenaltySeverity.major,
    ),
    UciInfractionType.illegalDraftingBehindCar: _UciPenaltyRuleSpec(
      baseTimePenaltySeconds: 20,
      baseRiderFineChf: 200,
      baseDirectorFineChf: 200,
      basePointsPenalty: 4,
      baseUciPointsPenalty: 5,
      baseSeverity: PenaltySeverity.minor,
    ),
    UciInfractionType.unprotectedFeedingZone: _UciPenaltyRuleSpec(
      baseTimePenaltySeconds: 20,
      baseRiderFineChf: 200,
      baseDirectorFineChf: 200,
      baseSeverity: PenaltySeverity.minor,
    ),
    UciInfractionType.sidewalkOrBikePathShortcut: _UciPenaltyRuleSpec(
      baseTimePenaltySeconds: 0,
      baseRiderFineChf: 500,
      issuesYellowCard: true,
      baseSeverity: PenaltySeverity.major,
    ),
    UciInfractionType.jerseyOrEquipmentViolation: _UciPenaltyRuleSpec(
      baseTimePenaltySeconds: 0,
      baseRiderFineChf: 200,
      baseSeverity: PenaltySeverity.warning,
    ),
    UciInfractionType.unsportingConduct: _UciPenaltyRuleSpec(
      baseTimePenaltySeconds: 0,
      baseRiderFineChf: 500,
      issuesYellowCard: true,
      baseUciPointsPenalty: 10,
      baseSeverity: PenaltySeverity.severe,
    ),
  };

  const CommissaireJuryPenaltiesEngine();

  /// Konwertuje grzywnę z franków szwajcarskich (CHF) na euro (EUR).
  static int convertChfToEur(int amountChf) {
    if (amountChf <= 0) return 0;
    return (amountChf * chfToEurRate).round();
  }

  /// Ocenia pojedynczą obserwację sędziowską i zwraca decyzję lub `null`,
  /// jeśli wykroczenie nie przekroczyło progu regulaminowego.
  CommissairePenaltyDecision? evaluateObservation(
    CommissaireObservationInput input, {
    int stageNumber = 1,
  }) {
    if (!_meetsInfractionThreshold(input)) {
      return null;
    }

    final _UciPenaltyRuleSpec spec = _penaltySchedule[input.infractionType]!;
    final int repeatMultiplier = 1 + input.repeatOffenseCount.clamp(0, 3);

    int timePenalty = spec.baseTimePenaltySeconds;
    int riderFineChf = spec.baseRiderFineChf * repeatMultiplier;
    int directorFineChf = spec.baseDirectorFineChf * repeatMultiplier;
    bool relegate = spec.relegatesByDefault;
    bool disqualified = false;
    bool yellowCard = spec.issuesYellowCard;
    int pointsPenalty = spec.basePointsPenalty;
    int uciPointsPenalty = spec.baseUciPointsPenalty;
    PenaltySeverity severity = spec.baseSeverity;

    switch (input.infractionType) {
      case UciInfractionType.stickyBottle:
        // Standardowe holowanie >3.5s = +20 s; recydywa lub bardzo długie (>=10s) eskaluje karę.
        if (input.repeatOffenseCount >= 1 || input.stickyBottleDurationSeconds >= 10.0) {
          timePenalty = stickyBottleTimePenaltySeconds + (input.repeatOffenseCount * 10);
          severity = PenaltySeverity.major;
        }
        break;

      case UciInfractionType.irregularSprint:
        // Niebezpieczne zajechanie drogi w sprincie -> relegacja na koniec grupy + 500 CHF.
        // Powtórne lub powodujące kraksę na finiszu może skutkować dyskwalifikacją (DSQ).
        if (input.causedCrashOrNearMiss && input.repeatOffenseCount >= 1) {
          disqualified = true;
          relegate = false;
          riderFineChf = 1000;
          pointsPenalty = 50;
          uciPointsPenalty = 40;
          severity = PenaltySeverity.disqualification;
        } else if (input.causedCrashOrNearMiss) {
          riderFineChf = 500;
          severity = PenaltySeverity.severe;
        }
        break;

      case UciInfractionType.unprotectedFeedingZone:
        // Kara czasowa +20s obowiązuje w ostatnich 20 km; wcześniej wyłącznie grzywna CHF.
        if (!input.isInFinal20Km) {
          timePenalty = 0;
          severity = PenaltySeverity.warning;
        }
        break;

      case UciInfractionType.sidewalkOrBikePathShortcut:
        if (input.causedCrashOrNearMiss || input.repeatOffenseCount >= 1) {
          relegate = true;
          riderFineChf = 1000;
          severity = PenaltySeverity.severe;
        }
        break;

      case UciInfractionType.unsportingConduct:
        if (input.repeatOffenseCount >= 2 || input.causedCrashOrNearMiss) {
          disqualified = true;
          riderFineChf = 1000;
          severity = PenaltySeverity.disqualification;
        }
        break;

      case UciInfractionType.illegalDraftingBehindCar:
      case UciInfractionType.jerseyOrEquipmentViolation:
        break;
    }

    final String decisionId =
        'uci_s${stageNumber}_${input.riderId}_${input.infractionType.name}_${input.kilometerMark.round()}';

    return CommissairePenaltyDecision(
      id: decisionId,
      riderId: input.riderId,
      riderName: input.riderName,
      teamId: input.teamId,
      teamName: input.teamName,
      bibNumber: input.bibNumber,
      infractionType: input.infractionType,
      severity: severity,
      kilometerMark: input.kilometerMark,
      timePenaltySeconds: timePenalty,
      relegateToBackOfGroup: relegate,
      disqualified: disqualified,
      fineChf: riderFineChf,
      teamDirectorFineChf: directorFineChf,
      pointsClassificationPenalty: pointsPenalty,
      uciPointsPenalty: uciPointsPenalty,
      yellowCardIssued: yellowCard,
      officialReasonPl: _buildReasonPl(input, timePenalty, relegate, disqualified, riderFineChf),
      officialReasonEn: _buildReasonEn(input, timePenalty, relegate, disqualified, riderFineChf),
      uciArticleCode: input.infractionType.uciArticleCode,
    );
  }

  bool _meetsInfractionThreshold(CommissaireObservationInput input) {
    switch (input.infractionType) {
      case UciInfractionType.stickyBottle:
        return input.stickyBottleDurationSeconds >= stickyBottleThresholdSeconds;
      case UciInfractionType.irregularSprint:
        return input.sprintDeviationMeters >= irregularSprintDeviationThresholdMeters ||
            input.causedCrashOrNearMiss;
      case UciInfractionType.illegalDraftingBehindCar:
      case UciInfractionType.unprotectedFeedingZone:
      case UciInfractionType.sidewalkOrBikePathShortcut:
      case UciInfractionType.jerseyOrEquipmentViolation:
      case UciInfractionType.unsportingConduct:
        return true;
    }
  }

  /// Rozpatruje listę obserwacji po etapie i generuje pełny komunikat sędziowski.
  CommissaireStageCommunique evaluateStageObservations({
    required int stageNumber,
    required String stageName,
    required List<CommissaireObservationInput> observations,
  }) {
    final List<CommissairePenaltyDecision> decisions = [];
    final Map<String, int> finesByTeam = {};
    int totalTimePenalties = 0;
    int totalFines = 0;
    int relegations = 0;
    int yellowCards = 0;
    int disqualifications = 0;

    for (final obs in observations) {
      final decision = evaluateObservation(obs, stageNumber: stageNumber);
      if (decision == null) continue;

      decisions.add(decision);
      totalTimePenalties += decision.timePenaltySeconds;
      totalFines += decision.totalFineChf;
      if (decision.relegateToBackOfGroup) relegations++;
      if (decision.yellowCardIssued) yellowCards++;
      if (decision.disqualified) disqualifications++;

      finesByTeam[decision.teamId] =
          (finesByTeam[decision.teamId] ?? 0) + decision.totalFineChf;
    }

    return CommissaireStageCommunique(
      stageNumber: stageNumber,
      stageName: stageName,
      decisions: decisions,
      totalTimePenaltiesSeconds: totalTimePenalties,
      totalFinesChf: totalFines,
      relegationsCount: relegations,
      yellowCardsCount: yellowCards,
      disqualificationsCount: disqualifications,
      finesByTeamChf: finesByTeam,
    );
  }

  /// Nakłada zatwierdzone kary czasowe, relegacje w grupie oraz dyskwalifikacje
  /// na listę wyników etapu (`OfficialRiderStageResult`), przeliczając miejsca i straty.
  List<OfficialRiderStageResult> applyPenaltiesToStageResults({
    required List<OfficialRiderStageResult> results,
    required CommissaireStageCommunique communique,
    double sameGroupGapThresholdSeconds = 1.0,
  }) {
    if (results.isEmpty || !communique.hasAnyPenalties) {
      return List<OfficialRiderStageResult>.from(results);
    }

    // Zgrupuj kary po ID kolarza (kolarz może mieć więcej niż 1 wykroczenie na etapie).
    final Map<String, List<CommissairePenaltyDecision>> decisionsByRider = {};
    for (final d in communique.decisions) {
      decisionsByRider.putIfAbsent(d.riderId, () => []).add(d);
    }

    // Posortuj wyniki wejściowe po oficjalnym czasie i pozycji, by poprawnie wyznaczyć grupy finiszowe.
    final List<OfficialRiderStageResult> sortedInput = List<OfficialRiderStageResult>.from(results)
      ..sort((a, b) {
        if (a.isDnf != b.isDnf) return a.isDnf ? 1 : -1;
        if (a.isEliminatedOtl != b.isEliminatedOtl) return a.isEliminatedOtl ? 1 : -1;
        final timeCmp = a.officialFinishTimeSeconds.compareTo(b.officialFinishTimeSeconds);
        if (timeCmp != 0) return timeCmp;
        return a.rank.compareTo(b.rank);
      });

    // Wyznacz granice grup finiszowych przed relegacjami.
    final Map<String, int> riderGroupIndex = {};
    final Map<int, double> groupLastTime = {};
    int currentGroup = 0;
    double? prevTime;
    for (final r in sortedInput) {
      if (r.isDnf || r.isEliminatedOtl) continue;
      if (prevTime != null &&
          (r.officialFinishTimeSeconds - prevTime).abs() > sameGroupGapThresholdSeconds) {
        currentGroup++;
      }
      riderGroupIndex[r.riderId] = currentGroup;
      groupLastTime[currentGroup] = r.officialFinishTimeSeconds;
      prevTime = r.officialFinishTimeSeconds;
    }

    final List<_PenalizedRiderRecord> records = [];
    for (int i = 0; i < sortedInput.length; i++) {
      final r = sortedInput[i];
      final riderDecisions = decisionsByRider[r.riderId];
      if (riderDecisions == null || riderDecisions.isEmpty) {
        records.add(_PenalizedRiderRecord(
          result: r,
          originalOrder: i,
          isRelegatedInGroup: false,
          groupIndex: riderGroupIndex[r.riderId] ?? currentGroup + 1,
        ));
        continue;
      }

      int totalTimePen = 0;
      int totalPointsPen = 0;
      bool relegate = false;
      bool dsq = false;

      for (final d in riderDecisions) {
        totalTimePen += d.timePenaltySeconds;
        totalPointsPen += d.pointsClassificationPenalty;
        if (d.relegateToBackOfGroup) relegate = true;
        if (d.disqualified) dsq = true;
      }

      if (dsq) {
        records.add(_PenalizedRiderRecord(
          result: r.copyWith(
            isDnf: true,
            timeBonusSeconds: 0,
            pointsGreenJersey: 0,
            pointsKom: 0,
            prizeMoneyEur: 0,
          ),
          originalOrder: i,
          isRelegatedInGroup: false,
          groupIndex: 999999,
        ));
        continue;
      }

      final int grpIdx = riderGroupIndex[r.riderId] ?? 0;
      double adjustedTime = r.officialFinishTimeSeconds;
      if (relegate && groupLastTime.containsKey(grpIdx)) {
        // Relegacja na koniec grupy zachowuje czas grupy, ale przesuwa na jej koniec.
        adjustedTime = groupLastTime[grpIdx]!;
      }
      adjustedTime += totalTimePen.toDouble();

      final int adjustedGreenPoints = math.max(0, r.pointsGreenJersey - totalPointsPen);
      final int adjustedBonus = relegate ? 0 : r.timeBonusSeconds;

      records.add(_PenalizedRiderRecord(
        result: r.copyWith(
          officialFinishTimeSeconds: adjustedTime,
          pointsGreenJersey: adjustedGreenPoints,
          timeBonusSeconds: adjustedBonus,
        ),
        originalOrder: i,
        isRelegatedInGroup: relegate,
        groupIndex: grpIdx,
      ));
    }

    records.sort((a, b) {
      final aOut = a.result.isDnf || a.result.isEliminatedOtl;
      final bOut = b.result.isDnf || b.result.isEliminatedOtl;
      if (aOut != bOut) return aOut ? 1 : -1;
      if (aOut && bOut) return a.originalOrder.compareTo(b.originalOrder);

      final timeCmp = a.result.officialFinishTimeSeconds
          .compareTo(b.result.officialFinishTimeSeconds);
      if (timeCmp != 0) return timeCmp;

      // W obrębie tej samej grupy i czasu: kolarze bez relegacji przed relegowanymi.
      if (a.isRelegatedInGroup != b.isRelegatedInGroup) {
        return a.isRelegatedInGroup ? 1 : -1;
      }
      return a.originalOrder.compareTo(b.originalOrder);
    });

    final double? winnerTime = records.any((e) => !e.result.isDnf && !e.result.isEliminatedOtl)
        ? records
            .firstWhere((e) => !e.result.isDnf && !e.result.isEliminatedOtl)
            .result
            .officialFinishTimeSeconds
        : null;

    final List<OfficialRiderStageResult> updated = [];
    int rankCounter = 1;
    for (final rec in records) {
      final r = rec.result;
      if (r.isDnf || r.isEliminatedOtl) {
        updated.add(r.copyWith(rank: 999));
      } else {
        final double gap = winnerTime != null
            ? math.max(0.0, r.officialFinishTimeSeconds - winnerTime)
            : 0.0;
        updated.add(r.copyWith(
          rank: rankCounter,
          gapToWinnerSeconds: gap,
        ));
        rankCounter++;
      }
    }

    return updated;
  }

  /// Deterministycznie generuje obserwacje sędziowskie dla etapu na podstawie
  /// ziarna `seed` i charakterystyki trasy.
  List<CommissaireObservationInput> detectAndGenerateRandomStageIncidents({
    required List<Rider> riders,
    required int stageNumber,
    required int seed,
    double stageDistanceKm = 180.0,
    bool isSprintStage = false,
    bool hasHighMountain = false,
  }) {
    if (riders.isEmpty) return const [];

    final math.Random rng = math.Random(seed ^ (stageNumber * 7919));
    final List<CommissaireObservationInput> generated = [];

    // Szansa na Sticky Bottle rośnie na ciężkich etapach górskich.
    final double stickyChance = hasHighMountain ? 0.38 : 0.22;
    if (rng.nextDouble() < stickyChance) {
      final rider = riders[rng.nextInt(riders.length)];
      final double km = (stageDistanceKm * (0.45 + rng.nextDouble() * 0.4)).clamp(10.0, stageDistanceKm - 5.0);
      generated.add(CommissaireObservationInput(
        riderId: rider.id,
        riderName: rider.fullName,
        teamId: rider.teamId,
        teamName: rider.teamId,
        bibNumber: (rng.nextInt(176) + 1),
        infractionType: UciInfractionType.stickyBottle,
        kilometerMark: double.parse(km.toStringAsFixed(1)),
        stickyBottleDurationSeconds: 4.5 + rng.nextDouble() * 3.5,
      ));
    }

    // Szansa na Irregular Sprint na etapach sprinterskich.
    final double sprintChance = isSprintStage ? 0.28 : 0.08;
    if (rng.nextDouble() < sprintChance) {
      final rider = riders[rng.nextInt(riders.length)];
      generated.add(CommissaireObservationInput(
        riderId: rider.id,
        riderName: rider.fullName,
        teamId: rider.teamId,
        teamName: rider.teamId,
        bibNumber: (rng.nextInt(176) + 1),
        infractionType: UciInfractionType.irregularSprint,
        kilometerMark: stageDistanceKm,
        sprintDeviationMeters: 1.4 + rng.nextDouble() * 1.1,
        isSprintFinish: true,
        causedCrashOrNearMiss: rng.nextDouble() < 0.25,
      ));
    }

    return generated;
  }

  String _buildReasonPl(
    CommissaireObservationInput input,
    int timePenalty,
    bool relegate,
    bool disqualified,
    int fineChf,
  ) {
    final kmStr = input.kilometerMark.toStringAsFixed(1);
    final List<String> parts = [];
    if (timePenalty > 0) parts.add('+$timePenalty s kary czasowej');
    if (relegate) parts.add('relegacja na koniec grupy');
    if (disqualified) parts.add('dyskwalifikacja z wyścigu (DSQ)');
    if (fineChf > 0) parts.add('grzywna $fineChf CHF');

    return '${input.infractionType.displayLabelPl} na $kmStr km: ${parts.join(', ')}.';
  }

  String _buildReasonEn(
    CommissaireObservationInput input,
    int timePenalty,
    bool relegate,
    bool disqualified,
    int fineChf,
  ) {
    final kmStr = input.kilometerMark.toStringAsFixed(1);
    final List<String> parts = [];
    if (timePenalty > 0) parts.add('+$timePenalty s time penalty');
    if (relegate) parts.add('relegation to back of group');
    if (disqualified) parts.add('disqualification (DSQ)');
    if (fineChf > 0) parts.add('$fineChf CHF fine');

    return '${input.infractionType.name} at km $kmStr: ${parts.join(', ')}.';
  }
}

class _PenalizedRiderRecord {
  final OfficialRiderStageResult result;
  final int originalOrder;
  final bool isRelegatedInGroup;
  final int groupIndex;

  const _PenalizedRiderRecord({
    required this.result,
    required this.originalOrder,
    required this.isRelegatedInGroup,
    required this.groupIndex,
  });
}

/// Filtr widoku komunikatów Kolegium Sędziów UCI.
enum CommissaireFilterTab {
  all('Wszystkie'),
  timePenalties('Kary czasowe'),
  relegations('Relegacje'),
  fines('Grzywny CHF');

  final String label;
  const CommissaireFilterTab(this.label);
}

/// Responsywny panel UI prezentujący oficjalny komunikat Kolegium Sędziów UCI
/// z paletą `AppColors`, czcionką `Inter` oraz pełnymi stanami interakcji.
class CommissaireJuryCommuniquesPanel extends StatefulWidget {
  final CommissaireStageCommunique communique;
  final ValueChanged<CommissairePenaltyDecision>? onAcknowledgeOrPayFine;
  final ValueChanged<CommissairePenaltyDecision>? onAppealDecision;

  const CommissaireJuryCommuniquesPanel({
    super.key,
    required this.communique,
    this.onAcknowledgeOrPayFine,
    this.onAppealDecision,
  });

  @override
  State<CommissaireJuryCommuniquesPanel> createState() =>
      _CommissaireJuryCommuniquesPanelState();
}

class _CommissaireJuryCommuniquesPanelState
    extends State<CommissaireJuryCommuniquesPanel> {
  CommissaireFilterTab _selectedTab = CommissaireFilterTab.all;
  String? _selectedDecisionId;
  final Set<String> _settledDecisionIds = {};

  List<CommissairePenaltyDecision> get _filteredDecisions {
    final all = widget.communique.decisions;
    switch (_selectedTab) {
      case CommissaireFilterTab.all:
        return all;
      case CommissaireFilterTab.timePenalties:
        return all.where((d) => d.timePenaltySeconds > 0).toList();
      case CommissaireFilterTab.relegations:
        return all.where((d) => d.relegateToBackOfGroup || d.disqualified).toList();
      case CommissaireFilterTab.fines:
        return all.where((d) => d.totalFineChf > 0).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 600;
        final bool isWide = constraints.maxWidth >= 1024;
        final filtered = _filteredDecisions;
        final CommissairePenaltyDecision? activeDecision = filtered.isEmpty
            ? null
            : filtered.firstWhere(
                (d) => d.id == _selectedDecisionId,
                orElse: () => filtered.first,
              );

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact),
              const SizedBox(height: 14),
              _buildKpiRow(isCompact),
              const SizedBox(height: 14),
              _buildFilterBar(),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                _buildEmptyState()
              else if (isWide && activeDecision != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildDecisionList(filtered, isCompact),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildDetailInspector(activeDecision),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDecisionList(filtered, isCompact),
                    if (activeDecision != null) ...[
                      const SizedBox(height: 12),
                      _buildDetailInspector(activeDecision),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.45)),
          ),
          child: const Icon(Icons.gavel_rounded, color: AppColors.goldAccent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KOMUNIKAT KOLEGIUM SĘDZIÓW UCI — ETAP ${widget.communique.stageNumber}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 13 : 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.communique.stageName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiRow(bool isCompact) {
    final items = [
      _KpiMetric(
        label: 'Decyzje',
        value: '${widget.communique.decisions.length}',
        color: AppColors.accentBlue,
      ),
      _KpiMetric(
        label: 'Kary czasowe',
        value: '+${widget.communique.totalTimePenaltiesSeconds} s',
        color: AppColors.amberWarning,
      ),
      _KpiMetric(
        label: 'Relegacje / DSQ',
        value:
            '${widget.communique.relegationsCount} / ${widget.communique.disqualificationsCount}',
        color: AppColors.crimsonAlert,
      ),
      _KpiMetric(
        label: 'Grzywny CHF',
        value: '${widget.communique.totalFinesChf} CHF',
        color: AppColors.goldAccent,
      ),
    ];

    if (isCompact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map((m) => SizedBox(
                  width: 150,
                  child: _buildKpiCard(m),
                ))
            .toList(),
      );
    }

    return Row(
      children: items
          .map((m) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildKpiCard(m),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildKpiCard(_KpiMetric metric) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: metric.color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: CommissaireFilterTab.values.map((tab) {
          final bool isSelected = tab == _selectedTab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _InteractivePillButton(
              label: tab.label,
              isSelected: isSelected,
              onPressed: () {
                setState(() {
                  _selectedTab = tab;
                  _selectedDecisionId = null;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: const Column(
        children: [
          Icon(Icons.verified_outlined, color: AppColors.statusSuccess, size: 28),
          SizedBox(height: 8),
          Text(
            'Brak kar dyscyplinarnych w tej kategorii',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Etap przebiegł zgodnie z przepisami UCI.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionList(
    List<CommissairePenaltyDecision> decisions,
    bool isCompact,
  ) {
    return Column(
      children: decisions.map((d) {
        final bool isSelected = d.id == _selectedDecisionId ||
            (_selectedDecisionId == null && decisions.first.id == d.id);
        final bool isSettled = _settledDecisionIds.contains(d.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _InteractiveDecisionCard(
            decision: d,
            isSelected: isSelected,
            isSettled: isSettled,
            isCompact: isCompact,
            onTap: () => setState(() => _selectedDecisionId = d.id),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailInspector(CommissairePenaltyDecision d) {
    final bool isSettled = _settledDecisionIds.contains(d.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${d.bibNumber} ${d.riderName}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (d.yellowCardIssued)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.amberWarning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.amberWarning),
                  ),
                  child: const Text(
                    'ŻÓŁTA KARTKA',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amberWarning,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${d.teamName} • ${d.uciArticleCode}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            d.officialReasonPl,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (d.timePenaltySeconds > 0)
                _buildPenaltyBadge('+${d.timePenaltySeconds} s GC', AppColors.amberWarning),
              if (d.relegateToBackOfGroup)
                _buildPenaltyBadge('RELEGACJA', AppColors.crimsonAlert),
              if (d.disqualified)
                _buildPenaltyBadge('DSQ', AppColors.crimsonAlert),
              if (d.totalFineChf > 0)
                _buildPenaltyBadge(
                  '${d.totalFineChf} CHF (~${d.fineEurEquivalent} EUR)',
                  AppColors.goldAccent,
                ),
              if (d.pointsClassificationPenalty > 0)
                _buildPenaltyBadge(
                  '-${d.pointsClassificationPenalty} pkt zielona',
                  AppColors.statusSuccess,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InteractiveActionButton(
                  label: isSettled ? 'Opłacono (CHF)' : 'Zapłać grzywnę',
                  icon: isSettled ? Icons.check_circle_outline : Icons.payments_outlined,
                  enabled: !isSettled && d.totalFineChf > 0,
                  isPrimary: true,
                  onPressed: () {
                    setState(() => _settledDecisionIds.add(d.id));
                    widget.onAcknowledgeOrPayFine?.call(d);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InteractiveActionButton(
                  label: 'Odwołanie',
                  icon: Icons.balance_outlined,
                  enabled: !isSettled && widget.onAppealDecision != null,
                  isPrimary: false,
                  onPressed: () => widget.onAppealDecision?.call(d),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPenaltyBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _KpiMetric {
  final String label;
  final String value;
  final Color color;
  const _KpiMetric({required this.label, required this.value, required this.color});
}

class _InteractivePillButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _InteractivePillButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  State<_InteractivePillButton> createState() => _InteractivePillButtonState();
}

class _InteractivePillButtonState extends State<_InteractivePillButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.isSelected
        ? AppColors.primaryAccent
        : _isPressed
            ? AppColors.surfaceLight
            : _isHovered
                ? AppColors.surfaceLight.withValues(alpha: 0.85)
                : AppColors.background;
    final Color borderColor = widget.isSelected
        ? AppColors.goldAccent
        : _isFocused
            ? AppColors.accentBlue
            : const Color(0xFF2A2F3D);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1.0),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: widget.isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveDecisionCard extends StatefulWidget {
  final CommissairePenaltyDecision decision;
  final bool isSelected;
  final bool isSettled;
  final bool isCompact;
  final VoidCallback onTap;

  const _InteractiveDecisionCard({
    required this.decision,
    required this.isSelected,
    required this.isSettled,
    required this.isCompact,
    required this.onTap,
  });

  @override
  State<_InteractiveDecisionCard> createState() => _InteractiveDecisionCardState();
}

class _InteractiveDecisionCardState extends State<_InteractiveDecisionCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.decision;
    final Color borderColor = widget.isSelected
        ? AppColors.goldAccent
        : _isFocused
            ? AppColors.accentBlue
            : _isHovered
                ? AppColors.primaryAccent
                : const Color(0xFF2A2F3D);

    final Color bgColor = _isPressed
        ? AppColors.surfaceLight
        : widget.isSelected
            ? AppColors.surfaceLight.withValues(alpha: 0.9)
            : _isHovered
                ? AppColors.surfaceLight.withValues(alpha: 0.55)
                : AppColors.background;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(widget.isCompact ? 10 : 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: widget.isSelected ? 1.4 : 1.0),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2A2F3D)),
                  ),
                  child: Text(
                    '${d.bibNumber}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldAccent,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.riderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.infractionType.displayLabelPl} • ${d.kilometerMark.toStringAsFixed(1)} km',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (d.timePenaltySeconds > 0)
                      Text(
                        '+${d.timePenaltySeconds} s',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amberWarning,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      )
                    else if (d.relegateToBackOfGroup)
                      const Text(
                        'RELEGACJA',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.crimsonAlert,
                        ),
                      )
                    else if (d.disqualified)
                      const Text(
                        'DSQ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.crimsonAlert,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      widget.isSettled ? 'Opłacono' : '${d.totalFineChf} CHF',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.isSettled ? AppColors.statusSuccess : AppColors.goldAccent,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() => _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.enabled;
    final Color baseBg = widget.isPrimary ? AppColors.primaryAccent : AppColors.background;
    final Color bgColor = !enabled
        ? AppColors.background.withValues(alpha: 0.4)
        : _isPressed
            ? baseBg.withValues(alpha: 0.75)
            : _isHovered
                ? baseBg.withValues(alpha: 0.92)
                : baseBg;

    final Color borderColor = !enabled
        ? const Color(0xFF2A2F3D).withValues(alpha: 0.5)
        : _isFocused
            ? AppColors.accentBlue
            : widget.isPrimary
                ? AppColors.goldAccent.withValues(alpha: 0.7)
                : const Color(0xFF2A2F3D);

    final Color fgColor = enabled ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.5);

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (enabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 16, color: fgColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fgColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
