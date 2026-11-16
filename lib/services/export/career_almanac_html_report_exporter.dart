import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../career/historical_records_and_palmares_service.dart';

/// Obsługiwane formaty eksportu Kroniki Kariery do udostępnienia znajomym.
enum CareerAlmanacExportFormat {
  html(
    'html',
    'Kronika HTML (.html)',
    'Samowystarczalny, elegancko ostylowany plik WWW gotowy do otwarcia w przeglądarce',
  ),
  markdown(
    'md',
    'Kronika Markdown (.md)',
    'Czytelny raport GitHub-Flavored Markdown na Discord, GitHub lub Notion',
  );

  final String fileExtension;
  final String displayName;
  final String subtitle;

  const CareerAlmanacExportFormat(
    this.fileExtension,
    this.displayName,
    this.subtitle,
  );
}

/// Wariant stylistyczny generowanego raportu HTML.
enum CareerAlmanacThemeStyle {
  pelotonNoirGold(
    'Peloton Noir & Gold',
    'Ciemna karbonowa estetyka #0F1115 ze złotymi akcentami #D4AF37',
  ),
  grandTourEditorial(
    'Grand Tour Editorial',
    'Jasny styl magazynu kolarskiego zoptymalizowany pod druk i PDF',
  );

  final String displayName;
  final String description;

  const CareerAlmanacThemeStyle(this.displayName, this.description);
}

/// Zbiorcze statystyki prowadzonej drużyny w karierze.
class CareerAlmanacTeamStats {
  final String teamId;
  final String teamName;
  final String divisionName;
  final String countryIso;
  final String managerName;
  final int currentSeasonYear;
  final int seasonsManaged;
  final int totalWins;
  final int grandTourGcWins;
  final int monumentWins;
  final int stageWins;
  final int worldTourWins;
  final int uciWorldRanking;
  final int totalUciPoints;
  final double budgetEur;
  final double teamPrestige;
  final String primaryColorHex;
  final String secondaryColorHex;
  final String topRiderName;
  final int topRiderWins;

  const CareerAlmanacTeamStats({
    required this.teamId,
    required this.teamName,
    required this.divisionName,
    required this.countryIso,
    required this.managerName,
    required this.currentSeasonYear,
    required this.seasonsManaged,
    required this.totalWins,
    required this.grandTourGcWins,
    required this.monumentWins,
    required this.stageWins,
    required this.worldTourWins,
    required this.uciWorldRanking,
    required this.totalUciPoints,
    required this.budgetEur,
    required this.teamPrestige,
    this.primaryColorHex = '#8E4A49',
    this.secondaryColorHex = '#D4AF37',
    this.topRiderName = '',
    this.topRiderWins = 0,
  });
}

/// Podsumowanie pojedynczego sezonu w kronice kariery.
class CareerAlmanacSeasonSummary {
  final int seasonYear;
  final int wins;
  final int podiums;
  final int uciPoints;
  final int uciRank;
  final double budgetEur;
  final String highlightAchievement;

  const CareerAlmanacSeasonSummary({
    required this.seasonYear,
    required this.wins,
    required this.podiums,
    required this.uciPoints,
    required this.uciRank,
    required this.budgetEur,
    required this.highlightAchievement,
  });
}

/// Pełny zestaw danych wejściowych do wygenerowania Kroniki Kariery.
class CareerAlmanacReportInput {
  final CareerAlmanacTeamStats teamStats;
  final List<CareerAlmanacSeasonSummary> seasonHistory;
  final List<PalmaresEntry> trophies;
  final List<ClimbKomRecord> climbRecords;
  final List<RiderPalmares> topRiders;
  final DateTime generatedAtUtc;
  final String? customTitle;
  final String appVersionLabel;

  const CareerAlmanacReportInput({
    required this.teamStats,
    this.seasonHistory = const [],
    this.trophies = const [],
    this.climbRecords = const [],
    this.topRiders = const [],
    required this.generatedAtUtc,
    this.customTitle,
    this.appVersionLabel = 'Pro Peloton Manager',
  });
}

/// Wynik eksportu Kroniki Kariery.
class CareerAlmanacExportResult {
  final CareerAlmanacExportFormat format;
  final CareerAlmanacThemeStyle themeStyle;
  final String content;
  final String suggestedFileName;
  final int trophyCount;
  final int climbRecordCount;
  final int seasonCount;
  final int riderLeaderCount;
  final int byteSize;

  const CareerAlmanacExportResult({
    required this.format,
    required this.themeStyle,
    required this.content,
    required this.suggestedFileName,
    required this.trophyCount,
    required this.climbRecordCount,
    required this.seasonCount,
    required this.riderLeaderCount,
    required this.byteSize,
  });
}

/// Raport walidacji struktury wygenerowanego pliku `.html` lub `.md`.
class CareerAlmanacValidationReport {
  final bool isValid;
  final CareerAlmanacExportFormat format;
  final List<String> errors;
  final bool hasTeamHeader;
  final bool hasTrophiesSection;
  final bool hasClimbRecordsSection;

  const CareerAlmanacValidationReport({
    required this.isValid,
    required this.format,
    required this.errors,
    required this.hasTeamHeader,
    required this.hasTrophiesSection,
    required this.hasClimbRecordsSection,
  });
}

/// Eksporter Kroniki Kariery generujący pojedynczy, elegancko ostylowany plik
/// raportu `.html` lub `.md` ze statystykami drużyny, rekordami podjazdów KOM
/// oraz zdobytymi trofeami do udostępnienia znajomym.
class CareerAlmanacHtmlReportExporter {
  const CareerAlmanacHtmlReportExporter();

