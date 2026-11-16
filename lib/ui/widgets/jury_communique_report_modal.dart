import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/events/commissaire_jury_penalties_engine.dart';

/// Zakładka filtrowania sekcji oficjalnego komunikatu Kolegium Sędziów UCI.
enum JuryCommuniqueSectionTab {
  all,
  penalties,
  eliminations,
  combativity,
}

/// Rodzaj wykluczenia lub wycofania kolarza odnotowany w komunikacie po etapie.
enum JuryEliminationType {
  otl,
  dnf,
  dns,
  dsq;

  String toJson() => name;

  static JuryEliminationType fromJson(String value) {
    return JuryEliminationType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => JuryEliminationType.dnf,
    );
  }

  String get code {
    switch (this) {
      case JuryEliminationType.otl:
        return 'OTL';
      case JuryEliminationType.dnf:
        return 'DNF';
      case JuryEliminationType.dns:
        return 'DNS';
      case JuryEliminationType.dsq:
        return 'DSQ';
    }
  }

  String get labelPl {
    switch (this) {
      case JuryEliminationType.otl:
        return 'Poza limitem czasu (Hors Délai)';
      case JuryEliminationType.dnf:
        return 'Nie ukończył etapu (Abandon)';
      case JuryEliminationType.dns:
        return 'Nie wystartował (Non-Partant)';
      case JuryEliminationType.dsq:
        return 'Dyskwalifikacja (Mise hors course)';
    }
  }

  Color get badgeColor {
    switch (this) {
      case JuryEliminationType.otl:
        return AppColors.amberWarning;
      case JuryEliminationType.dnf:
        return AppColors.crimsonAlert;
      case JuryEliminationType.dns:
        return AppColors.textSecondary;
      case JuryEliminationType.dsq:
        return AppColors.crimsonAlert;
    }
  }
}

/// Wpis dotyczący wykluczenia OTL lub wycofania DNF/DNS/DSQ w komunikacie sędziowskim.
class JuryRiderStatusEntry {
  final String riderId;
  final String riderName;
  final String teamName;
  final String teamShortCode;
  final int bibNumber;
  final JuryEliminationType statusType;
  final double? kilometerMark;
  final int? overTimeLimitSeconds;
  final String reasonPl;
  final String reasonEn;
  final bool isPlayerTeam;

  const JuryRiderStatusEntry({
    required this.riderId,
    required this.riderName,
    required this.teamName,
    required this.teamShortCode,
    required this.bibNumber,
    required this.statusType,
    this.kilometerMark,
    this.overTimeLimitSeconds,
    required this.reasonPl,
    required this.reasonEn,
    this.isPlayerTeam = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'teamName': teamName,
      'teamShortCode': teamShortCode,
      'bibNumber': bibNumber,
      'statusType': statusType.toJson(),
      'kilometerMark': kilometerMark,
      'overTimeLimitSeconds': overTimeLimitSeconds,
      'reasonPl': reasonPl,
      'reasonEn': reasonEn,
      'isPlayerTeam': isPlayerTeam,
    };
  }

  factory JuryRiderStatusEntry.fromJson(Map<String, dynamic> json) {
    return JuryRiderStatusEntry(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      teamName: json['teamName'] as String,
      teamShortCode: json['teamShortCode'] as String? ?? 'TEAM',
      bibNumber: (json['bibNumber'] as num?)?.toInt() ?? 1,
      statusType: JuryEliminationType.fromJson(json['statusType'] as String),
      kilometerMark: (json['kilometerMark'] as num?)?.toDouble(),
      overTimeLimitSeconds: (json['overTimeLimitSeconds'] as num?)?.toInt(),
      reasonPl: json['reasonPl'] as String? ?? '',
      reasonEn: json['reasonEn'] as String? ?? '',
      isPlayerTeam: json['isPlayerTeam'] as bool? ?? false,
    );
  }
}

/// Laureat nagrody dla Najaktywniejszego Kolarza Etapu (Combativity Award — czerwony numer startowy).
class CombativityAwardWinner {
  final String riderId;
  final String riderName;
  final String teamName;
  final String teamShortCode;
  final int bibNumber;
  final double breakawayKilometers;
  final double longestSoloLeadKm;
  final int komPointsEarned;
  final int sprintPointsEarned;
  final double juryVotesShare;
  final String citationPl;
  final String citationEn;
  final bool isPlayerTeam;

  const CombativityAwardWinner({
    required this.riderId,
    required this.riderName,
    required this.teamName,
    required this.teamShortCode,
    required this.bibNumber,
    required this.breakawayKilometers,
    this.longestSoloLeadKm = 0.0,
    this.komPointsEarned = 0,
    this.sprintPointsEarned = 0,
    this.juryVotesShare = 0.75,
    required this.citationPl,
    required this.citationEn,
    this.isPlayerTeam = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'teamName': teamName,
      'teamShortCode': teamShortCode,
      'bibNumber': bibNumber,
      'breakawayKilometers': breakawayKilometers,
      'longestSoloLeadKm': longestSoloLeadKm,
      'komPointsEarned': komPointsEarned,
      'sprintPointsEarned': sprintPointsEarned,
      'juryVotesShare': juryVotesShare,
      'citationPl': citationPl,
      'citationEn': citationEn,
      'isPlayerTeam': isPlayerTeam,
    };
  }

