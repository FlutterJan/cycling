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
- `lib/core/localization/app_localizations_pl_en.dart` — Słownik i system lokalizacji PL/EN (`AppLocalizationsPlEn`, `AppLanguage`, `CyclingGlossaryEntry`, `AppLocalizationsScope`, `AppLocalizationsContext`) z pełnym żargonem kolarskim i natychmiastowym przełączaniem przez `appLocalizationsProvider`.
- `lib/core/router/app_router.dart` — Konfiguracja `GoRouter` i stałych `AppRoutes`.
- `lib/core/theme/app_colors.dart` — Paleta kolorów gry i stref mocy Z1–Z7.
- `lib/core/theme/app_theme.dart` — Ciemny motyw `ThemeData`, typografia `Inter` i style kart.
- `lib/core/utils/formatters.dart` — Formatery czasu, walut (`€`), watów, prędkości i dystansu.
- `lib/core/utils/performance_profiler_overlay.dart` — Nakładka diagnostyczna `PerformanceProfilerOverlay` (`F3`, FPS, Frame Time Graph, telemetria `PerformanceTelemetryRegistry` Isolate/LOD/RAM).
- `lib/core/utils/windows_desktop_window_config.dart` — Konfiguracja okna Desktop (`WindowsDesktopWindowConfig`, `DesktopResponsiveScaler`, `DesktopWindowStatusBar`, `DesktopWindowController`, `desktopWindowProvider`: skalowanie 720p–4K, `F11` pełny ekran, obciążenie fizyki Isolate, `Screenshot Mode` `F12`).

