import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/career/career_save.dart';

/// Nagłówek magiczny skompresowanego pakietu zapisu międzyplatformowego.
const String kCrossSavePacketMagic = 'PPM_CROSS_SAVE_GZ_V1';

/// Prefiks przenośnego tokenu tekstowego (QR / schowek) dla transferu PC <-> Mac <-> Mobile.
const String kCrossSaveTokenPrefix = 'PPMCS1:';

/// Rozszerzenie pliku przenośnego zapisu skompresowanego GZIP.
const String kCrossSaveFileExtension = '.ppmsave.gz';

/// Bieżąca wersja schematu koperty synchronizacji chmurowej.
const int kCrossSaveSchemaVersion = 1;

/// Wyjątek integralności lub dekodowania pakietu Cross-Save.
class CrossSaveIntegrityException implements Exception {
  final String code;
  final String message;

  const CrossSaveIntegrityException(this.code, this.message);

  @override
  String toString() => 'CrossSaveIntegrityException($code): $message';
}

/// Platforma urządzenia uczestniczącego w synchronizacji zapisów.
enum CrossSaveDevicePlatform {
  pcWindows,
  macOs,
  mobileIos,
  mobileAndroid,
  linuxDesktop;

  String toJson() => name;

  static CrossSaveDevicePlatform fromJson(String value) {
    return CrossSaveDevicePlatform.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CrossSaveDevicePlatform.pcWindows,
    );
  }

  /// Wykrywa bieżącą platformę uruchomieniową (bezpieczne dla testów i desktop/mobile).
  static CrossSaveDevicePlatform detectCurrent() {
    if (Platform.isWindows) return CrossSaveDevicePlatform.pcWindows;
    if (Platform.isMacOS) return CrossSaveDevicePlatform.macOs;
    if (Platform.isIOS) return CrossSaveDevicePlatform.mobileIos;
    if (Platform.isAndroid) return CrossSaveDevicePlatform.mobileAndroid;
    return CrossSaveDevicePlatform.linuxDesktop;
  }

  String get labelPl {
    switch (this) {
      case CrossSaveDevicePlatform.pcWindows:
        return 'PC (Windows)';
      case CrossSaveDevicePlatform.macOs:
        return 'Mac (macOS)';
      case CrossSaveDevicePlatform.mobileIos:
        return 'Mobile (iOS)';
      case CrossSaveDevicePlatform.mobileAndroid:
        return 'Mobile (Android)';
      case CrossSaveDevicePlatform.linuxDesktop:
        return 'Desktop (Linux)';
    }
  }

  String get shortCode {
    switch (this) {
      case CrossSaveDevicePlatform.pcWindows:
        return 'WIN';
      case CrossSaveDevicePlatform.macOs:
        return 'MAC';
      case CrossSaveDevicePlatform.mobileIos:
        return 'IOS';
      case CrossSaveDevicePlatform.mobileAndroid:
        return 'AND';
      case CrossSaveDevicePlatform.linuxDesktop:
        return 'LNX';
    }
  }

  IconData get icon {
    switch (this) {
      case CrossSaveDevicePlatform.pcWindows:
        return Icons.desktop_windows_rounded;
      case CrossSaveDevicePlatform.macOs:
        return Icons.laptop_mac_rounded;
      case CrossSaveDevicePlatform.mobileIos:
        return Icons.phone_iphone_rounded;
      case CrossSaveDevicePlatform.mobileAndroid:
        return Icons.phone_android_rounded;
      case CrossSaveDevicePlatform.linuxDesktop:
        return Icons.computer_rounded;
    }
  }
}

/// Kierunek operacji synchronizacji chmurowej.
enum CrossSaveSyncDirection {
  uploadToCloud,
  downloadFromCloud,
  bidirectionalMerge;

  String get labelPl {
    switch (this) {
      case CrossSaveSyncDirection.uploadToCloud:
        return 'Wysyłka do Chmury';
      case CrossSaveSyncDirection.downloadFromCloud:
        return 'Pobranie z Chmury';
      case CrossSaveSyncDirection.bidirectionalMerge:
        return 'Synchronizacja Dwukierunkowa';
    }
  }
}

/// Strategia rozwiązywania konfliktu między zapisem lokalnym a chmurowym.
enum CrossSaveConflictResolutionStrategy {
  keepNewestTimestamp,
  preferLocalDevice,
  preferCloudRemote,
  manualReview;

  String get labelPl {
    switch (this) {
      case CrossSaveConflictResolutionStrategy.keepNewestTimestamp:
        return 'Nowszy znacznik czasu';
      case CrossSaveConflictResolutionStrategy.preferLocalDevice:
        return 'Zostaw zapis lokalny';
      case CrossSaveConflictResolutionStrategy.preferCloudRemote:
        return 'Nadpisz zapisem z chmury';
      case CrossSaveConflictResolutionStrategy.manualReview:
        return 'Decyzja ręczna';
    }
  }
}

/// Bieżący stan maszyny stanów adaptera Cross-Save.
enum CrossSaveSyncStatus {
  idle,
  compressing,
  uploading,
  downloading,
  decompressing,
  verifying,
  conflictDetected,
  synced,
  error;

  String get labelPl {
    switch (this) {
      case CrossSaveSyncStatus.idle:
        return 'GOTOWY';
      case CrossSaveSyncStatus.compressing:
        return 'KOMPRESJA GZIP';
      case CrossSaveSyncStatus.uploading:
        return 'WYSYŁANIE';
      case CrossSaveSyncStatus.downloading:
        return 'POBIERANIE';
      case CrossSaveSyncStatus.decompressing:
        return 'DEKOMPRESJA';
      case CrossSaveSyncStatus.verifying:
        return 'WERYFIKACJA SUM';
      case CrossSaveSyncStatus.conflictDetected:
        return 'WYKRYTO KONFLIKT';
      case CrossSaveSyncStatus.synced:
        return 'ZSYNCHRONIZOWANO';
      case CrossSaveSyncStatus.error:
        return 'BŁĄD TRANSFERU';
    }
  }

  Color get badgeColor {
    switch (this) {
      case CrossSaveSyncStatus.idle:
        return AppColors.textSecondary;
      case CrossSaveSyncStatus.compressing:
      case CrossSaveSyncStatus.uploading:
      case CrossSaveSyncStatus.downloading:
      case CrossSaveSyncStatus.decompressing:
      case CrossSaveSyncStatus.verifying:
        return AppColors.accentBlue;
      case CrossSaveSyncStatus.conflictDetected:
        return AppColors.amberWarning;
      case CrossSaveSyncStatus.synced:
        return AppColors.statusSuccess;
      case CrossSaveSyncStatus.error:
        return AppColors.crimsonAlert;
    }
  }
}

/// Kanał transportu pakietu GZIP między urządzeniami.
enum CrossSaveTransferChannel {
  cloudSyncRelay,
  portableToken,
  localFileBundle;

  String get labelPl {
    switch (this) {
      case CrossSaveTransferChannel.cloudSyncRelay:
        return 'Chmura Cross-Save';
      case CrossSaveTransferChannel.portableToken:
        return 'Token / Schowek';
      case CrossSaveTransferChannel.localFileBundle:
        return 'Plik .ppmsave.gz';
    }
  }
}

/// Profil urządzenia zsynchronizowanego z kontem menedżera.
class CrossSaveDeviceProfile {
  final String deviceId;
  final String deviceName;
  final CrossSaveDevicePlatform platform;
  final String appVersion;
  final DateTime lastSeenAt;
  final bool isCurrentDevice;

  const CrossSaveDeviceProfile({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.appVersion,
    required this.lastSeenAt,
    this.isCurrentDevice = false,
  });

