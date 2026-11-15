// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import '../../models/race/race_stage.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';

/// Okoliczność i kontekst zwołania konferencji prasowej lub wywiadu.
enum PressConferenceContext {
  /// Oficjalna konferencja przed startem Grand Touru (Grand Départ)
  preGrandTourOpening,

  /// Wywiad po spektakularnym zwycięstwie etapowym na podium
  postStageVictory,

  /// Trudna konferencja po bolesnej stracie czasu lidera w górach lub na wiatrach
  postStageDefeatOrTimeLoss,

  /// Konferencja kryzysowa po groźnej kraksie i podejrzeniu kontuzji lidera
  postCrashAndInjuryCrisis,

  /// Odprawa przed królewskim etapem górskim (Queen Stage Preview & Blefy taktyczne)
  preQueenStageMountainPreview,

  /// Pytania o spekulacje transferowe i wygasający kontrakt kluczowego zawodnika
  transferRumorsAndSillySeason,

  /// Konferencja po spięciu i niesubordynacji dwóch liderów w wyścigu (Afera domowa)
  intraTeamFeudScandal;

  String toJson() => name;

  static PressConferenceContext fromJson(String value) {
    return PressConferenceContext.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PressConferenceContext.preGrandTourOpening,
    );
  }

  String get displayName {
    switch (this) {
      case PressConferenceContext.preGrandTourOpening:
        return 'Wielka Konferencja Przedstartowa (Grand Départ)';
      case PressConferenceContext.postStageVictory:
        return 'Konferencja Zwycięzcy Etapu';
      case PressConferenceContext.postStageDefeatOrTimeLoss:
        return 'Wywiad po Stracie Czasu w Peletonie';
      case PressConferenceContext.postCrashAndInjuryCrisis:
        return 'Briefing Medyczny po Kraksie Lidera';
      case PressConferenceContext.preQueenStageMountainPreview:
        return 'Odprawa Przed Królewskim Etapem Górskim';
      case PressConferenceContext.transferRumorsAndSillySeason:
        return 'Pytania o Plotki Transferowe i Kontrakty';
      case PressConferenceContext.intraTeamFeudScandal:
        return 'Konferencja Kryzysowa: Konflikt w Drużynie';
    }
  }
}

/// Renomowana redakcja kolarska zadająca pytania na konferencji prasowej.
class MediaOutlet {
  final String id;
  final String name;
  final String countryIso;
  final String journalistName;
  final String editorialTone;

  const MediaOutlet({
    required this.id,
    required this.name,
    required this.countryIso,
    required this.journalistName,
    required this.editorialTone,
  });

  static const lequipe = MediaOutlet(
    id: 'lequipe',
    name: 'L\'Équipe',
    countryIso: 'FR',
    journalistName: 'Philippe Brunel',
    editorialTone: 'Wnikliwe pytania z naciskiem na dramaturgię, presję żółtej koszulki i heroizm.',
  );

  static const gazzetta = MediaOutlet(
    id: 'gazzetta',
    name: 'La Gazzetta dello Sport',
    countryIso: 'ITA',
    journalistName: 'Ciro Scognamiglio',
    editorialTone: 'Włoska pasja taktyczna, dociekanie niuansów podjazdów i odwagi do ataków.',
  );

  static const cyclingnews = MediaOutlet(
    id: 'cyclingnews',
    name: 'Cyclingnews',
    countryIso: 'GB',
    journalistName: 'Stephen Farrand',
    editorialTone: 'Anglojęzyczny chłodny profesjonalizm, waty na kilogram, pacing i zakulisowa polityka.',
  );

  static const wielerflits = MediaOutlet(
    id: 'wielerflits',
    name: 'WielerFlits',
    countryIso: 'NL',
    journalistName: 'Raymond Kerckhoffs',
    editorialTone: 'Bezlitosne pytania o wiatry, bruki, taktykę pociągu i transfery w WorldTourze.',
  );

  static const marca = MediaOutlet(
    id: 'marca',
    name: 'Marca / AS',
    countryIso: 'ES',
    journalistName: 'Nacho Labarga',
    editorialTone: 'Ekspresyjne pytania o hiszpańską dumę, walkę na wyniszczenie i ataki w wysokich górach.',
  );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'countryIso': countryIso,
        'journalistName': journalistName,
        'editorialTone': editorialTone,
      };

  factory MediaOutlet.fromJson(Map<String, dynamic> json) {
    return MediaOutlet(
      id: json['id'] as String,
      name: json['name'] as String,
      countryIso: json['countryIso'] as String,
      journalistName: json['journalistName'] as String,
      editorialTone: json['editorialTone'] as String,
    );
  }
}

/// Tematyka i oś pytania dziennikarskiego.
enum QuestionTopic {
  leaderConditionAndForm,
  mountainTacticsAndPacing,
  crashDamageAndPainManagement,
  transferRumorsAndContract,
  dualLeaderDynamicAndHierarchy,
  rivalryAndMindGames;

  String toJson() => name;

  static QuestionTopic fromJson(String value) {
    return QuestionTopic.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => QuestionTopic.leaderConditionAndForm,
    );
  }
}

/// Styl i ton odpowiedzi menedżera do mikrofonu prasowego.
enum PressAnswerTone {
  /// Blef taktyczny / dezinformacja (udawanie słabości, uśpienie czujności rywali AI)
  tacticalBluff,

  /// Agresywna pewność siebie / manifestacja potęgi (zastraszenie rywali, zachwyceni sponsorzy)
  aggressiveConfidence,

  /// Spokojna dyplomacja / tarcza ochronna dla drużyny (zdejmowanie presji, skupienie na procesie)
  diplomaticShield,

  /// Przeniesienie presji na rywali / kontratak retoryczny (zwrócenie uwagi na rywali, zrzucenie ciężaru)
  pressureDeflection;

  String toJson() => name;

  static PressAnswerTone fromJson(String value) {
    return PressAnswerTone.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PressAnswerTone.diplomaticShield,
    );
  }

  String get displayName {
    switch (this) {
      case PressAnswerTone.tacticalBluff:
        return 'Blef Taktyczny (Mind Games & Uśpienie Rywali)';
      case PressAnswerTone.aggressiveConfidence:
        return 'Agresywna Pewność Siebie (Demonstracja Siły)';
      case PressAnswerTone.diplomaticShield:
        return 'Spokojna Dyplomacja (Ochrona Zespołu)';
      case PressAnswerTone.pressureDeflection:
        return 'Przeniesienie Presji na Rywali';
    }
  }
}

/// Pojedyncza opcja odpowiedzi na pytanie dziennikarza z określonymi konsekwencjami mechanicznymi.
class PressConferenceAnswerOption {
  final String id;
  final PressAnswerTone tone;
  final String answerText;

  /// Zmiana presji psychicznej ciążącej na kolarzu (-20 do +20 pkt)
  final int riderPressureDelta;

  /// Zmiana satysfakcji sponsorów (-10.0 do +10.0 pkt)
  final double sponsorSatisfactionDelta;

  /// Mnożnik czujności rywali AI na kolejnym etapie (np. 0.70x = uśpienie, 1.35x = stan najwyższej gotowości)
  final double rivalAlertnessMultiplier;

  /// Zmiana reputacji menedżera (-3 do +5 pkt)
  final int managerReputationDelta;

  /// Zmiana morale zespołu (-10.0 do +10.0 pkt)
  final double teamMoraleDelta;

  /// Bonus procentowy do zaskoczenia rywali atakiem z dystansu (np. +18% przy udanym blefie)
  final double tacticalSurpriseBonusPercent;

  /// Przewidywana reakcja mediów i nagłówek prasowy
  final String expectedMediaReaction;

