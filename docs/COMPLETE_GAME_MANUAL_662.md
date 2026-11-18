# Pro Peloton Manager — Kompletny Przewodnik po 13 Trybach Gry i Systemach Fizycznych (`COMPLETE_GAME_MANUAL_662.md`)

> Oficjalna dokumentacja użytkownika i kompendium techniczne **Pro Peloton Manager** (stan systemu: zadania `#001–#662`, Paczki `#1–#9` + Obsidian Sovereign v4.0 QA). Dokument opisuje wszystkie **13 trybów rozgrywki**, **systemy fizyczne, bioenergetyczne, termoregulacyjne i taktyczne**, a także **sterowanie, skróty klawiszowe, analitykę BI oraz narzędzia ekosystemu**.

---

## Spis Treści

1. [Przegląd 13 Trybów Gry](#1-przegląd-13-trybów-gry)
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
2. [Systemy Fizyczne Ruchu, Aerodynamiki i Nawierzchni](#2-systemy-fizyczne-ruchu-aerodynamiki-i-nawierzchni)
3. [Fizjologia, Bioenergetyka, Termoregulacja i Trening](#3-fizjologia-bioenergetyka-termoregulacja-i-trening)
4. [Fizyka Specjalistyczna Dyscyplin Pozaszosowych, Torowych i Para-Cycling](#4-fizyka-specjalistyczna-dyscyplin-pozaszosowych-torowych-i-para-cycling)
5. [Taktyka Peletonu, Psychologia Szatni 2.0, AI DS i Sędziowie UCI / VAR](#5-taktyka-peletonu-psychologia-szatni-20-ai-ds-i-sędziowie-uci--var)
6. [Silnik Renderowania 3D 120 FPS, Audio, Sterowanie i Ekosystem BI](#6-silnik-renderowania-3d-120-fps-audio-sterowanie-i-ekosystem-bi)

---

## 1. Przegląd 13 Trybów Gry

| # | Tryb Gry | Główny Ekran / Serwis | Kluczowa Mechanika |
|---|---|---|---|
| 1 | **Kariera Menedżera** | `DashboardHqScreen`, `MainShellScreen` | Budżet, transfery, Split-Squad, Ekspansja Globalna, BI, NG+ |
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
| 13 | **UCI Para-Cycling & Igrzyska Paralimpijskie** | `UciParacyclingWorldCupScreen`, `TandemAndHandbike3dMeshRenderer` | Tandemy Klasy B (>800 W), Handbike H1–H5, Rowery C1–C5, sztafeta |

---

### Tryb 1: Kariera Menedżera WorldTour / ProTeam / Continental

Pełna symulacja zarządzania zawodową drużyną kolarską w wielosezonowym kalendarzu UCI (`SeasonCalendar`, `CareerStateNotifier`).

- **Start i Konfiguracja Realizmu**:
  - Wybór drużyny w `NewCareerSetupScreen` lub jednego z 4 gotowych scenariuszy szybkiego startu (`DemoSavePresetBuilder`: *Polski Projekt WT*, *Pojedynek Tytanów w Alpach*, *Kampania Brukowana*, *Imperium Galaktyczne*).
  - Konfiguracja **14 flag realizmu** i indeksu realizmu `0–100` w `CareerRealismCustomizerPanel` (`AppFeatureFlagsAndPresets`).
  - Styczniowa **Gala Prezentacji Drużyny** (`PreSeasonTeamPresentationScreen`, `PreSeasonTeamPresentationEvent`) z deklaracją celów sezonowych, prezentacją transferów i koszulek oraz **Ceremonią Prezentacji Tras Wielkich Tourów** (`GrandTourRouteRevealCeremonyScreen`).
- **Globalna Ekspansja Kalendarza UCI i Europa Środkowa**:
  - Rozszerzony kalendarz pozaeuropejski (`GlobalExoticToursExpansionModel`): *Tour du Rwanda* (*Mur de Kigali*), *Tour de Langkawi* (Malezja), *Tour of Oman* i *AlUla Tour* z profilami logistyczno-aklimatyzacyjnymi oraz egzotycznymi biomami 3D.
  - Pakiet Europy Środkowej (`TourDePologneAndCentralEuropePack`): pełny 7-etapowy **Tour de Pologne** (Karpacz Orlinek, Gliczarów, Kraków) oraz 5 klasyków i etapówek regionu.
- **Zarządzanie Kadrą, Sztabem, Treningiem i Infrastrukturą**:
  - **Skład i Hierarchia**: `SquadRosterScreen`, `TeamBuilderHierarchyScreen`, kontrola przepisów UCI (`RosterUciComplianceValidator`: limit 7/8 kolarzy, min. waga roweru `6.80 kg`), rozdzielanie 28-osobowej kadry i floty 30 rowerów na dwa równoległe wyścigi w tym samym dniu (**Split-Squad**: `MultiRaceParallelDaySimulator`, `SplitSquadCalendarAssignmentModal`).
  - **Kreator Mikrocykli Treningowych i Obóz Juniorów**: `WeeklyTrainingMicrocyclePlannerScreen` (`CustomTrainingMicrocycleBuilderService`) pozwala planować bloki tygodniowe (interwały VO2max, Motor-Pacing, Sweet Spot) z wyliczaniem TSS i prognozą Banistera CTL/ATL/TSB; coroczny obóz selekcyjny `TalentCombineTryoutsScreen` (`YouthTalentSummerCombineCampService`) testuje 17-letnich talentów z całego świata w 4 stacjach laboratoryjnych i wyścigu na 85 km.
  - **Rozbudowa Bazy (Service Course HQ) i Muzeum Klubowe 3D**: 5 działów po 5 poziomów w `ServiceCourseHqFacilityScreen` (`TeamServiceCourseHqUpgrades`), a także **Muzeum Klubowe i Historycznych Rowerów 3D** (`ClubMuseumAndLegendaryBikesScreen`, `EquipmentWindTunnelCustomDecalsAndSerialsService`) przechowujące ramy z indywidualnymi numerami seryjnymi i złote edycje mistrzowskie.
  - **Własna Marka Rowerowa R&D**: `InHouseBikeBrandFactoryScreen` (`InHouseBikeBrandModel`) umożliwia projektowanie własnych ram w CAD 2D, badania karbonu, sprzedawanie licencji B2B innym drużynom oraz czerpanie przychodów detalicznych.
  - **Globalne Akademii Satelickie i Skauting**: 8 regionalnych siatek skautingowych (`RegionalScoutingNetworksService`) oraz 4 akademie satelickie (Kolumbia, Afryka Wschodnia, Flandria, Sierra Nevada) w `GlobalAcademyNetworkMapScreen`.
- **Finanse, Sponsorzy Wschodzący, Ekonomia ESG i Analityka BI**:
  - Negocjacje tytularne (`SponsorPitchDeckNegotiationModal`), nadzwyczajne bonusy CEO (`SponsorBonusNegotiationEvents`), sponsorzy z rynków wschodzących Azji, Afryki i Bliskiego Wschodu (`GlobalSponsorMarketExpansionService`), przychody z praw TV (`TvBroadcastRightsRevenueSharingService`), sklep klubowy i Fan Zones (`TeamMerchandiseAndFanClubRevenue`), a także flota EV/FCEV i bilans $\text{CO}_2$ (`EsgSustainabilityAndFleetScreen`, `TeamEsgSustainabilityAndGreenFleetModel`).
  - **Analityka Biznesowo-Sportowa BI** (`DeepCareerAnalyticsBiScreen`, `CareerStatisticsDeepAnalyticsExporter`): ocena zwrotu z inwestycji (ROI) dla transferów i projektów R&D, symulator What-If R&D oraz eksport wieloletnich statystyk do CSV/JSON.
- **Rynek Transferowy, Psychologia Szatni 2.0 i New Game+**:
  - Klauzule kontraktowe (`AgentContractClausesEngine`), negocjacje na żywo (`ContractNegotiationChatSimulator`), dziennikarze i przecieki (`TransferRumorMillAndJournalistsService`) oraz studio na żywo **Transfer Deadline Day** (`TransferDeadlineDayLiveEventService`).
  - **Psychologia Szatni 2.0** (`RiderRelationshipChemistryWebModel`, `TeamChemistryRelationshipWebWidget`, `TeamBondingRetreatAndConflictMediationService`): macierz relacji `-100..+100`, pakt lojalności *Blood Brothers*, wyjazdy integracyjne i mediacje konfliktów między liderami, pamięć urazów (`AiRivalryGrudgeMemoryService`), mentoring i urlopy ojcowskie.
  - Gala **Vélo d'Or** (`VeloDorGalaCeremonyScreen`), **Season Wrapped**, drzewko perków menedżera, **Księga Legendy** i **Dynastia / New Game+** (`ManagerLegacyHallOfFameBookScreen`).

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

### Tryb 13: UCI Para-Cycling World Cup & Igrzyska Paralimpijskie

Pełnoprawna symulacja kolarstwa paralimpijskiego w klasach **Tandem (B)**, **Handbike (H1–H5)** oraz **Rowery (C1–C5)** w cyklu Pucharu Świata i Igrzysk Paralimpijskich (`UciParacyclingWorldCupScreen`, `UciParacyclingTandemHandbikeModel`).

- **Klasy Sportowe i Zestawienia Załóg**:
  - **Tandem Klasy B**: Załoga złożona z pilota pełnosprawnego i stokera z dysfunkcją wzroku (`TandemCrewPairing`), generująca wspólną moc przekraczającą `800 W` i rozwijająca prędkości powyżej `95 km/h` na zjazdach.
  - **Handbike H1–H5**: Trójkołowe rowery napędzane ręcznie (pozycja leżąca H1–H4 vs klęcząca H5, `HandbikePostureType`) z indywidualnym profilem aerodynamicznym i stabilnością w zakrętach.
  - **Rowery C1–C5**: Kolarze z dysfunkcjami narządu ruchu startujący na zmodyfikowanych rowerach szosowych i torowych.
- **Sztafeta Drużynowa Handbike Team Relay** (`HandbikeTeamRelayEntry`): Składanie 3-osobowych zespołów mieszczących się w regulaminowym limicie **11 punktów klasyfikacyjnych** oraz pełna klasyfikacja medalowa PŚ i Igrzysk Paralimpijskich.

---

## 2. Systemy Fizyczne Ruchu, Aerodynamiki i Nawierzchni

Silnik fizyczny działa deterministycznie w izolowanym wątku (`IsolateSimulationWorker` + `StageSimulationLoop`) w oparciu o ziarno `stageSeed` (`DeterministicRngSeedManager`) i stałe `PhysicsConstants` ($g = 9.80665\text{ m/s}^2$, $\rho_0 = 1.225\text{ kg/m}^3$, skala wysokości $H = 8500\text{ m}$).

### 2.1 Równanie Ruchu (`SpeedSolver` & `GravityAndRollingCalculator`)
- Hybrydowy solver Newtona-Raphsona z bisekcją rozwiązuje bilans sił w każdym kroku $\Delta t$:
  $$m_{total} \cdot a = F_{prop} - (F_{grav} + F_{roll} + F_{aero}) - F_{brake}$$
- Straty mechaniczne napędu: łańcuch woskowany **2.0%** ($\eta = 0.980$), smar standardowy **2.8%** ($\eta = 0.972$), napęd brudny/zużyty **3.5%** ($\eta = 0.965$).
- Opory toczenia $C_{rr}$ skalują się z chropowatością asfaltu, systemem `tubeless` oraz szerokością i ciśnieniem opony (`TirePressureCalculator`).

### 2.2 Strefowa Aerodynamika CFD, Podmuchy Boczne i Rynsztok
- **CFD w Czasie Rzeczywistym** (`RealTimeCfdVortexAndDragSolver`, `CfdWindTunnelHeatmap3dPainter`):
  - Analiza 6 stref oporu (kask, przedramiona, tekstylia, rama, koła przednie/tylne), **reguła 105%** (dopasowanie szerokości opony do obręczy), **efekt żagla** przy wietrze skośnym oraz generacja ścieżki wirów Kármána.
  - Przekłada się bezpośrednio na komparator $\Delta CdA$ w Tunelu Aerodynamicznym (`WindTunnelCdaDeltaComparator`).
- **Stabilność Kół na Wietrze Bocznym i Ryzyko Rynsztoka**:
  - `CrosswindWheelStabilityAndGustSolver` modeluje moment skręcający na przednim kole ($\tau_{steer}$) wysokich stożków karbonowych (`65–80 mm`).
  - `CrosswindPelotonGutterCollisionRisk` oblicza ryzyko zjechania na pobocze i kolizji z wachlarzem podczas prób wyprzedzania w ciasnym rynsztoku (*In the Gutter*) przy silnym wietrze bocznym.
- **Cień za Kolumną Wyścigową (`Caravan Drafting`)** (`DraftingBehindTeamCarAndMotosSolver`):
  - Powrót po kraksie lub defekcie za motocyklami TV i wozami technicznymi (*Car-Hopping*) daje ogromny zysk aero, ale buduje ryzyko kary czasowej UCI w `CaravanDraftingRiskMeterHud`.

### 2.3 Bruk, Kadencja, Zakręty, Zjazdy i Klimat Tropikalno-Pustynny
- **Ugięcie Opon na Bruku 1★–5★** (`CobbleTirePressureRealTimeDeflection`): Modeluje kompromis między stratami histerezy a stratami impedancyjnymi od drgań na sektorach takich jak *Trouée d'Arenberg* (2.4 km).
- **Kadencja i Przełożenia** (`CadenceAndGearingEfficiencySolver`, `DrivetrainGearingConfiguration`): Dobór tarcz (`50/34T` do `58T 1x`) i kaset 12s (`11-28T` do `10-36T`). Męczenie twardego przełożenia poniżej `60 RPM` na ściance `18%` zwiększa koszt glikogenu o **+18%**.
- **Straty Kinetyczne w Zakrętach i Przyczepność na Mokrym** (`BrakingZoneKineticEnergyLossSolver`, `WetCorneringGripAndBrakingSolver`): Cięższe koła tracą więcej energii obrotowej na dohamowaniach; $v_{max} = \sqrt{\mu \cdot g \cdot R}$ spada z $\mu \approx 0.85$ (suchy asfalt) do $\mu \approx 0.55$ (mokry asfalt) i $\mu \approx 0.40$ (mokry bruk).
- **Ataki na Zjazdach i Supertuck** (`DescenderAttackAndSupertuckPhysics`, `AltitudeDescentAirDensityTransition`): Kolarze o `descending >= 85 && bikeHandling >= 85` zyskują `25–45 s` na 15 km zjazdu przy ciągłej ($C^1$) zmianie gęstości powietrza $\rho(h, T)$.
- **Wilgotność Tropikalna 95% i Pustynny Piasek** (`TropicalHumidityAndDesertSandstormSolver`): Na wyścigach w Malezji i Omanie/AlUla uwzględnia gęstość wilgotnego powietrza, wskaźnik WBGT ograniczający parowanie potu oraz nawiany piasek podnoszący $C_{rr}$ i opory napędu.

---

## 3. Fizjologia, Bioenergetyka, Termoregulacja i Trening

### 3.1 Model Skiba $W'$, Profil Mleczanowy i Adaptacja TT
- `WPrimeBalanceEngine` symuluje zużycie baterii beztlenowej $W'$ (w kJ) powyżej progu krytycznego ($CP / FTP$) oraz jej wykładniczą regenerację poniżej $CP$.
- `LactateAndLabProfile` definiuje progi **$LT_1$**, **$LT_2$**, **$VO_2max$** oraz **$VLaMax$**; `PedalStrokeBiomechanicsAnalyzer` analizuje obrót korby $0^\circ–360^\circ$ (balans L/R, TE%, PS%, *Peanut Diagram*).
- **Adaptacja Pozycji TT i Motor-Pacing** (`MotorPacingAndAeroTuckAdaptation`, `AeroVsRoadPowerEfficiencyGauge`): Trenując za skuterem/Derny, kolarz poprawia retencję mocy na lemondce względem szosowego FTP, zmniejszając okluzję biodrową i koszt oddechowy przepony w niskiej pozycji aero (z uwzględnieniem detrainingu po >10 dniach przerwy).

### 3.2 Termoregulacja, Chłodzenie i Elektrolity
- **Temperatura Głęboka Ciała** (`CoreBodyTemperatureThermoregulation`): Zakres `37.0°C – 40.5°C` na bazie bilansu ciepła metabolicznego $\dot{Q}_{prod} = P \cdot \frac{1-\eta}{\eta}$, konwekcji $\dot{Q}_{conv} \propto v^{0.6}$ i parowania potu. Powyżej `39.2°C` następuje dryf tętna (`+12 BPM`).
- **Chłodzenie Aktywne i Elektrolity** (`IceSocksAndWaterDousingMechanics`, `SweatSodiumElectrolyteDepletion`): Rozkaz pobrania *Ice Sock* / polania głowy wodą obniża temperaturę głęboką o `0.4°C` na 15 min; pocenie `0.8–2.5 l/h` i utrata sodu powyżej `>3%` odwodnienia grozi skurczami (**Muscle Cramps**).

### 3.3 Żywienie, Suplementacja WorldTour, Hipoksja i Mikrocykle TSS/TSB
- **Nowoczesna Suplementacja** (`CarbohydrateHydrogelAndKetonesEngine`): `Standard 60g/h CHO`, `High-Carb Hydrogel 110g/h`, `Bicarbonate Pre-Load` (**+6% $W'$**) oraz `Post-Finish Exogenous Ketones` (**+12% regeneracji nocnej**).
- **Wysokość, Zmęczenie 3. Tygodnia i Dyspozycja Dnia**: `HighAltitudeHypoxiaCalculator` (spadek $VO_2max$ powyżej `1500–2000 m n.p.m.`), `GrandTourThirdWeekFatigueDecay` (etapy 14–21), `DailyRiderDayFormVarianceEngine` ("The Legs" `-3..+3` diamenty) oraz `OvertrainingAndBurnoutDiagnostics` (`TSB < -35`).
- **Planowanie Mikrocykli Treningowych** (`CustomTrainingMicrocycleBuilderService`, `WeeklyTrainingMicrocyclePlannerScreen`): Tworzenie tygodniowych mikrocykli z prognozą obciążenia Banistera CTL/ATL/TSB i bezpośrednią integracją treningów *Motor-Pacing*.

---

## 4. Fizyka Specjalistyczna Dyscyplin Pozaszosowych, Torowych i Para-Cycling

- **Cyclo-Cross (CX)**: `CxPitBikeExchangeMechanics` (oblepianie błotem `0.4–1.8 kg/km`, wymiana w Pit Lane `4.5 s`) oraz `CyclocrossBunnyhopAndCarrySolver` (bieg `12–16 km/h` vs skok *Bunny-Hop* `+1.8 s/rundę`).
- **Welodrom 250 m**: `VelodromeBankingAndCentripetalSolver` (siła odśrodkowa do `1.8G`, kara dystansu `250.0 m -> 258.5 m`) oraz `VelodromeKeirinAndMadisonSlingSolver` (transfer pędu w rzucie *Hand Sling*).
- **Gravel**: `GravelRollingResistanceAndSealantSolver` (zapadanie w luźnym żwirze i samonaprawa mleczkiem Tubeless).
- **MTB XCO**: `MtbSuspensionDampingAndLineChoiceSolver` (straty na *Pedal Bob* i *Chatter*, wybór **A-Line** vs **B-Line**).
- **Ultra-Bikepacking**: `UltraSleepDeprivationAndCircadianSolver` (dług snu, rytm dobowy Borbély'ego, kofeina i bilans dynama).
- **Retro 1970–2015**: `RetroSteelFrameAndNoPowermeterSolver` (skala **Borg RPE 6–20** i opóźnienie manetek na dolnej rurze ramy).
- **e-Sports**: `EsportsSmartTrainerErgAndPowerupsSolver` (mnożniki Power-Upów, Dual-Recording i eliminacja co 60 s).
- **UCI Para-Cycling** (`TandemAndHandbikePhysicsSolver`): Podwójna moc załóg Tandem B (`>800 W`), synchronizacja pilota i stokera, termika tarcz hamulcowych na zjazdach `>95 km/h` oraz stabilność boczna w zakrętach i opory aerodynamiczne trójkołowych handbike'ów H1–H5.

---

## 5. Taktyka Peletonu, Psychologia Szatni 2.0, AI DS i Sędziowie UCI / VAR

### 5.1 Ruch Ciągły Peletonu, Walka z Wiatrem i Blefowanie
- **Boids 60 FPS** (`BoidsSteeringCollisionAvoidance`, `BoidsPelotonFlockingSolver`): Separacja bez kolizji (`1.85 x 0.65 m`), `DraftSeeking`, wyprzedzanie i efekt akordeonu.
- **Wachlarze i Spychanie pod Krawężnik** (`EchelonCrosswindEngine`, `TeamSprintTrainEchelonDiagonalFormation`): Formowanie diagonalnego pociągu na wietrze bocznym spychającego rywali w tzw. **In the Gutter** (`GutterWindProtectionDiagramHud`, `TvEchelonCrosswindRadarHud`).
- **Mowa Ciała i Blefowanie Kryzysu (`Poker Face`)** (`BluffingAndPokerFaceEngine`, `RiderPokerFaceBluffActionButton`): Na stromych podjazdach kolarz może zamaskować zmęczenie lub zastosować *Sandbagging* (udawanie kryzysu z gwałtownym kontratakiem), wprowadzając AI rywali w błąd.

### 5.2 Algorytmy Taktyczne AI, 52 Style DS i Symulator „What-If”
- **Równowaga Ucieczki i Reakcja Kryzysowa GC**: `BreakawayVsPelotonEquilibriumSolver`, `GcTimeGapPanicThresholdAi` (`<4 min` GC w odjeździe = 4 pomocników na `88% FTP`), `SatelliteRiderRelayTacticsEngine` (Stacje Przekaźnikowe), `DomestiqueRoadBlockingMechanics` (`<4.5 m`, `65% FTP`) oraz `GrupettoAutobusSurvivalAi` (limit czasu OTL z 3-min zapasem).
- **Unikalne Style 52 Dyrektorów Sportowych AI** (`AiDirectorSportifTacticalStylesEngine`, `RivalTeamTacticalScoutingReportCard`): Każda z 52 drużyn AI posiada własny profil taktyczny DS (np. agresywne ataki z daleka, kontrola pociągu, zasadzki na wietrze), prezentowany w raporcie wywiadu przed etapem.
- **Symulator Taktyczny „What-If”** (`WhatIfTacticalSandboxSimulator`, `WhatIfScenarioComparatorModal`): Uruchamia w tle **20 wariantów Monte Carlo** w `<1.5 s`, porównując rozkłady wyników na szklanych wykresach pudełkowych (kwartyle Tukeya, H2H, prawdopodobieństwo wygranej).
- **Sprint i Finisz**: Rozprowadzanie (`SprintTrainAiController`), surfowanie po kołach (`SprinterTrainCounterSurfingAi`), **proca aerodynamiczna** (`SprintLeadoutAerodynamicSlingshot`, do `72–76 km/h`) oraz rzut rowerem na kreskę (**Bike Throw**: `+18–28 cm`, `FinishLineBikeThrowPhysics`) z fotofiniszem `0.001 s`.

### 5.3 Dyplomacja, Etykieta, Sędziowie UCI, Strefa 3 km i Pogoda Ekstremalna
- **Dyplomacja na Szosie i Etykieta** (`InRacePelotonDiplomacyEngine`, `NatureBreakAndPelotonEtiquetteEngine`): Pakty *Stage for GC Deal*, *Anti-Leader Coalition*, *Neutralization Truce*, *Nature Break* oraz rozejm po kraksie lidera.
- **Strefa Ochronna UCI 3 km / 5 km** (`LateRaceMechanicalNeutralZoneEngine`, `NeutralZone3kmActiveBannerHud`): Precyzyjna neutralizacja czasów GC w przypadku kraksy lub defektu w strefie finałowej etapów sprinterskich z telewizyjnym banerem `3 KM ZONE — GC TIMES NEUTRALIZED`.
- **Kolegium Sędziów UCI, VAR i Pogoda Ekstremalna**: `CommissaireJuryPenaltiesEngine`, `UciCommissaireRulebookAndVarModel` (`Sprint Deviation VAR`), `RaceProtestAndCourseRerouteEngine` (Art. `2.2.029bis`, głosowanie CPA) oraz `WeatherRadarLiveForecastShiftEngine`.

---

## 6. Silnik Renderowania 3D 120 FPS, Audio, Sterowanie i Ekosystem BI

### 6.1 Potok 3D Zero-GC 120 FPS (`Peloton3dCanvasEngine`)
- **Optymalizacja Pamięci**: `RenderObjectPoolManager` (prealokowane bufory `Float64List` dla 176 kolarzy, 352 kół i 890 cząsteczek), `SpatialHashGrid1d2d` (`<0.4 ms/klatkę`), `FrustumAndDistanceCuller` (`>450 m`) oraz proceduralny atlas PBR (`ProceduralPbrTextureAtlasGenerator`).
- **Realizm Wizualny i Nowe Biomy 3D**:
  - Solver IK (`InverseKinematicsLimbSolver`), kołysanie *en danseuse* (`StandingBikeRockingPhysics3d`), deformacja opony (`TireDeformationAndSpokeGlintFx`), para z ust i pot, mokry asfalt, dynamiczne niebo, tunel kibiców, napisy kredą, **proceduralne banery kibiców z nazwiskiem lidera i flagami regionów** (`DynamicSpectatorBannersAndFlags3dRenderer`), **egzotyczne biomy sawanny Rwandy, kanionów AlUla i dżungli Malezji** (`ExoticBiomesSavannaDesertJungleEngine`), siatki **tandemów i handbike'ów** (`TandemAndHandbike3dMeshRenderer`) oraz 6 animacji zwycięstwa.
- **Audio, Adaptacyjna Muzyka i Mikser 6-Kanałowy**:
  - Przestrzenne panoramowanie 3D (`Spatial3dPelotonAudioPanner`), 5-kanałowy pejzaż (`SoundscapeMixerController`), **proceduralny adaptacyjny silnik muzyki elektroniczno-orkiestrowej** (`AdaptiveDynamicMusicScoreEngine`), **6-kanałowy mikser z funkcjami Mute/Solo i presetami** (`AudioMixerAdvancedSettingsPanel`), radio drużynowe i haptyka (`HapticFeedbackVibrationController`).

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

### 6.3 Narzędzia Dodatkowe, Skróty TV, Modding i Eksport
- **Live Split-Screen GC & Skróty TV 45s**: Porównywacz telemetrii lidera i głównego rywala GC na żywo (`LiveSplitScreenTelemetryComparatorHud`) oraz automatyczny generator 45-sekundowych skrótów telewizyjnych po etapie (`InstantHighlightClipGenerator`, `TvHighlightReelPlayerOverlay`).
- **Konsola Wozu Technicznego (Dual-Screen)** (`CompanionCarDashboardScreen`, `DualScreenTelemetryWallServer`): Podłączenie drugiego ekranu/tabletu przez lokalny serwer WebSocket/HTTP.
- **Kino Powtórek i Tryb Fotograficzny 3D** (`RaceReplayDirectorTheaterScreen`, `PhotoMode3dCameraStudioOverlay`): Analiza powtórek klatka po klatce, *Aero Vision* oraz kamera Free-Fly 24–200 mm z efektem Bokeh.
- **Eksport Danych i Migracja Zapisów**: Telemetria `.gpx` / `.tcx`, Kronika Kariery `.html` / `.md`, Analityka BI `.csv` / `.json`, archiwa `.ppmsave.gz` (`CloudCrossSaveJsonSyncAdapter`) oraz automatyczna migracja zapisów do formatu v9 (`SaveCompatibilityV9Migrator`).
- **Edytory i Warsztat Modów**: Kreator etapów (`StageEditorCreatorScreen`), Edytor Bazy Danych i Składów (`InGameDatabaseRosterEditorScreen`), paczki `.ppmstage` i `.ppmmod`.
- **Dostępność i Języki**: Natychmiastowe przełączanie **PL / EN** (`BilingualCyclingDictionary`, `AppLocalizationsPlEn`) oraz **4 palety dla daltonistów** (*Protanopia*, *Deuteranopia*, *Tritanopia*, *Achromatopsia*) z podwójnym kodowaniem kształtami (`ColorblindAccessibilityPalettes`).
