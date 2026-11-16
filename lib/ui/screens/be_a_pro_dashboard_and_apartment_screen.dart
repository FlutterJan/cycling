import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/career/pro_cyclist_career_state.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_appearance.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/rider/rider_health.dart';
import '../../models/rider/rider_physiology.dart';
import '../../models/rider/rider_power_profile.dart';
import '../../models/rider/rider_skills.dart';
import '../../models/team/cycling_team.dart';

/// Sekcje głównego ekranu trybu Be a Pro ("Zostań Legendą").
enum BeAProDashboardSection {
  apartment,
  skillTree,
  messages,
  contracts,
  trophyCabinet;

  String get label {
    switch (this) {
      case BeAProDashboardSection.apartment:
        return 'Apartament';
      case BeAProDashboardSection.skillTree:
        return 'Rozwój XP';
      case BeAProDashboardSection.messages:
        return 'SMS (DS & Agent)';
      case BeAProDashboardSection.contracts:
        return 'Oferty WT';
      case BeAProDashboardSection.trophyCabinet:
        return 'Gablota';
    }
  }

  IconData get icon {
    switch (this) {
      case BeAProDashboardSection.apartment:
        return Icons.home_work_rounded;
      case BeAProDashboardSection.skillTree:
        return Icons.account_tree_rounded;
      case BeAProDashboardSection.messages:
        return Icons.sms_rounded;
      case BeAProDashboardSection.contracts:
        return Icons.assignment_turned_in_rounded;
      case BeAProDashboardSection.trophyCabinet:
        return Icons.emoji_events_rounded;
    }
  }
}

/// Gałąź drzewa rozwoju kolarza.
enum BeAProSkillBranch {
  physiological,
  technical;

  String get label {
    switch (this) {
      case BeAProSkillBranch.physiological:
        return 'Gałąź Fizjologiczna';
      case BeAProSkillBranch.technical:
        return 'Gałąź Techniczna';
    }
  }
}

/// Identyfikator węzła w drzewie rozwoju umiejętności Be a Pro.
enum BeAProSkillNodeId {
  ftpThreshold,
  wPrimeAnaerobic,
  vo2MaxEngine,
  recoveryBiology,
  glycogenTank,
  aeroPosition,
  cobblesMastery,
  descendingLines,
  pelotonDrafting,
  raceIqTactics,
  ttSpecialist,
}

/// Węzeł drzewa rozwoju umiejętności kolarza za punkty XP / SP.
class BeAProSkillNode {
  final BeAProSkillNodeId id;
  final BeAProSkillBranch branch;
  final int tier;
  final BeAProSkillNodeId? prerequisiteId;
  final String title;
  final String subtitle;
  final String deltaLabel;
  final int costSkillPoints;
  final int maxLevel;
  final int currentLevel;
  final IconData icon;
  final Color accentColor;

  const BeAProSkillNode({
    required this.id,
    required this.branch,
    required this.tier,
    this.prerequisiteId,
    required this.title,
    required this.subtitle,
    required this.deltaLabel,
    required this.costSkillPoints,
    required this.maxLevel,
    required this.currentLevel,
    required this.icon,
    required this.accentColor,
  });

  bool get isMaxed => currentLevel >= maxLevel;

  BeAProSkillNode copyWith({int? currentLevel}) {
    return BeAProSkillNode(
      id: id,
      branch: branch,
      tier: tier,
      prerequisiteId: prerequisiteId,
      title: title,
      subtitle: subtitle,
      deltaLabel: deltaLabel,
      costSkillPoints: costSkillPoints,
      maxLevel: maxLevel,
      currentLevel: currentLevel ?? this.currentLevel,
      icon: icon,
      accentColor: accentColor,
    );
  }
}

/// Nadawca wiadomości SMS w trybie Be a Pro.
enum BeAProSmsSenderRole {
  sportsDirector,
  agent,
  performanceCoach;

  String get badgeLabel {
    switch (this) {
      case BeAProSmsSenderRole.sportsDirector:
        return 'DYREKTOR SPORTOWY';
      case BeAProSmsSenderRole.agent:
        return 'AGENT UCI';
      case BeAProSmsSenderRole.performanceCoach:
        return 'TRENER LAB';
    }
  }

  Color get badgeColor {
    switch (this) {
      case BeAProSmsSenderRole.sportsDirector:
        return AppColors.primaryAccent;
      case BeAProSmsSenderRole.agent:
        return AppColors.goldAccent;
      case BeAProSmsSenderRole.performanceCoach:
        return AppColors.accentBlue;
    }
  }
}

/// Szybka odpowiedź SMS kolarza wpływająca na relacje i zaufanie.
class BeAProSmsQuickReply {
  final String id;
  final String text;
  final double dsTrustDelta;
  final double fameDelta;
  final String autoResponseText;

  const BeAProSmsQuickReply({
    required this.id,
    required this.text,
    required this.dsTrustDelta,
    required this.fameDelta,
    required this.autoResponseText,
  });
}

/// Pojedyncza wiadomość SMS.
class BeAProSmsMessage {
  final String id;
  final String text;
  final String timestampLabel;
  final bool isFromPlayer;
  final bool isRead;

  const BeAProSmsMessage({
    required this.id,
    required this.text,
    required this.timestampLabel,
    required this.isFromPlayer,
    this.isRead = true,
  });

  BeAProSmsMessage copyWith({bool? isRead}) {
    return BeAProSmsMessage(
      id: id,
      text: text,
      timestampLabel: timestampLabel,
      isFromPlayer: isFromPlayer,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Wątek SMS z dyrektorem sportowym, agentem lub trenerem.
class BeAProSmsThread {
  final String id;
  final String contactName;
  final String contactSubtitle;
  final BeAProSmsSenderRole role;
  final String initials;
  final List<BeAProSmsMessage> messages;
  final List<BeAProSmsQuickReply> quickReplies;

  const BeAProSmsThread({
    required this.id,
    required this.contactName,
    required this.contactSubtitle,
    required this.role,
    required this.initials,
    required this.messages,
    required this.quickReplies,
  });

  int get unreadCount =>
      messages.where((m) => !m.isFromPlayer && !m.isRead).length;

  BeAProSmsThread copyWith({
    List<BeAProSmsMessage>? messages,
    List<BeAProSmsQuickReply>? quickReplies,
  }) {
    return BeAProSmsThread(
      id: id,
      contactName: contactName,
      contactSubtitle: contactSubtitle,
      role: role,
      initials: initials,
      messages: messages ?? this.messages,
      quickReplies: quickReplies ?? this.quickReplies,
    );
  }
}

/// Status oferty kontraktowej z drużyny WorldTour / ProTeam.
enum BeAProContractOfferStatus {
  pending,
  accepted,
  declined,
}

/// Oferta kontraktowa od silniejszej drużyny WorldTour lub ProTeam.
class BeAProContractOffer {
  final String id;
  final String teamId;
  final String teamName;
  final TeamDivision division;
  final Color jerseyPrimaryColor;
  final Color jerseySecondaryColor;
  final RiderRole offeredRole;
  final int monthlySalaryEur;
  final int signingBonusEur;
  final int winBonusEur;
  final int contractYears;
  final List<String> guaranteedRaces;
  final int minOvrRequired;
  final double minTrustRequired;
  final String pitchSummary;
  final BeAProContractOfferStatus status;

  const BeAProContractOffer({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.division,
    required this.jerseyPrimaryColor,
    required this.jerseySecondaryColor,
    required this.offeredRole,
    required this.monthlySalaryEur,
    required this.signingBonusEur,
    required this.winBonusEur,
    required this.contractYears,
    required this.guaranteedRaces,
    required this.minOvrRequired,
    required this.minTrustRequired,
    required this.pitchSummary,
    this.status = BeAProContractOfferStatus.pending,
  });

  int get annualSalaryEur => monthlySalaryEur * 12;

  BeAProContractOffer copyWith({BeAProContractOfferStatus? status}) {
    return BeAProContractOffer(
      id: id,
      teamId: teamId,
      teamName: teamName,
      division: division,
      jerseyPrimaryColor: jerseyPrimaryColor,
      jerseySecondaryColor: jerseySecondaryColor,
      offeredRole: offeredRole,
      monthlySalaryEur: monthlySalaryEur,
      signingBonusEur: signingBonusEur,
      winBonusEur: winBonusEur,
      contractYears: contractYears,
      guaranteedRaces: guaranteedRaces,
      minOvrRequired: minOvrRequired,
      minTrustRequired: minTrustRequired,
      pitchSummary: pitchSummary,
      status: status ?? this.status,
    );
  }
}

/// Wzór koszulki w gablocie.
enum CabinetJerseyPattern {
  solid,
  polkaDot,
  rainbow,
  nationalBand,
}

/// Rodzaj pucharu w gablocie.
enum CabinetTrophyKind {
  cobblestone,
  grandTourCup,
  monumentPlaque,
  worldsMedal,
}

/// Filtr gabloty trofeów.
enum TrophyCabinetFilter {
  all,
  jerseys,
  trophies;

  String get label {
    switch (this) {
      case TrophyCabinetFilter.all:
        return 'Wszystkie';
      case TrophyCabinetFilter.jerseys:
        return 'Koszulki';
      case TrophyCabinetFilter.trophies:
        return 'Puchary';
    }
  }
}

/// Eksponat w gablocie prywatnych koszulek i pucharów kolarza.
class BeAProTrophyCabinetItem {
  final String id;
  final String title;
  final String subtitle;
  final String raceName;
  final int seasonYear;
  final bool isJersey;
  final Color primaryColor;
  final Color secondaryColor;
  final CabinetJerseyPattern jerseyPattern;
  final CabinetTrophyKind trophyKind;
  final int prestigePoints;
  final bool isUnlocked;

  const BeAProTrophyCabinetItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.raceName,
    required this.seasonYear,
    required this.isJersey,
    required this.primaryColor,
    required this.secondaryColor,
    this.jerseyPattern = CabinetJerseyPattern.solid,
    this.trophyKind = CabinetTrophyKind.grandTourCup,
    required this.prestigePoints,
    required this.isUnlocked,
  });
}

/// Opcja apartamentu / bazy treningowej dostępna w widoku nieruchomości.
class BeAProResidencePreset {
  final String id;
  final String name;
  final String location;
  final int altitudeMeters;
  final int purchasePriceEur;
  final int monthlyUpkeepEur;
  final double recoveryBonusPercent;
  final double altitudeBonusPercent;
  final double taxShieldPercent;
  final String atmosphereLabel;
  final Color skyTopColor;
  final Color skyBottomColor;

  const BeAProResidencePreset({
    required this.id,
    required this.name,
    required this.location,
    required this.altitudeMeters,
    required this.purchasePriceEur,
    required this.monthlyUpkeepEur,
    required this.recoveryBonusPercent,
    required this.altitudeBonusPercent,
    required this.taxShieldPercent,
    required this.atmosphereLabel,
    required this.skyTopColor,
    required this.skyBottomColor,
  });
}

/// Główny ekran trybu Be a Pro ("Zostań Legendą"):
/// - widok apartamentu i bazy treningowej kolarza,
/// - drzewo rozwoju umiejętności fizjologicznych i technicznych za punkty XP,
/// - wiadomości SMS od dyrektora sportowego i agenta,
/// - oferty kontraktowe od silniejszych drużyn WorldTour,
/// - gablota prywatnych koszulek i pucharów.
class BeAProDashboardAndApartmentScreen extends StatefulWidget {
  final ProCyclistCareerState? initialState;
  final ValueChanged<ProCyclistCareerState>? onStateChanged;
  final VoidCallback? onOpenRaceCalendar;
  final VoidCallback? onBack;

