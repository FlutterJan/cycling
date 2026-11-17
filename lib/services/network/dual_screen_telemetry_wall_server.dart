import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

/// Protocol version for the Dual-Screen Telemetry Wall WebSocket channel.
const int kDualScreenProtocolVersion = 1;

/// Status of the local WebSocket server.
enum DualScreenServerStatus {
  stopped,
  starting,
  running,
  error,
}

/// Command categories sent from a phone/tablet companion to the PC/Mac host.
enum CompanionCommandType {
  setEffort,
  tacticalOrder,
  teamPreset,
  serviceRequest,
  ping,
}

/// Server lifecycle & diagnostic event types.
enum DualScreenServerEventType {
  serverStarted,
  serverStopped,
  clientConnected,
  clientAuthenticated,
  clientDisconnected,
  commandReceived,
  commandRejected,
  error,
}

/// Telemetry snapshot of a single team rider streamed to the companion wall.
class CompanionRiderTelemetry {
  const CompanionRiderTelemetry({
    required this.riderId,
    required this.riderName,
    required this.bibNumber,
    required this.role,
    required this.watts,
    required this.wPerKg,
    required this.heartRateBpm,
    required this.cadenceRpm,
    required this.wPrimePercent,
    required this.glycogenPercent,
    required this.coreTempC,
    required this.effortPercent,
    required this.tacticalOrder,
    required this.gapToLeaderSec,
    required this.powerZone,
    this.isLeader = false,
  });

  final String riderId;
  final String riderName;
  final int bibNumber;
  final String role;
  final int watts;
  final double wPerKg;
  final int heartRateBpm;
  final int cadenceRpm;
  final double wPrimePercent;
  final double glycogenPercent;
  final double coreTempC;
  final int effortPercent;
  final String tacticalOrder;
  final double gapToLeaderSec;
  final int powerZone;
  final bool isLeader;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'riderId': riderId,
        'riderName': riderName,
        'bibNumber': bibNumber,
        'role': role,
        'watts': watts,
        'wPerKg': wPerKg,
        'heartRateBpm': heartRateBpm,
        'cadenceRpm': cadenceRpm,
        'wPrimePercent': wPrimePercent,
        'glycogenPercent': glycogenPercent,
        'coreTempC': coreTempC,
        'effortPercent': effortPercent,
        'tacticalOrder': tacticalOrder,
        'gapToLeaderSec': gapToLeaderSec,
        'powerZone': powerZone,
        'isLeader': isLeader,
      };

  factory CompanionRiderTelemetry.fromJson(Map<String, dynamic> json) {
    return CompanionRiderTelemetry(
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? 'Rider',
      bibNumber: (json['bibNumber'] as num?)?.toInt() ?? 0,
      role: json['role'] as String? ?? 'Domestique',
      watts: (json['watts'] as num?)?.toInt() ?? 0,
      wPerKg: (json['wPerKg'] as num?)?.toDouble() ?? 0.0,
      heartRateBpm: (json['heartRateBpm'] as num?)?.toInt() ?? 0,
      cadenceRpm: (json['cadenceRpm'] as num?)?.toInt() ?? 0,
      wPrimePercent: (json['wPrimePercent'] as num?)?.toDouble() ?? 100.0,
      glycogenPercent: (json['glycogenPercent'] as num?)?.toDouble() ?? 100.0,
      coreTempC: (json['coreTempC'] as num?)?.toDouble() ?? 37.2,
      effortPercent: (json['effortPercent'] as num?)?.toInt() ?? 70,
      tacticalOrder: json['tacticalOrder'] as String? ?? 'Hold Position',
      gapToLeaderSec: (json['gapToLeaderSec'] as num?)?.toDouble() ?? 0.0,
      powerZone: (json['powerZone'] as num?)?.toInt() ?? 2,
      isLeader: json['isLeader'] as bool? ?? false,
    );
  }
}

/// Group gap snapshot for the peloton monitor.
class CompanionGroupGap {
  const CompanionGroupGap({
    required this.groupName,
    required this.gapSeconds,
    required this.riderCount,
    required this.teamRidersCount,
  });

