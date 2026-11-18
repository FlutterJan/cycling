import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/career/career_save.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../../state/career_state_notifier.dart';

/// Identyfikator jednego z trzech Wielkich Tourów prezentowanych na ceremonii.
enum GrandTourId {
  tourDeFrance(
    title: 'Tour de France',
    shortCode: 'TDF',
    organizer: 'A.S.O.',
    defaultVenue: 'Palais des Congrès, Paryż',
    accentColor: AppColors.goldAccent,
    jerseyLabel: 'Maillot Jaune',
    monthWindow: 'Lipiec',
  ),
  giroDItalia(
    title: "Giro d'Italia",
    shortCode: 'GIRO',
    organizer: 'RCS Sport',
    defaultVenue: 'Auditorium Parco della Musica, Rzym',
    accentColor: AppColors.primaryAccent,
    jerseyLabel: 'Maglia Rosa',
    monthWindow: 'Maj',
  ),
  vueltaAEspana(
    title: 'La Vuelta a España',
    shortCode: 'VUELTA',
    organizer: 'Unipublic',
    defaultVenue: 'Palacio Municipal IFEMA, Madryt',
    accentColor: AppColors.crimsonAlert,
    jerseyLabel: 'La Roja',
    monthWindow: 'Sierpień / Wrzesień',
  );

  final String title;
  final String shortCode;
  final String organizer;
  final String defaultVenue;
  final Color accentColor;
  final String jerseyLabel;
  final String monthWindow;

  const GrandTourId({
    required this.title,
    required this.shortCode,
    required this.organizer,
    required this.defaultVenue,
    required this.accentColor,
    required this.jerseyLabel,
    required this.monthWindow,
  });
}

/// Typ etapu w oficjalnej prezentacji trasy Wielkiego Touru.
enum GrandTourRevealStageType {
  flat(
    label: 'Płaski',
    shortLabel: 'PŁASKI',
    icon: Icons.linear_scale_rounded,
    color: AppColors.statusSuccess,
  ),
  hilly(
    label: 'Pagórkowaty',
    shortLabel: 'PAGÓRKI',
    icon: Icons.waves_rounded,
    color: AppColors.amberWarning,
  ),
  mountainSummit(
    label: 'Górski (Meta na szczycie)',
    shortLabel: 'GÓRY',
    icon: Icons.terrain_rounded,
    color: AppColors.crimsonAlert,
  ),
  individualTimeTrial(
    label: 'Jazda Indywidualna na Czas',
    shortLabel: 'ITT',
    icon: Icons.timer_rounded,
    color: AppColors.accentBlue,
  ),
  teamTimeTrial(
    label: 'Jazda Drużynowa na Czas',
    shortLabel: 'TTT',
    icon: Icons.groups_rounded,
    color: AppColors.cyanAccent,
  ),
  cobblesOrGravel(
    label: 'Bruk / Białe Szutry',
    shortLabel: 'BRUK/SZUTR',
    icon: Icons.grain_rounded,
    color: AppColors.goldAccent,
  );

  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;

  const GrandTourRevealStageType({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.color,
  });
}

/// Filtr listy 21 etapów podczas ceremonii.
enum GrandTourStageFilter {
  all('Wszystkie (21)'),
  mountains('Górskie'),
  timeTrials('Czasówki'),
  sprintsAndClassics('Płaskie & Bruk');

  final String label;

  const GrandTourStageFilter(this.label);

  bool matches(GrandTourRevealStageSpec stage) {
    switch (this) {
      case GrandTourStageFilter.all:
        return true;
      case GrandTourStageFilter.mountains:
        return stage.stageType == GrandTourRevealStageType.mountainSummit ||
            stage.stageType == GrandTourRevealStageType.hilly;
      case GrandTourStageFilter.timeTrials:
        return stage.stageType ==
                GrandTourRevealStageType.individualTimeTrial ||
            stage.stageType == GrandTourRevealStageType.teamTimeTrial;
      case GrandTourStageFilter.sprintsAndClassics:
        return stage.stageType == GrandTourRevealStageType.flat ||
            stage.stageType == GrandTourRevealStageType.cobblesOrGravel;
    }
  }
}

/// Priorytet strategiczny drużyny deklarowany po odsłonięciu trasy Wielkiego Touru.
enum GrandTourStrategicPriority {
  gcPodium(
    label: 'Walka o Klasyfikację Generalną (GC)',
    shortLabel: 'Cel: GC',
    description:
        'Pełna koncentracja pociągu górskiego, zgrupowania wysokogórskie i testy w tunelu aero pod ITT.',
    icon: Icons.emoji_events_rounded,
    accentColor: AppColors.goldAccent,
  ),
  stageHunting(
    label: 'Polowanie na Etapy & Ucieczki',
    shortLabel: 'Cel: Etapy',
    description:
        'Elastyczny skład nastawiony na finisze sprinterskie, etapy pagórkowate i selektywne ucieczki.',
    icon: Icons.bolt_rounded,
    accentColor: AppColors.accentBlue,
  ),
  secondaryJersey(
    label: 'Koszulka Górska / Punktowa',
    shortLabel: 'Cel: Koszulka',
    description:
        'Dedykowani łowcy premii górskich HC/Cat 1 lub sprinterzy zbierający punkty na lotnych premiach.',
    icon: Icons.workspace_premium_rounded,
    accentColor: AppColors.primaryAccent,
  ),
  youthDevelopment(
    label: 'Rozwój Talentów U25',
    shortLabel: 'Cel: Młodzież',
    description:
        'Budowanie wytrzymałości trzytygodniowej u młodych liderów bez presji wyniku w pierwszej dziesiątce.',
    icon: Icons.trending_up_rounded,
    accentColor: AppColors.statusSuccess,
  );

  final String label;
  final String shortLabel;
  final String description;
  final IconData icon;
  final Color accentColor;

  const GrandTourStrategicPriority({
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.icon,
    required this.accentColor,
  });
}

/// Sekcja widoku na ekranach mobilnych (390x844).
enum GrandTourRevealMobileTab {
  overview('Prezentacja', Icons.auto_awesome_rounded),
  stages('21 Etapów', Icons.route_rounded),
  strategy('Plan Ekipy', Icons.assignment_turned_in_rounded);

  final String label;
  final IconData icon;

  const GrandTourRevealMobileTab(this.label, this.icon);
}

/// Kluczowy podjazd lub sektor specjalny wyróżniony w prezentacji etapu.
class GrandTourKeyClimbSpec {
  final String name;
  final String categoryLabel;
  final int altitudeM;
  final double lengthKm;
  final double avgGradientPct;
  final double maxGradientPct;

  const GrandTourKeyClimbSpec({
    required this.name,
    required this.categoryLabel,
    required this.altitudeM,
    required this.lengthKm,
    required this.avgGradientPct,
    required this.maxGradientPct,
  });
}

/// Specyfikacja pojedynczego etapu prezentowanego na ceremonii trasy Wielkiego Touru.
class GrandTourRevealStageSpec {
  final int stageNumber;
  final String title;
  final String startCity;
  final String finishCity;
  final double distanceKm;
  final int elevationGainM;
  final GrandTourRevealStageType stageType;
  final int difficultyStars;
  final bool isQueenStage;
  final bool isRestDayAfter;
  final List<GrandTourKeyClimbSpec> keyClimbs;
  final List<double> elevationProfilePoints;

  const GrandTourRevealStageSpec({
    required this.stageNumber,
    required this.title,
    required this.startCity,
    required this.finishCity,
    required this.distanceKm,
    required this.elevationGainM,
    required this.stageType,
    required this.difficultyStars,
    this.isQueenStage = false,
    this.isRestDayAfter = false,
    this.keyClimbs = const [],
    this.elevationProfilePoints = const [],
  });
}

/// Kompletna oficjalna prezentacja trasy przyszłorocznego Wielkiego Touru.
class GrandTourRouteRevealEdition {
  final GrandTourId tourId;
  final int editionYear;
  final String presentationVenue;
  final String grandDepartCity;
  final String grandDepartCountry;
  final String finaleCity;
  final String headlineQuote;
  final String favoriteArchetype;
  final int climberVsSprinterIndex;
  final List<GrandTourRevealStageSpec> stages;

  const GrandTourRouteRevealEdition({
    required this.tourId,
    required this.editionYear,
    required this.presentationVenue,
    required this.grandDepartCity,
    required this.grandDepartCountry,
    required this.finaleCity,
    required this.headlineQuote,
    required this.favoriteArchetype,
    required this.climberVsSprinterIndex,
    required this.stages,
  });

  double get totalDistanceKm =>
      stages.fold<double>(0.0, (sum, s) => sum + s.distanceKm);

  int get totalElevationGainM =>
      stages.fold<int>(0, (sum, s) => sum + s.elevationGainM);