  CrossSaveDeviceProfile copyWith({
    String? deviceId,
    String? deviceName,
    CrossSaveDevicePlatform? platform,
    String? appVersion,
    DateTime? lastSeenAt,
    bool? isCurrentDevice,
  }) {
    return CrossSaveDeviceProfile(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      appVersion: appVersion ?? this.appVersion,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isCurrentDevice: isCurrentDevice ?? this.isCurrentDevice,
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'platform': platform.toJson(),
        'appVersion': appVersion,
        'lastSeenAt': lastSeenAt.toUtc().toIso8601String(),
        'isCurrentDevice': isCurrentDevice,
      };

  factory CrossSaveDeviceProfile.fromJson(Map<String, dynamic> json) {
    return CrossSaveDeviceProfile(
      deviceId: json['deviceId'] as String? ?? 'unknown-device',
      deviceName: json['deviceName'] as String? ?? 'Nieznane urządzenie',
      platform: CrossSaveDevicePlatform.fromJson(
        json['platform'] as String? ?? 'pcWindows',
      ),
      appVersion: json['appVersion'] as String? ?? '0.1.0+1',
      lastSeenAt: DateTime.tryParse(json['lastSeenAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      isCurrentDevice: json['isCurrentDevice'] as bool? ?? false,
    );
  }
}

/// Metadane i sumy kontrolne skompresowanej koperty zapisu.
class CrossSaveEnvelopeMetadata {
  final String saveId;
  final String saveName;
  final String managerName;
  final String teamName;
  final int seasonYear;
  final String inGameDateIso;
  final int schemaVersion;
  final CrossSaveDevicePlatform sourcePlatform;
  final String sourceDeviceId;
  final String sourceDeviceName;
  final DateTime createdAtUtc;
  final int uncompressedBytes;
  final int compressedBytes;
  final String fnv1a64Checksum;
  final String crc32Checksum;

  const CrossSaveEnvelopeMetadata({
    required this.saveId,
    required this.saveName,
    required this.managerName,
    required this.teamName,
    required this.seasonYear,
    required this.inGameDateIso,
    required this.schemaVersion,
    required this.sourcePlatform,
    required this.sourceDeviceId,
    required this.sourceDeviceName,
    required this.createdAtUtc,
    required this.uncompressedBytes,
    required this.compressedBytes,
    required this.fnv1a64Checksum,
    required this.crc32Checksum,
  });

  /// Procent zaoszczędzonego rozmiaru dzięki kompresji GZIP (0–100).
  double get bandwidthSavedPercent {
    if (uncompressedBytes <= 0) return 0.0;
    final double saved =
        ((uncompressedBytes - compressedBytes) / uncompressedBytes) * 100.0;
    return saved.clamp(0.0, 99.9);
  }

  /// Współczynnik kompresji (np. 4.2x).
  double get compressionRatio {
    if (compressedBytes <= 0) return 1.0;
    return uncompressedBytes / compressedBytes;
  }

  Map<String, dynamic> toJson() => {
        'saveId': saveId,
        'saveName': saveName,
        'managerName': managerName,
        'teamName': teamName,
        'seasonYear': seasonYear,
        'inGameDateIso': inGameDateIso,
        'schemaVersion': schemaVersion,
        'sourcePlatform': sourcePlatform.toJson(),
        'sourceDeviceId': sourceDeviceId,
        'sourceDeviceName': sourceDeviceName,
        'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
        'uncompressedBytes': uncompressedBytes,
        'compressedBytes': compressedBytes,
        'fnv1a64Checksum': fnv1a64Checksum,
        'crc32Checksum': crc32Checksum,
      };

  factory CrossSaveEnvelopeMetadata.fromJson(Map<String, dynamic> json) {
    return CrossSaveEnvelopeMetadata(
      saveId: json['saveId'] as String? ?? '',
      saveName: json['saveName'] as String? ?? 'Kariera',
      managerName: json['managerName'] as String? ?? 'Menedżer',
      teamName: json['teamName'] as String? ?? 'Zespół',
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      inGameDateIso: json['inGameDateIso'] as String? ?? '',
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      sourcePlatform: CrossSaveDevicePlatform.fromJson(
        json['sourcePlatform'] as String? ?? 'pcWindows',
      ),
      sourceDeviceId: json['sourceDeviceId'] as String? ?? 'unknown',
      sourceDeviceName: json['sourceDeviceName'] as String? ?? 'Device',
      createdAtUtc: DateTime.tryParse(json['createdAtUtc'] as String? ?? '') ??
          DateTime.now().toUtc(),
      uncompressedBytes: (json['uncompressedBytes'] as num?)?.toInt() ?? 0,
      compressedBytes: (json['compressedBytes'] as num?)?.toInt() ?? 0,
      fnv1a64Checksum: json['fnv1a64Checksum'] as String? ?? '',
      crc32Checksum: json['crc32Checksum'] as String? ?? '',
    );
  }
}

/// Skompresowany pakiet transferowy gotowy do przesłania między PC, Mac i Mobile.
class CrossSaveCompressedPacket {
  final String magicHeader;
  final CrossSaveEnvelopeMetadata metadata;
  final String gzipPayloadBase64;

  const CrossSaveCompressedPacket({
    this.magicHeader = kCrossSavePacketMagic,
    required this.metadata,
    required this.gzipPayloadBase64,
  });

  Map<String, dynamic> toJson() => {
        'magicHeader': magicHeader,
        'metadata': metadata.toJson(),
        'gzipPayloadBase64': gzipPayloadBase64,
      };

  factory CrossSaveCompressedPacket.fromJson(Map<String, dynamic> json) {
    final String magic = json['magicHeader'] as String? ?? '';
    if (magic != kCrossSavePacketMagic) {
      throw CrossSaveIntegrityException(
        'INVALID_MAGIC',
        'Nieprawidłowy nagłówek pakietu Cross-Save: $magic',
      );
    }
    final rawMeta = json['metadata'];
    if (rawMeta is! Map<String, dynamic>) {
      throw const CrossSaveIntegrityException(
        'MISSING_METADATA',
        'Brak metadanych koperty w pakiecie Cross-Save.',
      );
    }
    final payload = json['gzipPayloadBase64'] as String? ?? '';
    if (payload.isEmpty) {
      throw const CrossSaveIntegrityException(
        'EMPTY_PAYLOAD',
        'Pusty ładunek GZIP w pakiecie Cross-Save.',
      );
    }
    return CrossSaveCompressedPacket(
      magicHeader: magic,
      metadata: CrossSaveEnvelopeMetadata.fromJson(rawMeta),
      gzipPayloadBase64: payload,
    );
  }
}

/// Raport konfliktu wersji zapisu między urządzeniem lokalnym a chmurą.
class CrossSaveConflictReport {
  final String saveId;
  final String saveName;
  final DateTime localTimestampUtc;
  final DateTime remoteTimestampUtc;
  final CrossSaveDeviceProfile localDevice;
  final CrossSaveDeviceProfile remoteDevice;
  final int localSeasonYear;
  final int remoteSeasonYear;
  final CrossSaveConflictResolutionStrategy recommendedStrategy;
  final String summaryPl;

  const CrossSaveConflictReport({
    required this.saveId,
    required this.saveName,
    required this.localTimestampUtc,
    required this.remoteTimestampUtc,
    required this.localDevice,
    required this.remoteDevice,
    required this.localSeasonYear,
    required this.remoteSeasonYear,
    required this.recommendedStrategy,
    required this.summaryPl,
  });
}

/// Potwierdzenie wykonania operacji kompresji/transferu Cross-Save.
class CrossSaveTransferReceipt {
  final bool success;
  final CrossSaveSyncDirection direction;
  final CrossSaveTransferChannel channel;
  final String saveId;
  final int uncompressedBytes;
  final int compressedBytes;
  final double savedBandwidthPercent;
  final int durationMs;
  final bool checksumVerified;
  final CrossSaveConflictReport? conflict;
  final String messagePl;
  final DateTime timestampUtc;

  const CrossSaveTransferReceipt({
    required this.success,
    required this.direction,
    required this.channel,
    required this.saveId,
    required this.uncompressedBytes,
    required this.compressedBytes,
    required this.savedBandwidthPercent,
    required this.durationMs,
    required this.checksumVerified,
    this.conflict,
    required this.messagePl,
    required this.timestampUtc,
  });
}

/// Rekord slotu zapisanego w chmurze.
class CrossSaveCloudSlotRecord {
  final String slotKey;
  final CrossSaveCompressedPacket packet;
  final DateTime uploadedAtUtc;
  final int revisionNumber;

  const CrossSaveCloudSlotRecord({
    required this.slotKey,
    required this.packet,
    required this.uploadedAtUtc,
    required this.revisionNumber,
  });

  CrossSaveEnvelopeMetadata get metadata => packet.metadata;
}

/// Wpis w dzienniku historii synchronizacji między urządzeniami.
class CrossSaveSyncHistoryEntry {
  final String id;
  final DateTime timestampUtc;
  final CrossSaveSyncDirection direction;
  final CrossSaveTransferChannel channel;
  final CrossSaveDevicePlatform sourcePlatform;
  final String deviceName;
  final String saveName;
  final int uncompressedBytes;
  final int compressedBytes;
  final bool success;
  final String summaryPl;

  const CrossSaveSyncHistoryEntry({
    required this.id,
    required this.timestampUtc,
    required this.direction,
    required this.channel,
    required this.sourcePlatform,
    required this.deviceName,
    required this.saveName,
    required this.uncompressedBytes,
    required this.compressedBytes,
    required this.success,
    required this.summaryPl,
  });
}

/// Abstrakcyjny interfejs transportu chmurowego (łatwy do podpięcia pod REST / Firebase / iCloud).
abstract class CrossSaveCloudTransport {
  Future<List<CrossSaveCloudSlotRecord>> listSlots();

  Future<CrossSaveCloudSlotRecord?> fetchSlot(String slotKey);

  Future<CrossSaveCloudSlotRecord> pushSlot({
    required String slotKey,
    required CrossSaveCompressedPacket packet,
  });

  Future<bool> deleteSlot(String slotKey);
}

/// Lokalna implementacja transportu chmurowego w pamięci (do testów, symulacji i kolejki offline).
class InMemoryCrossSaveCloudTransport implements CrossSaveCloudTransport {
  final Map<String, CrossSaveCloudSlotRecord> _store = {};

  InMemoryCrossSaveCloudTransport({
    List<CrossSaveCloudSlotRecord> initialRecords = const [],
  }) {
    for (final record in initialRecords) {
      _store[record.slotKey] = record;
    }
  }

  @override
  Future<List<CrossSaveCloudSlotRecord>> listSlots() async {
    final list = _store.values.toList()
      ..sort((a, b) => b.uploadedAtUtc.compareTo(a.uploadedAtUtc));
    return list;
  }

  @override
  Future<CrossSaveCloudSlotRecord?> fetchSlot(String slotKey) async {
    return _store[slotKey];
  }

  @override
  Future<CrossSaveCloudSlotRecord> pushSlot({
    required String slotKey,
    required CrossSaveCompressedPacket packet,
  }) async {
    final existing = _store[slotKey];
    final nextRevision = (existing?.revisionNumber ?? 0) + 1;
    final record = CrossSaveCloudSlotRecord(
      slotKey: slotKey,
      packet: packet,
      uploadedAtUtc: DateTime.now().toUtc(),
      revisionNumber: nextRevision,
    );
    _store[slotKey] = record;
    return record;
  }

  @override
  Future<bool> deleteSlot(String slotKey) async {
    return _store.remove(slotKey) != null;
  }
}

/// Główny adapter kompresji GZIP i transferu zapisów JSON między urządzeniami (PC <-> Mac <-> Mobile).
class CloudCrossSaveJsonSyncAdapter {
  final CrossSaveCloudTransport transport;

  CloudCrossSaveJsonSyncAdapter({
    CrossSaveCloudTransport? transport,
  }) : transport = transport ?? InMemoryCrossSaveCloudTransport();

  /// Wylicza deterministyczną sumę kontrolną FNV-1a 64-bit dla bajtów UTF-8.
  static String computeFnv1a64Hex(List<int> bytes) {
    BigInt hash = BigInt.parse('cbf29ce484222325', radix: 16);
    final BigInt prime = BigInt.parse('100000001b3', radix: 16);
    final BigInt mask64 = BigInt.parse('ffffffffffffffff', radix: 16);

    for (final int b in bytes) {
      hash = hash ^ BigInt.from(b & 0xff);
      hash = (hash * prime) & mask64;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  /// Wylicza deterministyczną sumę kontrolną CRC-32 (IEEE 802.3).
  static String computeCrc32Hex(List<int> bytes) {
    int crc = 0xffffffff;
    for (final int b in bytes) {
      crc ^= (b & 0xff);
      for (int i = 0; i < 8; i++) {
        if ((crc & 1) != 0) {
          crc = (crc >>> 1) ^ 0xedb88320;
        } else {
          crc = crc >>> 1;
        }
      }
    }
    final int finalCrc = crc ^ 0xffffffff;
    return finalCrc.toRadixString(16).padLeft(8, '0');
  }

  /// Normalizuje JSON między systemami (usuwa \r\n na rzecz \n w polach tekstowych i zachowuje strukturę).
  static dynamic normalizeCrossPlatformJson(dynamic value) {
    if (value is String) {
      return value.replaceAll('\r\n', '\n');
    }
    if (value is List) {
      return value.map(normalizeCrossPlatformJson).toList();
    }
    if (value is Map) {
      final Map<String, dynamic> normalized = <String, dynamic>{};
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      for (final key in keys) {
        normalized[key] = normalizeCrossPlatformJson(value[key]);
      }
      return normalized;
    }
    return value;
  }

  /// Kompresuje pełny obiekt [CareerSave] do pakietu GZIP z metadanymi i sumami kontrolnymi.
  CrossSaveCompressedPacket compressCareerSave({
    required CareerSave save,
    required CrossSaveDeviceProfile sourceDevice,
    int compressionLevel = 9,
  }) {
    final jsonMap = save.toJson();
    return compressRawJson(
      jsonMap: jsonMap,
      sourceDevice: sourceDevice,
      compressionLevel: compressionLevel,
      fallbackSaveId: save.id,
      fallbackSaveName: save.saveName,
      fallbackManagerName: save.playerManagerName,
      fallbackTeamName: save.playerTeam.name,
      fallbackSeasonYear: save.currentSeasonYear,
      fallbackInGameDateIso: save.currentDate.toIso8601String(),
    );
  }

  /// Kompresuje dowolną mapę JSON zapisu gry do pakietu GZIP gotowego do transferu między urządzeniami.
  CrossSaveCompressedPacket compressRawJson({
    required Map<String, dynamic> jsonMap,
    required CrossSaveDeviceProfile sourceDevice,
    int compressionLevel = 9,
    String? fallbackSaveId,
    String? fallbackSaveName,
    String? fallbackManagerName,
    String? fallbackTeamName,
    int? fallbackSeasonYear,
    String? fallbackInGameDateIso,
  }) {
    final int clampedLevel = compressionLevel.clamp(1, 9);
    final normalizedMap =
        normalizeCrossPlatformJson(jsonMap) as Map<String, dynamic>;
    final String canonicalJson = jsonEncode(normalizedMap);
    final Uint8List rawBytes = Uint8List.fromList(utf8.encode(canonicalJson));

    final GZipCodec codec = GZipCodec(level: clampedLevel);
    final List<int> compressedBytes = codec.encode(rawBytes);
    final String payloadBase64 = base64Encode(compressedBytes);

    final String fnvHash = computeFnv1a64Hex(rawBytes);
    final String crcHash = computeCrc32Hex(rawBytes);

    final String saveId =
        (normalizedMap['id'] as String?) ?? fallbackSaveId ?? 'save_unknown';
    final String saveName =
        (normalizedMap['saveName'] as String?) ?? fallbackSaveName ?? saveId;
    final String managerName =
        (normalizedMap['playerManagerName'] as String?) ??
            fallbackManagerName ??
            'Menedżer';
    final String teamName =
        _extractTeamName(normalizedMap) ?? fallbackTeamName ?? 'Zespół';
    final int seasonYear =
        (normalizedMap['currentSeasonYear'] as num?)?.toInt() ??
            fallbackSeasonYear ??
            2026;
    final String inGameDateIso =
        (normalizedMap['currentDate'] as String?) ??
            fallbackInGameDateIso ??
            DateTime.now().toUtc().toIso8601String();

    final metadata = CrossSaveEnvelopeMetadata(
      saveId: saveId,
      saveName: saveName,
      managerName: managerName,
      teamName: teamName,
      seasonYear: seasonYear,
      inGameDateIso: inGameDateIso,
      schemaVersion: kCrossSaveSchemaVersion,
      sourcePlatform: sourceDevice.platform,
      sourceDeviceId: sourceDevice.deviceId,
      sourceDeviceName: sourceDevice.deviceName,
      createdAtUtc: DateTime.now().toUtc(),
      uncompressedBytes: rawBytes.length,
      compressedBytes: compressedBytes.length,
      fnv1a64Checksum: fnvHash,
      crc32Checksum: crcHash,
    );

    return CrossSaveCompressedPacket(
      magicHeader: kCrossSavePacketMagic,
      metadata: metadata,
      gzipPayloadBase64: payloadBase64,
    );
  }

  /// Dekompresuje pakiet GZIP i weryfikuje rozmiar oraz sumy kontrolne FNV-1a64 i CRC-32.
  Map<String, dynamic> decompressToJson(CrossSaveCompressedPacket packet) {
    if (packet.magicHeader != kCrossSavePacketMagic) {
      throw CrossSaveIntegrityException(
        'INVALID_MAGIC',
        'Nieobsługiwany nagłówek pakietu: ${packet.magicHeader}',
      );
    }

    late final Uint8List compressedBytes;
    try {
      compressedBytes = base64Decode(packet.gzipPayloadBase64);
    } catch (e) {
      throw CrossSaveIntegrityException(
        'INVALID_BASE64',
        'Uszkodzone kodowanie Base64 ładunku GZIP: $e',
      );
    }

    late final List<int> decompressedBytes;
    try {
      decompressedBytes = GZipCodec().decode(compressedBytes);
    } catch (e) {
      throw CrossSaveIntegrityException(
        'GZIP_DECODE_FAILED',
        'Błąd dekompresji strumienia GZIP: $e',
      );
    }

    if (packet.metadata.uncompressedBytes > 0 &&
        decompressedBytes.length != packet.metadata.uncompressedBytes) {
      throw CrossSaveIntegrityException(
        'SIZE_MISMATCH',
        'Niezgodność rozmiaru po dekompresji: oczekiwano '
            '${packet.metadata.uncompressedBytes} B, otrzymano ${decompressedBytes.length} B.',
      );
    }

    final String actualFnv = computeFnv1a64Hex(decompressedBytes);
    if (packet.metadata.fnv1a64Checksum.isNotEmpty &&
        actualFnv != packet.metadata.fnv1a64Checksum) {
      throw CrossSaveIntegrityException(
        'FNV1A_MISMATCH',
        'Niezgodna suma kontrolna FNV-1a64 (oczekiwano '
            '${packet.metadata.fnv1a64Checksum}, otrzymano $actualFnv).',
      );
    }

    final String actualCrc = computeCrc32Hex(decompressedBytes);
    if (packet.metadata.crc32Checksum.isNotEmpty &&
        actualCrc != packet.metadata.crc32Checksum) {
      throw CrossSaveIntegrityException(
        'CRC32_MISMATCH',
        'Niezgodna suma kontrolna CRC-32 (oczekiwano '
            '${packet.metadata.crc32Checksum}, otrzymano $actualCrc).',
      );
    }

    try {
      final String jsonStr = utf8.decode(decompressedBytes);
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        throw const CrossSaveIntegrityException(
          'NOT_JSON_OBJECT',
          'Zdekodowany zapis nie jest obiektem JSON.',
        );
      }
      return decoded;
    } catch (e) {
      if (e is CrossSaveIntegrityException) rethrow;
      throw CrossSaveIntegrityException(
        'JSON_PARSE_FAILED',
        'Błąd parsowania JSON po dekompresji: $e',
      );
    }
  }

  /// Dekompresuje pakiet GZIP bezpośrednio do pełnego obiektu [CareerSave].
  CareerSave decompressToCareerSave(CrossSaveCompressedPacket packet) {
    final jsonMap = decompressToJson(packet);
    return CareerSave.fromJson(jsonMap);
  }

  /// Koduje pakiet do zwartego tokenu tekstowego (`PPMCS1:...`) do kopiowania między PC <-> Mac <-> Mobile.
  String encodePortableToken(CrossSaveCompressedPacket packet) {
    final String envelopeJson = jsonEncode(packet.toJson());
    final List<int> envelopeGz = GZipCodec(level: 9).encode(utf8.encode(envelopeJson));
    final String encoded = base64UrlEncode(envelopeGz);
    return '$kCrossSaveTokenPrefix$encoded';
  }

  /// Dekoduje przenośny token tekstowy (`PPMCS1:...`) z powrotem do pakietu Cross-Save.
  CrossSaveCompressedPacket decodePortableToken(String rawToken) {
    final String trimmed = rawToken.trim();
    if (!trimmed.startsWith(kCrossSaveTokenPrefix)) {
      throw const CrossSaveIntegrityException(
        'INVALID_TOKEN_PREFIX',
        'Token nie rozpoczyna się od wymaganego prefiksu $kCrossSaveTokenPrefix.',
      );
    }
    final String payload = trimmed.substring(kCrossSaveTokenPrefix.length);
    if (payload.isEmpty) {
      throw const CrossSaveIntegrityException(
        'EMPTY_TOKEN',
        'Przenośny token Cross-Save jest pusty.',
      );
    }

    try {
      final Uint8List gzBytes = base64Url.decode(payload);
      final List<int> jsonBytes = GZipCodec().decode(gzBytes);
      final dynamic decoded = jsonDecode(utf8.decode(jsonBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const CrossSaveIntegrityException(
          'INVALID_TOKEN_JSON',
          'Nieprawidłowa struktura JSON wewnątrz tokenu.',
        );
      }
      return CrossSaveCompressedPacket.fromJson(decoded);
    } catch (e) {
      if (e is CrossSaveIntegrityException) rethrow;
      throw CrossSaveIntegrityException(
        'TOKEN_DECODE_FAILED',
        'Nie udało się zdekodować tokenu Cross-Save: $e',
      );
    }
  }

  /// Zapisuje skompresowany pakiet na dysk jako przenośny plik `.ppmsave.gz` (kompatybilny między Windows/macOS/Mobile).
  Future<File> exportToCompressedFile({
    required CrossSaveCompressedPacket packet,
    required Directory targetDirectory,
    String? customFileName,
  }) async {
    if (!await targetDirectory.exists()) {
      await targetDirectory.create(recursive: true);
    }
    final String safeId = packet.metadata.saveId
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final String fileName = customFileName ?? '$safeId$kCrossSaveFileExtension';
    final String path =
        '${targetDirectory.path}${Platform.pathSeparator}$fileName';
    final File outFile = File(path);

    final List<int> envelopeGz =
        GZipCodec(level: 9).encode(utf8.encode(jsonEncode(packet.toJson())));
    await outFile.writeAsBytes(envelopeGz, flush: true);
    return outFile;
  }

  /// Odczytuje skompresowany plik `.ppmsave.gz` i weryfikuje jego strukturę.
  Future<CrossSaveCompressedPacket> importFromCompressedFile(File file) async {
    if (!await file.exists()) {
      throw CrossSaveIntegrityException(
        'FILE_NOT_FOUND',
        'Plik Cross-Save nie istnieje: ${file.path}',
      );
    }
    try {
      final Uint8List bytes = await file.readAsBytes();
      final List<int> jsonBytes = GZipCodec().decode(bytes);
      final dynamic decoded = jsonDecode(utf8.decode(jsonBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const CrossSaveIntegrityException(
          'INVALID_FILE_JSON',
          'Zawartość pliku nie jest prawidłowym pakietem Cross-Save.',
        );
      }
      return CrossSaveCompressedPacket.fromJson(decoded);
    } catch (e) {
      if (e is CrossSaveIntegrityException) rethrow;
      throw CrossSaveIntegrityException(
        'FILE_READ_FAILED',
        'Błąd odczytu pliku .ppmsave.gz: $e',
      );
    }
  }

  /// Wykrywa ewentualny konflikt wersji między lokalnym zapisem a slotem w chmurze.
  Future<CrossSaveConflictReport?> detectConflict({
    required String slotKey,
    required CrossSaveEnvelopeMetadata localMetadata,
    required CrossSaveDeviceProfile localDevice,
  }) async {
    final remote = await transport.fetchSlot(slotKey);
    if (remote == null) return null;

    final remoteMeta = remote.metadata;
    final bool differentDevice = remoteMeta.sourceDeviceId != localDevice.deviceId;
    final bool differentChecksum =
        remoteMeta.fnv1a64Checksum != localMetadata.fnv1a64Checksum;

    // Konflikt występuje, gdy inne urządzenie zapisało inną wersję, a lokalny zapis nie jest jednoznacznie nowszy o >2s lub ma inny sezon.
    if (differentDevice && differentChecksum) {
      final bool localNewer =
          localMetadata.createdAtUtc.isAfter(remoteMeta.createdAtUtc);
      final recommended = localNewer
          ? CrossSaveConflictResolutionStrategy.preferLocalDevice
          : CrossSaveConflictResolutionStrategy.preferCloudRemote;

      final remoteDevice = CrossSaveDeviceProfile(
        deviceId: remoteMeta.sourceDeviceId,
        deviceName: remoteMeta.sourceDeviceName,
        platform: remoteMeta.sourcePlatform,
        appVersion: '0.1.0+1',
        lastSeenAt: remoteMeta.createdAtUtc,
      );

      return CrossSaveConflictReport(
        saveId: localMetadata.saveId,
        saveName: localMetadata.saveName,
        localTimestampUtc: localMetadata.createdAtUtc,
        remoteTimestampUtc: remoteMeta.createdAtUtc,
        localDevice: localDevice,
        remoteDevice: remoteDevice,
        localSeasonYear: localMetadata.seasonYear,
        remoteSeasonYear: remoteMeta.seasonYear,
        recommendedStrategy: recommended,
        summaryPl: 'Wykryto rozbieżną wersję zapisu z urządzenia '
            '${remoteMeta.sourceDeviceName} (${remoteMeta.sourcePlatform.shortCode}).',
      );
    }
    return null;
  }

  /// Wysyła skompresowany zapis JSON do chmury z opcjonalnym sprawdzaniem konfliktów.
  Future<CrossSaveTransferReceipt> uploadSaveJson({
    required String slotKey,
    required Map<String, dynamic> saveJson,
    required CrossSaveDeviceProfile sourceDevice,
    int compressionLevel = 9,
    CrossSaveConflictResolutionStrategy conflictStrategy =
        CrossSaveConflictResolutionStrategy.keepNewestTimestamp,
  }) async {
    final Stopwatch sw = Stopwatch()..start();
    final packet = compressRawJson(
      jsonMap: saveJson,
      sourceDevice: sourceDevice,
      compressionLevel: compressionLevel,
    );

    final conflict = await detectConflict(
      slotKey: slotKey,
      localMetadata: packet.metadata,
      localDevice: sourceDevice,
    );

    if (conflict != null &&
        conflictStrategy == CrossSaveConflictResolutionStrategy.manualReview) {
      sw.stop();
      return CrossSaveTransferReceipt(
        success: false,
        direction: CrossSaveSyncDirection.uploadToCloud,
        channel: CrossSaveTransferChannel.cloudSyncRelay,
        saveId: packet.metadata.saveId,
        uncompressedBytes: packet.metadata.uncompressedBytes,
        compressedBytes: packet.metadata.compressedBytes,
        savedBandwidthPercent: packet.metadata.bandwidthSavedPercent,
        durationMs: sw.elapsedMilliseconds,
        checksumVerified: true,
        conflict: conflict,
        messagePl: conflict.summaryPl,
        timestampUtc: DateTime.now().toUtc(),
      );
    }

    if (conflict != null &&
        conflictStrategy ==
            CrossSaveConflictResolutionStrategy.preferCloudRemote) {
      sw.stop();
      return CrossSaveTransferReceipt(
        success: true,
        direction: CrossSaveSyncDirection.uploadToCloud,
        channel: CrossSaveTransferChannel.cloudSyncRelay,
        saveId: packet.metadata.saveId,
        uncompressedBytes: packet.metadata.uncompressedBytes,
        compressedBytes: packet.metadata.compressedBytes,
        savedBandwidthPercent: packet.metadata.bandwidthSavedPercent,
        durationMs: sw.elapsedMilliseconds,
        checksumVerified: true,
        conflict: conflict,
        messagePl: 'Zachowano wersję chmurową zgodnie ze strategią konfliktu.',
        timestampUtc: DateTime.now().toUtc(),
      );
    }

    await transport.pushSlot(slotKey: slotKey, packet: packet);
    sw.stop();

    return CrossSaveTransferReceipt(
      success: true,
      direction: CrossSaveSyncDirection.uploadToCloud,
      channel: CrossSaveTransferChannel.cloudSyncRelay,
      saveId: packet.metadata.saveId,
      uncompressedBytes: packet.metadata.uncompressedBytes,
      compressedBytes: packet.metadata.compressedBytes,
      savedBandwidthPercent: packet.metadata.bandwidthSavedPercent,
      durationMs: sw.elapsedMilliseconds,
      checksumVerified: true,
      messagePl: 'Wysłano zapis GZIP (${_formatBytes(packet.metadata.compressedBytes)} '
          'z ${_formatBytes(packet.metadata.uncompressedBytes)}).',
      timestampUtc: DateTime.now().toUtc(),
    );
  }

  /// Pobiera slot z chmury, dekompresuje GZIP i weryfikuje sumy kontrolne.
  Future<({Map<String, dynamic>? json, CrossSaveTransferReceipt receipt})>
      downloadSaveJson({
    required String slotKey,
  }) async {
    final Stopwatch sw = Stopwatch()..start();
    final record = await transport.fetchSlot(slotKey);
    if (record == null) {
      sw.stop();
      return (
        json: null,
        receipt: CrossSaveTransferReceipt(
          success: false,
          direction: CrossSaveSyncDirection.downloadFromCloud,
          channel: CrossSaveTransferChannel.cloudSyncRelay,
          saveId: slotKey,
          uncompressedBytes: 0,
          compressedBytes: 0,
          savedBandwidthPercent: 0,
          durationMs: sw.elapsedMilliseconds,
          checksumVerified: false,
          messagePl: 'Brak zapisu w chmurze dla slotu "$slotKey".',
          timestampUtc: DateTime.now().toUtc(),
        ),
      );
    }

    final decodedJson = decompressToJson(record.packet);
    sw.stop();

    return (
      json: decodedJson,
      receipt: CrossSaveTransferReceipt(
        success: true,
        direction: CrossSaveSyncDirection.downloadFromCloud,
        channel: CrossSaveTransferChannel.cloudSyncRelay,
        saveId: record.metadata.saveId,
        uncompressedBytes: record.metadata.uncompressedBytes,
        compressedBytes: record.metadata.compressedBytes,
        savedBandwidthPercent: record.metadata.bandwidthSavedPercent,
        durationMs: sw.elapsedMilliseconds,
        checksumVerified: true,
        messagePl:
            'Pobrano i zweryfikowano zapis z ${record.metadata.sourceDeviceName} '
            '(${record.metadata.sourcePlatform.shortCode}).',
        timestampUtc: DateTime.now().toUtc(),
      ),
    );
  }

  static String? _extractTeamName(Map<String, dynamic> map) {
    final String? teamId = map['playerTeamId'] as String?;
    final dynamic teams = map['teams'];
    if (teamId != null && teams is List) {
      for (final t in teams) {
        if (t is Map && t['id'] == teamId) {
          return t['name'] as String?;
        }
      }
    }
    return map['playerTeamName'] as String?;
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

/// Stan kontrolera synchronizacji Cross-Save w Riverpod.
class CloudCrossSaveSyncState {
  final CrossSaveDeviceProfile currentDevice;
  final List<CrossSaveDeviceProfile> linkedDevices;
  final List<CrossSaveCloudSlotRecord> cloudSlots;
  final List<CrossSaveSyncHistoryEntry> syncHistory;
  final CrossSaveSyncStatus status;
  final CrossSaveTransferChannel selectedChannel;
  final int gzipCompressionLevel;
  final bool autoSyncOnSave;
  final CrossSaveConflictReport? pendingConflict;
  final CrossSaveTransferReceipt? lastReceipt;
  final String? lastGeneratedToken;
  final String? errorMessage;

  const CloudCrossSaveSyncState({
    required this.currentDevice,
    this.linkedDevices = const [],
    this.cloudSlots = const [],
    this.syncHistory = const [],
    this.status = CrossSaveSyncStatus.idle,
    this.selectedChannel = CrossSaveTransferChannel.cloudSyncRelay,
    this.gzipCompressionLevel = 9,
    this.autoSyncOnSave = true,
    this.pendingConflict,
    this.lastReceipt,
    this.lastGeneratedToken,
    this.errorMessage,
  });

  int get totalUncompressedBytes => cloudSlots.fold<int>(
      0, (sum, s) => sum + s.metadata.uncompressedBytes);

  int get totalCompressedBytes =>
      cloudSlots.fold<int>(0, (sum, s) => sum + s.metadata.compressedBytes);

  double get averageBandwidthSavedPercent {
    final raw = totalUncompressedBytes;
    if (raw <= 0) return 0.0;
    return (((raw - totalCompressedBytes) / raw) * 100.0).clamp(0.0, 99.9);
  }

  CloudCrossSaveSyncState copyWith({
    CrossSaveDeviceProfile? currentDevice,
    List<CrossSaveDeviceProfile>? linkedDevices,
    List<CrossSaveCloudSlotRecord>? cloudSlots,
    List<CrossSaveSyncHistoryEntry>? syncHistory,
    CrossSaveSyncStatus? status,
    CrossSaveTransferChannel? selectedChannel,
    int? gzipCompressionLevel,
    bool? autoSyncOnSave,
    CrossSaveConflictReport? pendingConflict,
    bool clearPendingConflict = false,
    CrossSaveTransferReceipt? lastReceipt,
    String? lastGeneratedToken,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CloudCrossSaveSyncState(
      currentDevice: currentDevice ?? this.currentDevice,
      linkedDevices: linkedDevices ?? this.linkedDevices,
      cloudSlots: cloudSlots ?? this.cloudSlots,
      syncHistory: syncHistory ?? this.syncHistory,
      status: status ?? this.status,
      selectedChannel: selectedChannel ?? this.selectedChannel,
      gzipCompressionLevel: gzipCompressionLevel ?? this.gzipCompressionLevel,
      autoSyncOnSave: autoSyncOnSave ?? this.autoSyncOnSave,
      pendingConflict:
          clearPendingConflict ? null : (pendingConflict ?? this.pendingConflict),
      lastReceipt: lastReceipt ?? this.lastReceipt,
      lastGeneratedToken: lastGeneratedToken ?? this.lastGeneratedToken,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Kontroler Riverpod zarządzający kompresją GZIP i synchronizacją zapisów między urządzeniami.
class CloudCrossSaveSyncNotifier extends StateNotifier<CloudCrossSaveSyncState> {
  final CloudCrossSaveJsonSyncAdapter adapter;
  Map<String, dynamic>? _pendingConflictJson;
  String? _pendingConflictSlotKey;

  CloudCrossSaveSyncNotifier({
    CloudCrossSaveJsonSyncAdapter? adapter,
    CrossSaveDeviceProfile? currentDevice,
  })  : adapter = adapter ?? CloudCrossSaveJsonSyncAdapter(),
        super(_buildInitialState(currentDevice));

  static CloudCrossSaveSyncState _buildInitialState(
    CrossSaveDeviceProfile? currentDevice,
  ) {
    final now = DateTime.now().toUtc();
    final detectedPlatform = CrossSaveDevicePlatform.detectCurrent();
    final activeDevice = currentDevice ??
        CrossSaveDeviceProfile(
          deviceId: 'dev_local_${detectedPlatform.shortCode.toLowerCase()}',
          deviceName: 'Stacja robocza ${detectedPlatform.shortCode}',
          platform: detectedPlatform,
          appVersion: '0.1.0+1',
          lastSeenAt: now,
          isCurrentDevice: true,
        );

    final devices = <CrossSaveDeviceProfile>[
      activeDevice,
      if (detectedPlatform != CrossSaveDevicePlatform.pcWindows)
        CrossSaveDeviceProfile(
          deviceId: 'dev_win_studio',
          deviceName: 'PC Windows Gaming',
          platform: CrossSaveDevicePlatform.pcWindows,
          appVersion: '0.1.0+1',
          lastSeenAt: now.subtract(const Duration(hours: 3)),
        ),
      if (detectedPlatform != CrossSaveDevicePlatform.macOs)
        CrossSaveDeviceProfile(
          deviceId: 'dev_mac_pro',
          deviceName: 'MacBook Pro M3',
          platform: CrossSaveDevicePlatform.macOs,
          appVersion: '0.1.0+1',
          lastSeenAt: now.subtract(const Duration(hours: 6)),
        ),
      if (detectedPlatform != CrossSaveDevicePlatform.mobileIos &&
          detectedPlatform != CrossSaveDevicePlatform.mobileAndroid)
        CrossSaveDeviceProfile(
          deviceId: 'dev_mobile_companion',
          deviceName: 'iPhone / Android Mobile',
          platform: CrossSaveDevicePlatform.mobileIos,
          appVersion: '0.1.0+1',
          lastSeenAt: now.subtract(const Duration(minutes: 42)),
        ),
    ];

    return CloudCrossSaveSyncState(
      currentDevice: activeDevice,
      linkedDevices: devices,
    );
  }

  /// Odświeża listę slotów z transportu chmurowego.
  Future<void> refreshCloudSlots() async {
    final slots = await adapter.transport.listSlots();
    state = state.copyWith(cloudSlots: slots, clearError: true);
  }

  /// Wysyła zapis [CareerSave] do chmury ze skompresowanym ładunkiem GZIP.
  Future<CrossSaveTransferReceipt> syncUploadCareerSave({
    required String slotKey,
    required CareerSave save,
    CrossSaveConflictResolutionStrategy conflictStrategy =
        CrossSaveConflictResolutionStrategy.keepNewestTimestamp,
  }) {
    return syncUploadSaveJson(
      slotKey: slotKey,
      saveJson: save.toJson(),
      conflictStrategy: conflictStrategy,
    );
  }

  /// Wysyła surową mapę JSON zapisu do chmury ze skompresowanym ładunkiem GZIP.
  Future<CrossSaveTransferReceipt> syncUploadSaveJson({
    required String slotKey,
    required Map<String, dynamic> saveJson,
    CrossSaveConflictResolutionStrategy conflictStrategy =
        CrossSaveConflictResolutionStrategy.keepNewestTimestamp,
  }) async {
    state = state.copyWith(
      status: CrossSaveSyncStatus.compressing,
      clearError: true,
      clearPendingConflict: true,
    );

    try {
      state = state.copyWith(status: CrossSaveSyncStatus.uploading);
      final receipt = await adapter.uploadSaveJson(
        slotKey: slotKey,
        saveJson: saveJson,
        sourceDevice: state.currentDevice,
        compressionLevel: state.gzipCompressionLevel,
        conflictStrategy: conflictStrategy,
      );

      if (receipt.conflict != null && !receipt.success) {
        _pendingConflictJson = saveJson;
        _pendingConflictSlotKey = slotKey;
        state = state.copyWith(
          status: CrossSaveSyncStatus.conflictDetected,
          pendingConflict: receipt.conflict,
          lastReceipt: receipt,
        );
        return receipt;
      }

      final slots = await adapter.transport.listSlots();
      final historyEntry = CrossSaveSyncHistoryEntry(
        id: 'sync_${DateTime.now().microsecondsSinceEpoch}',
        timestampUtc: receipt.timestampUtc,
        direction: CrossSaveSyncDirection.uploadToCloud,
        channel: CrossSaveTransferChannel.cloudSyncRelay,
        sourcePlatform: state.currentDevice.platform,
        deviceName: state.currentDevice.deviceName,
        saveName: (saveJson['saveName'] as String?) ?? receipt.saveId,
        uncompressedBytes: receipt.uncompressedBytes,
        compressedBytes: receipt.compressedBytes,
        success: receipt.success,
        summaryPl: receipt.messagePl,
      );

      state = state.copyWith(
        status: CrossSaveSyncStatus.synced,
        cloudSlots: slots,
        lastReceipt: receipt,
        syncHistory: [historyEntry, ...state.syncHistory].take(20).toList(),
      );
      return receipt;
    } catch (e) {
      final errReceipt = CrossSaveTransferReceipt(
        success: false,
        direction: CrossSaveSyncDirection.uploadToCloud,
        channel: CrossSaveTransferChannel.cloudSyncRelay,
        saveId: slotKey,
        uncompressedBytes: 0,
        compressedBytes: 0,
        savedBandwidthPercent: 0,
        durationMs: 0,
        checksumVerified: false,
        messagePl: 'Błąd wysyłania: $e',
        timestampUtc: DateTime.now().toUtc(),
      );
      state = state.copyWith(
        status: CrossSaveSyncStatus.error,
        lastReceipt: errReceipt,
        errorMessage: errReceipt.messagePl,
      );
      return errReceipt;
    }
  }

  /// Pobiera zapis z chmury, dekompresuje i weryfikuje sumy kontrolne.
  Future<Map<String, dynamic>?> syncDownloadSaveJson(String slotKey) async {
    state = state.copyWith(
      status: CrossSaveSyncStatus.downloading,
      clearError: true,
    );

    try {
      final result = await adapter.downloadSaveJson(slotKey: slotKey);
      if (!result.receipt.success || result.json == null) {
        state = state.copyWith(
          status: CrossSaveSyncStatus.error,
          lastReceipt: result.receipt,
          errorMessage: result.receipt.messagePl,
        );
        return null;
      }

      final historyEntry = CrossSaveSyncHistoryEntry(
        id: 'sync_${DateTime.now().microsecondsSinceEpoch}',
        timestampUtc: result.receipt.timestampUtc,
        direction: CrossSaveSyncDirection.downloadFromCloud,
        channel: CrossSaveTransferChannel.cloudSyncRelay,
        sourcePlatform: state.currentDevice.platform,
        deviceName: state.currentDevice.deviceName,
        saveName: (result.json!['saveName'] as String?) ?? slotKey,
        uncompressedBytes: result.receipt.uncompressedBytes,
        compressedBytes: result.receipt.compressedBytes,
        success: true,
        summaryPl: result.receipt.messagePl,
      );

      state = state.copyWith(
        status: CrossSaveSyncStatus.synced,
        lastReceipt: result.receipt,
        syncHistory: [historyEntry, ...state.syncHistory].take(20).toList(),
      );
      return result.json;
    } catch (e) {
      state = state.copyWith(
        status: CrossSaveSyncStatus.error,
        errorMessage: 'Błąd dekompresji lub weryfikacji: $e',
      );
      return null;
    }
  }

  /// Rozwiązuje wykryty konflikt wybraną strategią.
  Future<void> resolvePendingConflict(
    CrossSaveConflictResolutionStrategy strategy,
  ) async {
    final slotKey = _pendingConflictSlotKey;
    final pendingJson = _pendingConflictJson;
    if (slotKey == null || pendingJson == null) {
      state = state.copyWith(
        clearPendingConflict: true,
        status: CrossSaveSyncStatus.idle,
      );
      return;
    }

    _pendingConflictJson = null;
    _pendingConflictSlotKey = null;

    if (strategy == CrossSaveConflictResolutionStrategy.preferCloudRemote) {
      await syncDownloadSaveJson(slotKey);
      state = state.copyWith(clearPendingConflict: true);
    } else {
      await syncUploadSaveJson(
        slotKey: slotKey,
        saveJson: pendingJson,
        conflictStrategy: CrossSaveConflictResolutionStrategy.preferLocalDevice,
      );
      state = state.copyWith(clearPendingConflict: true);
    }
  }

  /// Generuje przenośny token GZIP (`PPMCS1:...`) dla wskazanego slotu w chmurze.
  String? generatePortableTokenForSlot(String slotKey) {
    final match = state.cloudSlots.where((s) => s.slotKey == slotKey).toList();
    if (match.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Nie znaleziono slotu "$slotKey" do eksportu tokenu.',
      );
      return null;
    }
    final token = adapter.encodePortableToken(match.first.packet);
    state = state.copyWith(
      lastGeneratedToken: token,
      clearError: true,
    );
    return token;
  }

  /// Importuje przenośny token (`PPMCS1:...`), weryfikuje sumy i zapisuje go w chmurze.
  Future<Map<String, dynamic>?> importPortableToken({
    required String token,
    String targetSlotKey = 'slot_cross_import',
  }) async {
    state = state.copyWith(
      status: CrossSaveSyncStatus.verifying,
      clearError: true,
    );

    try {
      final packet = adapter.decodePortableToken(token);
      final jsonMap = adapter.decompressToJson(packet);
      await adapter.transport.pushSlot(slotKey: targetSlotKey, packet: packet);
      final slots = await adapter.transport.listSlots();

      final receipt = CrossSaveTransferReceipt(
        success: true,
        direction: CrossSaveSyncDirection.downloadFromCloud,
        channel: CrossSaveTransferChannel.portableToken,
        saveId: packet.metadata.saveId,
        uncompressedBytes: packet.metadata.uncompressedBytes,
        compressedBytes: packet.metadata.compressedBytes,
        savedBandwidthPercent: packet.metadata.bandwidthSavedPercent,
        durationMs: 1,
        checksumVerified: true,
        messagePl: 'Zaimportowano token z ${packet.metadata.sourceDeviceName} '
            '(${packet.metadata.sourcePlatform.shortCode}).',
        timestampUtc: DateTime.now().toUtc(),
      );

      final historyEntry = CrossSaveSyncHistoryEntry(
        id: 'tok_${DateTime.now().microsecondsSinceEpoch}',
        timestampUtc: receipt.timestampUtc,
        direction: CrossSaveSyncDirection.downloadFromCloud,
        channel: CrossSaveTransferChannel.portableToken,
        sourcePlatform: packet.metadata.sourcePlatform,
        deviceName: packet.metadata.sourceDeviceName,
        saveName: packet.metadata.saveName,
        uncompressedBytes: packet.metadata.uncompressedBytes,
        compressedBytes: packet.metadata.compressedBytes,
        success: true,
        summaryPl: receipt.messagePl,
      );

      state = state.copyWith(
        status: CrossSaveSyncStatus.synced,
        cloudSlots: slots,
        lastReceipt: receipt,
        syncHistory: [historyEntry, ...state.syncHistory].take(20).toList(),
      );
      return jsonMap;
    } catch (e) {
      state = state.copyWith(
        status: CrossSaveSyncStatus.error,
        errorMessage: 'Nieprawidłowy token Cross-Save: $e',
      );
      return null;
    }
  }

  /// Usuwa slot z chmury.
  Future<void> deleteCloudSlot(String slotKey) async {
    await adapter.transport.deleteSlot(slotKey);
    await refreshCloudSlots();
  }

  /// Zmienia symulowaną/aktywną platformę bieżącego urządzenia (PC / Mac / Mobile).
  void switchLocalDevicePlatform(CrossSaveDevicePlatform platform) {
    final updated = state.currentDevice.copyWith(
      deviceId: 'dev_local_${platform.shortCode.toLowerCase()}',
      deviceName: 'Urządzenie ${platform.labelPl}',
      platform: platform,
      lastSeenAt: DateTime.now().toUtc(),
      isCurrentDevice: true,
    );
    state = state.copyWith(currentDevice: updated);
  }

  void setTransferChannel(CrossSaveTransferChannel channel) {
    state = state.copyWith(selectedChannel: channel);
  }

  void setCompressionLevel(int level) {
    state = state.copyWith(gzipCompressionLevel: level.clamp(1, 9));
  }

  void toggleAutoSync(bool enabled) {
    state = state.copyWith(autoSyncOnSave: enabled);
  }

  void clearError() {
    state = state.copyWith(
      clearError: true,
      status: CrossSaveSyncStatus.idle,
    );
  }
}

/// Główny provider Riverpod dla systemu Cloud Cross-Save JSON + GZIP.
final cloudCrossSaveSyncProvider = StateNotifierProvider<
    CloudCrossSaveSyncNotifier, CloudCrossSaveSyncState>((ref) {
  return CloudCrossSaveSyncNotifier();
});

/// Produkcyjny panel UI synchronizacji Cross-Save (PC <-> Mac <-> Mobile) z kompresją GZIP.
class CloudCrossSaveJsonSyncPanel extends ConsumerStatefulWidget {
  final VoidCallback? onUploadDemoSave;

  const CloudCrossSaveJsonSyncPanel({
    super.key,
    this.onUploadDemoSave,
  });

  @override
  ConsumerState<CloudCrossSaveJsonSyncPanel> createState() =>
      _CloudCrossSaveJsonSyncPanelState();
}

class _CloudCrossSaveJsonSyncPanelState
    extends ConsumerState<CloudCrossSaveJsonSyncPanel> {
  final TextEditingController _tokenImportController = TextEditingController();
  bool _tokenInputFocused = false;

  @override
  void dispose() {
    _tokenImportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cloudCrossSaveSyncProvider);
    final notifier = ref.read(cloudCrossSaveSyncProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isCompact = constraints.maxWidth < 680;
          final bool isWideDesktop = constraints.maxWidth >= 1150;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(state, notifier, isCompact),
                const SizedBox(height: 16),
                if (state.pendingConflict != null) ...[
                  _buildConflictBanner(state.pendingConflict!, notifier, isCompact),
                  const SizedBox(height: 16),
                ],
                if (state.errorMessage != null) ...[
                  _buildErrorBanner(state.errorMessage!, notifier),
                  const SizedBox(height: 16),
                ],
                _buildDeviceBridgeCard(state, notifier, isCompact),
                const SizedBox(height: 16),
                if (isWideDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildCloudSlotsCard(state, notifier, isCompact),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _buildPortableTokenCard(state, notifier, isCompact),
                            const SizedBox(height: 16),
                            _buildHistoryCard(state),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildCloudSlotsCard(state, notifier, isCompact),
                  const SizedBox(height: 16),
                  _buildPortableTokenCard(state, notifier, isCompact),
                  const SizedBox(height: 16),
                  _buildHistoryCard(state),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    CloudCrossSaveSyncState state,
    CloudCrossSaveSyncNotifier notifier,
    bool isCompact,
  ) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryAccent.withValues(alpha: 0.6),
                      ),
                    ),
                    child: const Icon(
                      Icons.cloud_sync_rounded,
                      color: AppColors.goldAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CROSS-SAVE JSON & GZIP SYNC',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: isCompact ? 15 : 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Kompresja GZIP i transfer zapisów PC ↔ Mac ↔ Mobile',
                          style: TextStyle(
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: state.status.badgeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: state.status.badgeColor.withValues(alpha: 0.55),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: state.status.badgeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.status.labelPl,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: state.status.badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _TelemetryMetricChip(
                label: 'ZAPISY W CHMURZE',
                value: '${state.cloudSlots.length}',
                accent: AppColors.accentBlue,
              ),
              _TelemetryMetricChip(
                label: 'ROZMIAR RAW',
                value: _formatBytes(state.totalUncompressedBytes),
                accent: AppColors.textSecondary,
              ),
              _TelemetryMetricChip(
                label: 'PO KOMPRESJI GZIP',
                value: _formatBytes(state.totalCompressedBytes),
                accent: AppColors.statusSuccess,
              ),
              _TelemetryMetricChip(
                label: 'OSZCZĘDNOŚĆ TRANSFERU',
                value: '${state.averageBandwidthSavedPercent.toStringAsFixed(1)}%',
                accent: AppColors.goldAccent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InteractiveActionButton(
                label: 'Wyślij bieżący zapis',
                icon: Icons.cloud_upload_rounded,
                isPrimary: true,
                onPressed: () {
                  if (widget.onUploadDemoSave != null) {
                    widget.onUploadDemoSave!();
                  } else {
                    notifier.syncUploadSaveJson(
                      slotKey: 'slot_1',
                      saveJson: _buildSampleCareerJson(state.currentDevice),
                    );
                  }
                },
              ),
              _InteractiveActionButton(
                label: 'Odśwież chmurę',
                icon: Icons.refresh_rounded,
                onPressed: notifier.refreshCloudSlots,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Poziom GZIP:',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  for (final lvl in [1, 6, 9]) ...[
                    _SelectablePill(
                      label: 'L$lvl',
                      selected: state.gzipCompressionLevel == lvl,
                      onTap: () => notifier.setCompressionLevel(lvl),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceBridgeCard(
    CloudCrossSaveSyncState state,
    CloudCrossSaveSyncNotifier notifier,
    bool isCompact,
  ) {
    final platforms = [
      CrossSaveDevicePlatform.pcWindows,
      CrossSaveDevicePlatform.macOs,
      CrossSaveDevicePlatform.mobileIos,
      CrossSaveDevicePlatform.mobileAndroid,
    ];

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AKTYWNA PLATFORMA I MOST URZĄDZEŃ',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final p in platforms)
                _PlatformSelectorTile(
                  platform: p,
                  isActive: state.currentDevice.platform == p,
                  onTap: () => notifier.switchLocalDevicePlatform(p),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCloudSlotsCard(
    CloudCrossSaveSyncState state,
    CloudCrossSaveSyncNotifier notifier,
    bool isCompact,
  ) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'SLOTY W CHMURZE (GZIP + FNV-1a64)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${state.cloudSlots.length} aktywne',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.accentBlue,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.cloudSlots.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Center(
                child: Text(
                  'Brak zapisów w chmurze. Wyślij zapis z PC, Mac lub Mobile, aby rozpocząć synchronizację.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                for (final slot in state.cloudSlots) ...[
                  _CloudSlotRow(
                    record: slot,
                    isCompact: isCompact,
                    onDownload: () =>
                        notifier.syncDownloadSaveJson(slot.slotKey),
                    onGenerateToken: () =>
                        notifier.generatePortableTokenForSlot(slot.slotKey),
                    onDelete: () => notifier.deleteCloudSlot(slot.slotKey),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPortableTokenCard(
    CloudCrossSaveSyncState state,
    CloudCrossSaveSyncNotifier notifier,
    bool isCompact,
  ) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRANSFER PRZENOŚNY (TOKEN GZIP)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Wklej token PPMCS1:... wygenerowany na innym urządzeniu lub skopiuj własny.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Focus(
            onFocusChange: (focused) {
              setState(() => _tokenInputFocused = focused);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _tokenInputFocused
                      ? AppColors.goldAccent
                      : AppColors.cardBorder,
                  width: _tokenInputFocused ? 1.5 : 1.0,
                ),
              ),
              child: TextField(
                controller: _tokenImportController,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'PPMCS1:H4sIAAAAAAAA...',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InteractiveActionButton(
                label: 'Importuj token',
                icon: Icons.download_done_rounded,
                isPrimary: true,
                onPressed: _tokenImportController.text.trim().isEmpty
                    ? null
                    : () async {
                        await notifier.importPortableToken(
                          token: _tokenImportController.text,
                        );
                        _tokenImportController.clear();
                      },
              ),
              if (state.lastGeneratedToken != null)
                _InteractiveActionButton(
                  label: 'Kopiuj ostatni token',
                  icon: Icons.copy_rounded,
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: state.lastGeneratedToken!),
                    );
                  },
                ),
            ],
          ),
          if (state.lastGeneratedToken != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                state.lastGeneratedToken!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.cyanAccent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryCard(CloudCrossSaveSyncState state) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DZIENNIK TRANSFERÓW',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          if (state.syncHistory.isEmpty)
            const Text(
              'Brak zarejestrowanych transferów w bieżącej sesji.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            Column(
              children: [
                for (final entry in state.syncHistory.take(5)) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          entry.direction == CrossSaveSyncDirection.uploadToCloud
                              ? Icons.north_east_rounded
                              : Icons.south_west_rounded,
                          size: 16,
                          color: entry.success
                              ? AppColors.statusSuccess
                              : AppColors.crimsonAlert,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.saveName} • ${entry.sourcePlatform.shortCode}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                entry.summaryPl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildConflictBanner(
    CrossSaveConflictReport conflict,
    CloudCrossSaveSyncNotifier notifier,
    bool isCompact,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amberWarning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.amberWarning.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.amberWarning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Konflikt wersji zapisu: ${conflict.saveName}',
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
            conflict.summaryPl,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InteractiveActionButton(
                label: 'Zachowaj lokalny (${conflict.localDevice.platform.shortCode})',
                icon: Icons.upload_rounded,
                isPrimary: true,
                onPressed: () => notifier.resolvePendingConflict(
                  CrossSaveConflictResolutionStrategy.preferLocalDevice,
                ),
              ),
              _InteractiveActionButton(
                label: 'Pobierz z chmury (${conflict.remoteDevice.platform.shortCode})',
                icon: Icons.download_rounded,
                onPressed: () => notifier.resolvePendingConflict(
                  CrossSaveConflictResolutionStrategy.preferCloudRemote,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(
    String message,
    CloudCrossSaveSyncNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.crimsonAlert.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.crimsonAlert.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.crimsonAlert,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: notifier.clearError,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  static Map<String, dynamic> _buildSampleCareerJson(
    CrossSaveDeviceProfile device,
  ) {
    return {
      'id': 'career_cross_slot_1',
      'saveName': 'Alpejskie Imperium WT',
      'playerManagerName': 'Dyrektor Sportowy',
      'playerTeamId': 'team_pl_wt',
      'playerTeamName': 'Polska Ekipa WorldTour',
      'currentSeasonYear': 2027,
      'currentDate': DateTime.now().toUtc().toIso8601String(),
      'lastSavedAt': DateTime.now().toUtc().toIso8601String(),
      'sourceDevice': device.platform.shortCode,
    };
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class _PanelCard extends StatelessWidget {
  final Widget child;

  const _PanelCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: child,
    );
  }
}

class _TelemetryMetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _TelemetryMetricChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
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
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
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
    final bool enabled = widget.onPressed != null;
    final Color baseBg = widget.isPrimary
        ? AppColors.primaryAccent
        : AppColors.surfaceLight;
    final Color bg = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _pressed
            ? baseBg.withValues(alpha: 0.75)
            : _hovered
                ? baseBg.withValues(alpha: 0.9)
                : baseBg;

    final Color borderColor = !enabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : _focused
            ? AppColors.goldAccent
            : widget.isPrimary
                ? AppColors.goldAccent.withValues(alpha: 0.55)
                : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      onShowHoverHighlight: (h) => setState(() => _hovered = h),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectablePill extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectablePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SelectablePill> createState() => _SelectablePillState();
}

class _SelectablePillState extends State<_SelectablePill> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (h) => setState(() => _hovered = h),
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.goldAccent.withValues(alpha: 0.2)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused || widget.selected
                  ? AppColors.goldAccent
                  : AppColors.cardBorder,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
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

class _PlatformSelectorTile extends StatefulWidget {
  final CrossSaveDevicePlatform platform;
  final bool isActive;
  final VoidCallback onTap;

  const _PlatformSelectorTile({
    required this.platform,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_PlatformSelectorTile> createState() => _PlatformSelectorTileState();
}

class _PlatformSelectorTileState extends State<_PlatformSelectorTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (h) => setState(() => _hovered = h),
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.accentBlue.withValues(alpha: 0.16)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : widget.isActive
                      ? AppColors.accentBlue
                      : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.platform.icon,
                size: 17,
                color: widget.isActive
                    ? AppColors.accentBlue
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.platform.labelPl,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight:
                      widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isActive
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

class _CloudSlotRow extends StatelessWidget {
  final CrossSaveCloudSlotRecord record;
  final bool isCompact;
  final VoidCallback onDownload;
  final VoidCallback onGenerateToken;
  final VoidCallback onDelete;

  const _CloudSlotRow({
    required this.record,
    required this.isCompact,
    required this.onDownload,
    required this.onGenerateToken,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final meta = record.metadata;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    meta.sourcePlatform.icon,
                    size: 18,
                    color: AppColors.goldAccent,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${meta.saveName} (rev.${record.revisionNumber})',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${meta.teamName} • Sezon ${meta.seasonYear} • ${meta.sourcePlatform.shortCode}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccess.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'GZIP -${meta.bandwidthSavedPercent.toStringAsFixed(0)}% '
                  '(${meta.compressedBytes} B)',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusSuccess,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InteractiveActionButton(
                label: 'Pobierz',
                icon: Icons.cloud_download_rounded,
                isPrimary: true,
                onPressed: onDownload,
              ),
              _InteractiveActionButton(
                label: 'Token PPMCS1',
                icon: Icons.qr_code_2_rounded,
                onPressed: onGenerateToken,
              ),
              _InteractiveActionButton(
                label: 'Usuń',
                icon: Icons.delete_outline_rounded,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
