// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/memory_and_stream_leak_guard.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';

void _idleIsolateEntry(SendPort _) {}

void main() {
  group('MemoryAndStreamLeakGuard', () {
    test('reports clean audit when Isolate, AnimationController and StreamSubscription are closed before exit', () async {
      final MemoryAndStreamLeakGuard guard = MemoryAndStreamLeakGuard();
      guard.beginRace3dSession(stageId: 'stage_12', stageName: 'Alpe d\'Huez');

      final ReceivePort receivePort = ReceivePort();
      final Isolate isolate = await Isolate.spawn(
        _idleIsolateEntry,
        receivePort.sendPort,
      );
      final AnimationController animController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      );
      final StreamController<int> streamController = StreamController<int>();
      final StreamSubscription<int> subscription =
          streamController.stream.listen((_) {});

      guard.registerIsolate('sim_isolate', isolate: isolate);
      guard.registerAnimationController('camera_anim', animController);
      guard.registerStreamSubscription('telemetry_sub', subscription);

      expect(guard.currentSnapshot.isRace3dSessionActive, isTrue);
      expect(guard.currentSnapshot.totalActiveCount, 3);

      // Symulacja poprawnego wyjścia z wyścigu 3D do widoku menedżera
      isolate.kill(priority: Isolate.immediate);
      receivePort.close();
      guard.markIsolateClosed('sim_isolate');

      animController.dispose();
      guard.markAnimationControllerDisposed('camera_anim');

      await subscription.cancel();
      await streamController.close();
      guard.markStreamSubscriptionCancelled('telemetry_sub');

      final LeakAuditReport report = await guard.endRace3dSessionAndAudit();

      expect(report.isClean, isTrue);
      expect(report.totalTracked, 3);
      expect(report.properlyDisposed, 3);
      expect(report.totalLeaked, 0);
      expect(report.issues, isEmpty);
      expect(guard.currentSnapshot.isRace3dSessionActive, isFalse);

      await guard.disposeGuard();
    });

    test('detects and force-cleans leaked Isolate, AnimationController and StreamSubscription', () async {
      final MemoryAndStreamLeakGuard guard = MemoryAndStreamLeakGuard();
      guard.beginRace3dSession(stageId: 'stage_15', stageName: 'Mont Ventoux');

      bool isolateCallbackCalled = false;
      bool streamCancelled = false;

      final AnimationController animController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 500),
      )..repeat();

      final StreamController<String> streamController = StreamController<String>();
      final StreamSubscription<String> subscription =
          streamController.stream.listen((_) {});

      guard.registerIsolate(
        'leaked_isolate',
        onDispose: () {
          isolateCallbackCalled = true;
        },
      );
      guard.registerAnimationController('leaked_anim', animController);
      guard.registerStreamSubscription(
        'leaked_sub',
        subscription,
        onCancel: () {
          streamCancelled = true;
        },
      );

      final LeakAuditReport report = await guard.endRace3dSessionAndAudit(
        autoCleanupLeaks: true,
      );

      expect(report.isClean, isFalse);
      expect(report.leakedIsolates, 1);
      expect(report.leakedAnimationControllers, 1);
      expect(report.leakedStreamSubscriptions, 1);
      expect(report.forceCleanedCount, 3);
      expect(report.issues.length, 3);
      expect(isolateCallbackCalled, isTrue);
      expect(streamCancelled, isTrue);

      await streamController.close();
      await guard.disposeGuard();
    });
  });

  group('MemoryAndStreamLeakGuardPanel responsive layout', () {
    for (final Size viewportSize in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without RenderFlex overflow at ${viewportSize.width.toInt()}x${viewportSize.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewportSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final MemoryAndStreamLeakGuard guard = MemoryAndStreamLeakGuard();
          guard.beginRace3dSession(stageId: 'stage_1', stageName: 'Etap 1');
          final StreamController<int> controller = StreamController<int>();
          final StreamSubscription<int> sub = controller.stream.listen((_) {});
          guard.registerStreamSubscription('hud_sub', sub);

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: MemoryAndStreamLeakGuardPanel(guard: guard),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Strażnik Pamięci i Strumieni 3D'), findsOneWidget);
          expect(find.text('Audyt Wyjścia 3D'), findsOneWidget);
          expect(find.text('Wyczyść Wycieki'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.ensureVisible(find.text('Audyt Wyjścia 3D'));
          await tester.tap(find.text('Audyt Wyjścia 3D'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);

          // Odmontuj drzewo widgetów przed zamknięciem ValueNotifier w guard.disposeGuard()
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(milliseconds: 50));

          await tester.runAsync(() async {
            await guard.disposeGuard();
            await controller.close();
          });
        },
      );
    }
  });
}