  final String groupName;
  final double gapSeconds;
  final int riderCount;
  final int teamRidersCount;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'groupName': groupName,
        'gapSeconds': gapSeconds,
        'riderCount': riderCount,
        'teamRidersCount': teamRidersCount,
      };

  factory CompanionGroupGap.fromJson(Map<String, dynamic> json) {
    return CompanionGroupGap(
      groupName: json['groupName'] as String? ?? 'Peloton',
      gapSeconds: (json['gapSeconds'] as num?)?.toDouble() ?? 0.0,
      riderCount: (json['riderCount'] as num?)?.toInt() ?? 0,
      teamRidersCount: (json['teamRidersCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Race radio message streamed to the companion wall.
class CompanionRadioEvent {
  const CompanionRadioEvent({
    required this.id,
    required this.kmMark,
    required this.sender,
    required this.message,
    this.isUrgent = false,
  });

  final String id;
  final double kmMark;
  final String sender;
  final String message;
  final bool isUrgent;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'kmMark': kmMark,
        'sender': sender,
        'message': message,
        'isUrgent': isUrgent,
      };

  factory CompanionRadioEvent.fromJson(Map<String, dynamic> json) {
    return CompanionRadioEvent(
      id: json['id'] as String? ?? '',
      kmMark: (json['kmMark'] as num?)?.toDouble() ?? 0.0,
      sender: json['sender'] as String? ?? 'Race Radio',
      message: json['message'] as String? ?? '',
      isUrgent: json['isUrgent'] as bool? ?? false,
    );
  }
}

/// Team car logistics & commissaire barrage status.
class CompanionServiceStatus {
  const CompanionServiceStatus({
    required this.teamCarGapSeconds,
    required this.barrageActive,
    required this.bottlesRemaining,
    required this.gelsRemaining,
    required this.iceSocksRemaining,
    required this.spareBikesRemaining,
  });

  final double teamCarGapSeconds;
  final bool barrageActive;
  final int bottlesRemaining;
  final int gelsRemaining;
  final int iceSocksRemaining;
  final int spareBikesRemaining;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'teamCarGapSeconds': teamCarGapSeconds,
        'barrageActive': barrageActive,
        'bottlesRemaining': bottlesRemaining,
        'gelsRemaining': gelsRemaining,
        'iceSocksRemaining': iceSocksRemaining,
        'spareBikesRemaining': spareBikesRemaining,
      };

  factory CompanionServiceStatus.fromJson(Map<String, dynamic> json) {
    return CompanionServiceStatus(
      teamCarGapSeconds: (json['teamCarGapSeconds'] as num?)?.toDouble() ?? 15.0,
      barrageActive: json['barrageActive'] as bool? ?? false,
      bottlesRemaining: (json['bottlesRemaining'] as num?)?.toInt() ?? 40,
      gelsRemaining: (json['gelsRemaining'] as num?)?.toInt() ?? 32,
      iceSocksRemaining: (json['iceSocksRemaining'] as num?)?.toInt() ?? 12,
      spareBikesRemaining: (json['spareBikesRemaining'] as num?)?.toInt() ?? 6,
    );
  }
}

/// Full telemetry frame broadcast by [DualScreenTelemetryWallServer] at up to 2–5 Hz.
class TelemetryWallFrame {
  const TelemetryWallFrame({
    required this.sequence,
    required this.timestampMs,
    required this.stageName,
    required this.kmCompleted,
    required this.totalKm,
    required this.pelotonSpeedKmh,
    required this.windSpeedKmh,
    required this.windDirectionDeg,
    required this.temperatureC,
    required this.weatherLabel,
    required this.riders,
    required this.groupGaps,
    required this.radioFeed,
    required this.serviceStatus,
  });

  final int sequence;
  final int timestampMs;
  final String stageName;
  final double kmCompleted;
  final double totalKm;
  final double pelotonSpeedKmh;
  final double windSpeedKmh;
  final double windDirectionDeg;
  final double temperatureC;
  final String weatherLabel;
  final List<CompanionRiderTelemetry> riders;
  final List<CompanionGroupGap> groupGaps;
  final List<CompanionRadioEvent> radioFeed;
  final CompanionServiceStatus serviceStatus;

  double get kmRemaining => math.max(0.0, totalKm - kmCompleted);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'telemetry_frame',
        'protocolVersion': kDualScreenProtocolVersion,
        'sequence': sequence,
        'timestampMs': timestampMs,
        'stageName': stageName,
        'kmCompleted': kmCompleted,
        'totalKm': totalKm,
        'pelotonSpeedKmh': pelotonSpeedKmh,
        'windSpeedKmh': windSpeedKmh,
        'windDirectionDeg': windDirectionDeg,
        'temperatureC': temperatureC,
        'weatherLabel': weatherLabel,
        'riders': riders.map((r) => r.toJson()).toList(),
        'groupGaps': groupGaps.map((g) => g.toJson()).toList(),
        'radioFeed': radioFeed.map((e) => e.toJson()).toList(),
        'serviceStatus': serviceStatus.toJson(),
      };

  factory TelemetryWallFrame.fromJson(Map<String, dynamic> json) {
    final ridersList = (json['riders'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(CompanionRiderTelemetry.fromJson)
        .toList();
    final gapsList = (json['groupGaps'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(CompanionGroupGap.fromJson)
        .toList();
    final radioList = (json['radioFeed'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(CompanionRadioEvent.fromJson)
        .toList();
    final serviceMap = json['serviceStatus'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return TelemetryWallFrame(
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      timestampMs: (json['timestampMs'] as num?)?.toInt() ?? 0,
      stageName: json['stageName'] as String? ?? 'Stage 1',
      kmCompleted: (json['kmCompleted'] as num?)?.toDouble() ?? 0.0,
      totalKm: (json['totalKm'] as num?)?.toDouble() ?? 180.0,
      pelotonSpeedKmh: (json['pelotonSpeedKmh'] as num?)?.toDouble() ?? 42.0,
      windSpeedKmh: (json['windSpeedKmh'] as num?)?.toDouble() ?? 12.0,
      windDirectionDeg: (json['windDirectionDeg'] as num?)?.toDouble() ?? 0.0,
      temperatureC: (json['temperatureC'] as num?)?.toDouble() ?? 21.0,
      weatherLabel: json['weatherLabel'] as String? ?? 'Clear',
      riders: ridersList,
      groupGaps: gapsList,
      radioFeed: radioList,
      serviceStatus: CompanionServiceStatus.fromJson(serviceMap),
    );
  }
}

/// Command sent from the companion tablet/phone to the host game simulation.
class CompanionCarCommand {
  const CompanionCarCommand({
    required this.commandId,
    required this.type,
    required this.clientId,
    required this.issuedAtMs,
    this.riderId,
    this.effortPercent,
    this.orderName,
    this.presetName,
    this.serviceType,
  });

  final String commandId;
  final CompanionCommandType type;
  final String clientId;
  final int issuedAtMs;
  final String? riderId;
  final int? effortPercent;
  final String? orderName;
  final String? presetName;
  final String? serviceType;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'companion_command',
        'protocolVersion': kDualScreenProtocolVersion,
        'commandId': commandId,
        'commandType': type.name,
        'clientId': clientId,
        'issuedAtMs': issuedAtMs,
        if (riderId != null) 'riderId': riderId,
        if (effortPercent != null) 'effortPercent': effortPercent,
        if (orderName != null) 'orderName': orderName,
        if (presetName != null) 'presetName': presetName,
        if (serviceType != null) 'serviceType': serviceType,
      };

  factory CompanionCarCommand.fromJson(Map<String, dynamic> json) {
    final typeName = json['commandType'] as String? ?? 'ping';
    final resolvedType = CompanionCommandType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => CompanionCommandType.ping,
    );
    return CompanionCarCommand(
      commandId: json['commandId'] as String? ?? '',
      type: resolvedType,
      clientId: json['clientId'] as String? ?? 'unknown',
      issuedAtMs: (json['issuedAtMs'] as num?)?.toInt() ?? 0,
      riderId: json['riderId'] as String?,
      effortPercent: (json['effortPercent'] as num?)?.toInt(),
      orderName: json['orderName'] as String?,
      presetName: json['presetName'] as String?,
      serviceType: json['serviceType'] as String?,
    );
  }
}

/// Metadata of a connected phone/tablet companion device.
class ConnectedCompanionDevice {
  const ConnectedCompanionDevice({
    required this.clientId,
    required this.deviceName,
    required this.platform,
    required this.remoteAddress,
    required this.connectedAt,
    required this.lastSeenAt,
    required this.authenticated,
    this.rttMs = 0,
    this.commandsSent = 0,
  });

  final String clientId;
  final String deviceName;
  final String platform;
  final String remoteAddress;
  final DateTime connectedAt;
  final DateTime lastSeenAt;
  final bool authenticated;
  final int rttMs;
  final int commandsSent;

  ConnectedCompanionDevice copyWith({
    String? deviceName,
    String? platform,
    DateTime? lastSeenAt,
    bool? authenticated,
    int? rttMs,
    int? commandsSent,
  }) {
    return ConnectedCompanionDevice(
      clientId: clientId,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      remoteAddress: remoteAddress,
      connectedAt: connectedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      authenticated: authenticated ?? this.authenticated,
      rttMs: rttMs ?? this.rttMs,
      commandsSent: commandsSent ?? this.commandsSent,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'clientId': clientId,
        'deviceName': deviceName,
        'platform': platform,
        'remoteAddress': remoteAddress,
        'connectedAt': connectedAt.toIso8601String(),
        'lastSeenAt': lastSeenAt.toIso8601String(),
        'authenticated': authenticated,
        'rttMs': rttMs,
        'commandsSent': commandsSent,
      };
}

/// Event emitted by the server for diagnostics and UI logging.
class DualScreenServerEvent {
  const DualScreenServerEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    this.clientId,
  });

  final DualScreenServerEventType type;
  final String message;
  final DateTime timestamp;
  final String? clientId;
}

class _ClientSession {
  _ClientSession({
    required this.socket,
    required this.device,
  });

  final WebSocket socket;
  ConnectedCompanionDevice device;
  StreamSubscription<dynamic>? subscription;
}

/// Local HTTP + WebSocket server allowing a phone or tablet on the same LAN
/// to operate as a Team Car Dual-Screen Telemetry Wall during PC/Mac races.
class DualScreenTelemetryWallServer {
  DualScreenTelemetryWallServer({
    this.maxClients = 4,
    this.requirePairingPin = true,
  });

  final int maxClients;
  final bool requirePairingPin;

  HttpServer? _httpServer;
  final Map<String, _ClientSession> _clients = <String, _ClientSession>{};
  final StreamController<CompanionCarCommand> _commandController =
      StreamController<CompanionCarCommand>.broadcast();
  final StreamController<DualScreenServerEvent> _eventController =
      StreamController<DualScreenServerEvent>.broadcast();

  DualScreenServerStatus _status = DualScreenServerStatus.stopped;
  String _pairingPin = '';
  String _boundAddress = '127.0.0.1';
  List<String> _lanAddresses = const <String>[];
  int _boundPort = 0;
  int _framesBroadcastCount = 0;
  int _commandsProcessedCount = 0;
  TelemetryWallFrame? _latestFrame;
  bool _disposed = false;

  DualScreenServerStatus get status => _status;
  String get pairingPin => _pairingPin;
  String get boundAddress => _boundAddress;
  List<String> get lanAddresses => List<String>.unmodifiable(_lanAddresses);
  int get boundPort => _boundPort;
  int get framesBroadcastCount => _framesBroadcastCount;
  int get commandsProcessedCount => _commandsProcessedCount;
  TelemetryWallFrame? get latestFrame => _latestFrame;

  List<ConnectedCompanionDevice> get connectedDevices =>
      _clients.values.map((s) => s.device).toList(growable: false);

  Stream<CompanionCarCommand> get commandStream => _commandController.stream;
  Stream<DualScreenServerEvent> get eventStream => _eventController.stream;

  /// Primary WebSocket pairing URL for QR code or manual entry on tablet/phone.
  String get primaryWebSocketUrl {
    final host = _lanAddresses.isNotEmpty ? _lanAddresses.first : _boundAddress;
    if (_boundPort <= 0) return '';
    final pinQuery = requirePairingPin ? '?pin=$_pairingPin' : '';
    return 'ws://$host:$_boundPort/ws$pinQuery';
  }

  /// Primary HTTP URL for opening the built-in HTML5 companion wall in a mobile browser.
  String get primaryWebDashboardUrl {
    final host = _lanAddresses.isNotEmpty ? _lanAddresses.first : _boundAddress;
    if (_boundPort <= 0) return '';
    final pinQuery = requirePairingPin ? '?pin=$_pairingPin' : '';
    return 'http://$host:$_boundPort/$pinQuery';
  }

  /// Starts the local HTTP + WebSocket server.
  /// Pass [port] = 0 to let the OS assign an ephemeral free port (ideal for tests).
  Future<void> start({
    String bindAddress = '0.0.0.0',
    int port = 8765,
    String? customPin,
  }) async {
    if (_disposed) {
      throw StateError('DualScreenTelemetryWallServer has been disposed.');
    }
    if (_status == DualScreenServerStatus.running ||
        _status == DualScreenServerStatus.starting) {
      return;
    }

    _status = DualScreenServerStatus.starting;
    _pairingPin = _sanitizeOrGeneratePin(customPin);

    try {
      final address = InternetAddress(bindAddress);
      _httpServer = await HttpServer.bind(address, port, shared: false);
      _boundPort = _httpServer!.port;
      _boundAddress = bindAddress == '0.0.0.0' ? '127.0.0.1' : bindAddress;
      _lanAddresses = await _discoverLanIpv4Addresses();

      _httpServer!.listen(
        _handleHttpRequest,
        onError: (Object error) {
          _emitEvent(
            DualScreenServerEventType.error,
            'HTTP listener error: $error',
          );
        },
      );

      _status = DualScreenServerStatus.running;
      _emitEvent(
        DualScreenServerEventType.serverStarted,
        'Telemetry Wall server listening on $_boundAddress:$_boundPort (PIN: $_pairingPin)',
      );
    } catch (e) {
      _status = DualScreenServerStatus.error;
      _emitEvent(
        DualScreenServerEventType.error,
        'Failed to start server on $bindAddress:$port — $e',
      );
      rethrow;
    }
  }

  /// Stops the server and closes all active companion WebSocket sessions.
  Future<void> stop() async {
    if (_status == DualScreenServerStatus.stopped && _httpServer == null) {
      return;
    }

    final sessions = _clients.values.toList(growable: false);
    _clients.clear();
    for (final session in sessions) {
      await session.subscription?.cancel();
      try {
        await session.socket.close(WebSocketStatus.goingAway, 'Server stopping');
      } catch (_) {
        // Ignore socket close errors during shutdown.
      }
    }

    try {
      await _httpServer?.close(force: true);
    } catch (_) {
      // Ignore server close errors during shutdown.
    }
    _httpServer = null;
    _boundPort = 0;
    _status = DualScreenServerStatus.stopped;
    _emitEvent(
      DualScreenServerEventType.serverStopped,
      'Telemetry Wall server stopped.',
    );
  }

  /// Regenerates the 6-digit pairing PIN and disconnects unauthenticated clients.
  String regeneratePairingPin() {
    _pairingPin = _sanitizeOrGeneratePin(null);
    return _pairingPin;
  }

  /// Broadcasts a [TelemetryWallFrame] to all authenticated companion clients.
  int broadcastTelemetryFrame(TelemetryWallFrame frame) {
    _latestFrame = frame;
    if (_status != DualScreenServerStatus.running || _clients.isEmpty) {
      return 0;
    }

    final payload = jsonEncode(frame.toJson());
    var delivered = 0;
    final deadClients = <String>[];

    for (final entry in _clients.entries) {
      final session = entry.value;
      if (!session.device.authenticated) continue;
      if (session.socket.readyState != WebSocket.open) {
        deadClients.add(entry.key);
        continue;
      }
      try {
        session.socket.add(payload);
        delivered++;
      } catch (_) {
        deadClients.add(entry.key);
      }
    }

    for (final id in deadClients) {
      _removeClient(id, 'Socket write failed');
    }

    if (delivered > 0) {
      _framesBroadcastCount++;
    }
    return delivered;
  }

  /// Disconnects a specific companion device by [clientId].
  Future<void> disconnectClient(String clientId) async {
    final session = _clients.remove(clientId);
    if (session == null) return;
    await session.subscription?.cancel();
    try {
      await session.socket.close(WebSocketStatus.normalClosure, 'Disconnected by host');
    } catch (_) {}
    _emitEvent(
      DualScreenServerEventType.clientDisconnected,
      'Disconnected ${session.device.deviceName}',
      clientId: clientId,
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
    await _commandController.close();
    await _eventController.close();
  }

  Future<void> _handleHttpRequest(HttpRequest request) async {
    final path = request.uri.path;

    if (path == '/ws' && WebSocketTransformer.isUpgradeRequest(request)) {
      await _handleWebSocketUpgrade(request);
      return;
    }

    if (path == '/health') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode(<String, dynamic>{
            'status': _status.name,
            'protocolVersion': kDualScreenProtocolVersion,
            'port': _boundPort,
            'connectedClients': _clients.length,
            'framesBroadcast': _framesBroadcastCount,
          }),
        );
      await request.response.close();
      return;
    }

    if (path == '/' || path == '/index.html') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(_buildEmbeddedCompanionHtml());
      await request.response.close();
      return;
    }

    request.response
      ..statusCode = HttpStatus.notFound
      ..write('Not Found');
    await request.response.close();
  }

  Future<void> _handleWebSocketUpgrade(HttpRequest request) async {
    if (_clients.length >= maxClients) {
      request.response
        ..statusCode = HttpStatus.serviceUnavailable
        ..write('Maximum companion devices ($maxClients) reached.');
      await request.response.close();
      return;
    }

    final queryPin = request.uri.queryParameters['pin'] ?? '';
    final deviceName = request.uri.queryParameters['device'] ?? 'Team Car Tablet';
    final platform = request.uri.queryParameters['platform'] ?? 'Mobile';
    final isPreAuthed = !requirePairingPin || queryPin == _pairingPin;

    final socket = await WebSocketTransformer.upgrade(request);
    final clientId = 'comp_${DateTime.now().microsecondsSinceEpoch}_${_clients.length + 1}';
    final remoteAddr = request.connectionInfo?.remoteAddress.address ?? 'unknown';
    final now = DateTime.now();

    final session = _ClientSession(
      socket: socket,
      device: ConnectedCompanionDevice(
        clientId: clientId,
        deviceName: deviceName,
        platform: platform,
        remoteAddress: remoteAddr,
        connectedAt: now,
        lastSeenAt: now,
        authenticated: isPreAuthed,
      ),
    );
    _clients[clientId] = session;

    _emitEvent(
      DualScreenServerEventType.clientConnected,
      'Companion connected from $remoteAddr ($deviceName)',
      clientId: clientId,
    );

    if (isPreAuthed) {
      _sendHandshakeWelcome(session);
    } else {
      socket.add(
        jsonEncode(<String, dynamic>{
          'type': 'auth_required',
          'protocolVersion': kDualScreenProtocolVersion,
          'clientId': clientId,
        }),
      );
    }

    session.subscription = socket.listen(
      (dynamic data) => _handleClientMessage(clientId, data),
      onDone: () => _removeClient(clientId, 'Client closed connection'),
      onError: (Object error) => _removeClient(clientId, 'Socket error: $error'),
    );
  }

  void _sendHandshakeWelcome(_ClientSession session) {
    if (session.socket.readyState != WebSocket.open) return;
    session.socket.add(
      jsonEncode(<String, dynamic>{
        'type': 'welcome',
        'protocolVersion': kDualScreenProtocolVersion,
        'clientId': session.device.clientId,
        'serverTimeMs': DateTime.now().millisecondsSinceEpoch,
      }),
    );
    if (_latestFrame != null) {
      session.socket.add(jsonEncode(_latestFrame!.toJson()));
    }
    _emitEvent(
      DualScreenServerEventType.clientAuthenticated,
      'Authenticated ${session.device.deviceName}',
      clientId: session.device.clientId,
    );
  }

  void _handleClientMessage(String clientId, dynamic rawData) {
    final session = _clients[clientId];
    if (session == null) return;

    if (rawData is! String) {
      _emitEvent(
        DualScreenServerEventType.commandRejected,
        'Rejected non-text WebSocket frame from $clientId',
        clientId: clientId,
      );
      return;
    }

    Map<String, dynamic> decoded;
    try {
      final parsed = jsonDecode(rawData);
      if (parsed is! Map<String, dynamic>) {
        throw const FormatException('Root payload must be a JSON object');
      }
      decoded = parsed;
    } catch (e) {
      _emitEvent(
        DualScreenServerEventType.commandRejected,
        'Malformed JSON from $clientId: $e',
        clientId: clientId,
      );
      return;
    }

    final msgType = decoded['type'] as String? ?? '';
    final now = DateTime.now();

    if (msgType == 'auth') {
      final pin = decoded['pin'] as String? ?? '';
      final deviceName = decoded['deviceName'] as String?;
      final platform = decoded['platform'] as String?;
      if (!requirePairingPin || pin == _pairingPin) {
        session.device = session.device.copyWith(
          authenticated: true,
          deviceName: deviceName,
          platform: platform,
          lastSeenAt: now,
        );
        _sendHandshakeWelcome(session);
      } else {
        session.socket.add(
          jsonEncode(<String, dynamic>{
            'type': 'auth_failed',
            'reason': 'Invalid pairing PIN',
          }),
        );
        _emitEvent(
          DualScreenServerEventType.commandRejected,
          'Invalid pairing PIN from $clientId',
          clientId: clientId,
        );
      }
      return;
    }

    if (!session.device.authenticated) {
      session.socket.add(
        jsonEncode(<String, dynamic>{
          'type': 'auth_required',
          'reason': 'Authenticate before sending commands',
        }),
      );
      return;
    }

    if (msgType == 'ping') {
      final clientTs = (decoded['timestampMs'] as num?)?.toInt() ?? 0;
      final rtt = clientTs > 0
          ? math.max(0, now.millisecondsSinceEpoch - clientTs)
          : session.device.rttMs;
      session.device = session.device.copyWith(lastSeenAt: now, rttMs: rtt);
      session.socket.add(
        jsonEncode(<String, dynamic>{
          'type': 'pong',
          'clientTimestampMs': clientTs,
          'serverTimestampMs': now.millisecondsSinceEpoch,
        }),
      );
      return;
    }

    if (msgType == 'companion_command') {
      final command = CompanionCarCommand.fromJson(
        <String, dynamic>{
          ...decoded,
          'clientId': clientId,
        },
      );

      if (!_validateCommand(command)) {
        _emitEvent(
          DualScreenServerEventType.commandRejected,
          'Invalid command parameters (${command.type.name}) from $clientId',
          clientId: clientId,
        );
        return;
      }

      session.device = session.device.copyWith(
        lastSeenAt: now,
        commandsSent: session.device.commandsSent + 1,
      );
      _commandsProcessedCount++;
      if (!_commandController.isClosed) {
        _commandController.add(command);
      }

      session.socket.add(
        jsonEncode(<String, dynamic>{
          'type': 'command_ack',
          'commandId': command.commandId,
          'status': 'accepted',
        }),
      );
      _emitEvent(
        DualScreenServerEventType.commandReceived,
        'Command ${command.type.name} from ${session.device.deviceName}',
        clientId: clientId,
      );
    }
  }

  bool _validateCommand(CompanionCarCommand command) {
    switch (command.type) {
      case CompanionCommandType.setEffort:
        final effort = command.effortPercent;
        return (command.riderId?.isNotEmpty ?? false) &&
            effort != null &&
            effort >= 10 &&
            effort <= 100;
      case CompanionCommandType.tacticalOrder:
        return (command.riderId?.isNotEmpty ?? false) &&
            (command.orderName?.isNotEmpty ?? false);
      case CompanionCommandType.teamPreset:
        return command.presetName?.isNotEmpty ?? false;
      case CompanionCommandType.serviceRequest:
        return (command.riderId?.isNotEmpty ?? false) &&
            (command.serviceType?.isNotEmpty ?? false);
      case CompanionCommandType.ping:
        return true;
    }
  }

  void _removeClient(String clientId, String reason) {
    final session = _clients.remove(clientId);
    if (session == null) return;
    unawaited(session.subscription?.cancel());
    _emitEvent(
      DualScreenServerEventType.clientDisconnected,
      '${session.device.deviceName} disconnected ($reason)',
      clientId: clientId,
    );
  }

  void _emitEvent(
    DualScreenServerEventType type,
    String message, {
    String? clientId,
  }) {
    if (_eventController.isClosed) return;
    _eventController.add(
      DualScreenServerEvent(
        type: type,
        message: message,
        timestamp: DateTime.now(),
        clientId: clientId,
      ),
    );
  }

  String _sanitizeOrGeneratePin(String? customPin) {
    if (customPin != null && RegExp(r'^\d{6}$').hasMatch(customPin)) {
      return customPin;
    }
    final rng = math.Random();
    return (100000 + rng.nextInt(900000)).toString();
  }

  Future<List<String>> _discoverLanIpv4Addresses() async {
    final results = <String>[];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && !addr.address.startsWith('169.254.')) {
            results.add(addr.address);
          }
        }
      }
    } catch (_) {
      // Fallback to loopback if network enumeration is restricted.
    }
    if (results.isEmpty) {
      results.add('127.0.0.1');
    }
    return results;
  }

  String _buildEmbeddedCompanionHtml() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1" />
