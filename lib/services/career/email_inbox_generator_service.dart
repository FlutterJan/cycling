// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

/// Kategoria wiadomości e-mail w skrzynce menedżera drużyny kolarskiej.
enum EmailCategory {
  /// Oficjalne zaproszenia na wyścigi (Dzikie Karty / Wildcard, WorldTour, ProSeries)
  raceInvitation,

  /// Raporty medyczne lekarza zespołu (kraksy, złamania, powrót do zdrowia, komora hiperbaryczna)
  medicalReport,

  /// Rynek transferowy, oferty wykupu (buyout fee), zapytania od agentów kolarzy
  transferOffer,

  /// Obozy przygotowawcze i fizjologia (Sierra Nevada, Teide, Livigno, testy wydolnościowe)
  trainingAndCamp,

  /// Relacje ze sponsorem tytularnym i radą nadzorczą (budżet, cele, zadowolenie)
  sponsorAndBoard,

  /// Psychologia, ego i relacje z kolarzami (frustracja brakiem startu, bunty liderów)
  riderRelations,

  /// Zespół młodzieżowy U23 i skauting orlików (Devo Squad, raporty talentów)
  youthDevelopment,

  /// Sprzęt, innowacje technologiczne i dostawcy (aerodynamika, koła TT, odzież, ramy)
  equipmentAndTech,

  /// Nadzór antydopingowy UCI, system Whereabouts ADAMS i wyłączenia TUE
  antiDopingAndAdams,

  /// Relacje z mediami, dziennikarze (L'Équipe, Gazzetta), konferencje prasowe
  pressAndMedia;

  String toJson() => name;

  static EmailCategory fromJson(String value) {
    return EmailCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EmailCategory.sponsorAndBoard,
    );
  }

  String get displayName {
    switch (this) {
      case EmailCategory.raceInvitation:
        return 'Zaproszenia na Wyścigi';
      case EmailCategory.medicalReport:
        return 'Raporty Medyczne';
      case EmailCategory.transferOffer:
        return 'Rynek Transferowy';
      case EmailCategory.trainingAndCamp:
        return 'Treningi i Obozy';
      case EmailCategory.sponsorAndBoard:
        return 'Zarząd i Sponsorzy';
      case EmailCategory.riderRelations:
        return 'Relacje z Kolarzami';
      case EmailCategory.youthDevelopment:
        return 'Młodzież U23 / Devo';
      case EmailCategory.equipmentAndTech:
        return 'Sprzęt i Technologia';
      case EmailCategory.antiDopingAndAdams:
        return 'UCI / ADAMS';
      case EmailCategory.pressAndMedia:
        return 'Media i Prasa';
    }
  }
}

/// Priorytet wiadomości e-mail w skrzynce odbiorczej.
enum EmailPriority {
  low,
  normal,
  high,
  urgent;

  String toJson() => name;

  static EmailPriority fromJson(String value) {
    return EmailPriority.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EmailPriority.normal,
    );
  }

  String get displayName {
    switch (this) {
      case EmailPriority.low:
        return 'Niski';
      case EmailPriority.normal:
        return 'Standardowy';
      case EmailPriority.high:
        return 'Wysoki';
      case EmailPriority.urgent:
        return 'PILNE';
    }
  }
}

/// Typ interaktywnej akcji osadzonej bezpośrednio w wiadomości e-mail.
enum EmailActionType {
  /// Zaakceptowanie oficjalnego zaproszenia na wyścig (Wildcard)
  acceptRaceInvitation,

  /// Odrzucenie zaproszenia na wyścig
  declineRaceInvitation,

  /// Otwarcie szczegółowego raportu lekarskiego po kraksie
  viewMedicalReport,

  /// Zatwierdzenie kosztownej kuracji medycznej (np. komora hiperbaryczna / przyspieszona fizjoterapia)
  authorizeMedicalTreatment,

  /// Wycofanie kontuzjowanego kolarza ze startów
  withdrawRiderFromRaces,

  /// Zaakceptowanie oferty wykupu kolarza przez konkurencyjny zespół
  acceptTransferOffer,

  /// Odrzucenie oferty wykupu kolarza
  rejectTransferOffer,

  /// Kontroferta / żądanie podbicia kwoty odstępnego
  counterTransferOffer,

  /// Zatwierdzenie budżetu na obóz wysokogórski (np. Sierra Nevada)
  approveCampBudget,

  /// Odrzucenie wniosku o obóz wysokogórski
  rejectCampBudget,

  /// Wybór tańszego wariantu obozu
  chooseEconomyCamp,

  /// Zwołanie pilnej rozmowy indywidualnej z kolarzem
  scheduleRiderMeeting,

  /// Nałożenie kary finansowej / upomnienia na zbuntowanego kolarza
  penalizeRider,

  /// Podpisanie kontraktu z utalentowanym orlikiem do Devo Teamu
  signDevoRider,

  /// Wysłanie młodego talentu na testy w tunelu aerodynamicznym
  scoutLabTesting,

  /// Zamówienie ulepszonego pakietu technologicznego (koła TT, kierownice aero)
  orderEquipmentUpgrade,

  /// Zatwierdzenie protokołu kontroli antydopingowej UCI
  acknowledgeAntiDopingNotice,

  /// Złożenie oświadczenia prasowego / udział w wywiadzie
  respondToPress,

  /// Zwykłe potwierdzenie zapoznania się z treścią / archiwizacja
  acknowledge,

  /// Akcja niestandardowa
  customAction;

  String toJson() => name;

  static EmailActionType fromJson(String value) {
    return EmailActionType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EmailActionType.acknowledge,
    );
  }
}

/// Styl wizualny przycisku akcji w e-mailu.
enum EmailActionButtonStyle {
  primary,
  secondary,
  success,
  danger,
  warning;

  String toJson() => name;

  static EmailActionButtonStyle fromJson(String value) {
    return EmailActionButtonStyle.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EmailActionButtonStyle.primary,
    );
  }
}

/// Status wykonania interaktywnej akcji w mailu.
enum InboxActionStatus {
  /// Oczekuje na decyzję gracza
  pending,

  /// Akcja została pomyślnie wykonana przez gracza
  completed,

  /// Akcja została odrzucona przez gracza
  rejected,

  /// Akcja wygasła (minął termin ważności oferty/zaproszenia)
  expired,

  /// Zdezaktualizowana po wybraniu innej, wykluczającej akcji w tym samym mailu
  disabled;

  String toJson() => name;

  static InboxActionStatus fromJson(String value) {
    return InboxActionStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => InboxActionStatus.pending,
    );
  }
}

/// Model interaktywnego przycisku akcji osadzonego w wiadomości pocztowej.
class InboxEmailAction {
  final String actionId;
  final String label;
  final EmailActionType actionType;
  final EmailActionButtonStyle style;
  final String iconKey;
  final Map<String, dynamic> payload;
  final InboxActionStatus status;
  final String? resultMessage;
  final DateTime? executedAt;

  const InboxEmailAction({
    required this.actionId,
    required this.label,
    required this.actionType,
    this.style = EmailActionButtonStyle.primary,
    this.iconKey = 'check_circle',
    this.payload = const {},
    this.status = InboxActionStatus.pending,
    this.resultMessage,
    this.executedAt,
  });

  bool get isPending => status == InboxActionStatus.pending;
  bool get isCompleted => status == InboxActionStatus.completed;
  bool get isDisabled => status == InboxActionStatus.disabled;

