# Pro Peloton Manager — Biblia Projektowa, Naukowa i Fizyczna (`GAME_DESIGN_AND_PHYSICS_BIBLE.md`)

> Dokumentacja referencyjna modeli matematycznych, fizycznych, fizjologicznych, algorytmów AI oraz architektury symulacji i renderowania 3D w grze **Pro Peloton Manager** (zakres systemu: zadania `#001–#557`).

---

## 1. Architektura Silnika Symulacji i Determinizm

### 1.1 Wielowątkowa pętla wyścigu (`StageSimulationLoop` & `IsolateSimulationWorker`)
- Główny silnik wyścigu (`lib/engine/simulation/stage_simulation_loop.dart`) działa w kroku dyskretnym $\Delta t = 1.0\text{ s}$ w izolowanym wątku roboczym (`IsolateSimulationWorker`, `lib/engine/simulation/isolate_simulation_worker.dart`), odciążając główny wątek UI Fluttera odpowiedzialny za renderowanie 60–120 FPS.
- Centralny most integracyjny (`EngineIntegrationBridge`, `lib/engine/engine_integration_bridge.dart`) spina w każdym kroku symulacji:
  1. Konfigurację sprzętową (`CompleteBike`, `BikeFitConfiguration`, ciśnienie opon `RiderTirePressureSetup`, stan wosku/łańcucha).
  2. Warunki środowiskowe (wysokość n.p.m., temperaturę, wilgotność, wiatr i opady).
  3. Fizjologię kolarza (`WPrimeBalanceEngine`, `LactateAndLabProfile`, `CoreBodyTemperatureThermoregulation`, dyspozycję dnia).
  4. Fizykę ruchu (`SpeedSolver`, `AeroCalculator`, `GravityAndRollingCalculator`) oraz ruch ciągły peletonu (`BoidsSteeringCollisionAvoidance`).
- `RaceSimulationNotifier` (`lib/state/race_simulation_notifier.dart`) publikuje migawki `RiderPositionSnapshot` do warstwy 3D, HUD telemetrycznego i wykresów profilowych.

### 1.2 Determinizm i Powtarzalność (`DeterministicRngSeedManager`)
- `DeterministicRngSeedManager` (`lib/engine/simulation/deterministic_rng_seed_manager.dart`) opiera wszystkie zdarzenia losowe na pojedynczym ziarnie etapu (`stageSeed`) rozdzielonym na niezależne strumienie `RngDomain` (podmuchy wiatru, decyzje AI, defekty, kraksy).
- Dzięki temu powtórki (`StageReplayRecorder`) i symulacje duchów (`GhostChallengeModel`) odtwarzają identyczną trajektorię co do milisekundy.

---

## 2. Fizyka Ruchu Kolarza (Dynamika Szosowa, Terenowa i Torowa)

### 2.1 Stałe Fizyczne (`PhysicsConstants`)
Zdefiniowane w `lib/core/constants/physics_constants.dart`:
- Przyspieszenie ziemskie: $g = 9.80665\text{ m/s}^2$ (`gravity`)
- Bazowa gęstość powietrza na poziomie morza ($15^\circ\text{C}$, $1013.25\text{ hPa}$): $\rho_0 = 1.225\text{ kg/m}^3$ (`seaLevelAirDensity`)
- Skala wysokości atmosfery: $H = 8500.0\text{ m}$ (`atmosphericScaleHeight`), model wykładniczy:
  $$\rho(h) = \rho_0 \cdot \exp\left(-\frac{h}{H}\right)$$
- Pionowy gradient temperatury atmosfery wzorcowej (ISA): $\Gamma = 0.0065\text{ K/m}$ (`temperatureLapseRate`)
- Straty mechaniczne napędu:
  - Łańcuch woskowany (`drivetrainLossWaxed`): $2.0\%$ ($\eta = 0.980$)
  - Smar syntetyczny standardowy (`drivetrainLossStandard`): $2.8\%$ ($\eta = 0.972$)
  - Napęd zabrudzony / zużyty (`drivetrainLossDirty`): $3.5\%$ ($\eta = 0.965$)

