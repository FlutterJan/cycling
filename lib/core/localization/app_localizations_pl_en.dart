import 'package:flutter/material.dart';

/// Obsługiwane języki interfejsu i słownika kolarskiego gry.
enum AppLanguage {
  pl('PL', 'Polski', 'pl'),
  en('EN', 'English', 'en');

  final String code;
  final String nativeName;
  final String localeCode;

  const AppLanguage(this.code, this.nativeName, this.localeCode);

  Locale get locale => Locale(localeCode);

  String toJson() => name;

  static AppLanguage fromJson(String value) {
    final normalized = value.trim().toLowerCase();
    return AppLanguage.values.firstWhere(
      (lang) =>
          lang.name.toLowerCase() == normalized ||
          lang.code.toLowerCase() == normalized ||
          lang.localeCode.toLowerCase() == normalized,
      orElse: () => AppLanguage.pl,
    );
  }
}

/// Kategoria żargonu kolarskiego w słowniku PL/EN.
enum CyclingGlossaryCategory {
  tactics('Taktyka i Peleton', 'Tactics & Peloton'),
  physiology('Fizjologia i Żywienie', 'Physiology & Nutrition'),
  classifications('Klasyfikacje i Koszulki', 'Classifications & Jerseys'),
  weatherTerrain('Pogoda i Teren', 'Weather & Terrain'),
  equipment('Sprzęt i Mechanika', 'Equipment & Mechanics'),
  career('Kariera i Zarządzanie', 'Career & Management');

  final String labelPl;
  final String labelEn;

  const CyclingGlossaryCategory(this.labelPl, this.labelEn);

  String labelFor(AppLanguage language) =>
      language == AppLanguage.pl ? labelPl : labelEn;
}

/// Wpis w dwujęzycznym słowniku autentycznego żargonu kolarskiego.
class CyclingGlossaryEntry {
  final String key;
  final CyclingGlossaryCategory category;
  final String pl;
  final String en;
  final String descriptionPl;
  final String descriptionEn;

  const CyclingGlossaryEntry({
    required this.key,
    required this.category,
    required this.pl,
    required this.en,
    required this.descriptionPl,
    required this.descriptionEn,
  });

  String term(AppLanguage language) => language == AppLanguage.pl ? pl : en;

  String description(AppLanguage language) =>
      language == AppLanguage.pl ? descriptionPl : descriptionEn;
}

/// Kompletny system lokalizacji PL / EN oraz autentycznego żargonu kolarskiego.
///
/// Obsługuje natychmiastowe przełączanie języka pomiędzy Językiem Polskim (PL)
/// a Językiem Angielskim (EN) bez restartu aplikacji.
class AppLocalizationsPlEn {
  final AppLanguage language;

  const AppLocalizationsPlEn(this.language);

  static const AppLocalizationsPlEn pl = AppLocalizationsPlEn(AppLanguage.pl);
  static const AppLocalizationsPlEn en = AppLocalizationsPlEn(AppLanguage.en);

  factory AppLocalizationsPlEn.ofLanguage(AppLanguage language) {
    return language == AppLanguage.pl ? pl : en;
  }

  bool get isPolish => language == AppLanguage.pl;
  bool get isEnglish => language == AppLanguage.en;
  Locale get locale => language.locale;

