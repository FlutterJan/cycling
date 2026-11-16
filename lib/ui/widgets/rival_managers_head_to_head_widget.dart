import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Styl taktyczny dyrektora sportowego rywalizującej drużyny WorldTour.
enum RivalTacticalStyle {
  aggressive(
    label: 'Agresywny',
    shortLabel: 'Agresja',
    icon: Icons.flash_on_rounded,
    accentColor: AppColors.crimsonAlert,
    summary:
        'Inicjuje ataki już na przedostatnich przełęczach, narzuca wysokie tempo na wietrze bocznym i często wysyła stacje przekaźnikowe do ucieczek.',
    counterAdvice:
        'Utrzymuj 2 pomocników blisko lidera przed kluczowymi zjazdami i nie reaguj nerwowo na wczesne skoki z daleka.',
  ),
  calculating(
    label: 'Kalkulujący',
    shortLabel: 'Kalkulacja',
    icon: Icons.calculate_rounded,
    accentColor: AppColors.accentBlue,
    summary:
        'Kontroluje peleton równym tempem diesla na bazie mocy W/kg, chroni lidera do ostatnich 2 km i wygrywa wyścigi o pojedyncze sekundy.',
    counterAdvice:
        'Złam rytm jego pociągu górskiego atakiem z zaskoczenia na stromym fragmencie >10% lub na sektorze bruku.',
  ),
  stageHunter(
    label: 'Łowca Etapów',
    shortLabel: 'Łowca',
    icon: Icons.flag_rounded,
    accentColor: AppColors.goldAccent,
    summary:
        'Poluje na zwycięstwa etapowe, punkty KOM i premie lotne z odjazdów, rzadko angażując ekipę w całodniową obronę klasyfikacji GC.',
    counterAdvice:
        'Wykorzystaj jego pomocników w ucieczce jako darmowy pociąg lub zablokuj skład na sprincie lotnym.',
  );

  final String label;
  final String shortLabel;
  final IconData icon;
  final Color accentColor;
  final String summary;
  final String counterAdvice;

  const RivalTacticalStyle({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.accentColor,
    required this.summary,
    required this.counterAdvice,
  });
}

/// Ton wypowiedzi na konferencji prasowej między dyrektorami sportowymi.
enum PressStatementSentiment {
  respectful(
    label: 'Szacunek',
    color: AppColors.statusSuccess,
    icon: Icons.handshake_rounded,
  ),
  mindGames(
    label: 'Gry psychologiczne',
    color: AppColors.cyanAccent,
    icon: Icons.psychology_rounded,
  ),
  provocative(
    label: 'Prowokacja',
    color: AppColors.amberWarning,
    icon: Icons.campaign_rounded,
  ),
  hostile(
    label: 'Ostra riposta',
    color: AppColors.crimsonAlert,
    icon: Icons.local_fire_department_rounded,
  );

  final String label;
  final Color color;
  final IconData icon;

  const PressStatementSentiment({
    required this.label,
    required this.color,
    required this.icon,
  });
}

/// Kryterium sortowania listy rywali WorldTour.
enum RivalSortMode {
  intensity('Intensywność'),
  totalDuels('Liczba pojedynków'),
  balance('Bilans H2H');

  final String label;
  const RivalSortMode(this.label);
}

/// Pojedyncze bezpośrednie starcie na trasie z ekipą rywala.
class HeadToHeadDuelResult {
  final String raceName;
  final String dateLabel;
  final String raceCategory;
  final bool playerWon;
  final int playerBestPosition;
  final int rivalBestPosition;
  final int timeDeltaSeconds;
  final String keyTacticalNote;

  const HeadToHeadDuelResult({
    required this.raceName,
    required this.dateLabel,
    required this.raceCategory,
    required this.playerWon,
    required this.playerBestPosition,
    required this.rivalBestPosition,
    required this.timeDeltaSeconds,
    required this.keyTacticalNote,
  });
}

/// Wpis z historii wzajemnych wypowiedzi na konferencjach prasowych.
class PressConferenceExchange {
  final String id;
  final String dateLabel;
  final String eventContext;
  final String speakerName;
  final bool isPlayerStatement;
  final String quote;
  final PressStatementSentiment sentiment;
  final int moraleImpact;
  final int mediaHeat;

  const PressConferenceExchange({
    required this.id,
    required this.dateLabel,
    required this.eventContext,
    required this.speakerName,
    required this.isPlayerStatement,
    required this.quote,
    required this.sentiment,
    this.moraleImpact = 0,
    this.mediaHeat = 50,
  });
}

/// Profil rywalizującego dyrektora sportowego innej ekipy WorldTour.
class RivalDirectorProfile {
  final String id;
  final String managerName;
  final String nationalityCode;
  final String teamName;
  final String teamShortCode;
  final Color teamPrimaryColor;
  final Color teamSecondaryColor;
  final RivalTacticalStyle tacticalStyle;
  final int rivalryIntensity;
  final int playerWins;
  final int rivalWins;
  final int draws;
  final int gcBattlesWonByPlayer;
  final int gcBattlesWonByRival;
  final int stageWinsPlayer;
  final int stageWinsRival;
  final int aggressionRating;
  final int tacticalAdaptability;
  final int mediaPressureResistance;
  final String signatureTactic;
  final List<HeadToHeadDuelResult> recentEncounters;
  final List<PressConferenceExchange> pressHistory;

