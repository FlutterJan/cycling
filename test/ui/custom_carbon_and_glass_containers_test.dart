import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/widgets/custom_carbon_and_glass_containers.dart';

void main() {
  Widget wrapWithTheme(Widget child, Size size) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets('CarbonFiberCard renders, handles hover/tap/disabled', (
    WidgetTester tester,
  ) async {
    int tapCount = 0;

    await tester.pumpWidget(
      wrapWithTheme(
        Center(
          child: CarbonFiberCard(
            accentTone: CarbonAccentTone.gold,
            onTap: () => tapCount++,
            child: const Text('CARBON_HEADER'),
          ),
        ),
        const Size(1024, 768),
      ),
    );

    expect(find.text('CARBON_HEADER'), findsOneWidget);

    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(CarbonFiberCard)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CarbonFiberCard));
    await tester.pumpAndSettle();
    expect(tapCount, 1);

    await tester.pumpWidget(
      wrapWithTheme(
        Center(
          child: CarbonFiberCard(
            enabled: false,
            onTap: () => tapCount++,
            child: const Text('CARBON_DISABLED'),
          ),
        ),
        const Size(1024, 768),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CarbonFiberCard));
    await tester.pumpAndSettle();
    expect(tapCount, 1);
  });

  testWidgets('GlassmorphicHudPanel renders BackdropFilter blur(14,14) and 16px radius', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTheme(
        const Center(
          child: GlassmorphicHudPanel(
            child: Text('LIVE_HUD_DATA'),
          ),
        ),
        const Size(1600, 900),
      ),
    );

    expect(find.text('LIVE_HUD_DATA'), findsOneWidget);
    final BackdropFilter filterWidget = tester.widget<BackdropFilter>(
      find.byType(BackdropFilter),
    );
    expect(filterWidget.filter, ImageFilter.blur(sigmaX: 14, sigmaY: 14));

    final ClipRRect clipWidget = tester.widget<ClipRRect>(
      find.byType(ClipRRect),
    );
    expect(clipWidget.borderRadius, BorderRadius.circular(16));
  });

  testWidgets('AnimatedStatBadge animates numeric value smoothly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTheme(
        const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedStatBadge(
                label: 'PWR/WT',
                value: 6.4,
                unit: 'W/kg',
                fractionDigits: 1,
                accentColor: AppColors.goldAccent,
              ),
              SizedBox(width: 12),
              AnimatedStatBadge(
                label: 'FTP',
                value: 415,
                unit: 'W',
                fractionDigits: 0,
                accentColor: AppColors.primaryAccent,
              ),
            ],
          ),
        ),
        const Size(390, 844),
      ),
    );

    expect(find.text('6.4'), findsOneWidget);
    expect(find.text('W/kg'), findsOneWidget);
    expect(find.text('415'), findsOneWidget);

    await tester.pumpWidget(
      wrapWithTheme(
        const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedStatBadge(
                label: 'PWR/WT',
                value: 7.0,
                unit: 'W/kg',
                fractionDigits: 1,
                accentColor: AppColors.goldAccent,
              ),
              SizedBox(width: 12),
              AnimatedStatBadge(
                label: 'FTP',
                value: 430,
                unit: 'W',
                fractionDigits: 0,
                accentColor: AppColors.primaryAccent,
              ),
            ],
          ),
        ),
        const Size(390, 844),
      ),
    );

    await tester.pump(const Duration(milliseconds: 160));
    await tester.pumpAndSettle();

    expect(find.text('7.0'), findsOneWidget);
    expect(find.text('430'), findsOneWidget);
  });

  for (final Size viewport in const <Size>[
    Size(390, 844),
    Size(1024, 768),
    Size(1600, 900),
  ]) {
    testWidgets(
      'Responsive layout renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithTheme(
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  CustomCarbonAndGlassContainers.carbonCard(
                    child: const Text('Card Content'),
                  ),
                  const SizedBox(height: 12),
                  CustomCarbonAndGlassContainers.glassHud(
                    child: const Text('Glass HUD'),
                  ),
                  const SizedBox(height: 12),
                  CustomCarbonAndGlassContainers.statBadge(
                    label: 'FTP',
                    value: 415,
                    unit: 'W',
                    fractionDigits: 0,
                    trendDelta: 12,
                  ),
                ],
              ),
            ),
            viewport,
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
