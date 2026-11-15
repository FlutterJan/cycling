import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Rola komentatora w studiu transmisji telewizyjnej na żywo.
enum TvCommentatorRole {
  /// Główny komentator prowadzący relację play-by-play.
  leadPlayByPlay,

  /// Ekspert telewizyjny — były zawodowy kolarz analizujący taktykę i fizjologię.
  formerProExpert;

  String get shortLabel {
    switch (this) {
      case TvCommentatorRole.leadPlayByPlay:
        return 'KOMENTATOR';
      case TvCommentatorRole.formerProExpert:
        return 'EKSPERT • EX-PRO';
    }
  }
}

/// Kategoria zdarzenia wyścigowego wyzwalająca dynamiczny komentarz telewizyjny.
enum TvCommentaryTriggerType {
  /// Atak powyżej 10 W/kg ("bomba watowa").
  wattBombAttack,

  /// Pęknięcie peletonu na bocznym wietrze (formowanie rantów / wachlarzy).
  crosswindEchelonSplit,

  /// Kraksa lub poważny defekt w peletonie.
  crashOrMechanical,

  /// Przejazd przez strefę bufetu (bidony, żele, musette).
  feedZoneAndHydration,

  /// Zmiana lub napięta sytuacja w klasyfikacji generalnej na żywo (Virtual GC).
  virtualGcShift,

  /// Ogólna relacja sytuacyjna na trasie etapu.
  generalBroadcast;

  String get badgeLabel {
    switch (this) {
      case TvCommentaryTriggerType.wattBombAttack:
        return 'ATAK >10 W/KG';
      case TvCommentaryTriggerType.crosswindEchelonSplit:
        return 'RANTY / WIATR';
      case TvCommentaryTriggerType.crashOrMechanical:
        return 'KRAKSA';
      case TvCommentaryTriggerType.feedZoneAndHydration:
        return 'BUFET';
      case TvCommentaryTriggerType.virtualGcShift:
        return 'VIRTUAL GC';
      case TvCommentaryTriggerType.generalBroadcast:
        return 'RELACJA LIVE';
    }
  }

  Color get accentColor {
    switch (this) {
      case TvCommentaryTriggerType.wattBombAttack:
        return AppColors.powerZone6;
      case TvCommentaryTriggerType.crosswindEchelonSplit:
        return AppColors.cyanAccent;
      case TvCommentaryTriggerType.crashOrMechanical:
        return AppColors.crimsonAlert;
      case TvCommentaryTriggerType.feedZoneAndHydration:
        return AppColors.statusSuccess;
      case TvCommentaryTriggerType.virtualGcShift:
        return AppColors.goldAccent;
      case TvCommentaryTriggerType.generalBroadcast:
        return AppColors.accentBlue;
    }
  }

  IconData get icon {
    switch (this) {
      case TvCommentaryTriggerType.wattBombAttack:
        return Icons.bolt_rounded;
      case TvCommentaryTriggerType.crosswindEchelonSplit:
        return Icons.air_rounded;
      case TvCommentaryTriggerType.crashOrMechanical:
        return Icons.warning_amber_rounded;
      case TvCommentaryTriggerType.feedZoneAndHydration:
        return Icons.local_drink_rounded;
      case TvCommentaryTriggerType.virtualGcShift:
        return Icons.emoji_events_rounded;
      case TvCommentaryTriggerType.generalBroadcast:
        return Icons.live_tv_rounded;
    }
  }
}

/// Wejściowe zdarzenie lub zrzut telemetrii wyścigu dla generatora komentarza TV.
class TvCommentaryInputEvent {
  final TvCommentaryTriggerType triggerType;
  final double kilometerMark;
  final String? riderName;
  final String? teamName;
  final double? wattsPerKg;
  final int? absoluteWatts;
  final double? windSpeedKmh;
  final int? echelonGroupsCount;
  final String? virtualGcLeaderName;
  final int? virtualGcGapSeconds;
  final int? crashRiderCount;
  final bool isFeedZoneActive;
  final double? stageProgressPercent;

  const TvCommentaryInputEvent({
    required this.triggerType,
    required this.kilometerMark,
    this.riderName,
    this.teamName,
    this.wattsPerKg,
    this.absoluteWatts,
    this.windSpeedKmh,
    this.echelonGroupsCount,
    this.virtualGcLeaderName,
    this.virtualGcGapSeconds,
    this.crashRiderCount,
    this.isFeedZoneActive = false,
    this.stageProgressPercent,
  });

