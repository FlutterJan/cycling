// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Kanał tekstury PBR w atlasie pamięciowym.
enum PbrTextureChannel {
  /// Kolor bazowy (RGBA8888).
  albedo,

  /// Mapa normalnych w przestrzeni stycznej (tangent-space RGB + A=255).
  normal,

  /// Spakowana mapa ORM: R=Ambient Occlusion, G=Roughness, B=Metallic, A=Height.
  orm,
}

/// Rodzaj proceduralnie generowanego materiału PBR.
enum PbrMaterialType {
  /// Splot włókna węglowego 3K (2x2 diagonal twill weave).
  carbon3kTwill,

  /// Włókno węglowe jednokierunkowe (UD — Unidirectional).
  carbonUd,

  /// Metaliczny lakier ramy rowerowej z mikro-płatkami i lakierem bezbarwnym.
  metallicFramePaint,

  /// Bieżnik opony szosowej/gravelowej z kremowym bokiem (Tan-Wall).
  tanWallTireTread,

  /// Nawierzchnia asfaltowa z kruszywem mineralnym i spoiwem bitumicznym.
  roadAsphalt,
}

/// Presety rozdzielczości pojedynczego kafelka w atlasie PBR.
enum PbrAtlasTileResolution {
  /// 64x64 px na kafelek — tryb ultra-lekki / testy jednostkowe.
  micro(64),

  /// 128x128 px na kafelek — tryb wydajnościowy mobile.
  compact(128),

  /// 256x256 px na kafelek — domyślna jakość wyścigu 3D.
  standard(256),

  /// 512x512 px na kafelek — wysoka jakość garażu i zbliżeń.
  high(512);

  final int pixels;
  const PbrAtlasTileResolution(this.pixels);
}

/// Specyfikacja pojedynczego materiału umieszczanego w atlasie PBR.
class PbrMaterialSpec {
  final String id;
  final PbrMaterialType type;
  final Color primaryColor;
  final Color secondaryColor;
  final double metallicFlakeDensity;
  final double clearcoatRoughness;
  final double weaveScale;
  final double treadDepth;
  final double asphaltAggregateScale;
  final int seed;

  const PbrMaterialSpec({
    required this.id,
    required this.type,
    this.primaryColor = const Color(0xFF8E4A49),
    this.secondaryColor = const Color(0xFF181B22),
    this.metallicFlakeDensity = 0.65,
    this.clearcoatRoughness = 0.18,
    this.weaveScale = 1.0,
    this.treadDepth = 0.85,
    this.asphaltAggregateScale = 1.0,
    this.seed = 198,
  });

  factory PbrMaterialSpec.carbon3kDefault({String id = 'carbon_3k', int seed = 101}) {
    return PbrMaterialSpec(
      id: id,
      type: PbrMaterialType.carbon3kTwill,
      primaryColor: const Color(0xFF232832),
      secondaryColor: const Color(0xFF111318),
      clearcoatRoughness: 0.22,
      weaveScale: 1.0,
      seed: seed,
    );
  }

  factory PbrMaterialSpec.carbonUdDefault({String id = 'carbon_ud', int seed = 202}) {
    return PbrMaterialSpec(
      id: id,
      type: PbrMaterialType.carbonUd,
      primaryColor: const Color(0xFF1B1F27),
      secondaryColor: const Color(0xFF0E1014),
      clearcoatRoughness: 0.36,
      weaveScale: 1.0,
      seed: seed,
    );
  }

  factory PbrMaterialSpec.metallicPaint({
    String id = 'frame_metallic_burgundy',
    Color primaryColor = AppColors.primaryAccent,
    Color secondaryColor = const Color(0xFF3E191A),
    double flakeDensity = 0.72,
    double clearcoatRoughness = 0.14,
    int seed = 303,
  }) {
    return PbrMaterialSpec(
      id: id,
      type: PbrMaterialType.metallicFramePaint,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      metallicFlakeDensity: flakeDensity,
      clearcoatRoughness: clearcoatRoughness,
      seed: seed,
    );
  }

  factory PbrMaterialSpec.tanWallTireDefault({
    String id = 'tire_tan_wall',
    Color treadColor = const Color(0xFF181A1F),
    Color tanWallColor = const Color(0xFFD6B588),
    double treadDepth = 0.88,
    int seed = 404,
  }) {
    return PbrMaterialSpec(
      id: id,
      type: PbrMaterialType.tanWallTireTread,
      primaryColor: treadColor,
      secondaryColor: tanWallColor,
      treadDepth: treadDepth,
      seed: seed,
    );
  }

  factory PbrMaterialSpec.asphaltDefault({
    String id = 'road_asphalt',
    Color bitumenColor = const Color(0xFF1D2026),
    Color aggregateColor = const Color(0xFF474E5C),
    double aggregateScale = 1.0,
    int seed = 505,
  }) {
    return PbrMaterialSpec(
      id: id,
      type: PbrMaterialType.roadAsphalt,
      primaryColor: bitumenColor,
      secondaryColor: aggregateColor,
      asphaltAggregateScale: aggregateScale,
      seed: seed,
    );
  }

  String get cacheSignature {
    return '$id|${type.name}|${primaryColor.toARGB32()}|${secondaryColor.toARGB32()}|'
        '${metallicFlakeDensity.toStringAsFixed(2)}|${clearcoatRoughness.toStringAsFixed(2)}|'
        '${weaveScale.toStringAsFixed(2)}|${treadDepth.toStringAsFixed(2)}|'
        '${asphaltAggregateScale.toStringAsFixed(2)}|$seed';
  }
}

/// Znormalizowany obszar UV i współrzędne pikselowe kafelka w atlasie PBR.
class PbrUvRegion {
  final String materialId;
  final PbrMaterialType type;
  final int slotIndex;
  final int pixelX;
  final int pixelY;
  final int tileSize;
  final double u0;
  final double v0;
  final double u1;
  final double v1;

  const PbrUvRegion({
    required this.materialId,
    required this.type,
    required this.slotIndex,
    required this.pixelX,
    required this.pixelY,
    required this.tileSize,
    required this.u0,
    required this.v0,
    required this.u1,
    required this.v1,
  });

  Rect get pixelRect => Rect.fromLTWH(
        pixelX.toDouble(),
        pixelY.toDouble(),
        tileSize.toDouble(),
        tileSize.toDouble(),
      );

