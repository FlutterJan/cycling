import 'dart:math' as math;
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';

/// Pojedynczy odcinek składowy (pitch / rampa) w profilu podjazdu lub sektora.
///
/// Pozwala na realistyczne odwzorowanie zmian nachylenia (np. strome pierwsze 2 km
/// Alpe d'Huez o nachyleniu 10.5% vs płaskowyż na szczycie 5%), co z kolei
/// aktywuje taktyczne ataki górali w silniku wyścigu (`MountainGcAiController`).
class ClimbPitch {
  /// Długość tego fragmentu w kilometrach [km]
  final double lengthKm;

  /// Średnie nachylenie rampy w procentach [%] (dodatnie = podjazd, ujemne = wypłaszczenie/zjazd)
  final double gradientPercent;

  /// Rodzaj nawierzchni na tym odcinku
  final SegmentSurfaceType surfaceType;

  /// Trudność techniczna (1.0 - 100.0)
  final double technicalDifficulty;

  /// Ewentualna klasyfikacja górska lub premia na tym odcinku
  final SegmentClassification sprintOrKomClassification;

  /// Opis odcinka (np. "Serpentyny 21-17", "Ściana Cueña les Cabres 23.5%")
  final String note;

  const ClimbPitch({
    required this.lengthKm,
    required this.gradientPercent,
    this.surfaceType = SegmentSurfaceType.smoothAsphalt,
    this.technicalDifficulty = 40.0,
    this.sprintOrKomClassification = SegmentClassification.none,
    this.note = '',
  });

  /// Przewyższenie na tym odcinku [m]
  double get elevationGainM => lengthKm * 1000.0 * (gradientPercent / 100.0);

  ClimbPitch copyWith({
    double? lengthKm,
    double? gradientPercent,
    SegmentSurfaceType? surfaceType,
    double? technicalDifficulty,
    SegmentClassification? sprintOrKomClassification,
    String? note,
  }) {
    return ClimbPitch(
      lengthKm: lengthKm ?? this.lengthKm,
      gradientPercent: gradientPercent ?? this.gradientPercent,
      surfaceType: surfaceType ?? this.surfaceType,
      technicalDifficulty: technicalDifficulty ?? this.technicalDifficulty,
      sprintOrKomClassification:
          sprintOrKomClassification ?? this.sprintOrKomClassification,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lengthKm': lengthKm,
      'gradientPercent': gradientPercent,
      'surfaceType': surfaceType.toJson(),
      'technicalDifficulty': technicalDifficulty,
      'sprintOrKomClassification': sprintOrKomClassification.toJson(),
      'note': note,
    };
  }

