// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Pozycja aerodynamiczna kolarza na rowerze podczas etapu wyścigu.
enum RiderAeroPosition {
  /// Pozycja standardowa na klamkomanetkach (Hoods) – pełna sterowność i optymalna wentylacja płucna
  standard,

  /// Agresywna pozycja aero (Drops / Aero Hoods) – zminimalizowany opór czołowy kosztem sterowności
  aggressiveAero,

  /// Maksymalna oszczędność energii w peletonie – głębokie chowanie się za kołem w cieniu aerodynamicznym
  pelotonShelter;

  /// Oficjalna nazwa pozycji wymagana przez interfejs
  String get label {
    switch (this) {
      case RiderAeroPosition.standard:
        return 'Standardowa';
      case RiderAeroPosition.aggressiveAero:
        return 'Agresywna Aero (kosztem sterowności)';
      case RiderAeroPosition.pelotonShelter:
        return 'Maksymalna oszczędność energii w peletonie';
    }
  }

  /// Skrócona etykieta do widoków kompaktowych
  String get shortLabel {
    switch (this) {
      case RiderAeroPosition.standard:
        return 'Standard';
      case RiderAeroPosition.aggressiveAero:
        return 'Agresywna Aero';
      case RiderAeroPosition.pelotonShelter:
        return 'Oszczędność w peletonie';
    }
  }

  /// Szczegółowy opis taktyczny i fizyczny pozycji
  String get description {
    switch (this) {
      case RiderAeroPosition.standard:
        return 'Dłonie na klamkomanetkach. Pełna kontrola nad rowerem w zakrętach i peletonie, optymalna wentylacja płuc.';
      case RiderAeroPosition.aggressiveAero:
        return 'Głęboki chwyt dolny / wąskie ramiona (-14% CdA). Wyższa prędkość kosztem gorszej reakcji na przeszkody i wiatr boczny.';
      case RiderAeroPosition.pelotonShelter:
        return 'Głębokie chowanie się za kołem (+22% redukcji oporu z draftingu). Ochrona glikogenu i beztlenowej rezerwy W\'.';
    }
  }

  /// Mnożnik bazowego współczynnika oporu powietrza CdA (1.0 = standard)
  double get cdaMultiplier {
    switch (this) {
      case RiderAeroPosition.standard:
        return 1.00;
      case RiderAeroPosition.aggressiveAero:
        return 0.86; // -14% oporu czołowego
      case RiderAeroPosition.pelotonShelter:
        return 0.95; // W połączeniu z tunelem aerodynamicznym peletonu
    }
  }

  /// Współczynnik sterowności i zwinności manewrowej (0.0 - 1.0)
  double get handlingFactor {
    switch (this) {
      case RiderAeroPosition.standard:
        return 1.00; // 100% sterowności
      case RiderAeroPosition.aggressiveAero:
        return 0.72; // -28% stabilności w zakrętach i przy rantach
      case RiderAeroPosition.pelotonShelter:
        return 0.90; // Standardowa kontrola w szyku peletonu
    }
  }

  /// Dodatkowy bonus do redukcji oporów w tunelu powietrznym peletonu
  double get draftingBonus {
    switch (this) {
      case RiderAeroPosition.standard:
        return 0.00;
      case RiderAeroPosition.aggressiveAero:
        return 0.04;
      case RiderAeroPosition.pelotonShelter:
        return 0.22; // +22% oszczędności mocy w tunelu peletonu
    }
  }

  /// Ikona reprezentująca pozycję
  IconData get icon {
    switch (this) {
      case RiderAeroPosition.standard:
        return Icons.directions_bike_rounded;
      case RiderAeroPosition.aggressiveAero:
        return Icons.speed_rounded;
      case RiderAeroPosition.pelotonShelter:
        return Icons.shield_rounded;
    }
  }
}

/// Fizjologiczne strefy wysiłkowe powiązane z progami LT1, LT2 i VO2max.
enum PhysiologicalZone {
  /// Aktywna regeneracja (< 55% FTP)
  recovery,

  /// Wytrzymałość tlenowa / Baza (55% - 75% FTP) - do progu LT1
  aerobicLt1,

  /// Tempo / SweetSpot (76% - 90% FTP)
  tempo,