  /// Przelicza lokalne współrzędne UV [0..1] materiału (z zawijaniem) na globalne UV atlasu.
  Offset mapLocalUv(double u, double v) {
    final double wrappedU = u - u.floorToDouble();
    final double wrappedV = v - v.floorToDouble();
    return Offset(
      u0 + wrappedU * (u1 - u0),
      v0 + wrappedV * (v1 - v0),
    );
  }
}

/// Zestaw buforów pikseli PBR (Albedo, Normal, ORM) wygenerowany wyłącznie w pamięci RAM.
class PbrTextureAtlasMaps {
  final int width;
  final int height;
  final int tileSize;
  final int columns;
  final int rows;
  final Uint8List albedoRgba;
  final Uint8List normalRgba;
  final Uint8List ormRgba;
  final Map<String, PbrUvRegion> regions;
  final int generationTimeMs;

  const PbrTextureAtlasMaps({
    required this.width,
    required this.height,
    required this.tileSize,
    required this.columns,
    required this.rows,
    required this.albedoRgba,
    required this.normalRgba,
    required this.ormRgba,
    required this.regions,
    required this.generationTimeMs,
  });

  /// Łączne zużycie pamięci RAM przez wszystkie trzy mapy kanałów (w bajtach).
  int get totalMemoryBytes => albedoRgba.lengthInBytes + normalRgba.lengthInBytes + ormRgba.lengthInBytes;

  /// Zwraca kolor piksela dla wskazanego kanału i współrzędnych (z bezpiecznym zawijaniem).
  Color samplePixel(PbrTextureChannel channel, int x, int y) {
    final Uint8List buffer = _bufferForChannel(channel);
    final int wx = ((x % width) + width) % width;
    final int wy = ((y % height) + height) % height;
    final int idx = (wy * width + wx) * 4;
    return Color.fromARGB(
      buffer[idx + 3],
      buffer[idx],
      buffer[idx + 1],
      buffer[idx + 2],
    );
  }

  /// Próbkuje materiał po lokalnych współrzędnych UV [0..1].
  Color sampleMaterialUv(String materialId, PbrTextureChannel channel, double u, double v) {
    final PbrUvRegion? region = regions[materialId];
    if (region == null) {
      return AppColors.background;
    }
    final double wu = u - u.floorToDouble();
    final double wv = v - v.floorToDouble();
    final int lx = (wu * (region.tileSize - 1)).round().clamp(0, region.tileSize - 1);
    final int ly = (wv * (region.tileSize - 1)).round().clamp(0, region.tileSize - 1);
    return samplePixel(channel, region.pixelX + lx, region.pixelY + ly);
  }

  Uint8List _bufferForChannel(PbrTextureChannel channel) {
    switch (channel) {
      case PbrTextureChannel.albedo:
        return albedoRgba;
      case PbrTextureChannel.normal:
        return normalRgba;
      case PbrTextureChannel.orm:
        return ormRgba;
    }
  }
}

/// Zdekodowane obrazy GPU (`ui.Image`) gotowe do użycia w `CustomPainter` i `ImageShader`.
class PbrGpuTextureAtlas {
  final PbrTextureAtlasMaps maps;
  final ui.Image albedoImage;
  final ui.Image normalImage;
  final ui.Image ormImage;
  bool _disposed = false;

  PbrGpuTextureAtlas({
    required this.maps,
    required this.albedoImage,
    required this.normalImage,
    required this.ormImage,
  });

  bool get isDisposed => _disposed;

  ui.Image imageForChannel(PbrTextureChannel channel) {
    switch (channel) {
      case PbrTextureChannel.albedo:
        return albedoImage;
      case PbrTextureChannel.normal:
        return normalImage;
      case PbrTextureChannel.orm:
        return ormImage;
    }
  }

  /// Tworzy powtarzalny lub przycięty `ui.ImageShader` dla wybranego kafelka w atlasie.
  ui.ImageShader createAtlasShader({
    PbrTextureChannel channel = PbrTextureChannel.albedo,
    ui.TileMode tileModeX = ui.TileMode.repeated,
    ui.TileMode tileModeY = ui.TileMode.repeated,
    Float64List? matrix4,
  }) {
    final Float64List m = matrix4 ?? Matrix4.identity().storage;
    return ui.ImageShader(
      imageForChannel(channel),
      tileModeX,
      tileModeY,
      m,
    );
  }

  /// Buduje `Paint` z przypisanym shaderem atlasu (np. do nakładania tekstury na wielokąty 3D).
  Paint createAtlasPaint({
    PbrTextureChannel channel = PbrTextureChannel.albedo,
    double scale = 1.0,
    FilterQuality filterQuality = FilterQuality.medium,
    BlendMode blendMode = BlendMode.srcOver,
  }) {
    final Matrix4 matrix = Matrix4.diagonal3Values(scale, scale, 1.0);
    return Paint()
      ..shader = createAtlasShader(
        channel: channel,
        matrix4: matrix.storage,
      )
      ..filterQuality = filterQuality
      ..blendMode = blendMode
      ..isAntiAlias = true;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    albedoImage.dispose();
    normalImage.dispose();
    ormImage.dispose();
  }
}

/// Generator proceduralnych atlasów tekstur PBR w pamięci RAM (zero plików PNG na dysku).
///
/// Generuje bezszwowe (seamless) mapy Albedo, Normal oraz spakowane ORM
/// (AO / Roughness / Metallic / Height) dla:
/// - splotu włókna węglowego 3K Twill (`carbon3kTwill`)
/// - włókna węglowego jednokierunkowego UD (`carbonUd`)
/// - metalicznego lakieru ram (`metallicFramePaint`)
/// - bieżnika opon z kremowym bokiem Tan-Wall (`tanWallTireTread`)
/// - faktury asfaltu drogowego (`roadAsphalt`)
class ProceduralPbrTextureAtlasGenerator {
  final Map<String, PbrTextureAtlasMaps> _mapsCache = <String, PbrTextureAtlasMaps>{};
  final Map<String, PbrGpuTextureAtlas> _gpuCache = <String, PbrGpuTextureAtlas>{};

