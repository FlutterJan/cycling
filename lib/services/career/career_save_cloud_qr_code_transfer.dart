import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/career/pro_cyclist_career_state.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_appearance.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/rider/rider_health.dart';
import '../../models/rider/rider_physiology.dart';
import '../../models/rider/rider_power_profile.dart';
import '../../models/rider/rider_skills.dart';
import '../../models/team/bike_manufacturer_deal.dart';
import '../../models/team/cycling_team.dart';

/// Typ danych przenoszonych przez szybki transfer QR / Base64.
enum TransferPayloadKind {
  beAProProfile,
  teamRaceRoster;

  String toJson() => name;

  String get shortCode {
    switch (this) {
      case TransferPayloadKind.beAProProfile:
        return 'BAP';
      case TransferPayloadKind.teamRaceRoster:
        return 'TRS';
    }
  }

  String get label {
    switch (this) {
      case TransferPayloadKind.beAProProfile:
        return 'Profil Be a Pro';
      case TransferPayloadKind.teamRaceRoster:
        return 'Skład Wyścigowy Drużyny';
    }
  }

  static TransferPayloadKind fromJson(String value) {
    return TransferPayloadKind.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TransferPayloadKind.beAProProfile,
    );
  }

  static TransferPayloadKind? fromShortCode(String code) {
    switch (code.toUpperCase()) {
      case 'BAP':
        return TransferPayloadKind.beAProProfile;
      case 'TRS':
        return TransferPayloadKind.teamRaceRoster;
      default:
        return null;
    }
  }
}

/// Platforma źródłowa lub docelowa transferu między komputerem a telefonem.
enum TransferPlatformOrigin {
  windowsDesktop,
  macOsDesktop,
  linuxDesktop,
  androidMobile,
  iOsMobile,
  webBrowser;

  String toJson() => name;

  String get label {
    switch (this) {
      case TransferPlatformOrigin.windowsDesktop:
        return 'Windows PC';
      case TransferPlatformOrigin.macOsDesktop:
        return 'macOS Desktop';
      case TransferPlatformOrigin.linuxDesktop:
        return 'Linux Desktop';
      case TransferPlatformOrigin.androidMobile:
        return 'Android Mobile';
      case TransferPlatformOrigin.iOsMobile:
        return 'iOS Mobile';
      case TransferPlatformOrigin.webBrowser:
        return 'Web';
    }
  }

  static TransferPlatformOrigin fromJson(String value) {
    return TransferPlatformOrigin.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TransferPlatformOrigin.windowsDesktop,
    );
  }
}

/// Poziom korekcji błędów kodu QR (Reed-Solomon).
enum TransferQrErrorCorrectionLevel {
  low,
  medium,
  quartile,
  high;

  String get code {
    switch (this) {
      case TransferQrErrorCorrectionLevel.low:
        return 'L';
      case TransferQrErrorCorrectionLevel.medium:
        return 'M';
      case TransferQrErrorCorrectionLevel.quartile:
        return 'Q';
      case TransferQrErrorCorrectionLevel.high:
        return 'H';
    }
  }

  String get description {
    switch (this) {
      case TransferQrErrorCorrectionLevel.low:
        return 'L (7% korekcji — najgęstszy zapis)';
      case TransferQrErrorCorrectionLevel.medium:
        return 'M (15% korekcji — zbalansowany)';
      case TransferQrErrorCorrectionLevel.quartile:
        return 'Q (25% korekcji — wysoka odporność)';
      case TransferQrErrorCorrectionLevel.high:
        return 'H (30% korekcji — maksymalna pewność)';
    }
  }

  int get formatIndicatorBits {
    switch (this) {
      case TransferQrErrorCorrectionLevel.low:
        return 1; // 01
      case TransferQrErrorCorrectionLevel.medium:
        return 0; // 00
      case TransferQrErrorCorrectionLevel.quartile:
        return 3; // 11
      case TransferQrErrorCorrectionLevel.high:
        return 2; // 10
    }
  }
}

/// Status walidacji zeskanowanego tokena lub kodu QR.
enum TransferScanValidationStatus {
  valid,
  emptyInput,
  invalidPrefix,
  unsupportedVersion,
  corruptedBase64,
  checksumMismatch,
  decompressionFailed,
  malformedJson;

  bool get isSuccess => this == TransferScanValidationStatus.valid;

  String get label {
    switch (this) {
      case TransferScanValidationStatus.valid:
        return 'Token zweryfikowany poprawnie';
      case TransferScanValidationStatus.emptyInput:
        return 'Puste pole tokena';
      case TransferScanValidationStatus.invalidPrefix:
        return 'Nieprawidłowy nagłówek (wymagany PPM1:)';
      case TransferScanValidationStatus.unsupportedVersion:
        return 'Nieobsługiwana wersja protokołu transferu';
      case TransferScanValidationStatus.corruptedBase64:
        return 'Uszkodzone kodowanie Base64URL';
      case TransferScanValidationStatus.checksumMismatch:
        return 'Błąd sumy kontrolnej CRC32 — token ucięty lub zmodyfikowany';
      case TransferScanValidationStatus.decompressionFailed:
        return 'Błąd dekompresji ZLib ładunku';
      case TransferScanValidationStatus.malformedJson:
        return 'Nieprawidłowa struktura JSON profilu lub składu';
    }
  }
}

/// Kierunek operacji w historii transferów.
enum TransferHistoryDirection {
  exported,
  imported;

  String get label {
    switch (this) {
      case TransferHistoryDirection.exported:
        return 'Eksport';
      case TransferHistoryDirection.imported:
        return 'Import';
    }
  }
}

/// Kompaktowy zrzut profilu kolarza z trybu Be a Pro do szybkiego transferu.
class BeAProTransferSnapshot {
  final String careerId;
  final String careerName;
  final Rider playerRider;
  final int seasonYear;
  final String currentTeamId;
  final String currentTeamName;
  final TeamDivision currentDivision;
  final ProCyclistCareerTier careerTier;
  final double dsTrustScore;
  final int skillPoints;
  final int experienceXp;
  final int careerLevel;
  final int privateBalanceEur;
  final int careerEarningsEur;
  final double fameScore;
  final int fanFollowersCount;
  final ProCyclistPalmares palmares;
  final Map<String, dynamic>? fullCareerStateJson;

  const BeAProTransferSnapshot({
    required this.careerId,
    required this.careerName,
    required this.playerRider,
    required this.seasonYear,
    required this.currentTeamId,
    required this.currentTeamName,
    required this.currentDivision,
    required this.careerTier,
    required this.dsTrustScore,
    required this.skillPoints,
    required this.experienceXp,
    required this.careerLevel,
    required this.privateBalanceEur,
    required this.careerEarningsEur,
    required this.fameScore,
    required this.fanFollowersCount,
    required this.palmares,
    this.fullCareerStateJson,
  });

  factory BeAProTransferSnapshot.fromProCyclistState(
    ProCyclistCareerState state, {
    bool includeFullCareerState = true,
  }) {
    return BeAProTransferSnapshot(
      careerId: state.careerId,
      careerName: state.careerName,
      playerRider: state.playerRider,
      seasonYear: state.seasonYear,
      currentTeamId: state.currentTeamId,
      currentTeamName: state.currentTeamName,
      currentDivision: state.currentDivision,
      careerTier: state.careerTier,
      dsTrustScore: state.dsTrustScore,
      skillPoints: state.skillPoints,
      experienceXp: state.experienceXp,
      careerLevel: state.careerLevel,
      privateBalanceEur: state.privateBalanceEur,
      careerEarningsEur: state.careerEarningsEur,
      fameScore: state.fameScore,
      fanFollowersCount: state.fanFollowersCount,
      palmares: state.palmares,
      fullCareerStateJson: includeFullCareerState ? state.toJson() : null,
    );
  }

  /// Odtwarza pełny stan `ProCyclistCareerState`, jeśli został osadzony lub na podstawie bazowego stanu.
  ProCyclistCareerState toProCyclistCareerState({
    ProCyclistCareerState? fallbackBase,
  }) {
    if (fullCareerStateJson != null) {
      return ProCyclistCareerState.fromJson(fullCareerStateJson!);
    }
    if (fallbackBase != null) {
      return fallbackBase.copyWith(
        careerId: careerId,
        careerName: careerName,
        playerRider: playerRider,
        seasonYear: seasonYear,
        currentTeamId: currentTeamId,
        currentTeamName: currentTeamName,
        currentDivision: currentDivision,
        careerTier: careerTier,
        dsTrustScore: dsTrustScore,
        skillPoints: skillPoints,
        experienceXp: experienceXp,
        careerLevel: careerLevel,
        privateBalanceEur: privateBalanceEur,
        careerEarningsEur: careerEarningsEur,
        fameScore: fameScore,
        fanFollowersCount: fanFollowersCount,
        palmares: palmares,
      );
    }
    final now = DateTime.utc(seasonYear, 1, 1);
    return ProCyclistCareerState(
      careerId: careerId,
      careerName: careerName,
      playerRider: playerRider,
      currentDate: now,
      careerStartDate: now,
      seasonYear: seasonYear,
      currentTeamId: currentTeamId,
      currentTeamName: currentTeamName,
      currentDivision: currentDivision,
      careerTier: careerTier,
      dsTrustScore: dsTrustScore,
      skillPoints: skillPoints,
      experienceXp: experienceXp,
      careerLevel: careerLevel,
      totalSkillPointsEarned: skillPoints,
      totalSkillPointsSpent: 0,
      privateBalanceEur: privateBalanceEur,
      careerEarningsEur: careerEarningsEur,
      monthlyLivingExpensesEur: 2500,
      fameScore: fameScore,
      fanFollowersCount: fanFollowersCount,
      ownedProperties: const [],
      ownedPrivateEquipment: const [],
      activePersonalSponsors: const [],
      achievementJournal: const [],
      palmares: palmares,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'careerId': careerId,
      'careerName': careerName,
      'playerRider': playerRider.toJson(),
      'seasonYear': seasonYear,
      'currentTeamId': currentTeamId,
      'currentTeamName': currentTeamName,
      'currentDivision': currentDivision.toJson(),
      'careerTier': careerTier.toJson(),
      'dsTrustScore': dsTrustScore,
      'skillPoints': skillPoints,
      'experienceXp': experienceXp,
      'careerLevel': careerLevel,
      'privateBalanceEur': privateBalanceEur,
      'careerEarningsEur': careerEarningsEur,
      'fameScore': fameScore,
      'fanFollowersCount': fanFollowersCount,
      'palmares': palmares.toJson(),
      if (fullCareerStateJson != null) 'fullCareerState': fullCareerStateJson,
    };
  }

