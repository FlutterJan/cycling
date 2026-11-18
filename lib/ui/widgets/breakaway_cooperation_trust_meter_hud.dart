import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Status wkładu pojedynczego uciekiniera w prowadzenie grupy dnia.
enum BreakawayRiderContributionStatus {
  /// Kolarz bierze ponadprzeciętną liczbę zmian i ciągnie grupę.
  pullingHard(
    label: 'Mocno ciągnie',
    shortLabel: 'Praca+',
    icon: Icons.bolt_rounded,
    color: AppColors.accentBlue,
  ),

  /// Kolarz współpracuje uczciwie proporcjonalnie do liczebności grupy.
  cooperative(
    label: 'Równa współpraca',
    shortLabel: 'OK',
    icon: Icons.handshake_rounded,
    color: AppColors.statusSuccess,
  ),

  /// Kolarz opuszcza zmiany lub daje wyraźnie krótsze zmiany.
  skippingTurns(
    label: 'Oszczędza siły!',
    shortLabel: 'Oszczędza',
    icon: Icons.warning_amber_rounded,
    color: AppColors.amberWarning,
  ),

  /// Kolarz w ogóle nie wychodzi na zmianę i wiezie się na kole.
  freewheeling(
    label: 'Wiezie się na kole!',
    shortLabel: 'Pasażer',
    icon: Icons.block_rounded,
    color: AppColors.crimsonAlert,
  );

  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;

  const BreakawayRiderContributionStatus({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.color,
  });

  /// Czy status oznacza unikanie pracy na czele grupy.
  bool get isUnderContributing =>
      this == BreakawayRiderContributionStatus.skippingTurns ||
      this == BreakawayRiderContributionStatus.freewheeling;
}

/// Ogólny poziom zaufania i harmonii w ucieczce dnia.
enum BreakawayGroupHarmonyLevel {
  /// Wszyscy uciekinierzy dają równe zmiany.
  united(
    badgeLabel: 'ZGODA W GRUPIE',
    description: 'Ucieczka pracuje równym wachlarzem — wysokie morale zmian.',
    color: AppColors.statusSuccess,
    icon: Icons.verified_rounded,
  ),

  /// Co najmniej jeden kolarz oszczędza siły, rośnie napięcie.
  tense(
    badgeLabel: 'NAPIĘCIE W GRUPIE',
    description: 'Wykryto nierówny podział pracy — część kolarzy oszczędza siły.',
    color: AppColors.amberWarning,
    icon: Icons.warning_rounded,
  ),

  /// Poważny kryzys współpracy i groźba kontrataku lub rozpadu grupy.
  fracturing(
    badgeLabel: 'ROZŁAM UCIECZKI',
    description: 'Brak zaufania w odjeździe — grozi zatrzymanie zmian lub kontra!',
    color: AppColors.crimsonAlert,
    icon: Icons.gpp_bad_rounded,
  ),

  /// Wskaźnik wyłączony lub brak danych telemetrycznych.
  disabled(
    badgeLabel: 'WYŁĄCZONY',
    description: 'Telemetria współpracy ucieczki jest nieaktywna.',
    color: AppColors.textSecondary,
    icon: Icons.sensors_off_rounded,
  );

  final String badgeLabel;
  final String description;
  final Color color;
  final IconData icon;

  const BreakawayGroupHarmonyLevel({
    required this.badgeLabel,
    required this.description,
    required this.color,
    required this.icon,
  });
}

/// Tryb prezentacji szczegółów na kartach uciekinierów w HUD.
enum BreakawayTrustMeterViewMode {
  /// Procentowy udział w prowadzeniu (`42% zmian`) i pasek wkładu.
  contributionShare(
    label: '% zmian',
    icon: Icons.pie_chart_rounded,
  ),

  /// Czas na czele, waty zmiany i indywidualny indeks zaufania.
  powerAndTime(
    label: 'Moc / Czas',
    icon: Icons.speed_rounded,
  );

  final String label;
  final IconData icon;

  const BreakawayTrustMeterViewMode({
    required this.label,
    required this.icon,
  });
}

/// Niemutowalny wpis telemetrii wkładu pojedynczego uciekiniera.
@immutable
class BreakawayRiderContributionEntry {
  /// Unikalny identyfikator kolarza.
  final String riderId;

  /// Imię i nazwisko lub etykieta kolarza (np. `Kolarz A`).
  final String riderName;

  /// Trzyliterowy kod drużyny (np. `PLM`).
  final String teamShortCode;

  /// Kolor koszulki drużyny używany na pasku podziału pracy.
  final Color jerseyColor;

  /// Czy to kolarz prowadzony przez gracza.
  final bool isPlayerRider;

  /// Procentowy wkład kolarza w prowadzenie ucieczki (0..100).
  final double leadSharePercent;

  /// Łączny czas spędzony na czele grupy w sekundach.
  final int pullSeconds;

  /// Średnia moc generowana podczas dawania zmian (W).
  final int avgPullWatts;

  /// Liczba pominiętych zmian w rotacji.
  final int turnsSkippedCount;

  /// Indywidualna ocena zaufania w grupie (0..100).
  final double trustScore;

  /// Czy kolarz aktualnie jedzie na pierwszym kole i daje zmianę.
  final bool isCurrentlyPulling;

