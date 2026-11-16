import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Typ nawierzchni sektora klasyka monumentu.
enum SectorSurfaceKind {
  cobblestones('Bruk (Pavé)', Icons.grid_view_rounded),
  gravel('Szuter (Strade Bianche)', Icons.terrain_rounded);

  final String label;
  final IconData icon;
  const SectorSurfaceKind(this.label, this.icon);
}

/// Stan wilgotności nawierzchni na sektorze.
enum SectorMoistureCondition {
  dry(
    label: 'Suchy',
    shortLabel: 'Suchy',
    description: 'Optymalna przyczepność, wysoki poziom kurzu na poboczach.',
    pressureMultiplier: 1.00,
    gripFactor: 1.00,
    punctureRiskMultiplier: 1.00,
    accentColor: AppColors.statusSuccess,
    icon: Icons.wb_sunny_rounded,
  ),
  damp(
    label: 'Wilgotny',
    shortLabel: 'Wilgotny',
    description: 'Poranna rosa lub lekki opad — śliskie krawędzie kamieni.',
    pressureMultiplier: 0.94,
    gripFactor: 0.84,
    punctureRiskMultiplier: 1.25,
    accentColor: AppColors.accentBlue,
    icon: Icons.water_drop_outlined,
  ),
  wet(
    label: 'Mokry',
    shortLabel: 'Mokry',
    description: 'Deszcz i kałuże — wymagane wyraźne obniżenie ciśnienia.',
    pressureMultiplier: 0.88,
    gripFactor: 0.66,
    punctureRiskMultiplier: 1.55,
    accentColor: AppColors.amberWarning,
    icon: Icons.umbrella_rounded,
  ),
  muddy(
    label: 'Błoto / Ekstremalnie śliski',
    shortLabel: 'Błoto',
    description: 'Warstwa błota między brukiem — maksymalna powierzchnia styku.',
    pressureMultiplier: 0.82,
    gripFactor: 0.48,
    punctureRiskMultiplier: 1.95,
    accentColor: AppColors.crimsonAlert,
    icon: Icons.warning_amber_rounded,
  );

  final String label;
  final String shortLabel;
  final String description;
  final double pressureMultiplier;
  final double gripFactor;
  final double punctureRiskMultiplier;
  final Color accentColor;
  final IconData icon;

  const SectorMoistureCondition({
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.pressureMultiplier,
    required this.gripFactor,
    required this.punctureRiskMultiplier,
    required this.accentColor,
    required this.icon,
  });
}

/// Filtr listy sektorów w inspektorze.
enum SectorInspectorFilter {
  all('Wszystkie'),
  cobblesOnly('Bruk'),
  gravelOnly('Szuter'),
  fiveStars('5★ Piekielne');

  final String label;
  const SectorInspectorFilter(this.label);
}

/// Model pojedynczego sektora brukowanego lub szutrowego.
class MonumentSectorData {
  final String id;
  final int sectorNumber;
  final String name;
  final String monumentName;
  final SectorSurfaceKind surfaceKind;
  final int lengthMeters;
  final int starRating;
  final double averageGradientPercent;
  final double maxGradientPercent;
  final double distanceFromStartKm;
  final double distanceToFinishKm;
  final SectorMoistureCondition moistureCondition;
  final double cobbleCrownHeightMm;
  final double roadWidthMeters;
  final String tacticalNotes;

  const MonumentSectorData({
    required this.id,
    required this.sectorNumber,
    required this.name,
    required this.monumentName,
    required this.surfaceKind,
    required this.lengthMeters,
    required this.starRating,
    required this.averageGradientPercent,
    required this.maxGradientPercent,
    required this.distanceFromStartKm,
    required this.distanceToFinishKm,
    required this.moistureCondition,
    required this.cobbleCrownHeightMm,
    required this.roadWidthMeters,
    required this.tacticalNotes,
  }) : assert(starRating >= 1 && starRating <= 5);

  MonumentSectorData copyWith({
    SectorMoistureCondition? moistureCondition,
  }) {
    return MonumentSectorData(
      id: id,
      sectorNumber: sectorNumber,
      name: name,
      monumentName: monumentName,
      surfaceKind: surfaceKind,
      lengthMeters: lengthMeters,
      starRating: starRating,
      averageGradientPercent: averageGradientPercent,
      maxGradientPercent: maxGradientPercent,
      distanceFromStartKm: distanceFromStartKm,
      distanceToFinishKm: distanceToFinishKm,
      moistureCondition: moistureCondition ?? this.moistureCondition,
      cobbleCrownHeightMm: cobbleCrownHeightMm,
      roadWidthMeters: roadWidthMeters,
      tacticalNotes: tacticalNotes,
    );
  }
}

/// Wyliczona rekomendacja ciśnienia i zachowania opony na sektorze.
class TirePressureRecommendation {
  final String sectorId;
  final double frontBar;
  final double rearBar;
  final double frontPsi;
  final double rearPsi;
  final double crrEstimate;
  final double pinchFlatRiskPercent;
  final double gripScorePercent;
  final double vibrationDampingPercent;
  final String setupAdvisory;

  const TirePressureRecommendation({
    required this.sectorId,
    required this.frontBar,
    required this.rearBar,
    required this.frontPsi,
    required this.rearPsi,
    required this.crrEstimate,
    required this.pinchFlatRiskPercent,
    required this.gripScorePercent,
    required this.vibrationDampingPercent,
    required this.setupAdvisory,
  });
}