  /// Próg mleczanowy / Beztlenowy (91% - 105% FTP) - LT2 / FTP
  thresholdLt2,

  /// Pułap tlenowy (106% - 120% FTP) - VO2max
  vo2max;

  /// Czytelna polska nazwa strefy
  String get label {
    switch (this) {
      case PhysiologicalZone.recovery:
        return 'Aktywna regeneracja (Z1)';
      case PhysiologicalZone.aerobicLt1:
        return 'Baza tlenowa - LT₁ (Z2)';
      case PhysiologicalZone.tempo:
        return 'Tempo / SweetSpot (Z3)';
      case PhysiologicalZone.thresholdLt2:
        return 'Próg mleczanowy - LT₂ / FTP (Z4)';
      case PhysiologicalZone.vo2max:
        return 'Pułap tlenowy - VO₂max (Z5)';
    }
  }

  /// Krótka etykieta
  String get shortCode {
    switch (this) {
      case PhysiologicalZone.recovery:
        return 'Z1 Rec';
      case PhysiologicalZone.aerobicLt1:
        return 'Z2 LT₁';
      case PhysiologicalZone.tempo:
        return 'Z3 Tempo';
      case PhysiologicalZone.thresholdLt2:
        return 'Z4 LT₂/FTP';
      case PhysiologicalZone.vo2max:
        return 'Z5 VO₂max';
    }
  }

  /// Kolor strefy zgodny z paletą Coggana w aplikacji
  Color get color {
    switch (this) {
      case PhysiologicalZone.recovery:
        return AppColors.powerZone1;
      case PhysiologicalZone.aerobicLt1:
        return AppColors.powerZone2;
      case PhysiologicalZone.tempo:
        return AppColors.powerZone3;
      case PhysiologicalZone.thresholdLt2:
        return AppColors.powerZone4;
      case PhysiologicalZone.vo2max:
        return AppColors.powerZone5;
    }
  }

  /// Szacowane stężenie kwasu mlekowego we krwi w danej strefie
  String get lactateEstimate {
    switch (this) {
      case PhysiologicalZone.recovery:
        return '< 1.5 mmol/L (regeneracja)';
      case PhysiologicalZone.aerobicLt1:
        return '~2.0 mmol/L (FatMax / tlen)';
      case PhysiologicalZone.tempo:
        return '2.5 - 3.5 mmol/L (kontrolowany)';
      case PhysiologicalZone.thresholdLt2:
        return '~4.0 mmol/L (przegięcie MLSS)';
      case PhysiologicalZone.vo2max:
        return '> 6.0 mmol/L (kwasica W\')';
    }
  }

  /// Szacowany czas do wyczerpania (Time to Exhaustion - TTE)
  String get timeToExhaustion {
    switch (this) {
      case PhysiologicalZone.recovery:
        return 'Wielogodzinny';
      case PhysiologicalZone.aerobicLt1:
        return '4 - 8 godzin';
      case PhysiologicalZone.tempo:
        return '90 - 150 minut';
      case PhysiologicalZone.thresholdLt2:
        return '45 - 60 minut';
      case PhysiologicalZone.vo2max:
        return '3 - 8 minut';
    }
  }

  /// Główny szlak metaboliczny
  String get metabolismType {
    switch (this) {
      case PhysiologicalZone.recovery:
        return 'Metabolizm tłuszczowy';
      case PhysiologicalZone.aerobicLt1:
        return 'Tłuszcze (FatMax) + Tlen';
      case PhysiologicalZone.tempo:
        return 'Węglowodany + Tlen';
      case PhysiologicalZone.thresholdLt2:
        return 'Glikoliza beztlenowa / Równowaga MLSS';
      case PhysiologicalZone.vo2max:
        return 'Gwałtowny drenaż rezerwy W\'';
    }
  }

  /// Wyznacza strefę fizjologiczną na podstawie zadanego procentu FTP
  static PhysiologicalZone fromPercent(double percent) {
    if (percent < 55.0) {
      return PhysiologicalZone.recovery;
    } else if (percent <= 75.5) {
      return PhysiologicalZone.aerobicLt1;
    } else if (percent <= 90.5) {
      return PhysiologicalZone.tempo;
    } else if (percent <= 105.5) {
      return PhysiologicalZone.thresholdLt2;
    } else {
      return PhysiologicalZone.vo2max;
    }
  }
}

