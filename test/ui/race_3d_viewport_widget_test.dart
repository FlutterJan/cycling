// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/broadcast_tv_graphics_overlay.dart';
import 'package:pro_peloton_manager/engine/simulation/key_moments_detector.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/state/race_simulation_notifier.dart';
import 'package:pro_peloton_manager/ui/screens/race_3d_viewport_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestViewport({
    RaceStage? stage,
    ViewportCameraMode cameraMode = ViewportCameraMode.chasePlayerRider,
    bool showBroadcastHud = true,
    bool showCameraControls = true,
    ValueChanged<ViewportCameraMode>? onCameraModeChanged,
    ValueChanged<String>? onRiderSelected,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1280,
            height: 720,
            child: Race3DViewportWidget(
              stage: stage,
              initialCameraMode: cameraMode,
              showBroadcastHud: showBroadcastHud,
              showCameraControls: showCameraControls,
              onCameraModeChanged: onCameraModeChanged,
              onRiderSelected: onRiderSelected,
            ),
          ),
        ),
      ),
    );
  }

  group('Race3DViewportWidget - Renderowanie i Komponenty 3D', () {
    testWidgets('poprawnie montuje się i wyświetla demo wyścigu 3D oraz Broadcast HUD', (tester) async {
      await tester.pumpWidget(buildTestViewport());
      await tester.pump(const Duration(milliseconds: 32));

      // Sprawdzenie obecności Live Broadcast HUD
      expect(find.text('LIVE BROADCAST 3D'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Sprawdzenie domyślnej kamery
      expect(find.text('• ZA PLECAMI'), findsOneWidget);

      // Kolarz demonstracyjny (Pogacar)
      expect(find.textContaining('Pogacar'), findsOneWidget);
    });

    testWidgets('pozwala na przełączanie trybów kamer (Heli, Moto, Meta)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ViewportCameraMode? switchedMode;

      await tester.pumpWidget(buildTestViewport(
        onCameraModeChanged: (mode) => switchedMode = mode,
      ));
      await tester.pump(const Duration(milliseconds: 32));

      // Kliknięcie w kamerę Drona Peletonu
      final droneButton = find.text('Dron Peletonu');
      expect(droneButton, findsOneWidget);
      await tester.tap(droneButton);
      await tester.pump(const Duration(milliseconds: 64));

      expect(switchedMode, equals(ViewportCameraMode.droneOverhead));
      expect(find.text('• DRON PELETONU'), findsOneWidget);

      // Kliknięcie w motocykl TV
      final motoButton = find.text('Motocykl TV');
      expect(motoButton, findsOneWidget);
      await tester.tap(motoButton);
      await tester.pump(const Duration(milliseconds: 64));

      expect(switchedMode, equals(ViewportCameraMode.motoTvLead));
      expect(find.text('• MOTOCYKL TV'), findsOneWidget);

      // Kliknięcie w kamerę na kreskę mety
      final finishButton = find.text('Kreska Mety');
      expect(finishButton, findsOneWidget);
      await tester.tap(finishButton);
      await tester.pump(const Duration(milliseconds: 64));

      expect(switchedMode, equals(ViewportCameraMode.finishLineGantry));
      expect(find.text('• KRESKA METY'), findsOneWidget);
    });

    testWidgets('ukrywa HUD i kontrolki kamer gdy odpowiednie flagi są wyłączone', (tester) async {
      await tester.pumpWidget(buildTestViewport(
        showBroadcastHud: false,
        showCameraControls: false,
      ));
      await tester.pump(const Duration(milliseconds: 32));

      expect(find.text('LIVE BROADCAST 3D'), findsNothing);
      expect(find.text('Dron Peletonu'), findsNothing);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('pozwala na włączenie i wyłączenie trybu Aero Vision przyciskiem na HUD', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestViewport());
      await tester.pump(const Duration(milliseconds: 32));

      final aeroButton = find.text('AERO VISION');
      expect(aeroButton, findsOneWidget);

      // Kliknięcie włącza Aero Vision
      await tester.tap(aeroButton, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 32));

      // Kolejne kliknięcie wyłącza Aero Vision
      await tester.tap(aeroButton, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 32));

      expect(aeroButton, findsOneWidget);
    });

    testWidgets('obsługuje rzeczywisty etap wyścigu z segmentami brukowanymi i górskimi', (tester) async {
      const stage = RaceStage(
        id: 'stage_test_roubaix',
        stageNumber: 7,
        name: 'Compiegne > Roubaix',
        stageType: StageType.cobbleClassic,
        segments: [
          StageSegment(
            index: 0,
            startKm: 0.0,
            lengthKm: 15.0,
            startElevationM: 80.0,
            endElevationM: 110.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 20.0,
            windDirectionDegrees: 270.0,
            roadBearingDegrees: 0.0,
            sprintOrKomClassification: SegmentClassification.none,
          ),
          StageSegment(
            index: 1,
            startKm: 15.0,
            lengthKm: 2.5,
            startElevationM: 110.0,
            endElevationM: 105.0,
            surfaceType: SegmentSurfaceType.cobblestonesSector5,
            technicalDifficulty: 95.0,
            windDirectionDegrees: 270.0,
            roadBearingDegrees: 0.0,
            sprintOrKomClassification: SegmentClassification.none,
          ),
        ],
        baseTemperatureCelsius: 16.0,
        weatherCondition: WeatherCondition.lightRain,
        windSpeedKmh: 35.0,
      );

      await tester.pumpWidget(buildTestViewport(stage: stage));
      // Symulacja kilku klatek
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 32));

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('gesty przeciągania obracają kamerę wokół kolarza (orbit yaw/pitch), a RESET zeruje kąt', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestViewport());
      await tester.pump(const Duration(milliseconds: 32));

      final viewportFinder = find.byType(GestureDetector).first;

      // 1. Wykonanie gestu przeciągania poziomego (orbit yaw)
      await tester.drag(viewportFinder, const Offset(-180.0, -60.0));
      await tester.pump(const Duration(milliseconds: 32));

      // Sprawdzenie pojawienia się wskaźnika manualnego obrotu
      expect(find.textContaining('ORBIT:'), findsOneWidget);
      expect(find.text('RESET'), findsOneWidget);

      // 2. Kliknięcie RESET przywraca pozycję początkową
      await tester.tap(find.text('RESET'));
      await tester.pump(const Duration(milliseconds: 32));

      expect(find.text('RESET'), findsNothing);
    });

    testWidgets('rolka myszy i gest szczypania przybliżają i oddalają kamerę (zoom)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestViewport());
      await tester.pump(const Duration(milliseconds: 32));

      final center = tester.getCenter(find.byType(CustomPaint).first);

      // Symulacja zdarzenia rolki myszy (scroll down / zoom out)
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      pointer.hover(center);
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 300)));
      await tester.pump(const Duration(milliseconds: 32));

      expect(find.textContaining('ORBIT:'), findsOneWidget);

      // Podwójne kliknięcie resetuje zoom i orbit
      await tester.tap(find.byType(CustomPaint).first);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(CustomPaint).first);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('RESET'), findsNothing);
    });

    testWidgets('kliknięcie na kolarza w 3D otwiera panel telemetrii i pozwala wydać rozkaz taktyczny', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String? selectedRiderId;

      await tester.pumpWidget(buildTestViewport(
        onRiderSelected: (id) => selectedRiderId = id,
      ));
      // Symulacja klatek, by kolarze zostali przygotowani w kolejce renderowania 3D
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 32));

      // Kliknięcie w centrum ekranu, gdzie renderowany jest kolarz w perspektywie 3D
      final viewport = find.byType(Race3DViewportWidget).first;
      final center = tester.getCenter(viewport);

      await tester.tapAt(center);
      await tester.pump();
      // 400ms na rozstrzygnięcie gestu tap vs double-tap w GestureDetector
      await tester.pump(const Duration(milliseconds: 400));
      // 400ms na pełne wysunięcie się animacji modal bottom sheet
      await tester.pump(const Duration(milliseconds: 400));

      // Sprawdzenie czy otworzył się modal z telemetrią i rozkazami kolarza
      expect(find.textContaining('MOC (COGGAN)'), findsOneWidget);
      expect(find.textContaining('ENERGIA BEZTLENOWA'), findsOneWidget);

      // Wydanie rozkazu "Atakuj!"
      final attackButton = find.text('Atakuj!');
      expect(attackButton, findsOneWidget);

      await tester.tap(attackButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Sprawdzenie komunikatu zwrotnego na HUD
      expect(find.textContaining('Rozkaz: ATAKUJ!'), findsOneWidget);
      expect(selectedRiderId, isNotNull);

      // Czas na wygaśnięcie timera komunikatu zwrotnego
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('przycisk PHOTO FINISH na HUD otwiera modal z kamerą szczelinową', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestViewport());
      await tester.pump(const Duration(milliseconds: 32));

      final photoFinishBtn = find.text('PHOTO FINISH');
      expect(photoFinishBtn, findsOneWidget);

      await tester.tap(photoFinishBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PHOTO FINISH REPLAY'), findsOneWidget);

      // Zamknięcie powtórki
      await tester.tap(find.text('ZATWIERDŹ WYNIK I PODIUM'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PHOTO FINISH REPLAY'), findsNothing);
    });

    testWidgets('responsywność LayoutBuilder bez przepełnień dla 390x844, 1024x768 i 1600x900', (tester) async {
      for (final size in const <Size>[
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: const Race3DViewportWidget(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 32));

        expect(find.text('LIVE BROADCAST 3D'), findsOneWidget);
        if (size.width >= 600) {
          expect(find.byType(BroadcastTvGraphicsOverlay), findsOneWidget);
        }
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('KeyMomentsDetector wyzwala płynne przejście kamery na helikopter przy ataku GC', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const attackTrigger = KeyMomentTrigger(
        type: KeyMomentType.gcLeaderAttack,
        kilometerMark: 142.5,
        title: 'DECYDUJĄCY ATAK FAWORYTA GC!',
        description: 'Atak na podjeździe Hors Categorie!',
        shouldSwitchTo3d: true,
        recommendedCameraMode: 'helicopter',
        relatedRiderId: 'demo_leader',
        triggerKey: 'gc_attack_test_1',
      );

      final container = ProviderContainer(
        overrides: [
          activeKeyMomentProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      ViewportCameraMode? changedMode;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1600,
                height: 900,
                child: Race3DViewportWidget(
                  initialCameraMode: ViewportCameraMode.chasePlayerRider,
                  onCameraModeChanged: (mode) => changedMode = mode,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 32));

      // Wyzwolenie kluczowego momentu z KeyMomentsDetector
      container.updateOverrides([
        activeKeyMomentProvider.overrideWithValue(attackTrigger),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 64));

      expect(changedMode, equals(ViewportCameraMode.droneOverhead));
      expect(find.text('• DRON PELETONU'), findsOneWidget);
      expect(find.text('DECYDUJĄCY ATAK FAWORYTA GC!'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
    });
  });
}