/// Kalkulator rekomendowanego ciśnienia opon dla sektorów brukowanych i szutrowych.
class MonumentSectorPressureAdvisor {
  MonumentSectorPressureAdvisor._();

  static const double _barToPsi = 14.50377;

  static TirePressureRecommendation calculate({
    required MonumentSectorData sector,
    required SectorMoistureCondition moisture,
    required double systemWeightKg,
    required double tireWidthMm,
    required bool isTubeless,
  }) {
    final double clampedWeight = systemWeightKg.clamp(55.0, 105.0);
    final double clampedWidth = tireWidthMm.clamp(25.0, 45.0);

    // Bazowe ciśnienie referencyjne dla 75 kg, opony 30 mm na średnim asfalcie (~5.35 BAR).
    final double widthRatio = 30.0 / clampedWidth;
    final double weightRatio = clampedWeight / 75.0;
    double baseBar = 5.35 * math.pow(widthRatio, 1.38) * math.pow(weightRatio, 0.72);

    // Modyfikator trudności nawierzchni (1-5 gwiazdek i szuter).
    final double surfaceFactor = sector.surfaceKind == SectorSurfaceKind.gravel
        ? 0.72 - (sector.starRating - 1) * 0.025
        : 0.88 - (sector.starRating - 1) * 0.032;

    baseBar *= surfaceFactor;
    baseBar *= moisture.pressureMultiplier;

    // Dętka wymaga nieco wyższego ciśnienia dla ochrony przed snakebite.
    if (!isTubeless) {
      baseBar *= 1.07;
    }

    // Lekka korekta na strome podjazdy brukowane (>6% -> lepsza trakcja tylnego koła).
    if (sector.averageGradientPercent > 6.0) {
      baseBar *= 0.97;
    }

    // Rozkład masy przód 44% / tył 56%.
    final double minSafeBar = isTubeless ? 2.4 : 3.0;
    const double maxSafeBar = 7.2;

    final double frontBar = (baseBar * 0.94).clamp(minSafeBar, maxSafeBar);
    final double rearBar = (baseBar * 1.04).clamp(minSafeBar + 0.15, maxSafeBar);

    // Szacowany opór toczenia Crr.
    final double baseCrr = sector.surfaceKind == SectorSurfaceKind.gravel
        ? 0.0085
        : 0.0075 + sector.starRating * 0.0014;
    final double moistureCrrDelta = moisture == SectorMoistureCondition.muddy
        ? 0.0032
        : (moisture == SectorMoistureCondition.wet ? 0.0014 : 0.0);
    final double widthCrrBonus = (clampedWidth - 28.0) * 0.00012;
    final double crrEstimate =
        (baseCrr + moistureCrrDelta - widthCrrBonus).clamp(0.0050, 0.0220);

    // Ryzyko przyszczypnięcia (snakebite) i defektu.
    double pinchRisk = (sector.starRating * 4.5) *
        moisture.punctureRiskMultiplier *
        (32.0 / clampedWidth);
    if (isTubeless) {
      pinchRisk *= 0.35;
    }
    if (rearBar < 3.4 && !isTubeless) {
      pinchRisk += 14.0;
    }
    final double pinchFlatRiskPercent = pinchRisk.clamp(1.5, 48.0);

    // Przyczepność oraz tłumienie wibracji.
    final double gripScore = (moisture.gripFactor * 78.0 +
            (clampedWidth - 25.0) * 1.15 +
            (isTubeless ? 7.0 : 0.0))
        .clamp(32.0, 99.0);

    final double dampingScore = (60.0 +
            (clampedWidth - 25.0) * 2.1 +
            (isTubeless ? 8.0 : -4.0) -
            (rearBar - 3.5) * 6.5)
        .clamp(25.0, 98.0);

    final String advisory = _buildAdvisory(
      sector: sector,
      moisture: moisture,
      tireWidthMm: clampedWidth,
      isTubeless: isTubeless,
      rearBar: rearBar,
    );

    return TirePressureRecommendation(
      sectorId: sector.id,
      frontBar: _round2(frontBar),
      rearBar: _round2(rearBar),
      frontPsi: _round1(frontBar * _barToPsi),
      rearPsi: _round1(rearBar * _barToPsi),
      crrEstimate: crrEstimate,
      pinchFlatRiskPercent: _round1(pinchFlatRiskPercent),
      gripScorePercent: _round1(gripScore),
      vibrationDampingPercent: _round1(dampingScore),
      setupAdvisory: advisory,
    );
  }

  static String _buildAdvisory({
    required MonumentSectorData sector,
    required SectorMoistureCondition moisture,
    required double tireWidthMm,
    required bool isTubeless,
    required double rearBar,
  }) {
    if (sector.starRating == 5 &&
        (moisture == SectorMoistureCondition.wet ||
            moisture == SectorMoistureCondition.muddy)) {
      return 'Krytyczne warunki na 5★: utrzymuj kadencję 85–92 RPM, jedź koroną bruku i unikaj głębokich rynien po bokach.';
    }
    if (sector.averageGradientPercent >= 10.0) {
      return 'Stromy podjazd (${sector.averageGradientPercent.toStringAsFixed(1)}%): obniżone ciśnienie tylnego koła (${rearBar.toStringAsFixed(2)} BAR) zapobiega buksowaniu na stojąco.';
    }
    if (!isTubeless && tireWidthMm < 30.0) {
      return 'Ostrzeżenie: wąska opona z dętką (<30 mm) zwiększa ryzyko snakebite. Rozważ Tubeless ≥32 mm.';
    }
    if (sector.surfaceKind == SectorSurfaceKind.gravel) {
      return 'Długi szuter: szerokie ogumienie (${tireWidthMm.toStringAsFixed(0)} mm) redukuje straty impedancji i poprawia kontrolę w zakrętach.';
    }
    return 'Zbalansowany dobór BAR/PSI pod kątem minimalnych strat histerezy oraz ochrony obręczy.';
  }

