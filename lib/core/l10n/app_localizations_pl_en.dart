import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../localization/app_localizations_pl_en.dart';
import '../theme/app_colors.dart';

export '../localization/app_localizations_pl_en.dart';

/// Domeny tematyczne pełnego dwujęzycznego słownika lokalizacyjnego PL/EN.
enum AppL10nDomain {
  raceHud('HUD Wyścigu i Telemetria', 'Race HUD & Telemetry', Icons.speed),
  pelotonTactics(
    'Taktyka Peletonu i Dyplomacja',
    'Peloton Tactics & Diplomacy',
    Icons.alt_route,
  ),
  physiologyNutrition(
    'Fizjologia, Mleczan i Żywienie',
    'Physiology, Lactate & Nutrition',
    Icons.monitor_heart_outlined,
  ),
  equipmentMechanics(
    'Sprzęt, Aero i Mechanika',
    'Equipment, Aero & Mechanics',
    Icons.build_circle_outlined,
  ),
  disciplines(
    'Szosa, CX, Gravel, MTB, Tor i Ultra',
    'Road, CX, Gravel, MTB, Track & Ultra',
    Icons.directions_bike,
  ),
  careerManagement(
    'Kariera, Organizator, Ligi i Transfery',
    'Career, Organizer, Leagues & Transfers',
    Icons.emoji_events_outlined,
  ),
  juryEtiquette(
    'Sędziowie UCI, Etykieta i Pogoda',
    'UCI Jury, Etiquette & Weather',
    Icons.gavel_outlined,
  ),
  uiSystem(
    'Interfejs, Dostępność i Mody',
    'UI, Accessibility & Mods',
    Icons.tune,
  );

  final String labelPl;
  final String labelEn;
  final IconData icon;

  const AppL10nDomain(this.labelPl, this.labelEn, this.icon);

  String label(AppLanguage language) =>
      language == AppLanguage.pl ? labelPl : labelEn;
}

/// Rozszerzony wpis dwujęzycznego słownika żargonu kolarskiego PL/EN.
class BilingualTermEntry {
  final String key;
  final AppL10nDomain domain;
  final String pl;
  final String en;
  final String? slangOrOrigin;
  final String definitionPl;
  final String definitionEn;
  final String examplePl;
  final String exampleEn;

  const BilingualTermEntry({
    required this.key,
    required this.domain,
    required this.pl,
    required this.en,
    this.slangOrOrigin,
    required this.definitionPl,
    required this.definitionEn,
    required this.examplePl,
    required this.exampleEn,
  });

  String term(AppLanguage language) => language == AppLanguage.pl ? pl : en;

  String definition(AppLanguage language) =>
      language == AppLanguage.pl ? definitionPl : definitionEn;

  String example(AppLanguage language) =>
      language == AppLanguage.pl ? examplePl : exampleEn;

  bool matchesQuery(String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;
    return key.toLowerCase().contains(normalizedQuery) ||
        pl.toLowerCase().contains(normalizedQuery) ||
        en.toLowerCase().contains(normalizedQuery) ||
        (slangOrOrigin?.toLowerCase().contains(normalizedQuery) ?? false) ||
        definitionPl.toLowerCase().contains(normalizedQuery) ||
        definitionEn.toLowerCase().contains(normalizedQuery);
  }
}

/// Raport kompletności i spójności słownika dwujęzycznego PL/EN.
class DictionaryCompletenessReport {
  final int totalUiKeys;
  final int totalJargonEntries;
  final List<String> emptyOrInvalidKeys;
  final List<String> duplicateKeys;

  const DictionaryCompletenessReport({
    required this.totalUiKeys,
    required this.totalJargonEntries,
    required this.emptyOrInvalidKeys,
    required this.duplicateKeys,
  });

  bool get isComplete =>
      emptyOrInvalidKeys.isEmpty &&
      duplicateKeys.isEmpty &&
      totalUiKeys > 0 &&
      totalJargonEntries > 0;
}

/// Kompletny dwujęzyczny słownik lokalizacyjny PL/EN wraz z autentycznym żargonem kolarskim.
class BilingualCyclingDictionary {
  BilingualCyclingDictionary._();

