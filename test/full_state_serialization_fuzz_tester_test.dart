import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/full_state_serialization_fuzz_tester.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      return Directory.systemTemp.path;
    });
  });

  group('FullStateSerializationFuzzTester', () {
    test('runs full 18-iteration fuzz campaign with zero diffs and zero crashes',
        () async {
      final report = await FullStateSerializationFuzzTester.runFuzzCampaign(
        config: const FuzzCampaignConfig(
          baseSeed: 20260409,
          iterations: 18,
          includeSubModels: true,
        ),
      );

      expect(report.totalIterations, 18);
      expect(report.diffCount, 0, reason: report.summaryText);
      expect(report.crashCount, 0, reason: report.summaryText);
      expect(report.isSuccess, isTrue, reason: report.summaryText);
      expect(report.totalPathsChecked, greaterThan(100));
      expect(report.uniqueKeysCovered, greaterThan(20));
      expect(report.toJson()['isSuccess'], isTrue);
    });

    test('tryParseCareerSaveSafe handles malformed JSON payloads gracefully',
        () {
      expect(
        FullStateSerializationFuzzTester.tryParseCareerSaveSafe('').isSuccess,
        isFalse,
      );
      expect(
        FullStateSerializationFuzzTester.tryParseCareerSaveSafe('[1, 2, 3]')
            .isSuccess,
        isFalse,
      );
      expect(
        FullStateSerializationFuzzTester.tryParseCareerSaveSafe('{broken')
            .isSuccess,
        isFalse,
      );
      expect(
        FullStateSerializationFuzzTester.tryParseCareerSaveSafe(
          '{"id": 999, "saveName": null}',
        ).isSuccess,
        isFalse,
      );
    });

    test('compareJsonTrees detects structural diffs and respects float tolerance',
        () {
      final diffs = <FuzzJsonDiff>[];
      final a = <String, dynamic>{
        'name': 'Test',
        'score': 12.3456789,
        'items': [1, 2],
      };
      final b = <String, dynamic>{
        'name': 'Test',
        'score': 12.3456788, // within 1e-6 tolerance
        'items': [1, 2],
      };
      FullStateSerializationFuzzTester.compareJsonTrees(
        a,
        b,
        path: r'$',
        diffs: diffs,
      );
      expect(diffs, isEmpty);

      final c = <String, dynamic>{
        'name': 'Changed',
        'items': [1],
        'extra': true,
      };
      FullStateSerializationFuzzTester.compareJsonTrees(
        a,
        c,
        path: r'$',
        diffs: diffs,
      );
      expect(diffs.length, greaterThanOrEqualTo(3));
    });
  });

  group('FullStateSerializationFuzzTesterPanel UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.darkTheme,
                home: const Scaffold(
                  body: FullStateSerializationFuzzTesterPanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(
            find.text('Fuzzer Serializacji Stanu Kariery JSON'),
            findsOneWidget,
          );
          expect(find.text('Uruchom Fuzzing'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
