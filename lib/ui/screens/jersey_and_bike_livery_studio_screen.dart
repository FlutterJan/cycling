// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../services/career/custom_jersey_sponsor_patch_placer.dart';
import '../../state/career_controller.dart';
import '../widgets/custom_jersey_painter.dart';

/// Rodzaje pasków mistrzowskich na mankietach rękawków i kołnierzyku.
enum ChampionBandsType {
  none('Brak (Standardowe mankiety zespołu)'),
  worldChampionRainbow('Tęcza Mistrza Świata UCI (Rainbow Bands)'),
  poland('Mistrz Polski (Biało-Czerwone)'),
  italy('Mistrz Włoch (Tricolore: Zielono-Biało-Czerwone)'),
  france('Mistrz Francji (Bleu-Blanc-Rouge)'),
  belgium('Mistrz Belgii (Czarno-Żółto-Czerwone)'),
  spain('Mistrz Hiszpanii (Czerwono-Żółto-Czerwone)'),
  denmark('Mistrz Danii (Czerwono-Białe Dannebrog)'),
  slovenia('Mistrz Słowenii (Biało-Błękitno-Czerwone)'),
  greatBritain('Mistrz Wielkiej Brytanii (Union Stripes)');

  final String label;
  const ChampionBandsType(this.label);

  String toJson() => name;

  static ChampionBandsType fromJson(String value) {
    return ChampionBandsType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ChampionBandsType.none,
    );
  }
}

/// Rodzaj wykończenia lakierniczego ramy rowerowej (Team Issue Custom Paint).
enum BikePaintFinishType {
  matteRawCarbon(
    'Matowy Surowy Karbon UD',
    'Lekki kompozyt węglowy bez lakieru bezbarwnego (-80g wagi ramy)',
    Color(0xFF1E2024),
  ),
  metallicSilver(
    'Płynny Chrom Metalik (Liquid Chrome)',
    'Lustrzany połysk srebrnego metaliku odbijający promienie słońca',
    Color(0xFFCBD5E1),
  ),
  chameleonPrism(
    'Pryzmatyczny Kameleon (Flip-Flop)',
    'Wielobarwny lakier mieniący się pod kątem światła fioletem, błękitem i zielenią',
    Color(0xFF8B5CF6),
  ),
  raceLeaderGold(
    'Złoto Lidera Wyścigu & Mistrza',
    'Prestiżowy perłowy złoty lakier z drobinkami metalu dla lidera Grand Touru',
    Color(0xFFFFD700),
  ),
  glossySolid(
    'Głęboki Połysk (Glossy)',
    'Intensywny lśniący lakier z podwójną warstwą ochronną High-Gloss',
    Color(0xFFDC2626),
  ),
  stealthShadow(
    'Czerń Stealth Matowa',
    'Agresywna satynowa czerń z błyszczącymi kalkomaniami producenta',
    Color(0xFF0F1013),
  );

  final String title;
  final String description;
  final Color previewColor;

  const BikePaintFinishType(this.title, this.description, this.previewColor);

  String toJson() => name;

  static BikePaintFinishType fromJson(String value) {
    return BikePaintFinishType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BikePaintFinishType.glossySolid,
    );
  }
}

/// Kompletna konfiguracja wizerunku drużyny (strój + malowanie roweru).
class TeamLiveryConfiguration {
  final JerseyPattern jerseyPattern;
  final String primaryColorHex;
  final String secondaryColorHex;
  final String accentColorHex;
  final String bibShortsColorHex;
  final String bibShortsGripperColorHex;
  final ChampionBandsType championBands;
  final String sponsorMainText;
  final String sponsorSecondaryText;
  final String sponsorTextColorHex;
  final String bikeBrandName;
  final BikePaintFinishType bikeFinish;
  final String bikePrimaryColorHex;
  final String bikeAccentColorHex;
  final String bikeDecalColorHex;
  final String barTapeColorHex;
  final bool isTanWallTires;

  const TeamLiveryConfiguration({
    this.jerseyPattern = JerseyPattern.chestStripe,
    this.primaryColorHex = '#002B49',
    this.secondaryColorHex = '#FFD100',
    this.accentColorHex = '#FFFFFF',
    this.bibShortsColorHex = '#111317',
    this.bibShortsGripperColorHex = '#FFD100',
    this.championBands = ChampionBandsType.none,
    this.sponsorMainText = 'VISMA',
    this.sponsorSecondaryText = 'LEASE A BIKE',
    this.sponsorTextColorHex = '#FFFFFF',
    this.bikeBrandName = 'CERVÉLO',
    this.bikeFinish = BikePaintFinishType.matteRawCarbon,
    this.bikePrimaryColorHex = '#FFD100',
    this.bikeAccentColorHex = '#111317',
    this.bikeDecalColorHex = '#FFFFFF',
    this.barTapeColorHex = '#111317',
    this.isTanWallTires = true,
  });