### `lib/models/`
- `lib/models/model_serialization_audit.dart` — Walidator serializacji JSON wszystkich modeli świata gry (`ModelSerializationAudit`, `ModelAuditReport`, `ModelAuditIssue`).
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
- `lib/engine/engine_integration_bridge.dart` — Centralny most integracyjny łączący BikeFit, ciśnienie opon, wosk łańcucha, wysokość/ciepło, dyspozycję dnia, LT1/LT2/VLaMax, AI i Boids z `StageSimulationLoop` i `IsolateSimulationWorker` (`EngineIntegrationBridge`, `EngineIntegrationRiderContext`, `EngineIntegrationStepOutput`, `RiderTirePressureSetup`).
- `lib/engine/audio/procedural_cycling_audio_engine.dart` — Synteza dźwięku wiatru, bębenka i tłumu.
- `lib/engine/audio/race_radio_tts_and_beeps.dart` — Sygnały radia wyścigowego i alarmy Garmin.
- `lib/engine/audio/sound_effects_manager_provider.dart` — Centralny menedżer dźwięku i haptyki UI/3D (`SoundEffectsManagerProvider`, `soundEffectsManagerProvider`, `UiSoundSynthesizer`, `UiSoundEffect`, `SoundEffectsState`) łączący #117, #118 i 5-kanałowy mikser z natychmiastowym zapisem.
- `lib/engine/audio/soundscape_mixer_controller.dart` — 5-kanałowy mikser pejzażu dźwiękowego (`SoundscapeMixerController`, `soundscapeMixerProvider`, `SoundscapeTelemetry`, `WindNoiseV2Generator`, `FreehubCoastingGenerator`, `RiderBreathingGenerator`, `CowbellAtmosphereGenerator`, `CrowdSurgeGenerator`).
- `lib/engine/events/race_incident_engine.dart` — Generator kraks, defektów i przebić opon.
- `lib/engine/events/race_radio_generator.dart` — Generator komunikatów dyrektora sportowego.
- `lib/engine/peloton/boids_steering_collision_avoidance.dart` — Silnik fizyki ruchu ciągłego 60 FPS bez kolizji (`BoidsSteeringCollisionAvoidance`, `BoidRiderState`, `BoidSteeringVectors`, `BoidsFrameResult`, `OvertakeLaneDirection`: separacja 1.85x0.65m, draft/wachlarz, wyprzedzanie 15m, efekt akordeonu).
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
- `lib/engine/physics/altitude_acclimatization_and_heat_engine.dart` — Silnik aklimatyzacji wysokościowej (>1500m, COL/ECU, obozy) i stresu cieplnego (`AltitudeAcclimatizationAndHeatEngine`, `RiderThermalState`, `AltitudePerformanceResult`, `HeatStrainStepResult`, `AltitudeAndHeatCombinedResult`, Ice Socks).
- `lib/engine/physics/bike_fit_and_wind_tunnel_engine.dart` — Symulacja tunelu aero i bike fittingu.
- `lib/engine/physics/day_condition_and_biorhythm_engine.dart` — Silnik dyspozycji dnia -5..+5 (`DayConditionAndBiorhythmEngine`, `DayConditionDrawInputs`, `DayConditionModifiers`, `RiderDayConditionState`): losowanie ważone (TSB, sen, pogoda, morale, lojalność), wpływ na FTP/W'/VO2max/regenerację oraz odkrywanie `?` powyżej LT1 na podjeździe.
- `lib/engine/physics/gravity_and_rolling_calculator.dart` — Siła grawitacji i opory toczenia CRR.
- `lib/engine/physics/heart_rate_simulator.dart` — Kinetyka tętna BPM w zależności od wysiłku.
- `lib/engine/physics/nutrition_and_glycogen_engine.dart` — Spalanie glikogenu, węglowodany i "odcięcie prądu".
- `lib/engine/physics/speed_solver.dart` — Solver prędkości m/s z mocy W i sił oporu.
- `lib/engine/physics/tire_pressure_calculator.dart` — Kalkulator optymalnego ciśnienia BAR/PSI.
- `lib/engine/physics/w_prime_balance_engine.dart` — Model Skiba W'bal (zużycie i regeneracja beztlenowa).
- `lib/engine/rendering3d/alpine_crowd_tunnel_renderer.dart` — Efekt "Tunelu Kibiców" 3D na stromych podjazdach >8% (`AlpineCrowdTunnelRenderer`, `AlpineCrowdTunnelConfig`, `AlpineCrowdTunnelZone`, `AlpineCrowdTunnelSpectator3D`, `AlpineCrowdTunnelTelemetry`, `AlpineCrowdTunnelControlPanel`, `CrowdTunnelNationJersey`, `CrowdTunnelFlareColor`: koszulki narodowe, flagi, dym z flar pomarańczowy/czerwony, korytarz 2.8m i odsuwanie przed kołem lidera).
- `lib/engine/rendering3d/boids_peloton_flocking_solver.dart` — Solver unikania kolizji i ruchu 176 kolarzy 3D (`BoidsPelotonFlockingSolver`, `BoidsFlockingConfig`, `PelotonBoidAgent`, `BoidsFlockingStepResult`, `BoidFlockingForceBreakdown`, `FlockingForceVector`: `Separation` ≥0.45 m, `Alignment`, `DraftSeeking` CdA, `OvertakeLaneShift` Δv>0.8 m/s).
- `lib/engine/rendering3d/broadcast_tv_graphics_overlay.dart` — Nakładka grafik TV Eurosport/TDF (`BroadcastTvGraphicsOverlay`, `BroadcastRiderSpotlightData`, `BroadcastClimbTelemetryData`, `BroadcastLiveSplitData`: belka kolarza `#D4AF37`, profil podjazdu z VAM, stoper do setnych z Top 5).
- `lib/engine/rendering3d/camera_rig_controller.dart` — Kamery wyścigowe (helikopter, moto, tył, pierwsza osoba).
- `lib/engine/rendering3d/cobblestone_vibration_camera_fx.dart` — Efekt drgań kamery i kierownicy na sektorach bruku 1★–5★ (`CobblestoneVibrationCameraFx`, `CobblestoneSectorDifficulty`, `CobblestoneDustAndChatterPainter`, `CobblestoneVibrationControlPanel`: mikro-wstrząsy 18–42 Hz, chmura kurzu nad peletonem i rozciąganie w pojedynczy wężyk na koronie bruku).
- `lib/engine/rendering3d/crash_and_mechanical_visuals.dart` — Wizualizacja kraks i defektów na trasie 3D.
- `lib/engine/rendering3d/cyclist_3d_pose_animator.dart` — Animacja kadencji, jazdy na stojąco i aero tuck.
- `lib/engine/rendering3d/dynamic_skybox_and_lighting_painter.dart` — Renderer nieba, słońca/Golden Hour/latarni, burz z błyskami, cieni rzucanych (`ProjectedShadowResult`) i mokrego asfaltu (`DynamicSkyboxAndLightingPainter`, `StageTimeOfDay`, `SunLightState`).
- `lib/engine/rendering3d/environment_scenery_spawner.dart` — Proceduralne drzewa, skały, budynki i kibice.
- `lib/engine/rendering3d/glb_asset_loader_service.dart` — Ładowanie i cache modeli `.glb`.
- `lib/engine/rendering3d/glb_mesh_integrity_validator.dart` — Automatyczny walidator startowy plików `.glb` (`GlbMeshIntegrityValidator`, `GlbIntegrityValidationReport`, `GlbMeshIntegrityNotifier`, `GlbMeshIntegrityStatusPanel`) z generacją brakujących/uszkodzonych siatek w RAM.
- `lib/engine/rendering3d/inverse_kinematics_limb_solver.dart` — Dwustawowy analityczny solver IK 3D nóg i rąk (`InverseKinematicsLimbSolver`, `IkGripType`, `LimbIkGeometryConfig`, `LimbIkFrameInput`, `LimbIkFrameResult`, `SolvedTwoBoneLimb`: kolana, kostki, korba 165–175 mm, łokcie w chwytach `Tops`/`Hoods`/`Drops`/`AeroTuck`).
- `lib/engine/rendering3d/neutral_service_and_medical_cars.dart` — Kontroler i renderer 3D żółtych/niebieskich aut neutralnego serwisu z rowerami na dachu, ambulansu oraz wozów `Commissaire Car` z czerwonym dachem (`NeutralServiceAndMedicalCarsController`, `NeutralAndMedicalVehicle3D`, `RaceConvoyVehicleRole`, `ConvoyPlacementZone`, `RaceConvoyGroupMetrics`, `NeutralAndMedicalCarsConfig`).
- `lib/engine/rendering3d/on_bike_computer_hud_widget.dart` — Licznik na kierownicy w widoku FPP.
- `lib/engine/rendering3d/peloton_instanced_renderer.dart` — Rysowanie 176 kolarzy z LOD i sortowaniem Z.
- `lib/engine/rendering3d/peloton_3d_canvas_engine.dart` — Natywny silnik renderowania 3D 120 FPS na Canvasie (`Peloton3dCanvasEngine`, `Peloton3dCanvasPainter`, `Peloton3dViewportWidget`, `WheelProfileType`, `LeaderJerseyType`) z rzutowaniem `vector_math_64`, drogą/brukiem/drzewami/skałami/bramami, kolarzami 3D i integracją kamer + Boids (#184).
- `lib/engine/rendering3d/photo_finish_replay_widget.dart` — Kamera fotofiniszu na mecie.
- `lib/engine/rendering3d/procedural_pbr_texture_atlas_generator.dart` — Generator proceduralnego atlasu tekstur PBR w pamięci RAM (`ProceduralPbrTextureAtlasGenerator`, `PbrTextureAtlasMaps`, `PbrGpuTextureAtlas`, `PbrMaterialSpec`, `PbrUvRegion`, `PbrTextureAtlasInspectorPanel`: splot 3K/UD, metaliczny lakier, opony Tan-Wall i asfalt bez plików PNG).
- `lib/engine/rendering3d/projected_planar_shadows_painter.dart` — Miękkie cienie planarne na asfalcie (`ProjectedPlanarShadowsPainter`, `SlopeExposureProfile`, `PlanarSunProjectionState`, `PlanarShadowRiderInput`, `PlanarShadowTreeInput`, `PlanarShadowGateInput`) dla kolarzy, rowerów, drzew i bram (11:00–17:30 + ekspozycja zbocza).
- `lib/engine/rendering3d/rider_floating_labels_overlay.dart` — Pływające etykiety nad kolarzami w 3D.
- `lib/engine/rendering3d/road_furniture_3d_renderer.dart` — Brama km, barierki, znaki i reklamy przy trasie.
- `lib/engine/rendering3d/road_ribbon_mesh_builder.dart` — Budowa wstęgi asfaltu, bruku i zakrętów 3D.
- `lib/engine/rendering3d/roadside_banners_and_arches_renderer.dart` — Renderer 3D dmuchanych bram (`Start`, `Sprint Intermédiaire`, `Col / KOM`, `Flamme Rouge 1 km`) oraz barierek ochronnych z banerami sponsorów z `FictionalBrandsCatalog` (`RoadsideBannersAndArchesRenderer`, `InflatableArchType`, `RoadsideSponsorBanner`, `RoadsideArchInstance3D`, `RoadsideBarrierInstance3D`).
- `lib/engine/rendering3d/scene_3d_math_projection.dart` — Macierze rzutowania 3D->2D i geometria kamery.
- `lib/engine/rendering3d/support_vehicles_3d_renderer.dart` — Samochody techniczne, motocykle kamerzystów i helikopter.
- `lib/engine/rendering3d/tv_helicopter_sky_renderer.dart` — Renderer 3D helikoptera telewizyjnego krążącego nad czołem wyścigu (`TvHelicopterSkyRenderer`, `TvHelicopterSkyPainter`, `TvHelicopterTelemetryControlPanel`, `TvHelicopterFlightMode`, `TvHelicopterState`, `HelicopterRoadShadowGeometry`, `HelicopterTreeSwayDisplacement`: obracający się wirnik, kamera żyroskopowa Cineflex na dziobie, cień na szosie i podmuch wiatru poruszający korony drzew).
- `lib/engine/rendering3d/weather_particles_renderer.dart` — Cząsteczki deszczu, śniegu i kurzu.
- `lib/engine/rendering3d/wet_asphalt_reflections_painter.dart` — Painter mokrego asfaltu (`WetAsphaltReflectionsPainter`, `WetAsphaltSurfaceState`, `WetAsphaltPuddle`, `PelotonTireRutTracker`, `WetAsphaltReflectionsControlPanel`): ciemniejsza nawierzchnia, kałuże z falami, lustrzane odbicia sylwetek/koszulek kolarzy i suche koleiny peletonu.
- `lib/engine/rendering3d/wheel_and_drivetrain_rotator.dart` — Animacja mechaniczna kół z motion blur (>40 km/h), tarczy korby wg RPM oraz wózka tylnej przerzutki wg przełożenia (`WheelAndDrivetrainRotator`, `DrivetrainConfig`, `DrivetrainGearSelection`, `WheelMotionBlurProfile`, `RearDerailleurKinematics`, `WheelAndDrivetrainFrameState`).
- `lib/engine/rendering3d/wind_streamlines_visualizer.dart` — Linie strug wiatru w trybie taktycznym/tunelu.
- `lib/engine/simulation/isolate_simulation_worker.dart` — Wątek Isolate wykonujący ticki fizyki w tle.
- `lib/engine/simulation/key_moments_detector.dart` — Wykrywanie kluczowych momentów (ataki, kraksy, premie).
- `lib/engine/simulation/post_stage_recovery_processor.dart` — Przeliczanie zmęczenia i formy po etapie.
- `lib/engine/simulation/stage_replay_recorder.dart` — Zapis powtórki etapu i osi czasu.
- `lib/engine/simulation/stage_results_calculator.dart` — Klasyfikacja etapu, GC, górska, punktowa i młodzieżowa.
- `lib/engine/simulation/stage_simulation_loop.dart` — Główna pętla symulacji etapu.
- `lib/engine/simulation/tactical_ai_personality_profiles.dart` — System osobowości taktycznych AI (`TacticalAiPersonalityProfiles`, `CannibalAttacker`, `DieselCalculator`, `WheelsuckerOpportunist`, `KamikazeDescender`, `BreakawayHunter`, `LoyalRoadCaptain`).
- `lib/engine/simulation/time_trial_simulation_engine.dart` — Silnik jazdy indywidualnej i drużynowej na czas (ITT/TTT).
- `lib/engine/weather/dynamic_mountain_weather_engine.dart` — Pogoda zależna od wysokości n.p.m. i godziny.

### `lib/services/`
- `lib/services/career/achievement_and_milestones_service.dart` — Serwis 45 osiągnięć i kamieni milowych (`AchievementAndMilestonesService`, `AchievementTier`, `AchievementUnlockEvent`, `StageEvaluationContext`, `SeasonEvaluationContext`).
- `lib/services/career/ai_team_transfer_simulation_service.dart` — Symulacja rynku transferowego AI (`AiTeamTransferSimulationService`, `TeamRosterNeedsAnalyzer`, `TransferNewsItem`).
- `lib/services/career/anti_doping_and_whereabouts_service.dart` — Kontrole antydopingowe i paszport biologiczny.
- `lib/services/career/autosave_and_crash_recovery_guard.dart` — Atomowy zapis transakcyjny (`.tmp` + suma kontrolna `fnv1a64+crc32` + `.bak`) i punkty kontrolne `PreStageCheckpoint` (`AutosaveAndCrashRecoveryGuard`, `AutosaveGuardNotifier`, `SaveRecoveryResult`, `TransactionalSaveReceipt`, `autosaveGuardStateProvider`).
- `lib/services/career/bike_manufacturer_negotiation_service.dart` — Negocjacje kontraktów z producentami rowerów.
- `lib/services/career/development_team_u23_service.dart` — Zarządzanie drużyną młodzieżową U23.
- `lib/services/career/email_inbox_generator_service.dart` — Generator wiadomości w skrzynce menedżera.
- `lib/services/career/equipment_sponsorship_bidding_engine.dart` — Przetargi i oferty sponsorów sprzętowych.
- `lib/services/career/finance_and_budget_service.dart` — Przepływy finansowe, pensje i nagrody wyścigowe.
- `lib/services/career/historical_records_and_palmares_service.dart` — Rekordy historyczne, Hall of Fame i palmares.
- `lib/services/career/medical_post_race_trauma_report.dart` — Generator raportów medycznych RTG/MRI po kraksach (`MedicalPostRaceTraumaReport`, `RiderTraumaCaseReport`, `DiagnosticImagingResult`, `TraumaDiagnosisCategory`, `RaceClearanceDecision`: stłuczenia, szlify "road rash" -25% regeneracji nocnej, złamania obojczyka/nadgarstka DNF/DNS).
- `lib/services/career/national_championships_and_worlds_service.dart` — Mistrzostwa Krajowe i Mistrzostwa Świata UCI.
- `lib/services/career/physiology_lab_testing_service.dart` — Badania wydolnościowe VO2max i krzywej mleczanowej.
- `lib/services/career/post_race_equipment_degradation_service.dart` — Serwis zużycia sprzętu po etapie (`PostRaceEquipmentDegradationService`, `PostRaceSparePartsBudgetReport`, `BikePostRaceDegradationReport`, `CassetteAndBearingWear`, `RiderBikeStageUsage`, `SparePartCategory`: łańcuch, kaseta, opony, łożyska 3x w deszczu i na bruku oraz raport kosztów części dla budżetu).
- `lib/services/career/post_stage_morale_and_ego_updater.dart` — Procesor nastrojów i ego po etapie (`PostStageMoraleAndEgoUpdater`, `PostStageMoraleContext`, `PostStageMoraleUpdateReport`, `RiderMoraleAndEgoDelta`, `PostStageMoraleEventType`: wzrost morale całej ekipy po zwycięstwie/koszulce lidera, spadek przy braku ochrony lidera na wietrze oraz frustracja sprintera bez pociągu na płaskim finiszu).
- `lib/services/career/press_conference_service.dart` — Wywiady prasowe przed/po etapach i wpływ na morale.
- `lib/services/career/prize_money_distribution_service.dart` — Serwis podziału nagród finansowych (`PrizeMoneyDistributionService`, `PrizeMoneyDistributionPolicy`, `PrizeMoneyDistributionPreset`, `PrizeMoneyPoolInput`, `PrizeMoneyDistributionResult`, `SeasonPrizeMoneyLedgerSummary`): podział puli (np. 500 000 EUR w GT) na klub, zwycięzcę, równy podział dla `domestiques` oraz premię sztabu.
- `lib/services/career/race_calendar_selection_service.dart` — Zgłaszanie składów i dzikie karty na wyścigi.
- `lib/services/career/race_day_pipeline_orchestrator.dart` — Orkiestrator dnia wyścigowego (`RaceDayPipelineOrchestrator`, `RaceDayPipelineNotifier`, `raceDayPipelineProvider`, `RaceDayPipelinePhase`) łączący Calendar → PreRaceBriefing → Symulację 3D → StageResultsCalculator → Podium → SponsorObjectivesEvaluator → RecoveryProcessor → AutoSave.
- `lib/services/career/race_reconnaissance_service.dart` — Rekonesans tras i premia taktyczna.
- `lib/services/career/rider_ego_and_conflicts_service.dart` — Konflikty w zespole, ego liderów i lojalność.
- `lib/services/career/roster_uci_compliance_validator.dart` — Walidator przepisów UCI dla składów i sprzętu (`RosterUciComplianceValidator`, `RosterUciComplianceReport`, `BikeComplianceCheckResult`, `RosterAutoFillAction`: limit 8/7 kolarzy, zawieszenia medyczne/dopingowe, rowery >= 6.80 kg i auto-uzupełnianie rezerwami).
- `lib/services/career/scouting_and_youth_academy_service.dart` — Skauting talentów na świecie i akademia.
- `lib/services/career/season_transition_service.dart` — Przejście między sezonami, emerytury i nowi juniorzy.
- `lib/services/career/social_media_and_cycling_news_service.dart` — Serwis mediów kolarskich i social kolarzy (`SocialMediaAndCyclingNewsService`, `CyclingNewsItem`, `BikeComputerRideSnapshot`, `CyclingNewsStarPick`: zapowiedzi 5★, ucieczki, kraksy, plotki, W/kg i VAM).
- `lib/services/career/sponsor_negotiation_service.dart` — Negocjacje ze sponsorami tytularnymi.
- `lib/services/career/sponsor_objectives_evaluator.dart` — Ewaluacja celów sponsorskich po wyścigu i wypłata bonusów.
- `lib/services/career/team_chemistry_and_builder_service.dart` — Chemia drużyny i hierarchia liderów.
- `lib/services/career/training_and_camps_service.dart` — Zgrupowania wysokogórskie i plany treningowe.
- `lib/services/career/transfer_market_service.dart` — Rynek transferowy kolarzy i wolni agenci.
- `lib/services/career/uci_points_live_ledger_service.dart` — Księga punktów UCI na żywo (`UciPointsLiveLedgerService`, `UciPointsLedgerState`, `UciLedgerEntry`, `UciIndividualRankingEntry`, `UciLiveLedgerBatchResult`, `UciPointAwardSource`) dla miejsc 1–60 w klasykach, etapów, GC i dni w koszulce lidera z natychmiastową aktualizacją rankingu indywidualnego i 3-letniego cyklu licencyjnego.
- `lib/services/career/uci_promotion_relegation_cycle_service.dart` — 3-letni cykl licencyjny WorldTour i walka o utrzymanie.
- `lib/services/career/winter_offseason_training_service.dart` — Przygotowania zimowe i testy przedsezonowe.
- `lib/services/database/custom_mod_importer_service.dart` — Import modów JSON (bazy danych, drużyny, wyścigi).
- `lib/services/database/demo_save_preset_builder.dart` — Builder 4 scenariuszy szybkiego startu kariery (`DemoSavePresetBuilder`, `DemoSavePresetType`, `DemoSavePresetInfo`: Polski Projekt WT, Pojedynek Tytanów w Alpach, Kampania Brukowana, Imperium Galaktyczne).
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
- `lib/ui/screens/dashboard_hq_screen.dart` — Centrum dowodzenia HQ (`DashboardHqScreen`, `CarbonFiberCard` #190, `CyclingNewsFeedWidget` #197, `ProCyclingStatsTableWidget` #198, Transfer Ticker, Najbliższy Wyścig ze składem/odprawą, Stan Liderów TSB/Morale/Szczyt, Sponsor Tytularny 3 cele, Szybkie Akcje HQ).
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
- `lib/ui/screens/pre_race_briefing_screen.dart` — 4-krokowy Stepper Odprawy Przedstartowej (`PreRaceBriefingScreen`, `StageTacticalRole`, `StageBikePreset`): Trasa/Pogoda Górska (#151)/Rekonesans (#140), `MechanicWorkshopPanel` (#134) z `Zastosuj Optymalny Setup Mechanika`, `TeamBusLockerRoomScreen` (#188) z rolami taktycznymi oraz start KM 0.0 -> Widok 3D.
- `lib/ui/screens/pre_season_team_presentation_screen.dart` — Gala Prezentacji Zespołu przed sezonem (`PreSeasonTeamPresentationScreen`, `SeasonLeaderRole`, `RosterMovementEntry`, `_GalaStageSpotlightPainter`): scena z reflektorami, 3 liderów, rower, zmiany kadrowe, numery/role i start sezonu.
- `lib/ui/screens/quick_race_sandbox_screen.dart` — Szybki Wyścig / Laboratorium Taktyczne Sandbox 3D (`QuickRaceSandboxScreen`, `QuickRacePresetType`, `SandboxWeatherPreset`, `SandboxBikePreset`): 3-kolumnowy Bento Grid (trasa/wiatr 0–70 km/h, `Auto-Pick Optimal Roster`, presety sprzętowe -> 3D).
- `lib/ui/screens/race_3d_viewport_widget.dart` — Główny viewport 3D wyścigu (`Race3DViewportWidget`, `ViewportCameraMode`, `_AtmosphericOverlayPainter`) integrujący `Peloton3dCanvasEngine`, `DynamicSkyboxAndLightingPainter`, `BoidsSteeringCollisionAvoidance`, `BroadcastTvGraphicsOverlay`, raycasting ze złotym pierścieniem `#D4AF37` i filmowe przejścia kamer `KeyMomentsDetector`.
- `lib/ui/screens/race_hud_overlay.dart` — Warstwa HUD 3D w stylu ASO Broadcast / Zwift (`RaceHudOverlay`, 8 kart kolarzy, Flamme Rouge, `GroupGapsChalkboardWidget`, `OnBikeComputerHudWidget`, `TacticalMinimap2dWidget`, `RiderEffortSliderControl`, `TeamTacticalPresetsBar`, Aero Vision Mode).
- `lib/ui/screens/race_simulation_screen.dart` — Ekran wyścigu łączący 3D viewport, HUD i kontrolki.
- `lib/ui/screens/rider_detail_screen.dart` — Szczegółowy profil kolarza i statystyki.
- `lib/ui/screens/settings_and_mod_screen.dart` — Ustawienia gry i import modów.
- `lib/ui/screens/sponsor_pitch_deck_negotiation_modal.dart` — Interaktywne okno negocjacji ze sponsorem tytularnym (`SponsorPitchDeckNegotiationModal`, `TeamBibShortsPainter`, `PitchDeckMediaForecast`, `PitchNegotiationStatus`) z podglądem stroju, Media Value Index, 3 rundami suwaków/celów i wskaźnikiem cierpliwości.
- `lib/ui/screens/sponsors_and_finance_screen.dart` — Zarządzanie sponsorami i budżetem.
- `lib/ui/screens/squad_roster_screen.dart` — Lista składu drużyny z filtrami i statystykami.
- `lib/ui/screens/staff_management_screen.dart` — Zatrudnianie i zarządzanie personelem.
- `lib/ui/screens/stage_editor_creator_screen.dart` — Kreator własnych etapów i profili.
- `lib/ui/screens/strava_style_stage_analysis_screen.dart` — Analiza telemetryczna po etapie w stylu Strava.
- `lib/ui/screens/team_builder_hierarchy_screen.dart` — Hierarchia liderów i pociągi sprinterskie.
- `lib/ui/screens/team_bus_locker_room_screen.dart` — Wnętrze Autobusu Drużyny przed startem (`TeamBusLockerRoomScreen`, `TeamBusInteriorPainter`, `DirectorSpeechOption`, `TeamBusRiderSlot`, `TeamBusBriefingResult`).
- `lib/ui/screens/training_and_camps_screen.dart` — Obozy treningowe i plany obciążeń.
- `lib/ui/screens/transfer_market_scouting_screen.dart` — Rynek transferowy i negocjacje.
- `lib/ui/screens/wind_tunnel_and_bike_fit_screen.dart` — Tunel aerodynamiczny i bike fitting.

### `lib/ui/widgets/`
- `lib/ui/widgets/achievement_unlock_toast_overlay.dart` — Animowany baner odblokowania osiągnięcia (`AchievementUnlockToastOverlay`, `AchievementTrophyToastBanner`) ze złotym blaskiem `#D4AF37`.
- `lib/ui/widgets/animated_watt_bomb_effect.dart` — Efekt pulsującego impulsu ataku powyżej 12 W/kg / 1400W.
- `lib/ui/widgets/bike_preview_painter.dart` — Wektorowy podgląd roweru drużynowego.
- `lib/ui/widgets/career_onboarding_interactive_tour.dart` — Nieinwazyjny 5-krokowy samouczek nowego gracza (`CareerOnboardingInteractiveTour`, `CareerOnboardingTourNotifier`, `careerOnboardingTourProvider`, `OnboardingTourStep`, `OnboardingHighlightTarget`) podświetlający biuro menedżera, budowanie pociągu, ciśnienie opon i sterowanie 3D z opcją zwinięcia i pominięcia.
- `lib/ui/widgets/contract_negotiation_chat_simulator.dart` — Interaktywny symulator negocjacji kontraktowych na żywo z agentem kolarza (`ContractNegotiationChatSimulator`, `ContractOfferTerms`, `NegotiationChatMessage`, `BargainingChipType`, `ContractNegotiationOutcome`, `ContractNegotiationStatus`): pasek cierpliwości agenta, kontroferty w czasie rzeczywistym i karty przetargowe (Tour de France, pociąg sprinterski, premia za zwycięstwo).
- `lib/ui/widgets/custom_carbon_and_glass_containers.dart` — Luksusowe kontenery UI (`CustomCarbonAndGlassContainers`, `CarbonFiberCard` 3K 45°, `GlassmorphicHudPanel` blur 14px + szum, `AnimatedStatBadge` z `TweenAnimationBuilder`).
- `lib/ui/widgets/cycling_news_feed_widget.dart` — Strumień mediów kolarskich i wpisów kolarzy z licznikami (`CyclingNewsFeedWidget`, `CyclingNewsFilter`, filtry kategorii/ekipy, typy 5★, telemetria NP/W/kg/VAM).
- `lib/ui/widgets/custom_jersey_painter.dart` — Rysowanie wzoru koszulki i spodenek (`CustomPainter`).
- `lib/ui/widgets/custom_race_route_elevation_brush.dart` — Pędzel rzeźbienia terenu w Kreatorze Etapów (`CustomRaceRouteElevationBrush`, `ClimbCategoryCalculator`, `ElevationBrushMode`, `DetectedClimbSummary`) z rysowaniem profilu wysokościowego myszą/palcem oraz automatycznym wyliczaniem kategorii podjazdów (Cat 4–HC) i nachylenia %.
- `lib/ui/widgets/custom_ jersey_painter.dart` — Duplikat historyczny (nie modyfikować bez potrzeby).
- `lib/ui/widgets/elevation_profile_chart.dart` — Interaktywny profil wysokościowy etapu.
- `lib/ui/widgets/global_search_spotlight_modal.dart` — Globalna wyszukiwarka Spotlight `Ctrl+K` (`GlobalSearchSpotlightModal`, `SpotlightSearchIndex`, `SpotlightSearchCategory`, `SpotlightSearchItem`, `SpotlightClimbEntry`) dla 800+ kolarzy, 53 drużyn, wyścigów i podjazdów z podglądem i przejściem do profilu.
- `lib/ui/widgets/group_gaps_chalkboard_widget.dart` — Tablica różnic czasowych między grupami.
- `lib/ui/widgets/interactive_stage_timeline_scrubber.dart` — Interaktywna oś czasu wyścigu nad profilem (`InteractiveStageTimelineScrubber`, `StageProfileWithTimelineScrubber`, `StageTimelineEvent`, `StageTimelineEventType`, `StageGcGapSnapshot`) z markerami wydarzeń, tooltipami i analizą GC.
- `lib/ui/widgets/keyboard_shortcuts_manager.dart` — System skrótów klawiszowych (`KeyboardShortcutsManager`, `ShortcutsCheatSheetOverlay`, `ShortcutKeycap`) dla 3D i Menedżera.
- `lib/ui/widgets/key_moment_overlay.dart` — Powiadomienie i najazd na kluczowy moment wyścigu.
- `lib/ui/widgets/live_tv_commentary_ticker.dart` — Pasek komentarza TV na żywo (`LiveTvCommentaryTicker`, `LiveTvCommentaryGenerator`, `TvCommentaryInputEvent`, `TvCommentaryLine`, `TvCommentaryTriggerType`) z dwoma komentatorami reagującymi na ataki >10 W/kg, ranty, kraksy, bufet i Virtual GC.
- `lib/ui/widgets/live_virtual_standings_drawer.dart` — Wysuwana tabela wirtualnej klasyfikacji GC na żywo.
- `lib/ui/widgets/mechanic_workshop_panel.dart` — Panel warsztatu mechaników (ciśnienie opon, wosk, koła).
- `lib/ui/widgets/peloton_heatmap_position_widget.dart` — Taktyczna siatka ciepła pozycji w peletonie z lotu ptaka.
- `lib/ui/widgets/podium_3d_ceremony_painter.dart` — Animowana ceremonia podium 3D (`Podium3dCeremonyPainter`, `Podium3dCeremonyWidget`, `PodiumLeaderJerseyType`, `PodiumCeremonyRaceTheme`, `PodiumRiderEntry`, `PodiumNationalAnthemProfile`): 3 stopnie 3D, koszulki lidera (Żółta/Zielona/Grochy/Biała), konfetti, flesze fotoreporterów i hymn zwycięzcy.
- `lib/ui/widgets/power_curve_chart_widget.dart` — Wykres krzywej mocy W / W/kg.
- `lib/ui/widgets/press_interview_modal.dart` — Modal wywiadu z dziennikarzami.
- `lib/ui/widgets/pro_cycling_stats_table_widget.dart` — Tabela danych w stylu ProCyclingStats (`ProCyclingStatsTableWidget`, `PcsRiderRowData`, `PcsCountryFlagBadge`, `PcsTableMode`, `PcsSortColumn`, `PcsSpecializationCategory`) z wektorowymi flagami ISO, sortowaniem, filtrem na żywo i złotym paskiem drużyny gracza `#D4AF37`.
- `lib/ui/widgets/race_radio_banner.dart` — Pasek komunikatów radia wyścigowego.
- `lib/ui/widgets/race_top_hud_bar.dart` — Górny pasek HUD (km, prędkość, wiatr, pogoda).
- `lib/ui/widgets/rainbow_and_national_jersey_badge.dart` — Oznaczenia Tęczowej Koszulki i Mistrzów Krajowych.
- `lib/ui/widgets/rider_avatar_painter.dart` — Proceduralny portret kolarza w kasku i okularach.
- `lib/ui/widgets/rider_comparison_side_by_side_modal.dart` — Modal porównania 2–3 kolarzy obok siebie (`RiderComparisonSideBySideModal`).
- `lib/ui/widgets/rider_effort_slider_control.dart` — Suwak wysiłku i rozkazów taktycznych kolarza.
- `lib/ui/widgets/rider_fatigue_body_heatmap_painter.dart` — Anatomiczny diagram zmęczenia mięśniowego i CNS kolarza (`RiderFatigueBodyHeatmapPainter`, `RiderFatigueBodyHeatmapWidget`, `RiderMuscleFatigueProfile`, `BodyFatigueGroup`, `FatigueSeverityLevel`: czworogłowe, łydki, pośladki, lędźwie, CNS w skali zielony–ciemnoczerwony).
- `lib/ui/widgets/rider_telemetry_hud.dart` — Karta telemetrii kolarza na żywo (W, BPM, W', glikogen).
- `lib/ui/widgets/rider_telemetry_sparklines_card.dart` — Karta Sparklines 60s mocy (gradient Z1–Z7) + przerywane tętno i licznik spalonych zapałek (`RiderTelemetrySparklinesCard`, `RiderTelemetrySparklinePainter`, `MatchesBurnedCalculator`).
- `lib/ui/widgets/save_load_slots_modal.dart` — Okno zarządzania zapisami gry (`SaveLoadSlotsModal`, `TeamCrestPainter`, `SaveSlotEnrichedInfo`, `SaveLoadModalMode`, `SaveLoadModalResult`) dla 5 slotów ręcznych + `Auto-Save` z eksportem/importem `.json`.
- `lib/ui/widgets/season_calendar_gantt_timeline.dart` — Poziomy wykres Gantta sezonu (`SeasonCalendarGanttTimeline`, `GanttRiderScheduleRow`, `GanttTimelineBlock`, `GanttPeakFormWindow`) dla wszystkich 28 kolarzy (STY–PAŹ), obozów wysokogórskich, Peak 1/2 i wykrywania kolizji wyścigów.
- `lib/ui/widgets/tactical_minimap_2d_widget.dart` — Minimapa 2D trasy i pozycji grup.
- `lib/ui/widgets/tactical_radial_command_menu.dart` — Kołowe menu rozkazów taktycznych 3D (`TacticalRadialCommandMenu`, `TacticalRadialCommandType`): 8 wycinków (Atakuj, Pozycja, Zmiana, Na Kole, Chroń, Żel, Bidony, Grupetto) z animacją sprężynową 200ms, obsługą klawiatury i pełną responsywnością.
- `lib/ui/widgets/team_budget_cashflow_projection_chart.dart` — 12-miesięczny wykres przepływów pieniężnych drużyny (`TeamBudgetCashflowProjectionChart`, `MonthlyCashflowProjectionPoint`, `TeamCashflowProjectionSummary`, `TeamCashflowProjectionCalculator`): transze sponsorów, wypłaty pensji, koszty obozów, prognozowane saldo końcowe i ostrzeżenie o deficycie.
- `lib/ui/widgets/team_tactical_presets_bar.dart` — Szybkie presety taktyczne dla całej drużyny.
- `lib/ui/widgets/tutorial_coach_marks_overlay.dart` — Interaktywny samouczek wyścigowy (`TutorialCoachMarksOverlay`, `TutorialAcademyStep`, `TutorialTargetZone`) w estetyce ciemnego szkła ze strzałkami wektorowymi.
- `lib/ui/widgets/tv_broadcast_lower_third_banner.dart` — Telewizyjna belka dolna w stylu Tour de France (`TvBroadcastLowerThirdBanner`, `TvBroadcastLowerThirdData`, `TvBroadcastBannerStyle`: warianty złoto-czarny i bordowo-złoty, waty/W/kg, tętno, prędkość, strata/przewaga GC, pełne stany interakcji i responsywność).
- `lib/ui/widgets/tv_climb_gradient_3d_ribbon_hud.dart` — Telewizyjny profil podjazdu 3D w rogu ekranu (`TvClimbGradient3dRibbonHud`, `TvClimbGradient3dRibbonData`, `ClimbKilometerSegment`, `ClimbGradientDifficultyBand`: trójwymiarowe słupki km wg nachylenia 4–6% żółty / 7–9% pomarańczowy / 10–12% czerwony / >12% czarny oraz średnie VAM lidera).
- `lib/ui/widgets/tv_echelon_crosswind_radar_hud.dart` — Telewizyjny radar wiatru bocznego (`TvEchelonCrosswindRadarHud`, `TvEchelonCrosswindRadarData`, `EchelonSplitRowData`, `EchelonRiskLevel`: animowana róża wiatrów z kątem natarcia na szosę, alert `CROSSWIND ZONE — ECHELON RISK HIGH` oraz schemat podziału peletonu na ranty nr 1, 2 i 3 ze stratami sekundowymi).
- `lib/ui/widgets/tv_intermediate_sprint_kom_popup.dart` — Wyskakująca tablica wyników premii lotnej i górskiej (`TvIntermediateSprintKomPopup`, `TvIntermediateSprintKomPopupData`, `TvPrimeCrossingEntry`, `TvPrimeClassificationType`: animowane zliczanie punktów `20-17-15-13-11` na sprincie i `20-15-12-10-8` na HC oraz Cat 1–4 przy przejeździe przez linię premii).
- `lib/ui/widgets/tv_itt_split_timer_comparison_hud.dart` — Zegar pomiarowy jazdy na czas ITT/TTT (`TvIttSplitTimerComparisonHud`, `TvIttSplitTimerData`, `IttSplitCheckpointData`, `IttSplitCheckpointType`, `IttPhotocellStatus`: odliczanie setnych części sekundy do lidera na 1., 2. i 3. punkcie pomiarowym oraz zielone `-X.XX s` / czerwone `+X.XX s` tło po przecięciu fotokomórki).
- `lib/ui/widgets/tv_picture_in_picture_breakaway_cam.dart` — Okienko Picture-in-Picture 3D w prawym górnym rogu (`TvPictureInPictureBreakawayCam`, `TvPipBreakawayFeedData`, `PipBreakawayRiderSample`, `PipCameraTargetType`, `PipCameraAngle`: jednoczesny podgląd ucieczki lub pogoni po kraksie, zamiana kamer CAM 1/CAM 2, minimalizacja i responsywny renderer perspektywiczny 3D).
- `lib/ui/widgets/tv_rider_biometrics_telemetry_box.dart` — Telewizyjne okienko biometryczne F1/Whoop Live (`TvRiderBiometricsTelemetryBox`, `TvRiderBiometricsData`, `WPrimeBatteryStatus`: wykres EKG P-QRS-T na żywo, `% HRmax`, strefa mocy Z1–Z7 z W/kg, kadencja RPM oraz segmentowany pasek drenażu baterii beztlenowej $W'$ w kJ).
- `lib/ui/widgets/wind_tunnel_cda_delta_comparator.dart` — Komparator delty CdA w Tunelu Aerodynamicznym (`WindTunnelCdaDeltaComparator`, `WindTunnelCdaDeltaCalculator`, `CdaDeltaComparisonResult`, `CdaDeltaComponentBreakdown`: przeliczanie zmian ramy, kół i podkładek pod mostkiem na m² CdA, waty przy zadanej prędkości i sekundy na 40 km ITT).

### `blender_scripts/` & `test/`
- `blender_scripts/build_all_assets_master.py` + `build_3d_assets_windows.bat` + `generate_*.py`, `rig_and_animate_cyclist.py`, `style_and_materials.py` oraz `test_*.py` — Master pipeline #086–#182 dla Blender 5.3.0 na Windows z `asset_manifest.json`, izolacją `try/except` i skryptem `.bat`.
- `blender_scripts/generate_cobble_monument_props.py` — Generator 3D welodromu (`velodrome_finish_arena.glb`) i rekwizytów sektora bruku (`cobble_sector_props.glb`) w Blender 5.3.
- `blender_scripts/generate_alpine_summit_scenery.py` — Generator 3D scenerii szczytu Hors Categorie (`alpine_summit_pack.glb`: obserwatorium z wieżą, ściany śnieżne 3m, 3 kampery z markizami i flagami) w Blender 5.3.
- `blender_scripts/generate_time_trial_start_ramp.py` — Generator 3D domku i rampy startowej jazdy na czas (`tt_start_ramp.glb`: pawilon stalowo-szklany `#181B22`/`#8E4A49`, pochylnia z antypoślizgowym pasem, stojak koła TT, zegar LED z diodami R/Y/G) w Blender 5.3.
- `blender_scripts/generate_podium_and_trophies.py` — Generator 3D podium dekoracji po etapie (`podium_stage.glb`: 3-stopniowe podium, ścianka sponsorska, schodki, reflektory) oraz 4 trofeów (`trophies_pack.glb`: Kostka Bruku, Puchar Wielkiego Touru, Spirala Nieskończoności, Trójząb Morza Tyrreńskiego) w Blender 5.3.
- `blender_scripts/generate_wind_tunnel_facility.py` — Generator 3D komory pomiarowej Tunelu Aerodynamicznego (`assets/3d/environment/wind_tunnel_room.glb`: kanał cylindryczny, 12-łopatkowy wirnik, siatka prostująca, obrotowa platforma Yaw ±15° z rolkami, listwy LED, dysza i strugi dymu) w Blender 5.3.
- `blender_scripts/generate_helicopter_and_blimp.py` — Generator 3D śmigłowca telewizyjnego (`assets/3d/environment/tv_helicopter.glb`: `TV_Heli_Fuselage` w barwach transmisji, `TV_Heli_Skids`, osobne wirniki `TV_Heli_Main_Rotor`/`TV_Heli_Tail_Rotor` pod animację obrotu oraz głowica `TV_Heli_Cineflex_Gimbal`) w Blender 5.3.
- `blender_scripts/generate_jersey_textures_baker.py` — Proceduralny generator tekstur koszulek 1024x1024 PNG (`assets/textures/jerseys/`: 5 koszulek liderów GC/Points/KOM/Youth/WorldChamp + 8 szablonów drużynowych do barwienia) w Blender 5.3.
- `test/new_career_setup_test.dart`, `test/tactical_minimap_2d_widget_test.dart`, `test/ui/race_hud_overlay_test.dart`, `test/ui/pre_race_briefing_screen_test.dart`, `test/ui/dashboard_hq_screen_test.dart` oraz testy jednostkowe w `test/{core,engine,models,services,ui}/`.
- `test/physics_and_physiology_master_test.dart` — Zbiorczy zestaw 8 testów jednostkowych fizyki i fizjologii (`SpeedSolver`, `BikeFitAndWindTunnelEngine`, `TirePressureCalculator`, `WPrimeBalanceEngine`, `NutritionAndGlycogenEngine`, `AltitudeAcclimatizationAndHeatEngine`).