  const RivalDirectorProfile({
    required this.id,
    required this.managerName,
    required this.nationalityCode,
    required this.teamName,
    required this.teamShortCode,
    required this.teamPrimaryColor,
    required this.teamSecondaryColor,
    required this.tacticalStyle,
    required this.rivalryIntensity,
    required this.playerWins,
    required this.rivalWins,
    this.draws = 0,
    this.gcBattlesWonByPlayer = 0,
    this.gcBattlesWonByRival = 0,
    this.stageWinsPlayer = 0,
    this.stageWinsRival = 0,
    this.aggressionRating = 50,
    this.tacticalAdaptability = 50,
    this.mediaPressureResistance = 50,
    required this.signatureTactic,
    this.recentEncounters = const [],
    this.pressHistory = const [],
  });

  int get totalDuels => playerWins + rivalWins + draws;

  double get playerWinRate {
    final decided = playerWins + rivalWins;
    if (decided <= 0) return 0.5;
    return playerWins / decided;
  }

  int get netBalance => playerWins - rivalWins;

  String get rivalryTierLabel {
    if (rivalryIntensity >= 85) return 'Zaciekła Rywalizacja';
    if (rivalryIntensity >= 65) return 'Taktyczny Szach';
    if (rivalryIntensity >= 40) return 'Napięcie Sportowe';
    return 'Sportowy Szacunek';
  }

  String get initials {
    final parts = managerName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'DS';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(1, 2)).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  RivalDirectorProfile copyWith({
    int? rivalryIntensity,
    List<PressConferenceExchange>? pressHistory,
  }) {
    return RivalDirectorProfile(
      id: id,
      managerName: managerName,
      nationalityCode: nationalityCode,
      teamName: teamName,
      teamShortCode: teamShortCode,
      teamPrimaryColor: teamPrimaryColor,
      teamSecondaryColor: teamSecondaryColor,
      tacticalStyle: tacticalStyle,
      rivalryIntensity: rivalryIntensity ?? this.rivalryIntensity,
      playerWins: playerWins,
      rivalWins: rivalWins,
      draws: draws,
      gcBattlesWonByPlayer: gcBattlesWonByPlayer,
      gcBattlesWonByRival: gcBattlesWonByRival,
      stageWinsPlayer: stageWinsPlayer,
      stageWinsRival: stageWinsRival,
      aggressionRating: aggressionRating,
      tacticalAdaptability: tacticalAdaptability,
      mediaPressureResistance: mediaPressureResistance,
      signatureTactic: signatureTactic,
      recentEncounters: recentEncounters,
      pressHistory: pressHistory ?? this.pressHistory,
    );
  }
}

/// Domyślny katalog rywali WorldTour do podglądu i integracji z karierą.
class RivalManagersSampleCatalog {
  RivalManagersSampleCatalog._();

