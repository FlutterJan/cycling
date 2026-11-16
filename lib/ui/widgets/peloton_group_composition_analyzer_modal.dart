import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/peloton/drafting_grid_system.dart';
import '../../engine/peloton/rider_race_state.dart';

/// Kryterium sortowania listy kolarzy w analizatorze grupy.
enum GroupRiderSortBy {
  frontPosition('Pozycja'),
  powerWatts('Moc (W)'),
  speedKmh('Prędkość'),
  fatigue('Zmęczenie'),
  gcGap('Strata GC');

  final String label;
  const GroupRiderSortBy(this.label);
}

/// Dane pojedynczego kolarza znajdującego się w analizowanej grupie na trasie.
class PelotonGroupRiderEntry {
  final String riderId;
  final String riderName;
  final int bibNumber;
  final String teamCode;
  final String teamName;
  final String teamColorHex;
  final String? nationalityCode;
  final bool isPlayerTeam;
  final bool isPullingFront;
  final double pullSharePercent;
  final double currentSpeedKmh;
  final int currentWatts;
  final double wattsPerKg;
  final int heartRateBpm;
  final double fatiguePercent;
  final TacticalOrder tacticalOrder;
  final double? gcGapSeconds;
  final String? roleLabel;

  const PelotonGroupRiderEntry({
    required this.riderId,
    required this.riderName,
    required this.bibNumber,
    required this.teamCode,
    required this.teamName,
    required this.teamColorHex,
    this.nationalityCode,
    this.isPlayerTeam = false,
    this.isPullingFront = false,
    this.pullSharePercent = 0.0,
    required this.currentSpeedKmh,
    required this.currentWatts,
    required this.wattsPerKg,
    required this.heartRateBpm,
    required this.fatiguePercent,
    this.tacticalOrder = TacticalOrder.holdPosition,
    this.gcGapSeconds,
    this.roleLabel,
  });

  Color get teamColor => _parseHexColor(teamColorHex);
}

/// Procentowy udział pojedynczej drużyny w składzie analizowanej grupy.
class TeamCompositionShare {
  final String teamCode;
  final String teamName;
  final Color teamColor;
  final int riderCount;
  final double sharePercent;
  final bool isPlayerTeam;
  final int pullingRidersCount;

  const TeamCompositionShare({
    required this.teamCode,
    required this.teamName,
    required this.teamColor,
    required this.riderCount,
    required this.sharePercent,
    required this.isPlayerTeam,
    required this.pullingRidersCount,
  });
}

/// Pełny pakiet danych telemetrycznych i składowych dla analizowanej grupy na trasie.
class PelotonGroupCompositionData {
  final String groupId;
  final String groupTitle;
  final GroupType groupType;
  final double gapToLeaderSeconds;
  final double avgSpeedLast5KmKmh;
  final double currentSpeedKmh;
  final double? speedDeltaVsPelotonKmh;
  final List<double> last5KmSpeedSamplesKmh;
  final double distanceRemainingKm;
  final double gradientPercent;
  final List<PelotonGroupRiderEntry> riders;

  const PelotonGroupCompositionData({
    required this.groupId,
    required this.groupTitle,
    required this.groupType,
    required this.gapToLeaderSeconds,
    required this.avgSpeedLast5KmKmh,
    required this.currentSpeedKmh,
    this.speedDeltaVsPelotonKmh,
    this.last5KmSpeedSamplesKmh = const [],
    required this.distanceRemainingKm,
    this.gradientPercent = 0.0,
    required this.riders,
  });
}

/// Czysta logika obliczeniowa dla analizy składu drużynowego, pacemakera i prędkości grupy.
class PelotonGroupCompositionAnalyzer {
  PelotonGroupCompositionAnalyzer._();

