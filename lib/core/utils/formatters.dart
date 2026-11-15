import 'dart:math' as math;
import 'package:intl/intl.dart';

/// Uniwersalna klasa narzędziowa do formatowania danych kolarskich w całej aplikacji.
///
/// Obsługuje:
/// - Formatowanie czasu wyścigu (`HH:MM:SS`)
/// - Formatowanie różnic czasowych (`+0'14"`, `+1'25"`, `+1h 05'12"`)
/// - Formatowanie walut i budżetów (`€1,250,000`, `€1.25M`)
/// - Formatowanie mocy kolarskiej i watów na kilogram (`415 W (6.1 W/kg)`)
/// - Formatowanie nachylenia trasy (`8.4%`, `+8.4%`)
/// - Formatowanie wag sprzętu i rowerów (`6.82 kg`) z weryfikacją limitu UCI
/// - Dodatkowe metryki telemetryczne (prędkość, dystans, tętno, kadencja, przewyższenie)
class Formatters {
  Formatters._();

  /// Minimalna dopuszczalna masa roweru wyścigowego według regulaminu technicznego UCI [kg]
  static const double uciMinBikeWeightKg = 6.80;

  // ===========================================================================
  // 1. FORMATOWANIE CZASU WYŚCIGU (HH:MM:SS) I RÓŻNIC CZASOWYCH (+0'14")
  // ===========================================================================