  factory BeAProTransferSnapshot.fromJson(Map<String, dynamic> json) {
    return BeAProTransferSnapshot(
      careerId: json['careerId'] as String? ?? 'bap_transfer',
      careerName: json['careerName'] as String? ?? 'Be a Pro Transfer',
      playerRider: Rider.fromJson(json['playerRider'] as Map<String, dynamic>),
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      currentTeamId: json['currentTeamId'] as String? ?? 'team_0',
      currentTeamName: json['currentTeamName'] as String? ?? 'Pro Cycling Team',
      currentDivision: TeamDivision.fromJson(
        json['currentDivision'] as String? ?? 'worldTour',
      ),
      careerTier: ProCyclistCareerTier.fromJson(
        json['careerTier'] as String? ?? 'worldTourDomestique',
      ),
      dsTrustScore: (json['dsTrustScore'] as num?)?.toDouble() ?? 50.0,
      skillPoints: (json['skillPoints'] as num?)?.toInt() ?? 0,
      experienceXp: (json['experienceXp'] as num?)?.toInt() ?? 0,
      careerLevel: (json['careerLevel'] as num?)?.toInt() ?? 1,
      privateBalanceEur: (json['privateBalanceEur'] as num?)?.toInt() ?? 0,
      careerEarningsEur: (json['careerEarningsEur'] as num?)?.toInt() ?? 0,
      fameScore: (json['fameScore'] as num?)?.toDouble() ?? 10.0,
      fanFollowersCount: (json['fanFollowersCount'] as num?)?.toInt() ?? 0,
      palmares: json['palmares'] is Map<String, dynamic>
          ? ProCyclistPalmares.fromJson(json['palmares'] as Map<String, dynamic>)
          : const ProCyclistPalmares(),
      fullCareerStateJson: json['fullCareerState'] is Map<String, dynamic>
          ? json['fullCareerState'] as Map<String, dynamic>
          : null,
    );
  }
}

/// Zrzut wyścigowego składu drużyny do szybkiego przeniesienia między urządzeniami.
class TeamRaceRosterTransferSnapshot {
  final String teamId;
  final String teamName;
  final TeamDivision division;
  final String countryIso;
  final String primaryJerseyColorHex;
  final String secondaryJerseyColorHex;
  final String accentJerseyColorHex;
  final int cashBalanceEur;
  final int uciPointsSeason;
  final int seasonYear;
  final String raceTitle;
  final String? leaderRiderId;
  final String? sprinterRiderId;
  final List<Rider> raceRoster;

  const TeamRaceRosterTransferSnapshot({
    required this.teamId,
    required this.teamName,
    required this.division,
    required this.countryIso,
    required this.primaryJerseyColorHex,
    required this.secondaryJerseyColorHex,
    required this.accentJerseyColorHex,
    required this.cashBalanceEur,
    required this.uciPointsSeason,
    required this.seasonYear,
    required this.raceTitle,
    required this.raceRoster,
    this.leaderRiderId,
    this.sprinterRiderId,
  });

  factory TeamRaceRosterTransferSnapshot.fromTeamAndRoster({
    required CyclingTeam team,
    required List<Rider> raceRoster,
    String? leaderRiderId,
    String? sprinterRiderId,
    String raceTitle = 'Wyścigowy Skład Startowy',
    int seasonYear = 2026,
  }) {
    return TeamRaceRosterTransferSnapshot(
      teamId: team.id,
      teamName: team.name,
      division: team.division,
      countryIso: team.countryIso,
      primaryJerseyColorHex: team.primaryJerseyColorHex,
      secondaryJerseyColorHex: team.secondaryJerseyColorHex,
      accentJerseyColorHex: team.accentJerseyColorHex,
      cashBalanceEur: team.cashBalanceEur,
      uciPointsSeason: team.uciPointsSeason,
      seasonYear: seasonYear,
      raceTitle: raceTitle,
      raceRoster: List<Rider>.unmodifiable(raceRoster),
      leaderRiderId: leaderRiderId,
      sprinterRiderId: sprinterRiderId,
    );
  }

  double get averageOverallRating {
    if (raceRoster.isEmpty) return 0.0;
    final sum = raceRoster.fold<int>(0, (acc, r) => acc + r.overallRating);
    return sum / raceRoster.length;
  }

  double get averageFtpWkg {
    if (raceRoster.isEmpty) return 0.0;
    final sum = raceRoster.fold<double>(
      0.0,
      (acc, r) => acc + r.physiology.wattsPerKg,
    );
    return sum / raceRoster.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'division': division.toJson(),
      'countryIso': countryIso,
      'primaryJerseyColorHex': primaryJerseyColorHex,
      'secondaryJerseyColorHex': secondaryJerseyColorHex,
      'accentJerseyColorHex': accentJerseyColorHex,
      'cashBalanceEur': cashBalanceEur,
      'uciPointsSeason': uciPointsSeason,
      'seasonYear': seasonYear,
      'raceTitle': raceTitle,
      if (leaderRiderId != null) 'leaderRiderId': leaderRiderId,
      if (sprinterRiderId != null) 'sprinterRiderId': sprinterRiderId,
      'raceRoster': raceRoster.map((r) => r.toJson()).toList(),
    };
  }

  factory TeamRaceRosterTransferSnapshot.fromJson(Map<String, dynamic> json) {
    final rawRoster = json['raceRoster'] as List<dynamic>? ?? const [];
    return TeamRaceRosterTransferSnapshot(
      teamId: json['teamId'] as String? ?? 'team_transfer',
      teamName: json['teamName'] as String? ?? 'Transferred Cycling Team',
      division: TeamDivision.fromJson(
        json['division'] as String? ?? 'worldTour',
      ),
      countryIso: json['countryIso'] as String? ?? 'POL',
      primaryJerseyColorHex: json['primaryJerseyColorHex'] as String? ?? '#8E4A49',
      secondaryJerseyColorHex:
          json['secondaryJerseyColorHex'] as String? ?? '#181B22',
      accentJerseyColorHex: json['accentJerseyColorHex'] as String? ?? '#D4AF37',
      cashBalanceEur: (json['cashBalanceEur'] as num?)?.toInt() ?? 0,
      uciPointsSeason: (json['uciPointsSeason'] as num?)?.toInt() ?? 0,
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      raceTitle: json['raceTitle'] as String? ?? 'Skład Wyścigowy',
      leaderRiderId: json['leaderRiderId'] as String?,
      sprinterRiderId: json['sprinterRiderId'] as String?,
      raceRoster: rawRoster
          .whereType<Map<String, dynamic>>()
          .map(Rider.fromJson)
          .toList(),
    );
  }
}

/// Koperta kompaktowego tokena transferowego `PPM1:<KIND>.<BASE64URL>.<CRC32>`.
class CompactTransferTokenEnvelope {
  final int protocolVersion;
  final TransferPayloadKind kind;
  final TransferPlatformOrigin origin;
  final DateTime createdAtUtc;
  final String checksumHex;
  final String compressedBase64;
  final int rawJsonBytes;
  final int compressedBytes;
  final BeAProTransferSnapshot? beAProSnapshot;
  final TeamRaceRosterTransferSnapshot? teamRosterSnapshot;

  const CompactTransferTokenEnvelope({
    required this.protocolVersion,
    required this.kind,
    required this.origin,
    required this.createdAtUtc,
    required this.checksumHex,
    required this.compressedBase64,
    required this.rawJsonBytes,
    required this.compressedBytes,
    this.beAProSnapshot,
    this.teamRosterSnapshot,
  });

  String get tokenString =>
      'PPM$protocolVersion:${kind.shortCode}.$compressedBase64.$checksumHex';

  double get compressionRatio {
    if (rawJsonBytes <= 0) return 1.0;
    return compressedBytes / rawJsonBytes;
  }

  double get spaceSavedPercent {
    if (rawJsonBytes <= 0) return 0.0;
    return ((1.0 - compressionRatio) * 100.0).clamp(0.0, 99.9);
  }

  bool get isCompactEnoughForQr => utf8.encode(tokenString).length <= 2953;
}

/// Wynik skanowania lub wklejenia tokena transferowego.
class TransferScanResult {
  final TransferScanValidationStatus status;
  final CompactTransferTokenEnvelope? envelope;
  final String diagnosticMessage;
  final DateTime parsedAtUtc;

  const TransferScanResult({
    required this.status,
    required this.diagnosticMessage,
    required this.parsedAtUtc,
    this.envelope,
  });

  bool get isValid => status.isSuccess && envelope != null;
}

/// Paczka wyjściowa generatora zawierająca token Base64URL oraz matrycę kodu QR.
class CareerTransferExportBundle {
  final CompactTransferTokenEnvelope envelope;
  final QrCodeMatrix qrMatrix;
  final Duration generationTime;

  const CareerTransferExportBundle({
    required this.envelope,
    required this.qrMatrix,
    required this.generationTime,
  });

  String get token => envelope.tokenString;
}

/// Wpis w historii ostatnich eksportów i importów transferowych.
class TransferHistoryEntry {
  final String id;
  final TransferPayloadKind kind;
  final TransferHistoryDirection direction;
  final String title;
  final String subtitle;
  final String tokenFull;
  final String checksumHex;
  final int byteSize;
  final DateTime timestampUtc;

  const TransferHistoryEntry({
    required this.id,
    required this.kind,
    required this.direction,
    required this.title,
    required this.subtitle,
    required this.tokenFull,
    required this.checksumHex,
    required this.byteSize,
    required this.timestampUtc,
  });

  String get tokenPreview {
    if (tokenFull.length <= 34) return tokenFull;
    return '${tokenFull.substring(0, 18)}...${tokenFull.substring(tokenFull.length - 12)}';
  }
}

/// Wygenerowana dwuwymiarowa matryca kodu QR zgodna ze standardem ISO/IEC 18004 (tryb Byte).
class QrCodeMatrix {
  final int version;
  final int size;
  final List<List<bool>> modules;
  final TransferQrErrorCorrectionLevel errorCorrectionLevel;
  final int maskPattern;
  final int payloadByteLength;

  const QrCodeMatrix({
    required this.version,
    required this.size,
    required this.modules,
    required this.errorCorrectionLevel,
    required this.maskPattern,
    required this.payloadByteLength,
  });

  bool isDark(int row, int col) {
    if (row < 0 || row >= size || col < 0 || col >= size) return false;
    return modules[row][col];
  }
}

