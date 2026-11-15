import '../../models/race/stage_segment.dart';
import 'race_incident_engine.dart';

/// Kanał nadawczy komunikatu radiowego w trakcie etapu.
enum RadioChannel {
  /// Oficjalne Radio Wyścigu (Radio Tour / sędziowie i motocykle informacyjne)
  radioTour,

  /// Wewnętrzne radio zespołu gracza (Dyrektor Sportowy / DS Comms)
  directeurSportif,

  /// Motocykl pomiaru czasu (Moto Timekeeper / tablica z różnicami czasowymi)
  motoTimekeeper,

  /// Komunikat medyczny lub serwisowy neutralnego wozu Shimano/Mavic
  serviceNeutral;

  String toJson() => name;

  static RadioChannel fromJson(String value) {
    return RadioChannel.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RadioChannel.radioTour,
    );
  }

  String get label {
    switch (this) {
      case RadioChannel.radioTour:
        return 'Radio Tour';
      case RadioChannel.directeurSportif:
        return 'Dyrektor Sportowy';
      case RadioChannel.motoTimekeeper:
        return 'Moto Info';
      case RadioChannel.serviceNeutral:
        return 'Neutral Service';
    }
  }
}

/// Poziom priorytetu komunikatu radiowego (wpływa na kolorystykę i styl paska HUD).
enum RadioPriority {
  /// Czerwony alarm: kraksa, wycofanie z wyścigu (DNF), defekt lidera, pęknięcie peletonu
  urgent,

  /// Pomarańczowy: ostrzeżenie przed brukiem, strefa bocznego wiatru, odcięcie pomocnika
  warning,

  /// Niebieski: kluczowy manewr taktyczny, atak faworyta, zmiana w pociągu
  tactical,

  /// Biały / Szary: standardowa informacja o różnicy czasowej, punkcie na trasie
  info;

  String toJson() => name;

  static RadioPriority fromJson(String value) {
    return RadioPriority.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RadioPriority.info,
    );
  }
}

/// Pojedynczy komunikat radiowy wygenerowany w trakcie symulacji etapu.
class RaceRadioMessage {
  final String id;

  /// Kilometr etapu, na którym nadano komunikat [km]
  final double kilometerMark;

  /// Czas trwania etapu w sekundach od startu [s]
  final double elapsedSeconds;

  /// Kanał nadawczy
  final RadioChannel channel;

  /// Priorytet komunikatu
  final RadioPriority priority;

  /// Nazwa nadawcy (np. "Radio Tour", "DS Soudal Quick-Step", "Moto Info")
  final String senderName;

  /// Treść komunikatu radiowego wyświetlana na pasku HUD
  final String message;

  /// Opcjonalne powiązane nazwisko kolarza
  final String? highlightedRiderName;

  /// Opcjonalna powiązana nazwa drużyny
  final String? highlightedTeamName;

  const RaceRadioMessage({
    required this.id,
    required this.kilometerMark,
    required this.elapsedSeconds,
    required this.channel,
    required this.priority,
    required this.senderName,
    required this.message,
    this.highlightedRiderName,
    this.highlightedTeamName,
  });

  /// Sformatowany znacznik kilometrażu (np. "KM 142.5")
  String get formattedKm => 'KM ${kilometerMark.toStringAsFixed(1)}';

