import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../services/career/national_championships_and_worlds_service.dart';
import '../widgets/collectible_pro_rider_holo_card.dart';

/// Epoka historyczna lub współczesna w Albumie Kart i Kolekcji Gwiazd.
enum LegendCardEra {
  goldenSeventies(
    'Złote Lata 70.',
    '1970–1984',
    Color(0xFFD4AF37),
    'Era kanibali szosowych, stalowych ram i epickich pojedynków w Alpach.',
  ),
  classicEightiesNineties(
    'Epoka Klasyków 80/90',
    '1985–1999',
    Color(0xFF8E4A49),
    'Złoty wiek brukowanych monumentów, podjazdów z atakami z korby i włoskich tifosi.',
  ),
  modernGrandTours(
    'Nowoczesne Wielkie Toury',
    '2000–2019',
    Color(0xFF38BDF8),
    'Narodziny treningu na waty, pociągów górskich i karbonowej aerodynamiki.',
  ),
  currentWorldTour(
    'Era Współczesna WT',
    '2020–2026',
    Color(0xFF10B981),
    'Pokolenie wszechstronnych fenomenów łączących bruki, czasówki i wysokie góry.',
  );

  final String label;
  final String yearRange;
  final Color accentColor;
  final String description;

  const LegendCardEra(
    this.label,
    this.yearRange,
    this.accentColor,
    this.description,
  );

  String toJson() => name;

  static LegendCardEra fromJson(String value) {
    return LegendCardEra.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LegendCardEra.currentWorldTour,
    );
  }
}

/// Źródło odblokowania karty kolekcjonerskiej w trakcie kariery.
enum CardUnlockSource {
  careerSigning('Kontrakt w Karierze', Icons.badge_outlined),
  worldTourVictory('Zwycięstwo WorldTour', Icons.emoji_events_outlined),
  achievementMilestone('Osiągnięcie Menedżera', Icons.military_tech_outlined),
  tacticalChallenge('Wyzwanie Taktyczne', Icons.psychology_outlined),
  championshipPack('Złota Paczka Mistrzowska', Icons.auto_awesome_outlined);

  final String label;
  final IconData icon;

  const CardUnlockSource(this.label, this.icon);

  String toJson() => name;

  static CardUnlockSource fromJson(String value) {
    return CardUnlockSource.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CardUnlockSource.championshipPack,
    );
  }
}

/// Ranga paczki nagród za sukcesy wyścigowe i wyzwania.
enum ChampionshipPackTier {
  worldTourGoldPack(
    'Złota Paczka Mistrzowska',
    'Gwarantowana gwiazda OVR 88+ po wygraniu wyścigu WorldTour',
    AppColors.goldAccent,
    88,
  ),
  monumentTrophyPack(
    'Paczka Monumentu',
    'Specjalna paczka klasyków brukowanych i pagórkowatych (OVR 85+)',
    AppColors.primaryAccent,
    85,
  ),
  tacticalMasteryPack(
    'Paczka Wyzwań Taktycznych',
    'Nagroda za złoty medal w Scenariuszu Historycznym (OVR 84+)',
    AppColors.accentBlue,
    84,
  );

  final String label;
  final String description;
  final Color accentColor;
  final int guaranteedMinOvr;

  const ChampionshipPackTier(
    this.label,
    this.description,
    this.accentColor,
    this.guaranteedMinOvr,
  );

  String toJson() => name;

  static ChampionshipPackTier fromJson(String value) {
    return ChampionshipPackTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ChampionshipPackTier.worldTourGoldPack,
    );
  }
}

/// Tryb grupowania kart w interaktywnym albumie.
enum LegendsAlbumGroupingMode {
  byEra('Epoki'),
  byTeam('Drużyny');

  final String label;
  const LegendsAlbumGroupingMode(this.label);
}

/// Tryb filtrowania kart w albumie.
enum LegendsAlbumFilterMode {
  all('Wszystkie'),
  unlockedOnly('Odblokowane'),
  lockedOnly('Nieodblokowane'),
  goldLegendsOnly('Złote Legendy 90+'),
  favoritesOnly('Ulubione');

  final String label;
  const LegendsAlbumFilterMode(this.label);
}

/// Pojedynczy wpis karty w Albumie Legend i Gwiazd.
@immutable
class AlbumLegendCardEntry {
  final CollectibleProRiderCardData cardData;
  final LegendCardEra era;
  final String teamGroup;
  final CardUnlockSource unlockSource;
  final String unlockRequirementText;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int duplicateCount;
  final bool isFavorite;

  const AlbumLegendCardEntry({
    required this.cardData,
    required this.era,
    required this.teamGroup,
    required this.unlockSource,
    required this.unlockRequirementText,
    this.isUnlocked = false,
    this.unlockedAt,
    this.duplicateCount = 0,
    this.isFavorite = false,
  });

  String get riderId => cardData.riderId;

