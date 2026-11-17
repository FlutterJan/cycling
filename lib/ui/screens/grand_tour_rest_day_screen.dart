// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/rider/rider.dart';
import '../../state/career_controller.dart';
import '../widgets/team_chef_daily_menu_planner_card.dart';

/// Rodzaj 3-tygodniowego Wielkiego Touru (Grand Tour).
enum GrandTourType {
  tourDeFrance(
    'Tour de France',
    'Żółta Koszulka (Maillot Jaune)',
    AppColors.goldAccent,
    'Francja',
    'assets/images/tdf_logo.png',
  ),
  giroDItalia(
    'Giro d\'Italia',
    'Różowa Koszulka (Maglia Rosa)',
    Color(0xFFFF69B4),
    'Włochy',
    'assets/images/giro_logo.png',
  ),
  vueltaAEspana(
    'Vuelta a España',
    'Czerwona Koszulka (La Roja)',
    Color(0xFFDC2626),
    'Hiszpania',
    'assets/images/vuelta_logo.png',
  ),
  customGrandTour(
    'Wielki Tour',
    'Klasyfikacja Generalna',
    AppColors.goldAccent,
    'Europa',
    null,
  );

  final String title;
  final String leaderJersey;
  final Color primaryColor;
  final String hostCountry;
  final String? logoAsset;

  const GrandTourType(
    this.title,
    this.leaderJersey,
    this.primaryColor,
    this.hostCountry,
    this.logoAsset,
  );
}

/// Numer i kontekst dnia przerwy w 3-tygodniowym Grand Tourze.
enum RestDayStageIndex {
  firstRestDay(
    9,
    10,
    'I Dzień Przerwy (po 9. etapie)',
    'Regeneracja przed wejściem w decydujące etapy wysokogórskie',
  ),
  secondRestDay(
    15,
    16,
    'II Dzień Przerwy (po 15. etapie)',
    'Ostatni oddech przed morderczym III tygodniem i decydującą czasówką',
  );

  final int completedStages;
  final int nextStageNumber;
  final String label;
  final String strategicContext;

  const RestDayStageIndex(
    this.completedStages,
    this.nextStageNumber,
    this.label,
    this.strategicContext,
  );
}

/// Dostępne protokoły przejażdżki regeneracyjnej (Coffee Ride).
enum CoffeeRideProtocol {
  activeRecoveryCoffeeRide(
    'Klasyczny Coffee Ride (Z1 - 38 km)',
    'Lekkie kręcenie w strefie Z1 z postojem na espresso i ciastko w lokalnej kawiarni. '
        'Znakomity odpoczynek psychiczny, ale umiarkowane ryzyko zastygnięcia nóg.',
    38.0,
    135.0,
    -32.0,
    12,
    22.0,
    'Relaksacyjny (Umiarkowane ryzyko zablokowania nóg na 1. podjeździe)',
    Icons.coffee,
  ),
  primerOpenersRide(
    'Primer & Openers Ride (45 km z 3x30s zrywami)',
    '38 km w strefie Z1 + 3 dynamiczne 30-sekundowe zrywy na progu beztlenowym. '
        'Pobudza włókna szybkokurczliwe i układ nerwowy – ZAPOBIEGA zastygnięciu nóg przed etapem HC!',
    45.0,
    165.0,
    -26.0,
    8,
    0.0,
    'Optymalny wyścigowy (Zero ryzyka zastygnięcia nóg, pełna reaktywność!)',
    Icons.bolt,
  ),
  enduranceSpin(
    'Trening Tlenowy Pomocników (Z2 - 62 km)',
    'Dłuższy rozjazd w strefie Z2 dla pomocników i uciekinierów, by utrzymać wydolność tlenową. '
        'Mniejszy spadek zmęczenia, ale gotowość do walki na rantach.',
    62.0,
    210.0,
    -15.0,
    4,
    5.0,
    'Utrzymana wysoka gotowość tlenowa',
    Icons.directions_bike,
  ),
  totalBedRest(
    'Całkowity Odpoczynek w Łóżku (Day Off / Hotel Rest)',
    'Kolarze nie dotykają roweru przez 24 godziny i leżą w łóżku hotelowym. '
        'Maksymalny spadek zmęczenia, ale BARDZO WYSOKIE RYZYKO zastygnięcia nóg (-10% mocy na 1. wspinaczce)!',
    0.0,
    0.0,
    -48.0,
    6,
    65.0,
    'Letargiczny / Uśpiony (Ciężkie, drewniane nogi na pierwszym podjeździe)',
    Icons.hotel,
  );