### 2.2 Równanie Ruchu i Hybrydowy Solver (`SpeedSolver`)
Zaimplementowany w `lib/engine/physics/speed_solver.dart` rozwiązuje nieliniowe równanie dynamiki kolarza:
$$m_{total} \cdot a = F_{prop} - \left(F_{grav} + F_{roll} + F_{aero}\right) - F_{brake}$$
- **Metoda numeryczna**: hybrydowy algorytm Newtona-Raphsona z bisekcją (8 iteracji) wyznaczający prędkość równowagową (`equilibriumSpeedMs`) oraz nowy wektor prędkości w kroku $\Delta t$.
- **Siła napędowa na tylnym kole**:
  $$F_{prop} = \min\left(F_{max},\ \frac{P_{input} \cdot (1 - \text{loss})}{\max(v,\ v_{min})}\right)$$
  gdzie $F_{max} = 1250.0\text{ N}$ (`maxTractionForceNewtons`) zapobiega osobliwości przy ruszaniu z miejsca, a $v_{min} = 0.35\text{ m/s}$ (`minSpeedThresholdMs`).
- **Limit prędkości na zjeździe** (`calculateMaxDescentSpeedMs`): zależy od atrybutu `RiderSkills.descending` ($1\text{–}100$) oraz trudności technicznej drogi (`technicalDifficulty`):
  $$v_{base,\text{km/h}} = 54.0 + 0.44 \cdot \text{skill}, \quad v_{safe,\text{km/h}} = \max\left(32.0,\ v_{base,\text{km/h}} - \frac{\text{tech}}{100} \cdot \frac{100 - \text{skill}}{100} \cdot 24.0\right)$$
  Najlepsi zjazdowcy ($\text{skill} \approx 95\text{–}99$) osiągają do $98\text{ km/h}$ na łagodnych łukach, podczas gdy słabi technicznie dohamowują (`brakingForceNewtons > 0`) do $55\text{–}62\text{ km/h}$.

### 2.3 Grawitacja i Opory Toczenia (`GravityAndRollingCalculator`)
Zaimplementowany w `lib/engine/physics/gravity_and_rolling_calculator.dart`:
- **Masa całkowita układu**:
  $$m_{total} = \max\left(10.0,\ m_{rider} + m_{bike} + m_{bottles}\right)$$
  gdzie domyślna masa dwóch pełnych bidonów wynosi $m_{bottles} = 1.0\text{ kg}$ (`defaultBottlesWeightKg`).
- **Siła grawitacji wzdłuż stoku** (dla kąta nachylenia $\theta = \arctan(\text{gradient})$):
  $$F_{grav} = m_{total} \cdot g \cdot \sin(\theta), \qquad N = m_{total} \cdot g \cdot \cos(\theta)$$
- **Siła oporów toczenia**:
  $$F_{roll} = C_{rr,\text{eff}} \cdot N$$
  Bazowe wartości $C_{rr}$ z `PhysicsConstants`: gładki asfalt $0.0033$, standardowy asfalt $0.0045$, chropowaty asfalt $0.0065$, szuter $0.0085$, bruk $0.0125$. `calculateEffectiveCrr` skaluje $C_{rr}$ o mnożnik chropowatości nawierzchni (np. `smoothAsphalt` $\times 1.0$, `concrete` $\times 1.45$, `roughAsphalt` $\times 1.67$, `gravelStrade` $\times 2.73$), redukując straty impedancyjne dla systemów `tubeless` i szerszych opon $28\text{–}32\text{ mm}$.