  /// Słownik główny UI i terminologii wyścigowej (klucz -> {pl, en}).
  static const Map<String, ({String pl, String en})> _strings = {
    // --- Aplikacja & Język ---
    'app_title': (pl: 'Pro Peloton Manager', en: 'Pro Peloton Manager'),
    'language_label': (pl: 'Język gry', en: 'Game Language'),
    'language_pl': (pl: 'Polski (PL)', en: 'Polish (PL)'),
    'language_en': (pl: 'Angielski (EN)', en: 'English (EN)'),
    'language_short_pl': (pl: 'PL', en: 'PL'),
    'language_short_en': (pl: 'EN', en: 'EN'),
    'language_card_title': (
      pl: 'JĘZYK GRY I ŻARGON KOLARSKI (PL / EN)',
      en: 'GAME LANGUAGE & CYCLING JARGON (PL / EN)',
    ),
    'language_card_subtitle': (
      pl: 'Natychmiastowe przełączanie interfejsu oraz terminologii wyścigowej między językiem polskim a angielskim.',
      en: 'Instant UI and cycling terminology switching between Polish and English.',
    ),
    'language_active_badge': (
      pl: 'Aktywny: Polski',
      en: 'Active: English',
    ),
    'language_jargon_preview_title': (
      pl: 'Podgląd aktywnego słownika kolarskiego:',
      en: 'Active cycling jargon preview:',
    ),
    'language_switched_snackbar': (
      pl: 'Język gry zmieniony na Polski (PL)',
      en: 'Game language switched to English (EN)',
    ),

    // --- Ekran Ustawień i Modów (SettingsAndModScreen) ---
    'settings_header_title': (
      pl: 'USTAWIENIA & BAZA DANYCH (MODY)',
      en: 'SETTINGS & DATABASE (MODS)',
    ),
    'settings_header_main_mode': (
      pl: 'Tryb Główny Gry',
      en: 'Main Game Mode',
    ),
    'settings_header_career_subtitle': (
      pl: 'Kariera: {saveName} • Sezon {seasonYear}',
      en: 'Career: {saveName} • Season {seasonYear}',
    ),
    'settings_tab_graphics': (
      pl: 'Grafika 3D i Wydajność',
      en: '3D Graphics & Performance',
    ),
    'settings_tab_mods': (
      pl: 'Społeczność & Mody JSON',
      en: 'Community & JSON Mods',
    ),
    'settings_tab_riders': (
      pl: 'Edytor Kolarzy',
      en: 'Rider Editor',
    ),
    'settings_tab_teams': (
      pl: 'Edytor Drużyn i Barw',
      en: 'Team & Livery Editor',
    ),
    'settings_performance_profile': (
      pl: 'PROFIL WYDAJNOŚCIOWY',
      en: 'PERFORMANCE PROFILE',
    ),
    'settings_reset_defaults': (
      pl: 'Przywróć domyślne parametry fabryczne',
      en: 'Restore factory default settings',
    ),
    'settings_reset_snackbar': (
      pl: 'Przywrócono domyślne ustawienia (Zbalansowane 60 FPS).',
      en: 'Restored default settings (Balanced 60 FPS).',
    ),
    'settings_tutorial_title': (
      pl: 'INTERACTIVE RACE ACADEMY (SAMOUCZEK)',
      en: 'INTERACTIVE RACE ACADEMY (TUTORIAL)',
    ),
    'settings_tutorial_status_pending': (
      pl: 'Status: Aktywny podczas najbliższego wyścigu',
      en: 'Status: Active during next race',
    ),
    'settings_tutorial_status_completed': (
      pl: 'Status: Ukończono lub pominięto',
      en: 'Status: Completed or skipped',
    ),
    'settings_tutorial_status_disabled': (
      pl: 'Status: Podpowiedzi wyłączone',
      en: 'Status: Hints disabled',
    ),
    'settings_tutorial_desc': (
      pl: '6-krokowe szkolenie z fizyki draftingu, zapasu W\' i glikogenu, pociągu górskiego (5.8 W/kg), ciśnienia opon na bruku oraz planowania szczytu formy (TSB = CTL - ATL).',
      en: '6-step training covering drafting physics, W\' & glycogen reserves, mountain train (5.8 W/kg), cobble tire pressure, and peaking (TSB = CTL - ATL).',
    ),
    'settings_tutorial_launch_now': (
      pl: 'Uruchom Akademię teraz',
      en: 'Launch Academy Now',
    ),
    'settings_tutorial_show_next_race': (
      pl: 'Pokaż przy następnym wyścigu',
      en: 'Show at Next Race',
    ),
    'settings_tutorial_scheduled_snackbar': (
      pl: 'Interactive Race Academy zostanie uruchomiona automatycznie na starcie kolejnego wyścigu.',
      en: 'Interactive Race Academy will launch automatically at the start of the next race.',
    ),

    // --- Ustawienia grafiki & audio ---
    'graphics_shadow_quality': (
      pl: 'Jakość Cieni 3D',
      en: '3D Shadow Quality',
    ),
    'graphics_crowd_density': (
      pl: 'Gęstość Kibiców',
      en: 'Crowd Density',
    ),
    'graphics_target_fps': (
      pl: 'Limit Klatek (FPS)',
      en: 'Frame Rate Limit (FPS)',
    ),
    'graphics_battery_saver': (
      pl: 'Tryb Oszczędzania Baterii',
      en: 'Battery Saver Mode',
    ),
    'graphics_motion_blur': (
      pl: 'Rozmycie w Ruchu (Motion Blur)',
      en: 'Motion Blur',
    ),
    'graphics_particles': (
      pl: 'Efekty Cząsteczkowe (Deszcz / Kurz)',
      en: 'Particle Effects (Rain / Dust)',
    ),
    'graphics_bike_lod': (
      pl: 'Wysoki Detal Rowerów (LOD)',
      en: 'High Bike Detail (LOD)',
    ),
    'audio_settings_title': (
      pl: 'DŹWIĘK I RADIO WYŚCIGOWE',
      en: 'AUDIO & RACE RADIO',
    ),
    'audio_master_volume': (
      pl: 'Głośność Ogólna (Master)',
      en: 'Master Volume',
    ),
    'audio_environment_volume': (
      pl: 'Otoczenie (Wiatr, Koła, Bębenek)',
      en: 'Environment (Wind, Wheels, Freehub)',
    ),
    'audio_crowd_volume': (
      pl: 'Atmosfera Kibiców',
      en: 'Crowd Atmosphere',
    ),
    'audio_radio_volume': (
      pl: 'Radio Wyścigowe i Alarmy Garmin',
      en: 'Race Radio & Garmin Alerts',
    ),
    'audio_ui_volume': (
      pl: 'Dźwięki Interfejsu',
      en: 'UI Sounds',
    ),

    // --- Autentyczny Żargon Kolarski (Kluczowe pojęcia z #203) ---
    'jargon_echelons': (pl: 'Wachlarze', en: 'Echelons'),
    'jargon_crosswinds': (pl: 'Ranty', en: 'Crosswinds'),
    'jargon_sticky_bottle': (
      pl: 'Spłynięcie po bidony',
      en: 'Sticky bottle',
    ),
    'jargon_day_condition': (pl: 'Noga dnia', en: 'Day condition'),
    'jargon_sprint_train': (
      pl: 'Pociąg sprinterski',
      en: 'Lead-out train',
    ),
    'jargon_wheel_to_wheel': (pl: 'Koło w koło', en: 'Wheel-to-wheel'),
    'jargon_bonking': (pl: 'Odcięcie prądu', en: 'Bonking'),
    'jargon_polka_dot_jersey': (
      pl: 'Koszulka w grochy',
      en: 'Polka-dot jersey',
    ),
    'jargon_gc': (
      pl: 'Klasyfikacja generalna',
      en: 'GC',
    ),
    'jargon_gc_full': (
      pl: 'Klasyfikacja generalna (GC)',
      en: 'General Classification (GC)',
    ),

    // --- Dodatkowy Żargon Kolarski i Taktyka Wyścigu ---
    'jargon_peloton': (pl: 'Peleton', en: 'Peloton'),
    'jargon_breakaway': (pl: 'Ucieczka / Odjazd', en: 'Breakaway'),
    'jargon_grupetto': (pl: 'Grupetto (Autobus)', en: 'Gruppetto (The Bus)'),
    'jargon_domestique': (pl: 'Pomocnik (Gregario)', en: 'Domestique'),
    'jargon_road_captain': (pl: 'Kapitan drogi', en: 'Road captain'),
    'jargon_flamme_rouge': (
      pl: 'Flamme Rouge (Ostatni kilometr)',
      en: 'Flamme Rouge (Final kilometer)',
    ),
    'jargon_lanterne_rouge': (pl: 'Czerwona latarnia', en: 'Lanterne rouge'),
    'jargon_feed_zone': (pl: 'Strefa bufetu', en: 'Feed zone'),
    'jargon_cobbles': (pl: 'Bruk / Sektory brukowane', en: 'Cobbles / Pavé'),
    'jargon_hors_categorie': (
      pl: 'Podjazd Hors Catégorie (HC)',
      en: 'Hors Catégorie (HC) climb',
    ),
    'jargon_drafting': (pl: 'Jazda na kole (Drafting)', en: 'Drafting'),
    'jargon_pull_turn': (pl: 'Zmiana na czele', en: 'Pull at the front'),
    'jargon_attack': (pl: 'Atak / Skok', en: 'Attack / Surge'),
    'jargon_counter_attack': (pl: 'Kontratak', en: 'Counter-attack'),
    'jargon_bridge_gap': (pl: 'Przeskok do odjazdu', en: 'Bridge the gap'),
    'jargon_chase_down': (pl: 'Pogoń i kasowanie ucieczki', en: 'Reel in the break'),
    'jargon_sit_on_wheel': (pl: 'Wieźć się na kole', en: 'Sit on the wheel'),
    'jargon_time_gap': (pl: 'Strata czasowa', en: 'Time gap'),
    'jargon_photo_finish': (pl: 'Fotofinisz', en: 'Photo finish'),
    'jargon_itt': (
      pl: 'Jazda indywidualna na czas (ITT)',
      en: 'Individual Time Trial (ITT)',
    ),
    'jargon_ttt': (
      pl: 'Jazda drużynowa na czas (TTT)',
      en: 'Team Time Trial (TTT)',
    ),

    // --- Koszulki i Klasyfikacje ---
    'jersey_yellow': (
      pl: 'Żółta koszulka lidera (GC)',
      en: 'Yellow Leader Jersey (GC)',
    ),
    'jersey_green': (
      pl: 'Zielona koszulka punktowa',
      en: 'Green Points Jersey',
    ),
    'jersey_polka_dot': (
      pl: 'Koszulka w grochy (Górska)',
      en: 'Polka-Dot Jersey (KOM)',
    ),
    'jersey_white': (
      pl: 'Biała koszulka młodzieżowa',
      en: 'White Youth Jersey',
    ),
    'jersey_rainbow': (
      pl: 'Tęczowa koszulka Mistrza Świata',
      en: 'World Champion Rainbow Jersey',
    ),

    // --- Fizjologia, Telemetria i Sprzęt ---
    'phys_ftp': (pl: 'Próg FTP (W)', en: 'FTP Threshold (W)'),
    'phys_w_per_kg': (
      pl: 'Stosunek mocy do masy (W/kg)',
      en: 'Power-to-Weight (W/kg)',
    ),
    'phys_w_prime': (
      pl: 'Zapas beztlenowy W\'',
      en: 'Anaerobic Reserve W\'',
    ),
    'phys_glycogen': (
      pl: 'Zapasy glikogenu (kcal)',
      en: 'Glycogen Stores (kcal)',
    ),
    'phys_heart_rate': (pl: 'Tętno (BPM)', en: 'Heart Rate (BPM)'),
    'phys_cadence': (pl: 'Kadencja (RPM)', en: 'Cadence (RPM)'),
    'phys_vam': (
      pl: 'Prędkość wznoszenia (VAM)',
      en: 'Vertical Ascent Speed (VAM)',
    ),
    'phys_cda': (
      pl: 'Współczynnik oporu aero (CdA)',
      en: 'Aerodynamic Drag Area (CdA)',
    ),
    'phys_crr': (
      pl: 'Opór toczenia opon (Crr)',
      en: 'Rolling Resistance (Crr)',
    ),
    'phys_tire_pressure': (
      pl: 'Ciśnienie w oponach (BAR / PSI)',
      en: 'Tire Pressure (BAR / PSI)',
    ),

    // --- Nawigacja i Akcje Ogólne ---
    'nav_hq': (pl: 'Centrum Dowodzenia', en: 'Team HQ'),
    'nav_squad': (pl: 'Skład Drużyny', en: 'Squad Roster'),
    'nav_calendar': (pl: 'Kalendarz Sezonu', en: 'Season Calendar'),
    'nav_transfers': (pl: 'Rynek Transferowy', en: 'Transfer Market'),
    'nav_equipment': (pl: 'Garaż i Tunel Aero', en: 'Garage & Wind Tunnel'),
    'nav_medical': (pl: 'Centrum Medyczne', en: 'Medical Center'),
    'nav_settings': (pl: 'Ustawienia', en: 'Settings'),
    'action_save': (pl: 'Zapisz', en: 'Save'),
    'action_cancel': (pl: 'Anuluj', en: 'Cancel'),
    'action_apply': (pl: 'Zastosuj', en: 'Apply'),
    'action_close': (pl: 'Zamknij', en: 'Close'),
    'action_continue': (pl: 'Kontynuuj', en: 'Continue'),
    'action_start_race': (pl: 'Rozpocznij Wyścig', en: 'Start Race'),
  };

