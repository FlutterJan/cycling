# Pro Peloton Manager — Mapa Projektu (`CODE_MAP.md`)

> Szybka ściąga architektoniczna dla agentów. Zawsze czytaj ten plik przed rozpoczęciem zadania zamiast skanować dysk.

---

## 1. Architektura i Technologie

- **Framework**: Flutter (Dart SDK `>=3.3.0 <4.0.0`), aplikacja desktop/mobile (`windows` + responsive).
- **State Management**: `flutter_riverpod` (`^2.5.1`) — `StateNotifierProvider`, `Provider`, `AsyncNotifier`.
- **Routing**: `go_router` (`^14.2.0`) — definicje tras w `lib/core/router/app_router.dart` (`AppRoutes`).
- **Symulacja i Wielowątkowość**:
  - `StageSimulationLoop` (`lib/engine/simulation/stage_simulation_loop.dart`) + `IsolateSimulationWorker` (`lib/engine/simulation/isolate_simulation_worker.dart`).
  - `RaceSimulationNotifier` (`lib/state/race_simulation_notifier.dart`) emituje co sekundę `RiderPositionSnapshot` dla widoku 3D, HUD i wykresów 2D.
- **Renderowanie 3D i Wykresy**:
  - Natywny rzutnik 3D na `CustomPainter` (`Scene3dMathProjection`, `PelotonInstancedRenderer`, `RoadRibbonMeshBuilder`, `CameraRigController`).
  - Assety `.glb` generowane przez skrypty `blender_scripts/*.py` (`flutter_3d_controller`, `assets/3d/...`).
  - Wykresy: `fl_chart` (`^0.68.0`+) oraz dedykowane `CustomPainter`.
- **Trwałość Danych**: JSON save slots (`SaveGameManager`, `SaveService`) oraz `isar` (`^3.1.0+1`), `path_provider`.

---

## 2. System Projektowy i Style UI

- **Paleta Kolorów** (`lib/core/theme/app_colors.dart` & `lib/core/theme/app_theme.dart`):
  - Tło główne: `#0F1115` (`AppColors.background`)
  - Karty / Panele: `#181B22` (`AppColors.surface`), podniesione `#222630` (`AppColors.surfaceLight`)
  - Obramowania: `#2A2F3D` (`AppTheme.borderColor`), `#2E3440` (`AppColors.cardBorder`)
  - Akcent główny (Burgund): `#8E4A49` (`AppColors.primaryAccent`)
  - Akcent mistrzowski (Złoto): `#D4AF37` (`AppColors.goldAccent`)
  - Akcenty telemetryczne: `#38BDF8` (`accentBlue`), `#00E5FF` (`cyanAccent`)
  - Statusy: `#10B981` (`statusSuccess`), `#F59E0B` (`amberWarning`), `#EF4444` (`crimsonAlert`)
  - Tekst: `#F3F4F6` (`textPrimary`), `#9CA3AF` (`textSecondary`)
- **Typografia**: `Inter` (`fontFamily: 'Inter'`, `letterSpacing: -0.2`); liczby telemetryczne z `tabularFigures`.
- **Karty i Kontenery**: `elevation: 0`, `BorderRadius.circular(16)`, obramowanie `1.0px` w kolorze `#2A2F3D`.
- **Animacje i Responsywność**: Płynne przejścia `200–350ms` (`Curves.easeOutCubic`), pełne stany `hover`/`active`/`disabled`/`focus`, obsługa `LayoutBuilder` dla `390x844`, `1024x768`, `1600x900`.

---

## 3. Główne Klasy, Stany i Interfejsy