  static List<RivalDirectorProfile> defaultRivals() {
    return const [
      RivalDirectorProfile(
        id: 'ds_velasco',
        managerName: 'Matej Velasco',
        nationalityCode: 'SLO',
        teamName: 'Emirates Alpine Pro',
        teamShortCode: 'EAP',
        teamPrimaryColor: Color(0xFFEF4444),
        teamSecondaryColor: Color(0xFFF3F4F6),
        tacticalStyle: RivalTacticalStyle.aggressive,
        rivalryIntensity: 91,
        playerWins: 11,
        rivalWins: 9,
        draws: 2,
        gcBattlesWonByPlayer: 2,
        gcBattlesWonByRival: 2,
        stageWinsPlayer: 9,
        stageWinsRival: 7,
        aggressionRating: 94,
        tacticalAdaptability: 86,
        mediaPressureResistance: 78,
        signatureTactic: 'Atak lidera z daleka na przedostatnim szczycie HC',
        recentEncounters: [
          HeadToHeadDuelResult(
            raceName: 'Tour de France — Etap 14 (Tourmalet)',
            dateLabel: 'Lipiec 2026',
            raceCategory: 'Grand Tour',
            playerWon: true,
            playerBestPosition: 1,
            rivalBestPosition: 2,
            timeDeltaSeconds: -18,
            keyTacticalNote: 'Kontra na ostatnich 800 m podjazdu po wyczerpaniu jego pomocników.',
          ),
          HeadToHeadDuelResult(
            raceName: 'Liège-Bastogne-Liège',
            dateLabel: 'Kwiecień 2026',
            raceCategory: 'Monument',
            playerWon: false,
            playerBestPosition: 3,
            rivalBestPosition: 1,
            timeDeltaSeconds: 27,
            keyTacticalNote: 'Solowy odjazd na Côte de la Redoute przy 7.1 W/kg.',
          ),
          HeadToHeadDuelResult(
            raceName: 'Critérium du Dauphiné — GC',
            dateLabel: 'Czerwiec 2026',
            raceCategory: 'WT Stage Race',
            playerWon: true,
            playerBestPosition: 1,
            rivalBestPosition: 2,
            timeDeltaSeconds: -9,
            keyTacticalNote: 'Obrona przewagi na finałowym podjeździe dzięki stacji przekaźnikowej.',
          ),
        ],
        pressHistory: [
          PressConferenceExchange(
            id: 'p_velasco_1',
            dateLabel: '14 Lip 2026',
            eventContext: 'Konferencja po 14. etapie Tour de France',
            speakerName: 'Matej Velasco',
            isPlayerStatement: false,
            quote:
                'Dziś wygraliście o kilkanaście sekund, ale w trzecim tygodniu Alpy zweryfikują, kto naprawdę ma nogi na 3000 metrów.',
            sentiment: PressStatementSentiment.provocative,
            moraleImpact: -1,
            mediaHeat: 84,
          ),
          PressConferenceExchange(
            id: 'p_velasco_2',
            dateLabel: '14 Lip 2026',
            eventContext: 'Odpowiedź w strefie mieszanej',
            speakerName: 'Twoja Ekipa WT',
            isPlayerStatement: true,
            quote:
                'Nasi górale dopiero się rozgrzewają. Szanujemy tempo Emirates Alpine, lecz w dolinie to my dyktujemy warunki.',
            sentiment: PressStatementSentiment.mindGames,
            moraleImpact: 3,
            mediaHeat: 88,
          ),
          PressConferenceExchange(
            id: 'p_velasco_3',
            dateLabel: '26 Kwi 2026',
            eventContext: 'Po finiszu Liège-Bastogne-Liège',
            speakerName: 'Matej Velasco',
            isPlayerStatement: false,
            quote:
                'Kiedy widzimy zawahanie w grupie pościgowej, nigdy nie czekamy na ostatni kilometr.',
            sentiment: PressStatementSentiment.respectful,
            moraleImpact: 1,
            mediaHeat: 62,
          ),
        ],
      ),
      RivalDirectorProfile(
        id: 'ds_vandijk',
        managerName: 'Henrik van Dijk',
        nationalityCode: 'NED',
        teamName: 'Nordic Visma Dynamics',
        teamShortCode: 'NVD',
        teamPrimaryColor: Color(0xFFD4AF37),
        teamSecondaryColor: Color(0xFF181B22),
        tacticalStyle: RivalTacticalStyle.calculating,
        rivalryIntensity: 82,
        playerWins: 7,
        rivalWins: 10,
        draws: 1,
        gcBattlesWonByPlayer: 1,
        gcBattlesWonByRival: 3,
        stageWinsPlayer: 6,
        stageWinsRival: 7,
        aggressionRating: 64,
        tacticalAdaptability: 95,
        mediaPressureResistance: 92,
        signatureTactic: 'Pociąg 4 górali na 88% FTP i podwójny atak na 3 km przed szczytem',
        recentEncounters: [
          HeadToHeadDuelResult(
            raceName: 'Giro d\'Italia — Etap 16 (Stelvio)',
            dateLabel: 'Maj 2026',
            raceCategory: 'Grand Tour',
            playerWon: false,
            playerBestPosition: 2,
            rivalBestPosition: 1,
            timeDeltaSeconds: 34,
            keyTacticalNote: 'Rozbili grupę na wysokości 2400 m n.p.m. równym tempem pociągu.',
          ),
          HeadToHeadDuelResult(
            raceName: 'Paris-Nice — Czasówka Drużynowa',
            dateLabel: 'Marzec 2026',
            raceCategory: 'WT Stage Race',
            playerWon: true,
            playerBestPosition: 1,
            rivalBestPosition: 2,
            timeDeltaSeconds: -6,
            keyTacticalNote: 'Lepsze zmiany aerodynamiczne na bocznym wietrze.',
          ),
        ],
        pressHistory: [
          PressConferenceExchange(
            id: 'p_vandijk_1',
            dateLabel: '22 Maj 2026',
            eventContext: 'Briefing przed 3. tygodniem Giro',
            speakerName: 'Henrik van Dijk',
            isPlayerStatement: false,
            quote:
                'Wszystko mamy policzone co do kilodżula. Jeśli ktoś atakuje przed szczytem bez planu żywieniowego, zapłaci za to w niedzielę.',
            sentiment: PressStatementSentiment.mindGames,
            moraleImpact: 0,
            mediaHeat: 74,
          ),
          PressConferenceExchange(
            id: 'p_vandijk_2',
            dateLabel: '22 Maj 2026',
            eventContext: 'Konferencja przedetapowa',
            speakerName: 'Twoja Ekipa WT',
            isPlayerStatement: true,
            quote:
                'Arkusz kalkulacyjny nie jedzie w deszczu na zjeździe. Dziś liczy się instynkt kolarzy.',
            sentiment: PressStatementSentiment.provocative,
            moraleImpact: 2,
            mediaHeat: 79,
          ),
        ],
      ),
      RivalDirectorProfile(
        id: 'ds_peeters',
        managerName: 'Bram Peeters',
        nationalityCode: 'BEL',
        teamName: 'Flanders Cobble Pro',
        teamShortCode: 'FCP',
        teamPrimaryColor: Color(0xFF38BDF8),
        teamSecondaryColor: Color(0xFF0F1115),
        tacticalStyle: RivalTacticalStyle.stageHunter,
        rivalryIntensity: 68,
        playerWins: 8,
        rivalWins: 6,
        draws: 3,
        gcBattlesWonByPlayer: 1,
        gcBattlesWonByRival: 0,
        stageWinsPlayer: 7,
        stageWinsRival: 6,
        aggressionRating: 78,
        tacticalAdaptability: 84,
        mediaPressureResistance: 75,
        signatureTactic: 'Ranty przy wietrze >35 km/h i perfekcyjny pociąg sprinterski',
        recentEncounters: [
          HeadToHeadDuelResult(
            raceName: 'Paris-Roubaix',
            dateLabel: 'Kwiecień 2026',
            raceCategory: 'Monument',
            playerWon: true,
            playerBestPosition: 1,
            rivalBestPosition: 2,
            timeDeltaSeconds: -2,
            keyTacticalNote: 'Wygrany sprint dwóch kolarzy na welodromie w Roubaix.',
          ),
          HeadToHeadDuelResult(
            raceName: 'Ronde van Vlaanderen',
            dateLabel: 'Kwiecień 2026',
            raceCategory: 'Monument',
            playerWon: false,
            playerBestPosition: 4,
            rivalBestPosition: 1,
            timeDeltaSeconds: 41,
            keyTacticalNote: 'Perfekcyjne ustawienie przed Oude Kwaremont.',
          ),
        ],
        pressHistory: [
          PressConferenceExchange(
            id: 'p_peeters_1',
            dateLabel: '12 Kwi 2026',
            eventContext: 'Welodrom w Roubaix',
            speakerName: 'Bram Peeters',
            isPlayerStatement: false,
            quote:
                'Wielki pojedynek na bruku. Gratuluję przygotowania ciśnienia w oponach, na Carrefour de l\'Arbre byliście nie do ruszenia.',
            sentiment: PressStatementSentiment.respectful,
            moraleImpact: 2,
            mediaHeat: 55,
          ),
        ],
      ),
      RivalDirectorProfile(
        id: 'ds_moreau',
        managerName: 'Julien Moreau',
        nationalityCode: 'FRA',
        teamName: 'Hexagone Crédit Cycliste',
        teamShortCode: 'HCC',
        teamPrimaryColor: Color(0xFF10B981),
        teamSecondaryColor: Color(0xFFF3F4F6),
        tacticalStyle: RivalTacticalStyle.stageHunter,
        rivalryIntensity: 54,
        playerWins: 6,
        rivalWins: 4,
        draws: 1,
        gcBattlesWonByPlayer: 1,
        gcBattlesWonByRival: 0,
        stageWinsPlayer: 5,
        stageWinsRival: 4,
        aggressionRating: 71,
        tacticalAdaptability: 73,
        mediaPressureResistance: 66,
        signatureTactic: 'Codzienna ucieczka po koszulkę w grochy na etapach górskich',
        recentEncounters: [
          HeadToHeadDuelResult(
            raceName: 'La Vuelta — Etap 11',
            dateLabel: 'Sierpień 2026',
            raceCategory: 'Grand Tour',
            playerWon: true,
            playerBestPosition: 2,
            rivalBestPosition: 5,
            timeDeltaSeconds: -46,
            keyTacticalNote: 'Skuteczny pościg peletonu mimo dwóch ich kolarzy w odjeździe.',
          ),
        ],
        pressHistory: [
          PressConferenceExchange(
            id: 'p_moreau_1',
            dateLabel: '28 Sie 2026',
            eventContext: 'Strefa mety La Vuelta',
            speakerName: 'Julien Moreau',
            isPlayerStatement: false,
            quote:
                'Czasami macie za dużo respektu do kalkulacji GC. Publiczność kocha odważne ucieczki!',
            sentiment: PressStatementSentiment.provocative,
            moraleImpact: 0,
            mediaHeat: 58,
          ),
        ],
      ),
    ];
  }
}