  /// Kompletny glosariusz autentycznego żargonu kolarskiego PL <-> EN.
  static const List<CyclingGlossaryEntry> cyclingGlossary = [
    CyclingGlossaryEntry(
      key: 'jargon_echelons',
      category: CyclingGlossaryCategory.tactics,
      pl: 'Wachlarze',
      en: 'Echelons',
      descriptionPl:
          'Ukośna formacja kolarzy przy silnym wietrze bocznym, gdzie każdy chroni koło kolejnego aż do krawędzi szosy.',
      descriptionEn:
          'Diagonal line of riders in strong crosswinds, each sheltering the wheel behind until the road edge.',
    ),
    CyclingGlossaryEntry(
      key: 'jargon_crosswinds',
      category: CyclingGlossaryCategory.weatherTerrain,
      pl: 'Ranty',
      en: 'Crosswinds',
      descriptionPl:
          'Silne wiatry boczne rozrywające peleton na mniejsze grupy i zmuszające do jazdy po krawędzi asfaltu.',
      descriptionEn:
          'Strong sidewinds splitting the peloton into fractured groups along the gutter of the road.',
    ),
    CyclingGlossaryEntry(
      key: 'jargon_sticky_bottle',
      category: CyclingGlossaryCategory.tactics,
      pl: 'Spłynięcie po bidony',
      en: 'Sticky bottle',
      descriptionPl:
          'Powrót do wozu technicznego po napoje i żele dla liderów oraz subtelne podciągnięcie przy odbiorze bidonu.',
      descriptionEn:
          'Dropping back to the team car for bottles and gels, often holding onto the bottle a fraction longer for momentum.',
    ),
    CyclingGlossaryEntry(
      key: 'jargon_day_condition',
      category: CyclingGlossaryCategory.physiology,
      pl: 'Noga dnia',
      en: 'Day condition',
      descriptionPl:
          'Chwilowa dyspozycja fizjologiczna i samopoczucie kolarza na konkretnym etapie (-5 do +5).',
      descriptionEn:
          'Daily physiological readiness and race legs on a given stage (-5 to +5).',
    ),
    CyclingGlossaryEntry(
      key: 'jargon_sprint_train',
      category: CyclingGlossaryCategory.tactics,
      pl: 'Pociąg sprinterski',
      en: 'Lead-out train',
      descriptionPl:
          'Zorganizowany szyk pomocników rozprowadzających sprintera na wysoką prędkość przed finałową prostą.',
      descriptionEn:
          'Coordinated line of teammates delivering the sprinter at maximum speed to the final straight.',
    ),
    CyclingGlossaryEntry(
      key: 'jargon_wheel_to_wheel',
      category: CyclingGlossaryCategory.tactics,
      pl: 'Koło w koło',
      en: 'Wheel-to-wheel',
      descriptionPl:
          'Bezpośrednia, zacięta walka bark w bark na końcowych metrach lub kluczowych sektorach trasy.',
      descriptionEn:
          'Close-quarters, head-to-head battle for position on decisive sectors or the finish sprint.',
    ),
    CyclingGlossaryEntry(
      key: 'jargon_bonking',
      category: CyclingGlossaryCategory.physiology,
      pl: 'Odcięcie prądu',
      en: 'Bonking',
      descriptionPl:
          'Gwałtowny spadek mocy spowodowany całkowitym wyczerpaniem glikogenu mięśniowego ("ściana").',
      descriptionEn:
          'Sudden catastrophic loss of power due to complete glycogen depletion ("hitting the wall").',
    ),
    CyclingGlossaryEntry(
      key: 'jargon_polka_dot_jersey',
      category: CyclingGlossaryCategory.classifications,
      pl: 'Koszulka w grochy',
      en: 'Polka-dot jersey',
      descriptionPl:
          'Wyróżnienie dla najlepszego górala (KOM), lidera klasyfikacji górskiej na premiach wspinaczkowych.',
      descriptionEn:
          'King of the Mountains (KOM) jersey awarded to the leader of the climbing classification.',
    ),
    CyclingGlossaryEntry(
      key: 'jargon_gc',
      category: CyclingGlossaryCategory.classifications,
      pl: 'Klasyfikacja generalna',
      en: 'GC',
      descriptionPl:
          'Główna klasyfikacja wyścigu wieloetapowego liczona według najniższego łącznego czasu przejazdu.',
      descriptionEn:
          'General Classification (GC): the primary overall race standings ranked by lowest cumulative time.',
    ),
    CyclingGlossaryEntry(
      key: 'jargon_grupetto',
      category: CyclingGlossaryCategory.tactics,
      pl: 'Grupetto (Autobus)',
      en: 'Gruppetto (The Bus)',
      descriptionPl:
          'Grupa sprinterów i zmęczonych kolarzy jadących wspólnie w górach, by zmieścić się w limicie czasu.',
      descriptionEn:
          'Group of sprinters and dropped riders working together on mountain stages to make the time cut.',
    ),
    CyclingGlossaryEntry(
      key: 'jargon_flamme_rouge',
      category: CyclingGlossaryCategory.weatherTerrain,
      pl: 'Flamme Rouge (Ostatni kilometr)',
      en: 'Flamme Rouge (Final kilometer)',
      descriptionPl:
          'Czerwona chorągiewka lub brama oznaczająca dokładnie 1000 metrów do linii mety.',
      descriptionEn:
          'Red pennant or inflatable arch marking the final 1,000 meters to the finish line.',
    ),
    CyclingGlossaryEntry(
      key: 'jargon_domestique',
      category: CyclingGlossaryCategory.career,
      pl: 'Pomocnik (Gregario)',
      en: 'Domestique',
      descriptionPl:
          'Kolarz poświęcający własne szanse na rzecz ochrony lidera, wożenia bidonów i nadawania tempa.',
      descriptionEn:
          'Support rider sacrificing personal ambitions to protect the leader, fetch bottles, and set pace.',
    ),
  ];

