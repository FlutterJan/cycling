// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/career/equipment_wind_tunnel_custom_decals_and_serials.dart';

/// Epoka technologiczna historycznego roweru w Muzeum Klubowym.
enum MuseumBikeEra {
  steelClassic('Stal Klasyczna', '1970–1995'),
  alloyTransition('Aluminium & Tytan', '1996–2005'),
  carbonAero('Karbon Aero', '2006–2019'),
  modernSuperbike('Hyper-Aero WT', '2020–2026');

  const MuseumBikeEra(this.label, this.yearsSpan);

  final String label;
  final String yearsSpan;
}

/// Kategoria eksponatu w Muzeum Klubowym.
enum MuseumExhibitCategory {
  all('Wszystkie'),
  grandTourWinners('Wielkie Toury'),
  monumentClassics('Monumenty & Bruk'),
  worldChampion('Mistrzowie & Złoto'),
  clubHeritage('Dziedzictwo Klubu');

  const MuseumExhibitCategory(this.label);

  final String label;
}

/// Preset kamery 3D w sali wystawowej muzeum.
enum MuseumCameraPreset {
  threeQuarterFront('3/4 Przód', -0.58, 0.24, 1.02),
  driveSide('Profil Napędu', 0.0, 0.10, 1.06),
  cockpitTop('Kokpit & Aero', -0.95, 0.56, 1.18),
  rearStay('Tylny Trójkąt', 2.48, 0.20, 1.12);

  const MuseumCameraPreset(
    this.label,
    this.yawRad,
    this.pitchRad,
    this.zoom,
  );

  final String label;
  final double yawRad;
  final double pitchRad;
  final double zoom;
}

/// Preset oświetlenia gabloty 3D w Muzeum Klubowym.
enum MuseumLightingPreset {
  gallerySpot('Reflektor Galerii', AppColors.goldAccent, Color(0xFF1A2030)),
  goldenHour('Złota Godzina', Color(0xFFF59E0B), Color(0xFF281D16)),
  carbonStudio('Studio Karbon', AppColors.accentBlue, Color(0xFF141E2B)),
  velodromeNeon('Neon Welodromu', AppColors.cyanAccent, Color(0xFF11222C));

  const MuseumLightingPreset(this.label, this.spotColor, this.ambientTint);

  final String label;
  final Color spotColor;
  final Color ambientTint;
}

/// Aktywna zakładka widoku Muzeum Klubowego.
enum MuseumViewTab {
  bikes3d('Sala Rowerów 3D'),
  relicsArchive('Gabloty & Pamiątki');

  const MuseumViewTab(this.label);

  final String label;
}

/// Interaktywny punkt kontrolny (hotspot) na modelu 3D roweru.
enum BikeHotspotPart {
  frame('Rama & Geometria'),
  cockpit('Kokpit & Kierownica'),
  drivetrain('Napęd & Korba'),
  wheelset('Koła & Ogumienie');

  const BikeHotspotPart(this.label);

  final String label;
}

/// Eksponat historycznego roweru w Muzeum Klubowym.
@immutable
class LegendaryBikeExhibit {
  const LegendaryBikeExhibit({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.year,
    required this.era,
    required this.category,
    required this.editionType,
    required this.serialNumber,
    required this.riderName,
    required this.historicAchievement,
    required this.raceName,
    required this.stageOrLocation,
    required this.frameMaterial,
    required this.groupsetName,
    required this.wheelsetName,
    required this.weightKg,
    required this.cdaValue,
    required this.peakPowerWatts,
    required this.totalKmRidden,
    required this.frameColor,
    required this.accentColor,
    required this.rimDepthMm,
    required this.isTanWall,
    required this.isDiscBrake,
    required this.isDowntubeShifter,
    required this.hasAeroSeatpost,
    required this.curatorialNote,
    required this.hotspotDetails,
    this.provenanceVerified = true,
    this.isFromClubGarage = false,
  });

  final String id;
  final String name;
  final String manufacturer;
  final int year;
  final MuseumBikeEra era;
  final MuseumExhibitCategory category;
  final ChampionshipEditionType editionType;
  final String serialNumber;
  final String riderName;
  final String historicAchievement;
  final String raceName;
  final String stageOrLocation;
  final String frameMaterial;
  final String groupsetName;
  final String wheelsetName;
  final double weightKg;
  final double cdaValue;
  final int peakPowerWatts;
  final int totalKmRidden;
  final Color frameColor;
  final Color accentColor;
  final double rimDepthMm;
  final bool isTanWall;
  final bool isDiscBrake;
  final bool isDowntubeShifter;
  final bool hasAeroSeatpost;
  final String curatorialNote;
  final Map<BikeHotspotPart, String> hotspotDetails;
  final bool provenanceVerified;
  final bool isFromClubGarage;
}

/// Pamiątka / Trofeum w archiwalnej gablocie Muzeum Klubowego.
@immutable
class MuseumTrophyRelic {
  const MuseumTrophyRelic({
    required this.id,
    required this.title,
    required this.year,
    required this.raceName,
    required this.riderName,
    required this.categoryLabel,
    required this.description,
    required this.accentColor,
    required this.icon,
    required this.heritagePoints,
  });

  final String id;
  final String title;
  final int year;
  final String raceName;
  final String riderName;
  final String categoryLabel;
  final String description;
  final Color accentColor;
  final IconData icon;
  final int heritagePoints;
}

/// Stan Muzeum Klubowego i Historycznych Rowerów 3D.
@immutable
class ClubMuseumState {
  const ClubMuseumState({
    required this.exhibits,
    required this.relics,
    required this.selectedExhibitId,
    required this.activeTab,
    required this.eraFilter,
    required this.categoryFilter,
    required this.searchQuery,
    required this.cameraPreset,
    required this.lightingPreset,
    required this.autoRotate,
    required this.showHotspots,
    required this.activeHotspot,
    required this.pinnedExhibitIds,
    required this.restorationProgress,
  });

  final List<LegendaryBikeExhibit> exhibits;
  final List<MuseumTrophyRelic> relics;
  final String selectedExhibitId;
  final MuseumViewTab activeTab;
  final MuseumBikeEra? eraFilter;
  final MuseumExhibitCategory categoryFilter;
  final String searchQuery;
  final MuseumCameraPreset cameraPreset;
  final MuseumLightingPreset lightingPreset;
  final bool autoRotate;
  final bool showHotspots;
  final BikeHotspotPart activeHotspot;
  final Set<String> pinnedExhibitIds;
  final Map<String, int> restorationProgress;

