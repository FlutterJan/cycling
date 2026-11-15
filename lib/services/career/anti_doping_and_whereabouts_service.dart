// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import '../../models/career/staff_member.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_health.dart';
import '../../models/team/cycling_team.dart';
import '../../models/team/sponsor_contract.dart';

/// Typ i kontekst przeprowadzanego testu antydopingowego (WADA / CADF / ITA).
enum AntiDopingTestType {
  /// Kontrola po etapie wyścigu (In-Competition - IC)
  /// Obowiązkowo: zwycięzca etapu, lider klasyfikacji generalnej oraz 2-3 losowych kolarzy.
  inCompetition,

  /// Niezapowiedziana kontrola poza zawodami (Out-of-Competition - OOC)
  /// Wizyta kontrolerów o 06:00 rano w zadeklarowanym 60-minutowym oknie Whereabouts.
  outOfCompetition,

  /// Kontrola celowana (Targeted Testing)
  /// Zarządzana przez UCI / ITA na podstawie podejrzanych wahań w Paszporcie Biologicznym (ABP).
  targetedAudit;

  String toJson() => name;

  static AntiDopingTestType fromJson(String value) {
    return AntiDopingTestType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AntiDopingTestType.inCompetition,
    );
  }

  String get displayName {
    switch (this) {
      case AntiDopingTestType.inCompetition:
        return 'Kontrola po etapie wyścigu (In-Competition)';
      case AntiDopingTestType.outOfCompetition:
        return 'Niezapowiedziany test poza zawodami (Out-of-Competition)';
      case AntiDopingTestType.targetedAudit:
        return 'Celowany audyt antydopingowy (Targeted ABP Test)';
    }
  }
}

/// Wynik badania laboratoryjnego próbki A pobranej od zawodnika.
enum DopingTestOutcome {
  /// Wynik negatywny: brak zakazanych substancji, parametry krwi w normie
  negativeClean,

  /// Pozytywny wynik analityczny (AAF - Adverse Analytical Finding):
  /// Wykryto zabronioną substancję bez ważnego wyłączenia TUE lub z przekroczeniem dozwolonej dawki.
  adverseAnalyticalFinding,

  /// Wynik nietypowy (ATF - Atypical Finding):
  /// Niewielkie odchylenie wymagające pogłębionej analizy (np. izotopowej spektrometrii mas IRMS).
  atypicalFinding;

  String toJson() => name;

  static DopingTestOutcome fromJson(String value) {
    return DopingTestOutcome.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DopingTestOutcome.negativeClean,
    );
  }

  String get displayName {
    switch (this) {
      case DopingTestOutcome.negativeClean:
        return 'Negatywny (Czysty / Brak substancji)';
      case DopingTestOutcome.adverseAnalyticalFinding:
        return 'Pozytywny (Adverse Analytical Finding - AAF)';
      case DopingTestOutcome.atypicalFinding:
        return 'Nietypowy (Atypical Finding - ATF)';
    }
  }
}

/// Status Paszportu Biologicznego Kolarza (Athlete Biological Passport - ABP).
enum BiologicalPassportStatus {
  /// Wskaźniki w normie adaptacyjnego modelu Bayesa (gaussowska norma 99%)
  normalClean,

  /// Drobne fluktuacje (np. odwodnienie, adaptacja wysokogórska), profil monitorowany
  atypicalVariance,

  /// Podejrzany profil krwi/steroidów (przekroczenie 99.9% percentyla, zwołanie panelu ekspertów)
  suspiciousProfile,

  /// Wszczęte oficjalne postępowanie dyscyplinarne przed Niezależnym Panelem Ekspertów UCI
  disciplinaryProceedings,

  /// Zawieszenie licencji zawodnika z powodu naruszenia paszportu biologicznego
  suspended;

  String toJson() => name;

  static BiologicalPassportStatus fromJson(String value) {
    return BiologicalPassportStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BiologicalPassportStatus.normalClean,
    );
  }

  String get displayName {
    switch (this) {
      case BiologicalPassportStatus.normalClean:
        return 'Prawidłowy (Czysty)';
      case BiologicalPassportStatus.atypicalVariance:
        return 'Nietypowe wahania (Profil monitorowany)';
      case BiologicalPassportStatus.suspiciousProfile:
        return 'Podejrzany profil (Alarm Panelu Ekspertów UCI)';
      case BiologicalPassportStatus.disciplinaryProceedings:
        return 'Postępowanie dyscyplinarne UCI';
      case BiologicalPassportStatus.suspended:
        return 'Zawieszony (Dyskwalifikacja ABP)';
    }
  }
}

/// Rodzaj naruszenia obowiązku meldunkowego w systemie ADAMS (Whereabouts Failure).
enum WhereaboutsFailureType {
  /// Niestawiennictwo / nieobecność w zadeklarowanym 60-minutowym oknie (Missed Test)
  missedTest,

  /// Niezłożenie lub spóźnione złożenie kwartalnego raportu lokalizacyjnego (Filing Failure)
  filingFailure;

  String toJson() => name;

  static WhereaboutsFailureType fromJson(String value) {
    return WhereaboutsFailureType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WhereaboutsFailureType.missedTest,
    );
  }

  String get displayName {
    switch (this) {
      case WhereaboutsFailureType.missedTest:
        return 'Niestawiennictwo na kontroli (Missed Test - 60 min)';
      case WhereaboutsFailureType.filingFailure:
        return 'Błąd zgłoszenia lokalizacji w ADAMS (Filing Failure)';
    }
  }
}

/// Pojedynczy incydent meldunkowy kolarza (Strike w systemie ADAMS).
/// Zgodnie z przepisami WADA/UCI: 3 incydenty w ciągu 12 miesięcy = dyskwalifikacja.
class WhereaboutsStrike {
  final String id;
  final String riderId;
  final WhereaboutsFailureType type;
  final DateTime incidentDate;
  final String explanation;

  const WhereaboutsStrike({
    required this.id,
    required this.riderId,
    required this.type,
    required this.incidentDate,
    required this.explanation,
  });

  /// Czy incydent jest wciąż aktywny (ważność 365 dni od daty popełnienia)
  bool isActiveAt(DateTime date) {
    final diffDays = date.difference(incidentDate).inDays;
    return diffDays >= 0 && diffDays <= 365;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'riderId': riderId,
        'type': type.toJson(),
        'incidentDate': incidentDate.toIso8601String(),
        'explanation': explanation,
      };