  /// Tworzy wpis wkładu kolarza w ucieczce dnia.
  const BreakawayRiderContributionEntry({
    required this.riderId,
    required this.riderName,
    required this.teamShortCode,
    required this.jerseyColor,
    this.isPlayerRider = false,
    required this.leadSharePercent,
    this.pullSeconds = 0,
    this.avgPullWatts = 0,
    this.turnsSkippedCount = 0,
    this.trustScore = 100.0,
    this.isCurrentlyPulling = false,
  });

  /// Bezpieczny, znormalizowany procent wkładu w zakresie `0.0..100.0`.
  double get safeLeadSharePercent {
    if (!leadSharePercent.isFinite) return 0.0;
    return leadSharePercent.clamp(0.0, 100.0).toDouble();
  }

  /// Zaokrąglony procent wkładu do wyświetlenia w UI.
  int get roundedLeadSharePercent => safeLeadSharePercent.round();

  /// Bezpieczny czas na czele w sekundach (`>= 0`).
  int get safePullSeconds => pullSeconds < 0 ? 0 : pullSeconds;

  /// Bezpieczna średnia moc w watach (`>= 0`).
  int get safeAvgPullWatts => avgPullWatts < 0 ? 0 : avgPullWatts;

  /// Bezpieczna liczba opuszczonych zmian (`>= 0`).
  int get safeTurnsSkippedCount => turnsSkippedCount < 0 ? 0 : turnsSkippedCount;

  /// Bezpieczny wskaźnik zaufania (`0.0..100.0`).
  double get safeTrustScore {
    if (!trustScore.isFinite) return 0.0;
    return trustScore.clamp(0.0, 100.0).toDouble();
  }

  /// Wyznacza status współpracy kolarza względem równego podziału w grupie.
  BreakawayRiderContributionStatus resolveStatus(int groupSize) {
    if (groupSize <= 1) {
      return BreakawayRiderContributionStatus.cooperative;
    }
    final double fairShare = 100.0 / groupSize;
    final double share = safeLeadSharePercent;

    if (share < 6.0 || (safeTurnsSkippedCount >= 4 && share < fairShare * 0.45)) {
      return BreakawayRiderContributionStatus.freewheeling;
    }
    if (share < fairShare * 0.70 ||
        (safeTurnsSkippedCount >= 2 && share < fairShare * 0.85)) {
      return BreakawayRiderContributionStatus.skippingTurns;
    }
    if (share >= fairShare * 1.15) {
      return BreakawayRiderContributionStatus.pullingHard;
    }
    return BreakawayRiderContributionStatus.cooperative;
  }

  /// Formatuje krótki opis wkładu (np. `Kolarz A: 42% zmian` lub `Kolarz C: 18% — Oszczędza siły!`).
  String formatSummarySegment(int groupSize) {
    final BreakawayRiderContributionStatus status = resolveStatus(groupSize);
    if (status == BreakawayRiderContributionStatus.skippingTurns) {
      return '$riderName: $roundedLeadSharePercent% — ${status.label}';
    }
    if (status == BreakawayRiderContributionStatus.freewheeling) {
      return '$riderName: $roundedLeadSharePercent% — ${status.label}';
    }
    return '$riderName: $roundedLeadSharePercent% zmian';
  }

  /// Tworzy kopię wpisu z wybranymi modyfikacjami.
  BreakawayRiderContributionEntry copyWith({
    String? riderId,
    String? riderName,
    String? teamShortCode,
    Color? jerseyColor,
    bool? isPlayerRider,
    double? leadSharePercent,
    int? pullSeconds,
    int? avgPullWatts,
    int? turnsSkippedCount,
    double? trustScore,
    bool? isCurrentlyPulling,
  }) {
    return BreakawayRiderContributionEntry(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      teamShortCode: teamShortCode ?? this.teamShortCode,
      jerseyColor: jerseyColor ?? this.jerseyColor,
      isPlayerRider: isPlayerRider ?? this.isPlayerRider,
      leadSharePercent: leadSharePercent ?? this.leadSharePercent,
      pullSeconds: pullSeconds ?? this.pullSeconds,
      avgPullWatts: avgPullWatts ?? this.avgPullWatts,
      turnsSkippedCount: turnsSkippedCount ?? this.turnsSkippedCount,
      trustScore: trustScore ?? this.trustScore,
      isCurrentlyPulling: isCurrentlyPulling ?? this.isCurrentlyPulling,
    );
  }