  TeamLiveryConfiguration copyWith({
    JerseyPattern? jerseyPattern,
    String? primaryColorHex,
    String? secondaryColorHex,
    String? accentColorHex,
    String? bibShortsColorHex,
    String? bibShortsGripperColorHex,
    ChampionBandsType? championBands,
    String? sponsorMainText,
    String? sponsorSecondaryText,
    String? sponsorTextColorHex,
    String? bikeBrandName,
    BikePaintFinishType? bikeFinish,
    String? bikePrimaryColorHex,
    String? bikeAccentColorHex,
    String? bikeDecalColorHex,
    String? barTapeColorHex,
    bool? isTanWallTires,
  }) {
    return TeamLiveryConfiguration(
      jerseyPattern: jerseyPattern ?? this.jerseyPattern,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      secondaryColorHex: secondaryColorHex ?? this.secondaryColorHex,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      bibShortsColorHex: bibShortsColorHex ?? this.bibShortsColorHex,
      bibShortsGripperColorHex: bibShortsGripperColorHex ?? this.bibShortsGripperColorHex,
      championBands: championBands ?? this.championBands,
      sponsorMainText: sponsorMainText ?? this.sponsorMainText,
      sponsorSecondaryText: sponsorSecondaryText ?? this.sponsorSecondaryText,
      sponsorTextColorHex: sponsorTextColorHex ?? this.sponsorTextColorHex,
      bikeBrandName: bikeBrandName ?? this.bikeBrandName,
      bikeFinish: bikeFinish ?? this.bikeFinish,
      bikePrimaryColorHex: bikePrimaryColorHex ?? this.bikePrimaryColorHex,
      bikeAccentColorHex: bikeAccentColorHex ?? this.bikeAccentColorHex,
      bikeDecalColorHex: bikeDecalColorHex ?? this.bikeDecalColorHex,
      barTapeColorHex: barTapeColorHex ?? this.barTapeColorHex,
      isTanWallTires: isTanWallTires ?? this.isTanWallTires,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jerseyPattern': jerseyPattern.name,
      'primaryColorHex': primaryColorHex,
      'secondaryColorHex': secondaryColorHex,
      'accentColorHex': accentColorHex,
      'bibShortsColorHex': bibShortsColorHex,
      'bibShortsGripperColorHex': bibShortsGripperColorHex,
      'championBands': championBands.toJson(),
      'sponsorMainText': sponsorMainText,
      'sponsorSecondaryText': sponsorSecondaryText,
      'sponsorTextColorHex': sponsorTextColorHex,
      'bikeBrandName': bikeBrandName,
      'bikeFinish': bikeFinish.toJson(),
      'bikePrimaryColorHex': bikePrimaryColorHex,
      'bikeAccentColorHex': bikeAccentColorHex,
      'bikeDecalColorHex': bikeDecalColorHex,
      'barTapeColorHex': barTapeColorHex,
      'isTanWallTires': isTanWallTires,
    };
  }

  factory TeamLiveryConfiguration.fromJson(Map<String, dynamic> json) {
    return TeamLiveryConfiguration(
      jerseyPattern: JerseyPattern.values.firstWhere(
        (p) => p.name == json['jerseyPattern'],
        orElse: () => JerseyPattern.chestStripe,
      ),
      primaryColorHex: json['primaryColorHex'] as String? ?? '#002B49',
      secondaryColorHex: json['secondaryColorHex'] as String? ?? '#FFD100',
      accentColorHex: json['accentColorHex'] as String? ?? '#FFFFFF',
      bibShortsColorHex: json['bibShortsColorHex'] as String? ?? '#111317',
      bibShortsGripperColorHex: json['bibShortsGripperColorHex'] as String? ?? '#FFD100',
      championBands: ChampionBandsType.fromJson(json['championBands'] as String? ?? 'none'),
      sponsorMainText: json['sponsorMainText'] as String? ?? 'VISMA',
      sponsorSecondaryText: json['sponsorSecondaryText'] as String? ?? 'LEASE A BIKE',
      sponsorTextColorHex: json['sponsorTextColorHex'] as String? ?? '#FFFFFF',
      bikeBrandName: json['bikeBrandName'] as String? ?? 'CERVÉLO',
      bikeFinish: BikePaintFinishType.fromJson(json['bikeFinish'] as String? ?? 'matteRawCarbon'),
      bikePrimaryColorHex: json['bikePrimaryColorHex'] as String? ?? '#FFD100',
      bikeAccentColorHex: json['bikeAccentColorHex'] as String? ?? '#111317',
      bikeDecalColorHex: json['bikeDecalColorHex'] as String? ?? '#FFFFFF',
      barTapeColorHex: json['barTapeColorHex'] as String? ?? '#111317',
      isTanWallTires: json['isTanWallTires'] as bool? ?? true,
    );
  }
}

/// Ekran Studia Projektowania Wizerunku Drużyny (Livery Studio).
class JerseyAndBikeLiveryStudioScreen extends ConsumerStatefulWidget {
  final TeamLiveryConfiguration? initialConfig;
  final VoidCallback? onBack;
  final void Function(TeamLiveryConfiguration config)? onLiverySaved;

  const JerseyAndBikeLiveryStudioScreen({
    super.key,
    this.initialConfig,
    this.onBack,
    this.onLiverySaved,
  });

  @override
  ConsumerState<JerseyAndBikeLiveryStudioScreen> createState() =>
      _JerseyAndBikeLiveryStudioScreenState();
}

