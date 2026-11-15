import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../models/race/stage_segment.dart';

/// Typ premii lotnej lub górskiej wyświetlany w tablicy telewizyjnej [TvIntermediateSprintKomPopup].
enum TvPrimeClassificationType {
  /// Premia lotna (klasyfikacja punktowa / zielona koszulka): 20-17-15-13-11 pkt.
  intermediateSprint,

  /// Premia górska Hors Catégorie (HC / poza kategorią): 20-15-12-10-8 pkt.
  horsCategorie,

  /// Premia górska 1. kategorii: 10-8-6-4-2 pkt.
  cat1,

  /// Premia górska 2. kategorii: 5-3-2-1 pkt.
  cat2,

  /// Premia górska 3. kategorii: 2-1 pkt.
  cat3,

  /// Premia górska 4. kategorii: 1 pkt.
  cat4;

  /// Mapuje [SegmentClassification] z modelu etapu na typ premii TV.
  static TvPrimeClassificationType? fromSegmentClassification(
    SegmentClassification classification,
  ) {
    switch (classification) {
      case SegmentClassification.intermediateSprint:
        return TvPrimeClassificationType.intermediateSprint;
      case SegmentClassification.horsCategorie:
        return TvPrimeClassificationType.horsCategorie;
      case SegmentClassification.cat1:
        return TvPrimeClassificationType.cat1;
      case SegmentClassification.cat2:
        return TvPrimeClassificationType.cat2;
      case SegmentClassification.cat3:
        return TvPrimeClassificationType.cat3;
      case SegmentClassification.cat4:
        return TvPrimeClassificationType.cat4;
      case SegmentClassification.none:
      case SegmentClassification.finishLine:
        return null;
    }
  }

  /// Domyślna tabela punktów dla danej kategorii premii.
  List<int> get pointsSchedule {
    switch (this) {
      case TvPrimeClassificationType.intermediateSprint:
        return const <int>[20, 17, 15, 13, 11];
      case TvPrimeClassificationType.horsCategorie:
        return const <int>[20, 15, 12, 10, 8];
      case TvPrimeClassificationType.cat1:
        return const <int>[10, 8, 6, 4, 2];
      case TvPrimeClassificationType.cat2:
        return const <int>[5, 3, 2, 1];
      case TvPrimeClassificationType.cat3:
        return const <int>[2, 1];
      case TvPrimeClassificationType.cat4:
        return const <int>[1];
    }
  }

  /// Zwraca liczbę punktów dla podanej pozycji (1-indeksowanej).
  int pointsForPosition(int position) {
    if (position < 1 || position > pointsSchedule.length) {
      return 0;
    }
    return pointsSchedule[position - 1];
  }

  /// Krótka etykieta kategorii (np. `SPRINT`, `HC`, `KAT. 1`).
  String get shortBadge {
    switch (this) {
      case TvPrimeClassificationType.intermediateSprint:
        return 'SPRINT';
      case TvPrimeClassificationType.horsCategorie:
        return 'HC';
      case TvPrimeClassificationType.cat1:
        return 'KAT. 1';
      case TvPrimeClassificationType.cat2:
        return 'KAT. 2';
      case TvPrimeClassificationType.cat3:
        return 'KAT. 3';
      case TvPrimeClassificationType.cat4:
        return 'KAT. 4';
    }
  }

  /// Pełny tytuł klasyfikacji w nagłówku transmisji.
  String get headerTitle {
    switch (this) {
      case TvPrimeClassificationType.intermediateSprint:
        return 'PREMIA LOTNA • KLASYFIKACJA PUNKTOWA';
      case TvPrimeClassificationType.horsCategorie:
        return 'PREMIA GÓRSKA HC • HORS CATÉGORIE';
      case TvPrimeClassificationType.cat1:
        return 'PREMIA GÓRSKA • KATEGORIA 1';
      case TvPrimeClassificationType.cat2:
        return 'PREMIA GÓRSKA • KATEGORIA 2';
      case TvPrimeClassificationType.cat3:
        return 'PREMIA GÓRSKA • KATEGORIA 3';
      case TvPrimeClassificationType.cat4:
        return 'PREMIA GÓRSKA • KATEGORIA 4';
    }
  }

  /// Czy jest to premia lotna (w przeciwieństwie do premii górskiej).
  bool get isSprint => this == TvPrimeClassificationType.intermediateSprint;

