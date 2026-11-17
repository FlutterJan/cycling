import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_appearance.dart';
import '../../models/team/cycling_team.dart';
import '../../services/career/national_championships_and_worlds_service.dart';
import 'rider_avatar_painter.dart';

/// Typ Wielkiego Touru dla odznak zwycięstw na karcie kolekcjonerskiej.
enum GrandTourType {
  tourDeFrance,
  giroDItalia,
  vueltaAEspana;

  String get shortCode {
    switch (this) {
      case GrandTourType.tourDeFrance:
        return 'TDF';
      case GrandTourType.giroDItalia:
        return 'GIRO';
      case GrandTourType.vueltaAEspana:
        return 'VUELTA';
    }
  }

  String get fullName {
    switch (this) {
      case GrandTourType.tourDeFrance:
        return 'Tour de France';
      case GrandTourType.giroDItalia:
        return "Giro d'Italia";
      case GrandTourType.vueltaAEspana:
        return 'Vuelta a España';
    }
  }

  Color get jerseyColor {
    switch (this) {
      case GrandTourType.tourDeFrance:
        return AppColors.goldAccent;
      case GrandTourType.giroDItalia:
        return const Color(0xFFEC4899);
      case GrandTourType.vueltaAEspana:
        return AppColors.crimsonAlert;
    }
  }

  String toJson() => name;

  static GrandTourType fromJson(String value) {
    return GrandTourType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GrandTourType.tourDeFrance,
    );
  }
}

/// Odznaka wygranego Wielkiego Touru na karcie kolekcjonerskiej.
@immutable
class GrandTourWinBadge {
  final GrandTourType tour;
  final List<int> years;

  const GrandTourWinBadge({
    required this.tour,
    required this.years,
  });

  int get count => years.length;

  Map<String, dynamic> toJson() => {
        'tour': tour.toJson(),
        'years': years,
      };

  factory GrandTourWinBadge.fromJson(Map<String, dynamic> json) {
    final rawYears = json['years'] as List<dynamic>? ?? const [];
    return GrandTourWinBadge(
      tour: GrandTourType.fromJson(json['tour'] as String? ?? 'tourDeFrance'),
      years: rawYears.map((e) => (e as num).toInt()).toList(),
    );
  }
}

/// Wektor pochylenia karty w przestrzeni znormalizowanej [-1.0, 1.0]
/// używany przez mysz (PC) lub żyroskop / gest dotyku (mobile).
@immutable
class HoloTiltSample {
  /// Pochylenie poziome: -1.0 (lewo) .. +1.0 (prawo).
  final double x;

  /// Pochylenie pionowe: -1.0 (góra) .. +1.0 (dół).
  final double y;

  const HoloTiltSample(this.x, this.y);

  static const HoloTiltSample zero = HoloTiltSample(0.0, 0.0);

  HoloTiltSample clamped() => HoloTiltSample(
        x.clamp(-1.0, 1.0),
        y.clamp(-1.0, 1.0),
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HoloTiltSample && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}

/// Ranga wizualna karty wynikająca z oceny ogólnej OVR.
enum ProRiderCardTier {
  /// Kolarze elitarni OVR >= 90: metaliczno-złota rama Topps Chrome Gold Refractor.
  goldLegend,

  /// Kolarze WorldTour OVR 82..89: chromowo-srebrna rama.
  chromeSilver,

  /// Kolarze Pro / rozwojowi OVR < 82: ciemny karbon z burgundowym akcentem.
  carbonPro;

  static ProRiderCardTier fromOvr(int ovr) {
    if (ovr >= 90) return ProRiderCardTier.goldLegend;
    if (ovr >= 82) return ProRiderCardTier.chromeSilver;
    return ProRiderCardTier.carbonPro;
  }

  String get label {
    switch (this) {
      case ProRiderCardTier.goldLegend:
        return 'GOLD REFRACTOR';
      case ProRiderCardTier.chromeSilver:
        return 'CHROME PRISM';
      case ProRiderCardTier.carbonPro:
        return 'PRO EDITION';
    }
  }
}

/// 6 głównych statystyk wyświetlanych na karcie Ultimate Team / Topps Chrome.
@immutable
class ProRiderCardStats {
  final int mon; // Mountain / Góry
  final int hil; // Hills / Pagórki
  final int itt; // Individual Time Trial / Czasówka
  final int spr; // Sprint
  final int cob; // Cobbles / Bruki
  final int rec; // Recovery / Regeneracja

  const ProRiderCardStats({
    required this.mon,
    required this.hil,
    required this.itt,
    required this.spr,
    required this.cob,
    required this.rec,
  });

  List<({String code, int value})> get orderedEntries => [
        (code: 'MON', value: mon.clamp(1, 99)),
        (code: 'HIL', value: hil.clamp(1, 99)),
        (code: 'ITT', value: itt.clamp(1, 99)),
        (code: 'SPR', value: spr.clamp(1, 99)),
        (code: 'COB', value: cob.clamp(1, 99)),
        (code: 'REC', value: rec.clamp(1, 99)),
      ];