  double get totalIttKm => stages
      .where(
          (s) => s.stageType == GrandTourRevealStageType.individualTimeTrial)
      .fold<double>(0.0, (sum, s) => sum + s.distanceKm);

  double get totalTttKm => stages
      .where((s) => s.stageType == GrandTourRevealStageType.teamTimeTrial)
      .fold<double>(0.0, (sum, s) => sum + s.distanceKm);

  int get mountainSummitCount => stages
      .where((s) => s.stageType == GrandTourRevealStageType.mountainSummit)
      .length;

  int get sprintStagesCount =>
      stages.where((s) => s.stageType == GrandTourRevealStageType.flat).length;

  int get cobbleOrGravelCount => stages
      .where((s) => s.stageType == GrandTourRevealStageType.cobblesOrGravel)
      .length;

  GrandTourRevealStageSpec? get queenStage {
    if (stages.isEmpty) return null;
    return stages.firstWhere(
      (s) => s.isQueenStage,
      orElse: () => stages.reduce(
        (a, b) => a.elevationGainM >= b.elevationGainM ? a : b,
      ),
    );
  }
}

/// Decyzja taktyczna menedżera zapisana dla jednego Wielkiego Touru podczas ceremonii.
class GrandTourCeremonyPlanEntry {
  final GrandTourId tourId;
  final bool isRevealed;
  final GrandTourStrategicPriority priority;
  final String selectedLeaderName;
  final bool isConfirmed;

  const GrandTourCeremonyPlanEntry({
    required this.tourId,
    required this.isRevealed,
    required this.priority,
    required this.selectedLeaderName,
    required this.isConfirmed,
  });

  GrandTourCeremonyPlanEntry copyWith({
    bool? isRevealed,
    GrandTourStrategicPriority? priority,
    String? selectedLeaderName,
    bool? isConfirmed,
  }) {
    return GrandTourCeremonyPlanEntry(
      tourId: tourId,
      isRevealed: isRevealed ?? this.isRevealed,
      priority: priority ?? this.priority,
      selectedLeaderName: selectedLeaderName ?? this.selectedLeaderName,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }
}

/// Generator oficjalnych 21-etapowych tras przyszłorocznych Wielkich Tourów.
class GrandTourRouteRevealCatalog {
  GrandTourRouteRevealCatalog._();

  /// Tworzy kompletny zestaw prezentacji dla Tour de France, Giro d'Italia i La Vuelta.
  static List<GrandTourRouteRevealEdition> generateNextSeasonReveals({
    int editionYear = 2027,
  }) {
    return [
      _buildTourDeFrance(editionYear),
      _buildGiroDItalia(editionYear),
      _buildVueltaAEspana(editionYear),
    ];
  }