/// Ekran / panel rywalizacji z dyrektorami sportowymi innych ekip WorldTour.
///
/// Prezentuje bilans bezpośrednich pojedynków (Head-to-Head), styl taktyczny
/// rywala (Agresywny, Kalkulujący, Łowca Etapów) oraz interaktywną historię
/// wypowiedzi na konferencjach prasowych.
class RivalManagersHeadToHeadWidget extends StatefulWidget {
  final List<RivalDirectorProfile>? rivals;
  final String playerManagerName;
  final String playerTeamName;
  final String? initialSelectedRivalId;
  final void Function(
    RivalDirectorProfile rival,
    PressConferenceExchange exchange,
  )? onSendPressResponse;
  final ValueChanged<RivalDirectorProfile>? onSelectRival;

  const RivalManagersHeadToHeadWidget({
    super.key,
    this.rivals,
    this.playerManagerName = 'Dyrektor Sportowy',
    this.playerTeamName = 'Twoja Ekipa WT',
    this.initialSelectedRivalId,
    this.onSendPressResponse,
    this.onSelectRival,
  });

  @override
  State<RivalManagersHeadToHeadWidget> createState() =>
      _RivalManagersHeadToHeadWidgetState();
}

class _RivalManagersHeadToHeadWidgetState
    extends State<RivalManagersHeadToHeadWidget> {
  late List<RivalDirectorProfile> _rivals;
  RivalTacticalStyle? _styleFilter;
  RivalSortMode _sortMode = RivalSortMode.intensity;
  String? _selectedRivalId;
  PressStatementSentiment _selectedResponseSentiment =
      PressStatementSentiment.mindGames;
  final TextEditingController _quoteController = TextEditingController();
  String? _lastFeedbackBanner;

  static const TextStyle _baseInter = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
  );

  @override
  void initState() {
    super.initState();
    _rivals = List<RivalDirectorProfile>.from(
      widget.rivals ?? RivalManagersSampleCatalog.defaultRivals(),
    );
    _selectedRivalId = _resolveInitialSelection();
  }

  @override
  void didUpdateWidget(covariant RivalManagersHeadToHeadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rivals != oldWidget.rivals && widget.rivals != null) {
      _rivals = List<RivalDirectorProfile>.from(widget.rivals!);
      _selectedRivalId = _resolveInitialSelection();
    }
  }

  @override
  void dispose() {
    _quoteController.dispose();
    super.dispose();
  }

  String? _resolveInitialSelection() {
    if (_rivals.isEmpty) return null;
    if (widget.initialSelectedRivalId != null &&
        _rivals.any((r) => r.id == widget.initialSelectedRivalId)) {
      return widget.initialSelectedRivalId;
    }
    if (_selectedRivalId != null &&
        _rivals.any((r) => r.id == _selectedRivalId)) {
      return _selectedRivalId;
    }
    return _rivals.first.id;
  }

  List<RivalDirectorProfile> get _filteredRivals {
    final filtered = _rivals.where((r) {
      if (_styleFilter != null && r.tacticalStyle != _styleFilter) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortMode) {
        case RivalSortMode.intensity:
          return b.rivalryIntensity.compareTo(a.rivalryIntensity);
        case RivalSortMode.totalDuels:
          return b.totalDuels.compareTo(a.totalDuels);
        case RivalSortMode.balance:
          return b.netBalance.compareTo(a.netBalance);
      }
    });
    return filtered;
  }

  RivalDirectorProfile? get _activeRival {
    final visible = _filteredRivals;
    if (visible.isEmpty) return null;
    final match = visible.where((r) => r.id == _selectedRivalId);
    if (match.isNotEmpty) return match.first;
    return visible.first;
  }

  void _selectRival(RivalDirectorProfile rival) {
    setState(() {
      _selectedRivalId = rival.id;
      _lastFeedbackBanner = null;
    });
    widget.onSelectRival?.call(rival);
  }

  void _applyPresetQuote(
    RivalDirectorProfile rival,
    PressStatementSentiment sentiment,
  ) {
    final preset = _buildPresetQuote(rival, sentiment);
    setState(() {
      _selectedResponseSentiment = sentiment;
      _quoteController.text = preset;
    });
  }

  String _buildPresetQuote(
    RivalDirectorProfile rival,
    PressStatementSentiment sentiment,
  ) {
    switch (sentiment) {
      case PressStatementSentiment.respectful:
        return 'Ekipa ${rival.teamName} jedzie znakomity wyścig, ale nasi kolarze są gotowi na sportową walkę do ostatniego metra.';
      case PressStatementSentiment.mindGames:
        return 'Widzimy, ile energii ${rival.managerName} wkłada w kontrolowanie wyścigu zbyt wcześnie — pytanie, czy starczy jej na finał.';
      case PressStatementSentiment.provocative:
        return 'Styl ${rival.tacticalStyle.label.toLowerCase()} ekipy ${rival.teamShortCode} bywa widowiskowy, dopóki nie zderzy się z naszym pociągiem.';
      case PressStatementSentiment.hostile:
        return 'Nie zamierzamy przyglądać się tym zagrywkom na konferencjach. Na trasie odpowiemy atakiem od pierwszego podjazdu.';
    }
  }

  void _submitPressResponse(RivalDirectorProfile rival) {
    final rawText = _quoteController.text.trim();
    final quote = rawText.isEmpty
        ? _buildPresetQuote(rival, _selectedResponseSentiment)
        : rawText;

    final int moraleDelta;
    final int intensityDelta;
    final int heat;
    switch (_selectedResponseSentiment) {
      case PressStatementSentiment.respectful:
        moraleDelta = 2;
        intensityDelta = -2;
        heat = 45;
      case PressStatementSentiment.mindGames:
        moraleDelta = 3;
        intensityDelta = 4;
        heat = 76;
      case PressStatementSentiment.provocative:
        moraleDelta = 2;
        intensityDelta = 6;
        heat = 86;
      case PressStatementSentiment.hostile:
        moraleDelta = 1;
        intensityDelta = 9;
        heat = 95;
    }

    final newExchange = PressConferenceExchange(
      id: 'press_${DateTime.now().microsecondsSinceEpoch}',
      dateLabel: 'Dziś',
      eventContext: 'Konferencja prasowa — odpowiedź dla ${rival.teamShortCode}',
      speakerName: widget.playerTeamName,
      isPlayerStatement: true,
      quote: quote,
      sentiment: _selectedResponseSentiment,
      moraleImpact: moraleDelta,
      mediaHeat: heat,
    );

    final updatedRival = rival.copyWith(
      rivalryIntensity: (rival.rivalryIntensity + intensityDelta).clamp(0, 100),
      pressHistory: [newExchange, ...rival.pressHistory],
    );

    setState(() {
      final idx = _rivals.indexWhere((r) => r.id == rival.id);
      if (idx != -1) {
        _rivals[idx] = updatedRival;
      }
      _quoteController.clear();
      _lastFeedbackBanner =
          'Wypowiedź opublikowana (${_selectedResponseSentiment.label}) • Morale +$moraleDelta';
    });

    widget.onSendPressResponse?.call(updatedRival, newExchange);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final bool isCompact = width < 720;
          final bool isWideDesktop = width >= 1200;
          final visibleRivals = _filteredRivals;
          final activeRival = _activeRival;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopSummaryHeader(isCompact),
              const SizedBox(height: 12),
              _buildFilterAndSortBar(isCompact),
              const SizedBox(height: 12),
              Expanded(
                child: visibleRivals.isEmpty || activeRival == null
                    ? _buildEmptyState()
                    : isCompact
                        ? _buildMobileLayout(visibleRivals, activeRival)
                        : _buildDesktopTabletLayout(
                            visibleRivals,
                            activeRival,
                            isWideDesktop: isWideDesktop,
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopSummaryHeader(bool isCompact) {
    final totalPlayerWins =
        _rivals.fold<int>(0, (sum, r) => sum + r.playerWins);
    final totalRivalWins =
        _rivals.fold<int>(0, (sum, r) => sum + r.rivalWins);
    final decided = totalPlayerWins + totalRivalWins;
    final winRatePct =
        decided == 0 ? 0 : ((totalPlayerWins / decided) * 100).round();
    final fierceCount =
        _rivals.where((r) => r.rivalryIntensity >= 80).length;

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.6),
                  ),
                ),
                child: const Icon(
                  Icons.sports_score_rounded,
                  color: AppColors.goldAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rywalizacja Dyrektorów Sportowych WorldTour',
                      style: _baseInter.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: isCompact ? 15 : 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.playerManagerName} • ${widget.playerTeamName}',
                      style: _baseInter.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _HeaderMetricPill(
                label: 'Bilans H2H',
                value: '$totalPlayerWins - $totalRivalWins',
                accent: AppColors.goldAccent,
              ),
              _HeaderMetricPill(
                label: 'Skuteczność',
                value: '$winRatePct%',
                accent: winRatePct >= 50
                    ? AppColors.statusSuccess
                    : AppColors.amberWarning,
              ),
              _HeaderMetricPill(
                label: 'Gorące spory',
                value: '$fierceCount',
                accent: AppColors.crimsonAlert,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSortBar(bool isCompact) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InteractiveFilterChip(
                label: 'Wszystkie style (${_rivals.length})',
                icon: Icons.groups_rounded,
                selected: _styleFilter == null,
                accentColor: AppColors.goldAccent,
                onTap: () => setState(() {
                  _styleFilter = null;
                  _selectedRivalId = _resolveInitialSelection();
                }),
              ),
              for (final style in RivalTacticalStyle.values)
                _InteractiveFilterChip(
                  label: isCompact ? style.shortLabel : style.label,
                  icon: style.icon,
                  selected: _styleFilter == style,
                  accentColor: style.accentColor,
                  onTap: () => setState(() {
                    _styleFilter = _styleFilter == style ? null : style;
                    _selectedRivalId = _resolveInitialSelection();
                  }),
                ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Sortuj:',
                style: _baseInter.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              for (final mode in RivalSortMode.values)
                _InteractiveFilterChip(
                  label: mode.label,
                  selected: _sortMode == mode,
                  accentColor: AppColors.primaryAccent,
                  onTap: () => setState(() => _sortMode = mode),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: AppColors.textSecondary,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Brak dyrektorów spełniających kryteria',
              textAlign: TextAlign.center,
              style: _baseInter.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Zmień aktywny filtr stylu taktycznego, aby wyświetlić rywali WorldTour.',
              textAlign: TextAlign.center,
              style: _baseInter.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            _InteractiveActionButton(
              label: 'Resetuj filtry',
              icon: Icons.refresh_rounded,
              enabled: _styleFilter != null,
              accentColor: AppColors.goldAccent,
              onPressed: () => setState(() {
                _styleFilter = null;
                _selectedRivalId = _resolveInitialSelection();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    List<RivalDirectorProfile> visibleRivals,
    RivalDirectorProfile activeRival,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visibleRivals.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final rival = visibleRivals[index];
                return SizedBox(
                  width: 240,
                  child: _RivalListTileCard(
                    rival: rival,
                    selected: rival.id == activeRival.id,
                    compact: true,
                    onTap: () => _selectRival(rival),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildRivalDetailContent(activeRival, isWideDesktop: false),
        ],
      ),
    );
  }

  Widget _buildDesktopTabletLayout(
    List<RivalDirectorProfile> visibleRivals,
    RivalDirectorProfile activeRival, {
    required bool isWideDesktop,
  }) {
    final double listWidth = isWideDesktop ? 320 : 272;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: listWidth,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: ListView.separated(
              itemCount: visibleRivals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final rival = visibleRivals[index];
                return _RivalListTileCard(
                  rival: rival,
                  selected: rival.id == activeRival.id,
                  compact: false,
                  onTap: () => _selectRival(rival),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: SingleChildScrollView(
            child: _buildRivalDetailContent(
              activeRival,
              isWideDesktop: isWideDesktop,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRivalDetailContent(
    RivalDirectorProfile rival, {
    required bool isWideDesktop,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: Column(
        key: ValueKey<String>(rival.id),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRivalProfileHeaderCard(rival),
          const SizedBox(height: 12),
          if (isWideDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _buildHeadToHeadBalanceCard(rival),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: _buildTacticalStyleCard(rival),
                ),
              ],
            )
          else ...[
            _buildHeadToHeadBalanceCard(rival),
            const SizedBox(height: 12),
            _buildTacticalStyleCard(rival),
          ],
          const SizedBox(height: 12),
          _buildPressConferenceHistoryCard(rival),
        ],
      ),
    );
  }

  Widget _buildRivalProfileHeaderCard(RivalDirectorProfile rival) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: rival.teamPrimaryColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: rival.teamPrimaryColor,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  rival.initials,
                  style: _baseInter.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          rival.managerName,
                          style: _baseInter.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        _CodePill(
                          label: rival.nationalityCode,
                          color: AppColors.surfaceLight,
                        ),
                        _CodePill(
                          label: rival.teamShortCode,
                          color: rival.teamPrimaryColor.withValues(alpha: 0.25),
                          borderColor: rival.teamPrimaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rival.teamName} • ${rival.rivalryTierLabel}',
                      style: _baseInter.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Napięcie rywalizacji',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _baseInter.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${rival.rivalryIntensity}%',
                      style: _baseInter.copyWith(
                        color: rival.rivalryIntensity >= 80
                            ? AppColors.crimsonAlert
                            : AppColors.goldAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: (rival.rivalryIntensity / 100).clamp(0.0, 1.0),
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          rival.rivalryIntensity >= 80
                              ? AppColors.crimsonAlert
                              : AppColors.goldAccent,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadToHeadBalanceCard(RivalDirectorProfile rival) {
    final totalDecided = rival.playerWins + rival.rivalWins;
    final double playerRatio =
        totalDecided == 0 ? 0.5 : rival.playerWins / totalDecided;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.compare_arrows_rounded,
                color: AppColors.goldAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bilans Bezpośrednich Pojedynków',
                  style: _baseInter.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${rival.totalDuels} starć',
                style: _baseInter.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.playerTeamName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _baseInter.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${rival.playerWins}',
                            style: _baseInter.copyWith(
                              color: AppColors.goldAccent,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        rival.draws > 0 ? 'REMISY: ${rival.draws}' : 'VS',
                        style: _baseInter.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            rival.teamShortCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _baseInter.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${rival.rivalWins}',
                            style: _baseInter.copyWith(
                              color: rival.teamPrimaryColor,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (playerRatio * 100).round().clamp(5, 95),
                          child: Container(color: AppColors.goldAccent),
                        ),
                        Expanded(
                          flex: ((1 - playerRatio) * 100).round().clamp(5, 95),
                          child: Container(color: rival.teamPrimaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    _MiniDuelStat(
                      label: 'Klasyfikacje GC',
                      value:
                          '${rival.gcBattlesWonByPlayer} : ${rival.gcBattlesWonByRival}',
                    ),
                    _MiniDuelStat(
                      label: 'Etapy i Klasyki',
                      value:
                          '${rival.stageWinsPlayer} : ${rival.stageWinsRival}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ostatnie bezpośrednie starcia',
            style: _baseInter.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (rival.recentEncounters.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Brak zarejestrowanych bezpośrednich pojedynków w tym sezonie.',
                style: _baseInter.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            )
          else
            for (final duel in rival.recentEncounters) ...[
              _EncounterRow(duel: duel),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildTacticalStyleCard(RivalDirectorProfile rival) {
    final style = rival.tacticalStyle;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(style.icon, color: style.accentColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Profil i Styl Taktyczny',
                  style: _baseInter.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: style.accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: style.accentColor.withValues(alpha: 0.7),
                  ),
                ),
                child: Text(
                  style.label,
                  style: _baseInter.copyWith(
                    color: style.accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            style.summary,
            style: _baseInter.copyWith(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ZAGRANIE FIRMOWE',
                  style: _baseInter.copyWith(
                    color: AppColors.goldAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rival.signatureTactic,
                  style: _baseInter.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _AttributeProgressBar(
            label: 'Agresja w górach i na wietrze',
            value: rival.aggressionRating,
            color: AppColors.crimsonAlert,
          ),
          const SizedBox(height: 10),
          _AttributeProgressBar(
            label: 'Adaptacja taktyczna w trakcie etapu',
            value: rival.tacticalAdaptability,
            color: AppColors.accentBlue,
          ),
          const SizedBox(height: 10),
          _AttributeProgressBar(
            label: 'Odporność na presję mediów',
            value: rival.mediaPressureResistance,
            color: AppColors.statusSuccess,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryAccent.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.goldAccent,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kontrtaktyka: ${style.counterAdvice}',
                    style: _baseInter.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPressConferenceHistoryCard(RivalDirectorProfile rival) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.mic_external_on_rounded,
                color: AppColors.goldAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Historia Wypowiedzi na Konferencjach Prasowych',
                  style: _baseInter.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${rival.pressHistory.length} wypowiedzi',
                style: _baseInter.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Wyślij ripostę na konferencji prasowej',
                  style: _baseInter.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final sentiment in PressStatementSentiment.values)
                      _InteractiveFilterChip(
                        label: sentiment.label,
                        icon: sentiment.icon,
                        selected: _selectedResponseSentiment == sentiment,
                        accentColor: sentiment.color,
                        onTap: () => _applyPresetQuote(rival, sentiment),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _quoteController,
                  maxLines: 2,
                  style: _baseInter.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Wpisz własny komentarz lub wybierz ton powyżej, aby wygenerować cytat...',
                    hintStyle: _baseInter.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.goldAccent,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (_lastFeedbackBanner != null)
                      Text(
                        _lastFeedbackBanner!,
                        style: _baseInter.copyWith(
                          color: AppColors.statusSuccess,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Text(
                        'Wpływa na morale drużyny i temperaturę rywalizacji.',
                        style: _baseInter.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    _InteractiveActionButton(
                      label: 'Opublikuj wypowiedź',
                      icon: Icons.send_rounded,
                      enabled: true,
                      accentColor: AppColors.primaryAccent,
                      onPressed: () => _submitPressResponse(rival),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (rival.pressHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Brak dotychczasowych wypowiedzi w mediach z tym dyrektorem.',
                textAlign: TextAlign.center,
                style: _baseInter.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            )
          else
            for (final exchange in rival.pressHistory) ...[
              _PressQuoteBubble(
                exchange: exchange,
                rivalColor: rival.teamPrimaryColor,
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _HeaderMetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _HeaderMetricPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: accent,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveFilterChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractiveFilterChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveFilterChip> createState() => _InteractiveFilterChipState();
}

class _InteractiveFilterChipState extends State<_InteractiveFilterChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.selected
        ? widget.accentColor.withValues(alpha: 0.2)
        : _hovered
            ? AppColors.surfaceLight
            : AppColors.background;
    final Color border = _focused
        ? AppColors.goldAccent
        : widget.selected
            ? widget.accentColor
            : _hovered
                ? AppColors.textSecondary.withValues(alpha: 0.5)
                : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border, width: _focused ? 1.5 : 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 14,
                      color: widget.selected
                          ? widget.accentColor
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      letterSpacing: -0.2,
                      color: widget.selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          widget.selected ? FontWeight.w700 : FontWeight.w500,
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

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _hovered
            ? widget.accentColor
            : widget.accentColor.withValues(alpha: 0.85);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _focused ? AppColors.goldAccent : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 15,
                    color: widget.enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      letterSpacing: -0.2,
                      color: widget.enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

class _RivalListTileCard extends StatefulWidget {
  final RivalDirectorProfile rival;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _RivalListTileCard({
    required this.rival,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_RivalListTileCard> createState() => _RivalListTileCardState();
}

class _RivalListTileCardState extends State<_RivalListTileCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final rival = widget.rival;
    final style = rival.tacticalStyle;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.all(widget.compact ? 10 : 12),
              decoration: BoxDecoration(
                color: widget.selected
                    ? AppColors.surfaceLight
                    : _hovered
                        ? AppColors.surfaceLight.withValues(alpha: 0.55)
                        : AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _focused
                      ? AppColors.goldAccent
                      : widget.selected
                          ? AppColors.goldAccent
                          : AppColors.cardBorder,
                  width: widget.selected || _focused ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 28,
                        decoration: BoxDecoration(
                          color: rival.teamPrimaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rival.managerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                letterSpacing: -0.2,
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              rival.teamName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                letterSpacing: -0.2,
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${rival.playerWins}-${rival.rivalWins}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          letterSpacing: -0.2,
                          color: AppColors.goldAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(style.icon, size: 12, color: style.accentColor),
                          const SizedBox(width: 4),
                          Text(
                            style.label,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              letterSpacing: -0.2,
                              color: style.accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${rival.rivalryIntensity}%',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          letterSpacing: -0.2,
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
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

class _CodePill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? borderColor;

  const _CodePill({
    required this.label,
    required this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor ?? AppColors.cardBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniDuelStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniDuelStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Inter',
            letterSpacing: -0.2,
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _EncounterRow extends StatelessWidget {
  final HeadToHeadDuelResult duel;

  const _EncounterRow({required this.duel});

  @override
  Widget build(BuildContext context) {
    final Color outcomeColor =
        duel.playerWon ? AppColors.statusSuccess : AppColors.crimsonAlert;
    final String deltaText = duel.timeDeltaSeconds <= 0
        ? '${duel.timeDeltaSeconds}s'
        : '+${duel.timeDeltaSeconds}s';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: outcomeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  duel.raceName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'P${duel.playerBestPosition} vs P${duel.rivalBestPosition} ($deltaText)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  color: outcomeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${duel.raceCategory} • ${duel.dateLabel} — ${duel.keyTacticalNote}',
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttributeProgressBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _AttributeProgressBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$clamped/100',
              style: TextStyle(
                fontFamily: 'Inter',
                letterSpacing: -0.2,
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: clamped / 100),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (context, progress, _) {
              return LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PressQuoteBubble extends StatelessWidget {
  final PressConferenceExchange exchange;
  final Color rivalColor;

  const _PressQuoteBubble({
    required this.exchange,
    required this.rivalColor,
  });

  @override
  Widget build(BuildContext context) {
    final sentiment = exchange.sentiment;
    final Color accent =
        exchange.isPlayerStatement ? AppColors.goldAccent : rivalColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: exchange.isPlayerStatement
            ? AppColors.primaryAccent.withValues(alpha: 0.14)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: exchange.isPlayerStatement
              ? AppColors.primaryAccent.withValues(alpha: 0.55)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    exchange.speakerName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    exchange.dateLabel,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      letterSpacing: -0.2,
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: sentiment.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sentiment.color.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(sentiment.icon, size: 12, color: sentiment.color),
                    const SizedBox(width: 4),
                    Text(
                      sentiment.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.2,
                        color: sentiment.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '„${exchange.quote}”',
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                exchange.eventContext,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                'Media Heat: ${exchange.mediaHeat}%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              if (exchange.moraleImpact != 0)
                Text(
                  'Morale: ${exchange.moraleImpact > 0 ? '+${exchange.moraleImpact}' : exchange.moraleImpact}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: exchange.moraleImpact > 0
                        ? AppColors.statusSuccess
                        : AppColors.crimsonAlert,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