### 2.4 Aerodynamika, Wiatr Pozorny i Drafting (`AeroCalculator` & CFD)
Zaimplementowany w `lib/engine/physics/aero_calculator.dart`:
- **Bazowe współczynniki oporu $C_d A$** (`RiderPosition`):
  | Pozycja (`RiderPosition`) | $C_d A$ $[\text{m}^2]$ | Zastosowanie |
  |---|---:|---|
  | `timeTrial` (lemondka) | `0.225` | ITT / TTT |
  | `puppyPaws` (przedramiona) | `0.265` | Ucieczki solo / płaskie |
  | `drops` (dolny chwyt) | `0.295` | Zjazdy, sprint, pogoń |
  | `hoods` (chwyty górne) | `0.325` | Jazda bazowa w peletonie |
  | `standing` (na stojąco) | `0.415` | Strome podjazdy, przyspieszenia |
- Wzorcowa powierzchnia czołowa: $A_{ref} = 0.498\text{ m}^2$ (`referenceFrontalAreaM2`, dla $70\text{ kg} / 178\text{ cm}$).
- **Siła i moc oporu aerodynamicznego**:
  $$F_{aero} = \frac{1}{2} \cdot \rho(h, T) \cdot C_d A_{eff} \cdot v_{app}^2, \qquad P_{aero} = F_{aero} \cdot v$$
  gdzie $v_{app}$ to prędkość pozorna wiatru (składająca wektor ruchu kolarza oraz wektor wiatru czołowego/bocznego i kąt odchylenia `yawAngleDegrees`).
- **Drafting w peletonie**:
  - `PhysicsConstants.draftingDirectBehind = 0.62` ($38\%$ redukcji oporu bezpośrednio za kołem),
  - `PhysicsConstants.draftingDeepPeloton = 0.38` ($62\%$ redukcji w środku grupy; limit `maxDraftingReduction = 0.48` w kalkulatorze bazowym dla pojedynczego wektora),
  - `PhysicsConstants.draftingSideEchelon = 0.78` ($22\%$ redukcji na wachlarzu przy wietrze bocznym, `EchelonCrosswindEngine`).
- **Moduły rozszerzone**:
  - `RealTimeCfdVortexAndDragSolver` (`lib/engine/physics/real_time_cfd_vortex_and_drag_solver.dart`) — analiza strefowa CFD (kask, przedramiona, tekstylia, reguła $105\%$ dla kół, ścieżki wirów Kármána).
  - `CrosswindWheelStabilityAndGustSolver` (`lib/engine/physics/crosswind_wheel_stability_and_gust_solver.dart`) — siła boczna $F_{lat}$ i moment skręcający $\tau_{steer}$ na wysokich stożkach $65\text{–}80\text{ mm}$.
  - `AltitudeDescentAirDensityTransition` (`lib/engine/physics/altitude_descent_air_density_transition.dart`) — ciągła ($C^1$) interpolacja gęstości powietrza $\rho(h, T)$ podczas szybkich zjazdów alpejskich.
  - `SprintLeadoutAerodynamicSlingshot` (`lib/engine/peloton/sprint_leadout_aerodynamic_slingshot.dart`) — efekt procy aerodynamicznej na ostatnich $250\text{ m}$ (opóźnione narastanie oporu czołowego przez $1.5\text{ s}$ po wyskoku z koła przy $65\text{ km/h}$ do $72\text{–}76\text{ km/h}$).

### 2.5 Fizyka Specjalistyczna (Zakręty, Bruk, Szuter, MTB, CX, Welodrom)
- **Przyczepność w zakrętach** (`WetCorneringGripAndBrakingSolver`, `lib/engine/physics/wet_cornering_grip_and_braking_solver.dart`):
  $$v_{max} = \sqrt{\mu \cdot g \cdot R}$$
  gdzie $\mu_{dry} \approx 0.85$, $\mu_{wet} \approx 0.55$, $\mu_{wet\_cobble} \approx 0.40$, korygowane o mieszankę opony, ciśnienie i kąt pochylenia.
