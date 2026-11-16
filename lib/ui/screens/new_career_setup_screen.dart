import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/career/career_save.dart';
import '../../models/equipment/frame_model.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/cycling_team.dart';
import '../../models/team/sponsor_contract.dart';
import '../../services/generators/fictional_brands_catalog.dart';
import '../../services/generators/rider_procedural_generator.dart';
import '../../services/generators/world_teams_generator.dart';
import '../../state/career_controller.dart';
import '../widgets/rider_avatar_painter.dart';

/// Tryb tworzenia nowej kariery kolarskiej
enum CareerCreationMode {
  existingTeam,
  customTeam;

  String get title {
    switch (this) {
      case CareerCreationMode.existingTeam:
        return 'Poprowadź Istniejący Zespół';
      case CareerCreationMode.customTeam:
        return 'Stwórz Własny Zespół od Zera';
    }
  }

  String get description {
    switch (this) {
      case CareerCreationMode.existingTeam:
        return 'Wybierz jedną z 53 oficjalnych ekip peletonu (WorldTour, ProTeam lub Continental) i poprowadź jej kolarzy do sukcesów.';
      case CareerCreationMode.customTeam:
        return 'Zbuduj wymarzoną stajnię: zaprojektuj unikalną koszulkę, wybierz sponsora, dostawcę rowerów i przeprowadź draft kolarzy.';
    }
  }
}

/// Geometryczny wzór koszulki kolarskiej
enum JerseyPattern {
  chestStripe('Klasyczny pas piersiowy'),
  verticalStripes('Pionowe pasy wyścigowe'),
  diagonal('Skośny pas aerodynamiczny'),
  gradient('Gradient pionowy'),
  splitHalves('Dwukolorowy podział (Pół na pół)'),
  minimalist('Nowoczesny minimalistyczny blok');

  final String label;
  const JerseyPattern(this.label);
}

/// Opcja kraju dla tożsamości zespołu
class _CountryOption {
  final String iso;
  final String name;
  final String flag;
  const _CountryOption(this.iso, this.name, this.flag);
}

const List<_CountryOption> _kAvailableCountries = [
  _CountryOption('POL', 'Polska', '🇵🇱'),
  _CountryOption('FRA', 'Francja', '🇫🇷'),
  _CountryOption('ITA', 'Włochy', '🇮🇹'),
  _CountryOption('ESP', 'Hiszpania', '🇪🇸'),
  _CountryOption('BEL', 'Belgia', '🇧🇪'),
  _CountryOption('NED', 'Holandia', '🇳🇱'),
  _CountryOption('DEN', 'Dania', '🇩🇰'),
  _CountryOption('GBR', 'Wielka Brytania', '🇬🇧'),
  _CountryOption('SLO', 'Słowenia', '🇸🇮'),
  _CountryOption('COL', 'Kolumbia', '🇨🇴'),
  _CountryOption('GER', 'Niemcy', '🇩🇪'),
  _CountryOption('SUI', 'Szwajcaria', '🇨🇭'),
  _CountryOption('USA', 'Stany Zjednoczone', '🇺🇸'),
  _CountryOption('AUS', 'Australia', '🇦🇺'),
  _CountryOption('NOR', 'Norwegia', '🇳🇴'),
  _CountryOption('POR', 'Portugalia', '🇵🇹'),
  _CountryOption('AUT', 'Austria', '🇦🇹'),
  _CountryOption('ERI', 'Erytrea', '🇪🇷'),
  _CountryOption('KAZ', 'Kazachstan', '🇰🇿'),
  _CountryOption('CZE', 'Czechy', '🇨🇿'),
];

/// Paleta szybkich barw kolarskich
const List<Color> _kPresetColors = [
  Color(0xFFE10600), // Racing Red
  Color(0xFF0052CC), // Royal Blue
  Color(0xFF0EA5E9), // Sky Blue
  Color(0xFF00D26A), // Emerald Green
  Color(0xFF004225), // British Racing Green
  Color(0xFF00C2A8), // Celeste Bianchi
  Color(0xFFF59E0B), // Amber Gold
  Color(0xFFFACC15), // High-Vis Yellow
  Color(0xFFFF5722), // Papaya Orange
  Color(0xFF9333EA), // Royal Purple
  Color(0xFFEC4899), // Magenta Giro
  Color(0xFFFFFFFF), // Pearl White
  Color(0xFF94A3B8), // Silver Metallic
  Color(0xFF1E293B), // Navy Slate
  Color(0xFF0F172A), // Midnight Carbon
  Color(0xFF78350F), // Bronze Amber
];

/// Poziom budżetowy i trudności dla własnego zespołu
class _BudgetTierConfig {
  final CareerDifficulty difficulty;
  final String title;
  final String subtitle;
  final int initialCashEur;
  final int salaryCapEur;
  final IconData icon;

  const _BudgetTierConfig({
    required this.difficulty,
    required this.title,
    required this.subtitle,
    required this.initialCashEur,
    required this.salaryCapEur,
    required this.icon,
  });
}

const List<_BudgetTierConfig> _kBudgetTiers = [
  _BudgetTierConfig(
    difficulty: CareerDifficulty.easy,
    title: 'Bogaty Inwestor (Łatwy)',
    subtitle: 'Wielomilionowy budżet, możliwość zakontraktowania gwiazd i szybki marsz na szczyt WorldTour.',
    initialCashEur: 18000000,
    salaryCapEur: 12000000,
    icon: Icons.monetization_on_outlined,
  ),
  _BudgetTierConfig(
    difficulty: CareerDifficulty.normal,
    title: 'Stabilna Korporacja (Zbalansowany)',
    subtitle: 'Zdrowa sytuacja finansowa, wymagający lecz sprawiedliwy zarząd oraz zrównoważony rozwój.',
    initialCashEur: 9500000,
    salaryCapEur: 6500000,
    icon: Icons.account_balance_outlined,
  ),
  _BudgetTierConfig(
    difficulty: CareerDifficulty.hard,
    title: 'Skromny Budżet (Trudny)',
    subtitle: 'Ograniczone zasoby finansowe, konieczność szukania perełek na rynku i ostra dyscyplina płacowa.',
    initialCashEur: 4500000,
    salaryCapEur: 3200000,
    icon: Icons.savings_outlined,
  ),
  _BudgetTierConfig(
    difficulty: CareerDifficulty.realistic,
    title: 'Kolarski Romantyzm (Realistyczny)',
    subtitle: 'Minimalne środki, oparcie na lokalnej młodzieży, walka o każdą premię i każdą sekundę w ucieczce.',
    initialCashEur: 2200000,
    salaryCapEur: 1800000,
    icon: Icons.fitness_center_outlined,
  ),
];

/// Główny ekran kreatora nowej kariery
class NewCareerSetupScreen extends ConsumerStatefulWidget {
  final int initialSlotNumber;

  const NewCareerSetupScreen({
    super.key,
    this.initialSlotNumber = 1,
  });

  @override
  ConsumerState<NewCareerSetupScreen> createState() => _NewCareerSetupScreenState();
}

class _NewCareerSetupScreenState extends ConsumerState<NewCareerSetupScreen> {
  CareerCreationMode _mode = CareerCreationMode.existingTeam;

  // Globalne opcje zapisu
  late final TextEditingController _managerNameController;
  late final TextEditingController _saveNameController;
  CareerDifficulty _selectedDifficulty = CareerDifficulty.normal;
  late int _selectedSlot;

  // Istniejące zespoły (WorldTour / ProTeam / Continental)
  List<CyclingTeam> _existingTeams = [];
  List<Rider> _existingRiders = [];
  TeamDivision? _selectedDivisionFilter;
  String _teamSearchQuery = '';
  String _selectedExistingTeamId = '';
  bool _isLoadingWorld = true;

  // Własny zespół (Custom Team)
  int _customStepIndex = 0; // 0..5
  late final TextEditingController _customTeamNameController;
  late final TextEditingController _customTeamTlaController;
  String _selectedCountryIso = 'POL';
  TeamDivision _selectedCustomDivision = TeamDivision.continental;

