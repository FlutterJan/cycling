import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Filter categories for [CreditsAndArchitectureShowcaseScreen].
enum ArchitectureShowcaseCategory {
  all('Wszystkie', Icons.apps_rounded),
  scientificModels('Modele Naukowe', Icons.functions_rounded),
  boidsSimulation('Algorytm Boids', Icons.groups_rounded),
  blenderPipeline('Pipeline Blender .glb', Icons.view_in_ar_rounded),
  credits('Podziękowania & Stack', Icons.workspace_premium_rounded);

  const ArchitectureShowcaseCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Identifiers for the four core technical & scientific pillars of the engine.
enum ArchitectureModelId {
  skibaWPrime,
  martinCyclingPower,
  boidsFlocking,
  blenderGlbPipeline,
}

/// Immutable specification for one scientific model or engine pillar.
class ArchitectureModelSpec {
  const ArchitectureModelSpec({
    required this.id,
    required this.title,
    required this.shortLabel,
    required this.subtitle,
    required this.category,
    required this.badge,
    required this.accentColor,
    required this.icon,
    required this.formula,
    required this.variables,
    required this.reference,
    required this.engineFiles,
    required this.metrics,
    required this.summary,
  });

  final ArchitectureModelId id;
  final String title;
  final String shortLabel;
  final String subtitle;
  final ArchitectureShowcaseCategory category;
  final String badge;
  final Color accentColor;
  final IconData icon;
  final String formula;
  final List<({String symbol, String description})> variables;
  final String reference;
  final List<String> engineFiles;
  final List<({String label, String value})> metrics;
  final String summary;
}

/// Stage descriptor for the procedural Blender 5.3 `.glb` asset pipeline.
class BlenderPipelineStage {
  const BlenderPipelineStage({
    required this.stepNumber,
    required this.title,
    required this.scriptName,
    required this.outputArtifact,
    required this.details,
    required this.budgetLabel,
  });

  final int stepNumber;
  final String title;
  final String scriptName;
  final String outputArtifact;
  final String details;
  final String budgetLabel;
}

/// Credit or acknowledgement entry.
class ShowcaseCreditEntry {
  const ShowcaseCreditEntry({
    required this.title,
    required this.role,
    required this.category,
    required this.description,
    required this.badge,
    required this.accentColor,
    required this.icon,
  });

  final String title;
  final String role;
  final String category;
  final String description;
  final String badge;
  final Color accentColor;
  final IconData icon;
}

/// Result of Martin's cycling power equation breakdown.
class MartinPowerBreakdown {
  const MartinPowerBreakdown({
    required this.aeroWatts,
    required this.gravityWatts,
    required this.rollingWatts,
    required this.drivetrainLossWatts,
    required this.totalWatts,
    required this.wattsPerKg,
  });

  final double aeroWatts;
  final double gravityWatts;
  final double rollingWatts;
  final double drivetrainLossWatts;
  final double totalWatts;
  final double wattsPerKg;
}

/// Result of Skiba W'bal simulation step.
class SkibaWPrimeResult {
  const SkibaWPrimeResult({
    required this.remainingJoules,
    required this.remainingPercent,
    required this.tauSeconds,
    required this.isDepleting,
  });

  final double remainingJoules;
  final double remainingPercent;
  final double tauSeconds;
  final bool isDepleting;
}

/// Pure mathematical helpers powering the live interactive engine showcase.
class ArchitectureShowcaseCalculator {
  ArchitectureShowcaseCalculator._();

  static const double gravity = 9.80665;
  static const double defaultAirDensity = 1.225;

  /// Computes Skiba $W'_{bal}$ remaining anaerobic work capacity after [durationSeconds]
  /// starting from full [wPrimeJoules] at constant [powerWatts] and [criticalPowerWatts].
  static SkibaWPrimeResult computeSkibaWPrime({
    required double wPrimeJoules,
    required double criticalPowerWatts,
    required double powerWatts,
    required double durationSeconds,
    double initialFraction = 0.75,
  }) {
    final safeWPrime = math.max(1000.0, wPrimeJoules);
    final safeDuration = math.max(0.0, durationSeconds);
    final startW = safeWPrime * initialFraction.clamp(0.0, 1.0);

    if (powerWatts > criticalPowerWatts) {
      final deltaP = powerWatts - criticalPowerWatts;
      final remaining = (startW - deltaP * safeDuration).clamp(0.0, safeWPrime);
      return SkibaWPrimeResult(
        remainingJoules: remaining,
        remainingPercent: (remaining / safeWPrime) * 100.0,
        tauSeconds: 0.0,
        isDepleting: true,
      );
    }

    final dCp = (criticalPowerWatts - powerWatts).clamp(0.0, 500.0);
    final tau = 546.0 * math.exp(-0.01 * dCp) + 316.0;
    final recovered = safeWPrime -
        (safeWPrime - startW) * math.exp(-safeDuration / tau);
    final clamped = recovered.clamp(0.0, safeWPrime);
    return SkibaWPrimeResult(
      remainingJoules: clamped,
      remainingPercent: (clamped / safeWPrime) * 100.0,
      tauSeconds: tau,
      isDepleting: false,
    );
  }