  static GrandTourRouteRevealEdition _buildTourDeFrance(int year) {
    final stages = <GrandTourRevealStageSpec>[
      _stage(
        1,
        'Grand Départ w Edynburgu',
        'Edynburg',
        'Edynburg',
        184.0,
        1650,
        GrandTourRevealStageType.hilly,
        3,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: "Arthur's Seat",
            categoryLabel: 'Cat 3',
            altitudeM: 251,
            lengthKm: 2.4,
            avgGradientPct: 6.8,
            maxGradientPct: 11.0,
          ),
        ],
      ),
      _stage(
        2,
        'Sprinterski finisz nad Morzem Północnym',
        'Kelso',
        'Newcastle',
        198.5,
        1420,
        GrandTourRevealStageType.flat,
        2,
      ),
      _stage(
        3,
        'Przeprawa wiatrowa przez Yorkshire',
        'York',
        'Sheffield',
        179.0,
        2450,
        GrandTourRevealStageType.hilly,
        3,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Côte de Jenkin Road',
            categoryLabel: 'Cat 2',
            altitudeM: 312,
            lengthKm: 1.8,
            avgGradientPct: 9.4,
            maxGradientPct: 16.0,
          ),
        ],
      ),
      _stage(
        4,
        'Powrót do Francji: Bruki Północy',
        'Dunkierka',
        'Arenberg Porte du Hainaut',
        168.0,
        1180,
        GrandTourRevealStageType.cobblesOrGravel,
        4,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Trouée d’Arenberg (Sektor)',
            categoryLabel: '5★ Bruk',
            altitudeM: 42,
            lengthKm: 2.3,
            avgGradientPct: 0.2,
            maxGradientPct: 1.5,
          ),
        ],
      ),
      _stage(
        5,
        'Czasówka Mistrzów Szampanii',
        'Reims',
        'Épernay',
        34.5,
        390,
        GrandTourRevealStageType.individualTimeTrial,
        4,
      ),
      _stage(
        6,
        'Aleja Sprinterów nad Sekwaną',
        'Troyes',
        'Auxerre',
        192.0,
        1150,
        GrandTourRevealStageType.flat,
        2,
      ),
      _stage(
        7,
        'Wogezy: Pierwszy Test Górali',
        'Belfort',
        'La Planche des Belles Filles',
        164.0,
        3450,
        GrandTourRevealStageType.mountainSummit,
        4,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'La Super Planche',
            categoryLabel: 'Cat 1',
            altitudeM: 1148,
            lengthKm: 7.0,
            avgGradientPct: 8.7,
            maxGradientPct: 24.0,
          ),
        ],
      ),
      _stage(
        8,
        'Klasyk Jury w Dzień Przejścia',
        'Besançon',
        'Oyonnax',
        185.0,
        2780,
        GrandTourRevealStageType.hilly,
        3,
      ),
      _stage(
        9,
        'Alpejski Prolog na Col du Colombier',
        'Nantua',
        'Grand Colombier',
        158.0,
        3890,
        GrandTourRevealStageType.mountainSummit,
        5,
        isRestDayAfter: true,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Col du Grand Colombier',
            categoryLabel: 'HC',
            altitudeM: 1501,
            lengthKm: 17.4,
            avgGradientPct: 7.1,
            maxGradientPct: 14.0,
          ),
        ],
      ),
      _stage(
        10,
        'Po Dniu Przerwy: Dolina Rodanu',
        'Chambéry',
        'Valence',
        176.0,
        980,
        GrandTourRevealStageType.flat,
        2,
      ),
      _stage(
        11,
        'Olbrzym Prowansji: Podwójny Ventoux',
        'Carpentras',
        'Mont Ventoux',
        171.0,
        4120,
        GrandTourRevealStageType.mountainSummit,
        5,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Mont Ventoux (Bédoin)',
            categoryLabel: 'HC',
            altitudeM: 1910,
            lengthKm: 15.7,
            avgGradientPct: 8.8,
            maxGradientPct: 12.5,
          ),
        ],
      ),
      _stage(
        12,
        'Wiatr Mistral w Langwedocji',
        'Avignon',
        'Montpellier',
        188.0,
        890,
        GrandTourRevealStageType.flat,
        3,
      ),
      _stage(
        13,
        'Pirenejska Czasówka Górska',
        'Saint-Girons',
        'Plateau de Beille',
        26.5,
        1280,
        GrandTourRevealStageType.individualTimeTrial,
        4,
      ),
      _stage(
        14,
        'Pirenejski Tryptyk: Tourmalet & Luz Ardiden',
        'Pau',
        'Luz Ardiden',
        162.0,
        4650,
        GrandTourRevealStageType.mountainSummit,
        5,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Col du Tourmalet',
            categoryLabel: 'HC',
            altitudeM: 2115,
            lengthKm: 19.0,
            avgGradientPct: 7.4,
            maxGradientPct: 11.2,
          ),
          GrandTourKeyClimbSpec(
            name: 'Luz Ardiden',
            categoryLabel: 'HC',
            altitudeM: 1715,
            lengthKm: 13.3,
            avgGradientPct: 7.4,
            maxGradientPct: 10.5,
          ),
        ],
      ),
      _stage(
        15,
        'Przelot do Prowansji przed Odpoczynkiem',
        'Tarbes',
        'Carcassonne',
        194.0,
        1750,
        GrandTourRevealStageType.flat,
        2,
        isRestDayAfter: true,
      ),
      _stage(
        16,
        'Zasadzka Uciekinierów w Masywie Centralnym',
        'Mende',
        'Le Puy-en-Velay',
        182.0,
        2950,
        GrandTourRevealStageType.hilly,
        4,
      ),
      _stage(
        17,
        'Królewski Etap Alpejski: Galibier & Alpe d’Huez',
        'Bourg-d’Oisans',
        'Alpe d’Huez',
        167.0,
        5180,
        GrandTourRevealStageType.mountainSummit,
        5,
        isQueenStage: true,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Col du Galibier',
            categoryLabel: 'HC',
            altitudeM: 2642,
            lengthKm: 23.0,
            avgGradientPct: 5.1,
            maxGradientPct: 10.1,
          ),
          GrandTourKeyClimbSpec(
            name: "Alpe d'Huez (21 zakrętów)",
            categoryLabel: 'HC',
            altitudeM: 1850,
            lengthKm: 13.8,
            avgGradientPct: 8.1,
            maxGradientPct: 13.0,
          ),
        ],
      ),
      _stage(
        18,
        'Ostatnia Szansa Sprinterów przed Paryżem',
        'Grenoble',
        'Mâcon',
        196.0,
        1240,
        GrandTourRevealStageType.flat,
        2,
      ),
      _stage(
        19,
        'Alpejskie Pożegnanie na Col de la Loze',
        'Albertville',
        'Courchevel Col de la Loze',
        149.0,
        4520,
        GrandTourRevealStageType.mountainSummit,
        5,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Col de la Loze',
            categoryLabel: 'HC',
            altitudeM: 2304,
            lengthKm: 28.1,
            avgGradientPct: 6.0,
            maxGradientPct: 24.0,
          ),
        ],
      ),
      _stage(
        20,
        'Finałowa Próba Sił w Wersalu',
        'Saint-Quentin-en-Yvelines',
        'Wersal',
        29.0,
        340,
        GrandTourRevealStageType.individualTimeTrial,
        4,
      ),
      _stage(
        21,
        'Wielki Finał na Polach Elizejskich',
        'La Défense',
        'Paryż Champs-Élysées',
        118.0,
        480,
        GrandTourRevealStageType.flat,
        2,
      ),
    ];

    return GrandTourRouteRevealEdition(
      tourId: GrandTourId.tourDeFrance,
      editionYear: year,
      presentationVenue: GrandTourId.tourDeFrance.defaultVenue,
      grandDepartCity: 'Edynburg',
      grandDepartCountry: 'Szkocja (UK)',
      finaleCity: 'Paryż',
      headlineQuote:
          '„Trasa bez litości: bruk Arenbergu w pierwszym tygodniu, Mont Ventoux, Alpe d’Huez i ponad 90 km jazdy na czas.”',
      favoriteArchetype: 'Kompletny Lider GC & Czasowiec',
      climberVsSprinterIndex: 78,
      stages: stages,
    );
  }

  static GrandTourRouteRevealEdition _buildGiroDItalia(int year) {
    final stages = <GrandTourRevealStageSpec>[
      _stage(
        1,
        'Grande Partenza: Rzymski Prolog TTT',
        'Rzym',
        'Rzym Foro Italico',
        22.0,
        210,
        GrandTourRevealStageType.teamTimeTrial,
        3,
      ),
      _stage(
        2,
        'Wybrzeże Tyrreńskie dla Sprinterów',
        'Ostia',
        'Neapol',
        196.0,
        1320,
        GrandTourRevealStageType.flat,
        2,
      ),
      _stage(
        3,
        'Wulkaniczny Finisz na Wezuwiuszu',
        'Sorrento',
        'Wezuwiusz',
        158.0,
        3120,
        GrandTourRevealStageType.mountainSummit,
        4,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Monte Vesuvio',
            categoryLabel: 'Cat 1',
            altitudeM: 1015,
            lengthKm: 13.0,
            avgGradientPct: 7.4,
            maxGradientPct: 12.0,
          ),
        ],
      ),
      _stage(
        4,
        'Apeniński Klasyk w Abruzji',
        'Foggia',
        'Campobasso',
        184.0,
        2690,
        GrandTourRevealStageType.hilly,
        3,
      ),
      _stage(
        5,
        'Sprint nad Adriatykiem',
        'Termoli',
        'Pescara',
        179.0,
        920,
        GrandTourRevealStageType.flat,
        2,
      ),
      _stage(
        6,
        'Strade Bianche w Toskanii',
        'Perugia',
        'Siena Piazza del Campo',
        172.0,
        2540,
        GrandTourRevealStageType.cobblesOrGravel,
        5,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Monte Sante Marie (Szuter)',
            categoryLabel: '5★ Strade',
            altitudeM: 380,
            lengthKm: 11.5,
            avgGradientPct: 4.8,
            maxGradientPct: 18.0,
          ),
        ],
      ),
      _stage(
        7,
        'Czasówka w Winnicach Chianti',
        'Radda in Chianti',
        'Greve in Chianti',
        38.0,
        640,
        GrandTourRevealStageType.individualTimeTrial,
        4,
      ),
      _stage(
        8,
        'Ściana San Luca w Bolonii',
        'Modena',
        'Bolonia San Luca',
        169.0,
        2380,
        GrandTourRevealStageType.hilly,
        4,
      ),
      _stage(
        9,
        'Pierwsza Próba Apeninów: Blockhaus',
        'L’Aquila',
        'Blockhaus',
        164.0,
        4150,
        GrandTourRevealStageType.mountainSummit,
        5,
        isRestDayAfter: true,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Passo Lanciano / Blockhaus',
            categoryLabel: 'Cat 1',
            altitudeM: 2065,
            lengthKm: 13.6,
            avgGradientPct: 8.4,
            maxGradientPct: 14.0,
          ),
        ],
      ),
      _stage(
        10,
        'Nizina Padańska dla Pociągów Sprinterskich',
        'Rimini',
        'Ferrara',
        191.0,
        410,
        GrandTourRevealStageType.flat,
        2,
      ),
      _stage(
        11,
        'Wzgorza Prosecco i Muro di Ca’ del Poggio',
        'Treviso',
        'Valdobbiadene',
        174.0,
        2450,
        GrandTourRevealStageType.hilly,
        3,
      ),
      _stage(
        12,
        'Piekło Carnii: Monte Zoncolan',
        'Udine',
        'Monte Zoncolan (Ovaro)',
        154.0,
        4380,
        GrandTourRevealStageType.mountainSummit,
        5,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Monte Zoncolan',
            categoryLabel: 'Cima Coppi',
            altitudeM: 1730,
            lengthKm: 10.1,
            avgGradientPct: 11.9,
            maxGradientPct: 22.0,
          ),
        ],
      ),
      _stage(
        13,
        'Przejazd przez Wenecję Euganejską',
        'Padwa',
        'Werona',
        181.0,
        780,
        GrandTourRevealStageType.flat,
        2,
      ),
      _stage(
        14,
        'Dolomicki Maraton: Giau & Tre Cime',
        'Belluno',
        'Tre Cime di Lavaredo',
        176.0,
        5290,
        GrandTourRevealStageType.mountainSummit,
        5,
        isQueenStage: true,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Passo Giau',
            categoryLabel: 'Cat 1',
            altitudeM: 2236,
            lengthKm: 9.9,
            avgGradientPct: 9.3,
            maxGradientPct: 14.0,
          ),
          GrandTourKeyClimbSpec(
            name: 'Tre Cime di Lavaredo',
            categoryLabel: 'Cat 1',
            altitudeM: 2304,
            lengthKm: 7.2,
            avgGradientPct: 7.6,
            maxGradientPct: 18.0,
          ),
        ],
      ),
      _stage(
        15,
        'Sprint nad Jeziorem Garda',
        'Rovereto',
        'Brescia',
        189.0,
        1190,
        GrandTourRevealStageType.flat,
        2,
        isRestDayAfter: true,
      ),
      _stage(
        16,
        'Przełęcz Mortirolo i Aprica',
        'Sondrio',
        'Aprica',
        162.0,
        4490,
        GrandTourRevealStageType.mountainSummit,
        5,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Passo del Mortirolo',
            categoryLabel: 'Cat 1',
            altitudeM: 1854,
            lengthKm: 12.4,
            avgGradientPct: 10.5,
            maxGradientPct: 18.0,
          ),
        ],
      ),
      _stage(
        17,
        'Dach Wyścigu: Passo dello Stelvio',
        'Bormio',
        'Passo dello Stelvio',
        151.0,
        4820,
        GrandTourRevealStageType.mountainSummit,
        5,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Passo dello Stelvio (48 serpentyn)',
            categoryLabel: 'Cima Coppi',
            altitudeM: 2758,
            lengthKm: 24.3,
            avgGradientPct: 7.4,
            maxGradientPct: 12.0,
          ),
        ],
      ),
      _stage(
        18,
        'Ostatni Oddech w Piemoncie',
        'Bergamo',
        'Turyn',
        193.0,
        1340,
        GrandTourRevealStageType.flat,
        2,
      ),
      _stage(
        19,
        'Finestre: Szutrowa Katedra Alpejska',
        'Susa',
        'Sestriere (Colle delle Finestre)',
        148.0,
        4120,
        GrandTourRevealStageType.mountainSummit,
        5,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Colle delle Finestre (8 km szutru)',
            categoryLabel: 'Cima Coppi',
            altitudeM: 2178,
            lengthKm: 18.5,
            avgGradientPct: 9.2,
            maxGradientPct: 14.0,
          ),
        ],
      ),
      _stage(
        20,
        'Ściana w Alpie d’Oropa (Górska Czasówka)',
        'Biella',
        'Santuario di Oropa',
        19.5,
        920,
        GrandTourRevealStageType.individualTimeTrial,
        4,
      ),
      _stage(
        21,
        'Runda Koronacyjna w Mediolanie',
        'Monza',
        'Mediolan Piazza del Duomo',
        124.0,
        360,
        GrandTourRevealStageType.flat,
        2,
      ),
    ];

    return GrandTourRouteRevealEdition(
      tourId: GrandTourId.giroDItalia,
      editionYear: year,
      presentationVenue: GrandTourId.giroDItalia.defaultVenue,
      grandDepartCity: 'Rzym',
      grandDepartCountry: 'Włochy',
      finaleCity: 'Mediolan',
      headlineQuote:
          '„Prawdziwa włoska klasyka: białe szutry Toskanii, Zoncolan, Tre Cime, Stelvio i szutrowe Colle delle Finestre.”',
      favoriteArchetype: 'Wytrzymały Góral Wysokogórski',
      climberVsSprinterIndex: 86,
      stages: stages,
    );
  }

  static GrandTourRouteRevealEdition _buildVueltaAEspana(int year) {
    final stages = <GrandTourRevealStageSpec>[
      _stage(
        1,
        'Nocna Czasówka Otwarcia w Sewilli',
        'Sewilla',
        'Sewilla Plaza de España',
        14.5,
        95,
        GrandTourRevealStageType.teamTimeTrial,
        3,
      ),
      _stage(
        2,
        'Andaluzyjski Upał i Sprint w Kordobie',
        'Sewilla',
        'Kordoba',
        186.0,
        1480,
        GrandTourRevealStageType.flat,
        2,
      ),
      _stage(
        3,
        'Eksplozja na Ścianie w Jaén',
        'Úbeda',
        'Sierra de la Pandera',
        163.0,
        3340,
        GrandTourRevealStageType.mountainSummit,
        4,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Sierra de la Pandera',
            categoryLabel: 'Cat 1',
            altitudeM: 1830,
            lengthKm: 12.0,
            avgGradientPct: 7.3,
            maxGradientPct: 16.0,
          ),
        ],
      ),
      _stage(
        4,
        'Górskie Szutry Sierra Nevada',
        'Grenada',
        'Sierra Nevada (Alto Hoya de la Mora)',
        152.0,
        4120,
        GrandTourRevealStageType.mountainSummit,
        5,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Alto Hoya de la Mora',
            categoryLabel: 'ESP',
            altitudeM: 2510,
            lengthKm: 19.3,
            avgGradientPct: 7.9,
            maxGradientPct: 14.0,
          ),
        ],
      ),
      _stage(
        5,
        'Wiatr nad Morzem Śródziemnym',
        'Almería',
        'Murcja',
        191.0,
        1540,
        GrandTourRevealStageType.flat,
        2,
      ),
      _stage(
        6,
        'Rampa Xorret de Catí',
        'Alicante',
        'Xorret de Catí',
        166.0,
        2980,
        GrandTourRevealStageType.hilly,
        4,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Xorret de Catí',
            categoryLabel: 'Cat 1',
            altitudeM: 1097,
            lengthKm: 3.9,
            avgGradientPct: 11.4,
            maxGradientPct: 22.0,
          ),
        ],
      ),
      _stage(
        7,
        'Finisz Sprinterów w Walencji',
        'Gandía',
        'Walencja',
        178.0,
        820,
        GrandTourRevealStageType.flat,
        2,
      ),
      _stage(
        8,
        'Mury Katalonii: Coll de Pal',
        'Tarragona',
        'Coll de Pal',
        168.0,
        3680,
        GrandTourRevealStageType.mountainSummit,
        4,
      ),
      _stage(
        9,
        'Królewski Etap w Andorze',
        'Andorra la Vella',
        'Cortals d’Encamp',
        139.0,
        4290,
        GrandTourRevealStageType.mountainSummit,
        5,
        isRestDayAfter: true,
      ),
      _stage(
        10,
        'Czasówka w Pampelunie',
        'Pampeluna',
        'Pampeluna',
        33.0,
        380,
        GrandTourRevealStageType.individualTimeTrial,
        4,
      ),
      _stage(
        11,
        'Kraj Basków: Ściany pod Bilbao',
        'Vitoria',
        'Bilbao',
        172.0,
        3120,
        GrandTourRevealStageType.hilly,
        4,
      ),
      _stage(
        12,
        'Kantabryjski Podjazd na Peña Cabarga',
        'Santander',
        'Peña Cabarga',
        164.0,
        2740,
        GrandTourRevealStageType.mountainSummit,
        4,
      ),
      _stage(
        13,
        'Asturia: Lagos de Covadonga',
        'Llanes',
        'Lagos de Covadonga',
        171.0,
        3890,
        GrandTourRevealStageType.mountainSummit,
        5,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Lagos de Covadonga',
            categoryLabel: 'ESP',
            altitudeM: 1134,
            lengthKm: 12.5,
            avgGradientPct: 6.9,
            maxGradientPct: 16.0,
          ),
        ],
      ),
      _stage(
        14,
        'Piekło Asturii: Alto de l’Angliru',
        'Oviedo',
        "Alto de l'Angliru",
        156.0,
        4760,
        GrandTourRevealStageType.mountainSummit,
        5,
        isQueenStage: true,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: "Alto de l'Angliru (Cueña les Cabres)",
            categoryLabel: 'ESP',
            altitudeM: 1570,
            lengthKm: 12.4,
            avgGradientPct: 9.8,
            maxGradientPct: 24.0,
          ),
        ],
      ),
      _stage(
        15,
        'Sprint przed Drugim Odpoczynkiem',
        'León',
        'Burgos',
        188.0,
        1150,
        GrandTourRevealStageType.flat,
        2,
        isRestDayAfter: true,
      ),
      _stage(
        16,
        'Białe Drogi Kastylii',
        'Palencia',
        'Valladolid',
        169.0,
        1380,
        GrandTourRevealStageType.cobblesOrGravel,
        4,
      ),
      _stage(
        17,
        'Góry Salamanki: La Covatilla',
        'Salamanka',
        'La Covatilla',
        165.0,
        3620,
        GrandTourRevealStageType.mountainSummit,
        4,
      ),
      _stage(
        18,
        'Wiatr na Płaskowyżu Kastylijskim',
        'Ávila',
        'Toledo',
        184.0,
        1640,
        GrandTourRevealStageType.hilly,
        3,
      ),
      _stage(
        19,
        'Finałowe Starcie: Bola del Mundo',
        'San Lorenzo de El Escorial',
        'Bola del Mundo',
        157.0,
        4180,
        GrandTourRevealStageType.mountainSummit,
        5,
        climbs: const [
          GrandTourKeyClimbSpec(
            name: 'Bola del Mundo (Navacerrada)',
            categoryLabel: 'ESP',
            altitudeM: 2258,
            lengthKm: 22.4,
            avgGradientPct: 6.1,
            maxGradientPct: 20.0,
          ),
        ],
      ),
      _stage(
        20,
        'Krótka Czasówka Decyzji w Madrycie',
        'Alcobendas',
        'Madryt Casa de Campo',
        21.0,
        240,
        GrandTourRevealStageType.individualTimeTrial,
        3,
      ),
      _stage(
        21,
        'Parada Zwycięzców na Paseo de la Castellana',
        'Madryt',
        'Madryt Plaza de Cibeles',
        104.0,
        420,
        GrandTourRevealStageType.flat,
        2,
      ),
    ];

    return GrandTourRouteRevealEdition(
      tourId: GrandTourId.vueltaAEspana,
      editionYear: year,
      presentationVenue: GrandTourId.vueltaAEspana.defaultVenue,
      grandDepartCity: 'Sewilla',
      grandDepartCountry: 'Hiszpania',
      finaleCity: 'Madryt',
      headlineQuote:
          '„Dziesięć finiszów na szczytach, powrót na Angliru i piekielna końcówka na Bola del Mundo.”',
      favoriteArchetype: 'Eksplozywny Góral / Puncheur',
      climberVsSprinterIndex: 84,
      stages: stages,
    );
  }

  static GrandTourRevealStageSpec _stage(
    int number,
    String title,
    String start,
    String finish,
    double distanceKm,
    int elevationGainM,
    GrandTourRevealStageType type,
    int stars, {
    bool isQueenStage = false,
    bool isRestDayAfter = false,
    List<GrandTourKeyClimbSpec> climbs = const [],
  }) {
    return GrandTourRevealStageSpec(
      stageNumber: number,
      title: title,
      startCity: start,
      finishCity: finish,
      distanceKm: distanceKm,
      elevationGainM: elevationGainM,
      stageType: type,
      difficultyStars: stars,
      isQueenStage: isQueenStage,
      isRestDayAfter: isRestDayAfter,
      keyClimbs: climbs,
      elevationProfilePoints: _buildSyntheticProfile(type, number, elevationGainM),
    );
  }

  static List<double> _buildSyntheticProfile(
    GrandTourRevealStageType type,
    int seed,
    int elevationGainM,
  ) {
    final points = <double>[];
    const count = 28;
    for (int i = 0; i < count; i++) {
      final t = i / (count - 1);
      final wave = math.sin(t * math.pi * 4 + seed) * 0.12;
      double val;
      switch (type) {
        case GrandTourRevealStageType.flat:
          val = 0.12 + 0.08 * math.sin(t * math.pi * 2 + seed) + wave * 0.25;
          break;
        case GrandTourRevealStageType.hilly:
          val = 0.20 +
              0.38 * math.pow(math.sin(t * math.pi * 3 + seed * 0.5).abs(), 1.3) +
              (t > 0.7 ? 0.22 : 0.0);
          break;
        case GrandTourRevealStageType.mountainSummit:
          final baseClimb = math.pow(t, 1.55).toDouble() * 0.72;
          final midPeak =
              0.35 * math.exp(-math.pow((t - 0.45) * 4.5, 2).toDouble());
          val = 0.14 + baseClimb + midPeak + wave * 0.4;
          break;
        case GrandTourRevealStageType.individualTimeTrial:
        case GrandTourRevealStageType.teamTimeTrial:
          val = elevationGainM > 700
              ? 0.15 + math.pow(t, 1.8).toDouble() * 0.72
              : 0.16 + 0.18 * math.sin(t * math.pi * 2 + seed);
          break;
        case GrandTourRevealStageType.cobblesOrGravel:
          val = 0.18 +
              0.24 * math.sin(t * math.pi * 5 + seed).abs() +
              (t > 0.55 ? 0.14 : 0.0);
          break;
      }
      points.add(val.clamp(0.06, 0.98));
    }
    return points;
  }
}