  final String title;
  final String description;
  final double distanceKm;
  final double averageWatts;
  final double fatigueDeltaPercent;
  final int moraleBonus;
  final double legsStiffnessRiskPercent;
  final String muscleToneDescription;
  final IconData icon;

  const CoffeeRideProtocol(
    this.title,
    this.description,
    this.distanceKm,
    this.averageWatts,
    this.fatigueDeltaPercent,
    this.moraleBonus,
    this.legsStiffnessRiskPercent,
    this.muscleToneDescription,
    this.icon,
  );
}

/// Dostępne zabiegi medyczne i fizjoterapeutyczne w hotelu drużynowym.
enum PhysiotherapyTreatment {
  deepTissueMassage(
    'Głęboki Masaż Sportowy (Deep Tissue & Myofascial)',
    'Masaż powięziowy i rozbijanie mikrozrostów przez masażystów (Soigneurs).',
    -22.0,
    -10.0,
    Icons.spa,
    Color(0xFF38BDF8),
  ),
  lymphaticBoots(
    'Nogawki Kompresyjne Normatec (Drenaż Limfatyczny)',
    'Pneumatyczny masaż uciskowy wypłukujący metabolity i usuwający opuchliznę nóg.',
    -18.0,
    -5.0,
    Icons.air,
    Color(0xFF10B981),
  ),
  wholeBodyCryotherapy(
    'Krioterapia Całego Ciała (-110°C Cryo-Chamber)',
    '3-minutowa sesja w ciekłym azocie gasząca stany zapalne po kraksach i mikrourazach.',
    -15.0,
    -35.0,
    Icons.ac_unit,
    Color(0xFF818CF8),
  ),
  osteopathicRealignment(
    'Terapia Manualna & Nastawianie Miednicy',
    'Mobilizacja stawów krzyżowo-biodrowych i dekompresja kręgosłupa po upadkach.',
    -12.0,
    -25.0,
    Icons.healing,
    AppColors.goldAccent,
  );

  final String title;
  final String description;
  final double fatigueReductionPercent;
  final double injuryPainReductionPercent;
  final IconData icon;
  final Color badgeColor;

  const PhysiotherapyTreatment(
    this.title,
    this.description,
    this.fatigueReductionPercent,
    this.injuryPainReductionPercent,
    this.icon,
    this.badgeColor,
  );
}

/// Pytanie konferencji prasowej w Dniu Przerwy z wariantami odpowiedzi menedżera.
class RestDayPressQuestion {
  final String journalistOutlet;
  final String journalistName;
  final String questionText;
  final List<RestDayPressOption> options;

  const RestDayPressQuestion({
    required this.journalistOutlet,
    required this.journalistName,
    required this.questionText,
    required this.options,
  });
}

/// Opcja odpowiedzi menedżera na pytanie dziennikarza.
class RestDayPressOption {
  final String answerText;
  final String toneLabel;
  final int leaderMoraleDelta;
  final int mediaPressureDelta;
  final int sponsorSatisfactionDelta;
  final String reactionSummary;

  const RestDayPressOption({
    required this.answerText,
    required this.toneLabel,
    required this.leaderMoraleDelta,
    required this.mediaPressureDelta,
    required this.sponsorSatisfactionDelta,
    required this.reactionSummary,
  });
}

/// Karta kolarza z drużyny na ekranie Dnia Przerwy.
class RestDayRiderCardState {
  final String id;
  final String name;
  final int bibNumber;
  final bool isLeader;
  final double currentFatiguePercent; // 0 - 100%
  final String? injuryDescription;
  final double injurySeverityPercent; // 0 - 100%
  final PhysiotherapyTreatment? assignedTreatment;
  final CoffeeRideProtocol assignedRide;

  const RestDayRiderCardState({
    required this.id,
    required this.name,
    required this.bibNumber,
    this.isLeader = false,
    this.currentFatiguePercent = 65.0,
    this.injuryDescription,
    this.injurySeverityPercent = 0.0,
    this.assignedTreatment,
    this.assignedRide = CoffeeRideProtocol.primerOpenersRide,
  });