  Map<String, dynamic> toJson() => {
        'mon': mon,
        'hil': hil,
        'itt': itt,
        'spr': spr,
        'cob': cob,
        'rec': rec,
      };

  factory ProRiderCardStats.fromJson(Map<String, dynamic> json) {
    return ProRiderCardStats(
      mon: (json['mon'] as num).toInt(),
      hil: (json['hil'] as num).toInt(),
      itt: (json['itt'] as num).toInt(),
      spr: (json['spr'] as num).toInt(),
      cob: (json['cob'] as num).toInt(),
      rec: (json['rec'] as num).toInt(),
    );
  }
}

/// Pełny model danych kolekcjonerskiej karty gwiazdy kolarstwa.
@immutable
class CollectibleProRiderCardData {
  final String riderId;
  final String fullName;
  final String shortRoleLabel;
  final String nationalityIso;
  final String teamName;
  final String teamShortCode;
  final int ovr;
  final int editionYear;
  final String cardSerialNumber;
  final ProRiderCardStats stats;
  final List<GrandTourWinBadge> grandTourWins;
  final RiderAppearance? appearance;
  final CyclingTeam? team;
  final SpecialJerseyDesignation specialJersey;
  final String? primaryJerseyColorHex;
  final String? secondaryJerseyColorHex;
  final String? accentJerseyColorHex;
  final String? customAutographText;

  const CollectibleProRiderCardData({
    required this.riderId,
    required this.fullName,
    required this.shortRoleLabel,
    required this.nationalityIso,
    required this.teamName,
    required this.teamShortCode,
    required this.ovr,
    required this.stats,
    this.editionYear = 2026,
    this.cardSerialNumber = '01/99',
    this.grandTourWins = const [],
    this.appearance,
    this.team,
    this.specialJersey = SpecialJerseyDesignation.standardTeamJersey,
    this.primaryJerseyColorHex,
    this.secondaryJerseyColorHex,
    this.accentJerseyColorHex,
    this.customAutographText,
  });

  ProRiderCardTier get tier => ProRiderCardTier.fromOvr(ovr);

  bool get isGoldLegend => ovr >= 90;

  int get totalGrandTourWins =>
      grandTourWins.fold<int>(0, (sum, badge) => sum + badge.count);

  /// Konstruktor konwertujący bezpośrednio model domenowy [Rider] na dane karty.
  factory CollectibleProRiderCardData.fromRider(
    Rider rider, {
    CyclingTeam? team,
    List<GrandTourWinBadge> grandTourWins = const [],
    SpecialJerseyDesignation specialJersey =
        SpecialJerseyDesignation.standardTeamJersey,
    int editionYear = 2026,
    String cardSerialNumber = '01/99',
  }) {
    final weight =
        rider.physiology.weightKg > 0.0 ? rider.physiology.weightKg : 70.0;
    final wKg20m = rider.powerProfile.watts20m / weight;
    final wKg5m = rider.powerProfile.watts5m / weight;
    final wKg1m = rider.powerProfile.watts1m / weight;

    final mon = ((wKg20m - 3.5) / (6.6 - 3.5) * 55 + 44).round().clamp(40, 99);
    final hil = ((((wKg5m - 4.5) / (8.0 - 4.5) * 55 + 44) * 0.55) +
            (((wKg1m - 6.5) / (12.0 - 6.5) * 55 + 44) * 0.45))
        .round()
        .clamp(40, 99);
    final itt = ((((rider.powerProfile.watts60m - 260.0) /
                    (470.0 - 260.0) *
                    55 +
                44) *
            0.7) +
            (rider.skills.timeTrialPositioning * 0.3))
        .round()
        .clamp(40, 99);
    final spr = ((rider.powerProfile.watts5s - 900.0) / (1750.0 - 900.0) * 55 +
            44)
        .round()
        .clamp(40, 99);
    final cob = rider.skills.cobbles.clamp(40, 99);
    final rec = rider.physiology.recoveryRate.round().clamp(40, 99);

    final roleShort = _mapRoleShort(rider.specialization);
    final teamTitle = team?.name ?? 'WorldTour Pro';
    final teamCode = _extractTeamCode(teamTitle);

    return CollectibleProRiderCardData(
      riderId: rider.id,
      fullName: rider.fullName,
      shortRoleLabel: roleShort,
      nationalityIso: rider.nationalityIso,
      teamName: teamTitle,
      teamShortCode: teamCode,
      ovr: rider.overallRating.clamp(40, 99),
      editionYear: editionYear,
      cardSerialNumber: cardSerialNumber,
      stats: ProRiderCardStats(
        mon: mon,
        hil: hil,
        itt: itt,
        spr: spr,
        cob: cob,
        rec: rec,
      ),
      grandTourWins: grandTourWins,
      appearance: rider.appearance,
      team: team,
      specialJersey: specialJersey,
      primaryJerseyColorHex: team?.primaryJerseyColorHex,
      secondaryJerseyColorHex: team?.secondaryJerseyColorHex,
      accentJerseyColorHex: team?.accentJerseyColorHex,
    );
  }