  /// Zwraca przetłumaczony tekst dla podanego klucza (z bezpiecznym fallbackiem).
  String t(String key) {
    final entry = _strings[key];
    if (entry != null) {
      return isPolish ? entry.pl : entry.en;
    }
    return key;
  }

  /// Operator indeksowania dla zwięzłego odczytu kluczy: `l10n['jargon_echelons']`.
  String operator [](String key) => t(key);

  /// Zwraca wszystkie dostępne klucze w słowniku.
  Iterable<String> get availableKeys => _strings.keys;

  /// Zwraca liczbę haseł w głównym słowniku UI i żargonu.
  int get dictionarySize => _strings.length;

  /// Zwraca tekst z podstawionymi parametrami `{name}`.
  String format(String key, Map<String, Object> params) {
    var result = t(key);
    params.forEach((paramKey, paramValue) {
      result = result.replaceAll('{$paramKey}', paramValue.toString());
    });
    return result;
  }

  /// Wyszukuje hasła w glosariuszu żargonu kolarskiego (po PL, EN lub opisie).
  List<CyclingGlossaryEntry> searchGlossary(
    String query, {
    CyclingGlossaryCategory? category,
  }) {
    final normalized = query.trim().toLowerCase();
    return cyclingGlossary.where((entry) {
      if (category != null && entry.category != category) return false;
      if (normalized.isEmpty) return true;
      return entry.pl.toLowerCase().contains(normalized) ||
          entry.en.toLowerCase().contains(normalized) ||
          entry.descriptionPl.toLowerCase().contains(normalized) ||
          entry.descriptionEn.toLowerCase().contains(normalized);
    }).toList(growable: false);
  }