  static double _round1(double v) => (v * 10).roundToDouble() / 10;
  static double _round2(double v) => (v * 100).roundToDouble() / 100;
}

/// Katalog historycznych sektorów brukowanych i szutrowych monumentów.
class MonumentCobbleSectorsCatalog {
  MonumentCobbleSectorsCatalog._();

  static List<MonumentSectorData> defaultMonumentSectors() {
    return const [
      MonumentSectorData(
        id: 'trouee_arenberg',
        sectorNumber: 19,
        name: "Trouée d'Arenberg",
        monumentName: 'Paris-Roubaix',
        surfaceKind: SectorSurfaceKind.cobblestones,
        lengthMeters: 2300,
        starRating: 5,
        averageGradientPercent: -0.4,
        maxGradientPercent: 1.5,
        distanceFromStartKm: 164.0,
        distanceToFinishKm: 95.3,
        moistureCondition: SectorMoistureCondition.damp,
        cobbleCrownHeightMm: 44.0,
        roadWidthMeters: 3.4,
        tacticalNotes:
            'Wjazd z prędkością >55 km/h na lekkim zjeździe. Kluczowa pozycja w Top 15 przed lasem Wallers.',
      ),
      MonumentSectorData(
        id: 'mons_en_pevele',
        sectorNumber: 11,
        name: 'Mons-en-Pévèle',
        monumentName: 'Paris-Roubaix',
        surfaceKind: SectorSurfaceKind.cobblestones,
        lengthMeters: 3000,
        starRating: 5,
        averageGradientPercent: 1.1,
        maxGradientPercent: 4.2,
        distanceFromStartKm: 211.0,
        distanceToFinishKm: 48.6,
        moistureCondition: SectorMoistureCondition.dry,
        cobbleCrownHeightMm: 40.0,
        roadWidthMeters: 3.6,
        tacticalNotes:
            'Dwa zakręty 90° w błocie lub kurzu oraz wyboista końcówka pod górę — częste ataki liderów.',
      ),
      MonumentSectorData(
        id: 'carrefour_de_larbre',
        sectorNumber: 4,
        name: "Carrefour de l'Arbre",
        monumentName: 'Paris-Roubaix',
        surfaceKind: SectorSurfaceKind.cobblestones,
        lengthMeters: 2100,
        starRating: 5,
        averageGradientPercent: 0.5,
        maxGradientPercent: 2.8,
        distanceFromStartKm: 242.5,
        distanceToFinishKm: 17.1,
        moistureCondition: SectorMoistureCondition.dry,
        cobbleCrownHeightMm: 42.0,
        roadWidthMeters: 3.5,
        tacticalNotes:
            'Ostatni 5-gwiazdkowy sektor przed welodromem w Roubaix. Decydujący punkt selekcji finałowej.',
      ),
      MonumentSectorData(
        id: 'oude_kwaremont',
        sectorNumber: 14,
        name: 'Oude Kwaremont',
        monumentName: 'Ronde van Vlaanderen',
        surfaceKind: SectorSurfaceKind.cobblestones,
        lengthMeters: 2200,
        starRating: 4,
        averageGradientPercent: 4.0,
        maxGradientPercent: 11.6,
        distanceFromStartKm: 254.0,
        distanceToFinishKm: 16.8,
        moistureCondition: SectorMoistureCondition.damp,
        cobbleCrownHeightMm: 28.0,
        roadWidthMeters: 4.1,
        tacticalNotes:
            'Długa, wyczerpująca wspinaczka po fałszywym wypłaszczeniu na szczycie — wymaga >6.2 W/kg przez 4 min.',
      ),
      MonumentSectorData(
        id: 'paterberg',
        sectorNumber: 15,
        name: 'Paterberg',
        monumentName: 'Ronde van Vlaanderen',
        surfaceKind: SectorSurfaceKind.cobblestones,
        lengthMeters: 360,
        starRating: 5,
        averageGradientPercent: 12.9,
        maxGradientPercent: 20.3,
        distanceFromStartKm: 257.5,
        distanceToFinishKm: 13.3,
        moistureCondition: SectorMoistureCondition.wet,
        cobbleCrownHeightMm: 30.0,
        roadWidthMeters: 3.1,
        tacticalNotes:
            'Ściana bruku >20% nachylenia. Wąski rynsztok po prawej stronie często bywa jedynym płynnym torem.',
      ),
      MonumentSectorData(
        id: 'koppenberg',
        sectorNumber: 11,
        name: 'Koppenberg',
        monumentName: 'Ronde van Vlaanderen',
        surfaceKind: SectorSurfaceKind.cobblestones,
        lengthMeters: 600,
        starRating: 5,
        averageGradientPercent: 11.6,
        maxGradientPercent: 22.0,
        distanceFromStartKm: 226.0,
        distanceToFinishKm: 44.8,
        moistureCondition: SectorMoistureCondition.muddy,
        cobbleCrownHeightMm: 36.0,
        roadWidthMeters: 2.9,
        tacticalNotes:
            'Wąskie gardło Flandrii. W mokrych warunkach kolarze z tyłu zmuszeni są do zejścia z roweru.',
      ),
      MonumentSectorData(
        id: 'monte_sante_marie',
        sectorNumber: 8,
        name: 'Monte Sante Marie',
        monumentName: 'Strade Bianche',
        surfaceKind: SectorSurfaceKind.gravel,
        lengthMeters: 11500,
        starRating: 5,
        averageGradientPercent: 3.8,
        maxGradientPercent: 18.0,
        distanceFromStartKm: 131.0,
        distanceToFinishKm: 84.0,
        moistureCondition: SectorMoistureCondition.dry,
        cobbleCrownHeightMm: 22.0,
        roadWidthMeters: 4.5,
        tacticalNotes:
            'Najcięższy sektor białego szutru w Toskanii — strome rampy szutrowe i szybkie, sypkie zjazdy.',
      ),
      MonumentSectorData(
        id: 'cambron_casteau',
        sectorNumber: 24,
        name: 'Quiévy à Saint-Python',
        monumentName: 'Paris-Roubaix',
        surfaceKind: SectorSurfaceKind.cobblestones,
        lengthMeters: 1800,
        starRating: 3,
        averageGradientPercent: 0.4,
        maxGradientPercent: 2.1,
        distanceFromStartKm: 118.0,
        distanceToFinishKm: 141.6,
        moistureCondition: SectorMoistureCondition.dry,
        cobbleCrownHeightMm: 26.0,
        roadWidthMeters: 4.2,
        tacticalNotes:
            'Sektor otwierający selekcję: wysokie tempo peletonu i walka pociągów o ustawienie liderów.',
      ),
    ];
  }
}