  /// Tworzy zdarzenie automatycznie na podstawie bieżącej telemetrii wyścigu.
  factory TvCommentaryInputEvent.fromLiveTelemetry({
    required double kilometerMark,
    String? riderName,
    String? teamName,
    double? wattsPerKg,
    int? absoluteWatts,
    double? windSpeedKmh,
    int? echelonGroupsCount,
    String? virtualGcLeaderName,
    int? virtualGcGapSeconds,
    int? crashRiderCount,
    bool isFeedZoneActive = false,
    double? stageProgressPercent,
  }) {
    final TvCommentaryTriggerType detectedType;
    if ((crashRiderCount ?? 0) > 0) {
      detectedType = TvCommentaryTriggerType.crashOrMechanical;
    } else if ((wattsPerKg ?? 0.0) > 10.0) {
      detectedType = TvCommentaryTriggerType.wattBombAttack;
    } else if ((windSpeedKmh ?? 0.0) >= 24.0 &&
        (echelonGroupsCount ?? 1) > 1) {
      detectedType = TvCommentaryTriggerType.crosswindEchelonSplit;
    } else if (isFeedZoneActive) {
      detectedType = TvCommentaryTriggerType.feedZoneAndHydration;
    } else if (virtualGcLeaderName != null && virtualGcGapSeconds != null) {
      detectedType = TvCommentaryTriggerType.virtualGcShift;
    } else {
      detectedType = TvCommentaryTriggerType.generalBroadcast;
    }

    return TvCommentaryInputEvent(
      triggerType: detectedType,
      kilometerMark: kilometerMark,
      riderName: riderName,
      teamName: teamName,
      wattsPerKg: wattsPerKg,
      absoluteWatts: absoluteWatts,
      windSpeedKmh: windSpeedKmh,
      echelonGroupsCount: echelonGroupsCount,
      virtualGcLeaderName: virtualGcLeaderName,
      virtualGcGapSeconds: virtualGcGapSeconds,
      crashRiderCount: crashRiderCount,
      isFeedZoneActive: isFeedZoneActive,
      stageProgressPercent: stageProgressPercent,
    );
  }
}

/// Pojedyncza kwestia wypowiedziana na antenie przez komentatora lub eksperta.
class TvCommentaryLine {
  final String id;
  final TvCommentatorRole role;
  final String speakerName;
  final String speakerTitle;
  final TvCommentaryTriggerType triggerType;
  final double kilometerMark;
  final String message;
  final String? telemetryTag;
  final DateTime timestamp;
  final bool isBreaking;

  const TvCommentaryLine({
    required this.id,
    required this.role,
    required this.speakerName,
    required this.speakerTitle,
    required this.triggerType,
    required this.kilometerMark,
    required this.message,
    this.telemetryTag,
    required this.timestamp,
    this.isBreaking = false,
  });
}

/// Generator dynamicznych dialogów dwóch komentatorów telewizyjnych (główny + ekspert były kolarz).
class LiveTvCommentaryGenerator {
  final String leadCommentatorName;
  final String expertCommentatorName;
  final math.Random _random;
  int _sequenceCounter = 0;

  LiveTvCommentaryGenerator({
    this.leadCommentatorName = 'Adam Kowalczyk',
    this.expertCommentatorName = 'Piotr Zieliński',
    math.Random? random,
  }) : _random = random ?? math.Random();

  /// Generuje parę wypowiedzi (reakcja komentatora głównego + analiza eksperta byłego kolarza)
  /// na podstawie zdarzenia wyścigowego.
  List<TvCommentaryLine> generateDialogue(TvCommentaryInputEvent event) {
    final km = event.kilometerMark.clamp(0.0, 999.9);
    final rider = (event.riderName != null && event.riderName!.trim().isNotEmpty)
        ? event.riderName!.trim()
        : 'Lider grupy';
    final team = (event.teamName != null && event.teamName!.trim().isNotEmpty)
        ? event.teamName!.trim()
        : 'ekipy pościgowej';
    final now = DateTime.now();

    switch (event.triggerType) {
      case TvCommentaryTriggerType.wattBombAttack:
        return _buildWattBombDialogue(event, km, rider, team, now);
      case TvCommentaryTriggerType.crosswindEchelonSplit:
        return _buildCrosswindDialogue(event, km, rider, now);
      case TvCommentaryTriggerType.crashOrMechanical:
        return _buildCrashDialogue(event, km, rider, team, now);
      case TvCommentaryTriggerType.feedZoneAndHydration:
        return _buildFeedZoneDialogue(event, km, rider, now);
      case TvCommentaryTriggerType.virtualGcShift:
        return _buildVirtualGcDialogue(event, km, rider, now);
      case TvCommentaryTriggerType.generalBroadcast:
        return _buildGeneralDialogue(event, km, rider, now);
    }
  }