  factory WhereaboutsStrike.fromJson(Map<String, dynamic> json) {
    return WhereaboutsStrike(
      id: json['id'] as String,
      riderId: json['riderId'] as String,
      type: WhereaboutsFailureType.fromJson(json['type'] as String),
      incidentDate: DateTime.parse(json['incidentDate'] as String),
      explanation: json['explanation'] as String,
    );
  }
}

/// Pojedynczy wpis z próbki krwi i moczu w Paszporcie Biologicznym Kolarza (ABP).
class BiologicalPassportSample {
  final String id;
  final String riderId;
  final DateTime sampleDate;
  final AntiDopingTestType testType;

  /// Stężenie hemoglobiny we krwi [g/dL] (norma fizjologiczna kolarzy: 13.8 - 17.2 g/dL)
  final double hemoglobinGDL;

  /// Hematokryt [%] (norma: 41.0 - 49.5%, limit bezpieczeństwa UCI wynosi 50.0%)
  final double hematocritPercent;

  /// Odsetek retikulocytów RET% [%] (młode krwinki czerwone, norma: 0.4% - 1.8%)
  final double reticulocytesPercent;

  /// Złożony wskaźnik stymulacji erytropoezy (OFF-score / wskaźnik Gore'a):
  /// OFF-score = (Hb [g/dL] * 10) - 60 * sqrt(RET%)
  /// Norma dla kolarza: 85 - 110. Wynik > 125 wskazuje na transfuzję lub spadek retikulocytów po EPO.
  final double offScore;

  /// Stosunek testosteronu do epitestosteronu (T/E ratio, norma WADA: < 4.0)
  final double testosteroneEpitestosteroneRatio;

  /// Czy próbka wykazała odwodnienie (zwiększona gęstość i hematokryt przy braku zmian masy krwinek)
  final bool isHydrationAbnormal;

  /// Czy model Bayesa zakwalifikował próbkę jako anomalię statystyczną (>99.9% percentyl)
  final bool isAtypicalAnomaly;

  const BiologicalPassportSample({
    required this.id,
    required this.riderId,
    required this.sampleDate,
    required this.testType,
    required this.hemoglobinGDL,
    required this.hematocritPercent,
    required this.reticulocytesPercent,
    required this.offScore,
    required this.testosteroneEpitestosteroneRatio,
    this.isHydrationAbnormal = false,
    this.isAtypicalAnomaly = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'riderId': riderId,
        'sampleDate': sampleDate.toIso8601String(),
        'testType': testType.toJson(),
        'hemoglobinGDL': hemoglobinGDL,
        'hematocritPercent': hematocritPercent,
        'reticulocytesPercent': reticulocytesPercent,
        'offScore': offScore,
        'testosteroneEpitestosteroneRatio': testosteroneEpitestosteroneRatio,
        'isHydrationAbnormal': isHydrationAbnormal,
        'isAtypicalAnomaly': isAtypicalAnomaly,
      };

  factory BiologicalPassportSample.fromJson(Map<String, dynamic> json) {
    return BiologicalPassportSample(
      id: json['id'] as String,
      riderId: json['riderId'] as String,
      sampleDate: DateTime.parse(json['sampleDate'] as String),
      testType: AntiDopingTestType.fromJson(json['testType'] as String),
      hemoglobinGDL: (json['hemoglobinGDL'] as num).toDouble(),
      hematocritPercent: (json['hematocritPercent'] as num).toDouble(),
      reticulocytesPercent: (json['reticulocytesPercent'] as num).toDouble(),
      offScore: (json['offScore'] as num).toDouble(),
      testosteroneEpitestosteroneRatio:
          (json['testosteroneEpitestosteroneRatio'] as num).toDouble(),
      isHydrationAbnormal: json['isHydrationAbnormal'] as bool? ?? false,
      isAtypicalAnomaly: json['isAtypicalAnomaly'] as bool? ?? false,
    );
  }
}

/// Pełny Paszport Biologiczny kolarza (Athlete Biological Passport - ABP).
class AthleteBiologicalPassport {
  final String riderId;
  final List<BiologicalPassportSample> samples;
  final BiologicalPassportStatus status;
  final int suspicionScore; // 0 - 100
  final List<String> expertNotes;

  const AthleteBiologicalPassport({
    required this.riderId,
    this.samples = const [],
    this.status = BiologicalPassportStatus.normalClean,
    this.suspicionScore = 0,
    this.expertNotes = const [],
  });