  /// Computes Martin et al. (1998) cycling power components in Watts.
  static MartinPowerBreakdown computeMartinPower({
    required double riderMassKg,
    double bikeMassKg = 6.8,
    required double velocityKmh,
    required double gradePercent,
    double cda = 0.245,
    double crr = 0.0032,
    double headwindKmh = 0.0,
    double airDensity = defaultAirDensity,
    double drivetrainEfficiency = 0.976,
  }) {
    final totalMass = math.max(40.0, riderMassKg + bikeMassKg);
    final v = math.max(0.1, velocityKmh / 3.6);
    final vAir = math.max(0.0, v + (headwindKmh / 3.6));
    final gradeRad = math.atan(gradePercent / 100.0);

    final aero = 0.5 * airDensity * cda * vAir * vAir * v;
    final grav = totalMass * gravity * math.sin(gradeRad) * v;
    final roll = totalMass * gravity * math.cos(gradeRad) * crr * v;

    final wheelPower = math.max(0.0, aero + grav + roll);
    final total = wheelPower / drivetrainEfficiency.clamp(0.85, 1.0);
    final loss = math.max(0.0, total - wheelPower);

    return MartinPowerBreakdown(
      aeroWatts: aero,
      gravityWatts: grav,
      rollingWatts: roll,
      drivetrainLossWatts: loss,
      totalWatts: total,
      wattsPerKg: total / math.max(40.0, riderMassKg),
    );
  }

  /// Computes Boids anisotropic separation force magnitude (0..1+) for two riders.
  static double computeBoidsSeparationMagnitude({
    required double dxLongitudinalMeters,
    required double dyLateralMeters,
    double minLongitudinalMeters = 1.85,
    double minLateralMeters = 0.65,
  }) {
    final normX = dxLongitudinalMeters / math.max(0.1, minLongitudinalMeters);
    final normY = dyLateralMeters / math.max(0.1, minLateralMeters);
    final ellipDist = math.sqrt(normX * normX + normY * normY);
    if (ellipDist >= 1.0) return 0.0;
    return (1.0 - ellipDist).clamp(0.0, 1.0);
  }
}

/// Static catalog of scientific models, Blender pipeline stages, and credits.
class ArchitectureShowcaseCatalog {
  ArchitectureShowcaseCatalog._();

  static const List<ArchitectureModelSpec> models = [
    ArchitectureModelSpec(
      id: ArchitectureModelId.skibaWPrime,
      title: 'Model Skiby W\' (W\'bal)',
      shortLabel: 'Skiba W\'',
      subtitle: 'Beztlenowa pojemność pracy i wykładnicza regeneracja',
      category: ArchitectureShowcaseCategory.scientificModels,
      badge: 'FIZJOLOGIA',
      accentColor: AppColors.crimsonAlert,
      icon: Icons.bolt_rounded,
      formula: 'W\'_bal(t) = W\' - ∫ (P - CP) dt   |   τ = 546·e^(-0.01·ΔCP) + 316',
      variables: [
        (symbol: 'W\'', description: 'Pojemność beztlenowa powyżej CP (np. 18–28 kJ)'),
        (symbol: 'CP / FTP', description: 'Moc krytyczna rozgraniczająca strefę tlenową i beztlenową'),
        (symbol: 'τ_W\'', description: 'Stała czasowa regeneracji (zależy od zapasu ΔCP = CP - P)'),
      ],
      reference: 'Skiba P.F. et al. (2012, 2015) — Medicine & Science in Sports & Exercise',
      engineFiles: [
        'lib/engine/physics/w_prime_balance_engine.dart',
        'lib/engine/physics/heart_rate_simulator.dart',
        'lib/engine/physics/nutrition_and_glycogen_engine.dart',
      ],
      metrics: [
        (label: 'Częstotliwość', value: '60 Hz Isolate'),
        (label: 'Zakres τ', value: '316 – 862 s'),
        (label: 'Walidacja', value: 'Alpe d\'Huez & ITT'),
      ],
      summary:
          'Każdy atak powyżej mocy krytycznej drenuje baterię W\' w dżulach. Gdy kolarz wraca do peletonu poniżej CP, W\' odbudowuje się wykładniczo według równania Skiby — z wolniejszą regeneracją przy jeździe tuż pod progiem.',
    ),
    ArchitectureModelSpec(
      id: ArchitectureModelId.martinCyclingPower,
      title: 'Równania Martina dla Mocy Kolarskiej',
      shortLabel: 'Martin Power',
      subtitle: 'Pełny bilans sił aerodynamicznych, grawitacji i toczenia',
      category: ArchitectureShowcaseCategory.scientificModels,
      badge: 'FIZYKA 60HZ',
      accentColor: AppColors.accentBlue,
      icon: Icons.speed_rounded,
      formula: 'P = [½·ρ·CdA·v_air²·v + m·g·sin(θ)·v + m·g·cos(θ)·Crr·v] / η',
      variables: [
        (symbol: 'CdA', description: 'Powierzchnia czołowa × współczynnik oporu (0.19–0.34 m²)'),
        (symbol: 'Crr', description: 'Opór toczenia opon i nawierzchni (asfalt 0.003 vs bruk 0.009)'),
        (symbol: 'ρ (rho)', description: 'Gęstość powietrza zależna od wysokości n.p.m. i temperatury'),
      ],
      reference: 'Martin J.C. et al. (1998) — Validation of a Mathematical Model for Road Cycling Power',
      engineFiles: [
        'lib/engine/physics/speed_solver.dart',
        'lib/engine/physics/aero_calculator.dart',
        'lib/engine/physics/gravity_and_rolling_calculator.dart',
      ],
      metrics: [
        (label: 'Sprawność η', value: '97.6% (wosk +0.8%)'),
        (label: 'Drafting', value: '−35% do −48% CdA'),
        (label: 'Dokładność', value: 'VAM ±1.2%'),
      ],
      summary:
          'Solver prędkości rozwiązuje równanie kubiczne Martina dla każdego ze 176 kolarzy w każdej sekundzie etapu, uwzględniając wysokość n.p.m., wiatr boczny, ciśnienie opon i redukcję CdA w peletonie.',
    ),
    ArchitectureModelSpec(
      id: ArchitectureModelId.boidsFlocking,
      title: 'Algorytm Boids & Spatial Hash',
      shortLabel: 'Boids 176',
      subtitle: 'Ruch bezkolizyjny peletonu 176 kolarzy w czasie O(N)',
      category: ArchitectureShowcaseCategory.boidsSimulation,
      badge: 'AI & RUCH',
      accentColor: AppColors.statusSuccess,
      icon: Icons.hub_rounded,
      formula: 'F_steer = w_sep·F_sep(1.85×0.65m) + w_align·F_align + w_draft·F_draft',
      variables: [
        (symbol: 'F_sep', description: 'Anizotropowe odpychanie chroniące przed nakładaniem się rowerów'),
        (symbol: 'F_draft', description: 'Szukanie cienia aerodynamicznego i formowanie wachlarzy na wietrze'),
        (symbol: 'Hash 5m', description: 'Siatka przestrzenna Zero-GC redukująca złożoność z O(N²) do O(N)'),
      ],
      reference: 'Reynolds C.W. (1987) — Flocks, Herds, and Schools: A Distributed Behavioral Model',
      engineFiles: [
        'lib/engine/peloton/boids_steering_collision_avoidance.dart',
        'lib/engine/rendering3d/boids_peloton_flocking_solver.dart',
        'lib/engine/rendering3d/spatial_hash_grid_1d_2d.dart',
      ],
      metrics: [
        (label: 'Agenci 3D', value: '176 kolarzy'),
        (label: 'Czas klatki', value: '< 0.4 ms'),
        (label: 'Alokacje GC', value: '0 B / klatka'),
      ],
      summary:
          'Zamiast sztywnych torów jazdy, każdy kolarz jest autonomicznym agentem Boids z eliptyczną strefą bezpieczeństwa 1.85 × 0.65 m, pasem wyprzedzania przy Δv > 0.8 m/s oraz naturalnym efektem akordeonu w zakrętach.',
    ),
    ArchitectureModelSpec(
      id: ArchitectureModelId.blenderGlbPipeline,
      title: 'Proceduralny Pipeline Blender .glb',
      shortLabel: 'Blender .glb',
      subtitle: 'Automatyczna fabryka siatek 3D, rigów IK i tekstur PBR',
      category: ArchitectureShowcaseCategory.blenderPipeline,
      badge: 'GRAFIKA 3D',
      accentColor: AppColors.goldAccent,
      icon: Icons.view_in_ar_rounded,
      formula: 'Python bpy (Blender 5.3) → Rig & Bake → glTF 2.0 (.glb) → RamValidator',
      variables: [
        (symbol: 'bpy', description: 'Skrypty proceduralne generujące ramy aero, kaski, podium i auta'),
        (symbol: 'LOD 0–2', description: 'Wielo-poziomowa redukcja trójkątów dla płynnych 120 FPS'),
        (symbol: 'Fallback', description: 'GlbMeshIntegrityValidator generuje siatki w RAM w razie braku pliku'),
      ],
      reference: 'Blender 5.3 Python API + Khronos glTF 2.0 Specification',
      engineFiles: [
        'blender_scripts/build_all_assets_master.py',
        'blender_scripts/rig_and_animate_cyclist.py',
        'lib/engine/rendering3d/glb_mesh_integrity_validator.dart',
      ],
      metrics: [
        (label: 'Blender', value: 'v5.3.0 CLI'),
        (label: 'Budżet LOD', value: '120 FPS Pool'),
        (label: 'Tekstury', value: 'PBR Atlas RAM'),
      ],
      summary:
          'Cała geometria 3D — od sylwetki kolarza z kinematyką odwrotną IK po tunele aerodynamiczne, rampy TT, śmigłowce TV i trofea — powstaje deterministycznie w skryptach Pythona i trafia do paczek .glb.',
    ),
  ];