  /// Rozszerzony słownik kluczy UI dla wszystkich modułów gry (PL <-> EN).
  static const Map<String, ({String pl, String en})> uiStrings = {
    // --- HUD Wyścigu i Telemetria ---
    'hud_power_watts': (pl: 'Moc (W)', en: 'Power (W)'),
    'hud_power_wkg': (pl: 'Moc względna (W/kg)', en: 'Power-to-Weight (W/kg)'),
    'hud_cadence_rpm': (pl: 'Kadencja (RPM)', en: 'Cadence (RPM)'),
    'hud_heart_rate': (pl: 'Tętno (BPM)', en: 'Heart Rate (BPM)'),
    'hud_w_prime_bal': (pl: 'Rezerwa W\'bal', en: 'W\'bal Reserve'),
    'hud_speed_kmh': (pl: 'Prędkość (km/h)', en: 'Speed (km/h)'),
    'hud_gradient_pct': (pl: 'Nachylenie (%)', en: 'Gradient (%)'),
    'hud_wind_cross': (pl: 'Wiatr boczny', en: 'Crosswind'),
    'hud_cda_aero': (pl: 'Opór aero (CdA)', en: 'Aero Drag (CdA)'),
    'hud_vam_rate': (pl: 'VAM (m/h)', en: 'VAM (m/h)'),
    'hud_distance_to_go': (pl: 'Do mety', en: 'To Finish'),
    'hud_time_gap': (pl: 'Strata czasowa', en: 'Time Gap'),
    'hud_otl_margin': (pl: 'Zapas do limitu OTL', en: 'OTL Time Margin'),
    'hud_core_temp': (pl: 'Temp. głęboka', en: 'Core Temp'),
    'hud_glycogen_level': (pl: 'Glikogen', en: 'Glycogen'),
    'hud_hydration_status': (pl: 'Nawodnienie', en: 'Hydration'),
    'hud_photo_finish': (pl: 'Fotofinisz (0.001 s)', en: 'Photo Finish (0.001 s)'),
    'hud_bike_throw_ready': (pl: 'Rzut rowerem gotowy', en: 'Bike Throw Ready'),
    'hud_race_radio': (pl: 'Radio wyścigowe', en: 'Race Radio'),
    'hud_live_splits': (pl: 'Międzyczasy na żywo', en: 'Live Splits'),

    // --- Rozkazy Taktyczne ---
    'order_protect_leader': (pl: 'Chroń lidera', en: 'Protect Leader'),
    'order_set_tempo': (pl: 'Nadawaj tempo', en: 'Set Pace'),
    'order_attack': (pl: 'Atakuj', en: 'Attack'),
    'order_counter_attack': (pl: 'Kontratakuj', en: 'Counter-Attack'),
    'order_bridge_gap': (pl: 'Przeskocz do ucieczki', en: 'Bridge the Gap'),
    'order_sit_on_wheel': (pl: 'Jedź na kole (Nie dawaj zmian)', en: 'Sit On (Skip Pulls)'),
    'order_form_echelon': (pl: 'Uformuj rant (Wachlarz)', en: 'Form Echelon'),
    'order_drop_to_car': (pl: 'Zjedź do wozu po bidony', en: 'Drop to Team Car'),
    'order_wait_for_leader': (pl: 'Czekaj na lidera GC', en: 'Wait for GC Leader'),
    'order_satellite_relay': (pl: 'Stacja przekaźnikowa', en: 'Satellite Relay'),
    'order_sprint_leadout': (pl: 'Rozprowadzenie sprintu', en: 'Sprint Lead-out'),
    'order_grupetto_survival': (pl: 'Tryb Autobusu (Przetrwanie)', en: 'Gruppetto Survival'),
    'order_ice_sock': (pl: 'Pobierz woreczek z lodem', en: 'Fetch Ice Sock'),
    'order_water_douse': (pl: 'Polej głowę wodą', en: 'Water Douse'),
    'order_rain_jacket': (pl: 'Załóż pelerynę', en: 'Put On Rain Jacket'),
    'order_pit_bike_swap': (pl: 'Zmiana roweru w boksie', en: 'Pit Lane Bike Swap'),

    // --- Fizjologia i Żywienie ---
    'phys_ftp': (pl: 'FTP (Moc progowa)', en: 'FTP (Threshold Power)'),
    'phys_vo2max': (pl: 'VO2max', en: 'VO2max'),
    'phys_vlamax': (pl: 'VLaMax (Glikoliza)', en: 'VLaMax (Glycolytic Rate)'),
    'phys_lt1': (pl: 'Próg tlenowy LT1', en: 'Aerobic Threshold LT1'),
    'phys_lt2': (pl: 'Próg mleczanowy LT2', en: 'Lactate Threshold LT2'),
    'phys_ctl_fitness': (pl: 'Forma długoterminowa (CTL)', en: 'Fitness (CTL)'),
    'phys_atl_fatigue': (pl: 'Zmęczenie ostre (ATL)', en: 'Fatigue (ATL)'),
    'phys_tsb_freshness': (pl: 'Świeżość (TSB)', en: 'Freshness (TSB)'),
    'phys_day_form': (pl: 'Dyspozycja dnia', en: 'Day Condition'),
    'phys_hydrogel_110': (pl: 'Hydrożel 110g/h CHO', en: 'High-Carb Hydrogel 110g/h'),
    'phys_bicarbonate': (pl: 'Bufor wodorowęglanowy', en: 'Bicarbonate Pre-Load'),
    'phys_ketones': (pl: 'Ketony egzogenne', en: 'Exogenous Ketones'),
    'phys_gi_distress': (pl: 'Dyskomfort żołądkowy', en: 'GI Distress'),
    'phys_muscle_cramps': (pl: 'Skurcze mięśniowe', en: 'Muscle Cramps'),

    // --- Sprzęt i Mechanika ---
    'equip_frame_aero': (pl: 'Rama Aero', en: 'Aero Frame'),
    'equip_frame_climbing': (pl: 'Rama Górska', en: 'Climbing Frame'),
    'equip_frame_tt': (pl: 'Rama Czasowa (TT)', en: 'Time Trial Frame'),
    'equip_wheelset_depth': (pl: 'Stożek obręczy (mm)', en: 'Rim Depth (mm)'),
    'equip_tire_pressure': (pl: 'Ciśnienie opon (BAR/PSI)', en: 'Tire Pressure (BAR/PSI)'),
    'equip_tubeless_sealant': (pl: 'Mleczko Tubeless', en: 'Tubeless Sealant'),
    'equip_foam_inserts': (pl: 'Wkładki antyprzebiciowe', en: 'Foam Tire Inserts'),
    'equip_chain_wax': (pl: 'Wosk łańcucha (Watty)', en: 'Chain Waxing (Watts)'),
    'equip_gearing_setup': (pl: 'Przełożenia napędu', en: 'Drivetrain Gearing'),
    'equip_bike_fit': (pl: 'Bike Fitting & Tunel Aero', en: 'Bike Fit & Wind Tunnel'),
    'equip_mechanical_defect': (pl: 'Defekt mechaniczny', en: 'Mechanical Issue'),
    'equip_puncture_co2': (pl: 'Przebicie opony / Naprawa CO2', en: 'Puncture / CO2 Repair'),

    // --- Dyscypliny Specjalne ---
    'disc_grand_tour': (pl: 'Wielki Tour (21 etapów)', en: 'Grand Tour (21 Stages)'),
    'disc_monument': (pl: 'Monument kolarski', en: 'Cycling Monument'),
    'disc_cyclocross': (pl: 'Kolarstwo Przełajowe (CX)', en: 'Cyclocross (CX)'),
    'disc_gravel_series': (pl: 'Wyścigi Szutrowe (Gravel)', en: 'UCI Gravel Series'),
    'disc_velodrome_hour': (pl: 'Rekord Godzinny na Welodromie', en: 'Velodrome UCI Hour Record'),
    'disc_womens_wt': (pl: 'Kobiecy WorldTour', en: 'UCI Women\'s WorldTour'),
    'disc_mixed_relay': (pl: 'Sztafeta Mieszana TTT', en: 'Mixed Team Relay TTT'),

    // --- Kariera, Finanse i Hall of Fame ---
    'career_be_a_pro': (pl: 'Tryb Zostań Legendą', en: 'Be a Pro Career'),
    'career_ds_trust': (pl: 'Zaufanie Dyrektora Sportowego', en: 'DS Trust Level'),
    'career_goat_score': (pl: 'Punktacja Legend (GOAT)', en: 'All-Time GOAT Score'),
    'career_hall_of_fame': (pl: 'Galeria Sław', en: 'Hall of Fame'),
    'career_sponsor_goals': (pl: 'Cele Sponsorskie', en: 'Sponsor Objectives'),
    'career_transfer_market': (pl: 'Rynek Transferowy', en: 'Transfer Market'),
    'career_scouting': (pl: 'Skauting Talentów', en: 'Talent Scouting'),
    'career_training_camp': (pl: 'Obóz Wysokogórski', en: 'Altitude Training Camp'),
    'career_palmares': (pl: 'Palmarès (Osiągnięcia)', en: 'Palmarès (Achievements)'),

    // --- Sędziowie, Etykieta i Pogoda ---
    'jury_commissaire': (pl: 'Komisarz UCI', en: 'UCI Commissaire'),
    'jury_time_penalty': (pl: 'Kara czasowa', en: 'Time Penalty'),
    'jury_relegation': (pl: 'Relegacja na koniec grupy', en: 'Relegation'),
    'jury_neutralization': (pl: 'Neutralizacja po kraksie', en: 'Crash Neutralization'),
    'jury_combativity': (pl: 'Najaktywniejszy Kolarz', en: 'Most Combative Rider'),
    'weather_crosswind_gust': (pl: 'Podmuchy boczne', en: 'Crosswind Gusts'),
    'weather_wet_cobbles': (pl: 'Mokry bruk', en: 'Wet Cobbles'),
    'weather_heatwave': (pl: 'Fala upałów', en: 'Heatwave'),

    // --- System, Dostępność i Mody ---
    'l10n_panel_title': (
      pl: 'DWUJĘZYCZNY SŁOWNIK LOKALIZACYJNY I ŻARGON KOLARSKI',
      en: 'BILINGUAL LOCALIZATION & CYCLING JARGON DICTIONARY',
    ),
    'l10n_panel_subtitle': (
      pl: 'Kompletna terminologia Pro Peloton Manager (PL / EN) z definicjami i przykładami użycia w wyścigu.',
      en: 'Complete Pro Peloton Manager terminology (PL / EN) with definitions and in-race usage examples.',
    ),
    'l10n_search_hint': (
      pl: 'Szukaj hasła, skrótu lub definicji (np. echelon, sticky bottle, VAM)...',
      en: 'Search term, acronym, or definition (e.g. echelon, sticky bottle, VAM)...',
    ),
    'l10n_all_domains': (pl: 'Wszystkie domeny', en: 'All Domains'),
    'l10n_empty_results': (
      pl: 'Brak haseł pasujących do zapytania.',
      en: 'No dictionary entries match your query.',
    ),
    'l10n_clear_filters': (pl: 'Wyczyść filtry', en: 'Clear Filters'),
    'l10n_copy_term': (pl: 'Kopiuj hasło', en: 'Copy Term'),
    'l10n_copied_feedback': (
      pl: 'Skopiowano do schowka: {term}',
      en: 'Copied to clipboard: {term}',
    ),
    'l10n_origin_label': (pl: 'Pochodzenie / Slang', en: 'Origin / Slang'),
    'l10n_definition_label': (pl: 'Definicja taktyczna', en: 'Tactical Definition'),
    'l10n_example_label': (pl: 'Przykład z radia wyścigowego', en: 'Race Radio Example'),
    'l10n_stats_ui_keys': (pl: 'Klucze UI', en: 'UI Keys'),
    'l10n_stats_jargon': (pl: 'Hasła żargonu', en: 'Jargon Terms'),
    'l10n_stats_filtered': (pl: 'Widoczne', en: 'Visible'),

    // --- Ligi Online, ELO i Wyzwania Duchów (Paczka #6/#7) ---
    'multi_online_leagues': (
      pl: 'Ligi Online i Ranking ELO',
      en: 'Online Leagues & ELO Ranking',
    ),
    'multi_elo_rating': (pl: 'Ranking ELO', en: 'ELO Rating'),
    'multi_elo_division': (pl: 'Dywizja ELO', en: 'ELO Division'),
    'multi_ghost_challenge': (
      pl: 'Wyzwanie Ducha (Ghost)',
      en: 'Ghost Challenge',
    ),
    'multi_league_draft': (pl: 'Draft Ligi', en: 'League Draft'),
    'multi_ppmleague_export': (
      pl: 'Eksport paczki .ppmleague',
      en: 'Export .ppmleague Package',
    ),
    'multi_live_telemetry_ghost': (
      pl: 'Telemetria Ducha na żywo',
      en: 'Live Ghost Telemetry',
    ),

    // --- MTB XCO, Tor i Ultra-Bikepacking ---
    'disc_mtb_xco': (
      pl: 'MTB Cross-Country (XCO)',
      en: 'MTB Cross-Country (XCO)',
    ),
    'mtb_rock_garden': (pl: 'Ogród Skalny (Rock Garden)', en: 'Rock Garden'),
    'mtb_dropper_post': (
      pl: 'Sztyca Regulowana (Dropper)',
      en: 'Dropper Seatpost',
    ),
    'mtb_suspension_lockout': (
      pl: 'Blokada Zawieszenia',
      en: 'Suspension Lockout',
    ),
    'mtb_line_choice': (
      pl: 'Wybór Linii (A/B Line)',
      en: 'Line Choice (A/B Line)',
    ),
    'mtb_tire_24_pressure': (
      pl: 'Ciśnienie Opon 2.4" MTB',
      en: 'MTB 2.4" Tire Pressure',
    ),
    'disc_ultra_bikepacking': (
      pl: 'Ultra-Bikepacking 4000 km',
      en: 'Ultra-Bikepacking 4000 km',
    ),
    'ultra_dynamo_hub': (pl: 'Piasta z Dynamem', en: 'Dynamo Hub'),
    'ultra_sleep_deficit': (
      pl: 'Deficyt Snu i Mikrosen',
      en: 'Sleep Deficit & Microsleep',
    ),
    'ultra_self_supported': (
      pl: 'Reguła Samowystarczalności',
      en: 'Self-Supported Rule',
    ),
    'ultra_checkpoint': (pl: 'Punkt Kontrolny (CP)', en: 'Checkpoint (CP)'),
    'track_keirin': (pl: 'Keirin (Za Derny)', en: 'Keirin (Derny Paced)'),
    'track_madison': (
      pl: 'Madison (Wyścig Parami)',
      en: 'Madison (Hand-Sling)',
    ),
    'track_omnium': (
      pl: 'Omnium (Wielobój Torowy)',
      en: 'Omnium (Multi-Race)',
    ),

    // --- Własna Marka R&D, Organizator ASO/RCS i Przepisy UCI VAR ---
    'brand_inhouse_factory': (
      pl: 'Fabryka Własnej Marki',
      en: 'In-House Brand Factory',
    ),
    'brand_carbon_layup': (
      pl: 'Układ Włókien Karbonowych',
      en: 'Carbon Layup Grade',
    ),
    'brand_rd_project': (pl: 'Projekt R&D Ramy', en: 'Frame R&D Project'),
    'brand_external_license': (
      pl: 'Licencja dla Zespołów Zewnętrznych',
      en: 'External Team License',
    ),
    'brand_wind_tunnel_gain': (
      pl: 'Zysk Aero z Tunelu',
      en: 'Wind Tunnel Gain',
    ),
    'org_hq_title': (
      pl: 'Centrum Organizatora Wyścigów',
      en: 'Race Organizer HQ',
    ),
    'org_host_city_bid': (
      pl: 'Przetarg Miasta Gospodarza',
      en: 'Host City Bid',
    ),
    'org_tv_rights': (
      pl: 'Kontrakt Praw Telewizyjnych',
      en: 'TV Broadcast Rights',
    ),
    'org_uci_prestige': (
      pl: 'Prestiż Wyścigu UCI (2.UWT)',
      en: 'UCI Race Prestige (2.UWT)',
    ),
    'org_syndicate_ledger': (
      pl: 'Bilans Budżetowy Organizatora',
      en: 'Organizer Budget Ledger',
    ),
    'jury_sprint_var': (
      pl: 'Analiza Wideo Sprint VAR',
      en: 'Sprint Deviation VAR',
    ),
    'jury_yellow_card': (pl: 'Żółta Kartka UCI', en: 'UCI Yellow Card'),
    'jury_rulebook_edition': (
      pl: 'Regulamin UCI (Edycja Sezonowa)',
      en: 'UCI Rulebook Edition',
    ),
    'jury_equipment_compliance': (
      pl: 'Kontrola Zgodności Sprzętu UCI',
      en: 'UCI Equipment Compliance',
    ),
    'jury_rule_amendment': (
      pl: 'Nowelizacja Przepisów UCI',
      en: 'UCI Rule Amendment',
    ),

    // --- Akademie, Perki Menedżera, Plotki i System ---
    'career_satellite_academy': (
      pl: 'Akademia Satelicka',
      en: 'Satellite Academy',
    ),
    'career_manager_perks': (
      pl: 'Perki i Reputacja Menedżera',
      en: 'Manager Perks & Reputation',
    ),
    'career_transfer_rumors': (
      pl: 'Plotki Transferowe i Przecieki',
      en: 'Transfer Rumors & Leaks',
    ),
    'career_team_bus_warmup': (
      pl: 'Rozgrzewka w Autobusie (VO2 Priming)',
      en: 'Team Bus Warmup (VO2 Priming)',
    ),
    'ui_accessibility_colorblind': (
      pl: 'Tryb Daltonizmu (WCAG)',
      en: 'Colorblind Accessibility Mode',
    ),
    'ui_gamepad_mapper': (
      pl: 'Mapowanie Kontrolera / Gamepada',
      en: 'Controller / Gamepad Mapping',
    ),
    'ui_graphics_profiler': (
      pl: 'Profiler Graficzny 120 FPS',
      en: '120 FPS Graphics Profiler',
    ),

    // --- Paczka #8: Złota Era, e-Sports, ESG, Reprezentacja, Caravan Drafting i NG+ ---
    'retro_golden_era_title': (
      pl: 'Złota Era Kolarstwa (1970–2015)',
      en: 'Golden Era Cycling (1970–2015)',
    ),
    'retro_steel_columbus_frame': (
      pl: 'Stalowa Rama Columbus SL (9.2 kg)',
      en: 'Columbus SL Steel Frame (9.2 kg)',
    ),
    'retro_friction_shifters': (
      pl: 'Manetki Cierne na Dolnej Rurze',
      en: 'Friction Downtube Shifters',
    ),
    'retro_borg_rpe_scale': (
      pl: 'Skala Wysiłku Borg RPE (6–20)',
      en: 'Borg RPE Exertion Scale (6–20)',
    ),
    'retro_no_powermeter_radio': (
      pl: 'Bez Miernika Mocy i Radia',
      en: 'No Powermeter & No Race Radio',
    ),
    'retro_tv_film_filter': (
      pl: 'Filtr TV 16mm / VHS / Sepia',
      en: '16mm / VHS / Sepia TV Filter',
    ),
    'esports_uci_title': (
      pl: 'UCI Cycling Esports',
      en: 'UCI Cycling Esports',
    ),
    'esports_smart_trainer_erg': (
      pl: 'Trenażer Smart (Tryb ERG)',
      en: 'Smart Trainer (ERG Mode)',
    ),
    'esports_powerup_aero_helmet': (
      pl: 'Power-Up: Kask Aero',
      en: 'Power-Up: Aero Helmet',
    ),
    'esports_powerup_featherweight': (
      pl: 'Power-Up: Piórko (-10% masy)',
      en: 'Power-Up: Featherweight (-10% Weight)',
    ),
    'esports_powerup_burrito': (
      pl: 'Power-Up: Burrito (Brak draftu)',
      en: 'Power-Up: Burrito (No Draft)',
    ),
    'esports_elimination_60s': (
      pl: 'Wyścig Eliminacyjny (Co 60 s)',
      en: '60s Elimination Race',
    ),
    'esports_virtual_talent_academy': (
      pl: 'Akademia Virtual Talent ID',
      en: 'Virtual Talent ID Academy',
    ),
    'esg_green_fleet_title': (
      pl: 'Ekonomia ESG i Zielona Flota',
      en: 'ESG Sustainability & Green Fleet',
    ),
    'esg_ev_hydrogen_convoy': (
      pl: 'Konwój EV / Wodorowy Drużyny',
      en: 'EV / Hydrogen Team Convoy',
    ),
    'esg_carbon_footprint_co2': (
      pl: 'Bilans Śladu Węglowego (CO2)',
      en: 'Carbon Footprint Ledger (CO2)',
    ),
    'esg_green_sponsor_tier': (
      pl: 'Zielony Sponsor ESG',
      en: 'Green ESG Sponsor',
    ),
    'coach_ai_post_race_title': (
      pl: 'Analityk Taktyczny AI po Wyścigu',
      en: 'Post-Race AI Tactical Coach',
    ),
    'coach_ai_wasted_wind_watts': (
      pl: 'Stracone Waty na Wietrze',
      en: 'Wasted Wind Watts',
    ),
    'tactics_diagonal_echelon': (
      pl: 'Diagonalna Formacja Wachlarza',
      en: 'Diagonal Echelon Formation',
    ),
    'tactics_gutter_wind_trap': (
      pl: 'Pułapka Krawężnika (In the Gutter)',
      en: 'Gutter Wind Trap (In the Gutter)',
    ),
    'physics_braking_kinetic_loss': (
      pl: 'Strata Kinetyczna na Dohamowaniach',
      en: 'Braking Zone Kinetic Loss',
    ),
    'physics_caravan_drafting': (
      pl: 'Drafting w Kolumnie Wozów i Motocykli',
      en: 'Caravan & TV Moto Drafting',
    ),
    'physics_caravan_penalty_risk': (
      pl: 'Ryzyko Kary za Jazdę za Wozem',
      en: 'Caravan Drafting Penalty Risk',
    ),
    'career_personal_life_events': (
      pl: 'Życie Osobiste i Wydarzenia Rodzinne',
      en: 'Personal Life & Family Events',
    ),
    'career_national_team_hq': (
      pl: 'Biuro Selekcjonera Reprezentacji',
      en: 'National Team Selector HQ',
    ),
    'career_deadline_day_live': (
      pl: 'Transfer Deadline Day (Na Żywo)',
      en: 'Transfer Deadline Day Live',
    ),
    'career_club_fan_shop': (
      pl: 'Sklep Klubowy i Gadżety Kibiców',
      en: 'Club Merchandise & Fan Shop',
    ),
    'career_rider_nicknames': (
      pl: 'Przydomki Kolarskie Mediów',
      en: 'Media Rider Nicknames',
    ),
    'career_gt_route_reveal': (
      pl: 'Ceremonia Prezentacji Trasy GT',
      en: 'Grand Tour Route Reveal Ceremony',
    ),
    'career_legacy_book_ng_plus': (
      pl: 'Księga Legendy (New Game+ / Dynastia)',
      en: 'Manager Legacy Book (NG+ / Dynasty)',
    ),
    'jury_extreme_weather_protocol': (
      pl: 'Protokół Ekstremalnej Pogody UCI',
      en: 'UCI Extreme Weather Protocol',
    ),
    'jury_course_reroute': (
      pl: 'Dynamiczna Zmiana Trasy Etapu',
      en: 'Dynamic Stage Course Reroute',
    ),
    'ui_voice_quick_commands': (
      pl: 'Szybkie Komendy Radia (Alt+Space)',
      en: 'Race Radio Quick Commands (Alt+Space)',
    ),
    'ui_cross_save_gzip': (
      pl: 'Transfer Zapisu Między Urządzeniami (.ppmsave.gz)',
      en: 'Cross-Device Save Transfer (.ppmsave.gz)',
    ),
    'ui_realism_presets': (
      pl: 'Presety Realizmu Rozgrywki',
      en: 'Gameplay Realism Presets',
    ),
    'ui_save_v8_migrator': (
      pl: 'Migrator Zapisów Paczki #8 (v8)',
      en: 'Package #8 Save Migrator (v8)',
    ),
  };