  InboxEmailAction copyWith({
    String? actionId,
    String? label,
    EmailActionType? actionType,
    EmailActionButtonStyle? style,
    String? iconKey,
    Map<String, dynamic>? payload,
    InboxActionStatus? status,
    String? resultMessage,
    DateTime? executedAt,
  }) {
    return InboxEmailAction(
      actionId: actionId ?? this.actionId,
      label: label ?? this.label,
      actionType: actionType ?? this.actionType,
      style: style ?? this.style,
      iconKey: iconKey ?? this.iconKey,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      resultMessage: resultMessage ?? this.resultMessage,
      executedAt: executedAt ?? this.executedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'actionId': actionId,
      'label': label,
      'actionType': actionType.toJson(),
      'style': style.toJson(),
      'iconKey': iconKey,
      'payload': payload,
      'status': status.toJson(),
      'resultMessage': resultMessage,
      'executedAt': executedAt?.toIso8601String(),
    };
  }

  factory InboxEmailAction.fromJson(Map<String, dynamic> json) {
    return InboxEmailAction(
      actionId: json['actionId'] as String,
      label: json['label'] as String,
      actionType: EmailActionType.fromJson(json['actionType'] as String),
      style: EmailActionButtonStyle.fromJson(json['style'] as String? ?? 'primary'),
      iconKey: json['iconKey'] as String? ?? 'check_circle',
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      status: InboxActionStatus.fromJson(json['status'] as String? ?? 'pending'),
      resultMessage: json['resultMessage'] as String?,
      executedAt: json['executedAt'] != null ? DateTime.parse(json['executedAt'] as String) : null,
    );
  }
}

/// Model kompletnej, interaktywnej wiadomości pocztowej w skrzynce menedżera.
class InboxEmailMessage {
  final String id;
  final String senderName;
  final String senderRole;
  final String senderAvatar;
  final String subject;
  final String bodyText;
  final EmailCategory category;
  final EmailPriority priority;
  final DateTime sentDate;
  final bool isRead;
  final bool isStarred;
  final bool isArchived;
  final bool requiresImmediateAction;
  final DateTime? expiryDate;
  final List<InboxEmailAction> actions;
  final Map<String, dynamic> metadata;

  const InboxEmailMessage({
    required this.id,
    required this.senderName,
    required this.senderRole,
    this.senderAvatar = 'mail',
    required this.subject,
    required this.bodyText,
    required this.category,
    this.priority = EmailPriority.normal,
    required this.sentDate,
    this.isRead = false,
    this.isStarred = false,
    this.isArchived = false,
    this.requiresImmediateAction = false,
    this.expiryDate,
    this.actions = const [],
    this.metadata = const {},
  });

  bool get hasPendingActions => actions.any((a) => a.isPending);

  bool isActionCompleted(String actionId) {
    return actions.any((a) => a.actionId == actionId && a.isCompleted);
  }