  List<TvCommentaryLine> _buildWattBombDialogue(
    TvCommentaryInputEvent event,
    double km,
    String rider,
    String team,
    DateTime now,
  ) {
    final wkg = (event.wattsPerKg ?? 10.6).clamp(10.01, 24.0);
    final watts = event.absoluteWatts ?? (wkg * 66).round();
    final wkgText = wkg.toStringAsFixed(1);
    final tag = '$wkgText W/kg • $watts W';

    final leadVariants = <String>[
      'POTĘŻNY ATAK! $rider ($team) naciska na pedały z mocą $wkgText W/kg ($watts W) i natychmiast odrywa się od rywali na ${km.toStringAsFixed(1)} km!',
      'Co za przyspieszenie! $rider odpala bombę watową — $watts watów, aż $wkgText W/kg! Peleton w jednej chwili pęka na kawałki!',
      'Niesamowita eksplozja mocy! $rider wstaje z siodełka i generuje $wkgText W/kg. Nikt nie jest w stanie utrzymać tego koła!',
    ];

    final expertVariants = <String>[
      'Znam ten ból z peletonu — przy $wkgText W/kg nogi zalewa kwas mlekowy po 15 sekundach. Jeśli rywale nie odpowiedzą płynnie, luka urośnie błyskawicznie.',
      'Kluczowe jest teraz to, ile zapałek z W\' spalił $rider przed tym skokiem. Taka kadencja na stojąco przy $watts W to czysty test charakteru.',
      'Patrzcie na jego pozycję aerodynamiczną tuż po odejściu — od razu schował łokcie, żeby nie marnować ani jednego z tych $watts watów pod wiatr.',
    ];

    return [
      _makeLine(
        role: TvCommentatorRole.leadPlayByPlay,
        triggerType: TvCommentaryTriggerType.wattBombAttack,
        km: km,
        message: leadVariants[_random.nextInt(leadVariants.length)],
        telemetryTag: tag,
        now: now,
        isBreaking: true,
      ),
      _makeLine(
        role: TvCommentatorRole.formerProExpert,
        triggerType: TvCommentaryTriggerType.wattBombAttack,
        km: km,
        message: expertVariants[_random.nextInt(expertVariants.length)],
        telemetryTag: 'ANALIZA W\'BAL',
        now: now.add(const Duration(milliseconds: 1)),
        isBreaking: false,
      ),
    ];
  }

  List<TvCommentaryLine> _buildCrosswindDialogue(
    TvCommentaryInputEvent event,
    double km,
    String rider,
    DateTime now,
  ) {
    final wind = (event.windSpeedKmh ?? 34.0).clamp(0.0, 120.0);
    final groups = (event.echelonGroupsCount ?? 3).clamp(2, 12);
    final tag = 'Wiatr ${wind.toStringAsFixed(0)} km/h • $groups grupy';

    final leadVariants = <String>[
      'PELETON PĘKA NA WIETRZE! Boczny podmuch ${wind.toStringAsFixed(0)} km/h rwie grupę na $groups wachlarze na odkrytym odcinku!',
      'Chaos na rantach! Na ${km.toStringAsFixed(1)} km szerokość szosy nie wystarcza — część faworytów zostaje w drugim wachlarzu!',
      'Boczny wiatr ${wind.toStringAsFixed(0)} km/h robi spustoszenie! Pierwszy rant idzie pełnym gazem, a z tyłu trwa dramatyczna pogoń!',
    ];

    final expertVariants = <String>[
      'Na takich rantach nie ma miejsca na zawahanie. Gdy pierwszy wachlarz zajmie całą krawędź asfaltu, kolarze z tyłu jadą w 100% na wietrze i tracą po 50 watów więcej.',
      'Kto przespał ustawienie 2 kilometry wcześniej, ten teraz płaci najwyższą cenę. Tu pomocnicy muszą poświęcić cały swój zapas sił, by dociągnąć $rider do przodu.',
      'Pamiętam takie etapy — przy ${wind.toStringAsFixed(0)} km/h z boku czujesz, jak przednie koło ucieka spod ręki, a każda zmiana na czele trwa najwyżej 6–8 sekund.',
    ];

    return [
      _makeLine(
        role: TvCommentatorRole.leadPlayByPlay,
        triggerType: TvCommentaryTriggerType.crosswindEchelonSplit,
        km: km,
        message: leadVariants[_random.nextInt(leadVariants.length)],
        telemetryTag: tag,
        now: now,
        isBreaking: true,
      ),
      _makeLine(
        role: TvCommentatorRole.formerProExpert,
        triggerType: TvCommentaryTriggerType.crosswindEchelonSplit,
        km: km,
        message: expertVariants[_random.nextInt(expertVariants.length)],
        telemetryTag: 'TAKTYKA RANTÓW',
        now: now.add(const Duration(milliseconds: 1)),
        isBreaking: false,
      ),
    ];
  }

  List<TvCommentaryLine> _buildCrashDialogue(
    TvCommentaryInputEvent event,
    double km,
    String rider,
    String team,
    DateTime now,
  ) {
    final count = (event.crashRiderCount ?? 2).clamp(1, 50);
    final tag = '$count ${count == 1 ? 'kolarz' : 'kolarzy'} na asfalcie';

    final leadVariants = <String>[
      'UWAGA, KRAKSA W PELETONIE! Na ${km.toStringAsFixed(1)} km leży $count zawodników, w tym $rider ($team)! Wozy techniczne już ruszają z pomocą!',
      'Groźny upadek w środku stawki! Kolarze zahaczyli o siebie przy dużej prędkości — $rider potrzebuje błyskawicznej wymiany roweru!',
      'Dramatyczny moment transmisji! Kraksa blokuje połowę szosy na ${km.toStringAsFixed(1)} km, a część peletonu musi wyhamować niemal do zera!',
    ];

    final expertVariants = <String>[
      'Najważniejsze teraz to zachować chłodną głowę i nie panikować przy pogoni. Mechanik musi w 5 sekund sprawdzić hak przerzutki albo podać zapasowy rower z dachu.',
      'Po takim szlifie adrenalina maskuje ból przez pierwsze minuty, ale powrót do peletonu za kolumną wozów będzie kosztował ogromnie dużo energii.',
      'Zwróćcie uwagę na tempo z przodu — zgodnie z niepisanym kodeksem peleton czasem zwalnia, ale jeśli trwa walka o pozycję, nikt nie będzie czekał.',
    ];

    return [
      _makeLine(
        role: TvCommentatorRole.leadPlayByPlay,
        triggerType: TvCommentaryTriggerType.crashOrMechanical,
        km: km,
        message: leadVariants[_random.nextInt(leadVariants.length)],
        telemetryTag: tag,
        now: now,
        isBreaking: true,
      ),
      _makeLine(
        role: TvCommentatorRole.formerProExpert,
        triggerType: TvCommentaryTriggerType.crashOrMechanical,
        km: km,
        message: expertVariants[_random.nextInt(expertVariants.length)],
        telemetryTag: 'SERWIS & POWRÓT',
        now: now.add(const Duration(milliseconds: 1)),
        isBreaking: false,
      ),
    ];
  }

