// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, IconData, Icons;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

/// Kategorie modeli 3D w grze Pro Peloton Manager.
enum GlbAssetCategory {
  /// Ramy rowerowe i komponenty szosowe/czasowe.
  bike(
    label: 'Rowery i Ramy',
    icon: Icons.pedal_bike_rounded,
    folderPath: 'assets/3d/bikes',
  ),

  /// Kolarze, kaski, okulary i elementy wyposażenia.
  cyclist(
    label: 'Kolarze i Ekwipunek',
    icon: Icons.person_rounded,
    folderPath: 'assets/3d/cyclists',
  ),

  /// W pełni okinematyzowani kolarze z animacjami kości i szkieletu.
  rider(
    label: 'Animowani Kolarze',
    icon: Icons.directions_bike_rounded,
    folderPath: 'assets/3d/riders',
  ),

  /// Elementy otoczenia trasy: drzewa, skały, szczyty, budynki, kibice.
  environment(
    label: 'Otoczenie i Krajobraz',
    icon: Icons.landscape_rounded,
    folderPath: 'assets/3d/environment',
  ),

  /// Bramy finiszowe, górske KOM, lotne premie, Flamme Rouge, barierki.
  furniture(
    label: 'Infrastruktura i Bramy',
    icon: Icons.flag_rounded,
    folderPath: 'assets/3d/furniture',
  ),

  /// Wycinki nawierzchni szosy (asfalt, bruk, serpentyny).
  road(
    label: 'Nawierzchnie Szosy',
    icon: Icons.route_rounded,
    folderPath: 'assets/3d/roads',
  ),

  /// Pojazdy towarzyszące peletonowi: samochody techniczne, motocykle TV i sędziowskie.
  vehicle(
    label: 'Pojazdy Wyścigu',
    icon: Icons.directions_car_rounded,
    folderPath: 'assets/3d/vehicles',
  ),

  /// Modele niestandardowe lub niezidentyfikowane.
  unknown(
    label: 'Inne Obiekty 3D',
    icon: Icons.category_rounded,
    folderPath: 'assets/3d',
  );

  final String label;
  final IconData icon;
  final String folderPath;

  const GlbAssetCategory({
    required this.label,
    required this.icon,
    required this.folderPath,
  });
}

/// Metadane pojedynczego zasobu 3D w katalogu projektu.
class GlbAssetDefinition {
  /// Unikalny identyfikator zasobu (np. 'frame_aero', 'tree_pine').
  final String id;

  /// Kategoria zasobu 3D.
  final GlbAssetCategory category;

  /// Nazwa pliku z rozszerzeniem (np. 'frame_aero.glb').
  final String fileName;

  /// Względna ścieżka do pliku w projekcie Flutter (np. 'assets/3d/bikes/frame_aero.glb').
  final String relativePath;

  /// Czytelna polska nazwa modelu.
  final String displayName;

  /// Tagi ułatwiające wyszukiwanie i dopasowanie fallbacku.
  final List<String> tags;

  const GlbAssetDefinition({
    required this.id,
    required this.category,
    required this.fileName,
    required this.relativePath,
    required this.displayName,
    this.tags = const [],
  });
}

/// Statyczny katalog wszystkich 34 modeli .glb wygenerowanych w Blenderze.
class GlbAssetCatalog {
  static const List<GlbAssetDefinition> allAssets = [
    // --- ROWERY I KOMPONENTY (8 modeli) ---
    GlbAssetDefinition(
      id: 'frame_aero',
      category: GlbAssetCategory.bike,
      fileName: 'frame_aero.glb',
      relativePath: 'assets/3d/bikes/frame_aero.glb',
      displayName: 'Rama Aerodynamiczna Szosowa',
      tags: ['frame', 'aero', 'bike', 'carbon'],
    ),
    GlbAssetDefinition(
      id: 'frame_climbing',
      category: GlbAssetCategory.bike,
      fileName: 'frame_climbing.glb',
      relativePath: 'assets/3d/bikes/frame_climbing.glb',
      displayName: 'Lekka Rama Górka (Climbing)',
      tags: ['frame', 'climbing', 'mountain', 'lightweight'],
    ),
    GlbAssetDefinition(
      id: 'frame_tt',
      category: GlbAssetCategory.bike,
      fileName: 'frame_tt.glb',
      relativePath: 'assets/3d/bikes/frame_tt.glb',
      displayName: 'Rama Czasowa (Time Trial / TT)',
      tags: ['frame', 'tt', 'timetrial', 'chrono'],
    ),
    GlbAssetDefinition(
      id: 'wheel_35mm',
      category: GlbAssetCategory.bike,
      fileName: 'wheel_35mm.glb',
      relativePath: 'assets/3d/bikes/wheel_35mm.glb',
      displayName: 'Koło Karbonowe Niskoprofilowe 35mm',
      tags: ['wheel', '35mm', 'climbing'],
    ),
    GlbAssetDefinition(
      id: 'wheel_50mm',
      category: GlbAssetCategory.bike,
      fileName: 'wheel_50mm.glb',
      relativePath: 'assets/3d/bikes/wheel_50mm.glb',
      displayName: 'Koło Karbonowe Wszechstronne 50mm',
      tags: ['wheel', '50mm', 'allround'],
    ),
    GlbAssetDefinition(
      id: 'wheel_65mm',
      category: GlbAssetCategory.bike,
      fileName: 'wheel_65mm.glb',
      relativePath: 'assets/3d/bikes/wheel_65mm.glb',
      displayName: 'Koło Karbonowe Aero 65mm',
      tags: ['wheel', '65mm', 'aero', 'sprint'],
    ),
    GlbAssetDefinition(
      id: 'wheel_disc',
      category: GlbAssetCategory.bike,
      fileName: 'wheel_disc.glb',
      relativePath: 'assets/3d/bikes/wheel_disc.glb',
      displayName: 'Pełne Koło Dyskowe TT (Disc Wheel)',
      tags: ['wheel', 'disc', 'tt', 'chrono'],
    ),
    GlbAssetDefinition(
      id: 'components_pack',
      category: GlbAssetCategory.bike,
      fileName: 'components_pack.glb',
      relativePath: 'assets/3d/bikes/components_pack.glb',
      displayName: 'Zestaw Komponentów (Kierownica, Siodło, Korba)',
      tags: ['components', 'handlebar', 'saddle', 'crankset'],
    ),

    // --- KOLARZE I EKWIPUNEK (5 modeli) ---
    GlbAssetDefinition(
      id: 'cyclist_road',
      category: GlbAssetCategory.cyclist,
      fileName: 'cyclist_road.glb',
      relativePath: 'assets/3d/cyclists/cyclist_road.glb',
      displayName: 'Model Kolarza Szosowego',
      tags: ['cyclist', 'rider', 'mannequin'],
    ),
    GlbAssetDefinition(
      id: 'helmet_aero',
      category: GlbAssetCategory.cyclist,
      fileName: 'helmet_aero.glb',
      relativePath: 'assets/3d/cyclists/helmet_aero.glb',
      displayName: 'Kask Aerodynamiczny Szosowy',
      tags: ['helmet', 'aero'],
    ),
    GlbAssetDefinition(
      id: 'helmet_vented',
      category: GlbAssetCategory.cyclist,
      fileName: 'helmet_vented.glb',
      relativePath: 'assets/3d/cyclists/helmet_vented.glb',
      displayName: 'Kask Wentylowany Górski',
      tags: ['helmet', 'vented', 'climbing'],
    ),
    GlbAssetDefinition(
      id: 'helmet_tt',
      category: GlbAssetCategory.cyclist,
      fileName: 'helmet_tt.glb',
      relativePath: 'assets/3d/cyclists/helmet_tt.glb',
      displayName: 'Kask Czasowy z Długim Ogonem (TT)',
      tags: ['helmet', 'tt', 'visor'],
    ),
    GlbAssetDefinition(
      id: 'glasses_pro',
      category: GlbAssetCategory.cyclist,
      fileName: 'glasses_pro.glb',
      relativePath: 'assets/3d/cyclists/glasses_pro.glb',
      displayName: 'Okulary Kolarskie Pro Shield',
      tags: ['glasses', 'visor', 'shield'],
    ),

    // --- ANIMOWANI KOLARZE (1 model) ---
    GlbAssetDefinition(
      id: 'cyclist_animated',
      category: GlbAssetCategory.rider,
      fileName: 'cyclist_animated.glb',
      relativePath: 'assets/3d/riders/cyclist_animated.glb',
      displayName: 'Kolarz z Kośćmi i Pełnym Szkieletem Animacji',
      tags: ['rider', 'cyclist', 'rig', 'bones', 'animation'],
    ),

    // --- OTOCZENIE I KRAJOBRAZ (8 modeli) ---
    GlbAssetDefinition(
      id: 'tree_pine',
      category: GlbAssetCategory.environment,
      fileName: 'tree_pine.glb',
      relativePath: 'assets/3d/environment/tree_pine.glb',
      displayName: 'Sosna Alpejska',
      tags: ['tree', 'pine', 'alpine', 'nature'],
    ),
    GlbAssetDefinition(
      id: 'tree_cypress',
      category: GlbAssetCategory.environment,
      fileName: 'tree_cypress.glb',
      relativePath: 'assets/3d/environment/tree_cypress.glb',
      displayName: 'Cyprys Włoski (Toskania)',
      tags: ['tree', 'cypress', 'mediterranean'],
    ),
    GlbAssetDefinition(
      id: 'tree_deciduous',
      category: GlbAssetCategory.environment,
      fileName: 'tree_deciduous.glb',
      relativePath: 'assets/3d/environment/tree_deciduous.glb',
      displayName: 'Drzewo Liściaste (Dąb / Klon)',
      tags: ['tree', 'deciduous', 'leafy'],
    ),
    GlbAssetDefinition(
      id: 'rock_boulder',
      category: GlbAssetCategory.environment,
      fileName: 'rock_boulder.glb',
      relativePath: 'assets/3d/environment/rock_boulder.glb',
      displayName: 'Głaz Górski Granitowy',
      tags: ['rock', 'stone', 'boulder', 'mountain'],
    ),
    GlbAssetDefinition(
      id: 'mountain_peak',
      category: GlbAssetCategory.environment,
      fileName: 'mountain_peak.glb',
      relativePath: 'assets/3d/environment/mountain_peak.glb',
      displayName: 'Szczyt Alpejski z Pokrywą Śnieżną',
      tags: ['mountain', 'peak', 'snow', 'paralax'],
    ),
    GlbAssetDefinition(
      id: 'building_townhouse',
      category: GlbAssetCategory.environment,
      fileName: 'building_townhouse.glb',
      relativePath: 'assets/3d/environment/building_townhouse.glb',
      displayName: 'Miasteczko Europejskie (Kamienica)',
      tags: ['building', 'house', 'town', 'village'],
    ),
    GlbAssetDefinition(
      id: 'spectators_cheering',
      category: GlbAssetCategory.environment,
      fileName: 'spectators_cheering.glb',
      relativePath: 'assets/3d/environment/spectators_cheering.glb',
      displayName: 'Kibice Przy Barierkach Machający Flagami',
      tags: ['spectators', 'fans', 'crowd', 'flags'],
    ),
    GlbAssetDefinition(
      id: 'env_pack',
      category: GlbAssetCategory.environment,
      fileName: 'env_pack.glb',
      relativePath: 'assets/3d/environment/env_pack.glb',
      displayName: 'Zestaw Środowiskowy (Environment Master Pack)',
      tags: ['environment', 'pack', 'master'],
    ),

    // --- INFRASTRUKTURA I BRAMY (6 modeli) ---
    GlbAssetDefinition(
      id: 'arch_finish',
      category: GlbAssetCategory.furniture,
      fileName: 'arch_finish.glb',
      relativePath: 'assets/3d/furniture/arch_finish.glb',
      displayName: 'Brama Mety z Tablicą Pomiaru Czasu',
      tags: ['arch', 'finish', 'gantry'],
    ),
    GlbAssetDefinition(
      id: 'arch_flamme_rouge',
      category: GlbAssetCategory.furniture,
      fileName: 'arch_flamme_rouge.glb',
      relativePath: 'assets/3d/furniture/arch_flamme_rouge.glb',
      displayName: 'Brama Czerwonego Trójkąta (Flamme Rouge 1KM)',
      tags: ['arch', 'flamme_rouge', '1km'],
    ),
    GlbAssetDefinition(
      id: 'arch_kom',
      category: GlbAssetCategory.furniture,
      fileName: 'arch_kom.glb',
      relativePath: 'assets/3d/furniture/arch_kom.glb',
      displayName: 'Brama Górskiej Premii (KOM Polka Dot)',
      tags: ['arch', 'kom', 'climber'],
    ),
    GlbAssetDefinition(
      id: 'arch_sprint',
      category: GlbAssetCategory.furniture,
      fileName: 'arch_sprint.glb',
      relativePath: 'assets/3d/furniture/arch_sprint.glb',
      displayName: 'Brama Lotnej Premii Sprinterskiej',
      tags: ['arch', 'sprint', 'points'],
    ),
    GlbAssetDefinition(
      id: 'arch_kom_sprint',
      category: GlbAssetCategory.furniture,
      fileName: 'arch_kom_sprint.glb',
      relativePath: 'assets/3d/furniture/arch_kom_sprint.glb',
      displayName: 'Podwójna Brama Premii Górskiej i Lotnej',
      tags: ['arch', 'combo', 'kom', 'sprint'],
    ),
    GlbAssetDefinition(
      id: 'barrier_finish',
      category: GlbAssetCategory.furniture,
      fileName: 'barrier_finish.glb',
      relativePath: 'assets/3d/furniture/barrier_finish.glb',
      displayName: 'Bariera Bezpieczeństwa Finiszowa ze Sponsorami',
      tags: ['barrier', 'finish', 'sponsor'],
    ),

    // --- NAWIERZCHNIE SZOSY (3 modele) ---
    GlbAssetDefinition(
      id: 'road_asphalt',
      category: GlbAssetCategory.road,
      fileName: 'road_asphalt.glb',
      relativePath: 'assets/3d/roads/road_asphalt.glb',
      displayName: 'Szosa Asfaltowa z Oznakowaniem Poziomym',
      tags: ['road', 'asphalt', 'tarmac'],
    ),
    GlbAssetDefinition(
      id: 'road_cobbles',
      category: GlbAssetCategory.road,
      fileName: 'road_cobbles.glb',
      relativePath: 'assets/3d/roads/road_cobbles.glb',
      displayName: 'Sektor Bruku (Paris-Roubaix Pavé)',
      tags: ['road', 'cobbles', 'pave', 'roubaix'],
    ),
    GlbAssetDefinition(
      id: 'road_mountain_hairpin',
      category: GlbAssetCategory.road,
      fileName: 'road_mountain_hairpin.glb',
      relativePath: 'assets/3d/roads/road_mountain_hairpin.glb',
      displayName: 'Alpejska Serpentyna z Wyprofilowanym Łukiem',
      tags: ['road', 'hairpin', 'serpentine', 'switchback'],
    ),

    // --- POJAZDY WYŚCIGU (3 modele) ---
    GlbAssetDefinition(
      id: 'vehicle_team_car',
      category: GlbAssetCategory.vehicle,
      fileName: 'vehicle_team_car.glb',
      relativePath: 'assets/3d/vehicles/vehicle_team_car.glb',
      displayName: 'Samochód Dyrektora Sportowego z Rowerami na Dachu',
      tags: ['vehicle', 'car', 'team_car', 'director'],
    ),
    GlbAssetDefinition(
      id: 'vehicle_moto_tv',
      category: GlbAssetCategory.vehicle,
      fileName: 'vehicle_moto_tv.glb',
      relativePath: 'assets/3d/vehicles/vehicle_moto_tv.glb',
      displayName: 'Motocykl z Operatorem Kamery TV',
      tags: ['vehicle', 'moto', 'tv', 'broadcast'],
    ),
    GlbAssetDefinition(
      id: 'vehicle_moto_commissaire',
      category: GlbAssetCategory.vehicle,
      fileName: 'vehicle_moto_commissaire.glb',
      relativePath: 'assets/3d/vehicles/vehicle_moto_commissaire.glb',
      displayName: 'Motocykl Sędziowski UCI z Czerwoną Flagą',
      tags: ['vehicle', 'moto', 'commissaire', 'uci', 'marshal'],
    ),
  ];

