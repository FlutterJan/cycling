import 'dart:math' as math;

import 'peloton_chase_ai_controller.dart';

/// Poziom reakcji kryzysowej drużyny lidera GC na skład ucieczki dnia.
enum GcPanicReactionLevel {
  /// Brak zagrożenia GC w ucieczce (wszyscy uciekinierzy >= 4 min lub brak ucieczki).
  none,

  /// Uciekinier w strefie obserwacji (np. strata 4–6 min), bez pełnego alarmu.
  monitoring,

  /// Alarm kryzysowy (< 4 min straty GC): 4 pomocników na czoło, tempo 88% FTP.
  panicPursuit,

  /// Krytyczne zagrożenie wirtualną koszulką lidera (przewaga ucieczki > strata GC).
  virtualLeaderEmergency;

  String toJson() => name;

  static GcPanicReactionLevel fromJson(String value) {
    return GcPanicReactionLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GcPanicReactionLevel.none,
    );
  }

  String get label {
    switch (this) {
      case GcPanicReactionLevel.none:
        return 'Brak zagrożenia GC';
      case GcPanicReactionLevel.monitoring:
        return 'Obserwacja GC';
      case GcPanicReactionLevel.panicPursuit:
        return 'Alarm GC (4 pomocników • 88% FTP)';
      case GcPanicReactionLevel.virtualLeaderEmergency:
        return 'Wirtualny lider w ucieczce!';
    }
  }
}

/// Kandydat z ucieczki dnia oceniany pod kątem zagrożenia w klasyfikacji generalnej.
class BreakawayGcThreatCandidate {
  final String riderId;
  final String riderName;
  final String teamId;
  final String teamName;

  /// Strata kolarza w klasyfikacji generalnej (GC) w sekundach [s].
  /// Wartość < 240.0 s (< 4 min) uruchamia próg paniki, jeśli kolarz jest groźny.
  final double gcDeficitSeconds;

  /// Aktualna pozycja kolarza w klasyfikacji generalnej.
  final int gcRank;

  /// Czy kolarz jest realnym zagrożeniem dla GC (forma, profil górski/czasówka).
  final bool isDangerousContender;

  const BreakawayGcThreatCandidate({
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.teamName,
    required this.gcDeficitSeconds,
    this.gcRank = 10,
    this.isDangerousContender = true,
  });

  BreakawayGcThreatCandidate copyWith({
    String? riderId,
    String? riderName,
    String? teamId,
    String? teamName,
    double? gcDeficitSeconds,
    int? gcRank,
    bool? isDangerousContender,
  }) {
    return BreakawayGcThreatCandidate(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      gcDeficitSeconds: gcDeficitSeconds ?? this.gcDeficitSeconds,
      gcRank: gcRank ?? this.gcRank,
      isDangerousContender: isDangerousContender ?? this.isDangerousContender,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'teamId': teamId,
      'teamName': teamName,
      'gcDeficitSeconds': gcDeficitSeconds,
      'gcRank': gcRank,
      'isDangerousContender': isDangerousContender,
    };
  }

  factory BreakawayGcThreatCandidate.fromJson(Map<String, dynamic> json) {
    return BreakawayGcThreatCandidate(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      gcDeficitSeconds: (json['gcDeficitSeconds'] as num).toDouble(),
      gcRank: (json['gcRank'] as num?)?.toInt() ?? 10,
      isDangerousContender: json['isDangerousContender'] as bool? ?? true,
    );
  }
}

/// Pomocnik drużyny lidera dostępny w peletonie do natychmiastowej pracy na czele.
class PelotonDomestiqueCandidate {
  final String riderId;
  final String riderName;
  final int ftpWatts;

  /// Poziom zmęczenia (0.0 = wypoczęty, 1.0 = skrajnie wyczerpany).
  final double currentFatigueRatio;

  /// Czy kolarz jest chronionym liderem GC (nie jest wysyłany do ciągnięcia).
  final bool isGcLeader;

  /// Czy kolarz znajduje się aktualnie w peletonie i może wyjść na czoło.
  final bool isAvailableInPeloton;

  const PelotonDomestiqueCandidate({
    required this.riderId,
    required this.riderName,
    required this.ftpWatts,
    this.currentFatigueRatio = 0.2,
    this.isGcLeader = false,
    this.isAvailableInPeloton = true,
  });

