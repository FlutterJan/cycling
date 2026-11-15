import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/career/career_save.dart';
import '../../models/rider/rider.dart';
import '../../models/settings/game_settings.dart';
import '../../models/team/cycling_team.dart';
import '../../services/database/custom_mod_importer_service.dart';
import '../../state/career_controller.dart';
import '../../state/game_settings_notifier.dart';
import '../widgets/rider_avatar_painter.dart';

/// Ekran Ustawień, Grafiki 3D oraz Modyfikacji i Edytora Bazy Danych (In-Game Database Editor).
class SettingsAndModScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const SettingsAndModScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<SettingsAndModScreen> createState() => _SettingsAndModScreenState();
}

class _SettingsAndModScreenState extends ConsumerState<SettingsAndModScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Kontrolery dla zakładki Modyfikacji JSON
  final TextEditingController _jsonModController = TextEditingController();
  ModValidationResult? _validationReport;
  bool _isValidating = false;

  // Kontrolery dla Edytora Kolarzy
  final TextEditingController _riderSearchController = TextEditingController();
  String? _selectedRiderTeamFilter;
  RiderSpecialization? _selectedSpecializationFilter;
  Rider? _selectedEditingRider;

  // Kontrolery formularza kolarza
  final TextEditingController _editFirstNameController = TextEditingController();
  final TextEditingController _editLastNameController = TextEditingController();
  final TextEditingController _editCountryIsoController = TextEditingController();
  final TextEditingController _editAgeController = TextEditingController();
  final TextEditingController _editWeightController = TextEditingController();
  final TextEditingController _editHeightController = TextEditingController();
  final TextEditingController _editFtpController = TextEditingController();
  final TextEditingController _editWPrimeController = TextEditingController();
  final TextEditingController _editMaxHrController = TextEditingController();
  final TextEditingController _editSprintWattsController = TextEditingController();
  double _editCobbles = 65;
  double _editDescending = 70;
  double _editHandling = 72;
  double _editAero = 70;
  double _editVo2Max = 74;

  // Kontrolery dla Edytora Drużyn
  final TextEditingController _teamSearchController = TextEditingController();
  TeamDivision? _selectedDivisionFilter;
  CyclingTeam? _selectedEditingTeam;

  // Kontrolery formularza drużyny
  final TextEditingController _editTeamNameController = TextEditingController();
  final TextEditingController _editTeamCountryController = TextEditingController();
  final TextEditingController _editTeamCashController = TextEditingController();
  final TextEditingController _editPrimaryColorController = TextEditingController();
  final TextEditingController _editSecondaryColorController = TextEditingController();
  final TextEditingController _editAccentColorController = TextEditingController();
  String _selectedBrandName = 'Colnago';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _jsonModController.dispose();
    _riderSearchController.dispose();
    _teamSearchController.dispose();

    _editFirstNameController.dispose();
    _editLastNameController.dispose();
    _editCountryIsoController.dispose();
    _editAgeController.dispose();
    _editWeightController.dispose();
    _editHeightController.dispose();
    _editFtpController.dispose();
    _editWPrimeController.dispose();
    _editMaxHrController.dispose();
    _editSprintWattsController.dispose();

    _editTeamNameController.dispose();
    _editTeamCountryController.dispose();
    _editTeamCashController.dispose();
    _editPrimaryColorController.dispose();
    _editSecondaryColorController.dispose();
    _editAccentColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameSettings = ref.watch(gameSettingsProvider);
    final careerUi = ref.watch(careerControllerProvider);
    final careerSave = careerUi.save;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.settings_suggest_rounded, color: AppColors.primaryGold, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'USTAWIENIA & BAZA DANYCH (MODY)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  careerSave != null
                      ? 'Kariera: ${careerSave.saveName} • Sezon ${careerSave.currentSeasonYear}'
                      : 'Tryb Główny Gry',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGold,
          indicatorWeight: 3,
          labelColor: AppColors.primaryGold,
          unselectedLabelColor: AppColors.textMuted,
          isScrollable: true,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(icon: Icon(Icons.videogame_asset_outlined), text: 'Grafika 3D i Wydajność'),
            Tab(icon: Icon(Icons.public_rounded), text: 'Społeczność & Mody JSON'),
            Tab(icon: Icon(Icons.badge_outlined), text: 'Edytor Kolarzy'),
            Tab(icon: Icon(Icons.shield_outlined), text: 'Edytor Drużyn i Barw'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Ustawienia Grafiki 3D i Wydajności
          _buildTab1GraphicsSettings(gameSettings),

          // 2. Modyfikacje JSON i Społeczność
          _buildTab2CommunityMods(careerSave),

          // 3. Edytor Kolarzy
          _buildTab3RiderEditor(careerSave),

          // 4. Edytor Drużyn
          _buildTab4TeamEditor(careerSave),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. ZAKŁADKA 1: GRAFIKA 3D, CIENIE, KIBICE, FPS, OSZCZĘDZANIE BATERII
  // ===========================================================================

  Widget _buildTab1GraphicsSettings(GameSettings settings) {
    final notifier = ref.read(gameSettingsProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pasek profilu i obciążenia sprzętowego
          _buildHardwareStatusBanner(settings),
          const SizedBox(height: 24),

          // Profile Szybkiego Wyboru (One-click presets)
          const Text(
            'PROFIL WYDAJNOŚCIOWY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(height: 10),
          _buildPresetSelector(settings, notifier),
          const SizedBox(height: 24),

          // Główny przełącznik oszczędzania energii
          _buildBatterySaverCard(settings, notifier),
          const SizedBox(height: 20),

          // Karta Jakości Cieni
          _buildShadowQualityCard(settings, notifier),
          const SizedBox(height: 20),

          // Karta Gęstości Kibiców
          _buildCrowdDensityCard(settings, notifier),
          const SizedBox(height: 20),

          // Karta Limitu Klatek (FPS)
          _buildTargetFpsCard(settings, notifier),
          const SizedBox(height: 20),

          // Karta Efektów Post-Processingu i Środowiska
          _buildAdvancedEffectsCard(settings, notifier),
          const SizedBox(height: 20),

          // Karta Dźwięku i Audio
          _buildAudioSettingsCard(settings, notifier),
          const SizedBox(height: 30),

          // Przycisk przywrócenia domyślnych
          Center(
            child: TextButton.icon(
              onPressed: () {
                notifier.resetToDefaults();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Przywrócono domyślne ustawienia graficzne (Zbalansowane 60 FPS).')),
                );
              },
              icon: const Icon(Icons.restore_rounded, color: AppColors.textMuted),
              label: const Text('Przywróć domyślne parametry fabryczne', style: TextStyle(color: AppColors.textMuted)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareStatusBanner(GameSettings settings) {
    final score = settings.estimatedLoadScore;
    Color statusColor;
    IconData statusIcon;

    if (score <= 1.8) {
      statusColor = AppColors.emeraldGreen;
      statusIcon = Icons.battery_charging_full_rounded;
    } else if (score <= 3.0) {
      statusColor = AppColors.accentBlue;
      statusIcon = Icons.speed_rounded;
    } else if (score <= 4.0) {
      statusColor = AppColors.amberWarning;
      statusIcon = Icons.bolt_rounded;
    } else {
      statusColor = AppColors.crimsonAlert;
      statusIcon = Icons.local_fire_department_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SZACUNKOWY PROFIL EKSPLOATACJI',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Indeks: ${score.toStringAsFixed(1)} / 5.0',
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  settings.batteryDrainLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (score / 5.0).clamp(0.0, 1.0),
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelector(GameSettings settings, GameSettingsNotifier notifier) {
    final current = settings.currentPreset;

    return Row(
      children: [
        _buildPresetTile(
          preset: GraphicsPreset.batterySaver,
          title: 'Eco Bateria',
          subtitle: '30 FPS • Smartfon',
          icon: Icons.energy_savings_leaf_rounded,
          isSelected: current == GraphicsPreset.batterySaver,
          color: AppColors.emeraldGreen,
          onTap: () => notifier.applyPreset(GraphicsPreset.batterySaver),
        ),
        const SizedBox(width: 10),
        _buildPresetTile(
          preset: GraphicsPreset.balanced,
          title: 'Zrównoważony',
          subtitle: '60 FPS • Standard',
          icon: Icons.tune_rounded,
          isSelected: current == GraphicsPreset.balanced,
          color: AppColors.accentBlue,
          onTap: () => notifier.applyPreset(GraphicsPreset.balanced),
        ),
        const SizedBox(width: 10),
        _buildPresetTile(
          preset: GraphicsPreset.highQuality,
          title: 'Wysoka Jakość',
          subtitle: '60 FPS • Tablet/Mac',
          icon: Icons.hd_rounded,
          isSelected: current == GraphicsPreset.highQuality,
          color: AppColors.primaryGold,
          onTap: () => notifier.applyPreset(GraphicsPreset.highQuality),
        ),
        const SizedBox(width: 10),
        _buildPresetTile(
          preset: GraphicsPreset.ultraMacPc,
          title: 'Ultra PC / Mac',
          subtitle: '120 FPS • Max detale',
          icon: Icons.desktop_windows_rounded,
          isSelected: current == GraphicsPreset.ultraMacPc,
          color: const Color(0xFFC084FC),
          onTap: () => notifier.applyPreset(GraphicsPreset.ultraMacPc),
        ),
      ],
    );
  }

  Widget _buildPresetTile({
    required GraphicsPreset preset,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.cardBorder,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : AppColors.textMuted, size: 22),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatterySaverCard(GameSettings settings, GameSettingsNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.battery_saver_rounded, color: AppColors.emeraldGreen, size: 26),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tryb Oszczędzania Baterii na Telefonie',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                SizedBox(height: 2),
                Text(
                  'Blokuje limit do 30 FPS, wyłącza dynamiczne cienie i upraszcza kibiców, wydłużając czas pracy na akumulatorze.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: settings.batterySaverMode,
            onChanged: (val) => notifier.setBatterySaverMode(val),
            activeThumbColor: AppColors.emeraldGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildShadowQualityCard(GameSettings settings, GameSettingsNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wb_sunny_outlined, color: AppColors.primaryGold, size: 18),
              SizedBox(width: 8),
              Text(
                'JAKOŚĆ CIENI (SHADOW MAPS)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: ShadowQuality.values.map((q) {
              final isSelected = settings.shadowQuality == q;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => notifier.setShadowQuality(q),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryGold.withValues(alpha: 0.15) : AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryGold : Colors.white10,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            q.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? AppColors.primaryGold : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            settings.shadowQuality.description,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCrowdDensityCard(GameSettings settings, GameSettingsNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.groups_rounded, color: AppColors.accentBlue, size: 18),
              SizedBox(width: 8),
              Text(
                'GĘSTOŚĆ KIBICÓW PRZY TRASIE (CROWD DENSITY)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: CrowdDensity.values.map((c) {
              final isSelected = settings.crowdDensity == c;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => notifier.setCrowdDensity(c),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accentBlue.withValues(alpha: 0.15) : AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.accentBlue : Colors.white10,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            c.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            settings.crowdDensity.description,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetFpsCard(GameSettings settings, GameSettingsNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.motion_photos_on_rounded, color: Color(0xFFC084FC), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'LIMIT KLATEK NA SEKUNDĘ (TARGET FPS)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Licznik FPS', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(width: 6),
                  Switch(
                    value: settings.showFpsCounter,
                    onChanged: (val) => notifier.setShowFpsCounter(val),
                    activeThumbColor: const Color(0xFFC084FC),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: TargetFrameRate.values.map((fps) {
              final isSelected = settings.targetFrameRate == fps;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => notifier.setTargetFrameRate(fps),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFC084FC).withValues(alpha: 0.15) : AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFC084FC) : Colors.white10,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            fps.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? const Color(0xFFC084FC) : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            settings.targetFrameRate.description,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedEffectsCard(GameSettings settings, GameSettingsNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EFEKTY POST-PROCESSINGU & SYMULACJA ŚRODOWISKA',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Efekty cząsteczkowe (Deszcz, mgła, spray z kół)', style: TextStyle(fontSize: 13)),
            subtitle: const Text('Dynamiczne krople na kamerze i rozbryzg wody na mokrym asfalcie', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            value: settings.particleEffects,
            onChanged: (val) => notifier.setParticleEffects(val),
            activeThumbColor: AppColors.primaryGold,
          ),
          const Divider(color: Colors.white10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Rozmycie ruchu (Motion Blur przy >60 km/h)', style: TextStyle(fontSize: 13)),
            subtitle: const Text('Kinowy efekt prędkości podczas sprintów peletonu i zjazdów alpejskich', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            value: settings.motionBlur,
            onChanged: (val) => notifier.setMotionBlur(val),
            activeThumbColor: AppColors.primaryGold,
          ),
          const Divider(color: Colors.white10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Wysoki poziom detali rowerów (Bike LOD)', style: TextStyle(fontSize: 13)),
            subtitle: const Text('Precyzyjne profile stożków kół, geometria ram aero i zarys łańcucha', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            value: settings.bikeDetailLOD,
            onChanged: (val) => notifier.setBikeDetailLOD(val),
            activeThumbColor: AppColors.primaryGold,
          ),
        ],
      ),
    );
  }

  Widget _buildAudioSettingsCard(GameSettings settings, GameSettingsNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DŹWIĘK I KOMENTARZ RADIOWY',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.volume_up_rounded, color: AppColors.primaryGold, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: settings.soundVolume,
                  min: 0.0,
                  max: 1.0,
                  activeColor: AppColors.primaryGold,
                  onChanged: (val) => notifier.setSoundVolume(val),
                ),
              ),
              Text(
                '${(settings.soundVolume * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryGold),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Komunikaty radiowe dyrektora sportowego', style: TextStyle(fontSize: 13)),
            value: settings.commentaryAudio,
            onChanged: (val) => notifier.setCommentaryAudio(val),
            activeThumbColor: AppColors.primaryGold,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. ZAKŁADKA 2: SPOŁECZNOŚĆ & MODYFIKACJE JSON (REAL NAMES & BRANDS)
  // ===========================================================================

  Widget _buildTab2CommunityMods(CareerSave? save) {
    final careerController = ref.read(careerControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Karta informacyjna o modach
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.dataset_linked_rounded, color: AppColors.primaryGold, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Społeczność & Mody Bazy Danych (Real Names & Brands)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Zastąp generowane proceduralnie fikcyjne nazwiska i drużyny oficjalnymi danymi WorldTour 2026 '
                        '(Tadej Pogačar, Jonas Vingegaard, UAE Emirates, Visma-Lease a Bike, Colnago, Cervélo). '
                        'Możesz wczytać gotowy pakiet lub wkleić własną strukturę JSON.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Szybkie akcje w jednym rzędzie
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () => _applyOfficialRealNamePack(careerController),
                icon: const Icon(Icons.verified_rounded, size: 18),
                label: const Text('Załaduj Oficjalny Pakiet 2026 WorldTour'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _exportCurrentDatabaseAsJson(careerController),
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('Eksportuj Bazę do JSON'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentBlue,
                  side: const BorderSide(color: AppColors.accentBlue),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showSampleModTemplate(careerController),
                icon: const Icon(Icons.code_rounded, size: 18),
                label: const Text('Wzór Struktury JSON'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.cardBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Pole tekstowe do wprowadzania własnego pliku / skryptu JSON
          const Text(
            'WKLEJ LUB EDYTUJ KOD PAKIETU MODYFIKACJI (JSON)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111318),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF161920),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edytor JSON (Format: CustomModPackage)',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textMuted),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.paste_rounded, size: 16, color: AppColors.primaryGold),
                            tooltip: 'Wklej ze schowka',
                            onPressed: () async {
                              final data = await Clipboard.getData('text/plain');
                              if (data?.text != null) {
                                setState(() {
                                  _jsonModController.text = data!.text!;
                                });
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                            tooltip: 'Wyczyść',
                            onPressed: () => setState(() {
                              _jsonModController.clear();
                              _validationReport = null;
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TextField(
                  controller: _jsonModController,
                  maxLines: 12,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: '{\n  "metadata": {\n    "name": "Mój Real Name Pack 2026",\n    "version": "1.0"\n  },\n  "teams": [...],\n  "riders": [...]\n}',
                    hintStyle: TextStyle(color: Colors.white24, fontFamily: 'monospace'),
                    contentPadding: EdgeInsets.all(14),
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Przyciski walidacji i aplikacji
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isValidating ? null : () => _validateJsonMod(careerController),
                icon: _isValidating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Sprawdź Poprawność JSON'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _validationReport?.isValid == true
                    ? () => _applyCustomJsonMod(careerController)
                    : null,
                icon: const Icon(Icons.download_done_rounded, size: 18),
                label: const Text('Zastosuj do Aktywnej Gry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emeraldGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Wynik walidacji raportu
          if (_validationReport != null) _buildValidationReportCard(_validationReport!),
        ],
      ),
    );
  }

  Widget _buildValidationReportCard(ModValidationResult report) {
    final isValid = report.isValid;
    final color = isValid ? AppColors.emeraldGreen : AppColors.crimsonAlert;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isValid ? Icons.check_circle : Icons.error_outline, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                isValid ? 'STRUKTURA JSON JEST PRAWIDŁOWA!' : 'WYKRYTO BŁĘDY W STRUKTURZE JSON',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildBadge('Kolarze: ${report.totalRidersInMod}', AppColors.accentBlue),
              const SizedBox(width: 8),
              _buildBadge('Drużyny: ${report.totalTeamsInMod}', AppColors.primaryGold),
              const SizedBox(width: 8),
              _buildBadge('Marki: ${report.totalBikesInMod}', const Color(0xFFC084FC)),
              const SizedBox(width: 8),
              _buildBadge('Wyścigi: ${report.totalRacesInMod}', AppColors.emeraldGreen),
            ],
          ),
          if (report.errors.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Błędy krytyczne:', style: TextStyle(color: AppColors.crimsonAlert, fontWeight: FontWeight.w700)),
            ...report.errors.map((e) => Text('• ${e.message}', style: const TextStyle(fontSize: 11, color: AppColors.crimsonAlert))),
          ],
          if (report.warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Ostrzeżenia:', style: TextStyle(color: AppColors.amberWarning, fontWeight: FontWeight.w700)),
            ...report.warnings.map((w) => Text('• ${w.message}', style: const TextStyle(fontSize: 11, color: AppColors.amberWarning))),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  void _validateJsonMod(CareerController controller) {
    final text = _jsonModController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wklej najpierw treść kodu JSON do edytora.')),
      );
      return;
    }

    setState(() => _isValidating = true);
    final report = controller.validateModJson(text);
    setState(() {
      _validationReport = report;
      _isValidating = false;
    });
  }

  Future<void> _applyCustomJsonMod(CareerController controller) async {
    final text = _jsonModController.text.trim();
    try {
      final result = await controller.applyModFromJson(text);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.emeraldGreen),
              SizedBox(width: 10),
              Text('Mod Zastosowany Pomyślnie!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Zaktualizowano kolarzy: ${result.ridersRenamed}'),
              Text('Zaktualizowano drużyn: ${result.teamsUpdated}'),
              Text('Zaktualizowano marek: ${result.bikesUpdated}'),
              Text('Zaktualizowano wyścigów: ${result.racesRenamed}'),
              const SizedBox(height: 10),
              Text(result.summary, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold, foregroundColor: Colors.black),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.crimsonAlert, content: Text('Błąd modyfikacji: $e')),
      );
    }
  }

  Future<void> _applyOfficialRealNamePack(CareerController controller) async {
    try {
      final result = await controller.applySampleRealNamePack();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.emeraldGreen,
          content: Text(
            'Załadowano oficjalny zestaw 2026! Zaktualizowano ${result.ridersRenamed} kolarzy i ${result.teamsUpdated} zespołów.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.crimsonAlert, content: Text('Błąd: $e')),
      );
    }
  }

  void _exportCurrentDatabaseAsJson(CareerController controller) {
    try {
      final jsonExport = controller.exportCurrentWorldAsModJson();
      Clipboard.setData(ClipboardData(text: jsonExport));
      setState(() {
        _jsonModController.text = jsonExport;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.accentBlue,
          content: Text('Wyeksportowano pełną bazę danych kolarzy i zespołów. Skopiowano JSON do schowka!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Brak aktywnego zapisu kariery do wyeksportowania: $e')),
      );
    }
  }

  void _showSampleModTemplate(CareerController controller) {
    final sample = controller.generateSampleRealNamePackJson();
    setState(() {
      _jsonModController.text = sample;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Załadowano oficjalny szablon pakietu do edytora.')),
    );
  }

  // ===========================================================================
  // 3. ZAKŁADKA 3: WBUDOWANY EDYTOR KOLARZY (IN-GAME RIDER EDITOR)
  // ===========================================================================

  Widget _buildTab3RiderEditor(CareerSave? save) {
    if (save == null) {
      return const Center(
        child: Text('Załaduj lub rozpocznij karierę, aby edytować kolarzy w grze.',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }

    final allRiders = save.riders;
    final filteredRiders = allRiders.where((r) {
      final query = _riderSearchController.text.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          r.fullName.toLowerCase().contains(query) ||
          r.nationalityIso.toLowerCase().contains(query);
      final matchesTeam = _selectedRiderTeamFilter == null || r.teamId == _selectedRiderTeamFilter;
      final matchesSpec = _selectedSpecializationFilter == null || r.specialization == _selectedSpecializationFilter;
      return matchesQuery && matchesTeam && matchesSpec;
    }).toList();

    return Row(
      children: [
        // Lewa kolumna: Lista kolarzy z filtrami
        Expanded(
          flex: 4,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Column(
              children: [
                // Filtry i wyszukiwarka
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _riderSearchController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Szukaj kolarza (np. Pogačar, Evenepoel)...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.primaryGold),
                          filled: true,
                          fillColor: AppColors.cardDark,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              initialValue: _selectedRiderTeamFilter,
                              dropdownColor: AppColors.cardDark,
                              style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.cardDark,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Wszystkie Drużyny')),
                                ...save.teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name, overflow: TextOverflow.ellipsis))),
                              ],
                              onChanged: (val) => setState(() => _selectedRiderTeamFilter = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<RiderSpecialization?>(
                              initialValue: _selectedSpecializationFilter,
                              dropdownColor: AppColors.cardDark,
                              style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.cardDark,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Wszystkie Role')),
                                ...RiderSpecialization.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName, overflow: TextOverflow.ellipsis))),
                              ],
                              onChanged: (val) => setState(() => _selectedSpecializationFilter = val),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.cardBorder),

                // Lista przefiltrowanych kolarzy
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredRiders.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
                    itemBuilder: (ctx, index) {
                      final rider = filteredRiders[index];
                      final isSelected = _selectedEditingRider?.id == rider.id;
                      final team = save.getTeamById(rider.teamId);

                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedTileColor: AppColors.primaryGold.withValues(alpha: 0.12),
                        leading: RiderAvatarWidget.fromRider(
                          rider: rider,
                          team: team,
                          size: 34,
                        ),
                        title: Row(
                          children: [
                            Text(
                              rider.fullName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? AppColors.primaryGold : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                rider.nationalityIso,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${team?.name ?? "Brak teamu"} • ${rider.specialization.displayName}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${rider.overallRating}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryGold,
                              ),
                            ),
                            Text(
                              '${rider.physiology.ftpWatts}W • ${rider.physiology.wattsPerKg.toStringAsFixed(1)}W/kg',
                              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        onTap: () => _selectRiderForEditing(rider),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Prawa kolumna: Formularz edycji wybranego kolarza
        Expanded(
          flex: 6,
          child: _selectedEditingRider == null
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, color: AppColors.primaryGold, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Wybierz kolarza z listy po lewej stronie, aby edytować jego statystyki.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : _buildRiderEditForm(save),
        ),
      ],
    );
  }

  void _selectRiderForEditing(Rider rider) {
    setState(() {
      _selectedEditingRider = rider;
      _editFirstNameController.text = rider.firstName;
      _editLastNameController.text = rider.lastName;
      _editCountryIsoController.text = rider.nationalityIso;
      _editAgeController.text = rider.age.toString();
      _editWeightController.text = rider.physiology.weightKg.toStringAsFixed(1);
      _editHeightController.text = rider.physiology.heightCm.toStringAsFixed(0);
      _editFtpController.text = rider.physiology.ftpWatts.toString();
      _editWPrimeController.text = rider.physiology.wPrimeJoules.toString();
      _editMaxHrController.text = rider.physiology.maxHr.toString();
      _editSprintWattsController.text = rider.powerProfile.watts5s.toString();
      _editCobbles = rider.skills.cobbles.toDouble();
      _editDescending = rider.skills.descending.toDouble();
      _editHandling = rider.skills.bikeHandling.toDouble();
      _editAero = rider.skills.aeroPositioning.toDouble();
      _editVo2Max = rider.physiology.vo2Max;
    });
  }

  Widget _buildRiderEditForm(CareerSave save) {
    final rider = _selectedEditingRider!;
    final team = save.getTeamById(rider.teamId);
    final weight = double.tryParse(_editWeightController.text) ?? rider.physiology.weightKg;
    final ftp = int.tryParse(_editFtpController.text) ?? rider.physiology.ftpWatts;
    final wkg = weight > 0 ? ftp / weight : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Karta podglądu na żywo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                RiderAvatarWidget.fromRider(
                  rider: rider,
                  team: team,
                  size: 58,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${_editFirstNameController.text} ${_editLastNameController.text}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _editCountryIsoController.text.toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryGold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${team?.name ?? "Drużyna"} • Rola: ${rider.contract.role.label}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildBadge('FTP: ${ftp}W', AppColors.primaryGold),
                          const SizedBox(width: 8),
                          _buildBadge('${wkg.toStringAsFixed(2)} W/kg', AppColors.emeraldGreen),
                          const SizedBox(width: 8),
                          _buildBadge('W\': ${(int.tryParse(_editWPrimeController.text) ?? rider.physiology.wPrimeJoules) ~/ 1000}kJ', AppColors.crimsonAlert),
                          const SizedBox(width: 8),
                          _buildBadge('VO2max: ${_editVo2Max.toStringAsFixed(1)}', AppColors.accentBlue),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pola tekstowe: Dane personalne
          const Text('DANE OSOBOWE I BIOMETRYCZNE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryGold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildFormField('Imię', _editFirstNameController)),
              const SizedBox(width: 12),
              Expanded(child: _buildFormField('Nazwisko', _editLastNameController)),
              const SizedBox(width: 12),
              SizedBox(width: 90, child: _buildFormField('Kraj ISO', _editCountryIsoController)),
              const SizedBox(width: 12),
              SizedBox(width: 80, child: _buildFormField('Wiek', _editAgeController, isNumber: true)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildFormField('Waga (kg)', _editWeightController, isNumber: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildFormField('Wzrost (cm)', _editHeightController, isNumber: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildFormField('Max HR (bpm)', _editMaxHrController, isNumber: true)),
            ],
          ),
          const SizedBox(height: 24),

          // Parametry Wydolnościowe (Silnik Fizyczny)
          const Text('PROFIL MOCY I PARAMETRY WYDOLNOŚCIOWE (PHYSIOLOGY)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryGold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildFormField('FTP / Moc Progu (Watts)', _editFtpController, isNumber: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildFormField('Bateria beztlenowa W\' (Dżule)', _editWPrimeController, isNumber: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildFormField('Moc 5s Sprint (Watts)', _editSprintWattsController, isNumber: true)),
            ],
          ),
          const SizedBox(height: 16),

          // Suwaki Umiejętności Kolarza
          _buildSkillSlider('VO2 Max (ml/kg/min)', _editVo2Max, 60, 95, (v) => setState(() => _editVo2Max = v)),
          _buildSkillSlider('Jazda po Bruku (Cobbles)', _editCobbles, 40, 99, (v) => setState(() => _editCobbles = v)),
          _buildSkillSlider('Zjazdy ze szczytów (Descending)', _editDescending, 40, 99, (v) => setState(() => _editDescending = v)),
          _buildSkillSlider('Prowadzenie Roweru w Tłoku (Handling)', _editHandling, 40, 99, (v) => setState(() => _editHandling = v)),
          _buildSkillSlider('Pozycja Aero i Tunel (Aero Positioning)', _editAero, 40, 99, (v) => setState(() => _editAero = v)),
          const SizedBox(height: 24),

          // Przycisk zapisu kolarza
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _selectedEditingRider = null),
                child: const Text('Anuluj'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _saveRiderChanges(save),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Zapisz Zmiany Kolarza w Grze'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emeraldGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.cardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryGold)),
      ),
    );
  }

  Widget _buildSkillSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              activeColor: AppColors.primaryGold,
              inactiveColor: Colors.white10,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(
              value.round().toString(),
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryGold),
            ),
          ),
        ],
      ),
    );
  }

  void _saveRiderChanges(CareerSave save) {
    final rider = _selectedEditingRider;
    if (rider == null) return;

    final updatedPhysiology = rider.physiology.copyWith(
      heightCm: double.tryParse(_editHeightController.text) ?? rider.physiology.heightCm,
      weightKg: double.tryParse(_editWeightController.text) ?? rider.physiology.weightKg,
      ftpWatts: int.tryParse(_editFtpController.text) ?? rider.physiology.ftpWatts,
      wPrimeJoules: int.tryParse(_editWPrimeController.text) ?? rider.physiology.wPrimeJoules,
      maxHr: int.tryParse(_editMaxHrController.text) ?? rider.physiology.maxHr,
      vo2Max: _editVo2Max,
    );

    final updatedPower = rider.powerProfile.copyWith(
      watts5s: int.tryParse(_editSprintWattsController.text) ?? rider.powerProfile.watts5s,
      watts60m: updatedPhysiology.ftpWatts,
    );

    final updatedSkills = rider.skills.copyWith(
      cobbles: _editCobbles.round(),
      descending: _editDescending.round(),
      bikeHandling: _editHandling.round(),
      aeroPositioning: _editAero.round(),
    );

    final updatedRider = rider.copyWith(
      firstName: _editFirstNameController.text.trim(),
      lastName: _editLastNameController.text.trim(),
      nationalityIso: _editCountryIsoController.text.trim().toUpperCase(),
      age: int.tryParse(_editAgeController.text) ?? rider.age,
      physiology: updatedPhysiology,
      powerProfile: updatedPower,
      skills: updatedSkills,
    );

    ref.read(careerControllerProvider.notifier).updateRider(updatedRider);
    setState(() {
      _selectedEditingRider = updatedRider;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.emeraldGreen,
        content: Text('Zapisano zaktualizowane parametry dla kolarza: ${updatedRider.fullName}!'),
      ),
    );
  }

  // ===========================================================================
  // 4. ZAKŁADKA 4: WBUDOWANY EDYTOR DRUŻYN I BARW (IN-GAME TEAM EDITOR)
  // ===========================================================================

  Widget _buildTab4TeamEditor(CareerSave? save) {
    if (save == null) {
      return const Center(
        child: Text('Załaduj karierę, aby edytować drużyny w grze.',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }

    final allTeams = save.teams;
    final filteredTeams = allTeams.where((t) {
      final query = _teamSearchController.text.toLowerCase().trim();
      final matchesQuery = query.isEmpty || t.name.toLowerCase().contains(query) || t.countryIso.toLowerCase().contains(query);
      final matchesDiv = _selectedDivisionFilter == null || t.division == _selectedDivisionFilter;
      return matchesQuery && matchesDiv;
    }).toList();

    return Row(
      children: [
        // Lewa kolumna: Lista drużyn
        Expanded(
          flex: 4,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _teamSearchController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Szukaj drużyny (np. UAE, Visma, Ineos)...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          prefixIcon: const Icon(Icons.shield_outlined, size: 18, color: AppColors.primaryGold),
                          filled: true,
                          fillColor: AppColors.cardDark,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<TeamDivision?>(
                        initialValue: _selectedDivisionFilter,
                        dropdownColor: AppColors.cardDark,
                        style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.cardDark,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Wszystkie Dywizje')),
                          DropdownMenuItem(value: TeamDivision.worldTour, child: Text('UCI WorldTour (18)')),
                          DropdownMenuItem(value: TeamDivision.proTeam, child: Text('UCI ProTeam (15)')),
                          DropdownMenuItem(value: TeamDivision.continental, child: Text('UCI Continental (20)')),
                        ],
                        onChanged: (val) => setState(() => _selectedDivisionFilter = val),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.cardBorder),

                Expanded(
                  child: ListView.separated(
                    itemCount: filteredTeams.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
                    itemBuilder: (ctx, index) {
                      final team = filteredTeams[index];
                      final isSelected = _selectedEditingTeam?.id == team.id;
                      final isPlayer = team.id == save.playerTeamId;

                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedTileColor: AppColors.primaryGold.withValues(alpha: 0.12),
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _parseColor(team.primaryJerseyColorHex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _parseColor(team.accentJerseyColorHex),
                              width: 2.5,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                team.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? AppColors.primaryGold : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isPlayer)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGold,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('TWÓJ', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.black)),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${team.division.label} • Rower: ${team.bikeDeal.manufacturerName}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        onTap: () => _selectTeamForEditing(team),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Prawa kolumna: Formularz edycji wybranej drużyny
        Expanded(
          flex: 6,
          child: _selectedEditingTeam == null
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.primaryGold, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Wybierz drużynę z listy po lewej stronie, aby edytować jej barwy i dane.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : _buildTeamEditForm(save),
        ),
      ],
    );
  }

  void _selectTeamForEditing(CyclingTeam team) {
    setState(() {
      _selectedEditingTeam = team;
      _editTeamNameController.text = team.name;
      _editTeamCountryController.text = team.countryIso;
      _editTeamCashController.text = team.cashBalanceEur.toString();
      _editPrimaryColorController.text = team.primaryJerseyColorHex;
      _editSecondaryColorController.text = team.secondaryJerseyColorHex;
      _editAccentColorController.text = team.accentJerseyColorHex;
      _selectedBrandName = team.bikeDeal.manufacturerName;
    });
  }

  Widget _buildTeamEditForm(CareerSave save) {
    final team = _selectedEditingTeam!;
    final primary = _parseColor(_editPrimaryColorController.text);
    final secondary = _parseColor(_editSecondaryColorController.text);
    final accent = _parseColor(_editAccentColorController.text);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Karta podglądu koszulki i barw
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                // Miniatura koszulki
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editTeamNameController.text,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${team.division.label} • Kraj rejestracji: ${_editTeamCountryController.text.toUpperCase()}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildColorPill('Główny', primary),
                          const SizedBox(width: 8),
                          _buildColorPill('Wstawki', secondary),
                          const SizedBox(width: 8),
                          _buildColorPill('Akcent', accent),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Pola danych drużyny
          const Text('INFORMACJE O KLUBIE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryGold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(flex: 3, child: _buildFormField('Nazwa Zespołu', _editTeamNameController)),
              const SizedBox(width: 12),
              SizedBox(width: 100, child: _buildFormField('Kraj ISO', _editTeamCountryController)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildFormField('Budżet Gotówkowy w Skarbcu (EUR)', _editTeamCashController, isNumber: true)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedBrandName,
                  dropdownColor: AppColors.cardDark,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Producent Rowerów',
                    labelStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Colnago', child: Text('Colnago (Włochy)')),
                    DropdownMenuItem(value: 'Cervélo', child: Text('Cervélo (Kanada)')),
                    DropdownMenuItem(value: 'Specialized', child: Text('Specialized (USA)')),
                    DropdownMenuItem(value: 'Pinarello', child: Text('Pinarello (Włochy)')),
                    DropdownMenuItem(value: 'Canyon', child: Text('Canyon (Niemcy)')),
                    DropdownMenuItem(value: 'Trek', child: Text('Trek (USA)')),
                    DropdownMenuItem(value: 'Giant', child: Text('Giant (Tajwan)')),
                    DropdownMenuItem(value: 'BMC', child: Text('BMC (Szwajcaria)')),
                    DropdownMenuItem(value: 'Bianchi', child: Text('Bianchi (Włochy)')),
                    DropdownMenuItem(value: 'Scott', child: Text('Scott (Szwajcaria)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBrandName = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Próbniki kolorów koszulek Hex
          const Text('KOLORYSTYKA KOSZULKI (BARWY KLUBOWE)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryGold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildColorInputTile('Kolor Podstawowy', _editPrimaryColorController, primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildColorInputTile('Kolor Wstawek', _editSecondaryColorController, secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildColorInputTile('Kolor Akcentu', _editAccentColorController, accent),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Paleta szybkich gotowych kolorów kolarskich
          const Text('Szybki wybór popularnych barw WorldTour:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickColorSwatch('#FFFFFF', 'Biały (UAE)'),
              _buildQuickColorSwatch('#FFD700', 'Żółty (Visma)'),
              _buildQuickColorSwatch('#1E3A8A', 'Granat (Soudal)'),
              _buildQuickColorSwatch('#DC2626', 'Czerwony (Ineos)'),
              _buildQuickColorSwatch('#10B981', 'Zielony (Bora)'),
              _buildQuickColorSwatch('#00E5FF', 'Turkus (Astana)'),
              _buildQuickColorSwatch('#111827', 'Czerń (Lidl-Trek)'),
              _buildQuickColorSwatch('#EC4899', 'Róż (EF EasyPost)'),
            ],
          ),
          const SizedBox(height: 28),

          // Przycisk zapisu drużyny
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _selectedEditingTeam = null),
                child: const Text('Anuluj'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _saveTeamChanges(save),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Zapisz Barwy i Dane Zespołu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorPill(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildColorInputTile(String label, TextEditingController controller, Color parsed) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: parsed,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: '#FFFFFF',
              hintStyle: TextStyle(color: Colors.white24),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 6),
              border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryGold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickColorSwatch(String hex, String label) {
    final color = _parseColor(hex);

    return InkWell(
      onTap: () {
        setState(() {
          _editPrimaryColorController.text = hex;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _saveTeamChanges(CareerSave save) {
    final team = _selectedEditingTeam;
    if (team == null) return;

    final updatedDeal = team.bikeDeal.copyWith(
      manufacturerName: _selectedBrandName,
    );

    final updatedTeam = team.copyWith(
      name: _editTeamNameController.text.trim(),
      countryIso: _editTeamCountryController.text.trim().toUpperCase(),
      cashBalanceEur: int.tryParse(_editTeamCashController.text) ?? team.cashBalanceEur,
      primaryJerseyColorHex: _editPrimaryColorController.text.trim(),
      secondaryJerseyColorHex: _editSecondaryColorController.text.trim(),
      accentJerseyColorHex: _editAccentColorController.text.trim(),
      bikeDeal: updatedDeal,
    );

    ref.read(careerControllerProvider.notifier).updateTeam(updatedTeam);
    setState(() {
      _selectedEditingTeam = updatedTeam;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.emeraldGreen,
        content: Text('Zapisano zaktualizowaną drużynę: ${updatedTeam.name}!'),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      String clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        clean = 'FF$clean';
      }
      return Color(int.parse(clean, radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}