  /// Domyślny zestaw 6 materiałów kolarskich gotowy do użycia w silniku 3D i garażu.
  static List<PbrMaterialSpec> defaultCyclingMaterials({
    Color teamFrameColor = AppColors.primaryAccent,
    Color teamSecondaryColor = const Color(0xFF3A1819),
  }) {
    return <PbrMaterialSpec>[
      PbrMaterialSpec.carbon3kDefault(),
      PbrMaterialSpec.carbonUdDefault(),
      PbrMaterialSpec.metallicPaint(
        id: 'frame_metallic_team',
        primaryColor: teamFrameColor,
        secondaryColor: teamSecondaryColor,
      ),
      PbrMaterialSpec.metallicPaint(
        id: 'frame_metallic_gold',
        primaryColor: AppColors.goldAccent,
        secondaryColor: const Color(0xFF6B5312),
        flakeDensity: 0.78,
        seed: 309,
      ),
      PbrMaterialSpec.tanWallTireDefault(),
      PbrMaterialSpec.asphaltDefault(),
    ];
  }

  /// Synchronicznie generuje bufory PBR w pamięci RAM (idealne także dla Isolate i testów).
  PbrTextureAtlasMaps generateAtlasMaps({
    List<PbrMaterialSpec>? materials,
    PbrAtlasTileResolution tileResolution = PbrAtlasTileResolution.standard,
    bool useCache = true,
  }) {
    final List<PbrMaterialSpec> specs =
        (materials == null || materials.isEmpty) ? defaultCyclingMaterials() : materials;
    final int tileSize = tileResolution.pixels;
    final String cacheKey = _buildCacheKey(specs, tileSize);

    if (useCache && _mapsCache.containsKey(cacheKey)) {
      return _mapsCache[cacheKey]!;
    }

    final Stopwatch sw = Stopwatch()..start();
    final int count = specs.length;
    final int columns = math.max(1, math.sqrt(count).ceil());
    final int rows = math.max(1, (count / columns).ceil());
    final int atlasWidth = columns * tileSize;
    final int atlasHeight = rows * tileSize;
    final int totalBytes = atlasWidth * atlasHeight * 4;

    final Uint8List albedo = Uint8List(totalBytes);
    final Uint8List normal = Uint8List(totalBytes);
    final Uint8List orm = Uint8List(totalBytes);
    final Map<String, PbrUvRegion> regions = <String, PbrUvRegion>{};

    // Bufor pomocniczy wysokości pojedynczego kafelka do bezszwowego obliczania normalnych.
    final Float32List tileHeights = Float32List(tileSize * tileSize);

    for (int i = 0; i < count; i++) {
      final PbrMaterialSpec spec = specs[i];
      final int col = i % columns;
      final int row = i ~/ columns;
      final int startX = col * tileSize;
      final int startY = row * tileSize;

      regions[spec.id] = PbrUvRegion(
        materialId: spec.id,
        type: spec.type,
        slotIndex: i,
        pixelX: startX,
        pixelY: startY,
        tileSize: tileSize,
        u0: startX / atlasWidth,
        v0: startY / atlasHeight,
        u1: (startX + tileSize) / atlasWidth,
        v1: (startY + tileSize) / atlasHeight,
      );

      _synthesizeMaterialTile(
        spec: spec,
        tileSize: tileSize,
        startX: startX,
        startY: startY,
        atlasWidth: atlasWidth,
        albedo: albedo,
        orm: orm,
        tileHeights: tileHeights,
      );

      _computeSeamlessNormalsFromHeight(
        tileHeights: tileHeights,
        tileSize: tileSize,
        startX: startX,
        startY: startY,
        atlasWidth: atlasWidth,
        normal: normal,
        strength: _normalStrengthForMaterial(spec.type),
      );
    }

    sw.stop();
    final PbrTextureAtlasMaps maps = PbrTextureAtlasMaps(
      width: atlasWidth,
      height: atlasHeight,
      tileSize: tileSize,
      columns: columns,
      rows: rows,
      albedoRgba: albedo,
      normalRgba: normal,
      ormRgba: orm,
      regions: Map<String, PbrUvRegion>.unmodifiable(regions),
      generationTimeMs: sw.elapsedMilliseconds,
    );

    if (useCache) {
      _mapsCache[cacheKey] = maps;
    }
    return maps;
  }

  /// Generuje bufory w RAM i dekoduje je bezpośrednio do obiektów GPU `ui.Image` bez zapisu na dysk.
  Future<PbrGpuTextureAtlas> buildGpuAtlas({
    List<PbrMaterialSpec>? materials,
    PbrAtlasTileResolution tileResolution = PbrAtlasTileResolution.standard,
    bool useCache = true,
  }) async {
    final List<PbrMaterialSpec> specs =
        (materials == null || materials.isEmpty) ? defaultCyclingMaterials() : materials;
    final String cacheKey = _buildCacheKey(specs, tileResolution.pixels);

    if (useCache) {
      final PbrGpuTextureAtlas? cached = _gpuCache[cacheKey];
      if (cached != null && !cached.isDisposed) {
        return cached;
      }
    }

    final PbrTextureAtlasMaps maps = generateAtlasMaps(
      materials: specs,
      tileResolution: tileResolution,
      useCache: useCache,
    );

    final List<ui.Image> images = await Future.wait<ui.Image>(<Future<ui.Image>>[
      _decodeRgbaToImage(maps.albedoRgba, maps.width, maps.height),
      _decodeRgbaToImage(maps.normalRgba, maps.width, maps.height),
      _decodeRgbaToImage(maps.ormRgba, maps.width, maps.height),
    ]);

    final PbrGpuTextureAtlas gpuAtlas = PbrGpuTextureAtlas(
      maps: maps,
      albedoImage: images[0],
      normalImage: images[1],
      ormImage: images[2],
    );

    if (useCache) {
      _gpuCache[cacheKey] = gpuAtlas;
    }
    return gpuAtlas;
  }

  void clearCache() {
    _mapsCache.clear();
    for (final PbrGpuTextureAtlas atlas in _gpuCache.values) {
      atlas.dispose();
    }
    _gpuCache.clear();
  }

  String _buildCacheKey(List<PbrMaterialSpec> specs, int tileSize) {
    final StringBuffer sb = StringBuffer('$tileSize::');
    for (final PbrMaterialSpec spec in specs) {
      sb.write(spec.cacheSignature);
      sb.write(';');
    }
    return sb.toString();
  }