  /// Generuje raport Kroniki Kariery w formacie `.html` lub `.md`.
  CareerAlmanacExportResult export({
    required CareerAlmanacReportInput input,
    CareerAlmanacExportFormat format = CareerAlmanacExportFormat.html,
    CareerAlmanacThemeStyle themeStyle = CareerAlmanacThemeStyle.pelotonNoirGold,
    bool includeSeasonBreakdown = true,
    bool includeClimbRecords = true,
    bool includeTrophies = true,
    bool includeRiderLeaders = true,
  }) {
    final sortedSeasons = List<CareerAlmanacSeasonSummary>.from(
      includeSeasonBreakdown ? input.seasonHistory : const [],
    )..sort((a, b) => b.seasonYear.compareTo(a.seasonYear));

    final sortedTrophies = List<PalmaresEntry>.from(
      includeTrophies ? input.trophies : const [],
    )..sort((a, b) {
        final weightCmp = b.achievementType.allTimePointsWeight.compareTo(
          a.achievementType.allTimePointsWeight,
        );
        if (weightCmp != 0) return weightCmp;
        return b.date.compareTo(a.date);
      });

    final sortedClimbs = List<ClimbKomRecord>.from(
      includeClimbRecords ? input.climbRecords : const [],
    )..sort((a, b) => b.vamMetersPerHour.compareTo(a.vamMetersPerHour));

    final sortedRiders = List<RiderPalmares>.from(
      includeRiderLeaders ? input.topRiders : const [],
    )..sort(
        (a, b) => b.calculateAllTimeGoatPoints.compareTo(
          a.calculateAllTimeGoatPoints,
        ),
      );

    final String content = format == CareerAlmanacExportFormat.html
        ? _buildHtmlDocument(
            input: input,
            themeStyle: themeStyle,
            seasons: sortedSeasons,
            trophies: sortedTrophies,
            climbs: sortedClimbs,
            riders: sortedRiders,
          )
        : _buildMarkdownDocument(
            input: input,
            seasons: sortedSeasons,
            trophies: sortedTrophies,
            climbs: sortedClimbs,
            riders: sortedRiders,
          );

    return CareerAlmanacExportResult(
      format: format,
      themeStyle: themeStyle,
      content: content,
      suggestedFileName: _buildSuggestedFileName(input, format),
      trophyCount: sortedTrophies.length,
      climbRecordCount: sortedClimbs.length,
      seasonCount: sortedSeasons.length,
      riderLeaderCount: sortedRiders.length,
      byteSize: content.length,
    );
  }

  /// Zapisuje wygenerowaną Kronikę Kariery do pliku `.html` lub `.md` w [targetDirectory].
  Future<File> exportToFile({
    required CareerAlmanacReportInput input,
    required Directory targetDirectory,
    CareerAlmanacExportFormat format = CareerAlmanacExportFormat.html,
    CareerAlmanacThemeStyle themeStyle = CareerAlmanacThemeStyle.pelotonNoirGold,
    bool includeSeasonBreakdown = true,
    bool includeClimbRecords = true,
    bool includeTrophies = true,
    bool includeRiderLeaders = true,
    String? customFileName,
  }) async {
    final result = export(
      input: input,
      format: format,
      themeStyle: themeStyle,
      includeSeasonBreakdown: includeSeasonBreakdown,
      includeClimbRecords: includeClimbRecords,
      includeTrophies: includeTrophies,
      includeRiderLeaders: includeRiderLeaders,
    );

    if (!await targetDirectory.exists()) {
      await targetDirectory.create(recursive: true);
    }

    final String fileName =
        (customFileName != null && customFileName.trim().isNotEmpty)
            ? customFileName.trim()
            : result.suggestedFileName;
    final String sep = Platform.pathSeparator;
    final String fullPath = targetDirectory.path.endsWith(sep)
        ? '${targetDirectory.path}$fileName'
        : '${targetDirectory.path}$sep$fileName';

    final file = File(fullPath);
    return file.writeAsString(result.content, flush: true);
  }

  /// Waliduje poprawność struktury wygenerowanego dokumentu HTML lub Markdown.
  CareerAlmanacValidationReport validateExportedReport(
    String content,
    CareerAlmanacExportFormat format,
  ) {
    final errors = <String>[];
    if (content.trim().isEmpty) {
      errors.add('Wygenerowany raport jest pusty.');
      return CareerAlmanacValidationReport(
        isValid: false,
        format: format,
        errors: errors,
        hasTeamHeader: false,
        hasTrophiesSection: false,
        hasClimbRecordsSection: false,
      );
    }

    bool hasHeader = false;
    bool hasTrophies = false;
    bool hasClimbs = false;

    if (format == CareerAlmanacExportFormat.html) {
      if (!content.contains('<!DOCTYPE html>')) {
        errors.add('Brak deklaracji <!DOCTYPE html>.');
      }
      if (!content.contains('<html') || !content.contains('</html>')) {
        errors.add('Niekompletny znacznik główny <html>.');
      }
      if (!content.contains('<style>') || !content.contains('</style>')) {
        errors.add('Brak osadzonego arkusza stylów CSS.');
      }
      hasHeader = content.contains('class="hero-header"');
      hasTrophies = content.contains('id="trophies"');
      hasClimbs = content.contains('id="climbs"');
    } else {
      if (!content.startsWith('# ')) {
        errors.add('Raport Markdown powinien zaczynać się od nagłówka H1.');
      }
      hasHeader = content.contains('## Statystyki Drużyny');
      hasTrophies = content.contains('## Gablota Trofeów');
      hasClimbs = content.contains('## Rekordy Podjazdów (KOM)');
    }

    if (!hasHeader) {
      errors.add('Brak sekcji nagłówkowej drużyny.');
    }

    return CareerAlmanacValidationReport(
      isValid: errors.isEmpty,
      format: format,
      errors: errors,
      hasTeamHeader: hasHeader,
      hasTrophiesSection: hasTrophies,
      hasClimbRecordsSection: hasClimbs,
    );
  }