/// Szczegółowy modal inspektora sektorów brukowanych i szutrowych monumentów.
class MonumentCobbleSectorsInspectorModal extends StatefulWidget {
  final List<MonumentSectorData> sectors;
  final String? initialSectorId;
  final double initialTireWidthMm;
  final double initialSystemWeightKg;
  final bool initialIsTubeless;
  final ValueChanged<TirePressureRecommendation>? onApplyPressureSetup;
  final VoidCallback? onClose;

  const MonumentCobbleSectorsInspectorModal({
    super.key,
    required this.sectors,
    this.initialSectorId,
    this.initialTireWidthMm = 32.0,
    this.initialSystemWeightKg = 76.0,
    this.initialIsTubeless = true,
    this.onApplyPressureSetup,
    this.onClose,
  });

  /// Wyświetla modal inspektora sektorów brukowanych i szutrowych jako okno dialogowe.
  static Future<TirePressureRecommendation?> show(
    BuildContext context, {
    List<MonumentSectorData>? sectors,
    String? initialSectorId,
    double initialTireWidthMm = 32.0,
    double initialSystemWeightKg = 76.0,
    bool initialIsTubeless = true,
  }) {
    final List<MonumentSectorData> resolvedSectors =
        sectors ?? MonumentCobbleSectorsCatalog.defaultMonumentSectors();
    return showDialog<TirePressureRecommendation>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: MonumentCobbleSectorsInspectorModal(
            sectors: resolvedSectors,
            initialSectorId: initialSectorId,
            initialTireWidthMm: initialTireWidthMm,
            initialSystemWeightKg: initialSystemWeightKg,
            initialIsTubeless: initialIsTubeless,
            onApplyPressureSetup: (rec) {
              Navigator.of(dialogContext).pop(rec);
            },
            onClose: () => Navigator.of(dialogContext).pop(),
          ),
        );
      },
    );
  }

  @override
  State<MonumentCobbleSectorsInspectorModal> createState() =>
      _MonumentCobbleSectorsInspectorModalState();
}