  factory CombativityAwardWinner.fromJson(Map<String, dynamic> json) {
    return CombativityAwardWinner(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      teamName: json['teamName'] as String,
      teamShortCode: json['teamShortCode'] as String? ?? 'TEAM',
      bibNumber: (json['bibNumber'] as num?)?.toInt() ?? 1,
      breakawayKilometers: (json['breakawayKilometers'] as num).toDouble(),
      longestSoloLeadKm: (json['longestSoloLeadKm'] as num?)?.toDouble() ?? 0.0,
      komPointsEarned: (json['komPointsEarned'] as num?)?.toInt() ?? 0,
      sprintPointsEarned: (json['sprintPointsEarned'] as num?)?.toInt() ?? 0,
      juryVotesShare: (json['juryVotesShare'] as num?)?.toDouble() ?? 0.75,
      citationPl: json['citationPl'] as String? ?? '',
      citationEn: json['citationEn'] as String? ?? '',
      isPlayerTeam: json['isPlayerTeam'] as bool? ?? false,
    );
  }
}

/// Pełny zbiór danych oficjalnego komunikatu Kolegium Sędziów UCI wyświetlanego po etapie.
class JuryCommuniqueReportData {
  final String raceName;
  final int communiqueNumber;
  final int stageNumber;
  final String stageName;
  final String stageDateLabel;
  final double stageDistanceKm;
  final String winnerTimeFormatted;
  final String otlTimeLimitFormatted;
  final String presidentOfJury;
  final CommissaireStageCommunique stageCommunique;
  final List<JuryRiderStatusEntry> eliminations;
  final CombativityAwardWinner? combativityAward;
  final String? playerTeamName;

  const JuryCommuniqueReportData({
    required this.raceName,
    required this.communiqueNumber,
    required this.stageNumber,
    required this.stageName,
    required this.stageDateLabel,
    required this.stageDistanceKm,
    required this.winnerTimeFormatted,
    required this.otlTimeLimitFormatted,
    required this.presidentOfJury,
    required this.stageCommunique,
    required this.eliminations,
    this.combativityAward,
    this.playerTeamName,
  });

  List<JuryRiderStatusEntry> get otlEntries =>
      eliminations.where((e) => e.statusType == JuryEliminationType.otl).toList();

  List<JuryRiderStatusEntry> get dnfEntries => eliminations
      .where(
        (e) =>
            e.statusType == JuryEliminationType.dnf ||
            e.statusType == JuryEliminationType.dns ||
            e.statusType == JuryEliminationType.dsq,
      )
      .toList();

  int get totalPenaltiesCount => stageCommunique.decisions.length;
  int get totalFinesChf => stageCommunique.totalFinesChf;
  int get totalFinesEur => stageCommunique.totalFinesEur;

  bool get hasAnyIncidents =>
      stageCommunique.decisions.isNotEmpty || eliminations.isNotEmpty;

