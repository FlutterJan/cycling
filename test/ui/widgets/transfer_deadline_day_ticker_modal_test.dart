// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/widgets/transfer_deadline_day_ticker_modal.dart';

void main() {
  Widget buildTestApp({
    required Size surfaceSize,
    VoidCallback? onClose,
    VoidCallback? onOpenFullNegotiationDesk,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: Scaffold(
            body: SizedBox(
              width: surfaceSize.width,
              height: surfaceSize.height,
              child: TransferDeadlineDayTickerModal(
                onClose: onClose,
                onOpenFullNegotiationDesk: onOpenFullNegotiationDesk,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('TransferDeadlineDayTickerModal', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(buildTestApp(surfaceSize: size));
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.text('PELOTON SPORT TV'), findsOneWidget);
          expect(
            find.byType(BreakingNewsTickerBar),
            findsOneWidget,
          );

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(milliseconds: 50));
        },
      );
    }

    testWidgets(
      'supports ticker pause/resume, next story, and category filter',
      (tester) async {
        const size = Size(1280, 820);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestApp(surfaceSize: size));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('BREAKING NEWS'), findsOneWidget);

        // Pause ticker
        await tester.tap(find.byTooltip('Zatrzymaj pasek'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byTooltip('Wznów pasek'), findsOneWidget);

        // Resume ticker
        await tester.tap(find.byTooltip('Wznów pasek'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byTooltip('Zatrzymaj pasek'), findsOneWidget);

        // Next story
        await tester.tap(find.byTooltip('Następny news'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(tester.takeException(), isNull);

        // Filter by PRZECIEK
        await tester.tap(find.text('PRZECIEK').first);
        await tester.pump(const Duration(milliseconds: 250));
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
      },
    );

    testWidgets(
      'can advance time, switch tabs, shortlist and sign an offer',
      (tester) async {
        const size = Size(1440, 860);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestApp(surfaceSize: size));
        await tester.pump(const Duration(milliseconds: 300));

        // Advance 15 minutes
        await tester.tap(find.text('+15m'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('11h 45m'), findsOneWidget);

        // Toggle shortlist on featured offer
        await tester.tap(find.text('Obserwuj'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('Obserwowany'), findsOneWidget);

        // Sign featured offer
        await tester.tap(find.text('Podpisz teraz'));
        await tester.pump(const Duration(milliseconds: 300));

        // Switch to Sfinalizowane tab
        await tester.tap(find.text('Sfinalizowane (1)'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byIcon(Icons.verified_rounded), findsWidgets);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
      },
    );

    testWidgets(
      'showTransferDeadlineDayTickerModal opens and closes cleanly',
      (tester) async {
        const size = Size(1280, 820);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () =>
                          showTransferDeadlineDayTickerModal(context),
                      child: const Text('Open Studio'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text('Open Studio'));
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(TransferDeadlineDayTickerModal), findsOneWidget);

        await tester.tap(find.text('Zamknij'));
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(TransferDeadlineDayTickerModal), findsNothing);
      },
    );
  });
}