/// Czysto-dartowy generator kodów QR (ISO/IEC 18004, tryb Byte, GF(256) Reed-Solomon).
class QrCodeMatrixGenerator {
  QrCodeMatrixGenerator._();

  static const int _maxQrByteCapacityLevelL = 2953;

  // Liczba słów kodowych (data + EC) dla wersji 1..40, w formacie:
  // [totalCodewords, ecCodewordsPerBlockL, blocksL, ecCodewordsPerBlockM, blocksM, ecPerQ, blkQ, ecPerH, blkH]
  static const List<List<int>> _versionTable = [
    // v1..v10
    [26, 7, 1, 10, 1, 13, 1, 17, 1],
    [44, 10, 1, 16, 1, 22, 1, 28, 1],
    [70, 15, 1, 26, 1, 18, 2, 22, 2],
    [100, 20, 1, 18, 2, 26, 2, 16, 4],
    [134, 26, 1, 24, 2, 18, 4, 22, 4],
    [172, 18, 2, 16, 4, 24, 4, 28, 4],
    [196, 20, 2, 18, 4, 18, 6, 26, 5],
    [242, 24, 2, 22, 4, 22, 6, 26, 6],
    [292, 30, 2, 22, 5, 20, 8, 24, 8],
    [346, 18, 4, 26, 5, 24, 8, 28, 8],
    // v11..v20
    [404, 20, 4, 30, 5, 28, 8, 24, 11],
    [466, 24, 4, 22, 8, 26, 10, 28, 11],
    [532, 26, 4, 22, 9, 24, 12, 22, 16],
    [581, 30, 4, 24, 9, 20, 16, 24, 16],
    [655, 22, 6, 24, 10, 30, 12, 24, 18],
    [733, 24, 6, 28, 10, 24, 17, 30, 16],
    [815, 28, 6, 28, 11, 28, 16, 28, 19],
    [901, 30, 6, 26, 13, 28, 18, 28, 21],
    [991, 28, 7, 26, 14, 26, 21, 26, 25],
    [1085, 28, 8, 26, 16, 30, 20, 28, 25],
    // v21..v30
    [1156, 28, 8, 26, 17, 28, 23, 30, 25],
    [1258, 28, 9, 28, 17, 30, 23, 24, 34],
    [1364, 30, 9, 28, 18, 30, 25, 30, 30],
    [1474, 30, 10, 28, 20, 30, 27, 30, 32],
    [1588, 26, 12, 28, 21, 30, 29, 30, 35],
    [1706, 28, 12, 28, 23, 28, 34, 30, 37],
    [1828, 30, 12, 28, 25, 30, 34, 30, 40],
    [1921, 30, 13, 28, 26, 30, 35, 30, 42],
    [2051, 30, 14, 28, 28, 30, 38, 30, 45],
    [2185, 30, 15, 28, 29, 30, 40, 30, 48],
    // v31..v40
    [2323, 30, 16, 28, 31, 30, 43, 30, 51],
    [2465, 30, 17, 28, 33, 30, 45, 30, 54],
    [2611, 30, 18, 28, 35, 30, 48, 30, 57],
    [2761, 30, 19, 28, 37, 30, 51, 30, 60],
    [2876, 30, 19, 28, 38, 30, 53, 30, 63],
    [3034, 30, 20, 28, 40, 30, 56, 30, 66],
    [3196, 30, 21, 28, 43, 30, 59, 30, 70],
    [3362, 30, 22, 28, 45, 30, 62, 30, 74],
    [3532, 30, 24, 28, 47, 30, 65, 30, 77],
    [3706, 30, 25, 28, 49, 30, 68, 30, 81],
  ];

  static final List<int> _gfExp = _buildGfExp();
  static final List<int> _gfLog = _buildGfLog(_gfExp);

  static List<int> _buildGfExp() {
    final exp = List<int>.filled(512, 0);
    int v = 1;
    for (int i = 0; i < 255; i++) {
      exp[i] = v;
      v <<= 1;
      if ((v & 0x100) != 0) {
        v ^= 0x11D;
      }
    }
    for (int i = 255; i < 512; i++) {
      exp[i] = exp[i - 255];
    }
    return exp;
  }

  static List<int> _buildGfLog(List<int> exp) {
    final log = List<int>.filled(256, 0);
    for (int i = 0; i < 255; i++) {
      log[exp[i]] = i;
    }
    return log;
  }

  static int _gfMul(int a, int b) {
    if (a == 0 || b == 0) return 0;
    return _gfExp[_gfLog[a] + _gfLog[b]];
  }

  static List<int> _rsGeneratorPoly(int degree) {
    var poly = <int>[1];
    for (int i = 0; i < degree; i++) {
      final factor = [1, _gfExp[i]];
      final next = List<int>.filled(poly.length + 1, 0);
      for (int p = 0; p < poly.length; p++) {
        for (int f = 0; f < factor.length; f++) {
          next[p + f] ^= _gfMul(poly[p], factor[f]);
        }
      }
      poly = next;
    }
    return poly;
  }

  static List<int> _rsComputeRemainder(List<int> data, int ecCount) {
    final gen = _rsGeneratorPoly(ecCount);
    final res = List<int>.filled(ecCount, 0, growable: true);
    for (final byte in data) {
      final factor = byte ^ res[0];
      res.removeAt(0);
      res.add(0);
      for (int i = 0; i < ecCount; i++) {
        res[i] ^= _gfMul(gen[i + 1], factor);
      }
    }
    return res;
  }

  /// Generuje pełną matrycę QR dla podanego tekstu UTF-8.
  static QrCodeMatrix generate(
    String text, {
    TransferQrErrorCorrectionLevel errorCorrectionLevel =
        TransferQrErrorCorrectionLevel.medium,
  }) {
    final rawBytes = utf8.encode(text);
    if (rawBytes.length > _maxQrByteCapacityLevelL) {
      throw ArgumentError(
        'Ładunek (${rawBytes.length} B) przekracza maksymalną pojemność QR ($_maxQrByteCapacityLevelL B).',
      );
    }

    var effectiveEc = errorCorrectionLevel;
    int version = _findMinVersion(rawBytes.length, effectiveEc);
    if (version == -1) {
      // Automatyczne obniżenie EC do L, aby zmieścić duży skład drużyny w kodzie QR.
      effectiveEc = TransferQrErrorCorrectionLevel.low;
      version = _findMinVersion(rawBytes.length, effectiveEc);
    }
    if (version == -1) {
      throw StateError('Nie można dobrać wersji QR dla ${rawBytes.length} B.');
    }

    final codewords = _buildInterleavedCodewords(rawBytes, version, effectiveEc);
    final size = version * 4 + 17;
    final isFunction = List.generate(size, (_) => List<bool>.filled(size, false));
    final modules = List.generate(size, (_) => List<bool>.filled(size, false));

    _placeFunctionPatterns(modules, isFunction, version, size);
    _placeDataBits(modules, isFunction, codewords, size);

    // Wybór najlepszej maski (0..7) według reguły karnej lub deterministycznie dla dużych matryc.
    int bestMask = 0;
    int bestPenalty = 1 << 30;
    for (int mask = 0; mask < 8; mask++) {
      final candidate = List.generate(
        size,
        (r) => List<bool>.from(modules[r]),
      );
      _applyMask(candidate, isFunction, mask, size);
      _drawFormatBits(candidate, effectiveEc, mask, size);
      if (version >= 7) {
        _drawVersionBits(candidate, version, size);
      }
      final penalty = _evaluatePenalty(candidate, size);
      if (penalty < bestPenalty) {
        bestPenalty = penalty;
        bestMask = mask;
      }
    }

    _applyMask(modules, isFunction, bestMask, size);
    _drawFormatBits(modules, effectiveEc, bestMask, size);
    if (version >= 7) {
      _drawVersionBits(modules, version, size);
    }

    return QrCodeMatrix(
      version: version,
      size: size,
      modules: modules,
      errorCorrectionLevel: effectiveEc,
      maskPattern: bestMask,
      payloadByteLength: rawBytes.length,
    );
  }

  static int _findMinVersion(int byteLen, TransferQrErrorCorrectionLevel ec) {
    for (int v = 1; v <= 40; v++) {
      final cap = _dataCapacityBytes(v, ec);
      if (byteLen <= cap) return v;
    }
    return -1;
  }

  static int _dataCapacityBytes(int version, TransferQrErrorCorrectionLevel ec) {
    final row = _versionTable[version - 1];
    final total = row[0];
    final ecIdx = ec.index * 2 + 1;
    final ecPerBlock = row[ecIdx];
    final blocks = row[ecIdx + 1];
    final dataCodewords = total - ecPerBlock * blocks;
    final headerBits = version <= 9 ? 12 : 20; // 4-bit mode + 8/16-bit count
    return ((dataCodewords * 8) - headerBits) ~/ 8;
  }

  static List<int> _buildInterleavedCodewords(
    List<int> rawBytes,
    int version,
    TransferQrErrorCorrectionLevel ec,
  ) {
    final row = _versionTable[version - 1];
    final totalCodewords = row[0];
    final ecIdx = ec.index * 2 + 1;
    final ecPerBlock = row[ecIdx];
    final numBlocks = row[ecIdx + 1];
    final totalDataCodewords = totalCodewords - ecPerBlock * numBlocks;

    final bits = <int>[];
    void appendBits(int value, int bitLength) {
      for (int i = bitLength - 1; i >= 0; i--) {
        bits.add((value >> i) & 1);
      }
    }

    // Mode indicator: Byte = 0100
    appendBits(0x4, 4);
    final countBits = version <= 9 ? 8 : 16;
    appendBits(rawBytes.length, countBits);
    for (final b in rawBytes) {
      appendBits(b, 8);
    }

    final maxDataBits = totalDataCodewords * 8;
    final terminatorLen = math.min(4, maxDataBits - bits.length);
    for (int i = 0; i < terminatorLen; i++) {
      bits.add(0);
    }
    while (bits.length % 8 != 0) {
      bits.add(0);
    }

    final dataCodewords = <int>[];
    for (int i = 0; i < bits.length; i += 8) {
      int byteVal = 0;
      for (int b = 0; b < 8; b++) {
        byteVal = (byteVal << 1) | bits[i + b];
      }
      dataCodewords.add(byteVal);
    }

    const padBytes = [0xEC, 0x11];
    int padIdx = 0;
    while (dataCodewords.length < totalDataCodewords) {
      dataCodewords.add(padBytes[padIdx % 2]);
      padIdx++;
    }

    // Podział na bloki (grupa 1 krótsze, grupa 2 dłuższe)
    final numShortBlocks = numBlocks - (totalDataCodewords % numBlocks);
    final shortBlockLen = totalDataCodewords ~/ numBlocks;
    final blocksData = <List<int>>[];
    final blocksEc = <List<int>>[];

    int offset = 0;
    for (int b = 0; b < numBlocks; b++) {
      final len = b < numShortBlocks ? shortBlockLen : shortBlockLen + 1;
      final block = dataCodewords.sublist(offset, offset + len);
      offset += len;
      blocksData.add(block);
      blocksEc.add(_rsComputeRemainder(block, ecPerBlock));
    }

    final result = <int>[];
    final maxDataLen = shortBlockLen + (numShortBlocks < numBlocks ? 1 : 0);
    for (int i = 0; i < maxDataLen; i++) {
      for (final block in blocksData) {
        if (i < block.length) result.add(block[i]);
      }
    }
    for (int i = 0; i < ecPerBlock; i++) {
      for (final ecBlock in blocksEc) {
        result.add(ecBlock[i]);
      }
    }
    return result;
  }