  List<TvCommentaryLine> _buildFeedZoneDialogue(
    TvCommentaryInputEvent event,
    double km,
    String rider,
    DateTime now,
  ) {
    final tag = 'BUFET • KM ${km.toStringAsFixed(1)}';

    final leadVariants = <String>[
      'Jesteśmy w strefie bufetu na ${km.toStringAsFixed(1)} km! Obsługa drużyn wyciąga ręce z torbami musette — kolarze łapią bidony i żele w pełnym biegu!',
      'Kluczowy moment logistyczny etapu: strefa żywienia! Pomocnicy zjeżdżają na prawą krawędź szosy, a $rider odbiera świeży zapas węglowodanów.',
    ];

    final expertVariants = <String>[
      'Dzisiejsze kolarstwo to wyścig na 90–120 gramów węglowodanów na godzinę. Kto przegapi musette w bufecie, ten za godzinę może zderzyć się ze ścianą glikogenową.',
      'Zawsze powtarzam młodym zawodnikom: w bufecie jedziesz czujnie, z jedną ręką na kierownicy. Tu o kraksę przez upuszczony bidon jest równie łatwo jak na finiszu.',
    ];

    return [
      _makeLine(
        role: TvCommentatorRole.leadPlayByPlay,
        triggerType: TvCommentaryTriggerType.feedZoneAndHydration,
        km: km,
        message: leadVariants[_random.nextInt(leadVariants.length)],
        telemetryTag: tag,
        now: now,
      ),
      _makeLine(
        role: TvCommentatorRole.formerProExpert,
        triggerType: TvCommentaryTriggerType.feedZoneAndHydration,
        km: km,
        message: expertVariants[_random.nextInt(expertVariants.length)],
        telemetryTag: 'ODŻYWIANIE 90G/H',
        now: now.add(const Duration(milliseconds: 1)),
      ),
    ];
  }

  List<TvCommentaryLine> _buildVirtualGcDialogue(
    TvCommentaryInputEvent event,
    double km,
    String rider,
    DateTime now,
  ) {
    final leader = (event.virtualGcLeaderName != null &&
            event.virtualGcLeaderName!.trim().isNotEmpty)
        ? event.virtualGcLeaderName!.trim()
        : rider;
    final gapSec = event.virtualGcGapSeconds ?? 18;
    final absGap = gapSec.abs();
    final mins = absGap ~/ 60;
    final secs = (absGap % 60).toString().padLeft(2, '0');
    final sign = gapSec >= 0 ? '+' : '-';
    final formattedGap = '$sign$mins:$secs';
    final tag = 'VIRTUAL GC $formattedGap';

    final leadVariants = <String>[
      'SPÓJRZMY NA VIRTUAL GC! $leader w tym momencie wirtualnie przejmuje prowadzenie w klasyfikacji generalnej z różnicą $formattedGap na ${km.toStringAsFixed(1)} km!',
      'Tabela na żywo płonie! Różnica czasowa w Virtual GC wynosi teraz $formattedGap — dyrektorzy sportowi w wozach już przeliczają każdą sekundę!',
    ];

    final expertVariants = <String>[
      'Kiedy na tablicy pojawia się wirtualna zmiana koszulki lidera, w peletonie natychmiast zmienia się psychologia jazdy. Ekipa dotychczasowego lidera musi odkryć karty.',
      'Te $absGap sekund w Virtual GC wygląda groźnie, ale pamiętajmy o końcówce etapu — w finałowych 10 kilometrach zmęczenie potrafi zjeść przewagę w mgnieniu oka.',
    ];

    return [
      _makeLine(
        role: TvCommentatorRole.leadPlayByPlay,
        triggerType: TvCommentaryTriggerType.virtualGcShift,
        km: km,
        message: leadVariants[_random.nextInt(leadVariants.length)],
        telemetryTag: tag,
        now: now,
        isBreaking: absGap >= 15,
      ),
      _makeLine(
        role: TvCommentatorRole.formerProExpert,
        triggerType: TvCommentaryTriggerType.virtualGcShift,
        km: km,
        message: expertVariants[_random.nextInt(expertVariants.length)],
        telemetryTag: 'KALKULACJA GC',
        now: now.add(const Duration(milliseconds: 1)),
      ),
    ];
  }