  List<LegendaryBikeExhibit> get filteredExhibits {
    final query = searchQuery.trim().toLowerCase();
    return exhibits.where((item) {
      if (eraFilter != null && item.era != eraFilter) {
        return false;
      }
      if (categoryFilter != MuseumExhibitCategory.all &&
          item.category != categoryFilter) {
        return false;
      }
      if (query.isNotEmpty) {
        final haystack =
            '${item.name} ${item.manufacturer} ${item.riderName} ${item.raceName} ${item.serialNumber} ${item.year}'
                .toLowerCase();
        if (!haystack.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);
  }

  LegendaryBikeExhibit get selectedExhibit {
    for (final item in exhibits) {
      if (item.id == selectedExhibitId) {
        return item;
      }
    }
    return exhibits.first;
  }

  int get totalHeritageScore {
    final bikeScore = exhibits.length * 180;
    final restoredBonus =
        restorationProgress.values.where((v) => v >= 100).length * 90;
    final relicScore =
        relics.fold<int>(0, (sum, r) => sum + r.heritagePoints);
    return bikeScore + restoredBonus + relicScore;
  }

  ClubMuseumState copyWith({
    List<LegendaryBikeExhibit>? exhibits,
    List<MuseumTrophyRelic>? relics,
    String? selectedExhibitId,
    MuseumViewTab? activeTab,
    MuseumBikeEra? eraFilter,
    bool clearEraFilter = false,
    MuseumExhibitCategory? categoryFilter,
    String? searchQuery,
    MuseumCameraPreset? cameraPreset,
    MuseumLightingPreset? lightingPreset,
    bool? autoRotate,
    bool? showHotspots,
    BikeHotspotPart? activeHotspot,
    Set<String>? pinnedExhibitIds,
    Map<String, int>? restorationProgress,
  }) {
    return ClubMuseumState(
      exhibits: exhibits ?? this.exhibits,
      relics: relics ?? this.relics,
      selectedExhibitId: selectedExhibitId ?? this.selectedExhibitId,
      activeTab: activeTab ?? this.activeTab,
      eraFilter: clearEraFilter ? null : (eraFilter ?? this.eraFilter),
      categoryFilter: categoryFilter ?? this.categoryFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      cameraPreset: cameraPreset ?? this.cameraPreset,
      lightingPreset: lightingPreset ?? this.lightingPreset,
      autoRotate: autoRotate ?? this.autoRotate,
      showHotspots: showHotspots ?? this.showHotspots,
      activeHotspot: activeHotspot ?? this.activeHotspot,
      pinnedExhibitIds: pinnedExhibitIds ?? this.pinnedExhibitIds,
      restorationProgress: restorationProgress ?? this.restorationProgress,
    );
  }
}

/// Kontroler stanu Muzeum Klubowego i Historycznych Rowerów 3D.
class ClubMuseumNotifier extends StateNotifier<ClubMuseumState> {
  ClubMuseumNotifier({List<CustomFrameSerialRecord> garageRecords = const []})
      : super(_buildInitialState(garageRecords));

  static ClubMuseumState _buildInitialState(
    List<CustomFrameSerialRecord> garageRecords,
  ) {
    final baseExhibits = List<LegendaryBikeExhibit>.from(_defaultExhibits);

    for (final record in garageRecords) {
      if (record.status == SerialFrameStatus.museumArchived ||
          record.editionType.isGoldMasterEdition) {
        final alreadyPresent = baseExhibits.any(
          (e) => e.serialNumber == record.serialNumber,
        );
        if (!alreadyPresent) {
          baseExhibits.add(
            LegendaryBikeExhibit(
              id: 'garage_${record.serialNumber}',
              name: '${record.frameModelName} (${record.editionType.shortCode})',
              manufacturer: record.manufacturerName,
              year: record.commissionedDate.year,
              era: MuseumBikeEra.modernSuperbike,
              category: MuseumExhibitCategory.clubHeritage,
              editionType: record.editionType,
              serialNumber: record.serialNumber,
              riderName: record.assignedRiderName ?? 'Kolarz Klubu',
              historicAchievement: record.customTopTubeInscription.isNotEmpty
                  ? record.customTopTubeInscription
                  : 'Zarchiwizowana rama mistrzowska z parku maszyn klubu',
              raceName: record.editionType.label,
              stageOrLocation: 'Archiwum Tunelu Aero',
              frameMaterial: 'Karbon T1100 1K (Edycja Serializowana)',
              groupsetName: 'Elektroniczna 12-rzędowa WorldTour',
              wheelsetName: 'Karbonowe Stożki 52mm Ceramic',
              weightKg: 6.82,
              cdaValue: record.windTunnelCdA,
              peakPowerWatts: 1380,
              totalKmRidden: record.kilometersRidden.round(),
              frameColor: record.editionType.primaryDecalColor,
              accentColor: record.editionType.accentDecalColor,
              rimDepthMm: 52,
              isTanWall: true,
              isDiscBrake: true,
              isDowntubeShifter: false,
              hasAeroSeatpost: true,
              curatorialNote:
                  'Egzemplarz przekazany bezpośrednio z działu R&D klubu po przypisaniu indywidualnego numeru seryjnego i kalkomanii mistrzowskich.',
              hotspotDetails: <BikeHotspotPart, String>{
                BikeHotspotPart.frame:
                    'Rama nr ${record.serialNumber} w wykończeniu ${record.finishStyle.label}.',
                BikeHotspotPart.cockpit:
                    'Zintegrowany kokpit monocoque zoptymalizowany pod pozycję wyścigową.',
                BikeHotspotPart.drivetrain:
                    'Łańcuch woskowany o niskim tarciu i korba z pomiarem mocy.',
                BikeHotspotPart.wheelset:
                    'Stożek 52 mm z oponami 28 mm na mleczku bezdętkowym.',
              },
              isFromClubGarage: true,
            ),
          );
        }
      }
    }

    final initialRestoration = <String, int>{
      for (final exhibit in baseExhibits)
        exhibit.id: exhibit.era == MuseumBikeEra.modernSuperbike ? 100 : 85,
    };
    initialRestoration['exhibit_1974_molteni'] = 72;
    initialRestoration['exhibit_2012_roubaix'] = 92;

    return ClubMuseumState(
      exhibits: baseExhibits,
      relics: _defaultRelics,
      selectedExhibitId: baseExhibits.first.id,
      activeTab: MuseumViewTab.bikes3d,
      eraFilter: null,
      categoryFilter: MuseumExhibitCategory.all,
      searchQuery: '',
      cameraPreset: MuseumCameraPreset.threeQuarterFront,
      lightingPreset: MuseumLightingPreset.gallerySpot,
      autoRotate: false,
      showHotspots: true,
      activeHotspot: BikeHotspotPart.frame,
      pinnedExhibitIds: {baseExhibits.first.id},
      restorationProgress: initialRestoration,
    );
  }

  void selectExhibit(String id) {
    if (state.exhibits.any((e) => e.id == id)) {
      state = state.copyWith(selectedExhibitId: id);
    }
  }

  void setActiveTab(MuseumViewTab tab) {
    state = state.copyWith(activeTab: tab);
  }

  void setEraFilter(MuseumBikeEra? era) {
    if (era == null || state.eraFilter == era) {
      state = state.copyWith(clearEraFilter: true);
    } else {
      state = state.copyWith(eraFilter: era);
    }
    _ensureValidSelection();
  }

  void setCategoryFilter(MuseumExhibitCategory category) {
    state = state.copyWith(categoryFilter: category);
    _ensureValidSelection();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _ensureValidSelection();
  }

  void resetFilters() {
    state = state.copyWith(
      clearEraFilter: true,
      categoryFilter: MuseumExhibitCategory.all,
      searchQuery: '',
    );
    _ensureValidSelection();
  }

  void setCameraPreset(MuseumCameraPreset preset) {
    state = state.copyWith(cameraPreset: preset);
  }

  void setLightingPreset(MuseumLightingPreset preset) {
    state = state.copyWith(lightingPreset: preset);
  }

  void toggleAutoRotate() {
    state = state.copyWith(autoRotate: !state.autoRotate);
  }

  void toggleHotspots() {
    state = state.copyWith(showHotspots: !state.showHotspots);
  }

  void selectHotspot(BikeHotspotPart part) {
    state = state.copyWith(activeHotspot: part);
  }

  void togglePinToLobby(String exhibitId) {
    final updated = Set<String>.from(state.pinnedExhibitIds);
    if (updated.contains(exhibitId)) {
      updated.remove(exhibitId);
    } else {
      if (updated.length >= 3) {
        updated.remove(updated.first);
      }
      updated.add(exhibitId);
    }
    state = state.copyWith(pinnedExhibitIds: updated);
  }

  void polishExhibit(String exhibitId) {
    final current = state.restorationProgress[exhibitId] ?? 80;
    if (current >= 100) return;
    final next = math.min(100, current + 15);
    final updated = Map<String, int>.from(state.restorationProgress);
    updated[exhibitId] = next;
    state = state.copyWith(restorationProgress: updated);
  }

  void _ensureValidSelection() {
    final filtered = state.filteredExhibits;
    if (filtered.isEmpty) return;
    if (!filtered.any((e) => e.id == state.selectedExhibitId)) {
      state = state.copyWith(selectedExhibitId: filtered.first.id);
    }
  }
}

/// Provider stanu Muzeum Klubowego i Historycznych Rowerów 3D.
final clubMuseumProvider =
    StateNotifierProvider<ClubMuseumNotifier, ClubMuseumState>((ref) {
  final decalsState = ref.watch(equipmentWindTunnelDecalsProvider);
  return ClubMuseumNotifier(garageRecords: decalsState.frames);
});

/// Ekran Muzeum Klubowego i Historycznych Rowerów 3D.
///
/// Prezentuje interaktywną obrotową salę wystawową 3D z projekcją perspektywiczną
/// historycznych maszyn kolarskich, presetami kamer i oświetlenia, punktami
/// inspekcji komponentów, konserwacją eksponatów oraz archiwum pamiątek klubu.
class ClubMuseumAndLegendaryBikesScreen extends ConsumerStatefulWidget {
  const ClubMuseumAndLegendaryBikesScreen({
    super.key,
    this.initialExhibitId,
  });

  final String? initialExhibitId;

  @override
  ConsumerState<ClubMuseumAndLegendaryBikesScreen> createState() =>
      _ClubMuseumAndLegendaryBikesScreenState();
}

class _ClubMuseumAndLegendaryBikesScreenState
    extends ConsumerState<ClubMuseumAndLegendaryBikesScreen>
    with TickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final AnimationController _cameraTweenController;
  late final AnimationController _turntableController;

  double _yawRad = MuseumCameraPreset.threeQuarterFront.yawRad;
  double _pitchRad = MuseumCameraPreset.threeQuarterFront.pitchRad;
  double _zoom = MuseumCameraPreset.threeQuarterFront.zoom;

  double _animStartYaw = MuseumCameraPreset.threeQuarterFront.yawRad;
  double _animTargetYaw = MuseumCameraPreset.threeQuarterFront.yawRad;
  double _animStartPitch = MuseumCameraPreset.threeQuarterFront.pitchRad;
  double _animTargetPitch = MuseumCameraPreset.threeQuarterFront.pitchRad;
  double _animStartZoom = MuseumCameraPreset.threeQuarterFront.zoom;
  double _animTargetZoom = MuseumCameraPreset.threeQuarterFront.zoom;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _cameraTweenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(_onCameraTweenTick);

    _turntableController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..addListener(_onTurntableTick);

    if (widget.initialExhibitId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(clubMuseumProvider.notifier)
              .selectExhibit(widget.initialExhibitId!);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cameraTweenController.removeListener(_onCameraTweenTick);
    _cameraTweenController.dispose();
    _turntableController.removeListener(_onTurntableTick);
    _turntableController.dispose();
    super.dispose();
  }

  void _onCameraTweenTick() {
    final t = Curves.easeOutCubic.transform(_cameraTweenController.value);
    setState(() {
      _yawRad = _animStartYaw + (_animTargetYaw - _animStartYaw) * t;
      _pitchRad = _animStartPitch + (_animTargetPitch - _animStartPitch) * t;
      _zoom = _animStartZoom + (_animTargetZoom - _animStartZoom) * t;
    });
  }

  void _onTurntableTick() {
    if (!mounted) return;
    setState(() {
      _yawRad = (_yawRad + 0.012) % (math.pi * 2);
    });
  }

  void _animateToCamera(MuseumCameraPreset preset) {
    ref.read(clubMuseumProvider.notifier).setCameraPreset(preset);
    _animStartYaw = _yawRad;
    _animTargetYaw = preset.yawRad;
    _animStartPitch = _pitchRad;
    _animTargetPitch = preset.pitchRad;
    _animStartZoom = _zoom;
    _animTargetZoom = preset.zoom;
    _cameraTweenController.forward(from: 0.0);
  }

  void _handleAutoRotateToggle() {
    final notifier = ref.read(clubMuseumProvider.notifier);
    notifier.toggleAutoRotate();
    final nextAuto = ref.read(clubMuseumProvider).autoRotate;
    if (nextAuto) {
      _turntableController.repeat();
    } else {
      _turntableController.stop();
    }
  }

  void _handleOrbitDrag(DragUpdateDetails details) {
    if (ref.read(clubMuseumProvider).autoRotate) {
      _turntableController.stop();
      ref.read(clubMuseumProvider.notifier).toggleAutoRotate();
    }
    setState(() {
      _yawRad = (_yawRad + details.delta.dx * 0.012) % (math.pi * 2);
      _pitchRad = (_pitchRad + details.delta.dy * 0.008).clamp(-0.15, 0.72);
    });
  }

  void _handleZoomChange(double nextZoom) {
    setState(() {
      _zoom = nextZoom.clamp(0.75, 1.45);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clubMuseumProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 1200;
            final isTablet = width >= 700 && width < 1200;

            return Column(
              children: [
                _MuseumTopHeader(
                  state: state,
                  searchController: _searchController,
                  isCompact: width < 700,
                  onTabChanged: (tab) =>
                      ref.read(clubMuseumProvider.notifier).setActiveTab(tab),
                  onSearchChanged: (q) =>
                      ref.read(clubMuseumProvider.notifier).setSearchQuery(q),
                  onClearFilters: () {
                    _searchController.clear();
                    ref.read(clubMuseumProvider.notifier).resetFilters();
                  },
                ),
                const Divider(height: 1, color: AppTheme.borderColor),
                Expanded(
                  child: state.activeTab == MuseumViewTab.relicsArchive
                      ? _RelicsArchiveView(
                          relics: state.relics,
                          exhibitsCount: state.exhibits.length,
                          heritageScore: state.totalHeritageScore,
                          isDesktop: isDesktop,
                          isTablet: isTablet,
                        )
                      : _buildBikesHallBody(
                          state: state,
                          isDesktop: isDesktop,
                          isTablet: isTablet,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBikesHallBody({
    required ClubMuseumState state,
    required bool isDesktop,
    required bool isTablet,
  }) {
    final filtered = state.filteredExhibits;
    final selected = state.selectedExhibit;
    final restoration = state.restorationProgress[selected.id] ?? 100;
    final isPinned = state.pinnedExhibitIds.contains(selected.id);

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 310,
              child: _ExhibitCatalogPanel(
                exhibits: filtered,
                selectedId: selected.id,
                pinnedIds: state.pinnedExhibitIds,
                eraFilter: state.eraFilter,
                categoryFilter: state.categoryFilter,
                onSelectExhibit: (id) =>
                    ref.read(clubMuseumProvider.notifier).selectExhibit(id),
                onEraFilter: (era) =>
                    ref.read(clubMuseumProvider.notifier).setEraFilter(era),
                onCategoryFilter: (cat) =>
                    ref.read(clubMuseumProvider.notifier).setCategoryFilter(cat),
                onResetFilters: () {
                  _searchController.clear();
                  ref.read(clubMuseumProvider.notifier).resetFilters();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _Museum3dShowcasePanel(
                exhibit: selected,
                state: state,
                yawRad: _yawRad,
                pitchRad: _pitchRad,
                zoom: _zoom,
                onOrbitDrag: _handleOrbitDrag,
                onZoomChanged: _handleZoomChange,
                onCameraPreset: _animateToCamera,
                onLightingPreset: (preset) => ref
                    .read(clubMuseumProvider.notifier)
                    .setLightingPreset(preset),
                onToggleAutoRotate: _handleAutoRotateToggle,
                onToggleHotspots: () =>
                    ref.read(clubMuseumProvider.notifier).toggleHotspots(),
                onSelectHotspot: (part) =>
                    ref.read(clubMuseumProvider.notifier).selectHotspot(part),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 340,
              child: _CuratorialDossierPanel(
                exhibit: selected,
                restorationPercent: restoration,
                isPinned: isPinned,
                pinnedCount: state.pinnedExhibitIds.length,
                activeHotspot: state.activeHotspot,
                onTogglePin: () => ref
                    .read(clubMuseumProvider.notifier)
                    .togglePinToLobby(selected.id),
                onPolish: () => ref
                    .read(clubMuseumProvider.notifier)
                    .polishExhibit(selected.id),
              ),
            ),
          ],
        ),
      );
    }

    if (isTablet) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FilterRibbonBar(
              eraFilter: state.eraFilter,
              categoryFilter: state.categoryFilter,
              onEraFilter: (era) =>
                  ref.read(clubMuseumProvider.notifier).setEraFilter(era),
              onCategoryFilter: (cat) =>
                  ref.read(clubMuseumProvider.notifier).setCategoryFilter(cat),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 460,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 6,
                    child: _Museum3dShowcasePanel(
                      exhibit: selected,
                      state: state,
                      yawRad: _yawRad,
                      pitchRad: _pitchRad,
                      zoom: _zoom,
                      onOrbitDrag: _handleOrbitDrag,
                      onZoomChanged: _handleZoomChange,
                      onCameraPreset: _animateToCamera,
                      onLightingPreset: (preset) => ref
                          .read(clubMuseumProvider.notifier)
                          .setLightingPreset(preset),
                      onToggleAutoRotate: _handleAutoRotateToggle,
                      onToggleHotspots: () => ref
                          .read(clubMuseumProvider.notifier)
                          .toggleHotspots(),
                      onSelectHotspot: (part) => ref
                          .read(clubMuseumProvider.notifier)
                          .selectHotspot(part),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: _CuratorialDossierPanel(
                      exhibit: selected,
                      restorationPercent: restoration,
                      isPinned: isPinned,
                      pinnedCount: state.pinnedExhibitIds.length,
                      activeHotspot: state.activeHotspot,
                      onTogglePin: () => ref
                          .read(clubMuseumProvider.notifier)
                          .togglePinToLobby(selected.id),
                      onPolish: () => ref
                          .read(clubMuseumProvider.notifier)
                          .polishExhibit(selected.id),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _HorizontalExhibitStrip(
              exhibits: filtered,
              selectedId: selected.id,
              pinnedIds: state.pinnedExhibitIds,
              onSelectExhibit: (id) =>
                  ref.read(clubMuseumProvider.notifier).selectExhibit(id),
              onResetFilters: () {
                _searchController.clear();
                ref.read(clubMuseumProvider.notifier).resetFilters();
              },
            ),
          ],
        ),
      );
    }

    // Mobile (< 700px, np. 390x844)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FilterRibbonBar(
            eraFilter: state.eraFilter,
            categoryFilter: state.categoryFilter,
            onEraFilter: (era) =>
                ref.read(clubMuseumProvider.notifier).setEraFilter(era),
            onCategoryFilter: (cat) =>
                ref.read(clubMuseumProvider.notifier).setCategoryFilter(cat),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 360,
            child: _Museum3dShowcasePanel(
              exhibit: selected,
              state: state,
              yawRad: _yawRad,
              pitchRad: _pitchRad,
              zoom: _zoom,
              isCompact: true,
              onOrbitDrag: _handleOrbitDrag,
              onZoomChanged: _handleZoomChange,
              onCameraPreset: _animateToCamera,
              onLightingPreset: (preset) => ref
                  .read(clubMuseumProvider.notifier)
                  .setLightingPreset(preset),
              onToggleAutoRotate: _handleAutoRotateToggle,
              onToggleHotspots: () =>
                  ref.read(clubMuseumProvider.notifier).toggleHotspots(),
              onSelectHotspot: (part) =>
                  ref.read(clubMuseumProvider.notifier).selectHotspot(part),
            ),
          ),
          const SizedBox(height: 12),
          _HorizontalExhibitStrip(
            exhibits: filtered,
            selectedId: selected.id,
            pinnedIds: state.pinnedExhibitIds,
            onSelectExhibit: (id) =>
                ref.read(clubMuseumProvider.notifier).selectExhibit(id),
            onResetFilters: () {
              _searchController.clear();
              ref.read(clubMuseumProvider.notifier).resetFilters();
            },
          ),
          const SizedBox(height: 12),
          _CuratorialDossierPanel(
            exhibit: selected,
            restorationPercent: restoration,
            isPinned: isPinned,
            pinnedCount: state.pinnedExhibitIds.length,
            activeHotspot: state.activeHotspot,
            isScrollableEmbedded: true,
            onTogglePin: () => ref
                .read(clubMuseumProvider.notifier)
                .togglePinToLobby(selected.id),
            onPolish: () => ref
                .read(clubMuseumProvider.notifier)
                .polishExhibit(selected.id),
          ),
        ],
      ),
    );
  }
}

/// Górny pasek nagłówka Muzeum Klubowego.
class _MuseumTopHeader extends StatelessWidget {
  const _MuseumTopHeader({
    required this.state,
    required this.searchController,
    required this.isCompact,
    required this.onTabChanged,
    required this.onSearchChanged,
    required this.onClearFilters,
  });

  final ClubMuseumState state;
  final TextEditingController searchController;
  final bool isCompact;
  final ValueChanged<MuseumViewTab> onTabChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: isCompact ? 10 : 14,
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _buildBrandBadge(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Muzeum Klubowe 3D',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            '${state.exhibits.length} maszyn • ${state.totalHeritageScore} pkt dziedzictwa',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.statNumberStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.goldAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildTabSwitcher()),
                  ],
                ),
                if (state.activeTab == MuseumViewTab.bikes3d) ...[
                  const SizedBox(height: 8),
                  _buildSearchField(),
                ],
              ],
            )
          : Row(
              children: [
                _buildBrandBadge(),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Muzeum Klubowe & Historyczne Rowery 3D',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Eksponaty: ${state.exhibits.length}',
                            style: AppTheme.statNumberStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppColors.goldAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            'Prestiż Dziedzictwa: ${state.totalHeritageScore} pkt',
                            style: AppTheme.statNumberStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (state.activeTab == MuseumViewTab.bikes3d) ...[
                  SizedBox(width: 240, child: _buildSearchField()),
                  const SizedBox(width: 12),
                ],
                _buildTabSwitcher(),
              ],
            ),
    );
  }

  Widget _buildBrandBadge() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.45),
        ),
      ),
      child: const Icon(
        Icons.museum_outlined,
        color: AppColors.goldAccent,
        size: 22,
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: MuseumViewTab.values.map((tab) {
          final isSelected = state.activeTab == tab;
          return Expanded(
            flex: isCompact ? 1 : 0,
            child: _MuseumInteractiveButton(
              label: tab.label,
              icon: tab == MuseumViewTab.bikes3d
                  ? Icons.directions_bike_rounded
                  : Icons.emoji_events_outlined,
              isActive: isSelected,
              activeColor: AppColors.goldAccent,
              compact: true,
              onPressed: () => onTabChanged(tab),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Szukaj modelu, kolarza, S/N...',
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Wyczyść filtry',
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: onClearFilters,
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          filled: true,
          fillColor: AppColors.surfaceLight,
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
            borderSide:
                const BorderSide(color: AppColors.goldAccent, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Pasek poziomych filtrów dla tabletu i telefonu.
class _FilterRibbonBar extends StatelessWidget {
  const _FilterRibbonBar({
    required this.eraFilter,
    required this.categoryFilter,
    required this.onEraFilter,
    required this.onCategoryFilter,
  });

  final MuseumBikeEra? eraFilter;
  final MuseumExhibitCategory categoryFilter;
  final ValueChanged<MuseumBikeEra?> onEraFilter;
  final ValueChanged<MuseumExhibitCategory> onCategoryFilter;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...MuseumExhibitCategory.values.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _MuseumInteractiveButton(
                label: cat.label,
                isActive: categoryFilter == cat,
                activeColor: AppColors.goldAccent,
                compact: true,
                onPressed: () => onCategoryFilter(cat),
              ),
            );
          }),
          const SizedBox(width: 6),
          Container(width: 1, height: 22, color: AppTheme.borderColor),
          const SizedBox(width: 10),
          ...MuseumBikeEra.values.map((era) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _MuseumInteractiveButton(
                label: era.yearsSpan,
                isActive: eraFilter == era,
                activeColor: AppColors.accentBlue,
                compact: true,
                onPressed: () => onEraFilter(era),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Lewy panel katalogu eksponatów na desktopie.
class _ExhibitCatalogPanel extends StatelessWidget {
  const _ExhibitCatalogPanel({
    required this.exhibits,
    required this.selectedId,
    required this.pinnedIds,
    required this.eraFilter,
    required this.categoryFilter,
    required this.onSelectExhibit,
    required this.onEraFilter,
    required this.onCategoryFilter,
    required this.onResetFilters,
  });

  final List<LegendaryBikeExhibit> exhibits;
  final String selectedId;
  final Set<String> pinnedIds;
  final MuseumBikeEra? eraFilter;
  final MuseumExhibitCategory categoryFilter;
  final ValueChanged<String> onSelectExhibit;
  final ValueChanged<MuseumBikeEra?> onEraFilter;
  final ValueChanged<MuseumExhibitCategory> onCategoryFilter;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.collections_bookmark_outlined,
                      size: 16,
                      color: AppColors.goldAccent,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Katalog Eksponatów',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${exhibits.length}',
                      style: AppTheme.statNumberStyle(
                        fontSize: 12,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: MuseumExhibitCategory.values.map((cat) {
                    return _MuseumInteractiveButton(
                      label: cat.label,
                      isActive: categoryFilter == cat,
                      activeColor: AppColors.goldAccent,
                      compact: true,
                      onPressed: () => onCategoryFilter(cat),
                    );
                  }).toList(growable: false),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: MuseumBikeEra.values.map((era) {
                    return _MuseumInteractiveButton(
                      label: era.yearsSpan,
                      isActive: eraFilter == era,
                      activeColor: AppColors.accentBlue,
                      compact: true,
                      onPressed: () => onEraFilter(era),
                    );
                  }).toList(growable: false),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          Expanded(
            child: exhibits.isEmpty
                ? _EmptyExhibitsPlaceholder(onReset: onResetFilters)
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: exhibits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = exhibits[index];
                      return _ExhibitCatalogCard(
                        exhibit: item,
                        isSelected: item.id == selectedId,
                        isPinned: pinnedIds.contains(item.id),
                        onTap: () => onSelectExhibit(item.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Poziomy pasek wyboru eksponatów dla tabletu i telefonu.
class _HorizontalExhibitStrip extends StatelessWidget {
  const _HorizontalExhibitStrip({
    required this.exhibits,
    required this.selectedId,
    required this.pinnedIds,
    required this.onSelectExhibit,
    required this.onResetFilters,
  });

  final List<LegendaryBikeExhibit> exhibits;
  final String selectedId;
  final Set<String> pinnedIds;
  final ValueChanged<String> onSelectExhibit;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    if (exhibits.isEmpty) {
      return Container(
        height: 112,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: _EmptyExhibitsPlaceholder(onReset: onResetFilters),
      );
    }

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: exhibits.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = exhibits[index];
          return SizedBox(
            width: 240,
            child: _ExhibitCatalogCard(
              exhibit: item,
              isSelected: item.id == selectedId,
              isPinned: pinnedIds.contains(item.id),
              onTap: () => onSelectExhibit(item.id),
            ),
          );
        },
      ),
    );
  }
}

/// Karta pojedynczego eksponatu w katalogu z pełnymi stanami hover/active/focus.
class _ExhibitCatalogCard extends StatefulWidget {
  const _ExhibitCatalogCard({
    required this.exhibit,
    required this.isSelected,
    required this.isPinned,
    required this.onTap,
  });

  final LegendaryBikeExhibit exhibit;
  final bool isSelected;
  final bool isPinned;
  final VoidCallback onTap;

  @override
  State<_ExhibitCatalogCard> createState() => _ExhibitCatalogCardState();
}

class _ExhibitCatalogCardState extends State<_ExhibitCatalogCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? AppColors.goldAccent
        : _isFocused
            ? AppColors.accentBlue
            : _isHovered
                ? AppColors.textSecondary.withValues(alpha: 0.45)
                : AppTheme.borderColor;

    final bgColor = widget.isSelected
        ? AppColors.goldAccent.withValues(alpha: 0.12)
        : _isHovered
            ? AppColors.surfaceLight
            : AppColors.background.withValues(alpha: 0.55);

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: widget.exhibit.frameColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.exhibit.accentColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${widget.exhibit.year}',
                      style: AppTheme.statNumberStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: widget.isSelected
                            ? AppColors.goldAccent
                            : AppColors.accentBlue,
                      ),
                    ),
                    const Spacer(),
                    if (widget.isPinned)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.push_pin_rounded,
                          size: 13,
                          color: AppColors.goldAccent,
                        ),
                      ),
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
                        widget.exhibit.editionType.shortCode,
                        style: AppTheme.statNumberStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: widget.exhibit.editionType.isGoldMasterEdition
                              ? AppColors.goldAccent
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.exhibit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.exhibit.riderName} • ${widget.exhibit.raceName}',
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
        ),
      ),
    );
  }
}