  /// Kolor wiodący dla danej klasyfikacji.
  Color get accentColor {
    switch (this) {
      case TvPrimeClassificationType.intermediateSprint:
        return AppColors.statusSuccess;
      case TvPrimeClassificationType.horsCategorie:
        return AppColors.crimsonAlert;
      case TvPrimeClassificationType.cat1:
        return AppColors.primaryAccent;
      case TvPrimeClassificationType.cat2:
        return AppColors.amberWarning;
      case TvPrimeClassificationType.cat3:
        return AppColors.goldAccent;
      case TvPrimeClassificationType.cat4:
        return AppColors.accentBlue;
    }
  }
}

/// Tryb wyświetlania punktów w tabeli premii.
enum TvPrimePointsDisplayMode {
  /// Pokazuje zdobyte punkty na premii (`+20 pkt`) oraz sumę w klasyfikacji.
  awardedAndTotal,

  /// Pokazuje wyłącznie punkty zdobyte na tej premii (`+20`).
  awardedOnly,
}

/// Pojedynczy wpis kolarza przejeżdżającego przez linię premii lotnej lub górskiej.
@immutable
class TvPrimeCrossingEntry {
  final int position;
  final String riderId;
  final String riderName;
  final String teamShortCode;
  final String teamName;
  final String nationalityIso;
  final String primaryJerseyHex;
  final int? pointsAwardedOverride;
  final int totalPointsBefore;
  final double gapSeconds;
  final bool isPlayerTeam;
  final bool isClassificationLeader;

  const TvPrimeCrossingEntry({
    required this.position,
    required this.riderId,
    required this.riderName,
    required this.teamShortCode,
    this.teamName = '',
    this.nationalityIso = 'INT',
    this.primaryJerseyHex = '#D4AF37',
    this.pointsAwardedOverride,
    this.totalPointsBefore = 0,
    this.gapSeconds = 0.0,
    this.isPlayerTeam = false,
    this.isClassificationLeader = false,
  });

  /// Wylicza punkty zdobyte na premii (nadpisanie lub harmonogram dla [type]).
  int resolvePointsAwarded(TvPrimeClassificationType type) {
    if (pointsAwardedOverride != null) {
      return math.max(0, pointsAwardedOverride!);
    }
    return type.pointsForPosition(position);
  }

  /// Suma punktów w klasyfikacji po dodaniu punktów z premii.
  int resolveTotalPointsAfter(TvPrimeClassificationType type) {
    return math.max(0, totalPointsBefore) + resolvePointsAwarded(type);
  }

  /// Formatuje stratę czasową względem 1. kolarza na linii premii.
  String get formattedGap {
    if (position <= 1 || gapSeconds.isNaN || gapSeconds.isInfinite) {
      return '0.0"';
    }
    final double clamped = math.max(0.0, gapSeconds);
    if (clamped < 60.0) {
      return '+${clamped.toStringAsFixed(1)}"';
    }
    final int mins = clamped ~/ 60;
    final int secs = (clamped % 60).floor();
    return '+$mins\'${secs.toString().padLeft(2, '0')}"';
  }
}

/// Komplet danych wejściowych dla wyskakującej tablicy [TvIntermediateSprintKomPopup].
@immutable
class TvIntermediateSprintKomPopupData {
  final String primeId;
  final String primeName;
  final TvPrimeClassificationType classificationType;
  final double kilometerMark;
  final int? elevationMeters;
  final double? averageGradientPercent;
  final List<TvPrimeCrossingEntry> entries;
  final bool isVisible;
  final Duration? autoDismissDuration;

  const TvIntermediateSprintKomPopupData({
    required this.primeId,
    required this.primeName,
    required this.classificationType,
    required this.kilometerMark,
    this.elevationMeters,
    this.averageGradientPercent,
    required this.entries,
    this.isVisible = true,
    this.autoDismissDuration,
  });

  /// Zwraca posortowaną po pozycji listę pierwszych 5 (lub mniej) punktujących kolarzy.
  List<TvPrimeCrossingEntry> get sortedScoringEntries {
    final List<TvPrimeCrossingEntry> copy = List<TvPrimeCrossingEntry>.from(entries);
    copy.sort((a, b) => a.position.compareTo(b.position));
    final int maxRows = math.max(1, classificationType.pointsSchedule.length);
    if (copy.length > maxRows) {
      return copy.sublist(0, maxRows);
    }
    return copy;
  }
}