- **Bruk i Impedancja** (`CobbleTirePressureRealTimeDeflection`, `lib/engine/physics/cobble_tire_pressure_real_time_deflection.dart`): modeluje kompromis między histerezą opony a stratami wibracyjnymi (impedancją) na sektorach $1\bigstar\text{–}5\bigstar$.
- **Szuter i Mleczko Tubeless** (`GravelRollingResistanceAndSealantSolver`, `lib/engine/physics/gravel_rolling_resistance_and_sealant_solver.dart`): opory impedancyjne luźnego szutru oraz prawdopodobieństwo samouszczelnienia przebicia przez mleczko i wkładki piankowe (`GravelBikeAndTireInsertsModel`).
- **MTB XCO** (`MtbSuspensionDampingAndLineChoiceSolver`, `lib/engine/physics/mtb_suspension_damping_and_line_choice_solver.dart`): tłumienie zawieszenia $100\text{–}120\text{ mm}$, straty `Pedal Bob` i `Chatter`, wybór linii `A-Line` vs `B-Line`.
- **Cyclo-Cross (CX)** (`CyclocrossBunnyhopAndCarrySolver`, `lib/engine/physics/cyclocross_bunnyhop_and_carry_solver.dart`, `CxPitBikeExchangeMechanics`): opory błota ($0.4\text{–}1.8\text{ kg/km}$, $+12\text{ W/km}$), bieg z rowerem na ramieniu ($12\text{–}16\text{ km/h}$) oraz skok `Bunny-Hop` nad belkami przy `bikeHandling >= 85`.
- **Welodrom 250 m** (`VelodromeBankingAndCentripetalSolver`, `VelodromeKeirinAndMadisonSlingSolver`): siła odśrodkowa $a_c = v^2 / R$ w wirażach $42^\circ\text{–}45^\circ$ (przeciążenie do $1.8G$ podnoszące masę efektywną i opór toczenia), kara dystansowa powyżej czarnej linii ($250.0\text{ m} \to 258.5\text{ m}$), draft za motocyklem Derny ($50\text{ km/h}$) oraz przekazywanie pędu w rzucie `Hand Sling` w wyścigu Madison.
- **Rzut na kreskę** (`FinishLineBikeThrowPhysics`, `lib/engine/peloton/finish_line_bike_throw_physics.dart`): wysunięcie przedniego koła o $+18\text{–}28\text{ cm}$ na ostatnich $10\text{ m}$ z rozdzielczością fotofiniszu $0.001\text{ s}$.

---

## 3. Fizjologia, Bioenergetyka i Termoregulacja

### 3.1 Bilans Energii Beztlenowej $W'$ (`WPrimeBalanceEngine` — Model Skiby)
Zaimplementowany w `lib/engine/physics/w_prime_balance_engine.dart` wg modelu **Skiba et al. (2012, 2015)**:
1. **Gdy $P > CP$ ($\text{FTP}$)** — wydatek beztlenowy jest liniowy:
   $$\frac{dW'}{dt} = -(P - CP)$$
2. **Gdy $P < CP$ ($\text{FTP}$)** — regeneracja wykładnicza:
   $$W'(t + \Delta t) = W'_{max} - \left(W'_{max} - W'(t)\right) \cdot \exp\left(-\frac{\Delta t}{\tau}\right)$$
   Stała czasowa regeneracji $\tau$ uwzględnia bazową zależność Skiby oraz sprawność tlenową kolarza ($VO_2\text{max}$ i `recoveryRate`):
   $$\tau_{base} = 546 \cdot \exp\left(-0.01 \cdot (CP - P)\right) + 316$$
   $$\tau_{eff} = \text{clamp}\left(\frac{\tau_{base}}{\left(\frac{\max(45,\ VO_2\text{max})}{70}\right)^{0.75} \cdot \max(0.5,\ \text{recoveryRate})},\ 160\text{ s},\ 1200\text{ s}\right)$$
3. **Odcięcie beztlenowe (`isExhausted`)**: wyzerowanie $W' \le 0$ wymusza redukcję mocy maksymalnej do `exhaustionPowerCapRatio = 0.85` ($85\%$ FTP) aż do odbudowania bufora bezpieczeństwa `exhaustionExitThresholdRatio = 0.10` ($10\%\ W'_{max}$).

