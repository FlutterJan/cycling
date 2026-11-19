# Pro Peloton Manager — Kompletna Encyklopedia i Instrukcja Rozgrywki (`COMPLETE_GAME_MANUAL_712.md`)

> Oficjalna encyklopedia użytkownika oraz kompendium techniczne **Pro Peloton Manager** (stan systemu: zadania `#001–#712`, Paczki `#1–#10` + Titanium Imperial v5.0 QA). Dokument opisuje wszystkie **14 trybów rozgrywki**, **systemy fizyczne, bioenergetyczne, biologiczno-medyczne i taktyczne**, a także **silnik 3D 120 FPS, audio, sterowanie, analitykę BI, przepisy UCI/CAS oraz narzędzia ekosystemu**.

---

## Spis Treści

1. [Przegląd 14 Trybów Gry](#1-przegląd-14-trybów-gry)
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
   - [Tryb 13: UCI Para-Cycling World Cup & Igrzyska Paralimpijskie](#tryb-13-uci-para-cycling-world-cup--igrzyska-paralimpijskie)
   - [Tryb 14: Reżyser Transmisji Telewizyjnej na Żywo (TV Broadcast Director)](#tryb-14-reżyser-transmisji-telewizyjnej-na-żywo-tv-broadcast-director)
2. [Systemy Fizyczne Ruchu, Aerodynamiki, Termiki Hamulców i Nawierzchni](#2-systemy-fizyczne-ruchu-aerodynamiki-termiki-hamulców-i-nawierzchni)
3. [Biologia, Fizjologia, Nocne HRV i Medycyna Grand Tourowa](#3-biologia-fizjologia-nocne-hrv-i-medycyna-grand-tourowa)
4. [Fizyka Specjalistyczna Dyscyplin Pozaszosowych, Torowych i Para-Cycling](#4-fizyka-specjalistyczna-dyscyplin-pozaszosowych-torowych-i-para-cycling)
5. [Taktyka Peletonu, Psychologia Szatni 2.0, AI DS, Kontrole X-Ray UCI i Trybunał CAS](#5-taktyka-peletonu-psychologia-szatni-20-ai-ds-kontrole-x-ray-uci-i-trybunał-cas)
6. [Silnik Renderowania 3D 120 FPS, Audio, Sterowanie i Ekosystem BI](#6-silnik-renderowania-3d-120-fps-audio-sterowanie-i-ekosystem-bi)

---

## 1. Przegląd 14 Trybów Gry

| # | Tryb Gry | Główny Ekran / Serwis | Kluczowa Mechanika |
|---|---|---|---|
| 1 | **Kariera Menedżera** | `DashboardHqScreen`, `MainShellScreen` | Budżet, transfery, Split-Squad, Americas/Oceania, Obóz Aero, BI, Potrójna Korona, NG+ |
| 2 | **Zostań Legendą (Be a Pro)** | `BeAProCharacterCreatorScreen`, `BeAProDashboardAndApartmentScreen` | Rozwój 1 kolarza, rozkazy DS, FPP 3D, rezydencje, transfer QR |
| 3 | **Kobiecy WorldTour & Sztafeta Mieszana** | `WomensWorldtourTeamsAndRidersSeeder`, `MixedRelayTttHandoverHudWidget` | 24 drużyny WWT, 360 zawodniczek, przekazanie zmiany TTT |
| 4 | **Igrzyska Olimpijskie & Reprezentacja** | `OlympicGamesHubAndMedalTableScreen`, `NationalTeamSelectionHqScreen` | Cykl 4-letni, brak radia wyścigowego, Złoty Kask/Rama, stroje narodowe |
| 5 | **Zimowy Puchar Przełajowy (CX)** | `CyclocrossWinterSeriesScreen`, `Cyclocross3dArenaAndBarriersRenderer` | Błoto 0.4–1.8 kg/km, Pit Lane 4.5 s, Bunny-Hop |
| 6 | **Welodrom 250 m & Rekord Godzinny UCI** | `UciHourRecordAttemptScreen`, `TrackOmniumMadisonChampionshipScreen` | Wiraże 42°–45° (1.8G), Keirin, Madison Hand Sling, Omnium |
| 7 | **UCI Gravel World Series & Ultra-Gravel** | `GravelWorldSeriesHubScreen`, `GravelWhiteRoadsAndDust3dRenderer` | 5 kategorii nawierzchni, Tubeless Sealant, strefy Oasis |
| 8 | **MTB Cross-Country Olympic (XCO)** | `MtbXcoWorldCupScreen`, `MtbForestRockGarden3dRenderer` | Zawieszenie 100–120 mm, Dropper Post, linie A/B-Line |
| 9 | **Ultra-Endurance Bikepacking 4000 km** | `UltraBikepackingTranscontinentalScreen`, `NightRidingHeadlightAndStars3dRenderer` | Dotwatching GPS, rytm dobowy snu, piasta z dynamem |
| 10 | **Organizator Wyścigów (ASO / RCS)** | `RaceOrganizerHqDashboardScreen`, `HostCityBiddingAuctionModal` | Przetargi miast, prawa TV, Appearance Fees, bariery SafeR |
| 11 | **Złota Era (1970–2015) & Scenariusze** | `GoldenEraRetroCampaignsScreen`, `TacticalChallengesHubScreen` | Skala Borg RPE 6–20, stalowe ramy, brak radia, filtr 16mm/VHS |
| 12 | **UCI Cycling Esports & Ligi Online** | `CyclingEsportsAndVirtualAcademyScreen`, `MultiplayerLeaguesAndChallengesScreen` | Power-Upy, eliminacja co 60 s, ELO, duchy i `.ppmleague` |
| 13 | **UCI Para-Cycling & Igrzyska Paralimpijskie** | `UciParacyclingWorldCupScreen`, `TandemAndHandbike3dMeshRenderer` | Tandemy Klasy B (>800 W), Handbike H1–H5, Rowery C1–C5, sztafeta |
| 14 | **Reżyser Transmisji TV na Żywo** | `TvBroadcastDirectorControlRoomScreen`, `TvDirectorLiveProductionModel` | 12 kamer na trasie, szyna `PREVIEW`/`PROGRAM OUT`, grafiki TV, oglądalność |

---

### Tryb 1: Kariera Menedżera WorldTour / ProTeam / Continental

Pełna symulacja zarządzania zawodową drużyną kolarską w wielosezonowym kalendarzu UCI (`SeasonCalendar`, `CareerStateNotifier`).

- **Start i Konfiguracja Realizmu**:
  - Wybór drużyny w `NewCareerSetupScreen` lub jednego z 4 gotowych scenariuszy szybkiego startu (`DemoSavePresetBuilder`: *Polski Projekt WT*, *Pojedynek Tytanów w Alpach*, *Kampania Brukowana*, *Imperium Galaktyczne*).
  - Konfiguracja **14 flag realizmu** i indeksu realizmu `0–100` w `CareerRealismCustomizerPanel` (`AppFeatureFlagsAndPresets`).
  - Styczniowa **Gala Prezentacji Drużyny** (`PreSeasonTeamPresentationScreen`, `PreSeasonTeamPresentationEvent`) oraz **Ceremonia Prezentacji Tras Wielkich Tourów** (`GrandTourRouteRevealCeremonyScreen`).
  - **Grudniowy Obóz Aerodynamiczny** (`WinterWindTunnelCampScreen`, `PreSeasonWindTunnelCampEvent`): przedsezonowe testy w tunelu aero (*Silverstone Sports Engineering Hub* / *A2 Wind Tunnel*) dla 6 kluczowych kolarzy (3 pozycje TT, kaski, kombinezony, pomiar oporu w Newtonach przy `50 km/h`) trwale obniżające bazowe $CdA$ na cały sezon.
- **Globalna Ekspansja Kalendarza UCI (Ameryki, Oceania, Afryka, Azja i Europa Środkowa)**:
  - **Americas & Oceania Expansion** (`AmericasAndOceaniaToursModel`): *Santos Tour Down Under* w Australii (upały `38–43°C`, *Willunga Hill*), *Cadel Evans Great Ocean Road Race* (nadmorski wiatr boczny), *Tour Colombia 2.1*, *Vuelta a San Juan* (start na `2500 m`, podjazd na *Alto del Colorado* `3265 m n.p.m.`) oraz kanadyjskie klasyki *GP Cycliste de Québec & Montréal*.
  - **Rynki Wschodzące i Europa Środkowa**: *Tour du Rwanda* (*Mur de Kigali*), *Tour de Langkawi*, *Tour of Oman*, *AlUla Tour* (`GlobalExoticToursExpansionModel`) oraz pełny 7-etapowy **Tour de Pologne** i 5 wyścigów regionu (`TourDePologneAndCentralEuropePack`).
- **Zarządzanie Kadrą, Wypożyczeniami, Sztabem i Infrastrukturą**:
  - **Skład, Hierarchia i Split-Squad**: `SquadRosterScreen`, `TeamBuilderHierarchyScreen`, kontrola przepisów UCI (`RosterUciComplianceValidator`), rozdzielanie 28-osobowej kadry i floty 30 rowerów na dwa równoległe wyścigi w tym samym dniu (`MultiRaceParallelDaySimulator`, `SplitSquadCalendarAssignmentModal`).
  - **Wypożyczenia Juniorów (Loan System)** (`JuniorDevelopmentLoanSystemService`, `RiderLoanManagementModal`): wypożyczanie 19-letnich talentów z 28-osobowej kadry WorldTour na 1 sezon do partnerskich ekip ProTeam/Continental (z gwarancją dni wyścigowych, podziałem pensji i opcją natychmiastowego ściągnięcia przy kontuzjach).
  - **Mikrocykle Treningowe i Obóz Juniorów**: `WeeklyTrainingMicrocyclePlannerScreen` (`CustomTrainingMicrocycleBuilderService`) z prognozą Banistera CTL/ATL/TSB oraz coroczny obóz `TalentCombineTryoutsScreen` (`YouthTalentSummerCombineCampService`).
  - **Baza (Service Course HQ), Muzeum 3D i Własna Marka R&D**: 5 działów po 5 poziomów (`ServiceCourseHqFacilityScreen`), **Muzeum Klubowe 3D** (`ClubMuseumAndLegendaryBikesScreen`, `EquipmentWindTunnelCustomDecalsAndSerialsService`) z numerami seryjnymi ram i sprzętem mistrzowskim (`CyclistOlympicAndWorldChampionCustomGear`), oraz **Własna Marka Rowerowa R&D** (`InHouseBikeBrandFactoryScreen`, `InHouseBikeBrandModel`).
  - **Globalne Akademii Satelickie**: 8 regionalnych siatek skautingowych oraz 4 akademie satelickie (Kolumbia, Afryka Wschodnia, Flandria, Sierra Nevada) w `GlobalAcademyNetworkMapScreen`.
- **Finanse, VIP Hospitality, ESG i Analityka BI**:
  - Negocjacje tytularne (`SponsorPitchDeckNegotiationModal`), **Obsługa Gości VIP Sponsora** (`TeamSponsorHospitalityVipEvents`, `VipHospitalityGuestCardModal`: strefa VIP na *Paris-Roubaix* / *Champs-Élysées*, przejazd w wozie DS), sponsorzy z rynków wschodzących (`GlobalSponsorMarketExpansionService`), prawa TV, sklep klubowy, flota EV/FCEV i bilans $\text{CO}_2$ (`EsgSustainabilityAndFleetScreen`).
  - **Analityka BI** (`DeepCareerAnalyticsBiScreen`, `CareerStatisticsDeepAnalyticsExporter`): ROI transferów i projektów R&D, symulator What-If R&D, eksport CSV/JSON.
- **Kontrakty, Psychologia Szatni 2.0, Potrójna Korona i New Game+**:
  - **Wrześniowe Centrum Przedłużeń Kontraktów** (`ContractRenewalsWarRoomScreen`, `EndOfSeasonContractExtensionWindow`): przegląd umów wygasających 31 grudnia, alerty o ofertach rywali, prognoza budżetu płacowego.
  - Klauzule kontraktowe, plotki transferowe i studio **Transfer Deadline Day** (`TransferDeadlineDayLiveEventService`).
  - **Psychologia Szatni 2.0** (`RiderRelationshipChemistryWebModel`, `TeamChemistryRelationshipWebWidget`, `TeamBondingRetreatAndConflictMediationService`): macierz relacji `-100..+100`, pakt lojalności *Blood Brothers*, mediacje, mentoring.
  - **Baza Zwycięzców i Potrójna Korona** (`HistoricalGrandTourWinnersTimelineDb`, `TripleCrownLegendTrophyBanner`): wieloletnia kronika zwycięzców GT, Monumentów i MŚ ze złoto-tęczowym trofeum za **Potrójną Koronę Kolarstwa** (Giro + Tour + MŚ w jednym roku), gala **Vélo d'Or**, **Księga Legendy** i **New Game+** (`ManagerLegacyHallOfFameBookScreen`).

---

### Tryb 2: Zostań Legendą (Be a Pro — Kariera Pojedynczego Kolarza)

Tryb RPG skupiony na karierze jednego zawodnika — od 19-letniego juniora U23/Continental aż po zwycięzcę Wielkich Tourów (`ProCyclistCareerState`).

- **Kreator Kolarza** (`BeAProCharacterCreatorScreen`): dobór wzrostu (`160–198 cm`), wagi (`52–86 kg`) z automatycznym wyliczaniem $CdA$ (`BeAProPhysicsCalculator`), wybór 1 z **5 archetypów genetycznych**, personalizacja 3D i pierwszy kontrakt.
- **Apartament, Rozwój, Życie Prywatne i Transfer QR** (`BeAProDashboardAndApartmentScreen`, `ProCyclistLifestyleAndWealthService`, `CareerSaveCloudQrCodeTransfer`, `QrRosterShareCardModal`): drzewko XP/SP, SMS od DS i agenta, rezydencje (Girona, Andora, Livigno, Monako, Flandria, Sierra Nevada), namiot hipoksyjny, prywatny dietetyk/osteopata, osobisty sponsor oraz błyskawiczny transfer profilu między PC a telefonem przez kod QR / token Base64.
- **Rozkazy DS i Sterowanie Bezpośrednie 3D**: misje w wyścigu (`DsTeamOrdersMissionGenerator`), awans `dsTrustScore`, widok **First Person Cockpit** (`FirstPersonCockpitCameraRenderer`) lub **OnBoard Action Cam 140°** (`OnBoardBikeMountedActionCam3d`) oraz ręczne sterowanie (`DirectPlayerRiderSteeringController`: `W/S`, `A/D`, `Shift`, `Spacja`).

---

### Tryb 3: Kobiecy WorldTour (UCI Women's WorldTour) i Sztafeta Mieszana TTT

- **Kobiecy Peleton** (`WomensWorldtourTeamsAndRidersSeeder`): 24 drużyny (**15 Women's WorldTeams**, **6 Pro**, **3 Continental**) i **360 zawodniczek** z dedykowaną kalibracją fizjologiczną (`WomensPhysiologyProfile`), osobnym kalendarzem, klasyfikacjami UCI/U23 i transferami.
- **Drużynowa Sztafeta Mieszana TTT** (`MixedRelayTttHandoverHudWidget`, `MixedRelayRaceState`): pierwsza zmiana (3 mężczyzn) przekazuje wirtualną pałeczkę drugiej zmianie (3 kobiet); obowiązuje **zasada 2. zawodnika** oraz **kara falstartu +15 s**.

---

### Tryb 4: Igrzyska Olimpijskie i Selekcjoner Reprezentacji Narodowej

- **Cykl 4-letni Igrzysk Olimpijskich** (`OlympicGamesHubAndMedalTableScreen`, `OlympicGamesQuadrennialCycleService`): limity kadrowe UCI/MKOl (**4 kolarzy RR**, **2 ITT**), zasada **No Race Radio** (brak słuchawek i łączności z wozem), a dla Mistrza Olimpijskiego **Złoty Kask, złota owijka i złote detale ramy (`#D4AF37`)** na kolejne **4 lata** (`CyclistOlympicAndWorldChampionCustomGear`), podobnie jak biała rama i kask z tęczą dla Mistrza Świata UCI.
- **Biuro Selekcjonera Reprezentacji** (`NationalTeamSelectionHqScreen`, `NationalFederationTeamManagerService`, `NationalTeamCustomKits3dRenderer`): powołania na MŚ i IO z uwzględnieniem kwot federacji, konfliktów ego, negocjacji zwolnień z klubów oraz oficjalnych strojów narodowych w 3D.

---

### Tryb 5: Zimowy Puchar Przełajowy (Cyclo-Cross / CX)

- **Kalendarz i Arena 3D**: 8 kultowych rund zimowych (listopad–styczeń) zwieńczonych Mistrzostwami Świata CX (`CyclocrossWinterSeriesScreen`, `Cyclocross3dArenaAndBarriersRenderer`): kręte trasy `2.5–3.2 km` z taśmami, belkami, schodami, ławicami piasku Koksijde/Zonhoven i podwójnym boksem **Double Pit Lane**.
- **Premia do Kariery Szosowej**: podnosi atrybuty `bikeHandling`, `cobbles` oraz moc `1m` i `5m` przed wiosenną kampanią klasyków.

---

### Tryb 6: Kolarstwo Torowe na Welodromie 250 m i Rekord Godzinny UCI

- **Próba Bicia Rekordu Godzinnego UCI** (`UciHourRecordAttemptScreen`, `VelodromeTrackAndHourRecordModel`): welodrom nizinny (Grenchen) vs wysokogórski (Aguascalientes), przełożenie ostrego koła (`58T–64T` x `13T–15T`), strategia *Równe Tempo* vs *Negative Split*, zielony laser wirtualnego rekordu i certyfikat po `60:00.00`.
- **Mistrzostwa Torowe** (`TrackOmniumMadisonChampionshipScreen`, `VelodromeMadisonHandSling3dRenderer`): **Keirin** (Derny do `50 km/h` + sprint `750 m`), **Madison** (zmiany w locie *Hand Sling*), **Omnium (4 konkurencje)** i **Wyścig Punktowy**.

---

### Tryb 7: Wyścigi Szutrowe (UCI Gravel World Series & Ultra-Gravel)

- **Kalendarz i Nawierzchnie** (`GravelWorldSeriesHubScreen`, `GravelRaceAndSurfaceModel`): 7-rundowy cykl na **5 kategoriach nawierzchni** (od *Sterrato* po luźny szuter i bazalt) z chmurami pyłu 3D i brudzeniem kolarzy (`GravelWhiteRoadsAndDust3dRenderer`, `MudAndDustSplatterAccumulation`).
- **Sprzęt i Reguły Self-Supported** (`GravelBikeAndTireInsertsModel`): opony `38–50 mm`, wkładki `Foam Tire Inserts`, mleczko `Tubeless Sealant`, plecaki `Aero Hydration Pack`, strefy **Oasis** i naprawa $\text{CO}_2$ na poboczu.

---

### Tryb 8: Kolarstwo Górskie MTB Cross-Country Olympic (MTB XCO)

- **Trasa i Zawieszenie** (`MtbXcoWorldCupScreen`, `MtbXcoCourseAndSuspensionModel`, `MtbForestRockGarden3dRenderer`): rundy `4.2 km` z korzeniami, dropami i sekcjami **Rock Garden**; ramy `Hardtail` vs `Full-Suspension 100–120 mm`, regulacja SAG %, tłumienia odbicia, tokenów, zdalny Lockout, **Dropper Post** i opony `2.4"`.
- **Taktyka Linii**: wybór między ryzykowną linią **A-Line** a bezpieczniejszą **B-Line**.

---

### Tryb 9: Ultra-Endurance Bikepacking (Transcontinental 4000 km Non-Stop)

- **Dotwatching, Sen i Elektronika** (`UltraBikepackingTranscontinentalScreen`, `UltraEnduranceBikepackingRaceModel`): mapa GPS z punktami kontrolnymi (CP), planowanie bloków jazdy, dawek kofeiny, noclegów (**Bivy** vs **Hotel**), jazda nocna 3D ze stożkiem światła LED i Drogą Mleczną (`NightRidingHeadlightAndStars3dRenderer`) oraz piasta z dynamem ładująca elektronikę.

---

### Tryb 10: Promotor i Organizator Wyścigów (ASO / RCS Empire)

- **Zarządzanie Imperium Wyścigowym** (`RaceOrganizerHqDashboardScreen`, `RaceOrganizerEmpireModel`): aukcje miast gospodarzy (`HostCityBiddingAuctionModal`), sprzedaż praw TV, kontrola prestiżu UCI (`2.UWT`), projektowanie tras, negocjacje *Appearance Fees* gwiazd oraz rozmieszczanie barier energochłonnych **SafeR** (`CourseSafetyBarriersAndMarshalsPlanner`).

---

### Tryb 11: Złota Era Kolarstwa (1970–2015) i Scenariusze Historyczne

- **Kampania Historyczna Retro** (`GoldenEraRetroCampaignsScreen`, `GoldenEraRetroSeasonModel`): dekady 70., 80., 90. i 2000–2015 bez radia i bez miernika mocy (skala **Borg RPE 6–20**), stalowe ramy z manetkami na dolnej rurze, wełniane koszulki oraz filtr TV **16mm / VHS / Sepia** (`RetroSepiaFilmGrainAndSteelBikes3dRenderer`).
- **Scenariusze Historyczne** (`TacticalChallengesHubScreen`, `LegendaryHistoricScenariosSeeder`): 10 kultowych wyzwań taktycznych z medalami brązowym, srebrnym i złotym (`#D4AF37`).

---

### Tryb 12: UCI Cycling Esports, Ligi Online ELO i Szybki Wyścig Sandbox

- **UCI Cycling Esports** (`CyclingEsportsAndVirtualAcademyScreen`, `UciCyclingEsportsWorldModel`): **Cyber-Welodrom 3D** (`EsportsCyberVelodromeAndHologram3dEngine`), trenażery Smart (`Dual-Recording`, `SIM`/`ERG`/`Virtual Shifting`), Power-Upy (*Aero Helmet*, *Featherweight*, *Burrito*, *Draft Boost*, *Steamroller*), eliminacja co `60 s` i **Virtual Talent ID Academy**.
- **Ligi Online, ELO i Duchy** (`MultiplayerLeaguesAndChallengesScreen`, `AsyncMultiplayerLeagueSyncService`): ligi ze znajomymi, draft, ranking **ELO**, wyzwania duchów 3D (`GhostRiderHologram3dRenderer`) i paczki `.ppmleague`.
- **Szybki Wyścig / Sandbox 3D** (`QuickRaceSandboxScreen`): natychmiastowy test dowolnej trasy, wiatru (`0–70 km/h`), pogody i składu.

---

### Tryb 13: UCI Para-Cycling World Cup & Igrzyska Paralimpijskie

- **Klasy Sportowe** (`UciParacyclingWorldCupScreen`, `UciParacyclingTandemHandbikeModel`):
  - **Tandem Klasy B**: pilot + stoker z łączną mocą `>800 W` i zjazdami `>95 km/h` (`TandemCrewPairing`).
  - **Handbike H1–H5**: trójkołowe rowery napędzane ręcznie (pozycja leżąca H1–H4 vs klęcząca H5).
  - **Rowery C1–C5** oraz **Sztafeta Drużynowa Handbike Team Relay** w limicie **11 punktów klasyfikacyjnych**.

---

### Tryb 14: Reżyser Transmisji Telewizyjnej na Żywo (TV Broadcast Director)

Nowy tryb inspirowany pracą reżysera sygnału międzynarodowego Tour de France (`TvBroadcastDirectorControlRoomScreen`, `TvDirectorLiveProductionModel`).

- **Reżyserka Telewizyjna (`PROGRAM OUT` & `PREVIEW`)**:
  - Sterowanie **12 niezależnymi kamerami na trasie**: 3 śmigłowce (`HeliCam 1/2/3`), motocykle (`MotoCam Front/Peloton/Chase`), kamery pokładowe (`OnBoard Handlebars Cam`), meta (`Finish Line Overhead`) i wnętrze wozu technicznego (`Team Car Interior`).
  - Dolny rząd **6 monitorów podglądu na żywo** z kluczowych sektorów wyścigu, natychmiastowe przełączanie ujęć przyciskami `CUT` oraz `DISSOLVE`.
- **Grafiki Ekranowe, Oglądalność i Budżet Produkcyjny**:
  - Ręczne wyzwalanie grafik na antenie: porównanie **W/kg dwóch liderów**, interaktywny **profil podjazdu 3D**, powtórki w zwolnionym tempie (**Slow-Mo**) i tablice różnic czasowych.
  - Wskaźnik **Live TV Viewership & Drama Rating (`0–100`)**: oglądalność rośnie w czasie rzeczywistym, gdy reżyser łapie decydujące ataki, kraksy i sprinty, a spada przy przestojach (*Dead Air*) lub przekroczeniu budżetu produkcyjnego.

---

## 2. Systemy Fizyczne Ruchu, Aerodynamiki, Termiki Hamulców i Nawierzchni

Silnik fizyczny działa deterministycznie w izolowanym wątku (`IsolateSimulationWorker` + `StageSimulationLoop`) w oparciu o ziarno `stageSeed` (`DeterministicRngSeedManager`) i stałe `PhysicsConstants` ($g = 9.80665\text{ m/s}^2$, $\rho_0 = 1.225\text{ kg/m}^3$, skala wysokości $H = 8500\text{ m}$).

### 2.1 Równanie Ruchu (`SpeedSolver` & `GravityAndRollingCalculator`)
- Hybrydowy solver Newtona-Raphsona z bisekcją rozwiązuje bilans sił w każdym kroku $\Delta t$:
  $$m_{total} \cdot a = F_{prop} - (F_{grav} + F_{roll} + F_{aero}) - F_{brake}$$
- Straty mechaniczne napędu: łańcuch woskowany **2.0%** ($\eta = 0.980$), smar standardowy **2.8%** ($\eta = 0.972$), napęd brudny/zużyty **3.5%** ($\eta = 0.965$).
- Opory toczenia $C_{rr}$ skalują się z chropowatością asfaltu, temperaturą nawierzchni (do $58^\circ\text{C}$ w upale), systemem `tubeless` oraz ciśnieniem opony (`TirePressureCalculator`).

### 2.2 Strefowa Aerodynamika CFD, Asymetryczny Stożek Wachlarza 35° i Rynsztok
- **CFD w Czasie Rzeczywistym** (`RealTimeCfdVortexAndDragSolver`, `CfdWindTunnelHeatmap3dPainter`):
  - Analiza 6 stref oporu (kask, przedramiona, tekstylia, rama, koła przednie/tylne), **reguła 105%**, **efekt żagla** przy wietrze skośnym oraz ścieżka wirów Kármána.
- **Asymetryczny Stożek Cienia w Wachlarzu 35°** (`AerodynamicCrossDraftingEchelonVortex`, `EchelonVortexConeVisualizer3d`):
  - Przy wietrze bocznym strefa cienia aerodynamicznego przesuwa się na zawietrzną stronę od tylnego koła poprzedzającego kolarza: pozycja w przesuniętym stożku daje **38% redukcji oporu**, podczas gdy jazda bezpośrednio za kołem daje zaledwie **12%**.
- **Stabilność Kół na Wietrze Bocznym i Ryzyko Rynsztoka**:
  - `CrosswindWheelStabilityAndGustSolver` modeluje moment skręcający ($\tau_{steer}$) wysokich stożków `65–80 mm`.
  - `CrosswindPelotonGutterCollisionRisk` oblicza ryzyko zjechania na pobocze przy wyprzedzaniu w ciasnym rynsztoku (*In the Gutter*).
- **Cień za Kolumną Wyścigową (`Caravan Drafting`)** (`DraftingBehindTeamCarAndMotosSolver`):
  - Powrót po kraksie za motocyklami TV i wozami technicznymi (*Car-Hopping*) z rosnącym ryzykiem kary UCI w `CaravanDraftingRiskMeterHud`.

### 2.3 Termika Tarcz Hamulcowych (`Brake Fade`), Kąt Przechyłu, Bruk i Klimat Ekstremalny
- **Termika Tarcz Hamulcowych i `Brake Fade`** (`BrakeRotorHeatAndFadeDescentSolver`, `GlowingBrakeRotorsAndTireSmoke3d`):
  - Modeluje nagrzewanie tarcz **`140 mm` vs `160 mm`** przy dohamowaniach przed serpentynami z `85 km/h` do `25 km/h`. Przegrzanie powyżej **$450^\circ\text{C}$** wywołuje zjawisko **Brake Fade** (spadek siły hamowania i wydłużenie drogi hamowania), wizualizowane w 3D czerwoną poświatą tarcz oraz dymem i piskiem zblokowanej tylnej opony.
- **Kąt Przechyłu w Zakrętach i G-Force** (`RiderCenterOfMassAndCornerLeanAngle`, `CornerGForceAndLeanAngleTelemetryHud`):
  - Wylicza kąt przechyłu $\theta_{lean} = \arctan\left(\frac{v^2}{g \cdot R}\right)$ (do **$42^\circ$** na suchym asfalcie) z balansowaniem kolanem do wewnątrz zakrętu oraz telemetrią przeciążenia bocznego w widokach *OnBoard Action Cam* i *FPP Cockpit*.
- **Ugięcie Opon na Bruku 1★–5★** (`CobbleTirePressureRealTimeDeflection`): balans między stratami histerezy a impedancji na sektorach takich jak *Trouée d'Arenberg*.
- **Kadencja i Przełożenia** (`CadenceAndGearingEfficiencySolver`, `DrivetrainGearingConfiguration`): tarcze `50/34T–58T 1x`, kasety `11-28T–10-36T`; mielenie `<60 RPM` na `18%` kosztuje **+18% glikogenu**.
- **Straty Kinetyczne i Przyczepność na Mokrym** (`BrakingZoneKineticEnergyLossSolver`, `WetCorneringGripAndBrakingSolver`): $v_{max} = \sqrt{\mu \cdot g \cdot R}$ ($\mu_{dry} \approx 0.85$, $\mu_{wet} \approx 0.55$, $\mu_{wet\_cobble} \approx 0.40$).
- **Ataki na Zjazdach i Supertuck** (`DescenderAttackAndSupertuckPhysics`, `AltitudeDescentAirDensityTransition`): zysk `25–45 s` na 15 km zjazdu przy `descending >= 85 && bikeHandling >= 85` i ciągłej ($C^1$) gęstości $\rho(h, T)$.
- **Wilgotność Tropikalna 95% i Pustynny Piasek** (`TropicalHumidityAndDesertSandstormSolver`): uwzględnia WBGT, wilgotne $\rho$ i nawiany piasek zwiększający $C_{rr}$.

---

## 3. Biologia, Fizjologia, Nocne HRV i Medycyna Grand Tourowa

### 3.1 Model Skiba $W'$, Profil Mleczanowy i Adaptacja TT
- `WPrimeBalanceEngine`: zużycie baterii beztlenowej $W'$ (kJ) powyżej $CP / FTP$ i jej wykładnicza regeneracja poniżej $CP$.
- `LactateAndLabProfile`: progi **$LT_1$**, **$LT_2$**, **$VO_2max$**, **$VLaMax$**; `PedalStrokeBiomechanicsAnalyzer` analizuje obrót korby $0^\circ–360^\circ$ (balans L/R, TE%, PS%, *Peanut Diagram*).
- **Adaptacja Pozycji TT i Motor-Pacing** (`MotorPacingAndAeroTuckAdaptation`, `AeroVsRoadPowerEfficiencyGauge`): poprawa retencji mocy na lemondce poprzez treningi za skuterem/Derny (redukcja okluzji biodrowej, detraining po >10 dniach).

### 3.2 Ekstremalne Wysokości `>3000 m n.p.m.` i Fale Upałów `>40°C`
- **Solver Wysokościowy i Upałów** (`ExtremeAltitude3000mAndHeatwaveSolver`, `HighAltitudeHypoxiaCalculator`):
  - Powyżej **`2800 m n.p.m.`** (np. *Alto del Colorado* `3265 m`) spadek ciśnienia parcjalnego tlenu $\text{PaO}_2$ wydłuża stałą czasową regeneracji $\tau_{W'}$ o **+45%** (~2x wolniejsze odzyskiwanie $W'$ po ataku).
  - W australijskim upale **`>40°C`** (*Tour Down Under*) asfalt nagrzewa się do **$58^\circ\text{C}$**, podnosząc $C_{rr}$ o **+8%** i wymagając podwójnego nawadniania.
- **Termoregulacja, Chłodzenie i Elektrolity** (`CoreBodyTemperatureThermoregulation`, `IceSocksAndWaterDousingMechanics`, `SweatSodiumElectrolyteDepletion`): temperatura głęboka `37.0°C – 40.5°C` (dryf `+12 BPM` powyżej `39.2°C`), chłodzenie *Ice Sock* (`-0.4°C` na 15 min), utrata sodu i ryzyko skurczów przy `>3%` odwodnienia.

### 3.3 Codzienna Diagnostyka Grand Tour: Nocne HRV, CK i Triage Fizjoterapeutów
- **Poranny Raport Biomarkerów** (`GrandTourNightlyHrvAndPhysioModel`, `GrandTourMorningMedicalBriefingScreen`):
  - Każdego ranka podczas 3-tygodniowego Wielkiego Touru sztab medyczny bada u 8 kolarzy: nocne **HRV (rMSSD w ms)**, tętno spoczynkowe **RHR**, poziom kinazy kreatynowej **CK (U/L)**, stosunek **Kortyzol/Testosteron** oraz jakość snu (obniżaną przez długie transfery autokarem).
- **Przydział Fizjoterapeutów i Czartery Lotnicze** (`GrandTourPhysiotherapyTriageService`):
  - Gracz rozdziela ograniczony czas **3 specjalistów na 8 kolarzy**:
    - *Głęboki Masaż Powięziowy*: redukuje poziom **CK o `-25%`**.
    - *Terapia Tecar / Ultradźwięki*: przyspiesza gojenie stłuczeń po kraksach.
    - *Krioterapia Ogólnoustrojowa*: podnosi nocne **HRV o `+12 ms`**.
  - **Logistyka Snu**: wykupienie **czarteru lotniczego** zamiast 4-godzinnego transferu autokarem daje liderom **`+2 godziny` snu** i lepszą regenerację przed kolejnym etapem.

### 3.4 Suplementacja WorldTour, Zmęczenie 3. Tygodnia i Mikrocykle TSS/TSB
- **Suplementacja** (`CarbohydrateHydrogelAndKetonesEngine`): `Standard 60g/h CHO`, `High-Carb Hydrogel 110g/h`, `Bicarbonate Pre-Load` (**+6% $W'$**) oraz `Post-Finish Exogenous Ketones` (**+12% regeneracji nocnej**).
- **Zmęczenie i Dyspozycja Dnia**: `GrandTourThirdWeekFatigueDecay` (etapy 14–21), `DailyRiderDayFormVarianceEngine` ("The Legs" `-3..+3`), `OvertrainingAndBurnoutDiagnostics` (`TSB < -35`) oraz `WeeklyTrainingMicrocyclePlannerScreen`.

---

## 4. Fizyka Specjalistyczna Dyscyplin Pozaszosowych, Torowych i Para-Cycling

- **Cyclo-Cross (CX)**: `CxPitBikeExchangeMechanics` (oblepianie błotem `0.4–1.8 kg/km`, wymiana w Pit Lane `4.5 s`) oraz `CyclocrossBunnyhopAndCarrySolver` (bieg `12–16 km/h` vs skok *Bunny-Hop* `+1.8 s/rundę`).
- **Welodrom 250 m**: `VelodromeBankingAndCentripetalSolver` (siła odśrodkowa do `1.8G`, kara dystansu `250.0 m -> 258.5 m`) oraz `VelodromeKeirinAndMadisonSlingSolver` (transfer pędu w rzucie *Hand Sling*).
- **Gravel**: `GravelRollingResistanceAndSealantSolver` (zapadanie w luźnym żwirze i samonaprawa mleczkiem Tubeless).
- **MTB XCO**: `MtbSuspensionDampingAndLineChoiceSolver` (straty na *Pedal Bob* i *Chatter*, wybór **A-Line** vs **B-Line**).
- **Ultra-Bikepacking**: `UltraSleepDeprivationAndCircadianSolver` (dług snu, rytm dobowy Borbély'ego, kofeina i bilans dynama).
- **Retro 1970–2015**: `RetroSteelFrameAndNoPowermeterSolver` (skala **Borg RPE 6–20** i opóźnienie manetek na dolnej rurze ramy).
- **e-Sports**: `EsportsSmartTrainerErgAndPowerupsSolver` (mnożniki Power-Upów, Dual-Recording i eliminacja co `60 s`).
- **UCI Para-Cycling** (`TandemAndHandbikePhysicsSolver`): podwójna moc załóg Tandem B (`>800 W`), synchronizacja pilota i stokera, termika tarcz hamulcowych na zjazdach `>95 km/h` oraz stabilność boczna i opory aero trójkołowych handbike'ów H1–H5.

---

## 5. Taktyka Peletonu, Psychologia Szatni 2.0, AI DS, Kontrole X-Ray UCI i Trybunał CAS

### 5.1 Ruch Ciągły Peletonu, Walka na Łokcie i Blefowanie
- **Boids 60 FPS** (`BoidsSteeringCollisionAvoidance`, `BoidsPelotonFlockingSolver`): separacja bez kolizji (`1.85 x 0.65 m`), `DraftSeeking`, wyprzedzanie i efekt akordeonu.
- **Wachlarze i Spychanie pod Krawężnik** (`EchelonCrosswindEngine`, `TeamSprintTrainEchelonDiagonalFormation`): diagonalny pociąg spychający rywali w **In the Gutter** (`GutterWindProtectionDiagramHud`, `TvEchelonCrosswindRadarHud`).
- **Walka o Koło i Łokcie w Sprincie (`62 km/h`)** (`SprinterElbowRubbingAndWheelFighting`): na ostatnich `3 km` sprinterzy o wysokim `raceIq` i `sprint` bronią koła rozprowadzającego barkiem w bark; decydują masa ciała, siła core i agresywność w granicach przepisów UCI.
- **Mowa Ciała i Blefowanie Kryzysu (`Poker Face`)** (`BluffingAndPokerFaceEngine`, `RiderPokerFaceBluffActionButton`): maskowanie zmęczenia na podjeździe i *Sandbagging* z gwałtownym kontratakiem.

### 5.2 Algorytmy Taktyczne AI, Pakty Ucieczki, 52 Style DS i Symulator „What-If”
- **Mikro-Pakty i Zdrada w Ucieczce** (`BreakawayAlliancePactBetrayalAi`, `BreakawayCooperationTrustMeterHud`): na `15 km` przed metą dwaj najsilniejsi uciekinierzy mogą zawrzeć pakt współpracy do `1 km` przed metą, z analizą reputacji partnera i wskaźnikiem `%` zmian na czele.
- **Równowaga Ucieczki i Stacje Przekaźnikowe**: `BreakawayVsPelotonEquilibriumSolver`, `GcTimeGapPanicThresholdAi` (`<4 min` GC = 4 pomocników na `88% FTP`), `SatelliteRiderRelayTacticsEngine`, `DomestiqueRoadBlockingMechanics` (`<4.5 m`, `65% FTP`) oraz `GrupettoAutobusSurvivalAi`.
- **Unikalne Style 52 Dyrektorów Sportowych AI** (`AiDirectorSportifTacticalStylesEngine`, `RivalTeamTacticalScoutingReportCard`) i **Symulator „What-If”** (`WhatIfTacticalSandboxSimulator`, `WhatIfScenarioComparatorModal` — 20 wariantów Monte Carlo w `<1.5 s`).
- **Sprint i Finisz**: `SprintTrainAiController`, `SprinterTrainCounterSurfingAi`, **proca aerodynamiczna** (`SprintLeadoutAerodynamicSlingshot`, `72–76 km/h`) oraz **Bike Throw** (`+18–28 cm`, `FinishLineBikeThrowPhysics`) z fotofiniszem `0.001 s`.

### 5.3 Kontrole Techniczne UCI (X-Ray), Trybunał CAS, Incydenty Drogowe i Strefa 3 km
- **Kontrole Techniczne X-Ray i Trybunał CAS** (`TechnicalScrutinyAndCasTribunalModel`, `TechnicalScrutinyAndReputationDefenseService`, `UciTechnicalXrayScrutinyModal`):
  - Przed startem i po mecie komisarze UCI wykonują inspekcje tabletami magnetycznymi i mobilnymi skanerami **X-Ray** (wykrywanie ukrytych mikrosilników w suportach i piastach), sprawdzają wysokość skarpetek ($\le 50\%$ długości goleni), kąt klamek ($\le 10^\circ$), przedłużki lemondki ITT i szablon ramy.
  - Wykrycie naruszenia wymusza nerwową korektę kluczem dynamometrycznym na **3 minuty przed startem z rampy ITT** (skok stresu!) lub grozi dyskwalifikacją **DSQ**, od której drużyna może odwołać się przed **Trybunałem Arbitrażowym ds. Sportu (CAS w Lozannie)**.
- **Dramatyczne Zdarzenia na Trasie** (`SpectatorDogAndVehicleObstructionEvents`, `RiderRunningUphillIncident3d`):
  - Wtargnięcie psa kibica (test `bikeHandling`), zablokowanie wąskiego podjazdu przez wóz TV zmuszające lidera do **biegu pod górę w butach kolarskich** (styl Mont Ventoux) oraz decyzja sędziów o neutralizacji straty czasowej.
- **Dyplomacja, Strefa 3 km, VAR i Pogoda Ekstremalna**:
  - `InRacePelotonDiplomacyEngine`, `NatureBreakAndPelotonEtiquetteEngine`, `LateRaceMechanicalNeutralZoneEngine` (`3 KM ZONE`), `CommissaireJuryPenaltiesEngine`, `UciCommissaireRulebookAndVarModel` (`Sprint Deviation VAR`), `RaceProtestAndCourseRerouteEngine` (Art. `2.2.029bis`) i `WeatherRadarLiveForecastShiftEngine`.

---

## 6. Silnik Renderowania 3D 120 FPS, Audio, Sterowanie i Ekosystem BI

### 6.1 Potok 3D Zero-GC 120 FPS (`Peloton3dCanvasEngine`)
- **Optymalizacja Pamięci**: `RenderObjectPoolManager` (bufory `Float64List` dla 176 kolarzy, 352 kół i 890 cząsteczek), `SpatialHashGrid1d2d` (`<0.4 ms/klatkę`), `FrustumAndDistanceCuller` (`>450 m`) i `ProceduralPbrTextureAtlasGenerator`.
- **Kamery, Biomy i Efekty Fizyczne 3D**:
  - **OnBoard Action Cam 140° FOV** (`OnBoardBikeMountedActionCam3d`): kamera pod siodełkiem i na kierownicy z obiektywem rybiego oka, mikro-drganiami asfaltu, tylnym kołem/kasetą rywala i walką na łokcie na ostatnich `1500 m`.
  - **Biomy 3D**: **Wysokie Andy, Australijski Busz i Jesienne Rundy Québec/Montréal** (`AndesEucalyptusAndQuebecBiomes3d`), sawanna Rwandy, kaniony AlUla i dżungla Malezji (`ExoticBiomesSavannaDesertJungleEngine`), most Wielki Bełt, Arenberg, Toskania, Ventoux.
  - **Efekty Cząsteczkowe i Fizjologiczne**: **nagrzane tarcze hamulcowe i dym opon** (`GlowingBrakeRotorsAndTireSmoke3d`), **kałuże i pióropusze wody z kół** (`DynamicPuddleSplashAndTireSpray3d`), **bieg lidera pod górę** (`RiderRunningUphillIncident3d`), solver IK (`InverseKinematicsLimbSolver`), para z ust, pot, tunel kibiców, napisy kredą i banery kibiców z nazwiskiem lidera.
- **Audio, Adaptacyjna Muzyka i Mikser 6-Kanałowy**:
  - `Spatial3dPelotonAudioPanner`, `SoundscapeMixerController`, `AdaptiveDynamicMusicScoreEngine`, **6-kanałowy mikser z Mute/Solo** (`AudioMixerAdvancedSettingsPanel`), radio drużynowe i haptyka (`HapticFeedbackVibrationController`).

### 6.2 Sterowanie, Skróty Klawiszowe i Kontrolery
- **Klawiatura (`KeyboardShortcutsManager`)**:
  - `Spacja` — Pauza / Wznów wyścig (`Snap to Wheel` w trybie FPP)
  - `1–4` — Tempo symulacji (`1x`, `2x`, `4x`, `8x`)
  - `W / S` — Zwiększ / zmniejsz moc i przełożenia (w trybie sterowania bezpośredniego)
  - `A / D` — Ruch poprzeczny / szukanie luk w peletonie
  - `Shift` — Sprint na stojąco / *Watt Bomb*
  - `Alt + Space` — Paleta szybkich komend radia wyścigowego (`VoiceCommandQuickActionsPalette`)
  - `Ctrl + K` — Globalna wyszukiwarka **Spotlight** (`GlobalSearchSpotlightModal`)
  - `F3` — Nakładka profilera FPS/RAM (`PerformanceProfilerOverlay`)
  - `F11` — Pełny ekran Desktop (`WindowsDesktopWindowConfig`)
  - `F12` — Tryb zrzutów ekranu (`Screenshot Mode`)
- **Kontrolery Gamepad** (`ControllerGamepadInputMapper`): pełne mapowanie dla **Xbox**, **PlayStation DualSense** (adaptacyjne spusty) i **Steam Deck**.
- **Ergonomia Mobilna**: `MobileOneHandedThumbHudMode` oraz pełna responsywność UI `LayoutBuilder` dla `390x844` (Mobile), `1024x768` (Tablet) i `1600x900` (Desktop) z paletą `AppColors` i czcionką `Inter`.

### 6.3 Narzędzia Dodatkowe, Modding, Migracja v10 i Eksport
- **Live Split-Screen GC & Skróty TV 45s**: `LiveSplitScreenTelemetryComparatorHud` oraz `InstantHighlightClipGenerator` / `TvHighlightReelPlayerOverlay`.
- **Konsola Wozu Technicznego (Dual-Screen)** (`CompanionCarDashboardScreen`, `DualScreenTelemetryWallServer`) i **Kino Powtórek / Tryb Foto 3D** (`RaceReplayDirectorTheaterScreen`, `PhotoMode3dCameraStudioOverlay`).
- **Eksport, Transfer QR i Migracja Zapisów**: telemetria `.gpx` / `.tcx`, Kronika Kariery `.html` / `.md`, BI `.csv` / `.json`, archiwa `.ppmsave.gz` (`CloudCrossSaveJsonSyncAdapter`), transfer **QR / Base64** (`CareerSaveCloudQrCodeTransfer`) oraz automatyczna migracja zapisów do formatu **v10** (`SaveCompatibilityV10Migrator`).
- **Edytory i Warsztat Modów**: `StageEditorCreatorScreen`, `InGameDatabaseRosterEditorScreen`, paczki `.ppmstage` i `.ppmmod`.
- **Dostępność i Języki**: natychmiastowe przełączanie **PL / EN** (`BilingualCyclingDictionary`, `AppLocalizationsPlEn`) oraz **4 palety dla daltonistów** (*Protanopia*, *Deuteranopia*, *Tritanopia*, *Achromatopsia*) z podwójnym kodowaniem kształtami (`ColorblindAccessibilityPalettes`).