/// Centralny panel interaktywnej sali wystawowej 3D z obrotową platformą.
class _Museum3dShowcasePanel extends StatelessWidget {
  const _Museum3dShowcasePanel({
    required this.exhibit,
    required this.state,
    required this.yawRad,
    required this.pitchRad,
    required this.zoom,
    required this.onOrbitDrag,
    required this.onZoomChanged,
    required this.onCameraPreset,
    required this.onLightingPreset,
    required this.onToggleAutoRotate,
    required this.onToggleHotspots,
    required this.onSelectHotspot,
    this.isCompact = false,
  });

  final LegendaryBikeExhibit exhibit;
  final ClubMuseumState state;
  final double yawRad;
  final double pitchRad;
  final double zoom;
  final GestureDragUpdateCallback onOrbitDrag;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<MuseumCameraPreset> onCameraPreset;
  final ValueChanged<MuseumLightingPreset> onLightingPreset;
  final VoidCallback onToggleAutoRotate;
  final VoidCallback onToggleHotspots;
  final ValueChanged<BikeHotspotPart> onSelectHotspot;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Górny pasek kamery i oświetlenia
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: MuseumCameraPreset.values.map((preset) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _MuseumInteractiveButton(
                            label: preset.label,
                            isActive: state.cameraPreset == preset,
                            activeColor: AppColors.goldAccent,
                            compact: true,
                            onPressed: () => onCameraPreset(preset),
                          ),
                        );
                      }).toList(growable: false),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _MuseumInteractiveButton(
                  label: isCompact ? '360°' : 'Auto-Obrót 360°',
                  icon: Icons.threesixty_rounded,
                  isActive: state.autoRotate,
                  activeColor: AppColors.cyanAccent,
                  compact: true,
                  onPressed: onToggleAutoRotate,
                ),
                const SizedBox(width: 6),
                _MuseumInteractiveButton(
                  label: isCompact ? 'Punkty' : 'Hotspoty',
                  icon: Icons.adjust_rounded,
                  isActive: state.showHotspots,
                  activeColor: AppColors.accentBlue,
                  compact: true,
                  onPressed: onToggleHotspots,
                ),
              ],
            ),
          ),
          // Scena 3D
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: onOrbitDrag,
                  child: CustomPaint(
                    painter: _LegendaryBike3dPainter(
                      exhibit: exhibit,
                      yawRad: yawRad,
                      pitchRad: pitchRad,
                      zoom: zoom,
                      lighting: state.lightingPreset,
                      showHotspots: state.showHotspots,
                      activeHotspot: state.activeHotspot,
                    ),
                  ),
                ),
                // Narożna plakietka S/N i modelu
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: exhibit.editionType.isGoldMasterEdition
                            ? AppColors.goldAccent.withValues(alpha: 0.6)
                            : AppTheme.borderColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exhibit.serialNumber,
                          style: AppTheme.statNumberStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldAccent,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${exhibit.manufacturer} • ${exhibit.year}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Podpowiedź obrotu 3D
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.open_with_rounded,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Przeciągnij, aby obrócić 3D',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Selektor hotspotów na dole sceny
                if (state.showHotspots)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: BikeHotspotPart.values.map((part) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _MuseumInteractiveButton(
                              label: part.label,
                              isActive: state.activeHotspot == part,
                              activeColor: AppColors.accentBlue,
                              compact: true,
                              onPressed: () => onSelectHotspot(part),
                            ),
                          );
                        }).toList(growable: false),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Dolny pasek oświetlenia i zoomu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              border: Border(
                top: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: MuseumLightingPreset.values.map((preset) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _MuseumInteractiveButton(
                            label: preset.label,
                            isActive: state.lightingPreset == preset,
                            activeColor: preset.spotColor,
                            compact: true,
                            onPressed: () => onLightingPreset(preset),
                          ),
                        );
                      }).toList(growable: false),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.zoom_in_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                SizedBox(
                  width: isCompact ? 80 : 110,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2.5,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: AppColors.goldAccent,
                      inactiveTrackColor: AppTheme.borderColor,
                      thumbColor: AppColors.goldAccent,
                    ),
                    child: Slider(
                      value: zoom.clamp(0.75, 1.45),
                      min: 0.75,
                      max: 1.45,
                      onChanged: onZoomChanged,
                    ),
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