  static final Map<String, GlbAssetDefinition> _byId = {
    for (final def in allAssets) def.id: def,
  };

  static final Map<String, GlbAssetDefinition> _byFileName = {
    for (final def in allAssets) def.fileName: def,
  };

  static final Map<String, GlbAssetDefinition> _byPath = {
    for (final def in allAssets) def.relativePath.replaceAll('\\', '/'): def,
  };

  /// Wyszukuje definicję zasobu na podstawie klucza, nazwy pliku lub pełnej ścieżki.
  static GlbAssetDefinition? find(String keyOrPath) {
    final normalized = keyOrPath.replaceAll('\\', '/').trim();
    if (_byId.containsKey(normalized)) return _byId[normalized];
    if (_byPath.containsKey(normalized)) return _byPath[normalized];

    // Sprawdzenie samej nazwy pliku
    final fileName = normalized.split('/').last;
    if (_byFileName.containsKey(fileName)) return _byFileName[fileName];

    final idWithoutExtension = fileName.endsWith('.glb')
        ? fileName.substring(0, fileName.length - 4)
        : fileName;
    if (_byId.containsKey(idWithoutExtension)) return _byId[idWithoutExtension];

    return null;
  }

  /// Zwraca listę zasobów należących do zadanej kategorii.
  static List<GlbAssetDefinition> getByCategory(GlbAssetCategory category) {
    return allAssets.where((a) => a.category == category).toList();
  }
}

/// Właściwości materiału PBR (Physically Based Rendering) wyodrębnione z modelu GLB.
class GlbMaterialData {
  final String name;
  final Color baseColor;
  final double roughness;
  final double metallic;
  final bool isTransparent;
  final double opacity;
  final bool doubleSided;

  const GlbMaterialData({
    this.name = 'Default_Material',
    this.baseColor = const Color(0xFFFFFFFF),
    this.roughness = 0.5,
    this.metallic = 0.0,
    this.isTransparent = false,
    this.opacity = 1.0,
    this.doubleSided = false,
  });

  factory GlbMaterialData.fallback({
    String name = 'Fallback_Material',
    Color color = const Color(0xFF9E9E9E),
    double roughness = 0.5,
    double metallic = 0.1,
  }) {
    return GlbMaterialData(
      name: name,
      baseColor: color,
      roughness: roughness,
      metallic: metallic,
    );
  }
}

/// Pojedynczy prymityw geometryczny siatki 3D (Submesh) w modelu GLB.
class GlbMeshPrimitive {
  final String name;
  final List<Vector3> vertices;
  final List<Vector3> normals;
  final List<Vector2> uvs;
  final List<int> indices;
  final GlbMaterialData material;
  final Aabb3 boundingBox;

  GlbMeshPrimitive({
    required this.name,
    required this.vertices,
    required this.normals,
    required this.uvs,
    required this.indices,
    required this.material,
    required this.boundingBox,
  });

  /// Liczba trójkątów tworzących prymityw.
  int get triangleCount => indices.length ~/ 3;

  /// Liczba wierzchołków.
  int get vertexCount => vertices.length;
}

/// Kompletna sparsowana geometria modelu 3D gotowa do renderowania i buforowania.
class GlbModelGeometry {
  /// Unikalny klucz identyfikujący model w buforze pamięci podręcznej.
  final String assetKey;

  /// Nazwa modelu 3D.
  final String name;

  /// Kategoria zasobu.
  final GlbAssetCategory category;

  /// Lista składowych siatek trójkątów (primitives/submeshes).
  final List<GlbMeshPrimitive> primitives;

  /// Prostopadłościan otaczający całą geometrię modelu (AABB).
  final Aabb3 boundingBox;

  /// Środek geometryczny modelu.
  final Vector3 boundingCenter;

  /// Promień kuli otaczającej model (Bounding Sphere).
  final double boundingRadius;

  /// Łączna liczba wierzchołków we wszystkich prymitywach.
  final int totalVertices;

  /// Łączna liczba trójkątów we wszystkich prymitywach.
  final int totalTriangles;

  /// Czy model powstał w wyniku natychmiastowego fallbacku proceduralnego (brak pliku lub błąd).
  final bool isProceduralFallback;

  /// Opcjonalny opis przyczyny użycia fallbacku (np. brak pliku .glb na dysku).
  final String? fallbackReason;

  GlbModelGeometry({
    required this.assetKey,
    required this.name,
    required this.category,
    required this.primitives,
    required this.boundingBox,
    required this.boundingCenter,
    required this.boundingRadius,
    required this.totalVertices,
    required this.totalTriangles,
    this.isProceduralFallback = false,
    this.fallbackReason,
  });

  /// Wymiary prostopadłościanu otaczającego model (długość, wysokość, szerokość) [m].
  Vector3 get size {
    return boundingBox.max - boundingBox.min;
  }
}

/// Serwis zarządzający ładowaniem, buforowaniem i fallbackami proceduralnymi modeli 3D (.glb).
class GlbAssetLoaderService {
  static GlbAssetLoaderService? _singleton;

  /// Globalna instancja singletonu serwisu.
  static GlbAssetLoaderService get instance => _singleton ??= GlbAssetLoaderService();

  /// Pamięć podręczna sparsowanych geometrii modeli w RAM.
  final Map<String, GlbModelGeometry> _cache = {};

  /// Zbiór kluczy w trakcie asynchronicznego ładowania (ochrona przed wyścigiem).
  final Map<String, Future<GlbModelGeometry>> _inFlightLoads = {};

  /// Generator siatek proceduralnych dla fallbacku zerokraszowego.
  late final GlbProceduralFallbackBuilder _fallbackBuilder;