  String _buildHtmlDocument({
    required CareerAlmanacReportInput input,
    required CareerAlmanacThemeStyle themeStyle,
    required List<CareerAlmanacSeasonSummary> seasons,
    required List<PalmaresEntry> trophies,
    required List<ClimbKomRecord> climbs,
    required List<RiderPalmares> riders,
  }) {
    final stats = input.teamStats;
    final title = (input.customTitle != null && input.customTitle!.trim().isNotEmpty)
        ? input.customTitle!.trim()
        : 'Kronika Kariery — ${stats.teamName}';
    final isDark = themeStyle == CareerAlmanacThemeStyle.pelotonNoirGold;

    final bg = isDark ? '#0F1115' : '#F6F4EE';
    final surface = isDark ? '#181B22' : '#FFFFFF';
    final surfaceLight = isDark ? '#222630' : '#EFECE3';
    final border = isDark ? '#2E3440' : '#D9D3C3';
    final textPrimary = isDark ? '#F3F4F6' : '#181B22';
    final textSecondary = isDark ? '#9CA3AF' : '#525866';
    final gold = isDark ? '#D4AF37' : '#A67C00';
    final burgundy = _sanitizeHexColor(stats.primaryColorHex, fallback: '#8E4A49');
    final accentBlue = isDark ? '#38BDF8' : '#0284C7';
    final success = isDark ? '#10B981' : '#059669';

    final buf = StringBuffer();
    buf.writeln('<!DOCTYPE html>');
    buf.writeln('<html lang="pl">');
    buf.writeln('<head>');
    buf.writeln('  <meta charset="UTF-8">');
    buf.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buf.writeln('  <title>${_escapeHtml(title)}</title>');
    buf.writeln('  <style>');
    buf.writeln(_buildCss(
      bg: bg,
      surface: surface,
      surfaceLight: surfaceLight,
      border: border,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      gold: gold,
      burgundy: burgundy,
      accentBlue: accentBlue,
      success: success,
    ));
    buf.writeln('  </style>');
    buf.writeln('</head>');
    buf.writeln('<body>');
    buf.writeln('  <main class="almanac-container">');

    // Hero Header
    buf.writeln('    <header class="hero-header">');
    buf.writeln('      <div class="hero-badge-row">');
    buf.writeln('        <span class="badge badge-gold">${_escapeHtml(stats.divisionName)}</span>');
    buf.writeln('        <span class="badge badge-muted">${_escapeHtml(stats.countryIso.toUpperCase())} • SEZON ${stats.currentSeasonYear}</span>');
    buf.writeln('        <span class="badge badge-burgundy">RANKING UCI #${stats.uciWorldRanking}</span>');
    buf.writeln('      </div>');
    buf.writeln('      <h1>${_escapeHtml(title)}</h1>');
    buf.writeln('      <p class="hero-subtitle">Dyrektor Sportowy: <strong>${_escapeHtml(stats.managerName)}</strong> • Lata prowadzenia: <strong>${stats.seasonsManaged}</strong> • Prestiż: <strong>${stats.teamPrestige.toStringAsFixed(1)}/100</strong></p>');
    buf.writeln('    </header>');

    // KPI Grid
    buf.writeln('    <section id="team-stats" class="section-card">');
    buf.writeln('      <div class="section-title-row"><h2>Statystyki Prowadzonej Drużyny</h2><span class="section-tag">PALMARÈS &amp; EKONOMIA</span></div>');
    buf.writeln('      <div class="kpi-grid">');
    _writeHtmlKpi(buf, 'Zwycięstwa Ogółem', '${stats.totalWins}', 'highlight-gold');
    _writeHtmlKpi(buf, 'Wielkie Toury (GC)', '${stats.grandTourGcWins}', 'highlight-gold');
    _writeHtmlKpi(buf, 'Monumenty', '${stats.monumentWins}', 'highlight-burgundy');
    _writeHtmlKpi(buf, 'Wygrane Etapy', '${stats.stageWins}', '');
    _writeHtmlKpi(buf, 'Triumfy WorldTour', '${stats.worldTourWins}', '');
    _writeHtmlKpi(buf, 'Punkty UCI', _formatIntWithSpaces(stats.totalUciPoints), 'highlight-blue');
    _writeHtmlKpi(buf, 'Budżet Roczny', Formatters.formatCurrency(stats.budgetEur), '');
    _writeHtmlKpi(
      buf,
      'Lider Zwycięstw',
      stats.topRiderName.isEmpty ? '—' : '${stats.topRiderName} (${stats.topRiderWins})',
      '',
    );
    buf.writeln('      </div>');
    buf.writeln('    </section>');

    // Season History
    if (seasons.isNotEmpty) {
      buf.writeln('    <section id="seasons" class="section-card">');
      buf.writeln('      <div class="section-title-row"><h2>Kronika Sezonów</h2><span class="section-tag">${seasons.length} SEZONY</span></div>');
      buf.writeln('      <div class="table-wrap">');
      buf.writeln('        <table>');
      buf.writeln('          <thead><tr><th>Sezon</th><th>Zwycięstwa</th><th>Podia</th><th>Ranking UCI</th><th>Punkty UCI</th><th>Budżet</th><th>Największy Sukces</th></tr></thead>');
      buf.writeln('          <tbody>');
      for (final s in seasons) {
        buf.writeln(
          '            <tr>'
          '<td class="num strong">${s.seasonYear}</td>'
          '<td class="num gold">${s.wins}</td>'
          '<td class="num">${s.podiums}</td>'
          '<td class="num">#${s.uciRank}</td>'
          '<td class="num">${_formatIntWithSpaces(s.uciPoints)}</td>'
          '<td class="num">${_escapeHtml(Formatters.formatCurrency(s.budgetEur))}</td>'
          '<td>${_escapeHtml(s.highlightAchievement.isEmpty ? '—' : s.highlightAchievement)}</td>'
          '</tr>',
        );
      }
      buf.writeln('          </tbody>');
      buf.writeln('        </table>');
      buf.writeln('      </div>');
      buf.writeln('    </section>');
    }

    // Climb Records
    if (climbs.isNotEmpty) {
      buf.writeln('    <section id="climbs" class="section-card">');
      buf.writeln('      <div class="section-title-row"><h2>Rekordy Podjazdów (KOM)</h2><span class="section-tag">${climbs.length} PRZEŁĘCZY</span></div>');
      buf.writeln('      <div class="cards-grid">');
      for (final c in climbs) {
        buf.writeln('        <article class="climb-card">');
        buf.writeln('          <div class="climb-card-top">');
        buf.writeln('            <div><h3>${_escapeHtml(c.climbName)}</h3><p class="climb-meta">${_escapeHtml(c.mountainRange)} (${_escapeHtml(c.countryIso)}) • ${c.lengthKm.toStringAsFixed(1)} km @ ${c.averageGradientPct.toStringAsFixed(1)}%</p></div>');
        buf.writeln('            <span class="kom-time">${_escapeHtml(c.formattedRecordTime)}</span>');
        buf.writeln('          </div>');
        buf.writeln('          <div class="climb-stats-row">');
        buf.writeln('            <span><strong>${_escapeHtml(c.recordHolderRiderName)}</strong> (${_escapeHtml(c.recordHolderTeamName)})</span>');
        buf.writeln('            <span class="num">${c.vamMetersPerHour.round()} m/h VAM • ${c.estimatedWattsPerKg.toStringAsFixed(2)} W/kg</span>');
        buf.writeln('          </div>');
        buf.writeln('          <div class="climb-race-note">${_escapeHtml(c.achievedInRaceName)} • Sezon ${c.achievedInSeasonYear} • +${c.elevationGainM.round()} m przewyższenia</div>');
        buf.writeln('        </article>');
      }
      buf.writeln('      </div>');
      buf.writeln('    </section>');
    }

    // Trophies
    if (trophies.isNotEmpty) {
      buf.writeln('    <section id="trophies" class="section-card">');
      buf.writeln('      <div class="section-title-row"><h2>Gablota Trofeów</h2><span class="section-tag">${trophies.length} TROFEÓW</span></div>');
      buf.writeln('      <div class="table-wrap">');
      buf.writeln('        <table>');
      buf.writeln('          <thead><tr><th>Rok</th><th>Wyścig</th><th>Kategoria</th><th>Kolarz</th><th>Szczegóły / Koszulka</th></tr></thead>');
      buf.writeln('          <tbody>');
      for (final t in trophies) {
        final jerseyBadge = (t.jerseyWorn != null && t.jerseyWorn!.trim().isNotEmpty)
            ? ' <span class="badge badge-gold-inline">${_escapeHtml(t.jerseyWorn!)}</span>'
            : '';
        buf.writeln(
          '            <tr>'
          '<td class="num strong">${t.seasonYear}</td>'
          '<td class="strong">${_escapeHtml(t.raceName)}</td>'
          '<td>${_escapeHtml(t.achievementType.displayName)}</td>'
          '<td>${_escapeHtml(t.riderName)}</td>'
          '<td>${_escapeHtml(t.details)}$jerseyBadge</td>'
          '</tr>',
        );
      }
      buf.writeln('          </tbody>');
      buf.writeln('        </table>');
      buf.writeln('      </div>');
      buf.writeln('    </section>');
    }

    // Top Riders
    if (riders.isNotEmpty) {
      buf.writeln('    <section id="riders" class="section-card">');
      buf.writeln('      <div class="section-title-row"><h2>Gwiazdy i Legendy Drużyny</h2><span class="section-tag">GOAT INDEX</span></div>');
      buf.writeln('      <div class="table-wrap">');
      buf.writeln('        <table>');
      buf.writeln('          <thead><tr><th>Kolarz</th><th>Kraj</th><th>Zwycięstwa</th><th>GT GC</th><th>Monumenty</th><th>Dni Lidera GT</th><th>GOAT Pts</th></tr></thead>');
      buf.writeln('          <tbody>');
      for (final r in riders) {
        buf.writeln(
          '            <tr>'
          '<td class="strong">${_escapeHtml(r.riderName)}</td>'
          '<td class="num">${_escapeHtml(r.nationalityIso.toUpperCase())}</td>'
          '<td class="num gold">${r.totalCareerVictories}</td>'
          '<td class="num">${r.grandTourOverallWins}</td>'
          '<td class="num">${r.monumentWins}</td>'
          '<td class="num">${r.totalDaysInGrandTourLeaderJerseys}</td>'
          '<td class="num strong">${_formatIntWithSpaces(r.calculateAllTimeGoatPoints)}</td>'
          '</tr>',
        );
      }
      buf.writeln('          </tbody>');
      buf.writeln('        </table>');
      buf.writeln('      </div>');
      buf.writeln('    </section>');
    }

    // Footer
    buf.writeln('    <footer class="almanac-footer">');
    buf.writeln('      <span>Wygenerowano w <strong>${_escapeHtml(input.appVersionLabel)}</strong></span>');
    buf.writeln('      <span>Data eksportu (UTC): ${_formatUtcDateTime(input.generatedAtUtc)}</span>');
    buf.writeln('    </footer>');
    buf.writeln('  </main>');
    buf.writeln('</body>');
    buf.writeln('</html>');

    return buf.toString();
  }