  const PressConferenceAnswerOption({
    required this.id,
    required this.tone,
    required this.answerText,
    required this.riderPressureDelta,
    required this.sponsorSatisfactionDelta,
    required this.rivalAlertnessMultiplier,
    required this.managerReputationDelta,
    required this.teamMoraleDelta,
    this.tacticalSurpriseBonusPercent = 0.0,
    required this.expectedMediaReaction,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tone': tone.toJson(),
        'answerText': answerText,
        'riderPressureDelta': riderPressureDelta,
        'sponsorSatisfactionDelta': sponsorSatisfactionDelta,
        'rivalAlertnessMultiplier': rivalAlertnessMultiplier,
        'managerReputationDelta': managerReputationDelta,
        'teamMoraleDelta': teamMoraleDelta,
        'tacticalSurpriseBonusPercent': tacticalSurpriseBonusPercent,
        'expectedMediaReaction': expectedMediaReaction,
      };

  factory PressConferenceAnswerOption.fromJson(Map<String, dynamic> json) {
    return PressConferenceAnswerOption(
      id: json['id'] as String,
      tone: PressAnswerTone.fromJson(json['tone'] as String),
      answerText: json['answerText'] as String,
      riderPressureDelta: (json['riderPressureDelta'] as num).toInt(),
      sponsorSatisfactionDelta:
          (json['sponsorSatisfactionDelta'] as num).toDouble(),
      rivalAlertnessMultiplier:
          (json['rivalAlertnessMultiplier'] as num).toDouble(),
      managerReputationDelta: (json['managerReputationDelta'] as num).toInt(),
      teamMoraleDelta: (json['teamMoraleDelta'] as num).toDouble(),
      tacticalSurpriseBonusPercent:
          (json['tacticalSurpriseBonusPercent'] as num?)?.toDouble() ?? 0.0,
      expectedMediaReaction: json['expectedMediaReaction'] as String,
    );
  }
}

/// Pojedyncze pytanie zadane przez dziennikarza z 4 opcjami odpowiedzi do wyboru.
class PressConferenceQuestion {
  final String id;
  final MediaOutlet outlet;
  final QuestionTopic topic;
  final String questionText;
  final String contextDescription;
  final List<PressConferenceAnswerOption> options;

