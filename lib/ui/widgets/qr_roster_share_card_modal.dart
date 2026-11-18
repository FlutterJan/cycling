import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../models/career/pro_cyclist_career_state.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_appearance.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/rider/rider_health.dart';
import '../../models/rider/rider_physiology.dart';
import '../../models/rider/rider_power_profile.dart';
import '../../models/rider/rider_skills.dart';
import '../../models/team/bike_manufacturer_deal.dart';
import '../../models/team/cycling_team.dart';
import '../../services/career/career_save_cloud_qr_code_transfer.dart';

/// Tryb wyświetlania karty wizytówki w modalu udostępniania QR.
enum ShareCardMode {
  teamRoster,
  beAProRider;

  String get label {
    switch (this) {
      case ShareCardMode.teamRoster:
        return 'Wizytówka Drużyny';
      case ShareCardMode.beAProRider:
        return 'Profil Kolarza';
    }
  }

  IconData get icon {
    switch (this) {
      case ShareCardMode.teamRoster:
        return Icons.groups_rounded;
      case ShareCardMode.beAProRider:
        return Icons.person_pin_rounded;
    }
  }
}

/// Styl kolorystyczny generowanej karty wizytówki zespołu lub kolarza.
enum ShareCardThemeStyle {
  obsidianGold,
  burgundyHeritage,
  telemetryCyan;

  String get label {
    switch (this) {
      case ShareCardThemeStyle.obsidianGold:
        return 'Obsidian Gold';
      case ShareCardThemeStyle.burgundyHeritage:
        return 'Burgundy Heritage';
      case ShareCardThemeStyle.telemetryCyan:
        return 'Telemetry Cyan';
    }
  }

  Color get accentColor {
    switch (this) {
      case ShareCardThemeStyle.obsidianGold:
        return AppColors.goldAccent;
      case ShareCardThemeStyle.burgundyHeritage:
        return AppColors.primaryAccent;
      case ShareCardThemeStyle.telemetryCyan:
        return AppColors.cyanAccent;
    }
  }

  Color get secondaryAccentColor {
    switch (this) {
      case ShareCardThemeStyle.obsidianGold:
        return AppColors.primaryAccent;
      case ShareCardThemeStyle.burgundyHeritage:
        return AppColors.goldAccent;
      case ShareCardThemeStyle.telemetryCyan:
        return AppColors.accentBlue;
    }
  }
}

/// Wyliczone metryki OVR dla wizytówki drużyny lub pojedynczego kolarza.
class ShareCardOvrStats {
  final int averageOvr;
  final int peakOvr;
  final double averageWkg;
  final int climbScore;
  final int sprintScore;
  final int timeTrialScore;
  final int cobblesScore;
  final int punchScore;
  final int raceIqScore;

  const ShareCardOvrStats({
    required this.averageOvr,
    required this.peakOvr,
    required this.averageWkg,
    required this.climbScore,
    required this.sprintScore,
    required this.timeTrialScore,
    required this.cobblesScore,
    required this.punchScore,
    required this.raceIqScore,
  });

  factory ShareCardOvrStats.fromRiders(List<Rider> riders) {
    if (riders.isEmpty) {
      return const ShareCardOvrStats(
        averageOvr: 0,
        peakOvr: 0,
        averageWkg: 0.0,
        climbScore: 0,
        sprintScore: 0,
        timeTrialScore: 0,
        cobblesScore: 0,
        punchScore: 0,
        raceIqScore: 0,
      );
    }

    int ovrSum = 0;
    int peak = 0;
    double wkgSum = 0.0;
    double climbSum = 0.0;
    double sprintSum = 0.0;
    double ttSum = 0.0;
    double cobblesSum = 0.0;
    double punchSum = 0.0;
    double iqSum = 0.0;

    for (final r in riders) {
      final ovr = r.overallRating;
      ovrSum += ovr;
      if (ovr > peak) peak = ovr;

      final weight = r.physiology.weightKg > 0.0 ? r.physiology.weightKg : 70.0;
      final wkg20 = r.powerProfile.watts20m / weight;
      final wkg1 = r.powerProfile.watts1m / weight;
      wkgSum += r.physiology.wattsPerKg;

      climbSum += ((wkg20 - 3.5) / (6.6 - 3.5) * 55 + 44).clamp(40.0, 99.0);
      sprintSum +=
          ((r.powerProfile.watts5s - 900.0) / (1750.0 - 900.0) * 55 + 44)
              .clamp(40.0, 99.0);
      ttSum += ((r.powerProfile.watts60m - 280.0) / (460.0 - 280.0) * 40 +
              r.skills.timeTrialPositioning * 0.35 +
              r.skills.aeroPositioning * 0.25)
          .clamp(40.0, 99.0);
      cobblesSum +=
          (r.skills.cobbles * 0.65 + r.skills.bikeHandling * 0.35).clamp(40.0, 99.0);
      punchSum += ((wkg1 - 6.5) / (12.0 - 6.5) * 55 + 44).clamp(40.0, 99.0);
      iqSum += r.skills.raceIq.toDouble().clamp(40.0, 99.0);
    }

    final count = riders.length;
    return ShareCardOvrStats(
      averageOvr: (ovrSum / count).round(),
      peakOvr: peak,
      averageWkg: wkgSum / count,
      climbScore: (climbSum / count).round(),
      sprintScore: (sprintSum / count).round(),
      timeTrialScore: (ttSum / count).round(),
      cobblesScore: (cobblesSum / count).round(),
      punchScore: (punchSum / count).round(),
      raceIqScore: (iqSum / count).round(),
    );
  }
}

