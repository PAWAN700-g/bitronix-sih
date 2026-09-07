import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/sensor_reading.dart';

/// Connection states for the ESP32-S3 WaterMonitor.
enum Esp32ConnectionState {
  initial,
  checking,
  connected,
  disconnected,
}

/// Dedicated service managing direct Wi-Fi communication with the ESP32-S3.
///
/// Talks directly to the local ESP32 web server at http://192.168.4.1.
/// Does NOT check or require internet access.
class Esp32Service {
  static const String endpoint = 'http://192.168.4.1';
  static const Duration timeout = Duration(seconds: 4);
  static const Duration pollInterval = Duration(milliseconds: 1000);

  final http.Client _client;

  Esp32ConnectionState _connectionState = Esp32ConnectionState.initial;
  SensorReading? _lastReading;
  String? _lastErrorMessage;
  bool _isPolling = false;
  bool _isRequestInFlight = false;
  Timer? _autoCheckTimer;

  final List<SensorReading> _sessionHistory = [];

  final StreamController<Esp32ConnectionState> _stateController =
      StreamController<Esp32ConnectionState>.broadcast();
  final StreamController<SensorReading> _readingController =
      StreamController<SensorReading>.broadcast();

  Esp32Service({http.Client? client}) : _client = client ?? http.Client();

  Esp32ConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == Esp32ConnectionState.connected;
  SensorReading? get lastReading => _lastReading;
  String? get lastErrorMessage => _lastErrorMessage;
  List<SensorReading> get sessionHistory => List.unmodifiable(_sessionHistory);

  Stream<Esp32ConnectionState> get stateStream => _stateController.stream;
  Stream<SensorReading> get readingStream => _readingController.stream;

  /// Tests the actual ESP32 endpoint at http://192.168.4.1.
  ///
  /// Considers the ESP32 connected if:
  /// - HTTP request succeeds
  /// - status code is 200
  /// - response contains expected sensor fields (tds, turbidity, ph, etc.)
  Future<bool> checkConnection() async {
    if (_isRequestInFlight) return isConnected;
    _isRequestInFlight = true;

    debugPrint('Checking WaterMonitor...');
    _setConnectionState(Esp32ConnectionState.checking);

    try {
      final response = await _client
          .get(
            Uri.parse(endpoint),
            headers: const {
              'Connection': 'close',
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          // Validate that the response contains expected WaterMonitor fields
          final hasTds = decoded.containsKey('tds');
          final hasTurbidity = decoded.containsKey('turbidity');
          final hasPh = decoded.containsKey('ph');
          final hasTemp = decoded.containsKey('temperature');
          final hasSalinity = decoded.containsKey('salinity');

          if (hasTds || hasTurbidity || hasPh || hasTemp || hasSalinity) {
            final reading = _parseReading(decoded);
            _lastReading = reading;
            _lastErrorMessage = null;

            _addToSessionHistory(reading);

            debugPrint('WaterMonitor connected');
            _setConnectionState(Esp32ConnectionState.connected);

            if (!_readingController.isClosed) {
              _readingController.add(reading);
            }

            // Start live periodic polling loop
            startMonitoring();
            return true;
          } else {
            throw const FormatException(
              'Response is missing expected sensor fields (tds, turbidity, ph, etc.)',
            );
          }
        } else {
          throw const FormatException('Response is not a valid JSON object');
        }
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } on SocketException catch (e) {
      _handleFailure(e.message.isNotEmpty ? e.message : 'ESP32 at 192.168.4.1 is unreachable');
      return false;
    } on TimeoutException {
      _handleFailure('Connection timed out after 4 seconds (192.168.4.1 unreachable)');
      return false;
    } catch (e) {
      _handleFailure(e.toString());
      return false;
    } finally {
      _isRequestInFlight = false;
    }
  }

  /// Starts the continuous 1-second polling loop.
  void startMonitoring() {
    if (_isPolling) return;
    _isPolling = true;
    _runPollingLoop();
  }

  /// Stops continuous polling.
  void stopMonitoring() {
    _isPolling = false;
  }

  /// Starts auto-checking when on the connection screen.
  /// Checks every 3 seconds until connected.
  void startAutoCheck() {
    _autoCheckTimer?.cancel();
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!isConnected && !_isRequestInFlight) {
        checkConnection();
      }
    });
  }

  void stopAutoCheck() {
    _autoCheckTimer?.cancel();
    _autoCheckTimer = null;
  }

  Future<void> _runPollingLoop() async {
    while (_isPolling) {
      await Future.delayed(pollInterval);
      if (!_isPolling) break;

      if (_isRequestInFlight) continue;
      _isRequestInFlight = true;

      try {
        final response = await _client
            .get(
              Uri.parse(endpoint),
              headers: const {
                'Connection': 'close',
                'Accept': 'application/json',
              },
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
          final dynamic decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final reading = _parseReading(decoded);
            _lastReading = reading;
            _lastErrorMessage = null;
            _addToSessionHistory(reading);

            if (_connectionState != Esp32ConnectionState.connected) {
              debugPrint('WaterMonitor connected');
              _setConnectionState(Esp32ConnectionState.connected);
            }

            if (!_readingController.isClosed) {
              _readingController.add(reading);
            }
          }
        } else {
          _handleFailure('HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }
      } catch (e) {
        _handleFailure(e.toString());
      } finally {
        _isRequestInFlight = false;
      }
    }
  }

  void _handleFailure(String reason) {
    _lastErrorMessage = reason;
    debugPrint('WaterMonitor connection failed: ');
    _setConnectionState(Esp32ConnectionState.disconnected);
  }

  void _setConnectionState(Esp32ConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      if (!_stateController.isClosed) {
        _stateController.add(newState);
      }
    }
  }

  void _addToSessionHistory(SensorReading reading) {
    _sessionHistory.add(reading);
    if (_sessionHistory.length > 100) {
      _sessionHistory.removeAt(0);
    }
  }

  SensorReading _parseReading(Map<String, dynamic> json) {
    return SensorReading(
      deviceId: (json['deviceId'] as String?) ?? 'ESP001',
      timestamp: DateTime.now(),
      ph: _parseDouble(json['ph'], 7.0),
      tds: _parseDouble(json['tds'], 0.0),
      turbidity: _parseDouble(json['turbidity'], 0.0),
      salinity: _parseDouble(json['salinity'], 0.2),
      temperature: _parseDouble(json['temperature'], 25.0),
      status: json['status']?.toString().trim(),
      appReceivedTimestamp: DateTime.now(),
    );
  }

  double _parseDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  void dispose() {
    stopMonitoring();
    stopAutoCheck();
    _stateController.close();
    _readingController.close();
    _client.close();
  }
}
