// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/glb_asset_loader_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GlbAssetLoaderService loaderService;

  setUp(() {
    loaderService = GlbAssetLoaderService();
    loaderService.clearCache();
  });

  tearDown(() {
    loaderService.clearCache();
  });

  group('GlbAssetCatalog - Catalog 34 Modeli Blendra', () {
    test('katalog zawiera dokładnie 34 zdefiniowane modele 3D', () {
      expect(GlbAssetCatalog.allAssets.length, equals(34));
    });

    test('liczba modeli w poszczególnych kategoriach zgadza się ze specyfikacją', () {
      expect(GlbAssetCatalog.getByCategory(GlbAssetCategory.bike).length, equals(8));
      expect(GlbAssetCatalog.getByCategory(GlbAssetCategory.cyclist).length, equals(5));
      expect(GlbAssetCatalog.getByCategory(GlbAssetCategory.rider).length, equals(1));
      expect(GlbAssetCatalog.getByCategory(GlbAssetCategory.environment).length, equals(8));
      expect(GlbAssetCatalog.getByCategory(GlbAssetCategory.furniture).length, equals(6));
      expect(GlbAssetCatalog.getByCategory(GlbAssetCategory.road).length, equals(3));
      expect(GlbAssetCatalog.getByCategory(GlbAssetCategory.vehicle).length, equals(3));
    });

    test('find odnajduje zasób po identyfikatorze, nazwie pliku i ścieżce', () {
      // 1. Identyfikator
      final def1 = GlbAssetCatalog.find('frame_aero');
      expect(def1, isNotNull);
      expect(def1!.id, equals('frame_aero'));
      expect(def1.category, equals(GlbAssetCategory.bike));

      // 2. Nazwa pliku z rozszerzeniem
      final def2 = GlbAssetCatalog.find('frame_aero.glb');
      expect(def2, isNotNull);
      expect(def2!.id, equals('frame_aero'));

      // 3. Względna ścieżka z ukośnikami Unixowymi
      final def3 = GlbAssetCatalog.find('assets/3d/bikes/frame_aero.glb');
      expect(def3, isNotNull);
      expect(def3!.id, equals('frame_aero'));

      // 4. Ścieżka z ukośnikami Windowsowymi (\)
      final def4 = GlbAssetCatalog.find(r'assets\3d\bikes\frame_aero.glb');
      expect(def4, isNotNull);
      expect(def4!.id, equals('frame_aero'));

      // 5. Inne kategorie
      expect(GlbAssetCatalog.find('tree_pine')?.category, equals(GlbAssetCategory.environment));
      expect(GlbAssetCatalog.find('arch_finish')?.category, equals(GlbAssetCategory.furniture));
      expect(GlbAssetCatalog.find('vehicle_team_car')?.category, equals(GlbAssetCategory.vehicle));
    });
  });

  group('GlbAssetLoaderService - Parsowanie Binarne Plików .glb z Dysku', () {
    test('parsuje rzeczywisty model ramy frame_aero.glb wygenerowany w Blenderze', () async {
      final file = File('assets/3d/bikes/frame_aero.glb');
      expect(file.existsSync(), isTrue, reason: 'Plik frame_aero.glb musi istnieć w assets/3d/bikes/');

      final bytes = await file.readAsBytes();
      final model = loaderService.parseGlbBinary(
        bytes,
        assetKey: 'frame_aero',
        category: GlbAssetCategory.bike,
        displayName: 'Rama Aero',
      );

      expect(model.assetKey, equals('frame_aero'));
      expect(model.isProceduralFallback, isFalse);
      expect(model.primitives.length, greaterThanOrEqualTo(1));
      expect(model.totalVertices, greaterThan(100));
      expect(model.totalTriangles, greaterThan(100));

      // Sprawdzenie poprawności wektorów geometrii
      final prim = model.primitives.first;
      expect(prim.vertices.isNotEmpty, isTrue);
      expect(prim.normals.isNotEmpty, isTrue);
      expect(prim.indices.isNotEmpty, isTrue);
      expect(prim.indices.length % 3, equals(0)); // Kompletne trójkąty

      // Sprawdzenie AABB Bounding Box
      expect(model.boundingBox.min.x, lessThan(model.boundingBox.max.x));
      expect(model.boundingBox.min.y, lessThan(model.boundingBox.max.y));
      expect(model.boundingRadius, greaterThan(0.0));
    });

    test('parsuje koło szosowe wheel_50mm.glb oraz sosnę tree_pine.glb', () async {
      final wheelFile = File('assets/3d/bikes/wheel_50mm.glb');
      if (wheelFile.existsSync()) {
        final wheelModel = await loaderService.loadModel('assets/3d/bikes/wheel_50mm.glb');
        expect(wheelModel.totalVertices, greaterThan(50));
        expect(wheelModel.totalTriangles, greaterThan(50));
        expect(wheelModel.isProceduralFallback, isFalse);
      }

      final treeFile = File('assets/3d/environment/tree_pine.glb');
      if (treeFile.existsSync()) {
        final treeModel = await loaderService.loadModel('tree_pine');
        expect(treeModel.totalVertices, greaterThan(10));
        expect(treeModel.isProceduralFallback, isFalse);
      }
    });

    test('parsuje bramę mety arch_finish.glb oraz wóz techniczny vehicle_team_car.glb', () async {
      final archFile = File('assets/3d/furniture/arch_finish.glb');
      if (archFile.existsSync()) {
        final archModel = await loaderService.loadModel('arch_finish');
        expect(archModel.totalVertices, greaterThan(50));
        expect(archModel.isProceduralFallback, isFalse);
      }

      final carFile = File('assets/3d/vehicles/vehicle_team_car.glb');
      if (carFile.existsSync()) {
        final carModel = await loaderService.loadModel('vehicle_team_car');
        expect(carModel.totalVertices, greaterThan(100));
        expect(carModel.isProceduralFallback, isFalse);
      }
    });
  });

  group('GlbAssetLoaderService - Caching & Memory Management', () {
    test('ponowne załadowanie tego samego modelu natychmiast trafia w cache', () async {
      expect(loaderService.cachedModelCount, equals(0));

      final model1 = await loaderService.loadModel('frame_aero');
      expect(loaderService.cachedModelCount, equals(1));
      expect(loaderService.isModelCached('frame_aero'), isTrue);

      final model2 = await loaderService.loadModel('frame_aero');
      expect(identical(model1, model2), isTrue);
      expect(loaderService.cachedModelCount, equals(1));
    });

    test('clearCache czyści pamięć podręczną i zeruje liczniki', () async {
      await loaderService.loadModel('frame_aero');
      await loaderService.loadModel('tree_pine');
      expect(loaderService.cachedModelCount, equals(2));
      expect(loaderService.totalCachedVertexCount, greaterThan(0));
      expect(loaderService.totalCachedTriangleCount, greaterThan(0));

      loaderService.clearCache();
      expect(loaderService.cachedModelCount, equals(0));
      expect(loaderService.totalCachedVertexCount, equals(0));
      expect(loaderService.totalCachedTriangleCount, equals(0));
      expect(loaderService.isModelCached('frame_aero'), isFalse);
    });

    test('synchroniczny getModel zwraca natychmiast model bez blokowania pętli renderera', () {
      // Modelu jeszcze nie ma w cache - getModel musi natychmiast zwrócić fallback
      // i zarejestrować go w cache bez rzucania wyjątku
      final model = loaderService.getModel('wheel_disc');
      expect(model, isNotNull);
      expect(model.totalVertices, greaterThan(0));
      expect(loaderService.isModelCached('wheel_disc'), isTrue);

      // Drugie wywołanie zwraca ten sam obiekt z cache
      final modelCached = loaderService.getModel('wheel_disc');
      expect(identical(model, modelCached), isTrue);
    });
  });

  group('GlbAssetLoaderService - Procedural Fallback (Zero-Crash Guarantee)', () {
    test('żądanie nieistniejącego pliku nie rzuca błędu i zwraca proceduralny fallback', () async {
      final fallback = await loaderService.loadModel('assets/3d/bikes/frame_nonexistent_xyz.glb');

      expect(fallback, isNotNull);
      expect(fallback.isProceduralFallback, isTrue);
      expect(fallback.fallbackReason, isNotNull);
      expect(fallback.totalVertices, greaterThan(0));
      expect(fallback.totalTriangles, greaterThan(0));
      expect(fallback.primitives.isNotEmpty, isTrue);
      expect(fallback.boundingBox.min.x, lessThan(fallback.boundingBox.max.x));
    });

    test('uszkodzone dane binarne GLB nie powodują crasha - natychmiastowy fallback', () async {
      // Symulacja pliku z uszkodzonym nagłówkiem (losowe śmieci binarne)
      final corruptedBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

      expect(
        () => loaderService.parseGlbBinary(
          corruptedBytes,
          assetKey: 'corrupted',
          category: GlbAssetCategory.unknown,
          displayName: 'Uszkodzony',
        ),
        throwsFormatException,
      );

      // Metoda loadModel przechwytuje błąd parsowania i zwraca fallback
      final safeFallback = loaderService.getModel('completely_corrupted_model');
      expect(safeFallback.isProceduralFallback, isTrue);
      expect(safeFallback.totalVertices, greaterThan(0));
    });

    test('proceduralny fallback ramy rowerowej generuje realistyczną geometrię rur', () {
      final builder = GlbProceduralFallbackBuilder();
      final frameModel = builder.buildFallback('frame_climbing');

      expect(frameModel.category, equals(GlbAssetCategory.bike));
      expect(frameModel.isProceduralFallback, isTrue);
      expect(frameModel.primitives.length, greaterThanOrEqualTo(6)); // rury ramy

      // Wymiary ramy powinny mieścić się w skali roweru szosowego (~1m długości, ~0.9m wysokości)
      final size = frameModel.size;
      expect(size.x, inInclusiveRange(0.6, 1.4));
      expect(size.y, inInclusiveRange(0.4, 1.1));
    });

    test('proceduralny fallback koła wheel_disc tworzy pełny dysk i oponę', () {
      final builder = GlbProceduralFallbackBuilder();
      final wheelModel = builder.buildFallback('wheel_disc');

      expect(wheelModel.category, equals(GlbAssetCategory.bike));
      expect(wheelModel.primitives.length, greaterThanOrEqualTo(2)); // opona + tarcza dysku

      // Średnica koła szosowego ~62cm (promień ~0.31m)
      final size = wheelModel.size;
      expect(size.x, inInclusiveRange(0.55, 0.70));
      expect(size.y, inInclusiveRange(0.55, 0.70));
    });

    test('proceduralny fallback kolarza buduje pozycję kolarską z tułowiem i kończynami', () {
      final builder = GlbProceduralFallbackBuilder();
      final cyclist = builder.buildFallback('cyclist_road');

      expect(cyclist.category, equals(GlbAssetCategory.cyclist));
      expect(cyclist.primitives.length, greaterThanOrEqualTo(5)); // tułów, miednica, głowa, ręce, nogi
      expect(cyclist.totalVertices, greaterThan(50));
    });

    test('proceduralny fallback drzew i otoczenia (sosna, cyprys, budynek)', () {
      final builder = GlbProceduralFallbackBuilder();

      final pine = builder.buildFallback('tree_pine');
      expect(pine.category, equals(GlbAssetCategory.environment));
      expect(pine.size.y, greaterThan(4.0)); // wysokie drzewo

      final cypress = builder.buildFallback('tree_cypress');
      expect(cypress.category, equals(GlbAssetCategory.environment));
      expect(cypress.size.y, greaterThan(4.0));

      final house = builder.buildFallback('building_townhouse');
      expect(house.category, equals(GlbAssetCategory.environment));
      expect(house.size.y, greaterThan(6.0));
    });

    test('proceduralny fallback wozu technicznego tworzy bryłę kombi i koła', () {
      final builder = GlbProceduralFallbackBuilder();
      final car = builder.buildFallback('vehicle_team_car');

      expect(car.category, equals(GlbAssetCategory.vehicle));
      expect(car.primitives.length, greaterThanOrEqualTo(5)); // nadwozie, kabina, 4 koła, bagażnik

      // Długość kombi ~4.6m
      expect(car.size.z, inInclusiveRange(3.5, 5.5));
    });

    test('proceduralny fallback bramy finiszowej tworzy konstrukcję kratownicy z banerem', () {
      final builder = GlbProceduralFallbackBuilder();
      final arch = builder.buildFallback('arch_finish');

      expect(arch.category, equals(GlbAssetCategory.furniture));
      expect(arch.primitives.length, greaterThanOrEqualTo(3)); // słupy, belka, baner

      // Szerokość bramy nad jezdnią ~8-9m
      expect(arch.size.x, inInclusiveRange(7.0, 10.0));
      expect(arch.size.y, inInclusiveRange(4.5, 6.5));
    });
  });

  group('GlbAssetLoaderService - Preloading', () {
    test('preloadEssentialAssets wczytuje i buforuje kluczowe modele wyścigu', () async {
      await loaderService.preloadEssentialAssets();

      expect(loaderService.cachedModelCount, greaterThanOrEqualTo(10));
      expect(loaderService.isModelCached('frame_aero'), isTrue);
      expect(loaderService.isModelCached('wheel_50mm'), isTrue);
      expect(loaderService.isModelCached('tree_pine'), isTrue);
      expect(loaderService.isModelCached('arch_finish'), isTrue);
    });
  });
}