class _JerseyAndBikeLiveryStudioScreenState
    extends ConsumerState<JerseyAndBikeLiveryStudioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  TeamLiveryConfiguration _config = const TeamLiveryConfiguration();

  // Widok koszulki: przód / tył
  bool _isBackView = false;

  // Kontrolery tekstowe
  late TextEditingController _sponsorMainCtrl;
  late TextEditingController _sponsorSecondaryCtrl;
  late TextEditingController _bikeBrandCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    if (widget.initialConfig != null) {
      _config = widget.initialConfig!;
    }

    _sponsorMainCtrl = TextEditingController(text: _config.sponsorMainText);
    _sponsorSecondaryCtrl = TextEditingController(text: _config.sponsorSecondaryText);
    _bikeBrandCtrl = TextEditingController(text: _config.bikeBrandName);

    // Wczytanie barw aktualnej drużyny z aktywnej kariery (jeśli istnieje i nie przekazano initialConfig)
    if (widget.initialConfig == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initFromActiveTeam();
      });
    }
  }

  void _initFromActiveTeam() {
    final careerState = ref.read(careerControllerProvider);
    final curSave = careerState.save;
    if (curSave != null) {
      final team = curSave.playerTeam;
      final sponsor = team.sponsors.isNotEmpty ? team.sponsors.first.companyName : team.name;

      setState(() {
        _config = _config.copyWith(
          primaryColorHex: team.primaryJerseyColorHex,
          secondaryColorHex: team.secondaryJerseyColorHex,
          accentColorHex: team.accentJerseyColorHex,
          sponsorMainText: sponsor,
          bikeBrandName: team.bikeDeal.manufacturerName,
        );
        _sponsorMainCtrl.text = sponsor;
        _bikeBrandCtrl.text = team.bikeDeal.manufacturerName;
      });
      ref.read(customJerseySponsorPatchProvider.notifier).syncTeamMetadata(
            teamId: team.id,
            primarySponsor: sponsor,
            secondarySponsor: _config.sponsorSecondaryText,
            bikeBrand: team.bikeDeal.manufacturerName,
            countryIso: team.countryIso,
          );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sponsorMainCtrl.dispose();
    _sponsorSecondaryCtrl.dispose();
    _bikeBrandCtrl.dispose();
    super.dispose();
  }

  // ===========================================================================
  // PRESETY PRO PELOTONU
  // ===========================================================================

  void _applyPreset({
    required String name,
    required JerseyPattern pattern,
    required String primary,
    required String secondary,
    required String accent,
    required String bib,
    required String gripper,
    required String sponsor,
    required String sponsorSec,
    required String brand,
    required BikePaintFinishType finish,
    required String bikePrimary,
    required String bikeAccent,
    required String decal,
    required bool tanWall,
  }) {
    setState(() {
      _config = TeamLiveryConfiguration(
        jerseyPattern: pattern,
        primaryColorHex: primary,
        secondaryColorHex: secondary,
        accentColorHex: accent,
        bibShortsColorHex: bib,
        bibShortsGripperColorHex: gripper,
        championBands: ChampionBandsType.none,
        sponsorMainText: sponsor,
        sponsorSecondaryText: sponsorSec,
        sponsorTextColorHex: '#FFFFFF',
        bikeBrandName: brand,
        bikeFinish: finish,
        bikePrimaryColorHex: bikePrimary,
        bikeAccentColorHex: bikeAccent,
        bikeDecalColorHex: decal,
        barTapeColorHex: '#111317',
        isTanWallTires: tanWall,
      );

      _sponsorMainCtrl.text = sponsor;
      _sponsorSecondaryCtrl.text = sponsorSec;
      _bikeBrandCtrl.text = brand;
    });
    ref.read(customJerseySponsorPatchProvider.notifier).syncTeamMetadata(
          teamId: ref.read(careerControllerProvider).save?.playerTeam.id ?? 'player_team',
          primarySponsor: sponsor,
          secondarySponsor: sponsorSec,
          bikeBrand: brand,
          countryIso: ref.read(careerControllerProvider).save?.playerTeam.countryIso ?? 'POL',
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Zastosowano paletę stylu: $name'),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  // ===========================================================================
  // ZAPIS I APLIKACJA W KARIERZE
  // ===========================================================================

  void _saveLivery() {
    // 1. Wywołanie callbacku
    if (widget.onLiverySaved != null) {
      widget.onLiverySaved!(_config);
    }

    // 2. Aktualizacja drużyny w aktywnej karierze
    final careerCtrl = ref.read(careerControllerProvider.notifier);
    final curSave = ref.read(careerControllerProvider).save;

    if (curSave != null) {
      final team = curSave.playerTeam;
      final updatedTeam = team.copyWith(
        primaryJerseyColorHex: _config.primaryColorHex,
        secondaryJerseyColorHex: _config.secondaryColorHex,
        accentJerseyColorHex: _config.accentColorHex,
      );
      careerCtrl.updateTeam(updatedTeam);
    }

    _showSavedSuccessDialog();
  }

  void _showSavedSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.goldAccent, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.palette, color: AppColors.goldAccent, size: 28),
              SizedBox(width: 12),
              Text(
                'Wizerunek Zespołu Zapisany!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nowy projekt strojów kolarskich oraz lakierowania ram Team Issue został pomyślnie zatwierdzony.',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wzór koszulki: ${_config.jerseyPattern.label}',
                        style: const TextStyle(color: AppColors.goldAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('Paski na rękawkach: ${_config.championBands.label}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('Malowanie ramy: ${_config.bikeFinish.title}',
                        style: const TextStyle(color: AppColors.accentBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final jsonStr = jsonEncode(_config.toJson());
                Clipboard.setData(ClipboardData(text: jsonStr));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Konfiguracja wizerunku skopiowana do schowka!')),
                );
              },
              child: const Text('Kopiuj JSON', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                if (widget.onBack != null) widget.onBack!();
              },
              child: const Text('Gotowe', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // BUDOWA EKRANU (BUILD)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Studio Wizerunku Drużyny', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Livery Studio: Koszulka, Spodenki & Custom Paint Ramy',
                style: TextStyle(fontSize: 11, color: AppColors.goldAccent)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldAccent,
          labelColor: AppColors.goldAccent,
          unselectedLabelColor: AppColors.textSecondary,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.checkroom), text: 'Strój & Spodenki'),
            Tab(icon: Icon(Icons.layers), text: 'Rozmieszczacz Logo'),
            Tab(icon: Icon(Icons.pedal_bike), text: 'Lakierowanie Ramy'),
            Tab(icon: Icon(Icons.collections), text: 'Presety Pro Pelotonu'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldAccent,
                foregroundColor: Colors.black,
                elevation: 2,
              ),
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Zapisz Styl', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: _saveLivery,
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 920;

          return TabBarView(
            controller: _tabController,
            children: [
              // ZAKŁADKA 1: KOSZULKA I SPODENKI
              _buildKitDesignerTab(isWide),

              // ZAKŁADKA 2: ROZMIESZCZACZ LOGOTYPÓW SPONSORÓW
              CustomJerseySponsorPatchPlacerPanel(
                primaryColor: CustomJerseySponsorPatchPlacer.parseHexColor(_config.primaryColorHex),
                secondaryColor: CustomJerseySponsorPatchPlacer.parseHexColor(_config.secondaryColorHex),
                accentColor: CustomJerseySponsorPatchPlacer.parseHexColor(_config.accentColorHex),
                bibColor: CustomJerseySponsorPatchPlacer.parseHexColor(_config.bibShortsColorHex),
              ),

              // ZAKŁADKA 3: MALOWANIE RAMY
              _buildBikePaintTab(isWide),

              // ZAKŁADKA 4: PRESETY PRO
              _buildProPresetsTab(),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // ZAKŁADKA 1: STRÓJ I SPODENKI
  // ===========================================================================

  Widget _buildKitDesignerTab(bool isWide) {
    final previewWidget = Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Przełącznik przód / tył
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Widok z Przodu'),
                selected: !_isBackView,
                selectedColor: AppColors.goldAccent,
                onSelected: (val) => setState(() => _isBackView = false),
              ),
              ChoiceChip(
                label: const Text('Widok z Tyłu'),
                selected: _isBackView,
                selectedColor: AppColors.goldAccent,
                onSelected: (val) => setState(() => _isBackView = true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Wizualizator kombinezonu
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 0.65,
                child: CustomPaint(
                  painter: _FullCyclingKitPainter(
                    config: _config,
                    isBackView: _isBackView,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final controlsWidget = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Wybór wzoru koszulki
        const Text('Geometryczny Wzór Koszulki:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: JerseyPattern.values.map((p) {
            final isSel = _config.jerseyPattern == p;
            return ChoiceChip(
              label: Text(p.label, style: TextStyle(fontSize: 11, color: isSel ? Colors.black : AppColors.textPrimary)),
              selected: isSel,
              selectedColor: AppColors.goldAccent,
              backgroundColor: AppColors.surfaceLight,
              onSelected: (val) {
                if (val) setState(() => _config = _config.copyWith(jerseyPattern: p));
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // 2. Paski Mistrzowskie na Rękawkach i Kołnierzyku
        const Text('Paski Mistrza Świata / Kraju:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<ChampionBandsType>(
          isExpanded: true,
          initialValue: _config.championBands,
          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          items: ChampionBandsType.values.map((b) {
            return DropdownMenuItem(value: b, child: Text(b.label, style: const TextStyle(fontSize: 12)));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _config = _config.copyWith(championBands: val));
          },
        ),

        const SizedBox(height: 20),

        // 3. Kolorystyka Koszulki i Spodenek
        const Text('Paleta Barw Stroju (Kody HEX):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 10),
        _buildColorPickerRow('Kolor Główny Koszulki', _config.primaryColorHex, (hex) {
          setState(() => _config = _config.copyWith(primaryColorHex: hex));
        }),
        const SizedBox(height: 10),
        _buildColorPickerRow('Kolor Wtórny (Pas/Rękawy)', _config.secondaryColorHex, (hex) {
          setState(() => _config = _config.copyWith(secondaryColorHex: hex));
        }),
        const SizedBox(height: 10),
        _buildColorPickerRow('Kolor Akcentów / Detali', _config.accentColorHex, (hex) {
          setState(() => _config = _config.copyWith(accentColorHex: hex));
        }),
        const SizedBox(height: 10),
        _buildColorPickerRow('Kolor Spodenek (Bib Shorts)', _config.bibShortsColorHex, (hex) {
          setState(() => _config = _config.copyWith(bibShortsColorHex: hex));
        }),
        const SizedBox(height: 10),
        _buildColorPickerRow('Kolor Pasków Nogawki', _config.bibShortsGripperColorHex, (hex) {
          setState(() => _config = _config.copyWith(bibShortsGripperColorHex: hex));
        }),

        const SizedBox(height: 20),

        // 4. Logotypy Sponsorów
        const Text('Rozmieszczenie Sponsorów:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 10),
        TextFormField(
          controller: _sponsorMainCtrl,
          decoration: const InputDecoration(
            labelText: 'Sponsor Główny na Piersi',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (val) => setState(() => _config = _config.copyWith(sponsorMainText: val)),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _sponsorSecondaryCtrl,
          decoration: const InputDecoration(
            labelText: 'Sponsor Wtórny (Brzuch / Kieszenie)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (val) => setState(() => _config = _config.copyWith(sponsorSecondaryText: val)),
        ),
      ],
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(flex: 5, child: Padding(padding: const EdgeInsets.all(16), child: previewWidget)),
          Expanded(flex: 6, child: controlsWidget),
        ],
      );
    } else {
      return Column(
        children: [
          Expanded(flex: 5, child: Padding(padding: const EdgeInsets.all(12), child: previewWidget)),
          Expanded(flex: 6, child: controlsWidget),
        ],
      );
    }
  }

  // ===========================================================================
  // ZAKŁADKA 2: MALOWANIE RAMY ROWERU
  // ===========================================================================

  Widget _buildBikePaintTab(bool isWide) {
    final bikePreview = Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            '${_config.bikeBrandName} • ${_config.bikeFinish.title}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.goldAccent, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: CustomPaint(
                  painter: _CustomBikePaintPainter(config: _config),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final controls = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Wybór wykończenia lakierniczego
        const Text('Wykończenie Lakiernicze (Finish Type):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        ...BikePaintFinishType.values.map((f) {
          final isSel = _config.bikeFinish == f;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSel ? AppColors.surfaceLight : AppColors.cardDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSel ? AppColors.goldAccent : AppColors.cardBorder),
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: f.previewColor,
                  radius: 12,
                ),
                title: Text(f.title, style: TextStyle(fontSize: 13, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text(f.description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                trailing: isSel ? const Icon(Icons.check_circle, color: AppColors.goldAccent, size: 20) : null,
                onTap: () => setState(() => _config = _config.copyWith(bikeFinish: f)),
              ),
            ),
          );
        }),

        const SizedBox(height: 16),

        // 2. Marka roweru
        TextFormField(
          controller: _bikeBrandCtrl,
          decoration: const InputDecoration(
            labelText: 'Kalkomanie Marki na Ramie (Down Tube Decals)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (val) => setState(() => _config = _config.copyWith(bikeBrandName: val)),
        ),

        const SizedBox(height: 16),

        // 3. Kolorystyka elementów roweru
        const Text('Kolorystyka Ramy i Komponentów:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        _buildColorPickerRow('Kolor Główny Ramy', _config.bikePrimaryColorHex, (hex) {
          setState(() => _config = _config.copyWith(bikePrimaryColorHex: hex));
        }),
        const SizedBox(height: 8),
        _buildColorPickerRow('Kolor Widelca i Trójkąta', _config.bikeAccentColorHex, (hex) {
          setState(() => _config = _config.copyWith(bikeAccentColorHex: hex));
        }),
        const SizedBox(height: 8),
        _buildColorPickerRow('Kolor Logotypu / Kalkomanii', _config.bikeDecalColorHex, (hex) {
          setState(() => _config = _config.copyWith(bikeDecalColorHex: hex));
        }),
        const SizedBox(height: 8),
        _buildColorPickerRow('Kolor Owijki Kierownicy', _config.barTapeColorHex, (hex) {
          setState(() => _config = _config.copyWith(barTapeColorHex: hex));
        }),

        const SizedBox(height: 16),

        // 4. Ścianki opon
        SwitchListTile(
          title: const Text('Klasyczne Ścianki Opon Tan-Wall (Bawełna)', style: TextStyle(fontSize: 13)),
          subtitle: const Text('Beżowy bok opony retro vs czarny stealth', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          value: _config.isTanWallTires,
          activeThumbColor: AppColors.goldAccent,
          onChanged: (val) => setState(() => _config = _config.copyWith(isTanWallTires: val)),
        ),
      ],
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(flex: 6, child: Padding(padding: const EdgeInsets.all(16), child: bikePreview)),
          Expanded(flex: 5, child: controls),
        ],
      );
    } else {
      return Column(
        children: [
          Expanded(flex: 5, child: Padding(padding: const EdgeInsets.all(12), child: bikePreview)),
          Expanded(flex: 6, child: controls),
        ],
      );
    }
  }

  // ===========================================================================
  // ZAKŁADKA 3: PRESETY PRO PELOTONU
  // ===========================================================================

  Widget _buildProPresetsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Gotowe Szablony Wizerunku z WorldTouru:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        _buildPresetTile(
          name: 'Team Visma | Lease a Bike Style',
          primary: '#FFD100', // Yellow
          secondary: '#002B49', // Dark Navy
          accent: '#FFFFFF',
          brand: 'CERVÉLO',
          finish: BikePaintFinishType.matteRawCarbon,
          tanWall: true,
          description: 'Słynna żółto-granatowa szerszeniowa barwa mistrzów Tour de France.',
          pattern: JerseyPattern.chestStripe,
        ),
        _buildPresetTile(
          name: 'UAE Team Emirates Style',
          primary: '#FFFFFF',
          secondary: '#DC2626',
          accent: '#000000',
          brand: 'COLNAGO',
          finish: BikePaintFinishType.raceLeaderGold,
          tanWall: false,
          description: 'Czysta biel z czerwonymi akcentami i złotą ramą Colnago V4Rs.',
          pattern: JerseyPattern.chevron,
        ),
        _buildPresetTile(
          name: 'Ineos Grenadiers Style',
          primary: '#0B132B',
          secondary: '#FF6B35',
          accent: '#FFFFFF',
          brand: 'PINARELLO',
          finish: BikePaintFinishType.metallicSilver,
          tanWall: false,
          description: 'Granat z jaskrawym pomarańczem i chromowaną ramą Dogma F.',
          pattern: JerseyPattern.contrastSleeves,
        ),
        _buildPresetTile(
          name: 'EF Education - EasyPost Style',
          primary: '#FF1493', // Deep Pink
          secondary: '#FFFFFF',
          accent: '#00E5FF',
          brand: 'CANNONDALE',
          finish: BikePaintFinishType.chameleonPrism,
          tanWall: true,
          description: 'Kultowy neonowy róż z pryzmatycznym kameleonem SuperSix EVO.',
          pattern: JerseyPattern.gradient,
        ),
        _buildPresetTile(
          name: 'Alpecin - Deceuninck Style',
          primary: '#1E3A8A', // Denim Blue
          secondary: '#DC2626',
          accent: '#FFFFFF',
          brand: 'CANYON',
          finish: BikePaintFinishType.stealthShadow,
          tanWall: true,
          description: 'Granatowy dżins z matową ramą Aeroad CFR Mathieu van der Poela.',
          pattern: JerseyPattern.solid,
        ),
      ],
    );
  }

  Widget _buildPresetTile({
    required String name,
    required String primary,
    required String secondary,
    required String accent,
    required String brand,
    required BikePaintFinishType finish,
    required bool tanWall,
    required String description,
    required JerseyPattern pattern,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 10, backgroundColor: _parseHex(primary, Colors.yellow)),
              const SizedBox(width: 4),
              CircleAvatar(radius: 10, backgroundColor: _parseHex(secondary, Colors.blue)),
            ],
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text('$description • Rama: $brand (${finish.title})',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.goldAccent),
          onTap: () {
            _applyPreset(
              name: name,
              pattern: pattern,
              primary: primary,
              secondary: secondary,
              accent: accent,
              bib: '#111317',
              gripper: primary,
              sponsor: name.split(' ')[0],
              sponsorSec: brand,
              brand: brand,
              finish: finish,
              bikePrimary: primary,
              bikeAccent: secondary,
              decal: '#FFFFFF',
              tanWall: tanWall,
            );
          },
        ),
      ),
    );
  }

  Widget _buildColorPickerRow(String label, String hexValue, ValueChanged<String> onChanged) {
    final curColor = _parseHex(hexValue, Colors.blue);

    final List<String> quickPalette = [
      '#002B49', '#FFD100', '#DC2626', '#FFFFFF', '#0B132B',
      '#FF6B35', '#FF1493', '#00E5FF', '#10B981', '#111317', '#8B5CF6'
    ];

    return Row(
      children: [
        CircleAvatar(radius: 14, backgroundColor: curColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text(hexValue.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ),
        // Chipy palety szybkiej
        Wrap(
          spacing: 4,
          children: quickPalette.map((h) {
            final col = _parseHex(h, Colors.transparent);
            return InkWell(
              onTap: () => onChanged(h),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: col,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static Color _parseHex(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      }
    } catch (_) {}
    return fallback;
  }
}

// =============================================================================
// RYSOWNIK PEŁNEGO STROJU: KOSZULKA + SPODENKI BIB SHORTS + PASKI MISTRZA
// =============================================================================

class _FullCyclingKitPainter extends CustomPainter {
  final TeamLiveryConfiguration config;
  final bool isBackView;

  _FullCyclingKitPainter({
    required this.config,
    required this.isBackView,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final primary = _parseHex(config.primaryColorHex, const Color(0xFF002B49));
    final secondary = _parseHex(config.secondaryColorHex, const Color(0xFFFFD100));
    final accent = _parseHex(config.accentColorHex, Colors.white);
    final bibColor = _parseHex(config.bibShortsColorHex, const Color(0xFF111317));
    final bibGripperColor = _parseHex(config.bibShortsGripperColorHex, const Color(0xFFFFD100));

    // 1. RYSOWANIE SPODENEK (BIB SHORTS) w dolnej części
    final bibPath = Path();
    bibPath.moveTo(w * 0.28, h * 0.52);
    bibPath.lineTo(w * 0.72, h * 0.52);
    bibPath.lineTo(w * 0.77, h * 0.88);
    bibPath.lineTo(w * 0.58, h * 0.88);
    bibPath.lineTo(w * 0.50, h * 0.68); // Krok
    bibPath.lineTo(w * 0.42, h * 0.88);
    bibPath.lineTo(w * 0.23, h * 0.88);
    bibPath.close();

    final bibPaint = Paint()
      ..color = bibColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(bibPath, bibPaint);

    // Paski nogawek (Grippers)
    final gripperPaint = Paint()
      ..color = bibGripperColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(w * 0.23, h * 0.85, w * 0.19, h * 0.03), gripperPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.58, h * 0.85, w * 0.19, h * 0.03), gripperPaint);

    // Kontur spodenek
    final bibStroke = Paint()
      ..color = Colors.black45
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(bibPath, bibStroke);

    // 2. RYSOWANIE KOSZULKI (JERSEY) w górnej części
    final jerseyPath = Path();
    // Kołnierzyk
    jerseyPath.moveTo(w * 0.38, h * 0.08);
    jerseyPath.quadraticBezierTo(w * 0.50, isBackView ? h * 0.09 : h * 0.13, w * 0.62, h * 0.08);
    jerseyPath.lineTo(w * 0.82, h * 0.16); // Prawe ramię
    jerseyPath.lineTo(w * 0.94, h * 0.30); // Prawy mankiet
    jerseyPath.lineTo(w * 0.83, h * 0.35);
    jerseyPath.lineTo(w * 0.74, h * 0.28); // Prawa pacha
    jerseyPath.lineTo(w * 0.72, h * 0.54); // Prawy bok biodra
    jerseyPath.quadraticBezierTo(w * 0.50, h * 0.56, w * 0.28, h * 0.54); // Dolny pas
    jerseyPath.lineTo(w * 0.26, h * 0.28); // Lewy bok
    jerseyPath.lineTo(w * 0.17, h * 0.35);
    jerseyPath.lineTo(w * 0.06, h * 0.30); // Lewy mankiet
    jerseyPath.lineTo(w * 0.18, h * 0.16); // Lewe ramię
    jerseyPath.close();

    // Wypełnienie bazowe koszulki
    final jerseyPaint = Paint()
      ..color = primary
      ..style = PaintingStyle.fill;
    canvas.drawPath(jerseyPath, jerseyPaint);

    // Wzór koszulki
    canvas.save();
    canvas.clipPath(jerseyPath);
    _paintPattern(canvas, w, h, primary, secondary, accent);
    canvas.restore();

    // Paski Mistrzowskie na mankietach rękawków
    _paintChampionBands(canvas, w, h);

    // Zamek błyskawiczny lub kieszonki z tyłu
    if (isBackView) {
      // 3 kieszonki
      final pocketPaint = Paint()
        ..color = secondary.withAlpha(160)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(w * 0.31, h * 0.40, w * 0.38, h * 0.13), pocketPaint);

      final linePaint = Paint()
        ..color = Colors.black38
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(w * 0.435, h * 0.40), Offset(w * 0.435, h * 0.53), linePaint);
      canvas.drawLine(Offset(w * 0.565, h * 0.40), Offset(w * 0.565, h * 0.53), linePaint);
    } else {
      // Zamek z przodu
      final zipPaint = Paint()
        ..color = Colors.black45
        ..strokeWidth = 1.8;
      canvas.drawLine(Offset(w * 0.50, h * 0.13), Offset(w * 0.50, h * 0.54), zipPaint);
    }

    // Napis sponsora na piersi
    _paintSponsorText(canvas, w, h);

    // Kontur koszulki
    final outlinePaint = Paint()
      ..color = Colors.black38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(jerseyPath, outlinePaint);
  }

  void _paintPattern(Canvas canvas, double w, double h, Color p, Color s, Color a) {
    final sPaint = Paint()..color = s..style = PaintingStyle.fill;
    final aPaint = Paint()..color = a..style = PaintingStyle.fill;

    switch (config.jerseyPattern) {
      case JerseyPattern.chestStripe:
        canvas.drawRect(Rect.fromLTWH(0, h * 0.22, w, h * 0.12), sPaint);
        canvas.drawRect(Rect.fromLTWH(0, h * 0.34, w, h * 0.015), aPaint);
        break;
      case JerseyPattern.chevron:
        final path = Path();
        path.moveTo(0, h * 0.20);
        path.lineTo(w * 0.50, h * 0.36);
        path.lineTo(w, h * 0.20);
        path.lineTo(w, h * 0.28);
        path.lineTo(w * 0.50, h * 0.44);
        path.lineTo(0, h * 0.28);
        path.close();
        canvas.drawPath(path, sPaint);
        break;
      case JerseyPattern.gradient:
        final gradPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p, s],
          ).createShader(Rect.fromLTWH(0, 0, w, h));
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), gradPaint);
        break;
      case JerseyPattern.contrastSleeves:
        canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.26, h * 0.40), sPaint);
        canvas.drawRect(Rect.fromLTWH(w * 0.74, 0, w * 0.26, h * 0.40), sPaint);
        break;
      case JerseyPattern.verticalStripes:
        for (int i = 0; i < 5; i++) {
          if (i % 2 == 1) {
            canvas.drawRect(Rect.fromLTWH(w * (0.30 + i * 0.08), 0, w * 0.06, h), sPaint);
          }
        }
        break;
      default:
        break;
    }
  }

  void _paintChampionBands(Canvas canvas, double w, double h) {
    if (config.championBands == ChampionBandsType.none) return;

    // Rysowanie tęczowych pasków lub barw narodowych na lewym i prawym mankiecie
    final List<Color> bandsColors = [];
    if (config.championBands == ChampionBandsType.worldChampionRainbow) {
      // 5 tęczowych pasów UCI: błękitny, czerwony, czarny, żółty, zielony
      bandsColors.addAll([
        const Color(0xFF00E5FF),
        const Color(0xFFDC2626),
        Colors.black,
        const Color(0xFFFFD700),
        const Color(0xFF10B981),
      ]);
    } else if (config.championBands == ChampionBandsType.poland) {
      bandsColors.addAll([Colors.white, const Color(0xFFDC2626)]);
    } else if (config.championBands == ChampionBandsType.italy) {
      bandsColors.addAll([const Color(0xFF10B981), Colors.white, const Color(0xFFDC2626)]);
    } else if (config.championBands == ChampionBandsType.france) {
      bandsColors.addAll([const Color(0xFF1E3A8A), Colors.white, const Color(0xFFDC2626)]);
    } else {
      bandsColors.addAll([Colors.white, AppColors.goldAccent, Colors.black]);
    }

    final double bandWidth = (w * 0.08) / bandsColors.length;

    // Lewy mankiet
    for (int i = 0; i < bandsColors.length; i++) {
      final p = Paint()..color = bandsColors[i]..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(w * 0.07 + (i * bandWidth), h * 0.30, bandWidth, h * 0.04), p);
      canvas.drawRect(Rect.fromLTWH(w * 0.85 + (i * bandWidth), h * 0.30, bandWidth, h * 0.04), p);
    }
  }

  void _paintSponsorText(Canvas canvas, double w, double h) {
    final text = config.sponsorMainText;
    if (text.isEmpty) return;

    final tp = TextPainter(
      text: TextSpan(
        text: text.toUpperCase(),
        style: TextStyle(
          color: _parseHex(config.sponsorTextColorHex, Colors.white),
          fontWeight: FontWeight.w900,
          fontSize: math.max(10.0, w * 0.08),
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(w * 0.50 - (tp.width / 2), isBackView ? h * 0.28 : h * 0.24));
  }

  static Color _parseHex(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) return Color(int.parse('0xFF$clean'));
    } catch (_) {}
    return fallback;
  }

  @override
  bool shouldRepaint(covariant _FullCyclingKitPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.isBackView != isBackView;
  }
}

