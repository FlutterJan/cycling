import 'dart:math' as math;

class RiderPowerProfile {
  final int watts5s;
  final int watts15s;
  final int watts30s;
  final int watts1m;
  final int watts3m;
  final int watts5m;
  final int watts20m;
  final int watts60m;

  const RiderPowerProfile({
    required this.watts5s,
    required this.watts15s,
    required this.watts30s,
    required this.watts1m,
    required this.watts3m,
    required this.watts5m,
    required this.watts20m,
    required this.watts60m,
  });

  int get p5sWatts => watts5s;
  int get power5sWatts => watts5s;
  int get p15sWatts => watts15s;
  int get p30sWatts => watts30s;
  int get p1mWatts => watts1m;
  int get p3mWatts => watts3m;
  int get p5mWatts => watts5m;
  int get p20mWatts => watts20m;
  int get p60mWatts => watts60m;
  int get functionalThresholdPowerWatts => watts60m;

  /// Szacuje maksymalną moc kolarza (Mean Maximal Power) dla zadanego czasu trwania [seconds].
  /// Wykorzystuje interpolację logarytmiczną w dziedzinie ln(czasu) pomiędzy punktami pomiarowymi.
  double getMaxPowerForDuration(int seconds) {
    if (seconds <= 0) return watts5s.toDouble();
    if (seconds <= 5) return watts5s.toDouble();

    final points = <_PowerPoint>[
      _PowerPoint(5, watts5s.toDouble()),
      _PowerPoint(15, watts15s.toDouble()),
      _PowerPoint(30, watts30s.toDouble()),
      _PowerPoint(60, watts1m.toDouble()),
      _PowerPoint(180, watts3m.toDouble()),
      _PowerPoint(300, watts5m.toDouble()),
      _PowerPoint(1200, watts20m.toDouble()),
      _PowerPoint(3600, watts60m.toDouble()),
    ];

    if (seconds >= points.last.seconds) {
      // Ekstrapolacja ponad 1h w oparciu o spadek wydolności tlenowej wg modelu Riegela
      final p1 = points[points.length - 2];
      final p2 = points.last;
      final logSlope = (p2.watts - p1.watts) / (math.log(p2.seconds) - math.log(p1.seconds));
      final extrapolated = p2.watts + logSlope * (math.log(seconds) - math.log(p2.seconds));
      return math.max(100.0, extrapolated);
    }

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      if (seconds >= p1.seconds && seconds <= p2.seconds) {
        final lnT = math.log(seconds.toDouble());
        final lnT1 = math.log(p1.seconds.toDouble());
        final lnT2 = math.log(p2.seconds.toDouble());

        final fraction = (lnT - lnT1) / (lnT2 - lnT1);
        return p1.watts + fraction * (p2.watts - p1.watts);
      }
    }

    return watts60m.toDouble();
  }

  RiderPowerProfile copyWith({
    int? watts5s,
    int? watts15s,
    int? watts30s,
    int? watts1m,
    int? watts3m,
    int? watts5m,
    int? watts20m,
    int? watts60m,
    int? functionalThresholdPowerWatts,
  }) {
    return RiderPowerProfile(
      watts5s: watts5s ?? this.watts5s,
      watts15s: watts15s ?? this.watts15s,
      watts30s: watts30s ?? this.watts30s,
      watts1m: watts1m ?? this.watts1m,
      watts3m: watts3m ?? this.watts3m,
      watts5m: watts5m ?? this.watts5m,
      watts20m: watts20m ?? this.watts20m,
      watts60m: functionalThresholdPowerWatts ?? watts60m ?? this.watts60m,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'watts5s': watts5s,
      'watts15s': watts15s,
      'watts30s': watts30s,
      'watts1m': watts1m,
      'watts3m': watts3m,
      'watts5m': watts5m,
      'watts20m': watts20m,
      'watts60m': watts60m,
    };
  }

  factory RiderPowerProfile.fromJson(Map<String, dynamic> json) {
    return RiderPowerProfile(
      watts5s: (json['watts5s'] as num).toInt(),
      watts15s: (json['watts15s'] as num).toInt(),
      watts30s: (json['watts30s'] as num).toInt(),
      watts1m: (json['watts1m'] as num).toInt(),
      watts3m: (json['watts3m'] as num).toInt(),
      watts5m: (json['watts5m'] as num).toInt(),
      watts20m: (json['watts20m'] as num).toInt(),
      watts60m: (json['watts60m'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiderPowerProfile &&
        other.watts5s == watts5s &&
        other.watts15s == watts15s &&
        other.watts30s == watts30s &&
        other.watts1m == watts1m &&
        other.watts3m == watts3m &&
        other.watts5m == watts5m &&
        other.watts20m == watts20m &&
        other.watts60m == watts60m;
  }

  @override
  int get hashCode {
    return Object.hash(
      watts5s,
      watts15s,
      watts30s,
      watts1m,
      watts3m,
      watts5m,
      watts20m,
      watts60m,
    );
  }

  @override
  String toString() {
    return 'RiderPowerProfile(5s: ${watts5s}W, 15s: ${watts15s}W, 30s: ${watts30s}W, 1m: ${watts1m}W, 3m: ${watts3m}W, 5m: ${watts5m}W, 20m: ${watts20m}W, 60m: ${watts60m}W)';
  }
}

class _PowerPoint {
  final int seconds;
  final double watts;

  const _PowerPoint(this.seconds, this.watts);
}