  /// Autentyczny dwujęzyczny słownik żargonu kolarskiego (PL <-> EN).
  static const List<BilingualTermEntry> jargonEntries = [
    // --- Taktyka Peletonu ---
    BilingualTermEntry(
      key: 'echelons',
      domain: AppL10nDomain.pelotonTactics,
      pl: 'Ranty / Wachlarze',
      en: 'Echelons',
      slangOrOrigin: 'NL: Waaier',
      definitionPl:
          'Ukośna formacja kolarzy rozciągnięta od krawędzi do krawędzi szosy przy silnym wietrze bocznym, dająca osłonę aerodynamiczną tylko wybranej grupie.',
      definitionEn:
          'Diagonal line of riders stretched across the road in strong crosswinds, sheltering teammates while leaving rivals exposed in the gutter.',
      examplePl: 'Wiatr wieje z prawej! Uformować rant na pierwszej linii!',
      exampleEn: 'Crosswind from the right! Form an echelon at the front!',
    ),
    BilingualTermEntry(
      key: 'gutter',
      domain: AppL10nDomain.pelotonTactics,
      pl: 'Jazda w rynsztoku (Na wietrze)',
      en: 'In the Gutter',
      slangOrOrigin: 'EN: Gutter',
      definitionPl:
          'Pozycja na samym skraju asfaltu za końcem wachlarza, gdzie nie ma już miejsca na schowanie się przed wiatrem bocznym.',
      definitionEn:
          'Riding at the very edge of the road behind the tail of an echelon with zero shelter from the crosswind.',
      examplePl: 'Rywale jadą w rynsztoku — zwiększamy tempo o 30 watów!',
      exampleEn: 'Rivals are pinned in the gutter — raise the pace by 30 watts!',
    ),
    BilingualTermEntry(
      key: 'chasse_patate',
      domain: AppL10nDomain.pelotonTactics,
      pl: 'Pogoń w próżni (Ziemia niczyja)',
      en: 'Chasse-patate (No Man\'s Land)',
      slangOrOrigin: 'FR: Chasse-patate',
      definitionPl:
          'Bezowocna pogoń między ucieczką a peletonem, w której kolarz zużywa mnóstwo energii w pojedynkę i ani nie dogania czołówki, ani nie odpoczywa w grupie.',
      definitionEn:
          'Futile solo chase stuck between the breakaway and the peloton, burning matches without bridging across.',
      examplePl: 'Nie zostawaj w chasse-patate, poczekaj na peleton!',
      exampleEn: 'Don\'t get stuck in chasse-patate, sit up and wait for the bunch!',
    ),
    BilingualTermEntry(
      key: 'grupetto',
      domain: AppL10nDomain.pelotonTactics,
      pl: 'Grupetto (Autobus)',
      en: 'Gruppetto (The Bus)',
      slangOrOrigin: 'IT: Gruppetto',
      definitionPl:
          'Zwarty pociąg sprinterów i zmęczonych kolarzy jadących równym tempem na wysokich górskich przełęczach, aby bezpiecznie zmieścić się w limicie czasu (OTL).',
      definitionEn:
          'Large group of sprinters and dropped riders pacing together on mountain stages to survive within the time cut.',
      examplePl: 'Kapitan autobusu kontroluje zapas 4 minut do limitu OTL.',
      exampleEn: 'The gruppetto captain is holding a 4-minute buffer on the OTL.',
    ),
    BilingualTermEntry(
      key: 'wheelsucker',
      domain: AppL10nDomain.pelotonTactics,
      pl: 'Kołozjad (Pasażer na gapę)',
      en: 'Wheelsucker (Sit-on)',
      slangOrOrigin: 'EN: Wheelsucker',
      definitionPl:
          'Kolarz jadący wyłącznie w cieniu aerodynamicznym rywali i odmawiający dawania zmian na czele grupy.',
      definitionEn:
          'Rider who refuses to take pulls at the front while drafting behind rivals to save energy for the finale.',
      examplePl: 'Przestań dawać zmiany — on tylko siedzi nam na kole!',
      exampleEn: 'Stop pulling through — he\'s pure wheelsucking!',
    ),
    BilingualTermEntry(
      key: 'satellite_rider',
      domain: AppL10nDomain.pelotonTactics,
      pl: 'Stacja przekaźnikowa',
      en: 'Satellite Rider',
      slangOrOrigin: 'Tactical Relay',
      definitionPl:
          'Pomocnik wysłany wcześniej do porannej ucieczki, który na przedostatniej przełęczy czeka na swojego lidera GC, by pociągnąć go w dolinie i u podnóża finałowej góry.',
      definitionEn:
          'Domestique sent into the early breakaway to wait on the penultimate pass and pace the GC leader through the valley.',
      examplePl: 'Nasz pomocnik czeka na szczycie jako stacja przekaźnikowa.',
      exampleEn: 'Our domestique is waiting at the summit as a satellite relay.',
    ),
    BilingualTermEntry(
      key: 'leadout_train',
      domain: AppL10nDomain.pelotonTactics,
      pl: 'Pociąg sprinterski',
      en: 'Lead-out Train',
      slangOrOrigin: 'Sprint Tactics',
      definitionPl:
          'Zorganizowana kolejka 3–5 kolarzy rozprowadzających sprintera na ostatnich kilometrach przy prędkości 65–72 km/h.',
      definitionEn:
          'Organized line of teammates riding at 65–72 km/h in the final kilometers to launch their sprinter cleanly.',
      examplePl: 'Ustawić pociąg po lewej stronie na 2 km przed metą!',
      exampleEn: 'Line up the lead-out train on the left with 2 km to go!',
    ),
    BilingualTermEntry(
      key: 'aero_slingshot',
      domain: AppL10nDomain.pelotonTactics,
      pl: 'Proca aerodynamiczna',
      en: 'Aerodynamic Slingshot',
      slangOrOrigin: 'Sprint Physics',
      definitionPl:
          'Gwałtowny wyskok sprintera z koła ostatniego rozprowadzającego na 200 m przed kreską, wykorzystujący opóźnione narastanie oporu powietrza.',
      definitionEn:
          'Explosive launch out of the final lead-out man\'s slipstream at 200 m to go, peaking over 74 km/h.',
      examplePl: 'Ostatni rozprowadzający schodzi — odpalaj procę!',
      exampleEn: 'Final lead-out man peels off — launch the slingshot!',
    ),
    BilingualTermEntry(
      key: 'bike_throw',
      domain: AppL10nDomain.pelotonTactics,
      pl: 'Rzut rowerem na kreskę',
      en: 'Bike Throw',
      slangOrOrigin: 'Finish Line',
      definitionPl:
          'Wypchnięcie roweru maksymalnie do przodu tuż przed linią mety poprzez cofnięcie bioder za siodełko, dające 18–28 cm przewagi.',
      definitionEn:
          'Lunging the bike forward at the finish line by shifting hips behind the saddle to gain 18–28 cm.',
      examplePl: 'Różnica 0.004 s na fotofiniszu — idealny rzut rowerem!',
      exampleEn: '0.004 s margin on the photo finish — textbook bike throw!',
    ),
    BilingualTermEntry(
      key: 'poker_face_bluff',
      domain: AppL10nDomain.pelotonTactics,
      pl: 'Blef zmęczenia (Poker Face)',
      en: 'Poker Face Bluff',
      slangOrOrigin: 'Mind Games',
      definitionPl:
          'Celowe maskowanie świeżości lub udawanie skrajnego wyczerpania na końcu grupy, aby uśpić czujność rywali przed decydującym atakiem.',
      definitionEn:
          'Intentionally feigning exhaustion at the back of a group to lull rivals before launching a decisive attack.',
      examplePl: 'Nie wierz w jego minę — jedzie na końcu z pełnym W\'bal!',
      exampleEn: 'Don\'t buy his grimace — he\'s sitting last wheel with full W\'bal!',
    ),
    BilingualTermEntry(
      key: 'domestique',
      domain: AppL10nDomain.careerManagement,
      pl: 'Pomocnik (Gregario)',
      en: 'Domestique',
      slangOrOrigin: 'FR: Domestique / IT: Gregario',
      definitionPl:
          'Kolarz poświęcający własne ambicje dla lidera: osłania od wiatru, wozi bidony z wozu i goni groźne ucieczki.',
      definitionEn:
          'Support rider sacrificing personal results to shield the leader, fetch bidons, and chase down breakaways.',
      examplePl: 'Potrzebujemy dwóch gregario na czoło peletonu!',
      exampleEn: 'Send two domestiques to the front of the peloton!',
    ),
    BilingualTermEntry(
      key: 'road_captain',
      domain: AppL10nDomain.careerManagement,
      pl: 'Kapitan szosy',
      en: 'Road Captain',
      slangOrOrigin: 'Team Leadership',
      definitionPl:
          'Doświadczony weteran podejmujący decyzje taktyczne na trasie, organizujący drużynę na wietrze i przekazujący polecenia z radia.',
      definitionEn:
          'Veteran rider making on-road tactical calls, organizing crosswind formations, and relaying DS orders.',
      examplePl: 'Kapitan szosy zarządził przesunięcie lidera do pierwszej dziesiątki.',
      exampleEn: 'The road captain ordered the leader moved into the top ten.',
    ),
    BilingualTermEntry(
      key: 'baroudeur',
      domain: AppL10nDomain.pelotonTactics,
      pl: 'Uciekinier (Harce)',
      en: 'Baroudeur (Breakaway Specialist)',
      slangOrOrigin: 'FR: Baroudeur',
      definitionPl:
          'Kolarz o wysokiej wytrzymałości i determinacji, specjalizujący się w całodziennych odjazdach od startu ostrego.',
      definitionEn:
          'Relentless attacker specializing in long, all-day breakaways from kilometer zero.',
      examplePl: 'Nasz baroudeur zgarnął komplet punktów na trzech premiach.',
      exampleEn: 'Our baroudeur swept maximum points across three climbs.',
    ),
    BilingualTermEntry(
      key: 'puncheur',
      domain: AppL10nDomain.pelotonTactics,
      pl: 'Kolarz klasykowy (Puncheur)',
      en: 'Puncheur',
      slangOrOrigin: 'FR: Puncheur',
      definitionPl:
          'Specjalista od krótkich, bardzo stromych podjazdów (1–3 km, 10–20%) pokonywanych wysoką mocą beztlenową.',
      definitionEn:
          'Explosive rider thriving on short, steep climbs (1–3 km at 10–20%) solved by anaerobic surges.',
      examplePl: 'Na Mur de Huy nasi puncheurzy będą bezkonkurencyjni.',
      exampleEn: 'Our puncheurs will dominate the steep wall of Mur de Huy.',
    ),
    BilingualTermEntry(
      key: 'rouleur',
      domain: AppL10nDomain.pelotonTactics,
      pl: 'Siłacz płaskich odcinków (Rouleur)',
      en: 'Rouleur',
      slangOrOrigin: 'FR: Rouleur',
      definitionPl:
          'Silny kolarz potrafiący godzinami utrzymywać bardzo wysoką moc na płaskim terenie, brukach i w czasówkach.',
      definitionEn:
          'Powerhouse rider capable of sustaining high speeds for hours on flat roads, cobbles, and time trials.',
      examplePl: 'Wystaw rouleurów do kontroli straty przed sektorem bruku.',
      exampleEn: 'Put the rouleurs on the front before the cobble sector.',
    ),

    // --- Fizjologia i Żywienie ---
    BilingualTermEntry(
      key: 'bonking',
      domain: AppL10nDomain.physiologyNutrition,
      pl: 'Odcięcie prądu (Ściana)',
      en: 'Bonking (Hunger Knock)',
      slangOrOrigin: 'EN: Bonk / FR: Fringale',
      definitionPl:
          'Krytyczne wyczerpanie glikogenu mięśniowego skutkujące nagłym spadkiem mocy do strefy Z1 i utratą kontaktu z grupą.',
      definitionEn:
          'Catastrophic glycogen depletion causing a sudden power collapse down to Zone 1.',
      examplePl: 'Przegapił bufet i ma odcięcie — traci dwie minuty na kilometrze!',
      exampleEn: 'He missed the feed zone and bonked hard — losing minutes fast!',
    ),
    BilingualTermEntry(
      key: 'watt_bomb',
      domain: AppL10nDomain.physiologyNutrition,
      pl: 'Bomba watowa',
      en: 'Watt Bomb',
      slangOrOrigin: 'Modern Peloton',
      definitionPl:
          'Nagły atak z ponad 10 W/kg na stromym fragmencie góry, błyskawicznie rujnujący rezerwę W\'bal rywali.',
      definitionEn:
          'Explosive surge exceeding 10 W/kg on a steep climb, instantly draining rivals\' anaerobic W\'bal.',
      examplePl: 'Lider odpalił bombę watową na 14% nachylenia!',
      exampleEn: 'The GC leader dropped a watt bomb on the 14% ramp!',
    ),
    BilingualTermEntry(
      key: 'w_prime_bal',
      domain: AppL10nDomain.physiologyNutrition,
      pl: 'Rezerwa beztlenowa W\'bal',
      en: 'W\'bal (Anaerobic Battery)',
      slangOrOrigin: 'Skiba Model',
      definitionPl:
          'Dynamiczna pojemność pracy powyżej progu FTP (w dżulach/kJ), która zużywa się przy atakach i regeneruje poniżej progu.',
      definitionEn:
          'Dynamic anaerobic work capacity above FTP (kJ) that depletes during surges and recharges below threshold.',
      examplePl: 'Zostało tylko 15% W\'bal — nie odpowiadaj na ten skok!',
      exampleEn: 'Only 15% W\'bal left — do not follow that surge!',
    ),
    BilingualTermEntry(
      key: 'vam',
      domain: AppL10nDomain.physiologyNutrition,
      pl: 'VAM (Prędkość wznoszenia)',
      en: 'VAM (Vertical Ascent Meters/h)',
      slangOrOrigin: 'IT: Velocità Ascensionale Media',
      definitionPl:
          'Średnia prędkość zdobywania wysokości w metrach na godzinę; elita WorldTour osiąga 1750–1900 m/h na podjazdach HC.',
      definitionEn:
          'Average vertical climbing speed in meters per hour; WorldTour elites sustain 1750–1900 m/h on HC climbs.',
      examplePl: 'Peleton wspina się z VAM 1820 m/h — tempo jak na Alpe d\'Huez.',
      exampleEn: 'The bunch is climbing at 1820 m/h VAM — pure Grand Tour pace.',
    ),
    BilingualTermEntry(
      key: 'vlamax',
      domain: AppL10nDomain.physiologyNutrition,
      pl: 'VLaMax (Maks. produkcja mleczanu)',
      en: 'VLaMax (Glycolytic Flux)',
      slangOrOrigin: 'Metabolic Lab',
      definitionPl:
          'Maksymalna szybkość produkcji mleczanu określająca profil kolarza: niska (<0.35) sprzyja góralom GC, wysoka (>0.70) sprinterom.',
      definitionEn:
          'Maximal lactate production rate defining physiology: low (<0.35) suits GT climbers, high (>0.70) suits sprinters.',
      examplePl: 'Obniżyliśmy VLaMax na obozie — znacznie lepiej znosi tempo progowe.',
      exampleEn: 'Camp lowered his VLaMax — much higher threshold durability.',
    ),
    BilingualTermEntry(
      key: 'hydrogel_110',
      domain: AppL10nDomain.physiologyNutrition,
      pl: 'Hydrożel 110g/h CHO',
      en: 'High-Carb Hydrogel (110g/h)',
      slangOrOrigin: 'Modern Nutrition',
      definitionPl:
          'Zaawansowana suplementacja węglowodanami w żelu alginianowym pozwalająca przyswoić 100–120 g/h przy wytrenowanym żołądku.',
      definitionEn:
          'Alginate hydrogel carbohydrate delivery enabling 100–120 g/h absorption with sufficient gut training.',
      examplePl: 'Przechodzimy na strategię 110g/h CHO przed trzema przełęczami.',
      exampleEn: 'Switch to the 110g/h hydrogel plan ahead of the three cols.',
    ),
    BilingualTermEntry(
      key: 'bicarbonate_preload',
      domain: AppL10nDomain.physiologyNutrition,
      pl: 'Bufor wodorowęglanowy',
      en: 'Bicarbonate Pre-Load',
      slangOrOrigin: 'Sports Science',
      definitionPl:
          'Przedstartowa dawka dwuwęglanu sodu buforująca zakwaszenie krwi (+6% wydolności beztlenowej) kosztem ryzyka problemów żołądkowych.',
      definitionEn:
          'Pre-race sodium bicarbonate buffering blood acidosis (+6% anaerobic output) with a mild GI distress risk.',
      examplePl: 'Bufor zadziałał idealnie — ma zapas na finałowy sprint pod górę.',
      exampleEn: 'Bicarbonate pre-load worked — extra punch for the uphill finish.',
    ),
    BilingualTermEntry(
      key: 'ice_sock',
      domain: AppL10nDomain.physiologyNutrition,
      pl: 'Woreczek z lodem (Ice Sock)',
      en: 'Ice Sock',
      slangOrOrigin: 'Heat Protocol',
      definitionPl:
          'Pończocha wypełniona kruszonym lodem wkładana pod koszulkę na kark w upale >30°C, by obniżyć temperaturę głęboką ciała.',
      definitionEn:
          'Nylon stocking packed with crushed ice tucked down the jersey neck in >30°C heat to lower core temperature.',
      examplePl: 'Temperatura głęboka rośnie do 39.1°C — natychmiast po Ice Sock!',
      exampleEn: 'Core temp hitting 39.1°C — drop back for an ice sock now!',
    ),

    // --- HUD & Klasyfikacje ---
    BilingualTermEntry(
      key: 'flamme_rouge',
      domain: AppL10nDomain.raceHud,
      pl: 'Flamme Rouge (Ostatni kilometr)',
      en: 'Flamme Rouge (Final Kilometer)',
      slangOrOrigin: 'FR: Flamme Rouge',
      definitionPl:
          'Czerwona brama lub trójkątny proporzec dokładnie 1000 metrów przed metą etapu.',
      definitionEn:
          'Red pennant or inflatable arch marking the exact 1,000 meters remaining to the finish line.',
      examplePl: 'Mijają Flamme Rouge — czas na finałowe rozprowadzenie!',
      exampleEn: 'Passing under the Flamme Rouge — final kilometer!',
    ),
    BilingualTermEntry(
      key: 'lanterne_rouge',
      domain: AppL10nDomain.raceHud,
      pl: 'Czerwona latarnia (Ostatni w GC)',
      en: 'Lanterne Rouge',
      slangOrOrigin: 'FR: Lanterne Rouge',
      definitionPl:
          'Honorowo-humorystyczne określenie kolarza zajmującego ostatnie miejsce w klasyfikacji generalnej Wielkiego Touru.',
      definitionEn:
          'Traditional moniker for the rider sitting in last place overall in a Grand Tour.',
      examplePl: 'Po kraksie spadł na pozycję Lanterne Rouge, ale ukończył etap.',
      exampleEn: 'After the crash he sits as Lanterne Rouge, still fighting on.',
    ),
    BilingualTermEntry(
      key: 'hors_categorie',
      domain: AppL10nDomain.disciplines,
      pl: 'Poza Kategorią (HC)',
      en: 'Hors Catégorie (HC)',
      slangOrOrigin: 'FR: Hors Catégorie',
      definitionPl:
          'Najwyższa i najtrudniejsza kategoria podjazdów górskich w wyścigach szosowych (np. Mont Ventoux, Alpe d\'Huez, Tourmalet).',
      definitionEn:
          'Highest, most brutal climb classification beyond standard categories (e.g. Mont Ventoux, Alpe d\'Huez).',
      examplePl: 'Przed nami 21 km wspinaczki Hors Catégorie na Mont Ventoux.',
      exampleEn: 'Ahead lies a 21 km Hors Catégorie ascent up Mont Ventoux.',
    ),
    BilingualTermEntry(
      key: 'otl',
      domain: AppL10nDomain.juryEtiquette,
      pl: 'Poza limitem czasu (OTL)',
      en: 'Outside Time Limit (OTL)',
      slangOrOrigin: 'UCI Rule',
      definitionPl:
          'Dyskwalifikacja z wyścigu wieloetapowego po przekroczeniu maksymalnego dopuszczalnego czasu straty do zwycięzcy etapu.',
      definitionEn:
          'Elimination from a stage race for finishing slower than the stage winner\'s percentage time cut.',
      examplePl: 'Jeśli nie przyspieszą na ostatniej górze, grozi im OTL.',
      exampleEn: 'If they don\'t lift the pace on the final climb, they\'ll miss the OTL.',
    ),

    // --- Sprzęt i Mechanika ---
    BilingualTermEntry(
      key: 'supertuck',
      domain: AppL10nDomain.equipmentMechanics,
      pl: 'Pozycja na ramie (Supertuck)',
      en: 'Supertuck',
      slangOrOrigin: 'Aero Descent',
      definitionPl:
          'Skrajnie aerodynamiczna pozycja zjazdowa z klatką piersiową na kierownicy, redukująca CdA o ponad 15% na szybkich zjazdach.',
      definitionEn:
          'Ultra-aerodynamic descending tuck reducing CdA by over 15% on fast mountain descents.',
      examplePl: 'Wchodzi w Supertuck przy 88 km/h i urywa 15 sekund na zjeździe!',
      exampleEn: 'Drops into a supertuck at 88 km/h, gaining 15 seconds!',
    ),
    BilingualTermEntry(
      key: 'tubeless_sealant',
      domain: AppL10nDomain.equipmentMechanics,
      pl: 'Mleczko uszczelniające (Tubeless)',
      en: 'Tubeless Sealant',
      slangOrOrigin: 'Gravel & Cobbles',
      definitionPl:
          'Lateksowy płyn w oponie bezdętkowej automatycznie zaklejający drobne przebicia bez zatrzymywania kolarza.',
      definitionEn:
          'Latex liquid inside tubeless tires that automatically seals small punctures while riding.',
      examplePl: 'Mleczko Tubeless zakleiło dziurę po 3 sekundach — jedzie dalej!',
      exampleEn: 'Tubeless sealant plugged the puncture in 3 seconds — rolling on!',
    ),
    BilingualTermEntry(
      key: 'deep_section_rims',
      domain: AppL10nDomain.equipmentMechanics,
      pl: 'Wysokie stożki karbonowe (65–80 mm)',
      en: 'Deep-Section Carbon Wheels',
      slangOrOrigin: 'Aero Wheelset',
      definitionPl:
          'Aerodynamiczne obręcze zmniejszające opór powietrza na płaskim, ale podatne na moment skręcający przy podmuchach bocznych.',
      definitionEn:
          'Deep aerodynamic rims saving watts on flat roads but catching steering torque in gusty crosswinds.',
      examplePl: 'Przy wietrze 45 km/h zmień przednie koło ze stożka 80 mm na 45 mm.',
      exampleEn: 'With 45 km/h gusts, swap the 80 mm front wheel down to 45 mm.',
    ),
    BilingualTermEntry(
      key: 'chain_wax',
      domain: AppL10nDomain.equipmentMechanics,
      pl: 'Woskowanie łańcucha (Hot Wax)',
      en: 'Hot-Melt Chain Waxing',
      slangOrOrigin: 'Marginal Gains',
      definitionPl:
          'Pokrycie napędu parafiną z dodatkami PTFE/WS2 zmniejszające straty tarcia o 3–5 W w porównaniu do klasycznego oleju.',
      definitionEn:
          'Paraffin/PTFE chain treatment saving 3–5 watts of drivetrain friction over traditional wet lube.',
      examplePl: 'Nowy woskowany łańcuch założony przed etapem jazdy na czas.',
      exampleEn: 'Fresh hot-waxed chain fitted for today\'s individual time trial.',
    ),

    // --- Dyscypliny (Bruk, Gravel, CX, Tor) ---
    BilingualTermEntry(
      key: 'pave_cobbles',
      domain: AppL10nDomain.disciplines,
      pl: 'Bruk (Pavé 1★–5★)',
      en: 'Cobbles (Pavé 1★–5★)',
      slangOrOrigin: 'FR: Pavé',
      definitionPl:
          'Historyczne odcinki nierównej kostki brukowej (np. Las Arenberg, Carrefour de l\'Arbre) klasyfikowane w skali trudności od 1 do 5 gwiazdek.',
      definitionEn:
          'Rough historic cobblestone sectors (e.g. Arenberg Trench) rated 1 to 5 stars for severity.',
      examplePl: 'Wjeżdżają w 5-gwiazdkowy sektor bruku — niskie ciśnienie daje przewagę!',
      exampleEn: 'Entering a 5-star pavé sector — lower tire pressure pays off!',
    ),
    BilingualTermEntry(
      key: 'sterrato',
      domain: AppL10nDomain.disciplines,
      pl: 'Białe drogi szutrowe (Sterrato)',
      en: 'Sterrato (White Gravel Roads)',
      slangOrOrigin: 'IT: Strade Bianche',
      definitionPl:
          'Kredowe, pylące drogi szutrowe Toskanii łączące przyczepność jak na szutrze z wysokim ryzykiem defektów i tumanami kurzu.',
      definitionEn:
          'Chalky white Tuscan gravel roads blending loose grip, dust clouds, and elevated puncture risk.',
      examplePl: 'Na sektorze Sterrato widoczność spada do zera przez biały pył.',
      exampleEn: 'Visibility drops to zero in the white dust cloud on Sterrato.',
    ),
    BilingualTermEntry(
      key: 'bunny_hop',
      domain: AppL10nDomain.disciplines,
      pl: 'Przeskok nad belką (Bunny-Hop)',
      en: 'Bunny-Hop',
      slangOrOrigin: 'Cyclocross (CX)',
      definitionPl:
          'Dynamiczny skok rowerem nad przeszkodami bez zsiadania w błocie, dający +1.8 s zysku na rundę przy wysokiej technice.',
      definitionEn:
          'Hopping barriers on the bike without dismounting in CX, saving ~1.8 s per lap for skilled handlers.',
      examplePl: 'Znakomity Bunny-Hop nad podwójnymi belkami — zyskał 2 sekundy!',
      exampleEn: 'Clean bunny-hop over the double barriers — 2 seconds gained!',
    ),
    BilingualTermEntry(
      key: 'cx_pit_exchange',
      domain: AppL10nDomain.disciplines,
      pl: 'Wymiana roweru w boksie (Pit Lane)',
      en: 'Pit Lane Bike Exchange',
      slangOrOrigin: 'Cyclocross (CX)',
      definitionPl:
          'Błyskawiczna 4.5-sekundowa zamiana oblepionego błotem roweru na czysty w strefie technicznej co okrążenie.',
      definitionEn:
          'Rapid 4.5-second swap from a mud-laden bike to a clean spare inside the double pit lane.',
      examplePl: 'Rower waży już +1.5 kg od błota — wjeżdżaj do boksu na zmianę!',
      exampleEn: 'Bike carrying +1.5 kg of mud — hit the pit lane for a swap!',
    ),
    BilingualTermEntry(
      key: 'black_line_track',
      domain: AppL10nDomain.disciplines,
      pl: 'Czarna linia pomiarowa',
      en: 'Black Measurement Line',
      slangOrOrigin: 'Velodrome 250 m',
      definitionPl:
          'Najkrótsza linia toru na welodromie (dokładnie 250.0 m); zejście z niej wyżej w wirażu wydłuża przejechany dystans.',
      definitionEn:
          'Innermost 250.0 m measurement line on a velodrome; drifting above it adds extra meters every lap.',
      examplePl: 'Idealnie trzyma czarną linię — równe 15.80 s na okrążenie!',
      exampleEn: 'Glued to the black line — metronomic 15.80 s lap splits!',
    ),

    // --- Sędziowie UCI i Etykieta ---
    BilingualTermEntry(
      key: 'sticky_bottle',
      domain: AppL10nDomain.juryEtiquette,
      pl: 'Lepki bidon',
      en: 'Sticky Bottle',
      slangOrOrigin: 'UCI Infraction',
      definitionPl:
          'Przedłużone trzymanie bidonu podawanego z auta drużyny (ponad 2 sekundy), by zyskać darmowe przyspieszenie; karane +20 s przez sędziego.',
      definitionEn:
          'Holding onto a bottle handed from the team car for an illegal tow; penalized +20 s by the UCI commissaire.',
      examplePl: 'Komisarz UCI wyłapał lepki bidon — +20 s kary w komunikacie!',
      exampleEn: 'UCI commissaire spotted a sticky bottle — +20 s time penalty!',
    ),
    BilingualTermEntry(
      key: 'relegation',
      domain: AppL10nDomain.juryEtiquette,
      pl: 'Relegacja na koniec grupy',
      en: 'Relegation',
      slangOrOrigin: 'UCI Sprint Rule',
      definitionPl:
          'Przesunięcie kolarza na ostatnie miejsce jego grupy za niebezpieczną zmianę toru jazdy (zajechanie drogi) w finiszu.',
      definitionEn:
          'Demoting a rider to the back of their finishing group for an irregular, dangerous sprint deviation.',
      examplePl: 'Zajechał tor w sprincie — sędziowie orzekli relegację!',
      exampleEn: 'Deviated from his sprint line — jury issued a relegation!',
    ),
    BilingualTermEntry(
      key: 'nature_break',
      domain: AppL10nDomain.juryEtiquette,
      pl: 'Przerwa fizjologiczna',
      en: 'Nature Break',
      slangOrOrigin: 'Peloton Etiquette',
      definitionPl:
          'Niepisane zawieszenie broni w peletonie, podczas którego liderzy zatrzymują się na poboczu, a atakowanie w tym momencie łamie etykietę.',
      definitionEn:
          'Unwritten peloton truce for a roadside stop; attacking during a nature break triggers backlash.',
      examplePl: 'Żółta koszulka zarządziła Nature Break — peleton zwalnia.',
      exampleEn: 'Yellow jersey called a nature break — peloton eases off.',
    ),
    BilingualTermEntry(
      key: 'neutralization',
      domain: AppL10nDomain.juryEtiquette,
      pl: 'Neutralizacja wyścigu',
      en: 'Race Neutralization',
      slangOrOrigin: 'Safety Protocol',
      definitionPl:
          'Czasowe wstrzymanie rywalizacji przez dyrekcję wyścigu lub peleton z powodu masowej kraksy, przejazdu kolejowego albo pogody.',
      definitionEn:
          'Temporary suspension of racing by organizers or the peloton due to a crash, level crossing, or extreme weather.',
      examplePl: 'Masowa kraksa na 40 km przed metą — wyścig zneutralizowany.',
      exampleEn: 'Mass pile-up with 40 km to go — race has been neutralized.',
    ),
    // --- Paczka #6 & #7: MTB XCO, Tor, Ultra-Bikepacking, R&D, UCI VAR, Organizator i Ligi ---
    BilingualTermEntry(
      key: 'ghost_pacemaker',
      domain: AppL10nDomain.raceHud,
      pl: 'Duch Wyścigu (Ghost Pacemaker)',
      en: 'Ghost Pacemaker',
      slangOrOrigin: 'Online Telemetry',
      definitionPl:
          'Półprzezroczysty awatar rywala lub własnego rekordu z ligi online ELO, wyświetlany na trasie 3D wraz z różnicą watów i sekund na żywo.',
      definitionEn:
          'Translucent avatar of an online ELO rival or personal best rendered on the 3D course with live time and wattage delta.',
      examplePl: 'Duch lidera ELO ma +4 s przewagi na podjeździe — dołóż 20 W!',
      exampleEn: 'ELO leader ghost is +4 s ahead on the climb — add 20 W!',
    ),
    BilingualTermEntry(
      key: 'kamikaze_pull',
      domain: AppL10nDomain.pelotonTactics,
      pl: 'Zmiana Kamikaze (TTT)',
      en: 'Kamikaze Pull (TTT)',
      slangOrOrigin: 'Team Time Trial',
      definitionPl:
          'Maksymalna, ostatnia zmiana pomocnika w Drużynowej Jeździe na Czas na pełnym W\' tuż przed planowanym odpuszczeniem pociągu.',
      definitionEn:
          'All-out final pull by a domestique in a Team Time Trial burning remaining W\' before dropping off the pace line.',
      examplePl: 'Wykonaj zmianę Kamikaze przez 400 m i zejdź z koła!',
      exampleEn: 'Execute a 400 m Kamikaze pull and swing off the front!',
    ),
    BilingualTermEntry(
      key: 'supertuck_descent',
      domain: AppL10nDomain.pelotonTactics,
      pl: 'Pozycja Supertuck na zjeździe',
      en: 'Supertuck Descent',
      slangOrOrigin: 'Aero Tuck',
      definitionPl:
          'Ekstremalnie aerodynamiczna sylwetka na górnej rurze ramy redukująca CdA na szybkich zjazdach alpejskich (regulowana przepisami UCI).',
      definitionEn:
          'Ultra-low aerodynamic tuck over the top tube reducing CdA on fast alpine descents (subject to UCI rulebook editions).',
      examplePl: 'Zjazd techniczny 11% — wejdź w pozycję aero i odjedź grupie!',
      exampleEn: 'Technical 11% descent — tuck into aero and gap the group!',
    ),
    BilingualTermEntry(
      key: 'vo2_priming',
      domain: AppL10nDomain.physiologyNutrition,
      pl: 'Pobudzenie VO2 przed ITT',
      en: 'VO2 Priming',
      slangOrOrigin: 'Warmup Protocol',
      definitionPl:
          'Precyzyjna rozgrzewka na trenażerze w autobusie drużyny z krótkimi zrywami powyżej FTP, dająca +4.5% mocy od pierwszej sekundy czasówki.',
      definitionEn:
          'Targeted team bus smart-trainer warmup with brief supra-threshold surges, unlocking +4.5% opening power in an ITT.',
      examplePl: 'Protokół VO2 Priming zakończony — lider gotowy na rampę startową.',
      exampleEn: 'VO2 Priming protocol complete — leader ready for the start ramp.',
    ),
    BilingualTermEntry(
      key: 'sleep_monster_ultra',
      domain: AppL10nDomain.physiologyNutrition,
      pl: 'Kryzys Senny / Mikrosen (Ultra)',
      en: 'Sleep Monster / Microsleep',
      slangOrOrigin: 'Ultra-Bikepacking',
      definitionPl:
          'Kumulacja deficytu snu w wyścigach 4000 km non-stop, obniżająca moc progową i wymagająca strategicznego bivouacu na punktach kontrolnych.',
      definitionEn:
          'Accumulated sleep deprivation in 4000 km non-stop races, degrading threshold power until a tactical checkpoint bivouac.',
      examplePl: 'Deficyt snu przekroczył 22 h — zarządzaj drzemkę 90 min na CP3.',
      exampleEn: 'Sleep deficit exceeded 22 h — schedule a 90-min nap at CP3.',
    ),
    BilingualTermEntry(
      key: 'dropper_post',
      domain: AppL10nDomain.equipmentMechanics,
      pl: 'Sztyca regulowana (Dropper Post)',
      en: 'Dropper Post',
      slangOrOrigin: 'MTB XCO Tech',
      definitionPl:
          'Teleskopowa sztyca podsiodłowa obniżająca środek ciężkości na stromych dropach i w ogrodach skalnych MTB XCO oraz Gravelu.',
      definitionEn:
          'Hydraulic seatpost lowering the rider\'s center of gravity for steep drops and rock gardens in MTB XCO and Gravel.',
      examplePl: 'Opuść Dropper Post przed dropem i wybierz szybszą linię A!',
      exampleEn: 'Drop the dropper post before the chute and take the faster A-line!',
    ),
    BilingualTermEntry(
      key: 'carbon_layup',
      domain: AppL10nDomain.equipmentMechanics,
      pl: 'Układ warstw karbonu (R&D)',
      en: 'Carbon Layup (R&D)',
      slangOrOrigin: 'In-House Brand',
      definitionPl:
          'Projektowanie orientacji włókien węglowych we własnej fabryce R&D klubu w celu zbalansowania sztywności suportu, masy i tłumienia drgań.',
      definitionEn:
          'Engineering carbon fiber ply orientation in the club\'s in-house R&D factory to balance BB stiffness, weight, and compliance.',
      examplePl: 'Nowy layup High-Modulus obniżył masę ramy o 85 g bez straty sztywności.',
      exampleEn: 'New High-Modulus layup shaved 85 g off the frame without losing stiffness.',
    ),
    BilingualTermEntry(
      key: 'rock_garden_a_line',
      domain: AppL10nDomain.disciplines,
      pl: 'Linia A / Ogród Skalny (MTB XCO)',
      en: 'A-Line / Rock Garden (MTB XCO)',
      slangOrOrigin: 'MTB XCO',
      definitionPl:
          'Krótsza, lecz technicznie ryzykowna ścieżka przez ostre głazy na rundzie XCO; szybsza o kilka sekund niż bezpieczna linia B.',
      definitionEn:
          'Shorter, high-risk line through jagged boulders on an XCO lap; seconds faster than the safer B-line bypass.',
      examplePl: 'Atakuj linię A w ogrodzie skalnym z pełną blokadą otwartą!',
      exampleEn: 'Hit the A-line through the rock garden with suspension wide open!',
    ),
    BilingualTermEntry(
      key: 'madison_hand_sling',
      domain: AppL10nDomain.disciplines,
      pl: 'Zmiana za rękę (Madison)',
      en: 'Madison Hand-Sling',
      slangOrOrigin: 'Track Cycling',
      definitionPl:
          'Dynamiczne przekazanie pędu partnerowi na welodromie poprzez chwycenie dłoni i wyrzucenie go z wirażu w wyścigu Madison.',
      definitionEn:
          'High-speed momentum transfer on the velodrome by clasping hands and slinging your teammate off the banking.',
      examplePl: 'Perfekcyjny hand-sling na wirażu — łapiemy okrążenie przewagi!',
      exampleEn: 'Clean hand-sling off the banking — we are taking a lap!',
    ),
    BilingualTermEntry(
      key: 'derny_pacer',
      domain: AppL10nDomain.disciplines,
      pl: 'Motocykl Derny (Keirin)',
      en: 'Derny Pacer (Keirin)',
      slangOrOrigin: 'Track Keirin',
      definitionPl:
          'Lekki motocykl nadający rosnące tempo do 50 km/h przed zjazdem z toru na 2.5 okrążenia przed metą w sprincie Keirin.',
      definitionEn:
          'Motorized pacer ramping speed up to 50 km/h before pulling off with 2.5 laps to go in a Keirin sprint.',
      examplePl: 'Derny zjeżdża z toru — zaczynamy finałowy sprint na 62T!',
      exampleEn: 'Derny pulls off — launch the final sprint on the 62T ring!',
    ),
    BilingualTermEntry(
      key: 'dot_watching',
      domain: AppL10nDomain.disciplines,
      pl: 'Śledzenie Kropek (Dot-Watching)',
      en: 'Dot-Watching',
      slangOrOrigin: 'Ultra-Bikepacking',
      definitionPl:
          'Obserwowanie nadajników GPS kolarzy na mapie podczas wielodniowych wyścigów Ultra-Bikepacking 4000 km bez wsparcia wozów.',
      definitionEn:
          'Tracking riders\' live GPS beacons across 4000 km self-supported ultra-endurance bikepacking races.',
      examplePl: 'Kropka lidera nie rusza się od 3 godzin — regeneracja w schronisku.',
      exampleEn: 'The leader\'s dot has been stationary for 3 hours — resting at a shelter.',
    ),
    BilingualTermEntry(
      key: 'grand_depart',
      domain: AppL10nDomain.careerManagement,
      pl: 'Grand Départ (Start Honorowy)',
      en: 'Grand Départ',
      slangOrOrigin: 'Race Organizer HQ',
      definitionPl:
          'Uroczyste otwarcie Wielkiego Touru przyznawane w przetargu miastom gospodarzom przez organizatora (ASO/RCS) za wielomilionowe wpisowe.',
      definitionEn:
          'Prestigious Grand Tour opening stages awarded by the race organizer (ASO/RCS) via host-city bidding.',
      examplePl: 'Miasto gospodarz wygrało przetarg na Grand Départ — +4.5M € do budżetu.',
      exampleEn: 'Host city won the Grand Départ bid — +€4.5M into organizer ledger.',
    ),
    BilingualTermEntry(
      key: 'sprint_deviation_var',
      domain: AppL10nDomain.juryEtiquette,
      pl: 'Analiza VAR Toru Sprintu',
      en: 'Sprint Deviation VAR',
      slangOrOrigin: 'UCI Video Jury',
      definitionPl:
          'Powtórka wideo z kamery czołowej i helikoptera oceniająca, czy sprinter bezprawnie zjechał z linii jazdy w ostatnich 200 m.',
      definitionEn:
          'Overhead and head-on video review verifying whether a sprinter illegally deviated from their line in the final 200 m.',
      examplePl: 'Sędziowie analizują Sprint VAR — możliwa relegacja i żółta kartka!',
      exampleEn: 'Commissaires reviewing Sprint VAR — relegation and yellow card possible!',
    ),
    BilingualTermEntry(
      key: 'uci_yellow_card',
      domain: AppL10nDomain.juryEtiquette,
      pl: 'Żółta kartka UCI',
      en: 'UCI Yellow Card',
      slangOrOrigin: 'UCI Rulebook',
      definitionPl:
          'Oficjalne ostrzeżenie dyscyplinarne dla kolarza lub dyrektora sportowego; dwie żółte kartki w wyścigu skutkują dyskwalifikacją.',
      definitionEn:
          'Official disciplinary caution for a rider or sports director; two yellow cards in one race result in disqualification.',
      examplePl: 'Otrzymałeś żółtą kartkę UCI — kolejne wykroczenie oznacza DSQ.',
      exampleEn: 'Issued a UCI Yellow Card — another infraction means immediate DSQ.',
    ),

    // --- Paczka #8: Złota Era, e-Sports, ESG, Caravan Drafting, Reprezentacja & NG+ ---
    BilingualTermEntry(
      key: 'borg_rpe_scale',
      domain: AppL10nDomain.physiologyNutrition,
      pl: 'Skala RPE Borga (6–20)',
      en: 'Borg RPE Scale (6–20)',
      slangOrOrigin: 'Golden Era 1970–2015',
      definitionPl:
          'Subiektywna ocena odczuwanego wysiłku (od 6 do 20) używana w trybie Złotej Ery zamiast nowoczesnych mierników mocy W i W\'bal.',
      definitionEn:
          'Rating of Perceived Exertion (6–20) used in the Golden Era mode instead of modern powermeters and live W\'bal telemetry.',
      examplePl: 'Jedziemy bez watomierza — lider zgłasza RPE 17 na podjeździe!',
      exampleEn: 'No powermeter today — leader reports Borg RPE 17 on the climb!',
    ),
    BilingualTermEntry(
      key: 'friction_downtube_shifters',
      domain: AppL10nDomain.equipmentMechanics,
      pl: 'Manetki cierne na ramie',
      en: 'Friction Downtube Shifters',
      slangOrOrigin: 'Retro Steel Era',
      definitionPl:
          'Klasyczne dźwignie zmiany przełożeń na dolnej rurze stalowej ramy (np. Columbus SL), wprowadzające opóźnienie zmiany biegu i konieczność wyczucia łańcucha.',
      definitionEn:
          'Classic gear levers mounted on the downtube of steel frames (e.g. Columbus SL), adding shift latency and chain-trim skill checks.',
      examplePl: 'Przed stromą ścianką sięgnij po manetkę na dolnej rurze z wyprzedzeniem.',
      exampleEn: 'Reach down for the friction shifter well before the steep ramp.',
    ),
    BilingualTermEntry(
      key: 'caravan_drafting',
      domain: AppL10nDomain.pelotonTactics,
      pl: 'Jazda w kolumnie wozów (Caravan Drafting)',
      en: 'Caravan Drafting',
      slangOrOrigin: 'Convoy Slipstream',
      definitionPl:
          'Wykorzystywanie głębokiego cienia aerodynamicznego za wozami technicznymi i motocyklami TV podczas powrotu do peletonu po defekcie, obarczone ryzykiem kary sędziowskiej.',
      definitionEn:
          'Using the deep slipstream behind team cars and TV motos to bridge back after a mechanical, balancing speed gain against UCI penalty risk.',
      examplePl: 'Wskocz w kolumnę wozów po zmianie koła, ale uważaj na oko komisarza!',
      exampleEn: 'Slip through the car caravan after the wheel change, but watch the commissaire!',
    ),
    BilingualTermEntry(
      key: 'esports_burrito_powerup',
      domain: AppL10nDomain.disciplines,
      pl: 'Power-Up Burrito (UCI e-Sports)',
      en: 'Burrito Power-Up (UCI e-Sports)',
      slangOrOrigin: 'Virtual Racing',
      definitionPl:
          'Taktyczny bonus w wirtualnych wyścigach na trenażerach Smart, który odcina rywalom jadącym z tyłu korzyść z draftu aerodynamicznego na kilkanaście sekund.',
      definitionEn:
          'Tactical power-up in virtual Smart-trainer races that temporarily disables aerodynamic drafting for rivals sitting behind your wheel.',
      examplePl: 'Odpalaj Power-Up Burrito tuż przed eliminacją za 10 sekund!',
      exampleEn: 'Trigger the Burrito power-up right before the 10-second elimination gate!',
    ),
    BilingualTermEntry(
      key: 'cpa_extreme_weather_protocol',
      domain: AppL10nDomain.juryEtiquette,
      pl: 'Protokół ekstremalnej pogody UCI / CPA',
      en: 'UCI / CPA Extreme Weather Protocol',
      slangOrOrigin: 'Art. 2.2.029bis',
      definitionPl:
          'Procedura bezpieczeństwa uruchamiana wspólnie przez komisarzy UCI i stowarzyszenie kolarzy CPA przy wichurach, śnieżycach lub upałach, prowadząca do skrócenia lub zmiany trasy etapu.',
      definitionEn:
          'Safety procedure triggered by UCI commissaires and the CPA riders\' union during storms, snow, or extreme heat to shorten or reroute a stage.',
      examplePl: 'Peleton przegłosował protest CPA — dyrektor wyścigu skraca przełęcz.',
      exampleEn: 'Peloton voted for the CPA protocol — race director reroutes around the summit.',
    ),
    BilingualTermEntry(
      key: 'esg_carbon_ledger',
      domain: AppL10nDomain.careerManagement,
      pl: 'Zielona Flota i Bilans CO2 (ESG)',
      en: 'Green Fleet & CO2 Ledger (ESG)',
      slangOrOrigin: 'Team Sustainability',
      definitionPl:
          'System zarządzania elektrycznymi i wodorowymi wozami konwoju drużyny oraz śladem węglowym logistyki, otwierający dostęp do lukratywnych zielonych sponsorów.',
      definitionEn:
          'Management of electric/hydrogen team convoy vehicles and travel emissions ledger, unlocking high-value sustainability sponsor contracts.',
      examplePl: 'Przejście na flotę EV podniosło ocenę ESG i odblokowało nowego sponsora.',
      exampleEn: 'Switching to an EV convoy boosted our ESG rating and unlocked a green sponsor.',
    ),
    BilingualTermEntry(
      key: 'transfer_deadline_day',
      domain: AppL10nDomain.careerManagement,
      pl: 'Transfer Deadline Day',
      en: 'Transfer Deadline Day',
      slangOrOrigin: 'Mercato Finale',
      definitionPl:
          'Ostatnie 24 godziny okna transferowego z odliczaniem godzinowym na żywo i nagłymi ofertami agentów przed zamknięciem składów na nowy sezon.',
      definitionEn:
          'Final 24-hour countdown of the transfer window featuring live breaking-news tickers and last-minute agent contract offers.',
      examplePl: 'Zostały 2 godziny Deadline Day — agent oferuje nam wolnego sprintera!',
      exampleEn: '2 hours left on Deadline Day — an agent just pitched a free-agent sprinter!',
    ),
    BilingualTermEntry(
      key: 'manager_dynasty_ng_plus',
      domain: AppL10nDomain.careerManagement,
      pl: 'Księga Legendy (New Game+ / Dynastia)',
      en: 'Manager Legacy Book (NG+ / Dynasty)',
      slangOrOrigin: 'Hall of Fame',
      definitionPl:
          'Podsumowanie wieloletniej kariery menedżera po przejściu na emeryturę, pozwalające rozpocząć nową dynastię z zachowaniem dziedzictwa i prestiżu.',
      definitionEn:
          'Permanent career chronicle unlocked upon retirement, allowing you to launch a New Game+ dynasty carrying forward prestige and legacy records.',
      examplePl: 'Księga Legendy zapisana — rozpocznij nową dynastię jako mentor akademii!',
      exampleEn: 'Legacy Book archived — start a New Game+ dynasty as academy mentor!',
    ),
  ];

