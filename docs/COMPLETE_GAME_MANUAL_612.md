# Pro Peloton Manager — Kompletny Przewodnik po 12 Trybach Gry i Systemach Fizycznych (`COMPLETE_GAME_MANUAL_612.md`)

> Oficjalna dokumentacja użytkownika i kompendium techniczne **Pro Peloton Manager** (stan systemu: zadania `#001–#612`, Paczki `#1–#8` + Platinum Apex v3.0 QA). Dokument opisuje wszystkie **12 trybów rozgrywki**, **systemy fizyczne, bioenergetyczne, termoregulacyjne i taktyczne**, a także **sterowanie, skróty klawiszowe oraz narzędzia ekosystemu**.

---

## Spis Treści

1. [Przegląd 12 Trybów Gry](#1-przegląd-12-trybów-gry)
   - [Tryb 1: Kariera Menedżera WorldTour / ProTeam / Continental](#tryb-1-kariera-menedżera-worldtour--proteam--continental)
   - [Tryb 2: Zostań Legendą (Be a Pro — Kariera Pojedynczego Kolarza)](#tryb-2-zostań-legendą-be-a-pro--kariera-pojedynczego-kolarza)
   - [Tryb 3: Kobiecy WorldTour (UCI Women's WorldTour) i Sztafeta Mieszana TTT](#tryb-3-kobiecy-worldtour-uci-womens-worldtour-i-sztafeta-mieszana-ttt)
   - [Tryb 4: Igrzyska Olimpijskie i Selekcjoner Reprezentacji Narodowej](#tryb-4-igrzyska-olimpijskie-i-selekcjoner-reprezentacji-narodowej)
   - [Tryb 5: Zimowy Puchar Przełajowy (Cyclo-Cross / CX)](#tryb-5-zimowy-puchar-przełajowy-cyclo-cross--cx)
   - [Tryb 6: Kolarstwo Torowe na Welodromie 250 m i Rekord Godzinny UCI](#tryb-6-kolarstwo-torowe-na-welodromie-250-m-i-rekord-godzinny-uci)
   - [Tryb 7: Wyścigi Szutrowe (UCI Gravel World Series & Ultra-Gravel)](#tryb-7-wyścigi-szutrowe-uci-gravel-world-series--ultra-gravel)
   - [Tryb 8: Kolarstwo Górskie MTB Cross-Country Olympic (MTB XCO)](#tryb-8-kolarstwo-górskie-mtb-cross-country-olympic-mtb-xco)
   - [Tryb 9: Ultra-Endurance Bikepacking (Transcontinental 4000 km Non-Stop)](#tryb-9-ultra-endurance-bikepacking-transcontinental-4000-km-non-stop)
   - [Tryb 10: Promotor i Organizator Wyścigów (ASO / RCS Empire)](#tryb-10-promotor-i-organizator-wyścigów-aso--rcs-empire)
   - [Tryb 11: Złota Era Kolarstwa (1970–2015) i Scenariusze Historyczne](#tryb-11-złota-era-kolarstwa-19702015-i-scenariusze-historyczne)
   - [Tryb 12: UCI Cycling Esports, Ligi Online ELO i Szybki Wyścig Sandbox](#tryb-12-uci-cycling-esports-ligi-online-elo-i-szybki-wyścig-sandbox)
2. [Systemy Fizyczne Ruchu, Aerodynamiki i Nawierzchni](#2-systemy-fizyczne-ruchu-aerodynamiki-i-nawierzchni)
3. [Fizjologia, Bioenergetyka, Termoregulacja i Żywienie](#3-fizjologia-bioenergetyka-termoregulacja-i-żywienie)
4. [Fizyka Specjalistyczna Dyscyplin Pozaszosowych i Torowych](#4-fizyka-specjalistyczna-dyscyplin-pozaszosowych-i-torowych)
5. [Taktyka Peletonu, AI Rywali, Dyplomacja i Sędziowie UCI / VAR](#5-taktyka-peletonu-ai-rywali-dyplomacja-i-sędziowie-uci--var)
6. [Silnik Renderowania 3D 120 FPS, Audio, Sterowanie i Ekosystem](#6-silnik-renderowania-3d-120-fps-audio-sterowanie-i-ekosystem)

---

## 1. Przegląd 12 Trybów Gry

| # | Tryb Gry | Główny Ekran / Serwis | Kluczowa Mechanika |
|---|---|---|---|
| 1 | **Kariera Menedżera** | `DashboardHqScreen`, `MainShellScreen` | Budżet, transfery, Split-Squad, R&D, NG+ Dynastia |
| 2 | **Zostań Legendą (Be a Pro)** | `BeAProCharacterCreatorScreen`, `BeAProDashboardAndApartmentScreen` | Rozwój 1 kolarza, rozkazy DS, FPP 3D, rezydencje |
| 3 | **Kobiecy WorldTour & Sztafeta Mieszana** | `WomensWorldtourTeamsAndRidersSeeder`, `MixedRelayTttHandoverHudWidget` | 24 drużyny WWT, 360 zawodniczek, przekazanie zmiany TTT |
| 4 | **Igrzyska Olimpijskie & Reprezentacja** | `OlympicGamesHubAndMedalTableScreen`, `NationalTeamSelectionHqScreen` | Cykl 4-letni, brak radia wyścigowego, Złoty Kask/Rama |
| 5 | **Zimowy Puchar Przełajowy (CX)** | `CyclocrossWinterSeriesScreen`, `Cyclocross3dArenaAndBarriersRenderer` | Błoto 0.4–1.8 kg/km, Pit Lane 4.5 s, Bunny-Hop |
| 6 | **Welodrom 250 m & Rekord Godzinny UCI** | `UciHourRecordAttemptScreen`, `TrackOmniumMadisonChampionshipScreen` | Wiraże 42°–45° (1.8G), Keirin, Madison Hand Sling, Omnium |
| 7 | **UCI Gravel World Series & Ultra-Gravel** | `GravelWorldSeriesHubScreen`, `GravelWhiteRoadsAndDust3dRenderer` | 5 kategorii nawierzchni, Tubeless Sealant, strefy Oasis |
| 8 | **MTB Cross-Country Olympic (XCO)** | `MtbXcoWorldCupScreen`, `MtbForestRockGarden3dRenderer` | Zawieszenie 100–120 mm, Dropper Post, linie A/B-Line |
| 9 | **Ultra-Endurance Bikepacking 4000 km** | `UltraBikepackingTranscontinentalScreen`, `NightRidingHeadlightAndStars3dRenderer` | Dotwatching GPS, rytm dobowy snu, piasta z dynamem |
| 10 | **Organizator Wyścigów (ASO / RCS)** | `RaceOrganizerHqDashboardScreen`, `HostCityBiddingAuctionModal` | Przetargi miast, prawa TV, Appearance Fees, bariery SafeR |
| 11 | **Złota Era (1970–2015) & Scenariusze** | `GoldenEraRetroCampaignsScreen`, `TacticalChallengesHubScreen` | Skala Borg RPE 6–20, stalowe ramy, brak radia, filtr 16mm/VHS |
| 12 | **UCI Cycling Esports & Ligi Online** | `CyclingEsportsAndVirtualAcademyScreen`, `MultiplayerLeaguesAndChallengesScreen` | Power-Upy, eliminacja co 60 s, ELO, duchy i `.ppmleague` |

---

### Tryb 1: Kariera Menedżera WorldTour / ProTeam / Continental

Pełna symulacja zarządzania zawodową drużyną kolarską w wielosezonowym kalendarzu UCI (`SeasonCalendar`, `CareerStateNotifier`).

- **Start i Konfiguracja Realizmu**:
  - Wybór drużyny w `NewCareerSetupScreen` lub jednego z 4 gotowych scenariuszy szybkiego startu (`DemoSavePresetBuilder`: *Polski Projekt WT*, *Pojedynek Tytanów w Alpach*, *Kampania Brukowana*, *Imperium Galaktyczne*).
  - Konfiguracja **14 flag realizmu** i indeksu realizmu `0–100` w `CareerRealismCustomizerPanel` (`AppFeatureFlagsAndPresets`).
  - Styczniowa **Gala Prezentacji Drużyny** (`PreSeasonTeamPresentationScreen`, `PreSeasonTeamPresentationEvent`) z deklaracją celów sezonowych, prezentacją transferów i koszulek oraz **Ceremonią Prezentacji Tras Wielkich Tourów** (`GrandTourRouteRevealCeremonyScreen`).
- **Zarządzanie Kadrą, Sztabem i Infrastrukturą**:
  - **Skład i Hierarchia**: `SquadRosterScreen`, `TeamBuilderHierarchyScreen`, kontrola przepisów UCI (`RosterUciComplianceValidator`: limit 7/8 kolarzy, min. waga roweru `6.80 kg`), rozdzielanie 28-osobowej kadry i floty 30 rowerów na dwa równoległe wyścigi w tym samym dniu (**Split-Squad**: `MultiRaceParallelDaySimulator`, `SplitSquadCalendarAssignmentModal`).
  - **Rozbudowa Bazy (Service Course HQ)**: 5 działów po 5 poziomów w `ServiceCourseHqFacilityScreen` (`TeamServiceCourseHqUpgrades`: Tunel Aero, Centrum Hipoksji, Flota Autobusów, Warsztat Wosku, Akademia Skautingu).
  - **Własna Marka Rowerowa R&D**: `InHouseBikeBrandFactoryScreen` (`InHouseBikeBrandModel`) umożliwia projektowanie własnych ram w CAD 2D, badania karbonu, sprzedawanie licencji B2B innym drużynom oraz czerpanie przychodów detalicznych.
  - **Globalne Akademii Satelickie i Skauting**: 8 regionalnych siatek skautingowych (`RegionalScoutingNetworksService`) oraz 4 akademie satelickie (Kolumbia, Afryka Wschodnia, Flandria, Sierra Nevada) w `GlobalAcademyNetworkMapScreen`.
  - **Finanse, Sponsorzy i Ekonomia ESG**: Negocjacje tytularne (`SponsorPitchDeckNegotiationModal`), nadzwyczajne bonusy CEO (`SponsorBonusNegotiationEvents`), przychody z praw TV (`TvBroadcastRightsRevenueSharingService`), sklep klubowy i Fan Zones (`TeamMerchandiseAndFanClubRevenue`), a także zarządzanie flotą EV/FCEV i bilansem $\text{CO}_2$ (`EsgSustainabilityAndFleetScreen`, `TeamEsgSustainabilityAndGreenFleetModel`).
  - **Rynek Transferowy i Deadline Day**: Klauzule kontraktowe (`AgentContractClausesEngine`: *Guaranteed GT Leadership*, *Equipment Veto*), negocjacje na żywo (`ContractNegotiationChatSimulator`), dziennikarze i przecieki (`TransferRumorMillAndJournalistsService`) oraz studio na żywo **Transfer Deadline Day** (`TransferDeadlineDayLiveEventService`, `TransferDeadlineDayTickerModal`).
  - **Psychologia, Życie Osobiste i Relacje**: Pamięć urazów i wendety (`AiRivalryGrudgeMemoryService`), mentoring weteranów (`RiderMentorshipAndTutoringService`), wydarzenia rodzinne i urlopy ojcowskie (`RiderPersonalLifeAndFamilyEventsService`), złamane obietnice i bunty w szatni (`BrokenPromisesLockerRoomRevolt`).
  - **Zwieńczenie Kariery i New Game+**: Gala **Vélo d'Or** (`VeloDorGalaCeremonyScreen`), interaktywne podsumowanie roku **Season Wrapped** (`PostSeasonInteractiveYearInReviewStory`), drzewko perków menedżera (`ManagerSkillTreePerksService`), emerytura do **Księgi Legendy** ze złotymi tłoczeniami `#D4AF37` oraz tryb **Dynastii / New Game+** (`ManagerLegacyHallOfFameBookScreen`, `EndOfCareerHallOfFameRetirementService`).

---

### Tryb 2: Zostań Legendą (Be a Pro — Kariera Pojedynczego Kolarza)

Tryb RPG skupiony na karierze jednego zawodnika — od 19-letniego juniora w drużynie U23/Continental aż po zwycięzcę Wielkich Tourów (`ProCyclistCareerState`).

- **Kreator Kolarza** (`BeAProCharacterCreatorScreen`):
  - Dobór wzrostu (`160–198 cm`), wagi (`52–86 kg`) z automatycznym wyliczaniem powierzchni czołowej $CdA$ i predyspozycji fizjologicznych (`BeAProPhysicsCalculator`).
  - Wybór jednego z **5 archetypów genetycznych**, personalizacja wyglądu 3D (twarz, fryzura, okulary, kolor butów) oraz podpisanie pierwszego kontraktu U23/Continental.
- **Apartament, Rozwój i Życie Prywatne** (`BeAProDashboardAndApartmentScreen`, `ProCyclistLifestyleAndWealthService`):
  - Wydawanie punktów doświadczenia (XP/SP) w drzewku umiejętności (`BeAProSkillNode`), komunikacja SMS z Dyrektorem Sportowym i agentem, gablota trofeów.
  - Zakup rezydencji w kolarskich stolicach (Girona, Andora, Livigno, Monako, Flandria, Sierra Nevada), inwestycja w namiot hipoksyjny, prywatnego dietetyka/osteopatę, osobistych sponsorów (okulary, buty, zegarek) oraz portfel inwestycyjny.
- **Rozkazy DS i Sterowanie Bezpośrednie 3D**:
  - Podczas etapu gracz realizuje misje zlecane przez Dyrektora Sportowego (`DsTeamOrdersMissionGenerator`, np. wjazd w Top 15 na sektorze Arenberg, praca w pociągu przy `380 W`, zdobycie 5 pkt KOM), zdobywając `dsTrustScore` i awansując z roli **Młodego Pomocnika** na **Wolnego Elektrona** i **Lidera Drużyny**.
  - Śledzenie celów w HUD (`BeAProDsObjectiveHudTracker` ze strzałką kierunkową 3D do lidera) oraz opcjonalna kamera **First Person Cockpit** (`FirstPersonCockpitCameraRenderer`) i ręczne sterowanie kolarzem (`DirectPlayerRiderSteeringController`: `W/S` moc/biegi, `A/D` luki w peletonie, `Shift` sprint, `Spacja` *Snap to Wheel*).

---

### Tryb 3: Kobiecy WorldTour (UCI Women's WorldTour) i Sztafeta Mieszana TTT

Kompletna symulacja kobiecego peletonu zawodowego oraz widowiskowej konkurencji mistrzowskiej sztafety mieszanej (`WomensWorldtourTeamsAndRidersSeeder`, `MixedRelayRaceState`).

- **Kobiecy Peleton**: 24 drużyny (**15 Women's WorldTeams**, **6 Pro**, **3 Continental**) i **360 zawodniczek** z dedykowaną kalibracją fizjologiczną (`WomensPhysiologyProfile`), osobnym kalendarzem, klasyfikacjami UCI/U23 oraz rynkiem transferowym.
- **Drużynowa Sztafeta Mieszana TTT** (`MixedRelayTttHandoverHudWidget`):
  - Wyścig dwuetapowy: pierwsza zmiana (3 mężczyzn) przekazuje wirtualną pałeczkę drugiej zmianie (3 kobiet) w strefie bramki przekazania.
  - Obowiązuje **zasada 2. zawodnika** (czas drużyny mierzy się na drugim kolarzu przekraczającym linię) oraz automatyczna **kara falstartu +15 s** przy przedwczesnym opuszczeniu rampy przed przecięciem fotokomórki przez pierwszą zmianę.

---

### Tryb 4: Igrzyska Olimpijskie i Selekcjoner Reprezentacji Narodowej

Rywalizacja o medale w barwach narodowych, rozłączona z interesami klubowymi (`OlympicGamesQuadrennialCycleService`, `NationalFederationTeamManagerService`).

- **Cykl 4-letni Igrzysk Olimpijskich** (`OlympicGamesHubAndMedalTableScreen`):
  - Limity kadrowe UCI/MKOl: maksymalnie **4 kolarzy w wyścigu ze startu wspólnego (RR)** i **2 w jeździe indywidualnej na czas (ITT)**.
  - **Zasada No Race Radio**: Brak słuchawek i łączności z wozem technicznym — taktyka na trasie opiera się wyłącznie na obserwacji rywali, tabliczkach z motocykla i intuicji kolarzy (`OlympicNoRaceRadioRules`).
  - Nagroda prestiżowa: Mistrz Olimpijski otrzymuje **Złoty Kask i Złotą Ramę (`#D4AF37`)** na kolejne **4 lata** (`OlympicChampionGoldGear`).
- **Biuro Selekcjonera Reprezentacji** (`NationalTeamSelectionHqScreen`, `NationalTeamCustomKits3dRenderer`):
  - Powoływanie kadry na Mistrzostwa Świata i Igrzyska z uwzględnieniem kwot federacji, konfliktów ego między gwiazdami rywalizujących klubów, negocjacji zwolnień z zespołów WorldTour oraz oficjalnych strojów narodowych w 3D.

---

### Tryb 5: Zimowy Puchar Przełajowy (Cyclo-Cross / CX)

Zimowa rywalizacja na krótkich, intensywnych rundach `2.5–3.2 km` od listopada do stycznia, zintegrowana z rozwojem szosowym (`CyclocrossWinterSeriesScreen`, `CyclocrossCourseAndMudModel`).

- **Kalendarz**: 8 kultowych rund zimowych zwieńczonych Mistrzostwami Świata CX (`CyclocrossWinterCalendarCatalog`).
- **Specyfika Toru 3D** (`Cyclocross3dArenaAndBarriersRenderer`): Taśmy wyznaczające kręty tor, belki przeszkodowe, schody, ławice głębokiego piasku (wzorowane na Koksijde/Zonhoven), namioty kibiców i podwójny boks techniczny **Double Pit Lane**.
- **Premia do Kariery Szosowej**: Starty zimowe podnoszą atrybuty `bikeHandling`, `cobbles` oraz moc beztlenową `1m` i `5m` przed wiosenną kampanią klasyków.

---

### Tryb 6: Kolarstwo Torowe na Welodromie 250 m i Rekord Godzinny UCI

Rywalizacja pod dachem na lakierowanym parkiecie z drewna syberyjskiego z wirażami o nachyleniu `42°–45°` (`VelodromeWoodenBowl3dRenderer`).

- **Próba Bicia Rekordu Godzinnego UCI** (`UciHourRecordAttemptScreen`, `VelodromeTrackAndHourRecordModel`):
  - Wybór obiektu (welodrom nizinny np. Grenchen vs wysokogórski Aguascalientes w Meksyku o niższej gęstości powietrza $\rho$).
  - Dobór przełożenia roweru ostrokołowego (`58T–64T` x `13T–15T`) oraz strategii tempa (**Równe Tempo** vs **Negative Split**), z zielonym laserem wirtualnego rekordu i certyfikatem po upływie `60:00.00`.
- **Mistrzostwa Torowe** (`TrackOmniumMadisonChampionshipScreen`, `VelodromeMadisonHandSling3dRenderer`):
  - **Keirin**: Prowadzenie za motocyklem Derny do `50 km/h`, zjazd Derny i finałowy sprint `750 m`.
  - **Madison**: Wyścig parami ze zmianami w locie za rękę (**Hand Sling**) i punktacją sprinterską co 10 okrążeń.
  - **Omnium (4 konkurencje)** oraz **Wyścig Punktowy**.

---

### Tryb 7: Wyścigi Szutrowe (UCI Gravel World Series & Ultra-Gravel)

Długodystansowe ściganie poza asfaltem w reżimie samowystarczalności (`GravelWorldSeriesHubScreen`, `GravelRaceAndSurfaceModel`).

- **Kalendarz i Nawierzchnie**: 7-rundowy cykl na **5 kategoriach nawierzchni** (od białych dróg *Sterrato* po luźny szuter, kamienie i bazalt) z gęstymi chmurami pyłu 3D i progresywnym brudzeniem kolarzy (`GravelWhiteRoadsAndDust3dRenderer`, `MudAndDustSplatterAccumulation`).
- **Sprzęt i Reguły Self-Supported** (`GravelBikeAndTireInsertsModel`):
  - Konfiguracja opon `38–50 mm`, wkładek piankowych `Foam Tire Inserts` (tryb awaryjny *Run-Flat*), mleczka `Tubeless Sealant` oraz plecaków nawadniających `Aero Hydration Pack`.
  - Planowanie punktów wsparcia w strefach **Oasis** (`GravelOasisPlannerCalculator`) oraz obowiązkowy zestaw naprawczy z nabojami $\text{CO}_2$ do samodzielnej naprawy defektów na poboczu.

---

### Tryb 8: Kolarstwo Górskie MTB Cross-Country Olympic (MTB XCO)

Techniczne wyścigi Pucharu Świata na rundach `4.2 km` przez leśne dukty, korzenie, dropy i kamieniste sekcje **Rock Garden** (`MtbXcoWorldCupScreen`, `MtbForestRockGarden3dRenderer`).

- **Konfigurator Zawieszenia i Opon**:
  - Wybór architektury ramy (`Hardtail` vs `Full-Suspension 100–120 mm`), precyzyjne ustawienie ciśnienia widelca i dampera (**SAG %**, tłumienie odbicia *rebound*, tokeny objętościowe), zdalna blokada skoku (`SuspensionLockoutMode`), sztyca regulowana **Dropper Post** oraz opony `2.4"` (`MtbXcoCourseAndSuspensionModel`).
- **Taktyka Linii Przejazdu**: Wybór między szybką, ale ryzykowną linią **A-Line** (skoki, głazy, wyższe ryzyko defektu/kraksy przy zmęczeniu) a bezpieczniejszą i dłuższą linią **B-Line**.

---

### Tryb 9: Ultra-Endurance Bikepacking (Transcontinental 4000 km Non-Stop)

Ekstremalna próba wytrzymałościowa przez kontynent w formule samowystarczalnej non-stop (`UltraBikepackingTranscontinentalScreen`, `UltraEnduranceBikepackingRaceModel`).

- **Dotwatching Live Tracker**: Mapa GPS w czasie rzeczywistym z punktami kontrolnymi (CP) i śladem rywali.
- **Zarządzanie Snem i Nocą**:
  - Planowanie bloków jazdy, dawek kofeiny oraz wyborów noclegowych (**Bivy / śpiwór na poboczu** vs **Hotel**).
  - Jazda nocna 3D (`NightRidingHeadlightAndStars3dRenderer`) z oświetleniem LED, odblaskami drogowymi i gwiaździstym niebem.
  - **Zarządzanie Energią Elektroniki**: Torby bikepackingowe (`BikepackingLoadout`) oraz piasta z dynamem (`DynamoHubSpec`) ładująca licznik GPS i lampkę przy prędkości jazdy.

---

### Tryb 10: Promotor i Organizator Wyścigów (ASO / RCS Empire)

Odwrócenie perspektywy — zarządzanie imperium wyścigowym zamiast drużyną (`RaceOrganizerHqDashboardScreen`, `RaceOrganizerEmpireModel`).

- **Przetargi Miast Gospodarzy** (`HostCityBiddingAuctionModal`): Organizacja aukcji i negocjacji z miastami ubiegającymi się o *Grand Départ* lub metę górską HC.
- **Finanse i Prawa TV**: Księga budżetowa organizatora, sprzedaż praw telewizyjnych na rynki globalne, kontrola prestiżu UCI (`2.UWT`).
- **Projektowanie Tras i Gwiazdy Peletonu**:
  - Dobór profilu trasy (dla górali GC vs sprinterów) i negocjacja opłat startowych (**Appearance Fees**) przyciągających największe gwiazdy (`StarRiderAppearanceFeeNegotiator`).
  - **Bezpieczeństwo SafeR**: Rozmieszczanie barier energochłonnych (`Boplan Air-Cushion Barriers`), siatek asekuracyjnych i marshali na niebezpiecznych zjazdach i finiszach (`CourseSafetyBarriersAndMarshalsPlanner`).

---

### Tryb 11: Złota Era Kolarstwa (1970–2015) i Scenariusze Historyczne

Podróż w czasie do minionych dekad kolarstwa szosowego oraz 10 kultowych wyzwań taktycznych (`GoldenEraRetroCampaignsScreen`, `TacticalChallengesHubScreen`).

- **Kampania Historyczna Retro** (`GoldenEraRetroSeasonModel`):
  - Wybór dekady (lata 70., 80., 90., 2000–2015) z historycznymi przepisami: **brak radia wyścigowego**, **brak mierników mocy** (zamiast watów gracz korzysta ze skali odczuwanego wysiłku **Borg RPE 6–20**), ciężkie ramy stalowe z chromowanymi mufami, wełniane koszulki nasiąkające deszczem, czapeczki *casquette*, bidony na kierownicy oraz filtr transmisji TV **16mm / VHS / Sepia** (`RetroSepiaFilmGrainAndSteelBikes3dRenderer`).
- **Scenariusze Historyczne i Wyzwania Taktyczne** (`LegendaryHistoricScenariosSeeder`):
  - 10 grywalnych scenariuszy taktycznych z celami brązowego, srebrnego i złotego medalu (`#D4AF37`) oraz lokalną tablicą rekordów czasowych.

---

### Tryb 12: UCI Cycling Esports, Ligi Online ELO i Szybki Wyścig Sandbox

Nowoczesna rywalizacja wirtualna, asynchroniczny multiplayer oraz otwarte laboratorium taktyczne.

- **UCI Cycling Esports** (`CyclingEsportsAndVirtualAcademyScreen`, `UciCyclingEsportsWorldModel`):
  - Wyścigi w neonowo-szklanym **Cyber-Welodromie 3D** (`EsportsCyberVelodromeAndHologram3dEngine`) z kalibracją trenażerów Smart (`Dual-Recording`, tryby `SIM` / `ERG` / `Virtual Shifting`).
  - Strategiczne **Power-Upy** aktywowane przy bramach (*Aero Helmet*, *Featherweight*, *Burrito*, *Draft Boost*, *Steamroller*), wyścig eliminacyjny (**Elimination co 60 s**) oraz nabór talentów do **Virtual Talent ID Academy**.
- **Ligi Online, ELO i Wyzwania Duchów** (`MultiplayerLeaguesAndChallengesScreen`, `AsyncMultiplayerLeagueSyncService`):
  - Tworzenie lig ze znajomymi, sesje draftu kolarzy, globalny ranking **ELO** (`EloDivisionTier`), rywalizacja z zapisem przejazdu innych graczy (**Ghost Challenge** z półprzezroczystym złotym hologramem 3D `GhostRiderHologram3dRenderer`) oraz wymiana plików ligowych `.ppmleague`.
- **Szybki Wyścig / Sandbox 3D** (`QuickRaceSandboxScreen`):
  - Natychmiastowy test dowolnego scenariusza w 3-kolumnowym układzie Bento: wybór trasy, siły wiatru (`0–70 km/h`), pogody, `Auto-Pick Optimal Roster` i presetów sprzętowych wprost do widoku 3D.

---

## 2. Systemy Fizyczne Ruchu, Aerodynamiki i Nawierzchni

Silnik fizyczny działa deterministycznie w izolowanym wątku (`IsolateSimulationWorker` + `StageSimulationLoop`) w oparciu o ziarno `stageSeed` (`DeterministicRngSeedManager`) i stałe `PhysicsConstants` ($g = 9.80665\text{ m/s}^2$, $\rho_0 = 1.225\text{ kg/m}^3$, skala wysokości $H = 8500\text{ m}$).

### 2.1 Równanie Ruchu (`SpeedSolver` & `GravityAndRollingCalculator`)
- Hybrydowy solver Newtona-Raphsona z bisekcją rozwiązuje bilans sił w każdym kroku $\Delta t$:
  $$m_{total} \cdot a = F_{prop} - (F_{grav} + F_{roll} + F_{aero}) - F_{brake}$$
- Straty mechaniczne napędu: łańcuch woskowany **2.0%** ($\eta = 0.980$), smar standardowy **2.8%** ($\eta = 0.972$), napęd brudny/zużyty **3.5%** ($\eta = 0.965$).
- Opory toczenia $C_{rr}$ skalują się z chropowatością asfaltu, systemem `tubeless` oraz szerokością i ciśnieniem opony (`TirePressureCalculator`).

### 2.2 Strefowa Aerodynamika CFD i Podmuchy Boczne
- **CFD w Czasie Rzeczywistym** (`RealTimeCfdVortexAndDragSolver`, `CfdWindTunnelHeatmap3dPainter`):
  - Analiza 6 stref oporu (kask, przedramiona, tekstylia, rama, koła przednie/tylne), **reguła 105%** (dopasowanie szerokości opony do obręczy), **efekt żagla** przy wietrze skośnym oraz generacja ścieżki wirów Kármána.
  - Przekłada się bezpośrednio na komparator $\Delta CdA$ w Tunelu Aerodynamicznym (`WindTunnelCdaDeltaComparator`).
- **Stabilność Kół na Wietrze Bocznym** (`CrosswindWheelStabilityAndGustSolver`):
  - Wysokie stożki karbonowe (`65–80 mm`) generują wyższy moment skręcający na przednim kole ($\tau_{steer}$) i znoszenie boczne przy nagłych podmuchach — wymagają wysokiego `bikeHandling` lub zmiany na niższy profil obręczy.
- **Cień za Kolumną Wyścigową (`Caravan Drafting`)** (`DraftingBehindTeamCarAndMotosSolver`):
  - Powrót po kraksie lub defekcie za motocyklami TV i wozami technicznymi (*Car-Hopping*) daje ogromny zysk aero, ale buduje ryzyko kary czasowej UCI w `CaravanDraftingRiskMeterHud`.

### 2.3 Bruk, Kadencja, Zakręty i Zjazdy
- **Ugięcie Opon na Bruku 1★–5★** (`CobbleTirePressureRealTimeDeflection`):
  - Modeluje kompromis między stratami histerezy (zbyt niskie ciśnienie) a stratami impedancyjnymi od drgań (zbyt wysokie ciśnienie) na sektorach takich jak *Trouée d'Arenberg* (2.4 km).
- **Kadencja i Przełożenia** (`CadenceAndGearingEfficiencySolver`, `DrivetrainGearingConfiguration`):
  - Wybór tarcz (`50/34T` do `58T 1x`) i kaset 12s (`11-28T` do `10-36T`). Zbyt twarde przełożenie na stromym podjeździe (np. `18%` poniżej `60 RPM`) powoduje **+18% kosztu glikogenu** i przyspieszone zmęczenie włókien szybkokurczliwych Typu II.
- **Straty Kinetyczne w Zakrętach i Przyczepność na Mokrym** (`BrakingZoneKineticEnergyLossSolver`, `WetCorneringGripAndBrakingSolver`):
  - W kryteriach i krętych czasówkach cięższe koła tracą więcej energii obrotowej na każdym dohamowaniu.
  - Maksymalna prędkość w zakręcie $v_{max} = \sqrt{\mu \cdot g \cdot R}$ spada z $\mu \approx 0.85$ (suchy asfalt) do $\mu \approx 0.55$ (mokry asfalt) i $\mu \approx 0.40$ (mokry bruk).
- **Ataki na Zjazdach i Supertuck** (`DescenderAttackAndSupertuckPhysics`, `AltitudeDescentAirDensityTransition`):
  - Kolarze o `descending >= 85 && bikeHandling >= 85` mogą stosować późne hamowanie i agresywne pozycje aero na zjazdach, zyskując `25–45 s` na 15 km przy ciągłej ($C^1$) zmianie gęstości powietrza $\rho(h, T)$.

---

## 3. Fizjologia, Bioenergetyka, Termoregulacja i Żywienie

### 3.1 Model Skiba $W'$ i Profil Mleczanowy
- `WPrimeBalanceEngine` symuluje zużycie baterii beztlenowej $W'$ (w kJ) przy mocy powyżej progu krytycznego ($CP / FTP$) oraz jej wykładniczą regenerację poniżej $CP$.
- `LactateAndLabProfile` definiuje progi **$LT_1$**, **$LT_2$**, **$VO_2max$** oraz **$VLaMax$** (maksymalna produkcja mleczanu — kluczowa dla sprinterów vs górali wytrzymałościowych).
- `PedalStrokeBiomechanicsAnalyzer` analizuje obrót korby $0^\circ–360^\circ$ (balans L/R, *Torque Effectiveness* TE%, *Pedal Smoothness* PS%, wykres biegunowy *Peanut Diagram*).

### 3.2 Termoregulacja, Chłodzenie i Elektrolity
- **Temperatura Głęboka Ciała** (`CoreBodyTemperatureThermoregulation`):
  - Zakres `37.0°C – 40.5°C` na bazie bilansu ciepła metabolicznego $\dot{Q}_{prod} = P \cdot \frac{1-\eta}{\eta}$, chłodzenia konwekcyjnego $\dot{Q}_{conv} \propto v^{0.6}$ oraz parowania potu. Powyżej `39.2°C` następuje dryf tętna (`+12 BPM`) i spadek mocy maksymalnej.
- **Chłodzenie Aktywne** (`IceSocksAndWaterDousingMechanics`):
  - Rozkaz pobrania woreczka z lodem (`Ice Sock`) lub polania głowy wodą obniża temperaturę głęboką o `0.4°C` na 15 minut.
- **Odwodnienie i Sód** (`SweatSodiumElectrolyteDepletion`):
  - Pocenie `0.8–2.5 l/h` i utrata sodu `500–1500 mg/l`. Przekroczenie `>3%` odwodnienia lub brak tabletek elektrolitowych grozi skurczami (**Muscle Cramps**) blokującymi sprint na finiszu.

### 3.3 Żywienie, Suplementacja WorldTour, Hipoksja i Zmęczenie
- **Nowoczesna Suplementacja** (`CarbohydrateHydrogelAndKetonesEngine`, `NutritionAndGlycogenEngine`):
  - `Standard 60g/h CHO`, `High-Carb Hydrogel 110g/h` (zależny od `gutTrainingLevel`, ryzyko *GI Distress*), `Bicarbonate Pre-Load` przed czasówkami (**+6% $W'$**) oraz `Post-Finish Exogenous Ketones` (**+12% regeneracji nocnej**).
  - W Dniu Przerwy posiłkami i mikrobiomem zarządza Szef Kuchni (`TeamBusChefAndMicrobiomeNutritionService`).
- **Wysokość i Obozy Wysokogórskie** (`HighAltitudeHypoxiaCalculator`, `AltitudeCampAcclimatizationCurve`):
  - Powyżej `1500–2000 m n.p.m.` następuje nieliniowy spadek $VO_2max$ i FTP (łagodzony o połowę przez obozy w Sierra Nevada / Teide / Livigno w oknie superkompensacji dni `7–24`).
- **Zmęczenie 3. Tygodnia, Dyspozycja Dnia i Przetrenowanie**:
  - `GrandTourThirdWeekFatigueDecay` obniża FTP na etapach 14–21 (`2–3%` u specjalistów GT vs `9–14%` u klasykowców).
  - `DailyRiderDayFormVarianceEngine` ("The Legs" `-3..+3` diamenty) losuje formę dnia odkrywaną w pierwszych `30 km` etapu.
  - `OvertrainingAndBurnoutDiagnostics` wykrywa wypalenie przy `TSB < -35` przez >14 dni lub >85 dni wyścigowych (`-15 BPM` MaxHR, `-8%` FTP).

---

## 4. Fizyka Specjalistyczna Dyscyplin Pozaszosowych i Torowych

- **Cyclo-Cross (CX)**: `CxPitBikeExchangeMechanics` symuluje oblepianie roweru błotem (`0.4–1.8 kg/km`, `+12 W/km` oporu napędu) oraz wymianę na czysty rower w Pit Lane (`4.5 s`). `CyclocrossBunnyhopAndCarrySolver` porównuje bieg z rowerem na ramieniu (`12–16 km/h`) ze skokiem *Bunny-Hop* nad belkami (`bikeHandling >= 85`, zysk `+1.8 s/rundę`, ryzyko zahaczenia przy $W' < 15\%$).
- **Welodrom 250 m**: `VelodromeBankingAndCentripetalSolver` oblicza siłę odśrodkową $a_c = v^2 / R$ (do `1.8G` zwiększającą efektywną masę i opór toczenia w wirażach) oraz karę dystansu przy wyjeździe ponad czarną linię pomiarową (`250.0 m -> 258.5 m`). `VelodromeKeirinAndMadisonSlingSolver` modeluje transfer pędu podczas rzutu *Hand Sling*.
- **Gravel**: `GravelRollingResistanceAndSealantSolver` oblicza zapadanie opony w luźnym żwirze oraz szanse samonaprawy przebicia przez mleczko Tubeless i wkładki *Foam Inserts*.
- **MTB XCO**: `MtbSuspensionDampingAndLineChoiceSolver` oblicza straty energii na *Pedal Bob* i *Chatter* w zależności od blokady skoku oraz bilans ryzyko/czas między linią **A-Line** a **B-Line**.
- **Ultra-Bikepacking**: `UltraSleepDeprivationAndCircadianSolver` symuluje dług snu (*Sleep Debt*), krzywą rytmu dobowego Borbély'ego, wpływ kofeiny oraz bilans energetyczny piasty z dynamem.
- **Retro 1970–2015**: `RetroSteelFrameAndNoPowermeterSolver` przekłada generowaną moc na subiektywną skalę **Borg RPE (6–20)** i symuluje opóźnienie mechaniczne manetek na dolnej rurze ramy.
- **e-Sports**: `EsportsSmartTrainerErgAndPowerupsSolver` zarządza mnożnikami Power-Upów, kontrolą Dual-Recording i progami eliminacji co 60 s.

---

## 5. Taktyka Peletonu, AI Rywali, Dyplomacja i Sędziowie UCI / VAR

### 5.1 Ruch Ciągły Peletonu i Walka z Wiatrem
- **Boids 60 FPS** (`BoidsSteeringCollisionAvoidance`, `BoidsPelotonFlockingSolver`): Separacja bez kolizji (`1.85 x 0.65 m`), szukanie cienia aerodynamicznego (`DraftSeeking`), wyprzedzanie i efekt akordeonu na zakrętach.
- **Wachlarze i Spychanie pod Krawężnik** (`EchelonCrosswindEngine`, `TeamSprintTrainEchelonDiagonalFormation`): Formowanie diagonalnego pociągu na wietrze bocznym spychającego rywali w tzw. **In the Gutter** (widoczne na diagramie `GutterWindProtectionDiagramHud` i radarze `TvEchelonCrosswindRadarHud`).

### 5.2 Zaawansowane Algorytmy Taktyczne AI
- **Równowaga Ucieczki** (`BreakawayVsPelotonEquilibriumSolver`) oraz **Reakcja Kryzysowa GC** (`GcTimeGapPanicThresholdAi`: przy rywalu `<4 min` GC w odjeździe AI natychmiast wystawia 4 pomocników na `88% FTP`).
- **Stacje Przekaźnikowe** (`SatelliteRiderRelayTacticsEngine`): Wysłanie pomocnika do porannej ucieczki, rozkaz `Wait for GC Leader` na przedostatniej przełęczy i wspólne ciągnięcie w dolinie.
- **Blokowanie Drogi** (`DomestiqueRoadBlockingMechanics`): Spowalnianie pogoni na wąskich drogach (`<4.5 m`) przy `65% FTP`.
- **Grupetto / Autobus** (`GrupettoAutobusSurvivalAi`): 40-osobowa grupa pod wodzą Kapitana wyliczającego tempo na limit czasu **OTL** z 3-minutowym zapasem (z ostrzeżeniem `OtlTimeCutWarningBannerHud`).
- **Sprint i Finisz**: Rozprowadzanie (`SprintTrainAiController`), surfowanie po kołach rywali (`SprinterTrainCounterSurfingAi`), efekt **procy aerodynamicznej** na ostatnich `250 m` (`SprintLeadoutAerodynamicSlingshot`, do `72–76 km/h`) oraz rzut rowerem na kreskę (**Bike Throw**: `+18–28 cm`, `FinishLineBikeThrowPhysics`, `BikeThrowTimingMinigameOverlay`) z rozstrzygnięciem fotofiniszu co do `0.001 s` (`PhotoFinishReplayWidget`).
- **Blef i Pasywność**: `WheelsuckingAndBluffingAiLogic` (*Skip Pulls / Sit On*, *Poker Face*).

### 5.3 Dyplomacja, Etykieta, Sędziowie UCI i Pogoda Ekstremalna
- **Dyplomacja na Szosie** (`InRacePelotonDiplomacyEngine`, `InRaceDiplomacyRadioModal`): Zawieranie paktów *Stage for GC Deal*, *Anti-Leader Coalition*, *Neutralization Truce* oraz konsekwencje zdrady (`Betrayal!`).
- **Niepisane Zasady Peletonu** (`NatureBreakAndPelotonEtiquetteEngine`): *Nature Break*, zawieszenie ataków po kraksie lidera poza strefą finałową (`<25 km`) oraz etykieta strefy bufetu.
- **Kolegium Sędziów UCI i VAR** (`CommissaireJuryPenaltiesEngine`, `UciCommissaireRulebookAndVarModel`): Kary czasowe `+20 s` (*Sticky Bottle*), grzywny w CHF, żółte kartki oraz wideoanaliza z lotu ptaka **Sprint Deviation VAR** (`SprintVarOverheadReplayInspector`) na ostatnich 200 m.
- **Protokół Pogody Ekstremalnej** (`RaceProtestAndCourseRerouteEngine`, `UciExtremeWeatherProtocolModal`): Artykuł UCI `2.2.029bis`, głosowanie kolarzy (CPA) i skrócenie lub zmiana trasy etapu w przypadku śnieżycy lub osuwiska.
- **Radar Dopplera Live** (`WeatherRadarLiveForecastShiftEngine`, `LiveWeatherDopplerRadarMinimap`): Adwekcja komórek burzowych z prognozą `+15 / +30 / +60 min`.

---

## 6. Silnik Renderowania 3D 120 FPS, Audio, Sterowanie i Ekosystem

### 6.1 Potok 3D Zero-GC 120 FPS (`Peloton3dCanvasEngine`)
- **Optymalizacja Pamięci**: `RenderObjectPoolManager` (prealokowane bufory `Float64List` dla 176 kolarzy, 352 kół i 890 cząsteczek bez alokacji GC), `SpatialHashGrid1d2d` (koszyki co 5 m, O(N) `<0.4 ms/klatkę`), `FrustumAndDistanceCuller` (`>450 m`) oraz proceduralny atlas PBR w RAM (`ProceduralPbrTextureAtlasGenerator`).
- **Realizm Wizualny i Animacje**: Dwustawowy solver IK (`InverseKinematicsLimbSolver`), kołysanie roweru na stojąco *en danseuse* (`StandingBikeRockingPhysics3d`), deformacja styku opony i błyski szprych (`TireDeformationAndSpokeGlintFx`), para wodna z ust `<10°C` i pot `>28°C` (`ColdBreathVaporAndSweatSheen`), mokry asfalt z odbiciami (`WetAsphaltReflectionsPainter`), dynamiczne niebo od świtu po złotą godzinę (`SunriseSunsetSkyDomeEngine`), cienie chmur, tunel kibiców z flarami (`AlpineCrowdTunnelRenderer`), napisy kredą na asfalcie oraz 6 animacji zwycięstwa (`VictorySaluteCelebrationAnimator`).
- **Audio i Haptyka**: Przestrzenne panoramowanie 3D (`Spatial3dPelotonAudioPanner`), 5-kanałowy mikser pejzażu dźwiękowego (`SoundscapeMixerController`), synteza radia drużynowego (`TeamRadioVoiceSynthesisAndChatterEngine`) oraz wibracje haptyczne (`HapticFeedbackVibrationController`) na bruku 5★, przy kraksach i zmianie biegów.

### 6.2 Sterowanie, Skróty Klawiszowe i Kontrolery
- **Klawiatura (Widok 3D & Menedżer)** (`KeyboardShortcutsManager`):
  - `Spacja` — Pauza / Wznów wyścig
  - `1–4` — Tempo symulacji (`1x`, `2x`, `4x`, `8x`)
  - `W / S` — Zwiększ / zmniejsz moc i przełożenia (w trybie sterowania bezpośredniego)
  - `A / D` — Ruch poprzeczny / szukanie luk w peletonie
  - `Shift` — Sprint na stojąco / *Watt Bomb*
  - `Alt + Space` — Paleta szybkich komend radia wyścigowego (`VoiceCommandQuickActionsPalette`)
  - `Ctrl + K` — Globalna wyszukiwarka **Spotlight** (`GlobalSearchSpotlightModal`)
  - `F3` — Nakładka profilera FPS/RAM (`PerformanceProfilerOverlay`)
  - `F11` — Pełny ekran Desktop (`WindowsDesktopWindowConfig`)
  - `F12` — Tryb zrzutów ekranu (`Screenshot Mode`)
- **Kontrolery Gamepad** (`ControllerGamepadInputMapper`): Pełne mapowanie dla **Xbox**, **PlayStation DualSense** (z oporem adaptacyjnych spustów) oraz **Steam Deck**.
- **Ergonomia Mobilna**: Tryb obsługi jedną ręką (`MobileOneHandedThumbHudMode`) oraz pełna responsywność UI na `390x844` (Mobile), `1024x768` (Tablet) i `1600x900` (Desktop).

### 6.3 Narzędzia Dodatkowe, Modding i Eksport
- **Konsola Wozu Technicznego (Dual-Screen)** (`CompanionCarDashboardScreen`, `DualScreenTelemetryWallServer`): Podłączenie drugiego ekranu/tabletu przez lokalny serwer WebSocket/HTTP jako 3-monitorowe centrum dyrektora sportowego.
- **Kino Powtórek i Tryb Fotograficzny 3D** (`RaceReplayDirectorTheaterScreen`, `PhotoMode3dCameraStudioOverlay`): Analiza powtórek klatka po klatce, *Aero Vision* oraz kamera Free-Fly 24–200 mm z efektem Bokeh.
- **Eksport Danych**: Telemetria etapu do `.gpx` (GPX 1.1) i `.tcx` (Garmin TCX v2) (`GpxAndTcxTelemetryExporter`), Kronika Kariery do `.html` / `.md` (`CareerAlmanacHtmlReportExporter`), archiwa zapisów `.ppmsave.gz` z sumą `FNV-1a64`+`CRC-32` i tokenami `PPMCS1:` (`CloudCrossSaveJsonSyncAdapter`).
- **Edytory i Warsztat Modów**: Kreator etapów (`StageEditorCreatorScreen`), Edytor Bazy Danych i Składów (`InGameDatabaseRosterEditorScreen`), paczki etapów `.ppmstage` (`CommunityStagePackSharingService`) oraz paczki modów `.ppmmod` (`ModWorkshopValidatorAndPackager`).
- **Dostępność i Języki**: Natychmiastowe przełączanie **PL / EN** (`BilingualCyclingDictionary`, `AppLocalizationsPlEn`) oraz **4 palety dla daltonistów** (*Protanopia*, *Deuteranopia*, *Tritanopia*, *Achromatopsia*) z podwójnym kodowaniem kształtami (`ColorblindAccessibilityPalettes`).