/// Zagregowany stan ustawień intensywności wysiłku i aerodynamiki kolarza.
class RiderEffortSettings {
  /// Intensywność wysiłku w procentach FTP (od 50.0% do 120.0%)
  final double effortPercentFtp;

  /// Wybrana pozycja aerodynamiczna
  final RiderAeroPosition aeroPosition;

  /// Moc progowa kolarza FTP w watach [W]
  final int riderFtpWatts;

  /// Masa kolarza w kilogramach [kg]
  final double riderWeightKg;

  const RiderEffortSettings({
    required this.effortPercentFtp,
    required this.aeroPosition,
    this.riderFtpWatts = 400,
    this.riderWeightKg = 68.0,
  });

  /// Docelowa moc mechaniczna kolarza na korbie w watach [W]
  int get targetWatts => (riderFtpWatts * (effortPercentFtp / 100.0)).round();

  /// Stosunek mocy do masy ciała [W/kg]
  double get wattsPerKg => riderWeightKg > 0.0 ? (targetWatts / riderWeightKg) : 0.0;

  /// Aktualna strefa fizjologiczna kolarza
  PhysiologicalZone get zone => PhysiologicalZone.fromPercent(effortPercentFtp);

  /// Czy wysiłek przekracza próg FTP i drenuje beztlenowy bufor W'
  bool get isAboveFtp => effortPercentFtp > 100.0;

  RiderEffortSettings copyWith({
    double? effortPercentFtp,
    RiderAeroPosition? aeroPosition,
    int? riderFtpWatts,
    double? riderWeightKg,
  }) {
    return RiderEffortSettings(
      effortPercentFtp: effortPercentFtp ?? this.effortPercentFtp,
      aeroPosition: aeroPosition ?? this.aeroPosition,
      riderFtpWatts: riderFtpWatts ?? this.riderFtpWatts,
      riderWeightKg: riderWeightKg ?? this.riderWeightKg,
    );
  }

  @override
  String toString() {
    return 'RiderEffortSettings(${effortPercentFtp.toStringAsFixed(1)}% FTP, ${targetWatts}W, '
        '${wattsPerKg.toStringAsFixed(2)} W/kg, aero: ${aeroPosition.shortLabel})';
  }
}

/// Precyzyjny kontroler intensywności wysiłku kolarza w wyścigu.
///
/// Zawiera:
/// 1. Suwak od 50% do 120% FTP z wyraźnie zaznaczonymi progami fizjologicznymi:
///    - **LT₁** (75% FTP) - tlen / FatMax
///    - **LT₂ / FTP** (100% FTP) - próg mleczanowy / beztlenowy
///    - **VO₂max** (115% FTP) - pułap tlenowy
/// 2. Przyciski szybkiego skoku (Presety progowe) oraz mikro-krok (+/- 1% FTP)
/// 3. Przełącznik trzech pozycji aerodynamicznych:
///    - "Standardowa"
///    - "Agresywna Aero (kosztem sterowności)"
///    - "Maksymalna oszczędność energii w peletonie"
/// 4. Panel telemetryczny: docelowa moc w watach [W], W/kg, szacowane stężenie mleczanu,
///    metabolizm i ostrzeżenie o drenażu baterii W' powyżej 100% FTP.
class RiderEffortSliderControl extends StatefulWidget {
  /// Początkowa intensywność wysiłku kolarza w % FTP (od 50.0 do 120.0)
  final double initialEffortPercent;

  /// Początkowa pozycja aerodynamiczna kolarza
  final RiderAeroPosition initialAeroPosition;

  /// Wartość mocy progowej FTP kolarza w watach [W] (domyślnie 400 W)
  final int riderFtpWatts;

  /// Masa kolarza w kilogramach [kg] (domyślnie 68.0 kg)
  final double riderWeightKg;

  /// Opcjonalne imię i nazwisko kolarza do nagłówka
  final String? riderName;

  /// Opcjonalny kod zespołu (np. "UAD", "TVL")
  final String? teamCode;