- **Kariera & Świat**: `CareerState`, `CareerInboxMessage`, `InboxCategory`, `InboxPriority` (`lib/state/career_state_notifier.dart`), `CareerSave` (`lib/models/career/career_save.dart`), `SeasonCalendar` (`lib/models/career/season_calendar.dart`).
- **Drużyna & Sponsorzy**: `CyclingTeam`, `TeamDivision`, `TeamStaff` (`lib/models/team/cycling_team.dart`), `SponsorContract`, `SponsorObjective`, `SponsorIndustry`, `SponsorTier`, `ObjectiveImportance` (`lib/models/team/sponsor_contract.dart`), `BikeManufacturerDeal` (`lib/models/team/bike_manufacturer_deal.dart`).
- **Kolarz**: `Rider`, `RiderPhysiology`, `RiderPowerProfile`, `LactateAndLabProfile`, `RiderSkills`, `RiderHealth`, `RiderContract`, `RiderAppearance` (`lib/models/rider/`).
- **Wyścig & Sprzęt**: `RaceStage`, `StageSegment`, `TourRace` (`lib/models/race/`), `CompleteBike`, `FrameModel`, `WheelsetModel`, `TireModel`, `GroupsetModel`, `BikeFitConfiguration` (`lib/models/equipment/`).
- **Symulacja Wyścigu**: `RiderPositionSnapshot`, `RiderRaceState`, `TacticalOrder`, `GroupType`.

---

## 4. Drzewo Plików Projektu (`lib/`)

### `lib/` & `lib/core/`
- `lib/main.dart` — Punkt wejścia aplikacji, `ProviderScope` i konfiguracja motywu/routera.
- `lib/core/constants/physics_constants.dart` — Stałe fizyczne (grawitacja, gęstość powietrza, opory toczenia).
- `lib/core/router/app_router.dart` — Konfiguracja `GoRouter` i stałych `AppRoutes`.
- `lib/core/theme/app_colors.dart` — Paleta kolorów gry i stref mocy Z1–Z7.
- `lib/core/theme/app_theme.dart` — Ciemny motyw `ThemeData`, typografia `Inter` i style kart.
- `lib/core/utils/formatters.dart` — Formatery czasu, walut (`€`), watów, prędkości i dystansu.
- `lib/core/utils/performance_profiler_overlay.dart` — Nakładka diagnostyczna `PerformanceProfilerOverlay` (`F3`, FPS, Frame Time Graph, telemetria `PerformanceTelemetryRegistry` Isolate/LOD/RAM).