  PelotonDomestiqueCandidate copyWith({
    String? riderId,
    String? riderName,
    int? ftpWatts,
    double? currentFatigueRatio,
    bool? isGcLeader,
    bool? isAvailableInPeloton,
  }) {
    return PelotonDomestiqueCandidate(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      ftpWatts: ftpWatts ?? this.ftpWatts,
      currentFatigueRatio: currentFatigueRatio ?? this.currentFatigueRatio,
      isGcLeader: isGcLeader ?? this.isGcLeader,
      isAvailableInPeloton: isAvailableInPeloton ?? this.isAvailableInPeloton,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'ftpWatts': ftpWatts,
      'currentFatigueRatio': currentFatigueRatio,
      'isGcLeader': isGcLeader,
      'isAvailableInPeloton': isAvailableInPeloton,
    };
  }

  factory PelotonDomestiqueCandidate.fromJson(Map<String, dynamic> json) {
    return PelotonDomestiqueCandidate(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      ftpWatts: (json['ftpWatts'] as num).toInt(),
      currentFatigueRatio:
          (json['currentFatigueRatio'] as num?)?.toDouble() ?? 0.2,
      isGcLeader: json['isGcLeader'] as bool? ?? false,
      isAvailableInPeloton: json['isAvailableInPeloton'] as bool? ?? true,
    );
  }
}

/// Dane wejściowe dla systemu reakcji kryzysowej AI na zagrożenie GC w ucieczce.
class GcPanicThresholdInput {
  final String leaderTeamId;
  final String leaderTeamName;
  final String gcLeaderRiderId;

  /// Aktualna przewaga ucieczki dnia nad peletonem w sekundach [s].
  final double breakawayGapSeconds;

  /// Bazowe tempo peletonu przed alarmem jako ułamek FTP (np. 0.72).
  final double baselinePelotonFtpRatio;

  /// Lista kolarzy jadących aktualnie w ucieczce dnia.
  final List<BreakawayGcThreatCandidate> breakawayCandidates;

  /// Lista kolarzy drużyny lidera (pomocnicy i lider) w peletonie.
  final List<PelotonDomestiqueCandidate> leaderTeamDomestiques;

  /// Aktualny kilometr etapu [km].
  final double currentKm;

  /// Całkowity dystans etapu [km].
  final double stageDistanceKm;

  /// Czy etap jest jazdą na czas (ITT/TTT) – wtedy system nie działa.
  final bool isTimeTrial;

  const GcPanicThresholdInput({
    required this.leaderTeamId,
    required this.leaderTeamName,
    required this.gcLeaderRiderId,
    required this.breakawayGapSeconds,
    this.baselinePelotonFtpRatio =
        GcTimeGapPanicThresholdAi.defaultBaselineFtpRatio,
    required this.breakawayCandidates,
    required this.leaderTeamDomestiques,
    this.currentKm = 0.0,
    this.stageDistanceKm = 180.0,
    this.isTimeTrial = false,
  });

  GcPanicThresholdInput copyWith({
    String? leaderTeamId,
    String? leaderTeamName,
    String? gcLeaderRiderId,
    double? breakawayGapSeconds,
    double? baselinePelotonFtpRatio,
    List<BreakawayGcThreatCandidate>? breakawayCandidates,
    List<PelotonDomestiqueCandidate>? leaderTeamDomestiques,
    double? currentKm,
    double? stageDistanceKm,
    bool? isTimeTrial,
  }) {
    return GcPanicThresholdInput(
      leaderTeamId: leaderTeamId ?? this.leaderTeamId,
      leaderTeamName: leaderTeamName ?? this.leaderTeamName,
      gcLeaderRiderId: gcLeaderRiderId ?? this.gcLeaderRiderId,
      breakawayGapSeconds: breakawayGapSeconds ?? this.breakawayGapSeconds,
      baselinePelotonFtpRatio:
          baselinePelotonFtpRatio ?? this.baselinePelotonFtpRatio,
      breakawayCandidates: breakawayCandidates ?? this.breakawayCandidates,
      leaderTeamDomestiques:
          leaderTeamDomestiques ?? this.leaderTeamDomestiques,
      currentKm: currentKm ?? this.currentKm,
      stageDistanceKm: stageDistanceKm ?? this.stageDistanceKm,
      isTimeTrial: isTimeTrial ?? this.isTimeTrial,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leaderTeamId': leaderTeamId,
      'leaderTeamName': leaderTeamName,
      'gcLeaderRiderId': gcLeaderRiderId,
      'breakawayGapSeconds': breakawayGapSeconds,
      'baselinePelotonFtpRatio': baselinePelotonFtpRatio,
      'breakawayCandidates':
          breakawayCandidates.map((e) => e.toJson()).toList(),
      'leaderTeamDomestiques':
          leaderTeamDomestiques.map((e) => e.toJson()).toList(),
      'currentKm': currentKm,
      'stageDistanceKm': stageDistanceKm,
      'isTimeTrial': isTimeTrial,
    };
  }