  AthleteBiologicalPassport copyWith({
    String? riderId,
    List<BiologicalPassportSample>? samples,
    BiologicalPassportStatus? status,
    int? suspicionScore,
    List<String>? expertNotes,
  }) {
    return AthleteBiologicalPassport(
      riderId: riderId ?? this.riderId,
      samples: samples ?? this.samples,
      status: status ?? this.status,
      suspicionScore: suspicionScore ?? this.suspicionScore,
      expertNotes: expertNotes ?? this.expertNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'samples': samples.map((s) => s.toJson()).toList(),
        'status': status.toJson(),
        'suspicionScore': suspicionScore,
        'expertNotes': expertNotes,
      };

  factory AthleteBiologicalPassport.fromJson(Map<String, dynamic> json) {
    return AthleteBiologicalPassport(
      riderId: json['riderId'] as String,
      samples: (json['samples'] as List<dynamic>?)
              ?.map((e) =>
                  BiologicalPassportSample.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: json['status'] != null
          ? BiologicalPassportStatus.fromJson(json['status'] as String)
          : BiologicalPassportStatus.normalClean,
      suspicionScore: (json['suspicionScore'] as num?)?.toInt() ?? 0,
      expertNotes: (json['expertNotes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

/// Substancje i preparaty lecznicze Szarej Strefy Medycznej (Medical Grey Zone).
enum TherapeuticSubstance {
  /// Triamcynolon (Kenacort / iniekcja dostawowa lub domięśniowa sterydu)
  /// Silny kortykosteroid przeciwzapalny na ostry ból kolan i ścięgien; tłumi ból, redukuje stan zapalny,
  /// daje uczucie lekkości w nogach, ale jest zakazany w zawodach przez WADA (S9).
  triamcinolone,

  /// Doustny kortykosteroid (Prednizolon / Kortyzon w tabletkach)
  /// Przyspiesza redukcję zapalenia, poprawia wydolność oddechową, maskuje ból przeciążeniowy.
  oralCortisone,

  /// Tramadol (silny syntetyczny opioid przeciwbólowy)
  /// Zakazany przez UCI od 2019 w trakcie zawodów ze względu na senność i ryzyko kraks;
  /// od 2024 całkowicie zakazany przez WADA w zawodach.
  tramadol,

  /// Salbutamol w dawce ponadnormatywnej (> 1600 mcg / 24h)
  /// Wziewny beta-2 mimetyk rozszerzający oskrzela; przekroczenie stężenia 1000 ng/mL w moczu.
  salbutamolHighDose;

  String toJson() => name;

  static TherapeuticSubstance fromJson(String value) {
    return TherapeuticSubstance.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TherapeuticSubstance.triamcinolone,
    );
  }

  String get displayName {
    switch (this) {
      case TherapeuticSubstance.triamcinolone:
        return 'Triamcynolon (Kenacort - Iniekcja Kortykosteroidowa)';
      case TherapeuticSubstance.oralCortisone:
        return 'Prednizolon / Kortyzon doustny';
      case TherapeuticSubstance.tramadol:
        return 'Tramadol (Silny opioid przeciwbólowy)';
      case TherapeuticSubstance.salbutamolHighDose:
        return 'Salbutamol ponadnormatywny (>1600 mcg)';
    }
  }

  String get wadaCategory {
    switch (this) {
      case TherapeuticSubstance.triamcinolone:
      case TherapeuticSubstance.oralCortisone:
        return 'S9. Glikokortykosteroidy (Zakazane w zawodach)';
      case TherapeuticSubstance.tramadol:
        return 'M2 / Zakazane związki opioidowe UCI/WADA';
      case TherapeuticSubstance.salbutamolHighDose:
        return 'S3. Beta-2 Agoniści (Powyżej dawki terapeutycznej)';
    }
  }

  /// Ile procent wyjściowej wydolności odzyskuje kolarz z kontuzją po podaniu leku
  double get performanceRetentionPercent {
    switch (this) {
      case TherapeuticSubstance.triamcinolone:
        return 0.92; // 92% wydolności mimo zapalenia ścięgien
      case TherapeuticSubstance.oralCortisone:
        return 0.86;
      case TherapeuticSubstance.tramadol:
        return 0.88; // Całkowite zablokowanie receptorów bólowych
      case TherapeuticSubstance.salbutamolHighDose:
        return 0.90;
    }
  }

  /// Okno detekcji w organizmie zawodnika [dni]
  int get detectionWindowDays {
    switch (this) {
      case TherapeuticSubstance.triamcinolone:
        return 10;
      case TherapeuticSubstance.oralCortisone:
        return 6;
      case TherapeuticSubstance.tramadol:
        return 4;
      case TherapeuticSubstance.salbutamolHighDose:
        return 3;
    }
  }

  /// Bazowa trudność uzyskania oficjalnego TUE w UCI (0-100, im wyższa tym trudniej)
  int get tueApprovalBaseDifficulty {
    switch (this) {
      case TherapeuticSubstance.triamcinolone:
        return 50; // Wymaga bogatej dokumentacji USG / MRI
      case TherapeuticSubstance.oralCortisone:
        return 40;
      case TherapeuticSubstance.tramadol:
        return 80; // Niemal niemożliwe w trakcie wyścigu (zakaz UCI)
      case TherapeuticSubstance.salbutamolHighDose:
        return 35; // Wymaga spirometrii z próbą prowokacyjną
    }
  }

  String get clinicalDescription {
    switch (this) {
      case TherapeuticSubstance.triamcinolone:
        return 'Blokuje stan zapalny ścięgna rzepki / pasma biodrowo-piszczelowego. '
            'Umożliwia jazdę w górach z pełną mocą, ale niesie ogromne ryzyko skandalu '
            'jeśli wniosek TUE zostanie zakwestionowany przez komisję UCI.';
      case TherapeuticSubstance.oralCortisone:
        return 'Tłumi ogólnoustrojowy stan zapalny i ból mięśniowy po kraksie. '
            'Może maskować przeciążenia i wycieńczenie organizmu.';
      case TherapeuticSubstance.tramadol:
        return 'Eliminuje odczuwanie potężnego bólu po złamaniach i głębokich szlifach. '
            'Zwiększa jednak ryzyko utraty koncentracji na zjazdach o 40%.';
      case TherapeuticSubstance.salbutamolHighDose:
        return 'Maksymalizuje przepływ powietrza w pęcherzykach płucnych podczas ataku astmy powysiłkowej '
            'lub w upale i smogu.';
    }
  }
}

/// Status wniosku o Wyłączenie dla Celów Terapeutycznych (TUE).
enum TueApplicationStatus {
  pending,
  approved,
  rejected,
  retroactiveRejected;

  String toJson() => name;

  static TueApplicationStatus fromJson(String value) {
    return TueApplicationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TueApplicationStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case TueApplicationStatus.pending:
        return 'Rozpatrywany przez Komisję Medyczną UCI';
      case TueApplicationStatus.approved:
        return 'Zaakceptowany (Legalne wyłączenie TUE ważne)';
      case TueApplicationStatus.rejected:
        return 'Odrzucony (Brak wskazań klinicznych)';
      case TueApplicationStatus.retroactiveRejected:
        return 'Odrzucony wniosek wsteczny';
    }
  }
}

/// Wniosek o TUE (Therapeutic Use Exemption) złożony do UCI.
class TueApplication {
  final String id;
  final String riderId;
  final String riderName;
  final InjuryType injuryType;
  final TherapeuticSubstance substance;
  final DateTime applicationDate;
  final TueApplicationStatus status;
  final DateTime? decisionDate;
  final String doctorName;
  final String? rejectionReason;
  final DateTime validUntil;

  const TueApplication({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.injuryType,
    required this.substance,
    required this.applicationDate,
    required this.status,
    this.decisionDate,
    required this.doctorName,
    this.rejectionReason,
    required this.validUntil,
  });

  bool isValidAt(DateTime date) {
    return status == TueApplicationStatus.approved &&
        date.isBefore(validUntil) &&
        (decisionDate == null || !date.isBefore(decisionDate!));
  }

  TueApplication copyWith({
    String? id,
    String? riderId,
    String? riderName,
    InjuryType? injuryType,
    TherapeuticSubstance? substance,
    DateTime? applicationDate,
    TueApplicationStatus? status,
    DateTime? decisionDate,
    String? doctorName,
    String? rejectionReason,
    DateTime? validUntil,
  }) {
    return TueApplication(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      injuryType: injuryType ?? this.injuryType,
      substance: substance ?? this.substance,
      applicationDate: applicationDate ?? this.applicationDate,
      status: status ?? this.status,
      decisionDate: decisionDate ?? this.decisionDate,
      doctorName: doctorName ?? this.doctorName,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      validUntil: validUntil ?? this.validUntil,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'riderId': riderId,
        'riderName': riderName,
        'injuryType': injuryType.toJson(),
        'substance': substance.toJson(),
        'applicationDate': applicationDate.toIso8601String(),
        'status': status.toJson(),
        'decisionDate': decisionDate?.toIso8601String(),
        'doctorName': doctorName,
        'rejectionReason': rejectionReason,
        'validUntil': validUntil.toIso8601String(),
      };

  factory TueApplication.fromJson(Map<String, dynamic> json) {
    return TueApplication(
      id: json['id'] as String,
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      injuryType: InjuryType.fromJson(json['injuryType'] as String),
      substance: TherapeuticSubstance.fromJson(json['substance'] as String),
      applicationDate: DateTime.parse(json['applicationDate'] as String),
      status: TueApplicationStatus.fromJson(json['status'] as String),
      decisionDate: json['decisionDate'] != null
          ? DateTime.parse(json['decisionDate'] as String)
          : null,
      doctorName: json['doctorName'] as String,
      rejectionReason: json['rejectionReason'] as String?,
      validUntil: DateTime.parse(json['validUntil'] as String),
    );
  }
}

/// Aktywna kuracja lecznicza / substancja podana kolarzowi.
class ActiveMedicalTreatment {
  final String id;
  final String riderId;
  final TherapeuticSubstance substance;
  final DateTime administeredDate;
  final bool hasApprovedTue;
  final String? tueApplicationId;
  final DateTime detectionWindowEndDate;

  const ActiveMedicalTreatment({
    required this.id,
    required this.riderId,
    required this.substance,
    required this.administeredDate,
    required this.hasApprovedTue,
    this.tueApplicationId,
    required this.detectionWindowEndDate,
  });

  /// Czy na dany dzień substancja jest aktywna w krwioobiegu / moczu
  bool isDetectableAt(DateTime date) {
    return date.isAfter(administeredDate) &&
        date.isBefore(detectionWindowEndDate);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'riderId': riderId,
        'substance': substance.toJson(),
        'administeredDate': administeredDate.toIso8601String(),
        'hasApprovedTue': hasApprovedTue,
        'tueApplicationId': tueApplicationId,
        'detectionWindowEndDate': detectionWindowEndDate.toIso8601String(),
      };

  factory ActiveMedicalTreatment.fromJson(Map<String, dynamic> json) {
    return ActiveMedicalTreatment(
      id: json['id'] as String,
      riderId: json['riderId'] as String,
      substance: TherapeuticSubstance.fromJson(json['substance'] as String),
      administeredDate: DateTime.parse(json['administeredDate'] as String),
      hasApprovedTue: json['hasApprovedTue'] as bool,
      tueApplicationId: json['tueApplicationId'] as String?,
      detectionWindowEndDate:
          DateTime.parse(json['detectionWindowEndDate'] as String),
    );
  }
}

/// Wynik pojedynczego testu antydopingowego.
class AntiDopingTestResult {
  final String testId;
  final String riderId;
  final String riderName;
  final AntiDopingTestType testType;
  final DateTime testDate;
  final DopingTestOutcome outcome;
  final TherapeuticSubstance? detectedSubstance;
  final bool isCoveredByValidTue;
  final BiologicalPassportSample passportSample;
  final String labReportSummary;

  const AntiDopingTestResult({
    required this.testId,
    required this.riderId,
    required this.riderName,
    required this.testType,
    required this.testDate,
    required this.outcome,
    this.detectedSubstance,
    this.isCoveredByValidTue = false,
    required this.passportSample,
    required this.labReportSummary,
  });

  Map<String, dynamic> toJson() => {
        'testId': testId,
        'riderId': riderId,
        'riderName': riderName,
        'testType': testType.toJson(),
        'testDate': testDate.toIso8601String(),
        'outcome': outcome.toJson(),
        'detectedSubstance': detectedSubstance?.toJson(),
        'isCoveredByValidTue': isCoveredByValidTue,
        'passportSample': passportSample.toJson(),
        'labReportSummary': labReportSummary,
      };

  factory AntiDopingTestResult.fromJson(Map<String, dynamic> json) {
    return AntiDopingTestResult(
      testId: json['testId'] as String,
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      testType: AntiDopingTestType.fromJson(json['testType'] as String),
      testDate: DateTime.parse(json['testDate'] as String),
      outcome: DopingTestOutcome.fromJson(json['outcome'] as String),
      detectedSubstance: json['detectedSubstance'] != null
          ? TherapeuticSubstance.fromJson(json['detectedSubstance'] as String)
          : null,
      isCoveredByValidTue: json['isCoveredByValidTue'] as bool? ?? false,
      passportSample: BiologicalPassportSample.fromJson(
          json['passportSample'] as Map<String, dynamic>),
      labReportSummary: json['labReportSummary'] as String,
    );
  }
}

/// Oficjalna sankcja antydopingowa nałożona na zawodnika przez UCI / WADA.
class AntiDopingSanction {
  final String id;
  final String riderId;
  final String riderName;
  final String reason;
  final DateTime startDate;
  final DateTime endDate;
  final int suspensionMonths;
  final int uciPointsStripped;

  const AntiDopingSanction({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.suspensionMonths,
    required this.uciPointsStripped,
  });

  bool isActiveAt(DateTime date) {
    return date.isAfter(startDate) && date.isBefore(endDate);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'riderId': riderId,
        'riderName': riderName,
        'reason': reason,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'suspensionMonths': suspensionMonths,
        'uciPointsStripped': uciPointsStripped,
      };

  factory AntiDopingSanction.fromJson(Map<String, dynamic> json) {
    return AntiDopingSanction(
      id: json['id'] as String,
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      reason: json['reason'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      suspensionMonths: (json['suspensionMonths'] as num).toInt(),
      uciPointsStripped: (json['uciPointsStripped'] as num).toInt(),
    );
  }
}

/// Pełny raport ze skandalu antydopingowego w razie AAF lub naruszenia ABP.
class AntiDopingScandalReport {
  final Rider rider;
  final TherapeuticSubstance? substance;
  final AntiDopingSanction sanction;
  final int teamFineEur;
  final int managerReputationPenalty;
  final double sponsorSatisfactionPenalty;
  final bool titleSponsorTerminated;
  final SponsorContract? terminatedSponsor;
  final String mediaReactionHeadline;
  final String pressReleaseText;

  const AntiDopingScandalReport({
    required this.rider,
    this.substance,
    required this.sanction,
    required this.teamFineEur,
    required this.managerReputationPenalty,
    required this.sponsorSatisfactionPenalty,
    required this.titleSponsorTerminated,
    this.terminatedSponsor,
    required this.mediaReactionHeadline,
    required this.pressReleaseText,
  });
}

/// Główny serwis Paszportu Biologicznego UCI, Kontroli ADAMS i Szarej Strefy Medycznej
/// (Anti-Doping & Whereabouts Service).
class AntiDopingAndWhereaboutsService {
  AntiDopingAndWhereaboutsService._();

  // ---------------------------------------------------------------------------
  // 1. PASZPORT BIOLOGICZNY UCI (Athlete Biological Passport - ABP)
  // ---------------------------------------------------------------------------

  /// Wylicza wskaźnik stymulacji erytropoezy (OFF-score wg wzoru Gore'a i WADA):
  /// OFF-score = (hemoglobinGDL * 10) - 60 * sqrt(reticulocytesPercent)
  static double calculateOffScore({
    required double hemoglobinGDL,
    required double reticulocytesPercent,
  }) {
    final ret = math.max(0.01, reticulocytesPercent);
    final off = (hemoglobinGDL * 10.0) - (60.0 * math.sqrt(ret));
    return (off * 10.0).roundToDouble() / 10.0;
  }

  /// Generuje fizjologiczną próbkę krwi do Paszportu Biologicznego.
  static BiologicalPassportSample generatePassportSample({
    required Rider rider,
    required AntiDopingTestType testType,
    required DateTime sampleDate,
    bool isDehydrated = false,
    double? customHemoglobin,
    double? customReticulocytes,
    double? customTeRatio,
  }) {
    // Bazowe parametry krwi kolarza w oparciu o profil fizjologiczny (VO2max)
    final baseHb = customHemoglobin ??
        (14.8 + (((rider.physiology.vo2Max - 60.0) / 30.0) * 1.5) + (isDehydrated ? 0.9 : 0.0));
    final clampedHb = ((baseHb * 10.0).roundToDouble()) / 10.0;

    // Hematokryt (ok. 3-krotność hemoglobiny z drobną wariancją)
    final hct = isDehydrated
        ? (clampedHb * 3.02).clamp(42.0, 50.8)
        : (clampedHb * 2.92).clamp(40.5, 49.5);
    final clampedHct = ((hct * 10.0).roundToDouble()) / 10.0;

    // Retikulocyty RET% (młode erytrocyty)
    final ret = customReticulocytes ?? (isDehydrated ? 0.65 : 1.05);
    final clampedRet = ((ret * 100.0).roundToDouble()) / 100.0;

    // OFF-score
    final off = calculateOffScore(
      hemoglobinGDL: clampedHb,
      reticulocytesPercent: clampedRet,
    );

    // Stosunek T/E (testosteron / epitestosteron)
    final te = customTeRatio ?? 1.25;

    // Anomalia adaptacyjnego modelu Bayesa:
    // Występuje gdy OFF-score > 122 lub < 72, lub hematokryt przekracza limit bezpieczeństwa UCI 50.0%
    final isAtypical = off > 122.0 || off < 72.0 || clampedHct >= 50.0 || te >= 4.0;

    return BiologicalPassportSample(
      id: 'abp_${rider.id}_${sampleDate.millisecondsSinceEpoch}',
      riderId: rider.id,
      sampleDate: sampleDate,
      testType: testType,
      hemoglobinGDL: clampedHb,
      hematocritPercent: clampedHct,
      reticulocytesPercent: clampedRet,
      offScore: off,
      testosteroneEpitestosteroneRatio: te,
      isHydrationAbnormal: isDehydrated,
      isAtypicalAnomaly: isAtypical,
    );
  }

  /// Analizuje historię próbek w paszporcie kolarza za pomocą modelu adaptacyjnego Bayesa.
  static AthleteBiologicalPassport evaluateBiologicalPassport(
    AthleteBiologicalPassport currentPassport,
  ) {
    if (currentPassport.samples.isEmpty) return currentPassport;

    int anomalyCount = 0;
    int highOffScoreCount = 0;
    int highTeCount = 0;
    final notes = <String>[...currentPassport.expertNotes];

    for (final s in currentPassport.samples) {
      if (s.isAtypicalAnomaly) anomalyCount++;
      if (s.offScore > 120.0) highOffScoreCount++;
      if (s.testosteroneEpitestosteroneRatio >= 4.0) highTeCount++;
    }

    final BiologicalPassportStatus newStatus;
    final int suspicionScore;

    if (highOffScoreCount >= 2 || highTeCount >= 2 || anomalyCount >= 3) {
      newStatus = BiologicalPassportStatus.disciplinaryProceedings;
      suspicionScore = 95;
      notes.add(
        'Panel Niezależnych Ekspertów UCI stwierdził ekstremalne odchylenie profilu hematologicznego. '
        'Wszczęto oficjalne postępowanie antydopingowe.',
      );
    } else if (anomalyCount >= 2 || highOffScoreCount == 1) {
      newStatus = BiologicalPassportStatus.suspiciousProfile;
      suspicionScore = 75;
      notes.add(
        'Podejrzany skok OFF-score / supresja retikulocytów. Kolarz wpisany na listę celowanych kontroli WADA.',
      );
    } else if (anomalyCount == 1) {
      newStatus = BiologicalPassportStatus.atypicalVariance;
      suspicionScore = 35;
      notes.add('Pojedyncza anomalia w próbce – monitorowanie zmienności stężenia hemoglobiny.');
    } else {
      newStatus = BiologicalPassportStatus.normalClean;
      suspicionScore = math.max(0, currentPassport.suspicionScore - 10);
    }

    return currentPassport.copyWith(
      status: newStatus,
      suspicionScore: suspicionScore,
      expertNotes: notes,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. SYSTEM WHEREABOUTS (ADAMS) & RYZYKO MISSED TESTS
  // ---------------------------------------------------------------------------

  /// Weryfikuje codzienną dostępność kolarza w 60-minutowym oknie kontroli ADAMS.
  /// Wysoki poziom lekarza i dyrektorów sportowych drastycznie redukuje ryzyko błędów meldunkowych.
  static WhereaboutsStrike? evaluateDailyWhereaboutsCompliance({
    required Rider rider,
    required TeamStaff staff,
    required DateTime currentDate,
    math.Random? rng,
  }) {
    final random = rng ?? math.Random();

    // Szansa na wizytę kontrolerów WADA poza zawodami (np. 1.2% dziennie na kolarza)
    final isAuditedToday = random.nextDouble() < 0.012;
    if (!isAuditedToday) return null;

    // Bazowe ryzyko nieobecności (np. 3.5%)
    double failureRisk = 0.035;

    // Sztab medyczny i dyrektorzy pilnują kolarzy
    final doctorBonus = (staff.doctorsLevel / 100.0) * 0.025;
    final dsBonus = (staff.sportsDirectorsLevel / 100.0) * 0.010;
    failureRisk = (failureRisk - doctorBonus - dsBonus).clamp(0.002, 0.05);

    final failed = random.nextDouble() < failureRisk;
    if (!failed) return null;

    // Typ incydentu
    final isMissedTest = random.nextBool();
    final type = isMissedTest
        ? WhereaboutsFailureType.missedTest
        : WhereaboutsFailureType.filingFailure;

    final explanation = isMissedTest
        ? 'Kontroler WADA przybył o 06:15 pod zadeklarowany adres, lecz kolarz nie otworzył drzwi (Missed Test).'
        : 'Nieprawidłowa lub spóźniona aktualizacja kwartalnego harmonogramu pobytu w bazie ADAMS (Filing Failure).';

    return WhereaboutsStrike(
      id: 'strike_${rider.id}_${currentDate.millisecondsSinceEpoch}',
      riderId: rider.id,
      type: type,
      incidentDate: currentDate,
      explanation: explanation,
    );
  }

  /// Zwraca aktywne ostrzeżenia Whereabouts (ostatnie 365 dni).
  static List<WhereaboutsStrike> getActiveWhereaboutsStrikes({
    required List<WhereaboutsStrike> allStrikes,
    required String riderId,
    required DateTime currentDate,
  }) {
    return allStrikes
        .where((s) => s.riderId == riderId && s.isActiveAt(currentDate))
        .toList();
  }

  /// Czy zawodnik naruszył regułę 3 Whereabouts Failures w 12 miesięcy
  /// (co oznacza automatyczną dyskwalifikację na 12-24 miesiące!).
  static bool hasWhereaboutsRuleViolation({
    required List<WhereaboutsStrike> allStrikes,
    required String riderId,
    required DateTime currentDate,
  }) {
    final active = getActiveWhereaboutsStrikes(
      allStrikes: allStrikes,
      riderId: riderId,
      currentDate: currentDate,
    );
    return active.length >= 3;
  }

  // ---------------------------------------------------------------------------
  // 3. SZARA STREFA MEDYCZNA, TUE I LECZENIE KONTUZJOWANYCH LIDERÓW
  // ---------------------------------------------------------------------------

  /// Składa oficjalny wniosek o TUE (Therapeutic Use Exemption) do Komisji Medycznej UCI.
  /// Szansa na akceptację zależy od poziomu lekarza klubowego oraz rodzaju urazu.
  static TueApplication submitTueApplication({
    required Rider rider,
    required Injury injury,
    required TherapeuticSubstance substance,
    TeamDoctor? doctor,
    required DateTime applicationDate,
    math.Random? rng,
  }) {
    final random = rng ?? math.Random();

    // Bazowa szansa akceptacji TUE (np. 100 - baseDifficulty)
    double approvalChance = (100.0 - substance.tueApprovalBaseDifficulty) / 100.0;

    // Wpływ lekarza klubowego: elitarny lekarz przygotowuje bezbłędną dokumentację medyczną
    if (doctor != null) {
      final docBonus = ((doctor.experienceLevel + doctor.bloodDiagnosticsSkill) / 200.0) * 0.35;
      approvalChance += docBonus;
    } else {
      approvalChance -= 0.15;
    }

    // Wpływ kontuzji: tendinitis i road rash mają silne uzasadnienie dla leków p/zapalnych
    if (injury.type == InjuryType.kneeTendinitis || injury.type == InjuryType.roadRash) {
      approvalChance += 0.10;
    } else if (injury.type == InjuryType.clavicleFracture &&
        substance == TherapeuticSubstance.triamcinolone) {
      // Sterydy spowalniają zrost kości – komisja patrzy bardzo podejrzliwie
      approvalChance -= 0.35;
    }

    approvalChance = approvalChance.clamp(0.08, 0.95);

    final isApproved = random.nextDouble() < approvalChance;

    final TueApplicationStatus status;
    final String? reason;
    if (isApproved) {
      status = TueApplicationStatus.approved;
      reason = null;
    } else {
      status = TueApplicationStatus.rejected;
      reason = 'Komisja Medyczna UCI uznała dokumentację za niewystarczającą do dopuszczenia '
          'substancji z grupy ${substance.wadaCategory}. Zalecany odpoczynek fizjologiczny.';
    }

    final validUntil = applicationDate.add(Duration(days: substance.detectionWindowDays + 7));

    return TueApplication(
      id: 'tue_${rider.id}_${substance.name}_${applicationDate.millisecondsSinceEpoch}',
      riderId: rider.id,
      riderName: rider.fullName,
      injuryType: injury.type,
      substance: substance,
      applicationDate: applicationDate,
      status: status,
      decisionDate: applicationDate.add(const Duration(days: 1)),
      doctorName: doctor?.fullName ?? 'Lekarz Dyżurny Zespołu',
      rejectionReason: reason,
      validUntil: validUntil,
    );
  }

  /// Podaje substancję leczniczą z Szarej Strefy (z zatwierdzonym TUE lub nielegalnie bez TUE).
  /// Zwraca zaktualizowanego kolarza (odzyskuje zdolność startową w wyścigu!) oraz rekord kuracji.
  static ({Rider updatedRider, ActiveMedicalTreatment treatment}) administerGreyZoneTreatment({
    required Rider rider,
    required TherapeuticSubstance substance,
    required bool hasApprovedTue,
    String? tueApplicationId,
    required DateTime treatmentDate,
  }) {
    // 1. Zaktualizowanie stanu kolarza: znosi ból, przywraca dopuszczenie do jazdy
    final curHealth = rider.health;
    final curInjury = curHealth.currentInjury;

    final updatedInjury = curInjury?.copyWith(
      trainingAllowed: true, // Pozwala kolarzowi na start w etapie
    );

    final updatedRider = rider.copyWith(
      health: curHealth.copyWith(
        currentInjury: updatedInjury,
      ),
    );

    // 2. Utworzenie rekordu kuracji z oknem detekcji w organizmie
    final detectionEndDate =
        treatmentDate.add(Duration(days: substance.detectionWindowDays));

    final treatment = ActiveMedicalTreatment(
      id: 'treat_${rider.id}_${substance.name}_${treatmentDate.millisecondsSinceEpoch}',
      riderId: rider.id,
      substance: substance,
      administeredDate: treatmentDate,
      hasApprovedTue: hasApprovedTue,
      tueApplicationId: tueApplicationId,
      detectionWindowEndDate: detectionEndDate,
    );

    return (updatedRider: updatedRider, treatment: treatment);
  }

  // ---------------------------------------------------------------------------
  // 4. PRZEPROWADZANIE TESTÓW ANTYDOPINGOWYCH (NA ETAPIE I POZA ZAWODAMI)
  // ---------------------------------------------------------------------------

  /// Wybiera kolarzy do obowiązkowej kontroli antydopingowej po etapie:
  /// 1. Zwycięzca etapu,
  /// 2. Lider klasyfikacji generalnej (jeśli jest),
  /// 3. Losowo 2-3 kolarzy z peletonu.
  static List<Rider> selectRidersForStageAntiDoping({
    required Rider stageWinner,
    Rider? gcLeader,
    required List<Rider> pelotonRiders,
    math.Random? rng,
  }) {
    final random = rng ?? math.Random();
    final selected = <Rider>{stageWinner};

    if (gcLeader != null) {
      selected.add(gcLeader);
    }

    // Dobieramy 2-3 losowych kolarzy z peletonu (spoza zwycięzcy/lidera)
    final pool = pelotonRiders
        .where((r) => r.id != stageWinner.id && (gcLeader == null || r.id != gcLeader.id))
        .toList();
    pool.shuffle(random);

    final randomPicksCount = math.min(pool.length, 2 + random.nextInt(2));
    for (int i = 0; i < randomPicksCount; i++) {
      selected.add(pool[i]);
    }

    return selected.toList();
  }

  /// Przeprowadza test antydopingowy dla kolarza i weryfikuje obecność substancji w organizmie.
  static AntiDopingTestResult conductAntiDopingTest({
    required Rider rider,
    required AntiDopingTestType testType,
    required DateTime testDate,
    required List<ActiveMedicalTreatment> activeTreatments,
    required List<TueApplication> approvedTues,
    bool isDehydrated = false,
    math.Random? rng,
  }) {
    // 1. Wygenerowanie próbki biologicznej (ABP)
    final sample = generatePassportSample(
      rider: rider,
      testType: testType,
      sampleDate: testDate,
      isDehydrated: isDehydrated,
    );

    // 2. Sprawdzenie, czy kolarz ma aktywne substancje w organizmie w oknie detekcji
    final currentTreatments = activeTreatments
        .where((t) => t.riderId == rider.id && t.isDetectableAt(testDate))
        .toList();

    if (currentTreatments.isEmpty) {
      // Czysty wynik
      return AntiDopingTestResult(
        testId: 'test_${rider.id}_${testDate.millisecondsSinceEpoch}',
        riderId: rider.id,
        riderName: rider.fullName,
        testType: testType,
        testDate: testDate,
        outcome: sample.isAtypicalAnomaly
            ? DopingTestOutcome.atypicalFinding
            : DopingTestOutcome.negativeClean,
        passportSample: sample,
        labReportSummary: sample.isAtypicalAnomaly
            ? 'Próbka wolna od substancji egzogennych, lecz wykazuje anomalię wskaźników krwi (OFF-score: ${sample.offScore}).'
            : 'Wynik czysty. Brak obecności substancji zabronionych z listy WADA.',
      );
    }

    // 3. Kolarz zażył substancję leczniczą z Szarej Strefy!
    final activeTreatment = currentTreatments.first;
    final substance = activeTreatment.substance;

    // Sprawdzamy, czy kolarz posiada ważne i zatwierdzone TUE na tę substancję
    final hasValidTue = approvedTues.any((tue) =>
        tue.riderId == rider.id &&
        tue.substance == substance &&
        tue.isValidAt(testDate));

    if (hasValidTue) {
      // Wykryto substancję, lecz zawodnik ma ważne TUE -> Wynik formalnie czysty / uzasadniony medycznie
      return AntiDopingTestResult(
        testId: 'test_${rider.id}_${testDate.millisecondsSinceEpoch}',
        riderId: rider.id,
        riderName: rider.fullName,
        testType: testType,
        testDate: testDate,
        outcome: DopingTestOutcome.negativeClean,
        detectedSubstance: substance,
        isCoveredByValidTue: true,
        passportSample: sample,
        labReportSummary: 'Wykryto śladowe ilości metabolitów: ${substance.displayName}. '
            'Zawodnik posiada ważne wyłączenie dla celów terapeutycznych (TUE UCI). Sprawa zamknięta.',
      );
    } else {
      // BRAK TUE LUB ODRZUCONE TUE -> ADVERSE ANALYTICAL FINDING (AAF)!
      return AntiDopingTestResult(
        testId: 'test_${rider.id}_${testDate.millisecondsSinceEpoch}',
        riderId: rider.id,
        riderName: rider.fullName,
        testType: testType,
        testDate: testDate,
        outcome: DopingTestOutcome.adverseAnalyticalFinding,
        detectedSubstance: substance,
        isCoveredByValidTue: false,
        passportSample: sample,
        labReportSummary: 'POZYTYWNY WYNIK ANALITYCZNY (AAF)! Wykryto zabronioną substancję: '
            '${substance.displayName} (${substance.wadaCategory}) bez zatwierdzonego wyłączenia TUE.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 5. SKANDAL ANTYDOPINGOWY, KARY UCI I ZERWANIE KONTRAKTU SPONSORSKIEGO
  // ---------------------------------------------------------------------------

  /// Przetwarza wpadkę dopingową (AAF lub 3 Whereabouts Failures):
  /// - Zawieszenie zawodnika (6 - 24 miesięcy),
  /// - Grzywna finansowa od UCI dla drużyny (€50 000 - €250 000),
  /// - Odebranie punktów UCI,
  /// - Drastyczny spadek reputacji i zadowolenia sponsorów,
  /// - Ryzyko natychmiastowego zerwania kontraktu przez Sponsora Tytularnego (Strict Morality Clause).
  static AntiDopingScandalReport processAntiDopingViolation({
    required Rider rider,
    required CyclingTeam team,
    TherapeuticSubstance? substance,
    required String violationReason,
    required DateTime incidentDate,
    required bool isInCompetition,
    math.Random? rng,
  }) {
    final random = rng ?? math.Random();

    // Okres zawieszenia: od 6 miesięcy (w przypadku leków szarej strefy) do 24 miesięcy
    final int suspensionMonths;
    if (substance == TherapeuticSubstance.tramadol) {
      suspensionMonths = 6;
    } else if (substance == TherapeuticSubstance.triamcinolone ||
        substance == TherapeuticSubstance.oralCortisone) {
      suspensionMonths = isInCompetition ? 12 : 8;
    } else {
      suspensionMonths = 18; // 3 Whereabouts failures lub ciężki doping
    }

    final sanctionStartDate = incidentDate;
    final sanctionEndDate =
        incidentDate.add(Duration(days: suspensionMonths * 30));

    // Utrata punktów UCI (np. 400 - 1200 pkt)
    final pointsStripped = math.min(rider.careerPointsUci, 300 + (suspensionMonths * 40));

    final sanction = AntiDopingSanction(
      id: 'sanction_${rider.id}_${incidentDate.millisecondsSinceEpoch}',
      riderId: rider.id,
      riderName: rider.fullName,
      reason: violationReason,
      startDate: sanctionStartDate,
      endDate: sanctionEndDate,
      suspensionMonths: suspensionMonths,
      uciPointsStripped: pointsStripped,
    );

    // Kary finansowe i wizerunkowe dla drużyny
    final teamFineEur = 60000 + (suspensionMonths * 8000); // €108 000 - €204 000
    final managerRepLoss = 35 + random.nextInt(15); // -35 do -50 pkt reputacji
    final sponsorSatDrop = 45.0 + random.nextInt(25); // -45 do -70 pkt zadowolenia

    // Test klauzuli moralności dla sponsorów tytularnych (Strict Anti-Doping Morality Clause)
    bool titleSponsorTerminated = false;
    SponsorContract? terminatedSponsor;

    final titleSponsors = team.sponsors.where(
      (s) => s.sponsorTier == SponsorTier.titlePrimary,
    ).toList();

    if (titleSponsors.isNotEmpty) {
      // Sponsor tytularny ma 75% szans na natychmiastowe rozwiązanie umowy,
      // aby ratować wizerunek korporacyjny przed skandalem medialnym!
      final shouldTerminate = random.nextDouble() < 0.75;
      if (shouldTerminate) {
        titleSponsorTerminated = true;
        terminatedSponsor = titleSponsors.first;
      }
    }

    // Nagłówki prasowe i oświadczenie
    final substanceName = substance?.displayName ?? 'niedozwolonych środków / błędu Whereabouts';
    final headline = 'SKANDAL W PELETONIE: ${rider.fullName} ZAWIESZONY PRZEZ UCI ZA STOSOWANIE $substanceName!';

    final sponsorNotice = titleSponsorTerminated
        ? '\n\nSZOKUJĄCA REAKCJA BIZNESOWA: Sponsor tytularny „${terminatedSponsor?.companyName}” '
            'uruchomił natychmiastową klauzulę antydopingową i jednostronnie zerwał wielomilionowy kontrakt sponsorski!'
        : '\n\nSponsorzy wyrazili głębokie zaniepokojenie i zagrozili rewizją umów pod koniec sezonu.';

    final pressRelease = 'Oficjalny komunikat UCI i Międzynarodowej Agencji Testowej (ITA):\n'
        'Zawodnik ${rider.fullName} (drużyna ${team.name}) został tymczasowo zawieszony ze skutkiem natychmiastowym. '
        'W próbce pobranej podczas badań wykryto nieprawidłowości kwalifikujące się jako naruszenie przepisów antydopingowych.\n'
        'Na klub nałożono grzywnę w wysokości €$teamFineEur, a zawodnikowi grozi $suspensionMonths miesięcy bezwzględnej dyskwalifikacji.'
        '$sponsorNotice';

    return AntiDopingScandalReport(
      rider: rider,
      substance: substance,
      sanction: sanction,
      teamFineEur: teamFineEur,
      managerReputationPenalty: managerRepLoss,
      sponsorSatisfactionPenalty: sponsorSatDrop,
      titleSponsorTerminated: titleSponsorTerminated,
      terminatedSponsor: terminatedSponsor,
      mediaReactionHeadline: headline,
      pressReleaseText: pressRelease,
    );
  }

  /// Aktualizuje stan drużyny [`CyclingTeam`] po wybuchu afery dopingowej:
  /// potrąca grzywnę z budżetu, odejmuje punkty UCI, obniża satysfakcję sponsorów,
  /// a w razie zerwania umowy usuwa sponsora tytularnego z listy kontraktów.
  static CyclingTeam applyScandalConsequencesToTeam({
    required CyclingTeam team,
    required AntiDopingScandalReport report,
  }) {
    // 1. Potrącenie kary finansowej
    final newCashBalance = math.max(0, team.cashBalanceEur - report.teamFineEur);

    // 2. Odjęcie punktów UCI
    final newUciPoints = math.max(0, team.uciPointsSeason - report.sanction.uciPointsStripped);

    // 3. Aktualizacja sponsorów (usunięcie zerwanego sponsora tytularnego i spadek satysfakcji pozostałych)
    final updatedSponsors = <SponsorContract>[];
    for (final s in team.sponsors) {
      if (report.titleSponsorTerminated &&
          report.terminatedSponsor != null &&
          s.id == report.terminatedSponsor!.id) {
        // Ten sponsor zerwał umowę - nie dodajemy go do nowej listy
        continue;
      }

      // Spadek zadowolenia pozostałych sponsorów
      final newSat = (s.sponsorSatisfaction - report.sponsorSatisfactionPenalty).clamp(5.0, 100.0);
      updatedSponsors.add(s.copyWith(sponsorSatisfaction: newSat));
    }

    return team.copyWith(
      cashBalanceEur: newCashBalance,
      uciPointsSeason: newUciPoints,
      sponsors: updatedSponsors,
    );
  }
}