  GlbAssetLoaderService() {
    _fallbackBuilder = GlbProceduralFallbackBuilder();
  }

  // ===========================================================================
  // ZARZĄDZANIE PAMIĘCIĄ PODRĘCZNĄ (CACHE METRICS & CLEAR)
  // ===========================================================================

  /// Liczba modeli aktualnie zbuforowanych w pamięci RAM.
  int get cachedModelCount => _cache.length;

  /// Wszystkie unikalne klucze modeli znajdujące się w buforze.
  List<String> get cachedAssetKeys => _cache.keys.toList();

  /// Łączna liczba wierzchołków zbuforowanych modeli 3D.
  int get totalCachedVertexCount {
    return _cache.values.fold(0, (acc, model) => acc + model.totalVertices);
  }

  /// Łączna liczba trójkątów zbuforowanych modeli 3D.
  int get totalCachedTriangleCount {
    return _cache.values.fold(0, (acc, model) => acc + model.totalTriangles);
  }

  /// Sprawdza, czy model o zadanym kluczu lub ścieżce jest już zbuforowany w pamięci.
  bool isModelCached(String assetKeyOrPath) {
    final normalized = normalizeAssetKey(assetKeyOrPath);
    return _cache.containsKey(normalized);
  }

  /// Czyści pamięć podręczną wszystkich załadowanych modeli 3D.
  void clearCache() {
    _cache.clear();
    _inFlightLoads.clear();
  }

  // ===========================================================================
  // SYNCHRONICZNY DOSTĘP (ZERO-WAIT NON-BLOCKING DLA PĘTLI TICKERA 60/120 FPS)
  // ===========================================================================

  /// Zwraca model natychmiastowo i synchronicznie:
  /// - Jeśli model znajduje się w buforze, zwraca go bez żadnego opóźnienia.
  /// - Jeśli modelu nie ma jeszcze w buforze, NATYCHMIAST syntetyzuje fallback proceduralny
  ///   w pamięci RAM i uruchamia w tle ładowanie docelowego pliku .glb.
  ///
  /// GWARANCJA: Metoda NIGDY nie rzuca wyjątku i NIGDY nie zwraca null!
  GlbModelGeometry getModel(String assetKeyOrPath) {
    final normalized = normalizeAssetKey(assetKeyOrPath);

    // 1. Hit w pamięci podręcznej
    final cached = _cache[normalized];
    if (cached != null) {
      return cached;
    }

    // 2. Jeśli nie ma w cache, natychmiast generujemy fallback proceduralny,
    // aby pętla renderowania klatki nie uległa opóźnieniu ani crashowi.
    final fallback = _fallbackBuilder.buildFallback(normalized, reason: 'Cache-miss fallback');
    _cache[normalized] = fallback;

    // 3. W tle próbujemy załadować właściwy plik .glb i podmienić bufor
    loadModel(normalized).catchError((_) => fallback);

    return fallback;
  }

  // ===========================================================================
  // ASYNCHRONICZNE ŁADOWANIE MODELI Z DYSKU LUB ASSETÓW FLUTTERA
  // ===========================================================================

  /// Asynchronicznie ładuje model .glb i umieszcza go w pamięci podręcznej.
  ///
  /// W przypadku braku pliku, uszkodzenia pliku lub błędu parsowania,
  /// metoda zwraca perfekcyjnie dopasowany zamiennik proceduralny
  /// z flagą [GlbModelGeometry.isProceduralFallback] = true.
  Future<GlbModelGeometry> loadModel(
    String assetKeyOrPath, {
    bool forceReload = false,
  }) async {
    final normalized = normalizeAssetKey(assetKeyOrPath);

    // Cache hit
    if (!forceReload && _cache.containsKey(normalized)) {
      final existing = _cache[normalized]!;
      if (!existing.isProceduralFallback) {
        return existing;
      }
    }

    // Ochrona przed zduplikowanym równoczesnym ładowaniem tego samego zasobu
    if (_inFlightLoads.containsKey(normalized)) {
      return _inFlightLoads[normalized]!;
    }

    final loadFuture = _loadInternal(normalized);
    _inFlightLoads[normalized] = loadFuture;

    try {
      final loadedGeometry = await loadFuture;
      _cache[normalized] = loadedGeometry;
      return loadedGeometry;
    } finally {
      _inFlightLoads.remove(normalized);
    }
  }

  Future<GlbModelGeometry> _loadInternal(String normalizedKey) async {
    final def = GlbAssetCatalog.find(normalizedKey);
    final relativePath = def?.relativePath ?? normalizedKey;

    Uint8List? fileBytes;
    String? loadError;

    // Krok 1: Próba załadowania przez Flutter rootBundle
    try {
      final byteData = await rootBundle.load(relativePath);
      fileBytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    } catch (e) {
      loadError = 'rootBundle load error: $e';
    }

    // Krok 2: Próba bezpośredniego odczytu z systemu plików (dla testów i środowiska lokalnego)
    if (fileBytes == null) {
      try {
        final directFile = File(relativePath);
        if (await directFile.exists()) {
          fileBytes = await directFile.readAsBytes();
        } else {
          // Sprawdzenie alternatywnych ścieżek roboczych
          final altPath1 = 'assets/3d/${relativePath.split('3d/').last}';
          final altFile1 = File(altPath1);
          if (await altFile1.exists()) {
            fileBytes = await altFile1.readAsBytes();
          }
        }
      } catch (e) {
        loadError = (loadError != null) ? '$loadError; File IO error: $e' : 'File IO error: $e';
      }
    }

    // Krok 3: Jeśli plik istnieje i ma bajty, parsujemy format binarny glTF 2.0 (GLB)
    if (fileBytes != null && fileBytes.length >= 12) {
      try {
        final parsed = parseGlbBinary(
          fileBytes,
          assetKey: normalizedKey,
          category: def?.category ?? _deduceCategory(normalizedKey),
          displayName: def?.displayName ?? normalizedKey,
        );
        return parsed;
      } catch (parseEx) {
        if (kDebugMode) {
          debugPrint('Błąd parsowania GLB dla $normalizedKey: $parseEx');
        }
        return _fallbackBuilder.buildFallback(
          normalizedKey,
          reason: 'Błąd parsowania GLB: $parseEx',
        );
      }
    }

    // Krok 4: Brak pliku na dysku -> Bezpieczny proceduralny fallback w pamięci RAM
    return _fallbackBuilder.buildFallback(
      normalizedKey,
      reason: loadError ?? 'Brak pliku .glb pod ścieżką $relativePath',
    );
  }

  // ===========================================================================
  // PRELOADING (WSTĘPNE ŁADOWANIE KLUCZOWYCH ZASOBÓW WYŚCIGU)
  // ===========================================================================

  /// Wstępnie ładuje kluczowe modele niezbędne do rozpoczęcia symulacji wyścigu kolarskiego.
  Future<void> preloadEssentialAssets() async {
    final essentialKeys = [
      'frame_aero',
      'frame_climbing',
      'wheel_50mm',
      'cyclist_road',
      'helmet_aero',
      'tree_pine',
      'tree_deciduous',
      'arch_finish',
      'barrier_finish',
      'road_asphalt',
      'vehicle_team_car',
      'vehicle_moto_tv',
    ];

    await Future.wait(essentialKeys.map((key) => loadModel(key)));
  }

  /// Wstępnie ładuje wszystkie 34 modele wygenerowane w Blenderze.
  Future<void> preloadAllAssets() async {
    final allKeys = GlbAssetCatalog.allAssets.map((a) => a.id).toList();
    await Future.wait(allKeys.map((key) => loadModel(key)));
  }

  // ===========================================================================
  // NORMALIZACJA ŚCIEŻEK I DETEKCJA KATEGORII
  // ===========================================================================

  /// Normalizuje zadany klucz lub ścieżkę do spójnej reprezentacji.
  String normalizeAssetKey(String keyOrPath) {
    String normalized = keyOrPath.replaceAll('\\', '/').trim();
    if (normalized.startsWith('./')) {
      normalized = normalized.substring(2);
    }
    if (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }

    final def = GlbAssetCatalog.find(normalized);
    if (def != null) {
      return def.id;
    }

    if (normalized.endsWith('.glb')) {
      final name = normalized.split('/').last;
      return name.substring(0, name.length - 4);
    }

    return normalized;
  }

  GlbAssetCategory _deduceCategory(String key) {
    final lower = key.toLowerCase();
    if (lower.contains('frame') || lower.contains('wheel') || lower.contains('component')) {
      return GlbAssetCategory.bike;
    }
    if (lower.contains('cyclist') || lower.contains('helmet') || lower.contains('glasses')) {
      return GlbAssetCategory.cyclist;
    }
    if (lower.contains('tree') || lower.contains('mountain') || lower.contains('rock') || lower.contains('building') || lower.contains('spectator')) {
      return GlbAssetCategory.environment;
    }
    if (lower.contains('arch') || lower.contains('barrier')) {
      return GlbAssetCategory.furniture;
    }
    if (lower.contains('road') || lower.contains('cobble') || lower.contains('hairpin')) {
      return GlbAssetCategory.road;
    }
    if (lower.contains('vehicle') || lower.contains('moto') || lower.contains('car')) {
      return GlbAssetCategory.vehicle;
    }
    return GlbAssetCategory.unknown;
  }

  // ===========================================================================
  // GLTF 2.0 BINARY (GLB) PARSER
  // ===========================================================================