  InboxEmailMessage copyWith({
    String? id,
    String? senderName,
    String? senderRole,
    String? senderAvatar,
    String? subject,
    String? bodyText,
    EmailCategory? category,
    EmailPriority? priority,
    DateTime? sentDate,
    bool? isRead,
    bool? isStarred,
    bool? isArchived,
    bool? requiresImmediateAction,
    DateTime? expiryDate,
    List<InboxEmailAction>? actions,
    Map<String, dynamic>? metadata,
  }) {
    return InboxEmailMessage(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      subject: subject ?? this.subject,
      bodyText: bodyText ?? this.bodyText,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      sentDate: sentDate ?? this.sentDate,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      isArchived: isArchived ?? this.isArchived,
      requiresImmediateAction: requiresImmediateAction ?? this.requiresImmediateAction,
      expiryDate: expiryDate ?? this.expiryDate,
      actions: actions ?? this.actions,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderName': senderName,
      'senderRole': senderRole,
      'senderAvatar': senderAvatar,
      'subject': subject,
      'bodyText': bodyText,
      'category': category.toJson(),
      'priority': priority.toJson(),
      'sentDate': sentDate.toIso8601String(),
      'isRead': isRead,
      'isStarred': isStarred,
      'isArchived': isArchived,
      'requiresImmediateAction': requiresImmediateAction,
      'expiryDate': expiryDate?.toIso8601String(),
      'actions': actions.map((a) => a.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory InboxEmailMessage.fromJson(Map<String, dynamic> json) {
    return InboxEmailMessage(
      id: json['id'] as String,
      senderName: json['senderName'] as String,
      senderRole: json['senderRole'] as String,
      senderAvatar: json['senderAvatar'] as String? ?? 'mail',
      subject: json['subject'] as String,
      bodyText: json['bodyText'] as String,
      category: EmailCategory.fromJson(json['category'] as String),
      priority: EmailPriority.fromJson(json['priority'] as String? ?? 'normal'),
      sentDate: DateTime.parse(json['sentDate'] as String),
      isRead: json['isRead'] as bool? ?? false,
      isStarred: json['isStarred'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      requiresImmediateAction: json['requiresImmediateAction'] as bool? ?? false,
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate'] as String) : null,
      actions: (json['actions'] as List<dynamic>?)
              ?.map((a) => InboxEmailAction.fromJson(a as Map<String, dynamic>))
              .toList() ??
          const [],
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }
}

/// Wynik podjęcia interaktywnej akcji w e-mailu.
class EmailActionResult {
  final bool success;
  final String message;
  final String emailId;
  final String actionId;
  final EmailActionType actionType;
  final Map<String, dynamic> stateChanges;
  final DateTime timestamp;

  const EmailActionResult({
    required this.success,
    required this.message,
    required this.emailId,
    required this.actionId,
    required this.actionType,
    this.stateChanges = const {},
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'emailId': emailId,
      'actionId': actionId,
      'actionType': actionType.toJson(),
      'stateChanges': stateChanges,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Główny serwis generatora interaktywnej skrzynki odbiorczej (Inbox) menedżera.
class EmailInboxGeneratorService {
  final List<InboxEmailMessage> _emails = [];
  final math.Random _random;

  EmailInboxGeneratorService({
    List<InboxEmailMessage>? initialEmails,
    int? seed,
  }) : _random = math.Random(seed) {
    if (initialEmails != null) {
      _emails.addAll(initialEmails);
    }
  }

  /// Kopia listy wszystkich wiadomości w skrzynce.
  List<InboxEmailMessage> get emails => List.unmodifiable(_emails);

  /// Liczba nieprzeczytanych wiadomości.
  int get unreadCount => _emails.where((m) => !m.isRead && !m.isArchived).length;

  /// Liczba wiadomości pilnych wymagających natychmiastowej decyzji.
  int get urgentActionCount =>
      _emails.where((m) => m.requiresImmediateAction && m.hasPendingActions && !m.isArchived).length;

  /// Dodaje nową wiadomość na początek skrzynki odbiorczej.
  void addEmail(InboxEmailMessage email) {
    _emails.insert(0, email);
  }

  /// Oznacza wiadomość jako przeczytaną lub nieprzeczytaną.
  void markAsRead(String emailId, [bool read = true]) {
    final index = _emails.indexWhere((m) => m.id == emailId);
    if (index != -1) {
      _emails[index] = _emails[index].copyWith(isRead: read);
    }
  }

  /// Oznacza wszystkie wiadomości w skrzynce jako przeczytane.
  void markAllAsRead() {
    for (int i = 0; i < _emails.length; i++) {
      if (!_emails[i].isRead) {
        _emails[i] = _emails[i].copyWith(isRead: true);
      }
    }
  }

  /// Przełącza status wyróżnienia gwiazdką.
  void toggleStarred(String emailId) {
    final index = _emails.indexWhere((m) => m.id == emailId);
    if (index != -1) {
      _emails[index] = _emails[index].copyWith(isStarred: !_emails[index].isStarred);
    }
  }

  /// Przełącza status zarchiwizowania wiadomości.
  void toggleArchived(String emailId) {
    final index = _emails.indexWhere((m) => m.id == emailId);
    if (index != -1) {
      _emails[index] = _emails[index].copyWith(isArchived: !_emails[index].isArchived);
    }
  }

  /// Usuwa wiadomość ze skrzynki pocztowej.
  bool deleteEmail(String emailId) {
    final initialLen = _emails.length;
    _emails.removeWhere((m) => m.id == emailId);
    return _emails.length < initialLen;
  }

  /// Filtruje i przeszukuje wiadomości w skrzynce odbiorczej.
  List<InboxEmailMessage> getFilteredEmails({
    EmailCategory? category,
    bool? unreadOnly,
    bool? starredOnly,
    bool? archivedOnly,
    bool? requiresActionOnly,
    String? searchQuery,
  }) {
    return _emails.where((m) {
      if (archivedOnly == true && !m.isArchived) return false;
      if (archivedOnly != true && m.isArchived) return false;

      if (category != null && m.category != category) return false;
      if (unreadOnly == true && m.isRead) return false;
      if (starredOnly == true && !m.isStarred) return false;
      if (requiresActionOnly == true && !m.hasPendingActions) return false;

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.toLowerCase().trim();
        final matchesSubject = m.subject.toLowerCase().contains(query);
        final matchesSender = m.senderName.toLowerCase().contains(query);
        final matchesBody = m.bodyText.toLowerCase().contains(query);
        if (!matchesSubject && !matchesSender && !matchesBody) return false;
      }

      return true;
    }).toList();
  }

  // ===========================================================================
  // WYKONYWANIE INTERAKTYWNYCH AKCJI BEZPOŚREDNIO W MAILU
  // ===========================================================================

  /// Wykonuje interaktywną akcję zawartą w wiadomości.
  ///
  /// Zmienia stan akcji na [InboxActionStatus.completed] (lub [InboxActionStatus.rejected]),
  /// dezaktywuje wykluczające się akcje w tym samym mailu oraz zwraca [EmailActionResult]
  /// z informacją zwrotną i modyfikacjami stanu gry.
  EmailActionResult executeAction({
    required String emailId,
    required String actionId,
    Map<String, dynamic>? customParams,
  }) {
    final emailIndex = _emails.indexWhere((m) => m.id == emailId);
    if (emailIndex == -1) {
      return EmailActionResult(
        success: false,
        message: 'Nie odnaleziono wiadomości o ID: $emailId',
        emailId: emailId,
        actionId: actionId,
        actionType: EmailActionType.acknowledge,
        timestamp: DateTime.now(),
      );
    }

    final email = _emails[emailIndex];
    final actionIndex = email.actions.indexWhere((a) => a.actionId == actionId);
    if (actionIndex == -1) {
      return EmailActionResult(
        success: false,
        message: 'Nie odnaleziono akcji o ID: $actionId w tej wiadomości',
        emailId: emailId,
        actionId: actionId,
        actionType: EmailActionType.acknowledge,
        timestamp: DateTime.now(),
      );
    }

    final action = email.actions[actionIndex];
    if (action.status != InboxActionStatus.pending) {
      return EmailActionResult(
        success: false,
        message: 'Ta akcja została już podjęta lub wygasła (${action.status.name}).',
        emailId: emailId,
        actionId: actionId,
        actionType: action.actionType,
        timestamp: DateTime.now(),
      );
    }

    // Sprawdzenie czy termin ważności wiadomości nie upłynął
    final now = DateTime.now();
    if (email.expiryDate != null && now.isAfter(email.expiryDate!)) {
      final updatedActions = email.actions.map((a) {
        if (a.isPending) {
          return a.copyWith(status: InboxActionStatus.expired);
        }
        return a;
      }).toList();
      _emails[emailIndex] = email.copyWith(actions: updatedActions);

      return EmailActionResult(
        success: false,
        message: 'Termin na podjęcie decyzji upłynął (${email.expiryDate}). Oferta wygasła.',
        emailId: emailId,
        actionId: actionId,
        actionType: action.actionType,
        timestamp: now,
      );
    }

    // Wykonanie konkretnej akcji logicznej
    final result = _dispatchActionLogic(email, action, customParams, now);

    // Aktualizacja stanu akcji w mailu
    final updatedActions = email.actions.map((a) {
      if (a.actionId == actionId) {
        return a.copyWith(
          status: result.success ? InboxActionStatus.completed : InboxActionStatus.rejected,
          resultMessage: result.message,
          executedAt: now,
        );
      } else if (a.isPending) {
        // Dezaktywacja alternatywnych/wykluczających się przycisków w tym samym mailu
        return a.copyWith(
          status: InboxActionStatus.disabled,
          resultMessage: 'Zdezaktualizowano przez wybór innej opcji.',
        );
      }
      return a;
    }).toList();

    _emails[emailIndex] = email.copyWith(
      actions: updatedActions,
      isRead: true,
      requiresImmediateAction: false,
    );

    return result;
  }

  EmailActionResult _dispatchActionLogic(
    InboxEmailMessage email,
    InboxEmailAction action,
    Map<String, dynamic>? customParams,
    DateTime timestamp,
  ) {
    final payload = {...action.payload, ...?customParams};

    switch (action.actionType) {
      case EmailActionType.acceptRaceInvitation:
        final raceName = payload['raceName'] ?? 'Wyścig';
        final raceId = payload['raceId'] ?? 'race_unknown';
        return EmailActionResult(
          success: true,
          message: 'Pomyślnie zaakceptowano zaproszenie Wildcard na wyścig $raceName! Wyścig dodany do kalendarza.',
          emailId: email.id,
          actionId: action.actionId,
          actionType: action.actionType,
          stateChanges: {
            'action': 'race_invitation_accepted',
            'raceId': raceId,
            'raceName': raceName,
            'addedToCalendar': true,
          },
          timestamp: timestamp,
        );

      case EmailActionType.declineRaceInvitation:
        final raceName = payload['raceName'] ?? 'Wyścig';
        return EmailActionResult(
          success: true,
          message: 'Odrzucono zaproszenie na $raceName. Organizatorzy zostali powiadomieni.',
          emailId: email.id,
          actionId: action.actionId,
          actionType: action.actionType,
          stateChanges: {
            'action': 'race_invitation_declined',
            'raceName': raceName,
            'addedToCalendar': false,
          },
          timestamp: timestamp,
        );

      case EmailActionType.viewMedicalReport:
        final riderName = payload['riderName'] ?? 'Kolarz';
        final injuryType = payload['injuryType'] ?? 'Uraz';
        final daysOut = payload['daysOut'] ?? 7;
        return EmailActionResult(
          success: true,
          message: 'Otwarto kartę medyczną kolarza $riderName: $injuryType. Szacowana pauza: $daysOut dni.',
          emailId: email.id,
          actionId: action.actionId,
          actionType: action.actionType,
          stateChanges: {
            'action': 'view_medical_card',
            'riderId': payload['riderId'],
            'injuryType': injuryType,
            'daysOut': daysOut,
          },
          timestamp: timestamp,
        );

      case EmailActionType.authorizeMedicalTreatment:
        final costEur = payload['treatmentCostEur'] ?? 3500;
        final riderName = payload['riderName'] ?? 'Kolarz';
        final reducedDays = payload['reducedDays'] ?? 4;
        return EmailActionResult(
          success: true,
          message: 'Zatwierdzono terapię w komorze hiperbarycznej dla $riderName. Koszt: ${costEur.toString()} €. Czas rekonwalescencji skrócony o $reducedDays dni.',
          emailId: email.id,
          actionId: action.actionId,
          actionType: action.actionType,
          stateChanges: {
            'action': 'medical_treatment_authorized',
            'budgetDeltaEur': -costEur,
            'riderId': payload['riderId'],
            'daysReduced': reducedDays,
          },
          timestamp: timestamp,
        );

      case EmailActionType.withdrawRiderFromRaces:
        final riderName = payload['riderName'] ?? 'Kolarz';
        return EmailActionResult(
          success: true,
          message: '$riderName został oficjalnie wycofany ze zbliżających się wyścigów w celu pełnej regeneracji.',
          emailId: email.id,
          actionId: action.actionId,
          actionType: action.actionType,
          stateChanges: {
            'action': 'rider_withdrawn',
            'riderId': payload['riderId'],
          },
          timestamp: timestamp,
        );

      case EmailActionType.acceptTransferOffer:
        final riderName = payload['riderName'] ?? 'Kolarz';
        final buyoutFeeEur = payload['buyoutFeeEur'] ?? 500000;
        final buyingTeam = payload['buyingTeam'] ?? 'Rywale';
        return EmailActionResult(
          success: true,
          message: 'Zaakceptowano ofertę wykupu! $riderName przechodzi do $buyingTeam. Na konto wpłynęło ${buyoutFeeEur.toString()} €.',
          emailId: email.id,
          actionId: action.actionId,
          actionType: action.actionType,
          stateChanges: {
            'action': 'transfer_buyout_accepted',
            'riderId': payload['riderId'],
            'budgetDeltaEur': buyoutFeeEur,
            'buyingTeam': buyingTeam,
          },
          timestamp: timestamp,
        );

      case EmailActionType.rejectTransferOffer:
        final riderName = payload['riderName'] ?? 'Kolarz';
        final buyingTeam = payload['buyingTeam'] ?? 'Rywale';
        return EmailActionResult(
          success: true,
          message: 'Odrzucono ofertę transferową od $buyingTeam za kolarza $riderName.',
          emailId: email.id,
          actionId: action.actionId,
          actionType: action.actionType,
          stateChanges: {
            'action': 'transfer_offer_rejected',
            'riderId': payload['riderId'],
          },
          timestamp: timestamp,
        );

      case EmailActionType.counterTransferOffer:
        final riderName = payload['riderName'] ?? 'Kolarz';
        final originalFee = payload['buyoutFeeEur'] ?? 500000;
        final counterFee = (originalFee * 1.25).round();
        return EmailActionResult(
          success: true,
          message: 'Przesłano kontrofertę za $riderName: żądanie ${counterFee.toString()} € (+25%). Oczekujemy na odpowiedź.',
          emailId: email.id,
          actionId: action.actionId,
          actionType: action.actionType,
          stateChanges: {
            'action': 'counter_offer_sent',
            'riderId': payload['riderId'],
            'requestedFeeEur': counterFee,
          },
          timestamp: timestamp,
        );

      case EmailActionType.approveCampBudget:
        final campLocation = payload['location'] ?? 'Sierra Nevada';
        final costEur = payload['campCostEur'] ?? 42000;
        return EmailActionResult(
          success: true,
          message: 'Zatwierdzono budżet na obóz wysokogórski w $campLocation (${costEur.toString()} €). Zawodnicy rozpoczynają przygotowania!',
          emailId: email.id,
          actionId: action.actionId,
          actionType: action.actionType,
          stateChanges: {
            'action': 'camp_budget_approved',
            'budgetDeltaEur': -costEur,
            'campLocation': campLocation,
            'ftpBonusPct': payload['expectedFtpBonusPct'] ?? 3.5,
            'vamBonusPct': payload['expectedVamBonusPct'] ?? 5.0,
          },
          timestamp: timestamp,
        );

      case EmailActionType.chooseEconomyCamp:
        final campLocation = payload['economyLocation'] ?? 'Teide (Wariant Ekonomiczny)';
        final costEur = payload['economyCostEur'] ?? 29000;
        return EmailActionResult(
          success: true,
          message: 'Zatwierdzono oszczędnościowy wariant zgrupowania ($campLocation) za ${costEur.toString()} €.',
          emailId: email.id,
          actionId: action.actionId,
          actionType: action.actionType,
          stateChanges: {
            'action': 'camp_economy_approved',
            'budgetDeltaEur': -costEur,
            'campLocation': campLocation,
            'ftpBonusPct': 2.5,
          },
          timestamp: timestamp,
        );

      case EmailActionType.rejectCampBudget:
        return EmailActionResult(
          success: true,
          message: 'Odrzucono wniosek o zgrupowanie wysokogórskie ze względów oszczędnościowych.',
          emailId: email.id,
          actionId: action.actionId,
          actionType: action.actionType,
          stateChanges: {'action': 'camp_budget_rejected'},
          timestamp: timestamp,
        );

      case EmailActionType.scheduleRiderMeeting:
        final riderName = payload['riderName'] ?? 'Kolarz';
        return EmailActionResult(
          success: true,
          message: 'Zaplanowano indywidualną rozmowę z zawodnikiem $riderName w celu złagodzenia napięć.',
          emailId: email.id,
          actionId: action.actionId,
          actionType: action.actionType,
          stateChanges: {
            'action': 'rider_meeting_scheduled',
            'riderId': payload['riderId'],
            'moraleDelta': 10.0,
          },
          timestamp: timestamp,
        );

      case EmailActionType.penalizeRider:
        final riderName = payload['riderName'] ?? 'Kolarz';
        return EmailActionResult(
          success: true,
          message: 'Nałożono upomnienie dyscyplinarne i karę finansową na $riderName za niesubordynację.',
          emailId: email.id,
          actionId: action.actionId,
          actionType: action.actionType,
          stateChanges: {
            'action': 'rider_penalized',
            'riderId': payload['riderId'],
            'moraleDelta': -15.0,
          },
          timestamp: timestamp,
        );

      case EmailActionType.signDevoRider:
        final talentName = payload['talentName'] ?? 'Młody Kolarz';
        final salaryEur = payload['annualSalaryEur'] ?? 24000;
        return EmailActionResult(
          success: true,
          message: 'Podpisano 2-letni kontrakt rozwojowy z kolarzem $talentName ($salaryEur € rocznie) w zespole Devo!',
          emailId: email.id,
          actionId: action.actionId,
          actionType: action.actionType,
          stateChanges: {
            'action': 'devo_contract_signed',
            'talentName': talentName,
            'salaryEur': salaryEur,
          },
          timestamp: timestamp,
        );

      case EmailActionType.scoutLabTesting:
        final talentName = payload['talentName'] ?? 'Młody Kolarz';
        final costEur = payload['testCostEur'] ?? 3000;
        return EmailActionResult(
          success: true,
          message: 'Wysłano kolarza $talentName na pełne testy aerodynamiczne i wydolnościowe w laboratorium (${costEur.toString()} €).',
          emailId: email.id,
          actionId: action.actionId,
          actionType: action.actionType,
          stateChanges: {
            'action': 'scout_lab_tested',
            'budgetDeltaEur': -costEur,
            'talentName': talentName,
          },
          timestamp: timestamp,
        );

      case EmailActionType.orderEquipmentUpgrade:
        final upgradeName = payload['upgradeName'] ?? 'Koła Aero TT 60mm';
        final costEur = payload['costEur'] ?? 18000;
        return EmailActionResult(
          success: true,
          message: 'Zamówiono pakiet $upgradeName za ${costEur.toString()} €. Zysk aerodynamiczny: -11 Watów.',
          emailId: email.id,
          actionId: action.actionId,
          actionType: action.actionType,
          stateChanges: {
            'action': 'equipment_upgraded',
            'upgradeName': upgradeName,
            'budgetDeltaEur': -costEur,
            'wattSavings': payload['wattSavings'] ?? 11,
          },
          timestamp: timestamp,
        );

      case EmailActionType.acknowledgeAntiDopingNotice:
        return EmailActionResult(
          success: true,
          message: 'Potwierdzono odbiór powiadomienia UCI i zaktualizowano status ADAMS.',
          emailId: email.id,
          actionId: action.actionId,
          actionType: action.actionType,
          stateChanges: {'action': 'adams_confirmed'},
          timestamp: timestamp,
        );

      case EmailActionType.respondToPress:
        final outlet = payload['mediaOutlet'] ?? 'Prasa kolarska';
        return EmailActionResult(
          success: true,
          message: 'Przekazano oficjalne stanowisko redakcji $outlet. Wzrost zainteresowania medialnego.',
          emailId: email.id,
          actionId: action.actionId,
          actionType: action.actionType,
          stateChanges: {'action': 'press_statement_issued'},
          timestamp: timestamp,
        );

      case EmailActionType.acknowledge:
      case EmailActionType.customAction:
        return EmailActionResult(
          success: true,
          message: 'Przyjęto do wiadomości.',
          emailId: email.id,
          actionId: action.actionId,
          actionType: action.actionType,
          stateChanges: {'action': 'acknowledged'},
          timestamp: timestamp,
        );
    }
  }

  // ===========================================================================
  // GENERATORY KONKRETNYCH, BOGATYCH WIADOMOŚCI E-MAIL
  // ===========================================================================

  /// 1. Oficjalne zaproszenie na wyścig (Wildcard / Dzikie Karty od ASO, RCS itp.)
  InboxEmailMessage generateRaceInvitationEmail({
    required String raceName,
    required String raceId,
    required String organizerName,
    required String raceCategory,
    required DateTime raceStartDate,
    required int stageCount,
    DateTime? sentDate,
  }) {
    final now = sentDate ?? DateTime.now();
    final expiry = now.add(const Duration(days: 7));
    final id = 'invite_${raceId}_${now.millisecondsSinceEpoch}';

    final body = '''Szanowny Panie Menedżerze,

W imieniu komitetu organizacyjnego $organizerName mamy zaszczyt poinformować, że Państwa zespół otrzymał oficjalne zaproszenie Wildcard (Dziką Kartę) do wzięcia udziału w nadchodzącej edycji wyścigu:

🏁 Wyścig: $raceName
📅 Termin rozpoczęcia: ${raceStartDate.year}-${raceStartDate.month.toString().padLeft(2, '0')}-${raceStartDate.day.toString().padLeft(2, '0')}
📊 Kategoria UCI: $raceCategory
📈 Liczba etapów: $stageCount ${stageCount == 1 ? 'dzień rywalizacji' : 'etapów'}

Jako organizatorzy liczymy na ofensywną jazdę Waszych kolarzy, aktywność w odjazdach oraz walkę o etapy. Prosimy o potwierdzenie przyjęcia zaproszenia w ciągu 7 dni w celu dopełnienia formalności rejestracyjnych UCI.

Z poważaniem,
$organizerName – Dyrekcja Wyścigu''';

    return InboxEmailMessage(
      id: id,
      senderName: organizerName,
      senderRole: 'Dyrektor Organizacyjny Wyścigu',
      senderAvatar: 'flag',
      subject: 'Oficjalne zaproszenie Wildcard: $raceName',
      bodyText: body,
      category: EmailCategory.raceInvitation,
      priority: EmailPriority.high,
      sentDate: now,
      requiresImmediateAction: true,
      expiryDate: expiry,
      actions: [
        InboxEmailAction(
          actionId: 'accept_$id',
          label: 'Zaakceptuj zaproszenie na wyścig',
          actionType: EmailActionType.acceptRaceInvitation,
          style: EmailActionButtonStyle.success,
          iconKey: 'check_circle',
          payload: {
            'raceId': raceId,
            'raceName': raceName,
          },
        ),
        InboxEmailAction(
          actionId: 'decline_$id',
          label: 'Odrzuć zaproszenie',
          actionType: EmailActionType.declineRaceInvitation,
          style: EmailActionButtonStyle.danger,
          iconKey: 'cancel',
          payload: {
            'raceId': raceId,
            'raceName': raceName,
          },
        ),
      ],
      metadata: {
        'raceId': raceId,
        'raceName': raceName,
        'organizer': organizerName,
      },
    );
  }

  /// 2. Raport medyczny po kraksie kolarza (Crash Medical Report)
  InboxEmailMessage generateMedicalCrashReportEmail({
    required String riderName,
    required String riderId,
    required String raceName,
    required int stageNumber,
    required String injuryDescription,
    required int daysOut,
    int treatmentCostEur = 3500,
    int reducedDaysByTreatment = 4,
    DateTime? sentDate,
  }) {
    final now = sentDate ?? DateTime.now();
    final id = 'med_${riderId}_${now.millisecondsSinceEpoch}';

    final body = '''PILNY RAPORT MEDYCZNY ZE SZPITALA POLOWEGO

Do: Menedżer Zespołu
Od: Dr Marc Lefranc, Główny Lekarz Zespołu
Data: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}

Podczas dzisiejszego etapu ($stageNumber. etap $raceName) na 38. kilometrze przed metą kolarz $riderName uczestniczył w ciężkiej kraksie w peletonie przy prędkości ok. 58 km/h.

🩺 Wstępna diagnoza lekarska:
- Obrażenia: $injuryDescription
- Skóra: liczne głębokie otarcia (tzw. szosa) na biodrze i przedramieniu
- Badanie USG/RTG: wykluczono otwarte złamania kości udowej, lecz stwierdzono silne stłuczenie tkanek miękkich i mikropęknięcia żeber.
- Szacowany czas absencji treningowej w trybie standardowym: $daysOut dni.

💡 Zalecenia sztabu medycznego:
Mamy możliwość wdrożenia natychmiastowej procedury regeneracyjnej: sesje w komorze hiperbarycznej (1.8 ATA) + fizjoterapia drenażowa Indiba Active.
Koszt zabiegów wynosi $treatmentCostEur €, lecz pozwoli skrócić przerwę w startach o $reducedDaysByTreatment dni!''';

    return InboxEmailMessage(
      id: id,
      senderName: 'Dr Marc Lefranc',
      senderRole: 'Główny Lekarz Zespołu',
      senderAvatar: 'healing',
      subject: 'PILNE: Raport po kraksie na $stageNumber. etapie $raceName – $riderName',
      bodyText: body,
      category: EmailCategory.medicalReport,
      priority: EmailPriority.urgent,
      sentDate: now,
      requiresImmediateAction: true,
      actions: [
        InboxEmailAction(
          actionId: 'view_report_$id',
          label: 'Przejdź do raportu medycznego po kraksie',
          actionType: EmailActionType.viewMedicalReport,
          style: EmailActionButtonStyle.primary,
          iconKey: 'assignment',
          payload: {
            'riderId': riderId,
            'riderName': riderName,
            'injuryType': injuryDescription,
            'daysOut': daysOut,
          },
        ),
        InboxEmailAction(
          actionId: 'treat_$id',
          label: 'Zatwierdź przyspieszoną terapię ($treatmentCostEur €)',
          actionType: EmailActionType.authorizeMedicalTreatment,
          style: EmailActionButtonStyle.warning,
          iconKey: 'medical_services',
          payload: {
            'riderId': riderId,
            'riderName': riderName,
            'treatmentCostEur': treatmentCostEur,
            'reducedDays': reducedDaysByTreatment,
          },
        ),
        InboxEmailAction(
          actionId: 'withdraw_$id',
          label: 'Wycofaj kolarza ze startów na $daysOut dni',
          actionType: EmailActionType.withdrawRiderFromRaces,
          style: EmailActionButtonStyle.danger,
          iconKey: 'pause_circle',
          payload: {
            'riderId': riderId,
            'riderName': riderName,
          },
        ),
      ],
      metadata: {
        'riderId': riderId,
        'riderName': riderName,
        'daysOut': daysOut,
      },
    );
  }

  /// 3. Oficjalna oferta transferowa / klauzula wykupu (Transfer Buyout Offer)
  InboxEmailMessage generateTransferBuyoutOfferEmail({
    required String riderName,
    required String riderId,
    required String buyingTeamName,
    required String buyingTeamDsName,
    required int buyoutFeeEur,
    required int proposedRiderSalaryEur,
    DateTime? sentDate,
  }) {
    final now = sentDate ?? DateTime.now();
    final expiry = now.add(const Duration(days: 5));
    final id = 'transf_${riderId}_${now.millisecondsSinceEpoch}';

    final body = '''Dzień dobry,

Kontaktuję się w imieniu dyrekcji sportowej $buyingTeamName.
Z wielką uwagą śledzimy rozwój i występy Waszego zawodnika $riderName. Uważamy, że jego profil idealnie pasuje do naszej formacji na kolejne sezony.

Zgodnie z regulacjami UCI dotyczącymi transferów przed końcem kontraktu, składamy oficjalną ofertę aktywacji klauzuli wykupu:

💰 Oferowana kwota odstępnego dla Waszego zespołu: ${buyoutFeeEur.toString()} €
💼 Indywidualna pensja oferowana zawodnikowi: ${proposedRiderSalaryEur.toString()} € / miesiąc
⏳ Ważność oferty: 5 dni (do ${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')})

Czekamy na Wasze oficjalne stanowisko. W przypadku zgody środki zostaną natychmiast przelane na konto Waszej drużyny.

Z poważaniem,
$buyingTeamDsName
Dyrektor Sportowy, $buyingTeamName''';

    return InboxEmailMessage(
      id: id,
      senderName: buyingTeamDsName,
      senderRole: 'Dyrektor Sportowy, $buyingTeamName',
      senderAvatar: 'swap_horiz',
      subject: 'Oferta transferowa: $buyingTeamName składa zapytanie o kolarza $riderName',
      bodyText: body,
      category: EmailCategory.transferOffer,
      priority: EmailPriority.high,
      sentDate: now,
      requiresImmediateAction: true,
      expiryDate: expiry,
      actions: [
        InboxEmailAction(
          actionId: 'accept_buyout_$id',
          label: 'Zaakceptuj ofertę wykupu (${buyoutFeeEur.toString()} €)',
          actionType: EmailActionType.acceptTransferOffer,
          style: EmailActionButtonStyle.success,
          iconKey: 'attach_money',
          payload: {
            'riderId': riderId,
            'riderName': riderName,
            'buyoutFeeEur': buyoutFeeEur,
            'buyingTeam': buyingTeamName,
          },
        ),
        InboxEmailAction(
          actionId: 'counter_buyout_$id',
          label: 'Odpowiedz na ofertę wykupu kolarza (Zażądaj +25%)',
          actionType: EmailActionType.counterTransferOffer,
          style: EmailActionButtonStyle.warning,
          iconKey: 'trending_up',
          payload: {
            'riderId': riderId,
            'riderName': riderName,
            'buyoutFeeEur': buyoutFeeEur,
          },
        ),
        InboxEmailAction(
          actionId: 'reject_buyout_$id',
          label: 'Odrzuć ofertę definitywnie',
          actionType: EmailActionType.rejectTransferOffer,
          style: EmailActionButtonStyle.danger,
          iconKey: 'block',
          payload: {
            'riderId': riderId,
            'riderName': riderName,
            'buyingTeam': buyingTeamName,
          },
        ),
      ],
      metadata: {
        'riderId': riderId,
        'buyoutFeeEur': buyoutFeeEur,
        'buyingTeam': buyingTeamName,
      },
    );
  }

  /// 4. Wniosek budżetowy na obóz wysokogórski (Sierra Nevada / Teide / Livigno)
  InboxEmailMessage generateAltitudeCampBudgetEmail({
    String location = 'Sierra Nevada (Hiszpania, 2 320 m n.p.m.)',
    int durationWeeks = 3,
    int riderCount = 6,
    int totalBudgetEur = 42000,
    int economyBudgetEur = 28000,
    double expectedFtpGainPct = 3.8,
    double expectedVamGainPct = 5.2,
    DateTime? sentDate,
  }) {
    final now = sentDate ?? DateTime.now();
    final id = 'camp_${now.millisecondsSinceEpoch}';

    final body = '''WNIOSEK SZTABU SZKOLENIOWEGO O FINANSOWANIE ZGRUPOWANIA WYSOKOGÓRSKIEGO

Do: Menedżer Generalny
Od: Javier Fernandez, Kierownik Działu Performance i Fizjologii
Data: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}

Przed zbliżającym się szczytem sezonu nasz sztab opracował plan $durationWeeks-tygodniowego obozu hipoksyjnego dla $riderCount kluczowych kolarzy (liderzy GC + kluczowi górale).

🏔️ Lokalizacja docelowa: $location
⏱️ Czas trwania: $durationWeeks tygodnie (metoda Live High, Train Low)

Kalkulacja kosztów ($totalBudgetEur €):
- Rezerwacja hotelu wysokościowego w CAR Sierra Nevada: 21 000 €
- Dedykowany kucharz sportowy + suplementacja węglowodanowa (120g/h): 7 500 €
- Auta wsparcia, paliwo i zabezpieczenie na podjazdach: 6 000 €
- Codzienna telemetria mleczanowa i badania hematologiczne krwi: 7 500 €

📈 Spodziewane korzyści fizjologiczne:
- Wzrost produkcji EPO i masy hemoglobinowej: +4.5%
- Przyrost mocy na progu FTP: +${expectedFtpGainPct.toStringAsFixed(1)}%
- Średni wzrost wskaźnika wspinaczkowego VAM: +${expectedVamGainPct.toStringAsFixed(1)}%

Dostępny jest także wariant oszczędnościowy na Teneryfie (Teide) za $economyBudgetEur €, lecz z mniejszą bazą laboratoryjną.''';

    return InboxEmailMessage(
      id: id,
      senderName: 'Javier Fernandez',
      senderRole: 'Head of Performance',
      senderAvatar: 'terrain',
      subject: 'Wniosek budżetowy: $durationWeeks-tygodniowy obóz wysokogórski w Sierra Nevada',
      bodyText: body,
      category: EmailCategory.trainingAndCamp,
      priority: EmailPriority.high,
      sentDate: now,
      requiresImmediateAction: true,
      actions: [
        InboxEmailAction(
          actionId: 'approve_camp_$id',
          label: 'Zatwierdź budżet na obóz w Sierra Nevada (${totalBudgetEur.toString()} €)',
          actionType: EmailActionType.approveCampBudget,
          style: EmailActionButtonStyle.success,
          iconKey: 'check_circle',
          payload: {
            'location': 'Sierra Nevada',
            'campCostEur': totalBudgetEur,
            'expectedFtpBonusPct': expectedFtpGainPct,
            'expectedVamBonusPct': expectedVamGainPct,
          },
        ),
        InboxEmailAction(
          actionId: 'economy_camp_$id',
          label: 'Wybierz wariant oszczędnościowy Teide (${economyBudgetEur.toString()} €)',
          actionType: EmailActionType.chooseEconomyCamp,
          style: EmailActionButtonStyle.secondary,
          iconKey: 'savings',
          payload: {
            'economyLocation': 'Teide (Wariant Ekonomiczny)',
            'economyCostEur': economyBudgetEur,
          },
        ),
        InboxEmailAction(
          actionId: 'reject_camp_$id',
          label: 'Odrzuć wniosek ze względu na budżet',
          actionType: EmailActionType.rejectCampBudget,
          style: EmailActionButtonStyle.danger,
          iconKey: 'cancel',
          payload: const {},
        ),
      ],
      metadata: {
        'totalBudgetEur': totalBudgetEur,
        'location': 'Sierra Nevada',
      },
    );
  }

  /// 5. Konflikt ego kolarza / frustracja rolą w zespole (Rider Ego Conflict)
  InboxEmailMessage generateRiderConflictEmail({
    required String riderName,
    required String riderId,
    required String complaintReason,
    DateTime? sentDate,
  }) {
    final now = sentDate ?? DateTime.now();
    final id = 'ego_${riderId}_${now.millisecondsSinceEpoch}';

    final body = '''WIADOMOŚĆ PRYWATNA OD ZAWODNIKA

Do: Dyrektor Generalny
Od: $riderName
Status w drużynie: Współlider / Pretendent

Muszę porozmawiać z Panem w cztery oczy. Sytuacja w drużynie staje się dla mnie nie do zaakceptowania.
Powód mojej frustracji: $complaintReason

Nie podpisywałem kontraktu z tą drużyną, by wozić bidony na płaskich etapach lub czekać na kolarzy, którzy w górach nie mają nogi. Jeśli moje ambicje nie zostaną potraktowane poważnie, mój menedżer rozpocznie rozmowy z innymi ekipami WorldTour.

Oczekuję pilnego spotkania przed kolejnym blokiem wyścigowym.''';

    return InboxEmailMessage(
      id: id,
      senderName: riderName,
      senderRole: 'Kolarz – Współlider',
      senderAvatar: 'person',
      subject: 'Niezadowolenie kolarza: $riderName żąda pilnej rozmowy z dyrekcją',
      bodyText: body,
      category: EmailCategory.riderRelations,
      priority: EmailPriority.high,
      sentDate: now,
      requiresImmediateAction: true,
      actions: [
        InboxEmailAction(
          actionId: 'meet_$id',
          label: 'Zwołaj pilną rozmowę indywidualną z kolarzem',
          actionType: EmailActionType.scheduleRiderMeeting,
          style: EmailActionButtonStyle.primary,
          iconKey: 'forum',
          payload: {
            'riderId': riderId,
            'riderName': riderName,
          },
        ),
        InboxEmailAction(
          actionId: 'penalize_$id',
          label: 'Ukaraj kolarza naganą za niesubordynację',
          actionType: EmailActionType.penalizeRider,
          style: EmailActionButtonStyle.danger,
          iconKey: 'warning',
          payload: {
            'riderId': riderId,
            'riderName': riderName,
          },
        ),
      ],
      metadata: {
        'riderId': riderId,
        'riderName': riderName,
      },
    );
  }

  /// 6. Odkrycie talentu orlika w szkółce U23 / Devo Team (Scouting Discovery)
  InboxEmailMessage generateYouthDiscoveryEmail({
    required String talentName,
    required int age,
    required String nationality,
    required String riderType,
    required int vo2max,
    required int annualSalaryEur,
    DateTime? sentDate,
  }) {
    final now = sentDate ?? DateTime.now();
    final id = 'youth_${now.millisecondsSinceEpoch}';

    final body = '''RAPORT GŁÓWNEGO SKAUTA AKADEMII MŁODZIEŻOWEJ

Do: Menedżer Zespołu
Od: Jean-Paul Dubois, Dyrektor ds. Skautingu i Zespołu U23
Data: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}

Podczas wyścigów Pucharu Narodów U23 wpadł nam w oko wybitny zawodnik:

🚴 Kolarz: $talentName ($age lat, $nationality)
🌟 Profil: $riderType
🔬 Zbadany pułap tlenowy VO2max: $vo2max ml/kg/min! (Wartość na poziomie kolarzy podium Grand Tour!)
📈 Szacowane FTP na podjeździe: 5.9 W/kg przy wadze 63 kg.

Inne ekipy WorldTour (w tym Jumbo i UAE) już kręcą się wokół jego agenta. Jeśli chcemy go zabezpieczyć w naszym Devo Teamie, musimy działać natychmiast. Proponujemy 2-letni kontrakt neo-pro za $annualSalaryEur € rocznie.''';

    return InboxEmailMessage(
      id: id,
      senderName: 'Jean-Paul Dubois',
      senderRole: 'Dyrektor Skautingu U23',
      senderAvatar: 'school',
      subject: 'Odkrycie skautingu U23: $talentName ($vo2max ml/kg/min VO2max)',
      bodyText: body,
      category: EmailCategory.youthDevelopment,
      priority: EmailPriority.normal,
      sentDate: now,
      actions: [
        InboxEmailAction(
          actionId: 'sign_devo_$id',
          label: 'Podpisz 2-letni kontrakt Devo (${annualSalaryEur.toString()} €/rok)',
          actionType: EmailActionType.signDevoRider,
          style: EmailActionButtonStyle.success,
          iconKey: 'how_to_reg',
          payload: {
            'talentName': talentName,
            'annualSalaryEur': annualSalaryEur,
          },
        ),
        InboxEmailAction(
          actionId: 'lab_test_$id',
          label: 'Wyślij na testy laboratoryjne i tunel aero (3 000 €)',
          actionType: EmailActionType.scoutLabTesting,
          style: EmailActionButtonStyle.secondary,
          iconKey: 'science',
          payload: {
            'talentName': talentName,
            'testCostEur': 3000,
          },
        ),
      ],
      metadata: {
        'talentName': talentName,
        'vo2max': vo2max,
      },
    );
  }

  /// 7. Oferta technologiczna / ulepszenie sprzętu (Equipment Upgrade)
  InboxEmailMessage generateEquipmentUpgradeEmail({
    required String supplierName,
    required String upgradeName,
    required int costEur,
    required int wattSavings,
    DateTime? sentDate,
  }) {
    final now = sentDate ?? DateTime.now();
    final id = 'tech_${now.millisecondsSinceEpoch}';

    final body = '''OFERTA DZIAŁU ROZWOJU TECHNOLOGICZNEGO

Od: Dział Inżynierii Sprzętu i Aerodynamiki ($supplierName)
Do: Menedżer Zespołu

Nasz zespół inżynierów zakończył testy w tunelu aerodynamicznym w Silverstone nad nową serią komponentów:

⚙️ Pakiet: $upgradeName
🌬️ Oszczędność mocy w pozycji czasowej: -$wattSavings Watów przy prędkości 50 km/h!
⏱️ Zysk czasowy na dystansie 40 km ITT: ok. 28 sekund!
💶 Koszt zakupu i kalibracji dla liderów: $costEur €

Przed nami kluczowa jazda indywidualna na czas. Ten sprzęt może zadecydować o żółtej koszulce.''';

    return InboxEmailMessage(
      id: id,
      senderName: supplierName,
      senderRole: 'Partner Techniczny & Inżynieria R&D',
      senderAvatar: 'precision_manufacturing',
      subject: 'Innowacja Aero: Nowe $upgradeName (-$wattSavings W)',
      bodyText: body,
      category: EmailCategory.equipmentAndTech,
      priority: EmailPriority.normal,
      sentDate: now,
      actions: [
        InboxEmailAction(
          actionId: 'order_upgrade_$id',
          label: 'Zamów pakiet aero dla liderów (${costEur.toString()} €)',
          actionType: EmailActionType.orderEquipmentUpgrade,
          style: EmailActionButtonStyle.primary,
          iconKey: 'shopping_cart',
          payload: {
            'upgradeName': upgradeName,
            'costEur': costEur,
            'wattSavings': wattSavings,
          },
        ),
        InboxEmailAction(
          actionId: 'dismiss_upgrade_$id',
          label: 'Podziękuj za ofertę',
          actionType: EmailActionType.acknowledge,
          style: EmailActionButtonStyle.secondary,
          iconKey: 'close',
        ),
      ],
      metadata: {
        'upgradeName': upgradeName,
        'costEur': costEur,
      },
    );
  }

  /// 8. Zawiadomienie z UCI o kontroli antydopingowej ADAMS
  InboxEmailMessage generateAntiDopingNoticeEmail({
    required String riderName,
    required String testLocation,
    required bool isRandomOutCompetiton,
    DateTime? sentDate,
  }) {
    final now = sentDate ?? DateTime.now();
    final id = 'adams_${now.millisecondsSinceEpoch}';

    final body = '''OFICJALNE POWIADOMIENIE UCI CLEAN CYCLING INTEGRITY UNIT

Dotyczy: Kontrola antydopingowa ADAMS
Kolarz: $riderName
Miejsce pobrania próbek: $testLocation
Typ kontroli: ${isRandomOutCompetiton ? 'Niezapowiedziana poza zawodami (Out-of-Competition)' : 'Rutynowa poetapowa'}

Inspektorzy ITA (International Testing Agency) pobrali próbki krwi i moczu do analizy paszportu biologicznego kolarza. Wszystkie procedury protokołu łańcucha dostaw próbek zostały dopełnione bez zastrzeżeń.

Prosimy o formalne potwierdzenie zapoznania się z raportem w systemie ADAMS.''';

    return InboxEmailMessage(
      id: id,
      senderName: 'UCI Clean Cycling Integrity Unit',
      senderRole: 'Inspektorat Antydopingowy ITA',
      senderAvatar: 'verified_user',
      subject: 'Protokół kontroli ADAMS / Paszport Biologiczny: $riderName',
      bodyText: body,
      category: EmailCategory.antiDopingAndAdams,
      priority: EmailPriority.normal,
      sentDate: now,
      actions: [
        InboxEmailAction(
          actionId: 'confirm_adams_$id',
          label: 'Potwierdź odbiór protokołu UCI',
          actionType: EmailActionType.acknowledgeAntiDopingNotice,
          style: EmailActionButtonStyle.success,
          iconKey: 'verified',
        ),
      ],
      metadata: {
        'riderName': riderName,
      },
    );
  }

  /// 9. Zapytanie prasowe od dziennikarzy przed decydującym etapem
  InboxEmailMessage generatePressInterviewRequestEmail({
    required String mediaOutlet,
    required String journalistName,
    required String topic,
    DateTime? sentDate,
  }) {
    final now = sentDate ?? DateTime.now();
    final id = 'press_${now.millisecondsSinceEpoch}';

    final body = '''Szanowny Panie Menedżerze,

Z tej strony $journalistName z redakcji $mediaOutlet.
Przed jutrzejszym etapem chcielibyśmy zadać kilka pytań dotyczących:
"$topic"

Czy zespół planuje ofensywną taktykę na jutrzejszych podjazdach, czy raczej defensywną obronę pozycji lidera? Kibice w całym kraju z niecierpliwością czekają na Wasz komentarz.

Czekamy na oficjalną odpowiedź.''';

    return InboxEmailMessage(
      id: id,
      senderName: journalistName,
      senderRole: 'Dziennikarz sportowy, $mediaOutlet',
      senderAvatar: 'mic',
      subject: 'Prośba o komentarz dla $mediaOutlet: $topic',
      bodyText: body,
      category: EmailCategory.pressAndMedia,
      priority: EmailPriority.normal,
      sentDate: now,
      actions: [
        InboxEmailAction(
          actionId: 'respond_press_$id',
          label: 'Udziel oficjalnej odpowiedzi dziennikarzom',
          actionType: EmailActionType.respondToPress,
          style: EmailActionButtonStyle.primary,
          iconKey: 'send',
          payload: {'mediaOutlet': mediaOutlet},
        ),
        InboxEmailAction(
          actionId: 'decline_press_$id',
          label: 'Odmów komentarza przed etapem',
          actionType: EmailActionType.acknowledge,
          style: EmailActionButtonStyle.secondary,
          iconKey: 'speaker_notes_off',
        ),
      ],
      metadata: {
        'mediaOutlet': mediaOutlet,
      },
    );
  }

  // ===========================================================================
  // SYMULATOR PORANNEGO BRIEFINUGU POCZTY MENEDŻERA
  // ===========================================================================

  /// Generuje zestaw realistycznych porannych maili dla danego dnia kariery,
  /// jeśli w skrzynce nie ma zbyt wielu oczekujących wiadomości.
  List<InboxEmailMessage> generateDailyMorningBriefing({
    required DateTime currentDate,
    required String teamName,
    required String teamId,
    int currentBudgetEur = 500000,
    List<String> injuredRiderNames = const [],
  }) {
    final List<InboxEmailMessage> newEmails = [];

    // 1. Zawsze jeśli są kontuzjowani kolarze, lekarz wysyła raport
    for (final riderName in injuredRiderNames) {
      newEmails.add(
        generateMedicalCrashReportEmail(
          riderName: riderName,
          riderId: 'rider_${riderName.toLowerCase().replaceAll(' ', '_')}',
          raceName: 'Ostatni wyścig WorldTour',
          stageNumber: 3,
          injuryDescription: 'Głębokie stłuczenie biodra i obtarcia skóry',
          daysOut: 9,
          treatmentCostEur: 3800,
          reducedDaysByTreatment: 4,
          sentDate: currentDate,
        ),
      );
    }

    // 2. Okazjonalne zaproszenie na wyścig (np. 35% szans jeśli luty-kwiecień)
    final month = currentDate.month;
    if ((month >= 2 && month <= 5) && _random.nextDouble() < 0.40) {
      final races = [
        {'name': 'Strade Bianche', 'id': 'strade_bianche', 'org': 'RCS Sport', 'cat': '1.UWT', 'stg': 1},
        {'name': 'Brabantse Pijl', 'id': 'brabantse_pijl', 'org': 'Flanders Classics', 'cat': '1.Pro', 'stg': 1},
        {'name': 'Tour of the Alps', 'id': 'tour_alps', 'org': 'Euregio Team', 'cat': '2.Pro', 'stg': 5},
        {'name': 'Tour de Suisse', 'id': 'tour_suisse', 'org': 'Swiss Cycling', 'cat': '2.UWT', 'stg': 8},
      ];
      final pick = races[_random.nextInt(races.length)];
      newEmails.add(
        generateRaceInvitationEmail(
          raceName: pick['name'] as String,
          raceId: pick['id'] as String,
          organizerName: pick['org'] as String,
          raceCategory: pick['cat'] as String,
          raceStartDate: currentDate.add(Duration(days: 14 + _random.nextInt(20))),
          stageCount: pick['stg'] as int,
          sentDate: currentDate,
        ),
      );
    }

    // 3. Wniosek o obóz wysokogórski (jeśli maj lub czerwiec przed TdF/Vueltą)
    if ((month == 5 || month == 6 || month == 7) && _random.nextDouble() < 0.35) {
      newEmails.add(
        generateAltitudeCampBudgetEmail(
          sentDate: currentDate,
        ),
      );
    }

    // 4. Oferta transferowa od gigantów peletonu (np. lipiec-sierpień)
    if ((month == 7 || month == 8) && _random.nextDouble() < 0.40) {
      newEmails.add(
        generateTransferBuyoutOfferEmail(
          riderName: 'Matej Mohoric',
          riderId: 'rider_mohoric',
          buyingTeamName: 'UAE Team Emirates',
          buyingTeamDsName: 'Joxean Fernández Matxín',
          buyoutFeeEur: 750000,
          proposedRiderSalaryEur: 110000,
          sentDate: currentDate,
        ),
      );
    }

    // Dodaj wszystkie wygenerowane wiadomości do skrzynki
    for (final email in newEmails) {
      addEmail(email);
    }

    return newEmails;
  }

  // ===========================================================================
  // SERIALIZACJA DO ZAPISU STANU GRY (CareerSave)
  // ===========================================================================

  Map<String, dynamic> toJson() {
    return {
      'emails': _emails.map((e) => e.toJson()).toList(),
    };
  }

  factory EmailInboxGeneratorService.fromJson(Map<String, dynamic> json) {
    final rawEmails = (json['emails'] as List<dynamic>?)
            ?.map((e) => InboxEmailMessage.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return EmailInboxGeneratorService(initialEmails: rawEmails);
  }
}