  static void _placeFunctionPatterns(
    List<List<bool>> modules,
    List<List<bool>> isFunction,
    int version,
    int size,
  ) {
    // 3 Finder Patterns + Separators
    _drawFinderPattern(modules, isFunction, 0, 0, size);
    _drawFinderPattern(modules, isFunction, 0, size - 7, size);
    _drawFinderPattern(modules, isFunction, size - 7, 0, size);

    // Timing Patterns
    for (int i = 8; i < size - 8; i++) {
      final dark = i % 2 == 0;
      modules[6][i] = dark;
      isFunction[6][i] = true;
      modules[i][6] = dark;
      isFunction[i][6] = true;
    }

    // Alignment Patterns
    final alignCoords = _alignmentPatternPositions(version);
    for (final r in alignCoords) {
      for (final c in alignCoords) {
        if ((r <= 8 && c <= 8) ||
            (r <= 8 && c >= size - 9) ||
            (r >= size - 9 && c <= 8)) {
          continue;
        }
        _drawAlignmentPattern(modules, isFunction, r, c);
      }
    }

    // Dark module
    modules[size - 8][8] = true;
    isFunction[size - 8][8] = true;

    // Reserve Format Info areas
    for (int i = 0; i <= 8; i++) {
      if (i != 6) {
        isFunction[8][i] = true;
        isFunction[i][8] = true;
      }
    }
    for (int i = size - 8; i < size; i++) {
      isFunction[8][i] = true;
      isFunction[i][8] = true;
    }

    // Reserve Version Info areas (v >= 7)
    if (version >= 7) {
      for (int i = 0; i < 6; i++) {
        for (int j = 0; j < 3; j++) {
          isFunction[i][size - 11 + j] = true;
          isFunction[size - 11 + j][i] = true;
        }
      }
    }
  }

  static void _drawFinderPattern(
    List<List<bool>> modules,
    List<List<bool>> isFunction,
    int top,
    int left,
    int size,
  ) {
    for (int r = -1; r <= 7; r++) {
      for (int c = -1; c <= 7; c++) {
        final rr = top + r;
        final cc = left + c;
        if (rr < 0 || rr >= size || cc < 0 || cc >= size) continue;
        final inBox = r >= 0 && r <= 6 && c >= 0 && c <= 6;
        final isBorderOrCenter = inBox &&
            (r == 0 ||
                r == 6 ||
                c == 0 ||
                c == 6 ||
                (r >= 2 && r <= 4 && c >= 2 && c <= 4));
        modules[rr][cc] = isBorderOrCenter;
        isFunction[rr][cc] = true;
      }
    }
  }

  static void _drawAlignmentPattern(
    List<List<bool>> modules,
    List<List<bool>> isFunction,
    int centerRow,
    int centerCol,
  ) {
    for (int r = -2; r <= 2; r++) {
      for (int c = -2; c <= 2; c++) {
        final dark = r.abs() == 2 || c.abs() == 2 || (r == 0 && c == 0);
        modules[centerRow + r][centerCol + c] = dark;
        isFunction[centerRow + r][centerCol + c] = true;
      }
    }
  }

  static List<int> _alignmentPatternPositions(int version) {
    if (version == 1) return const [];
    final numAlign = version ~/ 7 + 2;
    final step = version == 32
        ? 26
        : ((version * 4 + numAlign * 2 + 1) ~/ (numAlign * 2 - 2)) * 2;
    final result = <int>[6];
    int pos = version * 4 + 10;
    for (int i = 1; i < numAlign; i++) {
      result.insert(1, pos);
      pos -= step;
    }
    return result;
  }

  static void _placeDataBits(
    List<List<bool>> modules,
    List<List<bool>> isFunction,
    List<int> codewords,
    int size,
  ) {
    final totalBits = codewords.length * 8;
    int bitIndex = 0;
    int upward = -1;

    for (int right = size - 1; right >= 1; right -= 2) {
      if (right == 6) right = 5;
      for (int vert = 0; vert < size; vert++) {
        final row = upward == -1 ? size - 1 - vert : vert;
        for (int j = 0; j < 2; j++) {
          final col = right - j;
          if (!isFunction[row][col]) {
            bool bit = false;
            if (bitIndex < totalBits) {
              final byteVal = codewords[bitIndex >> 3];
              bit = ((byteVal >> (7 - (bitIndex & 7))) & 1) != 0;
              bitIndex++;
            }
            modules[row][col] = bit;
          }
        }
      }
      upward = -upward;
    }
  }

  static void _applyMask(
    List<List<bool>> modules,
    List<List<bool>> isFunction,
    int mask,
    int size,
  ) {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (isFunction[r][c]) continue;
        bool invert;
        switch (mask) {
          case 0:
            invert = (r + c) % 2 == 0;
            break;
          case 1:
            invert = r % 2 == 0;
            break;
          case 2:
            invert = c % 3 == 0;
            break;
          case 3:
            invert = (r + c) % 3 == 0;
            break;
          case 4:
            invert = ((r ~/ 2) + (c ~/ 3)) % 2 == 0;
            break;
          case 5:
            invert = ((r * c) % 2) + ((r * c) % 3) == 0;
            break;
          case 6:
            invert = (((r * c) % 2) + ((r * c) % 3)) % 2 == 0;
            break;
          default:
            invert = (((r + c) % 2) + ((r * c) % 3)) % 2 == 0;
            break;
        }
        if (invert) {
          modules[r][c] = !modules[r][c];
        }
      }
    }
  }

  static void _drawFormatBits(
    List<List<bool>> modules,
    TransferQrErrorCorrectionLevel ec,
    int mask,
    int size,
  ) {
    final data = (ec.formatIndicatorBits << 3) | mask;
    int rem = data;
    for (int i = 0; i < 10; i++) {
      rem = (rem << 1) ^ (((rem >> 9) & 1) * 0x537);
    }
    final bits = ((data << 10) | rem) ^ 0x5412;

    for (int i = 0; i <= 5; i++) {
      modules[8][i] = ((bits >> i) & 1) != 0;
    }
    modules[8][7] = ((bits >> 6) & 1) != 0;
    modules[8][8] = ((bits >> 7) & 1) != 0;
    modules[7][8] = ((bits >> 8) & 1) != 0;
    for (int i = 9; i < 15; i++) {
      modules[14 - i][8] = ((bits >> i) & 1) != 0;
    }

    for (int i = 0; i < 8; i++) {
      modules[size - 1 - i][8] = ((bits >> i) & 1) != 0;
    }
    for (int i = 8; i < 15; i++) {
      modules[8][size - 15 + i] = ((bits >> i) & 1) != 0;
    }
  }

  static void _drawVersionBits(
    List<List<bool>> modules,
    int version,
    int size,
  ) {
    int rem = version;
    for (int i = 0; i < 12; i++) {
      rem = (rem << 1) ^ (((rem >> 11) & 1) * 0x1F25);
    }
    final bits = (version << 12) | rem;
    for (int i = 0; i < 18; i++) {
      final bit = ((bits >> i) & 1) != 0;
      final a = size - 11 + (i % 3);
      final b = i ~/ 3;
      modules[b][a] = bit;
      modules[a][b] = bit;
    }
  }

  static int _evaluatePenalty(List<List<bool>> modules, int size) {
    int penalty = 0;
    for (int r = 0; r < size; r++) {
      int runLen = 1;
      bool prev = modules[r][0];
      for (int c = 1; c < size; c++) {
        if (modules[r][c] == prev) {
          runLen++;
        } else {
          if (runLen >= 5) penalty += 3 + (runLen - 5);
          prev = modules[r][c];
          runLen = 1;
        }
      }
      if (runLen >= 5) penalty += 3 + (runLen - 5);
    }
    for (int c = 0; c < size; c++) {
      int runLen = 1;
      bool prev = modules[0][c];
      for (int r = 1; r < size; r++) {
        if (modules[r][c] == prev) {
          runLen++;
        } else {
          if (runLen >= 5) penalty += 3 + (runLen - 5);
          prev = modules[r][c];
          runLen = 1;
        }
      }
      if (runLen >= 5) penalty += 3 + (runLen - 5);
    }
    return penalty;
  }
}

/// Główny serwis kodowania, kompresji ZLib + Base64URL, generowania kodów QR i skanowania tokenów.
class CareerSaveCloudQrCodeTransfer {
  static const int currentProtocolVersion = 1;
  static const String protocolPrefix = 'PPM1:';

  static final List<int> _crc32Table = _buildCrc32Table();

  const CareerSaveCloudQrCodeTransfer();