class _MonumentCobbleSectorsInspectorModalState
    extends State<MonumentCobbleSectorsInspectorModal> {
  static const List<double> _availableTireWidths = [28.0, 30.0, 32.0, 34.0, 38.0];

  late String _selectedSectorId;
  SectorInspectorFilter _activeFilter = SectorInspectorFilter.all;
  late double _tireWidthMm;
  late double _systemWeightKg;
  late bool _isTubeless;
  final Map<String, SectorMoistureCondition> _moistureOverrides = {};
  bool _appliedFeedback = false;

  @override
  void initState() {
    super.initState();
    _tireWidthMm = widget.initialTireWidthMm.clamp(28.0, 38.0);
    _systemWeightKg = widget.initialSystemWeightKg.clamp(60.0, 95.0);
    _isTubeless = widget.initialIsTubeless;
    _selectedSectorId = _resolveInitialSectorId();
  }

  String _resolveInitialSectorId() {
    if (widget.sectors.isEmpty) return '';
    if (widget.initialSectorId != null &&
        widget.sectors.any((s) => s.id == widget.initialSectorId)) {
      return widget.initialSectorId!;
    }
    return widget.sectors.first.id;
  }

  List<MonumentSectorData> get _filteredSectors {
    return widget.sectors.where((sector) {
      switch (_activeFilter) {
        case SectorInspectorFilter.all:
          return true;
        case SectorInspectorFilter.cobblesOnly:
          return sector.surfaceKind == SectorSurfaceKind.cobblestones;
        case SectorInspectorFilter.gravelOnly:
          return sector.surfaceKind == SectorSurfaceKind.gravel;
        case SectorInspectorFilter.fiveStars:
          return sector.starRating == 5;
      }
    }).toList(growable: false);
  }

  MonumentSectorData? get _selectedSector {
    if (widget.sectors.isEmpty) return null;
    for (final s in widget.sectors) {
      if (s.id == _selectedSectorId) return s;
    }
    return widget.sectors.first;
  }

  SectorMoistureCondition _effectiveMoisture(MonumentSectorData sector) {
    return _moistureOverrides[sector.id] ?? sector.moistureCondition;
  }

  void _selectFilter(SectorInspectorFilter filter) {
    setState(() {
      _activeFilter = filter;
      final filtered = _filteredSectors;
      if (filtered.isNotEmpty && !filtered.any((s) => s.id == _selectedSectorId)) {
        _selectedSectorId = filtered.first.id;
      }
    });
  }

  void _setMoisture(MonumentSectorData sector, SectorMoistureCondition condition) {
    setState(() {
      _moistureOverrides[sector.id] = condition;
      _appliedFeedback = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxW = constraints.maxWidth;
        final double maxH = constraints.maxHeight;
        final bool isCompact = maxW < 680;
        final bool isDesktop = maxW >= 1100;

        final double modalWidth = isCompact
            ? maxW
            : (isDesktop ? math.min(maxW, 1220.0) : math.min(maxW, 960.0));
        final double modalHeight = isCompact
            ? maxH
            : math.min(maxH, isDesktop ? 820.0 : 720.0);

        return Center(
          child: Container(
            width: modalWidth,
            height: modalHeight,
            decoration: BoxDecoration(
              color: AppColors.background,
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
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildHeader(isCompact: isCompact),
                const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
                Expanded(
                  child: widget.sectors.isEmpty
                      ? _buildEmptyState()
                      : (isCompact
                          ? _buildCompactBody()
                          : _buildSplitBody(isDesktop: isDesktop)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({required bool isCompact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: isCompact ? 12 : 14,
      ),
      color: AppColors.surface,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.45),
                width: 1.0,
              ),
            ),
            child: const Icon(
              Icons.route_rounded,
              color: AppColors.goldAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Inspektor Sektorów Brukowanych i Szutrowych',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                    fontSize: isCompact ? 15 : 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Rekonesans Pavé & Strade Bianche • Dobór ciśnienia BAR/PSI',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _InteractiveIconButton(
            tooltip: 'Zamknij inspektor',
            icon: Icons.close_rounded,
            onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Brak zdefiniowanych sektorów brukowanych lub szutrowych dla tego wyścigu.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            letterSpacing: -0.2,
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactBody() {
    final MonumentSectorData? sector = _selectedSector;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilterStrip(),
          const SizedBox(height: 12),
          SizedBox(
            height: 132,
            child: _filteredSectors.isEmpty
                ? _buildNoFilterMatches()
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filteredSectors.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final s = _filteredSectors[index];
                      return SizedBox(
                        width: 240,
                        child: _SectorListTile(
                          sector: s,
                          moisture: _effectiveMoisture(s),
                          isSelected: s.id == _selectedSectorId,
                          onTap: () => setState(() {
                            _selectedSectorId = s.id;
                            _appliedFeedback = false;
                          }),
                        ),
                      );
                    },
                  ),
          ),
          if (sector != null) ...[
            const SizedBox(height: 14),
            _buildInspectorDetails(sector, isCompact: true),
          ],
        ],
      ),
    );
  }

  Widget _buildSplitBody({required bool isDesktop}) {
    final MonumentSectorData? sector = _selectedSector;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: isDesktop ? 4 : 5,
          child: Container(
            color: AppColors.background,
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFilterStrip(),
                const SizedBox(height: 12),
                Expanded(
                  child: _filteredSectors.isEmpty
                      ? _buildNoFilterMatches()
                      : ListView.separated(
                          itemCount: _filteredSectors.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final s = _filteredSectors[index];
                            return _SectorListTile(
                              sector: s,
                              moisture: _effectiveMoisture(s),
                              isSelected: s.id == _selectedSectorId,
                              onTap: () => setState(() {
                                _selectedSectorId = s.id;
                                _appliedFeedback = false;
                              }),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1, color: AppTheme.borderColor),
        Expanded(
          flex: isDesktop ? 6 : 7,
          child: sector == null
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: _buildInspectorDetails(sector, isCompact: false),
                ),
        ),
      ],
    );
  }

  Widget _buildNoFilterMatches() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: const Center(
        child: Text(
          'Brak sektorów spełniających wybrane kryteria filtra.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            letterSpacing: -0.2,
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterStrip() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SectorInspectorFilter.values.map((filter) {
        final bool isSelected = _activeFilter == filter;
        return _InteractivePillButton(
          label: filter.label,
          isSelected: isSelected,
          onTap: () => _selectFilter(filter),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildInspectorDetails(
    MonumentSectorData sector, {
    required bool isCompact,
  }) {
    final SectorMoistureCondition moisture = _effectiveMoisture(sector);
    final TirePressureRecommendation recommendation =
        MonumentSectorPressureAdvisor.calculate(
      sector: sector,
      moisture: moisture,
      systemWeightKg: _systemWeightKg,
      tireWidthMm: _tireWidthMm,
      isTubeless: _isTubeless,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectorHeroCard(sector, moisture, isCompact: isCompact),
        const SizedBox(height: 12),
        _buildTelemetryGrid(sector, moisture, isCompact: isCompact),
        const SizedBox(height: 12),
        _buildMoistureSelectorCard(sector, moisture),
        const SizedBox(height: 12),
        _buildTirePressureAdvisorCard(
          sector: sector,
          moisture: moisture,
          recommendation: recommendation,
          isCompact: isCompact,
        ),
      ],
    );
  }

  Widget _buildSectorHeroCard(
    MonumentSectorData sector,
    SectorMoistureCondition moisture, {
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primaryAccent,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            'SEKTOR #${sector.sectorNumber} • ${sector.monumentName.toUpperCase()}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              letterSpacing: 0.2,
                              color: AppColors.textPrimary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _StarRatingBadge(rating: sector.starRating),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sector.name,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                        fontSize: isCompact ? 19 : 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: moisture.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: moisture.accentColor.withValues(alpha: 0.55),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(moisture.icon, size: 14, color: moisture.accentColor),
                    const SizedBox(width: 5),
                    Text(
                      moisture.shortLabel,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.2,
                        color: moisture.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 76,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: _SectorSurfaceProfilePainter(
                  sector: sector,
                  moisture: moisture,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            sector.tacticalNotes,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryGrid(
    MonumentSectorData sector,
    SectorMoistureCondition moisture, {
    required bool isCompact,
  }) {
    final List<_MetricTileData> metrics = [
      _MetricTileData(
        label: 'Długość sektora',
        value: '${sector.lengthMeters} m',
        subtitle: '${(sector.lengthMeters / 1000).toStringAsFixed(2)} km',
        accent: AppColors.goldAccent,
        icon: Icons.straighten_rounded,
      ),
      _MetricTileData(
        label: 'Ocena trudności',
        value: '${sector.starRating} / 5 ★',
        subtitle: sector.surfaceKind.label,
        accent: AppColors.amberWarning,
        icon: Icons.star_rounded,
      ),
      _MetricTileData(
        label: 'Nachylenie (śr / max)',
        value:
            '${sector.averageGradientPercent >= 0 ? '+' : ''}${sector.averageGradientPercent.toStringAsFixed(1)}%',
        subtitle: 'Max ${sector.maxGradientPercent.toStringAsFixed(1)}%',
        accent: sector.averageGradientPercent >= 8.0
            ? AppColors.crimsonAlert
            : AppColors.accentBlue,
        icon: Icons.trending_up_rounded,
      ),
      _MetricTileData(
        label: 'Szerokość / Korona',
        value: '${sector.roadWidthMeters.toStringAsFixed(1)} m',
        subtitle: 'Nierówność ${sector.cobbleCrownHeightMm.toStringAsFixed(0)} mm',
        accent: AppColors.cyanAccent,
        icon: Icons.swap_horiz_rounded,
      ),
    ];

    if (isCompact) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: metrics.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.85,
        ),
        itemBuilder: (_, i) => _MetricCard(data: metrics[i]),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < metrics.length; i++) ...[
          Expanded(child: _MetricCard(data: metrics[i])),
          if (i < metrics.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildMoistureSelectorCard(
    MonumentSectorData sector,
    SectorMoistureCondition activeMoisture,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.water_drop_rounded,
                size: 16,
                color: AppColors.accentBlue,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Stan wilgotności nawierzchni (symulacja pogody)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Przyczepność ${(activeMoisture.gripFactor * 100).round()}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  color: activeMoisture.accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SectorMoistureCondition.values.map((condition) {
              final bool isSelected = condition == activeMoisture;
              return _InteractivePillButton(
                label: condition.shortLabel,
                icon: condition.icon,
                accentColor: condition.accentColor,
                isSelected: isSelected,
                onTap: () => _setMoisture(sector, condition),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 8),
          Text(
            activeMoisture.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTirePressureAdvisorCard({
    required MonumentSectorData sector,
    required SectorMoistureCondition moisture,
    required TirePressureRecommendation recommendation,
    required bool isCompact,
  }) {
    final bool canApply = widget.onApplyPressureSetup != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tire_repair_rounded,
                size: 17,
                color: AppColors.goldAccent,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Rekomendowane ciśnienie w oponach',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor, width: 1.0),
                ),
                child: Text(
                  'Crr ${recommendation.crrEstimate.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: AppColors.cyanAccent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PressureReadoutBox(
                  wheelLabel: 'PRZÓD (FRONT)',
                  barValue: recommendation.frontBar,
                  psiValue: recommendation.frontPsi,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PressureReadoutBox(
                  wheelLabel: 'TYŁ (REAR)',
                  barValue: recommendation.rearBar,
                  psiValue: recommendation.rearPsi,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Szerokość:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ..._availableTireWidths.map((w) {
                return _InteractivePillButton(
                  label: '${w.toInt()} mm',
                  isSelected: (_tireWidthMm - w).abs() < 0.1,
                  onTap: () => setState(() {
                    _tireWidthMm = w;
                    _appliedFeedback = false;
                  }),
                );
              }),
              _InteractivePillButton(
                label: _isTubeless ? 'Tubeless' : 'Dętka',
                icon: _isTubeless ? Icons.shield_rounded : Icons.circle_outlined,
                accentColor:
                    _isTubeless ? AppColors.statusSuccess : AppColors.amberWarning,
                isSelected: true,
                onTap: () => setState(() {
                  _isTubeless = !_isTubeless;
                  _appliedFeedback = false;
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masa kolarza + rower: ${_systemWeightKg.toStringAsFixed(0)} kg',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.goldAccent,
                    inactiveTrackColor: AppColors.surfaceLight,
                    thumbColor: AppColors.goldAccent,
                    overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _systemWeightKg,
                    min: 60.0,
                    max: 95.0,
                    divisions: 35,
                    onChanged: (val) => setState(() {
                      _systemWeightKg = val;
                      _appliedFeedback = false;
                    }),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Masa kolarza + rower: ${_systemWeightKg.toStringAsFixed(0)} kg',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      letterSpacing: -0.2,
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.goldAccent,
                      inactiveTrackColor: AppColors.surfaceLight,
                      thumbColor: AppColors.goldAccent,
                      overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _systemWeightKg,
                      min: 60.0,
                      max: 95.0,
                      divisions: 35,
                      onChanged: (val) => setState(() {
                        _systemWeightKg = val;
                        _appliedFeedback = false;
                      }),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _MiniStatBadge(
                label: 'Tłumienie wibracji',
                value: '${recommendation.vibrationDampingPercent.toStringAsFixed(0)}%',
                color: AppColors.statusSuccess,
              ),
              _MiniStatBadge(
                label: 'Przyczepność',
                value: '${recommendation.gripScorePercent.toStringAsFixed(0)}%',
                color: AppColors.accentBlue,
              ),
              _MiniStatBadge(
                label: 'Ryzyko snakebite',
                value: '${recommendation.pinchFlatRiskPercent.toStringAsFixed(1)}%',
                color: recommendation.pinchFlatRiskPercent > 18.0
                    ? AppColors.crimsonAlert
                    : AppColors.amberWarning,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor, width: 1.0),
            ),
            child: Text(
              recommendation.setupAdvisory,
              style: const TextStyle(
                fontFamily: 'Inter',
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InteractiveActionButton(
                  label: _appliedFeedback
                      ? 'Zastosowano w warsztacie'
                      : 'Zastosuj ciśnienie mechanika',
                  icon: _appliedFeedback
                      ? Icons.check_circle_rounded
                      : Icons.build_circle_rounded,
                  isPrimary: true,
                  enabled: canApply,
                  onPressed: () {
                    setState(() => _appliedFeedback = true);
                    widget.onApplyPressureSetup?.call(recommendation);
                  },
                ),
                const SizedBox(height: 8),
                _InteractiveActionButton(
                  label: 'Zamknij',
                  icon: Icons.close_rounded,
                  isPrimary: false,
                  enabled: true,
                  onPressed:
                      widget.onClose ?? () => Navigator.of(context).maybePop(),
                ),
              ],
            )
          else
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 8,
              children: [
                _InteractiveActionButton(
                  label: 'Zamknij',
                  icon: Icons.close_rounded,
                  isPrimary: false,
                  enabled: true,
                  onPressed:
                      widget.onClose ?? () => Navigator.of(context).maybePop(),
                ),
                _InteractiveActionButton(
                  label: _appliedFeedback
                      ? 'Zastosowano w warsztacie'
                      : 'Zastosuj ciśnienie mechanika',
                  icon: _appliedFeedback
                      ? Icons.check_circle_rounded
                      : Icons.build_circle_rounded,
                  isPrimary: true,
                  enabled: canApply,
                  onPressed: () {
                    setState(() => _appliedFeedback = true);
                    widget.onApplyPressureSetup?.call(recommendation);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SectorListTile extends StatefulWidget {
  final MonumentSectorData sector;
  final SectorMoistureCondition moisture;
  final bool isSelected;
  final VoidCallback onTap;

  const _SectorListTile({
    required this.sector,
    required this.moisture,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SectorListTile> createState() => _SectorListTileState();
}

class _SectorListTileState extends State<_SectorListTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.isSelected
        ? AppColors.goldAccent
        : (_focused
            ? AppColors.cyanAccent
            : (_hovered
                ? AppColors.goldAccent.withValues(alpha: 0.45)
                : AppTheme.borderColor));

    final Color bgColor = widget.isSelected
        ? AppColors.primaryAccent.withValues(alpha: 0.22)
        : (_pressed
            ? AppColors.surfaceLight.withValues(alpha: 0.9)
            : (_hovered ? AppColors.surfaceLight : AppColors.surface));

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
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
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected || _focused ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.sector.surfaceKind.icon,
                      size: 14,
                      color: AppColors.goldAccent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '#${widget.sector.sectorNumber} ${widget.sector.monumentName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          letterSpacing: -0.2,
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _StarRatingBadge(rating: widget.sector.starRating, compact: true),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.sector.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${widget.sector.lengthMeters} m',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.sector.averageGradientPercent >= 0 ? '+' : ''}${widget.sector.averageGradientPercent.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.2,
                        color: AppColors.accentBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            widget.moisture.icon,
                            size: 13,
                            color: widget.moisture.accentColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.moisture.shortLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                letterSpacing: -0.2,
                                color: widget.moisture.accentColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarRatingBadge extends StatelessWidget {
  final int rating;
  final bool compact;

  const _StarRatingBadge({
    required this.rating,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final bool filled = index < rating;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: compact ? 13 : 15,
          color: filled ? AppColors.goldAccent : AppColors.textSecondary.withValues(alpha: 0.4),
        );
      }),
    );
  }
}

class _MetricTileData {
  final String label;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;

  const _MetricTileData({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricTileData data;

  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 14, color: data.accent),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.subtitle,
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
    );
  }
}

class _PressureReadoutBox extends StatelessWidget {
  final String wheelLabel;
  final double barValue;
  final double psiValue;

  const _PressureReadoutBox({
    required this.wheelLabel,
    required this.barValue,
    required this.psiValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            wheelLabel,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: 0.3,
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${barValue.toStringAsFixed(2)} BAR',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.3,
                    color: AppColors.goldAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${psiValue.toStringAsFixed(0)} PSI)',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
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
    );
  }
}

class _InteractivePillButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color? accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _InteractivePillButton({
    required this.label,
    this.icon,
    this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_InteractivePillButton> createState() => _InteractivePillButtonState();
}

class _InteractivePillButtonState extends State<_InteractivePillButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = widget.accentColor ?? AppColors.goldAccent;
    final Color borderColor = widget.isSelected
        ? activeColor
        : (_focused
            ? AppColors.cyanAccent
            : (_hovered
                ? activeColor.withValues(alpha: 0.55)
                : AppTheme.borderColor));

    final Color bgColor = widget.isSelected
        ? activeColor.withValues(alpha: 0.18)
        : (_pressed
            ? AppColors.surfaceLight
            : (_hovered ? AppColors.surfaceLight : AppColors.surface));

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
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
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 13,
                    color: widget.isSelected ? activeColor : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: widget.isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight:
                        widget.isSelected ? FontWeight.w700 : FontWeight.w500,
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

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.enabled,
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
    final bool enabled = widget.enabled;
    final Color baseBg = widget.isPrimary
        ? AppColors.primaryAccent
        : AppColors.surfaceLight;
    final Color bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : (_pressed
            ? baseBg.withValues(alpha: 0.8)
            : (_hovered ? baseBg.withValues(alpha: 0.92) : baseBg));
    final Color borderColor = !enabled
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : (_focused
            ? AppColors.cyanAccent
            : (widget.isPrimary
                ? (_hovered
                    ? AppColors.goldAccent
                    : AppColors.goldAccent.withValues(alpha: 0.55))
                : (_hovered
                    ? AppColors.textSecondary
                    : AppTheme.borderColor)));

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (enabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        onEnter: (_) {
          if (enabled) setState(() => _hovered = true);
        },
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: enabled ? 1.0 : 0.45,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: _focused ? 1.6 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 16,
                    color: widget.isPrimary
                        ? AppColors.goldAccent
                        : AppColors.textPrimary,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      widget.label,
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
      child: FocusableActionDetector(
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
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
                color: _pressed || _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _focused
                      ? AppColors.cyanAccent
                      : (_hovered
                          ? AppColors.goldAccent.withValues(alpha: 0.6)
                          : AppTheme.borderColor),
                  width: _focused ? 1.5 : 1.0,
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

/// Rysuje schematyczny przekrój nawierzchni brukowej/szutrowej oraz kąt nachylenia sektora.
class _SectorSurfaceProfilePainter extends CustomPainter {
  final MonumentSectorData sector;
  final SectorMoistureCondition moisture;

  const _SectorSurfaceProfilePainter({
    required this.sector,
    required this.moisture,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()..color = AppColors.background;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Linia nachylenia terenu.
    final double normalizedSlope =
        (sector.averageGradientPercent / 18.0).clamp(-0.35, 0.75);
    final double startY = size.height * (0.68 + normalizedSlope * 0.16);
    final double endY = size.height * (0.68 - normalizedSlope * 0.28);

    final Path terrainPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, startY)
      ..lineTo(size.width, endY)
      ..lineTo(size.width, size.height)
      ..close();

    final Paint terrainFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.surfaceLight,
          AppColors.surface,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(terrainPath, terrainFill);

    // Kostki brukowe lub ziarna szutru wzdłuż profilu.
    final math.Random rng = math.Random(sector.id.hashCode);
    final int blockCount =
        sector.surfaceKind == SectorSurfaceKind.cobblestones ? 28 : 42;
    final double stepX = size.width / blockCount;

    for (int i = 0; i < blockCount; i++) {
      final double t = (i + 0.5) / blockCount;
      final double x = t * size.width;
      final double baseY = startY + (endY - startY) * t;
      final double jitter =
          (rng.nextDouble() - 0.5) * (sector.starRating * 1.15);

      if (sector.surfaceKind == SectorSurfaceKind.cobblestones) {
        final RRect stone = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, baseY + jitter - 2),
            width: math.max(5.0, stepX * 0.76),
            height: 6.5,
          ),
          const Radius.circular(2),
        );
        final Paint stonePaint = Paint()
          ..color = Color.lerp(
            const Color(0xFF4B5563),
            const Color(0xFF6B7280),
            rng.nextDouble(),
          )!;
        canvas.drawRRect(stone, stonePaint);
      } else {
        final Paint pebblePaint = Paint()
          ..color = const Color(0xFFD1D5DB).withValues(alpha: 0.65);
        canvas.drawCircle(
          Offset(x, baseY + jitter - 1.5),
          2.0 + rng.nextDouble() * 1.4,
          pebblePaint,
        );
      }
    }

    // Warstwa wilgoci / kałuż na nawierzchni.
    if (moisture != SectorMoistureCondition.dry) {
      final double alpha = moisture == SectorMoistureCondition.muddy
          ? 0.42
          : (moisture == SectorMoistureCondition.wet ? 0.30 : 0.18);
      final Paint wetLinePaint = Paint()
        ..color = moisture.accentColor.withValues(alpha: alpha)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(0, startY - 3),
        Offset(size.width, endY - 3),
        wetLinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SectorSurfaceProfilePainter oldDelegate) {
    return oldDelegate.sector.id != sector.id ||
        oldDelegate.moisture != moisture;
  }
}