  /// Serializuje wpis do mapy JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'riderId': riderId,
        'riderName': riderName,
        'teamShortCode': teamShortCode,
        'jerseyColorValue': jerseyColor.toARGB32(),
        'isPlayerRider': isPlayerRider,
        'leadSharePercent': safeLeadSharePercent,
        'pullSeconds': safePullSeconds,
        'avgPullWatts': safeAvgPullWatts,
        'turnsSkippedCount': safeTurnsSkippedCount,
        'trustScore': safeTrustScore,
        'isCurrentlyPulling': isCurrentlyPulling,
      };

  /// Odtwarza wpis z mapy JSON.
  factory BreakawayRiderContributionEntry.fromJson(Map<String, dynamic> json) {
    final int colorValue =
        (json['jerseyColorValue'] as num?)?.toInt() ?? 0xFF38BDF8;
    return BreakawayRiderContributionEntry(
      riderId: (json['riderId'] as String?) ?? 'rider_unknown',
      riderName: (json['riderName'] as String?) ?? 'Kolarz',
      teamShortCode: (json['teamShortCode'] as String?) ?? 'PRO',
      jerseyColor: Color(colorValue),
      isPlayerRider: (json['isPlayerRider'] as bool?) ?? false,
      leadSharePercent:
          (json['leadSharePercent'] as num?)?.toDouble() ?? 0.0,
      pullSeconds: (json['pullSeconds'] as num?)?.toInt() ?? 0,
      avgPullWatts: (json['avgPullWatts'] as num?)?.toInt() ?? 0,
      turnsSkippedCount: (json['turnsSkippedCount'] as num?)?.toInt() ?? 0,
      trustScore: (json['trustScore'] as num?)?.toDouble() ?? 100.0,
      isCurrentlyPulling: (json['isCurrentlyPulling'] as bool?) ?? false,
    );
  }
}

/// Kalkulator metryk współpracy i indeksu zaufania w ucieczce dnia.
class BreakawayCooperationCalculator {
  const BreakawayCooperationCalculator._();

  /// Normalizuje procentowy udział kolarzy tak, aby sumował się do 100%
  /// (lub zwraca 0% dla wszystkich, gdy suma wejściowa wynosi 0).
  static List<BreakawayRiderContributionEntry> normalizeShares(
    List<BreakawayRiderContributionEntry> riders,
  ) {
    if (riders.isEmpty) return const <BreakawayRiderContributionEntry>[];

    double totalShare = 0.0;
    for (final BreakawayRiderContributionEntry rider in riders) {
      totalShare += rider.safeLeadSharePercent;
    }

    if (totalShare <= 0.0) {
      int totalSeconds = 0;
      for (final BreakawayRiderContributionEntry rider in riders) {
        totalSeconds += rider.safePullSeconds;
      }
      if (totalSeconds <= 0) {
        return riders
            .map((BreakawayRiderContributionEntry r) =>
                r.copyWith(leadSharePercent: 0.0))
            .toList(growable: false);
      }
      return riders
          .map(
            (BreakawayRiderContributionEntry r) => r.copyWith(
              leadSharePercent: (r.safePullSeconds / totalSeconds) * 100.0,
            ),
          )
          .toList(growable: false);
    }

    return riders
        .map(
          (BreakawayRiderContributionEntry r) => r.copyWith(
            leadSharePercent: (r.safeLeadSharePercent / totalShare) * 100.0,
          ),
        )
        .toList(growable: false);
  }

  /// Oblicza zbiorczy indeks zaufania grupy (0..100) na podstawie odchylenia
  /// od równego podziału zmian oraz liczby opuszczonych zmian.
  static double computeGroupTrustIndex(
    List<BreakawayRiderContributionEntry> riders,
  ) {
    if (riders.isEmpty) return 0.0;
    if (riders.length == 1) return 100.0;

    final List<BreakawayRiderContributionEntry> normalized =
        normalizeShares(riders);
    final double fairShare = 100.0 / normalized.length;

    double deviationSum = 0.0;
    int totalSkipped = 0;
    for (final BreakawayRiderContributionEntry rider in normalized) {
      deviationSum += (rider.safeLeadSharePercent - fairShare).abs();
      totalSkipped += rider.safeTurnsSkippedCount;
    }

    // Maksymalne teoretyczne odchylenie gdy jedna osoba ciągnie 100%.
    final double maxDeviation =
        (100.0 - fairShare) + (normalized.length - 1) * fairShare;
    final double imbalanceRatio =
        maxDeviation > 0.0 ? (deviationSum / maxDeviation).clamp(0.0, 1.0) : 0.0;

    final double skipPenalty = math.min(35.0, totalSkipped * 4.5);
    final double score = 100.0 - (imbalanceRatio * 75.0) - skipPenalty;
    return score.clamp(0.0, 100.0).toDouble();
  }

  /// Wyznacza poziom harmonii grupy na podstawie zaufania i statusów kolarzy.
  static BreakawayGroupHarmonyLevel resolveHarmonyLevel({
    required List<BreakawayRiderContributionEntry> riders,
    required double groupTrustIndex,
    bool isEnabled = true,
  }) {
    if (!isEnabled || riders.isEmpty) {
      return BreakawayGroupHarmonyLevel.disabled;
    }
    final int count = riders.length;
    final bool hasFreewheeler = riders.any(
      (BreakawayRiderContributionEntry r) =>
          r.resolveStatus(count) == BreakawayRiderContributionStatus.freewheeling,
    );
    final bool hasSkipper = riders.any(
      (BreakawayRiderContributionEntry r) =>
          r.resolveStatus(count) == BreakawayRiderContributionStatus.skippingTurns,
    );

    if (groupTrustIndex < 45.0 || (hasFreewheeler && groupTrustIndex < 65.0)) {
      return BreakawayGroupHarmonyLevel.fracturing;
    }
    if (groupTrustIndex < 75.0 || hasSkipper || hasFreewheeler) {
      return BreakawayGroupHarmonyLevel.tense;
    }
    return BreakawayGroupHarmonyLevel.united;
  }

