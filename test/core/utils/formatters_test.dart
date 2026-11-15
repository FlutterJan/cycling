import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/utils/formatters.dart';

void main() {
  group('Formatters - Czas wyścigu (HH:MM:SS)', () {
    test('formatRaceTime z domyślnym formatem HH:MM:SS', () {
      expect(Formatters.formatRaceTime(0), equals('00:00:00'));
      expect(Formatters.formatRaceTime(14), equals('00:00:14'));
      expect(Formatters.formatRaceTime(65), equals('00:01:05'));
      expect(Formatters.formatRaceTime(3600), equals('01:00:00'));
      expect(Formatters.formatRaceTime(3674), equals('01:01:14'));
      expect(Formatters.formatRaceTime(15155), equals('04:12:35'));
    });

    test('formatRaceTime z ukrywaniem godzin gdy showHoursAlways = false', () {
      expect(Formatters.formatRaceTime(14, showHoursAlways: false), equals('00:14'));
      expect(Formatters.formatRaceTime(74, showHoursAlways: false), equals('01:14'));
      expect(Formatters.formatRaceTime(3674, showHoursAlways: false), equals('01:01:14'));
    });

    test('formatDuration dla obiektu Duration', () {
      const dur = Duration(hours: 3, minutes: 45, seconds: 12);
      expect(Formatters.formatDuration(dur), equals('03:45:12'));
      expect(dur.toRaceTime(), equals('03:45:12'));
    });

    test('Obsługa wartości brzegowych w czasie wyścigu (NaN, ujemne)', () {
      expect(Formatters.formatRaceTime(double.nan), equals('00:00:00'));
      expect(Formatters.formatRaceTime(-10), equals('00:00:00'));
      expect(Formatters.formatRaceTime(-10, allowNegative: true), equals('-00:00:10'));
    });
  });

  group('Formatters - Różnice czasowe (+0\'14")', () {
    test('Formatowanie kolarskich strat w formacie standardowym TV', () {
      expect(Formatters.formatTimeGap(14), equals('+0\'14"'));
      expect(Formatters.formatTimeGap(5), equals('+0\'05"'));
      expect(Formatters.formatTimeGap(74), equals('+1\'14"'));
      expect(Formatters.formatTimeGap(3674), equals('+1h 01\'14"'));
    });

    test('Zerowa różnica czasowa i opcjonalny label', () {
      expect(Formatters.formatTimeGap(0), equals('0\'00"'));
      expect(Formatters.formatTimeGap(0, sameTimeLabel: 'ten sam czas'), equals('ten sam czas'));
      expect(Formatters.formatTimeGap(0, sameTimeLabel: 's.t.'), equals('s.t.'));
    });

    test('Ujemna różnica czasowa (przewaga w ITT)', () {
      expect(Formatters.formatTimeGap(-14), equals('-0\'14"'));
      expect(Formatters.formatTimeGap(-74), equals('-1\'14"'));
      expect(Formatters.formatTimeGap(-3674), equals('-1h 01\'14"'));
    });

    test('Flaga showPlusSign = false', () {
      expect(Formatters.formatTimeGap(14, showPlusSign: false), equals('0\'14"'));
      expect(Formatters.formatTimeGap(74, showPlusSign: false), equals('1\'14"'));
    });

    test('Klasyczny format z dwukropkiem (formatTimeGapColon)', () {
      expect(Formatters.formatTimeGapColon(14), equals('+00:14'));
      expect(Formatters.formatTimeGapColon(74), equals('+01:14'));
      expect(Formatters.formatTimeGapColon(3674), equals('+01:01:14'));
    });
  });

  group('Formatters - Waluty (€1,250,000)', () {
    test('formatCurrency z separatorem tysięcy i symbolem Euro', () {
      expect(Formatters.formatCurrency(1250000), equals('€1,250,000'));
      expect(Formatters.formatCurrency(0), equals('€0'));
      expect(Formatters.formatCurrency(500), equals('€500'));
      expect(Formatters.formatCurrency(24500000), equals('€24,500,000'));
      expect(Formatters.formatCurrency(-50000), equals('-€50,000'));
    });

    test('formatCurrency z groszami/centami (showDecimals: true)', () {
      expect(Formatters.formatCurrency(1250000.5, showDecimals: true), equals('€1,250,000.50'));
      expect(Formatters.formatCurrency(99.99, showDecimals: true), equals('€99.99'));
    });

    test('formatCompactCurrency (skrótowe kwoty budżetowe)', () {
      expect(Formatters.formatCompactCurrency(1250000), equals('€1.25M'));
      expect(Formatters.formatCompactCurrency(450000), equals('€450k'));
      expect(Formatters.formatCompactCurrency(850), equals('€850'));
      expect(Formatters.formatCompactCurrency(-1500000), equals('-€1.5M'));
    });
  });

  group('Formatters - Moc kolarska (415 W (6.1 W/kg))', () {
    test('formatPower z masą kolarza', () {
      // 415 / 68.0 = 6.1029... -> 6.1 W/kg
      expect(Formatters.formatPower(415, 68.0), equals('415 W (6.1 W/kg)'));
      // Z większą precyzją W/kg
      expect(Formatters.formatPower(415, 68.0, 0, 2), equals('415 W (6.10 W/kg)'));
    });

    test('formatPower bez masy kolarza', () {
      expect(Formatters.formatPower(415), equals('415 W'));
      expect(Formatters.formatPower(415, null), equals('415 W'));
      expect(Formatters.formatPower(415, 0), equals('415 W'));
    });

    test('formatWatts oraz formatWattsPerKg', () {
      expect(Formatters.formatWatts(415), equals('415 W'));
      expect(Formatters.formatWatts(415.4, decimals: 1), equals('415.4 W'));
      expect(Formatters.formatWattsPerKg(6.1), equals('6.1 W/kg'));
      expect(Formatters.formatWattsPerKg(6.125, decimalDigits: 2), equals('6.13 W/kg'));
    });
  });

  group('Formatters - Nachylenie trasy (8.4%)', () {
    test('formatGradient z wartościami standardowymi', () {
      expect(Formatters.formatGradient(8.4), equals('8.4%'));
      expect(Formatters.formatGradient(0.0), equals('0.0%'));
      expect(Formatters.formatGradient(-5.2), equals('-5.2%'));
    });

    test('formatGradient z wymuszonym znakiem (showSign: true)', () {
      expect(Formatters.formatGradient(8.4, showSign: true), equals('+8.4%'));
      expect(Formatters.formatGradient(-5.2, showSign: true), equals('-5.2%'));
      expect(Formatters.formatGradient(0.0, showSign: true), equals('0.0%'));
    });

    test('formatElevationGain w metrach', () {
      expect(Formatters.formatElevationGain(1450), equals('1,450 m'));
      expect(Formatters.formatElevationGain(1450, showSign: true), equals('+1,450 m'));
      expect(Formatters.formatElevationGain(-320), equals('-320 m'));
    });
  });

  group('Formatters - Wagi sprzętu (6.82 kg) i limit UCI', () {
    test('formatEquipmentWeight z wagą w kilogramach i gramach', () {
      expect(Formatters.formatEquipmentWeight(6.82), equals('6.82 kg'));
      expect(Formatters.formatEquipmentWeight(7.15), equals('7.15 kg'));
      // Wartość > 50 jest automatycznie traktowana jako gramy
      expect(Formatters.formatEquipmentWeight(6820), equals('6.82 kg'));
      expect(Formatters.formatEquipmentWeight(850, isGrams: true), equals('0.85 kg'));
    });

    test('formatWeightGrams', () {
      expect(Formatters.formatWeightGrams(850), equals('850 g'));
      expect(Formatters.formatWeightGrams(1245.5, decimalDigits: 1), equals('1245.5 g'));
    });

    test('isUciWeightLegal i formatUciWeightCompliance', () {
      expect(Formatters.isUciWeightLegal(6.82), isTrue);
      expect(Formatters.isUciWeightLegal(6.80), isTrue);
      expect(Formatters.isUciWeightLegal(6.75), isFalse);
      expect(Formatters.isUciWeightLegal(6820), isTrue);

      expect(Formatters.formatUciWeightCompliance(6.82), equals('6.82 kg (Zgodny z UCI)'));
      expect(
        Formatters.formatUciWeightCompliance(6.65),
        equals('6.65 kg (Niezgodny z UCI: -150 g poniżej limitu 6.80 kg)'),
      );
    });
  });

  group('Formatters - Dodatkowe metryki telemetryczne', () {
    test('formatSpeed, formatDistance, formatHeartRate, formatCadence', () {
      expect(Formatters.formatSpeed(45.24), equals('45.2 km/h'));
      expect(Formatters.formatDistance(184.52), equals('184.5 km'));
      expect(Formatters.formatHeartRate(168), equals('168 bpm'));
      expect(Formatters.formatCadence(92), equals('92 rpm'));
    });

    test('formatCalories, formatWorkKj, formatTsb, formatPercent', () {
      expect(Formatters.formatCalories(3450), equals('3,450 kcal'));
      expect(Formatters.formatWorkKj(2450), equals('2,450 kJ'));
      expect(Formatters.formatTsb(14.5), equals('+14.5 pkt'));
      expect(Formatters.formatTsb(-12.0), equals('-12.0 pkt'));
      expect(Formatters.formatPercent(85), equals('85%'));
      expect(Formatters.formatPercent(5.2, decimalDigits: 1, showSign: true), equals('+5.2%'));
    });
  });

  group('CyclingNumFormatters & CyclingDurationFormatters - Extensions', () {
    test('Rozszerzenia numeryczne', () {
      expect(15155.toRaceTime(), equals('04:12:35'));
      expect(14.toTimeGap(), equals('+0\'14"'));
      expect(1250000.toCurrencyEur(), equals('€1,250,000'));
      expect(1250000.toCompactCurrencyEur(), equals('€1.25M'));
      expect(415.toPower(68.0), equals('415 W (6.1 W/kg)'));
      expect(6.1.toWattsPerKg(), equals('6.1 W/kg'));
      expect(8.4.toGradient(), equals('8.4%'));
      expect(6.82.toEquipmentWeight(), equals('6.82 kg'));
      expect(45.2.toSpeed(), equals('45.2 km/h'));
      expect(184.5.toDistance(), equals('184.5 km'));
      expect(168.toHeartRate(), equals('168 bpm'));
      expect(92.toCadence(), equals('92 rpm'));
      expect(3450.toCalories(), equals('3,450 kcal'));
      expect(2450.toWorkKj(), equals('2,450 kJ'));
    });

    test('Rozszerzenia Duration', () {
      const dur = Duration(seconds: 14);
      expect(dur.toTimeGap(), equals('+0\'14"'));
    });
  });
}

