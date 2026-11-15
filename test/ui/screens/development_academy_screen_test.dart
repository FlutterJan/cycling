// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/screens/development_academy_screen.dart';

void main() {
  Widget createTestWidget({int initialTab = 0, String? initialRiderId}) {
    return ProviderScope(
      child: MaterialApp(
        home: DevelopmentAcademyScreen(
          initialTab: initialTab,
          initialRiderId: initialRiderId,
        ),
      ),
    );
  }

  testWidgets('renders DevelopmentAcademyScreen header and 5 tabs',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify Title and Devo Campus indicator
    expect(find.textContaining('DEVO TEAM'), findsWidgets);
    expect(find.textContaining('Baza:'), findsOneWidget);

    // Verify all 5 tab titles
    expect(find.text('Kadra Devo'), findsOneWidget);
    expect(find.text('Krzywe Progresji'), findsOneWidget);
    expect(find.text('Benchmark Globalny'), findsOneWidget);
    expect(find.text('Raporty Trenera'), findsOneWidget);
    expect(find.text('Wyścigi & Kampus'), findsOneWidget);

    // Verify presence of Devo riders in the first tab
    expect(find.textContaining('Wiek: 18 l.'), findsWidgets);
    expect(find.textContaining('W/kg'), findsWidgets);
  });

  testWidgets('filters riders by specialization in Tab 1', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap filter chip "Górale GC"
    final climberChip = find.text('Górale GC');
    expect(climberChip, findsOneWidget);
    await tester.tap(climberChip);
    await tester.pumpAndSettle();

    // Verify filtered list shows only climbers
    expect(find.textContaining('Górale GC'), findsWidgets);
  });

  testWidgets('navigates to Tab 2 and displays progression curves chart',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget(initialTab: 1));
    await tester.pumpAndSettle();

    // Verify chart section
    expect(find.textContaining('EWOLUCJA W CZASIE:'), findsOneWidget);
    expect(find.text('Próg FTP (Wat)'), findsOneWidget);
    expect(find.text('Pułap Tlenowy (VO₂max)'), findsOneWidget);
    expect(find.text('Moc Względna (W/kg)'), findsOneWidget);

    // Verify CustomPaint chart is present
    expect(find.byType(CustomPaint), findsWidgets);

    // Verify audit history table
    expect(find.textContaining('HISTORIA AUDYTÓW WYDOLNOŚCIOWYCH'), findsOneWidget);
  });

  testWidgets('displays global peer benchmark comparison in Tab 3',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget(initialTab: 2));
    await tester.pumpAndSettle();

    // Verify Benchmark percentiles
    expect(find.textContaining('GLOBALNY RANKING U23: TOP'), findsOneWidget);
    expect(find.text('PORÓWNANIE Z METRYKAMI ŚWIATOWYMI U23'), findsOneWidget);
    expect(find.text('Moc 20 min (W/kg)'), findsOneWidget);
    expect(find.text('Pułap Tlenowy (VO₂max)'), findsOneWidget);
  });

  testWidgets('displays Coach reports and allows senior mentor assignment in Tab 4',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget(initialTab: 3));
    await tester.pumpAndSettle();

    // Verify Coach Dirk De Wolf report
    expect(find.text('DIRK DE WOLF'), findsOneWidget);
    expect(find.textContaining('Szef Przygotowania Fizycznego'), findsOneWidget);

    // Verify Senior Mentorship section
    expect(find.textContaining('PROGRAM MENTORINGU WETERANA'), findsOneWidget);

    // Tap mentor button
    final mentorBtn = find.textContaining('Mentora');
    expect(mentorBtn, findsOneWidget);
    await tester.tap(mentorBtn);
    await tester.pumpAndSettle();

    // Verify feedback SnackBar
    expect(find.textContaining('Przypisano mentora'), findsOneWidget);
  });

  testWidgets('promotes rider to WorldTeam Neo-Pro via confirmation dialog',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget(initialTab: 1));
    await tester.pumpAndSettle();

    // Tap promotion button
    final promoteBtn = find.text('Promuj do WorldTeamu (Neo-Pro)');
    expect(promoteBtn, findsOneWidget);
    await tester.tap(promoteBtn);
    await tester.pumpAndSettle();

    // Verify dialog title and contents
    expect(find.text('Awans do Pierwszej Drużyny (Neo-Pro)'), findsOneWidget);
    expect(find.textContaining('Nowy kontrakt WorldTour:'), findsOneWidget);

    // Confirm promotion
    final confirmBtn = find.text('Podpisz kontrakt Neo-Pro');
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    // Verify success SnackBar
    expect(find.textContaining('Sukces!'), findsOneWidget);
    expect(find.text('W Pierwszym Składzie'), findsOneWidget);
  });

  testWidgets('displays youth races and simulates race in Tab 5',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget(initialTab: 4));
    await tester.pumpAndSettle();

    // Verify campus tier and race calendar
    expect(find.textContaining('Klub Kontynentalny UCI Devo'), findsWidgets);
    expect(find.textContaining('Giro Next Gen (Baby Giro)'), findsOneWidget);
    expect(find.textContaining('Tour de l\'Avenir'), findsOneWidget);

    // Tap "Symuluj Start" on the first race
    final simBtn = find.text('Symuluj Start').first;
    await tester.ensureVisible(simBtn);
    await tester.tap(simBtn);
    await tester.pumpAndSettle();

    // Verify race result report dialog
    expect(find.textContaining('Giro del Belvedere U23'), findsWidgets);
    expect(find.text('OK'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });
}