  factory GcPanicThresholdInput.fromJson(Map<String, dynamic> json) {
    return GcPanicThresholdInput(
      leaderTeamId: json['leaderTeamId'] as String,
      leaderTeamName: json['leaderTeamName'] as String,
      gcLeaderRiderId: json['gcLeaderRiderId'] as String,
      breakawayGapSeconds: (json['breakawayGapSeconds'] as num).toDouble(),
      baselinePelotonFtpRatio:
          (json['baselinePelotonFtpRatio'] as num?)?.toDouble() ??
              GcTimeGapPanicThresholdAi.defaultBaselineFtpRatio,
      breakawayCandidates: (json['breakawayCandidates'] as List<dynamic>)
          .map((e) =>
              BreakawayGcThreatCandidate.fromJson(e as Map<String, dynamic>))
          .toList(),
      leaderTeamDomestiques: (json['leaderTeamDomestiques'] as List<dynamic>)
          .map((e) =>
              PelotonDomestiqueCandidate.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentKm: (json['currentKm'] as num?)?.toDouble() ?? 0.0,
      stageDistanceKm: (json['stageDistanceKm'] as num?)?.toDouble() ?? 180.0,
      isTimeTrial: json['isTimeTrial'] as bool? ?? false,
    );
  }
}

/// Wynik decyzji systemu reakcji kryzysowej AI na zagrożenie GC.
class GcPanicReactionDecision {
  final GcPanicReactionLevel reactionLevel;
  final bool isPanicTriggered;

  /// Liczba pomocników natychmiast wystawionych na czoło peletonu (docelowo 4).
  final int deployedDomestiquesCount;

  /// Identyfikatory pomocników oddelegowanych na czoło peletonu.
  final List<String> deployedDomestiqueIds;

  /// Nazwiska pomocników oddelegowanych na czoło peletonu.
  final List<String> deployedDomestiqueNames;

  /// Docelowe tempo pogoni jako ułamek FTP (0.88 = 88% FTP w stanie paniki).
  final double targetChaseFtpRatio;

  /// Średnia docelowa moc na pomocnika w watach [W].
  final int targetWattsPerDomestique;

  /// Najgroźniejszy kolarz z ucieczki, który uruchomił alarm.
  final BreakawayGcThreatCandidate? mostDangerousRider;

  /// Wszyscy groźni kolarze ze stratą < 4 min w ucieczce.
  final List<BreakawayGcThreatCandidate> allTriggeringThreats;

  /// Czy uciekinier wirtualnie przejął już koszulkę lidera wyścigu.
  final bool isVirtualGcLeaderThreat;

  /// Wirtualna różnica w GC względem lidera [s] (> 0 oznacza wirtualne prowadzenie).
  final double virtualGcLeadSeconds;

  /// Gotowe zobowiązanie pościgowe dla `PelotonChasePlan`.
  final ChaseCommitment? chaseCommitment;

  /// Zalecany poziom pilności pościgu.
  final ChaseUrgency recommendedChaseUrgency;

  /// Komunikat radia wyścigowego dyrektora sportowego.
  final String radioAlertMessage;

  const GcPanicReactionDecision({
    required this.reactionLevel,
    required this.isPanicTriggered,
    required this.deployedDomestiquesCount,
    required this.deployedDomestiqueIds,
    required this.deployedDomestiqueNames,
    required this.targetChaseFtpRatio,
    required this.targetWattsPerDomestique,
    required this.mostDangerousRider,
    required this.allTriggeringThreats,
    required this.isVirtualGcLeaderThreat,
    required this.virtualGcLeadSeconds,
    required this.chaseCommitment,
    required this.recommendedChaseUrgency,
    required this.radioAlertMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'reactionLevel': reactionLevel.toJson(),
      'isPanicTriggered': isPanicTriggered,
      'deployedDomestiquesCount': deployedDomestiquesCount,
      'deployedDomestiqueIds': deployedDomestiqueIds,
      'deployedDomestiqueNames': deployedDomestiqueNames,
      'targetChaseFtpRatio': targetChaseFtpRatio,
      'targetWattsPerDomestique': targetWattsPerDomestique,
      'mostDangerousRider': mostDangerousRider?.toJson(),
      'allTriggeringThreats':
          allTriggeringThreats.map((e) => e.toJson()).toList(),
      'isVirtualGcLeaderThreat': isVirtualGcLeaderThreat,
      'virtualGcLeadSeconds': virtualGcLeadSeconds,
      'chaseCommitment': chaseCommitment?.toJson(),
      'recommendedChaseUrgency': recommendedChaseUrgency.toJson(),
      'radioAlertMessage': radioAlertMessage,
    };
  }