  // Projektant koszulki
  JerseyPattern _selectedJerseyPattern = JerseyPattern.chestStripe;
  String _primaryColorHex = '#E10600';
  String _secondaryColorHex = '#1E293B';
  String _accentColorHex = '#FACC15';
  bool _isBackView = false;

  // Budżet i Sponsor tytularny
  _BudgetTierConfig _selectedBudgetTier = _kBudgetTiers[1];
  late final TextEditingController _sponsorNameController;
  SponsorIndustry _selectedSponsorIndustry = SponsorIndustry.energy;

  // Producent rowerów
  List<FictionalBrand> _availableBrands = [];
  String _selectedBrandId = 'brand_aethel';

  // Inauguralny Draft Kolarzy
  List<Rider> _draftPool = [];
  final Set<String> _draftedRiderIds = {};
  String _draftSearchQuery = '';
  RiderSpecialization? _draftSpecializationFilter;

  bool _isCreatingCareer = false;

  @override
  void initState() {
    super.initState();
    _selectedSlot = widget.initialSlotNumber;
    _managerNameController = TextEditingController(text: 'Dyrektor Sportowy');
    _saveNameController = TextEditingController(text: 'Kariera 2026');
    _customTeamNameController = TextEditingController(text: 'Orły Racing Team');
    _customTeamTlaController = TextEditingController(text: 'ORT');
    _sponsorNameController = TextEditingController(text: 'Orlen Energia');

    _loadWorldData();
  }

  @override
  void dispose() {
    _managerNameController.dispose();
    _saveNameController.dispose();
    _customTeamNameController.dispose();
    _customTeamTlaController.dispose();
    _sponsorNameController.dispose();
    super.dispose();
  }

  void _loadWorldData() {
    setState(() => _isLoadingWorld = true);

    final worldSystem = WorldTeamsGenerator.generateWorldTourSystem(seed: 42);
    _existingTeams = worldSystem.teams;
    _existingRiders = worldSystem.allRiders;
    if (_existingTeams.isNotEmpty) {
      _selectedExistingTeamId = _existingTeams.first.id;
    }

    _availableBrands = FictionalBrandsCatalog.allBrands;
    if (_availableBrands.isNotEmpty) {
      _selectedBrandId = _availableBrands.first.id;
    }

    _generateDraftPool();

    setState(() => _isLoadingWorld = false);
  }

