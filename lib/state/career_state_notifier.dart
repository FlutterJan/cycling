import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/career/career_save.dart';
import '../models/career/recovery_protocol_system.dart';
import '../models/career/season_calendar.dart';
import '../models/equipment/equipment_wear_and_maintenance.dart';
import '../models/race/race_stage.dart';
import '../models/race/tour_race.dart';
import '../models/rider/rider.dart';
import '../models/team/bike_manufacturer_deal.dart';
import '../models/team/cycling_team.dart';
import '../services/career/ai_team_transfer_simulation_service.dart';
import '../services/career/anti_doping_and_whereabouts_service.dart';
import '../services/career/finance_and_budget_service.dart';
import '../services/career/press_conference_service.dart';
import '../services/career/scouting_and_youth_academy_service.dart';
import '../services/career/social_media_and_cycling_news_service.dart';
import '../services/career/sponsor_objectives_evaluator.dart';
import '../services/career/training_and_camps_service.dart';
import '../services/database/save_game_manager.dart';
import '../services/database/save_service.dart';

/// Kategoria wiadomości w skrzynce odbiorczej dyrektora sportowego (Inbox).
enum InboxCategory {
  raceBriefing,
  raceResults,
  medicalReport,
  trainingUpdate,
  finance,
  sponsorNews,
  transferMarket,
  general;

  String toJson() => name;

  static InboxCategory fromJson(String value) {
    return InboxCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => InboxCategory.general,
    );
  }

  String get label {
    switch (this) {
      case InboxCategory.raceBriefing:
        return 'Odprawa przedstartowa';
      case InboxCategory.raceResults:
        return 'Wyniki wyścigu';
      case InboxCategory.medicalReport:
        return 'Raport medyczny';
      case InboxCategory.trainingUpdate:
        return 'Raport treningowy';
      case InboxCategory.finance:
        return 'Finanse i budżet';
      case InboxCategory.sponsorNews:
        return 'Wiadomość sponsorska';
      case InboxCategory.transferMarket:
        return 'Rynek transferowy';
      case InboxCategory.general:
        return 'Wiadomość ogólna';
    }
  }
}

/// Poziom ważności wiadomości w skrzynce odbiorczej.
enum InboxPriority {
  urgent,
  normal,
  low;

  String toJson() => name;

  static InboxPriority fromJson(String value) {
    return InboxPriority.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => InboxPriority.normal,
    );
  }
}

/// Wiadomość w skrzynce odbiorczej menedżera (Inbox Message).
class CareerInboxMessage {
  final String id;
  final DateTime date;
  final String senderName;
  final String senderRole;
  final String subject;
  final String body;
  final InboxCategory category;
  final InboxPriority priority;
  final bool isRead;
  final String? actionLabel;

  const CareerInboxMessage({
    required this.id,
    required this.date,
    required this.senderName,
    required this.senderRole,
    required this.subject,
    required this.body,
    required this.category,
    this.priority = InboxPriority.normal,
    this.isRead = false,
    this.actionLabel,
  });

  CareerInboxMessage copyWith({
    String? id,
    DateTime? date,
    String? senderName,
    String? senderRole,
    String? subject,
    String? body,
    InboxCategory? category,
    InboxPriority? priority,
    bool? isRead,
    String? actionLabel,
  }) {
    return CareerInboxMessage(
      id: id ?? this.id,
      date: date ?? this.date,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      actionLabel: actionLabel ?? this.actionLabel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'senderName': senderName,
      'senderRole': senderRole,
      'subject': subject,
      'body': body,
      'category': category.toJson(),
      'priority': priority.toJson(),
      'isRead': isRead,
      if (actionLabel != null) 'actionLabel': actionLabel,
    };
  }

  factory CareerInboxMessage.fromJson(Map<String, dynamic> json) {
    return CareerInboxMessage(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      senderName: json['senderName'] as String,
      senderRole: json['senderRole'] as String,
      subject: json['subject'] as String,
      body: json['body'] as String,
      category: InboxCategory.fromJson(json['category'] as String),
      priority: InboxPriority.fromJson(json['priority'] as String? ?? 'normal'),
      isRead: json['isRead'] as bool? ?? false,
      actionLabel: json['actionLabel'] as String?,
    );
  }
}

/// Powód zatrzymania szybkiego przewijania kalendarza (`simulateUntilNextStop`).
enum SimulationStopReason {
  raceDay,
  urgentDecisionEmail,
  transferOffer,
  maxDaysReached,
  cancelled;

  String get label {
    switch (this) {
      case SimulationStopReason.raceDay:
        return 'Dzień startu wyścigu';
      case SimulationStopReason.urgentDecisionEmail:
        return 'Pilny e-mail decyzyjny w skrzynce';
      case SimulationStopReason.transferOffer:
        return 'Oferta lub wydarzenie transferowe';
      case SimulationStopReason.maxDaysReached:
        return 'Osiągnięto limit dni symulacji';
      case SimulationStopReason.cancelled:
        return 'Przerwano symulację';
    }
  }
}

/// Aktywne zgrupowanie wysokogórskie kolarza przetwarzane w pętli dobowej.
class ActiveTrainingCampAssignment {
  final String riderId;
  final String locationName;
  final int altitudeMeters;
  final int daysRemaining;
  final double dailyFtpGain;
  final double dailyVo2Gain;
  final double dailyAtlLoad;
  final double dailyCtlGain;

  const ActiveTrainingCampAssignment({
    required this.riderId,
    required this.locationName,
    required this.altitudeMeters,
    required this.daysRemaining,
    required this.dailyFtpGain,
    required this.dailyVo2Gain,
    required this.dailyAtlLoad,
    required this.dailyCtlGain,
  });

  ActiveTrainingCampAssignment copyWith({
    int? daysRemaining,
  }) {
    return ActiveTrainingCampAssignment(
      riderId: riderId,
      locationName: locationName,
      altitudeMeters: altitudeMeters,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      dailyFtpGain: dailyFtpGain,
      dailyVo2Gain: dailyVo2Gain,
      dailyAtlLoad: dailyAtlLoad,
      dailyCtlGain: dailyCtlGain,
    );
  }
}

/// Zaplanowana sesja regeneracyjna (hiperbaria, sauna, kompresja) dla kolarza.
class ScheduledRecoverySession {
  final String riderId;
  final RecoveryProtocolType protocolType;
  final int daysRemaining;

  const ScheduledRecoverySession({
    required this.riderId,
    required this.protocolType,
    this.daysRemaining = 1,
  });

  ScheduledRecoverySession copyWith({
    int? daysRemaining,
  }) {
    return ScheduledRecoverySession(
      riderId: riderId,
      protocolType: protocolType,
      daysRemaining: daysRemaining ?? this.daysRemaining,
    );
  }
}

/// Pełny stan kariery menedżerskiej w pamięci podręcznej aplikacji (CareerState).
class CareerState {
  final DateTime currentDate;
  final int currentSeasonYear;
  final String playerTeamId;
  final CyclingTeam playerTeam;
  final List<Rider> riders;
  final List<CyclingTeam> teams;
  final SeasonCalendar calendar;
  final List<CareerInboxMessage> inboxMessages;
  final List<CareerFinanceLedgerEntry> financeLedger;
  final TourRace? activeRaceToday;
  final RaceStage? activeStageToday;
  final bool isRaceDayForPlayerTeam;
  final int? activeSlotNumber;
  final bool isLoading;
  final String? errorMessage;
  final CareerSave? rawSave;
  final List<ActiveTrainingCampAssignment> activeTrainingCamps;
  final List<ScheduledRecoverySession> scheduledRecoverySessions;
  final bool isFastForwarding;
  final SimulationStopReason? lastStopReason;
  final String? lastStopMessage;
  final int fastForwardDaysSimulated;
  final List<TransferNewsItem> recentTransferNews;
  final List<PressConferenceSession> pendingPressConferences;
  final List<AntiDopingTestResult> recentAntiDopingResults;
  final Set<String> triggeredOneTimeEventKeys;
  final List<CyclingNewsItem> newsFeed;

  const CareerState({
    required this.currentDate,
    required this.currentSeasonYear,
    required this.playerTeamId,
    required this.playerTeam,
    required this.riders,
    required this.teams,
    required this.calendar,
    this.inboxMessages = const [],
    this.financeLedger = const [],
    this.activeRaceToday,
    this.activeStageToday,
    this.isRaceDayForPlayerTeam = false,
    this.activeSlotNumber,
    this.isLoading = false,
    this.errorMessage,
    this.rawSave,
    this.activeTrainingCamps = const [],
    this.scheduledRecoverySessions = const [],
    this.isFastForwarding = false,
    this.lastStopReason,
    this.lastStopMessage,
    this.fastForwardDaysSimulated = 0,
    this.recentTransferNews = const [],
    this.pendingPressConferences = const [],
    this.recentAntiDopingResults = const [],
    this.triggeredOneTimeEventKeys = const {},
    this.newsFeed = const [],
  });