  /// Callback wywoływany przy każdej zmianie suwaka intensywności
  final ValueChanged<double>? onEffortChanged;

  /// Callback wywoływany przy zmianie pozycji aerodynamicznej
  final ValueChanged<RiderAeroPosition>? onPositionChanged;

  /// Zbiorczy callback informujący o zmianie pełnych ustawień kolarza
  final ValueChanged<RiderEffortSettings>? onSettingsChanged;

  /// Czy kontroler powinien być wyświetlany w wersji kompaktowej (np. pływający widget na HUD)
  final bool isCompact;

  const RiderEffortSliderControl({
    super.key,
    this.initialEffortPercent = 90.0,
    this.initialAeroPosition = RiderAeroPosition.standard,
    this.riderFtpWatts = 400,
    this.riderWeightKg = 68.0,
    this.riderName,
    this.teamCode,
    this.onEffortChanged,
    this.onPositionChanged,
    this.onSettingsChanged,
    this.isCompact = false,
  });

  /// Wartość progu tlenowego LT1 w % FTP
  static const double thresholdLt1Percent = 75.0;

  /// Wartość progu mleczanowego LT2 / FTP w % FTP
  static const double thresholdLt2Percent = 100.0;

  /// Wartość pułapu tlenowego VO2max w % FTP
  static const double thresholdVo2MaxPercent = 115.0;

  /// Minimalny dopuszczalny wysiłek na suwaku (50% FTP)
  static const double minEffortPercent = 50.0;

  /// Maksymalny dopuszczalny wysiłek na suwaku (120% FTP)
  static const double maxEffortPercent = 120.0;

  @override
  State<RiderEffortSliderControl> createState() => _RiderEffortSliderControlState();
}

class _RiderEffortSliderControlState extends State<RiderEffortSliderControl> {
  late double _effortPercent;
  late RiderAeroPosition _aeroPosition;

  @override
  void initState() {
    super.initState();
    _effortPercent = widget.initialEffortPercent.clamp(
      RiderEffortSliderControl.minEffortPercent,
      RiderEffortSliderControl.maxEffortPercent,
    );
    _aeroPosition = widget.initialAeroPosition;
  }

