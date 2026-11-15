# PRO PELOTON MANAGER — MASTER QUEUE & SNIPER MODE WORKFLOW

Ten dokument stanowi centralną kolejkę zadań dla autonomicznego agenta w Antigravity IDE.

* **Zadania #001 – #162:** Ukończone (`[x]`).

* **Zadania #163 – #212:** Aktywna paczka 50 ultra-szczegółowych zadań produkcyjnych (`[ ]`) zaprojektowanych pod model **Hydrogen** (1 zadanie = 1 świeży kontekst = weryfikacja `flutter analyze` = `git commit`).

## INSTRUKCJA URUCHOMIENIA AUTOMATYCZNEJ PĘTLI

### KROK A: Zapisz ten plik jako `docs/QUEUE.md` w swoim projekcie (lub wklej poniższy prompt do modelu ARGON 4):

```
Chcę zautomatyzować dalszą budowę tej gry w sposób maksymalnie oszczędzający tokeny i odporny na przerwanie po wyczerpaniu limitu tygodniowego. Dotychczas wykonaliśmy 162 prompty (modele, fizyka, część silnika 3D, serwisów i UI są już w projekcie).

Wykonaj teraz automatycznie 4 kroki konfiguracyjne (bez psucia obecnego kodu gry):

1. STWÓRZ MAPĘ PROJEKTU (`docs/CODE_MAP.md`):
Przeskanuj obecne pliki gry (to, co powstało w pierwszych 162 promptach) i stwórz zwięzły, techniczny plik `docs/CODE_MAP.md`. Zapisz w nim:
- dokładne drzewo plików projektu i za co odpowiada każdy plik,
- używaną architekturę (Riverpod, GoRouter, Isolate), główne klasy, stany, metody publiczne i interfejsy,
- ustaloną paletę kolorów (#0F1115, #181B22, #222630, #8E4A49, #D4AF37), zmienne stylów, czcionki i zasady animacji UI.
Ten plik ma służyć kolejnym agentom jako natychmiastowa ściąga, żeby nie tracili tokenów na przeszukiwanie dysku.

2. UTWÓRZ REGUŁY TRYBU SNAJPERA (`.agents/rules/sniper_mode.md`):
Utwórz plik `.agents/rules/sniper_mode.md` i zapisz w nim bezwzględne zasady dla modelu Hydrogen:
- EKONOMIA TOKENÓW: Zawsze zaczynaj od przeczytania `docs/CODE_MAP.md`. Nie skanuj całego repozytorium, jeśli ścieżki są w mapie. Odpowiedzi na czacie ogranicz do maksimum 2 krótkich zdań — cała moc ma iść w kod.
- JAKOŚĆ AAA I ZERO PROWIZORKI: Całkowity zakaz używania `// TODO`, `placeholder`, pustych metod czy uproszczonych stylów. Każdy element UI i kodu ma być skończony w 100% produkcyjnie (pełne stany hover/active/disabled/focus, płynne mikro-animacje, glassmorphism, obsługa błędów i brzegowych przypadków, brak RenderFlex overflow, czyste typowanie).
- WERYFIKACJA WIZUALNA I KODU: Każdy nowy widget/ekran musi używać `LayoutBuilder` lub `CustomPainter` z bezpiecznymi ograniczeniami (constraints), tak aby na ekranach mobilnych (390x844), tabletach (1024x768) i desktopie Windows (1600x900) nie występował żaden błąd wyjścia poza ekran.
- TRANSAKCYJNOŚĆ (ODPORNOŚĆ NA LIMIT): Po zrobieniu każdego pojedynczego zadania z `docs/QUEUE.md`: (a) uruchom weryfikację `flutter analyze` w terminalu i napraw błędy do zera, (b) dopisz nowe pliki/klasy w 1 linijce do `docs/CODE_MAP.md`, (c) zmień w `docs/QUEUE.md` status tego zadania z `- [ ]` na `- [x]`, (d) wykonaj `git add -A && git commit -m "Queue: ukończono zadanie [numer]"`.

3. ZWERYFIKUJ AKTYWNĄ KOLEJKĘ (`docs/QUEUE.md`):
Upewnij się, że plik `docs/QUEUE.md` zawiera zadania #001-#162 jako `- [x]` oraz nowe zadania #163-#212 jako `- [ ]` z zachowaniem wszystkich detali technicznych i wizualnych.

4. ZABEZPIECZ BAZĘ W GIT:
Upewnij się, że repozytorium Git działa poprawnie i zrób commit całej konfiguracji: `git add -A && git commit -m "Setup: system kolejkowy Sniper Mode i mapa kodu (stan na #162)"`.

```

### KROK B: Gdy Argon 4 skończy konfigurację, wklej ten prompt uruchamiający pętlę:

```
/run-workflow Napisz i uruchom sekwencyjny skrypt workflow (max_concurrency=1, model: hydrogen), który automatycznie realizuje zadania z pliku `docs/QUEUE.md`.

Zasady działania pętli:
1. Na starcie sprawdź `git status` — jeśli poprzednia sesja została przerwana w połowie zadania przez wyczerpanie limitu tokenów, dokończ to zadanie lub wyczyść niedokończone zmiany (`git checkout -- .`), aby startować z czystego stanu.
2. W pętli znajdź pierwsze nieukończone zadanie oznaczone jako `- [ ]` w `docs/QUEUE.md`.
3. Dla tego JEDNEGO zadania uruchom osobnego agenta Hydrogen ze świeżym kontekstem.
4. Agent ma przeczytać wyłącznie `docs/CODE_MAP.md` oraz treść tego jednego zadania, zaimplementować je w 100% produkcyjnie zgodnie z `.agents/rules/sniper_mode.md`, sprawdzić kompilację (`flutter analyze`), zaktualizować `docs/CODE_MAP.md`, zmienić `[ ]` na `[x]` w `docs/QUEUE.md` i zrobić `git commit`.
5. Po commicie zamknij kontekst agenta i przejdź do następnego zadania `- [ ]`, aż skończy się lista lub wyczerpie się mój limit.