  /// Wylicza procentowy udział każdej drużyny w grupie, posortowany malejąco wg liczebności.
  static List<TeamCompositionShare> computeTeamShares(
    List<PelotonGroupRiderEntry> riders,
  ) {
    if (riders.isEmpty) {
      return const [];
    }

    final Map<String, List<PelotonGroupRiderEntry>> grouped = {};
    for (final rider in riders) {
      final key = rider.teamCode.trim().isEmpty ? 'UNK' : rider.teamCode.trim();
      grouped.putIfAbsent(key, () => []).add(rider);
    }

    final int total = riders.length;
    final List<TeamCompositionShare> shares = grouped.entries.map((entry) {
      final list = entry.value;
      final first = list.first;
      final pullingCount = list.where((r) => r.isPullingFront).length;
      final hasPlayer = list.any((r) => r.isPlayerTeam);
      return TeamCompositionShare(
        teamCode: entry.key,
        teamName: first.teamName,
        teamColor: first.teamColor,
        riderCount: list.length,
        sharePercent: (list.length / total) * 100.0,
        isPlayerTeam: hasPlayer,
        pullingRidersCount: pullingCount,
      );
    }).toList();

    shares.sort((a, b) {
      final countCmp = b.riderCount.compareTo(a.riderCount);
      if (countCmp != 0) return countCmp;
      if (a.isPlayerTeam != b.isPlayerTeam) {
        return a.isPlayerTeam ? -1 : 1;
      }
      return a.teamCode.compareTo(b.teamCode);
    });

    return shares;
  }

  /// Formatuje zwięzły opis składu w stylu: "UAE: 4 kolarzy, Visma: 3 kolarzy".
  static String formatTeamSummaryLine(
    List<TeamCompositionShare> shares, {
    int maxTeams = 4,
  }) {
    if (shares.isEmpty) {
      return 'Brak kolarzy w grupie';
    }
    final visible = shares.take(maxTeams).map((share) {
      return '${share.teamCode}: ${share.riderCount} ${_pluralizeRiders(share.riderCount)}';
    }).toList();

    if (shares.length > maxTeams) {
      final remainingTeams = shares.length - maxTeams;
      visible.add('+$remainingTeams ${_pluralizeTeams(remainingTeams)}');
    }
    return visible.join(', ');
  }

  /// Zwraca listę kolarzy aktualnie ciągnących grupę na czele.
  static List<PelotonGroupRiderEntry> resolveFrontPullers(
    List<PelotonGroupRiderEntry> riders,
  ) {
    final explicit = riders.where((r) => r.isPullingFront).toList();
    if (explicit.isNotEmpty) {
      explicit.sort((a, b) => b.pullSharePercent.compareTo(a.pullSharePercent));
      return explicit;
    }

    final orderPullers = riders
        .where((r) => r.tacticalOrder == TacticalOrder.pullGroup)
        .toList();
    orderPullers.sort(
      (a, b) => b.pullSharePercent.compareTo(a.pullSharePercent),
    );
    return orderPullers;
  }

  /// Wyznacza średnią prędkość z ostatnich 5 km (z fallbackiem na próbki lub prędkość chwilową).
  static double computeAverageSpeedLast5Km(PelotonGroupCompositionData data) {
    if (data.avgSpeedLast5KmKmh > 0.0) {
      return data.avgSpeedLast5KmKmh;
    }
    final validSamples =
        data.last5KmSpeedSamplesKmh.where((s) => s > 0.0).toList();
    if (validSamples.isNotEmpty) {
      final sum = validSamples.fold<double>(0.0, (acc, v) => acc + v);
      return sum / validSamples.length;
    }
    return math.max(0.0, data.currentSpeedKmh);
  }

  static String _pluralizeRiders(int count) {
    if (count == 1) return 'kolarz';
    return 'kolarzy';
  }

  static String _pluralizeTeams(int count) {
    if (count == 1) return 'ekipa';
    if (count >= 2 && count <= 4) return 'ekipy';
    return 'ekip';
  }
}

/// Modal analityczny składu grupy na trasie otwierany po kliknięciu grupy (Zadanie #225).
///
/// Prezentuje listę wszystkich kolarzy w grupie, procentowy udział drużyn
/// (np. "UAE: 4 kolarzy, Visma: 3 kolarzy"), średnią prędkość z ostatnich 5 km
/// oraz kolarzy aktualnie ciągnących grupę na czele.
class PelotonGroupCompositionAnalyzerModal extends StatefulWidget {
  final PelotonGroupCompositionData groupData;
  final ValueChanged<PelotonGroupRiderEntry>? onSelectRider;
  final VoidCallback? onFocusGroupIn3d;
  final VoidCallback? onClose;