  void _generateDraftPool() {
    final rng = math.Random(54321);
    final pool = <Rider>[];

    // 4 GC Stars
    for (int i = 0; i < 4; i++) {
      pool.add(RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.gcClimber,
        role: RiderRole.teamLeader,
        targetOverallRating: 78 + rng.nextInt(7),
        random: rng,
      ));
    }
    // 6 Climbers
    for (int i = 0; i < 6; i++) {
      pool.add(RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.pureClimber,
        role: RiderRole.superDomestique,
        targetOverallRating: 74 + rng.nextInt(8),
        random: rng,
      ));
    }
    // 6 Sprinters
    for (int i = 0; i < 6; i++) {
      pool.add(RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.pureSprinter,
        role: RiderRole.sprinter,
        targetOverallRating: 74 + rng.nextInt(8),
        random: rng,
      ));
    }
    // 6 Punchers
    for (int i = 0; i < 6; i++) {
      pool.add(RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.puncher,
        role: RiderRole.breakawaySpecialist,
        targetOverallRating: 73 + rng.nextInt(8),
        random: rng,
      ));
    }
    // 6 Rouleurs / Time Trialists
    for (int i = 0; i < 6; i++) {
      pool.add(RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.timeTrialist,
        role: RiderRole.domestique,
        targetOverallRating: 73 + rng.nextInt(7),
        random: rng,
      ));
    }
    // 10 Domestiques & Neo-Pros
    for (int i = 0; i < 10; i++) {
      final isNeo = i % 2 == 0;
      if (isNeo) {
        pool.add(RiderProceduralGenerator.generateNeoProTalent(
          currentSeasonYear: 2026,
          tier: ScoutingTier.continentalHopeful,
          random: rng,
        ));
      } else {
        pool.add(RiderProceduralGenerator.generateRider(
          specialization: RiderSpecialization.domestiqueEngine,
          role: RiderRole.domestique,
          targetOverallRating: 68 + rng.nextInt(7),
          random: rng,
        ));
      }
    }

    _draftPool = pool;
    _draftedRiderIds.clear();
  }

  void _performAutoDraft() {
    _draftedRiderIds.clear();

    final gc = _draftPool.where((r) => r.specialization == RiderSpecialization.gcClimber).take(1);
    final climbers = _draftPool.where((r) => r.specialization == RiderSpecialization.pureClimber).take(3);
    final sprinters = _draftPool.where((r) => r.specialization == RiderSpecialization.pureSprinter).take(2);
    final punchers = _draftPool.where((r) => r.specialization == RiderSpecialization.puncher).take(2);
    final tt = _draftPool.where((r) => r.specialization == RiderSpecialization.timeTrialist).take(2);
    final domestiques = _draftPool.where((r) => r.contract.role == RiderRole.domestique || r.contract.role == RiderRole.neoPro).take(4);

    for (final r in [...gc, ...climbers, ...sprinters, ...punchers, ...tt, ...domestiques]) {
      _draftedRiderIds.add(r.id);
    }
    setState(() {});
  }

  int get _draftedTotalSalaryEur {
    int sum = 0;
    for (final id in _draftedRiderIds) {
      final r = _draftPool.firstWhere((x) => x.id == id, orElse: () => _draftPool.first);
      sum += r.contract.annualSalaryEur;
    }
    return sum;
  }

  Color _parseHex(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  String _formatEur(int amount) {
    if (amount >= 1000000) {
      return '€${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '€${(amount / 1000).toStringAsFixed(0)}k';
    }
    return '€$amount';
  }

  String _getCountryFlag(String iso) {
    for (final c in _kAvailableCountries) {
      if (c.iso == iso) return c.flag;
    }
    return '🏁';
  }

  Future<void> _launchExistingTeamCareer() async {
    final team = _existingTeams.firstWhere(
      (t) => t.id == _selectedExistingTeamId,
      orElse: () => _existingTeams.first,
    );

    setState(() => _isCreatingCareer = true);

    final careerController = ref.read(careerControllerProvider.notifier);
    final success = await careerController.startNewCareer(
      saveName: _saveNameController.text.trim().isNotEmpty
          ? _saveNameController.text.trim()
          : 'Kariera ${team.name}',
      playerManagerName: _managerNameController.text.trim().isNotEmpty
          ? _managerNameController.text.trim()
          : 'Dyrektor Sportowy',
      playerTeamId: team.id,
      difficulty: _selectedDifficulty,
      seasonYear: 2026,
      targetSlotNumber: _selectedSlot,
    );

    if (mounted) {
      setState(() => _isCreatingCareer = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.emeraldGreen,
            content: Text('Kariera z zespołem "${team.name}" w Slocie $_selectedSlot została pomyślnie rozpoczęta!'),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.crimsonAlert,
            content: Text('Wystąpił błąd podczas tworzenia pliku zapisu nowej kariery.'),
          ),
        );
      }
    }
  }

  Future<void> _launchCustomTeamCareer() async {
    if (_draftedRiderIds.length < 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.amberWarning,
          content: Text('Skład wymaga minimum 12 kolarzy (obecnie: ${_draftedRiderIds.length}). Dodaj więcej kolarzy w drafcie!'),
        ),
      );
      setState(() => _customStepIndex = 4);
      return;
    }

    if (_draftedTotalSalaryEur > _selectedBudgetTier.salaryCapEur) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.crimsonAlert,
          content: Text('Przekroczono limit płacowy draftu (${_formatEur(_draftedTotalSalaryEur)} > ${_formatEur(_selectedBudgetTier.salaryCapEur)}). Zredukuj pensje!'),
        ),
      );
      setState(() => _customStepIndex = 4);
      return;
    }

    setState(() => _isCreatingCareer = true);

    final tla = _customTeamTlaController.text.trim().toUpperCase().replaceAll(' ', '');
    final cleanTla = tla.isNotEmpty ? tla : 'ORT';
    final teamId = 'custom_${cleanTla.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch % 10000}';
    final teamName = _customTeamNameController.text.trim().isNotEmpty
        ? _customTeamNameController.text.trim()
        : 'Team Pro Cycling';

    // Kontrakt z producentem rowerów
    final bikeDeal = FictionalBrandsCatalog.createManufacturerDeal(
      brandId: _selectedBrandId,
      contractYearsLeft: 2,
    );

    final inventoryBikes = [
      FictionalBrandsCatalog.assembleBike(
        brandId: _selectedBrandId,
        frameCategory: FrameCategory.aero,
      ),
      FictionalBrandsCatalog.assembleBike(
        brandId: _selectedBrandId,
        frameCategory: FrameCategory.lightweightClimbing,
      ),
      FictionalBrandsCatalog.assembleBike(
        brandId: _selectedBrandId,
        frameCategory: FrameCategory.timeTrial,
      ),
    ];

    // Finanse i Sponsor
    final int initialCash = _selectedBudgetTier.initialCashEur;
    final int annualSponsorCash = (initialCash * 0.75).round();

    final primarySponsor = SponsorContract(
      id: 'sponsor_${teamId}_title',
      companyName: _sponsorNameController.text.trim().isNotEmpty
          ? _sponsorNameController.text.trim()
          : 'Orlen Energia',
      industry: _selectedSponsorIndustry,
      sponsorTier: SponsorTier.titlePrimary,
      annualBudgetEur: annualSponsorCash,
      contractDurationYears: 3,
      sponsorSatisfaction: 85.0,
      objectives: const [
        SponsorObjective(
          id: 'obj_1',
          description: 'Top 10 w klasyfikacji generalnej wyścigu etapowego',
          bonusPaymentEur: 50000,
          importance: ObjectiveImportance.high,
          isCompleted: false,
          currentProgress: 0,
          targetProgress: 1,
        ),
        SponsorObjective(
          id: 'obj_2',
          description: 'Wygraj przynajmniej 1 etap w sezonie',
          bonusPaymentEur: 75000,
          importance: ObjectiveImportance.critical,
          isCompleted: false,
          currentProgress: 0,
          targetProgress: 1,
        ),
      ],
    );

    // Kolarze z draftu
    final draftedRidersList = _draftPool
        .where((r) => _draftedRiderIds.contains(r.id))
        .map((r) => r.copyWith(
              contract: r.contract.copyWith(
                teamId: teamId,
                contractEndYear: 2027,
                morale: 95.0,
              ),
            ))
        .toList();

    final int annualSalaries = draftedRidersList.fold<int>(0, (sum, r) => sum + r.contract.annualSalaryEur);
    final int monthlyBurn = (annualSalaries / 12).round() + 35000;

    final customTeam = CyclingTeam(
      id: teamId,
      name: teamName,
      division: _selectedCustomDivision,
      countryIso: _selectedCountryIso,
      primaryJerseyColorHex: _primaryColorHex,
      secondaryJerseyColorHex: _secondaryColorHex,
      accentJerseyColorHex: _accentColorHex,
      cashBalanceEur: initialCash,
      monthlyBurnRateEur: monthlyBurn,
      uciPointsSeason: 0,
      rosterRiderIds: draftedRidersList.map((r) => r.id).toList(),
      staff: const TeamStaff(
        trainersLevel: 68,
        sportsDirectorsLevel: 72,
        doctorsLevel: 65,
        mechanicsLevel: 70,
        scoutsLevel: 64,
      ),
      bikeDeal: bikeDeal,
      sponsors: [primarySponsor],
      inventoryBikes: inventoryBikes,
    );

    final careerController = ref.read(careerControllerProvider.notifier);
    final success = await careerController.startNewCareer(
      saveName: _saveNameController.text.trim().isNotEmpty
          ? _saveNameController.text.trim()
          : 'Kariera $teamName',
      playerManagerName: _managerNameController.text.trim().isNotEmpty
          ? _managerNameController.text.trim()
          : 'Dyrektor Sportowy',
      playerTeamId: teamId,
      difficulty: _selectedBudgetTier.difficulty,
      seasonYear: 2026,
      targetSlotNumber: _selectedSlot,
      customTeam: customTeam,
      customRoster: draftedRidersList,
    );

    if (mounted) {
      setState(() => _isCreatingCareer = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.emeraldGreen,
            content: Text('Własny zespół "$teamName" został oficjalnie zainaugurowany w Slocie $_selectedSlot!'),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.crimsonAlert,
            content: Text('Wystąpił błąd podczas tworzenia własnej stajni kolarskiej.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.sports_score, color: AppColors.goldAccent),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'KREATOR NOWEJ KARIERY 2026',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildModeToggleTab(
                    mode: CareerCreationMode.existingTeam,
                    label: 'Poprowadź Istniejący Zespół',
                    icon: Icons.groups_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildModeToggleTab(
                    mode: CareerCreationMode.customTeam,
                    label: 'Stwórz Własny Zespół (Custom)',
                    icon: Icons.brush_outlined,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoadingWorld
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.goldAccent),
                  SizedBox(height: 16),
                  Text(
                    'Inicjalizacja peletonu UCI, kolarzy i tras...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : _mode == CareerCreationMode.existingTeam
              ? _buildExistingTeamModeView()
              : _buildCustomTeamModeView(),
    );
  }

  Widget _buildModeToggleTab({
    required CareerCreationMode mode,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _mode == mode;
    return InkWell(
      onTap: () => setState(() => _mode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldAccent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.goldAccent : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TRYB 1: POPROWADŹ ISTNIEJĄCY ZESPÓŁ
  // ===========================================================================

  Widget _buildExistingTeamModeView() {
    final filteredTeams = _existingTeams.where((t) {
      if (_selectedDivisionFilter != null && t.division != _selectedDivisionFilter) {
        return false;
      }
      if (_teamSearchQuery.isNotEmpty) {
        final query = _teamSearchQuery.toLowerCase();
        final matchName = t.name.toLowerCase().contains(query);
        final matchCountry = t.countryIso.toLowerCase().contains(query);
        if (!matchName && !matchCountry) return false;
      }
      return true;
    }).toList();

    final selectedTeam = _existingTeams.firstWhere(
      (t) => t.id == _selectedExistingTeamId,
      orElse: () => _existingTeams.first,
    );

    return Column(
      children: [
        // Pasek ustawień menedżera i slotu
        _buildGlobalSettingsHeader(),

        // Pasek filtrów dywizji i wyszukiwarki
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface,
          child: Wrap(
            spacing: 6,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Filtry dywizji
              _buildDivisionFilterChip('Wszystkie (${_existingTeams.length})', null),
              _buildDivisionFilterChip('WorldTour (18)', TeamDivision.worldTour),
              _buildDivisionFilterChip('ProTeam (17)', TeamDivision.proTeam),
              _buildDivisionFilterChip('Continental (18)', TeamDivision.continental),
              // Wyszukiwarka
              SizedBox(
                width: 220,
                height: 36,
                child: TextField(
                  onChanged: (val) => setState(() => _teamSearchQuery = val),
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Szukaj po nazwie lub kraju...',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Główny układ: Lista drużyn (po lewej) + Szczegółowe dossier wybranego zespołu (po prawej)
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 760;
              final teamList = ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: filteredTeams.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final team = filteredTeams[index];
                  final isSelected = team.id == _selectedExistingTeamId;
                  return _buildExistingTeamCard(team, isSelected);
                },
              );
              final teamDossier = Container(
                margin: isCompact
                    ? const EdgeInsets.fromLTRB(12, 0, 12, 12)
                    : const EdgeInsets.only(top: 12, right: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: _buildTeamDossier(selectedTeam),
              );

              if (isCompact) {
                return Column(
                  children: [
                    Expanded(flex: 4, child: teamList),
                    Expanded(flex: 5, child: teamDossier),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 5, child: teamList),
                  Expanded(flex: 6, child: teamDossier),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDivisionFilterChip(String label, TeamDivision? division) {
    final isSelected = _selectedDivisionFilter == division;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.black : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedDivisionFilter = division);
      },
      selectedColor: AppColors.goldAccent,
      backgroundColor: AppColors.surfaceLight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }

  Widget _buildExistingTeamCard(CyclingTeam team, bool isSelected) {
    final primaryColor = _parseHex(team.primaryJerseyColorHex, AppColors.accentBlue);
    final secondaryColor = _parseHex(team.secondaryJerseyColorHex, AppColors.surfaceLight);

    return InkWell(
      onTap: () => setState(() => _selectedExistingTeamId = team.id),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceLight : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.goldAccent : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Miniatura koszulki (barwy)
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Center(
                child: Text(
                  _getCountryFlag(team.countryIso),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Nazwa i liga
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _getDivisionBadgeColor(team.division).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _getDivisionBadgeColor(team.division),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          team.division.label,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: _getDivisionBadgeColor(team.division),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kolarzy: ${team.rosterRiderIds.length}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Budżet
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatEur(team.cashBalanceEur),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.emeraldGreen,
                  ),
                ),
                Text(
                  team.bikeDeal.manufacturerName,
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamDossier(CyclingTeam team) {
    final teamRiders = _existingRiders.where((r) => team.rosterRiderIds.contains(r.id)).toList();
    // Sortuj kolarzy malejąco wg OVR
    teamRiders.sort((a, b) => b.overallRating.compareTo(a.overallRating));

    final primaryColor = _parseHex(team.primaryJerseyColorHex, AppColors.accentBlue);
    final secondaryColor = _parseHex(team.secondaryJerseyColorHex, AppColors.surfaceLight);
    final accentColor = _parseHex(team.accentJerseyColorHex, AppColors.goldAccent);

    final avgOvr = teamRiders.isNotEmpty
        ? (teamRiders.map((r) => r.overallRating).reduce((a, b) => a + b) / teamRiders.length).round()
        : 70;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isShort = constraints.maxHeight < 420;
        final headerWidget = Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Próbnik barw zespołu
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor, accentColor],
                    stops: const [0.0, 0.65, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white24, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getCountryFlag(team.countryIso),
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${team.division.label}  •  ${team.countryIso}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.goldAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Śr. OVR: $avgOvr',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.goldAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        _buildMiniStat(Icons.euro, 'Budżet', _formatEur(team.cashBalanceEur), AppColors.emeraldGreen),
                        _buildMiniStat(Icons.pedal_bike, 'Rower', team.bikeDeal.manufacturerName, AppColors.cyanAccent),
                        _buildMiniStat(Icons.handshake_outlined, 'Sponsor', team.sponsors.isNotEmpty ? team.sponsors.first.companyName : 'Klubowy', AppColors.goldAccent),
                        _buildMiniStat(Icons.engineering_outlined, 'Sztab', '${team.staff.averageStaffLevel.toStringAsFixed(0)}/100', AppColors.powerZone7),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        // Lista gwiazd i składu
        final listHeader = Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'SKŁAD DRUŻYNY (${teamRiders.length} KOLARZY)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const Text(
                'Posortowano wg OVR',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        );

        final ridersList = ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: teamRiders.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderColor),
            itemBuilder: (context, index) {
              final rider = teamRiders[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    RiderAvatarWidget.fromRider(rider: rider, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rider.fullName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${rider.specialization.displayName}  •  ${rider.age} lat',
                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Kluczowe atrybuty
                    _buildRiderKeyStatBadge('FTP', '${rider.physiology.ftpWatts}W', AppColors.cyanAccent),
                    const SizedBox(width: 6),
                    _buildRiderKeyStatBadge('W/kg', rider.physiology.wattsPerKg.toStringAsFixed(1), AppColors.emeraldGreen),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Text(
                        '${rider.overallRating}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );

        // Przycisk wyboru i rozpoczęcia kariery
        final footerButton = Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            border: Border(top: BorderSide(color: AppTheme.borderColor)),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
          child: ElevatedButton.icon(
            onPressed: _isCreatingCareer ? null : _launchExistingTeamCareer,
            icon: _isCreatingCareer
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              _isCreatingCareer
                  ? 'GENEROWANIE ŚWIATA KARIERY...'
                  : 'WYBIERZ ${team.name.toUpperCase()} I ROZPOCZNIJ KARIERĘ',
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        );

        if (isShort) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                headerWidget,
                listHeader,
                SizedBox(height: 180, child: ridersList),
                footerButton,
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            headerWidget,
            listHeader,
            Expanded(child: ridersList),
            footerButton,
          ],
        );
      },
    );
  }

  Widget _buildMiniStat(IconData icon, String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildRiderKeyStatBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Color _getDivisionBadgeColor(TeamDivision division) {
    switch (division) {
      case TeamDivision.worldTour:
        return AppColors.goldAccent;
      case TeamDivision.proTeam:
        return AppColors.accentBlue;
      case TeamDivision.continental:
        return AppColors.cyanAccent;
    }
  }

  Widget _buildGlobalSettingsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          // Nazwisko Menedżera
          Expanded(
            flex: 3,
            child: TextField(
              controller: _managerNameController,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Dyrektor Sportowy (Menedżer)',
                labelStyle: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Nazwa zapisu
          Expanded(
            flex: 3,
            child: TextField(
              controller: _saveNameController,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Nazwa Pliku Zapisu',
                labelStyle: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Wybór trudności
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<CareerDifficulty>(
              isExpanded: true,
              initialValue: _selectedDifficulty,
              onChanged: (val) {
                if (val != null) setState(() => _selectedDifficulty = val);
              },
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(
                labelText: 'Poziom Trudności',
                labelStyle: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              ),
              items: CareerDifficulty.values.map((d) {
                return DropdownMenuItem(
                  value: d,
                  child: Text(
                    d.label.split('(').first.trim(),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 12),

          // Wybór slotu (1-5)
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _selectedSlot,
              onChanged: (val) {
                if (val != null) setState(() => _selectedSlot = val);
              },
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(
                labelText: 'Slot Zapisu',
                labelStyle: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              ),
              items: List.generate(5, (i) => i + 1).map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text('Slot $s', style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TRYB 2: STWÓRZ WŁASNY ZESPÓŁ (CUSTOM TEAM WIZARD)
  // ===========================================================================

  Widget _buildCustomTeamModeView() {
    return Column(
      children: [
        // Pasek kroków (Stepped Progress Bar)
        _buildWizardStepIndicator(),

        // Zawartość aktualnego kroku
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildCurrentWizardStepContent(),
          ),
        ),

        // Dolny pasek nawigacji kreatora (Wstecz / Dalej / Inauguruj)
        _buildWizardBottomNav(),
      ],
    );
  }

  Widget _buildWizardStepIndicator() {
    final steps = [
      '1. Tożsamość',
      '2. Koszulka',
      '3. Budżet & Sponsor',
      '4. Sprzęt & Rower',
      '5. Draft Kolarzy',
      '6. Inauguracja',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surfaceLight,
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = _customStepIndex == index;
          final isCompleted = _customStepIndex > index;

          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _customStepIndex = index),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 9,
                              backgroundColor: isCompleted
                                  ? AppColors.emeraldGreen
                                  : isActive
                                      ? AppColors.goldAccent
                                      : AppTheme.borderColor,
                              child: isCompleted
                                  ? const Icon(Icons.check, size: 11, color: Colors.black)
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isActive ? Colors.black : AppColors.textMuted,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                steps[index],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  color: isActive
                                      ? AppColors.goldAccent
                                      : isCompleted
                                          ? AppColors.textPrimary
                                          : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: isCompleted ? 1.0 : (isActive ? 0.5 : 0.0),
                          backgroundColor: AppTheme.borderColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted ? AppColors.emeraldGreen : AppColors.goldAccent,
                          ),
                          minHeight: 2.5,
                        ),
                      ],
                    ),
                  ),
                  if (index < steps.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.chevron_right, size: 14, color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentWizardStepContent() {
    switch (_customStepIndex) {
      case 0:
        return _buildStep1Identity();
      case 1:
        return _buildStep2JerseyDesigner();
      case 2:
        return _buildStep3BudgetAndSponsor();
      case 3:
        return _buildStep4BikeManufacturer();
      case 4:
        return _buildStep5RiderDraft();
      case 5:
        return _buildStep6Summary();
      default:
        return const SizedBox.shrink();
    }
  }

  // KROK 1: TOŻSAMOŚĆ ZESPOŁU
  Widget _buildStep1Identity() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.badge_outlined, color: AppColors.goldAccent, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'KROK 1: TOŻSAMOŚĆ TWOJEJ NOWEJ DRUŻYNY',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Wprowadź oficjalną nazwę, 3-literowy kod UCI oraz kraj rejestracji. To pod tymi barwami będziesz walczyć o zwycięstwa w Monumentach i Grand Tourach.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Divider(height: 28, color: AppTheme.borderColor),

              // Nazwa zespołu i TLA
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _customTeamNameController,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Oficjalna Nazwa Drużyny',
                        hintText: 'np. Orły Mazowsza, Amber Coast Racing',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _customTeamTlaController,
                      maxLength: 3,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldAccent,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Kod UCI (TLA)',
                        hintText: 'OMZ',
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Kraj rejestracji UCI
              const Text(
                'Kraj Rejestracji UCI',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kAvailableCountries.map((c) {
                  final isSelected = _selectedCountryIso == c.iso;
                  return ChoiceChip(
                    label: Text('${c.flag} ${c.name} (${c.iso})'),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _selectedCountryIso = c.iso);
                    },
                    selectedColor: AppColors.goldAccent,
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.black : AppColors.textPrimary,
                    ),
                    backgroundColor: AppColors.surfaceLight,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Dywizja startowa
              const Text(
                'Dywizja Startowa UCI',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDivisionOptionCard(
                      division: TeamDivision.continental,
                      title: 'UCI Continental',
                      desc: 'Początek drogi. Wyścigi niższej kategorii (1.2, 2.2), oparcie na młodych talentach.',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDivisionOptionCard(
                      division: TeamDivision.proTeam,
                      title: 'UCI ProTeam',
                      desc: 'Zaplecze elity. Dzikie karty na Monumenty i wielkie klasyki, dynamiczny rozwój.',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDivisionOptionCard(
                      division: TeamDivision.worldTour,
                      title: 'UCI WorldTour',
                      desc: 'Ścisła elita. Gwarantowany start w Tour de France, Giro i Vuelcie od pierwszego dnia.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Dane Menedżera i Zapis
              const Text(
                'Menedżer i Plik Zapisu',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _managerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Imię i Nazwisko Menedżera / DS',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _saveNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nazwa Zapisu Gry',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 130,
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedSlot,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSlot = val);
                      },
                      dropdownColor: AppColors.surface,
                      decoration: const InputDecoration(labelText: 'Slot'),
                      items: List.generate(5, (i) => i + 1).map((s) {
                        return DropdownMenuItem(value: s, child: Text('Slot $s'));
                      }).toList(),
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

  Widget _buildDivisionOptionCard({
    required TeamDivision division,
    required String title,
    required String desc,
  }) {
    final isSelected = _selectedCustomDivision == division;
    final badgeColor = _getDivisionBadgeColor(division);

    return InkWell(
      onTap: () => setState(() => _selectedCustomDivision = division),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? badgeColor.withValues(alpha: 0.12) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? badgeColor : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 16,
                  color: isSelected ? badgeColor : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? badgeColor : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // KROK 2: PROJEKTANT KOSZULKI (JERSEY DESIGNER)
  Widget _buildStep2JerseyDesigner() {
    final teamTla = _customTeamTlaController.text.trim().toUpperCase();
    final cleanTla = teamTla.isNotEmpty ? teamTla : 'ORT';
    final teamName = _customTeamNameController.text.trim().isNotEmpty
        ? _customTeamNameController.text.trim()
        : 'TEAM PRO';

    return Row(
      children: [
        // Lewa kolumna: Interaktywny podgląd koszulki 2D (CustomPainter)
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PODGLĄD KOSZULKI NA ŻYWO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    // Przełącznik Przód / Tył
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Przód')),
                        ButtonSegment(value: true, label: Text('Plecy (#1)')),
                      ],
                      selected: {_isBackView},
                      onSelectionChanged: (set) {
                        setState(() => _isBackView = set.first);
                      },
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 0.95,
                      child: CustomPaint(
                        painter: TeamJerseyPainter(
                          primaryColor: _parseHex(_primaryColorHex, const Color(0xFFE10600)),
                          secondaryColor: _parseHex(_secondaryColorHex, const Color(0xFF1E293B)),
                          accentColor: _parseHex(_accentColorHex, const Color(0xFFFACC15)),
                          pattern: _selectedJerseyPattern,
                          isBackView: _isBackView,
                          teamName: teamName,
                          teamTla: cleanTla,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Wzór: ${_selectedJerseyPattern.label}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Prawa kolumna: Narzędzia doboru wzoru i 3 kolorów
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. WYBIERZ WZÓR KOSZULKI',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: JerseyPattern.values.map((pattern) {
                      final isSelected = _selectedJerseyPattern == pattern;
                      return ChoiceChip(
                        label: Text(pattern.label),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() => _selectedJerseyPattern = pattern);
                        },
                        selectedColor: AppColors.goldAccent,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.black : AppColors.textPrimary,
                        ),
                        backgroundColor: AppColors.surfaceLight,
                      );
                    }).toList(),
                  ),
                  const Divider(height: 28, color: AppTheme.borderColor),

                  // Kolor Główny (Primary)
                  _buildColorPickerSection(
                    title: 'KOLOR GŁÓWNY (BAZA)',
                    currentColorHex: _primaryColorHex,
                    onColorChanged: (hex) => setState(() => _primaryColorHex = hex),
                  ),
                  const SizedBox(height: 18),

                  // Kolor Dodatkowy (Secondary)
                  _buildColorPickerSection(
                    title: 'KOLOR DODATKOWY (WZÓR / RĘKAWY)',
                    currentColorHex: _secondaryColorHex,
                    onColorChanged: (hex) => setState(() => _secondaryColorHex = hex),
                  ),
                  const SizedBox(height: 18),

                  // Kolor Akcentu (Accent)
                  _buildColorPickerSection(
                    title: 'KOLOR AKCENTU (KOŁNIERZ / DETALE)',
                    currentColorHex: _accentColorHex,
                    onColorChanged: (hex) => setState(() => _accentColorHex = hex),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPickerSection({
    required String title,
    required String currentColorHex,
    required ValueChanged<String> onColorChanged,
  }) {
    final currentColor = _parseHex(currentColorHex, Colors.white);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              currentColorHex.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.goldAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Próbniki kolorów
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _kPresetColors.map((color) {
            final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
            final isSelected = currentColorHex.toUpperCase() == hex;

            return InkWell(
              onTap: () => onColorChanged(hex),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? Colors.white : AppTheme.borderColor,
                    width: isSelected ? 2.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // KROK 3: BUDŻET POCZĄTKOWY I SPONSOR TYTULARNY
  Widget _buildStep3BudgetAndSponsor() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 860),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.monetization_on_outlined, color: AppColors.goldAccent, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'KROK 3: BUDŻET POCZĄTKOWY I SPONSOR TYTULARNY',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Wybierz pakiet finansowy definiujący poziom trudności oraz podpisz pierwszą wieloletnią umowę ze sponsorem tytularnym.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Divider(height: 28, color: AppTheme.borderColor),

              // Pakiety budżetowe (Difficulty Tiers)
              const Text(
                '1. Wybierz Pakiet Finansowy (Poziom Trudności)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              Column(
                children: _kBudgetTiers.map((tier) {
                  final isSelected = _selectedBudgetTier == tier;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => setState(() => _selectedBudgetTier = tier),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.goldAccent.withValues(alpha: 0.12)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.goldAccent : AppTheme.borderColor,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              tier.icon,
                              size: 28,
                              color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tier.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? AppColors.goldAccent : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    tier.subtitle,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatEur(tier.initialCashEur),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.emeraldGreen,
                                  ),
                                ),
                                Text(
                                  'Limit płac: ${_formatEur(tier.salaryCapEur)}/rok',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Divider(height: 28, color: AppTheme.borderColor),

              // Sponsor Tytularny
              const Text(
                '2. Umowa ze Sponsorem Tytularnym',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _sponsorNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nazwa Firmy Sponsora Tytularnego',
                        hintText: 'np. Orlen Energia, TotalEnergies, Apex Bank',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<SponsorIndustry>(
                      initialValue: _selectedSponsorIndustry,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSponsorIndustry = val);
                      },
                      dropdownColor: AppColors.surface,
                      decoration: const InputDecoration(labelText: 'Branża Sponsora'),
                      items: SponsorIndustry.values.map((ind) {
                        return DropdownMenuItem(
                          value: ind,
                          child: Text(ind.name.toUpperCase()),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_outlined, color: AppColors.goldAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Roczna wypłata sponsorska wyniesie ${_formatEur((_selectedBudgetTier.initialCashEur * 0.75).round())} przez 3 sezony (zależna od realizacji celów sportowych).',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // KROK 4: PRODUCENT ROWERÓW (BIKE MANUFACTURER DEAL)
  Widget _buildStep4BikeManufacturer() {
    final selectedBrand = _availableBrands.firstWhere(
      (b) => b.id == _selectedBrandId,
      orElse: () => _availableBrands.first,
    );

    return Row(
      children: [
        // Lista dostępnych marek (lewa strona)
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'WYBIERZ DOSTAWCĘ ROWERÓW (15 MAREK)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: AppColors.goldAccent,
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.borderColor),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _availableBrands.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final brand = _availableBrands[index];
                      final isSelected = brand.id == _selectedBrandId;

                      return InkWell(
                        onTap: () => setState(() => _selectedBrandId = brand.id),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.surfaceLight : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.goldAccent : AppTheme.borderColor,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _parseHex(brand.primaryColorHex, AppColors.cyanAccent),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    _getCountryFlag(brand.countryIso),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      brand.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (i) => Icon(
                                          Icons.star,
                                          size: 11,
                                          color: i < brand.prestige ? AppColors.goldAccent : AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatEur((brand.prestige * 450000) + 200000),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.emeraldGreen,
                                    ),
                                  ),
                                  const Text(
                                    'Wkład gotówkowy',
                                    style: TextStyle(fontSize: 9.5, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Szczegóły wybranej marki i dostarczany sprzęt (prawa strona)
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: _parseHex(selectedBrand.primaryColorHex, AppColors.cyanAccent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _getCountryFlag(selectedBrand.countryIso),
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedBrand.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              ...List.generate(
                                5,
                                (i) => Icon(
                                  Icons.star,
                                  size: 14,
                                  color: i < selectedBrand.prestige ? AppColors.goldAccent : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${selectedBrand.countryIso}  •  Prestiż ${selectedBrand.prestige}/5',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            selectedBrand.description,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28, color: AppTheme.borderColor),

                // Parametry kontraktu
                const Text(
                  'WARUNKI KONTRAKTU SPRZĘTOWEGO',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: AppColors.goldAccent,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildEquipmentStatCard(
                        title: 'Wkład Finansowy',
                        value: _formatEur((selectedBrand.prestige * 450000) + 200000),
                        subtitle: 'Roczny zastrzyk do budżetu',
                        color: AppColors.emeraldGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildEquipmentStatCard(
                        title: 'Darmowe Rowery',
                        value: '${(selectedBrand.prestige * 18) + 30} szt.',
                        subtitle: 'Pula maszyn na sezon',
                        color: AppColors.cyanAccent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildEquipmentStatCard(
                        title: 'Poziom R&D',
                        value: '${(selectedBrand.prestige * 16) + 18}/100',
                        subtitle: 'Szybkość rozwoju aero',
                        color: AppColors.powerZone7,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Dostarczane ramy
                const Text(
                  'DOSTARCZANE MODELE RAM',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: AppColors.goldAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: selectedBrand.frames.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final frame = selectedBrand.frames[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.pedal_bike, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                frame.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              '${frame.weightGrams}g  •  CdA: ${frame.aeroCdaModifier.toStringAsFixed(3)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // KROK 5: INAUGURALNY DRAFT KOLARZY (RIDER DRAFT)
  Widget _buildStep5RiderDraft() {
    final draftedCount = _draftedRiderIds.length;
    final totalSalary = _draftedTotalSalaryEur;
    final cap = _selectedBudgetTier.salaryCapEur;
    final isSalaryOver = totalSalary > cap;

    final filteredRiders = _draftPool.where((r) {
      if (_draftSpecializationFilter != null && r.specialization != _draftSpecializationFilter) {
        return false;
      }
      if (_draftSearchQuery.isNotEmpty) {
        final query = _draftSearchQuery.toLowerCase();
        if (!r.fullName.toLowerCase().contains(query) && !r.nationalityIso.toLowerCase().contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Pasek podsumowania draftu i salary cap
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              // Licznik kolarzy
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LICZBA KOLARZY W SKŁADZIE', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '$draftedCount / 16',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: draftedCount >= 12 ? AppColors.emeraldGreen : AppColors.amberWarning,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        draftedCount >= 12 ? '(Wymóg spełniony)' : '(Min. 12 kolarzy!)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: draftedCount >= 12 ? AppColors.emeraldGreen : AppColors.amberWarning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 24),

              // Pasek Salary Cap
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('SUMA PŁAC ROCZNYCH (SALARY CAP)', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        Text(
                          '${_formatEur(totalSalary)} / ${_formatEur(cap)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSalaryOver ? AppColors.crimsonAlert : AppColors.emeraldGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: (totalSalary / cap).clamp(0.0, 1.0),
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isSalaryOver ? AppColors.crimsonAlert : AppColors.emeraldGreen,
                      ),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Przycisk Szybki Auto-Draft
              ElevatedButton.icon(
                onPressed: _performAutoDraft,
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('SZYBKI AUTO-DRAFT (14)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => setState(() => _draftedRiderIds.clear()),
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('WYCZYŚĆ'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Filtry i wyszukiwarka draftu
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Wszyscy'),
                      selected: _draftSpecializationFilter == null,
                      onSelected: (val) => setState(() => _draftSpecializationFilter = null),
                      selectedColor: AppColors.goldAccent,
                      backgroundColor: AppColors.surfaceLight,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: _draftSpecializationFilter == null ? Colors.black : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ...RiderSpecialization.values.map((spec) {
                      final isSelected = _draftSpecializationFilter == spec;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(spec.displayName),
                          selected: isSelected,
                          onSelected: (val) => setState(() => _draftSpecializationFilter = val ? spec : null),
                          selectedColor: AppColors.goldAccent,
                          backgroundColor: AppColors.surfaceLight,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.black : AppColors.textPrimary,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 220,
              height: 36,
              child: TextField(
                onChanged: (val) => setState(() => _draftSearchQuery = val),
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Szukaj kolarza...',
                  hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Siatka / Lista kolarzy do wyboru
        Expanded(
          child: ListView.separated(
            itemCount: filteredRiders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final rider = filteredRiders[index];
              final isDrafted = _draftedRiderIds.contains(rider.id);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDrafted ? AppColors.goldAccent.withValues(alpha: 0.12) : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDrafted ? AppColors.goldAccent : AppTheme.borderColor,
                    width: isDrafted ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    RiderAvatarWidget.fromRider(rider: rider, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                rider.fullName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getCountryFlag(rider.nationalityIso),
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${rider.overallRating} OVR',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.goldAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${rider.specialization.displayName}  •  ${rider.age} lat  •  ${rider.contract.role.label}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Statystyki
                    _buildRiderKeyStatBadge('FTP', '${rider.physiology.ftpWatts}W', AppColors.cyanAccent),
                    const SizedBox(width: 6),
                    _buildRiderKeyStatBadge('W/kg', rider.physiology.wattsPerKg.toStringAsFixed(1), AppColors.emeraldGreen),
                    const SizedBox(width: 6),
                    _buildRiderKeyStatBadge('Sprint', '${rider.powerProfile.watts5s}W', AppColors.amberWarning),
                    const SizedBox(width: 14),

                    // Pensja
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatEur(rider.contract.annualSalaryEur),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emeraldGreen,
                          ),
                        ),
                        const Text('/rok', style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Przycisk Dodaj / Usuń
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (isDrafted) {
                            _draftedRiderIds.remove(rider.id);
                          } else {
                            if (_draftedRiderIds.length < 16) {
                              _draftedRiderIds.add(rider.id);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.amberWarning,
                                  content: Text('Maksymalna wielkość składu w drafcie to 16 kolarzy!'),
                                ),
                              );
                            }
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDrafted ? AppColors.crimsonAlert : AppColors.goldAccent,
                        foregroundColor: isDrafted ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: Text(
                        isDrafted ? 'USUŃ' : 'DODAJ',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // KROK 6: PODSUMOWANIE I INAUGURACJA
  Widget _buildStep6Summary() {
    final teamName = _customTeamNameController.text.trim().isNotEmpty
        ? _customTeamNameController.text.trim()
        : 'Team Pro Cycling';
    final tla = _customTeamTlaController.text.trim().toUpperCase();
    final cleanTla = tla.isNotEmpty ? tla : 'ORT';

    final draftedRiders = _draftPool.where((r) => _draftedRiderIds.contains(r.id)).toList();
    draftedRiders.sort((a, b) => b.overallRating.compareTo(a.overallRating));

    final avgOvr = draftedRiders.isNotEmpty
        ? (draftedRiders.map((r) => r.overallRating).reduce((a, b) => a + b) / draftedRiders.length).round()
        : 70;
    final avgAge = draftedRiders.isNotEmpty
        ? (draftedRiders.map((r) => r.age).reduce((a, b) => a + b) / draftedRiders.length).toStringAsFixed(1)
        : '25.0';

    final selectedBrand = _availableBrands.firstWhere(
      (b) => b.id == _selectedBrandId,
      orElse: () => _availableBrands.first,
    );

    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 880),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nagłówek
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _parseHex(_primaryColorHex, AppColors.goldAccent),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        _getCountryFlag(_selectedCountryIso),
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teamName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$cleanTla  •  ${_selectedCustomDivision.label}  •  Dyrektor Sportowy: ${_managerNameController.text.trim()}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.goldAccent),
                    ),
                    child: Text(
                      'ZAPIS W SLOCIE $_selectedSlot',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: AppTheme.borderColor),

              // 4 Sekcje Podsumowania: Barwy, Sponsor, Sprzęt, Skład
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Koszulka i Barwy
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BARWY I KOSZULKA', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildColorCircle(_primaryColorHex),
                              const SizedBox(width: 6),
                              _buildColorCircle(_secondaryColorHex),
                              const SizedBox(width: 6),
                              _buildColorCircle(_accentColorHex),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedJerseyPattern.label,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Sponsor
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SPONSOR TYTULARNY', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            _sponsorNameController.text.trim().isNotEmpty ? _sponsorNameController.text.trim() : 'Orlen Energia',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Wypłata: ${_formatEur((_selectedBudgetTier.initialCashEur * 0.75).round())}/rok',
                            style: const TextStyle(fontSize: 10.5, color: AppColors.emeraldGreen),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Rower
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DOSTAWCA ROWERÓW', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            selectedBrand.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(selectedBrand.prestige * 18) + 30} ram na sezon',
                            style: const TextStyle(fontSize: 10.5, color: AppColors.cyanAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Kadra
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('STATYSTYKI KADRY', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            '${draftedRiders.length} kolarzy  •  Śr. OVR: $avgOvr',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Średni wiek: $avgAge lat',
                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Lista wybranych kolarzy w drafcie
              const Text(
                'ZAKONTRAKTOWANA KADRA ZESPOŁU NA SEZON 2026',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: AppColors.goldAccent,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: draftedRiders.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderColor),
                  itemBuilder: (context, index) {
                    final rider = draftedRiders[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      child: Row(
                        children: [
                          RiderAvatarWidget.fromRider(rider: rider, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              rider.fullName,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            rider.specialization.displayName,
                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${rider.overallRating} OVR',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.goldAccent),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _formatEur(rider.contract.annualSalaryEur),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.emeraldGreen),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Przycisk Oficjalnego Startu Sezonu
              ElevatedButton.icon(
                onPressed: _isCreatingCareer ? null : _launchCustomTeamCareer,
                icon: _isCreatingCareer
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.rocket_launch),
                label: Text(
                  _isCreatingCareer
                      ? 'INICJALIZACJA SEZONU I TWORZENIE ZAPISU...'
                      : 'ZAINAUGURUJ SEZON I PRZEJDŹ DO CENTRALI (HQ)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emeraldGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorCircle(String hex) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: _parseHex(hex, Colors.white),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }

  // Dolny pasek nawigacji kreatora
  Widget _buildWizardBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: _customStepIndex > 0 ? () => setState(() => _customStepIndex--) : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text('WSTECZ'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              side: const BorderSide(color: AppTheme.borderColor),
            ),
          ),
          Text(
            'Krok ${_customStepIndex + 1} z 6',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (_customStepIndex < 5) {
                setState(() => _customStepIndex++);
              } else {
                _launchCustomTeamCareer();
              }
            },
            icon: Icon(_customStepIndex == 5 ? Icons.rocket_launch : Icons.arrow_forward),
            label: Text(_customStepIndex == 5 ? 'ZAINAUGURUJ SEZON' : 'DALEJ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _customStepIndex == 5 ? AppColors.emeraldGreen : AppColors.goldAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter rysujący estetyczną koszulkę kolarską (przód / plecy z numerem startowym)
class TeamJerseyPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final JerseyPattern pattern;
  final bool isBackView;
  final String teamName;
  final String teamTla;

  TeamJerseyPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.pattern,
    required this.isBackView,
    required this.teamName,
    required this.teamTla,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Zarys sylwetki koszulki (Torso, Ramiona, Rękawy)
    final jerseyPath = Path();

    // Kołnierzyk - wcięcie
    jerseyPath.moveTo(w * 0.40, h * 0.10);
    jerseyPath.quadraticBezierTo(w * 0.50, isBackView ? h * 0.11 : h * 0.16, w * 0.60, h * 0.10);

    // Prawe ramię do końca prawego rękawa
    jerseyPath.lineTo(w * 0.82, h * 0.20);
    jerseyPath.lineTo(w * 0.95, h * 0.38); // mankiet prawy zewnętrzny
    jerseyPath.lineTo(w * 0.83, h * 0.44); // mankiet prawy wewnętrzny
    jerseyPath.lineTo(w * 0.74, h * 0.35); // pacha prawa

    // Prawy bok i talia do dolnego ściągacza
    jerseyPath.quadraticBezierTo(w * 0.73, h * 0.60, w * 0.72, h * 0.86);

    // Dolny ściągacz koszulki (elastyczny łuk)
    jerseyPath.quadraticBezierTo(w * 0.50, h * 0.90, w * 0.28, h * 0.86);

    // Lewy bok i talia
    jerseyPath.quadraticBezierTo(w * 0.27, h * 0.60, w * 0.26, h * 0.35); // pacha lewa

    // Lewy rękaw
    jerseyPath.lineTo(w * 0.17, h * 0.44); // mankiet lewy wewnętrzny
    jerseyPath.lineTo(w * 0.05, h * 0.38); // mankiet lewy zewnętrzny
    jerseyPath.lineTo(w * 0.18, h * 0.20); // lewe ramię
    jerseyPath.close();

    // 2. Rysujemy cień pod koszulką
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.save();
    canvas.translate(0, 6);
    canvas.drawPath(jerseyPath, shadowPaint);
    canvas.restore();

    // 3. Kolor bazowy koszulki (Primary)
    final basePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(jerseyPath, basePaint);

    // 4. Nakładamy wybrany wzór geometryczny (przycięty do konturu koszulki)
    canvas.save();
    canvas.clipPath(jerseyPath);

    final patternPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;
    final accentLinePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    switch (pattern) {
      case JerseyPattern.chestStripe:
        // Szeroki pas przez klatkę piersiową
        final stripeRect = Rect.fromLTRB(0, h * 0.32, w, h * 0.52);
        canvas.drawRect(stripeRect, patternPaint);
        canvas.drawLine(Offset(0, h * 0.32), Offset(w, h * 0.32), accentLinePaint);
        canvas.drawLine(Offset(0, h * 0.52), Offset(w, h * 0.52), accentLinePaint);
        break;

      case JerseyPattern.verticalStripes:
        // Pionowe pasy wyścigowe
        final stripeW = w * 0.09;
        canvas.drawRect(Rect.fromLTWH(w * 0.32, 0, stripeW, h), patternPaint);
        canvas.drawRect(Rect.fromLTWH(w * 0.59, 0, stripeW, h), patternPaint);
        // Akcentowe linie
        canvas.drawRect(Rect.fromLTWH(w * 0.46, 0, w * 0.08, h), Paint()..color = accentColor);
        break;

      case JerseyPattern.diagonal:
        // Dynamiczny pas skośny z lewego ramienia na prawy bok
        final diagPath = Path()
          ..moveTo(w * 0.10, 0)
          ..lineTo(w * 0.38, 0)
          ..lineTo(w * 0.95, h * 0.90)
          ..lineTo(w * 0.67, h * 0.90)
          ..close();
        canvas.drawPath(diagPath, patternPaint);

        final diagAccent = Path()
          ..moveTo(w * 0.38, 0)
          ..lineTo(w * 0.43, 0)
          ..lineTo(w * 1.0, h * 0.90)
          ..lineTo(w * 0.95, h * 0.90)
          ..close();
        canvas.drawPath(diagAccent, Paint()..color = accentColor);
        break;

      case JerseyPattern.gradient:
        // Płynny gradient pionowy
        final gradPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [secondaryColor, primaryColor],
          ).createShader(Rect.fromLTWH(0, 0, w, h));
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), gradPaint);

        // Subtelny akcent na dole
        canvas.drawLine(Offset(0, h * 0.82), Offset(w, h * 0.82), accentLinePaint);
        break;

      case JerseyPattern.splitHalves:
        // Podział pół na pół
        canvas.drawRect(Rect.fromLTWH(w * 0.50, 0, w * 0.50, h), patternPaint);
        canvas.drawLine(Offset(w * 0.50, 0), Offset(w * 0.50, h), accentLinePaint);
        break;

      case JerseyPattern.minimalist:
        // Czysty blok z aerodynamicznymi panelami bocznymi
        final leftFlank = Path()
          ..moveTo(0, h * 0.20)
          ..lineTo(w * 0.28, h * 0.35)
          ..lineTo(w * 0.28, h * 0.86)
          ..lineTo(0, h * 0.86)
          ..close();
        canvas.drawPath(leftFlank, patternPaint);

        final rightFlank = Path()
          ..moveTo(w, h * 0.20)
          ..lineTo(w * 0.72, h * 0.35)
          ..lineTo(w * 0.72, h * 0.86)
          ..lineTo(w, h * 0.86)
          ..close();
        canvas.drawPath(rightFlank, patternPaint);
        break;
    }

    // 5. Mankiety rękawów (Sleeve cuffs) w kolorze akcentu
    final cuffPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    // Lewy mankiet
    canvas.drawCircle(Offset(w * 0.11, h * 0.41), 12, cuffPaint);
    // Prawy mankiet
    canvas.drawCircle(Offset(w * 0.89, h * 0.41), 12, cuffPaint);

    // 6. Cieniowanie aerodynamiczne tkaniny (3D Shader highlight)
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.black.withValues(alpha: 0.18),
          Colors.transparent,
          Colors.white.withValues(alpha: 0.14),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.18),
        ],
        stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), highlightPaint);

    canvas.restore();

    // 7. Kontur zewnętrzny koszulki
    final outlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(jerseyPath, outlinePaint);

    // 8. Kołnierzyk (Collar band)
    final collarPath = Path()
      ..moveTo(w * 0.40, h * 0.10)
      ..quadraticBezierTo(w * 0.50, isBackView ? h * 0.11 : h * 0.16, w * 0.60, h * 0.10)
      ..lineTo(w * 0.58, h * 0.08)
      ..quadraticBezierTo(w * 0.50, isBackView ? h * 0.09 : h * 0.14, w * 0.42, h * 0.08)
      ..close();
    canvas.drawPath(collarPath, Paint()..color = secondaryColor);
    canvas.drawPath(collarPath, Paint()..color = accentColor..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // 9. Widok Pleców (Back view: 3 kieszenie i numer startowy #1)
    if (isBackView) {
      // 3 kieszonki kolarskie z tyłu (lewa, środkowa, prawa)
      final pocketTopY = h * 0.65;
      final pocketBottomY = h * 0.84;
      final pocketWidth = w * 0.14;

      final pocketPaint = Paint()
        ..color = secondaryColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      final pocketBorder = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      // Lewa kieszonka
      final p1 = Rect.fromLTRB(w * 0.28, pocketTopY, w * 0.28 + pocketWidth, pocketBottomY);
      canvas.drawRRect(RRect.fromRectAndRadius(p1, const Radius.circular(4)), pocketPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(p1, const Radius.circular(4)), pocketBorder);

      // Środkowa kieszonka
      final p2 = Rect.fromLTRB(w * 0.43, pocketTopY, w * 0.57, pocketBottomY);
      canvas.drawRRect(RRect.fromRectAndRadius(p2, const Radius.circular(4)), pocketPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(p2, const Radius.circular(4)), pocketBorder);

      // Prawa kieszonka
      final p3 = Rect.fromLTRB(w * 0.72 - pocketWidth, pocketTopY, w * 0.72, pocketBottomY);
      canvas.drawRRect(RRect.fromRectAndRadius(p3, const Radius.circular(4)), pocketPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(p3, const Radius.circular(4)), pocketBorder);

      // Numer startowy #1 (prostokąt z numerem nad kieszeniami)
      final bibRect = Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.50),
        width: w * 0.22,
        height: h * 0.16,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bibRect, const Radius.circular(4)),
        Paint()..color = Colors.white,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bibRect, const Radius.circular(4)),
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      final bibPainter = TextPainter(
        text: const TextSpan(
          text: '1',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      bibPainter.paint(
        canvas,
        Offset(w * 0.50 - bibPainter.width / 2, h * 0.50 - bibPainter.height / 2),
      );

      // Nazwa zespołu na łopatkach
      final textSpan = TextSpan(
        text: teamTla,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(w * 0.50 - tp.width / 2, h * 0.24));
    } else {
      // 10. Widok Przodu (Front view: Suwak i Logo zespołu na klatce piersiowej)
      // Suwak (Zipper)
      final zipperPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(w * 0.50, h * 0.16), Offset(w * 0.50, h * 0.88), zipperPaint);

      // Uchwyt suwaka
      canvas.drawCircle(Offset(w * 0.50, h * 0.18), 2.5, Paint()..color = Colors.white);

      // Napis nazwy zespołu na klatce piersiowej
      final textSpan = TextSpan(
        text: teamTla,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 3.0,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 4, offset: const Offset(1, 1)),
          ],
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(w * 0.50 - tp.width / 2, h * 0.40));
    }
  }

  @override
  bool shouldRepaint(covariant TeamJerseyPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.pattern != pattern ||
        oldDelegate.isBackView != isBackView ||
        oldDelegate.teamName != teamName ||
        oldDelegate.teamTla != teamTla;
  }
}
