import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Typ slajdu w interaktywnym podsumowaniu sezonu „Season Wrapped / Year in Review”.
enum SeasonWrappedSlideKind {
  opener,
  victoriesAndPodiums,
  telemetryAndEffort,
  mvpAndBreakout,
  iconicMoments,
  summaryPoster,
}

/// Wyróżniony kolarz sezonu (MVP lub Odkrycie Roku).
class SeasonWrappedRiderHighlight {
  const SeasonWrappedRiderHighlight({
    required this.name,
    required this.nationalityCode,
    required this.role,
    required this.wins,
    required this.uciPoints,
    required this.peakWPerKg,
    required this.ovr,
    required this.bestMoment,
  });

  final String name;
  final String nationalityCode;
  final String role;
  final int wins;
  final int uciPoints;
  final double peakWPerKg;
  final int ovr;
  final String bestMoment;

  Map<String, dynamic> toJson() => {
        'name': name,
        'nationalityCode': nationalityCode,
        'role': role,
        'wins': wins,
        'uciPoints': uciPoints,
        'peakWPerKg': peakWPerKg,
        'ovr': ovr,
        'bestMoment': bestMoment,
      };

  factory SeasonWrappedRiderHighlight.fromJson(Map<String, dynamic> json) {
    return SeasonWrappedRiderHighlight(
      name: (json['name'] as String?) ?? 'Nieznany Kolarz',
      nationalityCode: (json['nationalityCode'] as String?) ?? 'POL',
      role: (json['role'] as String?) ?? 'Lider',
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      uciPoints: (json['uciPoints'] as num?)?.toInt() ?? 0,
      peakWPerKg: (json['peakWPerKg'] as num?)?.toDouble() ?? 6.0,
      ovr: (json['ovr'] as num?)?.toInt() ?? 75,
      bestMoment: (json['bestMoment'] as String?) ?? '',
    );
  }
}

/// Kluczowy moment sezonu prezentowany na slajdzie wspomnień.
class SeasonWrappedKeyMoment {
  const SeasonWrappedKeyMoment({
    required this.id,
    required this.raceName,
    required this.dateLabel,
    required this.category,
    required this.headline,
    required this.narrative,
    required this.statBadge,
    this.isMonumentOrGrandTour = false,
  });

  final String id;
  final String raceName;
  final String dateLabel;
  final String category;
  final String headline;
  final String narrative;
  final String statBadge;
  final bool isMonumentOrGrandTour;

  Map<String, dynamic> toJson() => {
        'id': id,
        'raceName': raceName,
        'dateLabel': dateLabel,
        'category': category,
        'headline': headline,
        'narrative': narrative,
        'statBadge': statBadge,
        'isMonumentOrGrandTour': isMonumentOrGrandTour,
      };