  static List<int> _buildCrc32Table() {
    final table = List<int>.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      int c = i;
      for (int k = 0; k < 8; k++) {
        c = (c & 1) != 0 ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
      }
      table[i] = c;
    }
    return table;
  }

  /// Wylicza sumę kontrolną CRC32 (IEEE 802.3) jako 8-znakowy hex.
  String computeCrc32Hex(List<int> bytes) {
    int crc = 0xFFFFFFFF;
    for (final b in bytes) {
      crc = _crc32Table[(crc ^ b) & 0xFF] ^ (crc >>> 8);
    }
    return ((crc ^ 0xFFFFFFFF) & 0xFFFFFFFF)
        .toRadixString(16)
        .toUpperCase()
        .padLeft(8, '0');
  }

  /// Wykrywa bieżącą platformę uruchomienia.
  TransferPlatformOrigin detectCurrentPlatformOrigin() {
    if (Platform.isWindows) return TransferPlatformOrigin.windowsDesktop;
    if (Platform.isMacOS) return TransferPlatformOrigin.macOsDesktop;
    if (Platform.isLinux) return TransferPlatformOrigin.linuxDesktop;
    if (Platform.isAndroid) return TransferPlatformOrigin.androidMobile;
    if (Platform.isIOS) return TransferPlatformOrigin.iOsMobile;
    return TransferPlatformOrigin.webBrowser;
  }

  /// Eksportuje profil kolarza z trybu Be a Pro do tokena Base64URL i matrycy QR.
  CareerTransferExportBundle exportBeAProProfile({
    required ProCyclistCareerState careerState,
    TransferPlatformOrigin? origin,
    TransferQrErrorCorrectionLevel errorCorrectionLevel =
        TransferQrErrorCorrectionLevel.medium,
    bool includeFullCareerState = false,
  }) {
    final sw = Stopwatch()..start();
    final effectiveOrigin = origin ?? detectCurrentPlatformOrigin();
    final snapshot = BeAProTransferSnapshot.fromProCyclistState(
      careerState,
      includeFullCareerState: includeFullCareerState,
    );
    final envelope = _encodeEnvelope(
      kind: TransferPayloadKind.beAProProfile,
      origin: effectiveOrigin,
      payloadJson: snapshot.toJson(),
      beAProSnapshot: snapshot,
    );
    final qr = QrCodeMatrixGenerator.generate(
      envelope.tokenString,
      errorCorrectionLevel: errorCorrectionLevel,
    );
    sw.stop();
    return CareerTransferExportBundle(
      envelope: envelope,
      qrMatrix: qr,
      generationTime: sw.elapsed,
    );
  }

  /// Eksportuje wyścigowy skład drużyny do tokena Base64URL i matrycy QR.
  CareerTransferExportBundle exportTeamRaceRoster({
    required CyclingTeam team,
    required List<Rider> raceRoster,
    String? leaderRiderId,
    String? sprinterRiderId,
    String raceTitle = 'Wyścigowy Skład Startowy',
    int seasonYear = 2026,
    TransferPlatformOrigin? origin,
    TransferQrErrorCorrectionLevel errorCorrectionLevel =
        TransferQrErrorCorrectionLevel.medium,
  }) {
    final sw = Stopwatch()..start();
    final effectiveOrigin = origin ?? detectCurrentPlatformOrigin();
    final snapshot = TeamRaceRosterTransferSnapshot.fromTeamAndRoster(
      team: team,
      raceRoster: raceRoster,
      leaderRiderId: leaderRiderId,
      sprinterRiderId: sprinterRiderId,
      raceTitle: raceTitle,
      seasonYear: seasonYear,
    );
    final envelope = _encodeEnvelope(
      kind: TransferPayloadKind.teamRaceRoster,
      origin: effectiveOrigin,
      payloadJson: snapshot.toJson(),
      teamRosterSnapshot: snapshot,
    );
    final qr = QrCodeMatrixGenerator.generate(
      envelope.tokenString,
      errorCorrectionLevel: errorCorrectionLevel,
    );
    sw.stop();
    return CareerTransferExportBundle(
      envelope: envelope,
      qrMatrix: qr,
      generationTime: sw.elapsed,
    );
  }

  CompactTransferTokenEnvelope _encodeEnvelope({
    required TransferPayloadKind kind,
    required TransferPlatformOrigin origin,
    required Map<String, dynamic> payloadJson,
    BeAProTransferSnapshot? beAProSnapshot,
    TeamRaceRosterTransferSnapshot? teamRosterSnapshot,
  }) {
    final now = DateTime.now().toUtc();
    final wrapper = <String, dynamic>{
      'v': currentProtocolVersion,
      'k': kind.toJson(),
      'o': origin.toJson(),
      'ts': now.toIso8601String(),
      'p': payloadJson,
    };
    final rawJson = utf8.encode(jsonEncode(wrapper));
    final compressed = ZLibCodec(level: 9).encode(rawJson);
    final b64 = base64UrlEncode(compressed).replaceAll('=', '');
    final checksum = computeCrc32Hex(compressed);

    return CompactTransferTokenEnvelope(
      protocolVersion: currentProtocolVersion,
      kind: kind,
      origin: origin,
      createdAtUtc: now,
      checksumHex: checksum,
      compressedBase64: b64,
      rawJsonBytes: rawJson.length,
      compressedBytes: compressed.length,
      beAProSnapshot: beAProSnapshot,
      teamRosterSnapshot: teamRosterSnapshot,
    );
  }

  /// Dekoduje i weryfikuje skanowany token tekstowy Base64URL (`PPM1:BAP.<b64>.<crc32>`).
  TransferScanResult decodeToken(String rawInput) {
    final now = DateTime.now().toUtc();
    final cleaned = rawInput.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) {
      return TransferScanResult(
        status: TransferScanValidationStatus.emptyInput,
        diagnosticMessage: 'Wklej token lub zeskanuj kod QR, aby zaimportować dane.',
        parsedAtUtc: now,
      );
    }

    if (!cleaned.startsWith('PPM')) {
      return TransferScanResult(
        status: TransferScanValidationStatus.invalidPrefix,
        diagnosticMessage:
            'Brak wymaganego prefiksu protokołu PPM1:. Sprawdź czy skopiowano cały kod.',
        parsedAtUtc: now,
      );
    }

    final colonIdx = cleaned.indexOf(':');
    if (colonIdx <= 3) {
      return TransferScanResult(
        status: TransferScanValidationStatus.invalidPrefix,
        diagnosticMessage: 'Nieprawidłowy format nagłówka tokena.',
        parsedAtUtc: now,
      );
    }

    final versionStr = cleaned.substring(3, colonIdx);
    final version = int.tryParse(versionStr);
    if (version == null || version != currentProtocolVersion) {
      return TransferScanResult(
        status: TransferScanValidationStatus.unsupportedVersion,
        diagnosticMessage:
            'Nieobsługiwana wersja protokołu ($versionStr). Wymagana wersja $currentProtocolVersion.',
        parsedAtUtc: now,
      );
    }

    final body = cleaned.substring(colonIdx + 1);
    final parts = body.split('.');
    if (parts.length != 3) {
      return TransferScanResult(
        status: TransferScanValidationStatus.invalidPrefix,
        diagnosticMessage:
            'Token musi składać się z 3 segmentów: TYP.ŁADUNEK.CRC32.',
        parsedAtUtc: now,
      );
    }

    final kindFromCode = TransferPayloadKind.fromShortCode(parts[0]);
    if (kindFromCode == null) {
      return TransferScanResult(
        status: TransferScanValidationStatus.invalidPrefix,
        diagnosticMessage: 'Nieznany typ ładunku: ${parts[0]}.',
        parsedAtUtc: now,
      );
    }

    final b64Part = parts[1];
    final expectedChecksum = parts[2].toUpperCase();

    final List<int> compressedBytes;
    try {
      final padded = _padBase64(b64Part);
      compressedBytes = base64Url.decode(padded);
    } catch (_) {
      return TransferScanResult(
        status: TransferScanValidationStatus.corruptedBase64,
        diagnosticMessage:
            'Nie udało się zdekodować danych Base64URL — uszkodzone znaki.',
        parsedAtUtc: now,
      );
    }

    final actualChecksum = computeCrc32Hex(compressedBytes);
    if (actualChecksum != expectedChecksum) {
      return TransferScanResult(
        status: TransferScanValidationStatus.checksumMismatch,
        diagnosticMessage:
            'Niezgodność CRC32 (oczekiwano $expectedChecksum, obliczono $actualChecksum).',
        parsedAtUtc: now,
      );
    }

    final List<int> rawJsonBytes;
    try {
      rawJsonBytes = ZLibCodec().decode(compressedBytes);
    } catch (_) {
      return TransferScanResult(
        status: TransferScanValidationStatus.decompressionFailed,
        diagnosticMessage: 'Dekompresja strumienia ZLib nie powiodła się.',
        parsedAtUtc: now,
      );
    }

    try {
      final decoded = jsonDecode(utf8.decode(rawJsonBytes));
      if (decoded is! Map<String, dynamic>) {
        return TransferScanResult(
          status: TransferScanValidationStatus.malformedJson,
          diagnosticMessage: 'Główny obiekt JSON ma nieprawidłowy typ.',
          parsedAtUtc: now,
        );
      }

      final origin = TransferPlatformOrigin.fromJson(
        decoded['o'] as String? ?? 'windowsDesktop',
      );
      final tsStr = decoded['ts'] as String?;
      final createdAt = tsStr != null
          ? DateTime.tryParse(tsStr)?.toUtc() ?? now
          : now;
      final payloadMap = decoded['p'];
      if (payloadMap is! Map<String, dynamic>) {
        return TransferScanResult(
          status: TransferScanValidationStatus.malformedJson,
          diagnosticMessage: 'Brak sekcji ładunku "p" w tokenie.',
          parsedAtUtc: now,
        );
      }

      BeAProTransferSnapshot? bap;
      TeamRaceRosterTransferSnapshot? trs;
      if (kindFromCode == TransferPayloadKind.beAProProfile) {
        bap = BeAProTransferSnapshot.fromJson(payloadMap);
      } else {
        trs = TeamRaceRosterTransferSnapshot.fromJson(payloadMap);
      }

      final envelope = CompactTransferTokenEnvelope(
        protocolVersion: version,
        kind: kindFromCode,
        origin: origin,
        createdAtUtc: createdAt,
        checksumHex: actualChecksum,
        compressedBase64: b64Part,
        rawJsonBytes: rawJsonBytes.length,
        compressedBytes: compressedBytes.length,
        beAProSnapshot: bap,
        teamRosterSnapshot: trs,
      );

      return TransferScanResult(
        status: TransferScanValidationStatus.valid,
        envelope: envelope,
        diagnosticMessage:
            'Pomyślnie odczytano ${kindFromCode.label} (${compressedBytes.length} B, CRC32 $actualChecksum).',
        parsedAtUtc: now,
      );
    } catch (e) {
      return TransferScanResult(
        status: TransferScanValidationStatus.malformedJson,
        diagnosticMessage: 'Błąd parsowania JSON: $e',
        parsedAtUtc: now,
      );
    }
  }

  /// Weryfikuje integralność geometryczną wygenerowanej matrycy QR (wzory lokalizacyjne 7x7 i taktowanie).
  bool verifyQrMatrixStructure(QrCodeMatrix matrix) {
    final s = matrix.size;
    if (s < 21 || matrix.modules.length != s) return false;
    for (final row in matrix.modules) {
      if (row.length != s) return false;
    }
    bool checkFinder(int top, int left) {
      for (int r = 0; r < 7; r++) {
        for (int c = 0; c < 7; c++) {
          final expected = r == 0 ||
              r == 6 ||
              c == 0 ||
              c == 6 ||
              (r >= 2 && r <= 4 && c >= 2 && c <= 4);
          if (matrix.modules[top + r][left + c] != expected) return false;
        }
      }
      return true;
    }

    if (!checkFinder(0, 0) ||
        !checkFinder(0, s - 7) ||
        !checkFinder(s - 7, 0)) {
      return false;
    }
    for (int i = 8; i < s - 8; i++) {
      if (matrix.modules[6][i] != (i % 2 == 0)) return false;
      if (matrix.modules[i][6] != (i % 2 == 0)) return false;
    }
    return true;
  }

  static String _padBase64(String input) {
    final mod = input.length % 4;
    if (mod == 0) return input;
    return input + ('=' * (4 - mod));
  }
}