  static const List<BlenderPipelineStage> pipelineStages = [
    BlenderPipelineStage(
      stepNumber: 1,
      title: 'Parametryczna Geometria bpy',
      scriptName: 'blender_scripts/generate_*.py',
      outputArtifact: 'Siatki bazowe ram, kół, aut i bram',
      details:
          'Skrypty Pythona budują profile rur aero Kamm-tail, koła stożkowe 50/80 mm, barierki, rampy startowe ITT oraz architekturę tunelu aerodynamicznego.',
      budgetLabel: 'Deterministyczny seed',
    ),
    BlenderPipelineStage(
      stepNumber: 2,
      title: 'Rigging i Animacja Kolarza',
      scriptName: 'blender_scripts/rig_and_animate_cyclist.py',
      outputArtifact: 'Armatura szkieletu + 6 póz wyścigowych',
      details:
          'Dwustawowy układ nóg i rąk przygotowany pod solver IK (Tops, Hoods, Drops, AeroTuck, En Danseuse oraz 6 animacji finiszu).',
      budgetLabel: '60–120 Hz IK',
    ),
    BlenderPipelineStage(
      stepNumber: 3,
      title: 'Materiały PBR & Wypalanie Koszulek',
      scriptName: 'blender_scripts/generate_jersey_textures_baker.py',
      outputArtifact: 'Atlasy 1024×1024 PNG + splot karbonu 3K',
      details:
          'Proceduralne tekstury koszulek liderów (Żółta, Zielona, Grochy, Biała, Tęczowa) i 8 szablonów drużynowych bez zewnętrznych zależności graficznych.',
      budgetLabel: 'Zero-I/O Atlas',
    ),
    BlenderPipelineStage(
      stepNumber: 4,
      title: 'Eksport glTF 2.0 (.glb) & Manifest',
      scriptName: 'blender_scripts/build_all_assets_master.py',
      outputArtifact: 'assets/3d/**/*.glb + asset_manifest.json',
      details:
          'Izolowana kompilacja wsadowa z obsługą błędów try/except oraz rejestracją sum kontrolnych i metadanych w manifeście.',
      budgetLabel: 'Batch Windows CLI',
    ),
    BlenderPipelineStage(
      stepNumber: 5,
      title: 'Walidacja Startowa & Pula Zero-GC',
      scriptName: 'lib/engine/rendering3d/glb_mesh_integrity_validator.dart',
      outputArtifact: 'Float64List RenderObjectPoolManager',
      details:
          'Weryfikacja integralności plików .glb przy starcie z automatycznym fallbackiem siatek w RAM oraz prealokacją buforów dla 176 kolarzy.',
      budgetLabel: '0 B GC / klatka',
    ),
  ];