  // ===========================================================================
  // Silnie typowane gettery kluczowego żargonu kolarskiego (PL <-> EN)
  // ===========================================================================

  String get echelons => t('jargon_echelons');
  String get crosswinds => t('jargon_crosswinds');
  String get stickyBottle => t('jargon_sticky_bottle');
  String get dayCondition => t('jargon_day_condition');
  String get sprintTrain => t('jargon_sprint_train');
  String get wheelToWheel => t('jargon_wheel_to_wheel');
  String get bonking => t('jargon_bonking');
  String get polkaDotJersey => t('jargon_polka_dot_jersey');
  String get generalClassification => t('jargon_gc');
  String get generalClassificationFull => t('jargon_gc_full');
  String get peloton => t('jargon_peloton');
  String get breakaway => t('jargon_breakaway');
  String get grupetto => t('jargon_grupetto');
  String get domestique => t('jargon_domestique');
  String get roadCaptain => t('jargon_road_captain');
  String get flammeRouge => t('jargon_flamme_rouge');
  String get lanterneRouge => t('jargon_lanterne_rouge');
  String get feedZone => t('jargon_feed_zone');
  String get cobbles => t('jargon_cobbles');
  String get horsCategorie => t('jargon_hors_categorie');
  String get drafting => t('jargon_drafting');
  String get yellowJersey => t('jersey_yellow');
  String get greenJersey => t('jersey_green');
  String get whiteJersey => t('jersey_white');
  String get rainbowJersey => t('jersey_rainbow');