  /// Buduje zwięzłą linię podsumowania wkładu każdego uciekiniera, np.
  /// `Kolarz A: 42% zmian, Kolarz B: 40% zmian, Kolarz C: 18% — Oszczędza siły!`.
  static String buildContributionSummaryLine(
    List<BreakawayRiderContributionEntry> riders,
  ) {
    if (riders.isEmpty) {
      return 'Brak aktywnych uciekinierów przed peletonem.';
    }
    final int count = riders.length;
    return riders
        .map((BreakawayRiderContributionEntry r) => r.formatSummarySegment(count))
        .join(', ');
  }
}

/// Niemutowalny model danych dla wskaźnika współpracy ucieczki dnia.
@immutable
class BreakawayCooperationTrustMeterData {
  /// Nazwa lub etykieta grupy ucieczkowej.
  final String breakawayGroupName;

  /// Przewaga nad peletonem w sekundach.
  final int gapToPelotonSeconds;

  /// Pozostały dystans do mety w kilometrach.
  final double distanceRemainingKm;

  /// Aktualna średnia prędkość grupy w km/h.
  final double groupSpeedKmh;

  /// Czy wskaźnik jest aktywny.
  final bool isEnabled;

  /// Opcjonalnie jawny indeks zaufania (jeśli null, liczony automatycznie).
  final double? explicitGroupTrustIndex;

  /// Lista kolarzy w ucieczce dnia.
  final List<BreakawayRiderContributionEntry> riders;

  /// Tworzy model danych wskaźnika współpracy grupy.
  const BreakawayCooperationTrustMeterData({
    required this.breakawayGroupName,
    required this.gapToPelotonSeconds,
    required this.distanceRemainingKm,
    required this.groupSpeedKmh,
    this.isEnabled = true,
    this.explicitGroupTrustIndex,
    required this.riders,
  });

  /// Przykładowy zestaw danych demonstracyjnych z 3 uciekinierami (42%, 40%, 18%).
  factory BreakawayCooperationTrustMeterData.sample() {
    return const BreakawayCooperationTrustMeterData(
      breakawayGroupName: 'Ucieczka dnia',
      gapToPelotonSeconds: 165,
      distanceRemainingKm: 34.6,
      groupSpeedKmh: 45.8,
      isEnabled: true,
      riders: <BreakawayRiderContributionEntry>[
        BreakawayRiderContributionEntry(
          riderId: 'rider_a',
          riderName: 'Kolarz A',
          teamShortCode: 'PLM',
          jerseyColor: AppColors.accentBlue,
          isPlayerRider: true,
          leadSharePercent: 42.0,
          pullSeconds: 756,
          avgPullWatts: 412,
          turnsSkippedCount: 0,
          trustScore: 94.0,
          isCurrentlyPulling: true,
        ),
        BreakawayRiderContributionEntry(
          riderId: 'rider_b',
          riderName: 'Kolarz B',
          teamShortCode: 'VSM',
          jerseyColor: AppColors.goldAccent,
          isPlayerRider: false,
          leadSharePercent: 40.0,
          pullSeconds: 720,
          avgPullWatts: 398,
          turnsSkippedCount: 0,
          trustScore: 91.0,
          isCurrentlyPulling: false,
        ),
        BreakawayRiderContributionEntry(
          riderId: 'rider_c',
          riderName: 'Kolarz C',
          teamShortCode: 'IGD',
          jerseyColor: AppColors.amberWarning,
          isPlayerRider: false,
          leadSharePercent: 18.0,
          pullSeconds: 324,
          avgPullWatts: 345,
          turnsSkippedCount: 3,
          trustScore: 46.0,
          isCurrentlyPulling: false,
        ),
      ],
    );
  }

  /// Pusty model danych (np. po doścignięciu ucieczki przez peleton).
  factory BreakawayCooperationTrustMeterData.empty() {
    return const BreakawayCooperationTrustMeterData(
      breakawayGroupName: 'Ucieczka dnia',
      gapToPelotonSeconds: 0,
      distanceRemainingKm: 0.0,
      groupSpeedKmh: 0.0,
      isEnabled: true,
      riders: <BreakawayRiderContributionEntry>[],
    );
  }

  /// Bezpieczna przewaga nad peletonem w sekundach (`>= 0`).
  int get safeGapToPelotonSeconds =>
      gapToPelotonSeconds < 0 ? 0 : gapToPelotonSeconds;

  /// Bezpieczny dystans do mety (`>= 0.0`).
  double get safeDistanceRemainingKm {
    if (!distanceRemainingKm.isFinite || distanceRemainingKm < 0.0) return 0.0;
    return distanceRemainingKm;
  }

  /// Bezpieczna prędkość grupy (`>= 0.0`).
  double get safeGroupSpeedKmh {
    if (!groupSpeedKmh.isFinite || groupSpeedKmh < 0.0) return 0.0;
    return groupSpeedKmh;
  }

  /// Zwraca listę uciekinierów ze znormalizowanym udziałem procentowym.
  List<BreakawayRiderContributionEntry> get normalizedRiders =>
      BreakawayCooperationCalculator.normalizeShares(riders);

