import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/career/career_save.dart';
import '../models/career/season_calendar.dart';
import '../models/race/race_stage.dart';
import '../models/race/tour_race.dart';
import '../models/rider/rider.dart';
import '../models/team/bike_manufacturer_deal.dart';
import '../models/team/cycling_team.dart';
import '../services/career/finance_and_budget_service.dart';
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

  /// Przesuwa czas w grze o 1 dzień (`advanceDay`).
  ///
  /// W trakcie kroku dobowego:
  /// 1. Przesuwa datę o 1 dzień do przodu.
  /// 2. Przeprowadza proces leczenia kontuzji z bonusem poziomu Centrum Medycznego.
  /// 3. Aktualizuje parametry zmęczenia (ATL) i formy (CTL) oraz superkompensacji.
  /// 4. W 1. dniu każdego miesiąca przetwarza finanse klubowe (transze sponsorskie, pensje, baza logistyczna).
  /// 5. Weryfikuje kalendarz wyścigowy pod kątem startów drużyny gracza w danym dniu.
  /// 6. Generuje powiadomienia w skrzynce odbiorczej (Inbox) od lekarza, dyrektora sportowego i sponsora.
  /// 7. Wykonuje automatyczny zapis stanu gry (Auto-Save).
  Future<void> advanceDay() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final newDate = state.currentDate.add(const Duration(days: 1));
      final bool isFirstDayOfMonth = newDate.day == 1;

      final currentSave = state.rawSave;
      final int medCenterLevel = currentSave?.medicalCenterLevel ?? 1;
      final int doctorsLevel = state.playerTeam.staff.doctorsLevel;

      final List<CareerInboxMessage> newInboxMessages = List.from(state.inboxMessages);

      // =======================================================================
      // 1. LECZENIE KONTUZJI & REGENERACJA ZMĘCZENIA (TSB / ATL / CTL)
      // =======================================================================
      final updatedRiders = state.riders.map((rider) {
        final bool isPlayerRider = state.playerTeam.rosterRiderIds.contains(rider.id);
        var health = rider.health;

        // A. Leczenie kontuzji
        if (health.currentInjury != null) {
          final injury = health.currentInjury!;

          // Bonus Centrum Medycznego i lekarza zespołu:
          int daysHealed = 1;
          if (isPlayerRider && medCenterLevel >= 4 && doctorsLevel >= 80) {
            daysHealed = 2; // Poziom 4-5 przyspiesza rekonwalescencję
          }

          final int remainingDays = injury.daysRemaining - daysHealed;

          if (remainingDays <= 0) {
            // Kontuzja całkowicie wyleczona!
            health = health.copyWith(
              clearInjury: true,
            );

            if (isPlayerRider) {
              newInboxMessages.insert(
                0,
                CareerInboxMessage(
                  id: 'msg_healed_${rider.id}_${newDate.millisecondsSinceEpoch}',
                  date: newDate,
                  senderName: 'Dr. Roberto Ferrari',
                  senderRole: 'Główny Lekarz Zespołu',
                  subject: 'Kolarz ${rider.fullName} zakończył rehabilitację!',
                  body: 'Z przyjemnością informuję, że ${rider.fullName} wyleczył uraz (${injury.name}) '
                      'i po pomyślnym przejściu badań w Centrum Medycznym (poziom $medCenterLevel) '
                      'otrzymał pełną zgodę na starty oraz intensywny trening.',
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

        // B. Regeneracja zmęczenia (ATL) i formy (CTL)
        // Zmęczenie krótkoterminowe (ATL) bez wyścigu spada o ~12% dziennie
        final double decayAtl = (health.acuteTrainingLoad * 0.88).clamp(0.0, 250.0);
        // Forma długoterminowa (CTL) spada o ~1.5% dziennie
        final double decayCtl = (health.chronicTrainingLoad * 0.985).clamp(15.0, 160.0);

        // C. Naturalny rozwój formy tlenowej u młodych kolarzy
        var power = rider.powerProfile;
        var physio = rider.physiology;

        if (health.isFitToRace && rider.age <= 28 && isPlayerRider) {
          final double ftpGain = 0.02 * (rider.potential / 100.0);
          power = power.copyWith(
            functionalThresholdPowerWatts: (power.functionalThresholdPowerWatts + ftpGain).round(),
          );
          physio = physio.copyWith(
            criticalPowerWatts: (physio.criticalPowerWatts + ftpGain).round(),
          );
        }

        return rider.copyWith(
          health: health.copyWith(
            acuteTrainingLoad: decayAtl,
            chronicTrainingLoad: decayCtl,
          ),
          powerProfile: power,
          physiology: physio,
        );
      }).toList();

      // =======================================================================
      // 2. MIESIĘCZNE ROZLICZENIE FINANSÓW (1. DZIEŃ MIESIĄCA)
      // =======================================================================
      var updatedTeams = state.teams;
      var updatedLedger = state.financeLedger;
      var updatedSave = currentSave;

      if (isFirstDayOfMonth && updatedSave != null) {
        updatedSave = FinanceAndBudgetService.processMonthlySettlement(save: updatedSave);
        updatedTeams = updatedSave.teams;
        updatedLedger = updatedSave.financeLedger;

        final updatedPlayerTeam = updatedTeams.firstWhere(
          (t) => t.id == state.playerTeamId,
          orElse: () => state.playerTeam,
        );

        newInboxMessages.insert(
          0,
          CareerInboxMessage(
            id: 'msg_fin_${newDate.millisecondsSinceEpoch}',
            date: newDate,
            senderName: 'Dyrektor Finansowy (CFO)',
            senderRole: 'Dział Finansów i Księgowości',
            subject: 'Miesięczny raport finansowy - ${newDate.month}/${newDate.year}',
            body: 'Zrealizowano comiesięczne rozliczenie budżetu klubu: zaksięgowano transze sponsorskie, '
                'wypłacono pensje kolarzy i sztabu szkoleniowego oraz opłacono koszty logistyki i bazy Service Course. '
                'Bieżący stan konta drużyny: €${(updatedPlayerTeam.cashBalanceEur / 1000000).toStringAsFixed(2)} mln.',
            category: InboxCategory.finance,
            priority: InboxPriority.normal,
          ),
        );
      }

      // =======================================================================
      // 3. KALENDARZ WYŚCIGÓW I STARTY DRUŻYNY GRACZA
      // =======================================================================
      TourRace? raceToday;
      RaceStage? stageToday;
      bool isRaceDay = false;
      var updatedCalendar = state.calendar;

      for (final race in updatedCalendar.races) {
        if (race.isCompleted) continue;

        // Czy dzisiejsza data mieści się w oknie wyścigu
        final bool isWithinDates =
            !newDate.isBefore(race.startDate) && !newDate.isAfter(race.endDate);

        if (isWithinDates) {
          final bool teamParticipates = race.participatingTeamIds.contains(state.playerTeamId);

          if (teamParticipates) {
            raceToday = race;
            isRaceDay = true;

            // Wyznaczamy etap na podstawie przesunięcia dni od startu wyścigu
            final int dayOffset = newDate.difference(race.startDate).inDays;
            final int stageIdx = dayOffset.clamp(0, race.stages.length - 1);
            stageToday = race.stages[stageIdx];

            updatedCalendar = updatedCalendar.copyWith(
              activeRaceId: race.id,
              activeStageIndex: stageIdx,
            );

            // Odprawa taktyczna od Dyrektora Sportowego
            newInboxMessages.insert(
              0,
              CareerInboxMessage(
                id: 'msg_race_${race.id}_${stageToday.stageNumber}_${newDate.millisecondsSinceEpoch}',
                date: newDate,
                senderName: 'Dyrektor Sportowy',
                senderRole: 'Sztab Taktyczny Zespołu',
                subject: 'Dziś dzień wyścigu: ${race.name} - Etap ${stageToday.stageNumber}',
                body: 'Dziś nasza drużyna ${state.playerTeam.name} staje na starcie etapu ${stageToday.stageNumber} '
                    'w ${race.name}! Dystans: ${stageToday.distanceKm.toStringAsFixed(1)} km, '
                    'Profil trasy: ${stageToday.profile.name}. Liderzy są zmotywowani i gotowi do walki o punkty UCI!',
                category: InboxCategory.raceBriefing,
                priority: InboxPriority.urgent,
              ),
            );
            break;
          }
        }
      }

      if (!isRaceDay) {
        updatedCalendar = updatedCalendar.copyWith(
          activeRaceId: null,
          activeStageIndex: 0,
        );
      }

      // =======================================================================
      // 4. SYNCHRONIZACJA ZAPISU I AUTO-SAVE
      // =======================================================================
      final updatedPlayerTeam = updatedTeams.firstWhere(
        (t) => t.id == state.playerTeamId,
        orElse: () => state.playerTeam,
      );

      final nextSave = (updatedSave ?? state.rawSave ?? state.toSave()).copyWith(
        currentDate: newDate,
        teams: updatedTeams,
        riders: updatedRiders,
        calendar: updatedCalendar,
        financeLedger: updatedLedger,
        lastSavedAt: DateTime.now(),
      );

      // Zapisujemy automatycznie w slocie Auto-Save
      await SaveGameManager.performAutoSave(
        save: nextSave,
        originatingSlotNumber: state.activeSlotNumber,
      );

      // =======================================================================
      // 5. EMISJA ZAKTUALIZOWANEGO STANU
      // =======================================================================
      state = state.copyWith(
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
        isLoading: false,
        rawSave: nextSave,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Błąd podczas przesuwania dnia w kalendarzu: $e',
      );
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
