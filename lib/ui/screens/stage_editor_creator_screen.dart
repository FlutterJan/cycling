// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/race/tour_race.dart';
import '../../state/career_controller.dart';
import '../widgets/custom_race_route_elevation_brush.dart';

/// Punkt kontrolny wysokości i nawierzchni na trasie edytowanego etapu.
class StageEditorPoint {
  final String id;
  final double distanceKm;
  final double elevationMeters;
  final SegmentSurfaceType surfaceType;
  final SegmentClassification classification;
  final double technicalDifficulty;
  final String note;
  final double roadBearingDegrees;
  final double windDirectionDegrees;

  const StageEditorPoint({
    required this.id,
    required this.distanceKm,
    required this.elevationMeters,
    this.surfaceType = SegmentSurfaceType.smoothAsphalt,
    this.classification = SegmentClassification.none,
    this.technicalDifficulty = 35.0,
    this.note = '',
    this.roadBearingDegrees = 90.0,
    this.windDirectionDegrees = 180.0,
  });

  StageEditorPoint copyWith({
    String? id,
    double? distanceKm,
    double? elevationMeters,
    SegmentSurfaceType? surfaceType,
    SegmentClassification? classification,
    double? technicalDifficulty,
    String? note,
    double? roadBearingDegrees,
    double? windDirectionDegrees,
  }) {
    return StageEditorPoint(
      id: id ?? this.id,
      distanceKm: distanceKm ?? this.distanceKm,
      elevationMeters: elevationMeters ?? this.elevationMeters,
      surfaceType: surfaceType ?? this.surfaceType,
      classification: classification ?? this.classification,
      technicalDifficulty: technicalDifficulty ?? this.technicalDifficulty,
      note: note ?? this.note,
      roadBearingDegrees: roadBearingDegrees ?? this.roadBearingDegrees,
      windDirectionDegrees: windDirectionDegrees ?? this.windDirectionDegrees,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'distanceKm': distanceKm,
      'elevationMeters': elevationMeters,
      'surfaceType': surfaceType.toJson(),
      'classification': classification.toJson(),
      'technicalDifficulty': technicalDifficulty,
      'note': note,
      'roadBearingDegrees': roadBearingDegrees,
      'windDirectionDegrees': windDirectionDegrees,
    };
  }

  factory StageEditorPoint.fromJson(Map<String, dynamic> json) {
    return StageEditorPoint(
      id: json['id'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      elevationMeters: (json['elevationMeters'] as num).toDouble(),
      surfaceType: SegmentSurfaceType.fromJson(json['surfaceType'] as String),
      classification: SegmentClassification.fromJson(json['classification'] as String),
      technicalDifficulty: (json['technicalDifficulty'] as num?)?.toDouble() ?? 35.0,
      note: json['note'] as String? ?? '',
      roadBearingDegrees: (json['roadBearingDegrees'] as num?)?.toDouble() ?? 90.0,
      windDirectionDegrees: (json['windDirectionDegrees'] as num?)?.toDouble() ?? 180.0,
    );
  }
}

/// Wbudowany w grę Kreator Etapów i Wyścigów (Stage & Race Builder).
///
/// Pozwala graczowi:
/// - Rysować profil wysokościowy z punktami kontrolnymi
/// - Ustalać nawierzchnię (asfalt gładki, szorstki, bruki 1-5★, toskański szuter)
/// - Oznaczać premie górskie (KOM 4, 3, 2, 1, HC) oraz lotne premie sprinterskie
/// - Wybierać z gotowych presetów inspiracji (np. Klasyk Wrocław-Sobótka ze Ślężą i brukiem, Tatry, Roubaix)
/// - Zapisywać gotowy wyścig bezpośrednio do kalendarza aktywnej kariery.
class StageEditorCreatorScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final void Function(TourRace race)? onRaceSaved;

  const StageEditorCreatorScreen({
    super.key,
    this.onBack,
    this.onRaceSaved,
  });

  @override
  ConsumerState<StageEditorCreatorScreen> createState() => _StageEditorCreatorScreenState();
}

class _StageEditorCreatorScreenState extends ConsumerState<StageEditorCreatorScreen> {
  // Kontrolery pól tekstowych metadanych wyścigu
  late final TextEditingController _raceNameCtrl;
  late final TextEditingController _stageNameCtrl;
  late final TextEditingController _prizePoolCtrl;
  late final TextEditingController _countryIsoCtrl;

  RaceCategory _selectedCategory = RaceCategory.worldTourOneDay;
  StageType _selectedStageType = StageType.hilly;
  int _startMonth = 5; // Maj
  int _startDay = 24;
  double _baseTemperatureCelsius = 22.0;
  WeatherCondition _baseWeather = WeatherCondition.sunny;
  double _baseWindSpeedKmh = 14.0;

  // Lista punktów wysokościowych profilu
  List<StageEditorPoint> _points = [];
  int _selectedPointIndex = 0;