  void _writeHtmlKpi(
    StringBuffer buf,
    String label,
    String value,
    String modifierClass,
  ) {
    final cls = modifierClass.isEmpty ? 'kpi-tile' : 'kpi-tile $modifierClass';
    buf.writeln('        <div class="$cls">');
    buf.writeln('          <span class="kpi-label">${_escapeHtml(label)}</span>');
    buf.writeln('          <span class="kpi-value num">${_escapeHtml(value)}</span>');
    buf.writeln('        </div>');
  }

  String _buildCss({
    required String bg,
    required String surface,
    required String surfaceLight,
    required String border,
    required String textPrimary,
    required String textSecondary,
    required String gold,
    required String burgundy,
    required String accentBlue,
    required String success,
  }) {
    return '''
    :root {
      --bg: $bg;
      --surface: $surface;
      --surface-light: $surfaceLight;
      --border: $border;
      --text: $textPrimary;
      --muted: $textSecondary;
      --gold: $gold;
      --burgundy: $burgundy;
      --blue: $accentBlue;
      --success: $success;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background: var(--bg);
      color: var(--text);
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      letter-spacing: -0.01em;
      line-height: 1.5;
      padding: 28px 16px 48px;
    }
    .almanac-container {
      max-width: 1120px;
      margin: 0 auto;
      display: flex;
      flex-direction: column;
      gap: 20px;
    }
    .hero-header {
      background: linear-gradient(135deg, var(--surface) 0%, var(--surface-light) 100%);
      border: 1px solid var(--border);
      border-top: 3px solid var(--gold);
      border-radius: 16px;
      padding: 28px;
    }
    .hero-badge-row {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin-bottom: 14px;
    }
    .badge {
      display: inline-block;
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 0.04em;
      text-transform: uppercase;
      padding: 4px 10px;
      border-radius: 999px;
      border: 1px solid var(--border);
    }
    .badge-gold { color: var(--gold); border-color: var(--gold); background: rgba(212, 175, 55, 0.12); }
    .badge-burgundy { color: #F3F4F6; border-color: var(--burgundy); background: var(--burgundy); }
    .badge-muted { color: var(--muted); background: var(--surface); }
    .badge-gold-inline {
      font-size: 10px;
      font-weight: 700;
      padding: 2px 7px;
      border-radius: 6px;
      color: var(--gold);
      border: 1px solid var(--gold);
      background: rgba(212, 175, 55, 0.10);
      margin-left: 6px;
    }
    h1 {
      font-size: clamp(24px, 3vw, 34px);
      font-weight: 800;
      letter-spacing: -0.025em;
      margin-bottom: 8px;
    }
    .hero-subtitle { color: var(--muted); font-size: 14px; }
    .hero-subtitle strong { color: var(--text); }
    .section-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 22px;
    }
    .section-title-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
      margin-bottom: 16px;
      padding-bottom: 12px;
      border-bottom: 1px solid var(--border);
    }
    h2 { font-size: 17px; font-weight: 700; letter-spacing: -0.015em; }
    .section-tag {
      font-size: 11px;
      font-weight: 700;
      color: var(--gold);
      letter-spacing: 0.06em;
    }
    .kpi-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 12px;
    }
    .kpi-tile {
      background: var(--surface-light);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 14px 16px;
      display: flex;
      flex-direction: column;
      gap: 4px;
    }
    .kpi-tile.highlight-gold { border-color: rgba(212, 175, 55, 0.55); }
    .kpi-tile.highlight-burgundy { border-color: var(--burgundy); }
    .kpi-tile.highlight-blue { border-color: rgba(56, 189, 248, 0.5); }
    .kpi-label { font-size: 11px; text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); font-weight: 600; }
    .kpi-value { font-size: 20px; font-weight: 800; color: var(--text); }
    .highlight-gold .kpi-value { color: var(--gold); }
    .highlight-blue .kpi-value { color: var(--blue); }
    .num { font-variant-numeric: tabular-nums; }
    .strong { font-weight: 700; }
    .gold { color: var(--gold); font-weight: 700; }
    .table-wrap { overflow-x: auto; }
    table { width: 100%; border-collapse: collapse; font-size: 13px; }
    th, td { padding: 10px 12px; text-align: left; border-bottom: 1px solid var(--border); }
    th {
      font-size: 11px;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      color: var(--muted);
      font-weight: 700;
      background: var(--surface-light);
    }
    tbody tr:hover { background: var(--surface-light); }
    .cards-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(290px, 1fr));
      gap: 12px;
    }
    .climb-card {
      background: var(--surface-light);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 14px 16px;
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .climb-card-top { display: flex; justify-content: space-between; align-items: flex-start; gap: 10px; }
    .climb-card h3 { font-size: 15px; font-weight: 700; }
    .climb-meta { font-size: 12px; color: var(--muted); }
    .kom-time {
      font-variant-numeric: tabular-nums;
      font-weight: 800;
      font-size: 15px;
      color: var(--gold);
      background: rgba(212, 175, 55, 0.12);
      border: 1px solid rgba(212, 175, 55, 0.45);
      padding: 4px 10px;
      border-radius: 8px;
      white-space: nowrap;
    }
    .climb-stats-row {
      display: flex;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 6px;
      font-size: 13px;
    }
    .climb-race-note { font-size: 11px; color: var(--muted); }
    .almanac-footer {
      display: flex;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 8px;
      font-size: 12px;
      color: var(--muted);
      padding: 8px 4px;
    }
    @media print {
      body { background: #FFFFFF; color: #111827; padding: 0; }
      .section-card, .hero-header { break-inside: avoid; }
    }
    ''';
  }

