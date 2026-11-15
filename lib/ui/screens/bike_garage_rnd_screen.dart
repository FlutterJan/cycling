import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/career/career_save.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/equipment/frame_model.dart';
import '../../models/equipment/groupset_model.dart';
import '../../models/equipment/tire_model.dart';
import '../../models/equipment/wheelset_model.dart';
import '../../services/career/bike_manufacturer_negotiation_service.dart';
import '../../services/generators/fictional_brands_catalog.dart';
import '../../state/career_controller.dart';
import '../widgets/bike_preview_painter.dart';
import '../widgets/mechanic_workshop_panel.dart';

/// Typ etapu dla gotowych presetów konfiguracji roweru.
enum BikeStagePreset {
  climbing,
  aero,
  cobbles,
  timeTrial;

  String get label {
    switch (this) {
      case BikeStagePreset.climbing:
        return 'Górski';
      case BikeStagePreset.aero:
        return 'Aero / Płaski';
      case BikeStagePreset.cobbles:
        return 'Bruk / Klasyk';
      case BikeStagePreset.timeTrial:
        return 'Jazda na Czas (TT)';
    }
  }

  IconData get icon {
    switch (this) {
      case BikeStagePreset.climbing:
        return Icons.terrain_rounded;
      case BikeStagePreset.aero:
        return Icons.air_rounded;
      case BikeStagePreset.cobbles:
        return Icons.grain_rounded;
      case BikeStagePreset.timeTrial:
        return Icons.timer_rounded;
    }
  }
}

/// Kategoria edytowanego komponentu w warsztacie.
enum BikeComponentTab {
  frame,
  wheels,
  groupset,
  tires,
  lube,
  cockpit;

  String get label {
    switch (this) {
      case BikeComponentTab.frame:
        return 'Rama';
      case BikeComponentTab.wheels:
        return 'Koła & Stożki';
      case BikeComponentTab.groupset:
        return 'Grupa Osprzętu';
      case BikeComponentTab.tires:
        return 'Opony & Dętki';
      case BikeComponentTab.lube:
        return 'Smarowanie Napędu';
      case BikeComponentTab.cockpit:
        return 'Kokpit & Fitting';
    }
  }

  IconData get icon {
    switch (this) {
      case BikeComponentTab.frame:
        return Icons.pedal_bike_rounded;
      case BikeComponentTab.wheels:
        return Icons.trip_origin_rounded;
      case BikeComponentTab.groupset:
        return Icons.settings_suggest_rounded;
      case BikeComponentTab.tires:
        return Icons.radio_button_checked_rounded;
      case BikeComponentTab.lube:
        return Icons.opacity_rounded;
      case BikeComponentTab.cockpit:
        return Icons.tune_rounded;
    }
  }
}

/// Ekran Garażu, Konfiguratora Sprzętu i R&D (`BikeGarageRndScreen`).
///
/// Zawiera:
/// 1. Konfigurator roweru z podglądem na żywo (`BikePreviewWidget`), doborem ramy,
///    kół, osprzętu, opon (25-32mm), dętek TPU vs Tubeless oraz smarowania (wosk vs olej),
///    z telemetrią masy co do grama i zysku watów przy 45 km/h.
/// 2. Podgląd umowy z obecnym producentem rowerów i oferty od innych marek.
/// 3. Centrum badawcze R&D i sesje w tunelu aerodynamicznym.
class BikeGarageRndScreen extends ConsumerStatefulWidget {
  final CompleteBike? initialBike;

  const BikeGarageRndScreen({
    super.key,
    this.initialBike,
  });

  @override
  ConsumerState<BikeGarageRndScreen> createState() => _BikeGarageRndScreenState();
}