  static const List<ShowcaseCreditEntry> credits = [
    ShowcaseCreditEntry(
      title: 'Dr Philip Skiba & Prof. James C. Martin',
      role: 'Podstawy Fizjologii & Fizyki Kolarstwa',
      category: 'Nauka',
      description:
          'Badania nad modelem W\'_bal oraz równaniami mocy kolarskiej stanowią fundament symulacji wydolnościowej i prędkości w Pro Peloton Manager.',
      badge: 'BADANIA NAUKOWE',
      accentColor: AppColors.crimsonAlert,
      icon: Icons.science_rounded,
    ),
    ShowcaseCreditEntry(
      title: 'Craig Reynolds & Dr Andrew Coggan',
      role: 'Algorytm Boids & Strefy Mocy Z1–Z7',
      category: 'Nauka',
      description:
          'Koncepcja rozproszonego ruchu stadnego Boids (1987) oraz klasyfikacja stref treningowych i wskaźników TSS/CTL/ATL/TSB.',
      badge: 'METODOLOGIA',
      accentColor: AppColors.statusSuccess,
      icon: Icons.analytics_rounded,
    ),
    ShowcaseCreditEntry(
      title: 'Flutter, Dart Isolates & Riverpod',
      role: 'Rdzeń Aplikacji & Wielowątkowość 60 Hz',
      category: 'Technologia',
      description:
          'Architektura reaktywna oparta na StateNotifier/Provider, bezpiecznym routingu GoRouter oraz odseparowanym wątku fizyki IsolateSimulationWorker.',
      badge: 'FRAMEWORK',
      accentColor: AppColors.accentBlue,
      icon: Icons.memory_rounded,
    ),
    ShowcaseCreditEntry(
      title: 'Blender Foundation & Khronos glTF 2.0',
      role: 'Proceduralny Pipeline 3D .glb',
      category: 'Technologia',
      description:
          'Narzędzia Python bpy w Blender 5.3 oraz otwarty standard transmisji scen 3D glTF/GLB używane do generowania modeli peletonu i obiektów tras.',
      badge: 'PIPELINE 3D',
      accentColor: AppColors.goldAccent,
      icon: Icons.view_in_ar_rounded,
    ),
    ShowcaseCreditEntry(
      title: 'fl_chart, vector_math_64 & Isar',
      role: 'Wizualizacja Telemetrii & Persystencja',
      category: 'Open Source',
      description:
          'Wykresy krzywych mocy, macierze rzutowania 3D→2D w podwójnej precyzji oraz transakcyjny zapis karier z sumą kontrolną FNV-1a64 + CRC32.',
      badge: 'OPEN SOURCE',
      accentColor: AppColors.cyanAccent,
      icon: Icons.code_rounded,
    ),
    ShowcaseCreditEntry(
      title: 'Społeczność Kolarska & Twórcy Modów',
      role: 'Testerzy Realizmu WorldTour & Scenariusze',
      category: 'Społeczność',
      description:
          'Podziękowania dla pasjonatów taktyki kolarskiej, kalibracji czasów na Alpe d\'Huez oraz twórców własnych etapów w formacie .ppmstage.',
      badge: 'SPOŁECZNOŚĆ',
      accentColor: AppColors.primaryAccent,
      icon: Icons.favorite_rounded,
    ),
  ];
}

/// Production screen showcasing scientific models, 3D pipeline, architecture, and credits.
class CreditsAndArchitectureShowcaseScreen extends StatefulWidget {
  const CreditsAndArchitectureShowcaseScreen({
    super.key,
    this.onBack,
    this.appVersion = 'v2.4.0 • Build 301',
    this.initialCategory = ArchitectureShowcaseCategory.all,
    this.initialModel = ArchitectureModelId.skibaWPrime,
  });

  final VoidCallback? onBack;
  final String appVersion;
  final ArchitectureShowcaseCategory initialCategory;
  final ArchitectureModelId initialModel;

  @override
  State<CreditsAndArchitectureShowcaseScreen> createState() =>
      _CreditsAndArchitectureShowcaseScreenState();
}

class _CreditsAndArchitectureShowcaseScreenState
    extends State<CreditsAndArchitectureShowcaseScreen> {
  late ArchitectureShowcaseCategory _selectedCategory;
  late ArchitectureModelId _selectedModel;
  int _selectedPipelineStageIndex = 0;
  bool _compactEquationsMode = false;
  bool _specCopied = false;

  // Live Skiba W' sandbox state
  double _skibaPowerWatts = 440.0;
  double _skibaDurationSec = 35.0;
  static const double _skibaCpWatts = 380.0;
  static const double _skibaWPrimeJoules = 22000.0;

  // Live Martin cycling power sandbox state
  double _martinVelocityKmh = 42.0;
  double _martinGradePercent = 4.5;
  static const double _martinMassKg = 68.0;

  // Live Boids sandbox state
  double _boidsLateralGapMeters = 0.45;
  double _boidsLongitudinalGapMeters = 1.20;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedModel = widget.initialModel;
  }