  AlbumLegendCardEntry copyWith({
    CollectibleProRiderCardData? cardData,
    LegendCardEra? era,
    String? teamGroup,
    CardUnlockSource? unlockSource,
    String? unlockRequirementText,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? duplicateCount,
    bool? isFavorite,
  }) {
    return AlbumLegendCardEntry(
      cardData: cardData ?? this.cardData,
      era: era ?? this.era,
      teamGroup: teamGroup ?? this.teamGroup,
      unlockSource: unlockSource ?? this.unlockSource,
      unlockRequirementText:
          unlockRequirementText ?? this.unlockRequirementText,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      duplicateCount: duplicateCount ?? this.duplicateCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
        'cardData': cardData.toJson(),
        'era': era.toJson(),
        'teamGroup': teamGroup,
        'unlockSource': unlockSource.toJson(),
        'unlockRequirementText': unlockRequirementText,
        'isUnlocked': isUnlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
        'duplicateCount': duplicateCount,
        'isFavorite': isFavorite,
      };

  factory AlbumLegendCardEntry.fromJson(Map<String, dynamic> json) {
    final unlockedRaw = json['unlockedAt'] as String?;
    return AlbumLegendCardEntry(
      cardData: CollectibleProRiderCardData.fromJson(
        json['cardData'] as Map<String, dynamic>? ?? const {},
      ),
      era: LegendCardEra.fromJson(json['era'] as String? ?? 'currentWorldTour'),
      teamGroup: json['teamGroup'] as String? ?? 'WorldTour Legends',
      unlockSource: CardUnlockSource.fromJson(
        json['unlockSource'] as String? ?? 'championshipPack',
      ),
      unlockRequirementText:
          json['unlockRequirementText'] as String? ?? 'Złota Paczka Mistrzowska',
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: unlockedRaw != null ? DateTime.tryParse(unlockedRaw) : null,
      duplicateCount: (json['duplicateCount'] as num?)?.toInt() ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}

/// Oczekująca paczka mistrzowska przyznana po wygraniu wyścigu WorldTour lub wyzwania.
@immutable
class PendingChampionshipPack {
  final String packId;
  final String title;
  final String originRaceName;
  final ChampionshipPackTier tier;
  final int cardCount;
  final bool isOpened;
  final DateTime awardedAt;

  const PendingChampionshipPack({
    required this.packId,
    required this.title,
    required this.originRaceName,
    required this.tier,
    this.cardCount = 3,
    this.isOpened = false,
    required this.awardedAt,
  });

  PendingChampionshipPack copyWith({
    bool? isOpened,
  }) {
    return PendingChampionshipPack(
      packId: packId,
      title: title,
      originRaceName: originRaceName,
      tier: tier,
      cardCount: cardCount,
      isOpened: isOpened ?? this.isOpened,
      awardedAt: awardedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'packId': packId,
        'title': title,
        'originRaceName': originRaceName,
        'tier': tier.toJson(),
        'cardCount': cardCount,
        'isOpened': isOpened,
        'awardedAt': awardedAt.toIso8601String(),
      };

  factory PendingChampionshipPack.fromJson(Map<String, dynamic> json) {
    return PendingChampionshipPack(
      packId: json['packId'] as String? ?? 'pack-unknown',
      title: json['title'] as String? ?? 'Złota Paczka Mistrzowska',
      originRaceName:
          json['originRaceName'] as String? ?? 'Wyścig WorldTour',
      tier: ChampionshipPackTier.fromJson(
        json['tier'] as String? ?? 'worldTourGoldPack',
      ),
      cardCount: (json['cardCount'] as num?)?.toInt() ?? 3,
      isOpened: json['isOpened'] as bool? ?? false,
      awardedAt: DateTime.tryParse(json['awardedAt'] as String? ?? '') ??
          DateTime(2026, 7, 26),
    );
  }
}

/// Wynik otwarcia paczki z informacją, które karty są nowe, a które są duplikatami.
@immutable
class OpenedPackPullItem {
  final AlbumLegendCardEntry entry;
  final bool isNewUnlock;

  const OpenedPackPullItem({
    required this.entry,
    required this.isNewUnlock,
  });
}

@immutable
class PackOpenResult {
  final PendingChampionshipPack pack;
  final List<OpenedPackPullItem> pulledCards;

  const PackOpenResult({
    required this.pack,
    required this.pulledCards,
  });
}

/// Pełny stan Albumu Kart i Paczek Mistrzowskich.
@immutable
class LegendsCardAlbumState {
  final List<AlbumLegendCardEntry> entries;
  final List<PendingChampionshipPack> pendingPacks;
  final LegendsAlbumGroupingMode groupingMode;
  final LegendsAlbumFilterMode filterMode;
  final String searchQuery;
  final String? selectedRiderId;
  final int worldTourWinsCount;

  const LegendsCardAlbumState({
    required this.entries,
    required this.pendingPacks,
    this.groupingMode = LegendsAlbumGroupingMode.byEra,
    this.filterMode = LegendsAlbumFilterMode.all,
    this.searchQuery = '',
    this.selectedRiderId,
    this.worldTourWinsCount = 1,
  });

  int get totalCards => entries.length;
  int get unlockedCards => entries.where((e) => e.isUnlocked).length;
  int get goldLegendsUnlocked =>
      entries.where((e) => e.isUnlocked && e.cardData.isGoldLegend).length;
  int get totalDuplicates =>
      entries.fold<int>(0, (sum, e) => sum + e.duplicateCount);
  double get completionRatio =>
      totalCards == 0 ? 0.0 : (unlockedCards / totalCards).clamp(0.0, 1.0);
  int get completionPercent => (completionRatio * 100).round();

  List<PendingChampionshipPack> get unopenedPacks =>
      pendingPacks.where((p) => !p.isOpened).toList(growable: false);

  AlbumLegendCardEntry? get selectedEntry {
    if (entries.isEmpty) return null;
    if (selectedRiderId == null) return entries.first;
    for (final entry in entries) {
      if (entry.riderId == selectedRiderId) return entry;
    }
    return entries.first;
  }

  List<AlbumLegendCardEntry> get filteredEntries {
    final q = searchQuery.trim().toLowerCase();
    return entries.where((entry) {
      switch (filterMode) {
        case LegendsAlbumFilterMode.all:
          break;
        case LegendsAlbumFilterMode.unlockedOnly:
          if (!entry.isUnlocked) return false;
        case LegendsAlbumFilterMode.lockedOnly:
          if (entry.isUnlocked) return false;
        case LegendsAlbumFilterMode.goldLegendsOnly:
          if (!entry.cardData.isGoldLegend) return false;
        case LegendsAlbumFilterMode.favoritesOnly:
          if (!entry.isFavorite) return false;
      }

      if (q.isEmpty) return true;
      return entry.cardData.fullName.toLowerCase().contains(q) ||
          entry.teamGroup.toLowerCase().contains(q) ||
          entry.cardData.nationalityIso.toLowerCase().contains(q) ||
          entry.era.label.toLowerCase().contains(q) ||
          entry.cardData.shortRoleLabel.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  LegendsCardAlbumState copyWith({
    List<AlbumLegendCardEntry>? entries,
    List<PendingChampionshipPack>? pendingPacks,
    LegendsAlbumGroupingMode? groupingMode,
    LegendsAlbumFilterMode? filterMode,
    String? searchQuery,
    String? selectedRiderId,
    int? worldTourWinsCount,
  }) {
    return LegendsCardAlbumState(
      entries: entries ?? this.entries,
      pendingPacks: pendingPacks ?? this.pendingPacks,
      groupingMode: groupingMode ?? this.groupingMode,
      filterMode: filterMode ?? this.filterMode,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRiderId: selectedRiderId ?? this.selectedRiderId,
      worldTourWinsCount: worldTourWinsCount ?? this.worldTourWinsCount,
    );
  }
}

/// Katalog startowy kart kolarzy podzielonych na drużyny i epoki.
class LegendsAlbumCatalog {
  LegendsAlbumCatalog._();

  static List<AlbumLegendCardEntry> buildDefaultEntries() {
    return [
      // === ZŁOTE LATA 70. ===
      AlbumLegendCardEntry(
        cardData: const CollectibleProRiderCardData(
          riderId: 'leg_merckx_74',
          fullName: 'Eddy Vermeulen',
          shortRoleLabel: 'CANNIBAL GC',
          nationalityIso: 'BEL',
          teamName: 'Molteni Heritage',
          teamShortCode: 'MOL',
          ovr: 97,
          editionYear: 1974,
          cardSerialNumber: '01/10',
          stats: ProRiderCardStats(
            mon: 96,
            hil: 97,
            itt: 98,
            spr: 90,
            cob: 95,
            rec: 99,
          ),
          grandTourWins: [
            GrandTourWinBadge(
              tour: GrandTourType.tourDeFrance,
              years: [1969, 1970, 1971, 1972, 1974],
            ),
            GrandTourWinBadge(
              tour: GrandTourType.giroDItalia,
              years: [1968, 1970, 1972, 1973, 1974],
            ),
            GrandTourWinBadge(
              tour: GrandTourType.vueltaAEspana,
              years: [1973],
            ),
          ],
          specialJersey: SpecialJerseyDesignation.rainbowJersey,
          primaryJerseyColorHex: '#D4AF37',
          secondaryJerseyColorHex: '#8E4A49',
          accentJerseyColorHex: '#181B22',
          customAutographText: 'E. Vermeulen',
        ),
        era: LegendCardEra.goldenSeventies,
        teamGroup: 'Molteni Heritage',
        unlockSource: CardUnlockSource.championshipPack,
        unlockRequirementText:
            'Wylosuj w Złotej Paczce Mistrzowskiej lub wygraj potrójną koronę GT',
        isUnlocked: true,
        unlockedAt: DateTime(2026, 5, 12),
      ),
      const AlbumLegendCardEntry(
        cardData: CollectibleProRiderCardData(
          riderId: 'leg_de_vlaeminck_75',
          fullName: 'Roger De Smet',
          shortRoleLabel: 'COBBLES KING',
          nationalityIso: 'BEL',
          teamName: 'Brooklyn Classic',
          teamShortCode: 'BRK',
          ovr: 93,
          editionYear: 1975,
          cardSerialNumber: '04/25',
          stats: ProRiderCardStats(
            mon: 78,
            hil: 92,
            itt: 84,
            spr: 93,
            cob: 99,
            rec: 90,
          ),
          specialJersey: SpecialJerseyDesignation.nationalChampionJersey,
          primaryJerseyColorHex: '#1E3A8A',
          secondaryJerseyColorHex: '#EF4444',
          accentJerseyColorHex: '#F3F4F6',
          customAutographText: 'R. De Smet',
        ),
        era: LegendCardEra.goldenSeventies,
        teamGroup: 'Brooklyn Classic',
        unlockSource: CardUnlockSource.tacticalChallenge,
        unlockRequirementText:
            'Wyzwanie Taktyczne: Zdobądź złoty medal na brukach Piekła Północy',
        isUnlocked: false,
      ),
      const AlbumLegendCardEntry(
        cardData: CollectibleProRiderCardData(
          riderId: 'leg_szurkowski_73',
          fullName: 'Ryszard Kowalczyk',
          shortRoleLabel: 'PEACE TOUR ACE',
          nationalityIso: 'POL',
          teamName: 'Polonia Classic',
          teamShortCode: 'POL',
          ovr: 91,
          editionYear: 1973,
          cardSerialNumber: '07/50',
          stats: ProRiderCardStats(
            mon: 86,
            hil: 92,
            itt: 91,
            spr: 90,
            cob: 88,
            rec: 92,
          ),
          specialJersey: SpecialJerseyDesignation.rainbowJersey,
          primaryJerseyColorHex: '#DC2626',
          secondaryJerseyColorHex: '#F3F4F6',
          accentJerseyColorHex: '#D4AF37',
          customAutographText: 'R. Kowalczyk',
        ),
        era: LegendCardEra.goldenSeventies,
        teamGroup: 'Polonia Classic',
        unlockSource: CardUnlockSource.achievementMilestone,
        unlockRequirementText:
            'Osiągnięcie: Wygraj 10 etapów polskim zespołem w karierze',
        isUnlocked: false,
      ),

      // === EPOKA KLASYKÓW 80/90 ===
      AlbumLegendCardEntry(
        cardData: const CollectibleProRiderCardData(
          riderId: 'leg_hinault_85',
          fullName: 'Bernard Moreau',
          shortRoleLabel: 'THE BADGER',
          nationalityIso: 'FRA',
          teamName: 'La Vie Claire Heritage',
          teamShortCode: 'LVC',
          ovr: 95,
          editionYear: 1985,
          cardSerialNumber: '02/20',
          stats: ProRiderCardStats(
            mon: 94,
            hil: 94,
            itt: 96,
            spr: 88,
            cob: 87,
            rec: 96,
          ),
          grandTourWins: [
            GrandTourWinBadge(
              tour: GrandTourType.tourDeFrance,
              years: [1978, 1979, 1981, 1982, 1985],
            ),
            GrandTourWinBadge(
              tour: GrandTourType.giroDItalia,
              years: [1980, 1982, 1985],
            ),
          ],
          specialJersey:
              SpecialJerseyDesignation.formerWorldChampionRainbowBands,
          primaryJerseyColorHex: '#181B22',
          secondaryJerseyColorHex: '#D4AF37',
          accentJerseyColorHex: '#EF4444',
          customAutographText: 'B. Moreau',
        ),
        era: LegendCardEra.classicEightiesNineties,
        teamGroup: 'La Vie Claire Heritage',
        unlockSource: CardUnlockSource.worldTourVictory,
        unlockRequirementText:
            'Zwycięstwo WorldTour: Wygraj klasyfikację generalną Tour de France',
        isUnlocked: true,
        unlockedAt: DateTime(2026, 6, 18),
      ),
      const AlbumLegendCardEntry(
        cardData: CollectibleProRiderCardData(
          riderId: 'leg_indurain_93',
          fullName: 'Miguel Navarro',
          shortRoleLabel: 'CHRONO GIANT',
          nationalityIso: 'ESP',
          teamName: 'Banesto Classics',
          teamShortCode: 'BAN',
          ovr: 94,
          editionYear: 1993,
          cardSerialNumber: '03/25',
          stats: ProRiderCardStats(
            mon: 92,
            hil: 88,
            itt: 99,
            spr: 76,
            cob: 79,
            rec: 96,
          ),
          grandTourWins: [
            GrandTourWinBadge(
              tour: GrandTourType.tourDeFrance,
              years: [1991, 1992, 1993, 1994, 1995],
            ),
            GrandTourWinBadge(
              tour: GrandTourType.giroDItalia,
              years: [1992, 1993],
            ),
          ],
          primaryJerseyColorHex: '#2563EB',
          secondaryJerseyColorHex: '#F3F4F6',
          accentJerseyColorHex: '#EF4444',
          customAutographText: 'M. Navarro',
        ),
        era: LegendCardEra.classicEightiesNineties,
        teamGroup: 'Banesto Classics',
        unlockSource: CardUnlockSource.tacticalChallenge,
        unlockRequirementText:
            'Wyzwanie Taktyczne: Pokonaj rywali na 40 km ITT z przewagą >90 s',
        isUnlocked: false,
      ),
      const AlbumLegendCardEntry(
        cardData: CollectibleProRiderCardData(
          riderId: 'leg_pantani_98',
          fullName: 'Marco Bellini',
          shortRoleLabel: 'IL PIRATA',
          nationalityIso: 'ITA',
          teamName: 'Mercatone Heritage',
          teamShortCode: 'MER',
          ovr: 94,
          editionYear: 1998,
          cardSerialNumber: '05/20',
          stats: ProRiderCardStats(
            mon: 99,
            hil: 92,
            itt: 78,
            spr: 74,
            cob: 68,
            rec: 93,
          ),
          grandTourWins: [
            GrandTourWinBadge(
              tour: GrandTourType.tourDeFrance,
              years: [1998],
            ),
            GrandTourWinBadge(
              tour: GrandTourType.giroDItalia,
              years: [1998],
            ),
          ],
          primaryJerseyColorHex: '#EAB308',
          secondaryJerseyColorHex: '#38BDF8',
          accentJerseyColorHex: '#EC4899',
          customAutographText: 'M. Bellini',
        ),
        era: LegendCardEra.classicEightiesNineties,
        teamGroup: 'Mercatone Heritage',
        unlockSource: CardUnlockSource.championshipPack,
        unlockRequirementText:
            'Złota Paczka Mistrzowska lub dublet Giro–Tour w jednym sezonie',
        isUnlocked: false,
      ),

      // === NOWOCZESNE WIELKIE TOURY ===
      AlbumLegendCardEntry(
        cardData: const CollectibleProRiderCardData(
          riderId: 'leg_cancellara_10',
          fullName: 'Fabian Meier',
          shortRoleLabel: 'SPARTACUS',
          nationalityIso: 'SUI',
          teamName: 'Saxo Classics',
          teamShortCode: 'SAX',
          ovr: 92,
          editionYear: 2010,
          cardSerialNumber: '06/35',
          stats: ProRiderCardStats(
            mon: 75,
            hil: 91,
            itt: 98,
            spr: 86,
            cob: 98,
            rec: 90,
          ),
          specialJersey: SpecialJerseyDesignation.nationalChampionJersey,
          primaryJerseyColorHex: '#1E293B',
          secondaryJerseyColorHex: '#38BDF8',
          accentJerseyColorHex: '#D4AF37',
          customAutographText: 'F. Meier',
        ),
        era: LegendCardEra.modernGrandTours,
        teamGroup: 'Saxo Classics',
        unlockSource: CardUnlockSource.careerSigning,
        unlockRequirementText:
            'Kariera: Zatrudnij specjalistę bruków 90+ lub otwórz paczkę',
        isUnlocked: true,
        unlockedAt: DateTime(2026, 7, 2),
      ),
      const AlbumLegendCardEntry(
        cardData: CollectibleProRiderCardData(
          riderId: 'leg_sagan_16',
          fullName: 'Peter Kováč',
          shortRoleLabel: 'GREEN MACHINE',
          nationalityIso: 'SVK',
          teamName: 'Tinkoff Pro',
          teamShortCode: 'TNK',
          ovr: 91,
          editionYear: 2016,
          cardSerialNumber: '09/40',
          stats: ProRiderCardStats(
            mon: 74,
            hil: 93,
            itt: 80,
            spr: 96,
            cob: 94,
            rec: 91,
          ),
          specialJersey: SpecialJerseyDesignation.rainbowJersey,
          primaryJerseyColorHex: '#10B981',
          secondaryJerseyColorHex: '#EAB308',
          accentJerseyColorHex: '#181B22',
          customAutographText: 'P. Kovac',
        ),
        era: LegendCardEra.modernGrandTours,
        teamGroup: 'Tinkoff Pro',
        unlockSource: CardUnlockSource.achievementMilestone,
        unlockRequirementText:
            'Osiągnięcie: Zdobądź Zieloną Koszulkę Punktową Wielkiego Touru',
        isUnlocked: false,
      ),
      AlbumLegendCardEntry(
        cardData: const CollectibleProRiderCardData(
          riderId: 'leg_kwiatkowski_14',
          fullName: 'Michał Nowicki',
          shortRoleLabel: 'RAINBOW TACTICIAN',
          nationalityIso: 'POL',
          teamName: 'Ineos Grenadiers',
          teamShortCode: 'IGD',
          ovr: 88,
          editionYear: 2014,
          cardSerialNumber: '12/75',
          stats: ProRiderCardStats(
            mon: 85,
            hil: 91,
            itt: 88,
            spr: 84,
            cob: 84,
            rec: 89,
          ),
          specialJersey:
              SpecialJerseyDesignation.formerWorldChampionRainbowBands,
          primaryJerseyColorHex: '#8E4A49',
          secondaryJerseyColorHex: '#181B22',
          accentJerseyColorHex: '#F97316',
          customAutographText: 'M. Nowicki',
        ),
        era: LegendCardEra.modernGrandTours,
        teamGroup: 'Ineos Grenadiers',
        unlockSource: CardUnlockSource.careerSigning,
        unlockRequirementText:
            'Kariera: Wygraj Strade Bianche lub etap na Grand Colombier',
        isUnlocked: true,
        unlockedAt: DateTime(2026, 7, 15),
        isFavorite: true,
      ),
      const AlbumLegendCardEntry(
        cardData: CollectibleProRiderCardData(
          riderId: 'leg_froome_17',
          fullName: 'Chris Sterling',
          shortRoleLabel: 'GC DOMINATOR',
          nationalityIso: 'GBR',
          teamName: 'Sky / Ineos Heritage',
          teamShortCode: 'SKY',
          ovr: 92,
          editionYear: 2017,
          cardSerialNumber: '08/30',
          stats: ProRiderCardStats(
            mon: 96,
            hil: 86,
            itt: 94,
            spr: 72,
            cob: 75,
            rec: 95,
          ),
          grandTourWins: [
            GrandTourWinBadge(
              tour: GrandTourType.tourDeFrance,
              years: [2013, 2015, 2016, 2017],
            ),
            GrandTourWinBadge(
              tour: GrandTourType.giroDItalia,
              years: [2018],
            ),
            GrandTourWinBadge(
              tour: GrandTourType.vueltaAEspana,
              years: [2011, 2017],
            ),
          ],
          primaryJerseyColorHex: '#0F172A',
          secondaryJerseyColorHex: '#38BDF8',
          accentJerseyColorHex: '#F3F4F6',
          customAutographText: 'C. Sterling',
        ),
        era: LegendCardEra.modernGrandTours,
        teamGroup: 'Ineos Grenadiers',
        unlockSource: CardUnlockSource.championshipPack,
        unlockRequirementText:
            'Złota Paczka Mistrzowska po zwycięstwie w wyścigu WorldTour',
        isUnlocked: false,
      ),

      // === ERA WSPÓŁCZESNA WT ===
      AlbumLegendCardEntry(
        cardData: const CollectibleProRiderCardData(
          riderId: 'wt_pogacar_26',
          fullName: 'Tadej Kovačič',
          shortRoleLabel: 'ALL-ROUND PHENOM',
          nationalityIso: 'SLO',
          teamName: 'UAE Team Emirates',
          teamShortCode: 'UAD',
          ovr: 96,
          editionYear: 2026,
          cardSerialNumber: '01/99',
          stats: ProRiderCardStats(
            mon: 97,
            hil: 98,
            itt: 93,
            spr: 89,
            cob: 88,
            rec: 96,
          ),
          grandTourWins: [
            GrandTourWinBadge(
              tour: GrandTourType.tourDeFrance,
              years: [2020, 2021, 2024, 2025],
            ),
            GrandTourWinBadge(
              tour: GrandTourType.giroDItalia,
              years: [2024],
            ),
          ],
          specialJersey: SpecialJerseyDesignation.rainbowJersey,
          primaryJerseyColorHex: '#F3F4F6',
          secondaryJerseyColorHex: '#181B22',
          accentJerseyColorHex: '#EF4444',
          customAutographText: 'T. Kovacic',
        ),
        era: LegendCardEra.currentWorldTour,
        teamGroup: 'UAE Team Emirates',
        unlockSource: CardUnlockSource.worldTourVictory,
        unlockRequirementText:
            'Zwycięstwo WorldTour: Wygraj Monument lub Wielki Tour',
        isUnlocked: true,
        unlockedAt: DateTime(2026, 7, 25),
        isFavorite: true,
      ),
      const AlbumLegendCardEntry(
        cardData: CollectibleProRiderCardData(
          riderId: 'wt_vingegaard_26',
          fullName: 'Jonas Lindholm',
          shortRoleLabel: 'ALPINE KING',
          nationalityIso: 'DEN',
          teamName: 'Visma | Lease a Bike',
          teamShortCode: 'TVL',
          ovr: 94,
          editionYear: 2026,
          cardSerialNumber: '02/99',
          stats: ProRiderCardStats(
            mon: 98,
            hil: 90,
            itt: 94,
            spr: 75,
            cob: 76,
            rec: 97,
          ),
          grandTourWins: [
            GrandTourWinBadge(
              tour: GrandTourType.tourDeFrance,
              years: [2022, 2023],
            ),
          ],
          primaryJerseyColorHex: '#EAB308',
          secondaryJerseyColorHex: '#181B22',
          accentJerseyColorHex: '#F3F4F6',
          customAutographText: 'J. Lindholm',
        ),
        era: LegendCardEra.currentWorldTour,
        teamGroup: 'Visma | Lease a Bike',
        unlockSource: CardUnlockSource.championshipPack,
        unlockRequirementText:
            'Złota Paczka Mistrzowska po wygraniu wyścigu WorldTour',
        isUnlocked: false,
      ),
      const AlbumLegendCardEntry(
        cardData: CollectibleProRiderCardData(
          riderId: 'wt_van_der_poel_26',
          fullName: 'Mathieu Vermeer',
          shortRoleLabel: 'MONUMENT FLYER',
          nationalityIso: 'NED',
          teamName: 'Alpecin-Deceuninck',
          teamShortCode: 'ADC',
          ovr: 93,
          editionYear: 2026,
          cardSerialNumber: '03/99',
          stats: ProRiderCardStats(
            mon: 76,
            hil: 96,
            itt: 84,
            spr: 95,
            cob: 99,
            rec: 91,
          ),
          specialJersey:
              SpecialJerseyDesignation.formerWorldChampionRainbowBands,
          primaryJerseyColorHex: '#1D4ED8',
          secondaryJerseyColorHex: '#181B22',
          accentJerseyColorHex: '#F97316',
          customAutographText: 'M. Vermeer',
        ),
        era: LegendCardEra.currentWorldTour,
        teamGroup: 'Alpecin-Deceuninck',
        unlockSource: CardUnlockSource.championshipPack,
        unlockRequirementText:
            'Złota Paczka Mistrzowska lub zwycięstwo w Ronde van Vlaanderen',
        isUnlocked: false,
      ),
      const AlbumLegendCardEntry(
        cardData: CollectibleProRiderCardData(
          riderId: 'wt_evenepoel_26',
          fullName: 'Remco Peeters',
          shortRoleLabel: 'AERO BULLET',
          nationalityIso: 'BEL',
          teamName: 'Soudal Quick-Step',
          teamShortCode: 'SOQ',
          ovr: 92,
          editionYear: 2026,
          cardSerialNumber: '05/99',
          stats: ProRiderCardStats(
            mon: 92,
            hil: 93,
            itt: 98,
            spr: 81,
            cob: 80,
            rec: 90,
          ),
          grandTourWins: [
            GrandTourWinBadge(
              tour: GrandTourType.vueltaAEspana,
              years: [2022],
            ),
          ],
          specialJersey: SpecialJerseyDesignation.nationalChampionJersey,
          primaryJerseyColorHex: '#1E40AF',
          secondaryJerseyColorHex: '#F3F4F6',
          accentJerseyColorHex: '#D4AF37',
          customAutographText: 'R. Peeters',
        ),
        era: LegendCardEra.currentWorldTour,
        teamGroup: 'Soudal Quick-Step',
        unlockSource: CardUnlockSource.tacticalChallenge,
        unlockRequirementText:
            'Wyzwanie Taktyczne: Uciekaj samotnie przez ostatnie 45 km Liège',
        isUnlocked: false,
      ),
      const AlbumLegendCardEntry(
        cardData: CollectibleProRiderCardData(
          riderId: 'wt_van_aert_26',
          fullName: 'Wout Janssens',
          shortRoleLabel: 'SUPER DOMESTIQUE',
          nationalityIso: 'BEL',
          teamName: 'Visma | Lease a Bike',
          teamShortCode: 'TVL',
          ovr: 90,
          editionYear: 2026,
          cardSerialNumber: '08/99',
          stats: ProRiderCardStats(
            mon: 82,
            hil: 92,
            itt: 91,
            spr: 94,
            cob: 95,
            rec: 90,
          ),
          primaryJerseyColorHex: '#EAB308',
          secondaryJerseyColorHex: '#181B22',
          accentJerseyColorHex: '#38BDF8',
          customAutographText: 'W. Janssens',
        ),
        era: LegendCardEra.currentWorldTour,
        teamGroup: 'Visma | Lease a Bike',
        unlockSource: CardUnlockSource.championshipPack,
        unlockRequirementText:
            'Złota Paczka Mistrzowska lub wygrana na Mont Ventoux i Champs-Élysées',
        isUnlocked: false,
      ),
      AlbumLegendCardEntry(
        cardData: const CollectibleProRiderCardData(
          riderId: 'wt_majka_26',
          fullName: 'Rafał Górecki',
          shortRoleLabel: 'MOUNTAIN LIEUTENANT',
          nationalityIso: 'POL',
          teamName: 'UAE Team Emirates',
          teamShortCode: 'UAD',
          ovr: 85,
          editionYear: 2026,
          cardSerialNumber: '19/99',
          stats: ProRiderCardStats(
            mon: 89,
            hil: 83,
            itt: 74,
            spr: 68,
            cob: 65,
            rec: 88,
          ),
          primaryJerseyColorHex: '#F3F4F6',
          secondaryJerseyColorHex: '#EF4444',
          accentJerseyColorHex: '#181B22',
          customAutographText: 'R. Gorecki',
        ),
        era: LegendCardEra.currentWorldTour,
        teamGroup: 'UAE Team Emirates',
        unlockSource: CardUnlockSource.careerSigning,
        unlockRequirementText:
            'Kariera: Zdobądź koszulkę w grochy KOM na etapie górskim',
        isUnlocked: true,
        unlockedAt: DateTime(2026, 7, 19),
      ),
      const AlbumLegendCardEntry(
        cardData: CollectibleProRiderCardData(
          riderId: 'wt_kopecky_26',
          fullName: 'Lotte De Vries',
          shortRoleLabel: 'WORLD CHAMPION',
          nationalityIso: 'BEL',
          teamName: 'SD Worx-Protime',
          teamShortCode: 'SDW',
          ovr: 92,
          editionYear: 2026,
          cardSerialNumber: '04/99',
          stats: ProRiderCardStats(
            mon: 84,
            hil: 94,
            itt: 89,
            spr: 94,
            cob: 96,
            rec: 92,
          ),
          specialJersey: SpecialJerseyDesignation.rainbowJersey,
          primaryJerseyColorHex: '#8E4A49',
          secondaryJerseyColorHex: '#EC4899',
          accentJerseyColorHex: '#D4AF37',
          customAutographText: 'L. De Vries',
        ),
        era: LegendCardEra.currentWorldTour,
        teamGroup: 'SD Worx-Protime',
        unlockSource: CardUnlockSource.achievementMilestone,
        unlockRequirementText:
            'Osiągnięcie: Zdobądź 5000 pkt UCI w jednym sezonie',
        isUnlocked: false,
      ),
      const AlbumLegendCardEntry(
        cardData: CollectibleProRiderCardData(
          riderId: 'wt_milan_26',
          fullName: 'Jonathan Rossi',
          shortRoleLabel: 'WATT TRAIN',
          nationalityIso: 'ITA',
          teamName: 'Lidl-Trek',
          teamShortCode: 'LTK',
          ovr: 87,
          editionYear: 2026,
          cardSerialNumber: '14/99',
          stats: ProRiderCardStats(
            mon: 64,
            hil: 76,
            itt: 84,
            spr: 96,
            cob: 82,
            rec: 85,
          ),
          primaryJerseyColorHex: '#1D4ED8',
          secondaryJerseyColorHex: '#EF4444',
          accentJerseyColorHex: '#EAB308',
          customAutographText: 'J. Rossi',
        ),
        era: LegendCardEra.currentWorldTour,
        teamGroup: 'Lidl-Trek',
        unlockSource: CardUnlockSource.championshipPack,
        unlockRequirementText:
            'Złota Paczka Mistrzowska lub wygrana 3 sprintów masowych w WT',
        isUnlocked: false,
      ),
    ];
  }

  static List<PendingChampionshipPack> buildDefaultPendingPacks() {
    return [
      PendingChampionshipPack(
        packId: 'wt-pack-2026-tdf',
        title: 'Złota Paczka Mistrzowska',
        originRaceName: 'Zwycięstwo: Tour de France — Klasyfikacja Generalna',
        tier: ChampionshipPackTier.worldTourGoldPack,
        cardCount: 3,
        awardedAt: DateTime(2026, 7, 26),
      ),
    ];
  }
}

/// Kontroler stanu Albumu Kart i Paczek Mistrzowskich (Riverpod).
class LegendsCardAlbumNotifier extends StateNotifier<LegendsCardAlbumState> {
  final math.Random _random;

  LegendsCardAlbumNotifier({
    LegendsCardAlbumState? initialState,
    math.Random? random,
  })  : _random = random ?? math.Random(2026),
        super(
          initialState ??
              LegendsCardAlbumState(
                entries: LegendsAlbumCatalog.buildDefaultEntries(),
                pendingPacks: LegendsAlbumCatalog.buildDefaultPendingPacks(),
                selectedRiderId:
                    LegendsAlbumCatalog.buildDefaultEntries().first.riderId,
              ),
        );

  void setGroupingMode(LegendsAlbumGroupingMode mode) {
    state = state.copyWith(groupingMode: mode);
  }

  void setFilterMode(LegendsAlbumFilterMode mode) {
    state = state.copyWith(filterMode: mode);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  LegendsCardAlbumState get currentState => state;

  void selectRider(String riderId) {
    state = state.copyWith(selectedRiderId: riderId);
  }

  void toggleFavorite(String riderId) {
    final updated = state.entries.map((entry) {
      if (entry.riderId != riderId) return entry;
      return entry.copyWith(isFavorite: !entry.isFavorite);
    }).toList(growable: false);
    state = state.copyWith(entries: updated);
  }

  /// Przyznaje nową Złotą Paczkę Mistrzowską po wygraniu wyścigu WorldTour.
  PendingChampionshipPack awardWorldTourVictoryPack({
    required String raceName,
    ChampionshipPackTier tier = ChampionshipPackTier.worldTourGoldPack,
    int cardCount = 3,
  }) {
    final pack = PendingChampionshipPack(
      packId: 'wt-pack-${DateTime.now().microsecondsSinceEpoch}',
      title: tier.label,
      originRaceName: 'Zwycięstwo WorldTour: $raceName',
      tier: tier,
      cardCount: cardCount,
      awardedAt: DateTime.now(),
    );
    state = state.copyWith(
      pendingPacks: [pack, ...state.pendingPacks],
      worldTourWinsCount: state.worldTourWinsCount + 1,
    );
    return pack;
  }

  /// Bezpośrednio odblokowuje kartę (np. z osiągnięcia, wyzwania taktycznego lub transferu w karierze).
  void unlockCardDirectly(
    String riderId, {
    CardUnlockSource? sourceOverride,
  }) {
    final now = DateTime.now();
    final updated = state.entries.map((entry) {
      if (entry.riderId != riderId) return entry;
      if (entry.isUnlocked) {
        return entry.copyWith(duplicateCount: entry.duplicateCount + 1);
      }
      return entry.copyWith(
        isUnlocked: true,
        unlockedAt: now,
        unlockSource: sourceOverride ?? entry.unlockSource,
      );
    }).toList(growable: false);
    state = state.copyWith(entries: updated, selectedRiderId: riderId);
  }

  /// Otwiera paczkę, losuje karty (priorytetowo nieodblokowane + gwarantowany wysoki OVR)
  /// i aktualizuje stan albumu.
  PackOpenResult openPack(String packId) {
    final packIndex = state.pendingPacks.indexWhere((p) => p.packId == packId);
    if (packIndex == -1) {
      throw StateError('Pack not found: $packId');
    }
    final pack = state.pendingPacks[packIndex];
    final lockedPool = state.entries
        .where((e) => !e.isUnlocked)
        .toList(growable: true);
    final unlockedPool = state.entries
        .where((e) => e.isUnlocked)
        .toList(growable: true);

    lockedPool.shuffle(_random);
    unlockedPool.shuffle(_random);

    final pulls = <OpenedPackPullItem>[];
    final pulledIds = <String>{};

    // 1. Gwarantowana karta spełniająca próg OVR paczki (najpierw z nieodblokowanych).
    final highTierLockedIdx = lockedPool.indexWhere(
      (e) => e.cardData.ovr >= pack.tier.guaranteedMinOvr,
    );
    if (highTierLockedIdx != -1) {
      final pick = lockedPool.removeAt(highTierLockedIdx);
      pulledIds.add(pick.riderId);
      pulls.add(OpenedPackPullItem(entry: pick, isNewUnlock: true));
    }

    // 2. Dopełnij pozostałe sloty paczki najpierw nowymi kartami, potem duplikatami.
    while (pulls.length < pack.cardCount && lockedPool.isNotEmpty) {
      final pick = lockedPool.removeAt(0);
      if (pulledIds.add(pick.riderId)) {
        pulls.add(OpenedPackPullItem(entry: pick, isNewUnlock: true));
      }
    }

    while (pulls.length < pack.cardCount && unlockedPool.isNotEmpty) {
      final pick = unlockedPool.removeAt(0);
      if (pulledIds.add(pick.riderId)) {
        pulls.add(OpenedPackPullItem(entry: pick, isNewUnlock: false));
      }
    }

    final now = DateTime.now();
    final updatedEntries = state.entries.map((entry) {
      final matched = pulls.where((p) => p.entry.riderId == entry.riderId);
      if (matched.isEmpty) return entry;
      final item = matched.first;
      if (item.isNewUnlock) {
        return entry.copyWith(isUnlocked: true, unlockedAt: now);
      }
      return entry.copyWith(duplicateCount: entry.duplicateCount + 1);
    }).toList(growable: false);

    final updatedPacks = [
      for (int i = 0; i < state.pendingPacks.length; i++)
        if (i == packIndex)
          state.pendingPacks[i].copyWith(isOpened: true)
        else
          state.pendingPacks[i],
    ];

    final refreshedPulls = pulls.map((p) {
      final updated = updatedEntries.firstWhere(
        (e) => e.riderId == p.entry.riderId,
      );
      return OpenedPackPullItem(entry: updated, isNewUnlock: p.isNewUnlock);
    }).toList(growable: false);

    state = state.copyWith(
      entries: updatedEntries,
      pendingPacks: updatedPacks,
      selectedRiderId:
          refreshedPulls.isNotEmpty ? refreshedPulls.first.entry.riderId : null,
    );

    return PackOpenResult(
      pack: pack.copyWith(isOpened: true),
      pulledCards: refreshedPulls,
    );
  }
}

final legendsCardAlbumProvider =
    StateNotifierProvider<LegendsCardAlbumNotifier, LegendsCardAlbumState>(
  (ref) => LegendsCardAlbumNotifier(),
);

/// Główny ekran Albumu Kart i Kolekcji Gwiazd (`LegendsCardAlbumAndPacksScreen`).
class LegendsCardAlbumAndPacksScreen extends StatefulWidget {
  /// Opcjonalny stan początkowy (używany w testach lub przy przekazaniu stanu kariery).
  final LegendsCardAlbumState? initialState;

  /// Czy włączyć subtelny połysk holograficzny na kartach w spoczynku.
  final bool enableAmbientShimmer;

  /// Opcjonalny callback powrotu do poprzedniego ekranu.
  final VoidCallback? onBack;

  /// Opcjonalny callback przejścia do Wyzwań Taktycznych.
  final VoidCallback? onNavigateToTacticalChallenges;

  const LegendsCardAlbumAndPacksScreen({
    super.key,
    this.initialState,
    this.enableAmbientShimmer = true,
    this.onBack,
    this.onNavigateToTacticalChallenges,
  });

  @override
  State<LegendsCardAlbumAndPacksScreen> createState() =>
      _LegendsCardAlbumAndPacksScreenState();
}

class _LegendsCardAlbumAndPacksScreenState
    extends State<LegendsCardAlbumAndPacksScreen>
    with SingleTickerProviderStateMixin {
  late LegendsCardAlbumNotifier _notifier;
  late final RemoveListener _removeListener;
  late TextEditingController _searchController;
  late AnimationController _packAnimController;

  bool _searchFocused = false;
  PackOpenResult? _activePackOpening;

  @override
  void initState() {
    super.initState();
    _notifier = LegendsCardAlbumNotifier(initialState: widget.initialState);
    _removeListener = _notifier.addListener(_onStateChanged);
    _searchController = TextEditingController(
      text: _notifier.currentState.searchQuery,
    );
    _packAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    );
  }

  void _onStateChanged(LegendsCardAlbumState _) {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _removeListener();
    _notifier.dispose();
    _searchController.dispose();
    _packAnimController.dispose();
    super.dispose();
  }

  void _triggerOpenPack(PendingChampionshipPack pack) {
    final result = _notifier.openPack(pack.packId);
    setState(() {
      _activePackOpening = result;
    });
    _packAnimController.forward(from: 0.0);
  }

  void _skipPackAnimation() {
    _packAnimController.value = 1.0;
  }

  void _closePackOpeningModal() {
    setState(() {
      _activePackOpening = null;
    });
  }

  void _awardDemoWorldTourPack() {
    final pack = _notifier.awardWorldTourVictoryPack(
      raceName: 'Paris-Roubaix WorldTour',
    );
    _triggerOpenPack(pack);
  }

  void _showMobileInspectorSheet(AlbumLegendCardEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: _CardInspectorPanel(
                entry: entry,
                enableAmbientShimmer: widget.enableAmbientShimmer,
                onToggleFavorite: () {
                  _notifier.toggleFavorite(entry.riderId);
                  Navigator.of(ctx).pop();
                },
                onClose: () => Navigator.of(ctx).pop(),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _notifier.currentState;
    final filtered = state.filteredEntries;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'Inter',
              bodyColor: AppColors.textPrimary,
              displayColor: AppColors.textPrimary,
            ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final isMobile = width < 640;
                  final isDesktop = width >= 1200;

                  return Column(
                    children: [
                      _buildTopHeader(state, isMobile),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.all(isMobile ? 12 : 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildPendingPacksBanner(state, isMobile),
                                    const SizedBox(height: 16),
                                    _buildFilterAndGroupingToolbar(
                                      state,
                                      isMobile,
                                    ),
                                    const SizedBox(height: 20),
                                    if (filtered.isEmpty)
                                      _buildEmptyState()
                                    else
                                      _buildGroupedAlbumSections(
                                        state: state,
                                        entries: filtered,
                                        availableWidth: isDesktop
                                            ? width - 380
                                            : width,
                                        isMobile: isMobile,
                                        isDesktop: isDesktop,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (isDesktop && state.selectedEntry != null)
                              Container(
                                width: 356,
                                margin: const EdgeInsets.only(
                                  top: 20,
                                  right: 20,
                                  bottom: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.cardBorder,
                                    width: 1,
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(18),
                                  child: _CardInspectorPanel(
                                    entry: state.selectedEntry!,
                                    enableAmbientShimmer:
                                        widget.enableAmbientShimmer,
                                    onToggleFavorite: () =>
                                        _notifier.toggleFavorite(
                                      state.selectedEntry!.riderId,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (_activePackOpening != null)
                _GoldenPackOpeningOverlay(
                  result: _activePackOpening!,
                  animation: _packAnimController,
                  enableAmbientShimmer: widget.enableAmbientShimmer,
                  onSkipAnimation: _skipPackAnimation,
                  onCollectAndClose: _closePackOpeningModal,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(LegendsCardAlbumState state, bool isMobile) {
    final progressWidget = _CollectionProgressBadge(
      unlocked: state.unlockedCards,
      total: state.totalCards,
      percent: state.completionPercent,
      goldCount: state.goldLegendsUnlocked,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (widget.onBack != null || Navigator.of(context).canPop())
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _InteractiveActionButton(
                          icon: Icons.arrow_back_rounded,
                          label: 'Wróć',
                          compact: true,
                          onPressed: widget.onBack ??
                              () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ALBUM KART I GWIAZD',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Legendy epok i gwiazdy WorldTour',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                progressWidget,
              ],
            )
          : Row(
              children: [
                if (widget.onBack != null || Navigator.of(context).canPop())
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _InteractiveActionButton(
                      icon: Icons.arrow_back_rounded,
                      label: 'Powrót',
                      onPressed: widget.onBack ??
                          () => Navigator.of(context).maybePop(),
                    ),
                  ),
                const Icon(
                  Icons.style_rounded,
                  color: AppColors.goldAccent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ALBUM KART I KOLEKCJA GWIAZD',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Zdobywaj kolarzy w karierze, za osiągnięcia, wyzwania taktyczne i Złote Paczki Mistrzowskie',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                progressWidget,
              ],
            ),
    );
  }

  Widget _buildPendingPacksBanner(LegendsCardAlbumState state, bool isMobile) {
    final unopened = state.unopenedPacks;
    final hasPack = unopened.isNotEmpty;
    final topPack = hasPack ? unopened.first : null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasPack ? AppColors.goldAccent : AppColors.cardBorder,
          width: 1,
        ),
        gradient: hasPack
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.goldAccent.withValues(alpha: 0.14),
                  AppColors.surface,
                  AppColors.primaryAccent.withValues(alpha: 0.10),
                ],
              )
            : null,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPackBannerInfo(unopened, topPack),
                const SizedBox(height: 12),
                _buildPackBannerActions(hasPack, topPack),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildPackBannerInfo(unopened, topPack)),
                const SizedBox(width: 16),
                _buildPackBannerActions(hasPack, topPack),
              ],
            ),
    );
  }

  Widget _buildPackBannerInfo(
    List<PendingChampionshipPack> unopened,
    PendingChampionshipPack? topPack,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: topPack != null
                ? AppColors.goldAccent.withValues(alpha: 0.18)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: topPack != null
                  ? AppColors.goldAccent
                  : AppColors.cardBorder,
              width: 1,
            ),
          ),
          child: Icon(
            topPack != null
                ? Icons.auto_awesome_rounded
                : Icons.lock_clock_outlined,
            color: topPack != null
                ? AppColors.goldAccent
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      topPack != null
                          ? '${topPack.title} (${unopened.length} do otwarcia)'
                          : 'Brak oczekujących Paczek Mistrzowskich',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: topPack != null
                            ? AppColors.goldAccent
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                topPack != null
                    ? '${topPack.originRaceName} • ${topPack.cardCount} karty w tym gwarantowana gwiazda OVR ${topPack.tier.guaranteedMinOvr}+'
                    : 'Wygraj kolejny wyścig WorldTour w karierze lub zdobądź złoto w Wyzwaniu Taktycznym, aby odebrać Złotą Paczkę Mistrzowską.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackBannerActions(
    bool hasPack,
    PendingChampionshipPack? topPack,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _InteractiveActionButton(
          key: const ValueKey('open_golden_pack_button'),
          icon: Icons.card_giftcard_rounded,
          label: hasPack ? 'Otwórz Złotą Paczkę' : 'Brak Paczek',
          isPrimaryGold: hasPack,
          enabled: hasPack,
          onPressed: topPack != null ? () => _triggerOpenPack(topPack) : null,
        ),
        _InteractiveActionButton(
          key: const ValueKey('simulate_wt_pack_button'),
          icon: Icons.emoji_events_outlined,
          label: 'Symuluj Zwycięstwo WT',
          onPressed: _awardDemoWorldTourPack,
        ),
        if (widget.onNavigateToTacticalChallenges != null)
          _InteractiveActionButton(
            icon: Icons.psychology_outlined,
            label: 'Wyzwania Taktyczne',
            onPressed: widget.onNavigateToTacticalChallenges,
          ),
      ],
    );
  }

  Widget _buildFilterAndGroupingToolbar(
    LegendsCardAlbumState state,
    bool isMobile,
  ) {
    final groupingToggle = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: LegendsAlbumGroupingMode.values.map((mode) {
          final isSelected = state.groupingMode == mode;
          return _InteractiveChipButton(
            key: ValueKey('grouping_${mode.name}'),
            label: mode.label,
            icon: mode == LegendsAlbumGroupingMode.byEra
                ? Icons.history_edu_rounded
                : Icons.groups_rounded,
            selected: isSelected,
            onTap: () => _notifier.setGroupingMode(mode),
          );
        }).toList(),
      ),
    );

    final searchBox = Focus(
      onFocusChange: (focused) => setState(() => _searchFocused = focused),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                _searchFocused ? AppColors.goldAccent : AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _notifier.setSearchQuery,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Szukaj kolarza, drużyny lub epoki...',
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
            suffixIcon: state.searchQuery.isNotEmpty
                ? IconButton(
                    tooltip: 'Wyczyść wyszukiwanie',
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _notifier.setSearchQuery('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            groupingToggle,
            SizedBox(
              width: isMobile ? double.infinity : 300,
              child: searchBox,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LegendsAlbumFilterMode.values.map((filter) {
            return _InteractiveChipButton(
              key: ValueKey('filter_${filter.name}'),
              label: filter.label,
              selected: state.filterMode == filter,
              onTap: () => _notifier.setFilterMode(filter),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.style_outlined,
            size: 42,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Brak kart spełniających wybrane kryteria',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Zmień filtr albumu lub wyczyść wyszukiwanie, aby zobaczyć wszystkie legendy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _InteractiveActionButton(
            icon: Icons.refresh_rounded,
            label: 'Pokaż Wszystkie Karty',
            onPressed: () {
              _searchController.clear();
              _notifier.setSearchQuery('');
              _notifier.setFilterMode(LegendsAlbumFilterMode.all);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedAlbumSections({
    required LegendsCardAlbumState state,
    required List<AlbumLegendCardEntry> entries,
    required double availableWidth,
    required bool isMobile,
    required bool isDesktop,
  }) {
    final Map<String, List<AlbumLegendCardEntry>> grouped = {};
    final Map<String, ({String subtitle, Color accent})> meta = {};

    if (state.groupingMode == LegendsAlbumGroupingMode.byEra) {
      for (final era in LegendCardEra.values) {
        final list = entries.where((e) => e.era == era).toList();
        if (list.isNotEmpty) {
          grouped['${era.label} (${era.yearRange})'] = list;
          meta['${era.label} (${era.yearRange})'] = (
            subtitle: era.description,
            accent: era.accentColor,
          );
        }
      }
    } else {
      for (final entry in entries) {
        grouped.putIfAbsent(entry.teamGroup, () => []).add(entry);
        meta.putIfAbsent(
          entry.teamGroup,
          () => (
            subtitle: 'Drużyna i dziedzictwo kolekcjonerskie',
            accent: AppColors.primaryAccent,
          ),
        );
      }
    }

    int columns = 1;
    if (availableWidth >= 1150) {
      columns = 3;
    } else if (availableWidth >= 600) {
      columns = 2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((section) {
        final sectionMeta = meta[section.key]!;
        final unlockedInGroup =
            section.value.where((e) => e.isUnlocked).length;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 28,
                      decoration: BoxDecoration(
                        color: sectionMeta.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.key,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            sectionMeta.subtitle,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.cardBorder,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$unlockedInGroup/${section.value.length}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: AppColors.goldAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: section.value.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isMobile ? 0.72 : 0.68,
                ),
                itemBuilder: (context, index) {
                  final entry = section.value[index];
                  final isSelected = state.selectedRiderId == entry.riderId;
                  return _AlbumCardSlotTile(
                    key: ValueKey('album_slot_${entry.riderId}'),
                    entry: entry,
                    isSelected: isSelected,
                    enableAmbientShimmer: widget.enableAmbientShimmer,
                    onTap: () {
                      _notifier.selectRider(entry.riderId);
                      if (!isDesktop) {
                        _showMobileInspectorSheet(entry);
                      }
                    },
                    onToggleFavorite: () =>
                        _notifier.toggleFavorite(entry.riderId),
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Wskaźnik postępu kolekcji w nagłówku.
class _CollectionProgressBadge extends StatelessWidget {
  final int unlocked;
  final int total;
  final int percent;
  final int goldCount;

  const _CollectionProgressBadge({
    required this.unlocked,
    required this.total,
    required this.percent,
    required this.goldCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'KOLEKCJA: $unlocked/$total ($percent%)',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 150,
                height: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : unlocked / total,
                    backgroundColor: AppColors.background,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.goldAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Text(
              '★ $goldCount Złote',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.goldAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kafelek pojedynczego slotu karty w siatce albumu (odblokowana lub zablokowana).
class _AlbumCardSlotTile extends StatefulWidget {
  final AlbumLegendCardEntry entry;
  final bool isSelected;
  final bool enableAmbientShimmer;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _AlbumCardSlotTile({
    super.key,
    required this.entry,
    required this.isSelected,
    required this.enableAmbientShimmer,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  State<_AlbumCardSlotTile> createState() => _AlbumCardSlotTileState();
}

class _AlbumCardSlotTileState extends State<_AlbumCardSlotTile> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final borderColor = widget.isSelected || _focused
        ? AppColors.goldAccent
        : _hovered
            ? AppColors.textSecondary
            : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : (_hovered ? 1.015 : 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceLight : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: entry.era.accentColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${entry.cardData.editionYear}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: entry.era.accentColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (entry.duplicateCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'x${entry.duplicateCount + 1}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentBlue,
                            ),
                          ),
                        ),
                      ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      tooltip: entry.isFavorite
                          ? 'Usuń z ulubionych'
                          : 'Dodaj do ulubionych',
                      icon: Icon(
                        entry.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 18,
                        color: entry.isFavorite
                            ? AppColors.goldAccent
                            : AppColors.textSecondary,
                      ),
                      onPressed: widget.onToggleFavorite,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: entry.isUnlocked
                      ? Center(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: CollectibleProRiderHoloCard(
                              data: entry.cardData,
                              isSelected: widget.isSelected,
                              maxWidth: 250,
                              enableAmbientShimmer: widget.enableAmbientShimmer,
                              onTap: widget.onTap,
                            ),
                          ),
                        )
                      : _LockedCardSilhouette(entry: entry),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      entry.unlockSource.icon,
                      size: 13,
                      color: entry.isUnlocked
                          ? AppColors.statusSuccess
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        entry.isUnlocked
                            ? entry.unlockSource.label
                            : entry.unlockRequirementText,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: entry.isUnlocked
                              ? AppColors.statusSuccess
                              : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sylwetka nieodblokowanej karty w albumie.
class _LockedCardSilhouette extends StatelessWidget {
  final AlbumLegendCardEntry entry;

  const _LockedCardSilhouette({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceLight,
              border: Border.all(
                color: entry.cardData.isGoldLegend
                    ? AppColors.goldAccent.withValues(alpha: 0.45)
                    : AppColors.cardBorder,
              ),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: entry.cardData.isGoldLegend
                  ? AppColors.goldAccent
                  : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            entry.cardData.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${entry.teamGroup} • OVR ${entry.cardData.ovr}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: Text(
              entry.cardData.tier.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: entry.cardData.isGoldLegend
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prawy panel inspektora wybranej karty (Desktop) lub modal szczegółów (Mobile/Tablet).
class _CardInspectorPanel extends StatelessWidget {
  final AlbumLegendCardEntry entry;
  final bool enableAmbientShimmer;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onClose;

  const _CardInspectorPanel({
    required this.entry,
    required this.enableAmbientShimmer,
    required this.onToggleFavorite,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome_mosaic_rounded,
              size: 18,
              color: AppColors.goldAccent,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'INSPEKTOR KARTY',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (onClose != null)
              IconButton(
                tooltip: 'Zamknij podgląd',
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                ),
                onPressed: onClose,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: CollectibleProRiderHoloCard(
            data: entry.cardData,
            enabled: entry.isUnlocked,
            maxWidth: 280,
            enableAmbientShimmer: enableAmbientShimmer && entry.isUnlocked,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InspectorInfoRow(label: 'Epoka', value: entry.era.label),
              const SizedBox(height: 6),
              _InspectorInfoRow(label: 'Drużyna', value: entry.teamGroup),
              const SizedBox(height: 6),
              _InspectorInfoRow(
                label: 'Źródło',
                value: entry.unlockSource.label,
              ),
              const SizedBox(height: 6),
              _InspectorInfoRow(
                label: 'Status',
                value: entry.isUnlocked ? 'Odblokowana' : 'Zablokowana',
                valueColor: entry.isUnlocked
                    ? AppColors.statusSuccess
                    : AppColors.amberWarning,
              ),
              const SizedBox(height: 10),
              Text(
                entry.unlockRequirementText,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _InteractiveActionButton(
            icon: entry.isFavorite
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            label: entry.isFavorite
                ? 'Usuń z Ulubionych'
                : 'Dodaj do Ulubionych',
            isPrimaryGold: entry.isFavorite,
            onPressed: onToggleFavorite,
          ),
        ),
      ],
    );
  }
}

class _InspectorInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InspectorInfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Nakładka animowanego otwierania Złotej Paczki Mistrzowskiej.
class _GoldenPackOpeningOverlay extends StatelessWidget {
  final PackOpenResult result;
  final Animation<double> animation;
  final bool enableAmbientShimmer;
  final VoidCallback onSkipAnimation;
  final VoidCallback onCollectAndClose;

  const _GoldenPackOpeningOverlay({
    required this.result,
    required this.animation,
    required this.enableAmbientShimmer,
    required this.onSkipAnimation,
    required this.onCollectAndClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.86),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = animation.value;
            final showPack = t < 0.55;
            final burstAlpha = t >= 0.32 && t <= 0.72
                ? math.sin(((t - 0.32) / 0.40) * math.pi)
                : 0.0;
            final cardsProgress = ((t - 0.50) / 0.50).clamp(0.0, 1.0);
            final isComplete = t >= 0.98;

            return LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 700;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (burstAlpha > 0.01)
                      CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _GoldenPackBurstPainter(
                          intensity: burstAlpha,
                          color: result.pack.tier.accentColor,
                        ),
                      ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            result.pack.title.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.goldAccent,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            result.pack.originRaceName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (showPack)
                            Transform.scale(
                              scale: 1.0 + (t * 0.25),
                              child: Transform.rotate(
                                angle: math.sin(t * 28) * 0.05 * t,
                                child: CustomPaint(
                                  size: const Size(210, 290),
                                  painter: _GoldenChampionshipPackPainter(
                                    tearProgress:
                                        ((t - 0.25) / 0.30).clamp(0.0, 1.0),
                                    accentColor: result.pack.tier.accentColor,
                                  ),
                                ),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: List.generate(
                                result.pulledCards.length,
                                (index) {
                                  final item = result.pulledCards[index];
                                  final staggered =
                                      ((cardsProgress - (index * 0.14)) / 0.72)
                                          .clamp(0.0, 1.0);
                                  final curved =
                                      Curves.easeOutCubic.transform(staggered);
                                  return Opacity(
                                    opacity: curved,
                                    child: Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.001)
                                        ..rotateY((1.0 - curved) * math.pi * 0.5),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: item.isNewUnlock
                                                  ? AppColors.goldAccent
                                                  : AppColors.accentBlue,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              item.isNewUnlock
                                                  ? 'NOWA KARTA!'
                                                  : 'DUPLIKAT +1',
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.background,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          CollectibleProRiderHoloCard(
                                            data: item.entry.cardData,
                                            maxWidth: isCompact ? 220 : 240,
                                            enableAmbientShimmer:
                                                enableAmbientShimmer,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              if (!isComplete)
                                _InteractiveActionButton(
                                  icon: Icons.fast_forward_rounded,
                                  label: 'Odkryj Natychmiast',
                                  onPressed: onSkipAnimation,
                                ),
                              _InteractiveActionButton(
                                key: const ValueKey('collect_pack_cards_button'),
                                icon: Icons.check_circle_outline_rounded,
                                label: 'Dodaj do Albumu',
                                isPrimaryGold: true,
                                onPressed: onCollectAndClose,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Rysuje zapieczętowaną Złotą Paczkę Mistrzowską przed rozdarciem folii.
class _GoldenChampionshipPackPainter extends CustomPainter {
  final double tearProgress;
  final Color accentColor;

  _GoldenChampionshipPackPainter({
    required this.tearProgress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(18));

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentColor,
          const Color(0xFF9A7B2C),
          const Color(0xFF181B22),
          accentColor.withValues(alpha: 0.9),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, bgPaint);

    // Paski mistrzowskie w połowie paczki
    final stripeColors = [
      const Color(0xFF38BDF8),
      const Color(0xFFEF4444),
      const Color(0xFF181B22),
      const Color(0xFFEAB308),
      const Color(0xFF10B981),
    ];
    final stripeTop = size.height * 0.56;
    for (int i = 0; i < stripeColors.length; i++) {
      final stripePaint = Paint()..color = stripeColors[i];
      canvas.drawRect(
        Rect.fromLTWH(0, stripeTop + i * 5.0, size.width, 4.0),
        stripePaint,
      );
    }

    // Złote obramowanie
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(rrect, borderPaint);

    // Linia rozdarcia folii
    if (tearProgress > 0) {
      final tearY = size.height * 0.18;
      final tearPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 3.0;
      canvas.drawLine(
        Offset(10, tearY),
        Offset(10 + (size.width - 20) * tearProgress, tearY),
        tearPaint,
      );
    }

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'WT\nCHAMPION\nPACK',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: AppColors.background,
          height: 1.15,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 24);
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        size.height * 0.28,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _GoldenChampionshipPackPainter oldDelegate) {
    return oldDelegate.tearProgress != tearProgress ||
        oldDelegate.accentColor != accentColor;
  }
}

/// Rysuje promienie złotego światła podczas otwierania paczki.
class _GoldenPackBurstPainter extends CustomPainter {
  final double intensity;
  final Color color;

  _GoldenPackBurstPainter({
    required this.intensity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.max(size.width, size.height) * 0.65;
    final rayPaint = Paint()
      ..color = color.withValues(alpha: 0.25 * intensity)
      ..style = PaintingStyle.fill;

    const rayCount = 12;
    for (int i = 0; i < rayCount; i++) {
      final baseAngle = (i / rayCount) * 2 * math.pi;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + math.cos(baseAngle - 0.08) * maxRadius,
          center.dy + math.sin(baseAngle - 0.08) * maxRadius,
        )
        ..lineTo(
          center.dx + math.cos(baseAngle + 0.08) * maxRadius,
          center.dy + math.sin(baseAngle + 0.08) * maxRadius,
        )
        ..close();
      canvas.drawPath(path, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GoldenPackBurstPainter oldDelegate) {
    return oldDelegate.intensity != intensity || oldDelegate.color != color;
  }
}

/// Przycisk z pełną obsługą stanów hover, active, focus i disabled.
class _InteractiveActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimaryGold;
  final bool enabled;
  final bool compact;

  const _InteractiveActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimaryGold = false,
    this.enabled = true,
    this.compact = false,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled && widget.onPressed != null;

    final Color bgColor;
    final Color fgColor;
    final Color borderColor;

    if (!isEnabled) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.5);
      fgColor = AppColors.textSecondary.withValues(alpha: 0.5);
      borderColor = AppColors.cardBorder.withValues(alpha: 0.5);
    } else if (widget.isPrimaryGold) {
      bgColor = _hovered
          ? AppColors.goldAccent.withValues(alpha: 0.9)
          : AppColors.goldAccent;
      fgColor = AppColors.background;
      borderColor = _focused ? Colors.white : AppColors.goldAccent;
    } else {
      bgColor = _hovered ? AppColors.surfaceLight : AppColors.surface;
      fgColor = AppColors.textPrimary;
      borderColor = _focused
          ? AppColors.goldAccent
          : (_hovered ? AppColors.textSecondary : AppColors.cardBorder);
    }

    return FocusableActionDetector(
      enabled: isEnabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (isEnabled) widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _pressed = false) : null,
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 14,
              vertical: widget.compact ? 7 : 10,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 17, color: fgColor),
                const SizedBox(width: 7),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: widget.compact ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
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

/// Chip filtrujący / przełączający z obsługą hover, focus i active.
class _InteractiveChipButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _InteractiveChipButton({
    super.key,
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_InteractiveChipButton> createState() => _InteractiveChipButtonState();
}

class _InteractiveChipButtonState extends State<_InteractiveChipButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? AppColors.primaryAccent
        : (_hovered ? AppColors.surfaceLight : AppColors.surface);
    final borderColor = _focused
        ? AppColors.goldAccent
        : (widget.selected ? AppColors.goldAccent : AppColors.cardBorder);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 15,
                  color: widget.selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight:
                      widget.selected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