class _BikeGarageRndScreenState extends ConsumerState<BikeGarageRndScreen>
    with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  BikeStagePreset _activePreset = BikeStagePreset.climbing;
  BikeComponentTab _activeComponentTab = BikeComponentTab.frame;

  // Aktywne komponenty konfiguratora
  late FrameModel _selectedFrame;
  late WheelsetModel _selectedWheelset;
  late GroupsetModel _selectedGroupset;
  late TireModel _selectedTire;

  // Parametry bike fittingu i technologii
  int _cockpitWidthMm = 400;
  double _hoodInwardTiltDegrees = 6.0;
  bool _slammedStem = true;
  bool _isTanWall = true;
  bool _isTubeless = true; // Tubeless vs ultralekka dętka TPU
  bool _isHotMeltWax = true; // Kąpiel w gorącym wosku vs olej syntetyczny
  Color? _customFrameColor;
  Color _barTapeColor = const Color(0xFF1E1E1E);

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  void _initializeFromSaveOrDefaults(CareerSave? save) {
    if (_isInitialized) return;

    if (widget.initialBike != null) {
      _applyBikeToState(widget.initialBike!);
    } else if (save != null && save.playerTeam.inventoryBikes.isNotEmpty) {
      _applyBikeToState(save.playerTeam.inventoryBikes.first);
    } else {
      _selectedFrame = FictionalBrandsCatalog.lightestClimbingFrame;
      _selectedWheelset = FictionalBrandsCatalog.lightestClimbingWheelset;
      _selectedGroupset = FictionalBrandsCatalog.allGroupsets.first;
      _selectedTire = FictionalBrandsCatalog.fastestTire;
      _isTubeless = _selectedTire.isTubeless;
    }
    _isInitialized = true;
  }

  void _applyBikeToState(CompleteBike bike) {
    _selectedFrame = bike.frame;
    _selectedWheelset = bike.wheelset;
    _selectedGroupset = bike.groupset;
    _selectedTire = bike.tire;
    _cockpitWidthMm = bike.cockpitWidthMm;
    _hoodInwardTiltDegrees = bike.hoodInwardTiltDegrees;
    _slammedStem = bike.slammedStem;
    _isTubeless = bike.tire.isTubeless;
  }

  void _applyPreset(BikeStagePreset preset) {
    setState(() {
      _activePreset = preset;
      switch (preset) {
        case BikeStagePreset.climbing:
          _selectedFrame = FictionalBrandsCatalog.lightestClimbingFrame;
          _selectedWheelset = FictionalBrandsCatalog.lightestClimbingWheelset;
          _selectedTire = FictionalBrandsCatalog.allTires.firstWhere(
            (t) => t.widthMm == 28,
            orElse: () => FictionalBrandsCatalog.fastestTire,
          );
          _cockpitWidthMm = 400;
          _hoodInwardTiltDegrees = 6.0;
          _slammedStem = false;
          _isTanWall = true;
          _isTubeless = true;
          _isHotMeltWax = true;
          break;

        case BikeStagePreset.aero:
          _selectedFrame = FictionalBrandsCatalog.mostAeroRoadFrame;
          _selectedWheelset = FictionalBrandsCatalog.mostAeroRoadWheelset;
          _selectedTire = FictionalBrandsCatalog.allTires.firstWhere(
            (t) => t.widthMm == 28,
            orElse: () => FictionalBrandsCatalog.fastestTire,
          );
          _cockpitWidthMm = 380;
          _hoodInwardTiltDegrees = 12.0;
          _slammedStem = true;
          _isTanWall = false;
          _isTubeless = true;
          _isHotMeltWax = true;
          break;

        case BikeStagePreset.cobbles:
          _selectedFrame = FictionalBrandsCatalog.allFrames.firstWhere(
            (f) => f.category == FrameCategory.cobbleEndurance,
            orElse: () => FictionalBrandsCatalog.allFrames.first,
          );
          _selectedWheelset = FictionalBrandsCatalog.allWheelsets.firstWhere(
            (w) => w.rimDepthMm >= 40 && w.rimDepthMm <= 50,
            orElse: () => FictionalBrandsCatalog.allWheelsets.first,
          );
          _selectedTire = FictionalBrandsCatalog.toughestCobbleTire;
          _cockpitWidthMm = 420;
          _hoodInwardTiltDegrees = 4.0;
          _slammedStem = false;
          _isTanWall = true;
          _isTubeless = true;
          _isHotMeltWax = false; // Olej odporny na deszcz i błoto na brukach
          break;

        case BikeStagePreset.timeTrial:
          _selectedFrame = FictionalBrandsCatalog.fastestTimeTrialFrame;
          _selectedWheelset = FictionalBrandsCatalog.fastestDiscWheelset;
          _selectedTire = FictionalBrandsCatalog.allTires.firstWhere(
            (t) => t.widthMm == 25,
            orElse: () => FictionalBrandsCatalog.fastestTire,
          );
          _cockpitWidthMm = 360;
          _hoodInwardTiltDegrees = 0.0;
          _slammedStem = true;
          _isTanWall = false;
          _isTubeless = true;
          _isHotMeltWax = true;
          break;
      }
    });
  }

  CompleteBike get _currentConfiguredBike {
    final effectiveTire = _selectedTire.copyWith(isTubeless: _isTubeless);
    return CompleteBike(
      id: 'custom_bike_${_selectedFrame.category.name}_${_selectedFrame.id}',
      name: '${_selectedFrame.name} Pro Edition',
      frame: _selectedFrame,
      wheelset: _selectedWheelset,
      groupset: _selectedGroupset,
      tire: effectiveTire,
      cockpitWidthMm: _cockpitWidthMm,
      hoodInwardTiltDegrees: _hoodInwardTiltDegrees,
      slammedStem: _slammedStem,
    );
  }

  // ===========================================================================
  // KALKULACJE TELEMETRYCZNE (MASA, ZYSK WATÓW PRZY 45 KM/H, OSZCZĘDNOŚĆ CZASU)
  // ===========================================================================

  /// Surowa waga w gramach uwzględniająca dętkę TPU lub mleko Tubeless
  int get _calculatedRawWeightGrams {
    final baseGrams = (_currentConfiguredBike.rawWeightKg * 1000.0).round();
    // Tubeless: ~45g mleka na koło (90g). Dętka TPU: ~35g na koło (70g). Różnica: -20g dla TPU
    final tubeDelta = _isTubeless ? 0 : -20;
    // Wosk: -10g wobec lepkiego smaru fabrycznego
    final waxDelta = _isHotMeltWax ? -10 : 0;
    return baseGrams + tubeDelta + waxDelta;
  }

  /// Oficjalna waga startowa wg limitu UCI 6,800 g
  int get _officialUciWeightGrams {
    return math.max(6800, _calculatedRawWeightGrams);
  }

  /// Masa balastu doważającego w gramach
  int get _ballastGrams {
    if (_calculatedRawWeightGrams < 6800) {
      return 6800 - _calculatedRawWeightGrams;
    }
    return 0;
  }

  /// Efektywny współczynnik oporu toczenia Crr
  double get _effectiveCrr {
    double crr = _selectedTire.rollingResistanceCrr;
    if (_isTubeless) {
      crr *= 0.94; // System bezdętkowy obniża histerezę i tarcie wewnętrzne
    } else {
      crr *= 1.05; // Dętka TPU jest szybka, lecz nieznacznie ustępuje mleku
    }
    return crr;
  }

  /// Wyliczony zysk mocy w watach przy 45 km/h (12.5 m/s) względem bazy referencyjnej
  double get _wattsSavedAt45Kmh {
    // 1. Zysk aerodynamiczny CdA (baza referencyjna: standardowy rower szosowy z CdA modifier = +0.005)
    const baselineCdaMod = 0.005;
    final cdaImprovement = baselineCdaMod - _currentConfiguredBike.totalCdaModifier;
    // P_aero = 0.5 * rho * deltaCdA * v^3  (rho = 1.225, v = 12.5 m/s, v^3 = 1953.125)
    final aeroWatts = cdaImprovement * (0.5 * 1.225 * 1953.125);

    // 2. Zysk oporu toczenia Crr (baza: opona treningowa Crr = 0.0048)
    const baselineCrr = 0.0048;
    final crrImprovement = baselineCrr - _effectiveCrr;
    final totalMassKg = 70.0 + (_officialUciWeightGrams / 1000.0);
    // P_rr = Crr * m * g * v
    final rrWatts = crrImprovement * totalMassKg * 9.81 * 12.5;

    // 3. Zysk napędu (gorący wosk daje ~4.8W vs standardowy smar, elektronika +0.8W)
    final waxWatts = _isHotMeltWax ? 4.8 : 0.0;
    final groupWatts = _selectedGroupset.isElectronic ? 0.8 : 0.0;

    return math.max(0.0, aeroWatts + rrWatts + waxWatts + groupWatts);
  }

  /// Zysk czasowy na 40 km płaskiej trasy / czasówki w sekundach
  int get _secondsSaved40km {
    return (_wattsSavedAt45Kmh * 3.4).round();
  }

  /// Zysk czasowy na podjeździe 10 km @ 8% w sekundach dzięki niskiej wadze
  int get _secondsSavedClimb10km {
    const baselineWeightGrams = 8000;
    final weightDelta = baselineWeightGrams - _officialUciWeightGrams;
    return ((weightDelta / 100.0) * 1.15).round();
  }

  // ===========================================================================
  // GŁÓWNA METODA BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final careerState = ref.watch(careerProvider);
    final currentSave = careerState.save;

    _initializeFromSaveOrDefaults(currentSave);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(currentSave),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _mainTabController,
                children: [
                  _buildConfiguratorView(currentSave),
                  _buildManufacturerDealView(currentSave),
                  _buildWindTunnelView(currentSave),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. NAGŁÓWEK I ZAKŁADKI GŁÓWNE
  // ===========================================================================

  Widget _buildTopHeader(CareerSave? save) {
    final teamName = save?.playerTeam.name ?? 'Zespół Menedżera';
    final manufacturerName = save?.playerTeam.bikeDeal.manufacturerName ?? 'Sponsor Techniczny';
    final budgetEur = save?.playerTeam.cashBalanceEur ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.precision_manufacturing_rounded,
              color: AppColors.accentBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Garaż, Warsztat Sprzętowy & R&D',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        manufacturerName,
                        style: const TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$teamName • Budżet operacyjny: €${_formatCurrency(budgetEur)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _openMechanicWorkshopModal(context),
            icon: const Icon(Icons.home_repair_service_rounded, size: 16),
            label: const Text('SERWIS & CIŚNIENIE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldAccent,
              foregroundColor: AppColors.backgroundDark,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _openMechanicWorkshopModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.90,
          margin: const EdgeInsets.only(top: 30),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: MechanicWorkshopPanel(
              bike: _currentConfiguredBike,
              onBikeUpdated: (updatedBike) {
                setState(() {
                  _applyBikeToState(updatedBike);
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.cardSurface,
      child: TabBar(
        controller: _mainTabController,
        indicatorColor: AppColors.accentBlue,
        indicatorWeight: 3,
        labelColor: AppColors.accentBlue,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: const [
          Tab(
            icon: Icon(Icons.tune_rounded, size: 18),
            text: 'Konfigurator & Telemetria',
          ),
          Tab(
            icon: Icon(Icons.handshake_rounded, size: 18),
            text: 'Umowa Sponsorska & Rynek',
          ),
          Tab(
            icon: Icon(Icons.air_rounded, size: 18),
            text: 'Tunel Aerodynamiczny R&D',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. WIDOK KONFIGURATORA ROWERU & TELEMETRIA (TAB 1)
  // ===========================================================================

  Widget _buildConfiguratorView(CareerSave? save) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1000;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lewa kolumna: Podgląd na żywo + Bento Box telemetrii
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPresetSelector(),
                      const SizedBox(height: 16),
                      _buildBikeLivePreviewHero(),
                      const SizedBox(height: 16),
                      _buildTelemetryBentoGrid(),
                      const SizedBox(height: 16),
                      _buildSaveAndApplyActions(save),
                    ],
                  ),
                ),
              ),

              // Prawa kolumna: Szczegółowy dobór komponentów
              Expanded(
                flex: 4,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: AppColors.cardBorder, width: 1)),
                  ),
                  child: Column(
                    children: [
                      _buildComponentCategorySelector(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: _buildActiveComponentPicker(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          // Układ mobilny / wąski ekran
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPresetSelector(),
                const SizedBox(height: 14),
                _buildBikeLivePreviewHero(),
                const SizedBox(height: 14),
                _buildTelemetryBentoGrid(),
                const SizedBox(height: 14),
                _buildComponentCategorySelector(),
                const SizedBox(height: 14),
                _buildActiveComponentPicker(),
                const SizedBox(height: 20),
                _buildSaveAndApplyActions(save),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildPresetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PROFIL ETAPU & PRESETY WYŚCIGOWE',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BikeStagePreset.values.map((preset) {
            final isSelected = _activePreset == preset;
            return ChoiceChip(
              selected: isSelected,
              onSelected: (_) => _applyPreset(preset),
              selectedColor: AppColors.accentBlue,
              backgroundColor: AppColors.cardSurface,
              side: BorderSide(
                color: isSelected ? AppColors.accentBlue : AppColors.cardBorder,
              ),
              avatar: Icon(
                preset.icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              label: Text(
                preset.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBikeLivePreviewHero() {
    final bike = _currentConfiguredBike;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pasek informacyjny maszyny
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bike.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_selectedFrame.category.name.toUpperCase()} • ${_selectedWheelset.rimDepthMm}mm Rim • ${_selectedTire.widthMm}mm ${_isTubeless ? "Tubeless" : "TPU"}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildUciComplianceBadge(),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.cardBorder),

          // Interaktywny podgląd 2D roweru
          SizedBox(
            height: 250,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: BikePreviewWidget(
                bike: bike,
                isTanWallOverride: _isTanWall,
                barTapeColorOverride: _barTapeColor,
                frameColorOverride: _customFrameColor,
                showBackground: true,
                showFloorReflection: true,
                showSpecsPill: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUciComplianceBadge() {
    final isBallastNeeded = _ballastGrams > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isBallastNeeded
            ? AppColors.primaryGold.withValues(alpha: 0.15)
            : AppColors.statusSuccess.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBallastNeeded
              ? AppColors.primaryGold.withValues(alpha: 0.4)
              : AppColors.statusSuccess.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBallastNeeded ? Icons.scale_rounded : Icons.verified_rounded,
            size: 14,
            color: isBallastNeeded ? AppColors.primaryGold : AppColors.statusSuccess,
          ),
          const SizedBox(width: 6),
          Text(
            isBallastNeeded
                ? 'Balast UCI +${_ballastGrams}g'
                : 'Norma UCI 6.8kg OK',
            style: TextStyle(
              color: isBallastNeeded ? AppColors.primaryGold : AppColors.statusSuccess,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryBentoGrid() {
    final wattsSaved = _wattsSavedAt45Kmh;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TELEMETRIA WYŚCIGOWA & ANALIZA OSIĄGÓW (45 KM/H)',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.8,
          children: [
            // Karta 1: Masa całkowita co do grama
            _buildTelemetryBentoCard(
              title: 'Masa z Balastem UCI',
              value: '$_officialUciWeightGrams g',
              subtitle: _ballastGrams > 0
                  ? 'Surowa: ${_calculatedRawWeightGrams}g (+${_ballastGrams}g balastu)'
                  : 'Waga surowa zgodna z regulaminem',
              icon: Icons.monitor_weight_rounded,
              accentColor: _ballastGrams > 0 ? AppColors.primaryGold : AppColors.statusSuccess,
            ),

            // Karta 2: Zysk w watach przy 45 km/h
            _buildTelemetryBentoCard(
              title: 'Zysk Mocy @ 45 km/h',
              value: '+${wattsSaved.toStringAsFixed(1)} W',
              subtitle: 'Aero, niskie Crr oraz wosk napędu',
              icon: Icons.bolt_rounded,
              accentColor: AppColors.statusSuccess,
            ),

            // Karta 3: Oszczędność czasu na 40 km
            _buildTelemetryBentoCard(
              title: 'Zysk na 40 km TT / Płaski',
              value: '-$_secondsSaved40km s',
              subtitle: 'Ok. ${(_secondsSaved40km / 60).floor()}m ${(_secondsSaved40km % 60)}s szybciej',
              icon: Icons.speed_rounded,
              accentColor: AppColors.accentBlue,
            ),

            // Karta 4: Zysk na podjeździe 10 km @ 8%
            _buildTelemetryBentoCard(
              title: 'Podjazd 10km @ 8%',
              value: '-$_secondsSavedClimb10km s',
              subtitle: 'Dzięki redukcji masy konstrukcji',
              icon: Icons.filter_hdr_rounded,
              accentColor: AppColors.powerZone5,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTelemetryBentoCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveAndApplyActions(CareerSave? save) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _saveConfiguredBikeToFlotilla(save),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text(
              'Zapisz Maszynę do Floty Drużyny',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: _showColorPickerModal,
          icon: const Icon(Icons.palette_rounded, color: AppColors.primaryGold),
          tooltip: 'Personalizuj lakier ramy i owijkę',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.cardSurface,
            side: const BorderSide(color: AppColors.cardBorder),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  void _saveConfiguredBikeToFlotilla(CareerSave? save) {
    if (save == null) return;

    final configuredBike = _currentConfiguredBike;
    final team = save.playerTeam;

    // Aktualizujemy lub zastępujemy rower w flocie
    final currentBikes = List<CompleteBike>.from(team.inventoryBikes);
    final existingIndex = currentBikes.indexWhere(
      (b) => b.frame.category == configuredBike.frame.category,
    );

    if (existingIndex >= 0) {
      currentBikes[existingIndex] = configuredBike;
    } else {
      currentBikes.add(configuredBike);
    }

    final updatedTeam = team.copyWith(inventoryBikes: currentBikes);
    final updatedSave = save.copyWith(
      teams: save.teams.map((t) => t.id == team.id ? updatedTeam : t).toList(),
    );

    ref.read(careerProvider.notifier).updateSave(updatedSave);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.statusSuccess,
        content: Text(
          'Pomyślnie zaktualizowano konfigurację roweru: ${configuredBike.name}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. PRAWA KOLUMNA: DOBÓR KOMPONENTÓW ROWERU
  // ===========================================================================

  Widget _buildComponentCategorySelector() {
    return Container(
      color: AppColors.cardDark,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: BikeComponentTab.values.map((tab) {
            final isSelected = _activeComponentTab == tab;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                selected: isSelected,
                onSelected: (_) => setState(() => _activeComponentTab = tab),
                selectedColor: AppColors.accentBlue.withValues(alpha: 0.2),
                backgroundColor: Colors.transparent,
                side: BorderSide(
                  color: isSelected ? AppColors.accentBlue : AppColors.cardBorder,
                ),
                avatar: Icon(
                  tab.icon,
                  size: 14,
                  color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
                ),
                label: Text(
                  tab.label,
                  style: TextStyle(
                    color: isSelected ? AppColors.accentBlue : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActiveComponentPicker() {
    switch (_activeComponentTab) {
      case BikeComponentTab.frame:
        return _buildFramePicker();
      case BikeComponentTab.wheels:
        return _buildWheelsetPicker();
      case BikeComponentTab.groupset:
        return _buildGroupsetPicker();
      case BikeComponentTab.tires:
        return _buildTireAndTubePicker();
      case BikeComponentTab.lube:
        return _buildDrivetrainLubePicker();
      case BikeComponentTab.cockpit:
        return _buildCockpitFittingPicker();
    }
  }

  Widget _buildFramePicker() {
    final frames = FictionalBrandsCatalog.allFrames;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DOBÓR RAMY (WAGA CO DO GRAMA & AERO)',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        ...frames.map((frame) {
          final isSelected = _selectedFrame.id == frame.id;
          return _buildSelectableItemCard(
            isSelected: isSelected,
            onTap: () => setState(() => _selectedFrame = frame),
            title: frame.name,
            badge: frame.category.name.toUpperCase(),
            weightGrams: frame.weightGrams,
            stats: [
              'Aero: ${(frame.aeroCdaModifier * 1000).toStringAsFixed(1)} mCdA',
              'Sztywność: ${frame.stiffnessToWeightIndex.toStringAsFixed(2)}',
              'Tłumienie: ${(frame.comfortCompliance * 100).toInt()}%',
            ],
          );
        }),
      ],
    );
  }

  Widget _buildWheelsetPicker() {
    final wheelsets = FictionalBrandsCatalog.allWheelsets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ZESTAW KÓŁ KARBONOWYCH (STOŻKI & DYSK TT)',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        ...wheelsets.map((wheels) {
          final isSelected = _selectedWheelset.id == wheels.id;
          return _buildSelectableItemCard(
            isSelected: isSelected,
            onTap: () => setState(() => _selectedWheelset = wheels),
            title: wheels.name,
            badge: wheels.isDiscWheel ? 'PEŁNY DYSK TT' : 'STOŻEK ${wheels.rimDepthMm}mm',
            weightGrams: wheels.weightGrams,
            stats: [
              'Aero: ${(wheels.aeroCdaModifier * 1000).toStringAsFixed(1)} mCdA',
              'Wiatr boczny: ${(wheels.crosswindStabilityPenalty * 100).toInt()}%',
              'Opór piast: ${wheels.hubEngagementDragWatts}W',
            ],
          );
        }),
      ],
    );
  }

  Widget _buildGroupsetPicker() {
    final groups = FictionalBrandsCatalog.allGroupsets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GRUPA OSPRZĘTU (NAPĘD & HAMULCE TARCZOWE)',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        ...groups.map((group) {
          final isSelected = _selectedGroupset.id == group.id;
          return _buildSelectableItemCard(
            isSelected: isSelected,
            onTap: () => setState(() => _selectedGroupset = group),
            title: group.name,
            badge: group.isElectronic ? 'ELEKTRONICZNA' : 'MECHANICZNA',
            weightGrams: group.weightGrams,
            stats: [
              'Biegi: ${group.speedCount}s',
              'Sprawność: ${(group.mechanicalEfficiency * 100).toStringAsFixed(1)}%',
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTireAndTubePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SZEROKOŚĆ OPON (25 - 32 MM)',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [25, 28, 30, 32].map((width) {
            final isSelected = _selectedTire.widthMm == width;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  selected: isSelected,
                  onSelected: (_) {
                    final matchingTire = FictionalBrandsCatalog.allTires.firstWhere(
                      (t) => t.widthMm == width,
                      orElse: () => _selectedTire.copyWith(widthMm: width),
                    );
                    setState(() => _selectedTire = matchingTire);
                  },
                  selectedColor: AppColors.accentBlue,
                  backgroundColor: AppColors.cardSurface,
                  side: BorderSide(
                    color: isSelected ? AppColors.accentBlue : AppColors.cardBorder,
                  ),
                  label: Text(
                    '${width}mm',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        const Text(
          'SYSTEM DĘTKOWY VS BEZDĘTKOWY TUBELESS',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildOptionTile(
                title: 'System Tubeless',
                subtitle: 'Mleko uszczelniające • Niższy Crr • Bezpieczeństwo',
                icon: Icons.shield_rounded,
                isSelected: _isTubeless,
                onTap: () => setState(() => _isTubeless = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildOptionTile(
                title: 'Dętka TPU',
                subtitle: 'Termoplast • Tylko 35g • Zwinność w górach',
                icon: Icons.bolt_rounded,
                isSelected: !_isTubeless,
                onTap: () => setState(() => _isTubeless = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const Text(
          'KOLORYSTYKA ŚCIANKI OPONY',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildOptionTile(
                title: 'Klasyczna Tan-Wall',
                subtitle: 'Beżowa bawełna Retro Pro',
                icon: Icons.lens_rounded,
                iconColor: const Color(0xFFD4A373),
                isSelected: _isTanWall,
                onTap: () => setState(() => _isTanWall = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildOptionTile(
                title: 'Czarna Black-Wall',
                subtitle: 'Nowoczesny mat stealth',
                icon: Icons.circle_outlined,
                isSelected: !_isTanWall,
                onTap: () => setState(() => _isTanWall = false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDrivetrainLubePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OBRÓBKA ŁAŃCUCHA & SMAROWANIE NAPĘDU',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        _buildOptionTile(
          title: 'Kąpiel w Gorącym Wosku (Hot Melt Wax)',
          subtitle: 'Wygotowany w płynnej parafinie z wolframem WS2 • Zysk do -4.8W przy 45 km/h • Czysty napęd odpychający pył',
          icon: Icons.whatshot_rounded,
          iconColor: AppColors.primaryGold,
          isSelected: _isHotMeltWax,
          onTap: () => setState(() => _isHotMeltWax = true),
        ),
        const SizedBox(height: 8),
        _buildOptionTile(
          title: 'Syntetyczny Olej Ceramiczny / Standardowy',
          subtitle: 'Tradycyjny film olejowy • Doskonała odporność na ulewny deszcz i błoto na brukach • Standardowe opory tarcia',
          icon: Icons.water_drop_rounded,
          iconColor: AppColors.accentBlue,
          isSelected: !_isHotMeltWax,
          onTap: () => setState(() => _isHotMeltWax = false),
        ),
      ],
    );
  }

  Widget _buildCockpitFittingPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SZEROKOŚĆ KIEROWNICY (AERODYNAMIKA TUŁOWIA)',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [360, 380, 400, 420].map((width) {
            final isSelected = _cockpitWidthMm == width;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  selected: isSelected,
                  onSelected: (_) => setState(() => _cockpitWidthMm = width),
                  selectedColor: AppColors.accentBlue,
                  backgroundColor: AppColors.cardSurface,
                  side: BorderSide(
                    color: isSelected ? AppColors.accentBlue : AppColors.cardBorder,
                  ),
                  label: Text(
                    '${width}mm',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        Text(
          'KĄT PODGIĘCIA KLAMEK UCI: ${_hoodInwardTiltDegrees.toStringAsFixed(1)}°',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        Slider(
          value: _hoodInwardTiltDegrees,
          min: 0.0,
          max: 14.0,
          divisions: 14,
          activeColor: AppColors.accentBlue,
          inactiveColor: AppColors.cardBorder,
          label: '${_hoodInwardTiltDegrees.toInt()}°',
          onChanged: (val) => setState(() => _hoodInwardTiltDegrees = val),
        ),
        const SizedBox(height: 10),

        _buildOptionTile(
          title: 'Mostek Slammed (Brak Podkładek)',
          subtitle: 'Agresywna pozycja czołowa kolarza • -0.0055 CdA redukcji oporu',
          icon: Icons.arrow_downward_rounded,
          isSelected: _slammedStem,
          onTap: () => setState(() => _slammedStem = !_slammedStem),
        ),
      ],
    );
  }

  Widget _buildSelectableItemCard({
    required bool isSelected,
    required VoidCallback onTap,
    required String title,
    required String badge,
    required int weightGrams,
    required List<String> stats,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accentBlue.withValues(alpha: 0.12) : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppColors.accentBlue : AppColors.cardBorder,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
        onTap: onTap,
        dense: true,
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.accentBlue : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${weightGrams}g',
                style: const TextStyle(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  stats.join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: AppColors.accentBlue, size: 20)
            : const Icon(Icons.circle_outlined, color: AppColors.cardBorder, size: 20),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue.withValues(alpha: 0.12) : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor ?? (isSelected ? AppColors.accentBlue : AppColors.textSecondary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.accentBlue : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 18,
              color: isSelected ? AppColors.accentBlue : AppColors.cardBorder,
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final colors = [
              const Color(0xFF1E88E5), // Blue
              const Color(0xFFE53935), // Red
              const Color(0xFFFFB300), // Yellow Gold
              const Color(0xFF43A047), // Green
              const Color(0xFF8E24AA), // Purple
              const Color(0xFF212121), // Stealth Black
              const Color(0xFFF5F5F5), // White
            ];

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personalizacja Lakieru Ramy & Owijki',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kolor Lakieru Ramy:',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: colors.map((c) {
                      final isSelected = _customFrameColor == c;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _customFrameColor = c);
                          setModalState(() {});
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : AppColors.cardBorder,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kolor Owijki Kierownicy:',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: [
                      const Color(0xFF1E1E1E), // Black
                      const Color(0xFFEEEEEE), // White
                      const Color(0xFFC62828), // Red
                      const Color(0xFFF9A825), // Yellow
                    ].map((c) {
                      final isSelected = _barTapeColor == c;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _barTapeColor = c);
                          setModalState(() {});
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.accentBlue : AppColors.cardBorder,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text('Zastosuj Malowanie'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // 4. WIDOK: UMOWA SPONSORSKA & RYNEK PRODUCENTÓW (TAB 2)
  // ===========================================================================

  Widget _buildManufacturerDealView(CareerSave? save) {
    if (save == null) {
      return const Center(child: Text('Brak danych kariery.', style: TextStyle(color: AppColors.textSecondary)));
    }

    final team = save.playerTeam;
    final deal = team.bikeDeal;
    final controller = ref.read(careerProvider.notifier);
    final prowess = controller.getTeamEquipmentProwessRating();
    final offers = controller.getAvailableBikeManufacturerOffers();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Karta obecnego kontraktu
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.handshake_rounded, color: AppColors.primaryGold, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                deal.manufacturerName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: List.generate(
                                  deal.prestigeLevel,
                                  (index) => const Icon(Icons.star_rounded, color: AppColors.primaryGold, size: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Oficjalny Dostawca Rowerów & Partner Techniczny Drużyny',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: deal.isExpiring
                            ? AppColors.powerZone6.withValues(alpha: 0.2)
                            : AppColors.statusSuccess.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        deal.isExpiring ? 'WYGASA W TYM SEZONIE' : '${deal.contractYearsLeft} LATA UMOWY',
                        style: TextStyle(
                          color: deal.isExpiring ? AppColors.powerZone6 : AppColors.statusSuccess,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.cardBorder, height: 1),
                const SizedBox(height: 16),

                // Statystyki kontraktu
                Row(
                  children: [
                    Expanded(
                      child: _buildDealStatTile(
                        label: 'Wkład Gotówkowy',
                        value: '€${_formatCurrency(deal.annualCashContributionEur)}/rok',
                        icon: Icons.euro_rounded,
                      ),
                    ),
                    Expanded(
                      child: _buildDealStatTile(
                        label: 'Pula Darmowych Rowerów',
                        value: '${deal.freeBikesQuota} maszyn',
                        icon: Icons.pedal_bike_rounded,
                      ),
                    ),
                    Expanded(
                      child: _buildDealStatTile(
                        label: 'Poziom R&D Inżynierii',
                        value: '${deal.researchAndDevelopmentLevel} / 100',
                        icon: Icons.biotech_rounded,
                      ),
                    ),
                    Expanded(
                      child: _buildDealStatTile(
                        label: 'Indeks Sprzętu Teamu',
                        value: '${prowess.toStringAsFixed(1)} / 100 pkt',
                        icon: Icons.military_tech_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Oferty od innych marek na rynku
          const Text(
            'RYNEK PRODUCENTÓW ROWERÓW (OFERTY NA KOLEJNY SEZON)',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: offers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final offer = offers[index];
              return _buildMarketOfferCard(save, offer);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDealStatTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryGold, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildMarketOfferCard(CareerSave save, ManufacturerOfferOption offer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.pedal_bike_rounded, color: AppColors.accentBlue, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      offer.brandName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: List.generate(
                        offer.brandPrestige,
                        (index) => const Icon(Icons.star_rounded, color: AppColors.primaryGold, size: 14),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        offer.dealTier.label,
                        style: const TextStyle(
                          color: AppColors.accentBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  offer.pitchDescription,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (offer.annualCashContributionEur > 0)
                      Text(
                        '+€${_formatCurrency(offer.annualCashContributionEur)}/rok • ',
                        style: const TextStyle(color: AppColors.statusSuccess, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    if (offer.teamPurchaseCostEur > 0)
                      Text(
                        'Koszt zakupu: €${_formatCurrency(offer.teamPurchaseCostEur)} • ',
                        style: const TextStyle(color: AppColors.powerZone6, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    Text(
                      '${offer.freeBikesQuota} rowerów • R&D ${offer.rdLevel}/100',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _showNegotiateDealDialog(save, offer),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Negocjuj Umowę', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showNegotiateDealDialog(CareerSave save, ManufacturerOfferOption offer) {
    int requestedCash = offer.annualCashContributionEur;
    int requestedBikes = offer.freeBikesQuota;
    int years = 2;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              title: Text('Negocjacje: ${offer.brandName}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Formuła: ${offer.dealTier.label}',
                    style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Text('Długość kontraktu: $years lata', style: const TextStyle(color: AppColors.textPrimary)),
                  Slider(
                    value: years.toDouble(),
                    min: 1,
                    max: 4,
                    divisions: 3,
                    activeColor: AppColors.accentBlue,
                    onChanged: (v) => setDialogState(() => years = v.round()),
                  ),
                  Text('Wkład gotówkowy: €${_formatCurrency(requestedCash)}/rok', style: const TextStyle(color: AppColors.textPrimary)),
                  Slider(
                    value: requestedCash.toDouble(),
                    min: 0,
                    max: math.max(100000.0, offer.annualCashContributionEur * 1.5),
                    divisions: 20,
                    activeColor: AppColors.statusSuccess,
                    onChanged: (v) => setDialogState(() => requestedCash = v.round()),
                  ),
                  Text('Pula rowerów: $requestedBikes sztuk', style: const TextStyle(color: AppColors.textPrimary)),
                  Slider(
                    value: requestedBikes.toDouble(),
                    min: 15,
                    max: 130,
                    divisions: 23,
                    activeColor: AppColors.primaryGold,
                    onChanged: (v) => setDialogState(() => requestedBikes = v.round()),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Anuluj', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _submitProposal(save, offer, requestedCash, requestedBikes, years);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue),
                  child: const Text('Wyślij Ofertę'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitProposal(CareerSave save, ManufacturerOfferOption offer, int cash, int bikes, int years) {
    final proposal = ManufacturerNegotiationProposal(
      brandId: offer.brandId,
      requestedDealTier: offer.dealTier,
      contractYears: years,
      requestedAnnualCashEur: cash,
      requestedBikesCount: bikes,
      proposedPurchaseDiscountRate: offer.discountRate,
      windTunnelCommitment: true,
    );

    final result = ref.read(careerProvider.notifier).submitBikeManufacturerProposal(proposal);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Text(
            result.isAccepted
                ? 'Oferta Zaakceptowana!'
                : (result.isCounterOffer ? 'Kontroferta Producenta' : 'Oferta Odrzucona'),
            style: TextStyle(
              color: result.isAccepted ? AppColors.statusSuccess : (result.isCounterOffer ? AppColors.primaryGold : AppColors.powerZone6),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"${result.commercialDirectorQuote}"',
                style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                'Ogólna nota propozycji: ${result.overallScore.toStringAsFixed(1)} / 100 pkt',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accentBlue),
              ),
              if (result.rejectionReason != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Powód: ${result.rejectionReason}',
                  style: const TextStyle(color: AppColors.powerZone6, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zamknij', style: TextStyle(color: AppColors.textSecondary)),
            ),
            if (result.isAccepted && result.resultingDeal != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(careerProvider.notifier).acceptBikeManufacturerDeal(
                    deal: result.resultingDeal!,
                    dealTier: result.resultingDealTier,
                    initialPurchaseCostEur: result.finalPurchaseCostEur,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.statusSuccess,
                      content: Text('Podpisano nowy kontrakt z ${result.resultingDeal!.manufacturerName}!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusSuccess),
                child: const Text('Podpisz Kontrakt i Dostarcz Flotę'),
              ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // 5. WIDOK: TUNEL AERODYNAMICZNY & BADANIA R&D (TAB 3)
  // ===========================================================================

  Widget _buildWindTunnelView(CareerSave? save) {
    if (save == null) {
      return const Center(child: Text('Brak danych kariery.', style: TextStyle(color: AppColors.textSecondary)));
    }

    final tunnelLevel = save.windTunnelLevel;
    final balance = save.playerTeam.cashBalanceEur;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner infrastruktury tunelu
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cardDark,
                  AppColors.accentBlue.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.air_rounded, color: AppColors.accentBlue, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tunel Aerodynamiczny & Laboratorium CFD',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Poziom placówki w bazie: $tunnelLevel / 3 • Dostępny budżet: €${_formatCurrency(balance)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'KAMPANIE BADAWCZO-ROZWOJOWE (R&D CAMPAIGNS)',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          ...WindTunnelCampaignType.values.map((campaign) {
            final canAfford = balance >= campaign.baseCostEur;
            final hasLevel = tunnelLevel >= campaign.minWindTunnelLevel;
            final canRun = canAfford && hasLevel;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          campaign.description,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Koszt: €${_formatCurrency(campaign.baseCostEur)}',
                              style: TextStyle(
                                color: canAfford ? AppColors.statusSuccess : AppColors.powerZone6,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                            Text(
                              'Zysk CdA: -${(campaign.cdaReduction * 1000).toStringAsFixed(1)} mCdA',
                              style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                            const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                            Text(
                              'Masa ramy: -${campaign.weightReductionGrams}g',
                              style: const TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton(
                    onPressed: canRun ? () => _runWindTunnelTest(campaign) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.cardDark,
                      disabledForegroundColor: AppColors.textMuted,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      !hasLevel ? 'Wymaga Lvl ${campaign.minWindTunnelLevel}' : 'Uruchom Sesję',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _runWindTunnelTest(WindTunnelCampaignType campaign) {
    try {
      final report = ref.read(careerProvider.notifier).conductWindTunnelTest(campaign);

      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.statusSuccess, size: 24),
                SizedBox(width: 8),
                Text('Raport z Tunelu Aerodynamicznego'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${report.chiefAerodynamicistQuote}"',
                  style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 14),
                Text('CdA delta: ${(report.cdaDelta * 1000).toStringAsFixed(1)} mCdA', style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.w700)),
                Text('Masa delta: ${report.weightDeltaGrams} g', style: const TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                const Text('Zaktualizowane maszyny we flocie:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ...report.upgradedFrameNames.map(
                  (name) => Text('• $name', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue),
                child: const Text('Zatwierdź Ulepszenia'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.powerZone6, content: Text('Błąd sesji: $e')),
      );
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }
}