  Future<ui.Image> _decodeRgbaToImage(Uint8List rgba, int width, int height) {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (ui.Image image) {
        if (!completer.isCompleted) {
          completer.complete(image);
        }
      },
    );
    return completer.future;
  }

  double _normalStrengthForMaterial(PbrMaterialType type) {
    switch (type) {
      case PbrMaterialType.carbon3kTwill:
        return 2.6;
      case PbrMaterialType.carbonUd:
        return 1.35;
      case PbrMaterialType.metallicFramePaint:
        return 0.85;
      case PbrMaterialType.tanWallTireTread:
        return 3.4;
      case PbrMaterialType.roadAsphalt:
        return 3.1;
    }
  }

  void _synthesizeMaterialTile({
    required PbrMaterialSpec spec,
    required int tileSize,
    required int startX,
    required int startY,
    required int atlasWidth,
    required Uint8List albedo,
    required Uint8List orm,
    required Float32List tileHeights,
  }) {
    switch (spec.type) {
      case PbrMaterialType.carbon3kTwill:
        _generateCarbon3kTile(spec, tileSize, startX, startY, atlasWidth, albedo, orm, tileHeights);
      case PbrMaterialType.carbonUd:
        _generateCarbonUdTile(spec, tileSize, startX, startY, atlasWidth, albedo, orm, tileHeights);
      case PbrMaterialType.metallicFramePaint:
        _generateMetallicPaintTile(spec, tileSize, startX, startY, atlasWidth, albedo, orm, tileHeights);
      case PbrMaterialType.tanWallTireTread:
        _generateTanWallTireTile(spec, tileSize, startX, startY, atlasWidth, albedo, orm, tileHeights);
      case PbrMaterialType.roadAsphalt:
        _generateAsphaltTile(spec, tileSize, startX, startY, atlasWidth, albedo, orm, tileHeights);
    }
  }

  /// 1. Splot włókna węglowego 3K (2x2 diagonal twill weave).
  void _generateCarbon3kTile(
    PbrMaterialSpec spec,
    int tileSize,
    int startX,
    int startY,
    int atlasWidth,
    Uint8List albedo,
    Uint8List orm,
    Float32List tileHeights,
  ) {
    final double baseR = ((spec.primaryColor.r * 255.0).round()).toDouble();
    final double baseG = ((spec.primaryColor.g * 255.0).round()).toDouble();
    final double baseB = ((spec.primaryColor.b * 255.0).round()).toDouble();
    final double darkR = ((spec.secondaryColor.r * 255.0).round()).toDouble();
    final double darkG = ((spec.secondaryColor.g * 255.0).round()).toDouble();
    final double darkB = ((spec.secondaryColor.b * 255.0).round()).toDouble();

    final double cellFrequency = 8.0 * spec.weaveScale.clamp(0.5, 4.0);

    for (int y = 0; y < tileSize; y++) {
      final double v = y / tileSize;
      final double gy = v * cellFrequency;
      final int iy = gy.floor();
      final double fy = gy - iy;

      for (int x = 0; x < tileSize; x++) {
        final double u = x / tileSize;
        final double gx = u * cellFrequency;
        final int ix = gx.floor();
        final double fx = gx - ix;

        // Splot ukośny 2x2 twill: przesunięcie o 1 na każdy rząd.
        final bool isWarp = ((ix + iy) & 3) < 2;

        // Profil przekroju wiązki włókien + mikro-włókna wzdłużne.
        final double crossProfile = isWarp ? math.sin(fy * math.pi) : math.sin(fx * math.pi);
        final double longitudinalStrand = isWarp
            ? 0.5 + 0.5 * math.sin(fy * math.pi * 10.0 + _hash01(ix, iy, spec.seed) * 3.14)
            : 0.5 + 0.5 * math.sin(fx * math.pi * 10.0 + _hash01(iy, ix, spec.seed) * 3.14);

        final double crown = (0.68 * crossProfile + 0.32 * longitudinalStrand * crossProfile).clamp(0.0, 1.0);
        // Wyróżnienie kierunku wątku/osnowy (anizotropia odbicia światła).
        final double sheen = isWarp ? 0.88 + 0.12 * crown : 0.65 + 0.20 * crown;
        final double shade = (crown * sheen).clamp(0.0, 1.0);

        final double height = 0.25 + 0.75 * crown;
        tileHeights[y * tileSize + x] = height;

        final int r = _lerpChannel(darkR, baseR * 1.35, shade);
        final int g = _lerpChannel(darkG, baseG * 1.35, shade);
        final int b = _lerpChannel(darkB, baseB * 1.38, shade);

        final double roughness = (spec.clearcoatRoughness + (1.0 - crown) * 0.26).clamp(0.08, 0.85);
        final double metallic = (0.14 + 0.14 * crown).clamp(0.0, 1.0);
        final double ao = (0.45 + 0.55 * crossProfile).clamp(0.0, 1.0);

        _writePixel(
          albedo: albedo,
          orm: orm,
          atlasOffset: ((startY + y) * atlasWidth + (startX + x)) * 4,
          r: r,
          g: g,
          b: b,
          ao: ao,
          roughness: roughness,
          metallic: metallic,
          height: height,
        );
      }
    }
  }

  /// 2. Włókno węglowe jednokierunkowe (UD — Unidirectional).
  void _generateCarbonUdTile(
    PbrMaterialSpec spec,
    int tileSize,
    int startX,
    int startY,
    int atlasWidth,
    Uint8List albedo,
    Uint8List orm,
    Float32List tileHeights,
  ) {
    final double baseR = ((spec.primaryColor.r * 255.0).round()).toDouble();
    final double baseG = ((spec.primaryColor.g * 255.0).round()).toDouble();
    final double baseB = ((spec.primaryColor.b * 255.0).round()).toDouble();
    final double darkR = ((spec.secondaryColor.r * 255.0).round()).toDouble();
    final double darkG = ((spec.secondaryColor.g * 255.0).round()).toDouble();
    final double darkB = ((spec.secondaryColor.b * 255.0).round()).toDouble();

    final int period = math.max(8, tileSize);

    for (int y = 0; y < tileSize; y++) {
      final double v = y / tileSize;
      // Pasmowanie jednokierunkowych włókien wzdłuż osi U.
      final double filamentFine = _periodicNoise(v * 64.0, 0.0, 64, 64, spec.seed);
      final double filamentBroad = _periodicNoise(v * 12.0, 0.0, 12, 12, spec.seed + 17);

      for (int x = 0; x < tileSize; x++) {
        final double u = x / tileSize;
        final double microGrain = _periodicNoise(u * 8.0, v * 48.0, 8, 48, spec.seed + 31);
        final double plyWave = 0.5 + 0.5 * math.sin((u * 2.0 + v * 0.25) * math.pi * 2.0);
        final double fiberIntensity =
            (0.45 * filamentFine + 0.35 * filamentBroad + 0.20 * microGrain).clamp(0.0, 1.0);

        final double height = (0.38 + 0.42 * fiberIntensity + 0.20 * plyWave).clamp(0.0, 1.0);
        tileHeights[y * tileSize + x] = height;

        final double shade = (0.25 + 0.65 * fiberIntensity + 0.10 * plyWave).clamp(0.0, 1.0);
        final int r = _lerpChannel(darkR, baseR * 1.25, shade);
        final int g = _lerpChannel(darkG, baseG * 1.25, shade);
        final int b = _lerpChannel(darkB, baseB * 1.30, shade);

        final double roughness = (spec.clearcoatRoughness + (1.0 - fiberIntensity) * 0.18).clamp(0.15, 0.85);
        final double metallic = (0.08 + 0.10 * fiberIntensity).clamp(0.0, 1.0);
        final double ao = (0.65 + 0.35 * fiberIntensity).clamp(0.0, 1.0);

        // Zapewnienie nieużytego ostrzeżenia dla period w trybach debug.
        assert(period > 0);

        _writePixel(
          albedo: albedo,
          orm: orm,
          atlasOffset: ((startY + y) * atlasWidth + (startX + x)) * 4,
          r: r,
          g: g,
          b: b,
          ao: ao,
          roughness: roughness,
          metallic: metallic,
          height: height,
        );
      }
    }
  }

  /// 3. Metaliczny lakier ramy rowerowej z mikro-płatkami i lakierem bezbarwnym.
  void _generateMetallicPaintTile(
    PbrMaterialSpec spec,
    int tileSize,
    int startX,
    int startY,
    int atlasWidth,
    Uint8List albedo,
    Uint8List orm,
    Float32List tileHeights,
  ) {
    final double pR = (spec.primaryColor.r * 255.0);
    final double pG = (spec.primaryColor.g * 255.0);
    final double pB = (spec.primaryColor.b * 255.0);
    final double sR = (spec.secondaryColor.r * 255.0);
    final double sG = (spec.secondaryColor.g * 255.0);
    final double sB = (spec.secondaryColor.b * 255.0);

    final double flakeThreshold = 1.0 - (0.35 * spec.metallicFlakeDensity.clamp(0.0, 1.0));

    for (int y = 0; y < tileSize; y++) {
      final double v = y / tileSize;
      for (int x = 0; x < tileSize; x++) {
        final double u = x / tileSize;

        // Delikatny perłowy gradient pod lakierem.
        final double coatWave = _periodicNoise(u * 4.0, v * 4.0, 4, 4, spec.seed);
        // Mikro-płatki metaliczne (wysoka częstotliwość).
        final double flakeRand = _hash01(x, y, spec.seed + 79);
        final double flakeNeighbor = _hash01((x + 1) % tileSize, y, spec.seed + 79);
        final bool isSparkleFlake = flakeRand > flakeThreshold;
        final double flakeBoost = isSparkleFlake
            ? ((flakeRand - flakeThreshold) / (1.0 - flakeThreshold + 1e-6)).clamp(0.0, 1.0)
            : 0.0;

        final double baseMix = (0.35 + 0.50 * coatWave + 0.15 * flakeNeighbor).clamp(0.0, 1.0);
        int r = _lerpChannel(sR, pR, baseMix);
        int g = _lerpChannel(sG, pG, baseMix);
        int b = _lerpChannel(sB, pB, baseMix);

        if (isSparkleFlake) {
          r = (r + (255 - r) * flakeBoost * 0.42).round().clamp(0, 255);
          g = (g + (255 - g) * flakeBoost * 0.42).round().clamp(0, 255);
          b = (b + (255 - b) * flakeBoost * 0.42).round().clamp(0, 255);
        }

        final double height = (0.50 + 0.10 * coatWave + 0.35 * flakeBoost).clamp(0.0, 1.0);
        tileHeights[y * tileSize + x] = height;

        final double roughness = (spec.clearcoatRoughness + (1.0 - flakeBoost) * 0.08).clamp(0.06, 0.55);
        final double metallic = (0.68 + 0.30 * flakeBoost).clamp(0.0, 1.0);
        final double ao = (0.85 + 0.15 * coatWave).clamp(0.0, 1.0);

        _writePixel(
          albedo: albedo,
          orm: orm,
          atlasOffset: ((startY + y) * atlasWidth + (startX + x)) * 4,
          r: r,
          g: g,
          b: b,
          ao: ao,
          roughness: roughness,
          metallic: metallic,
          height: height,
        );
      }
    }
  }

  /// 4. Bieżnik opon szosowych/gravelowych z kremowym bokiem (Tan-Wall).
  void _generateTanWallTireTile(
    PbrMaterialSpec spec,
    int tileSize,
    int startX,
    int startY,
    int atlasWidth,
    Uint8List albedo,
    Uint8List orm,
    Float32List tileHeights,
  ) {
    final double rubberR = (spec.primaryColor.r * 255.0);
    final double rubberG = (spec.primaryColor.g * 255.0);
    final double rubberB = (spec.primaryColor.b * 255.0);
    final double tanR = (spec.secondaryColor.r * 255.0);
    final double tanG = (spec.secondaryColor.g * 255.0);
    final double tanB = (spec.secondaryColor.b * 255.0);

    final double depth = spec.treadDepth.clamp(0.2, 1.0);

    for (int y = 0; y < tileSize; y++) {
      // V = 0.5 to środek bieżnika; V < 0.24 oraz V > 0.76 to kremowy bok Tan-Wall.
      final double v = y / tileSize;
      final double distFromCenter = (v - 0.5).abs() * 2.0; // 0 na środku, 1 na krawędzi

      for (int x = 0; x < tileSize; x++) {
        final double u = x / tileSize;
        final double microGrain = _periodicNoise(u * 32.0, v * 32.0, 32, 32, spec.seed);

        int r;
        int g;
        int b;
        double height;
        double roughness;
        double ao;

        if (distFromCenter <= 0.52) {
          // Strefa czarnego bieżnika gumowego (jodełka + centralny pas).
          final double chevronPhase = (u * 10.0 - distFromCenter * 3.2) % 1.0;
          final double grooveMask = (distFromCenter > 0.14 && chevronPhase < 0.28) ? 0.0 : 1.0;
          final double centerRib = distFromCenter <= 0.12 ? 1.0 : grooveMask;

          height = (0.18 + 0.78 * centerRib * depth + 0.04 * microGrain).clamp(0.0, 1.0);
          final double shade = (0.55 + 0.45 * centerRib + 0.15 * microGrain).clamp(0.0, 1.0);
          r = (rubberR * shade).round().clamp(0, 255);
          g = (rubberG * shade).round().clamp(0, 255);
          b = (rubberB * shade).round().clamp(0, 255);
          roughness = (0.72 + (1.0 - centerRib) * 0.16).clamp(0.5, 0.96);
          ao = (0.45 + 0.55 * centerRib).clamp(0.0, 1.0);
        } else if (distFromCenter <= 0.60) {
          // Przejście guma -> oplot bawełniany (bark opony).
          final double t = (distFromCenter - 0.52) / 0.08;
          final double lip = math.sin(t * math.pi);
          height = (0.35 + 0.35 * lip + 0.05 * microGrain).clamp(0.0, 1.0);
          r = _lerpChannel(rubberR, tanR * 0.82, t);
          g = _lerpChannel(rubberG, tanG * 0.82, t);
          b = _lerpChannel(rubberB, tanB * 0.82, t);
          roughness = 0.76;
          ao = 0.72;
        } else {
          // Kremowy bok Tan-Wall z diagonalnym splotem bawełnianego oplotu (45°).
          final double cordA = 0.5 + 0.5 * math.sin((u * 28.0 + v * 28.0) * math.pi * 2.0);
          final double cordB = 0.5 + 0.5 * math.sin((u * 28.0 - v * 28.0) * math.pi * 2.0);
          final double casing = (0.60 * cordA + 0.40 * cordB);
          final double beadDarken = distFromCenter > 0.92 ? (distFromCenter - 0.92) / 0.08 * 0.35 : 0.0;

          height = (0.40 + 0.28 * casing + 0.06 * microGrain).clamp(0.0, 1.0);
          final double tanShade = (0.82 + 0.18 * casing - beadDarken).clamp(0.35, 1.05);
          r = (tanR * tanShade).round().clamp(0, 255);
          g = (tanG * tanShade).round().clamp(0, 255);
          b = (tanB * tanShade).round().clamp(0, 255);
          roughness = (0.64 + 0.14 * (1.0 - casing)).clamp(0.45, 0.90);
          ao = (0.75 + 0.25 * casing - beadDarken * 0.4).clamp(0.0, 1.0);
        }

        tileHeights[y * tileSize + x] = height;
        _writePixel(
          albedo: albedo,
          orm: orm,
          atlasOffset: ((startY + y) * atlasWidth + (startX + x)) * 4,
          r: r,
          g: g,
          b: b,
          ao: ao,
          roughness: roughness,
          metallic: 0.02,
          height: height,
        );
      }
    }
  }

  /// 5. Faktura asfaltu drogowego z kruszywem mineralnym i porami bitumicznymi.
  void _generateAsphaltTile(
    PbrMaterialSpec spec,
    int tileSize,
    int startX,
    int startY,
    int atlasWidth,
    Uint8List albedo,
    Uint8List orm,
    Float32List tileHeights,
  ) {
    final double bitR = (spec.primaryColor.r * 255.0);
    final double bitG = (spec.primaryColor.g * 255.0);
    final double bitB = (spec.primaryColor.b * 255.0);
    final double aggR = (spec.secondaryColor.r * 255.0);
    final double aggG = (spec.secondaryColor.g * 255.0);
    final double aggB = (spec.secondaryColor.b * 255.0);

    final double aggScale = spec.asphaltAggregateScale.clamp(0.5, 2.5);
    final int coarseFreq = (12 * aggScale).round().clamp(6, 32);
    final int fineFreq = (32 * aggScale).round().clamp(16, 64);

    for (int y = 0; y < tileSize; y++) {
      final double v = y / tileSize;
      for (int x = 0; x < tileSize; x++) {
        final double u = x / tileSize;

        final double macroNoise = _periodicNoise(u * 4.0, v * 4.0, 4, 4, spec.seed);
        final double coarseAgg = _periodicNoise(
          u * coarseFreq,
          v * coarseFreq,
          coarseFreq,
          coarseFreq,
          spec.seed + 11,
        );
        final double fineAgg = _periodicNoise(
          u * fineFreq,
          v * fineFreq,
          fineFreq,
          fineFreq,
          spec.seed + 29,
        );
        final double mineralSpeck = _hash01(x, y, spec.seed + 53);

        // Kamyki kruszywa wystają powyżej spoiwa bitumicznego.
        final double stoneMask = ((coarseAgg * 0.65 + fineAgg * 0.35) > 0.56) ? 1.0 : 0.0;
        final double micaGlint = (stoneMask > 0.5 && mineralSpeck > 0.90) ? 1.0 : 0.0;

        final double height =
            (0.22 * macroNoise + 0.45 * coarseAgg + 0.25 * fineAgg + 0.08 * mineralSpeck).clamp(0.0, 1.0);
        tileHeights[y * tileSize + x] = height;

        final double mixFactor = (0.20 * macroNoise + 0.55 * stoneMask * coarseAgg + 0.25 * fineAgg).clamp(0.0, 1.0);
        int r = _lerpChannel(bitR, aggR, mixFactor);
        int g = _lerpChannel(bitG, aggG, mixFactor);
        int b = _lerpChannel(bitB, aggB, mixFactor);

        if (micaGlint > 0.5) {
          r = (r + 34).clamp(0, 255);
          g = (g + 34).clamp(0, 255);
          b = (b + 38).clamp(0, 255);
        }

        final double roughness = (0.76 + (1.0 - stoneMask) * 0.16 - micaGlint * 0.15).clamp(0.45, 0.96);
        final double metallic = micaGlint > 0.5 ? 0.18 : 0.03;
        final double ao = (0.48 + 0.52 * height).clamp(0.0, 1.0);

        _writePixel(
          albedo: albedo,
          orm: orm,
          atlasOffset: ((startY + y) * atlasWidth + (startX + x)) * 4,
          r: r,
          g: g,
          b: b,
          ao: ao,
          roughness: roughness,
          metallic: metallic,
          height: height,
        );
      }
    }
  }

  /// Oblicza bezszwowe normalne w przestrzeni stycznej z bufora wysokości metodą różnic centralnych.
  void _computeSeamlessNormalsFromHeight({
    required Float32List tileHeights,
    required int tileSize,
    required int startX,
    required int startY,
    required int atlasWidth,
    required Uint8List normal,
    required double strength,
  }) {
    for (int y = 0; y < tileSize; y++) {
      final int yPrev = (y - 1 + tileSize) % tileSize;
      final int yNext = (y + 1) % tileSize;

      for (int x = 0; x < tileSize; x++) {
        final int xPrev = (x - 1 + tileSize) % tileSize;
        final int xNext = (x + 1) % tileSize;

        final double hL = tileHeights[y * tileSize + xPrev];
        final double hR = tileHeights[y * tileSize + xNext];
        final double hU = tileHeights[yPrev * tileSize + x];
        final double hD = tileHeights[yNext * tileSize + x];

        final double dx = (hL - hR) * strength;
        final double dy = (hU - hD) * strength;
        const double dz = 1.0;

        final double invLen = 1.0 / math.sqrt(dx * dx + dy * dy + dz * dz);
        final int nx = (((dx * invLen) * 0.5 + 0.5) * 255.0).round().clamp(0, 255);
        final int ny = (((dy * invLen) * 0.5 + 0.5) * 255.0).round().clamp(0, 255);
        final int nz = (((dz * invLen) * 0.5 + 0.5) * 255.0).round().clamp(0, 255);

        final int offset = ((startY + y) * atlasWidth + (startX + x)) * 4;
        normal[offset] = nx;
        normal[offset + 1] = ny;
        normal[offset + 2] = nz;
        normal[offset + 3] = 255;
      }
    }
  }

  void _writePixel({
    required Uint8List albedo,
    required Uint8List orm,
    required int atlasOffset,
    required int r,
    required int g,
    required int b,
    required double ao,
    required double roughness,
    required double metallic,
    required double height,
  }) {
    albedo[atlasOffset] = r;
    albedo[atlasOffset + 1] = g;
    albedo[atlasOffset + 2] = b;
    albedo[atlasOffset + 3] = 255;

    orm[atlasOffset] = (ao * 255.0).round().clamp(0, 255);
    orm[atlasOffset + 1] = (roughness * 255.0).round().clamp(0, 255);
    orm[atlasOffset + 2] = (metallic * 255.0).round().clamp(0, 255);
    orm[atlasOffset + 3] = (height * 255.0).round().clamp(0, 255);
  }

  int _lerpChannel(double a, double b, double t) {
    return (a + (b - a) * t).round().clamp(0, 255);
  }

  /// Deterministyczny bezszwowy szum wartościowy (seamless periodic value noise).
  double _periodicNoise(double x, double y, int periodX, int periodY, int seed) {
    final int x0 = x.floor();
    final int y0 = y.floor();
    final double fx = x - x0;
    final double fy = y - y0;

    final int ix0 = ((x0 % periodX) + periodX) % periodX;
    final int iy0 = ((y0 % periodY) + periodY) % periodY;
    final int ix1 = (ix0 + 1) % periodX;
    final int iy1 = (iy0 + 1) % periodY;

    final double sx = fx * fx * (3.0 - 2.0 * fx);
    final double sy = fy * fy * (3.0 - 2.0 * fy);

    final double n00 = _hash01(ix0, iy0, seed);
    final double n10 = _hash01(ix1, iy0, seed);
    final double n01 = _hash01(ix0, iy1, seed);
    final double n11 = _hash01(ix1, iy1, seed);

    final double nx0 = n00 + (n10 - n00) * sx;
    final double nx1 = n01 + (n11 - n01) * sx;
    return nx0 + (nx1 - nx0) * sy;
  }

  double _hash01(int x, int y, int seed) {
    int h = (x * 374761393 + y * 668265263 + seed * 1442695041) & 0x7fffffff;
    h = (h ^ (h >> 13)) * 1274126177;
    h = (h ^ (h >> 16)) & 0x7fffffff;
    return h / 0x7fffffff;
  }
}