  factory SeasonWrappedKeyMoment.fromJson(Map<String, dynamic> json) {
    return SeasonWrappedKeyMoment(
      id: (json['id'] as String?) ?? '',
      raceName: (json['raceName'] as String?) ?? '',
      dateLabel: (json['dateLabel'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'WorldTour',
      headline: (json['headline'] as String?) ?? '',
      narrative: (json['narrative'] as String?) ?? '',
      statBadge: (json['statBadge'] as String?) ?? '',
      isMonumentOrGrandTour: (json['isMonumentOrGrandTour'] as bool?) ?? false,
    );
  }
}

/// Kompletny zestaw danych do wygenerowania historii „Season Wrapped”.
class SeasonWrappedStoryData {
  const SeasonWrappedStoryData({
    required this.seasonYear,
    required this.teamName,
    required this.teamDivision,
    required this.managerName,
    required this.totalWins,
    required this.worldTourWins,
    required this.grandTourStageWins,
    required this.monumentWins,
    required this.podiumFinishes,
    required this.uciPoints,
    required this.uciRank,
    required this.previousUciRank,
    required this.totalDistanceKm,
    required this.totalElevationGainM,
    required this.totalRaceDays,
    required this.totalEnergyKcal,
    required this.peakWattBombW,
    required this.peakWPerKg,
    required this.averageTeamSpeedKmh,
    required this.mvpRider,
    this.breakoutRider,
    required this.topMoments,
    required this.sponsorSatisfactionPct,
    required this.prizeMoneyEur,
    required this.mediaValueEur,
    this.seasonArchetypeOverride,
  });

  final int seasonYear;
  final String teamName;
  final String teamDivision;
  final String managerName;
  final int totalWins;
  final int worldTourWins;
  final int grandTourStageWins;
  final int monumentWins;
  final int podiumFinishes;
  final int uciPoints;
  final int uciRank;
  final int previousUciRank;
  final double totalDistanceKm;
  final double totalElevationGainM;
  final int totalRaceDays;
  final double totalEnergyKcal;
  final double peakWattBombW;
  final double peakWPerKg;
  final double averageTeamSpeedKmh;
  final SeasonWrappedRiderHighlight mvpRider;
  final SeasonWrappedRiderHighlight? breakoutRider;
  final List<SeasonWrappedKeyMoment> topMoments;
  final double sponsorSatisfactionPct;
  final double prizeMoneyEur;
  final double mediaValueEur;
  final String? seasonArchetypeOverride;

  Map<String, dynamic> toJson() => {
        'seasonYear': seasonYear,
        'teamName': teamName,
        'teamDivision': teamDivision,
        'managerName': managerName,
        'totalWins': totalWins,
        'worldTourWins': worldTourWins,
        'grandTourStageWins': grandTourStageWins,
        'monumentWins': monumentWins,
        'podiumFinishes': podiumFinishes,
        'uciPoints': uciPoints,
        'uciRank': uciRank,
        'previousUciRank': previousUciRank,
        'totalDistanceKm': totalDistanceKm,
        'totalElevationGainM': totalElevationGainM,
        'totalRaceDays': totalRaceDays,
        'totalEnergyKcal': totalEnergyKcal,
        'peakWattBombW': peakWattBombW,
        'peakWPerKg': peakWPerKg,
        'averageTeamSpeedKmh': averageTeamSpeedKmh,
        'mvpRider': mvpRider.toJson(),
        'breakoutRider': breakoutRider?.toJson(),
        'topMoments': topMoments.map((m) => m.toJson()).toList(),
        'sponsorSatisfactionPct': sponsorSatisfactionPct,
        'prizeMoneyEur': prizeMoneyEur,
        'mediaValueEur': mediaValueEur,
        'seasonArchetypeOverride': seasonArchetypeOverride,
      };

  factory SeasonWrappedStoryData.fromJson(Map<String, dynamic> json) {
    final rawMoments = (json['topMoments'] as List<dynamic>?) ?? const [];
    final rawMvp = json['mvpRider'] as Map<String, dynamic>?;
    final rawBreakout = json['breakoutRider'] as Map<String, dynamic>?;

    return SeasonWrappedStoryData(
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      teamName: (json['teamName'] as String?) ?? 'Veloce Pro Cycling',
      teamDivision: (json['teamDivision'] as String?) ?? 'UCI WorldTour',
      managerName: (json['managerName'] as String?) ?? 'Dyrektor Sportowy',
      totalWins: (json['totalWins'] as num?)?.toInt() ?? 0,
      worldTourWins: (json['worldTourWins'] as num?)?.toInt() ?? 0,
      grandTourStageWins: (json['grandTourStageWins'] as num?)?.toInt() ?? 0,
      monumentWins: (json['monumentWins'] as num?)?.toInt() ?? 0,
      podiumFinishes: (json['podiumFinishes'] as num?)?.toInt() ?? 0,
      uciPoints: (json['uciPoints'] as num?)?.toInt() ?? 0,
      uciRank: (json['uciRank'] as num?)?.toInt() ?? 1,
      previousUciRank: (json['previousUciRank'] as num?)?.toInt() ?? 1,
      totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ?? 0.0,
      totalElevationGainM:
          (json['totalElevationGainM'] as num?)?.toDouble() ?? 0.0,
      totalRaceDays: (json['totalRaceDays'] as num?)?.toInt() ?? 0,
      totalEnergyKcal: (json['totalEnergyKcal'] as num?)?.toDouble() ?? 0.0,
      peakWattBombW: (json['peakWattBombW'] as num?)?.toDouble() ?? 0.0,
      peakWPerKg: (json['peakWPerKg'] as num?)?.toDouble() ?? 0.0,
      averageTeamSpeedKmh:
          (json['averageTeamSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      mvpRider: rawMvp != null
          ? SeasonWrappedRiderHighlight.fromJson(rawMvp)
          : const SeasonWrappedRiderHighlight(
              name: 'Lider Zespołu',
              nationalityCode: 'POL',
              role: 'GC Lider',
              wins: 0,
              uciPoints: 0,
              peakWPerKg: 6.0,
              ovr: 80,
              bestMoment: '',
            ),
      breakoutRider: rawBreakout != null
          ? SeasonWrappedRiderHighlight.fromJson(rawBreakout)
          : null,
      topMoments: rawMoments
          .whereType<Map<String, dynamic>>()
          .map(SeasonWrappedKeyMoment.fromJson)
          .toList(),
      sponsorSatisfactionPct:
          (json['sponsorSatisfactionPct'] as num?)?.toDouble() ?? 80.0,
      prizeMoneyEur: (json['prizeMoneyEur'] as num?)?.toDouble() ?? 0.0,
      mediaValueEur: (json['mediaValueEur'] as num?)?.toDouble() ?? 0.0,
      seasonArchetypeOverride: json['seasonArchetypeOverride'] as String?,
    );
  }

  /// Przykładowy zestaw danych do podglądu i demonstracji.
  factory SeasonWrappedStoryData.sample() {
    return const SeasonWrappedStoryData(
      seasonYear: 2026,
      teamName: 'Bora-Vistula Pro Cycling',
      teamDivision: 'UCI WorldTour',
      managerName: 'Jan Kowalski',
      totalWins: 34,
      worldTourWins: 19,
      grandTourStageWins: 6,
      monumentWins: 2,
      podiumFinishes: 71,
      uciPoints: 14820,
      uciRank: 3,
      previousUciRank: 7,
      totalDistanceKm: 48620,
      totalElevationGainM: 612400,
      totalRaceDays: 294,
      totalEnergyKcal: 1248000,
      peakWattBombW: 1585,
      peakWPerKg: 6.72,
      averageTeamSpeedKmh: 43.8,
      mvpRider: SeasonWrappedRiderHighlight(
        name: 'Michał Majewski',
        nationalityCode: 'POL',
        role: 'Lider GC & Góral',
        wins: 11,
        uciPoints: 4120,
        peakWPerKg: 6.72,
        ovr: 91,
        bestMoment: 'Zwycięstwo na Alpe d\'Huez i podium Tour de France',
      ),
      breakoutRider: SeasonWrappedRiderHighlight(
        name: 'Kacper Nowak',
        nationalityCode: 'POL',
        role: 'Sprinter / Klasyki',
        wins: 7,
        uciPoints: 1980,
        peakWPerKg: 5.85,
        ovr: 83,
        bestMoment: 'Finisz 74.6 km/h i wygrana na Polach Elizejskich',
      ),
      topMoments: [
        SeasonWrappedKeyMoment(
          id: 'm1',
          raceName: 'Paris-Roubaix',
          dateLabel: '12 KWI 2026',
          category: 'Monument 5★',
          headline: 'Solo przez Trouée d\'Arenberg po Kostkę Bruku',
          narrative:
              'Atak na 42 km przed welodromem w deszczu i błocie na ciśnieniu 3.7 bar przyniósł pierwszy Monument w historii klubu.',
          statBadge: '+0:48 s przewagi',
          isMonumentOrGrandTour: true,
        ),
        SeasonWrappedKeyMoment(
          id: 'm2',
          raceName: 'Tour de France — Etap 14',
          dateLabel: '18 LIP 2026',
          category: 'Grand Tour HC',
          headline: 'Rekord VAM 1785 m/h na Alpe d\'Huez',
          narrative:
              'Taktyka stacji przekaźnikowej w dolinie Romanche pozwoliła liderowi zgubić rywali na 8. zakręcie.',
          statBadge: '6.72 W/kg • 38:42',
          isMonumentOrGrandTour: true,
        ),
        SeasonWrappedKeyMoment(
          id: 'm3',
          raceName: 'Il Lombardia',
          dateLabel: '10 PAŹ 2026',
          category: 'Monument',
          headline: 'Złoty finisz w Como i skok na 3. miejsce UCI',
          narrative:
              'Podwójne podium drużyny przypieczętowało awans o 4 pozycje w światowym rankingu WorldTour.',
          statBadge: '+4 pozycje UCI',
          isMonumentOrGrandTour: true,
        ),
      ],
      sponsorSatisfactionPct: 94.5,
      prizeMoneyEur: 1420000,
      mediaValueEur: 28600000,
    );
  }
}

/// Metadane pojedynczego slajdu historii.
class SeasonWrappedSlideSpec {
  const SeasonWrappedSlideSpec({
    required this.kind,
    required this.kicker,
    required this.title,
    required this.subtitle,
  });

  final SeasonWrappedSlideKind kind;
  final String kicker;
  final String title;
  final String subtitle;
}

/// Czysta logika obliczeniowa i analityczna dla podsumowania sezonu.
class SeasonWrappedAnalytics {
  const SeasonWrappedAnalytics._();

  static const double _mountEverestHeightM = 8848.86;

  static List<SeasonWrappedSlideSpec> buildSlides(
      SeasonWrappedStoryData data) {
    return [
      SeasonWrappedSlideSpec(
        kind: SeasonWrappedSlideKind.opener,
        kicker: 'SEASON WRAPPED ${data.seasonYear}',
        title: data.teamName,
        subtitle:
            '${data.teamDivision} • ${deriveSeasonArchetype(data)}',
      ),
      SeasonWrappedSlideSpec(
        kind: SeasonWrappedSlideKind.victoriesAndPodiums,
        kicker: 'BILANS ZWYCIĘSTW',
        title: data.totalWins > 0
            ? '${data.totalWins} triumfów na szosie'
            : 'Sezon budowania fundamentów',
        subtitle:
            '${data.podiumFinishes} miejsc na podium • ${data.uciPoints} pkt UCI',
      ),
      const SeasonWrappedSlideSpec(
        kind: SeasonWrappedSlideKind.telemetryAndEffort,
        kicker: 'TELEMETRIA PELETONU',
        title: 'Krew, pot i waty',
        subtitle: 'Liczby wygenerowane przez Twoją kadrę przez cały rok',
      ),
      const SeasonWrappedSlideSpec(
        kind: SeasonWrappedSlideKind.mvpAndBreakout,
        kicker: 'BOHATEROWIE ROKU',
        title: 'Liderzy i odkrycia',
        subtitle: 'Kolarze, którzy zdefiniowali wynik drużyny',
      ),
      const SeasonWrappedSlideSpec(
        kind: SeasonWrappedSlideKind.iconicMoments,
        kicker: 'KRONIKA CHWAŁY',
        title: 'Największe momenty sezonu',
        subtitle: 'Wybierz wspomnienie, aby zobaczyć szczegóły taktyczne',
      ),
      SeasonWrappedSlideSpec(
        kind: SeasonWrappedSlideKind.summaryPoster,
        kicker: 'OFICJALNA KARTA SEZONU',
        title: '${data.teamName} • ${data.seasonYear}',
        subtitle: 'Podsumowanie gotowe do archiwum i udostępnienia',
      ),
    ];
  }

  static String deriveSeasonArchetype(SeasonWrappedStoryData data) {
    if (data.seasonArchetypeOverride != null &&
        data.seasonArchetypeOverride!.trim().isNotEmpty) {
      return data.seasonArchetypeOverride!.trim();
    }
    if (data.monumentWins >= 2 && data.grandTourStageWins >= 4) {
      return 'Totalna Dominacja WorldTour';
    }
    if (data.monumentWins >= 1) {
      return 'Łowcy Monumentów i Klasyków';
    }
    if (data.grandTourStageWins >= 3) {
      return 'Mistrzowie Wielkich Tourów';
    }
    if (data.totalWins >= 20) {
      return 'Maszyna do Zwyciężania';
    }
    if (data.podiumFinishes >= 15) {
      return 'Waleczni Pretendenci';
    }
    return 'Budowniczowie Przyszłości';
  }

  static int rankDelta(int previousRank, int currentRank) {
    if (previousRank <= 0 || currentRank <= 0) return 0;
    return previousRank - currentRank;
  }

  static double everestEquivalents(double elevationGainM) {
    if (elevationGainM <= 0) return 0.0;
    return elevationGainM / _mountEverestHeightM;
  }

  static String formatCompactNumber(num value) {
    final abs = value.abs();
    if (abs >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (abs >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value is int ? value.toString() : value.toStringAsFixed(1);
  }

  static String formatCurrencyEur(double amount) {
    if (amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)} M EUR';
    }
    if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} tys. EUR';
    }
    return '${amount.toStringAsFixed(0)} EUR';
  }
}

/// Główny interaktywny widget podsumowania roku „Season Wrapped / Year in Review”.
class PostSeasonInteractiveYearInReviewStory extends StatefulWidget {
  const PostSeasonInteractiveYearInReviewStory({
    super.key,
    required this.data,
    this.initialSlideIndex = 0,
    this.autoPlay = true,
    this.slideDuration = const Duration(seconds: 6),
    this.isDisabled = false,
    this.onSlideChanged,
    this.onShareSummary,
    this.onClose,
  });

  final SeasonWrappedStoryData data;
  final int initialSlideIndex;
  final bool autoPlay;
  final Duration slideDuration;
  final bool isDisabled;
  final ValueChanged<int>? onSlideChanged;
  final ValueChanged<SeasonWrappedStoryData>? onShareSummary;
  final VoidCallback? onClose;

  @override
  State<PostSeasonInteractiveYearInReviewStory> createState() =>
      _PostSeasonInteractiveYearInReviewStoryState();
}

class _PostSeasonInteractiveYearInReviewStoryState
    extends State<PostSeasonInteractiveYearInReviewStory>
    with SingleTickerProviderStateMixin {
  late final List<SeasonWrappedSlideSpec> _slides;
  late final AnimationController _progressController;
  late int _currentIndex;
  late bool _isPlaying;
  int _selectedMomentIndex = 0;
  bool _shareConfirmed = false;

  @override
  void initState() {
    super.initState();
    _slides = SeasonWrappedAnalytics.buildSlides(widget.data);
    _currentIndex =
        widget.initialSlideIndex.clamp(0, math.max(0, _slides.length - 1));
    _isPlaying = widget.autoPlay && !widget.isDisabled;

    _progressController = AnimationController(
      vsync: this,
      duration: widget.slideDuration,
    )..addStatusListener(_handleProgressStatus);

    if (_isPlaying) {
      _progressController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(
      covariant PostSeasonInteractiveYearInReviewStory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDisabled && _isPlaying) {
      _isPlaying = false;
      _progressController.stop();
    }
    if (widget.slideDuration != oldWidget.slideDuration) {
      _progressController.duration = widget.slideDuration;
    }
  }

  @override
  void dispose() {
    _progressController.removeStatusListener(_handleProgressStatus);
    _progressController.dispose();
    super.dispose();
  }

  void _handleProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isPlaying && !widget.isDisabled) {
      if (_currentIndex < _slides.length - 1) {
        _goToSlide(_currentIndex + 1);
      } else {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  void _goToSlide(int targetIndex) {
    if (widget.isDisabled) return;
    final clamped = targetIndex.clamp(0, _slides.length - 1);
    if (clamped == _currentIndex && _progressController.value == 0.0) return;

    setState(() {
      _currentIndex = clamped;
    });
    widget.onSlideChanged?.call(_currentIndex);

    _progressController.reset();
    if (_isPlaying) {
      _progressController.forward(from: 0.0);
    }
  }

  void _nextSlide() {
    if (widget.isDisabled) return;
    if (_currentIndex < _slides.length - 1) {
      _goToSlide(_currentIndex + 1);
    } else {
      widget.onClose?.call();
    }
  }

  void _previousSlide() {
    if (widget.isDisabled) return;
    if (_currentIndex > 0) {
      _goToSlide(_currentIndex - 1);
    }
  }

  void _togglePlayPause() {
    if (widget.isDisabled) return;
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        if (_progressController.value >= 1.0) {
          _progressController.forward(from: 0.0);
        } else {
          _progressController.forward();
        }
      } else {
        _progressController.stop();
      }
    });
  }

  void _replayFromStart() {
    if (widget.isDisabled) return;
    setState(() {
      _isPlaying = widget.autoPlay;
      _currentIndex = 0;
    });
    widget.onSlideChanged?.call(0);
    _progressController.reset();
    if (_isPlaying) {
      _progressController.forward(from: 0.0);
    }
  }

  void _handleShare() {
    if (widget.isDisabled) return;
    widget.onShareSummary?.call(widget.data);
    setState(() {
      _shareConfirmed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeSlide = _slides[_currentIndex];

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowRight): _NextSlideIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _PrevSlideIntent(),
        SingleActivator(LogicalKeyboardKey.space): _TogglePlayIntent(),
        SingleActivator(LogicalKeyboardKey.escape): _CloseStoryIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NextSlideIntent: CallbackAction<_NextSlideIntent>(
            onInvoke: (_) {
              _nextSlide();
              return null;
            },
          ),
          _PrevSlideIntent: CallbackAction<_PrevSlideIntent>(
            onInvoke: (_) {
              _previousSlide();
              return null;
            },
          ),
          _TogglePlayIntent: CallbackAction<_TogglePlayIntent>(
            onInvoke: (_) {
              _togglePlayPause();
              return null;
            },
          ),
          _CloseStoryIntent: CallbackAction<_CloseStoryIntent>(
            onInvoke: (_) {
              if (!widget.isDisabled) {
                widget.onClose?.call();
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width;
              final isMobile = width < 600;
              final isDesktop = width >= 1100;
              final horizontalPadding = isMobile ? 14.0 : (isDesktop ? 32.0 : 22.0);
              final contentMaxWidth = isDesktop ? 980.0 : width;

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor, width: 1.0),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _StoryBackdropPainter(
                          slideIndex: _currentIndex,
                          totalSlides: _slides.length,
                        ),
                      ),
                    ),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMaxWidth),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            isMobile ? 12.0 : 18.0,
                            horizontalPadding,
                            isMobile ? 12.0 : 18.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTopProgressBars(),
                              const SizedBox(height: 12),
                              _buildHeaderBar(activeSlide, isMobile),
                              const SizedBox(height: 12),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeOutCubic,
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0.03, 0.0),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: KeyedSubtree(
                                    key: ValueKey<int>(_currentIndex),
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _buildSlideContent(
                                        activeSlide,
                                        isMobile: isMobile,
                                        isDesktop: isDesktop,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildBottomControls(isMobile),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopProgressBars() {
    return Row(
      children: List.generate(_slides.length, (index) {
        final isCompleted = index < _currentIndex;
        final isActive = index == _currentIndex;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == _slides.length - 1 ? 0 : 6,
            ),
            child: _StoryInteractiveSegment(
              tooltip: 'Slajd ${index + 1}: ${_slides[index].kicker}',
              enabled: !widget.isDisabled,
              onTap: () => _goToSlide(index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 5,
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, _) {
                      final double value;
                      if (isCompleted) {
                        value = 1.0;
                      } else if (isActive) {
                        value = _isPlaying ? _progressController.value : 0.35;
                      } else {
                        value = 0.0;
                      }
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: AppTheme.borderColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isActive || isCompleted
                              ? AppColors.goldAccent
                              : AppColors.surfaceLight,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeaderBar(SeasonWrappedSlideSpec slide, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryAccent.withValues(alpha: 0.7),
              ),
            ),
            child: Text(
              slide.kicker,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.goldAccent,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${_currentIndex + 1} / ${_slides.length}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const Spacer(),
        _StoryInteractiveButton(
          key: const ValueKey('story_play_pause_btn'),
          icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          label: isMobile ? null : (_isPlaying ? 'Pauza' : 'Odtwarzaj'),
          enabled: !widget.isDisabled,
          onPressed: _togglePlayPause,
        ),
        if (widget.onClose != null) ...[
          const SizedBox(width: 8),
          _StoryInteractiveButton(
            key: const ValueKey('story_close_btn'),
            icon: Icons.close_rounded,
            label: null,
            enabled: !widget.isDisabled,
            onPressed: widget.onClose,
          ),
        ],
      ],
    );
  }

  Widget _buildSlideContent(
    SeasonWrappedSlideSpec slide, {
    required bool isMobile,
    required bool isDesktop,
  }) {
    switch (slide.kind) {
      case SeasonWrappedSlideKind.opener:
        return _buildOpenerSlide(slide, isMobile: isMobile);
      case SeasonWrappedSlideKind.victoriesAndPodiums:
        return _buildVictoriesSlide(slide, isMobile: isMobile);
      case SeasonWrappedSlideKind.telemetryAndEffort:
        return _buildTelemetrySlide(slide, isMobile: isMobile);
      case SeasonWrappedSlideKind.mvpAndBreakout:
        return _buildMvpSlide(slide, isMobile: isMobile);
      case SeasonWrappedSlideKind.iconicMoments:
        return _buildMomentsSlide(slide, isMobile: isMobile);
      case SeasonWrappedSlideKind.summaryPoster:
        return _buildSummaryPosterSlide(slide, isMobile: isMobile);
    }
  }

  Widget _buildOpenerSlide(
    SeasonWrappedSlideSpec slide, {
    required bool isMobile,
  }) {
    final rankDelta = SeasonWrappedAnalytics.rankDelta(
      widget.data.previousUciRank,
      widget.data.uciRank,
    );
    final archetype = SeasonWrappedAnalytics.deriveSeasonArchetype(widget.data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StoryCard(
          borderColor: AppColors.goldAccent.withValues(alpha: 0.45),
          padding: EdgeInsets.all(isMobile ? 18 : 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: isMobile ? 48 : 58,
                    height: isMobile ? 48 : 58,
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.goldAccent, width: 1.2),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.goldAccent,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.data.teamDivision.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.accentBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.data.teamName,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: isMobile ? 22 : 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.goldAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tożsamość sezonu: $archetype',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pod wodzą Dyrektora Sportowego (${widget.data.managerName}) zespół ukończył sezon ${widget.data.seasonYear} na ${widget.data.uciRank}. miejscu w światowym rankingu UCI.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ResponsiveMetricsRow(
          isMobile: isMobile,
          children: [
            _MetricTile(
              label: 'RANKING UCI',
              value: '#${widget.data.uciRank}',
              accentColor: AppColors.goldAccent,
              footnote: rankDelta > 0
                  ? '+$rankDelta miejsc w górę'
                  : (rankDelta < 0
                      ? '$rankDelta miejsc względem ub. roku'
                      : 'Stabilna pozycja'),
            ),
            _MetricTile(
              label: 'PUNKTY UCI',
              value: SeasonWrappedAnalytics.formatCompactNumber(
                  widget.data.uciPoints),
              accentColor: AppColors.accentBlue,
              footnote: '${widget.data.totalRaceDays} dni wyścigowych',
            ),
            _MetricTile(
              label: 'SATYSFAKCJA SPONSORA',
              value:
                  '${widget.data.sponsorSatisfactionPct.toStringAsFixed(0)}%',
              accentColor: AppColors.statusSuccess,
              footnote:
                  'Ekwiwalent ${SeasonWrappedAnalytics.formatCurrencyEur(widget.data.mediaValueEur)}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVictoriesSlide(
    SeasonWrappedSlideSpec slide, {
    required bool isMobile,
  }) {
    final totalWins = widget.data.totalWins;
    final wtRatio = totalWins > 0
        ? (widget.data.worldTourWins / totalWins).clamp(0.0, 1.0)
        : 0.0;
    final gtRatio = totalWins > 0
        ? (widget.data.grandTourStageWins / totalWins).clamp(0.0, 1.0)
        : 0.0;
    final monumentRatio = totalWins > 0
        ? (widget.data.monumentWins / totalWins).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StoryCard(
          padding: EdgeInsets.all(isMobile ? 16 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slide.title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                slide.subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              _BreakdownProgressBar(
                label: 'Zwycięstwa WorldTour',
                countLabel: '${widget.data.worldTourWins} wygranych',
                ratio: wtRatio,
                color: AppColors.goldAccent,
              ),
              const SizedBox(height: 12),
              _BreakdownProgressBar(
                label: 'Etapy Wielkich Tourów',
                countLabel: '${widget.data.grandTourStageWins} etapów',
                ratio: gtRatio,
                color: AppColors.primaryAccent,
              ),
              const SizedBox(height: 12),
              _BreakdownProgressBar(
                label: 'Monumenty Kolarskie',
                countLabel: '${widget.data.monumentWins} trofeów',
                ratio: monumentRatio,
                color: AppColors.accentBlue,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ResponsiveMetricsRow(
          isMobile: isMobile,
          children: [
            _MetricTile(
              label: 'WSZYSTKIE PODIA',
              value: '${widget.data.podiumFinishes}',
              accentColor: AppColors.goldAccent,
              footnote: 'Miejsca w Top 3',
            ),
            _MetricTile(
              label: 'NAGRODY PIENIĘŻNE',
              value: SeasonWrappedAnalytics.formatCurrencyEur(
                  widget.data.prizeMoneyEur),
              accentColor: AppColors.statusSuccess,
              footnote: 'Pula wywalczona na szosie',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTelemetrySlide(
    SeasonWrappedSlideSpec slide, {
    required bool isMobile,
  }) {
    final everests =
        SeasonWrappedAnalytics.everestEquivalents(widget.data.totalElevationGainM);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StoryCard(
          padding: EdgeInsets.all(isMobile ? 16 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slide.title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                slide.subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ResponsiveMetricsRow(
          isMobile: isMobile,
          children: [
            _MetricTile(
              label: 'PRZEJECHANY DYSTANS',
              value:
                  '${SeasonWrappedAnalytics.formatCompactNumber(widget.data.totalDistanceKm)} km',
              accentColor: AppColors.accentBlue,
              footnote:
                  'Średnia prędkość ${widget.data.averageTeamSpeedKmh.toStringAsFixed(1)} km/h',
            ),
            _MetricTile(
              label: 'PRZEWYŻSZENIE',
              value:
                  '${SeasonWrappedAnalytics.formatCompactNumber(widget.data.totalElevationGainM)} m',
              accentColor: AppColors.amberWarning,
              footnote: '${everests.toStringAsFixed(1)}x Mount Everest',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ResponsiveMetricsRow(
          isMobile: isMobile,
          children: [
            _MetricTile(
              label: 'SZCZYTOWA WATT BOMB',
              value: '${widget.data.peakWattBombW.toStringAsFixed(0)} W',
              accentColor: AppColors.crimsonAlert,
              footnote:
                  'Maksymalna moc wspinaczkowa ${widget.data.peakWPerKg.toStringAsFixed(2)} W/kg',
            ),
            _MetricTile(
              label: 'SPALONA ENERGIA',
              value:
                  '${SeasonWrappedAnalytics.formatCompactNumber(widget.data.totalEnergyKcal)} kcal',
              accentColor: AppColors.statusSuccess,
              footnote: '${widget.data.totalRaceDays} osobodni wyścigowych',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMvpSlide(
    SeasonWrappedSlideSpec slide, {
    required bool isMobile,
  }) {
    final mvp = widget.data.mvpRider;
    final breakout = widget.data.breakoutRider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StoryCard(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slide.title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isMobile ? 20 : 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                slide.subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (isMobile || breakout == null) ...[
          _RiderHighlightCard(
            badgeText: 'MVP SEZONU',
            badgeColor: AppColors.goldAccent,
            rider: mvp,
          ),
          if (breakout != null) ...[
            const SizedBox(height: 12),
            _RiderHighlightCard(
              badgeText: 'ODKRYCIE ROKU',
              badgeColor: AppColors.accentBlue,
              rider: breakout,
            ),
          ],
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _RiderHighlightCard(
                  badgeText: 'MVP SEZONU',
                  badgeColor: AppColors.goldAccent,
                  rider: mvp,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _RiderHighlightCard(
                  badgeText: 'ODKRYCIE ROKU',
                  badgeColor: AppColors.accentBlue,
                  rider: breakout,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMomentsSlide(
    SeasonWrappedSlideSpec slide, {
    required bool isMobile,
  }) {
    final moments = widget.data.topMoments;
    if (moments.isEmpty) {
      return const _StoryCard(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.history_edu_rounded,
              color: AppColors.textSecondary,
              size: 36,
            ),
            SizedBox(height: 12),
            Text(
              'Brak wyróżnionych momentów w tym sezonie',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6),
            Text(
              'W kolejnym roku nowe klasyki i Wielkie Toury czekają na zapisanie w kronice.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final safeIndex = _selectedMomentIndex.clamp(0, moments.length - 1);
    final selected = moments[safeIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StoryCard(
          padding: EdgeInsets.all(isMobile ? 14 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slide.title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                slide.subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              ...List.generate(moments.length, (i) {
                final m = moments[i];
                final isSelected = i == safeIndex;
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: i == moments.length - 1 ? 0 : 8),
                  child: _StoryMomentTile(
                    moment: m,
                    isSelected: isSelected,
                    enabled: !widget.isDisabled,
                    onTap: () {
                      setState(() {
                        _selectedMomentIndex = i;
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _StoryCard(
          borderColor: AppColors.goldAccent.withValues(alpha: 0.4),
          padding: EdgeInsets.all(isMobile ? 14 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: AppColors.goldAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${selected.raceName} • ${selected.dateLabel}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                selected.headline,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                selected.narrative,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryPosterSlide(
    SeasonWrappedSlideSpec slide, {
    required bool isMobile,
  }) {
    final archetype = SeasonWrappedAnalytics.deriveSeasonArchetype(widget.data);

    return _StoryCard(
      borderColor: AppColors.goldAccent.withValues(alpha: 0.6),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KARTA PODSUMOWANIA ${widget.data.seasonYear}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.data.teamName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 20 : 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      archetype,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.goldAccent),
                ),
                child: Text(
                  '#${widget.data.uciRank} UCI',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderColor, height: 1),
          const SizedBox(height: 16),
          _ResponsiveMetricsRow(
            isMobile: isMobile,
            children: [
              _MetricTile(
                label: 'ZWYCIĘSTWA',
                value: '${widget.data.totalWins}',
                accentColor: AppColors.goldAccent,
                footnote: '${widget.data.worldTourWins} WorldTour',
              ),
              _MetricTile(
                label: 'MVP ROKU',
                value: widget.data.mvpRider.name,
                accentColor: AppColors.accentBlue,
                footnote: '${widget.data.mvpRider.wins} wygranych',
              ),
              _MetricTile(
                label: 'DYSTANS',
                value:
                    '${SeasonWrappedAnalytics.formatCompactNumber(widget.data.totalDistanceKm)} km',
                accentColor: AppColors.statusSuccess,
                footnote: '${widget.data.podiumFinishes} miejsc na podium',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StoryInteractiveButton(
                key: const ValueKey('story_share_btn'),
                icon: _shareConfirmed
                    ? Icons.check_circle_rounded
                    : Icons.ios_share_rounded,
                label: _shareConfirmed
                    ? 'Zapisano do kroniki'
                    : 'Udostępnij kartę sezonu',
                isPrimary: true,
                enabled: !widget.isDisabled && widget.onShareSummary != null,
                onPressed: _handleShare,
              ),
              _StoryInteractiveButton(
                key: const ValueKey('story_replay_btn'),
                icon: Icons.replay_rounded,
                label: 'Odtwórz od początku',
                enabled: !widget.isDisabled,
                onPressed: _replayFromStart,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(bool isMobile) {
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == _slides.length - 1;

    return Row(
      children: [
        _StoryInteractiveButton(
          key: const ValueKey('story_prev_btn'),
          icon: Icons.chevron_left_rounded,
          label: isMobile ? null : 'Poprzedni',
          enabled: !widget.isDisabled && !isFirst,
          onPressed: _previousSlide,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_slides.length, (i) {
                  final active = i == _currentIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _StoryInteractiveSegment(
                      tooltip: 'Przejdź do slajdu ${i + 1}',
                      enabled: !widget.isDisabled,
                      onTap: () => _goToSlide(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: active ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.goldAccent
                              : AppTheme.borderColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _StoryInteractiveButton(
          key: const ValueKey('story_next_btn'),
          icon: isLast ? Icons.check_rounded : Icons.chevron_right_rounded,
          label: isMobile ? null : (isLast ? 'Zakończ' : 'Następny'),
          isPrimary: isLast,
          enabled: !widget.isDisabled && (!isLast || widget.onClose != null),
          onPressed: _nextSlide,
        ),
      ],
    );
  }
}

/// Otwiera interaktywną historię „Season Wrapped” w oknie modalnym.
Future<void> showPostSeasonYearInReviewStoryModal(
  BuildContext context, {
  required SeasonWrappedStoryData data,
  bool autoPlay = true,
  ValueChanged<SeasonWrappedStoryData>? onShareSummary,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.85),
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1020, maxHeight: 760),
          child: PostSeasonInteractiveYearInReviewStory(
            data: data,
            autoPlay: autoPlay,
            onShareSummary: onShareSummary,
            onClose: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      );
    },
  );
}

class _NextSlideIntent extends Intent {
  const _NextSlideIntent();
}

class _PrevSlideIntent extends Intent {
  const _PrevSlideIntent();
}

class _TogglePlayIntent extends Intent {
  const _TogglePlayIntent();
}

class _CloseStoryIntent extends Intent {
  const _CloseStoryIntent();
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? AppTheme.borderColor,
          width: 1.0,
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}

class _ResponsiveMetricsRow extends StatelessWidget {
  const _ResponsiveMetricsRow({
    required this.isMobile,
    required this.children,
  });

  final bool isMobile;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            Expanded(child: children[i]),
            if (i < children.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.footnote,
  });

  final String label;
  final String value;
  final Color accentColor;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    return _StoryCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: accentColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            footnote,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BreakdownProgressBar extends StatelessWidget {
  const _BreakdownProgressBar({
    required this.label,
    required this.countLabel,
    required this.ratio,
    required this.color,
  });

  final String label;
  final String countLabel;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              countLabel,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: ratio.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            builder: (context, animatedRatio, _) {
              return LinearProgressIndicator(
                minHeight: 8,
                value: animatedRatio,
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

class _RiderHighlightCard extends StatelessWidget {
  const _RiderHighlightCard({
    required this.badgeText,
    required this.badgeColor,
    required this.rider,
  });

  final String badgeText;
  final Color badgeColor;
  final SeasonWrappedRiderHighlight rider;

  @override
  Widget build(BuildContext context) {
    return _StoryCard(
      borderColor: badgeColor.withValues(alpha: 0.45),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.6)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    color: badgeColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'OVR ${rider.ovr}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${rider.name} (${rider.nationalityCode})',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rider.role,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatPill(label: '${rider.wins} wygranych'),
              _StatPill(label: '${rider.uciPoints} pkt UCI'),
              _StatPill(
                  label: '${rider.peakWPerKg.toStringAsFixed(2)} W/kg'),
            ],
          ),
          if (rider.bestMoment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              rider.bestMoment,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _StoryMomentTile extends StatefulWidget {
  const _StoryMomentTile({
    required this.moment,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final SeasonWrappedKeyMoment moment;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_StoryMomentTile> createState() => _StoryMomentTileState();
}

class _StoryMomentTileState extends State<_StoryMomentTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? AppColors.goldAccent
        : (_focused
            ? AppColors.accentBlue
            : (_hovered
                ? AppColors.goldAccent.withValues(alpha: 0.5)
                : AppTheme.borderColor));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _pressed ? 0.99 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.primaryAccent.withValues(alpha: 0.22)
                  : (_hovered
                      ? AppColors.surfaceLight
                      : AppColors.background.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              children: [
                Icon(
                  widget.moment.isMonumentOrGrandTour
                      ? Icons.military_tech_rounded
                      : Icons.flag_rounded,
                  size: 18,
                  color: widget.isSelected
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.moment.raceName,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${widget.moment.category} • ${widget.moment.dateLabel}',
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
                Text(
                  widget.moment.statBadge,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.isSelected
                        ? AppColors.goldAccent
                        : AppColors.accentBlue,
                    fontFeatures: const [FontFeature.tabularFigures()],
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

class _StoryInteractiveSegment extends StatefulWidget {
  const _StoryInteractiveSegment({
    required this.tooltip,
    required this.enabled,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_StoryInteractiveSegment> createState() =>
      _StoryInteractiveSegmentState();
}

class _StoryInteractiveSegmentState extends State<_StoryInteractiveSegment> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        mouseCursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: _focused
                  ? Border.all(color: AppColors.accentBlue, width: 1.0)
                  : null,
            ),
            child: Opacity(
              opacity: widget.enabled ? (_hovered ? 1.0 : 0.92) : 0.45,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryInteractiveButton extends StatefulWidget {
  const _StoryInteractiveButton({
    super.key,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.isPrimary = false,
  });

  final IconData icon;
  final String? label;
  final bool enabled;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  State<_StoryInteractiveButton> createState() =>
      _StoryInteractiveButtonState();
}

class _StoryInteractiveButtonState extends State<_StoryInteractiveButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = !widget.enabled || widget.onPressed == null;
    final Color baseBg = widget.isPrimary
        ? AppColors.primaryAccent
        : AppColors.surfaceLight;
    final Color bg = isDisabled
        ? AppColors.surface.withValues(alpha: 0.5)
        : (_pressed
            ? baseBg.withValues(alpha: 0.78)
            : (_hovered ? baseBg.withValues(alpha: 0.95) : baseBg));
    final Color borderColor = isDisabled
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : (_focused
            ? AppColors.accentBlue
            : (_hovered
                ? AppColors.goldAccent
                : (widget.isPrimary
                    ? AppColors.goldAccent.withValues(alpha: 0.65)
                    : AppTheme.borderColor)));
    final Color fg = isDisabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : (widget.isPrimary ? AppColors.textPrimary : AppColors.textPrimary);

    return FocusableActionDetector(
      enabled: !isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: !isDisabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: !isDisabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            !isDisabled ? () => setState(() => _pressed = false) : null,
        onTap: !isDisabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.label != null ? 14 : 10,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 18, color: fg),
                if (widget.label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    widget.label!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryBackdropPainter extends CustomPainter {
  const _StoryBackdropPainter({
    required this.slideIndex,
    required this.totalSlides,
  });

  final int slideIndex;
  final int totalSlides;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = totalSlides > 1 ? slideIndex / (totalSlides - 1) : 0.0;

    final topGlowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(-0.6 + progress * 1.2, -0.7),
        radius: 1.1,
        colors: [
          AppColors.primaryAccent.withValues(alpha: 0.22),
          AppColors.background.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, topGlowPaint);

    final goldGlowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(0.7 - progress * 1.1, 0.85),
        radius: 0.9,
        colors: [
          AppColors.goldAccent.withValues(alpha: 0.12),
          AppColors.background.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, goldGlowPaint);

    final gridPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.22)
      ..strokeWidth = 1.0;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StoryBackdropPainter oldDelegate) {
    return oldDelegate.slideIndex != slideIndex ||
        oldDelegate.totalSlides != totalSlides;
  }
}