/// Telewizyjna wyskakująca tablica wyników premii lotnej i górskiej w stylu transmisji TDF/Eurosport.
///
/// Obsługuje animowane wejście (300 ms, `Curves.easeOutCubic`), sekwencyjne zliczanie punktów
/// (`20-17-15-13-11` pkt na sprincie oraz `20-15-12-10-8` pkt na HC) w momencie przejazdu
/// pierwszych kolarzy przez linię premii, pełne stany hover/active/disabled/focus oraz
/// responsywność `LayoutBuilder` dla `390x844`, `1024x768` i `1600x900`.
class TvIntermediateSprintKomPopup extends StatefulWidget {
  final TvIntermediateSprintKomPopupData data;
  final VoidCallback? onDismiss;
  final ValueChanged<TvPrimeCrossingEntry>? onRiderTap;
  final bool isEnabled;
  final TvPrimePointsDisplayMode initialDisplayMode;

  const TvIntermediateSprintKomPopup({
    super.key,
    required this.data,
    this.onDismiss,
    this.onRiderTap,
    this.isEnabled = true,
    this.initialDisplayMode = TvPrimePointsDisplayMode.awardedAndTotal,
  });

  @override
  State<TvIntermediateSprintKomPopup> createState() =>
      _TvIntermediateSprintKomPopupState();
}