  /// Skład kolarzy w drużynie gracza
  List<Rider> get playerRoster {
    return riders.where((r) => playerTeam.rosterRiderIds.contains(r.id)).toList();
  }

  /// Liczba nieprzeczytanych wiadomości w skrzynce
  int get unreadMessagesCount {
    return inboxMessages.where((m) => !m.isRead).length;
  }

  /// Lista nieprzeczytanych wiadomości
  List<CareerInboxMessage> get unreadMessages {
    return inboxMessages.where((m) => !m.isRead).toList();
  }

  /// Aktualny stan konta drużyny gracza w Euro
  int get cashBalanceEur => playerTeam.cashBalanceEur;

  /// Sformatowana data w grze (YYYY-MM-DD)
  String get formattedDate {
    final m = currentDate.month.toString().padLeft(2, '0');
    final d = currentDate.day.toString().padLeft(2, '0');
    return '${currentDate.year}-$m-$d';
  }

  /// Czy jakikolwiek kolarz w drużynie gracza zmaga się z kontuzją
  bool get hasInjuredRiders {
    return playerRoster.any((r) => r.health.currentInjury != null);
  }

  /// Lista kolarzy z aktywnymi urazami
  List<Rider> get injuredRiders {
    return playerRoster.where((r) => r.health.currentInjury != null).toList();
  }

  /// Czy dzisiaj odbywa się wyścig z udziałem drużyny gracza
  bool get hasActiveRaceToday => isRaceDayForPlayerTeam && activeStageToday != null;

  CareerState copyWith({
    DateTime? currentDate,
    int? currentSeasonYear,
    String? playerTeamId,
    CyclingTeam? playerTeam,
    List<Rider>? riders,
    List<CyclingTeam>? teams,
    SeasonCalendar? calendar,
    List<CareerInboxMessage>? inboxMessages,
    List<CareerFinanceLedgerEntry>? financeLedger,
    TourRace? activeRaceToday,
    bool clearActiveRace = false,
    RaceStage? activeStageToday,
    bool clearActiveStage = false,
    bool? isRaceDayForPlayerTeam,
    int? activeSlotNumber,
    bool clearActiveSlot = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    CareerSave? rawSave,
    List<ActiveTrainingCampAssignment>? activeTrainingCamps,
    List<ScheduledRecoverySession>? scheduledRecoverySessions,
    bool? isFastForwarding,
    SimulationStopReason? lastStopReason,
    bool clearLastStop = false,
    String? lastStopMessage,
    int? fastForwardDaysSimulated,
    List<TransferNewsItem>? recentTransferNews,
    List<PressConferenceSession>? pendingPressConferences,
    List<AntiDopingTestResult>? recentAntiDopingResults,
    Set<String>? triggeredOneTimeEventKeys,
    List<CyclingNewsItem>? newsFeed,
  }) {
    return CareerState(
      currentDate: currentDate ?? this.currentDate,
      currentSeasonYear: currentSeasonYear ?? this.currentSeasonYear,
      playerTeamId: playerTeamId ?? this.playerTeamId,
      playerTeam: playerTeam ?? this.playerTeam,
      riders: riders ?? this.riders,
      teams: teams ?? this.teams,
      calendar: calendar ?? this.calendar,
      inboxMessages: inboxMessages ?? this.inboxMessages,
      financeLedger: financeLedger ?? this.financeLedger,
      activeRaceToday: clearActiveRace ? null : (activeRaceToday ?? this.activeRaceToday),
      activeStageToday: clearActiveStage ? null : (activeStageToday ?? this.activeStageToday),
      isRaceDayForPlayerTeam: isRaceDayForPlayerTeam ?? this.isRaceDayForPlayerTeam,
      activeSlotNumber: clearActiveSlot ? null : (activeSlotNumber ?? this.activeSlotNumber),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      rawSave: rawSave ?? this.rawSave,
      activeTrainingCamps: activeTrainingCamps ?? this.activeTrainingCamps,
      scheduledRecoverySessions: scheduledRecoverySessions ?? this.scheduledRecoverySessions,
      isFastForwarding: isFastForwarding ?? this.isFastForwarding,
      lastStopReason: clearLastStop ? null : (lastStopReason ?? this.lastStopReason),
      lastStopMessage: clearLastStop ? null : (lastStopMessage ?? this.lastStopMessage),
      fastForwardDaysSimulated: fastForwardDaysSimulated ?? this.fastForwardDaysSimulated,
      recentTransferNews: recentTransferNews ?? this.recentTransferNews,
      pendingPressConferences: pendingPressConferences ?? this.pendingPressConferences,
      recentAntiDopingResults: recentAntiDopingResults ?? this.recentAntiDopingResults,
      triggeredOneTimeEventKeys: triggeredOneTimeEventKeys ?? this.triggeredOneTimeEventKeys,
      newsFeed: newsFeed ?? this.newsFeed,
    );
  }

  /// Tworzy stan CareerState na podstawie modelu zapisu CareerSave
  factory CareerState.fromSave(
    CareerSave save, {
    int? activeSlotNumber,
    List<CareerInboxMessage>? previousInboxMessages,
  }) {
    final team = save.playerTeam;

    // Sprawdzamy czy dzisiaj odbywa się etap dla zespołu gracza
    TourRace? raceToday;
    RaceStage? stageToday;
    bool raceDay = false;

    for (final race in save.calendar.races) {
      if (race.isCompleted) continue;
      final bool withinDates =
          !save.currentDate.isBefore(race.startDate) && !save.currentDate.isAfter(race.endDate);

      if (withinDates && race.participatingTeamIds.contains(save.playerTeamId)) {
        raceToday = race;
        raceDay = true;
        final dayOffset = save.currentDate.difference(race.startDate).inDays;
        final stageIdx = dayOffset.clamp(0, race.stages.length - 1);
        stageToday = race.stages[stageIdx];
        break;
      }
    }

    // Inicjalizacja wiadomości powitalnych, jeśli skrzynka jest pusta
    final List<CareerInboxMessage> inbox = previousInboxMessages != null && previousInboxMessages.isNotEmpty
        ? previousInboxMessages
        : [
            CareerInboxMessage(
              id: 'msg_welcome_${save.id}',
              date: save.currentDate,
              senderName: 'Prezydent Klubu & Zarząd',
              senderRole: 'Rada Nadzorcza Zespołu',
              subject: 'Witamy w zespole! Początek sezonu ${save.currentSeasonYear}',
              body: 'Objąłeś oficjalne stanowisko Głównego Menedżera w drużynie ${team.name}. '
                  'Twoim nadrzędnym celem jest zarządzanie formą zawodników, dbanie o zrównoważony budżet klubu, '
                  'renegocjacja kontraktów sponsorskich oraz walka o zwycięstwa w wyścigach UCI.',
              category: InboxCategory.general,
              priority: InboxPriority.urgent,
            ),
            CareerInboxMessage(
              id: 'msg_service_course_${save.id}',
              date: save.currentDate,
              senderName: 'Główny Mechanik Zespołu',
              senderRole: 'Service Course & Zaplecze Sprzętowe',
              subject: 'Flota rowerów ${team.bikeDeal.manufacturerName} przygotowana do sezonu',
              body: 'Dostarczono przepisową pulę ram i kół od ${team.bikeDeal.manufacturerName}. '
                  'Wszystkie rowery spełniają restrykcyjne normy wagowe UCI (minimum 6.80 kg) i są gotowe do startów.',
              category: InboxCategory.general,
              priority: InboxPriority.normal,
            ),
          ];

    const newsService = SocialMediaAndCyclingNewsService();
    final initialNewsFeed = newsService.generateInitialFeed(save);

    return CareerState(
      currentDate: save.currentDate,
      currentSeasonYear: save.currentSeasonYear,
      playerTeamId: save.playerTeamId,
      playerTeam: team,
      riders: save.riders,
      teams: save.teams,
      calendar: save.calendar,
      inboxMessages: inbox,
      financeLedger: save.financeLedger,
      activeRaceToday: raceToday,
      activeStageToday: stageToday,
      isRaceDayForPlayerTeam: raceDay,
      activeSlotNumber: activeSlotNumber,
      rawSave: save,
      newsFeed: initialNewsFeed,
    );
  }