  /// Obliczony lub jawny indeks zaufania grupy (`0.0..100.0`).
  double get resolvedGroupTrustIndex {
    if (explicitGroupTrustIndex != null && explicitGroupTrustIndex!.isFinite) {
      return explicitGroupTrustIndex!.clamp(0.0, 100.0).toDouble();
    }
    return BreakawayCooperationCalculator.computeGroupTrustIndex(riders);
  }

  /// Wyznaczony poziom harmonii w ucieczce.
  BreakawayGroupHarmonyLevel get harmonyLevel =>
      BreakawayCooperationCalculator.resolveHarmonyLevel(
        riders: riders,
        groupTrustIndex: resolvedGroupTrustIndex,
        isEnabled: isEnabled,
      );

  /// Sformatowana przewaga czasowa nad peletonem (np. `+2:45`).
  String get formattedGap {
    final int sec = safeGapToPelotonSeconds;
    final int minutes = sec ~/ 60;
    final int remSeconds = sec % 60;
    return '+$minutes:${remSeconds.toString().padLeft(2, '0')}';
  }

  /// Podsumowanie tekstowe wkładu wszystkich uciekinierów.
  String get summaryLine =>
      BreakawayCooperationCalculator.buildContributionSummaryLine(riders);

  /// Tworzy kopię danych z wybranymi modyfikacjami.
  BreakawayCooperationTrustMeterData copyWith({
    String? breakawayGroupName,
    int? gapToPelotonSeconds,
    double? distanceRemainingKm,
    double? groupSpeedKmh,
    bool? isEnabled,
    double? explicitGroupTrustIndex,
    List<BreakawayRiderContributionEntry>? riders,
  }) {
    return BreakawayCooperationTrustMeterData(
      breakawayGroupName: breakawayGroupName ?? this.breakawayGroupName,
      gapToPelotonSeconds: gapToPelotonSeconds ?? this.gapToPelotonSeconds,
      distanceRemainingKm: distanceRemainingKm ?? this.distanceRemainingKm,
      groupSpeedKmh: groupSpeedKmh ?? this.groupSpeedKmh,
      isEnabled: isEnabled ?? this.isEnabled,
      explicitGroupTrustIndex:
          explicitGroupTrustIndex ?? this.explicitGroupTrustIndex,
      riders: riders ?? this.riders,
    );
  }