class _TvIntermediateSprintKomPopupState
    extends State<TvIntermediateSprintKomPopup>
    with SingleTickerProviderStateMixin {
  static const Color _borderColor = Color(0xFF2A2F3D);

  late final AnimationController _panelController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  late TvPrimePointsDisplayMode _displayMode;
  Timer? _autoDismissTimer;

  bool _isCloseHovered = false;
  bool _isClosePressed = false;
  bool _isCloseFocused = false;

  bool _isModeHovered = false;
  bool _isModePressed = false;
  bool _isModeFocused = false;

  @override
  void initState() {
    super.initState();
    _displayMode = widget.initialDisplayMode;
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _panelController,
        curve: Curves.easeOutCubic,
      ),
    );

    if (widget.data.isVisible) {
      _panelController.forward();
      _scheduleAutoDismiss();
    }
  }

  @override
  void didUpdateWidget(covariant TvIntermediateSprintKomPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.isVisible && !oldWidget.data.isVisible) {
      _panelController.forward(from: 0.0);
      _scheduleAutoDismiss();
    } else if (!widget.data.isVisible && oldWidget.data.isVisible) {
      _autoDismissTimer?.cancel();
      _panelController.reverse();
    } else if (widget.data.primeId != oldWidget.data.primeId) {
      _panelController.forward(from: 0.0);
      _scheduleAutoDismiss();
    } else if (widget.data.entries.length != oldWidget.data.entries.length) {
      _scheduleAutoDismiss();
    }
  }

  void _scheduleAutoDismiss() {
    _autoDismissTimer?.cancel();
    final Duration? duration = widget.data.autoDismissDuration;
    if (duration != null && widget.onDismiss != null && widget.isEnabled) {
      _autoDismissTimer = Timer(duration, () {
        if (mounted && widget.data.isVisible) {
          widget.onDismiss?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _panelController.dispose();
    super.dispose();
  }

  void _toggleDisplayMode() {
    if (!widget.isEnabled) return;
    setState(() {
      _displayMode =
          _displayMode == TvPrimePointsDisplayMode.awardedAndTotal
              ? TvPrimePointsDisplayMode.awardedOnly
              : TvPrimePointsDisplayMode.awardedAndTotal;
    });
  }

  void _handleDismiss() {
    if (!widget.isEnabled) return;
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.data.isVisible && _panelController.isDismissed) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final double availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;

        final bool isCompact = availableWidth < 520.0;
        final bool isMedium = availableWidth >= 520.0 && availableWidth < 1100.0;

        final double targetWidth = isCompact
            ? math.max(260.0, availableWidth - 24.0)
            : (isMedium ? 430.0 : 470.0);
        final double maxPopupHeight = math.max(220.0, availableHeight - 24.0);

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: targetWidth,
                maxHeight: maxPopupHeight,
              ),
              child: Semantics(
                container: true,
                label:
                    '${widget.data.classificationType.headerTitle}: ${widget.data.primeName}',
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: widget.isEnabled ? 1.0 : 0.55,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _borderColor,
                        width: 1.0,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _buildHeader(isCompact: isCompact),
                          _buildScheduleStrip(isCompact: isCompact),
                          _buildColumnLegend(isCompact: isCompact),
                          _buildEntriesList(isCompact: isCompact),
                          _buildFooter(isCompact: isCompact),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({required bool isCompact}) {
    final TvPrimeClassificationType type = widget.data.classificationType;
    final Color accent = type.accentColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12.0 : 16.0,
        vertical: isCompact ? 10.0 : 12.0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            AppColors.background,
            accent.withValues(alpha: 0.22),
            AppColors.surfaceLight,
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: _borderColor, width: 1.0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _ClassificationEmblem(type: type, isCompact: isCompact),
          SizedBox(width: isCompact ? 10.0 : 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.7),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        type.shortBadge,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isCompact ? 9.5 : 10.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        type.headerTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isCompact ? 9.5 : 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: AppColors.goldAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.data.primeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 14.0 : 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _buildLocationMetadataText(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 10.5 : 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildHeaderActions(isCompact: isCompact),
        ],
      ),
    );
  }

  String _buildLocationMetadataText() {
    final List<String> parts = <String>[
      'KM ${widget.data.kilometerMark.toStringAsFixed(1)}',
    ];
    if (widget.data.elevationMeters != null) {
      parts.add('${widget.data.elevationMeters} m n.p.m.');
    }
    if (widget.data.averageGradientPercent != null) {
      parts.add('${widget.data.averageGradientPercent!.toStringAsFixed(1)}%');
    }
    return parts.join(' • ');
  }

  Widget _buildHeaderActions({required bool isCompact}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _HeaderActionButton(
          tooltip:
              _displayMode == TvPrimePointsDisplayMode.awardedAndTotal
                  ? 'Pokaż tylko punkty z premii'
                  : 'Pokaż punkty z premii i sumę',
          icon:
              _displayMode == TvPrimePointsDisplayMode.awardedAndTotal
                  ? Icons.summarize_outlined
                  : Icons.add_chart_outlined,
          isEnabled: widget.isEnabled,
          isHovered: _isModeHovered,
          isPressed: _isModePressed,
          isFocused: _isModeFocused,
          isCompact: isCompact,
          onHoverChanged: (bool v) => setState(() => _isModeHovered = v),
          onPressedChanged: (bool v) => setState(() => _isModePressed = v),
          onFocusChanged: (bool v) => setState(() => _isModeFocused = v),
          onTap: _toggleDisplayMode,
        ),
        if (widget.onDismiss != null) ...<Widget>[
          const SizedBox(width: 6),
          _HeaderActionButton(
            tooltip: 'Zamknij tablicę premii',
            icon: Icons.close_rounded,
            isEnabled: widget.isEnabled,
            isHovered: _isCloseHovered,
            isPressed: _isClosePressed,
            isFocused: _isCloseFocused,
            isCompact: isCompact,
            onHoverChanged: (bool v) => setState(() => _isCloseHovered = v),
            onPressedChanged: (bool v) => setState(() => _isClosePressed = v),
            onFocusChanged: (bool v) => setState(() => _isCloseFocused = v),
            onTap: _handleDismiss,
          ),
        ],
      ],
    );
  }

  Widget _buildScheduleStrip({required bool isCompact}) {
    final List<int> schedule = widget.data.classificationType.pointsSchedule;
    final Color accent = widget.data.classificationType.accentColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12.0 : 16.0,
        vertical: 6.0,
      ),
      color: AppColors.background.withValues(alpha: 0.72),
      child: Row(
        children: <Widget>[
          Text(
            'PKT:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 10.0 : 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: List<Widget>.generate(schedule.length, (int idx) {
                final int pos = idx + 1;
                final int pts = schedule[idx];
                final bool hasCrossed = widget.data.entries
                    .any((TvPrimeCrossingEntry e) => e.position == pos);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: hasCrossed
                        ? accent.withValues(alpha: 0.24)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: hasCrossed ? accent : _borderColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$pos. $pts',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 10.0 : 10.5,
                      fontWeight: hasCrossed ? FontWeight.w700 : FontWeight.w500,
                      color: hasCrossed
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnLegend({required bool isCompact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12.0 : 16.0,
        vertical: 6.0,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          top: BorderSide(color: _borderColor, width: 1.0),
          bottom: BorderSide(color: _borderColor, width: 1.0),
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: isCompact ? 24 : 28,
            child: Text(
              '#',
              style: _legendStyle(isCompact),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'KOLARZ / ZESPÓŁ',
              style: _legendStyle(isCompact),
            ),
          ),
          if (!isCompact) ...<Widget>[
            SizedBox(
              width: 56,
              child: Text(
                'STRATA',
                textAlign: TextAlign.right,
                style: _legendStyle(isCompact),
              ),
            ),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: _displayMode == TvPrimePointsDisplayMode.awardedAndTotal
                ? (isCompact ? 102 : 112)
                : (isCompact ? 56 : 64),
            child: Text(
              _displayMode == TvPrimePointsDisplayMode.awardedAndTotal
                  ? 'PREMIA / SUMA'
                  : 'PREMIA',
              textAlign: TextAlign.right,
              style: _legendStyle(isCompact),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _legendStyle(bool isCompact) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: isCompact ? 9.5 : 10.0,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: AppColors.textSecondary,
    );
  }

  Widget _buildEntriesList({required bool isCompact}) {
    final List<TvPrimeCrossingEntry> entries = widget.data.sortedScoringEntries;
    if (entries.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12.0 : 16.0,
          vertical: 18.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.data.classificationType.accentColor,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Oczekiwanie na przejazd pierwszych kolarzy przez linię premii...',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(entries.length, (int index) {
        final TvPrimeCrossingEntry entry = entries[index];
        return _AnimatedPrimeCrossingRow(
          key: ValueKey<String>(
            '${widget.data.primeId}_${entry.riderId}_${entry.position}',
          ),
          entry: entry,
          classificationType: widget.data.classificationType,
          displayMode: _displayMode,
          staggerIndex: index,
          isCompact: isCompact,
          isEnabled: widget.isEnabled,
          isLast: index == entries.length - 1,
          onTap: widget.onRiderTap != null
              ? () => widget.onRiderTap!(entry)
              : null,
        );
      }),
    );
  }

  Widget _buildFooter({required bool isCompact}) {
    final List<TvPrimeCrossingEntry> entries = widget.data.sortedScoringEntries;
    final int scoredCount = entries.length;
    final int totalSlots = widget.data.classificationType.pointsSchedule.length;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12.0 : 16.0,
        vertical: 8.0,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: _borderColor, width: 1.0),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            widget.data.classificationType.isSprint
                ? Icons.bolt_rounded
                : Icons.terrain_rounded,
            size: 14,
            color: AppColors.goldAccent,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Przejazd przez linię: $scoredCount/$totalSlots punktujących',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isCompact ? 10.5 : 11.0,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
          Text(
            'TV LIVE',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 9.5 : 10.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.goldAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassificationEmblem extends StatelessWidget {
  final TvPrimeClassificationType type;
  final bool isCompact;

  const _ClassificationEmblem({
    required this.type,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final double size = isCompact ? 34.0 : 38.0;
    final Color accent = type.accentColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accent.withValues(alpha: 0.75),
          width: 1.2,
        ),
      ),
      child: Center(
        child: type.isSprint
            ? Icon(
                Icons.flash_on_rounded,
                size: isCompact ? 18 : 20,
                color: AppColors.statusSuccess,
              )
            : CustomPaint(
                size: Size.square(isCompact ? 20 : 22),
                painter: _PolkaDotMountainPainter(dotColor: accent),
              ),
      ),
    );
  }
}

class _PolkaDotMountainPainter extends CustomPainter {
  final Color dotColor;

  const _PolkaDotMountainPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Path mountain = Path()
      ..moveTo(size.width * 0.08, size.height * 0.84)
      ..lineTo(size.width * 0.44, size.height * 0.20)
      ..lineTo(size.width * 0.64, size.height * 0.56)
      ..lineTo(size.width * 0.78, size.height * 0.34)
      ..lineTo(size.width * 0.94, size.height * 0.84)
      ..close();

    final Paint fillPaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    canvas.drawPath(mountain, fillPaint);

    final Paint dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.44, size.height * 0.44),
      size.width * 0.085,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.34, size.height * 0.68),
      size.width * 0.085,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.66, size.height * 0.70),
      size.width * 0.085,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PolkaDotMountainPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor;
  }
}

