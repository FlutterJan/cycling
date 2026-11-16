import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';

/// Nadawca wiadomości w oknie negocjacji kontraktowych.
enum NegotiationSender {
  manager,
  agent,
  system,
}

/// Status bieżącej sesji negocjacyjnej z agentem kolarza.
enum ContractNegotiationStatus {
  inProgress,
  accepted,
  walkedAway,
}

/// Typy kart przetargowych możliwych do użycia podczas rozmów z agentem.
enum BargainingChipType {
  tourDeFranceGuarantee,
  dedicatedSprintTrain,
  higherWinBonus,
}

extension BargainingChipTypeX on BargainingChipType {
  String get title {
    switch (this) {
      case BargainingChipType.tourDeFranceGuarantee:
        return 'Gwarancja startu w Tour de France';
      case BargainingChipType.dedicatedSprintTrain:
        return 'Dedykowany pociąg sprinterski';
      case BargainingChipType.higherWinBonus:
        return 'Wyższa premia za zwycięstwo';
    }
  }

  String get shortTag {
    switch (this) {
      case BargainingChipType.tourDeFranceGuarantee:
        return 'TDF GWARANCJA';
      case BargainingChipType.dedicatedSprintTrain:
        return 'POCIĄG SPRINT';
      case BargainingChipType.higherWinBonus:
        return 'PREMIA WIN+';
    }
  }

  String get description {
    switch (this) {
      case BargainingChipType.tourDeFranceGuarantee:
        return 'Zapis w kontrakcie gwarantujący miejsce w 8-osobowym składzie na Wielką Pętlę.';
      case BargainingChipType.dedicatedSprintTrain:
        return 'Przydzielenie 2 rozprowadzających (lead-out) na najważniejsze finisze sezonu.';
      case BargainingChipType.higherWinBonus:
        return 'Podniesienie premii za każdy triumf etapowy i klasyczny zamiast sztywnej pensji.';
    }
  }

  String get managerArgumentText {
    switch (this) {
      case BargainingChipType.tourDeFranceGuarantee:
        return 'Kładziemy na stół twardą gwarancję startu w Tour de France. To najlepsza ekspozycja dla Twojego zawodnika.';
      case BargainingChipType.dedicatedSprintTrain:
        return 'Zbudujemy wokół niego dedykowany pociąg sprinterski z dwoma doświadczonymi rozprowadzającymi.';
      case BargainingChipType.higherWinBonus:
        return 'Zamiast podnosić podstawę, znacząco zwiększamy premię za każde zwycięstwo. Wynik sportowy sam się spłaci.';
    }
  }

  IconData get icon {
    switch (this) {
      case BargainingChipType.tourDeFranceGuarantee:
        return Icons.emoji_events_rounded;
      case BargainingChipType.dedicatedSprintTrain:
        return Icons.bolt_rounded;
      case BargainingChipType.higherWinBonus:
        return Icons.trending_up_rounded;
    }
  }

  /// Procentowa redukcja oczekiwań płacowych agenta po zagraniu karty.
  double get salaryDemandReductionFactor {
    switch (this) {
      case BargainingChipType.tourDeFranceGuarantee:
        return 0.09;
      case BargainingChipType.dedicatedSprintTrain:
        return 0.10;
      case BargainingChipType.higherWinBonus:
        return 0.07;
    }
  }

  /// Wzrost cierpliwości agenta po zagraniu karty (w punktach 0..100).
  int get patienceBoost {
    switch (this) {
      case BargainingChipType.tourDeFranceGuarantee:
        return 10;
      case BargainingChipType.dedicatedSprintTrain:
        return 11;
      case BargainingChipType.higherWinBonus:
        return 8;
    }
  }

  /// Dodatkowy bonus do premii za zwycięstwo [EUR], jeśli karta dotyczy premii.
  int get winBonusBoostEur {
    switch (this) {
      case BargainingChipType.tourDeFranceGuarantee:
        return 0;
      case BargainingChipType.dedicatedSprintTrain:
        return 0;
      case BargainingChipType.higherWinBonus:
        return 3500;
    }
  }
}

/// Niemutowalny zapis warunków kontraktu w ofercie lub kontrofercie.
class ContractOfferTerms {
  final int monthlySalaryEur;
  final int contractYears;
  final int signingBonusEur;
  final int winBonusEur;
  final RiderRole role;
  final Set<BargainingChipType> activeChips;

  const ContractOfferTerms({
    required this.monthlySalaryEur,
    required this.contractYears,
    required this.signingBonusEur,
    required this.winBonusEur,
    required this.role,
    this.activeChips = const <BargainingChipType>{},
  });

  int get annualSalaryEur => monthlySalaryEur * 12;

  int get totalGuaranteedValueEur =>
      (annualSalaryEur * contractYears) + signingBonusEur;

  ContractOfferTerms copyWith({
    int? monthlySalaryEur,
    int? contractYears,
    int? signingBonusEur,
    int? winBonusEur,
    RiderRole? role,
    Set<BargainingChipType>? activeChips,
  }) {
    return ContractOfferTerms(
      monthlySalaryEur: monthlySalaryEur ?? this.monthlySalaryEur,
      contractYears: contractYears ?? this.contractYears,
      signingBonusEur: signingBonusEur ?? this.signingBonusEur,
      winBonusEur: winBonusEur ?? this.winBonusEur,
      role: role ?? this.role,
      activeChips: activeChips ?? this.activeChips,
    );
  }
}

/// Pojedynczy wpis na osi czasu czatu negocjacji.
class NegotiationChatMessage {
  final String id;
  final NegotiationSender sender;
  final String senderLabel;
  final String text;
  final String timestampLabel;
  final ContractOfferTerms? attachedOffer;
  final BargainingChipType? playedChip;
  final int? patienceDelta;