```

## CZĘŚĆ I: UKOŃCZONE ZADANIA (#001 – #162)

- [x] **Zadanie #001** (`lib/core/theme/app_colors.dart`): Klasa `AppColors` ze statycznymi kolorami Dark Mode (#0F1115, #181B22, #222630, #8E4A49, #D4AF37) i strefami mocy Z1–Z7.

- [x] **Zadanie #002** (`lib/core/theme/app_theme.dart`): Klasa `AppTheme` konfigurująca `ThemeData`, bezramkowe karty 16px, obramowania #2A2F3D i typografię sportową.

- [x] **Zadanie #003** (`lib/core/constants/physics_constants.dart`): Stałe fizyczne ($g = 9.80665$, gęstość powietrza, straty napędu wosk/olej, bazowe wartości $CdA$).

- [x] **Zadanie #004** (`lib/models/rider/rider_physiology.dart`): Model `RiderPhysiology` (wzrost, waga, FTP, $W'$, $VO_2max$, HR, glikogen, powierzchnia czołowa DuBois).

- [x] **Zadanie #005** (`lib/models/rider/rider_power_profile.dart`): Model `RiderPowerProfile` (krzywa mocy 5s–60m z interpolacją logarytmiczną).

- [x] **Zadanie #006** (`lib/models/rider/rider_skills.dart`): Model `RiderSkills` (bruk, zjazdy, bikeHandling, aeroPositioning, draftingEfficiency, raceIq, pogoda).

- [x] **Zadanie #007** (`lib/models/rider/rider_appearance.dart`): Model `RiderAppearance` (kształt twarzy, skóra, włosy, okulary, kask, sylwetka 3D).

- [x] **Zadanie #008** (`lib/models/rider/rider_contract.dart`): Model `RiderContract` (rola, pensja, bonusy, klauzula wykupu, morale, lojalność, wymagane wyścigi).

- [x] **Zadanie #009** (`lib/models/rider/rider_health.dart`): Model `RiderHealth` (ATL, CTL, TSB/forma, kontuzje `Injury`, choroby).

- [x] **Zadanie #010** (`lib/models/rider/rider.dart`): Główny model `Rider` łączący wszystkie podmodele oraz wyliczający ocenę OVR pod specjalizację.

- [x] **Zadanie #011** (`lib/models/equipment/frame_model.dart`): Model `FrameModel` (Aero, Górska, TT, Bruk, waga, modyfikator $CdA$, sztywność, komfort).

- [x] **Zadanie #012** (`lib/models/equipment/wheelset_model.dart`): Model `WheelsetModel` (wysokość stożka 35–80mm/Disc, waga, $CdA$, bezwładność, kara na wietrze bocznym).

- [x] **Zadanie #013** (`lib/models/equipment/groupset_and_tires.dart`): Modele `GroupsetModel` (napęd, wosk/smar, przełożenia) oraz `TireModel` (szerokość, Tubeless/TPU, $Crr$, przebicia).

- [x] **Zadanie #014** (`lib/models/equipment/complete_bike.dart`): Model `CompleteBike` łączący komponenty i weryfikujący limit UCI $6.8\text{ kg}$.

- [x] **Zadanie #015** (`lib/models/team/bike_manufacturer_deal.dart`): Model `BikeManufacturerDeal` (umowa ze sponsorem sprzętowym, budżet, poziom R&D).

- [x] **Zadanie #016** (`lib/models/team/sponsor_contract.dart`): Model `SponsorContract` (sponsorzy tytularni, budżet roczny, cele sponsorskie `SponsorObjective`).

- [x] **Zadanie #017** (`lib/models/team/cycling_team.dart`): Model `CyclingTeam` (dywizja, kolory, budżet, kolarze, sztab, garaż rowerowy).

- [x] **Zadanie #018** (`lib/models/race/stage_segment.dart`): Model `StageSegment` (długość, wzniesienie, gradient %, nawierzchnia, trudność techniczna, premie KOM/Sprint).

- [x] **Zadanie #019** (`lib/models/race/race_stage.dart`): Model `RaceStage` (typ etapu, lista segmentów, pogoda, temperatura, wiatr).

- [x] **Zadanie #020** (`lib/models/race/tour_race.dart`): Model `TourRace` (kategoria UCI, etapy, pula nagród, klasyfikacje GC, Points, KOM, U23, Team).

- [x] **Zadanie #021** (`lib/engine/physics/aero_calculator.dart`): Kalkulator oporu aerodynamicznego $P_{aero}$ z gęstością powietrza n.p.m., wiatrem i draftingiem.

- [x] **Zadanie #022** (`lib/engine/physics/gravity_and_rolling_calculator.dart`): Kalkulator oporu grawitacji $P_{gravity}$, toczenia $P_{rolling}$ i strat napędu.

- [x] **Zadanie #023** (`lib/engine/physics/speed_solver.dart`): Solver równania ruchu kolarza wyliczający przyspieszenie i prędkość w każdej sekundzie.

- [x] **Zadanie #024** (`lib/engine/physics/w_prime_balance_engine.dart`): Naukowy model Skiba $W'$ Balance (zużycie powyżej CP i wykładnicza regeneracja poniżej CP).

- [x] **Zadanie #025** (`lib/engine/physics/nutrition_and_glycogen_engine.dart`): Silnik spalania glikogenu, nawodnienia, spożywania żeli/bidonów i odcięcia ("bonk").

- [x] **Zadanie #026** (`lib/engine/physics/heart_rate_simulator.dart`): Symulator tętna z inercją fizjologiczną i dryfem tętna (cardiac drift).

- [x] **Zadanie #027** (`lib/engine/peloton/drafting_grid_system.dart`): System siatki peletonu wyliczający % oszczędności energii w cieniu aerodynamicznym.

- [x] **Zadanie #028** (`lib/engine/peloton/echelon_crosswind_engine.dart`): Mechanika formowania wachlarzy (rantów) i rwanych grup na silnym wietrze bocznym.

- [x] **Zadanie #029** (`lib/engine/peloton/rider_race_state.dart`): Stan pojedynczego kolarza podczas wyścigu (`RiderRaceState`).

- [x] **Zadanie #030** (`lib/engine/peloton/tactical_orders_processor.dart`): Procesor przekładający rozkazy taktyczne na docelowe waty i pozycję w grupie.

- [x] **Zadanie #031** (`lib/engine/peloton/breakaway_ai_controller.dart`): Kontroler AI odpowiedzialny za zawiązywanie ucieczki dnia i współpracę na zmianach.

- [x] **Zadanie #032** (`lib/engine/peloton/peloton_chase_ai_controller.dart`): Kontroler AI dla drużyn kontrolujących tempo pogoni w peletonie.

- [x] **Zadanie #033** (`lib/engine/peloton/mountain_gc_ai_controller.dart`): Kontroler AI dla pociągów górskich i ataków faworytów klasyfikacji generalnej.

- [x] **Zadanie #034** (`lib/engine/peloton/sprint_train_ai_controller.dart`): Kontroler AI dla pociągów sprinterskich (Lead-out Train) na ostatnich 3 kilometrach.

- [x] **Zadanie #035** (`lib/engine/events/race_incident_engine.dart`): Generator kraks, przebitych opon i defektów mechanicznych podczas etapu.

- [x] **Zadanie #036** (`lib/engine/events/race_radio_generator.dart`): Generator komunikatów Radia Wyścigowego od dyrektora sportowego.

- [x] **Zadanie #037** (`lib/engine/simulation/key_moments_detector.dart`): Detektor kluczowych momentów etapu przełączający szybki symulator w tryb 3D.

- [x] **Zadanie #038** (`lib/engine/simulation/stage_simulation_loop.dart`): Główna pętla symulacji etapu obsługująca prędkości 1x–8x i skoki do kluczowych momentów.

- [x] **Zadanie #039** (`lib/engine/simulation/stage_results_calculator.dart`): Kalkulator wyników etapu, bonifikat, reguły 3 km, punktów KOM/Sprint i limitu czasu (OTL).

- [x] **Zadanie #040** (`lib/engine/simulation/post_stage_recovery_processor.dart`): Procesor zmęczenia i regeneracji nocnej między etapami Touru.

- [x] **Zadanie #041** (`lib/services/generators/fictional_brands_catalog.dart`): Katalog 15 marek rowerowych i osprzętowych z modelami ram, kół, napędów i opon.

- [x] **Zadanie #042** (`lib/services/generators/rider_procedural_generator.dart`): Proceduralny generator kolarzy z 25 krajów z realistyczną korelacją wagi do mocy.

- [x] **Zadanie #043** (`lib/services/generators/world_teams_generator.dart`): Generator 53 drużyn (WorldTour, ProTeam, Continental) i ponad 800 zawodników.

- [x] **Zadanie #044** (`lib/services/generators/uci_calendar_generator.dart`): Generator pełnego kalendarza wyścigów od stycznia do października.

- [x] **Zadanie #045** (`lib/services/generators/stage_profile_builder.dart`): Konstruktor dokładnych profili tras i słynnych podjazdów alpejskich/brukowanych.

- [x] **Zadanie #046** (`lib/services/career/transfer_market_service.dart`): Serwis rynku transferowego, klauzul wykupu i negocjacji z agentami.

- [x] **Zadanie #047** (`lib/services/career/team_chemistry_and_builder_service.dart`): Serwis budowania zespołu wokół liderów i wyliczania synergii pociągów.

- [x] **Zadanie #048** (`lib/services/career/sponsor_negotiation_service.dart`): Serwis pozyskiwania sponsorów tytularnych i negocjowania budżetu.

- [x] **Zadanie #049** (`lib/services/career/bike_manufacturer_negotiation_service.dart`): Serwis umów z producentami rowerów i rozwoju R&D.

- [x] **Zadanie #050** (`lib/services/career/training_and_camps_service.dart`): Serwis planów treningowych i obozów wysokogórskich.

- [x] **Zadanie #051** (`lib/services/career/race_calendar_selection_service.dart`): Serwis zgłaszania składów na wyścigi i wniosków o Dzikie Karty (Wildcards).

- [x] **Zadanie #052** (`lib/services/career/finance_and_budget_service.dart`): Serwis finansowy śledzący przychody, pensje, koszty logistyki i nagrody.

- [x] **Zadanie #053** (`lib/services/career/scouting_and_youth_academy_service.dart`): Serwis skautingu młodych talentów U19/U23 i odkrywania ich potencjału.

- [x] **Zadanie #054** (`lib/services/database/custom_mod_importer_service.dart`): Importer baz społeczności (Real Name Packs w formacie JSON).

- [x] **Zadanie #055** (`lib/services/database/save_game_manager.dart`): Menedżer zapisu i wczytywania stanu kariery (5 slotów + Auto-Save).

- [x] **Zadanie #056** (`lib/state/career_state_notifier.dart`): Główny kontroler stanu kariery Riverpod (`CareerStateNotifier`) z metodą `advanceDay()`.

- [x] **Zadanie #057** (`lib/state/race_simulation_notifier.dart`): Kontroler stanu wyścigu na żywo (`RaceSimulationNotifier`).

- [x] **Zadanie #058** (`lib/ui/widgets/rider_avatar_painter.dart`): Wektorowy `CustomPainter` generujący portret kolarza z okularami, kaskiem i koszulką.

- [x] **Zadanie #059** (`lib/ui/widgets/bike_preview_painter.dart`): Wektorowy `CustomPainter` rysujący skonfigurowany rower szosowy/TT i profil kół.

- [x] **Zadanie #060** (`lib/ui/widgets/elevation_profile_chart.dart`): Interaktywny wykres profilu wysokościowego trasy ze znacznikami kolarzy na żywo.

- [x] **Zadanie #061** (`lib/ui/widgets/power_curve_chart_widget.dart`): Wykres krzywej mocy (5s–60m) z nakładaniem statystyk dwóch kolarzy.

- [x] **Zadanie #062** (`lib/ui/screens/main_shell_screen.dart`): Responsywny szkielet nawigacyjny aplikacji (Mobile, Tablet, Desktop).

- [x] **Zadanie #063** (`lib/ui/screens/dashboard_hq_screen.dart`): Ekran główny biura menedżera w układzie Bento Grid.

- [x] **Zadanie #064** (`lib/ui/screens/squad_roster_screen.dart`): Ekran kadry zespołu z tabelą fizjologii, formy i kontraktów.

- [x] **Zadanie #065** (`lib/ui/screens/rider_detail_screen.dart`): Szczegółowy profil pojedynczego kolarza z 4 zakładkami analitycznymi.

- [x] **Zadanie #066** (`lib/ui/screens/team_builder_hierarchy_screen.dart`): Ekran budowania hierarchii drużyny i pociągów wokół liderów.

- [x] **Zadanie #067** (`lib/ui/screens/bike_garage_rnd_screen.dart`): Ekran garażu, konfiguratora sprzętu co do grama i badań R&D.

- [x] **Zadanie #068** (`lib/ui/screens/sponsors_and_finance_screen.dart`): Ekran zarządzania sponsorami, celami zarządu i budżetem.

- [x] **Zadanie #069** (`lib/ui/screens/transfer_market_scouting_screen.dart`): Ekran rynku transferowego, negocjacji i skautingu.

- [x] **Zadanie #070** (`lib/ui/screens/calendar_and_race_planner_screen.dart`): Ekran kalendarza UCI i wyboru składów na poszczególne Toury.

- [x] **Zadanie #071** (`lib/ui/screens/training_and_camps_screen.dart`): Ekran wykresów PMC (CTL/ATL/TSB) i planowania obozów wysokogórskich.

- [x] **Zadanie #072** (`lib/ui/screens/pre_race_briefing_screen.dart`): Ekran odprawy taktycznej i doboru sprzętu bezpośrednio przed etapem.

- [x] **Zadanie #073** (`lib/ui/screens/race_3d_viewport_widget.dart`): Główny widok renderowania wyścigu 3D.

- [x] **Zadanie #074** (`lib/ui/screens/race_hud_overlay.dart`): Nakładka taktyczna HUD podczas wyścigu (karty kolarzy, tętno, waty, $W'$, rozkazy).

- [x] **Zadanie #075** (`lib/ui/screens/post_stage_podium_screen.dart`): Ekran wyników etapu i wszystkich klasyfikacji wyścigu (GC, KOM, Points, U23).

- [x] **Zadanie #076** (`lib/ui/screens/settings_and_mod_screen.dart`): Ekran ustawień graficznych 3D i importu baz danych społeczności.

- [x] **Zadanie #077** (`lib/ui/screens/new_career_setup_screen.dart`): Kreator nowej kariery i tworzenia własnego zespołu od zera.

- [x] **Zadanie #078** (`lib/ui/widgets/tactical_minimap_2d_widget.dart`): Minimapa taktyczna 2D pokazująca najbliższe zakręty i układ grupy.

- [x] **Zadanie #079** (`lib/core/utils/formatters.dart`): Formatery czasów wyścigowych, różnic sekundowych, watów, W/kg i walut.

- [x] **Zadanie #080** (`lib/services/generators/initial_game_seeder.dart`): Seeder inicjalizujący kompletny świat gry przy starcie nowej kariery.

- [x] **Zadanie #081** (`lib/ui/widgets/custom_jersey_painter.dart`): `CustomPainter` rysujący koszulki zespołów w 8 wzorach.

- [x] **Zadanie #082** (`lib/engine/simulation/time_trial_simulation_engine.dart`): Silnik rozgrywania etapów jazdy indywidualnej (ITT) oraz drużynowej na czas (TTT).

- [x] **Zadanie #083** (`lib/services/career/season_transition_service.dart`): Serwis podsumowania roku, awansów/spadków, emerytur i przejścia do nowego sezonu.

- [x] **Zadanie #084** (`lib/core/router/app_router.dart`): Konfiguracja nawigacji `GoRouter` dla wszystkich ekranów aplikacji.

- [x] **Zadanie #085** (`lib/main.dart`): Punkt wejścia aplikacji spinający `ProviderScope`, motyw i router.

- [x] **Zadanie #086** (`blender_scripts/style_and_materials.py`): Skrypt Blender Python API definiujący materiały PBR (karbon, lakier, guma, lycra).

- [x] **Zadanie #087** (`blender_scripts/generate_aero_frame.py`): Skrypt Blender Python API generujący model 3D ramy aerodynamicznej.

- [x] **Zadanie #088** (`blender_scripts/generate_climbing_frame.py`): Skrypt Blender Python API generujący model 3D lekkiej ramy górskiej.

- [x] **Zadanie #089** (`blender_scripts/generate_tt_frame.py`): Skrypt Blender Python API generujący model 3D ramy czasowej TT z lemondką.

- [x] **Zadanie #090** (`blender_scripts/generate_wheelsets.py`): Skrypt Blender Python API generujący koła 35mm, 50mm, 65mm i pełny dysk.

- [x] **Zadanie #091** (`blender_scripts/generate_cockpit_and_drivetrain.py`): Skrypt Blender Python API generujący kokpit aero, korbę, napęd i bidony.

- [x] **Zadanie #092** (`blender_scripts/generate_cyclist_mesh.py`): Skrypt Blender Python API generujący siatkę 3D kolarza z 3 sylwetkami (Shape Keys).

- [x] **Zadanie #093** (`blender_scripts/generate_helmets_and_glasses.py`): Skrypt Blender Python API generujący kaski (szosowy, aero, TT) i okulary.

- [x] **Zadanie #094** (`blender_scripts/rig_and_animate_cyclist.py`): Skrypt Blender Python API tworzący szkielet i 6 animacji pedałowania/sprintu.

- [x] **Zadanie #095** (`blender_scripts/generate_road_tiles.py`): Skrypt Blender Python API generujący segmenty asfaltu, bruku i serpentyn.

- [x] **Zadanie #096** (`blender_scripts/generate_race_furniture.py`): Skrypt Blender Python API generujący barierki, bramę 1 km (Flamme Rouge) i metę.

- [x] **Zadanie #097** (`blender_scripts/generate_support_vehicles.py`): Skrypt Blender Python API generujący wóz techniczny drużyny i motocykle TV.

- [x] **Zadanie #098** (`blender_scripts/generate_environment_assets.py`): Skrypt Blender Python API generujący drzewa, skały, budynki i kibiców.

- [x] **Zadanie #099** (`blender_scripts/build_all_assets_master.py`): Główny skrypt wykonawczy kompilujący wszystkie modele 3D do `.glb`.

- [x] **Zadanie #100** (`README_NIGHT_BUILD.md`): Dokumentacja uruchomienia skryptów Blendera i audytu pierwszych 100 kroków.

- [x] **Zadanie #101** (`lib/engine/rendering3d/scene_3d_math_projection.dart`): Rzutowanie perspektywiczne 3D oparte na macierzach `vector_math_64`.

- [x] **Zadanie #102** (`lib/engine/rendering3d/camera_rig_controller.dart`): Kontroler kamer 3D (ChaseCam, MotoTvCam, HeliCam, FinishLineCam).

- [x] **Zadanie #103** (`lib/engine/rendering3d/road_ribbon_mesh_builder.dart`): Generator wstęgi drogi 3D z krzywymi zakrętów i cieniowaniem nawierzchni.

- [x] **Zadanie #104** (`lib/engine/rendering3d/cyclist_3d_pose_animator.dart`): Animator kolarza w 60/120 FPS (kąt korby z RPM, pochylenie w zakręcie, kołysanie roweru).

- [x] **Zadanie #105** (`lib/engine/rendering3d/glb_asset_loader_service.dart`): Loader i pamięć podręczna plików `.glb` z proceduralnym fallbackiem siatek.

- [x] **Zadanie #106** (`lib/engine/rendering3d/peloton_instanced_renderer.dart`): Renderer instancjonowany dla 176 kolarzy z 3 poziomami detali (LOD).

- [x] **Zadanie #107** (`lib/engine/rendering3d/environment_scenery_spawner.dart`): Proceduralny generator krajobrazu zależny od wysokości n.p.m.

- [x] **Zadanie #108** (`lib/engine/rendering3d/weather_particles_renderer.dart`): System cząsteczek deszczu, pióropuszy wody spod kół, mgły i kurzu na bruku.

- [x] **Zadanie #109** (`lib/engine/rendering3d/on_bike_computer_hud_widget.dart`): Widget komputera rowerowego (styl Garmin/Wahoo) z ClimbPro i przełożeniami.

- [x] **Zadanie #110** (`lib/engine/rendering3d/rider_floating_labels_overlay.dart`): Znaczniki 3D nad kolarzami w peletonie (nazwisko, W/kg, ikona ataku/ochrony).

- [x] **Zadanie #111** (`lib/engine/rendering3d/road_furniture_3d_renderer.dart`): Renderer bramy mety, Flamme Rouge, tablic kilometrowych i barierek.

- [x] **Zadanie #112** (`lib/engine/rendering3d/support_vehicles_3d_renderer.dart`): Renderer kolumny wozów technicznych i motocykli TV w wyścigu 3D.

- [x] **Zadanie #113** (`lib/engine/rendering3d/crash_and_mechanical_visuals.dart`): Wizualizacja kraks, podnoszenia ręki przy defekcie i wymiany koła.

- [x] **Zadanie #114** (`lib/engine/rendering3d/wind_streamlines_visualizer.dart`): Wizualizator strug powietrza i kieszeni aerodynamicznych (Aero Vision Mode).

- [x] **Zadanie #115** (`lib/engine/rendering3d/photo_finish_replay_widget.dart`): Kamera szczelinowa Photo Finish rozstrzygająca finisze poniżej $0.15\text{ s}$.

- [x] **Zadanie #116** (`lib/ui/screens/race_3d_viewport_widget.dart`): Integracja modułów `rendering3d` i obsługa gestów obracania/zoomowania kamery.

- [x] **Zadanie #117** (`lib/engine/audio/procedural_cycling_audio_engine.dart`): Proceduralny syntezator szumu stożków karbonowych, terkotu bębenka i wrzawy kibiców.

- [x] **Zadanie #118** (`lib/engine/audio/race_radio_tts_and_beeps.dart`): Sygnały dźwiękowe krótkofalówki radia wyścigowego i alarmy komputera rowerowego.

- [x] **Zadanie #119** (`lib/ui/widgets/group_gaps_chalkboard_widget.dart`): Tablica motocyklisty (Ardoisier) pokazująca różnice czasowe między grupami.

- [x] **Zadanie #120** (`lib/ui/widgets/rider_effort_slider_control.dart`): Suwak intensywności wysiłku (50–120% FTP) i pozycji aerodynamicznej.

- [x] **Zadanie #121** (`lib/ui/widgets/team_tactical_presets_bar.dart`): Pasek szybkich rozkazów dla całej drużyny (Pociąg Górski, Pociąg Sprinterski, Wachlarz).

- [x] **Zadanie #122** (`lib/ui/widgets/live_virtual_standings_drawer.dart`): Szuflada Wirtualnej Klasyfikacji Generalnej (Virtual GC) przeliczanej na żywo na trasie.

- [x] **Zadanie #123** (`lib/engine/simulation/isolate_simulation_worker.dart`): Wielowątkowy worker `Isolate` liczący fizykę 176 kolarzy poza wątkiem UI.

- [x] **Zadanie #124** (`lib/engine/simulation/stage_replay_recorder.dart`): Rejestrator telemetrii etapu i powtórek ostatniego kilometra.

- [x] **Zadanie #125** (`lib/ui/screens/strava_style_stage_analysis_screen.dart`): Powyścigowa analiza danych w stylu Strava/TrainingPeaks (NP, IF, TSS, wykresy).

- [x] **Zadanie #126** (`lib/models/rider/lactate_and_lab_profile.dart`): Profil laboratoryjny kolarza ($LT_1$, $LT_2$, $VLaMax$ w mmol/l/s, Gross Efficiency).

- [x] **Zadanie #127** (`lib/services/career/physiology_lab_testing_service.dart`): Serwis badań wydolnościowych i testów stopniowanych (Ramp Test + krzywa mleczanowa).

- [x] **Zadanie #128** (`lib/ui/screens/physiology_lab_screen.dart`): Ekran Laboratorium Wydolnościowego z wykresem mleczanu (mmol/l) do mocy (W/kg).

- [x] **Zadanie #129** (`lib/models/equipment/bike_fit_configuration.dart`): Model `BikeFitConfiguration` (wysokość/cofnięcie siodła, szerokość kierownicy, korby, klamki).

- [x] **Zadanie #130** (`lib/engine/physics/bike_fit_and_wind_tunnel_engine.dart`): Silnik fizyczny łączący parametry Bike Fittingu z oporem $CdA$ i ryzykiem kontuzji.

- [x] **Zadanie #131** (`lib/ui/screens/wind_tunnel_and_bike_fit_screen.dart`): Ekran Tunelu Aerodynamicznego i studia pozycji na rowerze.

- [x] **Zadanie #132** (`lib/models/equipment/equipment_wear_and_maintenance.dart`): Model zużycia napędu, wypłukiwania wosku z łańcucha w deszczu i stanu opon.

- [x] **Zadanie #133** (`lib/engine/physics/tire_pressure_calculator.dart`): Kalkulator optymalnego ciśnienia w oponach (BAR/PSI) pod wagę, szerokość i bruk.

- [x] **Zadanie #134** (`lib/ui/widgets/mechanic_workshop_panel.dart`): Panel warsztatu mechaników do konfiguracji ciśnienia, woskowania i serwisu nocnego.

- [x] **Zadanie #135** (`lib/models/career/recovery_protocol_system.dart`): Model protokołów regeneracyjnych (kompresja, komora hiperbaryczna, sauna, opatrunki).

- [x] **Zadanie #136** (`lib/ui/screens/medical_and_recovery_center_screen.dart`): Ekran Centrum Medycznego, morfologii krwi i zarządzania regeneracją.

- [x] **Zadanie #137** (`lib/models/career/staff_member.dart`): Model członków sztabu (Dyrektor Sportowy, Trener, Lekarz, Mechanik, Skaut).

- [x] **Zadanie #138** (`lib/ui/screens/staff_management_screen.dart`): Ekran zatrudniania i przydzielania sztabu szkoleniowego.

- [x] **Zadanie #139** (`lib/services/career/winter_offseason_training_service.dart`): Serwis przygotowań zimowych (siłownia: przysiady bułgarskie, martwy ciąg, ergometr).

- [x] **Zadanie #140** (`lib/services/career/race_reconnaissance_service.dart`): Serwis rekonesansu kluczowych etapów górskich i sektorów bruku.

- [x] **Zadanie #141** (`lib/services/career/anti_doping_and_whereabouts_service.dart`): System paszportu biologicznego UCI, kontroli ADAMS i ryzyka wyłączeń TUE.

- [x] **Zadanie #142** (`lib/services/career/rider_ego_and_conflicts_service.dart`): System psychologii, ambicji liderów i rozwiązywania konfliktów w drużynie.

- [x] **Zadanie #143** (`lib/services/career/press_conference_service.dart`): Generator konferencji prasowych, wywiadów i gier psychologicznych z rywalami.

- [x] **Zadanie #144** (`lib/ui/widgets/press_interview_modal.dart`): Okno modalne konferencji prasowej z natychmiastową reakcją mediów i sponsora.

- [x] **Zadanie #145** (`lib/services/career/development_team_u23_service.dart`): Serwis zarządzania drużyną młodzieżową U23 (Devo Squad).

- [x] **Zadanie #146** (`lib/ui/screens/development_academy_screen.dart`): Ekran Akademii Młodzieżowej U23 i promocji talentów do WorldTouru.

- [x] **Zadanie #147** (`lib/services/career/equipment_sponsorship_bidding_engine.dart`): Silnik przetargów na osobnych sponsorów kół, grup osprzętu, kasków i odżywek.

- [x] **Zadanie #148** (`lib/services/career/historical_records_and_palmares_service.dart`): Archiwum trofeów (`Palmares`) oraz rekordów czasowych i VAM na podjazdach.

- [x] **Zadanie #149** (`lib/ui/screens/hall_of_fame_and_records_screen.dart`): Ekran Gabloty Trofeów i Tabeli Rekordów Wspinaczki (KOM Records).

- [x] **Zadanie #150** (`lib/services/career/email_inbox_generator_service.dart`): Generator interaktywnych wiadomości e-mail z przyciskami decyzji menedżerskich.

- [x] **Zadanie #151** (`lib/engine/weather/dynamic_mountain_weather_engine.dart`): Silnik dynamicznej pogody górskiej ze spadkiem temperatury o $0.65^\circ\text{C}/100\text{ m}$.

- [x] **Zadanie #152** (`lib/engine/peloton/feeding_and_rain_jacket_mechanics.dart`): Mechanika stref bufetu oraz zakładania kurtek przeciwdeszczowych przed zjazdami.

- [x] **Zadanie #153** (`lib/ui/screens/stage_editor_creator_screen.dart`): Wbudowany Kreator Etapów pozwalający rysować własne trasy i klasyki.

- [x] **Zadanie #154** (`lib/ui/screens/jersey_and_bike_livery_studio_screen.dart`): Studio projektowania malowania ram rowerowych i koszulek zespołu.

- [x] **Zadanie #155** (`lib/ui/widgets/animated_watt_bomb_effect.dart`): Efekt wizualny "Watt Bomb" podczas ataków przekraczających $12\text{ W/kg}$ lub $1400\text{ W}$.

- [x] **Zadanie #156** (`lib/ui/widgets/peloton_heatmap_position_widget.dart`): Interaktywna siatka pozycjonowania kolarzy na szerokości szosy.

- [x] **Zadanie #157** (`lib/ui/screens/grand_tour_rest_day_screen.dart`): Ekran Dnia Przerwy (Rest Day) podczas 3-tygodniowego Grand Touru.

- [x] **Zadanie #158** (`lib/services/career/national_championships_and_worlds_service.dart`): Serwis rozgrywania Mistrzostw Krajowych oraz Mistrzostw Świata.

- [x] **Zadanie #159** (`lib/ui/widgets/rainbow_and_national_jersey_badge.dart`): Oznaczenia Tęczowej Koszulki Mistrza Świata i mistrzów krajowych w UI i 3D.

- [x] **Zadanie #160** (`lib/services/career/uci_promotion_relegation_cycle_service.dart`): System 3-letniego cyklu licencyjnego UCI WorldTour (awanse i spadki).

- [x] **Zadanie #161** (`lib/ui/screens/uci_rankings_and_relegation_screen.dart`): Ekran Rankingów UCI i tabeli walki o utrzymanie licencji WorldTour.

- [x] **Zadanie #162** (`lib/services/career/sponsor_objectives_evaluator.dart`): Ewaluator celów sponsorskich po każdym wyścigu wypłacający bonusy i aktualizujący zaufanie zarządu.

## CZĘŚĆ II: AKTYWNA KOLEJKA — PACZKA 50 ULTRA-SZCZEGÓŁOWYCH ZADAŃ (#163 – #212)

- [x] **Zadanie #163** (`lib/ui/widgets/rider_comparison_side_by_side_modal.dart`): Stwórz w 100% produkcyjny, wizualnie zjawiskowy modal `RiderComparisonSideBySideModal` (iOS Dark Mode #0F1115, karty #181B22 z subtelnym obramowaniem 1px #2A2F3D i efektem `BackdropFilter` blur 16px). Widget musi pozwalać na jednoczesne porównanie 2 lub 3 obiektów `Rider` obok siebie. Zaimplementuj:

  1. Nagłówek z portretami `RiderAvatarWidget`, flagami narodowości, wiekiem, specjalizacją, oceną OVR (w złotym okręgu `#D4AF37` dla lidera) oraz aktualną pensją i klauzulą wykupu.

  2. Przełącznik jednostek `Bezwzględne (W) / Względne (W/kg)` z płynną animacją `AnimatedContainer` (250ms, `Curves.easeOutCubic`).

  3. Zintegrowany wykres nakładający krzywe mocy wszystkich porównywanych kolarzy (`5s, 15s, 30s, 1m, 3m, 5m, 20m, 60m`) w różnych kolorach (#8E4A49, #D4AF37, #3B82F6) z podświetleniem delty procentowej ($\Delta\%$) po najechaniu myszką lub dotknięciu punktu.

  4. Tabelę pasków porównawczych (Horizontal Dual/Triple Progress Bars) dla parametrów fizjologicznych i technicznych (`FTP`, $W'$, $VO_2max$, $VLaMax$, `cobbles`, `descending`, `bikeHandling`, `aeroPositioning`, `draftingEfficiency`, `recoveryRate`), gdzie najwyższa wartość w wierszu jest automatycznie podświetlana zielonym akcentem `#10B981` i ikoną przewagi `+X`.

  5. Responsywność przez `LayoutBuilder`: na wąskich ekranach (<600px) układ przewijany poziomo z przyklejoną kolumną nazw statystyk, na desktopie/tablecie pełna siatka wielokolumnowa bez jakiegokolwiek `RenderFlex overflow`. Zweryfikuj kompilację przez `flutter analyze`.

- [x] **Zadanie #164** (`lib/services/career/ai_team_transfer_simulation_service.dart`): Zbuduj zaawansowany serwis `AiTeamTransferSimulationService`, który symuluje realistyczny, żyjący rynek transferowy pomiędzy wszystkimi 52 drużynami AI w oknie transferowym (od 1 sierpnia do 15 listopada) oraz w trakcie sezonu (przedłużenia kontraktów). Zaimplementuj:

  1. Analizę potrzeb kadrowych każdej drużyny AI (`TeamRosterNeedsAnalyzer`): sprawdzenie braków na pozycjach `GCLeader`, `PureSprinter`, `ClassicCobbles`, `SuperDomestique` oraz weryfikację średniego wieku składu i zagrożenia spadkiem w 3-letnim rankingu UCI.

  2. Algorytm wyceny rynkowej kolarza w EUR bazujący na: wieku (krzywa szczytu wartości w wieku 24–28 lat), punktach UCI, stosunku mocy progowej $\text{W/kg}$ oraz potencjale rozwojowym.

  3. Mechanikę licytacji (Bidding Wars) między bogatymi ekipami WorldTour o najlepszych wolnych agentów i młodych kolarzy z wysokim potencjałem (w tym składanie ofert wykupu klauzuli za kolarzy z drużyny gracza!).

  4. Generator struktur `TransferNewsItem` (data, kolarz, stara drużyna, nowa drużyna, kwota kontraktu, rola, komentarz ekspercki) przekazywanych do paska informacyjnego "Transfer Ticker" w Dashboardzie oraz skrzynki Inbox. Zweryfikuj brak błędów przez `flutter analyze`.

- [x] **Zadanie #165** (`lib/ui/widgets/keyboard_shortcuts_manager.dart`): Stwórz kompletny system skrótów klawiszowych i obsługi kontrolerów `KeyboardShortcutsManager` (oparty o `Shortcuts`, `Actions`, `FocusNode` i `HardwareKeyboard` we Flutterze) dla wersji Windows (`.exe`), macOS (`.dmg`) i tabletów z klawiaturą. Zaimplementuj:

  1. Skróty wyścigowe 3D: `Spacja` (Pauza / Wznów symulację), klawisze `+` / `-` lub `[` / `]` (zmiana mnożnika prędkości czasu `1x, 2x, 4x, 8x`), klawisze `1`–`8` (wybór kolarza nr 1–8 z drużyny i natychmiastowe wycentrowanie na nim kamery 3D), `A` (rozkaz natychmiastowego ataku), `R` (daj zmianę na czele grupy), `P` (chroń lidera), `G` (spożyj żel energetyczny), `B` (spłyń do wozu technicznego po bidony), `C` (cykliczne przełączanie kamer: `ChaseCam -> MotoTvCam -> HeliCam -> FinishLineCam`), `V` (włączenie widoku strug powietrza `Aero Vision Mode`), `Tab` (ukrycie/pokazanie bocznych paneli telemetrii HUD).

  2. Skróty w trybie Menedżera: `Ctrl+S` (szybki zapis gry), `Enter` lub `Ctrl+Space` (przejście do następnego dnia `advanceDay()`), `F1` (otwarcie ściągi skrótów klawiszowych).

  3. Wizualny, półprzezroczysty modal `ShortcutsCheatSheetOverlay` wyświetlający eleganckie kafelki klawiszy (Keycaps w stylu `#222630` z obramowaniem 3D) pogrupowane na sekcje. Zweryfikuj przez `flutter analyze`.

- [x] **Zadanie #166** (`lib/ui/screens/quick_race_sandbox_screen.dart`): Zbuduj dopracowany wizualnie ekran `QuickRaceSandboxScreen` ("Szybki Wyścig / Laboratorium Taktyczne Sandbox") pozwalający graczowi skonfigurować i uruchomić dowolny wyścig 3D w 10 sekund z poziomu menu głównego. Zaimplementuj:

  1. Trójkolumnowy układ Bento Grid (automatycznie składający się do zakładek na telefonie):

     * Kolumna 1 (Wybór Trasy i Warunków): lista wszystkich wyścigów i etapów (w tym presety: *Alpe d'Huez Summit Finish*, *Paryż-Roubaix 5-Star Cobbles*, *Champs-Élysées Sprint*, *Wachlarze w Katarze 50 km/h Crosswind*, *Górska Czasówka ITT*), interaktywny podgląd `ElevationProfileChart`, wybór pogody (Słońce, Ulewa, Burza, Upał $38^\circ\text{C}$, Mróz w górach $2^\circ\text{C}$), suwak prędkości wiatru ($0–70\text{ km/h}$) i kompas kierunku wiatru.

     * Kolumna 2 (Wybór Drużyny i Składu): wybór drużyny z pełnej bazy, automatyczny dobór 8 najlepszych kolarzy pod profil trasy jednym przyciskiem (`Auto-Pick Optimal Roster`) lub ręczna wymiana zawodników z podglądem ich W/kg i umiejętności.

     * Kolumna 3 (Szybki Setup Sprzętowy): wybór presetu rowerowego dla drużyny (`Full Aero 65mm`, `Ultralight Climbing 6.8kg`, `Cobble Tubeless 32mm 3.8 bar`), przycisk "START SYMULACJI 3D" w kolorze `#8E4A49` ze złotym podświetleniem hover `#D4AF37`, który inicjuje `RaceSimulationNotifier` i przenosi gracza na ekran `Race3dViewportWidget`. Zweryfikuj przez `flutter analyze`.

- [x] **Zadanie #167** (`lib/ui/screens/main_title_menu_screen.dart`): Stwórz ekran tytułowy gry klasy AAA `MainTitleMenuScreen`, który robi piorunujące pierwsze wrażenie po uruchomieniu gry na PC/Mac i telefonie. Zaimplementuj:

  1. Dynamiczne tło 3D/Canvas (`AnimatedPelotonBackdropPainter`): płynnie animowana w 60/120 FPS scena sylwetek kolarzy pokonujących alpejską serpentynę o zachodzie słońca (głęboki granat `#0F1115` przechodzący w krwistą czerwień `#8E4A49` i złoto `#D4AF37` na horyzoncie, obracające się szprychy, smugi świateł wozów technicznych i subtelny ruch kamery z efektami paralaksy reagującymi na ruch kursora myszy).

  2. Lewy panel nawigacyjny w stylu nowoczesnych gier sportowych (szklany panel `BackdropFilter` z gradientem `#181B22` przy 85% krycia): typograficzne logo **PRO PELOTON MANAGER** ze złotym podtytułem `WORLD TOUR EDITION`, wskaźnik aktywnej bazy danych (np. `Default Fictional DB v1.0` lub `Custom Real Name Pack Active`) oraz status ostatniego zapisu kariery.

  3. Animowane przyciski menu z mikro-interakcjami (rozszerzenie paska akcentowego `#D4AF37` przy najechaniu, dźwięk kliknięcia):

     * `KONTYNUUJ KARIERĘ` (widoczny i podświetlony, jeśli istnieje zapis w `SaveGameManager`, wyświetla nazwę drużyny i datę w grze),

     * `NOWA KARIERA` (przejście do `NewCareerSetupScreen`),

     * `WCZYTAJ GRĘ` (modal wyboru jednego z 5 slotów zapisu z opcją importu/eksportu pliku),

     * `SZYBKI WYŚCIG (SANDBOX)` (przejście do `QuickRaceSandboxScreen`),

     * `KREATOR TRAS I STUDIO MALOWANIA` (wybór `StageEditorCreatorScreen` lub `JerseyAndBikeLiveryStudioScreen`),

     * `BAZY DANYCH I USTAWIENIA` (przejście do `SettingsAndModScreen`). Zweryfikuj przez `flutter analyze`.

- [x] **Zadanie #168** (`lib/services/database/preset_real_names_template_generator.dart`): Stwórz serwis `PresetRealNamesTemplateGenerator`, który pozwala graczowi i społeczności moderskiej wygenerować jednym kliknięciem na dysku kompletny, ustrukturyzowany plik szablonu `pro_peloton_real_names_pack_template.json` oraz wbudowany pakiet `Community Realism Patch Structure`. Zaimplementuj:

  1. Eksport wszystkich obecnych w grze ID drużyn, kolarzy, wyścigów i marek sprzętu wraz z ich polami mapującymi (`originalId`, `customName`, `customShortName`, `customCountryIso`, `primaryHex`, `secondaryHex`, `jerseyPatternIndex`).

  2. Walidator schematu (`ModSchemaValidator`), który przed zaaplikowaniem paczki sprawdza poprawność kolorów HEX, unikalność ID oraz obecność wszystkich wymaganych kluczy, zwracając szczegółowy raport (liczba podmienionych kolarzy, drużyn, rowerów i wyścigów).

  3. Metodę `applyLivePatchToActiveCareer()`, która pozwala podmienić nazwy na prawdziwe nawet w trakcie trwającej już kariery bez psucia postępów, kontraktów i wyników w klasyfikacjach! Zweryfikuj przez `flutter analyze`.

- [x] **Zadanie #169** (`lib/ui/widgets/tutorial_coach_marks_overlay.dart`): Stwórz interaktywny system samouczka i podpowiedzi taktycznych `TutorialCoachMarksOverlay` dla nowych graczy, utrzymany w estetyce ciemnego szkła (`#181B22`, złota ramka `#D4AF37`, strzałki wektorowe wskazujące konkretne elementy interfejsu). Zaimplementuj:

  1. Tryb prowadzenia za rękę podczas pierwszego wyścigu (Interactive Race Academy - 6 kroków):

     * Krok 1: Fizyka Draftingu i Wiatru (dlaczego jazda na czele kosztuje $100\%$ mocy, a schowanie lidera w środku grupy oszczędza do $45\%$ watów).

     * Krok 2: Zapas Beztlenowy $W'$ (czerwony pasek w kJ) kontra Glikogen (żółty pasek w gramach) – kiedy użyć żelu energetycznego (90–120g węglowodanów/h), żeby uniknąć "odcięcia prądu" (bonk) na ostatnim podjeździe.

     * Krok 3: Pociąg Górski vs Samotny Atak – jak ustawić pomocników na tempo $5.8\text{ W/kg}$ przed skokiem lidera.

     * Krok 4: Ciśnienie w oponach i Bruk – wpływ szerokości opon (28mm vs 32mm) i ciśnienia na straty oporów toczenia ($Crr$) i ryzyko przebicia.

     * Krok 5: Planowanie Szczytu Formy (TSB = CTL - ATL) w kalendarzu przed docelowym Grand Tourem.

  2. Możliwość pominięcia samouczka w dowolnej chwili oraz ponownego uruchomienia z ekranu ustawień. Zweryfikuj przez `flutter analyze`.

- [x] **Zadanie #170** (`lib/core/utils/performance_profiler_overlay.dart`): Zbuduj profesjonalny widget diagnostyczny `PerformanceProfilerOverlay` (włączany klawiszem `F3` na Windows/macOS lub przełącznikiem w ustawieniach), wyświetlany w prawym górnym rogu ekranu. Zaimplementuj:

  1. Pomiar w czasie rzeczywistym za pomocą `SchedulerBinding.instance.addTimingsCallback`: aktualny licznik FPS (z podświetleniem na zielono $\ge 60\text{ FPS}$, żółto $30–59\text{ FPS}$, czerwono $<30\text{ FPS}$), czas budowania klatki UI (`Build ms`), czas rasteryzacji GPU (`Raster ms`).

  2. Wykres słupkowy ostatnich 60 klatek (Frame Time Graph) z poziomą linią budżetu klatki ($8.33\text{ ms}$ dla 120 Hz oraz $16.67\text{ ms}$ dla 60 Hz).

  3. Telemetrię silnika symulacji kolarskiej: czas przeliczenia 1 ticku fizyki dla 176 kolarzy w wątku `Isolate` (w mikrosekundach $\mu\text{s}$), liczba aktywnych obiektów 3D w kamerze (LOD0 / LOD1 / LOD2) oraz aktualne zużycie pamięci RAM procesu. Zweryfikuj przez `flutter analyze`.

- [x] **Zadanie #171** (`lib/ui/screens/main_shell_screen.dart`): Zaktualizuj i dopieść do perfekcji `MainShellScreen` oraz powiązany `lib/core/router/app_router.dart`, tak aby spinały absolutnie wszystkie ekrany menedżerskie i wyścigowe w jeden spójny, luksusowy ekosystem. Zaimplementuj:

  1. Kategoryzowany boczny pasek nawigacyjny (Sidebar na Desktop/Tablet, Szuflada + BottomBar na Mobile) podzielony na 4 czytelne sekcje z ikonami i licznikami powiadomień (Badges):

     * `CENTRUM DOWODZENIA`: Biuro HQ (Dashboard), Skrzynka Odbiorcza (z licznikiem nieprzeczytanych maili), Kalendarz UCI & Planer Startów.

     * `ZESPÓŁ I WYDOLNOŚĆ`: Kadra Zespołu, Budowa Teamu i Hierarchia, Treningi i Obozy (PMC), Laboratorium Fizjologiczne (Mleczan/VO2max), Centrum Medyczne i Regeneracja, Akademia U23 (Devo), Sztab Szkoleniowy.

     * `SPRZĘT I FINANSE`: Garaż i R&D, Tunel Aerodynamiczny i Bike Fit, Sponsorzy i Finanse, Rynek Transferowy i Skauting, Studio Malowania Rowerów i Koszulek.

     * `ŚWIAT UCI`: Rankingi UCI i Walka o Licencję, Gablota Trofeów i Rekordy Górskie, Profil Menedżera i Osiągnięcia, Kreator Tras, Ustawienia i Mody.

  2. Górny pasek TopBar wyświetlający: herb i barwy drużyny, stan konta w EUR, aktualną datę, pogodę w bazie, mini-odliczanie dni do kolejnego wyścigu oraz wielki, dynamiczny przycisk akcji: `NASTĘPNY DZIEŃ` (lub czerwono-złoty `START WYŚCIGU: [Nazwa Wyścigu]`, jeśli w danym dniu drużyna staje na starcie!). Zweryfikuj przez `flutter analyze`.

- [x] **Zadanie #172** (`lib/state/career_state_notifier.dart`): Rozbuduj i zintegruj metodę `advanceDay()` oraz `advanceToNextEvent()` w `CareerStateNotifier`, aby stanowiły bezbłędne serce symulacji całego świata kolarskiego dzień po dniu. Zaimplementuj:

  1. Codzienną pętlę aktualizacji dla wszystkich drużyn: przeliczanie obciążeń treningowych (CTL, ATL, TSB), aplikowanie efektów obozów wysokogórskich i sesji regeneracyjnych (hiperbaria, sauna, kompresja), postęp leczenia kontuzji, zużycie sprzętu i automatyczną symulację wyścigów w kalendarzu, w których gracz nie bierze udziału (aby tabele UCI i statystyki rywali żyły przez cały rok).

  2. Wyzwalacze zdarzeń specjalnych: otwarcie okna transferowego (1 sierpnia), losowe kontrole antydopingowe ADAMS, zaproszenia na konferencje prasowe przed wielkimi Tourami, raporty od skautów U23, miesięczne rozliczenia pensji i transz sponsorskich oraz weryfikację celów po wyścigach (`SponsorObjectivesEvaluator`).

  3. Funkcję `simulateUntilNextStop()`, która pozwala płynnie przewijać dni w kalendarzu (z animowanym licznikiem daty), zatrzymując się automatycznie przed ważnym mailem decyzyjnym, ofertą transferową lub dniem startu wyścigu. Zweryfikuj przez `flutter analyze`.

- [x] **Zadanie #173** (`lib/ui/screens/race_hud_overlay.dart`): Przebuduj i ulepsz `RaceHudOverlay`, aby wyglądał jak połączenie oficjalnej oprawy telewizyjnej Tour de France (styl ASO Broadcast Graphics) oraz interfejsu Zwift/MyWhoosh. Zaimplementuj:

  1. Lewy Panel Kolarzy Drużyny (8 kompaktowych, szklanych kart): na każdej karcie portret kolarza, numer startowy, aktualna pozycja w wyścigu (np. `14.`), aktualne przełożenie, waty i $\text{W/kg}$ (z kolorowym tłem strefy mocy Z1–Z7), tętno bpm, dwa precyzyjne paski energii (żółty glikogen i czerwony beztlenowy $W'$), ikony pozostałych bidonów i żeli oraz ikona aktywnego rozkazu. Kliknięcie karty przełącza kamerę 3D na tego kolarza i rozwija jego panel rozkazów.

  2. Górny Pasek Telewizyjny (Broadcast Top Bar): logo wyścigu, kilometr do mety (ze specjalnym złotym podświetleniem poniżej $10\text{ km}$ i czerwonym płomieniem *Flamme Rouge* na ostatnim $1.0\text{ km}$), widget tablicy motocyklisty `GroupGapsChalkboardWidget`, wskaźnik wiatru i nachylenia podjazdu oraz przyciski prędkości symulacji (`Pause, 1x, 2x, 4x, 8x, Skocz do Akcji`).

  3. Prawy Dolny Róg: interaktywny komputer rowerowy `OnBikeComputerHudWidget`, minimapa 2D/3D `TacticalMinimap2dWidget` oraz przełącznik `Aero Vision Mode`.

  4. Dolna Konsola Taktyczna: `RiderEffortSliderControl` oraz `TeamTacticalPresetsBar` z płynnymi animacjami wejścia/wyjścia. Użyj `LayoutBuilder`, aby na mniejszych ekranach panele boczne mogły być zwijane jednym kliknięciem bez zasłaniania widoku 3D kolarzy. Zweryfikuj przez `flutter analyze`.

- [x] **Zadanie #174** (`lib/services/career/achievement_and_milestones_service.dart`): Stwórz kompletny serwis `AchievementAndMilestonesService` zarządzający 45 osiągnięciami (Achievements) i kamieniami milowymi kariery menedżera, podzielonymi na 4 rangi (`Bronze`, `Silver`, `Gold`, `Platinum Legend`). Zaimplementuj:

  1. Definicje 45 wyzwań kolarskich z warunkami sprawdzanymi automatycznie po każdym etapie i sezonie, m.in.:

     * *Solo z Daleka*: Wygraj etap po samotnym ataku z dystansu ponad $50\text{ km}$ przed metą.

     * *Mistrz Rantów*: Rozerwij peleton na bocznym wietrze i przyjedź z przewagą ponad 2 minut nad głównym rywalem GC.

     * *Król Piekła Północy*: Wygraj brukowany Monument w deszczu bez ani jednej wymiany roweru.

     * *Inżynier Watów*: Osiągnij w tunelu aerodynamicznym współczynnik $CdA < 0.190\text{ m}^2$ dla kolarza czasowego.

     * *Od Zera do WorldTouru*: Awansuj własnym zespołem z dywizji Continental do WorldTour i wygraj Wielki Tour.

  2. Emitowanie zdarzeń odblokowania osiągnięcia, które wyświetlają na ekranie elegancki, animowany baner powiadomienia (Toast w stylu trofeów PlayStation/Steam ze złotym blaskiem `#D4AF37`). Zweryfikuj przez `flutter analyze`.

- [x] **Zadanie #175** (`lib/ui/screens/manager_profile_and_achievements_screen.dart`): Stwórz ekran `ManagerProfileAndAchievementsScreen` prezentujący dorobek kariery gracza. Zaimplementuj:

  1. Kartę Licencji Dyrektora Sportowego UCI (wyglądającą jak fizyczna, holograficzna przepustka VIP z Touru): imię i nazwisko menedżera, narodowość, poziom reputacji (1–100), ulubiona specjalizacja taktyczna, liczba rozegranych sezonów, bilans zwycięstw (Etapy, Klasyfikacje Generalne, Monumenty) oraz łączna kwota wygranych nagród finansowych.

  2. Wykres kołowy i słupkowy zwycięstw według typu terenu (Płaskie, Pagórki, Wysokie Góry, Bruki, Czasówki).

  3. Siatkę 45 odblokowanych i zablokowanych osiągnięć z paskami postępu (np. `Wygrane etapy z ucieczki: 7/10`), filtrowaniem według rangi i datą zdobycia. Zweryfikuj przez `flutter analyze`.

- [x] **Zadanie #176** (`blender_scripts/generate_cobble_monument_props.py`): Napisz kompletny, bezbłędny skrypt Blender 5.3 Python API (`bpy`), który proceduralnie buduje w 3D ikoniczne obiekty Wiosennych Klasyków i Monumentów brukowanych:

  1. Betonowy Welodrom na finał klasyku (`assets/3d/environment/velodrome_finish_arena.glb`): owalna niecka toru kolarskiego z nachylonymi wirażami ($31^\circ$), trawą pośrodku, linią mety i zadaszoną trybuną historyczną.

  2. Zestaw rekwizytów sektora bruku (`assets/3d/environment/cobble_sector_props.glb`): drewniana brama wjazdowa na sektor z oznaczeniem 5 gwiazdek trudności (`*****`), kamienny pomnik przy drodze oraz geometryczne tafle błota i kałuż z materiałem o niskim `Roughness = 0.08` (efekt lustra wody).
     Skrypt musi automatycznie tworzyć katalogi wyjściowe i eksportować pliki w formacie glTF 2.0 (`.glb`).

- [x] **Zadanie #177** (`blender_scripts/generate_alpine_summit_scenery.py`): Napisz kompletny skrypt Blender 5.3 Python API (`bpy`), który proceduralnie modeluje w 3D scenerię szczytu wysokogórskiego Hors Categorie (`assets/3d/environment/alpine_summit_pack.glb`):

  1. Charakterystyczny budynek obserwatorium meteorologicznego z biało-czerwoną wieżą przekaźnikową (inspirowany Mont Ventoux / Pic du Midi).

  2. Wysokie na 3 metry ściany śnieżne po obu stronach szosy (inspirowane przełęczą Stelvio / Gavia w maju) z chłodnym, lekko niebieskawym materiałem śniegu.

  3. Zestaw 3 stylizowanych kamperów (RV) kibiców z markizami i flagami kolarskimi ustawianych na zakrętach serpentyn. Zapewnij czysty eksport do `.glb`.

- [x] **Zadanie #178** (`blender_scripts/generate_time_trial_start_ramp.py`): Napisz skrypt Blender 5.3 Python API (`bpy`), który proceduralnie modeluje w 3D profesjonalny domek i rampę startową do jazdy na czas (`assets/3d/environment/tt_start_ramp.glb`):

  1. Zadaszony pawilon startowy z nowoczesną ramą stalowo-szklaną w kolorach ciemnego grafitu `#181B22` i czerwieni `#8E4A49`.

  2. Nachyloną pochylnię zjazdową z antypoślizgowym pasem, stojak startowy przytrzymujący tylne koło roweru TT oraz bramkę elektronicznego zegara odliczającego z diodami LED (czerwona, żółta, zielona). Wyeksportuj do `.glb`.

- [x] **Zadanie #179** (`blender_scripts/generate_podium_and_trophies.py`): Napisz skrypt Blender 5.3 Python API (`bpy`), który proceduralnie modeluje w 3D scenę dekoracji po etapie (`assets/3d/environment/podium_stage.glb`) oraz zestaw 4 prestiżowych trofeów kolarskich (`assets/3d/environment/trophies_pack.glb`):

  1. Trzystopniowe podium ze ścianką sponsorską, schodkami i reflektorami scenicznymi.

  2. Modele trofeów z materiałami złota (`Metallic = 1.0, Roughness = 0.15`), granitu i szkła: Kostka Bruku na drewnianym postumencie, Złoty Puchar Wielkiego Touru, Złota Spirala nieskończoności oraz Trójząb Morza Tyrreńskiego.

- [x] **Zadanie #180** (`blender_scripts/generate_wind_tunnel_facility.py`): Napisz skrypt Blender 5.3 Python API (`bpy`), który proceduralnie modeluje w 3D komorę pomiarową Tunelu Aerodynamicznego (`assets/3d/environment/wind_tunnel_room.glb`):

  1. Cylindryczny kanał powietrzny z ogromnym, 12-łopatkowym wirnikiem wentylatora w tle i siatką prostującą przepływ.

  2. Obrotową platformę aerodynamiczną w podłodze (do testowania kątów wiatru bocznego Yaw $-15^\circ$ do $+15^\circ$) z rolkami pod koła roweru, listwami świetlnymi LED na ścianach i dyszą wypuszczającą strugi dymu przed przednim kołem.

- [x] **Zadanie #181** (`blender_scripts/generate_helicopter_and_blimp.py`): Napisz skrypt Blender 5.3 Python API (`bpy`), który proceduralnie modeluje w 3D śmigłowiec telewizyjny krążący nad peletonem (`assets/3d/environment/tv_helicopter.glb`):

  1. Aerodynamiczny kadłub śmigłowca w barwach transmisji wyścigowej, płozy podwozia, wirnik główny i ogonowy (jako osobne, nazwane obiekty pod animację obrotu) oraz kulistą głowicę kamery żyroskopowej Cineflex zamontowaną pod dziobem.

- [x] **Zadanie #182** (`blender_scripts/generate_jersey_textures_baker.py`): Napisz skrypt w Pythonie (kompatybilny ze środowiskiem Pythona wbudowanym w Blender 5.3), który proceduralnie generuje i zapisuje na dysku w folderze `assets/textures/jerseys/` zestaw tekstur PNG (rozdzielczość 1024x1024) dla modeli 3D kolarzy:

  1. Koszulki liderów klasyfikacji: `jersey_gc_yellow.png` (#D4AF37), `jersey_points_green.png` (#10B981), `jersey_kom_polkadot.png` (biała w czerwone grochy #EF4444), `jersey_youth_white.png` (#F3F4F6), `jersey_world_champ_rainbow.png` (5 pasów tęczy UCI na białym tle).

  2. 8 szablonów wzorów drużynowych (szewron, pas piersiowy, gradient alpejski, pasy pionowe, szachownica, ukośna szarfa) gotowych do barwienia kolorami drużyny w silniku gry.

- [x] **Zadanie #183** (`blender_scripts/build_all_assets_master.py` oraz `build_3d_assets_windows.bat`): Zaktualizuj skrypt główny `blender_scripts/build_all_assets_master.py`, aby wykonywał wszystkie skrypty od #086 do #182 w sposób w 100% kompatybilny z **Blender 5.3.0 na Windows** (obsługa zmian w API `bpy` w wersji 5.x, bezpieczne ścieżki `os.path`, przechwyt wyjątków `try/except` dla każdego pliku z osobna, generowanie raportu `assets/3d/asset_manifest.json`). Stwórz również w głównym katalogu plik `build_3d_assets_windows.bat`, który uruchamia proces w tle i wypisuje status każdego wygenerowanego pliku `.glb`.

- [x] **Zadanie #184** (`lib/engine/peloton/boids_steering_collision_avoidance.dart`): Aby kolarze w widoku 3D nigdy nie przenikali przez siebie (brak efektu "clippingu" siatek 3D) i poruszali się jak prawdziwy, żywy peleton szosowy, stwórz silnik fizyki ruchu ciągłego `BoidsSteeringCollisionAvoidance`. Zaimplementuj:

  1. Trzy wektory sterujące dla każdego z 176 kolarzy w każdej klatce (60 FPS):

     * **Separacja (Collision Avoidance):** minimalna bezpieczna kopuła wokół roweru ($1.85\text{ m}$ długości $\times 0.65\text{ m}$ szerokości). Gdy dwóch kolarzy zbliża się zbyt mocno bokiem, wyliczana jest płynna siła odpychająca na boki szosy ($\Delta y$).

     * **Szukanie Cienia Aerodynamicznego (Draft Seeking):** kolarz automatycznie przesuwa się za plecy kolarza jadącego z przodu, ustawiając się lekko po przekątnej w przypadku wiatru bocznego (formowanie wachlarza).

     * **Wyprzedzanie i Atak (Overtaking Lane Finder):** gdy kolarz ma wyższą prędkość niż zawodnik przed nim, skanuje lewą i prawą stronę drogi w promieniu $15\text{ m}$, wybiera wolny korytarz, płynnie zmienia tor jazdy (z animacją wychylenia roweru), wyprzedza i wraca do szyku.

  2. Uwzględnij zwężenia szosy (np. wjazd na wąski sektor bruku o szerokości $3.2\text{ m}$), co naturalnie rozciąga peleton w długiego "węża" (efekt akordeonu / *gruppo allungato*). Zweryfikuj przez `flutter analyze`.

- [x] **Zadanie #185** (`lib/engine/rendering3d/broadcast_tv_graphics_overlay.dart`): Stwórz zestaw autentycznych grafik telewizyjnych `BroadcastTvGraphicsOverlay` wzorowanych na oficjalnej oprawie telewizyjnej Eurosportu / Tour de France, które pojawiają się dynamicznie podczas transmisji wyścigu 3D. Zaimplementuj:

  1. **Belkę dolną prezentacji kolarza (Lower-Third Rider Spotlight):** gdy kamera przełącza się na lidera lub atakującego zawodnika, z dołu ekranu wyjeżdża animowana belka ze złotym paskiem `#D4AF37`, portretem, flagą, miejscem w klasyfikacji generalnej, aktualną mocą (W i W/kg), tętnem oraz prędkością chwilową.

  2. **Grafikę Profilu Podjazdu (Climb Telemetry Banner):** przy wjeździe na kategoryzowany podjazd (Cat 4 do HC) wyświetla się belka z nazwą przełęczy, długością, średnim nachyleniem, wysokością szczytu n.p.m. oraz przewidywanym czasem wspinaczki i aktualnym VAM ($\text{m/h}$) grupy liderów.

  3. **Stoper Punktów Pomiaru Czasu (Live Split Timer):** na premiach górskich, lotnych finiszach oraz punktach pomiaru czasu ITT wyświetla na żywo tykający do setnych części sekundy stoper i tabelę Top 5 z różnicami zielonymi (`-0'12"`) lub czerwonymi (`+0'28"`). Zweryfikuj przez `flutter analyze`.

- [x] **Zadanie #186** (`lib/engine/rendering3d/dynamic_skybox_and_lighting_painter.dart`): Stwórz zaawansowany renderer oświetlenia atmosferycznego, nieba i cieni `DynamicSkyboxAndLightingPainter` dla widoku wyścigu 3D. Zaimplementuj:

  1. Proceduralny gradient nieba zależny od pory dnia etapu (np. start o 11:30 w pełnym słońcu, finisz królewskiego etapu w Alpach o 17:15 w ciepłym świetle *Golden Hour*, lub wieczorne kryterium / finisz w Paryżu przy światłach latarni) oraz pogody (stalowe chmury burzowe z błyskami w oddali podczas deszczu).

  2. Dynamiczne cienie rzucane przez kolarzy i rowery na asfalt (Projected Drop Shadows): kąt i długość cienia każdego kolarza wyliczane z pozycji słońca oraz nachylenia drogi.

  3. Efekt mokrego asfaltu (`WetRoadSpecularReflection`): podczas deszczu szosa odbija przytłumione kolory koszulek peletonu oraz czerwone światła tylne samochodów dyrektora sportowego. Zweryfikuj przez `flutter analyze`.

- [x] **Zadanie #187** (`lib/engine/rendering3d/peloton_3d_canvas_engine.dart`): Aby widok 3D działał ze gwarantowaną płynnością 120 FPS od razu po uruchomieniu na Windows, macOS, Androidzie i iOS (nawet zanim zewnętrzne pliki `.glb` zostaną załadowane), zbuduj ultrawydajny, natywny silnik renderowania 3D na Canvasie Fluttera `Peloton3dCanvasEngine` wykorzystujący rzutowanie macierzowe `vector_math_64`. Zaimplementuj:

  1. Trójwymiarowe rysowanie wstęgi drogi z perspektywą, zakrętami, zmianami nachylenia, teksturą asfaltu/bruku, pasami ruchu, barierkami ochronnymi, drzewami, skałami i bramami kilometrowymi.

  2. Pełne bryły 3D kolarzy i rowerów z cieniowaniem kierunkowym: obracające się koła ze stożkami karbonowymi (35/50/65mm/Dysk), trójkąty ramy w kolorze zespołu, animowane dwusegmentowe nogi (udo + łydka z białymi skarpetkami aero i butami) poruszające się w rytm kadencji RPM, pochylony tułów w koszulce drużynowej lub koszulce lidera (żółta/zielona/grochy/tęczowa), głowa w kasku aero i okularach.

  3. Pełną integrację z kamerami (`ChaseCam`, `MotoTvCam`, `HeliCam`, `FinishLineCam`) oraz fizyką omijania kolizji z zadania #184. Dzięki temu wyścig wygląda spektakularnie w 3D w każdej sytuacji! Zweryfikuj przez `flutter analyze`.

- [x] **Zadanie #188** (`lib/ui/screens/team_bus_locker_room_screen.dart`): Stwórz klimatyczny ekran Wnętrza Autobusu Drużyny przed startem etapu `TeamBusLockerRoomScreen`, który buduje niesamowitą immersję rodem z dokumentów kolarskich (styl *Tour de France: W sercu peletonu*). Zaimplementuj:

  1. Wizualizację nowoczesnego wnętrza autobusu zespołu (`CustomPainter` z fotelami skórzanymi, oświetleniem LED w barwach drużyny, ekranem taktycznym TV na ścianie i zawieszonymi koszulkami startowymi kolarzy).

  2. Interaktywne karty 8 kolarzy siedzących w autobusie z ich aktualnym samopoczuciem dnia ("Day Condition / Noga Dnia" od $-5$ do $+5$, odkrywana po krótkiej rozgrzewce na trenażerze przed autobusem!).

  3. Możliwość wygłoszenia mowy motywacyjnej przez Dyrektora Sportowego przed wyjściem na linię startu (`Zdejmijcie presję`, `Jedziemy dziś wszystko na naszego lidera!`, `Zaatakujcie od kilometra zero!`, `Przetrwajcie ten etap w limicie czasu`), która modyfikuje morale i początkową koncentrację kolarzy na pierwszych 20 kilometrach wyścigu. Zweryfikuj przez `flutter analyze`.

- [x] **Zadanie #189** (`lib/engine/physics/day_condition_and_biorhythm_engine.dart`): Stwórz silnik dyspozycji dnia `DayConditionAndBiorhythmEngine`, który decyduje o subtelnych wahaniach dyspozycji kolarza w konkretnym dniu wyścigowym (od $-5$ "Kryzys / Ciężkie nogi" do $+5$ "Dzień Konia / Diamentowa noga"). Zaimplementuj:

  1. Algorytm losowania ważonego oparty o: aktualną świeżość (TSB), jakość snu/regeneracji nocnej, dopasowanie pogody do preferencji kolarza (`rainResistance`, `heatTolerance`), morale oraz lojalność wobec lidera.

  2. Wpływ dyspozycji dnia na parametry podczas etapu: każdy punkt powyżej zera zwiększa dostępne FTP o $+1.2\%$, pojemność beztlenową $W'$ o $+2.5\%$ oraz szybkość regeneracji między skokami; wartości ujemne analogicznie obniżają pułap tlenowy.

  3. Mechanikę odkrywania dyspozycji dnia: na starcie etapu dyspozycja rywali (oraz kolarzy gracza, którzy nie zrobili rozgrzewki na trenażerze) jest ukryta pod znakiem `?` i odkrywa się dopiero, gdy tętno kolarza przekroczy próg $LT_1$ na pierwszym podjeździe! Zweryfikuj przez `flutter analyze`.

- [x] **Zadanie #190** (`lib/ui/widgets/custom_carbon_and_glass_containers.dart`): Stwórz bibliotekę luksusowych komponentów wizualnych wielokrotnego użytku `CustomCarbonAndGlassContainers`, która nada wszystkim ekranom gry wygląd przewyższający EA Sports FC i nowoczesne aplikacje iOS. Zaimplementuj:

  1. `CarbonFiberCard`: kontener z proceduralnie rysowaną w tle subtelną mikroteksturą włókna węglowego (Carbon 3K weave pod kątem $45^\circ$), ciemnym lakierem `#181B22`, odbiciem światła na górnej krawędzi (1px gradient `#3A4154` do przezroczystości) oraz płynnym podświetleniem obramowania na kolor `#8E4A49` lub `#D4AF37` po najechaniu kursorem (`MouseRegion`).

  2. `GlassmorphicHudPanel`: półprzezroczysty panel dla nakładek wyścigowych 3D z rozmyciem tła (`ImageFilter.blur(sigmaX: 14, sigmaY: 14)`), delikatnym szumem i zaokrągleniem 16px.

  3. `AnimatedStatBadge`: kafelek statystyki (np. `6.4 W/kg`, `FTP 415W`) z animowanym licznikiem `TweenAnimationBuilder`, który przy zmianie wartości płynnie przelicza cyfry. Zweryfikuj przez `flutter analyze`.

- [ ] **Zadanie #191** (`lib/core/utils/windows_desktop_window_config.dart`): Stwórz kompletną konfigurację okna i skalowania dla wersji Desktop (`Windows` oraz `macOS`) w klasie `WindowsDesktopWindowConfig`. Zaimplementuj:

  1. Responsywny wrapper skalujący interfejs (`DesktopResponsiveScaler`), który gwarantuje ostrość czcionek i idealne proporcje kart na rozdzielczościach od `1280x720`, przez `1920x1080` (Full HD), `2560x1440` (QHD) aż po `3840x2160` (4K).

  2. Niestandardowy, zintegrowany pasek stanu aplikacji z przełącznikiem pełnego ekranu (`F11`), szybkim podglądem obciążenia wątku fizyki oraz przyciskiem zrzutu ekranu (Screenshot Mode ukrywa HUD do zrobienia czystego zdjęcia peletonu 3D). Zweryfikuj przez `flutter analyze`.

- [ ] **Zadanie #192** (`lib/services/database/demo_save_preset_builder.dart`): Stwórz klasę `DemoSavePresetBuilder` generującą 4 gotowe, bogate w detale scenariusze startowe ("Scenariusze Szybkiego Startu Kariery"), dzięki którym gracz może od razu wskoczyć w środek wielkich emocji bez zaczynania od 1 stycznia:

  1. `Polski Projekt WorldTour`: prowadzisz ambitną polską ekipę ProTeam z budżetem 8 mln EUR, młodym talentem górskim z Tatr i walczysz o Dziką Kartę na Wielką Pętlę.

  2. `Pojedynek Tytanów w Alpach`: zapis gry bezpośrednio przed 18. etapem Wielkiego Touru (3 przełęcze ponad 2000m n.p.m.), gdzie Twój lider traci tylko 14 sekund do żółtej koszulki!

  3. `Kampania Brukowana`: kwiecień, Twój zespół klasykowców staje przed decydującym tygodniem dwóch brukowanych Monumentów w deszczowej Belgii i północnej Francji.

  4. `Imperium Galaktyczne`: zarządzasz najbogatszą drużyną świata (budżet 45 mln EUR) z trzema gwiazdami w składzie, musisz pogodzić ich wielkie ego i wygrać wszystkie 3 Grand Toury w jednym sezonie. Zweryfikuj przez `flutter analyze`.

- [ ] **Zadanie #193** (`lib/engine/simulation/tactical_ai_personality_profiles.dart`): Stwórz system osobowości taktycznych dla kolarzy i dyrektorów sportowych AI `TacticalAiPersonalityProfiles`, aby rywale w wyścigu 3D zachowywali się nieprzewidywalnie i z charakterem. Zaimplementuj 6 archetypów AI:

  1. `CannibalAttacker` (styl Pogačara): nie czeka na ostatni kilometr – atakuje już na przedostatniej przełęczy 50 km przed metą, jeśli czuje słabość rywali.

  2. `DieselCalculator` (styl Vingegaarda / Dumoulina): ignoruje szarpane zrywy rywali, jedzie równym, morderczym tempem według miernika mocy na własnym progu FTP, doganiając przegrzanych atakujących pod szczytem.

  3. `WheelsuckerOpportunist`: oszczędza każdą kroplę energii w ucieczce, odmawia dawania mocnych zmian, by wyskoczyć z koła na ostatnich 300 metrach.

  4. `KamikazeDescender`: atakuje na szczycie przełęczy i podejmuje maksymalne ryzyko na krętym zjeździe, zmuszając ostrożniejszych rywali do pogoni w dolinie.

  5. `BreakawayHunter`: specjalista od ucieczek, który skacze do każdego odjazdu i walczy o każdą premię górską do koszulki w grochy.

  6. `LoyalRoadCaptain`: weteran, który w ułamku sekundy oddaje własne koło liderowi po defekcie i ustawia zespół przed zakrętami. Zweryfikuj przez `flutter analyze`.

- [ ] **Zadanie #194** (`lib/ui/widgets/interactive_stage_timeline_scrubber.dart`): Stwórz interaktywny pasek osi czasu wyścigu `InteractiveStageTimelineScrubber` umieszczony nad profilem wysokościowym etapu. Zaimplementuj:

  1. Znaczniki wszystkich wydarzeń, które miały miejsce dotychczas na etapie (ikona błyskawicy = atak, ikona klucza = defekt, ikona ostrzeżenia = kraksa, ikona góry = wyniki premii KOM, ikona bidonu = strefa bufetu).

  2. Po najechaniu kursorem na dowolny znacznik wyświetla się dymek (Tooltip) z dokładnym kilometrem etapu, godziną i opisem sytuacji (np. `Km 114.2: Kraksa w środku peletonu (12 kolarzy zatrzymanych)`).

  3. Na ekranie podsumowania etapu oś czasu pozwala przewijać i analizować, w którym dokładnie kilometrze wyścigu rozstrzygnęły się losy klasyfikacji generalnej. Zweryfikuj przez `flutter analyze`.

- [ ] **Zadanie #195** (`lib/ui/screens/sponsor_pitch_deck_negotiation_modal.dart`): Stwórz interaktywne okno negocjacji ze sponsorem tytularnym `SponsorPitchDeckNegotiationModal`, w którym gracz składa ofertę budżetową na nowy sezon. Zaimplementuj:

  1. Wizualną prezentację "Pitch Decku" drużyny: podgląd nowej koszulki zespołu z wyeksponowanym logo negocjowanego sponsora na piersi i spodenkach, prognozę ekspozycji telewizyjnej (Media Value Index wyliczany z liczby startów w WorldTourze i popularności liderów).

  2. Interaktywne suwaki negocjacyjne w 3 rundach rozmów:

     * Roczna kwota wsparcia (w EUR),

     * Długość kontraktu (1–4 lata),

     * Premia za wygranie Wielkiego Touru / Monumentu,

     * Lista 3 celów obowiązkowych, które gracz sam może zmodyfikować (im ambitniejsze cele wybierze gracz, tym wyższy budżet bazowy zgodzi się wypłacić zarząd sponsora!).

  3. Wskaźnik cierpliwości dyrektora marketingu sponsora (0–100%) reagujący na żywo na żądania finansowe gracza. Zweryfikuj przez `flutter analyze`.

- [ ] **Zadanie #196** (`lib/ui/screens/pre_season_team_presentation_screen.dart`): Stwórz uroczysty ekran Gali Prezentacji Zespołu przed startem nowego sezonu (styczeń) `PreSeasonTeamPresentationScreen`. Zaimplementuj:

  1. Scenografię sceny z reflektorami w kolorach zespołu, na której stoją trzej główni liderzy drużyny (`RiderAvatarWidget` w pełnej skali) obok nowego roweru wyścigowego (`BikePreviewWidget`) na nadchodzący sezon.

  2. Podsumowanie zmian kadrowych (kto dołączył do zespołu, kto odszedł, kto awansował z Akademii U23), prezentację głównych wyścigów docelowych poszczególnych liderów oraz zatwierdzenie ostatecznych numerów i ról na sezon.

  3. Przycisk "ROZPOCZNIJ SEZON WYŚCIGOWY", który generuje artykuł prasowy w mediach i przenosi gracza do kalendarza styczniowych wyścigów. Zweryfikuj przez `flutter analyze`.

- [ ] **Zadanie #197** (`lib/services/career/social_media_and_cycling_news_service.dart`): Aby świat gry tętnił życiem każdego dnia, stwórz serwis mediów kolarskich `SocialMediaAndCyclingNewsService` (wzorowany na portalach *Cyclingnews / ProCyclingStats / Velonews* oraz wpisach zawodników po wyścigach). Zaimplementuj:

  1. Generator codziennych artykułów i nagłówków prasowych po każdym rozegranym wyścigu na świecie: zapowiedzi faworytów przed etapem ("5 gwiazdek dla..."), relacje z ucieczek, komentarze po kraksach, plotki transferowe oraz wyliczenia ekspertów dotyczące watów i rekordów VAM na podjazdach.

  2. Krótkie wpisy społecznościowe samych kolarzy z załączonymi danymi z ich komputerów rowerowych (np. *"Ciężki dzień w deszczu na bruku. 340W Normalized Power przez 5 godzin, ale lider dowieziony bezpiecznie do mety! 🚴‍♂️🌧️"*).

  3. Integrację tego strumienia wiadomości z dedykowanym widgetem `CyclingNewsFeedWidget` w ekranie głównym `DashboardHqScreen`. Zweryfikuj przez `flutter analyze`.

- [ ] **Zadanie #198** (`lib/ui/widgets/pro_cycling_stats_table_widget.dart`): Stwórz komponent tabeli danych `ProCyclingStatsTableWidget` wzorowany na kultowym portalu *ProCyclingStats (PCS)*, używany do prezentacji wyników, list startowych i statystyk kolarzy. Zaimplementuj:

  1. Ultraczytelną, kompaktową tabelę o wysokim kontraście w ciemnym motywie: flaga kraju (rysowana wektorowo lub z kodu ISO), nazwisko pogrubione + imię, klikalna nazwa drużyny w jej kolorach, wiek, specjalizacja z kolorowym znacznikiem punktowym (zielony = sprint, czerwony = góry, niebieski = TT, pomarańczowy = bruk) oraz kolumny czasów/punktów.

  2. Błyskawiczne sortowanie po kliknięciu dowolnego nagłówka kolumny, pole wyszukiwania na żywo (Live Search Filter) oraz podświetlenie wierszy należących do kolarzy z drużyny gracza subtelnym złotym paskiem bocznym `#D4AF37`. Zweryfikuj przez `flutter analyze`.

- [ ] **Zadanie #199** (`lib/engine/physics/altitude_acclimatization_and_heat_engine.dart`): Stwórz precyzyjny silnik fizjologiczny aklimatyzacji wysokościowej i adaptacji cieplnej `AltitudeAcclimatizationAndHeatEngine`. Zaimplementuj:

  1. Model spadku wydolności tlenowej na dużej wysokości n.p.m.: powyżej $1500\text{ m n.p.m.}$ niezreklimatyzowany kolarz traci ok. $1.5\%$ swojego bazowego FTP na każde kolejne $300\text{ m}$ wysokości (na przełęczy $2700\text{ m n.p.m.}$ to aż $-6\%$ mocy!), podczas gdy kolarz po obozie wysokogórskim (`altitudeAcclimatizationScore` 0–100) lub urodzony na dużej wysokości (np. kolarze z Kolumbii / Ekwadoru) traci o połowę mniej!

  2. Model stresu cieplnego (`CoreBodyTemperatureCelsius`): podczas jazdy pod górę w upale $>32^\circ\text{C}$ przy niskiej prędkości powietrza chłodzącego temperatura głęboka ciała rośnie z $37.0^\circ\text{C}$ w stronę $39.5^\circ\text{C}$. Kolarze mogą używać "skarpet lodowych" (Ice Socks podawanych z wozu technicznego), aby schłodzić organizm i uchronić się przed przegrzaniem. Zweryfikuj przez `flutter analyze`.

- [ ] **Zadanie #200** (`lib/ui/widgets/rider_telemetry_sparklines_card.dart`): Stwórz zaawansowany komponent analityczny `RiderTelemetrySparklinesCard` wyświetlający mikro-wykresy na żywo (Sparklines) wewnątrz kart kolarzy podczas wyścigu 3D oraz w laboratorium. Zaimplementuj:

  1. Lekki `CustomPainter` rysujący płynną krzywą ostatnich 60 sekund generowanej mocy (z wypełnieniem gradientowym pod wykresem odpowiadającym aktualnej strefie mocy Z1–Z7) oraz nałożoną przerywaną linię tętna.

  2. Wizualny wskaźnik "Zapałek" (Matches Burned Counter): licznik pokazujący, ile razy podczas dzisiejszego etapu kolarz wykonał głęboki zryw beztlenowy powyżej $120\%$ FTP trwający dłużej niż 15 sekund. Każda "spalona zapałka" lekko obniża maksymalny sprint na finiszu! Zweryfikuj przez `flutter analyze`.

- [ ] **Zadanie #201** (`lib/ui/screens/race_3d_viewport_widget.dart` - Pełne Połączenie Silnika 3D): Zintegruj w pliku `lib/ui/screens/race_3d_viewport_widget.dart` natywny silnik `Peloton3dCanvasEngine` (#187), oświetlenie i niebo `DynamicSkyboxAndLightingPainter` (#186), fizykę omijania kolizji `BoidsSteeringCollisionAvoidance` (#184) oraz oprawę telewizyjną `BroadcastTvGraphicsOverlay` (#185). Zaimplementuj:

  1. Płynną pętlę renderowania `Ticker` / `AnimationController` odświeżającą scenę w 60/120 FPS z interpolacją pozycji pomiędzy kolejnymi tickami z `RaceSimulationNotifier`.

  2. Interaktywne wybieranie kolarzy na scenie 3D (Raycasting / Hit-testing współrzędnych ekranowych 2D wyliczonych podczas rzutowania 3D) – kliknięcie na kolarza w peletonie podświetla pod jego rowerem złoty pierścień taktyczny i otwiera jego kartę sterowania.

  3. Płynne przejścia kamer (Cinematic Camera Transitions) przy wykryciu kluczowego momentu przez `KeyMomentsDetector` (np. automatyczny najazd kamery z helikoptera na czoło peletonu, gdy rozpoczyna się atak w górach). Zweryfikuj przez `flutter analyze`.

- [ ] **Zadanie #202** (`lib/engine/audio/sound_effects_manager_provider.dart`): Stwórz centralny menedżer dźwięku i udźwiękowienia UI/3D `SoundEffectsManagerProvider` (oparty o `flutter_riverpod`), który łączy `ProceduralCyclingAudioEngine` (#117) oraz `RaceRadioTtsAndBeeps` (#118) z całą aplikacją. Zaimplementuj:

  1. Subtelne, nowoczesne dźwięki interfejsu (UI Haptics & Audio Feedback): ciche kliknięcie przy przełączaniu zakładek, dźwięk podpisania kontraktu, sygnał nowej wiadomości w skrzynce, dźwięk klucza dynamometrycznego w garażu rowerowym oraz dźwięk odliczania na rampie startowej TT (`Beep... Beep... BEEP!`).

  2. Osobne suwaki głośności w ustawieniach: `Głośność Ogólna (Master)`, `Otoczenie Wyścigu (Koła, Bębenek, Wiatr)`, `Kibice i Atmosfera`, `Radio Wyścigowe i Alarmy Garmin` oraz `Dźwięki Interfejsu`, z natychmiastowym zapisem preferencji. Zweryfikuj przez `flutter analyze`.

- [ ] **Zadanie #203** (`lib/core/localization/app_localizations_pl_en.dart`): Stwórz kompletny słownik i system lokalizacji językowej `AppLocalizationsPlEn` obsługujący natychmiastowe przełączanie języka gry pomiędzy **Językiem Polskim (PL)** (pełny, autentyczny żargon kolarski: *wachlarze, ranty, spłynięcie po bidony, noga dnia, pociąg sprinterski, koło w koło, odcięcie prądu, koszulka w grochy, klasyfikacja generalna*) a **Językiem Angielskim (EN)** (*echelons, crosswinds, sticky bottle, day condition, lead-out train, bonking, polka-dot jersey, GC*). Dodaj przełącznik języka `PL / EN` w `SettingsAndModScreen`. Zweryfikuj przez `flutter analyze`.

- [ ] **Zadanie #204** (`lib/services/career/autosave_and_crash_recovery_guard.dart`): Stwórz niezawodny strażnik integralności zapisu `AutosaveAndCrashRecoveryGuard`. Zaimplementuj:

  1. Atomowy zapis transakcyjny stanu kariery (zapis do pliku tymczasowego `.tmp`, weryfikacja sumy kontrolnej JSON i zamiana pliku głównego, co gwarantuje, że wyłączenie prądu lub zamknięcie okna gry nigdy nie uszkodzi zapisu kariery!).

  2. Automatyczny zapis stanu przed startem każdego etapu (`PreStageCheckpoint`), dzięki czemu w razie nieprzewidzianego zamknięcia aplikacji w trakcie wyścigu gracz może od razu wznowić grę dokładnie przed odprawą tego etapu. Zweryfikuj przez `flutter analyze`.

- [ ] **Zadanie #205** (`lib/models/model_serialization_audit.dart`): Przeprowadź kompleksowy audyt wszystkich modeli danych w katalogach `lib/models/rider/`, `lib/models/equipment/`, `lib/models/team/`, `lib/models/race/`, `lib/models/career/`. Stwórz pomocniczą klasę walidującą `ModelSerializationAudit`, która testuje w pętli serializację i deserializację (`fromJson(model.toJson())`) każdego modelu z wygenerowanego świata gry. Napraw w modelach wszelkie potencjalne błędy rzutowania typów (`int` vs `double` w JSON, listy `List<dynamic>`, obsługa `null` dla nowych pól dodanych w zadaniach #126–#199). Zweryfikuj przez `flutter analyze`.

- [ ] **Zadanie #206** (`lib/engine/engine_integration_bridge.dart`): Stwórz czysty most integracyjny `EngineIntegrationBridge`, który łączy wszystkie kalkulatory fizyki i fizjologii stworzone w obu fazach:

  * opór aero z uwzględnieniem `BikeFitConfiguration` (#130),

  * ciśnienie w oponach i stan wosku na łańcuchu (#132, #133),

  * aklimatyzację wysokościową i stres cieplny (#199),

  * dyspozycję dnia "Noga Dnia" (#189),

  * profil mleczanowy $LT_1/LT_2/VLaMax$ (#126),

  * osobowości taktyczne AI (#193) oraz omijanie kolizji Boids (#184)
    bezpośrednio z główną pętlą `StageSimulationLoop` (#038) oraz wątkiem `IsolateSimulationWorker` (#123). Upewnij się, że żaden kalkulator nie jest martwym kodem i każdy parametr wpływa na prędkość kolarza w wyścigu 3D! Zweryfikuj przez `flutter analyze`.

- [ ] **Zadanie #207** (`lib/ui/screens/pre_race_briefing_screen.dart` - Pełna Integracja Przedstartowa): Rozbuduj ekran `PreRaceBriefingScreen`, aby łączył w jednym płynnym procesie (Stepper 4-krokowy przed wyścigiem):

  1. Krok 1: Analiza Trasy, Pogody Górskiej (#151) i Rekonesansu (#140).

  2. Krok 2: Warsztat Mechaników (`MechanicWorkshopPanel` #134) – dobór rowerów, kół, opon, ciśnienia BAR/PSI oraz smarowania łańcucha na dzisiejszy etap z automatycznym przyciskiem `Zastosuj Optymalny Setup Mechanika`.

  3. Krok 3: Autobus Drużyny (`TeamBusLockerRoomScreen` #188) – sprawdzenie dyspozycji dnia kolarzy po rozgrzewce, mowy motywacyjnej i wyznaczenie ról (Lider, Ochroniarz, Uciekinier, Sprinterski Lead-out).

  4. Krok 4: Wielki przycisk `WYJAZD NA START HONOROWY (KM 0.0) -> WIDOK 3D`. Zweryfikuj przez `flutter analyze`.

- [ ] **Zadanie #208** (`lib/ui/screens/dashboard_hq_screen.dart` - Rozbudowa Centrum Dowodzenia): Zaktualizuj ekran główny `DashboardHqScreen`, wykorzystując nowe komponenty `CarbonFiberCard` (#190), `CyclingNewsFeedWidget` (#197) oraz `ProCyclingStatsTableWidget` (#198). Zaimplementuj na ekranie głównym:

  1. Interaktywny widżet Najbliższego Wyścigu z profilem trasy, składem i przyciskiem przejścia do odprawy.

  2. Pasek "Transfer Ticker" i "Cycling News" z najnowszymi wydarzeniami ze świata gry.

  3. Kafelek Stanu Liderów (forma TSB, morale, dni do szczytu formy) oraz Kafelek Zadowolenia Sponsora Tytularnego z postępem 3 głównych celów sezonowych.

  4. Kafelek Szybkich Akcji (np. `2 kolarzy czeka na przedłużenie kontraktu`, `Wyniki testów z Laboratorium gotowe`, `Dostępny rekonesans przed Monumentem`). Zweryfikuj przez `flutter analyze`.

- [ ] **Zadanie #209** (`test/physics_and_physiology_master_test.dart`): Napisz kompletny, rygorystyczny zestaw testów jednostkowych (`flutter_test`) weryfikujących całą matematykę gry:

  1. Test Równania Mocy: sprawdź prędkości dla górala ($58\text{ kg}, 370\text{ W}$) vs sprintera ($78\text{ kg}, 420\text{ W}$) na płaskim ($0\%$) oraz na ściance ($10\%$).

  2. Test Tunelu Aero i Ciśnienia: sprawdź, że obniżenie $CdA$ oraz dobór właściwego ciśnienia na bruku dają mierzalną przewagę czasową na dystansie $40\text{ km}$.

  3. Test Skiba $W'$, Glikogenu i Wysokości n.p.m.: sprawdź wyczerpanie $W'$ podczas ataku, spadek mocy na wysokości $2500\text{ m n.p.m.}$ oraz regenerację po podaniu żelu.
     Uruchom `flutter test test/physics_and_physiology_master_test.dart` w terminalu i upewnij się, że 100% testów przechodzi na zielono!

- [ ] **Zadanie #210** (`test/ui_screens_smoke_and_overflow_test.dart`): Napisz automatyczny test weryfikacji wizualnej i odporności na błędy układu (`WidgetTester` w `flutter_test`), który po kolei renderuje kluczowe ekrany gry (`MainTitleMenuScreen`, `DashboardHqScreen`, `SquadRosterScreen`, `BikeGarageRndScreen`, `WindTunnelAndBikeFitScreen`, `PhysiologyLabScreen`, `Race3dViewportWidget` z `RaceHudOverlay`) w dwóch rozdzielczościach testowych:

  * Desktop Windows (`1600x900`),

  * Smartfon (`390x844`).
    Test musi automatycznie przechwytywać błędy `FlutterError` i weryfikować, że na żadnym ekranie nie występuje `RenderFlex overflowed` ani błąd brakującego providera! Uruchom test w terminalu i napraw ewentualne przepełnienia w widgetach, aż test przejdzie w 100% na zielono.

- [ ] **Zadanie #211** (`pubspec.yaml` oraz `blender_scripts/build_all_assets_master.py` - Kompilacja Assetów 3D): Upewnij się, że w pliku `pubspec.yaml` wszystkie ścieżki do katalogów `assets/3d/bikes/`, `assets/3d/riders/`, `assets/3d/environment/` oraz `assets/textures/jerseys/` są poprawnie zadeklarowane. Następnie uruchom w terminalu komendę:
  `blender --background --python blender_scripts\build_all_assets_master.py`
  i zweryfikuj, że wszystkie modele `.glb` (od #086 do #182) oraz tekstury koszulek wygenerowały się na dysku i są wpisane w `assets/3d/asset_manifest.json`.

- [ ] **Zadanie #212** (`docs/CODE_MAP.md` - Pełny Audyt Kompilacji i Lintera): Wykonaj w terminalu komendy `flutter pub get`, `flutter analyze` oraz `flutter test`. Napraw wszelkie pozostałe ostrzeżenia (warnings/infos), nieużywane importy lub niezgodności typów w całym katalogu `lib/` oraz `test/`, tak aby `flutter analyze` zwracało `No issues found!`, a cały zestaw testów `flutter test` świecił w 100% na zielono. Zaktualizuj `docs/CODE_MAP.md` o wszystkie nowe klasy z zadań #163–#212 i wykonaj finalny commit paczki.