  RestDayRiderCardState copyWith({
    String? id,
    String? name,
    int? bibNumber,
    bool? isLeader,
    double? currentFatiguePercent,
    String? injuryDescription,
    bool clearInjury = false,
    double? injurySeverityPercent,
    PhysiotherapyTreatment? assignedTreatment,
    bool clearTreatment = false,
    CoffeeRideProtocol? assignedRide,
  }) {
    return RestDayRiderCardState(
      id: id ?? this.id,
      name: name ?? this.name,
      bibNumber: bibNumber ?? this.bibNumber,
      isLeader: isLeader ?? this.isLeader,
      currentFatiguePercent: currentFatiguePercent ?? this.currentFatiguePercent,
      injuryDescription: clearInjury ? null : (injuryDescription ?? this.injuryDescription),
      injurySeverityPercent: injurySeverityPercent ?? this.injurySeverityPercent,
      assignedTreatment: clearTreatment ? null : (assignedTreatment ?? this.assignedTreatment),
      assignedRide: assignedRide ?? this.assignedRide,
    );
  }
}

/// Raport końcowy z przeprowadzonego Dnia Przerwy przekazywany do silnika wyścigu.
class RestDaySummaryReport {
  final CoffeeRideProtocol primaryCoffeeRide;
  final double averageFatigueReduction;
  final double averageFinalFatigue;
  final bool hasHeavyLegsRisk;
  final int treatmentsAdministeredCount;
  final int leaderMoraleChange;
  final int sponsorSatisfactionChange;
  final String pressHeadline;

  const RestDaySummaryReport({
    required this.primaryCoffeeRide,
    required this.averageFatigueReduction,
    required this.averageFinalFatigue,
    required this.hasHeavyLegsRisk,
    required this.treatmentsAdministeredCount,
    required this.leaderMoraleChange,
    required this.sponsorSatisfactionChange,
    required this.pressHeadline,
  });
}

/// Dedykowany ekran Dnia Przerwy (Grand Tour Rest Day Screen).
class GrandTourRestDayScreen extends ConsumerStatefulWidget {
  final GrandTourType grandTourType;
  final RestDayStageIndex restDayIndex;
  final String locationCity;
  final List<RestDayRiderCardState>? initialRiders;
  final VoidCallback? onBack;
  final void Function(RestDaySummaryReport report)? onProceedToNextStage;

  const GrandTourRestDayScreen({
    super.key,
    this.grandTourType = GrandTourType.tourDeFrance,
    this.restDayIndex = RestDayStageIndex.firstRestDay,
    this.locationCity = 'Morzine / Pau',
    this.initialRiders,
    this.onBack,
    this.onProceedToNextStage,
  });

  @override
  ConsumerState<GrandTourRestDayScreen> createState() =>
      _GrandTourRestDayScreenState();
}

