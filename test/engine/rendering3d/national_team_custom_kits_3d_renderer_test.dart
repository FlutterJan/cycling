// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/national_team_custom_kits_3d_renderer.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  group('NationalTeamKitsCatalog & Models', () {
    test('contains 16 official cycling nations with unique country codes', () {
      const kits = NationalTeamKitsCatalog.officialKits;
      expect(kits.length, 16);
      final codes = kits.map((k) => k.countryCode).toSet();
      expect(codes.length, 16);
      expect(codes, containsAll(['POL', 'BEL', 'FRA', 'ITA', 'SLO', 'NED']));
    });

    test('byCountryCode returns exact match and deterministic fallback', () {
      final pol = NationalTeamKitsCatalog.byCountryCode('pol');
      expect(pol.countryCode, 'POL');
      expect(pol.patternStyle, NationalKitPatternStyle.chestBand);

      final fallback = NationalTeamKitsCatalog.byCountryCode('JPN');
      expect(fallback.countryCode, 'JPN');
      expect(fallback.flagColors.length, 3);
    });

    test('NationalTeamKitSpec and NationalKit3dRenderConfig JSON round-trip', () {
      final bel = NationalTeamKitsCatalog.byCountryCode('BEL');
      final decodedSpec = NationalTeamKitSpec.fromJson(bel.toJson());
      expect(decodedSpec.countryCode, 'BEL');
      expect(decodedSpec.patternStyle, bel.patternStyle);
      expect(decodedSpec.uciNationRank, bel.uciNationRank);

      const cfg = NationalKit3dRenderConfig(
        selectedCountryCode: 'SLO',
        eventVariant: NationalTeamKitEventVariant.olympicGamesItt,
        helmetAndBibMode: NationalKitHelmetAndBibMode.olympicChampionGold,
        showPelotonComparison: true,
        cadenceRpm: 102,
      );
      final decodedCfg = NationalKit3dRenderConfig.fromJson(cfg.toJson());
      expect(decodedCfg.selectedCountryCode, 'SLO');
      expect(
        decodedCfg.eventVariant,
        NationalTeamKitEventVariant.olympicGamesItt,
      );
      expect(
        decodedCfg.helmetAndBibMode,
        NationalKitHelmetAndBibMode.olympicChampionGold,
      );
      expect(decodedCfg.showPelotonComparison, isTrue);
      expect(decodedCfg.cadenceRpm, 102);
    });
  });

  group('NationalTeamCustomKits3dRenderer 3D Math & Stats', () {
    const renderer = NationalTeamCustomKits3dRenderer();

    test('projects 3D world point in front of camera to visible 2D point', () {
      const cfg = NationalKit3dRenderConfig();
      final projected = renderer.projectWorldPoint(
        worldPoint: Vector3(0.0, 1.0, 0.0),
        config: cfg,
        viewportSize: const Size(800, 600),
      );
      expect(projected.visible, isTrue);
      expect(projected.depth, greaterThan(1.0));
      expect(projected.scale, greaterThan(100.0));
    });

    test('evaluates fabric luminance within valid shading range', () {
      const cfg = NationalKit3dRenderConfig(showLightingAndSpecular: true);
      final lum = renderer.evaluateFabricLuminance(
        surfaceNormal: Vector3(0.5, 0.8, 0.4),
        config: cfg,
      );
      expect(lum, inInclusiveRange(0.32, 1.12));

      const flatCfg = NationalKit3dRenderConfig(showLightingAndSpecular: false);
      expect(
        renderer.evaluateFabricLuminance(
          surfaceNormal: Vector3(-1.0, 0.0, 0.0),
          config: flatCfg,
        ),
        0.88,
      );
    });

    test('computeFrameStats scales riders and vertices for echelon mode', () {
      const single = NationalKit3dRenderConfig(showPelotonComparison: false);
      const echelon = NationalKit3dRenderConfig(
        showPelotonComparison: true,
        eventVariant: NationalTeamKitEventVariant.worldChampionshipsItt,
      );

      final singleStats = renderer.computeFrameStats(single);
      final echelonStats = renderer.computeFrameStats(echelon);

      expect(singleStats.riderCount, 1);
      expect(echelonStats.riderCount, 3);
      expect(
        echelonStats.projectedVerticesCount,
        greaterThan(singleStats.projectedVerticesCount * 3),
      );
      expect(echelonStats.eventVariantTag, 'MŚ ITT');
    });
  });

  group('NationalTeamCustomKits3dPreviewPanel Widget & Responsive Tests', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      Key? key,
      bool controlsEnabled = true,
      ValueChanged<NationalKit3dRenderConfig>? onConfigChanged,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NationalTeamCustomKits3dPreviewPanel(
              key: key,
              controlsEnabled: controlsEnabled,
              onConfigChanged: onConfigChanged,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly without overflow at 390x844 (mobile)', (
      tester,
    ) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(tester.takeException(), isNull);
      expect(find.text('POLSKA (POL)'), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow at 1024x768 (tablet)', (
      tester,
    ) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(tester.takeException(), isNull);
      expect(find.text('OFICJALNE KOSZULKI REPREZENTACJI 3D'), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow at 1600x900 (desktop)', (
      tester,
    ) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(tester.takeException(), isNull);
      expect(find.text('POLSKA (POL)'), findsOneWidget);
    });

    testWidgets('switches nation, event variant, and respects disabled state', (
      tester,
    ) async {
      NationalKit3dRenderConfig? latestConfig;
      await pumpPanelAtSize(
        tester,
        const Size(1600, 900),
        onConfigChanged: (c) => latestConfig = c,
      );

      await tester.tap(find.text('BEL'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('BELGIA (BEL)'), findsOneWidget);
      expect(latestConfig?.selectedCountryCode, 'BEL');

      await tester.tap(find.text('MŚ ITT'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(latestConfig?.eventVariant,
          NationalTeamKitEventVariant.worldChampionshipsItt);

      await tester.tap(find.text('ZŁOTO IO'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(latestConfig?.helmetAndBibMode,
          NationalKitHelmetAndBibMode.olympicChampionGold);

      // Sprawdzenie trybu wyłączonego (disabled).
      await pumpPanelAtSize(
        tester,
        const Size(1600, 900),
        key: const ValueKey('disabled-panel'),
        controlsEnabled: false,
      );
      await tester.tap(find.text('FRA'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('POLSKA (POL)'), findsOneWidget);
    });
  });
}