  const PressConferenceQuestion({
    required this.id,
    required this.outlet,
    required this.topic,
    required this.questionText,
    required this.contextDescription,
    required this.options,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'outlet': outlet.toJson(),
        'topic': topic.toJson(),
        'questionText': questionText,
        'contextDescription': contextDescription,
        'options': options.map((o) => o.toJson()).toList(),
      };

  factory PressConferenceQuestion.fromJson(Map<String, dynamic> json) {
    return PressConferenceQuestion(
      id: json['id'] as String,
      outlet: MediaOutlet.fromJson(json['outlet'] as Map<String, dynamic>),
      topic: QuestionTopic.fromJson(json['topic'] as String),
      questionText: json['questionText'] as String,
      contextDescription: json['contextDescription'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) =>
              PressConferenceAnswerOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Pełna sesja konferencji prasowej wygenerowana dla gracza.
class PressConferenceSession {
  final String id;
  final PressConferenceContext context;
  final String raceName;
  final int? stageNumber;
  final String targetRiderName;
  final List<PressConferenceQuestion> questions;
  final DateTime conferenceDate;

  const PressConferenceSession({
    required this.id,
    required this.context,
    required this.raceName,
    this.stageNumber,
    required this.targetRiderName,
    required this.questions,
    required this.conferenceDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'context': context.toJson(),
        'raceName': raceName,
        'stageNumber': stageNumber,
        'targetRiderName': targetRiderName,
        'questions': questions.map((q) => q.toJson()).toList(),
        'conferenceDate': conferenceDate.toIso8601String(),
      };

  factory PressConferenceSession.fromJson(Map<String, dynamic> json) {
    return PressConferenceSession(
      id: json['id'] as String,
      context: PressConferenceContext.fromJson(json['context'] as String),
      raceName: json['raceName'] as String,
      stageNumber: (json['stageNumber'] as num?)?.toInt(),
      targetRiderName: json['targetRiderName'] as String,
      questions: (json['questions'] as List<dynamic>)
          .map((e) =>
              PressConferenceQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      conferenceDate: DateTime.parse(json['conferenceDate'] as String),
    );
  }
}

/// Rezultat i skumulowane konsekwencje konferencji prasowej po dokonaniu wyborów przez gracza.
class PressConferenceResult {
  final PressConferenceSession session;
  final Map<String, PressConferenceAnswerOption> chosenAnswers;
  final int totalRiderPressureDelta;
  final double totalSponsorSatisfactionDelta;
  final double rivalAlertnessFactor;
  final double tacticalSurpriseBonusPercent;
  final int totalManagerReputationDelta;
  final double totalTeamMoraleDelta;
  final String mediaSummaryReport;
  final List<String> frontPageHeadlines;

  const PressConferenceResult({
    required this.session,
    required this.chosenAnswers,
    required this.totalRiderPressureDelta,
    required this.totalSponsorSatisfactionDelta,
    required this.rivalAlertnessFactor,
    required this.tacticalSurpriseBonusPercent,
    required this.totalManagerReputationDelta,
    required this.totalTeamMoraleDelta,
    required this.mediaSummaryReport,
    required this.frontPageHeadlines,
  });
}

/// Główny serwis generowania konferencji prasowych, wywiadów i psychologii medialnej
/// (Press Conference Service).
class PressConferenceService {
  PressConferenceService._();

  /// Generuje kompletną konferencję prasową z 2-3 wnikliwymi pytaniami od dziennikarzy
  /// oraz 4 wariantami odpowiedzi dla gracza.
  static PressConferenceSession generatePressConference({
    required PressConferenceContext context,
    required TourRace race,
    RaceStage? currentStage,
    required Rider focalRider,
    Rider? rivalLeader,
    bool riderWonStage = false,
    bool riderLostTime = false,
    bool riderCrashed = false,
    bool isDualLeaderClash = false,
    DateTime? conferenceDate,
  }) {
    final date = conferenceDate ?? DateTime.now();
    final questions = <PressConferenceQuestion>[];
    final rivalName = rivalLeader?.fullName ?? 'Główny Rywal w GC';

    switch (context) {
      case PressConferenceContext.preGrandTourOpening:
        questions.add(_buildPreGrandTourExpectationsQuestion(race, focalRider));
        questions.add(_buildTacticalPlanQuestion(race, focalRider, rivalName));
        break;

      case PressConferenceContext.postStageVictory:
        questions.add(_buildVictoryEuphoriaQuestion(race, currentStage, focalRider));
        questions.add(_buildGcAmbitionAfterWinQuestion(race, focalRider, rivalName));
        break;

      case PressConferenceContext.postStageDefeatOrTimeLoss:
        questions.add(_buildTimeLossCrisisQuestion(race, currentStage, focalRider));
        questions.add(_buildComebackStrategyQuestion(race, focalRider));
        break;

      case PressConferenceContext.postCrashAndInjuryCrisis:
        questions.add(_buildCrashDamageHealthQuestion(race, focalRider));
        questions.add(_buildContinueRaceOrWithdrawQuestion(race, focalRider));
        break;

      case PressConferenceContext.preQueenStageMountainPreview:
        questions.add(_buildQueenStageAttackIntentQuestion(race, currentStage, focalRider, rivalName));
        questions.add(_buildMountainPacingBluffQuestion(race, focalRider));
        break;

      case PressConferenceContext.transferRumorsAndSillySeason:
        questions.add(_buildTransferRumorQuestion(race, focalRider));
        break;

      case PressConferenceContext.intraTeamFeudScandal:
        questions.add(_buildIntraTeamFeudQuestion(race, focalRider));
        break;
    }

    return PressConferenceSession(
      id: 'press_${race.id}_${context.name}_${date.millisecondsSinceEpoch}',
      context: context,
      raceName: race.name,
      stageNumber: currentStage?.stageNumber,
      targetRiderName: focalRider.fullName,
      questions: questions,
      conferenceDate: date,
    );
  }

  // ---------------------------------------------------------------------------
  // GENERATORY PYTAŃ I 4 ODPOWIEDZI
  // ---------------------------------------------------------------------------

  static PressConferenceAnswerOption _createOption({
    required String id,
    required PressAnswerTone tone,
    required String answerText,
    required int riderPressureDelta,
    required double sponsorSatisfactionDelta,
    required double rivalAlertnessMultiplier,
    required int managerReputationDelta,
    required double teamMoraleDelta,
    double tacticalSurpriseBonusPercent = 0.0,
    required String expectedMediaReaction,
  }) {
    return PressConferenceAnswerOption(
      id: id,
      tone: tone,
      answerText: answerText,
      riderPressureDelta: riderPressureDelta,
      sponsorSatisfactionDelta: sponsorSatisfactionDelta,
      rivalAlertnessMultiplier: rivalAlertnessMultiplier,
      managerReputationDelta: managerReputationDelta,
      teamMoraleDelta: teamMoraleDelta,
      tacticalSurpriseBonusPercent: tacticalSurpriseBonusPercent,
      expectedMediaReaction: expectedMediaReaction,
    );
  }

  static PressConferenceQuestion _buildPreGrandTourExpectationsQuestion(
    TourRace race,
    Rider rider,
  ) {
    return PressConferenceQuestion(
      id: 'q_pre_gt_expectations',
      outlet: MediaOutlet.lequipe,
      topic: QuestionTopic.leaderConditionAndForm,
      contextDescription: 'Grand Départ ${race.name}. Sala konferencyjna pęka w szwach, setki dziennikarzy patrzą na Wasz sztab.',
      questionText: 'Philippe Brunel (L\'Équipe): „Menedżerze, ${rider.fullName} przyjeżdża na ten wyścig z wielkimi nadziejami kibiców. '
          'Czy Wasz lider jest w szczytowej formie, by rzucić wyzwanie faworytom i wygrać klasyfikację generalną?”',
      options: [
        _createOption(
          id: 'opt_pre_gt_bluff',
          tone: PressAnswerTone.tacticalBluff,
          answerText: '„Przygotowania były wyboiste, a ostatnie testy laboratoryjne nie napawają optymizmem. '
              'Jedziemy ostrożnie, bez presji na generalkę, raczej celując w pojedyncze etapy.”',
          riderPressureDelta: -12,
          sponsorSatisfactionDelta: -3.0,
          rivalAlertnessMultiplier: 0.75, // Rywale odpuszczają czujność!
          managerReputationDelta: -1,
          teamMoraleDelta: -2.0,
          tacticalSurpriseBonusPercent: 0.15,
          expectedMediaReaction: 'Prasa zszokowana asekuranctwem: „Czy lider jest bez formy? Rywale nie traktują go jako zagrożenia.”',
        ),
        _createOption(
          id: 'opt_pre_gt_aggressive',
          tone: PressAnswerTone.aggressiveConfidence,
          answerText: '„${rider.fullName} kręci najlepsze waty w swojej karierze. Przyjechaliśmy tu wyłącznie po zwycięstwo '
              'i zamierzamy dyktować tempo od pierwszego podjazdu!”',
          riderPressureDelta: 16,
          sponsorSatisfactionDelta: 7.0, // Sponsorzy wniebowzięci
          rivalAlertnessMultiplier: 1.35, // Rywale w pełnym alercie
          managerReputationDelta: 3,
          teamMoraleDelta: 8.0,
          expectedMediaReaction: 'Gazety krzyczą z pierwszych stron: „DEKLARACJA WOJNY! Lider rzuca wyzwanie całemu peletonowi!”',
        ),
        _createOption(
          id: 'opt_pre_gt_diplomatic',
          tone: PressAnswerTone.diplomaticShield,
          answerText: '„Wykonaliśmy solidną pracę na zgrupowaniach wysokogórskich. Grand Tour to 21 dni cierpienia; '
              'szanujemy rywali, skupiamy się na każdym etapie i wierzymy w nasz plan.”',
          riderPressureDelta: -6,
          sponsorSatisfactionDelta: 3.0,
          rivalAlertnessMultiplier: 1.00,
          managerReputationDelta: 2,
          teamMoraleDelta: 4.0,
          expectedMediaReaction: 'Spokojna, profesjonalna narracja sztabu. Zespół unika niepotrzebnej burzy medialnej.',
        ),
        _createOption(
          id: 'opt_pre_gt_deflection',
          tone: PressAnswerTone.pressureDeflection,
          answerText: '„Presja spoczywa na zespołach z dwukrotnie większym budżetem niż nasz. '
              'To oni muszą gonić i kontrolować wyścig. My jesteśmy pretendentem i wykorzystamy każdą ich pomyłkę.”',
          riderPressureDelta: -14,
          sponsorSatisfactionDelta: 1.0,
          rivalAlertnessMultiplier: 0.90,
          managerReputationDelta: 2,
          teamMoraleDelta: 3.0,
          expectedMediaReaction: 'Błyskotliwa riposta menedżera: ciężar faworyta sprytnie zrzucony na najbogatsze stajnie peletonu.',
        ),
      ],
    );
  }

  static PressConferenceQuestion _buildTacticalPlanQuestion(
    TourRace race,
    Rider rider,
    String rivalName,
  ) {
    return PressConferenceQuestion(
      id: 'q_pre_gt_tactics',
      outlet: MediaOutlet.gazzetta,
      topic: QuestionTopic.rivalryAndMindGames,
      contextDescription: 'Włoscy korespondenci pytają o bezpośrednie starcie z najgroźniejszym rywalem.',
      questionText: 'Ciro Scognamiglio (La Gazzetta dello Sport): „Wszyscy eksperci typują pojedynek ${rider.fullName} kontra $rivalName. '
          'Gdzie zamierzacie zadać decydujący cios?”',
      options: [
        _createOption(
          id: 'opt_tactics_bluff',
          tone: PressAnswerTone.tacticalBluff,
          answerText: '„Nie mamy sił ani pociągu, by rywalizować czołowo z $rivalName na długich przełęczach. '
              'Będziemy po prostu pilnować koła i modlić się o przetrwanie w trzecim tygodniu.”',
          riderPressureDelta: -10,
          sponsorSatisfactionDelta: -2.0,
          rivalAlertnessMultiplier: 0.70,
          managerReputationDelta: 0,
          teamMoraleDelta: -1.0,
          tacticalSurpriseBonusPercent: 0.20,
          expectedMediaReaction: 'Eksperci zdumieni brakiem wiary: „Rywal $rivalName może poczuć się zbyt pewnie na trasie!”',
        ),
        _createOption(
          id: 'opt_tactics_aggressive',
          tone: PressAnswerTone.aggressiveConfidence,
          answerText: '„Znamy słabe punkty $rivalName – gubi się na sztywnych stromiznach powyżej 10% i w upale. '
              'Tam właśnie zdetonujemy wyścig!”',
          riderPressureDelta: 14,
          sponsorSatisfactionDelta: 6.0,
          rivalAlertnessMultiplier: 1.40,
          managerReputationDelta: 3,
          teamMoraleDelta: 6.0,
          expectedMediaReaction: 'Wojna psychologiczna w toku! Sztab $rivalName odpowiada oburzeniem na zaczepki.',
        ),
        _createOption(
          id: 'opt_tactics_diplomatic',
          tone: PressAnswerTone.diplomaticShield,
          answerText: '„$rivalName to wybitny mistrz i wielki kolarz. Szosa zweryfikuje, kto lepiej przepracował zimę. '
              'My skupiamy się na naszej jeździe.”',
          riderPressureDelta: -4,
          sponsorSatisfactionDelta: 2.0,
          rivalAlertnessMultiplier: 1.00,
          managerReputationDelta: 2,
          teamMoraleDelta: 3.0,
          expectedMediaReaction: 'Klasa i szacunek dla rywala docenione przez międzynarodową prasę.',
        ),
        _createOption(
          id: 'opt_tactics_deflection',
          tone: PressAnswerTone.pressureDeflection,
          answerText: '„Fiksacja na jednym rywalu to błąd. Na starcie jest dziesięciu kandydatów do podium. '
              'Jeśli $rivalName będzie patrzył tylko na nas, ktoś inny ucieknie po zwycięstwo.”',
          riderPressureDelta: -8,
          sponsorSatisfactionDelta: 2.0,
          rivalAlertnessMultiplier: 0.85,
          managerReputationDelta: 2,
          teamMoraleDelta: 4.0,
          expectedMediaReaction: 'Dziennikarze chwalą chłodną kalkulację taktyczną i dojrzałość menedżera.',
        ),
      ],
    );
  }

  static PressConferenceQuestion _buildVictoryEuphoriaQuestion(
    TourRace race,
    RaceStage? stage,
    Rider rider,
  ) {
    final stageNum = stage?.stageNumber ?? 1;
    return PressConferenceQuestion(
      id: 'q_post_win_euphoria',
      outlet: MediaOutlet.cyclingnews,
      topic: QuestionTopic.leaderConditionAndForm,
      contextDescription: 'Strefa wywiadów po kapitalnym zwycięstwie na etapie $stageNum. Błyski fleszy, szampan na podium.',
      questionText: 'Stephen Farrand (Cyclingnews): „Niesamowity pokaz mocy! ${rider.fullName} zniszczył rywali w finale. '
          'Czy to był najlepszy dzień w historii Waszego zespołu?”',
      options: [
        _createOption(
          id: 'opt_win_bluff',
          tone: PressAnswerTone.tacticalBluff,
          answerText: '„Cieszymy się z etapu, ale ten wysiłek kosztował ${rider.fullName} resztki sił. '
              'Jutro zapłacimy za to wysoką cenę w górach, nogi są kompletnie puste.”',
          riderPressureDelta: -8,
          sponsorSatisfactionDelta: 2.0,
          rivalAlertnessMultiplier: 0.72,
          managerReputationDelta: 1,
          teamMoraleDelta: 2.0,
          tacticalSurpriseBonusPercent: 0.18,
          expectedMediaReaction: 'Prasa zastanawia się nad zmęczeniem zwycięzcy: „Czy rywale zaatakują osłabionego triumfatora?”',
        ),
        _createOption(
          id: 'opt_win_aggressive',
          tone: PressAnswerTone.aggressiveConfidence,
          answerText: '„To dopiero początek demonstracji naszej siły! Zmiażdżyliśmy ich dzisiaj i zamierzamy '
              'powtórzyć to na każdym kolejnym górskim etapie!”',
          riderPressureDelta: 15,
          sponsorSatisfactionDelta: 8.0,
          rivalAlertnessMultiplier: 1.45,
          managerReputationDelta: 4,
          teamMoraleDelta: 10.0,
          expectedMediaReaction: 'Nagłówki: „NIEPOWSTRZYMANI! Lider wbija flagę w serca rywali i zapowiada rzeź w górach!”',
        ),
        _createOption(
          id: 'opt_win_diplomatic',
          tone: PressAnswerTone.diplomaticShield,
          answerText: '„To sukces całej 8-ki kolarzy, mechaników i masażystów. Chwila radości dziś wieczorem, '
              'a od jutra pełna koncentracja na kolejnych zadaniach.”',
          riderPressureDelta: -5,
          sponsorSatisfactionDelta: 6.0,
          rivalAlertnessMultiplier: 1.05,
          managerReputationDelta: 3,
          teamMoraleDelta: 6.0,
          expectedMediaReaction: 'Wzorowa postawa lidera i sztabu: uznanie dla pracy pomocników wzmacnia jedność w drużynie.',
        ),
        _createOption(
          id: 'opt_win_deflection',
          tone: PressAnswerTone.pressureDeflection,
          answerText: '„Wygraliśmy etap, ale to rywale wciąż mają koszulkę lidera i to oni muszą bronić pozycji. '
              'Niech oni się martwią.”',
          riderPressureDelta: -10,
          sponsorSatisfactionDelta: 4.0,
          rivalAlertnessMultiplier: 0.95,
          managerReputationDelta: 2,
          teamMoraleDelta: 5.0,
          expectedMediaReaction: 'Sprytna zagrywka: triumf etapowy świętowany, ale presja natychmiast przerzucona na obóz rywali.',
        ),
      ],
    );
  }

  static PressConferenceQuestion _buildGcAmbitionAfterWinQuestion(
    TourRace race,
    Rider rider,
    String rivalName,
  ) {
    return PressConferenceQuestion(
      id: 'q_post_win_gc_ambition',
      outlet: MediaOutlet.wielerflits,
      topic: QuestionTopic.rivalryAndMindGames,
      contextDescription: 'Dziennikarze z Beneluksu dopytują o zmianę celów z etapowych na żółtą koszulkę.',
      questionText: 'Raymond Kerckhoffs (WielerFlits): „Po tym zwycięstwie strata do $rivalName stopniała do kilkunastu sekund. '
          'Czy zmienicie strategię i zaatakujecie żółtą koszulkę?”',
      options: [
        _createOption(
          id: 'opt_gc_bluff',
          tone: PressAnswerTone.tacticalBluff,
          answerText: '„Nie, klasyfikacja generalna nas nie interesuje. Nasz skład nie jest zbudowany do kontrolowania wyścigu. '
              'Jeśli $rivalName chce żółtka, niech go sobie pilnuje.”',
          riderPressureDelta: -12,
          sponsorSatisfactionDelta: -1.0,
          rivalAlertnessMultiplier: 0.68,
          managerReputationDelta: 1,
          teamMoraleDelta: 1.0,
          tacticalSurpriseBonusPercent: 0.22,
          expectedMediaReaction: 'Dezinformacja doskonała: rywale są przekonani, że odpuścicie generalkę, co daje wolną rękę na trasie.',
        ),
        _createOption(
          id: 'opt_gc_aggressive',
          tone: PressAnswerTone.aggressiveConfidence,
          answerText: '„Oczywiście! Idziemy po koszulkę lidera i nie spoczniemy, dopóki nie staniemy na najwyższym stopniu w Paryżu!”',
          riderPressureDelta: 18,
          sponsorSatisfactionDelta: 9.0,
          rivalAlertnessMultiplier: 1.50,
          managerReputationDelta: 4,
          teamMoraleDelta: 9.0,
          expectedMediaReaction: 'Euforia sponsorów i kibiców! Jednak rywale wystawiają potrójną straż wokół Waszego lidera.',
        ),
        _createOption(
          id: 'opt_gc_diplomatic',
          tone: PressAnswerTone.diplomaticShield,
          answerText: '„Bierzemy wyścig dzień po dniu. Jeśli nadarzy się okazja na atak, skorzystamy z niej, '
              'ale nie tracimy chłodnej głowy.”',
          riderPressureDelta: -4,
          sponsorSatisfactionDelta: 5.0,
          rivalAlertnessMultiplier: 1.00,
          managerReputationDelta: 2,
          teamMoraleDelta: 4.0,
          expectedMediaReaction: 'Zrównoważony komunikat sztabu, pełna aprobata ekspertów telewizyjnych.',
        ),
        _createOption(
          id: 'opt_gc_deflection',
          tone: PressAnswerTone.pressureDeflection,
          answerText: '„Zapytajcie dyrektora $rivalName, czy nie boi się jutrzejszego etapu. '
              'To oni mają wszystko do stracenia, my już zrealizowaliśmy plan minimum wygrywając etap.”',
          riderPressureDelta: -9,
          sponsorSatisfactionDelta: 4.0,
          rivalAlertnessMultiplier: 0.85,
          managerReputationDelta: 3,
          teamMoraleDelta: 5.0,
          expectedMediaReaction: 'Błyskotliwa szpila w obóz rywala! Media ekscytują się rosnącą presją na faworycie.',
        ),
      ],
    );
  }

  static PressConferenceQuestion _buildTimeLossCrisisQuestion(
    TourRace race,
    RaceStage? stage,
    Rider rider,
  ) {
    final stageNum = stage?.stageNumber ?? 1;
    return PressConferenceQuestion(
      id: 'q_post_defeat_crisis',
      outlet: MediaOutlet.lequipe,
      topic: QuestionTopic.leaderConditionAndForm,
      contextDescription: 'Gorąca atmosfera pod autokarem zespołu po etapie $stageNum. Lider stracił 2 minuty i wypadł z podium.',
      questionText: 'Philippe Brunel (L\'Équipe): „To był czarny dzień dla Waszego zespołu. ${rider.fullName} nie wytrzymał tempa rywali. '
          'Czy to koniec marzeń o klasyfikacji generalnej?”',
      options: [
        _createOption(
          id: 'opt_defeat_bluff',
          tone: PressAnswerTone.tacticalBluff,
          answerText: '„Nogi nie podawały i ewidentnie coś wisi w powietrzu, może jakaś infekcja. '
              'Wycofujemy się z walki o podium, teraz będziemy po prostu zbierać siły w grupetto.”',
          riderPressureDelta: -16,
          sponsorSatisfactionDelta: -6.0,
          rivalAlertnessMultiplier: 0.65, // Rywale całkowicie skreślają lidera!
          managerReputationDelta: -2,
          teamMoraleDelta: -4.0,
          tacticalSurpriseBonusPercent: 0.25, // Kosmiczny bonus do niespodziewanego rajdu!
          expectedMediaReaction: 'Grobowe nastroje w mediach: „Katastrofa zespołu, lider wywiesza białą flagę!” Rywale przestają go pilnować.',
        ),
        _createOption(
          id: 'opt_defeat_aggressive',
          tone: PressAnswerTone.aggressiveConfidence,
          answerText: '„Przegraliśmy bitwę, ale nie wojnę! Kto nas skreśla, pożałuje tego w trzecim tygodniu. '
              'Zaatakujemy z taką furią, że rywale nie będą wiedzieli, co się dzieje!”',
          riderPressureDelta: 14,
          sponsorSatisfactionDelta: 3.0,
          rivalAlertnessMultiplier: 1.25,
          managerReputationDelta: 2,
          teamMoraleDelta: 6.0,
          expectedMediaReaction: 'Odpowiedź wojownika! Mimo strat sponsorzy doceniają nieugiętą postawę i walkę do końca.',
        ),
        _createOption(
          id: 'opt_defeat_diplomatic',
          tone: PressAnswerTone.diplomaticShield,
          answerText: '„Taki jest sport. Każdy ma słabszy dzień na 3-tygodniowym Tourze. Przeanalizujemy błędy, '
              'zregenerujemy się i jutro rano stajemy na starcie z podniesioną głową.”',
          riderPressureDelta: -8,
          sponsorSatisfactionDelta: -1.0,
          rivalAlertnessMultiplier: 0.95,
          managerReputationDelta: 1,
          teamMoraleDelta: 2.0,
          expectedMediaReaction: 'Dojrzałość i spokój w obliczu porażki uspokajają atmosferę w zespole.',
        ),
        _createOption(
          id: 'opt_defeat_deflection',
          tone: PressAnswerTone.pressureDeflection,
          answerText: '„Straciliśmy minuty przez zablokowanie drogi przez motocykl sędziowski i kraksę rywali. '
              'To nie kwestia nóg, tylko pecha organizacyjnego. Czas na rewanż.”',
          riderPressureDelta: -10,
          sponsorSatisfactionDelta: 0.0,
          rivalAlertnessMultiplier: 1.05,
          managerReputationDelta: 0,
          teamMoraleDelta: 3.0,
          expectedMediaReaction: 'Menedżer kieruje ogień krytyki na sędziów UCI, zdejmując winę z barków lidera.',
        ),
      ],
    );
  }

  static PressConferenceQuestion _buildComebackStrategyQuestion(
    TourRace race,
    Rider rider,
  ) {
    return PressConferenceQuestion(
      id: 'q_post_defeat_comeback',
      outlet: MediaOutlet.marca,
      topic: QuestionTopic.mountainTacticsAndPacing,
      contextDescription: 'Hiszpańscy żurnaliści pytają o szalone rajdy i taktykę "all-in".',
      questionText: 'Nacho Labarga (Marca): „Menedżerze, hiszpańscy kibice kochają szaleńców, którzy atakują z 70 kilometrów. '
          'Czy zobaczymy jutro szarżę na wszystko albo nic?”',
      options: [
        _createOption(
          id: 'opt_comeback_bluff',
          tone: PressAnswerTone.tacticalBluff,
          answerText: '„Absolutnie nie. Jesteśmy zbyt wycieńczeni na jakiekolwiek ataki z daleka. '
              'Będziemy jechać zachowawczo w środku peletonu.”',
          riderPressureDelta: -12,
          sponsorSatisfactionDelta: -3.0,
          rivalAlertnessMultiplier: 0.65,
          managerReputationDelta: 0,
          teamMoraleDelta: -1.0,
          tacticalSurpriseBonusPercent: 0.22,
          expectedMediaReaction: 'Blef doskonały: peleton uwierzył w bierność, idealne warunki do ataku z zaskoczenia!',
        ),
        _createOption(
          id: 'opt_comeback_aggressive',
          tone: PressAnswerTone.aggressiveConfidence,
          answerText: '„Kolarstwo to pasja i odwaga! Nie mamy nic do stracenia – podpalimy wyścig na pierwszym wzniesieniu!”',
          riderPressureDelta: 16,
          sponsorSatisfactionDelta: 6.0,
          rivalAlertnessMultiplier: 1.40,
          managerReputationDelta: 3,
          teamMoraleDelta: 8.0,
          expectedMediaReaction: 'Entuzjazm kibiców sięga zenitu: „Romantyczne kolarstwo powraca! Przygotujcie się na fajerwerki!”',
        ),
        _createOption(
          id: 'opt_comeback_diplomatic',
          tone: PressAnswerTone.diplomaticShield,
          answerText: '„Taktyka wymaga chłodnej głowy. Zaatakujemy wtedy, gdy będzie to miało uzasadnienie matematyczne, '
              'a nie pod wpływem emocji.”',
          riderPressureDelta: -6,
          sponsorSatisfactionDelta: 1.0,
          rivalAlertnessMultiplier: 1.00,
          managerReputationDelta: 2,
          teamMoraleDelta: 2.0,
          expectedMediaReaction: 'Rzeczowy profesjonalizm: menedżer studzi emocje hiszpańskich mediów.',
        ),
        _createOption(
          id: 'opt_comeback_deflection',
          tone: PressAnswerTone.pressureDeflection,
          answerText: '„Zapytajcie inne ekipy z czołówki, czy zamierzają wieźć lidera wyścigu w fotelu. '
              'To nie my musimy samotnie odrabiać straty.”',
          riderPressureDelta: -8,
          sponsorSatisfactionDelta: 0.0,
          rivalAlertnessMultiplier: 0.88,
          managerReputationDelta: 1,
          teamMoraleDelta: 3.0,
          expectedMediaReaction: 'Próba zawiązania taktycznego sojuszu medialnego z innymi poszkodowanymi ekipami.',
        ),
      ],
    );
  }

  static PressConferenceQuestion _buildCrashDamageHealthQuestion(
    TourRace race,
    Rider rider,
  ) {
    return PressConferenceQuestion(
      id: 'q_post_crash_health',
      outlet: MediaOutlet.cyclingnews,
      topic: QuestionTopic.crashDamageAndPainManagement,
      contextDescription: 'Briefing medyczny pod drzwiami szpitala polowego po kraksie przy prędkości 60 km/h.',
      questionText: 'Stephen Farrand (Cyclingnews): „Lekarz wyścigu opatrywał ${rider.fullName} przez kwadrans. '
          'Głębokie szlify, stłuczone biodro. Czy nie ma pęknięć kości i czy kolarz jest w stanie kontynuować rywalizację?”',
      options: [
        _createOption(
          id: 'opt_crash_bluff',
          tone: PressAnswerTone.tacticalBluff,
          answerText: '„Badania RTG nie wykazały złamań, ale ból jest paraliżujący. Lider ledwo wchodzi po schodach do autokaru. '
              'Jutro celem jest tylko przejechanie etapu w limicie czasu.”',
          riderPressureDelta: -15,
          sponsorSatisfactionDelta: -3.0,
          rivalAlertnessMultiplier: 0.60, // Rywale całkowicie go ignorują!
          managerReputationDelta: 0,
          teamMoraleDelta: -2.0,
          tacticalSurpriseBonusPercent: 0.25,
          expectedMediaReaction: 'Rywale przekonani o niemocy lidera: „To cud, jeśli utrzyma się w peletonie.”',
        ),
        _createOption(
          id: 'opt_crash_aggressive',
          tone: PressAnswerTone.aggressiveConfidence,
          answerText: '„Kolarze są zrobieni ze stali. Kawałek zdartej skóry nie zatrzyma ${rider.fullName}! '
              'Jutro ból zamieni się w sportową złość na trasie!”',
          riderPressureDelta: 12,
          sponsorSatisfactionDelta: 5.0,
          rivalAlertnessMultiplier: 1.20,
          managerReputationDelta: 3,
          teamMoraleDelta: 7.0,
          expectedMediaReaction: 'Kult twardości peletonu: media podziwiają heroizm i niezłomny charakter lidera.',
        ),
        _createOption(
          id: 'opt_crash_diplomatic',
          tone: PressAnswerTone.diplomaticShield,
          answerText: '„Zdrowie i bezpieczeństwo zawodnika są zawsze na pierwszym miejscu. Nocna fizjoterapia '
              'oraz poranna ocena lekarza klubowego zdecydują o ostatecznym starcie.”',
          riderPressureDelta: -10,
          sponsorSatisfactionDelta: 2.0,
          rivalAlertnessMultiplier: 0.90,
          managerReputationDelta: 3,
          teamMoraleDelta: 3.0,
          expectedMediaReaction: 'Medyczna odpowiedzialność i dbałość o człowieka spotyka się z szacunkiem komentatorów.',
        ),
        _createOption(
          id: 'opt_crash_deflection',
          tone: PressAnswerTone.pressureDeflection,
          answerText: '„Kraksa była wynikiem nieodpowiedzialnego zachowania kibica z telefonem i wąskiej barierki. '
              'Oczekujemy od sędziów UCI wyciągnięcia natychmiastowych wniosków.”',
          riderPressureDelta: -8,
          sponsorSatisfactionDelta: 1.0,
          rivalAlertnessMultiplier: 1.00,
          managerReputationDelta: 1,
          teamMoraleDelta: 4.0,
          expectedMediaReaction: 'Menedżer przenosi uwagę na kwestię bezpieczeństwa tras, odciążając psychicznie zawodnika.',
        ),
      ],
    );
  }

  static PressConferenceQuestion _buildContinueRaceOrWithdrawQuestion(
    TourRace race,
    Rider rider,
  ) {
    return PressConferenceQuestion(
      id: 'q_post_crash_decision',
      outlet: MediaOutlet.lequipe,
      topic: QuestionTopic.crashDamageAndPainManagement,
      contextDescription: 'Dziennikarze drążą kwestię rezygnacji z Grand Touru na rzecz odpoczynku pod Vueltę.',
      questionText: 'Philippe Brunel (L\'Équipe): „Czy w obliczu obrażeń nie rozsądniej byłoby wycofać lidera i ocalić resztę sezonu?”',
      options: [
        _createOption(
          id: 'opt_decision_bluff',
          tone: PressAnswerTone.tacticalBluff,
          answerText: '„Poważnie to rozważamy. Dajemy sobie czas do rana. Jeśli ból nie ustąpi, wóz techniczny zabierze go z trasy.”',
          riderPressureDelta: -14,
          sponsorSatisfactionDelta: -4.0,
          rivalAlertnessMultiplier: 0.65,
          managerReputationDelta: 0,
          teamMoraleDelta: -3.0,
          tacticalSurpriseBonusPercent: 0.20,
          expectedMediaReaction: 'Peleton przekonany o rychłym wycofaniu: rywale przestają delegować pomocników do pilnowania.',
        ),
        _createOption(
          id: 'opt_decision_aggressive',
          tone: PressAnswerTone.aggressiveConfidence,
          answerText: '„Nigdy się nie poddajemy! Dopóki kolarz ma dwie nogi i kierownicę w dłoniach, walczymy o podium!”',
          riderPressureDelta: 15,
          sponsorSatisfactionDelta: 6.0,
          rivalAlertnessMultiplier: 1.30,
          managerReputationDelta: 3,
          teamMoraleDelta: 8.0,
          expectedMediaReaction: 'Niezłomny duch walki budzi zachwyt kibiców i dumę sponsorów tytularnych.',
        ),
        _createOption(
          id: 'opt_decision_diplomatic',
          tone: PressAnswerTone.diplomaticShield,
          answerText: '„Decyzję podejmiemy w porozumieniu ze sztabem medycznym po śniadaniu. Zaufajcie naszej ekspertyzie.”',
          riderPressureDelta: -6,
          sponsorSatisfactionDelta: 2.0,
          rivalAlertnessMultiplier: 0.95,
          managerReputationDelta: 2,
          teamMoraleDelta: 2.0,
          expectedMediaReaction: 'Chłodny profesjonalizm zamyka spekulacje prasowe do kolejnego komunikatu.',
        ),
        _createOption(
          id: 'opt_decision_deflection',
          tone: PressAnswerTone.pressureDeflection,
          answerText: '„Nawet potłuczony ${rider.fullName} jest groźniejszy dla rywali niż większość zdrowego peletonu.”',
          riderPressureDelta: -4,
          sponsorSatisfactionDelta: 4.0,
          rivalAlertnessMultiplier: 1.15,
          managerReputationDelta: 2,
          teamMoraleDelta: 6.0,
          expectedMediaReaction: 'Brawurowa deklaracja: menedżer buduje mit herosa wokół cierpiącego kolarza.',
        ),
      ],
    );
  }

  static PressConferenceQuestion _buildQueenStageAttackIntentQuestion(
    TourRace race,
    RaceStage? stage,
    Rider rider,
    String rivalName,
  ) {
    return PressConferenceQuestion(
      id: 'q_queen_stage_attack',
      outlet: MediaOutlet.gazzetta,
      topic: QuestionTopic.mountainTacticsAndPacing,
      contextDescription: 'Wieczorna odprawa przed Królewskim Etapem w Alpach (3 przełęcze HC, w tym Col du Galibier i Alpe d\'Huez).',
      questionText: 'Ciro Scognamiglio (La Gazzetta dello Sport): „Jutro dzień prawdy. Ponad 4500 metrów przewyższenia. '
          'Czy Wasza drużyna wyśle pomocników do wczesnej ucieczki, by przygotować daleki atak ${rider.fullName}?”',
      options: [
        _createOption(
          id: 'opt_queen_bluff',
          tone: PressAnswerTone.tacticalBluff,
          answerText: '„Zupełnie nie. Zamierzamy jechać skrajnie defensywnie i oszczędzać siły. '
              'Żadnych szalonych ataków, celem jest dojechanie w grupie faworytów.”',
          riderPressureDelta: -12,
          sponsorSatisfactionDelta: -2.0,
          rivalAlertnessMultiplier: 0.65, // Potężny blef! Rywale nie pilnują wczesnych ucieczek
          managerReputationDelta: 1,
          teamMoraleDelta: 0.0,
          tacticalSurpriseBonusPercent: 0.25, // +25% do sukcesu ataku z daleka!
          expectedMediaReaction: 'Rywale uśpieni blefem menedżera: „Będą jechać defensywnie, możemy odpuścić ucieczkę.”',
        ),
        _createOption(
          id: 'opt_queen_aggressive',
          tone: PressAnswerTone.aggressiveConfidence,
          answerText: '„Od kilometra zero narzucimy mordercze tempo. Nasi pomocnicy zamienią ten etap w piekło, '
              'a ${rider.fullName} zada ostateczny cios na Galibier!”',
          riderPressureDelta: 18,
          sponsorSatisfactionDelta: 7.0,
          rivalAlertnessMultiplier: 1.45, // Rywale w pełnym pogotowiu
          managerReputationDelta: 4,
          teamMoraleDelta: 9.0,
          expectedMediaReaction: 'Zapowiedź trzęsienia ziemi w Alpach! Rywale wysyłają dodatkowe wsparcie na czoło peletonu.',
        ),
        _createOption(
          id: 'opt_queen_diplomatic',
          tone: PressAnswerTone.diplomaticShield,
          answerText: '„Pogoda i wiatr na przełęczach powyżej 2000 metrów zadecydują o taktyce. '
              'Dostosujemy plan do rozwoju wydarzeń na trasie.”',
          riderPressureDelta: -4,
          sponsorSatisfactionDelta: 2.0,
          rivalAlertnessMultiplier: 1.00,
          managerReputationDelta: 2,
          teamMoraleDelta: 3.0,
          expectedMediaReaction: 'Sztab nie odkrywa kart, utrzymując rywali w zdrowej niepewności.',
        ),
        _createOption(
          id: 'opt_queen_deflection',
          tone: PressAnswerTone.pressureDeflection,
          answerText: '„Ciężar prowadzenia etapu spoczywa na drużynie $rivalName. Jeśli chcą wygrać ten Tour, '
              'to oni muszą nadawać tempo przez 180 kilometrów.”',
          riderPressureDelta: -10,
          sponsorSatisfactionDelta: 2.0,
          rivalAlertnessMultiplier: 0.85,
          managerReputationDelta: 2,
          teamMoraleDelta: 4.0,
          expectedMediaReaction: 'Zręczne przerzucenie odpowiedzialności taktycznej na liderów wyścigu.',
        ),
      ],
    );
  }

  static PressConferenceQuestion _buildMountainPacingBluffQuestion(
    TourRace race,
    Rider rider,
  ) {
    return PressConferenceQuestion(
      id: 'q_queen_stage_pacing',
      outlet: MediaOutlet.wielerflits,
      topic: QuestionTopic.mountainTacticsAndPacing,
      contextDescription: 'Pytania o dobór przełożeń i pacing watów na wysokości 2600m n.p.m.',
      questionText: 'Raymond Kerckhoffs (WielerFlits): „Czy rozrzedzone powietrze na wysokości powyżej 2000 metrów '
          'nie odbije się negatywnie na dyspozycji ${rider.fullName}?”',
      options: [
        _createOption(
          id: 'opt_altitude_bluff',
          tone: PressAnswerTone.tacticalBluff,
          answerText: '„Niestety, dane z obozu na Teide pokazały, że ${rider.fullName} ma problemy z saturacją tlenową powyżej 2200m. '
              'Na Galibier będziemy jechać na przetrwanie.”',
          riderPressureDelta: -14,
          sponsorSatisfactionDelta: -3.0,
          rivalAlertnessMultiplier: 0.68,
          managerReputationDelta: 0,
          teamMoraleDelta: -2.0,
          tacticalSurpriseBonusPercent: 0.20,
          expectedMediaReaction: 'Rywale notują informację o problemach tlenowych: planują atak na szczycie, nie spodziewając się kontry!',
        ),
        _createOption(
          id: 'opt_altitude_aggressive',
          tone: PressAnswerTone.aggressiveConfidence,
          answerText: '„Spędziliśmy trzy tygodnie w Sierra Nevada i na Teide. Wysokość to nasz dom. '
              'Im wyżej jedziemy, tym słabiej oddychają nasi rywale!”',
          riderPressureDelta: 14,
          sponsorSatisfactionDelta: 5.0,
          rivalAlertnessMultiplier: 1.35,
          managerReputationDelta: 3,
          teamMoraleDelta: 7.0,
          expectedMediaReaction: 'Pewność siebie imponuje mediom: rywale zmuszeni do asekuracyjnej jazdy w wysokich partiach gór.',
        ),
        _createOption(
          id: 'opt_altitude_diplomatic',
          tone: PressAnswerTone.diplomaticShield,
          answerText: '„Fizjologii nie oszukasz, rozrzedzone powietrze dotyka każdego kolarza. '
              'Kluczem będzie rygorystyczny dowóz węglowodanów i bidonów.”',
          riderPressureDelta: -6,
          sponsorSatisfactionDelta: 3.0,
          rivalAlertnessMultiplier: 1.00,
          managerReputationDelta: 2,
          teamMoraleDelta: 3.0,
          expectedMediaReaction: 'Fizjologiczny pragmatyzm i profesjonalizm sztabu.',
        ),
        _createOption(
          id: 'opt_altitude_deflection',
          tone: PressAnswerTone.pressureDeflection,
          answerText: '„Większość peletonu cierpi na wysokości znacznie bardziej niż my. '
              'Zobaczycie jutro, jak wielu faworytów straci minuty przed szczytem.”',
          riderPressureDelta: -8,
          sponsorSatisfactionDelta: 3.0,
          rivalAlertnessMultiplier: 0.90,
          managerReputationDelta: 2,
          teamMoraleDelta: 5.0,
          expectedMediaReaction: 'Przeniesienie wątpliwości na rywali wywołuje nerwowość w obozach przeciwników.',
        ),
      ],
    );
  }

  static PressConferenceQuestion _buildTransferRumorQuestion(
    TourRace race,
    Rider rider,
  ) {
    return PressConferenceQuestion(
      id: 'q_transfer_rumors',
      outlet: MediaOutlet.marca,
      topic: QuestionTopic.transferRumorsAndContract,
      contextDescription: 'Okienko transferowe. W mediach huczy o astronomicznej ofercie dla Waszego kolarza z konkurencyjnej stajni.',
      questionText: 'Nacho Labarga (Marca): „Podobno szejkowie z konkurencyjnego zespołu oferują ${rider.fullName} 6 milionów euro rocznie. '
          'Czy Wasz klub jest w stanie utrzymać lidera na kolejny sezon?”',
      options: [
        _createOption(
          id: 'opt_trans_bluff',
          tone: PressAnswerTone.tacticalBluff,
          answerText: '„Pieniądze to nie wszystko, ale rynek jest bezlitosny. Nie wykluczamy, że to ostatni wielki wyścig '
              '${rider.fullName} w naszych barwach.”',
          riderPressureDelta: -6,
          sponsorSatisfactionDelta: -5.0,
          rivalAlertnessMultiplier: 0.85,
          managerReputationDelta: -1,
          teamMoraleDelta: -4.0,
          expectedMediaReaction: 'Niepokój sponsorów i kibiców: spekulacje o transferze przykrywają sportowy wymiar wyścigu.',
        ),
        _createOption(
          id: 'opt_trans_aggressive',
          tone: PressAnswerTone.aggressiveConfidence,
          answerText: '„${rider.fullName} jest fundamentem naszego projektu. Żadne petrodolary go stąd nie wyciągną – '
              'budujemy wokół niego potęgę na lata!”',
          riderPressureDelta: 8,
          sponsorSatisfactionDelta: 7.0,
          rivalAlertnessMultiplier: 1.10,
          managerReputationDelta: 4,
          teamMoraleDelta: 8.0,
          expectedMediaReaction: 'Twarde stanowisko menedżera: sponsorzy zachwyceni lojalnością i wizją wielkiego klubu.',
        ),
        _createOption(
          id: 'opt_trans_diplomatic',
          tone: PressAnswerTone.diplomaticShield,
          answerText: '„Jesteśmy w trakcie wyścigu i skupiamy się wyłącznie na szosie. O kontraktach porozmawiamy '
              'przy kawie po sezonie.”',
          riderPressureDelta: -8,
          sponsorSatisfactionDelta: 2.0,
          rivalAlertnessMultiplier: 1.00,
          managerReputationDelta: 2,
          teamMoraleDelta: 2.0,
          expectedMediaReaction: 'Ucięcie plotek medialnych w zarodku pozwala zawodnikowi skupić się na ściganiu.',
        ),
        _createOption(
          id: 'opt_trans_deflection',
          tone: PressAnswerTone.pressureDeflection,
          answerText: '„Takie plotki zawsze wypuszcza konkurencja, by zdestabilizować naszą ekipę przed decydującymi etapami. '
              'Nie damy się wciągnąć w te gierki.”',
          riderPressureDelta: -10,
          sponsorSatisfactionDelta: 3.0,
          rivalAlertnessMultiplier: 0.95,
          managerReputationDelta: 3,
          teamMoraleDelta: 5.0,
          expectedMediaReaction: 'Menedżer demaskuje wojnę psychologiczną rywali, wzmacniając morale zespołu.',
        ),
      ],
    );
  }

  static PressConferenceQuestion _buildIntraTeamFeudQuestion(
    TourRace race,
    Rider rider,
  ) {
    return PressConferenceQuestion(
      id: 'q_feud_scandal',
      outlet: MediaOutlet.lequipe,
      topic: QuestionTopic.dualLeaderDynamicAndHierarchy,
      contextDescription: 'Afera po etapie. Kamery telewizyjne zarejestrowały wymianę ostrych słów i pretensji między dwoma kolarzami zespołu.',
      questionText: 'Philippe Brunel (L\'Équipe): „Menedżerze, w zespole wrze! Drugi lider odmówił zjazdu po bidony i zaatakował na podjeździe. '
          'Kto tak naprawdę dowodzi w Waszej drużynie?”',
      options: [
        _createOption(
          id: 'opt_feud_bluff',
          tone: PressAnswerTone.tacticalBluff,
          answerText: '„To była nasza zaplanowana dezinformacja! Celowo udawaliśmy konflikt w radiu, '
              'by sprowokować rywali do błędu taktycznego.”',
          riderPressureDelta: -8,
          sponsorSatisfactionDelta: 1.0,
          rivalAlertnessMultiplier: 0.80,
          managerReputationDelta: 2,
          teamMoraleDelta: 3.0,
          tacticalSurpriseBonusPercent: 0.15,
          expectedMediaReaction: 'Mistrzowska manipulacja PR: media zdezorientowane, afera zneutralizowana jako „gra taktyczna”.',
        ),
        _createOption(
          id: 'opt_feud_aggressive',
          tone: PressAnswerTone.aggressiveConfidence,
          answerText: '„Jedynym liderem jest ${rider.fullName} i każdy, kto tego nie rozumie, wyleci z zespołu na zbity pysk. '
              'Hierarchia jest święta!”',
          riderPressureDelta: 15,
          sponsorSatisfactionDelta: 4.0,
          rivalAlertnessMultiplier: 1.15,
          managerReputationDelta: 2,
          teamMoraleDelta: -4.0,
          expectedMediaReaction: 'Żelazna ręka menedżera: buntownicy spacyfikowani, choć w zespole rośnie napięcie podskórne.',
        ),
        _createOption(
          id: 'opt_feud_diplomatic',
          tone: PressAnswerTone.diplomaticShield,
          answerText: '„Kolarstwo to sport potężnych emocji i tętna 190 uderzeń na minutę. Wyjaśniliśmy sobie wszystko '
              'przy kolacji jak dorośli faceci. Drużyna jest zjednoczona.”',
          riderPressureDelta: -10,
          sponsorSatisfactionDelta: 4.0,
          rivalAlertnessMultiplier: 1.00,
          managerReputationDelta: 3,
          teamMoraleDelta: 5.0,
          expectedMediaReaction: 'Pożar ugaszony w zarodku. Sponsorzy odetchnęli z ulgą, widząc klasę i opanowanie sztabu.',
        ),
        _createOption(
          id: 'opt_feud_deflection',
          tone: PressAnswerTone.pressureDeflection,
          answerText: '„Lepiej mieć dwóch zwycięzców z charakterem niż ośmiu grzecznych kolarzy bez ambicji. '
              'Rywale mają większy problem z nami niż my sami ze sobą.”',
          riderPressureDelta: -5,
          sponsorSatisfactionDelta: 2.0,
          rivalAlertnessMultiplier: 1.10,
          managerReputationDelta: 3,
          teamMoraleDelta: 6.0,
          expectedMediaReaction: 'Błyskotliwe przekucie kryzysu w atut siły: „Dwa lwy w jednej klatce, ale pożrą rywali!”',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PODSUMOWANIE KONFERENCJI I APLIKACJA SKUTKÓW
  // ---------------------------------------------------------------------------

  /// Podsumowuje wybory gracza, wylicza skumulowane konsekwencje i zwraca raport końcowy.
  static PressConferenceResult processCompletedConference({
    required PressConferenceSession session,
    required Map<String, String> chosenOptionIdsByQuestionId,
    required CyclingTeam team,
    math.Random? rng,
  }) {
    final chosenOptions = <String, PressConferenceAnswerOption>{};
    int totalPressure = 0;
    double totalSponsorSat = 0.0;
    double alertnessProduct = 1.0;
    double totalSurpriseBonus = 0.0;
    int totalRep = 0;
    double totalMorale = 0.0;

    for (final q in session.questions) {
      final chosenId = chosenOptionIdsByQuestionId[q.id];
      final option = q.options.firstWhere(
        (o) => o.id == chosenId,
        orElse: () => q.options.first,
      );

      chosenOptions[q.id] = option;
      totalPressure += option.riderPressureDelta;
      totalSponsorSat += option.sponsorSatisfactionDelta;
      alertnessProduct *= option.rivalAlertnessMultiplier;
      totalSurpriseBonus += option.tacticalSurpriseBonusPercent;
      totalRep += option.managerReputationDelta;
      totalMorale += option.teamMoraleDelta;
    }

    // Uśrednienie / normalizacja wskaźnika czujności rywali
    final double effectiveRivalAlertness = (alertnessProduct).clamp(0.50, 1.80);
    final double effectiveSurpriseBonus = totalSurpriseBonus.clamp(0.0, 0.40);

    // Nagłówki gazet w zależności od dominującego tonu
    final headlines = <String>[];
    for (final opt in chosenOptions.values) {
      headlines.add(opt.expectedMediaReaction);
    }

    final summary = 'Konferencja prasowa zakończona. '
        'Wypowiedzi menedżera wywołały następujące echo: '
        'Zmiana presji psychicznej: ${totalPressure > 0 ? "+$totalPressure" : "$totalPressure"} pkt. '
        'Wpływ na sponsorów: ${totalSponsorSat > 0 ? "+${totalSponsorSat.toStringAsFixed(1)}" : totalSponsorSat.toStringAsFixed(1)} pkt. '
        'Wskaźnik czujności rywali AI: ${effectiveRivalAlertness.toStringAsFixed(2)}x '
        '(${effectiveRivalAlertness < 0.90 ? "Rywale uśpieni blefem!" : (effectiveRivalAlertness > 1.20 ? "Rywale w pełnym alercie!" : "Standardowa czujność")}).';

    return PressConferenceResult(
      session: session,
      chosenAnswers: chosenOptions,
      totalRiderPressureDelta: totalPressure,
      totalSponsorSatisfactionDelta: totalSponsorSat,
      rivalAlertnessFactor: effectiveRivalAlertness,
      tacticalSurpriseBonusPercent: effectiveSurpriseBonus,
      totalManagerReputationDelta: totalRep,
      totalTeamMoraleDelta: totalMorale,
      mediaSummaryReport: summary,
      frontPageHeadlines: headlines,
    );
  }

  /// Aktualizuje stan drużyny [`CyclingTeam`] na podstawie wyników konferencji prasowej.
  static CyclingTeam applyConferenceImpactToTeam({
    required CyclingTeam team,
    required PressConferenceResult result,
  }) {
    // 1. Zmiana satysfakcji sponsorów
    final updatedSponsors = team.sponsors.map((s) {
      final newSat = (s.sponsorSatisfaction + result.totalSponsorSatisfactionDelta).clamp(5.0, 100.0);
      return s.copyWith(sponsorSatisfaction: newSat);
    }).toList();

    return team.copyWith(
      sponsors: updatedSponsors,
    );
  }

  /// Wylicza modyfikator sukcesu ataku dalekiego zasięgu (Long-range attack)
  /// w silniku symulacji etapu na podstawie blefu w mediach.
  static double calculateLongRangeAttackSuccessFactor(double rivalAlertnessFactor) {
    if (rivalAlertnessFactor <= 0.0) return 1.0;
    // Jeśli czujność wynosi 0.70x, szansa powodzenia rośnie do 1.42x
    return (1.0 / rivalAlertnessFactor).clamp(0.60, 1.65);
  }
}
