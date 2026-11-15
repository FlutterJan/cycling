class RiderSkills {
  final int cobbles;
  final int descending;
  final int bikeHandling;
  final int aeroPositioning;
  final int draftingEfficiency;
  final int raceIq;
  final int rainResistance;
  final int heatTolerance;
  final int timeTrialPositioning;

  const RiderSkills({
    required this.cobbles,
    required this.descending,
    required this.bikeHandling,
    required this.aeroPositioning,
    required this.draftingEfficiency,
    required this.raceIq,
    required this.rainResistance,
    required this.heatTolerance,
    required this.timeTrialPositioning,
  });

  /// Ocena dynamiki na krótkich podjazdach / pagórkach (Punch)
  int get punch => ((raceIq * 0.5) + (bikeHandling * 0.5)).round();

  /// Średnia ogólna umiejętności technicznych kolarza (Overall Technical Score)
  double get overallTechnicalSkill {
    return (cobbles +
            descending +
            bikeHandling +
            aeroPositioning +
            draftingEfficiency +
            raceIq +
            rainResistance +
            heatTolerance +
            timeTrialPositioning) /
        9.0;
  }

  /// Mnożnik redukcji oporu w tunelu aero w oparciu o draftingEfficiency [0.85 - 1.15]
  double get draftingBonusMultiplier {
    return 1.0 + ((draftingEfficiency - 50) / 100.0) * 0.3;
  }

  /// Mnożnik redukcji bazowego CdA w oparciu o aeroPositioning [0.90 - 1.10]
  double get cdaModifier {
    return 1.0 - ((aeroPositioning - 50) / 100.0) * 0.15;
  }

  /// Mnożnik prędkości na zjazdach w oparciu o descending i bikeHandling
  double get descendingSpeedMultiplier {
    final avg = (descending * 0.7) + (bikeHandling * 0.3);
    return 0.85 + (avg / 100.0) * 0.30;
  }

  RiderSkills copyWith({
    int? cobbles,
    int? descending,
    int? bikeHandling,
    int? aeroPositioning,
    int? draftingEfficiency,
    int? raceIq,
    int? rainResistance,
    int? heatTolerance,
    int? timeTrialPositioning,
  }) {
    return RiderSkills(
      cobbles: cobbles ?? this.cobbles,
      descending: descending ?? this.descending,
      bikeHandling: bikeHandling ?? this.bikeHandling,
      aeroPositioning: aeroPositioning ?? this.aeroPositioning,
      draftingEfficiency: draftingEfficiency ?? this.draftingEfficiency,
      raceIq: raceIq ?? this.raceIq,
      rainResistance: rainResistance ?? this.rainResistance,
      heatTolerance: heatTolerance ?? this.heatTolerance,
      timeTrialPositioning: timeTrialPositioning ?? this.timeTrialPositioning,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cobbles': cobbles,
      'descending': descending,
      'bikeHandling': bikeHandling,
      'aeroPositioning': aeroPositioning,
      'draftingEfficiency': draftingEfficiency,
      'raceIq': raceIq,
      'rainResistance': rainResistance,
      'heatTolerance': heatTolerance,
      'timeTrialPositioning': timeTrialPositioning,
    };
  }

  factory RiderSkills.fromJson(Map<String, dynamic> json) {
    return RiderSkills(
      cobbles: (json['cobbles'] as num).toInt(),
      descending: (json['descending'] as num).toInt(),
      bikeHandling: (json['bikeHandling'] as num).toInt(),
      aeroPositioning: (json['aeroPositioning'] as num).toInt(),
      draftingEfficiency: (json['draftingEfficiency'] as num).toInt(),
      raceIq: (json['raceIq'] as num).toInt(),
      rainResistance: (json['rainResistance'] as num).toInt(),
      heatTolerance: (json['heatTolerance'] as num).toInt(),
      timeTrialPositioning: (json['timeTrialPositioning'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiderSkills &&
        other.cobbles == cobbles &&
        other.descending == descending &&
        other.bikeHandling == bikeHandling &&
        other.aeroPositioning == aeroPositioning &&
        other.draftingEfficiency == draftingEfficiency &&
        other.raceIq == raceIq &&
        other.rainResistance == rainResistance &&
        other.heatTolerance == heatTolerance &&
        other.timeTrialPositioning == timeTrialPositioning;
  }

  @override
  int get hashCode {
    return Object.hash(
      cobbles,
      descending,
      bikeHandling,
      aeroPositioning,
      draftingEfficiency,
      raceIq,
      rainResistance,
      heatTolerance,
      timeTrialPositioning,
    );
  }

  @override
  String toString() {
    return 'RiderSkills(cobbles: $cobbles, descending: $descending, handling: $bikeHandling, aero: $aeroPositioning, drafting: $draftingEfficiency, IQ: $raceIq, rain: $rainResistance, heat: $heatTolerance, TT: $timeTrialPositioning)';
  }
}