  /// Sformatowany czas wyścigu (np. "03:24:15")
  String get formattedTime {
    final int totalSec = elapsedSeconds.round();
    final int hours = totalSec ~/ 3600;
    final int minutes = (totalSec % 3600) ~/ 60;
    final int seconds = totalSec % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  RaceRadioMessage copyWith({
    String? id,
    double? kilometerMark,
    double? elapsedSeconds,
    RadioChannel? channel,
    RadioPriority? priority,
    String? senderName,
    String? message,
    String? highlightedRiderName,
    String? highlightedTeamName,
  }) {
    return RaceRadioMessage(
      id: id ?? this.id,
      kilometerMark: kilometerMark ?? this.kilometerMark,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      channel: channel ?? this.channel,
      priority: priority ?? this.priority,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      highlightedRiderName: highlightedRiderName ?? this.highlightedRiderName,
      highlightedTeamName: highlightedTeamName ?? this.highlightedTeamName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kilometerMark': kilometerMark,
      'elapsedSeconds': elapsedSeconds,
      'channel': channel.toJson(),
      'priority': priority.toJson(),
      'senderName': senderName,
      'message': message,
      'highlightedRiderName': highlightedRiderName,
      'highlightedTeamName': highlightedTeamName,
    };
  }

  factory RaceRadioMessage.fromJson(Map<String, dynamic> json) {
    return RaceRadioMessage(
      id: json['id'] as String,
      kilometerMark: (json['kilometerMark'] as num).toDouble(),
      elapsedSeconds: (json['elapsedSeconds'] as num).toDouble(),
      channel: RadioChannel.fromJson(json['channel'] as String),
      priority: RadioPriority.fromJson(json['priority'] as String),
      senderName: json['senderName'] as String,
      message: json['message'] as String,
      highlightedRiderName: json['highlightedRiderName'] as String?,
      highlightedTeamName: json['highlightedTeamName'] as String?,
    );
  }

  @override
  String toString() {
    return '[$formattedKm | $senderName]: $message';
  }
}

/// Generator realistycznych komunikatów Radia Wyścigowego (Race Radio / DS Comms).
///
/// Śledzi dynamikę wyścigu i tworzy zwięzłe, klimatyczne meldunki na pasek HUD:
/// - Ataki faworytów i formowanie ucieczki
/// - Kraksy, upadki faworytów i blokady szosy
/// - Defekty mechaniczne, przebicia i oddawanie rowerów przez pomocników
/// - Odcięcie prądu u pomocnika (wyczerpanie glikogenu / puste W')
/// - Zbliżające się niebezpieczne sektory (bruk, zwężenia, strome ścianki)
/// - Strefy wiatru bocznego i tworzenie wachlarzy (echelons)
/// - Oficjalne różnice czasowe motocykla pomiarowego
class RaceRadioGenerator {
  RaceRadioGenerator._();

  static int _messageCounter = 0;

  static String _generateMessageId() {
    _messageCounter++;
    return 'radio_${DateTime.now().millisecondsSinceEpoch}_$_messageCounter';
  }

  /// 1. Komunikat o kraksie w peletonie.
  static RaceRadioMessage generateCrashMessage({
    required double kilometerMark,
    required double elapsedSeconds,
    required RaceIncidentEvent incident,
  }) {
    final int count = incident.primaryVictims.length;
    final bool hasDnf = incident.hasDnf;

    String text;
    if (hasDnf) {
      final victim = incident.dnfVictims.first;
      text = 'CHUTE! Kraksa na ${kilometerMark.toStringAsFixed(1)} km! ${victim.riderName} (${victim.description}) wycofuje się z wyścigu!';
    } else if (count >= 5) {
      text = 'KRAKSA ZBIOROWA! Leży około $count kolarzy. Szosa częściowo zablokowana na ${kilometerMark.toStringAsFixed(1)} km.';
    } else {
      final victimName = incident.primaryVictims.isNotEmpty ? incident.primaryVictims.first.riderName : 'kolarz';
      text = 'Upadek na trasie: $victimName leży na asfalcie, ale szybko zbiera rower.';
    }

    return RaceRadioMessage(
      id: _generateMessageId(),
      kilometerMark: kilometerMark,
      elapsedSeconds: elapsedSeconds,
      channel: RadioChannel.radioTour,
      priority: RadioPriority.urgent,
      senderName: 'Radio Tour',
      message: text,
      highlightedRiderName: incident.primaryVictims.isNotEmpty ? incident.primaryVictims.first.riderName : null,
    );
  }