  const NegotiationChatMessage({
    required this.id,
    required this.sender,
    required this.senderLabel,
    required this.text,
    required this.timestampLabel,
    this.attachedOffer,
    this.playedChip,
    this.patienceDelta,
  });
}

/// Końcowy rezultat sesji negocjacyjnej przekazywany do ekranu nadrzędnego.
class ContractNegotiationOutcome {
  final ContractNegotiationStatus status;
  final ContractOfferTerms finalTerms;
  final int remainingPatience;
  final int roundsTaken;

  const ContractNegotiationOutcome({
    required this.status,
    required this.finalTerms,
    required this.remainingPatience,
    required this.roundsTaken,
  });
}

/// Interaktywny symulator negocjacji kontraktowych na żywo z agentem kolarza.
///
/// Obsługuje dynamiczny pasek cierpliwości agenta, kontroferty w czasie rzeczywistym,
/// zagrywanie kart przetargowych (gwarancja startu w Tour de France, dedykowany pociąg
/// sprinterski, wyższa premia za zwycięstwo) oraz pełną responsywność (390x844, 1024x768, 1600x900).
class ContractNegotiationChatSimulator extends StatefulWidget {
  final Rider? rider;
  final String riderDisplayName;
  final String riderSpecializationLabel;
  final String agentName;
  final String agencyName;
  final ContractOfferTerms? initialAgentDemand;
  final ContractOfferTerms? initialManagerOffer;
  final int initialPatience;
  final Duration agentReplyDelay;
  final ValueChanged<ContractOfferTerms>? onOfferSent;
  final ValueChanged<ContractNegotiationOutcome>? onNegotiationComplete;

  const ContractNegotiationChatSimulator({
    super.key,
    this.rider,
    this.riderDisplayName = 'Mateusz Kowalski',
    this.riderSpecializationLabel = 'Wszechstronny Sprinter',
    this.agentName = 'Jean-Luc Moreau',
    this.agencyName = 'Apex Peloton Management',
    this.initialAgentDemand,
    this.initialManagerOffer,
    this.initialPatience = 78,
    this.agentReplyDelay = const Duration(milliseconds: 320),
    this.onOfferSent,
    this.onNegotiationComplete,
  });

  @override
  State<ContractNegotiationChatSimulator> createState() =>
      _ContractNegotiationChatSimulatorState();
}

