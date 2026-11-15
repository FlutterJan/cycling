import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/localization/app_localizations_pl_en.dart';
import 'package:pro_peloton_manager/models/settings/game_settings.dart';
import 'package:pro_peloton_manager/state/game_settings_notifier.dart';
import 'package:pro_peloton_manager/ui/screens/settings_and_mod_screen.dart';

class _InMemorySettingsStorage implements GameSettingsStorage {
  GameSettings? saved;

  @override
  Future<GameSettings?> load() async => saved;

  @override
  Future<void> save(GameSettings settings) async {
    saved = settings;
  }
}

void main() {
  group('AppLocalizationsPlEn Dictionary & Cycling Jargon', () {
    test('zawiera kompletny autentyczny żargon kolarski PL <-> EN', () {
      const pl = AppLocalizationsPlEn.pl;
      const en = AppLocalizationsPlEn.en;

      expect(pl.echelons, 'Wachlarze');
      expect(en.echelons, 'Echelons');

      expect(pl.crosswinds, 'Ranty');
      expect(en.crosswinds, 'Crosswinds');

      expect(pl.stickyBottle, 'Spłynięcie po bidony');
      expect(en.stickyBottle, 'Sticky bottle');

      expect(pl.dayCondition, 'Noga dnia');
      expect(en.dayCondition, 'Day condition');

      expect(pl.sprintTrain, 'Pociąg sprinterski');
      expect(en.sprintTrain, 'Lead-out train');

      expect(pl.wheelToWheel, 'Koło w koło');
      expect(en.wheelToWheel, 'Wheel-to-wheel');

      expect(pl.bonking, 'Odcięcie prądu');
      expect(en.bonking, 'Bonking');

      expect(pl.polkaDotJersey, 'Koszulka w grochy');
      expect(en.polkaDotJersey, 'Polka-dot jersey');

      expect(pl.generalClassification, 'Klasyfikacja generalna');
      expect(en.generalClassification, 'GC');
    });

    test('wyszukiwanie w glosariuszu oraz formatowanie parametrów działa poprawnie', () {
      const en = AppLocalizationsPlEn.en;
      expect(
        en.settingsHeaderCareerSubtitle('Polski Projekt', 2027),
        'Career: Polski Projekt • Season 2027',
      );

      final matches = en.searchGlossary('bonking');
      expect(matches, hasLength(1));
      expect(matches.first.pl, 'Odcięcie prądu');
    });

    test('GameSettings serializuje i odtwarza język gry oraz zachowuje go przy zmianie presetu', () async {
      final storage = _InMemorySettingsStorage();
      final notifier = GameSettingsNotifier.withStorage(storage: storage);

      expect(notifier.state.language, AppLanguage.pl);

      notifier.setLanguage(AppLanguage.en);
      await notifier.pendingSave;

      expect(notifier.state.language, AppLanguage.en);
      expect(storage.saved?.language, AppLanguage.en);

      final restored = GameSettings.fromJsonString(storage.saved!.toJsonString());
      expect(restored.language, AppLanguage.en);

      notifier.applyPreset(GraphicsPreset.highQuality);
      expect(notifier.state.language, AppLanguage.en);

      notifier.toggleLanguage();
      expect(notifier.state.language, AppLanguage.pl);
    });
  });

  group('SettingsAndModScreen PL / EN Switcher', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'natychmiastowo przełącza język PL / EN bez przepełnień w ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final storage = _InMemorySettingsStorage();
          final container = ProviderContainer(
            overrides: [
              gameSettingsProvider.overrideWith(
                (ref) => GameSettingsNotifier.withStorage(storage: storage),
              ),
            ],
          );
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(
                home: SettingsAndModScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('USTAWIENIA & BAZA DANYCH (MODY)'), findsOneWidget);
          expect(find.text('Wachlarze'), findsOneWidget);
          expect(find.text('Odcięcie prądu'), findsOneWidget);

          await tester.tap(find.text('EN').first);
          await tester.pumpAndSettle();

          expect(container.read(appLanguageProvider), AppLanguage.en);
          expect(find.text('SETTINGS & DATABASE (MODS)'), findsOneWidget);
          expect(find.text('Echelons'), findsOneWidget);
          expect(find.text('Bonking'), findsOneWidget);

          await tester.tap(find.text('PL').first);
          await tester.pumpAndSettle();

          expect(container.read(appLanguageProvider), AppLanguage.pl);
          expect(find.text('USTAWIENIA & BAZA DANYCH (MODY)'), findsOneWidget);
        },
      );
    }
  });
}