  /// Formatuje łączny czas wyścigu w sekundach do postaci `HH:MM:SS` (np. `04:12:35` lub `00:00:14`).
  ///
  /// Jeśli [showHoursAlways] ma wartość `false`, a czas jest krótszy niż godzina,
  /// wynik zostanie sformatowany do `MM:SS` (np. `00:14` lub `12:35`).
  static String formatRaceTime(
    num seconds, {
    bool showHoursAlways = true,
    bool allowNegative = false,
  }) {
    if (seconds.isNaN || seconds.isInfinite) return '00:00:00';

    final isNegative = seconds < 0;
    final double rawSec = allowNegative ? seconds.abs().toDouble() : math.max(0.0, seconds.toDouble());
    final int totalSec = rawSec.round();

    final int hours = totalSec ~/ 3600;
    final int minutes = (totalSec % 3600) ~/ 60;
    final int secs = totalSec % 60;

    final String prefix = (isNegative && allowNegative) ? '-' : '';

    if (!showHoursAlways && hours == 0) {
      return '$prefix${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }

    return '$prefix${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Formatuje obiekt [Duration] do postaci `HH:MM:SS` lub `MM:SS`.
  static String formatDuration(
    Duration duration, {
    bool showHoursAlways = true,
  }) {
    return formatRaceTime(
      duration.inMilliseconds / 1000.0,
      showHoursAlways: showHoursAlways,
      allowNegative: true,
    );
  }

  /// Formatuje różnicę czasową (stratę lub przewagę) w profesjonalnym standardzie kolarskim (`+0'14"`).
  ///
  /// Przykłady formatowania:
  /// - `14.0` sekund  -> `+0'14"`
  /// - `5.0` sekund   -> `+0'05"`
  /// - `74.0` sekundy -> `+1'14"`
  /// - `3674.0` sekundy -> `+1h 01'14"`
  /// - `0.0` sekund   -> `0'00"` (lub `sameTimeLabel`, np. `ten sam czas` / `m.t.`)
  /// - `-14.0` sekund -> `-0'14"` (gdy [allowNegative] = true, np. w wirtualnym pomiarze czasu ITT)
  static String formatTimeGap(
    num gapSeconds, {
    bool showPlusSign = true,
    bool allowNegative = true,
    String? sameTimeLabel,
  }) {
    if (gapSeconds.isNaN || gapSeconds.isInfinite) return "0'00\"";

    final double roundedSec = gapSeconds.roundToDouble();

    if (roundedSec == 0.0 && sameTimeLabel != null) {
      return sameTimeLabel;
    }

    final bool isNegative = roundedSec < 0.0;
    final int totalSec = allowNegative ? roundedSec.abs().round() : math.max(0, roundedSec.round());

    final int hours = totalSec ~/ 3600;
    final int minutes = (totalSec % 3600) ~/ 60;
    final int seconds = totalSec % 60;

    String sign = '';
    if (isNegative && allowNegative) {
      sign = '-';
    } else if (showPlusSign && totalSec > 0) {
      sign = '+';
    }

    if (hours > 0) {
      return '$sign${hours}h ${minutes.toString().padLeft(2, '0')}\'${seconds.toString().padLeft(2, '0')}"';
    }

    return '$sign$minutes\'${seconds.toString().padLeft(2, '0')}"';
  }

  /// Formatuje różnicę czasową w klasycznej notacji dwukropkowej z plusem (np. `+00:14`, `+01:25`, `+01:05:12`).
  static String formatTimeGapColon(
    num gapSeconds, {
    bool showPlusSign = true,
    bool showHoursAlways = false,
  }) {
    if (gapSeconds.isNaN || gapSeconds.isInfinite) return showPlusSign ? '+00:00' : '00:00';

    final bool isNegative = gapSeconds < 0.0;
    final int totalSec = gapSeconds.abs().round();

    final int hours = totalSec ~/ 3600;
    final int minutes = (totalSec % 3600) ~/ 60;
    final int seconds = totalSec % 60;

    String sign = '';
    if (isNegative) {
      sign = '-';
    } else if (showPlusSign && totalSec > 0) {
      sign = '+';
    }

    if (showHoursAlways || hours > 0) {
      return '$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '$sign${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ===========================================================================
  // 2. FORMATOWANIE WALUT (€1,250,000)
  // ===========================================================================

  /// Formatuje kwotę pieniężną z symbolem waluty i separatorami tysięcy (np. `€1,250,000`).
  ///
  /// Obsługuje:
  /// - Dodatnie i ujemne kwoty (np. `€1,250,000` lub `-€50,000`)
  /// - Opcjonalne grosze/centy ([showDecimals] = true -> `€1,250,000.50`)
  /// - Zmianę symbolu waluty ([symbol], domyślnie `€`)
  static String formatCurrency(
    num amountEur, {
    String symbol = '€',
    bool showDecimals = false,
    int decimalDigits = 2,
    bool spaceAfterSymbol = false,
  }) {
    if (amountEur.isNaN || amountEur.isInfinite) return '${symbol}0';

    final bool isNegative = amountEur < 0;
    final num absAmount = amountEur.abs();

    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: showDecimals ? decimalDigits : 0,
      customPattern: '#,##0${showDecimals ? '.00' : ''}',
    );

    final formattedNumber = formatter.format(absAmount);
    final space = spaceAfterSymbol ? ' ' : '';
    final sign = isNegative ? '-' : '';

    return '$sign$symbol$space$formattedNumber';
  }

  /// Kompaktowe formatowanie dużych kwot budżetowych (np. `€1.25M`, `€450k`, `€850`).
  static String formatCompactCurrency(
    num amountEur, {
    String symbol = '€',
    int decimalDigits = 2,
    bool spaceAfterSymbol = false,
  }) {
    if (amountEur.isNaN || amountEur.isInfinite) return '${symbol}0';

    final bool isNegative = amountEur < 0;
    final double absVal = amountEur.abs().toDouble();
    final String sign = isNegative ? '-' : '';
    final String space = spaceAfterSymbol ? ' ' : '';

    if (absVal >= 1000000.0) {
      final millions = absVal / 1000000.0;
      final str = millions.toStringAsFixed(decimalDigits).replaceAll(RegExp(r'\.?0+$'), '');
      return '$sign$symbol$space${str}M';
    } else if (absVal >= 1000.0) {
      final thousands = absVal / 1000.0;
      final str = thousands >= 100.0
          ? thousands.round().toString()
          : thousands.toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '');
      return '$sign$symbol$space${str}k';
    }

    return '$sign$symbol$space${absVal.round()}';
  }

  // ===========================================================================
  // 3. FORMATOWANIE MOCY KOLARSKIEJ (415 W (6.1 W/kg))
  // ===========================================================================

  /// Formatuje moc kolarską wraz z opcjonalnym przelicznikiem watów na kilogram masy ciała.
  ///
  /// Przykłady:
  /// - `formatPower(415, 68.0)` -> `415 W (6.1 W/kg)`
  /// - `formatPower(415)`       -> `415 W`
  /// - `formatPower(415.4, 68.0, wKgDecimals: 2)` -> `415 W (6.11 W/kg)`
  static String formatPower(
    num watts, [
    num? weightKg,
    int wattsDecimals = 0,
    int wKgDecimals = 1,
  ]) {
    if (watts.isNaN || watts.isInfinite) return '0 W';

    final String wattsStr = wattsDecimals == 0
        ? '${watts.round()} W'
        : '${watts.toStringAsFixed(wattsDecimals)} W';

    if (weightKg != null && weightKg > 0 && !weightKg.isNaN && !weightKg.isInfinite) {
      final double wKg = watts.toDouble() / weightKg.toDouble();
      final String wKgStr = wKg.toStringAsFixed(wKgDecimals);
      return '$wattsStr ($wKgStr W/kg)';
    }

    return wattsStr;
  }

  /// Formatuje czystą moc w watach (np. `415 W`).
  static String formatWatts(num watts, {int decimals = 0}) {
    if (watts.isNaN || watts.isInfinite) return '0 W';
    if (decimals == 0) return '${watts.round()} W';
    return '${watts.toStringAsFixed(decimals)} W';
  }

  /// Formatuje współczynnik watów na kilogram (np. `6.1 W/kg` lub `6.12 W/kg`).
  static String formatWattsPerKg(
    num wKg, {
    int decimalDigits = 1,
    bool includeUnit = true,
  }) {
    if (wKg.isNaN || wKg.isInfinite) return includeUnit ? '0.0 W/kg' : '0.0';
    final str = wKg.toStringAsFixed(decimalDigits);
    return includeUnit ? '$str W/kg' : str;
  }

  // ===========================================================================
  // 4. FORMATOWANIE NACHYLENIA TRASY (8.4%)
  // ===========================================================================

  /// Formatuje nachylenie jezdni w procentach (np. `8.4%` lub `+8.4%`, `-5.2%`).
  ///
  /// Jeśli [showSign] = true, dla wartości dodatnich zostanie dodany prefiks `+`.
  static String formatGradient(
    num gradientPercent, {
    bool showSign = false,
    int decimalDigits = 1,
  }) {
    if (gradientPercent.isNaN || gradientPercent.isInfinite) return '0.0%';

    final double grad = gradientPercent.toDouble();
    final String val = grad.toStringAsFixed(decimalDigits);

    if (showSign && grad > 0.0) {
      return '+$val%';
    }

    return '$val%';
  }

  /// Formatuje przewyższenie lub sumę wzniesień w metrach (np. `1,250 m` lub `+1,250 m`).
  static String formatElevationGain(
    num meters, {
    bool showSign = false,
    String unit = 'm',
  }) {
    if (meters.isNaN || meters.isInfinite) return '0 $unit';

    final bool isNegative = meters < 0;
    final int absMeters = meters.abs().round();
    final formatter = NumberFormat('#,##0');
    final formatted = formatter.format(absMeters);

    String sign = '';
    if (isNegative) {
      sign = '-';
    } else if (showSign && absMeters > 0) {
      sign = '+';
    }

    return '$sign$formatted $unit';
  }

  // ===========================================================================
  // 5. FORMATOWANIE WAG SPRZĘTU (6.82 kg) I WERYFIKACJA LIMITU UCI
  // ===========================================================================

  /// Formatuje masę roweru, ramy lub komponentu do postaci kilogramów (np. `6.82 kg`).
  ///
  /// Parametr [weight] może być podany w kilogramach (np. `6.82`) lub w gramach
  /// (np. `6820`), przy czym wartości powyżej 50.0 są automatycznie interpretowane jako gramy.
  static String formatEquipmentWeight(
    num weight, {
    bool isGrams = false,
    int decimalDigits = 2,
    String unit = 'kg',
  }) {
    if (weight.isNaN || weight.isInfinite) return '0.00 $unit';

    final double weightKg = (isGrams || weight > 50.0)
        ? (weight.toDouble() / 1000.0)
        : weight.toDouble();

    return '${weightKg.toStringAsFixed(decimalDigits)} $unit';
  }

  /// Zwraca masę w gramach sformatowaną do postaci np. `850 g`.
  static String formatWeightGrams(num grams, {int decimalDigits = 0}) {
    if (grams.isNaN || grams.isInfinite) return '0 g';
    if (decimalDigits == 0) return '${grams.round()} g';
    return '${grams.toStringAsFixed(decimalDigits)} g';
  }

  /// Sprawdza, czy łączna masa roweru jest zgodna z minimalnym limitem technicznym UCI (6.80 kg).
  static bool isUciWeightLegal(num weightKg) {
    if (weightKg.isNaN || weightKg.isInfinite) return false;
    final double kg = weightKg > 50.0 ? weightKg / 1000.0 : weightKg.toDouble();
    return kg >= uciMinBikeWeightKg;
  }

  /// Zwraca sformatowaną masę sprzętu wraz z etykietą zgodności z regulaminem UCI.
  ///
  /// Przykłady:
  /// - `6.82` -> `6.82 kg (Zgodny z UCI)`
  /// - `6.65` -> `6.65 kg (Niezgodny z UCI: -150 g poniżej limitu 6.80 kg)`
  static String formatUciWeightCompliance(
    num weightKg, {
    int decimalDigits = 2,
  }) {
    final double kg = weightKg > 50.0 ? weightKg / 1000.0 : weightKg.toDouble();
    final String weightStr = '${kg.toStringAsFixed(decimalDigits)} kg';

    if (isUciWeightLegal(kg)) {
      return '$weightStr (Zgodny z UCI)';
    }

    final int diffGrams = ((uciMinBikeWeightKg - kg) * 1000.0).round();
    return '$weightStr (Niezgodny z UCI: -$diffGrams g poniżej limitu ${uciMinBikeWeightKg.toStringAsFixed(2)} kg)';
  }

  // ===========================================================================
  // 6. DODATKOWE METRYKI TELEMETRYCZNE I WYŚCIGOWE
  // ===========================================================================

  /// Formatuje prędkość w km/h (np. `45.2 km/h`).
  static String formatSpeed(num speedKmh, {int decimalDigits = 1}) {
    if (speedKmh.isNaN || speedKmh.isInfinite) return '0.0 km/h';
    return '${speedKmh.toStringAsFixed(decimalDigits)} km/h';
  }

  /// Formatuje dystans w kilometrach (np. `184.5 km` lub `0.8 km`).
  static String formatDistance(num distanceKm, {int decimalDigits = 1}) {
    if (distanceKm.isNaN || distanceKm.isInfinite) return '0.0 km';
    return '${distanceKm.toStringAsFixed(decimalDigits)} km';
  }

  /// Formatuje tętno w uderzeniach na minutę (np. `168 bpm`).
  static String formatHeartRate(num bpm) {
    if (bpm.isNaN || bpm.isInfinite) return '0 bpm';
    return '${bpm.round()} bpm';
  }

  /// Formatuje kadencję pedałowania w obrotach na minutę (np. `92 rpm`).
  static String formatCadence(num rpm) {
    if (rpm.isNaN || rpm.isInfinite) return '0 rpm';
    return '${rpm.round()} rpm';
  }

  /// Formatuje spalone kalorie (np. `3,450 kcal`).
  static String formatCalories(num kcal) {
    if (kcal.isNaN || kcal.isInfinite) return '0 kcal';
    final formatter = NumberFormat('#,##0');
    return '${formatter.format(kcal.round())} kcal';
  }

  /// Formatuje wykonaną pracę mechaniczną w kilodżulach (np. `2,450 kJ`).
  static String formatWorkKj(num kj, {int decimalDigits = 0}) {
    if (kj.isNaN || kj.isInfinite) return '0 kJ';
    final formatter = NumberFormat('#,##0');
    return '${formatter.format(kj.round())} kJ';
  }

  /// Formatuje wskaźnik TSB (Training Stress Balance) / Świeżość kolarza (np. `+14.5 pkt` lub `-12.0 pkt`).
  static String formatTsb(num tsb, {int decimalDigits = 1, bool includeUnit = true}) {
    if (tsb.isNaN || tsb.isInfinite) return '0.0';
    final double val = tsb.toDouble();
    final String sign = val > 0 ? '+' : '';
    final String formatted = '$sign${val.toStringAsFixed(decimalDigits)}';
    return includeUnit ? '$formatted pkt' : formatted;
  }

  /// Formatuje wartość procentową (np. `85%` lub `+5.2%`).
  static String formatPercent(
    num percent, {
    int decimalDigits = 0,
    bool showSign = false,
  }) {
    if (percent.isNaN || percent.isInfinite) return '0%';
    final double val = percent.toDouble();
    final String sign = (showSign && val > 0) ? '+' : '';
    if (decimalDigits == 0) {
      return '$sign${val.round()}%';
    }
    return '$sign${val.toStringAsFixed(decimalDigits)}%';
  }
}

/// Alias dla czytelności i semantyki w architekturze projektu
typedef CyclingFormatters = Formatters;

// =============================================================================
// ROZSZERZENIA DART DLA WYGODY PROGRAMISTY (EXTENSION METHODS)
// =============================================================================

/// Rozszerzenia ułatwiające bezpośrednie formatowanie liczb w kodzie UI i logice gry
extension CyclingNumFormatters on num {
  /// Formatowanie łącznego czasu wyścigu do `HH:MM:SS`
  String toRaceTime({bool showHoursAlways = true}) =>
      Formatters.formatRaceTime(this, showHoursAlways: showHoursAlways);

  /// Formatowanie różnicy czasowej do standardu `+0'14"`
  String toTimeGap({bool showPlusSign = true, String? sameTimeLabel}) =>
      Formatters.formatTimeGap(this, showPlusSign: showPlusSign, sameTimeLabel: sameTimeLabel);

  /// Formatowanie waluty do `€1,250,000`
  String toCurrencyEur({bool showDecimals = false}) =>
      Formatters.formatCurrency(this, showDecimals: showDecimals);

  /// Kompaktowe formatowanie waluty do `€1.25M`
  String toCompactCurrencyEur() => Formatters.formatCompactCurrency(this);

  /// Formatowanie mocy do `415 W` lub `415 W (6.1 W/kg)`
  String toPower([num? weightKg]) => Formatters.formatPower(this, weightKg);

  /// Formatowanie watów na kilogram do `6.1 W/kg`
  String toWattsPerKg({int decimalDigits = 1}) =>
      Formatters.formatWattsPerKg(this, decimalDigits: decimalDigits);

  /// Formatowanie nachylenia do `8.4%` lub `+8.4%`
  String toGradient({bool showSign = false}) =>
      Formatters.formatGradient(this, showSign: showSign);

  /// Formatowanie wagi sprzętu do `6.82 kg`
  String toEquipmentWeight({int decimalDigits = 2}) =>
      Formatters.formatEquipmentWeight(this, decimalDigits: decimalDigits);

  /// Formatowanie prędkości do `45.2 km/h`
  String toSpeed() => Formatters.formatSpeed(this);

  /// Formatowanie dystansu do `184.5 km`
  String toDistance() => Formatters.formatDistance(this);

  /// Formatowanie tętna do `168 bpm`
  String toHeartRate() => Formatters.formatHeartRate(this);

  /// Formatowanie kadencji do `92 rpm`
  String toCadence() => Formatters.formatCadence(this);

  /// Formatowanie energii do `3,450 kcal`
  String toCalories() => Formatters.formatCalories(this);

  /// Formatowanie pracy do `2,450 kJ`
  String toWorkKj() => Formatters.formatWorkKj(this);
}

/// Rozszerzenia dla obiektów [Duration]
extension CyclingDurationFormatters on Duration {
  /// Formatowanie czasu trwania do `HH:MM:SS`
  String toRaceTime({bool showHoursAlways = true}) =>
      Formatters.formatDuration(this, showHoursAlways: showHoursAlways);

  /// Formatowanie czasu trwania do różnicy kolarskiej `+0'14"`
  String toTimeGap({bool showPlusSign = true}) =>
      Formatters.formatTimeGap(inMilliseconds / 1000.0, showPlusSign: showPlusSign);
}