/// Stan Riverpod dla modułu szybkiego transferu QR / Base64.
class CareerSaveCloudQrTransferState {
  final TransferPayloadKind activeMode;
  final TransferQrErrorCorrectionLevel errorCorrectionLevel;
  final CareerTransferExportBundle? currentExportBundle;
  final TransferScanResult? lastScanResult;
  final String scannerInputText;
  final bool isBusy;
  final String? statusBanner;
  final List<TransferHistoryEntry> history;

  const CareerSaveCloudQrTransferState({
    this.activeMode = TransferPayloadKind.beAProProfile,
    this.errorCorrectionLevel = TransferQrErrorCorrectionLevel.medium,
    this.currentExportBundle,
    this.lastScanResult,
    this.scannerInputText = '',
    this.isBusy = false,
    this.statusBanner,
    this.history = const [],
  });

  CareerSaveCloudQrTransferState copyWith({
    TransferPayloadKind? activeMode,
    TransferQrErrorCorrectionLevel? errorCorrectionLevel,
    CareerTransferExportBundle? currentExportBundle,
    bool clearExportBundle = false,
    TransferScanResult? lastScanResult,
    bool clearScanResult = false,
    String? scannerInputText,
    bool? isBusy,
    String? statusBanner,
    bool clearStatusBanner = false,
    List<TransferHistoryEntry>? history,
  }) {
    return CareerSaveCloudQrTransferState(
      activeMode: activeMode ?? this.activeMode,
      errorCorrectionLevel: errorCorrectionLevel ?? this.errorCorrectionLevel,
      currentExportBundle: clearExportBundle
          ? null
          : (currentExportBundle ?? this.currentExportBundle),
      lastScanResult:
          clearScanResult ? null : (lastScanResult ?? this.lastScanResult),
      scannerInputText: scannerInputText ?? this.scannerInputText,
      isBusy: isBusy ?? this.isBusy,
      statusBanner:
          clearStatusBanner ? null : (statusBanner ?? this.statusBanner),
      history: history ?? this.history,
    );
  }
}

/// Notifier zarządzający generowaniem kodów QR, tokenów i ich skanowaniem.
class CareerSaveCloudQrTransferNotifier
    extends StateNotifier<CareerSaveCloudQrTransferState> {
  final CareerSaveCloudQrCodeTransfer _service;

  CareerSaveCloudQrTransferNotifier([
    CareerSaveCloudQrCodeTransfer? service,
  ])  : _service = service ?? const CareerSaveCloudQrCodeTransfer(),
        super(const CareerSaveCloudQrTransferState());

  void selectMode(TransferPayloadKind mode) {
    state = state.copyWith(activeMode: mode, clearStatusBanner: true);
  }

  void setErrorCorrectionLevel(TransferQrErrorCorrectionLevel level) {
    state = state.copyWith(errorCorrectionLevel: level);
    final current = state.currentExportBundle;
    if (current != null) {
      final regeneratedQr = QrCodeMatrixGenerator.generate(
        current.token,
        errorCorrectionLevel: level,
      );
      state = state.copyWith(
        currentExportBundle: CareerTransferExportBundle(
          envelope: current.envelope,
          qrMatrix: regeneratedQr,
          generationTime: current.generationTime,
        ),
      );
    }
  }

  void updateScannerInput(String value) {
    state = state.copyWith(scannerInputText: value);
  }

  void clearScanResult() {
    state = state.copyWith(
      clearScanResult: true,
      scannerInputText: '',
      clearStatusBanner: true,
    );
  }

  /// Generuje kod QR i token dla przekazanego profilu Be a Pro.
  void exportBeAPro(
    ProCyclistCareerState careerState, {
    bool includeFullCareerState = false,
  }) {
    state = state.copyWith(isBusy: true);
    final bundle = _service.exportBeAProProfile(
      careerState: careerState,
      errorCorrectionLevel: state.errorCorrectionLevel,
      includeFullCareerState: includeFullCareerState,
    );
    final entry = TransferHistoryEntry(
      id: 'exp_${DateTime.now().microsecondsSinceEpoch}',
      kind: TransferPayloadKind.beAProProfile,
      direction: TransferHistoryDirection.exported,
      title: careerState.playerRider.fullName,
      subtitle:
          '${careerState.careerTier.label} • ${careerState.currentTeamName}',
      tokenFull: bundle.token,
      checksumHex: bundle.envelope.checksumHex,
      byteSize: bundle.envelope.compressedBytes,
      timestampUtc: bundle.envelope.createdAtUtc,
    );
    state = state.copyWith(
      activeMode: TransferPayloadKind.beAProProfile,
      currentExportBundle: bundle,
      isBusy: false,
      statusBanner:
          'Wygenerowano kod QR Be a Pro (${bundle.envelope.compressedBytes} B, ${bundle.generationTime.inMilliseconds} ms).',
      history: [entry, ...state.history].take(12).toList(),
    );
  }

  /// Generuje kod QR i token dla wyścigowego składu drużyny.
  void exportTeamRoster({
    required CyclingTeam team,
    required List<Rider> raceRoster,
    String? leaderRiderId,
    String? sprinterRiderId,
    String raceTitle = 'Wyścigowy Skład Startowy',
    int seasonYear = 2026,
  }) {
    state = state.copyWith(isBusy: true);
    final bundle = _service.exportTeamRaceRoster(
      team: team,
      raceRoster: raceRoster,
      leaderRiderId: leaderRiderId,
      sprinterRiderId: sprinterRiderId,
      raceTitle: raceTitle,
      seasonYear: seasonYear,
      errorCorrectionLevel: state.errorCorrectionLevel,
    );
    final entry = TransferHistoryEntry(
      id: 'exp_${DateTime.now().microsecondsSinceEpoch}',
      kind: TransferPayloadKind.teamRaceRoster,
      direction: TransferHistoryDirection.exported,
      title: team.name,
      subtitle: '$raceTitle (${raceRoster.length} kolarzy)',
      tokenFull: bundle.token,
      checksumHex: bundle.envelope.checksumHex,
      byteSize: bundle.envelope.compressedBytes,
      timestampUtc: bundle.envelope.createdAtUtc,
    );
    state = state.copyWith(
      activeMode: TransferPayloadKind.teamRaceRoster,
      currentExportBundle: bundle,
      isBusy: false,
      statusBanner:
          'Wygenerowano kod QR składu (${bundle.envelope.compressedBytes} B, ${bundle.generationTime.inMilliseconds} ms).',
      history: [entry, ...state.history].take(12).toList(),
    );
  }

  /// Skanuje / dekoduje token ze schowka lub pola tekstowego.
  TransferScanResult scanAndImportToken(String rawToken) {
    state = state.copyWith(isBusy: true, scannerInputText: rawToken);
    final result = _service.decodeToken(rawToken);
    final updatedHistory = List<TransferHistoryEntry>.from(state.history);
    if (result.isValid && result.envelope != null) {
      final env = result.envelope!;
      final title = env.beAProSnapshot != null
          ? env.beAProSnapshot!.playerRider.fullName
          : (env.teamRosterSnapshot?.teamName ?? 'Skład Drużyny');
      final subtitle = env.beAProSnapshot != null
          ? '${env.beAProSnapshot!.careerTier.label} • ${env.beAProSnapshot!.currentTeamName}'
          : '${env.teamRosterSnapshot?.raceTitle ?? "Wyścig"} (${env.teamRosterSnapshot?.raceRoster.length ?? 0} kolarzy)';
      updatedHistory.insert(
        0,
        TransferHistoryEntry(
          id: 'imp_${DateTime.now().microsecondsSinceEpoch}',
          kind: env.kind,
          direction: TransferHistoryDirection.imported,
          title: title,
          subtitle: subtitle,
          tokenFull: env.tokenString,
          checksumHex: env.checksumHex,
          byteSize: env.compressedBytes,
          timestampUtc: result.parsedAtUtc,
        ),
      );
    }
    state = state.copyWith(
      lastScanResult: result,
      isBusy: false,
      statusBanner: result.diagnosticMessage,
      history: updatedHistory.take(12).toList(),
    );
    return result;
  }

  /// Generuje gotowy profil lub skład demonstracyjny dla natychmiastowego podglądu.
  void generateDemoExportForActiveMode() {
    if (state.activeMode == TransferPayloadKind.beAProProfile) {
      exportBeAPro(_buildSampleProCyclistState());
    } else {
      final (team, roster) = _buildSampleTeamAndRoster();
      exportTeamRoster(
        team: team,
        raceRoster: roster,
        leaderRiderId: roster.first.id,
        sprinterRiderId: roster.last.id,
        raceTitle: 'Tour de France — Ósemka Startowa',
        seasonYear: 2026,
      );
    }
  }

  void loadHistoryEntryToScanner(TransferHistoryEntry entry) {
    scanAndImportToken(entry.tokenFull);
  }

  static Rider _buildSampleRider({
    required String id,
    required String firstName,
    required String lastName,
    required String country,
    required RiderSpecialization spec,
    required int ftp,
    required double weight,
  }) {
    return Rider(
      id: id,
      firstName: firstName,
      lastName: lastName,
      nationalityIso: country,
      birthDate: DateTime(1999, 5, 14),
      potential: 91,
      specialization: spec,
      physiology: RiderPhysiology(
        heightCm: 178.0,
        weightKg: weight,
        bodyFatPercentage: 6.4,
        ftpWatts: ftp,
        wPrimeJoules: 24500,
        vo2Max: 84.5,
        maxHr: 194,
        restingHr: 38,
        lactateThresholdHr: 176,
        recoveryRate: 0.88,
        glycogenCapacityGrams: 540.0,
      ),
      powerProfile: RiderPowerProfile(
        watts5s: spec == RiderSpecialization.pureSprinter ? 1580 : 1220,
        watts15s: spec == RiderSpecialization.pureSprinter ? 1320 : 980,
        watts30s: 920,
        watts1m: 690,
        watts3m: (ftp * 1.24).round(),
        watts5m: (ftp * 1.18).round(),
        watts20m: (ftp * 1.05).round(),
        watts60m: (ftp * 0.96).round(),
      ),
      skills: const RiderSkills(
        cobbles: 72,
        descending: 80,
        bikeHandling: 81,
        aeroPositioning: 80,
        draftingEfficiency: 84,
        raceIq: 84,
        rainResistance: 78,
        heatTolerance: 79,
        timeTrialPositioning: 82,
      ),
      appearance: const RiderAppearance(
        faceShapeIndex: 2,
        skinToneHex: '#E0B899',
        hairStyleIndex: 4,
        hairColorHex: '#3B2F2F',
        facialHairIndex: 1,
        glassesModelId: 'aero_pro_gold',
        glassesLensColorHex: '#D4AF37',
        helmetModelId: 'obsidian_aero_v4',
        shoeColorHex: '#F3F4F6',
        sockHeightProportion: 0.72,
        bodyBuildType: BodyBuildType.climberLean,
      ),
      contract: const RiderContract(
        teamId: 'team_demo_wt',
        role: RiderRole.teamLeader,
        monthlySalaryEur: 70000,
        signingBonusEur: 120000,
        winBonusEur: 25000,
        releaseClauseEur: 2500000,
        contractEndYear: 2028,
        morale: 0.9,
        leaderLoyalty: 0.88,
        requiredRacesIds: ['tour_de_france'],
      ),
      health: const RiderHealth(
        acuteTrainingLoad: 74.0,
        chronicTrainingLoad: 92.0,
      ),
      careerPointsUci: 1840,
    );
  }

  static ProCyclistCareerState _buildSampleProCyclistState() {
    final rider = _buildSampleRider(
      id: 'bap_kacper_1',
      firstName: 'Kacper',
      lastName: 'Majewski',
      country: 'POL',
      spec: RiderSpecialization.gcClimber,
      ftp: 428,
      weight: 64.5,
    );
    return ProCyclistCareerState(
      careerId: 'bap_2026_pol',
      careerName: 'Droga po Żółtą Koszulkę',
      playerRider: rider,
      currentDate: DateTime(2026, 7, 4),
      careerStartDate: DateTime(2024, 1, 1),
      seasonYear: 2026,
      currentTeamId: 'team_obsidian_wt',
      currentTeamName: 'Obsidian Sovereign Pro',
      currentDivision: TeamDivision.worldTour,
      careerTier: ProCyclistCareerTier.worldTourLeader,
      dsTrustScore: 89.5,
      skillPoints: 14,
      experienceXp: 4820,
      careerLevel: 18,
      totalSkillPointsEarned: 42,
      totalSkillPointsSpent: 28,
      privateBalanceEur: 1240000,
      careerEarningsEur: 2650000,
      monthlyLivingExpensesEur: 6500,
      fameScore: 84.0,
      fanFollowersCount: 312000,
      ownedProperties: const [],
      ownedPrivateEquipment: const [],
      activePersonalSponsors: const [],
      achievementJournal: const [],
      palmares: const ProCyclistPalmares(
        careerWins: 19,
        grandTourStageWins: 4,
        monumentWins: 1,
      ),
    );
  }

  static (CyclingTeam, List<Rider>) _buildSampleTeamAndRoster() {
    final riders = [
      _buildSampleRider(
        id: 'r_1',
        firstName: 'Michał',
        lastName: 'Kowalski',
        country: 'POL',
        spec: RiderSpecialization.gcClimber,
        ftp: 424,
        weight: 65.0,
      ),
      _buildSampleRider(
        id: 'r_2',
        firstName: 'Lucas',
        lastName: 'Vandenberg',
        country: 'BEL',
        spec: RiderSpecialization.classicCobbles,
        ftp: 445,
        weight: 74.0,
      ),
      _buildSampleRider(
        id: 'r_3',
        firstName: 'Matteo',
        lastName: 'Bellini',
        country: 'ITA',
        spec: RiderSpecialization.pureClimber,
        ftp: 398,
        weight: 60.5,
      ),
      _buildSampleRider(
        id: 'r_4',
        firstName: 'Jakub',
        lastName: 'Nowak',
        country: 'POL',
        spec: RiderSpecialization.pureSprinter,
        ftp: 418,
        weight: 75.5,
      ),
    ];

    final team = CyclingTeam(
      id: 'team_obsidian_wt',
      name: 'Obsidian Sovereign Cycling',
      division: TeamDivision.worldTour,
      countryIso: 'POL',
      primaryJerseyColorHex: '#8E4A49',
      secondaryJerseyColorHex: '#181B22',
      accentJerseyColorHex: '#D4AF37',
      cashBalanceEur: 14500000,
      monthlyBurnRateEur: 920000,
      uciPointsSeason: 9420,
      rosterRiderIds: riders.map((r) => r.id).toList(),
      staff: const TeamStaff(
        trainersLevel: 90,
        sportsDirectorsLevel: 88,
        doctorsLevel: 86,
        mechanicsLevel: 91,
        scoutsLevel: 84,
      ),
      bikeDeal: const BikeManufacturerDeal(
        manufacturerId: 'factor_aerolab',
        manufacturerName: 'Factor AeroLab',
        prestigeLevel: 5,
        annualCashContributionEur: 1800000,
        freeBikesQuota: 40,
        researchAndDevelopmentLevel: 92,
        suppliedFrameIds: ['ostro_vam_2'],
        suppliedWheelsetIds: ['black_inc_48_58'],
        contractYearsLeft: 3,
        minimumUciRankingRequired: 10,
      ),
      sponsors: const [],
      inventoryBikes: const [],
    );
    return (team, riders);
  }
}