  /// Przykładowy komunikat pokazowy do podglądu lub testów UI.
  factory JuryCommuniqueReportData.sample({String? playerTeamName}) {
    final team = playerTeamName ?? 'Veloce Alpine Pro';
    final decisions = [
      CommissairePenaltyDecision(
        id: 'pen_1',
        riderId: 'r_104',
        riderName: 'Kacper Majewski',
        teamId: 'team_player',
        teamName: team,
        bibNumber: 42,
        infractionType: UciInfractionType.stickyBottle,
        severity: PenaltySeverity.minor,
        kilometerMark: 148.5,
        timePenaltySeconds: 20,
        relegateToBackOfGroup: false,
        disqualified: false,
        fineChf: 200,
        teamDirectorFineChf: 200,
        uciPointsPenalty: 0,
        yellowCardIssued: false,
        officialReasonPl:
            'Nadmiernie długie trzymanie bidonu przy wozie technicznym (6.2 s na podjeździe).',
        officialReasonEn:
            'Prolonged sticky bottle assistance from team car (6.2 s on climb).',
        uciArticleCode: UciInfractionType.stickyBottle.uciArticleCode,
      ),
      CommissairePenaltyDecision(
        id: 'pen_2',
        riderId: 'r_019',
        riderName: 'Matteo Bellini',
        teamId: 'team_italia',
        teamName: 'Scuderia Emilia',
        bibNumber: 19,
        infractionType: UciInfractionType.irregularSprint,
        severity: PenaltySeverity.major,
        kilometerMark: 186.2,
        timePenaltySeconds: 0,
        relegateToBackOfGroup: true,
        disqualified: false,
        fineChf: 500,
        teamDirectorFineChf: 0,
        pointsClassificationPenalty: 13,
        uciPointsPenalty: 15,
        yellowCardIssued: true,
        officialReasonPl:
            'Gwałtowne zajechanie toru jazdy rywalowi na ostatnich 150 m finiszu sprinterskiego.',
        officialReasonEn:
            'Deviating from chosen sprint line and endangering another rider in final 150 m.',
        uciArticleCode: UciInfractionType.irregularSprint.uciArticleCode,
      ),
    ];

    final communique = CommissaireStageCommunique(
      stageNumber: 14,
      stageName: 'Pau → Saint-Lary-Soulan (Pla d\'Adet)',
      decisions: decisions,
      totalTimePenaltiesSeconds: 20,
      totalFinesChf: 900,
      relegationsCount: 1,
      yellowCardsCount: 1,
      disqualificationsCount: 0,
      finesByTeamChf: {
        team: 400,
        'Scuderia Emilia': 500,
      },
    );

    return JuryCommuniqueReportData(
      raceName: 'Tour de France',
      communiqueNumber: 14,
      stageNumber: 14,
      stageName: 'Pau → Saint-Lary-Soulan (Pla d\'Adet)',
      stageDateLabel: 'Sobota, 19 lipca',
      stageDistanceKm: 151.9,
      winnerTimeFormatted: '4h 01\' 52"',
      otlTimeLimitFormatted: '+38\' 35" (16%)',
      presidentOfJury: 'Philippe Marien (BEL • UCI)',
      stageCommunique: communique,
      playerTeamName: team,
      eliminations: const [
        JuryRiderStatusEntry(
          riderId: 'r_177',
          riderName: 'Liam O\'Connor',
          teamName: 'Celtic Pro Cycling',
          teamShortCode: 'CPC',
          bibNumber: 177,
          statusType: JuryEliminationType.otl,
          overTimeLimitSeconds: 194,
          reasonPl: 'Przekroczony limit czasu o 3\' 14" na mecie szczytowej Pla d\'Adet.',
          reasonEn: 'Finished outside time limit (+3\' 14" over 16% cutoff).',
        ),
        JuryRiderStatusEntry(
          riderId: 'r_088',
          riderName: 'Julien Marchand',
          teamName: 'Bretagne Avenir',
          teamShortCode: 'BRE',
          bibNumber: 88,
          statusType: JuryEliminationType.dnf,
          kilometerMark: 94.0,
          reasonPl: 'Wycofanie po kraksie na zjeździe z Col du Tourmalet (podejrzenie urazu barku).',
          reasonEn: 'Abandoned following crash on Col du Tourmalet descent.',
        ),
      ],
      combativityAward: CombativityAwardWinner(
        riderId: 'r_042',
        riderName: 'Antoine Moreau',
        teamName: team,
        teamShortCode: 'VAP',
        bibNumber: 42,
        breakawayKilometers: 118.4,
        longestSoloLeadKm: 24.5,
        komPointsEarned: 32,
        sprintPointsEarned: 15,
        juryVotesShare: 0.72,
        citationPl:
            'Inicjator porannej ucieczki od 12. kilometra, samotny atak na Col de Peyresourde i walka o premię HC.',
        citationEn:
            'Instigator of the main breakaway from km 12, solo attack on Col de Peyresourde.',
        isPlayerTeam: true,
      ),
    );
  }
}

/// Oficjalny komunikat Kolegium Sędziów UCI wyświetlany po etapie w stylistyce dokumentu UCI.
class JuryCommuniqueReportModal extends StatefulWidget {
  final JuryCommuniqueReportData data;
  final VoidCallback? onClose;
  final ValueChanged<String>? onCopyProtocol;

  const JuryCommuniqueReportModal({
    super.key,
    required this.data,
    this.onClose,
    this.onCopyProtocol,
  });

  /// Otwiera modal oficjalnego komunikatu Kolegium Sędziów UCI.
  static Future<void> show(
    BuildContext context, {
    required JuryCommuniqueReportData data,
    ValueChanged<String>? onCopyProtocol,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (dialogContext) => JuryCommuniqueReportModal(
        data: data,
        onClose: () => Navigator.of(dialogContext).pop(),
        onCopyProtocol: onCopyProtocol,
      ),
    );
  }

  @override
  State<JuryCommuniqueReportModal> createState() =>
      _JuryCommuniqueReportModalState();
}