  /// Sprawdza, czy klucz istnieje w słowniku UI lub w bazowym [AppLocalizationsPlEn].
  static bool hasKey(String key) {
    if (uiStrings.containsKey(key)) return true;
    final fallback = AppLocalizationsPlEn.ofLanguage(AppLanguage.pl).t(key);
    return fallback != key;
  }

  /// Tłumaczy klucz UI z obsługą fallbacku do [AppLocalizationsPlEn] oraz parametrów `{name}`.
  static String translate(
    String key,
    AppLanguage language, {
    Map<String, Object>? params,
  }) {
    final entry = uiStrings[key];
    String text;
    if (entry != null) {
      text = language == AppLanguage.pl ? entry.pl : entry.en;
    } else {
      text = AppLocalizationsPlEn.ofLanguage(language).t(key);
    }

    if (params != null && params.isNotEmpty) {
      params.forEach((paramKey, paramValue) {
        text = text.replaceAll('{$paramKey}', paramValue.toString());
      });
    }
    return text;
  }

  /// Odmiana liczebnikowa uwzględniająca polską gramatykę (1 / 2-4 / 5+) oraz angielską (1 / many).
  static String pluralize(
    AppLanguage language,
    int count, {
    required String plOne,
    required String plFew,
    required String plMany,
    required String enOne,
    required String enMany,
  }) {
    final absCount = count.abs();
    if (language == AppLanguage.en) {
      return absCount == 1 ? '$count $enOne' : '$count $enMany';
    }

    final mod10 = absCount % 10;
    final mod100 = absCount % 100;
    if (absCount == 1) {
      return '$count $plOne';
    }
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return '$count $plFew';
    }
    return '$count $plMany';
  }

  /// Wyszukuje hasła żargonu kolarskiego po frazie i opcjonalnej domenie.
  static List<BilingualTermEntry> searchJargon(
    String query, {
    AppL10nDomain? domain,
  }) {
    final normalized = query.trim().toLowerCase();
    return jargonEntries.where((entry) {
      if (domain != null && entry.domain != domain) return false;
      return entry.matchesQuery(normalized);
    }).toList(growable: false);
  }

  /// Zwraca wszystkie hasła żargonu przypisane do danej domeny.
  static List<BilingualTermEntry> entriesForDomain(AppL10nDomain domain) {
    return jargonEntries
        .where((entry) => entry.domain == domain)
        .toList(growable: false);
  }

  /// Weryfikuje kompletność i brak duplikatów w słowniku PL/EN.
  static DictionaryCompletenessReport auditCompleteness() {
    final invalid = <String>[];
    final duplicates = <String>[];
    final seenJargonKeys = <String>{};

    uiStrings.forEach((key, value) {
      if (key.trim().isEmpty ||
          value.pl.trim().isEmpty ||
          value.en.trim().isEmpty) {
        invalid.add(key);
      }
    });

    for (final entry in jargonEntries) {
      if (!seenJargonKeys.add(entry.key)) {
        duplicates.add(entry.key);
      }
      if (entry.key.trim().isEmpty ||
          entry.pl.trim().isEmpty ||
          entry.en.trim().isEmpty ||
          entry.definitionPl.trim().isEmpty ||
          entry.definitionEn.trim().isEmpty ||
          entry.examplePl.trim().isEmpty ||
          entry.exampleEn.trim().isEmpty) {
        invalid.add('jargon:${entry.key}');
      }
    }

    return DictionaryCompletenessReport(
      totalUiKeys: uiStrings.length,
      totalJargonEntries: jargonEntries.length,
      emptyOrInvalidKeys: List<String>.unmodifiable(invalid),
      duplicateKeys: List<String>.unmodifiable(duplicates),
    );
  }
}