  factory GcPanicReactionDecision.fromJson(Map<String, dynamic> json) {
    return GcPanicReactionDecision(
      reactionLevel:
          GcPanicReactionLevel.fromJson(json['reactionLevel'] as String),
      isPanicTriggered: json['isPanicTriggered'] as bool,
      deployedDomestiquesCount:
          (json['deployedDomestiquesCount'] as num).toInt(),
      deployedDomestiqueIds: (json['deployedDomestiqueIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      deployedDomestiqueNames:
          (json['deployedDomestiqueNames'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      targetChaseFtpRatio: (json['targetChaseFtpRatio'] as num).toDouble(),
      targetWattsPerDomestique:
          (json['targetWattsPerDomestique'] as num).toInt(),
      mostDangerousRider: json['mostDangerousRider'] == null
          ? null
          : BreakawayGcThreatCandidate.fromJson(
              json['mostDangerousRider'] as Map<String, dynamic>,
            ),
      allTriggeringThreats: (json['allTriggeringThreats'] as List<dynamic>)
          .map((e) =>
              BreakawayGcThreatCandidate.fromJson(e as Map<String, dynamic>))
          .toList(),
      isVirtualGcLeaderThreat: json['isVirtualGcLeaderThreat'] as bool,
      virtualGcLeadSeconds: (json['virtualGcLeadSeconds'] as num).toDouble(),
      chaseCommitment: json['chaseCommitment'] == null
          ? null
          : ChaseCommitment.fromJson(
              json['chaseCommitment'] as Map<String, dynamic>,
            ),
      recommendedChaseUrgency:
          ChaseUrgency.fromJson(json['recommendedChaseUrgency'] as String),
      radioAlertMessage: json['radioAlertMessage'] as String,
    );
  }
}

/// System reakcji kryzysowej AI dla obrony klasyfikacji generalnej (GC).
///
/// Jeśli niebezpieczny kolarz ze stratą `< 4 min` (`< 240 s`) w klasyfikacji
/// generalnej zabierze się do ucieczki dnia, drużyna lidera wyścigu natychmiast
/// wystawia 4 pomocników na czoło peletonu i podnosi tempo pogoni do `88% FTP`.
class GcTimeGapPanicThresholdAi {
  /// Próg straty w GC uruchamiający reakcję kryzysową: ściśle < 4 minuty (240 s).
  static const double panicGcDeficitThresholdSeconds = 240.0;

  /// Próg obserwacji w GC (6 minut = 360 s) przed pełną paniką.
  static const double monitoringGcDeficitThresholdSeconds = 360.0;

  /// Liczba pomocników wystawiana natychmiast na czoło peletonu w trybie paniki.
  static const int panicDomestiquesCount = 4;

  /// Docelowe tempo pogoni drużyny lidera w stanie paniki (88% FTP).
  static const double panicChaseFtpRatio = 0.88;

  /// Domyślne spokojne tempo kontrolowanej ucieczki (72% FTP).
  static const double defaultBaselineFtpRatio = 0.72;

  /// Domyślne FTP pomocnika WorldTour przy braku wpisu kadrowego.
  static const int fallbackDomestiqueFtpWatts = 390;

  const GcTimeGapPanicThresholdAi();

  /// Ocenia skład ucieczki dnia i generuje natychmiastową decyzję taktyczną
  /// drużyny lidera wyścigu.
  GcPanicReactionDecision evaluatePanicReaction(GcPanicThresholdInput input) {
    final double safeBaselineFtp =
        input.baselinePelotonFtpRatio.clamp(0.50, 0.87);

    if (input.isTimeTrial ||
        input.breakawayCandidates.isEmpty ||
        input.breakawayGapSeconds <= 0.0) {
      return GcPanicReactionDecision(
        reactionLevel: GcPanicReactionLevel.none,
        isPanicTriggered: false,
        deployedDomestiquesCount: 0,
        deployedDomestiqueIds: const [],
        deployedDomestiqueNames: const [],
        targetChaseFtpRatio: safeBaselineFtp,
        targetWattsPerDomestique:
            (fallbackDomestiqueFtpWatts * safeBaselineFtp).round(),
        mostDangerousRider: null,
        allTriggeringThreats: const [],
        isVirtualGcLeaderThreat: false,
        virtualGcLeadSeconds: 0.0,
        chaseCommitment: null,
        recommendedChaseUrgency: ChaseUrgency.idle,
        radioAlertMessage: input.isTimeTrial
            ? 'Jazda na czas – system kontroli ucieczki nieaktywny.'
            : 'Brak aktywnej ucieczki zagrażającej klasyfikacji generalnej.',
      );
    }

    // Filtrujemy rywali (ignorujemy kolegów z drużyny lidera i samego lidera).
    final List<BreakawayGcThreatCandidate> rivalContenders = input
        .breakawayCandidates
        .where((c) =>
            c.teamId != input.leaderTeamId &&
            c.riderId != input.gcLeaderRiderId &&
            c.isDangerousContender)
        .toList();

    // Kolarze ze stratą ściśle < 4 min (240 s) w GC.
    final List<BreakawayGcThreatCandidate> panicThreats = rivalContenders
        .where((c) => c.gcDeficitSeconds < panicGcDeficitThresholdSeconds)
        .toList()
      ..sort((a, b) => a.gcDeficitSeconds.compareTo(b.gcDeficitSeconds));

    if (panicThreats.isEmpty) {
      // Sprawdź, czy ktoś jest w strefie obserwacji (4-6 min).
      final List<BreakawayGcThreatCandidate> watchList = rivalContenders
          .where(
              (c) => c.gcDeficitSeconds < monitoringGcDeficitThresholdSeconds)
          .toList()
        ..sort((a, b) => a.gcDeficitSeconds.compareTo(b.gcDeficitSeconds));

      final BreakawayGcThreatCandidate? closestWatch =
          watchList.isNotEmpty ? watchList.first : null;
      final GcPanicReactionLevel level = closestWatch != null
          ? GcPanicReactionLevel.monitoring
          : GcPanicReactionLevel.none;

      return GcPanicReactionDecision(
        reactionLevel: level,
        isPanicTriggered: false,
        deployedDomestiquesCount: 0,
        deployedDomestiqueIds: const [],
        deployedDomestiqueNames: const [],
        targetChaseFtpRatio: safeBaselineFtp,
        targetWattsPerDomestique:
            (fallbackDomestiqueFtpWatts * safeBaselineFtp).round(),
        mostDangerousRider: closestWatch,
        allTriggeringThreats: const [],
        isVirtualGcLeaderThreat: false,
        virtualGcLeadSeconds: closestWatch == null
            ? 0.0
            : input.breakawayGapSeconds - closestWatch.gcDeficitSeconds,
        chaseCommitment: null,
        recommendedChaseUrgency: ChaseUrgency.controlledPacing,
        radioAlertMessage: closestWatch != null
            ? 'Ucieczka pod kontrolą ${input.leaderTeamName}: najbliższy rywal ${closestWatch.riderName} ma ${_formatMinutesSeconds(closestWatch.gcDeficitSeconds)} straty w GC (>= 4 min).'
            : 'Brak zagrożenia GC w ucieczce dnia – spokojna kontrola tempa.',
      );
    }

    // ALARM KRYZYSOWY: co najmniej jeden groźny kolarz ma < 4 min straty GC!
    final BreakawayGcThreatCandidate primaryThreat = panicThreats.first;
    final double virtualLeadSeconds =
        input.breakawayGapSeconds - primaryThreat.gcDeficitSeconds;
    final bool isVirtualLeader = virtualLeadSeconds > 0.0;

    // Wybieramy maksymalnie 4 najlepszych dostępnych pomocników drużyny lidera.
    final List<PelotonDomestiqueCandidate> eligibleDomestiques = input
        .leaderTeamDomestiques
        .where((d) =>
            d.isAvailableInPeloton &&
            !d.isGcLeader &&
            d.riderId != input.gcLeaderRiderId)
        .toList()
      ..sort((a, b) {
        // Najpierw najmniej zmęczeni, w razie remisu wyższe FTP.
        final int fatigueCmp =
            a.currentFatigueRatio.compareTo(b.currentFatigueRatio);
        if (fatigueCmp != 0) return fatigueCmp;
        return b.ftpWatts.compareTo(a.ftpWatts);
      });

    final int deployCount =
        math.min(panicDomestiquesCount, eligibleDomestiques.length);
    final List<PelotonDomestiqueCandidate> selectedDomestiques =
        eligibleDomestiques.take(deployCount).toList();

    final List<String> deployedIds =
        selectedDomestiques.map((d) => d.riderId).toList();
    final List<String> deployedNames =
        selectedDomestiques.map((d) => d.riderName).toList();

    final double avgFtp = selectedDomestiques.isEmpty
        ? fallbackDomestiqueFtpWatts.toDouble()
        : selectedDomestiques.fold<int>(0, (sum, d) => sum + d.ftpWatts) /
            selectedDomestiques.length;
    final int targetWatts = (avgFtp * panicChaseFtpRatio).round();

    final GcPanicReactionLevel reactionLevel = isVirtualLeader
        ? GcPanicReactionLevel.virtualLeaderEmergency
        : GcPanicReactionLevel.panicPursuit;

    final String motive = isVirtualLeader
        ? 'ALARM GC (Wirtualny Lider!): ${primaryThreat.riderName} (-${_formatMinutesSeconds(primaryThreat.gcDeficitSeconds)}) w ucieczce!'
        : 'ALARM GC (<4 min): ${primaryThreat.riderName} (-${_formatMinutesSeconds(primaryThreat.gcDeficitSeconds)}) w odjeździe!';

    final ChaseCommitment commitment = ChaseCommitment(
      teamId: input.leaderTeamId,
      teamName: input.leaderTeamName,
      committedDomestiqueIds: deployedIds,
      targetWattsPerRider: targetWatts,
      motive: motive,
    );

    final String radioAlert =
        'ALARM TAKTYCZNY ${input.leaderTeamName}: ${primaryThreat.riderName} '
        '(${primaryThreat.teamName}, strata ${_formatMinutesSeconds(primaryThreat.gcDeficitSeconds)} w GC) '
        'zabrał się do ucieczki! Na czoło peletonu natychmiast wchodzi $deployCount '
        'pomocników na tempie ${(panicChaseFtpRatio * 100).toStringAsFixed(0)}% FTP (${targetWatts}W).';

    return GcPanicReactionDecision(
      reactionLevel: reactionLevel,
      isPanicTriggered: true,
      deployedDomestiquesCount: deployCount,
      deployedDomestiqueIds: deployedIds,
      deployedDomestiqueNames: deployedNames,
      targetChaseFtpRatio: panicChaseFtpRatio,
      targetWattsPerDomestique: targetWatts,
      mostDangerousRider: primaryThreat,
      allTriggeringThreats: panicThreats,
      isVirtualGcLeaderThreat: isVirtualLeader,
      virtualGcLeadSeconds: virtualLeadSeconds,
      chaseCommitment: commitment,
      recommendedChaseUrgency: ChaseUrgency.panicCatch,
      radioAlertMessage: radioAlert,
    );
  }

  /// Integruje decyzję kryzysową AI z istniejącym planem pościgu `PelotonChasePlan`.
  ///
  /// Jeśli próg paniki GC nie został przekroczony, zwraca `basePlan` bez zmian.
  PelotonChasePlan applyPanicOverrideToChasePlan({
    required PelotonChasePlan basePlan,
    required GcPanicThresholdInput input,
  }) {
    final GcPanicReactionDecision decision = evaluatePanicReaction(input);
    if (!decision.isPanicTriggered || decision.chaseCommitment == null) {
      return basePlan;
    }

    final ChaseCommitment panicCommitment = decision.chaseCommitment!;
    final List<ChaseCommitment> updatedTeams = basePlan.committedTeams
        .where((team) => team.teamId != input.leaderTeamId)
        .toList()
      ..insert(0, panicCommitment);

    // 4 pomocników na 88% FTP znacząco przyspiesza odrabianie straty.
    final double boostedClawback = math.max(
      basePlan.actualClawbackSecondsPer10Km,
      decision.deployedDomestiquesCount * 16.5,
    );

    return basePlan.copyWith(
      urgency: ChaseUrgency.panicCatch,
      actualClawbackSecondsPer10Km: boostedClawback,
      breakawaySurvivalProbability:
          math.min(basePlan.breakawaySurvivalProbability, 0.12),
      committedTeams: updatedTeams,
      radioReport: decision.radioAlertMessage,
    );
  }

  static String _formatMinutesSeconds(double totalSeconds) {
    final int clamped = math.max(0, totalSeconds.round());
    final int mins = clamped ~/ 60;
    final int secs = clamped % 60;
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }
}
