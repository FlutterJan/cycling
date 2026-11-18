import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/l10n/app_localizations_pl_en.dart';

void main() {
  group('BilingualCyclingDictionary', () {
    test('passes completeness and uniqueness audit', () {
      final report = BilingualCyclingDictionary.auditCompleteness();
      expect(report.isComplete, isTrue);
      expect(report.emptyOrInvalidKeys, isEmpty);
      expect(report.duplicateKeys, isEmpty);
      expect(report.totalUiKeys, greaterThanOrEqualTo(60));
      expect(report.totalJargonEntries, greaterThanOrEqualTo(30));
    });

    test('translates UI keys in PL and EN with parameter interpolation', () {
      expect(
        BilingualCyclingDictionary.translate('order_form_echelon', AppLanguage.pl),
        'Uformuj rant (Wachlarz)',
      );
      expect(
        BilingualCyclingDictionary.translate('order_form_echelon', AppLanguage.en),
        'Form Echelon',
      );
      expect(
        BilingualCyclingDictionary.translate(
          'l10n_copied_feedback',
          AppLanguage.en,
          params: {'term': 'Echelons'},
        ),
        'Copied to clipboard: Echelons',
      );
      // Fallback to AppLocalizationsPlEn
      expect(
        BilingualCyclingDictionary.translate('jargon_sticky_bottle', AppLanguage.pl),
        'Spłynięcie po bidony',
      );
    });

    test('pluralizes Polish and English nouns accurately', () {
      String plStages(int n) => BilingualCyclingDictionary.pluralize(
            AppLanguage.pl,
            n,
            plOne: 'etap',
            plFew: 'etapy',
            plMany: 'etapów',
            enOne: 'stage',
            enMany: 'stages',
          );

      expect(plStages(1), '1 etap');
      expect(plStages(2), '2 etapy');
      expect(plStages(4), '4 etapy');
      expect(plStages(5), '5 etapów');
      expect(plStages(12), '12 etapów');
      expect(plStages(22), '22 etapy');
      expect(plStages(25), '25 etapów');

      expect(
        BilingualCyclingDictionary.pluralize(
          AppLanguage.en,
          1,
          plOne: 'etap',
          plFew: 'etapy',
          plMany: 'etapów',
          enOne: 'stage',
          enMany: 'stages',
        ),
        '1 stage',
      );
      expect(
        BilingualCyclingDictionary.pluralize(
          AppLanguage.en,
          21,
          plOne: 'etap',
          plFew: 'etapy',
          plMany: 'etapów',
          enOne: 'stage',
          enMany: 'stages',
        ),
        '21 stages',
      );
    });

    test('searches cycling jargon by query and domain', () {
      final echelonResults = BilingualCyclingDictionary.searchJargon('waaier');
      expect(echelonResults.any((e) => e.key == 'echelons'), isTrue);

      final juryResults = BilingualCyclingDictionary.searchJargon(
        'bidon',
        domain: AppL10nDomain.juryEtiquette,
      );
      expect(juryResults.length, 1);
      expect(juryResults.first.key, 'sticky_bottle');
    });

    test('AppL10nDelegate supports pl and en locales', () async {
      const delegate = AppL10nDelegate();
      expect(delegate.isSupported(const Locale('pl')), isTrue);
      expect(delegate.isSupported(const Locale('en')), isTrue);
      expect(delegate.isSupported(const Locale('fr')), isFalse);

      final plL10n = await delegate.load(const Locale('pl'));
      final enL10n = await delegate.load(const Locale('en'));
      expect(plL10n.isPolish, isTrue);
      expect(enL10n.isEnglish, isTrue);
    });

    test('covers Package 6 & 7 UI keys, jargon entries, and hasKey helper', () {
      expect(BilingualCyclingDictionary.hasKey('multi_online_leagues'), isTrue);
      expect(BilingualCyclingDictionary.hasKey('disc_mtb_xco'), isTrue);
      expect(BilingualCyclingDictionary.hasKey('brand_inhouse_factory'), isTrue);
      expect(BilingualCyclingDictionary.hasKey('jury_sprint_var'), isTrue);
      expect(BilingualCyclingDictionary.hasKey('org_hq_title'), isTrue);
      expect(BilingualCyclingDictionary.hasKey('disc_ultra_bikepacking'), isTrue);
      expect(BilingualCyclingDictionary.hasKey('nonexistent_key_xyz'), isFalse);

      expect(
        BilingualCyclingDictionary.translate('jury_sprint_var', AppLanguage.pl),
        'Analiza Wideo Sprint VAR',
      );
      expect(
        BilingualCyclingDictionary.translate('jury_sprint_var', AppLanguage.en),
        'Sprint Deviation VAR',
      );
      expect(
        BilingualCyclingDictionary.searchJargon('rock garden')
            .any((e) => e.key == 'rock_garden_a_line'),
        isTrue,
      );
    });

    test('covers Package 9 UI keys and jargon entries', () {
      const package9Keys = [
        'exotic_tours_expansion_title',
        'exotic_tour_rwanda_kigali',
        'exotic_tour_langkawi_humidity',
        'exotic_tour_alula_oman',
        'exotic_tour_poland_central_eu',
        'emerging_market_sponsors',
        'chemistry_locker_room_web',
        'chemistry_blood_brothers_pact',
        'chemistry_bonding_mediation',
        'what_if_monte_carlo_title',
        'paracycling_world_cup_title',
        'paracycling_tandem_class_b',
        'paracycling_handbike_h1_h5',
        'hud_split_screen_telemetry',
        'tactic_poker_face_bluff',
        'tactic_gutter_collision_risk',
        'neutral_zone_3km_banner',
        'club_museum_legendary_bikes',
        'equipment_serial_gold_edition',
        'scouting_rival_ds_styles',
        'tv_highlight_reel_45s',
        'training_weekly_microcycle',
        'training_motor_pacing_aero',
        'scouting_global_talent_combine',
        'audio_adaptive_music_6ch',
        'analytics_deep_bi_roi',
        'ui_save_v9_migrator',
      ];
      for (final key in package9Keys) {
        expect(BilingualCyclingDictionary.hasKey(key), isTrue, reason: key);
      }

      expect(
        BilingualCyclingDictionary.translate(
          'neutral_zone_3km_banner',
          AppLanguage.pl,
        ),
        'STREFA 3 KM — CZASY GC ZNEUTRALIZOWANE',
      );
      expect(
        BilingualCyclingDictionary.translate(
          'neutral_zone_3km_banner',
          AppLanguage.en,
        ),
        '3 KM ZONE — GC TIMES NEUTRALIZED',
      );
      expect(
        BilingualCyclingDictionary.searchJargon('kigali')
            .any((e) => e.key == 'mur_de_kigali_cobbles'),
        isTrue,
      );
      expect(
        BilingualCyclingDictionary.searchJargon('blood brothers')
            .any((e) => e.key == 'blood_brothers_pact'),
        isTrue,
      );
      expect(
        BilingualCyclingDictionary.searchJargon('poker face')
            .any((e) => e.key == 'poker_face_sandbagging'),
        isTrue,
      );
      expect(
        BilingualCyclingDictionary.searchJargon('motor-pacing')
            .any((e) => e.key == 'motor_pacing_derny'),
        isTrue,
      );
    });
  });

  group('CyclingJargonDictionaryPanel responsive UI', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CyclingJargonDictionaryPanel(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders without overflow on 390x844 mobile', (tester) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(find.byType(CyclingJargonDictionaryPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on 1024x768 tablet', (tester) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.byType(CyclingJargonDictionaryPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on 1600x900 desktop and switches PL/EN',
        (tester) async {
      await pumpAtSize(tester, const Size(1600, 900));
      expect(find.text('Ranty / Wachlarze'), findsWidgets);

      await tester.tap(find.text('EN').first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Echelons'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