class _HeaderActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool isEnabled;
  final bool isHovered;
  final bool isPressed;
  final bool isFocused;
  final bool isCompact;
  final ValueChanged<bool> onHoverChanged;
  final ValueChanged<bool> onPressedChanged;
  final ValueChanged<bool> onFocusChanged;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.tooltip,
    required this.icon,
    required this.isEnabled,
    required this.isHovered,
    required this.isPressed,
    required this.isFocused,
    required this.isCompact,
    required this.onHoverChanged,
    required this.onPressedChanged,
    required this.onFocusChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double size = isCompact ? 28.0 : 30.0;
    final Color bgColor = !isEnabled
        ? AppColors.surface
        : isPressed
            ? AppColors.primaryAccent.withValues(alpha: 0.45)
            : isHovered
                ? AppColors.surfaceLight
                : AppColors.background.withValues(alpha: 0.75);
    final Color borderColor = isFocused
        ? AppColors.goldAccent
        : isHovered && isEnabled
            ? AppColors.textSecondary
            : const Color(0xFF2A2F3D);

    return Tooltip(
      message: tooltip,
      child: FocusableActionDetector(
        enabled: isEnabled,
        onShowHoverHighlight: onHoverChanged,
        onShowFocusHighlight: onFocusChanged,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) {
              if (isEnabled) onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTapDown: isEnabled ? (_) => onPressedChanged(true) : null,
          onTapUp: isEnabled ? (_) => onPressedChanged(false) : null,
          onTapCancel: isEnabled ? () => onPressedChanged(false) : null,
          onTap: isEnabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor,
                width: isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Icon(
              icon,
              size: isCompact ? 15 : 16,
              color: isEnabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedPrimeCrossingRow extends StatefulWidget {
  final TvPrimeCrossingEntry entry;
  final TvPrimeClassificationType classificationType;
  final TvPrimePointsDisplayMode displayMode;
  final int staggerIndex;
  final bool isCompact;
  final bool isEnabled;
  final bool isLast;
  final VoidCallback? onTap;

  const _AnimatedPrimeCrossingRow({
    super.key,
    required this.entry,
    required this.classificationType,
    required this.displayMode,
    required this.staggerIndex,
    required this.isCompact,
    required this.isEnabled,
    required this.isLast,
    this.onTap,
  });

  @override
  State<_AnimatedPrimeCrossingRow> createState() =>
      _AnimatedPrimeCrossingRowState();
}

class _AnimatedPrimeCrossingRowState extends State<_AnimatedPrimeCrossingRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rowController;
  late final Animation<double> _revealAnimation;
  late final Animation<double> _pointsAnimation;

  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    final int delayMs = math.min(widget.staggerIndex * 90, 450);
    _rowController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 340 + delayMs),
    );

    final double startFraction =
        delayMs / (340.0 + delayMs).clamp(1.0, double.infinity);

    _revealAnimation = CurvedAnimation(
      parent: _rowController,
      curve: Interval(startFraction, 1.0, curve: Curves.easeOutCubic),
    );
    _pointsAnimation = CurvedAnimation(
      parent: _rowController,
      curve: Interval(
        math.min(0.95, startFraction + 0.08),
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );

    _rowController.forward();
  }

  @override
  void dispose() {
    _rowController.dispose();
    super.dispose();
  }

  Color _parseJerseyColor(String hex) {
    final String cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      final int? parsed = int.tryParse('FF$cleaned', radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return AppColors.goldAccent;
  }

  @override
  Widget build(BuildContext context) {
    final TvPrimeCrossingEntry entry = widget.entry;
    final int targetPoints =
        entry.resolvePointsAwarded(widget.classificationType);
    final int baseTotal = math.max(0, entry.totalPointsBefore);
    final Color jerseyColor = _parseJerseyColor(entry.primaryJerseyHex);
    final Color typeAccent = widget.classificationType.accentColor;

    final bool canInteract = widget.isEnabled && widget.onTap != null;
    final Color rowBg = !widget.isEnabled
        ? AppColors.surface.withValues(alpha: 0.6)
        : _isPressed && canInteract
            ? AppColors.primaryAccent.withValues(alpha: 0.25)
            : _isHovered && canInteract
                ? AppColors.surfaceLight
                : entry.isPlayerTeam
                    ? AppColors.goldAccent.withValues(alpha: 0.12)
                    : Colors.transparent;

    return AnimatedBuilder(
      animation: _rowController,
      builder: (BuildContext context, Widget? child) {
        final double reveal = _revealAnimation.value;
        final double ptsProgress = _pointsAnimation.value;
        final int animatedPoints = (targetPoints * ptsProgress).round();
        final int animatedTotal = baseTotal + animatedPoints;

        return Opacity(
          opacity: reveal,
          child: Transform.translate(
            offset: Offset((1.0 - reveal) * 18.0, 0.0),
            child: FocusableActionDetector(
              enabled: canInteract,
              onShowHoverHighlight: (bool v) {
                if (_isHovered != v) setState(() => _isHovered = v);
              },
              onShowFocusHighlight: (bool v) {
                if (_isFocused != v) setState(() => _isFocused = v);
              },
              shortcuts: const <ShortcutActivator, Intent>{
                SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
              },
              actions: <Type, Action<Intent>>{
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (ActivateIntent intent) {
                    if (canInteract) widget.onTap?.call();
                    return null;
                  },
                ),
              },
              child: GestureDetector(
                onTapDown: canInteract
                    ? (_) => setState(() => _isPressed = true)
                    : null,
                onTapUp: canInteract
                    ? (_) => setState(() => _isPressed = false)
                    : null,
                onTapCancel: canInteract
                    ? () => setState(() => _isPressed = false)
                    : null,
                onTap: canInteract ? widget.onTap : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isCompact ? 12.0 : 16.0,
                    vertical: widget.isCompact ? 8.0 : 9.0,
                  ),
                  decoration: BoxDecoration(
                    color: rowBg,
                    border: Border(
                      left: BorderSide(
                        color: _isFocused
                            ? AppColors.goldAccent
                            : entry.isPlayerTeam
                                ? AppColors.goldAccent
                                : Colors.transparent,
                        width: 3.0,
                      ),
                      bottom: widget.isLast
                          ? BorderSide.none
                          : const BorderSide(
                              color: Color(0xFF2A2F3D),
                              width: 1.0,
                            ),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      _PositionBadge(
                        position: entry.position,
                        accentColor: typeAccent,
                        isCompact: widget.isCompact,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: widget.isCompact ? 24 : 28,
                        decoration: BoxDecoration(
                          color: jerseyColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    entry.riderName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: widget.isCompact ? 12.5 : 13.5,
                                      fontWeight: entry.isPlayerTeam
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      letterSpacing: -0.2,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (entry.isClassificationLeader) ...<Widget>[
                                  const SizedBox(width: 5),
                                  Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 13,
                                    color: typeAccent,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${entry.teamShortCode} • ${entry.nationalityIso.toUpperCase()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: widget.isCompact ? 10.0 : 10.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!widget.isCompact) ...<Widget>[
                        SizedBox(
                          width: 56,
                          child: Text(
                            entry.formattedGap,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              fontFeatures: <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      SizedBox(
                        width: widget.displayMode ==
                                TvPrimePointsDisplayMode.awardedAndTotal
                            ? (widget.isCompact ? 102 : 112)
                            : (widget.isCompact ? 56 : 64),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: typeAccent.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: typeAccent.withValues(alpha: 0.65),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '+$animatedPoints',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: widget.isCompact ? 11.5 : 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  fontFeatures: const <FontFeature>[
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                            if (widget.displayMode ==
                                TvPrimePointsDisplayMode
                                    .awardedAndTotal) ...<Widget>[
                              const SizedBox(width: 6),
                              Text(
                                '$animatedTotal',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: widget.isCompact ? 11.5 : 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.goldAccent,
                                  fontFeatures: const <FontFeature>[
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
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
      },
    );
  }
}

class _PositionBadge extends StatelessWidget {
  final int position;
  final Color accentColor;
  final bool isCompact;

  const _PositionBadge({
    required this.position,
    required this.accentColor,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWinner = position == 1;
    final double size = isCompact ? 24.0 : 28.0;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isWinner
            ? AppColors.goldAccent.withValues(alpha: 0.22)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isWinner ? AppColors.goldAccent : const Color(0xFF2A2F3D),
          width: 1,
        ),
      ),
      child: Text(
        '$position',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: isCompact ? 11.0 : 12.0,
          fontWeight: FontWeight.w800,
          color: isWinner ? AppColors.goldAccent : AppColors.textPrimary,
          fontFeatures: const <FontFeature>[
            FontFeature.tabularFigures(),
          ],
        ),
      ),
    );
  }
}