class _GrandTourRestDayScreenState extends ConsumerState<GrandTourRestDayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late CoffeeRideProtocol _selectedRideProtocol;
  bool _applyRideToAll = true;

  late List<RestDayRiderCardState> _riders;

  // Stan pytań konferencji prasowej (indeks pytania i wybrane odpowiedzi)
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  int _pressMoraleScore = 0;
  int _pressSponsorScore = 0;
  int _pressMediaPressure = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedRideProtocol = CoffeeRideProtocol.primerOpenersRide;

    if (widget.initialRiders != null && widget.initialRiders!.isNotEmpty) {
      _riders = List.from(widget.initialRiders!);
    } else {
      _riders = _generateDefaultSquad();
    }

    // Załadowanie kolarzy z aktywnej kariery, jeśli istnieją
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFromActiveCareer();
    });
  }

  void _initFromActiveCareer() {
    final curSave = ref.read(careerControllerProvider).save;
    if (curSave != null && widget.initialRiders == null) {
      final roster = curSave.playerRoster;
      if (roster.isNotEmpty) {
        final List<RestDayRiderCardState> careerRiders = [];
        final squad = roster.take(8).toList();

        for (int i = 0; i < squad.length; i++) {
          final Rider r = squad[i];
          final bool isLeader = i == 0;
          final double fatigue = (r.health.acuteTrainingLoad / 1.5).clamp(25.0, 95.0);
          final injury = r.health.currentInjury;
          final String? injuryDesc = injury != null
              ? '${injury.name} (${injury.daysRemaining} dni)'
              : (i == 1 ? 'Szlify prawego biodra po kraksie w ulewie' : null);

          careerRiders.add(RestDayRiderCardState(
            id: r.id,
            name: '${r.firstName} ${r.lastName}',
            bibNumber: i + 1,
            isLeader: isLeader,
            currentFatiguePercent: fatigue,
            injuryDescription: injuryDesc,
            injurySeverityPercent: injury != null ? 50.0 : (i == 1 ? 25.0 : 0.0),
            assignedRide: _selectedRideProtocol,
          ));
        }

        setState(() {
          _riders = careerRiders;
        });
      }
    }
  }

  List<RestDayRiderCardState> _generateDefaultSquad() {
    return [
      const RestDayRiderCardState(
        id: 'r1',
        name: 'Tadej Pogačar',
        bibNumber: 1,
        isLeader: true,
        currentFatiguePercent: 68.0,
        injuryDescription: null,
      ),
      const RestDayRiderCardState(
        id: 'r2',
        name: 'Rafał Majka',
        bibNumber: 2,
        isLeader: false,
        currentFatiguePercent: 74.0,
        injuryDescription: 'Szlify prawego biodra po kraksie na 7. etapie',
        injurySeverityPercent: 35.0,
      ),
      const RestDayRiderCardState(
        id: 'r3',
        name: 'Adam Yates',
        bibNumber: 3,
        isLeader: false,
        currentFatiguePercent: 71.0,
        injuryDescription: null,
      ),
      const RestDayRiderCardState(
        id: 'r4',
        name: 'Tim Wellens',
        bibNumber: 4,
        isLeader: false,
        currentFatiguePercent: 62.0,
        injuryDescription: null,
      ),
      const RestDayRiderCardState(
        id: 'r5',
        name: 'Pavel Sivakov',
        bibNumber: 5,
        isLeader: false,
        currentFatiguePercent: 69.0,
        injuryDescription: 'Przeciążenie pasma biodrowo-piszczelowego ITB',
        injurySeverityPercent: 40.0,
      ),
      const RestDayRiderCardState(
        id: 'r6',
        name: 'Nils Politt',
        bibNumber: 6,
        isLeader: false,
        currentFatiguePercent: 78.0,
        injuryDescription: null,
      ),
      const RestDayRiderCardState(
        id: 'r7',
        name: 'Marc Soler',
        bibNumber: 7,
        isLeader: false,
        currentFatiguePercent: 75.0,
        injuryDescription: 'Stłuczenie żeber po upadku w peletonie',
        injurySeverityPercent: 50.0,
      ),
      const RestDayRiderCardState(
        id: 'r8',
        name: 'Domen Novak',
        bibNumber: 8,
        isLeader: false,
        currentFatiguePercent: 64.0,
        injuryDescription: null,
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // PYTANIA KONFERENCJI PRASOWEJ
  // ===========================================================================

  List<RestDayPressQuestion> _getPressQuestions() {
    return const [
      RestDayPressQuestion(
        journalistOutlet: 'L\'Équipe',
        journalistName: 'Philippe Brunel',
        questionText:
            'Za nami morderczy pierwszy blok etapów. Wasz lider jedzie na czele klasyfikacji generalnej, '
            'ale rywale zapowiadają bezpardonowy atak już jutro na pierwszym alpejskim podjeździe. '
            'Czy zespół wytrzyma to tempo?',
        options: [
          RestDayPressOption(
            answerText:
                'Jesteśmy w życiowej formie. Nie boimy się nikogo. Jeśli spróbują zaatakować, skontrujemy ich z podwójną siłą!',
            toneLabel: 'Pewność Siebie & Atak',
            leaderMoraleDelta: 8,
            mediaPressureDelta: 6,
            sponsorSatisfactionDelta: 10,
            reactionSummary: 'Odważna deklaracja! Media zachwycone bezkompromisową postawą.',
          ),
          RestDayPressOption(
            answerText:
                'Wyścig trwa trzy tygodnie, a Tour wygrywa się chłodną głową w trzecim tygodniu. Mamy swój plan i konsekwentnie go realizujemy.',
            toneLabel: 'Spokojna Dyplomacja',
            leaderMoraleDelta: 4,
            mediaPressureDelta: -4,
            sponsorSatisfactionDelta: 5,
            reactionSummary: 'Profesjonalny spokój. Lider czuje się bezpiecznie bez zbędnej presji.',
          ),
          RestDayPressOption(
            answerText:
                'To nasi rywale mają stratę i to na nich spoczywa cała presja gonienia wyniku. My możemy jechać defensywnie i czekać na ich błąd.',
            toneLabel: 'Przeniesienie Presji',
            leaderMoraleDelta: 5,
            mediaPressureDelta: -8,
            sponsorSatisfactionDelta: 6,
            reactionSummary: 'Sprytne posunięcie psychologiczne – ciężar walki przerzucony na rywali.',
          ),
        ],
      ),
      RestDayPressQuestion(
        journalistOutlet: 'La Gazzetta dello Sport',
        journalistName: 'Ciro Scognamiglio',
        questionText:
            'Wielu kolarzy poobijało się na wietrznych etapach i brukach. '
            'Jak oceniacie stan zdrowia pomocników przed górskimi etapami HC?',
        options: [
          RestDayPressOption(
            answerText:
                'Nasi fizjoterapeuci wykonali dziś tytaniczną pracę w hotelu. Zespół jest zregenerowany i zwarty.',
            toneLabel: 'Pochwała Sztabu',
            leaderMoraleDelta: 6,
            mediaPressureDelta: 0,
            sponsorSatisfactionDelta: 6,
            reactionSummary: 'Sztab medyczny doceniony, a zespół czuje jedność.',
          ),
          RestDayPressOption(
            answerText:
                'Kolarstwo to sport twardych ludzi. Każdy ma szlify, ale nikt nie narzeka. Jutro od startu jedziemy na 100%.',
            toneLabel: 'Twardy Wojownik',
            leaderMoraleDelta: 7,
            mediaPressureDelta: 3,
            sponsorSatisfactionDelta: 8,
            reactionSummary: 'Bojowy duch w peletonie. Kibice doceniają waleczność.',
          ),
        ],
      ),
      RestDayPressQuestion(
        journalistOutlet: 'Cyclingnews / Eurosport',
        journalistName: 'Daniel Benson',
        questionText:
            'Wielu menedżerów boi się tzw. "zastygnięcia nóg" po dniu przerwy. '
            'Jaki protokół rozjazdu wybraliście dzisiaj na Coffee Ride?',
        options: [
          RestDayPressOption(
            answerText:
                'Zrobiliśmy idealny Primer z trzema mocnymi zrywami na progu. Nogi są pobudzone i jutro od pierwszego kilometra będziemy gotowi na ogień!',
            toneLabel: 'Gotowość Wyścigowa',
            leaderMoraleDelta: 5,
            mediaPressureDelta: 2,
            sponsorSatisfactionDelta: 5,
            reactionSummary: 'Świetna taktyka fizjologiczna – kolarze czują moc w nogach.',
          ),
          RestDayPressOption(
            answerText:
                'Postawiliśmy na kawę, relaks i regenerację psychiczną. Psychika jest w trzecim tygodniu ważniejsza niż waty.',
            toneLabel: 'Balans Psychiczny',
            leaderMoraleDelta: 6,
            mediaPressureDelta: -3,
            sponsorSatisfactionDelta: 4,
            reactionSummary: 'Lider zrelaksowany i uśmiechnięty na konferencji.',
          ),
        ],
      ),
    ];
  }

  // ===========================================================================
  // INTERAKCJE I METODY LOGICZNE
  // ===========================================================================

  void _onCoffeeRideSelected(CoffeeRideProtocol protocol) {
    setState(() {
      _selectedRideProtocol = protocol;
      if (_applyRideToAll) {
        _riders = _riders.map((r) => r.copyWith(assignedRide: protocol)).toList();
      }
    });
  }

  void _assignTreatment(String riderId, PhysiotherapyTreatment treatment) {
    setState(() {
      _riders = _riders.map((r) {
        if (r.id == riderId) {
          // Jeśli już ten zabieg był przypisany – zdejmij go
          if (r.assignedTreatment == treatment) {
            return r.copyWith(clearTreatment: true);
          } else {
            return r.copyWith(assignedTreatment: treatment);
          }
        }
        return r;
      }).toList();
    });
  }

  void _onAnswerPressQuestion(int questionIndex, int optionIndex) {
    final question = _getPressQuestions()[questionIndex];
    final option = question.options[optionIndex];

    setState(() {
      _selectedAnswers[questionIndex] = optionIndex;
      _pressMoraleScore += option.leaderMoraleDelta;
      _pressSponsorScore += option.sponsorSatisfactionDelta;
      _pressMediaPressure += option.mediaPressureDelta;
    });
  }

  void _finishRestDay() {
    // 1. Obliczenie statystyk regeneracji
    double totalFatigueReduction = 0.0;
    double totalFinalFatigue = 0.0;
    int treatmentsCount = 0;

    for (final r in _riders) {
      final rideReduction = r.assignedRide.fatigueDeltaPercent.abs();
      final physioReduction = r.assignedTreatment != null
          ? r.assignedTreatment!.fatigueReductionPercent.abs()
          : 0.0;

      final combinedReduction = rideReduction + physioReduction;
      totalFatigueReduction += combinedReduction;

      final finalFatigue = (r.currentFatiguePercent - combinedReduction).clamp(10.0, 100.0);
      totalFinalFatigue += finalFatigue;

      if (r.assignedTreatment != null) treatmentsCount++;
    }

    final double avgReduction = _riders.isNotEmpty ? totalFatigueReduction / _riders.length : 0.0;
    final double avgFinalFatigue = _riders.isNotEmpty ? totalFinalFatigue / _riders.length : 0.0;
    final bool hasHeavyLegsRisk = _selectedRideProtocol == CoffeeRideProtocol.totalBedRest ||
        _selectedRideProtocol == CoffeeRideProtocol.activeRecoveryCoffeeRide;

    final report = RestDaySummaryReport(
      primaryCoffeeRide: _selectedRideProtocol,
      averageFatigueReduction: avgReduction,
      averageFinalFatigue: avgFinalFatigue,
      hasHeavyLegsRisk: hasHeavyLegsRisk,
      treatmentsAdministeredCount: treatmentsCount,
      leaderMoraleChange: _pressMoraleScore + _selectedRideProtocol.moraleBonus,
      sponsorSatisfactionChange: _pressSponsorScore,
      pressHeadline: _pressMoraleScore >= 12
          ? 'Niezachwiana pewność siebie! Zespół gotowy na królewski etap w chmurach'
          : 'Spokój przed burzą: Perfekcyjna regeneracja w hotelu przed górami',
    );

    _showSummaryDialog(report);
  }

  void _showSummaryDialog(RestDaySummaryReport report) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.goldAccent, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.hotel_class, color: AppColors.goldAccent, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Dzień Przerwy Zakończony!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.pressHeadline,
                style: const TextStyle(
                  color: AppColors.goldAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Średnia regeneracja zmęczenia:',
                      '-${report.averageFatigueReduction.toStringAsFixed(1)}%',
                      AppColors.statusSuccess,
                    ),
                    const SizedBox(height: 6),
                    _buildSummaryRow(
                      'Średnie zmęczenie zespołu:',
                      '${report.averageFinalFatigue.toStringAsFixed(1)}%',
                      AppColors.textPrimary,
                    ),
                    const SizedBox(height: 6),
                    _buildSummaryRow(
                      'Zabiegi fizjoterapeutyczne:',
                      '${report.treatmentsAdministeredCount} wykonanych',
                      AppColors.cyanAccent,
                    ),
                    const SizedBox(height: 6),
                    _buildSummaryRow(
                      'Morale lidera i zespołu:',
                      '+${report.leaderMoraleChange} pkt',
                      AppColors.goldAccent,
                    ),
                    const SizedBox(height: 6),
                    _buildSummaryRow(
                      'Gotowość nóg na 1. podjazd:',
                      report.hasHeavyLegsRisk
                          ? 'Umiarkowane ryzyko zastygnięcia'
                          : 'Optymalna reaktywność (Zero zastygnięcia!)',
                      report.hasHeavyLegsRisk ? AppColors.amberWarning : AppColors.statusSuccess,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                if (widget.onProceedToNextStage != null) {
                  widget.onProceedToNextStage!(report);
                } else if (widget.onBack != null) {
                  widget.onBack!();
                }
              },
              child: Text(
                'Wyrusz na Etap ${widget.restDayIndex.nextStageNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }

  // ===========================================================================
  // BUDOWA GŁÓWNA EKRANU (BUILD)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final gt = widget.grandTourType;
    final restDay = widget.restDayIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    '${gt.title} • ${restDay.label}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: gt.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: gt.primaryColor, width: 1),
                  ),
                  child: Text(
                    gt.hostCountry,
                    style: TextStyle(
                      color: gt.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Hotel Drużynowy: ${widget.locationCity} • ${restDay.strategicContext}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: gt.primaryColor,
          labelColor: gt.primaryColor,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.coffee), text: 'Coffee Ride (Rozjazd)'),
            Tab(icon: Icon(Icons.mic), text: 'Konferencja Prasowa'),
            Tab(icon: Icon(Icons.healing), text: 'Fizjoterapia i Medycyna'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: gt.primaryColor,
                foregroundColor: Colors.black,
                elevation: 2,
              ),
              icon: const Icon(Icons.flag, size: 18),
              label: const Text(
                'Zakończ Dzień Przerwy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: _finishRestDay,
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Zakładka Coffee Ride
          _buildCoffeeRideTab(),

          // 2. Zakładka Konferencji Prasowej
          _buildPressConferenceTab(),

          // 3. Zakładka Fizjoterapii
          _buildPhysiotherapyTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // ZAKŁADKA 1: COFFEE RIDE
  // ===========================================================================

  Widget _buildCoffeeRideTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Karta informacyjna o fizjologii dnia przerwy
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, color: AppColors.goldAccent, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Złota Zasada Dnia Przerwy w Wielkim Tourze:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.goldAccent),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Kolarze nie mogą spędzić całego dnia w bezruchu! Brak wysiłku powoduje spadek napięcia '
                      'mięśniowego i tzw. "zastygnięcie nóg" na pierwszym alpejskim podjeździe kolejnego etapu. '
                      'Optymalny Coffee Ride pobudza układ nerwowy bez uszczerbku na zapasach glikogenu.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textPrimary, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Przełącznik dla całej drużyny
        SwitchListTile(
          title: const Text('Zastosuj wybrany protokół dla całej 8-osobowej drużyny', style: TextStyle(fontSize: 12.5)),
          subtitle: const Text('Wszyscy kolarze wykonają ten sam wariant Coffee Ride', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          value: _applyRideToAll,
          activeThumbColor: AppColors.goldAccent,
          onChanged: (val) => setState(() => _applyRideToAll = val),
        ),

        const SizedBox(height: 10),

        // Wybór protokołów
        const Text(
          'Wybierz Protokół Przejażdżki Regeneracyjnej (Coffee Ride):',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),

        ...CoffeeRideProtocol.values.map((protocol) {
          final isSelected = _selectedRideProtocol == protocol;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surfaceLight : AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.goldAccent : AppColors.cardBorder,
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _onCoffeeRideSelected(protocol),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            protocol.icon,
                            color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              protocol.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.goldAccent : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: AppColors.goldAccent, size: 20),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        protocol.description,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildChipBadge(
                            'Dystans: ${protocol.distanceKm.round()} km',
                            Icons.route,
                            AppColors.accentBlue,
                          ),
                          _buildChipBadge(
                            'Śr. moc: ${protocol.averageWatts.round()} W',
                            Icons.speed,
                            AppColors.textPrimary,
                          ),
                          _buildChipBadge(
                            'Zmęczenie: ${protocol.fatigueDeltaPercent.round()}%',
                            Icons.battery_charging_full,
                            AppColors.statusSuccess,
                          ),
                          _buildChipBadge(
                            'Morale: +${protocol.moraleBonus}',
                            Icons.sentiment_very_satisfied,
                            AppColors.goldAccent,
                          ),
                          _buildChipBadge(
                            'Zastygnięcie nóg: ${protocol.legsStiffnessRiskPercent.round()}%',
                            Icons.warning_amber,
                            protocol.legsStiffnessRiskPercent > 30
                                ? AppColors.crimsonAlert
                                : (protocol.legsStiffnessRiskPercent > 0
                                    ? AppColors.amberWarning
                                    : AppColors.statusSuccess),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildChipBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ZAKŁADKA 2: KONFERENCJA PRASOWA
  // ===========================================================================

  Widget _buildPressConferenceTab() {
    final questions = _getPressQuestions();
    final curQ = questions[_currentQuestionIndex];
    final selectedOptionIndex = _selectedAnswers[_currentQuestionIndex];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Ścianka konferencyjna z mikrofonami
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.crimsonAlert.withValues(alpha: 0.2),
                          border: Border.all(color: AppColors.crimsonAlert),
                        ),
                        child: const Icon(Icons.mic, color: AppColors.crimsonAlert, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Oficjalna Konferencja Prasowa UCI (Media Day)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Sala konferencyjna hotelu drużynowego • Transmisja na żywo',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.crimsonAlert,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('ON AIR',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Pasek wskaźników presji mediów
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPressIndicator('Morale Lidera', '+$_pressMoraleScore', AppColors.goldAccent),
                  _buildPressIndicator('Zaufanie Sponsorów', '+$_pressSponsorScore%', AppColors.statusSuccess),
                  _buildPressIndicator('Presja Mediów', '$_pressMediaPressure pkt', AppColors.accentBlue),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Karta aktualnego pytania dziennikarza
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.goldAccent.withValues(alpha: 0.2),
                    child: Text(
                      curQ.journalistOutlet[0],
                      style: const TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${curQ.journalistName} • ${curQ.journalistOutlet}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.goldAccent),
                  ),
                  const Spacer(),
                  Text(
                    'Pytanie ${_currentQuestionIndex + 1} z ${questions.length}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '„${curQ.questionText}”',
                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textPrimary, height: 1.35),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 3. Warianty odpowiedzi
        const Text(
          'Odpowiedź Menedżera / Dyrektora Sportowego:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),

        ...List.generate(curQ.options.length, (optIdx) {
          final opt = curQ.options[optIdx];
          final isChosen = selectedOptionIndex == optIdx;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isChosen ? AppColors.surfaceLight : AppColors.cardDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isChosen ? AppColors.goldAccent : AppColors.cardBorder,
                width: isChosen ? 1.6 : 1.0,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                title: Text(
                  opt.answerText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                    color: isChosen ? AppColors.goldAccent : AppColors.textPrimary,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Text('Styl: ${opt.toneLabel}',
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                      Text('Morale: +${opt.leaderMoraleDelta}',
                          style: const TextStyle(fontSize: 10.5, color: AppColors.statusSuccess)),
                    ],
                  ),
                ),
                trailing: isChosen
                    ? const Icon(Icons.check_circle, color: AppColors.goldAccent)
                    : const Icon(Icons.radio_button_unchecked, color: AppColors.textSecondary),
                onTap: () => _onAnswerPressQuestion(_currentQuestionIndex, optIdx),
              ),
            ),
          );
        }),

        // Nawigacja między pytaniami
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Poprzednie pytanie'),
              onPressed: _currentQuestionIndex > 0
                  ? () => setState(() => _currentQuestionIndex--)
                  : null,
            ),
            TextButton.icon(
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Następne pytanie'),
              onPressed: _currentQuestionIndex < questions.length - 1
                  ? () => setState(() => _currentQuestionIndex++)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPressIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
      ],
    );
  }

  // ===========================================================================
  // ZAKŁADKA 3: FIZJOTERAPIA I MEDYCYNA
  // ===========================================================================

  Widget _buildPhysiotherapyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Nagłówek strefy regeneracji
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: const Row(
            children: [
              Icon(Icons.medical_services_outlined, color: AppColors.cyanAccent, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sztab Medyczny i Strefa Regeneracji Hotelu',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(height: 2),
                    Text(
                      'Przydziel intensywne zabiegi (Masaż, Normatec, Krioterapia, Osteopatia) najbardziej '
                      'poobijanym i zmęczonym kolarzom przed nadchodzącym tygodniem.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Lista kolarzy z ich kontuzjami i zabiegami
        const Text('Stan Kolarzy i Przydział Zabiegów:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),

        ..._riders.map((rider) {
          final hasInjury = rider.injuryDescription != null && rider.injuryDescription!.isNotEmpty;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: rider.isLeader ? AppColors.goldAccent : AppColors.cardBorder,
                width: rider.isLeader ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Górna belka kolarza
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: rider.isLeader ? AppColors.goldAccent : AppColors.cardBorder,
                          child: Text(
                            '${rider.bibNumber}',
                            style: TextStyle(
                              color: rider.isLeader ? Colors.black : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          rider.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: rider.isLeader ? AppColors.goldAccent : AppColors.textPrimary,
                          ),
                        ),
                        if (rider.isLeader) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.goldAccent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('LIDER GC',
                                style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'Zmęczenie: ${rider.currentFatiguePercent.round()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: rider.currentFatiguePercent > 70
                            ? AppColors.crimsonAlert
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                // Obrażenia po kraksie (jeśli występują)
                if (hasInjury) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.crimsonAlert.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.crimsonAlert.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: AppColors.crimsonAlert, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Uraz: ${rider.injuryDescription!}',
                            style: const TextStyle(fontSize: 11, color: AppColors.crimsonAlert, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Wybór zabiegu fizjoterapeutycznego dla kolarza
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: PhysiotherapyTreatment.values.map((treatment) {
                    final isAssigned = rider.assignedTreatment == treatment;

                    return ChoiceChip(
                      avatar: Icon(
                        treatment.icon,
                        size: 13,
                        color: isAssigned ? Colors.black : treatment.badgeColor,
                      ),
                      label: Text(
                        treatment.title.split(' ')[0], // Skrócona nazwa
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isAssigned ? FontWeight.bold : FontWeight.normal,
                          color: isAssigned ? Colors.black : AppColors.textPrimary,
                        ),
                      ),
                      selected: isAssigned,
                      selectedColor: treatment.badgeColor,
                      backgroundColor: AppColors.cardDark,
                      onSelected: (_) => _assignTreatment(rider.id, treatment),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        const TeamChefDailyMenuPlannerCard(),
      ],
    );
  }
}