  const PelotonGroupCompositionAnalyzerModal({
    super.key,
    required this.groupData,
    this.onSelectRider,
    this.onFocusGroupIn3d,
    this.onClose,
  });

  /// Otwiera [PelotonGroupCompositionAnalyzerModal] z efektem glassmorfizmu i animacją wejścia.
  static Future<void> show(
    BuildContext context, {
    required PelotonGroupCompositionData groupData,
    ValueChanged<PelotonGroupRiderEntry>? onSelectRider,
    VoidCallback? onFocusGroupIn3d,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Zamknij analizator składu grupy',
      barrierColor: Colors.black.withValues(alpha: 0.68),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1120,
                maxHeight: 860,
              ),
              child: Material(
                color: Colors.transparent,
                child: PelotonGroupCompositionAnalyzerModal(
                  groupData: groupData,
                  onSelectRider: onSelectRider,
                  onFocusGroupIn3d: onFocusGroupIn3d,
                  onClose: () => Navigator.of(dialogContext).maybePop(),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<PelotonGroupCompositionAnalyzerModal> createState() =>
      _PelotonGroupCompositionAnalyzerModalState();
}

class _PelotonGroupCompositionAnalyzerModalState
    extends State<PelotonGroupCompositionAnalyzerModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedTeamCode;
  bool _onlyPlayerTeam = false;
  GroupRiderSortBy _sortBy = GroupRiderSortBy.frontPosition;
  bool _sortAscending = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _toggleTeamFilter(String? teamCode) {
    setState(() {
      if (_selectedTeamCode == teamCode) {
        _selectedTeamCode = null;
      } else {
        _selectedTeamCode = teamCode;
        _onlyPlayerTeam = false;
      }
    });
  }

  void _selectSort(GroupRiderSortBy sort) {
    setState(() {
      if (_sortBy == sort) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sort;
        _sortAscending = sort == GroupRiderSortBy.gcGap;
      }
    });
  }

  List<PelotonGroupRiderEntry> _buildFilteredAndSortedRiders() {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = widget.groupData.riders.where((rider) {
      if (_onlyPlayerTeam && !rider.isPlayerTeam) {
        return false;
      }
      if (_selectedTeamCode != null && rider.teamCode != _selectedTeamCode) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchName = rider.riderName.toLowerCase().contains(query);
        final matchTeam = rider.teamCode.toLowerCase().contains(query) ||
            rider.teamName.toLowerCase().contains(query);
        final matchBib = rider.bibNumber.toString().contains(query);
        if (!matchName && !matchTeam && !matchBib) {
          return false;
        }
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case GroupRiderSortBy.frontPosition:
          if (a.isPullingFront != b.isPullingFront) {
            cmp = a.isPullingFront ? 1 : -1;
          } else {
            cmp = a.pullSharePercent.compareTo(b.pullSharePercent);
            if (cmp == 0) {
              cmp = a.currentWatts.compareTo(b.currentWatts);
            }
          }
        case GroupRiderSortBy.powerWatts:
          cmp = a.currentWatts.compareTo(b.currentWatts);
        case GroupRiderSortBy.speedKmh:
          cmp = a.currentSpeedKmh.compareTo(b.currentSpeedKmh);
        case GroupRiderSortBy.fatigue:
          cmp = a.fatiguePercent.compareTo(b.fatiguePercent);
        case GroupRiderSortBy.gcGap:
          final aGap = a.gcGapSeconds ?? double.infinity;
          final bGap = b.gcGapSeconds ?? double.infinity;
          cmp = aGap.compareTo(bGap);
      }
      return _sortAscending ? cmp : -cmp;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final shares = PelotonGroupCompositionAnalyzer.computeTeamShares(
      widget.groupData.riders,
    );
    final pullers = PelotonGroupCompositionAnalyzer.resolveFrontPullers(
      widget.groupData.riders,
    );
    final avg5Km = PelotonGroupCompositionAnalyzer.computeAverageSpeedLast5Km(
      widget.groupData,
    );
    final filteredRiders = _buildFilteredAndSortedRiders();
    final hasPlayerRiders =
        widget.groupData.riders.any((r) => r.isPlayerTeam);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handleClose,
      },
      child: Focus(
        autofocus: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 640;
                  final isTablet =
                      constraints.maxWidth >= 640 && constraints.maxWidth < 1020;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(isMobile),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppTheme.borderColor,
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(isMobile ? 12 : 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildKpiSection(
                                isMobile: isMobile,
                                isTablet: isTablet,
                                shares: shares,
                                pullers: pullers,
                                avgSpeed5Km: avg5Km,
                              ),
                              const SizedBox(height: 16),
                              _buildTeamCompositionCard(
                                shares: shares,
                                isMobile: isMobile,
                              ),
                              const SizedBox(height: 16),
                              _buildRidersListCard(
                                riders: filteredRiders,
                                totalRidersCount:
                                    widget.groupData.riders.length,
                                hasPlayerRiders: hasPlayerRiders,
                                isMobile: isMobile,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final badge = _groupTypeBadgeData(widget.groupData.groupType);
    final gapLabel = widget.groupData.gapToLeaderSeconds <= 0.5
        ? 'Czoło wyścigu'
        : '+${_formatGapSeconds(widget.groupData.gapToLeaderSeconds)} do lidera';
    final grad = widget.groupData.gradientPercent;
    final gradLabel = grad.abs() < 0.3
        ? 'Płasko'
        : '${grad >= 0 ? '+' : ''}${grad.toStringAsFixed(1)}%';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 12 : 16,
      ),
      color: AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isMobile ? 38 : 44,
            height: isMobile ? 38 : 44,
            decoration: BoxDecoration(
              color: badge.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: badge.color.withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            child: Icon(badge.icon, color: badge.color, size: isMobile ? 20 : 22),
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
                    Text(
                      widget.groupData.groupTitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 16 : 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badge.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: badge.color.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        badge.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badge.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _HeaderMetaChip(
                      icon: Icons.groups_rounded,
                      text:
                          '${widget.groupData.riders.length} ${PelotonGroupCompositionAnalyzer._pluralizeRiders(widget.groupData.riders.length)}',
                    ),
                    _HeaderMetaChip(
                      icon: Icons.timer_outlined,
                      text: gapLabel,
                    ),
                    _HeaderMetaChip(
                      icon: Icons.flag_outlined,
                      text:
                          'Meta: ${widget.groupData.distanceRemainingKm.toStringAsFixed(1)} km ($gradLabel)',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isMobile && widget.onFocusGroupIn3d != null) ...[
            const SizedBox(width: 8),
            _InteractiveActionButton(
              icon: Icons.videocam_outlined,
              label: 'Kamera 3D',
              accentColor: AppColors.goldAccent,
              onPressed: widget.onFocusGroupIn3d,
            ),
          ],
          const SizedBox(width: 8),
          _InteractiveIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Zamknij (Esc)',
            onPressed: _handleClose,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSection({
    required bool isMobile,
    required bool isTablet,
    required List<TeamCompositionShare> shares,
    required List<PelotonGroupRiderEntry> pullers,
    required double avgSpeed5Km,
  }) {
    final frontCard = _buildFrontPullerKpiCard(pullers);
    final speedCard = _buildSpeedLast5KmKpiCard(avgSpeed5Km);
    final summaryCard = _buildTeamDominanceKpiCard(shares);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          frontCard,
          const SizedBox(height: 12),
          speedCard,
          const SizedBox(height: 12),
          summaryCard,
        ],
      );
    }

    if (isTablet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: frontCard),
              const SizedBox(width: 12),
              Expanded(child: speedCard),
            ],
          ),
          const SizedBox(height: 12),
          summaryCard,
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 4, child: frontCard),
          const SizedBox(width: 12),
          Expanded(flex: 4, child: speedCard),
          const SizedBox(width: 12),
          Expanded(flex: 4, child: summaryCard),
        ],
      ),
    );
  }

  Widget _buildFrontPullerKpiCard(List<PelotonGroupRiderEntry> pullers) {
    final primaryPuller = pullers.isNotEmpty ? pullers.first : null;
    final secondaryPuller = pullers.length > 1 ? pullers[1] : null;

    return _AnalyzerCard(
      borderColor: primaryPuller != null
          ? AppColors.goldAccent.withValues(alpha: 0.45)
          : AppTheme.borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.air_rounded,
                size: 16,
                color: AppColors.goldAccent,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'AKTUALNIE CIĄGNIE NA CZELE',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (pullers.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${pullers.length} na zmianie',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (primaryPuller == null)
            const Text(
              'Brak aktywnego pacemakera — jazda pasywna / na kole',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            _PullerHighlightRow(
              rider: primaryPuller,
              onTap: widget.onSelectRider != null
                  ? () => widget.onSelectRider!(primaryPuller)
                  : null,
            ),
            if (secondaryPuller != null) ...[
              const SizedBox(height: 8),
              _PullerHighlightRow(
                rider: secondaryPuller,
                isSecondary: true,
                onTap: widget.onSelectRider != null
                    ? () => widget.onSelectRider!(secondaryPuller)
                    : null,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSpeedLast5KmKpiCard(double avgSpeed5Km) {
    final current = widget.groupData.currentSpeedKmh;
    final diff = current - avgSpeed5Km;
    final diffColor = diff >= 1.0
        ? AppColors.statusSuccess
        : (diff <= -1.0 ? AppColors.crimsonAlert : AppColors.textSecondary);
    final diffPrefix = diff >= 0 ? '+' : '';

    return _AnalyzerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.speed_rounded,
                size: 16,
                color: AppColors.accentBlue,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'ŚREDNIA PRĘDKOŚĆ (OSTATNIE 5 KM)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    avgSpeed5Km.toStringAsFixed(1),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'km/h',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Teraz: ${current.toStringAsFixed(1)} km/h',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    '$diffPrefix${diff.toStringAsFixed(1)} km/h vs 5 km',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: diffColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: CustomPaint(
              painter: _Last5KmSpeedSparklinePainter(
                samples: widget.groupData.last5KmSpeedSamplesKmh.isNotEmpty
                    ? widget.groupData.last5KmSpeedSamplesKmh
                    : [avgSpeed5Km, current],
                averageSpeed: avgSpeed5Km,
              ),
              size: const Size(double.infinity, 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamDominanceKpiCard(List<TeamCompositionShare> shares) {
    final summaryText = PelotonGroupCompositionAnalyzer.formatTeamSummaryLine(
      shares,
      maxTeams: 3,
    );
    final topShare = shares.isNotEmpty ? shares.first : null;

    return _AnalyzerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pie_chart_outline_rounded,
                size: 16,
                color: AppColors.primaryAccent,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'DOMINACJA DRUŻYNOWA',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '${shares.length} ${PelotonGroupCompositionAnalyzer._pluralizeTeams(shares.length)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summaryText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          if (topShare != null) ...[
            const SizedBox(height: 8),
            Text(
              'Najliczniejsza ekipa: ${topShare.teamName} (${topShare.sharePercent.toStringAsFixed(1)}%)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamCompositionCard({
    required List<TeamCompositionShare> shares,
    required bool isMobile,
  }) {
    return _AnalyzerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Procentowy udział drużyn w grupie',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (_selectedTeamCode != null)
                TextButton(
                  onPressed: () => _toggleTeamFilter(null),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.goldAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Wyczyść filtr ekipy',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (shares.isEmpty)
            const Text(
              'Brak danych o drużynach w tej grupie.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: shares.map((share) {
                    final isSelected = _selectedTeamCode == null ||
                        _selectedTeamCode == share.teamCode;
                    return Expanded(
                      flex: math.max(1, (share.sharePercent * 10).round()),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        opacity: isSelected ? 1.0 : 0.28,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 0.5),
                          color: share.teamColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: shares.map((share) {
                final selected = _selectedTeamCode == share.teamCode;
                return _TeamShareChip(
                  share: share,
                  isSelected: selected,
                  compact: isMobile,
                  onTap: () => _toggleTeamFilter(share.teamCode),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRidersListCard({
    required List<PelotonGroupRiderEntry> riders,
    required int totalRidersCount,
    required bool hasPlayerRiders,
    required bool isMobile,
  }) {
    return _AnalyzerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Kolarze w grupie (${riders.length}/$totalRidersCount)',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(
                width: isMobile ? double.infinity : 240,
                height: 36,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Szukaj kolarza lub ekipy...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              size: 15,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            padding: EdgeInsets.zero,
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
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
                      borderSide: const BorderSide(color: AppColors.goldAccent),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...GroupRiderSortBy.values.map((sort) {
                final active = _sortBy == sort;
                return _SortFilterChip(
                  label: sort.label,
                  isActive: active,
                  ascending: _sortAscending,
                  onTap: () => _selectSort(sort),
                );
              }),
              _ToggleFilterChip(
                label: 'Tylko moi',
                isSelected: _onlyPlayerTeam,
                enabled: hasPlayerRiders,
                onTap: hasPlayerRiders
                    ? () => setState(() {
                          _onlyPlayerTeam = !_onlyPlayerTeam;
                          if (_onlyPlayerTeam) _selectedTeamCode = null;
                        })
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (riders.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.directions_bike_outlined,
                    size: 28,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Brak kolarzy spełniających wybrane kryteria',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: riders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final rider = riders[index];
                return _GroupRiderRowTile(
                  rider: rider,
                  isMobile: isMobile,
                  onTap: widget.onSelectRider != null
                      ? () => widget.onSelectRider!(rider)
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AnalyzerCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _AnalyzerCard({
    required this.child,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? AppTheme.borderColor,
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}

class _HeaderMetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeaderMetaChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _PullerHighlightRow extends StatefulWidget {
  final PelotonGroupRiderEntry rider;
  final bool isSecondary;
  final VoidCallback? onTap;

  const _PullerHighlightRow({
    required this.rider,
    this.isSecondary = false,
    this.onTap,
  });

  @override
  State<_PullerHighlightRow> createState() => _PullerHighlightRowState();
}

class _PullerHighlightRowState extends State<_PullerHighlightRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final rider = widget.rider;
    final interactive = widget.onTap != null;

    return FocusableActionDetector(
      enabled: interactive,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.surfaceLight
                : AppColors.surfaceLight.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (_hovered
                      ? AppColors.goldAccent.withValues(alpha: 0.5)
                      : AppTheme.borderColor),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: rider.teamColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider.riderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: widget.isSecondary ? 12 : 14,
                        fontWeight: FontWeight.w700,
                        color: rider.isPlayerTeam
                            ? AppColors.goldAccent
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${rider.teamCode} • #${rider.bibNumber}',
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
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${rider.currentWatts} W',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    '${rider.wattsPerKg.toStringAsFixed(1)} W/kg'
                    '${rider.pullSharePercent > 0 ? ' • ${rider.pullSharePercent.toStringAsFixed(0)}%' : ''}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.accentBlue,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamShareChip extends StatefulWidget {
  final TeamCompositionShare share;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  const _TeamShareChip({
    required this.share,
    required this.isSelected,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_TeamShareChip> createState() => _TeamShareChipState();
}

class _TeamShareChipState extends State<_TeamShareChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final share = widget.share;
    final bgColor = widget.isSelected
        ? share.teamColor.withValues(alpha: 0.22)
        : (_hovered ? AppColors.surfaceLight : AppColors.background);

    final borderColor = _focused
        ? AppColors.goldAccent
        : (widget.isSelected
            ? share.teamColor
            : (_hovered ? AppColors.textSecondary : AppTheme.borderColor));

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 9 : 11,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: share.teamColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${share.teamCode}: ${share.riderCount}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: share.isPlayerTeam
                        ? AppColors.goldAccent
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '(${share.sharePercent.toStringAsFixed(0)}%)',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SortFilterChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final bool ascending;
  final VoidCallback onTap;

  const _SortFilterChip({
    required this.label,
    required this.isActive,
    required this.ascending,
    required this.onTap,
  });

  @override
  State<_SortFilterChip> createState() => _SortFilterChipState();
}

class _SortFilterChipState extends State<_SortFilterChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.primaryAccent.withValues(alpha: 0.28)
                : (_hovered ? AppColors.surfaceLight : AppColors.background),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (widget.isActive
                      ? AppColors.primaryAccent
                      : AppTheme.borderColor),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight:
                      widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isActive
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              if (widget.isActive) ...[
                const SizedBox(width: 4),
                Icon(
                  widget.ascending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 12,
                  color: AppColors.goldAccent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  const _ToggleFilterChip({
    required this.label,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_ToggleFilterChip> createState() => _ToggleFilterChipState();
}

class _ToggleFilterChipState extends State<_ToggleFilterChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.enabled || widget.onTap == null;
    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: disabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: disabled
                ? AppColors.background.withValues(alpha: 0.4)
                : (widget.isSelected
                    ? AppColors.goldAccent.withValues(alpha: 0.2)
                    : (_hovered
                        ? AppColors.surfaceLight
                        : AppColors.background)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: disabled
                  ? AppTheme.borderColor.withValues(alpha: 0.5)
                  : (_focused
                      ? AppColors.goldAccent
                      : (widget.isSelected
                          ? AppColors.goldAccent
                          : AppTheme.borderColor)),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              color: disabled
                  ? AppColors.textSecondary.withValues(alpha: 0.45)
                  : (widget.isSelected
                      ? AppColors.goldAccent
                      : AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupRiderRowTile extends StatefulWidget {
  final PelotonGroupRiderEntry rider;
  final bool isMobile;
  final VoidCallback? onTap;

  const _GroupRiderRowTile({
    required this.rider,
    required this.isMobile,
    this.onTap,
  });

  @override
  State<_GroupRiderRowTile> createState() => _GroupRiderRowTileState();
}

class _GroupRiderRowTileState extends State<_GroupRiderRowTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final rider = widget.rider;
    final interactive = widget.onTap != null;
    final fatigueColor = rider.fatiguePercent >= 75
        ? AppColors.crimsonAlert
        : (rider.fatiguePercent >= 45
            ? AppColors.amberWarning
            : AppColors.statusSuccess);

    return FocusableActionDetector(
      enabled: interactive,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: interactive ? (_) => setState(() => _pressed = true) : null,
        onTapUp: interactive ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            interactive ? () => setState(() => _pressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isMobile ? 10 : 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.surfaceLight
                : (_hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.85)
                    : (rider.isPullingFront
                        ? AppColors.goldAccent.withValues(alpha: 0.08)
                        : AppColors.background)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (rider.isPullingFront
                      ? AppColors.goldAccent.withValues(alpha: 0.5)
                      : (_hovered
                          ? AppColors.textSecondary.withValues(alpha: 0.5)
                          : AppTheme.borderColor)),
            ),
          ),
          child: widget.isMobile
              ? _buildMobileLayout(rider, fatigueColor)
              : _buildDesktopLayout(rider, fatigueColor),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    PelotonGroupRiderEntry rider,
    Color fatigueColor,
  ) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 30,
          decoration: BoxDecoration(
            color: rider.teamColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '#${rider.bibNumber}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        Container(
          width: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: rider.teamColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: rider.teamColor.withValues(alpha: 0.45)),
          ),
          child: Text(
            rider.teamCode,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Flexible(
                child: Text(
                  rider.riderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: rider.isPlayerTeam
                        ? AppColors.goldAccent
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (rider.isPullingFront) ...[
                const SizedBox(width: 6),
                const _FrontPullBadge(),
              ],
              if (rider.roleLabel != null) ...[
                const SizedBox(width: 6),
                Text(
                  '• ${rider.roleLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            '${rider.currentSpeedKmh.toStringAsFixed(1)} km/h',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 96,
          child: Text(
            '${rider.currentWatts} W (${rider.wattsPerKg.toStringAsFixed(1)})',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accentBlue,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 58,
          child: Text(
            '${rider.heartRateBpm} bpm',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 66,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Zmęcz. ${rider.fatiguePercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: fatigueColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (rider.fatiguePercent / 100.0).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(fatigueColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    PelotonGroupRiderEntry rider,
    Color fatigueColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: rider.teamColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              rider.teamCode,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: rider.teamColor,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${rider.riderName} (#${rider.bibNumber})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: rider.isPlayerTeam
                      ? AppColors.goldAccent
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (rider.isPullingFront) const _FrontPullBadge(),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              '${rider.currentSpeedKmh.toStringAsFixed(1)} km/h',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${rider.currentWatts} W • ${rider.wattsPerKg.toStringAsFixed(1)} W/kg',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.accentBlue,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            Text(
              'Zmęcz. ${rider.fatiguePercent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fatigueColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FrontPullBadge extends StatelessWidget {
  const _FrontPullBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.6),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.air_rounded, size: 10, color: AppColors.goldAccent),
          SizedBox(width: 3),
          Text(
            'CZEŁO',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: AppColors.goldAccent,
            ),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        mouseCursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.surfaceLight
                  : AppColors.background.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused ? AppColors.goldAccent : AppTheme.borderColor,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: _hovered ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _InteractiveActionButton({
    required this.icon,
    required this.label,
    required this.accentColor,
    this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.accentColor.withValues(alpha: 0.22)
                : widget.accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.textPrimary
                  : widget.accentColor.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: widget.accentColor),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: widget.accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Last5KmSpeedSparklinePainter extends CustomPainter {
  final List<double> samples;
  final double averageSpeed;

  const _Last5KmSpeedSparklinePainter({
    required this.samples,
    required this.averageSpeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    final double minVal = samples.reduce(math.min) - 1.5;
    final double maxVal = samples.reduce(math.max) + 1.5;
    final double range = math.max(1.0, maxVal - minVal);

    // Linia odniesienia średniej prędkości
    final avgY = size.height -
        ((averageSpeed - minVal) / range).clamp(0.0, 1.0) * size.height;
    final avgPaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.45)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, avgY), Offset(size.width, avgY), avgPaint);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < samples.length; i++) {
      final double x = samples.length == 1
          ? size.width
          : (i / (samples.length - 1)) * size.width;
      final double normalized = ((samples[i] - minVal) / range).clamp(0.0, 1.0);
      final double y = size.height - normalized * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accentBlue.withValues(alpha: 0.28),
          AppColors.accentBlue.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.accentBlue
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _Last5KmSpeedSparklinePainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.averageSpeed != averageSpeed;
  }
}

class _GroupTypeBadge {
  final String label;
  final IconData icon;
  final Color color;

  const _GroupTypeBadge(this.label, this.icon, this.color);
}

_GroupTypeBadge _groupTypeBadgeData(GroupType type) {
  switch (type) {
    case GroupType.solo:
      return const _GroupTypeBadge(
        'SOLO',
        Icons.person_outline_rounded,
        AppColors.goldAccent,
      );
    case GroupType.breakaway:
      return const _GroupTypeBadge(
        'UCIECZKA',
        Icons.bolt_rounded,
        AppColors.amberWarning,
      );
    case GroupType.chaseGroup:
      return const _GroupTypeBadge(
        'POŚCIG',
        Icons.fast_forward_rounded,
        AppColors.primaryAccent,
      );
    case GroupType.peloton:
      return const _GroupTypeBadge(
        'PELETON',
        Icons.groups_rounded,
        AppColors.accentBlue,
      );
    case GroupType.grupetto:
      return const _GroupTypeBadge(
        'GRUPETTO',
        Icons.directions_bus_outlined,
        AppColors.textSecondary,
      );
  }
}

String _formatGapSeconds(double seconds) {
  final total = seconds.round().abs();
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final secs = total % 60;
  if (hours > 0) {
    return '${hours}h${minutes.toString().padLeft(2, '0')}\'${secs.toString().padLeft(2, '0')}"';
  }
  if (minutes > 0) {
    return '$minutes\'${secs.toString().padLeft(2, '0')}"';
  }
  return '$secs"';
}

Color _parseHexColor(String hex) {
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length == 6) {
    final parsed = int.tryParse('FF$cleaned', radix: 16);
    if (parsed != null) return Color(parsed);
  }
  if (cleaned.length == 8) {
    final parsed = int.tryParse(cleaned, radix: 16);
    if (parsed != null) return Color(parsed);
  }
  return AppColors.accentBlue;
}