/// Uroczysty ekran Ceremonii Prezentacji Oficjalnej Trasy Przyszłorocznych Wielkich Tourów.
class GrandTourRouteRevealCeremonyScreen extends ConsumerStatefulWidget {
  /// Opcjonalna lista prezentacji tras; jeśli null, generowana z [GrandTourRouteRevealCatalog].
  final List<GrandTourRouteRevealEdition>? editions;

  /// Opcjonalna nazwa zespołu gracza (używana m.in. w testach bez aktywnego zapisu).
  final String? teamNameOverride;

  /// Opcjonalna lista nazwisk liderów dostępnych do przypisania pod Wielkie Toury.
  final List<String>? leaderCandidatesOverride;

  /// Czy wszystkie 3 Wielkie Toury mają być domyślnie odsłonięte na starcie ekranu.
  final bool revealAllInitially;

  /// Callback wywoływany po zatwierdzeniu planu i zakończeniu ceremonii.
  final ValueChanged<Map<GrandTourId, GrandTourCeremonyPlanEntry>>?
      onCeremonyCompleted;

  const GrandTourRouteRevealCeremonyScreen({
    super.key,
    this.editions,
    this.teamNameOverride,
    this.leaderCandidatesOverride,
    this.revealAllInitially = false,
    this.onCeremonyCompleted,
  });

