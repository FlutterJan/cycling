import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/engine/rendering3d/procedural_pbr_texture_atlas_generator.dart';

void main() {
  group('ProceduralPbrTextureAtlasGenerator', () {
    late ProceduralPbrTextureAtlasGenerator generator;

    setUp(() {
      generator = ProceduralPbrTextureAtlasGenerator();
    });

    tearDown(() {
      generator.clearCache();
    });

    test('generates all 5 PBR material types in RAM with valid buffers and UV regions', () {
      final PbrTextureAtlasMaps maps = generator.generateAtlasMaps(
        tileResolution: PbrAtlasTileResolution.micro,
      );

      expect(maps.tileSize, 64);
      expect(maps.regions.length, 6);
      expect(maps.albedoRgba.length, maps.width * maps.height * 4);
      expect(maps.normalRgba.length, maps.width * maps.height * 4);
      expect(maps.ormRgba.length, maps.width * maps.height * 4);
      expect(maps.totalMemoryBytes, maps.width * maps.height * 4 * 3);

      expect(maps.regions.containsKey('carbon_3k'), isTrue);
      expect(maps.regions.containsKey('carbon_ud'), isTrue);
      expect(maps.regions.containsKey('frame_metallic_team'), isTrue);
      expect(maps.regions.containsKey('frame_metallic_gold'), isTrue);
      expect(maps.regions.containsKey('tire_tan_wall'), isTrue);
      expect(maps.regions.containsKey('road_asphalt'), isTrue);

      for (final PbrUvRegion region in maps.regions.values) {
        expect(region.u0, greaterThanOrEqualTo(0.0));
        expect(region.v0, greaterThanOrEqualTo(0.0));
        expect(region.u1, lessThanOrEqualTo(1.0));
        expect(region.v1, lessThanOrEqualTo(1.0));
        expect(region.u1, greaterThan(region.u0));
        expect(region.v1, greaterThan(region.v0));
      }
    });

    test('tan-wall tire has dark rubber tread center and warm cream sidewall', () {
      final PbrTextureAtlasMaps maps = generator.generateAtlasMaps(
        materials: <PbrMaterialSpec>[PbrMaterialSpec.tanWallTireDefault()],
        tileResolution: PbrAtlasTileResolution.micro,
        useCache: false,
      );

      final Color centerTread = maps.sampleMaterialUv('tire_tan_wall', PbrTextureChannel.albedo, 0.5, 0.5);
      final Color tanSidewall = maps.sampleMaterialUv('tire_tan_wall', PbrTextureChannel.albedo, 0.5, 0.08);

      // Bieżnik jest ciemny, a kremowy bok Tan-Wall jest wyraźnie jaśniejszy i ciepły (R > B).
      expect((centerTread.r * 255).round(), lessThan(80));
      expect((tanSidewall.r * 255).round(), greaterThan(140));
      expect(tanSidewall.r, greaterThan(tanSidewall.b));
    });

    test('metallic frame paint has high metallic channel in ORM and carbon 3k has tangent-space normals', () {
      final PbrTextureAtlasMaps maps = generator.generateAtlasMaps(
        materials: <PbrMaterialSpec>[
          PbrMaterialSpec.metallicPaint(primaryColor: AppColors.primaryAccent),
          PbrMaterialSpec.carbon3kDefault(),
        ],
        tileResolution: PbrAtlasTileResolution.micro,
        useCache: false,
      );

      final Color paintOrm =
          maps.sampleMaterialUv('frame_metallic_burgundy', PbrTextureChannel.orm, 0.5, 0.5);
      // Kanał B w ORM przechowuje Metallic (> 0.65).
      expect(paintOrm.b, greaterThan(0.60));

      final Color carbonNormal = maps.sampleMaterialUv('carbon_3k', PbrTextureChannel.normal, 0.25, 0.25);
      // Składowa Z normalnej w przestrzeni stycznej powinna być skierowana dodatnio (> 0.5).
      expect(carbonNormal.b, greaterThan(0.50));
    });

    test('decodes RAM buffers directly to GPU ui.Image without disk PNGs and disposes cleanly', () async {
      final PbrGpuTextureAtlas gpuAtlas = await generator.buildGpuAtlas(
        tileResolution: PbrAtlasTileResolution.micro,
      );

      expect(gpuAtlas.isDisposed, isFalse);
      expect(gpuAtlas.albedoImage.width, gpuAtlas.maps.width);
      expect(gpuAtlas.normalImage.height, gpuAtlas.maps.height);
      expect(gpuAtlas.ormImage.width, gpuAtlas.maps.width);

      final ui.ImageShader shader = gpuAtlas.createAtlasShader();
      expect(shader, isA<ui.ImageShader>());

      final Paint paint = gpuAtlas.createAtlasPaint();
      expect(paint.shader, isNotNull);

      generator.clearCache();
      expect(gpuAtlas.isDisposed, isTrue);
    });

    testWidgets('PbrTextureAtlasInspectorPanel renders without overflow at 390x844, 1024x768, 1600x900',
        (WidgetTester tester) async {
      final List<Size> viewports = <Size>[
        const Size(390, 844),
        const Size(1024, 768),
        const Size(1600, 900),
      ];

      for (final Size size in viewports) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: SizedBox(
                  width: size.width - 16,
                  height: size.height - 16,
                  child: PbrTextureAtlasInspectorPanel(
                    generator: generator,
                    initialResolution: PbrAtlasTileResolution.micro,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 80));
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.text('PBR TEXTURE ATLAS (RAM)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      await tester.binding.setSurfaceSize(null);
    });
  });
}