/// Interaktywny panel podglądu i diagnostyki wygenerowanego atlasu PBR w pamięci.
class PbrTextureAtlasInspectorPanel extends StatefulWidget {
  final ProceduralPbrTextureAtlasGenerator generator;
  final List<PbrMaterialSpec>? materials;
  final PbrAtlasTileResolution initialResolution;
  final bool enabled;

  const PbrTextureAtlasInspectorPanel({
    super.key,
    required this.generator,
    this.materials,
    this.initialResolution = PbrAtlasTileResolution.compact,
    this.enabled = true,
  });

  @override
  State<PbrTextureAtlasInspectorPanel> createState() => _PbrTextureAtlasInspectorPanelState();
}

class _PbrTextureAtlasInspectorPanelState extends State<PbrTextureAtlasInspectorPanel> {
  PbrGpuTextureAtlas? _gpuAtlas;
  PbrTextureChannel _selectedChannel = PbrTextureChannel.albedo;
  String? _selectedMaterialId;
  bool _isLoading = true;
  bool _tiledPreview = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _rebuildAtlas();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _rebuildAtlas({bool bypassCache = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final PbrGpuTextureAtlas atlas = await widget.generator.buildGpuAtlas(
        materials: widget.materials,
        tileResolution: widget.initialResolution,
        useCache: !bypassCache,
      );
      if (!mounted) return;
      setState(() {
        _gpuAtlas = atlas;
        _selectedMaterialId ??= atlas.maps.regions.keys.isNotEmpty ? atlas.maps.regions.keys.first : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isCompact = constraints.maxWidth < 520;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildHeader(isCompact),
                const SizedBox(height: 12),
                _buildChannelSelector(),
                const SizedBox(height: 12),
                if (isCompact) ...<Widget>[
                  _buildPreviewViewport(height: 200),
                  const SizedBox(height: 12),
                  _buildMaterialList(),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(flex: 3, child: _buildPreviewViewport(height: 240)),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: _buildMaterialList()),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    final PbrTextureAtlasMaps? maps = _gpuAtlas?.maps;
    final String stats = maps == null
        ? 'Generowanie w RAM...'
        : '${maps.width}x${maps.height} px • ${(maps.totalMemoryBytes / (1024 * 1024)).toStringAsFixed(2)} MB RAM • ${maps.generationTimeMs} ms';

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'PBR TEXTURE ATLAS (RAM)',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              stats,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _AtlasActionButton(
              label: _tiledPreview ? 'Kafelek 2x2' : 'Pełny Atlas',
              icon: _tiledPreview ? Icons.grid_view_rounded : Icons.layers_rounded,
              enabled: widget.enabled && !_isLoading,
              isActive: _tiledPreview,
              onPressed: () {
                setState(() => _tiledPreview = !_tiledPreview);
              },
            ),
            const SizedBox(width: 8),
            _AtlasActionButton(
              label: 'Odśwież',
              icon: Icons.refresh_rounded,
              enabled: widget.enabled && !_isLoading,
              isActive: false,
              onPressed: () => _rebuildAtlas(bypassCache: true),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChannelSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PbrTextureChannel.values.map((PbrTextureChannel channel) {
        final bool selected = _selectedChannel == channel;
        final String label;
        switch (channel) {
          case PbrTextureChannel.albedo:
            label = 'Albedo';
          case PbrTextureChannel.normal:
            label = 'Normal Map';
          case PbrTextureChannel.orm:
            label = 'ORM (AO/Rough/Metal)';
        }
        return _AtlasActionButton(
          label: label,
          icon: Icons.texture_rounded,
          enabled: widget.enabled,
          isActive: selected,
          onPressed: () {
            setState(() => _selectedChannel = channel);
          },
        );
      }).toList(),
    );
  }

  Widget _buildPreviewViewport({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      clipBehavior: Clip.antiAlias,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.goldAccent, strokeWidth: 2),
            )
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(fontFamily: 'Inter', color: AppColors.crimsonAlert, fontSize: 12),
                  ),
                )
              : CustomPaint(
                  painter: _PbrAtlasPreviewPainter(
                    atlas: _gpuAtlas!,
                    channel: _selectedChannel,
                    selectedMaterialId: _tiledPreview ? _selectedMaterialId : null,
                  ),
                  child: const SizedBox.expand(),
                ),
    );
  }

  Widget _buildMaterialList() {
    final Map<String, PbrUvRegion> regions = _gpuAtlas?.maps.regions ?? <String, PbrUvRegion>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: regions.values.map((PbrUvRegion region) {
        final bool selected = _selectedMaterialId == region.materialId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _MaterialSlotTile(
            region: region,
            selected: selected,
            enabled: widget.enabled,
            onTap: () => setState(() => _selectedMaterialId = region.materialId),
          ),
        );
      }).toList(),
    );
  }
}