  List<TvCommentaryLine> _buildGeneralDialogue(
    TvCommentaryInputEvent event,
    double km,
    String rider,
    DateTime now,
  ) {
    final progress = event.stageProgressPercent?.clamp(0.0, 100.0);
    final tag = progress != null
        ? 'DYSTANS ${progress.toStringAsFixed(0)}%'
        : 'KM ${km.toStringAsFixed(1)}';

    final leadVariants = <String>[
      'Mijamy ${km.toStringAsFixed(1)} kilometr etapu. Peleton utrzymuje wysokie, równe tempo pod kontrolą najsilniejszych ekip w stawce.',
      'Kamera z helikoptera pokazuje długą wstęgę kolarzy na ${km.toStringAsFixed(1)} km — napięcie w grupie wyraźnie rośnie przed decydującą fazą.',
    ];

    final expertVariants = <String>[
      'W takich momentach wygrywa się wyścig oszczędzaniem sił. Kolarze schowani w środku szyku jadą o 30–35% lżej niż ci na pierwszej linii.',
      'Obserwujcie ustawienie liderów — każdy chce być blisko czoła przed zwężeniem drogi, żeby nie zużywać energii na bezsensowne hamowania i przyspieszenia.',
    ];

    return [
      _makeLine(
        role: TvCommentatorRole.leadPlayByPlay,
        triggerType: TvCommentaryTriggerType.generalBroadcast,
        km: km,
        message: leadVariants[_random.nextInt(leadVariants.length)],
        telemetryTag: tag,
        now: now,
      ),
      _makeLine(
        role: TvCommentatorRole.formerProExpert,
        triggerType: TvCommentaryTriggerType.generalBroadcast,
        km: km,
        message: expertVariants[_random.nextInt(expertVariants.length)],
        telemetryTag: 'KOMENTARZ TAKTYCZNY',
        now: now.add(const Duration(milliseconds: 1)),
      ),
    ];
  }

  TvCommentaryLine _makeLine({
    required TvCommentatorRole role,
    required TvCommentaryTriggerType triggerType,
    required double km,
    required String message,
    required String telemetryTag,
    required DateTime now,
    bool isBreaking = false,
  }) {
    _sequenceCounter++;
    return TvCommentaryLine(
      id: 'tv_${now.microsecondsSinceEpoch}_$_sequenceCounter',
      role: role,
      speakerName: role == TvCommentatorRole.leadPlayByPlay
          ? leadCommentatorName
          : expertCommentatorName,
      speakerTitle: role.shortLabel,
      triggerType: triggerType,
      kilometerMark: km,
      message: message,
      telemetryTag: telemetryTag,
      timestamp: now,
      isBreaking: isBreaking,
    );
  }
}

/// Pasek komentarza telewizyjnego na żywo (`LiveTvCommentaryTicker`) dla transmisji 3D wyścigu.
///
/// Generuje i prezentuje dynamiczne wypowiedzi dwóch komentatorów (głównego oraz
/// eksperta byłego kolarza) reagujące na ataki >10 W/kg, pęknięcia peletonu na wietrze,
/// kraksy, strefę bufetu oraz zmiany w Virtual GC.
class LiveTvCommentaryTicker extends StatefulWidget {
  /// Jawna lista nadchodzących zdarzeń wyścigowych do przekształcenia w komentarz TV.
  final List<TvCommentaryInputEvent> events;

  /// Opcjonalna lista gotowych wypowiedzi na start.
  final List<TvCommentaryLine> initialLines;

  /// Bieżący zrzut telemetrii wyścigu (automatycznie wykrywa ataki >10 W/kg, ranty, kraksy, bufet, Virtual GC).
  final TvCommentaryInputEvent? liveTelemetry;

  /// Imię i nazwisko głównego komentatora.
  final String leadCommentatorName;

  /// Imię i nazwisko eksperta (byłego kolarza).
  final String expertCommentatorName;

  /// Interwał automatycznego przełączania między wypowiedziami komentatorów.
  final Duration autoRotateInterval;

  /// Czy pasek komentarza jest aktywny (obsługa pełnego stanu `disabled`).
  final bool enabled;

  /// Callback wywoływany po kliknięciu lub wybraniu konkretnej wypowiedzi.
  final ValueChanged<TvCommentaryLine>? onLineSelected;

  /// Callback wywoływany przy wyciszeniu / włączeniu dźwięku komentarza TV.
  final ValueChanged<bool>? onMuteChanged;

  const LiveTvCommentaryTicker({
    super.key,
    this.events = const [],
    this.initialLines = const [],
    this.liveTelemetry,
    this.leadCommentatorName = 'Adam Kowalczyk',
    this.expertCommentatorName = 'Piotr Zieliński',
    this.autoRotateInterval = const Duration(seconds: 7),
    this.enabled = true,
    this.onLineSelected,
    this.onMuteChanged,
  });

  @override
  State<LiveTvCommentaryTicker> createState() => _LiveTvCommentaryTickerState();
}