  @override
  void didUpdateWidget(covariant RiderEffortSliderControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialEffortPercent != widget.initialEffortPercent) {
      _effortPercent = widget.initialEffortPercent.clamp(
        RiderEffortSliderControl.minEffortPercent,
        RiderEffortSliderControl.maxEffortPercent,
      );
    }
    if (oldWidget.initialAeroPosition != widget.initialAeroPosition) {
      _aeroPosition = widget.initialAeroPosition;
    }
  }

  void _updateEffort(double newEffort) {
    final clamped = newEffort.clamp(
      RiderEffortSliderControl.minEffortPercent,
      RiderEffortSliderControl.maxEffortPercent,
    );
    setState(() {
      _effortPercent = clamped;
    });
    widget.onEffortChanged?.call(clamped);
    _notifySettingsChanged();
  }

  void _updatePosition(RiderAeroPosition newPosition) {
    if (_aeroPosition == newPosition) return;
    setState(() {
      _aeroPosition = newPosition;
    });
    widget.onPositionChanged?.call(newPosition);
    _notifySettingsChanged();
  }

  void _notifySettingsChanged() {
    final settings = RiderEffortSettings(
      effortPercentFtp: _effortPercent,
      aeroPosition: _aeroPosition,
      riderFtpWatts: widget.riderFtpWatts,
      riderWeightKg: widget.riderWeightKg,
    );
    widget.onSettingsChanged?.call(settings);
  }

  @override
  Widget build(BuildContext context) {
    final settings = RiderEffortSettings(
      effortPercentFtp: _effortPercent,
      aeroPosition: _aeroPosition,
      riderFtpWatts: widget.riderFtpWatts,
      riderWeightKg: widget.riderWeightKg,
    );

    final zone = settings.zone;
    final zoneColor = zone.color;
    final bool isAboveFtp = settings.isAboveFtp;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131720).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(widget.isCompact ? 10 : 14),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Nagłówek kontrolera i odczyt telemetryczny
            _buildTelemetryHeader(settings, zone, zoneColor),

            const SizedBox(height: 12),

            // 2. Precyzyjny suwak 50% - 120% FTP z zaznaczonymi progami LT1, LT2 i VO2max
            _buildPhysiologicalSlider(zoneColor),

            const SizedBox(height: 8),

            // 3. Przyciski szybkiego wyboru progów (Presety fizjologiczne)
            _buildThresholdPresetsRow(zoneColor),

            const SizedBox(height: 10),

            // 4. Panel fizjologiczny: metabolizm, mleczan i TTE
            _buildPhysiologyDetailsPanel(zone, zoneColor, isAboveFtp),

            const SizedBox(height: 12),
            const Divider(color: Color(0xFF232836), height: 1, thickness: 1),
            const SizedBox(height: 12),

            // 5. Przełącznik pozycji aerodynamicznej (3 tryby)
            _buildAeroPositionSelector(),
          ],
        ),
      ),
    );
  }

  /// Górny nagłówek z nazwą kolarza, docelową mocą [W], W/kg oraz wskaźnikiem strefy
  Widget _buildTelemetryHeader(RiderEffortSettings settings, PhysiologicalZone zone, Color zoneColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Ikona i tytuł modułu
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: zoneColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: zoneColor.withValues(alpha: 0.5), width: 1.2),
          ),
          child: Icon(Icons.tune_rounded, size: 20, color: zoneColor),
        ),
        const SizedBox(width: 10),

        // Nazwa kolarza i opis
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.riderName != null
                    ? '${widget.riderName!} ${widget.teamCode != null ? "(${widget.teamCode})" : ""}'
                    : 'KONTROLA TEMPA I AERO',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  zone.label,
                  style: TextStyle(
                    color: zoneColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Główny licznik: % FTP oraz Waty
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: zoneColor.withValues(alpha: 0.6), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${_effortPercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: zoneColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'FTP',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Text(
                '${settings.targetWatts} W • ${settings.wattsPerKg.toStringAsFixed(1)} W/kg',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Suwak z precyzyjną osią fizjologiczną i naniesionymi progami LT1, LT2 oraz VO2max
  Widget _buildPhysiologicalSlider(Color zoneColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Rząd z przyciskami mikro-kroku [-1%] i [+1%] oraz etykietą suwaka
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'INTENSYWNOŚĆ WYSIŁKU (% FTP)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMicroStepButton(
                  key: const Key('button_step_minus'),
                  icon: Icons.remove,
                  onPressed: _effortPercent > RiderEffortSliderControl.minEffortPercent
                      ? () => _updateEffort(_effortPercent - 1.0)
                      : null,
                ),
                const SizedBox(width: 6),
                _buildMicroStepButton(
                  key: const Key('button_step_plus'),
                  icon: Icons.add,
                  onPressed: _effortPercent < RiderEffortSliderControl.maxEffortPercent
                      ? () => _updateEffort(_effortPercent + 1.0)
                      : null,
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Suwak z dedykowanym motywem kolorystycznym
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: zoneColor,
            inactiveTrackColor: const Color(0xFF252A36),
            thumbColor: zoneColor,
            overlayColor: zoneColor.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10,
              elevation: 4,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2.5),
            activeTickMarkColor: Colors.white70,
            inactiveTickMarkColor: Colors.white24,
          ),
          child: Slider(
            key: const Key('effort_slider'),
            value: _effortPercent,
            min: RiderEffortSliderControl.minEffortPercent,
            max: RiderEffortSliderControl.maxEffortPercent,
            divisions: 70, // Krok co 1% od 50 do 120
            onChanged: _updateEffort,
          ),
        ),

        // Skala z naniesionymi progami fizjologicznymi LT1, LT2 i VO2max
        _buildThresholdScaleMarkers(),
      ],
    );
  }

  /// Rysuje podziałkę z fizjologicznymi punktami przegięcia: LT1, LT2 (FTP) i VO2max
  Widget _buildThresholdScaleMarkers() {
    // Procentowa pozycja progów na odcinku 50% - 120% (rozpiętość 70 jednostek)
    const double range = RiderEffortSliderControl.maxEffortPercent - RiderEffortSliderControl.minEffortPercent;
    const double posLt1 = (RiderEffortSliderControl.thresholdLt1Percent - RiderEffortSliderControl.minEffortPercent) / range;
    const double posLt2 = (RiderEffortSliderControl.thresholdLt2Percent - RiderEffortSliderControl.minEffortPercent) / range;
    const double posVo2 = (RiderEffortSliderControl.thresholdVo2MaxPercent - RiderEffortSliderControl.minEffortPercent) / range;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          // Kreski znaczników progów
          const Row(
            children: [
              Text('50%', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w700)),
              Expanded(
                child: CustomPaint(
                  size: Size(double.infinity, 8),
                  painter: _ThresholdTicksPainter(
                    fractionLt1: posLt1,
                    fractionLt2: posLt2,
                    fractionVo2: posVo2,
                  ),
                ),
              ),
              Text('120%', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 2),

          // Etykiety tekstowe progów
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildThresholdLegendPill('LT₁ (75%)', AppColors.powerZone2, 'Tlen'),
                const SizedBox(width: 12),
                _buildThresholdLegendPill('LT₂/FTP (100%)', AppColors.powerZone4, 'Mleczan'),
                const SizedBox(width: 12),
                _buildThresholdLegendPill('VO₂max (115%)', AppColors.powerZone5, 'Pułap'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdLegendPill(String title, Color color, String subtitle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          '($subtitle)',
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Przyciski szybkiego skoku (presety fizjologiczne)
  Widget _buildThresholdPresetsRow(Color activeZoneColor) {
    return Row(
      children: [
        Expanded(
          child: _buildPresetChip(
            key: const Key('preset_lt1'),
            label: '75% LT₁ (Tlen)',
            targetPercent: RiderEffortSliderControl.thresholdLt1Percent,
            color: AppColors.powerZone2,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildPresetChip(
            key: const Key('preset_tempo'),
            label: '90% Tempo',
            targetPercent: 90.0,
            color: AppColors.powerZone3,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildPresetChip(
            key: const Key('preset_lt2'),
            label: '100% LT₂ (FTP)',
            targetPercent: RiderEffortSliderControl.thresholdLt2Percent,
            color: AppColors.powerZone4,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildPresetChip(
            key: const Key('preset_vo2max'),
            label: '115% VO₂max',
            targetPercent: RiderEffortSliderControl.thresholdVo2MaxPercent,
            color: AppColors.powerZone5,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip({
    required Key key,
    required String label,
    required double targetPercent,
    required Color color,
  }) {
    final bool isSelected = (_effortPercent - targetPercent).abs() < 0.5;

    return InkWell(
      key: key,
      onTap: () => _updateEffort(targetPercent),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.25) : const Color(0xFF1B202C),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF2C3242),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicroStepButton({
    required Key key,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      key: key,
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2432),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF323A4D), width: 1),
        ),
        child: Icon(icon, size: 14, color: onPressed != null ? Colors.white : Colors.white24),
      ),
    );
  }

  /// Panel telemetryczno-fizjologiczny z informacją o metabolizmie, mleczanie i czasie do wyczerpania
  Widget _buildPhysiologyDetailsPanel(PhysiologicalZone zone, Color zoneColor, bool isAboveFtp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF171B26),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF262C3A), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Kolumna 1: Metabolizm
              Expanded(
                child: _buildPhysiologyMetric(
                  icon: Icons.bubble_chart_rounded,
                  label: 'METABOLIZM',
                  value: zone.metabolismType,
                  color: zoneColor,
                ),
              ),
              Container(width: 1, height: 26, color: const Color(0xFF262C3A)),
              // Kolumna 2: Mleczan
              Expanded(
                child: _buildPhysiologyMetric(
                  icon: Icons.water_drop_rounded,
                  label: 'MLECZAN KRWI',
                  value: zone.lactateEstimate,
                  color: zoneColor,
                ),
              ),
              Container(width: 1, height: 26, color: const Color(0xFF262C3A)),
              // Kolumna 3: Czas TTE
              Expanded(
                child: _buildPhysiologyMetric(
                  icon: Icons.timer_outlined,
                  label: 'WYTRZYMAŁOŚĆ',
                  value: zone.timeToExhaustion,
                  color: isAboveFtp ? AppColors.powerZone6 : AppColors.cyanAccent,
                ),
              ),
            ],
          ),

          // Ostrzeżenie o drenażu beztlenowym W' powyżej 100% FTP
          if (isAboveFtp) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.powerZone6.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.powerZone6.withValues(alpha: 0.5), width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.powerZone6),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pobór z beztlenowej rezerwy W\'! Utrzymanie tego tempa wyczerpie siły kolarza w kilka minut.',
                      style: TextStyle(
                        color: AppColors.powerZone6,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhysiologyMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Sekcja przełącznika pozycji aerodynamicznej (3 tryby)
  Widget _buildAeroPositionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tytuł sekcji
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'POZYCJA AERODYNAMICZNA KOLARZA',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            Icon(Icons.air_rounded, size: 14, color: AppColors.accentBlue),
          ],
        ),

        const SizedBox(height: 8),

        // Trzy opcje pozycji aerodynamicznej
        _buildAeroPositionTile(
          key: const Key('position_standard'),
          position: RiderAeroPosition.standard,
          badgeColor: AppColors.powerZone2,
          cdaTag: 'CdA: 100% (bazowy)',
          handlingTag: 'Sterowność: 100%',
        ),

        const SizedBox(height: 6),

        _buildAeroPositionTile(
          key: const Key('position_aggressive_aero'),
          position: RiderAeroPosition.aggressiveAero,
          badgeColor: AppColors.amberWarning,
          cdaTag: 'CdA: -14% (Szybciej)',
          handlingTag: 'Sterowność: -28%',
        ),

        const SizedBox(height: 6),

        _buildAeroPositionTile(
          key: const Key('position_peloton_shelter'),
          position: RiderAeroPosition.pelotonShelter,
          badgeColor: AppColors.emeraldGreen,
          cdaTag: 'Drafting: +22% osłony',
          handlingTag: 'Ochrona glikogenu i W\'',
        ),
      ],
    );
  }

  /// Pojedynczy kafelek wyboru pozycji aerodynamicznej
  Widget _buildAeroPositionTile({
    required Key key,
    required RiderAeroPosition position,
    required Color badgeColor,
    required String cdaTag,
    required String handlingTag,
  }) {
    final bool isSelected = _aeroPosition == position;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: () => _updatePosition(position),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1D2332)
                : const Color(0xFF141822).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.goldAccent : const Color(0xFF262C3A),
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.goldAccent.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Ikona pozycji
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.goldAccent.withValues(alpha: 0.2)
                      : const Color(0xFF1E2330),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  position.icon,
                  size: 16,
                  color: isSelected ? AppColors.goldAccent : Colors.white60,
                ),
              ),
              const SizedBox(width: 10),

              // Tytuł i opis pozycji
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      position.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      position.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Badges ze statystykami aero i sterowności
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.5), width: 0.8),
                    ),
                    child: Text(
                      cdaTag,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    handlingTag,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 6),

              // Wskaźnik wyboru (Radio check)
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: isSelected ? AppColors.goldAccent : Colors.white24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Painter rysujący kreski znaczników na skali suwaka dla progów LT1, LT2 i VO2max
class _ThresholdTicksPainter extends CustomPainter {
  final double fractionLt1;
  final double fractionLt2;
  final double fractionVo2;

  const _ThresholdTicksPainter({
    required this.fractionLt1,
    required this.fractionLt2,
    required this.fractionVo2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0;

    // Rysowanie bazowej linii osi
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      linePaint,
    );

    // Rysowanie znaczników dla progów
    _drawMarker(canvas, size, fractionLt1, AppColors.powerZone2);
    _drawMarker(canvas, size, fractionLt2, AppColors.powerZone4);
    _drawMarker(canvas, size, fractionVo2, AppColors.powerZone5);
  }

  void _drawMarker(Canvas canvas, Size size, double fraction, Color color) {
    final x = (fraction * size.width).clamp(0.0, size.width);
    final markerPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      markerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ThresholdTicksPainter oldDelegate) {
    return oldDelegate.fractionLt1 != fractionLt1 ||
        oldDelegate.fractionLt2 != fractionLt2 ||
        oldDelegate.fractionVo2 != fractionVo2;
  }
}
