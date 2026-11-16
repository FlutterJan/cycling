# Pro Peloton Manager — Instrukcja Gracza i Dokumentacja Wydania (`RELEASE_CHECKLIST_AND_MANUAL.md`)

> Kompletny podręcznik dyrektora sportowego oraz procedura kompilacji i weryfikacji wydań produkcyjnych dla platform **Windows**, **macOS**, **Android** oraz **iOS/iPadOS** (wersja bazowa z `pubspec.yaml`: `0.1.0+1`, Dart SDK `>=3.3.0 <4.0.0`).

---

## Spis Treści

1. [Przegląd Systemów Gry](#1-przegląd-systemów-gry)
2. [Skróty Klawiszowe i Sterowanie](#2-skróty-klawiszowe-i-sterowanie)
3. [Taktyka Wyścigowa i Silnik 3D](#3-taktyka-wyścigowa-i-silnik-3d)
4. [Fizjologia Treningu, Żywienia i Regeneracji](#4-fizjologia-treningu-żywienia-i-regeneracji)
5. [Lista Kontrolna Wydania (Pre-Release Checklist)](#5-lista-kontrolna-wydania-pre-release-checklist)
6. [Komendy Kompilacji i Pakowania na Wszystkie Platformy](#6-komendy-kompilacji-i-pakowania-na-wszystkie-platformy)

---

## 1. Przegląd Systemów Gry

- **Architektura**: Flutter + Riverpod (`flutter_riverpod`) + `GoRouter` (`lib/core/router/app_router.dart`).
- **Symulacja w tle**: Fizyka wyścigu działa w osobnym wątku (`IsolateSimulationWorker`, `StageSimulationLoop`) i dostarcza sekundowe migawki telemetryczne (`RiderPositionSnapshot`) do HUD i renderera 3D (`Peloton3dCanvasEngine`).
- **Zapisy i odzyskiwanie danych**: Atomowy zapis transakcyjny (`.tmp` + suma kontrolna `fnv1a64+crc32` + kopia `.bak`) przez `AutosaveAndCrashRecoveryGuard` oraz 5 ręcznych slotów + `Auto-Save` w `SaveLoadSlotsModal`.
- **Eksport danych**: Telemetria etapów w standardach `.tcx` (Garmin TCX v2) i `.gpx` (GPX 1.1) przez `GpxAndTcxTelemetryExporter`, kronika kariery `.html`/`.md` (`CareerAlmanacHtmlReportExporter`) oraz paczki tras `.ppmstage` (`CommunityStagePackSharingService`).

---

## 2. Skróty Klawiszowe i Sterowanie

Wszystkie skróty klawiszowe są obsługiwane przez `KeyboardShortcutsManager` (`lib/ui/widgets/keyboard_shortcuts_manager.dart`) oraz moduły systemowe. Ściągawkę w grze otworzysz w każdej chwili klawiszem **`F1`**.

### 2.1. Wyścig 3D — Czas, Kamera i Widok

| Skrót | Akcja | Opis działania |
| :--- | :--- | :--- |
| **`Spacja`** | Pauza / Wznów | Zatrzymuje lub wznawia symulację wyścigu 3D (w trybie pauzy dostępny jest m.in. Tryb Fotograficzny 3D `PhotoMode3dCameraStudioOverlay`). |
| **`+`** lub **`]`** | Przyspiesz czas | Zwiększa mnożnik prędkości symulacji (`1x → 2x → 4x → 8x`). |
| **`-`** lub **`[`** | Zwolnij czas | Zmniejsza mnożnik prędkości symulacji (`8x → 4x → 2x → 1x`). |
| **`C`** | Przełącz kamerę 3D | Cyklicznie zmienia ujęcie: `ChaseCam → MotoTvCam → HeliCam → FinishLineCam`. |
| **`V`** | Aero Vision Mode | Włącza lub wyłącza wizualizację strug powietrza, wiatru bocznego i cienia aerodynamicznego (`WindStreamlinesVisualizer`). |
| **`Tab`** | Pokaż / Ukryj HUD | Chowa lub odsłania boczne panele telemetrii dla czystego widoku transmisji TV. |
| **`1`** – **`8`** | Wybór kolarza (1–8) | Wybiera kolarza z aktywnego składu drużyny (sloty 1–8) i natychmiast centruje na nim kamerę 3D. |

### 2.2. Wyścig 3D — Rozkazy Taktyczne i Żywienie

| Skrót | Akcja | Opis działania |
| :--- | :--- | :--- |
| **`A`** | Natychmiastowy atak | Wydaje wybranemu kolarzowi rozkaz oderwania się od grupy (wysoki pobór $W'$). |
| **`R`** | Zmiana na czele (`Pull Group`) | Kolarz wychodzi na czoło grupy i nadaje tempo zgodnie z ustawionym suwakiem wysiłku. |
| **`P`** | Chroń lidera | Kolarz osłania lidera drużyny przed wiatrem i atakami rywali. |
| **`G`** | Spożyj żel energetyczny | Podaje żel węglowodanowy wybranemu kolarzowi w celu uzupełnienia glikogenu. |
| **`B`** | Spłyń po bidony | Wysyła kolarza do wozu technicznego po bidony z wodą i elektrolitami dla drużyny (uwaga na blokadę sędziowską `Barrage Active` poniżej 60 s przewagi). |

### 2.3. Tryb Menedżera, Diagnostyka i Okno Desktop

| Skrót | Akcja | Opis działania |
| :--- | :--- | :--- |
| **`Ctrl + S`** / **`Cmd + S`** | Szybki zapis gry | Natychmiast zapisuje bieżący stan kariery w trybie menedżera. |
| **`Enter`** / **`Ctrl + Spacja`** | Następny dzień (`Advance Day`) | Przechodzi do kolejnego dnia kalendarza kariery. |
| **`Ctrl + K`** | Wyszukiwarka Spotlight | Otwiera `GlobalSearchSpotlightModal` dla 800+ kolarzy, 53 drużyn, wyścigów i podjazdów. |
| **`F1`** | Ściąga skrótów | Otwiera lub zamyka modal `ShortcutsCheatSheetOverlay` (`Esc` zamyka). |
| **`F3`** | Nakładka wydajności | Przełącza `PerformanceProfilerOverlay` (FPS, Frame Time Graph, czas ticku fizyki Isolate, LOD i RAM). |
| **`F11`** | Pełny ekran (Desktop) | Przełącza tryb pełnoekranowy okna (`WindowsDesktopWindowConfig`). |
| **`F12`** | Screenshot Mode | Tryb czystego zrzutu ekranu w konfiguracji desktopowej. |

### 2.4. Sterowanie Dotykowe i Tryb Jednej Ręki (Mobile / Tablet)

- **Kołowe menu taktyczne** (`TacticalRadialCommandMenu`): 8 wycinków rozkazów (*Atakuj, Pozycja, Zmiana, Na Kole, Chroń, Żel, Bidony, Grupetto*).
- **Tryb kciuka** (`MobileOneHandedThumbHudMode`): przenosi wybór kolarzy, suwak wysiłku i rozkazy taktyczne do dolnej strefy ekranu dla wygodnej obsługi jedną ręką na telefonie (`390x844`).

---

## 3. Taktyka Wyścigowa i Silnik 3D

### 3.1. Odprawa Przedstartowa i Sprzęt (`PreRaceBriefingScreen`)

1. **Rekonesans i profil trasy**: Sprawdź nachylenia, sektory bruku 1★–5★ (`MonumentCobbleSectorsInspectorModal`), wysokość przełęczy oraz prognozę wiatru/temperatury (`DynamicMountainWeatherEngine`).
2. **Warsztat mechaników (`MechanicWorkshopPanel`)**:
   - **Ciśnienie opon** (`TirePressureCalculator`): dobierz niższe ciśnienie (np. ~3.8 bar) na bruk 5★ i mokry asfalt dla przyczepności i tłumienia, a wyższe (~6.5 bar) na gładką czasówkę ITT.
   - **Przełożenia napędu** (`DrivetrainGearingConfiguration`): tarcze od `50/34T` do `58T 1x` oraz kasety 12-rzędowe od `11-28T` do `10-36T`. Zbyt twarde przełożenie na stromym podjeździe (kadencja `< 60 RPM`) powoduje **+18% kosztu glikogenu** i szybkie zmęczenie włókien szybkokurczliwych (`CadenceAndGearingEfficiencySolver`).
   - **Bike Fit i Tunel Aero**: konfiguracja pozycji (`BikeFitConfiguration`) wpływa bezpośrednio na współczynnik $CdA$. Możesz użyć przycisku *Zastosuj Optymalny Setup Mechanika*.
3. **Role taktyczne w autobusie (`TeamBusLockerRoomScreen`)**: przypisz lidera GC/Sprintera, rozprowadzających, pomocników i harcowników do ucieczki.

### 3.2. Aerodynamika, Drafting i Wachlarze (Echelons)

- **Cień aerodynamiczny (`DraftingGridSystem`, `AeroCalculator`)**: jazda w środku peletonu redukuje opór powietrza o **35–48%**, drastycznie oszczędzając glikogen i baterię $W'$.
- **Wiatr boczny i ranty (`EchelonCrosswindEngine`, `TvEchelonCrosswindRadarHud`)**: przy wietrze bocznym powyżej **35 km/h** peleton pęka na echelony (ranty). Gdy radar wyświetli alert `CROSSWIND ZONE — ECHELON RISK HIGH`, utrzymuj lidera w pierwszej 15–20 pozycji pod osłoną 1–2 pomocników (`P`).
- **Równowaga ucieczki (`BreakawayVsPelotonEquilibriumSolver`)**: na etapach płaskich ucieczka ma zwykle 8–12% szans powodzenia przeciwko pociągom sprinterskim, na pagórkowatych 45–55%, a w górach wymaga co najmniej ~1 min przewagi na każde 3 km finałowego podjazdu.
- **Próg paniki GC (`GcTimeGapPanicThresholdAi`)**: jeśli w odjeździe znajduje się rywal groźny w klasyfikacji generalnej (strata `< 4 min`), AI automatycznie wystawia do 4 pomocników na czoło peletonu przy ~88% FTP.

### 3.3. Taktyki Zaawansowane (Góry, Zjazdy, Sprinty)

- **Stacje Przekaźnikowe (`SatelliteRiderRelayTacticsEngine`)**: wyślij mocnego pomocnika do porannej ucieczki, wydaj mu rozkaz `Wait for GC Leader` na przedostatniej przełęczy, a następnie wykorzystaj go do holowania lidera w dolinie i u podnóża finałowego podjazdu.
- **Ataki na zjazdach i Supertuck (`DescenderAttackAndSupertuckPhysics`)**: kolarze z atrybutami `descending >= 85` oraz `bikeHandling >= 85` mogą atakować na technicznych zjazdach, opóźniając hamowanie przed nawrotami 180° (zysk 25–45 s na 15 km zjazdu). Monitoruj ryzyko poślizgu w `DescentTechnicalityRadarHud` — na mokrym asfalcie ($\mu \approx 0.55$) i mokrym bruku ($\mu \approx 0.40$) prędkość maksymalna w zakręcie spada zgodnie z $v_{\max} = \sqrt{\mu \cdot g \cdot R}$ (`WetCorneringGripAndBrakingSolver`).
- **Blokowanie drogi (`DomestiqueRoadBlockingMechanics`)**: na wąskich drogach (`< 4.5 m`) pomocnicy drużyny lidera mogą spowalniać pogoń jadąc szeroko przy ~65% FTP.
- **Pociąg sprinterski i proca aero (`SprintTrainAiController`, `SprintLeadoutAerodynamicSlingshot`)**: ustaw pociąg na ostatnich 3 km; ostatni rozprowadzający powinien rozwinąć ~65 km/h, aby na 250 m przed metą sprinter wyskoczył z jego koła z pełnym $W'$ i osiągnął **72–76 km/h**.
- **Jazda na kole i blef (`WheelsuckingAndBluffingAiLogic`)**: rozkaz `Skip Pulls / Sit On` pozwala oszczędzać energię w ucieczce i rozgrywać końcówkę psychologicznie (`Poker Face`).
- **Grupetto i Limit Czasu OTL (`GrupettoAutobusSurvivalAi`, `OtlTimeCutWarningBannerHud`)**: gdy zmęczony sprinter lub pomocnik odpada na etapach górskich, dołącz go do Grupetto (40-osobowego autobusu), w którym kapitan wylicza tempo gwarantujące zmieszczenie się w limicie OTL z zapasem ~3 minut. Jeśli baner ostrzeże o spadku zapasu poniżej **2 minut**, cofnij pomocników do holowania.

### 3.4. Przepisy Sędziowskie UCI (`CommissaireJuryPenaltiesEngine`)

- **Sticky Bottle**: zbyt długie trzymanie się bidonu przy wozie technicznym skutkuje karą **+20 s** i grzywną w CHF.
- **Irregular Sprint**: niebezpieczne zajechanie drogi przy barierkach kończy się relegacją na koniec grupy.
- **Barrage Active (`LiveTeamCarGapIndicatorHud`)**: gdy przewaga grupy nad peletonem spada poniżej **60 s**, sędziowie blokują przejazd wozów technicznych — zaplanuj pobór bidonów (`B`) z wyprzedzeniem.

---

## 4. Fizjologia Treningu, Żywienia i Regeneracji

### 4.1. Profil Metaboliczny i Strefy Mocy (Z1–Z7)

Każdy kolarz opisany jest przez model fizjologiczny (`RiderPhysiology`, `LactateAndLabProfile`) oraz krzywą mocy (`RiderPowerProfile`: 5s, 1m, 5m, 20m, 60m):

- **FTP / CP** (*Functional Threshold Power / Critical Power*): granica mocy progowej (w W oraz W/kg), powyżej której dochodzi do drenażu baterii beztlenowej.
- **Strefy Mocy (Z1–Z7)** (`AppColors`): od regeneracji Z1 po wysiłek nerwowo-mięśniowy Z7 (sprint >150% FTP).
- **$W'$ (W-Prime) i model Skiby (`WPrimeBalanceEngine`)**: pojemność beztlenowa w kJ. Każdy wysiłek powyżej FTP/CP drenuje $W'$, a jazda poniżej FTP pozwala na jego wykładniczą regenerację. Spadek $W'$ do `0 kJ` uniemożliwia atak i sprint.
- **$LT_1$, $LT_2$, $VO_2\max$ i $VLa\max$**: niski $VLa\max$ sprzyja wytrzymałości i wspinaczce GT (wysoka produkcja tlenowa przy niskim mleczanie), wysoki $VLa\max$ daje eksplozywność w klasykach i sprintach.

### 4.2. Forma, Dyspozycja Dnia i Zmęczenie (CTL / ATL / TSB)

- **CTL (Fitness)**, **ATL (Fatigue)**, **TSB (Form = CTL − ATL)** w `RiderHealth`: planuj szczyty formy (`Peak 1 / Peak 2`) na wykresie Gantta (`SeasonCalendarGanttTimeline`), aby na docelowy Wielki Tour lub Monument uzyskać dodatni lub lekko ujemny bilans świeżości bez utraty bazy.
- **Dyspozycja Dnia (`DayConditionAndBiorhythmEngine`)**: losowana codziennie w zakresie **`-5` do `+5`** na podstawie TSB, jakości snu, pogody, morale i lojalności. Ukryta wartość `?` ujawnia się po przekroczeniu progu $LT_1$ na podjeździe.
- **Przetrenowanie i wypalenie (`OvertrainingAndBurnoutDiagnostics`)**: utrzymywanie **`TSB < -35` przez ponad 14 dni** lub przekroczenie **85 dni wyścigowych w sezonie** wywołuje przetrenowanie parasympatyczne: spadek tętna maksymalnego o **`-15 BPM`** oraz spadek FTP o **`-8%`**.
- **Zmęczenie 3. Tygodnia Grand Touru (`GrandTourThirdWeekFatigueDecay`)**: na etapach 14–21 narasta zmęczenie obwodowe i spadek glikogenu wątrobowego; specjaliści GT tracą tylko **2–3% FTP**, podczas gdy kolarze jednodniowi nawet **9–14% FTP**.

### 4.3. Obozy Wysokogórskie i Hipoksja

- **Obozy wysokogórskie (`AltitudeCampAcclimatizationCurve`)**: lokalizacje Sierra Nevada, Teide, Livigno.
  - **Dni 1–5**: faza ostrej adaptacji (chwilowy spadek wydolności).
  - **Dni 7–24**: okno superkompensacji dające **`+3.5%` do $VO_2\max$ oraz szybszą regenerację $W'$**.
- **Hipoksja podczas wyścigu (`HighAltitudeHypoxiaCalculator`)**: powyżej **1500–2000 m n.p.m.** następuje nieliniowy spadek mocy i $VO_2\max$ według krzywej $\Delta P = -0.0085 \cdot \left(\frac{h - 1500}{100}\right)^{1.4}$. Kolarze po obozie wysokogórskim lub pochodzący z Andów (COL/ECU) mają tę karę zredukowaną o połowę.

### 4.4. Termoregulacja, Nawodnienie i Żywienie

- **Temperatura głęboka ciała (`CoreBodyTemperatureThermoregulation`)**: bezpieczny zakres to `37.0°C – 38.8°C`. Powyżej **`39.2°C`** pojawia się dryf tętna (`+12 BPM`) i spadek mocy maksymalnej (limit krytyczny `40.5°C`).
- **Chłodzenie w upale (`IceSocksAndWaterDousingMechanics`, `ThermoregulationAndHydrationHudGauge`)**: w gorące dni używaj rozkazów **Lód na kark (`Ice Sock`)** z wozu technicznego oraz **Polewanie wodą (`Water Douse`)** — obniżają one temperaturę głęboką o **`0.4°C` na 15 minut**. Rozpięcie koszulki poprawia chłodzenie kosztem niewielkiego wzrostu $CdA$.
- **Pot i elektrolity (`SweatSodiumElectrolyteDepletion`)**: kolarz traci `0.8–2.5 l/h` potu i `500–1500 mg/l` sodu. Odwodnienie **`> 3%`** lub brak tabletek elektrolitowych wywołuje bolesne **skurcze (`Muscle Cramps`)**, blokujące sprint na ostatnich kilometrach.
- **Glikogen i „odcięcie prądu” (`NutritionAndGlycogenEngine`, `LiveEnergyExpenditureSparklinesHud`)**: regularnie podawaj żele (`G`) i bidony (`B`). Wyczerpanie zapasów glikogenu powoduje nagły spadek mocy (*bonk*) — obserwuj zegar prognozy odcięcia w panelu `LiveEnergyExpenditureSparklinesHud`.

---

## 5. Lista Kontrolna Wydania (Pre-Release Checklist)

Przed wygenerowaniem paczek produkcyjnych na dowolną platformę wykonaj poniższe kroki w katalogu głównym projektu:

- [ ] **1. Wersja i zależności**: sprawdź pole `version:` w `pubspec.yaml` (np. `0.1.0+1`) i uruchom:
  ```powershell
  flutter pub get
  ```
- [ ] **2. Statyczna analiza kodu**: upewnij się, że `flutter analyze` zwraca zero błędów i zero ostrzeżeń:
  ```powershell
  flutter analyze
  ```
- [ ] **3. Pełny zestaw testów (z bezpiecznym timeoutem 30s)**:
  ```powershell
  flutter test --timeout 30s
  ```
- [ ] **4. Weryfikacja assetów 3D (`.glb`)**: sprawdź integralność plików w `assets/3d/` (nagłówek binarny `glTF`) — wbudowane automatycznie w skrypty wydania lub poprzez `GlbMeshIntegrityValidator`.
- [ ] **5. Audyt responsywności i pamięci**: potwierdź przejście testów `test/ui_responsive_layout_overflow_test.dart` (`390x844`, `1024x768`, `1600x900`) oraz `test/core/memory_and_stream_leak_guard_test.dart`.
- [ ] **6. Testy symulacji i fizyki**: zweryfikuj `test/stress_test_176_riders_storm_cobbles.dart`, `test/physics_and_w_prime_unit_test.dart` oraz `test/career_simulation_full_year_test.dart`.
- [ ] **7. Czystość drzewa Git**: upewnij się, że wszystkie zmiany są zacommitowane (`git status`).

---

## 6. Komendy Kompilacji i Pakowania na Wszystkie Platformy

Projekt posiada gotowe skrypty produkcyjne w katalogu `scripts/`, które automatycznie walidują środowisko, zasoby `.glb`, uruchamiają testy, kompilują aplikację w trybie `--release`, tworzą `BUILD_MANIFEST.txt` oraz generują sumy kontrolne `.sha256`. Poniżej znajdują się zarówno komendy skryptowe, jak i bezpośrednie polecenia Flutter CLI.

### 6.1. Windows (Desktop `.exe` + `.zip`)

**Wymagania**: Windows 10/11 (x64), Visual Studio 2022 z pakietem *Desktop development with C++*, Flutter SDK w `PATH`.

- **Zalecany skrypt produkcyjny (PowerShell)**:
  ```powershell
  .\scripts\build_windows_release.ps1 -Clean -OutputDir "dist\windows"
  ```
  *(Dostępne flagi: `-DryRun`, `-SkipTests`, `-SkipBuild`, `-AllowMissingAssets`, `-Version "0.1.0+1"`)*

- **Bezpośrednia komenda Flutter CLI**:
  ```powershell
  flutter build windows --release
  ```
  Wynikowy plik wykonywalny i biblioteki `.dll` znajdują się w `build\windows\x64\runner\Release\`.

---

### 6.2. macOS (Desktop `.app` / `.dmg`)

**Wymagania**: macOS z zainstalowanym Xcode (Command Line Tools), CocoaPods (`pod`), Flutter SDK.

- **Zalecany skrypt produkcyjny (Bash na macOS)**:
  ```bash
  chmod +x scripts/build_macos_and_ios_release.sh
  ./scripts/build_macos_and_ios_release.sh --target macos --clean --output-dir dist/apple
  ```
  Skrypt kompiluje aplikację natywną oraz pakuje archiwum `.app.zip` (przez `ditto`) i instalator `.dmg` (przez `hdiutil`) wraz z `BUILD_MANIFEST.txt` i `.sha256`.

- **Bezpośrednia komenda Flutter CLI**:
  ```bash
  flutter build macos --release
  ```
  Wynikowy pakiet: `build/macos/Build/Products/Release/pro_peloton_manager.app`.

---

### 6.3. Android (`.apk` split-per-abi + Google Play `.aab`)

**Wymagania**: Android SDK, JDK 17, skonfigurowany podpis wydania (`android/key.properties` dla publikacji w Google Play) oraz włączone `isMinifyEnabled` / `isShrinkResources` w `android/app/build.gradle.kts`.

- **Zalecany skrypt produkcyjny (PowerShell)**:
  ```powershell
  .\scripts\build_android_apk_aab.ps1 -Clean -Obfuscate -OutputDir "dist\android"
  ```
  *(Dostępne flagi: `-SkipApk`, `-SkipAab`, `-SkipTests`, `-DryRun`, `-AllowMissingAssets`)*

- **Bezpośrednie komendy Flutter CLI**:
  ```powershell
  # Zoptymalizowane pakiety APK osobno dla architektur (arm64-v8a, armeabi-v7a, x86_64)
  flutter build apk --release --split-per-abi

  # Pakiet App Bundle (.aab) dla Google Play Store
  flutter build appbundle --release
  ```
  *(Opcjonalnie z obfuskacją kodu Dart: `--obfuscate --split-debug-info=build/app/outputs/symbols`)*

---

### 6.4. iOS / iPadOS (Uniwersalny pakiet `.ipa`)

**Wymagania**: macOS, Xcode z aktywnym kontem Apple Developer oraz profilem provisioning (`app-store`, `ad-hoc`, `development` lub `enterprise`), CocoaPods.

- **Zalecany skrypt produkcyjny (Bash na macOS)**:
  ```bash
  # Budowanie wyłącznie paczki iOS/iPadOS (.ipa)
  ./scripts/build_macos_and_ios_release.sh --target ios --export-method app-store --clean --output-dir dist/apple

  # Lub jednoczesne wydanie macOS + iOS:
  ./scripts/build_macos_and_ios_release.sh --target all --clean --output-dir dist/apple
  ```
  *(Własny plik eksportu można przekazać flagą `--export-options-plist path/to/ExportOptions.plist`)*

- **Bezpośrednia komenda Flutter CLI**:
  ```bash
  flutter build ipa --release --export-method=app-store
  ```
  Wynikowy pakiet `.ipa` trafia do `build/ios/ipa/`.

---

### 6.5. Weryfikacja Końcowa po Kompilacji

1. Sprawdź wygenerowane sumy kontrolne SHA-256 (`.sha256`) oraz raport `BUILD_MANIFEST.txt` w katalogu wyjściowym `dist/`.
2. Uruchom test dymny (smoke test) na docelowym urządzeniu:
   - Start do `MainTitleMenuScreen` → uruchomienie `QuickRaceSandboxScreen` lub kariery → weryfikacja płynności 3D (klawisz `F3`) i poprawnego wczytania tekstur/modeli `.glb`.
   - Zapis i odczyt stanu gry w `SaveLoadSlotsModal` oraz wyjście z wyścigu bez wycieków pamięci (`MemoryAndStreamLeakGuard`).