/// Globalny provider stanu transferu QR / Base64.
final careerSaveCloudQrTransferProvider = StateNotifierProvider<
    CareerSaveCloudQrTransferNotifier, CareerSaveCloudQrTransferState>(
  (ref) => CareerSaveCloudQrTransferNotifier(),
);

/// Rysuje precyzyjną matrycę kodu QR z zachowaniem strefy ciszy i akcentu marki PPM.
class QrCodeMatrixPainter extends CustomPainter {
  final QrCodeMatrix matrix;
  final Color moduleColor;
  final Color backgroundColor;
  final Color finderAccentColor;

  const QrCodeMatrixPainter({
    required this.matrix,
    this.moduleColor = const Color(0xFF0F1115),
    this.backgroundColor = const Color(0xFFF3F4F6),
    this.finderAccentColor = AppColors.primaryAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(12),
      ),
      bgPaint,
    );

    const quietZoneModules = 2;
    final totalModules = matrix.size + quietZoneModules * 2;
    final moduleSize = math.min(size.width, size.height) / totalModules;
    final offsetX = (size.width - moduleSize * totalModules) / 2.0;
    final offsetY = (size.height - moduleSize * totalModules) / 2.0;

    final darkPaint = Paint()..color = moduleColor;
    final accentPaint = Paint()..color = finderAccentColor;