  const BeAProDashboardAndApartmentScreen({
    super.key,
    this.initialState,
    this.onStateChanged,
    this.onOpenRaceCalendar,
    this.onBack,
  });

  @override
  State<BeAProDashboardAndApartmentScreen> createState() =>
      _BeAProDashboardAndApartmentScreenState();
}

class _BeAProDashboardAndApartmentScreenState
    extends State<BeAProDashboardAndApartmentScreen>
    with SingleTickerProviderStateMixin {
  late ProCyclistCareerState _careerState;
  BeAProDashboardSection _activeSection = BeAProDashboardSection.apartment;
  late List<BeAProSkillNode> _skillNodes;
  late List<BeAProSmsThread> _smsThreads;
  late String _selectedThreadId;
  late List<BeAProContractOffer> _contractOffers;
  late List<BeAProTrophyCabinetItem> _cabinetItems;
  TrophyCabinetFilter _cabinetFilter = TrophyCabinetFilter.all;
  String? _selectedCabinetItemId;
  String? _selectedHotspotId;
  late AnimationController _ambientController;

  static const List<BeAProResidencePreset> _residenceCatalog = [
    BeAProResidencePreset(
      id: 'res_girona',
      name: 'Loft Barri Vell',
      location: 'Girona, Hiszpania',
      altitudeMeters: 120,
      purchasePriceEur: 0,
      monthlyUpkeepEur: 1150,
      recoveryBonusPercent: 6.0,
      altitudeBonusPercent: 0.0,
      taxShieldPercent: 0.0,
      atmosphereLabel: 'Katalońskie wzgórza • Baza peletonu',
      skyTopColor: Color(0xFF1D2C44),
      skyBottomColor: Color(0xFF43313B),
    ),
    BeAProResidencePreset(
      id: 'res_andorra',
      name: 'Chalet Ordino',
      location: 'Andora, Pireneje',
      altitudeMeters: 1580,
      purchasePriceEur: 185000,
      monthlyUpkeepEur: 1650,
      recoveryBonusPercent: 10.0,
      altitudeBonusPercent: 4.5,
      taxShieldPercent: 18.0,
      atmosphereLabel: 'Wysokogórski mikro-obóz • Pireneje',
      skyTopColor: Color(0xFF132238),
      skyBottomColor: Color(0xFF28425E),
    ),
    BeAProResidencePreset(
      id: 'res_monaco',
      name: 'Penthouse Fontvieille',
      location: 'Monako, Lazurowe Wybrzeże',
      altitudeMeters: 45,
      purchasePriceEur: 490000,
      monthlyUpkeepEur: 2800,
      recoveryBonusPercent: 14.0,
      altitudeBonusPercent: 0.0,
      taxShieldPercent: 32.0,
      atmosphereLabel: 'Śródziemnomorska regeneracja • Ulga podatkowa',
      skyTopColor: Color(0xFF162742),
      skyBottomColor: Color(0xFF2B4C65),
    ),
    BeAProResidencePreset(
      id: 'res_livigno',
      name: 'Baza Treningowa Alta Valtellina',
      location: 'Livigno, Włochy',
      altitudeMeters: 1816,
      purchasePriceEur: 240000,
      monthlyUpkeepEur: 1750,
      recoveryBonusPercent: 11.0,
      altitudeBonusPercent: 6.5,
      taxShieldPercent: 12.0,
      atmosphereLabel: 'Maksymalna adaptacja tlenowa >1800 m',
      skyTopColor: Color(0xFF0E1D33),
      skyBottomColor: Color(0xFF203A58),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _careerState = widget.initialState ?? _buildDefaultCareerState();
    _skillNodes = _buildInitialSkillNodes();
    _smsThreads = _buildInitialSmsThreads(_careerState);
    _selectedThreadId = _smsThreads.first.id;
    _contractOffers = _buildInitialContractOffers();
    _cabinetItems = _buildCabinetItems(_careerState.palmares);
    _selectedCabinetItemId = _cabinetItems.first.id;
    _selectedHotspotId = 'trainer';
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  void _updateCareerState(ProCyclistCareerState next) {
    setState(() {
      _careerState = next;
      _cabinetItems = _buildCabinetItems(next.palmares);
    });
    widget.onStateChanged?.call(next);
  }

  ProCyclistCareerState _buildDefaultCareerState() {
    final rider = Rider(
      id: 'pro_player_1',
      firstName: 'Kacper',
      lastName: 'Kowalski',
      nationalityIso: 'POL',
      birthDate: DateTime(2005, 5, 14),
      potential: 93,
      specialization: RiderSpecialization.gcClimber,
      physiology: const RiderPhysiology(
        heightCm: 177.0,
        weightKg: 64.5,
        bodyFatPercentage: 6.8,
        ftpWatts: 382,
        wPrimeJoules: 23500,
        vo2Max: 81.2,
        maxHr: 194,
        restingHr: 39,
        lactateThresholdHr: 176,
        recoveryRate: 82.0,
        glycogenCapacityGrams: 540.0,
        form: 84.0,
        fatigue: 22.0,
      ),
      powerProfile: const RiderPowerProfile(
        watts5s: 1180,
        watts15s: 960,
        watts30s: 740,
        watts1m: 585,
        watts3m: 475,
        watts5m: 445,
        watts20m: 405,
        watts60m: 382,
      ),
      skills: const RiderSkills(
        cobbles: 66,
        descending: 76,
        bikeHandling: 78,
        aeroPositioning: 74,
        draftingEfficiency: 79,
        raceIq: 77,
        rainResistance: 72,
        heatTolerance: 75,
        timeTrialPositioning: 73,
      ),
      appearance: const RiderAppearance(
        faceShapeIndex: 1,
        skinToneHex: '#F1C6A8',
        hairStyleIndex: 2,
        hairColorHex: '#3B281E',
        facialHairIndex: 0,
        glassesModelId: 'aero_pro_v2',
        glassesLensColorHex: '#D4AF37',
        helmetModelId: 'vent_pro_x',
        shoeColorHex: '#F3F4F6',
        sockHeightProportion: 0.72,
        bodyBuildType: BodyBuildType.climberLean,
      ),
      contract: const RiderContract(
        teamId: 'pro_team_polonia',
        role: RiderRole.coLeader,
        monthlySalaryEur: 7500,
        signingBonusEur: 12000,
        winBonusEur: 3500,
        releaseClauseEur: 120000,
        contractEndYear: 2027,
        morale: 0.88,
        leaderLoyalty: 0.84,
        requiredRacesIds: ['tour_de_pologne', 'tirreno_adriatico'],
      ),
      health: const RiderHealth(
        acuteTrainingLoad: 58.0,
        chronicTrainingLoad: 76.0,
      ),
      careerPointsUci: 645,
    );

    final baseDate = DateTime(2026, 4, 18);
    return ProCyclistCareerState(
      careerId: 'be_a_pro_default',
      careerName: 'Droga do Żółtej Koszulki',
      playerRider: rider,
      currentDate: baseDate,
      careerStartDate: DateTime(2025, 1, 1),
      seasonYear: 2026,
      currentTeamId: 'pro_team_polonia',
      currentTeamName: 'Polonia Pro Cycling',
      currentDivision: TeamDivision.proTeam,
      careerTier: ProCyclistCareerTier.proTeam,
      dsTrustScore: 76.0,
      skillPoints: 6,
      experienceXp: 780,
      careerLevel: 3,
      totalSkillPointsEarned: 11,
      totalSkillPointsSpent: 5,
      privateBalanceEur: 68400,
      careerEarningsEur: 142000,
      monthlyLivingExpensesEur: 1150,
      fameScore: 44.0,
      fanFollowersCount: 18400,
      ownedProperties: [
        ProCyclistRealEstate(
          id: 'res_girona',
          name: 'Loft Barri Vell',
          location: 'Girona, Hiszpania',
          altitudeMeters: 120,
          category: ProCyclistPropertyCategory.apartment,
          purchasePriceEur: 0,
          monthlyUpkeepEur: 1150,
          recoveryBonusPercent: 6.0,
          purchasedDate: DateTime(2025, 2, 1),
          isPrimaryResidence: true,
        ),
      ],
      ownedPrivateEquipment: [
        ProCyclistPrivateEquipment(
          id: 'eq_wattbike',
          name: 'Trenażer Smart Direct-Drive Pro',
          brand: 'WattLab Pro',
          category: ProCyclistEquipmentCategory.indoorTrainer,
          purchasePriceEur: 3400,
          trainingXpBonusPercent: 12.0,
          recoveryBonusPercent: 0.0,
          wattSavings: 0.0,
          purchasedDate: DateTime(2025, 3, 10),
          isEquipped: true,
        ),
        ProCyclistPrivateEquipment(
          id: 'eq_hypoxic_tent',
          name: 'Namiot Hipoksyjny 2800m',
          brand: 'AltiSleep',
          category: ProCyclistEquipmentCategory.recoveryTech,
          purchasePriceEur: 6200,
          trainingXpBonusPercent: 6.0,
          recoveryBonusPercent: 5.5,
          wattSavings: 0.0,
          purchasedDate: DateTime(2025, 11, 20),
          isEquipped: true,
        ),
        ProCyclistPrivateEquipment(
          id: 'eq_aero_wheels',
          name: 'Koła Karbonowe 52mm Ceramic',
          brand: 'VeloAero',
          category: ProCyclistEquipmentCategory.aeroWheelset,
          purchasePriceEur: 2900,
          trainingXpBonusPercent: 0.0,
          recoveryBonusPercent: 0.0,
          wattSavings: 6.5,
          purchasedDate: DateTime(2026, 1, 14),
          isEquipped: true,
        ),
      ],
      palmares: const ProCyclistPalmares(
        raceDays: 68,
        careerWins: 5,
        careerPodiums: 14,
        stageWins: 3,
        u23Wins: 4,
        monumentStarts: 2,
        grandTourStarts: 1,
        leaderJerseyDays: 4,
        komJerseyWins: 1,
        youthJerseyWins: 2,
      ),
    );
  }

  List<BeAProSkillNode> _buildInitialSkillNodes() {
    return const [
      // Gałąź Fizjologiczna
      BeAProSkillNode(
        id: BeAProSkillNodeId.ftpThreshold,
        branch: BeAProSkillBranch.physiological,
        tier: 1,
        title: 'Próg Mleczanowy FTP',
        subtitle: 'Zwiększa moc progową na długich podjazdach i czasówkach.',
        deltaLabel: '+4 W FTP',
        costSkillPoints: 1,
        maxLevel: 5,
        currentLevel: 2,
        icon: Icons.bolt_rounded,
        accentColor: AppColors.goldAccent,
      ),
      BeAProSkillNode(
        id: BeAProSkillNodeId.wPrimeAnaerobic,
        branch: BeAProSkillBranch.physiological,
        tier: 2,
        prerequisiteId: BeAProSkillNodeId.ftpThreshold,
        title: 'Bateria Beztlenowa W\'',
        subtitle: 'Większy zapas energii na gwałtowne ataki i kontry >120% FTP.',
        deltaLabel: '+600 J W\'',
        costSkillPoints: 2,
        maxLevel: 4,
        currentLevel: 1,
        icon: Icons.battery_charging_full_rounded,
        accentColor: AppColors.crimsonAlert,
      ),
      BeAProSkillNode(
        id: BeAProSkillNodeId.vo2MaxEngine,
        branch: BeAProSkillBranch.physiological,
        tier: 2,
        prerequisiteId: BeAProSkillNodeId.ftpThreshold,
        title: 'Silnik Tlenowy VO2max',
        subtitle: 'Podnosi pułap tlenowy w wysokich górach powyżej 2000 m.',
        deltaLabel: '+0.8 VO2max',
        costSkillPoints: 2,
        maxLevel: 4,
        currentLevel: 1,
        icon: Icons.air_rounded,
        accentColor: AppColors.accentBlue,
      ),
      BeAProSkillNode(
        id: BeAProSkillNodeId.recoveryBiology,
        branch: BeAProSkillBranch.physiological,
        tier: 3,
        prerequisiteId: BeAProSkillNodeId.vo2MaxEngine,
        title: 'Regeneracja 3. Tygodnia',
        subtitle: 'Ogranicza spadek mocy w ostatnim tygodniu Wielkiego Touru.',
        deltaLabel: '+1.5 Regeneracja',
        costSkillPoints: 2,
        maxLevel: 4,
        currentLevel: 0,
        icon: Icons.nightlight_round,
        accentColor: AppColors.statusSuccess,
      ),
      BeAProSkillNode(
        id: BeAProSkillNodeId.glycogenTank,
        branch: BeAProSkillBranch.physiological,
        tier: 3,
        prerequisiteId: BeAProSkillNodeId.wPrimeAnaerobic,
        title: 'Pojemność Glikogenu',
        subtitle: 'Zwiększa rezerwy węglowodanowe chroniące przed odcięciem.',
        deltaLabel: '+25 g Glikogenu',
        costSkillPoints: 1,
        maxLevel: 4,
        currentLevel: 1,
        icon: Icons.local_fire_department_rounded,
        accentColor: AppColors.amberWarning,
      ),

      // Gałąź Techniczna
      BeAProSkillNode(
        id: BeAProSkillNodeId.pelotonDrafting,
        branch: BeAProSkillBranch.technical,
        tier: 1,
        title: 'Drafting w Peletonie',
        subtitle: 'Lepsze czytanie rantu i oszczędność watów w środku grupy.',
        deltaLabel: '+2 Drafting',
        costSkillPoints: 1,
        maxLevel: 5,
        currentLevel: 2,
        icon: Icons.groups_rounded,
        accentColor: AppColors.cyanAccent,
      ),
      BeAProSkillNode(
        id: BeAProSkillNodeId.aeroPosition,
        branch: BeAProSkillBranch.technical,
        tier: 2,
        prerequisiteId: BeAProSkillNodeId.pelotonDrafting,
        title: 'Pozycja Aero & CdA',
        subtitle: 'Niższy opór czołowy w ucieczkach i na płaskich odcinkach.',
        deltaLabel: '+2 Aero',
        costSkillPoints: 1,
        maxLevel: 5,
        currentLevel: 1,
        icon: Icons.speed_rounded,
        accentColor: AppColors.accentBlue,
      ),
      BeAProSkillNode(
        id: BeAProSkillNodeId.descendingLines,
        branch: BeAProSkillBranch.technical,
        tier: 2,
        prerequisiteId: BeAProSkillNodeId.pelotonDrafting,
        title: 'Linia Zjazdów & Supertuck',
        subtitle: 'Większa pewność w technicznych serpentynach i na mokrym.',
        deltaLabel: '+2 Zjazdy',
        costSkillPoints: 2,
        maxLevel: 4,
        currentLevel: 1,
        icon: Icons.trending_down_rounded,
        accentColor: AppColors.amberWarning,
      ),
      BeAProSkillNode(
        id: BeAProSkillNodeId.cobblesMastery,
        branch: BeAProSkillBranch.technical,
        tier: 3,
        prerequisiteId: BeAProSkillNodeId.descendingLines,
        title: 'Technika Bruków 5★',
        subtitle: 'Tłumienie drgań i utrzymanie kadencji na sektorach Paryż-Roubaix.',
        deltaLabel: '+2 Bruk',
        costSkillPoints: 2,
        maxLevel: 4,
        currentLevel: 0,
        icon: Icons.grid_view_rounded,
        accentColor: AppColors.primaryAccent,
      ),
      BeAProSkillNode(
        id: BeAProSkillNodeId.raceIqTactics,
        branch: BeAProSkillBranch.technical,
        tier: 3,
        prerequisiteId: BeAProSkillNodeId.aeroPosition,
        title: 'Taktyka & Race IQ',
        subtitle: 'Precyzyjny wybór momentu ataku i pozycjonowania na 3 km.',
        deltaLabel: '+2 Race IQ',
        costSkillPoints: 2,
        maxLevel: 4,
        currentLevel: 1,
        icon: Icons.psychology_rounded,
        accentColor: AppColors.goldAccent,
      ),
      BeAProSkillNode(
        id: BeAProSkillNodeId.ttSpecialist,
        branch: BeAProSkillBranch.technical,
        tier: 3,
        prerequisiteId: BeAProSkillNodeId.aeroPosition,
        title: 'Pozycja Czasowa ITT',
        subtitle: 'Stabilizacja mocy na lemondce w jeździe indywidualnej na czas.',
        deltaLabel: '+2 Czasówka',
        costSkillPoints: 2,
        maxLevel: 4,
        currentLevel: 0,
        icon: Icons.timer_rounded,
        accentColor: AppColors.statusSuccess,
      ),
    ];
  }

  List<BeAProSmsThread> _buildInitialSmsThreads(ProCyclistCareerState state) {
    return [
      BeAProSmsThread(
        id: 'thread_ds',
        contactName: 'Marco Bellini',
        contactSubtitle: 'Dyrektor Sportowy • ${state.currentTeamName}',
        role: BeAProSmsSenderRole.sportsDirector,
        initials: 'MB',
        messages: const [
          BeAProSmsMessage(
            id: 'ds_1',
            text:
                'Świetna robota na ostatnim podjeździe. Twoje 6.1 W/kg przez 18 minut ustawiło całą grupę.',
            timestampLabel: 'Wczoraj • 19:40',
            isFromPlayer: false,
            isRead: true,
          ),
          BeAProSmsMessage(
            id: 'ds_2',
            text:
                'Na niedzielnym wyścigu w Ardenach dostajesz status chronionego Co-Lidera. Zdecyduj, czy chcesz dwóch pomocników na dojeździe do finałowej ścianki.',
            timestampLabel: 'Dziś • 08:15',
            isFromPlayer: false,
            isRead: false,
          ),
        ],
        quickReplies: const [
          BeAProSmsQuickReply(
            id: 'ds_r1',
            text: 'Biorę pełną odpowiedzialność. Zbieram pomocników na finał!',
            dsTrustDelta: 3.5,
            fameDelta: 1.0,
            autoResponseText:
                'Takiej pewności siebie oczekuję. Odprawa w autobusie o 10:00 — jedziemy po podium.',
          ),
          BeAProSmsQuickReply(
            id: 'ds_r2',
            text: 'Wolę jechać z cienia i zaatakować z ucieczki dnia.',
            dsTrustDelta: 1.5,
            fameDelta: 2.0,
            autoResponseText:
                'Odważny plan. Masz zielone światło na skok po pierwszym lotnym finiszu.',
          ),
        ],
      ),
      const BeAProSmsThread(
        id: 'thread_agent',
        contactName: 'Lucas Moreau',
        contactSubtitle: 'Licencjonowany Agent UCI',
        role: BeAProSmsSenderRole.agent,
        initials: 'LM',
        messages: [
          BeAProSmsMessage(
            id: 'ag_1',
            text:
                'Skauci z dwóch ekip WorldTour dzwonili dziś rano po Twoich wynikach w klasyfikacji młodzieżowej.',
            timestampLabel: 'Dziś • 09:05',
            isFromPlayer: false,
            isRead: false,
          ),
          BeAProSmsMessage(
            id: 'ag_2',
            text:
                'Wrzuciłem Ci trzy wstępne oferty do zakładki Oferty WT. Jeśli dobijesz zaufanie DS i OVR, możemy negocjować gwarantowany start w Tour de France.',
            timestampLabel: 'Dziś • 09:07',
            isFromPlayer: false,
            isRead: false,
          ),
        ],
        quickReplies: [
          BeAProSmsQuickReply(
            id: 'ag_r1',
            text: 'Negocjuj klauzulę lidera na Grand Tour i wyższy bonus za wygraną.',
            dsTrustDelta: -0.5,
            fameDelta: 1.5,
            autoResponseText:
                'Jasne, podbijam stawkę. Składam kontrofertę dyrektorom generalnym w WorldTourze.',
          ),
          BeAProSmsQuickReply(
            id: 'ag_r2',
            text: 'Na razie skupiam się na obecnym sezonie i punktach UCI.',
            dsTrustDelta: 2.0,
            fameDelta: 0.5,
            autoResponseText:
                'Rozsądnie. Dobre nogi na wiosnę podbiją Twoją wartość rynkową o kolejne 30%.',
          ),
        ],
      ),
      const BeAProSmsThread(
        id: 'thread_coach',
        contactName: 'Dr Elena Vance',
        contactSubtitle: 'Fizjolog & Lab Wydolnościowe',
        role: BeAProSmsSenderRole.performanceCoach,
        initials: 'EV',
        messages: [
          BeAProSmsMessage(
            id: 'co_1',
            text:
                'Twój profil TSB jest na optymalnym poziomie +18. Namiot hipoksyjny w apartamencie podniósł hematokryt bez zmęczenia układu nerwowego.',
            timestampLabel: 'Dziś • 07:30',
            isFromPlayer: false,
            isRead: true,
          ),
        ],
        quickReplies: [
          BeAProSmsQuickReply(
            id: 'co_r1',
            text: 'Zwiększamy bodziec na progu LT2 w tym tygodniu.',
            dsTrustDelta: 1.0,
            fameDelta: 0.0,
            autoResponseText:
                'Wgrałam blok 3x12 min @ 102% FTP na Twój Smart Trainer. Powodzenia!',
          ),
        ],
      ),
    ];
  }

  List<BeAProContractOffer> _buildInitialContractOffers() {
    return const [
      BeAProContractOffer(
        id: 'offer_visma',
        teamId: 'wt_visma_veloce',
        teamName: 'Team Visma-Veloce',
        division: TeamDivision.worldTour,
        jerseyPrimaryColor: Color(0xFFD4AF37),
        jerseySecondaryColor: Color(0xFF181B22),
        offeredRole: RiderRole.superDomestique,
        monthlySalaryEur: 18500,
        signingBonusEur: 45000,
        winBonusEur: 8500,
        contractYears: 2,
        guaranteedRaces: ['Tour de France', 'Paris-Nice', 'Criterium du Dauphine'],
        minOvrRequired: 74,
        minTrustRequired: 65.0,
        pitchSummary:
            'Najlepszy sztab naukowy WorldTouru, pełne wsparcie tunelu aero i rola kluczowego górskiego pomocnika na Wielkich Tourach.',
      ),
      BeAProContractOffer(
        id: 'offer_ineos',
        teamId: 'wt_ineos_alps',
        teamName: 'INEOS Alpine Grenadiers',
        division: TeamDivision.worldTour,
        jerseyPrimaryColor: Color(0xFF8E4A49),
        jerseySecondaryColor: Color(0xFF0F1115),
        offeredRole: RiderRole.coLeader,
        monthlySalaryEur: 24000,
        signingBonusEur: 65000,
        winBonusEur: 11000,
        contractYears: 3,
        guaranteedRaces: ['Giro d\'Italia', 'Tour de Suisse', 'Liege-Bastogne-Liege'],
        minOvrRequired: 78,
        minTrustRequired: 75.0,
        pitchSummary:
            'Status chronionego Co-Lidera na Giro d\'Italia oraz indywidualny program obozów wysokogórskich w Sierra Nevada.',
      ),
      BeAProContractOffer(
        id: 'offer_alpecin',
        teamId: 'wt_alpecin_flanders',
        teamName: 'Alpecin-Flanders Deceuninck',
        division: TeamDivision.worldTour,
        jerseyPrimaryColor: Color(0xFF38BDF8),
        jerseySecondaryColor: Color(0xFF1E293B),
        offeredRole: RiderRole.breakawaySpecialist,
        monthlySalaryEur: 14500,
        signingBonusEur: 28000,
        winBonusEur: 7000,
        contractYears: 2,
        guaranteedRaces: ['Ronde van Vlaanderen', 'Strade Bianche', 'Vuelta a Espana'],
        minOvrRequired: 70,
        minTrustRequired: 55.0,
        pitchSummary:
            'Wolna ręka na klasykach i etapach pagórkowatych, nacisk na agresywną jazdę i zbieranie premii górskich.',
      ),
    ];
  }

  List<BeAProTrophyCabinetItem> _buildCabinetItems(ProCyclistPalmares palmares) {
    return [
      BeAProTrophyCabinetItem(
        id: 'cab_youth_jersey',
        title: 'Biała Koszulka Młodzieżowa',
        subtitle: 'Najlepszy Kolarz U25',
        raceName: 'Tirreno-Adriatico',
        seasonYear: 2026,
        isJersey: true,
        primaryColor: const Color(0xFFF3F4F6),
        secondaryColor: AppColors.accentBlue,
        jerseyPattern: CabinetJerseyPattern.solid,
        prestigePoints: 180,
        isUnlocked: palmares.youthJerseyWins > 0,
      ),
      BeAProTrophyCabinetItem(
        id: 'cab_kom_jersey',
        title: 'Koszulka w Grochy KOM',
        subtitle: 'Król Gór Klasyfikacji',
        raceName: 'Tour de Pologne',
        seasonYear: 2025,
        isJersey: true,
        primaryColor: const Color(0xFFF3F4F6),
        secondaryColor: AppColors.crimsonAlert,
        jerseyPattern: CabinetJerseyPattern.polkaDot,
        prestigePoints: 210,
        isUnlocked: palmares.komJerseyWins > 0,
      ),
      BeAProTrophyCabinetItem(
        id: 'cab_yellow_jersey',
        title: 'Maillot Jaune (Żółta GC)',
        subtitle: 'Lider Klasyfikacji Generalnej',
        raceName: 'Tour de France',
        seasonYear: 2026,
        isJersey: true,
        primaryColor: AppColors.goldAccent,
        secondaryColor: const Color(0xFF181B22),
        jerseyPattern: CabinetJerseyPattern.solid,
        prestigePoints: 650,
        isUnlocked: palmares.leaderJerseyDays >= 10,
      ),
      BeAProTrophyCabinetItem(
        id: 'cab_rainbow_jersey',
        title: 'Tęczowa Koszulka MŚ UCI',
        subtitle: 'Mistrz Świata Elity',
        raceName: 'UCI World Championships',
        seasonYear: 2026,
        isJersey: true,
        primaryColor: const Color(0xFFF3F4F6),
        secondaryColor: AppColors.goldAccent,
        jerseyPattern: CabinetJerseyPattern.rainbow,
        prestigePoints: 900,
        isUnlocked: palmares.worldChampMedals > 0,
      ),
      BeAProTrophyCabinetItem(
        id: 'cab_u23_cup',
        title: 'Puchar Etapowy U23',
        subtitle: 'Zwycięstwo Klasyfikacji Generalnej',
        raceName: 'Tour de l\'Avenir',
        seasonYear: 2025,
        isJersey: false,
        primaryColor: AppColors.goldAccent,
        secondaryColor: AppColors.primaryAccent,
        trophyKind: CabinetTrophyKind.grandTourCup,
        prestigePoints: 240,
        isUnlocked: palmares.u23Wins > 0,
      ),
      BeAProTrophyCabinetItem(
        id: 'cab_roubaix_cobble',
        title: 'Kostka Bruku Roubaix',
        subtitle: 'Podium / Zwycięstwo Monumentu',
        raceName: 'Paris-Roubaix',
        seasonYear: 2026,
        isJersey: false,
        primaryColor: const Color(0xFF9CA3AF),
        secondaryColor: AppColors.goldAccent,
        trophyKind: CabinetTrophyKind.cobblestone,
        prestigePoints: 500,
        isUnlocked: palmares.monumentWins > 0,
      ),
      BeAProTrophyCabinetItem(
        id: 'cab_stage_plaque',
        title: 'Plakieta Zwycięzcy Etapu',
        subtitle: 'Wygrany Etap Górski',
        raceName: 'Vuelta a Andalucia',
        seasonYear: 2026,
        isJersey: false,
        primaryColor: AppColors.accentBlue,
        secondaryColor: AppColors.goldAccent,
        trophyKind: CabinetTrophyKind.monumentPlaque,
        prestigePoints: 160,
        isUnlocked: palmares.stageWins > 0,
      ),
    ];
  }

  bool _isPrerequisiteMet(BeAProSkillNode node) {
    if (node.prerequisiteId == null) return true;
    final prereq = _skillNodes.firstWhere((n) => n.id == node.prerequisiteId);
    return prereq.currentLevel > 0;
  }

  String _currentMetricForNode(BeAProSkillNodeId id) {
    final p = _careerState.playerRider.physiology;
    final s = _careerState.playerRider.skills;
    switch (id) {
      case BeAProSkillNodeId.ftpThreshold:
        return '${p.ftpWatts} W (${p.wattsPerKg.toStringAsFixed(2)} W/kg)';
      case BeAProSkillNodeId.wPrimeAnaerobic:
        return '${(p.wPrimeJoules / 1000.0).toStringAsFixed(1)} kJ';
      case BeAProSkillNodeId.vo2MaxEngine:
        return '${p.vo2Max.toStringAsFixed(1)} ml/kg';
      case BeAProSkillNodeId.recoveryBiology:
        return '${p.recoveryRate.toStringAsFixed(1)} pkt';
      case BeAProSkillNodeId.glycogenTank:
        return '${p.glycogenCapacityGrams.round()} g';
      case BeAProSkillNodeId.aeroPosition:
        return '${s.aeroPositioning} / 99';
      case BeAProSkillNodeId.cobblesMastery:
        return '${s.cobbles} / 99';
      case BeAProSkillNodeId.descendingLines:
        return '${s.descending} / 99';
      case BeAProSkillNodeId.pelotonDrafting:
        return '${s.draftingEfficiency} / 99';
      case BeAProSkillNodeId.raceIqTactics:
        return '${s.raceIq} / 99';
      case BeAProSkillNodeId.ttSpecialist:
        return '${s.timeTrialPositioning} / 99';
    }
  }

  void _upgradeSkillNode(BeAProSkillNode node) {
    if (node.isMaxed ||
        !_isPrerequisiteMet(node) ||
        _careerState.skillPoints < node.costSkillPoints) {
      return;
    }

    final rider = _careerState.playerRider;
    var phys = rider.physiology;
    var skills = rider.skills;
    var power = rider.powerProfile;

    switch (node.id) {
      case BeAProSkillNodeId.ftpThreshold:
        final nextFtp = phys.ftpWatts + 4;
        phys = phys.copyWith(ftpWatts: nextFtp);
        power = RiderPowerProfile(
          watts5s: power.watts5s,
          watts15s: power.watts15s,
          watts30s: power.watts30s,
          watts1m: power.watts1m + 3,
          watts3m: power.watts3m + 4,
          watts5m: power.watts5m + 4,
          watts20m: power.watts20m + 4,
          watts60m: nextFtp,
        );
        break;
      case BeAProSkillNodeId.wPrimeAnaerobic:
        phys = phys.copyWith(wPrimeJoules: phys.wPrimeJoules + 600);
        break;
      case BeAProSkillNodeId.vo2MaxEngine:
        phys = phys.copyWith(
          vo2Max: double.parse((phys.vo2Max + 0.8).toStringAsFixed(1)),
        );
        break;
      case BeAProSkillNodeId.recoveryBiology:
        phys = phys.copyWith(
          recoveryRate: (phys.recoveryRate + 1.5).clamp(0.0, 99.0),
        );
        break;
      case BeAProSkillNodeId.glycogenTank:
        phys = phys.copyWith(
          glycogenCapacityGrams: phys.glycogenCapacityGrams + 25.0,
        );
        break;
      case BeAProSkillNodeId.aeroPosition:
        skills = skills.copyWith(
          aeroPositioning: (skills.aeroPositioning + 2).clamp(1, 99),
        );
        break;
      case BeAProSkillNodeId.cobblesMastery:
        skills = skills.copyWith(
          cobbles: (skills.cobbles + 2).clamp(1, 99),
        );
        break;
      case BeAProSkillNodeId.descendingLines:
        skills = skills.copyWith(
          descending: (skills.descending + 2).clamp(1, 99),
        );
        break;
      case BeAProSkillNodeId.pelotonDrafting:
        skills = skills.copyWith(
          draftingEfficiency: (skills.draftingEfficiency + 2).clamp(1, 99),
        );
        break;
      case BeAProSkillNodeId.raceIqTactics:
        skills = skills.copyWith(
          raceIq: (skills.raceIq + 2).clamp(1, 99),
        );
        break;
      case BeAProSkillNodeId.ttSpecialist:
        skills = skills.copyWith(
          timeTrialPositioning: (skills.timeTrialPositioning + 2).clamp(1, 99),
        );
        break;
    }

    final updatedRider = rider.copyWith(
      physiology: phys,
      skills: skills,
      powerProfile: power,
    );
    final nextState = _careerState
        .spendSkillPoints(node.costSkillPoints)
        .copyWith(playerRider: updatedRider);

    setState(() {
      _skillNodes = _skillNodes
          .map(
            (n) => n.id == node.id
                ? n.copyWith(currentLevel: n.currentLevel + 1)
                : n,
          )
          .toList();
    });
    _updateCareerState(nextState);
    _showStatusSnackBar('Ulepszono: ${node.title} (${node.deltaLabel})');
  }

  void _completeIndoorTrainingSession() {
    final xpBonusMult = 1.0 + (_careerState.totalTrainingXpBonusPercent / 100.0);
    final gainedXp = (260 * xpBonusMult).round();
    final nextState = _careerState.grantExperienceXp(gainedXp);
    _updateCareerState(nextState);
    _showStatusSnackBar(
      'Sesja treningowa ukończona: +$gainedXp XP (Premia bazy +${_careerState.totalTrainingXpBonusPercent.round()}%)',
    );
  }

  void _toggleEquipmentEquipped(String equipmentId) {
    final updated = _careerState.ownedPrivateEquipment.map((eq) {
      if (eq.id != equipmentId) return eq;
      return eq.copyWith(isEquipped: !eq.isEquipped);
    }).toList();
    _updateCareerState(_careerState.copyWith(ownedPrivateEquipment: updated));
  }

  void _selectOrPurchaseResidence(BeAProResidencePreset preset) {
    final ownedIndex =
        _careerState.ownedProperties.indexWhere((p) => p.id == preset.id);
    if (ownedIndex != -1) {
      final updated = _careerState.ownedProperties
          .map((p) => p.copyWith(isPrimaryResidence: p.id == preset.id))
          .toList();
      _updateCareerState(_careerState.copyWith(ownedProperties: updated));
      _showStatusSnackBar('Przeniesiono bazę główną do: ${preset.location}');
      return;
    }

    if (_careerState.privateBalanceEur < preset.purchasePriceEur) {
      _showStatusSnackBar('Niewystarczające środki na zakup ${preset.name}');
      return;
    }

    final newProp = ProCyclistRealEstate(
      id: preset.id,
      name: preset.name,
      location: preset.location,
      altitudeMeters: preset.altitudeMeters,
      category: preset.altitudeMeters >= 1500
          ? ProCyclistPropertyCategory.mountainChalet
          : ProCyclistPropertyCategory.taxHavenPenthouse,
      purchasePriceEur: preset.purchasePriceEur,
      monthlyUpkeepEur: preset.monthlyUpkeepEur,
      recoveryBonusPercent: preset.recoveryBonusPercent,
      altitudeAcclimatizationBonus: preset.altitudeBonusPercent,
      taxShieldPercent: preset.taxShieldPercent,
      purchasedDate: _careerState.currentDate,
      isPrimaryResidence: true,
    );

    final updatedList = [
      ..._careerState.ownedProperties
          .map((p) => p.copyWith(isPrimaryResidence: false)),
      newProp,
    ];
    _updateCareerState(
      _careerState.copyWith(
        privateBalanceEur:
            _careerState.privateBalanceEur - preset.purchasePriceEur,
        ownedProperties: updatedList,
      ),
    );
    _showStatusSnackBar('Zakupiono nieruchomość: ${preset.name}!');
  }

  void _selectSmsThread(String threadId) {
    setState(() {
      _selectedThreadId = threadId;
      _smsThreads = _smsThreads.map((t) {
        if (t.id != threadId) return t;
        return t.copyWith(
          messages: t.messages.map((m) => m.copyWith(isRead: true)).toList(),
        );
      }).toList();
    });
  }

  void _sendQuickReply(BeAProSmsThread thread, BeAProSmsQuickReply reply) {
    final playerMsg = BeAProSmsMessage(
      id: '${reply.id}_player_${thread.messages.length}',
      text: reply.text,
      timestampLabel: 'Teraz',
      isFromPlayer: true,
      isRead: true,
    );
    final contactReply = BeAProSmsMessage(
      id: '${reply.id}_resp_${thread.messages.length}',
      text: reply.autoResponseText,
      timestampLabel: 'Teraz',
      isFromPlayer: false,
      isRead: true,
    );

    setState(() {
      _smsThreads = _smsThreads.map((t) {
        if (t.id != thread.id) return t;
        return t.copyWith(
          messages: [...t.messages, playerMsg, contactReply],
          quickReplies:
              t.quickReplies.where((q) => q.id != reply.id).toList(),
        );
      }).toList();
    });

    final nextState = _careerState
        .applyDsTrustDelta(reply.dsTrustDelta)
        .copyWith(
          fameScore: (_careerState.fameScore + reply.fameDelta).clamp(0.0, 100.0),
        );
    _updateCareerState(nextState);
  }

  bool _canSignContractOffer(BeAProContractOffer offer) {
    if (offer.status != BeAProContractOfferStatus.pending) return false;
    return _careerState.playerRider.overallRating >= offer.minOvrRequired &&
        _careerState.dsTrustScore >= offer.minTrustRequired;
  }

  void _acceptContractOffer(BeAProContractOffer offer) {
    if (!_canSignContractOffer(offer)) return;

    final nextContract = _careerState.playerRider.contract.copyWith(
      teamId: offer.teamId,
      role: offer.offeredRole,
      monthlySalaryEur: offer.monthlySalaryEur,
      signingBonusEur: offer.signingBonusEur,
      winBonusEur: offer.winBonusEur,
      contractEndYear: _careerState.seasonYear + offer.contractYears,
    );

    final nextTier = offer.offeredRole == RiderRole.coLeader ||
            offer.offeredRole == RiderRole.teamLeader
        ? ProCyclistCareerTier.worldTourCoLeader
        : ProCyclistCareerTier.worldTourDomestique;

    final journalEntry = ProCyclistJournalEntry(
      entryId: 'contract_${offer.id}_${_careerState.seasonYear}',
      date: _careerState.currentDate,
      seasonYear: _careerState.seasonYear,
      category: ProCyclistJournalCategory.contract,
      title: 'Transfer do ${offer.teamName}',
      description:
          'Podpisano ${offer.contractYears}-letni kontrakt WorldTour jako ${offer.offeredRole.label}.',
      xpDelta: 400,
      eurDelta: offer.signingBonusEur,
      isKeyMilestone: true,
    );

    setState(() {
      _contractOffers = _contractOffers.map((o) {
        if (o.id == offer.id) {
          return o.copyWith(status: BeAProContractOfferStatus.accepted);
        }
        return o.status == BeAProContractOfferStatus.pending
            ? o.copyWith(status: BeAProContractOfferStatus.declined)
            : o;
      }).toList();
    });

    final nextState = _careerState
        .copyWith(
          playerRider: _careerState.playerRider.copyWith(contract: nextContract),
          currentTeamId: offer.teamId,
          currentTeamName: offer.teamName,
          currentDivision: offer.division,
          careerTier: nextTier,
          privateBalanceEur:
              _careerState.privateBalanceEur + offer.signingBonusEur,
          careerEarningsEur:
              _careerState.careerEarningsEur + offer.signingBonusEur,
        )
        .grantExperienceXp(400)
        .appendJournalEntry(journalEntry);

    _updateCareerState(nextState);
    _showStatusSnackBar(
      'Podpisano kontrakt WorldTour z ${offer.teamName}! (+${Formatters.formatCurrency(offer.signingBonusEur)})',
    );
  }

  void _declineContractOffer(BeAProContractOffer offer) {
    if (offer.status != BeAProContractOfferStatus.pending) return;
    setState(() {
      _contractOffers = _contractOffers
          .map(
            (o) => o.id == offer.id
                ? o.copyWith(status: BeAProContractOfferStatus.declined)
                : o,
          )
          .toList();
    });
  }

  void _showStatusSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.goldAccent, width: 1),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  BeAProResidencePreset get _activeResidencePreset {
    final primary = _careerState.ownedProperties.where((p) => p.isPrimaryResidence);
    final activeId = primary.isNotEmpty ? primary.first.id : 'res_girona';
    return _residenceCatalog.firstWhere(
      (r) => r.id == activeId,
      orElse: () => _residenceCatalog.first,
    );
  }

  int get _totalUnreadSms =>
      _smsThreads.fold<int>(0, (sum, t) => sum + t.unreadCount);

  int get _pendingContractsCount => _contractOffers
      .where((c) => c.status == BeAProContractOfferStatus.pending)
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isCompact = width < 760;
            final isDesktop = width >= 1200;

            return Column(
              children: [
                _buildTopHeader(isCompact: isCompact),
                Expanded(
                  child: isCompact
                      ? Column(
                          children: [
                            _buildHorizontalNavBar(),
                            Expanded(
                              child: _buildActiveSectionBody(
                                width: width,
                                isCompact: true,
                                isDesktop: false,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSideNavigationRail(isDesktop: isDesktop),
                            Expanded(
                              child: _buildActiveSectionBody(
                                width: width - (isDesktop ? 236 : 196),
                                isCompact: false,
                                isDesktop: isDesktop,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader({required bool isCompact}) {
    final rider = _careerState.playerRider;
    final trustTier = _careerState.dsTrustTier;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 24,
        vertical: isCompact ? 12 : 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.onBack != null) ...[
                _BeAProActionButton(
                  label: '',
                  icon: Icons.arrow_back_rounded,
                  variant: _BeAProButtonVariant.secondary,
                  compact: true,
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 10),
              ],
              Container(
                width: isCompact ? 40 : 46,
                height: isCompact ? 40 : 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryAccent, Color(0xFF4F2525)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppColors.goldAccent, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${rider.firstName[0]}${rider.lastName[0]}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            rider.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.textPrimary,
                              fontSize: isCompact ? 16 : 19,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(
                          label: 'OVR ${rider.overallRating}',
                          color: AppColors.goldAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_careerState.currentTeamName} • ${_careerState.careerTier.label} • ${rider.specialization.displayName}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCompact) ...[
                _HeaderMetricChip(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Konto',
                  value: Formatters.formatCurrency(_careerState.privateBalanceEur),
                  accent: AppColors.statusSuccess,
                ),
                const SizedBox(width: 10),
                _HeaderMetricChip(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Punkty Rozwoju',
                  value: '${_careerState.skillPoints} SP',
                  accent: AppColors.goldAccent,
                ),
                const SizedBox(width: 10),
                if (widget.onOpenRaceCalendar != null)
                  _BeAProActionButton(
                    label: 'Kalendarz',
                    icon: Icons.calendar_month_rounded,
                    variant: _BeAProButtonVariant.primary,
                    onPressed: widget.onOpenRaceCalendar,
                  ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isCompact ? double.infinity : 250,
                child: _CompactProgressBar(
                  label:
                      'Poziom ${_careerState.careerLevel} (${_careerState.experienceXp}/${_careerState.xpRequiredForNextLevel} XP)',
                  progress: _careerState.levelProgressRatio,
                  color: AppColors.accentBlue,
                ),
              ),
              SizedBox(
                width: isCompact ? double.infinity : 260,
                child: _CompactProgressBar(
                  label:
                      'Zaufanie DS: ${_careerState.dsTrustScoreRounded}/100 (${trustTier.label})',
                  progress: (_careerState.dsTrustScore / 100.0).clamp(0.0, 1.0),
                  color: AppColors.goldAccent,
                ),
              ),
              if (isCompact)
                Row(
                  children: [
                    Expanded(
                      child: _HeaderMetricChip(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Konto',
                        value: Formatters.formatCurrency(
                          _careerState.privateBalanceEur,
                        ),
                        accent: AppColors.statusSuccess,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HeaderMetricChip(
                        icon: Icons.auto_awesome_rounded,
                        label: 'Rozwój',
                        value: '${_careerState.skillPoints} SP',
                        accent: AppColors.goldAccent,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalNavBar() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            for (var i = 0; i < BeAProDashboardSection.values.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _NavTabItem(
                section: BeAProDashboardSection.values[i],
                isSelected: _activeSection == BeAProDashboardSection.values[i],
                badgeCount: _badgeCountForSection(BeAProDashboardSection.values[i]),
                compact: true,
                onTap: () => setState(
                  () => _activeSection = BeAProDashboardSection.values[i],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSideNavigationRail({required bool isDesktop}) {
    return Container(
      width: isDesktop ? 236 : 196,
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              'TRYB BE A PRO',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          ...BeAProDashboardSection.values.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _NavTabItem(
                section: section,
                isSelected: _activeSection == section,
                badgeCount: _badgeCountForSection(section),
                compact: false,
                onTap: () => setState(() => _activeSection = section),
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BILANS MIESIĘCZNY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  Formatters.formatCurrency(
                    _careerState.projectedMonthlyNetCashflowEur,
                  ),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: _careerState.projectedMonthlyNetCashflowEur >= 0
                        ? AppColors.statusSuccess
                        : AppColors.crimsonAlert,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kibice: ${_careerState.fanFollowersCount}',
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
    );
  }

  int _badgeCountForSection(BeAProDashboardSection section) {
    switch (section) {
      case BeAProDashboardSection.skillTree:
        return _careerState.skillPoints;
      case BeAProDashboardSection.messages:
        return _totalUnreadSms;
      case BeAProDashboardSection.contracts:
        return _pendingContractsCount;
      case BeAProDashboardSection.apartment:
      case BeAProDashboardSection.trophyCabinet:
        return 0;
    }
  }

  Widget _buildActiveSectionBody({
    required double width,
    required bool isCompact,
    required bool isDesktop,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: KeyedSubtree(
        key: ValueKey(_activeSection),
        child: switch (_activeSection) {
          BeAProDashboardSection.apartment => _buildApartmentSection(
              isCompact: isCompact,
              isDesktop: isDesktop,
            ),
          BeAProDashboardSection.skillTree => _buildSkillTreeSection(
              isCompact: isCompact,
              isDesktop: isDesktop,
            ),
          BeAProDashboardSection.messages => _buildSmsMessagesSection(
              isCompact: isCompact,
            ),
          BeAProDashboardSection.contracts => _buildContractOffersSection(
              isCompact: isCompact,
              isDesktop: isDesktop,
            ),
          BeAProDashboardSection.trophyCabinet => _buildTrophyCabinetSection(
              width: width,
              isCompact: isCompact,
            ),
        },
      ),
    );
  }

  // ===========================================================================
  // SEKCJA 1: APARTAMENT I BAZA TRENINGOWA
  // ===========================================================================
  Widget _buildApartmentSection({
    required bool isCompact,
    required bool isDesktop,
  }) {
    final residence = _activeResidencePreset;

    final sceneCard = _SectionCard(
      title: 'Apartament & Baza Treningowa — ${residence.name}',
      subtitle:
          '${residence.location} • ${residence.altitudeMeters} m n.p.m. • ${residence.atmosphereLabel}',
      trailing: _StatusPill(
        label:
            '+${_careerState.totalRecoveryBonusPercent.toStringAsFixed(0)}% Regeneracja',
        color: AppColors.statusSuccess,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: isCompact ? 210 : 265,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedBuilder(
                    animation: _ambientController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _ApartmentTrainingBasePainter(
                          residence: residence,
                          animationPhase: _ambientController.value,
                          selectedHotspotId: _selectedHotspotId,
                          hasHypoxicTent: _careerState.ownedPrivateEquipment.any(
                            (e) =>
                                e.id == 'eq_hypoxic_tent' && e.isEquipped,
                          ),
                          hasAeroWheels: _careerState.ownedPrivateEquipment.any(
                            (e) =>
                                e.id == 'eq_aero_wheels' && e.isEquipped,
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    right: 12,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HotspotChip(
                          label: 'Smart Trainer',
                          icon: Icons.directions_bike_rounded,
                          selected: _selectedHotspotId == 'trainer',
                          onTap: () =>
                              setState(() => _selectedHotspotId = 'trainer'),
                        ),
                        _HotspotChip(
                          label: 'Namiot Hipoksyjny',
                          icon: Icons.bedtime_rounded,
                          selected: _selectedHotspotId == 'tent',
                          onTap: () =>
                              setState(() => _selectedHotspotId = 'tent'),
                        ),
                        _HotspotChip(
                          label: 'Rower & Koła',
                          icon: Icons.tire_repair_rounded,
                          selected: _selectedHotspotId == 'bike',
                          onTap: () =>
                              setState(() => _selectedHotspotId = 'bike'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _MiniStatTile(
                    label: 'Premia XP',
                    value:
                        '+${_careerState.totalTrainingXpBonusPercent.round()}%',
                    color: AppColors.accentBlue,
                  ),
                  _MiniStatTile(
                    label: 'Oszczędność Aero',
                    value:
                        '-${_careerState.totalPrivateEquipmentWattSavings.toStringAsFixed(1)} W',
                    color: AppColors.goldAccent,
                  ),
                  _MiniStatTile(
                    label: 'Majątek Netto',
                    value: Formatters.formatCurrency(
                      _careerState.totalNetWorthEur,
                    ),
                    color: AppColors.statusSuccess,
                  ),
                ],
              ),
              _BeAProActionButton(
                label: 'Trenuj na Trenażerze (+XP)',
                icon: Icons.fitness_center_rounded,
                variant: _BeAProButtonVariant.gold,
                onPressed: _completeIndoorTrainingSession,
              ),
            ],
          ),
        ],
      ),
    );

    final equipmentCard = _SectionCard(
      title: 'Wyposażenie Bazy Kolarza',
      subtitle: 'Aktywuj sprzęt prywatny, aby wzmocnić trening i regenerację.',
      child: Column(
        children: _careerState.ownedPrivateEquipment.map((eq) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BeAProInteractiveCard(
              onTap: () => _toggleEquipmentEquipped(eq.id),
              borderColor: eq.isEquipped
                  ? AppColors.goldAccent.withValues(alpha: 0.7)
                  : AppColors.cardBorder,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Icon(
                      _iconForEquipmentCategory(eq.category),
                      color: eq.isEquipped
                          ? AppColors.goldAccent
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eq.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _equipmentBonusSummary(eq),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(
                    label: eq.isEquipped ? 'AKTYWNY' : 'WYŁĄCZONY',
                    color: eq.isEquipped
                        ? AppColors.statusSuccess
                        : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );

    final residencesCard = _SectionCard(
      title: 'Rezydencje Kolarskie',
      subtitle: 'Wybierz lub wykup nową bazę w Europie.',
      child: Column(
        children: _residenceCatalog.map((preset) {
          final isOwned =
              _careerState.ownedProperties.any((p) => p.id == preset.id);
          final isPrimary = residence.id == preset.id;
          final canAfford =
              _careerState.privateBalanceEur >= preset.purchasePriceEur;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BeAProInteractiveCard(
              borderColor: isPrimary
                  ? AppColors.goldAccent
                  : AppColors.cardBorder,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${preset.name} • ${preset.location}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isPrimary) ...[
                              const SizedBox(width: 8),
                              const _StatusPill(
                                label: 'BAZA GŁÓWNA',
                                color: AppColors.goldAccent,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Wysokość: ${preset.altitudeMeters} m • Reg. +${preset.recoveryBonusPercent.round()}% • Podatek -${preset.taxShieldPercent.round()}%',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _BeAProActionButton(
                    label: isPrimary
                        ? 'Aktywna'
                        : isOwned
                            ? 'Przenieś'
                            : Formatters.formatCurrency(
                                preset.purchasePriceEur,
                              ),
                    compact: true,
                    variant: isPrimary
                        ? _BeAProButtonVariant.secondary
                        : isOwned
                            ? _BeAProButtonVariant.primary
                            : _BeAProButtonVariant.gold,
                    onPressed: isPrimary || (!isOwned && !canAfford)
                        ? null
                        : () => _selectOrPurchaseResidence(preset),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sceneCard,
          const SizedBox(height: 16),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: equipmentCard),
                const SizedBox(width: 16),
                Expanded(child: residencesCard),
              ],
            )
          else ...[
            equipmentCard,
            const SizedBox(height: 16),
            residencesCard,
          ],
        ],
      ),
    );
  }

  IconData _iconForEquipmentCategory(ProCyclistEquipmentCategory category) {
    switch (category) {
      case ProCyclistEquipmentCategory.personalBike:
        return Icons.pedal_bike_rounded;
      case ProCyclistEquipmentCategory.aeroWheelset:
        return Icons.tire_repair_rounded;
      case ProCyclistEquipmentCategory.powerMeter:
        return Icons.speed_rounded;
      case ProCyclistEquipmentCategory.recoveryTech:
        return Icons.bedtime_rounded;
      case ProCyclistEquipmentCategory.indoorTrainer:
        return Icons.fitness_center_rounded;
      case ProCyclistEquipmentCategory.labDiagnostics:
        return Icons.biotech_rounded;
    }
  }

  String _equipmentBonusSummary(ProCyclistPrivateEquipment eq) {
    final parts = <String>[];
    if (eq.trainingXpBonusPercent > 0) {
      parts.add('+${eq.trainingXpBonusPercent.round()}% XP');
    }
    if (eq.recoveryBonusPercent > 0) {
      parts.add('+${eq.recoveryBonusPercent.toStringAsFixed(1)}% Regeneracja');
    }
    if (eq.wattSavings > 0) {
      parts.add('-${eq.wattSavings.toStringAsFixed(1)} W CdA');
    }
    return parts.isEmpty ? eq.category.label : parts.join(' • ');
  }

  // ===========================================================================
  // SEKCJA 2: DRZEWO ROZWOJU UMIEJĘTNOŚCI XP
  // ===========================================================================
  Widget _buildSkillTreeSection({
    required bool isCompact,
    required bool isDesktop,
  }) {
    final physNodes = _skillNodes
        .where((n) => n.branch == BeAProSkillBranch.physiological)
        .toList();
    final techNodes = _skillNodes
        .where((n) => n.branch == BeAProSkillBranch.technical)
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            title: 'Drzewo Rozwoju Kolarza (XP -> Punkty Rozwoju)',
            subtitle:
                'Dostępne punkty: ${_careerState.skillPoints} SP • Wydano łącznie: ${_careerState.totalSkillPointsSpent} SP',
            trailing: _BeAProActionButton(
              label: '+260 XP Trening',
              icon: Icons.bolt_rounded,
              compact: true,
              variant: _BeAProButtonVariant.gold,
              onPressed: _completeIndoorTrainingSession,
            ),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildSkillBranchColumn(
                          branch: BeAProSkillBranch.physiological,
                          nodes: physNodes,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSkillBranchColumn(
                          branch: BeAProSkillBranch.technical,
                          nodes: techNodes,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildSkillBranchColumn(
                        branch: BeAProSkillBranch.physiological,
                        nodes: physNodes,
                      ),
                      const SizedBox(height: 18),
                      _buildSkillBranchColumn(
                        branch: BeAProSkillBranch.technical,
                        nodes: techNodes,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillBranchColumn({
    required BeAProSkillBranch branch,
    required List<BeAProSkillNode> nodes,
  }) {
    final isPhys = branch == BeAProSkillBranch.physiological;
    final headerColor = isPhys ? AppColors.crimsonAlert : AppColors.accentBlue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isPhys ? Icons.favorite_rounded : Icons.settings_suggest_rounded,
                color: headerColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  branch.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...nodes.map((node) {
            final prereqMet = _isPrerequisiteMet(node);
            final canAfford = _careerState.skillPoints >= node.costSkillPoints;
            final canUpgrade = !node.isMaxed && prereqMet && canAfford;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BeAProInteractiveCard(
                onTap: canUpgrade ? () => _upgradeSkillNode(node) : null,
                disabled: !canUpgrade && !node.isMaxed,
                borderColor: node.isMaxed
                    ? AppColors.goldAccent
                    : canUpgrade
                        ? node.accentColor.withValues(alpha: 0.75)
                        : AppColors.cardBorder,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: node.accentColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: node.accentColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(node.icon, color: node.accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  node.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              _StatusPill(
                                label: 'T${node.tier} • ${node.currentLevel}/${node.maxLevel}',
                                color: node.isMaxed
                                    ? AppColors.goldAccent
                                    : AppColors.textSecondary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Aktualnie: ${_currentMetricForNode(node.id)} • ${node.deltaLabel}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          if (!prereqMet)
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Text(
                                'Wymaga odblokowania poprzedniego poziomu',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: AppColors.amberWarning,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _BeAProActionButton(
                      label: node.isMaxed ? 'MAX' : '${node.costSkillPoints} SP',
                      compact: true,
                      variant: node.isMaxed
                          ? _BeAProButtonVariant.secondary
                          : _BeAProButtonVariant.gold,
                      onPressed: canUpgrade ? () => _upgradeSkillNode(node) : null,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // SEKCJA 3: WIADOMOŚCI SMS OD DS I AGENTA
  // ===========================================================================
  Widget _buildSmsMessagesSection({required bool isCompact}) {
    final activeThread = _smsThreads.firstWhere(
      (t) => t.id == _selectedThreadId,
      orElse: () => _smsThreads.first,
    );

    final threadListWidget = Column(
      children: _smsThreads.map((thread) {
        final isSelected = thread.id == activeThread.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _BeAProInteractiveCard(
            onTap: () => _selectSmsThread(thread.id),
            borderColor:
                isSelected ? AppColors.goldAccent : AppColors.cardBorder,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      thread.role.badgeColor.withValues(alpha: 0.2),
                  child: Text(
                    thread.initials,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: thread.role.badgeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thread.contactName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        thread.role.badgeLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: thread.role.badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (thread.unreadCount > 0)
                  _StatusPill(
                    label: '${thread.unreadCount}',
                    color: AppColors.crimsonAlert,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );

    final chatWidget = _SectionCard(
      title: activeThread.contactName,
      subtitle: activeThread.contactSubtitle,
      trailing: _StatusPill(
        label: activeThread.role.badgeLabel,
        color: activeThread.role.badgeColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...activeThread.messages.map((msg) {
            return Align(
              alignment: msg.isFromPlayer
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxWidth: 520),
                decoration: BoxDecoration(
                  color: msg.isFromPlayer
                      ? AppColors.primaryAccent.withValues(alpha: 0.35)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: msg.isFromPlayer
                        ? AppColors.primaryAccent
                        : AppColors.cardBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.text,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      msg.timestampLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (activeThread.quickReplies.isNotEmpty) ...[
            const Divider(color: AppColors.cardBorder, height: 22),
            const Text(
              'SZYBKIE ODPOWIEDZI SMS',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: activeThread.quickReplies.map((reply) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BeAProInteractiveCard(
                    onTap: () => _sendQuickReply(activeThread, reply),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.send_rounded,
                          size: 15,
                          color: AppColors.goldAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reply.text,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                threadListWidget,
                const SizedBox(height: 12),
                chatWidget,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 280, child: threadListWidget),
                const SizedBox(width: 16),
                Expanded(child: chatWidget),
              ],
            ),
    );
  }

  // ===========================================================================
  // SEKCJA 4: OFERTY KONTRAKTOWE WORLDTOUR
  // ===========================================================================
  Widget _buildContractOffersSection({
    required bool isCompact,
    required bool isDesktop,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      child: _SectionCard(
        title: 'Oferty Kontraktowe WorldTour & ProTeam',
        subtitle:
            'Aktualny kontrakt: ${_careerState.currentTeamName} (${Formatters.formatCurrency(_careerState.playerRider.contract.monthlySalaryEur)}/mies.)',
        child: Column(
          children: _contractOffers.map((offer) {
            final ovrOk =
                _careerState.playerRider.overallRating >= offer.minOvrRequired;
            final trustOk = _careerState.dsTrustScore >= offer.minTrustRequired;
            final eligible = ovrOk && trustOk;
            final isAccepted =
                offer.status == BeAProContractOfferStatus.accepted;
            final isDeclined =
                offer.status == BeAProContractOfferStatus.declined;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BeAProInteractiveCard(
                borderColor: isAccepted
                    ? AppColors.statusSuccess
                    : eligible
                        ? AppColors.goldAccent.withValues(alpha: 0.65)
                        : AppColors.cardBorder,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 42,
                          height: 42,
                          child: CustomPaint(
                            painter: _CabinetJerseyPainter(
                              primaryColor: offer.jerseyPrimaryColor,
                              secondaryColor: offer.jerseySecondaryColor,
                              pattern: CabinetJerseyPattern.solid,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                offer.teamName,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${offer.division.label} • Rola: ${offer.offeredRole.label}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _StatusPill(
                          label: isAccepted
                              ? 'PODPISANO'
                              : isDeclined
                                  ? 'ODRZUCONO'
                                  : eligible
                                      ? 'KWALIFIKACJA OK'
                                      : 'WYMAGA OVR ${offer.minOvrRequired}',
                          color: isAccepted
                              ? AppColors.statusSuccess
                              : isDeclined
                                  ? AppColors.textSecondary
                                  : eligible
                                      ? AppColors.goldAccent
                                      : AppColors.amberWarning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      offer.pitchSummary,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _MiniStatTile(
                          label: 'Pensja / rok',
                          value: Formatters.formatCurrency(offer.annualSalaryEur),
                          color: AppColors.statusSuccess,
                        ),
                        _MiniStatTile(
                          label: 'Bonus podpis',
                          value: Formatters.formatCurrency(offer.signingBonusEur),
                          color: AppColors.goldAccent,
                        ),
                        _MiniStatTile(
                          label: 'Okres',
                          value: '${offer.contractYears} lata',
                          color: AppColors.accentBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: offer.guaranteedRaces
                          .map(
                            (race) => _StatusPill(
                              label: race,
                              color: AppColors.accentBlue,
                            ),
                          )
                          .toList(),
                    ),
                    if (offer.status == BeAProContractOfferStatus.pending) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _BeAProActionButton(
                            label: 'Odrzuć',
                            compact: true,
                            variant: _BeAProButtonVariant.secondary,
                            onPressed: () => _declineContractOffer(offer),
                          ),
                          _BeAProActionButton(
                            label: 'Podpisz Kontrakt',
                            icon: Icons.verified_rounded,
                            compact: true,
                            variant: _BeAProButtonVariant.gold,
                            onPressed: eligible
                                ? () => _acceptContractOffer(offer)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ===========================================================================
  // SEKCJA 5: GABLOTA PRYWATNYCH KOSZULEK I PUCHARÓW
  // ===========================================================================
  Widget _buildTrophyCabinetSection({
    required double width,
    required bool isCompact,
  }) {
    final filtered = _cabinetItems.where((item) {
      switch (_cabinetFilter) {
        case TrophyCabinetFilter.all:
          return true;
        case TrophyCabinetFilter.jerseys:
          return item.isJersey;
        case TrophyCabinetFilter.trophies:
          return !item.isJersey;
      }
    }).toList();

    final unlockedCount = _cabinetItems.where((i) => i.isUnlocked).length;
    final columns = width >= 1100 ? 4 : (width >= 680 ? 3 : 2);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      child: _SectionCard(
        title: 'Gablota Prywatnych Koszulek i Pucharów',
        subtitle:
            'Zdobyte eksponaty: $unlockedCount/${_cabinetItems.length} • Zwycięstwa kariery: ${_careerState.palmares.careerWins}',
        trailing: Wrap(
          spacing: 6,
          children: TrophyCabinetFilter.values.map((filter) {
            final selected = _cabinetFilter == filter;
            return _HotspotChip(
              label: filter.label,
              icon: filter == TrophyCabinetFilter.jerseys
                  ? Icons.checkroom_rounded
                  : filter == TrophyCabinetFilter.trophies
                      ? Icons.emoji_events_rounded
                      : Icons.auto_awesome_mosaic_rounded,
              selected: selected,
              onTap: () => setState(() => _cabinetFilter = filter),
            );
          }).toList(),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isCompact ? 0.85 : 0.95,
          ),
          itemBuilder: (context, index) {
            final item = filtered[index];
            final isSelected = _selectedCabinetItemId == item.id;
            return _BeAProInteractiveCard(
              onTap: () => setState(() => _selectedCabinetItemId = item.id),
              borderColor: isSelected
                  ? AppColors.goldAccent
                  : item.isUnlocked
                      ? item.primaryColor.withValues(alpha: 0.5)
                      : AppColors.cardBorder,
              child: Opacity(
                opacity: item.isUnlocked ? 1.0 : 0.48,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 68,
                      height: 68,
                      child: CustomPaint(
                        painter: item.isJersey
                            ? _CabinetJerseyPainter(
                                primaryColor: item.primaryColor,
                                secondaryColor: item.secondaryColor,
                                pattern: item.jerseyPattern,
                              )
                            : _CabinetTrophyPainter(
                                kind: item.trophyKind,
                                primaryColor: item.primaryColor,
                                secondaryColor: item.secondaryColor,
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.isUnlocked
                          ? '${item.raceName} (${item.seasonYear})'
                          : 'Do zdobycia • ${item.raceName}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// =============================================================================
// REUSABLE INTERACTIVE & VISUAL COMPONENTS
// =============================================================================

enum _BeAProButtonVariant {
  primary,
  secondary,
  gold,
}

class _BeAProActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final _BeAProButtonVariant variant;
  final bool compact;

  const _BeAProActionButton({
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = _BeAProButtonVariant.primary,
    this.compact = false,
  });

  @override
  State<_BeAProActionButton> createState() => _BeAProActionButtonState();
}

class _BeAProActionButtonState extends State<_BeAProActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final Color baseBg;
    final Color baseBorder;
    final Color fgColor;

    switch (widget.variant) {
      case _BeAProButtonVariant.primary:
        baseBg = AppColors.primaryAccent;
        baseBorder = AppColors.primaryAccent;
        fgColor = AppColors.textPrimary;
        break;
      case _BeAProButtonVariant.secondary:
        baseBg = AppColors.surfaceLight;
        baseBorder = AppColors.cardBorder;
        fgColor = AppColors.textPrimary;
        break;
      case _BeAProButtonVariant.gold:
        baseBg = AppColors.goldAccent.withValues(alpha: 0.16);
        baseBorder = AppColors.goldAccent;
        fgColor = AppColors.goldAccent;
        break;
    }

    final effectiveBg = disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.5)
        : _pressed
            ? baseBg.withValues(alpha: 0.72)
            : _hovered
                ? baseBg.withValues(alpha: 0.92)
                : baseBg;

    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 11 : 16,
            vertical: widget.compact ? 7 : 10,
          ),
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : disabled
                      ? AppColors.cardBorder
                      : baseBorder,
              width: _focused ? 1.8 : 1.0,
            ),
          ),
          child: Opacity(
            opacity: disabled ? 0.5 : 1.0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: widget.compact ? 15 : 17, color: fgColor),
                  if (widget.label.isNotEmpty) const SizedBox(width: 6),
                ],
                if (widget.label.isNotEmpty)
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: fgColor,
                        fontSize: widget.compact ? 12 : 13,
                        fontWeight: FontWeight.w600,
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

class _BeAProInteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color borderColor;
  final bool disabled;

  const _BeAProInteractiveCard({
    required this.child,
    this.onTap,
    this.borderColor = AppColors.cardBorder,
    this.disabled = false,
  });

  @override
  State<_BeAProInteractiveCard> createState() => _BeAProInteractiveCardState();
}

class _BeAProInteractiveCardState extends State<_BeAProInteractiveCard> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null && !widget.disabled;

    return FocusableActionDetector(
      enabled: interactive,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: interactive ? (_) => setState(() => _pressed = true) : null,
        onTapUp: interactive ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            interactive ? () => setState(() => _pressed = false) : null,
        onTap: interactive ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.surface
                : _hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.95)
                    : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : _hovered && interactive
                      ? AppColors.goldAccent.withValues(alpha: 0.75)
                      : widget.borderColor,
              width: _focused ? 1.6 : 1.0,
            ),
          ),
          child: Opacity(
            opacity: widget.disabled ? 0.65 : 1.0,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final titleCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              );

              if (trailing == null) return titleCol;
              if (headerConstraints.maxWidth >= 560) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: titleCol),
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleCol,
                  const SizedBox(height: 10),
                  trailing!,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _NavTabItem extends StatefulWidget {
  final BeAProDashboardSection section;
  final bool isSelected;
  final int badgeCount;
  final bool compact;
  final VoidCallback onTap;

  const _NavTabItem({
    required this.section,
    required this.isSelected,
    required this.badgeCount,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_NavTabItem> createState() => _NavTabItemState();
}

class _NavTabItemState extends State<_NavTabItem> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 12 : 12,
            vertical: widget.compact ? 6 : 11,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primaryAccent.withValues(alpha: 0.25)
                : _hovered
                    ? AppColors.surfaceLight
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : widget.isSelected
                      ? AppColors.primaryAccent
                      : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: widget.compact ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(
                widget.section.icon,
                size: 18,
                color: widget.isSelected
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              if (widget.compact)
                Text(
                  widget.section.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: widget.isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight:
                        widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                )
              else
                Expanded(
                  child: Text(
                    widget.section.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: widget.isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight:
                          widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              if (widget.badgeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${widget.badgeCount}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.goldAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeaderMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _HeaderMetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
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
        ],
      ),
    );
  }
}

class _CompactProgressBar extends StatelessWidget {
  final String label;
  final double progress;
  final Color color;

  const _CompactProgressBar({
    required this.label,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _MiniStatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _HotspotChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _HotspotChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.goldAccent.withValues(alpha: 0.22)
              : AppColors.surface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.goldAccent : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? AppColors.goldAccent : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                color: selected ? AppColors.goldAccent : AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTERS (APARTAMENT, KOSZULKI, PUCHARY)
// =============================================================================

class _ApartmentTrainingBasePainter extends CustomPainter {
  final BeAProResidencePreset residence;
  final double animationPhase;
  final String? selectedHotspotId;
  final bool hasHypoxicTent;
  final bool hasAeroWheels;

  const _ApartmentTrainingBasePainter({
    required this.residence,
    required this.animationPhase,
    required this.selectedHotspotId,
    required this.hasHypoxicTent,
    required this.hasAeroWheels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Tło ściany apartamentu
    final wallPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF151922), Color(0xFF0F1115)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), wallPaint);

    // Panoramiczne okno z widokiem górskim
    final windowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.1,
        size.width * 0.48,
        size.height * 0.52,
      ),
      const Radius.circular(10),
    );
    final skyPaint = Paint()
      ..shader = LinearGradient(
        colors: [residence.skyTopColor, residence.skyBottomColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(windowRect.outerRect);
    canvas.drawRRect(windowRect, skyPaint);

    // Sylwetki gór w oknie
    canvas.save();
    canvas.clipRRect(windowRect);
    final mountainPath = Path()
      ..moveTo(windowRect.left, windowRect.bottom)
      ..lineTo(windowRect.left + windowRect.width * 0.25, windowRect.top + windowRect.height * 0.45)
      ..lineTo(windowRect.left + windowRect.width * 0.48, windowRect.top + windowRect.height * 0.65)
      ..lineTo(windowRect.left + windowRect.width * 0.72, windowRect.top + windowRect.height * 0.32)
      ..lineTo(windowRect.right, windowRect.top + windowRect.height * 0.58)
      ..lineTo(windowRect.right, windowRect.bottom)
      ..close();
    canvas.drawPath(
      mountainPath,
      Paint()..color = const Color(0xFF0B0E14).withValues(alpha: 0.72),
    );
    canvas.restore();

    // Rama okna
    canvas.drawRRect(
      windowRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = AppColors.cardBorder,
    );

    // Podłoga treningowa
    final floorRect = Rect.fromLTWH(
      0,
      size.height * 0.72,
      size.width,
      size.height * 0.28,
    );
    canvas.drawRect(
      floorRect,
      Paint()..color = const Color(0xFF1D212B),
    );
    canvas.drawLine(
      Offset(0, size.height * 0.72),
      Offset(size.width, size.height * 0.72),
      Paint()
        ..color = AppColors.cardBorder
        ..strokeWidth = 1.2,
    );

    // Smart Trainer + Rower na środku
    final trainerCenter = Offset(size.width * 0.36, size.height * 0.70);
    final wheelRadius = math.min(size.height * 0.11, 24.0);
    final bikePaint = Paint()
      ..color = selectedHotspotId == 'trainer'
          ? AppColors.goldAccent
          : AppColors.textPrimary
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      Offset(trainerCenter.dx + wheelRadius * 1.4, trainerCenter.dy - wheelRadius),
      wheelRadius,
      bikePaint,
    );
    // Rama roweru na trenażerze
    final framePath = Path()
      ..moveTo(trainerCenter.dx - wheelRadius * 1.1, trainerCenter.dy - wheelRadius * 0.6)
      ..lineTo(trainerCenter.dx, trainerCenter.dy - wheelRadius * 1.7)
      ..lineTo(trainerCenter.dx + wheelRadius * 1.1, trainerCenter.dy - wheelRadius * 1.65)
      ..lineTo(trainerCenter.dx + wheelRadius * 0.1, trainerCenter.dy - wheelRadius * 0.6)
      ..close();
    canvas.drawPath(framePath, bikePaint);

    // Namiot hipoksyjny po prawej
    if (hasHypoxicTent) {
      final tentRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.64,
          size.height * 0.44,
          size.width * 0.28,
          size.height * 0.28,
        ),
        const Radius.circular(14),
      );
      canvas.drawRRect(
        tentRect,
        Paint()
          ..color = AppColors.accentBlue.withValues(
            alpha: 0.12 + 0.06 * animationPhase,
          ),
      );
      canvas.drawRRect(
        tentRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selectedHotspotId == 'tent' ? 2.0 : 1.2
          ..color = selectedHotspotId == 'tent'
              ? AppColors.goldAccent
              : AppColors.accentBlue.withValues(alpha: 0.7),
      );
    }

    // Zapasowe koła aero na ścianie
    if (hasAeroWheels) {
      final wheelPos = Offset(size.width * 0.78, size.height * 0.24);
      canvas.drawCircle(
        wheelPos,
        20,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..color = selectedHotspotId == 'bike'
              ? AppColors.goldAccent
              : AppColors.textSecondary,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ApartmentTrainingBasePainter oldDelegate) {
    return oldDelegate.animationPhase != animationPhase ||
        oldDelegate.residence.id != residence.id ||
        oldDelegate.selectedHotspotId != selectedHotspotId ||
        oldDelegate.hasHypoxicTent != hasHypoxicTent ||
        oldDelegate.hasAeroWheels != hasAeroWheels;
  }
}

class _CabinetJerseyPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final CabinetJerseyPattern pattern;

  const _CabinetJerseyPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.pattern,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.34, h * 0.12)
      ..lineTo(w * 0.66, h * 0.12)
      ..lineTo(w * 0.90, h * 0.32)
      ..lineTo(w * 0.80, h * 0.48)
      ..lineTo(w * 0.72, h * 0.42)
      ..lineTo(w * 0.72, h * 0.88)
      ..lineTo(w * 0.28, h * 0.88)
      ..lineTo(w * 0.28, h * 0.42)
      ..lineTo(w * 0.20, h * 0.48)
      ..lineTo(w * 0.10, h * 0.32)
      ..close();

    canvas.drawPath(path, Paint()..color = primaryColor);

    canvas.save();
    canvas.clipPath(path);
    if (pattern == CabinetJerseyPattern.polkaDot) {
      final dotPaint = Paint()..color = secondaryColor;
      for (var y = 0.24; y <= 0.82; y += 0.18) {
        for (var x = 0.32; x <= 0.68; x += 0.18) {
          canvas.drawCircle(Offset(w * x, h * y), w * 0.045, dotPaint);
        }
      }
    } else if (pattern == CabinetJerseyPattern.rainbow) {
      const colors = [
        Color(0xFF38BDF8),
        Color(0xFFEF4444),
        Color(0xFF181B22),
        Color(0xFFEAB308),
        Color(0xFF10B981),
      ];
      for (var i = 0; i < colors.length; i++) {
        canvas.drawRect(
          Rect.fromLTWH(0, h * (0.42 + i * 0.04), w, h * 0.04),
          Paint()..color = colors[i],
        );
      }
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, h * 0.48, w, h * 0.12),
        Paint()..color = secondaryColor.withValues(alpha: 0.85),
      );
    }
    canvas.restore();

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = AppColors.cardBorder,
    );
  }

  @override
  bool shouldRepaint(covariant _CabinetJerseyPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.pattern != pattern;
  }
}

class _CabinetTrophyPainter extends CustomPainter {
  final CabinetTrophyKind kind;
  final Color primaryColor;
  final Color secondaryColor;

  const _CabinetTrophyPainter({
    required this.kind,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fillPaint = Paint()..color = primaryColor;
    final strokePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    if (kind == CabinetTrophyKind.cobblestone) {
      final stoneRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.25, h * 0.24, w * 0.50, h * 0.48),
        const Radius.circular(6),
      );
      canvas.drawRRect(stoneRect, fillPaint);
      canvas.drawRRect(stoneRect, strokePaint);
      canvas.drawRect(
        Rect.fromLTWH(w * 0.20, h * 0.74, w * 0.60, h * 0.12),
        Paint()..color = const Color(0xFF222630),
      );
      return;
    }

    // Puchar klasyczny
    final cupPath = Path()
      ..moveTo(w * 0.26, h * 0.18)
      ..lineTo(w * 0.74, h * 0.18)
      ..lineTo(w * 0.64, h * 0.54)
      ..lineTo(w * 0.36, h * 0.54)
      ..close();
    canvas.drawPath(cupPath, fillPaint);
    canvas.drawPath(cupPath, strokePaint);

    // Nóżka i podstawa
    canvas.drawRect(
      Rect.fromLTWH(w * 0.45, h * 0.54, w * 0.10, h * 0.18),
      fillPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.30, h * 0.72, w * 0.40, h * 0.14),
      Paint()..color = secondaryColor,
    );
  }

  @override
  bool shouldRepaint(covariant _CabinetTrophyPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