  String _buildMarkdownDocument({
    required CareerAlmanacReportInput input,
    required List<CareerAlmanacSeasonSummary> seasons,
    required List<PalmaresEntry> trophies,
    required List<ClimbKomRecord> climbs,
    required List<RiderPalmares> riders,
  }) {
    final stats = input.teamStats;
    final title = (input.customTitle != null && input.customTitle!.trim().isNotEmpty)
        ? input.customTitle!.trim()
        : 'Kronika Kariery — ${stats.teamName}';

    final buf = StringBuffer();
    buf.writeln('# $title');
    buf.writeln();
    buf.writeln(
      '> **Dywizja:** ${stats.divisionName} (${stats.countryIso.toUpperCase()}) | '
      '**Dyrektor Sportowy:** ${stats.managerName} | '
      '**Sezon:** ${stats.currentSeasonYear} (Lata: ${stats.seasonsManaged}) | '
      '**Ranking UCI:** #${stats.uciWorldRanking}',
    );
    buf.writeln();

    buf.writeln('## Statystyki Drużyny');
    buf.writeln();
    buf.writeln('| Metryka | Wartość |');
    buf.writeln('| --- | --- |');
    buf.writeln('| Zwycięstwa Ogółem | **${stats.totalWins}** |');
    buf.writeln('| Wielkie Toury (GC) | **${stats.grandTourGcWins}** |');
    buf.writeln('| Monumenty Kolarstwa | **${stats.monumentWins}** |');
    buf.writeln('| Wygrane Etapy | ${stats.stageWins} |');
    buf.writeln('| Triumfy WorldTour | ${stats.worldTourWins} |');
    buf.writeln('| Punkty UCI | ${_formatIntWithSpaces(stats.totalUciPoints)} |');
    buf.writeln('| Budżet Roczny | ${Formatters.formatCurrency(stats.budgetEur)} |');
    buf.writeln('| Prestiż Drużyny | ${stats.teamPrestige.toStringAsFixed(1)} / 100 |');
    if (stats.topRiderName.isNotEmpty) {
      buf.writeln('| Lider Zwycięstw | ${stats.topRiderName} (${stats.topRiderWins} wygranych) |');
    }
    buf.writeln();

    if (seasons.isNotEmpty) {
      buf.writeln('## Kronika Sezonów');
      buf.writeln();
      buf.writeln('| Sezon | Zwycięstwa | Podia | Ranking UCI | Punkty UCI | Budżet | Największy Sukces |');
      buf.writeln('| :---: | :---: | :---: | :---: | :---: | :---: | --- |');
      for (final s in seasons) {
        buf.writeln(
          '| ${s.seasonYear} | ${s.wins} | ${s.podiums} | #${s.uciRank} | '
          '${_formatIntWithSpaces(s.uciPoints)} | '
          '${_escapeMarkdownCell(Formatters.formatCurrency(s.budgetEur))} | '
          '${_escapeMarkdownCell(s.highlightAchievement.isEmpty ? '—' : s.highlightAchievement)} |',
        );
      }
      buf.writeln();
    }

    if (climbs.isNotEmpty) {
      buf.writeln('## Rekordy Podjazdów (KOM)');
      buf.writeln();
      buf.writeln('| Podjazd | Pasmo | Dystans / Śr. % | Czas KOM | Rekordzista | Ekipa | VAM | W/kg | Wyścig (Rok) |');
      buf.writeln('| --- | --- | :---: | :---: | --- | --- | :---: | :---: | --- |');
      for (final c in climbs) {
        buf.writeln(
          '| **${_escapeMarkdownCell(c.climbName)}** | '
          '${_escapeMarkdownCell(c.mountainRange)} (${c.countryIso}) | '
          '${c.lengthKm.toStringAsFixed(1)} km @ ${c.averageGradientPct.toStringAsFixed(1)}% | '
          '**${c.formattedRecordTime}** | '
          '${_escapeMarkdownCell(c.recordHolderRiderName)} | '
          '${_escapeMarkdownCell(c.recordHolderTeamName)} | '
          '${c.vamMetersPerHour.round()} m/h | '
          '${c.estimatedWattsPerKg.toStringAsFixed(2)} | '
          '${_escapeMarkdownCell(c.achievedInRaceName)} (${c.achievedInSeasonYear}) |',
        );
      }
      buf.writeln();
    }

    if (trophies.isNotEmpty) {
      buf.writeln('## Gablota Trofeów');
      buf.writeln();
      buf.writeln('| Rok | Wyścig | Kategoria | Kolarz | Szczegóły |');
      buf.writeln('| :---: | --- | --- | --- | --- |');
      for (final t in trophies) {
        final jersey = (t.jerseyWorn != null && t.jerseyWorn!.trim().isNotEmpty)
            ? ' [${t.jerseyWorn}]'
            : '';
        buf.writeln(
          '| ${t.seasonYear} | **${_escapeMarkdownCell(t.raceName)}** | '
          '${_escapeMarkdownCell(t.achievementType.displayName)} | '
          '${_escapeMarkdownCell(t.riderName)} | '
          '${_escapeMarkdownCell('${t.details}$jersey')} |',
        );
      }
      buf.writeln();
    }

    if (riders.isNotEmpty) {
      buf.writeln('## Gwiazdy i Legendy Drużyny');
      buf.writeln();
      buf.writeln('| Kolarz | Kraj | Zwycięstwa | GT GC | Monumenty | Dni Lidera GT | GOAT Pts |');
      buf.writeln('| --- | :---: | :---: | :---: | :---: | :---: | :---: |');
      for (final r in riders) {
        buf.writeln(
          '| **${_escapeMarkdownCell(r.riderName)}** | '
          '${r.nationalityIso.toUpperCase()} | '
          '${r.totalCareerVictories} | '
          '${r.grandTourOverallWins} | '
          '${r.monumentWins} | '
          '${r.totalDaysInGrandTourLeaderJerseys} | '
          '${_formatIntWithSpaces(r.calculateAllTimeGoatPoints)} |',
        );
      }
      buf.writeln();
    }

    buf.writeln('---');
    buf.writeln(
      '*Wygenerowano w ${input.appVersionLabel} • Data eksportu (UTC): ${_formatUtcDateTime(input.generatedAtUtc)}*',
    );

    return buf.toString();
  }

