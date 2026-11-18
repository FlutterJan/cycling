// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/junior_development_loan_system_service.dart';
import 'package:pro_peloton_manager/ui/widgets/rider_loan_management_modal.dart';

void main() {
  Future<void> pumpModalAtSize(
    WidgetTester tester, {
    required Size size,
    bool isReadOnly = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: RiderLoanManagementModal(
              isReadOnly: isReadOnly,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('RiderLoanManagementModal', () {
    testWidgets('renders without overflow on mobile 390x844', (tester) async {
      await pumpModalAtSize(tester, size: const Size(390, 844));

      expect(find.text('Zarządzanie Wypożyczeniami Juniorów'), findsOneWidget);
      expect(find.text('Kluby Partnerskie'), findsOneWidget);
      expect(find.text('Dni & Pensja'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Dni & Pensja'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Gwarantowane dni wyścigowe'), findsOneWidget);
      expect(find.text('Podział pokrycia pensji'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.textContaining('Aktywne Umowy'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Aktywne Wypożyczenia'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on tablet 1024x768', (tester) async {
      await pumpModalAtSize(tester, size: const Size(1024, 768));

      expect(find.text('Zarządzanie Wypożyczeniami Juniorów'), findsOneWidget);
      expect(find.text('Gwarantowane dni wyścigowe'), findsOneWidget);
      expect(find.text('Podział pokrycia pensji'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on desktop 1600x900', (tester) async {
      await pumpModalAtSize(tester, size: const Size(1600, 900));

      expect(find.text('Zarządzanie Wypożyczeniami Juniorów'), findsOneWidget);
      expect(find.text('Juniorzy w Kadrze WT'), findsOneWidget);
      expect(
        find.text('Kluby Partnerskie (ProTeam & Continental)'),
        findsOneWidget,
      );
      expect(find.text('Gwarantowane dni wyścigowe'), findsOneWidget);
      expect(find.text('Podział pokrycia pensji'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('filters partner clubs and sends junior on loan', (tester) async {
      await pumpModalAtSize(tester, size: const Size(1600, 900));

      // Filter by Continental
      await tester.tap(find.text('Continental'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.textContaining('UCI Continental'), findsWidgets);

      // Reset filter to Wszystkie
      await tester.tap(find.text('Wszystkie'));
      await tester.pump(const Duration(milliseconds: 250));

      // Send selected junior on loan
      final sendButton = find.textContaining('Wypożycz Kacper Kowalski');
      expect(sendButton, findsOneWidget);
      await tester.ensureVisible(sendButton);
      await tester.tap(sendButton);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Aktywne Wypożyczenia (2)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows read-only block message and opens via showRiderLoanManagementModal',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 820);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showRiderLoanManagementModal(context, isReadOnly: true);
                  },
                  child: const Text('Otwórz modal'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Otwórz modal'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tryb tylko do odczytu.'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Zamknij'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Tryb tylko do odczytu.'), findsNothing);
    });

    testWidgets('handles empty state gracefully', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            juniorDevelopmentLoanProvider.overrideWith(
              (ref) => _EmptyLoanNotifier(
                const JuniorDevelopmentLoanSystemService(),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RiderLoanManagementModal(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Brak juniorów w kadrze.'), findsOneWidget);
      expect(
        find.text('Brak klubów partnerskich spełniających kryteria.'),
        findsOneWidget,
      );
      expect(
        find.text('Brak aktywnych wypożyczeń w bieżącym sezonie.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

class _EmptyLoanNotifier extends JuniorLoanSystemNotifier {
  _EmptyLoanNotifier(super.service) {
    state = const JuniorLoanSystemState(
      seasonYear: 2026,
      wtRosterSize: 28,
      injuredWtCount: 0,
      partnerClubs: [],
      candidates: [],
      agreements: [],
    );
  }
}