class _AtlasActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool isActive;
  final VoidCallback onPressed;

  const _AtlasActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.isActive,
    required this.onPressed,
  });

  @override
  State<_AtlasActionButton> createState() => _AtlasActionButtonState();
}

class _AtlasActionButtonState extends State<_AtlasActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    if (!widget.enabled) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.4);
    } else if (_pressed) {
      bgColor = AppColors.primaryAccent.withValues(alpha: 0.85);
    } else if (widget.isActive) {
      bgColor = AppColors.primaryAccent;
    } else if (_hovered) {
      bgColor = AppColors.surfaceLight;
    } else {
      bgColor = AppColors.background;
    }

    final Color borderColor = _focused
        ? AppColors.goldAccent
        : (widget.isActive ? AppColors.goldAccent.withValues(alpha: 0.7) : const Color(0xFF2A2F3D));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                widget.icon,
                size: 14,
                color: widget.enabled ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                  color: widget.enabled ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialSlotTile extends StatefulWidget {
  final PbrUvRegion region;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _MaterialSlotTile({
    required this.region,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_MaterialSlotTile> createState() => _MaterialSlotTileState();
}

class _MaterialSlotTileState extends State<_MaterialSlotTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = !widget.enabled
        ? AppColors.background.withValues(alpha: 0.4)
        : widget.selected
            ? AppColors.surfaceLight
            : (_hovered ? AppColors.surfaceLight.withValues(alpha: 0.7) : AppColors.background);

    final Color border = _focused
        ? AppColors.goldAccent
        : (widget.selected ? AppColors.goldAccent : const Color(0xFF2A2F3D));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  widget.region.materialId,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                    color: widget.enabled ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '${widget.region.tileSize}px',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PbrAtlasPreviewPainter extends CustomPainter {
  final PbrGpuTextureAtlas atlas;
  final PbrTextureChannel channel;
  final String? selectedMaterialId;

  const _PbrAtlasPreviewPainter({
    required this.atlas,
    required this.channel,
    this.selectedMaterialId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final ui.Image img = atlas.imageForChannel(channel);
    final Paint paint = Paint()..filterQuality = FilterQuality.medium;

    if (selectedMaterialId != null && atlas.maps.regions.containsKey(selectedMaterialId)) {
      final PbrUvRegion region = atlas.maps.regions[selectedMaterialId]!;
      final Rect src = region.pixelRect;
      final double halfW = size.width * 0.5;
      final double halfH = size.height * 0.5;
      for (int row = 0; row < 2; row++) {
        for (int col = 0; col < 2; col++) {
          final Rect dst = Rect.fromLTWH(col * halfW, row * halfH, halfW, halfH);
          canvas.drawImageRect(img, src, dst, paint);
        }
      }
    } else {
      final Rect src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final Rect dst = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawImageRect(img, src, dst, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PbrAtlasPreviewPainter oldDelegate) {
    return oldDelegate.atlas != atlas ||
        oldDelegate.channel != channel ||
        oldDelegate.selectedMaterialId != selectedMaterialId;
  }
}