/// Prawy panel dokumentacji kuratorskiej, telemetrii i akcji konserwacyjnych.
class _CuratorialDossierPanel extends StatelessWidget {
  const _CuratorialDossierPanel({
    required this.exhibit,
    required this.restorationPercent,
    required this.isPinned,
    required this.pinnedCount,
    required this.activeHotspot,
    required this.onTogglePin,
    required this.onPolish,
    this.isScrollableEmbedded = false,
  });

  final LegendaryBikeExhibit exhibit;
  final int restorationPercent;
  final bool isPinned;
  final int pinnedCount;
  final BikeHotspotPart activeHotspot;
  final VoidCallback onTogglePin;
  final VoidCallback onPolish;
  final bool isScrollableEmbedded;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: isScrollableEmbedded ? MainAxisSize.min : MainAxisSize.max,
      children: [
        // Nagłówek eksponatu
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exhibit.editionType.label.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.goldAccent,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    exhibit.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            if (exhibit.provenanceVerified)
              Tooltip(
                message: 'Proweniencja i numer seryjny zweryfikowane',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.statusSuccess.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.statusSuccess.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 13,
                        color: AppColors.statusSuccess,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'AUTENTYK',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.statusSuccess,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // Historia zwycięstwa
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: AppColors.goldAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      exhibit.riderName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                exhibit.historicAchievement,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.goldAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${exhibit.raceName} • ${exhibit.stageOrLocation}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Metryki telemetryczne 2x2
        Row(
          children: [
            Expanded(
              child: _SpecMetricTile(
                label: 'Masa',
                value: '${exhibit.weightKg.toStringAsFixed(2)} kg',
                accent: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SpecMetricTile(
                label: 'Aero CdA',
                value: '${exhibit.cdaValue.toStringAsFixed(3)} m²',
                accent: AppColors.accentBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SpecMetricTile(
                label: 'Moc Szczytowa',
                value: '${exhibit.peakPowerWatts} W',
                accent: AppColors.goldAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SpecMetricTile(
                label: 'Przebieg',
                value: '${exhibit.totalKmRidden} km',
                accent: AppColors.statusSuccess,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Szczegóły wybranego hotspota 3D
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.accentBlue.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.adjust_rounded,
                    size: 14,
                    color: AppColors.accentBlue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Inspekcja: ${activeHotspot.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                exhibit.hotspotDetails[activeHotspot] ?? exhibit.curatorialNote,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Specyfikacja techniczna
        _SpecKeyValueRow(label: 'Materiał ramy', value: exhibit.frameMaterial),
        _SpecKeyValueRow(label: 'Grupa napędu', value: exhibit.groupsetName),
        _SpecKeyValueRow(label: 'Zestaw kół', value: exhibit.wheelsetName),
        const SizedBox(height: 10),
        // Pasek konserwacji eksponatu
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Stan Konserwacji',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$restorationPercent%',
                    style: AppTheme.statNumberStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: restorationPercent >= 100
                          ? AppColors.statusSuccess
                          : AppColors.goldAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: restorationPercent / 100.0,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    restorationPercent >= 100
                        ? AppColors.statusSuccess
                        : AppColors.goldAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Akcje: Konserwacja & Przypnij w Holu
        Row(
          children: [
            Expanded(
              child: _MuseumInteractiveButton(
                label: restorationPercent >= 100
                    ? 'Stan Idealny'
                    : 'Poleruj (+15%)',
                icon: restorationPercent >= 100
                    ? Icons.check_circle_outline_rounded
                    : Icons.auto_awesome_outlined,
                isActive: false,
                isDisabled: restorationPercent >= 100,
                activeColor: AppColors.goldAccent,
                onPressed: onPolish,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MuseumInteractiveButton(
                label: isPinned
                    ? 'W Holu ($pinnedCount/3)'
                    : 'Przypnij w Holu',
                icon: isPinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                isActive: isPinned,
                activeColor: AppColors.primaryAccent,
                onPressed: onTogglePin,
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: isScrollableEmbedded
          ? content
          : SingleChildScrollView(child: content),
    );
  }
}

/// Zakładka Gabloty & Pamiątki Klubu.
class _RelicsArchiveView extends StatelessWidget {
  const _RelicsArchiveView({
    required this.relics,
    required this.exhibitsCount,
    required this.heritageScore,
    required this.isDesktop,
    required this.isTablet,
  });

  final List<MuseumTrophyRelic> relics;
  final int exhibitsCount;
  final int heritageScore;
  final bool isDesktop;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 20 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.4),
              ),
            ),
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gabloty Trofeów & Pamiątki Historyczne',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Oryginalne kostki brukowe, koszulki liderów i numery startowe z najważniejszych triumfów klubu.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SpecMetricTile(
                      label: 'Pamiątki',
                      value: '${relics.length}',
                      accent: AppColors.accentBlue,
                    ),
                    const SizedBox(width: 10),
                    _SpecMetricTile(
                      label: 'Rowery 3D',
                      value: '$exhibitsCount',
                      accent: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 10),
                    _SpecMetricTile(
                      label: 'Prestiż',
                      value: '$heritageScore pkt',
                      accent: AppColors.goldAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: relics.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 174,
            ),
            itemBuilder: (context, index) {
              final relic = relics[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: relic.accentColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: relic.accentColor.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Icon(
                            relic.icon,
                            color: relic.accentColor,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                relic.categoryLabel.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.7,
                                  color: relic.accentColor,
                                ),
                              ),
                              Text(
                                relic.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${relic.year}',
                          style: AppTheme.statNumberStyle(
                            fontSize: 12,
                            color: AppColors.goldAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Text(
                        relic.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${relic.riderName} • ${relic.raceName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '+${relic.heritagePoints} pkt',
                          style: AppTheme.statNumberStyle(
                            fontSize: 11,
                            color: AppColors.statusSuccess,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Rzutnik 3D roweru na obrotowej platformie muzealnej z projekcją perspektywiczną.
class _LegendaryBike3dPainter extends CustomPainter {
  _LegendaryBike3dPainter({
    required this.exhibit,
    required this.yawRad,
    required this.pitchRad,
    required this.zoom,
    required this.lighting,
    required this.showHotspots,
    required this.activeHotspot,
  });

  final LegendaryBikeExhibit exhibit;
  final double yawRad;
  final double pitchRad;
  final double zoom;
  final MuseumLightingPreset lighting;
  final bool showHotspots;
  final BikeHotspotPart activeHotspot;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.56);
    final scale = math.min(size.width, size.height) * 0.34 * zoom;

    // Tło galerii z subtelnym gradientem reflektora
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.35),
        radius: 0.95,
        colors: [
          lighting.spotColor.withValues(alpha: 0.16),
          lighting.ambientTint.withValues(alpha: 0.55),
          AppColors.background,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Stożek światła z reflektora sufitowego
    final beamPath = Path()
      ..moveTo(size.width * 0.35, 0)
      ..lineTo(size.width * 0.65, 0)
      ..lineTo(center.dx + scale * 1.45, center.dy + scale * 0.38)
      ..lineTo(center.dx - scale * 1.45, center.dy + scale * 0.38)
      ..close();
    canvas.drawPath(
      beamPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lighting.spotColor.withValues(alpha: 0.10),
            lighting.spotColor.withValues(alpha: 0.01),
          ],
        ).createShader(Offset.zero & size),
    );

    Offset project(double x, double y, double z) {
      final cosY = math.cos(yawRad);
      final sinY = math.sin(yawRad);
      final x1 = x * cosY - z * sinY;
      final z1 = x * sinY + z * cosY;

      final cosP = math.cos(pitchRad);
      final sinP = math.sin(pitchRad);
      final y2 = y * cosP - z1 * sinP;
      final z2 = y * sinP + z1 * cosP;

      const cameraDist = 4.2;
      final perspective = cameraDist / (cameraDist - z2).clamp(1.2, 8.0);
      return Offset(
        center.dx + x1 * scale * perspective,
        center.dy - y2 * scale * perspective,
      );
    }

    // Obrotowy postument muzealny (okrągła platforma)
    _drawPedestal(canvas, project, scale);

    // Definicja węzłów 3D roweru (układ w metrach przeskalowanych na ~[-1, 1])
    const wheelY = -0.22;
    const rearHub = _Vec3(-0.62, wheelY, 0.0);
    const frontHub = _Vec3(0.64, wheelY, 0.0);
    const bottomBracket = _Vec3(-0.12, -0.24, 0.0);
    const seatCluster = _Vec3(-0.29, 0.25, 0.0);
    const headTop = _Vec3(0.39, 0.30, 0.0);
    const headBottom = _Vec3(0.45, 0.14, 0.0);
    const saddleCenter = _Vec3(-0.34, 0.44, 0.0);
    const stemTip = _Vec3(0.50, 0.37, 0.0);

    // Koła 3D (tylne i przednie)
    _drawWheel3d(
      canvas: canvas,
      project: project,
      hub: rearHub,
      radius: 0.36,
      rimDepthNorm: (exhibit.rimDepthMm / 90.0).clamp(0.06, 0.22),
    );
    _drawWheel3d(
      canvas: canvas,
      project: project,
      hub: frontHub,
      radius: 0.36,
      rimDepthNorm: (exhibit.rimDepthMm / 90.0).clamp(0.06, 0.22),
    );

    final tubeWidth = exhibit.era == MuseumBikeEra.steelClassic
        ? 3.8
        : (exhibit.era == MuseumBikeEra.alloyTransition ? 5.2 : 6.8);

    // Tylny trójkąt (chainstays & seatstays)
    _drawTube3d(
      canvas,
      project,
      rearHub.withZ(-0.045),
      bottomBracket.withZ(-0.025),
      tubeWidth * 0.55,
      exhibit.frameColor,
    );
    _drawTube3d(
      canvas,
      project,
      rearHub.withZ(0.045),
      bottomBracket.withZ(0.025),
      tubeWidth * 0.55,
      exhibit.frameColor,
    );
    _drawTube3d(
      canvas,
      project,
      rearHub.withZ(-0.045),
      seatCluster.withZ(-0.018),
      tubeWidth * 0.48,
      exhibit.frameColor,
    );
    _drawTube3d(
      canvas,
      project,
      rearHub.withZ(0.045),
      seatCluster.withZ(0.018),
      tubeWidth * 0.48,
      exhibit.frameColor,
    );

    // Główny trójkąt ramy
    _drawTube3d(
      canvas,
      project,
      bottomBracket,
      seatCluster,
      tubeWidth,
      exhibit.frameColor,
    );
    _drawTube3d(
      canvas,
      project,
      bottomBracket,
      headBottom,
      tubeWidth * 1.15,
      exhibit.frameColor,
    );
    _drawTube3d(
      canvas,
      project,
      seatCluster,
      headTop,
      tubeWidth * 0.92,
      exhibit.frameColor,
    );
    _drawTube3d(
      canvas,
      project,
      headBottom,
      headTop,
      tubeWidth * 1.05,
      exhibit.frameColor,
    );

    // Pasek mistrzowski na górnej rurze (akcent edycji)
    if (exhibit.editionType.isGoldMasterEdition) {
      const bandStart = _Vec3(-0.04, 0.27, 0.0);
      const bandEnd = _Vec3(0.22, 0.285, 0.0);
      _drawTube3d(
        canvas,
        project,
        bandStart,
        bandEnd,
        tubeWidth * 0.98,
        exhibit.accentColor,
      );
    }

    // Widelec przedni (lewa i prawa goleń)
    _drawTube3d(
      canvas,
      project,
      headBottom.withZ(-0.025),
      frontHub.withZ(-0.045),
      tubeWidth * 0.68,
      exhibit.frameColor,
    );
    _drawTube3d(
      canvas,
      project,
      headBottom.withZ(0.025),
      frontHub.withZ(0.045),
      tubeWidth * 0.68,
      exhibit.frameColor,
    );

    // Sztyca i siodło
    _drawTube3d(
      canvas,
      project,
      seatCluster,
      saddleCenter,
      exhibit.hasAeroSeatpost ? 5.0 : 3.2,
      const Color(0xFF1F2430),
    );
    _drawTube3d(
      canvas,
      project,
      _Vec3(saddleCenter.x - 0.13, saddleCenter.y + 0.01, 0.0),
      _Vec3(saddleCenter.x + 0.11, saddleCenter.y + 0.005, 0.0),
      5.5,
      const Color(0xFF111318),
    );

    // Kokpit, mostek i kierownica szosowa (baranki)
    _drawTube3d(
      canvas,
      project,
      headTop,
      _Vec3(headTop.x - 0.02, headTop.y + 0.07, 0.0),
      3.5,
      const Color(0xFF252A36),
    );
    _drawTube3d(
      canvas,
      project,
      _Vec3(headTop.x - 0.02, headTop.y + 0.07, 0.0),
      stemTip,
      3.6,
      const Color(0xFF252A36),
    );
    _drawHandlebar3d(canvas, project, stemTip);

    // Napęd: korba, tarcza i łańcuch
    _drawDrivetrain3d(canvas, project, bottomBracket, rearHub, scale);

    // Interaktywne hotspoty 3D
    if (showHotspots) {
      final hotspotCoords = <BikeHotspotPart, _Vec3>{
        BikeHotspotPart.frame: const _Vec3(0.08, 0.18, 0.0),
        BikeHotspotPart.cockpit: stemTip,
        BikeHotspotPart.drivetrain: bottomBracket,
        BikeHotspotPart.wheelset: frontHub,
      };
      for (final entry in hotspotCoords.entries) {
        final pos = project(entry.value.x, entry.value.y, entry.value.z);
        final isSelected = entry.key == activeHotspot;
        canvas.drawCircle(
          pos,
          isSelected ? 10 : 7,
          Paint()
            ..color = (isSelected ? AppColors.goldAccent : AppColors.accentBlue)
                .withValues(alpha: isSelected ? 0.35 : 0.22),
        );
        canvas.drawCircle(
          pos,
          isSelected ? 5 : 3.5,
          Paint()
            ..color = isSelected ? AppColors.goldAccent : AppColors.accentBlue,
        );
        canvas.drawCircle(
          pos,
          isSelected ? 10 : 7,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = isSelected ? AppColors.goldAccent : AppColors.accentBlue,
        );
      }
    }
  }

  void _drawPedestal(
    Canvas canvas,
    Offset Function(double, double, double) project,
    double scale,
  ) {
    const segments = 48;
    const radius = 1.05;
    const pedestalTopY = -0.59;
    final ringPath = Path();

    for (int i = 0; i <= segments; i++) {
      final theta = (i / segments) * math.pi * 2;
      final pt = project(
        math.cos(theta) * radius,
        pedestalTopY,
        math.sin(theta) * radius,
      );
      if (i == 0) {
        ringPath.moveTo(pt.dx, pt.dy);
      } else {
        ringPath.lineTo(pt.dx, pt.dy);
      }
    }

    canvas.drawPath(
      ringPath,
      Paint()
        ..color = AppColors.surfaceLight.withValues(alpha: 0.72)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      ringPath,
      Paint()
        ..color = lighting.spotColor.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  void _drawWheel3d({
    required Canvas canvas,
    required Offset Function(double, double, double) project,
    required _Vec3 hub,
    required double radius,
    required double rimDepthNorm,
  }) {
    const segments = 36;
    final outerPath = Path();
    final innerRimPath = Path();
    final innerR = radius * (1.0 - rimDepthNorm);

    for (int i = 0; i <= segments; i++) {
      final a = (i / segments) * math.pi * 2;
      final pOuter = project(
        hub.x + math.cos(a) * radius,
        hub.y + math.sin(a) * radius,
        hub.z,
      );
      final pInner = project(
        hub.x + math.cos(a) * innerR,
        hub.y + math.sin(a) * innerR,
        hub.z,
      );
      if (i == 0) {
        outerPath.moveTo(pOuter.dx, pOuter.dy);
        innerRimPath.moveTo(pInner.dx, pInner.dy);
      } else {
        outerPath.lineTo(pOuter.dx, pOuter.dy);
        innerRimPath.lineTo(pInner.dx, pInner.dy);
      }
    }

    // Szprychy
    final hubCenter = project(hub.x, hub.y, hub.z);
    final spokePaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.32)
      ..strokeWidth = 1.0;
    const spokeCount = 16;
    for (int i = 0; i < spokeCount; i++) {
      final a = (i / spokeCount) * math.pi * 2;
      final rimPt = project(
        hub.x + math.cos(a) * innerR,
        hub.y + math.sin(a) * innerR,
        hub.z,
      );
      canvas.drawLine(hubCenter, rimPt, spokePaint);
    }

    // Stożek karbonowy / obręcz
    canvas.drawPath(
      outerPath,
      Paint()
        ..color = const Color(0xFF141720)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (rimDepthNorm * 32).clamp(3.0, 9.0),
    );

    // Ścianka opony (tan-wall lub stealth)
    canvas.drawPath(
      outerPath,
      Paint()
        ..color = exhibit.isTanWall
            ? const Color(0xFFC89D66)
            : const Color(0xFF2B303D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6,
    );

    // Tarcza hamulcowa dla nowoczesnych rowerów
    if (exhibit.isDiscBrake) {
      canvas.drawCircle(
        hubCenter,
        6.5,
        Paint()
          ..color = AppColors.textSecondary.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }
    canvas.drawCircle(hubCenter, 3.2, Paint()..color = AppColors.goldAccent);
  }

  void _drawTube3d(
    Canvas canvas,
    Offset Function(double, double, double) project,
    _Vec3 a,
    _Vec3 b,
    double width,
    Color color,
  ) {
    final p1 = project(a.x, a.y, a.z);
    final p2 = project(b.x, b.y, b.z);
    canvas.drawLine(
      p1,
      p2,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawHandlebar3d(
    Canvas canvas,
    Offset Function(double, double, double) project,
    _Vec3 stemTip,
  ) {
    const halfWidth = 0.21;
    final leftTop = _Vec3(stemTip.x, stemTip.y, -halfWidth);
    final rightTop = _Vec3(stemTip.x, stemTip.y, halfWidth);
    _drawTube3d(
      canvas,
      project,
      leftTop,
      rightTop,
      3.5,
      const Color(0xFF1A1D26),
    );

    for (final sideZ in [-halfWidth, halfWidth]) {
      final top = _Vec3(stemTip.x, stemTip.y, sideZ);
      final hood = _Vec3(stemTip.x + 0.08, stemTip.y + 0.01, sideZ);
      final drop = _Vec3(stemTip.x + 0.09, stemTip.y - 0.11, sideZ);
      final tail = _Vec3(stemTip.x - 0.03, stemTip.y - 0.12, sideZ);
      _drawTube3d(canvas, project, top, hood, 3.2, const Color(0xFF111318));
      _drawTube3d(canvas, project, hood, drop, 3.0, const Color(0xFF111318));
      _drawTube3d(canvas, project, drop, tail, 3.0, const Color(0xFF111318));
    }
  }

  void _drawDrivetrain3d(
    Canvas canvas,
    Offset Function(double, double, double) project,
    _Vec3 bb,
    _Vec3 rearHub,
    double scale,
  ) {
    final bbProj = project(bb.x, bb.y, bb.z + 0.04);
    final rearProj = project(rearHub.x, rearHub.y, rearHub.z + 0.04);

    canvas.drawCircle(
      bbProj,
      (scale * 0.095).clamp(8.0, 20.0),
      Paint()
        ..color = const Color(0xFF343B4D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6,
    );
    canvas.drawCircle(
      rearProj,
      (scale * 0.05).clamp(5.0, 11.0),
      Paint()
        ..color = const Color(0xFF475066)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawLine(
      Offset(bbProj.dx, bbProj.dy - 9),
      Offset(rearProj.dx, rearProj.dy - 5),
      Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.45)
        ..strokeWidth = 1.4,
    );
    canvas.drawLine(
      Offset(bbProj.dx, bbProj.dy + 9),
      Offset(rearProj.dx, rearProj.dy + 5),
      Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.45)
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant _LegendaryBike3dPainter oldDelegate) {
    return oldDelegate.exhibit.id != exhibit.id ||
        oldDelegate.yawRad != yawRad ||
        oldDelegate.pitchRad != pitchRad ||
        oldDelegate.zoom != zoom ||
        oldDelegate.lighting != lighting ||
        oldDelegate.showHotspots != showHotspots ||
        oldDelegate.activeHotspot != activeHotspot;
  }
}

class _Vec3 {
  const _Vec3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  _Vec3 withZ(double nextZ) => _Vec3(x, y, nextZ);
}

/// Przycisk interaktywny Muzeum z obsługą hover / active / disabled / focus.
class _MuseumInteractiveButton extends StatefulWidget {
  const _MuseumInteractiveButton({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.isDisabled = false,
  });

  final String label;
  final IconData? icon;
  final bool isActive;
  final Color activeColor;
  final bool compact;
  final bool isDisabled;
  final VoidCallback onPressed;

  @override
  State<_MuseumInteractiveButton> createState() =>
      _MuseumInteractiveButtonState();
}

class _MuseumInteractiveButtonState extends State<_MuseumInteractiveButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : widget.isActive
            ? widget.activeColor.withValues(alpha: 0.18)
            : _isHovered
                ? AppColors.surfaceLight
                : AppColors.surface;

    final borderColor = widget.isDisabled
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : widget.isActive
            ? widget.activeColor
            : _isFocused
                ? AppColors.accentBlue
                : _isHovered
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : AppTheme.borderColor;

    final fgColor = widget.isDisabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : widget.isActive
            ? widget.activeColor
            : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: MouseRegion(
        cursor: widget.isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.isDisabled ? null : widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 12,
              vertical: widget.compact ? 6 : 9,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: widget.isActive || _isFocused ? 1.3 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: widget.compact ? 14 : 16, color: fgColor),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: widget.compact ? 11 : 12,
                      fontWeight:
                          widget.isActive ? FontWeight.w700 : FontWeight.w600,
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

class _SpecMetricTile extends StatelessWidget {
  const _SpecMetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.statNumberStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecKeyValueRow extends StatelessWidget {
  const _SpecKeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 98,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyExhibitsPlaceholder extends StatelessWidget {
  const _EmptyExhibitsPlaceholder({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 28,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 6),
            const Text(
              'Brak eksponatów dla wybranych filtrów.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _MuseumInteractiveButton(
              label: 'Resetuj filtry',
              isActive: true,
              activeColor: AppColors.goldAccent,
              compact: true,
              onPressed: onReset,
            ),
          ],
        ),
      ),
    );
  }
}

const List<LegendaryBikeExhibit> _defaultExhibits = [
  LegendaryBikeExhibit(
    id: 'exhibit_2025_apex_gt',
    name: 'Apex SL-R Gold Edition',
    manufacturer: 'Apex Cycles',
    year: 2025,
    era: MuseumBikeEra.modernSuperbike,
    category: MuseumExhibitCategory.grandTourWinners,
    editionType: ChampionshipEditionType.grandTourYellowGold,
    serialNumber: 'PPM-GT-2025-001',
    riderName: 'Jan Kowalski',
    historicAchievement: 'Zwycięstwo w Klasyfikacji Generalnej Tour de France',
    raceName: 'Tour de France',
    stageOrLocation: 'Paryż — Pola Elizejskie',
    frameMaterial: 'Karbon Toray T1100 1K Monocoque',
    groupsetName: 'Shimano Dura-Ace Di2 12s (54/40T)',
    wheelsetName: 'Karbonowe Stożki 50mm Ceramic',
    weightKg: 6.81,
    cdaValue: 0.194,
    peakPowerWatts: 1410,
    totalKmRidden: 3420,
    frameColor: Color(0xFFD4AF37),
    accentColor: Color(0xFFFACC15),
    rimDepthMm: 50,
    isTanWall: true,
    isDiscBrake: true,
    isDowntubeShifter: false,
    hasAeroSeatpost: true,
    curatorialNote:
        'Złota rama przygotowana specjalnie na finałowy etap w Paryżu. Masa na limicie UCI 6.81 kg przy zachowaniu sztywności sprinterskiej.',
    hotspotDetails: {
      BikeHotspotPart.frame:
          'Złote malowanie pamiątkowe z grawerem numeru seryjnego PPM-GT-2025-001 na górnej rurze.',
      BikeHotspotPart.cockpit:
          'Zintegrowany kokpit 380 mm z komputerem telemetrycznym i owijką o wysokiej przyczepności.',
      BikeHotspotPart.drivetrain:
          'Tarcze 54/40T oraz woskowany łańcuch oszczędzający 4.2 W na płaskich odcinkach.',
      BikeHotspotPart.wheelset:
          'Stożki 50 mm na łożyskach ceramicznych z oponami 28 mm Tan-Wall.',
    },
  ),
  LegendaryBikeExhibit(
    id: 'exhibit_2024_rainbow',
    name: 'Valkyrie Aero WC',
    manufacturer: 'Valkyrie Lab',
    year: 2024,
    era: MuseumBikeEra.modernSuperbike,
    category: MuseumExhibitCategory.worldChampion,
    editionType: ChampionshipEditionType.worldChampionRainbow,
    serialNumber: 'PPM-WC-2024-007',
    riderName: 'Marek Zieliński',
    historicAchievement: 'Tytuł Mistrza Świata Elity ze Startu Wspólnego',
    raceName: 'Mistrzostwa Świata UCI',
    stageOrLocation: 'Zurych — Wyścig Elity',
    frameMaterial: 'Ultra-High Modulus Carbon Aero',
    groupsetName: 'SRAM RED AXS E1 12s (52/39T)',
    wheelsetName: 'Aero 62mm Tubeless Carbon',
    weightKg: 6.95,
    cdaValue: 0.189,
    peakPowerWatts: 1525,
    totalKmRidden: 2890,
    frameColor: Color(0xFFF3F4F6),
    accentColor: Color(0xFFD4AF37),
    rimDepthMm: 62,
    isTanWall: false,
    isDiscBrake: true,
    isDowntubeShifter: false,
    hasAeroSeatpost: true,
    curatorialNote:
        'Biała perłowa rama z tęczowymi pasami UCI na rurze podsiodłowej i widelcu. Zaprojektowana pod solowy atak na 45 km przed metą.',
    hotspotDetails: {
      BikeHotspotPart.frame:
          'Tęczowe paski Mistrza Świata UCI naniesione ręcznie w komorze lakierniczej.',
      BikeHotspotPart.cockpit:
          'Wąskie klamkomanetki ustawione do wewnątrz o 8 stopni dla redukcji oporu CdA.',
      BikeHotspotPart.drivetrain:
          'Miernik mocy zintegrowany w pająku korby — zarejestrowano atak 1180 W.',
      BikeHotspotPart.wheelset:
          'Głęboki profil 62 mm zoptymalizowany pod wiatr boczny 15–25 km/h.',
    },
  ),
  LegendaryBikeExhibit(
    id: 'exhibit_2012_roubaix',
    name: 'Flandria Pavé Endurance',
    manufacturer: 'Meridian Cycles',
    year: 2012,
    era: MuseumBikeEra.carbonAero,
    category: MuseumExhibitCategory.monumentClassics,
    editionType: ChampionshipEditionType.monumentWinner,
    serialNumber: 'PPM-MN-2012-014',
    riderName: 'Tomasz Nowak',
    historicAchievement: 'Triumf na Welodromie w Paryż-Roubaix',
    raceName: 'Paryż-Roubaix',
    stageOrLocation: 'Lasek Arenberg & Carrefour de l’Arbre',
    frameMaterial: 'Karbon Endurace z elastomerem Zertz',
    groupsetName: 'Shimano Dura-Ace 7970 Di2 10s',
    wheelsetName: 'Aluminiowo-Karbonowe Szytkowe 32mm',
    weightKg: 7.45,
    cdaValue: 0.224,
    peakPowerWatts: 1610,
    totalKmRidden: 6150,
    frameColor: Color(0xFF8E4A49),
    accentColor: Color(0xFFD4AF37),
    rimDepthMm: 32,
    isTanWall: true,
    isDiscBrake: false,
    isDowntubeShifter: false,
    hasAeroSeatpost: false,
    curatorialNote:
        'Zachowano oryginalne ślady kurzu z północnej Francji oraz podwójną owijkę żelową tłumiącą drgania na pięciogwiazdkowym bruku.',
    hotspotDetails: {
      BikeHotspotPart.frame:
          'Wydłużony rozstaw osi i tłumiące wkładki w tylnych widełkach pod bruk 5★.',
      BikeHotspotPart.cockpit:
          'Podwójna warstwa owijki korkowej i dodatkowe przyciski zmiany biegów na górnym chwycie.',
      BikeHotspotPart.drivetrain:
          'Duża tarcza 53T oraz korba 175 mm dopasowana do jazdy na płaskim bruku.',
      BikeHotspotPart.wheelset:
          'Szytki bawełniane 28 mm napompowane do 4.8 bar na mokre sektory.',
    },
  ),
  LegendaryBikeExhibit(
    id: 'exhibit_1999_alpe',
    name: 'Alpinista Scandium SL',
    manufacturer: 'Bianchi & Co. Heritage',
    year: 1999,
    era: MuseumBikeEra.alloyTransition,
    category: MuseumExhibitCategory.grandTourWinners,
    editionType: ChampionshipEditionType.nationalChampion,
    serialNumber: 'PPM-NC-1999-003',
    riderName: 'Piotr Wiśniewski',
    historicAchievement: 'Rekordowy podjazd na Alpe d’Huez (37:48)',
    raceName: 'Tour de France',
    stageOrLocation: '21 zakrętów Alpe d’Huez',
    frameMaterial: 'Aluminium Dedacciai Scandium',
    groupsetName: 'Campagnolo Record 9s Titanium',
    wheelsetName: 'Niskoprofilowe Obręcze Szytkowe 22mm',
    weightKg: 7.12,
    cdaValue: 0.242,
    peakPowerWatts: 1120,
    totalKmRidden: 8400,
    frameColor: Color(0xFF38BDF8),
    accentColor: Color(0xFFF3F4F6),
    rimDepthMm: 22,
    isTanWall: true,
    isDiscBrake: false,
    isDowntubeShifter: false,
    hasAeroSeatpost: false,
    curatorialNote:
        'Ultralekka maszyna górska przełomu wieków. Rury ze stopu skandu pozwoliły zejść poniżej 7.2 kg w erze dominacji aluminium.',
    hotspotDetails: {
      BikeHotspotPart.frame:
          'Cieniowane rury aluminiowo-skandowe z klasyczną geometrią poziomą.',
      BikeHotspotPart.cockpit:
          'Klasyczny wspornik kierownicy i płytkie gięcie baranka typu włoskiego.',
      BikeHotspotPart.drivetrain:
          'Campagnolo Record 9s z kasetą górską 12-25T i korbą 53/39T.',
      BikeHotspotPart.wheelset:
          'Minimalna masa rotująca kół 22 mm idealna do przyspieszeń na 10% nachyleniu.',
    },
  ),
  LegendaryBikeExhibit(
    id: 'exhibit_1974_molteni',
    name: 'Corsa Acciaio 1974',
    manufacturer: 'Officina Milano',
    year: 1974,
    era: MuseumBikeEra.steelClassic,
    category: MuseumExhibitCategory.clubHeritage,
    editionType: ChampionshipEditionType.standardTeamIssue,
    serialNumber: 'PPM-CL-1974-001',
    riderName: 'Stanisław Król',
    historicAchievement: 'Pierwszy historyczny triumf klubu w Wyścigu Pokoju',
    raceName: 'Wyścig Pokoju',
    stageOrLocation: 'Warszawa — Praga — Berlin',
    frameMaterial: 'Stal Columbus SL Chromowo-Molibdenowa',
    groupsetName: 'Campagnolo Nuovo Record 6s',
    wheelsetName: 'Obręcze Aluminiowe 36-szprychowe',
    weightKg: 9.45,
    cdaValue: 0.278,
    peakPowerWatts: 1090,
    totalKmRidden: 14200,
    frameColor: Color(0xFFEF4444),
    accentColor: Color(0xFFD4AF37),
    rimDepthMm: 18,
    isTanWall: true,
    isDiscBrake: false,
    isDowntubeShifter: true,
    hasAeroSeatpost: false,
    curatorialNote:
        'Najstarszy eksponat w Muzeum Klubowym. Ręcznie lutowana rama ze stali Columbus SL z manetkami zmiany biegów na dolnej rurze.',
    hotspotDetails: {
      BikeHotspotPart.frame:
          'Mufowana ręcznie stal Columbus SL w klasycznym szkarłatnym lakierze.',
      BikeHotspotPart.cockpit:
          'Zewnętrzne linki hamulcowe poprowadzone nad kierownicą i skórzana owijka.',
      BikeHotspotPart.drivetrain:
          'Mechaniczne manetki na dolnej rurze i 6-rzędowy wolnobieg 13-24T.',
      BikeHotspotPart.wheelset:
          '36 szprych stalowych zaplecionych na 3 krzyże — niezawodność na szutrach.',
    },
  ),
];

const List<MuseumTrophyRelic> _defaultRelics = [
  MuseumTrophyRelic(
    id: 'relic_1',
    title: 'Żółta Koszulka Lidera #01',
    year: 2025,
    raceName: 'Tour de France',
    riderName: 'Jan Kowalski',
    categoryLabel: 'Wielki Tour',
    description:
        'Oryginalna koszulka lidera z autografem całego zespołu po zwycięstwie na Polach Elizejskich.',
    accentColor: AppColors.goldAccent,
    icon: Icons.workspace_premium_rounded,
    heritagePoints: 450,
  ),
  MuseumTrophyRelic(
    id: 'relic_2',
    title: 'Kostka Brukowa z Roubaix',
    year: 2012,
    raceName: 'Paryż-Roubaix',
    riderName: 'Tomasz Nowak',
    categoryLabel: 'Monument',
    description:
        'Trofeum „Królowej Klasyków” wydobyte z sektora Carrefour de l’Arbre wraz z tabliczką pamiątkową.',
    accentColor: AppColors.primaryAccent,
    icon: Icons.grid_view_rounded,
    heritagePoints: 350,
  ),
  MuseumTrophyRelic(
    id: 'relic_3',
    title: 'Tęczowa Koszulka UCI',
    year: 2024,
    raceName: 'Mistrzostwa Świata UCI',
    riderName: 'Marek Zieliński',
    categoryLabel: 'Mistrzostwo Świata',
    description:
        'Oficjalny trykot mistrza świata wręczony na podium w Zurychu z oryginalnym numerem startowym 41.',
    accentColor: AppColors.accentBlue,
    icon: Icons.military_tech_outlined,
    heritagePoints: 400,
  ),
  MuseumTrophyRelic(
    id: 'relic_4',
    title: 'Złoty Bidon z Alpe d’Huez',
    year: 1999,
    raceName: 'Tour de France',
    riderName: 'Piotr Wiśniewski',
    categoryLabel: 'Rekord Podjazdu',
    description:
        'Historyczny bidon użyty podczas rekordowego ataku na 14. zakręcie legendarnej wspinaczki.',
    accentColor: AppColors.cyanAccent,
    icon: Icons.terrain_rounded,
    heritagePoints: 260,
  ),
  MuseumTrophyRelic(
    id: 'relic_5',
    title: 'Numer Startowy #1974',
    year: 1974,
    raceName: 'Wyścig Pokoju',
    riderName: 'Stanisław Król',
    categoryLabel: 'Dziedzictwo Klubu',
    description:
        'Płócienny numer startowy przypięty agrafkami do wełnianej koszulki z pierwszego triumfu drużyny.',
    accentColor: AppColors.statusSuccess,
    icon: Icons.confirmation_number_outlined,
    heritagePoints: 220,
  ),
  MuseumTrophyRelic(
    id: 'relic_6',
    title: 'Protokół Tunelu Aero #001',
    year: 2025,
    raceName: 'Dział R&D Klubu',
    riderName: 'Zespół Inżynieryjny',
    categoryLabel: 'Innowacja',
    description:
        'Podpisana dokumentacja testowa redukcji oporu CdA poniżej granicy 0.190 m².',
    accentColor: AppColors.amberWarning,
    icon: Icons.air_rounded,
    heritagePoints: 240,
  ),
];