/// Delegat Fluttera do integracji [AppLocalizationsPlEn] z `MaterialApp.localizationsDelegates`.
class AppL10nDelegate extends LocalizationsDelegate<AppLocalizationsPlEn> {
  const AppL10nDelegate();

  static const List<Locale> supportedLocales = [
    Locale('pl'),
    Locale('en'),
  ];

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'pl' || locale.languageCode == 'en';

  @override
  Future<AppLocalizationsPlEn> load(Locale locale) {
    final language = locale.languageCode == 'en'
        ? AppLanguage.en
        : AppLanguage.pl;
    return SynchronousFuture<AppLocalizationsPlEn>(
      AppLocalizationsPlEn.ofLanguage(language),
    );
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizationsPlEn> old) =>
      false;
}

/// Produkcyjny, responsywny panel przeglądarki dwujęzycznego słownika i żargonu kolarskiego PL/EN.
class CyclingJargonDictionaryPanel extends StatefulWidget {
  final AppLanguage initialLanguage;
  final ValueChanged<AppLanguage>? onLanguageChanged;
  final bool allowLanguageSwitch;

  const CyclingJargonDictionaryPanel({
    super.key,
    this.initialLanguage = AppLanguage.pl,
    this.onLanguageChanged,
    this.allowLanguageSwitch = true,
  });