// =============================================================================
// RYSOWNIK MALOWANIA RAMY: TEAM ISSUE CUSTOM PAINT
// =============================================================================

class _CustomBikePaintPainter extends CustomPainter {
  final TeamLiveryConfiguration config;

  _CustomBikePaintPainter({required this.config});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Koła i opony (Drive-side)
    final wheelRadius = h * 0.33;
    final rearCenter = Offset(w * 0.22, h * 0.60);
    final frontCenter = Offset(w * 0.78, h * 0.60);

    // Opony (Tan-wall lub Black-wall)
    final tireColor = config.isTanWallTires ? const Color(0xFFC2A675) : const Color(0xFF1E2024);
    final tirePaint = Paint()
      ..color = tireColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.038;
    canvas.drawCircle(rearCenter, wheelRadius, tirePaint);
    canvas.drawCircle(frontCenter, wheelRadius, tirePaint);

    // Karbonowe stożki kół 50mm
    final rimPaint = Paint()
      ..color = const Color(0xFF111317)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.065;
    canvas.drawCircle(rearCenter, wheelRadius - (h * 0.03), rimPaint);
    canvas.drawCircle(frontCenter, wheelRadius - (h * 0.03), rimPaint);

    // 2. RAMA ROWERU Z LAKIEREM SPECJALNYM
    final bb = Offset(w * 0.44, h * 0.60); // Środek suportu
    final seatCluster = Offset(w * 0.38, h * 0.30); // Łączenie rury podsiodłowej
    final headBottom = Offset(w * 0.70, h * 0.30); // Główka dolna
    final headTop = Offset(w * 0.68, h * 0.22); // Główka górna