  /// 2. Komunikat o defekcie mechanicznym lub przebiciu opony.
  static RaceRadioMessage generatePunctureMessage({
    required double kilometerMark,
    required double elapsedSeconds,
    required IncidentVictim victim,
    bool isLeader = false,
  }) {
    String text;
    RadioPriority priority = RadioPriority.warning;

    if (victim.assistanceMethod == AssistanceMethod.teammateBikeSwap) {
      priority = RadioPriority.urgent;
      text = 'DEFEKT KOŁA! Pomocnik oddaje swój rower liderowi [${victim.riderName}]! Błyskawiczna wymiana w ferworze walki!';
    } else if (isLeader) {
      priority = RadioPriority.urgent;
      text = 'DRAMAT LATERA! Przebita opona u [${victim.riderName}]! Samochód serwisowy wezwany na czoło kolumny!';
    } else {
      text = 'Defekt mechaniczny: ${victim.riderName} sygnalizuje uniesioną ręką przebicie koła.';
    }

    return RaceRadioMessage(
      id: _generateMessageId(),
      kilometerMark: kilometerMark,
      elapsedSeconds: elapsedSeconds,
      channel: RadioChannel.radioTour,
      priority: priority,
      senderName: 'Radio Tour',
      message: text,
      highlightedRiderName: victim.riderName,
      highlightedTeamName: victim.teamId,
    );
  }

  /// 3. Komunikat o ataku faworyta lub kolarza z peletonu.
  static RaceRadioMessage generateAttackMessage({
    required double kilometerMark,
    required double elapsedSeconds,
    required String attackerName,
    required String teamName,
    double? gradientPercent,
    bool isGcContender = false,
  }) {
    String text;
    if (gradientPercent != null && gradientPercent >= 9.0) {
      text = 'ATAK NA ŚCIANCE! $attackerName ($teamName) odpala potężne przyspieszenie na nachyleniu ${gradientPercent.toStringAsFixed(1)}%!';
    } else if (isGcContender) {
      text = 'OGIEŃ W CZUBIE! Faworyt klasyfikacji generalnej $attackerName ($teamName) rwie peleton!';
    } else {
      text = 'Skok z grupy! $attackerName ($teamName) decyduje się na atak i próbuje odjechać.';
    }

    return RaceRadioMessage(
      id: _generateMessageId(),
      kilometerMark: kilometerMark,
      elapsedSeconds: elapsedSeconds,
      channel: RadioChannel.radioTour,
      priority: isGcContender ? RadioPriority.urgent : RadioPriority.tactical,
      senderName: 'Radio Tour',
      message: text,
      highlightedRiderName: attackerName,
      highlightedTeamName: teamName,
    );
  }

  /// 4. Ostrzeżenie przed wiatrem bocznym i tworzeniem wachlarzy (echelons).
  static RaceRadioMessage generateCrosswindWarning({
    required double kilometerMark,
    required double elapsedSeconds,
    required double crosswindKmh,
    required int echelonsCount,
    bool isPelotonSplit = false,
  }) {
    String text;
    RadioPriority priority = RadioPriority.warning;

    if (isPelotonSplit) {
      priority = RadioPriority.urgent;
      text = 'PELETON PĘKA NA RATACH! Boczny wiatr ${crosswindKmh.toStringAsFixed(0)} km/h rorywa stawkę na $echelonsCount osobne wachlarze!';
    } else {
      text = 'Uwaga na boczny wiatr (${crosswindKmh.toStringAsFixed(0)} km/h)! Szosa odsłonięta, kolarze ustawiają się w wachlarz!';
    }

    return RaceRadioMessage(
      id: _generateMessageId(),
      kilometerMark: kilometerMark,
      elapsedSeconds: elapsedSeconds,
      channel: RadioChannel.radioTour,
      priority: priority,
      senderName: 'Radio Tour',
      message: text,
    );
  }