  // ===========================================================================
  // Silnie typowane gettery UI dla SettingsAndModScreen
  // ===========================================================================

  String get settingsHeaderTitle => t('settings_header_title');
  String get settingsHeaderMainMode => t('settings_header_main_mode');
  String settingsHeaderCareerSubtitle(String saveName, int seasonYear) =>
      format('settings_header_career_subtitle', {
        'saveName': saveName,
        'seasonYear': seasonYear,
      });

  String get settingsTabGraphics => t('settings_tab_graphics');
  String get settingsTabMods => t('settings_tab_mods');
  String get settingsTabRiders => t('settings_tab_riders');
  String get settingsTabTeams => t('settings_tab_teams');
  String get settingsPerformanceProfile => t('settings_performance_profile');
  String get settingsResetDefaults => t('settings_reset_defaults');
  String get settingsResetSnackbar => t('settings_reset_snackbar');
  String get languageCardTitle => t('language_card_title');
  String get languageCardSubtitle => t('language_card_subtitle');
  String get languageActiveBadge => t('language_active_badge');
  String get languageJargonPreviewTitle => t('language_jargon_preview_title');
  String get languageSwitchedSnackbar => t('language_switched_snackbar');
}

/// InheritedWidget udostępniający [AppLocalizationsPlEn] bez potrzeby Riverpoda w podwidżetach.
class AppLocalizationsScope extends InheritedWidget {
  final AppLocalizationsPlEn localizations;

  const AppLocalizationsScope({
    super.key,
    required this.localizations,
    required super.child,
  });

  static AppLocalizationsPlEn of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppLocalizationsScope>();
    return scope?.localizations ?? AppLocalizationsPlEn.pl;
  }

  @override
  bool updateShouldNotify(covariant AppLocalizationsScope oldWidget) {
    return oldWidget.localizations.language != localizations.language;
  }
}

/// Wygodne rozszerzenie na [BuildContext] do natychmiastowego dostępu do tłumaczeń.
extension AppLocalizationsContext on BuildContext {
  AppLocalizationsPlEn get l10n => AppLocalizationsScope.of(this);
}