  @override
  ConsumerState<GrandTourRouteRevealCeremonyScreen> createState() =>
      _GrandTourRouteRevealCeremonyScreenState();
}

class _GrandTourRouteRevealCeremonyScreenState
    extends ConsumerState<GrandTourRouteRevealCeremonyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spotlightController;
  late List<GrandTourRouteRevealEdition> _editions;
  GrandTourId _selectedTourId = GrandTourId.tourDeFrance;
  int _selectedStageNumber = 17;
  GrandTourStageFilter _stageFilter = GrandTourStageFilter.all;
  GrandTourRevealMobileTab _mobileTab = GrandTourRevealMobileTab.overview;
  final Map<GrandTourId, GrandTourCeremonyPlanEntry> _plans = {};
  bool _ceremonyFinished = false;

  @override
  void initState() {
    super.initState();
    _spotlightController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _initializeEditionsAndPlans();
  }

  @override
  void didUpdateWidget(covariant GrandTourRouteRevealCeremonyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editions != widget.editions) {
      _initializeEditionsAndPlans();
    }
  }

  @override
  void dispose() {
    _spotlightController.dispose();
    super.dispose();
  }

  void _initializeEditionsAndPlans() {
    final careerSave = _safeReadCareerSave();
    final nextYear = (careerSave?.currentDate.year ?? 2026) + 1;
    _editions = widget.editions ??
        GrandTourRouteRevealCatalog.generateNextSeasonReveals(
          editionYear: nextYear,
        );

    if (_editions.isNotEmpty) {
      if (!_editions.any((e) => e.tourId == _selectedTourId)) {
        _selectedTourId = _editions.first.tourId;
      }
      _syncDefaultStageSelection();
    }

    final leaders = _resolveLeaderCandidates(careerSave);
    for (final edition in _editions) {
      _plans.putIfAbsent(
        edition.tourId,
        () => GrandTourCeremonyPlanEntry(
          tourId: edition.tourId,
          isRevealed: widget.revealAllInitially ||
              edition.tourId == GrandTourId.tourDeFrance,
          priority: edition.tourId == GrandTourId.tourDeFrance
              ? GrandTourStrategicPriority.gcPodium
              : GrandTourStrategicPriority.stageHunting,
          selectedLeaderName: leaders.isNotEmpty
              ? leaders[edition.tourId.index % leaders.length]
              : 'Lider Zespołu',
          isConfirmed: false,
        ),
      );
    }
  }

  CareerSave? _safeReadCareerSave() {
    try {
      return ref.read(careerStateNotifierProvider).rawSave;
    } catch (_) {
      return null;
    }
  }

  List<String> _resolveLeaderCandidates(CareerSave? save) {
    if (widget.leaderCandidatesOverride != null &&
        widget.leaderCandidatesOverride!.isNotEmpty) {
      return widget.leaderCandidatesOverride!;
    }
    if (save != null) {
      final playerTeam = save.teams.cast<CyclingTeam?>().firstWhere(
            (t) => t?.id == save.playerTeamId,
            orElse: () => null,
          );
      final rosterIds = playerTeam?.rosterRiderIds.toSet() ?? const <String>{};
      final riders = save.riders
          .where((r) => rosterIds.contains(r.id))
          .toList()
        ..sort((a, b) => b.overallRating.compareTo(a.overallRating));
      if (riders.isNotEmpty) {
        return riders.take(6).map((Rider r) => r.fullName).toList();
      }
    }
    return const [
      'M. Kwiatkowski',
      'J. Vingegaard',
      'T. Pogačar',
      'R. Evenepoel',
      'J. Philipsen',
    ];
  }

  String _resolveTeamName(CareerSave? save) {
    if (widget.teamNameOverride != null &&
        widget.teamNameOverride!.trim().isNotEmpty) {
      return widget.teamNameOverride!;
    }
    if (save != null) {
      final playerTeam = save.teams.cast<CyclingTeam?>().firstWhere(
            (t) => t?.id == save.playerTeamId,
            orElse: () => null,
          );
      if (playerTeam != null) return playerTeam.name;
    }
    return 'Pro Peloton Racing';
  }

  GrandTourRouteRevealEdition? get _activeEdition {
    if (_editions.isEmpty) return null;
    return _editions.firstWhere(
      (e) => e.tourId == _selectedTourId,
      orElse: () => _editions.first,
    );
  }

  void _syncDefaultStageSelection() {
    final edition = _activeEdition;
    if (edition == null || edition.stages.isEmpty) {
      _selectedStageNumber = 1;
      return;
    }
    final queen = edition.queenStage;
    _selectedStageNumber = queen?.stageNumber ?? edition.stages.first.stageNumber;
  }

  void _selectTour(GrandTourId tourId) {
    setState(() {
      _selectedTourId = tourId;
      _stageFilter = GrandTourStageFilter.all;
      _syncDefaultStageSelection();
    });
  }

  void _revealTour(GrandTourId tourId) {
    final current = _plans[tourId];
    if (current == null || current.isRevealed) return;
    setState(() {
      _plans[tourId] = current.copyWith(isRevealed: true);
    });
  }

  void _revealAllTours() {
    setState(() {
      for (final edition in _editions) {
        final current = _plans[edition.tourId];
        if (current != null && !current.isRevealed) {
          _plans[edition.tourId] = current.copyWith(isRevealed: true);
        }
      }
    });
  }

  void _updatePriority(
    GrandTourId tourId,
    GrandTourStrategicPriority priority,
  ) {
    final current = _plans[tourId];
    if (current == null || !current.isRevealed || current.isConfirmed) return;
    setState(() {
      _plans[tourId] = current.copyWith(priority: priority);
    });
  }

  void _updateLeader(GrandTourId tourId, String leaderName) {
    final current = _plans[tourId];
    if (current == null || !current.isRevealed || current.isConfirmed) return;
    setState(() {
      _plans[tourId] = current.copyWith(selectedLeaderName: leaderName);
    });
  }

  void _toggleConfirmPlan(GrandTourId tourId) {
    final current = _plans[tourId];
    if (current == null || !current.isRevealed) return;
    setState(() {
      _plans[tourId] = current.copyWith(isConfirmed: !current.isConfirmed);
    });
  }

  void _finishCeremony() {
    setState(() {
      _ceremonyFinished = true;
    });
    if (widget.onCeremonyCompleted != null) {
      widget.onCeremonyCompleted!(Map.unmodifiable(_plans));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.surfaceLight,
        content: Text(
          'Plan Wielkich Tourów zapisany w kalendarzu drużyny.',
          style: TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    Navigator.of(context).maybePop();
  }

  int get _revealedCount =>
      _plans.values.where((entry) => entry.isRevealed).length;

  int get _confirmedCount =>
      _plans.values.where((entry) => entry.isConfirmed).length;

  @override
  Widget build(BuildContext context) {
    final careerSave = _safeReadCareerSave();
    final teamName = _resolveTeamName(careerSave);
    final leaderCandidates = _resolveLeaderCandidates(careerSave);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _spotlightController,
              builder: (context, _) {
                final accent = _activeEdition?.tourId.accentColor ??
                    AppColors.goldAccent;
                return CustomPaint(
                  painter: _CeremonyStageSpotlightPainter(
                    phase: _spotlightController.value,
                    accentColor: accent,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                if (_editions.isEmpty) {
                  return _buildEmptyState(context, width);
                }
                if (width < 760) {
                  return _buildMobileLayout(
                    context,
                    teamName: teamName,
                    leaderCandidates: leaderCandidates,
                  );
                }
                if (width < 1260) {
                  return _buildTabletLayout(
                    context,
                    teamName: teamName,
                    leaderCandidates: leaderCandidates,
                  );
                }
                return _buildDesktopLayout(
                  context,
                  teamName: teamName,
                  leaderCandidates: leaderCandidates,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, double width) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width < 500 ? width - 32 : 520),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.map_outlined,
                color: AppColors.goldAccent,
                size: 44,
              ),
              const SizedBox(height: 12),
              const Text(
                'BRAK PREZENTACJI TRAS WIELKICH TOURÓW',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Organizatorzy ASO, RCS Sport i Unipublic nie opublikowali jeszcze tras na kolejny sezon.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              _CeremonyActionButton(
                label: 'Wróć do Biura HQ',
                icon: Icons.arrow_back_rounded,
                accentColor: AppColors.goldAccent,
                isPrimary: true,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context, {
    required String teamName,
    required List<String> leaderCandidates,
  }) {
    final edition = _activeEdition!;
    final plan = _plans[edition.tourId]!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: _buildTopHeader(
            compact: true,
            teamName: teamName,
            edition: edition,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildTourSelectorRow(compact: true),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: GrandTourRevealMobileTab.values.map((tab) {
              final isSelected = _mobileTab == tab;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _InteractivePillTab(
                    label: tab.label,
                    icon: tab.icon,
                    isSelected: isSelected,
                    accentColor: edition.tourId.accentColor,
                    onTap: () => setState(() => _mobileTab = tab),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              child: switch (_mobileTab) {
                GrandTourRevealMobileTab.overview => Column(
                    key: ValueKey('mobile_overview_${edition.tourId.name}'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildRevealHeroCard(edition, plan, compact: true),
                      const SizedBox(height: 12),
                      if (plan.isRevealed) ...[
                        _buildRouteDnaMetricsCard(edition, compact: true),
                        const SizedBox(height: 12),
                        _buildRouteRibbonCard(edition, compact: true),
                      ],
                    ],
                  ),
                GrandTourRevealMobileTab.stages => Column(
                    key: ValueKey('mobile_stages_${edition.tourId.name}'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!plan.isRevealed)
                        _buildLockedOverlayCard(edition)
                      else ...[
                        _buildSelectedStageDetailCard(edition, compact: true),
                        const SizedBox(height: 12),
                        _buildStagesListCard(edition, maxListHeight: 380),
                      ],
                    ],
                  ),
                GrandTourRevealMobileTab.strategy => Column(
                    key: ValueKey('mobile_strategy_${edition.tourId.name}'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTacticalPlanCard(
                        edition,
                        plan,
                        leaderCandidates,
                        compact: true,
                      ),
                    ],
                  ),
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(
    BuildContext context, {
    required String teamName,
    required List<String> leaderCandidates,
  }) {
    final edition = _activeEdition!;
    final plan = _plans[edition.tourId]!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: _buildTopHeader(
            compact: false,
            teamName: teamName,
            edition: edition,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildTourSelectorRow(compact: false),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildRevealHeroCard(edition, plan, compact: false),
                        const SizedBox(height: 12),
                        if (plan.isRevealed)
                          _buildRouteDnaMetricsCard(edition, compact: false),
                        const SizedBox(height: 12),
                        _buildTacticalPlanCard(
                          edition,
                          plan,
                          leaderCandidates,
                          compact: false,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    child: plan.isRevealed
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildRouteRibbonCard(edition, compact: false),
                              const SizedBox(height: 12),
                              _buildSelectedStageDetailCard(
                                edition,
                                compact: false,
                              ),
                              const SizedBox(height: 12),
                              _buildStagesListCard(
                                edition,
                                maxListHeight: 360,
                              ),
                            ],
                          )
                        : _buildLockedOverlayCard(edition),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context, {
    required String teamName,
    required List<String> leaderCandidates,
  }) {
    final edition = _activeEdition!;
    final plan = _plans[edition.tourId]!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: _buildTopHeader(
            compact: false,
            teamName: teamName,
            edition: edition,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildTourSelectorRow(compact: false),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildRevealHeroCard(edition, plan, compact: false),
                        const SizedBox(height: 14),
                        if (plan.isRevealed)
                          _buildRouteDnaMetricsCard(edition, compact: false)
                        else
                          _buildLockedOverlayCard(edition),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: plan.isRevealed
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildRouteRibbonCard(edition, compact: false),
                              const SizedBox(height: 14),
                              _buildSelectedStageDetailCard(
                                edition,
                                compact: false,
                              ),
                            ],
                          )
                        : _buildLockedOverlayCard(edition),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (plan.isRevealed)
                          _buildStagesListCard(edition, maxListHeight: 280)
                        else
                          _buildLockedOverlayCard(edition),
                        const SizedBox(height: 14),
                        _buildTacticalPlanCard(
                          edition,
                          plan,
                          leaderCandidates,
                          compact: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader({
    required bool compact,
    required String teamName,
    required GrandTourRouteRevealEdition edition,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 18,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 780;
          final titleSection = Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.45),
                  ),
                ),
                child: const Icon(
                  Icons.live_tv_rounded,
                  color: AppColors.goldAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CEREMONIA PREZENTACJI TRAS ${edition.editionYear}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: compact ? 14 : 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '$teamName • Odsłonięto $_revealedCount/${_editions.length} • Zatwierdzono $_confirmedCount/${_editions.length}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actionButtons = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CeremonyActionButton(
                label: 'Odsłoń Wszystkie',
                icon: Icons.visibility_rounded,
                accentColor: AppColors.accentBlue,
                isDisabled: _revealedCount >= _editions.length,
                onPressed: _revealAllTours,
              ),
              _CeremonyActionButton(
                label: _ceremonyFinished
                    ? 'Plan Zapisany'
                    : 'Zakończ Ceremonię',
                icon: _ceremonyFinished
                    ? Icons.check_circle_rounded
                    : Icons.flag_rounded,
                accentColor: AppColors.goldAccent,
                isPrimary: true,
                isDisabled: _revealedCount == 0,
                onPressed: _finishCeremony,
              ),
            ],
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: titleSection),
                const SizedBox(width: 12),
                actionButtons,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleSection,
              const SizedBox(height: 10),
              actionButtons,
            ],
          );
        },
      ),
    );
  }

  Widget _buildTourSelectorRow({required bool compact}) {
    return Row(
      children: _editions.map((edition) {
        final isSelected = edition.tourId == _selectedTourId;
        final plan = _plans[edition.tourId]!;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _TourSelectorCardButton(
              edition: edition,
              plan: plan,
              isSelected: isSelected,
              compact: compact,
              onTap: () => _selectTour(edition.tourId),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRevealHeroCard(
    GrandTourRouteRevealEdition edition,
    GrandTourCeremonyPlanEntry plan, {
    required bool compact,
  }) {
    final accent = edition.tourId.accentColor;
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: plan.isRevealed ? 0.55 : 0.30),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.14),
            AppColors.surface,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '${edition.tourId.organizer} • ${edition.tourId.monthWindow}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                plan.isRevealed
                    ? Icons.lock_open_rounded
                    : Icons.lock_outline_rounded,
                color: plan.isRevealed
                    ? AppColors.statusSuccess
                    : AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${edition.tourId.title} ${edition.editionYear}',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: compact ? 20 : 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gala w: ${edition.presentationVenue}',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _KeyValuePoint(
                    label: 'Grand Départ',
                    value:
                        '${edition.grandDepartCity}, ${edition.grandDepartCountry}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KeyValuePoint(
                    label: 'Wielki Finał',
                    value: edition.finaleCity,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            crossFadeState: plan.isRevealed
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Kurtyna oficjalnej prezentacji jest jeszcze zasłonięta. Odsłoń mapę 21 etapów, aby poznać profil gór i czasówek.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                _CeremonyActionButton(
                  label: 'Odsłoń Trasę ${edition.tourId.shortCode}',
                  icon: Icons.auto_awesome_rounded,
                  accentColor: accent,
                  isPrimary: true,
                  onPressed: () => _revealTour(edition.tourId),
                ),
              ],
            ),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edition.headlineQuote,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.person_pin_circle_rounded,
                      color: accent,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Profil dla: ${edition.favoriteArchetype}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedOverlayCard(GrandTourRouteRevealEdition edition) {
    final accent = edition.tourId.accentColor;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.theater_comedy_rounded, color: accent, size: 42),
          const SizedBox(height: 12),
          Text(
            'TRASA ${edition.tourId.title.toUpperCase()} OCZEKUJE NA PREZENTACJĘ',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kliknij „Odsłoń Trasę”, aby zobaczyć wszystkie 21 etapów, sumę przewyższeń oraz wymagane profile kolarzy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          _CeremonyActionButton(
            label: 'Odsłoń Trasę ${edition.tourId.shortCode}',
            icon: Icons.auto_awesome_rounded,
            accentColor: accent,
            isPrimary: true,
            onPressed: () => _revealTour(edition.tourId),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteDnaMetricsCard(
    GrandTourRouteRevealEdition edition, {
    required bool compact,
  }) {
    final accent = edition.tourId.accentColor;
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PARAMETRY OFICJALNEJ TRASY',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: compact ? 2.15 : 2.35,
            children: [
              _MetricTile(
                label: 'Dystans całkowity',
                value: '${edition.totalDistanceKm.toStringAsFixed(0)} km',
                accent: accent,
              ),
              _MetricTile(
                label: 'Suma przewyższeń',
                value: '${edition.totalElevationGainM} m',
                accent: AppColors.crimsonAlert,
              ),
              _MetricTile(
                label: 'Czasówki (ITT / TTT)',
                value:
                    '${edition.totalIttKm.toStringAsFixed(1)} / ${edition.totalTttKm.toStringAsFixed(1)} km',
                accent: AppColors.accentBlue,
              ),
              _MetricTile(
                label: 'Mety górskie / Sprint',
                value:
                    '${edition.mountainSummitCount} gór / ${edition.sprintStagesCount} pł.',
                accent: AppColors.statusSuccess,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Balans: Sprinterzy vs Górale',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${edition.climberVsSprinterIndex}/100 Góry',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (edition.climberVsSprinterIndex / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteRibbonCard(
    GrandTourRouteRevealEdition edition, {
    required bool compact,
  }) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'PANORAMA 21 ETAPÓW (KLIKNIJ ETAP)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (edition.queenStage != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.goldAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Królewski: E${edition.queenStage!.stageNumber}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.goldAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (edition.stages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Brak zdefiniowanych etapów dla tej edycji.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: compact ? 118 : 136,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: edition.stages.map((stage) {
                  final isSelected = stage.stageNumber == _selectedStageNumber;
                  final normalizedHeight =
                      (stage.elevationGainM / 5400).clamp(0.18, 1.0);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: _StageRibbonBar(
                        stage: stage,
                        heightFraction: normalizedHeight,
                        isSelected: isSelected,
                        onTap: () => setState(
                          () => _selectedStageNumber = stage.stageNumber,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: GrandTourRevealStageType.values.map((type) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: type.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    type.shortLabel,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedStageDetailCard(
    GrandTourRouteRevealEdition edition, {
    required bool compact,
  }) {
    if (edition.stages.isEmpty) {
      return const SizedBox.shrink();
    }
    final stage = edition.stages.firstWhere(
      (s) => s.stageNumber == _selectedStageNumber,
      orElse: () => edition.stages.first,
    );
    final accent = stage.stageType.color;

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accent.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(stage.stageType.icon, color: accent, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          'ETAP ${stage.stageNumber} • ${stage.stageType.shortLabel}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (stage.isQueenStage)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldAccent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ETAP KRÓLEWSKI',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.goldAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                '${stage.distanceKm.toStringAsFixed(1)} km • +${stage.elevationGainM} m',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            stage.title,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${stage.startCity} → ${stage.finishCity}',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: compact ? 120 : 148,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: CustomPaint(
              painter: GrandTourStageProfileDetailPainter(
                points: stage.elevationProfilePoints,
                accentColor: accent,
              ),
            ),
          ),
          if (stage.keyClimbs.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'KLUCZOWE PODJAZDY & SEKTORY',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stage.keyClimbs.map((climb) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${climb.categoryLabel} • ${climb.name}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${climb.lengthKm.toStringAsFixed(1)} km • śr. ${climb.avgGradientPct.toStringAsFixed(1)}% (max ${climb.maxGradientPct.toStringAsFixed(0)}%) • ${climb.altitudeM} m n.p.m.',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStagesListCard(
    GrandTourRouteRevealEdition edition, {
    double? maxListHeight,
  }) {
    final filtered =
        edition.stages.where((s) => _stageFilter.matches(s)).toList();

    final listContent = filtered.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Brak etapów pasujących do wybranego filtra.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          )
        : ListView.separated(
            shrinkWrap: maxListHeight != null,
            physics: maxListHeight != null
                ? const ClampingScrollPhysics()
                : const BouncingScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final stage = filtered[index];
              final isSelected = stage.stageNumber == _selectedStageNumber;
              return _StageListRowButton(
                stage: stage,
                isSelected: isSelected,
                onTap: () => setState(
                  () => _selectedStageNumber = stage.stageNumber,
                ),
              );
            },
          );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HARMONOGRAM 21 ETAPÓW',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: GrandTourStageFilter.values.map((filter) {
                final isSelected = _stageFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _InteractivePillTab(
                    label: filter.label,
                    isSelected: isSelected,
                    accentColor: edition.tourId.accentColor,
                    onTap: () => setState(() => _stageFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          if (maxListHeight != null)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxListHeight),
              child: listContent,
            )
          else
            Expanded(child: listContent),
        ],
      ),
    );
  }

  Widget _buildTacticalPlanCard(
    GrandTourRouteRevealEdition edition,
    GrandTourCeremonyPlanEntry plan,
    List<String> leaderCandidates, {
    required bool compact,
  }) {
    final accent = edition.tourId.accentColor;
    final canEdit = plan.isRevealed && !plan.isConfirmed;

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.isConfirmed
              ? AppColors.statusSuccess.withValues(alpha: 0.65)
              : AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DEKLARACJA CELU NA PRZYSZŁY SEZON',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (plan.isConfirmed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.statusSuccess.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ZATWIERDZONO',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.statusSuccess,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...GrandTourStrategicPriority.values.map((priority) {
            final isSelected = plan.priority == priority;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _PriorityOptionTile(
                priority: priority,
                isSelected: isSelected,
                isDisabled: !canEdit,
                onTap: () => _updatePriority(edition.tourId, priority),
              ),
            );
          }),
          const SizedBox(height: 8),
          const Text(
            'Wyznaczony Lider Ekipy',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: leaderCandidates.map((leader) {
              final isSelected = plan.selectedLeaderName == leader;
              return _InteractivePillTab(
                label: leader,
                isSelected: isSelected,
                isDisabled: !canEdit,
                accentColor: accent,
                onTap: () => _updateLeader(edition.tourId, leader),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _CeremonyActionButton(
            label: plan.isConfirmed
                ? 'Odblokuj Edycję Planu'
                : 'Zatwierdź Plan na ${edition.tourId.shortCode}',
            icon: plan.isConfirmed
                ? Icons.edit_rounded
                : Icons.check_circle_outline_rounded,
            accentColor:
                plan.isConfirmed ? AppColors.amberWarning : AppColors.statusSuccess,
            isPrimary: !plan.isConfirmed,
            isDisabled: !plan.isRevealed,
            onPressed: () => _toggleConfirmPlan(edition.tourId),
          ),
        ],
      ),
    );
  }
}

class _KeyValuePoint extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValuePoint({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              color: accent,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _TourSelectorCardButton extends StatefulWidget {
  final GrandTourRouteRevealEdition edition;
  final GrandTourCeremonyPlanEntry plan;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  const _TourSelectorCardButton({
    required this.edition,
    required this.plan,
    required this.isSelected,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_TourSelectorCardButton> createState() =>
      _TourSelectorCardButtonState();
}

class _TourSelectorCardButtonState extends State<_TourSelectorCardButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.edition.tourId.accentColor;
    final bgColor = widget.isSelected
        ? accent.withValues(alpha: 0.16)
        : (_isHovered ? AppColors.surfaceLight : AppColors.surface);
    final borderColor = _isFocused
        ? AppColors.accentBlue
        : (widget.isSelected
            ? accent
            : (_isHovered
                ? accent.withValues(alpha: 0.5)
                : AppTheme.borderColor));

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapCancel: () => setState(() => _isPressed = false),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 8 : 14,
              vertical: widget.compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected || _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.compact
                            ? widget.edition.tourId.shortCode
                            : widget.edition.tourId.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        widget.plan.isConfirmed
                            ? 'Plan gotowy'
                            : (widget.plan.isRevealed
                                ? 'Odsłonięto'
                                : 'Zasłonięto'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: widget.plan.isConfirmed
                              ? AppColors.statusSuccess
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StageRibbonBar extends StatefulWidget {
  final GrandTourRevealStageSpec stage;
  final double heightFraction;
  final bool isSelected;
  final VoidCallback onTap;

  const _StageRibbonBar({
    required this.stage,
    required this.heightFraction,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StageRibbonBar> createState() => _StageRibbonBarState();
}

class _StageRibbonBarState extends State<_StageRibbonBar> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.stage.stageType.color;
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message:
              'Etap ${widget.stage.stageNumber}: ${widget.stage.title} (${widget.stage.distanceKm.toStringAsFixed(0)} km, +${widget.stage.elevationGainM} m)',
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.stage.isQueenStage)
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.goldAccent,
                  size: 11,
                ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: widget.heightFraction,
                    widthFactor: 1.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: widget.isSelected || _isHovered
                            ? color
                            : color.withValues(alpha: 0.62),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        border: widget.isSelected || _isFocused
                            ? Border.all(
                                color: _isFocused
                                    ? AppColors.accentBlue
                                    : AppColors.textPrimary,
                                width: 1.4,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.stage.stageNumber}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: widget.isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight:
                      widget.isSelected ? FontWeight.w800 : FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageListRowButton extends StatefulWidget {
  final GrandTourRevealStageSpec stage;
  final bool isSelected;
  final VoidCallback onTap;

  const _StageListRowButton({
    required this.stage,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StageListRowButton> createState() => _StageListRowButtonState();
}

class _StageListRowButtonState extends State<_StageListRowButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.stage.stageType.color;
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? accent.withValues(alpha: 0.14)
                : (_isHovered
                    ? AppColors.surfaceLight
                    : AppColors.background.withValues(alpha: 0.55)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isFocused
                  ? AppColors.accentBlue
                  : (widget.isSelected
                      ? accent
                      : (_isHovered
                          ? AppColors.cardBorder
                          : AppTheme.borderColor)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.stage.stageNumber}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.stage.startCity} → ${widget.stage.finishCity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.stage.stageType.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.stage.distanceKm.toStringAsFixed(0)} km',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    '+${widget.stage.elevationGainM} m',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityOptionTile extends StatefulWidget {
  final GrandTourStrategicPriority priority;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _PriorityOptionTile({
    required this.priority,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_PriorityOptionTile> createState() => _PriorityOptionTileState();
}

class _PriorityOptionTileState extends State<_PriorityOptionTile> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.priority.accentColor;
    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      mouseCursor: widget.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: Opacity(
          opacity: widget.isDisabled ? 0.55 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? accent.withValues(alpha: 0.14)
                  : (_isHovered && !widget.isDisabled
                      ? AppColors.surfaceLight
                      : AppColors.background.withValues(alpha: 0.45)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isFocused
                    ? AppColors.accentBlue
                    : (widget.isSelected ? accent : AppTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                Icon(widget.priority.icon, color: accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.priority.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.priority.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractivePillTab extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final bool isDisabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractivePillTab({
    required this.label,
    this.icon,
    required this.isSelected,
    this.isDisabled = false,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractivePillTab> createState() => _InteractivePillTabState();
}

class _InteractivePillTabState extends State<_InteractivePillTab> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      mouseCursor: widget.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: Opacity(
          opacity: widget.isDisabled ? 0.5 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.accentColor.withValues(alpha: 0.18)
                  : (_isHovered && !widget.isDisabled
                      ? AppColors.surfaceLight
                      : AppColors.surface),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isFocused
                    ? AppColors.accentBlue
                    : (widget.isSelected
                        ? widget.accentColor
                        : AppTheme.borderColor),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 14,
                    color: widget.isSelected
                        ? widget.accentColor
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: widget.isSelected
                          ? widget.accentColor
                          : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight:
                          widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CeremonyActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isPrimary;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _CeremonyActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    this.isPrimary = false,
    this.isDisabled = false,
    required this.onPressed,
  });

  @override
  State<_CeremonyActionButton> createState() => _CeremonyActionButtonState();
}

class _CeremonyActionButtonState extends State<_CeremonyActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : (widget.isPrimary
            ? (_isHovered
                ? widget.accentColor.withValues(alpha: 0.92)
                : widget.accentColor)
            : (_isHovered
                ? widget.accentColor.withValues(alpha: 0.16)
                : AppColors.surfaceLight));

    final fgColor = widget.isDisabled
        ? AppColors.textSecondary
        : (widget.isPrimary ? AppColors.background : AppColors.textPrimary);

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      mouseCursor: widget.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: widget.isDisabled
            ? null
            : (_) => setState(() => _isPressed = true),
        onTapCancel: () => setState(() => _isPressed = false),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTap: widget.isDisabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused
                    ? AppColors.accentBlue
                    : (widget.isDisabled
                        ? AppTheme.borderColor
                        : widget.accentColor.withValues(alpha: 0.7)),
                width: _isFocused ? 1.6 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 16, color: fgColor),
                const SizedBox(width: 7),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: fgColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rysuje szczegółowy profil wysokościowy wybranego etapu.
class GrandTourStageProfileDetailPainter extends CustomPainter {
  final List<double> points;
  final Color accentColor;

  const GrandTourStageProfileDetailPainter({
    required this.points,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || size.width <= 0 || size.height <= 0) return;

    final gridPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.55)
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePath = Path();
    final fillPath = Path();
    for (int i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final y = size.height * (1.0 - points[i].clamp(0.05, 0.98));
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: 0.36),
          accentColor.withValues(alpha: 0.03),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final strokePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant GrandTourStageProfileDetailPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.accentColor != accentColor;
  }
}

class _CeremonyStageSpotlightPainter extends CustomPainter {
  final double phase;
  final Color accentColor;

  const _CeremonyStageSpotlightPainter({
    required this.phase,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final leftBeamCenter = size.width * (0.22 + 0.14 * phase);
    final rightBeamCenter = size.width * (0.78 - 0.14 * phase);

    final leftBeam = Path()
      ..moveTo(size.width * 0.18, 0)
      ..lineTo(leftBeamCenter - size.width * 0.16, size.height)
      ..lineTo(leftBeamCenter + size.width * 0.16, size.height)
      ..close();

    final rightBeam = Path()
      ..moveTo(size.width * 0.82, 0)
      ..lineTo(rightBeamCenter - size.width * 0.16, size.height)
      ..lineTo(rightBeamCenter + size.width * 0.16, size.height)
      ..close();

    final leftPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: 0.12),
          accentColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final rightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.goldAccent.withValues(alpha: 0.08),
          AppColors.goldAccent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(leftBeam, leftPaint);
    canvas.drawPath(rightBeam, rightPaint);
  }

  @override
  bool shouldRepaint(covariant _CeremonyStageSpotlightPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.accentColor != accentColor;
  }
}