  /// Zwraca zaktualizowany obiekt CareerSave gotowy do trwałego zapisu na dysku
  CareerSave toSave() {
    final baseSave = rawSave;
    if (baseSave != null) {
      return baseSave.copyWith(
        currentDate: currentDate,
        currentSeasonYear: currentSeasonYear,
        teams: teams,
        riders: riders,
        calendar: calendar,
        financeLedger: financeLedger,
        lastSavedAt: DateTime.now(),
      );
    }

    return CareerSave(
      id: 'save_${currentDate.millisecondsSinceEpoch}',
      saveName: 'Kariera ${playerTeam.name}',
      createdAt: DateTime.now(),
      lastSavedAt: DateTime.now(),
      difficulty: CareerDifficulty.normal,
      playerManagerName: 'Dyrektor Sportowy',
      playerTeamId: playerTeamId,
      currentDate: currentDate,
      currentSeasonYear: currentSeasonYear,
      calendar: calendar,
      teams: teams,
      riders: riders,
      financeLedger: financeLedger,
    );
  }
}

/// Główny kontroler stanu kariery w Riverpod zarządzający upływem czasu,
/// skrzynką odbiorczą (Inbox), treningami, leczeniem kontuzji oraz finansami.
class CareerStateNotifier extends StateNotifier<CareerState> {
  CareerStateNotifier()
      : super(
          CareerState(
            currentDate: DateTime(2026, 1, 1),
            currentSeasonYear: 2026,
            playerTeamId: 'wt_aethel_veloce',
            playerTeam: const CyclingTeam(
              id: 'wt_aethel_veloce',
              name: 'Pro Peloton Team',
              division: TeamDivision.worldTour,
              countryIso: 'FRA',
              primaryJerseyColorHex: '#FFFFFF',
              secondaryJerseyColorHex: '#000000',
              accentJerseyColorHex: '#FF0000',
              cashBalanceEur: 35000000,
              monthlyBurnRateEur: 2500000,
              uciPointsSeason: 4500,
              rosterRiderIds: [],
              staff: TeamStaff(
                trainersLevel: 75,
                sportsDirectorsLevel: 75,
                doctorsLevel: 75,
                mechanicsLevel: 75,
                scoutsLevel: 75,
              ),
              bikeDeal: BikeManufacturerDeal(
                manufacturerId: 'brand_veloce',
                manufacturerName: 'Veloce Corsa',
                prestigeLevel: 5,
                annualCashContributionEur: 2500000,
                freeBikesQuota: 80,
                researchAndDevelopmentLevel: 80,
                suppliedFrameIds: ['frame_veloce_aero'],
                suppliedWheelsetIds: ['wheels_veloce_50'],
                contractYearsLeft: 2,
                minimumUciRankingRequired: 18,
              ),
              sponsors: [],
              inventoryBikes: [],
            ),
            riders: const [],
            teams: const [],
            calendar: const SeasonCalendar(
              seasonYear: 2026,
              races: [],
            ),
          ),
        );