  // Widok pomocniczy: 0 = Edytor punktu, 1 = Lista punktów, 2 = Ustawienia wyścigu
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _raceNameCtrl = TextEditingController(text: 'Klasyk Dolnośląski: Wrocław - Sobótka (Ślęża)');
    _stageNameCtrl = TextEditingController(text: 'Etap 1: Ślężański Szlem, Ścianki & Bruk Sobótki');
    _prizePoolCtrl = TextEditingController(text: '45000');
    _countryIsoCtrl = TextEditingController(text: 'POL');

    _loadSobotkaClassicPreset();
  }

  @override
  void dispose() {
    _raceNameCtrl.dispose();
    _stageNameCtrl.dispose();
    _prizePoolCtrl.dispose();
    _countryIsoCtrl.dispose();
    super.dispose();
  }

  // ===========================================================================
  // SZABLONY I PRESETY INSPIRACJI
  // ===========================================================================

  /// Preset 1: Klasyk Wrocław - Sobótka (Masyw Ślęży, Ścianki i Bruki Rynku w Sobótce)
  void _loadSobotkaClassicPreset() {
    setState(() {
      _raceNameCtrl.text = 'Klasyk Dolnośląski: Wrocław - Sobótka (Ślęża)';
      _stageNameCtrl.text = 'Etap 1: Ślężański Szlem, Ścianki & Bruk Sobótki';
      _countryIsoCtrl.text = 'POL';
      _selectedCategory = RaceCategory.worldTourOneDay;
      _selectedStageType = StageType.hilly;
      _startMonth = 5;
      _startDay = 24;
      _baseTemperatureCelsius = 22.0;
      _baseWeather = WeatherCondition.sunny;
      _baseWindSpeedKmh = 16.0;

      _points = [
        const StageEditorPoint(
          id: 'p_0',
          distanceKm: 0.0,
          elevationMeters: 120.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.none,
          note: 'Wrocław Rynek - Start Honorowy',
        ),
        const StageEditorPoint(
          id: 'p_1',
          distanceKm: 25.0,
          elevationMeters: 145.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.none,
          note: 'Kobierzyce - Szosa Dolnośląska',
        ),
        const StageEditorPoint(
          id: 'p_2',
          distanceKm: 50.0,
          elevationMeters: 180.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.intermediateSprint,
          note: 'Mirosławice - Lotna Premia',
        ),
        const StageEditorPoint(
          id: 'p_3',
          distanceKm: 70.0,
          elevationMeters: 210.0,
          surfaceType: SegmentSurfaceType.cobblestonesSector3,
          classification: SegmentClassification.none,
          note: 'Sobótka Rynek - Sektor Bruku 3★ (Runda 1)',
        ),
        const StageEditorPoint(
          id: 'p_4',
          distanceKm: 78.5,
          elevationMeters: 384.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.cat2,
          technicalDifficulty: 65.0,
          note: 'Przełęcz Tąpadła (Ślęża 7.8%) - Premia Górska 2. Kat',
        ),
        const StageEditorPoint(
          id: 'p_5',
          distanceKm: 92.0,
          elevationMeters: 195.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.none,
          note: 'Sulistrowiczki - Zjazd Techniczny',
        ),
        const StageEditorPoint(
          id: 'p_6',
          distanceKm: 115.0,
          elevationMeters: 210.0,
          surfaceType: SegmentSurfaceType.cobblestonesSector3,
          classification: SegmentClassification.none,
          note: 'Sobótka Rynek - Sektor Bruku 3★ (Runda 2)',
        ),
        const StageEditorPoint(
          id: 'p_7',
          distanceKm: 123.5,
          elevationMeters: 384.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.cat2,
          technicalDifficulty: 70.0,
          note: 'Przełęcz Tąpadła (Ścianka pod Ślężę) - Premia 2. Kat',
        ),
        const StageEditorPoint(
          id: 'p_8',
          distanceKm: 145.0,
          elevationMeters: 190.0,
          surfaceType: SegmentSurfaceType.gravelStrade,
          classification: SegmentClassification.none,
          note: 'Biała Droga Szutrowa pod Wieżycą',
        ),
        const StageEditorPoint(
          id: 'p_9',
          distanceKm: 165.0,
          elevationMeters: 290.0,
          surfaceType: SegmentSurfaceType.cobblestonesSector4,
          classification: SegmentClassification.cat3,
          note: 'Górka pod Wieżycą - Bruk 4★ i Ścianka 14%',
        ),
        const StageEditorPoint(
          id: 'p_10',
          distanceKm: 174.0,
          elevationMeters: 345.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.finishLine,
          note: 'Schronisko pod Wieżycą - Finałowa Ścianka i Meta!',
        ),
      ];
      _selectedPointIndex = 0;
    });
  }

  /// Preset 2: Królewski Etap w Tatrach (Zakopane - Bukowina Tatrzańska - Tatrzańska Łomnica)
  void _loadTatryMountainPreset() {
    setState(() {
      _raceNameCtrl.text = 'Królewski Wyścig Tatrzański: Tour des Tatras';
      _stageNameCtrl.text = 'Etap Królewski: Zakopane - Ściana Bukovina - Morskie Oko';
      _countryIsoCtrl.text = 'POL';
      _selectedCategory = RaceCategory.worldTourStageRace;
      _selectedStageType = StageType.highMountain;
      _startMonth = 8;
      _startDay = 15;
      _baseTemperatureCelsius = 19.0;
      _baseWeather = WeatherCondition.overcast;
      _baseWindSpeedKmh = 22.0;

      _points = [
        const StageEditorPoint(
          id: 't_0',
          distanceKm: 0.0,
          elevationMeters: 840.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.none,
          note: 'Zakopane Krupówki - Start Ostrzeżony',
        ),
        const StageEditorPoint(
          id: 't_1',
          distanceKm: 22.0,
          elevationMeters: 960.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.none,
          note: 'Poronin - Dojazd Doliną',
        ),
        const StageEditorPoint(
          id: 't_2',
          distanceKm: 45.0,
          elevationMeters: 1138.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.cat1,
          technicalDifficulty: 55.0,
          note: 'Głodówka Panorama Tatr - Premia Górska 1. Kat',
        ),
        const StageEditorPoint(
          id: 't_3',
          distanceKm: 68.0,
          elevationMeters: 810.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.none,
          note: 'Białka Tatrzańska - Bufet i Dno Doliny',
        ),
        const StageEditorPoint(
          id: 't_4',
          distanceKm: 85.0,
          elevationMeters: 1010.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.cat1,
          technicalDifficulty: 75.0,
          note: 'Ściana Bukovina (Max 22%) - Legendarna Stroma Rampa',
        ),
        const StageEditorPoint(
          id: 't_5',
          distanceKm: 110.0,
          elevationMeters: 920.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.intermediateSprint,
          note: 'Łysa Polana - Granica Państwa & Lotna Premia',
        ),
        const StageEditorPoint(
          id: 't_6',
          distanceKm: 138.0,
          elevationMeters: 1850.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.horsCategorie,
          technicalDifficulty: 85.0,
          note: 'Wysokogórska Przełęcz Tatrzańska (HC) - Cima Coppi 1850m!',
        ),
        const StageEditorPoint(
          id: 't_7',
          distanceKm: 156.0,
          elevationMeters: 1150.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.none,
          technicalDifficulty: 88.0,
          note: 'Alpejski Zjazd Serpentynami - Wymagana Kurtka!',
        ),
        const StageEditorPoint(
          id: 't_8',
          distanceKm: 168.0,
          elevationMeters: 980.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.finishLine,
          note: 'Tatrzańska Łomnica - Meta Królewskiego Etapu',
        ),
      ];
      _selectedPointIndex = 0;
    });
  }

  /// Preset 3: Piekło Północy (Sektory Brukowe Roubaix 1-5★)
  void _loadCobbledClassicPreset() {
    setState(() {
      _raceNameCtrl.text = 'Piekło Północy: Custom Paris-Roubaix';
      _stageNameCtrl.text = 'Etap: Bitwa o Bruki & Lasek Arenberg';
      _countryIsoCtrl.text = 'FRA';
      _selectedCategory = RaceCategory.monument;
      _selectedStageType = StageType.cobbleClassic;
      _startMonth = 4;
      _startDay = 12;
      _baseTemperatureCelsius = 15.0;
      _baseWeather = WeatherCondition.lightRain;
      _baseWindSpeedKmh = 26.0;

      _points = [
        const StageEditorPoint(
          id: 'c_0',
          distanceKm: 0.0,
          elevationMeters: 45.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.none,
          note: 'Compiègne - Start Monumentu',
        ),
        const StageEditorPoint(
          id: 'c_1',
          distanceKm: 60.0,
          elevationMeters: 55.0,
          surfaceType: SegmentSurfaceType.cobblestonesSector2,
          classification: SegmentClassification.none,
          note: 'Sektor 2★ Troisvilles',
        ),
        const StageEditorPoint(
          id: 'c_2',
          distanceKm: 95.0,
          elevationMeters: 40.0,
          surfaceType: SegmentSurfaceType.cobblestonesSector3,
          classification: SegmentClassification.none,
          note: 'Sektor 3★ Haveluy',
        ),
        const StageEditorPoint(
          id: 'c_3',
          distanceKm: 120.0,
          elevationMeters: 38.0,
          surfaceType: SegmentSurfaceType.cobblestonesSector5,
          classification: SegmentClassification.none,
          note: 'Trouée d\'Arenberg (Lasek Arenberg 5★ - Piekło na Ziemi)',
        ),
        const StageEditorPoint(
          id: 'c_4',
          distanceKm: 155.0,
          elevationMeters: 42.0,
          surfaceType: SegmentSurfaceType.cobblestonesSector4,
          classification: SegmentClassification.none,
          note: 'Sektor 4★ Mons-en-Pévèle',
        ),
        const StageEditorPoint(
          id: 'c_5',
          distanceKm: 178.0,
          elevationMeters: 35.0,
          surfaceType: SegmentSurfaceType.cobblestonesSector5,
          classification: SegmentClassification.none,
          note: 'Carrefour de l\'Arbre (5★ Decydujący Atak!)',
        ),
        const StageEditorPoint(
          id: 'c_6',
          distanceKm: 192.0,
          elevationMeters: 30.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.finishLine,
          note: 'Welodrom Roubaix - Runda Honorowa i Meta!',
        ),
      ];
      _selectedPointIndex = 0;
    });
  }

  // ===========================================================================
  // KALKULACJE STATYSTYK NA ŻYWO
  // ===========================================================================

  double get _totalDistanceKm => _points.isNotEmpty ? _points.last.distanceKm : 0.0;

  double get _maxElevationM {
    if (_points.isEmpty) return 0.0;
    return _points.map((p) => p.elevationMeters).reduce(math.max);
  }

  double get _totalElevationGainM {
    if (_points.length < 2) return 0.0;
    double gain = 0.0;
    for (int i = 0; i < _points.length - 1; i++) {
      final diff = _points[i + 1].elevationMeters - _points[i].elevationMeters;
      if (diff > 0) gain += diff;
    }
    return gain;
  }

  double get _cobblestonesKm {
    if (_points.length < 2) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < _points.length - 1; i++) {
      final pNext = _points[i + 1];
      if (pNext.surfaceType.name.contains('cobble')) {
        sum += (pNext.distanceKm - _points[i].distanceKm);
      }
    }
    return sum;
  }

  double get _gravelKm {
    if (_points.length < 2) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < _points.length - 1; i++) {
      final pNext = _points[i + 1];
      if (pNext.surfaceType == SegmentSurfaceType.gravelStrade) {
        sum += (pNext.distanceKm - _points[i].distanceKm);
      }
    }
    return sum;
  }

  int get _komCount {
    return _points.where((p) =>
        p.classification == SegmentClassification.cat4 ||
        p.classification == SegmentClassification.cat3 ||
        p.classification == SegmentClassification.cat2 ||
        p.classification == SegmentClassification.cat1 ||
        p.classification == SegmentClassification.horsCategorie).length;
  }

  int get _sprintCount {
    return _points.where((p) => p.classification == SegmentClassification.intermediateSprint).length;
  }

  // ===========================================================================
  // METODY MANIPULACJI PUNKTAMI
  // ===========================================================================

  void _addPointAfter(int index) {
    if (_points.isEmpty) return;

    final cur = _points[index];
    final double newDist = index < _points.length - 1
        ? (cur.distanceKm + _points[index + 1].distanceKm) / 2.0
        : cur.distanceKm + 15.0;
    final double newAlt = index < _points.length - 1
        ? (cur.elevationMeters + _points[index + 1].elevationMeters) / 2.0
        : cur.elevationMeters + 50.0;

    final newPoint = StageEditorPoint(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      distanceKm: double.parse(newDist.toStringAsFixed(1)),
      elevationMeters: double.parse(newAlt.toStringAsFixed(0)),
      surfaceType: cur.surfaceType,
      classification: SegmentClassification.none,
      note: 'Nowy punkt trasy',
    );

    setState(() {
      _points.insert(index + 1, newPoint);
      _selectedPointIndex = index + 1;
    });
  }

  void _removePoint(int index) {
    if (_points.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Etap musi posiadać co najmniej 2 punkty (początek i koniec trasy)!'),
          backgroundColor: AppColors.crimsonAlert,
        ),
      );
      return;
    }

    setState(() {
      _points.removeAt(index);
      if (_selectedPointIndex >= _points.length) {
        _selectedPointIndex = _points.length - 1;
      }
    });
  }

  void _updateActivePoint(StageEditorPoint updated) {
    setState(() {
      _points[_selectedPointIndex] = updated;
      // Zapewniamy porządek chronologiczny według dystansu
      _points.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      _selectedPointIndex = _points.indexOf(updated);
    });
  }

  // ===========================================================================
  // BUDOWANIE OBIEKTU TOUR RACE I ZAPIS DO KALENDARZA KARIERY
  // ===========================================================================

  TourRace _buildTourRace() {
    // 1. Walidacja
    if (_points.length < 2) {
      throw StateError('Etap musi mieć co najmniej 2 punkty!');
    }

    // 2. Generowanie obiektów StageSegment pomiędzy kolejnymi punktami
    final List<StageSegment> segments = [];
    for (int i = 0; i < _points.length - 1; i++) {
      final pStart = _points[i];
      final pEnd = _points[i + 1];
      final double segLength = math.max(0.5, pEnd.distanceKm - pStart.distanceKm);

      segments.add(StageSegment(
        index: i,
        startKm: pStart.distanceKm,
        lengthKm: segLength,
        startElevationM: pStart.elevationMeters,
        endElevationM: pEnd.elevationMeters,
        surfaceType: pEnd.surfaceType,
        technicalDifficulty: pEnd.technicalDifficulty,
        windDirectionDegrees: pEnd.windDirectionDegrees,
        roadBearingDegrees: pEnd.roadBearingDegrees,
        sprintOrKomClassification: pEnd.classification,
      ));
    }

    // 3. Budowa etapu RaceStage
    final raceId = 'custom_race_${DateTime.now().millisecondsSinceEpoch}';
    final stageId = '${raceId}_stg_1';

    final stage = RaceStage(
      id: stageId,
      stageNumber: 1,
      name: _stageNameCtrl.text.trim().isNotEmpty
          ? _stageNameCtrl.text.trim()
          : 'Etap 1: Autorski Wyścig',
      stageType: _selectedStageType,
      segments: segments,
      baseTemperatureCelsius: _baseTemperatureCelsius,
      weatherCondition: _baseWeather,
      windSpeedKmh: _baseWindSpeedKmh,
    );

    // 4. Budowa wyścigu TourRace
    final int prizePool = int.tryParse(_prizePoolCtrl.text.trim()) ?? 40000;
    final country = _countryIsoCtrl.text.trim().toUpperCase().isNotEmpty
        ? _countryIsoCtrl.text.trim().toUpperCase()
        : 'POL';

    return TourRace(
      id: raceId,
      name: _raceNameCtrl.text.trim().isNotEmpty
          ? _raceNameCtrl.text.trim()
          : 'Autorski Klasyk Gracza',
      countryIso: country,
      uciCategory: _selectedCategory,
      startMonth: _startMonth,
      startDay: _startDay,
      stages: [stage],
      prizePoolEur: prizePool,
      participatingTeamIds: const [],
      ridersPerTeam: 7,
      classifications: const RaceClassifications(
        generalClassification: [],
        pointsClassification: [],
        mountainsClassification: [],
        youthClassification: [],
        teamClassification: [],
      ),
    );
  }

  Future<void> _saveRaceToCareer() async {
    try {
      final race = _buildTourRace();

      // Wywołanie kontrolera kariery
      final success = await ref.read(careerControllerProvider.notifier).addCustomRaceToCalendar(race);

      if (widget.onRaceSaved != null) {
        widget.onRaceSaved!(race);
      }

      if (!mounted) return;

      _showSuccessDialog(race, isCareerSaved: success);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd zapisu wyścigu: $e'),
          backgroundColor: AppColors.crimsonAlert,
        ),
      );
    }
  }

  void _showSuccessDialog(TourRace race, {required bool isCareerSaved}) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.goldAccent, width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.verified, color: AppColors.goldAccent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Wyścig Zapisany do Kalendarza!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                race.name,
                style: const TextStyle(
                  color: AppColors.goldAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Data w kalendarzu: ${race.startDay} ${_getMonthName(race.startMonth)} 2026',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              Text(
                'Dystans: ${race.totalRaceDistanceKm.toStringAsFixed(1)} km  •  Przewyższenie: +${race.totalRaceElevationGainM.round()} m',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                'Kategoria UCI: ${race.uciCategory.name.toUpperCase()}  •  Pula nagród: ${race.prizePoolEur} €',
                style: const TextStyle(color: AppColors.accentBlue, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  isCareerSaved
                      ? '✓ Wyścig został oficjalnie zarejestrowany w Twojej aktywnej karierze menedżera. Będziesz mógł wystawić swój skład w kalendarzu wyścigów!'
                      : 'Wyścig wygenerowany pomyślnie i gotowy do symulacji.',
                  style: const TextStyle(color: AppColors.statusSuccess, fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final jsonStr = jsonEncode(race.toJson());
                Clipboard.setData(ClipboardData(text: jsonStr));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil wyścigu skopiowany do schowka (JSON)!')),
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
              child: const Text('Powrót do Gry', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Stycznia', 'Lutego', 'Marca', 'Kwietnia', 'Maja', 'Czerwca',
      'Lipca', 'Sierpnia', 'Września', 'Października', 'Listopada', 'Grudnia'
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : 'Miesiąca $month';
  }

  // ===========================================================================
  // BUDOWA INTERFEJSU UŻYTKOWNIKA (BUILD METHOD)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final activePoint = _points.isNotEmpty && _selectedPointIndex < _points.length
        ? _points[_selectedPointIndex]
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kreator Etapów i Wyścigów',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_totalDistanceKm.toStringAsFixed(1)} km  •  +${_totalElevationGainM.round()} m przewyższenia',
              style: const TextStyle(fontSize: 12, color: AppColors.goldAccent),
            ),
          ],
        ),
        actions: [
          // Przycisk wyboru gotowego szablonu
          PopupMenuButton<String>(
            icon: const Icon(Icons.auto_awesome, color: AppColors.goldAccent),
            tooltip: 'Załaduj gotowy szablon',
            onSelected: (val) {
              if (val == 'sobotka') _loadSobotkaClassicPreset();
              if (val == 'tatry') _loadTatryMountainPreset();
              if (val == 'cobbles') _loadCobbledClassicPreset();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'sobotka',
                child: Text('Klasyk Wrocław - Sobótka (Ślęża & Bruk)'),
              ),
              const PopupMenuItem(
                value: 'tatry',
                child: Text('Królewski Etap w Tatrach (Zakopane - Morskie Oko)'),
              ),
              const PopupMenuItem(
                value: 'cobbles',
                child: Text('Piekło Północy (Paris-Roubaix Bruk 1-5★)'),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Główny przycisk zapisu
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 8.0, bottom: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldAccent,
                foregroundColor: Colors.black,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              icon: const Icon(Icons.save, size: 18),
              label: const Text(
                'Zapisz do Kalendarza',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: _saveRaceToCareer,
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          return Column(
            children: [
              // 1. GÓRNY PASEK ZBIORCZY STATYSTYK
              _buildStatsHeaderBanner(),

              // 2. INTERAKTYWNY WYKRES PROFILU WYSOKOŚCIOWEGO Z PĘDZLEM TERENU
              Expanded(
                flex: isWide ? 5 : 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: CustomRaceRouteElevationBrush(
                    points: _points,
                    selectedPointIndex: _selectedPointIndex,
                    onPointsChanged: (updatedPoints) {
                      setState(() {
                        _points = updatedPoints;
                        if (_points.isEmpty) {
                          _selectedPointIndex = 0;
                        } else if (_selectedPointIndex >= _points.length) {
                          _selectedPointIndex = _points.length - 1;
                        }
                      });
                    },
                    onPointSelected: (index) {
                      setState(() {
                        _selectedPointIndex = index;
                        _activeTab = 0;
                      });
                    },
                  ),
                ),
              ),

              // 3. DOLNY PANEL EDYCJI PUNKTÓW I PARAMETRÓW ETAPU
              Expanded(
                flex: isWide ? 6 : 6,
                child: Material(
                  color: AppColors.surface,
                  child: Column(
                    children: [
                      // Pasek zakładek: Edycja Punktu / Lista / Metadane
                      _buildNavigationTabs(),
                      const Divider(height: 1, color: AppColors.cardBorder),
                      Expanded(
                        child: IndexedStack(
                          index: _activeTab,
                          children: [
                            // Zakładka 0: Edytor wybranego punktu
                            activePoint != null
                                ? _buildActivePointEditor(activePoint)
                                : const Center(child: Text('Wybierz punkt na profilu')),

                            // Zakładka 1: Tabela wszystkich punktów
                            _buildPointsListView(),

                            // Zakładka 2: Metadane wyścigu i warunki
                            _buildRaceSettingsView(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // WIDGETY SKŁADOWE EKRANU
  // ===========================================================================

  Widget _buildStatsHeaderBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surfaceLight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatPill(Icons.straighten, 'Dystans', '${_totalDistanceKm.toStringAsFixed(1)} km'),
          _buildStatPill(Icons.trending_up, 'Przewyższenie', '+${_totalElevationGainM.round()} m'),
          _buildStatPill(Icons.terrain, 'Szczyt', '${_maxElevationM.round()} m'),
          _buildStatPill(Icons.flag, 'Premie KOM', '$_komCount szt.'),
          _buildStatPill(Icons.speed, 'Sprinty', '$_sprintCount szt.'),
          if (_cobblestonesKm > 0)
            _buildStatPill(Icons.grid_view, 'Bruk', '${_cobblestonesKm.toStringAsFixed(1)} km', color: Colors.amber),
          if (_gravelKm > 0)
            _buildStatPill(Icons.grain, 'Szuter', '${_gravelKm.toStringAsFixed(1)} km', color: AppColors.accentBlue),
        ],
      ),
    );
  }

  Widget _buildStatPill(IconData icon, String label, String value, {Color? color}) {
    final activeColor = color ?? AppColors.goldAccent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: activeColor),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: activeColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationTabs() {
    return Material(
      color: AppColors.surface,
      child: Row(
        children: [
          _buildTabButton(0, 'Edycja Punktu (${_selectedPointIndex + 1}/${_points.length})', Icons.edit_location_alt),
          _buildTabButton(1, 'Lista Wszystkich Odcinków', Icons.list_alt),
          _buildTabButton(2, 'Parametry Wyścigu & Pogoda', Icons.settings),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.goldAccent : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AppColors.goldAccent : AppColors.textSecondary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ZAKŁADKA 0: EDYTOR AKTYWNEGO PUNKTU
  // ===========================================================================

  Widget _buildActivePointEditor(StageEditorPoint point) {
    // Obliczenie nachylenia z poprzedniego punktu
    double gradient = 0.0;
    double distDelta = 0.0;
    double altDelta = 0.0;
    if (_selectedPointIndex > 0) {
      final prev = _points[_selectedPointIndex - 1];
      distDelta = point.distanceKm - prev.distanceKm;
      altDelta = point.elevationMeters - prev.elevationMeters;
      if (distDelta > 0) {
        gradient = (altDelta / (distDelta * 1000.0)) * 100.0;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Pasek nawigacji między punktami
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _selectedPointIndex > 0
                  ? () => setState(() => _selectedPointIndex--)
                  : null,
            ),
            Text(
              'Punkt ${_selectedPointIndex + 1} z ${_points.length}: ${point.note.isNotEmpty ? point.note : "Odcinek"}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _selectedPointIndex < _points.length - 1
                  ? () => setState(() => _selectedPointIndex++)
                  : null,
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add_circle, color: AppColors.goldAccent, size: 18),
              label: const Text('Wstaw po tym', style: TextStyle(color: AppColors.goldAccent, fontSize: 12)),
              onPressed: () => _addPointAfter(_selectedPointIndex),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.crimsonAlert, size: 20),
              tooltip: 'Usuń ten punkt',
              onPressed: () => _removePoint(_selectedPointIndex),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 2. Karta wskaźnika nachylenia
        if (_selectedPointIndex > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getGradientBadgeColor(gradient).withAlpha(40),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _getGradientBadgeColor(gradient).withAlpha(120)),
            ),
            child: Row(
              children: [
                Icon(
                  gradient > 2.0 ? Icons.trending_up : (gradient < -2.0 ? Icons.trending_down : Icons.trending_flat),
                  color: _getGradientBadgeColor(gradient),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Średnie nachylenie odcinka: ${gradient.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _getGradientBadgeColor(gradient),
                      ),
                    ),
                    Text(
                      'Różnica wysokości: ${altDelta >= 0 ? "+" : ""}${altDelta.round()} m na dystansie ${distDelta.toStringAsFixed(1)} km',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // 3. Suwaki Dystansu i Wysokości
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kilometraż: ${point.distanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  Slider(
                    value: point.distanceKm.clamp(0.0, 260.0),
                    min: 0.0,
                    max: 260.0,
                    divisions: 260,
                    activeColor: AppColors.accentBlue,
                    onChanged: (val) {
                      _updateActivePoint(point.copyWith(distanceKm: double.parse(val.toStringAsFixed(1))));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wysokość n.p.m.: ${point.elevationMeters.round()} m',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  Slider(
                    value: point.elevationMeters.clamp(0.0, 2800.0),
                    min: 0.0,
                    max: 2800.0,
                    divisions: 280,
                    activeColor: AppColors.goldAccent,
                    onChanged: (val) {
                      _updateActivePoint(point.copyWith(elevationMeters: val.roundToDouble()));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 4. Pole notatki / nazwy punktu
        TextFormField(
          initialValue: point.note,
          decoration: const InputDecoration(
            labelText: 'Nazwa / Etykieta Punktu (np. Szczyt, Bruk, Serpentyny)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (val) => _updateActivePoint(point.copyWith(note: val)),
        ),

        const SizedBox(height: 16),

        // 5. Wybór Nawierzchni (SegmentSurfaceType)
        const Text('Rodzaj Nawierzchni:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSurfaceChip(point, SegmentSurfaceType.smoothAsphalt, 'Asfalt Gładki', Icons.directions_bike),
            _buildSurfaceChip(point, SegmentSurfaceType.roughAsphalt, 'Asfalt Szorstki', Icons.terrain),
            _buildSurfaceChip(point, SegmentSurfaceType.cobblestonesSector1, 'Bruk 1★', Icons.grid_view),
            _buildSurfaceChip(point, SegmentSurfaceType.cobblestonesSector2, 'Bruk 2★', Icons.grid_view),
            _buildSurfaceChip(point, SegmentSurfaceType.cobblestonesSector3, 'Bruk 3★', Icons.grid_view),
            _buildSurfaceChip(point, SegmentSurfaceType.cobblestonesSector4, 'Bruk 4★', Icons.grid_view),
            _buildSurfaceChip(point, SegmentSurfaceType.cobblestonesSector5, 'Bruk 5★ (Piekło)', Icons.grid_view),
            _buildSurfaceChip(point, SegmentSurfaceType.gravelStrade, 'Szuter Toskański (Strade)', Icons.grain),
          ],
        ),

        const SizedBox(height: 16),

        // 6. Wybór Klasyfikacji / Premii (SegmentClassification)
        const Text('Premia Górska lub Sprinterska:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildClassificationChip(point, SegmentClassification.none, 'Brak'),
            _buildClassificationChip(point, SegmentClassification.intermediateSprint, 'Lotna Premia (Sprint)', color: AppColors.statusSuccess),
            _buildClassificationChip(point, SegmentClassification.cat4, 'KOM 4. Kat', color: Colors.blue),
            _buildClassificationChip(point, SegmentClassification.cat3, 'KOM 3. Kat', color: Colors.amber),
            _buildClassificationChip(point, SegmentClassification.cat2, 'KOM 2. Kat', color: Colors.orange),
            _buildClassificationChip(point, SegmentClassification.cat1, 'KOM 1. Kat', color: AppColors.crimsonAlert),
            _buildClassificationChip(point, SegmentClassification.horsCategorie, 'KOM Hors Catégorie (HC)', color: Colors.purple),
            _buildClassificationChip(point, SegmentClassification.finishLine, 'Linia Mety', color: Colors.white),
          ],
        ),

        const SizedBox(height: 16),

        // 7. Trudność techniczna zakrętów
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trudność techniczna zakrętów: ${point.technicalDifficulty.round()}/100',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Slider(
                    value: point.technicalDifficulty,
                    min: 1.0,
                    max: 100.0,
                    divisions: 100,
                    onChanged: (val) => _updateActivePoint(point.copyWith(technicalDifficulty: val)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSurfaceChip(
    StageEditorPoint point,
    SegmentSurfaceType type,
    String label,
    IconData icon,
  ) {
    final isSelected = point.surfaceType == type;
    return ChoiceChip(
      avatar: Icon(icon, size: 14, color: isSelected ? Colors.black : AppColors.textSecondary),
      label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : AppColors.textPrimary)),
      selected: isSelected,
      selectedColor: AppColors.goldAccent,
      backgroundColor: AppColors.surfaceLight,
      onSelected: (val) {
        if (val) _updateActivePoint(point.copyWith(surfaceType: type));
      },
    );
  }

  Widget _buildClassificationChip(
    StageEditorPoint point,
    SegmentClassification classification,
    String label, {
    Color? color,
  }) {
    final isSelected = point.classification == classification;
    final chipColor = color ?? AppColors.goldAccent;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : AppColors.textPrimary)),
      selected: isSelected,
      selectedColor: chipColor,
      backgroundColor: AppColors.surfaceLight,
      onSelected: (val) {
        if (val) _updateActivePoint(point.copyWith(classification: classification));
      },
    );
  }

  Color _getGradientBadgeColor(double gradient) {
    if (gradient > 12.0) return Colors.purple;
    if (gradient > 8.0) return AppColors.crimsonAlert;
    if (gradient > 5.0) return Colors.orange;
    if (gradient > 2.0) return Colors.amber;
    if (gradient < -2.0) return AppColors.accentBlue;
    return AppColors.statusSuccess;
  }

  // ===========================================================================
  // ZAKŁADKA 1: TABELA WSZYSTKICH PUNKTÓW
  // ===========================================================================

  Widget _buildPointsListView() {
    return ListView.separated(
      itemCount: _points.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
      itemBuilder: (ctx, idx) {
        final pt = _points[idx];
        final isSelected = idx == _selectedPointIndex;

        return Material(
          color: Colors.transparent,
          child: ListTile(
            selected: isSelected,
            selectedTileColor: AppColors.surfaceLight,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: isSelected ? AppColors.goldAccent : AppColors.cardBorder,
              child: Text(
                '${idx + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : AppColors.textPrimary,
                ),
              ),
            ),
            title: Text(
              pt.note.isNotEmpty ? pt.note : 'Punkt trasy #${idx + 1}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            subtitle: Text(
              '${pt.distanceKm.toStringAsFixed(1)} km  •  ${pt.elevationMeters.round()} m n.p.m.  •  ${pt.surfaceType.name}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pt.classification != SegmentClassification.none)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withAlpha(50),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      pt.classification.name.toUpperCase(),
                      style: const TextStyle(fontSize: 10, color: AppColors.goldAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: AppColors.crimsonAlert),
                  onPressed: () => _removePoint(idx),
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _selectedPointIndex = idx;
                _activeTab = 0;
              });
            },
          ),
        );
      },
    );
  }

  // ===========================================================================
  // ZAKŁADKA 2: PARAMETRY WYŚCIGU I WARUNKI POGODOWE
  // ===========================================================================

  Widget _buildRaceSettingsView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Nazwa wyścigu
        TextFormField(
          controller: _raceNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nazwa Wyścigu (np. Klasyk Dolnośląski)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        // Nazwa etapu
        TextFormField(
          controller: _stageNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nazwa Etapu (np. Etap 1: Ślężański Szlem)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        // Kategoria UCI i Typ profilu
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<RaceCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Kategoria UCI', border: OutlineInputBorder()),
                items: RaceCategory.values.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c.name.toUpperCase(), style: const TextStyle(fontSize: 12)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<StageType>(
                initialValue: _selectedStageType,
                decoration: const InputDecoration(labelText: 'Profil Etapu', border: OutlineInputBorder()),
                items: StageType.values.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(fontSize: 12)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedStageType = val);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Data w kalendarzu i Pula nagród
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _startMonth,
                decoration: const InputDecoration(labelText: 'Miesiąc', border: OutlineInputBorder()),
                items: List.generate(12, (i) => i + 1).map((m) {
                  return DropdownMenuItem(value: m, child: Text(_getMonthName(m), style: const TextStyle(fontSize: 12)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _startMonth = val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _startDay,
                decoration: const InputDecoration(labelText: 'Dzień', border: OutlineInputBorder()),
                items: List.generate(31, (i) => i + 1).map((d) {
                  return DropdownMenuItem(value: d, child: Text('$d', style: const TextStyle(fontSize: 12)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _startDay = val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _prizePoolCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Pula Nagród (€)', border: OutlineInputBorder()),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Warunki pogodowe bazowe
        const Text('Warunki Atmosferyczne w Dolinie:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<WeatherCondition>(
                initialValue: _baseWeather,
                decoration: const InputDecoration(labelText: 'Pogoda Bazowa', border: OutlineInputBorder()),
                items: WeatherCondition.values.map((w) {
                  return DropdownMenuItem(value: w, child: Text(w.name, style: const TextStyle(fontSize: 12)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _baseWeather = val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Temp. bazowa: ${_baseTemperatureCelsius.toStringAsFixed(1)}°C', style: const TextStyle(fontSize: 12)),
                  Slider(
                    value: _baseTemperatureCelsius,
                    min: 5.0,
                    max: 38.0,
                    divisions: 33,
                    onChanged: (val) => setState(() => _baseTemperatureCelsius = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