### `lib/models/`
- `lib/models/career/career_save.dart` — Model pełnego zapisu kariery.
- `lib/models/career/recovery_protocol_system.dart` — Protokoły regeneracji i zabiegi medyczne.
- `lib/models/career/season_calendar.dart` — Kalendarz wyścigów WorldTour/ProSeries/GT.
- `lib/models/career/staff_member.dart` — Model personelu (dyrektorzy, mechanicy, lekarze, skauci).
- `lib/models/equipment/bike_fit_configuration.dart` — Pozycja kolarza na rowerze i wpływ na CdA.
- `lib/models/equipment/complete_bike.dart` — Złożony rower drużynowy (rama, koła, opony, grupa).
- `lib/models/equipment/equipment_wear_and_maintenance.dart` — Zużycie sprzętu i stan wosku/łańcucha.
- `lib/models/equipment/frame_model.dart` — Model ramy (aero, climbing, TT) i waga/sztywność.
- `lib/models/equipment/groupset_model.dart` — Model osprzętu / grupy napędowej.
- `lib/models/equipment/tire_model.dart` — Model opon (CRR, szerokość, odporność na przebicia).
- `lib/models/equipment/wheelset_model.dart` — Model kół (stożek, aero, waga).
- `lib/models/race/race_stage.dart` — Model etapu lub wyścigu jednodniowego.
- `lib/models/race/stage_segment.dart` — Segment trasy (długość, nachylenie, nawierzchnia, wiatr).
- `lib/models/race/tour_race.dart` — Model wyścigu wieloetapowego i klasyfikacji (GC, Punkty, Góry, Młodzież).
- `lib/models/rider/lactate_and_lab_profile.dart` — Profil mleczanowy LT1, LT2, VLaMax, VO2max.
- `lib/models/rider/rider.dart` — Główny model kolarza łączący atrybuty, zdrowie i kontrakt.
- `lib/models/rider/rider_appearance.dart` — Wygląd twarzy, kasku, okularów i sylwetki.
- `lib/models/rider/rider_contract.dart` — Kontrakt, pensja, klauzule i długość umowy.
- `lib/models/rider/rider_health.dart` — Zmęczenie, kontuzje, forma CTL/ATL/TSB i morale.
- `lib/models/rider/rider_physiology.dart` — Fizjologia (FTP, W', waga, wzrost, kadencja).
- `lib/models/rider/rider_power_profile.dart` — Krzywa mocy (5s, 1m, 5m, 20m, 60m).
- `lib/models/rider/rider_skills.dart` — Umiejętności kolarskie (płaskie, góry, sprint, bruk, zjazdy, TT).
- `lib/models/settings/game_settings.dart` — Ustawienia gry (grafika, audio, jednostki, język).
- `lib/models/team/bike_manufacturer_deal.dart` — Kontrakt sprzętowy z producentem rowerów.
- `lib/models/team/cycling_team.dart` — Model drużyny kolarskiej, budżetu, dywizji i malowania.
- `lib/models/team/sponsor_contract.dart` — Umowa sponsorska i cele sezonowe (`SponsorObjective`).

### `lib/engine/`
- `lib/engine/audio/procedural_cycling_audio_engine.dart` — Synteza dźwięku wiatru, bębenka i tłumu.
- `lib/engine/audio/race_radio_tts_and_beeps.dart` — Sygnały radia wyścigowego i alarmy Garmin.
- `lib/engine/events/race_incident_engine.dart` — Generator kraks, defektów i przebić opon.
- `lib/engine/events/race_radio_generator.dart` — Generator komunikatów dyrektora sportowego.
- `lib/engine/peloton/breakaway_ai_controller.dart` — AI ucieczki i współpracy w odjeździe.
- `lib/engine/peloton/drafting_grid_system.dart` — Siatka aerodynamiczna peletonu i oszczędność W.
- `lib/engine/peloton/echelon_crosswind_engine.dart` — Silnik wiatru bocznego i formowania wachlarzy.
- `lib/engine/peloton/feeding_and_rain_jacket_mechanics.dart` — Mechanika bidonów, żeli i peleryn przeciwdeszczowych.
- `lib/engine/peloton/mountain_gc_ai_controller.dart` — AI faworytów GC na podjazdach górskich.
- `lib/engine/peloton/peloton_chase_ai_controller.dart` — AI pościgu peletonu za ucieczką.
- `lib/engine/peloton/rider_race_state.dart` — Dynamiczny stan kolarza podczas etapu.
- `lib/engine/peloton/sprint_train_ai_controller.dart` — AI pociągów sprinterskich i rozprowadzania.
- `lib/engine/peloton/tactical_orders_processor.dart` — Przetwarzanie rozkazów taktycznych gracza.
- `lib/engine/physics/aero_calculator.dart` — Obliczenia oporu aerodynamicznego CdA i wiatru.
- `lib/engine/physics/bike_fit_and_wind_tunnel_engine.dart` — Symulacja tunelu aero i bike fittingu.
- `lib/engine/physics/gravity_and_rolling_calculator.dart` — Siła grawitacji i opory toczenia CRR.
- `lib/engine/physics/heart_rate_simulator.dart` — Kinetyka tętna BPM w zależności od wysiłku.
- `lib/engine/physics/nutrition_and_glycogen_engine.dart` — Spalanie glikogenu, węglowodany i "odcięcie prądu".
- `lib/engine/physics/speed_solver.dart` — Solver prędkości m/s z mocy W i sił oporu.
- `lib/engine/physics/tire_pressure_calculator.dart` — Kalkulator optymalnego ciśnienia BAR/PSI.
- `lib/engine/physics/w_prime_balance_engine.dart` — Model Skiba W'bal (zużycie i regeneracja beztlenowa).
- `lib/engine/rendering3d/camera_rig_controller.dart` — Kamery wyścigowe (helikopter, moto, tył, pierwsza osoba).
- `lib/engine/rendering3d/crash_and_mechanical_visuals.dart` — Wizualizacja kraks i defektów na trasie 3D.
- `lib/engine/rendering3d/cyclist_3d_pose_animator.dart` — Animacja kadencji, jazdy na stojąco i aero tuck.
- `lib/engine/rendering3d/environment_scenery_spawner.dart` — Proceduralne drzewa, skały, budynki i kibice.
- `lib/engine/rendering3d/glb_asset_loader_service.dart` — Ładowanie i cache modeli `.glb`.
- `lib/engine/rendering3d/on_bike_computer_hud_widget.dart` — Licznik na kierownicy w widoku FPP.
- `lib/engine/rendering3d/peloton_instanced_renderer.dart` — Rysowanie 176 kolarzy z LOD i sortowaniem Z.
- `lib/engine/rendering3d/photo_finish_replay_widget.dart` — Kamera fotofiniszu na mecie.
- `lib/engine/rendering3d/rider_floating_labels_overlay.dart` — Pływające etykiety nad kolarzami w 3D.
- `lib/engine/rendering3d/road_furniture_3d_renderer.dart` — Brama km, barierki, znaki i reklamy przy trasie.
- `lib/engine/rendering3d/road_ribbon_mesh_builder.dart` — Budowa wstęgi asfaltu, bruku i zakrętów 3D.
- `lib/engine/rendering3d/scene_3d_math_projection.dart` — Macierze rzutowania 3D->2D i geometria kamery.
- `lib/engine/rendering3d/support_vehicles_3d_renderer.dart` — Samochody techniczne, motocykle kamerzystów i helikopter.
- `lib/engine/rendering3d/weather_particles_renderer.dart` — Cząsteczki deszczu, śniegu i kurzu.
- `lib/engine/rendering3d/wind_streamlines_visualizer.dart` — Linie strug wiatru w trybie taktycznym/tunelu.
- `lib/engine/simulation/isolate_simulation_worker.dart` — Wątek Isolate wykonujący ticki fizyki w tle.
- `lib/engine/simulation/key_moments_detector.dart` — Wykrywanie kluczowych momentów (ataki, kraksy, premie).
- `lib/engine/simulation/post_stage_recovery_processor.dart` — Przeliczanie zmęczenia i formy po etapie.
- `lib/engine/simulation/stage_replay_recorder.dart` — Zapis powtórki etapu i osi czasu.
- `lib/engine/simulation/stage_results_calculator.dart` — Klasyfikacja etapu, GC, górska, punktowa i młodzieżowa.
- `lib/engine/simulation/stage_simulation_loop.dart` — Główna pętla symulacji etapu.
- `lib/engine/simulation/time_trial_simulation_engine.dart` — Silnik jazdy indywidualnej i drużynowej na czas (ITT/TTT).
- `lib/engine/weather/dynamic_mountain_weather_engine.dart` — Pogoda zależna od wysokości n.p.m. i godziny.

### `lib/services/`
- `lib/services/career/achievement_and_milestones_service.dart` — Serwis 45 osiągnięć i kamieni milowych (`AchievementAndMilestonesService`, `AchievementTier`, `AchievementUnlockEvent`, `StageEvaluationContext`, `SeasonEvaluationContext`).
- `lib/services/career/ai_team_transfer_simulation_service.dart` — Symulacja rynku transferowego AI (`AiTeamTransferSimulationService`, `TeamRosterNeedsAnalyzer`, `TransferNewsItem`).
- `lib/services/career/anti_doping_and_whereabouts_service.dart` — Kontrole antydopingowe i paszport biologiczny.
- `lib/services/career/bike_manufacturer_negotiation_service.dart` — Negocjacje kontraktów z producentami rowerów.
- `lib/services/career/development_team_u23_service.dart` — Zarządzanie drużyną młodzieżową U23.
- `lib/services/career/email_inbox_generator_service.dart` — Generator wiadomości w skrzynce menedżera.
- `lib/services/career/equipment_sponsorship_bidding_engine.dart` — Przetargi i oferty sponsorów sprzętowych.
- `lib/services/career/finance_and_budget_service.dart` — Przepływy finansowe, pensje i nagrody wyścigowe.
- `lib/services/career/historical_records_and_palmares_service.dart` — Rekordy historyczne, Hall of Fame i palmares.
- `lib/services/career/national_championships_and_worlds_service.dart` — Mistrzostwa Krajowe i Mistrzostwa Świata UCI.
- `lib/services/career/physiology_lab_testing_service.dart` — Badania wydolnościowe VO2max i krzywej mleczanowej.
- `lib/services/career/press_conference_service.dart` — Wywiady prasowe przed/po etapach i wpływ na morale.
- `lib/services/career/race_calendar_selection_service.dart` — Zgłaszanie składów i dzikie karty na wyścigi.
- `lib/services/career/race_reconnaissance_service.dart` — Rekonesans tras i premia taktyczna.
- `lib/services/career/rider_ego_and_conflicts_service.dart` — Konflikty w zespole, ego liderów i lojalność.
- `lib/services/career/scouting_and_youth_academy_service.dart` — Skauting talentów na świecie i akademia.
- `lib/services/career/season_transition_service.dart` — Przejście między sezonami, emerytury i nowi juniorzy.
- `lib/services/career/sponsor_negotiation_service.dart` — Negocjacje ze sponsorami tytularnymi.
- `lib/services/career/sponsor_objectives_evaluator.dart` — Ewaluacja celów sponsorskich po wyścigu i wypłata bonusów.
- `lib/services/career/team_chemistry_and_builder_service.dart` — Chemia drużyny i hierarchia liderów.
- `lib/services/career/training_and_camps_service.dart` — Zgrupowania wysokogórskie i plany treningowe.
- `lib/services/career/transfer_market_service.dart` — Rynek transferowy kolarzy i wolni agenci.
- `lib/services/career/uci_promotion_relegation_cycle_service.dart` — 3-letni cykl licencyjny WorldTour i walka o utrzymanie.
- `lib/services/career/winter_offseason_training_service.dart` — Przygotowania zimowe i testy przedsezonowe.
- `lib/services/database/custom_mod_importer_service.dart` — Import modów JSON (bazy danych, drużyny, wyścigi).
- `lib/services/database/preset_real_names_template_generator.dart` — Generator szablonu paczek modów (`PresetRealNamesTemplateGenerator`, `CommunityRealismPatchStructure`, `ModSchemaValidator`, `applyLivePatchToActiveCareer`).
- `lib/services/database/save_game_manager.dart` — Zarządzanie slotami zapisów na dysku.
- `lib/services/database/save_service.dart` — Serializacja/deserializacja zapisu gry.
- `lib/services/generators/fictional_brands_catalog.dart` — Katalog fikcyjnych marek rowerowych i sponsorów.
- `lib/services/generators/initial_game_seeder.dart` — Generator nowego świata gry (drużyny, kolarze, kalendarz).
- `lib/services/generators/rider_procedural_generator.dart` — Proceduralny generator kolarzy z profilami fizjologicznymi.
- `lib/services/generators/stage_profile_builder.dart` — Builder profili wysokościowych i segmentów.
- `lib/services/generators/uci_calendar_generator.dart` — Generator pełnego kalendarza UCI na sezon.
- `lib/services/generators/world_teams_generator.dart` — Generator drużyn WorldTour, ProTeam i Continental.

### `lib/state/`
- `lib/state/career_controller.dart` — Kontroler akcji kariery i logiki postępu dni.
- `lib/state/career_state_notifier.dart` — Główny stan kariery (`CareerState`, `CareerStateNotifier`, `SimulationStopReason`, `ActiveTrainingCampAssignment`, `ScheduledRecoverySession`, `advanceDay`, `advanceToNextEvent`, `simulateUntilNextStop`).
- `lib/state/game_settings_notifier.dart` — Stan i zapis ustawień aplikacji.
- `lib/state/race_simulation_controller.dart` — Kontroler sterowania wyścigiem (pauza, tempo, rozkazy).
- `lib/state/race_simulation_notifier.dart` — Stan symulacji wyścigu na żywo i snapshoty kolarzy.

### `lib/ui/screens/`
- `lib/ui/screens/bike_garage_rnd_screen.dart` — Garaż rowerowy, R&D i konfiguracja sprzętu.
- `lib/ui/screens/calendar_and_race_planner_screen.dart` — Kalendarz sezonu i planowanie szczytów formy.
- `lib/ui/screens/career_dashboard_screen.dart` — Widok pulpitu kariery.
- `lib/ui/screens/dashboard_hq_screen.dart` — Centrum dowodzenia (HQ), wiadomości i skróty.
- `lib/ui/screens/development_academy_screen.dart` — Ekran drużyny rozwojowej U23 i skautingu.
- `lib/ui/screens/game_start_screen.dart` — Ekran powitalny i ładowanie zapisów.
- `lib/ui/screens/grand_tour_rest_day_screen.dart` — Dzień przerwy w Wielkim Tourze (Coffee Ride, prasa, fizjo).
- `lib/ui/screens/hall_of_fame_and_records_screen.dart` — Galeria sław i historyczne rekordy.
- `lib/ui/screens/jersey_and_bike_livery_studio_screen.dart` — Studio projektowania koszulek i malowania ram.
- `lib/ui/screens/main_shell_screen.dart` — Główna nawigacja powłoki kariery (`MainShellScreen`, `MainNavigationSection`, `MainNavigationTab` 4 sekcje / 20 ekranów, TopBar, `CareerInboxView`, `UciRankingsAndLicenseView`, `ManagerProfileAndAchievementsView`).
- `lib/ui/screens/main_title_menu_screen.dart` — Ekran tytułowy AAA (`MainTitleMenuScreen`, `AnimatedPelotonBackdropPainter`) z animowanym tłem alpejskim 60/120 FPS i szklanym panelem nawigacyjnym.
- `lib/ui/screens/manager_profile_and_achievements_screen.dart` — Profil Menedżera (`ManagerProfileAndAchievementsScreen`): holograficzna licencja UCI VIP, wykresy zwycięstw wg terenu (`fl_chart`) i siatka 45 osiągnięć z filtrami rangi i paskami postępu.
- `lib/ui/screens/medical_and_recovery_center_screen.dart` — Centrum medyczne, kontuzje i paszport biologiczny.
- `lib/ui/screens/new_career_setup_screen.dart` — Kreator nowej kariery i wybór drużyny.
- `lib/ui/screens/physiology_lab_screen.dart` — Laboratorium wydolnościowe (mleczan, VO2max, krzywa mocy).
- `lib/ui/screens/post_stage_podium_screen.dart` — Ceremonia podium i klasyfikacje po etapie.
- `lib/ui/screens/pre_race_briefing_screen.dart` — Odprawa przedstartowa i wybór składu.
- `lib/ui/screens/quick_race_sandbox_screen.dart` — Szybki Wyścig / Laboratorium Taktyczne Sandbox 3D (`QuickRaceSandboxScreen`).
- `lib/ui/screens/race_3d_viewport_widget.dart` — Główny viewport 3D wyścigu.
- `lib/ui/screens/race_hud_overlay.dart` — Warstwa HUD 3D w stylu ASO Broadcast / Zwift (`RaceHudOverlay`, 8 kart kolarzy, Flamme Rouge, `GroupGapsChalkboardWidget`, `OnBikeComputerHudWidget`, `TacticalMinimap2dWidget`, `RiderEffortSliderControl`, `TeamTacticalPresetsBar`, Aero Vision Mode).
- `lib/ui/screens/race_simulation_screen.dart` — Ekran wyścigu łączący 3D viewport, HUD i kontrolki.
- `lib/ui/screens/rider_detail_screen.dart` — Szczegółowy profil kolarza i statystyki.
- `lib/ui/screens/settings_and_mod_screen.dart` — Ustawienia gry i import modów.
- `lib/ui/screens/sponsors_and_finance_screen.dart` — Zarządzanie sponsorami i budżetem.
- `lib/ui/screens/squad_roster_screen.dart` — Lista składu drużyny z filtrami i statystykami.
- `lib/ui/screens/staff_management_screen.dart` — Zatrudnianie i zarządzanie personelem.
- `lib/ui/screens/stage_editor_creator_screen.dart` — Kreator własnych etapów i profili.
- `lib/ui/screens/strava_style_stage_analysis_screen.dart` — Analiza telemetryczna po etapie w stylu Strava.
- `lib/ui/screens/team_builder_hierarchy_screen.dart` — Hierarchia liderów i pociągi sprinterskie.
- `lib/ui/screens/training_and_camps_screen.dart` — Obozy treningowe i plany obciążeń.
- `lib/ui/screens/transfer_market_scouting_screen.dart` — Rynek transferowy i negocjacje.
- `lib/ui/screens/wind_tunnel_and_bike_fit_screen.dart` — Tunel aerodynamiczny i bike fitting.

### `lib/ui/widgets/`
- `lib/ui/widgets/achievement_unlock_toast_overlay.dart` — Animowany baner odblokowania osiągnięcia (`AchievementUnlockToastOverlay`, `AchievementTrophyToastBanner`) ze złotym blaskiem `#D4AF37`.
- `lib/ui/widgets/animated_watt_bomb_effect.dart` — Efekt pulsującego impulsu ataku powyżej 12 W/kg / 1400W.
- `lib/ui/widgets/bike_preview_painter.dart` — Wektorowy podgląd roweru drużynowego.
- `lib/ui/widgets/custom_jersey_painter.dart` — Rysowanie wzoru koszulki i spodenek (`CustomPainter`).
- `lib/ui/widgets/custom_ jersey_painter.dart` — Duplikat historyczny (nie modyfikować bez potrzeby).
- `lib/ui/widgets/elevation_profile_chart.dart` — Interaktywny profil wysokościowy etapu.
- `lib/ui/widgets/group_gaps_chalkboard_widget.dart` — Tablica różnic czasowych między grupami.
- `lib/ui/widgets/keyboard_shortcuts_manager.dart` — System skrótów klawiszowych (`KeyboardShortcutsManager`, `ShortcutsCheatSheetOverlay`, `ShortcutKeycap`) dla 3D i Menedżera.
- `lib/ui/widgets/key_moment_overlay.dart` — Powiadomienie i najazd na kluczowy moment wyścigu.
- `lib/ui/widgets/live_virtual_standings_drawer.dart` — Wysuwana tabela wirtualnej klasyfikacji GC na żywo.
- `lib/ui/widgets/mechanic_workshop_panel.dart` — Panel warsztatu mechaników (ciśnienie opon, wosk, koła).
- `lib/ui/widgets/peloton_heatmap_position_widget.dart` — Taktyczna siatka ciepła pozycji w peletonie z lotu ptaka.
- `lib/ui/widgets/power_curve_chart_widget.dart` — Wykres krzywej mocy W / W/kg.
- `lib/ui/widgets/press_interview_modal.dart` — Modal wywiadu z dziennikarzami.
- `lib/ui/widgets/race_radio_banner.dart` — Pasek komunikatów radia wyścigowego.
- `lib/ui/widgets/race_top_hud_bar.dart` — Górny pasek HUD (km, prędkość, wiatr, pogoda).
- `lib/ui/widgets/rainbow_and_national_jersey_badge.dart` — Oznaczenia Tęczowej Koszulki i Mistrzów Krajowych.
- `lib/ui/widgets/rider_avatar_painter.dart` — Proceduralny portret kolarza w kasku i okularach.
- `lib/ui/widgets/rider_comparison_side_by_side_modal.dart` — Modal porównania 2–3 kolarzy obok siebie (`RiderComparisonSideBySideModal`).
- `lib/ui/widgets/rider_effort_slider_control.dart` — Suwak wysiłku i rozkazów taktycznych kolarza.
- `lib/ui/widgets/rider_telemetry_hud.dart` — Karta telemetrii kolarza na żywo (W, BPM, W', glikogen).
- `lib/ui/widgets/tactical_minimap_2d_widget.dart` — Minimapa 2D trasy i pozycji grup.
- `lib/ui/widgets/team_tactical_presets_bar.dart` — Szybkie presety taktyczne dla całej drużyny.
- `lib/ui/widgets/tutorial_coach_marks_overlay.dart` — Interaktywny samouczek wyścigowy (`TutorialCoachMarksOverlay`, `TutorialAcademyStep`, `TutorialTargetZone`) w estetyce ciemnego szkła ze strzałkami wektorowymi.

### `blender_scripts/` & `test/`
- `blender_scripts/build_all_assets_master.py` + `generate_*.py`, `rig_and_animate_cyclist.py`, `style_and_materials.py` oraz odpowiadające `test_*.py` — Generator assetów 3D `.glb` w Blenderze.
- `blender_scripts/generate_cobble_monument_props.py` — Generator 3D welodromu (`velodrome_finish_arena.glb`) i rekwizytów sektora bruku (`cobble_sector_props.glb`) w Blender 5.3.
- `test/new_career_setup_test.dart`, `test/tactical_minimap_2d_widget_test.dart`, `test/ui/race_hud_overlay_test.dart` oraz testy jednostkowe w `test/{core,engine,models,services,ui}/`.