class _ContractNegotiationChatSimulatorState
    extends State<ContractNegotiationChatSimulator> {
  static const TextStyle _interBase = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
  );

  static const TextStyle _tabularBase = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  final ScrollController _chatScrollController = ScrollController();
  Timer? _agentReplyTimer;

  late ContractOfferTerms _agentDemand;
  late ContractOfferTerms _managerDraft;
  late int _patience;
  late int _round;
  late ContractNegotiationStatus _status;
  late Set<BargainingChipType> _usedChips;
  late List<NegotiationChatMessage> _messages;
  bool _isAgentTyping = false;
  int _messageCounter = 0;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  @override
  void dispose() {
    _agentReplyTimer?.cancel();
    _chatScrollController.dispose();
    super.dispose();
  }

  String get _resolvedRiderName {
    final rider = widget.rider;
    if (rider != null) {
      return '${rider.firstName} ${rider.lastName}';
    }
    return widget.riderDisplayName;
  }

  String get _resolvedSpecialization {
    final rider = widget.rider;
    if (rider != null) {
      return rider.specialization.displayName;
    }
    return widget.riderSpecializationLabel;
  }

  int get _minSalaryBound => 3000;
  int get _maxSalaryBound => 120000;

  void _initSession() {
    _agentReplyTimer?.cancel();
    _isAgentTyping = false;
    _round = 1;
    _patience = widget.initialPatience.clamp(10, 100);
    _status = ContractNegotiationStatus.inProgress;
    _usedChips = <BargainingChipType>{};
    _messageCounter = 0;

    final rider = widget.rider;
    final defaultDemand = widget.initialAgentDemand ??
        ContractOfferTerms(
          monthlySalaryEur: rider != null
              ? math.max(8500, (rider.contract.monthlySalaryEur * 1.18).round())
              : 24000,
          contractYears: 3,
          signingBonusEur: rider != null
              ? math.max(5000, rider.contract.signingBonusEur)
              : 18000,
          winBonusEur: rider != null
              ? math.max(2500, rider.contract.winBonusEur)
              : 4500,
          role: rider?.contract.role ?? RiderRole.sprinter,
        );

    final defaultDraft = widget.initialManagerOffer ??
        ContractOfferTerms(
          monthlySalaryEur:
              (defaultDemand.monthlySalaryEur * 0.80 / 500).round() * 500,
          contractYears: defaultDemand.contractYears,
          signingBonusEur:
              (defaultDemand.signingBonusEur * 0.75 / 1000).round() * 1000,
          winBonusEur: defaultDemand.winBonusEur,
          role: defaultDemand.role,
        );

    _agentDemand = defaultDemand;
    _managerDraft = defaultDraft.copyWith(
      monthlySalaryEur:
          defaultDraft.monthlySalaryEur.clamp(_minSalaryBound, _maxSalaryBound),
    );

    _messages = <NegotiationChatMessage>[
      NegotiationChatMessage(
        id: _nextId(),
        sender: NegotiationSender.system,
        senderLabel: 'POKÓJ NEGOCJACYJNY',
        text:
            'Rozpoczęto negocjacje w sprawie kontraktu dla $_resolvedRiderName.',
        timestampLabel: '10:00',
      ),
      NegotiationChatMessage(
        id: _nextId(),
        sender: NegotiationSender.agent,
        senderLabel: widget.agentName,
        text:
            'Dzień dobry. Reprezentuję $_resolvedRiderName ($_resolvedSpecialization). '
            'Mamy dwie inne oferty z WorldTouru, ale chcemy porozmawiać o warunkach w Waszej ekipie. '
            'Nasze oczekiwania otwierające to ${Formatters.formatCurrency(_agentDemand.monthlySalaryEur)}/mies.',
        timestampLabel: '10:01',
        attachedOffer: _agentDemand,
      ),
    ];
  }

  String _nextId() {
    _messageCounter += 1;
    return 'msg_$_messageCounter';
  }

  String _formattedClockForIndex(int index) {
    final totalMinutes = 600 + index * 2;
    final hh = (totalMinutes ~/ 60) % 24;
    final mm = totalMinutes % 60;
    return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chatScrollController.hasClients) return;
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  bool get _canInteract =>
      _status == ContractNegotiationStatus.inProgress && !_isAgentTyping;

  void _updateDraft(ContractOfferTerms next) {
    if (!_canInteract) return;
    setState(() {
      _managerDraft = next;
    });
  }

  void _playBargainingChip(BargainingChipType chip) {
    if (!_canInteract || _usedChips.contains(chip)) return;

    final int patienceGain = chip.patienceBoost;
    final int nextPatience = (_patience + patienceGain).clamp(0, 100);
    final int reducedDemandSalary = math.max(
      _minSalaryBound,
      ((_agentDemand.monthlySalaryEur * (1.0 - chip.salaryDemandReductionFactor)) /
                  500)
              .round() *
          500,
    );

    final updatedChips = <BargainingChipType>{
      ..._managerDraft.activeChips,
      chip,
    };

    final updatedDraft = _managerDraft.copyWith(
      activeChips: updatedChips,
      winBonusEur: _managerDraft.winBonusEur + chip.winBonusBoostEur,
    );

    final updatedDemand = _agentDemand.copyWith(
      monthlySalaryEur: reducedDemandSalary,
      winBonusEur: _agentDemand.winBonusEur + chip.winBonusBoostEur,
      activeChips: updatedChips,
    );

    final String agentReaction = _buildChipReactionText(chip, reducedDemandSalary);

    setState(() {
      _usedChips = <BargainingChipType>{..._usedChips, chip};
      _managerDraft = updatedDraft;
      _agentDemand = updatedDemand;
      _patience = nextPatience;
      _messages = <NegotiationChatMessage>[
        ..._messages,
        NegotiationChatMessage(
          id: _nextId(),
          sender: NegotiationSender.manager,
          senderLabel: 'Dyrektor Sportowy (Ty)',
          text: chip.managerArgumentText,
          timestampLabel: _formattedClockForIndex(_messages.length),
          playedChip: chip,
        ),
        NegotiationChatMessage(
          id: _nextId(),
          sender: NegotiationSender.agent,
          senderLabel: widget.agentName,
          text: agentReaction,
          timestampLabel: _formattedClockForIndex(_messages.length + 1),
          attachedOffer: updatedDemand,
          patienceDelta: patienceGain,
        ),
      ];
    });
    _scrollToBottom();
  }

  String _buildChipReactionText(BargainingChipType chip, int newSalaryDemand) {
    final salaryLabel = Formatters.formatCurrency(newSalaryDemand);
    switch (chip) {
      case BargainingChipType.tourDeFranceGuarantee:
        return 'Start w Tour de France na piśmie to potężny argument sportowy. Możemy zejść z oczekiwaniami do $salaryLabel/mies.';
      case BargainingChipType.dedicatedSprintTrain:
        return 'Dedykowany pociąg sprinterski realnie zwiększy szanse na wygrane etapowe. Koryguję nasze żądania do $salaryLabel/mies.';
      case BargainingChipType.higherWinBonus:
        return 'Podoba nam się model premiowy nastawiony na zwycięstwa. Obniżam bazę oczekiwań do $salaryLabel/mies. przy wyższym bonusie za wygraną.';
    }
  }

  void _sendOffer() {
    if (!_canInteract) return;
    final submittedOffer = _managerDraft;
    widget.onOfferSent?.call(submittedOffer);

    setState(() {
      _isAgentTyping = true;
      _messages = <NegotiationChatMessage>[
        ..._messages,
        NegotiationChatMessage(
          id: _nextId(),
          sender: NegotiationSender.manager,
          senderLabel: 'Dyrektor Sportowy (Ty)',
          text:
              'Przesyłam oficjalną propozycję: ${Formatters.formatCurrency(submittedOffer.monthlySalaryEur)}/mies. '
              'na ${submittedOffer.contractYears} ${_yearsLabel(submittedOffer.contractYears)}, '
              'rola: ${submittedOffer.role.label}, premia za podpis ${Formatters.formatCurrency(submittedOffer.signingBonusEur)}.',
          timestampLabel: _formattedClockForIndex(_messages.length),
          attachedOffer: submittedOffer,
        ),
      ];
    });
    _scrollToBottom();

    _agentReplyTimer?.cancel();
    _agentReplyTimer = Timer(widget.agentReplyDelay, () {
      if (!mounted) return;
      _evaluateOfferAndRespond(submittedOffer);
    });
  }

  void _evaluateOfferAndRespond(ContractOfferTerms offer) {
    final double salaryRatio =
        offer.monthlySalaryEur / math.max(1, _agentDemand.monthlySalaryEur);
    final double bonusRatio = (offer.signingBonusEur + offer.winBonusEur * 2) /
        math.max(
            1, _agentDemand.signingBonusEur + _agentDemand.winBonusEur * 2);
    final bool roleAcceptable =
        offer.role.index <= _agentDemand.role.index + 1;
    final double compositeScore =
        (salaryRatio * 0.78) + (bonusRatio * 0.14) + (roleAcceptable ? 0.08 : 0.0);

    // Scenariusz 1: Pełna akceptacja
    if (compositeScore >= 0.97 && salaryRatio >= 0.94) {
      final acceptedTerms = offer;
      setState(() {
        _isAgentTyping = false;
        _status = ContractNegotiationStatus.accepted;
        _patience = (_patience + 6).clamp(0, 100);
        _messages = <NegotiationChatMessage>[
          ..._messages,
          NegotiationChatMessage(
            id: _nextId(),
            sender: NegotiationSender.agent,
            senderLabel: widget.agentName,
            text:
                'Mamy porozumienie! $_resolvedRiderName akceptuje warunki ${Formatters.formatCurrency(acceptedTerms.monthlySalaryEur)}/mies. '
                'Możemy przygotowywać dokumenty do podpisu.',
            timestampLabel: _formattedClockForIndex(_messages.length),
            attachedOffer: acceptedTerms,
            patienceDelta: 6,
          ),
        ];
      });
      _scrollToBottom();
      widget.onNegotiationComplete?.call(
        ContractNegotiationOutcome(
          status: ContractNegotiationStatus.accepted,
          finalTerms: acceptedTerms,
          remainingPatience: _patience,
          roundsTaken: _round,
        ),
      );
      return;
    }

    // Wyliczenie zmiany cierpliwości agenta
    int patienceDelta;
    if (salaryRatio < 0.72) {
      patienceDelta = -26;
    } else if (salaryRatio < 0.85) {
      patienceDelta = -16;
    } else if (salaryRatio < 0.94) {
      patienceDelta = -9;
    } else {
      patienceDelta = -4;
    }
    if (!roleAcceptable) {
      patienceDelta -= 6;
    }

    final int nextPatience = (_patience + patienceDelta).clamp(0, 100);

    // Scenariusz 2: Zerwanie rozmów przy wyczerpaniu cierpliwości
    if (nextPatience <= 0) {
      setState(() {
        _isAgentTyping = false;
        _patience = 0;
        _status = ContractNegotiationStatus.walkedAway;
        _messages = <NegotiationChatMessage>[
          ..._messages,
          NegotiationChatMessage(
            id: _nextId(),
            sender: NegotiationSender.agent,
            senderLabel: widget.agentName,
            text:
                'Niestety, rozbieżność jest zbyt duża, a nasza cierpliwość się wyczerpała. '
                'Zamykamy rozmowy i skupiamy się na innych ofertach.',
            timestampLabel: _formattedClockForIndex(_messages.length),
            patienceDelta: patienceDelta,
          ),
        ];
      });
      _scrollToBottom();
      widget.onNegotiationComplete?.call(
        ContractNegotiationOutcome(
          status: ContractNegotiationStatus.walkedAway,
          finalTerms: offer,
          remainingPatience: 0,
          roundsTaken: _round,
        ),
      );
      return;
    }

    // Scenariusz 3: Kontroferta w czasie rzeczywistym
    final double concessionRate = salaryRatio >= 0.85 ? 0.35 : 0.16;
    final int gap = _agentDemand.monthlySalaryEur - offer.monthlySalaryEur;
    final int stepDown = (gap * concessionRate).round();
    final int counterSalary = math.max(
      offer.monthlySalaryEur + 500,
      (((_agentDemand.monthlySalaryEur - stepDown) / 500).round() * 500),
    );
    final int counterSigning = offer.signingBonusEur < _agentDemand.signingBonusEur
        ? ((_agentDemand.signingBonusEur * 0.95) / 500).round() * 500
        : _agentDemand.signingBonusEur;

    final ContractOfferTerms nextCounter = _agentDemand.copyWith(
      monthlySalaryEur: counterSalary.clamp(_minSalaryBound, _maxSalaryBound),
      signingBonusEur: counterSigning,
      contractYears: offer.contractYears,
    );

    final String tonePrefix = nextPatience <= 28
        ? 'Ostrzegam, to nasza ostatnia runda ustępstw.'
        : (salaryRatio < 0.80
            ? 'Ta propozycja jest wyraźnie poniżej wartości rynkowej.'
            : 'Zbliżamy się do kompromisu, ale potrzebujemy lepszej bazy.');

    setState(() {
      _isAgentTyping = false;
      _patience = nextPatience;
      _round += 1;
      _agentDemand = nextCounter;
      _messages = <NegotiationChatMessage>[
        ..._messages,
        NegotiationChatMessage(
          id: _nextId(),
          sender: NegotiationSender.agent,
          senderLabel: widget.agentName,
          text:
              '$tonePrefix Kontroferta: ${Formatters.formatCurrency(nextCounter.monthlySalaryEur)}/mies. '
              'oraz ${Formatters.formatCurrency(nextCounter.signingBonusEur)} premii za podpis.',
          timestampLabel: _formattedClockForIndex(_messages.length),
          attachedOffer: nextCounter,
          patienceDelta: patienceDelta,
        ),
      ];
    });
    _scrollToBottom();
  }

  void _acceptAgentDemand() {
    if (!_canInteract) return;
    final accepted = _agentDemand;
    setState(() {
      _managerDraft = accepted;
      _status = ContractNegotiationStatus.accepted;
      _patience = (_patience + 5).clamp(0, 100);
      _messages = <NegotiationChatMessage>[
        ..._messages,
        NegotiationChatMessage(
          id: _nextId(),
          sender: NegotiationSender.manager,
          senderLabel: 'Dyrektor Sportowy (Ty)',
          text:
              'Zgoda. Akceptujemy Waszą kontrofertę na poziomie ${Formatters.formatCurrency(accepted.monthlySalaryEur)}/mies.',
          timestampLabel: _formattedClockForIndex(_messages.length),
          attachedOffer: accepted,
        ),
        NegotiationChatMessage(
          id: _nextId(),
          sender: NegotiationSender.agent,
          senderLabel: widget.agentName,
          text:
              'Świetna decyzja! Podpisujemy kontrakt dla $_resolvedRiderName.',
          timestampLabel: _formattedClockForIndex(_messages.length + 1),
          patienceDelta: 5,
        ),
      ];
    });
    _scrollToBottom();
    widget.onNegotiationComplete?.call(
      ContractNegotiationOutcome(
        status: ContractNegotiationStatus.accepted,
        finalTerms: accepted,
        remainingPatience: _patience,
        roundsTaken: _round,
      ),
    );
  }

  void _walkAway() {
    if (!_canInteract) return;
    setState(() {
      _status = ContractNegotiationStatus.walkedAway;
      _messages = <NegotiationChatMessage>[
        ..._messages,
        NegotiationChatMessage(
          id: _nextId(),
          sender: NegotiationSender.manager,
          senderLabel: 'Dyrektor Sportowy (Ty)',
          text:
              'Nie możemy spełnić tych oczekiwań budżetowych. Kończymy negocjacje.',
          timestampLabel: _formattedClockForIndex(_messages.length),
        ),
      ];
    });
    _scrollToBottom();
    widget.onNegotiationComplete?.call(
      ContractNegotiationOutcome(
        status: ContractNegotiationStatus.walkedAway,
        finalTerms: _managerDraft,
        remainingPatience: _patience,
        roundsTaken: _round,
      ),
    );
  }

  String _yearsLabel(int years) {
    if (years == 1) return 'rok';
    if (years >= 2 && years <= 4) return 'lata';
    return 'lat';
  }

  Color _patienceColor(int patience) {
    if (patience >= 60) return AppColors.statusSuccess;
    if (patience >= 30) return AppColors.amberWarning;
    return AppColors.crimsonAlert;
  }

  String _patienceMoodLabel(int patience) {
    if (patience >= 75) return 'Spokojny';
    if (patience >= 50) return 'Rozważny';
    if (patience >= 28) return 'Niecierpliwy';
    if (patience > 0) return 'Ostatnia szansa';
    return 'Zerwał rozmowy';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final bool isCompact = width < 760;
          final bool isWideDesktop = width >= 1240;

          if (isCompact) {
            return _buildCompactLayout();
          }
          if (isWideDesktop) {
            return _buildWideDesktopLayout();
          }
          return _buildTabletLayout();
        },
      ),
    );
  }

  Widget _buildCompactLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHeaderAndPatienceCard(compact: true),
          const SizedBox(height: 12),
          SizedBox(
            height: 290,
            child: _buildChatCard(),
          ),
          const SizedBox(height: 12),
          _buildBargainingChipsCard(compact: true),
          const SizedBox(height: 12),
          _buildCounterOfferBuilderCard(compact: true),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHeaderAndPatienceCard(compact: false),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(child: _buildChatCard()),
                      const SizedBox(height: 12),
                      _buildBargainingChipsCard(compact: false),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: _buildCounterOfferBuilderCard(compact: false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHeaderAndPatienceCard(compact: false),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  width: 320,
                  child: SingleChildScrollView(
                    child: _buildBargainingChipsCard(compact: false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 6,
                  child: _buildChatCard(),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 390,
                  child: SingleChildScrollView(
                    child: _buildCounterOfferBuilderCard(compact: false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAndPatienceCard({required bool compact}) {
    final Color pColor = _patienceColor(_patience);
    final String mood = _patienceMoodLabel(_patience);

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: compact ? 40 : 46,
                height: compact ? 40 : 46,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.45),
                  ),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.goldAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            widget.agentName,
                            overflow: TextOverflow.ellipsis,
                            style: _interBase.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: compact ? 15 : 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.agencyName} • Kolarz: $_resolvedRiderName ($_resolvedSpecialization)',
                      overflow: TextOverflow.ellipsis,
                      style: _interBase.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...<Widget>[
                const SizedBox(width: 12),
                _buildRoundBadge(),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'CIERPLIWOŚĆ AGENTA',
                  overflow: TextOverflow.ellipsis,
                  style: _interBase.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        mood,
                        overflow: TextOverflow.ellipsis,
                        style: _interBase.copyWith(
                          color: pColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_patience%',
                      style: _tabularBase.copyWith(
                        color: pColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 10,
              color: AppColors.surfaceLight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _patience / 100.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, double value, Widget? child) {
                    return FractionallySizedBox(
                      widthFactor: value.clamp(0.0, 1.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: pColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final Color color;
    final String label;
    switch (_status) {
      case ContractNegotiationStatus.inProgress:
        color = AppColors.accentBlue;
        label = 'NA ŻYWO';
      case ContractNegotiationStatus.accepted:
        color = AppColors.statusSuccess;
        label = 'PODPISANY';
      case ContractNegotiationStatus.walkedAway:
        color = AppColors.crimsonAlert;
        label = 'ZERWANE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: _interBase.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRoundBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Text(
        'Runda $_round',
        style: _tabularBase.copyWith(
          color: AppColors.goldAccent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildChatCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.forum_rounded,
                  size: 16,
                  color: AppColors.goldAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'CZAT NEGOCJACYJNY NA ŻYWO',
                    overflow: TextOverflow.ellipsis,
                    style: _interBase.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (_status != ContractNegotiationStatus.inProgress) ...<Widget>[
                  const SizedBox(width: 8),
                  _NegotiationActionButton(
                    label: 'Nowa sesja',
                    icon: Icons.refresh_rounded,
                    variant: _ActionButtonVariant.secondary,
                    compact: true,
                    onPressed: () {
                      setState(_initSession);
                    },
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          Expanded(
            child: ListView.separated(
              controller: _chatScrollController,
              padding: const EdgeInsets.all(14),
              itemCount: _messages.length + (_isAgentTyping ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                if (_isAgentTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildChatBubble(_messages[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.goldAccent,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${widget.agentName} analizuje ofertę...',
              style: _interBase.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(NegotiationChatMessage message) {
    if (message.sender == NegotiationSender.system) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Text(
            message.text,
            textAlign: TextAlign.center,
            style: _interBase.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final bool isManager = message.sender == NegotiationSender.manager;
    final Alignment alignment =
        isManager ? Alignment.centerRight : Alignment.centerLeft;
    final Color bubbleColor = isManager
        ? AppColors.primaryAccent.withValues(alpha: 0.22)
        : AppColors.surfaceLight;
    final Color borderColor = isManager
        ? AppColors.primaryAccent.withValues(alpha: 0.6)
        : AppTheme.borderColor;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    message.senderLabel,
                    style: _interBase.copyWith(
                      color: isManager
                          ? AppColors.goldAccent
                          : AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message.timestampLabel,
                    style: _tabularBase.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  if (message.patienceDelta != null) ...<Widget>[
                    const SizedBox(width: 8),
                    _buildPatienceDeltaChip(message.patienceDelta!),
                  ],
                ],
              ),
              if (message.playedChip != null) ...<Widget>[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.goldAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        message.playedChip!.icon,
                        size: 12,
                        color: AppColors.goldAccent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        message.playedChip!.shortTag,
                        style: _interBase.copyWith(
                          color: AppColors.goldAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                message.text,
                style: _interBase.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.38,
                ),
              ),
              if (message.attachedOffer != null) ...<Widget>[
                const SizedBox(height: 8),
                _buildOfferMiniSummary(message.attachedOffer!, isManager),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatienceDeltaChip(int delta) {
    final bool positive = delta >= 0;
    final Color color =
        positive ? AppColors.statusSuccess : AppColors.crimsonAlert;
    final String text = positive ? '+$delta% cierpl.' : '$delta% cierpl.';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: _tabularBase.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildOfferMiniSummary(ContractOfferTerms offer, bool isManager) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        children: <Widget>[
          Text(
            '${Formatters.formatCurrency(offer.monthlySalaryEur)}/m',
            style: _tabularBase.copyWith(
              color: isManager ? AppColors.goldAccent : AppColors.accentBlue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${offer.contractYears} ${_yearsLabel(offer.contractYears)}',
            style: _tabularBase.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          Text(
            'Podpis: ${Formatters.formatCompactCurrency(offer.signingBonusEur)}',
            style: _tabularBase.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          Text(
            'Wygrana: ${Formatters.formatCompactCurrency(offer.winBonusEur)}',
            style: _tabularBase.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBargainingChipsCard({required bool compact}) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.style_rounded,
                size: 16,
                color: AppColors.goldAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'KARTY PRZETARGOWE',
                  style: _interBase.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                '${_usedChips.length}/${BargainingChipType.values.length}',
                style: _tabularBase.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...BargainingChipType.values.map((BargainingChipType chip) {
            final bool used = _usedChips.contains(chip);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _BargainingChipCardButton(
                chip: chip,
                isUsed: used,
                isEnabled: _canInteract && !used,
                onTap: () => _playBargainingChip(chip),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCounterOfferBuilderCard({required bool compact}) {
    final int salaryDelta =
        _managerDraft.monthlySalaryEur - _agentDemand.monthlySalaryEur;
    final bool meetsSalary = salaryDelta >= 0;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.tune_rounded,
                size: 16,
                color: AppColors.goldAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'KONTROFERTA NA ŻYWO',
                  style: _interBase.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Porównanie żądania agenta i oferty menedżera
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Żądanie agenta',
                        overflow: TextOverflow.ellipsis,
                        style: _interBase.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${Formatters.formatCurrency(_agentDemand.monthlySalaryEur)}/mies.',
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: _tabularBase.copyWith(
                          color: AppColors.accentBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Twoja propozycja',
                        overflow: TextOverflow.ellipsis,
                        style: _interBase.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${Formatters.formatCurrency(_managerDraft.monthlySalaryEur)}/mies.',
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: _tabularBase.copyWith(
                          color: AppColors.goldAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Różnica / Budżet roczny',
                        overflow: TextOverflow.ellipsis,
                        style: _interBase.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${meetsSalary ? '+' : ''}${Formatters.formatCompactCurrency(salaryDelta)} • ${Formatters.formatCompactCurrency(_managerDraft.annualSalaryEur)}/rok',
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: _tabularBase.copyWith(
                          color: meetsSalary
                              ? AppColors.statusSuccess
                              : AppColors.amberWarning,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Suwak pensji miesięcznej + szybkie kroki
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Pensja miesięczna',
                style: _interBase.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _StepperMiniButton(
                    icon: Icons.remove_rounded,
                    tooltip: 'Zmniejsz pensję o €500',
                    enabled: _canInteract &&
                        _managerDraft.monthlySalaryEur > _minSalaryBound,
                    onPressed: () {
                      _updateDraft(
                        _managerDraft.copyWith(
                          monthlySalaryEur: math.max(
                            _minSalaryBound,
                            _managerDraft.monthlySalaryEur - 500,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  _StepperMiniButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Zwiększ pensję o €500',
                    enabled: _canInteract &&
                        _managerDraft.monthlySalaryEur < _maxSalaryBound,
                    onPressed: () {
                      _updateDraft(
                        _managerDraft.copyWith(
                          monthlySalaryEur: math.min(
                            _maxSalaryBound,
                            _managerDraft.monthlySalaryEur + 500,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.goldAccent,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.goldAccent,
              overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _managerDraft.monthlySalaryEur
                  .toDouble()
                  .clamp(_minSalaryBound.toDouble(), _maxSalaryBound.toDouble()),
              min: _minSalaryBound.toDouble(),
              max: _maxSalaryBound.toDouble(),
              divisions: (_maxSalaryBound - _minSalaryBound) ~/ 500,
              onChanged: _canInteract
                  ? (double value) {
                      final rounded = (value / 500).round() * 500;
                      _updateDraft(
                        _managerDraft.copyWith(monthlySalaryEur: rounded),
                      );
                    }
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          // Długość kontraktu (1-4 lata)
          Text(
            'Długość kontraktu',
            style: _interBase.copyWith(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: <int>[1, 2, 3, 4].map((int years) {
              final bool selected = _managerDraft.contractYears == years;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: years == 4 ? 0 : 6),
                  child: _SelectablePillButton(
                    label: '$years ${_yearsLabel(years)}',
                    selected: selected,
                    enabled: _canInteract,
                    onTap: () {
                      _updateDraft(
                        _managerDraft.copyWith(contractYears: years),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Premia za podpis i za zwycięstwo
          Row(
            children: <Widget>[
              Expanded(
                child: _BonusAdjustBox(
                  title: 'Premia za podpis',
                  valueText: Formatters.formatCompactCurrency(
                    _managerDraft.signingBonusEur,
                  ),
                  enabled: _canInteract,
                  onDecrease: () {
                    _updateDraft(
                      _managerDraft.copyWith(
                        signingBonusEur:
                            math.max(0, _managerDraft.signingBonusEur - 2000),
                      ),
                    );
                  },
                  onIncrease: () {
                    _updateDraft(
                      _managerDraft.copyWith(
                        signingBonusEur: math.min(
                            200000, _managerDraft.signingBonusEur + 2000),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BonusAdjustBox(
                  title: 'Premia za wygraną',
                  valueText: Formatters.formatCompactCurrency(
                    _managerDraft.winBonusEur,
                  ),
                  enabled: _canInteract,
                  onDecrease: () {
                    _updateDraft(
                      _managerDraft.copyWith(
                        winBonusEur:
                            math.max(0, _managerDraft.winBonusEur - 500),
                      ),
                    );
                  },
                  onIncrease: () {
                    _updateDraft(
                      _managerDraft.copyWith(
                        winBonusEur:
                            math.min(50000, _managerDraft.winBonusEur + 500),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Rola w drużynie
          Text(
            'Rola w drużynie',
            style: _interBase.copyWith(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <RiderRole>[
              RiderRole.teamLeader,
              RiderRole.coLeader,
              RiderRole.sprinter,
              RiderRole.superDomestique,
            ].map((RiderRole role) {
              final bool selected = _managerDraft.role == role;
              return _SelectablePillButton(
                label: role.label,
                selected: selected,
                enabled: _canInteract,
                onTap: () => _updateDraft(_managerDraft.copyWith(role: role)),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          // Przyciski akcji
          _NegotiationActionButton(
            label: 'Wyślij kontrofertę',
            icon: Icons.send_rounded,
            variant: _ActionButtonVariant.primary,
            enabled: _canInteract,
            onPressed: _sendOffer,
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: _NegotiationActionButton(
                  label: 'Akceptuj żądania',
                  icon: Icons.check_circle_outline_rounded,
                  variant: _ActionButtonVariant.goldOutline,
                  enabled: _canInteract,
                  compact: true,
                  onPressed: _acceptAgentDemand,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NegotiationActionButton(
                  label: 'Odejdź od stołu',
                  icon: Icons.close_rounded,
                  variant: _ActionButtonVariant.dangerOutline,
                  enabled: _canInteract,
                  compact: true,
                  onPressed: _walkAway,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BargainingChipCardButton extends StatefulWidget {
  final BargainingChipType chip;
  final bool isUsed;
  final bool isEnabled;
  final VoidCallback onTap;

  const _BargainingChipCardButton({
    required this.chip,
    required this.isUsed,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_BargainingChipCardButton> createState() =>
      _BargainingChipCardButtonState();
}

class _BargainingChipCardButtonState extends State<_BargainingChipCardButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isEnabled;
    final Color borderColor;
    if (widget.isUsed) {
      borderColor = AppColors.statusSuccess.withValues(alpha: 0.55);
    } else if (_focused) {
      borderColor = AppColors.goldAccent;
    } else if (_hovered && active) {
      borderColor = AppColors.goldAccent.withValues(alpha: 0.7);
    } else {
      borderColor = AppTheme.borderColor;
    }

    final Color bgColor;
    if (widget.isUsed) {
      bgColor = AppColors.statusSuccess.withValues(alpha: 0.10);
    } else if (_pressed && active) {
      bgColor = AppColors.goldAccent.withValues(alpha: 0.16);
    } else if (_hovered && active) {
      bgColor = AppColors.surfaceLight;
    } else {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.72);
    }

    return FocusableActionDetector(
      enabled: active,
      mouseCursor:
          active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onShowHoverHighlight: (bool value) => setState(() => _hovered = value),
      onShowFocusHighlight: (bool value) => setState(() => _focused = value),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (active) widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: active ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: active ? () => setState(() => _pressed = false) : null,
        onTap: active ? widget.onTap : null,
        child: AnimatedScale(
          scale: (_pressed && active) ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Opacity(
              opacity: (active || widget.isUsed) ? 1.0 : 0.45,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: widget.isUsed
                          ? AppColors.statusSuccess.withValues(alpha: 0.18)
                          : AppColors.goldAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      widget.isUsed ? Icons.check_rounded : widget.chip.icon,
                      size: 18,
                      color: widget.isUsed
                          ? AppColors.statusSuccess
                          : AppColors.goldAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                widget.chip.title,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  letterSpacing: -0.2,
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.isUsed
                                  ? 'UŻYTO'
                                  : '-${(widget.chip.salaryDemandReductionFactor * 100).round()}%',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontFeatures: <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                                color: AppColors.goldAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.chip.description,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            letterSpacing: -0.2,
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectablePillButton extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _SelectablePillButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_SelectablePillButton> createState() => _SelectablePillButtonState();
}

class _SelectablePillButtonState extends State<_SelectablePillButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.enabled;
    final Color bg = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.35)
        : (_hovered && active ? AppColors.surfaceLight : AppColors.background);
    final Color border = _focused
        ? AppColors.goldAccent
        : (widget.selected
            ? AppColors.goldAccent.withValues(alpha: 0.85)
            : (_hovered && active
                ? AppColors.textSecondary.withValues(alpha: 0.5)
                : AppTheme.borderColor));

    return FocusableActionDetector(
      enabled: active,
      mouseCursor:
          active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (active) widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: active ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: active ? () => setState(() => _pressed = false) : null,
        onTap: active ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: _pressed && active
              ? Matrix4.diagonal3Values(0.97, 0.97, 1.0)
              : Matrix4.identity(),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: border, width: _focused ? 1.5 : 1.0),
          ),
          child: Opacity(
            opacity: active ? 1.0 : 0.45,
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                letterSpacing: -0.2,
                color: widget.selected
                    ? AppColors.goldAccent
                    : AppColors.textPrimary,
                fontSize: 11,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepperMiniButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  const _StepperMiniButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_StepperMiniButton> createState() => _StepperMiniButtonState();
}

class _StepperMiniButtonState extends State<_StepperMiniButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.enabled;
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: active,
        mouseCursor:
            active ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
        onShowFocusHighlight: (bool v) => setState(() => _focused = v),
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (active) widget.onPressed();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTapDown: active ? (_) => setState(() => _pressed = true) : null,
          onTapUp: active ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: active ? () => setState(() => _pressed = false) : null,
          onTap: active ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _pressed && active
                  ? AppColors.goldAccent.withValues(alpha: 0.2)
                  : (_hovered && active
                      ? AppColors.surfaceLight
                      : AppColors.background),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : (_hovered && active
                        ? AppColors.goldAccent.withValues(alpha: 0.6)
                        : AppTheme.borderColor),
              ),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: active ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _BonusAdjustBox extends StatelessWidget {
  final String title;
  final String valueText;
  final bool enabled;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _BonusAdjustBox({
    required this.title,
    required this.valueText,
    required this.enabled,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text(
                  valueText,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _StepperMiniButton(
                    icon: Icons.remove_rounded,
                    tooltip: 'Zmniejsz $title',
                    enabled: enabled,
                    onPressed: onDecrease,
                  ),
                  const SizedBox(width: 4),
                  _StepperMiniButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Zwiększ $title',
                    enabled: enabled,
                    onPressed: onIncrease,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _ActionButtonVariant {
  primary,
  secondary,
  goldOutline,
  dangerOutline,
}

class _NegotiationActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final _ActionButtonVariant variant;
  final bool enabled;
  final bool compact;
  final VoidCallback onPressed;

  const _NegotiationActionButton({
    required this.label,
    required this.icon,
    required this.variant,
    this.enabled = true,
    this.compact = false,
    required this.onPressed,
  });

  @override
  State<_NegotiationActionButton> createState() =>
      _NegotiationActionButtonState();
}

class _NegotiationActionButtonState extends State<_NegotiationActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.enabled;

    Color bgColor;
    Color fgColor;
    Color borderColor;

    switch (widget.variant) {
      case _ActionButtonVariant.primary:
        bgColor = _pressed && active
            ? AppColors.primaryAccent
            : (_hovered && active
                ? AppColors.primaryAccent.withValues(alpha: 0.92)
                : AppColors.primaryAccent.withValues(alpha: 0.82));
        fgColor = AppColors.textPrimary;
        borderColor = _focused
            ? AppColors.goldAccent
            : AppColors.goldAccent.withValues(alpha: _hovered ? 0.8 : 0.35);
      case _ActionButtonVariant.secondary:
        bgColor = _hovered && active
            ? AppColors.surfaceLight
            : AppColors.background;
        fgColor = AppColors.textPrimary;
        borderColor = _focused ? AppColors.goldAccent : AppTheme.borderColor;
      case _ActionButtonVariant.goldOutline:
        bgColor = _hovered && active
            ? AppColors.goldAccent.withValues(alpha: 0.14)
            : Colors.transparent;
        fgColor = AppColors.goldAccent;
        borderColor = AppColors.goldAccent.withValues(alpha: _focused ? 1.0 : 0.6);
      case _ActionButtonVariant.dangerOutline:
        bgColor = _hovered && active
            ? AppColors.crimsonAlert.withValues(alpha: 0.14)
            : Colors.transparent;
        fgColor = AppColors.crimsonAlert;
        borderColor =
            AppColors.crimsonAlert.withValues(alpha: _focused ? 1.0 : 0.55);
    }

    return FocusableActionDetector(
      enabled: active,
      mouseCursor:
          active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (active) widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: active ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: active ? () => setState(() => _pressed = false) : null,
        onTap: active ? widget.onPressed : null,
        child: AnimatedScale(
          scale: (_pressed && active) ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 14,
              vertical: widget.compact ? 9 : 11,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: borderColor,
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Opacity(
              opacity: active ? 1.0 : 0.42,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(widget.icon, size: 15, color: fgColor),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      widget.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.2,
                        color: fgColor,
                        fontSize: widget.compact ? 11 : 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