class _JuryCommuniqueReportModalState extends State<JuryCommuniqueReportModal>
    with SingleTickerProviderStateMixin {
  JuryCommuniqueSectionTab _activeTab = JuryCommuniqueSectionTab.all;
  bool _onlyPlayerTeam = false;
  String _searchQuery = '';
  bool _copiedRecently = false;
  late final TextEditingController _searchController;
  late final AnimationController _entryController;
  late final Animation<double> _entryFade;
  late final Animation<double> _entryScale;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _entryFade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _entryScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  bool _matchesFilter({
    required String riderName,
    required String teamName,
    required int bibNumber,
    String extra = '',
  }) {
    if (_onlyPlayerTeam && widget.data.playerTeamName != null) {
      final target = widget.data.playerTeamName!.toLowerCase();
      if (!teamName.toLowerCase().contains(target)) {
        return false;
      }
    }
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    return riderName.toLowerCase().contains(query) ||
        teamName.toLowerCase().contains(query) ||
        bibNumber.toString().contains(query) ||
        extra.toLowerCase().contains(query);
  }

  List<CommissairePenaltyDecision> get _filteredDecisions {
    return widget.data.stageCommunique.decisions.where((d) {
      return _matchesFilter(
        riderName: d.riderName,
        teamName: d.teamName,
        bibNumber: d.bibNumber,
        extra: '${d.infractionType.displayLabelPl} ${d.uciArticleCode} ${d.officialReasonPl}',
      );
    }).toList();
  }

  List<JuryRiderStatusEntry> get _filteredEliminations {
    return widget.data.eliminations.where((e) {
      return _matchesFilter(
        riderName: e.riderName,
        teamName: e.teamName,
        bibNumber: e.bibNumber,
        extra: '${e.statusType.code} ${e.reasonPl}',
      );
    }).toList();
  }

  bool get _showCombativityCard {
    final winner = widget.data.combativityAward;
    if (winner == null) return false;
    if (_activeTab != JuryCommuniqueSectionTab.all &&
        _activeTab != JuryCommuniqueSectionTab.combativity) {
      return false;
    }
    return _matchesFilter(
      riderName: winner.riderName,
      teamName: winner.teamName,
      bibNumber: winner.bibNumber,
      extra: '${winner.citationPl} combativity najaktywniejszy',
    );
  }

  String _buildPlainTextProtocol() {
    final d = widget.data;
    final buf = StringBuffer()
      ..writeln('============================================================')
      ..writeln('UNION CYCLISTE INTERNATIONALE — COLLÈGE DES COMMISSAIRES')
      ..writeln('COMMUNIQUÉ OFFICIEL N° ${d.communiqueNumber} | ${d.raceName}')
      ..writeln('Etap ${d.stageNumber}: ${d.stageName} (${d.stageDistanceKm.toStringAsFixed(1)} km)')
      ..writeln('Czas zwycięzcy: ${d.winnerTimeFormatted} | Limit OTL: ${d.otlTimeLimitFormatted}')
      ..writeln('============================================================')
      ..writeln();

    if (d.combativityAward != null) {
      final c = d.combativityAward!;
      buf
        ..writeln('[PRIX DE LA COMBATIVITÉ — CZERWONY NUMER STARTOWY]')
        ..writeln('  #${c.bibNumber} ${c.riderName} (${c.teamName})')
        ..writeln('  Ucieczka: ${c.breakawayKilometers.toStringAsFixed(1)} km | Solo: ${c.longestSoloLeadKm.toStringAsFixed(1)} km')
        ..writeln('  Uzasadnienie: ${c.citationPl}')
        ..writeln();
    }

    buf.writeln('[DECYZJE DYSCYPLINARNE I KARY UCI]');
    if (d.stageCommunique.decisions.isEmpty) {
      buf.writeln('  Brak nałożonych kar na tym etapie.');
    } else {
      for (final pen in d.stageCommunique.decisions) {
        final parts = <String>[];
        if (pen.timePenaltySeconds > 0) parts.add('+${pen.timePenaltySeconds}s');
        if (pen.relegateToBackOfGroup) parts.add('RELEGACJA');
        if (pen.disqualified) parts.add('DSQ');
        if (pen.yellowCardIssued) parts.add('ŻÓŁTA KARTKA');
        if (pen.totalFineChf > 0) parts.add('${pen.totalFineChf} CHF');
        buf.writeln(
          '  #${pen.bibNumber} ${pen.riderName} (${pen.teamName}) | km ${pen.kilometerMark.toStringAsFixed(1)} | ${pen.uciArticleCode} -> ${parts.join(', ')}',
        );
        buf.writeln('     ${pen.officialReasonPl}');
      }
    }
    buf.writeln();

    buf.writeln('[WYKLUCZENIA OTL / WYCOFANIA DNF & DNS]');
    if (d.eliminations.isEmpty) {
      buf.writeln('  Wszyscy startujący ukończyli etap w limicie czasu.');
    } else {
      for (final el in d.eliminations) {
        buf.writeln(
          '  [${el.statusType.code}] #${el.bibNumber} ${el.riderName} (${el.teamName}) — ${el.reasonPl}',
        );
      }
    }
    buf
      ..writeln()
      ..writeln('Przewodniczący Kolegium Sędziów: ${d.presidentOfJury}');
    return buf.toString();
  }

  Future<void> _copyProtocol() async {
    final text = _buildPlainTextProtocol();
    await Clipboard.setData(ClipboardData(text: text));
    widget.onCopyProtocol?.call(text);
    if (!mounted) return;
    setState(() => _copiedRecently = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copiedRecently = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handleClose,
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final isTablet =
                constraints.maxWidth >= 600 && constraints.maxWidth < 1100;

            final dialogPadding = isMobile
                ? const EdgeInsets.symmetric(horizontal: 10, vertical: 14)
                : const EdgeInsets.symmetric(horizontal: 24, vertical: 24);
            final maxWidth = isMobile
                ? constraints.maxWidth - 20
                : (isTablet ? 860.0 : 980.0);
            final maxHeight = constraints.maxHeight - (isMobile ? 28 : 48);

            return FadeTransition(
              opacity: _entryFade,
              child: ScaleTransition(
                scale: _entryScale,
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: dialogPadding,
                  elevation: 0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth,
                      maxHeight: maxHeight,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.borderColor,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 32,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildUciRainbowStrip(),
                          _buildOfficialHeader(isMobile),
                          Flexible(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(isMobile ? 12 : 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildSummaryKpiRow(isMobile),
                                  const SizedBox(height: 14),
                                  _buildFilterAndSearchBar(isMobile),
                                  const SizedBox(height: 16),
                                  if (_showCombativityCard) ...[
                                    _buildCombativitySection(isMobile),
                                    const SizedBox(height: 16),
                                  ],
                                  if (_activeTab ==
                                          JuryCommuniqueSectionTab.all ||
                                      _activeTab ==
                                          JuryCommuniqueSectionTab
                                              .penalties) ...[
                                    _buildPenaltiesSection(isMobile),
                                    const SizedBox(height: 16),
                                  ],
                                  if (_activeTab ==
                                          JuryCommuniqueSectionTab.all ||
                                      _activeTab ==
                                          JuryCommuniqueSectionTab
                                              .eliminations) ...[
                                    _buildEliminationsSection(isMobile),
                                    const SizedBox(height: 16),
                                  ],
                                  _buildOfficialSignOffFooter(isMobile),
                                ],
                              ),
                            ),
                          ),
                          _buildBottomActionBar(isMobile),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUciRainbowStrip() {
    const uciBands = [
      Color(0xFF38BDF8), // Niebieski UCI
      Color(0xFFEF4444), // Czerwony UCI
      Color(0xFF111827), // Czarny UCI
      Color(0xFFFACC15), // Żółty UCI
      Color(0xFF10B981), // Zielony UCI
    ];
    return SizedBox(
      height: 4,
      child: Row(
        children: uciBands
            .map((color) => Expanded(child: Container(color: color)))
            .toList(),
      ),
    );
  }

  Widget _buildOfficialHeader(bool isMobile) {
    final d = widget.data;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 22,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isMobile ? 40 : 48,
            height: isMobile ? 40 : 48,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.gavel_rounded,
              color: AppColors.goldAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldAccent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.goldAccent.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        'COMMUNIQUÉ OFFICIEL N° ${d.communiqueNumber}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                          color: AppColors.goldAccent,
                        ),
                      ),
                    ),
                    Text(
                      '${d.raceName.toUpperCase()} • ${d.stageDateLabel.toUpperCase()}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Komunikat Kolegium Sędziów — Etap ${d.stageNumber}: ${d.stageName}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isMobile ? 15 : 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    _HeaderMetaChip(
                      icon: Icons.straighten_rounded,
                      label: '${d.stageDistanceKm.toStringAsFixed(1)} km',
                    ),
                    _HeaderMetaChip(
                      icon: Icons.timer_outlined,
                      label: 'Zwycięzca: ${d.winnerTimeFormatted}',
                    ),
                    _HeaderMetaChip(
                      icon: Icons.hourglass_bottom_rounded,
                      label: 'Limit OTL: ${d.otlTimeLimitFormatted}',
                      highlightColor: AppColors.amberWarning,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _InteractiveIconButton(
            tooltip: 'Zamknij komunikat (Esc)',
            icon: Icons.close_rounded,
            onPressed: _handleClose,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryKpiRow(bool isMobile) {
    final d = widget.data;
    final otlCount = d.otlEntries.length;
    final dnfCount = d.dnfEntries.length;
    final combativity = d.combativityAward;

    final cards = [
      _KpiSummaryTile(
        label: 'KARY & GRZYWNY',
        value: '${d.totalPenaltiesCount}',
        subvalue: d.totalFinesChf > 0
            ? '${d.totalFinesChf} CHF (${d.totalFinesEur} €)'
            : 'Brak grzywien',
        accent: d.totalPenaltiesCount > 0
            ? AppColors.amberWarning
            : AppColors.statusSuccess,
        icon: Icons.policy_outlined,
      ),
      _KpiSummaryTile(
        label: 'POZA LIMITEM (OTL)',
        value: '$otlCount',
        subvalue: 'Limit ${d.otlTimeLimitFormatted}',
        accent: otlCount > 0 ? AppColors.amberWarning : AppColors.textSecondary,
        icon: Icons.timer_off_outlined,
      ),
      _KpiSummaryTile(
        label: 'WYCOFANIA (DNF/DSQ)',
        value: '$dnfCount',
        subvalue: dnfCount == 0 ? 'Pełny peleton na mecie' : 'Wykluczeni z wyścigu',
        accent: dnfCount > 0 ? AppColors.crimsonAlert : AppColors.statusSuccess,
        icon: Icons.person_off_outlined,
      ),
      _KpiSummaryTile(
        label: 'CZERWONY NUMER',
        value: combativity != null ? '#${combativity.bibNumber}' : '—',
        subvalue: combativity != null
            ? combativity.riderName
            : 'Nie przyznano',
        accent: AppColors.crimsonAlert,
        icon: Icons.local_fire_department_rounded,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 8),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 8),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _buildFilterAndSearchBar(bool isMobile) {
    final d = widget.data;
    final tabs = [
      (
        tab: JuryCommuniqueSectionTab.all,
        label: 'Pełny dokument',
      ),
      (
        tab: JuryCommuniqueSectionTab.penalties,
        label: 'Kary (${d.totalPenaltiesCount})',
      ),
      (
        tab: JuryCommuniqueSectionTab.eliminations,
        label: 'OTL / DNF (${d.eliminations.length})',
      ),
      (
        tab: JuryCommuniqueSectionTab.combativity,
        label: 'Najaktywniejszy',
      ),
    ];

    final tabStrip = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tabs.map((item) {
        final selected = _activeTab == item.tab;
        return _InteractiveFilterChip(
          label: item.label,
          selected: selected,
          onTap: () => setState(() => _activeTab = item.tab),
        );
      }).toList(),
    );

    final searchBox = SizedBox(
      width: isMobile ? double.infinity : 260,
      height: 38,
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Szukaj kolarza, ekipy, nr...',
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 17,
            color: AppColors.textSecondary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: 'Wyczyść wyszukiwanie',
                  icon: const Icon(
                    Icons.clear_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceLight,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.goldAccent, width: 1.4),
          ),
        ),
      ),
    );

    final playerTeamToggle = d.playerTeamName == null
        ? const SizedBox.shrink()
        : _InteractiveFilterChip(
            label: 'Tylko ${d.playerTeamName}',
            selected: _onlyPlayerTeam,
            accentColor: AppColors.goldAccent,
            icon: Icons.star_rounded,
            onTap: () => setState(() => _onlyPlayerTeam = !_onlyPlayerTeam),
          );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, filterConstraints) {
          if (isMobile || filterConstraints.maxWidth < 880) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                tabStrip,
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (d.playerTeamName != null) playerTeamToggle,
                    SizedBox(
                      width: isMobile ? double.infinity : 260,
                      child: searchBox,
                    ),
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: tabStrip),
              const SizedBox(width: 10),
              if (d.playerTeamName != null) ...[
                playerTeamToggle,
                const SizedBox(width: 10),
              ],
              searchBox,
            ],
          );
        },
      ),
    );
  }

  Widget _buildCombativitySection(bool isMobile) {
    final award = widget.data.combativityAward!;
    final votesPct = (award.juryVotesShare * 100).round();

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.crimsonAlert.withValues(alpha: 0.16),
            AppColors.surfaceLight,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.crimsonAlert.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.crimsonAlert,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'PRIX DE LA COMBATIVITÉ — NAJAKTYWNIEJSZY KOLARZ ETAPU',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.crimsonAlert,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.crimsonAlert,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'CZERWONY NUMER',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _RedDossardBadge(bibNumber: award.bibNumber),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCombativityIdentity(award)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCombativityStatsWrap(award, votesPct),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _RedDossardBadge(bibNumber: award.bibNumber),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: _buildCombativityIdentity(award)),
                const SizedBox(width: 16),
                Flexible(
                  flex: 2,
                  child: _buildCombativityStatsWrap(award, votesPct),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  award.citationPl,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (award.citationEn.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'UCI Citation: ${award.citationEn}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombativityIdentity(CombativityAwardWinner award) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              award.riderName,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (award.isPlayerTeam)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.6),
                  ),
                ),
                child: const Text(
                  'TWOJA EKIPA',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldAccent,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          '${award.teamName} (${award.teamShortCode}) • Prawo noszenia czerwonego numeru na kolejnym etapie',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCombativityStatsWrap(
    CombativityAwardWinner award,
    int votesPct,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MiniStatPill(
          label: 'W UCIECZCE',
          value: '${award.breakawayKilometers.toStringAsFixed(1)} km',
        ),
        if (award.longestSoloLeadKm > 0)
          _MiniStatPill(
            label: 'SOLO',
            value: '${award.longestSoloLeadKm.toStringAsFixed(1)} km',
          ),
        _MiniStatPill(
          label: 'KOM / SPR',
          value: '${award.komPointsEarned} / ${award.sprintPointsEarned} pkt',
        ),
        _MiniStatPill(
          label: 'GŁOSY JURY',
          value: '$votesPct%',
          highlightColor: AppColors.goldAccent,
        ),
      ],
    );
  }

  Widget _buildPenaltiesSection(bool isMobile) {
    final decisions = _filteredDecisions;
    final teamFines = widget.data.stageCommunique.finesByTeamChf;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitleHeader(
            icon: Icons.gavel_rounded,
            title: 'DECYZJE DYSCYPLINARNE I KARY REGULAMINOWE UCI',
            countBadge: '${decisions.length}',
            accent: decisions.isEmpty
                ? AppColors.statusSuccess
                : AppColors.amberWarning,
          ),
          const SizedBox(height: 12),
          if (decisions.isEmpty)
            _EmptyProtocolBox(
              icon: Icons.verified_outlined,
              message: _searchQuery.isNotEmpty || _onlyPlayerTeam
                  ? 'Brak kar spełniających aktywne kryteria filtrowania.'
                  : 'Kolegium Sędziów nie nałożyło żadnych kar czasowych ani finansowych na tym etapie.',
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: decisions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final decision = decisions[index];
                final isPlayer = widget.data.playerTeamName != null &&
                    decision.teamName.toLowerCase() ==
                        widget.data.playerTeamName!.toLowerCase();
                return _PenaltyDecisionRow(
                  decision: decision,
                  isPlayerTeam: isPlayer,
                  isMobile: isMobile,
                );
              },
            ),
            if (teamFines.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ZESTAWIENIE GRZYWIEN ZESPOŁOWYCH (CHF)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: teamFines.entries.map((entry) {
                        final eur = CommissaireJuryPenaltiesEngine.convertChfToEur(
                          entry.value,
                        );
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Text(
                            '${entry.key}: ${entry.value} CHF ($eur €)',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEliminationsSection(bool isMobile) {
    final entries = _filteredEliminations;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitleHeader(
            icon: Icons.timer_off_outlined,
            title: 'WYKLUCZENIA POZA LIMITEM (OTL) ORAZ WYCOFANIA (DNF / DNS)',
            countBadge: '${entries.length}',
            accent: entries.isEmpty
                ? AppColors.statusSuccess
                : AppColors.crimsonAlert,
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            _EmptyProtocolBox(
              icon: Icons.check_circle_outline_rounded,
              message: _searchQuery.isNotEmpty || _onlyPlayerTeam
                  ? 'Brak wykluczeń ani wycofań spełniających kryteria filtrowania.'
                  : 'Wszyscy kolarze wystartowali i ukończyli etap w regulaminowym limicie czasu.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _EliminationStatusRow(
                  entry: entries[index],
                  isMobile: isMobile,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOfficialSignOffFooter(bool isMobile) {
    final d = widget.data;
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSignatureText(d),
                const SizedBox(height: 10),
                const _UciVerifiedStamp(),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildSignatureText(d)),
                const SizedBox(width: 16),
                const _UciVerifiedStamp(),
              ],
            ),
    );
  }

  Widget _buildSignatureText(JuryCommuniqueReportData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'COLLÈGE DES COMMISSAIRES • PODPIS PROTOKOŁU',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Przewodniczący Jury: ${d.presidentOfJury}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Odwołania od decyzji finansowych i czasowych nie wstrzymują wykonania klasyfikacji etapu (Art. 2.12.007).',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(bool isMobile) {
    final copyBtn = _InteractiveActionButton(
      label: _copiedRecently ? 'Skopiowano protokół' : 'Kopiuj protokół UCI',
      icon: _copiedRecently
          ? Icons.check_rounded
          : Icons.content_copy_rounded,
      isPrimary: false,
      accentColor:
          _copiedRecently ? AppColors.statusSuccess : AppColors.textPrimary,
      onPressed: _copyProtocol,
    );
    final closeBtn = _InteractiveActionButton(
      label: 'Zamknij komunikat',
      icon: Icons.done_all_rounded,
      isPrimary: true,
      onPressed: _handleClose,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 22,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: isMobile
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [copyBtn, closeBtn],
            )
          : Row(
              children: [
                copyBtn,
                const Spacer(),
                closeBtn,
              ],
            ),
    );
  }
}

class _HeaderMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? highlightColor;

  const _HeaderMetaChip({
    required this.icon,
    required this.label,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlightColor ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiSummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final String subvalue;
  final Color accent;
  final IconData icon;

  const _KpiSummaryTile({
    required this.label,
    required this.value,
    required this.subvalue,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subvalue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RedDossardBadge extends StatelessWidget {
  final int bibNumber;

  const _RedDossardBadge({required this.bibNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.crimsonAlert,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.85),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimsonAlert.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'DOSSARD',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: Colors.white70,
            ),
          ),
          Text(
            '$bibNumber',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.05,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? highlightColor;

  const _MiniStatPill({
    required this.label,
    required this.value,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: highlightColor ?? AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitleHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String countBadge;
  final Color accent;

  const _SectionTitleHeader({
    required this.icon,
    required this.title,
    required this.countBadge,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Text(
            countBadge,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _PenaltyDecisionRow extends StatefulWidget {
  final CommissairePenaltyDecision decision;
  final bool isPlayerTeam;
  final bool isMobile;

  const _PenaltyDecisionRow({
    required this.decision,
    required this.isPlayerTeam,
    required this.isMobile,
  });

  @override
  State<_PenaltyDecisionRow> createState() => _PenaltyDecisionRowState();
}

class _PenaltyDecisionRowState extends State<_PenaltyDecisionRow> {
  bool _hovered = false;

  Color _severityColor(PenaltySeverity severity) {
    switch (severity) {
      case PenaltySeverity.warning:
        return AppColors.accentBlue;
      case PenaltySeverity.minor:
        return AppColors.amberWarning;
      case PenaltySeverity.major:
        return const Color(0xFFF97316);
      case PenaltySeverity.severe:
      case PenaltySeverity.disqualification:
        return AppColors.crimsonAlert;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.decision;
    final severityColor = _severityColor(d.severity);
    final borderColor = widget.isPlayerTeam
        ? AppColors.goldAccent.withValues(alpha: _hovered ? 0.9 : 0.6)
        : (_hovered
            ? AppColors.textSecondary.withValues(alpha: 0.5)
            : AppTheme.borderColor);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.surface.withValues(alpha: 0.95)
              : AppColors.background.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: widget.isPlayerTeam ? 1.3 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BibBadge(bibNumber: d.bibNumber, accent: severityColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            d.riderName,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '• ${d.teamName}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (widget.isPlayerTeam)
                            const _TagChip(
                              label: 'TWOJA EKIPA',
                              color: AppColors.goldAccent,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            d.infractionType.displayLabelPl,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: severityColor,
                            ),
                          ),
                          Text(
                            '${d.uciArticleCode} • km ${d.kilometerMark.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _TagChip(label: d.severity.labelPl, color: severityColor),
                if (d.timePenaltySeconds > 0)
                  _TagChip(
                    label: '+${d.timePenaltySeconds} s GC',
                    color: AppColors.amberWarning,
                  ),
                if (d.relegateToBackOfGroup)
                  const _TagChip(
                    label: 'RELEGACJA NA KONIEC GRUPY',
                    color: Color(0xFFF97316),
                  ),
                if (d.disqualified)
                  const _TagChip(
                    label: 'DSQ — WYKLUCZENIE',
                    color: AppColors.crimsonAlert,
                  ),
                if (d.yellowCardIssued)
                  const _TagChip(
                    label: 'ŻÓŁTA KARTKA UCI',
                    color: Color(0xFFFACC15),
                  ),
                if (d.pointsClassificationPenalty > 0)
                  _TagChip(
                    label: '-${d.pointsClassificationPenalty} pkt Zielona',
                    color: AppColors.statusSuccess,
                  ),
                if (d.uciPointsPenalty > 0)
                  _TagChip(
                    label: '-${d.uciPointsPenalty} pkt UCI',
                    color: AppColors.accentBlue,
                  ),
                if (d.totalFineChf > 0)
                  _TagChip(
                    label: '${d.totalFineChf} CHF (${d.fineEurEquivalent} €)',
                    color: AppColors.textPrimary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              d.officialReasonPl,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EliminationStatusRow extends StatefulWidget {
  final JuryRiderStatusEntry entry;
  final bool isMobile;

  const _EliminationStatusRow({
    required this.entry,
    required this.isMobile,
  });

  @override
  State<_EliminationStatusRow> createState() => _EliminationStatusRowState();
}

class _EliminationStatusRowState extends State<_EliminationStatusRow> {
  bool _hovered = false;

  String _formatOverLimit(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '+$mins\' ${secs.toString().padLeft(2, '0')}" ponad limit';
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final badgeColor = e.statusType.badgeColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.surface.withValues(alpha: 0.95)
              : AppColors.background.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: e.isPlayerTeam
                ? AppColors.goldAccent.withValues(alpha: 0.7)
                : AppTheme.borderColor,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BibBadge(bibNumber: e.bibNumber, accent: badgeColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _TagChip(label: e.statusType.code, color: badgeColor),
                      Text(
                        e.riderName,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${e.teamName} (${e.teamShortCode})',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (e.overTimeLimitSeconds != null)
                        _TagChip(
                          label: _formatOverLimit(e.overTimeLimitSeconds!),
                          color: AppColors.amberWarning,
                        ),
                      if (e.kilometerMark != null)
                        _TagChip(
                          label: 'km ${e.kilometerMark!.toStringAsFixed(1)}',
                          color: AppColors.textSecondary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    e.reasonPl,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BibBadge extends StatelessWidget {
  final int bibNumber;
  final Color accent;

  const _BibBadge({required this.bibNumber, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Text(
        '#$bibNumber',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: accent,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _EmptyProtocolBox extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyProtocolBox({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.statusSuccess),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UciVerifiedStamp extends StatelessWidget {
  const _UciVerifiedStamp();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.statusSuccess.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.statusSuccess.withValues(alpha: 0.5),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 16,
            color: AppColors.statusSuccess,
          ),
          SizedBox(width: 6),
          Text(
            'OFICJALNY DOKUMENT UCI',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: AppColors.statusSuccess,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? accentColor;
  final IconData? icon;

  const _InteractiveFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accentColor,
    this.icon,
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
    final accent = widget.accentColor ?? AppColors.primaryAccent;
    final bgColor = widget.selected
        ? accent.withValues(alpha: _pressed ? 0.34 : (_hovered ? 0.28 : 0.22))
        : (_hovered ? AppColors.surfaceLight : AppColors.surface);
    final borderColor = _focused
        ? AppColors.goldAccent
        : (widget.selected
            ? accent
            : (_hovered
                ? AppColors.textSecondary.withValues(alpha: 0.5)
                : AppTheme.borderColor));

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: _focused || widget.selected ? 1.3 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 14,
                  color: widget.selected ? accent : AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _InteractiveIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_InteractiveIconButton> createState() => _InteractiveIconButtonState();
}

class _InteractiveIconButtonState extends State<_InteractiveIconButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        mouseCursor: SystemMouseCursors.click,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _pressed
                  ? AppColors.surfaceLight
                  : (_hovered
                      ? AppColors.surfaceLight.withValues(alpha: 0.85)
                      : AppColors.surface),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : (_hovered
                        ? AppColors.textSecondary.withValues(alpha: 0.6)
                        : AppTheme.borderColor),
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: AppColors.textPrimary,
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
  final bool isPrimary;
  final VoidCallback? onPressed;
  final Color? accentColor;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onPressed,
    this.accentColor,
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
    final disabled = widget.onPressed == null;
    final baseColor = widget.isPrimary
        ? AppColors.primaryAccent
        : AppColors.surfaceLight;
    final bgColor = disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : (_pressed
            ? baseColor.withValues(alpha: 0.85)
            : (_hovered
                ? (widget.isPrimary
                    ? AppColors.primaryAccent.withValues(alpha: 0.9)
                    : AppColors.surfaceLight)
                : baseColor));
    final borderColor = disabled
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : (_focused
            ? AppColors.goldAccent
            : (widget.isPrimary
                ? AppColors.goldAccent.withValues(alpha: _hovered ? 0.85 : 0.45)
                : (_hovered
                    ? AppColors.textSecondary.withValues(alpha: 0.6)
                    : AppTheme.borderColor)));
    final fgColor = disabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : (widget.isPrimary
            ? AppColors.textPrimary
            : (widget.accentColor ?? AppColors.textPrimary));

    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: fgColor),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