    // Wybór koloru/efektu lakierniczego
    Paint framePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = h * 0.055..strokeCap = StrokeCap.round;

    final primaryCol = _parseHex(config.bikePrimaryColorHex, const Color(0xFFFFD100));
    final accentCol = _parseHex(config.bikeAccentColorHex, const Color(0xFF111317));

    switch (config.bikeFinish) {
      case BikePaintFinishType.chameleonPrism:
        framePaint.shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5CF6), // Fiolet
            Color(0xFF00E5FF), // Cyan
            Color(0xFF10B981), // Szmaragd
            Color(0xFFFFD700), // Złoto
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h));
        break;
      case BikePaintFinishType.metallicSilver:
        framePaint.shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFF94A3B8),
            Color(0xFFE2E8F0),
            Color(0xFF64748B),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h));
        break;
      case BikePaintFinishType.raceLeaderGold:
        framePaint.shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF078),
            Color(0xFFFFD700),
            Color(0xFFA67C00),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h));
        break;
      case BikePaintFinishType.matteRawCarbon:
        framePaint.color = const Color(0xFF1A1C20);
        break;
      case BikePaintFinishType.stealthShadow:
        framePaint.color = const Color(0xFF0D0E11);
        break;
      case BikePaintFinishType.glossySolid:
        framePaint.color = primaryCol;
        break;
    }

    // Główne rury ramy:
    // Rura dolna (Down tube)
    canvas.drawLine(headBottom, bb, framePaint);
    // Rura górna (Top tube)
    canvas.drawLine(headTop, seatCluster, framePaint);
    // Rura podsiodłowa (Seat tube)
    canvas.drawLine(seatCluster, bb, framePaint);
    // Główka ramy (Head tube)
    canvas.drawLine(headBottom, headTop, framePaint);

    // Widelec i tylny trójkąt (kolor akcentu)
    final forkPaint = Paint()
      ..color = accentCol
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.045
      ..strokeCap = StrokeCap.round;

    // Widelec przedni
    canvas.drawLine(headBottom, frontCenter, forkPaint);
    // Dolne widełki tylne (Chainstays)
    canvas.drawLine(bb, rearCenter, forkPaint);
    // Górne widełki tylne (Seatstays)
    canvas.drawLine(seatCluster, rearCenter, forkPaint);

    // Sztyca podsiodłowa i siodło
    final postPaint = Paint()..color = const Color(0xFF111317)..strokeWidth = h * 0.038;
    canvas.drawLine(seatCluster, Offset(w * 0.36, h * 0.20), postPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.36, h * 0.18), width: w * 0.10, height: h * 0.025), const Radius.circular(4)),
      postPaint,
    );

    // Kokpit i owijka kierownicy
    final barTapeCol = _parseHex(config.barTapeColorHex, const Color(0xFF111317));
    final barPaint = Paint()..color = barTapeCol..strokeWidth = h * 0.035..strokeCap = StrokeCap.round;
    // Mostek
    canvas.drawLine(headTop, Offset(w * 0.74, h * 0.19), barPaint);
    // Baranek
    canvas.drawLine(Offset(w * 0.74, h * 0.19), Offset(w * 0.77, h * 0.26), barPaint);

    // 3. KALKOMANIE MARKI NA RURZE DOLNEJ
    final brandText = config.bikeBrandName;
    if (brandText.isNotEmpty) {
      final decalPaint = TextPainter(
        text: TextSpan(
          text: brandText.toUpperCase(),
          style: TextStyle(
            color: _parseHex(config.bikeDecalColorHex, Colors.white),
            fontWeight: FontWeight.w900,
            fontSize: math.max(9.0, h * 0.045),
            letterSpacing: 2.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      decalPaint.layout();

      canvas.save();
      // Kąt stoku rury dolnej
      canvas.translate(w * 0.56, h * 0.44);
      canvas.rotate(0.52); // ~30 stopni
      decalPaint.paint(canvas, Offset(-decalPaint.width / 2, -decalPaint.height / 2));
      canvas.restore();
    }
  }

  static Color _parseHex(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) return Color(int.parse('0xFF$clean'));
    } catch (_) {}
    return fallback;
  }

  @override
  bool shouldRepaint(covariant _CustomBikePaintPainter oldDelegate) {
    return oldDelegate.config != config;
  }
}