class _LiveTvCommentaryTickerState extends State<LiveTvCommentaryTicker>
    with SingleTickerProviderStateMixin {
  static const int _maxHistoryLines = 40;

  late LiveTvCommentaryGenerator _generator;
  late final AnimationController _livePulseController;
  final List<TvCommentaryLine> _lines = [];
  Timer? _autoRotateTimer;

  int _currentIndex = 0;
  bool _isPaused = false;
  bool _isMuted = false;
  bool _isHistoryExpanded = false;
  String? _lastTelemetrySignature;

  @override
  void initState() {
    super.initState();
    _generator = LiveTvCommentaryGenerator(
      leadCommentatorName: widget.leadCommentatorName,
      expertCommentatorName: widget.expertCommentatorName,
    );
    _livePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _seedInitialLines();
    _ingestEvents(widget.events);
    if (widget.liveTelemetry != null) {
      _ingestLiveTelemetry(widget.liveTelemetry!);
    }
    _restartAutoRotateTimer();
  }

  @override
  void didUpdateWidget(covariant LiveTvCommentaryTicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.leadCommentatorName != widget.leadCommentatorName ||
        oldWidget.expertCommentatorName != widget.expertCommentatorName) {
      _generator = LiveTvCommentaryGenerator(
        leadCommentatorName: widget.leadCommentatorName,
        expertCommentatorName: widget.expertCommentatorName,
      );
    }

    if (widget.events.length > oldWidget.events.length) {
      final newEvents = widget.events.sublist(oldWidget.events.length);
      _ingestEvents(newEvents);
    } else if (widget.events != oldWidget.events && widget.events.isNotEmpty) {
      _ingestEvents(widget.events);
    }

    if (widget.liveTelemetry != null &&
        widget.liveTelemetry != oldWidget.liveTelemetry) {
      _ingestLiveTelemetry(widget.liveTelemetry!);
    }

    if (oldWidget.autoRotateInterval != widget.autoRotateInterval ||
        oldWidget.enabled != widget.enabled) {
      _restartAutoRotateTimer();
    }
  }

  @override
  void dispose() {
    _autoRotateTimer?.cancel();
    _livePulseController.dispose();
    super.dispose();
  }

  void _seedInitialLines() {
    if (widget.initialLines.isNotEmpty) {
      _lines.addAll(widget.initialLines);
      _currentIndex = 0;
      return;
    }
    if (widget.events.isEmpty && widget.liveTelemetry == null) {
      _lines.addAll(
        _generator.generateDialogue(
          const TvCommentaryInputEvent(
            triggerType: TvCommentaryTriggerType.generalBroadcast,
            kilometerMark: 0.0,
            stageProgressPercent: 0.0,
          ),
        ),
      );
      _currentIndex = 0;
    }
  }

  void _ingestEvents(List<TvCommentaryInputEvent> events) {
    if (events.isEmpty) return;
    final generated = <TvCommentaryLine>[];
    for (final event in events) {
      generated.addAll(_generator.generateDialogue(event));
    }
    if (generated.isEmpty) return;

    setState(() {
      final previousLength = _lines.length;
      _lines.addAll(generated);
      if (_lines.length > _maxHistoryLines) {
        final overflow = _lines.length - _maxHistoryLines;
        _lines.removeRange(0, overflow);
        _currentIndex = (_lines.length - generated.length).clamp(
          0,
          math.max(0, _lines.length - 1),
        );
      } else {
        _currentIndex = previousLength.clamp(0, math.max(0, _lines.length - 1));
      }
    });
  }

  void _ingestLiveTelemetry(TvCommentaryInputEvent telemetry) {
    // Pomijamy generowanie duplikatu, jeśli kluczowe parametry zdarzenia się nie zmieniły.
    final signature = [
      telemetry.triggerType.name,
      telemetry.riderName ?? '',
      (telemetry.wattsPerKg ?? 0.0).toStringAsFixed(1),
      telemetry.echelonGroupsCount ?? 0,
      telemetry.crashRiderCount ?? 0,
      telemetry.isFeedZoneActive,
      telemetry.virtualGcGapSeconds ?? 0,
    ].join('|');

    if (signature == _lastTelemetrySignature) return;
    _lastTelemetrySignature = signature;

    // Ignorujemy zwykły zrzut ogólny, jeśli mamy już świeże wypowiedzi.
    if (telemetry.triggerType == TvCommentaryTriggerType.generalBroadcast &&
        _lines.isNotEmpty) {
      return;
    }

    _ingestEvents([telemetry]);
  }

  void _restartAutoRotateTimer() {
    _autoRotateTimer?.cancel();
    if (!widget.enabled || _isPaused) return;

    _autoRotateTimer = Timer.periodic(widget.autoRotateInterval, (_) {
      if (!mounted || _lines.length <= 1 || _isPaused || !widget.enabled) {
        return;
      }
      setState(() {
        _currentIndex = (_currentIndex + 1) % _lines.length;
      });
    });
  }

  void _goPrevious() {
    if (!widget.enabled || _lines.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + _lines.length) % _lines.length;
    });
    _restartAutoRotateTimer();
  }

  void _goNext() {
    if (!widget.enabled || _lines.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _lines.length;
    });
    _restartAutoRotateTimer();
  }

  void _togglePause() {
    if (!widget.enabled) return;
    setState(() {
      _isPaused = !_isPaused;
    });
    _restartAutoRotateTimer();
  }

  void _toggleMute() {
    if (!widget.enabled) return;
    setState(() {
      _isMuted = !_isMuted;
    });
    widget.onMuteChanged?.call(_isMuted);
  }

  void _toggleHistory() {
    if (!widget.enabled) return;
    setState(() {
      _isHistoryExpanded = !_isHistoryExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_lines.isEmpty) {
      return const SizedBox.shrink();
    }

    final safeIndex = _currentIndex.clamp(0, _lines.length - 1);
    final currentLine = _lines[safeIndex];
    final Color triggerColor = currentLine.triggerType.accentColor;
    final bool isDisabled = !widget.enabled;

    return Opacity(
      opacity: isDisabled ? 0.55 : 1.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final bool isCompact = width < 560;
          final bool isWide = width >= 960;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: currentLine.isBreaking && !isDisabled
                    ? triggerColor.withValues(alpha: 0.75)
                    : AppTheme.borderColor,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: (currentLine.isBreaking && !isDisabled
                          ? triggerColor
                          : AppColors.background)
                      .withValues(alpha: currentLine.isBreaking ? 0.18 : 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 12 : 16,
                      vertical: isCompact ? 10 : 12,
                    ),
                    child: isCompact
                        ? _buildCompactLayout(currentLine, triggerColor, safeIndex)
                        : _buildRegularOrWideLayout(
                            currentLine,
                            triggerColor,
                            safeIndex,
                            isWide: isWide,
                          ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _isHistoryExpanded
                        ? _buildHistoryDrawer(safeIndex)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactLayout(
    TvCommentaryLine currentLine,
    Color triggerColor,
    int safeIndex,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildLiveBadge(currentLine.isBreaking),
            const SizedBox(width: 6),
            Flexible(
              child: _buildTriggerBadge(currentLine.triggerType, compact: true),
            ),
            const Spacer(),
            _buildKilometerBadge(currentLine.kilometerMark),
          ],
        ),
        const SizedBox(height: 8),
        _buildAnimatedQuoteArea(currentLine, compact: true),
        const SizedBox(height: 8),
        Row(
          children: [
            if (currentLine.telemetryTag != null)
              Flexible(
                child: _buildTelemetryTagChip(
                  currentLine.telemetryTag!,
                  triggerColor,
                ),
              ),
            const Spacer(),
            _buildControlsCluster(safeIndex, compact: true),
          ],
        ),
      ],
    );
  }

  Widget _buildRegularOrWideLayout(
    TvCommentaryLine currentLine,
    Color triggerColor,
    int safeIndex, {
    required bool isWide,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLiveBadge(currentLine.isBreaking),
                const SizedBox(width: 6),
                _buildKilometerBadge(currentLine.kilometerMark),
              ],
            ),
            const SizedBox(height: 6),
            _buildTriggerBadge(currentLine.triggerType, compact: false),
          ],
        ),
        const SizedBox(width: 14),
        Container(
          width: 1,
          height: 44,
          color: AppTheme.borderColor,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildAnimatedQuoteArea(currentLine, compact: false),
        ),
        if (isWide && currentLine.telemetryTag != null) ...[
          const SizedBox(width: 12),
          _buildTelemetryTagChip(currentLine.telemetryTag!, triggerColor),
        ],
        const SizedBox(width: 12),
        _buildControlsCluster(safeIndex, compact: false),
      ],
    );
  }

  Widget _buildLiveBadge(bool isBreaking) {
    final Color dotColor = _isMuted
        ? AppColors.textSecondary
        : (isBreaking ? AppColors.crimsonAlert : AppColors.goldAccent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dotColor.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _livePulseController,
            builder: (context, child) {
              final double scale = _isPaused || _isMuted || !widget.enabled
                  ? 1.0
                  : 0.8 + (_livePulseController.value * 0.35);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 5),
          Text(
            _isMuted ? 'TV MUTED' : 'LIVE TV',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKilometerBadge(double km) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Text(
        'KM ${km.toStringAsFixed(1)}',
        style: AppTheme.statNumberStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.goldAccent,
        ),
      ),
    );
  }

  Widget _buildTriggerBadge(
    TvCommentaryTriggerType type, {
    required bool compact,
  }) {
    final color = type.accentColor;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              type.badgeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryTagChip(String tag, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        tag,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.statNumberStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildAnimatedQuoteArea(
    TvCommentaryLine currentLine, {
    required bool compact,
  }) {
    final bool isExpert = currentLine.role == TvCommentatorRole.formerProExpert;
    final Color speakerColor =
        isExpert ? AppColors.goldAccent : AppColors.accentBlue;

    return GestureDetector(
      onTap: widget.enabled
          ? () => widget.onLineSelected?.call(currentLine)
          : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.14),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: Column(
          key: ValueKey<String>(currentLine.id),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isExpert ? Icons.directions_bike_rounded : Icons.mic_rounded,
                  size: 13,
                  color: speakerColor,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    '${currentLine.speakerName} • ${currentLine.speakerTitle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      color: speakerColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              _isMuted
                  ? 'Komentarz telewizyjny wyciszony — kliknij ikonę głośnika, aby przywrócić relację.'
                  : currentLine.message,
              maxLines: compact ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: compact ? 12.5 : 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                color: _isMuted ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsCluster(int safeIndex, {required bool compact}) {
    final bool canStep = widget.enabled && _lines.length > 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BroadcastControlButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Poprzednia wypowiedź',
          enabled: canStep,
          compact: compact,
          onPressed: _goPrevious,
        ),
        const SizedBox(width: 4),
        _BroadcastControlButton(
          icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          tooltip: _isPaused ? 'Wznów pasek komentarza' : 'Wstrzymaj pasek',
          enabled: widget.enabled,
          isActive: _isPaused,
          compact: compact,
          onPressed: _togglePause,
        ),
        const SizedBox(width: 4),
        _BroadcastControlButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Następna wypowiedź',
          enabled: canStep,
          compact: compact,
          onPressed: _goNext,
        ),
        const SizedBox(width: 4),
        _BroadcastControlButton(
          icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          tooltip: _isMuted ? 'Włącz komentarz TV' : 'Wycisz komentarz TV',
          enabled: widget.enabled,
          isActive: _isMuted,
          activeColor: AppColors.primaryAccent,
          compact: compact,
          onPressed: _toggleMute,
        ),
        const SizedBox(width: 4),
        _BroadcastControlButton(
          icon: _isHistoryExpanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.forum_rounded,
          tooltip: 'Historia transmisji (${safeIndex + 1}/${_lines.length})',
          enabled: widget.enabled,
          isActive: _isHistoryExpanded,
          compact: compact,
          onPressed: _toggleHistory,
        ),
      ],
    );
  }

  Widget _buildHistoryDrawer(int activeIndex) {
    final reversedLines = _lines.reversed.toList(growable: false);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: reversedLines.length,
        separatorBuilder: (_, __) => const Divider(
          height: 12,
          thickness: 1,
          color: AppTheme.borderColor,
        ),
        itemBuilder: (context, revIndex) {
          final originalIndex = _lines.length - 1 - revIndex;
          final line = reversedLines[revIndex];
          final bool isSelected = originalIndex == activeIndex;
          final bool isExpert = line.role == TvCommentatorRole.formerProExpert;
          final Color speakerColor =
              isExpert ? AppColors.goldAccent : AppColors.accentBlue;

          return InkWell(
            onTap: widget.enabled
                ? () {
                    setState(() {
                      _currentIndex = originalIndex;
                    });
                    widget.onLineSelected?.call(line);
                  }
                : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.surfaceLight
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(color: speakerColor.withValues(alpha: 0.45))
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'km ${line.kilometerMark.toStringAsFixed(1)}',
                    style: AppTheme.statNumberStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${line.speakerName} (${line.speakerTitle})',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: speakerColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          line.message,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Przycisk sterujący transmisją z pełnymi stanami `hover`, `active`, `focus` i `disabled`.
class _BroadcastControlButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final bool isActive;
  final Color activeColor;
  final bool compact;
  final VoidCallback onPressed;

  const _BroadcastControlButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    this.isActive = false,
    this.activeColor = AppColors.goldAccent,
    this.compact = false,
    required this.onPressed,
  });

  @override
  State<_BroadcastControlButton> createState() =>
      _BroadcastControlButtonState();
}