  /// Kompletny parser binarnego formatu GLB (glTF 2.0 Binary) zgodny ze specyfikacją Khronos.
  GlbModelGeometry parseGlbBinary(
    Uint8List bytes, {
    required String assetKey,
    required GlbAssetCategory category,
    required String displayName,
  }) {
    if (bytes.length < 12) {
      throw const FormatException('Plik GLB jest zbyt krótki (mniej niż 12 bajtów nagłówka)');
    }

    final bd = ByteData.sublistView(bytes);

    // 1. Nagłówek GLB (12 bajtów)
    final magic = bd.getUint32(0, Endian.little);
    if (magic != 0x46546C67) {
      // 0x46546C67 odpowiada ciągowi 'glTF'
      throw FormatException('Nieprawidłowy magic GLB: 0x${magic.toRadixString(16)} (oczekiwano glTF)');
    }

    final version = bd.getUint32(4, Endian.little);
    if (version != 2) {
      throw FormatException('Nieobsługiwana wersja GLB: $version (wymagana wersja 2.0)');
    }

    // 2. Chunk 0 (JSON Chunk)
    if (bytes.length < 20) {
      throw const FormatException('Plik GLB ucięty przed nagłówkiem pierwszego chunka');
    }
    final chunk0Length = bd.getUint32(12, Endian.little);
    final chunk0Type = bd.getUint32(16, Endian.little);
    if (chunk0Type != 0x4E4F534A) {
      // 0x4E4F534A odpowiada 'JSON'
      throw const FormatException('Oczekiwano chunka JSON na pozycji 12');
    }

    final chunk0End = 20 + chunk0Length;
    if (bytes.length < chunk0End) {
      throw const FormatException('Ucięty chunk JSON w pliku GLB');
    }

    final jsonString = utf8.decode(bytes.sublist(20, chunk0End));
    final Map<String, dynamic> gltf = jsonDecode(jsonString) as Map<String, dynamic>;

    // 3. Chunk 1 (Binary Buffer Chunk)
    Uint8List binBuffer = Uint8List(0);
    final chunk1Offset = chunk0End;
    if (bytes.length >= chunk1Offset + 8) {
      final chunk1Length = bd.getUint32(chunk1Offset, Endian.little);
      final chunk1DataOffset = chunk1Offset + 8;
      if (bytes.length >= chunk1DataOffset + chunk1Length) {
        binBuffer = bytes.sublist(chunk1DataOffset, chunk1DataOffset + chunk1Length);
      }
    }

    final binBd = ByteData.sublistView(binBuffer);

    // Wyciągamy tablice metadanych glTF
    final accessors = (gltf['accessors'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final bufferViews = (gltf['bufferViews'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final materialsJson = (gltf['materials'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final meshesJson = (gltf['meshes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // Parsujemy materiały
    final parsedMaterials = <GlbMaterialData>[];
    for (final mat in materialsJson) {
      final name = mat['name'] as String? ?? 'Material_${parsedMaterials.length}';
      final pbr = mat['pbrMetallicRoughness'] as Map<String, dynamic>?;
      Color baseColor = const Color(0xFFFFFFFF);
      double roughness = 0.5;
      double metallic = 0.0;
      double opacity = 1.0;

      if (pbr != null) {
        final factor = pbr['baseColorFactor'] as List?;
        if (factor != null && factor.length >= 4) {
          final r = ((factor[0] as num).toDouble() * 255.0).clamp(0.0, 255.0).round();
          final g = ((factor[1] as num).toDouble() * 255.0).clamp(0.0, 255.0).round();
          final b = ((factor[2] as num).toDouble() * 255.0).clamp(0.0, 255.0).round();
          final a = ((factor[3] as num).toDouble() * 255.0).clamp(0.0, 255.0).round();
          opacity = (factor[3] as num).toDouble();
          baseColor = Color.fromARGB(a, r, g, b);
        }
        roughness = (pbr['roughnessFactor'] as num?)?.toDouble() ?? 0.5;
        metallic = (pbr['metallicFactor'] as num?)?.toDouble() ?? 0.0;
      }

      parsedMaterials.add(GlbMaterialData(
        name: name,
        baseColor: baseColor,
        roughness: roughness,
        metallic: metallic,
        isTransparent: opacity < 0.99,
        opacity: opacity,
        doubleSided: mat['doubleSided'] as bool? ?? false,
      ));
    }

    final primitives = <GlbMeshPrimitive>[];
    final overallMin = Vector3.all(double.infinity);
    final overallMax = Vector3.all(-double.infinity);

    // Iterujemy po wszystkich meshach i ich prymitywach
    for (int mIdx = 0; mIdx < meshesJson.length; mIdx++) {
      final meshObj = meshesJson[mIdx];
      final meshName = meshObj['name'] as String? ?? 'Mesh_$mIdx';
      final primsJson = (meshObj['primitives'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      for (int pIdx = 0; pIdx < primsJson.length; pIdx++) {
        final primObj = primsJson[pIdx];
        final attrs = primObj['attributes'] as Map<String, dynamic>? ?? {};

        final posAccIdx = attrs['POSITION'] as int?;
        if (posAccIdx == null || posAccIdx >= accessors.length) continue;

        // 1. Pozycje wierzchołków
        final vertices = _readVec3Accessor(accessors[posAccIdx], bufferViews, binBd);
        if (vertices.isEmpty) continue;

        // 2. Normalne
        List<Vector3> normals = [];
        final normAccIdx = attrs['NORMAL'] as int?;
        if (normAccIdx != null && normAccIdx < accessors.length) {
          normals = _readVec3Accessor(accessors[normAccIdx], bufferViews, binBd);
        }

        // 3. Koordynaty UV
        List<Vector2> uvs = [];
        final uvAccIdx = attrs['TEXCOORD_0'] as int?;
        if (uvAccIdx != null && uvAccIdx < accessors.length) {
          uvs = _readVec2Accessor(accessors[uvAccIdx], bufferViews, binBd);
        }

        // 4. Indeksy trójkątów
        List<int> indices = [];
        final indAccIdx = primObj['indices'] as int?;
        if (indAccIdx != null && indAccIdx < accessors.length) {
          indices = _readIndicesAccessor(accessors[indAccIdx], bufferViews, binBd);
        } else {
          // Generowanie domyślnych indeksów sekwencyjnych
          indices = List.generate(vertices.length, (i) => i);
        }

        // Wyrównanie brakujących normalnych jeśli plik ich nie definiował
        if (normals.length != vertices.length) {
          normals = _generateSmoothNormals(vertices, indices);
        }

        // 5. Materiał prymitywu
        final matIdx = primObj['material'] as int?;
        GlbMaterialData primMaterial = GlbMaterialData.fallback();
        if (matIdx != null && matIdx < parsedMaterials.length) {
          primMaterial = parsedMaterials[matIdx];
        }

        // 6. Bounding Box prymitywu
        final primMin = Vector3.all(double.infinity);
        final primMax = Vector3.all(-double.infinity);
        for (final v in vertices) {
          primMin.x = math.min(primMin.x, v.x);
          primMin.y = math.min(primMin.y, v.y);
          primMin.z = math.min(primMin.z, v.z);

          primMax.x = math.max(primMax.x, v.x);
          primMax.y = math.max(primMax.y, v.y);
          primMax.z = math.max(primMax.z, v.z);

          overallMin.x = math.min(overallMin.x, v.x);
          overallMin.y = math.min(overallMin.y, v.y);
          overallMin.z = math.min(overallMin.z, v.z);

          overallMax.x = math.max(overallMax.x, v.x);
          overallMax.y = math.max(overallMax.y, v.y);
          overallMax.z = math.max(overallMax.z, v.z);
        }

        final primAabb = Aabb3.minMax(primMin, primMax);

        primitives.add(GlbMeshPrimitive(
          name: '${meshName}_prim_$pIdx',
          vertices: vertices,
          normals: normals,
          uvs: uvs,
          indices: indices,
          material: primMaterial,
          boundingBox: primAabb,
        ));
      }
    }

    if (primitives.isEmpty) {
      throw const FormatException('Plik GLB nie zawiera żadnych poprawnych prymitywów siatki trójkątów');
    }

    final modelAabb = Aabb3.minMax(overallMin, overallMax);
    final modelCenter = (overallMin + overallMax) * 0.5;
    final modelRadius = (overallMax - overallMin).length * 0.5;

    final totalVerts = primitives.fold(0, (acc, p) => acc + p.vertexCount);
    final totalTris = primitives.fold(0, (acc, p) => acc + p.triangleCount);

    return GlbModelGeometry(
      assetKey: assetKey,
      name: displayName,
      category: category,
      primitives: primitives,
      boundingBox: modelAabb,
      boundingCenter: modelCenter,
      boundingRadius: modelRadius,
      totalVertices: totalVerts,
      totalTriangles: totalTris,
      isProceduralFallback: false,
    );
  }

  // ===========================================================================
  // PARSOWANIE AKCESORÓW I BUFORÓW GLTF
  // ===========================================================================

  List<Vector3> _readVec3Accessor(
    Map<String, dynamic> acc,
    List<Map<String, dynamic>> bufferViews,
    ByteData binBd,
  ) {
    final bvIdx = acc['bufferView'] as int?;
    if (bvIdx == null || bvIdx >= bufferViews.length) return [];

    final bv = bufferViews[bvIdx];
    final bvOffset = bv['byteOffset'] as int? ?? 0;
    final accOffset = acc['byteOffset'] as int? ?? 0;
    final totalOffset = bvOffset + accOffset;

    final count = acc['count'] as int? ?? 0;
    final stride = bv['byteStride'] as int? ?? 12; // 3 x 4 bajty float

    final result = <Vector3>[];
    for (int i = 0; i < count; i++) {
      final offset = totalOffset + i * stride;
      if (offset + 12 > binBd.lengthInBytes) break;
      final x = binBd.getFloat32(offset, Endian.little);
      final y = binBd.getFloat32(offset + 4, Endian.little);
      final z = binBd.getFloat32(offset + 8, Endian.little);
      result.add(Vector3(x, y, z));
    }

    return result;
  }

  List<Vector2> _readVec2Accessor(
    Map<String, dynamic> acc,
    List<Map<String, dynamic>> bufferViews,
    ByteData binBd,
  ) {
    final bvIdx = acc['bufferView'] as int?;
    if (bvIdx == null || bvIdx >= bufferViews.length) return [];

    final bv = bufferViews[bvIdx];
    final bvOffset = bv['byteOffset'] as int? ?? 0;
    final accOffset = acc['byteOffset'] as int? ?? 0;
    final totalOffset = bvOffset + accOffset;

    final count = acc['count'] as int? ?? 0;
    final stride = bv['byteStride'] as int? ?? 8; // 2 x 4 bajty float

    final result = <Vector2>[];
    for (int i = 0; i < count; i++) {
      final offset = totalOffset + i * stride;
      if (offset + 8 > binBd.lengthInBytes) break;
      final u = binBd.getFloat32(offset, Endian.little);
      final v = binBd.getFloat32(offset + 4, Endian.little);
      result.add(Vector2(u, v));
    }

    return result;
  }

  List<int> _readIndicesAccessor(
    Map<String, dynamic> acc,
    List<Map<String, dynamic>> bufferViews,
    ByteData binBd,
  ) {
    final bvIdx = acc['bufferView'] as int?;
    if (bvIdx == null || bvIdx >= bufferViews.length) return [];

    final bv = bufferViews[bvIdx];
    final bvOffset = bv['byteOffset'] as int? ?? 0;
    final accOffset = acc['byteOffset'] as int? ?? 0;
    final totalOffset = bvOffset + accOffset;

    final count = acc['count'] as int? ?? 0;
    final componentType = acc['componentType'] as int? ?? 5123;

    final result = <int>[];
    if (componentType == 5123) {
      // UNSIGNED_SHORT (uint16)
      for (int i = 0; i < count; i++) {
        final offset = totalOffset + i * 2;
        if (offset + 2 > binBd.lengthInBytes) break;
        result.add(binBd.getUint16(offset, Endian.little));
      }
    } else if (componentType == 5125) {
      // UNSIGNED_INT (uint32)
      for (int i = 0; i < count; i++) {
        final offset = totalOffset + i * 4;
        if (offset + 4 > binBd.lengthInBytes) break;
        result.add(binBd.getUint32(offset, Endian.little));
      }
    } else if (componentType == 5121) {
      // UNSIGNED_BYTE (uint8)
      for (int i = 0; i < count; i++) {
        final offset = totalOffset + i;
        if (offset + 1 > binBd.lengthInBytes) break;
        result.add(binBd.getUint8(offset));
      }
    }

    return result;
  }

  List<Vector3> _generateSmoothNormals(List<Vector3> vertices, List<int> indices) {
    final normals = List<Vector3>.generate(vertices.length, (_) => Vector3.zero());

    for (int i = 0; i < indices.length - 2; i += 3) {
      final i0 = indices[i];
      final i1 = indices[i + 1];
      final i2 = indices[i + 2];

      if (i0 < vertices.length && i1 < vertices.length && i2 < vertices.length) {
        final v0 = vertices[i0];
        final v1 = vertices[i1];
        final v2 = vertices[i2];

        final e1 = v1 - v0;
        final e2 = v2 - v0;
        final normal = e1.cross(e2);
        if (normal.length2 > 1e-8) {
          normal.normalize();
          normals[i0] += normal;
          normals[i1] += normal;
          normals[i2] += normal;
        }
      }
    }

    for (int i = 0; i < normals.length; i++) {
      if (normals[i].length2 > 1e-8) {
        normals[i].normalize();
      } else {
        normals[i] = Vector3(0.0, 1.0, 0.0);
      }
    }

    return normals;
  }
}

/// Generator proceduralnych siatek 3D działający jako bufor bezpieczeństwa (Zero-Crash Fallback).
class GlbProceduralFallbackBuilder {
  /// Główna metoda budująca proceduralny model zamienny na podstawie klucza i kategorii.
  GlbModelGeometry buildFallback(String keyOrPath, {String? reason}) {
    final def = GlbAssetCatalog.find(keyOrPath);
    final key = def?.id ?? keyOrPath.split('/').last.replaceAll('.glb', '');
    final category = def?.category ?? _deduceCategory(key);
    final displayName = def?.displayName ?? 'Model Proceduralny ($key)';

    List<GlbMeshPrimitive> primitives = [];

    switch (category) {
      case GlbAssetCategory.bike:
        if (key.contains('wheel')) {
          primitives = _createWheelFallback(key);
        } else if (key.contains('component')) {
          primitives = _createComponentsFallback();
        } else {
          primitives = _createBikeFrameFallback(key);
        }
        break;

      case GlbAssetCategory.cyclist:
        if (key.contains('helmet')) {
          primitives = _createHelmetFallback(key);
        } else if (key.contains('glasses')) {
          primitives = _createGlassesFallback();
        } else {
          primitives = _createCyclistFallback();
        }
        break;

      case GlbAssetCategory.rider:
        primitives = _createCyclistFallback(isAnimated: true);
        break;

      case GlbAssetCategory.environment:
        if (key.contains('tree') || key.contains('pine') || key.contains('cypress')) {
          primitives = _createTreeFallback(key);
        } else if (key.contains('rock') || key.contains('boulder')) {
          primitives = _createRockFallback();
        } else if (key.contains('mountain') || key.contains('peak')) {
          primitives = _createMountainPeakFallback();
        } else if (key.contains('building') || key.contains('town')) {
          primitives = _createTownhouseFallback();
        } else if (key.contains('spectator') || key.contains('fan')) {
          primitives = _createSpectatorsFallback();
        } else {
          primitives = _createGenericFallbackBox(key, const Color(0xFF2E7D32));
        }
        break;

      case GlbAssetCategory.furniture:
        if (key.contains('barrier')) {
          primitives = _createBarrierFallback();
        } else {
          primitives = _createArchFallback(key);
        }
        break;

      case GlbAssetCategory.road:
        primitives = _createRoadSegmentFallback(key);
        break;

      case GlbAssetCategory.vehicle:
        if (key.contains('car')) {
          primitives = _createTeamCarFallback();
        } else {
          primitives = _createMotorcycleFallback(key);
        }
        break;

      case GlbAssetCategory.unknown:
        primitives = _createGenericFallbackBox(key, const Color(0xFFD97706));
        break;
    }

    if (primitives.isEmpty) {
      primitives = _createGenericFallbackBox(key, const Color(0xFF6366F1));
    }

    // Wyznaczenie całościowego Bounding Box
    final overallMin = Vector3.all(double.infinity);
    final overallMax = Vector3.all(-double.infinity);
    for (final p in primitives) {
      overallMin.x = math.min(overallMin.x, p.boundingBox.min.x);
      overallMin.y = math.min(overallMin.y, p.boundingBox.min.y);
      overallMin.z = math.min(overallMin.z, p.boundingBox.min.z);

      overallMax.x = math.max(overallMax.x, p.boundingBox.max.x);
      overallMax.y = math.max(overallMax.y, p.boundingBox.max.y);
      overallMax.z = math.max(overallMax.z, p.boundingBox.max.z);
    }

    final aabb = Aabb3.minMax(overallMin, overallMax);
    final center = (overallMin + overallMax) * 0.5;
    final radius = (overallMax - overallMin).length * 0.5;

    final totalVerts = primitives.fold(0, (acc, p) => acc + p.vertexCount);
    final totalTris = primitives.fold(0, (acc, p) => acc + p.triangleCount);

    return GlbModelGeometry(
      assetKey: key,
      name: displayName,
      category: category,
      primitives: primitives,
      boundingBox: aabb,
      boundingCenter: center,
      boundingRadius: radius,
      totalVertices: totalVerts,
      totalTriangles: totalTris,
      isProceduralFallback: true,
      fallbackReason: reason ?? 'Natychmiastowa proceduralna siatka zapasowa',
    );
  }

  GlbAssetCategory _deduceCategory(String key) {
    final lower = key.toLowerCase();
    if (lower.contains('frame') || lower.contains('wheel')) return GlbAssetCategory.bike;
    if (lower.contains('cyclist') || lower.contains('helmet')) return GlbAssetCategory.cyclist;
    if (lower.contains('tree') || lower.contains('rock') || lower.contains('building')) return GlbAssetCategory.environment;
    if (lower.contains('arch') || lower.contains('barrier')) return GlbAssetCategory.furniture;
    if (lower.contains('road')) return GlbAssetCategory.road;
    if (lower.contains('vehicle') || lower.contains('moto') || lower.contains('car')) return GlbAssetCategory.vehicle;
    return GlbAssetCategory.unknown;
  }

  // ===========================================================================
  // 1. PROCEDURALNE MODELE ROWERÓW I KÓŁ (BIKE & WHEEL FALLBACKS)
  // ===========================================================================

  List<GlbMeshPrimitive> _createBikeFrameFallback(String key) {
    final prims = <GlbMeshPrimitive>[];

    // Kolor ramy zależny od wariantu
    Color frameColor = const Color(0xFFE11D48); // Karminowy dla Aero
    double roughness = 0.15;
    if (key.contains('climbing')) {
      frameColor = const Color(0xFF1E293B); // Ciemny karbon
      roughness = 0.5;
    } else if (key.contains('tt')) {
      frameColor = const Color(0xFF0284C7); // Metaliczny błękit TT
      roughness = 0.2;
    }

    final frameMat = GlbMaterialData(
      name: 'M_Frame_PBR',
      baseColor: frameColor,
      roughness: roughness,
      metallic: 0.1,
    );

    const carbonMat = GlbMaterialData(
      name: 'M_Carbon_PBR',
      baseColor: Color(0xFF111827),
      roughness: 0.6,
      metallic: 0.05,
    );

    // Węzły geometrii ramy szosowej (X: wzdłuż osi, Y: wysokość, Z: szerokość)
    final bb = Vector3(0.0, 0.28, 0.0); // Suport (Bottom Bracket)
    final headTop = Vector3(0.55, 0.88, 0.0); // Główka ramy - góra
    final headBot = Vector3(0.52, 0.74, 0.0); // Główka ramy - dół
    final seatCluster = Vector3(-0.16, 0.78, 0.0); // Węzeł podsiodłowy
    final rearDropoutL = Vector3(-0.43, 0.32, -0.065); // Hak tylny lewy
    final rearDropoutR = Vector3(-0.43, 0.32, 0.065); // Hak tylny prawy
    final forkTipL = Vector3(0.56, 0.32, -0.05); // Hak widelca lewy
    final forkTipR = Vector3(0.56, 0.32, 0.05); // Hak widelca prawy

    // Rury głównego trójkąta ramy
    prims.add(_buildTubePrimitive('top_tube', seatCluster, headTop, 0.024, frameMat));
    prims.add(_buildTubePrimitive('down_tube', headBot, bb, 0.032, frameMat));
    prims.add(_buildTubePrimitive('seat_tube', seatCluster, bb, 0.026, frameMat));
    prims.add(_buildTubePrimitive('head_tube', headBot, headTop, 0.028, frameMat));

    // Tylne widełki (Chainstays & Seatstays)
    prims.add(_buildTubePrimitive('chainstay_l', bb, rearDropoutL, 0.016, carbonMat));
    prims.add(_buildTubePrimitive('chainstay_r', bb, rearDropoutR, 0.016, carbonMat));
    prims.add(_buildTubePrimitive('seatstay_l', seatCluster, rearDropoutL, 0.014, carbonMat));
    prims.add(_buildTubePrimitive('seatstay_r', seatCluster, rearDropoutR, 0.014, carbonMat));

    // Przedni widelec
    prims.add(_buildTubePrimitive('fork_l', headBot, forkTipL, 0.018, frameMat));
    prims.add(_buildTubePrimitive('fork_r', headBot, forkTipR, 0.018, frameMat));

    return prims;
  }

  List<GlbMeshPrimitive> _createWheelFallback(String key) {
    final prims = <GlbMeshPrimitive>[];

    const tireMat = GlbMaterialData(
      name: 'M_Tire_Rubber',
      baseColor: Color(0xFF1F2430),
      roughness: 0.85,
      metallic: 0.0,
    );

    const carbonRimMat = GlbMaterialData(
      name: 'M_Carbon_Rim',
      baseColor: Color(0xFF111827),
      roughness: 0.3,
      metallic: 0.1,
    );

    final isDisc = key.contains('disc');
    final double rimDepth = key.contains('65mm')
        ? 0.065
        : (key.contains('35mm') ? 0.035 : 0.050);

    const double outerRadius = 0.311; // 700c wheel
    final double innerRadius = isDisc ? 0.03 : (outerRadius - rimDepth);

    // Opona kolarska
    prims.add(_buildTorusPrimitive('tire', outerRadius, 0.014, 18, 8, tireMat));

    // Stożek obręczy karbonowej
    prims.add(_buildDiskPrimitive('rim_disc', innerRadius, outerRadius, 24, carbonRimMat));

    // Piasta i szprychy
    const hubMat = GlbMaterialData(
      name: 'M_Hub_Alu',
      baseColor: Color(0xFF4B5563),
      roughness: 0.2,
      metallic: 0.8,
    );
    prims.add(_buildCylinderPrimitive(
      'hub',
      Vector3(0.0, 0.0, -0.025),
      Vector3(0.0, 0.0, 0.025),
      0.02,
      hubMat,
    ));

    return prims;
  }

  List<GlbMeshPrimitive> _createComponentsFallback() {
    final prims = <GlbMeshPrimitive>[];
    const aluMat = GlbMaterialData(
      name: 'M_Alu_Black',
      baseColor: Color(0xFF1E2330),
      roughness: 0.35,
      metallic: 0.4,
    );

    // Mostek i kierownica
    prims.add(_buildCylinderPrimitive(
      'stem',
      Vector3(0.55, 0.88, 0.0),
      Vector3(0.66, 0.86, 0.0),
      0.018,
      aluMat,
    ));
    prims.add(_buildCylinderPrimitive(
      'handlebar_top',
      Vector3(0.66, 0.86, -0.21),
      Vector3(0.66, 0.86, 0.21),
      0.015,
      aluMat,
    ));

    // Siodełko
    const saddleMat = GlbMaterialData(
      name: 'M_Saddle_Leather',
      baseColor: Color(0xFF0F172A),
      roughness: 0.6,
      metallic: 0.0,
    );
    prims.add(_buildBoxPrimitive(
      'saddle',
      Vector3(-0.16, 0.85, 0.0),
      Vector3(0.24, 0.04, 0.13),
      saddleMat,
    ));

    // Korba i pedały
    prims.add(_buildCylinderPrimitive(
      'crank_left',
      Vector3(0.0, 0.28, -0.07),
      Vector3(0.0, 0.11, -0.07),
      0.012,
      aluMat,
    ));
    prims.add(_buildCylinderPrimitive(
      'crank_right',
      Vector3(0.0, 0.28, 0.07),
      Vector3(0.0, 0.45, 0.07),
      0.012,
      aluMat,
    ));

    return prims;
  }

  // ===========================================================================
  // 2. PROCEDURALNE MODELE KOLARZY I KASKÓW (CYCLIST & HELMET FALLBACKS)
  // ===========================================================================

  List<GlbMeshPrimitive> _createCyclistFallback({bool isAnimated = false}) {
    final prims = <GlbMeshPrimitive>[];

    const jerseyMat = GlbMaterialData(
      name: 'M_Jersey_Pro',
      baseColor: Color(0xFFF59E0B), // Złoty lider
      roughness: 0.7,
      metallic: 0.0,
    );
    const shortsMat = GlbMaterialData(
      name: 'M_Shorts_Black',
      baseColor: Color(0xFF0F172A),
      roughness: 0.85,
      metallic: 0.0,
    );
    const skinMat = GlbMaterialData(
      name: 'M_Rider_Skin',
      baseColor: Color(0xFFDEB887),
      roughness: 0.6,
      metallic: 0.0,
    );

    // Tułów pochylony aerodynamicznie (Torso)
    prims.add(_buildBoxPrimitive(
      'torso',
      Vector3(0.12, 1.05, 0.0),
      Vector3(0.42, 0.22, 0.32),
      jerseyMat,
    ));

    // Biodra (Pelvis)
    prims.add(_buildBoxPrimitive(
      'pelvis',
      Vector3(-0.12, 0.88, 0.0),
      Vector3(0.22, 0.18, 0.28),
      shortsMat,
    ));

    // Głowa z kaskiem
    prims.add(_buildSpherePrimitive(
      'head',
      Vector3(0.38, 1.22, 0.0),
      0.12,
      12,
      8,
      skinMat,
    ));

    // Ramiona sięgające kierownicy
    prims.add(_buildTubePrimitive('arm_l', Vector3(0.28, 1.10, -0.16), Vector3(0.64, 0.86, -0.18), 0.04, skinMat));
    prims.add(_buildTubePrimitive('arm_r', Vector3(0.28, 1.10, 0.16), Vector3(0.64, 0.86, 0.18), 0.04, skinMat));

    // Nogi ugięte w pozycji pedałowania
    prims.add(_buildTubePrimitive('thigh_l', Vector3(-0.10, 0.86, -0.12), Vector3(0.12, 0.65, -0.14), 0.055, shortsMat));
    prims.add(_buildTubePrimitive('calf_l', Vector3(0.12, 0.65, -0.14), Vector3(0.0, 0.11, -0.12), 0.045, skinMat));

    prims.add(_buildTubePrimitive('thigh_r', Vector3(-0.10, 0.86, 0.12), Vector3(0.05, 0.72, 0.14), 0.055, shortsMat));
    prims.add(_buildTubePrimitive('calf_r', Vector3(0.05, 0.72, 0.14), Vector3(0.0, 0.45, 0.12), 0.045, skinMat));

    return prims;
  }

  List<GlbMeshPrimitive> _createHelmetFallback(String key) {
    final prims = <GlbMeshPrimitive>[];
    const helmetMat = GlbMaterialData(
      name: 'M_Helmet_Shell',
      baseColor: Color(0xFFE2E8F0),
      roughness: 0.15,
      metallic: 0.1,
    );

    if (key.contains('tt')) {
      // Kask czasowy w kształcie łezki z długim ogonem
      prims.add(_buildConePrimitive(
        'tt_tail',
        Vector3(0.0, 0.0, 0.0),
        Vector3(-0.35, -0.08, 0.0),
        0.14,
        14,
        helmetMat,
      ));
    }

    prims.add(_buildSpherePrimitive(
      'helmet_dome',
      Vector3(0.0, 0.0, 0.0),
      0.14,
      14,
      8,
      helmetMat,
    ));

    return prims;
  }

  List<GlbMeshPrimitive> _createGlassesFallback() {
    final prims = <GlbMeshPrimitive>[];
    const lensMat = GlbMaterialData(
      name: 'M_Glasses_Iridium',
      baseColor: Color(0xFF00E5FF),
      roughness: 0.05,
      metallic: 0.9,
      isTransparent: true,
      opacity: 0.75,
    );

    prims.add(_buildBoxPrimitive(
      'lens',
      Vector3(0.0, 0.0, 0.0),
      Vector3(0.04, 0.06, 0.16),
      lensMat,
    ));

    return prims;
  }

  // ===========================================================================
  // 3. PROCEDURALNE OTOCZENIE TRASY (ENVIRONMENT FALLBACKS)
  // ===========================================================================

  List<GlbMeshPrimitive> _createTreeFallback(String key) {
    final prims = <GlbMeshPrimitive>[];

    const trunkMat = GlbMaterialData(
      name: 'M_Bark_Brown',
      baseColor: Color(0xFF3E2723),
      roughness: 0.9,
      metallic: 0.0,
    );

    if (key.contains('cypress')) {
      // Cyprys toskański (smukła pionowa kolumna)
      const foliageMat = GlbMaterialData(
        name: 'M_Cypress_Green',
        baseColor: Color(0xFF1B4D2E),
        roughness: 0.75,
        metallic: 0.0,
      );
      prims.add(_buildCylinderPrimitive('trunk', Vector3(0.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0), 0.12, trunkMat));
      prims.add(_buildCylinderPrimitive('foliage', Vector3(0.0, 0.8, 0.0), Vector3(0.0, 6.5, 0.0), 0.45, foliageMat));
      return prims;
    }

    if (key.contains('deciduous')) {
      // Drzewo liściaste (dąb z rozłożystą koroną)
      const foliageMat = GlbMaterialData(
        name: 'M_Deciduous_Green',
        baseColor: Color(0xFF2E7D32),
        roughness: 0.8,
        metallic: 0.0,
      );
      prims.add(_buildCylinderPrimitive('trunk', Vector3(0.0, 0.0, 0.0), Vector3(0.0, 2.2, 0.0), 0.22, trunkMat));
      prims.add(_buildSpherePrimitive('canopy', Vector3(0.0, 4.2, 0.0), 2.2, 12, 8, foliageMat));
      return prims;
    }

    // Domyślnie: Alpejska Sosna (trzy stożki igliwia)
    const pineMat = GlbMaterialData(
      name: 'M_Pine_Needles',
      baseColor: Color(0xFF14532D),
      roughness: 0.85,
      metallic: 0.0,
    );

    prims.add(_buildCylinderPrimitive('trunk', Vector3(0.0, 0.0, 0.0), Vector3(0.0, 2.0, 0.0), 0.2, trunkMat));
    prims.add(_buildConePrimitive('tier_1', Vector3(0.0, 1.8, 0.0), Vector3(0.0, 4.5, 0.0), 1.8, 12, pineMat));
    prims.add(_buildConePrimitive('tier_2', Vector3(0.0, 3.5, 0.0), Vector3(0.0, 6.2, 0.0), 1.4, 12, pineMat));
    prims.add(_buildConePrimitive('tier_3', Vector3(0.0, 5.2, 0.0), Vector3(0.0, 7.8, 0.0), 0.9, 10, pineMat));

    return prims;
  }

  List<GlbMeshPrimitive> _createRockFallback() {
    const rockMat = GlbMaterialData(
      name: 'M_Rock_Granite',
      baseColor: Color(0xFF64748B),
      roughness: 0.88,
      metallic: 0.05,
    );

    return [_buildBoxPrimitive('boulder', Vector3(0.0, 0.6, 0.0), Vector3(1.6, 1.2, 1.4), rockMat)];
  }

  List<GlbMeshPrimitive> _createMountainPeakFallback() {
    final prims = <GlbMeshPrimitive>[];

    const mountainBaseMat = GlbMaterialData(
      name: 'M_Mountain_Rock',
      baseColor: Color(0xFF475569),
      roughness: 0.9,
      metallic: 0.0,
    );
    const snowCapMat = GlbMaterialData(
      name: 'M_Alpine_Snow',
      baseColor: Color(0xFFFFFFFF),
      roughness: 0.35,
      metallic: 0.1,
    );

    prims.add(_buildConePrimitive(
      'mountain_body',
      Vector3(0.0, 0.0, 0.0),
      Vector3(0.0, 120.0, 0.0),
      85.0,
      12,
      mountainBaseMat,
    ));
    prims.add(_buildConePrimitive(
      'snow_summit',
      Vector3(0.0, 85.0, 0.0),
      Vector3(0.0, 120.0, 0.0),
      25.0,
      12,
      snowCapMat,
    ));

    return prims;
  }

  List<GlbMeshPrimitive> _createTownhouseFallback() {
    final prims = <GlbMeshPrimitive>[];

    const wallMat = GlbMaterialData(
      name: 'M_House_Plaster',
      baseColor: Color(0xFFFEF3C7),
      roughness: 0.9,
      metallic: 0.0,
    );
    const roofMat = GlbMaterialData(
      name: 'M_Terracotta_Roof',
      baseColor: Color(0xFFB45309),
      roughness: 0.7,
      metallic: 0.0,
    );

    // Korpus budynku (2 piętra)
    prims.add(_buildBoxPrimitive(
      'walls',
      Vector3(0.0, 4.0, 0.0),
      Vector3(7.0, 8.0, 8.5),
      wallMat,
    ));

    // Dach dwuspadowy
    prims.add(_buildConePrimitive(
      'roof',
      Vector3(0.0, 8.0, 0.0),
      Vector3(0.0, 11.5, 0.0),
      5.5,
      4,
      roofMat,
    ));

    return prims;
  }

  List<GlbMeshPrimitive> _createSpectatorsFallback() {
    final prims = <GlbMeshPrimitive>[];
    final fanColors = [const Color(0xFFEF4444), const Color(0xFF3B82F6), const Color(0xFFEAB308)];

    for (int i = 0; i < 3; i++) {
      final fanMat = GlbMaterialData(
        name: 'M_Fan_Clothing_$i',
        baseColor: fanColors[i],
        roughness: 0.8,
      );
      final offset = Vector3((i - 1) * 0.7, 0.0, 0.0);
      prims.add(_buildBoxPrimitive('fan_torso_$i', offset + Vector3(0.0, 1.1, 0.0), Vector3(0.35, 0.6, 0.25), fanMat));
      prims.add(_buildSpherePrimitive('fan_head_$i', offset + Vector3(0.0, 1.6, 0.0), 0.12, 8, 6, fanMat));
    }

    return prims;
  }

  // ===========================================================================
  // 4. PROCEDURALNA INFRASTRUKTURA WYŚCIGOWA (ARCHES & BARRIERS)
  // ===========================================================================

  List<GlbMeshPrimitive> _createArchFallback(String key) {
    final prims = <GlbMeshPrimitive>[];

    Color bannerColor = const Color(0xFF0F172A);
    if (key.contains('flamme_rouge')) {
      bannerColor = const Color(0xFFDC2626); // Czerwień Flamme Rouge
    } else if (key.contains('kom')) {
      bannerColor = const Color(0xFFBE123C); // Polka dot czerwony
    } else if (key.contains('sprint')) {
      bannerColor = const Color(0xFF15803D); // Zielony sprinterów
    }

    const trussMat = GlbMaterialData(
      name: 'M_Truss_Alu',
      baseColor: Color(0xFFCBD5E1),
      roughness: 0.25,
      metallic: 0.8,
    );

    final bannerMat = GlbMaterialData(
      name: 'M_Banner_Graphic',
      baseColor: bannerColor,
      roughness: 0.5,
      metallic: 0.0,
    );

    const double roadWidth = 8.5;
    const double archHeight = 5.2;

    // Lewy i prawy słup kratownicowy
    prims.add(_buildCylinderPrimitive(
      'pillar_l',
      Vector3(-roadWidth * 0.5, 0.0, 0.0),
      Vector3(-roadWidth * 0.5, archHeight, 0.0),
      0.22,
      trussMat,
    ));
    prims.add(_buildCylinderPrimitive(
      'pillar_r',
      Vector3(roadWidth * 0.5, 0.0, 0.0),
      Vector3(roadWidth * 0.5, archHeight, 0.0),
      0.22,
      trussMat,
    ));

    // Belka poprzeczna
    prims.add(_buildCylinderPrimitive(
      'crossbeam',
      Vector3(-roadWidth * 0.5, archHeight, 0.0),
      Vector3(roadWidth * 0.5, archHeight, 0.0),
      0.24,
      trussMat,
    ));

    // Baner reklamowy / pomiar czasu nad szosą
    prims.add(_buildBoxPrimitive(
      'banner',
      Vector3(0.0, archHeight - 0.5, 0.0),
      Vector3(roadWidth - 0.5, 1.2, 0.35),
      bannerMat,
    ));

    return prims;
  }

  List<GlbMeshPrimitive> _createBarrierFallback() {
    const barrierMat = GlbMaterialData(
      name: 'M_Barrier_Blue',
      baseColor: Color(0xFF0284C7),
      roughness: 0.4,
      metallic: 0.5,
    );

    return [_buildBoxPrimitive('barrier', Vector3(0.0, 0.5, 0.0), Vector3(2.2, 1.0, 0.12), barrierMat)];
  }

  // ===========================================================================
  // 5. PROCEDURALNE SZOSY I POJAZDY (ROADS & VEHICLES)
  // ===========================================================================

  List<GlbMeshPrimitive> _createRoadSegmentFallback(String key) {
    final roadMat = GlbMaterialData(
      name: 'M_Road_Surface',
      baseColor: key.contains('cobbles') ? const Color(0xFF475569) : const Color(0xFF1E2430),
      roughness: key.contains('cobbles') ? 0.95 : 0.7,
      metallic: 0.0,
    );

    return [_buildBoxPrimitive('road_ribbon', Vector3(0.0, -0.05, 0.0), Vector3(8.0, 0.1, 20.0), roadMat)];
  }

  List<GlbMeshPrimitive> _createTeamCarFallback() {
    final prims = <GlbMeshPrimitive>[];

    const carPaintMat = GlbMaterialData(
      name: 'M_TeamCar_Paint',
      baseColor: Color(0xFF0284C7),
      roughness: 0.15,
      metallic: 0.3,
    );
    const glassMat = GlbMaterialData(
      name: 'M_Car_Glass',
      baseColor: Color(0xFF0F172A),
      roughness: 0.05,
      metallic: 0.9,
      isTransparent: true,
      opacity: 0.85,
    );
    const wheelMat = GlbMaterialData(
      name: 'M_Car_Wheel',
      baseColor: Color(0xFF18181B),
      roughness: 0.8,
    );

    // Podwozie i nadwozie kombi
    prims.add(_buildBoxPrimitive('chassis', Vector3(0.0, 0.5, 0.0), Vector3(1.85, 0.55, 4.6), carPaintMat));
    prims.add(_buildBoxPrimitive('cabin', Vector3(0.0, 1.05, -0.3), Vector3(1.65, 0.6, 2.7), glassMat));

    // Bagażnik dachowy z zapasowymi rowerami
    const rackMat = GlbMaterialData(name: 'M_Roof_Rack', baseColor: Color(0xFF475569), roughness: 0.3, metallic: 0.7);
    prims.add(_buildBoxPrimitive('roof_rack', Vector3(0.0, 1.4, -0.3), Vector3(1.5, 0.15, 2.2), rackMat));

    // Koła samochodu (4 sztuki)
    prims.add(_buildCylinderPrimitive('wheel_fl', Vector3(-0.95, 0.32, 1.4), Vector3(-0.75, 0.32, 1.4), 0.32, wheelMat));
    prims.add(_buildCylinderPrimitive('wheel_fr', Vector3(0.75, 0.32, 1.4), Vector3(0.95, 0.32, 1.4), 0.32, wheelMat));
    prims.add(_buildCylinderPrimitive('wheel_rl', Vector3(-0.95, 0.32, -1.4), Vector3(-0.75, 0.32, -1.4), 0.32, wheelMat));
    prims.add(_buildCylinderPrimitive('wheel_rr', Vector3(0.75, 0.32, -1.4), Vector3(0.95, 0.32, -1.4), 0.32, wheelMat));

    return prims;
  }

  List<GlbMeshPrimitive> _createMotorcycleFallback(String key) {
    final prims = <GlbMeshPrimitive>[];

    const motoMat = GlbMaterialData(
      name: 'M_Moto_Body',
      baseColor: Color(0xFFEAB308), // Żółty motocykl medialny
      roughness: 0.25,
      metallic: 0.2,
    );
    const tireMat = GlbMaterialData(name: 'M_Moto_Tire', baseColor: Color(0xFF18181B), roughness: 0.85);

    // Rama i owiewka motocykla
    prims.add(_buildBoxPrimitive('moto_body', Vector3(0.0, 0.65, 0.0), Vector3(0.65, 0.6, 2.1), motoMat));

    // Koło przednie i tylne
    prims.add(_buildCylinderPrimitive('front_wheel', Vector3(-0.06, 0.32, 0.85), Vector3(0.06, 0.32, 0.85), 0.32, tireMat));
    prims.add(_buildCylinderPrimitive('rear_wheel', Vector3(-0.06, 0.32, -0.85), Vector3(0.06, 0.32, -0.85), 0.32, tireMat));

    return prims;
  }

  List<GlbMeshPrimitive> _createGenericFallbackBox(String key, Color color) {
    final mat = GlbMaterialData(name: 'M_Generic_$key', baseColor: color, roughness: 0.5, metallic: 0.1);
    return [_buildBoxPrimitive('generic_cube', Vector3(0.0, 0.5, 0.0), Vector3(1.0, 1.0, 1.0), mat)];
  }

  // ===========================================================================
  // GEOMETRYCZNE FUNKCJE BUDOWANIA PRYMITYWÓW 3D
  // ===========================================================================

  GlbMeshPrimitive _buildBoxPrimitive(String name, Vector3 center, Vector3 size, GlbMaterialData mat) {
    final hx = size.x * 0.5;
    final hy = size.y * 0.5;
    final hz = size.z * 0.5;

    final verts = <Vector3>[
      // Przód
      Vector3(center.x - hx, center.y - hy, center.z + hz),
      Vector3(center.x + hx, center.y - hy, center.z + hz),
      Vector3(center.x + hx, center.y + hy, center.z + hz),
      Vector3(center.x - hx, center.y + hy, center.z + hz),
      // Tył
      Vector3(center.x + hx, center.y - hy, center.z - hz),
      Vector3(center.x - hx, center.y - hy, center.z - hz),
      Vector3(center.x - hx, center.y + hy, center.z - hz),
      Vector3(center.x + hx, center.y + hy, center.z - hz),
      // Góra
      Vector3(center.x - hx, center.y + hy, center.z + hz),
      Vector3(center.x + hx, center.y + hy, center.z + hz),
      Vector3(center.x + hx, center.y + hy, center.z - hz),
      Vector3(center.x - hx, center.y + hy, center.z - hz),
      // Dół
      Vector3(center.x - hx, center.y - hy, center.z - hz),
      Vector3(center.x + hx, center.y - hy, center.z - hz),
      Vector3(center.x + hx, center.y - hy, center.z + hz),
      Vector3(center.x - hx, center.y - hy, center.z + hz),
      // Lewo
      Vector3(center.x - hx, center.y - hy, center.z - hz),
      Vector3(center.x - hx, center.y - hy, center.z + hz),
      Vector3(center.x - hx, center.y + hy, center.z + hz),
      Vector3(center.x - hx, center.y + hy, center.z - hz),
      // Prawo
      Vector3(center.x + hx, center.y - hy, center.z + hz),
      Vector3(center.x + hx, center.y - hy, center.z - hz),
      Vector3(center.x + hx, center.y + hy, center.z - hz),
      Vector3(center.x + hx, center.y + hy, center.z + hz),
    ];

    final normals = <Vector3>[
      for (int i = 0; i < 4; i++) Vector3(0.0, 0.0, 1.0),
      for (int i = 0; i < 4; i++) Vector3(0.0, 0.0, -1.0),
      for (int i = 0; i < 4; i++) Vector3(0.0, 1.0, 0.0),
      for (int i = 0; i < 4; i++) Vector3(0.0, -1.0, 0.0),
      for (int i = 0; i < 4; i++) Vector3(-1.0, 0.0, 0.0),
      for (int i = 0; i < 4; i++) Vector3(1.0, 0.0, 0.0),
    ];

    final uvs = <Vector2>[
      for (int i = 0; i < 6; i++) ...[
        Vector2(0.0, 0.0),
        Vector2(1.0, 0.0),
        Vector2(1.0, 1.0),
        Vector2(0.0, 1.0),
      ]
    ];

    final indices = <int>[];
    for (int face = 0; face < 6; face++) {
      final base = face * 4;
      indices.addAll([base, base + 1, base + 2, base, base + 2, base + 3]);
    }

    final minVec = center - Vector3(hx, hy, hz);
    final maxVec = center + Vector3(hx, hy, hz);

    return GlbMeshPrimitive(
      name: name,
      vertices: verts,
      normals: normals,
      uvs: uvs,
      indices: indices,
      material: mat,
      boundingBox: Aabb3.minMax(minVec, maxVec),
    );
  }

  GlbMeshPrimitive _buildTubePrimitive(String name, Vector3 start, Vector3 end, double radius, GlbMaterialData mat) {
    return _buildCylinderPrimitive(name, start, end, radius, mat, segments: 8);
  }

  GlbMeshPrimitive _buildCylinderPrimitive(
    String name,
    Vector3 start,
    Vector3 end,
    double radius,
    GlbMaterialData mat, {
    int segments = 12,
  }) {
    final axis = end - start;
    final length = axis.length;
    if (length < 1e-6) {
      return _buildBoxPrimitive(name, start, Vector3.all(radius * 2.0), mat);
    }

    final dir = axis / length;
    Vector3 right = Vector3(0.0, 1.0, 0.0).cross(dir);
    if (right.length2 < 1e-4) {
      right = Vector3(1.0, 0.0, 0.0).cross(dir);
    }
    right.normalize();
    final up = dir.cross(right)..normalize();

    final verts = <Vector3>[];
    final normals = <Vector3>[];
    final uvs = <Vector2>[];
    final indices = <int>[];

    // Punkty pobocznicy cylindra
    for (int i = 0; i <= segments; i++) {
      final angle = (i % segments) * 2.0 * math.pi / segments;
      final radialDir = (right * math.cos(angle) + up * math.sin(angle))..normalize();

      verts.add(start + radialDir * radius);
      normals.add(radialDir);
      uvs.add(Vector2(i / segments, 0.0));

      verts.add(end + radialDir * radius);
      normals.add(radialDir);
      uvs.add(Vector2(i / segments, 1.0));
    }

    for (int i = 0; i < segments; i++) {
      final b0 = i * 2;
      final t0 = i * 2 + 1;
      final b1 = (i + 1) * 2;
      final t1 = (i + 1) * 2 + 1;

      indices.addAll([b0, b1, t0, t0, b1, t1]);
    }

    final minVec = Vector3.all(double.infinity);
    final maxVec = Vector3.all(-double.infinity);
    for (final v in verts) {
      minVec.x = math.min(minVec.x, v.x);
      minVec.y = math.min(minVec.y, v.y);
      minVec.z = math.min(minVec.z, v.z);

      maxVec.x = math.max(maxVec.x, v.x);
      maxVec.y = math.max(maxVec.y, v.y);
      maxVec.z = math.max(maxVec.z, v.z);
    }

    return GlbMeshPrimitive(
      name: name,
      vertices: verts,
      normals: normals,
      uvs: uvs,
      indices: indices,
      material: mat,
      boundingBox: Aabb3.minMax(minVec, maxVec),
    );
  }

  GlbMeshPrimitive _buildConePrimitive(
    String name,
    Vector3 baseCenter,
    Vector3 tip,
    double radius,
    int segments,
    GlbMaterialData mat,
  ) {
    final axis = tip - baseCenter;
    final height = axis.length;
    final dir = height > 1e-6 ? (axis / height) : Vector3(0.0, 1.0, 0.0);

    Vector3 right = Vector3(0.0, 1.0, 0.0).cross(dir);
    if (right.length2 < 1e-4) right = Vector3(1.0, 0.0, 0.0).cross(dir);
    right.normalize();
    final up = dir.cross(right)..normalize();

    final verts = <Vector3>[tip]; // wierzchołek 0 = czubek
    final normals = <Vector3>[dir];
    final uvs = <Vector2>[Vector2(0.5, 1.0)];
    final indices = <int>[];

    for (int i = 0; i < segments; i++) {
      final angle = i * 2.0 * math.pi / segments;
      final radialDir = (right * math.cos(angle) + up * math.sin(angle))..normalize();
      final p = baseCenter + radialDir * radius;
      verts.add(p);
      normals.add((radialDir * height + dir * radius)..normalize());
      uvs.add(Vector2(i / segments, 0.0));
    }

    for (int i = 0; i < segments; i++) {
      final curr = 1 + i;
      final next = 1 + ((i + 1) % segments);
      indices.addAll([0, curr, next]);
    }

    final minVec = Vector3.all(double.infinity);
    final maxVec = Vector3.all(-double.infinity);
    for (final v in verts) {
      minVec.x = math.min(minVec.x, v.x);
      minVec.y = math.min(minVec.y, v.y);
      minVec.z = math.min(minVec.z, v.z);

      maxVec.x = math.max(maxVec.x, v.x);
      maxVec.y = math.max(maxVec.y, v.y);
      maxVec.z = math.max(maxVec.z, v.z);
    }

    return GlbMeshPrimitive(
      name: name,
      vertices: verts,
      normals: normals,
      uvs: uvs,
      indices: indices,
      material: mat,
      boundingBox: Aabb3.minMax(minVec, maxVec),
    );
  }

  GlbMeshPrimitive _buildSpherePrimitive(
    String name,
    Vector3 center,
    double radius,
    int slices,
    int stacks,
    GlbMaterialData mat,
  ) {
    final verts = <Vector3>[];
    final normals = <Vector3>[];
    final uvs = <Vector2>[];
    final indices = <int>[];

    for (int t = 0; t <= stacks; t++) {
      final phi = t * math.pi / stacks;
      final y = radius * math.cos(phi);
      final rSlice = radius * math.sin(phi);

      for (int s = 0; s <= slices; s++) {
        final theta = s * 2.0 * math.pi / slices;
        final x = rSlice * math.cos(theta);
        final z = rSlice * math.sin(theta);

        final norm = Vector3(x, y, z)..normalize();
        verts.add(center + Vector3(x, y, z));
        normals.add(norm);
        uvs.add(Vector2(s / slices, t / stacks));
      }
    }

    for (int t = 0; t < stacks; t++) {
      for (int s = 0; s < slices; s++) {
        final first = (t * (slices + 1)) + s;
        final second = first + slices + 1;

        indices.addAll([first, second, first + 1]);
        indices.addAll([second, second + 1, first + 1]);
      }
    }

    final minVec = center - Vector3.all(radius);
    final maxVec = center + Vector3.all(radius);

    return GlbMeshPrimitive(
      name: name,
      vertices: verts,
      normals: normals,
      uvs: uvs,
      indices: indices,
      material: mat,
      boundingBox: Aabb3.minMax(minVec, maxVec),
    );
  }

  GlbMeshPrimitive _buildTorusPrimitive(
    String name,
    double majorRadius,
    double minorRadius,
    int radialSegments,
    int tubularSegments,
    GlbMaterialData mat,
  ) {
    final verts = <Vector3>[];
    final normals = <Vector3>[];
    final uvs = <Vector2>[];
    final indices = <int>[];

    for (int j = 0; j <= radialSegments; j++) {
      final u = j * 2.0 * math.pi / radialSegments;
      final centerOnRing = Vector3(majorRadius * math.cos(u), majorRadius * math.sin(u), 0.0);

      for (int i = 0; i <= tubularSegments; i++) {
        final v = i * 2.0 * math.pi / tubularSegments;
        final normal = Vector3(
          math.cos(u) * math.cos(v),
          math.sin(u) * math.cos(v),
          math.sin(v),
        );

        final p = centerOnRing + normal * minorRadius;
        verts.add(p);
        normals.add(normal);
        uvs.add(Vector2(j / radialSegments, i / tubularSegments));
      }
    }

    for (int j = 0; j < radialSegments; j++) {
      for (int i = 0; i < tubularSegments; i++) {
        final a = (tubularSegments + 1) * j + i;
        final b = (tubularSegments + 1) * (j + 1) + i;
        final c = (tubularSegments + 1) * (j + 1) + i + 1;
        final d = (tubularSegments + 1) * j + i + 1;

        indices.addAll([a, b, d]);
        indices.addAll([b, c, d]);
      }
    }

    final maxExtent = majorRadius + minorRadius;
    final minVec = Vector3(-maxExtent, -maxExtent, -minorRadius);
    final maxVec = Vector3(maxExtent, maxExtent, minorRadius);

    return GlbMeshPrimitive(
      name: name,
      vertices: verts,
      normals: normals,
      uvs: uvs,
      indices: indices,
      material: mat,
      boundingBox: Aabb3.minMax(minVec, maxVec),
    );
  }

  GlbMeshPrimitive _buildDiskPrimitive(
    String name,
    double innerRadius,
    double outerRadius,
    int segments,
    GlbMaterialData mat,
  ) {
    final verts = <Vector3>[];
    final normals = <Vector3>[];
    final uvs = <Vector2>[];
    final indices = <int>[];

    for (int i = 0; i <= segments; i++) {
      final angle = i * 2.0 * math.pi / segments;
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);

      // Wierzchołek wewnętrzny
      verts.add(Vector3(innerRadius * cosA, innerRadius * sinA, 0.0));
      normals.add(Vector3(0.0, 0.0, 1.0));
      uvs.add(Vector2(0.5 + 0.5 * cosA * (innerRadius / outerRadius), 0.5 + 0.5 * sinA * (innerRadius / outerRadius)));

      // Wierzchołek zewnętrzny
      verts.add(Vector3(outerRadius * cosA, outerRadius * sinA, 0.0));
      normals.add(Vector3(0.0, 0.0, 1.0));
      uvs.add(Vector2(0.5 + 0.5 * cosA, 0.5 + 0.5 * sinA));
    }

    for (int i = 0; i < segments; i++) {
      final i0 = i * 2;
      final o0 = i * 2 + 1;
      final i1 = (i + 1) * 2;
      final o1 = (i + 1) * 2 + 1;

      indices.addAll([i0, o0, i1]);
      indices.addAll([i1, o0, o1]);
    }

    final minVec = Vector3(-outerRadius, -outerRadius, -0.01);
    final maxVec = Vector3(outerRadius, outerRadius, 0.01);

    return GlbMeshPrimitive(
      name: name,
      vertices: verts,
      normals: normals,
      uvs: uvs,
      indices: indices,
      material: mat,
      boundingBox: Aabb3.minMax(minVec, maxVec),
    );
  }
}

/// Provider Riverpoda dostarczający instancję serwisu ładowania modeli 3D.
final glbAssetLoaderServiceProvider = Provider<GlbAssetLoaderService>((ref) {
  return GlbAssetLoaderService.instance;
});