/// Otwiera elegancki modal `QrRosterShareCardModal` z płynną animacją wejścia.
Future<void> showQrRosterShareCardModal(
  BuildContext context, {
  CyclingTeam? team,
  List<Rider>? roster,
  Rider? featuredRider,
  ProCyclistCareerState? proCyclistState,
  String raceTitle = 'Wyścigowy Skład Startowy',
  int seasonYear = 2026,
  String? leaderRiderId,
  String? sprinterRiderId,
  ShareCardMode? initialMode,
  bool useDemoFallback = true,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Zamknij modal udostępniania składu QR',
    barrierColor: Colors.black.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return QrRosterShareCardModal(
        team: team,
        roster: roster,
        featuredRider: featuredRider,
        proCyclistState: proCyclistState,
        raceTitle: raceTitle,
        seasonYear: seasonYear,
        leaderRiderId: leaderRiderId,
        sprinterRiderId: sprinterRiderId,
        initialMode: initialMode,
        useDemoFallback: useDemoFallback,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Elegancki modal udostępniania składu drużyny i profilu kolarza z generowaną
/// kartą wizytówką zespołu, statystykami OVR, kodem QR oraz kopiowaniem tokena
/// transferowego `PPM1:` do schowka.
class QrRosterShareCardModal extends StatefulWidget {
  final CyclingTeam? team;
  final List<Rider>? roster;
  final Rider? featuredRider;
  final ProCyclistCareerState? proCyclistState;
  final String raceTitle;
  final int seasonYear;
  final String? leaderRiderId;
  final String? sprinterRiderId;
  final ShareCardMode? initialMode;
  final bool useDemoFallback;
  final VoidCallback? onClose;

  const QrRosterShareCardModal({
    super.key,
    this.team,
    this.roster,
    this.featuredRider,
    this.proCyclistState,
    this.raceTitle = 'Wyścigowy Skład Startowy',
    this.seasonYear = 2026,
    this.leaderRiderId,
    this.sprinterRiderId,
    this.initialMode,
    this.useDemoFallback = true,
    this.onClose,
  });

  @override
  State<QrRosterShareCardModal> createState() => _QrRosterShareCardModalState();
}

class _QrRosterShareCardModalState extends State<QrRosterShareCardModal>
    with SingleTickerProviderStateMixin {
  static const CareerSaveCloudQrCodeTransfer _transferService =
      CareerSaveCloudQrCodeTransfer();

  late final AnimationController _pulseController;
  late ShareCardMode _mode;
  ShareCardThemeStyle _themeStyle = ShareCardThemeStyle.obsidianGold;
  TransferQrErrorCorrectionLevel _ecLevel =
      TransferQrErrorCorrectionLevel.medium;

  CyclingTeam? _activeTeam;
  List<Rider> _activeRoster = const [];
  Rider? _activeRider;
  ProCyclistCareerState? _activeProState;
  String? _leaderId;
  String? _sprinterId;

  CareerTransferExportBundle? _exportBundle;
  bool _showFullToken = false;
  bool _copiedToken = false;
  bool _copiedSummary = false;
  Timer? _copiedTokenTimer;
  Timer? _copiedSummaryTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _resolveInitialData();
    _regenerateBundle();
  }

  @override
  void dispose() {
    _copiedTokenTimer?.cancel();
    _copiedSummaryTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _resolveInitialData() {
    final hasExplicitTeam = widget.team != null && widget.roster != null;
    final hasExplicitPro = widget.proCyclistState != null;
    final hasExplicitRider = widget.featuredRider != null;

    if (!hasExplicitTeam &&
        !hasExplicitPro &&
        !hasExplicitRider &&
        widget.useDemoFallback &&
        widget.roster == null) {
      _loadShowcaseData();
    } else {
      _activeTeam = widget.team;
      _activeRoster = List<Rider>.unmodifiable(widget.roster ?? const []);
      _activeProState = widget.proCyclistState;
      _activeRider = widget.featuredRider ??
          widget.proCyclistState?.playerRider ??
          (_activeRoster.isNotEmpty ? _activeRoster.first : null);
      _leaderId = widget.leaderRiderId ??
          (_activeRoster.isNotEmpty ? _activeRoster.first.id : null);
      _sprinterId = widget.sprinterRiderId ??
          (_activeRoster.length > 1 ? _activeRoster.last.id : null);
    }

    if (widget.initialMode != null) {
      _mode = widget.initialMode!;
    } else if (_activeRoster.isNotEmpty && _activeTeam != null) {
      _mode = ShareCardMode.teamRoster;
    } else if (_activeRider != null || _activeProState != null) {
      _mode = ShareCardMode.beAProRider;
    } else {
      _mode = ShareCardMode.teamRoster;
    }
  }

  void _loadShowcaseData() {
    final showcase = _ShowcaseShareData.build();
    _activeTeam = showcase.team;
    _activeRoster = showcase.roster;
    _activeProState = showcase.proState;
    _activeRider = showcase.proState.playerRider;
    _leaderId = showcase.roster.first.id;
    _sprinterId = showcase.roster.last.id;
  }

  bool get _hasTeamData => _activeTeam != null && _activeRoster.isNotEmpty;
  bool get _hasRiderData => _activeRider != null || _activeProState != null;

  void _regenerateBundle() {
    if (_mode == ShareCardMode.teamRoster && _hasTeamData) {
      _exportBundle = _transferService.exportTeamRaceRoster(
        team: _activeTeam!,
        raceRoster: _activeRoster,
        leaderRiderId: _leaderId,
        sprinterRiderId: _sprinterId,
        raceTitle: widget.raceTitle,
        seasonYear: widget.seasonYear,
        errorCorrectionLevel: _ecLevel,
      );
    } else if (_mode == ShareCardMode.beAProRider && _hasRiderData) {
      final proState = _activeProState ?? _synthesizeProState(_activeRider!);
      _exportBundle = _transferService.exportBeAProProfile(
        careerState: proState,
        errorCorrectionLevel: _ecLevel,
        includeFullCareerState: false,
      );
    } else {
      _exportBundle = null;
    }
  }

  ProCyclistCareerState _synthesizeProState(Rider rider) {
    final now = DateTime(widget.seasonYear, 7, 1);
    return ProCyclistCareerState(
      careerId: 'card_${rider.id}',
      careerName: _activeTeam?.name ?? 'Pro Peloton Profile',
      playerRider: rider,
      currentDate: now,
      careerStartDate: DateTime(widget.seasonYear - 2, 1, 1),
      seasonYear: widget.seasonYear,
      currentTeamId: _activeTeam?.id ?? 'team_free',
      currentTeamName: _activeTeam?.name ?? 'Niezależny Kolarz',
      currentDivision: _activeTeam?.division ?? TeamDivision.worldTour,
      careerTier: ProCyclistCareerTier.worldTourLeader,
      dsTrustScore: 86.0,
      skillPoints: 4,
      experienceXp: 4200,
      careerLevel: 18,
      privateBalanceEur: 320000,
      careerEarningsEur: 1250000,
      fameScore: 78.0,
      fanFollowersCount: 145000,
      palmares: const ProCyclistPalmares(
        careerWins: 19,
        grandTourStageWins: 4,
        monumentWins: 1,
      ),
    );
  }

  void _setMode(ShareCardMode nextMode) {
    if (_mode == nextMode) return;
    if (nextMode == ShareCardMode.teamRoster && !_hasTeamData) return;
    if (nextMode == ShareCardMode.beAProRider && !_hasRiderData) return;
    setState(() {
      _mode = nextMode;
      _copiedToken = false;
      _copiedSummary = false;
      _regenerateBundle();
    });
  }

  void _setEcLevel(TransferQrErrorCorrectionLevel level) {
    if (_ecLevel == level) return;
    setState(() {
      _ecLevel = level;
      _regenerateBundle();
    });
  }

  Future<void> _copyTransferToken() async {
    final token = _exportBundle?.token;
    if (token == null || token.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;

    _copiedTokenTimer?.cancel();
    setState(() {
      _copiedToken = true;
    });
    _copiedTokenTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() {
          _copiedToken = false;
        });
      }
    });
  }

  Future<void> _copyOvrSummary() async {
    final bundle = _exportBundle;
    if (bundle == null) return;

    final buffer = StringBuffer();
    if (_mode == ShareCardMode.teamRoster && _hasTeamData) {
      final stats = ShareCardOvrStats.fromRiders(_activeRoster);
      buffer.writeln(
        '${_activeTeam!.name} (${_activeTeam!.division.label}) — ${widget.raceTitle} ${widget.seasonYear}',
      );
      buffer.writeln(
        'Śr. OVR: ${stats.averageOvr} | Szczyt OVR: ${stats.peakOvr} | Śr. FTP: ${stats.averageWkg.toStringAsFixed(2)} W/kg',
      );
      for (final r in _activeRoster.take(8)) {
        final role = r.id == _leaderId
            ? ' [LIDER]'
            : (r.id == _sprinterId ? ' [SPRINTER]' : '');
        buffer.writeln(
          '• ${r.fullName} (${r.nationalityIso}) — OVR ${r.overallRating} | ${r.physiology.wattsPerKg.toStringAsFixed(2)} W/kg$role',
        );
      }
    } else if (_activeRider != null) {
      final r = _activeRider!;
      buffer.writeln(
        '${r.fullName} (${r.nationalityIso}) — ${r.specialization.displayName}',
      );
      buffer.writeln(
        'OVR: ${r.overallRating} | POT: ${r.potential} | FTP: ${r.physiology.ftpWatts} W (${r.physiology.wattsPerKg.toStringAsFixed(2)} W/kg)',
      );
    }
    buffer.writeln('Kod transferowy: ${bundle.token}');

    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    if (!mounted) return;

    _copiedSummaryTimer?.cancel();
    setState(() {
      _copiedSummary = true;
    });
    _copiedSummaryTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() {
          _copiedSummary = false;
        });
      }
    });
  }

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handleClose,
      },
      child: Focus(
        autofocus: true,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                final isMobile = width < 680;
                final isTablet = width >= 680 && width < 1100;

                final double modalWidth = isMobile
                    ? (width - 24).clamp(280.0, 520.0)
                    : isTablet
                        ? math.min(920.0, width - 48)
                        : math.min(1040.0, width - 64);

                final double maxModalHeight = isMobile
                    ? math.max(320.0, height - 32)
                    : math.min(820.0, height - 48);

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: modalWidth,
                    maxHeight: maxModalHeight,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.cardBorder,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.65),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModalHeader(isMobile),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.cardBorder,
                          ),
                          Flexible(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(isMobile ? 16 : 24),
                              child: _exportBundle == null
                                  ? _buildEmptyState()
                                  : (isMobile
                                      ? _buildMobileBody()
                                      : _buildDesktopTabletBody()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 14 : 18,
      ),
      color: AppColors.background,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _themeStyle.accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _themeStyle.accentColor.withValues(alpha: 0.45),
              ),
            ),
            child: Icon(
              Icons.qr_code_2_rounded,
              color: _themeStyle.accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Karta Wizytówki i Transfer QR',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _mode == ShareCardMode.teamRoster
                      ? 'Udostępnij skład wyścigowy, oceny OVR i kod transferowy'
                      : 'Udostępnij profil kolarza, statystyki OVR i token Be a Pro',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _InteractiveIconButton(
            tooltip: 'Zamknij (Esc)',
            icon: Icons.close_rounded,
            onPressed: _handleClose,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.qr_code_scanner_rounded,
            size: 44,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Brak aktywnego składu lub profilu kolarza do udostępnienia',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Wybierz kolarzy do składu wyścigowego lub załaduj przykładową wizytówkę podglądową.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          _InteractiveModalButton(
            label: 'Załaduj wizytówkę pokazową',
            icon: Icons.auto_awesome_rounded,
            accentColor: AppColors.goldAccent,
            isPrimary: true,
            onPressed: () {
              setState(() {
                _loadShowcaseData();
                _mode = ShareCardMode.teamRoster;
                _regenerateBundle();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildControlsBar(isCompact: true),
        const SizedBox(height: 16),
        _buildBusinessCardPreview(),
        const SizedBox(height: 16),
        _buildQrAndClipboardPanel(isCompact: true),
      ],
    );
  }

  Widget _buildDesktopTabletBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildControlsBar(isCompact: false),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 12,
              child: _buildBusinessCardPreview(),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 10,
              child: _buildQrAndClipboardPanel(isCompact: false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlsBar({required bool isCompact}) {
    final modeButtons = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ShareCardMode.values.map((m) {
        final enabled = m == ShareCardMode.teamRoster
            ? _hasTeamData
            : _hasRiderData;
        return _InteractiveChip(
          label: m.label,
          icon: m.icon,
          selected: _mode == m,
          enabled: enabled,
          accentColor: _themeStyle.accentColor,
          onTap: () => _setMode(m),
        );
      }).toList(),
    );

    final styleChips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ShareCardThemeStyle.values.map((style) {
        return _InteractiveChip(
          label: style.label,
          dotColor: style.accentColor,
          selected: _themeStyle == style,
          enabled: true,
          accentColor: style.accentColor,
          onTap: () => setState(() => _themeStyle = style),
        );
      }).toList(),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          modeButtons,
          const SizedBox(height: 10),
          styleChips,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: modeButtons),
        const SizedBox(width: 12),
        Flexible(child: styleChips),
      ],
    );
  }

  Widget _buildBusinessCardPreview() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _themeStyle.accentColor.withValues(alpha: 0.45),
          width: 1.0,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceLight,
            AppColors.background,
            _themeStyle.accentColor.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardTopBanner(),
          Padding(
            padding: const EdgeInsets.all(18),
            child: _mode == ShareCardMode.teamRoster && _hasTeamData
                ? _buildTeamCardContent()
                : _buildRiderCardContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTopBanner() {
    final teamPrimary = _parseHexColor(
      _activeTeam?.primaryJerseyColorHex,
      _themeStyle.accentColor,
    );
    final teamSecondary = _parseHexColor(
      _activeTeam?.secondaryJerseyColorHex,
      AppColors.surface,
    );
    final teamAccent = _parseHexColor(
      _activeTeam?.accentJerseyColorHex,
      _themeStyle.secondaryAccentColor,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        border: const Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        gradient: LinearGradient(
          colors: [
            teamPrimary.withValues(alpha: 0.28),
            AppColors.surface,
          ],
        ),
      ),
      child: Row(
        children: [
          _JerseyEmblemBadge(
            primary: teamPrimary,
            secondary: teamSecondary,
            accent: teamAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _mode == ShareCardMode.teamRoster
                      ? (_activeTeam?.name ?? 'Pro Peloton Team')
                      : (_activeRider?.fullName ?? 'Kolarz Pro'),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MiniBadge(
                      label: _activeTeam?.division.label ?? 'UCI WorldTour',
                      color: _themeStyle.accentColor,
                    ),
                    Text(
                      _mode == ShareCardMode.teamRoster
                          ? '${widget.raceTitle} • ${widget.seasonYear}'
                          : '${_activeRider?.nationalityIso ?? 'POL'} • ${_activeRider?.specialization.displayName ?? ''}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCardContent() {
    final stats = ShareCardOvrStats.fromRiders(_activeRoster);
    final team = _activeTeam!;
    final displayedRiders = _activeRoster.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _OvrHeroTile(
              value: '${stats.averageOvr}',
              label: 'ŚR. OVR',
              accentColor: _themeStyle.accentColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricTile(
                    label: 'SZCZYT OVR',
                    value: '${stats.peakOvr}',
                    valueColor: AppColors.goldAccent,
                  ),
                  _MetricTile(
                    label: 'ŚR. FTP',
                    value: '${stats.averageWkg.toStringAsFixed(2)} W/kg',
                    valueColor: AppColors.cyanAccent,
                  ),
                  _MetricTile(
                    label: 'PKT UCI',
                    value: '${team.uciPointsSeason}',
                    valueColor: AppColors.statusSuccess,
                  ),
                  _MetricTile(
                    label: 'SKŁAD',
                    value: '${_activeRoster.length} kol.',
                    valueColor: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildOvrBreakdownGrid(stats),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'KLUCZOWI KOLARZE SKŁADU',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.textSecondary,
              ),
            ),
            if (_activeRoster.length > displayedRiders.length)
              Text(
                '+${_activeRoster.length - displayedRiders.length} w karcie',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...displayedRiders.map((rider) {
          final isLeader = rider.id == _leaderId;
          final isSprinter = rider.id == _sprinterId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _RiderRosterCompactRow(
              rider: rider,
              isLeader: isLeader,
              isSprinter: isSprinter,
              accentColor: _themeStyle.accentColor,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRiderCardContent() {
    final rider = _activeRider!;
    final stats = ShareCardOvrStats.fromRiders([rider]);
    final palmares = _activeProState?.palmares;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _OvrHeroTile(
              value: '${rider.overallRating}',
              label: 'OVR',
              accentColor: _themeStyle.accentColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricTile(
                    label: 'POTENCJAŁ',
                    value: '${rider.potential}',
                    valueColor: AppColors.goldAccent,
                  ),
                  _MetricTile(
                    label: 'FTP',
                    value:
                        '${rider.physiology.ftpWatts} W (${rider.physiology.wattsPerKg.toStringAsFixed(2)})',
                    valueColor: AppColors.cyanAccent,
                  ),
                  _MetricTile(
                    label: 'SPRINT 5S',
                    value: '${rider.powerProfile.watts5s} W',
                    valueColor: AppColors.amberWarning,
                  ),
                  _MetricTile(
                    label: 'VO2MAX',
                    value: rider.physiology.vo2Max.toStringAsFixed(1),
                    valueColor: AppColors.statusSuccess,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildOvrBreakdownGrid(stats),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CompactStatPair(
                label: 'Wiek',
                value: '${rider.age} lat',
              ),
              _CompactStatPair(
                label: 'Wzrost / Waga',
                value:
                    '${rider.physiology.heightCm.round()} cm / ${rider.physiology.weightKg.toStringAsFixed(1)} kg',
              ),
              _CompactStatPair(
                label: palmares != null ? 'Zwycięstwa' : 'Pkt UCI',
                value: palmares != null
                    ? '${palmares.careerWins}'
                    : '${rider.careerPointsUci}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOvrBreakdownGrid(ShareCardOvrStats stats) {
    final items = [
      ('GÓRY', stats.climbScore, AppColors.statusSuccess),
      ('SPRINT', stats.sprintScore, AppColors.amberWarning),
      ('TT', stats.timeTrialScore, AppColors.accentBlue),
      ('BRUKI', stats.cobblesScore, AppColors.primaryAccent),
      ('PUNCH', stats.punchScore, AppColors.goldAccent),
      ('RACE IQ', stats.raceIqScore, AppColors.cyanAccent),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROFIL STATYSTYK OVR',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: items.map((entry) {
              return SizedBox(
                width: 130,
                child: _StatProgressBar(
                  label: entry.$1,
                  score: entry.$2,
                  color: entry.$3,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQrAndClipboardPanel({required bool isCompact}) {
    final bundle = _exportBundle!;
    final qrMatrix = bundle.qrMatrix;
    final token = bundle.token;
    final truncatedToken = token.length > 72
        ? '${token.substring(0, 44)}...${token.substring(token.length - 18)}'
        : token;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Text(
                'KOD QR TRANSFERU',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.textSecondary,
                ),
              ),
              _MiniBadge(
                label: 'QR v${qrMatrix.version} • ${qrMatrix.size}x${qrMatrix.size}',
                color: AppColors.accentBlue,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _themeStyle.accentColor.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: SizedBox(
                width: isCompact ? 176 : 196,
                height: isCompact ? 176 : 196,
                child: CustomPaint(
                  painter: QrCodeMatrixPainter(
                    matrix: qrMatrix,
                    moduleColor: AppColors.background,
                    backgroundColor: AppColors.textPrimary,
                    finderAccentColor: _themeStyle.accentColor == AppColors.goldAccent
                        ? AppColors.primaryAccent
                        : _themeStyle.accentColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              const Text(
                'Korekcja ECC:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              ...TransferQrErrorCorrectionLevel.values.map((level) {
                return _InteractiveChip(
                  label: level.code,
                  selected: _ecLevel == level,
                  enabled: true,
                  accentColor: _themeStyle.accentColor,
                  compact: true,
                  onTap: () => _setEcLevel(level),
                );
              }),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'TOKEN (${bundle.envelope.compressedBytes} B • CRC ${bundle.envelope.checksumHex})',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: AppColors.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _InteractiveTextAction(
                      label: _showFullToken ? 'Zwiń' : 'Rozwiń',
                      onTap: () =>
                          setState(() => _showFullToken = !_showFullToken),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(
                  _showFullToken ? token : truncatedToken,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    height: 1.35,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _InteractiveModalButton(
            label: _copiedToken
                ? 'Skopiowano kod transferowy!'
                : 'Kopiuj kod transferowy do schowka',
            icon: _copiedToken ? Icons.check_circle_rounded : Icons.copy_rounded,
            accentColor:
                _copiedToken ? AppColors.statusSuccess : _themeStyle.accentColor,
            isPrimary: true,
            onPressed: _copyTransferToken,
          ),
          const SizedBox(height: 8),
          _InteractiveModalButton(
            label: _copiedSummary
                ? 'Skopiowano wizytówkę OVR!'
                : 'Kopiuj podsumowanie OVR + kod',
            icon: _copiedSummary
                ? Icons.check_rounded
                : Icons.share_rounded,
            accentColor: AppColors.accentBlue,
            isPrimary: false,
            onPressed: _copyOvrSummary,
          ),
        ],
      ),
    );
  }

  Color _parseHexColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final clean = hex.replaceFirst('#', '').trim();
    if (clean.length != 6 && clean.length != 8) return fallback;
    final parsed = int.tryParse(clean.length == 6 ? 'FF$clean' : clean, radix: 16);
    if (parsed == null) return fallback;
    return Color(parsed);
  }
}

class _OvrHeroTile extends StatelessWidget {
  final String value;
  final String label;
  final Color accentColor;

  const _OvrHeroTile({
    required this.value,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.55)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.05,
              color: accentColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
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
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatProgressBar extends StatelessWidget {
  final String label;
  final int score;
  final Color color;

  const _StatProgressBar({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = (score / 99.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$score',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: 5,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _RiderRosterCompactRow extends StatelessWidget {
  final Rider rider;
  final bool isLeader;
  final bool isSprinter;
  final Color accentColor;

  const _RiderRosterCompactRow({
    required this.rider,
    required this.isLeader,
    required this.isSprinter,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLeader
              ? accentColor.withValues(alpha: 0.45)
              : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${rider.overallRating}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: accentColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rider.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${rider.nationalityIso} • ${rider.specialization.displayName}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isLeader)
            const _MiniBadge(label: 'LIDER', color: AppColors.goldAccent)
          else if (isSprinter)
            const _MiniBadge(label: 'SPR', color: AppColors.amberWarning),
          const SizedBox(width: 8),
          Text(
            '${rider.physiology.wattsPerKg.toStringAsFixed(2)} W/kg',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.cyanAccent,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _JerseyEmblemBadge extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final Color accent;

  const _JerseyEmblemBadge({
    required this.primary,
    required this.secondary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent, width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, secondary],
        ),
      ),
      child: Icon(
        Icons.directions_bike_rounded,
        color: accent,
        size: 22,
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
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

class _CompactStatPair extends StatelessWidget {
  final String label;
  final String value;

  const _CompactStatPair({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Przycisk modalny z pełnymi stanami `hover`, `active`, `focus` oraz `disabled`.
class _InteractiveModalButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const _InteractiveModalButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  State<_InteractiveModalButton> createState() =>
      _InteractiveModalButtonState();
}

class _InteractiveModalButtonState extends State<_InteractiveModalButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final bgColor = !enabled
        ? AppColors.surface
        : widget.isPrimary
            ? (_pressed
                ? widget.accentColor.withValues(alpha: 0.85)
                : (_hovered
                    ? widget.accentColor.withValues(alpha: 0.94)
                    : widget.accentColor))
            : (_pressed
                ? widget.accentColor.withValues(alpha: 0.22)
                : (_hovered
                    ? widget.accentColor.withValues(alpha: 0.14)
                    : AppColors.surface));

    final fgColor = !enabled
        ? AppColors.textSecondary
        : widget.isPrimary
            ? AppColors.background
            : AppColors.textPrimary;

    return Focus(
      onFocusChange: (val) => setState(() => _focused = val),
      child: MouseRegion(
        cursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : (widget.isPrimary
                        ? widget.accentColor
                        : (_hovered
                            ? widget.accentColor.withValues(alpha: 0.65)
                            : AppColors.cardBorder)),
                width: _focused ? 1.8 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 17, color: fgColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: fgColor,
                    ),
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

class _InteractiveChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color? dotColor;
  final bool selected;
  final bool enabled;
  final Color accentColor;
  final bool compact;
  final VoidCallback onTap;

  const _InteractiveChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.accentColor,
    required this.onTap,
    this.icon,
    this.dotColor,
    this.compact = false,
  });

  @override
  State<_InteractiveChip> createState() => _InteractiveChipState();
}

class _InteractiveChipState extends State<_InteractiveChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = !widget.enabled
        ? AppColors.surface.withValues(alpha: 0.45)
        : widget.selected
            ? widget.accentColor.withValues(alpha: _pressed ? 0.28 : 0.18)
            : (_hovered ? AppColors.surfaceLight : AppColors.background);

    final borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : _focused
            ? AppColors.goldAccent
            : widget.selected
                ? widget.accentColor
                : (_hovered
                    ? widget.accentColor.withValues(alpha: 0.5)
                    : AppColors.cardBorder);

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
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
              horizontal: widget.compact ? 9 : 12,
              vertical: widget.compact ? 5 : 7,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: _focused ? 1.6 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 14,
                    color: widget.enabled
                        ? (widget.selected
                            ? widget.accentColor
                            : AppColors.textSecondary)
                        : AppColors.textSecondary.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 6),
                ] else if (widget.dotColor != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: widget.compact ? 11 : 12,
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.enabled
                        ? (widget.selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary)
                        : AppColors.textSecondary.withValues(alpha: 0.45),
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

class _InteractiveIconButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _InteractiveIconButton({
    required this.tooltip,
    required this.icon,
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
      child: Focus(
        onFocusChange: (v) => setState(() => _focused = v),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() {
            _hovered = false;
            _pressed = false;
          }),
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
                    ? AppColors.primaryAccent.withValues(alpha: 0.25)
                    : (_hovered ? AppColors.surfaceLight : AppColors.surface),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _focused
                      ? AppColors.goldAccent
                      : (_hovered
                          ? AppColors.textSecondary
                          : AppColors.cardBorder),
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
      ),
    );
  }
}

class _InteractiveTextAction extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _InteractiveTextAction({
    required this.label,
    required this.onTap,
  });

  @override
  State<_InteractiveTextAction> createState() => _InteractiveTextActionState();
}

class _InteractiveTextActionState extends State<_InteractiveTextAction> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: _focused
                  ? Border.all(color: AppColors.goldAccent)
                  : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _hovered ? AppColors.goldAccent : AppColors.accentBlue,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShowcaseShareData {
  final CyclingTeam team;
  final List<Rider> roster;
  final ProCyclistCareerState proState;

  const _ShowcaseShareData({
    required this.team,
    required this.roster,
    required this.proState,
  });

  static _ShowcaseShareData build() {
    Rider buildRider({
      required String id,
      required String firstName,
      required String lastName,
      required String iso,
      required RiderSpecialization spec,
      required int ftp,
      required double weight,
      required int sprint5s,
      required int potential,
    }) {
      return Rider(
        id: id,
        firstName: firstName,
        lastName: lastName,
        nationalityIso: iso,
        birthDate: DateTime(1999, 5, 14),
        potential: potential,
        specialization: spec,
        physiology: RiderPhysiology(
          heightCm: 179.0,
          weightKg: weight,
          bodyFatPercentage: 6.2,
          ftpWatts: ftp,
          wPrimeJoules: 21500,
          vo2Max: 84.5,
          maxHr: 194,
          restingHr: 39,
          lactateThresholdHr: 175,
          recoveryRate: 0.91,
          glycogenCapacityGrams: 540,
        ),
        powerProfile: RiderPowerProfile(
          watts5s: sprint5s,
          watts15s: (sprint5s * 0.84).round(),
          watts30s: (sprint5s * 0.68).round(),
          watts1m: (ftp * 1.62).round(),
          watts3m: (ftp * 1.28).round(),
          watts5m: (ftp * 1.24).round(),
          watts20m: (ftp * 1.05).round(),
          watts60m: (ftp * 0.94).round(),
        ),
        skills: const RiderSkills(
          cobbles: 78,
          descending: 84,
          bikeHandling: 86,
          aeroPositioning: 85,
          draftingEfficiency: 84,
          raceIq: 88,
          rainResistance: 80,
          heatTolerance: 82,
          timeTrialPositioning: 83,
        ),
        appearance: const RiderAppearance(
          faceShapeIndex: 2,
          skinToneHex: '#E0B596',
          hairStyleIndex: 4,
          hairColorHex: '#2B221C',
          facialHairIndex: 1,
          glassesModelId: 'aero_pro_gold',
          glassesLensColorHex: '#D4AF37',
          helmetModelId: 'obsidian_aero_v4',
          shoeColorHex: '#F3F4F6',
          sockHeightProportion: 0.72,
          bodyBuildType: BodyBuildType.climberLean,
        ),
        contract: const RiderContract(
          teamId: 'team_obsidian',
          role: RiderRole.teamLeader,
          monthlySalaryEur: 75000,
          signingBonusEur: 120000,
          winBonusEur: 25000,
          releaseClauseEur: 4500000,
          contractEndYear: 2028,
          morale: 0.92,
          leaderLoyalty: 0.90,
          requiredRacesIds: ['tour_de_france'],
        ),
        health: const RiderHealth(
          acuteTrainingLoad: 74.0,
          chronicTrainingLoad: 92.0,
        ),
        careerPointsUci: 1840,
      );
    }

    final roster = [
      buildRider(
        id: 'r_1',
        firstName: 'Kacper',
        lastName: 'Majewski',
        iso: 'POL',
        spec: RiderSpecialization.gcClimber,
        ftp: 425,
        weight: 64.5,
        sprint5s: 1120,
        potential: 94,
      ),
      buildRider(
        id: 'r_2',
        firstName: 'Mateo',
        lastName: 'Alvarez',
        iso: 'ESP',
        spec: RiderSpecialization.pureClimber,
        ftp: 395,
        weight: 60.2,
        sprint5s: 990,
        potential: 89,
      ),
      buildRider(
        id: 'r_3',
        firstName: 'Lukas',
        lastName: 'Vermeer',
        iso: 'NED',
        spec: RiderSpecialization.timeTrialist,
        ftp: 445,
        weight: 73.0,
        sprint5s: 1260,
        potential: 88,
      ),
      buildRider(
        id: 'r_4',
        firstName: 'Julien',
        lastName: 'Moreau',
        iso: 'FRA',
        spec: RiderSpecialization.pureSprinter,
        ftp: 395,
        weight: 74.5,
        sprint5s: 1620,
        potential: 91,
      ),
    ];

    final team = CyclingTeam(
      id: 'team_obsidian',
      name: 'Obsidian Sovereign Cycling',
      division: TeamDivision.worldTour,
      countryIso: 'POL',
      primaryJerseyColorHex: '#8E4A49',
      secondaryJerseyColorHex: '#181B22',
      accentJerseyColorHex: '#D4AF37',
      cashBalanceEur: 12400000,
      monthlyBurnRateEur: 840000,
      uciPointsSeason: 6820,
      rosterRiderIds: roster.map((r) => r.id).toList(),
      staff: const TeamStaff(
        trainersLevel: 90,
        sportsDirectorsLevel: 92,
        doctorsLevel: 88,
        mechanicsLevel: 89,
        scoutsLevel: 86,
      ),
      bikeDeal: const BikeManufacturerDeal(
        manufacturerId: 'bike_obsidian',
        manufacturerName: 'Sovereign Carbon Works',
        prestigeLevel: 5,
        annualCashContributionEur: 1200000,
        freeBikesQuota: 32,
        researchAndDevelopmentLevel: 92,
        suppliedFrameIds: ['sovereign_sl8'],
        suppliedWheelsetIds: ['sovereign_aero_55'],
        contractYearsLeft: 2,
        minimumUciRankingRequired: 10,
      ),
      sponsors: const [],
      inventoryBikes: const [],
    );

    final proState = ProCyclistCareerState(
      careerId: 'showcase_bap',
      careerName: 'Droga po Żółtą Koszulkę',
      playerRider: roster.first,
      currentDate: DateTime(2026, 7, 12),
      careerStartDate: DateTime(2023, 1, 1),
      seasonYear: 2026,
      currentTeamId: team.id,
      currentTeamName: team.name,
      currentDivision: team.division,
      careerTier: ProCyclistCareerTier.worldTourLeader,
      dsTrustScore: 91.0,
      skillPoints: 5,
      experienceXp: 6400,
      careerLevel: 24,
      privateBalanceEur: 620000,
      careerEarningsEur: 2450000,
      fameScore: 86.0,
      fanFollowersCount: 280000,
      palmares: const ProCyclistPalmares(
        careerWins: 19,
        grandTourStageWins: 4,
        monumentWins: 1,
      ),
    );

    return _ShowcaseShareData(
      team: team,
      roster: roster,
      proState: proState,
    );
  }
}