class _BroadcastControlButtonState extends State<_BroadcastControlButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  void _handleActivate() {
    if (!widget.enabled) return;
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.compact ? 28 : 32;
    final Color backgroundColor;
    final Color borderColor;
    final Color iconColor;

    if (!widget.enabled) {
      backgroundColor = AppColors.background.withValues(alpha: 0.4);
      borderColor = AppTheme.borderColor.withValues(alpha: 0.45);
      iconColor = AppColors.textSecondary.withValues(alpha: 0.38);
    } else if (_isPressed) {
      backgroundColor = widget.activeColor.withValues(alpha: 0.26);
      borderColor = widget.activeColor;
      iconColor = AppColors.textPrimary;
    } else if (widget.isActive) {
      backgroundColor = widget.activeColor.withValues(alpha: 0.18);
      borderColor = widget.activeColor.withValues(alpha: 0.8);
      iconColor = widget.activeColor;
    } else if (_isHovered) {
      backgroundColor = AppColors.surfaceLight;
      borderColor = AppColors.goldAccent.withValues(alpha: 0.6);
      iconColor = AppColors.textPrimary;
    } else {
      backgroundColor = AppColors.background;
      borderColor = AppTheme.borderColor;
      iconColor = AppColors.textSecondary;
    }

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowHoverHighlight: (hovered) {
          if (_isHovered != hovered) {
            setState(() => _isHovered = hovered);
          }
        },
        onShowFocusHighlight: (focused) {
          if (_isFocused != focused) {
            setState(() => _isFocused = focused);
          }
        },
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _handleActivate();
              return null;
            },
          ),
        },
        mouseCursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: widget.enabled
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: widget.enabled
              ? () => setState(() => _isPressed = false)
              : null,
          onTap: _handleActivate,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isFocused && widget.enabled
                    ? AppColors.goldAccent
                    : borderColor,
                width: _isFocused && widget.enabled ? 1.6 : 1.0,
              ),
            ),
            child: Icon(
              widget.icon,
              size: widget.compact ? 16 : 18,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