  factory ClimbPitch.fromJson(Map<String, dynamic> json) {
    return ClimbPitch(
      lengthKm: (json['lengthKm'] as num).toDouble(),
      gradientPercent: (json['gradientPercent'] as num).toDouble(),
      surfaceType: SegmentSurfaceType.fromJson(json['surfaceType'] as String),
      technicalDifficulty: (json['technicalDifficulty'] as num).toDouble(),
      sprintOrKomClassification: SegmentClassification.fromJson(
        json['sprintOrKomClassification'] as String,
      ),
      note: json['note'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClimbPitch &&
        other.lengthKm == lengthKm &&
        other.gradientPercent == gradientPercent &&
        other.surfaceType == surfaceType &&
        other.technicalDifficulty == technicalDifficulty &&
        other.sprintOrKomClassification == sprintOrKomClassification &&
        other.note == note;
  }

  @override
  int get hashCode => Object.hash(
        lengthKm,
        gradientPercent,
        surfaceType,
        technicalDifficulty,
        sprintOrKomClassification,
        note,
      );

  @override
  String toString() =>
      'ClimbPitch(${lengthKm.toStringAsFixed(1)}km, ${gradientPercent.toStringAsFixed(1)}%, ${surfaceType.name}, "$note")';
}

/// Szczegółowy preset słynnego podjazdu, bergu brukowego lub sektora historycznego.
class ClimbPreset {
  final String id;
  final String name;
  final String localName;
  final String country;
  final double totalLengthKm;
  final double baseElevationM;
  final double summitElevationM;
  final double averageGradientPercent;
  final double maxGradientPercent;
  final SegmentClassification classification;
  final SegmentSurfaceType defaultSurfaceType;
  final double technicalDifficulty;
  final double typicalRoadBearingDegrees;
  final String description;
  final List<ClimbPitch> pitches;

  const ClimbPreset({
    required this.id,
    required this.name,
    required this.localName,
    required this.country,
    required this.totalLengthKm,
    required this.baseElevationM,
    required this.summitElevationM,
    required this.averageGradientPercent,
    required this.maxGradientPercent,
    required this.classification,
    required this.defaultSurfaceType,
    required this.technicalDifficulty,
    required this.typicalRoadBearingDegrees,
    required this.description,
    required this.pitches,
  });

  /// Łączne przewyższenie podjazdu [m]
  double get totalElevationGainM => math.max(0.0, summitElevationM - baseElevationM);

  /// Czy jest to sektor brukowy
  bool get isCobbled =>
      defaultSurfaceType == SegmentSurfaceType.cobblestonesSector1 ||
      defaultSurfaceType == SegmentSurfaceType.cobblestonesSector2 ||
      defaultSurfaceType == SegmentSurfaceType.cobblestonesSector3 ||
      defaultSurfaceType == SegmentSurfaceType.cobblestonesSector4 ||
      defaultSurfaceType == SegmentSurfaceType.cobblestonesSector5;

  /// Czy jest to odcinek szutrowy (sterrato / Strade Bianche)
  bool get isGravel => defaultSurfaceType == SegmentSurfaceType.gravelStrade;

  ClimbPreset copyWith({
    String? id,
    String? name,
    String? localName,
    String? country,
    double? totalLengthKm,
    double? baseElevationM,
    double? summitElevationM,
    double? averageGradientPercent,
    double? maxGradientPercent,
    SegmentClassification? classification,
    SegmentSurfaceType? defaultSurfaceType,
    double? technicalDifficulty,
    double? typicalRoadBearingDegrees,
    String? description,
    List<ClimbPitch>? pitches,
  }) {
    return ClimbPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      localName: localName ?? this.localName,
      country: country ?? this.country,
      totalLengthKm: totalLengthKm ?? this.totalLengthKm,
      baseElevationM: baseElevationM ?? this.baseElevationM,
      summitElevationM: summitElevationM ?? this.summitElevationM,
      averageGradientPercent: averageGradientPercent ?? this.averageGradientPercent,
      maxGradientPercent: maxGradientPercent ?? this.maxGradientPercent,
      classification: classification ?? this.classification,
      defaultSurfaceType: defaultSurfaceType ?? this.defaultSurfaceType,
      technicalDifficulty: technicalDifficulty ?? this.technicalDifficulty,
      typicalRoadBearingDegrees:
          typicalRoadBearingDegrees ?? this.typicalRoadBearingDegrees,
      description: description ?? this.description,
      pitches: pitches ?? this.pitches,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'localName': localName,
      'country': country,
      'totalLengthKm': totalLengthKm,
      'baseElevationM': baseElevationM,
      'summitElevationM': summitElevationM,
      'averageGradientPercent': averageGradientPercent,
      'maxGradientPercent': maxGradientPercent,
      'classification': classification.toJson(),
      'defaultSurfaceType': defaultSurfaceType.toJson(),
      'technicalDifficulty': technicalDifficulty,
      'typicalRoadBearingDegrees': typicalRoadBearingDegrees,
      'description': description,
      'pitches': pitches.map((p) => p.toJson()).toList(),
    };
  }

  factory ClimbPreset.fromJson(Map<String, dynamic> json) {
    return ClimbPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      localName: json['localName'] as String,
      country: json['country'] as String,
      totalLengthKm: (json['totalLengthKm'] as num).toDouble(),
      baseElevationM: (json['baseElevationM'] as num).toDouble(),
      summitElevationM: (json['summitElevationM'] as num).toDouble(),
      averageGradientPercent: (json['averageGradientPercent'] as num).toDouble(),
      maxGradientPercent: (json['maxGradientPercent'] as num).toDouble(),
      classification: SegmentClassification.fromJson(json['classification'] as String),
      defaultSurfaceType:
          SegmentSurfaceType.fromJson(json['defaultSurfaceType'] as String),
      technicalDifficulty: (json['technicalDifficulty'] as num).toDouble(),
      typicalRoadBearingDegrees:
          (json['typicalRoadBearingDegrees'] as num).toDouble(),
      description: json['description'] as String,
      pitches: (json['pitches'] as List<dynamic>)
          .map((e) => ClimbPitch.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClimbPreset && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ClimbPreset($name [$country], ${totalLengthKm.toStringAsFixed(1)}km, ${averageGradientPercent.toStringAsFixed(1)}%, szczyt: ${summitElevationM.round()}m)';
}

/// Zaawansowany serwis budujący szczegółowe profile tras i listy `StageSegment`
/// z autentycznymi podjazdami alpejskimi, pirenejskimi, brukami Flandrii i Roubaix.
class StageProfileBuilder {
  StageProfileBuilder._();

  // ===========================================================================
  // PRESETY SŁYNNYCH PODJAZDÓW I SEKTORÓW ŚWIATOWEGO KOLARSTWA
  // ===========================================================================

  /// Alpe d'Huez – ikona Tour de France, 21 ponumerowanych zakrętów
  static const ClimbPreset alpeDHuez = ClimbPreset(
    id: 'alpe_dhuez',
    name: "Alpe d'Huez",
    localName: "L'Alpe des 21 Virages",
    country: 'Francja',
    totalLengthKm: 13.8,
    baseElevationM: 730.0,
    summitElevationM: 1850.0,
    averageGradientPercent: 8.1,
    maxGradientPercent: 13.0,
    classification: SegmentClassification.horsCategorie,
    defaultSurfaceType: SegmentSurfaceType.smoothAsphalt,
    technicalDifficulty: 65.0,
    typicalRoadBearingDegrees: 110.0,
    description:
        'Legendarny alpejski podjazd o 21 ponumerowanych serpentynach. Początkowe 2 kilometry to brutalna ściana o nachyleniu 10.5-12%, po której następuje regularne 8-9% aż do płaskiego finiszu na stacji narciarskiej.',
    pitches: [
      ClimbPitch(
        lengthKm: 2.5,
        gradientPercent: 10.5,
        technicalDifficulty: 70.0,
        note: 'Virages 21-17: Morderczy początek podjazdu z doliny Romanche',
      ),
      ClimbPitch(
        lengthKm: 4.5,
        gradientPercent: 8.3,
        technicalDifficulty: 65.0,
        note: 'Virages 16-8: La Garde i Sainte-Ferréol, regularne alpejskie tempo',
      ),
      ClimbPitch(
        lengthKm: 4.8,
        gradientPercent: 8.5,
        technicalDifficulty: 60.0,
        note: 'Virages 7-1: Wieś Huez i otwarte pastwiska z widokiem na lodowiec',
      ),
      ClimbPitch(
        lengthKm: 2.0,
        gradientPercent: 5.1,
        technicalDifficulty: 45.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
        note: 'Finałowa prosta przez stację narciarską Alpe d\'Huez (1850m n.p.m.)',
      ),
    ],
  );

  /// Col du Tourmalet – król Pirenejów
  static const ClimbPreset tourmalet = ClimbPreset(
    id: 'tourmalet',
    name: 'Col du Tourmalet',
    localName: 'Gigant Pirenejów',
    country: 'Francja',
    totalLengthKm: 17.1,
    baseElevationM: 865.0,
    summitElevationM: 2115.0,
    averageGradientPercent: 7.3,
    maxGradientPercent: 11.5,
    classification: SegmentClassification.horsCategorie,
    defaultSurfaceType: SegmentSurfaceType.smoothAsphalt,
    technicalDifficulty: 60.0,
    typicalRoadBearingDegrees: 245.0,
    description:
        'Najczęściej pokonywana przełęcz w historii Wielkiej Pętli (od 1910 roku). Długi, nieustępliwy podjazd z surowym, wietrznym krajobrazem i pomnikiem Jacques\'a Goddeta na wierzchołku.',
    pitches: [
      ClimbPitch(
        lengthKm: 4.5,
        gradientPercent: 5.8,
        technicalDifficulty: 45.0,
        note: 'Dolina Campan: Wstępne wzniesienie wzdłuż rzeki Adour',
      ),
      ClimbPitch(
        lengthKm: 5.0,
        gradientPercent: 7.8,
        technicalDifficulty: 55.0,
        note: 'Gęsty las jodłowy Gripp i pierwsze strome rampy',
      ),
      ClimbPitch(
        lengthKm: 5.5,
        gradientPercent: 8.6,
        technicalDifficulty: 65.0,
        note: 'Stacja La Mongie i tunele przeciwlawinowe',
      ),
      ClimbPitch(
        lengthKm: 2.1,
        gradientPercent: 9.4,
        technicalDifficulty: 70.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
        note: 'Szczytowe serpentyny Tourmalet (2115m n.p.m.)',
      ),
    ],
  );

  /// Passo dello Stelvio – Cima Coppi Giro d'Italia (48 tornanti)
  static const ClimbPreset stelvio = ClimbPreset(
    id: 'stelvio',
    name: 'Passo dello Stelvio',
    localName: 'Cima Coppi – 48 Tornanti',
    country: 'Włochy',
    totalLengthKm: 21.5,
    baseElevationM: 1170.0,
    summitElevationM: 2758.0,
    averageGradientPercent: 7.4,
    maxGradientPercent: 14.0,
    classification: SegmentClassification.horsCategorie,
    defaultSurfaceType: SegmentSurfaceType.smoothAsphalt,
    technicalDifficulty: 80.0,
    typicalRoadBearingDegrees: 195.0,
    description:
        'Dach włoskiego Giro d\'Italia. 48 ponumerowanych kamiennymi słupkami serpentyn wspinających się na wysokość 2758 m n.p.m. Powyżej 2200 m n.p.m. kolarze zmagają się z rozrzedzonym powietrzem i drastycznym spadkiem mocy.',
    pitches: [
      ClimbPitch(
        lengthKm: 5.0,
        gradientPercent: 6.0,
        technicalDifficulty: 50.0,
        note: 'Wyjazd z Prato allo Stelvio, dolina Trafoi',
      ),
      ClimbPitch(
        lengthKm: 5.5,
        gradientPercent: 7.3,
        technicalDifficulty: 70.0,
        note: 'Wąwóz Gomagoi i serpentyny 48-35 w cieniu lasu',
      ),
      ClimbPitch(
        lengthKm: 4.5,
        gradientPercent: 8.2,
        technicalDifficulty: 80.0,
        note: 'Serpentyny 34-22, widok na lodowiec Ortler',
      ),
      ClimbPitch(
        lengthKm: 4.0,
        gradientPercent: 8.8,
        technicalDifficulty: 85.0,
        note: 'Strefa alpejska powyżej 2200m n.p.m. – hipoksja i chłód',
      ),
      ClimbPitch(
        lengthKm: 2.5,
        gradientPercent: 9.5,
        technicalDifficulty: 85.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
        note: 'Ostatnie wiraże na wierzchołek Cima Coppi (2758m n.p.m.)',
      ),
    ],
  );

  /// Passo del Mortirolo – najtrudniejszy podjazd Lombardii
  static const ClimbPreset mortirolo = ClimbPreset(
    id: 'mortirolo',
    name: 'Passo del Mortirolo',
    localName: 'Ściana Valtelliny',
    country: 'Włochy',
    totalLengthKm: 12.4,
    baseElevationM: 552.0,
    summitElevationM: 1852.0,
    averageGradientPercent: 10.5,
    maxGradientPercent: 18.0,
    classification: SegmentClassification.cat1,
    defaultSurfaceType: SegmentSurfaceType.roughAsphalt,
    technicalDifficulty: 75.0,
    typicalRoadBearingDegrees: 60.0,
    description:
        'Mordercza wspinaczka z Mazzo di Valtellina. Wąski, stromy asfalt bez choćby 100 metrów wypłaszczenia. Średnie nachylenie 10.5% z rampami sięgającymi 18%. Miejsce legendarnego ataku Marco Pantaniego w 1994 roku.',
    pitches: [
      ClimbPitch(
        lengthKm: 3.0,
        gradientPercent: 9.8,
        technicalDifficulty: 65.0,
        note: 'Mazzo: Natychmiastowe wejście w dwucyfrowe nachylenie',
      ),
      ClimbPitch(
        lengthKm: 3.5,
        gradientPercent: 12.2,
        technicalDifficulty: 80.0,
        note: 'Środkowa ściana: Ciągłe 12-18%, kolarze zygzakują na szosie',
      ),
      ClimbPitch(
        lengthKm: 3.5,
        gradientPercent: 10.8,
        technicalDifficulty: 75.0,
        note: 'Pomnik Marco Pantaniego na 11. zakręcie',
      ),
      ClimbPitch(
        lengthKm: 2.4,
        gradientPercent: 8.9,
        technicalDifficulty: 70.0,
        sprintOrKomClassification: SegmentClassification.cat1,
        note: 'Ostatni odcinek przez pastwisko Colica na grań Mortirolo (1852m)',
      ),
    ],
  );

  /// Alto de l'Angliru – piekło Asturii
  static const ClimbPreset angliru = ClimbPreset(
    id: 'angliru',
    name: "Alto de l'Angliru",
    localName: 'Piekło Asturii',
    country: 'Hiszpania',
    totalLengthKm: 12.5,
    baseElevationM: 310.0,
    summitElevationM: 1570.0,
    averageGradientPercent: 10.1,
    maxGradientPercent: 23.5,
    classification: SegmentClassification.horsCategorie,
    defaultSurfaceType: SegmentSurfaceType.roughAsphalt,
    technicalDifficulty: 85.0,
    typicalRoadBearingDegrees: 180.0,
    description:
        'Najbardziej bezwzględny podjazd Vuelta a España. Druga połowa wspinaczki to pasmo ramp o nachyleniu przekraczającym 20%, ze słynną Cueña les Cabres (23.5%), gdzie kolarze tracą równowagę przy prędkościach rzędu 7 km/h.',
    pitches: [
      ClimbPitch(
        lengthKm: 5.0,
        gradientPercent: 7.6,
        technicalDifficulty: 50.0,
        note: 'La Vega: Wstępna wspinaczka przez zielone łąki Asturii',
      ),
      ClimbPitch(
        lengthKm: 1.5,
        gradientPercent: 2.5,
        technicalDifficulty: 35.0,
        note: 'Viapará: Jedyne wypłaszczenie na trasie przed wjazdem do piekła',
      ),
      ClimbPitch(
        lengthKm: 4.0,
        gradientPercent: 14.5,
        technicalDifficulty: 90.0,
        note: 'Les Cabanes (20%) i rampa Cueña les Cabres (23.5%)',
      ),
      ClimbPitch(
        lengthKm: 2.0,
        gradientPercent: 11.2,
        technicalDifficulty: 75.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
        note: 'El Aviru (21.5%) i zjazdowy dojazd do kotła szczytowego Angliru',
      ),
    ],
  );

  /// Mont Ventoux – Łysa Góra Prowansji
  static const ClimbPreset montVentoux = ClimbPreset(
    id: 'mont_ventoux',
    name: 'Mont Ventoux',
    localName: 'Le Géant de Provence',
    country: 'Francja',
    totalLengthKm: 21.4,
    baseElevationM: 305.0,
    summitElevationM: 1909.0,
    averageGradientPercent: 7.5,
    maxGradientPercent: 12.0,
    classification: SegmentClassification.horsCategorie,
    defaultSurfaceType: SegmentSurfaceType.smoothAsphalt,
    technicalDifficulty: 65.0,
    typicalRoadBearingDegrees: 75.0,
    description:
        'Samotna góra wznosząca się ponad Prowansją. Pierwsze 15 km wiedzie przez duszny las o stałym nachyleniu 9.5%, po czym kolarze wyjeżdżają na nagie wapienne rumowisko z huraganowym wiatrem mistral.',
    pitches: [
      ClimbPitch(
        lengthKm: 5.5,
        gradientPercent: 4.6,
        technicalDifficulty: 40.0,
        note: 'Wyjazd z Bédoin przez winnice Saint-Estève',
      ),
      ClimbPitch(
        lengthKm: 9.5,
        gradientPercent: 9.2,
        technicalDifficulty: 65.0,
        note: 'Duszny las sosnowy do Chalet Reynard – ciągłe 9-10%',
      ),
      ClimbPitch(
        lengthKm: 4.5,
        gradientPercent: 7.8,
        technicalDifficulty: 70.0,
        note: 'Księżycowy krajobraz wapienny i pomnik Toma Simpsona',
      ),
      ClimbPitch(
        lengthKm: 1.9,
        gradientPercent: 9.8,
        technicalDifficulty: 75.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
        note: 'Finałowa rampa pod wieżę obserwatorium meteorologicznego (1909m)',
      ),
    ],
  );

  /// Col du Galibier – dach Alp
  static const ClimbPreset galibier = ClimbPreset(
    id: 'galibier',
    name: 'Col du Galibier',
    localName: 'Monument Henri Desgrange',
    country: 'Francja',
    totalLengthKm: 18.1,
    baseElevationM: 1410.0,
    summitElevationM: 2642.0,
    averageGradientPercent: 6.9,
    maxGradientPercent: 11.0,
    classification: SegmentClassification.horsCategorie,
    defaultSurfaceType: SegmentSurfaceType.smoothAsphalt,
    technicalDifficulty: 65.0,
    typicalRoadBearingDegrees: 170.0,
    description:
        'Jedna z najwyższych przełęczy drogowych Europy. Od strony Lautaret wspinaczka zaczyna się umiarkowanie, lecz ostatnie 8 kilometrów powyżej Plan Lachat to walka ze stromizną i wysokością ponad 2500 m.',
    pitches: [
      ClimbPitch(
        lengthKm: 5.0,
        gradientPercent: 5.5,
        technicalDifficulty: 45.0,
        note: 'Odejście od Col du Lautaret ku Plan Lachat',
      ),
      ClimbPitch(
        lengthKm: 5.5,
        gradientPercent: 6.8,
        technicalDifficulty: 60.0,
        note: 'Mostek Plan Lachat i wejście w surową dolinę rzeki Guisane',
      ),
      ClimbPitch(
        lengthKm: 5.0,
        gradientPercent: 8.3,
        technicalDifficulty: 70.0,
        note: 'Alpejskie zakręty powyżej 2300m i pomnik Henri Desgrange\'a',
      ),
      ClimbPitch(
        lengthKm: 2.6,
        gradientPercent: 9.1,
        technicalDifficulty: 75.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
        note: 'Objazd tunelu szczytowego i grzbiet Galibier (2642m n.p.m.)',
      ),
    ],
  );

  /// Monte Zoncolan – bestia z Friuli
  static const ClimbPreset zoncolan = ClimbPreset(
    id: 'zoncolan',
    name: 'Monte Zoncolan',
    localName: 'Il Mostro Zoncolan',
    country: 'Włochy',
    totalLengthKm: 10.1,
    baseElevationM: 530.0,
    summitElevationM: 1730.0,
    averageGradientPercent: 11.9,
    maxGradientPercent: 22.0,
    classification: SegmentClassification.horsCategorie,
    defaultSurfaceType: SegmentSurfaceType.smoothAsphalt,
    technicalDifficulty: 80.0,
    typicalRoadBearingDegrees: 90.0,
    description:
        'Powszechnie uznawany za najtrudniejszy podjazd w Europie. Środkowe 6 kilometrów z Ovaro ma stałe średnie nachylenie 15% z powtarzającymi się progami 20-22%. Końcówka wiedzie przez trzy wąskie, wykute w skale tunele.',
    pitches: [
      ClimbPitch(
        lengthKm: 2.0,
        gradientPercent: 8.5,
        technicalDifficulty: 55.0,
        note: 'Ovaro: Wioska i pierwsze ostre zakręty w lesie',
      ),
      ClimbPitch(
        lengthKm: 6.0,
        gradientPercent: 15.0,
        technicalDifficulty: 90.0,
        note: 'Ściana Zoncolan: 6 kilometrów piekła o stałym nachyleniu 15%',
      ),
      ClimbPitch(
        lengthKm: 2.1,
        gradientPercent: 8.1,
        technicalDifficulty: 75.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
        note: 'Trzy wąskie tunele skalne i szczytowy kocioł Zoncolan (1730m)',
      ),
    ],
  );

  /// Colle delle Finestre – sterrato na wysokości 2176 m n.p.m.
  static const ClimbPreset finestre = ClimbPreset(
    id: 'finestre',
    name: 'Colle delle Finestre',
    localName: 'Il Colle dello Sterrato',
    country: 'Włochy',
    totalLengthKm: 18.5,
    baseElevationM: 474.0,
    summitElevationM: 2176.0,
    averageGradientPercent: 9.2,
    maxGradientPercent: 14.0,
    classification: SegmentClassification.horsCategorie,
    defaultSurfaceType: SegmentSurfaceType.roughAsphalt,
    technicalDifficulty: 85.0,
    typicalRoadBearingDegrees: 210.0,
    description:
        'Niewiarygodna przełęcz w Piemoncie. Pierwsze 10.7 km to wąski asfalt z 28 serpentynami, a finałowe 7.8 km to utwardzony szuter (sterrato) o niezmiennym nachyleniu 9.2% aż do Fortu delle Finestre.',
    pitches: [
      ClimbPitch(
        lengthKm: 6.0,
        gradientPercent: 9.1,
        technicalDifficulty: 70.0,
        note: 'Meana di Susa: Dolne serpentyny w cieniu kasztanowców',
      ),
      ClimbPitch(
        lengthKm: 4.7,
        gradientPercent: 9.3,
        technicalDifficulty: 75.0,
        note: 'Koniec asfaltu i wjazd na poziom 1400m n.p.m.',
      ),
      ClimbPitch(
        lengthKm: 7.8,
        gradientPercent: 9.2,
        surfaceType: SegmentSurfaceType.gravelStrade,
        technicalDifficulty: 90.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
        note: 'Słynny odcinek szutrowy (sterrato) i grań przełęczy Finestre',
      ),
    ],
  );

  /// Lagos de Covadonga – asturyjskie jeziora polodowcowe
  static const ClimbPreset covadonga = ClimbPreset(
    id: 'covadonga',
    name: 'Lagos de Covadonga',
    localName: 'Santuario y Lagos de Covadonga',
    country: 'Hiszpania',
    totalLengthKm: 12.5,
    baseElevationM: 240.0,
    summitElevationM: 1110.0,
    averageGradientPercent: 6.9,
    maxGradientPercent: 15.0,
    classification: SegmentClassification.horsCategorie,
    defaultSurfaceType: SegmentSurfaceType.smoothAsphalt,
    technicalDifficulty: 65.0,
    typicalRoadBearingDegrees: 140.0,
    description:
        'Historyczny finisz Vuelta a España w Parku Narodowym Picos de Europa. Kluczowym momentem jest mordercza rampa La Huesera (15%), po której kolarze mijają jeziora Enol i Ercina.',
    pitches: [
      ClimbPitch(
        lengthKm: 5.5,
        gradientPercent: 6.2,
        technicalDifficulty: 50.0,
        note: 'Mijając Sanktuarium Covadonga i wjazd w Picos de Europa',
      ),
      ClimbPitch(
        lengthKm: 4.0,
        gradientPercent: 11.0,
        technicalDifficulty: 75.0,
        note: 'Słynna ściana La Huesera (15%) i Mirador de la Reina',
      ),
      ClimbPitch(
        lengthKm: 3.0,
        gradientPercent: 3.5,
        technicalDifficulty: 55.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
        note: 'Pofałdowany dojazd wokół jezior Enol i Ercina (1110m n.p.m.)',
      ),
    ],
  );

  /// Oude Kwaremont – kręgosłup Ronde van Vlaanderen
  static const ClimbPreset oudeKwaremont = ClimbPreset(
    id: 'oude_kwaremont',
    name: 'Oude Kwaremont',
    localName: 'Oude Kwaremont Cobbles',
    country: 'Belgia',
    totalLengthKm: 2.2,
    baseElevationM: 18.0,
    summitElevationM: 111.0,
    averageGradientPercent: 4.2,
    maxGradientPercent: 11.6,
    classification: SegmentClassification.cat3,
    defaultSurfaceType: SegmentSurfaceType.cobblestonesSector4,
    technicalDifficulty: 75.0,
    typicalRoadBearingDegrees: 330.0,
    description:
        'Najważniejszy podjazd brukowy Flandrii. 1500 metrów wybijającego z rytmu, nierównego bruku. Po stromej rampie w środku następuje wietrzny, płaski bruk ku szosie N8.',
    pitches: [
      ClimbPitch(
        lengthKm: 0.6,
        gradientPercent: 6.5,
        technicalDifficulty: 50.0,
        note: 'Asfaltowy dojazd z Berchem do pierwszych kostek bruku',
      ),
      ClimbPitch(
        lengthKm: 1.1,
        gradientPercent: 4.5,
        surfaceType: SegmentSurfaceType.cobblestonesSector4,
        technicalDifficulty: 80.0,
        note: 'Brukowa rampa przez rynek Kwaremont z maksymalnym nachyleniem 11.6%',
      ),
      ClimbPitch(
        lengthKm: 0.5,
        gradientPercent: 1.5,
        surfaceType: SegmentSurfaceType.cobblestonesSector3,
        technicalDifficulty: 70.0,
        sprintOrKomClassification: SegmentClassification.cat3,
        note: 'Płaski, wyboisty grzbiet brukowy wystawiony na boczny wiatr',
      ),
    ],
  );

  /// Paterberg – stroma brukowana ściana Flandrii
  static const ClimbPreset paterberg = ClimbPreset(
    id: 'paterberg',
    name: 'Paterberg',
    localName: 'Paterberg Muur',
    country: 'Belgia',
    totalLengthKm: 0.36,
    baseElevationM: 32.0,
    summitElevationM: 80.0,
    averageGradientPercent: 12.9,
    maxGradientPercent: 20.3,
    classification: SegmentClassification.cat4,
    defaultSurfaceType: SegmentSurfaceType.cobblestonesSector5,
    technicalDifficulty: 85.0,
    typicalRoadBearingDegrees: 350.0,
    description:
        'Krótki, brutalny berg brukowy o maksymalnym nachyleniu 20.3%. Ostatnia wspinaczka Ronde van Vlaanderen, skąd do mety w Oudenaarde pozostaje 13 km płaskiej szosy.',
    pitches: [
      ClimbPitch(
        lengthKm: 0.36,
        gradientPercent: 12.9,
        surfaceType: SegmentSurfaceType.cobblestonesSector5,
        technicalDifficulty: 85.0,
        sprintOrKomClassification: SegmentClassification.cat4,
        note: 'Pionowy bruk Paterbergu (20.3% max) – decydujący punkt Flandrii',
      ),
    ],
  );

  /// Koppenberg – wąwóz oślizgłego bruku
  static const ClimbPreset koppenberg = ClimbPreset(
    id: 'koppenberg',
    name: 'Koppenberg',
    localName: 'De Koppenberg',
    country: 'Belgia',
    totalLengthKm: 0.60,
    baseElevationM: 13.0,
    summitElevationM: 77.0,
    averageGradientPercent: 11.6,
    maxGradientPercent: 22.0,
    classification: SegmentClassification.cat3,
    defaultSurfaceType: SegmentSurfaceType.cobblestonesSector5,
    technicalDifficulty: 90.0,
    typicalRoadBearingDegrees: 20.0,
    description:
        'Legenda Flandrii. Wąska gardziel wcięta w zbocze, gdzie wilgotny bruk zmusza do podchodzenia pieszo, gdy choć jeden kolarz straci przyczepność na 22% nachyleniu.',
    pitches: [
      ClimbPitch(
        lengthKm: 0.2,
        gradientPercent: 7.5,
        surfaceType: SegmentSurfaceType.cobblestonesSector3,
        technicalDifficulty: 70.0,
        note: 'Wjazd w wąwóz Koppenbergu pod koronami drzew',
      ),
      ClimbPitch(
        lengthKm: 0.4,
        gradientPercent: 13.6,
        surfaceType: SegmentSurfaceType.cobblestonesSector5,
        technicalDifficulty: 95.0,
        sprintOrKomClassification: SegmentClassification.cat3,
        note: 'Maksymalne nachylenie 22% na śliskim, zapiaszczonym bruku',
      ),
    ],
  );

  /// Muur van Geraardsbergen – Kapelmuur
  static const ClimbPreset geraardsbergen = ClimbPreset(
    id: 'geraardsbergen',
    name: 'Muur van Geraardsbergen',
    localName: 'Kapelmuur',
    country: 'Belgia',
    totalLengthKm: 1.07,
    baseElevationM: 20.0,
    summitElevationM: 110.0,
    averageGradientPercent: 9.3,
    maxGradientPercent: 19.8,
    classification: SegmentClassification.cat3,
    defaultSurfaceType: SegmentSurfaceType.cobblestonesSector4,
    technicalDifficulty: 80.0,
    typicalRoadBearingDegrees: 15.0,
    description:
        'Historyczne serce flandryjskiego kolarstwa. Wspinaczka z miasteczka ku kapliczce na szczycie Oudenbergu, z łukiem o nachyleniu blisko 20%.',
    pitches: [
      ClimbPitch(
        lengthKm: 0.6,
        gradientPercent: 7.5,
        surfaceType: SegmentSurfaceType.cobblestonesSector3,
        technicalDifficulty: 70.0,
        note: 'Oudenbergstraat: Brukowana ulica w Geraardsbergen',
      ),
      ClimbPitch(
        lengthKm: 0.47,
        gradientPercent: 11.6,
        surfaceType: SegmentSurfaceType.cobblestonesSector4,
        technicalDifficulty: 85.0,
        sprintOrKomClassification: SegmentClassification.cat3,
        note: 'Łuk wokół Kapliczki (Kapelmuur) o nachyleniu 19.8%',
      ),
    ],
  );

  /// Mur de Huy – Chemin des Gueules
  static const ClimbPreset murDeHuy = ClimbPreset(
    id: 'mur_de_huy',
    name: 'Mur de Huy',
    localName: 'Chemin des Gueules',
    country: 'Belgia',
    totalLengthKm: 1.3,
    baseElevationM: 75.0,
    summitElevationM: 204.0,
    averageGradientPercent: 9.6,
    maxGradientPercent: 26.0,
    classification: SegmentClassification.cat3,
    defaultSurfaceType: SegmentSurfaceType.smoothAsphalt,
    technicalDifficulty: 75.0,
    typicalRoadBearingDegrees: 135.0,
    description:
        'Finałowa ściana Walońskiej Strzały (La Flèche Wallonne). Kluczowa jest szykana Claudy Criquieliona (26%), gdzie atak w odpowiednim ułamku sekundy decyduje o zwycięstwie.',
    pitches: [
      ClimbPitch(
        lengthKm: 0.4,
        gradientPercent: 6.8,
        technicalDifficulty: 50.0,
        note: 'Chemin des Chapelles: Dolne kapliczki wzdłuż drogi',
      ),
      ClimbPitch(
        lengthKm: 0.5,
        gradientPercent: 15.2,
        technicalDifficulty: 85.0,
        note: 'Słynna podwójna szykana ' 'S-bend' ' o nachyleniu 26%',
      ),
      ClimbPitch(
        lengthKm: 0.4,
        gradientPercent: 8.5,
        technicalDifficulty: 65.0,
        sprintOrKomClassification: SegmentClassification.cat3,
        note: 'Finałowy sprint pod górę pod kościołem Notre-Dame de la Sarte',
      ),
    ],
  );

  /// Côte de La Redoute – kluczowy punkt Liège-Bastogne-Liège
  static const ClimbPreset laRedoute = ClimbPreset(
    id: 'la_redoute',
    name: 'Côte de La Redoute',
    localName: 'La Redoute Remouchamps',
    country: 'Belgia',
    totalLengthKm: 1.6,
    baseElevationM: 130.0,
    summitElevationM: 282.0,
    averageGradientPercent: 9.5,
    maxGradientPercent: 20.0,
    classification: SegmentClassification.cat2,
    defaultSurfaceType: SegmentSurfaceType.smoothAsphalt,
    technicalDifficulty: 70.0,
    typicalRoadBearingDegrees: 270.0,
    description:
        'Kultowy podjazd Ardeński z Remouchamps. Asfalt pomalowany imionami kolarzy, wąska szosa wzdłuż autostrady i rampa 20%, gdzie formują się decydujące ataki w Staruszce.',
    pitches: [
      ClimbPitch(
        lengthKm: 0.9,
        gradientPercent: 11.5,
        technicalDifficulty: 75.0,
        note: 'Dolna ściana La Redoute o nachyleniu sięgającym 20%',
      ),
      ClimbPitch(
        lengthKm: 0.7,
        gradientPercent: 6.9,
        technicalDifficulty: 60.0,
        sprintOrKomClassification: SegmentClassification.cat2,
        note: 'Wietrzny grzbiet nad autostradą E25 ku szczytowi',
      ),
    ],
  );

  /// Poggio di Sanremo – trampolina Mediolan-San Remo
  static const ClimbPreset poggio = ClimbPreset(
    id: 'poggio',
    name: 'Poggio di Sanremo',
    localName: 'Il Poggio',
    country: 'Włochy',
    totalLengthKm: 3.7,
    baseElevationM: 20.0,
    summitElevationM: 162.0,
    averageGradientPercent: 3.7,
    maxGradientPercent: 8.0,
    classification: SegmentClassification.cat4,
    defaultSurfaceType: SegmentSurfaceType.smoothAsphalt,
    technicalDifficulty: 75.0,
    typicalRoadBearingDegrees: 240.0,
    description:
        'Wzgórze nad Morzem Liguryjskim, na które kolarze wjeżdżają po niemal 300 km jazdy. Choć średnie nachylenie to tylko 3.7%, rampa 8% przy budce telefonicznej i szaleńczy zjazd decydują o triumfie w Primaverze.',
    pitches: [
      ClimbPitch(
        lengthKm: 2.5,
        gradientPercent: 3.5,
        technicalDifficulty: 60.0,
        note: 'Podjazd przez szklarnie i wille nad zatoką Sanremo',
      ),
      ClimbPitch(
        lengthKm: 1.2,
        gradientPercent: 4.2,
        technicalDifficulty: 75.0,
        sprintOrKomClassification: SegmentClassification.cat4,
        note: 'Rampa 8% przed szczytem i wejście w karkołomny zjazd',
      ),
    ],
  );

  /// Cipressa – wstęp do finału Mediolan-San Remo
  static const ClimbPreset cipressa = ClimbPreset(
    id: 'cipressa',
    name: 'Cipressa',
    localName: 'La Cipressa',
    country: 'Włochy',
    totalLengthKm: 5.6,
    baseElevationM: 10.0,
    summitElevationM: 240.0,
    averageGradientPercent: 4.1,
    maxGradientPercent: 9.0,
    classification: SegmentClassification.cat3,
    defaultSurfaceType: SegmentSurfaceType.smoothAsphalt,
    technicalDifficulty: 65.0,
    typicalRoadBearingDegrees: 310.0,
    description:
        'Pierwszy z dwóch decydujących przylądków liguryjskich w Mediolan-San Remo. Tempo narzucane przez pomocników faworytów odczepia czystych sprinterów.',
    pitches: [
      ClimbPitch(
        lengthKm: 3.5,
        gradientPercent: 4.8,
        technicalDifficulty: 65.0,
        note: 'Costarainera: Serpentyny nad szosą Aurelia z rampą 9%',
      ),
      ClimbPitch(
        lengthKm: 2.1,
        gradientPercent: 3.0,
        technicalDifficulty: 55.0,
        sprintOrKomClassification: SegmentClassification.cat3,
        note: 'Tarasy oliwne przed zjazdem ku szosie nadmorskiej',
      ),
    ],
  );

  /// Madonna del Ghisallo – sanktuarium kolarzy w Il Lombardia
  static const ClimbPreset ghisallo = ClimbPreset(
    id: 'ghisallo',
    name: 'Madonna del Ghisallo',
    localName: 'Colle del Ghisallo',
    country: 'Włochy',
    totalLengthKm: 8.6,
    baseElevationM: 220.0,
    summitElevationM: 754.0,
    averageGradientPercent: 6.2,
    maxGradientPercent: 14.0,
    classification: SegmentClassification.cat2,
    defaultSurfaceType: SegmentSurfaceType.smoothAsphalt,
    technicalDifficulty: 65.0,
    typicalRoadBearingDegrees: 180.0,
    description:
        'Słynne wzgórze nad Jeziorem Como ze świątynią Matki Boskiej patronki kolarzy. Dolne 3.5 km to ściana o nachyleniu 9-14%, po czym następuje wypłaszczenie i finałowa wspinaczka pod dzwonnicę.',
    pitches: [
      ClimbPitch(
        lengthKm: 3.5,
        gradientPercent: 9.1,
        technicalDifficulty: 70.0,
        note: 'Bellagio: Dolne serpentyny z widokiem na jezioro, nachylenie do 14%',
      ),
      ClimbPitch(
        lengthKm: 3.0,
        gradientPercent: 1.4,
        technicalDifficulty: 45.0,
        note: 'Płaskowyż Civenna: Szybki odcinek regeneracyjny',
      ),
      ClimbPitch(
        lengthKm: 2.1,
        gradientPercent: 7.8,
        technicalDifficulty: 65.0,
        sprintOrKomClassification: SegmentClassification.cat2,
        note: 'Dojazd pod kościółek Madonna del Ghisallo i muzeum kolarstwa',
      ),
    ],
  );

  /// Muro di Sormano – pionowa ściana Il Lombardia
  static const ClimbPreset sormano = ClimbPreset(
    id: 'sormano',
    name: 'Muro di Sormano',
    localName: 'Il Muro di Sormano',
    country: 'Włochy',
    totalLengthKm: 1.92,
    baseElevationM: 830.0,
    summitElevationM: 1124.0,
    averageGradientPercent: 15.8,
    maxGradientPercent: 27.0,
    classification: SegmentClassification.cat1,
    defaultSurfaceType: SegmentSurfaceType.smoothAsphalt,
    technicalDifficulty: 85.0,
    typicalRoadBearingDegrees: 160.0,
    description:
        'Przerażający podjazd w Górach Lombardzkich. Średnie nachylenie prawie 16% na dystansie niespełna 2 km z rampą sięgającą 27%. Na asfalcie wypisane są cytaty kolarzy i metry przewyższenia co do centymetra.',
    pitches: [
      ClimbPitch(
        lengthKm: 1.0,
        gradientPercent: 15.4,
        technicalDifficulty: 85.0,
        note: 'Wąska leśna dróżka z wymalowanymi na asfalcie wysokościami',
      ),
      ClimbPitch(
        lengthKm: 0.92,
        gradientPercent: 16.2,
        technicalDifficulty: 90.0,
        sprintOrKomClassification: SegmentClassification.cat1,
        note: 'Maksymalny próg 27% – kolarze jadą na przełożeniach 34x32',
      ),
    ],
  );

  /// Trouée d'Arenberg – 5-gwiazdkowy sektor brukowy Paryż-Roubaix
  static const ClimbPreset troueeArenberg = ClimbPreset(
    id: 'trouee_arenberg',
    name: "Trouée d'Arenberg",
    localName: "Drève des Boules d'Hérin",
    country: 'Francja',
    totalLengthKm: 2.3,
    baseElevationM: 25.0,
    summitElevationM: 25.0,
    averageGradientPercent: 0.0,
    maxGradientPercent: 0.0,
    classification: SegmentClassification.none,
    defaultSurfaceType: SegmentSurfaceType.cobblestonesSector5,
    technicalDifficulty: 95.0,
    typicalRoadBearingDegrees: 65.0,
    description:
        'Piekło Północy w czystej postaci. Prosta jak strzała aleja w mrocznym lesie Arenberg, z nieregularnymi, porośniętymi mchem głazami. Peleton wjeżdża tu z prędkością 60 km/h, ryzykując masowe kraksy i defekty.',
    pitches: [
      ClimbPitch(
        lengthKm: 2.3,
        gradientPercent: 0.0,
        surfaceType: SegmentSurfaceType.cobblestonesSector5,
        technicalDifficulty: 95.0,
        note: '5 gwiazdek: Morderczy bruk Lasu Arenberg – kluczowy punkt Roubaix',
      ),
    ],
  );

  /// Carrefour de l'Arbre – przedostatni 5-gwiazdkowy sektor Paryż-Roubaix
  static const ClimbPreset carrefourArbre = ClimbPreset(
    id: 'carrefour_arbre',
    name: "Carrefour de l'Arbre",
    localName: "Pavé de Luchin à Camphin",
    country: 'Francja',
    totalLengthKm: 2.1,
    baseElevationM: 48.0,
    summitElevationM: 48.0,
    averageGradientPercent: 0.0,
    maxGradientPercent: 0.0,
    classification: SegmentClassification.none,
    defaultSurfaceType: SegmentSurfaceType.cobblestonesSector5,
    technicalDifficulty: 90.0,
    typicalRoadBearingDegrees: 120.0,
    description:
        'Ostatnia szansa na atak przed welodromem w Roubaix (15 km do mety). Bruk jest tu rozrzucony i pełen dziur, a seria ostrych zakrętów pod kątem 90 stopni wymaga perfekcyjnego panowania nad rowerem.',
    pitches: [
      ClimbPitch(
        lengthKm: 2.1,
        gradientPercent: 0.0,
        surfaceType: SegmentSurfaceType.cobblestonesSector5,
        technicalDifficulty: 90.0,
        note: '5 gwiazdek: Wyboisty, połamany bruk wokół oberży de l\'Arbre',
      ),
    ],
  );

  /// Mons-en-Pévèle – 5-gwiazdkowy sektor Paryż-Roubaix
  static const ClimbPreset monsEnPevele = ClimbPreset(
    id: 'mons_en_pevele',
    name: 'Mons-en-Pévèle',
    localName: 'Pavé du Bar',
    country: 'Francja',
    totalLengthKm: 3.0,
    baseElevationM: 52.0,
    summitElevationM: 58.0,
    averageGradientPercent: 0.2,
    maxGradientPercent: 3.0,
    classification: SegmentClassification.none,
    defaultSurfaceType: SegmentSurfaceType.cobblestonesSector5,
    technicalDifficulty: 88.0,
    typicalRoadBearingDegrees: 275.0,
    description:
        '3000 metrów zdradzieckiego, błotnistego bruku z dwoma ostrymi skrętami o 90 stopni i fałszywym wzniesieniem pod wiatr.',
    pitches: [
      ClimbPitch(
        lengthKm: 3.0,
        gradientPercent: 0.2,
        surfaceType: SegmentSurfaceType.cobblestonesSector5,
        technicalDifficulty: 88.0,
        note: '5 gwiazdek: Mons-en-Pévèle – 3 km błota i głębokich kolein',
      ),
    ],
  );

  /// Monte Sante Marie – królewski sektor szutrowy Strade Bianche
  static const ClimbPreset monteSanteMarie = ClimbPreset(
    id: 'monte_sante_marie',
    name: 'Monte Sante Marie',
    localName: 'Settore Fabian Cancellara',
    country: 'Włochy',
    totalLengthKm: 11.5,
    baseElevationM: 180.0,
    summitElevationM: 360.0,
    averageGradientPercent: 2.5,
    maxGradientPercent: 18.0,
    classification: SegmentClassification.cat3,
    defaultSurfaceType: SegmentSurfaceType.gravelStrade,
    technicalDifficulty: 85.0,
    typicalRoadBearingDegrees: 15.0,
    description:
        'Najdłuższy i najtrudniejszy sektor toskańskiego szutru w Strade Bianche (11.5 km). Strome, sypkie ścianki o nachyleniu do 18% przeplatają się z szybkimi, niebezpiecznymi zjazdami w tumanach białego pyłu.',
    pitches: [
      ClimbPitch(
        lengthKm: 4.0,
        gradientPercent: 3.8,
        surfaceType: SegmentSurfaceType.gravelStrade,
        technicalDifficulty: 80.0,
        note: 'Asciano: Wjazd na sypki biały szuter toskański',
      ),
      ClimbPitch(
        lengthKm: 3.5,
        gradientPercent: 6.2,
        surfaceType: SegmentSurfaceType.gravelStrade,
        technicalDifficulty: 90.0,
        sprintOrKomClassification: SegmentClassification.cat3,
        note: 'Stroma rampa 18% w kurzu i grzbiet Monte Sante Marie',
      ),
      ClimbPitch(
        lengthKm: 4.0,
        gradientPercent: -2.4,
        surfaceType: SegmentSurfaceType.gravelStrade,
        technicalDifficulty: 85.0,
        note: 'Szybki, techniczny zjazd po luźnych kamieniach ku szosie asfaltowej',
      ),
    ],
  );

  /// Cauberg – wzgórze w Valkenburgu (Amstel Gold Race)
  static const ClimbPreset cauberg = ClimbPreset(
    id: 'cauberg',
    name: 'Cauberg',
    localName: 'Valkenburg Cauberg',
    country: 'Holandia',
    totalLengthKm: 0.8,
    baseElevationM: 60.0,
    summitElevationM: 134.0,
    averageGradientPercent: 5.8,
    maxGradientPercent: 12.0,
    classification: SegmentClassification.cat4,
    defaultSurfaceType: SegmentSurfaceType.smoothAsphalt,
    technicalDifficulty: 60.0,
    typicalRoadBearingDegrees: 105.0,
    description:
        'Ikona holenderskiego kolarstwa w Valkenburgu. Szeroka szosa, na której podjazd rozpoczyna się łagodnie, by w połowie osiągnąć 12% przed metą w Vilt.',
    pitches: [
      ClimbPitch(
        lengthKm: 0.8,
        gradientPercent: 5.8,
        technicalDifficulty: 60.0,
        sprintOrKomClassification: SegmentClassification.cat4,
        note: 'Rampa Caubergu (12% max) z widokiem na ruiny zamku w Valkenburgu',
      ),
    ],
  );

  /// Mapa wszystkich dostępnych presetów podjazdów i sektorów
  static final Map<String, ClimbPreset> allPresets = {
    alpeDHuez.id: alpeDHuez,
    tourmalet.id: tourmalet,
    stelvio.id: stelvio,
    mortirolo.id: mortirolo,
    angliru.id: angliru,
    montVentoux.id: montVentoux,
    galibier.id: galibier,
    zoncolan.id: zoncolan,
    finestre.id: finestre,
    covadonga.id: covadonga,
    oudeKwaremont.id: oudeKwaremont,
    paterberg.id: paterberg,
    koppenberg.id: koppenberg,
    geraardsbergen.id: geraardsbergen,
    murDeHuy.id: murDeHuy,
    laRedoute.id: laRedoute,
    poggio.id: poggio,
    cipressa.id: cipressa,
    ghisallo.id: ghisallo,
    sormano.id: sormano,
    troueeArenberg.id: troueeArenberg,
    carrefourArbre.id: carrefourArbre,
    monsEnPevele.id: monsEnPevele,
    monteSanteMarie.id: monteSanteMarie,
    cauberg.id: cauberg,
  };

  /// Pobiera preset po identyfikatorze
  static ClimbPreset? getPreset(String id) => allPresets[id];

  /// Zwraca listę gigantów Grand Tourów (HC i Cat 1)
  static List<ClimbPreset> getGrandTourAscents() => [
        alpeDHuez,
        tourmalet,
        stelvio,
        mortirolo,
        angliru,
        montVentoux,
        galibier,
        zoncolan,
        finestre,
        covadonga,
      ];

  /// Zwraca listę bruków Flandrii
  static List<ClimbPreset> getFlemishBergs() => [
        oudeKwaremont,
        paterberg,
        koppenberg,
        geraardsbergen,
      ];

  /// Zwraca listę 5-gwiazdkowych sektorów Paryż-Roubaix
  static List<ClimbPreset> getParisRoubaixSectors() => [
        troueeArenberg,
        monsEnPevele,
        carrefourArbre,
      ];

  /// Zwraca listę stromych ścian klasyków ardeńskich
  static List<ClimbPreset> getArdennesWalls() => [
        murDeHuy,
        laRedoute,
        cauberg,
      ];

  /// Zwraca listę podjazdów włoskich klasyków (Sanremo i Lombardia)
  static List<ClimbPreset> getItalianMonumentsClimbs() => [
        cipressa,
        poggio,
        ghisallo,
        sormano,
      ];

  // ===========================================================================
  // FABRYKI I GENERATORY ETAPÓW (STAGE BUILDERS)
  // ===========================================================================

  /// Buduje królewski etap wysokogórski (High Mountain / Summit Finish)
  /// z autentycznymi podjazdami z listy presetów.
  static RaceStage buildHighMountainStage({
    required String id,
    required int stageNumber,
    required String name,
    required double distanceKm,
    required List<ClimbPreset> climbs,
    bool isSummitFinish = true,
    double valleyElevationM = 400.0,
    double baseTemperatureCelsius = 17.0,
    WeatherCondition weatherCondition = WeatherCondition.sunny,
    double windSpeedKmh = 18.0,
    double windDirectionDegrees = 270.0,
  }) {
    if (climbs.isEmpty) {
      throw ArgumentError('Etap wysokogórski wymaga co najmniej jednego podjazdu.');
    }

    final List<StageSegment> segments = [];
    int segmentIndex = 0;
    double currentKm = 0.0;
    double currentElevation = valleyElevationM;

    // Obliczamy łączną długość wszystkich podjazdów z listy
    double totalClimbsDistance = 0.0;
    for (final c in climbs) {
      totalClimbsDistance += c.totalLengthKm;
    }

    // Pozostały dystans dzielimy na:
    // - dojazd w dolinie przed pierwszym podjazdem
    // - zjazdy i doliny łączące między podjazdami
    // - ewentualny zjazd/płaski dojazd po ostatnim podjeździe (jeśli nie jest summit finish)
    final double remainingDistance = math.max(20.0, distanceKm - totalClimbsDistance);
    final int transitionsCount = climbs.length + (isSummitFinish ? 0 : 1);
    final double transitionLength = remainingDistance / transitionsCount;

    for (int i = 0; i < climbs.length; i++) {
      final climb = climbs[i];

      // 1. Odcinek dojazdowy w dolinie (płaski / falujący)
      final double valleyLen = double.parse(
        math.max(5.0, transitionLength * (i == 0 ? 0.6 : 0.4)).toStringAsFixed(1),
      );
      final double valleyEndElev = climb.baseElevationM;

      segments.add(
        StageSegment(
          index: segmentIndex++,
          startKm: double.parse(currentKm.toStringAsFixed(2)),
          lengthKm: valleyLen,
          startElevationM: double.parse(currentElevation.toStringAsFixed(1)),
          endElevationM: double.parse(valleyEndElev.toStringAsFixed(1)),
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 25.0,
          windDirectionDegrees: windDirectionDegrees,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: (i == 1 && climbs.length > 1)
              ? SegmentClassification.intermediateSprint
              : SegmentClassification.none,
        ),
      );
      currentKm += valleyLen;
      currentElevation = valleyEndElev;

      // 2. Wstawienie autentycznego podjazdu podzielonego na pitche (rampy)
      for (int p = 0; p < climb.pitches.length; p++) {
        final pitch = climb.pitches[p];
        final bool isLastPitchOfClimb = p == climb.pitches.length - 1;
        final bool isLastClimbOfStage = i == climbs.length - 1;

        final double pitchElevGain = pitch.elevationGainM;
        final double pitchEndElev = currentElevation + pitchElevGain;

        // Określamy klasyfikację:
        // Jeśli to finisz na szczycie i ostatni pitch ostatniego podjazdu,
        // przypisujemy klasyfikację szczytu (np. horsCategorie).
        SegmentClassification classification = pitch.sprintOrKomClassification;
        if (isLastPitchOfClimb) {
          classification = climb.classification;
        }

        segments.add(
          StageSegment(
            index: segmentIndex++,
            startKm: double.parse(currentKm.toStringAsFixed(2)),
            lengthKm: double.parse(pitch.lengthKm.toStringAsFixed(2)),
            startElevationM: double.parse(currentElevation.toStringAsFixed(1)),
            endElevationM: double.parse(pitchEndElev.toStringAsFixed(1)),
            surfaceType: pitch.surfaceType,
            technicalDifficulty: pitch.technicalDifficulty,
            windDirectionDegrees: windDirectionDegrees,
            roadBearingDegrees: climb.typicalRoadBearingDegrees,
            sprintOrKomClassification: classification,
          ),
        );
        currentKm += pitch.lengthKm;
        currentElevation = pitchEndElev;

        // Jeśli to ostatni pitch ostatniego podjazdu na summit finish, kończymy etap!
        if (isLastClimbOfStage && isSummitFinish && isLastPitchOfClimb) {
          break;
        }
      }

      // 3. Zjazd z przełęczy (jeśli nie jest to meta na szczycie)
      if (i < climbs.length - 1 || !isSummitFinish) {
        final double nextBaseElevation = (i < climbs.length - 1)
            ? climbs[i + 1].baseElevationM
            : valleyElevationM;
        final double descentLen = double.parse(
          math.max(8.0, transitionLength * 0.6).toStringAsFixed(1),
        );

        segments.add(
          StageSegment(
            index: segmentIndex++,
            startKm: double.parse(currentKm.toStringAsFixed(2)),
            lengthKm: descentLen,
            startElevationM: double.parse(currentElevation.toStringAsFixed(1)),
            endElevationM: double.parse(nextBaseElevation.toStringAsFixed(1)),
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 75.0, // Bardzo techniczny, niebezpieczny zjazd alpejski
            windDirectionDegrees: windDirectionDegrees,
            roadBearingDegrees: (climb.typicalRoadBearingDegrees + 180.0) % 360.0,
            sprintOrKomClassification: SegmentClassification.none,
          ),
        );
        currentKm += descentLen;
        currentElevation = nextBaseElevation;
      }
    }

    // 4. Jeśli etap nie kończy się na szczycie, dodajemy finisz na płaskim w dolinie
    if (!isSummitFinish) {
      final double finalSprintLen = math.max(3.0, distanceKm - currentKm);
      segments.add(
        StageSegment(
          index: segmentIndex++,
          startKm: double.parse(currentKm.toStringAsFixed(2)),
          lengthKm: double.parse(finalSprintLen.toStringAsFixed(2)),
          startElevationM: double.parse(currentElevation.toStringAsFixed(1)),
          endElevationM: double.parse(currentElevation.toStringAsFixed(1)),
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 50.0,
          windDirectionDegrees: windDirectionDegrees,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.finishLine,
        ),
      );
    }

    return RaceStage(
      id: id,
      stageNumber: stageNumber,
      name: name,
      stageType: isSummitFinish ? StageType.summitFinish : StageType.highMountain,
      segments: segments,
      baseTemperatureCelsius: baseTemperatureCelsius,
      weatherCondition: weatherCondition,
      windSpeedKmh: windSpeedKmh,
    );
  }

  /// Buduje wiosenny klasyk brukowy (Cobbled Classic – Ronde van Vlaanderen lub Paris-Roubaix).
  static RaceStage buildCobbledClassicStage({
    required String id,
    required int stageNumber,
    required String name,
    required double distanceKm,
    required List<ClimbPreset> sectors,
    double baseElevationM = 25.0,
    double baseTemperatureCelsius = 11.0,
    WeatherCondition weatherCondition = WeatherCondition.overcast,
    double windSpeedKmh = 26.0, // Silny wiatr sprzyjający rantowaniu!
  }) {
    if (sectors.isEmpty) {
      throw ArgumentError('Klasyk brukowy wymaga co najmniej jednego sektora.');
    }

    final List<StageSegment> segments = [];
    int segmentIndex = 0;
    double currentKm = 0.0;
    double currentElevation = baseElevationM;

    // Pierwsze 80-100 km klasyka to zazwyczaj płaski dojazd po asfalcie
    // z częstymi zmianami kierunku (ranty / echelons).
    final double initialRunInKm = math.min(90.0, distanceKm * 0.4);
    const int runInSegmentsCount = 3;
    final double runInSegmentLen = initialRunInKm / runInSegmentsCount;

    for (int r = 0; r < runInSegmentsCount; r++) {
      final double endElev = currentElevation + (r % 2 == 0 ? 15.0 : -10.0);
      segments.add(
        StageSegment(
          index: segmentIndex++,
          startKm: double.parse(currentKm.toStringAsFixed(2)),
          lengthKm: double.parse(runInSegmentLen.toStringAsFixed(2)),
          startElevationM: double.parse(currentElevation.toStringAsFixed(1)),
          endElevationM: double.parse(endElev.toStringAsFixed(1)),
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 30.0,
          windDirectionDegrees: 240.0,
          roadBearingDegrees: (r * 65.0) % 360.0, // Zmiany kierunku jazdy
          sprintOrKomClassification: r == 1
              ? SegmentClassification.intermediateSprint
              : SegmentClassification.none,
        ),
      );
      currentKm += runInSegmentLen;
      currentElevation = endElev;
    }

    // Dystans pozostały na sektory i asfaltowe łączniki
    final double remainingKm = math.max(20.0, distanceKm - currentKm - 8.0);
    final double connectingAsphaltLen = remainingKm / sectors.length;

    for (int s = 0; s < sectors.length; s++) {
      final sector = sectors[s];

      // Asfaltowy łącznik przed sektorem
      final double asphaltLen = double.parse(
        math.max(3.0, connectingAsphaltLen - sector.totalLengthKm).toStringAsFixed(2),
      );
      final double asphaltEndElev = sector.baseElevationM;

      segments.add(
        StageSegment(
          index: segmentIndex++,
          startKm: double.parse(currentKm.toStringAsFixed(2)),
          lengthKm: asphaltLen,
          startElevationM: double.parse(currentElevation.toStringAsFixed(1)),
          endElevationM: double.parse(asphaltEndElev.toStringAsFixed(1)),
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 45.0, // Walka o pozycję przed wjazdem na sektor
          windDirectionDegrees: 240.0,
          roadBearingDegrees: 180.0,
          sprintOrKomClassification: SegmentClassification.none,
        ),
      );
      currentKm += asphaltLen;
      currentElevation = asphaltEndElev;

      // Sektor brukowy z podziałem na pitche
      for (int p = 0; p < sector.pitches.length; p++) {
        final pitch = sector.pitches[p];
        final double pitchGain = pitch.elevationGainM;
        final double pitchEndElev = currentElevation + pitchGain;

        segments.add(
          StageSegment(
            index: segmentIndex++,
            startKm: double.parse(currentKm.toStringAsFixed(2)),
            lengthKm: double.parse(pitch.lengthKm.toStringAsFixed(2)),
            startElevationM: double.parse(currentElevation.toStringAsFixed(1)),
            endElevationM: double.parse(pitchEndElev.toStringAsFixed(1)),
            surfaceType: pitch.surfaceType,
            technicalDifficulty: pitch.technicalDifficulty,
            windDirectionDegrees: 240.0,
            roadBearingDegrees: sector.typicalRoadBearingDegrees,
            sprintOrKomClassification: (p == sector.pitches.length - 1)
                ? sector.classification
                : pitch.sprintOrKomClassification,
          ),
        );
        currentKm += pitch.lengthKm;
        currentElevation = pitchEndElev;
      }
    }

    // Finałowe kilometry do mety (np. welodrom w Roubaix lub prosta w Oudenaarde)
    final double finishRunInKm = math.max(4.0, distanceKm - currentKm);
    segments.add(
      StageSegment(
        index: segmentIndex++,
        startKm: double.parse(currentKm.toStringAsFixed(2)),
        lengthKm: double.parse(finishRunInKm.toStringAsFixed(2)),
        startElevationM: double.parse(currentElevation.toStringAsFixed(1)),
        endElevationM: baseElevationM,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 65.0,
        windDirectionDegrees: 240.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.finishLine,
      ),
    );

    return RaceStage(
      id: id,
      stageNumber: stageNumber,
      name: name,
      stageType: StageType.cobbleClassic,
      segments: segments,
      baseTemperatureCelsius: baseTemperatureCelsius,
      weatherCondition: weatherCondition,
      windSpeedKmh: windSpeedKmh,
    );
  }

  /// Buduje pagórkowaty klasyk ardeński (Ardennes Classic – np. Flèche Wallonne lub Liège).
  static RaceStage buildArdennesClassicStage({
    required String id,
    required int stageNumber,
    required String name,
    required double distanceKm,
    required List<ClimbPreset> cotes,
    ClimbPreset? finishClimb,
    double baseElevationM = 100.0,
    double baseTemperatureCelsius = 15.0,
    WeatherCondition weatherCondition = WeatherCondition.overcast,
    double windSpeedKmh = 18.0,
  }) {
    final List<StageSegment> segments = [];
    int segmentIndex = 0;
    double currentKm = 0.0;
    double currentElevation = baseElevationM;

    final allClimbs = [...cotes];
    if (finishClimb != null) {
      allClimbs.add(finishClimb);
    }

    final double availableTransitionKm =
        math.max(20.0, distanceKm - allClimbs.fold(0.0, (sum, c) => sum + c.totalLengthKm));
    final double transitionLen = availableTransitionKm / (allClimbs.length + 1);

    for (int i = 0; i < allClimbs.length; i++) {
      final cote = allClimbs[i];
      final bool isFinalClimb = i == allClimbs.length - 1 && finishClimb != null;

      // Dojazd asfaltowy
      final double transLen = double.parse(math.max(4.0, transitionLen).toStringAsFixed(2));
      final double transEndElev = cote.baseElevationM;

      segments.add(
        StageSegment(
          index: segmentIndex++,
          startKm: double.parse(currentKm.toStringAsFixed(2)),
          lengthKm: transLen,
          startElevationM: double.parse(currentElevation.toStringAsFixed(1)),
          endElevationM: double.parse(transEndElev.toStringAsFixed(1)),
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 40.0,
          windDirectionDegrees: 180.0,
          roadBearingDegrees: 45.0,
          sprintOrKomClassification: (i == 2)
              ? SegmentClassification.intermediateSprint
              : SegmentClassification.none,
        ),
      );
      currentKm += transLen;
      currentElevation = transEndElev;

      // Odcinki podjazdu
      for (int p = 0; p < cote.pitches.length; p++) {
        final pitch = cote.pitches[p];
        final bool isLastPitch = p == cote.pitches.length - 1;
        final double pitchGain = pitch.elevationGainM;
        final double pitchEndElev = currentElevation + pitchGain;

        SegmentClassification classif = pitch.sprintOrKomClassification;
        if (isLastPitch) {
          classif = isFinalClimb ? SegmentClassification.finishLine : cote.classification;
        }

        segments.add(
          StageSegment(
            index: segmentIndex++,
            startKm: double.parse(currentKm.toStringAsFixed(2)),
            lengthKm: double.parse(pitch.lengthKm.toStringAsFixed(2)),
            startElevationM: double.parse(currentElevation.toStringAsFixed(1)),
            endElevationM: double.parse(pitchEndElev.toStringAsFixed(1)),
            surfaceType: pitch.surfaceType,
            technicalDifficulty: pitch.technicalDifficulty,
            windDirectionDegrees: 180.0,
            roadBearingDegrees: cote.typicalRoadBearingDegrees,
            sprintOrKomClassification: classif,
          ),
        );
        currentKm += pitch.lengthKm;
        currentElevation = pitchEndElev;
      }
    }

    // Jeśli finisz nie był na szczycie, dodajemy płaski lub zjazdowy dojazd do mety
    if (finishClimb == null) {
      final double finalKm = math.max(3.0, distanceKm - currentKm);
      segments.add(
        StageSegment(
          index: segmentIndex++,
          startKm: double.parse(currentKm.toStringAsFixed(2)),
          lengthKm: double.parse(finalKm.toStringAsFixed(2)),
          startElevationM: double.parse(currentElevation.toStringAsFixed(1)),
          endElevationM: baseElevationM,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 55.0,
          windDirectionDegrees: 180.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.finishLine,
        ),
      );
    }

    return RaceStage(
      id: id,
      stageNumber: stageNumber,
      name: name,
      stageType: finishClimb != null ? StageType.summitFinish : StageType.hilly,
      segments: segments,
      baseTemperatureCelsius: baseTemperatureCelsius,
      weatherCondition: weatherCondition,
      windSpeedKmh: windSpeedKmh,
    );
  }

  /// Buduje płaski etap sprinterski z realistycznym podziałem na strefy wiatru
  /// i nerwowy finisz chroniony regułą 3 kilometrów.
  static RaceStage buildFlatSprintStage({
    required String id,
    required int stageNumber,
    required String name,
    required double distanceKm,
    double baseElevationM = 40.0,
    double windSpeedKmh = 22.0,
    double windDirectionDegrees = 270.0,
    WeatherCondition weatherCondition = WeatherCondition.sunny,
    bool includesCrosswindZone = false,
  }) {
    final List<StageSegment> segments = [];
    int segmentIndex = 0;
    double currentKm = 0.0;
    double currentElevation = baseElevationM;

    // Płaski etap dzielimy na 6-8 segmentów
    final int count = math.max(5, (distanceKm / 28.0).round());
    final double segLen = distanceKm / count;

    for (int i = 0; i < count; i++) {
      // Delikatne falowanie terenu (±15m)
      final double endElev = math.max(10.0, currentElevation + (i % 2 == 0 ? 12.0 : -10.0));

      // Jeśli włączono strefę wiatru bocznego, segment w połowie etapu ma kąt 90° do wiatru
      double roadBearing = 90.0;
      double technicalDiff = 25.0;
      SegmentClassification classif = SegmentClassification.none;

      if (i == (count ~/ 2)) {
        classif = SegmentClassification.intermediateSprint;
      }

      if (includesCrosswindZone && i == count - 3) {
        // Czysty boczny wiatr (Crosswind) pod kątem 90° do wiatru 270° -> azymut 0° lub 180°
        roadBearing = 0.0;
        technicalDiff = 45.0; // Nerwowość w peletonie
      }

      // Ostatni segment (strefa finiszowa)
      if (i == count - 1) {
        classif = SegmentClassification.finishLine;
        technicalDiff = 60.0; // Ronda, barierki, zwężenia jezdni
      }

      segments.add(
        StageSegment(
          index: segmentIndex++,
          startKm: double.parse(currentKm.toStringAsFixed(2)),
          lengthKm: double.parse(segLen.toStringAsFixed(2)),
          startElevationM: double.parse(currentElevation.toStringAsFixed(1)),
          endElevationM: double.parse(endElev.toStringAsFixed(1)),
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: technicalDiff,
          windDirectionDegrees: windDirectionDegrees,
          roadBearingDegrees: roadBearing,
          sprintOrKomClassification: classif,
        ),
      );
      currentKm += segLen;
      currentElevation = endElev;
    }

    return RaceStage(
      id: id,
      stageNumber: stageNumber,
      name: name,
      stageType: StageType.flat,
      segments: segments,
      baseTemperatureCelsius: 24.0,
      weatherCondition: weatherCondition,
      windSpeedKmh: windSpeedKmh,
    );
  }

  /// Buduje etap jazdy indywidualnej na czas (ITT)
  static RaceStage buildTimeTrialStage({
    required String id,
    required int stageNumber,
    required String name,
    required double distanceKm,
    ClimbPreset? intermediateClimb,
    double startElevationM = 50.0,
    double windSpeedKmh = 14.0,
  }) {
    final List<StageSegment> segments = [];
    int segmentIndex = 0;
    double currentKm = 0.0;
    double currentElevation = startElevationM;

    if (intermediateClimb != null) {
      // Czasówka z podjazdem (np. La Planche des Belles Filles lub Col d'Èze)
      final double flatApproachKm = math.max(5.0, (distanceKm - intermediateClimb.totalLengthKm) * 0.5);

      // Dojazd płaski do pomiaru czasu 1
      segments.add(
        StageSegment(
          index: segmentIndex++,
          startKm: double.parse(currentKm.toStringAsFixed(2)),
          lengthKm: double.parse(flatApproachKm.toStringAsFixed(2)),
          startElevationM: currentElevation,
          endElevationM: intermediateClimb.baseElevationM,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 35.0,
          windDirectionDegrees: 180.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.intermediateSprint, // 1. punkt pomiaru czasu
        ),
      );
      currentKm += flatApproachKm;
      currentElevation = intermediateClimb.baseElevationM;

      // Podjazd na czasówce
      for (int p = 0; p < intermediateClimb.pitches.length; p++) {
        final pitch = intermediateClimb.pitches[p];
        final double pitchGain = pitch.elevationGainM;
        final double pitchEndElev = currentElevation + pitchGain;

        segments.add(
          StageSegment(
            index: segmentIndex++,
            startKm: double.parse(currentKm.toStringAsFixed(2)),
            lengthKm: double.parse(pitch.lengthKm.toStringAsFixed(2)),
            startElevationM: double.parse(currentElevation.toStringAsFixed(1)),
            endElevationM: double.parse(pitchEndElev.toStringAsFixed(1)),
            surfaceType: pitch.surfaceType,
            technicalDifficulty: pitch.technicalDifficulty,
            windDirectionDegrees: 180.0,
            roadBearingDegrees: intermediateClimb.typicalRoadBearingDegrees,
            sprintOrKomClassification: (p == intermediateClimb.pitches.length - 1)
                ? SegmentClassification.finishLine
                : SegmentClassification.none,
          ),
        );
        currentKm += pitch.lengthKm;
        currentElevation = pitchEndElev;
      }
    } else {
      // Klasyczna płaska/pofałdowana próba czasowa z 4 sektorami (2 pomiary czasu)
      const int segmentCount = 4;
      final double segLen = distanceKm / segmentCount;

      for (int i = 0; i < segmentCount; i++) {
        final double endElev = currentElevation + (i == 1 ? 30.0 : (i == 2 ? -25.0 : 5.0));
        SegmentClassification classif = SegmentClassification.none;

        if (i == 1 || i == 2) {
          classif = SegmentClassification.intermediateSprint; // Pomiar czasu
        } else if (i == segmentCount - 1) {
          classif = SegmentClassification.finishLine;
        }

        segments.add(
          StageSegment(
            index: segmentIndex++,
            startKm: double.parse(currentKm.toStringAsFixed(2)),
            lengthKm: double.parse(segLen.toStringAsFixed(2)),
            startElevationM: double.parse(currentElevation.toStringAsFixed(1)),
            endElevationM: double.parse(endElev.toStringAsFixed(1)),
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 40.0,
            windDirectionDegrees: 90.0,
            roadBearingDegrees: (i % 2 == 0) ? 90.0 : 270.0, // Trasa z nawrotem
            sprintOrKomClassification: classif,
          ),
        );
        currentKm += segLen;
        currentElevation = endElev;
      }
    }

    return RaceStage(
      id: id,
      stageNumber: stageNumber,
      name: name,
      stageType: StageType.individualTimeTrial,
      segments: segments,
      baseTemperatureCelsius: 22.0,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: windSpeedKmh,
    );
  }

  /// Wzbogaca bazowy etap o autentyczne segmenty ze znanych podjazdów lub bruków.
  static RaceStage enrichStageWithAuthenticProfile(
    RaceStage stage, {
    List<ClimbPreset>? customClimbs,
  }) {
    // Jeżeli etap już ma szczegółowe segmenty z presetów (powyżej 8 segmentów), zwracamy bez zmian
    if (stage.segments.length >= 8 && customClimbs == null) {
      return stage;
    }

    switch (stage.stageType) {
      case StageType.highMountain:
      case StageType.summitFinish:
        final climbsToUse = customClimbs ??
            (stage.name.toLowerCase().contains('alpe')
                ? [alpeDHuez]
                : (stage.name.toLowerCase().contains('tourmalet')
                    ? [tourmalet]
                    : (stage.name.toLowerCase().contains('stelvio')
                        ? [stelvio]
                        : (stage.name.toLowerCase().contains('angliru')
                            ? [angliru]
                            : [galibier, alpeDHuez]))));

        return buildHighMountainStage(
          id: stage.id,
          stageNumber: stage.stageNumber,
          name: stage.name,
          distanceKm: stage.totalDistanceKm,
          climbs: climbsToUse,
          isSummitFinish: stage.stageType == StageType.summitFinish,
          baseTemperatureCelsius: stage.baseTemperatureCelsius,
          weatherCondition: stage.weatherCondition,
          windSpeedKmh: stage.windSpeedKmh,
        );

      case StageType.cobbleClassic:
        final sectors = customClimbs ??
            (stage.name.toLowerCase().contains('roubaix') || stage.name.toLowerCase().contains('hell')
                ? getParisRoubaixSectors()
                : getFlemishBergs());

        return buildCobbledClassicStage(
          id: stage.id,
          stageNumber: stage.stageNumber,
          name: stage.name,
          distanceKm: stage.totalDistanceKm,
          sectors: sectors,
          baseTemperatureCelsius: stage.baseTemperatureCelsius,
          weatherCondition: stage.weatherCondition,
          windSpeedKmh: stage.windSpeedKmh,
        );

      case StageType.hilly:
        final walls = customClimbs ?? getArdennesWalls();
        return buildArdennesClassicStage(
          id: stage.id,
          stageNumber: stage.stageNumber,
          name: stage.name,
          distanceKm: stage.totalDistanceKm,
          cotes: walls,
          baseTemperatureCelsius: stage.baseTemperatureCelsius,
          weatherCondition: stage.weatherCondition,
          windSpeedKmh: stage.windSpeedKmh,
        );

      case StageType.flat:
        return buildFlatSprintStage(
          id: stage.id,
          stageNumber: stage.stageNumber,
          name: stage.name,
          distanceKm: stage.totalDistanceKm,
          windSpeedKmh: stage.windSpeedKmh,
          weatherCondition: stage.weatherCondition,
        );

      case StageType.individualTimeTrial:
      case StageType.teamTimeTrial:
        return buildTimeTrialStage(
          id: stage.id,
          stageNumber: stage.stageNumber,
          name: stage.name,
          distanceKm: stage.totalDistanceKm,
          windSpeedKmh: stage.windSpeedKmh,
        );
    }
  }
}