  List<ArchitectureModelSpec> get _filteredModels {
    if (_selectedCategory == ArchitectureShowcaseCategory.all ||
        _selectedCategory == ArchitectureShowcaseCategory.credits) {
      return ArchitectureShowcaseCatalog.models;
    }
    return ArchitectureShowcaseCatalog.models
        .where((m) => m.category == _selectedCategory)
        .toList(growable: false);
  }

  ArchitectureModelSpec get _activeModelSpec {
    return ArchitectureShowcaseCatalog.models.firstWhere(
      (m) => m.id == _selectedModel,
      orElse: () => ArchitectureShowcaseCatalog.models.first,
    );
  }

  Future<void> _copyActiveSpecToClipboard() async {
    final spec = _activeModelSpec;
    final buffer = StringBuffer()
      ..writeln('${spec.title} [${spec.badge}]')
      ..writeln('Wzór: ${spec.formula}')
      ..writeln('Źródło: ${spec.reference}')
      ..writeln('Pliki silnika: ${spec.engineFiles.join(', ')}');

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    setState(() => _specCopied = true);
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _specCopied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeSpec = _activeModelSpec;
    final showModelsSection =
        _selectedCategory != ArchitectureShowcaseCategory.credits;
    final showPipelineSection =
        _selectedCategory == ArchitectureShowcaseCategory.all ||
            _selectedCategory == ArchitectureShowcaseCategory.blenderPipeline;
    final showCreditsSection =
        _selectedCategory == ArchitectureShowcaseCategory.all ||
            _selectedCategory == ArchitectureShowcaseCategory.credits;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 720;
            final isDesktop = width >= 1200;
            final horizontalPadding = isMobile ? 16.0 : (isDesktop ? 28.0 : 22.0);

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isMobile ? 14.0 : 20.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context, isMobile: isMobile),
                      const SizedBox(height: 16),
                      _buildKpiTelemetryStrip(isMobile: isMobile),
                      const SizedBox(height: 16),
                      _buildFilterAndControlsBar(isMobile: isMobile),
                      const SizedBox(height: 18),
                      if (showModelsSection) ...[
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _buildModelsGrid(
                                  crossAxisCount: 2,
                                  models: _filteredModels,
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                flex: 6,
                                child: _buildActiveModelInspector(
                                  activeSpec,
                                  isMobile: false,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _buildModelsGrid(
                            crossAxisCount: isMobile ? 1 : 2,
                            models: _filteredModels,
                          ),
                          const SizedBox(height: 18),
                          _buildActiveModelInspector(
                            activeSpec,
                            isMobile: isMobile,
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                      if (showPipelineSection) ...[
                        _buildBlenderPipelineSection(
                          isMobile: isMobile,
                          isDesktop: isDesktop,
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (showCreditsSection) ...[
                        _buildCreditsSection(
                          isMobile: isMobile,
                          isDesktop: isDesktop,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isMobile}) {
    final canPop = widget.onBack != null || Navigator.of(context).canPop();

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceLight.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InteractiveActionChip(
                icon: Icons.arrow_back_rounded,
                label: isMobile ? '' : 'Powrót',
                tooltip: 'Powrót do poprzedniego ekranu',
                enabled: canPop,
                onTap: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const _BadgePill(
                          label: 'ARCHITEKTURA SILNIKA',
                          color: AppColors.goldAccent,
                        ),
                        _BadgePill(
                          label: widget.appVersion,
                          color: AppColors.accentBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Silnik Naukowy, Pipeline 3D & Podziękowania',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.4,
                        fontSize: isMobile ? 20 : 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Przegląd modeli fizjologii i fizyki kolarskiej (Skiba W\', równania Martina), '
                      'symulacji Boids dla 176 kolarzy oraz proceduralnego pipeline\'u Blender .glb.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.2,
                        fontSize: isMobile ? 13 : 14,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiTelemetryStrip({required bool isMobile}) {
    const items = [
      (
        label: 'MODELE NAUKOWE',
        value: '4 Rdzenie',
        sub: 'Skiba • Martin • Boids • glTF',
        color: AppColors.crimsonAlert,
      ),
      (
        label: 'PĘTLA FIZYKI',
        value: '60 Hz Isolate',
        sub: 'Deterministyczny PRNG',
        color: AppColors.accentBlue,
      ),
      (
        label: 'PELETON 3D',
        value: '176 Agentów',
        sub: 'Spatial Hash < 0.4 ms',
        color: AppColors.statusSuccess,
      ),
      (
        label: 'RENDERER CANVAS',
        value: '120 FPS Zero-GC',
        sub: 'Prealokacja Float64List',
        color: AppColors.goldAccent,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = isMobile ? 2 : 4;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
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
                    const SizedBox(height: 4),
                    Text(
                      item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.2,
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w800,
                        color: item.color,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.sub,
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
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFilterAndControlsBar({required bool isMobile}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ArchitectureShowcaseCategory.values.map((category) {
              final selected = _selectedCategory == category;
              return _InteractiveActionChip(
                icon: category.icon,
                label: category.label,
                selected: selected,
                accentColor: AppColors.goldAccent,
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                    final visible = _filteredModels;
                    if (visible.isNotEmpty &&
                        !visible.any((m) => m.id == _selectedModel)) {
                      _selectedModel = visible.first.id;
                    }
                  });
                },
              );
            }).toList(),
          ),
          _InteractiveActionChip(
            icon: _compactEquationsMode
                ? Icons.visibility_off_rounded
                : Icons.functions_rounded,
            label: _compactEquationsMode
                ? 'Pokaż równania'
                : 'Tryb kompaktowy',
            selected: _compactEquationsMode,
            accentColor: AppColors.accentBlue,
            onTap: () {
              setState(() {
                _compactEquationsMode = !_compactEquationsMode;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModelsGrid({
    required int crossAxisCount,
    required List<ArchitectureModelSpec> models,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: models.map((spec) {
            final isSelected = spec.id == _selectedModel;
            return SizedBox(
              width: cardWidth,
              child: _InteractiveModelCard(
                spec: spec,
                selected: isSelected,
                compactMode: _compactEquationsMode,
                onTap: () => setState(() => _selectedModel = spec.id),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActiveModelInspector(
    ArchitectureModelSpec spec, {
    required bool isMobile,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: Container(
        key: ValueKey<ArchitectureModelId>(spec.id),
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: spec.accentColor.withValues(alpha: 0.55),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: spec.accentColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: spec.accentColor.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Icon(spec.icon, color: spec.accentColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BadgePill(label: spec.badge, color: spec.accentColor),
                          const SizedBox(height: 4),
                          Text(
                            spec.title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              letterSpacing: -0.3,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _InteractiveActionChip(
                  icon: _specCopied
                      ? Icons.check_rounded
                      : Icons.content_copy_rounded,
                  label: _specCopied ? 'Skopiowano' : 'Kopiuj specyfikację',
                  selected: _specCopied,
                  accentColor: AppColors.statusSuccess,
                  onTap: _copyActiveSpecToClipboard,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              spec.summary,
              style: const TextStyle(
                fontFamily: 'Inter',
                letterSpacing: -0.2,
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            if (!_compactEquationsMode) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FORMUŁA MATEMATYCZNA / ARCHITEKTURA',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      spec.formula,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: spec.accentColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...spec.variables.map(
                      (v) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                v.symbol,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                v.description,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            _buildInteractiveModelSandbox(spec.id),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: spec.engineFiles.map((filePath) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.insert_drive_file_outlined,
                        size: 13,
                        color: AppColors.goldAccent,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          filePath,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              'Źródło: ${spec.reference}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveModelSandbox(ArchitectureModelId modelId) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: switch (modelId) {
        ArchitectureModelId.skibaWPrime => _buildSkibaSandbox(),
        ArchitectureModelId.martinCyclingPower => _buildMartinSandbox(),
        ArchitectureModelId.boidsFlocking => _buildBoidsSandbox(),
        ArchitectureModelId.blenderGlbPipeline => _buildBlenderQuickPreview(),
      },
    );
  }

  Widget _buildSkibaSandbox() {
    final result = ArchitectureShowcaseCalculator.computeSkibaWPrime(
      wPrimeJoules: _skibaWPrimeJoules,
      criticalPowerWatts: _skibaCpWatts,
      powerWatts: _skibaPowerWatts,
      durationSeconds: _skibaDurationSec,
    );

    final statusColor =
        result.isDepleting ? AppColors.crimsonAlert : AppColors.statusSuccess;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'SYMULATOR NA ŻYWO: SKIBA W\'_bal (CP = 380 W, W\' = 22.0 kJ)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                ),
              ),
            ),
            _BadgePill(
              label: result.isDepleting ? 'DRENAŻ W\'' : 'REGENERACJA',
              color: statusColor,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LabeledSliderRow(
          label: 'Moc chwilowa P',
          valueLabel: '${_skibaPowerWatts.round()} W',
          value: _skibaPowerWatts,
          min: 180,
          max: 650,
          activeColor: statusColor,
          onChanged: (v) => setState(() => _skibaPowerWatts = v),
        ),
        _LabeledSliderRow(
          label: 'Czas wysiłku Δt',
          valueLabel: '${_skibaDurationSec.round()} s',
          value: _skibaDurationSec,
          min: 5,
          max: 120,
          activeColor: AppColors.accentBlue,
          onChanged: (v) => setState(() => _skibaDurationSec = v),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (result.remainingPercent / 100.0).clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _MetricInline(
              label: 'Pozostałe W\'_bal',
              value:
                  '${(result.remainingJoules / 1000.0).toStringAsFixed(1)} kJ (${result.remainingPercent.toStringAsFixed(0)}%)',
              color: statusColor,
            ),
            if (!result.isDepleting)
              _MetricInline(
                label: 'Stała τ_W\'',
                value: '${result.tauSeconds.round()} s',
                color: AppColors.accentBlue,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMartinSandbox() {
    final breakdown = ArchitectureShowcaseCalculator.computeMartinPower(
      riderMassKg: _martinMassKg,
      velocityKmh: _martinVelocityKmh,
      gradePercent: _martinGradePercent,
    );

    final denom = math.max(1.0, breakdown.totalWatts);
    final aeroShare = (breakdown.aeroWatts / denom).clamp(0.0, 1.0);
    final gravShare =
        (math.max(0.0, breakdown.gravityWatts) / denom).clamp(0.0, 1.0);
    final rollShare = (breakdown.rollingWatts / denom).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'KALKULATOR MARTINA (68 kg + 6.8 kg, CdA 0.245)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentBlue,
                ),
              ),
            ),
            Text(
              '${breakdown.totalWatts.round()} W • ${breakdown.wattsPerKg.toStringAsFixed(2)} W/kg',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.goldAccent,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LabeledSliderRow(
          label: 'Prędkość v',
          valueLabel: '${_martinVelocityKmh.toStringAsFixed(1)} km/h',
          value: _martinVelocityKmh,
          min: 14,
          max: 65,
          activeColor: AppColors.accentBlue,
          onChanged: (v) => setState(() => _martinVelocityKmh = v),
        ),
        _LabeledSliderRow(
          label: 'Nachylenie θ',
          valueLabel: '${_martinGradePercent.toStringAsFixed(1)}%',
          value: _martinGradePercent,
          min: -4,
          max: 14,
          activeColor: AppColors.amberWarning,
          onChanged: (v) => setState(() => _martinGradePercent = v),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                if (aeroShare > 0.01)
                  Expanded(
                    flex: math.max(1, (aeroShare * 100).round()),
                    child: Container(color: AppColors.accentBlue),
                  ),
                if (gravShare > 0.01)
                  Expanded(
                    flex: math.max(1, (gravShare * 100).round()),
                    child: Container(color: AppColors.crimsonAlert),
                  ),
                if (rollShare > 0.01)
                  Expanded(
                    flex: math.max(1, (rollShare * 100).round()),
                    child: Container(color: AppColors.statusSuccess),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _MetricInline(
              label: 'Aero',
              value: '${breakdown.aeroWatts.round()} W',
              color: AppColors.accentBlue,
            ),
            _MetricInline(
              label: 'Grawitacja',
              value: '${breakdown.gravityWatts.round()} W',
              color: AppColors.crimsonAlert,
            ),
            _MetricInline(
              label: 'Toczenie',
              value: '${breakdown.rollingWatts.round()} W',
              color: AppColors.statusSuccess,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBoidsSandbox() {
    final repulsion =
        ArchitectureShowcaseCalculator.computeBoidsSeparationMagnitude(
      dxLongitudinalMeters: _boidsLongitudinalGapMeters,
      dyLateralMeters: _boidsLateralGapMeters,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'POLE SEPARACJI BOIDS (1.85 m × 0.65 m)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.statusSuccess,
                ),
              ),
            ),
            _BadgePill(
              label: repulsion > 0
                  ? 'UNIK ${(repulsion * 100).round()}%'
                  : 'CZYSTY DRAFT',
              color: repulsion > 0
                  ? AppColors.amberWarning
                  : AppColors.statusSuccess,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LabeledSliderRow(
          label: 'Odstęp boczny Δy',
          valueLabel: '${_boidsLateralGapMeters.toStringAsFixed(2)} m',
          value: _boidsLateralGapMeters,
          min: 0.10,
          max: 1.20,
          activeColor: AppColors.statusSuccess,
          onChanged: (v) => setState(() => _boidsLateralGapMeters = v),
        ),
        _LabeledSliderRow(
          label: 'Odstęp wzdłużny Δx',
          valueLabel: '${_boidsLongitudinalGapMeters.toStringAsFixed(2)} m',
          value: _boidsLongitudinalGapMeters,
          min: 0.40,
          max: 2.50,
          activeColor: AppColors.cyanAccent,
          onChanged: (v) => setState(() => _boidsLongitudinalGapMeters = v),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 84,
          width: double.infinity,
          child: CustomPaint(
            painter: _BoidsSeparationPreviewPainter(
              dxMeters: _boidsLongitudinalGapMeters,
              dyMeters: _boidsLateralGapMeters,
              repulsionStrength: repulsion,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlenderQuickPreview() {
    final stage =
        ArchitectureShowcaseCatalog.pipelineStages[_selectedPipelineStageIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'AKTYWNY ETAP PIPELINE\'U BLENDER .GLB',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                ),
              ),
            ),
            _BadgePill(label: stage.budgetLabel, color: AppColors.goldAccent),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${stage.stepNumber}. ${stage.title}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${stage.scriptName} → ${stage.outputArtifact}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.accentBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stage.details,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBlenderPipelineSection({
    required bool isMobile,
    required bool isDesktop,
  }) {
    const stages = ArchitectureShowcaseCatalog.pipelineStages;
    final activeStage = stages[_selectedPipelineStageIndex];

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_tree_rounded,
                    color: AppColors.goldAccent,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Proceduralny Pipeline Blender 5.3 → .glb',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.3,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              _BadgePill(
                label: '5 ETAPÓW • ZERO RĘCZNEGO MODELOWANIA',
                color: AppColors.goldAccent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(stages.length, (index) {
              final stage = stages[index];
              final isSelected = index == _selectedPipelineStageIndex;
              return _InteractiveActionChip(
                icon: Icons.layers_rounded,
                label: '${stage.stepNumber}. ${stage.title}',
                selected: isSelected,
                accentColor: AppColors.goldAccent,
                onTap: () =>
                    setState(() => _selectedPipelineStageIndex = index),
              );
            }),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.4),
              ),
            ),
            child: isDesktop
                ? Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildPipelineDetailColumn(activeStage),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _buildPipelineArtifactBox(activeStage),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPipelineDetailColumn(activeStage),
                      const SizedBox(height: 12),
                      _buildPipelineArtifactBox(activeStage),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineDetailColumn(BlenderPipelineStage stage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Etap ${stage.stepNumber}: ${stage.title}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          stage.details,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPipelineArtifactBox(BlenderPipelineStage stage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricInline(
            label: 'Skrypt / Moduł',
            value: stage.scriptName,
            color: AppColors.accentBlue,
          ),
          const SizedBox(height: 6),
          _MetricInline(
            label: 'Artefakt',
            value: stage.outputArtifact,
            color: AppColors.goldAccent,
          ),
          const SizedBox(height: 6),
          _MetricInline(
            label: 'Budżet',
            value: stage.budgetLabel,
            color: AppColors.statusSuccess,
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsSection({
    required bool isMobile,
    required bool isDesktop,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.primaryAccent,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Podziękowania, Inspiracje Naukowe & Stack Technologiczny',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.3,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = isMobile ? 1 : (isDesktop ? 3 : 2);
              const spacing = 12.0;
              final itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: ArchitectureShowcaseCatalog.credits.map((entry) {
                  return SizedBox(
                    width: itemWidth,
                    child: Container(
                      padding: const EdgeInsets.all(14),
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
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      entry.accentColor.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  entry.icon,
                                  color: entry.accentColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _BadgePill(
                                  label: entry.badge,
                                  color: entry.accentColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            entry.title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.role,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: entry.accentColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.description,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InteractiveModelCard extends StatefulWidget {
  const _InteractiveModelCard({
    required this.spec,
    required this.selected,
    required this.compactMode,
    required this.onTap,
  });

  final ArchitectureModelSpec spec;
  final bool selected;
  final bool compactMode;
  final VoidCallback onTap;

  @override
  State<_InteractiveModelCard> createState() => _InteractiveModelCardState();
}

class _InteractiveModelCardState extends State<_InteractiveModelCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final borderColor = widget.selected
        ? spec.accentColor
        : (_focused
            ? AppColors.goldAccent
            : (_hovered
                ? spec.accentColor.withValues(alpha: 0.6)
                : AppTheme.borderColor));

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      actions: <Type, Action<Intent>>{
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
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.surfaceLight
                  : (_hovered ? const Color(0xFF1D212A) : AppColors.surface),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: widget.selected || _focused ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: spec.accentColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(spec.icon, color: spec.accentColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BadgePill(
                        label: spec.badge,
                        color: spec.accentColor,
                      ),
                    ),
                    if (widget.selected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: spec.accentColor,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  spec.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  spec.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (!widget.compactMode) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: spec.metrics.map((m) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Text(
                          '${m.label}: ${m.value}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      );
                    }).toList(),
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

class _InteractiveActionChip extends StatefulWidget {
  const _InteractiveActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.enabled = true,
    this.accentColor = AppColors.goldAccent,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool enabled;
  final Color accentColor;
  final String? tooltip;

  @override
  State<_InteractiveActionChip> createState() => _InteractiveActionChipState();
}

class _InteractiveActionChipState extends State<_InteractiveActionChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = widget.enabled;
    final bgColor = !effectiveEnabled
        ? AppColors.surface.withValues(alpha: 0.45)
        : (widget.selected
            ? widget.accentColor.withValues(alpha: 0.18)
            : (_hovered ? AppColors.surfaceLight : AppColors.background));

    final borderColor = !effectiveEnabled
        ? AppTheme.borderColor.withValues(alpha: 0.45)
        : (widget.selected || _focused
            ? widget.accentColor
            : (_hovered
                ? widget.accentColor.withValues(alpha: 0.55)
                : AppTheme.borderColor));

    final fgColor = !effectiveEnabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : (widget.selected ? widget.accentColor : AppColors.textPrimary);

    final chip = FocusableActionDetector(
      enabled: effectiveEnabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: effectiveEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (effectiveEnabled) widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: effectiveEnabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: effectiveEnabled
            ? (_) => setState(() => _pressed = false)
            : null,
        onTapCancel: effectiveEnabled
            ? () => setState(() => _pressed = false)
            : null,
        onTap: effectiveEnabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.label.isEmpty ? 10 : 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 16, color: fgColor),
                if (widget.label.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      widget.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.2,
                        fontSize: 12.5,
                        fontWeight:
                            widget.selected ? FontWeight.w700 : FontWeight.w600,
                        color: fgColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: chip);
    }
    return chip;
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }
}

class _LabeledSliderRow extends StatelessWidget {
  const _LabeledSliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.activeColor,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              valueLabel,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: activeColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: activeColor,
            inactiveTrackColor: AppColors.background,
            thumbColor: activeColor,
            overlayColor: activeColor.withValues(alpha: 0.15),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _MetricInline extends StatelessWidget {
  const _MetricInline({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoidsSeparationPreviewPainter extends CustomPainter {
  const _BoidsSeparationPreviewPainter({
    required this.dxMeters,
    required this.dyMeters,
    required this.repulsionStrength,
  });

  final double dxMeters;
  final double dyMeters;
  final double repulsionStrength;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      bgPaint,
    );

    final center = Offset(size.width * 0.35, size.height * 0.52);
    const scalePxPerMeter = 28.0;

    // Draw anisotropic 1.85m x 0.65m safety zone ellipse
    final zoneRect = Rect.fromCenter(
      center: center,
      width: 1.85 * scalePxPerMeter * 2,
      height: 0.65 * scalePxPerMeter * 2,
    );
    final zonePaint = Paint()
      ..color = (repulsionStrength > 0
              ? AppColors.amberWarning
              : AppColors.statusSuccess)
          .withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    final zoneBorder = Paint()
      ..color = repulsionStrength > 0
          ? AppColors.amberWarning
          : AppColors.statusSuccess
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawOval(zoneRect, zonePaint);
    canvas.drawOval(zoneRect, zoneBorder);

    // Primary rider dot
    final primaryPaint = Paint()..color = AppColors.goldAccent;
    canvas.drawCircle(center, 6, primaryPaint);

    // Neighbor rider dot
    final neighbor = Offset(
      (center.dx + dxMeters * scalePxPerMeter).clamp(12.0, size.width - 12.0),
      (center.dy - dyMeters * scalePxPerMeter).clamp(12.0, size.height - 12.0),
    );
    final neighborPaint = Paint()
      ..color = repulsionStrength > 0
          ? AppColors.crimsonAlert
          : AppColors.accentBlue;
    canvas.drawCircle(neighbor, 5.5, neighborPaint);

    // Repulsion vector line if inside safety ellipse
    if (repulsionStrength > 0) {
      final linePaint = Paint()
        ..color = AppColors.amberWarning
        ..strokeWidth = 1.5;
      canvas.drawLine(center, neighbor, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoidsSeparationPreviewPainter oldDelegate) {
    return oldDelegate.dxMeters != dxMeters ||
        oldDelegate.dyMeters != dyMeters ||
        oldDelegate.repulsionStrength != repulsionStrength;
  }
}