  /// Serializuje model danych do JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'breakawayGroupName': breakawayGroupName,
        'gapToPelotonSeconds': safeGapToPelotonSeconds,
        'distanceRemainingKm': safeDistanceRemainingKm,
        'groupSpeedKmh': safeGroupSpeedKmh,
        'isEnabled': isEnabled,
        'explicitGroupTrustIndex': explicitGroupTrustIndex,
        'riders': riders
            .map((BreakawayRiderContributionEntry r) => r.toJson())
            .toList(growable: false),
      };

  /// Odtwarza model danych z mapy JSON.
  factory BreakawayCooperationTrustMeterData.fromJson(
    Map<String, dynamic> json,
  ) {
    final List<dynamic> rawRiders =
        (json['riders'] as List<dynamic>?) ?? const <dynamic>[];
    return BreakawayCooperationTrustMeterData(
      breakawayGroupName:
          (json['breakawayGroupName'] as String?) ?? 'Ucieczka dnia',
      gapToPelotonSeconds:
          (json['gapToPelotonSeconds'] as num?)?.toInt() ?? 0,
      distanceRemainingKm:
          (json['distanceRemainingKm'] as num?)?.toDouble() ?? 0.0,
      groupSpeedKmh: (json['groupSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      isEnabled: (json['isEnabled'] as bool?) ?? true,
      explicitGroupTrustIndex:
          (json['explicitGroupTrustIndex'] as num?)?.toDouble(),
      riders: rawRiders
          .whereType<Map<String, dynamic>>()
          .map(BreakawayRiderContributionEntry.fromJson)
          .toList(growable: false),
    );
  }
}

/// Wskaźnik współpracy grupy w ucieczce dnia (Breakaway Cooperation & Trust Meter HUD).
///
/// Prezentuje procentowy wkład każdego uciekiniera w prowadzenie, ogólny indeks
/// zaufania grupy, pasek proporcji zmian oraz ostrzeżenia dla pasażerów
/// unikających pracy (np. `Oszczędza siły!`). Obsługuje pełne stany interakcji
/// (`hover`, `active`, `disabled`, `focus`) i responsywność `390x844` / `1024x768` / `1600x900`.
class BreakawayCooperationTrustMeterHud extends StatefulWidget {
  /// Dane telemetryczne współpracy w ucieczce dnia.
  final BreakawayCooperationTrustMeterData data;

  /// Czy widget jest aktywny i interaktywny.
  final bool isEnabled;

  /// Czy karta jest domyślnie rozwinięta.
  final bool initiallyExpanded;

  /// Identyfikator aktualnie wyróżnionego uciekiniera.
  final String? selectedRiderId;

  /// Callback wywoływany po kliknięciu wiersza kolarza.
  final ValueChanged<BreakawayRiderContributionEntry>? onRiderTap;

  /// Callback wywoływany po kliknięciu przycisku wezwania kolarza do dawania zmian.
  final ValueChanged<BreakawayRiderContributionEntry>? onDemandPullTap;

  /// Callback zmiany stanu rozwinięcia/zwinięcia panelu.
  final ValueChanged<bool>? onToggleCollapse;

  /// Tworzy widget HUD wskaźnika współpracy ucieczki dnia.
  const BreakawayCooperationTrustMeterHud({
    super.key,
    required this.data,
    this.isEnabled = true,
    this.initiallyExpanded = true,
    this.selectedRiderId,
    this.onRiderTap,
    this.onDemandPullTap,
    this.onToggleCollapse,
  });

  @override
  State<BreakawayCooperationTrustMeterHud> createState() =>
      _BreakawayCooperationTrustMeterHudState();
}

class _BreakawayCooperationTrustMeterHudState
    extends State<BreakawayCooperationTrustMeterHud> {
  static const Duration _animDuration = Duration(milliseconds: 260);
  static const Curve _animCurve = Curves.easeOutCubic;

  late bool _isExpanded;
  BreakawayTrustMeterViewMode _viewMode =
      BreakawayTrustMeterViewMode.contributionShare;
  String? _hoveredRiderId;
  String? _pressedRiderId;
  String? _focusedRiderId;

  bool get _effectiveEnabled => widget.isEnabled && widget.data.isEnabled;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggleExpanded() {
    if (!_effectiveEnabled) return;
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onToggleCollapse?.call(_isExpanded);
  }

  void _setViewMode(BreakawayTrustMeterViewMode mode) {
    if (!_effectiveEnabled || _viewMode == mode) return;
    setState(() {
      _viewMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final BreakawayCooperationTrustMeterData data = widget.data;
    final BreakawayGroupHarmonyLevel harmony = _effectiveEnabled
        ? data.harmonyLevel
        : BreakawayGroupHarmonyLevel.disabled;
    final List<BreakawayRiderContributionEntry> riders = data.normalizedRiders;
    final double trustIndex =
        _effectiveEnabled ? data.resolvedGroupTrustIndex : 0.0;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 420.0;
        final bool isCompact = maxWidth < 460.0;
        final bool isWide = maxWidth >= 820.0;

        return AnimatedOpacity(
          duration: _animDuration,
          curve: _animCurve,
          opacity: _effectiveEnabled ? 1.0 : 0.62,
          child: AnimatedContainer(
            duration: _animDuration,
            curve: _animCurve,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _effectiveEnabled
                    ? harmony.color.withValues(alpha: 0.42)
                    : AppColors.cardBorder,
                width: 1.0,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.background.withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildHeader(
                      data: data,
                      harmony: harmony,
                      trustIndex: trustIndex,
                      riderCount: riders.length,
                      isCompact: isCompact,
                    ),
                    AnimatedCrossFade(
                      duration: _animDuration,
                      firstCurve: _animCurve,
                      secondCurve: _animCurve,
                      sizeCurve: _animCurve,
                      crossFadeState: _isExpanded
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const SizedBox(height: 12),
                          _buildTrustGaugeSection(
                            harmony: harmony,
                            trustIndex: trustIndex,
                            riders: riders,
                            isCompact: isCompact,
                          ),
                          const SizedBox(height: 12),
                          _buildToolbar(
                            riders: riders,
                            isCompact: isCompact,
                          ),
                          const SizedBox(height: 10),
                          if (riders.isEmpty)
                            _buildEmptyState()
                          else
                            _buildRidersList(
                              riders: riders,
                              isCompact: isCompact,
                              isWide: isWide,
                            ),
                          if (riders.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 10),
                            _buildSummaryTicker(
                              summary: data.summaryLine,
                              harmony: harmony,
                            ),
                          ],
                        ],
                      ),
                      secondChild: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required BreakawayCooperationTrustMeterData data,
    required BreakawayGroupHarmonyLevel harmony,
    required double trustIndex,
    required int riderCount,
    required bool isCompact,
  }) {
    final Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: harmony.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: harmony.color.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(harmony.icon, size: 14, color: harmony.color),
          const SizedBox(width: 5),
          Text(
            harmony.badgeLabel,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: harmony.color,
            ),
          ),
        ],
      ),
    );

    final Widget telemetryRow = Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _TelemetryChip(
          icon: Icons.timer_outlined,
          label: data.formattedGap,
          accentColor: AppColors.goldAccent,
        ),
        _TelemetryChip(
          icon: Icons.flag_outlined,
          label: '${data.safeDistanceRemainingKm.toStringAsFixed(1)} km',
          accentColor: AppColors.textSecondary,
        ),
        if (!isCompact)
          _TelemetryChip(
            icon: Icons.speed_rounded,
            label: '${data.safeGroupSpeedKmh.toStringAsFixed(1)} km/h',
            accentColor: AppColors.accentBlue,
          ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    '${data.breakawayGroupName} ($riderCount)',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  badge,
                ],
              ),
              const SizedBox(height: 6),
              telemetryRow,
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            _HudInteractiveIconButton(
              icon: _isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              tooltip: _isExpanded ? 'Zwiń wskaźnik' : 'Rozwiń wskaźnik',
              enabled: _effectiveEnabled,
              onPressed: _toggleExpanded,
            ),
            if (!_isExpanded) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'Zaufanie ${trustIndex.round()}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: harmony.color,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTrustGaugeSection({
    required BreakawayGroupHarmonyLevel harmony,
    required double trustIndex,
    required List<BreakawayRiderContributionEntry> riders,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Indeks zaufania i współpracy grupy',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TweenAnimationBuilder<double>(
                duration: _animDuration,
                curve: _animCurve,
                tween: Tween<double>(begin: trustIndex, end: trustIndex),
                builder: (BuildContext context, double value, Widget? child) {
                  return Text(
                    '${value.round()}%',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: harmony.color,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Container(color: AppColors.background),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (trustIndex / 100.0).clamp(0.0, 1.0),
                    child: AnimatedContainer(
                      duration: _animDuration,
                      curve: _animCurve,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            harmony.color.withValues(alpha: 0.75),
                            harmony.color,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            harmony.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: AppColors.textSecondary,
              letterSpacing: -0.1,
            ),
          ),
          if (riders.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            _buildStackedShareBar(riders),
          ],
        ],
      ),
    );
  }

  Widget _buildStackedShareBar(List<BreakawayRiderContributionEntry> riders) {
    double totalShare = 0.0;
    for (final BreakawayRiderContributionEntry r in riders) {
      totalShare += r.safeLeadSharePercent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Podział zmian na czele',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 10,
            child: totalShare <= 0.0
                ? Container(color: AppColors.background)
                : Row(
                    children: riders.map((BreakawayRiderContributionEntry r) {
                      final int flexValue =
                          math.max(1, (r.safeLeadSharePercent * 10).round());
                      return Expanded(
                        flex: flexValue,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 0.5),
                          color: r.jerseyColor,
                        ),
                      );
                    }).toList(growable: false),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar({
    required List<BreakawayRiderContributionEntry> riders,
    required bool isCompact,
  }) {
    final int fairSharePercent =
        riders.isEmpty ? 0 : (100 / riders.length).round();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          riders.length <= 1
              ? 'Norma rotacji: 100% (solo)'
              : 'Równa zmiana: ~$fairSharePercent% na kolarza',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: BreakawayTrustMeterViewMode.values
              .map((BreakawayTrustMeterViewMode mode) {
            final bool isSelected = _viewMode == mode;
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _HudModeChip(
                label: mode.label,
                icon: mode.icon,
                selected: isSelected,
                enabled: _effectiveEnabled,
                compact: isCompact,
                onTap: () => _setViewMode(mode),
              ),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: const Row(
        children: <Widget>[
          Icon(
            Icons.directions_bike_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Brak aktywnej ucieczki dnia — peleton jedzie razem.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRidersList({
    required List<BreakawayRiderContributionEntry> riders,
    required bool isCompact,
    required bool isWide,
  }) {
    final int groupSize = riders.length;

    if (isWide && riders.length >= 2) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          final double itemWidth = (box.maxWidth - 10) / 2;
          return Wrap(
            spacing: 10,
            runSpacing: 8,
            children: riders.map((BreakawayRiderContributionEntry rider) {
              return SizedBox(
                width: itemWidth,
                child: _buildRiderRow(
                  rider: rider,
                  groupSize: groupSize,
                  isCompact: isCompact,
                ),
              );
            }).toList(growable: false),
          );
        },
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: riders.map((BreakawayRiderContributionEntry rider) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildRiderRow(
            rider: rider,
            groupSize: groupSize,
            isCompact: isCompact,
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildRiderRow({
    required BreakawayRiderContributionEntry rider,
    required int groupSize,
    required bool isCompact,
  }) {
    final BreakawayRiderContributionStatus status =
        rider.resolveStatus(groupSize);
    final bool isSelected = widget.selectedRiderId == rider.riderId;
    final bool isHovered = _hoveredRiderId == rider.riderId;
    final bool isPressed = _pressedRiderId == rider.riderId;
    final bool isFocused = _focusedRiderId == rider.riderId;
    final double fairShare = groupSize > 0 ? 100.0 / groupSize : 100.0;

    Color borderColor = AppColors.cardBorder;
    if (isFocused) {
      borderColor = AppColors.goldAccent;
    } else if (isSelected) {
      borderColor = AppColors.accentBlue;
    } else if (isHovered && _effectiveEnabled) {
      borderColor = AppColors.textSecondary.withValues(alpha: 0.7);
    } else if (status.isUnderContributing && _effectiveEnabled) {
      borderColor = status.color.withValues(alpha: 0.5);
    }

    Color bgColor = AppColors.surfaceLight;
    if (isPressed && _effectiveEnabled) {
      bgColor = AppColors.cardBorder;
    } else if (isSelected) {
      bgColor = AppColors.accentBlue.withValues(alpha: 0.12);
    } else if (isHovered && _effectiveEnabled) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.85);
    }

    return FocusableActionDetector(
      enabled: _effectiveEnabled,
      onShowFocusHighlight: (bool focused) {
        setState(() {
          _focusedRiderId = focused ? rider.riderId : null;
        });
      },
      onShowHoverHighlight: (bool hovered) {
        setState(() {
          _hoveredRiderId = hovered ? rider.riderId : null;
        });
      },
      child: GestureDetector(
        onTapDown: _effectiveEnabled
            ? (_) => setState(() => _pressedRiderId = rider.riderId)
            : null,
        onTapUp: _effectiveEnabled
            ? (_) => setState(() => _pressedRiderId = null)
            : null,
        onTapCancel: _effectiveEnabled
            ? () => setState(() => _pressedRiderId = null)
            : null,
        onTap: _effectiveEnabled && widget.onRiderTap != null
            ? () => widget.onRiderTap!(rider)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: _animCurve,
          padding: EdgeInsets.all(isCompact ? 9 : 11),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isFocused || isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: rider.jerseyColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textPrimary.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            rider.riderName,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: rider.isPlayerRider
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: rider.isPlayerRider
                                  ? AppColors.goldAccent
                                  : AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          rider.teamShortCode,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (rider.isCurrentlyPulling) ...<Widget>[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.accentBlue.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'NA CZELE',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentBlue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _viewMode == BreakawayTrustMeterViewMode.contributionShare
                        ? '${rider.roundedLeadSharePercent}% zmian'
                        : '${rider.safeAvgPullWatts} W',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: status.isUnderContributing
                          ? status.color
                          : AppColors.textPrimary,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              _buildRiderProgressBar(
                rider: rider,
                status: status,
                fairShare: fairShare,
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(status.icon, size: 13, color: status.color),
                      const SizedBox(width: 4),
                      Text(
                        _viewMode ==
                                BreakawayTrustMeterViewMode.contributionShare
                            ? status.label
                            : 'Czas: ${_formatDuration(rider.safePullSeconds)} • Zaufanie ${rider.safeTrustScore.round()}%',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: status.isUnderContributing
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: status.isUnderContributing
                              ? status.color
                              : AppColors.textSecondary,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (status.isUnderContributing &&
                      widget.onDemandPullTap != null)
                    _DemandPullButton(
                      enabled: _effectiveEnabled,
                      onPressed: () => widget.onDemandPullTap!(rider),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiderProgressBar({
    required BreakawayRiderContributionEntry rider,
    required BreakawayRiderContributionStatus status,
    required double fairShare,
  }) {
    final double fraction =
        (rider.safeLeadSharePercent / 100.0).clamp(0.0, 1.0);
    final double fairFraction = (fairShare / 100.0).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double width = box.maxWidth;
        final double markerX = (width * fairFraction).clamp(2.0, width - 2.0);
        return SizedBox(
          height: 8,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    color: AppColors.background,
                    alignment: Alignment.centerLeft,
                    child: AnimatedFractionallySizedBox(
                      duration: _animDuration,
                      curve: _animCurve,
                      widthFactor: fraction,
                      child: Container(
                        decoration: BoxDecoration(
                          color: status.isUnderContributing
                              ? status.color
                              : rider.jerseyColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: markerX - 1,
                top: -1,
                bottom: -1,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryTicker({
    required String summary,
    required BreakawayGroupHarmonyLevel harmony,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: harmony.color.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.analytics_outlined,
            size: 14,
            color: harmony.color,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              summary,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final int mins = totalSeconds ~/ 60;
    final int secs = totalSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}

class _TelemetryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;

  const _TelemetryChip({
    required this.icon,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: accentColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accentColor,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _HudInteractiveIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  const _HudInteractiveIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_HudInteractiveIconButton> createState() =>
      _HudInteractiveIconButtonState();
}

class _HudInteractiveIconButtonState extends State<_HudInteractiveIconButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _pressed
            ? AppColors.cardBorder
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    final Color border = _focused
        ? AppColors.goldAccent
        : _hovered && widget.enabled
            ? AppColors.textSecondary
            : AppColors.cardBorder;

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowFocusHighlight: (bool v) => setState(() => _focused = v),
        onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
        child: GestureDetector(
          onTapDown: widget.enabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _pressed = false)
              : null,
          onTapCancel:
              widget.enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: border,
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: widget.enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _HudModeChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final bool compact;
  final VoidCallback onTap;

  const _HudModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_HudModeChip> createState() => _HudModeChipState();
}

class _HudModeChipState extends State<_HudModeChip> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    if (!widget.enabled) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.4);
    } else if (_pressed) {
      bgColor = AppColors.primaryAccent.withValues(alpha: 0.4);
    } else if (widget.selected) {
      bgColor = AppColors.primaryAccent.withValues(alpha: 0.26);
    } else if (_hovered) {
      bgColor = AppColors.surfaceLight;
    } else {
      bgColor = AppColors.background;
    }

    final Color borderColor = _focused
        ? AppColors.goldAccent
        : widget.selected && widget.enabled
            ? AppColors.primaryAccent
            : _hovered && widget.enabled
                ? AppColors.textSecondary
                : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 7 : 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                widget.icon,
                size: 13,
                color: widget.selected && widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight:
                      widget.selected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.selected && widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemandPullButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _DemandPullButton({
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_DemandPullButton> createState() => _DemandPullButtonState();
}

class _DemandPullButtonState extends State<_DemandPullButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = !widget.enabled
        ? AppColors.surface
        : _pressed
            ? AppColors.amberWarning.withValues(alpha: 0.35)
            : _hovered
                ? AppColors.amberWarning.withValues(alpha: 0.24)
                : AppColors.amberWarning.withValues(alpha: 0.14);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : AppColors.amberWarning.withValues(alpha: 0.65),
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.campaign_rounded,
                size: 12,
                color: AppColors.amberWarning,
              ),
              SizedBox(width: 4),
              Text(
                'Wymuś zmianę',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amberWarning,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