  String _buildSuggestedFileName(
    CareerAlmanacReportInput input,
    CareerAlmanacExportFormat format,
  ) {
    final safeTeam = _slugify(input.teamStats.teamName);
    final dt = input.generatedAtUtc.toUtc();
    final datePart =
        '${dt.year.toString().padLeft(4, '0')}'
        '${dt.month.toString().padLeft(2, '0')}'
        '${dt.day.toString().padLeft(2, '0')}';
    return 'kronika_${safeTeam}_s${input.teamStats.currentSeasonYear}_$datePart.${format.fileExtension}';
  }

  static String _slugify(String raw) {
    final normalized = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'team' : normalized;
  }

  static String _escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static String _escapeMarkdownCell(String input) {
    return input.replaceAll('|', '\\|').replaceAll('\n', ' ').trim();
  }

  static String _sanitizeHexColor(String hex, {required String fallback}) {
    final clean = hex.trim();
    if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(clean)) {
      return clean;
    }
    return fallback;
  }

  static String _formatIntWithSpaces(int value) {
    final str = value.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final posFromEnd = str.length - i;
      if (i > 0 && posFromEnd % 3 == 0) {
        buf.write(' ');
      }
      buf.write(str[i]);
    }
    return value < 0 ? '-${buf.toString()}' : buf.toString();
  }

  static String _formatUtcDateTime(DateTime dt) {
    final u = dt.toUtc();
    String p2(int v) => v.toString().padLeft(2, '0');
    return '${u.year.toString().padLeft(4, '0')}-${p2(u.month)}-${p2(u.day)} '
        '${p2(u.hour)}:${p2(u.minute)}:${p2(u.second)} UTC';
  }
}

// ============================================================================
// PANEL UI EKSPORTU KRONIKI KARIERY (.HTML / .MD) — PALETA AppColors & INTER
// ============================================================================

/// Interaktywny panel eksportu Kroniki Kariery do udostępnienia znajomym.
/// Obsługuje responsywność `390x844` / `1024x768` / `1600x900` oraz pełne stany
/// `hover` / `active` / `disabled` / `focus`.
class CareerAlmanacExporterPanel extends StatefulWidget {
  final CareerAlmanacReportInput? input;
  final ValueChanged<CareerAlmanacExportResult>? onExported;
  final bool enabled;

  const CareerAlmanacExporterPanel({
    super.key,
    required this.input,
    this.onExported,
    this.enabled = true,
  });

  @override
  State<CareerAlmanacExporterPanel> createState() =>
      _CareerAlmanacExporterPanelState();
}