### 3.2 Profil Mleczanowy, Kadencja i Biomechanika
- **Próg mleczanowy i VO2max** (`LactateAndLabProfile`, `lib/models/rider/lactate_and_lab_profile.dart`): modeluje parametry `LT1`, `LT2`, `VLaMax` i $VO_2\text{max}$, determinując proporcję spalania tłuszczów do glikogenu w strefach Z1–Z7.
- **Kadencja i przełożenia** (`CadenceAndGearingEfficiencySolver`, `lib/engine/physics/cadence_and_gearing_efficiency_solver.dart`):
  $$i = \frac{Z_{front}}{Z_{rear}}, \qquad \text{RPM} = \frac{v \cdot 60}{C_{wheel} \cdot i}$$
  Mielenie przy niskiej kadencji ($<60\text{ RPM}$, np. na ściance $18\%$ z kasetą `11-28T`) generuje $+18\%$ kosztu glikogenu i przyspiesza zmęczenie włókien szybkokurczliwych.
- **Biomechanika obrotu korby $360^\circ$** (`PedalStrokeBiomechanicsAnalyzer`): wyznacza siłę styczną $F_t(\theta)$, balans L/R ($49.2\%/50.8\%$, przesuwany do $44\%/56\%$ po kontuzji kolana), `Torque Effectiveness (TE %)` i `Pedal Smoothness (PS %)`.

### 3.3 Hipoksja Wysokogórska (`HighAltitudeHypoxiaCalculator`)
Zaimplementowany w `lib/engine/physics/high_altitude_hypoxia_calculator.dart`:
- Do wysokości $h \le 1500\text{ m n.p.m.}$ panuje normoksja ($\Delta P = 0$).
- Powyżej $1500\text{ m n.p.m.}$ dostępny pułap $VO_2\text{max}$ i FTP spada nieliniowo:
  $$\Delta P = -0.0085 \cdot \left(\frac{h - 1500}{100}\right)^{1.4}$$
- Strefy wysokościowe: `normoxia` ($\le 1500\text{ m}$), `moderateAltitude` ($1500\text{–}2000\text{ m}$), `highMountain` ($2000\text{–}2500\text{ m}$, np. Col du Tourmalet $2115\text{ m}$), `extremeAlpine` ($>2500\text{ m}$, np. Col du Galibier $2642\text{ m}$, Passo dello Stelvio $2758\text{ m}$).
- Kolarze po ukończonym obozie wysokogórskim (`AltitudeCampAcclimatizationCurve` — dni $7\text{–}24$ superkompensacji $+3.5\%\ VO_2\text{max}$) lub pochodzący z Andów (COL/ECU) redukują karę hipoksji o połowę (`effectiveDeltaP = rawDeltaP * 0.5`).

### 3.4 Termoregulacja, Nawodnienie i Odżywianie
- **Temperatura głęboka ciała** (`CoreBodyTemperatureThermoregulation`, `lib/engine/physics/core_body_temperature_thermoregulation.dart`): zakres $37.0^\circ\text{C}\text{–}40.5^\circ\text{C}$. Produkcja ciepła metabolicznego:
  $$\dot{Q}_{prod} = P \cdot \frac{1 - \eta}{\eta}$$
  bilansowana przez konwekcję ($\dot{Q}_{conv} \propto v^{0.6}$) oraz parowanie potu. Przekroczenie $39.2^\circ\text{C}$ wywołuje dryf tętna $+12\text{ BPM}$ i spadek mocy maksymalnej.