<title>Pro Peloton Manager — Team Car Telemetry Wall</title>
<style>
  body { margin:0; font-family:Inter,system-ui,sans-serif; background:#0F1115; color:#F3F4F6; padding:16px; }
  .card { background:#181B22; border:1px solid #2A2F3D; border-radius:16px; padding:16px; margin-bottom:12px; }
  .gold { color:#D4AF37; font-weight:700; }
  .mono { font-variant-numeric:tabular-nums; }
  .grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(260px,1fr)); gap:12px; }
  button { background:#8E4A49; color:#F3F4F6; border:1px solid #D4AF37; border-radius:8px; padding:8px 12px; cursor:pointer; }
</style>
</head>
<body>
  <div class="card">
    <div class="gold">PRO PELOTON MANAGER // TEAM CAR TELEMETRY WALL</div>
    <div id="stage">Connecting to host WebSocket...</div>
  </div>
  <div id="riders" class="grid"></div>
  <script>
    const params = new URLSearchParams(window.location.search);
    const pin = params.get('pin') || '';
    const ws = new WebSocket((location.protocol === 'https:' ? 'wss://' : 'ws://') + location.host + '/ws?pin=' + encodeURIComponent(pin) + '&device=WebTablet&platform=Browser');
    ws.onmessage = (ev) => {
      const msg = JSON.parse(ev.data);
      if (msg.type === 'telemetry_frame') {
        document.getElementById('stage').innerText = msg.stageName + ' | ' + msg.kmCompleted.toFixed(1) + ' / ' + msg.totalKm.toFixed(1) + ' km | ' + msg.pelotonSpeedKmh.toFixed(1) + ' km/h';
        document.getElementById('riders').innerHTML = (msg.riders || []).map(r =>
          '<div class="card"><div><b>#' + r.bibNumber + ' ' + r.riderName + '</b></div>' +
          '<div class="mono">' + r.watts + ' W (' + r.wPerKg.toFixed(2) + ' W/kg) | ' + r.heartRateBpm + ' BPM | Effort ' + r.effortPercent + '%</div>' +
          '<div style="margin-top:8px"><button onclick="sendEffort(\\'' + r.riderId + '\\',' + Math.min(100, r.effortPercent + 5) + ')">+5% Effort</button> ' +
          '<button onclick="sendEffort(\\'' + r.riderId + '\\',' + Math.max(10, r.effortPercent - 5) + ')">-5% Effort</button></div></div>'
        ).join('');
      }
    };
    function sendEffort(riderId, effort) {
      ws.send(JSON.stringify({ type:'companion_command', commandId:'cmd_' + Date.now(), commandType:'setEffort', issuedAtMs:Date.now(), riderId:riderId, effortPercent:effort }));
    }
  </script>
</body>
</html>
''';
  }
}

/// Companion-side WebSocket client used by a phone/tablet running the
/// Team Car Dashboard to connect to [DualScreenTelemetryWallServer].
class DualScreenTelemetryWallClient {
  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  final StreamController<TelemetryWallFrame> _frameController =
      StreamController<TelemetryWallFrame>.broadcast();
  final StreamController<Map<String, dynamic>> _ackController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _connected = false;
  bool _authenticated = false;
  String? _clientId;

  bool get isConnected => _connected;
  bool get isAuthenticated => _authenticated;
  String? get clientId => _clientId;
  Stream<TelemetryWallFrame> get frameStream => _frameController.stream;
  Stream<Map<String, dynamic>> get ackStream => _ackController.stream;

  Future<void> connect({
    required String host,
    required int port,
    required String pin,
    String deviceName = 'Companion Tablet',
    String platform = 'Tablet',
  }) async {
    await disconnect();
    final uri = Uri(
      scheme: 'ws',
      host: host,
      port: port,
      path: '/ws',
      queryParameters: <String, String>{
        'pin': pin,
        'device': deviceName,
        'platform': platform,
      },
    );
    _socket = await WebSocket.connect(uri.toString());
    _connected = true;
    _subscription = _socket!.listen(
      _onMessage,
      onDone: () {
        _connected = false;
        _authenticated = false;
      },
      onError: (_) {
        _connected = false;
        _authenticated = false;
      },
    );
  }

  void sendCommand(CompanionCarCommand command) {
    final socket = _socket;
    if (socket == null || socket.readyState != WebSocket.open) {
      throw StateError('Companion WebSocket is not connected.');
    }
    socket.add(jsonEncode(command.toJson()));
  }

  Future<void> disconnect() async {
    _connected = false;
    _authenticated = false;
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _frameController.close();
    await _ackController.close();
  }

  void _onMessage(dynamic data) {
    if (data is! String) return;
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map<String, dynamic>) return;
      final type = decoded['type'] as String? ?? '';
      if (type == 'welcome') {
        _authenticated = true;
        _clientId = decoded['clientId'] as String?;
      } else if (type == 'telemetry_frame') {
        if (!_frameController.isClosed) {
          _frameController.add(TelemetryWallFrame.fromJson(decoded));
        }
      } else if (type == 'command_ack' || type == 'pong' || type == 'auth_failed') {
        if (!_ackController.isClosed) {
          _ackController.add(decoded);
        }
      }
    } catch (_) {
      // Ignore malformed frames from network.
    }
  }
}

/// Immutable Riverpod state for [DualScreenTelemetryWallNotifier].
class DualScreenTelemetryWallState {
  const DualScreenTelemetryWallState({
    this.status = DualScreenServerStatus.stopped,
    this.port = 8765,
    this.pairingPin = '------',
    this.wsUrl = '',
    this.dashboardUrl = '',
    this.connectedDevices = const <ConnectedCompanionDevice>[],
    this.framesBroadcast = 0,
    this.commandsProcessed = 0,
    this.recentLogs = const <String>[],
    this.errorMessage,
  });

  final DualScreenServerStatus status;
  final int port;
  final String pairingPin;
  final String wsUrl;
  final String dashboardUrl;
  final List<ConnectedCompanionDevice> connectedDevices;
  final int framesBroadcast;
  final int commandsProcessed;
  final List<String> recentLogs;
  final String? errorMessage;

  bool get isRunning => status == DualScreenServerStatus.running;

  DualScreenTelemetryWallState copyWith({
    DualScreenServerStatus? status,
    int? port,
    String? pairingPin,
    String? wsUrl,
    String? dashboardUrl,
    List<ConnectedCompanionDevice>? connectedDevices,
    int? framesBroadcast,
    int? commandsProcessed,
    List<String>? recentLogs,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DualScreenTelemetryWallState(
      status: status ?? this.status,
      port: port ?? this.port,
      pairingPin: pairingPin ?? this.pairingPin,
      wsUrl: wsUrl ?? this.wsUrl,
      dashboardUrl: dashboardUrl ?? this.dashboardUrl,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      framesBroadcast: framesBroadcast ?? this.framesBroadcast,
      commandsProcessed: commandsProcessed ?? this.commandsProcessed,
      recentLogs: recentLogs ?? this.recentLogs,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Riverpod notifier managing the lifecycle of [DualScreenTelemetryWallServer].
class DualScreenTelemetryWallNotifier
    extends StateNotifier<DualScreenTelemetryWallState> {
  DualScreenTelemetryWallNotifier({
    DualScreenTelemetryWallServer? server,
  })  : _server = server ?? DualScreenTelemetryWallServer(),
        super(const DualScreenTelemetryWallState()) {
    _eventSub = _server.eventStream.listen(_onServerEvent);
  }

  final DualScreenTelemetryWallServer _server;
  StreamSubscription<DualScreenServerEvent>? _eventSub;

  DualScreenTelemetryWallServer get server => _server;

  Future<void> startServer({int port = 8765, String bindAddress = '0.0.0.0'}) async {
    state = state.copyWith(
      status: DualScreenServerStatus.starting,
      clearError: true,
    );
    try {
      await _server.start(bindAddress: bindAddress, port: port);
      _syncFromServer();
    } catch (e) {
      state = state.copyWith(
        status: DualScreenServerStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> stopServer() async {
    await _server.stop();
    _syncFromServer();
  }

  void regeneratePin() {
    _server.regeneratePairingPin();
    _syncFromServer();
  }

  int broadcastFrame(TelemetryWallFrame frame) {
    final delivered = _server.broadcastTelemetryFrame(frame);
    if (delivered > 0) {
      state = state.copyWith(
        framesBroadcast: _server.framesBroadcastCount,
      );
    }
    return delivered;
  }

  Future<void> disconnectDevice(String clientId) async {
    await _server.disconnectClient(clientId);
    _syncFromServer();
  }

  void _onServerEvent(DualScreenServerEvent event) {
    final updatedLogs = <String>[
      '[${_formatTime(event.timestamp)}] ${event.message}',
      ...state.recentLogs,
    ].take(20).toList(growable: false);

    state = state.copyWith(
      status: _server.status,
      port: _server.boundPort,
      pairingPin: _server.pairingPin.isEmpty ? '------' : _server.pairingPin,
      wsUrl: _server.primaryWebSocketUrl,
      dashboardUrl: _server.primaryWebDashboardUrl,
      connectedDevices: _server.connectedDevices,
      framesBroadcast: _server.framesBroadcastCount,
      commandsProcessed: _server.commandsProcessedCount,
      recentLogs: updatedLogs,
    );
  }

  void _syncFromServer() {
    state = state.copyWith(
      status: _server.status,
      port: _server.boundPort,
      pairingPin: _server.pairingPin.isEmpty ? '------' : _server.pairingPin,
      wsUrl: _server.primaryWebSocketUrl,
      dashboardUrl: _server.primaryWebDashboardUrl,
      connectedDevices: _server.connectedDevices,
      framesBroadcast: _server.framesBroadcastCount,
      commandsProcessed: _server.commandsProcessedCount,
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    unawaited(_server.dispose());
    super.dispose();
  }
}

final dualScreenTelemetryWallProvider = StateNotifierProvider<
    DualScreenTelemetryWallNotifier, DualScreenTelemetryWallState>(
  (ref) => DualScreenTelemetryWallNotifier(),
);

/// Production UI panel for configuring and monitoring the Dual-Screen
/// Telemetry Wall WebSocket server on PC/Mac.
class DualScreenTelemetryWallPanel extends StatelessWidget {
  const DualScreenTelemetryWallPanel({
    super.key,
    required this.state,
    required this.onToggleServer,
    required this.onRegeneratePin,
    this.onDisconnectDevice,
    this.enabled = true,
  });

  final DualScreenTelemetryWallState state;
  final VoidCallback onToggleServer;
  final VoidCallback onRegeneratePin;
  final ValueChanged<String>? onDisconnectDevice;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final isWide = constraints.maxWidth >= 1100;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 12 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isCompact),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildConnectionCard(isCompact)),
                      const SizedBox(width: 16),
                      Expanded(flex: 6, child: _buildDevicesAndLogsCard(isCompact)),
                    ],
                  )
                else ...[
                  _buildConnectionCard(isCompact),
                  const SizedBox(height: 16),
                  _buildDevicesAndLogsCard(isCompact),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final statusColor = switch (state.status) {
      DualScreenServerStatus.running => AppColors.statusSuccess,
      DualScreenServerStatus.starting => AppColors.amberWarning,
      DualScreenServerStatus.error => AppColors.crimsonAlert,
      DualScreenServerStatus.stopped => AppColors.textSecondary,
    };

    final statusLabel = switch (state.status) {
      DualScreenServerStatus.running => 'ONLINE',
      DualScreenServerStatus.starting => 'STARTING',
      DualScreenServerStatus.error => 'ERROR',
      DualScreenServerStatus.stopped => 'OFFLINE',
    };

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.cast_connected_rounded,
                  color: AppColors.goldAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TEAM CAR TELEMETRY WALL',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Local WebSocket Dual-Screen Link',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              _InteractiveWallButton(
                label: state.isRunning ? 'Stop Server' : 'Start Server',
                icon: state.isRunning
                    ? Icons.stop_rounded
                    : Icons.play_arrow_rounded,
                isPrimary: !state.isRunning,
                enabled: enabled && state.status != DualScreenServerStatus.starting,
                onPressed: onToggleServer,
              ),
            ],
          ),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                Icons.cast_connected_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TEAM CAR TELEMETRY WALL',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Local WebSocket Dual-Screen Link (PC/Mac -> Tablet/Phone)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: statusColor.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _InteractiveWallButton(
              label: state.isRunning ? 'Stop Server' : 'Start Server',
              icon: state.isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
              isPrimary: !state.isRunning,
              enabled: enabled && state.status != DualScreenServerStatus.starting,
              onPressed: onToggleServer,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionCard(bool isCompact) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
      ),
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'PAIRING & ENDPOINT',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _InteractiveWallButton(
                label: 'New PIN',
                icon: Icons.refresh_rounded,
                isPrimary: false,
                enabled: enabled && state.isRunning,
                onPressed: onRegeneratePin,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2F3D)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '6-DIGIT PAIRING PIN',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.pairingPin,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldAccent,
                    letterSpacing: 4,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'WebSocket URI',
            state.wsUrl.isEmpty ? 'Server offline' : state.wsUrl,
            accent: AppColors.accentBlue,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Web Companion URL',
            state.dashboardUrl.isEmpty ? 'Server offline' : state.dashboardUrl,
            accent: AppColors.textPrimary,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildStatChip('Frames Sent', '${state.framesBroadcast}'),
              _buildStatChip('Commands Rx', '${state.commandsProcessed}'),
              _buildStatChip('Devices', '${state.connectedDevices.length}'),
            ],
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.crimsonAlert.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.crimsonAlert),
              ),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.crimsonAlert,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDevicesAndLogsCard(bool isCompact) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
      ),
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONNECTED COMPANION DEVICES',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          if (state.connectedDevices.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2F3D)),
              ),
              child: const Text(
                'No companion phones or tablets connected yet. Start the server and open the Companion URL or scan the pairing PIN.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Column(
              children: state.connectedDevices.map((device) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A2F3D)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          device.platform.toLowerCase().contains('phone')
                              ? Icons.smartphone_rounded
                              : Icons.tablet_mac_rounded,
                          color: AppColors.accentBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.deviceName,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${device.remoteAddress} • ${device.rttMs} ms • ${device.commandsSent} cmds',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onDisconnectDevice != null)
                          _InteractiveWallButton(
                            label: 'Kick',
                            icon: Icons.link_off_rounded,
                            isPrimary: false,
                            enabled: enabled,
                            onPressed: () => onDisconnectDevice!(device.clientId),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 14),
          const Text(
            'RECENT TELEMETRY LINK LOGS',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2F3D)),
            ),
            child: state.recentLogs.isEmpty
                ? const Text(
                    'Awaiting server activity...',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: state.recentLogs.take(5).map((log) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          log,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {required Color accent}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        SelectableText(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: accent,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveWallButton extends StatefulWidget {
  const _InteractiveWallButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_InteractiveWallButton> createState() => _InteractiveWallButtonState();
}

class _InteractiveWallButtonState extends State<_InteractiveWallButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseBg = widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceLight;
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _pressed
            ? baseBg.withValues(alpha: 0.8)
            : _hovered
                ? (widget.isPrimary
                    ? AppColors.primaryAccent.withValues(alpha: 0.9)
                    : const Color(0xFF2C313E))
                : baseBg;
    final borderColor = !widget.enabled
        ? const Color(0xFF2A2F3D).withValues(alpha: 0.5)
        : _focused
            ? AppColors.goldAccent
            : _hovered
                ? AppColors.goldAccent.withValues(alpha: 0.7)
                : const Color(0xFF2A2F3D);
    final fgColor = widget.enabled ? AppColors.textPrimary : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: fgColor),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