class _CareerAlmanacExporterPanelState
    extends State<CareerAlmanacExporterPanel> {
  final CareerAlmanacHtmlReportExporter _exporter =
      const CareerAlmanacHtmlReportExporter();

  CareerAlmanacExportFormat _selectedFormat = CareerAlmanacExportFormat.html;
  CareerAlmanacThemeStyle _selectedTheme = CareerAlmanacThemeStyle.pelotonNoirGold;
  bool _includeSeasonBreakdown = true;
  bool _includeClimbRecords = true;
  bool _includeTrophies = true;
  bool _includeRiderLeaders = true;
  bool _showSourcePreview = false;

  CareerAlmanacExportResult? _lastResult;
  CareerAlmanacValidationReport? _validationReport;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _recomputeReport();
  }

  @override
  void didUpdateWidget(covariant CareerAlmanacExporterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.input != widget.input) {
      _recomputeReport();
    }
  }

  void _recomputeReport() {
    final input = widget.input;
    if (input == null) {
      _lastResult = null;
      _validationReport = null;
      return;
    }

    final result = _exporter.export(
      input: input,
      format: _selectedFormat,
      themeStyle: _selectedTheme,
      includeSeasonBreakdown: _includeSeasonBreakdown,
      includeClimbRecords: _includeClimbRecords,
      includeTrophies: _includeTrophies,
      includeRiderLeaders: _includeRiderLeaders,
    );
    _lastResult = result;
    _validationReport = _exporter.validateExportedReport(
      result.content,
      _selectedFormat,
    );
  }

  void _triggerExport() {
    if (!widget.enabled || _lastResult == null) return;
    widget.onExported?.call(_lastResult!);
    setState(() {
      _statusMessage =
          'Wygenerowano ${_lastResult!.suggestedFileName} (${_formatBytes(_lastResult!.byteSize)})';
    });
  }

  Future<void> _copyToClipboard() async {
    if (!widget.enabled || _lastResult == null) return;
    await Clipboard.setData(ClipboardData(text: _lastResult!.content));
    if (!mounted) return;
    setState(() {
      _statusMessage =
          'Skopiowano Kronikę ${_selectedFormat.fileExtension.toUpperCase()} do schowka';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasInput = widget.input != null;
    final bool canInteract = widget.enabled && hasInput;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 600;
        final bool isWide = constraints.maxWidth >= 980;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isCompact, hasInput),
                const SizedBox(height: 16),
                if (!hasInput)
                  _buildEmptyState()
                else ...[
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildFormatAndOptionsCard(canInteract),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 6,
                          child: _buildSummaryCard(isCompact),
                        ),
                      ],
                    )
                  else ...[
                    _buildFormatAndOptionsCard(canInteract),
                    const SizedBox(height: 14),
                    _buildSummaryCard(isCompact),
                  ],
                  const SizedBox(height: 16),
                  _buildActionBar(isCompact, canInteract),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 12),
                    _buildStatusBanner(),
                  ],
                  if (_showSourcePreview && _lastResult != null) ...[
                    const SizedBox(height: 14),
                    _buildPreviewBox(),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact, bool hasInput) {
    final bool isValid = _validationReport?.isValid ?? false;
    final stats = widget.input?.teamStats;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.45),
                ),
              ),
              child: const Icon(
                Icons.auto_stories_outlined,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KRONIKA KARIERY (.HTML / .MD)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 13 : 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    hasInput && stats != null
                        ? '${stats.teamName} • Sezon ${stats.currentSeasonYear} • ${stats.totalWins} zwycięstw'
                        : 'Brak danych kariery do wygenerowania kroniki',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (hasInput)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (isValid ? AppColors.statusSuccess : AppColors.amberWarning)
                  .withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: (isValid ? AppColors.statusSuccess : AppColors.amberWarning)
                    .withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isValid ? Icons.verified_outlined : Icons.warning_amber_rounded,
                  size: 14,
                  color: isValid ? AppColors.statusSuccess : AppColors.amberWarning,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isValid ? 'Raport gotowy do udostępnienia' : 'Wymaga weryfikacji',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isValid ? AppColors.statusSuccess : AppColors.amberWarning,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 36,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 10),
          Text(
            'Rozpocznij karierę, aby wygenerować Kronikę',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Eksporter zbierze statystyki drużyny, rekordy KOM oraz trofea do jednego pliku .html lub .md.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatAndOptionsCard(bool canInteract) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FORMAT I ZAKRES KRONIKI',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          for (final format in CareerAlmanacExportFormat.values) ...[
            _InteractiveOptionTile(
              title: format.displayName,
              subtitle: format.subtitle,
              selected: _selectedFormat == format,
              enabled: canInteract,
              accentColor: AppColors.goldAccent,
              onTap: () {
                setState(() {
                  _selectedFormat = format;
                  _recomputeReport();
                });
              },
            ),
            const SizedBox(height: 8),
          ],
          if (_selectedFormat == CareerAlmanacExportFormat.html) ...[
            const SizedBox(height: 4),
            const Text(
              'MOTYW WIZUALNY HTML',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CareerAlmanacThemeStyle.values.map((style) {
                return _InteractiveFilterChip(
                  label: style.displayName,
                  selected: _selectedTheme == style,
                  enabled: canInteract,
                  onTap: () {
                    setState(() {
                      _selectedTheme = style;
                      _recomputeReport();
                    });
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'SEKCJE W RAPORCIE',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InteractiveFilterChip(
                label: 'Sezony',
                selected: _includeSeasonBreakdown,
                enabled: canInteract,
                onTap: () {
                  setState(() {
                    _includeSeasonBreakdown = !_includeSeasonBreakdown;
                    _recomputeReport();
                  });
                },
              ),
              _InteractiveFilterChip(
                label: 'Rekordy KOM',
                selected: _includeClimbRecords,
                enabled: canInteract,
                onTap: () {
                  setState(() {
                    _includeClimbRecords = !_includeClimbRecords;
                    _recomputeReport();
                  });
                },
              ),
              _InteractiveFilterChip(
                label: 'Trofea',
                selected: _includeTrophies,
                enabled: canInteract,
                onTap: () {
                  setState(() {
                    _includeTrophies = !_includeTrophies;
                    _recomputeReport();
                  });
                },
              ),
              _InteractiveFilterChip(
                label: 'Legendy',
                selected: _includeRiderLeaders,
                enabled: canInteract,
                onTap: () {
                  setState(() {
                    _includeRiderLeaders = !_includeRiderLeaders;
                    _recomputeReport();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isCompact) {
    final res = _lastResult;
    final stats = widget.input!.teamStats;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PODSUMOWANIE ZAWARTOŚCI',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricBadge(
                label: 'Zwycięstwa',
                value: '${stats.totalWins}',
                color: AppColors.goldAccent,
                compact: isCompact,
              ),
              _MetricBadge(
                label: 'Trofea',
                value: '${res?.trophyCount ?? 0}',
                color: AppColors.primaryAccent,
                compact: isCompact,
              ),
              _MetricBadge(
                label: 'Rekordy KOM',
                value: '${res?.climbRecordCount ?? 0}',
                color: AppColors.accentBlue,
                compact: isCompact,
              ),
              _MetricBadge(
                label: 'Sezony',
                value: '${res?.seasonCount ?? 0}',
                color: AppColors.statusSuccess,
                compact: isCompact,
              ),
              _MetricBadge(
                label: 'Legendy',
                value: '${res?.riderLeaderCount ?? 0}',
                color: AppColors.cyanAccent,
                compact: isCompact,
              ),
              _MetricBadge(
                label: 'Rozmiar',
                value: _formatBytes(res?.byteSize ?? 0),
                color: AppColors.textPrimary,
                compact: isCompact,
              ),
            ],
          ),
          if (res != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                'Plik: ${res.suggestedFileName}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBar(bool isCompact, bool canInteract) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      children: [
        _InteractiveActionButton(
          label: 'Eksportuj Kronikę (.${_selectedFormat.fileExtension})',
          icon: Icons.download_rounded,
          isPrimary: true,
          enabled: canInteract && _lastResult != null,
          onPressed: _triggerExport,
        ),
        _InteractiveActionButton(
          label: 'Kopiuj kod',
          icon: Icons.copy_rounded,
          isPrimary: false,
          enabled: canInteract && _lastResult != null,
          onPressed: _copyToClipboard,
        ),
        _InteractiveActionButton(
          label: _showSourcePreview ? 'Ukryj podgląd' : 'Podgląd źródła',
          icon: _showSourcePreview ? Icons.visibility_off_outlined : Icons.code_rounded,
          isPrimary: false,
          enabled: canInteract && _lastResult != null,
          onPressed: () {
            setState(() {
              _showSourcePreview = !_showSourcePreview;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.statusSuccess.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.statusSuccess.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: AppColors.statusSuccess),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBox() {
    final content = _lastResult!.content;
    final preview = content.length > 1800
        ? '${content.substring(0, 1800)}\n... [skrócono podgląd]'
        : content;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 240),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          preview,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024.0;
    return '${kb.toStringAsFixed(1)} KB';
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool compact;

  const _MetricBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: compact ? 92 : 112),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveOptionTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractiveOptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveOptionTile> createState() => _InteractiveOptionTileState();
}

class _InteractiveOptionTileState extends State<_InteractiveOptionTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    if (!widget.enabled) {
      borderColor = AppColors.cardBorder.withValues(alpha: 0.45);
    } else if (_focused) {
      borderColor = AppColors.accentBlue;
    } else if (widget.selected) {
      borderColor = widget.accentColor;
    } else if (_hovered) {
      borderColor = AppColors.textSecondary.withValues(alpha: 0.6);
    } else {
      borderColor = AppColors.cardBorder;
    }

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: !widget.enabled
                  ? AppColors.surface.withValues(alpha: 0.45)
                  : _pressed
                      ? AppColors.surface.withValues(alpha: 0.9)
                      : widget.selected
                          ? widget.accentColor.withValues(alpha: 0.12)
                          : _hovered
                              ? AppColors.surface.withValues(alpha: 0.75)
                              : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: widget.selected ? 1.4 : 1.0),
            ),
            child: Row(
              children: [
                Icon(
                  widget.selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: !widget.enabled
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
                      : widget.selected
                          ? widget.accentColor
                          : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.enabled
                              ? AppColors.textPrimary
                              : AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: widget.enabled
                              ? AppColors.textSecondary
                              : AppColors.textSecondary.withValues(alpha: 0.45),
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

class _InteractiveFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _InteractiveFilterChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_InteractiveFilterChip> createState() => _InteractiveFilterChipState();
}

class _InteractiveFilterChipState extends State<_InteractiveFilterChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : _focused
            ? AppColors.accentBlue
            : widget.selected
                ? AppColors.goldAccent
                : _hovered
                    ? AppColors.textSecondary
                    : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: !widget.enabled
                  ? AppColors.surface.withValues(alpha: 0.4)
                  : _pressed
                      ? AppColors.goldAccent.withValues(alpha: 0.24)
                      : widget.selected
                          ? AppColors.goldAccent.withValues(alpha: 0.16)
                          : _hovered
                              ? AppColors.surface
                              : AppColors.background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.selected ? Icons.check_rounded : Icons.add_rounded,
                  size: 13,
                  color: !widget.enabled
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
                      : widget.selected
                          ? AppColors.goldAccent
                          : AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: !widget.enabled
                        ? AppColors.textSecondary.withValues(alpha: 0.4)
                        : widget.selected
                            ? AppColors.goldAccent
                            : AppColors.textPrimary,
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

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color border;

    if (!widget.enabled) {
      bg = AppColors.surfaceLight.withValues(alpha: 0.5);
      fg = AppColors.textSecondary.withValues(alpha: 0.45);
      border = AppColors.cardBorder.withValues(alpha: 0.45);
    } else if (widget.isPrimary) {
      bg = _pressed
          ? AppColors.goldAccent.withValues(alpha: 0.8)
          : _hovered
              ? AppColors.goldAccent
              : AppColors.goldAccent.withValues(alpha: 0.92);
      fg = AppColors.background;
      border = _focused ? AppColors.accentBlue : AppColors.goldAccent;
    } else {
      bg = _pressed
          ? AppColors.surface
          : _hovered
              ? AppColors.surfaceLight
              : AppColors.surface;
      fg = AppColors.textPrimary;
      border = _focused
          ? AppColors.accentBlue
          : _hovered
              ? AppColors.textSecondary
              : AppColors.cardBorder;
    }

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: _focused ? 1.5 : 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 17, color: fg),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      color: fg,
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