  @override
  State<CyclingJargonDictionaryPanel> createState() =>
      _CyclingJargonDictionaryPanelState();
}

class _CyclingJargonDictionaryPanelState
    extends State<CyclingJargonDictionaryPanel> {
  late AppLanguage _language;
  late final TextEditingController _searchController;
  AppL10nDomain? _selectedDomain;
  late BilingualTermEntry _selectedEntry;
  String? _copiedTermKey;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
    _searchController = TextEditingController();
    _selectedEntry = BilingualCyclingDictionary.jargonEntries.first;
  }

  @override
  void didUpdateWidget(covariant CyclingJargonDictionaryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLanguage != widget.initialLanguage) {
      _language = widget.initialLanguage;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setLanguage(AppLanguage next) {
    if (!widget.allowLanguageSwitch || _language == next) return;
    setState(() {
      _language = next;
    });
    widget.onLanguageChanged?.call(next);
  }

  Future<void> _copySelectedTerm(BilingualTermEntry entry) async {
    final termText = '${entry.pl} / ${entry.en}';
    await Clipboard.setData(ClipboardData(text: termText));
    if (!mounted) return;
    setState(() {
      _copiedTermKey = entry.key;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceLight,
        content: Text(
          BilingualCyclingDictionary.translate(
            'l10n_copied_feedback',
            _language,
            params: {'term': termText},
          ),
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = BilingualCyclingDictionary.searchJargon(
      _searchController.text,
      domain: _selectedDomain,
    );
    final activeEntry = filteredEntries.contains(_selectedEntry)
        ? _selectedEntry
        : (filteredEntries.isNotEmpty ? filteredEntries.first : null);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 680;
          final isDesktop = constraints.maxWidth >= 1120;

          return Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isMobile: isMobile, visibleCount: filteredEntries.length),
                const SizedBox(height: 14),
                _buildSearchAndDomainBar(isMobile: isMobile),
                const SizedBox(height: 16),
                if (filteredEntries.isEmpty)
                  _buildEmptyState()
                else if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildEntriesGrid(
                          entries: filteredEntries,
                          activeEntry: activeEntry,
                          crossAxisCount: 2,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (activeEntry != null)
                        Expanded(
                          flex: 4,
                          child: _buildInspectorCard(activeEntry),
                        ),
                    ],
                  )
                else ...[
                  if (activeEntry != null) ...[
                    _buildInspectorCard(activeEntry),
                    const SizedBox(height: 14),
                  ],
                  _buildEntriesGrid(
                    entries: filteredEntries,
                    activeEntry: activeEntry,
                    crossAxisCount: isMobile ? 1 : 2,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader({required bool isMobile, required int visibleCount}) {
    final title = BilingualCyclingDictionary.translate(
      'l10n_panel_title',
      _language,
    );
    final subtitle = BilingualCyclingDictionary.translate(
      'l10n_panel_subtitle',
      _language,
    );

    final statsWrap = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatBadge(
          label: BilingualCyclingDictionary.translate(
            'l10n_stats_ui_keys',
            _language,
          ),
          value: '${BilingualCyclingDictionary.uiStrings.length}',
          accent: AppColors.accentBlue,
        ),
        _StatBadge(
          label: BilingualCyclingDictionary.translate(
            'l10n_stats_jargon',
            _language,
          ),
          value: '${BilingualCyclingDictionary.jargonEntries.length}',
          accent: AppColors.goldAccent,
        ),
        _StatBadge(
          label: BilingualCyclingDictionary.translate(
            'l10n_stats_filtered',
            _language,
          ),
          value: '$visibleCount',
          accent: AppColors.statusSuccess,
        ),
      ],
    );

    final languageSwitcher = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LanguagePillButton(
          label: 'PL',
          selected: _language == AppLanguage.pl,
          enabled: widget.allowLanguageSwitch,
          onTap: () => _setLanguage(AppLanguage.pl),
        ),
        const SizedBox(width: 8),
        _LanguagePillButton(
          label: 'EN',
          selected: _language == AppLanguage.en,
          enabled: widget.allowLanguageSwitch,
          onTap: () => _setLanguage(AppLanguage.en),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.translate_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              statsWrap,
              languageSwitcher,
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.translate_rounded,
            color: AppColors.goldAccent,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              statsWrap,
            ],
          ),
        ),
        const SizedBox(width: 16),
        languageSwitcher,
      ],
    );
  }

  Widget _buildSearchAndDomainBar({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            hintText: BilingualCyclingDictionary.translate(
              'l10n_search_hint',
              _language,
            ),
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.textSecondary,
              size: 18,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    tooltip: BilingualCyclingDictionary.translate(
                      'l10n_clear_filters',
                      _language,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2A2F3D)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.goldAccent,
                width: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _DomainFilterChip(
                label: BilingualCyclingDictionary.translate(
                  'l10n_all_domains',
                  _language,
                ),
                icon: Icons.apps,
                selected: _selectedDomain == null,
                onTap: () => setState(() => _selectedDomain = null),
              ),
              const SizedBox(width: 8),
              ...AppL10nDomain.values.map(
                (domain) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _DomainFilterChip(
                    label: domain.label(_language),
                    icon: domain.icon,
                    selected: _selectedDomain == domain,
                    onTap: () => setState(() => _selectedDomain = domain),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: AppColors.textSecondary,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            BilingualCyclingDictionary.translate(
              'l10n_empty_results',
              _language,
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label: BilingualCyclingDictionary.translate(
              'l10n_clear_filters',
              _language,
            ),
            icon: Icons.refresh,
            onPressed: () {
              _searchController.clear();
              setState(() => _selectedDomain = null);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesGrid({
    required List<BilingualTermEntry> entries,
    required BilingualTermEntry? activeEntry,
    required int crossAxisCount,
  }) {
    if (crossAxisCount == 1) {
      return Column(
        children: entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _JargonEntryTile(
                  entry: entry,
                  language: _language,
                  selected: activeEntry?.key == entry.key,
                  onTap: () => setState(() => _selectedEntry = entry),
                ),
              ),
            )
            .toList(growable: false),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i += 2) {
      final first = entries[i];
      final second = i + 1 < entries.length ? entries[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _JargonEntryTile(
                  entry: first,
                  language: _language,
                  selected: activeEntry?.key == first.key,
                  onTap: () => setState(() => _selectedEntry = first),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: second != null
                    ? _JargonEntryTile(
                        entry: second,
                        language: _language,
                        selected: activeEntry?.key == second.key,
                        onTap: () => setState(() => _selectedEntry = second),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildInspectorCard(BilingualTermEntry entry) {
    final isCopied = _copiedTermKey == entry.key;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(entry.domain.icon, color: AppColors.goldAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.domain.label(_language),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.goldAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _ActionButton(
                label: BilingualCyclingDictionary.translate(
                  'l10n_copy_term',
                  _language,
                ),
                icon: isCopied ? Icons.check : Icons.copy_rounded,
                onPressed: () => _copySelectedTerm(entry),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            entry.term(_language),
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2F3D)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  'PL: ${entry.pl}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'EN: ${entry.en}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.accentBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (entry.slangOrOrigin != null) ...[
            const SizedBox(height: 10),
            Text(
              '${BilingualCyclingDictionary.translate('l10n_origin_label', _language)}: ${entry.slangOrOrigin}',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            BilingualCyclingDictionary.translate(
              'l10n_definition_label',
              _language,
            ),
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.definition(_language),
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            BilingualCyclingDictionary.translate(
              'l10n_example_label',
              _language,
            ),
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2F3D)),
            ),
            child: Text(
              '“${entry.example(_language)}”',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textPrimary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguagePillButton extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _LanguagePillButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_LanguagePillButton> createState() => _LanguagePillButtonState();
}

class _LanguagePillButtonState extends State<_LanguagePillButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surface.withValues(alpha: 0.45)
        : widget.selected
            ? AppColors.primaryAccent
            : (_pressed
                ? AppColors.surfaceLight
                : (_hovered ? AppColors.surfaceLight : AppColors.surface));
    final borderColor = !widget.enabled
        ? const Color(0xFF2A2F3D).withValues(alpha: 0.5)
        : (_focused
            ? AppColors.goldAccent
            : (widget.selected
                ? AppColors.goldAccent
                : const Color(0xFF2A2F3D)));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: widget.enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _DomainFilterChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DomainFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_DomainFilterChip> createState() => _DomainFilterChipState();
}

class _DomainFilterChipState extends State<_DomainFilterChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.9)
        : (_pressed || _hovered ? AppColors.surfaceLight : AppColors.surface);
    final borderColor = _focused
        ? AppColors.goldAccent
        : (widget.selected ? AppColors.goldAccent : const Color(0xFF2A2F3D));

    return FocusableActionDetector(
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: widget.selected
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JargonEntryTile extends StatefulWidget {
  final BilingualTermEntry entry;
  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  const _JargonEntryTile({
    required this.entry,
    required this.language,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_JargonEntryTile> createState() => _JargonEntryTileState();
}

class _JargonEntryTileState extends State<_JargonEntryTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? AppColors.surfaceLight
        : (_pressed || _hovered ? AppColors.surfaceLight : AppColors.surface);
    final borderColor = _focused || widget.selected
        ? AppColors.goldAccent
        : (_hovered
            ? AppColors.accentBlue.withValues(alpha: 0.6)
            : const Color(0xFF2A2F3D));

    return FocusableActionDetector(
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: _focused || widget.selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.entry.domain.icon,
                    size: 15,
                    color: widget.selected
                        ? AppColors.goldAccent
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.entry.term(widget.language),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.language == AppLanguage.pl
                    ? 'EN: ${widget.entry.en}'
                    : 'PL: ${widget.entry.pl}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.accentBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.entry.definition(widget.language),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final bgColor = !enabled
        ? AppColors.surface.withValues(alpha: 0.45)
        : (_pressed
            ? AppColors.primaryAccent
            : (_hovered ? AppColors.surfaceLight : AppColors.surface));
    final borderColor = !enabled
        ? const Color(0xFF2A2F3D).withValues(alpha: 0.5)
        : (_focused ? AppColors.goldAccent : const Color(0xFF2A2F3D));

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _focused ? 1.4 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: enabled ? AppColors.goldAccent : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