  /// 5. Ostrzeżenie dyrektora sportowego przed wjazdem na sektor bruku lub zwężenie.
  static RaceRadioMessage generateApproachingCobbleWarning({
    required double kilometerMark,
    required double elapsedSeconds,
    required String teamName,
    required SegmentSurfaceType surfaceType,
    required double distanceToSectorMeters,
  }) {
    final int meters = distanceToSectorMeters.round();
    String text;

    if (surfaceType == SegmentSurfaceType.cobblestonesSector5 ||
        surfaceType == SegmentSurfaceType.cobblestonesSector4) {
      text = 'DS $teamName: Uwaga zespół! Za $meters m kluczowy, trudny sektor bruku! Walka o czub, pilnować lidera!';
    } else if (surfaceType == SegmentSurfaceType.gravelStrade) {
      text = 'DS $teamName: Za $meters m wjazd na biały szuter (Strade)! Uwaga na kurz i uślizgi kół!';
    } else {
      text = 'DS $teamName: Zbliża się sektor brukowy ($meters m). Utrzymywać pozycję w pierwszej dziesiątce!';
    }

    return RaceRadioMessage(
      id: _generateMessageId(),
      kilometerMark: kilometerMark,
      elapsedSeconds: elapsedSeconds,
      channel: RadioChannel.directeurSportif,
      priority: RadioPriority.warning,
      senderName: 'DS $teamName',
      message: text,
      highlightedTeamName: teamName,
    );
  }

  /// 6. Komunikat o wyczerpaniu pomocnika (odcięcie beztlenowe / głód / puste nogi).
  static RaceRadioMessage generateDomestiqueDepletedMessage({
    required double kilometerMark,
    required double elapsedSeconds,
    required String domestiqueName,
    required String teamName,
    bool isBonking = false,
  }) {
    final String text = isBonking
        ? 'DS $teamName: $domestiqueName całkowicie odcięty z braku cukru (Bonk)! Zjeżdża na bok, lider zostaje bez wsparcia.'
        : 'DS $teamName: Pomocnik $domestiqueName dał z siebie 100% na czele pociągu i spływa z siłami do tyłu.';

    return RaceRadioMessage(
      id: _generateMessageId(),
      kilometerMark: kilometerMark,
      elapsedSeconds: elapsedSeconds,
      channel: RadioChannel.directeurSportif,
      priority: RadioPriority.warning,
      senderName: 'DS $teamName',
      message: text,
      highlightedRiderName: domestiqueName,
      highlightedTeamName: teamName,
    );
  }

  /// 7. Meldunek pomiarowy różnicy czasowej między ucieczką a peletonem.
  static RaceRadioMessage generateTimeGapReport({
    required double kilometerMark,
    required double elapsedSeconds,
    required double gapSeconds,
    required int breakawayRiderCount,
  }) {
    final int totalSec = gapSeconds.round();
    final int minutes = totalSec ~/ 60;
    final int seconds = totalSec % 60;
    final String timeStr = '${minutes}m ${seconds.toString().padLeft(2, '0')}s';

    final String text = 'Moto Info: Różnica czasowa na trasie: $breakawayRiderCount kolarzy na czele z przewagą $timeStr nad peletonem.';

    return RaceRadioMessage(
      id: _generateMessageId(),
      kilometerMark: kilometerMark,
      elapsedSeconds: elapsedSeconds,
      channel: RadioChannel.motoTimekeeper,
      priority: RadioPriority.info,
      senderName: 'Moto Info',
      message: text,
    );
  }

  /// 8. Komunikat na ostatnim kilometrze (Flamme Rouge) etapu sprinterskiego.
  static RaceRadioMessage generateFlammeRougeMessage({
    required double kilometerMark,
    required double elapsedSeconds,
    required String teamName,
  }) {
    return RaceRadioMessage(
      id: _generateMessageId(),
      kilometerMark: kilometerMark,
      elapsedSeconds: elapsedSeconds,
      channel: RadioChannel.directeurSportif,
      priority: RadioPriority.urgent,
      senderName: 'DS $teamName',
      message: 'FLAMME ROUGE! Ostatni kilometr! Pociągi idą pełnym ogniem, pilot wyprowadza sprintera na 250 metrów!',
      highlightedTeamName: teamName,
    );
  }
}