- **Chłodzenie i elektrolity** (`IceSocksAndWaterDousingMechanics`, `SweatSodiumElectrolyteDepletion`): woreczki z lodem i polewanie wodą obniżają temperaturę głęboką o $0.4^\circ\text{C}$ na $15\text{ min}$. Pocenie $0.8\text{–}2.5\text{ l/h}$ z utratą sodu $500\text{–}1500\text{ mg/l}$ prowadzi do skurczów (`Muscle Cramps`) przy $>3\%$ odwodnienia.
- **Glikogen i suplementacja** (`NutritionAndGlycogenEngine`, `CarbohydrateHydrogelAndKetonesEngine`): strategie `Standard 60g/h CHO`, `High-Carb Hydrogel 110g/h` (zależna od `gutTrainingLevel`), `Bicarbonate Pre-Load` ($+6\%\ W'$ z ryzykiem `GI Distress`) oraz `Post-Finish Exogenous Ketones` ($+12\%$ regeneracji nocnej).
- **Zmęczenie wielodniowe i rytm dobowy**:
  - `GrandTourThirdWeekFatigueDecay`: spadek FTP na etapach $14\text{–}21$ ($2\text{–}3\%$ dla specjalistów GT, $9\text{–}14\%$ dla kolarzy klasycznych).
  - `DayConditionAndBiorhythmEngine` ($-5\dots +5$) i `DailyRiderDayFormVarianceEngine` ($-3\dots +3$ diamenty): losowanie skorelowane z TSB i snem, odkrywane powyżej LT1 w pierwszych $30\text{ km}$.
  - `UltraSleepDeprivationAndCircadianSolver`: model deficytu snu (`Sleep Debt`) i rytmu dobowego Borbély'ego w wyścigach ultra-bikepackingowych.

---

## 4. Sztuczna Inteligencja Peletonu i Taktyka Wyścigowa

### 4.1 Ruch Ciągły bez Kolizji (`BoidsSteeringCollisionAvoidance`)
- `BoidsSteeringCollisionAvoidance` (`lib/engine/peloton/boids_steering_collision_avoidance.dart`) oraz `BoidsPelotonFlockingSolver` (`lib/engine/rendering3d/boids_peloton_flocking_solver.dart`) sterują jednocześnie 176 kolarzami w oparciu o siatkę przestrzenną `SpatialHashGrid1d2d` (koszyki co $5\text{ m}$, złożoność $O(N)$, czas kroku $< 0.4\text{ ms}$).
- Cztery siły wektorowe: `Separation` (koperta bezpieczeństwa $1.85 \times 0.65\text{ m}$, min. odstęp boczny $\ge 0.45\text{ m}$), `Alignment`, `DraftSeeking` (szukanie strefy najniższego $C_d A$) oraz `OvertakeLaneShift` (wyprzedzanie na $15\text{ m}$ przy $\Delta v > 0.8\text{ m/s}$).

### 4.2 Algorytmy Taktyczne AI
- **Osobowości AI** (`TacticalAiPersonalityProfiles`): `CannibalAttacker`, `DieselCalculator`, `WheelsuckerOpportunist`, `KamikazeDescender`, `BreakawayHunter`, `LoyalRoadCaptain`.
- **Równowaga ucieczek** (`BreakawayVsPelotonEquilibriumSolver`): kontroluje odjazdy w zależności od profilu ($8\text{–}12\%$ szans na płaskim przy pociągach sprinterskich, $45\text{–}55\%$ na pagórkach, kontrola $\ge 1\text{ min}/3\text{ km}$ u podnóża finałowego podjazdu).
- **Progi paniki GC** (`GcTimeGapPanicThresholdAi`): gdy rywal z top GC znajduje się w ucieczce poniżej $4\text{ min}$ straty, AI wystawia $4$ pomocników na czoło peletonu przy $88\%\text{ FTP}$.
- **Taktyki zaawansowane**:
  - `SatelliteRiderRelayTacticsEngine`: stacje przekaźnikowe na przedostatnich przełęczach i czekanie na lidera GC.
  - `GrupettoAutobusSurvivalAi`: formowanie 40-osobowego autobusu z Kapitanem wyliczającym tempo na limit czasu (OTL) z buforem $3\text{ min}$.
  - `SprinterTrainCounterSurfingAi`: przeskakiwanie sprinterów między pociągami rywali.
  - `TeamTimeTrialRiderDropStrategy`: strategia `Kamikaze Pull & Drop` w TTT.
  - `InRacePelotonDiplomacyEngine` i `NatureBreakAndPelotonEtiquetteEngine`: pakty na szosie, rozejmy po kraksie lidera poza strefą $<25\text{ km}$ oraz konsekwencje zdrady.

---

## 5. Architektura Renderowania 3D, Audio i Systemów Kariery

### 5.1 Potok Renderowania 3D Zero-GC 120 FPS
- **Budżet klatki**: $< 4.5\text{ ms}$ na klatkę dla stałych 120 FPS, audytowany przez `Performance120FpsFrameBudgetAuditor` (`lib/core/diagnostics/performance_120fps_frame_budget_auditor.dart`).
- **Pula pamięci Zero-GC** (`RenderObjectPoolManager`): prealokowane bufory `Float64List` dla 176 kolarzy, 352 kół i 890 cząsteczek pogody.
- **Rzutowanie i widoczność**: `Scene3dMathProjection` (macierze `vector_math_64`), `FrustumAndDistanceCuller` (odrzucanie $>450\text{ m}$ z mgłą odległościową), `Peloton3dCanvasEngine`.
- **Kinematyka i detale**: `InverseKinematicsLimbSolver` (analityczne IK 2-stawowe nóg i rąk dla korby $165\text{–}175\text{ mm}$), `StandingBikeRockingPhysics3d` (kołysanie $\phi(t) = \phi_{max}\sin(\theta_{crank})$, $\pm 7^\circ$), `ProceduralPbrTextureAtlasGenerator` (atlas tekstur PBR w RAM), `ProjectedPlanarShadowsPainter`, `WetAsphaltReflectionsPainter`, `DynamicSkyboxAndLightingPainter`.

### 5.2 Audio Przestrzenne 3D i Haptyka
- `ProceduralCyclingAudioEngine` & `SoundscapeMixerController`: 5-kanałowa synteza proceduralna (szum wiatru, bębenek piasty, oddech kolarza, dzwonki kibiców, ryk tłumu).
- `Spatial3dPelotonAudioPanner`: panoramowanie stereo 3D źródeł względem aktywnej kamery (`CameraRigController`).
- `HapticFeedbackVibrationController`: impulsy wibracyjne na bruku $5\bigstar$, przy kraksach i zmianach przełożeń.

### 5.3 Ekonomia Kariery, Przepisy UCI i Tryby Rozgrywki
- **Ekonomia i starzenie**: `DynamicInflationAndMarketBoomService` (makroekonomia 2026–2040), `MultiSeasonRiderAgingAndDeclineCurve` (szczyt $24\text{–}29$ lat, spadek $>31$ przy wzroście `raceIq`), `OvertrainingAndBurnoutDiagnostics` (`TSB < -35` przez $>14$ dni $\to -15\text{ BPM}$ MaxHR i $-8\%$ FTP).
- **Przepisy i VAR**: `UciCommissaireRulebookAndVarModel` (analiza `Sprint Deviation VAR`, żółte kartki, ewolucja regulaminów), `RosterUciComplianceValidator` (limit wagi roweru $\ge 6.80\text{ kg}$).
- **Tryby rozgrywki**: Kariera Menedżera (`CareerSave`), Kariera Kolarza *Be a Pro* (`ProCyclistCareerState`), Kobiecy WorldTour i Sztafeta Mieszana (`WomensWorldTourSeasonState`), Organizator Wyścigów (`RaceOrganizerEmpireModel`), Własna Marka Rowerowa R&D (`InHouseBikeBrandModel`), Ligi Online ELO i Duchy (`OnlineLeagueModel`, `GhostChallengeModel`), MTB XCO, Gravel, Cyclo-Cross, Tor/Welodrom oraz Ultra-Bikepacking.