    for (int r = 0; r < matrix.size; r++) {
      for (int c = 0; c < matrix.size; c++) {
        if (!matrix.modules[r][c]) continue;
        final isFinderCenter =
            (r >= 2 && r <= 4 && c >= 2 && c <= 4) ||
            (r >= 2 && r <= 4 && c >= matrix.size - 5 && c <= matrix.size - 3) ||
            (r >= matrix.size - 5 && r <= matrix.size - 3 && c >= 2 && c <= 4);

        final rect = Rect.fromLTWH(
          offsetX + (c + quietZoneModules) * moduleSize,
          offsetY + (r + quietZoneModules) * moduleSize,
          moduleSize + 0.15,
          moduleSize + 0.15,
        );
        canvas.drawRect(rect, isFinderCenter ? accentPaint : darkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant QrCodeMatrixPainter oldDelegate) {
    return oldDelegate.matrix != matrix ||
        oldDelegate.moduleColor != moduleColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.finderAccentColor != finderAccentColor;
  }
}

/// Produkcyjny panel UI transferu QR i kompaktowych tokenów Base64 (390x844 / 1024x768 / 1600x900).
class CareerSaveCloudQrCodeTransferPanel extends ConsumerStatefulWidget {
  final ProCyclistCareerState? initialBeAProState;
  final CyclingTeam? initialTeam;
  final List<Rider>? initialRaceRoster;

  const CareerSaveCloudQrCodeTransferPanel({
    super.key,
    this.initialBeAProState,
    this.initialTeam,
    this.initialRaceRoster,
  });

  @override
  ConsumerState<CareerSaveCloudQrCodeTransferPanel> createState() =>
      _CareerSaveCloudQrCodeTransferPanelState();
}

class _CareerSaveCloudQrCodeTransferPanelState
    extends ConsumerState<CareerSaveCloudQrCodeTransferPanel> {
  late final TextEditingController _scannerController;
  final FocusNode _scannerFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scannerController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(careerSaveCloudQrTransferProvider.notifier);
      if (widget.initialBeAProState != null) {
        notifier.exportBeAPro(widget.initialBeAProState!);
      } else if (widget.initialTeam != null && widget.initialRaceRoster != null) {
        notifier.exportTeamRoster(
          team: widget.initialTeam!,
          raceRoster: widget.initialRaceRoster!,
        );
      } else {
        notifier.generateDemoExportForActiveMode();
      }
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _scannerFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(careerSaveCloudQrTransferProvider);
    final notifier = ref.read(careerSaveCloudQrTransferProvider.notifier);

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1120;
          final isCompact = constraints.maxWidth < 600;
          final padding = isCompact ? 14.0 : 22.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(state, notifier, isCompact),
                if (state.statusBanner != null) ...[
                  const SizedBox(height: 14),
                  _buildStatusBanner(state.statusBanner!, state.lastScanResult),
                ],
                const SizedBox(height: 18),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildGeneratorCard(state, notifier, isCompact),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            _buildScannerCard(state, notifier, isCompact),
                            const SizedBox(height: 18),
                            _buildHistoryCard(state, notifier),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildGeneratorCard(state, notifier, isCompact),
                  const SizedBox(height: 16),
                  _buildScannerCard(state, notifier, isCompact),
                  const SizedBox(height: 16),
                  _buildHistoryCard(state, notifier),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    CareerSaveCloudQrTransferState state,
    CareerSaveCloudQrTransferNotifier notifier,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.45),
                  ),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: AppColors.goldAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Szybki Transfer QR & Base64 (PC ↔ Mobile)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isCompact ? 16 : 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Przenieś profil Be a Pro lub wyścigowy skład drużyny w ułamku sekundy z weryfikacją CRC32.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: TransferPayloadKind.values.map((kind) {
              final selected = state.activeMode == kind;
              return _InteractiveModeTab(
                label: kind.label,
                icon: kind == TransferPayloadKind.beAProProfile
                    ? Icons.person_pin_rounded
                    : Icons.groups_rounded,
                selected: selected,
                onTap: () {
                  notifier.selectMode(kind);
                  notifier.generateDemoExportForActiveMode();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String message, TransferScanResult? scanResult) {
    final isError = scanResult != null && !scanResult.isValid;
    final accent = isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: accent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratorCard(
    CareerSaveCloudQrTransferState state,
    CareerSaveCloudQrTransferNotifier notifier,
    bool isCompact,
  ) {
    final bundle = state.currentExportBundle;
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.ios_share_rounded,
                color: AppColors.accentBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Generator Kodu QR & Tokena',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _InteractiveActionButton(
                label: 'Odśwież',
                icon: Icons.refresh_rounded,
                variant: _ButtonVariant.secondary,
                disabled: state.isBusy,
                onPressed: notifier.generateDemoExportForActiveMode,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Korekcja błędów QR (Reed-Solomon)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TransferQrErrorCorrectionLevel.values.map((level) {
              return _EcLevelChip(
                code: level.code,
                selected: state.errorCorrectionLevel == level,
                onTap: () => notifier.setErrorCorrectionLevel(level),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          if (bundle != null) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: SizedBox(
                  width: isCompact ? 210 : 240,
                  height: isCompact ? 210 : 240,
                  child: CustomPaint(
                    painter: QrCodeMatrixPainter(matrix: bundle.qrMatrix),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricsStrip(bundle),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: SelectableText(
                bundle.token,
                maxLines: 3,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: AppColors.accentBlue,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InteractiveActionButton(
                  label: 'Kopiuj token do schowka',
                  icon: Icons.copy_rounded,
                  variant: _ButtonVariant.primary,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: bundle.token));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Skopiowano token transferowy do schowka.'),
                      ),
                    );
                  },
                ),
                _InteractiveActionButton(
                  label: 'Testuj w skanerze',
                  icon: Icons.qr_code_scanner_rounded,
                  variant: _ButtonVariant.gold,
                  onPressed: () {
                    _scannerController.text = bundle.token;
                    notifier.scanAndImportToken(bundle.token);
                  },
                ),
              ],
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Wybierz tryb i wygeneruj kod transferowy.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricsStrip(CareerTransferExportBundle bundle) {
    final env = bundle.envelope;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MetricBadge(
          label: 'Wersja QR',
          value: 'V${bundle.qrMatrix.version} (${bundle.qrMatrix.size}×${bundle.qrMatrix.size})',
          color: AppColors.textPrimary,
        ),
        _MetricBadge(
          label: 'Rozmiar ZLib',
          value: '${env.compressedBytes} B (-${env.spaceSavedPercent.toStringAsFixed(0)}%)',
          color: AppColors.statusSuccess,
        ),
        _MetricBadge(
          label: 'CRC32',
          value: env.checksumHex,
          color: AppColors.goldAccent,
        ),
      ],
    );
  }

  Widget _buildScannerCard(
    CareerSaveCloudQrTransferState state,
    CareerSaveCloudQrTransferNotifier notifier,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.qr_code_scanner_rounded,
                color: AppColors.goldAccent,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Skaner & Importer Tokena',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _scannerController,
            focusNode: _scannerFocusNode,
            maxLines: 3,
            minLines: 2,
            onChanged: notifier.updateScannerInput,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              hintText: 'Wklej token PPM1:BAP... lub PPM1:TRS... zeskanowany telefonem',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InteractiveActionButton(
                label: 'Skanuj i weryfikuj',
                icon: Icons.verified_user_rounded,
                variant: _ButtonVariant.primary,
                disabled: state.isBusy,
                onPressed: () {
                  notifier.scanAndImportToken(_scannerController.text);
                },
              ),
              _InteractiveActionButton(
                label: 'Wklej ze schowka',
                icon: Icons.paste_rounded,
                variant: _ButtonVariant.secondary,
                onPressed: () async {
                  final clip = await Clipboard.getData(Clipboard.kTextPlain);
                  final text = clip?.text ?? '';
                  if (text.isNotEmpty) {
                    _scannerController.text = text;
                    notifier.scanAndImportToken(text);
                  }
                },
              ),
              _InteractiveActionButton(
                label: 'Wyczyść',
                icon: Icons.clear_rounded,
                variant: _ButtonVariant.secondary,
                disabled: _scannerController.text.isEmpty &&
                    state.lastScanResult == null,
                onPressed: () {
                  _scannerController.clear();
                  notifier.clearScanResult();
                },
              ),
            ],
          ),
          if (state.lastScanResult != null) ...[
            const SizedBox(height: 16),
            _buildDecodedPreview(state.lastScanResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildDecodedPreview(TransferScanResult result) {
    final env = result.envelope;
    if (!result.isValid || env == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.crimsonAlert.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.crimsonAlert.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.crimsonAlert),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${result.status.label}: ${result.diagnosticMessage}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (env.beAProSnapshot != null) {
      final bap = env.beAProSnapshot!;
      final r = bap.playerRider;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.goldAccent, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${r.fullName} (${r.nationalityIso}) • OVR ${r.overallRating}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${bap.careerTier.label} • ${bap.currentTeamName} • Sezon ${bap.seasonYear}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _MetricBadge(
                  label: 'FTP',
                  value: '${r.physiology.ftpWatts.round()} W (${r.physiology.wattsPerKg.toStringAsFixed(2)} W/kg)',
                  color: AppColors.accentBlue,
                ),
                _MetricBadge(
                  label: 'Zwycięstwa',
                  value: '${bap.palmares.careerWins}',
                  color: AppColors.statusSuccess,
                ),
                _MetricBadge(
                  label: 'Źródło',
                  value: env.origin.label,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ],
        ),
      );
    }

    final trs = env.teamRosterSnapshot!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, color: AppColors.accentBlue, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${trs.teamName} (${trs.countryIso}) — ${trs.raceTitle}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${trs.raceRoster.length} kolarzy • Śr. OVR ${trs.averageOverallRating.toStringAsFixed(1)} • Śr. ${trs.averageFtpWkg.toStringAsFixed(2)} W/kg',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 10),
          ...trs.raceRoster.map(
            (rider) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '• ${rider.fullName} (${rider.specialization.displayName})',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    'OVR ${rider.overallRating}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldAccent,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
    CareerSaveCloudQrTransferState state,
    CareerSaveCloudQrTransferNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, color: AppColors.textSecondary, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Historia Ostatnich Transferów',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (state.history.isEmpty)
            const Text(
              'Brak zarejestrowanych transferów w bieżącej sesji.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            )
          else
            ...state.history.map(
              (entry) => _InteractiveHistoryRow(
                entry: entry,
                onTap: () {
                  _scannerController.text = entry.tokenFull;
                  notifier.loadHistoryEntryToScanner(entry);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBadge({
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
        borderRadius: BorderRadius.circular(8),
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
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ButtonVariant { primary, secondary, gold }

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final _ButtonVariant variant;
  final bool disabled;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.variant,
    required this.onPressed,
    this.disabled = false,
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
    final baseBg = switch (widget.variant) {
      _ButtonVariant.primary => AppColors.primaryAccent,
      _ButtonVariant.gold => AppColors.goldAccent.withValues(alpha: 0.2),
      _ButtonVariant.secondary => AppColors.surfaceLight,
    };
    final borderColor = _focused
        ? AppColors.accentBlue
        : switch (widget.variant) {
            _ButtonVariant.primary => AppColors.primaryAccent,
            _ButtonVariant.gold => AppColors.goldAccent,
            _ButtonVariant.secondary => AppColors.cardBorder,
          };
    final fgColor = widget.disabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : switch (widget.variant) {
            _ButtonVariant.primary => AppColors.textPrimary,
            _ButtonVariant.gold => AppColors.goldAccent,
            _ButtonVariant.secondary => AppColors.textPrimary,
          };

    final bgColor = widget.disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _pressed
            ? baseBg.withValues(alpha: 0.72)
            : _hovered
                ? baseBg.withValues(alpha: 0.88)
                : baseBg;

    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: MouseRegion(
        cursor: widget.disabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
          onTapUp: widget.disabled ? null : (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.disabled ? null : widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: _focused ? 1.5 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 16, color: fgColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: fgColor,
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

class _InteractiveModeTab extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _InteractiveModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_InteractiveModeTab> createState() => _InteractiveModeTabState();
}

class _InteractiveModeTabState extends State<_InteractiveModeTab> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.primaryAccent
                  : (_hovered ? AppColors.surfaceLight : AppColors.background),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.accentBlue
                    : (widget.selected
                        ? AppColors.primaryAccent
                        : AppColors.cardBorder),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: widget.selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
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

class _EcLevelChip extends StatefulWidget {
  final String code;
  final bool selected;
  final VoidCallback onTap;

  const _EcLevelChip({
    required this.code,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_EcLevelChip> createState() => _EcLevelChipState();
}

class _EcLevelChipState extends State<_EcLevelChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.goldAccent.withValues(alpha: 0.2)
                : (_hovered ? AppColors.surfaceLight : AppColors.background),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  widget.selected ? AppColors.goldAccent : AppColors.cardBorder,
            ),
          ),
          child: Text(
            'ECC ${widget.code}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: widget.selected
                  ? AppColors.goldAccent
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveHistoryRow extends StatefulWidget {
  final TransferHistoryEntry entry;
  final VoidCallback onTap;

  const _InteractiveHistoryRow({
    required this.entry,
    required this.onTap,
  });

  @override
  State<_InteractiveHistoryRow> createState() => _InteractiveHistoryRowState();
}

class _InteractiveHistoryRowState extends State<_InteractiveHistoryRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isExport = widget.entry.direction == TransferHistoryDirection.exported;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceLight : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Icon(
                isExport ? Icons.upload_rounded : Icons.download_rounded,
                size: 16,
                color: isExport ? AppColors.accentBlue : AppColors.statusSuccess,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.entry.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.entry.subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${widget.entry.byteSize} B',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