  static String _mapRoleShort(RiderSpecialization spec) {
    switch (spec) {
      case RiderSpecialization.gcClimber:
        return 'GC';
      case RiderSpecialization.pureClimber:
        return 'CLM';
      case RiderSpecialization.puncher:
        return 'PUN';
      case RiderSpecialization.classicCobbles:
        return 'CLX';
      case RiderSpecialization.pureSprinter:
      case RiderSpecialization.versatileSprinter:
        return 'SPR';
      case RiderSpecialization.timeTrialist:
        return 'ITT';
      case RiderSpecialization.domestiqueEngine:
        return 'DOM';
      case RiderSpecialization.breakawaySpecialist:
        return 'BRK';
    }
  }

  static String _extractTeamCode(String name) {
    final cleaned = name.trim().toUpperCase();
    if (cleaned.isEmpty) return 'PRO';
    final words = cleaned.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return words
          .take(3)
          .map((w) => w.isNotEmpty ? w[0] : '')
          .join()
          .padRight(3, 'X');
    }
    return cleaned.length >= 3 ? cleaned.substring(0, 3) : cleaned;
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'fullName': fullName,
        'shortRoleLabel': shortRoleLabel,
        'nationalityIso': nationalityIso,
        'teamName': teamName,
        'teamShortCode': teamShortCode,
        'ovr': ovr,
        'editionYear': editionYear,
        'cardSerialNumber': cardSerialNumber,
        'stats': stats.toJson(),
        'grandTourWins': grandTourWins.map((e) => e.toJson()).toList(),
        'specialJersey': specialJersey.name,
        'primaryJerseyColorHex': primaryJerseyColorHex,
        'secondaryJerseyColorHex': secondaryJerseyColorHex,
        'accentJerseyColorHex': accentJerseyColorHex,
        'customAutographText': customAutographText,
      };

  factory CollectibleProRiderCardData.fromJson(Map<String, dynamic> json) {
    final rawWins = json['grandTourWins'] as List<dynamic>? ?? const [];
    final jerseyName = json['specialJersey'] as String? ?? 'standardTeamJersey';
    return CollectibleProRiderCardData(
      riderId: json['riderId'] as String? ?? 'unknown',
      fullName: json['fullName'] as String? ?? 'Unknown Rider',
      shortRoleLabel: json['shortRoleLabel'] as String? ?? 'PRO',
      nationalityIso: json['nationalityIso'] as String? ?? 'INT',
      teamName: json['teamName'] as String? ?? 'Pro Team',
      teamShortCode: json['teamShortCode'] as String? ?? 'PRO',
      ovr: (json['ovr'] as num?)?.toInt() ?? 80,
      editionYear: (json['editionYear'] as num?)?.toInt() ?? 2026,
      cardSerialNumber: json['cardSerialNumber'] as String? ?? '01/99',
      stats: ProRiderCardStats.fromJson(
        json['stats'] as Map<String, dynamic>? ?? const {},
      ),
      grandTourWins: rawWins
          .map((e) => GrandTourWinBadge.fromJson(e as Map<String, dynamic>))
          .toList(),
      specialJersey: SpecialJerseyDesignation.values.firstWhere(
        (e) => e.name == jerseyName,
        orElse: () => SpecialJerseyDesignation.standardTeamJersey,
      ),
      primaryJerseyColorHex: json['primaryJerseyColorHex'] as String?,
      secondaryJerseyColorHex: json['secondaryJerseyColorHex'] as String?,
      accentJerseyColorHex: json['accentJerseyColorHex'] as String?,
      customAutographText: json['customAutographText'] as String?,
    );
  }
}

/// Kolekcjonerska karta gwiazdy kolarstwa w stylu Ultimate Team / Topps Chrome.
///
/// Obsługuje:
/// - metaliczno-złotą ramę dla kolarzy `OVR >= 90` (oraz chrom/karbon dla niższych rang),
/// - tęczowy holograficzny połysk (Shader/Gradient + refractor scanlines) reagujący
///   na ruch myszki na PC, przeciąganie na ekranie dotykowym lub opcjonalny strumień
///   żyroskopu [tiltStream] / [externalTilt] na telefonie,
/// - proceduralny portret kolarza ([RiderAvatarWidget] lub własny [portraitOverride]),
/// - 6 głównych statystyk (`MON, HIL, ITT, SPR, COB, REC`),
/// - kaligraficzny podpis autografu,
/// - odznaki wygranych Wielkich Tourów (`TDF`, `GIRO`, `VUELTA`),
/// - pełne stany `hover`, `active`, `focus`, `disabled` oraz responsywność `LayoutBuilder`.
class CollectibleProRiderHoloCard extends StatefulWidget {
  final CollectibleProRiderCardData data;

  /// Opcjonalny strumień z żyroskopu / akcelerometru na urządzeniach mobilnych.
  final Stream<HoloTiltSample>? tiltStream;

  /// Opcjonalne statyczne lub zewnętrznie sterowane pochylenie karty.
  final HoloTiltSample? externalTilt;