  /// Przesuwa czas w grze o 1 dzień (`advanceDay`), wykonując pełną pętlę
  /// symulacji świata kolarskiego:
  /// 1. Przeliczanie obciążeń treningowych (CTL, ATL, TSB) dla wszystkich drużyn.
  /// 2. Efekty obozów wysokogórskich i sesji regeneracyjnych (hiperbaria, sauna, kompresja).
  /// 3. Postęp leczenia kontuzji (wszystkie drużyny + bonus Centrum Medycznego gracza).
  /// 4. Zużycie sprzętu (`EquipmentWearAndMaintenance`) podczas startów i alerty serwisowe.
  /// 5. Automatyczna symulacja wyścigów bez udziału gracza (punkty UCI, historia, statystyki).
  /// 6. Wyzwalacze zdarzeń specjalnych (1 sierpnia okno transferowe + rynek AI,
  ///    losowe kontrole ADAMS, konferencje przed Grand Tourami, raporty skautów U23,
  ///    miesięczne rozliczenia finansowe oraz ewaluacja celów sponsorskich).
  Future<void> advanceDay({bool persistAutoSave = true}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final nextState = _simulateSingleDay(state);

      if (persistAutoSave) {
        await _safePerformAutoSave(
          save: nextState.rawSave ?? nextState.toSave(),
          slotNumber: nextState.activeSlotNumber,
        );
      }

      state = nextState.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Błąd podczas przesuwania dnia w kalendarzu: $e',
      );
    }
  }

  /// Szybko przewija dni w kalendarzu bez opóźnień animacji do najbliższego
  /// ważnego wydarzenia (wyścig, oferta transferowa, pilny e-mail decyzyjny).
  Future<SimulationStopReason> advanceToNextEvent({int maxDays = 30}) {
    return simulateUntilNextStop(
      maxDays: maxDays,
      stepDelay: Duration.zero,
    );
  }

  /// Płynnie przewija dni w kalendarzu (z animowanym licznikiem daty w UI poprzez
  /// emitowanie kolejnych stanów), zatrzymując się automatycznie przed:
  /// - dniem startu wyścigu z udziałem drużyny gracza,
  /// - pilną ofertą transferową / otwarciem okna transferowego,
  /// - ważnym e-mailem decyzyjnym wymagającym reakcji menedżera.
  Future<SimulationStopReason> simulateUntilNextStop({
    int maxDays = 30,
    Duration stepDelay = const Duration(milliseconds: 90),
    bool Function()? shouldCancel,
  }) async {
    final int initialUnreadUrgentCount = state.inboxMessages
        .where((m) => !m.isRead && m.priority == InboxPriority.urgent)
        .length;

    state = state.copyWith(
      isFastForwarding: true,
      fastForwardDaysSimulated: 0,
      clearLastStop: true,
      clearError: true,
    );

    SimulationStopReason stopReason = SimulationStopReason.maxDaysReached;
    String stopMessage = 'Osiągnięto limit $maxDays dni symulacji bez zdarzeń blokujących.';

    try {
      for (int day = 1; day <= maxDays; day++) {
        if (shouldCancel?.call() == true) {
          stopReason = SimulationStopReason.cancelled;
          stopMessage = 'Symulacja została zatrzymana przez menedżera.';
          break;
        }

        final nextState = _simulateSingleDay(state);
        state = nextState.copyWith(
          isFastForwarding: true,
          fastForwardDaysSimulated: day,
        );

        final stopCheck = _evaluateStopCondition(
          currentState: state,
          initialUnreadUrgentCount: initialUnreadUrgentCount,
        );

        if (stopCheck != null) {
          stopReason = stopCheck.$1;
          stopMessage = stopCheck.$2;
          break;
        }

        if (stepDelay > Duration.zero && day < maxDays) {
          await Future<void>.delayed(stepDelay);
        }
      }

      await _safePerformAutoSave(
        save: state.rawSave ?? state.toSave(),
        slotNumber: state.activeSlotNumber,
      );

      state = state.copyWith(
        isFastForwarding: false,
        lastStopReason: stopReason,
        lastStopMessage: stopMessage,
      );
      return stopReason;
    } catch (e) {
      state = state.copyWith(
        isFastForwarding: false,
        lastStopReason: SimulationStopReason.cancelled,
        lastStopMessage: 'Błąd symulacji: $e',
        errorMessage: 'Błąd podczas przewijania kalendarza: $e',
      );
      return SimulationStopReason.cancelled;
    }
  }

  /// Zapisuje kolarzy na aktywne zgrupowanie wysokogórskie przetwarzane dzień po dniu.
  void enrollRidersInAltitudeCamp({
    required AltitudeCampLocation location,
    required List<String> riderIds,
    required int durationDays,
  }) {
    if (riderIds.isEmpty || durationDays <= 0) return;

    final double dailyFtp = location.ftpGainWatts / durationDays;
    final double dailyVo2 = (location.vo2maxBoostPct * 0.6) / durationDays;
    final double dailyAtl = location.atlFatigueDaily;
    final double dailyCtl = location.atlFatigueDaily * 0.45;

    final updatedCamps = List<ActiveTrainingCampAssignment>.from(state.activeTrainingCamps)
      ..removeWhere((c) => riderIds.contains(c.riderId));

    for (final rId in riderIds) {
      updatedCamps.add(
        ActiveTrainingCampAssignment(
          riderId: rId,
          locationName: location.name,
          altitudeMeters: location.altitudeMeters,
          daysRemaining: durationDays,
          dailyFtpGain: dailyFtp,
          dailyVo2Gain: dailyVo2,
          dailyAtlLoad: dailyAtl,
          dailyCtlGain: dailyCtl,
        ),
      );
    }

    state = state.copyWith(activeTrainingCamps: updatedCamps);
  }

  /// Planuje sesję regeneracyjną (hiperbaria, sauna, kompresja itp.) do wykonania w pętli dobowej.
  void scheduleRecoverySession({
    required String riderId,
    required RecoveryProtocolType protocolType,
    int durationDays = 1,
  }) {
    if (durationDays <= 0) return;
    final updatedSessions = List<ScheduledRecoverySession>.from(state.scheduledRecoverySessions)
      ..add(
        ScheduledRecoverySession(
          riderId: riderId,
          protocolType: protocolType,
          daysRemaining: durationDays,
        ),
      );
    state = state.copyWith(scheduledRecoverySessions: updatedSessions);
  }

  /// Ręczna lub powyścigowa ewaluacja celów sponsorskich drużyny gracza (`SponsorObjectivesEvaluator`).
  SponsorEvaluationResult evaluatePostRaceObjectives(PostRaceSponsorContext context) {
    const evaluator = SponsorObjectivesEvaluator();
    final evalResult = evaluator.evaluatePostRace(
      team: state.playerTeam,
      context: context,
    );

    final updatedPlayerTeam = evaluator.applyEvaluationToTeam(
      team: state.playerTeam,
      result: evalResult,
    );

    final updatedTeams = state.teams.map((t) {
      return t.id == state.playerTeamId ? updatedPlayerTeam : t;
    }).toList();

    final updatedLedger = List<CareerFinanceLedgerEntry>.from(state.financeLedger);
    if (evalResult.totalBonusesPaidEur > 0) {
      updatedLedger.insert(
        0,
        CareerFinanceLedgerEntry(
          id: 'fin_sponsor_bonus_${state.currentDate.millisecondsSinceEpoch}',
          date: state.currentDate,
          category: FinanceCategory.sponsorPayout,
          amountEur: evalResult.totalBonusesPaidEur,
          description: 'Bonusy sponsorskie za wyścig ${context.raceName}',
        ),
      );
    }

    final updatedInbox = [...evalResult.generatedEmails, ...state.inboxMessages];
    final nextSave = (state.rawSave ?? state.toSave()).copyWith(
      teams: updatedTeams,
      financeLedger: updatedLedger,
      lastSavedAt: DateTime.now(),
    );

    state = state.copyWith(
      playerTeam: updatedPlayerTeam,
      teams: updatedTeams,
      financeLedger: updatedLedger,
      inboxMessages: updatedInbox,
      rawSave: nextSave,
    );

    return evalResult;
  }

  // ===========================================================================
  // WEWNĘTRZNY RDZEŃ SYMULACJI DOBOWEJ
  // ===========================================================================

  CareerState _simulateSingleDay(CareerState current) {
    final newDate = current.currentDate.add(const Duration(days: 1));
    final int seed = newDate.year * 10000 + newDate.month * 100 + newDate.day;
    final rng = math.Random(seed);

    final List<CareerInboxMessage> newInboxMessages = List.from(current.inboxMessages);
    final Set<String> triggeredKeys = Set<String>.from(current.triggeredOneTimeEventKeys);
    var updatedTeams = List<CyclingTeam>.from(current.teams);
    var updatedLedger = List<CareerFinanceLedgerEntry>.from(current.financeLedger);
    var updatedCalendar = current.calendar;
    var updatedSave = current.rawSave ?? current.toSave();
    final int medCenterLevel = updatedSave.medicalCenterLevel;

    // Mapa drużyny dla szybkiego dostępu w pętli kolarzy
    final Map<String, CyclingTeam> teamById = {
      for (final t in updatedTeams) t.id: t,
    };
    final Map<String, CyclingTeam> riderTeamMap = {};
    for (final t in updatedTeams) {
      for (final rId in t.rosterRiderIds) {
        riderTeamMap[rId] = t;
      }
    }

    // Zidentyfikuj aktywne wyścigi w dniu `newDate`
    final Set<String> racingTeamIdsToday = {};
    final Map<String, RaceStage> teamStageTodayMap = {};
    for (final race in updatedCalendar.races) {
      if (updatedCalendar.isRaceCompleted(race.id)) continue;
      final raceStart = DateTime(newDate.year, race.startMonth, race.startDay);
      final raceEnd = raceStart.add(Duration(days: race.stages.isNotEmpty ? race.stages.length - 1 : 0));
      if (!newDate.isBefore(raceStart) && !newDate.isAfter(raceEnd)) {
        final dayOffset = newDate.difference(raceStart).inDays;
        final stage = race.stages.isNotEmpty
            ? race.stages[dayOffset.clamp(0, race.stages.length - 1)]
            : null;
        for (final tId in race.participatingTeamIds) {
          racingTeamIdsToday.add(tId);
          if (stage != null) {
            teamStageTodayMap[tId] = stage;
          }
        }
      }
    }

    // Aktywne obozy wysokogórskie i sesje regeneracyjne po riderId
    final Map<String, ActiveTrainingCampAssignment> campByRider = {
      for (final c in current.activeTrainingCamps) c.riderId: c,
    };
    final Map<String, List<ScheduledRecoverySession>> recoveryByRider = {};
    for (final s in current.scheduledRecoverySessions) {
      recoveryByRider.putIfAbsent(s.riderId, () => []).add(s);
    }

    final List<ActiveTrainingCampAssignment> remainingCamps = [];
    final List<ScheduledRecoverySession> remainingRecoverySessions = [];

    // -------------------------------------------------------------------------
    // 1. PĘTLA AKTUALIZACJI DLA WSZYSTKICH KOLARZY I DRUŻYN (CTL/ATL/TSB, OBOZY, REGENERACJA, KONTUZJE)
    // -------------------------------------------------------------------------
    var updatedRiders = current.riders.map((rider) {
      final team = riderTeamMap[rider.id];
      final bool isPlayerRider = team?.id == current.playerTeamId;
      final int doctorsLevel = team?.staff.doctorsLevel ?? 65;
      final int trainersLevel = team?.staff.trainersLevel ?? 65;
      var workingRider = rider;
      var health = workingRider.health;

      // A. Leczenie kontuzji
      if (health.currentInjury != null) {
        final injury = health.currentInjury!;
        final int daysHealed = (isPlayerRider && medCenterLevel >= 4 && doctorsLevel >= 80) ? 2 : 1;
        final int remainingDays = injury.daysRemaining - daysHealed;

        if (remainingDays <= 0) {
          health = health.copyWith(clearInjury: true);
          if (isPlayerRider) {
            newInboxMessages.insert(
              0,
              CareerInboxMessage(
                id: 'msg_healed_${rider.id}_${newDate.millisecondsSinceEpoch}',
                date: newDate,
                senderName: 'Dr. Roberto Ferrari',
                senderRole: 'Główny Lekarz Zespołu',
                subject: 'Kolarz ${rider.fullName} zakończył rehabilitację!',
                body: '${rider.fullName} wyleczył uraz (${injury.name}) i otrzymał pełną zgodę '
                    'sztabu medycznego (Centrum Medyczne poz. $medCenterLevel) na powrót do rywalizacji.',
                category: InboxCategory.medicalReport,
                priority: InboxPriority.urgent,
              ),
            );
          }
        } else {
          health = health.copyWith(
            currentInjury: injury.copyWith(daysRemaining: remainingDays),
          );
        }
      }

      // B. Przeliczanie obciążeń treningowych (CTL, ATL, TSB) oraz obozów wysokogórskich
      final camp = campByRider[rider.id];
      final bool isRacingToday = team != null && racingTeamIdsToday.contains(team.id) && health.isFitToRace;

      double nextAtl = health.acuteTrainingLoad;
      double nextCtl = health.chronicTrainingLoad;
      var power = workingRider.powerProfile;
      var physio = workingRider.physiology;

      if (camp != null && health.canTrain) {
        nextAtl = (nextAtl + camp.dailyAtlLoad).clamp(0.0, 250.0);
        nextCtl = (nextCtl + camp.dailyCtlGain).clamp(15.0, 160.0);
        final int nextFtp = (physio.ftpWatts + camp.dailyFtpGain.round()).clamp(220, 540);
        final double nextVo2 = (physio.vo2Max + camp.dailyVo2Gain).clamp(55.0, 95.0);
        physio = physio.copyWith(
          ftpWatts: nextFtp,
          criticalPowerWatts: nextFtp,
          vo2Max: nextVo2,
        );
        power = power.copyWith(functionalThresholdPowerWatts: nextFtp);

        final int campDaysLeft = camp.daysRemaining - 1;
        if (campDaysLeft > 0) {
          remainingCamps.add(camp.copyWith(daysRemaining: campDaysLeft));
        } else if (isPlayerRider) {
          newInboxMessages.insert(
            0,
            CareerInboxMessage(
              id: 'msg_camp_done_${rider.id}_${newDate.millisecondsSinceEpoch}',
              date: newDate,
              senderName: 'Trener Przygotowania Fizycznego',
              senderRole: 'Sztab Szkoleniowy',
              subject: 'Zakończono obóz wysokogórski: ${rider.fullName}',
              body: '${rider.fullName} ukończył blok hipoksyjny w ${camp.locationName} '
                  '(${camp.altitudeMeters} m n.p.m.). Parametry tlenowe wzrosły, teraz zalecany jest '
                  'krótki tapering regeneracyjny przed kolejnym startem.',
              category: InboxCategory.trainingUpdate,
              priority: InboxPriority.normal,
            ),
          );
        }
      } else if (isRacingToday) {
        const double raceTss = 135.0;
        nextAtl = (nextAtl + (raceTss - nextAtl) / 7.0).clamp(0.0, 250.0);
        nextCtl = (nextCtl + (raceTss - nextCtl) / 42.0).clamp(15.0, 160.0);
      } else if (health.isFitToRace) {
        final double dailyTss = 55.0 + (trainersLevel - 50) * 0.25;
        nextAtl = (nextAtl + (dailyTss - nextAtl) / 7.0).clamp(0.0, 250.0);
        nextCtl = (nextCtl + (dailyTss - nextCtl) / 42.0).clamp(15.0, 160.0);
      } else {
        // Odpoczynek przy chorobie lub ciężkiej kontuzji
        nextAtl = (nextAtl * 0.86).clamp(0.0, 250.0);
        nextCtl = (nextCtl * 0.985).clamp(15.0, 160.0);
      }

      // Naturalny rozwój młodych kolarzy
      if (health.isFitToRace && rider.age <= 26 && team != null) {
        final double ftpGain = 0.015 * (rider.potential / 100.0);
        final int updatedFtp = (power.functionalThresholdPowerWatts + ftpGain).round();
        power = power.copyWith(functionalThresholdPowerWatts: updatedFtp);
        physio = physio.copyWith(criticalPowerWatts: updatedFtp);
      }

      workingRider = workingRider.copyWith(
        health: health.copyWith(
          acuteTrainingLoad: nextAtl,
          chronicTrainingLoad: nextCtl,
        ),
        powerProfile: power,
        physiology: physio,
      );

      // C. Sesje regeneracyjne (hiperbaria, sauna, kompresja)
      final sessions = recoveryByRider[rider.id];
      if (sessions != null && sessions.isNotEmpty) {
        for (final session in sessions) {
          final (recoveredRider, _) = RecoveryProtocolSystem.applyProtocol(
            rider: workingRider,
            protocolType: session.protocolType,
            teamDoctorSkillLevel: doctorsLevel,
          );
          workingRider = recoveredRider;
          if (session.daysRemaining > 1) {
            remainingRecoverySessions.add(
              session.copyWith(daysRemaining: session.daysRemaining - 1),
            );
          }
        }
      }

      return workingRider;
    }).toList();

    // -------------------------------------------------------------------------
    // 2. ZUŻYCIE SPRZĘTU (EQUIPMENT WEAR & SERVICE COURSE)
    // -------------------------------------------------------------------------
    updatedTeams = updatedTeams.map((team) {
      if (team.inventoryBikes.isEmpty) return team;
      final stageToday = teamStageTodayMap[team.id];
      if (stageToday == null) return team;

      bool lowWaxAlertTriggered = false;
      final bool isRaining = rng.nextDouble() < 0.22;
      final updatedBikes = team.inventoryBikes.map((bike) {
        final wearResult = bike.wear.simulateStageWear(
          stageDistanceKm: stageToday.totalDistanceKm,
          elevationGainMeters: stageToday.totalElevationGainM,
          descentElevationMeters: stageToday.totalElevationGainM * 0.9,
          isRaining: isRaining,
          roadWetness: isRaining ? 0.7 : 0.0,
        );
        final nextWear = EquipmentWearAndMaintenance(
          chain: wearResult.updatedChain,
          frontTire: wearResult.updatedFrontTire,
          rearTire: wearResult.updatedRearTire,
          frontBrake: wearResult.updatedFrontBrake,
          rearBrake: wearResult.updatedRearBrake,
          electronicBatteryPercent: (bike.wear.electronicBatteryPercent - 3.5).clamp(10.0, 100.0),
        );
        if (team.id == current.playerTeamId &&
            (wearResult.didWaxWashoutOccur || nextWear.chain.waxFilmRemainingPercent < 20.0)) {
          lowWaxAlertTriggered = true;
        }
        return bike.applyWear(nextWear);
      }).toList();

      if (lowWaxAlertTriggered && triggeredKeys.add('wax_alert_${team.id}_${newDate.year}_${newDate.month}_${newDate.day}')) {
        newInboxMessages.insert(
          0,
          CareerInboxMessage(
            id: 'msg_equip_${newDate.millisecondsSinceEpoch}',
            date: newDate,
            senderName: 'Główny Mechanik Service Course',
            senderRole: 'Dział Techniczny i Sprzętu',
            subject: 'Raport zużycia sprzętu: wymagane woskowanie łańcuchów',
            body: 'Po dzisiejszym etapie (${stageToday.totalDistanceKm.toStringAsFixed(0)} km) warstwa wosku '
                'na części rowerów spadła poniżej 20%. Zalecamy serwis w Garażu R&D przed kolejnym startem.',
            category: InboxCategory.general,
            priority: InboxPriority.normal,
            actionLabel: 'Otwórz Garaż R&D',
          ),
        );
      }

      return team.copyWith(inventoryBikes: updatedBikes);
    }).toList();

    // -------------------------------------------------------------------------
    // 3. AUTOMATYCZNA SYMULACJA WYŚCIGÓW AI (BEZ UDZIAŁU GRACZA)
    // -------------------------------------------------------------------------
    final aiSimResult = _simulateCompletedNonPlayerRaces(
      date: newDate,
      playerTeamId: current.playerTeamId,
      calendar: updatedCalendar,
      teams: updatedTeams,
      riders: updatedRiders,
      rng: rng,
    );
    updatedCalendar = aiSimResult.calendar;
    updatedTeams = aiSimResult.teams;
    updatedRiders = aiSimResult.riders;
    newInboxMessages.insertAll(0, aiSimResult.newsMessages);

    // -------------------------------------------------------------------------
    // 4. WYZWALACZE ZDARZEŃ SPECJALNYCH
    // -------------------------------------------------------------------------

    // 4A. Otwarcie okna transferowego (1 sierpnia)
    if (newDate.month == AiTeamTransferSimulationService.windowOpenMonth &&
        newDate.day == AiTeamTransferSimulationService.windowOpenDay &&
        triggeredKeys.add('transfer_window_open_${newDate.year}')) {
      newInboxMessages.insert(
        0,
        CareerInboxMessage(
          id: 'msg_tw_open_${newDate.year}',
          date: newDate,
          senderName: 'Biuro Transferowe UCI',
          senderRole: 'Komisja Licencyjna WorldTour',
          subject: 'Oficjalne otwarcie okna transferowego (${newDate.year})',
          body: 'Z dniem 1 sierpnia otwarto główne okno transferowe UCI (potrwa do 15 listopada). '
              'Drużyny mogą składać wiążące oferty wolnym agentom, negocjować wykupy klauzul oraz '
              'zgłaszać stażystów U23 (Stagiaires).',
          category: InboxCategory.transferMarket,
          priority: InboxPriority.urgent,
          actionLabel: 'Otwórz Rynek Transferowy',
        ),
      );
    }

    // 4B. Dzienna symulacja rynku transferowego AI i ofert wykupu dla gracza
    List<TransferNewsItem> updatedTransferNews = List.from(current.recentTransferNews);
    if (updatedTeams.length > 1 && updatedRiders.isNotEmpty) {
      final transferSim = AiTeamTransferSimulationService.simulateMarketDay(
        currentDate: newDate,
        currentSeasonYear: newDate.year,
        playerTeamId: current.playerTeamId,
        teams: updatedTeams,
        riders: updatedRiders,
        maxEventsPerStep: 3,
        randomSeed: seed,
      );
      updatedTeams = transferSim.updatedTeams;
      updatedRiders = transferSim.updatedRiders;
      if (transferSim.newsItems.isNotEmpty) {
        updatedTransferNews = [...transferSim.newsItems, ...updatedTransferNews].take(30).toList();
      }
      if (transferSim.playerBuyoutOffers.isNotEmpty) {
        for (final buyout in transferSim.playerBuyoutOffers) {
          newInboxMessages.insert(
            0,
            CareerInboxMessage(
              id: 'msg_buyout_${buyout.riderId}_${newDate.millisecondsSinceEpoch}',
              date: newDate,
              senderName: buyout.winningTeamName,
              senderRole: 'Oferta Transferowa',
              subject: 'Oferta transferowa za ${buyout.riderName}!',
              body: '${buyout.winningTeamName} złożyła ofertę kontraktową / wykupu za ${buyout.riderName} '
                  '(pensja €${buyout.winningOffer.offeredAnnualSalaryEur}/rok). Sprawdź szczegóły na Rynku Transferowym.',
              category: InboxCategory.transferMarket,
              priority: InboxPriority.urgent,
              actionLabel: 'Rozpatrz Ofertę Transferową',
            ),
          );
        }
      }
    }

    // 4C. Losowe kontrole antydopingowe ADAMS
    final List<AntiDopingTestResult> updatedDopingResults = List.from(current.recentAntiDopingResults);
    final playerRosterNow = updatedRiders
        .where((r) => (teamById[current.playerTeamId]?.rosterRiderIds ?? current.playerTeam.rosterRiderIds).contains(r.id))
        .toList();
    final bool playerRacingToday = racingTeamIdsToday.contains(current.playerTeamId);
    final double adamsChance = playerRacingToday ? 0.045 : 0.015;
    if (playerRosterNow.isNotEmpty && rng.nextDouble() < adamsChance) {
      final testedRider = playerRosterNow[rng.nextInt(playerRosterNow.length)];
      final testType = playerRacingToday
          ? AntiDopingTestType.inCompetition
          : AntiDopingTestType.outOfCompetition;
      final testResult = AntiDopingAndWhereaboutsService.conductAntiDopingTest(
        rider: testedRider,
        testType: testType,
        testDate: newDate,
        activeTreatments: const [],
        approvedTues: const [],
        rng: rng,
      );
      updatedDopingResults.insert(0, testResult);
      if (updatedDopingResults.length > 20) {
        updatedDopingResults.removeLast();
      }

      final bool isFlagged = testResult.outcome != DopingTestOutcome.negativeClean;
      newInboxMessages.insert(
        0,
        CareerInboxMessage(
          id: 'msg_adams_${testedRider.id}_${newDate.millisecondsSinceEpoch}',
          date: newDate,
          senderName: 'ITA / ADAMS Kontroler WADA',
          senderRole: 'Niezależna Agencja Antydopingowa',
          subject: isFlagged
              ? 'PILNE ADAMS: Nietypowy wynik próbki — ${testedRider.fullName}'
              : 'Kontrola ADAMS zakończona wynikiem negatywnym (${testedRider.fullName})',
          body: 'Przeprowadzono kontrolę (${testType.displayName}) u zawodnika ${testedRider.fullName}. '
              'Raport laboratorium: ${testResult.labReportSummary}',
          category: InboxCategory.medicalReport,
          priority: isFlagged ? InboxPriority.urgent : InboxPriority.low,
          actionLabel: isFlagged ? 'Otwórz Centrum Medyczne' : null,
        ),
      );
    }

    // 4D. Zaproszenia na konferencje prasowe przed Wielkimi Tourami (Grand Tour)
    final List<PressConferenceSession> updatedPressConferences = List.from(current.pendingPressConferences);
    for (final race in updatedCalendar.races) {
      if (updatedCalendar.isRaceCompleted(race.id)) continue;
      if (race.uciCategory != RaceCategory.grandTour) continue;
      if (!race.participatingTeamIds.contains(current.playerTeamId)) continue;

      final raceStart = DateTime(newDate.year, race.startMonth, race.startDay);
      if (raceStart.difference(newDate).inDays == 1 &&
          triggeredKeys.add('press_gt_${race.id}_${newDate.year}')) {
        if (playerRosterNow.isNotEmpty) {
          final focalRider = playerRosterNow.reduce(
            (a, b) => a.overallRating >= b.overallRating ? a : b,
          );
          final rivalCandidates = updatedRiders.where(
            (r) => !playerRosterNow.any((pr) => pr.id == r.id),
          );
          final rivalLeader = rivalCandidates.isNotEmpty
              ? rivalCandidates.reduce((a, b) => a.overallRating >= b.overallRating ? a : b)
              : null;

          final session = PressConferenceService.generatePressConference(
            context: PressConferenceContext.preGrandTourOpening,
            race: race,
            focalRider: focalRider,
            rivalLeader: rivalLeader,
            conferenceDate: newDate,
          );
          updatedPressConferences.insert(0, session);

          newInboxMessages.insert(
            0,
            CareerInboxMessage(
              id: 'msg_press_gt_${race.id}_${newDate.year}',
              date: newDate,
              senderName: 'Biuro Prasowe ${race.name}',
              senderRole: 'Akredytowane Media Międzynarodowe',
              subject: 'Zaproszenie na konferencję prasową przed ${race.name}',
              body: 'Dziennikarze L\'Équipe, La Gazzetta i Cyclingnews oczekują na odpowiedzi przed startem '
                  '${race.name}. Lider zespołu ${focalRider.fullName} weźmie udział w oficjalnym briefingu.',
              category: InboxCategory.general,
              priority: InboxPriority.urgent,
              actionLabel: 'Weź udział w konferencji',
            ),
          );
        }
      }
    }

    // 4E. Okresowe raporty skautów U23 (10. i 25. dzień miesiąca)
    if ((newDate.day == 10 || newDate.day == 25) &&
        triggeredKeys.add('u23_scout_${newDate.year}_${newDate.month}_${newDate.day}')) {
      final pTeam = updatedTeams.firstWhere(
        (t) => t.id == current.playerTeamId,
        orElse: () => current.playerTeam,
      );
      final prospects = ScoutingAndYouthAcademyService.generateInitialScoutingPool(
        seasonYear: newDate.year,
        count: pTeam.staff.scoutsLevel >= 80 ? 3 : 2,
        random: rng,
      );
      if (prospects.isNotEmpty) {
        final topProspect = prospects.first;
        updatedSave = updatedSave.copyWith(
          scoutingProspects: [...prospects, ...updatedSave.scoutingProspects].take(25).toList(),
        );
        newInboxMessages.insert(
          0,
          CareerInboxMessage(
            id: 'msg_u23_scout_${newDate.millisecondsSinceEpoch}',
            date: newDate,
            senderName: 'Szef Skautingu U23',
            senderRole: 'Akademia Młodzieżowa & Scouting',
            subject: 'Nowy raport skautów U23: ${topProspect.fullName} (${topProspect.nationalityIso})',
            body: 'Nasi obserwatorzy wypatrzyli ${prospects.length} obiecujących kolarzy U23. '
                'Wyróżnia się ${topProspect.fullName} (wiek ${topProspect.age} l., szac. FTP: '
                '${topProspect.estimatedMinFtpWatts}-${topProspect.estimatedMaxFtpWatts} W). '
                '${topProspect.scoutReport}',
            category: InboxCategory.general,
            priority: InboxPriority.normal,
            actionLabel: 'Otwórz Akademię U23',
          ),
        );
      }
    }

    // 4F. Miesięczne rozliczenie pensji, transz sponsorskich i rozwoju Akademii U23 (1. dzień miesiąca)
    if (newDate.day == 1) {
      updatedSave = updatedSave.copyWith(
        currentDate: newDate,
        teams: updatedTeams,
        riders: updatedRiders,
        calendar: updatedCalendar,
        financeLedger: updatedLedger,
      );
      updatedSave = FinanceAndBudgetService.processMonthlySettlement(save: updatedSave);
      updatedSave = ScoutingAndYouthAcademyService.processMonthlyAcademyDevelopment(save: updatedSave);
      updatedTeams = List<CyclingTeam>.from(updatedSave.teams);
      updatedLedger = List<CareerFinanceLedgerEntry>.from(updatedSave.financeLedger);

      final updatedPlayerTeam = updatedTeams.firstWhere(
        (t) => t.id == current.playerTeamId,
        orElse: () => current.playerTeam,
      );

      newInboxMessages.insert(
        0,
        CareerInboxMessage(
          id: 'msg_fin_${newDate.millisecondsSinceEpoch}',
          date: newDate,
          senderName: 'Dyrektor Finansowy (CFO)',
          senderRole: 'Dział Finansów i Księgowości',
          subject: 'Miesięczne rozliczenie budżetu - ${newDate.month}/${newDate.year}',
          body: 'Zaksięgowano comiesięczne transze sponsorskie, wypłacono pensje kolarzy i sztabu oraz '
              'pokryto koszty operacyjne bazy. Bieżące saldo klubu: '
              '€${(updatedPlayerTeam.cashBalanceEur / 1000000).toStringAsFixed(2)} mln.',
          category: InboxCategory.finance,
          priority: InboxPriority.normal,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // 5. KALENDARZ WYŚCIGÓW I STARTY DRUŻYNY GRACZA
    // -------------------------------------------------------------------------
    TourRace? raceToday;
    RaceStage? stageToday;
    bool isRaceDay = false;

    for (final race in updatedCalendar.races) {
      if (updatedCalendar.isRaceCompleted(race.id)) continue;

      final raceStart = DateTime(newDate.year, race.startMonth, race.startDay);
      final raceEnd = raceStart.add(Duration(days: race.stages.isNotEmpty ? race.stages.length - 1 : 0));
      final bool isWithinDates = !newDate.isBefore(raceStart) && !newDate.isAfter(raceEnd);

      if (isWithinDates && race.participatingTeamIds.contains(current.playerTeamId)) {
        raceToday = race;
        isRaceDay = true;

        final int dayOffset = newDate.difference(raceStart).inDays;
        final int stageIdx = dayOffset.clamp(0, race.stages.length - 1);
        stageToday = race.stages.isNotEmpty ? race.stages[stageIdx] : null;

        updatedCalendar = updatedCalendar.copyWith(
          activeRaceId: race.id,
          activeStageIndex: stageIdx,
        );

        if (stageToday != null) {
          newInboxMessages.insert(
            0,
            CareerInboxMessage(
              id: 'msg_race_${race.id}_${stageToday.stageNumber}_${newDate.millisecondsSinceEpoch}',
              date: newDate,
              senderName: 'Dyrektor Sportowy',
              senderRole: 'Sztab Taktyczny Zespołu',
              subject: 'Dziś dzień wyścigu: ${race.name} - Etap ${stageToday.stageNumber}',
              body: 'Dziś nasza drużyna staje na starcie etapu ${stageToday.stageNumber} w ${race.name}! '
                  'Dystans: ${stageToday.distanceKm.toStringAsFixed(1)} km, profil: ${stageToday.profile.name}.',
              category: InboxCategory.raceBriefing,
              priority: InboxPriority.urgent,
              actionLabel: 'Przejdź do Odprawy',
            ),
          );
        }
        break;
      }
    }

    if (!isRaceDay) {
      updatedCalendar = updatedCalendar.copyWith(
        activeRaceId: null,
        activeStageIndex: 0,
      );
    }

    // 5b. Codzienne wiadomości mediów kolarskich i wpisy społecznościowe kolarzy
    final newlyCompletedRaces = updatedCalendar.raceHistory.entries
        .where((e) => !current.calendar.raceHistory.containsKey(e.key))
        .map((e) => e.value)
        .toList();
    final dailyNews = const SocialMediaAndCyclingNewsService().generateDailyFeed(
      currentDate: newDate,
      calendar: updatedCalendar,
      teams: updatedTeams,
      riders: updatedRiders,
      playerTeamId: current.playerTeamId,
      recentTransfers: updatedTransferNews,
      newlyCompletedRaces: newlyCompletedRaces,
    );
    final updatedNewsFeed = [...dailyNews, ...current.newsFeed];
    if (updatedNewsFeed.length > 45) {
      updatedNewsFeed.removeRange(45, updatedNewsFeed.length);
    }

    // -------------------------------------------------------------------------
    // 6. ZŁOŻENIE NOWEGO STANU
    // -------------------------------------------------------------------------
    final updatedPlayerTeam = updatedTeams.firstWhere(
      (t) => t.id == current.playerTeamId,
      orElse: () => current.playerTeam,
    );

    final nextSave = updatedSave.copyWith(
      currentDate: newDate,
      currentSeasonYear: newDate.year,
      teams: updatedTeams,
      riders: updatedRiders,
      calendar: updatedCalendar,
      financeLedger: updatedLedger,
      lastSavedAt: DateTime.now(),
    );

    return current.copyWith(
      currentDate: newDate,
      currentSeasonYear: newDate.year,
      playerTeam: updatedPlayerTeam,
      riders: updatedRiders,
      teams: updatedTeams,
      calendar: updatedCalendar,
      financeLedger: updatedLedger,
      inboxMessages: newInboxMessages,
      activeRaceToday: raceToday,
      activeStageToday: stageToday,
      clearActiveRace: !isRaceDay,
      clearActiveStage: !isRaceDay,
      isRaceDayForPlayerTeam: isRaceDay,
      activeTrainingCamps: remainingCamps,
      scheduledRecoverySessions: remainingRecoverySessions,
      recentTransferNews: updatedTransferNews,
      pendingPressConferences: updatedPressConferences,
      recentAntiDopingResults: updatedDopingResults,
      triggeredOneTimeEventKeys: triggeredKeys,
      rawSave: nextSave,
      newsFeed: updatedNewsFeed,
    );
  }

  /// Symuluje w tle wyścigi AI (bez udziału drużyny gracza), które dobiegły końca
  /// w dniu `date`, aktualizując punkty UCI drużyn i kolarzy oraz historię sezonu.
  ({
    SeasonCalendar calendar,
    List<CyclingTeam> teams,
    List<Rider> riders,
    List<CareerInboxMessage> newsMessages,
  }) _simulateCompletedNonPlayerRaces({
    required DateTime date,
    required String playerTeamId,
    required SeasonCalendar calendar,
    required List<CyclingTeam> teams,
    required List<Rider> riders,
    required math.Random rng,
  }) {
    var currentCalendar = calendar;
    final workingTeams = List<CyclingTeam>.from(teams);
    final workingRiders = List<Rider>.from(riders);
    final newsMessages = <CareerInboxMessage>[];

    final Map<String, int> teamIndexById = {
      for (int i = 0; i < workingTeams.length; i++) workingTeams[i].id: i,
    };
    final Map<String, int> riderIndexById = {
      for (int i = 0; i < workingRiders.length; i++) workingRiders[i].id: i,
    };

    for (final race in calendar.races) {
      if (currentCalendar.isRaceCompleted(race.id)) continue;
      if (race.participatingTeamIds.contains(playerTeamId)) continue;

      final raceStart = DateTime(date.year, race.startMonth, race.startDay);
      final raceEnd = raceStart.add(Duration(days: race.stages.isNotEmpty ? race.stages.length - 1 : 0));

      if (date.isBefore(raceEnd)) continue;

      // Zbierz kandydatów ze startujących drużyn AI
      final List<Rider> contenders = [];
      for (final tId in race.participatingTeamIds) {
        final tIdx = teamIndexById[tId];
        if (tIdx == null) continue;
        final team = workingTeams[tIdx];
        for (final rId in team.rosterRiderIds) {
          final rIdx = riderIndexById[rId];
          if (rIdx != null && workingRiders[rIdx].health.isFitToRace) {
            contenders.add(workingRiders[rIdx]);
          }
        }
      }

      if (contenders.isEmpty) {
        final updatedCompleted = [...currentCalendar.completedRaceIds, race.id];
        currentCalendar = currentCalendar.copyWith(completedRaceIds: updatedCompleted);
        continue;
      }

      // Ocena formy i losowości dla wyniku wyścigu AI
      final scored = contenders.map((r) {
        final double formBonus = (r.health.trainingStressBalance * 0.25).clamp(-8.0, 10.0);
        final double noise = (rng.nextDouble() - 0.5) * 14.0;
        return (rider: r, score: r.overallRating + formBonus + noise);
      }).toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      final List<int> uciPointsTable = _uciPointsForCategory(race.uciCategory);
      final int awardCount = math.min(uciPointsTable.length, scored.length);

      for (int i = 0; i < awardCount; i++) {
        final r = scored[i].rider;
        final int pts = uciPointsTable[i];
        final rIdx = riderIndexById[r.id];
        if (rIdx != null) {
          workingRiders[rIdx] = workingRiders[rIdx].copyWith(
            careerPointsUci: workingRiders[rIdx].careerPointsUci + pts,
          );
        }
        // Znajdź drużynę kolarza i dopisz punkty UCI drużynie
        for (final tId in race.participatingTeamIds) {
          final tIdx = teamIndexById[tId];
          if (tIdx != null && workingTeams[tIdx].rosterRiderIds.contains(r.id)) {
            workingTeams[tIdx] = workingTeams[tIdx].copyWith(
              uciPointsSeason: workingTeams[tIdx].uciPointsSeason + pts,
            );
            break;
          }
        }
      }

      final winner = scored.first.rider;
      String winnerTeamId = '';
      String winnerTeamName = 'Zespół AI';
      for (final tId in race.participatingTeamIds) {
        final tIdx = teamIndexById[tId];
        if (tIdx != null && workingTeams[tIdx].rosterRiderIds.contains(winner.id)) {
          winnerTeamId = workingTeams[tIdx].id;
          winnerTeamName = workingTeams[tIdx].name;
          break;
        }
      }

      final historyEntry = RaceHistoryEntry(
        raceId: race.id,
        raceName: race.name,
        seasonYear: date.year,
        winnerRiderId: winner.id,
        winnerRiderName: winner.fullName,
        winnerTeamId: winnerTeamId,
        winnerTeamName: winnerTeamName,
        winnerTotalTimeSeconds: (race.totalRaceDistanceKm * 86).round().clamp(3600, 350000),
        completedDate: date,
      );

      final updatedCompleted = List<String>.from(currentCalendar.completedRaceIds)..add(race.id);
      final updatedHistory = Map<String, RaceHistoryEntry>.from(currentCalendar.raceHistory)
        ..[race.id] = historyEntry;

      currentCalendar = currentCalendar.copyWith(
        completedRaceIds: updatedCompleted,
        raceHistory: updatedHistory,
      );

      if (race.uciCategory == RaceCategory.grandTour ||
          race.uciCategory == RaceCategory.monument ||
          race.uciCategory == RaceCategory.worldTourStageRace) {
        newsMessages.add(
          CareerInboxMessage(
            id: 'msg_ai_res_${race.id}_${date.year}',
            date: date,
            senderName: 'Serwis Prasowy UCI',
            senderRole: 'Wyniki Światowego Peletonu',
            subject: '${winner.fullName} wygrywa ${race.name}!',
            body: 'Zakończyła się rywalizacja w ${race.name}. Zwycięstwo odniósł ${winner.fullName} '
                '($winnerTeamName), zdobywając ${uciPointsTable.first} pkt do rankingu UCI.',
            category: InboxCategory.raceResults,
            priority: InboxPriority.low,
          ),
        );
      }
    }

    return (
      calendar: currentCalendar,
      teams: workingTeams,
      riders: workingRiders,
      newsMessages: newsMessages,
    );
  }

  List<int> _uciPointsForCategory(RaceCategory category) {
    switch (category) {
      case RaceCategory.grandTour:
        return [1000, 800, 675, 575, 475, 400, 325, 275, 225, 175];
      case RaceCategory.monument:
        return [800, 640, 520, 440, 360, 280, 240, 200, 160, 135];
      case RaceCategory.worldTourStageRace:
        return [500, 400, 325, 275, 225, 175, 150, 125, 100, 85];
      case RaceCategory.worldTourOneDay:
        return [400, 320, 260, 220, 180, 140, 120, 100, 80, 68];
      case RaceCategory.proSeries:
        return [200, 150, 125, 100, 85, 70, 60, 50, 40, 35];
      case RaceCategory.class1:
        return [125, 85, 70, 60, 50, 40, 35, 30, 25, 20];
    }
  }

  (SimulationStopReason, String)? _evaluateStopCondition({
    required CareerState currentState,
    required int initialUnreadUrgentCount,
  }) {
    if (currentState.isRaceDayForPlayerTeam && currentState.activeRaceToday != null) {
      return (
        SimulationStopReason.raceDay,
        'Dzień startu wyścigu: ${currentState.activeRaceToday!.name}',
      );
    }

    final newUrgentMessages = currentState.inboxMessages
        .where((m) => !m.isRead && m.priority == InboxPriority.urgent)
        .toList();

    if (newUrgentMessages.length > initialUnreadUrgentCount) {
      final newestUrgent = newUrgentMessages.first;
      if (newestUrgent.category == InboxCategory.transferMarket) {
        return (
          SimulationStopReason.transferOffer,
          newestUrgent.subject,
        );
      }
      return (
        SimulationStopReason.urgentDecisionEmail,
        newestUrgent.subject,
      );
    }

    return null;
  }

  Future<void> _safePerformAutoSave({
    required CareerSave save,
    int? slotNumber,
  }) async {
    try {
      await SaveGameManager.performAutoSave(
        save: save,
        originatingSlotNumber: slotNumber,
      );
    } catch (_) {
      // Ignorujemy błędy zapisu w środowisku testowym bez pluginów platformowych
    }
  }

  // ===========================================================================
  // ZARZĄDZANIE SKRZYNKĄ ODBIORCZĄ (INBOX)
  // ===========================================================================

  /// Oznacza wybraną wiadomość jako przeczytaną
  void markMessageAsRead(String messageId) {
    final updated = state.inboxMessages.map((msg) {
      if (msg.id == messageId) {
        return msg.copyWith(isRead: true);
      }
      return msg;
    }).toList();

    state = state.copyWith(inboxMessages: updated);
  }

  /// Oznacza wszystkie wiadomości w skrzynce jako przeczytane
  void markAllMessagesAsRead() {
    final updated = state.inboxMessages.map((m) => m.copyWith(isRead: true)).toList();
    state = state.copyWith(inboxMessages: updated);
  }

  /// Usuwa wiadomość ze skrzynki odbiorczej
  void deleteInboxMessage(String messageId) {
    final updated = state.inboxMessages.where((m) => m.id != messageId).toList();
    state = state.copyWith(inboxMessages: updated);
  }

  /// Dodaje nową wiadomość do skrzynki odbiorczej
  void addInboxMessage(CareerInboxMessage message) {
    state = state.copyWith(
      inboxMessages: [message, ...state.inboxMessages],
    );
  }

  /// Przełącza polubienie wpisu w strumieniu mediów kolarskich
  void toggleNewsLike(String newsId) {
    final updated = state.newsFeed.map((item) {
      if (item.id != newsId) return item;
      final nextLiked = !item.isLikedByPlayer;
      return item.copyWith(
        isLikedByPlayer: nextLiked,
        likesCount: item.likesCount + (nextLiked ? 1 : -1),
      );
    }).toList();
    state = state.copyWith(newsFeed: updated);
  }

  /// Przełącza zakładkę (zapis) wpisu w strumieniu mediów kolarskich
  void toggleNewsBookmark(String newsId) {
    final updated = state.newsFeed.map((item) {
      if (item.id != newsId) return item;
      return item.copyWith(isBookmarked: !item.isBookmarked);
    }).toList();
    state = state.copyWith(newsFeed: updated);
  }

  /// Ręcznie odświeża lub dogenerowuje świeży przegląd mediów kolarskich
  void refreshDailyNewsFeed({int? seed}) {
    final fresh = const SocialMediaAndCyclingNewsService().generateDailyFeed(
      currentDate: state.currentDate,
      calendar: state.calendar,
      teams: state.teams,
      riders: state.riders,
      playerTeamId: state.playerTeamId,
      recentTransfers: state.recentTransferNews,
      seed: seed ?? DateTime.now().millisecondsSinceEpoch,
    );
    if (fresh.isEmpty) return;
    final merged = [...fresh, ...state.newsFeed];
    if (merged.length > 45) {
      merged.removeRange(45, merged.length);
    }
    state = state.copyWith(newsFeed: merged);
  }

  // ===========================================================================
  // SYSTEM ZAPISU I WCZYTYWANIA (SAVE / LOAD)
  // ===========================================================================

  /// Tworzy kompletnie nową karierę menedżerską w wybranym slocie.
  /// Obsługuje zespoły istniejące oraz własny zespół gracza (Custom Team).
  Future<bool> startNewCareer({
    required String saveName,
    required String playerManagerName,
    required String playerTeamId,
    CareerDifficulty difficulty = CareerDifficulty.normal,
    int seasonYear = 2026,
    int targetSlotNumber = 1,
    CyclingTeam? customTeam,
    List<Rider>? customRoster,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final newSave = await SaveService.createNewCareer(
        saveName: saveName,
        playerManagerName: playerManagerName,
        playerTeamId: playerTeamId,
        difficulty: difficulty,
        seasonYear: seasonYear,
        customTeam: customTeam,
        customRoster: customRoster,
      );

      await SaveGameManager.saveToSlot(
        slotNumber: targetSlotNumber,
        save: newSave,
      );

      state = CareerState.fromSave(
        newSave,
        activeSlotNumber: targetSlotNumber,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Błąd podczas tworzenia nowej kariery: $e',
      );
      return false;
    }
  }

  /// Ładuje stan kariery z wybranego slotu (1-5)
  Future<bool> loadFromSlot(int slotNumber) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final loadedSave = await SaveGameManager.loadFromSlot(slotNumber);
      if (loadedSave != null) {
        state = CareerState.fromSave(
          loadedSave,
          activeSlotNumber: slotNumber,
          previousInboxMessages: state.inboxMessages,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Slot #$slotNumber jest pusty lub uszkodzony.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Błąd ładowania slotu #$slotNumber: $e',
      );
      return false;
    }
  }

  /// Ładuje stan kariery ze slotu Auto-Save
  Future<bool> loadAutoSave() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final loadedSave = await SaveGameManager.loadAutoSave();
      if (loadedSave != null) {
        state = CareerState.fromSave(
          loadedSave,
          activeSlotNumber: 0,
          previousInboxMessages: state.inboxMessages,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Brak pliku Auto-Save na dysku.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Błąd wczytywania Auto-Save: $e',
      );
      return false;
    }
  }

  /// Zapisuje bieżący stan kariery do wybranego slotu (1-5)
  Future<SaveSlotInfo?> saveToSlot(int slotNumber, {String? customSaveName}) async {
    try {
      final save = state.toSave();
      final info = await SaveGameManager.saveToSlot(
        slotNumber: slotNumber,
        save: save,
        customSaveName: customSaveName,
      );
      state = state.copyWith(activeSlotNumber: slotNumber, rawSave: save);
      return info;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Nie udało się zapisać do slotu #$slotNumber: $e');
      return null;
    }
  }

  /// Inicjalizuje stan z istniejącego obiektu CareerSave
  void loadFromCareerSave(CareerSave save, {int? slotNumber}) {
    state = CareerState.fromSave(
      save,
      activeSlotNumber: slotNumber ?? state.activeSlotNumber,
      previousInboxMessages: state.inboxMessages,
    );
  }
}

/// Globalny dostawca Riverpod dla głównego kontrolera stanu kariery
final careerStateNotifierProvider =
    StateNotifierProvider<CareerStateNotifier, CareerState>((ref) {
  return CareerStateNotifier();
});