  /// Opcjonalny własny widżet portretu zastępujący domyślny [RiderAvatarWidget].
  final Widget? portraitOverride;

  /// Akcja po kliknięciu / aktywacji klawiaturą (`Enter` / `Space`).
  final VoidCallback? onTap;

  /// Czy karta jest interaktywna (false => pełny stan `disabled`).
  final bool enabled;

  /// Czy karta jest aktualnie zaznaczona / wybrana (np. w galerii lub składzie).
  final bool isSelected;

  /// Maksymalna szerokość karty (automatycznie skalowana przez [LayoutBuilder]).
  final double maxWidth;

  /// Czy włączyć delikatny animowany połysk w spoczynku.
  final bool enableAmbientShimmer;

  const CollectibleProRiderHoloCard({
    super.key,
    required this.data,
    this.tiltStream,
    this.externalTilt,
    this.portraitOverride,
    this.onTap,
    this.enabled = true,
    this.isSelected = false,
    this.maxWidth = 340.0,
    this.enableAmbientShimmer = true,
  });

  @override
  State<CollectibleProRiderHoloCard> createState() =>
      _CollectibleProRiderHoloCardState();
}

class _CollectibleProRiderHoloCardState
    extends State<CollectibleProRiderHoloCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  StreamSubscription<HoloTiltSample>? _tiltSubscription;

  HoloTiltSample _pointerTilt = HoloTiltSample.zero;
  HoloTiltSample _sensorTilt = HoloTiltSample.zero;

  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    if (widget.enableAmbientShimmer && widget.enabled) {
      _shimmerController.repeat();
    }
    _bindTiltStream();
  }

  @override
  void didUpdateWidget(covariant CollectibleProRiderHoloCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tiltStream != widget.tiltStream) {
      _tiltSubscription?.cancel();
      _bindTiltStream();
    }
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.enableAmbientShimmer != widget.enableAmbientShimmer) {
      if (widget.enabled && widget.enableAmbientShimmer) {
        if (!_shimmerController.isAnimating) {
          _shimmerController.repeat();
        }
      } else {
        _shimmerController.stop();
        if (!widget.enabled) {
          _isHovered = false;
          _isPressed = false;
          _pointerTilt = HoloTiltSample.zero;
        }
      }
    }
  }

  void _bindTiltStream() {
    _tiltSubscription = widget.tiltStream?.listen((sample) {
      if (!mounted || !widget.enabled) return;
      setState(() {
        _sensorTilt = sample.clamped();
      });
    });
  }

  @override
  void dispose() {
    _tiltSubscription?.cancel();
    _shimmerController.dispose();
    super.dispose();
  }

  HoloTiltSample get _effectiveTilt {
    if (!widget.enabled) return HoloTiltSample.zero;
    if (widget.externalTilt != null) return widget.externalTilt!.clamped();
    if (_isHovered || _isPressed) return _pointerTilt;
    return _sensorTilt;
  }

  void _updateTiltFromLocalPosition(Offset localPos, Size cardSize) {
    if (!widget.enabled || cardSize.width <= 0 || cardSize.height <= 0) return;
    final nx = ((localPos.dx / cardSize.width) * 2.0 - 1.0).clamp(-1.0, 1.0);
    final ny = ((localPos.dy / cardSize.height) * 2.0 - 1.0).clamp(-1.0, 1.0);
    setState(() {
      _pointerTilt = HoloTiltSample(nx, ny);
    });
  }

  void _resetPointerTilt() {
    if (!_isHovered && !_isPressed && _pointerTilt == HoloTiltSample.zero) {
      return;
    }
    setState(() {
      _isHovered = false;
      _isPressed = false;
      _pointerTilt = HoloTiltSample.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? math.min(constraints.maxWidth, widget.maxWidth)
            : widget.maxWidth;
        final cardWidth = availableWidth.clamp(220.0, widget.maxWidth);
        // Proporcja karty kolekcjonerskiej ~ 5 : 7.3 (Topps Chrome / UT)
        final rawHeight = cardWidth * 1.46;
        final cardHeight = constraints.hasBoundedHeight
            ? math.min(rawHeight, constraints.maxHeight)
            : rawHeight;
        final effectiveWidth = cardHeight / 1.46;
        final cardSize = Size(effectiveWidth, cardHeight);
        final isCompact = effectiveWidth < 260.0;

        final tilt = _effectiveTilt;
        final rotateY = tilt.x * 0.16;
        final rotateX = -tilt.y * 0.14;
        final scale = !widget.enabled
            ? 0.98
            : _isPressed
                ? 0.975
                : (_isHovered || _isFocused ? 1.025 : 1.0);

        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..rotateX(rotateX)
          ..rotateY(rotateY);

        return Semantics(
          button: widget.onTap != null,
          enabled: widget.enabled,
          selected: widget.isSelected,
          label:
              '${widget.data.fullName}, OVR ${widget.data.ovr}, ${widget.data.teamName}',
          child: FocusableActionDetector(
            enabled: widget.enabled,
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
                  if (widget.enabled) widget.onTap?.call();
                  return null;
                },
              ),
            },
            child: MouseRegion(
              cursor: widget.enabled && widget.onTap != null
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              onEnter: (_) {
                if (widget.enabled) setState(() => _isHovered = true);
              },
              onHover: (event) =>
                  _updateTiltFromLocalPosition(event.localPosition, cardSize),
              onExit: (_) => _resetPointerTilt(),
              child: GestureDetector(
                onTapDown: (_) {
                  if (widget.enabled) setState(() => _isPressed = true);
                },
                onTapUp: (_) {
                  if (widget.enabled) setState(() => _isPressed = false);
                },
                onTapCancel: () {
                  if (widget.enabled) setState(() => _isPressed = false);
                },
                onTap: widget.enabled ? widget.onTap : null,
                onPanStart: (details) {
                  if (!widget.enabled) return;
                  setState(() => _isPressed = true);
                  _updateTiltFromLocalPosition(details.localPosition, cardSize);
                },
                onPanUpdate: (details) {
                  if (!widget.enabled) return;
                  _updateTiltFromLocalPosition(details.localPosition, cardSize);
                },
                onPanEnd: (_) => _resetPointerTilt(),
                child: AnimatedScale(
                  scale: scale,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    width: effectiveWidth,
                    height: cardHeight,
                    transform: matrix,
                    transformAlignment: Alignment.center,
                    child: Opacity(
                      opacity: widget.enabled ? 1.0 : 0.48,
                      child: _buildCardShell(
                        context,
                        cardSize: cardSize,
                        tilt: tilt,
                        isCompact: isCompact,
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

  Widget _buildCardShell(
    BuildContext context, {
    required Size cardSize,
    required HoloTiltSample tilt,
    required bool isCompact,
  }) {
    final tier = widget.data.tier;
    final frameColors = _frameGradientColors(tier);
    final glowColor = tier == ProRiderCardTier.goldLegend
        ? AppColors.goldAccent
        : (tier == ProRiderCardTier.chromeSilver
            ? AppColors.accentBlue
            : AppColors.primaryAccent);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: _isHovered ? 28 : 18,
            offset: Offset(-tilt.x * 8, 10 + tilt.y * 6),
          ),
          if (widget.enabled &&
              (widget.data.isGoldLegend ||
                  _isHovered ||
                  _isFocused ||
                  widget.isSelected))
            BoxShadow(
              color: glowColor.withValues(
                alpha: _isFocused || widget.isSelected
                    ? 0.55
                    : (_isHovered ? 0.42 : 0.24),
              ),
              blurRadius: _isFocused || widget.isSelected ? 22 : 16,
              spreadRadius: _isFocused ? 2 : 0.5,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Zewnętrzna metaliczna rama (złota dla OVR >= 90)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.9 + tilt.x * 0.6, -1.0 + tilt.y * 0.5),
                  end: Alignment(0.9 + tilt.x * 0.6, 1.0 + tilt.y * 0.5),
                  colors: frameColors,
                  stops: const [0.0, 0.25, 0.5, 0.78, 1.0],
                ),
              ),
            ),

            // 2. Wewnętrzne ciemne tło karty (#0F1115 / #181B22)
            Padding(
              padding: EdgeInsets.all(isCompact ? 4.0 : 5.5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCardInteriorBackground(tier),
                    // 3. Tęczowy holograficzny shader/gradient pod spodem zawartości
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _HolographicFoilPainter(
                            tilt: tilt,
                            shimmerPhase: widget.enableAmbientShimmer &&
                                    widget.enabled
                                ? _shimmerController.value
                                : 0.25,
                            tier: tier,
                            intensity: !widget.enabled
                                ? 0.15
                                : (_isHovered || _isPressed ? 1.0 : 0.68),
                          ),
                        );
                      },
                    ),
                    // 4. Główna zawartość karty
                    _buildCardContent(
                      cardSize: cardSize,
                      isCompact: isCompact,
                      tier: tier,
                    ),
                    // 5. Delikatny odblask szkła Topps Chrome na wierzchu
                    IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _SpecularGlintPainter(
                              tilt: tilt,
                              shimmerPhase: _shimmerController.value,
                              enabled: widget.enabled,
                              isActive: _isHovered || _isPressed,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 6. Zewnętrzna ramka 1px dla precyzyjnego obrysu i stanu focus/selected
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isFocused
                        ? AppColors.cyanAccent
                        : (widget.isSelected
                            ? AppColors.goldAccent
                            : (widget.data.isGoldLegend
                                ? const Color(0xFFFFE58F).withValues(alpha: 0.75)
                                : AppColors.cardBorder)),
                    width: _isFocused || widget.isSelected ? 2.0 : 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _frameGradientColors(ProRiderCardTier tier) {
    switch (tier) {
      case ProRiderCardTier.goldLegend:
        return const [
          Color(0xFF9A7418),
          Color(0xFFD4AF37),
          Color(0xFFFFF3B0),
          Color(0xFFD4AF37),
          Color(0xFF7A5810),
        ];
      case ProRiderCardTier.chromeSilver:
        return const [
          Color(0xFF4B5563),
          Color(0xFFCBD5E1),
          Color(0xFFF8FAFC),
          Color(0xFF94A3B8),
          Color(0xFF334155),
        ];
      case ProRiderCardTier.carbonPro:
        return const [
          Color(0xFF2E3440),
          Color(0xFF8E4A49),
          Color(0xFF475569),
          Color(0xFF8E4A49),
          Color(0xFF181B22),
        ];
    }
  }

  Widget _buildCardInteriorBackground(ProRiderCardTier tier) {
    final accentTint = tier == ProRiderCardTier.goldLegend
        ? AppColors.goldAccent.withValues(alpha: 0.14)
        : (tier == ProRiderCardTier.chromeSilver
            ? AppColors.accentBlue.withValues(alpha: 0.12)
            : AppColors.primaryAccent.withValues(alpha: 0.16));

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.15, -0.35),
          radius: 1.05,
          colors: [
            Color.alphaBlend(accentTint, AppColors.surfaceLight),
            AppColors.surface,
            AppColors.background,
          ],
          stops: const [0.0, 0.52, 1.0],
        ),
      ),
    );
  }

  Widget _buildCardContent({
    required Size cardSize,
    required bool isCompact,
    required ProRiderCardTier tier,
  }) {
    final pad = isCompact ? 8.0 : 11.0;
    final portraitSize = (cardSize.width * 0.44).clamp(88.0, 148.0);
    final accentColor = tier == ProRiderCardTier.goldLegend
        ? AppColors.goldAccent
        : (tier == ProRiderCardTier.chromeSilver
            ? AppColors.accentBlue
            : AppColors.primaryAccent);

    return Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Górny pasek edycji / serii Topps Chrome
          Row(
            children: [
              _buildEditionChip(tier, accentColor, isCompact),
              const Spacer(),
              Text(
                '#${widget.data.cardSerialNumber}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 8.5 : 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),

          SizedBox(height: isCompact ? 4 : 6),

          // Sekcja główna: Lewy filar (OVR + Rola + Flaga + Drużyna) + Portret
          Expanded(
            flex: 11,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: isCompact ? 54 : 66,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${widget.data.ovr}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isCompact ? 28 : 34,
                          height: 0.95,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                          color: tier == ProRiderCardTier.goldLegend
                              ? const Color(0xFFFFF3B0)
                              : AppColors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.55),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          widget.data.shortRoleLabel,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: isCompact ? 9 : 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _CountryFlagChip(
                        isoCode: widget.data.nationalityIso,
                        compact: isCompact,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.data.teamShortCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isCompact ? 8.5 : 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Portret kolarza w ramce z efektem głębi
                Expanded(
                  child: Center(
                    child: _buildPortraitFrame(
                      size: portraitSize,
                      accentColor: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Nazwisko + Autograf
          Padding(
            padding: EdgeInsets.symmetric(vertical: isCompact ? 3 : 5),
            child: Column(
              children: [
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        accentColor.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isCompact ? 3 : 5),
                Text(
                  widget.data.fullName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 13 : 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                // Kaligraficzny podpis autografu
                SizedBox(
                  height: isCompact ? 20 : 25,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _RiderAutographPainter(
                      signatureSeed: widget.data.customAutographText ??
                          widget.data.fullName,
                      inkColor: tier == ProRiderCardTier.goldLegend
                          ? const Color(0xFFFFE58F)
                          : AppColors.cyanAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Siatka 6 głównych statystyk (MON, HIL, ITT, SPR, COB, REC)
          _buildStatsGrid(isCompact: isCompact),

          SizedBox(height: isCompact ? 5 : 7),

          // Dolny pasek: odznaki wygranych Wielkich Tourów + rok edycji
          _buildGrandTourBadgesRow(
            isCompact: isCompact,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildEditionChip(
    ProRiderCardTier tier,
    Color accentColor,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 5 : 7,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.55),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tier == ProRiderCardTier.goldLegend
                ? Icons.auto_awesome_rounded
                : Icons.bolt_rounded,
            size: isCompact ? 9 : 11,
            color: accentColor,
          ),
          const SizedBox(width: 4),
          Text(
            tier.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 7.5 : 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitFrame({
    required double size,
    required Color accentColor,
  }) {
    final portrait = widget.portraitOverride ??
        RiderAvatarWidget(
          appearance: widget.data.appearance ?? _defaultAppearance(),
          team: widget.data.team,
          primaryJerseyColorHex: widget.data.primaryJerseyColorHex,
          secondaryJerseyColorHex: widget.data.secondaryJerseyColorHex,
          accentJerseyColorHex: widget.data.accentJerseyColorHex,
          specialJersey: widget.data.specialJersey,
          nationalityIso: widget.data.nationalityIso,
          size: size,
          showHelmet: true,
          showGlasses: true,
          showBorder: false,
          backgroundColor: AppColors.surface,
        );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: accentColor.withValues(alpha: 0.75),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.26),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: FittedBox(
          fit: BoxFit.cover,
          child: portrait,
        ),
      ),
    );
  }

  Widget _buildStatsGrid({required bool isCompact}) {
    final entries = widget.data.stats.orderedEntries;
    // 2 kolumny po 3 wiersze: [MON, SPR], [HIL, COB], [ITT, REC]
    final leftCol = [entries[0], entries[1], entries[2]];
    final rightCol = [entries[3], entries[4], entries[5]];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.8),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: leftCol
                  .map((e) => _buildStatRow(e.code, e.value, isCompact))
                  .toList(),
            ),
          ),
          Container(
            width: 1,
            height: isCompact ? 42 : 50,
            margin: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 10),
            color: AppColors.cardBorder.withValues(alpha: 0.65),
          ),
          Expanded(
            child: Column(
              children: rightCol
                  .map((e) => _buildStatRow(e.code, e.value, isCompact))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String code, int value, bool isCompact) {
    final Color valueColor;
    if (value >= 90) {
      valueColor = AppColors.goldAccent;
    } else if (value >= 82) {
      valueColor = AppColors.cyanAccent;
    } else if (value >= 74) {
      valueColor = AppColors.statusSuccess;
    } else {
      valueColor = AppColors.textPrimary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            code,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 9.5 : 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 11.5 : 13.0,
              fontWeight: FontWeight.w800,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrandTourBadgesRow({
    required bool isCompact,
    required Color accentColor,
  }) {
    final wins = widget.data.grandTourWins;

    return Row(
      children: [
        Expanded(
          child: wins.isEmpty
              ? Row(
                  children: [
                    Icon(
                      Icons.military_tech_outlined,
                      size: isCompact ? 12 : 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'WORLDTOUR PALMARES',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isCompact ? 8.0 : 9.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                )
              : Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: wins
                      .map(
                        (badge) => _GrandTourBadgePill(
                          badge: badge,
                          compact: isCompact,
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          '${widget.data.editionYear}',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isCompact ? 8.5 : 9.5,
            fontWeight: FontWeight.w800,
            color: accentColor.withValues(alpha: 0.85),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  RiderAppearance _defaultAppearance() {
    final hash = widget.data.riderId.hashCode.abs();
    return RiderAppearance(
      faceShapeIndex: hash % 3,
      skinToneHex: '#E0AC69',
      hairStyleIndex: hash % 5,
      hairColorHex: '#3B2F2F',
      facialHairIndex: hash % 3,
      glassesModelId: 'aero_pro',
      glassesLensColorHex: '#00E5FF',
      helmetModelId: 'aero_vr',
      shoeColorHex: '#F3F4F6',
      sockHeightProportion: 0.55,
      bodyBuildType: BodyBuildType.allRounder,
    );
  }
}

class _GrandTourBadgePill extends StatelessWidget {
  final GrandTourWinBadge badge;
  final bool compact;

  const _GrandTourBadgePill({
    required this.badge,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final color = badge.tour.jerseyColor;
    final tooltipText = badge.years.isEmpty
        ? badge.tour.fullName
        : '${badge.tour.fullName} (${badge.years.join(', ')})';

    return Tooltip(
      message: tooltipText,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 6,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color.withValues(alpha: 0.72),
            width: 0.9,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              size: compact ? 9.5 : 11,
              color: color,
            ),
            const SizedBox(width: 3),
            Text(
              '${badge.tour.shortCode}${badge.count > 1 ? ' ×${badge.count}' : ''}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: compact ? 7.5 : 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryFlagChip extends StatelessWidget {
  final String isoCode;
  final bool compact;

  const _CountryFlagChip({
    required this.isoCode,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 0.8,
        ),
      ),
      child: Text(
        isoCode.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: compact ? 8.5 : 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// Rysuje tęczowy holograficzny połysk Topps Chrome reagujący na kąt pochylenia.
class _HolographicFoilPainter extends CustomPainter {
  final HoloTiltSample tilt;
  final double shimmerPhase;
  final ProRiderCardTier tier;
  final double intensity;

  const _HolographicFoilPainter({
    required this.tilt,
    required this.shimmerPhase,
    required this.tier,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shiftX = tilt.x * 0.75 + math.sin(shimmerPhase * math.pi * 2) * 0.18;
    final shiftY = tilt.y * 0.65 + math.cos(shimmerPhase * math.pi * 2) * 0.14;

    // 1. Wielokolorowy gradient pryzmatyczny (tęcza holograficzna)
    final rainbowAlpha = (tier == ProRiderCardTier.goldLegend ? 0.24 : 0.19) *
        intensity;
    final prismShader = LinearGradient(
      begin: Alignment(-1.2 + shiftX, -1.0 + shiftY),
      end: Alignment(1.2 + shiftX, 1.0 + shiftY),
      colors: [
        Colors.transparent,
        AppColors.cyanAccent.withValues(alpha: rainbowAlpha),
        const Color(0xFF8B5CF6).withValues(alpha: rainbowAlpha * 0.95),
        const Color(0xFFEC4899).withValues(alpha: rainbowAlpha * 0.9),
        AppColors.goldAccent.withValues(alpha: rainbowAlpha * 1.1),
        AppColors.statusSuccess.withValues(alpha: rainbowAlpha * 0.85),
        AppColors.accentBlue.withValues(alpha: rainbowAlpha),
        Colors.transparent,
      ],
      stops: const [0.0, 0.16, 0.30, 0.45, 0.58, 0.72, 0.86, 1.0],
    ).createShader(rect);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = prismShader
        ..blendMode = BlendMode.screen,
    );

    // 2. Ukośne mikro-linie refraktora Topps Chrome
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035 * intensity)
      ..strokeWidth = 1.0;

    const step = 7.0;
    final phaseOffset = (shiftX + shiftY) * 18.0;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      final dx = x + (phaseOffset % step);
      canvas.drawLine(
        Offset(dx, 0),
        Offset(dx - size.height * 0.45, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HolographicFoilPainter oldDelegate) {
    return oldDelegate.tilt != tilt ||
        oldDelegate.shimmerPhase != shimmerPhase ||
        oldDelegate.tier != tier ||
        oldDelegate.intensity != intensity;
  }
}

/// Rysuje punktowy odblask światła (specular hotspot) podążający za kursorem/żyroskopem.
class _SpecularGlintPainter extends CustomPainter {
  final HoloTiltSample tilt;
  final double shimmerPhase;
  final bool enabled;
  final bool isActive;

  const _SpecularGlintPainter({
    required this.tilt,
    required this.shimmerPhase,
    required this.enabled,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!enabled) return;
    final rect = Offset.zero & size;
    final cx = 0.5 + tilt.x * 0.42;
    final cy = 0.45 + tilt.y * 0.42;
    final alpha = isActive ? 0.24 : 0.11;

    final spotlight = RadialGradient(
      center: Alignment(cx * 2 - 1, cy * 2 - 1),
      radius: 0.75,
      colors: [
        Colors.white.withValues(alpha: alpha),
        const Color(0xFFFFF3B0).withValues(alpha: alpha * 0.45),
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 1.0],
    ).createShader(rect);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = spotlight
        ..blendMode = BlendMode.screen,
    );
  }

  @override
  bool shouldRepaint(covariant _SpecularGlintPainter oldDelegate) {
    return oldDelegate.tilt != tilt ||
        oldDelegate.shimmerPhase != shimmerPhase ||
        oldDelegate.enabled != enabled ||
        oldDelegate.isActive != isActive;
  }
}

/// Proceduralny kaligraficzny podpis autografu kolarza deterministycznie generowany
/// na podstawie nazwiska/ziarna [signatureSeed].
class _RiderAutographPainter extends CustomPainter {
  final String signatureSeed;
  final Color inkColor;

  const _RiderAutographPainter({
    required this.signatureSeed,
    required this.inkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final seed = signatureSeed.codeUnits.fold<int>(
      17,
      (acc, code) => (acc * 31 + code) & 0x7fffffff,
    );
    final rng = math.Random(seed);

    final startX = size.width * 0.18;
    final endX = size.width * 0.82;
    final midY = size.height * 0.54;
    final spanX = endX - startX;

    final path = Path();
    // Inicjał (wysoka pętla kaligraficzna)
    path.moveTo(startX, midY + size.height * 0.15);
    path.cubicTo(
      startX + spanX * 0.04,
      size.height * 0.05,
      startX + spanX * 0.14,
      size.height * 0.08,
      startX + spanX * 0.11,
      midY + size.height * 0.22,
    );

    // Płynne pociągnięcia liter nazwiska
    const segments = 7;
    var currX = startX + spanX * 0.14;
    var currY = midY;
    for (int i = 0; i < segments; i++) {
      final nextX = startX + spanX * (0.20 + (i / segments) * 0.64);
      final amp = (rng.nextDouble() * 0.32 + 0.12) * size.height;
      final dir = i.isEven ? -1.0 : 1.0;
      final ctrlX = (currX + nextX) * 0.5 + (rng.nextDouble() - 0.5) * 6.0;
      final ctrlY = (midY + dir * amp).clamp(2.0, size.height - 2.0);
      final targetY =
          (midY + (rng.nextDouble() - 0.5) * size.height * 0.22).clamp(
        3.0,
        size.height - 3.0,
      );
      path.quadraticBezierTo(ctrlX, ctrlY, nextX, targetY);
      currX = nextX;
      currY = targetY;
    }

    // Podkreślenie / zamaszysty ogon podpisu
    path.quadraticBezierTo(
      endX + 4,
      currY - size.height * 0.18,
      startX + spanX * 0.28,
      size.height * 0.86,
    );

    final glowPaint = Paint()
      ..color = inkColor.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final inkPaint = Paint()
      ..color = inkColor.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, inkPaint);
  }

  @override
  bool shouldRepaint(covariant _RiderAutographPainter oldDelegate) {
    return oldDelegate.signatureSeed != signatureSeed ||
        oldDelegate.inkColor != inkColor;
  }
}
